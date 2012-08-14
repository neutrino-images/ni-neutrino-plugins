#include <string.h>
#include <stdio.h>
#include <time.h>
//#include <linux/delay.h>
//#include "getrc.h"
#include "io.h"

int main (int argc, char **argv)
{
int rv='X',i;
char *key=NULL;
int tmo=0;
	InitRC();
	for(i=1; i<argc; i++)
	{
		if(strstr(argv[i],"key=")==argv[i])
		{
			key=argv[i]+4;
		}
		if(strstr(argv[i],"timeout=")==argv[i])
		{
			if(sscanf(argv[i]+8,"%d",&tmo)!=1)
			{
				tmo=0;
			}
		}
	}

	rv=GetRCCode(key, tmo);
	
	CloseRC();

	printf("%c\n",rv);
	return rv;
}



