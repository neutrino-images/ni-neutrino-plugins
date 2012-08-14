#include "shellexec.h"
#include "gfx.h"

char circle[] =
{
	0,0,0,0,0,1,1,0,0,0,0,0,
	0,0,0,1,1,1,1,1,1,0,0,0,
	0,0,1,1,1,1,1,1,1,1,0,0,
	0,1,1,1,1,1,1,1,1,1,1,0,
	0,1,1,1,1,1,1,1,1,1,1,0,
	1,1,1,1,1,1,1,1,1,1,1,1,
	1,1,1,1,1,1,1,1,1,1,1,1,
	0,1,1,1,1,1,1,1,1,1,1,0,
	0,1,1,1,1,1,1,1,1,1,1,0,
	0,0,1,1,1,1,1,1,1,1,0,0,
	0,0,0,1,1,1,1,1,1,0,0,0,
	0,0,0,0,0,1,1,0,0,0,0,0
};

//typedef struct { unsigned char width_lo; unsigned char width_hi; unsigned char height_lo; unsigned char height_hi; 	unsigned char transp; } IconHeader;


void RenderBox(int sx, int sy, int ex, int ey, int rad, int col)
{
	int F,R=rad,ssx=startx+sx,ssy=starty+sy,dxx=ex-sx,dyy=ey-sy,rx,ry,wx,wy,count;

	unsigned char *pos=(lbb+(ssx<<2)+fix_screeninfo.line_length*ssy);
	unsigned char *pos0, *pos1, *pos2, *pos3, *i;
	unsigned char pix[4]={bl[col],gn[col],rd[col],tr[col]};

	if (dxx<0)
	{
		printf("[shellexec] RenderBox called with dx < 0 (%d)\n", dxx);
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

		pos0=pos+((dyy-ry)*fix_screeninfo.line_length);
		pos1=pos+(ry*fix_screeninfo.line_length);
		pos2=pos+(rx*fix_screeninfo.line_length);
		pos3=pos+((dyy-rx)*fix_screeninfo.line_length);
		while (ssx <= ssy)
		{
			rx=R-ssx;
			ry=R-ssy;
			wx=rx<<1;
			wy=ry<<1;

			for(i=pos0+(rx<<2); i<pos0+((rx+dxx-wx)<<2);i+=4)
				memcpy(i, pix, 4);
			for(i=pos1+(rx<<2); i<pos1+((rx+dxx-wx)<<2);i+=4)
				memcpy(i, pix, 4);
			for(i=pos2+(ry<<2); i<pos2+((ry+dxx-wy)<<2);i+=4)
				memcpy(i, pix, 4);
			for(i=pos3+(ry<<2); i<pos3+((ry+dxx-wy)<<2);i+=4)
				memcpy(i, pix, 4);

			ssx++;
			pos2-=fix_screeninfo.line_length;
			pos3+=fix_screeninfo.line_length;
			if (F<0)
			{
				F+=(ssx<<1)-1;
			}
			else
			{
				F+=((ssx-ssy)<<1);
				ssy--;
				pos0-=fix_screeninfo.line_length;
				pos1+=fix_screeninfo.line_length;
			}
		}
		pos+=R*fix_screeninfo.line_length;
	}

	for (count=R; count<(dyy-R); count++)
	{
		for(i=pos; i<pos+(dxx<<2);i+=4)
			memcpy(i, pix, 4);
		pos+=fix_screeninfo.line_length;
	}
}

/******************************************************************************
 * RenderCircle
 ******************************************************************************/

void RenderCircle(int sx, int sy, char col)
{
	int x, y;
	unsigned char pix[4]={bl[col],gn[col],rd[col],tr[col]};
	//render

		for(y = 0; y < 12; y++)
		{
			for(x = 0; x < 12; x++) if(circle[x + y*12]) memcpy(lbb + (startx + sx + x)*4 + fix_screeninfo.line_length*(starty + sy + y), pix, 4);
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
		printf("shellexec <unable to load icon: %s>\n", filename);
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