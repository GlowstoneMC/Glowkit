#!/usr/bin/env bash

(
set -e
basedir="$(cd "$1" && pwd -P)"
gitcmd="git -c commit.gpgsign=false"

($gitcmd submodule update --init && ./scripts/applyPatches.sh "$basedir") || (
    echo "Failed to build Glowkit"
    exit 1
) || exit 1
if [ "$2" == "--jar" ]; then
(
  cd "$basedir/Glowkit-Patched" &&\
  mvn -T 1C -B clean package install &&\
  find . -regextype grep -regex '.*/glowkit.*\([0-9]\|SNAPSHOT\)-shaded\.jar' | xargs -i cp {} glowkit.jar
)    
fi
) || exit 1
