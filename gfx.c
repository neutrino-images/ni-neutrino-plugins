//getline needed #define _GNU_SOURCE
#define _GNU_SOURCE

#include "tuxwetter.h"
#include "gfx.h"
#include "resize.h"
#include "pngw.h"
#include "fb_display.h"

extern const char NOMEM[];

void Center_Screen(int wx, int wy, int *csx, int *csy)
{
	*csx = ((ex-sx) - wx)/2;
	*csy = ((ey-sy) - wy)/2;
}

/******************************************************************************
 * RenderBox
 ******************************************************************************/
void RenderBox(int rsx, int rsy, int rex, int rey, int rad, int col)
{
	int F,R=rad,ssx=sx+rsx,ssy=sy+rsy,dxx=rex,dyy=rey,rx,ry,wx,wy,count;

	uint32_t *pos = lbb + ssx + stride * ssy;
	uint32_t *pos0, *pos1, *pos2, *pos3, *i;
	uint32_t pix = bgra[col];

	if (dxx<0)
	{
		printf("[tuxwetter] %s called with dxx < 0 (%d)\n", __func__, dxx);
		dxx=0;
	}

	int dyy_max = var_screeninfo.yres;
	if (ssy + dyy > dyy_max)
	{
		printf("[tuxwetter] %s called with max. width = %d (max. %d)\n", __func__, ssy + dyy, var_screeninfo.yres);
		dyy = dyy_max - ssy;
	}

	if(R)
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

		pos0=pos+(dyy-ry)*stride;
		pos1=pos+ry*stride;
		pos2=pos+rx*stride;
		pos3=pos+(dyy-rx)*stride;
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
			pos2-=stride;
			pos3+=stride;
			if (F<0)
			{
				F+=(ssx<<1)-1;
			}
			else
			{
				F+=((ssx-ssy)<<1);
				ssy--;
				pos0-=stride;
				pos1+=stride;
			}
		}
		pos+=R*stride;
	}

	for (count=R; count<(dyy-R); count++)
	{
		for(i=pos; i<pos+dxx;i++)
			*i = pix;
		pos+=stride;
	}
}

/******************************************************************************
 * PaintIcon
 ******************************************************************************/

int paintIcon(const char *const fname, int xstart, int ystart, int xsize, int ysize, int *iw, int *ih)
{
	FILE *tfh;
	int x1, y1, rv=-1, alpha=0, bpp=0;
	int imx,imy,dxo,dyo,dxp,dyp;
	unsigned char *buffer=NULL;

	xstart += sx;
	ystart += sy;

	if((tfh=fopen(fname,"r"))!=NULL)
	{
		if(png_getsize(fname, &x1, &y1))
		{
			perror("tuxwetter <invalid PNG-Format>\n");
			fclose(tfh);
			return -1;
		}
		// no resize
		if (xsize == 0 || ysize == 0)
		{
			xsize = x1;
			ysize = y1;
		}
		if((buffer=(unsigned char *) malloc(x1*y1*4))==NULL)
		{
			printf(NOMEM);
			fclose(tfh);
			return -1;
		}

		if(!(rv=png_load(fname, &buffer, &x1, &y1, &bpp)))
		{
			alpha=(bpp==4)?1:0;
			scale_pic(&buffer,x1,y1,xstart,ystart,xsize,ysize,&imx,&imy,&dxp,&dyp,&dxo,&dyo,0,alpha);

			fb_display(buffer, imx, imy, dxp, dyp, dxo, dyo, 0, 0, alpha);
		}
		free(buffer);
		fclose(tfh);
	}
	*iw = imx;
	*ih = imy;
	return (rv)?-1:0;
}

void scale_pic(unsigned char **buffer, int x1, int y1, int xstart, int ystart, int xsize, int ysize,
			   int *imx, int *imy, int *dxp, int *dyp, int *dxo, int *dyo, int center, int alpha)
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
		if (center !=0)
		{
			tystart=(ey-sy)-*imy;
			tystart=tystart/2;
			tystart=tystart+ystart;
		}
	}
	else
	{
		*imx=(int)x1*yfact;
		*imy=(int)y1*yfact;
		if (center !=0)
		{
			txstart=(ex-sx)-*imx;
			txstart=txstart/2;
			txstart=txstart+xstart;
		}
	}
	if ((x1 != *imx) || (y1 != *imy))
		*buffer=color_average_resize(*buffer,x1,y1,*imx,*imy,alpha);

	*dxp=0;
	*dyp=0;
	*dxo=txstart;
	*dyo=tystart;
}

/******************************************************************************
 * RenderLine
 ******************************************************************************/

void RenderLine( int xa, int ya, int xb, int yb, unsigned char col )
{
	int dx;
	int	dy;
	int	x;
	int	y;
	int	End;
	int	step;
	uint32_t pix = bgra[col];

	dx = abs (xa - xb);
	dy = abs (ya - yb);
	
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
		*(lbb + startx+x + stride*(y+starty)) = pix;

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
			*(lbb + startx+x + stride*(y+starty)) = pix;
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
		*(lbb + startx+x + stride*(y+starty)) = pix;

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

			*(lbb + startx+x + stride*(y+starty)) = pix;
		}
	}
}
