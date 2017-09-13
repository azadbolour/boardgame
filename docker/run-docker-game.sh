#!/bin/sh

# For production deployment.
# TODO. Try to redirect output or run.sh to a mounted volume in the container.
# Then can use docker run -d to create a detatched conatiner.
# And the logs will be on teh host file system.
nohup docker run -p 6587:6587 --restart on-failure:5 azadbolour/boardgame:0.2 &

# For development.
# docker run -p 6587:6587 -i -t azadbolour/boardgame:0.2 &
