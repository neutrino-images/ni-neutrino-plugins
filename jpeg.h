#ifndef __jpeg_h__
#define __jpeg_h__


int jpeg_load(const char *filename, unsigned char **buffer, int* x, int* y);
int jpeg_getsize(const char *filename,int *x,int *y, int wanted_width, int wanted_height);

#define FH_ERROR_OK 0
#define FH_ERROR_FILE 1		/* read/access error */
#define FH_ERROR_FORMAT 2	/* file format error */
#define FH_ERROR_MALLOC 3	/* error during malloc */


#endif // __jpeg_h__
