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

//#include "config.h"
#include <string.h>
#include <stdio.h>
#include "text.h"
#include "io.h"
#include "gfx.h"
#include "fb_display.h"

extern unsigned int alpha;

void blit2FB(void *fbbuff,
	uint32_t width, uint32_t height,
	uint32_t xoffs, uint32_t yoffs,
	uint32_t xp, uint32_t yp,
	int cpp);

void fb_display(unsigned char *rgbbuff, int x_size, int y_size, int x_pan, int y_pan, int x_offs, int y_offs, int clearflag, int alpha)
{
	void *fbbuff = NULL;
	int bp = 0;
	if(rgbbuff==NULL)
		return;

	/* correct panning */
	if(x_pan > x_size - (int)var_screeninfo.xres) x_pan = 0;
	if(y_pan > y_size - (int)var_screeninfo.yres) y_pan = 0;
	/* correct offset */
	if(x_offs + x_size > (int)var_screeninfo.xres) x_offs = 0;
	if(y_offs + y_size > (int)var_screeninfo.yres) y_offs = 0;

	/* blit buffer 2 fb */
	fbbuff = convertRGB2FB(rgbbuff, x_size * y_size, var_screeninfo.bits_per_pixel, &bp, alpha);
	if(fbbuff==NULL)
		return;
	/* ClearFB if image is smaller */
	if(clearflag)
		clearFB();
	blit2FB(fbbuff, x_size, y_size, x_offs, y_offs, x_pan, y_pan, bp);
	free(fbbuff);
}

void blit2FB(void *fbbuff,
	uint32_t width, uint32_t height,
	uint32_t xoffs, uint32_t yoffs,
	uint32_t xp, uint32_t yp,
	int cpp)
{
	int count, count2, xc, yc;

	int ssx=startx+xoffs;
	int ssy=starty+yoffs;

	xc = (width  > var_screeninfo.xres) ? var_screeninfo.xres : width;
	yc = (height > var_screeninfo.yres) ? var_screeninfo.yres : height;

	int xo = (ssx/*xoffs*/ * cpp)/sizeof(uint32_t);

	switch(cpp){
		case 4:
		{
			uint32_t * data = (uint32_t *) fbbuff;

			uint32_t * d = (uint32_t *)lbb + xo + stride * ssy/*yoffs*/;
			uint32_t * d2;

			for (count = 0; count < yc; count++ ) {
				uint32_t *pixpos = &data[(count + yp) * width];
				d2 = (uint32_t *) d;
				for (count2 = 0; count2 < xc; count2++ ) {
					uint32_t pix = *(pixpos + xp);
					if ((pix & 0xff000000) == 0xff000000)
						*d2 = pix;
					else {
						uint8_t *in = (uint8_t *)(pixpos + xp);
						uint8_t *out = (uint8_t *)d2;
						int a = in[3];	/* TODO: big/little endian */
						*out = (*out + ((*in - *out) * a) / 256);
						in++; out++;
						*out = (*out + ((*in - *out) * a) / 256);
						in++; out++;
						*out = (*out + ((*in - *out) * a) / 256);
					}
					d2++;
					pixpos++;
				}
				d += stride;
			}
		}
		break;
	}
}

void clearFB()
{
	memset(lbb, 0, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
	memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
}

void* convertRGB2FB(unsigned char *rgbbuff, unsigned long count, int bpp, int *cpp, int alpha)
{
	unsigned long i;
	unsigned int *fbbuff = NULL;

	switch(bpp)
	{
	case 24:
	case 32:
		*cpp = 4;
		fbbuff = (unsigned int *) malloc(count * sizeof(unsigned int));
		if(fbbuff==NULL)
		{
			printf("Error: malloc\n");
			return NULL;
		}
		if(alpha) {
			for(i = 0; i < count ; i++) {
				fbbuff[i] = ((rgbbuff[i*4+3] << 24) & 0xFF000000) | 
					    ((rgbbuff[i*4]   << 16) & 0x00FF0000) | 
					    ((rgbbuff[i*4+1] <<  8) & 0x0000FF00) | 
					    ((rgbbuff[i*4+2])       & 0x000000FF);
			}
		}
		else
		{
			int transp;
			for(i = 0; i < count ; i++) {
				transp = 0;
				if(rgbbuff[i*3] || rgbbuff[i*3+1] || rgbbuff[i*3+2])
				transp = 0xFF;
				fbbuff[i] = (transp << 24) |
					((rgbbuff[i*3]    << 16) & 0xFF0000) |
					((rgbbuff[i*3+1]  <<  8) & 0xFF00) |
					(rgbbuff[i*3+2]          & 0xFF);
			}
		}
		break;
	default:
		fprintf(stderr, "Unsupported video mode! You've got: %dbpp\n", bpp);
		exit(1);
	}
	return (void *)fbbuff;
}
