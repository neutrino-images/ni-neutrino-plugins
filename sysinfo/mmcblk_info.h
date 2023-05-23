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

#ifndef __MMCBLK_INFO_H__
#define __MMCBLK_INFO_H__

typedef struct {
	char device[32];
	char mountpoint[256];
	double total_size;
	double free_size;
	double usage_percent;
} mmcblk_info_t;

int is_block_device(const char* path);
int compare_mmcblk_info(const void* a, const void* b);
mmcblk_info_t* get_mmcblk_info(int* num_devices);

#endif