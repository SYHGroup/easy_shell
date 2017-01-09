#!/usr/bin/env bash
####Change your personal settings####
ssport="1080"
ssdomain="jerry981028.ml"
ssconfig="/etc/shadowsocks-libev/config-client.json"
#############################
function Update(){
echo -e "正在下载路由表，请稍候...\c"
curl -s 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute.list
echo "完成"
}
function Checkenv(){
if [[ $EUID != "0" ]] ; then
	echo "错误：设置iptables需要root权限"
	exit 1
fi
if  ! [ -f "$ssconfig" ] ; then
	echo "错误：${ssconfig}不存在"
	exit 1
fi
}
function Start(){
ss-redir -c /etc/shadowsocks-libev/config-client.json -f shadowsocks.pid
# Setup the ipset
ipset -N chnroute hash:net maxelem 65536
echo -e "正在配置iptables，请稍候...\c"
for Ip in $(cat 'chnroute.list'); do
  ipset add chnroute $Ip
done
echo "完成"
# Setup iptables
iptables -t nat -N SHADOWSOCKS
# Allow connection to the server
iptables -t nat -A SHADOWSOCKS -d 104.156.230.63 -j RETURN
# Allow connection to reserved networks
iptables -t nat -A SHADOWSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A SHADOWSOCKS -d 240.0.0.0/4 -j RETURN
# Allow connection to chinese IPs
iptables -t nat -A SHADOWSOCKS -p tcp -m set --match-set chnroute dst -j RETURN
# Redirect to Shadowsocks
iptables -t nat -A SHADOWSOCKS -p tcp -j REDIRECT --to-port "$ssport"
# Redirect to SHADOWSOCKS
iptables -t nat -A OUTPUT -p tcp -j SHADOWSOCKS
}
function Stop(){
iptables -t nat -D OUTPUT -p tcp -j SHADOWSOCKS
iptables -t nat -F SHADOWSOCKS
iptables -t nat -X SHADOWSOCKS
ipset destroy chnroute
kill `cat shadowsocks.pid`
rm shadowsocks.pid
}
#主进程开始
Checkenv
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd "$SCRIPTPATH"
case $* in
update)
Update
;;
start)
Start
;;
stop)
Stop
;;
restart)
Stop
service networking restart
#Update
Start
;;
*)
echo "用法:
	update	更新路由表
	start	配置iptables
	stop	取消配置iptables
	restart	重新配置iptables"
;;
esac
exit 0
