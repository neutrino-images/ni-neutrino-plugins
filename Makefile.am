AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	@PNG_CFLAGS@ \
	-I$(top_srcdir)/include

bin_PROGRAMS = sysinfo

sysinfo_SOURCES = \
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

sysinfo_LDADD = \
	@FREETYPE_LIBS@ \
	@PNG_LIBS@

install-exec-local:
	install -d $(DESTDIR)/usr/bin
	install -m 0755 input $(DESTDIR)/usr/bin/sysinfo
