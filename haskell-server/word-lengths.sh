#!/bin/sh

#
# Count words by length.
#

awk '{ print length($0); }' $1 | sort -n | uniq -c
