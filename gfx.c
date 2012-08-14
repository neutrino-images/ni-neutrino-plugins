#include "logomask.h"
#include "gfx.h"

gpixel *make_color(int col, gpixel *pix)
{
	pix->cpixel.bl=bl[col];
	pix->cpixel.gn=gn[col];
	pix->cpixel.rd=rd[col];
	pix->cpixel.tr=tr[col];
	return pix;
};

void RenderBox(int sx, int sy, int ex, int ey, int mode, gpixel *pix)
{
	int F,ssx=startx+sx,ssy=starty+sy,dxx=ex-sx,dyy=ey-sy,rx,ry,wx,wy,count;

	unsigned char *pos=(lbb+(ssx<<2)+fix_screeninfo.line_length*ssy);
	unsigned char *pos0, *pos1, *pos2, *pos3, *i;
		
	if (dxx<0) 
	{
		printf("[gfx.c] RenderBox called with dx < 0 (%d)\n", dxx);
		dxx=0;
	}

	if(mode==FILL)
	{
		for (count=0; count<dyy; count++)
		{
			for(i=pos; i<pos+(dxx<<2);i+=4)
				memcpy(i, pix, 4);
			pos+=fix_screeninfo.line_length;
		}
	}
	else
	{
		for (count=0; count<2 && count<dyy-2; count++)
		{
			for(i=pos; i<pos+(dxx<<2);i+=4)
				memcpy(i, pix, 4);
			pos+=fix_screeninfo.line_length;
		}
		for (count=2; count<dyy-2; count++)
		{
			memcpy(pos, pix, 4);
			memcpy(pos+4, pix, 4);
			memcpy(pos+((dxx-2)<<2), pix, 4);
			memcpy(pos+((dxx-1)<<2), pix, 4);
			pos+=fix_screeninfo.line_length;
		}
		for (count=0; count<2 && count<dyy-2; count++)
		{
			for(i=pos; i<pos+(dxx<<2);i+=4)
				memcpy(i, pix, 4);
			pos+=fix_screeninfo.line_length;
		}
	}
}


