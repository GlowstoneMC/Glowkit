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

"$basedir"/scripts/requireDeps.sh || exit $?

failed=0
case "$1" in
    "u" | "up" | "upstream")
    (
        cd "$basedir"
        scripts/upstreamMerge.sh "$basedir" "$2"
    ) || exit $?
    ;;
    "cu" | "commitup" | "commitupstream" | "upc" | "upcommit" | "upstreamcommit")
    (
        cd "$basedir"
        shift
        scripts/upstreamCommit.sh "$@"
    ) || exit $?
    ;;
    "r" | "root")
        cd "$basedir"
    ;;
    "a" | "api")
        cd "$basedir/glowkit"
    ;;
    "c" | "clean")
        rm -rf "$basedir/glowkit"
        rm -rf "$basedir/work"
        ./gradlew clean
        ./gradlew cleanCache
        echo "Cleaned build files"
    ;;
    "con" | "continue")
        cd "$basedir/glowkit"
        (
            set -e

            $gitcmd add .
            $gitcmd commit --amend
            $gitcmd rebase --continue

            cd "$basedir"
            ./gradlew rebuildApiPatches
        )
        cd "$basedir"
    ;;
    "e" | "edit")
        cd "$basedir/glowkit"
        (
            set -e

            glowkitstash
            $gitcmd rebase -i upstream/master
            glowkitunstash
        )
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
        echo "  * u, up, upstream     | Updates the submodules used by Glowkit to their latest upstream versions."
        echo "  * upc, upstreamcommit | Creates the correctly-formatted upstream commit after updating upstream."
        echo "  * c, clean            | Removes all generated files."
        echo ""
        echo " These commands require the setup command before use:"
        echo "  * r, root           | Change directory to the root of the project."
        echo "  * a. api            | Move to the glowkit directory."
        echo "  * e, edit           | Use to edit a specific patch."
        echo "  * con, continue     | After the changes have been made with \"edit\", finish and rebuild patches."
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
