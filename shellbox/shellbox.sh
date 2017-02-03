#!/usr/bin/env bash
#encoding=utf8
rootpath="/root"
openwrtpath=$rootpath"/files/openwrt/OpenWrt-SDK-15.05.1-ar71xx-*"

########
#Small Script
########

function Checkroot(){
if [[ $EUID != "0" ]]
then
echo "Not root user."
exit 1
fi
}

function Dnspod(){
TokenID=$1
Token=$2
SubDomain=$3
Domain="simonsmh.cc"
RecordTTL=3600
RecodIP=$(nc ns1.dnspod.net 6666)
List=$(curl -skX POST https://dnsapi.cn/Record.List -d "login_token=${TokenID},${Token}&format=json&domain=${Domain}")
RecodID=$(echo $List | sed -n 's/.*"id":"\([0-9]*\)".*"name":"'${SubDomain}'".*/\1/p')
OldIP=$(echo $List | sed -n 's/.*"value":"\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)".*"name":"${SubDomain}".*/\1/p')
OldTTL=$(echo $List | sed -n 's/.*"ttl":"\([0-9]*\)".*"name":"'${SubDomain}'".*/\1/p')
if [ $OldIP == $RecodIP ]&&[ $OldTTL == $RecordTTL ]
then
Result="Action skipped successful"
else
Result=$(curl -skX POST https://dnsapi.cn/Record.Modify -d "login_token=${TokenID},${Token}&format=json&record_id=${RecodID}&domain=${Domain}&sub_domain=${SubDomain}&value=${RecodIP}&ttl=${RecordTTL}&record_type=A&record_line_id=0" | sed -n 's/.*"message":"\(.*\)","created_at".*/\1/p')
echo "Dnspod-ddns.sh: $(date) ${Result}"
fi
}

function Sshroot(){
Checkroot
sed -i s/'PermitRootLogin without-password'/'PermitRootLogin yes'/ /etc/ssh/sshd_config
sed -i s/'PermitRootLogin prohibit-password'/'PermitRootLogin yes'/ /etc/ssh/sshd_config
sed -i s/'Port 22'/'Port 20'/ /etc/ssh/sshd_config
}

function Switchipv6(){
Checkroot
if grep -q "#precedence ::ffff:0:0/96  100" /etc/gai.conf
then
sed -i s/'#precedence ::ffff:0:0\/96  100'/'precedence ::ffff:0:0\/96  100'/ /etc/gai.conf
echo "Set to prefer ipv4."
else
sed -i s/'precedence ::ffff:0:0\/96  100'/'#precedence ::ffff:0:0\/96  100'/ /etc/gai.conf
echo "Set to prefer ipv6."
fi
}

function Swap(){
Checkroot
dd if=/dev/zero of=/swap bs=256M count=2
mkswap /swap
chmod 600 /swap
echo '/swap none swap sw 0 0' >> /etc/fstab
swapon -a
}

########
#Server Preset
########

function Aptstablesources(){
Checkroot
echo -e 'deb http://ftp.debian.org/debian/ stable main contrib non-free
deb http://security.debian.org/ stable/updates main contrib non-free
deb http://ftp.debian.org/debian/ stable-updates main contrib non-free
deb http://ftp.debian.org/debian/ stable-proposed-updates main contrib non-free
deb http://ftp.debian.org/debian/ stable-backports main contrib non-free\n' > /etc/apt/sources.list
}

function Apttestingsources(){
Checkroot
echo -e 'deb http://ftp.debian.org/debian/ testing main contrib non-free
deb http://security.debian.org/ testing/updates main contrib non-free
deb http://ftp.debian.org/debian/ testing-updates main contrib non-free
deb http://ftp.debian.org/debian/ testing-proposed-updates main contrib non-free
deb http://ftp.debian.org/debian experimental main\n' > /etc/apt/sources.list
}

function Setsysctl(){
Checkroot
echo -e 'kernel.domainname = simonsmh.cc
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.default_qdisc = fq
fs.file-max = 51200
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 60
net.ipv4.tcp_keepalive_time = 3600
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_max_tw_buckets = 10000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.all.accept_ra=2
net.ipv6.conf.eth0.accept_ra=2
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864' > /etc/sysctl.conf
sysctl -p
}

function Setdns(){
Checkroot
apt install -y resolvconf
echo -e 'nameserver 2001:4860:4860:0:0:0:0:8888
nameserver 2001:4860:4860:0:0:0:0:8844
nameserver 8.8.8.8
nameserver 8.8.4.4\n' > /etc/resolvconf/resolv.conf.d/base
resolvconf -u
}

function Setgolang(){
Checkroot
apt install golang
mkdir ~/go
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export PATH=${PATH}:$GOPATH/bin' >> ~/.bashrc
source ~/.bashrc
}

function Zsh(){
apt -y install git zsh powerline
rm -r ~/.oh-my-zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp -f ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
sed -i "s/robbyrussell/ys/g" ~/.zshrc
sed -i "s/git/git git-extras svn last-working-dir catimg encode64 urltools wd sudo zsh-syntax-highlighting command-not-found common-aliases debian gitfast gradle npm python repo screen systemd dircycle/g" ~/.zshrc
echo "source ~/.bashrc" >> ~/.zshrc
chsh -s zsh
}

function Desktop(){
Checkroot
apt install -y tigervnc-scraping-server tigervnc-standalone-server tigervnc-xorg-extension xfce4 xfce4-goodies xorg fonts-noto
wget https://github.com/SYHGroup/easysystemd/raw/master/x0vncserver%40.service -O /etc/systemd/system/x0vncserver@.service
systemctl enable x0vncserver@5901.service
systemctl start x0vncserver@5901.service
}

function LNMP(){
Checkroot
apt install nginx-extras mariadb-client mariadb-server php7.0-[^dev,apcu,redis]
systemctl enable nginx
systemctl enable mysql
systemctl enable php7.0-fpm
sed -i  s/'upload_max_filesize = 2M'/'upload_max_filesize = 1024M'/ /etc/php/7.0/fpm/php.ini
sed -i  s/'post_max_size = 8M'/'post_max_size = 1024M'/ /etc/php/7.0/fpm/php.ini
sed -i  s/'short_open_tag = Off'/'short_open_tag = On'/ /etc/php/7.0/fpm/php.ini
sed -i  s/'default_socket_timeout = 60'/'default_socket_timeout = 300'/ /etc/php/7.0/fpm/php.ini
sed -i  s/'memory_limit = 128M'/'memory_limit = 64M'/ /etc/php/7.0/fpm/php.ini
sed -i  s/';opcache.enable=0'/'opcache.enable=1'/ /etc/php/7.0/fpm/php.ini
sed -i  s/';opcache.enable_cli=0'/'opcache.enable_cli=1'/ /etc/php/7.0/fpm/php.ini
sed -i  s/';opcache.fast_shutdown=0'/'opcache.fast_shutdown=1'/ /etc/php/7.0/fpm/php.ini
sed -i  s/'zlib.output_compression = Off'/'zlib.output_compression = On'/ /etc/php/7.0/fpm/php.ini
sed -i  s/';zlib.output_compression_level = -1'/'zlib.output_compression_level = 5'/ /etc/php/7.0/fpm/php.ini
sed -i  s/'allow_url_include = Off'/'allow_url_include = On'/ /etc/php/7.0/fpm/php.ini
}

function Github(){
git config --global user.name "simonsmh"
git config --global user.email simonsmh@gmail.com
git config --global credential.helper store
}

function SSPreset(){
Checkroot
apt install -y build-essential autoconf libtool libssl-dev libpcre3-dev clang screen tmux sudo curl gawk debhelper dh-systemd init-system-helpers pkg-config apg libpcre3-dev zip unzip npm golang tree bzr git subversion python-pip python-m2crypto
apt install -y --no-install-recommends asciidoc xmlto
wget 'https://github.com/SYHGroup/easysystemd/raw/master/shadowsocks-server.service' -O /etc/systemd/system/shadowsocks-server.service 
wget https://github.com/SYHGroup/easysystemd/raw/master/shadowsocks-go.service -O /etc/systemd/system/shadowsocks-go.service
Libsodium
Mbedtls
Python
Setgolang
Libev
systemctl enable shadowsocks-go.service 
systemctl enable shadowsocks-server.service
systemctl enable shadowsocks-libev
}

########
#Production Server Automatic Update
########

function Updatemotd(){
Checkroot
apt update 2>&1 | sed -n '$p' > /etc/motd
if certbot renew|grep -q "No renewals were attempted."
then
echo -e "\e[37;44;1mSSL 证书状态: \e[0m\e[37;42;1m 最新 \e[0m" >> /etc/motd
else
certbot renew --pre-hook "service nginx stop" --post-hook "service nginx start"
if certbot renew|grep -q "No renewals were attempted."
then
echo -e "\e[37;44;1mSSL 证书状态: \e[0m\e[37;42;1m 已更新 \e[0m" >> /etc/motd
else
echo -e "\e[37;44;1mSSL 证书状态: \e[0m\e[37;41;1m 无法更新 \e[0m" >> /etc/motd
fi
fi
for motd in nginx mysql php7.0-fpm x0vncserver@1 transmission-daemon shadowsocks-server shadowsocks-libev
do
if systemctl status $motd|grep -q "(running)"
then
echo -e "\e[37;44;1m$motd 状态: \e[0m\e[37;42;1m 正常 \e[0m\n"`systemctl status $motd|sed -n '$p'` >> /etc/motd
else
echo -e "\e[37;44;1m$motd 状态: \e[0m\e[37;41;1m 异常 \e[0m\n"`systemctl status $motd|sed -n '$p'` >> /etc/motd
fi &
done
wait
echo -e "\e[37;40;4m上次执行: \e[0m"`date` >> /etc/motd
cat /etc/motd
}

function Sysupdate(){
Checkroot
apt update
systemctl stop nginx
systemctl stop php7.0-fpm
apt full-upgrade -y
systemctl start php7.0-fpm
systemctl start nginx
#apt autoremove -y
#dpkg -l |grep ^rc|awk '{print $2}' |sudo xargs dpkg -P
}

function Vlmcsd(){
Checkroot
cd $rootpath
git clone https://github.com/Wind4/vlmcsd
cd vlmcsd
git fetch
git reset --hard
git pull
make clean
make
chmod +x vlmcs
chmod +x vlmcsd
}

function Libsodium(){
Checkroot
cd $rootpath
git clone https://github.com/jedisct1/libsodium -b stable
cd libsodium
git fetch
git reset --hard
git pull
./configure
make
make install
}

function Mbedtls(){
Checkroot
cd $rootpath
git clone https://github.com/ARMmbed/mbedtls.git
cd mbedtls
git fetch
git reset --hard
git pull
make
make install
}


function Libev(){
Checkroot
## Libev
cd $rootpath
git clone https://github.com/shadowsocks/shadowsocks-libev
cd shadowsocks-libev
git fetch
git reset --hard
git pull
git submodule update --init --recursive
./autogen.sh
dpkg-buildpackage -b -i
cd ..
dpkg -i shadowsocks-libev_*.deb
rm -rf *shadowsocks*.deb *.changes *.buildinfo
service shadowsocks-libev restart
## Obfs Plugin
cd $rootpath
git clone https://github.com/shadowsocks/simple-obfs
cd simple-obfs
git fetch
git reset --hard
git pull
git submodule update --init --recursive
./autogen.sh
./configure
make
make install
setcap cap_net_bind_service+ep /usr/local/bin/obfs-server
}

function Python(){
Checkroot
cd $rootpath
git clone https://github.com/shadowsocksr/shadowsocksr.git
cd shadowsocksr
git fetch
git reset --hard
git pull
python setup.py install
systemctl restart shadowsocks-server.service
}

function Go(){
go get github.com/shadowsocks/shadowsocks-go/cmd/shadowsocks-server
cp ~/go/bin/shadowsocks-server /usr/bin/
systemctl restart shadowsocks-server.service
}

function Openwrt(){
cd $openwrtpath
git clone https://github.com/aa65535/openwrt-feeds.git package/feeds
git clone https://github.com/shadowsocks/luci-app-shadowsocks.git package/luci-app-shadowsocks
git clone https://github.com/shadowsocks/openwrt-shadowsocks.git package/shadowsocks-libev
git clone https://github.com/aa65535/openwrt-simple-obfs.git package/simple-obfs
git clone https://github.com/aa65535/openwrt-chinadns.git package/chinadns
git clone https://github.com/aa65535/openwrt-dns-forwarder.git package/dns-forwarder
git clone https://github.com/aa65535/openwrt-dist-luci.git package/openwrt-dist-luci
git clone https://github.com/licess/openwrt-pdnsd package/pdnsd
git clone https://github.com/AlexZhuo/luci-app-pdnsd package/luci-app-pdnsd
for dir in $(ls -l package/ |awk '/^d/ {print $NF}')
do
cd package/$dir
git fetch
git reset --hard
git pull
cd ../..
done
make -j2 -k
}

########
#Large Script
########

function NX(){
Checkroot
Aptstablesources
apt update
apt install -y nginx-extras screen
echo -e 'server {
listen 80 default_server;
listen [::]:80 default_server;
autoindex on;
autoindex_exact_size off;
autoindex_localtime on;
root /root/; 
}\n' > /etc/nginx/sites-available/default
sed -i s/'user www-data'/'user root'/ /etc/nginx/nginx.conf
systemctl enable nginx
systemctl nginx restart
}

function TMSU(){
Checkroot
Aptstablesources
apt update
apt install -y transmission-daemon nginx-extras screen
systemctl stop transmission-daemon
#username="transmission"
#password="transmission"
#sed -i  s/"\"rpc-username\": \"transmission\","/"\"rpc-username\": \"$username\","/ /etc/transmission-daemon/settings.json
#sed -i  s/"\"rpc-password\": \".*"/"\"rpc-password\": \"$password\","/ /etc/transmission-daemon/settings.json
sed -i  s/'"download-queue-enabled": true'/'"download-queue-enabled": false'/ /etc/transmission-daemon/settings.json
sed -i  s/'"rpc-authentication-required": true'/'"rpc-authentication-required": false'/ /etc/transmission-daemon/settings.json
sed -i  s/'"rpc-whitelist-enabled": true'/'"rpc-whitelist-enabled": false'/ /etc/transmission-daemon/settings.json
echo -e 'server {
listen 80 default_server;
listen [::]:80 default_server;
autoindex on;
autoindex_exact_size off;
autoindex_localtime on;
root /var/lib/transmission-daemon/downloads/; 
location /transmission {
proxy_pass http://127.0.0.1:9091;
proxy_set_header Accept-Encoding "";
proxy_pass_header  X-Transmission-Session-Id;
}}\n' > /etc/nginx/sites-available/default
wget https://github.com/ronggang/transmission-web-control/raw/master/release/tr-control-easy-install.sh
bash tr-control-easy-install.sh
rm -rf tr-control-easy-install.sh
systemctl enable transmission-daemon
systemctl enable nginx
systemctl restart transmission-daemon
systemctl restart nginx
}

########
#Help
########

function Help(){
echo -e `date`"
Usage:
\tSmall Script:
\t\t-checkroot\tCheck root
\t\t-ddns\t\tDnspod ddns script
\t\t-sshroot\tEnable ssh for root
\t\t-ipv6\t\tSwitch ipv6
\t\t-swap\t\tSwap file generation
\tServer Preset:
\t\t-stable\t\tApt stable sources
\t\t-testing\tApt testing sources
\t\t-setsysctl\tSet sysctl
\t\t-setdns\t\tSet dns
\t\t-setgolang\tSet golang
\t\t-setzsh\t\tSet zsh
\t\t-setdesktop\tSet Xfce
\t\t-lnmp\t\tNginx+Mariadb+PHP7
\t\t-gitpreset\tGitHub Preset
\t\t-sspreset\tShadowsocks Preset
\tProduction Server Automatic Update:
\t\t-m\t\tUpdate motd
\t\t-u\t\tSystem update
\t\t-v\t\tCompile Vlmcsd
\t\t-l\t\tCompile Libsodium
\t\t-t\t\tCompile Mbedtls
\t\t-sl\t\tCompile SS-Libev
\t\t-sp\t\tCompile SS-Python
\t\t-sg\t\tCompile SS-Go
\t\t-o\t\tOpenwrt Compile Task
\tLarge Script:
\t\tNX\t\tNginx
\t\tTMSU\t\tTransmission+Nginx
\tShellbox:
\t\t-server\t\tRun Production Server Automatic Update
\t\tupdate\t\tUpdate shellbox.sh
\t\tRUN\t\tRun with function param"
}

########
#Running
########

for arg in "$@"
do
case $arg in
#Small Script
-checkroot)Checkroot;;
-ddns)Dnspod;;
-sshroot)Sshroot;;
-ipv6)Switchipv6;;
-swap)Swap;;
#Server Preset
-stable)Aptstablesources;;
-testing)Apttestingsources;;
-setsysctl)Setsysctl;;
-setdns)Setdns;;
-setgolang)Setgolang;;
-setzsh)Zsh;;
-setdesktop)Desktop;;
-lnmp|LNMP)LNMP;;
-gitpreset)Github;;
-sspreset)SSPreset;;
#Production Server Automatic Update
-m)Updatemotd;;
-u)Sysupdate;;
-v)Vlmcsd;;
-l)Libsodium;;
-t)Mbedtls;;
-sl)Libev;;
-sp)Python;;
-sg)Go;;
-o)Openwrt;;
#Large Script
-nx|NX)NX;;
-tmsu|TMSU)TMSU;;
#Shellbox
-server)
Sysupdate
Vlmcsd &
Libsodium &
Mbedtls &
wait
Python &
Libev &
Openwrt &
#Go &
wait
;;
update|upgrade)
cd $(cd "$(dirname "$0")"; pwd)
wget --no-cache https://raw.githubusercontent.com/SYHGroup/easy_shell/master/shellbox/shellbox.sh -O shellbox.sh
chmod +x shellbox.sh
exit 0
;;
RUN)
`echo $*|sed -e 's/^RUN //g'|awk -F ' ' '{ print $0 }'`
exit 0
;;
*)
Help
;;
esac
done
[[ ! -n "$@" ]] && Help
exit 0
