#ifndef __GFX_H__
#define __GFX_H__

void RenderBox(int sx, int sy, int ex, int ey, int mode, int color);
void RenderCircle(int sx, int sy, char type);
size_t GetCircleHeight();
//void PaintIcon(char *filename, int x, int y, unsigned char offset);

#endif
