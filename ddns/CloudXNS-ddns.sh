#!/bin/sh
#==================================================
# OS Required: Linux with curl
# Description: CloudXNS DDNS on bash
# Author: Kuretru
# Version: 1.1.160913
# Github: https://github.com/kuretru/CloudXNS-DDNS/
#==================================================

#API Key
api_key=""
 
#Secret Key
secret_key=""
 
#Domain name
#e.g. domain="www.cloudxns.net."
domain=""

value=$(curl members.3322.org/dyndns/getip)
url="https://www.cloudxns.net/api2/ddns"
time=$(date -R)
data="{\"domain\":\"${domain}\",\"ip\":\"${value}\",\"line_id\":\"1\"}"
mac_raw="$api_key$url$data$time$secret_key"
mac=$(echo -n $mac_raw | md5sum | awk '{print $1}')
header1="API-KEY:"$api_key
header2="API-REQUEST-DATE:"$time
header3="API-HMAC:"$mac
header4="API-FORMAT:json"

result=$(curl -k -X POST -H $header1 -H "$header2" -H $header3 -H $header4 -d "$data" $url)
echo "${result} ${time} ${data}" 
