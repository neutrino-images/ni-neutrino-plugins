#include "text.h"
#include "gfx.h"
#include "io.h"

int FSIZE_BIG=28;
int FSIZE_MED=24;
int FSIZE_SMALL=20;
int FSIZE_VSMALL=16;
int TABULATOR=72;
unsigned sc[8]={'a','o','u','A','O','U','z','d'}, tc[8]={'ä','ö','ü','Ä','Ö','Ü','ß','°'};

/******************************************************************************
 * MyFaceRequester
 ******************************************************************************/

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library library, FT_Pointer request_data, FT_Face *aface)
{
	FT_Error result;

	result = FT_New_Face(library, face_id, 0, aface);

	if(result) printf("msgbox <Font \"%s\" failed>\n", (char*)face_id);

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

int GetStringLen(int sx, char *string, int size)
{
int i, found;
int stringlen = 0;

	//reset kerning

		prev_glyphindex = 0;

	//calc len

		if(size)
		{
			desc.width = desc.height = size;
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


void CatchTabs(char *text)
{
	int i;
	char *tptr=text;
	
	while((tptr=strstr(tptr,"~T"))!=NULL)
	{
		*(++tptr)='t';
		for(i=0; i<4; i++)
		{
			if(*(++tptr))
			{
				*tptr=' ';
			}
		}
	}
}

/******************************************************************************
 * RenderString
 ******************************************************************************/

int RenderString(char *string, int sx, int sy, int maxwidth, int layout, int size, int color)
{
	int stringlen, ex, charwidth,i,found;
	char rstr[BUFSIZE], *rptr=rstr, rc;
	int varcolor=color;

	//set size
	
		strcpy(rstr,string);

		desc.width = desc.height = size;
		TABULATOR=3*size;
	//set alignment

		stringlen = GetStringLen(sx, rstr, size);

		if(layout != LEFT)
		{
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
					if((charwidth = RenderChar(rc, sx, sy, ex, varcolor)) == -1) return sx; /* string > maxwidth */
					sx += charwidth;
				}
				else
				{
					switch(*rptr)
					{
						case 'R': varcolor=RED; break;
						case 'G': varcolor=GREEN; break;
						case 'Y': varcolor=YELLOW; break;
						case 'B': varcolor=BLUE0; break;
						case 'S': varcolor=color; break;
						case 't':				
							sx=TABULATOR*((int)(sx/TABULATOR)+1);
							break;
						case 'T':
							if(sscanf(rptr+1,"%4d",&i)==1)
							{
								rptr+=4;
								sx=i;
							}
						break;
					}
				}
			}
			else
			{
				int uml = 0;
				switch(*rptr)    /* skip Umlauts */
				{
					case '\xc4':
					case '\xd6':
					case '\xdc':
					case '\xe4':
					case '\xf6':
					case '\xfc':
					case '\xdf': uml=1; break;
				}
				if (uml == 0)
				{
					// UTF8_to_Latin1 encoding
					if (((*rptr) & 0xf0) == 0xf0)      /* skip (can't be encoded in Latin1) */
					{
						rptr++;
						if ((*rptr) == 0)
							*rptr='\x3f'; // ? question mark
						rptr++;
						if ((*rptr) == 0)
							*rptr='\x3f';
						rptr++;
						if ((*rptr) == 0)
							*rptr='\x3f';
					}
					else if (((*rptr) & 0xe0) == 0xe0) /* skip (can't be encoded in Latin1) */
					{
						rptr++;
						if ((*rptr) == 0)
							*rptr='\x3f';
						rptr++;
						if ((*rptr) == 0)
							*rptr='\x3f';
					}
					else if (((*rptr) & 0xc0) == 0xc0)
					{
						char c = (((*rptr) & 3) << 6);
						rptr++;
						if ((*rptr) == 0)
							*rptr='\x3f';
						*rptr = (c | ((*rptr) & 0x3f));
					}
				}
				if((charwidth = RenderChar(*rptr, sx, sy, ex, varcolor)) == -1) return sx; /* string > maxwidth */
				sx += charwidth;
			}
			rptr++;
		}
	return stringlen;
}

/******************************************************************************
 * ShowMessage
 ******************************************************************************/

void ShowMessage(char *message, int wait)
{
	extern int radius;
	int mxw=400, myw=120+40*wait, mhw=30;
	int msx,msy;
	char *tdptr;

	Center_Screen(mxw, myw, &msx, &msy);

	//layout

		RenderBox(msx, msy, mxw, myw, radius, CMH);
		RenderBox(msx+2, msy+2, mxw-4, myw-4, radius, CMC);
		RenderBox(msx, msy, mxw, mhw, radius, CMH);

	//message

		tdptr=strdup("Tuxwetter Info");
		RenderString(tdptr, msx+2, msy+(mhw-4), mxw-4, CENTER, FSIZE_MED, CMHT);
		free(tdptr);
		tdptr=strdup(message);
		RenderString(tdptr, msx+2, msy+mhw+((myw-mhw)/2)-FSIZE_MED/2+(!wait*15), mxw-4, CENTER, FSIZE_MED, CMCT);
		free(tdptr);

		if(wait)
		{
			RenderBox(msx+mxw/2-25, msy+myw-45, 50, FSIZE_SMALL*3/2, radius, CMCS);
			RenderString("OK", msx+mxw/2-26, msy+myw-42+FSIZE_SMALL, 50, CENTER, FSIZE_SMALL, CMCT);
		}
		memcpy(lfb, lbb, fix_screeninfo.line_length*var_screeninfo.yres);

		while(wait && (GetRCCode() != KEY_OK));


}

void TranslateString(char *src)
{
int i,found;
char rc,*rptr=src,*tptr=src;

	while(*rptr != '\0')
	{
		if(*rptr=='~')
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
			*tptr=*rptr;
		}
		tptr++;
		rptr++;
	}
	*tptr=0;
}
