#!/bin/sh
# Requirements:
# QEMU arm  magiskinit64
# x86       magiskboot curl unzip
######
BOOTIMAGE=$1
KEEPVERITY=true
KEEPFORCEENCRYPT=true
RECOVERYMODE=false
######
[ -f magisk-release.zip ] || wget https://github.com/topjohnwu/magisk_files/raw/canary/magisk-release.zip -O magisk-release.zip
unzip magisk-release.zip x86/magiskboot
unzip magisk-release.zip arm/magiskinit64
mv x86/magiskboot ./
mv arm/magiskinit64 ./
rmdir x86 arm
chmod +x magiskboot magiskinit64
export KEEPVERITY
export KEEPFORCEENCRYPT
SHA1=`./magiskboot sha1 "$BOOTIMAGE"`
echo "KEEPVERITY=$KEEPVERITY
KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT
RECOVERYMODE=$RECOVERYMODE
SHA1=$SHA1" > config
[ -e magisk ] || qemu-arm magiskinit64 -x magisk magisk
./magiskboot unpack $BOOTIMAGE
cp -af ramdisk.cpio ramdisk.cpio.orig
./magiskboot cpio ramdisk.cpio \
"add 750 init magiskinit64" \
"patch" \
"backup ramdisk.cpio.orig" \
"mkdir 000 .backup" \
"add 000 .backup/.magisk config"
./magiskboot dtb dtb patch
./magiskboot hexpatch kernel \
736B69705F696E697472616D667300 \
77616E745F696E697472616D667300
./magiskboot repack $BOOTIMAGE
./magiskboot cleanup
rm -f ramdisk.cpio.orig config magisk*
