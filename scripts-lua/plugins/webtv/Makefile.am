webtvdir = $(WEBTVDIR)

webtv_DATA = \
	best_bitrate_m3u8.lua \
	streamlink.lua

if ENABLE_FILMON
webtv_DATA += \
	filmon.lua \
	filmon.xml
endif
if ENABLE_PLUTOTV
webtv_DATA += \
	plutotv.lua \
	plutotv.xml \
	plutotv_us.lua \
	plutotv_us.xml
if HAVE_PYTHON
webtv_DATA += \
	plutotv_de.xml
endif
endif
if ENABLE_RAKUTENTV
webtv_DATA += \
	rakutentv.xml
endif
if ENABLE_SAMSUNGTVPLUS
if HAVE_PYTHON
webtv_DATA += \
	samsungtvplus_de.xml
endif
endif
if ENABLE_YT_LIVE
webtv_DATA += \
	yt_live.lua \
	yt_live.xml
endif
