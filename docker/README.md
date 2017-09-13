

Two docker images are used for board game:

- boardgame-base - includes all the dependencies of the system up to a
  given tag. Because the haskell dependencies must be downloaded and compiled,
  creating this image take a long time - 20 minutes on current crop of 
  machines. This image does not have an explicit entry point.

- boardgame - is based on boardgame-base but builds the system with the 
  latest sources. It takes very little time to build because most of 
  the dependencies are likely to exist in the base image. This image's
  entry point starts the baordgame web application.

Resources used to build and run docker conatiners.

- docker file for the base image: `Dockerfile.boardgame-base`

- script to build the base image: 

  `build-boardgame-base-docker.sh registry-namespace repository-tag`

  creates an image named: `${registry-namespace}/boardgame-base/${repository-tag}`

- docker file for building the latest board game: `Dockerfile.boardgame`

- script to build the build the board game server: 

  `boardgame-docker.sh registry-namespace repository-tag`

  creates an image named: `${registry-namespace}/boardgame/${repository-tag}`

- run a docker container based on the boardgame image: `run-docker-game.sh`



