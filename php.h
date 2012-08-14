#ifndef __PHP_H__
#define __PHP_H__

int fh_php_load(const char *name, int sx, int sy, int dy, int cs, int line, int highlite, int plain, int *cut);
int fh_php_getsize(const char *filename, int plain, int *x,int *y);

#endif
