###
###  Makefile logoview - für Coolstream
###

## Diese beiden Pfade müssen u.U. angepasst werden!
CROSS_CDK = /opt/newcross/arm-cx2450x-linux-gnueabi
BUILDSYSTEM = $(HOME)/coolstream/buildsystem-cs

# includes
includedir1 = -I$(BUILDSYSTEM)/root/include
#includedir2 = -I$(CROSS_CDK)/arm-cx2450x-linux-gnueabi/include

# libraries und cdk
libdir1 = -L$(BUILDSYSTEM)/root/lib
#libdir2 = -L$(CROSS_CDK)/arm-cx2450x-linux-gnueabi/lib

# Pfad zum Cross-Compiler
CCPATH        = $(CROSS_CDK)/bin
HOST          = arm-cx2450x-linux-gnueabi
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

INCLUDES = $(includedir1) $(includedir2)
LIBS = $(libdir1) $(libdir2)
#LIBS += -L$(CROSS_CDK)/lib
LIBS += -lstdc++ -ljpeg

CFLAGS = $(INCLUDES) -Wall -W -Wshadow -Wl,-O1 -pipe -g -O2 -fno-strict-aliasing -DUSE_NEVIS_GXA
CPPFLAGS = 
CXXFLAGS = $(INCLUDES) -Wall -W -Wshadow -Wl,-O1 -g -O2 -fno-strict-aliasing -DUSE_NEVIS_GXA
LDFLAGS = $(LIBS)

.c.o:
	$(CC) $(CFLAGS) $(LDFLAGS) -MT $@ -MD -MP -c -o $@ $<

.cpp.o:
	$(CC) $(CFLAGS) $(LDFLAGS) -MT $@ -MD -MP -c -o $@ $<

all: clean logoview strip

logoview: logoview.cpp logoview.h jpeg.cpp jpeg.h jpeg.o
	$(CC) $(CFLAGS) $(LDFLAGS) logoview.cpp jpeg.cpp -o logoview

clean:
	rm -f *.o *.d
	rm -f logoview

strip:
	$(STRIP) logoview
