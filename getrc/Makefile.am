AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

noinst_PROGRAMS = getrc

getrc_SOURCES = \
	getrc.c \
	io.c

getrc_LDADD = \
	@FREETYPE_LIBS@

install-exec-local:
	install -d $(DESTDIR)/bin
	install -m 0755 getrc $(DESTDIR)/bin/getrc
