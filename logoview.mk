
## Diese beiden Pfade müssen u.U. angepasst werden!
BUILDSYSTEM = $(HOME)/coolstream/buildsystem-cs
LV_SOURCE = $(BUILDSYSTEM)/source/cs-tools/Tools/logoview

INCLUDES = -I.
INCLUDES += -I$(BUILDSYSTEM)/root/include
INCLUDES += -I$(BUILDSYSTEM)/source/neutrino-hd-beta/lib/libconfigfile
LIBS = -L$(BUILDSYSTEM)/root/lib -lstdc++ -ljpeg
LD_ADD = $(BUILDSYSTEM)/build_tmp/neutrino-hd/lib/libconfigfile/libtuxbox-configfile.a

STRIP = arm-cx2450x-linux-gnueabi-strip

ML_CFLAGS  = -Wall -W -Wshadow -fno-strict-aliasing
ML_CFLAGS += -DUSE_NEVIS_GXA

.cpp.o:
	$(TARGET)-gcc $(INCLUDES) $(LIBS) -MT $@ -MD -MP -c -o $@ $<

logoview: $(LV_SOURCE)/logoview.cpp $(LV_SOURCE)/logoview.h $(LV_SOURCE)/jpeg.o $(LV_SOURCE)/jpeg.cpp $(LV_SOURCE)/jpeg.h $(LD_ADD)
	cd $(LV_SOURCE) && \
		rm -f logoview *.o *.d && \
		$(TARGET)-gcc -W -Wall $(INCLUDES) $(ML_CFLAGS) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) $(LIBS) logoview.cpp jpeg.cpp -o logoview $(LD_ADD) && \
		$(STRIP) logoview
