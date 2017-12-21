#!/bin/sh

# For production deployment.
# TODO. Try to redirect output or run.sh to a mounted volume in the container.
# Then can use docker run -d to create a detatched conatiner.
# And the logs will be on teh host file system.

port=$1
defaultPort=6587

if [ -z "${port}" ]; then
  port=${defaultPort}
fi

nohup docker run -p ${port}:${port} --restart on-failure:5 -e port=${port} azadbolour/boardgame-scala:0.1 &

# For development.
# docker run -p 6587:6587 -i -t azadbolour/boardgame:0.2 &
