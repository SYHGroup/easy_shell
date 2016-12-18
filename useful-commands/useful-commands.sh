#!/usr/bin/env bash
function GatewayPorts(){
  #sshpf
  echo "GatewayPorts yes" >> /etc/ssh/sshd_config
}
function GitSetup(){
  #git setup
  git config --global user.name "Jerry"
  git config --global user.email "Jerry981028@gmail.com"
  sed -i 's/https:\/\/github.com\//git@github.com:/g' ./.git/config
  git add .
  git commit
  git push
}
function SystemControl(){
  #wifi led blink off
  echo none > /sys/class/leds/phy0-led/trigger
  #cpufreq-set
  #apt install cpufrequtils
  cpufreq-set -c 0 -u 800000
  cpufreq-set -c 1 -u 800000
  #uuid
  #查看硬盘UUID
  ls -l /dev/disk/by-uuid
  blkid /dev/sdb2
  uuidgen | xargs tune2fs /dev/sdb2 -U
  #original uuid = 7651122e-84c1-4e85-956b-4860651fb019 (/dev/sda3)
  tune2fs -U 735a2fd3-9425-4ddd-9c91-a57e3ebbaeff /dev/sdb2
  #apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 2D87398A
}
exit 0