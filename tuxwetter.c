/*
 * tuxwetter.c - TuxBox Weather Plugin
 *
 * Copyright (C) 2004 SnowHead <SnowHead@keywelt-board.com>
 *                    Worschter
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * $Id: tuxwetter.c,v 3.18 2010/06/18 20:00 SnowHead $
 */

//getline needed #define _GNU_SOURCE
#define _GNU_SOURCE

#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <signal.h>
#include <time.h>
//#include <linux/delay.h>
#include "tuxwetter.h"
#include "parser.h"
#include "text.h"
#include "io.h"
#include "gfx.h"
#include "php.h"
#include "http.h"
#include "jpeg.h"
#include "pngw.h"
#include "gif.h"
#include "fb_display.h"
#include "resize.h"
#include "gifdecomp.h"

#define P_VERSION "3.03"

#ifndef HAVE_DREAMBOX_HARDWARE
char CONVERT_LIST[]="/var/tuxbox/config/tuxwetter/convert.list";
#define CFG_FILE 	"/var/tuxbox/config/tuxwetter/tuxwetter.conf"
#define MCF_FILE 	"/var/tuxbox/config/tuxwetter/tuxwetter.mcfg"
#define TIME_FILE	"/var/tuxbox/config/tuxwetter/swisstime"
//#define MISS_FILE	"/var/tuxbox/config/tuxwetter/missing_translations.txt"
#else
char CONVERT_LIST[]="/var/bin/tuxwet/convert.list";
#define CFG_FILE 	"/var/bin/tuxwet/tuxwetter.conf"
#define MCF_FILE 	"/var/bin/tuxwet/tuxwetter.mcfg"
#define TIME_FILE	"/var/bin/tuxwet/swisstime"
#define MISS_FILE	"/var/bin/tuxwet/missing_translations.txt"
#endif
#define NCF_FILE 	"/var/tuxbox/config/neutrino.conf"
#define ECF_FILE	"/var/tuxbox/config/enigma/config"
#define BMP_FILE 	"tuxwettr.bmp"
#define JPG_FILE	"/tmp/picture.jpg"
#define GIF_FILE	"/tmp/picture.gif"
#define GIF_MFILE	"/tmp/gpic"
#define PNG_FILE	"/tmp/picture.png"
#define PHP_FILE	"/tmp/php.htm"
#define TMP_FILE	"/tmp/tuxwettr.tmp"
#define ICON_FILE	"/tmp/icon.gif"
#define TRANS_FILE	"/tmp/picture.html"
static char TCF_FILE[128]="";

#define LIST_STEP 	10
#define MAX_FUNCS  7
#define LCD_CPL 	12
#define LCD_RDIST 	10

// Forward defines
int pic_on_data(char *name, int xstart, int ystart, int xsize, int ysize, int wait, int single, int center, int rahmen);
char par[32]="1005530704", key[32]="a9c95f7636ad307b";
void TrimString(char *strg);

// Color table stuff
static char menucoltxt[][25]={"Content_Selected_Text","Content_Selected","Content_Text","Content","Content_inactive_Text","Content_inactive","Head_Text","Head"};
//static char spres[][5]={"","_crt","_lcd"};

//#define FONT "/usr/share/fonts/md_khmurabi_10.ttf"
#define FONT2 "/share/fonts/pakenham.ttf"
// if font is not in usual place, we look here:
#define FONT "/share/fonts/neutrino.ttf"

//					    CMCST,  CMCS,   CMCT,   CMC,    CMCIT,  CMCI,   CMHT,   CMH
//					    WHITE,  BLUE0,  TRANSP, CMS,    ORANGE, GREEN,  YELLOW, RED
//					    CMCP0,  CMCP1,  CMCP2,  CMCP3
unsigned char bl[] = {	0x00, 	0x00, 	0xFF, 	0x80, 	0xFF, 	0x80, 	0x00, 	0x80,
						0xFF, 	0xFF, 	0x00, 	0xFF, 	0x00, 	0x00, 	0x00, 	0x00,
						0x00, 	0x00,  	0x00,  	0x00};
unsigned char gn[] = {	0x00, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0x00, 	0xC0, 	0x00,
						0xFF, 	0x80, 	0x00, 	0x80, 	0xC0, 	0xFF, 	0xFF, 	0x00,
						0x00, 	0x00,  	0x00,  	0x00};
unsigned char rd[] = {	0x00, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0x00,
						0xFF, 	0x00, 	0x00, 	0x00, 	0xFF, 	0x00, 	0xFF, 	0xFF,
						0x00, 	0x00,  	0x00,  	0x00};
unsigned char tr[] = {	0xFF, 	0xFF, 	0xFF,  	0xA0,  	0xFF,  	0x80,  	0xFF,  	0xFF,
						0xFF, 	0xFF, 	0x00,  	0xFF,  	0xFF,  	0xFF,  	0xFF,  	0xFF,
						0x00, 	0x00,  	0x00,  	0x00};

// Menu structure stuff
enum {TYP_MENU, TYP_CITY, TYP_PICTURE, TYP_PICHTML, TYP_TXTHTML, TYP_TEXTPAGE, TYP_TXTPLAIN, TYP_EXECUTE, TYP_ENDMENU, TYP_WEATH};
static char TYPESTR[TYP_WEATH+1][10]={"MENU=","Stadt=","PICTURE=","PICHTML=","TXTHTML=","TEXTPAGE=","TXTPLAIN=","EXECUTE=","ENDMENU"};
enum {PTYP_ASK, PTYP_JPG, PTYP_GIF, PTYP_PNG};
static char PTYPESTR[PTYP_PNG+1][5]={"","JPG","GIF","PNG"};
char *cmdline=NULL;
char *line_buffer=NULL;

typedef struct {char *entry; int headerpos; int type; int pictype; int repeat; int underline; int absolute;} LISTENTRY;
typedef LISTENTRY *PLISTENTRY;
typedef PLISTENTRY	*LIST;
typedef struct {int num_headers; int act_header; int max_header; char **headertxt; int *headerlevels; int *lastheaderentrys; int num_entrys; int act_entry; int max_entrys; LIST list;} MENU;

MENU menu;
MENU funcs;

int Check_Config(void);
int Clear_List(MENU *m, int mode);
int Get_Selection(MENU *m);
int AddListEntry(MENU *m, char *line, int pos);
int Get_Menu();
void ShowInfo(MENU *m);

// Misc
char NOMEM[]="Tuxwetter <Out of memory>\n";
unsigned char *lfb = 0, *lbb = 0;
int intype=0, show_icons=0, gmodeon=0, ctmo=0, metric=1, loadalways=0, radius=0;
char city_code[30] = "";
char city_name[50] = "";
unsigned int alpha=0x0202;
int show_splash=0;
char lastpicture[BUFSIZE]="";
char nstr[BUFSIZE]="";
char *trstr;
char *htmstr;
unsigned char *proxyadress=NULL, *proxyuserpwd=NULL;
char INST_FILE[]="/tmp/rc.locked";
char LCDL_FILE[]="/tmp/lcd.locked";
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
FILE *fh;

	if(pval)
	{
		if((fh=fopen(INST_FILE,"w"))!=NULL)
		{
			fputc(pval,fh);
			fclose(fh);
		}
		if(pval==1)
		{
			if((fh=fopen(LCDL_FILE,"w"))!=NULL)
			{
				fputc(0,fh);
				fclose(fh);
			}
		}
	}
	else
	{
		remove(INST_FILE);
		remove(LCDL_FILE);
	}
}

static void quit_signal(int sig)
{
	put_instance(get_instance()-1);
	printf("tuxwetter Version %s killed\n",P_VERSION);
	exit(1);
}

void xremove(char *fname)
{
FILE *fh;

	if((fh=fopen(fname,"r"))!=NULL)
		{
		fclose(fh);
		remove(fname);
		}
}

int Read_Neutrino_Cfg(char *entry)
{
FILE *nfh;
char tstr [512], *cfptr=NULL;
int rv=-1,styp=0;

	if((((nfh=fopen(NCF_FILE,"r"))!=NULL)&&(styp=1)) || ((((nfh=fopen(ECF_FILE,"r"))!=NULL))&&(styp=2)))
	{
		tstr[0]=0;

		while((!feof(nfh)) && ((strstr(tstr,entry)==NULL) || ((cfptr=strchr(tstr,'='))==NULL)))
		{
			fgets(tstr,500,nfh);
		}
		if(!feof(nfh) && cfptr)
		{
			++cfptr;
			if(styp==1)
			{
				if(sscanf(cfptr,"%d",&rv)!=1)
				{
					if(strstr(cfptr,"true")!=NULL)
						rv=1;
					else if(strstr(cfptr,"false")!=NULL)
						rv=0;
					else
						rv=-1;
				}
			}
			if(styp==2)
			{
				if(sscanf(cfptr,"%x",&rv)!=1)
				{
					rv=-1;
				}
			}
//			printf("%s\n%s=%s -> %d\n",tstr,entry,cfptr,rv);
		}
		fclose(nfh);
	}
	return rv;
}

/******************************************************************************
 * ReadConf (0=fail, 1=done)
 ******************************************************************************/

int ReadConf(char *iscmd)
{
	FILE *fd_conf;
	char *cptr;

	//open config

	if((!strlen(TCF_FILE)) ||  (strlen(TCF_FILE) && !(fd_conf = fopen(TCF_FILE, "r"))))
	{
		if(!(fd_conf = fopen(CFG_FILE, "r")))
		{
			if(iscmd==NULL)
			{
				printf("Tuxwetter <unable to open Config-File>\n");
				return 0;
			}
		}
		else
		{
			strcpy(TCF_FILE,CFG_FILE);
		}
	}
	if(fd_conf)
	{
		fclose(fd_conf);
	}
	if(!(fd_conf = fopen(MCF_FILE, "r")))
	{
		fd_conf = fopen(TCF_FILE, "r");
	}

	while(fgets(line_buffer, BUFSIZE, fd_conf))
	{
		TrimString(line_buffer);

		if((line_buffer[0]) && (line_buffer[0]!='#') && (!isspace(line_buffer[0])) && ((cptr=strchr(line_buffer,'='))!=NULL))
		{
			if(strstr(line_buffer,"SplashScreen") == line_buffer)
				{
					sscanf(cptr+1,"%d",&show_splash);
				}
			if(strstr(line_buffer,"ShowIcons") == line_buffer)
				{
					sscanf(cptr+1,"%d",&show_icons);
				}
			if(strstr(line_buffer,"ProxyAdressPort") == line_buffer)
				{
					proxyadress=strdup(cptr+1);
				}
			if(strstr(line_buffer,"ProxyUserPwd") == line_buffer)
				{
					proxyuserpwd=strdup(cptr+1);
				}
			if(strstr(line_buffer,"ConnectTimeout") == line_buffer)
				{
					sscanf(cptr+1,"%d",&ctmo);
				}
			if(strstr(line_buffer,"Metric") == line_buffer)
				{
					sscanf(cptr+1,"%d",&metric);
				}
			if(strstr(line_buffer,"LoadAlways") == line_buffer)
				{
					sscanf(cptr+1,"%d",&loadalways);
				}
			if(strstr(line_buffer,"PartnerID") == line_buffer)
				{
					strncpy(par,cptr+1,sizeof(par)-1);
				}
			if(strstr(line_buffer,"LicenseKey") == line_buffer)
				{
					strncpy(key,cptr+1,sizeof(key)-1);
				}
			if(strstr(line_buffer,"InetConnection") == line_buffer)
				{
					if(strstr(cptr+1,"ISDN")!=NULL)
						{
							intype=1;
						}
					if(strstr(cptr+1,"ANALOG")!=NULL)
						{
							intype=2;
						}
				}

/*			if(strstr(line_buffer,"FONT=") == line_buffer)
			{
				strcpy(FONT,strchr(line_buffer,'=')+1);
			}
			if(strstr(line_buffer,"FONTSIZE=") == line_buffer)
			{
				sscanf(strchr(line_buffer,'=')+1,"%d",&FSIZE_MED);
				FSIZE_FSIZE_BIG=(FSIZE_MED*4)/3;
				FSIZE_SMALL=(FSIZE_MED*4)/5;
			}
*/
		}
	}

	return 1;
}

int Transform_Entry(char *src, char *trg)
{
int type=0,tret=-1,fcnt,fpos,tval,ferr,tsub;	
int noprint,rndval,loctime=0;
char /*pstr[512],nstr[512],dstr[50],*/fstr[5],*cptr,*tptr,*aptr;
time_t stime;
struct tm *tltime;

	type=0;
	tsub=0;
	*trg=0;
	if((cptr=strchr(src,','))==NULL)
	{
		return tret;
	}
	cptr++;
	aptr=strchr(cptr,'|');
	if(aptr)
	{
		while(aptr && ((aptr=strchr(aptr,'|'))!=NULL))
		{
			++aptr;
			rndval=0;
			if(*aptr=='L')
			{
				++aptr;
				loctime=1;
			}
			if(*aptr=='R')
			{
				++aptr;
				rndval=1;
			}
			if(*aptr=='N')
			{
				++aptr;
			}
			if(sscanf(aptr,"%d",&tval)==1)
			{
				while((aptr<(cptr+strlen(cptr))) && (*aptr=='-' || ((*aptr>='0') && (*aptr<='9'))))
				{ 
					++aptr;
				}
				if(!rndval)
				{
					switch(*aptr)
					{
						case 'Y': tsub+=tval*365*24*3600; break;
						case 'M': tsub+=tval*31*24*3600; break;
						case 'D': tsub+=tval*24*3600; break;
						case 'h': tsub+=tval*3600; break;
						case 'm': tsub+=tval*60; break;
						case 's': tsub+=tval; break;
					}
				}
			}
		}
		time(&stime);	
		stime-=tsub;
		if(loctime)
		{
			tltime=localtime(&stime);
		}
		else
		{
			tltime=gmtime(&stime);
		}	
//		strncpy(nstr,src,cptr-src);
//		++cptr;
		fpos=0;
		ferr=0;
		tval=0;
		while(*cptr>' ' && !ferr)
		{
			if(*cptr=='|')
			{
				noprint=0;
				rndval=0;
				++cptr;
				if(*cptr=='L')
				{
					++cptr;
				}
				if(*cptr=='N')
				{
					noprint=1;
					++cptr;
				}
				if(*cptr=='R')
				{
					++cptr;
					sscanf(cptr,"%d",&rndval);
					rndval=abs(rndval);
				}
				while(*cptr && ((*cptr=='-') || ((*cptr>='0') && (*cptr<='9'))))
				{
					cptr++;
				}
				tptr=cptr+1;
				fcnt=1;
				while(*tptr && (*tptr==*cptr))
				{
					fcnt++;
					tptr++;
				}
				sprintf(fstr,"%%0%dd",fcnt);
				switch(*cptr)
				{
					case 'Y':
						if(fcnt==4)
						{
							tval=1900+tltime->tm_year;
						}
						else
						{
							tval=tltime->tm_year-100;
						}
						break;
									
					case 'M':
						tval=tltime->tm_mon+1;
						break;
								
					case 'D':
						tval=tltime->tm_mday;
						break;
										
					case 'h':
						tval=tltime->tm_hour;
						break;
										
					case 'm':
						tval=tltime->tm_min;
						break;
										
					case 's':
						tval=tltime->tm_sec;
						break;
										
					default:
						ferr=1;
						break;
				}
				if(!ferr && !noprint)
				{
					if(rndval)
					{
						tval=((int)(tval/rndval))*rndval;
					}
					sprintf(trg+fpos,fstr,tval);
					fpos+=fcnt;
				}
				cptr=tptr;
			}
			else
			{
				*(trg+(fpos++))=*cptr;
				++cptr;
			}
		}
		*(trg+fpos)=0;
		tret=ferr;
	}
	else
	{
		ferr=0;
		tret=0;
		strcpy(trg,cptr);
		strcpy(nstr,src);
		if((cptr=strchr(nstr,','))!=NULL)
		{
			*cptr=0;
		}
	}
	return tret;
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


int Check_Config(void)
{
int rv=-1, level=0;
char *pt1;
FILE *fh;

	if((fh=fopen(TCF_FILE,"r"))!=NULL)
	{
		while(fgets(line_buffer, BUFSIZE, fh))
		{
			TrimString(line_buffer);
			if(strstr(line_buffer,TYPESTR[TYP_MENU])==line_buffer)
			{
				if(menu.num_headers>=menu.max_header)
				{
					if((menu.headertxt=realloc(menu.headertxt,(menu.max_header+LIST_STEP)*sizeof(char*)))==NULL)
					{
						printf(NOMEM);
						Clear_List(&menu,0);
						return rv;
					}
					memset(&menu.headertxt[menu.max_header],0,LIST_STEP*sizeof(char*));
					if((menu.headerlevels=realloc(menu.headerlevels,(menu.max_header+LIST_STEP)*sizeof(int)))==NULL)
					{
						printf(NOMEM);
						Clear_List(&menu,0);
						return rv;
					}
					if((menu.lastheaderentrys=realloc(menu.lastheaderentrys,(menu.max_header+LIST_STEP)*sizeof(int)))==NULL)
					{
						printf(NOMEM);
						Clear_List(&menu,0);
						return rv;
					}
				menu.max_header+=LIST_STEP;
				}
				pt1=strchr(line_buffer,'=');
				if(*(++pt1)=='*')
				{
					++pt1;
				}
				if(menu.headertxt[menu.num_headers])
				{
					free(menu.headertxt[menu.num_headers]);
					menu.headertxt[menu.num_headers]=NULL;
				}
				menu.headerlevels[menu.num_headers]=level++;
				menu.headertxt[menu.num_headers++]=strdup(pt1);
			}
			else
			{
				if(strstr(line_buffer,TYPESTR[TYP_ENDMENU])==line_buffer)
				{
				--level;
				}
			}
		}
		rv=0;
		fclose(fh);
	}
	return rv;
}

int Clear_List(MENU *m, int mode)
{
int i;
PLISTENTRY entr;

	if(m->max_entrys)
	{
		for(i=0; i<m->num_entrys; i++)
		{
			if(m->list[i]->entry) free(m->list[i]->entry);
			free(m->list[i]);
		}
		m->num_entrys=0;
		m->max_entrys=0;
		m->list=NULL;
	}
	switch(mode)
	{
		case 0: return 0;
		
		case 1:
	
			if((m->list=calloc(LIST_STEP,sizeof(PLISTENTRY)))==NULL)
			{
				printf(NOMEM);
				return -1;
			}

			for(i=0; i<LIST_STEP; i++)
			{
				if((entr=calloc(1,sizeof(LISTENTRY)))==NULL)
					{
					printf(NOMEM);
					Clear_List(m,0);
					return -1;
					}
				m->list[i]=entr;
			}
			m->max_entrys=LIST_STEP;
			break;
			
		case -1:
			if(m->num_headers && m->headertxt)
			{
				for(i=0; i<m->num_headers; i++)
				{
					free(m->headertxt[i]);
				}
				m->num_headers=0;
				m->list=NULL;
			}
			if(m->headertxt)
			{
				free(m->headertxt);
				m->headertxt=NULL;
			}
			break;
	}
	return 0;
}

int Get_Selection(MENU *m)
{
int rv=1,rccode, mloop=1;
//int lrow,lpos;
//char dstr[128];
char *lcptr = NULL, *lcstr= NULL, *lcdptr = NULL;
//	LCD_Init();
	do{
		rccode=-1;
		ShowInfo(m);
		if(m->list[m->act_entry]->entry)
		{
			sprintf(trstr,"%s%s",(m->list[m->act_entry]->type==TYP_MENU)?"> ":"",m->list[m->act_entry]->entry);
			if((lcptr=strchr(trstr,','))!=NULL)
			{
				*lcptr=0;
			}
		}
		else
		{
			sprintf(trstr,"%s",prs_translate("Kein Eintrag",CONVERT_LIST));
		}
		lcstr=strdup(trstr);
		lcptr=lcdptr=lcstr;
		while(*lcptr)
		{
			if(*lcptr=='~')
			{
				++lcptr;
				if(*lcptr)
				{
					++lcptr;
				}
			}
			*(lcdptr++)=*(lcptr++);
		}
#if 0
		*lcptr=0;
		LCD_Clear();
		LCD_draw_rectangle (0,0,119,59, LCD_PIXEL_ON,LCD_PIXEL_OFF);
		LCD_draw_rectangle (3,3,116,56, LCD_PIXEL_ON,LCD_PIXEL_OFF);
		lpos=strlen(lcstr);
		lrow=0;
		while(lpos>0)
		{
			strncpy(dstr,lcstr+LCD_CPL*lrow,LCD_CPL);
			dstr[LCD_CPL]=0;
			lpos-=LCD_CPL;
			LCD_draw_string(13, (lrow+2)*LCD_RDIST, dstr);
			lrow++;
		}
		LCD_update();
#endif
		switch((rccode = GetRCCode()))
		{
			case KEY_RED:
				m->act_entry=(m->act_entry/10)*10;
				rv=1;
				mloop=0;
				break;

			case KEY_GREEN:
				m->act_entry=(m->act_entry/10)*10+1;
				rv=1;
				mloop=0;
				break;

			case KEY_YELLOW:
				m->act_entry=(m->act_entry/10)*10+2;
				rv=1;
				mloop=0;
				break;

			case KEY_BLUE:
				m->act_entry=(m->act_entry/10)*10+3;
				rv=1;
				mloop=0;
				break;

			case KEY_1:
				m->act_entry=(m->act_entry/10)*10+4;
				rv=1;
				mloop=0;
				break;

			case KEY_2:
				m->act_entry=(m->act_entry/10)*10+5;
				rv=1;
				mloop=0;
				break;

			case KEY_3:
				m->act_entry=(m->act_entry/10)*10+6;
				rv=1;
				mloop=0;
				break;

			case KEY_4:
				m->act_entry=(m->act_entry/10)*10+7;
				rv=1;
				mloop=0;
				break;

			case KEY_5:
				m->act_entry=(m->act_entry/10)*10+8;
				rv=1;
				mloop=0;
				break;

			case KEY_6:
				m->act_entry=(m->act_entry/10)*10+9;
				rv=1;
				mloop=0;
				break;

			case KEY_UP:
			case KEY_VOLUMEDOWN:	--m->act_entry;
					break;

			case KEY_DOWN:
			case KEY_VOLUMEUP:	++m->act_entry;
					break;

			case KEY_PAGEUP :	m->act_entry-=10;
					break;

			case KEY_PAGEDOWN :	m->act_entry+=10;
					break;

			case KEY_OK:
				rv=1;
				mloop=0;
				break;

			case KEY_EXIT:
				rv=0;
				mloop=0;
				break;

			case KEY_MUTE:	break;

			case KEY_HELP:
				rv=-99;
				mloop=0;
				break;

			case KEY_POWER:
				rv=-1;
				mloop=0;
				break;

			case KEY_SETUP:
				rv=-98;
				mloop=0;
				break;
				
			default:	continue;
		}

		if (m->act_entry>=m->num_entrys)
		{
			m->act_entry=0;
		}
		if(m->act_entry<0)
		{
			m->act_entry=(m->num_entrys)?m->num_entrys-1:0;
		}
	} while(mloop);

	ShowInfo(m);

return rv;
}

int AddListEntry(MENU *m, char *line, int pos)
{
int i,j,found=0,pfound=1;
PLISTENTRY entr;
char *ptr1,*ptr2,*ptr3;


	if(!strlen(line))
	{
		return 1;
	}
	
	if(m->num_entrys>=m->max_entrys)
	{
		if((m->list=realloc(m->list,(m->max_entrys+LIST_STEP)*sizeof(PLISTENTRY)))==NULL)
		{
			printf(NOMEM);
			Clear_List(m,0);
			return 0;
		}
		for(i=m->num_entrys; i<m->num_entrys+LIST_STEP; i++)
		{
			if((entr=calloc(1,sizeof(LISTENTRY)))==NULL)
				{
				printf(NOMEM);
				Clear_List(m,0);
				return -1;
				}
			m->list[i]=entr;
		}
		m->max_entrys+=LIST_STEP;
	}
	
	entr=m->list[m->num_entrys];

	if(m == &funcs)
	{
		entr->type=TYP_WEATH;
		entr->entry=strdup(line);
		entr->headerpos=pos;
		m->num_entrys++;
		found=1;
	}
	else
	{
		for(i=TYP_MENU; !found && i<=TYP_EXECUTE; i++)
		{
			if((ptr1=strstr(line,TYPESTR[i]))==line)
			{
				ptr2=strchr(ptr1,'=');
				ptr2++;
				if(*ptr2=='*')
				{
					entr->underline=1;
					while(*(++ptr2))
					{
						*(ptr2-1)=*ptr2;
					}
					*(ptr2-1)=0;
					ptr2=strchr(ptr1,'=')+1;
				}
				if((i==TYP_MENU) || ((ptr1=strchr(ptr2,','))!=NULL))
				{
					if(i!=TYP_MENU)
					{
						++ptr1;
						if((ptr3=strstr(ptr1,"abs://"))!=NULL)
						{
							memmove(ptr3,ptr3+3,strlen(ptr3));
							entr->absolute=1;
						}
						else
						{
							entr->absolute=0;
						}
						if((i==TYP_PICTURE) || (i==TYP_PICHTML))
						{
							if(*ptr1=='|')
							{
								pfound=0;
								ptr2=ptr1;
								++ptr1;
								for(j=PTYP_JPG; !pfound && j<=PTYP_PNG; j++)
								{
									if(strncasecmp(ptr1,PTYPESTR[j],3)==0)
									{
										pfound=1;
										entr->pictype=j;
										ptr1+=3;
										if(sscanf(ptr1,"%d",&(entr->repeat))!=1)
										{
											entr->repeat=0;
										}
										ptr1=strchr(ptr1,'|');
										while(ptr1 && (*(++ptr1)))
										{
											*(ptr2++)=*ptr1;
										}
										*(ptr2)=0;
									}
								}	
							}
						}
					}
					ptr2=strchr(line,'=');
					ptr2++;
					entr->type=i;
					if((i==TYP_TXTHTML) || (i==TYP_TEXTPAGE) || (i==TYP_TXTPLAIN))
					{
						entr->pictype=i;
					}
					entr->entry=strdup(ptr2);
					entr->headerpos=pos;
					m->num_entrys++;
					found=1;
				}
			}
		}
	}
	return !found || (found && pfound);
}

int Get_Menu(void)
{
int rv=-1, loop=1, mlevel=0, clevel=0, pos=0;
char *pt1;
FILE *fh;

	Clear_List(&menu,1);
	if((fh=fopen(TCF_FILE,"r"))!=NULL)
	{
		loop=1;
		while((loop==1) && fgets(line_buffer, BUFSIZE, fh))
		{
			TrimString(line_buffer);
			pt1=strstr(line_buffer,TYPESTR[TYP_MENU]);
			if(pt1 && (pt1==line_buffer))
			{
				if(pos==menu.act_header)
				{
					clevel=menu.headerlevels[pos];
					loop=0;
				}
				mlevel++;
				pos++;
			}
			else
			{
				pt1=strstr(line_buffer,TYPESTR[TYP_ENDMENU]);
				if(pt1 && (pt1==line_buffer))
				{
					mlevel--;
				}
			}
		}
		if(loop)
		{
			return rv;
		}
		
		--pos;
		--mlevel;
		loop=1;
		while((loop==1) && fgets(line_buffer, BUFSIZE, fh))
		{
			TrimString(line_buffer);
			pt1=strstr(line_buffer,TYPESTR[TYP_MENU]);
			if(pt1 && (pt1==line_buffer))
			{
				pos++;
				if(mlevel==clevel)
				{
					AddListEntry(&menu, line_buffer, pos);
					rv=0;
				}
				mlevel++;
			}
			pt1=strstr(line_buffer,TYPESTR[TYP_ENDMENU]);
			if(pt1 && (pt1==line_buffer))
			{
				mlevel--;
			}
			else
			{
				if(mlevel==clevel)
				{
					AddListEntry(&menu, line_buffer, pos);
					rv=0;
				}
			}
			if(mlevel<clevel)
			{
				loop=0;
			}
		}
	fclose(fh);
	}

	return rv;
}

/******************************************************************************
 * ShowInfo
 ******************************************************************************/

#define XX 0xA7
#define XL 58

void ShowInfo(MENU *m)
{
	int scrollbar_len, scrollbar_ofs, scrollbar_cor, loop;
	int index=m->act_entry,tind=m->act_entry, sbw=(m->num_entrys>10)?14:0;
	char tstr[BUFSIZE], *tptr;
	int moffs=35, ixw=400, iyw=(m->num_entrys<10)?((m->num_entrys+1)*30+moffs):375, dy, my, mh=iyw-moffs-radius-8, toffs, soffs=4, isx, isy;
	dy=(m->num_entrys<10)?30:(mh/11);
	toffs=dy/2;
	my=moffs+dy+toffs;
	
	Center_Screen(ixw, iyw, &isx, &isy);

	tind=index;
	
	//frame layout
	RenderBox(isx, isy, ixw, iyw, radius, CMC);
//	RenderBox(0, 0, ixw, iyw, GRID, CMCS);

	// titlebar
	RenderBox(isx+2, isy+2, ixw-2, moffs+5, radius, CMH);

	//selectbar
	RenderBox(isx+2, isy+moffs+toffs+soffs+(index%10)*dy+2, ixw-sbw-2, dy+2, radius, CMCS);


	if(sbw)
	{
		//sliderframe
		RenderBox(isx+ixw-sbw, isy+moffs+8, sbw, mh, radius, CMCP1);
		//slider
		scrollbar_len = (double)mh / (double)((m->num_entrys/LIST_STEP+1)*LIST_STEP);
		scrollbar_ofs = scrollbar_len*(double)((index/LIST_STEP)*LIST_STEP);
		scrollbar_cor = scrollbar_len*(double)LIST_STEP;
		RenderBox(isx+ixw-sbw, isy+moffs + scrollbar_ofs+8, sbw,  scrollbar_cor , radius, CMCP3);
	}

	// Title text
	RenderString(m->headertxt[m->act_header], isx+45, isy+dy-soffs+3, ixw-sbw, LEFT, FSIZE_BIG, CMHT);

	index /= 10;
	//Show table of commands
	for(loop = index*10; (loop < (index+1)*10) && (loop < m->num_entrys); ++loop)
	{
		strcpy(tstr,m->list[loop]->entry);
		if((tptr=strchr(tstr,','))!=NULL)
		{
			*tptr=0;
		}
		RenderString(tstr, isx+45, isy+my, ixw-sbw-65, LEFT, FSIZE_MED, ((loop%10) == (tind%10))?CMCST:CMCT);
		if(m->list[loop]->type==TYP_MENU)
		{
			RenderString(">", isx+30, isy+my, 65, LEFT, FSIZE_MED, ((loop%10) == (tind%10))?CMCST:CMCT);
		}
		if(m->list[loop]->underline)
		{
			RenderBox(isx+10, isy+my+soffs+2, ixw-10-sbw, my+soffs+2, 0, CMCP3);
			RenderBox(isx+10, isy+my+soffs+3, ixw-10-sbw, my+soffs+3, 0, CMCP1);
		}

		switch(loop % 10)
		{
			case 0: RenderCircle(isx+9,isy+my-15,RED);    break;
			case 1: RenderCircle(isx+9,isy+my-15,GREEN);  break;
			case 2: RenderCircle(isx+9,isy+my-15,YELLOW); break;
			case 3: RenderCircle(isx+9,isy+my-15,BLUE0);  break;
/*
			case 0: PaintIcon("/share/tuxbox/neutrino/icons/rot.raw",9,my-17,1); break;
			case 1: PaintIcon("/share/tuxbox/neutrino/icons/gruen.raw",9,my-17,1); break;
			case 2: PaintIcon("/share/tuxbox/neutrino/icons/gelb.raw",9,my-17,1); break;
			case 3: PaintIcon("/share/tuxbox/neutrino/icons/blau.raw",9,my-17,1); break;
*/
			default:
				sprintf(tstr,"%1d",(loop % 10)-3);
				RenderString(tstr, isx+10, isy+my-1, 15, CENTER, FSIZE_SMALL, ((loop%10) == (tind%10))?CMCST:CMCT);
			break;

		}
		my += dy;
	}
	//copy backbuffer to framebuffer
	memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
}


/* Parse City-Code from Entry
 */

static int prs_get_city(void)
{
char *tptr;
int cpos;
int res;
int len;

	len=strlen(menu.list[menu.act_entry]->entry);

	if ((tptr=strchr(menu.list[menu.act_entry]->entry,','))!=NULL)
	{
		ShowInfo(&menu);
		if(!cmdline)
		{
			ShowMessage(prs_translate("Bitte warten",CONVERT_LIST),0);
		}
		cpos=(tptr-menu.list[menu.act_entry]->entry);
		strncpy(city_code,++tptr,len-cpos-1);
		strncpy(city_name,menu.list[menu.act_entry]->entry,cpos);
		city_name[cpos]=0;
		city_code[len-cpos-1]=0;
		printf("Tuxwetter <Citycode %s selected>\n",city_code);
		if((res=parser(city_code,CONVERT_LIST,metric,intype,ctmo))!=0)
		{
			ShowMessage((res==-1)?prs_translate("keine Daten vom Wetterserver erhalten!",CONVERT_LIST):prs_translate("Datei convert.list nicht gefunden",CONVERT_LIST),1);
			city_code[0]=0;
			return 1;
		}
	}
	else
	{
		ShowMessage(prs_translate("Ungültige Daten aus tuxwetter.conf",CONVERT_LIST),1);
		city_code[0]=0;
		return 1;
	}
	
	return 0;
}

void clear_screen(void)
{
//	for(; sy <= ey; sy++) memset(lbb + sx + var_screeninfo.xres*(sy),TRANSP, ex-sx + 1);
	memset(lbb, TRANSP, fix_screeninfo.line_length*var_screeninfo.yres);
	memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
}

	

void show_data(int index)
{
#ifndef WWEATHER
	char *pt1 = NULL;
	int itmp;
#endif

char vstr[512],v2str[512],rstr[512],tstr[512],icon[60];
int vy=70,col1=40,col2=340;

int wxw=ex-sx-10;		//box width 
int wyw=ey-sy;			//box height
int gys=vy;			//table space top
int gysf=34;			//table space bottom
int gxs=40;			//table space left
int gxw=((wxw-(gxs*2))/5) * 5;	//table width
int gywf=100;			//table footer height
int gyw=wyw-vy-gywf-gysf;	//table height
int gicw=gxw/5;			//table data width
int dy=26;			//linespace
int vxs=0,wsx,wsy;
int tret=0;
int prelate=0;
int rcd;
int HMED=22;
int slim=0;			//using 720x576
time_t atime;
struct tm *sltime;
char tun[2]="C",sun[5]="km/h",dun[3]="km",pun[5]="mbar",cun[20];

	if(var_screeninfo.xres < 800)
		slim=1;

	clear_screen();

	Center_Screen(wxw, wyw, &wsx, &wsy);
	gxs+=wsx;
	gys+=wsy;
	gyw+=wsy;
	col1+=wsx;
	col2+=wsx;
	vy+=wsy;

	//frame layout
	if(index!=1)
	{
		RenderBox(wsx, wsy, wxw, wyw, radius, CMC);
		RenderBox(wsx+2, wsy+2, wxw-2, 44, radius, CMH);
	}
	else
	{
		if(!cmdline)
		{
			ShowMessage(prs_translate("Bitte warten",CONVERT_LIST),0);
		}
	}

	strcpy(cun,prs_translate("Uhr",CONVERT_LIST));
	if(!metric)
	{
		sprintf(tun,"F");
		sprintf(sun,"mph");
		sprintf(dun,"mi");
		sprintf(pun,"in");
		*cun=0;
	}
	if(index==-99)
	{
		int i;
		unsigned char grstr[XL+1]={'G'^XX,'r'^XX,'\xFC'^XX,'\xDF'^XX,'e'^XX,' '^XX,'v'^XX,'o'^XX,'m'^XX,' '^XX,'N'^XX,'e'^XX,'w'^XX,'-'^XX,'T'^XX,'u'^XX,'x'^XX,'w'^XX,'e'^XX,'t'^XX,'t'^XX,'e'^XX,'r'^XX,'-'^XX,'T'^XX,'e'^XX,'a'^XX,'m'^XX,'!'^XX,' '^XX,' '^XX,';'^XX,'-'^XX,')'^XX,' '^XX,' '^XX,'w'^XX,'w'^XX,'w'^XX,'.'^XX,'k'^XX,'e'^XX,'y'^XX,'w'^XX,'e'^XX,'l'^XX,'t'^XX,'-'^XX,'b'^XX,'o'^XX,'a'^XX,'r'^XX,'d'^XX,'.'^XX,'c'^XX,'o'^XX,'m'^XX,0};

		sprintf(rstr,"CS-Tuxwetter    Version %s",P_VERSION);
		RenderString(rstr, 0, 34, wxw, CENTER, FSIZE_BIG, CMHT);

		sprintf(rstr,"%s",prs_translate("Steuertasten in den Menüs",CONVERT_LIST));
		RenderString(rstr, 0, vy, wxw, CENTER, HMED, GREEN);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("Farbtasten Rot, Grün, Gelb, Blau",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("Direktanwahl Funktionen 1-4",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("Zifferntasten 1-6",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("Direktanwahl Funktionen 5-10",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("Hoch",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("vorheriger Menüeintrag",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("Runter",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("nächster Menüeintrag",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("PgDown (bei mehrseitigen Menüs)",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("eine Seite vorblättern",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("PgUp (bei mehrseitigen Menüs)",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("eine Seite zurückblättern",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("OK",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("Menüpunkt ausführen",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("Home",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("zurück zum vorigen Menü",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("MENU-Taste (im Hauptmenü)",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("fehlende Übersetzungen anzeigen",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("Standby-Taste",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("CS-Tuxwetter beenden",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=(1.5*(double)dy);

		sprintf(rstr,"%s",prs_translate("Steuertasten in Datenanzeige",CONVERT_LIST));
		RenderString(rstr, 0, vy, wxw, CENTER, HMED, GREEN);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("Hoch",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("vorherigen Eintrag anzeigen",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("Runter",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("nächsten Eintrag anzeigen",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;
/*
		sprintf(rstr,"%s",prs_translate("Links (in Bildanzeige)",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("neu downloaden (für WebCams)",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("Rechts (bei Ani-GIF's)",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("Animation wiederholen",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;
*/
		sprintf(rstr,"%s",prs_translate("Rot (in fehlenden Übersetzungen)",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("Fehlliste löschen",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=dy;

		sprintf(rstr,"%s",prs_translate("OK / Home",CONVERT_LIST));
		RenderString(rstr, col1, vy, col2-col1, LEFT, HMED, CMCT);
		sprintf(rstr,"%s",prs_translate("Aktuelle Anzeige schließen",CONVERT_LIST));
		RenderString(rstr, col2, vy, wxw-col2, LEFT, HMED, CMCT);
		vy+=(1.5*(double)dy);

		for(i=0; i<(XL-1); i++)
			{
				grstr[i]^=XX;
			}
		RenderString(grstr, 0, vy, wxw, CENTER, HMED, CMHT);
		memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
		rcd=GetRCCode();
		while((rcd != KEY_OK) && (rcd != KEY_EXIT))
		{
			rcd=GetRCCode();
		}
	}
	else
	{
		if(index==1)
		{
			int i, tmax[7], tmin[7], mint=100, maxt=-100, j, pmin, pmax;
			double tstep=1, garr[70], tv1, tv2, tv3;

			RenderBox(wsx, wsy, wxw, wyw, radius, CMC);
			RenderBox(wsx, wsy, wxw, 44, radius, CMH);
			sprintf(rstr,"%s",prs_translate("Trend für die kommende Woche",CONVERT_LIST));
			RenderString(rstr, wsx, wsy+34, wxw, CENTER, FSIZE_BIG, CMHT);
			RenderLine(gxs,gys,gxs,gys+gyw+gywf,CMCIT);
			RenderLine(gxs+1,gys,gxs+1,gys+gyw+gywf,CMCIT);
			for(i=0; i<5; i++)
			{
				prs_get_val(i, PRE_TEMPH,0,vstr);
				if(sscanf(vstr,"%d",&tmax[i])!=1)
				{
					if(!i)
					{
						vxs=1;
						tmax[i]=0;
					}
					else
					{
						tmax[i]=tmax[i-1];
					}
				}
				prs_get_val(i, PRE_TEMPL,0,vstr);
				if(sscanf(vstr,"%d",&tmin[i])!=1)
				{
					tmin[i]=(i)?tmin[i-1]:0;
				}
				if(tmin[i]<mint)
				{
					mint=tmin[i];
				}
				if((i || !vxs)  && tmax[i]<mint)
				{
					mint=tmax[i];
				}
				if((i || !vxs)  && tmax[i]>maxt)
				{
					maxt=tmax[i];
				}
				if(tmin[i]>maxt)
				{
					maxt=tmin[i];
				}
				if(!show_icons)
				{
#ifdef WWEATHER
					prs_get_dwday(i, PRE_DAY,vstr);
					strcat(vstr,"_SIG");
#else
					prs_get_day(i, vstr, metric);
					if((pt1=strchr(vstr,','))!=NULL)
					{
						strcpy(pt1,"_SIG");
					}
#endif
					strcpy(rstr,prs_translate(vstr,CONVERT_LIST));
					RenderString(rstr, gxs+i*gicw, gys+gyw+(FSIZE_BIG/2+gywf/2), gicw, CENTER, FSIZE_BIG, CMCT);//weekday
				}
				RenderLine(gxs+(i+1)*gicw,gys,gxs+(i+1)*gicw,gys+gyw+gywf,CMCIT);
			}
			RenderLine(gxs+i*gicw+1,gys,gxs+i*gicw+1,gys+gyw+gywf,CMCIT);
			tstep=(5*(1+(int)((maxt-mint)/5))+1);
			tstep=(double)(gyw-5)/tstep;

			RenderLine(gxs,gys,gxs,gys+gyw,CMCIT);
			RenderLine(gxs+1,gys,gxs+1,gys+gyw,CMCIT);
			RenderLine(gxs+2,gys,gxs+2,gys+gyw,CMCIT);
			RenderLine(gxs,gys+gyw,gxs+gxw,gys+gyw,CMCIT);
			RenderLine(gxs,gys+gyw+1,gxs+gxw,gys+gyw+1,CMCIT);
			RenderLine(gxs,gys+gyw+2,gxs+gxw,gys+gyw+2,CMCIT);
			RenderLine(gxs,gys+gyw+gywf,gxs+gxw,gys+gyw+gywf,CMCIT);
			RenderLine(gxs,gys+gyw+gywf+1,gxs+gxw,gys+gyw+gywf+1,CMCIT);
			RenderString(prs_translate("Höchstwerte",CONVERT_LIST), gxs, gys, gxw/2, CENTER, FSIZE_SMALL, YELLOW);
			RenderString(prs_translate("Tiefstwerte",CONVERT_LIST), gxs+(gxw/2), gys, gxw/2, CENTER, FSIZE_SMALL, GREEN);

			for(i=1; i<=(5*(1+(int)((maxt-mint)/5))+1); i++)
			{
				if(i)
				{
//					RenderLine(gxs,gys+gyw-(i*tstep)-1,gxs+gxw,gys+gyw-(i*tstep)-1,((!(mint+i-1)))?CMCT:CMCIT);
					RenderLine(gxs,gys+gyw-(i*tstep)-2,gxs+gxw,gys+gyw-(i*tstep)-2,((!(mint+i-1)))?CMCT:CMCIT);
					if(!((mint+i-1)%5))
					{
						RenderLine(gxs,gys+gyw-(i*tstep)-3,gxs+gxw,gys+gyw-(i*tstep)-3,((!(mint+i-1)))?CMCT:CMCIT);
					}
					RenderLine(gxs,gys+gyw-(i*tstep)-1,gxs+gxw,gys+gyw-(i*tstep)-1,CMCP3);
				}
				sprintf(vstr,"%d",mint+i-1);
				RenderString(vstr,gxs-35,gys+gyw-(i*tstep)+7, 30, RIGHT, FSIZE_VSMALL, CMCT);
				RenderString(vstr,gxs+gxw+2,gys+gyw-(i*tstep)+7, 30, RIGHT, FSIZE_VSMALL, CMCT);
			}
			RenderLine(gxs,gys+gyw-((i-1)*tstep)-3,gxs+gxw,gys+gyw-((i-1)*tstep)-3,((!(mint+i-1)))?CMCT:CMCIT);

// Geglättete Kurven

			for(i=0; i<5; i++)
			{
				tv1=tmin[i];
				tv2=tmin[i+1];
				for(j=0; j<10; j++)
				{
					tv3=j-2;
					if(j<2)
					{
						garr[i*10+j]=tv1;
					}
					else
					{
						if(j>7)
						{
							garr[i*10+j]=tv2;
						}
						else
						{
							garr[i*10+j]=((tv1*(6.0-tv3))+(tv2*tv3))/6.0;
						}
					}
				}
			}
			for(i=2; i<39; i++)
			{
				garr[i]=(garr[i-2]+garr[i-1]+garr[i]+garr[i+1]+garr[i+2])/5.0;
			}
			for(i=1; i<=40; i++)
			{
				pmin=(gys+gyw)-(garr[i-1]-mint+1)*tstep-1;
				pmax=(gys+gyw)-(garr[i]-mint+1)*tstep-1;
				RenderLine(gxs+gicw/2+((i-1)*(gicw/10)),pmin,gxs+gicw/2+i*(gicw/10),pmax,GREEN);
				RenderLine(gxs+gicw/2+((i-1)*(gicw/10)),pmin+1,gxs+gicw/2+i*(gicw/10),pmax+1,GREEN);
				RenderLine(gxs+gicw/2+((i-1)*(gicw/10)),pmin+2,gxs+gicw/2+i*(gicw/10),pmax+2,GREEN);
			}
			for(i=vxs; i<5; i++)
			{
				tv1=tmax[i];
				tv2=tmax[i+1];
				for(j=0; j<10; j++)
				{
					tv3=j-2;
					if(j<2)
					{
						garr[i*10+j]=tv1;
					}
					else
					{
						if(j>7)
						{
							garr[i*10+j]=tv2;
						}
						else
						{
							garr[i*10+j]=((tv1*(6.0-tv3))+(tv2*tv3))/6.0;
						}
					}
				}
			}
			for(i=2+10*vxs; i<39; i++)
			{
				garr[i]=(garr[i-2]+garr[i-1]+garr[i]+garr[i+1]+garr[i+2])/5.0;
			}
			for(i=1+10*vxs; i<=40; i++)
			{
				pmin=(gys+gyw)-(garr[i-1]-mint+1)*tstep-1;
				pmax=(gys+gyw)-(garr[i]-mint+1)*tstep-1;
				RenderLine(gxs+gicw/2+((i-1)*(gicw/10)),pmin,gxs+gicw/2+i*(gicw/10),pmax,YELLOW);
				RenderLine(gxs+gicw/2+((i-1)*(gicw/10)),pmin+1,gxs+gicw/2+i*(gicw/10),pmax+1,YELLOW);
				RenderLine(gxs+gicw/2+((i-1)*(gicw/10)),pmin+2,gxs+gicw/2+i*(gicw/10),pmax+2,YELLOW);
			}

//	Ungeglättete Kurven
/*
			for(i=1; i<7; i++)
			{
				{
					pmin=(gys+gyw)-(tmin[i-1]-mint+1)*tstep-1;
					pmax=(gys+gyw)-(tmin[i]-mint+1)*tstep-1;
					RenderLine(gxs+gicw/2+gicw*(i-1),pmin,gxs+gicw/2+gicw*i,pmax,GREEN);
					RenderLine(gxs+gicw/2+gicw*(i-1),pmin+1,gxs+gicw/2+gicw*i,pmax+1,GREEN);
					pmin=(gys+gyw)-(tmax[i-1]-mint+1)*tstep-1;
					pmax=(gys+gyw)-(tmax[i]-mint+1)*tstep-1;
					RenderLine(gxs+gicw/2+gicw*(i-1),pmin,gxs+gicw/2+gicw*i,pmax,YELLOW);
					RenderLine(gxs+gicw/2+gicw*(i-1),pmin+1,gxs+gicw/2+gicw*i,pmax+1,YELLOW);
				}
			}
*/	

//			memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres);

			if(show_icons)
			{
				for(i=0; i<5; i++)
				{
					prs_get_val(i,PRE_ICON,prelate,vstr);
#ifdef WWEATHER
					if (HTTP_downloadFile(vstr, ICON_FILE, 0, intype, ctmo, 2) == 0)
#else
					sprintf  (icon,"http://image.weather.com/web/common/intlwxicons/52/%s.gif",vstr);
					if (HTTP_downloadFile(icon, ICON_FILE, 0, intype, ctmo, 2) == 0)
#endif
					{
						int picx=80,picy=80;
						tret=pic_on_data(icon,sx+gxs+(i*gicw)+((gicw/2)-(picx/2)),sy+gys+gyw+((gywf/2)-(picy/2)), picx, picy, 5, (i)?((i==4)?1:0):2, 0, 0);
					}
					prs_get_dwday(i, PRE_DAY,vstr);
					strcat(vstr,"_SIG");
					strcpy(rstr,prs_translate(vstr,CONVERT_LIST));
					RenderString(rstr, gxs+(i*gicw+17), gys+gyw+FSIZE_BIG+5, gicw, LEFT, FSIZE_BIG,CMCT );//weekday
				}
			}

			memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
		}
		else
		{
			if(index==0)
			{
				dy=24;
				vy-=2;

				// show icon
				prs_get_val(0, ACT_ICON, 0, vstr);
#if 0
				sprintf (rstr,"%s.bmp",vstr);
				bmp2lcd (rstr);
#endif
				if(show_icons)
				{
					xremove(ICON_FILE);
#ifdef WWEATHER
					if (HTTP_downloadFile(vstr, ICON_FILE, 0, intype, ctmo, 2) != 0) 
#else
					sprintf  (icon,"http://image.weather.com/web/common/intlwxicons/52/%s.gif",vstr);
					if (HTTP_downloadFile(icon, ICON_FILE, 0, intype, ctmo, 2) != 0)
#endif
					{
						printf("Tuxwetter <unable to get icon>\n");
					}
				}

				sprintf(rstr,"%s",prs_translate("Aktuelles Wetter",CONVERT_LIST));
				RenderString(rstr, 0, 34, wxw, CENTER, FSIZE_BIG, CMHT);

				sprintf(rstr,"%s",prs_translate("Standort:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, GREEN);
#ifdef WWEATHER
				prs_get_val(0, ACT_CITY, 0, vstr);
				RenderString(vstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
#else
				sprintf(rstr,"%s",city_name);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
#endif
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Längengrad:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_dbl(0, ACT_LON, 0, vstr);
				sprintf(rstr,"%s",vstr);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Breitengrad:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_dbl(0, ACT_LAT, 0, vstr);
				sprintf(rstr,"%s",vstr);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Ortszeit:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_time(0, ACT_TIME, vstr, metric);
				sprintf(rstr,"%s %s",vstr,cun);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Aktuelle Uhrzeit:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
//				prs_get_time(0, ACT_TIME, vstr);
				time(&atime);
				sltime=localtime(&atime);
				if(metric)
				{
					sprintf(rstr,"%02d:%02d %s",sltime->tm_hour,sltime->tm_min,cun);
				}
				else
				{
					sprintf(rstr,"%02d:%02d %s",(sltime->tm_hour)?((sltime->tm_hour>12)?sltime->tm_hour-12:sltime->tm_hour):12,sltime->tm_min,(sltime->tm_hour>=12)?"PM":"AM");
				}
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Zeitpunkt der Messung:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				prs_get_time(0, ACT_UPTIME, vstr, metric);
#else
				prs_get_dtime(0, ACT_UPTIME, vstr, metric);
#endif
				sprintf(rstr,"%s %s",vstr,cun);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=(1.5*(double)dy);

				sprintf(rstr,"%s",prs_translate("Bedingung:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, GREEN);
				prs_get_val(0, ACT_COND, 0, vstr);
				sprintf(rstr,"%s",vstr);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Temperatur:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(0, ACT_TEMP, 0, vstr);
#ifdef WWEATHER
				sprintf(rstr,"%s °%s",vstr,tun);
#else
				prs_get_val(0, ACT_FTEMP, 0, v2str);
				sprintf(rstr,"%s °%s  %s %s °%s",vstr,tun,prs_translate("gefühlt:",CONVERT_LIST),v2str,tun);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Luftfeuchtigkeit:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(0, ACT_HMID, 0, vstr);
				sprintf(rstr,"%s %%",vstr);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Taupunkt:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_val(0, ACT_DEWP, 0, vstr);
				sprintf(rstr,"%s °%s",vstr,tun);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Luftdruck:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(0, ACT_PRESS, 0, vstr);
#ifdef WWEATHER
				RenderString(vstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
#else
				prs_get_val(0, ACT_PRTEND, 0, v2str);
				sprintf(rstr,"%s %s  %s",vstr,pun,v2str);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
#endif
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Wind:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(0, ACT_WINDD, 0, vstr);
				prs_get_val(0, ACT_WSPEED, 0, v2str);
				if((strstr(vstr,"windstill")!=NULL) || (strstr(v2str,"CALM")!=NULL))
				{
					sprintf(rstr,"%s",prs_translate("windstill",CONVERT_LIST));
				}
				else
				{
					sprintf(tstr,"%s",prs_translate("von",CONVERT_LIST));
					sprintf(rstr,"%s %s %s %s %s",tstr,vstr,prs_translate("mit",CONVERT_LIST),v2str,sun);
				}
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=(1.5*(double)dy);

				sprintf(rstr,"%s",prs_translate("Sonnenaufgang:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_time(0, ACT_SUNR, vstr,metric);
				sprintf(rstr,"%s %s",vstr,cun);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Sonnenuntergang:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_time(0, ACT_SUNS, vstr,metric);
				sprintf(rstr,"%s %s",vstr,cun);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;
#ifdef WWEATHER
				sprintf(rstr,"%s",prs_translate("Bewölkung:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(0, ACT_CLOUDC, 0, v2str);
				sprintf(rstr,"%s %%",v2str);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;
#else
				sprintf(rstr,"%s",prs_translate("Mondphase:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(0, ACT_MOON, 0, v2str);
				sprintf(rstr,"%s",v2str);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;			
#endif
				sprintf(rstr,"%s",prs_translate("Fernsicht:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(0, ACT_VIS, 0, vstr);
#ifdef WWEATHER
				sprintf(rstr,"%s %s",vstr,dun);
#else
				if(sscanf(vstr,"%d",&itmp)==1)
				{
					sprintf(rstr,"%s %s",vstr,dun);
				}
				else
				{
					strcpy(rstr,vstr);
				}
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;
#ifdef WWEATHER
				sprintf(rstr,"%s",prs_translate("Niederschlag:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(0, ACT_PRECIPMM, 0, vstr);
				sprintf(rstr,"%s mm",vstr);
#else
				sprintf(rstr,"%s",prs_translate("UV-Index:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);

				prs_get_val(0, ACT_UVIND, 0, vstr);
				prs_get_val(0, ACT_UVTEXT, 0, v2str);
				sprintf(rstr,"%s  %s",vstr,v2str);

				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Regenrisiko:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(0, PRE_PPCP, 0, vstr);
				sprintf(rstr,"%s %%",vstr);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

//				memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres);

				if(show_icons)
				{
					//tret=pic_on_data(icon, 540, 115, 100, 100, 5, 3, 0, 0);
					if(!slim)
						tret=pic_on_data(icon,700, 115, 100, 100, 5, 3, 0, 0);
					else
						tret=pic_on_data(icon,540, 115, 80, 80, 5, 3, 0, 0);
				}

				memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
			}
			else
			{
				--index;
				if(index==1)
				{
					prs_get_val(index-1, PRE_TEMPH, 0, vstr);
					if(strstr(vstr,"N/A")!=NULL)
					{
						prelate=1;
					}
				}


				// show icon
				prs_get_val(index-1,PRE_ICON,prelate,vstr);
#if 0
				sprintf (rstr,"%s.bmp",vstr);
				bmp2lcd (rstr);
#endif
				if(show_icons)
				{
					xremove(ICON_FILE);
#ifdef WWEATHER
					if (HTTP_downloadFile(vstr, ICON_FILE, 0, intype, ctmo, 2) != 0) 
#else
					sprintf  (icon,"http://image.weather.com/web/common/intlwxicons/52/%s.gif",vstr);
					if (HTTP_downloadFile(icon, ICON_FILE,0,intype,ctmo,2) != 0)
#endif
					{
						printf("Tuxwetter <unable to get icon file \n");
					}
				}

				if(index==1)
				{
					sprintf(vstr,"%s",prs_translate("Heute",CONVERT_LIST));
				}
				else
				{
#ifdef WWEATHER
					prs_get_dwday(index-1, PRE_DAY,rstr);
					sprintf(vstr,"%s",prs_translate(rstr,CONVERT_LIST));
#else
					prs_get_day(index-1, vstr, metric);
#endif
				}
				sprintf(rstr,"%s %s",prs_translate("Vorschau für",CONVERT_LIST),vstr);
				RenderString(rstr, 0, 34, wxw, CENTER, FSIZE_BIG, CMHT);

				sprintf(rstr,"%s",prs_translate("Standort:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, GREEN);
				sprintf(rstr,"%s",city_name);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=(1.5*(double)dy);

				sprintf(rstr,"%s",prs_translate("Höchste Temperatur:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(index-1,PRE_TEMPH,0,vstr);
				sprintf(rstr,"%s °%s",vstr,tun);
				RenderString((prelate)?"---":rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Tiefste Temperatur:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(index-1,PRE_TEMPL,0,vstr);
				sprintf(rstr,"%s °%s",vstr,tun);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Sonnenaufgang:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_time(index-1, PRE_SUNR,vstr,metric);
				sprintf(rstr,"%s %s",vstr,cun);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Sonnenuntergang:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_time(index-1, PRE_SUNS,vstr,metric);
				sprintf(rstr,"%s %s",vstr,cun);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=(1.5*(double)dy);

				RenderString(prs_translate("Tageswerte",CONVERT_LIST), col1, vy, col2-col1, LEFT, FSIZE_MED, GREEN);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Bedingung:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
				prs_get_val(index-1, PRE_COND, 0, vstr);
				sprintf(rstr,"%s",vstr);
				RenderString((prelate)?"---":rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Wind:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);

				prs_get_val(index-1, PRE_WINDD, 0, vstr);
				prs_get_val(index-1, PRE_WSPEED, 0, v2str);
				sprintf(tstr,"%s",prs_translate("von",CONVERT_LIST));
				sprintf(rstr,"%s %s %s %s %s",tstr,vstr,prs_translate("mit",CONVERT_LIST),v2str,sun);

				RenderString((prelate)?"---":rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Luftfeuchtigkeit:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_val(index-1, PRE_HMID, 0, vstr);
				sprintf(rstr,"%s %%",vstr);
#endif
				RenderString((prelate)?"---":rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;
#ifdef WWEATHER
				sprintf(rstr,"%s",prs_translate("Niederschlag:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);

				prs_get_val(index-1, PRE_PRECIPMM, 0, vstr);
				sprintf(rstr,"%s mm",vstr);
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
#else
				sprintf(rstr,"%s",prs_translate("Regenrisiko:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);

				prs_get_val(index-1, PRE_PPCP, 0, vstr);
				sprintf(rstr,"%s %%",vstr);

				RenderString((prelate)?"---":rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
#endif
				vy+=(1.5*(double)dy);

				RenderString(prs_translate("Nachtwerte",CONVERT_LIST), col1, vy, col2-col1, LEFT, FSIZE_MED, GREEN);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Bedingung:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_val(index-1, PRE_COND, 1, vstr);
				sprintf(rstr,"%s",vstr);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Wind:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_val(index-1, PRE_WINDD, 1, vstr);
				prs_get_val(index-1, PRE_WSPEED, 1, v2str);
				if((strstr(vstr,"windstill")!=NULL) || (strstr(v2str,"CALM")!=NULL))
				{
					sprintf(rstr,"%s",prs_translate("windstill",CONVERT_LIST));
				}	
				else
				{
					sprintf(tstr,"%s",prs_translate("von",CONVERT_LIST));
					sprintf(rstr,"%s %s %s %s %s",tstr,vstr,prs_translate("mit",CONVERT_LIST),v2str,sun);
				}
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Luftfeuchtigkeit:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_val(index-1, PRE_HMID, 1, vstr);
				sprintf(rstr,"%s %%",vstr);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

				sprintf(rstr,"%s",prs_translate("Regenrisiko:",CONVERT_LIST));
				RenderString(rstr, col1, vy, col2-col1, LEFT, FSIZE_MED, CMCT);
#ifdef WWEATHER
				sprintf(rstr,"---");
#else
				prs_get_val(index-1, PRE_PPCP, 1, vstr);
				sprintf(rstr,"%s %%",vstr);
#endif
				RenderString(rstr, col2, vy, wxw-col2, LEFT, FSIZE_MED, CMCT);
				vy+=dy;

//				memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres);

				if(show_icons)
				{
					//tret=pic_on_data(icon, 540, 115, 100, 100, 5, 3, 0, 0);
					tret=pic_on_data(icon,slim?540:700, 115, 100, 100, 5, 3, 0, 0);
				}

				memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
			}
		}
	}
}

void scale_pic(unsigned char **buffer, int x1, int y1, int xstart, int ystart, int xsize, int ysize,
			   int *imx, int *imy, int *dxp, int *dyp, int *dxo, int *dyo, int center)
{
	float xfact=0, yfact=0;
	int txsize=0, tysize=0;
	int tempx =0, tempy=0;
	int txstart =xstart, tystart= ystart;
	
	if (xsize > (ex-xstart)) txsize= (ex-xstart);
	else  txsize= xsize; 
	if (ysize > (ey-ystart)) tysize= (ey-ystart);
	else tysize=ysize;
	xfact= 1000*txsize/x1;
	xfact= xfact/1000;
	yfact= 1000*tysize/y1;
	yfact= yfact/1000;
	
	if ( xfact <= yfact)
	{
		*imx=(int)x1*xfact;
		*imy=(int)y1*xfact;
		if (center !=0) 
		{
			tystart=(ey-sy)-*imy;
			tystart=tystart/2;
			tystart=tystart+ystart;
		}
	}
	else
	{
		*imx=(int)x1*yfact;
		*imy=(int)y1*yfact;
		if (center !=0) 
		{
			txstart=(ex-sx)-*imx;
			txstart=txstart/2;
			txstart=txstart+xstart;
		}
	}
	tempx=*imx;
	tempy=*imy;
	*buffer=(char*)color_average_resize(*buffer,x1,y1,*imx,*imy);

	*dxp=0;
	*dyp=0;
	*dxo=txstart;
	*dyo=tystart;
}

void close_jpg_gif_png(void)
{
#if 0
	// clear Display	
	fb_set_gmode(0);
//	memcpy(&otr,&rtr,256);
	ioctl(fb, FBIOPUTCMAP, oldcmap);
//	for(; sy <= ey; sy++) memset(lbb + sx + var_screeninfo.xres*(sy),TRANSP, ex-sx + 1);
	memset(lbb, TRANSP, var_screeninfo.xres*var_screeninfo.yres);
	memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
	gmodeon=0; 
#endif
}

int wait_image(int repeat, int first)
{
time_t t1,t2;
int rv;

	if(!repeat)
	{
		rv=GetRCCode();
		return rv;
	}
	time(&t1);
	t2=t1;
	while((t2-t1)<repeat)
	{
		rv=GetRCCode();
		if(rv==-1)
		{
			usleep(200000L);
			time(&t2);
		}
		else
		{
			return rv;
		}
	}
	
	return KEY_LEFT;
}

int show_jpg(char *name, int xstart, int ystart, int xsize, int ysize, int wait, int repeat, int single, int center)
{
FILE *tfh;
int x1,y1,rcj,rv=-1;
int imx = -1,imy = -1,dxo = -1,dyo = -1,dxp = -1,dyp = -1;
unsigned char *buffer=NULL;

	if((tfh=fopen(name,"r"))!=NULL)
	{
		fclose(tfh);
		if(fh_jpeg_getsize(name, &x1, &y1, xsize, ysize))
		{
			printf("Tuxwetter <invalid JPG-Format>\n");
			return -1;
		}
		if((buffer=(unsigned char *) malloc(x1*y1*4))==NULL)
		{
			printf(NOMEM);
			return -1;
		}
		if(!(rv=fh_jpeg_load(name, buffer, x1, y1)))
		{
			scale_pic(&buffer,x1,y1,xstart,ystart,xsize,ysize,&imx,&imy,&dxp,&dyp,&dxo,&dyo,center);
			//fb_set_gmode(1);
			fb_display(buffer, imx, imy, dxp, dyp, dxo, dyo, 1, 1);
			gmodeon=1;
		}
		free(buffer);
		
		if(!rv && wait)
		{
			rcj=wait_image(repeat, 1);
			while((rcj != KEY_OK) && (rcj != KEY_EXIT) && (rcj != KEY_DOWN) && (rcj != KEY_LEFT) && (rcj != KEY_UP) && (rcj != KEY_VOLUMEUP) && (rcj != KEY_VOLUMEDOWN))
			{
				rcj=wait_image(repeat, 0);
			}
			if(single || (rcj==KEY_OK) || (rcj==KEY_EXIT))
			{
				close_jpg_gif_png();
			}
			else
			{
				showBusy(startx+3,starty+3,10,0xff,00,00);
//				showBusy(startx+10,starty+10,20,170,0,0);
				if(rcj==KEY_EXIT)
				{
					rcj=KEY_OK;
				}
				return rcj;
			}
		}
	}
	
	return (rv)?-1:0;	
}

int show_png(char *name, int xstart, int ystart, int xsize, int ysize, int wait, int repeat, int single, int center)
{
FILE *tfh;
int x1,y1,rcn,rv=-1;
int imx,imy,dxo,dyo,dxp,dyp;
unsigned char *buffer=NULL;

	if((tfh=fopen(name,"r"))!=NULL)
	{
		fclose(tfh);
		if(fh_png_getsize(name, &x1, &y1, xsize, ysize))
		{
			printf("Tuxwetter <invalid PNG-Format>\n");
			return -1;
		}
		if((buffer=(unsigned char *) malloc(x1*y1*4))==NULL)
		{
			printf(NOMEM);
			return -1;
		}
		if(!(rv=fh_png_load(name, buffer, x1, y1)))
		{
			scale_pic(&buffer,x1,y1,xstart,ystart,xsize,ysize,&imx,&imy,&dxp,&dyp,&dxo,&dyo,center);
			fb_set_gmode(1);
			fb_display(buffer, imx, imy, dxp, dyp, dxo, dyo, 1, 1);
			gmodeon=1;
		}
		free(buffer);
		
		if(!rv && wait)
		{
			rcn=wait_image(repeat, 1);
			while((rcn != KEY_OK) && (rcn != KEY_EXIT) && (rcn != KEY_DOWN) && (rcn != KEY_LEFT) && (rcn != KEY_UP) && (rcn != KEY_VOLUMEUP) && (rcn != KEY_VOLUMEDOWN))
			{
				rcn=wait_image(repeat, 0);
			}
			if(single || (rcn==KEY_OK) || (rcn==KEY_EXIT))
			{
				close_jpg_gif_png();
			}
			else
			{
				showBusy(startx+3,starty+3,10,0xff,00,00);
//				showBusy(startx+10,starty+10,20,170,0,0);
				if(rcn==KEY_EXIT)
				{
					rcn=KEY_OK;
				}
				return rcn;
			}
		}
	}
	
	return (rv)?-1:0;	
}

static int gifs=0;

int show_gif(char *name, int xstart, int ystart, int xsize, int ysize, int wait, int repeat, int single, int center, int nodecomp)
{
FILE *tfh;
int x1,y1,rcg,count,cloop,rv=-1;
int imx,imy,dxo,dyo,dxp,dyp;
char *buffer=NULL, fname[512];

	if((tfh=fopen(name,"r"))!=NULL)
	{
		fclose(tfh);
		if(nodecomp)
		{
			count=gifs;
		}
		else
		{		
			xremove("/tmp/tempgif.gif");
			gifs=count=gifdecomp(GIF_FILE, GIF_MFILE);
		}
		if(count<1)
		{
			printf("Tuxwetter <invalid GIF-Format>\n");
			return -1;
		}
		cloop=0;
		while(count--)
		{
			sprintf(fname,"%s%02d.gif",GIF_MFILE,cloop++);
			if(fh_gif_getsize(fname, &x1, &y1, xsize, ysize))
			{
				printf("Tuxwetter <invalid GIF-Format>\n");
				return -1;
			}
			if((buffer=(unsigned char *) malloc(x1*y1*4))==NULL)
			{
				printf(NOMEM);
				return -1;
			}
			if(!(rv=fh_gif_load(fname, buffer, x1, y1)))
			{
				scale_pic(&buffer,x1,y1,xstart,ystart,xsize,ysize,&imx,&imy,&dxp,&dyp,&dxo,&dyo,center);
				fb_set_gmode(1);
				fb_display(buffer, imx, imy, dxp, dyp, dxo, dyo, 1, 1);
				gmodeon=1;

				if(gifs>1)
				{
					sprintf(fname,"%s %2d / %d", prs_translate("Bild",CONVERT_LIST),cloop, gifs);
// 					LCD_draw_string(13, 9, fname);
// 					LCD_update();
				}
			}
			free(buffer);
		}
		
		if(!rv && wait)
		{
			rcg=wait_image(repeat, 1);
			while((rcg != KEY_OK) && (rcg != KEY_EXIT) && (rcg != KEY_DOWN) && (rcg != KEY_UP) && (rcg != KEY_VOLUMEUP) && (rcg != KEY_VOLUMEDOWN)&& (rcg != KEY_LEFT) && (rcg != KEY_RIGHT))
			{
				rcg=wait_image(repeat, 0);
			}
			if(single || (rcg==KEY_OK) || (rcg==KEY_EXIT))
			{
				close_jpg_gif_png();
			}
			else
			{
				showBusy(startx+3,starty+3,10,0xff,00,00);
//				showBusy(startx+10,starty+10,20,170,0,0);
				if(rcg==KEY_EXIT)
				{
					rcg=KEY_OK;
				}
				return rcg;
			}
		}
	}
	
	return (rv)?-1:0;	
}

int pic_on_data(char *url, int xstart, int ystart, int xsize, int ysize, int wait, int single, int center, int rahmen)
{
FILE *tfh;
int /*i,*/x1,y1,rv=-1;

int imx,imy,dxo,dyo,dxp,dyp;
unsigned char *buffer=NULL/*,*gbuf*/;
unsigned char *tbuf=lfb;

	if((tfh=fopen(ICON_FILE,"r"))!=NULL)
	{
		lfb=lbb;
#ifdef WWEATHER
		if(fh_png_getsize(ICON_FILE, &x1, &y1, xsize, ysize))
		{
			printf("Tuxwetter <invalid PNG-Format>\n");
			return -1;
		}
#else
		if(fh_gif_getsize(ICON_FILE, &x1, &y1, xsize, ysize))
		{
			printf("Tuxwetter <invalid GIF-Format>\n");
			return -1;
		}
#endif
		if((buffer=(unsigned char *) malloc(x1*y1*4))==NULL)
		{
			printf(NOMEM);
			return -1;
		}
#ifdef WWEATHER
		if(!(rv=fh_png_load(ICON_FILE, buffer, x1, y1)))
#else
		if(!(rv=fh_gif_load(ICON_FILE, buffer, x1, y1)))
#endif
		{
			scale_pic(&buffer,x1,y1,xstart,ystart,xsize,ysize,&imx,&imy,&dxp,&dyp,&dxo,&dyo,center);
			if (rahmen >0)
			{
				RenderBox(xstart+1-sx-rahmen, ystart-6-sy-rahmen,xstart+xsize+2-sx+rahmen,ystart+ysize-sy-6+rahmen, 0, CMCS);
//				memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
			}

			if(single & 2)
			{
				single &= ~2;
#if 0
// don't know what this is about
#ifndef HAVE_DREAMBOX_HARDWARE
				i=fix_screeninfo.line_length*var_screeninfo.yres;
				gbuf=lfb;
				while(i--)
					if(*gbuf >=127)
						*(gbuf++)-=127;
					else
						*(gbuf++)=11;
#endif
#endif
			}

			fb_display(buffer, imx, imy, dxp, dyp, dxo, dyo, 0, single);
#if 0
// don't know what this is about
			if(single & 1)
 			{
 				ioctl(fb, FBIOPUTCMAP, &spcmap);
 			}
#endif
			gmodeon=1;

		}
		free(buffer);
		lfb=tbuf;
	}
	return (rv)?-1:0;
}

int show_php(char *name, char *title, int plain, int highlite)
{
FILE *tfh;
int x1,y1,cs,rcp,rv=-1,run=1,line=0,action=1,cut;
int col1,sy=0,dy=26,psx,psy,pxw=/*620*/ex-sx,pyw=/*510*/ey-sy;

	Center_Screen(pxw,pyw,&psx,&psy);
	col1=psx+40;
	sy=psy+70;
	if((tfh=fopen(name,"r"))!=NULL)
	{
/*		if(gmodeon)
		{
			close_jpg_gif_png();
		}
*/		fclose(tfh);

		RenderString("X", psx+pxw/2, psy+pyw/2, 100, LEFT, FSIZE_SMALL, CMCT);
		if(fh_php_getsize(name, plain, &x1, &y1))
		{
			printf("Tuxwetter <invalid PHP-Format>\n");
			return -1;
		}
		cs=FSIZE_MED*((double)(pxw-1.5*(double)(col1-psx))/(double)x1);
		if(cs>FSIZE_MED)
		{
			cs=FSIZE_MED;
		}		

		dy=1.2*(double)cs;
		
		while(run)
		{
			//frame layout
			if(action)
			{
				RenderBox(psx, psy, pxw, pyw, radius, CMC);
				RenderBox(psx+2, psy+2, pxw-4, 44, radius, CMH);
				RenderString(title, psx, psy+34, pxw, CENTER, FSIZE_BIG, CMHT);

				if(!(rv=fh_php_load(name, col1, sy, dy, cs, line, highlite, plain, &cut)))
				{
					memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
				}
			}
	
			if(!rv)
			{
				rcp=GetRCCode();
				while((rcp != KEY_OK) && (rcp != KEY_EXIT) && (rcp != KEY_PAGEUP) && (rcp != KEY_PAGEDOWN) && (rcp != KEY_DOWN) && (rcp != KEY_UP) && (rcp != KEY_VOLUMEUP) && (rcp != KEY_VOLUMEDOWN)&& (rcp != KEY_RED))
				{
					rcp=GetRCCode();
				}
				if(rcp==KEY_EXIT)
				{
					rcp=KEY_OK;
				}
				if((rcp != KEY_PAGEUP) && (rcp != KEY_PAGEDOWN))
				{
					return rcp;
				}
				switch(rcp)
				{
					case KEY_PAGEDOWN:
						if((action=cut)!=0)
						{
							line+=5;
						}
						break;
						
					case KEY_PAGEUP:
						if(line)
						{				
							if((line-=5)<0)
							{
								line=0;
							}
							action=1;
						}
						else
						{
							action=0;
						}
						break;
				}
			}
			rv=0;
		}
	}
	return (rv)?-1:0;	
}

char *translate_url(char *cmd, int ftype, int absolute)
{
char *rptr=NULL,*pt1 = NULL,*pt2 = NULL,*pt3 = NULL,*pt4 = NULL,*pt5 = NULL;
char *sstr=strdup(cmd),*estr=strdup(cmd);
FILE *fh = NULL,*fh2 = NULL;
int txttype=(ftype==TYP_TXTHTML),crlf=0;
long flength = 0;


	strcpy(trstr,cmd);
	pt1=trstr;
//	++pt1;
	if((pt2=strchr(pt1,'|'))!=NULL)
	{
		*pt2=0;
		++pt2;
		if((pt3=strchr(pt2,'|'))!=NULL)
		{
			*pt3=0;
			++pt3;
			printf("Tuxwetter <Downloading %s>\n",pt1);
			if(!HTTP_downloadFile(pt1, TRANS_FILE, 1, intype, ctmo, 2))
			{
				if((fh=fopen(TRANS_FILE,"r"))!=NULL)
				{
					fseek(fh,0,SEEK_END);
					flength=ftell(fh);
					rewind(fh);
					if((htmstr=calloc(flength+1,sizeof(char)))!=NULL)
					{
						if(fread(htmstr,(size_t)flength,1,fh)>0)
						{
							*(htmstr+flength)=0;
							if((pt4=strchr(htmstr,13))!=NULL)
								{
									crlf=(*(pt4+1)==10);
								}
							pt4=sstr;
							while(*pt2)
							{
								if((*pt2=='\\') && (*(pt2+1)=='n'))
								{
									if(crlf)
									{
										*pt4=13;
										pt4++;
									}
									pt2++;
									*pt4=10;
								}
								else
								{
									*pt4=*pt2;
								}
								++pt4;		
								++pt2;
							}
							*pt4=0;
					
							pt4=estr;
							while(*pt3)
							{
								if((*pt3=='\\') && (*(pt3+1)=='n'))
								{
									if(crlf)
									{
										*pt4=13;
										pt4++;
									}
									pt3++;
									*pt4=10;
								}
								else
								{
									*pt4=*pt3;
								}	
								++pt4;		
								++pt3;
							}
							*pt4=0;
							if((pt3=strstr(htmstr,sstr))!=NULL)
							{
								if((pt5=strstr(pt3+strlen(sstr)+1,estr))!=NULL)
								{
									do
									{
										pt4=pt3;	
										pt3++;
										pt3=strstr(pt3,sstr);
									}
									while(pt3 && (pt3<pt5));
									*pt5=0;
									pt4+=strlen(sstr);
									if(!txttype)
									{
										if(strstr(pt4,"://")!=NULL)
										{
											sprintf(trstr+strlen(trstr)+1,"\"%s",pt4);
										}
										else
										{
									 		if((pt5=(absolute)?(strrchr(pt1+8,'/')):(strchr(pt1+8,'/')))!=NULL)
									 		{
									 			sprintf(trstr+strlen(trstr)+1,"\"%s",pt1);
									 			sprintf(trstr+strlen(trstr)+1+(pt5-pt1)+((*pt4=='/')?1:2),"%s",pt4);
								 			}
									 	}
										rptr=trstr+strlen(trstr)+1;
									}
									else
									{
										xremove(PHP_FILE);
										if((fh2=fopen(PHP_FILE,"w"))!=NULL)
										{
										int dontsave=0, newline=1;
										
											flength=0;
											fprintf(fh2,"<br>");
												
											while(*pt4)	
											{
												if(*pt4=='<')
												{
													dontsave=1;
												}
												if(*pt4=='>')
												{
													dontsave=2;
												}
												if(!dontsave)
												{
													if((*pt4==' ') && (flength>60))
													{
														fprintf(fh2,"\n<br>");
														flength=0;
														newline=1;
													}
													else
													{
														if(*pt4>' ' || newline<2)
														{
															if(*pt4>' ')
															{
																newline=0;
															}
															fputc(*pt4,fh2);
														}
													}
													if(*pt4==10)
													{
														if(newline<2)
														{
															fprintf(fh2,"<br>");
														}
														flength=0;
														++newline;
													}
													flength++;
												}
												if(dontsave==2)
												{
													dontsave=0;
												}
												pt4++;
											}
											fprintf(fh2,"\n<br><br>");
											fclose(fh2);
											rptr=pt1;
										}
									}
								}
							}
						}
						free(htmstr);
					}
				fclose(fh);
				}
			}
		}
	}

	free(sstr);
	free(estr);

	if(rptr)
	{
		pt1=rptr;
		while(*pt1)
		{
			if(*pt1==' ')
			{
				*(pt1+strlen(pt1)+2)=0;
				memmove(pt1+2,pt1,strlen(pt1));
				*pt1++='%';
				*pt1++='2';
				*pt1='0';
			}
			pt1++;
		}
	}
			
	return rptr;
}

int Menu_Up(MENU *m)
{
int llev=m->headerlevels[m->act_header], lmen=m->act_header, lentr=m->lastheaderentrys[m->act_header];
	
	while((lmen>=0) && (m->headerlevels[lmen]>=llev))
	{
		--lmen;
	}
	if(lmen<0)
	{
		return 0;
	}
	m->act_header=lmen;
	Get_Menu();
	m->act_entry=lentr;
	
	return 1;	
}

void read_neutrino_osd_conf(int *ex,int *sx,int *ey, int *sy)
{
	const char *filename="/var/tuxbox/config/neutrino.conf";
	const char spres[][5]={"","_crt","_lcd"};
	char sstr[4][32];
	int pres=-1, loop, *sptr[4]={ex, sx, ey, sy};
	char *buffer;
	size_t len;
	ssize_t read;
	FILE* fd;

	fd = fopen(filename, "r");
	if(fd){
		buffer=NULL;
		len = 0;
		while ((read = getline(&buffer, &len, fd)) != -1){
			sscanf(buffer, "screen_preset=%d", &pres);
		}
		if(buffer)
			free(buffer);
		rewind(fd);
		++pres;
		sprintf(sstr[0], "screen_EndX%s=%%d", spres[pres]);
		sprintf(sstr[1], "screen_StartX%s=%%d", spres[pres]);
		sprintf(sstr[2], "screen_EndY%s=%%d", spres[pres]);
		sprintf(sstr[3], "screen_StartY%s=%%d", spres[pres]);

		buffer=NULL;
		len = 0;
		while ((read = getline(&buffer, &len, fd)) != -1){
			for(loop=0; loop<4; loop++) {
				sscanf(buffer, sstr[loop], sptr[loop]);
			}
		}
		fclose(fd);
		if(buffer)
			free(buffer);
	}
}

/******************************************************************************
 * Tuxwetter Main
 ******************************************************************************/

int main (int argc, char **argv)
{
int index=0,cindex=0,tv,rcm,rce,ferr=0,tret=-1;
int mainloop=1,wloop=1, dloop=1;
char rstr[BUFSIZE], *rptr;
char tstr[BUFSIZE];
FILE *tfh;
LISTENTRY epl={NULL, 0, TYP_TXTPLAIN, TYP_TXTPLAIN, 0, 0, 0};
PLISTENTRY pl=&epl;

		// if problem with config file return from plugin

		for(tv=1; tv<argc; tv++)
		{
			if((strstr(argv[tv],"-v")==argv[tv])||(strstr(argv[tv],"--Version")==argv[tv]))
			{
				printf("CS-Tuxwetter Version %s\n",P_VERSION);
				return 0;
			}
			if(*argv[tv]=='/')
			{
				strcpy(TCF_FILE,argv[tv]);
			}
			if(strchr(argv[tv],'='))
			{
				cmdline=strdup(argv[tv]);
				TrimString(cmdline);
				TranslateString(cmdline);
			}
		}

//		system("ping -c 2 google.com &");

		if((line_buffer=calloc(BUFSIZE+1, sizeof(char)))==NULL)
		{
			printf(NOMEM);
			return -1;
		}
	
		if (!ReadConf(cmdline))
		{
			printf("Tuxwetter <Configuration failed>\n");
			return -1;
		}
	
		if((trstr=malloc(BUFSIZE))==NULL)
		{
			printf(NOMEM);
			return -1;
		}

		memset(&menu,0,sizeof(MENU));
		memset(&funcs,0,sizeof(MENU));
/*
		if((menu.headertxt=calloc(MAX_MENUTXT, sizeof(char*)))==NULL)
		{
			printf(NOMEM);
			free(line_buffer);
			Clear_List(&menu,-1);
			return -1;
		}
*/
/*
		if(Clear_List(&menu,1))
		{
			printf(NOMEM);
			free(line_buffer);
			Clear_List(&menu,-1);
			return -1;
		}
*/
		if(!cmdline)
		{
			if(Check_Config())
			{
				printf("<tuxwetter> Unable to read tuxwetter.conf\n");
				Clear_List(&menu,-1);
				free(line_buffer);
				return -1;
			}
		}

		if((funcs.headertxt=calloc(1, sizeof(char*)))==NULL)
		{
			printf(NOMEM);
			free(line_buffer);
			Clear_List(&menu,-1);
			Clear_List(&funcs,-1);
			return -1;
		}

		read_neutrino_osd_conf(&ex,&sx,&ey, &sy);
		if((ex == -1) || (sx == -1) || (ey == -1) || (sy == -1)){
			sx = 40;
			ex = var_screeninfo.xres - 40;
			sy = 40;
			ey = var_screeninfo.yres - 40;
		}
		printf("sx=%i, ex =%i, sy=%i, ey=%i\n", sx, ex, sy, ey);

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

		cindex=CMC;
		for(index=CMCP0; index<=CMCP3; index++)
		{
			rd[index]=rd[cindex]+25;
			gn[index]=gn[cindex]+25;
			bl[index]=bl[cindex]+25;
			tr[index]=tr[cindex];
			cindex=index;
		}

		if(Read_Neutrino_Cfg("rounded_corners")>0)
			radius=10;
		else
			radius=0;

		fb = open(FB_DEVICE, O_RDWR);
		if(fb == -1)
		{
			perror("tuxwetter <open framebuffer device>");
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
			perror("tuxwetter <FBIOGET_FSCREENINFO>\n");
			return -1;
		}
		if(ioctl(fb, FBIOGET_VSCREENINFO, &var_screeninfo) == -1)
		{
			perror("tuxwetter <FBIOGET_VSCREENINFO>\n");
			return -1;
		}
		if(!(lfb = (unsigned char*)mmap(0, fix_screeninfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fb, 0)))
		{
			perror("tuxwetter <mapping of Framebuffer>\n");
			return -1;
		}

	//init fontlibrary

		if((error = FT_Init_FreeType(&library)))
		{
			printf("tuxwetter <FT_Init_FreeType failed with Errorcode 0x%.2X>", error);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_Manager_New(library, 1, 2, 0, &MyFaceRequester, NULL, &manager)))
		{
			printf("tuxwetter <FTC_Manager_New failed with Errorcode 0x%.2X>\n", error);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_SBitCache_New(manager, &cache)))
		{
			printf("tuxwetter <FTC_SBitCache_New failed with Errorcode 0x%.2X>\n", error);
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		if((error = FTC_Manager_LookupFace(manager, FONT, &face)))
		{
			if((error = FTC_Manager_LookupFace(manager, FONT2, &face)))
			{
				printf("tuxwetter <FTC_Manager_LookupFace failed with Errorcode 0x%.2X>\n", error);
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
			perror("tuxwetter <allocating of Backbuffer>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}

		memset(lbb, TRANSP, fix_screeninfo.line_length*var_screeninfo.yres);

		startx = sx;
		starty = sy;

	/* Set up signal handlers. */
	signal(SIGINT, quit_signal);
	signal(SIGTERM, quit_signal);
	signal(SIGQUIT, quit_signal);


//  Startbildschirm

	put_instance(instance=get_instance()+1);

	if(show_splash && !cmdline)
	{
#if 0
		sprintf (rstr,"cd /tmp\n/bin/busybox tar -xf bmps.tar startbild.jpg");
		system(rstr);
		show_jpg("/tmp/startbild.jpg", sx, sy, ex-sx, ey-sy, 5, 0, 1, 1);
		xremove("/tmp/startbild.jpg");
#endif
		show_jpg("/var/tuxbox/config/tuxwetter/startbild.jpg", sx, sy, ex-sx, ey-sy, 5, 0, 1, 1);
	}

	//main loop
	
	menu.act_entry=0;
	if(cmdline)
	{
		AddListEntry(&menu, cmdline, 0);
		cindex=99;
	}
	else
	{
		if(Get_Menu())
		{
			printf("Tuxwetter <unable to read tuxwetter.conf>\n");
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			put_instance(instance=get_instance()-1);
			return -1;
		}
		cindex=0;
	}

	while(mainloop)
	{
		if(cindex!=99)
		{
			cindex=Get_Selection(&menu);
		}
		else
		{
			cindex=1;
		}
		dloop=1;
		switch(cindex)
		{
			case -99:
				show_data(-99);
				break;
			
			case -1:
				mainloop=0;
				break;
				
			case 0:
				mainloop=Menu_Up(&menu);
				break;
				
			case -98:
				if((tfh=fopen(MISS_FILE,"r"))!=NULL)
				{
					fclose(tfh);
					pl=&epl;
					sprintf(tstr,"%s,http://localhost/../../../..%s",prs_translate("Fehlende Übersetzungen",CONVERT_LIST),MISS_FILE);
					pl->entry=strdup(tstr);
				}
				else
				{	
					ShowMessage(prs_translate("Keine fehlenden Übersetzungen",CONVERT_LIST),1);
					break;
				}
			case 1:
				if(cindex==1)
				{
					pl=menu.list[menu.act_entry];
				}
				switch (pl->type)
				{
					case TYP_MENU:
						menu.act_header=pl->headerpos;
						menu.lastheaderentrys[menu.act_header]=menu.act_entry;
						Get_Menu();
						menu.act_entry=0;
						break;
						
					case TYP_EXECUTE:
						if((rptr=strchr(pl->entry,','))!=NULL)
						{
							rptr++;
							system(rptr);
							CloseRC();
							InitRC();
						close_jpg_gif_png();
						}
						break;
						
					case TYP_PICTURE:
					case TYP_PICHTML:
					case TYP_TXTHTML:
					case TYP_TEXTPAGE:
					case TYP_TXTPLAIN:
						dloop=1;
						*line_buffer=0;
//						LCD_Init();
						do
						{
							if((pl->type==TYP_TXTHTML) || (pl->type==TYP_PICHTML))
							{
							char *pt1=pl->entry, *pt2=nstr;
							
								strcpy(line_buffer,strchr(pt1,',')+1);
								while(*pt1 && (*pt1 != ','))
									{
										*pt2++=*pt1++;
									}
								*pt2=0;	
								tret=0;
							}
							else
							{
								tret=Transform_Entry(pl->entry, line_buffer);
							}
							if(!tret)
							{
								if((pl->type==TYP_PICHTML) || (pl->type==TYP_TXTHTML))
								{
									if((rptr=translate_url(line_buffer, pl->type, pl->absolute))!=NULL)
									{
										strcpy(line_buffer,rptr);
									}
									else
									{
										close_jpg_gif_png();
										ShowMessage(prs_translate("Formatfehler der URL in der tuxwetter.conf",CONVERT_LIST),1);
										dloop=-1;
										break;
									}
								}
								
								if((pl->type==TYP_PICHTML) || (pl->type==TYP_PICTURE))
								{
									if(pl->pictype==PTYP_ASK)
									{
										if((rptr=strrchr(line_buffer,'.'))!=NULL)
										{
											++rptr;
											if(strncasecmp(rptr,"JPG",3)==0)
											{
												pl->pictype=PTYP_JPG;
											}
											else
											{
												if(strncasecmp(rptr,"GIF",3)==0)
												{
													pl->pictype=PTYP_GIF;
												}
												else
												{
													if(strncasecmp(rptr,"PNG",3)==0)
													{
														pl->pictype=PTYP_PNG;
													}
												}
											}
										}
									}
									if(pl->pictype==PTYP_ASK)
									{
										close_jpg_gif_png();
										ShowMessage(prs_translate("Nicht unterstütztes Dateiformat",CONVERT_LIST),1);
										dloop=-1;
										break;
									}
								}

							
							
								if((pl->type==TYP_TXTHTML) || (pl->type==TYP_TEXTPAGE) || (pl->type==TYP_TXTPLAIN))
								{
									if(gmodeon)
									{
										close_jpg_gif_png();
										ShowInfo(&menu);
									}
									if(!cmdline)
									{
										ShowMessage(prs_translate("Bitte warten",CONVERT_LIST),0);
									}
								}
								else
								{
									if(!gmodeon && !cmdline)
									{
										ShowMessage(prs_translate("Bitte warten",CONVERT_LIST),0);
									}
								}
/*
								LCD_Clear();
								LCD_draw_rectangle (0,0,119,59, LCD_PIXEL_ON,LCD_PIXEL_OFF);
								LCD_draw_rectangle (3,3,116,56, LCD_PIXEL_ON,LCD_PIXEL_OFF);
								lpos=strlen(nstr);
								lrow=0;
								while(lpos>0)
								{
									strncpy(dstr,nstr+LCD_CPL*lrow,LCD_CPL);
									lpos-=LCD_CPL;
									LCD_draw_string(13, (lrow+2)*LCD_RDIST, dstr);
									lrow++;
								}
								LCD_update();
								ferr=(strlen(line_buffer))?0:-1;
*/
								if((!ferr) && ((strcmp(line_buffer,lastpicture)!=0)||(loadalways)) && (pl->pictype!=TYP_TXTHTML))
								{
									rptr=line_buffer;
									if(*rptr=='\"')
									{
										++rptr;
									}
									printf("Tuxwetter <Downloading %s>\n",rptr);
									ferr=HTTP_downloadFile(rptr, (pl->pictype==PTYP_JPG)?JPG_FILE:(pl->pictype==PTYP_PNG)?PNG_FILE:(pl->pictype==PTYP_GIF)?GIF_FILE:PHP_FILE, 1, intype, ctmo, 2);
								}
					
								if(!ferr)
								{
									switch(pl->pictype)
									{
										case PTYP_JPG:
											tret=show_jpg(JPG_FILE, sx, sy, ex-sx, ey-sy, 5, pl->repeat, 0, 1);
										break;

										case PTYP_PNG:
											tret=show_png(PNG_FILE, sx, sy, ex-sx, ey-sy, 5, pl->repeat, 0, 1);
										break;

										case PTYP_GIF:
											tret=show_gif(GIF_FILE, sx, sy, ex-sx, ey-sy, 5, pl->repeat, 0, 1, (strcmp(line_buffer,lastpicture)==0));
										break;

										case TYP_TEXTPAGE:
											tret=show_php(PHP_FILE, nstr, 0, 1);
										break;
										
										case TYP_TXTHTML:
											tret=show_php(PHP_FILE, nstr, 0, 0);
										break;

										case TYP_TXTPLAIN:
										{
											FILE *fh1,*fh2;
											int cnt=0;
											char *pt1;
											
											tret=-1;
											if((fh1=fopen(PHP_FILE,"r"))!=NULL)
											{
												if((fh2=fopen(TMP_FILE,"w"))!=NULL)
												{
													while(fgets(rstr, BUFSIZE-1,fh1))
													{
														TrimString(rstr);
														pt1=rstr;
														cnt=0;
														fprintf(fh2,"<br>");
														while(*pt1)
														{	
															if(*pt1==' ' && cnt>40)
															{
																fprintf(fh2,"\n<br>");
																cnt=0;
															}
															else
															{
																fputc(*pt1,fh2);
																++cnt;
															}
														++pt1;
														}
														fprintf(fh2,"\n");
													}
//													fprintf(fh2,"<br><br>\n");
													fclose(fh2);
													tret=show_php(TMP_FILE, nstr, 1, 0);
													if(cindex==-98 && tret==KEY_RED)
													{
														xremove(MISS_FILE);
													}
												}
												fclose(fh1);
											}
										}
										break;
									}
									
									if(cindex!=-98)
									{
										strncpy(lastpicture,line_buffer,BUFSIZE);
	
										index=menu.act_entry;						
										switch(tret)
										{
											case -1:
												close_jpg_gif_png();
												ShowMessage(prs_translate("Datei kann nicht angezeigt werden.",CONVERT_LIST),1);
												dloop=-1;
												break;
									
											case KEY_UP:
											case KEY_VOLUMEDOWN:
												if(--index < 0)
												{
													index=menu.num_entrys-1;
												}
											break;
								
											case KEY_DOWN:
											case KEY_VOLUMEUP:
												if(++index>=menu.num_entrys)
												{
													index=0;
												}
											break;
								
											case KEY_LEFT:
												*lastpicture=0;
											case KEY_RIGHT:
											break;
															
											default:
												dloop=0;
											break;
										}
										menu.act_entry=index;
										pl=menu.list[menu.act_entry];
										if((pl->type!=TYP_PICTURE) && (pl->type!=TYP_PICHTML) && (pl->type!=TYP_TXTHTML) && (pl->type!=TYP_TXTPLAIN) && (pl->type!=TYP_TEXTPAGE))
										{
											dloop=0;
											cindex=99;
										}
									}
									else
									{
										dloop=0;
									}
								}
								else
								{
									close_jpg_gif_png();
									sprintf(tstr,"%s",prs_translate("Fehler",CONVERT_LIST));
									sprintf(tstr,"%s %d %s.",tstr,ferr,prs_translate("beim Download",CONVERT_LIST));
									ShowMessage(tstr,1);
									ferr = 0;
									dloop=-1;
								}
							
							
							
							}
							else
							{
								close_jpg_gif_png();
								ShowMessage(prs_translate("Formatfehler der URL in der tuxwetter.conf",CONVERT_LIST),1);
								dloop=-1;
								break;
							}
						}
						while(dloop>0);
						close_jpg_gif_png();
						break;
												
					case TYP_CITY:
						if(!prs_get_city())
						{
		
							rcm = -1;
							sprintf(tstr," ");
							
							Clear_List(&funcs, 1);
							funcs.act_entry=0;
							
							sprintf(tstr,"%s %s",prs_translate("Wetterdaten für",CONVERT_LIST),city_name);
							if(funcs.headertxt[0])
							{
								free(funcs.headertxt[0]);
							}
							funcs.headertxt[0]=strdup(tstr);

							for(index=0; index<MAX_FUNCS; index++)
							{
#ifdef WWEATHER
								if(index==2)
								{
									sprintf(rstr,"%s",prs_translate("Heute",CONVERT_LIST));
								}
								else
								{
									prs_get_dwday(index-2, PRE_DAY,tstr);
									sprintf(rstr,"%s",prs_translate(tstr,CONVERT_LIST));
								}
#else
								if(index==2)
								{
									sprintf(rstr,"%s",prs_translate("Heute",CONVERT_LIST));
								}
								else
								{
									prs_get_day(index-2, rstr, metric);
								}
								if((rptr=strchr(rstr,','))!=NULL)
								{
									*rptr=0;
								}
#endif
								if(index>1)
								{
									sprintf(tstr,"%s %s",prs_translate("Vorschau für",CONVERT_LIST),rstr);
								}
								else
								{
									if(index==1)
									{
										sprintf(tstr,"%s",prs_translate("Wochentrend",CONVERT_LIST));
									}
									else
									{
										sprintf(tstr,"%s",prs_translate("Aktuelles Wetter",CONVERT_LIST));
									}
								}
								AddListEntry(&funcs,tstr, 0);
							}
							wloop=1;
							while(wloop)
							{
								clear_screen();
								switch(Get_Selection(&funcs))
								{
									case -99:
										show_data(-99);
										break;
				
									case -1:
										mainloop=0;
										wloop=0;
										break;
										
									case 0:
										wloop=0;
										break;
										
									case 1:
										dloop=1;
										while(dloop>0)
										{
											if(!cmdline)
											{
												ShowMessage(prs_translate("Bitte warten",CONVERT_LIST),0);
											}
											show_data(funcs.act_entry);
											rce=GetRCCode();
											while((rce != KEY_OK) && (rce != KEY_EXIT) && (rce != KEY_DOWN) && (rce != KEY_UP) && (rce != KEY_VOLUMEUP) && (rce != KEY_VOLUMEDOWN))
											{
												rce=GetRCCode();
											}
											index=funcs.act_entry;
											if(gmodeon)
											{
												close_jpg_gif_png();
											}
											switch(rce)
											{
												case KEY_UP:
												case KEY_VOLUMEDOWN:
													if(--index < 0)
													{							
														index=MAX_FUNCS-1;
													}
													break;
						
												case KEY_DOWN:
												case KEY_VOLUMEUP:
													if(++index>=MAX_FUNCS)
													{
													index=0;
													}
													break;

												case KEY_OK:
												case KEY_EXIT:
													dloop=0;
													break;	
											}
											funcs.act_entry=index;
										}
								}
							}
						}
						break;
				}	
				break;
		}
		clear_screen();
		if(cindex==-98 && epl.entry)
		{
			free(epl.entry);
			epl.entry=NULL;
		}
		
		if(cmdline)
		{
			mainloop=0;
		}
	}

	//cleanup

	// clear Display
	free(proxyadress);
	free(proxyuserpwd);
	
	Clear_List(&menu,-1);
	Clear_List(&funcs,-1);

	free(trstr);
	if(cmdline)
	{
		free(cmdline);
	}

	FTC_Manager_Done(manager);
	FT_Done_FreeType(library);

	close_jpg_gif_png();
	
//	clear_lcd();
	
	CloseRC();

    for(index=0; index<32; index++)
    {
    	sprintf(tstr,"%s%02d.gif",GIF_MFILE,index);
    	xremove(tstr);
    }
	sprintf(tstr,"[ -e /tmp/picture* ] && rm /tmp/picture*");
	system(tstr);
	xremove("/tmp/tuxwettr.tmp");
	xremove("/tmp/bmps.tar");
	xremove("/tmp/icon.gif");
	xremove("/tmp/tempgif.gif");
	xremove(PHP_FILE);
	put_instance(get_instance()-1);
	
	if((tfh=fopen(TIME_FILE,"r"))!=NULL)
	{
		fclose(tfh);
		sprintf(line_buffer,"%s &",TIME_FILE);
		system(line_buffer);
		free(line_buffer);
	}
	

	// clear Display
	memset(lbb, TRANSP, fix_screeninfo.line_length*var_screeninfo.yres);
	memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);
//	memset(lfb, TRANSP, fix_screeninfo.line_length*var_screeninfo.yres);
	munmap(lfb, fix_screeninfo.smem_len);
	close(fb);
	free(lbb);
	return 0;
}
