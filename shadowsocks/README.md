# easyshell/shadowsocks  
linux + shadowsocks-libev + chinadns + iptables  
## install.sh:  
安装脚本  
## lsci.sh:
依赖`shadowsocks-libev`,`systemd`,`ipset`。  
直接执行 sudo ./ss-iptables.sh 即可自动判断运行状态 也可以增加参数 /update/start/stop/restart 手动运行。  
## files/etc/resolv.conf:  
若你的系统使用resolvconf，请参照resolvconf的manual来修改resolv.conf。如果系统使用network-manager，可以使用network-manager的图形界面修改dns。(主dns127.0.0.2,备用114.114.114.114)  
