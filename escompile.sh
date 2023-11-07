#!/bin/bash

# ExtendScript Compiler

# Copyright 2023 Josh Duncan
# https://joshbduncan.com

# See README.md for more info

# This script is distributed under the MIT License.
# See the LICENSE file for details.

# set -x
set -Eeuo pipefail

VERSION="0.3.5"
FPATH=""

# set usage options
USAGE_OPTS="[-h] [--version] [FILE]"
usage() {
    printf "usage: %s %s\n" "${0##*/}" "$USAGE_OPTS" >&2
}

# set help menu
help() {
    cat <<EOF
usage: ${0##*/} $USAGE_OPTS

Compile modular ExtendScripts into a single human readable JSX file.

Arguments:
  [FILE]         Path of script file to compile from.

Options:
  -h, --help     Print this help message.
      --version  Print version.
EOF
    exit
}

version() {
    printf "%s %s\n" "${0##*/}" "$VERSION"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | -\? | --help)
            help
            ;;
        --version)
            version
            exit
            ;;
        --) # End of args.
            shift
            break
            ;;
        -?*)
            usage
            printf "%s: error: unrecognized arguments: %s\n" "${0##*/}" "$1" >&2
            exit 2
            ;;
        *)
            # check to make sure provided file exists
            if [[ ! -f "$1" ]]; then
                printf "%s: error: No such file: '%s'\n" "${0##*/}" "$1" >&2
                exit 1
            fi
            FPATH="$1"
            break
            ;;
        esac
        shift
    done

    # check to make sure a file was provided
    if [ -z "$FPATH" ]; then
        usage
        printf "%s: error: the following arguments are required: file\n" "${0##*/}" >&2
        exit 1
    fi

    return 0
}

# parse script arguments
parse_args "$@"

# read file into variable
DATA=$(<"$FPATH")

# get the base directory of the script file being processed
BASE_DIR=$(dirname "$FPATH")
cd "$BASE_DIR"

# set up and array to hold the include paths
INCLUDE_PATHS=()

while [[ $DATA =~ (\#|\@)include ]]; do
    # keep iterating over any include statements until no more exist
    # this allows support for nested imports (import within imports)
    while IFS= read -r LINE; do
        # create an escaped version of the line for later substitution
        LINE_ESCAPED=$(printf '%s\n' "$LINE" | sed -e 's/[]\/$*.^[]/\\&/g')

        # extract all `includepath` statements and add them to the `INCLUDE_PATHS` array
        if [[ $LINE =~ (\#|\@)includepath ]]; then
            # extract just the value
            FOLDER=$(sed -n -e 's/^.*includepath[[:blank:]]//p' <<<"$LINE" | tr -d \"\')
            # if includepath had multiple entries split them apart
            if [[ $FOLDER =~ ";" ]]; then
                IFS=";" read -r -a FOLDERS <<<"$FOLDER"
                INCLUDE_PATHS+=("${FOLDERS[@]}")
            else
                INCLUDE_PATHS+=("$FOLDER")
            fi
            # delete the include statement from `$DATA`
            DATA=$(grep -v "$LINE_ESCAPED" <<<"$DATA")
        else
            # substitute include file data into main script

            # extract just the path value
            FPATH=$(sed -n -e 's/^.*include[[:blank:]]//p' <<<"$LINE" | tr -d \"\')

            # if an absolute path was not specified look through INCLUDE_PATHS
            if [[ ! -f $FPATH ]]; then
                # check in all of the `includepath` paths
                for INCLUDE_PATH in "${INCLUDE_PATHS[@]}"; do
                    # if file is found at current include path break
                    if [[ -f "$INCLUDE_PATH/$FPATH" ]]; then
                        FPATH="$INCLUDE_PATH/$FPATH"
                        break
                    fi
                done
            fi

            # if $FPATH was a valid path, cat that file out
            if [[ -f "$FPATH" ]]; then
                # get the leading whitespace for the include line
                WS=$(grep -o "^[[:blank:]]*" <<<"$LINE")

                # pad the include file data with matching whitespace (non-blank line)
                FDATA=$(sed -e "s/^./$WS&/" "$FPATH")

                # escape the include file data and substitute it for the statement
                FDATA_ESCAPED=$(printf '%s\n' "$FDATA" | sed 's,[\/&],\\&,g;s/$/\\/')
                FDATA_ESCAPED=${FDATA_ESCAPED%?}

                # shellcheck disable=SC2001
                DATA=$(sed "s/$LINE_ESCAPED/$FDATA_ESCAPED/" <<<"$DATA")

            else
                echo >&2 "[error]: '$FPATH': No such file."
                exit 1

            fi
            continue
        fi
    done < <(grep -E "^.*\#|\@include" <<<"$DATA")
done

echo "$DATA"
