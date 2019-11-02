AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

bin_PROGRAMS = msgbox

msgbox_SOURCES = \
	msgbox.c \
	gfx.c \
	io.c \
	txtform.c \
	text.c \
	fb_display.c \
	rc_device.c \
	resize.c \
	pngw.cpp \
	png_helper.cpp

msgbox_LDADD = \
	@FREETYPE_LIBS@ \
	@PNG_LIBS@
