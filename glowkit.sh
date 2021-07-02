#!/usr/bin/env bash
# Heavily based on the paper tool (thanks Paper!)
# https://github.com/PaperMC/Paper

# resolve shell-specifics
case "$(echo "$SHELL" | sed -E 's|/usr(/local)?||g')" in
    "/bin/zsh")
        RCPATH="$HOME/.zshrc"
        SOURCE="${BASH_SOURCE[0]:-${(%):-%N}}"
    ;;
    *)
        RCPATH="$HOME/.bashrc"
        if [[ -f "$HOME/.bash_aliases" ]]; then
            RCPATH="$HOME/.bash_aliases"
        fi
        SOURCE="${BASH_SOURCE[0]}"
    ;;
esac

# get base dir regardless of execution location
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SOURCE=$([[ "$SOURCE" = /* ]] && echo "$SOURCE" || echo "$PWD/${SOURCE#./}")
basedir=$(dirname "$SOURCE")
gitcmd="git -c commit.gpgsign=false"

source "$basedir/scripts/functions.sh"

failed=0
case "$1" in
    "rb" | "rbp" | "rebuild")
    (
        set -e
        cd "$basedir"
        scripts/rebuildPatches.sh "$basedir" || exit 1
    ) || failed=1
    ;;
    "p" | "patch")
    (
        set -e
        cd "$basedir"
        scripts/build.sh "$basedir" || exit 1
    ) || failed=1
    ;;
    "j" | "jar")
    (
        set -e
        cd "$basedir"
        scripts/build.sh "$basedir" "--jar" || exit 1
    ) || failed=1
    ;;
    "u" | "up" | "upstream")
    (
        cd "$basedir"
        scripts/upstreamMerge.sh "$basedir" "$2"
    )
    ;;
    "cu" | "commitup" | "commitupstream" | "upc" | "upcommit" | "upstreamcommit")
    (
        cd "$basedir"
        shift
        scripts/upstreamCommit.sh "$@"
    )
    ;;
    "r" | "root")
        cd "$basedir"
    ;;
    "a" | "api")
        cd "$basedir/Glowkit"
    ;;
    "c" | "clean")
        rm -rf "$basedir/Glowkit"
        rm -rf "$basedir/work"
        echo "Cleaned build files"
    ;;
    "e" | "edit")
        case "$2" in
            "c" | "continue")
            cd "$GLOWKIT_LAST_EDIT"
            unset GLOWKIT_LAST_EDIT
            (
                set -e

                $gitcmd add .
                $gitcmd commit --amend
                $gitcmd rebase --continue

                cd "$basedir"
                scripts/rebuildPatches.sh "$basedir"
            )
            cd "$basedir"
            ;;
            *)
            export GLOWKIT_LAST_EDIT="$basedir/Glowkit"
            cd "$basedir/Glowkit"
            (
                set -e

                glowkitstash
                $gitcmd rebase -i upstream/upstream
                glowkitunstash
            )
            ;;
        esac
    ;;
    "setup")
        if [[ -f "$RCPATH" ]] ; then
            NAME="glowkit"
            if [[ ! -z "${2+x}" ]] ; then
                NAME="$2"
            fi
            (grep "alias $NAME=" "$RCPATH" > /dev/null) && (sed -i "s|alias $NAME=.*|alias $NAME='. $SOURCE'|g" "$RCPATH") || (echo "alias $NAME='. $SOURCE'" >> "$RCPATH")
            alias "$NAME=. $SOURCE"
            echo "You can now just type '$NAME' at any time to access the glowkit tool."
        else
          echo "We were unable to setup the glowkit build tool alias: $RCPATH is missing"
        fi
    ;;
    *)
        echo "Glowkit build tool command. This provides a variety of commands to build and manage the Glowkit build"
        echo "environment. For all of the functionality of this command to be available, you must first run the"
        echo "'setup' command. View below for details. For essential building and patching, you do not need to do the setup."
        echo ""
        echo " Normal commands:"
        echo "  * rb, rebuild       | Rebuild patches, can be called from anywhere."
        echo "  * p, patch          | Apply all patches to the project without building it. Can be run from anywhere."
        echo "  * j, jar            | Apply all patches and build the project. Can be run from anywhere."
        echo "  * u, up, upstream   | Updates the submodules used by Glowkit to their latest upstream versions."
        echo ""
        echo " These commands require the setup command before use:"
        echo "  * r, root           | Change directory to the root of the project."
        echo "  * a. api            | Move to the Glowkit directory."
        echo "  * e, edit           | Use to edit a specific patch."
        echo "                      | Use the argument \"continue\" after the changes have been made"
        echo "                      | to finish and rebuild patches. Can be called from anywhere."
        echo ""
        echo "  * setup             | Add an alias to $RCPATH to allow full functionality of this script. Run as:"
        echo "                      |     . ./glowkit.sh setup"
        echo "                      | After you run this command you'll be able to just run 'glowkit' from anywhere."
        echo "                      | The default name for the resulting alias is 'glowkit', you can give an argument to override"
        echo "                      | this default, such as:"
        echo "                      |     . ./glowkit.sh setup example"
        echo "                      | Which will allow you to run 'example' instead."
    ;;
esac

unset RCPATH
unset SOURCE
unset basedir
unset -f color
unset -f colorend
unset -f glowkitstash
unset -f glowkitunstash
if [[ "$failed" == "1" ]]; then
	unset failed
	false
else
	unset failed
	true
fi
