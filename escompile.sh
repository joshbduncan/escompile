#!/usr/bin/env bash

# ExtendScript Compiler - Compile modular ExtendScripts into a single human readable JSX file.
#
# Adobe Preprocessor Directives Documentation
# https://extendscript.docsforadobe.dev/extendscript-tools-features/preprocessor-directives.html

# Copyright 2024 Josh Duncan
# https://joshbduncan.com

# See README.md for more info

# This script is distributed under the MIT License.
# See the LICENSE file for details.

# set -x
set -Eeuo pipefail

script_version="0.6.0"
script_name="${0##*/}"
source_path=""

# create a temp file to hold the seen paths
# having to use paths since bash doesn't keep state during while loop with pipes
seen="$(mktemp /tmp/escompile-seen.XXXXXX)"

usage_opts="[-h] [--version] [FILE]"
usage() {
    printf "usage: %s %s\n" "${script_name%.*}" "$usage_opts" >&2
}

help() {
    cat <<EOF
usage: ${script_name%.*} $usage_opts

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
    printf "%s %s\n" "${script_name%.*}" "$script_version"
}

error() {
    printf "%s: %s\n" "${script_name%.*}" "$1" >&2
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | -\? | --help) help ;;
        --version)
            version
            exit 0
            ;;
        --)
            shift
            break
            ;; # end of args.
        -?*)
            usage
            error "unrecognized arguments: $1"
            exit 2
            ;;
        *)
            source_path="$1"
            break
            ;;
        esac
        shift
    done

    # ensure a file was provided
    if [ -z "$source_path" ]; then
        usage
        error "the following arguments are required: [FILE]"
        exit 1
    fi

    # ensure valid file path
    if [[ ! -f "$source_path" ]]; then
        error "no such file: $source_path"
        exit 1
    fi

    return 0
}

absolute_path() {
    echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

already_seen() {
    local path="$1"
    local line
    while IFS= read -r line; do
        # skip empty lines
        [[ -z "$line" ]] && continue

        # compare the current line with the variable $p
        if [[ "$line" == "$path" ]]; then
            return 0 # already seen
        fi
    done <"$seen"

    return 1 # not seen
}

parse_file() {
    # declare variables
    local include_paths=()
    local file="$1"

    # get data, name, absolute path, and base dir of the file
    local data
    data=$(<"$file")
    local file_name
    file_name=$(basename "$file")
    local file_path
    file_path=$(absolute_path "$file")
    local base_dir
    base_dir=$(dirname "$file")

    # track seen paths to avoid double imports
    if already_seen "$file_path"; then
        error "include skipped since already imported: '$1'"
        return
    else
        echo "$file_path" >>"$seen"
    fi

    # check for utf-8 bom encoding (https://github.com/joshbduncan/escompile/issues/4)
    if head -c 3 "$file" | grep -q $'\xEF\xBB\xBF'; then
        local tmpfile
        tmpfile=$(mktemp /tmp/"$file_name".XXXXXX)
        tail -c +4 "$file" >"$tmpfile"
        file="$tmpfile"
    fi

    # iterate over include directives
    while IFS= read -r line; do
        # create an escaped version of the line for substitution
        local escaped_line
        escaped_line=$(printf '%s\n' "$line" | sed -e 's/[]\/$*.^[]/\\&/g')

        if [[ "$line" =~ ^[[:blank:]]*(//@|#)includepath[[:space:]]*(\"|\')(.*)(\"|\') ]]; then
            # read path(s) into array split on ';'
            local arr
            IFS=";" read -r -a arr <<<"${BASH_REMATCH[3]}"
            include_paths+=("${arr[@]}")

            # delete the includepath statement
            data=$(grep -v "$escaped_line" <<<"$data")
        elif [[ "$line" =~ ^[[:blank:]]*(//@|#)include[[:space:]]*(\"|\')(.*)(\"|\') ]]; then
            # resolve include file path
            local include_file_path="${BASH_REMATCH[3]}"
            if [[ ! -f $include_file_path ]]; then
                if [[ -f "$base_dir/$include_file_path" ]]; then
                    include_file_path="$base_dir/$include_file_path"
                else # check in all of the `includepath` paths
                    for include_path in "${include_paths[@]-}"; do
                        # if file is found at current include path break
                        if [[ -f "$base_dir/$include_path/$include_file_path" ]]; then
                            include_file_path="$base_dir/$include_path/$include_file_path"
                            break
                        fi
                    done
                fi
            fi

            # if $include_file_path is valid, process it
            local include_data
            if [[ -f "$include_file_path" ]]; then
                include_data=$(parse_file "$include_file_path")
            else
                error "no such file: $include_file_path"
                exit 1
            fi

            # get the leading whitespace for the include directive
            local whitespace
            whitespace=$(grep -o '^[[:blank:]]*' <<<"$line")

            # pad the include file data with matching whitespace (non-blank line)
            # shellcheck disable=SC2001
            include_data=$(sed "s/^./$whitespace&/" <<<"$include_data")

            # escape the include file data and substitute it for the statement
            local escaped_include_data
            escaped_include_data=$(printf '%s\n' "$include_data" | sed 's,[\/&],\\&,g;s/$/\\/')
            escaped_include_data=${escaped_include_data%?}

            # shellcheck disable=SC2001
            data=$(sed "s/$escaped_line/$escaped_include_data/" <<<"$data")
        fi

    done <<<"$(grep -E "^[[:blank:]]*(#|//@)include" <<<"$data")"

    echo "$data"
}

# parse script arguments
parse_args "$@"

# process the source file
parse_file "$source_path"
