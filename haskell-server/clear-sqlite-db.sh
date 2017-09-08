#!/bin/sh

sqlite3 database/game-sqlite.db <<EOF
  drop table play;
  drop table game;
  drop table player;
EOF
