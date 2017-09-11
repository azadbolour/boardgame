
FROM ubuntu:trusty

RUN apt-get update
RUN apt-get install -y apt-utils wget curl

RUN echo "deb http://apt.postgresql.org/pub/repos/apt trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt-get update

RUN apt-get install -y postgresql-9.6 postgresql-client-9.6 postgresql-contrib-9.6 libpq-dev postgresql-server-dev-9.6 pgadmin3

RUN dpkg -L libpq-dev

RUN echo `pwd`
RUN whoami
RUN apt-get install -y git && which git
RUN ls /home

RUN mkdir -p /home/workspace
RUN cd /home/workspace && git clone https://github.com/azadbolour/boardgame
RUN ls /home/workspace
WORKDIR /home/workspace/boardgame
RUN echo `pwd`

RUN apt-get update
RUN curl -sL https://raw.githubusercontent.com/nodesource/distributions/master/deb/setup_7.x | bash -

RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get install -y nodejs

RUN cd web-ui && npm install -g eslint && npm install -g jsdoc
RUN cd web-ui && npm install
RUN cd web-ui && ./build-prod.sh

RUN curl -sSL https://get.haskellstack.org/ | sh

RUN cd haskell-server && stack setup && stack build
