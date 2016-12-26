#!/usr/bin/env bash
file="$1"
sof="$2"
eof=$(sed -n '$=' ${file})
sed -n "${sof},${eof}p" ${file} >> output.txt
exit 0
