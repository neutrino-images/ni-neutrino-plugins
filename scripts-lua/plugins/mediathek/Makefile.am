plugindir = $(PLUGINDIR)

plugin_DATA = \
	neutrino-mediathek.cfg \
	neutrino-mediathek.lua \
	neutrino-mediathek_hint.png

plugin_neutrino_mediathekdir = $(PLUGINDIR)/neutrino-mediathek

plugin_neutrino_mediathek_DATA = \
	neutrino-mediathek/background.jpg \
	neutrino-mediathek/main.lua \
	neutrino-mediathek/mt_config.lua \
	neutrino-mediathek/mt_filters.lua \
	neutrino-mediathek/mt_functions.lua \
	neutrino-mediathek/mt_images.lua \
	neutrino-mediathek/mt_json_decode.lua \
	neutrino-mediathek/mt_leftMenu.lua \
	neutrino-mediathek/mt_livestream.lua \
	neutrino-mediathek/mt_mediathek.lua \
	neutrino-mediathek/mt_movieInfo.lua \
	neutrino-mediathek/mt_parse_m3u8.lua \
	neutrino-mediathek/mt_util.lua \
	neutrino-mediathek/mt_variables.lua \
	neutrino-mediathek/VERSION

plugin_neutrino_mediathek_localedir = $(PLUGINDIR)/neutrino-mediathek/locale

plugin_neutrino_mediathek_locale_DATA = \
	neutrino-mediathek/locale/deutsch.lua \
	neutrino-mediathek/locale/english.lua

uninstall-hook:
	-rmdir $(DESTDIR)$(PLUGINDIR)/neutrino-mediathek/locale
	-rmdir $(DESTDIR)$(PLUGINDIR)/neutrino-mediathek
