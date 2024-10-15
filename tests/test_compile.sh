#!/usr/bin/env bash

# test_name="$(basename "$0")"
# timestamp=$(date +%s)

tmpfile=$(mktemp /tmp/"escompile-test.XXXXXX")
./escompile.sh sample_jsx_project/src/script.jsx >"$tmpfile"
diff "$tmpfile" tests/known.jsx
