#!/bin/sh

configPath=$1

if [ -z "$configPath" ]; then
  configPath="./config.yml"
fi

if [ -f ${configPath} ]; then 
  stack exec boardgame-database-migrator $configPath
else
  stack exec boardgame-database-migrator 
fi

#
# TODO. Insertion/update of initial data should be part of the migration
# procedure, and use the correct user etc.
#
psql -U postgres -h 127.0.0.1 <<EOF
insert into player (name) values ('You');
EOF

