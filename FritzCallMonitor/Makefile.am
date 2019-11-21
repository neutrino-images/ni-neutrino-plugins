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
	install -D -m 0755 $(srcdir)/fritzcallmonitor.init $(DESTDIR)$(sysconfdir)/init.d/fritzcallmonitor

uninstall-hook:
	rm -f $(DESTDIR)$(sysconfdir)/init.d/fritzcallmonitor
