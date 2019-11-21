ACLOCAL_AMFLAGS = \
	-I m4

bin_PROGRAMS = stbup

stbup_SOURCES = \
	stbup.c

sysconf_DATA = \
	stbup.conf

install-exec-local:
	install -D -m 0755 $(srcdir)/stbup.init $(DESTDIR)$(sysconfdir)/init.d/stbup

uninstall-hook:
	rm -f $(DESTDIR)$(sysconfdir)/init.d/stbup
