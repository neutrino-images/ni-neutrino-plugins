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

int fh_php_trans(const char *name, int _sx, int _sy, int dy, int cs, int line, int highlite, int *cut, int *x, int *y, int plain, int plot)
{
char tstr[BUFSIZE]={0},rstr[BUFSIZE]={0},*tptr=NULL,*xptr=NULL,cc,br3flag=0;
int loop=1, j, first, aline=0, fx=_sx, fy=_sy, slen, deg=0;

int wxw=ex-_sx-((preset)?scale2res(120):scale2res(30));		//box width
int wyw=ey-_sy-((preset)?scale2res(60):scale2res(40));		//box height

FILE *fh;

	if(!(fh=fopen(name,"rb")))	return(FH_ERROR_FILE);

	first=(line==0);
	*x=0;
	*y=0;
//	_sy+=dy;
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
											cc=0xA4;  //ä
										}
										break;
									case 'A': cc=0x84; break;
									case 'o': cc=0xB6; break;
									case 'O': cc=0x96; break;
									case 'u': cc=0xBC; break;
									case 'U': cc=0x9C; break;
									case 's': cc=0x9F; break; // ß
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
									rstr[j++]=0xC3;
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
					if((loop>0) && (_sy<(fy+wyw/*420*/)))
					{
						rstr[j]=0;
						if(plot)
						{

							if(!br3flag)
							{
								RenderString(rstr, _sx, _sy, wxw/*619*/, LEFT, cs, (first && highlite)?GREEN:CMCT);
							}
							else
							{
								RenderString(rstr, _sx, fx+scale2res(250), wxw/*619*/, CENTER, FSIZE_BIG, CMCT);
							}
							if(strlen(rstr))
							{
								first=0;
							}
							_sy+=dy;
						}
						else
						{
							if(strlen(rstr))
							{
								slen=GetStringLen(_sx, rstr, FSIZE_MED);
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
					int ssx = ((preset)?scale2res(82):scale2res(25));
					*cut=(_sy>=(fy+wyw/*420*/));
					if(line)
					{
						RenderString("<<", ssx, fy, _sx, LEFT, FSIZE_MED, CMHT);
					}
					if(*cut)
					{
						RenderString(">>", ssx, _sy-dy, _sx, LEFT, FSIZE_MED, CMHT);
					}
				}
			}
		}
	}
	fclose(fh);
	return(FH_ERROR_OK);
}

int fh_php_load(const char *name, int _sx, int _sy, int dy, int cs, int line, int highlite, int plain, int *cut)
{
	int dummy;
	
	return fh_php_trans(name, _sx, _sy, dy, cs, line, highlite, cut, &dummy, &dummy, plain, 1);
}


int fh_php_getsize(const char *name, int plain, int *x, int *y)
{
	int dummy;
	
	return fh_php_trans(name, 0, 0, 0, 0, 0, 0, &dummy, x, y, plain, 0);
}
