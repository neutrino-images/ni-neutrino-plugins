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
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "text.h"
#include "gfx.h"
#include "fb_display.h"


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
	int count, xc, yc;

	// int ssx=startx+xoffs;
	// int ssy=starty+yoffs;
	int ssx=xoffs;
	int ssy=yoffs;

	xc = (width  > var_screeninfo.xres) ? var_screeninfo.xres : width;
	yc = (height > var_screeninfo.yres) ? var_screeninfo.yres : height;

	int xo = (ssx/*xoffs*/ * cpp)/sizeof(uint32_t);

	switch(cpp){
		case 4:
		{
			uint32_t * data = (uint32_t *) fbbuff;
			uint32_t * d = (uint32_t *)lbb + xo + swidth * ssy/*yoffs*/;
			uint32_t * d2 = (uint32_t *) (((uintptr_t) d + 15) & ~15); // Align the pointer to 16-byte boundary

			uint32_t *pixpos = &data[(yp * width) + xp];
			uint32_t *pixpos_end = pixpos + (yc * width);

			for (; pixpos < pixpos_end; pixpos += width) {
				for (count = 0; count < xc; count++) {
					uint32_t pix = *(pixpos + count);
					if ((pix & 0xff000000) == 0xff000000) {
						*(d2 + count) = pix;
					} else {
						uint8_t *in = (uint8_t *) &pix;
						uint8_t *out = (uint8_t *) (d2 + count);
						int a = in[3];
						*out = (*out + ((*in - *out) * a) / 256);
						in++;
						out++;
						*out = (*out + ((*in - *out) * a) / 256);
						in++;
						out++;
						*out = (*out + ((*in - *out) * a) / 256);
					}
				}
				d2 += swidth;
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

void* convertRGB2FB(unsigned char* rgbbuff, unsigned long count, int bpp, int* cpp, int alpha) {
    unsigned long i;
    unsigned int* fbbuff = NULL;
    unsigned char* rgb;
    unsigned int transp = 0;
    unsigned int argb;

    switch (bpp) {
        case 24:
        case 32:
            *cpp = 4;
            fbbuff = (unsigned int*)malloc(count * sizeof(unsigned int));
            if (fbbuff == NULL) {
                printf("Error: malloc\n");
                return NULL;
            }
            if (alpha) {
                for (i = 0; i < count; i++) {
                    rgb = &rgbbuff[i * 4];
                    argb = ((rgb[3] << 24) & 0xFF000000) | ((rgb[0] << 16) & 0x00FF0000) |
                           ((rgb[1] << 8) & 0x0000FF00) | (rgb[2] & 0x000000FF);
                    fbbuff[i] = argb;
                }
            } else {
                for (i = 0; i < count; i++) {
                    rgb = &rgbbuff[i * 3];
                    transp = ((rgb[0] || rgb[1] || rgb[2]) ? 0xFF000000 : 0);
                    argb = transp | ((rgb[0] << 16) & 0x00FF0000) | ((rgb[1] << 8) & 0x0000FF00) |
                           (rgb[2] & 0x000000FF);
                    fbbuff[i] = argb;
                }
            }
            break;
        default:
            fprintf(stderr, "Unsupported video mode! You've got: %dbpp\n", bpp);
            exit(1);
    }
    return (void*)fbbuff;
}

