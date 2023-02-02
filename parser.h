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

#define TRANSLATION 0x8000

#	define NA			0
	//offset simpleforecast
#	define PRE_STEP		39
#	define NIGHT_STEP	0
	//offset forecast
#	define PRE_STEP2	39
#	define NIGHT_STEP2	0

	// actual Values
#	define ACT_CITY			NA
#	define ACT_OBST			NA
#	define ACT_LOCALTIME	NA

#	define ACT_LAT			1
#	define ACT_LON			2
#	define ELEVATION		5
#	define ACT_UPTIME		6

#	define ACT_COND			7 | TRANSLATION
#	define ACT_ICON			8
#	define ACT_PRECIPINT	11
#	define ACT_PRECIPPROP	12
#	define ACT_TEMP			15
#	define ACT_FTEMP		16
#	define ACT_DEWPOINT		17
#	define ACT_HMID			18
#	define ACT_PRESS		19
#	define ACT_WINDSPEED	20
#	define ACT_WINDGUST		21
#	define ACT_WINDDIR		22 //| TRANSLATION
#	define ACT_CLOUDC		23
#	define ACT_UVIND		24
#	define ACT_VISIBILITY	25
#	define ACT_OZONE		26

#	define ACT_SUNR			32
#	define ACT_SUNS			33
#	define ACT_MOON			34 //| TRANSLATION
#	define ACT_PRTEND		NA
#	define ACT_UVTEXT		NA

	// Preview Values
#	define PRE_DAY			29
#	define PRE_ICON			30
#	define PRE_COND			31 | TRANSLATION
#	define PRE_SUNR			32
#	define PRE_SUNS			33
#	define PRE_MOON			34 //| TRANSLATION
#	define PRE_PRECIPINT	35 //| TRANSLATION
#	define PRE_PRECIPPROP	38
#	define PRE_TEMPH		41
#	define PRE_TEMPL		43
#	define PRE_SNOW			NA //| TRANSLATION

#	define PRE_BT			NA
#	define PRE_DEWPOINT		49
#	define PRE_HMID			50
#	define PRE_PRESS		51
#	define PRE_WINDSPEED	52
#	define PRE_WINDGUST		53
#	define PRE_WINDDIR		55 //| TRANSLATION

#define JSON_FILE	"/tmp/pirateweather.json"

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
void moonPhase(double val, char *out);

#endif // __wxparser__
