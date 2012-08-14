#ifndef __TXTFORM_H__
#define __TXTFORM_H__

int fh_txt_load(const char *name, int sx, int wx, int sy, int dy, int size, int line, int *cut);
int fh_txt_getsize(const char *filename, int *x, int *y, int size, int *cut);

#endif
