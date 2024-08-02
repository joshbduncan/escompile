#!/usr/bin/env bash

# ExtendScript Compiler - Compile modular ExtendScripts into a single human readable JSX file.

# Copyright 2024 Josh Duncan
# https://joshbduncan.com

# See README.md for more info

# This script is distributed under the MIT License.
# See the LICENSE file for details.

# set -x
set -Eeuo pipefail

script_version="0.5.0"
source_path=""

# set usage options
usage_opts="[-h] [--version] [FILE]"
usage() {
    printf "usage: %s %s\n" "${0##*/}" "$usage_opts" >&2
}

# set help menu
help() {
    cat <<EOF
usage: ${0##*/} $usage_opts

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
    printf "%s %s\n" "${0##*/}" "$script_version"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | -\? | --help) help ;;
        --version) version exit ;;
        --)
            shift
            break
            ;; # end of args.
        -?*)
            usage
            printf "%s: error: unrecognized arguments: %s\n" "${0##*/}" "$1" >&2
            exit 2
            ;;
        *)
            source_path="$1"
            break
            ;;
        esac
        shift
    done

    # check to make sure a file was provided
    if [ -z "$source_path" ]; then
        usage
        printf "%s: error: the following arguments are required: file\n" "${0##*/}" >&2
        exit 1
    fi

    return 0
}

is_in_array() {
    local value="$1"
    local array=("${@:2}")

    for item in "${array[@]}"; do
        if [[ "$item" == "$value" ]]; then
            return 0 # found
        fi
    done

    return 1 # not found
}

get_abs_filename() {
    echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

process_include() {
    # extract the function arguments
    local file="$1"
    local pad="${2:-0}"

    # check if file exists
    if [[ ! -f "$file" ]]; then
        printf "%s: error: No such file: '%s'\n" "${0##*/}" "$file" >&2
        exit 1
    fi

    # track all seen paths to avoid double imports
    local full_path
    full_path=$(get_abs_filename "$file")
    if [[ ${#INCLUDE_PATHS[@]} -gt 0 ]] && is_in_array "$full_path" "${IMPORTED_PATHS[@]}"; then
        printf "%s: warning: File already imported: '%s'\n" "${0##*/}" "$file" >&2
        return
    else
        IMPORTED_PATHS+=("$full_path")
    fi

    # get the base dir of the file
    local base_dir
    base_dir=$(dirname "$file")

    # get the file name
    local file_name
    file_name=$(basename "$file")

    # check for utf-8 bom encoding (https://github.com/joshbduncan/escompile/issues/4)
    if head -c 3 "$file" | grep -q $'\xEF\xBB\xBF'; then
        tmpfile=$(mktemp /tmp/"$file_name".XXXXXX)
        tail -c +4 "$file" >"$tmpfile"
        file="$tmpfile"
    fi

    # build proper padding for current line
    local padding
    padding=$(printf "%*s" "$pad" "")

    # iterate over every line of the file and either process import/includepath statementes, or echo the line
    local arr
    local escaped
    while IFS= read -r line || [[ -n "$line" ]]; do
        # get the leading whitespace for the include line
        local trimmed="${line#"${line%%[![:space:]]*}"}"
        local _pad=$((${#line} - ${#trimmed} + pad))

        if [[ "$line" =~ ^[[:blank:]]*(//@|#)includepath[[:space:]]*(\"|\')(.*)(\"|\') ]]; then
            # read path(s) into array split on ';' incase multiple paths were provided
            IFS=";" read -r -a arr <<<"${BASH_REMATCH[3]}"
            INCLUDE_PATHS+=("${arr[@]}")
        elif [[ "$line" =~ ^[[:blank:]]*(//@|#)include[[:space:]]*(\"|\')(.*)(\"|\') ]]; then
            local fp="${BASH_REMATCH[3]}"

            # look for file in includepaths if path is relative
            if [[ ! -f "$fp" ]]; then
                if [[ -f "$base_dir/$fp" ]]; then
                    fp="$base_dir/$fp"
                else
                    for i in "${INCLUDE_PATHS[@]}"; do
                        if [[ -f "$base_dir/$i/$fp" ]]; then
                            fp="$base_dir/$i/$fp"
                            break
                        fi
                    done
                fi
            fi

            process_include "$fp" "$_pad"
        else
            escaped=$(printf '%s\n' "$line")
            echo "${padding}${escaped}"
        fi
    done <"$file"
}

# parse script arguments
parse_args "$@"

# setup array to hold includepaths
INCLUDE_PATHS=()

# setup array to hold import paths
IMPORTED_PATHS=()

# process the source file
process_include "$source_path"
