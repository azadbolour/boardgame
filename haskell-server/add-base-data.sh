#!/bin/sh

#
# TODO. Use the correct db parameters from config.yml.
#
psql -U postgres -h 127.0.0.1 <<EOF
insert into player (name) values ('You');
EOF

