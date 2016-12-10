#include <string.h>
#include <stdio.h>
#include <time.h>
#include <signal.h>
#include "input.h"
#include "text.h"
#include "io.h"
#include "gfx.h"
#include "inputd.h"

#define NCF_FILE 	"/var/tuxbox/config/neutrino.conf"
#define BUFSIZE 	1024
#define I_VERSION	1.11

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

char *buffer=NULL;

//static void ShowInfo(void);

// Misc
char NOMEM[]="input <Out of memory>\n";
char TMP_FILE[]="/tmp/input.tmp";
unsigned char *lfb = 0, *lbb = 0, *obb = 0;
unsigned char nstr[512]="",rstr[512]="";
unsigned char *trstr;
unsigned char rc,sc[8]={'a','o','u','A','O','U','z','d'}, tc[8]={0xE4,0xF6,0xFC,0xC4,0xD6,0xDC,0xDF,0xB0};
int radius=10;

static void quit_signal(int sig)
{
	char *txt=NULL;
	switch (sig)
	{
		case SIGINT:  txt=strdup("SIGINT");  break;
		case SIGTERM: txt=strdup("SIGTERM"); break;
		case SIGQUIT: txt=strdup("SIGQUIT"); break;
		case SIGSEGV: txt=strdup("SIGSEGV"); break;
		default:
			txt=strdup("UNKNOWN"); break;
	}

	printf("input Version %.2f killed, signal %s(%d)\n", I_VERSION, txt, sig);
	put_instance(get_instance()-1);
	free(txt);
	exit(1);
}

int Read_Neutrino_Cfg(char *entry)
{
FILE *nfh;
char tstr [512], *cfptr=NULL;
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

int Transform_Msg(char *msg)
{
int found=0,i;
char *sptr=msg, *tptr=msg;

	while(*sptr)
	{
		if(*sptr!='~')
		{
			*tptr=*sptr;
		}
		else
		{
			rc=*(sptr+1);
			found=0;
			for(i=0; i<sizeof(sc) && !found; i++)
			{
				if(rc==sc[i])
				{
					rc=tc[i];
					found=1;
				}
			}
			if(found)
			{
				*tptr=rc;
				++sptr;
			}
			else
			{
				*tptr=*sptr;
			}
		}
		++sptr;
		++tptr;
	}
	*tptr=0;
	return strlen(msg);
}

void ShowUsage(void)
{
	printf("\ninput Version %.2f Syntax:\n", I_VERSION);
	printf("    input l=\"layout\" [Options]\n\n");
	printf("    layout                : format-string\n");
	printf("                            #=numeric @=alphanumeric\n");
	printf("Options:\n");
	printf("    t=\"Window-Title\"      : specify title of window [default \"Eingabe\"]\n");
	printf("    d=\"Defaults\"          : default values\n");
	printf("    k=1/0                 : show the keyboard layout [default 0]\n");
	printf("    f=1/0                 : show frame around edit fields [default 1]\n");
	printf("    m=1/0                 : mask numeric inputs (for PIN entrys) [default 0]\n");
	printf("    h=1/0                 : return on help key (for PIN changes) [default 0]\n");
	printf("    c=n                   : colums per line, n=1..25 [default 25]\n");
	printf("    o=n                   : menu timeout (0=no timeout) [default 0]\n");

}
/******************************************************************************
 * input Main
 ******************************************************************************/

int main (int argc, char **argv)
{
int tv,cols=25,debounce=25,tmo=0,index, spr;
char ttl[]="Eingabe";
int dloop=1,keys=0,frame=1,mask=0,bhelp=0;
char *title=NULL, *format=NULL, *defstr=NULL, *aptr, *rptr; 
unsigned int alpha;
//FILE *fh;

		if(argc==1)
		{
			ShowUsage();
			return 0;
		}

		dloop=0;
		for(tv=1; !dloop && tv<argc; tv++)
		{
			aptr=argv[tv];
			if((rptr=strchr(aptr,'='))!=NULL)
			{
				rptr++;
				if(strstr(aptr,"l=")!=NULL)
				{
					format=rptr;
					dloop=Transform_Msg(format)==0;
				}
				else
				{
					if(strstr(aptr,"t=")!=NULL)
					{
						title=rptr;
						dloop=Transform_Msg(title)==0;
					}
					else
					{
						if(strstr(aptr,"d=")!=NULL)
						{
							defstr=rptr;
							dloop=Transform_Msg(defstr)==0;
						}
						else
						{
							if(strstr(aptr,"m=")!=NULL)
							{
								if(sscanf(rptr,"%d",&mask)!=1)
								{
									dloop=1;
								}
							}
							else
							{
								if(strstr(aptr,"f=")!=NULL)
								{
									if(sscanf(rptr,"%d",&frame)!=1)
									{
										dloop=1;
									}
								}
								else
								{
									if(strstr(aptr,"k=")!=NULL)
									{
										if(sscanf(rptr,"%d",&keys)!=1)
										{
											dloop=1;
										}
									}
									else
									{
										if(strstr(aptr,"h=")!=NULL)
										{
											if(sscanf(rptr,"%d",&bhelp)!=1)
											{
												dloop=1;
											}
										}
										else
										{
											if(strstr(aptr,"c=")!=NULL)
											{
												if(sscanf(rptr,"%d",&cols)!=1)
												{
													dloop=1;
												}
											}
											else
											{
												if(strstr(aptr,"o=")!=NULL)
												{
													if(sscanf(rptr,"%d",&tmo)!=1)
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
			switch (dloop)
			{
				case 1:
					printf("input <param error: %s>\n",aptr);
					return 0;
					break;
				
				case 2:
					printf("input <unknown command: %s>\n\n",aptr);
					ShowUsage();
					return 0;
					break;
			}
		}
		if(!format)
		{
			printf("input <missing format string>\n");
			return 0;
    	}
		if(!title)
		{
			title=ttl;
		}

		if((buffer=calloc(BUFSIZE+1, sizeof(char)))==NULL)
		{
			printf(NOMEM);
			return 0;
		}

		spr=Read_Neutrino_Cfg("screen_preset")+1;
		sprintf(buffer,"screen_StartX%s",spres[spr]);
		if((sx=Read_Neutrino_Cfg(buffer))<0)
			sx=100;

		sprintf(buffer,"screen_EndX%s",spres[spr]);
		if((ex=Read_Neutrino_Cfg(buffer))<0)
			ex=1180;

		sprintf(buffer,"screen_StartY%s",spres[spr]);
		if((sy=Read_Neutrino_Cfg(buffer))<0)
			sy=100;

		sprintf(buffer,"screen_EndY%s",spres[spr]);
		if((ey=Read_Neutrino_Cfg(buffer))<0)
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
			perror("input <open framebuffer device>");
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
			perror("input <FBIOGET_FSCREENINFO>\n");
			return -1;
		}
		if(ioctl(fb, FBIOGET_VSCREENINFO, &var_screeninfo) == -1)
		{
			perror("input <FBIOGET_VSCREENINFO>\n");
			return -1;
		}
		if(!(lfb = (unsigned char*)mmap(0, fix_screeninfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fb, 0)))
		{
			perror("input <mapping of Framebuffer>\n");
			return -1;
		}

	//init fontlibrary

		if((error = FT_Init_FreeType(&library)))
		{
			printf("input <FT_Init_FreeType failed with Errorcode 0x%.2X>", error);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_Manager_New(library, 1, 2, 0, &MyFaceRequester, NULL, &manager)))
		{
			printf("input <FTC_Manager_New failed with Errorcode 0x%.2X>\n", error);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_SBitCache_New(manager, &cache)))
		{
			printf("input <FTC_SBitCache_New failed with Errorcode 0x%.2X>\n", error);
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_Manager_LookupFace(manager, FONT, &face)))
		{
			if((error = FTC_Manager_LookupFace(manager, FONT2, &face)))
			{
				printf("input <FTC_Manager_LookupFace failed with Errorcode 0x%.2X>\n", error);
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
			perror("input <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}
		if(!(obb = malloc(fix_screeninfo.line_length*var_screeninfo.yres)))
		{
			perror("input <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			free(lbb);
			munmap(lfb, fix_screeninfo.smem_len);
			return 0;
		}

		memcpy(lbb, lfb, fix_screeninfo.line_length*var_screeninfo.yres);
		memcpy(obb, lfb, fix_screeninfo.line_length*var_screeninfo.yres);

		startx = sx /*+ (((ex-sx) - 620)/2)*/;
		starty = sy /* + (((ey-sy) - 505)/2)*/;

	signal(SIGINT, quit_signal);
	signal(SIGTERM, quit_signal);
	signal(SIGQUIT, quit_signal);
	signal(SIGSEGV, quit_signal);

	//main loop
	put_instance(instance=get_instance()+1);
	printf("%s\n",inputd(format, title, defstr, keys, frame, mask, bhelp, cols, tmo, debounce));
	put_instance(get_instance()-1);
	
	//cleanup

	// clear Display
//	memset(lbb, 0, var_screeninfo.xres*var_screeninfo.yres);
//	memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres);
	
	memcpy(lfb, obb, fix_screeninfo.line_length*var_screeninfo.yres);

	free(buffer);

	FTC_Manager_Done(manager);
	FT_Done_FreeType(library);

	free(lbb);
	free(obb);
	munmap(lfb, fix_screeninfo.smem_len);

	close(fb);
	CloseRC();


	return 1;
}

