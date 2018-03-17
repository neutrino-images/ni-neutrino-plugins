#include <string.h>
#include <time.h>
#include "logomask.h"
#include "gfx.h"

extern int FSIZE_BIG;
extern int FSIZE_MED;
extern int FSIZE_SMALL;


#define CL_VERSION  "1.3"
#define MAX_MASK 16

//					TRANSP,	BLACK,	RED, 	GREEN, 	YELLOW,	BLUE, 	MAGENTA, TURQUOISE,
//					WHITE, 	GRAY, 	LRED,	LGREEN,	LYELLOW,LBLUE,	LMAGENTA,LTURQUOISE
unsigned char
			rd[]={	0x00,	0x00,	0x80,	0x00,	0x80,	0x00,	0x80,	0x00,
					0xFF,	0x80,	0xFF,	0x00,	0xFF,	0x00,	0xFF,	0x00
				 },
			gn[]={	0x00,	0x00,	0x00,	0x80,	0x80,	0x00,	0x00,	0x80,
					0xFF,	0x80,	0x00,	0xFF,	0xFF,	0x00,	0x00,	0xFF
				 },
			 bl[]={	0x00,	0x00,	0x00,	0x00,	0x00,	0x80,	0x80,	0x80,
					0xFF,	0x80,	0x00,	0x00,	0x00,	0xFF,	0xFF,	0xFF
			     },
			 tr[]={	0x00,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF,
					0xFF,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF
				  };

unsigned char *lfb = 0, *lbb = 0;
char tstr[BUFSIZE];
int xpos=0,ypos=0,sdat=0,big=0,secs=1;
int wxh, wyh;
gpixel lpix;

void TrimString(char *strg)
{
char *pt1=strg, *pt2=strg;

	while(*pt2 && *pt2<=' ')
	{
		++pt2;
	}
	if(pt1 != pt2)
	{
		do
		{
			*pt1=*pt2;
			++pt1;
			++pt2;
		}
		while(*pt2);
		*pt1=0;
	}
	while(strlen(strg) && strg[strlen(strg)-1]<=' ')
	{
		strg[strlen(strg)-1]=0;
	}
}

int Read_Neutrino_Cfg(char *entry)
{
FILE *nfh;
char *cfptr=NULL;
int rv=-1;

	if((nfh=fopen(NCF_FILE,"r"))!=NULL)
	{
		tstr[0]=0;

		while((!feof(nfh)) && ((strstr(tstr,entry)==NULL) || ((cfptr=strchr(tstr,'='))==NULL)))
		{
			fgets(tstr,500,nfh);
		}
		if(!feof(nfh) && cfptr)
		{
			++cfptr;
			if(sscanf(cfptr,"%d",&rv)!=1)
			{
				rv=-1;
			}
//			printf("%s\n%s=%s -> %d\n",tstr,entry,cfptr,rv);
		}
		fclose(nfh);
	}
	return rv;
}

void xscal(int *xp, int *xw, int sxp, int sxw, double scal)
{
	int xe=sxp+sxw,lxp,lxw;

	lxp=sxp;
	if(sxp<wxh)
		lxp=wxh-(wxh-sxp)*scal;
	else
		lxp=wxh+(sxp-wxh)*scal;
	if(lxp<0)
		lxp=0;
	if(lxp>=var_screeninfo.xres)
		lxp=var_screeninfo.xres-1;
	if(xe<wxh)
		xe=wxh-(wxh-xe)*scal;
	else
		xe=wxh+(xe-wxh)*scal;
	if(xe<0)
		xe=0;
	if(xe>=var_screeninfo.xres)
		xe=var_screeninfo.xres-1;
	lxw=xe-lxp;
	if((lxp+lxw)>=var_screeninfo.xres)
		lxw=var_screeninfo.xres-lxw-1;
	*xp=lxp;
	*xw=lxw;
}

void yscal(int *yp, int *yw, int syp, int syw, double scal)
{
	int ye=syp+syw,lyp,lyw;

	lyp=syp;
	if(syp<wyh)
		lyp=wyh-(wyh-syp)*scal;
	else
		lyp=wyh+(syp-wyh)*scal;
	if(lyp<0)
		lyp=0;
	if(lyp>=var_screeninfo.yres)
		lyp=var_screeninfo.yres-1;
	if(ye<wyh)
		ye=wyh-(wyh-ye)*scal;
	else
		ye=wyh+(ye-wyh)*scal;
	if(ye<0)
		ye=0;
	if(ye>=var_screeninfo.yres)
		ye=var_screeninfo.yres-1;
	lyw=ye-lyp;
	if((lyp+lyw)>=var_screeninfo.yres)
		lyw=var_screeninfo.yres-lyw-1;
	*yp=lyp;
	*yw=lyw;
}

/******************************************************************************
 * logomask Main
 ******************************************************************************/


int main (int argc, char **argv)
{
	int i,j,m,found,loop=1,mask=0,test=0,pmode=0,lmode=0,pmode43=1,lmode43=1,mchanged=1,mchanged43=1,cchanged=2,mwait,tv;
	unsigned char lastchan[20]="", actchan[20]=""/*,channel[128]=""*/;
	int xp[4][MAX_MASK][8],yp[4][MAX_MASK][8],xw[4][MAX_MASK][8],yw[4][MAX_MASK][8],valid[MAX_MASK],xxp,xxw,yyp,yyw,nmsk=0;
	gpixel tp, cmc, mc[MAX_MASK];
	double sc131=1.16666666667, sc132=1.193, sc23=1.33333333333;
	FILE *fh;
	char *cpt1,*cpt2;
	
		if(argc==2 && strstr(argv[1],"test")!=NULL)
		{
			test=1;
		}
		printf("logomask Version %s\n",CL_VERSION);
		if((mwait=Read_Neutrino_Cfg("timing.infobar"))<0)
			mwait=6;
		if((tv=Read_Neutrino_Cfg("video_Format"))<0)
			tv=3;
		--tv;

		/* open Framebuffer */
		fb=open(FB_DEVICE, O_RDWR);
		if (fb < 0)
			fb=open(FB_DEVICE_FALLBACK, O_RDWR);

		if (fb < 0) {
			perror("logomask <open framebuffer>");
			exit(1);
		}

		if(ioctl(fb, FBIOGET_FSCREENINFO, &fix_screeninfo) == -1)
		{
			printf("logomask <FBIOGET_FSCREENINFO failed>\n");
			return -1;
		}
		if(ioctl(fb, FBIOGET_VSCREENINFO, &var_screeninfo) == -1)
		{
			printf("logomask <FBIOGET_VSCREENINFO failed>\n");
			return -1;
		}
		
		if(!(lfb = (unsigned char*)mmap(0, fix_screeninfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fb, 0)))
		{
			printf("logomask <mapping of Framebuffer failed>\n");
			return -1;
		}

	//init backbuffer

		if(!(lbb = malloc(fix_screeninfo.line_length*var_screeninfo.yres)))
		{
			printf("logomask <allocating of Backbuffer failed>\n");
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		memset(lbb, 0, fix_screeninfo.line_length*var_screeninfo.yres);

	// if problem with config file return from plugin
		wxh=var_screeninfo.xres>>1;
		wyh=var_screeninfo.yres>>1;

		while(loop)
		{
			sleep(1);
			mchanged=0;
			if(access("/tmp/.logomask_pause",0)!=-1)
				continue;
			i=0;
			system("wget -Y off -q -O /tmp/logomask.stat http://localhost/control/zapto?statussectionsd");
			if((fh=fopen("/tmp/logomask.stat","r"))!=NULL)
			{
				if(fgets(tstr,500,fh))
				{
					TrimString(tstr);
					if(strlen(tstr))
					{
						sscanf(tstr,"%d",&i);
					}
				}
				fclose(fh);
			}
			if(i!=1)
				continue;
			system("pzapit -var > /tmp/logomaskset.stat");
			if((fh=fopen("/tmp/logomaskset.stat","r"))!=NULL)
			{
				if(fgets(tstr,500,fh))
				{
					TrimString(tstr);
					if(strlen(tstr))
					{
						lmode=pmode;
						if(sscanf(tstr+strlen(tstr)-1,"%d",&i)!=1)
						{
							pmode=0;
						}
						else
						{
							mchanged=(pmode!=i);
							pmode=i;
						}
					}
				}
				fclose(fh);
			}

			if(tv>1)
			{
				system("pzapit -vm43 > /tmp/logomaskset.stat");
				if((fh=fopen("/tmp/logomaskset.stat","r"))!=NULL)
				{
					if(fgets(tstr,500,fh))
					{
						TrimString(tstr);
						if(strlen(tstr))
						{
							lmode43=pmode43;
							if(sscanf(tstr+strlen(tstr)-1,"%d",&i)!=1)
							{
								pmode43=0;
							}
							else
							{
								mchanged43=(pmode43!=i);
								pmode43=i;
							}
						}
					}
					fclose(fh);
				}
			}

			system("pzapit -gi > /tmp/logomask.chan");
			if((fh=fopen("/tmp/logomask.chan","r"))!=NULL)
			{
				if(fgets(tstr, BUFSIZE, fh))
				{
					TrimString(tstr);
					if((cpt1=strchr(tstr,' '))!=NULL)
						*cpt1=0;
				}
				fclose(fh);
				if(strlen(tstr))
				{
					strcpy(actchan,tstr);
					cchanged=(cchanged==2)?3:((mchanged43 || (strcmp(actchan,lastchan))?1:0));
					if(mchanged || cchanged)
					{
						found=0;
						if(cchanged)
						{
							if(cchanged==1)
							{
								sleep((mchanged43)?3:mwait);
							}
							cchanged=1;
						}
						if(mask)
						{
							for(m=0; m<nmsk; m++)
							{
								if(valid[m])
								{
									xxp=xp[lmode43][m][lmode];
									xxw=xw[lmode43][m][lmode];
									yyp=yp[lmode43][m][lmode];
									yyw=yw[lmode43][m][lmode];
									make_color(TRANSP, &cmc);
									RenderBox(xxp, yyp, xxp+abs(xxw), yyp+yyw, FILL,&cmc);
									for(i=0;i<=yyw;i++)
									{
										j=(yyp+i)*fix_screeninfo.line_length+(xxp<<2);
										if((j+(xxw<<2))<=fix_screeninfo.line_length*var_screeninfo.yres)
										{
											memcpy(lfb+j, lbb+j, xxw<<2);
										}
									}
								}
							}
						}
						mask=0;
						
					if((fh=fopen(CFG_FILE,"r"))!=NULL)
					{
						strcpy(lastchan,actchan);
						found=0;
						while(fgets(tstr, BUFSIZE, fh) && !found)
						{
							TrimString(tstr);
							if(strlen(tstr))
							{
								if(strstr(tstr,actchan)!=NULL)
								{
									mask=1;
									nmsk=0;
									cpt2=strstr(tstr,",MC");
									if((cpt1=strchr(tstr,','))!=NULL)
									{
										while(cpt1)
										{
											valid[nmsk]=0;
											if(cpt2 && sscanf(cpt2+1,"MC%8x",&tp)==1)
											{
												cmc.lpixel=tp.lpixel;
												cpt2=strchr(cpt2+1,',');
											}
											else
											{
												make_color(BLACK, &cmc);
											}
											for(i=0; i<8 && cpt1; i++)
											{
												cpt1++;
												if(sscanf(cpt1,"%d,%d,%d,%d",&xxp,&xxw,&yyp,&yyw)==4)
												{
													xp[1][nmsk][i]=xxp;
													xw[1][nmsk][i]=xxw;
													yp[1][nmsk][i]=yyp;
													yw[1][nmsk][i]=yyw;
													if(tv>1)
													{ // todo 14:9-Fernseher beruecksichtigen
														// Pan & Scan
														xscal(&(xp[0][nmsk][i]),&(xw[0][nmsk][i]),xxp,xxw,sc23);
														yscal(&(yp[0][nmsk][i]),&(yw[0][nmsk][i]),yyp,yyw,sc23);
														// Vollbild
														xscal(&(xp[2][nmsk][i]),&(xw[2][nmsk][i]),xxp,xxw,sc23);
														yp[2][nmsk][i]=yyp;
														yw[2][nmsk][i]=yyw;
														// Pan & Scan 14:9
														xscal(&(xp[3][nmsk][i]),&(xw[3][nmsk][i]),xxp,xxw,sc131);
														yscal(&(yp[3][nmsk][i]),&(yw[3][nmsk][i]),yyp,yyw,sc132);
													}
													mc[nmsk].lpixel=cmc.lpixel;
													found=1;
													valid[nmsk]=1;
												}
												for(j=0; j<4 && cpt1; j++)
												{
													cpt1=strchr(cpt1+1,',');
												}
											}
											if(valid[nmsk])
											{
												nmsk++;
											}
										}
									}
								}
							}
						}
						fclose(fh);
					}
				}
			}
			if(mask)
			{
//printf("[logomask] pmode=%d,pmode43=%d\n",pmode,pmode43);
				for(m=0; m<nmsk; m++)
				{
					if(valid[m])
					{
						xxw=xw[pmode43][m][pmode];
						if(xxw>0)
						{
							xxp=xp[pmode43][m][pmode];
							yyp=yp[pmode43][m][pmode];
							yyw=yw[pmode43][m][pmode];
							cmc.lpixel=mc[m].lpixel;
							RenderBox(xxp, yyp, xxp+xxw, yyp+yyw, (test)?GRID:FILL, &cmc);
							for(i=0;i<=yyw;i++)
							{
								j=(yyp+i)*fix_screeninfo.line_length+(xxp<<2);
								if((j+(xxw<<2))<=fix_screeninfo.line_length*var_screeninfo.yres)
								{
									memcpy(lfb+j, lbb+j, xxw<<2);
								}
							}
						}
//printf("[logomask]mask%d: xxp=%d, xxw=%d, yyp=%d, yyw=%d\n",m+1,xxp,xxw,yyp,yyw);
					}
				}
			}
			if(++loop>5)
			{
				if(access("/tmp/.logomask_kill",0)!=-1)
				{
					loop=0;
				}
			}	
		}
	}

	make_color(TRANSP, &cmc);
	for(m=0; m<nmsk; m++)
	{
		if(valid[m])
		{
			xxp=xp[pmode43][m][pmode];
			xxw=xw[pmode43][m][pmode];
			yyp=yp[pmode43][m][pmode];
			yyw=yw[pmode43][m][pmode];
			RenderBox(xxp, yyp, xxp+abs(xxw), yyp+yyw, FILL, &cmc);
			for(i=0;i<=yyw;i++)
			{
				j=(yyp+i)*fix_screeninfo.line_length+(xxp<<2);
				if((j+(xxw<<2))<=fix_screeninfo.line_length*var_screeninfo.yres)
				{
					memcpy(lfb+j, lbb+j, xxw<<2);
				}
			}
		}
	}

	free(lbb);
	munmap(lfb, fix_screeninfo.smem_len);
	close(fb);
	remove("/tmp/.logomask_kill");
	remove("/tmp/logomask.*");
	return 0;
}

