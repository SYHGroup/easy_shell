#!/usr/bin/env bash
move-ss-built(){
cd /tmp/build-source
#rm -rf *[shadowsocks-libev,simple-obfs]*[buildinfo,changes,deb]
wwwdir="/var/wwwfiles/files/ss-debian-amd64binary"
if [ ! -d "$wwwdir" ] ; then
mkdir -p -m 755 "$wwwdir"
chown www-data:www-data "$wwwdir"
[ $? == 0 ] || exit 1
fi
List=$(ls |grep -E "\<*(shadowsocks-libev|simple-obfs)*(buildinfo|changes|deb)\>")
#List=$(ls |grep -E "(shadowsocks-libev|simple-obfs)*(buildinfo|changes|deb)$")
[ $? == 0 ] && [ -n "$List" ] || exit 1
echo "Moving built debian packages."
sudo -u www-data rm -rf "${wwwdir}/*"
for File in $List
do
mv "$File" "${wwwdir}/"
chown www-data:www-data "${wwwdir}/${File}"
done
}
move-ss-built
exit 0

