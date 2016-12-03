#include <string.h>
#include <stdio.h>
#include <time.h>
#include <signal.h>

#include "current.h"

#include "text.h"
#include "io.h"
#include "gfx.h"
#include "txtform.h" 

#define M_VERSION 1.24

#define NCF_FILE 	"/var/tuxbox/config/neutrino.conf"
#define HDF_FILE	"/tmp/.msgbox_hidden"

//#define FONT "/usr/share/fonts/md_khmurabi_10.ttf"
#define FONT2 "/share/fonts/pakenham.ttf"
// if font is not in usual place, we look here:
#define FONT "/share/fonts/neutrino.ttf"

//					   CMCST,   CMCS,  CMCT,    CMC,    CMCIT,  CMCI,   CMHT,   CMH
//					   WHITE,   BLUE0, TRANSP,  CMS,    ORANGE, GREEN,  YELLOW, RED

unsigned char bl[] = {	0x00, 	0x00, 	0xFF, 	0x80, 	0xFF, 	0x80, 	0x00, 	0x80,
						0xFF, 	0xFF, 	0x00, 	0xFF, 	0x00, 	0x00, 	0x00, 	0x00};
unsigned char gn[] = {	0x00, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0x00, 	0xC0, 	0x00,
						0xFF, 	0x80, 	0x00, 	0x80, 	0xC0, 	0xFF, 	0xFF, 	0x00};
unsigned char rd[] = {	0x00, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0x00,
						0xFF, 	0x00, 	0x00, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0xFF};
unsigned char tr[] = {	0xFF, 	0xFF, 	0xFF,  	0xA0,  	0xFF,  	0xA0,  	0xFF,  	0xFF,
						0xFF, 	0xFF, 	0x00,  	0xFF,  	0xFF,  	0xFF,  	0xFF,  	0xFF};

uint32_t bgra[20];

void TrimString(char *strg);

// OSD stuff
static char menucoltxt[][25]={"Content_Selected_Text","Content_Selected","Content_Text","Content","Content_inactive_Text","Content_inactive","Head_Text","Head"};
static char spres[][5]={"","_crt","_lcd"};

char *line_buffer=NULL, *title=NULL;
int size=24, type=0, timeout=0, refresh=3, flash=0, selection=0, tbuttons=0, buttons=0, bpline=3, echo=0, absolute=0, mute=1, header=1, cyclic=1;
char *butmsg[16]={0};
int rbutt[16],hide=0,radius=11;

// Misc
const char NOMEM[]="MsgBox <Out of memory>\n";
char TMP_FILE[64]="/tmp/msgbox.tmp";
uint32_t *lfb = NULL, *lbb = NULL, *obb = NULL, *hbb = NULL, *ibb = NULL;
char nstr[BUFSIZE]={0};
char *trstr=NULL;
const char INST_FILE[]="/tmp/rc.locked";
int instance=0;
int stride;

int get_instance(void)
{
FILE *fh;
int rval=0;

	if((fh=fopen(INST_FILE,"r"))!=NULL)
	{
		rval=fgetc(fh);
		fclose(fh);
	}
	return rval;
}

void put_instance(int pval)
{
FILE *fh;

	if(pval)
	{
		if((fh=fopen(INST_FILE,"w"))!=NULL)
		{
			fputc(pval,fh);
			fclose(fh);
		}
	}
	else
	{
		remove(INST_FILE);
	}
}

static void quit_signal(int sig)
{
	put_instance(get_instance()-1);
	printf("%s Version %.2f killed, signal %d\n", __plugin__, M_VERSION, sig);
	exit(1);
}

int Read_Neutrino_Cfg(char *entry)
{
FILE *nfh;
char tstr [512]={0}, *cfptr=NULL;
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
				if(strstr(cfptr,"true")!=NULL)
				{
					rv=1;
				}
				else
				{
					if(strstr(cfptr,"false")!=NULL)
					{
						rv=0;
					}
					else
					{
						rv=-1;
					}
				}
			}
//			printf("%s\n%s=%s -> %d\n",tstr,entry,cfptr,rv);
		}
		fclose(nfh);
	}
	return rv;
}

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

int GetSelection(char *sptr)
{
int rv=0,btn=0,run=1;
char *pt1=strdup(sptr),*pt2=NULL,*pt3=NULL;

	pt2=pt1;
	while(*pt2 && run && btn<MAX_BUTTONS)
	{
		if((pt3=strchr(pt2,','))!=NULL)
		{
			*pt3=0;
			++pt3;
		}
		else
		{
			run=0;
		}
		++tbuttons;
		if(strlen(pt2))
		{	
			rbutt[btn]=tbuttons;
			size_t l = strlen(pt2);
			char *t = (char *)alloca(l * 4 + 1);
			memcpy(t, pt2, l + 1);
			TranslateString(t, l * 4);
			butmsg[btn]=strdup(t);
			CatchTabs(butmsg[btn++]);
		}
		if(run)
		{
			pt2=pt3;
		}
	}
	if(!btn)
	{
		rv=1;
	}
	else
	{
		buttons=btn;
	}
	free(pt1);
	return rv;
}

static int yo=80,dy;
static int psx, psy, pxw, pyw, myo=0, buttx=80, butty=30, buttdx=20, buttdy=10, buttsize=0, buttxstart=0, buttystart=0;

int show_txt(int buttonly)
{
FILE *tfh;
int i,bx,by,x1,y1,rv=-1,run=1,line=0,action=1,cut,itmp,btns=buttons,lbtns=(buttons>bpline)?bpline:buttons,blines=1+((btns-1)/lbtns);

	if(hide)
	{
		memcpy(lfb, hbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
		return 0;
	}

	yo=20+((header)?FSIZE_MED*5/4:0);
	int moffs=yo*3/4+6;
	if(!buttonly)
	{
		memcpy(lbb, ibb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
	}
	if((tfh=fopen(TMP_FILE,"r"))!=NULL)
	{
		fclose(tfh);
		if(!buttonly)
		{
			if(type!=1)
			{
				btns=0;
				myo=0;
			}	
		
			pxw=GetStringLen(sx,title,FSIZE_BIG)+10;
			if(type==1)
			{
				myo=blines*(butty+buttdy);
				for(i=0; i<btns; i++)
				{
					itmp=GetStringLen(sx,butmsg[i], 26)+10;
					if(itmp>buttx)
					{
						buttx=itmp;
					}
				}
			}
			buttsize=buttx;
			
			if(fh_txt_getsize(TMP_FILE, &x1, &y1, size, &cut))
			{
				printf(__plugin__ " <invalid Text-Format>\n");
				return -1;
			}
			x1+=10;

			dy=size;
			if(pxw<x1)
			{
				pxw=x1;
			}
			if(pxw<(lbtns*buttx+lbtns*buttdx))
			{
				pxw=(lbtns*buttx+lbtns*buttdx);
			}
			if(pxw>((ex-sx)-2*buttdx))
			{
				pxw=ex-sx-2*buttdx;
			}
			psx=((ex-sx)/2-pxw/2);
			pyw=y1*dy/*-myo*/;
			if(pyw>((ey-sy)-yo-myo))
			{
				pyw=((ey-sy)-yo-myo);
			}
			psy=((ey-sy)/2-(pyw+myo-yo)/2);
			if(btns)
			{
				buttxstart=psx+pxw/2-(((double)lbtns*(double)buttsize+(((lbtns>2)&&(lbtns&1))?((double)buttdx):0.0))/2.0);
				buttystart=psy+y1*dy+15;
			}
		}

		while(run)
		{
			//frame layout
			if(action)
			{
				if(!buttonly)
				{
					RenderBox(psx-20, psy-yo, psx+pxw+20, psy+pyw+myo+15, radius, CMH);
					RenderBox(psx-20+2, psy-yo+2, psx+pxw+20-2, psy+pyw+myo+15-2, radius, CMC);
					if(header)
					{
						RenderBox(psx-20, psy-yo+2-FSIZE_BIG/2, psx+pxw+20, psy-yo+FSIZE_BIG*3/4, radius, CMH);
						RenderString(title, psx, psy-moffs+FSIZE_BIG/2, pxw, CENTER, FSIZE_BIG, CMHT);
					}
				}
				if(buttonly || !(rv=fh_txt_load(TMP_FILE, psx, pxw, psy+20, dy, size, line, &cut)))
				{
					if(type==1)
					{
						for(i=0; i<btns; i++)
						{
							bx=i%lbtns;
							by=i/lbtns;
							RenderBox(buttxstart+bx*(buttsize+buttdx/2), buttystart+by*(butty+buttdy/2), buttxstart+(bx+1)*buttsize+bx*(buttdx/2), buttystart+by*(butty+buttdy/2)+butty, radius, YELLOW);
							RenderBox(buttxstart+bx*(buttsize+buttdx/2)+2, buttystart+by*(butty+buttdy/2)+2, buttxstart+(bx+1)*buttsize+bx*(buttdx/2)-2, buttystart+by*(butty+buttdy/2)+butty-2, radius, ((by*bpline+bx)==(selection-1))?CMCS:CMC);
							RenderString(butmsg[i], buttxstart+bx*(buttsize+buttdx/2), buttystart+by*(butty+buttdy/2)+butty, buttsize, CENTER, 26, (i==(selection-1))?CMCST:CMCIT);
						}
					}
					memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
				}
			}
			run=0;
		}
	}
	return (rv)?-1:0;	
}

int Transform_Msg(char *msg)
{
int rv=0;
FILE *xfh;

	if(*msg=='/')
	{
		if((xfh=fopen(msg,"r"))!=NULL)
		{
			fclose(xfh);
			strcpy(TMP_FILE,msg);
		}
		else
		{
			rv=1;
		}
	}
	else
	{
		size_t l = strlen(msg);
		char *t = (char *)alloca(l * 4 + 1);
		memcpy(t, msg, l + 1);
		TranslateString(t, l * 4);
		msg = t;

		if((xfh=fopen(TMP_FILE,"w"))!=NULL)
		{
			while(*msg)
			{
				if(*msg!='~')
				{
					fputc(*msg,xfh);
				}
				else
				{
					if(*(msg+1)=='n')
					{
						fputc(0x0A,xfh);
						++msg;
					}
					else
					{
						fputc(*msg,xfh);
					}
				}
				msg++;
			}
			fclose(xfh);
		}
	}
	return rv;
}

void ShowUsage(void)
{
	printf("MsgBox Version %.2f\n",M_VERSION);
	printf("\nSyntax:\n");
	printf("    msgbox msg=\"text to show\" [Options]\n");
	printf("    msgbox msg=filename [Options]\n");
	printf("    msgbox popup=\"text to show\" [Options]\n");
	printf("    msgbox popup=filename [Options]\n\n");
	printf("Options:\n");
	printf("    -v || --version       : only print version and return\n");
	printf("    title=\"Window-Title\"  : specify title of window\n");
	printf("    size=nn               : set fontsize\n");
	printf("    timeout=nn            : set autoclose-timeout\n");
	printf("    refresh=n             : n=1..3, see readme.txt\n");
	printf("    select=\"Button1,..\"   : Labels of up to 16 Buttons, see readme.txt\n");
	printf("    absolute=n            : n=0/1 return relative/absolute button number (default is 0)\n");
	printf("    order=n               : maximal buttons per line (default is 3)\n");
	printf("    default=n             : n=1..buttons, initially selected button, see readme.txt\n");
	printf("    echo=n                : n=0/1 print the button-label to console on return (default is 0)\n");
	printf("    hide=n                : n=0..2, function of mute-button, see readme.txt (default is 1)\n");
	printf("    cyclic=n              : n=0/1, cyclic screen refresh (default is 1)\n");

}
/******************************************************************************
 * MsgBox Main
 ******************************************************************************/

int main (int argc, char **argv)
{
int ix,tv,found=0, spr;
int dloop=1, rcc=-1;
char rstr[BUFSIZE]={0}, *rptr=NULL, *aptr=NULL;
time_t tm1,tm2;
FILE *fh;

		if(argc<2)
		{
			ShowUsage();
			return 0;
		}
		dloop=0;
		for(tv=1; !dloop && tv<argc; tv++)
		{
			aptr=argv[tv];
			if(!strcmp(aptr,"-v") || !strcmp(aptr,"--version"))
			{
				printf("%s Version %.2f\n", __plugin__, M_VERSION);
				return 0;
			}
			if((rptr=strchr(aptr,'='))!=NULL)
			{
				rptr++;
				if(strstr(aptr,"size=")!=NULL)
				{
					if(sscanf(rptr,"%d",&FSIZE_MED)!=1)
					{
						dloop=1;
					}
				}
				else
				{
					if(strstr(aptr,"title=")!=NULL)
					{
						size_t l = strlen(rptr);
						char *t = (char *)alloca(l * 4 + 1);
						memcpy(t, rptr, l + 1);
						TranslateString(t, l * 4);
						title = strdup(t);
						CatchTabs(title);

						if(strcmp(title,"none")==0)
						{
							header=0;
						}
					}
					else
					{
						if(strstr(aptr,"timeout=")!=NULL)
						{
							if(sscanf(rptr,"%d",&timeout)!=1)
							{
								dloop=1;
							}
						}
						else
						{
							if(strstr(aptr,"msg=")!=NULL)
							{
								dloop=Transform_Msg(rptr);
								if(timeout==0)
								{
										if((timeout=Read_Neutrino_Cfg("timing.epg"))<0)
											timeout=300;
								}
								type=1;
							}
							else
							{
								if(strstr(aptr,"popup=")!=NULL)
								{
									dloop=Transform_Msg(rptr);
									if(timeout==0)
									{
										if((timeout=Read_Neutrino_Cfg("timing.infobar"))<0)
											timeout=6;
									}
									type=2;
								}
								else
								{
									if(strstr(aptr,"refresh=")!=NULL)
									{
										if(sscanf(rptr,"%d",&refresh)!=1)
										{
											dloop=1;
										}
									}
									else
									{
										if(strstr(aptr,"select=")!=NULL)
										{
											dloop=GetSelection(rptr);
										}
										else
										{
											if(strstr(aptr,"default=")!=NULL)
											{
												if((sscanf(rptr,"%d",&selection)!=1) || selection<1)
												{
													dloop=1;
												}
											}
											else
											{
												if(strstr(aptr,"order=")!=NULL)
												{
													if(sscanf(rptr,"%d",&bpline)!=1)
													{
														dloop=1;
													}
												}
												else
												{
													if(strstr(aptr,"echo=")!=NULL)
													{
														if(sscanf(rptr,"%d",&echo)!=1)
														{
															dloop=1;
														}
													}
													else
													{
														if(strstr(aptr,"absolute=")!=NULL)
														{
															if(sscanf(rptr,"%d",&absolute)!=1)
															{
																dloop=1;
															}
														}
														else
														{
															if(strstr(aptr,"hide=")!=NULL)
															{
																if(sscanf(rptr,"%d",&mute)!=1)
																{
																	dloop=1;
																}
															}
															else
															{
																if(strstr(aptr,"cyclic=")!=NULL)
																{
																	if(sscanf(rptr,"%d",&cyclic)!=1)
																	{
																		dloop=1;
																	}
																}
																else
																{
																dloop=2;
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
			switch (dloop)
			{
				case 1:
					printf("%s <param error: %s>\n", __plugin__, aptr);
					return 0;
					break;
				
				case 2:
					printf("%s <unknown command: %s>\n\n", __plugin__, aptr);
					ShowUsage();
					return 0;
					break;
			}
		}

		FSIZE_BIG=(FSIZE_MED*5)/4;
		FSIZE_SMALL=(FSIZE_MED*4)/5;
		TABULATOR=2*FSIZE_MED;
		size=FSIZE_MED;
		
		/*
		if(!echo)
		{
			printf("\nMsgBox Version %.2f\n", M_VERSION);
		}
		*/
		if(!buttons)
		{
			butmsg[0]=strdup("OK");
			buttons=1;
		}
		if(!absolute)
		{
			for(tv=0; tv<buttons; tv++)
			{
				rbutt[tv]=tv+1;
			}
		}
		if(selection)
		{	
			for(tv=0; tv<buttons && !found; tv++)		
			{
				if(rbutt[tv]==selection)
				{
					selection=tv+1;
					found=1;
				}
			}
			if(!found)
			{
				printf("%s <param error: default=%d>\n", __plugin__, selection);
				return 0;
			}
		}
		else
		{
			for(tv=0; tv<buttons && !selection; tv++)
			{
				if(strlen(butmsg[tv]))
				{
					selection=tv+1;
				}
			}
		}
		if(!title)
		{
			title=strdup("Information");
		}
		if((line_buffer=calloc(BUFSIZE+1, sizeof(char)))==NULL)
		{
			printf(NOMEM);
			return -1;
		}
	
		spr=Read_Neutrino_Cfg("screen_preset")+1;
		sprintf(line_buffer,"screen_StartX%s",spres[spr]);
		if((sx=Read_Neutrino_Cfg(line_buffer))<0)
			sx=100;

		sprintf(line_buffer,"screen_EndX%s",spres[spr]);
		if((ex=Read_Neutrino_Cfg(line_buffer))<0)
			ex=1180;

		sprintf(line_buffer,"screen_StartY%s",spres[spr]);
		if((sy=Read_Neutrino_Cfg(line_buffer))<0)
			sy=100;

		sprintf(line_buffer,"screen_EndY%s",spres[spr]);
		if((ey=Read_Neutrino_Cfg(line_buffer))<0)
			ey=620;


		for(ix=CMCST; ix<=CMH; ix++)
		{
			sprintf(rstr,"menu_%s_alpha",menucoltxt[ix]);
			if((tv=Read_Neutrino_Cfg(rstr))>=0)
				tr[ix]=255-(float)tv*2.55;

			sprintf(rstr,"menu_%s_blue",menucoltxt[ix]);
			if((tv=Read_Neutrino_Cfg(rstr))>=0)
				bl[ix]=(float)tv*2.55;

			sprintf(rstr,"menu_%s_green",menucoltxt[ix]);
			if((tv=Read_Neutrino_Cfg(rstr))>=0)
				gn[ix]=(float)tv*2.55;

			sprintf(rstr,"menu_%s_red",menucoltxt[ix]);
			if((tv=Read_Neutrino_Cfg(rstr))>=0)
				rd[ix]=(float)tv*2.55;
		}
		for (ix = 0; ix <= RED; ix++)
			bgra[ix] = (tr[ix] << 24) | (rd[ix] << 16) | (gn[ix] << 8) | bl[ix];


		if(Read_Neutrino_Cfg("rounded_corners")>0)
			radius=11;
		else
			radius=0;

		fb = open(FB_DEVICE, O_RDWR);
		if(fb == -1)
		{
			perror(__plugin__ " <open framebuffer device>");
			exit(1);
		}

		InitRC();
		
		if((trstr=malloc(BUFSIZE))==NULL)
		{
			printf(NOMEM);
			return -1;
		}

	//init framebuffer

		if(ioctl(fb, FBIOGET_FSCREENINFO, &fix_screeninfo) == -1)
		{
			perror(__plugin__ " <FBIOGET_FSCREENINFO>\n");
			return -1;
		}
		if(ioctl(fb, FBIOGET_VSCREENINFO, &var_screeninfo) == -1)
		{
			perror(__plugin__ " <FBIOGET_VSCREENINFO>\n");
			return -1;
		}

		if(!(lfb = (uint32_t*)mmap(0, fix_screeninfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fb, 0)))
		{
			perror(__plugin__ " <mapping of Framebuffer>\n");
			return -1;
		}
		
	//init fontlibrary

		if((error = FT_Init_FreeType(&library)))
		{
			printf("%s <FT_Init_FreeType failed with Errorcode 0x%.2X>", __plugin__, error);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_Manager_New(library, 1, 2, 0, &MyFaceRequester, NULL, &manager)))
		{
			printf("%s <FTC_Manager_New failed with Errorcode 0x%.2X>\n", __plugin__, error);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_SBitCache_New(manager, &cache)))
		{
			printf("%s <FTC_SBitCache_New failed with Errorcode 0x%.2X>\n", __plugin__, error);
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_Manager_LookupFace(manager, FONT, &face)))
		{
			if((error = FTC_Manager_LookupFace(manager, FONT2, &face)))
			{
				printf("%s <FTC_Manager_LookupFace failed with Errorcode 0x%.2X>\n", __plugin__, error);
				FTC_Manager_Done(manager);
				FT_Done_FreeType(library);
				munmap(lfb, fix_screeninfo.smem_len);
				return 2;
			}
			else
				desc.face_id = FONT2;
		}
		else
			desc.face_id = FONT;
		
		use_kerning = FT_HAS_KERNING(face);

		desc.flags = FT_LOAD_RENDER | FT_LOAD_FORCE_AUTOHINT;

	//init backbuffer

		if(!(lbb = malloc(var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t))))
		{
			perror(__plugin__ " <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}
		stride = fix_screeninfo.line_length/sizeof(uint32_t);

		if(!(obb = malloc(var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t))))
		{
			perror(__plugin__ " <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			free(lbb);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}
		if(!(hbb = malloc(var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t))))
		{
			perror(__plugin__ " <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			free(lbb);
			free(obb);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}
		if(!(ibb = malloc(var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t))))
		{
			perror(__plugin__ " <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			free(lbb);
			free(obb);
			free(hbb);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if(refresh & 1)
		{
			memcpy(ibb, lbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
		}
		else
		{
			memset(ibb, TRANSP, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
		}
		if(mute==2)
		{
			memcpy(hbb, lbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
		}
		else
		{
			memset(hbb, TRANSP, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
		}
		if(refresh & 2)
		{
			memcpy(obb, lbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
		}
		else
		{
			memset(obb, TRANSP, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
		}

		startx = sx;
		starty = sy;


	/* Set up signal handlers. */
	signal(SIGINT, quit_signal);
	signal(SIGTERM, quit_signal);
	signal(SIGQUIT, quit_signal);

	put_instance(instance=get_instance()+1);

  	show_txt(0);	
	
	time(&tm1);
	tm2=tm1;
	
	//main loop
	while((rcc!=KEY_EXIT) && (rcc!=KEY_OK) && ((timeout==-1)||((tm2-tm1)<timeout)))
	{
		rcc=GetRCCode(1000);
		if(rcc!=-1)
		{
			time(&tm1);
		}
		else
		{
			if(cyclic)
				show_txt(0);
#if 0
			if(++cupd>100)
			{
				if(cyclic)
				{
					show_txt(0);
					cupd=0;
				}
			}
			usleep(10000L);
#endif
		}
		if(mute && rcc==KEY_MUTE)
		{
			hide^=1;
			show_txt(0);

			while(GetRCCode(300)!=-1);
			if(hide)
			{
				if((fh=fopen(HDF_FILE,"w"))!=NULL)
				{
					fprintf(fh,"hidden");
					fclose(fh);
				}
			}
			else
			{
				remove(HDF_FILE);
			}
		}
		if((!hide) && (rcc!=KEY_EXIT) && (rcc!=KEY_OK))
		{
			switch(rcc)
			{
				case KEY_LEFT:
					if(!hide && (--selection<1))
					{
						selection=buttons;
					}
					show_txt(1);
				break;
				
				case KEY_RIGHT:
					if(!hide && (++selection>buttons))
					{
						selection=1;
					}
					show_txt(1);
				break;
				
				case KEY_UP:
					if(!hide && ((selection-=bpline)<1))
					{
						selection=1;
					}
					show_txt(1);
				break;
				
				case KEY_DOWN:
					if(!hide && ((selection+=bpline)>buttons))
					{
						selection=buttons;
					}
					show_txt(1);
				break;

				default:
					flash^=1;
				break;
			}
		}
		time(&tm2);
		if(hide)
		{
			rcc=-1;
		}
	}
	if((type!=1) || (rcc!=KEY_OK))
	{
		selection=0;
	}
	
	
	//cleanup
	memcpy(lfb, obb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
	munmap(lfb, fix_screeninfo.smem_len);
	close(fb);
	free(lbb);

	put_instance(get_instance()-1);

	if(echo && selection>0)
	{
		printf("%s\n",butmsg[selection-1]);
	}

	for(tv=0; tv<buttons; tv++)
	{
		free(butmsg[tv]);
	}
	free(trstr);
	free(line_buffer);
	free(title);

	FTC_Manager_Done(manager);
	FT_Done_FreeType(library);

	free(obb);
	free(hbb);
	free(ibb);

	CloseRC();

	remove("/tmp/msgbox.tmp");

	if(selection)
	{
		return rbutt[selection-1];
	}
	return 0;
}

