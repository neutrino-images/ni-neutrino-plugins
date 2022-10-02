################################################################################
#
# y-extension creation script
#
################################################################################

yext=$1
test -e yI-ext/$yext || { echo "$yext not found"; exit 1; }

. yI-ext/$yext/install.inc

echo "Processing $yI_ext_tag v$yI_ext_version"

ytmp=$(mktemp -d yI-ext.XXXXXX)

cp -a yI-ext/$yext/* $ytmp
cp -a yI-scripts/install.sh $ytmp
chmod 755 $ytmp/install.sh
cp -a yI-scripts/uninstall.sh $ytmp
chmod 755 $ytmp/uninstall.sh

ytar="yI-ext/yI-ext_${yI_ext_tag}_${yI_ext_version}.tar"
pushd $ytmp
tar -cf ../$ytar --exclude="README.md" *
popd

rm -r $ytmp

ls -al --block-size=k $ytar

#
# type:
#	m: Management Extension
#	n: Normal Extension
#	x: Menu Extension
#
#	s: Script
#	p: Plugin
#	o: One Time Run
#

#
# n/m = type, menuitem, desc, file, tag, version, url, yweb_version, info_url
# x   = type, menuitem, ymenu, file, tag, version, url, yweb_version, info_url
# u   = type, site, description, url
#
