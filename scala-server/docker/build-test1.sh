#!/bin/sh -x

namespace=azadbolour
tag=1.0

here=`pwd`

dockerfile=$here/Dockerfile.test1

cd $HOME

docker build --no-cache --force-rm=true -f ${dockerfile} -t ${namespace}/test1:${tag} .
