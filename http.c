/*
 * http.c - TuxBox Weather Plugin / HTTP-Interface
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
 * $Id: http.c,v 1.01 2004/09/30 00:29 SnowHead $
 */

#include <curl/curl.h>
//#include <curl/types.h> /* new for v7 */
#include <curl/easy.h> /* new for v7 */
#include <ctype.h>
//#include "lcd.h"
#include "tuxwetter.h"


double spdsize[3]={100000.0,16000.0,8000.0};
int speed=0;

int show_progress( void *clientp, double dltotal, double dlnow, double ultotal, double ulnow )
{
#if 0
	char prstr[50];
	
	if(dltotal<spdsize[speed])
	{
		return 0;
	}
	
	LCD_draw_rectangle (7,7,111,17, LCD_PIXEL_ON,LCD_PIXEL_OFF);
	LCD_draw_fill_rect (7,7,(int)((dlnow/dltotal)*111.0),17,LCD_PIXEL_ON);
	sprintf(prstr,"%d%%",(int)(dlnow*100.0/dltotal));
	LCD_draw_Istring(45, 9, prstr);
	LCD_update();
#endif
	return 0;
}

int HTTP_downloadFile(char *URL, char *downloadTarget, int showprogress, int tmo, int ctimo, int repeats)
{
	CURL *curl;
	CURLcode res=-1;
	char *pt1,*pt2,*pt3=NULL,*tstr=NULL,*surl=URL,myself[25];
	FILE *headerfile,*netfile;
	int i=strlen(URL),y;

	for(y=0; y<4; y++) // change HTTP to lower case
		URL[y]=tolower(URL[y]);

	while(i)
	{
		if(URL[i] <= ' ')
		{
			URL[i]=0;
		}
		--i;
	}
	headerfile = fopen(downloadTarget, "w");
	if (!headerfile)
		return res;
	curl = curl_easy_init();
	if(curl)
	{
		pt1=strstr(URL,"localhost");
		if(!pt1)
		{
			pt1=strstr(URL,"127.0.0.1");
		}
		if(pt1)
		{
			if((pt2=strchr(pt1,'/'))!=NULL)
			{
				if((tstr=malloc(strlen(URL)+20))!=NULL)
				{
					if((netfile=fopen("/etc/network/interfaces","r"))!=NULL)
					{
						i=0;
						while(fgets(tstr, strlen(URL), netfile) && !i)
						{
							if((pt3=strstr(tstr,"address"))!=NULL)
							{
								strcpy(myself,pt3+8);
								myself[strlen(myself)-1]=0;
								i=1;
							}
						}
						if(pt3 && i)
						{
							*pt1=0;
							sprintf(tstr,"%s%s%s",URL,myself,pt2);
							surl=tstr;
						}
						fclose(netfile);
					}
				}
			}
		}
		speed=tmo;
		while(res && repeats--)
		{
			curl_easy_setopt(curl, CURLOPT_URL, surl);
			curl_easy_setopt(curl, CURLOPT_FILE, headerfile);
			curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, show_progress);
			curl_easy_setopt(curl, CURLOPT_PROGRESSDATA, show_progress);
			curl_easy_setopt(curl, CURLOPT_NOPROGRESS, (showprogress)?0:1);
//			curl_easy_setopt(curl, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1);
			curl_easy_setopt(curl, CURLOPT_USERAGENT, "neutrino/httpdownloader");
			curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, (ctimo)?ctimo:(30+tmo*45));
			curl_easy_setopt(curl, CURLOPT_TIMEOUT, (tmo+1)*60);
			curl_easy_setopt(curl, CURLOPT_FAILONERROR, 0);
			if(proxyadress && strstr(URL,"//127.0.0.1/")==NULL && strstr(URL,"//localhost/")==NULL)
			{
				curl_easy_setopt(curl, CURLOPT_PROXY, proxyadress);
				curl_easy_setopt(curl, CURLOPT_PROXYTYPE, CURLPROXY_HTTP);
			}
			else
			{
				curl_easy_setopt(curl, CURLOPT_PROXY, 0);
			}
			if(proxyuserpwd && strstr(URL,"//127.0.0.1/")==NULL && strstr(URL,"//localhost/")==NULL)
			{
				curl_easy_setopt(curl, CURLOPT_PROXYUSERPWD, proxyuserpwd);
			}

			res = curl_easy_perform(curl);
			if(res==CURLE_PARTIAL_FILE)
			{
				res=CURLE_OK;
			}
		}
		curl_easy_cleanup(curl);
	}
	if(tstr)
	{
		free(tstr);
	}
	if (headerfile)
	{
		fflush(headerfile);
		fclose(headerfile);
	}
	if(res)
	{
		remove(downloadTarget);
	}
#if 0
	if(showprogress)
	{
		LCD_draw_fill_rect (6,6,112,18,LCD_PIXEL_OFF);
		LCD_update();
	}
#endif
	return res;
}
