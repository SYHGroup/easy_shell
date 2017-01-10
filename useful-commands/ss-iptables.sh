#!/usr/bin/env bash
####Change your personal settings####
localport="1080"
ssdomain="ipv4.jerry981028.ml"
ssconfig="/etc/shadowsocks-libev/config-client.json"
#############################
function Update(){
echo -e "下载路由表"
wget -O chnroute.tmp 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest'
if [ ! -f chnroute.tmp ] ; then
	echo "错误：路由表下载失败，检查网络连接"
	exit 1
fi
cat chnroute.tmp | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute.list
rm chnroute.tmp
}
function Checkenv(){
if [[ $EUID != "0" ]] ; then
	echo "错误：设置iptables需要root权限"
	exit 1
fi
if [ ! -f "$ssconfig" ] ; then
	echo "错误：配置文件${ssconfig}不存在"
	exit 1
fi
if [ ! -f chnroute.list ] ; then
Update
fi
}
function Start(){
#Start ss client
ss-redir -c "$ssconfig" -f shadowsocks.pid
#Get ip from domain
serverip=`ping ${ssdomain} -s 1 -c 1 | grep ${ssdomain} | head -n 1`
serverip=`echo ${serverip} | cut -d'(' -f 2 | cut -d')' -f1`
if [ "$serverip" == "" ] ; then
	echo "错误：查找服务器ip失败，检查网络连接"
	exit 1
fi
ss-nat -s $serverip -l $localport -i chnroute.list -o
}
function Stop(){
ss-nat -f
kill `cat shadowsocks.pid`
rm shadowsocks.pid
}
#主进程开始
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd "$SCRIPTPATH"
case $* in
update)
Update
exit 0
;;
start)
Checkenv
Start
;;
stop)
Checkenv
Stop
;;
restart)
Checkenv
Stop
service networking restart
Start
;;
"")
Checkenv
if [ -f shadowsocks.pid ] ; then
	PID=`cat shadowsocks.pid`
	ss_started=`ps -aux |grep "$PID" |grep -o ss-redir`
	if [ "$ss_started" == "ss-redir" ] ; then
		echo "关闭中..."
		Stop
	else
		echo "上次未正常退出，但仍然启动..."
		ss-nat -f
		Start
	fi
else
	echo "启动中..."
	Start
fi
read -p "回车键退出"
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
