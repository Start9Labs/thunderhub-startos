#!/bin/bash

DURATION=$(</dev/stdin)
if (($DURATION <= 10000 )); then
    exit 60
else
    curl --silent --fail thunderhub.embassy:3000 &>/dev/null
    RES=$?
    if test "$RES" != 0; then
        echo "The Thunderhub UI is unreachable" >&2
        exit 1
    fi
fi
