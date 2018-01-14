#!/bin/sh

#
# Package the play application.
#
# Prerequisite. The UI bundle should be in public/javascripts folder.
#
# The package will be placed in target/universal/scala-server-1.0.zip
#

sbt clean compile "test" dist

