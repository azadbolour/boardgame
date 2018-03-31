#!/bin/sh -x

namespace=$1
tag=$2

if [ -z "${namespace}" -o -z "${tag}" ]; then
  echo "usage: $0 docker-namespace repository-tag"
  exit 1
fi

repository=jvm-node
dockerfile=Dockerfile.${repository}

docker build --no-cache --force-rm=true -f ${dockerfile} --build-arg BASE=${baseImage} -t ${namespace}/${repository}:${tag} .

