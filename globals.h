#ifndef __GLOBALS_H__
#define __GLOBALS_H__

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <netdb.h>
#include <paths.h>
#include <signal.h>
#include <stdarg.h>
#include <stdbool.h>
#include <time.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <ft2build.h>
#include <sys/ioctl.h>
#include <linux/fb.h>
#ifndef HAVE_DREAMBOX_HARDWARE
#include <linux/input.h>
#endif
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/param.h>
#include <sys/mman.h>
#include FT_FREETYPE_H
#include FT_CACHE_H
#include FT_CACHE_SMALL_BITMAPS_H
#include "text.h"
#include "io.h"
#include "gfx.h"

#define P_VERSION		"1.36"
#define MAX_ENTRYS		32
#define CK_INTERVALL	30
#define STATFILE "/var/etc/logcsd.stat"
#define SCKFILE "/tmp/logcsd.socket"
#define PIDFILE "/tmp/logcsd.pid"
#define ECMFILE "/tmp/ecm.info"

#define	RC_0		0x00
#define	RC_1		0x01
#define	RC_2		0x02
#define	RC_3		0x03
#define	RC_4		0x04
#define	RC_5		0x05
#define	RC_6		0x06
#define	RC_7		0x07
#define	RC_8		0x08
#define	RC_9		0x09
#define	RC_RIGHT	0x0A
#define	RC_LEFT		0x0B
#define	RC_UP		0x0C
#define	RC_DOWN		0x0D
#define	RC_OK		0x0E
#define	RC_MUTE		0x0F
#define	RC_STANDBY	0x10
#define	RC_GREEN	0x11
#define	RC_YELLOW	0x12
#define	RC_RED		0x13
#define	RC_BLUE		0x14
#define	RC_PLUS		0x15
#define	RC_MINUS	0x16
#define	RC_HELP		0x17
#define	RC_DBOX		0x18
#define	RC_HOME		0x1F

FILE *fd_pid;
int pid;

typedef struct {unsigned char	used;
				unsigned char 	user[32];
				unsigned char 	pwd[32];
				unsigned char 	ip[16];
				int				newip;
				int				connection;
				int				cmd;
				char			prov[12];
				char			serv[5];
				int				cok;
				int				active;
				time_t			ltime;
				time_t			atime;
				time_t			stime;
				time_t			ctime;
				double			rtime;
				} ENTRY, *PENTRY;

typedef struct {ENTRY			entrys[MAX_ENTRYS];
				} LOG;					

extern unsigned char FONT[64];
extern char camdversion[16];
extern char dversion[16];

enum {LEFT, CENTER, RIGHT};
enum {SMALL, MED, BIG};

FT_Error 		error;
FT_Library		library;
FTC_Manager		manager;
FTC_SBitCache		cache;
FTC_SBit		sbit;
#if FREETYPE_MAJOR == 2 && FREETYPE_MINOR == 0
FTC_Image_Desc		desc;
#else
FTC_ImageTypeRec	desc;
#endif
FT_Face			face;
FT_UInt			prev_glyphindex;
FT_Bool			use_kerning;

//devs

int fb, rc;

//framebuffer stuff

enum {FILL, GRID};
enum {EMPTY, CMCST, CMCS, CMCT, CMC, CMCIT, CMCI, CMHT, CMH, WHITE, BLUE0, TRANSP, BLUE2, ORANGE, GREEN, YELLOW, RED};

extern unsigned char *lfb, *lbb;
extern unsigned char *proxyadress, *proxyuserpwd;

struct fb_fix_screeninfo fix_screeninfo;
struct fb_var_screeninfo var_screeninfo;

//int startx, starty, sx, ex, sy, ey;

#define FB_DEVICE	"/dev/fb/0"

#define MAXSLOTS		4

#endif
