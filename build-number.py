#!/usr/bin/python

import boto3
import sys

ddb = boto3.client('dynamodb')

project = sys.argv[1]

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

print(values['Attributes']['BuildCounter']['N'])
