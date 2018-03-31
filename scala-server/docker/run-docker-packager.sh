#!/bin/sh -x

# 
# Run the docker packager to build and package the application.
#
# We use the convention that external server data for the
# application is rooted on the host system at the well-known folder:
#
#       /opt/data/boardgame
#
# And that this folder is mapped to a folder of the same absolute name in the 
# container file system. The mapping is done by using the -v option of the
# docker run command.
#

# TODO. Try to redirect output of the container to a mounted volume in the container.
# Then can use docker run -d to create a detached container.
# And the logs will be on the host file system.

#
# import DEFAULT_BOARDGAME_DATA
#
. ../defaults.sh

BOARDGAME_DATA=${DEFAULT_BOARDGAME_DATA}

while [ $# -gt 0 ]; do
    case "$1" in
        --tag) 
            shift && TAG="$1" || (echo "missing tag value"; exit 1) ;;
        *) 
            echo "$0: unknown option $1" && die ;;
    esac
    shift
done

if [ -z "${TAG}" ]; then
    echo "required parameter 'tag' [of the docker image to run] is missing"
    exit 1
fi

#
# Create the mapped volume directory on the host.
# TODO. Permissions for mapped volume directories?
#
sudo mkdir -p ${BOARDGAME_DATA}
sudo chmod 777 ${BOARDGAME_DATA}

NAMESPACE=azadbolour
REPOSITORY=boardgame-scala-packager

nohup docker run --restart on-failure:5 --name boardgame-scala-packager \
    --workdir="" \
    -v ${BOARDGAME_DATA}:${BOARDGAME_DATA} \
    ${NAMESPACE}/${REPOSITORY}:${TAG} &
