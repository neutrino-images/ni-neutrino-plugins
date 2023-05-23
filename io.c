/*
 * sysinfo
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
*/
#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/input.h>
#include "current.h"
#include "io.h"
#include "sysinfo.h"
#include "rc_device.h"

struct input_event ev;
unsigned short rccode=-1;
int rc;

int InitRC(void)
{
	char rc_device[32];
	get_rc_device(rc_device);
	printf("rc_device: using %s\n", rc_device);

	rc = open(rc_device, O_RDONLY | O_CLOEXEC);
	if(rc == -1)
	{
		perror(__plugin__ " <open remote control failed>");
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

int GetRCCode()
{
#define REPEAT_TIMER 3
	static int count = 0;
	static __u16 rc_last_key = KEY_RESERVED;
	//get code

	if (read(rc, &ev, sizeof(ev)) == sizeof(ev))
	{
		if(ev.value > 0 && ev.code != rc_last_key)
		{
			if (ev.value == 2)
			{
				while (count < REPEAT_TIMER)
				{
					count++;
					rccode = -1;
					usleep(15000L);
					return rccode;
				}
			}
			else
				count = 0;

			rc_last_key = ev.code;
			switch (ev.code)
			{
				case KEY_UP:			rccode = RC_UP;		break;
				case KEY_DOWN:			rccode = RC_DOWN;	break;
				case KEY_LEFT:			rccode = RC_LEFT;	break;
				case KEY_RIGHT:			rccode = RC_RIGHT;	break;
				case KEY_OK:			rccode = RC_OK;		break;
				case KEY_0:				rccode = RC_0;		break;
				case KEY_1:				rccode = RC_1;		break;
				case KEY_2:				rccode = RC_2;		break;
				case KEY_3:				rccode = RC_3;		break;
				case KEY_4:				rccode = RC_4;		break;
				case KEY_5:				rccode = RC_5;		break;
				case KEY_6:				rccode = RC_6;		break;
				case KEY_7:				rccode = RC_7;		break;
				case KEY_8:				rccode = RC_8;		break;
				case KEY_9:				rccode = RC_9;		break;
				case KEY_RED:			rccode = RC_RED;	break;
				case KEY_GREEN:			rccode = RC_GREEN;	break;
				case KEY_YELLOW:		rccode = RC_YELLOW;	break;
				case KEY_BLUE:			rccode = RC_BLUE;	break;
				case KEY_VOLUMEUP:		rccode = RC_PLUS;	break;
				case KEY_VOLUMEDOWN:	rccode = RC_MINUS;	break;
				case KEY_MUTE:			rccode = RC_MUTE;	break;
				case KEY_HELP:			rccode = RC_HELP;	break;
				case KEY_INFO:			rccode = RC_HELP;	break;
				case KEY_SETUP:			rccode = RC_DBOX;	break;
				case KEY_MENU:			rccode = RC_DBOX;	break;
				case KEY_EXIT:			rccode = RC_HOME;	break;
				case KEY_POWER:			rccode = RC_STANDBY;break;
				default:				rccode = -1;
			}
			return rccode;
		}
		else
		{
			rccode = -1;
			rc_last_key = KEY_RESERVED;
		}
	}
	return -1;
}

