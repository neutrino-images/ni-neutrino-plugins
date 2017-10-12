#include <config.h>

#if HAVE_COOL_HARDWARE
#define RC_DEVICE "/dev/input/nevis_ir"

#elif HAVE_DUCKBOX_HARDWARE
#define RC_DEVICE "/dev/input/event0"

#else
#define RC_DEVICE "/dev/input/event1"

#endif
