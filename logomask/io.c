#define _GNU_SOURCE
#include <stdio.h>
#include <errno.h>
#include <locale.h>
#include <fcntl.h>
#include <stdio.h>
#include <ctype.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <linux/fb.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/dir.h>
#include <sys/stat.h>
#include <linux/input.h>

#include "io.h"

#define RC_DEVICE	"/dev/input/nevis_ir"

extern int instance;
struct input_event ev;
static unsigned short rccode=-1;
static int rc;

int InitRC(void)
{
	rc = open(RC_DEVICE, O_RDONLY);
	if(rc == -1)
	{
		perror("msgbox <open remote control>");
		exit(1);
	}
	fcntl(rc, F_SETFL, O_NONBLOCK | O_SYNC);
	while(RCKeyPressed());
	return 1;
}

int CloseRC(void)
{
	while(RCKeyPressed());
	close(rc);
	return 1;
}

int RCKeyPressed(void)
{
	if(read(rc, &ev, sizeof(ev)) == sizeof(ev))
	{
		if(ev.value)
		{
			rccode=ev.code;
			return 1;
		}
	}
	rccode = -1;
	return 0;
}


int GetRCCode(void)
{
	int rv;
	
	if(!RCKeyPressed())
	{
		return -1;
	}
	rv=rccode;
//	while(RCKeyPressed());
	
	return rv;
}


