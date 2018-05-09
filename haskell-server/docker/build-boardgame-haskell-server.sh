#!/bin/sh -x

#
# Build the docker image for the boardgame haskell server from an aleady built
# distribution (see build-prod.sh).
#

NAMESPACE=$1
TAG=$2
PACKAGE_DIR=$3

if [ -z "${NAMESPACE}" -o -z "${TAG}" -o -z "${PACKAGE_DIR}" ]; then
  echo "usage: $0 namespace tag package-dir"
  exit 1
fi

if [ ! -d "${PACKAGE_DIR}" ]; then
    echo "expected application distribution package directory ${PACKAGE_DIR} does not exist"
    exit 1
fi

REPOSITORY=boardgame-haskell-server
DOCKERFILE=Dockerfile.${REPOSITORY}

#
# Docker build can only use files below its current working directory.
# So to be able to use the packaged distribution, we need to cd to the package directory.
# But then the dockerfile needs to be copied there as well.
#
cp ${DOCKERFILE} ${PACKAGE_DIR}
cd ${PACKAGE_DIR}

#
# Use --no-cache so that the latest source will be pulled.
# Otherwise docker just compares the pull request with a previously-built and cached layer's 
# command and since they are the same it will use the old cached layer.
#
docker build --no-cache --force-rm=true -f ${DOCKERFILE} -t ${NAMESPACE}/${REPOSITORY}:${TAG} .


