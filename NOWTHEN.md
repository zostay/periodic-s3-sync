---
kind: infrastructure
forge: github
tracker: github-issues
test: docker build -t periodic-s3-sync .
deploy.mode: ci-on-push
deploy.target: ghcr.io/zostay/periodic-s3-sync
---

periodic-s3-sync is a single Docker image — two shell scripts (`entrypoint.sh`,
`s3-sync.sh`) on an Alpine base — that syncs files between S3-compatible object
stores and local paths, once at startup or on a cron schedule.

There is no test suite. The build *is* the check: `RUN s3cmd --version` in the
Dockerfile is a deliberate smoke test, so a base-image bump that drops or
renames an apk package fails the build rather than shipping. `.github/workflows/pr-build.yaml`
runs exactly that, amd64-only, on every PR.

A merge to `master` finishes the deploy: `build-and-push.yaml` builds multi-arch
(amd64/arm64) and pushes `:latest` plus a `<run>.<attempt>` tag to
`ghcr.io/zostay/periodic-s3-sync`, then records the build number via the
reusable workflow at `zostay/build`. Nothing else has to happen afterwards for
the image to be published — but publishing is not the same as being *running*
anywhere: whatever pulls this image redeploys on its own schedule, and that
consumer is not recorded in this repository.

The `environment: v4.qubling.cloud` on the build job supplies the credentials
and bucket vars for build-number recording. It is not a host this project
deploys onto, despite reading like one.

Old GHCR versions are pruned weekly by `ghcr-lifecycle.yaml` (Sundays, 00:00
UTC), keeping at least 10 versions and deleting untagged ones after 7 days.

Maintenance here has been dependency upkeep only — Dependabot covers GitHub
Actions and Docker base images.
