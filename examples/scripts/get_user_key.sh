#!/bin/bash
set -xue
in_oauth="$1"
out_oauth="$2"
max_session_time="$3"
usname="$4"
realm="$5"

hmackey="$(echo '$usname:$realm:mysecret_password | md5sum | awk '{print $1}')"
echo "out_oauth: 0"
echo "max_session_time: 420"
echo "key: $hmackey"
