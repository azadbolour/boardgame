#!/bin/sh

#
# Removes obsolete images.
#
for c in $(docker ps -a -f status=exited -f status=created -f status=dead --format="{{.ID}}"); do
    docker rm $c
done
for img in $(docker images -f dangling=true --format="{{.ID}}"); do
    docker rmi $img
done
