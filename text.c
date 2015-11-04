#include "text.h"
#include "gfx.h"
#include "io.h"

int FSIZE_BIG=28;
int FSIZE_MED=24;
int FSIZE_SMALL=20;
int TABULATOR=72;

static unsigned sc[8]={'a','o','u','A','O','U','z','d'}, tc[8]={'ä','ö','ü','Ä','Ö','Ü','ß','°'}, su[7]={0xA4,0xB6,0xBC,0x84,0x96,0x9C,0x9F};

void TranslateString(char *src)
{
int i,found,quota=0;
char rc,*rptr=src,*tptr=src;

	while(*rptr != '\0')
	{
		if(*rptr=='\'')
		{
			quota^=1;
		}
		if(!quota && *rptr=='~')
		{
			++rptr;
			rc=*rptr;
			found=0;
			for(i=0; i<sizeof(sc)/sizeof(sc[0]) && !found; i++)
			{
				if(rc==sc[i])
				{
					rc=tc[i];
					found=1;
				}
			}
			if(found)
			{
				*tptr=rc;
			}
			else
			{
				*tptr='~';
				tptr++;
				*tptr=*rptr;
			}
		}
		else
		{
			if (!quota && *rptr==0xC3 && *(rptr+1))
			{
				found=0;
				for(i=0; i<sizeof(su)/sizeof(su[0]) && !found; i++)
				{
					if(*(rptr+1)==su[i])
					{
						found=1;
						*tptr=tc[i];
						++rptr;
					}
				}
				if(!found)
				{
					*tptr=*rptr;
				}
			}
			else
			{
				*tptr=*rptr;
			}
		}
		tptr++;
		rptr++;
	}
	*tptr=0;
}

/******************************************************************************
* MyFaceRequester
******************************************************************************/

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library library, FT_Pointer request_data, FT_Face *aface)
{
	FT_Error result;

	result = FT_New_Face(library, face_id, 0, aface);

	if(result) printf("shellexec <Font \"%s\" failed>\n", (char*)face_id);

	return result;
}

/******************************************************************************
* RenderChar
******************************************************************************/

int RenderChar(FT_ULong currentchar, int sx, int sy, int ex, int color)
{
	//	unsigned char pix[4]={oldcmap.red[col],oldcmap.green[col],oldcmap.blue[col],oldcmap.transp[col]};
	//	unsigned char pix[4]={0x80,0x80,0x80,0x80};
	unsigned char pix[4]={bl[color],gn[color],rd[color],tr[color]};
	int row, pitch, bit, x = 0, y = 0;
	FT_UInt glyphindex;
	FT_Vector kerning;
	FT_Error error;

	currentchar=currentchar & 0xFF;

	//load char

	if(!(glyphindex = FT_Get_Char_Index(face, (int)currentchar)))
	{
		//			printf("msgbox <FT_Get_Char_Index for Char \"%c\" failed\n", (int)currentchar);
		return 0;
	}


	if((error = FTC_SBitCache_Lookup(cache, &desc, glyphindex, &sbit, NULL)))
	{
		//			printf("msgbox <FTC_SBitCache_Lookup for Char \"%c\" failed with Errorcode 0x%.2X>\n", (int)currentchar, error);
		return 0;
	}

	// no kerning used
	/*
	if(use_kerning)
	{
		FT_Get_Kerning(face, prev_glyphindex, glyphindex, ft_kerning_default, &kerning);

		prev_glyphindex = glyphindex;
		kerning.x >>= 6;
}
else
	*/
	kerning.x = 0;

//render char

if(color != -1) /* don't render char, return charwidth only */
{
	if(sx + sbit->xadvance >= ex) return -1; /* limit to maxwidth */

		for(row = 0; row < sbit->height; row++)
		{
			for(pitch = 0; pitch < sbit->pitch; pitch++)
			{
				for(bit = 7; bit >= 0; bit--)
				{
					if(pitch*8 + 7-bit >= sbit->width) break; /* render needed bits only */

						if((sbit->buffer[row * sbit->pitch + pitch]) & 1<<bit) memcpy(lbb + (startx + sx + sbit->left + kerning.x + x)*4 + fix_screeninfo.line_length*(starty + sy - sbit->top + y),pix,4);

						x++;
				}
			}

			x = 0;
			y++;
		}

}

//return charwidth

return sbit->xadvance + kerning.x;
}

/******************************************************************************
 * GetStringLen
 ******************************************************************************/

int GetStringLen(int sx, unsigned char *string, int size)
{
	int i, found;
	int stringlen = 0;
	
	//reset kerning
	
	prev_glyphindex = 0;
	
	//calc len
	
	switch (size)
	{
		case SMALL: desc.width = desc.height = FSIZE_SMALL; break;
		case MED:   desc.width = desc.height = FSIZE_MED; break;
		case BIG:   desc.width = desc.height = FSIZE_BIG; break;
		default:    desc.width = desc.height = size; break;
	}

	while(*string != '\0')
	{
		if(*string != '~')
		{
			stringlen += RenderChar(*string, -1, -1, -1, -1);
		}
		else
		{
			string++;
			if(*string=='t')
			{
				stringlen=desc.width+TABULATOR*((int)(stringlen/TABULATOR)+1);
			}
			else
			{
				if(*string=='T')
				{
					if(sscanf(string+1,"%4d",&i)==1)
					{
						string+=4;
						stringlen=i-sx;
					}
				}
				else
				{
					found=0;
					for(i=0; i<sizeof(sc)/sizeof(sc[0]) && !found; i++)
					{
						if(*string==sc[i])
						{
							stringlen += RenderChar(tc[i], -1, -1, -1, -1);
							found=1;
						}
					}
				}
			}
		}
		string++;
	}
	
	return stringlen;
}


/******************************************************************************
 * RenderString
 ******************************************************************************/

void RenderString(char *string, int sx, int sy, int maxwidth, int layout, int size, int color)
{
	int stringlen, ex, charwidth, i;
	char rstr[256], *rptr=rstr;
	int varcolor=color;

	strcpy(rstr,string);
	if(strstr(rstr,"~c"))
		layout=CENTER;

	//set size

		switch (size)
		{
			case SMALL: desc.width = desc.height = FSIZE_SMALL; break;
			case MED:   desc.width = desc.height = FSIZE_MED; break;
			case BIG:   desc.width = desc.height = FSIZE_BIG; break;
			default:    desc.width = desc.height = size; break;
		}
		
	//set alignment

		if(layout != LEFT)
		{
			stringlen = GetStringLen(sx, string, size);

			switch(layout)
			{
				case CENTER:	if(stringlen < maxwidth) sx += (maxwidth - stringlen)/2;
						break;

				case RIGHT:	if(stringlen < maxwidth) sx += maxwidth - stringlen;
			}
		}

	//reset kerning

		prev_glyphindex = 0;

	//render string

		ex = sx + maxwidth;

		while(*rptr != '\0')
		{
			if(*rptr=='~')
			{
				++rptr;
				switch(*rptr)
				{
					case 'R': varcolor=RED; break;
					case 'G': varcolor=GREEN; break;
					case 'Y': varcolor=YELLOW; break;
					case 'B': varcolor=BLUE0; break;
					case 'S': varcolor=color; break;
					case 't': sx=((sx/TABULATOR)+1)*TABULATOR; break;
					case 'T': 
						if(sscanf(rptr+1,"%4d",&i)==1)
						{
							rptr+=4;
							sx=i;
						}
						else
						{
							sx=((sx/TABULATOR)+1)*TABULATOR;
						}
				}
			}
			else
			{
				if((charwidth = RenderChar(*rptr, sx, sy, ex, ((color!=CMCIT) && (color!=CMCST))?varcolor:color)) == -1) return; /* string > maxwidth */
				sx += charwidth;
			}
			rptr++;
		}
}

/******************************************************************************
 * ShowMessage
 ******************************************************************************/

void remove_tabs(char *src)
{
int i;
char *rmptr, *rmstr, *rmdptr;

	if(src && *src)
	{
		rmstr=strdup(src);
		rmdptr=rmstr;
		rmptr=src;
		while(*rmptr)
		{
			if(*rmptr=='~')
			{
				++rmptr;
				if(*rmptr)
				{
					if(*rmptr=='t')
					{
						*(rmdptr++)=' ';
					}
					else
					{
						if(*rmptr=='T')
						{
							*(rmdptr++)=' ';
							i=4;
							while(i-- && *(rmptr++));
						}
					}
					++rmptr;
				}
			}
			else
			{
				*(rmdptr++)=*(rmptr++);
			}
		}
		*rmdptr=0;
		strcpy(src,rmstr);
		free(rmstr);
	}
}

void ShowMessage(char *mtitle, char *message, int wait)
{
	extern int radius;
	int ixw=400;
	int lx=startx/*, ly=starty*/;
	char *tdptr;
	
	startx = sx + (((ex-sx) - ixw)/2);
//	starty=sy;
	
	//layout

		RenderBox(0, 178, ixw, 327, radius, CMH);
		RenderBox(2, 180, ixw-4, 323, radius, CMC);
		RenderBox(0, 178, ixw, 220, radius, CMH);

	//message
		
		tdptr=strdup(mtitle);
		remove_tabs(tdptr);
		RenderString(tdptr, 2, 213, ixw, CENTER, FSIZE_BIG, CMHT);
		free(tdptr);
		tdptr=strdup(message);
		remove_tabs(tdptr);
		RenderString(tdptr, 2, 270, ixw, CENTER, FSIZE_MED, CMCT);
		free(tdptr);

		if(wait)
		{
			RenderBox(ixw/2-25, 286, ixw/2+25, 310, radius, CMCS);
			RenderString("OK", ixw/2-25, 305, 50, CENTER, FSIZE_MED, CMCT);
		}
		memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);

		while(wait && (GetRCCode() != RC_OK));
		
		startx=lx;
//		starty=ly;

}

