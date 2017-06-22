#ifndef __GFX_H__

#define __GFX_H__

void Center_Screen(int wx, int wy, int *csx, int *csy);
void RenderBox(int sx, int sy, int ex, int ey, int mode, int color);
//void PaintIcon(char *filename, int x, int y, unsigned char offset);

void RenderLine( int xa, int ya, int xb, int yb, unsigned char farbe );
void RenderCircle(int sx, int sy, int col);

#endif
