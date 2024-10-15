#!/usr/bin/env bash

while IFS= read -r line; do
    echo "running test: $line"
    "$line"
done <<<"$(find tests -type f -name "test*.sh")"
