#include <config.h>

#if HAVE_COOL_HARDWARE
#ifndef RC_DEVICE
#define RC_DEVICE "/dev/input/nevis_ir"
#endif
#ifndef RC_DEVICE_FALLBACK
#define RC_DEVICE_FALLBACK "/dev/input/event0"
#endif

#else
#ifndef RC_DEVICE
#define RC_DEVICE "/dev/input/event1"
#endif
#ifndef RC_DEVICE_FALLBACK
#define RC_DEVICE_FALLBACK "/dev/input/event0"
#endif

#endif
