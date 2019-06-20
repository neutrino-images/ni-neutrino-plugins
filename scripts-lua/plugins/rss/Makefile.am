plugindir = $(PLUGINDIR)

plugin_DATA = \
	rss.cfg \
	rss.lua \
	rss_hint.png

rss_addondir = $(PLUGINDIR)/rss_addon

rss_addon_DATA = \
	rss_addon/3sat.lua \
	rss_addon/ard.lua \
	rss_addon/arte.lua \
	rss_addon/chip.lua \
	rss_addon/ComputerBase.lua \
	rss_addon/golem.lua \
	rss_addon/heise.lua \
	rss_addon/instagram.lua \
	rss_addon/kingofsat.lua \
	rss_addon/liveleak.lua \
	rss_addon/pitchfork.lua \
	rss_addon/postillon.lua \
	rss_addon/tagesschau.lua \
	rss_addon/twitter.lua \
	rss_addon/vimeo.lua \
	rss_addon/winfuture.lua \
	rss_addon/yt.lua \
	rss_addon/yt_video_url.lua \
	rss_addon/zdf.lua

uninstall-hook:
	-rmdir $(DESTDIR)$(PLUGINDIR)/rss_addon
