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
#ifndef __FE_INFOS_H__
#define __FE_INFOS_H__

#include <stdint.h>
#include <linux/dvb/frontend.h>

#define MAX_NUM_FRONTENDS 64

// frontends
struct frontend_info {
    char name[128];
    enum fe_type type;
	uint16_t signal_strength;
	uint16_t snr;
};

int get_frontend_info(struct frontend_info *info_array, int max_num_frontends);

#endif