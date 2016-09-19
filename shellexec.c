#include <string.h>
#include <stdio.h>
#include <time.h>
#include "shellexec.h"
#include "text.h"
#include "io.h"
#include "gfx.h"

static char CFG_FILE[128]="/var/tuxbox/config/shellexec.conf";

//#define FONT "/usr/share/fonts/md_khmurabi_10.ttf"
#define FONT2 "/share/fonts/pakenham.ttf"
// if font is not in usual place, we look here:
char FONT[128]="/share/fonts/neutrino.ttf";

//						CMCST,	CMCS,	CMCT,	CMC,	CMCIT,	CMCI,	CMHT,	CMH
//						WHITE,	BLUE0,	TRANSP,	CMS,	ORANGE,	GREEN,	YELLOW,	RED

unsigned char bl[] = {	0x00,	0x00,	0xFF,	0x80,	0xFF,	0x80,	0x00,	0x80,
						0xFF,	0x80,	0x00,	0xFF,	0x00,	0x00,	0x00,	0x00,
						0x00,	0x00,	0x00,	0x00};
unsigned char gn[] = {	0x00,	0x00,	0xFF,	0x00,	0xFF,	0x00,	0xC0,	0x00,
						0xFF,	0x00,	0x00,	0x80,	0x80,	0x80,	0x80,	0x00,
						0x00,	0x00,	0x00,	0x00};
unsigned char rd[] = {	0x00,	0x00,	0xFF,	0x00,	0xFF,	0x00,	0xFF,	0x00,
						0xFF,	0x00,	0x00,	0x00,	0xFF,	0x00,	0x80,	0x80,
						0x00,	0x00,	0x00,	0x00};
unsigned char tr[] = {	0xFF,	0xFF,	0xFF,	0xA0,	0xFF,	0x80,	0xFF,	0xFF,
						0xFF,	0xFF,	0x00,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF,
						0x00,	0x00,	0x00,	0x00};

uint32_t bgra[20];
void TrimString(char *strg);

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
static char spres[][5]={"","_crt","_lcd"};

#define LIST_STEP 	10
#define BUFSIZE 	4095
#define SH_VERSION	1.21
typedef struct {int fnum; FILE *fh[16];} FSTRUCT, *PFSTRUCT;

static int direct[32];
int MAX_FUNCS=10;
static int STYP=1;

typedef struct {char *entry; char *message; int headerpos; int type; int underline; int stay; int showalways;} LISTENTRY;
typedef LISTENTRY *PLISTENTRY;
typedef PLISTENTRY *LIST;
typedef struct {int num_headers; int act_header; int max_header; int *headerwait; int *headermed; char **headertxt; char **icon; int *headerlevels; int *lastheaderentrys; int num_entrys; int act_entry; int max_entrys; int num_active; char *menact; char *menactdep; LIST list;} MENU;
enum {TYP_MENU, TYP_MENUDON, TYP_MENUDOFF, TYP_MENUFON, TYP_MENUFOFF, TYP_MENUSON, TYP_MENUSOFF, TYP_EXECUTE, TYP_COMMENT, TYP_DEPENDON, TYP_DEPENDOFF, TYP_FILCONTON, TYP_FILCONTOFF, TYP_SHELLRESON, TYP_SHELLRESOFF, TYP_ENDMENU, TYP_INACTIVE};
static char TYPESTR[TYP_ENDMENU+1][13]={"MENU=","MENUDON=","MENUDOFF=","MENUFON=","MENUFOFF=","MENUSON=","MENUSOFF=","ACTION=","COMMENT=","DEPENDON=","DEPENDOFF=","FILCONTON=","FILCONTOFF=","SHELLRESON=","SHELLRESOFF=","ENDMENU"};
char NOMEM[]="ShellExec <Out of memory>\n";

MENU menu;

int Check_Config(void);
int Clear_List(MENU *m, int mode);
int Get_Selection(MENU *m);
int AddListEntry(MENU *m, char *line, int pos);
int Get_Menu(int showwait);
static void ShowInfo(MENU *m, int knew);


uint32_t *lfb = NULL, *lbb = NULL;
char title[256];
char VFD[256]="";
char url[256]="time.fu-berlin.de";
char *line_buffer=NULL;
char *trstr;
int paging=1, mtmo=120, radius=10;
int ixw=600, iyw=680, xoffs=13, vfd=0;
char INST_FILE[]="/tmp/rc.locked";
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
	printf("shellexec Version %.2f killed, signal %d\n",SH_VERSION,sig);
	exit(1);
}

char *strxchr(char *xstr, char srch)
{
	int quota=0;
	char *resptr=xstr;

	if(resptr)
	{
		while(*resptr)
		{
			if(!quota && (*resptr==srch))
			{
				return resptr;
			}
			if(*resptr=='\'')
			{
				quota^=1;
			}
			++resptr;
		}
	}
	return NULL;
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

int GetLine(char *buffer, int size, PFSTRUCT fstruct)
{
	int rv=0;
	char *pt1;

	if(fstruct->fnum<0)
	{
		return rv;
	}
	rv=(fgets(buffer, size, fstruct->fh[fstruct->fnum])!=NULL);
	if(!rv)
	{
		while(!rv)
		{
			if(!fstruct->fnum)
			{
				return rv;
			}
			else
			{
				fclose(fstruct->fh[fstruct->fnum]);
				--fstruct->fnum;
				rv=(fgets(buffer, size, fstruct->fh[fstruct->fnum])!=NULL);
			}
		}
	}
	if(rv)
	{
		TrimString(buffer);
		if(strstr(buffer,"INCLUDE=") && (fstruct->fnum<15) && ((pt1=strchr(buffer,'='))!=NULL))
		{
			if(((fstruct->fh[fstruct->fnum+1]=fopen(++pt1,"r"))!=NULL) && (fgets(buffer, BUFSIZE, fstruct->fh[fstruct->fnum+1])))
			{
				fstruct->fnum++;
				TrimString(buffer);
			}
		}
		TranslateString(buffer, size);
	}
	return rv;
}

int ExistFile(char *fname)
{
	FILE *efh;

	if((efh=fopen(fname,"r"))==NULL)
	{
		return 0;
	}
	fclose(efh);
	return 1;
}

int FileContainText(char *line)
{
	int rv=0;
	long flength;
	char *pt1,*tline=strdup(line),*fbuf=NULL;
	FILE *ffh;

	if((pt1=strchr(tline,' '))!=NULL)
	{
		*pt1=0;
		++pt1;
		if((ffh=fopen(tline,"r"))!=NULL)
		{
			fseek(ffh,0,SEEK_END);
			flength=ftell(ffh);
			rewind(ffh);
			if((fbuf=calloc(flength+1,sizeof(char)))!=NULL)
			{
				if(fread(fbuf,(size_t)flength,1,ffh)>0)
				{
					*(fbuf+flength)=0;
					rv=strstr(fbuf,pt1)!=NULL;
				}
				free(fbuf);
			}
			fclose(ffh);
		}
	}
	free(tline);
	return rv;
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
			//printf("%s\n%s=%s -> %d\n",tstr,entry,cfptr,rv);
		}
		fclose(nfh);
	}
	return rv;
}

int IsMenu(char *buf)
{
	int i, res=0;

	for(i=TYP_MENU; !res && i<=TYP_MENUSOFF; i++)
	{
		if(strstr(buf,TYPESTR[i])==buf)
		{
			res=1;
		}
	}
	return res;
}
static int mysystem(const char *command) {
	if (!command)
		return -1;
	char *a = (char *) alloca(strlen(command) + 1);
	strcpy(a, command);
	char *s = a;
	while (*s && *s != ' ' && *s != '\t')
		s++;
	*s = 0;
	if (access(a, X_OK))
		chmod(a, 0755);

	return system(command);
}
#define system mysystem

void OnMenuClose(char *cmd, char *dep)
{
	int res=1;

	if(dep)
	{
		res=!system(dep);
		res|=ExistFile(dep);
	}
	if(cmd && res)
	{
		ShowMessage("System-Aktualisierung", "Bitte warten", 0);
		system(cmd);
	}
}

int Check_Config(void)
{
	int rv=-1, level=0;
	char *pt1,*pt2;
	FSTRUCT fstr;

	if((fstr.fh[0]=fopen(CFG_FILE,"r"))!=NULL)
	{
		fstr.fnum=0;
		while(GetLine(line_buffer, BUFSIZE, &fstr))
		{
			if(IsMenu(line_buffer))
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
					if((menu.icon=realloc(menu.icon,(menu.max_header+LIST_STEP)*sizeof(char*)))==NULL)
					{
						printf(NOMEM);
						Clear_List(&menu,0);
						return rv;
					}
					memset(&menu.icon[menu.max_header],0,LIST_STEP*sizeof(char*));
					if((menu.headerlevels=realloc(menu.headerlevels,(menu.max_header+LIST_STEP)*sizeof(int)))==NULL)
					{
						printf(NOMEM);
						Clear_List(&menu,0);
						return rv;
					}
					memset(&menu.headerlevels[menu.max_header],0,LIST_STEP*sizeof(int));
					if((menu.headerwait=realloc(menu.headerwait,(menu.max_header+LIST_STEP)*sizeof(int)))==NULL)
					{
						printf(NOMEM);
						Clear_List(&menu,0);
						return rv;
					}
					memset(&menu.headerwait[menu.max_header],0,LIST_STEP*sizeof(int));
					if((menu.headermed=realloc(menu.headermed,(menu.max_header+LIST_STEP)*sizeof(int)))==NULL)
					{
						printf(NOMEM);
						Clear_List(&menu,0);
						return rv;
					}
					memset(&menu.headermed[menu.max_header],0,LIST_STEP*sizeof(int));
					if((menu.lastheaderentrys=realloc(menu.lastheaderentrys,(menu.max_header+LIST_STEP)*sizeof(int)))==NULL)
					{
						printf(NOMEM);
						Clear_List(&menu,0);
						return rv;
					}
					memset(&menu.lastheaderentrys[menu.max_header],0,LIST_STEP*sizeof(int));
					menu.max_header+=LIST_STEP;
				}
				pt1=strchr(line_buffer,'=');
				if(!pt1)
				{
					pt1=line_buffer;
				}
				else
				{
					++pt1;
				}
				pt2=pt1;
				while(*pt2 && ((*pt2=='*') || (*pt2=='&') || (*pt2==0302) || (*pt2==0247) || (*pt2=='+') || (*pt2=='-') || (*pt2=='!') || (*pt2=='_')))
				{
					if(*pt2=='_')
					{
						menu.headermed[menu.num_headers]=1;
					}
					while(*(++pt2))
					{
						*(pt2-1)=*pt2;
					}
					*(pt2-1)=0;
					pt2=pt1;
				}

				if(menu.icon[menu.num_headers])
				{
					free(menu.icon[menu.num_headers]);
					menu.icon[menu.num_headers]=NULL;
				}
				if((pt2=strstr(pt1,",ICON="))!=NULL)
				{
					*pt2=0;
					menu.icon[menu.num_headers]=strdup(pt2+6);
				}
				if(menu.headertxt[menu.num_headers])
				{
					free(menu.headertxt[menu.num_headers]);
				}
				menu.headerlevels[menu.num_headers]=level++;
				if((pt2=strxchr(pt1,','))!=NULL)
				{
					*pt2=0;
				}
				menu.headertxt[menu.num_headers++]=strdup(pt1);
			}
			else
			{
				if(strstr(line_buffer,TYPESTR[TYP_ENDMENU])==line_buffer)
				{
					--level;
				}
				else
				{
					if(strstr(line_buffer,"FONT=")==line_buffer)
					{
						strcpy(FONT,strchr(line_buffer,'=')+1);
					}
					if(strstr(line_buffer,"VFD=")==line_buffer)
					{
						strcpy(VFD,strchr(line_buffer,'=')+1);
						if(access(VFD,1)!=-1)
							vfd=1;
					}
					if(strstr(line_buffer,"FONTSIZE=")==line_buffer)
					{
						sscanf(strchr(line_buffer,'=')+1,"%d",&FSIZE_MED);
					}
#if 0
					if(strstr(line_buffer,"MENUTIMEOUT=")==line_buffer)
					{
						sscanf(strchr(line_buffer,'=')+1,"%d",&mtmo);
					}
#endif
					if(strstr(line_buffer,"PAGING=")==line_buffer)
					{
						sscanf(strchr(line_buffer,'=')+1,"%d",&paging);
					}
					if(strstr(line_buffer,"LINESPP=")==line_buffer)
					{
						sscanf(strchr(line_buffer,'=')+1,"%d",&MAX_FUNCS);
					}
					if(strstr(line_buffer,"WIDTH=")==line_buffer)
					{
						sscanf(strchr(line_buffer,'=')+1,"%d",&ixw);
					}
					if(strstr(line_buffer,"HEIGHT=")==line_buffer)
					{
						sscanf(strchr(line_buffer,'=')+1,"%d",&iyw);
					}
					if(strstr(line_buffer,"HIGHT=")==line_buffer)
					{
						sscanf(strchr(line_buffer,'=')+1,"%d",&iyw);
						printf("shellexec::Check_Config: please use HEIGHT instead of HIGHT\n");
					}
					if(strstr(line_buffer,"TIMESERVICE=")==line_buffer)
					{
						strcpy(url,strchr(line_buffer,'=')+1);
						if(strstr(url,"NONE") || strlen(url)<4)
						{
							*url=0;
						}
					}
				}
			}
			//printf("Check_Config: Level: %d -> %s\n",level,line_buffer);
		}
		rv=0;
		fclose(fstr.fh[fstr.fnum]);
	}
	FSIZE_BIG=(FSIZE_MED*5)/4;
	FSIZE_SMALL=(FSIZE_MED*4)/5;
	TABULATOR=2*FSIZE_MED;
	ixw=(ixw>(ex-sx))?(ex-sx):((ixw<400)?400:ixw);
	iyw=(iyw>(ey-sy))?(ey-sy):((iyw<380)?380:iyw);
	return rv;
}

int Clear_List(MENU *m, int mode)
{
	int i;
	PLISTENTRY entr;

	if(m->menact)
	{
		free(m->menact);
		m->menact=NULL;
	}
	if(m->menactdep)
	{
		free(m->menactdep);
		m->menactdep=NULL;
	}
	if(m->max_entrys)
	{
		for(i=0; i<m->num_entrys; i++)
		{
			if(m->list[i]->entry) free(m->list[i]->entry);
			if(m->list[i]->message) free(m->list[i]->message);
			free(m->list[i]);
		}
		m->num_entrys=0;
		m->max_entrys=0;
		m->num_active=0;
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
	int rv=1,rccode, mloop=1,i,j,first,last,active,knew=1;
	time_t tm1,tm2;

	if(m->num_active)
	{
		i=m->act_entry;
		while((i>=0) && ((m->list[i]->type==TYP_COMMENT) || (m->list[i]->type==TYP_INACTIVE)))
		{
			++i;
			if(i>=m->num_entrys)
			{
				i=-1;
			}
		}
		if(i==-1)
		{
			i=0;
		}
		m->act_entry=i;
	}
	time(&tm1);
	do{
		//usleep(100000L);
		first=(paging)?0:(MAX_FUNCS*(int)(m->act_entry/MAX_FUNCS));
		last=(paging)?(m->num_entrys-1):(MAX_FUNCS*(int)(m->act_entry/MAX_FUNCS)+MAX_FUNCS-1);
		if(last>=m->num_entrys)
		{
			last=m->num_entrys-1;
		}

		active=0;
		for(i=first; i<=last && !active; i++)
		{
			active |= ((m->list[i]->type != TYP_COMMENT) && (m->list[i]->type != TYP_INACTIVE));
		}

		rccode=-1;
		if(knew)
		{
			ShowInfo(m, knew);
		}
		knew=1;
		switch(rccode = GetRCCode(mtmo * 1000))
		{
			case RC_RED:
				if(active && direct[0]>=0)
				{
					m->act_entry=direct[0];
					rv=1;
					mloop=0;
				}
				break;

			case RC_GREEN:
				if(active && direct[1]>=0)
				{
					m->act_entry=direct[1];
					rv=1;
					mloop=0;
				}
				break;

			case RC_YELLOW:
				if(active && direct[2]>=0)
				{
					m->act_entry=direct[2];
					rv=1;
					mloop=0;
				}
				break;

			case RC_BLUE:
				if(active && direct[3]>=0)
				{
					m->act_entry=direct[3];
					rv=1;
					mloop=0;
				}
				break;

			case RC_1:
				if(active && direct[4]>=0)
				{
					m->act_entry=direct[4];
					rv=1;
					mloop=0;
				}
				break;

			case RC_2:
				if(active && direct[5]>=0)
				{
					m->act_entry=direct[5];
					rv=1;
					mloop=0;
				}
				break;

			case RC_3:
				if(active && direct[6]>=0)
				{
					m->act_entry=direct[6];
					rv=1;
					mloop=0;
				}
				break;

			case RC_4:
				if(active && direct[7]>=0)
				{
					m->act_entry=direct[7];
					rv=1;
					mloop=0;
				}
				break;

			case RC_5:
				if(active && direct[8]>=0)
				{
					m->act_entry=direct[8];
					rv=1;
					mloop=0;
				}
				break;

			case RC_6:
				if(active && direct[9]>=0)
				{
					m->act_entry=direct[9];
					rv=1;
					mloop=0;
				}
				break;

			case RC_7:
				if(active && direct[10]>=0)
				{
					m->act_entry=direct[10];
					rv=1;
					mloop=0;
				}
				break;

			case RC_8:
				if(active && direct[11]>=0)
				{
					m->act_entry=direct[11];
					rv=1;
					mloop=0;
				}
				break;

			case RC_9:
				if(active && direct[12]>=0)
				{
					m->act_entry=direct[12];
					rv=1;
					mloop=0;
				}
				break;

			case RC_0:
				if(active && direct[13]>=0)
				{
					m->act_entry=direct[13];
					rv=1;
					mloop=0;
				}
				break;

			case RC_UP:
			case RC_MINUS:
				if(m->num_active)
				{
					i=m->act_entry-1;
					if(i<first)
					{
						i=last;
					}
					while(active && ((m->list[i]->type==TYP_COMMENT) || (m->list[i]->type==TYP_INACTIVE)))
					{
						--i;
						if(i<first)
						{
							i=last;
						}
					}
					m->act_entry=i;
				}
				//knew=1;
				break;

			case RC_DOWN:
			case RC_PLUS:
				if(m->num_active)
				{
					i=m->act_entry+1;
					if(i>last)
					{
						i=first;
					}
					while(active && ((m->list[i]->type==TYP_COMMENT) || (m->list[i]->type==TYP_INACTIVE)))
					{
						++i;
						if(i>last)
						{
							i=first;
						}
					}
					m->act_entry=i;
				}
				//knew=1;
				break;

			case RC_PAGEUP:
				i=MAX_FUNCS*(m->act_entry/MAX_FUNCS)-MAX_FUNCS;
				if(i<0)
				{
					i=MAX_FUNCS*((m->num_entrys-1)/MAX_FUNCS);
				}
				j=0;
				while((m->list[i+j]->type==TYP_COMMENT || m->list[i+j]->type==TYP_INACTIVE) && active && (i+j)<=(last+MAX_FUNCS) && (i+j)<m->num_entrys)
				{
					++j;
				}
				if((i+j)<=(last+MAX_FUNCS) && (i+j)<m->num_entrys)
				{
					i+=j;
				}
				m->act_entry=i;
				break;

			case RC_PAGEDOWN:
				i=MAX_FUNCS*(m->act_entry/MAX_FUNCS)+MAX_FUNCS;
				if(i>=m->num_entrys)
				{
					i=0;
				}
				j=0;
				while((m->list[i+j]->type==TYP_COMMENT || m->list[i+j]->type==TYP_INACTIVE) && active && (i+j)<=(last+MAX_FUNCS) && (i+j)<m->num_entrys)
				{
					++j;
				}
				if((i+j)<=(last+MAX_FUNCS) && (i+j)<m->num_entrys)
				{
					i+=j;
				}
				m->act_entry=i;
				break;

			case RC_OK:
				if(m->num_active)
				{
					rv=1;
					mloop=0;
				}
				break;

			case -1:
				knew=0;
#if 0
				if(mtmo == 0)
					break;
#endif
				time(&tm2);
				if((tm2-tm1)<mtmo)
				{
					break;
				}
				rv=RC_HOME;
			case RC_HOME:
				rv=0;
				mloop=0;
				break;

			case RC_MUTE:
				memset(lbb, TRANSP, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
				//blit();
				usleep(500000L);
				ClearRC();
				while(GetRCCode(-1)!=RC_MUTE);
				ClearRC();
				break;

			case RC_STANDBY:
				rv=-1;
				mloop=0;
				break;

			default: knew=0; break;
		}
		if(rccode!=-1)
		{
			time(&tm1);
		}
	} while(mloop);

	ShowInfo(m, knew);

	return rv;
}

int AddListEntry(MENU *m, char *line, int pos)
{
	int i,found=0,pfound=0;
	PLISTENTRY entr;
	char *ptr1,*ptr2,*ptr3,*ptr4, *wstr;

	if(!strlen(line))
	{
		return 1;
	}
	//printf("AddListEntry: %s\n",line);
	wstr=strdup(line);

	if(m->num_entrys>=m->max_entrys)
	{
		if((m->list=realloc(m->list,(m->max_entrys+LIST_STEP)*sizeof(PLISTENTRY)))==NULL)
		{
			printf(NOMEM);
			Clear_List(m,0);
			free(wstr);
			return 0;
		}
		for(i=m->num_entrys; i<m->num_entrys+LIST_STEP; i++)
		{
			if((entr=calloc(1,sizeof(LISTENTRY)))==NULL)
				{
				printf(NOMEM);
				Clear_List(m,0);
				free(wstr);
				return -1;
				}
			m->list[i]=entr;
		}
		m->max_entrys+=LIST_STEP;
	}

	entr=m->list[m->num_entrys];
	entr->underline=entr->stay=entr->showalways=0;

	for(i=TYP_MENU; !found && i<=TYP_SHELLRESOFF; i++)
	{
		ptr4=NULL;
		if((ptr1=strstr(wstr,TYPESTR[i]))==wstr)
		{
			ptr1=strchr(wstr,'=');
			ptr1++;
			ptr2=ptr1;
			while(*ptr2 && ((*ptr2=='*') || (*ptr2=='&') || (*ptr2==0302) || (*ptr2==0247) || (*ptr2=='+') || (*ptr2=='-') || (*ptr2=='!') || (*ptr2=='_')))
			{
				switch(*ptr2)
				{
					case '*': entr->underline=1; break;
					case '!': entr->underline=2; break;
					case '+': entr->showalways=1; break;
					case '-': entr->showalways=2; break;
					case '&': entr->stay=1; break;
					case 0302: if (*(ptr2 + 1) != 0247) break; // UTF-8 value of paragraph symbol
						ptr2++;
					case 0247: entr->stay=2; break;
				}
				while(*(++ptr2))
				{
					*(ptr2-1)=*ptr2;
				}
				*(ptr2-1)=0;
				ptr2=ptr1;
			}
			switch (i)
			{
				case TYP_EXECUTE:
				case TYP_MENUDON:
				case TYP_MENUDOFF:
				case TYP_MENUFON:
				case TYP_MENUFOFF:
					if((ptr2=strxchr(ptr1,','))!=NULL)
					{
						if((ptr4=strstr(ptr1,",ICON="))!=NULL)
						{
							*ptr4=0;
						}
						if((ptr4=strxchr(ptr2+1,','))!=NULL)
						{
							*ptr4=0;
							entr->message=strdup(ptr4+1);
						}
					}
				break;

				case TYP_MENU:
					if((ptr2=strstr(ptr1,",ICON="))!=NULL)
					{
						*ptr2=0;
					}
					if((ptr2=strxchr(ptr1,','))!=NULL)
					{
						*ptr2=0;
						entr->message=strdup(ptr2+1);
					}
				break;
			}
			switch (i)
			{
				case TYP_EXECUTE:
				case TYP_MENU:
				case TYP_COMMENT:
					entr->type=i;
					entr->entry=strdup(ptr1);
					entr->headerpos=pos;
					m->num_entrys++;
					found=1;
					break;

				case TYP_DEPENDON:
				case TYP_DEPENDOFF:
				case TYP_MENUDON:
				case TYP_MENUDOFF:
				case TYP_FILCONTON:
				case TYP_FILCONTOFF:
				case TYP_MENUFON:
				case TYP_MENUFOFF:
					if((ptr2=strstr(ptr1,",ICON="))!=NULL)
					{
						*ptr2=0;
					}
					if((ptr2=strxchr(ptr1,','))!=NULL)
					{
						if(i<TYP_EXECUTE)
						{
							ptr3=ptr2;
						}
						else
						{
							ptr2++;
							ptr3=strxchr(ptr2,',');
							ptr4=strxchr(ptr3+1,',');
						}
						if(ptr3!=NULL)
						{
							*ptr3=0;
							ptr3++;
							found=1;
							if(ptr4)
							{
								*ptr4=0;
							}
							if((i==TYP_FILCONTON) || (i==TYP_FILCONTOFF) || (i==TYP_MENUFON) || (i==TYP_MENUFOFF))
							{
								pfound=FileContainText(ptr3);
							}
							else
							{
								pfound=ExistFile(ptr3);
							}
							if((((i==TYP_DEPENDON)||(i==TYP_MENUDON)||(i==TYP_FILCONTON)||(i==TYP_MENUFON)) && pfound) || (((i==TYP_DEPENDOFF)||(i==TYP_MENUDOFF)||(i==TYP_FILCONTOFF)||(i==TYP_MENUFOFF)) && !pfound))
							{
								entr->type=(i<TYP_EXECUTE)?TYP_MENU:((strlen(ptr2))?TYP_EXECUTE:TYP_INACTIVE);
								entr->entry=strdup(ptr1);
								if(ptr4)
								{
									entr->message=strdup(ptr4+1);
								}
								entr->headerpos=pos;
								m->num_entrys++;
							}
							else
							{
								if(entr->showalways)
								{
									entr->type=TYP_INACTIVE;
									entr->entry=strdup(ptr1);
									entr->headerpos=pos;
									m->num_entrys++;
								}
							}
						}
					}
					break;

				case TYP_SHELLRESON:
				case TYP_SHELLRESOFF:
				case TYP_MENUSON:
				case TYP_MENUSOFF:
					if((ptr2=strstr(ptr1,",ICON="))!=NULL)
					{
						*ptr2=0;
					}
					if((ptr2=strxchr(ptr1,','))!=NULL)
					{
						if(i<TYP_EXECUTE)
						{
							ptr3=ptr2;
						}
						else
						{
							ptr2++;
							ptr3=strxchr(ptr2,',');
							ptr4=strxchr(ptr3+1,',');
						}
						if(ptr3!=NULL)
						{
							*ptr3=0;
							ptr3++;
							found=1;
							if(ptr4)
							{
								*ptr4=0;
							}
							pfound=system(ptr3);
							if((((i==TYP_SHELLRESON)||(i==TYP_MENUSON)) && !pfound) || (((i==TYP_SHELLRESOFF)||(i==TYP_MENUSOFF)) && pfound))
							{
								entr->type=(i<TYP_EXECUTE)?TYP_MENU:((strlen(ptr2))?TYP_EXECUTE:TYP_INACTIVE);
								entr->entry=strdup(ptr1);
								if(ptr4)
								{
									entr->message=strdup(ptr4+1);
								}
								entr->headerpos=pos;
								m->num_entrys++;
							}
							else
							{
								if(entr->showalways)
								{
									entr->type=TYP_INACTIVE;
									entr->entry=strdup(ptr1);
									entr->headerpos=pos;
									m->num_entrys++;
								}
							}
						}
					}
					break;
			}
			if(found && (i != TYP_COMMENT) && (i != TYP_INACTIVE))
			{
				m->num_active++;
			}
		}
	}
	free(wstr);
	return !found;

}

int Get_Menu(int showwait)
{
	int rv=-1, loop=1, mlevel=0, clevel=0, pos=0;
	char *pt1,*pt2;
	FSTRUCT fstr;

	if(showwait && menu.headerwait[menu.act_header] && menu.headertxt[menu.act_header])
	{
		ShowMessage(menu.headertxt[menu.act_header],"Bitte warten ...",0);
	}
	Clear_List(&menu,1);
	if((fstr.fh[0]=fopen(CFG_FILE,"r"))!=NULL)
	{
		loop=1;
		menu.num_active=0;
		fstr.fnum=0;
		while((loop==1) && GetLine(line_buffer, BUFSIZE, &fstr))
		{
			if(IsMenu(line_buffer))
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
			//printf("Get_Menu: loop: %d, mlevel: %d, pos: %d -> %s\n",loop,mlevel,pos,line_buffer);
		}
		if(loop)
		{
			return rv;
		}

		--pos;
		--mlevel;
		loop=1;
		while((loop==1) && GetLine(line_buffer, BUFSIZE, &fstr))
		{
			if(IsMenu(line_buffer))
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
				if(mlevel==clevel)
				{
					if((pt1=strchr(line_buffer,'='))!=NULL)
					{
						pt1++;
						if((pt2=strxchr(pt1,','))!=NULL)
						{
							*(pt2++)=0;
							menu.menactdep=strdup(pt2);
						}
						menu.menact=strdup(pt1);
					}

				}
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
	fclose(fstr.fh[fstr.fnum]);
	}

	return rv;
}

void clean_string(char *trstr, char *lcstr)
{
	int i;
	char *lcdptr,*lcptr,*tptr;

	lcdptr=lcstr;
	lcptr=trstr;
	while(*lcptr)
	{
		if(*lcptr=='~')
		{
			++lcptr;
			if(*lcptr)
			{
				if(*lcptr=='t')
				{
					*(lcdptr++)=' ';
				}
				else
				{
					if(*lcptr=='T')
					{
						*(lcdptr++)=' ';
						lcptr++;
						if (*lcptr && sscanf(lcptr,"%3d",&i)==1)
						{
							i=2;
							while(i-- && *(lcptr++));
						}
					}
				}
				++lcptr;
			}
		}
		else
		{
			*(lcdptr++)=*(lcptr++);
		}
	}
	*lcdptr=0;
	lcptr=tptr=lcstr;
	while(*tptr)
	{
		if(*tptr==0x27)
		{
			memmove(tptr,tptr+1,strlen(tptr));
		}
		++tptr;
	}
}

/******************************************************************************
 * ShowInfo
 ******************************************************************************/

static void ShowInfo(MENU *m, int knew )
{
	int loop, dloop, ldy, stlen;
	double scrollbar_len, scrollbar_ofs, scrollbar_cor;
	int index=m->act_entry,tind=m->act_entry;
	int sbw=(m->num_entrys>MAX_FUNCS)?15:0; // scrollbar width
	int sbo=2; // inner scrollbar offset
	char tstr[BUFSIZE], *tptr;
	char dstr[BUFSIZE],*lcptr,*lcstr;
	int dy, my, moffs, mh, toffs, soffs=4, oldx=startx, oldy=starty, sbar=0, nosel;
	PLISTENTRY pl;

	moffs=iyw/(MAX_FUNCS+1)+5;
	mh=iyw-moffs;
	dy=mh/(MAX_FUNCS+1);
	toffs=dy/2;
	my=moffs+toffs+dy;

	startx = sx + (((ex-sx) - ixw)/2);
	starty = sy + (((ey-sy) - iyw)/2);

	tind=index;

	//frame layout
	RenderBox(0, 0, ixw, iyw, radius, CMC);

	// titlebar
	RenderBox(0, 0, ixw, moffs, radius, CMH);

	for(loop=MAX_FUNCS*(index/MAX_FUNCS); loop<MAX_FUNCS*(index/MAX_FUNCS+1) && loop<m->num_entrys && !sbar; loop++)
	{
		pl=m->list[loop];
		sbar |= ((pl->type!=TYP_COMMENT) && (pl->type!=TYP_INACTIVE));
	}
	--loop;
	if(loop>index)
	{
		m->act_entry=index=loop;
	}

	if(sbw)
	{
		//sliderframe
		RenderBox(ixw-sbw, moffs, ixw, iyw, radius, COL_MENUCONTENT_PLUS_1);
		//slider
		scrollbar_len = (double)mh / (double)((m->num_entrys/MAX_FUNCS+1)*MAX_FUNCS);
		scrollbar_ofs = scrollbar_len*(double)((index/MAX_FUNCS)*MAX_FUNCS);
		scrollbar_cor = scrollbar_len*(double)MAX_FUNCS;
		RenderBox(ixw-sbw + sbo, moffs + scrollbar_ofs + sbo, ixw - sbo, moffs + scrollbar_ofs + scrollbar_cor - sbo, radius, COL_MENUCONTENT_PLUS_3);
	}

	// Title text
	lcstr=strdup(m->headertxt[m->act_header]);
	clean_string(m->headertxt[m->act_header],lcstr);
	RenderString(lcstr, (m->headermed[m->act_header]==1)?0:45, moffs-(moffs-FSIZE_BIG)/2, ixw-sbw-((m->headermed[m->act_header]==1)?0:45) , (m->headermed[m->act_header]==1)?CENTER:LEFT, FSIZE_BIG, CMHT);
	free(lcstr);

	if(m->icon[m->act_header])
	{
		//PaintIcon(m->icon[m->act_header],xoffs-6,soffs+2,1);
	}

	index /= MAX_FUNCS;
	dloop=0;
	ldy=dy;
	//Show table of commands
	for(loop = index*MAX_FUNCS; (loop < (index+1)*MAX_FUNCS) && (loop < m->num_entrys); ++loop)
	{
		int clh=2; // comment line height
		dy=ldy;
		pl=m->list[loop];
		strcpy(dstr,pl->entry);
		if((tptr=strxchr(dstr,','))!=NULL)
		{
			if(pl->type != TYP_COMMENT)
			{
				*tptr=0;
			}
		}
		lcptr=tptr=dstr;
		while(*tptr)
		{
			if(*tptr==0x27)
			{
				memmove(tptr,tptr+1,strlen(tptr));
			}
			++tptr;
		}

		if(m->num_active && sbar && (loop==m->act_entry))
		{
			RenderBox(0, my+soffs-dy, ixw-sbw, my+soffs, radius, CMCS);
		}
		nosel=(pl->type==TYP_COMMENT) || (pl->type==TYP_INACTIVE);
		if(!(pl->type==TYP_COMMENT && pl->underline==2))
		{
			int font_type = MED;
			int font_size = FSIZE_MED;
			int coffs=0; // comment offset
			if (pl->type==TYP_COMMENT)
			{
				font_type = SMALL;
				font_size = FSIZE_SMALL;
				if (pl->underline==1)
				{
					coffs=clh;
				}
			}
			RenderString(dstr, 45, my+soffs-(dy-font_size)/2-coffs, ixw-sbw-65, LEFT, font_type, (((loop%MAX_FUNCS) == (tind%MAX_FUNCS)) && (sbar) && (!nosel))?CMCST:(nosel)?CMCIT:CMCT);
		}
		if(pl->type==TYP_MENU)
		{
			RenderString(">", 30, my+soffs-(dy-FSIZE_MED)/2, 65, LEFT, MED, (((loop%MAX_FUNCS) == (tind%MAX_FUNCS)) && (sbar) && (!nosel))?CMCST:CMCT);
		}
		if(pl->underline)
		{
			int cloffs=0,ccenter=0;
			if(pl->type==TYP_COMMENT)
			{
				if(strlen(dstr)==0)
				{
					cloffs=dy/2;
					if(pl->underline==2)
					{
						dy/=2; // FIXME: these substraction causes space at bottom of painted box
						cloffs+=dy/2;
					}
				}
				else
				{
					if(pl->underline==2)
					{
						cloffs=dy/2;
						ccenter=1;
					}
				}
			}
			else
			{
				if(pl->underline==2)
				{
					dy+=dy/2; // FIXME: these addition causes text outside painted box
					cloffs=-dy/4;
				}
			}
			RenderBox(xoffs, my+soffs-cloffs-clh, ixw-xoffs-sbw, my+soffs-cloffs, 0, COL_MENUCONTENT_PLUS_3);
			if(ccenter)
			{
				stlen=GetStringLen(xoffs, dstr, MED);
				RenderBox(xoffs+(ixw-xoffs-sbw)/2-stlen/2, my+soffs-ldy, xoffs+(ixw-xoffs-sbw)/2+stlen/2+15, my+soffs, FILL, CMC);
				RenderString(dstr, xoffs, my+soffs-(dy-FSIZE_MED)/2, ixw-sbw, CENTER, MED, CMCIT);
			}
		}
		if((pl->type!=TYP_COMMENT) && ((pl->type!=TYP_INACTIVE) || (pl->showalways==2)))
		{
			int ch = GetCircleHeight();
			direct[dloop++]=(pl->type!=TYP_INACTIVE)?loop:-1;
			switch(dloop)
			{
				case 1: RenderCircle(xoffs,my+soffs-(dy+ch)/2,RED);    break;
				case 2: RenderCircle(xoffs,my+soffs-(dy+ch)/2,GREEN);  break;
				case 3: RenderCircle(xoffs,my+soffs-(dy+ch)/2,YELLOW); break;
				case 4: RenderCircle(xoffs,my+soffs-(dy+ch)/2,BLUE0);  break;
/*
				case 1: PaintIcon("/share/tuxbox/neutrino/icons/rot.raw",xoffs-2,my-15,1); break;
				case 2: PaintIcon("/share/tuxbox/neutrino/icons/gruen.raw",xoffs-2,my-15,1); break;
				case 3: PaintIcon("/share/tuxbox/neutrino/icons/gelb.raw",xoffs-2,my-15,1); break;
				case 4: PaintIcon("/share/tuxbox/neutrino/icons/blau.raw",xoffs-2,my-15,1); break;
*/
				default:
					if(dloop<15)
					{
						sprintf(tstr,"%1d",(dloop-4)%10);
						RenderString(tstr, xoffs, my+soffs-(dy-FSIZE_SMALL)/2, 15, CENTER, SMALL, ((loop%MAX_FUNCS) == (tind%MAX_FUNCS))?CMCST:((pl->type==TYP_INACTIVE)?CMCIT:CMCT));
					}
				break;
			}
		}
		my += dy;
	}
	dy=ldy;
	for(; dloop<MAX_FUNCS; dloop++)
	{
		direct[dloop]=-1;
	}

	//copy backbuffer to framebuffer
	memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
	//blit();

	if(m->num_active && knew)
		{
			if(m->list[m->act_entry]->entry)
			{
				sprintf(trstr,"%s%s",(m->list[m->act_entry]->type<=TYP_MENUSOFF)?"> ":"",m->list[m->act_entry]->entry);
				if((lcptr=strxchr(trstr,','))!=NULL)
				{
					*lcptr=0;
				}
			}
			else
			{
				sprintf(trstr,"Kein Eintrag");
			}

			if(vfd)
			{
				lcstr=strdup(trstr);
				clean_string(trstr,lcstr);
				sprintf(tstr,"%s -t\"%s\"",VFD,lcstr);
				system(tstr);
				free(lcstr);
			}
		}

	startx=oldx;
	starty=oldy;
}


int Menu_Up(MENU *m)
{
int llev=m->headerlevels[m->act_header], lmen=m->act_header, lentr=m->lastheaderentrys[m->act_header];

	if(m->menact)
	{
		OnMenuClose(m->menact,m->menactdep);
	}
	while((lmen>=0) && (m->headerlevels[lmen]>=llev))
	{
		--lmen;
	}
	if(lmen<0)
	{
		return 0;
	}
	m->act_header=lmen;
	Get_Menu(1);
	m->act_entry=lentr;

	return 1;
}


/******************************************************************************
 * shellexec Main
 ******************************************************************************/

int main (int argc, char **argv)
{
	int index=0,cindex=0,mainloop=1,dloop=1,tv, spr;
	char tstr[BUFSIZE], *rptr;
	PLISTENTRY pl;

	printf("shellexec Version %.2f\n",SH_VERSION);
	for(tv=1; tv<argc; tv++)
	{
		if(*argv[tv]=='/')
		{
			strcpy(CFG_FILE,argv[tv]);
		}
	}

	if((line_buffer=calloc(BUFSIZE+1, sizeof(char)))==NULL)
	{
		printf(NOMEM);
		return -1;
	}

	if((trstr=calloc(BUFSIZE+1, sizeof(char)))==NULL)
	{
		printf(NOMEM);
		return -1;
	}

	spr=Read_Neutrino_Cfg("screen_preset")+1;
	sprintf(trstr,"screen_StartX%s",spres[spr]);
	if((sx=Read_Neutrino_Cfg(trstr))<0)
		sx=100;

	sprintf(trstr,"screen_EndX%s",spres[spr]);
	if((ex=Read_Neutrino_Cfg(trstr))<0)
		ex=1180;

	sprintf(trstr,"screen_StartY%s",spres[spr]);
	if((sy=Read_Neutrino_Cfg(trstr))<0)
		sy=100;

	sprintf(trstr,"screen_EndY%s",spres[spr]);
	if((ey=Read_Neutrino_Cfg(trstr))<0)
		ey=620;

	for(index=CMCST; index<=CMH; index++)
	{
		sprintf(trstr,"menu_%s_alpha",menucoltxt[index]);
		if((tv=Read_Neutrino_Cfg(trstr))>=0)
			tr[index]=255-(float)tv*2.55;

		sprintf(trstr,"menu_%s_blue",menucoltxt[index]);
		if((tv=Read_Neutrino_Cfg(trstr))>=0)
			bl[index]=(float)tv*2.55;

		sprintf(trstr,"menu_%s_green",menucoltxt[index]);
		if((tv=Read_Neutrino_Cfg(trstr))>=0)
			gn[index]=(float)tv*2.55;

		sprintf(trstr,"menu_%s_red",menucoltxt[index]);
		if((tv=Read_Neutrino_Cfg(trstr))>=0)
			rd[index]=(float)tv*2.55;
	}

	cindex=CMC;
	for(index=COL_MENUCONTENT_PLUS_0; index<=COL_MENUCONTENT_PLUS_3; index++)
	{
		rd[index]=rd[cindex]+25;
		gn[index]=gn[cindex]+25;
		bl[index]=bl[cindex]+25;
		tr[index]=tr[cindex];
		cindex=index;
	}
	for (index = 0; index <= COL_MENUCONTENT_PLUS_3; index++)
		bgra[index] = (tr[index] << 24) | (rd[index] << 16) | (gn[index] << 8) | bl[index];

	fb = open(FB_DEVICE, O_RDWR);
	if(fb == -1)
	{
		perror("shellexec <open framebuffer device>");
		exit(1);
	}

	InitRC();
	//InitVFD();

	//init framebuffer
	if(ioctl(fb, FBIOGET_FSCREENINFO, &fix_screeninfo) == -1)
	{
		perror("shellexec <FBIOGET_FSCREENINFO>\n");
		return -1;
	}
	if(ioctl(fb, FBIOGET_VSCREENINFO, &var_screeninfo) == -1)
	{
		perror("shellexec <FBIOGET_VSCREENINFO>\n");
		return -1;
	}
	if(!(lfb = (uint32_t*)mmap(0, fix_screeninfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fb, 0)))
	{
		perror("shellexec <mapping of Framebuffer>\n");
		return -1;
	}

	//init fontlibrary
	if((error = FT_Init_FreeType(&library)))
	{
		printf("shellexec <FT_Init_FreeType failed with Errorcode 0x%.2X>", error);
		munmap(lfb, fix_screeninfo.smem_len);
		return -1;
	}

	if((error = FTC_Manager_New(library, 1, 2, 0, &MyFaceRequester, NULL, &manager)))
	{
		printf("shellexec <FTC_Manager_New failed with Errorcode 0x%.2X>\n", error);
		FT_Done_FreeType(library);
		munmap(lfb, fix_screeninfo.smem_len);
		return -1;
	}

	if((error = FTC_SBitCache_New(manager, &cache)))
	{
		printf("shellexec <FTC_SBitCache_New failed with Errorcode 0x%.2X>\n", error);
		FTC_Manager_Done(manager);
		FT_Done_FreeType(library);
		munmap(lfb, fix_screeninfo.smem_len);
		return -1;
	}

	memset(&menu,0,sizeof(MENU));
	if(Check_Config())
	{
		printf("shellexec <Check_Config> Unable to read Config %s\n",CFG_FILE);
		FTC_Manager_Done(manager);
		FT_Done_FreeType(library);
		munmap(lfb, fix_screeninfo.smem_len);
		Clear_List(&menu,-1);
		free(line_buffer);
		return -1;
	}

	if((error = FTC_Manager_LookupFace(manager, FONT, &face)))
	{
		printf("shellexec <FTC_Manager_LookupFace failed with Errorcode 0x%.2X, trying default font>\n", error);
		if((error = FTC_Manager_LookupFace(manager, FONT2, &face)))
		{
			printf("shellexec <FTC_Manager_LookupFace failed with Errorcode 0x%.2X>\n", error);
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
	printf("shellexec <FTC_Manager_LookupFace Font \"%s\" loaded>\n", desc.face_id);

	use_kerning = FT_HAS_KERNING(face);
	desc.flags = FT_LOAD_RENDER | FT_LOAD_FORCE_AUTOHINT;

	if(Read_Neutrino_Cfg("rounded_corners")>0)
		radius=9;
	else
		radius=0;

	//init backbuffer
	if(!(lbb = malloc(var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t))))
	{
		printf("shellexec <allocating of Backbuffer failed>\n");
		FTC_Manager_Done(manager);
		FT_Done_FreeType(library);
		munmap(lfb, fix_screeninfo.smem_len);
		return -1;
	}
	stride = fix_screeninfo.line_length/sizeof(uint32_t);

	//lbb=lfb;
	memset(lbb, TRANSP, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
	memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
	//blit();
	startx = sx + (((ex-sx) - (fix_screeninfo.line_length-200))/2);
	starty = sy + (((ey-sy) - (var_screeninfo.yres-150))/2);

	index=0;
	if(vfd)
	{
		sprintf(tstr,"%s -c", VFD);
		system(tstr);
	}
	ShowInfo(&menu, 1);
	//main loop
	menu.act_entry=0;
	if(Get_Menu(1))
	{
		printf("ShellExec <unable to create menu>\n");
		FTC_Manager_Done(manager);
		FT_Done_FreeType(library);
		munmap(lfb, fix_screeninfo.smem_len);
		return -1;
	}
	cindex=0;
	signal(SIGINT, quit_signal);
	signal(SIGTERM, quit_signal);
	signal(SIGQUIT, quit_signal);

	put_instance(instance=get_instance()+1);

	while(mainloop)
	{
		cindex=Get_Selection(&menu);
		dloop=1;
		switch(cindex)
		{
			case -1:
				mainloop=0;
				break;

			case 0:
				mainloop=Menu_Up(&menu);
				break;

			case 1:
				pl=menu.list[menu.act_entry];
				switch (pl->type)
				{
					case TYP_MENU:
						menu.act_header=pl->headerpos;
						menu.lastheaderentrys[menu.act_header]=menu.act_entry;
						menu.headerwait[menu.act_header]=pl->message!=NULL;
						if(menu.headerwait[menu.act_header])
							{
								strcpy(tstr,pl->entry);
								if((rptr=strxchr(tstr,','))!=NULL)
								{
									*rptr=0;
								}
								ShowMessage(tstr, pl->message, 0);
							}
						Get_Menu(0);
						menu.act_entry=0;
						break;

					case TYP_EXECUTE:
						if((rptr=strxchr(pl->entry,','))!=NULL)
						{
							strcpy(tstr,pl->entry);
							rptr=strxchr(tstr,',');
							*rptr=0;
							rptr=strxchr(pl->entry,',');
							rptr++;
							if(pl->stay)
							{
								if(pl->stay==1)
								{
									if(pl->message)
									{
										if(strlen(pl->message))
										{
											ShowMessage(tstr, pl->message, 0);
										}
									}
									else
									{
										ShowMessage(tstr, "Bitte warten", 0);
									}
								}
								else
								{
									memset(lbb, TRANSP, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
									memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
									//blit();
								}

								if(*(rptr+strlen(rptr)-1)=='&')
								{
									*(rptr+strlen(rptr)-1)=0;
								}
							}
							else
							{
								if(*(rptr+strlen(rptr)-1)!='&')
								{
									sprintf(tstr,"%s &",rptr);
									rptr=tstr;
								}
							}
							CloseRC();
							system(rptr);
							InitRC();

							mainloop= pl->stay==1;
							if(pl->stay==1)
							{
								Get_Menu(1);
							}
						}
						break;
				}
		}
	}

	//cleanup
	Clear_List(&menu,-1);

	FTC_Manager_Done(manager);
	FT_Done_FreeType(library);
#if 0
	if(strlen(url))
	{
		sprintf(line_buffer,"/sbin/rdate -s %s > /dev/null &",url);
		system(line_buffer);
	}
#endif
	CloseRC();
	//CloseVFD();

	free(line_buffer);
	free(trstr);

	// clear Display
	memset(lbb, TRANSP, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
	memcpy(lfb, lbb, var_screeninfo.xres*var_screeninfo.yres*sizeof(uint32_t));
	//blit();
	munmap(lfb, fix_screeninfo.smem_len);

	close(fb);
	free(lbb);

	put_instance(get_instance()-1);

	return 0;
}
