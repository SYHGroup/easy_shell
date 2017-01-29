# Dnspod-ddns-sh

非常简易的 DNSPod DDNS 脚本。  
需要创建 DNSPod API token。  
需要`curl`支持。  
适合所有发行版平台，包括 openwrt。

## 使用

1. `wget https://raw.githubusercontent.com/simonsmh/Dnspod-ddns-sh/master/dnspod-ddns.sh`  
2. 根据[DNSPod](https://support.dnspod.cn/Kb/showarticle/tsid/227/)，获取并在脚本填写 API Token 和 TokenID。  
3. 在DNSPod添加需要DDNS的域名和二级域名，并在脚本填写该域名。  
4. 在系统-计划任务中，添加`0 */3 * * * sh /etc/dnspod-ddns.sh`即可每3小时自动更新。  

# CloudXNS-DDNS
看到很多 CloudXNS 的 DDNS 客户端都是基于官方的 Python SDK 做的，于是根据官方的API文档撸了个 bash 下的一个轮子。

## 特点
1. 系统需支持 curl 命令，适合在闪存容量小，不能安装 Python 的路由器上运行。
2. 在CloudXNS[申请API Key](https://www.cloudxns.net/AccountManage/apimanage.html)，只需要在脚本中填写 API Key ，不需要提供账号密码，绿色安全。
3. 不像 DNSPod 那样繁琐，需要先通过客户端查询域名ID、记录ID，只需提供需要 DDNS 的域名。

## 用法
1. `wget https://raw.githubusercontent.com/kuretru/CloudXNS-DDNS/master/CloudXNS-ddns.sh`
2. 在[CloudXNS](https://www.cloudxns.net/AccountManage/apimanage.html)获得 API Key 后，将 API Key、Secret Key 填入脚本。
3. 在CloudXNS添加需要DDNS的域名，并在脚本填写该域名。  
`domain="www.cloudxns.net."`
4. 执行`sh CloudXNS-ddns.sh`。

## Credit

Copyright (C) 2016 simonsmh <simonsmh@gmail.com>  

## LICENSE
GNU General Public License v3.0