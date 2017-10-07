#ifndef __INPUTD_H__
#define __INPUTD_H__

extern int instance;
int get_instance(void);
void put_instance(int pval);
char *inputd(char *format, char *title, char *defstr, int keys, int frame, int mask, int bhelp, int cols, int tmo);

#endif

