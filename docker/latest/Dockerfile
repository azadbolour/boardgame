
#
# Latest version of board game
#

#
# Begin with ubuntu version 14.04.
#
FROM azadbolour/boardgame-base-v0.2

RUN cd /home/me/dev/boardgame && git pull origin master
RUN ls /home/me/dev/boardgame/haskell-server

ENTRYPOINT ["/home/me/dev/boardgame/haskell-server/cd-run.sh", "/home/me/dev/boardgame/haskell-server", "test-data/sqlite-config.yml"]
