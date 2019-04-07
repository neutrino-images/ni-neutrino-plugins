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
	stbup \
	tuxcal \
	tuxcom \
	tuxmail \
	tuxwetter \
	vinfo

SUBDIRS += \
	scripts-lua/plugins/add-locale \
	scripts-lua/plugins/ard_mediathek \
	scripts-lua/plugins/epgfilter \
	scripts-lua/plugins/EPGscan-setup \
	scripts-lua/plugins/favorites2bin \
	scripts-lua/plugins/heizoelpreise \
	scripts-lua/plugins/LocalTV \
	scripts-lua/plugins/logoupdater \
	scripts-lua/plugins/mtv \
	scripts-lua/plugins/netzkino \
	scripts-lua/plugins/openvpn-setup \
	scripts-lua/plugins/stb_startup \
	scripts-lua/plugins/userbouquets

SUBDIRS += \
	scripts-sh/plugins/autoreboot \
	scripts-sh/plugins/dropbox_uploader \
	scripts-sh/plugins/EPGscan \
	scripts-sh/plugins/imgbackup-hd51 \
	scripts-sh/plugins/mountpointmanagement \
	scripts-sh/plugins/pr-auto-timer \
	scripts-sh/plugins/smarthomeinfo

uninstall-hook:
	-rmdir $(DESTDIR)$(PLUGINDIR)