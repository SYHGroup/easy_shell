# easyshell/shadowsocks  
旨在分享linux下使用shadowsocks的经验。  
## ss-iptables.sh:  
依赖`shadowsocks-libev`,`systemd`,`ipset`。  
配置完成files/中的所有文件后，直接执行 sudo ./ss-iptables.sh 即可自动判断运行状态 也可以增加参数 /update/start/stop/restart 手动运行。  
## files/ 中包含:  
chinadns和shadowsocks-libev-nat的systemd脚本  
桌面配置文件和图标  
( 使用前置于合适的路径并修改 )。  
## files/etc/resolv.conf:  
若你的系统使用resolvconf，请参照resolvconf的manual来修改resolv.conf。如果系统使用network-manager，可以使用network-manager的图形界面修改dns。(主dns127.0.0.2,备用114.114.114.114)  
  
## ss-rules-without-ipset  (目前还不能正常运作)
原项目： https://github.com/shadowsocks/luci-app-shadowsocks 地址： https://raw.githubusercontent.com/shadowsocks/luci-app-shadowsocks/master/files/root/usr/bin/ss-rules-without-ipset  
改变：第一行 #!/bin/sh => #!/usr/bin/env bash  
使用：更改 sstool="ss-nat" 为 sstool="./ss-rules-without-ipset"	注意：ss-nat需要ipset和shadowsocks-libev.  
警告：使用ss-rules-without-ipset会造成运行缓慢！  
