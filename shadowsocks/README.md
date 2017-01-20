# easyshell/shadowsocks  
旨在分享linux下使用shadowsocks的经验。  
## ss-iptables.sh:  
依赖`shadowsocks-libev`,`ipset`。  
直接执行 ./ss-iptables.sh 即可自动判断运行状态 也可以增加参数 /update/start/stop/restart 手动运行。  
## shadowsocks-iptables.desktop,shadowsocks.png:  
桌面配置文件和图标( 使用前置于合适的路径并修改 shadowsocks-iptables.desktop )。  
  
  
## ss-rules-without-ipset  (目前还不能正常运作)
原项目： https://github.com/shadowsocks/luci-app-shadowsocks 地址： https://raw.githubusercontent.com/shadowsocks/luci-app-shadowsocks/master/files/root/usr/bin/ss-rules-without-ipset  
改变：第一行 #!/bin/sh => #!/usr/bin/env bash  
使用：更改 sstool="ss-nat" 为 sstool="./ss-rules-without-ipset"	注意：ss-nat需要ipset和shadowsocks-libev.  
警告：使用ss-rules-without-ipset会造成运行缓慢！  
