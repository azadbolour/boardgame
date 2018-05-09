
# Board Game Application

## Versions

Version 0.9.1 beta.

## The Board Game

The board game is in the same genre as other well-known crossword games:
drag and drop letters to form words on a square board.

See the [project web site](http://www.bolour.com/boardgame/index.html).

## Scope

This project is intended as an test bed for the development and deployment
of production quality applications by using different programming languages,
their ecosystems, and devops tools.

It defines a board game API, and client and server implementations for it.
At this time, the API has two server implementations, one in Haskell and 
one in Scala, and one client implementation, in Javascript using the React 
framework.

For a simple representation of the API, see the Haskell module 
BoardGame.Common.GameApi in teh haskell-server hierarchy.

The first implementation is being developed on the MAC OS/X 10.9+, deployed on
a Linux Amazon EC2 instance, and accessed through modern browsers.

## Sub-Projects

- haskell-server - The game server in Haskell. Exposes a game API through HTTP.

- scala-server - The game server in Scala.

- web-ui - The Javascript/React user interface for the game.

- java-client - A client-side library for accessing the API in Java clients.

- benchmark - A game server benchmark (in Java) simulating concurrent game sessions.

## Getting Started in Development

The steps needed to set up the development and deployment environments for the 
application are scripted in the Dockerfiles used for deployment in the _docker_
directories of haskell-server and scala-server. 

To get started with development follow the same steps listed in the Dockerfiles
on your development machine. You may start by consulting the README.md file in
the docker directory, and then reviewing the Dockerfiles there.

For Java development (java-client and benchmark sub-projects) you'll also 
need to install maven.

For postgres installation on ubuntu see: 

https://www.postgresql.org/download/linux/ubuntu/

After cloning the repository:

* `cp branch.sh.template branch.sh` - this is the environment-setting script for
  development
* edit _branch.sh_ as appropriate for your minimal environment
* set your environment: `. branch.sh`

Utility libraries used by the Java sub-projects are hosted on _jCenter_ 
(https://jcenter.bintray.com). Make sure your maven settings.xml in $HOME/.m2 
configures that repository in its profiles. The source for these libraries 
in open at my github (azadbolour).

## Dictionaries

Please refer to the README file in the dict/ directory. One issue to be
aware of is that diectionaries are preprocessed to a list of _masked words_, 
words with blank holes in them. Because masked words pre-processing is
time-consuming, the masked words file is saved in git, but in zipped form 
because it is too large for github. 

At this time, unzipping this file for the first time, and maintaining it in
case the dictionary is updated remains a manual step. Use the script
dict/unzip-masked-words.sh.

## Working with the Client API Library

The java-client sub-project uses a standard Maven pom project structure. See
build.sh in the java-client directory.

See sample test class: com.bolour.boardgame.integration.BasicGameClientTest.

The java client code is based on Java 8.

## Benchmarking

The benchmark sub-project is written in Java, and uses a standard Maven pom
structure. See build.sh and run.sh in the benchmark directory. To configure the
benchmark, copy benchmark-config.yml and edit as appropriate. Then start the
benchmark giving it your copy of the config file as a parameter.

The benchmark is based Java 8.

### Performance

Following are some benchmark results for a version of the game circa 
late 2017. Latest performance benchmarks TBD.

```
machine: MAC-Book Pro i7 2.8GHz 4-core
dictionary: 114K words
users: 75
average think time: 100 milliseconds

haskell: average latency of a machine move: 270 milliseconds
scala: average latency of a machine move: 59 milliseconds
```

Since human interactions have much longer think times, scaling to hundreds of
concurrent games on a single machine should not be an issue. Beyond that the
application is easily amenable to horizontal scaling. The bottleneck for very
high scalability may end up being the database. But at this stage of the project
database interactions are de-emphasized, and very high scalability is beyond our
scope.

## Github Site

http://www.bolour.com/boardgame/index.html

## General Conventions

- For trivial code cleanup and unimportant changes with minimal impact to users,
  TODO comments are added at the right places in the source code. The backlog
  lists larger tasks or tasks that cannot yet be localized in the code base.

## Branches of Development

- master - stable version
- dev - development version - not necessarily stable - off master
- others - temporary feature branches

## Credits

Thanks to Eitan Chatav for advice on Haskell development.

Thanks to Allen Haim for advice on Javascript development.

Thanks to Dennis Allard for hosting the application at oceanpark.com.

Thanks to the Moby project for the English dictionary:

    - http://www.gutenberg.org/files/3201/3201.txt
    - http://www.gutenberg.org/files/3201/files/CROSSWD.TXT.
 
## Contact

azadbolour

bolour.com

