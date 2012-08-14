#ifndef __GFX_H__

#define __GFX_H__

typedef struct {unsigned char bl; unsigned char gn; unsigned char rd; unsigned char tr;} pixstruct;
typedef union {
	unsigned long lpixel;
	pixstruct cpixel;
} gpixel;

gpixel *make_color(int col, gpixel *pix);

void RenderBox(int sx, int sy, int ex, int ey, int mode, gpixel *pix);

#endif
