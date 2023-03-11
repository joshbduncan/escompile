#!/bin/bash

# ExtendScript Compiler

# Copyright 2023 Josh Duncan
# https://joshbduncan.com

# See README.md for more info

# This script is distributed under the MIT License.
# See the LICENSE file for details.

VERSION=0.2.3

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
while :; do
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

# get the base directory of the script file being processed
BASE_DIR=$(dirname "$1")

# set up and array to hold the include paths
INCLUDE_PATHS=( )

# read through the script line by line
while IFS= read -r LINE || [ -n "$LINE" ]; do

    # if `includepath`` statement split the specified paths into an array and add to INCLUDE_PATHS
    if [[ $LINE =~ (\#|\@)includepath ]]; then
        # extract just the value
        FOLDER=$(sed -n -e 's/^.*includepath[[:blank:]]//p' <<< "$LINE" | tr -d \"\')
        # if includepath had multiple entries split them apart
        if [[ $FOLDER =~ ";" ]]; then
            # FOLDERS=$(tr ';' ' ' <<< "$FOLDER")
            IFS=";" read -r -a FOLDERS <<< "$FOLDER"
            INCLUDE_PATHS+=( "${FOLDERS[@]}" )
        else
            INCLUDE_PATHS+=( "$FOLDER" )
        fi
        continue
    fi

    # if `include` file statement try and find that file in `includepath` paths
    if [[ $LINE =~ (\#|\@)include ]]; then
        FP=""
        # extract just the value
        FILE=$(sed -n -e 's/^.*include[[:blank:]]//p' <<< "$LINE" | tr -d \"\')

        # if an absolute path was specified
        if [[ $FILE =~ ^/ ]] && [ -f "$FILE" ]; then
            FP=$FILE
        else

            # check in all of the `includepath` paths
            for INCLUDE_PATH in "${INCLUDE_PATHS[@]}"; do
                # if file is found at current include path break
                if [[ -f "$BASE_DIR/$INCLUDE_PATH/$FILE" ]]; then
                    FP="$BASE_DIR/$INCLUDE_PATH/$FILE"
                    break
                fi
            done

        fi

        # if $FP was a valid path, cat that file out
        if [[ -f "$FP" ]]; then
            # get the leading whitespace for the include line
            WS=$(grep -o "^[[:blank:]]*" <<< "$LINE")

            # pad the include file with matching whitespace (non-blank line)
            sed -e "s/^./$WS&/" "$FP"

            # if include file didn't end with blank line add one
            if [[ ! $(tail -c1 "$FP" | wc -l) -gt 0 ]]; then
                echo
            fi

        else
            >&2 echo "[error]: '$FILE': No such file."
            exit 1

        fi
        continue
    fi

    # if it's just a regular line of code just echo it out
    echo "$LINE"

done < "$1"
