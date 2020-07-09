#!/bin/bash
set -xue
in_oauth="$1"
out_oauth="$2"
max_session_time="$3"
usname="$4"
realm="$5"

key="$(echo weiqiy | hmac256 secret42)"
echo "out_oauth: 0"
echo "max_session_time: 420"
echo "key: $key"