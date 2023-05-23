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
#define _GNU_SOURCE

#include <math.h>

#include "current.h"
#include "sysinfo.h"
#include "gfx.h"
#include "resize.h"
#include "pngw.h"
#include "fb_display.h"

extern const char NOMEM[];


// Definition der Funktion, die einen einzelnen Pixel im Framebuffer setzt
void set_pixel(int x, int y, uint32_t color) {
    *(lbb + x + swidth*(y)) = color;
}

void set_pixelw(int x, int y, int width, uint32_t color) {
	uint32_t pix = bgra[color];
	y = y-(width/2);
	int i	= 0;
	int ii	= 0;

	for(i = 0; i < width; i++)
	{
		for(ii = 0; ii < width; ii++)
		{
			*(lbb + x+ii + swidth*(y+i)) = pix;
		}
	}
}

void draw_progressbar_bg(int x_start, int y_start, int x_end, int y_end) {
    int x, y;
 	int mid_y = (y_start + y_end) / 2;
	float red = 0, green = 0, blue = 0;
	uint32_t color;

	// Background
	for (y = y_start; y <= mid_y; y++) {
		float color_percent = (float)(y - y_start) / (mid_y - y_start -1);
		red = 32.0 + 128.0 * color_percent;
		green = 32.0 + 128.0 * color_percent;
		blue = 32.0 + 128.0 * color_percent;
		if (red > 160.0) red = 160.0;
		if (green > 160.0) green = 160.0;
		if (blue > 160.0) blue = 160.0;
		color = (uint32_t)(255) << 24 | (uint32_t)(red) << 16 | (uint32_t)(green) << 8 | (uint32_t)(blue);
		for (x = x_start; x < x_end; x++) {
			set_pixel(x, y, color);
		}
	}
	for (y = mid_y; y < y_end; y++) {
		float color_percent = (float)(y - mid_y) / (y_end - mid_y);
		red = 160.0 - 128.0 * color_percent;
		green = 160.0 - 128.0 * color_percent;
		blue = 160.0 - 128.0 * color_percent;
		if (red < 32.0) red = 32.0;
		if (green < 32.0) green = 32.0;
		if (blue < 32.0) blue = 32.0;
		color = (uint32_t)(255) << 24 | (uint32_t)(red) << 16 | (uint32_t)(green) << 8 | (uint32_t)(blue);
		for (x = x_start; x < x_end; x++) {
			set_pixel(x, y, color);
		}
	}
}

void draw_progressbar(int x_start, int y_start, int x_end, int y_end, int start_col, int percent) {
	int x, y, width = x_end - x_start, progress_width;
	float r, g, b, red, green, blue, fx;
	if (percent < 0)   percent = 0;
	if (percent > 100) percent = 100;
	progress_width = (percent * width) / 100;

	draw_progressbar_bg(x_start, y_start, x_end, y_end);
	red = 212.0;
	green = 212.0;
	blue = 0.0;

	switch (start_col)
	{
		case PB_LEFT_RED30:
		case PB_LEFT_GREEN30:
			fx = 0.3;
			break;
		case PB_LEFT_RED70:
		case PB_LEFT_GREEN70:
			fx = 0.7;
			break;
		default:
			fx = 0.3;
			break;
	}

	int mid_y = (y_start + y_end) / 2;
	// ----------------------------
    for (y = y_start; y <= mid_y; y++) {
		float darken_percent = 0.7 - (float)(y - y_start) / (mid_y - y_start) * 0.7;
		for (x = x_start; x < x_end; x++) {
			float color_percent = (float)(x - x_start) / (width - 1);
			uint32_t color;
			if (color_percent < fx) {
				// Smoother Farbverlauf von rot (255, 0, 0) nach gelb (255, 255, 0)
				if (start_col == PB_LEFT_RED30 || start_col == PB_LEFT_RED70) {
					r = red;
					g = green * color_percent / fx;
				}
				else {
					r = red * color_percent / fx;
					g = green;
				}
				b = blue;
				r *= (1.0 - darken_percent);
				g *= (1.0 - darken_percent);
				b *= (1.0 - darken_percent);
				color = (uint32_t)(255) << 24 | (uint32_t)(r) << 16 | (uint32_t)(g) << 8 | (uint32_t)(b);
			} else {
				// Smoother Farbverlauf von gelb (255, 255, 0) nach gelb (255, 255, 0)
				if (start_col == PB_LEFT_RED30 || start_col == PB_LEFT_RED70) {
					r = red * (1.0 - (color_percent - fx) / (1.0-fx));
					g = green;
				}
				else {
					r = red;
					g = green * (1.0 - (color_percent - fx) / (1.0-fx));
				}
				b = blue;
				r *= (1.0 - darken_percent);
				g *= (1.0 - darken_percent);
				b *= (1.0 - darken_percent);
				color = (uint32_t)(255) << 24 | (uint32_t)(r) << 16 | (uint32_t)(g) << 8 | (uint32_t)(b);
			}
			if (x < x_start + progress_width) {
				set_pixel(x, y, color);
			}
		}
	}
	// untere Hälfte
	for (y = mid_y; y < y_end; y++) {
		float darken_percent = (float)(y - mid_y) / (y_end - mid_y) * 0.7;
		for (x = x_start; x < x_end; x++) {
			float color_percent = (float)(x - x_start) / (width - 1);
			uint32_t color;
			if (color_percent < fx) {
				// Smoother Farbverlauf von rot (255, 0, 0) nach gelb (255, 255, 0)
				if (start_col == PB_LEFT_RED30 || start_col == PB_LEFT_RED70) {
					r = red;
					g = green * color_percent / fx;
				}
				else {
					r = red * color_percent / fx;
					g = green;
				}
				b = blue;
				r *= (1.0 - darken_percent);
				g *= (1.0 - darken_percent);
				b *= (1.0 - darken_percent);
				color = (uint32_t)(255) << 24 | (uint32_t)(r) << 16 | (uint32_t)(g) << 8 | (uint32_t)(b);
			} else {
				// Smoother Farbverlauf von gelb (255, 255, 0) nach gelb (255, 255, 0)
				if (start_col == PB_LEFT_RED30 || start_col == PB_LEFT_RED70) {
					r = red * (1.0 - (color_percent - fx) / (1.0-fx));
					g = green;
				}
				else {
					r = red;
					g = green * (1.0 - (color_percent - fx) / (1.0-fx));
				}
				b = blue;
				r *= (1.0 - darken_percent);
				g *= (1.0 - darken_percent);
				b *= (1.0 - darken_percent);
				color = (uint32_t)(255) << 24 | (uint32_t)(r) << 16 | (uint32_t)(g) << 8 | (uint32_t)(b);
			}
			if (x < x_start + progress_width) {
				set_pixel(x, y, color);
			}
		}
	}
}

void setBackground(uint32_t color)
{
	uint32_t *pos = lbb;
	uint32_t *i, pix = bgra[color];
	int count, yres = var_screeninfo.yres;

	if (stride == 7680 && var_screeninfo.xres == 1280) {
		yres = 720;
	}

	for (count = 0; count < yres; count++)
	{
		for (i = pos; i < pos + var_screeninfo.xres; i++)
			*i = pix;
		pos += swidth;
	}
}

void RenderBox(int _sx, int _sy, int _ex, int _ey, int mode, int color, int radius)
{
	int F,R=radius,ssx=_sx,ssy=_sy,dxx=_ex-_sx,dyy=_ey-_sy,rx,ry,wx,wy,count;

	uint32_t *pos = lbb + ssx + swidth * ssy;
	uint32_t *pos0, *pos1, *pos2, *pos3, *i;
	uint32_t pix = bgra[color];

	if (dxx<0)
	{
		printf("[%s] RenderBox called with dx < 0 (%d)\n", __plugin__, dxx);
		dxx=0;
	}

	int dyy_max = var_screeninfo.yres;
	if (ssy + dyy > dyy_max)
	{
		printf("[%s] %s called with height = %d (max. %d)\n", __plugin__, __func__, ssy + dyy, dyy_max);
		dyy = dyy_max - ssy;
	}

	if(R && mode != GRID)
	{
		if(--dyy<=0)
		{
			dyy=1;
		}

		if(R==1 || R>(dxx/2) || R>(dyy/2))
		{
			R=dxx/10;
			F=dyy/10;
			if(R>F)
			{
				if(R>(dyy/3))
				{
					R=dyy/3;
				}
			}
			else
			{
				R=F;
				if(R>(dxx/3))
				{
					R=dxx/3;
				}
			}
		}
		ssx=0;
		ssy=R;
		F=1-R;

		rx=R-ssx;
		ry=R-ssy;

		pos0=pos+(dyy-ry)*swidth;
		pos1=pos+ry*swidth;
		pos2=pos+rx*swidth;
		pos3=pos+(dyy-rx)*swidth;
		while (ssx <= ssy)
		{
			rx=R-ssx;
			ry=R-ssy;
			wx=rx<<1;
			wy=ry<<1;

			for(i=pos0+rx; i<pos0+rx+dxx-wx;i++)
				*i = pix;
			for(i=pos1+rx; i<pos1+rx+dxx-wx;i++)
				*i = pix;
			for(i=pos2+ry; i<pos2+ry+dxx-wy;i++)
				*i = pix;
			for(i=pos3+ry; i<pos3+ry+dxx-wy;i++)
				*i = pix;

			ssx++;
			pos2-=swidth;
			pos3+=swidth;
			if (F<0)
			{
				F+=(ssx<<1)-1;
			}
			else
			{
				F+=((ssx-ssy)<<1);
				ssy--;
				pos0-=swidth;
				pos1+=swidth;
			}
		}
		pos+=R*swidth;
	}

	if (mode == FILL) {
		for (count=R; count<(dyy-R); count++)
		{
			for(i=pos; i<pos+dxx;i++)
				*i = pix;
			pos+=swidth;
		}
	}
	else {
		// horizontal lines
		pos0 = pos;
		int loop, thickness=2;
		for (count=0; count<2; count++)
		{
			for (loop=0; loop<thickness; loop++ )
			{
				for (i=pos; i<pos+dxx; i++)
				{
					*i = pix;
					i++;
					*i = pix;
				}
				pos += swidth;
			}
			pos = pos0;
			pos += swidth * (_ey-_sy-1);
		}

		// columns
		pos = pos0;
		for (count=0; count<2; count++)
		{
			for (loop=0; loop<dyy; loop++)
			{
				i = pos;
				*i = pix;
				i++;
				*i = pix;
				pos+=swidth;
			}
			pos = pos0+dxx-thickness;
		}
	}
}

/******************************************************************************
 * PaintIcon
 ******************************************************************************/

int paintIcon(const char *const fname, int xstart, int ystart, int xsize, int ysize, int *iw, int *ih)
{
int x1, y1, rv=-1, alpha=0, bpp=0;
int imx=0,imy=0,dxo=0,dyo=0,dxp=0,dyp=0;
unsigned char *buffer=NULL;
FILE *tfh;


	if((tfh=fopen(fname,"r"))!=NULL)
	{
		if(png_getsize(fname, &x1, &y1))
		{
			perror(__plugin__ " <invalid PNG-Format>\n");
			fclose(tfh);
			return -1;
		}
		// no resize
		if (xsize == 0 || ysize ==0)
		{
			xsize = x1;
			ysize = y1;
		}
		if((buffer=(unsigned char *) malloc(x1*y1*4))==NULL)
		{
			printf("%s", NOMEM);
			fclose(tfh);
			return -1;
		}

		if(!(rv=png_load(fname, &buffer, &x1, &y1, &bpp)))
		{
			alpha=(bpp==4)?1:0;
			scale_pic(&buffer,x1,y1,xstart,ystart,xsize,ysize,&imx,&imy,&dxp,&dyp,&dxo,&dyo,alpha);
			fb_display(buffer, imx, imy, dxp, dyp, dxo, dyo, 0, alpha);
		}
		free(buffer);
		fclose(tfh);
	}
	*iw = imx;
	*ih = imy;
	return (rv)?-1:0;
}

void scale_pic(unsigned char **buffer, int x1, int y1, int xstart, int ystart, int xsize, int ysize,
			   int *imx, int *imy, int *dxp, int *dyp, int *dxo, int *dyo, int alpha)
{
	float xfact=0, yfact=0;
	int txsize=0, tysize=0;
	int txstart =xstart, tystart= ystart;

	if (xsize > (ex-xstart)) txsize= (ex-xstart);
	else  txsize= xsize;
	if (ysize > (ey-ystart)) tysize= (ey-ystart);
	else tysize=ysize;
	xfact= 1000*txsize/x1;
	xfact= xfact/1000;
	yfact= 1000*tysize/y1;
	yfact= yfact/1000;

	if ( xfact <= yfact)
	{
		*imx=(int)x1*xfact;
		*imy=(int)y1*xfact;
	}
	else
	{
		*imx=(int)x1*yfact;
		*imy=(int)y1*yfact;
	}
	if ((x1 != *imx) || (y1 != *imy))
		*buffer=color_average_resize(*buffer,x1,y1,*imx,*imy,alpha);

	*dxp=0;
	*dyp=0;
	*dxo=txstart;
	*dyo=tystart;
}

void RenderLine(int xa, int ya, int xb, int yb, int width, int color)
{
	int dx = abs (xa - xb);
	int	dy = abs (ya - yb);
	int	x;
	int	y;
	int	End;
	int	step;

	if ( dx > dy )
	{
		int	p = 2 * dy - dx;
		int	twoDy = 2 * dy;
		int	twoDyDx = 2 * (dy-dx);

		if ( xa > xb )
		{
			x = xb;
			y = yb;
			End = xa;
			step = ya < yb ? -1 : 1;
		}
		else
		{
			x = xa;
			y = ya;
			End = xb;
			step = yb < ya ? -1 : 1;
		}
		set_pixelw(x, y, width, color);

		while( x < End )
		{
			x++;
			if ( p < 0 )
				p += twoDy;
			else
			{
				y += step;
				p += twoDyDx;
			}
			set_pixelw(x, y, width, color);
		}
	}
	else
	{
		int	p = 2 * dx - dy;
		int	twoDx = 2 * dx;
		int	twoDxDy = 2 * (dx-dy);

		if ( ya > yb )
		{
			x = xb;
			y = yb;
			End = ya;
			step = xa < xb ? -1 : 1;
		}
		else
		{
			x = xa;
			y = ya;
			End = yb;
			step = xb < xa ? -1 : 1;
		}
		set_pixelw(x, y, width, color);

		while( y < End )
		{
			y++;
			if ( p < 0 )
				p += twoDx;
			else
			{
				x += step;
				p += twoDxDy;
			}
			set_pixelw(x, y, width, color);
		}
	}
}

void RenderHLine(int _sx, int _sy, int _ex, char dot, char width, char spacing, int color)
{
	if (dot == 0)
		RenderBox(_sx,(int)(_sy-(width/2)),_ex, (int)(_sy+(width/2)), FILL, color, 0);

	if (dot == 1)
	{
		while (_sx <= _ex)
		{
			RenderBox(_sx,(int)(_sy-(width/2)),_sx+width, (int)(_sy+(width/2)), FILL, color, 0);
			_sx=_sx+width+(spacing*width);
		}
	}
}

void RenderVLine(int _sx, int _sy, int _ey, char dot, char width, char spacing, int color)
{
	//printf("%d %d %d %d %d %d\n",_sx, _sy, _ey, dot, width, spacing );
	if (dot == 0)
		RenderBox((int)(_sx-(width/2)), _sy,(int)(_sx+(width/2)), _ey, FILL, color, 0);
	if (dot == 1)
	{
		while (_sy <= _ey)
		{
			RenderBox((int)(_sx-(width/2)), _sy,(int)(_sx+(width/2)), _sy+width, FILL, color, 0);
			_sy=_sy + width + (spacing*width);
		}
	}
}
