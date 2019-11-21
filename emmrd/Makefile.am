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

uninstall-hook:
	rm -f $(DESTDIR)$(sysconfdir)/init.d/emmrd
