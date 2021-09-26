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
	rc_device.c \
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

EXTRA_DIST = \
	shellexec.conf shellexec.conf.in

config_DATA = \
	shellexec.conf

flexdir = $(DATADIR)/neutrino/flex

flex_DATA = \
	flex_plugins.conf

varflexdir = $(DATADIR_VAR)/flex

varflex_DATA = \
	flex_usr.conf

install-data-hook:
	set -e; cd $(DESTDIR)$(PLUGINDIR); \
		mv -f shellexec.so 00_shellexec.so; \
		mv -f shellexec.cfg 00_shellexec.cfg; \
		mv -f shellexec_hint.png 00_shellexec_hint.png
	ln -sf $(PLUGINDIR)/00_shellexec.so $(DESTDIR)$(bindir)/shellexec

uninstall-hook:
	set -e; cd $(DESTDIR)$(PLUGINDIR); \
		rm -f 00_shellexec.so; \
		rm -f 00_shellexec.cfg; \
		rm -f 00_shellexec_hint.png
	rm -f $(DESTDIR)$(bindir)/shellexec
	-rmdir $(DESTDIR)$(flexdir)
