/*
 * InitFB
 * Framebuffer initalisation helper for VUPLUS / E4HD 4K Ultra by BPanther (https://forum.mbremer.de)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 */

#include <config.h>
#include <linux/fb.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <string.h>
#include <unistd.h>

#if BOXMODEL_E4HDULTRA
#define FB_WIDTH_STD 220
#define FB_HEIGHT_STD 176
#define FB_BPP 16
#else
#define FB_WIDTH_STD 1280
#define FB_HEIGHT_STD 720
#define FB_WIDTH_HIGH 1920
#define FB_HEIGHT_HIGH 1080
#define FB_BPP 32
#endif

#ifndef FBIO_BLIT
#define FBIO_SET_MANUAL_BLIT _IOW('F', 0x21, __u8)
#define FBIO_BLIT 0x22
#endif

int g_fbFd = -1;
#if BOXMODEL_E4HDULTRA
char g_fbDevice[] = "/dev/fb1";
#else
char g_fbDevice[] = "/dev/fb0";
#endif
unsigned char tmp;
struct fb_var_screeninfo g_screeninfo_var;
struct fb_fix_screeninfo g_screeninfo_fix;

int main(int argc, char **argv)
{
	g_fbFd = open(g_fbDevice, O_RDWR);
	if (ioctl(g_fbFd, FBIO_BLIT) < 0)
		perror("FBIO_BLIT");
	tmp = 1;
	if (ioctl(g_fbFd, FBIO_SET_MANUAL_BLIT, &tmp)<0)
		perror("FBIO_SET_MANUAL_BLIT (on)");
	tmp = 0;
	if (ioctl(g_fbFd, FBIO_SET_MANUAL_BLIT, &tmp)<0)
		perror("FBIO_SET_MANUAL_BLIT (off)");

	g_screeninfo_var.xres_virtual = g_screeninfo_var.xres = FB_WIDTH_STD;
	g_screeninfo_var.yres_virtual = g_screeninfo_var.yres = FB_HEIGHT_STD;

#if !BOXMODEL_E4HDULTRA
	for(int x=1; x<argc; x++) {
		if ((!strcmp(argv[x], "1"))) {
			g_screeninfo_var.xres_virtual = g_screeninfo_var.xres = FB_WIDTH_HIGH;
			g_screeninfo_var.yres_virtual = g_screeninfo_var.yres = FB_HEIGHT_HIGH;
		}
	}
#endif

	printf("OSD-RES: %i x %i\n", g_screeninfo_var.xres_virtual, g_screeninfo_var.yres_virtual);

	g_screeninfo_var.bits_per_pixel = FB_BPP;
	g_screeninfo_var.xoffset = g_screeninfo_var.yoffset = 0;
	g_screeninfo_var.height = 0;
	g_screeninfo_var.width = 0;

	if (ioctl(g_fbFd, FBIOPUT_VSCREENINFO, &g_screeninfo_var) < 0)
		perror("Error: Cannot set variable information!");

	if (g_fbFd >= 0)
	{
		close(g_fbFd);
		g_fbFd = -1;
	} else
		perror("Error: Framebuffer not available!\n");
}
