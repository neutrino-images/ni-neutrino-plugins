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
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/statvfs.h>
#include <sys/stat.h>

#include "mmcblk_info.h"

int is_block_device(const char* path) {
	struct stat sb;

	if (stat(path, &sb) == -1) {
		perror("stat");
		return 0;
	}
	if ((sb.st_mode & S_IFMT) != S_IFBLK) {
		return 0;
	}
	return 1;
}

int compare_mmcblk_info(const void* a, const void* b) {
	mmcblk_info_t* aa = (mmcblk_info_t*)a;
	mmcblk_info_t* bb = (mmcblk_info_t*)b;
	return strcmp(aa->mountpoint, bb->mountpoint);
}

mmcblk_info_t* get_mmcblk_info(int* num_devices) {
	int count = 0;
	// Scan /dev directory for all entries
	DIR* dir = opendir("/dev");
	if (dir == NULL) {
		perror("opendir");
		return NULL;
	}
	// Count the number of MMCBLK devices
	struct dirent* entry;
	while ((entry = readdir(dir)) != NULL) {
		if (strstr(entry->d_name, "mmcblk") != NULL) {
			count++;
		}
	}
	closedir(dir);

	// Allocate memory for mmcblk_info_t structures
	mmcblk_info_t* mmcblk_info = malloc(count * sizeof(mmcblk_info_t));
	if (mmcblk_info == NULL) {
		perror("malloc");
		return NULL;
	}
	count = 0;

	// Go through all entries in /dev directory
	dir = opendir("/dev");
	if (dir == NULL) {
		perror("opendir");
		return NULL;
	}
	while ((entry = readdir(dir)) != NULL) {
		char device_path[262];
		sprintf(device_path, "/dev/%s", entry->d_name);

		// Check if this is an mmcblk device
		if (strstr(entry->d_name, "mmcblk") != NULL) {
			// Get device name
			strcpy(mmcblk_info[count].device, entry->d_name);

			// Get mountpoint and check if device is mounted
			char mountpoint[256];
			char device[128];
			FILE* mount_file = fopen("/proc/mounts", "r");
			if (mount_file == NULL) {
				perror("fopen");
				continue;
			}

			int is_mounted = 0;
			while (fscanf(mount_file, "%s %s %*s %*s %*d %*d\n", device, mountpoint) != EOF) {
				if (strcmp(device, device_path) == 0) {
					// Check if device is a block device
					if (is_block_device(device_path)) {
						is_mounted = 1;
						break;
					}
				}
			}
			fclose(mount_file);

			if (!is_mounted) {
				continue;
			}

			// Get total size and free size using statvfs
			struct statvfs stat;
			if (statvfs(mountpoint, &stat) != 0) {
				perror("statvfs");
				continue;
			}
			strcpy(mmcblk_info[count].device, entry->d_name);
			strcpy(mmcblk_info[count].mountpoint, mountpoint);
			mmcblk_info[count].total_size = (double) stat.f_frsize * stat.f_blocks / 1000000.0;
			mmcblk_info[count].free_size = (double) stat.f_frsize * stat.f_bfree / 1000000.0;
			mmcblk_info[count].usage_percent = (double)(stat.f_blocks - stat.f_bfree) * 100 / stat.f_blocks;
			count++;
		}
	}
	closedir(dir);
	*num_devices = count;
	return mmcblk_info;
}
