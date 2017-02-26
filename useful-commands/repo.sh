#!/bin/sh
repo=(
SYHGroup/easy_shell
SYHGroup/easy_systemd
)
for line in ${repo[@]}
do
git clone git@github.com:/$line
done
