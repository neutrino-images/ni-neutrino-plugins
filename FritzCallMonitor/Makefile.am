AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	@CURL_CFLAGS@ \
	-I$(top_srcdir)/include

bin_PROGRAMS = FritzCallMonitor

FritzCallMonitor_SOURCES = \
	connect.cpp \
	FritzCallMonitor.cpp

FritzCallMonitor_LDADD = \
	@FREETYPE_LIBS@ \
	@CURL_LIBS@ \
	-lcrypto \
	-lssl

configdir = $(CONFIGDIR)

config_DATA = \
	FritzCallMonitor.addr \
	FritzCallMonitor.cfg

iconsdir = $(ICONSDIR)

icons_DATA = \
	hint_FritzCallMonitor.png

install-exec-local:
	install -D -m 0755 $(srcdir)/fritzcallmonitor.init $(DESTDIR)/etc/init.d/fritzcallmonitor

install-exec-hook:
	set -e; cd $(DESTDIR)/etc/init.d; \
		ln -sf fritzcallmonitor S99fritzcallmonitor; \
		ln -sf fritzcallmonitor K01fritzcallmonitor
