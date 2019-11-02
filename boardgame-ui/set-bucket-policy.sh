#!/bin/sh -x

bucketName=$1
aws s3api put-bucket-policy --bucket ${bucketName} --policy file://bucket-policy.json
