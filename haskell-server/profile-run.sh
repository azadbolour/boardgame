#!/bin/sh

export GAME_SERVER_PORT=6587
stack exec -- boardgame-server +RTS -p

