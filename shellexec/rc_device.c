#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "rc_device.h"

#include <sys/stat.h>
#include <fcntl.h>
#include <rc_device_hardcoded.h>

void get_rc_device(char *rc_device)
{
#if 0
	char line[128];
	int event;
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
					if (strstr(line, "Handlers=") && strstr(line, "event"))
					{
						sscanf(line, "%*sevent%d", &event);
						//printf("using: event%d\n", event);
						sprintf(rc_device, "%s%d", "/dev/input/event", event);
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
#else
	rc_device[0] = '\0';

	int rc = open(RC_DEVICE, O_RDONLY);
	if (rc != -1)
		sprintf(rc_device, "%s", RC_DEVICE);
	else
	{
		rc = open(RC_DEVICE_FALLBACK, O_RDONLY);
		if (rc != -1)
			sprintf(rc_device, "%s", RC_DEVICE_FALLBACK);
	}
	close(rc);

	if (rc_device[0] == '\0')
		sprintf(rc_device, "%s", "/dev/input/event0");
#endif
}
