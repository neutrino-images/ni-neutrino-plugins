/*
 * $Id: resize.c,v 1.1 2009/12/19 19:42:49 rhabarber1848 Exp $
 *
 * tuxwetter - d-box2 linux project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 *
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#if 0
unsigned char * simple_resize(unsigned char * orgin,int ox,int oy,int dx,int dy)
{
//   dbout("simple_resize{\n");
	unsigned char *cr,*p,*l;
	int i,j,k,ip;
	cr=(unsigned char*) malloc(dx*dy*3);
	if(cr==NULL)
	{
		printf("Error: malloc\n");
//      dbout("simple_resize}\n");
		return(orgin);
	}
	l=cr;

	for(j=0;j<dy;j++,l+=dx*3)
	{
		p=orgin+(j*oy/dy*ox*3);
		for(i=0,k=0;i<dx;i++,k+=3)
		{
			ip=i*ox/dx*3;
			l[k]=p[ip];
			l[k+1]=p[ip+1];
			l[k+2]=p[ip+2];
		}
	}
	free(orgin);
//   dbout("simple_resize}\n");
	return(cr);
}
#endif

unsigned char * color_average_resize(unsigned char * orgin, int ox, int oy, int dx, int dy, int alpha)
{
#if DEBUG
printf(" COLOR_AVERAGE_RESIZE in\n");
#endif
	unsigned char *cr,*p,*q;
	int i,j,k,l,ya,yb;
	int sq,r,g,b,a;
	cr = (unsigned char*) malloc(dx * dy * ((alpha) ? 4 : 3));
	if(cr==NULL)
	{
		printf("Error: malloc\n");
		return(orgin);
	}
	p=cr;

	int xa_v[dx];
	for(i=0;i<dx;i++)
		xa_v[i] = i*ox/dx;
	int xb_v[dx+1];
	for(i=0;i<dx;i++)
	{
		xb_v[i]= (i+1)*ox/dx;
		if(xb_v[i]>=ox)
			xb_v[i]=ox-1;
	}

	if (alpha)
	{
		for(j=0;j<dy;j++)
		{
			ya= j*oy/dy;
			yb= (j+1)*oy/dy; if(yb>=oy) yb=oy-1;
			for(i=0;i<dx;i++,p+=4)
			{
				for(l=ya,r=0,g=0,b=0,a=0,sq=0;l<=yb;l++)
				{
					q=orgin+((l*ox+xa_v[i])*4);
					for(k=xa_v[i];k<=xb_v[i];k++,q+=4,sq++)
					{
						r+=q[0]; g+=q[1]; b+=q[2]; a+=q[3];
					}
				}
				int sq_tmp = sq ? sq : 1;//avoid division by zero
				p[0]= (uint8_t)(r/sq_tmp);
				p[1]= (uint8_t)(g/sq_tmp);
				p[2]= (uint8_t)(b/sq_tmp);
				p[3]= (uint8_t)(a/sq_tmp);
			}
		}
	}else
	{
		for(j=0;j<dy;j++)
		{
			ya= j*oy/dy;
			yb= (j+1)*oy/dy; if(yb>=oy) yb=oy-1;
			for(i=0;i<dx;i++,p+=3)
			{
				for(l=ya,r=0,g=0,b=0,sq=0;l<=yb;l++)
				{
					q=orgin+((l*ox+xa_v[i])*3);
					for(k=xa_v[i];k<=xb_v[i];k++,q+=3,sq++)
					{
						r+=q[0]; g+=q[1]; b+=q[2];
					}
				}
				int sq_tmp = sq ? sq : 1;//avoid division by zero
				p[0]= (uint8_t)(r/sq_tmp);
				p[1]= (uint8_t)(g/sq_tmp);
				p[2]= (uint8_t)(b/sq_tmp);
			}
		}
	}
	free(orgin);
#if DEBUG
printf(" COLOR_AVERAGE_RESIZE out\n");
#endif
	return(cr);
}
