AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

bin_PROGRAMS = shellexec

shellexec_LDADD = \
	@FREETYPE_LIBS@

shellexec_SOURCES = \
 shellexec.c \
 io.c \
 text.c \
 gfx.c \
 fb_display.c \
 resize.c \
 pngw.cpp \
 png_helper.cpp

noinst_LTLIBRARIES = shellexec.la

shellexec_la_LDFLAGS = -rpath $(PLUGINDIR) -module -avoid-version

shellexec_la_SOURCES = \
	starter.c

install-exec-local:
	install -d $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(CONFIGDIR)
	$(LIBTOOL) --mode=install install shellexec.la $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/shellexec.cfg $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/shellexec_hint.png $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/shellexec.conf $(DESTDIR)$(CONFIGDIR)
	install -d $(DESTDIR)$(CONFIGDIR)/flexinc
	rm -f $(DESTDIR)$(CONFIGDIR)/flexinc/plugin_config.mnu
	touch $(DESTDIR)$(CONFIGDIR)/flexinc/plugin_config.mnu

