AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

bin_PROGRAMS = logomask

logomask_SOURCES = \
	logomask.c \
	gfx.c

bin_SCRIPTS = \
	logomask.sh

plugindir = $(PLUGINDIR)

plugin_PROGRAMS = logomask.so

logomask_so_SOURCES = \
	starter_logomask.c

plugin_DATA = \
	logomask.cfg \
	logomask_hint.png

plugin_PROGRAMS += logoset.so

logoset_so_SOURCES = \
	logoset.c \
	io.c \
	text.c\
	gfx.c

logoset_so_LDADD = \
	@FREETYPE_LIBS@ \
	-lz

plugin_DATA += \
	logoset.cfg \
	logoset_hint.png
