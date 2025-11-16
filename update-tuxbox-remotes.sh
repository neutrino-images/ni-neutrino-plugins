#!/bin/sh

REPLIST="cooliTSclimax getrc input logomask logoview msgbox scripts-lua shellexec sysinfo tuxcal tuxcom tuxmail tuxwetter"

export GIT_MERGE_AUTOEDIT=no
for plugin in $REPLIST; do
	git subtree pull --prefix=$plugin https://github.com/tuxbox-neutrino/plugin-$plugin.git master || exit 1
done
git subtree pull --prefix=scripts-lua/plugins/mediathek https://github.com/tuxbox-neutrino/plugin-lua-neutrino-mediathek.git master
