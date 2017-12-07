#!/bin/sh
###############
Email="**@*.**"
Domain="***.**"
SubDomain="***"
APIKey="******"
###############
if [ ! -x "$(command -v curl)" ]
then
echo "Cannot find cURL."
exit 1
fi
RecodIP=$(curl -skX GET members.3322.org/dyndns/getip)
ZoneINFO=$(curl -skX GET https://api.cloudflare.com/client/v4/zones/ -H "Content-Type:application/json" -H "X-Auth-Email:${Email}" -H "X-Auth-Key:${APIKey}")
ZoneID=$(echo ${ZoneINFO}| sed -n 's/.*"id":"\(.*\)","name":"'${Domain}'".*/\1/p')
Record=$(curl -skX GET https://api.cloudflare.com/client/v4/zones/${ZoneID}/dns_records -H "Content-Type:application/json" -H "X-Auth-Email:${Email}" -H "X-Auth-Key:${APIKey}")
RecordID=$(echo $Record | sed -n 's/.*"id":"\(.*\)","type":"[A]\+","name":"'${SubDomain}'.'${Domain}'".*/\1/p')
OldIP=$(echo $Record | sed -n 's/.*"type":"[A]\+","name":"'${SubDomain}'.'${Domain}'","content":"\([0-9.]*\)".*/\1/p')
if [ "${OldIP}" = "${RecodIP}" ]
then
Result="Action skipped successfully"
else
Result=$(curl -X PUT https://api.cloudflare.com/client/v4/zones/${ZoneID}/dns_records/${RecordID} -H "Content-Type:application/json" -H "X-Auth-Email:${Email}" -H "X-Auth-Key:${APIKey}" --data '{"type":"A","name":"'${SubDomain}'.'${Domain}'","content":"'${RecodIP}'","ttl":1,"proxied":false}' |grep -Eo '"success"[^,]*,')
if [ ${?} -ne 0 ]
then
Result='cURL failed.'
fi
fi
if [ -x "$(command -v logger)" ]
then
logger -s "CloudFlare-ddns.sh: $(date) ${Result}"
else
echo "CloudFlare-ddns.sh: $(date) ${Result}"
fi
exit 0
