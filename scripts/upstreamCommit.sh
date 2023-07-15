#!/usr/bin/env bash
(
set -e
PS1="$"

function changelog() {
    base=$(git ls-tree HEAD $1  | cut -d' ' -f3 | cut -f1)
    current=$(cd $1 && git rev-parse HEAD)
    msg=$(cd $1 && git --no-pager log --oneline ${base}..${current})
    echo ${msg:-"Reverting from ${base} to ${current}"}
}
paper=$(changelog work/Paper)

updated=""
logsuffix=""
if [ ! -z "$paper" ]; then
    logsuffix="$logsuffix\n\nPaper Changes:\n$paper"
    if [ -z "$updated" ]; then updated="Paper"; else updated="$updated/Paper"; fi
fi

if [ -z "$updated" ]; then
  exit 0
fi

log="${UP_LOG_PREFIX}Updated Upstream ($updated)\n\n${logsuffix}"

echo -e "$log" | git commit -F -

) || exit $?
