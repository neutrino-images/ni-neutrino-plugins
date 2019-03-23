AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	@CURL_CFLAGS@ \
	-I$(top_srcdir)/include

FritzCallMonitor_LDADD = \
	@FREETYPE_LIBS@ \
	@CURL_LIBS@ \
	-lcrypto \
	-lssl

noinst_PROGRAMS = FritzCallMonitor

FritzCallMonitor_SOURCES = \
	connect.cpp \
	FritzCallMonitor.cpp

install-exec-local:
	install -d $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(CONFIGDIR)
	install -d $(DESTDIR)$(DATADIR)/neutrino/icons
	install -d $(DESTDIR)/etc/init.d
	install -m 0755 FritzCallMonitor $(DESTDIR)/bin/FritzCallMonitor
	install -m644 $(srcdir)/FritzCallMonitor.addr $(DESTDIR)$(CONFIGDIR)
	install -m644 $(srcdir)/FritzCallMonitor.cfg $(DESTDIR)$(CONFIGDIR)
	install -m644 $(srcdir)/hint_FritzCallMonitor.png $(DESTDIR)$(DATADIR)/neutrino/icons
	install -m755 $(srcdir)/fritzcallmonitor.init $(DESTDIR)/etc/init.d/fritzcallmonitor

