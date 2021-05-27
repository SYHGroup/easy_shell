#!/bin/bash
# Requirements: curl unzip
######
WAITING=5
######
[ -z $1 ] && { echo "Usage: $0 <miui_rom_str>" && exit 1 ;} || zipstr=$1
tmp=${zipstr#*_}
device=${tmp%%_*}
tmp=${tmp#*_}
version=${tmp%%_*}
tmp=${tmp#*_}
hash=${tmp%%_*}
tmp=${tmp#*_}
api=${tmp%%.zip}
zipstr=miui_${device}_${version}_${hash}_${api}.zip
[ -z $device ] || [ -z $version ] || [ -z $hash ] || [ -z $api ] && { echo "Error: Bad str $1" && exit 1 ;} || [ ! -f $zipstr ] && { echo "Downloading $zipstr"
aria2c -j10 https://bigota.d.miui.com/$version/$zipstr
while [ -f $zipstr.aria2 ]
do
echo "Warning: Trying again after ${WAITING}s..." && sleep $WAITING
aria2c -j10 https://bigota.d.miui.com/$version/$zipstr
done
}
yes | unzip $zipstr boot.img
sh boot_patch_app.sh boot.img
zstd new-boot.img -f
rm -f new-boot.img
