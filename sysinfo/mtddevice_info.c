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
#include <string.h>

#include "mtddevice_info.h"

char mtds[MAX_MTD_DEVICES][BUFFER_SIZE];

extern int correct_string();

int get_mtd(void)
{
	FILE *file = NULL;
	int mtd_count = 0;
	memset(mtds, 0, sizeof(mtds));

	if ((file = fopen("/proc/mtd", "r")) == NULL)
	{
		printf("cannot open /proc/mtd\n");
		return -1;
	}

	while (mtd_count < MAX_MTD_DEVICES && fgets(mtds[mtd_count], BUFFER_SIZE, file))
	{
		if (strstr(mtds[mtd_count], "mtd") != NULL)
		{
			correct_string(mtds[mtd_count]);
			mtd_count++;
		}
	}
	fclose(file);
	return mtd_count;
}

int parse_df(const char *mtd_dev, long* size, long* used, double* percent) {
	char line[512];
	int ret = -1;
	*size = 0;
	*used = 0;

	FILE *fp = popen("df -k", "r");
	if (fp == NULL) {
		perror("error command df -k");
		return -1;
	}

	while (fgets(line, sizeof(line), fp)) {
		if (strstr(line, mtd_dev) != NULL) {
			long k_size, k_used;
			if (sscanf(line, "%*s %ld %ld %*d %lf%%", &k_size, &k_used, percent) == 3) {
				*size = k_size * 1024;
				*used = k_used * 1024; // Umrechnung von Kilobyte in Byte
				ret = 0;
				break;
			} else {
				fprintf(stderr, "error parsing df: %s", line);
			}
		}
	}
	pclose(fp);
	return ret;
}

int get_mtd_device_infos(MTDDeviceInfo *devices) {
	long df_size, df_used;
	double df_percent;
	int num_mtd_devices = 0, i;
	char dev[16] = "";
	char name[32] = "";
	char mtd_device_path[64] = "";

	for (i = 0; i < MAX_MTD_DEVICES; i++) {
		snprintf(mtd_device_path, sizeof(mtd_device_path), "%s/mtd%d", SYSFS_MTD_DEVICES_PATH, i);

		FILE *size_file = fopen(strcat(mtd_device_path, "/size"), "r");
		if (size_file == NULL) {
			// We have reached the end of MTD devices
			break;
		}

		snprintf(mtd_device_path, sizeof(mtd_device_path), "%s/mtd%d", SYSFS_MTD_DEVICES_PATH, i);
		FILE *erase_size_file = fopen(strcat(mtd_device_path, "/erasesize"), "r");
		if (erase_size_file == NULL) {
			perror("fopen");
			return 0;
		}

		snprintf(mtd_device_path, sizeof(mtd_device_path), "%s/mtd%d", SYSFS_MTD_DEVICES_PATH, i);
		FILE *name_file = fopen(strcat(mtd_device_path, "/name"), "r");
		if (name_file == NULL) {
			perror("fopen");
			return 0;
		}

		size_t total_size, erase_size;

		fscanf(size_file, "%zu", &total_size);
		fscanf(erase_size_file, "%zu", &erase_size);
		fscanf(name_file, "%31s", name);
		fclose(size_file);
		fclose(erase_size_file);
		fclose(name_file);

		snprintf(devices[num_mtd_devices].dev, sizeof(devices[num_mtd_devices].dev), "mtd%d", i);
		snprintf(devices[num_mtd_devices].name, sizeof(devices[num_mtd_devices].name), "%s", name);

		size_t used_size = total_size - erase_size;
		double percent = (double) used_size / total_size * 100.0;

		// For CST with MTD Devices
		if ((strstr(name, "systemFS") != NULL) || (strstr(name, "var") != NULL) ||
			(strstr(name, "root0") != NULL) || (strstr(name, "root1") != NULL))
		{
			strcpy(dev, devices[num_mtd_devices].dev);
			dev[strlen(dev)] = '\0';

			if (strstr(name, "var") || strstr(name, "root")) {
				char* ptr = strstr(devices[num_mtd_devices].dev, "mtd");
				if (ptr != NULL) {
					ptr += 3; // setzt pointer auf die Position nach dem "mtd" Substring
					int num = atoi(ptr);
					if (strstr(name, "root"))
						snprintf(dev, sizeof(dev), "mtd:root%d", num);
					else if (strstr(name, "var"))
						snprintf(dev, sizeof(dev), "mtdblock%d", num);
				}
			}

			df_size = df_used = df_percent = 0.0;
			total_size = used_size = percent = 0.0;
			if (parse_df(dev, &df_size, &df_used, &df_percent) == 0) {
				//printf("parse df: DEV = %s %ld %ld %f\n", devices[num_mtd_devices].dev, df_size, df_used, df_percent);
				total_size = df_size;
				used_size = df_used;
				percent = df_percent;
			}
		}

		devices[num_mtd_devices].total_size = total_size;
		devices[num_mtd_devices].used_size = used_size;
		devices[num_mtd_devices].used_percentage = percent;

		//printf("Sizes = %zu %zu %lf\n", total_size, used_size, percent);
		if (total_size < 1024) {
			snprintf(devices[num_mtd_devices].total_size_str, sizeof(devices[num_mtd_devices].total_size_str), "%.0f B", (double) total_size);
		} else if (total_size < (1024 * 1024)) {
			snprintf(devices[num_mtd_devices].total_size_str, sizeof(devices[num_mtd_devices].total_size_str), "%.0f K", (double) total_size / 1024.0);
		} else {
			snprintf(devices[num_mtd_devices].total_size_str, sizeof(devices[num_mtd_devices].total_size_str), "%.2f M", (double) total_size / (1024.0 * 1024.0));
		}

		if (used_size < 1024) {
			snprintf(devices[num_mtd_devices].used_size_str, sizeof(devices[num_mtd_devices].used_size_str), "%.0f B", (double) used_size);
		} else if (total_size < (1024 * 1024)) {
			snprintf(devices[num_mtd_devices].used_size_str, sizeof(devices[num_mtd_devices].used_size_str), "%.0f K", (double) used_size / 1024.0);
		} else {
			snprintf(devices[num_mtd_devices].used_size_str, sizeof(devices[num_mtd_devices].used_size_str), "%.2f M", (double) used_size / (1024.0 * 1024.0));
		}

		num_mtd_devices++;
	}

	return num_mtd_devices;
}
