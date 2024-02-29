# Periodic S3 Sync

This docker image is intended to do just one thing: copy files between S3 and
somewhere, either once or on a schedule. This is configured using an IAM role
rather than an explicit AWS key. The reasons for this are listed below.

## Configuration

To startup the container quickly, just run:

    docker run -d [OPTIONS] zostay/periodic-s3-sync

The options are passed in via environment variables like so:

* `SYNC_FROM` - (Required) This is the name of the location to get files from.
  This may be either a local path or an S3 URI.
* `SYNC_TO` - (Required) This is the name of the location to send files to. This
  may be either a local path or an S3 URI.
* `CRON_SCHEDULE` - This is the schedule to run with. If not given, it is
  assumed to be "0 * * * *", so the period is once every hour.
* `SYNC_MODE` - This may be set to `PERIODIC` or `STARTUP` or
  `STARTUP+PERIODIC`. If the mode is `PERIODIC` or `STARTUP+PERIODIC`, the
  copying is performed according to the `CRON_SCHEDULE`. If the mode is either
  `STARTUP` or `STARTUP+PERIODIC`, the sync happens once immediately after the
  container starts. This can be set to an empty value to cause the container to
  do nothing, if you need to disable it and don't want to stop it. The default
  is `STARTUP+PERIODIC`.
* `SYNC_PARAMS` - Any additional parameters you want to pass to the AWS CLI S3
  sync command.
* `CHMOD_MODE` - If set and `SYNC_TO` is a local path, this will be passed as
  the mode to set on all files and directories recursively after sync.
* `CHOWN_OWNER` - If set and `SYNC_TO` is a local path, this user will be given
  ownership of all the files after sync is complete.

## IAM Key Pair Authentication

You can authenticate directly using an access key/secret key pair.

* `AWS_ACCESS_KEY_ID` - The access key ID to use.
* `AWS_SECRET_ACCESS_KEY` - The secret that goes with the access key ID.
* `AWS_SESSION_TOKEN` - You will only need this if you have manually acquired
  temporary session credentials. If you do not know what that last sentence
  means, you do not need to know what this parameter is.

This is the most straightforward authentication method. This is useful when you
are running this container away from AWS. However, using key pairs for
authentication is not a recommended practice, in general. There are some notes
below explaining why.

## IAM Role Authentication

If you are running your container on an EC2 instance or using ECS or something
similar, it is usually better to use an IAM Role account instead of an
explicitly named key pair. This can be done in the following ways:

* If you provide no authentication information at all, the container (actually
  the AWS CLI) will attempt to use the IAM role that has been attached to the
  instance running the container.

* `ROLE_ARN` - You may name the ARN of a role you want the sync container to
  take on explicitly. The container will assume this role if it is able to do
  so.

If you are having trouble getting an explicit role to work, a `SESSION_DEBUG`
option is added. If you set this to 1, it will display the output of the login
sequence, which can be sure the role switch is working correctly from the
container.

## Additional Configuration

You can add the other environment variables mentioned in [Configuring the AWS
CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

## Examples

The container uses the AWS CLI to run the following command to perform the sync:

    aws s3 sync $SYNC_FROM $SYNC_TO $SYNC_PARAMS

This can be used to pull files from S3 into a local directory:

    docker run -d \
        -e ROLE_ARN=arn:aws:iam::123456789012:role/sync \
        -e SYNC_FROM=s3://bucket.example.com/path/to/files/ \
        -e SYNC_TO=/data \
        zostay/periodic-s3-sync

Or to push files from a local directory to S3:

    docker run -d \
        -e ROLE_ARN=arn:aws:iam::123456789012:role/sync \
        -e SYNC_FROM=/data \
        -e SYNC_TO=s3://bucket.example.com/path/to/files/ \
        zostay/periodic-s3-sync

Or to move files around between locations on S3:

    docker run -d \
        -e ROLE_ARN=arn:aws:iam::123456789012:role/sync \
        -e SYNC_FROM=s3://bucket1.example.com/path/to/files/ \
        -e SYNC_TO=s3://bucket2.example.com/path/to/files/ \
        zostay/periodic-s3-sync

When syncing to a local directory, the `/data` directory is the recommended
location to use.

## Additional Notes

Okay, now I need to explain why I built it this way and why so many AWS-related
docker containers are annoying in how they are implemented. I hope it also gives
some hints into ways in which you can use this service sanely.

### The Problem with Explicit Keys

Here are some problems with using an explicit access/secret key pair is:

* It requires the use of an IAM user account. IAM user accounts are designed for
  user by people, not services running on their. Docker containers are services
  running on their own, not people.

* IAM user account access keys should, ideally, be rotated periodically. If you
  are rotating your access keys, then you have to go update your container
  configuration every time you do that. That's annoying and I use
  docker/kubernetes and the like because I'm too lazy to be annoyed like that.

* Storing your secret key is not ideal. Any secret storage mechanism is a
  potential weakness in the security of a system. You can be smarter about it by
  maybe making use of the SSM Parameter Store or a secret storage service, but
  you are generally better off avoiding even these when you can.

### A Solution to Explicit Keys

A solution to this problem is to define an IAM role and attach it to the
instance running the container. This solves problems like so:

* IAM role accounts designed for use by services running on their, not people.
  Docker containers are services running on their, not people.

* IAM role accounts are assumed by services, each getting an automatically
  rotated access/secret on assumption. This means you never have to rotate the
  key because you just get the key values you need by "magic" (i.e., they are
  typically assigned per EC2 instance via metadata only available from the
  instance itself).

### The Problem with Instance Attached Roles

The above solution is alright for many use-cases, but has its own problems.

* An EC2 instance is granted a single role as part of the instance profile (or
  none). This means that the role the instance possesses must be the union of
  all security policies needed by all containers running on the instance.
  This, in turn, means that every container has all of those permissions too,
  which is not a good security model.

### A Solution to Instance Attached Role Problems

Fortunately, there are solutions to these problems too. Here is one general
solution to the problem:

* Instead of creating a single instance profile role that is the union of
  all policies, create multiple roles, perhaps one per container or one per
  container type.

* For each of these additional roles, edit the trust relationship so that the
  instance profile role is permitted to assume these roles (sometimes called
  "Role Switching" in the AWS documentation).

* Each container then must assume the role it needs and not use the instance
  role.

Now, what you need to do to start up your containers to get these roles depends
heavily on how you are starting and running your containers. If containers are
able to assume any role starting with the instance profile role, the situation
is not really any better than before. 

Somehow you need to make it so that the instance assigns the roles to the
containers at startup. Typically, this is done by blocking access to the
instance metadata normally used by the AWS CLI and other tools to assume the
instance profile role. Then, somehow providing equivalent metadata to the
containers or just sending in the temporary credentials.

Here are couple specific solutions that may suit your situation that I've found
while learning about these issues:

* For ECS, you can perform the special cluster configuration described in [IAM
  Roles for Tasks](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html).

* For Kubernetes, you can look into configuring
    [kaim](https://github.com/uswitch/kiam) or
  [kube2iam](https://github.com/jtblin/kube2iam).
