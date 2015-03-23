###
###  Makefile logoview - für CST nevis / apollo
###

#PLATFORM ?= apollo
PLATFORM ?= kronos
#PLATFORM ?= nevis

## Diese Pfade müssen u.U. angepasst werden!
CROSS_CDK   ?= /opt/newcross/$(PLATFORM)
N_HD_SOURCE ?= $(BUILDSYSTEM)/source/neutrino-hd
ifeq ($(PLATFORM), nevis)
BUILDSYSTEM ?= $(HOME)/coolstream/buildsystem-cs
HOST         = arm-cx2450x-linux-gnueabi
endif

ifeq ($(PLATFORM), apollo)
BUILDSYSTEM ?= $(HOME)/coolstream/bs-apollo
#HOST         = arm-pnx8400-linux-uclibcgnueabi
HOST         = arm-cortex-linux-uclibcgnueabi
#HOST         = arm-cortex-linux-gnueabi
endif

ifeq ($(PLATFORM), kronos)
BUILDSYSTEM ?= $(HOME)/coolstream/bs-apollo
HOST         = arm-cortex-linux-uclibcgnueabi
#HOST         = arm-cortex-linux-gnueabi

endif

# includes
includedir1 = -I$(BUILDSYSTEM)/root/include
includedir2 = -I$(BUILDSYSTEM)/root/usr/include
includedir3 = -I$(N_HD_SOURCE)/lib/libconfigfile

# libraries und cdk
libdir1 = -L$(BUILDSYSTEM)/root/lib -L$(BUILDSYSTEM)/root/usr/lib
LD_ADD = $(BUILDSYSTEM)/build_tmp/neutrino-hd/lib/libconfigfile/libtuxbox-configfile.a

# Pfad zum Cross-Compiler
CCPATH        = $(CROSS_CDK)/bin
CROSS_COMPILE = $(CCPATH)/$(HOST)

CC            = $(CROSS_COMPILE)-gcc
#CPP           = $(CROSS_COMPILE)-gcc -E
#CXX           = $(CROSS_COMPILE)-g++
#CXXCPP        = $(CROSS_COMPILE)-g++ -E
#LD            = $(CROSS_COMPILE)-ld
#LD            = $(CROSS_CDK)/$(HOST)/bin/ld
#AR            = $(CROSS_COMPILE)-ar
#NM            = $(CROSS_COMPILE)-nm
#RANLIB        = $(CROSS_COMPILE)-ranlib
#OBJDUMP       = $(CROSS_COMPILE)-objdump
STRIP         = $(CROSS_COMPILE)-strip

INCLUDES = $(includedir1) $(includedir2) $(includedir3)
LIBS = $(libdir1) $(libdir2)
#LIBS += -L$(CROSS_CDK)/lib
LIBS += -lstdc++ -ljpeg

#ACCEL = -DUSE_NEVIS_GXA

CFLAGS = $(INCLUDES) -Wall -W -Wshadow -Wl,-O1 -pipe -g -ggdb3 -fno-strict-aliasing $(ACCEL)
CPPFLAGS = 
CXXFLAGS = $(INCLUDES) -Wall -W -Wshadow -Wl,-O1 -g -ggdb3 -fno-strict-aliasing $(ACCEL)
LDFLAGS = $(LIBS)

.c.o:
	$(CC) $(CFLAGS) $(LDFLAGS) -MT $@ -MD -MP -c -o $@ $<

.cpp.o:
	$(CC) $(CFLAGS) $(LDFLAGS) -MT $@ -MD -MP -c -o $@ $<

all: clean logoview strip

logoview: logoview.cpp logoview.h jpeg.cpp jpeg.h jpeg.o $(LD_ADD)
	$(CC) $(CFLAGS) $(LDFLAGS) logoview.cpp jpeg.cpp -o logoview $(LD_ADD)

clean:
	rm -f *.o *.d
	rm -f logoview

strip:
	$(STRIP) logoview

binfile: all
	mkdir -p bin
	cp -a logoview bin/logoview.$(PLATFORM)
