AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

bin_PROGRAMS = tuxcald

tuxcald_SOURCES = \
	tuxcald.c

tuxcald_LDADD = \
	@FREETYPE_LIBS@ \
	-lpthread \
	-lz

install-exec-local:
	install -D -m 0755 $(srcdir)/tuxcald.init $(DESTDIR)$(sysconfdir)/init.d/tuxcald

uninstall-hook:
	rm -f $(DESTDIR)$(sysconfdir)/init.d/tuxcald
