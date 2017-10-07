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
	CURLcode res = -1;
	char *surl=URL;
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

	FILE *tmpFile = fopen(downloadTarget, "wb");
	if (tmpFile) {
		CURL *curl = curl_easy_init();
		if(curl)
		{
			curl_easy_setopt(curl, CURLOPT_VERBOSE, 0L);
			curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L/*(showprogress)?0:1*/);
			curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
			curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, NULL);
			curl_easy_setopt(curl, CURLOPT_WRITEDATA, tmpFile);
			curl_easy_setopt(curl, CURLOPT_FAILONERROR, 1L);
			curl_easy_setopt(curl, CURLOPT_URL, surl);
			curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, (ctimo)?ctimo:(30+tmo*45));
			curl_easy_setopt(curl, CURLOPT_TIMEOUT, (tmo+1)*60);
			curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
			if(proxyadress && strstr(URL,"//127.0.0.1/")==NULL && strstr(URL,"//localhost/")==NULL)
			{
				curl_easy_setopt(curl, CURLOPT_PROXY, proxyadress);
				curl_easy_setopt(curl, CURLOPT_PROXYTYPE, CURLPROXY_HTTP);
			}
			else
			{
				curl_easy_setopt(curl, CURLOPT_PROXY, (char *)0);
			}
			if(proxyuserpwd && strstr(URL,"//127.0.0.1/")==NULL && strstr(URL,"//localhost/")==NULL)
			{
				curl_easy_setopt(curl, CURLOPT_PROXYUSERPWD, proxyuserpwd);
			}

			res = curl_easy_perform(curl);
			if (res != CURLE_OK){
				printf("[%s] curl_easy_perform() failed:%s\n",__func__, curl_easy_strerror(res));
			}
			curl_easy_cleanup(curl);
		}
		fclose(tmpFile);
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
