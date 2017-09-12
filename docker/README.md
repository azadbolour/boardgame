

Two docker images are used for board game:

- boardgame-base - includes all the dependencies of the system up to a
  given tag. Because the haskell dependencies must be downloaded and compiled,
  creating this image take a long time - 20 minutes on current crop of 
  machines. This image does not have an explicit entry point.

- boardgame - is based on boardgame-base but builds the system with the 
  latest sources. It takes very little time to build because most of 
  the dependencies are likely to exist in the base image. This image's
  entry point starts the baordgame web application.

The following files are are used in building and using the boardgame
images:

- Dockerfile.boardgame-base - The docker file for building the base image.

- build-boardgame-base-docker.sh - Builds the base image - needs a tag as 
  parameter.

- Dockerfile.boardgame - The docker file for building the latest board game.

- build-boardgame-docker.sh - Builds the latest board game - needs a tag.
  The tag should be the same as that of an already-built base.

- run-docker-game.sh - Runs a docker container based on the boardgame image.


