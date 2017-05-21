#!/bin/sh
###############
TokenID="*****"
Token="*******"
SubDomain="***"
Domain="******"
RecordTTL=600
###############
if [ ! -x "$(command -v curl)" ]
then
echo "Cannot find cURL."
exit 1
fi
#if [ ! -x "$(command -v nc)" ]
#then
RecodIP=$(curl members.3322.org/dyndns/getip)
#else
#RecodIP=$(nc ns1.dnspod.net 6666)  # This command is out of date.
#fi
List=$(curl -skX POST https://dnsapi.cn/Record.List -d "login_token=${TokenID},${Token}&format=json&domain=${Domain}&sub_domain=${SubDomain}")
RecodID=$(echo $List|sed -n 's/.*"id":"\([0-9]*\)".*"name":"'${SubDomain}'".*/\1/p')
OldIP=$(echo $List|sed -n 's/.*"value":"\([0-9.]*\)".*"name":"'${SubDomain}'".*/\1/p')
OldTTL=$(echo $List|sed -n 's/.*"ttl":"\([0-9]*\)".*"name":"'${SubDomain}'".*/\1/p')
if [ $OldIP == $RecodIP ]&&[ $OldTTL == $RecordTTL ]
then
Result="Action skipped successful"
else
Result=$(curl -skX POST https://dnsapi.cn/Record.Modify -d "login_token=${TokenID},${Token}&format=json&record_id=${RecodID}&domain=${Domain}&sub_domain=${SubDomain}&value=${RecodIP}&ttl=${RecordTTL}&record_type=A&record_line_id=0" | sed -n 's/.*"message":"\(.*\)","created_at".*/\1/p')
fi
if [ -x "$(command -v logger)" ]
then
logger -s "Dnspod-ddns.sh: $(date) ${Result}"
else
echo "Dnspod-ddns.sh: $(date) ${Result}"
fi
exit 0
