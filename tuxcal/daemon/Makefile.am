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
	install -D -m 0755 $(srcdir)/tuxcald.init $(DESTDIR)/etc/init.d/tuxcald

install-exec-hook:
	set -e; cd $(DESTDIR)/etc/init.d; \
		ln -sf tuxcald S99tuxcald; \
		ln -sf tuxcald K01tuxcald
