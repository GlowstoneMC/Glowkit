#!/usr/bin/env bash

(
set -e
PS1="$"
basedir="$(cd "$1" && pwd -P)"
workdir="$basedir/work"
gitcmd="git -c commit.gpgsign=false"

updated="0"
function getRef {
    git ls-tree $1 $2  | cut -d' ' -f3 | cut -f1
}
function update {
    cd "$workdir/$1"
    $gitcmd fetch && $gitcmd clean -fd && $gitcmd reset --hard $2
    refRemote=$(git rev-parse HEAD)
    cd ../
    $gitcmd add --force $1
    refHEAD=$(getRef HEAD "$workdir/$1")
    echo "$1 $refHEAD - $refRemote"
    if [ "$refHEAD" != "$refRemote" ]; then
        export updated="1"
    fi
}

#update Paper origin/master
update Paper "1.19.4"

if [ "$updated" == "1" ]; then
    cd "$basedir"
    ./gradlew cleanCache || exit 1 # todo: Figure out why this is necessary
    ./gradlew applyApiPatches -Dpaperweight.debug=true || exit 1
    ./gradlew rebuildApiPatches || exit 1
    $gitcmd add --force "Paper-API-Patches"
fi
)
