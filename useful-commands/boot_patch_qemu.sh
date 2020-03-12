#!/bin/sh
# Requirements:
# QEMU arm  magiskinit64
# x86       magiskboot
######
BOOTIMAGE=$1
KEEPVERITY=true
KEEPFORCEENCRYPT=true
RECOVERYMODE=false
######
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
rm -f ramdisk.cpio.orig config magisk
