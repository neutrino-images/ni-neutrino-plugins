#!/bin/sh
imgbackup=$(which imgbackup-hd51)
if [ -n "$imgbackup" ];then
	$imgbackup
else
	echo "Mainscript not found"
fi
exit 0
