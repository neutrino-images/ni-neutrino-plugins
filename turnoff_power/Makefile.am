ACLOCAL_AMFLAGS = \
	-I m4

bin_PROGRAMS = turnoff_power

turnoff_power_SOURCES = \
	turnoff_power.c

install-exec-local:
	install -D -m 0755 $(srcdir)/turnoff_power.init $(DESTDIR)$(sysconfdir)/init.d/turnoff_power
	sed -i "s|turnoff_power|$(bindir)/turnoff_power|g" $(DESTDIR)$(sysconfdir)/init.d/turnoff_power

uninstall-hook:
	rm -f $(DESTDIR)$(sysconfdir)/init.d/turnoff_power
