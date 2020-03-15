plugindir = $(PLUGINDIR)

plugin_DATA = \
	tierwelt_tv.cfg \
	tierwelt_tv.lua \
	tierwelt_tv_hint.png

# doesn't work; see below
#logodir = $(ICONSDIR)/logo

#logo_DATA = \
#	Tierwelt TV.png

# workaround to install channellogo with space in filename
install-exec-local:
	install -D -m 0755 $(srcdir)/"Tierwelt TV.png" $(DESTDIR)$(ICONSDIR)/logo/"Tierwelt TV.png"

uninstall-hook:
	rm -f $(DESTDIR)$(ICONSDIR)/logo/"Tierwelt TV.png"
