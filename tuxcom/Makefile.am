
AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

noinst_PROGRAMS = tuxcom

#tuxcom_la_CFLAGS = -DDREAMBOX 

tuxcom_SOURCES = tuxcom.c

tuxcom_LDADD = \
	 @FREETYPE_LIBS@
	 
install-exec-local:
	install -d $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(CONFIGDIR)
	install -d $(DESTDIR)$(CONFIGDIR)/tuxcom
	install -m 0755 tuxcom $(DESTDIR)$(PLUGINDIR)/tuxcom.so
	install -m 0644 $(srcdir)/tuxcom.cfg $(DESTDIR)$(PLUGINDIR)
