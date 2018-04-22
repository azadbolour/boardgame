#!/bin/sh

# Used to make it easier to find dependents of an image. 
# Get everything built after an image.

# The parent image's sha.
parent=$1

# docker inspect --format='{{.Id}} {{.Parent}}' $(docker images --filter since=${parent} -q) | grep ${parent}
docker inspect --format='{{.Id}} {{.Parent}}' $(docker images --filter since=${parent} -q) 
