
## Diese beiden Pfade müssen u.U. angepasst werden!
BUILDSYSTEM = $(HOME)/coolstream/buildsystem-cs
LW_SOURCE = $(BUILDSYSTEM)/source/cs-tools/Tools/logoview

INCLUDES = -I.
INCLUDES += -I$(BUILDSYSTEM)/root/include
LIBS = -L$(BUILDSYSTEM)/root/lib -lstdc++ -ljpeg

STRIP = arm-cx2450x-linux-gnueabi-strip

ML_CFLAGS  = -Wall -W -Wshadow -fno-strict-aliasing
ML_CFLAGS += -DUSE_NEVIS_GXA

.cpp.o:
	$(TARGET)-gcc $(INCLUDES) $(LIBS) -MT $@ -MD -MP -c -o $@ $<

logoview: $(LW_SOURCE)/logoview.cpp $(LW_SOURCE)/logoview.h $(LW_SOURCE)/jpeg.o $(LW_SOURCE)/jpeg.cpp $(LW_SOURCE)/jpeg.h
	cd $(LW_SOURCE) && \
		rm -f logoview *.o *.d && \
		$(TARGET)-gcc -W -Wall $(INCLUDES) $(ML_CFLAGS) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) $(LIBS) logoview.cpp jpeg.cpp -o logoview && \
		$(STRIP) logoview
