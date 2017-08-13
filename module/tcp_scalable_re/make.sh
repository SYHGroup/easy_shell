#!/bin/sh
make && make install
sed -i 's/bbr/scalable-re/g' /etc/sysctl.conf
sysctl -p