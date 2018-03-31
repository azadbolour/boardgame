#!/bin/sh -x

namespace=azadbolour
tag=1.0

CONTEXT_ROOT=$HOME/junk
dockerfile=Dockerfile.test1
cp $dockerfile $CONTEXT_ROOT

cd $CONTEXT_ROOT

docker build --no-cache --force-rm=true -f ${dockerfile} -t ${namespace}/test1:${tag} .
