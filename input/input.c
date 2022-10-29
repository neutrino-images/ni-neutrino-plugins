#include <string.h>
#include <stdio.h>
#include <time.h>
#include <signal.h>

#include "current.h"
#include <fb_device.h>

#include "text.h"
#include "io.h"
#include "gfx.h"
#include "inputd.h"

#define I_VERSION	2.16

#ifndef CONFIGDIR
#define CONFIGDIR "/var/tuxbox/config"
#endif
#ifndef FONTDIR
#define FONTDIR	"/usr/share/fonts"
#endif

#define NCF_FILE CONFIGDIR "/neutrino.conf"

//freetype stuff
char FONT[128] = FONTDIR "/neutrino.ttf";
// if font is not in usual place, we look here:
#define FONT2 FONTDIR "/pakenham.ttf"

#define BUFSIZE 	1024

FT_Error 		error;
FT_Library		library;
FTC_Manager		manager;
FTC_SBitCache		cache;
FTC_SBit		sbit;
#if FREETYPE_MAJOR == 2 && FREETYPE_MINOR == 0
FTC_Image_Desc		desc;
#else
FTC_ImageTypeRec	desc;
#endif
FT_Face			face;
FT_UInt			prev_glyphindex;
FT_Bool			use_kerning;

struct fb_fix_screeninfo fix_screeninfo;
struct fb_var_screeninfo var_screeninfo;

int fb;
int startx, starty, sx, ex, sy, ey;

//					   CMCST,   CMCS,  CMCT,    CMC,    CMCIT,  CMCI,   CMHT,   CMH
//					   WHITE,   BLUE0, TRANSP,  CMS,    ORANGE, GREEN,  YELLOW, RED
//					   COL_MENUCONTENT_PLUS_0 - 3, COL_SHADOW_PLUS_0

unsigned char bl[] = {	0x00, 	0x00, 	0xFF, 	0x80, 	0xFF, 	0x80, 	0x00, 	0x80,
					    0xFF, 	0xFF, 	0x00, 	0xFF, 	0x00, 	0x00, 	0x00, 	0x00,
						0x00,	0x00,	0x00,	0x00,	0x00};
unsigned char gn[] = {	0x00, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0x00, 	0xC0, 	0x00,
					    0xFF, 	0x80, 	0x00, 	0x80, 	0xC0, 	0xFF, 	0xFF, 	0x00,
						0x00,	0x00,	0x00,	0x00,	0x00};
unsigned char rd[] = {	0x00, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0x00,
					    0xFF, 	0x00, 	0x00, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0xFF,
						0x00,	0x00,	0x00,	0x00,	0x00};
unsigned char tr[] = {	0xFF, 	0xFF, 	0xFF,  	0xA0,  	0xFF,  	0xA0,  	0xFF,  	0xFF,
						0xFF, 	0xFF, 	0x00,  	0xFF,  	0xFF,  	0xFF,  	0xFF,  	0xFF,
						0x00,	0x00,	0x00,	0x00,	0x00};
uint32_t bgra[22];

void TrimString(char *strg);
void closedown(void);

// OSD stuff
static char menucoltxt[][25]={
	"Content_Selected_Text",
	"Content_Selected",
	"Content_Text",
	"Content",
	"Content_inactive_Text",
	"Content_inactive",
	"Head_Text",
	"Head"
};
static char spres[][4]={"", "a", "b"};

char *line_buffer=NULL;

// Misc
const char NOMEM[]="input <Out of memory>\n";
const char TMP_FILE[]="/tmp/input.tmp";
uint32_t *lfb = NULL, *lbb = NULL, *obb = NULL;
char nstr[512]={0};
char *trstr=NULL;
const char sc[8]={'a','o','u','A','O','U','z','d'}, tc[8]={0xE4,0xF6,0xFC,0xC4,0xD6,0xDC,0xDF,0xB0};
int radius;
int swidth;


static void quit_signal(int sig)
{
	char *txt=NULL;
	switch (sig)
	{
		case SIGINT:  txt=strdup("SIGINT");  break;  // 2
		case SIGQUIT: txt=strdup("SIGQUIT"); break;  // 3
		case SIGSEGV: txt=strdup("SIGSEGV"); break;  // 11
		case SIGTERM: txt=strdup("SIGTERM"); break;  // 15
		default:
			txt=strdup("UNKNOWN"); break;
	}

	printf("%s Version %.2f killed, signal %s(%d)\n", __plugin__, I_VERSION, txt, sig);
	free(txt);
	closedown();
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
			if((strncmp(entry, tstr, 10) == 0) && (strncmp(entry, "font_file=", 10) == 0))
			{
				sscanf(tstr, "font_file=%127s", FONT);
				rv = 1;
			}
//			printf("%s\n%s=%s -> %d\n",tstr,entry,cfptr,rv);
		}
		fclose(nfh);
	}
	return rv;
}

int scale2res(int s)
{
	if (var_screeninfo.xres == 1920)
		s += s/2;

	return s;
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
unsigned i;
int found=0;
char *sptr=msg, *tptr=msg, rc;

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
			for(i=0; i<sizeof(sc)/sizeof(sc[0]) && !found; i++)
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
int ix, tv, cols=25, tmo=0, spr, resolution;
const char ttl[]="Eingabe";
int dloop=1,keys=0,frame=1,mask=0,bhelp=0;
char rstr[512]={0}, *title=NULL, *format=NULL, *defstr=NULL, *aptr=NULL, *rptr=NULL;

		if(argc==1)
		{
			ShowUsage();
			return 0;
		}

		//init framebuffer before 1st scale2res
		fb=open(FB_DEVICE, O_RDWR);
		if (fb < 0)
			fb=open(FB_DEVICE_FALLBACK, O_RDWR);
		if(fb == -1)
		{
			perror(__plugin__ " <open framebuffer device>");
			exit(1);
		}
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

		// read arguments
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
					fprintf(stderr, "%s <param error: %s>\n",__plugin__,aptr);
					return 0;
					break;
				
				case 2:
					fprintf(stderr, "%s <unknown command: %s>\n\n",__plugin__ ,aptr);
					ShowUsage();
					return 0;
					break;
			}
		}
		if(!format)
		{
			fprintf(stderr, "%s <missing format string>\n", __plugin__);
			return 0;
    	}
		if(!title)
		{
			title=strdup(ttl);
		}

		if((line_buffer=calloc(BUFSIZE+1, sizeof(char)))==NULL)
		{
			fprintf(stderr, NOMEM);
			return 0;
		}

		spr=Read_Neutrino_Cfg("screen_preset") + 1;
		resolution=Read_Neutrino_Cfg("osd_resolution");

		if (resolution == -1)
			sprintf(line_buffer,"screen_StartX_%s", spres[spr]);
		else
			sprintf(line_buffer,"screen_StartX_%s_%d", spres[spr], resolution);
		if((sx=Read_Neutrino_Cfg(line_buffer))<0)
			sx=scale2res(100);

		if (resolution == -1)
			sprintf(line_buffer,"screen_EndX_%s", spres[spr]);
		else
			sprintf(line_buffer,"screen_EndX_%s_%d", spres[spr], resolution);
		if((ex=Read_Neutrino_Cfg(line_buffer))<0)
			ex=scale2res(1180);

		if (resolution == -1)
			sprintf(line_buffer,"screen_StartY_%s", spres[spr]);
		else
			sprintf(line_buffer,"screen_StartY_%s_%d", spres[spr], resolution);
		if((sy=Read_Neutrino_Cfg(line_buffer))<0)
			sy=scale2res(100);

		if (resolution == -1)
			sprintf(line_buffer,"screen_EndY_%s", spres[spr]);
		else
			sprintf(line_buffer,"screen_EndY_%s_%d", spres[spr], resolution);
		if((ey=Read_Neutrino_Cfg(line_buffer))<0)
			ey=scale2res(620);

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

		int	cix=CMC;
		for(ix=COL_MENUCONTENT_PLUS_0; ix<=COL_MENUCONTENT_PLUS_3; ix++)
		{
			rd[ix]=rd[cix]+25;
			gn[ix]=gn[cix]+25;
			bl[ix]=bl[cix]+25;
			tr[ix]=tr[cix];
			cix=ix;
		}

		sprintf(rstr,"infobar_alpha");
		if((tv=Read_Neutrino_Cfg(rstr))>=0)
			tr[COL_SHADOW_PLUS_0]=255-(float)tv*2.55;

		sprintf(rstr,"infobar_blue");
		if((tv=Read_Neutrino_Cfg(rstr))>=0)
			bl[COL_SHADOW_PLUS_0]=(float)tv*2.55*0.4;

		sprintf(rstr,"infobar_green");
		if((tv=Read_Neutrino_Cfg(rstr))>=0)
			gn[COL_SHADOW_PLUS_0]=(float)tv*2.55*0.4;

		sprintf(rstr,"infobar_red");
		if((tv=Read_Neutrino_Cfg(rstr))>=0)
			rd[COL_SHADOW_PLUS_0]=(float)tv*2.55*0.4;

		for (ix = 0; ix <= COL_SHADOW_PLUS_0; ix++)
			bgra[ix] = (tr[ix] << 24) | (rd[ix] << 16) | (gn[ix] << 8) | bl[ix];

		if(Read_Neutrino_Cfg("rounded_corners")>0)
			radius=scale2res(11);
		else
			radius = 0;

		InitRC();

		if((trstr=malloc(BUFSIZE))==NULL)
		{
			fprintf(stderr, NOMEM);
			return -1;
		}


	//init fontlibrary

		if((error = FT_Init_FreeType(&library)))
		{
			fprintf(stderr, "%s <FT_Init_FreeType failed with Errorcode 0x%.2X>",__plugin__ , error);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_Manager_New(library, 1, 2, 0, &MyFaceRequester, NULL, &manager)))
		{
			fprintf(stderr, "%s <FTC_Manager_New failed with Errorcode 0x%.2X>\n",__plugin__ , error);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_SBitCache_New(manager, &cache)))
		{
			fprintf(stderr, "%s <FTC_SBitCache_New failed with Errorcode 0x%.2X>\n",__plugin__ , error);
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		Read_Neutrino_Cfg("font_file=");
		if((error = FTC_Manager_LookupFace(manager, FONT, &face)))
		{
			if((error = FTC_Manager_LookupFace(manager, FONT2, &face)))
			{
				fprintf(stderr, "%s <FTC_Manager_LookupFace failed with Errorcode 0x%.2X>\n",__plugin__ , error);
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
		int stride = fix_screeninfo.line_length;
		swidth = stride/sizeof(uint32_t);
#if !BOXMODEL_VUPLUS_ALL
		if (stride == 7680 && var_screeninfo.xres == 1280)
#endif
			var_screeninfo.yres = 1080;

		if(!(lbb = malloc(var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t))))
		{
			perror(__plugin__ " <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}
		if(!(obb = malloc(var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t))))
		{
			perror(__plugin__ " <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			free(lbb);
			munmap(lfb, fix_screeninfo.smem_len);
			return 0;
		}
		memcpy(lbb, lfb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
		memcpy(obb, lfb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));

		startx = sx;
		starty = sy;

	/* scale to resolution */
	FSIZE_BIG = scale2res(FSIZE_BIG);
	FSIZE_MED = scale2res(FSIZE_MED);
	FSIZE_SMALL = scale2res(FSIZE_SMALL);

	TABULATOR = scale2res(TABULATOR);

	OFFSET_MED = scale2res(OFFSET_MED);
	OFFSET_SMALL = scale2res(OFFSET_SMALL);
	OFFSET_MIN = scale2res(OFFSET_MIN);

	/* Set up signal handlers. */
	signal(SIGINT, quit_signal);
	signal(SIGQUIT, quit_signal);
	signal(SIGTERM, quit_signal);
	signal(SIGSEGV, quit_signal);

	//main loop
	put_instance(instance=get_instance()+1);
	printf("%s", inputd(format, title, defstr, keys, frame, mask, bhelp, cols, tmo));
	closedown();
	return 1;
}

/******************************************************************************
 * input close
 ******************************************************************************/
void closedown(void)
{
	put_instance(get_instance()-1);
	
	// clear Display
	memcpy(lfb, obb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
	munmap(lfb, fix_screeninfo.smem_len);

	free(line_buffer);

	FTC_Manager_Done(manager);
	FT_Done_FreeType(library);

	free(lbb);
	free(obb);

	close(fb);
	CloseRC();
}
