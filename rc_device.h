#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef HAVE_COOL_HARDWARE
#define RC_DEVICE "/dev/input/nevis_ir"
#define RC_DEVICE_FALLBACK "/dev/input/event0"
#endif

#ifdef HAVE_SPARK_HARDWARE
#define RC_DEVICE "/dev/input/nevis_ir"
#define RC_DEVICE_FALLBACK "/dev/input/event1"
#endif

#ifdef HAVE_DUCKBOX_HARDWARE
 #define RC_DEVICE "/dev/input/event0"
 #define RC_DEVICE_FALLBACK "/dev/input/event1"
#endif

#ifdef HAVE_ARM_HARDWARE
#if BOXMODEL_H7
#define RC_DEVICE "/dev/input/event2"
#define RC_DEVICE_FALLBACK "/dev/input/event0"
#else
#define RC_DEVICE "/dev/input/event1"
#define RC_DEVICE_FALLBACK "/dev/input/event0"
#endif
#endif

