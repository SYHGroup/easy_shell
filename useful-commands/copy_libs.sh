#!/bin/sh -x
OUT="recovery/root/vendor/lib64/"
EXTRACT="/mnt/storage/WorkGround/umi/R_MIUI/miui_UMI_20.6.28_a5e0d69c19_11.0"
FILES=$(find $OUT -maxdepth 1 -type f -exec basename {} \;)
for file in $FILES
do
    LIB=$(sudo find $EXTRACT/vendor/bin $EXTRACT/vendor/lib64 $EXTRACT/system/system/lib64 $EXTRACT/apex/apex/lib64 -type f -iname $file | head -n 1)
    if [[ -f $LIB ]]; then
        echo Success: $LIB "->" $OUT/$file
        cp $LIB $OUT
        if grep -q /system/bin/linker64 $OUT/$file; then
            echo Relink: $OUT/$file
            sed -i "s|/system/bin/linker64\x0|/sbin/linker64\x0\x0\x0\x0\x0\x0\x0|g" $OUT/$file
        fi
    else
        echo Not found: $OUT/$file
    fi
done
