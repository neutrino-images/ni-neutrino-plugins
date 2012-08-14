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
#include "shellexec.h"
#include "io.h"

extern int instance;
struct input_event ev;
static unsigned short rccode=-1;
static int rc;

int InitRC(void)
{
	rc = open(RC_DEVICE, O_RDONLY);
	if(rc == -1)
	{
		perror("shellexec <open remote control>");
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

		case KEY_0:			rccode = RC_0;
			break;

		case KEY_1:			rccode = RC_1;
			break;

		case KEY_2:			rccode = RC_2;
			break;

		case KEY_3:			rccode = RC_3;
			break;

		case KEY_4:			rccode = RC_4;
			break;

		case KEY_5:			rccode = RC_5;
			break;

		case KEY_6:			rccode = RC_6;
			break;

		case KEY_7:			rccode = RC_7;
			break;

		case KEY_8:			rccode = RC_8;
			break;

		case KEY_9:			rccode = RC_9;
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

		default:			rccode = -1;
	}

	return rccode;

}

int GetRCCode(void)
{
	int rv;

	if(!RCKeyPressed() || (get_instance()>instance))
	{
		return -1;
	}
	rv=rccode;
	while(RCKeyPressed());

	return RCTranslate(rv);
}


