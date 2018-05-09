#!/bin/sh -x

#
# Sanity check the environment and the source tree.
#
. ../prepare.sh

#
# Must 'test' for resources in the conf directory to be copied to the classpath.
#
sbt compile 'test'

