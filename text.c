#include "text.h"
#include "gfx.h"
#include "io.h"

int FSIZE_BIG=32;
int FSIZE_MED=24;
int FSIZE_SMALL=20;
int TABULATOR=300;

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

int GetStringLen(unsigned char *string, int size)
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
			stringlen += RenderChar(*string, -1, -1, -1, -1);
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
		for(i=0; i<3; i++)
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

		switch (size)
		{
			case SMALL: desc.width = desc.height = FSIZE_SMALL; break;
			case MED:   desc.width = desc.height = FSIZE_MED; break;
			case BIG:   desc.width = desc.height = FSIZE_BIG; break;
			default:    desc.width = desc.height = size; break;
		}
		TABULATOR=3*size;
	//set alignment

		stringlen = GetStringLen(rstr, size);

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
				for(i=0; i<sizeof(sc) && !found; i++)
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
						case 'B': varcolor=BLUE1; break;
						case 'S': varcolor=color; break;
						case 't':				
							sx=TABULATOR*((int)(sx/TABULATOR)+1);
							break;
						case 'T':
							if(sscanf(rptr+1,"%3d",&i)==1)
							{
								rptr+=3;
								sx=i;
							}
						break;
					}
				}
			}
			else
			{
				if((charwidth = RenderChar(*rptr, sx, sy, ex, varcolor)) == -1) return sx; /* string > maxwidth */
				sx += charwidth;
			}
			rptr++;
		}
	return stringlen;
}

