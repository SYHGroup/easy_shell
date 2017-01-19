#!/usr/bin/env bash
####Change your personal settings####
localport="1080"
ssdomain="ipv4.jerry981028.ml"
ssconfig="/etc/shadowsocks-libev/config-client.json"
#############################
function ErrorSolve(){
if [ $IS_TERMINAL ] ; then
read -n 1 -t 5 -p "发生错误，等待5秒或任意键退出"
fi
exit 1
}
function Update(){
echo "下载路由表"
wget -O chnroute.tmp 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest'
if [ ! -f chnroute.tmp ] ; then
	echo "错误：路由表下载失败，检查网络连接"
	ErrorSolve
fi
cat chnroute.tmp | grep ipv4 | grep CN | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > chnroute.txt
rm chnroute.tmp
}
function Checkenv(){
if [[ $EUID != "0" ]] ; then
	echo "错误：设置iptables需要root权限"
	ErrorSolve
fi
if [ ! -f "$ssconfig" ] ; then
	echo "错误：配置文件${ssconfig}不存在"
	ErrorSolve
fi
if [ ! -f chnroute.txt ] ; then
Update
fi
}
function Start(){
#Get ip from domain
serverip=`ping ${ssdomain} -s 1 -c 1 -W 2 | grep ${ssdomain} | head -n 1`
serverip=`echo ${serverip} | cut -d'(' -f 2 | cut -d')' -f1`
if [ "$serverip" == "" ] ; then
	echo "错误：查找服务器ip失败，检查网络连接"
	ErrorSolve
fi
#Start ss client
ss-redir -c "$ssconfig" -f shadowsocks.pid
ss-nat -s $serverip -l $localport -i chnroute.txt -o
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
IS_TERMINAL=1
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
echo "                                   
                                 CO
                              Ls40a
                          e088S4S8C
                       O48S88STT84 
                   Ca4SS48SSTTTT4O 
                L08S88SSSSs4UTTS8  
            3s44S4STTS48ssSUTTT4Y  
         es4888STTTS48sL4STTTTTS3  
     3O0484STTTTTS44s1aSSTTTTT80   
 3Y44S48STTTTTTS44s e44TTTTTTT8e   
 tO08SS48STTTS44Y  a8STTTTTTTS4    
     7sa48SS44Y  O44TTTTTTTTT4Y    
          3YO   Y4088STTTTTTT8?    
                lL0448SS848S4s     
                0ast  2O008842     
                Saa0C       3      
                Ta4e               
                T0                 
                O                  "
read -n 1 -t 5 -p "等待5秒或任意键退出"
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
