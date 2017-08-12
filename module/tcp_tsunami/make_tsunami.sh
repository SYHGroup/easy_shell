#!/bin/sh
mkdir -p /tmp/tsunami && cd /tmp/tsunami
wget https://gist.githubusercontent.com/simonsmh/c782f4ff82e492e7493899da73d5cf70/raw/tcp_tsunami.c
wget https://gist.githubusercontent.com/simonsmh/c782f4ff82e492e7493899da73d5cf70/raw/Makefile
make && make install
sed -i 's/bbr/tsunami/g' /etc/sysctl.conf
sysctl -p