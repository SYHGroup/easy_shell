#!/bin/sh
dd if=/dev/zero of=/swap bs=256M count=2
mkswap /swap
chmod 600 /swap
echo '/swap none swap sw 0 0' >> /etc/fstab
swapon -a
