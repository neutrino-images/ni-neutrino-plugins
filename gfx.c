#include <math.h>

#include "current.h"
#include "gfx.h"

char circle[] =
{
	0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,
	0,2,1,1,1,1,1,1,1,1,1,1,1,1,2,0,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,
	0,2,1,1,1,1,1,1,1,1,1,1,1,1,2,0,
	0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0
};

size_t GetCircleHeight()
{
	return sqrt(sizeof(circle));
}

//typedef struct { unsigned char width_lo; unsigned char width_hi; unsigned char height_lo; unsigned char height_hi; 	unsigned char transp; } IconHeader;

void RenderBox(int sx, int sy, int ex, int ey, int rad, int col)
{
	int F,R=rad,ssx=startx+sx,ssy=starty+sy,dxx=ex-sx,dyy=ey-sy,rx,ry,wx,wy,count;

	uint32_t *pos = lbb + ssx + stride * ssy;
	uint32_t *pos0, *pos1, *pos2, *pos3, *i;
	uint32_t pix = bgra[col];

	if (dxx<0)
	{
		printf("[%s] RenderBox called with dx < 0 (%d)\n", __plugin__, dxx);
		dxx=0;
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
 * RenderCircle
 ******************************************************************************/

void RenderCircle(int sx, int sy, char col)
{
	int x, y;
	uint32_t pix = bgra[col];
	uint32_t *p = lbb + startx + sx;
	int s = stride * (starty + sy);
	int h = GetCircleHeight();

	for(y = 0; y < h * h; y += h, s += stride)
		for(x = 0; x < h; x++)
			switch(circle[x + y]) {
				case 1: *(p + x + s) = pix; break;
				case 2: *(p + x + s) = 0xFFFFFFFF; break;
			}
}

/******************************************************************************
 * PaintIcon
 ******************************************************************************/

/*void PaintIcon(char *filename, int x, int y, unsigned char offset)
{
	IconHeader iheader;
	unsigned int  width, height,count,count2;
	unsigned char pixbuf[768],*pixpos,compressed,pix1,pix2;
	unsigned char * d = (lbb+(startx+x)+var_screeninfo.xres*(starty+y));
	unsigned char * d2;
	int fd;

	fd = open(filename, O_RDONLY);

	if (fd == -1)
	{
		printf("%s <unable to load icon: %s>\n", __plugin__, filename);
		return;
	}

	read(fd, &iheader, sizeof(IconHeader));

	width  = (iheader.width_hi  << 8) | iheader.width_lo;
	height = (iheader.height_hi << 8) | iheader.height_lo;


	for (count=0; count<height; count ++ )
	{
		read(fd, &pixbuf, width >> 1 );
		pixpos = (unsigned char*) &pixbuf;
		d2 = d;
		for (count2=0; count2<width >> 1; count2 ++ )
		{
			compressed = *pixpos;
			pix1 = (compressed & 0xf0) >> 4;
			pix2 = (compressed & 0x0f);

			if (pix1 != iheader.transp)
			{
				*d2=pix1 + offset;
			}
			d2++;
			if (pix2 != iheader.transp)
			{
				*d2=pix2 + offset;
			}
			d2++;
			pixpos++;
		}
		d += var_screeninfo.xres;
	}
	close(fd);
	return;
}
*/
