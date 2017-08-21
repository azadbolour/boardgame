#!/bin/sh

GAME_SERVER_PORT=6587
curl -u "admin:admin" -H "Accept: application/json" -H "Content-Type: application/json" -X POST -d @start-game.json "http://localhost:$GAME_SERVER_PORT/game/game" | python -m json.tool
