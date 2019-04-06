AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

plugindir = $(PLUGINDIR)

plugin_PROGRAMS = tuxcom.so

tuxcom_so_SOURCES = \
	tuxcom.c

tuxcom_so_LDADD = \
	@FREETYPE_LIBS@

plugin_DATA = \
	tuxcom.cfg \
	tuxcom_hint.png

tuxcomdir = $(CONFIGDIR)/tuxcom

#tuxcom_DATA =

#tuxcom_SCRIPTS =

# creating empty tuxcomdir until we have no DATA or SCRIPTS to install
install-data-hook:
	install -d $(DESTDIR)$(tuxcomdir)
