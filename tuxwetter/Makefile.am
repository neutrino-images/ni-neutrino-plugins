AM_CPPFLAGS = \
	-DWWEATHER \
	@FREETYPE_CFLAGS@ \
	@CURL_CFLAGS@ \
	@PNG_CFLAGS@ \
	-I$(top_srcdir)/include

plugindir = $(PLUGINDIR)

plugin_PROGRAMS = tuxwetter.so

tuxwetter_so_SOURCES = \
	tuxwetter.c \
	gfx.c \
	io.c \
	text.c \
	parser.c \
	php.c \
	http.c \
	jpeg.c \
	fb_display.c \
	resize.c \
	pngw.cpp \
	png_helper.cpp \
	gif.c \
	gifdecomp.c

tuxwetter_so_LDADD = \
	@FREETYPE_LIBS@ \
	@CURL_LIBS@ \
	@PNG_LIBS@ \
	-lcrypto \
	-lssl \
	-ljpeg \
	-lgif

plugin_DATA = \
	tuxwetter.cfg \
	tuxwetter_hint.png

tuxwetterdir = $(CONFIGDIR)/tuxwetter

tuxwetter_DATA = \
	convert.list \
	startbild.jpg \
	tuxwetter.conf \
	tuxwetter.mcfg \
	tuxwetter.png

install-data-hook:
	ln -sf $(PLUGINDIR)/tuxwetter.so $(DESTDIR)$(bindir)/tuxwetter

uninstall-hook:
	rm -f $(DESTDIR)$(bindir)/tuxwetter
	-rmdir $(DESTDIR)$(tuxwetterdir)
