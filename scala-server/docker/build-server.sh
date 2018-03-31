#!/bin/sh -x

#
# Build the packager image for the board game.
#
# PRE_REQUISITE. The dockerfile expects the root of the app's distribution
# to be $DEFAULT_BOARDGAME_DATA/package. By default the application packager 
# outputs n that directory the play app's bundled zip file, and a script 
# directory with scripts needed to install and run the application.
# Before running this script the packager should be run in its default 
# configuration.
#

namespace=$1
tag=$2
baseImage=$3

if [ -z "${namespace}" -o -z "${tag}" ]; then
  echo "usage: $0 docker-namespace repository-tag [base-image]"
  exit 1
fi

if [ -z "$baseImage" ]; then 
  baseImage="azadbolour/jvm-node:1.0"
fi

#
# import DEFAULT_BOARDGAME_DATA
#
. ../defaults.sh

PACKAGE_DIR=$DEFAULT_BOARDGAME_DATA/package

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "expected applicaiton distribution package directory $PACKAGE_DIR does not exist"
    exit 1
fi

repository=boardgame-scala-server
dockerfile=Dockerfile.${repository}

#
# Use --no-cache so that the latest source will be pulled.
# Otherwise docker just compares the pull request with a previously-built and cached layer's 
# command and since they are the same it will use the old cached layer.
#
docker build --no-cache --force-rm=true -f ${dockerfile} \
  --build-arg BASE=${baseImage} \
  -t ${namespace}/${repository}:${tag} .

