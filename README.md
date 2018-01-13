
# Board Game Application

## Versions

Version 0.2.0. Beta 1. Released.
Version 0.5.0 development started.

## The Board Game

The board game is is in the same genre as other well-known crossword games. 
The detailed rules will not be documented here as they are subject to change.
But they are pretty easy to discern by actually playing the game.

See the [project web site](http://www.bolour.com/boardgame/index.html) for details.

## Scope

I started this application as a means of learning real-world Haskell.
Of course, the board game needed at least a web user interface, and for 
that I decided to use React, and specifically React drap and drop.
Like Haskell, React and React DND were also new to me at the time.

My aim in this project is to demonstrate a production-quality application in
Haskell. But as a single developer, I can only support the application in a few
client and server configurations. The first implementation is being developed on
the MAC OS/X 10.9+, deployed on Linux Amazon EC2 instance, and accessed
through Chrome version 60+ on the MAC. It has been tested with 50 concurrent
games. 

## Sub-Projects

- haskell-server - The game server in Haskell. Exposes a game API through HTTP.

- web-ui - The Javascript/React user interface for the game.

- java-client - A client-side library for accessing the API in Java clients.

- benchmark - A game server benchmark (in Java) simulating concurrent game sessions.

## Getting Started in Development

The steps needed to set up the development and deployment environments for the 
application are scripted in the Dockerfiles used for deployment in the _docker_
directory. 

To get started with the development othe haskell-server and the web-ui, 
follow the same steps listed in the Dockerfiles on your development machine.
You may start by consulting the README.md file in the docker directory, and then 
reviewing the Dockerfiles there.

For Java development (java-client and benchmark sub-projects) you'll also 
need to install maven set up your Java environment. 

For postgres installation on ubuntu see: 

https://www.postgresql.org/download/linux/ubuntu/

After cloning the repository:

* `cp branch.sh.template branch.sh` - this is the environment-setting script for
  development
* edit _branch.sh_ as appropriate for your minimal environment
* set your environment: `. branch.sh`

Utility libraries used by the Java sub-projects are hosted on _jCenter_ 
(https://jcenter.bintray.com). Make sure your maven settings.xml in $HOME/.m2 
configures that repository in its profiles.

## Working with the Client API Library

The java-client sub-project uses a standard Maven pom project structure. See
build.sh in the java-client directory.

See sample test class: com.bolour.boardgame.integration.BasicGameClientTest.

Note. The client library depends on the com.bolour.util.util library. As of this
writing this dependency is not available from public maven repositories (an
oversight to be fixed shortly). For now, you may clone
https://github.com/azadbolour/util.git and build it locally.

Note. The java client code uses Java 8.

## Benchmarking

The benchmark sub-project is written in Java, and uses a standard Maven pom
structure. See build.sh and run.sh in the benchmark directory. To configure the
benchmark, copy benchmark-config.yml and edit as appropriate. Then start the
benchmark giving it your copy as a parameter.

Note. The benchmark depends on the artifacts com.bolour.util.util, and
com.bolour.benchmark.base. Until the dependency jar files make it to 
public places (shortly) clone https://github.com/azadbolour/util.git
and https://github.com/azadbolour/benchmark.git and build them locally.

Note. The benchmark code uses Java 8.

### Performance

Following is a benchmark result after performance improvements.

```
machine: MAC-Book Pro i7 2.8GHz 4-core
dictionary: 235K words
users: 50
average think time: 15 seconds

resulting average latency of a machine move: 20 milliseconds
```

CPUs were only 10% busy. 

Scalability to large numbers of concurrent users is beyond the initial scope of this 
project. 

## Github Site

http://www.bolour.com/boardgame/index.html

## General Conventions

- For trivial code cleanup and unimportant changes with minimal impact to users,
  add a TODO comment to at the right places in the source code. Do not clutter
  the issues list and the backlog with trivial issues.

## Branches of Development

- master - stable version
- dev - development version - not necessarily stable - off master
- scala-dev - feature branch for development of scala server - off dev
- others - temporary feature branches

## Credits

Thanks to Eitan Chatav for advice on Haskell development.

Thanks to Allen Haim for advice on Javascript development.

Thanks to Dennis Allard for hosting the application at oceanpark.com.

Test Dictionary - http://www-personal.umich.edu/~jlawler/wordlist.html
compiled by John Lawler and put in the public domain with no restrictions
of use.

## Contact

azadbolour

bolour.com

