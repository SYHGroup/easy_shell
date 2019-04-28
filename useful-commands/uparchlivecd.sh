#!/bin/bash

# !! Make sure your partition has a label !! See line 11
# How to use:
# mkdir -p /livecd
# place this script inside /livecd
# run this script
# grub command:
#   cat livecd/archiso-x86_64.conf
#   set root=(xxx)
#   linux /livecd/vmlinuz archisobasedir=livecd archisolabel=YOUR_LABEL
#   initrd /livecd/YOUR_ucode.img
#   initrd /livecd/archiso.img
#   boot

#[jerry@jerry livecd]$  tree /livecd
#/livecd
#├── 2019-04-01
#├── amd_ucode.img
#├── archiso.img
#├── archiso-x86_64.conf
#├── default.network
#├── intel_ucode.img
#├── vmlinuz
#└── x86_64
#    ├── airootfs.sfs
#    ├── airootfs.sfs.sig
#    └── airootfs.sha512

die() {
    echo $@
    exit 1
}
read -p 'Place this script inside a empty dir. [Enter]'

MIRROR="https://mirrors.tuna.tsinghua.edu.cn/archlinux"
ISO_DIR="iso/latest"
MD5SUM="${MIRROR}/${ISO_DIR}/md5sums.txt"

SUDO='sudo'
[[ $EUID == 0 ]] && SUDO=''

wget -O md5sum ${MD5SUM}

md5=$(cat md5sum |grep -F '.iso')
ISO=$(awk '{print $2;}' <<< "$md5")
echo "$md5" > md5sum

if [[ -n $ISO ]]; then
    [[ -f $ISO ]] && echo "iso exists" || wget -O ${ISO} "${MIRROR}/${ISO_DIR}/${ISO}"
else
    die "iso not found"
fi
md5sum -c md5sum || die "md5sum check failed"

mkdir -p mnt
$SUDO mount -o loop,ro ${ISO} mnt || die "mount failed"

echo "copying..."
DST='./'
cp mnt/arch/boot/{amd_ucode.img,intel_ucode.img} ${DST}
cp -R mnt/arch/x86_64 ${DST}
cp mnt/arch/boot/x86_64/{archiso.img,vmlinuz} ${DST}
cp mnt/loader/entries/archiso-x86_64.conf ${DST}
echo "done copying"

$SUDO umount mnt && echo "unmount successful" || echo "!! unmount failed"

read -p "Delete iso file? [Enter]"
rm "$ISO"
