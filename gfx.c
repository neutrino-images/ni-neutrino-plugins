#include "input.h"

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

void RenderBox(int sx, int sy, int ex, int ey, int rad, int col)
{
	int F,R=rad,ssx=startx+sx,ssy=starty+sy,dxx=ex-sx,dyy=ey-sy,rx,ry,wx,wy,count;

	unsigned char *pos=(lbb+(ssx<<2)+fix_screeninfo.line_length*ssy);
	unsigned char *pos0, *pos1, *pos2, *pos3, *i;
	unsigned char pix[4]={bl[col],gn[col],rd[col],tr[col]};
		
	if (dxx<0) 
	{
		printf("[input] RenderBox called with dx < 0 (%d)\n", dxx);
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

