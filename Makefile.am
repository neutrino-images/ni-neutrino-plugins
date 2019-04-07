AUTOMAKE_OPTIONS = gnu

SUBDIRS = \
	cooliTSclimax \
	emmrd \
	FritzCallMonitor \
	FritzInfoMonitor \
	getrc \
	input \
	logomask \
	msgbox \
	oscammon \
	satfind \
	shellexec \
	showiframe \
	tuxcal \
	tuxcom \
	tuxmail \
	tuxwetter \
	vinfo

SUBDIRS += \
	scripts-lua/plugins/ard_mediathek \
	scripts-lua/plugins/epgfilter \
	scripts-lua/plugins/EPGscan \
	scripts-lua/plugins/favorites2bin \
	scripts-lua/plugins/LocalTV \
	scripts-lua/plugins/logoupdater \
	scripts-lua/plugins/mtv \
	scripts-lua/plugins/netzkino \
	scripts-lua/plugins/openvpn-setup \
	scripts-lua/plugins/stb_startup \
	scripts-lua/plugins/userbouquets

uninstall-hook:
	-rmdir $(DESTDIR)$(PLUGINDIR)