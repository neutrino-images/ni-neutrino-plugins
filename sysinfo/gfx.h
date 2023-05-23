/*
 * $Id: gfx.h,v 1.0 Exp $
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

#ifndef __GFX_H__
#define __GFX_H__

void setBackground(uint32_t color);
void set_pixel(int x, int y, uint32_t color);
void set_pixelw(int x, int y, int width, uint32_t color);
void RenderBox(int sx, int sy, int ex, int ey, int mode, int color, int radius);
int paintIcon(const char *const fname, int xstart, int ystart, int xsize, int ysize, int *iw, int *ih);
void scale_pic(unsigned char **buffer, int x1, int y1, int xstart, int ystart, int xsize, int ysize,
			   int *imx, int *imy, int *dxp, int *dyp, int *dxo, int *dyo, int alpha);
void RenderLine(int xa, int ya, int xb, int yb, int width, int color);
void RenderHLine(int sx, int sy, int ex, char dot, char width, char spacing, int color);
void RenderVLine(int sx, int sy, int ey, char dot, char width, char spacing, int color);
void draw_progressbar(int start_x, int start_y, int end_x, int end_y, int start_col, int fill_percent);
void draw_progressbar_bg(int start_x, int start_y, int end_x, int end_y);

#endif
