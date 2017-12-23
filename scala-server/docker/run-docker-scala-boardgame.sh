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
DEFAULT_PORT=6597

if [ -z "${HTTP_PORT}" -o -z "${PROD_CONF}" ]; then
  echo "usage: $0 HTTP_PORT PROD_CONF - aborting"
  exit 1
fi

APP_DATA_DIR=/opt/data/boardgame
NAMESPACE=azadbolour
REPOSITORY=boardgame-scala
TAG=0.1

nohup docker run -p ${HTTP_PORT}:${HTTP_PORT} --restart on-failure:5 --name boardgame-scala \
    -e HTTP_PORT="${HTTP_PORT}" -e PROD_CONF="${PROD_CONF}" \
    -v ${APP_DATA_DIR}:${APP_DATA_DIR} ${NAMESPACE}/${REPOSITORY}:${TAG} &

# For development.
# docker run -p 6587:6587 -i -t azadbolour/boardgame:0.2 &
