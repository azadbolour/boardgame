#!/bin/sh

# Generate jsdoc documents, 

#
# TODO. Streamline javadoc and only generate docs for exported methods.
# http://usejsdoc.org/
#

jsdoc -P package.json -r src -d jsdoc
