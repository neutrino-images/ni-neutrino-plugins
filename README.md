for plugin in getrc input logomask logoview msgbox scripts-lua shellexec tuxcal tuxcom tuxmail tuxwetter; do
	git subtree add --prefix=$plugin https://github.com/tuxbox-neutrino/plugin-$plugin.git master
done
