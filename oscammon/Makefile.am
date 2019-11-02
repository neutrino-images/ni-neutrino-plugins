AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

plugindir = $(PLUGINDIR)

plugin_PROGRAMS = oscammon.so

oscammon_so_SOURCES = \
	oscammon.c \
	rc_device.c

oscammon_so_LDADD = \
	@FREETYPE_LIBS@ \
	-lcrypto \
	-lz

plugin_DATA = \
	oscammon.cfg \
	oscammon_hint.png

configdir = $(CONFIGDIR)

config_DATA = \
	oscammon.conf
