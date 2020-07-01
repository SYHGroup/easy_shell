#!/bin/sh
MOUNT=$(mktemp -d)
mkdir -p apex/lib64
for file in ./*.apex
do
    if [[ -f $file ]]; then
        unzip -o $file apex_payload.img
        sudo mount -t ext4 -o loop,ro apex_payload.img $MOUNT
        if [[ -d $MOUNT/lib64 ]]; then
            cp -rf $MOUNT/lib64/* apex/lib64/
        fi
        sudo umount $MOUNT
    fi
done
rmdir $MOUNT
