###
###  Makefile logoview - für CST nevis / apollo
###

CFLAGS   = $(CFLAGS_)
CPPFLAGS = 
CXXFLAGS =
LDFLAGS = $(LDFLAGS_) -lstdc++ -ljpeg

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

binfile: logoview
	mkdir -p bin
	cp -a logoview bin/logoview.$(PLATFORM)

