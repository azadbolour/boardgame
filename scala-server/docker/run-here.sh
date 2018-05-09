#!/bin/sh

ALLOWED_HOST=$1
# ALLOWED_HOST="host:port"
run-docker-server.sh --tag 0.9.5 --allowed-host "$ALLOWED_HOST"
