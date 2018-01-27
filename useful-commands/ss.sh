#!/usr/bin/env bash
china_ip_list=/etc/overture/china_ip_list.txt
config_location=/etc/shadowsocks
Ignorelist(){
wget -qO- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /tmp/ignore.list
[[ "$?" == "0" ]] && mv /tmp/ignore.list $china_ip_list || echo "Failed to update ignore list."
}
Checkroot(){
if [[ $EUID != "0" ]]
then
echo "Not root user."
exit 1
fi
}
Help(){
echo "Usage: $0 <config_name_under_$config_location> <[start]|stop>"
exit $@
}
Checkroot
[[ -z "$1" ]] && Help 1 || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] && Help 0 || CONFIG=$1
[[ "$2" == "stop" ]] && unset ENABLE || ENABLE=start
if [ $ENABLE ]; then
[[ $(systemctl is-active shadowsocks-libev-redir@$CONFIG.service) ]] || { echo "ERROR: ss-libev is running." && exit 1;}
ip=$(ping $(sed -n 's/.*"server":"\(.*\)".*/\1/p' $config_location/$CONFIG.json 2>/dev/null) -t1 -c1 -s0 -q 2>/dev/null| sed -n 's/.* (\([0-9.]*\)) .*/\1/p' 2>/dev/null)
[[ -z "$ip" ]] && { echo "ERROR: Couldn't find your server." && exit 1;}
port=$(sed -n 's/.*"local_port":\([0-9]*\).*/\1/p' $config_location/$CONFIG.json 2>/dev/null)
[[ -z "$port" ]] && port=1080
# echo $ip $port $ENABLE
Ignorelist
systemctl restart shadowsocks-libev-redir@$CONFIG.service
ss-nat -s $ip -l $port -i $china_ip_list -u -o
else
systemctl stop shadowsocks-libev-redir@$CONFIG.service
ss-nat -f
fi
exit $?
