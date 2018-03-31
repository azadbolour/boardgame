#!/bin/sh -x

#
# Make sure needed resources are available in form required.
#
./pre-build.sh

#
# Must 'test' for resources in the conf directory to be copied to the classpath.
#
sbt compile 'test'

