ACLOCAL_AMFLAGS = \
	-I m4

bin_PROGRAMS = emmrd

emmrd_SOURCES = \
	emmrd.cpp

iconsdir = $(ICONSDIR)

icons_DATA = \
	hint_emmrd.png

install-exec-local:
	install -D -m 0755 $(srcdir)/emmrd.init $(DESTDIR)$(sysconfdir)/init.d/emmrd

install-exec-hook:
	set -e; cd $(DESTDIR)$(sysconfdir)/init.d; \
		ln -sf emmrd S99emmrd; \
		ln -sf emmrd K01emmrd

uninstall-hook:
	set -e; cd $(DESTDIR)$(sysconfdir)/init.d; \
		rm -f emmrd; \
		rm -f S99emmrd; \
		rm -f K01emmrd
