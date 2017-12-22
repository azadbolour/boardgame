#!/bin/sh

# 
# Run a production docker container for the application.
#
# The docker container is cognizant of two environment variables:
#
#   HTTP_PORT for the port of the server application
#       obtained as the 'port' argument to this script
#   PROD_CONF for the Play production configuration file of the application
#       obtained as the environment variable PROD_CONF to this script
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

PORT=$1
DEFAULT_PORT=6587

if [ -z "${PORT}" ]; then
  PORT=${DEFAULT_PORT}
fi

APP_DATA_DIR=/opt/data/boardgame
NAMESPACE=azadbolour
REPOSITORY=boardgame-scala
TAG=0.1

nohup docker run -p ${port}:${port} --restart on-failure:5 \
    -e HTTP_PORT=${port} -e PROD_CONF="${PROD_CONF}" \
    -v ${APP_DATA_DIR}:${APP_DATA_DIR} \
    ${NAMESOACE}/${REPOSITORY}:${TAG} &

# For development.
# docker run -p 6587:6587 -i -t azadbolour/boardgame:0.2 &
