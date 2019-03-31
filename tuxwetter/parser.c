/* 
*********************************************************************************************
********************************** New Tuxwetter XML-File_parser ****************************
*********************************************************************************************
*/
//getline needed #define _GNU_SOURCE
//#define _GNU_SOURCE
//#include <ctype.h>

#include <curl/curl.h>
#include <math.h>
//#include <strings.h>
#include "tuxwetter.h"
#include "parser.h"
#include "http.h"

/*
Interne Variablen Bitte nicht direkt aufrufen!!!
*/
#ifdef WWEATHER
#	define MAXITEM	1000
#	define MAXMEM	300
#else
#	define MAXITEM	1000
#	define MAXMEM	50
#endif
char 	data		[MAXITEM][MAXMEM];
char 	conveng		[500][40]; 
char	convger		[500][40];
int	prev_count =	0;
int days_count =	0;
char    null[2]=  	{0,0};
int 	ptc=		0;
int 	t_actday=	0;
int	t_actmonth=	0;
int 	t_actyear=	0;
const char mnames[12][10]={"Januar","Februar","März","April","Mai","Juni","Juli","August","September","Oktober","November","Dezember"};
char prstrans[512];
extern int num_of_days;

//**************************************** Preview Counter ********************************

extern const char CONVERT_LIST[];
extern void TrimString(char *strg);

char *convertUnixTime(const char *timestr, char *buf, int metric)
{
	time_t timenum = (time_t) atoi(timestr);

	struct tm t;
	localtime_r(&timenum, &t);
	if (metric)
		strftime(buf, 30, "%H:%M", &t);
	else
		strftime(buf, 30, "%I:%M %P", &t);
	//printf ("DateTime = %s\n", buf);
	return buf;
}

int convertDegToCardinal(const char *degstr, char *out)
{
	const char DirTable[][5] = {"N","NNO","NO","ONO","O","OSO","SO","SSO","S","SSW","SW","WSW","W","WNW","NW","NNW","N"};
	float deg = atof(degstr);

	while( deg < 0 ) deg += 360 ;
	while( deg >= 360 ) deg -= 360 ;

	sprintf(out, "%s", prs_translate((char*)DirTable[(int)(floor((deg+11.25)/22.5))], CONVERT_LIST));

	return 0;
}

void prs_check_missing(char *entry)
{
char rstr[512];
int found=0;
FILE *fh;

	if((fh=fopen(MISS_FILE,"r"))!=NULL)
	{
		while(!feof(fh)&&!found)
		{
			if(fgets(rstr,500,fh))
			{
				TrimString(rstr);
				if(!strcmp(rstr,entry))
				{
					found=1;
				}
			}
		}
		fclose(fh);
	}
	if(!found)
	{
		if((fh=fopen(MISS_FILE,"a"))!=NULL)
		{
			fprintf(fh,"%s\n",entry);
			fclose(fh);
		}
	}
}

char  *prs_translate(char *trans, const char *tfile)
{
char *sptr;
int i,found=0;
FILE *fh;

	if((fh=fopen(tfile,"r"))!=NULL)
	{
		while(!found && fgets(prstrans,511,fh))
		{
			TrimString(prstrans);
			if(strstr(prstrans,trans)==prstrans)
			{
				sptr=prstrans+strlen(trans);
				if(*sptr=='|')
				{
					++sptr;
					i=strlen(sptr);
					memmove(prstrans,sptr,i+1);
					found=1;
				}
			}
		}
		fclose(fh);
	}
	if(found && strlen(prstrans))
	{	
		if(!strcmp(prstrans,"---"))
		{
			*prstrans=0;
		}
		return prstrans;
	}
	return trans;
}

int prs_get_prev_count (void)
{
	return prev_count;
}

int prs_get_days_count(void)
{
	return days_count;
}

int prs_get_day (int i, char *out, int metric)
{
	int ret=1, set=(PRE_DAY+(i*PRE_STEP)), z=0, intdaynum=0, monthtemp=0;
	char day[15], tstr[128];
	char *pt1, *pt2;

	*out=0;
	if((pt1=strstr(data[set],"T=\""))!=NULL)
	{
		pt1+=3;
		if((pt2=strstr(pt1,"\""))!=NULL)
		{
			strncpy(day,pt1,pt2-pt1);
			day[pt2-pt1]=0;
		
			for(z=0;z<=ptc;z++)
			{
				if (strcasecmp(day,conveng[z])==0) strcpy (day,convger[z]);
			}
			
			pt2++;
			if((pt1=strstr(pt2,"DT=\""))!=NULL)
			{
				pt1+=4;
				if((pt2=strstr(pt1," "))!=NULL)
				{
					pt2++;
					if(sscanf(pt2,"%d",&intdaynum)==1)
					{
						monthtemp=t_actmonth;
						if (intdaynum < t_actday) 
						{
							if((++monthtemp)>12)
							{
							monthtemp =1;
							}
						}
						sprintf(tstr,"%s",prs_translate((char*)day,CONVERT_LIST));
						if(metric)
						{
							sprintf (out,"%s,  %02d. %s", tstr, intdaynum, prs_translate((char*)mnames[monthtemp-1],CONVERT_LIST));
						}
						else
						{
							sprintf (out,"%s, %s %02d. ", tstr, prs_translate((char*)mnames[monthtemp-1],CONVERT_LIST),intdaynum);
						}
						ret=0;
					}
				}
			}
		}
	}
return ret;
}

int prs_get_val (int i, int what, int nacht, char *out)
{
int z;

	strcpy(out,data[(what & ~TRANSLATION)+(i*PRE_STEP)+(nacht*NIGHT_STEP)]);
	TrimString(out);

	if(what & TRANSLATION)
	{
		for(z=0;z<=ptc;z++)
		{
			if (strcasecmp(out,conveng[z])==0)
			{
				strcpy (out,convger[z]);
				return 0;
			}
		}
		if(sscanf(out,"%d",&z)!=1)
		{
			prs_check_missing(out);
		}
	}
	return (strlen(out)==0);
}

#ifdef WWEATHER
int prs_get_val2 (int i, int what, int nacht, char *out)
{
	int z;

	strcpy(out,data[(what & ~TRANSLATION)+(i*PRE_STEP2)+(nacht*NIGHT_STEP2)]);
	if(what & TRANSLATION)
	{
		for(z=0;z<=ptc;z++)
		{
			if (strcasecmp(out,conveng[z])==0)
			{
				strcpy (out,convger[z]);
				return 0;
			}
		}
		if(sscanf(out,"%d",&z)!=1)
		{
			prs_check_missing(out);
		}
	}
	return (strlen(out)==0);
}
#endif

int prs_get_dbl (int i, int what, int nacht, char *out)
{
int ret=1;
double tv;
	
	*out=0;
	if(sscanf(data[(what & ~TRANSLATION)+(i*PRE_STEP)+(nacht*NIGHT_STEP)], "%lf", &tv)==1)
	{
		sprintf(out, "%05.2lf", tv);
		ret=0;
	}
	return ret;
}

int prs_get_time(int i, int what, char *out, int metric)
{
int hh,mm,ret=1;

	*out=0;
	if(sscanf(data[(what & ~TRANSLATION)+(i*PRE_STEP)],"%d:%d",&hh,&mm)==2)
	{
		if(metric)
		{
			if(hh<12)
			{
				if(strstr(data[(what & ~TRANSLATION)+(i*PRE_STEP)],"pm")!=NULL)
				{
					hh+=12;
				}
			}
			else
			{
				if(strstr(data[(what & ~TRANSLATION)+(i*PRE_STEP)],"am")!=NULL)
				{
					hh=0;
				}
			}
			sprintf(out,"%02d:%02d",hh,mm);
		}
		else
		{
			sprintf(out,"%02d:%02d %s",hh,mm,(strstr(data[(what & ~TRANSLATION)+(i*PRE_STEP)],"pm")!=NULL)?"pm":"pm");
		}
		ret=0;
	}
	return ret;
}

int prs_get_dtime(int i, int what, char *out, int metric)
{
int hh,mm,ret=1;

	*out=0;
	if(sscanf(data[(what & ~TRANSLATION)+(i*PRE_STEP)],"%d/%d/%d %d:%d",&t_actmonth,&t_actday,&t_actyear,&hh,&mm)==5)
	{
		if(metric)
		{
			if((hh<12)&&(strstr(data[(what & ~TRANSLATION)+(i*PRE_STEP)],"PM")!=NULL))
			{
				hh+=12;
			}
			sprintf(out,"%02d.%02d.%04d %02d:%02d",t_actday,t_actmonth,t_actyear+2000,hh,mm);
		}
		else
		{
			sprintf(out,"%04d/%02d/%02d %02d:%02d %s",t_actyear+2000,t_actmonth,t_actday,hh,mm,(strstr(data[(what & ~TRANSLATION)+(i*PRE_STEP)],"PM")!=NULL)?"pm":"am");
		}
		ret=0;
	}
	return ret;
}

int prs_get_dwday(int i, int what, char *out)
{
	int ret=1;
	char *wday[] = {"SUNDAY","MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY","???"};

	struct tm ts;

	*out=0;

	if(sscanf(data[(what & ~TRANSLATION)+(i*PRE_STEP)],"%d-%d-%d",&t_actyear,&t_actmonth,&t_actday)==3)
	{
		ts.tm_year = t_actyear - 1900;
		ts.tm_mon  = t_actmonth - 1;
		ts.tm_mday = t_actday;

		ts.tm_hour = 0;
		ts.tm_min  = 0;
		ts.tm_sec  = 1;
		ts.tm_isdst = -1;

		if ( mktime(&ts) == -1 )
			ts.tm_wday = 7;

		sprintf(out,"%s", wday[ts.tm_wday]);
		ret=0;
	}
	return ret;
}

int prs_get_timeWday(int i, int what, char *out)
{
	int ret=1;
	*out=0;
	struct tm ts;
	char buffer [80];

	strcpy(out,data[(what & ~TRANSLATION)+(i*PRE_STEP)]);
	TrimString(out);

	time_t rawtime=atoi(out);
	struct tm * timeinfo;
	timeinfo = localtime (&rawtime);

	strftime (buffer,sizeof(buffer),"%A",timeinfo);
	sprintf(out,"%s", buffer);

	return (strlen(out)==0);
}

//**************************************** Parser ****************************************

//*** XML File ***

int parser(char *citycode, const char *trans, int metric, int inet, int ctmo)
{
	int  rec=0, flag=0, next=0, windspeed=1;
	int cc=0, bc=1, exit_ind=-1;
	char gettemp;
	FILE *wxfile=NULL;
	char url[512];
	char debug[505];

#ifdef WWEATHER
	char tagname[512];
	int getold=0, skip=1, tag=0, tc=0, tcc=0;
	extern char key[];
#else
	int day_data=PRE_DAY;
	int previews=9;
	extern char par[], key[];
#endif
	memset(data,0,MAXITEM*MAXMEM /* 1000*50 */);
	memset(conveng,0,500*40); 
	memset(convger,0,500*40);
	prev_count=0;
	days_count=0;
	memset(null,0,2);
	ptc=0;
	t_actday=0;
	t_actmonth=0;

#ifdef WWEATHER
	//FIXME KEY! and CITYCODE
	//sprintf (url,"http://api.wunderground.com/api/%s/geolookup/conditions/forecast10day/astronomy/lang:DL/pws:0/q/%s.json",key,citycode);
	sprintf (url,"https://api.darksky.net/forecast/%s/%s?lang=%s&units=%s&exclude=hourly,minutely",key,citycode,(metric)?"de":"en",(metric)?"ca":"us");
	printf("url:%s\n",url);

	exit_ind=HTTP_downloadFile(url, "/tmp/tuxwettr.tmp", 0, inet, ctmo, 3);

	if(exit_ind != 0)
	{
		printf("Tuxwetter <Download data from server failed. Errorcode: %d>\n",exit_ind);
		exit_ind=-1;
		return exit_ind;
	}

	exit_ind=-1;

	if ((wxfile = fopen("/tmp/tuxwettr.tmp","r"))==NULL)
	{
		printf("Tuxwetter <Missing tuxwettr.tmp File>\n");
		return exit_ind;
	}
	else
	{
		fgets(debug,50,wxfile);
		//printf("%s\n",debug);
		if((debug[2] != 'l')||(debug[3] != 'a')||(debug[4] != 't'))
		{
			fclose(wxfile);
			return exit_ind;
		 }
		else
		{
			// starting position forcast
			strcpy(data[tc],"N/A");
			tc++;

			fseek(wxfile, 0L, SEEK_SET);
			while (!feof(wxfile))
			{
				gettemp=fgetc(wxfile);
				if(gettemp=='"')
				{
					if(tag==0 && rec==0)
					{
						tag=1;
					}
					continue;
				}
				if(gettemp==':')
				{
					tagname[tcc]='\0';
					if(!strcmp(tagname,"currently") || !strcmp(tagname,"daily") || !strcmp(tagname,"data") || !strcmp(tagname,"flags") || !strcmp(tagname,"sources"))
					{
						tcc=0;
						if(!strcmp(tagname,"flags"))
						{
							tagname[0]='\0';
							break;
						}
						else
						{
							//printf("	skip %s\n",tagname);
							tagname[0]='\0';
							continue;
						}
					}
					rec=1;
					continue;
				}

				if(tag==1 && rec==0)
				{
					if(gettemp=='{' || gettemp=='[')
						continue;

					tagname[tcc]=gettemp;
					//printf("tag_char[%d] [%c]\n",tcc,gettemp);
					tcc++;
					continue;
				}

				if(rec==1)
				{
					if(tag==1)
						tag==0;

					if(gettemp=='}' || gettemp==']')
						continue;

					if(gettemp==',')
					{
						data[tc][cc]='\0';
						//printf("tagname[%d] = %s | data = %s\n",tc,tagname,data[tc]);
						//fix zero precipIntensityMaxTime
						if(!strcmp(tagname,"precipIntensityMax") && !strcmp(data[tc],"0"))
						{
							tc++;
							strcpy(data[tc], "0");
							//printf("tagname[%d] = precipIntensityMaxTime | data = %s\n",tc,data[tc]);
						}
						//fix zero precipType
						else if(!strcmp(tagname,"precipProbability") && !strcmp(data[tc],"0"))
						{
							tc++;
							strcpy(data[tc], "0");
							//printf("tagname[%d] = precipType | data = %s\n",tc,data[tc]);
						}
						//fix zero windSpeed / windBearing
						else if(!strcmp(tagname,"windSpeed") && !strcmp(data[tc], "0"))
						{
							//printf("tagname[%d] = windSpeed | data = %s\n",tc,data[tc]);
							windspeed = 0;
						}
						else if(!strcmp(tagname,"windGust") && windspeed == 0)
						{
							tc++;
							strcpy(data[tc], "0");
							windspeed = 1;
							//printf("tagname[%d] = windBearing | data = %s\n",tc,data[tc]);
						}
						tagname[0]='\0';
						rec=0;
						cc=0;
						tcc=0;
						tc++;
					}
					else
					{
						//FIXME optional value
						if(!strcmp(tagname,"precipAccumulation"))
						{
							//printf("tagname[%d] = %s \n",tc, tagname);
							tagname[0]='\0';
							tag=0;
							rec=0;
							cc=0;
							tcc=0;
							continue;
						}
						//printf("%c",gettemp);
						data[tc][cc]=gettemp;
						cc++;
					}
				}
			}
		}
	}
	fclose(wxfile);

	exit_ind=1;
#else
/*	sprintf (url,"http://xoap.weather.com/weather/local/%s?cc=*&dayf=%d&prod=xoap&unit=%c&par=1005530704&key=a9c95f7636ad307b",citycode,previews,(metric)?'m':'u');
	exit_ind=HTTP_downloadFile(url, "/tmp/tuxwettr.tmp", 0, inet, ctmo, 3);
*/
	sprintf (url,"wget -q -O /tmp/tuxwettr.tmp http://xoap.weather.com/weather/local/%s?unit=%c\\&dayf=%d\\&cc=*\\&prod=xoap\\&link=xoap\\&par=%s\\&key=%s",citycode,(metric)?'m':'u',previews,par,key);
	exit_ind=system(url);
	sleep(1);
	if(exit_ind != 0)
	{
		printf("Tuxwetter <Download data from server failed. Errorcode: %d>\n",exit_ind);
		exit_ind=-1;
		return exit_ind;
	}
	exit_ind=-1;
	system("sed -i /'prmo'/,/'\\/lnks'/d /tmp/tuxwettr.tmp");
	if ((wxfile = fopen("/tmp/tuxwettr.tmp","r"))==NULL)
	{
		printf("Tuxwetter <Missing tuxwettr.tmp File>\n");
		return exit_ind;
	}
	else
	{
	bc=1;
		fgets(debug,500,wxfile);
//		printf("%s",debug);
		fgets(debug,5,wxfile);
//		printf("%s",debug);
		if((debug[0] != 60)||(debug[1] != 33)||(debug[2] != 45)||(debug[3] != 45))
		{
			fclose(wxfile);
			return exit_ind;
		}
		else {
		fclose(wxfile);
		wxfile = fopen("/tmp/tuxwettr.tmp","r");
		while (!feof(wxfile))
		{
			gettemp=fgetc(wxfile);
			if ((gettemp >=97) && (gettemp <=122)) gettemp = gettemp -32;
			if (gettemp == 13) gettemp=0; 
			if (bc == day_data)
			{
				
				if (gettemp == 62) 
				{
					rec = 0;
				}
				if (rec == 1)
				{
					data[bc][cc] = gettemp;
					cc++;
				}
				if (gettemp == 60) rec = 1;
				if (gettemp == 13) data[bc][cc+1] =0;
				if (gettemp == 10) 
				{
					bc++;
					cc = 0;
					rec = 0;
					flag=1;
					prev_count++;
				}
			}
			else
			{
				if (gettemp == 60) rec = 0;
				if (rec == 1)
				{
					data[bc][cc] = gettemp;
					cc++;
				}
				if (gettemp == 62) rec = 1;
				if (gettemp == 13) data[bc][cc] =0;
				if (gettemp == 10) 
				{
					bc++;
					cc = 0;
					rec = 0;
				}
			}
			if ((flag==1) && (gettemp == 0))
			{
				day_data=day_data+PRE_STEP;
				flag=0;
			}
		}
		}
		fclose(wxfile);
	}
	if (prev_count > 0) prev_count=prev_count-1;
	if (prev_count > 0) prev_count=prev_count-1;
	cc=0;

	exit_ind=1;
#endif

//*** Übersetzungs File ***
	
	if ((wxfile = fopen(trans,"r"))==NULL)
	{
		printf("Tuxwetter <File %s not found.>\n",trans);
		return exit_ind;
	}
	else
	{
		while (!feof(wxfile))
		{
			gettemp=fgetc(wxfile);
			if (gettemp == 10)
			{
				cc=0;
				ptc++;
				flag=0;
			}
			else
			{
				if (gettemp == 124)
				{
					cc=0;
					flag=2;
				}
				if (gettemp == 13) gettemp = 0;
				if (flag==0) 
				{
					if ((gettemp >=97) && (gettemp <=122)) gettemp = gettemp -32;
					conveng[ptc][cc]=gettemp;
				}
				if (flag==1) convger[ptc][cc]=gettemp;
				cc++;
				if (flag == 2) 
				{
					flag--;
					cc=0;
				}
			}
		}
		fclose(wxfile);
	}
	prs_get_dtime (0, ACT_UPTIME, debug, metric);

return 0;
}


