AM_CPPFLAGS = \
	@FREETYPE_CFLAGS@ \
	-I$(NEUTRINO_SOURCE) \
	-I$(top_srcdir)/include

bin_PROGRAMS = logoview

logoview_SOURCES = \
	logoview.cpp \
	jpeg.cpp

logoview_LDADD = \
	-lstdc++ \
	-ljpeg

# linked with libtuxbox-configfile.a from neutrino build
logoview_LDADD += \
	$(NEUTRINO_BUILD)/lib/libconfigfile/libtuxbox-configfile.a
