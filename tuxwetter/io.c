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
#include <poll.h>

#include "io.h"
#include "tuxwetter.h"

extern int instance;
struct input_event ev;
static unsigned short rccode=-1;
static int rc;

int InitRC(void)
{
	rc = open(RC_DEVICE, O_RDONLY | O_CLOEXEC);
	if(rc == -1)
	{
		perror("tuxwetter <open remote control>");
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

void ClearRC(void)
{
	struct pollfd pfd;
	pfd.fd = rc;
	pfd.events = POLLIN;
	pfd.revents = 0;

	do
		poll(&pfd, 1, 300);
	while(read(rc, &ev, sizeof(ev)) == sizeof(ev));
}


int GetRCCode(int timeout_in_ms)
{
	int rv = -1;

	if (get_instance()>instance)
	{
		return rv;
	}

	if (timeout_in_ms) {
		struct pollfd pfd;
		struct timeval tv;
		uint64_t ms_now, ms_final;

		pfd.fd = rc;
		pfd.events = POLLIN;
		pfd.revents = 0;

		gettimeofday( &tv, NULL );
		ms_now = tv.tv_usec/1000 + tv.tv_sec * 1000;
		if (timeout_in_ms > 0)
			ms_final = ms_now + timeout_in_ms;
		else
			ms_final = UINT64_MAX;
		while (ms_final > ms_now) {
			switch(poll(&pfd, 1, timeout_in_ms)) {
				case -1:
					perror("GetRCCode: poll() failed");
				case 0:
					return -1;
				default:
					;
			}
			if(RCKeyPressed()) {
				rv = rccode;
				while(RCKeyPressed());
				return rv;
			}

			gettimeofday( &tv, NULL );
			ms_now = tv.tv_usec/1000 + tv.tv_sec * 1000;
			if (timeout_in_ms > 0)
				timeout_in_ms = (int)(ms_final - ms_now);
		}
	} else if(RCKeyPressed()) {
		rv = rccode;
		while(RCKeyPressed());
	}
	return rv;
}
