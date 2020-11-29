#!/bin/sh
model=`cat /proc/stb/info/model`
[ -e /proc/stb/info/vumodel ] && vumodel=`cat /proc/stb/info/vumodel`
[ "$model" == "dm8000" ] && [ "$vumodel" == "solo4k" ] && model=$vumodel
[ "$model" == "dm8000" ] && [ "$vumodel" == "duo4k" ] && model=$vumodel
[ "$model" == "dm8000" ] && [ "$vumodel" == "duo4kse" ] && model=$vumodel
[ "$model" == "dm8000" ] && [ "$vumodel" == "zero4k" ] && model=$vumodel
[ "$model" == "dm8000" ] && [ "$vumodel" == "ultimo4k" ] && model=$vumodel
[ "$model" == "dm8000" ] && [ "$vumodel" == "uno4k" ] && model=$vumodel
[ "$model" == "dm8000" ] && [ "$vumodel" == "uno4kse" ] && model=$vumodel
rootmtd=`readlink /dev/root`
if [ "$model" == "solo4k" -o "$model" == "ultimo4k" -o "$model" == "uno4k" -o "$model" == "uno4kse" ] && [ "$rootmtd" == "mmcblk0p4" ] || \
   [ "$model" == "zero4k" ] && [ "$rootmtd" == "mmcblk0p7" ] || \
   [ "$model" == "duo4k" -o "$model" == "duo4kse" ] && [ "$rootmtd" == "mmcblk0p9" ]; then
	/usr/share/tuxbox/neutrino/plugins/imgbackup select_dir
else
	/usr/share/tuxbox/neutrino/plugins/imgbackup gui
fi
exit 0
