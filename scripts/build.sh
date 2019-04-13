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
    (cd "$basedir/Glowkit-Patched" && mvn clean package install)
fi
) || exit 1
