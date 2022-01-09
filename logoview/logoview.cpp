/*
	logoview - Logoviewer for Coolstream

	Copyright (C) 2011-2016 Michael Liebmann

	License: GPL

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.

	You should have received a copy of the GNU General Public
	License along with this program; if not, write to the
	Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
	Boston, MA  02110-1301, USA.
*/

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>
#include <getopt.h>

// included from neutrino source
#include <lib/libconfigfile/configfile.h>

#include <fb_device.h>
#include "logoview.h"
#include "jpeg.h"

#ifndef CONFIGDIR
#define CONFIGDIR "/var/tuxbox/config"
#endif
#ifndef ICONSDIR
#define ICONSDIR "/usr/share/neutrino/icons"
#endif

#define VERSIONSTR "\n\
      ------------------------------------------------------------\n\
      -- logoview v" LV_VERSION " * (C)2011-2016, M. Liebmann (micha-bbg) --\n\
      ------------------------------------------------------------\n\n"
#define FLAG_FILE "/tmp/.logoview"
#define NEUTRINO_CONF CONFIGDIR "/neutrino.conf"
#define START_LOGO ICONSDIR "/start.jpg"

#define DEFAULT_X_START_SD	60
#define DEFAULT_Y_START_SD	20
#define DEFAULT_X_END_SD	1220
#define DEFAULT_Y_END_SD	560

#define DEFAULT_X_START_HD	40   //5
#define DEFAULT_Y_START_HD	25   //5
#define DEFAULT_X_END_HD	1235 //1275
#define DEFAULT_Y_END_HD	690  //715

CConfigFile config(',', false);

CLogoView* CLogoView::getInstance()
{
	static CLogoView* instance = NULL;
	if(!instance)
		instance = new CLogoView();
	return instance;
}

CLogoView::CLogoView()
{
	fb            = 0;
	screen_StartX = 0;
	screen_StartY = 0;
	screen_EndX   = 0;
	screen_EndY   = 0;
	screen_preset = 0;
	osd_resolution = 0;
	stride        = 0;
	lfb           = 0;
	PicBuf        = 0;
	TmpBuf        = 0;
	ScBuf         = 0;
	doneMode      = CLogoView::EMPTY;
	timeout       = 0;
	clearScreen   = false;
	onlyClearScreen = false;
	background    = false;
	nomem         = "logoview <Out of memory>\n";
	start_logo    = START_LOGO;
}

CLogoView::~CLogoView()
{
	ClearThis();
}

void CLogoView::SetScreenBuf(unsigned char *buf, int r, int g, int b, int t)
{
TIMER_START();
	for(unsigned int z = 0; z < var_screeninfo.yres; z++) {
		unsigned int s1 = 0;
		unsigned int z1 = z * stride;
		for (unsigned int s = 0; s < var_screeninfo.xres; s++) {
			ScBuf[z1 + s1 + 3] = t; // transp
			ScBuf[z1 + s1 + 0] = b; // blue
			ScBuf[z1 + s1 + 1] = g; // green
			ScBuf[z1 + s1 + 2] = r; // red
			s1 += 4;
		}
	}
	memcpy(buf, ScBuf, stride*var_screeninfo.yres);
TIMER_STOP("[logoview] SetScreenBuf   ");
}

void CLogoView::ClearThis(bool ClearDisplay/*=true*/)
{
	unlink(FLAG_FILE);
	if (lfb) {
		if (ClearDisplay)
			SetScreenBuf(lfb, 0x00, 0x00, 0x00, 0x00); // clear screen
		munmap(lfb, fix_screeninfo.smem_len);
	}
	if (PicBuf)
		free(PicBuf);
	if (TmpBuf)
		free(TmpBuf);
	if (ScBuf)
		free(ScBuf);
	if (fb > 0)
		close(fb);

        std::string msg = " with ";
        switch (doneMode) {
          case CLogoView::SIGHANDLER:
                msg += "Sighandler";
                break;
          case CLogoView::TIMEOUT:
                msg += "Timeout";
                break;
          case CLogoView::FLAGFILE:
                msg += "Flagfile";
                break;
          default:
                msg = "";
                break;
        }
	printf("[logoview] done%s...\n", msg.c_str());
}
	
bool CLogoView::ReadConfig()
{
	if (!config.loadConfig(NEUTRINO_CONF)) {
		printf("[logoview] %s not found\n", NEUTRINO_CONF);
		return false;
	}

	screen_preset = config.getInt32("screen_preset", 1);
	osd_resolution = config.getInt32("osd_resolution", 0);
	char buf1[512] = "";
	sprintf(buf1, "screen_StartX_%s_%d", (screen_preset) ? "b" : "a", osd_resolution);
	screen_StartX = config.getInt32(buf1, (screen_preset) ? DEFAULT_X_START_HD : DEFAULT_X_START_SD);
	sprintf(buf1, "screen_StartY_%s_%d", (screen_preset) ? "b" : "a", osd_resolution);
	screen_StartY = config.getInt32(buf1, (screen_preset) ? DEFAULT_Y_START_HD : DEFAULT_Y_START_SD);
	sprintf(buf1, "screen_EndX_%s_%d", (screen_preset) ? "b" : "a", osd_resolution);
	screen_EndX = config.getInt32(buf1, (screen_preset) ? DEFAULT_X_END_HD : DEFAULT_X_END_SD);
	sprintf(buf1, "screen_EndY_%s_%d", (screen_preset) ? "b" : "a", osd_resolution);
	screen_EndY = config.getInt32(buf1, (screen_preset) ? DEFAULT_Y_END_HD : DEFAULT_Y_END_SD);
//	printf("\n##### [%s] screen_StartX: %d, screen_StartY: %d, screen_EndX: %d, screen_EndY: %d\n \n", __FUNCTION__, screen_StartX, screen_StartY, screen_EndX, screen_EndY);

	return true;
}

bool CLogoView::CheckFile(std::string datei)
{
	FILE* f1 = fopen(datei.c_str(), "r");
	if (f1) {
		fclose(f1);
		return true;
	}
	return false;
}

void CLogoView::PrintHelp()
{
	std::string msg = "\
    logoview [LogoName] &\n\
        LogoName   : Path to logofile (jpg only)\n\
                     default = " + start_logo + "\n\
\n\
    logoview <Options>\n\
        Options:\n\
        --------\n\
          -l | --logo         Path to logofile (jpg only)\n\
          -b | --background   Run in background\n\
          -t | --timeout      Timeout in sec. (default 0 = no timeout)\n\
          -c | --clearscreen  Clear screen when timeout (default = no)\n\
          -o | --only-clear   No logo view, clear screen and exit\n\
          -h | --help         This help\n\
\n\
    Example:\n\
      logoview --background -t 3 --logo=/var/share/icons/logo.jpg\n\
";
	msg = VERSIONSTR + msg;
	printf(msg.c_str());
}

static struct option long_options[] = {
	{"help",        0, NULL, 'h'},
	{"clearscreen", 0, NULL, 'c'},
	{"only-clear",  0, NULL, 'o'},
	{"background",  0, NULL, 'b'},
	{"timeout",     1, NULL, 't'},
	{"logo",        1, NULL, 'l'},
	{NULL,          0, NULL, 0}
};

void * CLogoView::int_convertRGB2FB(unsigned char *rgbbuff, unsigned long x, unsigned long y, bool alpha)
{
	unsigned long i;
	unsigned int *fbbuff;
	unsigned long count = x * y;

	fbbuff = (unsigned int *) malloc(count * sizeof(unsigned int));
	if(fbbuff == NULL) {
		printf("convertRGB2FB%s: Error: malloc\n", ((alpha) ? " (Alpha)" : ""));
		return NULL;
	}

	if (alpha) {
		for(i = 0; i < count ; i++)
			fbbuff[i] = ((rgbbuff[i*4+3] << 24) & 0xFF000000) |
				    ((rgbbuff[i*4]   << 16) & 0x00FF0000) |
				    ((rgbbuff[i*4+1] <<  8) & 0x0000FF00) |
				    ((rgbbuff[i*4+2])       & 0x000000FF);
	}
	else {
			for(i = 0; i < count ; i++)
				fbbuff[i] = 0xFF000000 | ((rgbbuff[i*3] << 16) & 0xFF0000) | ((rgbbuff[i*3+1] << 8) & 0xFF00) | (rgbbuff[i*3+2] & 0xFF);
	}
	return (void *) fbbuff;
}

void * CLogoView::convertRGB2FB(unsigned char *rgbbuff, unsigned long x, unsigned long y)
{
	return int_convertRGB2FB(rgbbuff, x, y, false);
}

void * CLogoView::convertRGBA2FB(unsigned char *rgbbuff, unsigned long x, unsigned long y)
{
	return int_convertRGB2FB(rgbbuff, x, y, true);
}

void CLogoView::blitPicture(void *fbbuff, uint32_t width, uint32_t height, uint32_t xoff, uint32_t yoff, uint32_t xp, uint32_t yp)
{
	int xc = std::min(width, var_screeninfo.xres);
	int yc = std::min(height, var_screeninfo.yres);

	uint32_t* data = (uint32_t *) fbbuff;
	uint8_t * d = ((uint8_t *)lfb) + xoff * sizeof(uint32_t) + stride * yoff;
	uint32_t * d2;

	for (int count = 0; count < yc; count++ ) {
		uint32_t *pixpos = &data[(count + yp) * width];
		d2 = (uint32_t *) d;
		for (int count2 = 0; count2 < xc; count2++ ) {
			uint32_t pix = *(pixpos + xp);
			*d2 = pix;
			d2++;
			pixpos++;
		}
		d += stride;
	}
}

int CLogoView::run(int argc, char* argv[])
{
#ifdef LV_DEBUG
	printf(VERSIONSTR);
#endif

	int c, opt;
	if ((argc == 2) && (argv[1][0] != '-') && (CheckFile(argv[1]))) {
		start_logo = argv[1];
	} else {
		while ((opt = getopt_long(argc, argv, "t:h?cobl:", long_options, &c)) >= 0)
		{
			switch (opt) {
				case 't':
					timeout = strtol(optarg, NULL, 0);
					break;
				case 'c':
					clearScreen = true;
					break;
				case 'o':
					onlyClearScreen = true;
					break;
				case 'b':
					background = true;
					break;
				case 'l':
					if (CheckFile(optarg))
						start_logo = optarg;
					break;
				case '?':
				case 'h':
					PrintHelp();
					return (opt == '?') ? -1 : 0;
				default:
					break;
			}
		}
	}

	if (background) {
		switch (fork()) {
			case -1: return -1;
			case 0:  break;
			default: return 0;
		}
	}
#if 1
	fb = -1;
	int count = 0;
	// waiting for framebuffer device
	while (fb == -1) {
		fb = open(FB_DEVICE, O_RDWR);
		if (fb != -1) break;
		if (count >= 80) { // 8 sec
			perror("[logoview] <timeout open framebuffer device>");
			exit(1);
		}
		count++;
		usleep(100000);
	}
	if (count > 0)
		printf("[logoview] <open framebuffer device OK>, waiting: %.1f sec\n", count/10.0);
#else
	fb = open(FB_DEVICE, O_RDWR);
	if(fb == -1) {
		perror("[logoview] <open framebuffer device>");
		exit(1);
	}
#endif
	if(ioctl(fb, FBIOGET_FSCREENINFO, &fix_screeninfo) == -1) {
		perror("[logoview] <FBIOGET_FSCREENINFO>\n");
		ClearThis(false);
		return -1;
	}
	stride = fix_screeninfo.line_length;
	if(ioctl(fb, FBIOGET_VSCREENINFO, &var_screeninfo) == -1) {
		perror("[logoview] <FBIOGET_VSCREENINFO>\n");
		ClearThis(false);
		return -1;
	}
	if(!(lfb = (unsigned char*)mmap(0, fix_screeninfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED, fb, 0))) {
		perror("[logoview] <mapping of Framebuffer>\n");
		ClearThis(false);
		return -1;
	}
	if (!CheckFile(start_logo)) {
		perror("[logoview] <no logo file found>");
		ClearThis(false);
		return -1;
	}
	if (!ReadConfig()) {
		ClearThis(false);
		return -1;
	}

#ifdef LV_DEBUG
	printf("Framebuffer ID: %s\nResolution    : %dx%d\nScreenMode    : %s\n \n", 
		fix_screeninfo.id, var_screeninfo.xres, var_screeninfo.yres, (screen_preset) ? "b" : "a");
#endif

	if ((PicBuf = (unsigned char *)malloc(var_screeninfo.xres * var_screeninfo.yres * 3)) == NULL) {
		perror(nomem.c_str());
		ClearThis(false);
		return -1;
	}
	if ((TmpBuf = (unsigned char *)malloc(stride * var_screeninfo.yres)) == NULL) {
		perror(nomem.c_str());
		ClearThis(false);
		return -1;
	}
	if ((ScBuf = (unsigned char *)malloc(stride * var_screeninfo.yres)) == NULL) {
		perror(nomem.c_str());
		ClearThis(false);
		return -1;
	}

	int x=0, y=0;

	if (onlyClearScreen) {
		ClearThis(true);
		return 0;
	}

TIMER_START();
	if (jpeg_load(start_logo.c_str(), (unsigned char **)&PicBuf, &x, &y) != FH_ERROR_OK)
	{
		perror("[logoview] <error read logo file>");
		ClearThis(false);
		return -1;
	}
TIMER_STOP("[logoview] load pic       ");

	unsigned int xres = (var_screeninfo.xres - (screen_StartX + (var_screeninfo.xres - screen_EndX)));
	unsigned int yres = (var_screeninfo.yres - (screen_StartY + (var_screeninfo.yres - screen_EndY)));

TIMER_START();
	PicBuf = Resize(PicBuf, x, y, xres, yres, false);
TIMER_STOP("[logoview] Resize         ");
#ifdef LV_DEBUG
	printf("[logoview] %s - %dx%d, resize to %dx%d\n", start_logo.c_str(), x, y, xres, yres);
#endif

	SetScreenBuf(TmpBuf, 0, 0, 0, 0xFF); // black screen

TIMER_START();
	uint8_t* tmpB = (uint8_t*)convertRGB2FB(PicBuf, xres, yres);
TIMER_STOP("[logoview] convertRGB2FB  ");
	if (tmpB != NULL) {
TIMER_START();
		blitPicture(tmpB, xres, yres, screen_StartX, screen_StartY, 0, 0);
		free(tmpB);
TIMER_STOP("[logoview] blitPicture    ");
	}

	time_t startTime = time(NULL);
	while (true)
	{
		if ((timeout > 0) && ((startTime + timeout) <= time(NULL))) {
			doneMode = CLogoView::TIMEOUT;
			ClearThis(clearScreen);
			return 0;
		}
		if (CheckFile(FLAG_FILE)) {
			doneMode = CLogoView::FLAGFILE;
			ClearThis();
			return 0;
		}
		usleep(100000);
	}
	ClearThis();
	return 0;
}

unsigned char * CLogoView::Resize(unsigned char *orgin, int ox, int oy, int dx, int dy, bool alpha)
{
	unsigned char * cr;
	cr = (unsigned char*) malloc(dx * dy * ((alpha) ? 4 : 3));
	if(cr == NULL) {
		printf("Resize Error: malloc\n");
		return(orgin);
	}
	unsigned char *p,*q;
	int i,j,k,l,ya,yb;
	int sq,r,g,b,a;
	p=cr;
	int xa_v[dx];
	for(i=0;i<dx;i++)
		xa_v[i] = i*ox/dx;
	int xb_v[dx+1];
	for(i=0;i<dx;i++) {
		xb_v[i]= (i+1)*ox/dx;
		if(xb_v[i]>=ox)
			xb_v[i]=ox-1;
	}
	if (alpha) {
		for(j=0;j<dy;j++) {
			ya= j*oy/dy;
			yb= (j+1)*oy/dy; if(yb>=oy) yb=oy-1;
			for(i=0;i<dx;i++,p+=4) {
				for(l=ya,r=0,g=0,b=0,a=0,sq=0;l<=yb;l++) {
					q=orgin+((l*ox+xa_v[i])*4);
					for(k=xa_v[i];k<=xb_v[i];k++,q+=4,sq++) {
						r+=q[0]; g+=q[1]; b+=q[2]; a+=q[3];
					}
				}
				p[0]=r/sq; p[1]=g/sq; p[2]=b/sq; p[3]=a/sq;
			}
		}
	} else {
		for(j=0;j<dy;j++) {
			ya= j*oy/dy;
			yb= (j+1)*oy/dy; if(yb>=oy) yb=oy-1;
			for(i=0;i<dx;i++,p+=3) {
				for(l=ya,r=0,g=0,b=0,sq=0;l<=yb;l++) {
					q=orgin+((l*ox+xa_v[i])*3);
					for(k=xa_v[i];k<=xb_v[i];k++,q+=3,sq++) {
						r+=q[0]; g+=q[1]; b+=q[2];
					}
				}
				p[0]=r/sq; p[1]=g/sq; p[2]=b/sq;
			}
		}
	}
	free(orgin);
	return(cr);
}

void sighandler(int signum)
{
// http://www.linux-praxis.de/linux1/prozess4.html
        CLogoView * clv = CLogoView::getInstance();
        switch (signum) {
          case SIGTERM: //15
          case SIGINT:  // 2
		signal (signum, SIG_IGN);
		clv->doneMode = CLogoView::SIGHANDLER;
		clv->ClearThis();
                exit(0);
          case SIGUSR1: //10
		signal (signum, SIG_IGN);
		clv->doneMode = CLogoView::SIGHANDLER;
		clv->ClearThis(false);
                exit(0);
          case SIGUSR2: //12
		clv->PrintHelp();
                break;
          default:
                break;
        }
}

int main(int argc, char *argv[])
{
	signal(SIGTERM, sighandler);
	signal(SIGINT,  sighandler);
	signal(SIGUSR1, sighandler);
	signal(SIGUSR2, sighandler);
	signal(SIGHUP,  SIG_IGN);
	return CLogoView::getInstance()->run(argc, argv);
}
