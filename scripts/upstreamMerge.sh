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
    ($gitcmd fetch && $gitcmd clean -fd) || exit $?
    if [ $3 == "1" ]; then
        $gitcmd switch --detach $2 || exit $?
    else
        $gitcmd reset --hard $2 -- || exit $?
    fi
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
#update Paper origin/ver/1.19.4
update Paper f9dc371fd8c56f1ad1359fc3bf1f7a40921ec66f 1

if [ "$updated" == "1" ]; then
    cd "$basedir"
    ./gradlew cleanCache || exit $?
    ./gradlew applyApiPatches -Dpaperweight.debug=true || exit $?
    ./gradlew rebuildApiPatches || exit $?
    $gitcmd add --force "Paper-API-Patches"
fi
) || exit $?
