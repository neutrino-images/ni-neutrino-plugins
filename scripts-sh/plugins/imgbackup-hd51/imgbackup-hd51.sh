#!/bin/sh
# Script for complete image backup
# (C) 2018 DboxOldie
# License: GPLv2 or later
Version="1.0 v. 13.09.2018"
#
file=$0
model=`cat /proc/stb/info/model`
save_path="/tmp"
tmproot="/tmp/buroot"
destname="imgbackup-hd51_$(date +%d.%m.%Y-%H.%M)"
archive="tgz"
knl=0
klen=0
bz2=$(which bzip2)
hexd=$(which hexdump)
#
magic_number="0x016f2818"
#magic_number="0x016f2810"
dtb_magic_number="0xd00dfeed"
#
# Root und Kernel Partition bestimmen
#
rootmtd=`readlink /dev/root`
rootnumber=`echo ${rootmtd:8:1}`
mmcprefix=`echo ${rootmtd:0:8}`
kernelnumber=$((rootnumber -1))
kernelmtd=$mmcprefix$kernelnumber

echo "  HD51 Image Backup (Version: $Version)"
if [ "$model" == "hd51" ];then
	echo "  Image Backup für Boxmodel '$model' startet..."
else
	echo "  Falsche Box...Abbruch"
	exit 0
fi

if [ -z "$bz2" ];then
	echo "  Kein 'bzip2' im Image"
	echo "  packen von 'rootfs.tar.bz2' nicht möglich"
	echo "  Abbruch... !!"
	exit 0
fi

if [ $kernelnumber -lt 9 -a $kernelnumber -gt 1 ];then
	echo
	echo "  Bootdevice   = $rootmtd"
	echo "  Kerneldevice = $kernelmtd"
else
	echo "  Kernel MTD nicht im Bereich ( 2,4,6,8 ) !! > $kernelnumber"
	echo "  Abbruch !!"
	exit 0
fi

# Parameter auslesen
#
while [ $# -gt 0 ]
do
	parm=$1
	[ "$parm" == "none" ] && archive=$parm
	[ "$(echo ${parm:0:1})" == "/" ] && save_path=$parm
	shift
done

[ "$archive" == "none" ] && save_path="$save_path/$destname"

k_backup()
{
	if [ -z "$hexd" ];then
		echo "  Missing Busybox Applet 'hexdump'"
		echo "$gelb skip Kernel Backup"
		knl=0
	else
		knl=1
		k_check
	fi
}

k_check()
{
# 16 Bytes ( 33 bis 49 ) aus Kernel Partition lesen
#
line=`dd if=/dev/$kernelmtd bs=1 skip=32 count=16 2> /dev/null | hexdump -C`

# Kernelmagic für zImage prüfen
#
kmagic="0x"
kmagic=$kmagic`echo $line | cut -d " " -f9`
kmagic=$kmagic`echo $line | cut -d " " -f8`
kmagic=$kmagic`echo $line | cut -d " " -f7`
kmagic=$kmagic`echo $line | cut -d " " -f6`

echo
if [ "$kmagic" == "$magic_number" ];then
	echo "  Magic für zImage gefunden > $kmagic == $magic_number"
else
	echo "  Keine Magic für zImage gefunden > $kmagic != $magic_number"
	echo "$gelb skip Kernel Backup"
	knl=0
fi
if [ "$knl" == "1" ];then
# zImage Länge bestimmen
#
	zimage_len="0x"
	zimage_len=$zimage_len`echo $line | cut -d " " -f17`
	zimage_len=$zimage_len`echo $line | cut -d " " -f16`
	zimage_len=$zimage_len`echo $line | cut -d " " -f15`
	zimage_len=$zimage_len`echo $line | cut -d " " -f14`

	echo "  zImage Länge = $((zimage_len)) Bytes"

# Prüfung auf DTB
#
# 16 Bytes ( ab zImage Länge ) aus Kernel Partition lesen
#
	line=`dd if=/dev/$kernelmtd bs=1 skip=$((zimage_len)) count=16 2> /dev/null | hexdump -C`

	dtb_magic="0x"
	dtb_magic=$dtb_magic`echo $line | cut -d " " -f2`
	dtb_magic=$dtb_magic`echo $line | cut -d " " -f3`
	dtb_magic=$dtb_magic`echo $line | cut -d " " -f4`
	dtb_magic=$dtb_magic`echo $line | cut -d " " -f5`

	if [ "$dtb_magic" == "$dtb_magic_number" ];then
		echo "  DTB Bereich vorhanden"
# DTB Länge bestimmen
#
		dtb_len="0x"
		dtb_len=$dtb_len`echo $line | cut -d " " -f6`
		dtb_len=$dtb_len`echo $line | cut -d " " -f7`
		dtb_len=$dtb_len`echo $line | cut -d " " -f8`
		dtb_len=$dtb_len`echo $line | cut -d " " -f9`
		echo "  DTB Länge = $((dtb_len)) Bytes"
	else
		echo "$gelb Kein DTB Bereich vorhanden"
		dtb_len=0
	fi

# Endgültige Kernellänge
#
	klen=$((zimage_len + dtb_len))

	echo "  Gesamt Kernel Länge = $klen Bytes"
	k_read
fi
}
#
k_read()
{
# Kernel aus Partition auslesen
#
count=`echo $((klen / 4096))`
len1=`echo $((count * 4096))`
rest=`echo $((klen - len1))`

dd if=/dev/$kernelmtd of=$save_path/kernel_1.bin bs=4096 count=$count 2> /dev/null
dd if=/dev/$kernelmtd of=$save_path/kernel_2.bin bs=1 count=$rest skip=$len1 2> /dev/null

cat $save_path/kernel_*.bin > $save_path/kernel.bin

rm -f $save_path/kernel_*.bin

echo
echo "  'kernel.bin' in $save_path gespeichert"
}
#
r_backup()
{
mkdir -p $tmproot
mount --bind / $tmproot

echo
echo "  erstelle 'rootfs.tar'"
tar -cf $save_path/rootfs.tar -C $tmproot ./ 2> /dev/null
echo "  packe 'rootfs.tar' zu rootfs.tar.bz2'"
echo "  dauert ca. 1 bis 2 Minuten...."
$bz2 $save_path/rootfs.tar

umount -f $tmproot
[ -z "$(mount | grep $tmproot)" ] && rm -rf $tmproot

if [ "$archive" == "tgz" ];then
	echo "  erstelle Image Archiv '$destname.tgz' in $save_path"
	tar -czf $save_path/$destname.tgz -C $save_path kernel.bin rootfs.tar.bz2
	rm -f $save_path/kernel.bin
	rm -f $save_path/rootfs.tar.bz2
	echo
	echo "  Image Archiv '$destname.tgz' gespeichert in $save_path"
else
	echo
	echo "  'rootfs.tar.bz2' in $save_path gespeichert"
fi

}


# main
mkdir -p $save_path
k_backup
r_backup

exit 0
