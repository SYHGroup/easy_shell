#!/bin/sh
code=RIfrSEq
string="Keep Out!\"$code\"Keep Out!"
md5check(){
if (echo -n $string|md5sum|grep $1)
then
echo $code
fi
}
md5check 1b22289d656182b24547f307c9d368b7
md5check 552bc26417cb2969badc8f1229797571
