AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

noinst_PROGRAMS = tuxcal tuxcald

tuxcal_SOURCES = tuxcal.c

tuxcal_LDADD = \
	@FREETYPE_LIBS@ \
	-lz

tuxcald_SOURCES = daemon/tuxcald.c

tuxcald_LDADD = \
	@FREETYPE_LIBS@ \
	-lz \
	-lpthread

install-exec-local:
	install -d $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(CONFIGDIR)
	install -d $(DESTDIR)$(CONFIGDIR)/tuxcal
	install -m 0755 tuxcal $(DESTDIR)$(PLUGINDIR)/tuxcal.so
	install -m 0755 tuxcald $(DESTDIR)/bin/tuxcald
	install -m 0755 $(srcdir)/daemon/tuxcald $(DESTDIR)/etc/init.d/tuxcald
	install -m 0644 $(srcdir)/tuxcal.cfg $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/tuxcal_hint.png $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/tuxcal.conf $(DESTDIR)$(CONFIGDIR)/tuxcal
	install -m 0755 $(srcdir)/tuxcal.notify $(DESTDIR)$(CONFIGDIR)/tuxcal

