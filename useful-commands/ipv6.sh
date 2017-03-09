#!/bin/sh
if grep -q "#precedence ::ffff:0:0/96  100" /etc/gai.conf
then
sed -i s/'#precedence ::ffff:0:0\/96  100'/'precedence ::ffff:0:0\/96  100'/ /etc/gai.conf
echo "Set to prefer ipv4."
else
sed -i s/'precedence ::ffff:0:0\/96  100'/'#precedence ::ffff:0:0\/96  100'/ /etc/gai.conf
echo "Set to prefer ipv6."
fi
