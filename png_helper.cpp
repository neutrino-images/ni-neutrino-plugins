
#include "pngw.h"

int png_load_ext(const char *filename, unsigned char **buffer, int* xp, int* yp, int* bpp);
int fh_png_getsize(const char *filename, int *x, int *y);

extern "C"
{

int png_load(const char *filename, unsigned char **buffer, int* xp, int* yp, int* bpp)
{
	return png_load_ext(filename, buffer, xp, yp, bpp);
}

int png_getsize(const char *filename, int *x, int *y)
{
	return fh_png_getsize(filename, x, y);
}

}
