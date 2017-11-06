#ifndef __IO_H__
#define __IO_H__

#include <rc_device.h>

int InitRC(void);
int CloseRC(void);
int RCKeyPressed(void);
int GetRCCode(void);

#endif
