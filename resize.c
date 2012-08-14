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

unsigned char * color_average_resize(unsigned char * orgin,int ox,int oy,int dx,int dy)
{
//   dbout("color_average_resize{\n");
	unsigned char *cr,*p,*q;
	int i,j,k,l,xa,xb,ya,yb;
	int sq,r,g,b;
	cr=(unsigned char*) malloc(dx*dy*3); 
	if(cr==NULL)
	{
		printf("Error: malloc\n");
//      dbout("color_average_resize}\n");
		return(orgin);
	}
	p=cr;

	for(j=0;j<dy;j++)
	{
		for(i=0;i<dx;i++,p+=3)
		{
			xa=i*ox/dx;
			ya=j*oy/dy;
			xb=(i+1)*ox/dx; if(xb>=ox)	xb=ox-1;
			yb=(j+1)*oy/dy; if(yb>=oy)	yb=oy-1;
			for(l=ya,r=0,g=0,b=0,sq=0;l<=yb;l++)
			{
				q=orgin+((l*ox+xa)*3);
				for(k=xa;k<=xb;k++,q+=3,sq++)
				{
					r+=q[0]; g+=q[1]; b+=q[2];
				}
			}
			p[0]=r/sq; p[1]=g/sq; p[2]=b/sq;
		}
	}
	free(orgin);
//   dbout("color_average_resize}\n");
	return(cr);
}
