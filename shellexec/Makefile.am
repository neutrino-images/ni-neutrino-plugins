AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

plugindir = $(PLUGINDIR)

plugin_PROGRAMS = shellexec.so

shellexec_so_SOURCES = \
	shellexec.c \
	io.c \
	text.c \
	gfx.c \
	fb_display.c \
	resize.c \
	pngw.cpp \
	png_helper.cpp

shellexec_so_LDADD = \
	@FREETYPE_LIBS@ \
	@PNG_LIBS@

plugin_DATA = \
	shellexec.cfg \
	shellexec_hint.png

configdir = $(CONFIGDIR)

config_DATA = \
	shellexec.conf

flexdir = $(DESTDIR)/share/tuxbox/neutrino/flex

flex_DATA = \
	flex_plugins.conf \
	flex_user.conf

install-data-hook:
	set -e; cd $(DESTDIR)$(PLUGINDIR); \
		mv -f shellexec.so 00_shellexec.so; \
		mv -f shellexec.cfg 00_shellexec.cfg; \
		mv -f shellexec_hint.png 00_shellexec_hint.png
	ln -sf $(PLUGINDIR)/00_shellexec.so $(DESTDIR)/bin/shellexec
