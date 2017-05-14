#!/usr/bin/env bash

(
set -e
PS1="$"
basedir="$(cd "$1" && pwd -P)"
workdir="$basedir/work"

function update {
    cd "$workdir/$1"
    git fetch && git reset --hard origin/$2
    cd ../
    git add $1
}

update Bukkit master
update Spigot master
update Paper pre/1.12

)
