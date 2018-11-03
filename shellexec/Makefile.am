AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

noinst_PROGRAMS = shellexec

shellexec_SOURCES = \
	shellexec.c \
	io.c \
	text.c \
	gfx.c \
	fb_display.c \
	resize.c \
	pngw.cpp \
	png_helper.cpp

shellexec_LDADD = \
	@FREETYPE_LIBS@ \
	@PNG_LIBS@

install-exec-local:
	install -d $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(CONFIGDIR)
	install -d $(DESTDIR)/bin
	install -m 0755 shellexec $(DESTDIR)$(PLUGINDIR)/shellexec.so
	install -m 0644 $(srcdir)/shellexec.conf $(DESTDIR)$(CONFIGDIR)
	install -m 0644 $(srcdir)/shellexec.cfg $(DESTDIR)$(PLUGINDIR)
	ln -sf $(PLUGINDIR)/shellexec.so $(DESTDIR)/bin/shellexec
	install -m 0644 $(srcdir)/shellexec_hint.png $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(CONFIGDIR)/flexinc
	rm -f $(DESTDIR)$(CONFIGDIR)/flexinc/plugin_config.mnu
	touch $(DESTDIR)$(CONFIGDIR)/flexinc/plugin_config.mnu
