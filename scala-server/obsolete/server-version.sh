#!/bin/sh

grep '^version\s*:=\s*' build.sbt | sed -e 's/version[ ]*:=[ ]*//' -e 's/"//g' -e 's/ //g'
