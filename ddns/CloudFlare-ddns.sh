#!/bin/sh
###############
Email="**@*.**"
Domain="***.**"
SubDomain="***"
APIKey="******"
USE_IPV4=true
USE_IPV6=true
###############
[ -x "$(command -v curl)" ] || exit 1
# Sleep Wait Network
if [ "${1}" = "-w" ]
then
sleep 15
fi
# Login Check
ZoneINFO=$(curl -skX GET https://api.cloudflare.com/client/v4/zones/ -H "Content-Type:application/json" -H "X-Auth-Email:${Email}" -H "X-Auth-Key:${APIKey}")
ZoneID=$(echo ${ZoneINFO}| sed -n 's/.*"id":"\(.*\)","name":"'${Domain}'".*/\1/p')
Record=$(curl -skX GET https://api.cloudflare.com/client/v4/zones/${ZoneID}/dns_records -H "Content-Type:application/json" -H "X-Auth-Email:${Email}" -H "X-Auth-Key:${APIKey}")
# IPv4
if ${USE_IPV4}
then
RecodIP4=$(curl -skX GET http://v4.ipv6-test.com/api/myip.php)
RecordID4=$(echo $Record | sed -n 's/.*"id":"\(.*\)","type":"[A]\+","name":"'${SubDomain}'.'${Domain}'".*/\1/p')
OldIP4=$(echo $Record | sed -n 's/.*"type":"[A]\+","name":"'${SubDomain}'.'${Domain}'","content":"\([0-9.]*\)".*/\1/p')
    if [ "${OldIP4}" = "${RecodIP4}" ]
    then
    Result4="Skipped."
    else
    Result4=$(curl -sX PUT https://api.cloudflare.com/client/v4/zones/${ZoneID}/dns_records/${RecordID4} -H "Content-Type:application/json" -H "X-Auth-Email:${Email}" -H "X-Auth-Key:${APIKey}" --data '{"type":"A","name":"'${SubDomain}'.'${Domain}'","content":"'${RecodIP}'","ttl":1,"proxied":false}' |grep -Eo '"success"[^,]*,')
        if [ ${?} -ne 0 ]
        then
        Result4='cURL failed.'
        fi
    fi
fi
# IPv6
if ${USE_IPV6}
then
RecodIP6=$(curl -skX GET http://v6.ipv6-test.com/api/myip.php)
RecordID6=$(echo $Record | sed -n 's/.*"id":"\(.*\)","type":"[AAAA]\+","name":"'${SubDomain}'.'${Domain}'".*/\1/p')
OldIP6=$(echo $Record | sed -n 's/.*"type":"[AAAA]\+","name":"'${SubDomain}'.'${Domain}'","content":"\([^\"]*\)".*/\1/p')
    if [ "${OldIP6}" = "${RecodIP6}" ]
    then
    Result6="Skipped."
    else
    Result6=$(curl -sX PUT https://api.cloudflare.com/client/v4/zones/${ZoneID}/dns_records/${RecordID6} -H "Content-Type:application/json" -H "X-Auth-Email:${Email}" -H "X-Auth-Key:${APIKey}" --data '{"type":"AAAA","name":"'${SubDomain6}'.'${Domain}'","content":"'${RecodIP6}'","ttl":1,"proxied":false}' |grep -Eo '"success"[^,]*,')
        if [ ${?} -ne 0 ]
        then
        Result6='cURL failed.'
        fi
    fi
fi
[ -x "$(command -v logger)" ] && logger -s "CloudFlare-ddns.sh: $(date) IPV4 ${Result4} IPV6 ${Result6}."
exit 0