AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

noinst_PROGRAMS = tuxmail tuxmaild

tuxmail_SOURCES = tuxmail.c

tuxmail_LDADD = \
	@FREETYPE_LIBS@

tuxmaild_SOURCES = daemon/tuxmaild.c

tuxmaild_LDADD = \
	-lpthread \
	-lssl \
	-lcrypto \
	-lfreetype \
	-lz

install-exec-local:
	install -d $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(CONFIGDIR)
	install -d $(DESTDIR)$(CONFIGDIR)/tuxmail
	install -m 0755 tuxmail $(DESTDIR)$(PLUGINDIR)/tuxmail.so
	install -m 0755 tuxmaild $(DESTDIR)/bin/tuxmaild
	install -m 0755 $(srcdir)/daemon/tuxmaild $(DESTDIR)/etc/init.d/tuxmaild
	install -m 0644 $(srcdir)/tuxmail.cfg $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/tuxmail.conf $(DESTDIR)$(CONFIGDIR)/tuxmail
	install -m 0644 $(srcdir)/tuxmail_hint.png $(DESTDIR)$(PLUGINDIR)

