ACLOCAL_AMFLAGS = \
	-I m4

bin_PROGRAMS = initfb

initfb_SOURCES = \
	initfb.c

# FIXME: Is there an or-condition?
if BOXMODEL_E4HDULTRA
install-exec-local:
	install -D -m 0755 $(srcdir)/initfb.init $(DESTDIR)$(sysconfdir)/init.d/initfb

uninstall-hook:
	rm -f $(DESTDIR)$(sysconfdir)/init.d/initfb
endif

if BOXMODEL_PROTEK4K
install-exec-local:
	install -D -m 0755 $(srcdir)/initfb.init $(DESTDIR)$(sysconfdir)/init.d/initfb

uninstall-hook:
	rm -f $(DESTDIR)$(sysconfdir)/init.d/initfb
endif
