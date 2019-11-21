AM_CPPFLAGS = \
	-I$(top_srcdir)/include

bin_PROGRAMS = tuxmaild

tuxmaild_SOURCES = \
	tuxmaild.c

tuxmaild_LDADD = \
	-lpthread \
	-lcrypto \
	-lssl \
	-lz

install-exec-local:
	install -D -m 0755 $(srcdir)/tuxmaild.init $(DESTDIR)$(sysconfdir)/init.d/tuxmaild

uninstall-hook:
	rm -f $(DESTDIR)$(sysconfdir)/init.d/tuxmaild
