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
#	define PRE_STEP		61
#	define NIGHT_STEP	3
	//offset forecast
#	define PRE_STEP2	14
#	define NIGHT_STEP2	7

	// atual Values
#	define ACT_CITY		7
#	define ACT_OBST		21
#	define ACT_LAT		16
#	define ACT_LON		17
#	define ACT_UPTIME	31
#	define ACT_LOCALTIME	33
#	define ACT_TEMP_F	40
#	define ACT_TEMP_C	41
#	define ACT_FTEMP_F	63
#	define ACT_FTEMP_C	64
#	define ACT_ICON		75
#	define ACT_COND		38 //| TRANSLATION
#	define ACT_HMID		42
#	define ACT_WINDD	44 | TRANSLATION
#	define ACT_WSPEED_M	46
#	define ACT_WSPEED_K	48
#	define ACT_PRESS_MB	50
#	define ACT_PRESS_IN	51
#	define ACT_DEWP_F	54
#	define ACT_DEWP_C	55
#	define ACT_PRECIP_MM	72
#	define ACT_PRECIP_IN	73
#	define ACT_VIS_MI	65
#	define ACT_VIS_KM	66
#	define ACT_CLOUDC	NA
#	define ACT_SUNR		845
#	define ACT_SUNR_MM	846
#	define ACT_SUNS		848
#	define ACT_SUNS_MM	849
#	define ACT_PRTEND	52
#	define ACT_UVIND	NA
#	define ACT_UVTEXT	NA
#	define ACT_MOON_VIS	837
#	define ACT_MOON		839 | TRANSLATION

	// Preview Values
#	define PRE_DAY_SIG	239
#	define PRE_DAY		240
#	define PRE_TEMPH_F	246
#	define PRE_TEMPH_C	247
#	define PRE_TEMPL_F	249
#	define PRE_TEMPL_C	250
#	define PRE_SNOW_IN	266 | TRANSLATION
#	define PRE_SNOW_MM	267 | TRANSLATION
#	define PRE_WSPEED	281
#	define PRE_WINDD	282 | TRANSLATION
#	define PRE_ICON		253
#	define PRE_COND		88
#	define PRE_COND_M	89
#	define PRE_PRECIPMM	261 | TRANSLATION
#	define PRE_SUNR		NA
#	define PRE_SUNS		NA
#	define PRE_BT		NA
#	define PRE_PPCP		90
#	define PRE_HMID		284
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

#endif // __wxparser__

