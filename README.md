
# Board Game Application

## Versions

Version 0.2.0. Beta 1. Released.
Version 0.5.0 development started.

## The Board Game

The board game is in the same genre as other well-known crossword games. 
The detailed rules will not be documented here as they are subject to change.
But they are pretty easy to discern by playing the game.

See the [project web site](http://www.bolour.com/boardgame/index.html).

## Scope

I started this application as a means of learning real-world Haskell.
Of course, the board game needed at least a web user interface, and for 
that I decided to use React, and specifically React drap and drop.
Like Haskell, React and React DND were also new to me at the time.

My initial aim in this project is to demonstrate a production-quality
application in Haskell. I like Haskell a lot as a language. But because its IDE
tooling is not on a par with more mainstream languages, I am less efficient in
it.  For this reason, I started programming the game server in Scala as well.
Because of its better IDE support, I find I am quite a bit more efficient in
Scala than in Haskell. 

At this time, development of both servers in this project proceeds in lock step.
And the two sub-projects cross fertilize each other and help in getting a 
better grasp of both languages and their idioms and patterns of usage.

The first implementation is being developed on the MAC OS/X 10.9+, deployed on
Linux Amazon EC2 instance, and accessed through Chrome version 60+ on the MAC. 

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

## Working with the Client API Library

The java-client sub-project uses a standard Maven pom project structure. See
build.sh in the java-client directory.

See sample test class: com.bolour.boardgame.integration.BasicGameClientTest.

The java client code is based on Java 8.

## Benchmarking

The benchmark sub-project is written in Java, and uses a standard Maven pom
structure. See build.sh and run.sh in the benchmark directory. To configure the
benchmark, copy benchmark-config.yml and edit as appropriate. Then start the
benchmark giving it your copy as a parameter.

The benchmark is based Java 8.

### Performance

Following are benchmark results for the two servers:

```
machine: MAC-Book Pro i7 2.8GHz 4-core
dictionary: 114K words
users: 75
average think time: 100 millis

haskell: average latency of a machine move: 270 milliseconds
scala: average latency of a machine move: 59 milliseconds
```

Since human interactions have much longer think times, scaling to hundreds of
concurrent games on a single machine should not be an issue. Beyond that the
application is easily amenable to horizontal scaling. So the bottleneck may end
up being the database. But at this stage of teh project, time very high
scalability is beyond our scope.

## Github Site

http://www.bolour.com/boardgame/index.html

## General Conventions

- For trivial code cleanup and unimportant changes with minimal impact to users,
  add a TODO comment to at the right places in the source code. Do not clutter
  the issues list and the backlog with trivial issues.

## Branches of Development

- master - stable version
- dev - development version - not necessarily stable - off master
- others - temporary feature branches

## Credits

Thanks to Eitan Chatav for advice on Haskell development.

Thanks to Allen Haim for advice on Javascript development.

Thanks to Dennis Allard for hosting the application at oceanpark.com.

English dictionary - Moby project. See:

    - http://www.gutenberg.org/files/3201/3201.txt
    - http://www.gutenberg.org/files/3201/files/CROSSWD.TXT.
 
## Contact

azadbolour

bolour.com

