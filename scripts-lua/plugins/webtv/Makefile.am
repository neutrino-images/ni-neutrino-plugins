webtvdir = $(WEBTVDIR)

webtv_DATA = \
	best_bitrate_m3u8.lua

if ENABLE_FILMON
webtv_DATA += \
	filmon.lua \
	filmon.xml
endif
if ENABLE_PLUTOTV
webtv_DATA += \
	plutotv.lua \
	plutotv.xml
endif
if ENABLE_YT_LIVE
webtv_DATA += \
	yt_live.lua \
	yt_live.xml
endif
