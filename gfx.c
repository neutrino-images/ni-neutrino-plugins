#include <math.h>

#include "current.h"
#include "input.h"

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

void RenderBox(int _sx, int _sy, int _ex, int _ey, int rad, int col)
{
	int F,R=rad,ssx=startx+_sx,ssy=starty+_sy,dxx=_ex-_sx,dyy=_ey-_sy,rx,ry,wx,wy,count;

	uint32_t *pos = lbb + ssx + stride * ssy;
	uint32_t *pos0, *pos1, *pos2, *pos3, *i;
	uint32_t pix = bgra[col];

	if (dxx<0) 
	{
		fprintf(stderr, "[%s] RenderBox called with dx < 0 (%d)\n",__plugin__ , dxx);
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

void RenderCircle(int _sx, int _sy, int col)
{
	int x, y;
	uint32_t pix = bgra[col];
	uint32_t *p = lbb + startx + _sx;
	int s = stride * (starty + _sy /*+ y*/);
	int h = GetCircleHeight();

	for(y = 0; y < h * h; y += h, s += stride)
		for(x = 0; x < h; x++)
			switch(circle[x + y]) {
				case 1: *(p + x + s) = pix; break;
				case 2: *(p + x + s) = 0xFFFFFFFF; break;
			}
}
