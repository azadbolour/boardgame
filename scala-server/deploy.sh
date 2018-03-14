#!/bin/sh

#
# Locally deploy the play executable to the dist directory.
#
# Prerequisites. Distribution package built in target/universal folder. See package.sh.
#
# The distribution is deployed to dist/scala-server-1.0
#

# TODO. Input parameter for deployDir.
deployDir=dist
projectDir=`pwd`
outDir=${projectDir}/target/universal

# TODO. Get version from build.sbt.
version=0.9.0
server=scala-server-${version}

echo "deploying board game scala server from ${outDir} to ${deployDir}"
mkdir -p $deployDir
cd $deployDir
rm -rf ${server}/
unzip $outDir/${server}.zip
cd ${server}
mkdir dict
cp ${projectDir}/dict/en-words.txt dict/en-words.txt

echo "preprocessing masked words"
maskedWordsFile=${deployDir}/${server}/dict/en-masked-words.txt
# TODO. maxBlanks should be a deployment configuration parameter.
maxBlanks=3
cd ${projectDir}
# Preprocessing masked words is time-consuming. No reral need to redo it in deployments.
if [ ! -e ${maskedWordsFile} ]; then
  ./preprocess-masked-words.sh dict/en-words.txt ${maskedWordsFile} ${maxBlanks}
fi
echo "deployed"
echo "server dictionary directory"
ls -lt ${deployDir}/${server}/dict

