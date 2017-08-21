#!/bin/sh

stack clean
stack build --profile 
-- stack build --profile 2>&1 >/dev/null | head -30

