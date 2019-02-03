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

update Bukkit version/1.12.2
update Spigot version/1.12.2
update Paper ver/1.12.2

)
