SUBDIRS = daemon

AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

plugindir = $(PLUGINDIR)

plugin_PROGRAMS = tuxcal.so

tuxcal_so_SOURCES = \
	tuxcal.c

tuxcal_so_LDADD = \
	@FREETYPE_LIBS@ \
	-lz

plugin_DATA = \
	tuxcal.cfg \
	tuxcal_hint.png

tuxcaldir = $(CONFIGDIR)/tuxcal

tuxcal_DATA = \
	tuxcal.conf

tuxcal_SCRIPTS = \
	tuxcal.notify
