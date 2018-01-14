#!/bin/sh -x

# 
# Run a production docker container for the application.
#
# The docker container is cognizant of two environment variables:
#
#   HTTP_PORT for the port of the server application
#   PROD_CONF for the Play production configuration file of the application
#
# These variables are used to provide information about the production 
# deployment environment to the Play application. They are transmitted
# to the container via -e options to the docker run command.
#
# The production config file is created on the host machine and must be 
# mapped into the docker file system. We use the convention that external server
# data for the application is rooted on the host system at the well-known folder:
#
#       /opt/data/boardgame
#
# And that this folder is mapped to a folder of the same absolute name in the 
# container file system. The mapping is done by using the -v option of the
# docker run command.
#

# TODO. Try to redirect output of the container to a mounted volume in the container.
# Then can use docker run -d to create a detatched conatiner.
# And the logs will be on the host file system.

HTTP_PORT=$1
PROD_CONF=$2

BOARDGAME_DATA=/opt/data/boardgame

DEFAULT_PORT=6597
DEFAULT_PROD_CONF=$BOARDGAME_DATA/conf/prod.conf

if [ -z "${HTTP_PORT}" ]; then
  HTTP_PORT=$DEFAULT_PORT
fi

if [ -z "${PROD_CONF}" ]; then
  PROD_CONF=$DEFAULT_PROD_CONF
fi

# if [ -z "${HTTP_PORT}" -o -z "${PROD_CONF}" ]; then
#   echo "usage: $0 HTTP_PORT PROD_CONF - aborting"
#   exit 1
# fi

NAMESPACE=azadbolour
REPOSITORY=boardgame-scala
TAG=0.5

nohup docker run -p ${HTTP_PORT}:${HTTP_PORT} --restart on-failure:5 --name boardgame-scala \
    -e HTTP_PORT="${HTTP_PORT}" -e PROD_CONF="${PROD_CONF}" \
    -v ${BOARDGAME_DATA}:${BOARDGAME_DATA} ${NAMESPACE}/${REPOSITORY}:${TAG} &

