plugindir = $(PLUGINDIR)

plugin_DATA = \
	neutrino-mediathek.cfg \
	neutrino-mediathek.lua \
	neutrino-mediathek_hint.png

plugin_neutrino_mediathekdir = $(PLUGINDIR)/neutrino-mediathek

plugin_neutrino_mediathek_DATA = \
	neutrino-mediathek/background.jpg \
	neutrino-mediathek/config.lua \
	neutrino-mediathek/functions.lua \
	neutrino-mediathek/images.lua \
	neutrino-mediathek/json_decode.lua \
	neutrino-mediathek/livestream.lua \
	neutrino-mediathek/main.lua \
	neutrino-mediathek/mediathek.lua \
	neutrino-mediathek/mediathek_leftMenu.lua \
	neutrino-mediathek/mediathek_movieInfo.lua \
	neutrino-mediathek/parse_m3u8.lua \
	neutrino-mediathek/variables.lua

plugin_neutrino_mediathek_localedir = $(PLUGINDIR)/neutrino-mediathek/locale

plugin_neutrino_mediathek_locale_DATA = \
	neutrino-mediathek/locale/deutsch.lua \
	neutrino-mediathek/locale/english.lua

uninstall-hook:
	-rmdir $(DESTDIR)$(PLUGINDIR)/neutrino-mediathek/locale
	-rmdir $(DESTDIR)$(PLUGINDIR)/neutrino-mediathek
