#!/bin/sh

#
# TODO. Table play is no longer in use. Remove it and then remove from this script.
#
sqlite3 database/game-sqlite.db <<EOF
  drop table play;
  drop table game;
  drop table player;
EOF
