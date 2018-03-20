#include <config.h>

#if HAVE_COOL_HARDWARE
#define RC_DEVICE "/dev/input/nevis_ir"
#define RC_DEVICE_FALLBACK "/dev/input/event0"

#else
#define RC_DEVICE "/dev/input/event1"
#define RC_DEVICE_FALLBACK "/dev/input/event0"

#endif
