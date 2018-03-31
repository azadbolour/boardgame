#!/bin/sh -x

# 
# Run a production docker container for the application.
# Parameters passed to the entry point of the container.
#
#   HTTP_PORT for the port of the server application
#   PROD_CONF for the Play production configuration file of the application
#   PID_FILE the location of play's pid lock file
#   VERSION the version of the application
#
# These variables are used to provide information about the production 
# deployment environment to the Play application. 
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

#
# import BOARDGAME_DATA
# import DEFAULT_HTTP_PORT
# import DEFAULT_PROD_CONF
# import DEFAULT_PID_FILE
# import DEFAULT_INSTALL_DIR
#
. ../defaults.sh

INSTALL_ROOT=$DEFAULT_INSTALL_DIR

while [ $# -gt 0 ]; do
    case "$1" in
        --http-port) 
            shift && HTTP_PORT="$1" || (echo "missing http-port value"; exit 1) ;;
        --allowed-host) 
            shift && ALLOWED_HOST="$1" || (echo "missing allowed-host value"; exit 1) ;;
        --pid-file) 
            shift && PID_FILE="$1" || (echo "missing pid-file value"; exit 1) ;;
        --tag) 
            shift && TAG="$1" || (echo "missing tag value"; exit 1) ;;
        *) 
            echo "$0: unknown option $1" && die ;;
    esac
    shift
done

if [ -z "$TAG" ]; then 
    echo "required parameter 'tag' [of the docker image to run] is missing"
    exit 1
fi

if [ -z "$HTTP_PORT" ]; then HTTP_PORT=${DEFAULT_HTTP_PORT}; fi
if [ -z "$PID_FILE" ]; then PID_FILE=${DEFAULT_PID_FILE}; fi
if [ -z "$ALLOWED_HOST" ]; then VERSION=${DEFAULT_ALLOWED_HOST}; fi

NAMESPACE=azadbolour
REPOSITORY=boardgame-scala-server

nohup docker run -p ${HTTP_PORT}:${HTTP_PORT} --restart on-failure:5 --name boardgame-scala-server \
    --build-arg INSTALL_ROOT="$INSTALL_ROOT" \
    -e HTTP_PORT="${HTTP_PORT}" -e ALLOWED_HOST="${ALLOWED_HOST}" -e PID_FILE="${PID_FILE}" \
    -v ${BOARDGAME_DATA}:${BOARDGAME_DATA} ${NAMESPACE}/${REPOSITORY}:${TAG} &
