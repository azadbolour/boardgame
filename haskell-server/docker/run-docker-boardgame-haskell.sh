#!/bin/sh

tag=$1

if [ -z "$tag" ]; then
  echo "usage: $0 tag"
  exit 1
fi

image=boardgame-haskell

# For production deployment.
# TODO. Try to redirect output of run.sh to a mounted volume in the container.
# Then can use docker run -d to create a detatched conatiner.
# And the logs will be on teh host file system.

nohup docker run -p 6587:6587 --restart on-failure:5 azadbolour/${image}:${tag} &

# For development.
# docker run -p 6587:6587 -i -t azadbolour/${image}:${tag} &
