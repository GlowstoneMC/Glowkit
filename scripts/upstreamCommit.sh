#!/usr/bin/env bash
(
set -e
PS1="$"

function changelog() {
    base=$(git ls-tree HEAD $1  | cut -d' ' -f3 | cut -f1)
    cd $1 && git log --oneline ${base}..HEAD -- patches/api
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
