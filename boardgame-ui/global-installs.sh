#!/bin/sh

# Install some packages globally.

npm install -g eslint 
npm install -g jsdoc
npm install -g serve      # Node server for testing the production build.

# Allow automatic merge of package-lock.json to avoid build failures
# when npm updates this file.
npx npm-merge-driver install --global

# output:
# npm-merge-driver: npm-merge-driver installed to `git config --global` 
# and /Users/azadbolour/.config/git/attributes

