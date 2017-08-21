#!/bin/sh

psql -U postgres <<EOF
  drop table play;
  drop table game;
  drop table player;
EOF
