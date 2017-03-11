#!/usr/bin/env bash
#encoding=utf8
rootpath="/tmp/build-source"
mkdir -p -m 777 $rootpath

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

function Saveapt(){
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
rm /var/lib/dpkg/lock
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
deb http://ftp.debian.org/debian/ stable-backports main contrib non-free
deb http://repo.debiancn.org/ stable main\n' > /etc/apt/sources.list
}

function Apttestingsources(){
Checkroot
echo -e 'deb http://ftp.debian.org/debian/ testing main contrib non-free
deb http://security.debian.org/ testing/updates main contrib non-free
deb http://ftp.debian.org/debian/ testing-updates main contrib non-free
deb http://ftp.debian.org/debian/ testing-proposed-updates main contrib non-free
deb http://ftp.debian.org/debian experimental main
deb http://repo.debiancn.org/ testing main\n' > /etc/apt/sources.list
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
### For Ordinary Vnc Server ###
#apt install -y tightvncserver xfce4 xfce4-goodies xorg fonts-noto
#wget https://github.com/SYHGroup/easysystemd/raw/master/vncserver%40.service -O /etc/systemd/system/vncserver@.service
#systemctl enable vncserver@1.service
#vncserver :1
#vncserver -kill :1
#systemctl start vncserver@1.service
### For x0vncserver ###
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
git config --global commit.gpgsign true
git config --global tag.gpgsign true
echo "export GPG_TTY=$(tty)" >>~/.bashrc
#Import gpg key from keybase first
}

function SSPreset(){
Checkroot
apt install -y build-essential gettext build-essential autoconf libtool libpcre3-dev libev-dev libudns-dev automake libcork-dev libcorkipset-dev libmbedtls-dev libsodium-dev python-pip python-m2crypto golang
apt install -y --no-install-recommends asciidoc xmlto
wget https://github.com/SYHGroup/easy_systemd/raw/master/ssserver.service -O /etc/systemd/user/ssserver.service 
Libsodium
Mbedtls
Python
Setgolang
Libev
systemctl --user enable ssserver.service
systemctl enable shadowsocks-libev
}

########
#Production Server Automatic Update
########

function Updatemotd(){
Checkroot
AVAILABLE_MEM=$(free -h | sed -n '2p' | awk '{print $7}')
DISK_FREE=$(df / -h | sed -n '2p' | awk '{print $4}')
apt update 2>&1 | sed -n '$p' > /etc/motd
if grep -q 'G' <<< $DISK_FREE ; then
echo -e "\e[37;44;1m存储充足: \e[0m\e[37;42;1m ${DISK_FREE} \e[0m" >> /etc/motd
else
echo -e "\e[37;44;1m存储爆炸: \e[0m\e[37;41;1m ${DISK_FREE} \e[0m" >> /etc/motd
fi
echo -e "\e[37;44;1m可用内存: \e[0m\e[37;42;1m ${AVAILABLE_MEM} \e[0m" >>/etc/motd
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
for motd in nginx.service mysql.service php7.0-fpm.service transmission-daemon.service shadowsocks-libev.service x0vncserver@5901
do
if systemctl status $motd|grep -q "(running)"
then
echo -e "\e[37;44;1m$motd 状态: \e[0m\e[37;42;1m 正常 \e[0m\n"`systemctl status $motd|sed -n '$p'` >> /etc/motd
else
echo -e "\e[37;44;1m$motd 状态: \e[0m\e[37;41;1m 异常 \e[0m\n"`systemctl status $motd|sed -n '$p'` >> /etc/motd
fi &
done
for motd in $(ls /root/.config/systemd/user/default.target.wants/)
do
if systemctl --user status $motd|grep -q "(running)"
then
echo -e "\e[37;44;1m$motd 状态: \e[0m\e[37;42;1m 正常 \e[0m\n"`systemctl --user status $motd|sed -n '$p'` >> /etc/motd
else
echo -e "\e[37;44;1m$motd 状态: \e[0m\e[37;41;1m 异常 \e[0m\n"`systemctl --user status $motd|sed -n '$p'` >> /etc/motd
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
apt -y full-upgrade
systemctl start php7.0-fpm
systemctl start nginx
#apt -y autoremove
apt -y purge `dpkg -l | grep ^rc | awk '{print $2}'`
}

function Vlmcsd(){
Checkroot
cd $rootpath
git clone https://github.com/Wind4/vlmcsd
cd vlmcsd
git fetch
git reset --hard origin/HEAD
make
chmod +x ./bin/vlmcs
chmod +x ./bin/vlmcsd
mv ./bin/vlmcs /usr/bin/
mv ./bin/vlmcsd /usr/bin/
git clean -fdx
}

function Libev(){
Checkroot
## Libev
cd $rootpath
git clone https://github.com/shadowsocks/shadowsocks-libev
cd shadowsocks-libev
git fetch
git reset --hard origin/HEAD
git submodule update --init --recursive
./autogen.sh
dpkg-buildpackage -b -uc -us
git clean -fdx
## Obfs Plugin
cd $rootpath
git clone https://github.com/shadowsocks/simple-obfs
cd simple-obfs
git fetch
git reset --hard origin/HEAD
git submodule update --init --recursive
./autogen.sh
dpkg-buildpackage -b -uc -us
git clean -fdx
## Install
cd $rootpath
dpkg -i simple-obfs_*.deb
dpkg -i shadowsocks-libev_*.deb
setcap cap_net_bind_service+ep /usr/bin/obfs-server
systemctl restart shadowsocks-libev
#rm -rf *[shadowsocks-libev,simple-obfs]*[buildinfo,changes,deb]
### Preserve built debian packages ###
wwwdir="/var/www/wwwfiles/files/ss-debian-amd64binary"
if [ ! -d "$wwwdir" ] ; then
mkdir -p -m 755 $wwwdir
chown www-data:www-data $wwwdir
[ $? == 0 ] || exit 1
fi
List=$(ls |xargs -n 1 echo |grep -E "\<*(shadowsocks-libev|simple-obfs)*(buildinfo|changes|deb)\>")
[ $? == 0 ] && [ -n "$List" ] || exit 1
echo "Moving built debian packages."
sudo -u www-data rm -rf "${wwwdir}/*"
for File in $List
do
mv "$File" "${wwwdir}/"
chown www-data:www-data "${wwwdir}/${File}"
done
}

function Python(){
Checkroot
cd $rootpath
git clone https://github.com/shadowsocksr/shadowsocksr.git
cd shadowsocksr
git fetch
git reset --hard origin/HEAD
python setup.py install
systemctl --user restart ssserver.service
}

function Go(){
go get github.com/shadowsocks/go-shadowsocks2
mv ~/go/bin/go-shadowsocks2 /usr/bin/
systemctl --user restart go-shadowsocks2.service
}

function Openwrt(){
#Migrated to Travis Ci
cd /root/files/openwrt/OpenWrt-SDK-*
for dir in $(ls -l package/ |awk '/^d/ {print $NF}')
do
cd package/$dir
git fetch
git reset --hard origin/HEAD
cd ../..
done
make -k
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
\t\t-sshroot\tEnable ssh for root
\t\t-ipv6\t\tSwitch ipv6
\t\t-saveapt\tSave apt/dpkg lock
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
-sshroot)Sshroot;;
-ipv6)Switchipv6;;
-saveapt)Saveapt;;
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
Python &
Libev &
wait
;;
update|upgrade)
cd $(cd "$(dirname "$0")"; pwd)
wget --no-cache https://raw.githubusercontent.com/SYHGroup/easy_shell/master/shellbox/shellbox.sh -O shellbox.sh
chmod +x shellbox.sh
exit 0
;;
RUN)
`echo -n $*|sed -e 's/^RUN //g'|awk -F ' ' '{ print $0 }'`
exit $?
;;
*)
Help
;;
esac
done
[[ ! -n "$@" ]] && Help && exit 1
