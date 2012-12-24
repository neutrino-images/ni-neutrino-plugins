//#include "config.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include "text.h"
#include "gfx.h"
#include "msgbox.h"

#define FH_ERROR_OK 0
#define FH_ERROR_FILE 1		/* read/access error */
#define FH_ERROR_FORMAT 2	/* file format error */
#define FH_ERROR_MALLOC 3	/* error during malloc */

int fh_txt_trans(const char *name, int xs, int xw, int ys, int dy, int size, int line, int *cut, int *x, int *y, int plot)
{
char tstr[BUFSIZE],rstr[BUFSIZE],*tptr;
int loop=1, j, slen, cnt=0;
FILE *fh;
int just, color=CMCT;

	if(!(fh=fopen(name,"rb")))	return(FH_ERROR_FILE);

	*x=0;
	*y=0;
	while((loop>0) && (fgets(tstr, sizeof(tstr), fh)))
	{
		j=0;
		just=LEFT;
		color=CMCT;
		
		tptr=tstr+strlen(tstr);
		while((tptr>=tstr) && (*tptr<=32))
		{
			*tptr=0;
			--tptr;
		}
		tptr=tstr;
		while(*tptr)
		{
			rstr[j++]=*tptr;
			cnt++;

			if(*tptr == '~')
			{
				switch (*(tptr+1))
				{
					case 'l': just=LEFT; break;
					case 'r': just=RIGHT; break;
					case 'c': just=CENTER; break;
					case 's':
						RenderBox(xs, ys-size/3+1, xs+xw, ys-size/3+2, FILL, CMS);
						RenderBox(xs, ys-size/3, xs+xw, ys-size/3+1, FILL, CMCIT);
						break;
				}
			}
			tptr++;
		}
		if((loop>0) && (ys<(ey-dy)))
		{
			rstr[j]=0;
			if(plot)
			{
				if(loop>=line)
				{
					RenderString(rstr, xs, ys, xw, just, size, color);
					ys+=dy;
				}
			}
			else
			{
				if(strlen(rstr))
				{
					slen=GetStringLen(xs, rstr, size);
					if(slen>*x)
					{
						*x=slen;
					}
				}
				*y=*y+1;
			}
		}
	}
	if(plot)
	{
		*cut=(ys>=(ey-dy));
	}
	fclose(fh);
	return(FH_ERROR_OK);
}

int fh_txt_load(const char *name, int sx, int wx, int sy, int dy, int size, int line, int *cut)
{
int dummy;

	return fh_txt_trans(name, sx, wx, sy, dy, size, line, cut, &dummy, &dummy, 1);
}


int fh_txt_getsize(const char *name, int *x, int *y, int size, int *cut)
{
	return fh_txt_trans(name, 0, 0, 0, 0, size, 0, cut, x, y, 0);
}
