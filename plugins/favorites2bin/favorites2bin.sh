#!/bin/sh

#	favorites2bin - Put the favorites bouquet into an installable package
#
#	Copyright (C) 2015 Sven Hoefer <svenhoefer@svenhoefer.com>
#	License: WTFPLv2

if [ ! -e /var/tuxbox/config/zapit/ubouquets.xml ]; then
	exit
fi

_dir=${1:-/tmp}
_file=${2:-favorites.bin}

echo "creating $_dir/$_file"

temp_inst=/tmp/temp_inst
inst_dir=$temp_inst/inst
ctrl_dir=$temp_inst/ctrl
preinstall=$ctrl_dir/preinstall.sh
postinstall=$ctrl_dir/postinstall.sh

rm -rf $temp_inst

mkdir -p $inst_dir
mkdir -p $ctrl_dir

cat > $preinstall << EOPRE
#!/bin/sh
#
EOPRE
chmod 0755 $preinstall

cat > $postinstall << EOPOST
#!/bin/sh
#
wget -q -O /dev/null "http://localhost/control/updatebouquet"
sleep 2
wget -q -O /dev/null "http://localhost/control/message?popup=Favoriten-Bouquet%20wurde%20installiert."
sleep 2
sync
EOPOST
chmod 0755 $postinstall

cd $inst_dir
mkdir -p var/tuxbox/config/zapit
cp -a /var/tuxbox/config/zapit/ubouquets.xml var/tuxbox/config/zapit

cd /tmp
rm -f $_dir/$_file
tar -czvf $_dir/$_file temp_inst

echo "done"

rm -rf $temp_inst
