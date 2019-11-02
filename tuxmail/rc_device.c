#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "rc_device.h"

void get_rc_device(char *rc_device)
{
	char line[128];
	char event[10];
	FILE *f;

	rc_device[0] = '\0';

	if(access("/dev/input/nevis_ir", F_OK) == 0)
	{
		sprintf(rc_device, "%s", "/dev/input/nevis_ir");
		return;
	}

	if((f = fopen("/proc/bus/input/devices", "r")))
	{
		while (fgets(line, sizeof(line), f))
		{
			if (strstr(line, "advanced remote control"))
			{
				while (fgets(line, sizeof(line), f))
				{
					if (strstr(line, "Handlers=")) {
						sscanf(line, "%*s %*s %s", event);
						sprintf(rc_device, "%s%s", "/dev/input/", event);
						break;
					}							
				}
				break;
			}
		}
		fclose(f);
	}
	if(rc_device[0] == '\0')
		sprintf(rc_device, "%s", "/dev/input/event0");
}
