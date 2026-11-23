webtvdir = $(WEBTVDIR)

webtv_DATA =

if ENABLE_STREAMLINK
webtv_DATA += \
	streamlink-loader.py
if ENABLE_STREAMLINK_PLUTOTV
webtv_DATA += \
	plutotv_de.xml
endif
if ENABLE_STREAMLINK_SAMSUNGTVPLUS
webtv_DATA += \
	samsungtvplus_de.xml
endif
endif
