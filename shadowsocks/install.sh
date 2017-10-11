#!/usr/bin/env bash
install_ubuntu(){
install_shadowsocks_flag || return 0
add-apt-repository -y ppa:max-c-lv/shadowsocks-libev
apt update
apt install -y shadowsocks-libev
}
install_debian(){
install_shadowsocks_flag || return 0
apt update
apt install -y shadowsocks-libev
}
get_ss_version(){
  echo -n "已安装的shadowsocks-libev版本: "
  version=$(apt list --installed shadowsocks-libev 2>/dev/null)
  if (($(sed -n '$=' <<< "$version") <= 1)) ;then
    echo "未安装"
    return 1
  fi
  echo $(sed -n '2p' <<< "$version"| awk '{print $2}')
}
install_chinadns(){
apt install -y build-essential
wget https://github.com/shadowsocks/ChinaDNS/releases/download/1.3.2/chinadns-1.3.2.tar.gz
tar -zxvf chinadns-1.3.2.tar.gz
rm chinadns-1.3.2.tar.gz
cd chinadns-1.3.2
./configure && make
install -p src/chinadns /usr/bin/chinadns
cd ..
rm -rf chinadns-1.3.2
}
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
cd "$SCRIPTPATH"

read -n1 -p "是否安装shadowsocks-libev(或者跳过) [Y/N]? " answer
case "$answer" in
Y|y)
  echo "好的，继续"
  install_shadowsocks_flag=true
;;
N|n)
  echo "好的，跳过"
  install_shadowsocks_flag=false
;;
*)
  echo "错误的输入，跳过"
  install_shadowsocks_flag=false
;;

issue=$(cat /etc/issue)
if grep -Fiq 'ubuntu' <<< "$issue"; then
  get_ss_version
  if grep -Fiq 'trusty' <<< "$issue" || grep -Fiq 'xenial' <<< "$issue"; then
    echo "不支持的ubuntu版本，可以自行编译安装/更新"
  else
    install_ubuntu
  fi
elif grep -Fiq 'debian' <<< "$issue"; then
  get_ss_version
  if cat /etc/debian_version| grep -Fiq 'buster/sid'; then
    install_debian
  else
    echo "debian版本过旧，可以自行编译安装/更新"
  fi
else
  echo "不支持的发行版，将立即退出"
  exit 1
fi

read -n1 -p "是否编译安装chinadns(或者跳过) [Y/N]? " answer
case "$answer" in
Y|y)
  echo "好的，继续"
  install_chinadns
;;
N|n)
  echo "好的，跳过"
;;
*)
  echo "错误的输入，跳过"
;;


wget -q https://github.com/SYHGroup/easy_systemd/raw/master/chinadns.service -O /etc/systemd/system/chinadns.service
wget -q https://github.com/SYHGroup/easy_systemd/raw/master/shadowsocks-libev-redir%40.service -O /etc/systemd/system/shadowsocks-libev-redir@.service
apt install -y ipset

exit 0
