#!/bin/sh

psql -U postgres -h 127.0.0.1 <<EOF
  drop table game;
  drop table player;
EOF
