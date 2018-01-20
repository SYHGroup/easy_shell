#!/bin/sh
usb="/sys/class/android_usb/android0"
file = $1
# ro = $2
enable = $2
echo 0 > $usb/enable
grep mass_storage $usb/functions > /dev/null || sed -e 's/$/mass_storage/' $usb/functions | cat > $usb/functions
[[ -z $(cat $usb/functions) ]] && echo mass_storage > $usb/functions
[[ 0 == $enable ]] && sed -e 's/mass_storage//' $usb/functions | cat > $usb/functions
echo disk > $usb/f_mass_storage/luns
echo 1 > $usb/enable
echo > $usb/f_mass_storage/lun0/file
echo 0 > $usb/f_mass_storage/lun0/ro
echo $file > $usb/f_mass_storage/lun0/file
echo > $usb/f_mass_storage/lun/file
echo 0 > $usb/f_mass_storage/lun/ro
echo $file > $usb/f_mass_storage/lun/file
echo success