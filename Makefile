###
###  Makefile logoview - für CST nevis / apollo
###

# inside the well-known buildsystems logoview can be compiled with
# $(MAKE) logoview CROSS_CDK=$(CROSS_DIR) BUILDSYSTEM=$(BASE_DIR) N_HD_SOURCE=$(N_HD_SOURCE) TARGET=$(TARGET)
# in this case there's no need to edit the following variables

# Diese Variablen müssen u.U. angepasst werden!
BOXMODEL    ?= apollo
#BOXMODEL    ?= nevis
CROSS_CDK   ?= /opt/newcross/$(BOXMODEL)
N_HD_SOURCE ?= $(BUILDSYSTEM)/source/neutrino-hd

ifeq ($(BOXMODEL), nevis)
  BUILDSYSTEM ?= $(HOME)/coolstream/buildsystem-cs
  TARGET      ?= arm-cx2450x-linux-gnueabi
endif

ifeq ($(BOXMODEL), apollo)
  BUILDSYSTEM ?= $(HOME)/coolstream/bs-apollo
  TARGET      ?= arm-pnx8400-linux-uclibcgnueabi
endif

# includes
includedir1 = -I$(BUILDSYSTEM)/root/include
includedir3 = -I$(N_HD_SOURCE)/lib/libconfigfile

# libraries und cdk
libdir1 = -L$(BUILDSYSTEM)/root/lib
LD_ADD = $(BUILDSYSTEM)/build_tmp/neutrino-hd/lib/libconfigfile/libtuxbox-configfile.a

# Pfad zum Cross-Compiler
CCPATH        = $(CROSS_CDK)/bin
CROSS_COMPILE = $(CCPATH)/$(TARGET)

CC            = $(CROSS_COMPILE)-gcc
#CPP           = $(CROSS_COMPILE)-gcc -E
#CXX           = $(CROSS_COMPILE)-g++
#CXXCPP        = $(CROSS_COMPILE)-g++ -E
#LD            = $(CROSS_COMPILE)-ld
#LD            = $(CROSS_CDK)/$(TARGET)/bin/ld
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
	cp -a logoview bin/logoview.$(BOXMODEL)
