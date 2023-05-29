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
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/ioctl.h>
#include <linux/dvb/frontend.h>

#include "fe_infos.h"

int get_frontend_info(struct frontend_info *info_array, int max_num_frontends) {
	int fd;
	int num_frontends = 0;
	struct dvb_frontend_info fe_info;

	fd = open("/dev/dvb/adapter0/frontend0", O_RDONLY);
	if (fd < 0) {
		fprintf(stderr, "Error opening frontend: %s\n", strerror(errno));
		return -1;
	}

	while (num_frontends <= max_num_frontends && ioctl(fd, FE_GET_INFO, &fe_info) == 0)
	{
		struct frontend_info info;
		info.type = fe_info.type;
		//strcpy(info_array[num_frontends].name, fe_info.name);
		memset(info.name, '\0', sizeof(info.name));
		snprintf(info.name, sizeof(info.name), "%s", fe_info.name);
		if (ioctl(fd, FE_READ_SIGNAL_STRENGTH, &info.signal_strength) != 0) {
			info.signal_strength = 0;
		}
		if (ioctl(fd, FE_READ_SNR, &info.snr) != 0) {
			info.snr = 0;
		}
		info_array[num_frontends] = info;
		num_frontends++;
		close(fd);
		fd = open("/dev/dvb/adapter0/frontend" + num_frontends, O_RDONLY);
		if (fd < 0) {
			//printf("Error opening frontend %d: \n", num_frontends);
			break;
		}
	}

	close(fd);
	return num_frontends;
}
