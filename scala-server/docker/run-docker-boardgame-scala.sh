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
# Get default values of command line parameters:
# HTTP_PORT, PROD_CONF, PID_FILE, VERSION.
#
. defaults.sh

while [ $# -gt 0 ]; do
    case "$1" in
        --http-port) 
            shift && HTTP_PORT="$1" || die ;;
        --prod-conf) 
            shift && PROD_CONF="$1" || die ;;
        --pid-file) 
            shift && PID_FILE="$1" || die ;;
        --version) 
            shift && VERSION="$1" || die ;;
        *) 
            echo "$0: unknown option $1" && die ;;
    esac
    shift
done

if [ -z "$VERSION" ]; then echo "missing version" && die; fi

NAMESPACE=azadbolour
REPOSITORY=boardgame-scala

nohup docker run -p ${HTTP_PORT}:${HTTP_PORT} --restart on-failure:5 --name boardgame-scala \
    -v ${BOARDGAME_DATA}:${BOARDGAME_DATA} ${NAMESPACE}/${REPOSITORY}:${VERSION} \
    --http-port $HTTP_PORT --prod-conf $PROD_CONF --pid-file $PID_FILE --version $VERSION &

#    -e HTTP_PORT="${HTTP_PORT}" -e PROD_CONF="${PROD_CONF}" \
