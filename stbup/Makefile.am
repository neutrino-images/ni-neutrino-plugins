ACLOCAL_AMFLAGS = \
	-I m4

bin_PROGRAMS = stbup

stbup_SOURCES = \
	stbup.c

sysconf_DATA = \
	stbup.conf

install-exec-local:
	install -D -m 0755 $(srcdir)/stbup.init $(DESTDIR)$(sysconfdir)/init.d/stbup

install-exec-hook:
	set -e; cd $(DESTDIR)$(sysconfdir)/init.d; \
		ln -sf stbup S99stbup; \
		ln -sf stbup K01stbup

uninstall-hook:
	set -e; cd $(DESTDIR)$(sysconfdir)/init.d; \
		rm -f stbup; \
		rm -f S99stbup; \
		rm -f K01stbup
