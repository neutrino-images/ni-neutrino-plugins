#define _GNU_SOURCE
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif
#include <stdio.h>
#include <errno.h>
#include <locale.h>
#include <fcntl.h>
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
#include "rc_device.h"

extern int instance;
struct input_event ev;
static unsigned short rccode=-1;
static int rc;

int InitRC(void)
{
	char rc_device[32];
	get_rc_device(rc_device);
	printf("rc_device: using %s\n", rc_device);

	rc = open(rc_device, O_RDONLY | O_CLOEXEC);
	if(rc == -1)
	{
		perror("logomask <open remote control>");
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
#if HAVE_ARM_HARDWARE
		if(ev.value && ev.code)
#else
		if(ev.value)
#endif
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


