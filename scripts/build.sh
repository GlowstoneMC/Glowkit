#!/usr/bin/env bash

(
set -e
basedir="$(cd "$1" && pwd -P)"

(git submodule update --init && ./scripts/applyPatches.sh "$basedir") || (
	echo "Failed to build Glowkit"
	exit 1
) || exit 1
if [ "$2" == "--jar" ]; then
	(cd Glowkit-Patched && mvn clean install)
fi
)
