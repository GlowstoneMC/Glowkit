#!/usr/bin/env bash

(
PS1="$"
basedir="$(cd "$1" && pwd -P)"
workdir="$basedir/work"
gitcmd="git -c commit.gpgsign=false"
applycmd="$gitcmd am --3way --ignore-whitespace"
# Windows detection to workaround ARG_MAX limitation
windows="$([[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]] && echo "true" || echo "false")"

echo "Rebuilding Forked projects.... "

function applyPatch {
    what=$1
    what_name=$(basename "$what")
    target=$2
    branch=$3

    cd "$basedir/$what"
    $gitcmd fetch
    $gitcmd branch -f upstream "$branch" >/dev/null

    cd "$basedir"
    if [ ! -d  "$basedir/$target" ]; then
        $gitcmd clone "$what" "$target"
    fi
    cd "$basedir/$target"

    echo "Resetting $target to $what_name..."
    $gitcmd remote rm upstream > /dev/null 2>&1
    $gitcmd remote add upstream "$basedir/$what" >/dev/null 2>&1
    $gitcmd checkout master 2>/dev/null || $gitcmd checkout -b master
    $gitcmd fetch upstream >/dev/null 2>&1
    $gitcmd reset --hard upstream/upstream

    echo "  Applying patches to $target..."

    statusfile=".git/patch-apply-failed"
    rm -f "$statusfile"
    $gitcmd am --abort >/dev/null 2>&1

    # Special case Windows handling because of ARG_MAX constraint

    if [[ $target == "Paper-API" ]]; then
        patches="$basedir/patches/api/"*.patch
    else
        patches="$basedir/${what_name}-Patches/"*.patch
    fi

    if [[ $windows == "true" ]]; then
        echo "  Using workaround for Windows ARG_MAX constraint"
        find $patches -print0 | xargs -0 $applycmd
    else
        $applycmd $patches
    fi

    if [ "$?" != "0" ]; then
        echo 1 > "$statusfile"
        echo "  Something did not apply cleanly to $target."
        echo "  Please review above details and finish the apply then"
        echo "  save the changes with rebuildPatches.sh"

        # On Windows, finishing the patch apply will only fix the latest patch
        # users will need to rebuild from that point and then re-run the patch
        # process to continue
        if [[ $windows == "true" ]]; then
            echo ""
            echo "  Because you're on Windows you'll need to finish the AM,"
            echo "  rebuild all patches, and then re-run the patch apply again."
            echo "  Consider using the scripts with Windows Subsystem for Linux."
        fi

        exit 1
    else
        rm -f "$statusfile"
        echo "  Patches applied cleanly to $target"
    fi
}

# Move into spigot dir
cd "$workdir/Spigot"
basedir=$(pwd)
# Apply Spigot
(
    applyPatch ../Bukkit Spigot-API HEAD
) || (
    echo "Failed to apply Spigot Patches"
    exit 1
) || exit 1
# Move out of Spigot
basedir="$1"
cd "$basedir"

# Move into paper dir
cd "$workdir/Paper"
basedir=$(pwd)
# Apply paper
(
    applyPatch "../Spigot/Spigot-API" Paper-API HEAD
) || (
    echo "Failed to apply Paper Patches"
    exit 1
) || exit 1
# Move out of Paper
basedir="$1"
cd "$basedir"

# Apply glowkit
cd "$basedir"
(
    applyPatch "work/Paper/Paper-API" Glowkit HEAD
) || (
    echo "Failed to apply Glowkit Patches"
    exit 1
) || exit 1
) || exit 1
