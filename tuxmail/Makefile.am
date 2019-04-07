SUBDIRS = daemon

AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

plugindir = $(PLUGINDIR)

plugin_PROGRAMS = tuxmail.so

tuxmail_so_SOURCES = \
	tuxmail.c

tuxmail_so_LDADD = \
	@FREETYPE_LIBS@

plugin_DATA = \
	tuxmail.cfg \
	tuxmail_hint.png

tuxmaildir = $(CONFIGDIR)/tuxmail

tuxmail_DATA = \
	tuxmail.conf

tuxmail_SCRIPTS = \
	tuxmail.onreadmail

uninstall-hook:
	-rmdir $(DESTDIR)$(tuxmaildir)
