
#include <string.h>
#include <stdlib.h>
#include <stdio.h>


#ifndef __wxparser__
#define __wxparser__

#define TRANSLATION 0x8000

#ifdef WWEATHER
#	define NA		0
#	define PRE_STEP		14
#	define NIGHT_STEP	13

	// atual Values
#	define ACT_CITY		2
#	define ACT_OBST		3
#	define ACT_LAT		6
#	define ACT_LON		7
#	define ACT_UPTIME	10
#	define ACT_TEMP		11
#	define ACT_ICON		14
#	define ACT_COND		15 | TRANSLATION
#	define ACT_WSPEED	17
#	define ACT_WINDD	19 | TRANSLATION
#	define ACT_PRECIPMM	20
#	define ACT_HMID		21
#	define ACT_VIS		22
#	define ACT_PRESS	23
#	define ACT_CLOUDC	24
#	define ACT_SUNR		NA
#	define ACT_SUNS		NA
#	define ACT_FTEMP	NA
#	define ACT_PRTEND	NA
#	define ACT_UVIND	NA
#	define ACT_UVTEXT	NA
#	define ACT_DEWP		NA
#	define ACT_MOON		NA

	// Preview Values
#	define PRE_DAY		25
#	define PRE_TEMPH	26
#	define PRE_TEMPL	28
#	define PRE_WSPEED	31
#	define PRE_WINDD	32 | TRANSLATION
#	define PRE_ICON		36
#	define PRE_COND		37 | TRANSLATION
#	define PRE_PRECIPMM	38
#	define PRE_SUNR		NA
#	define PRE_SUNS		NA
#	define PRE_BT		NA
#	define PRE_PPCP		NA
#	define PRE_HMID		NA
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
#	define ACT_TEMP		27
#	define ACT_FTEMP	28
#	define ACT_COND		29 | TRANSLATION
#	define ACT_ICON		30
#	define ACT_PRESS	32
#	define ACT_PRTEND	33 | TRANSLATION
#	define ACT_WSPEED	36
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
#	define PRE_WSPEED	64
#	define PRE_WINDD	67 | TRANSLATION
#	define PRE_BT		69
#	define PRE_PPCP		70
#	define PRE_HMID		71
#endif

int  parser		(char *,char *, int, int, int);
int  prs_get_prev_count 	(void);
/*void prs_get_act_int (int what, char *out);
void prs_get_act_loc (int what, char *out);
void prs_get_act_dbl (int what, char *out);
void prs_get_act_time(int what, char *out);
void prs_get_act_dtime(int what, char *out);
*/
int  prs_get_day 	(int, char *, int);
int  prs_get_val (int i, int what, int nacht, char *out);
int  prs_get_dbl (int i, int what, int nacht, char *out);
int  prs_get_time(int i, int what, char *out, int metric);
int  prs_get_dtime(int i, int what, char *out, int metric);
int  prs_get_dwday(int i, int what, char *out);
char *prs_translate(char *trans, char *tfile);

#endif // __wxparser__

