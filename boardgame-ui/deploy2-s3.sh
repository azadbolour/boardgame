#!/bin/sh -x

bucketName=$1
# Recursively copy changed files and delete obsolete files.
aws s3 sync build/ s3://${bucketName} --delete

