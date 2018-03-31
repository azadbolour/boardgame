#!/bin/sh

ALLOWED_HOST="host:port"
run-docker-server.sh --tag 0.9.1 --allowed-host "$ALLOWED_HOST"
