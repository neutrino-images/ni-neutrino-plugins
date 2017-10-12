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

struct input_event ev;
static unsigned short rccode=-1;
static int rc;

int InitRC(void)
{
	rc = open(RC_DEVICE, O_RDONLY | O_CLOEXEC);
	if(rc == -1) 
	{
		perror("getrc <open remote control>");
		exit(1);
	}
	fcntl(rc, F_SETFL, O_NONBLOCK);
	return 1;
}

int CloseRC(void)
{
	close(rc);
	return 1;
}

int RCKeyPressed(void)
{
	if(read(rc, &ev, sizeof(ev)) == sizeof(ev))
	{
		if(ev.code)
		{
			rccode=ev.code;
			return 1;
		}
	}
	rccode = -1;
	return 0;
}

int Translate(int code)
{
	int rv=-1;
	
	switch(code)
	{
		case KEY_0:
		case KEY_1:
		case KEY_2:
		case KEY_3:
		case KEY_4:
		case KEY_5:
		case KEY_6:
		case KEY_7:
		case KEY_8:
		case KEY_9:				rv = 0x29+code;
			break;

		case KEY_UP:			rv = 'C'; break;
		case KEY_DOWN:			rv = 'D'; break;
		case KEY_LEFT:			rv = 'B'; break;
		case KEY_RIGHT:			rv = 'A'; break;
		case KEY_OK:			rv = 'E'; break;
		case KEY_RED:			rv = 'J'; break;
		case KEY_GREEN:			rv = 'H'; break;
		case KEY_YELLOW:		rv = 'I'; break;
		case KEY_BLUE:			rv = 'K'; break;
		case KEY_VOLUMEUP:		rv = 'L'; break;
		case KEY_VOLUMEDOWN:	rv = 'M'; break;
		case KEY_MUTE:			rv = 'F'; break;
		case KEY_HELP:			rv = 'N'; break;
		case KEY_SETUP:			rv = 'O'; break;
		case KEY_HOME:			rv = 'P'; break;
		case KEY_POWER:			rv = 'G'; break;

		case KEY_PAGEUP:		rv = 'Q'; break;
		case KEY_PAGEDOWN:		rv = 'R'; break;
		case KEY_TVR:			rv = 'S'; break;
		case KEY_TTX:			rv = 'T'; break;
		case KEY_COOL:			rv = 'U'; break;
		case KEY_FAV:			rv = 'V'; break;
		case KEY_EPG:			rv = 'W'; break;
		case KEY_VF:			rv = 'Y'; break;
		case KEY_SAT:			rv = 'Z'; break;
		case KEY_SKIPP:			rv = 'a'; break;
		case KEY_SKIPM:			rv = 'b'; break;
		case KEY_TS:			rv = 'c'; break;
		case KEY_AUDIO:			rv = 'd'; break;
		case KEY_REW:			rv = 'e'; break;
		case KEY_FWD:			rv = 'f'; break;
		case KEY_HOLD:			rv = 'g'; break;
		case KEY_REC:			rv = 'h'; break;
		case KEY_STOP:			rv = 'i'; break;
		case KEY_PLAY:			rv = 'j'; break;

		default:			rccode = -1;
	}

	return rv;

}

int GetRCCode(char *key, int timeout)
{
int tmo=timeout;
	
	timeout>>=1;
	
	if(key)
	{
		while(Translate(rccode)!=(int)(*key))
		{
			RCKeyPressed();
			usleep(10000L);
			if(tmo &&((timeout-=10)<=0))
			{
				return 'X';
			}
		}
	}
	else
	{
		while(!RCKeyPressed())
		{
			usleep(10000L);
			if(tmo &&((timeout-=10)<=0))
			{
				return 'X';
			}
		}
	}
	return Translate(rccode);
}
