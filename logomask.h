#ifndef __logomask_H__

#define __logomask_H__

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <linux/fb.h>
#if HAVE_DVB_API_VERSION == 3
#include <linux/input.h>
#endif
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/un.h>

#ifndef FB_DEVICE
#define FB_DEVICE	"/dev/fb/0"
#endif
#ifndef FB_DEVICE_FALLBACK
#define FB_DEVICE_FALLBACK	"/dev/fb0"
#endif
#ifndef CONFIGDIR
#define CONFIGDIR "/var/tuxbox/config"
#endif

#define NCF_FILE CONFIGDIR "/neutrino.conf"
#define CFG_FILE CONFIGDIR "/logomask.conf"
#define PID_FILE "/tmp/logomask.pid"

#define BUFSIZE 4096

// rc codes

#undef KEY_EPG
#undef KEY_SAT
#undef KEY_STOP
#undef KEY_PLAY

#define KEY_1			 		2
#define KEY_2			 		3
#define KEY_3			 		4
#define KEY_4			 		5
#define KEY_5			 		6
#define KEY_6			 		7
#define KEY_7			 		8
#define KEY_8			 		9
#define KEY_9					10
#define KEY_BACKSPACE           14
#define KEY_UP                  103
#define KEY_LEFT                105
#define KEY_RIGHT               106
#define KEY_DOWN                108
#define KEY_MUTE                113
#define KEY_VOLUMEDOWN          114
#define KEY_VOLUMEUP            115
#define KEY_POWER               116
#define KEY_HELP                138
#define KEY_HOME                102
#define KEY_EXIT                174
#define KEY_SETUP               141
#define KEY_PAGEUP              104
#define KEY_PAGEDOWN            109
#define KEY_OK           		0x160
#define KEY_RED          		0x18e
#define KEY_GREEN        		0x18f
#define KEY_YELLOW       		0x190
#define KEY_BLUE         		0x191

#define KEY_TVR					0x179
#define KEY_TTX					0x184
#define KEY_FAVORITES			0x16c
#define KEY_EPG					0x16d

#define KEY_SKIPP				0x197
#define KEY_SKIPM				0x19c
#define KEY_AUDIO				0x188
#define KEY_REW					0x0a8
#define KEY_HOLD				0x077
#define KEY_REC					0x0a7
#define KEY_STOP				128
#define KEY_PLAY				207

#ifdef HAVE_COOL_HARDWARE
#define KEY_FWD					0x09f
#endif
#ifdef HAVE_ARM_HARDWARE
#define KEY_FWD					0x0d0
#endif

// Coolstream
#define KEY_COOL				0x1a1
#define KEY_VF					0x175
#define KEY_SAT					0x17d
#define KEY_TS					0x167

// AX/Mutant
#define KEY_PROGRAM             0x16a   /* TIME */
#define KEY_RADIO               0x181
#define KEY_VIDEO               0x189   /* LIST */
#define KEY_BOOKMARKS           156     /* CONTEXT */
#define KEY_NEXTSONG            163
#define KEY_PLAYPAUSE           164
#define KEY_PREVIOUSSONG        165

//devs
int fb, rc, pid;

//framebuffer stuff

enum {FILL, GRID};

enum {TRANSP, BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, TURQUOISE, WHITE, GRAY, LRED, LGREEN, LYELLOW, LBLUE, LMAGENTA, LTURQUOISE};

extern unsigned char rd[], gn[], bl[], tr[];
extern unsigned char *lfb, *lbb;

struct fb_fix_screeninfo fix_screeninfo;
struct fb_var_screeninfo var_screeninfo;

#endif
