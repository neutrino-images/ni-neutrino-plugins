#include <string.h>
#include <stdio.h>
#include <time.h>
#include <signal.h>
#include "msgbox.h"
#include "text.h"
#include "io.h"
#include "gfx.h"
#include "txtform.h" 

#define M_VERSION 1.12

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

void TrimString(char *strg);

// OSD stuff
static char menucoltxt[][25]={"Content_Selected_Text","Content_Selected","Content_Text","Content","Content_inactive_Text","Content_inactive","Head_Text","Head"};
static char spres[][5]={"","_crt","_lcd"};

char *line_buffer=NULL, *title=NULL;
int size=24, type=0, timeout=0, refresh=3, flash=0, selection=0, tbuttons=0, buttons=0, bpline=3, echo=0, absolute=0, mute=1, header=1, cyclic=1;
int rbutt[16],hide=0,radius=10;

// Misc
const char NOMEM[]="msgbox <Out of memory>\n";
char TMP_FILE[64]="/tmp/msgbox.tmp";
unsigned char *lfb = 0, *lbb = 0, *obb = 0, *hbb = 0, *ibb = 0;
unsigned char nstr[BUFSIZE]="";
unsigned char *trstr;
unsigned char sc[8]={'a','o','u','A','O','U','z','d'}, tc[8]={0xE4,0xF6,0xFC,0xC4,0xD6,0xDC,0xDF,0xB0};
unsigned char rc = ' ';
const char INST_FILE[]="/tmp/rc.locked";
int instance=0;

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
	if(pval)
	{
		FILE *fh;
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

static void quit_signal()
{
	put_instance(get_instance()-1);
	printf("msgbox Version %.2f killed\n",M_VERSION);
	exit(1);
}

int Read_Neutrino_Cfg(char *entry)
{
FILE *nfh;
int rv=-1;

	if((nfh=fopen(NCF_FILE,"r"))!=NULL)
	{
		char tstr [512]={0}, *cfptr=NULL;
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
char *pt1=strdup(sptr),*pt2,*pt3;

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
			butmsg[btn]=strdup(pt2);
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
int x1,y1,cut,rv=-1,btns=buttons,lbtns=(buttons>bpline)?bpline:buttons,blines=1+((btns-1)/lbtns);

	if(hide)
	{
		memcpy(lfb, hbb, fix_screeninfo.line_length*var_screeninfo.yres);
		return 0;
	}
	yo=40+((header)?FSIZE_MED*5/4:0);
	if(!buttonly)
	{
		memcpy(lbb, ibb, fix_screeninfo.line_length*var_screeninfo.yres);
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
				int itmp = 0,i;
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
				printf("msgbox <invalid Text-Format>\n");
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
				buttystart=psy+y1*dy;
			}
		}
		int bx,by,run=1,line=0,action=1;
		while(run)
		{
			//frame layout
			if(action)
			{
				if(!buttonly)
				{
					RenderBox(psx-20, psy-yo, psx+pxw+20, psy+pyw+myo, radius, CMH);
					RenderBox(psx-20+2, psy-yo+2, psx+pxw+20-2, psy+pyw+myo-2, radius, CMC);
					if(header)
					{
						RenderBox(psx-20, psy-yo+2-FSIZE_BIG/2, psx+pxw+20, psy-yo+FSIZE_BIG*3/4, radius, CMH);
						RenderString(title, psx, psy-yo+FSIZE_BIG/2, pxw, CENTER, FSIZE_BIG, CMHT);
					}
				}
				if(buttonly || !(rv=fh_txt_load(TMP_FILE, psx, pxw, psy, dy, size, line, &cut)))
				{
					if(type==1)
					{
						int i;
						for(i=0; i<btns; i++)
						{
							bx=i%lbtns;
							by=i/lbtns;
							RenderBox(buttxstart+bx*(buttsize+buttdx/2), buttystart+by*(butty+buttdy/2), buttxstart+(bx+1)*buttsize+bx*(buttdx/2), buttystart+by*(butty+buttdy/2)+butty, radius, YELLOW);
							RenderBox(buttxstart+bx*(buttsize+buttdx/2)+2, buttystart+by*(butty+buttdy/2)+2, buttxstart+(bx+1)*buttsize+bx*(buttdx/2)-2, buttystart+by*(butty+buttdy/2)+butty-2, radius, ((by*bpline+bx)==(selection-1))?CMCS:CMC);
							RenderString(butmsg[i], buttxstart+bx*(buttsize+buttdx/2), buttystart+by*(butty+buttdy/2)+butty-7, buttsize, CENTER, 26, (i==(selection-1))?CMCST:CMCIT);
						}
					}
					memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
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
			snprintf(TMP_FILE,sizeof(TMP_FILE),"%s",msg);
		}
		else
		{
			rv=1;
		}
	}
	else
	{
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
	printf("msgbox Version %.2f\n",M_VERSION);
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
int index=0,tv=0,found=0, spr=0;
int dloop=1, rcc=-1, cupd=0;
char rstr[BUFSIZE]={0}, *rptr=NULL, *aptr=NULL;
time_t tm1=0,tm2=0;
//clock_t tk1=0;
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
				printf("msgbox Version %.2f\n",M_VERSION);
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
						title=strdup(rptr);
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
					printf("msgbox <param error: %s>\n",aptr);
					return 0;
					break;
				
				case 2:
					printf("msgbox <unknown command: %s>\n\n",aptr);
					ShowUsage();
					return 0;
					break;
			}
		}

		FSIZE_BIG=(FSIZE_MED*5)/4;
		FSIZE_SMALL=(FSIZE_MED*4)/5;
		TABULATOR=2*FSIZE_MED;
		size=FSIZE_MED;
		
		if(!echo)
		{
			printf("\nmsgbox  Message-Box Version %.2f\n",M_VERSION);
		}
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
				printf("msgbox <param error: default=%d>\n",selection);
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


		for(index=CMCST; index<=CMH; index++)
		{
			sprintf(rstr,"menu_%s_alpha",menucoltxt[index]);
			if((tv=Read_Neutrino_Cfg(rstr))>=0)
				tr[index]=255-(float)tv*2.55;

			sprintf(rstr,"menu_%s_blue",menucoltxt[index]);
			if((tv=Read_Neutrino_Cfg(rstr))>=0)
				bl[index]=(float)tv*2.55;

			sprintf(rstr,"menu_%s_green",menucoltxt[index]);
			if((tv=Read_Neutrino_Cfg(rstr))>=0)
				gn[index]=(float)tv*2.55;

			sprintf(rstr,"menu_%s_red",menucoltxt[index]);
			if((tv=Read_Neutrino_Cfg(rstr))>=0)
				rd[index]=(float)tv*2.55;
		}

		if(Read_Neutrino_Cfg("rounded_corners")>0)
			radius=10;
		else
			radius=0;

		fb = open(FB_DEVICE, O_RDWR);
		if(fb == -1)
		{
			perror("msgbox <open framebuffer device>");
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
			perror("msgbox <FBIOGET_FSCREENINFO>\n");
			return -1;
		}
		if(ioctl(fb, FBIOGET_VSCREENINFO, &var_screeninfo) == -1)
		{
			perror("msgbox <FBIOGET_VSCREENINFO>\n");
			return -1;
		}
		if(!(lfb = (unsigned char*)mmap(0, fix_screeninfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fb, 0)))
		{
			perror("msgbox <mapping of Framebuffer>\n");
			return -1;
		}
		
	//init fontlibrary

		if((error = FT_Init_FreeType(&library)))
		{
			printf("msgbox <FT_Init_FreeType failed with Errorcode 0x%.2X>", error);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_Manager_New(library, 1, 2, 0, &MyFaceRequester, NULL, &manager)))
		{
			printf("msgbox <FTC_Manager_New failed with Errorcode 0x%.2X>\n", error);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_SBitCache_New(manager, &cache)))
		{
			printf("msgbox <FTC_SBitCache_New failed with Errorcode 0x%.2X>\n", error);
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_Manager_LookupFace(manager, FONT, &face)))
		{
			if((error = FTC_Manager_LookupFace(manager, FONT2, &face)))
			{
				printf("msgbox <FTC_Manager_LookupFace failed with Errorcode 0x%.2X>\n", error);
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

		desc.flags = FT_LOAD_MONOCHROME;

	//init backbuffer

		if(!(lbb = malloc(fix_screeninfo.line_length*var_screeninfo.yres)))
		{
			perror("msgbox <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if(!(obb = malloc(fix_screeninfo.line_length*var_screeninfo.yres)))
		{
			perror("msgbox <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			free(lbb);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if(!(hbb = malloc(fix_screeninfo.line_length*var_screeninfo.yres)))
		{
			perror("msgbox <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			free(lbb);
			free(obb);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if(!(ibb = malloc(fix_screeninfo.line_length*var_screeninfo.yres)))
		{
			perror("msgbox <allocating of Backbuffer>\n");
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
			memcpy(ibb, lfb, fix_screeninfo.line_length*var_screeninfo.yres);
		}
		else
		{
			memset(ibb, TRANSP, fix_screeninfo.line_length*var_screeninfo.yres);
		}
		if(mute==2)
		{
			memcpy(hbb, lfb, fix_screeninfo.line_length*var_screeninfo.yres);
		}
		else
		{
			memset(hbb, TRANSP, fix_screeninfo.line_length*var_screeninfo.yres);
		}
		if(refresh & 2)
		{
			memcpy(obb, lfb, fix_screeninfo.line_length*var_screeninfo.yres);
		}
		else
		{
			memset(obb, TRANSP, fix_screeninfo.line_length*var_screeninfo.yres);
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
		rcc=GetRCCode();
		if(rcc!=-1)
		{
			time(&tm1);
		}
		else
		{
			if(++cupd>100)
			{
				if(cyclic)
				{
					show_txt(0);
					cupd=0;
				}
			}
			usleep(10000L);
		}
		if(mute && rcc==KEY_MUTE)
		{
			hide^=1;
			show_txt(0);
			usleep(500000L);
			while(GetRCCode()!=-1);
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

	memcpy(lfb, obb, fix_screeninfo.line_length*var_screeninfo.yres);
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

