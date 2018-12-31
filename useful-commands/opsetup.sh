#!/bin/sh
sed -i 's/downloads.openwrt.org/mirrors.ustc.edu.cn\/lede/g' /etc/opkg/distfeeds.conf

# SSL Required Packages
opkg update
opkg install \
ca-bundle \
ca-certificates \
libustream-mbedtls

sed -i 's/http/https/g' /etc/opkg/distfeeds.conf
echo "src/gz simonsmh_base http://github.com/simonsmh/openwrt-dist/raw/ipq806x/packages/arm_cortex-a15_neon-vfpv4/base
src/gz simonsmh_packages http://github.com/simonsmh/openwrt-dist/raw/ipq806x/targets/ipq806x/generic/packages" >> /etc/opkg/customfeeds.conf

# Basic Packages
opkg update
opkg install \
block-mount \
coreutils \
coreutils-base64 \
curl \
ip-full \
iptables-mod-tproxy \
kmod-fs-nfs \
kmod-fs-xfs \
kmod-usb-storage-extras \
libmbedtls \
luci-app-dns-forwarder \
luci-app-nfs \
luci-app-samba \
luci-app-shadowsocks \
luci-i18n-base-zh-cn \
luci-i18n-firewall-zh-cn \
luci-i18n-samba-zh-cn \
mount-utils \
nfs-kernel-server-utils \
nfs-utils \
rsync \
shadowsocks-libev

wget https://github.com/SYHGroup/easy_shell/raw/master/ddns/CloudFlare-ddns.sh
wget https://github.com/SYHGroup/easy_shell/raw/master/useful-commands/update_list
wget https://github.com/cokebar/gfwlist2dnsmasq/raw/master/gfwlist2dnsmasq.sh

echo "30 4 * * 0 /root/update_list >/dev/null 2>&1
0 */3 * * * /root/CloudFlare-ddns.sh >/dev/null 2>&1
#30 2 * * 0 opkg update && opkg upgrade `opkg list-upgradable | awk '{printf $1\" \"}'`" >> /etc/crontabs/root

uci set shadowsocks.@access_control[0].wan_bp_list='/etc/chinadns_chnroute.txt'
uci set dhcp.@dnsmasq[0].serversfile='/etc/dnsmasq_gfwlist.conf'