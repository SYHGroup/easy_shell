#!/bin/sh
# Requirements: wget unzip
######
BOOTIMAGE=$1
KEEPVERITY=true
KEEPFORCEENCRYPT=true
RECOVERYMODE=false
filename=magisk.apk
######
[ -f $filename ] || wget https://github.com/topjohnwu/Magisk/releases/download/v22.0/Magisk-v22.0.apk -O $filename
[ -z $1 ] && { echo "Usage: $0 <boot.img>" && exit 1 ;}
[ -f $filename ] || { echo "Error: Need $filename" && exit 1 ;}
unzip $filename lib/x86/libmagiskboot.so
unzip $filename lib/armeabi-v7a/libmagiskinit.so
unzip $filename lib/armeabi-v7a/libmagisk32.so
unzip $filename lib/armeabi-v7a/libmagisk64.so
mv lib/x86/libmagiskboot.so ./magiskboot
mv lib/armeabi-v7a/libmagiskinit.so ./magiskinit
mv lib/armeabi-v7a/libmagisk32.so ./magisk32
mv lib/armeabi-v7a/libmagisk64.so ./magisk64
rm -r lib
chmod +x magiskboot
export KEEPVERITY
export KEEPFORCEENCRYPT
SHA1=`./magiskboot sha1 "$BOOTIMAGE"`
echo "KEEPVERITY=$KEEPVERITY
KEEPFORCEENCRYPT=$KEEPFORCEENCRYPT
RECOVERYMODE=$RECOVERYMODE
SHA1=$SHA1" > config
./magiskboot unpack $BOOTIMAGE
cp -af ramdisk.cpio ramdisk.cpio.orig
./magiskboot compress=xz magisk32 magisk32.xz
./magiskboot compress=xz magisk64 magisk64.xz
./magiskboot cpio ramdisk.cpio \
        "add 0750 init magiskinit" \
        "mkdir 0750 overlay.d" \
        "mkdir 0750 overlay.d/sbin" \
        "add 0644 overlay.d/sbin/magisk32.xz magisk32.xz" \
        "add 0644 overlay.d/sbin/magisk64.xz magisk64.xz" \
        "patch" \
        "backup ramdisk.cpio.orig" \
        "mkdir 000 .backup" \
        "add 000 .backup/.magisk config"
for dt in dtb kernel_dtb extra; do
        [ -f $dt ] && ./magiskboot dtb $dt patch
done
./magiskboot hexpatch kernel \
        736B69705F696E697472616D667300 \
        77616E745F696E697472616D667300
./magiskboot repack $BOOTIMAGE
./magiskboot cleanup
rm -f ramdisk.cpio.orig config magisk32* magisk64* magiskboot magiskinit
