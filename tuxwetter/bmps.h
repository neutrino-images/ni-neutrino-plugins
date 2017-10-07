/*
 * $Id: bmps.h,v 1.1 2009/12/19 19:42:49 rhabarber1848 Exp $
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



//****************************** bmp2lcd *****************************

#ifndef __BMP2LCD__
#define __BMP2LCD__

int bmp2lcd (char *); 
void clear_lcd(void);
#endif // __BMP2LCD__


//******************************** raw.h ******************************

#ifndef __raw__
#define __raw__

struct raw_header {
	short int width;
	short int height;
	unsigned char trans;
}__attribute((packed));

typedef unsigned char lcd_raw_buffer[64][120];
typedef unsigned char lcd_packed_buffer[8][120];
typedef unsigned char lcd_raw4bit_buffer[64][60];

void packed2raw(lcd_packed_buffer, lcd_raw_buffer);
void raw2packed(lcd_raw_buffer, lcd_packed_buffer);
void raw2raw4bit(lcd_raw_buffer, lcd_raw4bit_buffer);

#endif // __raw__

//******************************** bmp.h ******************************

#ifndef __bmp__
#define __bmp__

struct bmp_header {
	unsigned char _B;	// = 'B'
	unsigned char _M;	// = 'M'
	long int file_size;	// file size
	long int reserved;	// = 0
	long int data_offset;	// start of raw data
	// bitmap info header starts here
	long int header_size;	// = 40
	long int width;		// = 120
	long int height;	// = 64
	short int planes;	// = 1
	short int bit_count;	// 1..24
	long int compression;	// = 0
	long int image_size;	// 120*64*bitcount/8
	long int x_ppm;		// X pixels/meter
	long int y_ppm;		// Y pixels/meter
	long int colors_used;	// 
	long int colors_vip;	// important colors (all=0)
}__attribute((packed));

struct bmp_color {
	unsigned char r, g, b, reserved;
}__attribute((packed));

int bmp2raw(struct bmp_header bh, unsigned char *bmp, lcd_raw_buffer raw);

#endif // __bmp__



