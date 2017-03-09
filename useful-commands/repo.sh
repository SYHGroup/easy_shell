#!/bin/sh

repo=(
SYHGroup/easy_shell
SYHGroup/easy_systemd
)

for line in ${repo[@]}
do
git clone git@github.com:/$line
done

mat1=(1 2)
mat3=(4 5)
while (( i <= ((${#mat1[$i]})) ))
do
echo ${mat1[$i]} ${mat3[$i]}
((i++))
done
