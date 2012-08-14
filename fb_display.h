/*
 * $Id: fb_display.h,v 1.1 2009/12/19 19:42:49 rhabarber1848 Exp $
 *
 * tuxwetter - d-box2 linux project
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

#ifndef __pictureviewer_fbdisplay__
#define __pictureviewer_fbdisplay__
void* convertRGB2FB(unsigned char *rgbbuff, unsigned long count, int bpp, int *cpp);
void fb_display(unsigned char *rgbbuff, int x_size, int y_size, int x_pan, int y_pan, int x_offs, int y_offs, int clearflag, int  transp);
int fb_set_gmode(int gmode);
void getCurrentRes(int *x,int *y);
void clearFB(int cfx, int cfy, int bpp, int cpp);
void closeFB(void);

int showBusy(int sx, int sy, int width, char r, char g, char b);


#endif
