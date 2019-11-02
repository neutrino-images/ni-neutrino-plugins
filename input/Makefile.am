AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

bin_PROGRAMS = input

input_SOURCES = \
	input.c \
	inputd.c \
	io.c \
	text.c \
	gfx.c \
	fb_display.c \
	rc_device.c \
	resize.c \
	pngw.cpp \
	png_helper.cpp

input_LDADD = \
	@FREETYPE_LIBS@ \
	@PNG_LIBS@
