#!/usr/bin/env bash
(
set -e
PS1="$"

function changelog() {
    base=$(git ls-tree HEAD $1  | cut -d' ' -f3 | cut -f1)
    cd $1 && git log --oneline ${base}...HEAD
}
bukkit=$(changelog work/Bukkit)
spigot=$(changelog work/Spigot)
paper=$(changelog work/Paper)

updated=""
logsuffix=""
if [ ! -z "$bukkit" ]; then
    logsuffix="$logsuffix\n\nBukkit Changes:\n$bukkit"
    updated="Bukkit"
fi
if [ ! -z "$spigot" ]; then
    logsuffix="$logsuffix\n\nSpigot Changes:\n$spigot"
    if [ -z "$updated" ]; then updated="Spigot"; else updated="$updated/Spigot"; fi
fi
if [ ! -z "$paper" ]; then
    logsuffix="$logsuffix\n\nPaper Changes:\n$spigot"
    if [ -z "$updated" ]; then updated="Paper"; else updated="$updated/Paper"; fi
fi
disclaimer="Upstream has released updates that appears to apply and compile correctly.\nThis update has not been tested by Glowstone and as with ANY update, please do your own testing"

if [ ! -z "$1" ]; then
    disclaimer="$@"
fi

log="${UP_LOG_PREFIX}Updated Upstream ($updated)\n\n${disclaimer}${logsuffix}"

echo -e "$log" | git commit -F -

) || exit 1
