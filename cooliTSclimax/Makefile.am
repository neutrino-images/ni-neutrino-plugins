AM_CPPFLAGS =  \
	@FREETYPE_CFLAGS@ \
	-I$(top_srcdir)/include

AM_LDFLAGS = \
	-Wl,-unresolved-symbols=ignore-in-shared-libs

bin_PROGRAMS = cooliTSclimax

cooliTSclimax_SOURCES = \
	cooliTSclimax.cpp

cooliTSclimax_CXXFLAGS = \
	-D__STDC_CONSTANT_MACROS

cooliTSclimax_LDADD = \
	@FREETYPE_LIBS@ \
	-lavformat \
	-lavcodec \
	-lavutil \
	-lz \
	-lpthread
