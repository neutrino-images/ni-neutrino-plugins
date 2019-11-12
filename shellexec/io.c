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
#include <stdint.h>

#include "current.h"
#include "io.h"
#include <rc_device.h>

extern int instance;
struct input_event ev;
static unsigned short rccode=-1;
static int rc;

int InitRC(void)
{
	char rc_device[32];
	get_rc_device(rc_device);
	//printf("rc_device: using %s\n", rc_device);

	rc = open(rc_device, O_RDONLY | O_CLOEXEC);
	if(rc == -1)
	{
		perror(__plugin__ " <open remote control>");
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


int RCTranslate(int code)
{
	switch(code)
	{
		case KEY_UP:		rccode = RC_UP;
			break;

		case KEY_DOWN:		rccode = RC_DOWN;
			break;

		case KEY_PAGEUP:	rccode = RC_PAGEUP;
			break;

		case KEY_PAGEDOWN:	rccode = RC_PAGEDOWN;
			break;

		case KEY_OK:		rccode = RC_OK;
			break;

		case KEY_0:		rccode = RC_0;
			break;

		case KEY_1:		rccode = RC_1;
			break;

		case KEY_2:		rccode = RC_2;
			break;

		case KEY_3:		rccode = RC_3;
			break;

		case KEY_4:		rccode = RC_4;
			break;

		case KEY_5:		rccode = RC_5;
			break;

		case KEY_6:		rccode = RC_6;
			break;

		case KEY_7:		rccode = RC_7;
			break;

		case KEY_8:		rccode = RC_8;
			break;

		case KEY_9:		rccode = RC_9;
			break;

		case KEY_RED:		rccode = RC_RED;
			break;

		case KEY_GREEN:		rccode = RC_GREEN;
			break;

		case KEY_YELLOW:	rccode = RC_YELLOW;
			break;

		case KEY_BLUE:		rccode = RC_BLUE;
			break;

		case KEY_VOLUMEUP:	rccode = RC_PLUS;
			break;

		case KEY_VOLUMEDOWN:	rccode = RC_MINUS;
			break;

		case KEY_MUTE:		rccode = RC_MUTE;
			break;

		case KEY_HELP:		rccode = RC_HELP;
			break;

		case KEY_SETUP:		rccode = RC_DBOX;
			break;

		case KEY_EXIT:		rccode = RC_HOME;
			break;

		case KEY_POWER:		rccode = RC_STANDBY;
			break;

		default:		rccode = -1;
	}

	return rccode;

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
				return RCTranslate(rv);
			}

			gettimeofday( &tv, NULL );
			ms_now = tv.tv_usec/1000 + tv.tv_sec * 1000;
			if (timeout_in_ms > 0)
				timeout_in_ms = (int)(ms_final - ms_now);
		}
	} else if(RCKeyPressed()) {
		rv = rccode;
		while(RCKeyPressed());
		return RCTranslate(rv);
	}
	return rv;
}
