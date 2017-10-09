#!/usr/bin/env bash
#encoding=utf8
rootpath="/tmp/build-source"
mkdir -p -m 777 $rootpath

########
#Small Script
########

Checkroot(){
if [[ $EUID != "0" ]]
then
echo "Not root user."
exit 1
fi
}

Sshroot(){
Checkroot
sed -i s/'PermitRootLogin without-password'/'PermitRootLogin yes'/ /etc/ssh/sshd_config
sed -i s/'PermitRootLogin prohibit-password'/'PermitRootLogin yes'/ /etc/ssh/sshd_config
sed -i s/'Port 22'/'Port 20'/ /etc/ssh/sshd_config
}

Switchipv6(){
Checkroot
if grep -Fq "#precedence ::ffff:0:0/96  100" /etc/gai.conf
then
sed -i s/'#precedence ::ffff:0:0\/96  100'/'precedence ::ffff:0:0\/96  100'/ /etc/gai.conf
echo "Set to prefer ipv4."
else
sed -i s/'precedence ::ffff:0:0\/96  100'/'#precedence ::ffff:0:0\/96  100'/ /etc/gai.conf
echo "Set to prefer ipv6."
fi
}

Saveapt(){
rm /var/lib/apt/lists/lock
rm /var/cache/apt/archives/lock
rm /var/lib/dpkg/lock
}

########
#Server Preset
########

Debiancnsource(){
Checkroot
echo "deb https://repo.debiancn.org/ buster main" > /etc/apt/sources.list.d/debiancn.list
wget https://repo.debiancn.org/pool/main/d/debiancn-keyring/debiancn-keyring_0~20161212_all.deb -O /tmp/debiancn-keyring.deb
apt install /tmp/debiancn-keyring.deb
}

Aptstablesources(){
Debiancnsource
echo -e 'deb https://deb.debian.org/debian/ stable main contrib non-free
deb https://deb.debian.org/debian/ stable-updates main contrib non-free
deb https://deb.debian.org/debian/ stable-proposed-updates main contrib non-free
deb https://deb.debian.org/debian/ stable-backports main contrib non-free
deb https://deb.debian.org/debian-security/ stable/updates main\n' > /etc/apt/sources.list
}

Apttestingsources(){
Debiancnsource
echo -e 'deb https://deb.debian.org/debian/ testing main contrib non-free
deb https://deb.debian.org/debian/ testing-updates main contrib non-free
deb https://deb.debian.org/debian/ testing-proposed-updates main contrib non-free
deb https://deb.debian.org/debian-security/ testing/updates main contrib non-free
deb https://deb.debian.org/debian/ experimental main contrib non-free\n' > /etc/apt/sources.list
}

Aptunstablesources(){
Debiancnsource
echo -e 'deb https://deb.debian.org/debian/ unstable main contrib non-free
deb https://deb.debian.org/debian/ experimental main contrib non-free\n' > /etc/apt/sources.list
}

Setsysctl(){
Checkroot
wget --no-cache https://gist.github.com/simonsmh/d5531ea7e07ef152bbe8e672da1ddd65/raw/sysctl.conf -O /etc/sysctl.conf
sysctl -p
}

Setdns(){
Checkroot
apt install -y resolvconf
echo -e 'nameserver 2001:4860:4860:0:0:0:0:8888
nameserver 2001:4860:4860:0:0:0:0:8844
nameserver 8.8.8.8
nameserver 8.8.4.4\n' > /etc/resolvconf/resolv.conf.d/base
resolvconf -u
}

Setgolang(){
Checkroot
apt install golang
mkdir ~/go
echo 'export GOPATH=$GOPATH:$HOME/go' >> ~/.bashrc
echo 'export PATH=${PATH}:$GOPATH/bin' >> ~/.bashrc
source ~/.bashrc
}

Setsh(){
read -p "Choose your team: 1.zsh 2.fish "
sed -i s/required/sufficient/g /etc/pam.d/chsh
if [ $REPLY = 1 ]
then
apt -y install git mosh zsh powerline
rm -r ~/.oh-my-zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp -f ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
sed -i "s/robbyrussell/ys/g" ~/.zshrc
sed -i "s/git/git git-extras svn last-working-dir catimg encode64 urltools wd sudo zsh-syntax-highlighting command-not-found common-aliases debian gitfast gradle npm python repo screen systemd dircycle/g" ~/.zshrc
echo "source ~/.bashrc" >> ~/.zshrc
chsh -s /usr/bin/zsh
elif [ $REPLY = 2 ]
then
apt -y install git mosh fish powerline
rm -r ~/.config/fish/config.fish ~/.config/fish/functions/
mkdir -p ~/.config/fish/functions/
wget https://github.com/fisherman/fisherman/raw/master/fisher.fish -O ~/.config/fish/functions/fisher.fish
echo "source ~/.bashrc" >> ~/.config/fish/config.fish
chsh -s /usr/bin/fish
else
echo "Bad syntax."
fi
}

Desktop(){
Checkroot
apt install -y tigervnc-scraping-server tigervnc-standalone-server tigervnc-xorg-extension xfce4 xfce4-goodies xorg fonts-noto
wget https://github.com/SYHGroup/easysystemd/raw/master/x0vncserver%40.service -O /etc/systemd/system/x0vncserver@.service
systemctl enable x0vncserver@5901.service
systemctl start x0vncserver@5901.service
}

LNMP(){
Checkroot
apt install nginx-extras mariadb-client mariadb-server php7.1-[^dev]
systemctl enable nginx mysql php7.1-fpm
sed -i  s/'upload_max_filesize = 2M'/'upload_max_filesize = 100M'/ /etc/php/7.1/fpm/php.ini
sed -i  s/'post_max_size = 8M'/'post_max_size = 100M'/ /etc/php/7.1/fpm/php.ini
sed -i  s/'short_open_tag = Off'/'short_open_tag = On'/ /etc/php/7.1/fpm/php.ini
sed -i  s/'default_socket_timeout = 60'/'default_socket_timeout = 300'/ /etc/php/7.1/fpm/php.ini
sed -i  s/'memory_limit = 128M'/'memory_limit = 64M'/ /etc/php/7.1/fpm/php.ini
sed -i  s/';opcache.enable=0'/'opcache.enable=1'/ /etc/php/7.1/fpm/php.ini
sed -i  s/';opcache.enable_cli=0'/'opcache.enable_cli=1'/ /etc/php/7.1/fpm/php.ini
sed -i  s/';opcache.fast_shutdown=0'/'opcache.fast_shutdown=1'/ /etc/php/7.1/fpm/php.ini
sed -i  s/'zlib.output_compression = Off'/'zlib.output_compression = On'/ /etc/php/7.1/fpm/php.ini
sed -i  s/';zlib.output_compression_level = -1'/'zlib.output_compression_level = 5'/ /etc/php/7.1/fpm/php.ini
sed -i  s/'allow_url_include = Off'/'allow_url_include = On'/ /etc/php/7.1/fpm/php.ini
}

Github(){
git config --global user.name "Simon Shi"
git config --global user.email simonsmh@gmail.com
git config --global credential.helper store
git config --global commit.gpgsign true
git config --global tag.gpgsign true
echo -e 'export GPG_TTY=$(tty)
export DEBEMAIL="simonsmh@gmail.com"
export DEBFULLNAME="Simon Shi"' >>~/.bashrc
#Import gpg key from keybase.io first
}

SSPreset(){
Checkroot
apt install -y build-essential gettext build-essential autoconf libtool libpcre3-dev libc-ares-dev libev-dev automake libcork-dev libcorkipset-dev libmbedtls-dev libsodium-dev python-pip python-m2crypto golang libwebsockets-dev libjson-c-dev libssl-dev
apt install -y --no-install-recommends asciidoc xmlto
wget https://github.com/SYHGroup/easy_systemd/raw/master/ssserver.service -O /etc/systemd/system/ssserver.service
Python &
Libev &
systemctl enable ssserver shadowsocks-libev
}

########
#Production Server Automatic Update
########

Updatemotd(){
Checkroot
local AVAILABLE_MEM=$(free -h |sed -n '2p' |awk '{print $7}')
local DISK_FREE=$(df / -h |sed -n '2p' |awk '{print $4}')
local XDG_RUNTIME_DIR=/run/user/$(id -u)
apt update 2>&1 |sed -n '$p' > /etc/motd
if grep -Fq 'G' <<< $DISK_FREE ; then
echo -e "\e[37;44;1m存储充足: \e[0m\e[37;42;1m ${DISK_FREE} \e[0m" >> /etc/motd
else
echo -e "\e[37;44;1m存储爆炸: \e[0m\e[37;41;1m ${DISK_FREE} \e[0m" >> /etc/motd
fi
echo -e "\e[37;44;1m可用内存: \e[0m\e[37;42;1m ${AVAILABLE_MEM} \e[0m" >>/etc/motd
for motd in nginx.service mysql.service php7.1-fpm.service transmission-daemon.service shadowsocks-libev.service x0vncserver@5901.service vlmcsd.service ssserver.service
do
if systemctl is-active $motd
then
echo -e "\e[37;44;1m$motd 状态: \e[0m\e[37;42;1m 正常 \e[0m\n"`systemctl status $motd |sed -n '$p'` >> /etc/motd
elif systemctl is-failed $motd
then
echo -e "\e[37;44;1m$motd 状态: \e[0m\e[37;41;1m 异常 \e[0m\n"`systemctl status $motd |sed -n '$p'` >> /etc/motd
else
echo -e "\e[37;44;1m$motd 状态: \e[0m\e[37;43;1m 退出 \e[0m\n"`systemctl status $motd |sed -n '$p'` >> /etc/motd
fi &
done
wait
echo -e "\e[37;40;4m上次执行: \e[0m"`date` >> /etc/motd
cat /etc/motd
}

Sysupdate(){
Checkroot
apt update
systemctl stop php7.1-fpm nginx
apt -y full-upgrade
systemctl start php7.1-fpm nginx
apt -y purge `dpkg -l |grep ^rc |awk '{print $2}'`
}

Vlmcsd(){
Checkroot
cd $rootpath
git clone https://github.com/simonsmh/vlmcsd
cd vlmcsd
git fetch
git reset --hard origin/HEAD
dpkg-buildpackage -rfakeroot -us -uc
git clean -fdx
dpkg -i ../vlmcsd_*.deb
rm ../vlmcsd*.{buildinfo,changes,deb}
}

Ttyd(){
Checkroot
cd $rootpath
git clone https://github.com/tsl0922/ttyd
cd ttyd
git fetch
git reset --hard origin/HEAD
dpkg-buildpackage -rfakeroot -us -uc
git clean -fdx
dpkg -i ../ttyd_*.deb
rm ../ttyd*.{buildinfo,changes,deb}
}

Rust(){
Checkroot
cd $rootpath
git clone https://github.com/shadowsocks/shadowsocks-rust
cd shadowsocks-rust
git fetch
git reset --hard origin/HEAD
dpkg-buildpackage -rfakeroot -us -uc
git clean -fdx
dpkg -i ../shadowsocks-rust_*.deb
rm ../shadowsocks-rust*.{buildinfo,changes,deb}
}

Libev(){
Checkroot
## Libev
cd $rootpath
git clone https://github.com/shadowsocks/shadowsocks-libev
cd shadowsocks-libev
git fetch
git reset --hard origin/HEAD
git submodule update --init --recursive
./autogen.sh
dpkg-buildpackage -rfakeroot -us -uc
git clean -fdx
## Obfs Plugin
cd $rootpath
git clone https://github.com/shadowsocks/simple-obfs
cd simple-obfs
git fetch
git reset --hard origin/HEAD
git submodule update --init --recursive
./autogen.sh
dpkg-buildpackage -rfakeroot -us -uc
git clean -fdx
## Install
cd $rootpath
dpkg -i {shadowsocks-libev,simple-obfs}_*.deb
systemctl restart shadowsocks-libev
rm *{shadowsocks-libev,simple-obfs}*.{buildinfo,changes,deb}
}

Python(){
Checkroot
cd $rootpath
pip install --upgrade git+https://github.com/shadowsocks/shadowsocks.git@master
systemctl restart ssserver
}

Go(){
go get -u github.com/shadowsocks/go-shadowsocks2
install ~/go/bin/go-shadowsocks2 /usr/bin/
systemctl restart go-shadowsocks2
}

########
#Large Script
########

NX(){
Checkroot
Aptstablesources
apt update
apt install -y nginx-extras tmux
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
systemctl restart nginx
}

TMSU(){
Checkroot
Aptstablesources
apt update
apt install -y transmission-daemon nginx-extras tmux
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
rm tr-control-easy-install.sh
systemctl enable transmission-daemon nginx
systemctl restart transmission-daemon nginx
}

########
#Help
########

Help(){
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
\t\t-unstable\tApt unstable sources
\t\t-setsysctl\tSet sysctl
\t\t-setdns\t\tSet dns
\t\t-setgolang\tSet golang
\t\t-setsh\t\tSet custome shell
\t\t-setdesktop\tSet Xfce
\t\t-lnmp\t\tNginx+Mariadb+PHP7
\t\t-gitpreset\tGitHub Preset
\t\t-sspreset\tShadowsocks Preset
\tProduction Server Automatic Update:
\t\t-m\t\tUpdate motd
\t\t-u\t\tSystem update
\t\t-v\t\tCompile Vlmcsd
\t\t-t\t\tCompile Ttyd
\t\t-sr\t\tCompile SS-Rust
\t\t-sl\t\tCompile SS-Libev
\t\t-sp\t\tCompile SS-Python
\t\t-sg\t\tCompile SS-Go
\tLarge Script:
\t\tNX\t\tNginx
\t\tTMSU\t\tTransmission+Nginx
\tShellbox:
\t\t-server\t\tRun Production Server Automatic Update
\t\tupdate\t\tUpdate shellbox.sh
\t\tRUN\t\tRun with parameter
\t\tfishroom\tRun Fishroom
\t\tkillfishroom\tKill Fishroom"
exit 0
}

########
#Running
########
for arg in "$@"
do
[ -z $1 ] && arg="help"
case $arg in
#Small Script
-checkroot)Checkroot;;
-sshroot)Sshroot;;
-ipv6)Switchipv6;;
-saveapt)Saveapt;;
#Server Preset
-stable)Aptstablesources;;
-testing)Apttestingsources;;
-unstable)Aptunstablesources;;
-setsysctl)Setsysctl;;
-setdns)Setdns;;
-setgolang)Setgolang;;
-setsh)Setsh;;
-setdesktop)Desktop;;
-lnmp|LNMP)LNMP;;
-gitpreset)Github;;
-sspreset)SSPreset;;
#Production Server Automatic Update
-m)Updatemotd;;
-u)Sysupdate;;
-t)Ttyd;;
-v)Vlmcsd;;
-sr)Rust;;
-sl)Libev;;
-sp)Python;;
-sg)Go;;
#Large Script
-nx|NX)NX;;
-tmsu|TMSU)TMSU;;
#Shellbox
-server)
Vlmcsd &
Rust &
wait
;;
u|update|upgrade)
cd $(cd "$(dirname "$0")"; pwd)
wget --no-cache https://raw.githubusercontent.com/SYHGroup/easy_shell/master/shellbox/shellbox.sh -O shellbox.sh
chmod +x shellbox.sh
exit 0
;;
fishroom)
export PYTHONPATH=/root/fishroom
tmux new-session -d -s fishroom -n core python3 -m fishroom.fishroom
tmux new-window -t fishroom -n telegram python3 -m fishroom.telegram
tmux new-window -t fishroom -n web python3 -m fishroom.web
;;
killfishroom)
tmux kill-session -t fishroom
;;
RUN)
`echo -n $* |sed -e 's/^RUN //g' |awk -F ' ' '{ print $0 }'`
exit $?
;;
-h)
Help
;;
*)
Help
exit 1
;;
esac
done
exit 0
