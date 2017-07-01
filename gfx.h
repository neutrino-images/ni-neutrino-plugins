#ifndef __GFX_H__

#define __GFX_H__

void Center_Screen(int wx, int wy, int *csx, int *csy);
void RenderBox(int rsx, int rsy, int rex, int rey, int mode, int color);
int paintIcon(const char *const fname, int xstart, int ystart, int xsize, int ysize, int *iw, int *ih);
void scale_pic(unsigned char **buffer, int x1, int y1, int xstart, int ystart, int xsize, int ysize,
			   int *imx, int *imy, int *dxp, int *dyp, int *dxo, int *dyo, int center, int alpha);

void RenderLine( int xa, int ya, int xb, int yb, unsigned char farbe );

#endif
