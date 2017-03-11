#!/bin/sh
cd /root/files/openwrt/OpenWrt-SDK-*
for dir in $(ls -l package/ |awk '/^d/ {print $NF}')
do                                                                 cd package/$dir
git fetch
git reset --hard origin/HEAD
cd ../..
done
