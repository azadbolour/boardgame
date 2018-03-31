#!/bin/sh -x

#
# Build the packager image for the board game.
#
# 
# The application packager puts the play application bundle
# and scripts needed to run the application in a package directory.
# See defaults.sh for its default value. The paramater PACKAGE_DIR
# should point to the package area produced by the packager.
#

NAMESPACE=$1
TAG=$2
PACKAGE_DIR=$3
BASE_IMAGE=$4

if [ -z "${NAMESPACE}" -o -z "${TAG}" -o -z "$PACKAGE_DIR" ]; then
  echo "usage: $0 docker-namespace docker-tag package-dir [base-image]"
  exit 1
fi

if [ -z "$BASE_IMAGE" ]; then 
  BASE_IMAGE="azadbolour/jvm-node:1.0"
fi

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "expected applicaiton distribution package directory $PACKAGE_DIR does not exist"
    exit 1
fi

#
# Large hierarchy is a a sign of an error in package directory parameter.
#
LIMIT=1000000 # k
size=`du -s -k $PACKAGE_DIR`
if [ $size -gt $LIMIT ]; then
    echo "package hierarchy too large - likely an error in package-dir path $PACKAGE_DIR"
    exit 1
fi

REPOSITORY=boardgame-scala-server
DOCKERFILE=Dockerfile.${REPOSITORY}

#
# Docker build can only use files below its current working directory.
# So to be able to use the packaged distribution, we need to cd to the package directory.
# But then the dockerfile needs to be copied there as well.
#
cp $DOCKERFILE $PACKAGE_DIR
cd $PACKAGE_DIR

#
# Use --no-cache so that the latest source will be pulled.
# Otherwise docker just compares the pull request with a previously-built and cached layer's 
# command and since they are the same it will use the old cached layer.
#
docker build --no-cache --force-rm=true -f ${DOCKERFILE} \
  --build-arg BASE=${BASE_IMAGE} \
  -t ${NAMESPACE}/${REPOSITORY}:${TAG} .

