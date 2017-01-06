#!/usr/bin/env bash
#if [ $# -lt 1 ]; then
#    echo $0 need a parameter
#    exit 0
#fi
ADDR=$1
Result=`ping ${ADDR} -s 1 -c 1 | grep ${ADDR} | head -n 1`
Result=`echo ${Result} | cut -d'(' -f 2 | cut -d')' -f1`
echo "$Result"
exit 0
