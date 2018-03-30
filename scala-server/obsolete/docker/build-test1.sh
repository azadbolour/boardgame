#!/bin/sh

namespace=azadbolour
tag=1.0

dockerfile=Dockerfile.test1

docker build --no-cache --force-rm=true -f ${dockerfile} -t ${namespace}/test1:${tag} .
