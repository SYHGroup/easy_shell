# ss.sh

## /etc/NetworkManager/NetworkManager.conf
```
[main]
dns=dnsmasq
```

## gfwlist2dnsmasq.sh
```
A=$(cat gfwlist2dnsmasq.sh) && (rm gfwlist2dnsmasq.sh; wget $A; chmod +x gfwlist2dnsmasq.sh)
```
