#!/usr/bin/python

import boto3
import sys

ddb = boto3.client('dynamodb')

build = sys.argv[1]
build_parts = build.split(':')
project_parts = build_parts[:-1]
project = ':'.join(project_parts)

values = ddb.update_item(
    TableName        = 'BuildCounter',
    Key              = {
        'Project': { 'S': project },
    },
    ReturnValues     = "UPDATED_NEW",
    UpdateExpression = "ADD BuildCounter :one",
    ExpressionAttributeValues = {
        ':one': { 'N': '1' },
    },
)

print values['Attributes']['BuildCounter']['N']
