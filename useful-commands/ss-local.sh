#!/usr/bin/env bash
function Update(){
echo -e "正在下载acl，请稍候...\c"
wget https://raw.githubusercontent.com/shadowsocks/shadowsocks-android/master/src/main/assets/acl/china-list.acl -O bypasschina.cal
echo "完成"
}
function Checkroot(){
if [[ $EUID != "0" ]]
then
echo "需要root权限"
exit 1
fi
}
function Start(){
ss-local -c /etc/shadowsocks-libev/config-client.json --acl ./bypasschina.acl -f ss-local.pid
echo "Started."
}
function Stop(){
kill `cat ss-local.pid`
rm ss-local.pid
}
#主进程开始
Checkroot
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
	update	更新acl
	start	开启本地socks
	stop	关闭本地socks
	restart	重新打开本地socks"
;;
esac
exit 0
