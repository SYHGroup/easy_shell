#!/usr/bin/env bash
china_ip_list=/etc/overture/china_ip_list.txt
Checkroot(){
if [[ $EUID != "0" ]]
then
echo "Not root user."
exit 1
fi
}
Help(){
echo "Usage: $0 <config_name_under_/etc/shadowsocks> <[start]|stop>"
exit $@
}
Checkroot
[[ -z "$1" ]] && Help 1 || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] && Help 0 || CONFIG=$1
[[ "$2" == "stop" ]] && unset ENABLE || ENABLE=start
ip=$(ping $(sed -n 's/.*"server":"\(.*\)".*/\1/p' /etc/shadowsocks/$CONFIG.json 2>/dev/null) -t1 -c1 -s0 -q 2>/dev/null| sed -n 's/.* (\([0-9.]*\)) .*/\1/p' 2>/dev/null)
[[ -z "$ip" ]] && {echo "ERROR: Couldn't find your server." && exit 1}
port=$(sed -n 's/.*"local_port":\([0-9]*\).*/\1/p' /etc/shadowsocks/$CONFIG.json 2>/dev/null)
[[ -z "$port" ]] && port=1080
# echo $ip $port $ENABLE
if [ $ENABLE ]; then
systemctl restart shadowsocks-libev-redir@$CONFIG.service
ss-nat -s $ip -l $port -i $china_ip_list -u -o
else
systemctl stop shadowsocks-libev-redir@$CONFIG.service
ss-nat -f
fi
exit $?
