#!/usr/bin/env bash
set -x
primaryDisk=/dev/sda
debianVersion=testing
myChroot=/debian-chroot
Stage1(){
pacman -Syu debootstrap
parted ${primaryDisk} mklabel gpt
parted ${primaryDisk} mkpart efi fat32 0 128MB
parted ${primaryDisk} mkpart debian ext4 128MB 100%
mkfs.ext4 ${primaryDisk}2
mkfs.vfat -F 32 ${primaryDisk}1
mkdir ${myChroot}
mount ${primaryDisk}2 ${myChroot}
debootstrap --arch amd64 ${debianVersion} ${myChroot} https://mirrors.ustc.edu.cn/debian/
#cp /proc/mounts ${myChroot}/etc/mtab
# Must find a way to get rid of genfstab
mkdir -p ${myChroot}/boot/efi
mount ${primaryDisk}1 ${myChroot}/boot/efi
genfstab -U ${myChroot} >> ${myChroot}/etc/fstab
mount /proc ${myChroot}/proc -t proc
mount /sys ${myChroot}/sys -t sysfs
mount /sys/firmware/efi/efivars ${myChroot}/sys/firmware/efi/efivars -t efivarfs -o nosuid,noexec,nodev
mount /dev ${myChroot}/dev -t devtmpfs -o mode=0755,nosuid
mount /dev/pts ${myChroot}/dev/pts -t devpts -o mode=0620,gid=5,nosuid,noexec
mount /dev/shm ${myChroot}/dev/shm -t tmpfs -o mode=1777,nosuid,nodev
mount /run ${myChroot}/run -t tmpfs -o nosuid,nodev,mode=0755
mount /tmp ${myChroot}/tmp -t tmpfs -o mode=1777,strictatime,nodev,nosuid
cp $0 ${myChroot}/
chroot ${myChroot} /bin/bash
}
Stage2(){
export PATH=${PATH}:/sbin:/usr/sbin
apt update
apt list linux-image* |grep -E "linux-image-[0-9].[0-9]+.[0-9]+-[0-9]+-amd64[^-]" |cut -d '/' -f 1 |head -n 1| xargs apt install -y
apt install -y grub-efi
if [ -d /sys/firmware/efi ]; then
echo "Not efi system"
exit 1; fi
grub-install ${primaryDisk}
update-grub
echo "ok"
echo "set password for root, install firmware, then ctrl d to exit, umount -R ${myChroot} and reboot"
}

[ "$*" == "1" ] && Stage1
[ "$*" == "2" ] && Stage2