#!/usr/bin/env bash
sed -i 's/https:\/\/github.com\//git@github.com:/g' ./.git/config
exit $?
