#include "text.h"
#include "gfx.h"
#include "io.h"

int FSIZE_BIG=28;
int FSIZE_MED=24;
int FSIZE_SMALL=20;
int TABULATOR=72;

/******************************************************************************
 * MyFaceRequester
 ******************************************************************************/

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library _library, FT_Pointer request_data, FT_Face *aface)
{
	FT_Error result;
	request_data=request_data;//for unused request_data
	result = FT_New_Face(_library, face_id, 0, aface);

	if(result) printf("msgbox <Font \"%s\" failed>\n", (char*)face_id);

	return result;
}

/******************************************************************************
 * RenderChar
 ******************************************************************************/

int RenderChar(FT_ULong currentchar, int _sx, int _sy, int _ex, int color)
{
//	unsigned char pix[4]={oldcmap.red[col],oldcmap.green[col],oldcmap.blue[col],oldcmap.transp[col]};
//	unsigned char pix[4]={0x80,0x80,0x80,0x80};
	FT_UInt glyphindex;
	FT_Vector kerning;
//	FT_Error _error;

	currentchar=currentchar & 0xFF;

	//load char

		if(!(glyphindex = FT_Get_Char_Index(face, (int)currentchar)))
		{
//			printf("msgbox <FT_Get_Char_Index for Char \"%c\" failed\n", (int)currentchar);
			return 0;
		}


		if((/*_error =*/ FTC_SBitCache_Lookup(cache, &desc, glyphindex, &sbit, NULL)))
		{
//			printf("msgbox <FTC_SBitCache_Lookup for Char \"%c\" failed with Errorcode 0x%.2X>\n", (int)currentchar, _error);
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
			if(_sx + sbit->xadvance >= _ex){
				return -1; /* limit to maxwidth */
			}
			unsigned char pix[4]={bl[color],gn[color],rd[color],tr[color]};
			int row, pitch, bit, x = 0, y = 0;

			for(row = 0; row < sbit->height; row++)
			{
				for(pitch = 0; pitch < sbit->pitch; pitch++)
				{
					for(bit = 7; bit >= 0; bit--)
					{
						if(pitch*8 + 7-bit >= sbit->width) break; /* render needed bits only */

						if((sbit->buffer[row * sbit->pitch + pitch]) & 1<<bit) memcpy(lbb + (startx + _sx + sbit->left + kerning.x + x)*4 + fix_screeninfo.line_length*(starty + _sy - sbit->top + y),pix,4);

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

int GetStringLen(int _sx, char *string, int size)
{
unsigned int i = 0;
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
							stringlen=i-_sx;
						}
					}
					else
					{
						int found=0;
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

int RenderString(char *string, int _sx, int _sy, int maxwidth, int layout, int size, int color)
{
	int stringlen = 0, _ex = 0, charwidth = 0,found = 0;
	unsigned int i = 0;
	char rstr[BUFSIZE]={0}, *rptr=rstr, rc=' ';
	int varcolor=color;

	//set size
		snprintf(rstr,sizeof(rstr),"%s",string);

		desc.width = desc.height = size;
		TABULATOR=3*size;
	//set alignment

		stringlen = GetStringLen(_sx, rstr, size);

		if(layout != LEFT)
		{
			switch(layout)
			{
				case CENTER:	if(stringlen < maxwidth) _sx += (maxwidth - stringlen)/2;
						break;

				case RIGHT:	if(stringlen < maxwidth) _sx += maxwidth - stringlen;
			}
		}

	//reset kerning

		prev_glyphindex = 0;

	//render string

		_ex = _sx + maxwidth;

		while(*rptr != '\0')
		{
			if(*rptr=='~')
			{
				++rptr;
				rc=*rptr;
				found=0;
				for(i=0; i< sizeof(sc)/sizeof(sc[0]) && !found; i++)
				{
					if(rc==sc[i])
					{
						found=1;
					}
				}
				if(found)
				{
					if((charwidth = RenderChar(rc, _sx, _sy, _ex, varcolor)) == -1) return _sx; /* string > maxwidth */
					_sx += charwidth;
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
							_sx=TABULATOR*((int)(_sx/TABULATOR)+1);
							break;
						case 'T':
							if(sscanf(rptr+1,"%4d",&i)==1)
							{
								rptr+=4;
								_sx=i;
							}
						break;
					}
				}
			}
			else
			{
				if((charwidth = RenderChar(*rptr, _sx, _sy, _ex, varcolor)) == -1) return _sx; /* string > maxwidth */
				_sx += charwidth;
			}
			rptr++;
		}
	return stringlen;
}

