#!/bin/sh

stack build 2>&1 >/dev/null | head -30

