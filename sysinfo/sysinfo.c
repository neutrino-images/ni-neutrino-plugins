/*
 * sysinfo - ported by GetAway
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
#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>
#include <math.h>
#include <linux/dvb/frontend.h>

#include <linux/ethtool.h>
#include <linux/sockios.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <netdb.h>

#include "current.h"
#include "icons.h"
#include "sysinfo.h"
#include "text.h"
#include "gfx.h"
#include "io.h"
#include "pngw.h"
#include "fe_infos.h"
#include "mmcblk_info.h"
#include "mtddevice_info.h"

#define SH_VERSION 1.25

FT_Error error;
FT_Library library;
FTC_Manager manager;
FTC_SBitCache cache;
FTC_SBit sbit;
FTC_ImageTypeRec desc;
FT_Face face;
FT_UInt prev_glyphindex;
FT_Bool use_kerning;

//#define NET_DEBUG
//#define NET_DEBUG2

char VERSION_FILE[10] = "/.version";
char INST_FILE[] = "/tmp/rc.locked";
char FONT[128] = FONTDIR "/neutrino.ttf";
// if font is not in usual place, we look here:
#define FONT2 FONTDIR "/pakenham.ttf"

#define BUFSIZE 4095
#define NETWORKFILE_VAR "/var/etc/network/interfaces"
#define NETWORKFILE_ETC "/etc/network/interfaces"
#define RESOLVEFILE_VAR "/var/etc/resolv.conf"
#define RESOLVEFILE_ETC "/etc/resolv.conf"

#define MAXLINES 500

//				CMCST,	CMCS,	CMCT,	CMC,	CMCIT,	CMCI,	CMHT,	CMH
//				WHITE,	BLUE0,	TRANSP,	CMS,	ORANGE,	GREEN,	YELLOW,	RED,	LRED	HGREY
//				COL_MENUCONTENT_PLUS_0 - 3, COL_SHADOW_PLUS_0
#define MAX_COLORS 23
uint32_t tr[] = {0xFF,	0xFF,	0xFF,	0xA0,	0xFF,	0x80,	0xFF,	0xFF,
				 0xFF,	0xFF,	0x00,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF,	0xFF,
				 0x00,  0x00,	0x00,	0x00,	0x00};

uint32_t bl[] = {0x00,	0x00,	0xFF,	0x80,	0xFF,	0x80,	0x00,	0x80,
				 0xFF,	0xFF,	0x00,	0xFF,	0x00,	0x00,	0x00,	0x00,	0x20,	0xC0,
				 0x00,	0x00,	0x00,	0x00,	0x00};

uint32_t gn[] = {0x00,	0x00,    0xFF,	0x00,	0xFF,	0x00,	0xC0,	0x00,
				 0xFF,	0x80,    0x00,	0x80,	0x80,	0x9C,	0xB8,	0x00,	0x20,	0xC0,
				 0x00,	0x00,    0x00,	0x00,	0x00};

uint32_t rd[] = {0x00,	0x00,	0xFF,	0x00,	0xFF,	0x00,	0xFF,	0x00,
				 0xFF,	0x00,	0x00,	0x00,	0xFF,	0x00,	0xB8,	0x80,	0xC8,	0xC0,
				 0x00,	0x00,	0x00,	0x00,	0x00};

uint32_t bgra[MAX_COLORS];

char uptime[50] = "";
char datum[36] = "";
char zeit[36] = "";

char cores[12] = "";
char processor[64] = "";
char hardware[64] = "";
char boxname[64] = "";
char tuner[16] = "";
char features[256] = "";
char hard_rev[32] = "";
char bogomips[12] = "";
char kernel[256] = "";

double user_perf = 0;
double nice_perf = 0;
double sys_perf = 0;
double idle_perf = 0;
double old_user_perf = 0;
double old_nice_perf = 0;
double old_sys_perf = 0;
double old_idle_perf = 0;

float memtotal = 0;
float memfree = 0;
float memused = 0;
float memactive = 0;
float meminakt = 0;

float old_memtotal = 0;
float old_memfree = 0;
float old_memused = 0;
float old_memactive = 0;
float old_meminakt = 0;

#define MAX_FS 25
char Filesystem[MAX_FS][256] = {"", ""};
char FS_total[MAX_FS][10] = {"", ""};
char FS_used[MAX_FS][10] = {"", ""};
char FS_free[MAX_FS][10] = {"", ""};
char FS_percent[MAX_FS][6] = {"", ""};
char FS_mount[MAX_FS][128] = {"", ""};
int FS_count = 0;

#define MAX_NAME_LEN 16

char IP_ADRESS[25] = {"n.a."};
char MAC_ADRESS[25] = {"n.a."};
char BC_ADRESS[25] = {"n.a."};
char MASK_ADRESS[25] = {"n.a."};
char BASE_ADRESS[10] = {"n.a."};
char GATEWAY_ADRESS[25] = {"n.a."};
char NAMES_ADRESS[25] = {"n.a."};

#define DATA_SIZE 10 // Anzahl der letzten Werte für den gleitenden Durchschnitt
#define N_ALPHA 0.5 // Filterkoeffizient für den gleitenden Durchschnitt

unsigned long long read_akt = 0;
unsigned long long read_old = 0;
unsigned long long write_akt = 0;
unsigned long long write_old = 0;
unsigned long long delta_read = 0;
unsigned long long delta_write = 0;
int count_data = 0;
int count_index = 0;

float average_delta_read = 0;
float data_delta_read[DATA_SIZE];
float average_delta_write = 0;
float data_delta_write[DATA_SIZE];

float delta_read_old = 0;
float delta_write_old = 0;
long read_packet = 0;
long write_packet = 0;
long dummy = 0;

struct fb_fix_screeninfo fix_screeninfo;
struct fb_var_screeninfo var_screeninfo;

int linie_oben = 0, linie_unten = 0, rahmen = 0, rabs = 0;
int sx = -1, ex = -1, sy = -1, ey = -1;
int startx = 0, starty = 0;
int x_pos = 0;
int win_sx = 0, win_ex = 0, win_sy = 0, win_ey = 0;
int fb;
int radius = 0, radius_small = 0;

char NOMEM[] = "Sysinfo <Out of memory>\n";

uint32_t *lfb = NULL, *lbb = NULL;
char *_line_buffer = NULL;
char IFNAME[16] = "";
int if_active = -1;
int instance = 0;
int rclocked = 0;
int stride = 0;
int swidth = 0;

static void quit_signal(int sig);

#ifndef HAVE_STRLCPY
size_t strlcpy(char *dst, const char *src, size_t size) {
	size_t len = strlen(src);
	if (len >= size) {
		len = size - 1;
	}
	memcpy(dst, src, len);
	dst[len] = '\0';
	return len;
}
#endif

void safe_strncpy(char *dest, const char *src, size_t dest_size) {
	size_t src_len = strcspn(src, "\r\n"); // Länge ohne Zeilenende
	size_t copy_len = src_len < dest_size ? src_len : dest_size - 1;
	memcpy(dest, src, copy_len);
	dest[copy_len] = '\0';
}

void get_substring(const char *str, char *out, const char delimiter) {
    const char *start = strrchr(str, delimiter);
    if (start == NULL) {
        out[0] = '\0';
        return;
    }
    strcpy(out, start + 1);
}

int get_instance(void)
{
	FILE *fh;
	int rval = 0;

	if ((fh = fopen(INST_FILE, "r")) != NULL)
	{
		rval = fgetc(fh);
		fclose(fh);
	}
	return rval;
}

void put_instance(int pval)
{
	FILE *fh;

	if (pval)
	{
		if (!rclocked)
		{
			rclocked = 1;
			system("pzapit -lockrc > /dev/null");
		}
		if ((fh = fopen(INST_FILE, "w")) != NULL)
		{
			fputc(pval, fh);
			fclose(fh);
		}
	}
	else
	{
		remove(INST_FILE);
		system("pzapit -unlockrc > /dev/null");
	}
}

void read_neutrino_osd_conf(int *_ex, int *_sx, int *_ey, int *_sy)
{
	const char spres[][4] = {"", "crt", "lcd", "a", "b"};
	char sstr[4][32];
	int step = 0, pres = -1, resolution = -1, loop, *sptr[4] = {_ex, _sx, _ey, _sy};
	char *buffer;
	size_t len;
	ssize_t read;
	FILE *fd;

	fd = fopen(NCFFILE, "r");
	if (fd)
	{
		buffer = NULL;
		len = 0;
		while ((read = getline(&buffer, &len, fd)) != -1)
		{
			if (strstr(buffer, "screen_EndX_a"))
				step = 2;
			sscanf(buffer, "screen_preset=%d", &pres);
			sscanf(buffer, "osd_resolution=%d", &resolution);
		}
		if (buffer)
			free(buffer);
		rewind(fd);
		++pres;
		pres += step;
		if (resolution == -1)
		{
			snprintf(sstr[0], sizeof(sstr[0]), "screen_EndX_%s   = %%d", spres[pres]);
			snprintf(sstr[1], sizeof(sstr[1]), "screen_StartX_%s = %%d", spres[pres]);
			snprintf(sstr[2], sizeof(sstr[2]), "screen_EndY_%s   = %%d", spres[pres]);
			snprintf(sstr[3], sizeof(sstr[3]), "screen_StartY_%s = %%d", spres[pres]);
		}
		else
		{
			snprintf(sstr[0], sizeof(sstr[0]), "screen_EndX_%s_%d   = %%d", spres[pres], resolution);
			snprintf(sstr[1], sizeof(sstr[1]), "screen_StartX_%s_%d = %%d", spres[pres], resolution);
			snprintf(sstr[2], sizeof(sstr[2]), "screen_EndY_%s_%d   = %%d", spres[pres], resolution);
			snprintf(sstr[3], sizeof(sstr[3]), "screen_StartY_%s_%d = %%d", spres[pres], resolution);
		}
		buffer = NULL;
		len = 0;
		while ((read = getline(&buffer, &len, fd)) != -1)
		{
			for (loop = 0; loop < 4; loop++)
			{
				sscanf(buffer, sstr[loop], sptr[loop]);
			}
		}
		fclose(fd);
		if (buffer)
			free(buffer);
	}
}

int scale2res(int s)
{
	if (var_screeninfo.xres == 1920)
		s += s / 2;

	return s;
}

double bytes_to_ibytes(long long bytes, int *unit)
{
	static const char units[] = {' ', 'k', 'M', 'G'};
	uint8_t i = 0;
	double ibytes = (double)bytes;

	while((ibytes >= 1000.0) && (i < (sizeof(units) - 1)))
	{
		ibytes /= 1024.0;
		++i;
	}
	*unit = (int)units[i];
	return ibytes;
}

int get_active_interface(char *interface_name)
{
	struct ifaddrs *ifaddr, *ifa;
	int family, s;
	char host[NI_MAXHOST];
	int status = -1;

	if (getifaddrs(&ifaddr) == -1) {
		perror("getifaddrs");
		return -1;
	}

	for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
		if (ifa->ifa_addr == NULL)
			continue;

		family = ifa->ifa_addr->sa_family;

		if (family == AF_INET || family == AF_INET6) {
			s = getnameinfo(ifa->ifa_addr,
							(family == AF_INET) ? sizeof(struct sockaddr_in) :
												sizeof(struct sockaddr_in6),
							host, NI_MAXHOST,
							NULL, 0, NI_NUMERICHOST);
			if (s != 0) {
				printf("getnameinfo() failed: %s\n", gai_strerror(s));
				continue;
			}
			if (strcmp(host, "127.0.0.1") == 0 || strcmp(host, "::1") == 0) {
				continue; // skip loopback interface
			}
			if (ifa->ifa_flags & IFF_RUNNING) {
				strcpy(interface_name, ifa->ifa_name);
				status = 0;
				break;
			}
		}
	}

	freeifaddrs(ifaddr);
	return status;
}

int init_fb(void)
{
	char *tstr = NULL;
	static char menucoltxt[][25] = {"Content_Selected_Text", "Content_Selected",
									"Content_Text", "Content", "Content_inactive_Text", "Content_inactive",
									"Head_Text", "Head"};
	int index = 0, cindex = 0, tv;

	fb = open(FB_DEVICE, O_RDWR);
	if (fb < 0)
		fb = open(FB_DEVICE_FALLBACK, O_RDWR);
	if (fb == -1)
	{
		perror(__plugin__ " <open framebuffer device failed>");
		exit(1);
	}

	if (ioctl(fb, FBIOGET_FSCREENINFO, &fix_screeninfo) == -1)
	{
		printf("%s <FBIOGET_FSCREENINFO failed>\n", __plugin__);
		return -1;
	}
	if (ioctl(fb, FBIOGET_VSCREENINFO, &var_screeninfo) == -1)
	{
		printf("%s <FBIOGET_VSCREENINFO failed>\n", __plugin__);
		return -1;
	}
	if (ioctl(fb, FBIOGET_FSCREENINFO, &fix_screeninfo) == -1 ||
	    ioctl(fb, FBIOGET_VSCREENINFO, &var_screeninfo) == -1 ||
	    !(lfb = (uint32_t *)mmap(0, fix_screeninfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fb, 0)))
	{
		printf("%s <mapping of Framebuffer failed>\n", __plugin__);
		return -1;
	}

	if ((tstr = malloc(BUFSIZE + 1)) == NULL)
	{
		printf("%s", NOMEM);
		return -1;
	}

	for (index = CMCST; index <= CMH; index++)
	{
		snprintf(tstr, BUFSIZE, "menu_%s_alpha", menucoltxt[index]);
		if ((tv = Read_Neutrino_Cfg(tstr)) >= 0)
			tr[index] = 255 - (float)tv * 2.55;

		snprintf(tstr, BUFSIZE, "menu_%s_blue", menucoltxt[index]);
		if ((tv = Read_Neutrino_Cfg(tstr)) >= 0)
			bl[index] = (float)tv * 2.55;

		snprintf(tstr, BUFSIZE, "menu_%s_green", menucoltxt[index]);
		if ((tv = Read_Neutrino_Cfg(tstr)) >= 0)
			gn[index] = (float)tv * 2.55;

		snprintf(tstr, BUFSIZE, "menu_%s_red", menucoltxt[index]);
		if ((tv = Read_Neutrino_Cfg(tstr)) >= 0)
			rd[index] = (float)tv * 2.55;
	}

	if (Read_Neutrino_Cfg("rounded_corners") > 0)
	{
		radius = scale2res(1);
		radius_small = scale2res(5);
	}
	else
		radius = radius_small = 0;

	cindex = CMC;
	for (index = COL_MENUCONTENT_PLUS_0; index <= COL_MENUCONTENT_PLUS_3; index++)
	{
		rd[index] = rd[cindex] + 25;
		gn[index] = gn[cindex] + 25;
		bl[index] = bl[cindex] + 25;
		tr[index] = tr[cindex];
		cindex = index;
	}
	snprintf(tstr, BUFSIZE, "infobar_alpha");
	if ((tv = Read_Neutrino_Cfg(tstr)) >= 0)
		tr[COL_SHADOW_PLUS_0] = 255 - (float)tv * 2.55;

	snprintf(tstr,BUFSIZE, "infobar_blue");
	if ((tv = Read_Neutrino_Cfg(tstr)) >= 0)
		bl[COL_SHADOW_PLUS_0] = (float)tv * 2.55 * 0.4;

	snprintf(tstr, BUFSIZE, "infobar_green");
	if ((tv = Read_Neutrino_Cfg(tstr)) >= 0)
		gn[COL_SHADOW_PLUS_0] = (float)tv * 2.55 * 0.4;

	snprintf(tstr, BUFSIZE, "infobar_red");
	if ((tv = Read_Neutrino_Cfg(tstr)) >= 0)
		rd[COL_SHADOW_PLUS_0] = (float)tv * 2.55 * 0.4;

	for (index = 0; index <= COL_SHADOW_PLUS_0; index++)
		bgra[index] = (tr[index] << 24) | (rd[index] << 16) | (gn[index] << 8) | bl[index];

	free(tstr);

#if 1
	sx = scale2res(80);
	ex = var_screeninfo.xres - sx;
	sy = scale2res(50);
	ey = var_screeninfo.yres - sy;
#else
	/* center output on screen */
	read_neutrino_osd_conf(&ex, &sx, &ey, &sy);
	if ((ex == -1) || (sx == -1) || (ey == -1) || (sy == -1))
	{
		sx = 100;
		ex = var_screeninfo.xres - sx;
		sy = 60;
		ey = var_screeninfo.yres - sy;
	}

	tv=ex-sx-1060;
	tv=tv/2;
	sx+=tv;

	tv=ey-sy-490;
	tv=tv/2;
	sy+=tv;

	tv=0;

	ex=1060+sx;
	ey=490+sy;
#endif
	// init Fonts
	if ((error = FT_Init_FreeType(&library)))
	{
		printf("%s <FT_Init_FreeType failed with Errorcode 0x%.2X>", __plugin__, error);
		munmap(lfb, fix_screeninfo.smem_len);
		return -1;
	}

	if ((error = FTC_Manager_New(library, 1, 2, 0, &MyFaceRequester, NULL, &manager)))
	{
		printf("%s <FTC_Manager_New failed with Errorcode 0x%.2X>\n", __plugin__, error);
		FT_Done_FreeType(library);
		munmap(lfb, fix_screeninfo.smem_len);
		return -1;
	}

	if ((error = FTC_SBitCache_New(manager, &cache)))
	{
		printf("%s <FTC_SBitCache_New failed with Errorcode 0x%.2X>\n", __plugin__, error);
		FTC_Manager_Done(manager);
		FT_Done_FreeType(library);
		munmap(lfb, fix_screeninfo.smem_len);
		return -1;
	}

	if ((error = FTC_Manager_LookupFace(manager, FONT, &face)))
	{
		if ((error = FTC_Manager_LookupFace(manager, FONT2, &face)))
		{
			printf("%s <FTC_Manager_LookupFace failed with Errorcode 0x%.2X>\n", __plugin__, error);
			FTC_Manager_Done(manager);
			FT_Done_FreeType(library);
			munmap(lfb, fix_screeninfo.smem_len);
			return -1;
		}
		else
			desc.face_id = FONT2;
	}
	else
		desc.face_id = FONT;

	use_kerning = FT_HAS_KERNING(face);
	desc.flags = FT_LOAD_RENDER | FT_LOAD_FORCE_AUTOHINT;

	// init backbuffer
	stride = fix_screeninfo.line_length;
	swidth = stride / sizeof(uint32_t);
	if (stride == 7680 && var_screeninfo.xres == 1280)
	{
		var_screeninfo.yres = 1080;
	}

	if (!(lbb = malloc(var_screeninfo.xres * var_screeninfo.yres * sizeof(uint32_t))))
	{
		printf("%s <allocating of Backbuffer failed>\n", __plugin__);
		FTC_Manager_Done(manager);
		FT_Done_FreeType(library);
		munmap(lfb, fix_screeninfo.smem_len);
		return -1;
	}

	memset(lbb, 0, var_screeninfo.xres * var_screeninfo.yres * sizeof(uint32_t));
	memcpy(lfb, lbb, var_screeninfo.xres * var_screeninfo.yres * sizeof(uint32_t));
	//printf("%s init fb done\n", __plugin__);

	return 0;
}

int Read_Neutrino_Cfg(char *entry)
{
	FILE *nfh;
	char tstr[512] = {0}, *cfptr = NULL;
	int rv = -1;

	if ((nfh = fopen(NCFFILE, "r")) != NULL)
	{
		tstr[0] = 0;

		while ((!feof(nfh)) && ((strstr(tstr, entry) == NULL) || ((cfptr = strchr(tstr, '=')) == NULL)))
		{
			fgets(tstr, 500, nfh);
		}
		if (!feof(nfh) && cfptr)
		{
			++cfptr;
			if (sscanf(cfptr, "%d", &rv) != 1)
			{
				if (strstr(cfptr, "true") != NULL)
				{
					rv = 1;
				}
				else
				{
					if (strstr(cfptr, "false") != NULL)
					{
						rv = 0;
					}
					else
					{
						rv = -1;
					}
				}
			}
			if ((strncmp(entry, tstr, 10) == 0) && (strncmp(entry, "font_file=", 10) == 0))
			{
				sscanf(tstr, "font_file=%127s", FONT);
				rv = 1;
			}
			// printf("%s\n%s=%s -> %d\n",tstr,entry,cfptr,rv);
		}
		fclose(nfh);
	}
	return rv;
}

void correct_string(char *strg)
{
	if (strg == NULL) {
		return;
	}

	// Leerzeichen und Zeilenumbrüche am Anfang entfernen
	char *start = strg;
	while (*start && isspace((unsigned char)*start)) {
		++start;
	}

	// Leerzeichen und Zeilenumbrüche am Ende entfernen
	char *end = strg + strlen(strg) - 1;
	while (end >= start && (isspace((unsigned char)*end) || *end == '\n')) {
		--end;
	}

	// Null-Terminierung setzen
	*(end + 1) = '\0';

	// Verschieben des bereinigten Strings, falls erforderlich
	if (start > strg) {
		memmove(strg, start, end - start + 2);
	}
}

void corr(char *aus, const char *temp, size_t size)
{
	char temp_data[256] = {0};
	snprintf(temp_data, sizeof(temp_data), temp);
	int z=0;
	while (temp_data[z]!=0)
	{
		if(temp_data[z] > 0 && temp_data[z] <= 32)
			temp_data[z]=0;
		z++;
	}
	snprintf(aus, size, "%s", temp_data);
}

void daten_auslesen(const char *buffer, char *ergebnis, const size_t size, const char symbol1, const char symbol2)
{
	size_t count = 0, i = 0;
	while ((buffer[count] != symbol1) && (count < strlen(buffer)))
	{
		count++;
	}
	count++;
	while (isspace(buffer[count]))
	{
		count++;
	}
	while ((buffer[count] != symbol2) && (count < strlen(buffer)))
	{
		ergebnis[i] = buffer[count];
		i++;
		count++;
		if (i >= size - 1)
		{
			break;
		}
	}
	ergebnis[i] = '\0';
}

int get_date(void)
{
	long t = time(NULL);
	struct tm *tp;
	tp = localtime(&t);
	snprintf(zeit, sizeof(zeit), "%02d:%02d:%02d", tp->tm_hour, tp->tm_min, tp->tm_sec);
	snprintf(datum, sizeof(datum), "%02d.%02d.%4d", tp->tm_mday, (tp->tm_mon + 1), (1900 + tp->tm_year));
	return 0;
}

void update_zeit(void)
{
	int len = GetStringLen("88:88:88", FSIZE_SMALL + 2)+ OFFSET_MIN;
	get_date();
	RenderBox(ex - scale2res(150), sy + rahmen, ex - rahmen, linie_oben - rabs, FILL, CMCST, 0); // CMCST
	RenderString(zeit, ex - scale2res(136), sy + 3 * OFFSET_MED + OFFSET_MIN, scale2res(120), LEFT, FSIZE_SMALL + 2, CMCT);
	RenderString("Uhr", ex - scale2res(136)+len, sy + 3 * OFFSET_MED + OFFSET_MIN, scale2res(50), LEFT, FSIZE_SMALL + 2, CMCT);
	RenderString(datum, ex - scale2res(135), sy + 5 * OFFSET_MED + OFFSET_MIN, scale2res(100), CENTER, FSIZE_SMALL, CMCT);
	memcpy(lfb, lbb, var_screeninfo.xres * var_screeninfo.yres * sizeof(uint32_t));
}

void read_cpu_stats(long* cpu_array) {
	FILE* f = fopen("/proc/stat", "r");
	char line[MAXLINES];

	if (f) {
		fgets(line, MAXLINES, f);
		sscanf(line, "cpu %lu %lu %lu %lu", &cpu_array[1], &cpu_array[2], &cpu_array[3], &cpu_array[4]);
		cpu_array[0] = cpu_array[1] + cpu_array[2] + cpu_array[3] + cpu_array[4];
		fclose(f);
	} else {
		perror("Failed to read /proc/stat");
		return;
	}
}

void update_perf(double* perf, long* curCPU, long* prevCPU) {
	float faktor;
	int i;

	if ((curCPU[0] - prevCPU[0]) != 0) {
		faktor = 100.0 / (curCPU[0] - prevCPU[0]);
		for (i = 0; i < 4; i++)
			perf[i] = (curCPU[i] - prevCPU[i]) * faktor;

		perf[4] = 100.0 - perf[1] - perf[2] - perf[3];
	}
}

void get_perf() {
	double perf[5] = {0, 0, 0, 0, 0};
	long curCPU[5] = {0, 0, 0, 0, 0};
	long prevCPU[5] = {0, 0, 0, 0, 0};

	read_cpu_stats(prevCPU);
	sleep(1);
	read_cpu_stats(curCPU);
	while (((curCPU[0] - prevCPU[0]) < 100) || (curCPU[0] == 0)) {
		read_cpu_stats(curCPU);
	}
	update_perf(perf, curCPU, prevCPU);

	user_perf = perf[1];
	nice_perf = perf[2];
	sys_perf = perf[3];
	idle_perf = perf[4];
}

int get_uptime(void)
{
	FILE *fd;
	char line[MAXLINES];
	fd = fopen("/proc/uptime", "r");
	if (fd)
	{
		fgets(line, 256, fd);
		float ret[4];
		const char *strTage[2] = {"T", "T"};
		const char *strStunden[2] = {"Std", "Std"};
		const char *strMinuten[2] = {"Min", "Min"};
		sscanf(line, "%f", &ret[0]);
		ret[0] = ret[0] / 60;
		ret[1] = (long)(ret[0]) / 60 / 24;
		ret[2] = (long)(ret[0]) / 60 - (long)(ret[1]) * 24;
		ret[3] = (long)(ret[0]) - (long)(ret[2]) * 60 - (long)(ret[1]) * 60 * 24;
		fclose(fd);
		snprintf(uptime, sizeof(uptime),"%.0f %s - %.0f %s - %.0f %s\n", ret[1], strTage[(int)(ret[1]) == 1], ret[2], strStunden[(int)(ret[2]) == 1], ret[3], strMinuten[(int)(ret[3]) == 1]);
	}
	correct_string(uptime);
	return 0;
}

int read_nim_socket(char chip_name[][MAX_NAME_LEN], int max_names)
{
	if (access("/proc/bus/nim_sockets", F_OK) == -1) {

		return -1;
	}
	int i;
	FILE *file = NULL;
	if ((file = fopen("/proc/bus/nim_sockets", "r")) == NULL)
	{
		printf("cannot open /proc/mim_sockets\n");
		return -1;
	}
	else
	{
		int index = 0;
		char* line = NULL;
		size_t len = 0;
		ssize_t read;
		while ((read = getline(&line, &len, file)) != -1 && index < max_names) {
			char* pos = strstr(line, "Name:");
			if (pos != NULL) {
				pos += strlen("Name:");
				while (isspace(*pos)) {
					pos++;
				}
				safe_strncpy(chip_name[index], pos, MAX_NAME_LEN);
				index++;
			}
		}
		fclose(file);
		free(line);
		if (index > 0)
		{
			for (i = 0; i < index; i++)
			{
				char temp[MAX_NAME_LEN + 2];
				snprintf(temp, MAX_NAME_LEN + 2, "(%s)", chip_name[i]);
				safe_strncpy(chip_name[i], temp, MAX_NAME_LEN);
			}
		}
	}
	return 0;
}

int get_info_cpu(void)
{
	FILE *file = NULL;
	char *ptr = NULL;
	char line_buffer[512] = "";
	if ((file = fopen("/proc/cpuinfo", "r")) == NULL)
	{

		printf("cannot open /proc/cpuinfo\n");
		return -1;
	}
	else
	{
		while (fgets(line_buffer, sizeof(line_buffer), file))
		{
			if ((ptr = strstr(line_buffer, "processor")) != NULL)
			{
				daten_auslesen(line_buffer, cores, sizeof(cores), ':', '\n');
			}
#if HAVE_SH4_HARDWARE
			if ((ptr = strstr(line_buffer, "cpu type")) != NULL)
			{
				daten_auslesen(line_buffer, processor, sizeof(processor),':', '\n');
			}
			if ((ptr = strstr(line_buffer, "bogomips")) != NULL)
			{
				daten_auslesen(line_buffer, bogomips, sizeof(bogomips),':', '\n');
			}
#else
			if ((ptr = strstr(line_buffer, "Processor")) != NULL)
			{
				daten_auslesen(line_buffer, processor, sizeof(processor),':', '\n');
			}
			if ((ptr = strstr(line_buffer, "BogoMIPS")) != NULL)
			{
				daten_auslesen(line_buffer, bogomips, sizeof(bogomips),':', '\n');
			}
#endif

			if ((ptr = strstr(line_buffer, "Features")) != NULL)
			{
				daten_auslesen(line_buffer, features, sizeof(features),':', '\n');
			}

#if HAVE_SH4_HARDWARE
			if ((ptr = strstr(line_buffer, "machine")) != NULL)
			{
				daten_auslesen(line_buffer, hardware, sizeof(hardware),':', '\n');
			}
			if ((ptr = strstr(line_buffer, "cut")) != NULL)
			{
				daten_auslesen(line_buffer, hard_rev, sizeof(hard_rev),':', '\n');
			}
#else
			if ((ptr = strstr(line_buffer, "Hardware")) != NULL)
			{
				daten_auslesen(line_buffer, hardware, sizeof(hardware),':', '\n');
			}
			if ((ptr = strstr(line_buffer, "Revision")) != NULL)
			{
				daten_auslesen(line_buffer, hard_rev, sizeof(hard_rev),':', '\n');
			}
#endif
		}
		fclose(file);
	}

	if (atoi(bogomips) == 0)
	{
		file = fopen("/sys/kernel/debug/clk/fixed0/clk_rate", "r");
		if (file)
		{
			fgets(line_buffer, sizeof(line_buffer), file);
			snprintf(bogomips, sizeof(bogomips), "%.2f", atof(line_buffer) / 1000000);
			fclose(file);
		}
	}

	file = fopen("/proc/version", "r");
	if (file)
	{
		while (fgets(line_buffer, sizeof(line_buffer), file))
		{
			if ((ptr = strstr(line_buffer, "Linux")) != NULL)
			{
				snprintf(kernel, sizeof(kernel), "%s", line_buffer);
			}
		}
		fclose(file);
	}
	correct_string(kernel);
	return 0;
}

int get_df(void)
{
	FILE *f;
	char line[512];
	int got;
	system("df -h > /tmp/systmp");
	if ((f = fopen("/tmp/systmp", "r")) != NULL)
	{
		FS_count = 0;
		while ((fgets(line, 512, f) != NULL && FS_count < MAX_FS))
		{
			got = sscanf(line, "%s %s %s %s %s %s ", Filesystem[FS_count], FS_total[FS_count], FS_used[FS_count], FS_free[FS_count], FS_percent[FS_count], FS_mount[FS_count]);
			if (got == 1)
				if (fgets(line + strlen(line), 512 - strlen(line), f) != 0)
					got = sscanf(line, "%s %s %s %s %s %s ", Filesystem[FS_count], FS_total[FS_count], FS_used[FS_count], FS_free[FS_count], FS_percent[FS_count], FS_mount[FS_count]);
			if (got == 6 && isdigit(FS_used[FS_count][0]))
				FS_count++;
		}
		fclose(f);
	}
	return 0;
}

void rc_Nnull(int mu)
{

	while (ev.value != 0)
	{
		if (mu == 1)
			up_main_mem();
		if (mu == 2)
			up_full(1);
		if (mu == 3)
			up_full(2);
		if (mu == 4)
			up_net();
		update_zeit();
		GetRCCode();
	}
}

void rc_null(int mu)
{

	while (ev.value == 0)
	{
		if (mu == 1)
			up_main_mem();
		if (mu == 2)
			up_full(1);
		if (mu == 3)
			up_full(2);
		if (mu == 4)
			up_net();
		update_zeit();
		GetRCCode();
	}
}

int show_FileS(void)
{
	int lauf = 0, p_start = 0, svar = 0, v_abs = 0, v_next = 0, z = 0, size = FSIZE_MED, end_show = 0, anz = 6;
	int iw = 0, ih = 0;
	int icon_w = 0, icon_h = 0;
	int maxwidth = scale2res(400);
	int spalte[2] = {0, 0};
	spalte[0] = sx + 4 * OFFSET_MED;
	spalte[1] = ex - sx;
	spalte[1] = spalte[1] / 2;
	spalte[1] = spalte[1] + sx;

	get_df();
	while (end_show == 0)
	{
		z = 0;
		v_abs = scale2res(45);
		hintergrund();
		p_start = lauf;

		if ((lauf + anz) < FS_count)
		{
			png_getsize(ICON_BUTTON_DOWN, &icon_w, &icon_h);
			paintIcon(ICON_BUTTON_DOWN, sx + scale2res(16 + (icon_w / 2)), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
			RenderString("WEITER", sx + scale2res(50), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
		}
		if (p_start > 0)
		{
			png_getsize(ICON_BUTTON_UP, &icon_w, &icon_h);
			paintIcon(ICON_BUTTON_UP, sx + scale2res(15 + (icon_w / 2)) + (int)((ex - sx - 3 * OFFSET_MED) / 4), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
			RenderString("ZURÜCK", sx + scale2res(50) + (int)((ex - sx - 3 * OFFSET_MED) / 4), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
		}
		png_getsize(ICON_BUTTON_HOME, &icon_w, &icon_h);
		paintIcon(ICON_BUTTON_HOME, sx + scale2res(34 + (icon_w / 2)) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 3), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
		RenderString("EXIT", sx + scale2res(76) + (((ex - sx - 3 * OFFSET_MED) / 4) * 3), ey - 2 * OFFSET_SMALL, scale2res(300), LEFT, FSIZE_SMALL, CMCT);

		int slen = GetStringLen("Mountpunkt:", size);
		for (svar = 0; (svar < anz) && (lauf < FS_count); svar++)
		{
			v_next = scale2res(24);
			RenderString("Verzeichnis:", spalte[z], (linie_oben + v_abs), maxwidth, LEFT, size, CMHT);
			RenderString(Filesystem[lauf], spalte[z] + slen + OFFSET_MED, (linie_oben + v_abs), maxwidth, LEFT, size, CMCT);

			RenderString("Mountpunkt:", spalte[z], (linie_oben + v_abs + v_next), maxwidth, LEFT, size, CMHT);
			RenderString(FS_mount[lauf], spalte[z] + slen + OFFSET_MED, (linie_oben + v_abs + v_next), maxwidth, LEFT, size, CMCT);

			v_next += scale2res(24);
			RenderString("Größe:", spalte[z], (linie_oben + v_abs + v_next), maxwidth, LEFT, size, CMHT);
			RenderString(FS_total[lauf], spalte[z] + slen + OFFSET_MED, (linie_oben + v_abs + v_next), maxwidth, LEFT, size, CMCT);

			v_next += scale2res(24);
			RenderString("Genutzt:", spalte[z], (linie_oben + v_abs + v_next), maxwidth, LEFT, size, CMHT);
			RenderString(FS_used[lauf], spalte[z] + slen + OFFSET_MED, (linie_oben + v_abs+ v_next), maxwidth, LEFT, size, CMCT);

			v_next += scale2res(24);
			RenderString("Frei:", spalte[z], (linie_oben + v_abs + v_next), maxwidth, LEFT, size, CMHT);
			RenderString(FS_free[lauf], spalte[z] + slen + OFFSET_MED, (linie_oben + v_abs + v_next), maxwidth, LEFT, size, CMCT);

			v_next += scale2res(24);
			RenderString("Belegt:", spalte[z], (linie_oben + v_abs + v_next), maxwidth, LEFT, size, CMHT);

			char prozent[16];
			strcpy(prozent, FS_percent[lauf]);
			prozent[strlen(prozent)-1] = '\0';
			int proz = atoi(prozent);
			draw_progressbar(spalte[z] + slen + OFFSET_MED, linie_oben + scale2res(100) + v_abs,
					spalte[z] + slen + scale2res(135), linie_oben + scale2res(116) + v_abs, PB_LEFT_GREEN70, proz);

			RenderString(FS_percent[lauf], spalte[z] + slen + scale2res(140) + OFFSET_MED, (linie_oben + v_abs + v_next), maxwidth, LEFT, FSIZE_SMALL, CMCT);
			z++; // rem for 1 column
			lauf++;
			if (z > 1) // rem for 1 colums
			{
				z = 0; // rem for 1 colums
				v_abs = v_abs + scale2res(164);
			}
		}
		rc_Nnull(0);
		rc_null(0);
		switch (ev.code)
		{
		case KEY_UP:
			lauf = p_start - anz;
			if (lauf < 0)
				lauf = 0;
			break;

		case KEY_DOWN:
			if (lauf >= FS_count)
				lauf = p_start;
			break;
		case KEY_OK:
		case KEY_HOME:
		case KEY_EXIT:
			end_show = 1;
			break;
		default:
			lauf = p_start;
		}
	}
	rc_Nnull(0);
	return 0;
}

int show_ps_status(int psnum)
{
	FILE *f;
	int end_show = 0, i = 0, v_abs = scale2res(21), abs = 0, bstart = 0, y = 0, end_temp = 0;
	int iw = 0, ih = 0;
	int icon_w = 0, icon_h = 0;
	int maxwidth = scale2res(300), max_lines = 22;

	char line[256];
	snprintf(line, sizeof(line), "/proc/%d/status", psnum);
	if ((f = fopen(line, "r")) != NULL)
	{
		while (end_show == 0)
		{
			abs = scale2res(38);
			end_temp = 0;
			hintergrund();

			RenderBox(sx + OFFSET_MED, linie_oben + OFFSET_MED, ex - OFFSET_MED, linie_unten - OFFSET_MED, FILL, CMCST, 0); // CMCST
			png_getsize(ICON_BUTTON_DOWN, &icon_w, &icon_h);
			paintIcon(ICON_BUTTON_DOWN, sx + scale2res(16 + (icon_w / 2)), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
			RenderString("WEITER", sx + scale2res(50), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
			if (bstart >= max_lines)
			{
				png_getsize(ICON_BUTTON_UP, &icon_w, &icon_h);
				paintIcon(ICON_BUTTON_UP, sx + scale2res(15 + (icon_w / 2)) + (int)((ex - sx - 3 * OFFSET_MED) / 4), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
				RenderString("ZURÜCK", sx + scale2res(50) + (int)((ex - sx - 3 * OFFSET_MED) / 4), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
			}
			png_getsize(ICON_BUTTON_HOME, &icon_w, &icon_h);
			paintIcon(ICON_BUTTON_HOME, sx + scale2res(34 + (icon_w / 2)) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 3), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
			RenderString("EXIT", sx + scale2res(76) + (((ex - sx - 3 * OFFSET_MED) / 4) * 3), ey - 2 * OFFSET_SMALL, scale2res(300), LEFT, FSIZE_SMALL, CMCT);

			for (i = 0; i < max_lines; i++)
			{
				if (fgets(line, 256, f) != NULL)
				{
					correct_string(line);
					RenderString(line, sx + scale2res(40), (linie_oben + abs), ex - sx - scale2res(40), LEFT, scale2res(22), CMCT);
					abs = v_abs + abs;
				}
				else
				{
					end_temp = 1;
					RenderBox(sx + scale2res(11), linie_unten + 2 * OFFSET_MIN, sx + OFFSET_MED + (int)(ex - sx - 3 * OFFSET_MED) / 4, ey - 4 * OFFSET_MIN, FILL, CMCST, 0); // CMCST
				}
			}
			rc_Nnull(0);
			rc_null(0);
			switch (ev.code)
			{
			case KEY_UP:
				fseek(f, 0L, SEEK_SET);
				if (bstart < max_lines)
				{
					bstart = 0;
				}
				else
				{
					bstart = bstart - max_lines;
				}
				for (y = 0; y < bstart; y++)
				{
					fgets(line, 256, f);
				}
				break;

			case KEY_DOWN:
				if (end_temp != 0)
				{
					fseek(f, 0L, SEEK_SET);
					for (y = 0; y < bstart; y++)
					{
						fgets(line, 256, f);
					}
				}
				else
				{
					bstart = bstart + max_lines;
				}
				break;
			case KEY_HOME:
			case KEY_EXIT:
				end_show = 1;
				break;

			case KEY_OK:
				end_show = 1;
				break;

			default:
				fseek(f, 0L, SEEK_SET);
				for (y = 0; y < bstart; y++)
					fgets(line, 256, f);
				break;
			}
		}
		fclose(f);
	}
	else
	{
		RenderBox(sx + scale2res(350), sy + scale2res(215), ex - scale2res(350), sy + scale2res(300), FILL, CMH, 0);
		RenderBox(sx + scale2res(350), sy + scale2res(215), ex - scale2res(350), sy + scale2res(300), GRID, CMCIT, 0);
		RenderString("Prozess beendet!", sx + scale2res(420), sy + scale2res(265), scale2res(150), CENTER, FSIZE_BIG, CMCT);
		update_zeit();
		sleep(3);
	}
	rc_Nnull(0);
	return 0;
}

int show_ps_dmseg(char quote)
{
	int end_show = 0, i = 0, v_abs = 2 * OFFSET_MED, abs = 0, bstart = 0, y = 0, z = 0, end_temp = 0, ps_end = 0, ps_pointer = 0, endf = 10000;
	int maxwidth = scale2res(300), max_lines = 23;
	int iw = 0, ih = 0;
	int icon_w = 0, icon_h = 0;
	char line[256] = "";
	char temp[10] = "";
	FILE *f;

	if (quote == 0)
	{
		system("dmesg > /tmp/systmp");
	}
	else
	{
		struct stat buf;
		int xx;
		system("ps -A > /tmp/systmp");
		xx = stat("/tmp/systmp", &buf);
		if (buf.st_size == 0)
			system("ps > /tmp/systmp");
	}
	if ((f = fopen("/tmp/systmp", "r")) != NULL)
	{
		while (end_show == 0)
		{
			endf = 10000;
			abs = scale2res(45);
			end_temp = 0;
			hintergrund();
			RenderBox(sx + OFFSET_MED, linie_oben + OFFSET_MED, ex - OFFSET_MED, linie_unten - OFFSET_MED, FILL, CMCST, 0); // CMCST

			png_getsize(ICON_BUTTON_DOWN, &icon_w, &icon_h);
			paintIcon(ICON_BUTTON_DOWN, sx + scale2res(16 + (icon_w / 2)), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
			RenderString("WEITER", sx + scale2res(50), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
			if (bstart >= max_lines)
			{
				png_getsize(ICON_BUTTON_UP, &icon_w, &icon_h);
				paintIcon(ICON_BUTTON_UP, sx + scale2res(15 + (icon_w / 2)) + (int)((ex - sx - 3 * OFFSET_MED) / 4), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
				RenderString("ZURÜCK", sx + scale2res(50) + (int)((ex - sx - 3 * OFFSET_MED) / 4), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
			}
			if (quote != 0)
			{
				png_getsize(ICON_BUTTON_OK, &icon_w, &icon_h);
				paintIcon(ICON_BUTTON_OK, sx + scale2res(+(icon_w / 2)) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 2), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
				RenderString("PROZESSSTATUS", sx + scale2res(40) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 2), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
			}
			png_getsize(ICON_BUTTON_HOME, &icon_w, &icon_h);
			paintIcon(ICON_BUTTON_HOME, sx + scale2res(34 + (icon_w / 2)) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 3), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
			RenderString("EXIT", sx + scale2res(76) + (((ex - sx - 3 * OFFSET_MED) / 4) * 3), ey - 2 * OFFSET_SMALL, scale2res(300), LEFT, FSIZE_SMALL, CMCT);

			for (i = 0; i < max_lines; i++)
			{
				if (fgets(line, 256, f) != NULL)
				{
					correct_string(line);
					if (quote == 0)
						RenderString(line, sx + scale2res(25), linie_oben + abs, ex - sx - scale2res(40), LEFT, scale2res(22), CMCT);
					else
						RenderString(line, sx + scale2res(50), (linie_oben + abs), ex - sx - scale2res(40), LEFT, scale2res(22), CMCT);
					abs = v_abs + abs;
				}
				else
				{
					if (end_temp == 0)
						endf = bstart + i;
					end_temp = 1;
					RenderBox(sx + scale2res(11), linie_unten + 2 * OFFSET_MIN, sx + 2 * OFFSET_MED + (int)(ex - sx - 3 * OFFSET_MED) / 4, ey - 4 * OFFSET_MIN, FILL, CMCST, 0); // CMCST
				}
			}
			rc_Nnull(0);
			rc_null(0);
			abs = scale2res(45);
			switch (ev.code)
			{
			case KEY_UP:
				fseek(f, 0L, SEEK_SET);
				if (bstart < max_lines)
				{
					bstart = 0;
				}
				else
				{
					bstart = bstart - max_lines;
				}
				for (y = 0; y < bstart; y++)
					fgets(line, 256, f);
				break;

			case KEY_DOWN:
				if (end_temp != 0)
				{
					fseek(f, 0L, SEEK_SET);
					for (y = 0; y < bstart; y++)
						fgets(line, 256, f);
				}
				else
				{
					bstart = bstart + max_lines;
				}
				break;

			case KEY_HOME:
			case KEY_EXIT:
				end_show = 1;
				break;

			case KEY_OK:
				if (quote != 0)
				{
					//							printf("aussseeeen i= %d - ps_pointer = %d - endf= %d\n",i,ps_pointer,endf); fflush(stdout);
					RenderBox(sx + 2 * ((ex - sx - 3 * OFFSET_MED) / 4), linie_unten + 2 * OFFSET_MIN, sx + 4 * OFFSET_MED + (((ex - sx - 3 * OFFSET_MED) / 4) * 3), ey - 4 * OFFSET_MIN, FILL, CMCST, 0); // CMCST
					png_getsize(ICON_BUTTON_INFO, &icon_w, &icon_h);
					paintIcon(ICON_BUTTON_INFO, sx + scale2res((icon_w / 2)) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 2), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
					RenderString("PROZESSSTATUS", sx + scale2res(40) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 2), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMHT);

					ps_pointer = bstart;
					i = 0;
					ps_end = 0;
					while (ps_end == 0)
					{
						if ((bstart + i) == 0)
						{
							i = 1;
							abs = abs + v_abs;
						}
						ps_pointer = bstart + i;
						RenderBox(sx + scale2res(15), linie_oben + scale2res(10), sx + scale2res(44), linie_unten - scale2res(10), FILL, CMCST, 0); // CMCST
						RenderString(">", sx + 3 * OFFSET_MED, linie_oben + abs + 2*OFFSET_MIN, scale2res(20), LEFT, FSIZE_BIG, CMHT);				// CMHT

						RenderBox(sx + OFFSET_MED, linie_unten + 2 * OFFSET_MIN, sx + scale2res(480), ey - 4 * OFFSET_MIN, FILL, CMCST, 0); // CMCST
						if (i < max_lines - 1)
						{
							png_getsize(ICON_BUTTON_DOWN, &icon_w, &icon_h);
							paintIcon(ICON_BUTTON_DOWN, sx + scale2res(16 + (icon_w / 2)), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
							RenderString("WEITER", sx + scale2res(50), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
						}
						if (i > 0 && ps_pointer > 1)
						{
							png_getsize(ICON_BUTTON_UP, &icon_w, &icon_h);
							paintIcon(ICON_BUTTON_UP, sx + scale2res(15 + (icon_w / 2)) + (int)((ex - sx - 3 * OFFSET_MED) / 4), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
							RenderString("ZURÜCK", sx + scale2res(50) + (int)((ex - sx - 3 * OFFSET_MED) / 4), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
						}
						rc_Nnull(0);
						rc_null(0);
						// RenderBox(sx+scale2res(15),linie_oben+scale2res(10), sx+scale2res(42), linie_unten-scale2res(10), FILL, BLUE0, 0); //CMCST

						switch (ev.code)
						{
						case KEY_UP:
							if ((i > 0) && (ps_pointer > 1))
							{
								abs = abs - v_abs; //-v_abs;
								i--;
								// i--;
							}
							break;

						case KEY_DOWN:
							if ((i < max_lines - 1) && (ps_pointer < (endf - 1)))
							{
								;
								abs = v_abs + abs;
								i++;
							}
							break;

						case KEY_HOME:
						case KEY_EXIT:
							ps_end = 1;
							break;

						case KEY_HELP:
						case KEY_INFO: // Info
							fseek(f, 0L, SEEK_SET);
							for (y = 0; y <= ps_pointer; y++)
								fgets(line, 256, f);
							y = 0;
							z = 0;
							while (!isdigit(line[y]))
								y++;
							while (!isspace(line[y]))
							{
								temp[z] = line[y];
								y++;
								z++;
							}
							temp[z] = 0;
							sscanf(temp, "%d", &y);
							show_ps_status(y);
							ps_end = 1;
							break;
							//	break;
						}
					}
					//	ps_end=0;
				}
				fseek(f, 0L, SEEK_SET);
				for (y = 0; y < bstart; y++)
					fgets(line, 256, f);
				ps_end = 0;
				break;

			default:
				fseek(f, 0L, SEEK_SET);
				for (y = 0; y < bstart; y++)
				{
					fgets(line, 256, f);
				}
			}
		}
		fclose(f);
	}
	rc_Nnull(0);
	return 0;
}

int get_mem(void)
{
	FILE *file = NULL;
	char line_buffer[256] = "";
	if ((file = fopen("/proc/meminfo", "rb")) == NULL)
	{
		printf("cannot open /proc/meminfo\n");
		return -1;
	}
	else
	{
		while (fgets(line_buffer, sizeof(line_buffer), file))
		{
			if (strncmp(line_buffer, "MemTotal:", 9) == 0)
			{
				memtotal = strtol(line_buffer + 9, NULL, 10);
			}
			else if (strncmp(line_buffer, "MemFree:", 8) == 0)
			{
				memfree = strtol(line_buffer + 8, NULL, 10);
			}
			else if (strncmp(line_buffer, "Active:", 7) == 0)
			{
				memactive = strtol(line_buffer + 7, NULL, 10);
			}
			else if (strncmp(line_buffer, "Inactive:", 9) == 0)
			{
				meminakt = strtol(line_buffer + 9, NULL, 10);
			}
		}
		fclose(file);
	}
	memused = memtotal - memfree;
	memtotal /= 1024.0;
	memused /= 1024.0;
	memfree /= 1024.0;
	memactive /= 1024.0;
	meminakt /= 1024.0;
	return 0;
}

int get_boxinfo(char* vendor,char* boxname, char* boxarch)
{
	FILE *pipe;
	int ret = -1;
	char buffer[128];

	pipe = popen("wget http://127.0.0.1/control/boxinfo -q -O -", "r");
	if (pipe == NULL) {
		perror("popen");
		return -1;
	}

	while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
		// Prozessiere jede Zeile der Ausgabe
		char *equalsign = strchr(buffer, '=');
		if (equalsign != NULL) {
			*equalsign = '\0';			// Setze das "="-Zeichen auf Null, um den Key zu terminieren
			char *value = equalsign + 1;		// Zeiger auf das Value
			value[strcspn(value, "\n")] = '\0';	// Entferne den Zeilenumbruch, falls vorhanden

			// Speichere die Werte entsprechend den übergebenen Zeigern
			if (strcmp(buffer, "vendor") == 0) {
				strcpy(vendor, value);
			} else if (strcmp(buffer, "boxname") == 0) {
				strcpy(boxname, value);
			} else if (strcmp(buffer, "boxarch") == 0) {
				strcpy(boxarch, value);
			}
			ret = 0;
		}
	}
	pclose(pipe);
	return ret;
}

void get_imagename(const char* filename, char* out) {
	FILE* fp = fopen(filename, "r");
	if (fp == NULL) {
		*out = '\0';
		perror("Fehler beim Oeffnen der Datei");
		return;
	}

	char line[256];
	char* start = NULL;
	while (fgets(line, sizeof(line), fp) != NULL) {
		if ((start = strstr(line, "imagename=")) != NULL) {
			start += strlen("imagename=");
			break;
		}
	}

	fclose(fp);

	if (start == NULL) {
		*out = '\0';
		return;
	}

	correct_string(start);
	strcpy(out, start);
}

void hintergrund(void)
{
	char vstr[256];
	char vendor[32];
	char imgname[64];
	char boxname[32];
	char boxarch[32];

	setBackground(CMCST);
	RenderBox(sx, sy, ex, ey, FILL, CMCIT, 0);

	RenderBox(sx + rahmen, sy + rahmen, ex - rahmen, linie_oben - rabs, FILL, CMCST, 0);			// CMCST
	RenderBox(sx + rahmen, linie_oben + rabs - 1, ex - rahmen, linie_unten - rabs + 1, FILL, CMH, 0);	// CMH
	RenderBox(sx + rahmen, linie_unten + rabs, ex - rahmen, ey - rahmen, FILL, CMCST, 0);			// CMCST

	RenderBox(sx + rabs, sy + rabs, ex - rabs, linie_oben, GRID, CMCST, 0);					// CMCST
	RenderBox(sx + rabs, linie_oben - 1, ex - rabs, linie_unten + 1, GRID, CMCST, 0);			// CMCST
	RenderBox(sx + rabs, linie_unten, ex - rabs, ey - rabs, GRID, CMCST, 0);				// CMCST

	snprintf(vstr, sizeof(vstr), "Sysinfo %.2f", SH_VERSION);
	RenderString(vstr, sx + 2 * OFFSET_MED, sy + 4 * OFFSET_MED + 4 * OFFSET_MIN, scale2res(300), LEFT, scale2res(38), GREEN);

	get_imagename(VERSION_FILE, imgname);
	if (get_boxinfo(vendor, boxname, boxarch) == 0) {
		snprintf(vstr, sizeof(vstr), "%s - %s %s (%s)", imgname, vendor, boxname, boxarch);
	}
	else {
		snprintf(vstr, sizeof(vstr), "%s", imgname);
	}
	RenderString(vstr, sx + scale2res(235), sy + 4 * OFFSET_MED + 2 * OFFSET_MIN, scale2res(700), CENTER, scale2res(30), BLUE0); // BLUE3
}

void hauptseite(void)
{
	int i = 0, y = 0, mtd_count = 0, slen = 0, longest_length = 0;
	int abs_links = 0, maxwidth = 0, v_dist = scale2res(24), hoffs = 0;
	int h_abs = scale2res(18), v_abs = scale2res(36);
	char temp_string[256] = {0};

	get_info_cpu();
	get_uptime();
#if BOXMODEL_VUPLUS_ARM
	mtd_count = 0;
#else
	mtd_count = get_mtd();
#endif

	if (mtd_count)
	{
		while (mtds[1][i] != ' ')
			i++;
		i++;
		while (mtds[1][i] != ' ')
			i++;
		i++;
		while (mtds[1][i] != ' ' && y < BUFFER_SIZE - 1)
		{
			temp_string[y] = mtds[1][i];
			y++;
			i++;
		}
	}
	temp_string[y] = '\0';
	sscanf(temp_string, "%d", &y);

	// longest string
	abs_links = sx + h_abs + GetStringLen("BogoMIPS:", FSIZE_MED) + OFFSET_MED ;
	maxwidth = ex - scale2res(540) - abs_links;

	RenderString("Onlinezeit:", sx + h_abs, (linie_oben + v_abs), maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(uptime, (abs_links + hoffs), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist + OFFSET_SMALL;

	RenderString("Hardware:", sx + h_abs, (linie_oben + v_abs), maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(hardware, abs_links + hoffs, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist;

	RenderString("Revision:", sx + h_abs, (linie_oben + v_abs), maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(hard_rev, abs_links + hoffs, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist;

	RenderString("Processor:", sx + h_abs, (linie_oben + v_abs), maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(processor, abs_links + hoffs, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist;

	int count = atoi(cores);
	if (count > 0)
	{
		count++;
		snprintf(cores, sizeof(cores), "%d", count);
		RenderString("Cores:", sx + h_abs, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED, CMHT);
		RenderString(cores, abs_links + hoffs, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
		v_abs += v_dist;
	}

	RenderString("BogoMIPS:", sx + h_abs, (linie_oben + v_abs), maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(bogomips, (abs_links + hoffs), (linie_oben + v_abs), maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist + OFFSET_SMALL;

	char* parts[256] = {0};
	int start = 0, end = 0, currentWidth = 0, partCount = 0;
	int textLength = strlen(features);

	while (end < textLength) {
		int width = RenderChar(features[end], -1, -1, -1, -1);

		if (currentWidth + width > maxwidth) {
			int lastSpace = end - 1;
			int cutPoint = end; // Der Punkt, an dem abgeschnitten wird (Standard: nächstes Zeichen)

			if (lastSpace >= start) {
				// Nach einem Leerzeichen vor `maxwidth` suchen
				while (lastSpace >= start && features[lastSpace] != ' ') {
					lastSpace--;
				}

				if (lastSpace >= start) {
					cutPoint = lastSpace + 1; // Nach dem Leerzeichen abschneiden
				}
			}

			int partLength = cutPoint - start;
			char* part = malloc((partLength + 1) * sizeof(char));
			strncpy(part, features + start, partLength);
			part[partLength] = '\0';

			parts[partCount++] = part;

			start = cutPoint;
			currentWidth = 0;
		} else {
			currentWidth += width;
			end++;
		}
	}

	int lastPartLength = end - start;
	if (lastPartLength > 0) {
		char lastPart[lastPartLength + 1];
		strncpy(lastPart, features + start, lastPartLength);
		lastPart[lastPartLength] = '\0';
		parts[partCount++] = strdup(lastPart);
	}

	RenderString("Features:", sx + h_abs, (linie_oben + v_abs), maxwidth, LEFT, FSIZE_MED, CMHT);
	for (i = 0; i < partCount; i++) {
		RenderString(parts[i], (abs_links + hoffs), (linie_oben + v_abs), maxwidth, LEFT, FSIZE_SMALL, CMCT);
		if (i < partCount-1) {
			v_abs += v_dist - OFFSET_MIN;
		}
		free(parts[i]);
	}
	v_abs += v_dist + OFFSET_SMALL;
	v_abs += v_dist - ((partCount > 2 ? 6 : 3) * OFFSET_MIN);

	RenderString("Flash Struktur:", sx + h_abs, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 3, CMHT);
	if (!mtd_count)
	{
		v_abs += (v_dist - 2 * OFFSET_MIN);
		int num_devices;
		char *tmp_str = NULL;
		mmcblk_info_t* mmcblk_info = get_mmcblk_info(&num_devices);

		if (mmcblk_info == NULL) {
			printf("Keine mmcblk Geräte gefunden.\n");
		} else {
			// sortiere das Array nach device
			qsort(mmcblk_info, num_devices, sizeof(mmcblk_info_t), compare_mmcblk_info);
			char short_name[32] = {0};
			for (i = 0; i < num_devices; i++)
			{
				get_substring(mmcblk_info[i].mountpoint, short_name, '/');
				// get longest string, should be longer as rootfs and boot
				slen = GetStringLen(short_name, FSIZE_SMALL);
				if (slen > longest_length) {
					longest_length = slen;
				}
			}
			RenderString("Filesystem", sx + h_abs, (linie_oben + v_abs), maxwidth, LEFT, FSIZE_VSMALL, CMCIT);
			RenderString("Total", sx + h_abs + longest_length + 2*OFFSET_MED, (linie_oben + v_abs), maxwidth, LEFT, FSIZE_VSMALL, CMCIT);
			RenderString("Free", sx + h_abs + longest_length + 2*OFFSET_MED + scale2res(110), (linie_oben + v_abs), maxwidth, LEFT, FSIZE_VSMALL, CMCIT);
			RenderString("Used", sx + h_abs + longest_length + 2*OFFSET_MED + scale2res(230), (linie_oben + v_abs), maxwidth, LEFT, FSIZE_VSMALL, CMCIT);

			for (i = 0; i < num_devices; i++) {
				get_substring(mmcblk_info[i].mountpoint, short_name, '/');
#if 0
				printf("Device: %s\n", mmcblk_info[i].device);
				printf("Mountpoint: %s\n", mmcblk_info[i].mountpoint);
				printf("Mountpoint short: %s\n", short_name);
				if (mmcblk_info[i].total_size > 1000)
					printf("Speicherkapazität: %.2f GB\n", mmcblk_info[i].total_size / 1000);
				else
					printf("Speicherkapazität: %.2f MB\n", mmcblk_info[i].total_size);
				printf("Freier Speicher: %0.2f MB\n", mmcblk_info[i].free_size);
				printf("Belegter Speicher: %d%%\n", (int) floor(mmcblk_info[i].usage_percent + 0.5));
				printf("\n");
#endif
				if (strcmp(mmcblk_info[i].mountpoint, "/") == 0)
					tmp_str = "rootfs";
				else if (strcmp(mmcblk_info[i].mountpoint, "/boot") == 0)
					tmp_str = "boot";
				else {
					tmp_str = short_name;

				}
				v_abs += (v_dist - 2 * OFFSET_MIN); // Filesystem
				snprintf(temp_string, sizeof(temp_string), "%s", tmp_str);
				RenderString(temp_string, sx + h_abs, linie_oben + v_abs, maxwidth, LEFT, FSIZE_SMALL, CMCT);

				if (mmcblk_info[i].total_size > 1000) // Total
					snprintf(temp_string, sizeof(temp_string), "%0.2f %s", mmcblk_info[i].total_size / 1000, "GB");
				else
					snprintf(temp_string, sizeof(temp_string), "%0.2f %s", mmcblk_info[i].total_size, "MB");
				RenderString(temp_string, sx + h_abs + longest_length + 2*OFFSET_MED, linie_oben + v_abs, maxwidth, LEFT, FSIZE_SMALL, CMCT);

				if (mmcblk_info[i].total_size > 1000) // free
					snprintf(temp_string, sizeof(temp_string), "%0.2f %s", mmcblk_info[i].free_size / 1000, "GB");
				else
					snprintf(temp_string, sizeof(temp_string), "%0.2f %s", mmcblk_info[i].free_size, "MB");
				RenderString(temp_string, sx + h_abs + longest_length + 2*OFFSET_MED + scale2res(110), linie_oben + v_abs, maxwidth, LEFT, FSIZE_SMALL, CMCT);

				snprintf(temp_string, sizeof(temp_string), "%d%%", (int) floor(mmcblk_info[i].usage_percent + 0.5));
#if 1	//looks better :)
				draw_progressbar(sx + h_abs + longest_length + 2*OFFSET_MED + scale2res(230), linie_oben + v_abs - 2*OFFSET_MED, sx + h_abs + longest_length + 2*OFFSET_MED + scale2res(310),
#else
				draw_progressbar(sx + h_abs + longest_length + 2*OFFSET_MED + scale2res(230), linie_oben + v_abs - 2*OFFSET_MED, sx + h_abs + longest_length + 2*OFFSET_MED + scale2res(340),
#endif
					(linie_oben + v_abs - 2*OFFSET_MED + scale2res(16)), PB_LEFT_GREEN70, (int) floor(mmcblk_info[i].usage_percent + 0.5));
				// used
#if 1	//looks better :)
				RenderString(temp_string, sx + h_abs + longest_length + 2*OFFSET_MED + scale2res(320), (linie_oben + v_abs - OFFSET_MIN), maxwidth, LEFT, FSIZE_VSMALL, CMCT);
#else
				RenderString(temp_string, sx + h_abs + longest_length + 2*OFFSET_MED + scale2res(350), (linie_oben + v_abs - OFFSET_MIN), maxwidth, LEFT, FSIZE_VSMALL, CMCT);
#endif
			}
		}
		// Freigabe des mmcblk_info Speichers
		free(mmcblk_info);
	}
	else {
		// CST with MTD Devices
		//-------------------------
		MTDDeviceInfo devices[MAX_MTD_DEVICES] = {{ .total_size = 0 }};
		int num_mtd_devices = get_mtd_device_infos(devices);
#if 0
		printf("Found %d MTD devices:\n", num_mtd_devices);
		for (i = 0; i < num_mtd_devices; i++) {
			printf("MTD Device %d:\n", i);
			printf("  Name: %s\n", devices[i].name);
			printf("  Total size: %zu bytes (%s)\n", devices[i].total_size, devices[i].total_size_str);
			printf("  Used size: %zu bytes (%s)\n", devices[i].used_size, devices[i].used_size_str);
			printf("  Used space: %.2f%%\n", devices[i].used_percentage);
		}
#endif
		int v_abs_progress = v_abs;
		for (i = 0; i < mtd_count; i++)
		{
			v_abs += (v_dist - 2 * OFFSET_MIN);
			// get longest string len
			slen = GetStringLen(mtds[i], FSIZE_SMALL);
			if (slen > longest_length) {
				longest_length = slen;
			}
			RenderString((mtds[i]), sx + h_abs, linie_oben + v_abs, maxwidth, LEFT, FSIZE_SMALL, CMCT);
		}
		for (i = 0; i < num_mtd_devices; i++) {
			v_abs_progress += (v_dist - 2 * OFFSET_MIN);
			snprintf(temp_string, sizeof(temp_string), "%s / %s", devices[i].used_size_str, devices[i].total_size_str);

#if HAVE_SH4_HARDWARE // FIXME, SH4 braucht Vollbild, da laengere Texte
			RenderString(temp_string, sx + longest_length + OFFSET_SMALL, linie_oben + v_abs_progress-OFFSET_MIN, scale2res(125), RIGHT, FSIZE_VSMALL, CMCT);
			draw_progressbar(sx  + longest_length + scale2res(140), linie_oben + v_abs_progress - 2*OFFSET_MED+1, sx + longest_length + scale2res(165),
#else
			RenderString(temp_string, sx + longest_length + OFFSET_SMALL, linie_oben + v_abs_progress-OFFSET_MIN, scale2res(150), RIGHT, FSIZE_VSMALL, CMCT);
			draw_progressbar(sx  + longest_length + scale2res(165), linie_oben + v_abs_progress - 2*OFFSET_MED+1, sx + longest_length + scale2res(245),
#endif
				linie_oben + v_abs_progress - 2*OFFSET_MED+1 + scale2res(14), PB_LEFT_GREEN70, (int)devices[i].used_percentage);

			snprintf(temp_string, sizeof(temp_string), "%d %c", (int)devices[i].used_percentage, 37);
#if HAVE_SH4_HARDWARE // FIXME, SH4 braucht Vollbild, da laengere Texte
			RenderString(temp_string, sx + longest_length + scale2res(160) , linie_oben + v_abs_progress-OFFSET_MIN, scale2res(40), RIGHT, FSIZE_VSMALL, CMCT);
#else
			RenderString(temp_string, sx + longest_length + scale2res(245) , linie_oben + v_abs_progress-OFFSET_MIN, scale2res(40), RIGHT, FSIZE_VSMALL, CMCT);
#endif
		}
	}

	RenderString(kernel, sx + h_abs, linie_unten - 2 * OFFSET_MIN, ex - sx, LEFT, FSIZE_VSMALL, CMCT);

	int iw, ih;
	int icon_w = 0, icon_h = 0;
	png_getsize(ICON_BUTTON_RED, &icon_w, &icon_h);

	paintIcon(ICON_BUTTON_RED, sx + scale2res(16 + (icon_w / 2)), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
	RenderString("FILE-SYSTEM", sx + scale2res(50), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);

	paintIcon(ICON_BUTTON_GREEN, sx + scale2res(15 + (icon_w / 2)) + (int)((ex - sx - 3 * OFFSET_MED) / 4), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
	RenderString("PROZESSE", sx + scale2res(50) + (int)((ex - sx - 3 * OFFSET_MED) / 4), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);

	paintIcon(ICON_BUTTON_YELLOW, sx + (icon_w / 2) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 2), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
	RenderString("KERNEL MESSAGE", sx + scale2res(33) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 2), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);

	paintIcon(ICON_BUTTON_BLUE, sx + scale2res(15 + (icon_w / 2)) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 3), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
	RenderString("NETZWERK", sx + scale2res(50) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 3), ey - 2 * OFFSET_SMALL, maxwidth, LEFT, FSIZE_SMALL, CMCT);
}

void up_main_mem(void)
{
	char temp_string[200] = "";
	char type[32]= "";
	int i, LO = 0, maxwidth = scale2res(200);
	LO = linie_oben + OFFSET_MIN;

	RenderBox(ex - scale2res(535), LO + scale2res(3), ex - scale2res(10), LO + scale2res(30), FILL, CMH, 0);	// CMH
	RenderBox(ex - scale2res(535), LO + scale2res(140), ex - scale2res(10), LO + scale2res(210), FILL, CMH, 0); // CMH
	RenderBox(ex - scale2res(535), LO + scale2res(318), ex - scale2res(10), linie_unten - 3*OFFSET_MED, FILL, CMH, 0); // CMH
	// Clear rechts für String Vollb.
	RenderBox(ex - scale2res(60), LO + scale2res(30), ex - scale2res(10), LO + scale2res(325), FILL, CMH, 0); // CMH

	if (x_pos == ex - scale2res(527))
		get_mem();

	if (x_pos == ex - scale2res(527))
		get_perf();

	old_user_perf = user_perf;
	old_nice_perf = nice_perf;
	old_sys_perf = sys_perf;
	old_idle_perf = idle_perf;

	old_memtotal = memtotal;
	old_memfree = memfree;
	old_memused = memused;
	old_memactive = memactive;
	old_meminakt = meminakt;

	if (x_pos != ex - scale2res(527))
		get_mem();

	if (x_pos != ex - scale2res(527))
		get_perf();

	int slen = GetStringLen("Speicher total:", FSIZE_MED);
	RenderString("Speicher total:", ex - scale2res(530), (LO + 3 * OFFSET_MED), maxwidth + OFFSET_MED, LEFT, FSIZE_MED, CMHT);
	snprintf(temp_string, sizeof(temp_string), " %2.1f MB", memtotal);
	RenderString(temp_string, ex - scale2res(530) + slen + OFFSET_SMALL, LO + scale2res(30), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	if (x_pos == ex - scale2res(527))
	{
		RenderBox(ex - scale2res(530), LO + scale2res(32), ex - scale2res(60), LO + scale2res(138), FILL, CMCST, 0); // CMCST
		RenderBox(ex - scale2res(530), LO + scale2res(32), ex - scale2res(60), LO + scale2res(138), GRID, CMCIT, 0); // CMCIT
	}
	snprintf(temp_string, sizeof(temp_string),"free: %2.1f MB", memfree);
	RenderString(temp_string, ex - scale2res(530), LO + scale2res(165), maxwidth, LEFT, FSIZE_SMALL, GREEN);
	snprintf(temp_string, sizeof(temp_string),"used: %2.1f MB", memused);
	RenderString(temp_string, ex - scale2res(370), LO + scale2res(165), maxwidth, LEFT, FSIZE_SMALL, BLUE0); // BLUE3
	snprintf(temp_string, sizeof(temp_string),"active: %2.1f MB", memactive);
	RenderString(temp_string, ex - scale2res(530), LO + scale2res(183), maxwidth, LEFT, FSIZE_SMALL, YELLOW);
	snprintf(temp_string, sizeof(temp_string),"inactive: %2.1f MB", meminakt);
	RenderString(temp_string, ex - scale2res(370), LO + scale2res(183), maxwidth, LEFT, FSIZE_SMALL, LRED); // LRED

	int factor = scale2res(100);
	RenderLine(x_pos - 0, (int)LO + scale2res(137) - (old_memtotal * (factor / memtotal)), x_pos + 2, (int)LO + scale2res(137) - (memtotal * (factor / memtotal)), 2, CMCT);
	RenderLine(x_pos - 0, (int)LO + scale2res(135) - (old_meminakt * (factor / memtotal)), x_pos + 2, (int)LO + scale2res(135) - (meminakt * (factor / memtotal)), 2, LRED); // LRED
	RenderLine(x_pos - 0, (int)LO + scale2res(135) - (old_memfree * (factor / memtotal)), x_pos + 2, (int)LO + scale2res(135) - (memfree * (factor / memtotal)), 2, GREEN);
	RenderLine(x_pos - 0, (int)LO + scale2res(137) - (old_memused * (factor / memtotal)), x_pos + 2, (int)LO + scale2res(137) - (memused * (factor / memtotal)), 2, BLUE0); // BLUE3
	RenderLine(x_pos - 0, (int)LO + scale2res(135) - (old_memactive * (factor / memtotal)), x_pos + 2, (int)LO + scale2res(135) - (memactive * (factor / memtotal)), 2, YELLOW);

	LO = LO + scale2res(178);
	RenderString("Systemauslastung in %", ex - scale2res(530), LO + scale2res(32), maxwidth + 6*OFFSET_MED, LEFT, FSIZE_MED, CMHT);
	if (x_pos == ex - scale2res(527))
	{
		RenderBox(ex - scale2res(530), LO + scale2res(32), ex - scale2res(60), LO + scale2res(138), FILL, CMCST, 0); // CMCST
		RenderBox(ex - scale2res(530), LO + scale2res(32), ex - scale2res(60), LO + scale2res(138), GRID, CMCIT, 0); // CMCIT
	}

	snprintf(temp_string, sizeof(temp_string),"user: %3.1f", user_perf);
	RenderString(temp_string, ex - scale2res(530), LO + scale2res(165), maxwidth, LEFT, FSIZE_MED - 2, GREEN);
	snprintf(temp_string, sizeof(temp_string),"idle: %3.1f", idle_perf);
	RenderString(temp_string, ex - scale2res(400), LO + scale2res(165), maxwidth, LEFT, FSIZE_MED - 2, BLUE0); // BLUE3
	snprintf(temp_string, sizeof(temp_string),"system: %3.1f", sys_perf);
	RenderString(temp_string, ex - scale2res(530), LO + scale2res(183), maxwidth, LEFT, FSIZE_MED - 2, YELLOW);
	snprintf(temp_string, sizeof(temp_string),"nice: %3.1f", nice_perf);
	RenderString(temp_string, ex - scale2res(400), LO + scale2res(183), maxwidth, LEFT, FSIZE_MED - 2, LRED); // LRED

	RenderLine(x_pos - 0, (int)LO + scale2res(135) - scale2res(old_nice_perf), x_pos + 2, (int)LO + scale2res(135) - scale2res(nice_perf), 2, LRED); // LRED
	RenderLine(x_pos - 0, (int)LO + scale2res(135) - scale2res(old_user_perf), x_pos + 2, (int)LO + scale2res(135) - scale2res(user_perf), 2, GREEN);
	RenderLine(x_pos - 0, (int)LO + scale2res(137) - scale2res(old_idle_perf), x_pos + 2, (int)LO + scale2res(137) - scale2res(idle_perf), 2, BLUE0); // BLUE3
	RenderLine(x_pos - 0, (int)LO + scale2res(135) - scale2res(old_sys_perf), x_pos + 2, (int)LO + scale2res(135) - scale2res(sys_perf), 2, YELLOW);

	x_pos = x_pos + OFFSET_SMALL - OFFSET_MIN;
	if (x_pos >= ex - scale2res(62))
		x_pos = ex - scale2res(527);

	RenderString("( 1 )", ex - scale2res(55), linie_oben + scale2res(57), scale2res(55), LEFT, FSIZE_BIG - 2, CMCT);
	RenderString("V", ex - scale2res(40), linie_oben + scale2res(78), scale2res(18), LEFT, FSIZE_SMALL, CMCT);
	RenderString("o", ex - scale2res(40), linie_oben + scale2res(94), scale2res(18), LEFT, FSIZE_SMALL, CMCT);
	RenderString("l", ex - scale2res(39), linie_oben + scale2res(112), scale2res(18), LEFT, FSIZE_SMALL, CMCT);
	RenderString("l", ex - scale2res(39), linie_oben + scale2res(130), scale2res(18), LEFT, FSIZE_SMALL, CMCT);
	RenderString("b.", ex - scale2res(40), linie_oben + scale2res(152), scale2res(24), LEFT, FSIZE_MED, CMCT);

	LO = linie_oben + scale2res(178);
	RenderString("( 2 )", ex - scale2res(55), LO + scale2res(57), scale2res(55), LEFT, FSIZE_BIG - 2, CMCT);
	RenderString("V", ex - scale2res(40), LO + scale2res(78), scale2res(18), LEFT, FSIZE_SMALL, CMCT);
	RenderString("o", ex - scale2res(40), LO + scale2res(94), scale2res(18), LEFT, FSIZE_SMALL, CMCT);
	RenderString("l", ex - scale2res(39), LO + scale2res(112), scale2res(18), LEFT, FSIZE_SMALL, CMCT);
	RenderString("l", ex - scale2res(39), LO + scale2res(130), scale2res(18), LEFT, FSIZE_SMALL, CMCT);
	RenderString("b.", ex - scale2res(40), LO + scale2res(152), scale2res(25), LEFT, FSIZE_MED, CMCT);

	unsigned int sig = 0, snr = 0;
	struct frontend_info frontend_array[MAX_NUM_FRONTENDS];
	int num_frontends = get_frontend_info(frontend_array, MAX_NUM_FRONTENDS);
	if (num_frontends < 0) {
		fprintf(stderr, "Error getting frontend info: %s\n", strerror(errno));
	}
	else {
		for (i = 0; i < num_frontends; i++)
		{
			switch (frontend_array[i].type) {
				case FE_QPSK:
					snprintf(type, sizeof(type), "DVB-S");
					break;
				case FE_QAM:
					snprintf(type, sizeof(type), "DVB-C");
					break;
				case FE_OFDM:
					snprintf(type, sizeof(type), "DVB-T/T2");
					break;
				default:
					snprintf(type, sizeof(type), "Unknown");
					break;
			}
			sig = frontend_array[i].signal_strength & 0xFFFF;
			sig = (sig & 0xFFFF) * 100 / 65535;
			snr = frontend_array[i].snr;
			snr = (snr & 0xFFFF) * 100 / 65535;
		}
	}

	char chip_name[2][MAX_NAME_LEN] = {};
	if (read_nim_socket(chip_name, 2) < 0)
		safe_strncpy(chip_name[0], "", MAX_NAME_LEN);

	snprintf(temp_string, sizeof(temp_string),"Tuner A: %s %s  Mode: %s", frontend_array[0].name, chip_name[0], type);
	RenderString(temp_string, ex - scale2res(530), LO + scale2res(225),scale2res(510), LEFT, FSIZE_SMALL, CMCT);

	snprintf(temp_string, sizeof(temp_string),"SIG %d%c", sig, 37);
	RenderString(temp_string, ex - scale2res(170), LO + scale2res(250), maxwidth, LEFT, FSIZE_VSMALL, CMCT);
	draw_progressbar(ex - scale2res(530), LO + scale2res(230), ex - scale2res(180), LO + scale2res(248), PB_LEFT_RED30, sig);
	snprintf(temp_string, sizeof(temp_string),"SNR %d%c", snr, 37);
	RenderString(temp_string, ex - scale2res(170), LO + scale2res(278), maxwidth, LEFT, FSIZE_VSMALL, CMCT);
	draw_progressbar(ex - scale2res(530), LO + scale2res(258), ex - scale2res(180), LO + scale2res(276), PB_LEFT_RED30, snr);
}

void get_net_traf(void)
{
	FILE *file = NULL;
	char *ptr;
	char line_buffer[256] = "";
	if ((file = fopen("/proc/net/dev", "r")) == NULL)
	{
		printf("Open /proc/net/dev failure\n");
		return;
	}

	while (fgets(line_buffer, sizeof(line_buffer), file))
	{
		if ((ptr = strstr(line_buffer, IFNAME)) != NULL)
		{
#if defined NET_DEBUG2
			printf("Procline=%s\n", line_buffer);
			fflush(stdout);
#endif
			sscanf(ptr + strlen(IFNAME) + 1, "%lld%ld%ld%ld%ld%ld%ld%ld%lld%ld", &read_akt, &read_packet, &dummy, &dummy, &dummy, &dummy, &dummy, &dummy, &write_akt, &write_packet);
#if defined NET_DEBUG2
			printf("Read=%lld\n", read_akt);
			printf("Write=%lld\n", write_akt);
			fflush(stdout);
			printf("Read_packet=%ld\n", read_packet);
			printf("Write_pcket=%ld\n", write_packet);
			fflush(stdout);
#endif
		}
	}
	fclose(file);
}

int get_network_info(const char *interface, int *speed, char *duplex_mode) {
	int fd;
	struct ifreq ifr;
	struct ethtool_cmd edata;

	if ((fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
		perror("socket");
		return -1;
	}

	memset(&ifr, 0, sizeof(ifr));
	strlcpy(ifr.ifr_name, interface, IFNAMSIZ);

	edata.cmd = ETHTOOL_GSET;
	ifr.ifr_data = (caddr_t)&edata;

	if (ioctl(fd, SIOCETHTOOL, &ifr) == -1) {
		perror("ioctl");
		close(fd);
		strlcpy(duplex_mode, "Unknown", 20);
		return -1;
	}

	*speed = ethtool_cmd_speed(&edata);

	if (edata.duplex == DUPLEX_FULL) {
		strlcpy(duplex_mode, "Full", 20);
	} else if (edata.duplex == DUPLEX_HALF) {
		strlcpy(duplex_mode, "Half", 20);
	} else {
		strlcpy(duplex_mode, "Unknown", 20);
	}

	close(fd);
	return 0;
}

void up_net(void)
{
	char temp_string[200] = "";
	int maxwidth = scale2res(220);
	int LO = linie_oben + 2;
	int condition = 2, i, unit;
	double dtemp;
	int speed = 0;
	char duplex_mode[20] = "";
	static int of_read = 0, of_write = 0;

	if (get_network_info(IFNAME, &speed, duplex_mode) == -1) {
		fprintf(stderr, "Error getting network speed and duplex mode\n");
	}
	//printf("Network Card Speed: %d Mb/s\n", speed);
	//printf("Network Card Duplex Mode: %s\n", duplex_mode);

	RenderBox(ex - scale2res(535), LO + scale2res(3), ex - OFFSET_MED, LO + scale2res(30), FILL, CMH, 0);		// CMH
	RenderBox(ex - scale2res(535), LO + scale2res(140), ex - OFFSET_MED, LO + scale2res(240), FILL, CMH, 0);	// CMH

	int slen = GetStringLen("Netzauslastung:", FSIZE_MED);
	if (slen > scale2res(145))
	{
		condition = 1;
	}

	RenderString("Netzauslastung:", ex - scale2res(530), LO + 3*OFFSET_MED, maxwidth, LEFT, FSIZE_MED, CMHT);
	snprintf(temp_string, sizeof(temp_string), "Speed: %d Mb/s   Duplex: %s", speed, duplex_mode);
	RenderString(temp_string, ex - scale2res(530) + slen + OFFSET_MED, LO + 3*OFFSET_MED, scale2res(300), LEFT, FSIZE_SMALL, CMCT);

	if (x_pos == ex - scale2res(527))
	{
		RenderBox(ex - scale2res(530), LO + scale2res(32), ex - scale2res(60), LO + scale2res(138), FILL, CMCST, 0);	// CMCST
		RenderBox(ex - scale2res(530), LO + scale2res(32), ex - scale2res(60), LO + scale2res(138), GRID, CMCIT, 0);	// CMCIT
	}
	if (if_active == -1) {
		RenderString("No active interface", ex - scale2res(380), LO + scale2res(80), maxwidth, LEFT, FSIZE_SMALL - 2, CMHT);
		return;
	}

	get_net_traf();
	read_old = read_akt + of_read * 0x100000000ULL;
	write_old = write_akt + of_write * 0x100000000ULL;
	usleep(750000);
	get_net_traf();
	read_akt += of_read * 0x100000000ULL;
	write_akt += of_write * 0x100000000ULL;
	if(read_akt < read_old)
	{
		++of_read;
		read_akt += 0x100000000ULL;
	}
	if(write_akt < write_old)
	{
		++of_write;
		write_akt += 0x100000000ULL;
	}

	delta_read = ((read_akt - read_old) << 2) / 3;
	delta_write = ((write_akt - write_old) << 2) / 3;

	//printf("diff read = %lld\t diff write = %lld\n", delta_read, delta_write);

	// Berechnen des neuen Durchschnitts
	data_delta_read[count_index] = delta_read;
	average_delta_read = 0;
	for(i = 0; i < DATA_SIZE; i++)
	{
		average_delta_read += data_delta_read[i];
	}
	average_delta_read /= DATA_SIZE;

	data_delta_write[count_index] = delta_write;
	average_delta_write = 0;
	for(i = 0; i < DATA_SIZE; i++)
	{
		average_delta_write += data_delta_write[i];
	}
	average_delta_write /= DATA_SIZE;

	dtemp = bytes_to_ibytes(read_akt, &unit);
	RenderString("Receive:", ex - scale2res(530), LO + scale2res(165), maxwidth, LEFT, FSIZE_SMALL, LRED); // LRED
	snprintf(temp_string, sizeof(temp_string), "Packets: %ld", read_packet);
	RenderString(temp_string, ex - scale2res(500), LO + scale2res(185), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string), "Bytes:");
	RenderString(temp_string, ex - scale2res(345), LO + scale2res(185), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string), "%.*lf", condition, dtemp);
	RenderString(temp_string, ex - scale2res(465), LO + scale2res(185), maxwidth, RIGHT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string), "%cB", unit);
	RenderString(temp_string, ex - scale2res(240), LO + scale2res(185), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	dtemp = bytes_to_ibytes(average_delta_read * 8, &unit);
	snprintf(temp_string, sizeof(temp_string), "Speed:");
	RenderString(temp_string, ex - scale2res(190), LO + scale2res(185), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string), "%.*lf", condition, dtemp);
	RenderString(temp_string, ex - scale2res(305), LO + scale2res(185), maxwidth, RIGHT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string),"%cb/s", unit);
	RenderString(temp_string, ex - scale2res(80), LO + scale2res(185), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);

	dtemp = bytes_to_ibytes(write_akt, &unit);
	RenderString("Transmit:", ex - scale2res(530), LO + scale2res(205), maxwidth, LEFT, FSIZE_SMALL, GREEN);
	snprintf(temp_string, sizeof(temp_string),"Packets: %ld", write_packet);
	RenderString(temp_string, ex - scale2res(500), LO + scale2res(225), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string),"Bytes:");
	RenderString(temp_string, ex - scale2res(345), LO + scale2res(225), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string), "%.*lf", condition, dtemp);
	RenderString(temp_string, ex - scale2res(465), LO + scale2res(225), maxwidth, RIGHT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string),"%cB", unit);
	RenderString(temp_string, ex - scale2res(240), LO + scale2res(225), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	dtemp = bytes_to_ibytes(average_delta_write * 8, &unit);
	snprintf(temp_string, sizeof(temp_string),"Speed:");
	RenderString(temp_string, ex - scale2res(190), LO + scale2res(225), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string), "%.*lf", condition, dtemp);
	RenderString(temp_string, ex - scale2res(305), LO + scale2res(225), maxwidth, RIGHT, FSIZE_SMALL - 2, CMCT);
	snprintf(temp_string, sizeof(temp_string),"%cb/s", unit);
	RenderString(temp_string, ex - scale2res(80), LO + scale2res(225), maxwidth, LEFT, FSIZE_SMALL - 2, CMCT);
	#undef FLOAT_FORMAT

	// Inkrementieren des Index für das Hinzufügen neuer Werte
	count_index = (count_index + 1) % DATA_SIZE;
	if (count_data < DATA_SIZE)
		count_data++;
#if 0
	int i;
	for (i=0; i<DATA_SIZE; i++)
		printf("DATA = %f\n", data_delta_read[i]);
	printf("Normal Average = %f        Update index = %d\n", average_delta_read, count_index);
	printf("##########################\n\n");
#endif
	// to Kilobyte(KB)
	delta_read = (average_delta_read * 40) / 1024 / 1024;
	delta_write = (average_delta_write * 40) / 1024 / 1024;

	if (delta_read >= (unsigned int)scale2res(100))
		delta_read = scale2res(100);
	if (delta_write >= (unsigned int)scale2res(100))
		delta_write = scale2res(100);

	if (count_data > 6) {
		RenderLine(x_pos - 1, LO + scale2res(135) - delta_read_old, x_pos + 1, (int)LO + scale2res(135) - delta_read, 2, LRED); // LRED
		RenderLine(x_pos - 1, LO + scale2res(135) - delta_write_old, x_pos + 1, (int)LO + scale2res(135) - delta_write, 2, GREEN);
		x_pos = x_pos + scale2res(3);
		if (x_pos >= ex - scale2res(62))
			x_pos = ex - scale2res(527);
	}

	delta_read_old = delta_read;
	delta_write_old = delta_write;
}

void render_koord(char ver)
{
	int i = 0;
	char temptext[20] = "";
	win_sx = sx + scale2res(66);
	win_sy = linie_oben + scale2res(20);
	win_ex = ex - scale2res(24);
	win_ey = linie_unten - scale2res(45);
	fflush(stdout);
	RenderBox(sx + OFFSET_MED, linie_oben + OFFSET_MED, ex - OFFSET_MED, linie_unten - OFFSET_MED, FILL, CMCST, 0);

	RenderVLine(win_sx + 1, win_sy, win_ey, 0, 3, 1, CMCT); // CMCT
	RenderHLine(win_sx, win_ey, win_ex, 0, 3, 1, CMCT);		// CMCT

	RenderLine(win_sx - 2 * OFFSET_MIN, win_sy + scale2res(13), win_sx, win_sy, scale2res(2), CMCT);
	RenderLine(win_sx + 2 * OFFSET_MIN, win_sy + scale2res(13), win_sx, win_sy, scale2res(2), CMCT);
	RenderLine(win_ex - scale2res(10), win_ey - OFFSET_SMALL - 1, win_ex, win_ey, scale2res(2), CMCT);
	RenderLine(win_ex - scale2res(10), win_ey + OFFSET_SMALL, win_ex, win_ey, scale2res(2), CMCT);

	for (i = win_sx + scale2res(50); i < win_ex; i = i + scale2res(50))
	{
		RenderVLine(i, win_sy + 2 * OFFSET_MED, win_ey, 1, OFFSET_MIN, scale2res(6), BLUE0); // CMCS
	}
	if (ver == 1)
	{
		get_mem();
		int mem = (int)(memtotal / 8);
		for (i = 1; i <= 8; i++)
		{
			RenderHLine(win_sx + OFFSET_MED, win_ey - 2 * OFFSET_MIN - i * scale2res(50), win_ex - 2 * OFFSET_MED, 1, 2, scale2res(6), BLUE0); // CMCS  H-LINE
			RenderHLine(win_sx - OFFSET_MED, win_ey - 2 * OFFSET_MIN - i * scale2res(50), win_sx, 0, 2, 1, CMCT);
			snprintf(temptext, sizeof(temptext),"%d MB", i * mem);
			RenderString(temptext, win_sx - 6 * OFFSET_MED + OFFSET_MIN, win_ey - (i * 5 * OFFSET_MED) + 2, scale2res(45), RIGHT, FSIZE_VSMALL-scale2res(3), CMCT);
		}
	}
	if (ver == 2)
	{
		for (i = 1; i <= 10; i++)
		{
			RenderHLine(win_sx + OFFSET_MIN, win_ey - scale2res(3) - i*scale2res(40), win_ex - 2*OFFSET_MED, 1, 2, scale2res(7), BLUE0); // CMCS H-Line
			RenderHLine(win_sx - OFFSET_MED, win_ey - scale2res(3) - i*scale2res(40), win_sx, 0, 2, 1, CMCT);
			snprintf(temptext, sizeof(temptext),"%d%c", i*10, 37);
			RenderString(temptext, win_sx - scale2res(64), win_ey - i*scale2res(40) + OFFSET_SMALL, scale2res(52), RIGHT, FSIZE_SMALL-scale2res(3), CMCT);
		}
	}
}

void up_full(char sel)
{
	char temp_string[24] = "";
	int maxwidth = scale2res(200);

	RenderBox(sx + OFFSET_MED, win_ey + OFFSET_MIN, ex - 4*OFFSET_MED, linie_unten - OFFSET_MED, FILL, CMCST, 0); // CMCST
	if (sel == 1)
	{
		if (x_pos == win_sx + 3*OFFSET_MIN)
			get_mem();

		old_memtotal = memtotal;
		old_memfree = memfree;
		old_memused = memused;
		old_memactive = memactive;
		old_meminakt = meminakt;

		if (x_pos != win_sx + OFFSET_SMALL - OFFSET_MIN)
			get_mem();

		int x0 = OFFSET_SMALL - OFFSET_MIN;
		snprintf(temp_string, sizeof(temp_string), "total: %3.1f MB", memtotal);
		RenderString(temp_string, win_sx, linie_unten - scale2res(14), maxwidth, LEFT, FSIZE_MED, CMCT);
		snprintf(temp_string, sizeof(temp_string), "free: %3.1f MB", memfree);
		RenderString(temp_string, win_sx + scale2res(185), linie_unten - scale2res(14), maxwidth, LEFT, FSIZE_MED, GREEN);
		snprintf(temp_string, sizeof(temp_string), "used: %3.1f MB", memused);
		RenderString(temp_string, win_sx + scale2res(365), linie_unten - scale2res(14), maxwidth, LEFT, FSIZE_MED, BLUE0); // BLUE3
		snprintf(temp_string, sizeof(temp_string), "active: %3.1f MB", memactive);
		RenderString(temp_string, win_sx + scale2res(560), linie_unten - scale2res(14), maxwidth, LEFT, FSIZE_MED, YELLOW);
		snprintf(temp_string, sizeof(temp_string), "inactive: %3.1f MB", meminakt);
		RenderString(temp_string, win_sx + scale2res(756), linie_unten - scale2res(14), maxwidth, LEFT, FSIZE_MED, LRED); // LRED
		RenderLine(x_pos - x0, (int)win_ey - scale2res(3) - (scale2res(4) + 0.01) * (old_memtotal * (100 / memtotal)), x_pos + 1, (int)win_ey - scale2res(3) - (scale2res(4) + 0.01) * (memtotal * (100 / memtotal)), 3, CMCT);
		RenderLine(x_pos - x0, (int)win_ey - scale2res(3) - scale2res(4) * (old_memused * (100 / memtotal)), x_pos + 1, (int)win_ey - scale2res(3) - scale2res(4) * (memused * (100 / memtotal)), 3, BLUE0); // BLUE0
		RenderLine(x_pos - x0, (int)win_ey - scale2res(3) - scale2res(4) * (old_memfree * (100 / memtotal)), x_pos + 1, (int)win_ey - scale2res(3) - scale2res(4) * (memfree * (100 / memtotal)), 3, GREEN);
		RenderLine(x_pos - x0, (int)win_ey - scale2res(3) - scale2res(4) * (old_memactive * (100 / memtotal)), x_pos + 1, (int)win_ey - scale2res(3) - scale2res(4) * (memactive * (100 / memtotal)), 3, YELLOW);
		RenderLine(x_pos - x0, (int)win_ey - scale2res(3) - scale2res(4) * (old_meminakt * (100 / memtotal)), x_pos + 1, (int)win_ey - scale2res(3) - scale2res(4) * (meminakt * (100 / memtotal)), 3, LRED); // LRED

		x_pos = x_pos + OFFSET_SMALL - OFFSET_MIN;
		if (x_pos >= win_ex - 2*OFFSET_MED)
		{
			x_pos = win_sx + 3*OFFSET_MIN;
			render_koord(1);
		}
		sleep(1);
	}
	if (sel == 2)
	{
		if (x_pos == win_sx + 3*OFFSET_MIN)
		{
			get_perf();
			old_nice_perf = win_ey - scale2res(3) - scale2res(4)*(nice_perf);
			old_user_perf = win_ey - scale2res(3) - scale2res(4)*(user_perf);
			old_idle_perf = win_ey - scale2res(3) - scale2res(4)*(idle_perf);
			old_sys_perf  = win_ey - scale2res(3) - scale2res(4)*(sys_perf);
		}
		else
		{
			old_user_perf = user_perf;
			old_nice_perf = nice_perf;
			old_sys_perf = sys_perf;
			old_idle_perf = idle_perf;
		}
		if (x_pos != win_sx + 3*OFFSET_MIN)
			get_perf();

		snprintf(temp_string, sizeof(temp_string),"user: %3.1f %c", user_perf, 37);
		RenderString(temp_string, win_sx, linie_unten - scale2res(14), maxwidth, LEFT, FSIZE_MED, GREEN);
		snprintf(temp_string, sizeof(temp_string),"idle: %3.1f %c", idle_perf, 37);
		RenderString(temp_string, win_sx + scale2res(165), linie_unten - scale2res(14), maxwidth, LEFT, FSIZE_MED, BLUE0); // BLUE3
		snprintf(temp_string, sizeof(temp_string),"system: %3.1f %c", sys_perf, 37);
		RenderString(temp_string, win_sx + scale2res(330), linie_unten - scale2res(14), maxwidth, LEFT, FSIZE_MED, YELLOW);
		snprintf(temp_string, sizeof(temp_string),"nice: %3.1f %c", nice_perf, 37);
		RenderString(temp_string, win_sx + scale2res(515), linie_unten - scale2res(14), maxwidth, LEFT, FSIZE_MED, LRED); // LRED

		nice_perf = win_ey - scale2res(3) - scale2res(4)*(nice_perf);
		user_perf = win_ey - scale2res(3) - scale2res(4)*(user_perf);
		idle_perf = win_ey - scale2res(3) - scale2res(4)*(idle_perf);
		sys_perf  = win_ey - scale2res(3) - scale2res(4)*(sys_perf);

		RenderLine(x_pos, (int)old_nice_perf, x_pos + scale2res(3), (int)nice_perf, 3, LRED); // LRED
		RenderLine(x_pos, (int)old_user_perf, x_pos + scale2res(3), (int)user_perf, 3, GREEN);
		RenderLine(x_pos, (int)old_idle_perf, x_pos + scale2res(3), (int)idle_perf, 3, BLUE0); // BLUE3
		RenderLine(x_pos, (int)old_sys_perf, x_pos + scale2res(3), (int)sys_perf, 3, YELLOW);

		x_pos = x_pos + scale2res(3);
		if (x_pos >= win_ex - 2*OFFSET_MED)
		{
			x_pos = win_sx + 3*OFFSET_MIN;
			render_koord(2);
		}
	}
}

void mem_full(void)
{
	int iw = 0, ih = 0;
	int icon_w = 0, icon_h = 0;
	char end_show = 0;
	hintergrund();

	png_getsize(ICON_BUTTON_HOME, &icon_w, &icon_h);
	paintIcon(ICON_BUTTON_HOME, sx + scale2res(34 + (icon_w / 2)) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 3), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
	RenderString("EXIT", sx + scale2res(76) + (((ex - sx - 3 * OFFSET_MED) / 4) * 3), ey - 2 * OFFSET_SMALL, scale2res(300), LEFT, FSIZE_SMALL, CMCT);
	render_koord(1);

	x_pos = win_sx + 3 * OFFSET_MIN;
	while (!end_show)
	{
		rc_Nnull(2);
		rc_null(2);
		switch (ev.code)
		{
		case KEY_OK:
		case KEY_HOME:
		case KEY_EXIT:
			end_show = 1;
			break;
		default:
			end_show = 0;
		}
	}
}

void perf_full(void)
{
	int iw = 0, ih = 0;
	int icon_w = 0, icon_h = 0;
	char end_show = 0;
	hintergrund();

	png_getsize(ICON_BUTTON_HOME, &icon_w, &icon_h);
	paintIcon(ICON_BUTTON_HOME, sx + scale2res(34 + (icon_w / 2)) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 3), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
	RenderString("EXIT", sx + scale2res(76) + (((ex - sx - 3 * OFFSET_MED) / 4) * 3), ey - 2 * OFFSET_SMALL, scale2res(300), LEFT, FSIZE_SMALL, CMCT);
	render_koord(2);
	x_pos = win_sx + 3 * OFFSET_MIN;
	while (!end_show)
	{
		rc_Nnull(3);
		rc_null(3);
		switch (ev.code)
		{
		case KEY_OK:
		case KEY_HOME:
		case KEY_EXIT:
			end_show = 1;
			break;
		default:
			end_show = 0;
		}
	}
}

void get_network(void)
{
	FILE *file = NULL;
	char *ptr = NULL, *eptr = NULL;
	char line_buffer[256] = "";
	char temp_line[256] = "";

	snprintf(temp_line, sizeof(temp_line),"route -n | grep UG > /tmp/.sys_net");
	system(temp_line);
	if ((file = fopen("/tmp/.sys_net", "r")) == NULL)
	{
		printf("%s: cannot open Netfile\n", __plugin__);
		fflush(stdout);
	}
	else
	{
		if (fgets(line_buffer, sizeof(line_buffer), file))
		{
			if ((ptr = strchr(line_buffer, ' ')))
			{
				while (*ptr && (*ptr <= ' '))
					++ptr;
				if ((eptr = strchr(ptr, ' ')))
				{
					*eptr = 0;
					strncpy(GATEWAY_ADRESS, ptr, sizeof(GATEWAY_ADRESS) - 1);
#if defined NET_DEBUG
					printf("GATEWAY_ADRESS=%s\n", GATEWAY_ADRESS);
					fflush(stdout);
#endif
					ptr = eptr + 1;
				}
			}
		}
		fclose(file);
	}
	snprintf(temp_line, sizeof(temp_line),"ifconfig %s > /tmp/.sys_net", IFNAME);
	system(temp_line);
	if ((file = fopen("/tmp/.sys_net", "r")) == NULL)
	{
		printf("%s: cannot open Netfile\n", __plugin__);
		fflush(stdout);
	}
	else
	{
		while (fgets(line_buffer, sizeof(line_buffer), file))
		{
			snprintf(temp_line, sizeof(temp_line),"HWaddr ");
			if ((ptr = strstr(line_buffer, temp_line)) != NULL)
			{
				corr(MAC_ADRESS, ptr + strlen(temp_line), sizeof(MAC_ADRESS));
#if defined NET_DEBUG
				printf("MAC-Adress=%s\n", MAC_ADRESS);
				fflush(stdout);

#endif
			}
			snprintf(temp_line, sizeof(temp_line),"inet addr:");
			if ((ptr = strstr(line_buffer, temp_line)) != NULL)
			{
				corr(IP_ADRESS, ptr + strlen(temp_line), sizeof(IP_ADRESS));
#if defined NET_DEBUG
				printf("IP_ADRESS=%s\n", IP_ADRESS);
				fflush(stdout);
#endif
			}
			snprintf(temp_line, sizeof(temp_line), "Bcast:");
			if ((ptr = strstr(line_buffer, temp_line)) != NULL)
			{
				corr(BC_ADRESS, ptr + strlen(temp_line), sizeof(BC_ADRESS));
#if defined NET_DEBUG
				printf("BC_ADRESS=%s\n", BC_ADRESS);
				fflush(stdout);
#endif
			}
			snprintf(temp_line, sizeof(temp_line), "Mask:");
			if ((ptr = strstr(line_buffer, temp_line)) != NULL)
			{
				corr(MASK_ADRESS, ptr + strlen(temp_line), sizeof(MASK_ADRESS));
#if defined NET_DEBUG
				printf("MASK_ADRESS=%s\n", MASK_ADRESS);
				fflush(stdout);
#endif
			}
			snprintf(temp_line, sizeof(temp_line), "Base address:");
			if ((ptr = strstr(line_buffer, temp_line)) != NULL)
			{
				corr(BASE_ADRESS, ptr + strlen(temp_line), sizeof(BASE_ADRESS));
#if defined NET_DEBUG
				printf("BASE_ADRESS=%s\n", BASE_ADRESS);
				fflush(stdout);
#endif
			}
		}
		fclose(file);
	}
	snprintf(temp_line, sizeof(temp_line), "nameserver ");
	if ((file = fopen(RESOLVEFILE_VAR, "r")) == NULL)
	{
		if ((file = fopen(RESOLVEFILE_ETC, "r")) == NULL)
		{
			printf("%s: cannot open Resolve-File\n", __plugin__);
			fflush(stdout);
		}
		else
		{
			while (fgets(line_buffer, sizeof(line_buffer), file))
			{
				if ((ptr = strstr(line_buffer, temp_line)) != NULL)
				{
					corr(NAMES_ADRESS, ptr + strlen(temp_line), sizeof(NAMES_ADRESS));

#if defined NET_DEBUG
					printf("NAMES_ADRESS ETC=%s\n", NAMES_ADRESS);
					fflush(stdout);
#endif
				}
			}
			fclose(file);
		}
	}
	else
	{
		while (fgets(line_buffer, sizeof(line_buffer), file))
		{
			if ((ptr = strstr(line_buffer, temp_line)) != NULL)
			{
				corr(NAMES_ADRESS, ptr + strlen(temp_line), sizeof(NAMES_ADRESS));
#if defined NET_DEBUG
				printf("NAMES_ADRESS VAR=%s\n", NAMES_ADRESS);
				fflush(stdout);
#endif
			}
		}
		fclose(file);
	}

#if defined NET_DEBUG
	printf("IP_ADRESS=%s\n", IP_ADRESS);
	fflush(stdout);
	printf("MAC-Adress=%s\n", MAC_ADRESS);
	fflush(stdout);
	printf("MASK_ADRESS=%s\n", MASK_ADRESS);
	fflush(stdout);
	printf("BC_ADRESS=%s\n", BC_ADRESS);
	fflush(stdout);
	printf("GATEWAY_ADRESS=%s\n", GATEWAY_ADRESS);
	fflush(stdout);
	printf("NAMES_ADRESS=%s\n", NAMES_ADRESS);
	fflush(stdout);
#endif

	remove("/tmp/.sys_net");
}

void search_clients(void)
{
	char temp_IP[20] = {0};
	int i = 0, j = 3;
	char temp_line[50] = "";

	RenderBox(sx + rahmen + scale2res(300), linie_oben + scale2res(265), ex - rahmen - scale2res(300), linie_unten - rabs - scale2res(160), FILL, BLUE0, 0); // BLUE3
	RenderBox(sx + rahmen + scale2res(305), linie_oben + scale2res(270), ex - rahmen - scale2res(305), linie_unten - rabs - scale2res(165), FILL, CMH, 0);	 // CMH
	RenderString("Suche nach Clients", sx + rahmen + scale2res(400), linie_oben + scale2res(326), scale2res(370), LEFT, scale2res(38), CMHT);

	memcpy(lfb, lbb, var_screeninfo.xres * var_screeninfo.yres * sizeof(uint32_t));

	while ((IP_ADRESS[i] > 32) && (j > 0))
	{
		temp_IP[i] = IP_ADRESS[i];
		if (IP_ADRESS[i] == 46)
			j--;
		i++;
	}
#if defined NET_DEBUG
	printf("temp IP=%s\n", temp_IP);
	fflush(stdout);
#endif
	for (i = 0; i < 255; i++)
	{
		snprintf(temp_line, sizeof(temp_line),"ping -c 1 %s%d > /dev/null & ", temp_IP, i);
		system(temp_line);
		usleep(1000);
#if defined NET_DEBUG
		printf("temp_line=%s\n", temp_line);
		fflush(stdout);
#endif
	}
	sleep(2);
	system("killall ping  > /dev/null &");
}

void show_network(void)
{
	int iw = 0, ih = 0;
	int icon_w = 0, icon_h = 0;
	FILE *file = NULL;
	char *ptr = NULL;
	char line_buffer[256] = "";
	char temp_line[50] = "";
	char temp_IP[20] = {0};
	char temp_MAC[20] = {0};
	int ret = 0;

	hintergrund();

	if ((if_active = get_active_interface(IFNAME)) == -1)
		printf("No active network.\n");
	else
		get_network();

	int abs_links = 0, maxwidth = 0, v_abs = scale2res(37), v_dist = scale2res(24), i = 0, j = 0, old_abs = 0, x_plus = 0, mainloop = 1;
	x_pos = ex - scale2res(527);
	maxwidth = ex - 2 * OFFSET_MED - abs_links;

	png_getsize(ICON_BUTTON_HOME, &icon_w, &icon_h);
	paintIcon(ICON_BUTTON_HOME, sx + scale2res(34 + (icon_w / 2)) + ((int)((ex - sx - 3 * OFFSET_MED) / 4) * 3), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
	RenderString("EXIT", sx + scale2res(76) + (((ex - sx - 3 * OFFSET_MED) / 4) * 3), ey - 2 * OFFSET_SMALL, scale2res(100), LEFT, FSIZE_SMALL, CMCT);
	png_getsize(ICON_BUTTON_RED, &icon_w, &icon_h);
	paintIcon(ICON_BUTTON_RED, sx + scale2res(16 + (icon_w / 2)), linie_unten + 3 * OFFSET_SMALL + OFFSET_MIN - (icon_h / 2), 0, 0, &iw, &ih);
	RenderString("WEITERE CLIENTS SUCHEN...", sx + scale2res(50), ey - 2 * OFFSET_SMALL, scale2res(350), LEFT, FSIZE_SMALL, CMCT);

	// longest string
	int slen = GetStringLen("Nameserver:", FSIZE_MED);
	abs_links = sx + scale2res(40) + slen + OFFSET_MED;
	RenderString("Box IP:", sx + scale2res(40), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(IP_ADRESS, abs_links, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	snprintf(temp_line,  sizeof(temp_line),"ping -c 1 %s > /dev/null", IP_ADRESS);
#if defined NET_DEBUG
	printf("%s\n", temp_line);
	fflush(stdout);
#endif
	ret = system(temp_line);
	if (ret == 0)
	{
		RenderString("ping ok", abs_links + scale2res(200), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, GREEN);
	}
	else
	{
		RenderString("ping false", abs_links + scale2res(200), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, RED);
	}
	v_abs += v_dist;

	RenderString("Gateway:", sx + scale2res(40), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(GATEWAY_ADRESS, abs_links, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	snprintf(temp_line,  sizeof(temp_line),"ping -c 1 %s > /dev/null", GATEWAY_ADRESS);
#if defined NET_DEBUG
	printf("%s\n", temp_line);
	fflush(stdout);
#endif
	ret = system(temp_line);
	if (ret == 0)
	{
		RenderString("ping ok", abs_links + scale2res(200), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, GREEN);
	}
	else
	{
		RenderString("ping false", abs_links + scale2res(200), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, RED);
	}
	v_abs += v_dist;

	RenderString("Nameserver:", sx + scale2res(40), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(NAMES_ADRESS, abs_links, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	snprintf(temp_line,  sizeof(temp_line),"ping -c 1 %s > /dev/null", NAMES_ADRESS);
#if defined NET_DEBUG
	printf("%s\n", temp_line);
	fflush(stdout);
#endif
	ret = system(temp_line);
	if (ret == 0)
	{
		RenderString("ping ok", abs_links + scale2res(200), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, GREEN);
	}
	else
	{
		RenderString("ping false", abs_links + scale2res(200), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, RED);
	}
	v_abs += v_dist;

	RenderString("Internet:", sx + scale2res(40), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString("www.google.de", abs_links, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	snprintf(temp_line,  sizeof(temp_line),"ping -c 1 google.de > /dev/null");
#if defined NET_DEBUG
	printf("%s\n", temp_line);
	fflush(stdout);
#endif
	ret = system(temp_line);
	if (ret == 0)
	{
		RenderString("ping ok", abs_links + scale2res(200), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, GREEN);
	}
	else
	{
		RenderString("ping false", abs_links + scale2res(200), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, RED);
	}
	v_abs += v_dist;

	RenderString("Interface:", sx + scale2res(40), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(IFNAME, abs_links, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist;

	RenderString("Box MAC:", (sx + scale2res(40)), (linie_oben + v_abs), maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(MAC_ADRESS, (abs_links), (linie_oben + v_abs), maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist;

	RenderString("Subn. Mask:", sx + scale2res(40), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(MASK_ADRESS, abs_links, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist;

	RenderString("Broadcast:", sx + scale2res(40), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED, CMHT);
	RenderString(BC_ADRESS, abs_links, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist;

	//RenderString("Base Addr:", sx + scale2res(40), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED, CMHT);
	//RenderString(BASE_ADRESS, abs_links, linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMCT);
	v_abs += v_dist + OFFSET_MED;

	RenderString("Bekannte Netzwerk Clients:", sx + scale2res(40), linie_oben + v_abs, maxwidth, LEFT, FSIZE_MED - 2, CMHT);
	old_abs = v_abs;

	// longest string
	slen = GetStringLen("255.255.255.255", FSIZE_SMALL);
	int h_dist = slen + scale2res(55);
	while (mainloop != 0)
	{
		x_plus = 0;
		v_abs += v_dist;
		RenderBox(sx + rahmen + OFFSET_MIN, linie_oben + old_abs + OFFSET_MIN, ex - rahmen - OFFSET_MIN, linie_unten - rabs - OFFSET_MIN, FILL, CMH, 0); // CMH

		ret = 0;
		snprintf(temp_line, sizeof(temp_line), "0x2");
		if ((file = fopen("/proc/net/arp", "r")) != NULL)
		{
			while ((fgets(line_buffer, sizeof(line_buffer), file)) && ret < 24)
			{
				if ((ptr = strstr(line_buffer, temp_line)) != NULL)
				{
#if defined NET_DEBUG
					printf("arp %s\n", line_buffer);
					fflush(stdout);
					printf("ptr %s\n", ptr);
					fflush(stdout);
#endif
					i = 0;
					j = 0;
					while (line_buffer[i] > 32)
					{
						temp_IP[j] = line_buffer[i];
						i++;
						j++;
					}
					temp_IP[j] = 0;
					j = 0;
					i = 0;
					while (ptr[i] > 32)
						i++;
					//					i++;
					while (ptr[i] < 33)
						i++;
					//					i++;
					while (ptr[i] > 32)
					{
						temp_MAC[j] = ptr[i];
						i++;
						j++;
					}
					temp_MAC[j] = 0;
					RenderString(temp_IP, sx + scale2res(40) + x_plus, linie_oben + v_abs, maxwidth, LEFT, FSIZE_SMALL, CMCT);
					RenderString(temp_MAC, sx + h_dist + x_plus, linie_oben + v_abs, maxwidth, LEFT, FSIZE_SMALL, CMCT);
					ret++;
					v_abs += (v_dist);
					if (!(ret % 8))
					{
						v_abs = old_abs + v_dist;
						x_plus = ex - sx;
						x_plus = x_plus / 3;
						x_plus = (ret / 8) * x_plus - 2 * OFFSET_MED;
					}
				}
			}
			fclose(file);
		}
		rc_Nnull(4);
		rc_null(4);
		switch (ev.code)
		{
		case KEY_RED:
			search_clients();
			v_abs = old_abs;
			break;

		case KEY_OK:
		case KEY_HOME:
		case KEY_EXIT:
			mainloop = 0;
			break;

		default:
			v_abs = old_abs;
		}
	}
}

int main(void)
{
	// Initialisieren des Arrays mit Nullen
	memset(data_delta_read,  0, DATA_SIZE * sizeof(float));
	memset(data_delta_write, 0, DATA_SIZE * sizeof(float));

	init_fb();

	/* scale to resolution */
	FSIZE_BIG = scale2res(FSIZE_BIG);
	FSIZE_MED = scale2res(FSIZE_MED);
	FSIZE_SMALL = scale2res(FSIZE_SMALL);
	FSIZE_VSMALL = scale2res(FSIZE_VSMALL);

	OFFSET_MED = scale2res(OFFSET_MED);
	OFFSET_SMALL = scale2res(OFFSET_SMALL);
	OFFSET_MIN = scale2res(OFFSET_MIN);

	InitRC();

	int mainloop = 1;

	/* Set up signal handlers. */
	signal(SIGINT, quit_signal);
	signal(SIGTERM, quit_signal);
	signal(SIGQUIT, quit_signal);
	signal(SIGSEGV, quit_signal);
	signal(SIGFPE, quit_signal);

	put_instance(instance = get_instance() + 1);

	linie_oben = scale2res(54) + sy;
	linie_unten = ey - scale2res(38);
	rahmen = scale2res(8);
	rabs = rahmen / 2;

	while (mainloop)
	{
		x_pos = ex - scale2res(527);
		//printf("go hintergrund\n");
		hintergrund();
		//printf("go hauptseite\n");
		hauptseite();
		//printf("go nach hauptseite\n");
		rc_Nnull(1);
		rc_null(1);

		switch (ev.code)
		{
		case KEY_1:
			mem_full();
			break;

		case KEY_2:
			perf_full();
			break;

		case KEY_RED:
			show_FileS();
			break;

		case KEY_GREEN:
			show_ps_dmseg(1);
			break;

		case KEY_YELLOW:
			show_ps_dmseg(0);
			break;

		case KEY_BLUE:
			show_network();
			break;

		case KEY_HOME:
		case KEY_EXIT:
			mainloop = 0;
			break;
		default:
			break;
		}
	}
	closedown();
	return 0;
}

static void quit_signal(int sig)
{
	closedown();
	char *txt = NULL;
	switch (sig)
	{
	case SIGINT:
		txt = strdup("SIGINT");
		break;
	case SIGTERM:
		txt = strdup("SIGTERM");
		break;
	case SIGQUIT:
		txt = strdup("SIGQUIT");
		break;
	case SIGSEGV:
		txt = strdup("SIGSEGV");
		break;
	case SIGFPE:
		txt = strdup("SIGFPE: Floating point exception");
		break;
	default:
		txt = strdup("UNKNOWN");
		break;
	}

	printf("%s Version %.2f killed, signal %s(%d)\n", __plugin__, SH_VERSION, txt, sig);
	free(txt);
	exit(1);
}

void closedown(void)
{
	FTC_Manager_Done(manager);
	FT_Done_FreeType(library);
	memset(lbb, 0, var_screeninfo.xres * var_screeninfo.yres * sizeof(uint32_t));
	memcpy(lfb, lbb, var_screeninfo.xres * var_screeninfo.yres * sizeof(uint32_t));
	munmap(lfb, fix_screeninfo.smem_len);

	free(lbb);
	close(fb);
	CloseRC();
	remove("/tmp/systmp");
	put_instance(get_instance() - 1);
}
