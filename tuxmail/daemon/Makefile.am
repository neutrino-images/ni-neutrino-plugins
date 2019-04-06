AM_CPPFLAGS = \
	-I$(top_srcdir)/include

bin_PROGRAMS = tuxmaild

tuxmaild_SOURCES = \
	tuxmaild.c

tuxmaild_LDADD = \
	-lpthread \
	-lcrypto \
	-lssl \
	-lz

install-exec-local:
	install -D -m 0755 $(srcdir)/tuxmaild.init $(DESTDIR)/etc/init.d/tuxmaild

install-exec-hook:
	set -e; cd $(DESTDIR)/etc/init.d; \
		ln -sf tuxmaild S99tuxmaild; \
		ln -sf tuxmaild K01tuxmaild
