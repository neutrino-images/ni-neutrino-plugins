/*
 * $Id: fb_display.c,v 1.1 2009/12/19 19:42:49 rhabarber1848 Exp $
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

//#include "config.h"
#include <string.h>
#include <stdio.h>
#ifdef HAVE_DBOX_HARDWARE
#include <dbox/fb.h>
#endif
#include "tuxwetter.h"
#include "parser.h"
//#include "bmps.h"
#include "text.h"
#include "io.h"
#include "gfx.h"
#include "fb_display.h"

#define FB_DEVICE	"/dev/fb/0"

/* Public Use Functions:
 *
 * extern void fb_display(unsigned char *rgbbuff,
 *     int x_size, int y_size,
 *     int x_pan, int y_pan,
 *     int x_offs, int y_offs);
 *
 * extern void getCurrentRes(int *x,int *y);
 *
 */

//static unsigned short rd[] = {0xFF<<8, 0x00<<8, 0x00<<8, 0x00<<8, 0xFF<<8, 0x00<<8, 0xFF<<8, 0xFF<<8};
//static unsigned short gn[] = {0xFF<<8, 0x80<<8, 0x00<<8, 0x80<<8, 0xC0<<8, 0xFF<<8, 0xFF<<8, 0x00<<8};
//static unsigned short bl[] = {0xFF<<8, 0xFF<<8, 0x80<<8, 0xFF<<8, 0x00<<8, 0x00<<8, 0x00<<8, 0x00<<8};
//static unsigned short tr[] = {0x0000,  0x0A00,  0x0A00,  0x0000,  0x0000,  0x0000,  0x0000,  0x0000 };
//static struct fb_cmap map_back = {0, 256, red_b, green_b, blue_b, NULL};
// static unsigned short red_b[256], green_b[256], blue_b[256];

static unsigned short red[256], green[256], blue[256], transp[256];
static struct fb_cmap map332 = {0, 256, red, green, blue, NULL};
extern int fbd; // Framebuffer device
extern unsigned char *lfb;
extern unsigned int alpha;
static int gbpp, gccp, gmode_on=0;
static struct fb_fix_screeninfo fix;
//static struct fb_cmap colormap = {1, 8, rd, gn, bl, tr};

typedef struct pixelformat{
	char *name;
	struct fb_bitfield red;
	struct fb_bitfield green;
	struct fb_bitfield blue;
	struct fb_bitfield transp;
	char bpp;
	char pixenum;
	}spix;


const struct pixelformat gpix = {
	    .name = "RGB565", 		// RGB565
		.bpp = 16, .pixenum = 2,
		.red = 	 { .offset = 11, .length=5, .msb_right =0 },
		.green = { .offset = 5,  .length=6, .msb_right =0 },
		.blue =  { .offset = 0,  .length=5, .msb_right =0 },
		.transp= { .offset = 0,  .length=0, .msb_right =0 },
	};

int openFB(const char *name);
void getFixScreenInfo(struct fb_fix_screeninfo *fix);
int set332map(void);
void blit2FB(void *fbbuff,
	unsigned int pic_xs, unsigned int pic_ys,
	unsigned int scr_xs, unsigned int scr_ys,
	unsigned int xp, unsigned int yp,
	unsigned int xoffs, unsigned int yoffs,
	int cpp, int setpal);

inline unsigned short make16color(unsigned long r, unsigned long g, 
											 unsigned long b, unsigned long rl, 
											 unsigned long ro, unsigned long gl, 
											 unsigned long go, unsigned long bl, 
											 unsigned long bo, unsigned long tl, 
											 unsigned long to);

int fb_set_gmode(int gmode)
{
    struct fb_var_screeninfo var;

	if(ioctl(fb, FBIOGET_VSCREENINFO, &var) == -1)
	{
		printf("fb_display <FBIOGET_VSCREENINFO failed>\n");
		return -1;
	}

	struct fb_fix_screeninfo fix;

	if (ioctl(fb, FBIOGET_FSCREENINFO, &fix)<0) {
		perror("FBIOGET_FSCREENINFO");
		return -1;
	}

//	memset(lfb, 0, stride * yRes);
        if (ioctl(fb, FBIOBLANK, FB_BLANK_UNBLANK) < 0) {
                printf("screen unblanking failed\n");
        }

	gmode_on=gmode;
	return 0;
}


void fb_display(unsigned char *rgbbuff, int x_size, int y_size, int x_pan, int y_pan, int x_offs, int y_offs, int clearflag, int setpal)
{
    struct fb_var_screeninfo var;
    unsigned short *fbbuff = NULL;
    int bp = 0;
    if(rgbbuff==NULL)
		 return;

	if(ioctl(fb, FBIOGET_FSCREENINFO, &fix) == -1)
	{
		printf("fb_display <FBIOGET_FSCREENINFO failed>\n");
		return;
	}

	if(ioctl(fb, FBIOGET_VSCREENINFO, &var) == -1)
	{
		printf("fb_display <FBIOGET_VSCREENINFO failed>\n");
		return;
	}

    /* correct panning */
    if(x_pan > x_size - (int)var.xres) x_pan = 0;
    if(y_pan > y_size - (int)var.yres) y_pan = 0;
    /* correct offset */
    if(x_offs + x_size > (int)var.xres) x_offs = 0;
    if(y_offs + y_size > (int)var.yres) y_offs = 0;
    
    /* blit buffer 2 fb */
    fbbuff = (unsigned short *) convertRGB2FB(rgbbuff, x_size * y_size, var.bits_per_pixel, &bp);
    if(fbbuff==NULL)
		 return;
	 /* ClearFB if image is smaller */
   if(clearflag)
       clearFB(0,0,var.bits_per_pixel, bp);
    blit2FB(fbbuff, x_size, y_size, var.xres, var.yres, x_pan, y_pan, x_offs, y_offs, bp, setpal);
    free(fbbuff);
    gbpp=bp;
    gccp=var.bits_per_pixel;
}

void getCurrentRes(int *x, int *y)
{
    struct fb_var_screeninfo tvar;
    ioctl(fb, FBIOGET_VSCREENINFO, &tvar);
    *x = tvar.xres;
    *y = tvar.yres;
}

void make332map(struct fb_cmap *map)
{
        unsigned short rd[] = {0xFF<<8, 0x00<<8, 0xFF<<8, 0x00<<8, 0xFF<<8, 0x00<<8, 0xFF<<8, 0x00<<8, 
					   0xFF<<8, 0x00<<8, 0x00<<8, 0x00<<8, 0xFF<<8, 0x00<<8, 0xFF<<8, 0xFF<<8};
        unsigned short gn[] = {0xFF<<8, 0x80<<8, 0xFF<<8, 0x00<<8, 0xFF<<8, 0x00<<8, 0xC0<<8, 0x00<<8, 
					   0xFF<<8, 0x80<<8, 0x00<<8, 0x80<<8, 0xC0<<8, 0xFF<<8, 0xFF<<8, 0x00<<8};
        unsigned short bl[] = {0xFF<<8, 0xFF<<8, 0xFF<<8, 0x80<<8, 0xFF<<8, 0x80<<8, 0x00<<8, 0x80<<8, 
					   0xFF<<8, 0xFF<<8, 0x00<<8, 0xFF<<8, 0x00<<8, 0x00<<8, 0x00<<8, 0x00<<8};
        unsigned short tr[] = {0x0000,  0x0A00,  0x0000,  0x0A00,  0x0000,  0x0A00,  0x0000,  0x0000, 
					   0x0000,  0x0A00,  0xFFFF,  0x0000,  0x0000,  0x0000,  0x0000,  0x0000 };

	int rs, gs, bs, i;
	int r = 8, g = 8, b = 4;

	map->red = red;
	map->green = green;
	map->blue = blue;
	map->transp = transp;

	rs = 256 / (r - 1);
	gs = 256 / (g - 1);
	bs = 256 / (b - 1);
	
	for (i = 0; i < 256; i++) {
		map->red[i]   = (rs * ((i / (g * b)) % r)) * 255;
		map->green[i] = (gs * ((i / b) % g)) * 255;
		map->blue[i]  = (bs * ((i) % b)) * 255;
		map->transp[i]	= 0x0000;
	}

	// set system-colors
	for (i = 0; i < 16; i++) {
		map->red[i]   = rd[i];
		map->green[i] = gn[i];
		map->blue[i]  = bl[i];
		map->transp[i] = tr[i];
	}

}

int set332map(void)
{
    make332map(&map332);
	return ioctl(fb, FBIOPUTCMAP, &map332);
}

void blit2FB(void *fbbuff,
	unsigned int pic_xs, unsigned int pic_ys,
	unsigned int scr_xs, unsigned int scr_ys,
	unsigned int xp, unsigned int yp,
	unsigned int xoffs, unsigned int yoffs,
	int cpp, int setpal)
{
    int i, xc, yc;
    unsigned char *cp; unsigned short *sp; unsigned int *ip;
    ip = (unsigned int *) fbbuff;
    sp = (unsigned short *) ip;
    cp = (unsigned char *) sp;

    xc = (pic_xs > scr_xs) ? scr_xs : pic_xs;
    yc = (pic_ys > scr_ys) ? scr_ys : pic_ys;

    unsigned int stride = fix.line_length;

	 switch(cpp){
		case 1:
		if(setpal)
		{
			set332map();
		}
	    for(i = 0; i < yc; i++){
			 memcpy(lfb+(i+yoffs)*stride+xoffs*cpp,cp + (i+yp)*pic_xs+xp,xc*cpp);
		 }
		 break;
		 case 2:
			 for(i = 0; i < yc; i++){
				 memcpy(lfb+(i+yoffs)*stride+xoffs*cpp,sp + (i+yp)*pic_xs+xp, xc*cpp);
			 }
			 break;
		 case 4:
			 for(i = 0; i < yc; i++){
				 memcpy(lfb+(i+yoffs)*stride+xoffs*cpp,ip + (i+yp)*pic_xs+xp, xc*cpp);
			 }
			 break;
	 }
}


void clearFB(int cfx, int cfy, int bpp, int cpp)
{
int x,y;

	if(cfx<=0 || cfy<=0)
	{
   		getCurrentRes(&x,&y);
   	}
   	else
   	{
   		x=cfx;
   		y=cfy;
   	}
   	
    unsigned int stride = fix.line_length;
	
	switch(cpp){
		case 2:
			{
				unsigned long rl, ro, gl, go, bl, bo, tl, to;
				unsigned int i;
				struct fb_var_screeninfo tvar;
				ioctl(fb, FBIOGET_VSCREENINFO, &tvar);
				rl = tvar.red.length;
				ro = tvar.red.offset;
				gl = tvar.green.length;
				go = tvar.green.offset;
				bl = tvar.blue.length;
				bo = tvar.blue.offset;
				tl = tvar.transp.length;
				to = tvar.transp.offset;
				short black=make16color(0,0,0, rl, ro, gl, go, bl, bo, tl, to);
				unsigned short *s_fbbuff = (unsigned short *) malloc(y*stride/2 * sizeof(unsigned short));
				if(s_fbbuff==NULL)
				{
					printf("Error: malloc\n");
					return;
				}

				for(i = 0; i < y*stride/2; i++)
				   s_fbbuff[i] = black;
				memcpy(lfb, s_fbbuff, y*stride);
				free(s_fbbuff);
			}
			break;
		case 4:
			{
			unsigned int  col = 0xFF000000;
			unsigned int  * dest = (unsigned int  *) lfb;
			unsigned int i;
			for(i = 0; i < stride*y/4; i ++)
				dest[i] = col;
			}
			break;

		default:
			memset(lfb, 0, stride*y);
	}

}

void closeFB(void)
{
	clearFB(0, 0, gbpp, gccp);
}

inline unsigned char make8color(unsigned char r, unsigned char g, unsigned char b)
{
    return (
	(((r >> 5) & 7) << 5) |
	(((g >> 5) & 7) << 2) |
	 ((b >> 6) & 3)       );
}

inline unsigned short make15color(unsigned char r, unsigned char g, unsigned char b)
{
    return ( 
	(((b >> 3) & 31) << 10) |
	(((g >> 3) & 31) << 5)  |
	 ((r >> 3) & 31)        );
}

inline unsigned short make16color(unsigned long r, unsigned long g, unsigned long b, 
				    unsigned long rl, unsigned long ro, 
				    unsigned long gl, unsigned long go, 
				    unsigned long bl, unsigned long bo, 
				    unsigned long tl, unsigned long to)
{
    return (
//		 ((0xFF >> (8 - tl)) << to) |
	    ((r    >> (8 - rl)) << ro) |
	    ((g    >> (8 - gl)) << go) |
	    ((b    >> (8 - bl)) << bo));
}

void* convertRGB2FB(unsigned char *rgbbuff, unsigned long count, int bpp, int *cpp)
{
    unsigned long i;
    void *fbbuff = NULL;
    unsigned char *c_fbbuff;
    unsigned short *s_fbbuff;
    unsigned int *i_fbbuff;
    unsigned long rl, ro, gl, go, bl, bo, tl, to;
    
	struct fb_var_screeninfo tvar;
    ioctl(fb, FBIOGET_VSCREENINFO, &tvar);
    rl = tvar.red.length;
    ro = tvar.red.offset;
    gl = tvar.green.length;
    go = tvar.green.offset;
    bl = tvar.blue.length;
    bo = tvar.blue.offset;
    tl = tvar.transp.length;
    to = tvar.transp.offset;
	 
	 switch(bpp)
    {
	case 8:
	    *cpp = 1;
	    c_fbbuff = (unsigned char *) malloc(count * sizeof(unsigned char));
		 if(c_fbbuff==NULL)
		 {
			 printf("Error: malloc\n");
			 return NULL;
		 }
	    for(i = 0; i < count; i++)
		c_fbbuff[i] = make8color(rgbbuff[i*3], rgbbuff[i*3+1], rgbbuff[i*3+2]);
	    fbbuff = (void *) c_fbbuff;
	    break;
	case 15:
	    *cpp = 2;
	    s_fbbuff = (unsigned short *) malloc(count * sizeof(unsigned short));
		 if(s_fbbuff==NULL)
		 {
			 printf("Error: malloc\n");
			 return NULL;
		 }
	    for(i = 0; i < count ; i++)
		s_fbbuff[i] = make15color(rgbbuff[i*3], rgbbuff[i*3+1], rgbbuff[i*3+2]);
	    fbbuff = (void *) s_fbbuff;
	    break;
	case 16:
	    *cpp = 2;
	    s_fbbuff = (unsigned short *) malloc(count * sizeof(unsigned short));
		 if(s_fbbuff==NULL)
		 {
			 printf("Error: malloc\n");
			 return NULL;
		 }
	    for(i = 0; i < count ; i++)
			 s_fbbuff[i]=make16color(rgbbuff[i*3], rgbbuff[i*3+1], rgbbuff[i*3+2], rl, ro, gl, go, bl, bo, tl, to);
		 fbbuff = (void *) s_fbbuff;
	    break;
	case 24:
	case 32:
	    *cpp = 4;
	    i_fbbuff = (unsigned int *) malloc(count * sizeof(unsigned int));
		 if(i_fbbuff==NULL)
		 {
			 printf("Error: malloc\n");
			 return NULL;
		 }
	    for(i = 0; i < count ; i++)
		i_fbbuff[i] = (/*transp*/0xFF << 24) | ((rgbbuff[i*3] << 16) & 0xFF0000) | ((rgbbuff[i*3+1] << 8) & 0xFF00) | (rgbbuff[i*3+2] & 0xFF);

	    fbbuff = (void *) i_fbbuff;
	    break;
	default:
	    fprintf(stderr, "Unsupported video mode! You've got: %dbpp\n", bpp);
	    exit(1);
    }
    return fbbuff;
}




int showBusy(int sx, int sy, int width, char r, char g, char b)
{
	unsigned char rgb_buffer[3];
	unsigned char* fb_buffer;
	unsigned char* m_busy_buffer=NULL;
	unsigned char* busy_buffer_wrk;
	int cpp;
	struct fb_fix_screeninfo fix;
	if(ioctl(fb, FBIOGET_FSCREENINFO, &fix) == -1)
	{
		printf("fb_display <FBIOGET_FSCREENINFO failed>\n");
		return -1;
	}
	
	struct fb_var_screeninfo var;
	if(ioctl(fb, FBIOGET_VSCREENINFO, &var) == -1)
	{
		printf("fb_display <FBIOGET_VSCREENINFO failed>\n");
		return -1;
	}
	var.bits_per_pixel = gpix.bpp;

	rgb_buffer[0]=r;
	rgb_buffer[1]=g;
	rgb_buffer[2]=b;

	fb_buffer = (unsigned char*) convertRGB2FB(rgb_buffer, 1, var.bits_per_pixel, &cpp);
	if(fb_buffer==NULL)
	{
		printf("Error: malloc\n");
		return -1;
	}
	if(m_busy_buffer!=NULL)
	{
		free(m_busy_buffer);
		m_busy_buffer=NULL;
	}
	m_busy_buffer = (unsigned char*) malloc(width*width*cpp);
	if(m_busy_buffer==NULL)
	{
		printf("Error: malloc\n");
		return -1;
	}
	busy_buffer_wrk = m_busy_buffer;
      	unsigned int stride = fix_screeninfo.line_length*2;

	int y=0, x=0;
	for(y=sy ; y < sy+width; y++)
	{
		for(x=sx ; x< sx+width; x++)
		{
			memcpy(busy_buffer_wrk, lfb + y * stride + x*cpp, cpp);
			busy_buffer_wrk+=cpp;
			memcpy(lfb + y * stride + x*cpp, fb_buffer, cpp);
		}
	}
return 0;
}
