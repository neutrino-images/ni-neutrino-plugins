/*
 * $Id: bmps.c,v 1.1 2009/12/19 19:42:49 rhabarber1848 Exp $
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

#include <stdio.h>
#include <stdlib.h>
#include "bmps.h"
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <dbox/lcd-ks0713.h>
#include <string.h>
#include "bmps.h"


//***************** bmp_show.c **********************

#define swap32bits(i) (i>>24) | (i<<24) | ((i>>8) & 0x00f0) | ((i<<8) & 0x0f00)
#define swap16bits(i) (i>>8) | (i<<8)

int lcd_fd=-1;
lcd_packed_buffer s;
#if 0 // only dbox2 begin
int bmp2lcd (char *bildfile)
{
	char bild2lcd [50];
	char filename[50];
	char bmpfile[50];

	int intbild;

	if (strstr(bildfile,"tuxwettr.bmp")==NULL)
	{
		if (bildfile[0] == 45)
		{
			sprintf (filename,"na.bmp");
		}
		else
		{
			intbild=atoi(bildfile);
			sprintf(filename,"%d.bmp",intbild);
		}
	}
	else
	{
		strcpy(filename,bildfile);
	}

	sprintf(bmpfile,"/share/tuxbox/tuxwetter/%s",filename);

	FILE *fbmp;

	struct bmp_header bh;
	struct bmp_color *colors;
	long int line_size, bmpline_size, image_size;
	unsigned char *image;

	lcd_raw_buffer raw;
	int mode;

	if ((fbmp = fopen(bmpfile, "r"))==NULL) {
		perror("fopen(BMP_FILE)");
		return(2);
	}
	if (fread(&bh, 1, sizeof(bh), fbmp)!=sizeof(bh)) {
		perror("fread(BMP_HEADER)");
		fclose(fbmp);
		return(3);
	}
	if ((bh._B!='B')||(bh._M!='M')) {
		fprintf(stderr, "Bad Magic (not a BMP file).\n");
		fclose(fbmp);
		return(4);
	}

	#if 1
	bh.file_size = swap32bits(bh.file_size);
	bh.width = swap32bits(bh.width);
	bh.height = swap32bits(bh.height);
	bh.bit_count = swap16bits(bh.bit_count);
	#endif

	// 4 * 2^bit_count
	colors = malloc(4<<bh.bit_count);
	if (fread(colors, 1, 4<<bh.bit_count, fbmp)!=4<<bh.bit_count) {
		perror("fread(BMP_COLORS)");
		fclose(fbmp);
		if(colors)
			free(colors);
		return(5);
	}
	if(colors)
		free(colors);

	// image
	line_size = (bh.width*bh.bit_count / 8);
	bmpline_size = (line_size + 3) & ~3;
	image_size = bmpline_size*bh.height;

	image = malloc(image_size);
	if (fread(image, 1, image_size, fbmp)!=image_size) {
		perror("fread(BMP_IMAGE)");
		fclose(fbmp);
		if(image)
			free(image);
		return(6);
	}
	fclose(fbmp);

	if ((bh.width != 120) || (bh.height != 64))
		printf("WARNING: Not 120x64 pixels - result unpredictable.\n");
	if (bh.compression != 0)
		printf("WARNING: Image is compressed - result unpredictable.\n");

	bmp2raw(bh, image, raw);
	if(image)
		free(image);
	raw2packed(raw, s);

	if(lcd_fd < 0)
	{
        	if ((lcd_fd = open("/dev/dbox/lcd0",O_RDWR)) < 0)
        	{
                	perror("open(/dev/dbox/lcd0)");
                	return(1);
        	}
        	mode = LCD_MODE_BIN;
        	if (ioctl(lcd_fd,LCD_IOCTL_ASC_MODE,&mode) < 0)
        	{
                	perror("init(LCD_MODE_BIN)");
                	close(lcd_fd);
                	return(1);
        	}
        }
	write(lcd_fd, &s, LCD_BUFFER_SIZE);

	return 0;
}
void clear_lcd(void)
{
	if(lcd_fd)
	{
		close(lcd_fd);
		lcd_fd=-1;
	}
}

//************** bmp.c **********************

int bmp2raw(struct bmp_header bh, unsigned char *bmp, lcd_raw_buffer raw) {
	int x, y, ofs, linesize;
	linesize = ((bh.width*bh.bit_count / 8) + 3) & ~3;
	switch (bh.bit_count) {
	case 1:
		for (y=0; y<64; y++) { for (x=0; x<120; x++) {
			ofs = (bh.height - 1 - y)*linesize + (x>>3);
			raw[y][x] = 255*((bmp[ofs]>>(7-(x&7)))&1);
		} }
		break;
	case 4:
		for (y=0; y<64; y++) { for (x=0; x<60; x++) {
			ofs = (bh.height - 1 - y)*linesize + x;
			raw[y][x*2] = bmp[ofs] >> 4;
			raw[y][x*2+1] = bmp[ofs] & 0x0F;
		} }
		break;
	default:
		return -1;
	}
	return 0;
}


//***************** raw.c ******************



void packed2raw(lcd_packed_buffer source, lcd_raw_buffer dest) {
	int x, y, pix;
	for (y=0; y<64; y++) {
		for (x=0; x<120; x++) {
			pix = (source[y>>3][x] >> (y&7)) & 1;
			dest[y][x] = pix*255;
		}
	}
}
void raw2packed(lcd_raw_buffer source, lcd_packed_buffer dest) {
	int x, y, y_sub, pix;

	for (y=0; y<8; y++) {
		for (x=0; x<120; x++) {
			pix = 0;
			for (y_sub=7; y_sub>=0; y_sub--) {
				pix = pix<<1;
				if (source[y*8+y_sub][x]) pix++;
			}
			dest[y][x] = pix;
		}
	}
}

void raw2raw4bit(lcd_raw_buffer source, lcd_raw4bit_buffer dest) {
	int x, y;

	for (y=0; y<64; y++) {
		for (x=0; x<60; x++) {
			dest[y][x] = ((source[y][x*2]<<4) & 0xf0) +
			             (source[y][x*2+1] & 0x0f);
		}
	}
}
#endif // only dbox2 end
