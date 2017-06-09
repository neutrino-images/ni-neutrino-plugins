#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include "text.h"
#include "tuxwetter.h"

#define FH_ERROR_OK 0
#define FH_ERROR_FILE 1		/* read/access error */
#define FH_ERROR_FORMAT 2	/* file format error */
#define FH_ERROR_MALLOC 3	/* error during malloc */

int fh_php_trans(const char *name, int sx, int sy, int dy, int cs, int line, int highlite, int *cut, int *x, int *y, int plain, int plot)
{
char tstr[BUFSIZE],rstr[BUFSIZE],*tptr,*xptr,cc,br3flag=0;
int loop=1, j, first, aline=0, fx=sx, fy=sy, slen, deg=0;

int wxw=ex-sx-((preset)?120:30);		//box width 
int wyw=ey-sy-((preset)?60:40);		//box height

FILE *fh;

	if(!(fh=fopen(name,"rb")))	return(FH_ERROR_FILE);

	first=(line==0);
	*x=0;
	*y=0;
//	sy+=dy;
	while((loop>0) && (fgets(tstr, sizeof(tstr), fh)))
	{
		tptr=tstr+strlen(tstr);
		while((tptr>=tstr) && (*tptr<=32))
		{
			*tptr=0;
			--tptr;
		}

		if(((tptr=strstr(tstr,"<br>"))!=NULL) || ((tptr=strstr(tstr,"<h3>"))!=NULL))
		{
			tptr+=4;
			if((xptr=strstr(tstr,"</h3>"))!=NULL)
			{
				*xptr=0;
				br3flag=1;
			}
			if((*tptr=='=') || (strncmp(tptr,"<br>",4)==0))
			{
				if(aline>=line)
				{
					first=1;
				}
			}
			else
			{
				if(aline++>=line)
				{
					j=0;
					while(*tptr)
					{
						if(plain || (*tptr != '&'))
						{
							rstr[j++]=*tptr;
							tptr++;
						}
						else
						{
							if ((*(tptr+1)!='#') &&
								(strstr(tptr,"uml;") != (tptr+2)) &&
								(strstr(tptr,"nbsp;")!= (tptr+1)) &&
								(strstr(tptr,"gt;")  != (tptr+1)) &&
								(strstr(tptr,"lt;")  != (tptr+1)) &&
								(strstr(tptr,"amp;") != (tptr+1)) &&
								(strstr(tptr,"quot;")!= (tptr+1)) &&
								(strstr(tptr,"zlig;")!= (tptr+2)))
							{
								rstr[j++]=*tptr++;
							}
							else
							{
								tptr++;
								cc=' ';
								switch (*tptr)
								{
									case 'a':
										if (strncmp(tptr,"amp;",4)==0) {
											cc='&';
										}
										else {
											cc='ä';
										}
										break;
									case 'A': cc='Ä'; break;
									case 'o': cc='ö'; break;
									case 'O': cc='Ö'; break;
									case 'u': cc='ü'; break;
									case 'U': cc='Ü'; break;
									case 's': cc='ß'; break;
									case 'q':
									case 'Q': cc='"'; break;
									case 'l':
									case 'g': cc=0;   break;
									case '#': 
										if(sscanf(tptr+1,"%3d",&deg)==1)
										{
											cc=deg;
										}
										break;
								}
								if(cc)
								{
									rstr[j++]=cc;
								}
								if((tptr=strchr(tptr,';'))==NULL)
								{
									printf("Tuxwetter <Parser Error in PHP>\n");
									fclose(fh);
									return -1;
								}
								else
								{
									++tptr;
								}
							}
						}
					}
					if((loop>0) && (sy<(fy+wyw/*420*/)))
					{
						rstr[j]=0;
						if(plot)
						{
							if(!br3flag)
							{
								RenderString(rstr, sx, sy, wxw/*619*/, LEFT, cs, (first && highlite)?GREEN:CMCT);
							}
							else
							{
								RenderString(rstr, sx, fx+250, wxw/*619*/, CENTER, FSIZE_BIG, CMCT);
							}
							if(strlen(rstr))
							{
								first=0;
							}
							sy+=dy;
						}
						else
						{
							if(strlen(rstr))
							{
								slen=GetStringLen(sx, rstr, FSIZE_MED);
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
					int ssy = ((preset)?80:25);
					*cut=(sy>=(fy+wyw/*420*/));
					if(line)
					{
						RenderString("<<", ssy, fy, sx, LEFT, FSIZE_MED, CMHT);
					}
					if(*cut)
					{
						RenderString(">>", ssy, sy-dy, sx, LEFT, FSIZE_MED, CMHT);
					}
				}
			}
		}
	}
	fclose(fh);
	return(FH_ERROR_OK);
}

int fh_php_load(const char *name, int sx, int sy, int dy, int cs, int line, int highlite, int plain, int *cut)
{
	int dummy;
	
	return fh_php_trans(name, sx, sy, dy, cs, line, highlite, cut, &dummy, &dummy, plain, 1);
}


int fh_php_getsize(const char *name, int plain, int *x, int *y)
{
	int dummy;
	
	return fh_php_trans(name, 0, 0, 0, 0, 0, 0, &dummy, x, y, plain, 0);
}
