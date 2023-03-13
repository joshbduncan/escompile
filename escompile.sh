#!/bin/bash

# ExtendScript Compiler

# Copyright 2023 Josh Duncan
# https://joshbduncan.com

# See README.md for more info

# This script is distributed under the MIT License.
# See the LICENSE file for details.

VERSION=0.3.0

function show_help {
    printf "usage: %s [-h] file\n\n" "${0##*/}"
    printf "Compile modular ExtendScripts into a single human readable JSX file.\n\n"
    printf "positional arguments:\n"
    printf "  file        Path of script file to compile from.\n\n"
    printf "options:\n"
    printf "  -h, --help  Print this help message.\n"
}

# check to make sure file was provided
if [[ $# -eq 0 ]]; then
    printf "usage: %s [-h] file\n" "${0##*/}" >&2
    printf "%s: error: the following arguments are required: file\n" "${0##*/}" >&2
    exit 1
fi

# iterate over provided arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit
            ;;
        --version)
            echo $VERSION
            exit
            ;;
        --) # End of all options.
            shift
            break
            ;;
        -?*)
            printf "usage: %s [-h] file\n" "${0##*/}" >&2
            printf "%s: error: unrecognized arguments: %s\n" "${0##*/}" "$1" >&2
            exit 2
            ;;
        *) # Default case: No more options, so break out of the loop.
            break
    esac
    shift
done

# check to make sure provided file exists
if [[ ! -f "$1" ]]; then
    >&2 echo "$1: No such file."
    exit 1
fi

# read file into variable
DATA=$(<"$1")

# get the base directory of the script file being processed
BASE_DIR=$(dirname "$1")

# set up and array to hold the include paths
INCLUDE_PATHS=( )

while [[ $DATA =~ (\#|\@)include ]]; do
    # keep iterating over any include statements until no more exist
    # this allows support for nested imports (import within imports)
    while read -r LINE ; do
        # create an escaped version of the line for later substitution
        LINE_ESCAPED=$(printf '%s\n' "$LINE" | sed -e 's/[]\/$*.^[]/\\&/g');

        # extract all `includepath` statements and add them to the `INCLUDE_PATHS` array
        if [[ $LINE =~ (\#|\@)includepath ]]; then
            # extract just the value
            FOLDER=$(sed -n -e 's/^.*includepath[[:blank:]]//p' <<< "$LINE" | tr -d \"\')
            # if includepath had multiple entries split them apart
            if [[ $FOLDER =~ ";" ]]; then
                IFS=";" read -r -a FOLDERS <<< "$FOLDER"
                INCLUDE_PATHS+=( "${FOLDERS[@]}" )
            else
                INCLUDE_PATHS+=( "$FOLDER" )
            fi
            # delete the include statement from `$DATA`
            DATA=$(grep -v "$LINE_ESCAPED" <<< "$DATA")
        else
            # substitute include file data into main script

            # extract just the path value
            FPATH=$(sed -n -e 's/^.*include[[:blank:]]//p' <<< "$LINE" | tr -d \"\')

            # if an absolute path was not specified look through INCLUDE_PATHS
            if [[ ! -f $FPATH ]]; then
                # check in all of the `includepath` paths
                for INCLUDE_PATH in "${INCLUDE_PATHS[@]}"; do
                    # if file is found at current include path break
                    if [[ -f "$BASE_DIR/$INCLUDE_PATH/$FPATH" ]]; then
                        FPATH="$BASE_DIR/$INCLUDE_PATH/$FPATH"
                        break
                    fi
                done
            fi

            # if $FPATH was a valid path, cat that file out
            if [[ -f "$FPATH" ]]; then
                # get the leading whitespace for the include line
                WS=$(grep -o "^[[:blank:]]*" <<< "$LINE")

                # pad the include file data with matching whitespace (non-blank line)
                FDATA=$(sed -e "s/^./$WS&/" "$FPATH")

                # escape the include file data and substitute it for the statement
                FDATA_ESCAPED=$(printf '%s\n' "$FDATA" | sed 's,[\/&],\\&,g;s/$/\\/')
                FDATA_ESCAPED=${FDATA_ESCAPED%?}

                # shellcheck disable=SC2001
                DATA=$(sed "s/$LINE_ESCAPED/$FDATA_ESCAPED/" <<< "$DATA")

            else
                >&2 echo "[error]: '$VAL': No such file."
                exit 1

            fi
            continue
        fi
    done < <(grep -E "^.*\#|\@include" <<< "$DATA")
done

echo "$DATA"
