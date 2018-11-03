AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

noinst_PROGRAMS = logomask logomasks logoset

logomask_SOURCES = \
	logomask.c \
	gfx.c

logomasks_SOURCES = \
	starter_logomask.c

logoset_SOURCES = \
	logoset.c \
	io.c \
	text.c\
	gfx.c

logoset_LDADD = \
	@FREETYPE_LIBS@ \
	-lz

install-exec-local:
	install -d $(DESTDIR)$(PLUGINDIR)
	install -d $(DESTDIR)$(CONFIGDIR)
	install -m 0755 logomask $(DESTDIR)/bin/logomask
	install -m 0755 logomasks $(DESTDIR)$(PLUGINDIR)/logomask.so
	install -m 0755 logoset $(DESTDIR)$(PLUGINDIR)/logoset.so
	install -m 0644 $(srcdir)/logomask.sh $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/logomask.cfg $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/logomask_hint.png $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/logoset.cfg $(DESTDIR)$(PLUGINDIR)
	install -m 0644 $(srcdir)/logoset_hint.png $(DESTDIR)$(PLUGINDIR)
