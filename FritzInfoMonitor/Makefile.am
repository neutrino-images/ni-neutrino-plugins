AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	@CURL_CFLAGS@ \
	-I$(top_srcdir)/include

noinst_PROGRAMS = FritzInfoMonitor

FritzInfoMonitor_SOURCES = \
	connect.cpp \
	framebuffer.cpp \
	FritzInfoMonitor.cpp \
	icons.cpp \
	parser.cpp \
	phonebook.cpp \
	rc.cpp \
	submenu.cpp

FritzInfoMonitor_LDADD = \
	@FREETYPE_LIBS@ \
	@CURL_LIBS@ \
	-lz \
	-lstdc++ \
	-lcrypto

install-exec-local:
	install -d $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(CONFIGDIR)
	install -m 0755 FritzInfoMonitor $(DESTDIR)$(PLUGINDIR)/FritzInfoMonitor.so
	install -m644 $(srcdir)/FritzInfoMonitor.cfg $(DESTDIR)$(PLUGINDIR)
	install -m644 $(srcdir)/FritzInfoMonitor_hint.png $(DESTDIR)$(PLUGINDIR)
	install -m755 $(srcdir)/FritzInfoMonitor_setup.lua $(DESTDIR)$(PLUGINDIR)
	install -m644 $(srcdir)/FritzInfoMonitor_setup.cfg $(DESTDIR)$(PLUGINDIR)
	install -m644 $(srcdir)/FritzInfoMonitor_setup_hint.png $(DESTDIR)$(PLUGINDIR)

