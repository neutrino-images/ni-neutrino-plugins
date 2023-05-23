/*
 * $Id: sysinfo.h,v 1.0 Exp $
 *
 * sysinfo - coolstream linux project
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

#ifndef __SYSINFO_H__
#define __SYSINFO_H__

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <linux/fb.h>
#include <linux/input.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/un.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_CACHE_H
#include FT_CACHE_SMALL_BITMAPS_H

#ifndef FB_DEVICE
#define FB_DEVICE	"/dev/fb/0"
#endif
#ifndef FB_DEVICE_FALLBACK
#define FB_DEVICE_FALLBACK	"/dev/fb0"
#endif
#ifndef CONFIGDIR
#define CONFIGDIR "/var/tuxbox/config"
#endif
#ifndef FONTDIR
#define FONTDIR	"/share/fonts"
#endif

#define NCFFILE CONFIGDIR "/neutrino.conf"

//freetype stuff

enum {LEFT, CENTER, RIGHT};
//enum {VSMALL, SMALL, MED, BIG};

extern FT_Error error;
extern FT_Library library;
extern FTC_Manager manager;
extern FTC_SBitCache cache;
extern FTC_SBit sbit;
extern FTC_ImageTypeRec desc;
extern FT_Face face;
extern FT_UInt prev_glyphindex;
extern FT_Bool use_kerning;

//framebuffer stuff

enum {
	PB_LEFT_RED30,
	PB_LEFT_RED70,
	PB_LEFT_GREEN30,
	PB_LEFT_GREEN70
	};

enum { FILL, GRID } ;
enum {
	CMCST,
	CMCS,
	CMCT,
	CMC,
	CMCIT,
	CMCI,
	CMHT,
	CMH,
	WHITE,
	BLUE0,
	TRANSP,
	CMS,
	ORANGE,
	GREEN,
	YELLOW,
	RED,
	LRED,
	HGREY,
	COL_MENUCONTENT_PLUS_0,
	COL_MENUCONTENT_PLUS_1,
	COL_MENUCONTENT_PLUS_2,
	COL_MENUCONTENT_PLUS_3,
	COL_SHADOW_PLUS_0
};

extern int FSIZE_BIG;
extern int FSIZE_MED;
extern int FSIZE_SMALL;
extern int FSIZE_VSMALL;

extern int OFFSET_MED;
extern int OFFSET_SMALL;
	extern int OFFSET_MIN;

extern uint32_t bgra[];
extern int stride;
extern int swidth;
extern uint32_t *lfb, *lbb;
extern int instance;
extern int startx, starty, sx, ex, sy, ey;

// devs
extern struct input_event ev;
extern unsigned short rccode;
extern int rc;
extern int fb;

extern struct fb_fix_screeninfo fix_screeninfo;
extern struct fb_var_screeninfo var_screeninfo;

int get_instance(void);
void put_instance(int pval);
void up_main_mem(void);
void hintergrund(void);
int Read_Neutrino_Cfg(char *entry);
void render_koord(char ver);
void up_full(char sel);
void up_net(void);
void get_substring(const char *str, char *out, const char delimiter);
void read_neutrino_osd_conf(int *ex,int *sx,int *ey, int *sy);
void daten_auslesen(const char *buffer, char *ergebnis, const size_t size, const char symbol1, const char symbol2);
void get_homepage(const char* filename, char* out);
void closedown(void);

#endif
