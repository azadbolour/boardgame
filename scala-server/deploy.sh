#!/bin/sh

# Locally deploy play executable to the dist directory.

# TODO. Input parameter for deployDir.
deployDir=dist
projectDir=`pwd`
outDir=${projectDir}/target/universal

sbt dist

mkdir -p $deployDir
cd $deployDir
rm -rf scala-server-1.0/
unzip $outDir/scala-server-1.0.zip
cd scala-server-1.0
mkdir dict
cp ${projectDir}/dict/*.txt dict/
