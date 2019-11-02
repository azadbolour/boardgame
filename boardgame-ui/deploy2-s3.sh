#!/bin/sh -x

bucketName=$1
aws s3 cp build/ s3://${bucketName} --recursive
