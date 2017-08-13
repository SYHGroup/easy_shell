#!/bin/sh
make && make install
sed -i 's/bbr/tsunami/g' /etc/sysctl.conf
sysctl -p
