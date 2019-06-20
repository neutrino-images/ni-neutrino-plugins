SUBDIRS =

if ENABLE_COOLITSCLIMAX
SUBDIRS += cooliTSclimax
endif
if ENABLE_EMMRD
SUBDIRS += emmrd
endif
if ENABLE_FRITZCALLMONITOR
SUBDIRS += FritzCallMonitor
endif
if ENABLE_FRITZINFOMONITOR
SUBDIRS += FritzInfoMonitor
endif
if ENABLE_GETRC
SUBDIRS += getrc
endif
if ENABLE_INPUT
SUBDIRS += input
endif
if ENABLE_LOGOMASK
SUBDIRS += logomask
endif
if ENABLE_LOGOVIEW
SUBDIRS += logoview
endif
if ENABLE_OSCAMMON
SUBDIRS += oscammon
endif
if ENABLE_MSGBOX
SUBDIRS += msgbox
endif
if ENABLE_SATFIND
SUBDIRS += satfind
endif
if ENABLE_SHELLEXEC
SUBDIRS += shellexec
endif
if ENABLE_SHOWIFRAME
SUBDIRS += showiframe
endif
if ENABLE_STBUP
SUBDIRS += stbup
endif
if ENABLE_TUXCAL
SUBDIRS += tuxcal
endif
if ENABLE_TUXCOM
SUBDIRS += tuxcom
endif
if ENABLE_TUXMAIL
SUBDIRS += tuxmail
endif
if ENABLE_TUXWETTER
SUBDIRS += tuxwetter
endif
if ENABLE_VINFO
SUBDIRS += vinfo
endif
if BOXMODEL_VUSOLO4K
SUBDIRS += vu-initfb
SUBDIRS += vu-turnoff_power
endif
if BOXMODEL_VUDUO
SUBDIRS += vu-initfb
SUBDIRS += vu-turnoff_power
endif


SUBDIRS += \
	scripts-lua \
	scripts-sh

SUBDIRS += data

install-data-hook:
	$(INSTALL) -d $(DESTDIR)$(LUAPLUGINDIR)

uninstall-hook:
	-rmdir $(DESTDIR)$(GAMESDIR)
	-rmdir $(DESTDIR)$(PLUGINDIR)
	-rmdir $(DESTDIR)$(LUAPLUGINDIR)
