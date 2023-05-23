AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

plugindir = $(PLUGINDIR)

plugin_PROGRAMS = sysinfo.so

sysinfo_so_SOURCES = \
	sysinfo.c \
	io.c \
	text.c \
	gfx.c \
	fb_display.c \
	rc_device.c \
	fe_infos.c \
	mmcblk_info.c \
	mtddevice_info.c \
	resize.c \
	pngw.cpp \
	png_helper.cpp

sysinfo_so_LDADD = \
	@FREETYPE_LIBS@ \
	@PNG_LIBS@

plugin_DATA = \
	sysinfo.cfg \
	sysinfo_hint.png
