/*
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

#ifndef __MTDDEVICE_INFO_H__
#define __MTDDEVICE_INFO_H__

#define MAX_MTD_DEVICES 12
#define BUFFER_SIZE 256
#define SYSFS_MTD_DEVICES_PATH "/sys/class/mtd/"

extern char mtds[MAX_MTD_DEVICES][BUFFER_SIZE];

typedef struct {
	char dev[12];
	char name[32];
	size_t total_size;
	size_t used_size;
	char total_size_str[16];
	char used_size_str[16];
	double used_percentage;
} MTDDeviceInfo;

int get_mtd(void);
int parse_df(const char *mtd_dev, long* size, long* used, double* percent);
int get_mtd_device_infos(MTDDeviceInfo *devices);

#endif