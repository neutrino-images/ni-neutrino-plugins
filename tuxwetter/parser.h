/*
 * $Id: parser.h,v 1.1 2009/12/19 19:42:49 rhabarber1848 Exp $
 *
 * tuxwetter - d-box2 linux project
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
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
*/

#ifndef __wxparser__
#define __wxparser__

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>

//#define WWEATHER
#define TRANSLATION 0x8000

#ifdef WWEATHER
#	define NA		0
	//offset simpleforecast
#	define PRE_STEP		39
#	define NIGHT_STEP	0
	//offset forecast
#	define PRE_STEP2	39
#	define NIGHT_STEP2	0

	// actual Values
#	define ACT_CITY		NA
#	define ACT_OBST		NA
#	define ACT_LAT		1
#	define ACT_LON		2
#	define ACT_UPTIME	4
#	define ACT_LOCALTIME	NA
#	define ACT_TEMP		10
#	define ACT_FTEMP	11
#	define ACT_ICON		6
#	define ACT_COND		5 //| TRANSLATION
#	define ACT_HMID		13
#	define ACT_WINDSPEED	15
#	define ACT_WINDGUST	16
#	define ACT_WINDDIR	17 //| TRANSLATION
#	define ACT_PRESS	14
#	define ACT_DEWPOINT	12
#	define ACT_PRECIPINT	7
#	define ACT_PRECIPPROP	8
#	define ACT_CLOUDC	18
#	define ACT_SUNR		27
#	define ACT_SUNS		28
#	define ACT_PRTEND	NA
#	define ACT_UVIND	19
#	define ACT_UVTEXT	NA
#	define ACT_VISIBILITY	20
#	define ACT_OZONE	21
#	define ACT_MOON		29 | TRANSLATION

	// Preview Values
#	define PRE_DAY		24
#	define PRE_TEMPH	35
#	define PRE_TEMPL	37
#	define PRE_SNOW		NA | TRANSLATION
#	define PRE_ICON		26
#	define PRE_COND		25
#	define PRE_PRECIPINT	30 | TRANSLATION
#	define PRE_PRECIPPROP	33
#	define PRE_SUNR		27
#	define PRE_SUNS		28
#	define PRE_BT		NA
#	define PRE_HMID		44
#	define PRE_WINDSPEED	46
#	define PRE_WINDGUST	47
#	define PRE_WINDDIR	49 //| TRANSLATION
#else
#	define PRE_STEP		32
#	define NIGHT_STEP	13

	// atual Values
#	define ACT_CITY		16
#	define ACT_TIME		17
#	define ACT_LAT		18
#	define ACT_LON		12
#	define ACT_SUNR		4
#	define ACT_SUNS		21
#	define ACT_UPTIME	25
#	define ACT_OBST		26
#	define ACT_TEMPC	27
#	define ACT_TEMPF	28
#	define ACT_FTEMPC	NA
#	define ACT_FTEMPF	NA
#	define ACT_COND		29 | TRANSLATION
#	define ACT_ICON		30
#	define ACT_PRESS	32
#	define ACT_PRTEND	33 | TRANSLATION
#	define ACT_WSPEEDM	NA
#	define ACT_WSPEEDK	36
#	define ACT_WINDD	39 | TRANSLATION
#	define ACT_HMID		41
#	define ACT_VIS		42 | TRANSLATION
#	define ACT_UVIND	44
#	define ACT_UVTEXT	45 | TRANSLATION
#	define ACT_DEWP		47
#	define ACT_MOON		50 | TRANSLATION

	// Preview Values
#	define PRE_DAY		55
#	define PRE_TEMPH	56
#	define PRE_TEMPL	57
#	define PRE_SUNR		58
#	define PRE_SUNS		59
#	define PRE_ICON		61
#	define PRE_COND		62 | TRANSLATION
#	define PRE_WSPEEDM	NA
#	define PRE_WSPEEDK	64
#	define PRE_WINDD	67 | TRANSLATION
#	define PRE_BT		69
#	define PRE_PPCP		70
#	define PRE_HMID		71
#endif

int  parser		(char *,const char *, int, int, int);
int  prs_get_prev_count 	(void);
/*void prs_get_act_int (int what, char *out);
void prs_get_act_loc (int what, char *out);
void prs_get_act_dbl (int what, char *out);
void prs_get_act_time(int what, char *out);
void prs_get_act_dtime(int what, char *out);
*/
int  prs_get_day 	(int, char *, int);
int  prs_get_days_count(void);
int  prs_get_val (int i, int what, int nacht, char *out);
int  prs_get_val2 (int i, int what, int nacht, char *out);
int  prs_get_dbl (int i, int what, int nacht, char *out);
int  prs_get_time(int i, int what, char *out, int metric);
int  prs_get_dtime(int i, int what, char *out, int metric);
int  prs_get_dwday(int i, int what, char *out);
char *prs_translate(char *trans, const char *tfile);
int  prs_get_timeWday(int i, int what, char *out);
char *convertUnixTime(const char *timestr, char *buf, int metric);
int  convertDegToCardinal(const char *degstr, char *out);

#endif // __wxparser__

