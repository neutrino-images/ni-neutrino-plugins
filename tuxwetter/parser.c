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
#include "current.h"
#include "parser.h"
#include "http.h"

/*
Interne Variablen Bitte nicht direkt aufrufen!!!
*/
#	define MAXITEM	1000
#	define MAXMEM	300
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

void moonPhase(double val, char *out)
{
	const char mphase[][14]= {
		"MOONPHASE_0",	// new
		"MOONPHASE_1",
		"MOONPHASE_2",
		"MOONPHASE_3",
		"MOONPHASE_4",	// full
		"MOONPHASE_5",
		"MOONPHASE_6",
		"MOONPHASE_7",
		"MOONPHASE_NULL"
	};
	int phase = 0;

	if (val == 1)
		val = 0; // New Moon

	if (0 < val && val < 0.25)
		phase = 1;
	else if (val == 0.25)
		phase = 2;
	else if (0.25 < val && val < 0.50)
		phase = 3;
	else if (val == 0.50)
		phase = 4; // Full Moon
	else if (0.50 < val && val < 0.75)
		phase = 4;
	else if (val == 0.75)
		phase = 5;
	else if (0.75 < val && val < 1)
		phase = 7;
	else
		phase = 8; // error

	sprintf(out, "%s", prs_translate((char*)mphase[phase], CONVERT_LIST));
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
	*out=0;
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
	int data_day = -1, next = 0, i = 0;
	int rec = 0, flag = 0;
	int cc = 0, exit_ind = -1;
	size_t array_size;
	char gettemp;
	FILE *wxfile = NULL;

	char url[512];
	char debug[505];
	char keyname[512];
	char keyname_next[30];
	char keyname_tmp[30];
	int tag=0, tc=0, tcc=0;
	extern char key[];

	memset(data,0,MAXITEM*MAXMEM /* 1000*50 */);
	memset(conveng,0,500*40);
	memset(convger,0,500*40);
	prev_count=0;
	days_count=0;
	memset(null,0,2);
	ptc=0;
	t_actday=0;
	t_actmonth=0;

#if 0
	const char * keys[] = {
		// standard
		"latitude",
		"longitude",
		"timezone"
	};
#endif
	// currently
	const char * keys_currently[] = {
		"time",
		"summary",
		"icon",
		"precipIntensity",
		"precipProbability",
		"precipType",
		"temperature",
		"apparentTemperature",
		"dewPoint",
		"humidity",
		"pressure",
		"windSpeed",
		"windGust",
		"windBearing",
		"cloudCover",
		"uvIndex",
		"visibility",
		"ozone"
	};
	// daily
	const char * keys_daily[] = {
		"time",
		"summary",
		"icon",
		"sunriseTime",
		"sunsetTime",
		"moonPhase",
		"precipIntensity",
		"precipIntensityMax",
		"precipIntensityMaxTime",
		"precipProbability",
		"precipType",
		"temperatureHigh",
		"temperatureHighTime",
		"temperatureLow",
		"temperatureLowTime",
		"apparentTemperatureHigh",
		"apparentTemperatureHighTime",
		"apparentTemperatureLow",
		"apparentTemperatureLowTime",
		"dewPoint",
		"humidity",
		"pressure",
		"windSpeed",
		"windGust",
		"windGustTime",
		"windBearing",
		"cloudCover",
		"uvIndex",
		"uvIndexTime",
		"visibility",
		"ozone",
		"temperatureMin",
		"temperatureMinTime",
		"temperatureMax",
		"temperatureMaxTime",
		"apparentTemperatureMin",
		"apparentTemperatureMinTime",
		"apparentTemperatureMax",
		"apparentTemperatureMaxTime"
	};

	//FIXME KEY! and CITYCODE
	sprintf (url,"https://api.darksky.net/forecast/%s/%s?lang=%s&units=%s&exclude=minutely,hourly,flags,alerts",key,citycode,(metric)?"de":"en",(metric)?"ca":"us");
	printf("url:%s\n",url);

	exit_ind=HTTP_downloadFile(url, JSON_FILE, 0, inet, ctmo, 3);

	if(exit_ind != 0)
	{
		printf("%s <Download data from server failed. Errorcode: %d>\n", __plugin__, exit_ind);
		exit_ind=-1;
		return exit_ind;
	}

	exit_ind=-1;

	if ((wxfile = fopen(JSON_FILE,"r"))==NULL)
	{
		printf("%s <Missing JSON_FILE file>\n", __plugin__);
		return exit_ind;
	}
	else
	{
		fgets(debug, 50, wxfile);
		// Test existing file
		if((debug[2] != 'l')||(debug[3] != 'a')||(debug[4] != 't'))
		{
			printf("%s <Wrong format %s file>\n", __plugin__, JSON_FILE);
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
					keyname[tcc]='\0';
					if(!strcmp(keyname,"currently") || !strcmp(keyname,"daily") || !strcmp(keyname,"data") || !strcmp(keyname,"offset"))
					{
						tcc=0;

						if (!strcmp(keyname,"offset"))
						{
							keyname[0]='\0';
							break;
						}
						else
						{
							if (!strcmp(keyname,"currently") || !strcmp(keyname,"data"))
								sprintf(keyname_tmp, keyname);
							else
								keyname_tmp[0]='\0';
							//printf("	skip %s\n",keyname);
							keyname[0]='\0';
							continue;
						}
					}
					rec=1;
					continue;
				}

				if (!strcmp(keyname_tmp,"currently") && gettemp=='{')
				{
					// set keyname next
					strcpy(keyname_next, keys_currently[0]);
					next = 0;
				}
				if (!strcmp(keyname_tmp,"data") && gettemp=='{')
				{
					// set keyname next
					strcpy(keyname_next, keys_daily[0]);
					next = 0;
					data_day++;
				}

				if(tag==1 && rec==0)
				{
					if(gettemp=='{' || gettemp=='[')
					{
						continue;
					}

					keyname[tcc]=gettemp;
					//printf("tag_char[%d] [%c]\n",tcc,gettemp);
					tcc++;
					continue;
				}

				if(rec==1)
				{
					if(tag == 1)
						tag = 0;

					if(gettemp=='}' || gettemp==']')
						continue;

					if(gettemp==',')
					{
						int found = 0;
						data[tc][cc]='\0';
						//printf(">> keyname  D  [%d] = %s | data = %s | day = %i\n", tc, keyname, data[tc], data_day);
						//printf(">> keyname  N ----- = %s[%i] <> %s[%i]\n", keyname_next, strlen(keyname_next), keyname, strlen(keyname));

						// --------------------------------------
						if (!strcmp(keyname_tmp,"currently"))
						{
							array_size = sizeof(keys_currently)/sizeof(keys_currently[0]);

							for (i = 0; i < array_size; i++)
							{
								if (!strcmp(keyname, keys_currently[i]))
									found = 1;
							}
							if (found)
							{
								if (strcmp(keyname_next, keyname ) && found)
								{
									memcpy(data[tc+1], data[tc], sizeof(MAXMEM)+1);
									strcpy(data[tc], "*");
									//printf("++ error - füge Daten ein [%d] %s %s\n",tc, keyname_next, data[tc]);
									//printf(">> keyname  X  [%d] = %s | data = %s | day = %i\n", tc, keyname, data[tc], data_day);
									tc++;
									next++;
								}
								next++;

								if (next < array_size)
									strcpy(keyname_next, keys_currently[next]);
								//printf(">> keyname_next[%d] = %s\n", next, keyname_next);
							}
							else
							{
								tc--;
								printf("New Parameter found in %s: %s\n","currently", keyname);
							}
						}
						// --------------------------------------
						if (!strcmp(keyname_tmp,"data"))
						{
							array_size = sizeof(keys_daily)/sizeof(keys_daily[0]);
							for (i = 0; i < array_size; i++)
							{
								if (!strcmp(keyname, keys_daily[i]))
									found = 1;
							}
							if (found)
							{
								if (strcmp(keyname_next, keyname ) && found)
								{
									memcpy(data[tc+1], data[tc], sizeof(MAXMEM)+1);
									strcpy(data[tc], "*");
									//printf("++ error - füge Daten ein [%d] %s %s\n",tc, keyname_next, data[tc]);
									//printf(">> keyname  X  [%d] = %s | data = %s | day = %i\n", tc, keyname, data[tc], data_day);
									tc++;
									next++;
								}
								next++;

								if (next < array_size)
									strcpy(keyname_next, keys_daily[next]);
								//printf(">> keyname_next[%d] = %s\n", next, keyname_next);
							}
							else
							{
								tc--;
								printf("New Parameter found in %s: %s\n","data", keyname);
							}
						}
						keyname[0]='\0';
						rec=0;
						cc=0;
						tcc=0;
						tc++;
					}
					else
					{
						data[tc][cc]=gettemp;
						cc++;
					}
				}
			}
		}
	}
	fclose(wxfile);

	exit_ind=1;

// debug
#if 0
	int v = 0;
	int start = ACT_UPTIME;
	int end = start + (sizeof(keys_currently)/sizeof(keys_currently[0])) -1;
	for (i = start; i <= end; i++)
	{
		if (v >= sizeof(keys_currently)/sizeof(keys_currently[0])) {
			v = 0;
		}
		printf("## currently [%02i] > %s = %s\n", i ,keys_currently[v], data[i]);
		v++;
	}
	v = 0;
	int day = 1;
	start = PRE_DAY;
	// max days 8
	end = start + 8 * (sizeof(keys_daily)/sizeof(keys_daily[0])) -1;
	for (i = start; i <= end; i++)
	{
		if (v >= sizeof(keys_daily)/sizeof(keys_daily[0])) {
			v = 0;
			day++;
		}
		printf("## day %i [%03i] > %s = %s\n",day, i ,keys_daily[v], data[i]);
		v++;
	}
#endif

//*** Übersetzungs File ***

	if ((wxfile = fopen(trans,"r"))==NULL)
	{
		printf("%s <File %s not found.>\n", __plugin__, trans);
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
