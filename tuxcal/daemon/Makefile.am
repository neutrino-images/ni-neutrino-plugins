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

install-exec-hook:
	set -e; cd $(DESTDIR)$(sysconfdir)/init.d; \
		ln -sf tuxcald S99tuxcald; \
		ln -sf tuxcald K01tuxcald

uninstall-hook:
	set -e; cd $(DESTDIR)$(sysconfdir)/init.d; \
		rm -f tuxcald; \
		rm -f S99tuxcald; \
		rm -f K01tuxcald
