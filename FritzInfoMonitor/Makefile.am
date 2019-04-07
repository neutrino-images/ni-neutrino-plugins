AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	@CURL_CFLAGS@ \
	-I$(top_srcdir)/include

plugindir = $(PLUGINDIR)

plugin_PROGRAMS = FritzInfoMonitor.so

FritzInfoMonitor_so_SOURCES = \
	connect.cpp \
	framebuffer.cpp \
	FritzInfoMonitor.cpp \
	icons.cpp \
	parser.cpp \
	phonebook.cpp \
	rc.cpp \
	submenu.cpp

FritzInfoMonitor_so_LDADD = \
	@FREETYPE_LIBS@ \
	@CURL_LIBS@ \
	-lz \
	-lstdc++ \
	-lcrypto

plugin_DATA = \
	FritzInfoMonitor.cfg \
	FritzInfoMonitor_hint.png
