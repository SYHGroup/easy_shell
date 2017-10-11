#!/usr/bin/env bash
####Change your personal settings####
localport="1080"
ssdomain="yourdomain"
ssconfig="config-client"	#完整路径为/etc/shadowsocks-libev/config-client.json
sstool="ss-nat"
#############################
GetIP(){
set -e
serverip=$(ping ${ssdomain} -s 1 -c 1 -W 2 | grep ${ssdomain} | head -n 1)
serverip=$(echo ${serverip} | cut -d '(' -f 2 | cut -d ')' -f 1)
return 0
}
tries=0
serverip=""
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
# For compatibility with busybox readlink
#[ -L "$0" ] && SCRIPT=$(readlink "$0") || SCRIPT="$0"
#SCRIPTPATH=$(cd "$(dirname "$SCRIPT")"; pwd)
cd "$SCRIPTPATH"
[ -f /run/ss-iptables.lock ] && exit 1
#Get ip from domain
while true ; do
	((tries=$tries+1))
	GetIP
	if [ $? == 0 ] && [ -n "$serverip" ] ; then
		unset tries
		break
	else
		echo -n "Failed to get server ip. "
		(( tries <= 10 )) && echo "Retrying." || exit 1
		sleep 20
	fi
done
touch /run/ss-iptables.lock
$sstool -s ${serverip} -l ${localport} -i chnroute.txt -o
[ $? == 0 ] || exit 1
exit 0
