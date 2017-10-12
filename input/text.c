#include "text.h"
#include "gfx.h"
#include "io.h"

int FSIZE_BIG=32;
int FSIZE_MED=24;
int FSIZE_SMALL=20;
int TABULATOR=300;

int OFFSET_MED=10;
int OFFSET_SMALL=5;
int OFFSET_MIN=2;

/******************************************************************************
 * MyFaceRequester
 ******************************************************************************/

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library lib, FT_Pointer request_data __attribute__((unused)), FT_Face *aface)
{
	FT_Error result;

	result = FT_New_Face(lib, face_id, 0, aface);

	if(result) fprintf(stderr, "msgbox <Font \"%s\" failed>\n", (char*)face_id);

	return result;
}

/******************************************************************************
 * RenderChar
 ******************************************************************************/

struct colors_struct
{
	uint32_t fgcolor, bgcolor;
	uint32_t colors[256];
};

#define COLORS_LRU_SIZE 16
static struct colors_struct *colors_lru_array[COLORS_LRU_SIZE] = { NULL };

static uint32_t *lookup_colors(uint32_t fgcolor, uint32_t bgcolor)
{
	struct colors_struct *cs;
	int i = 0, j;
	for (i = 0; i < COLORS_LRU_SIZE; i++)
		if (colors_lru_array[i] && colors_lru_array[i]->fgcolor == fgcolor && colors_lru_array[i]->bgcolor == bgcolor) {
			cs = colors_lru_array[i];
			for (j = i; j > 0; j--)
				colors_lru_array[j] = colors_lru_array[j - 1];
			colors_lru_array[0] = cs;
			return cs->colors;
		}
	i--;
	cs = colors_lru_array[i];
	if (!cs)
		cs = (struct colors_struct *) calloc(1, sizeof(struct colors_struct));
	for (j = i; j > 0; j--)
		colors_lru_array[j] = colors_lru_array[j - 1];
	cs->fgcolor = fgcolor;
	cs->bgcolor = bgcolor;

	int ro = var_screeninfo.red.offset;
	int go = var_screeninfo.green.offset;
	int bo = var_screeninfo.blue.offset;
	int to = var_screeninfo.transp.offset;
	int rm = (1 << var_screeninfo.red.length) - 1;
	int gm = (1 << var_screeninfo.green.length) - 1;
	int bm = (1 << var_screeninfo.blue.length) - 1;
	int tm = (1 << var_screeninfo.transp.length) - 1;
	int fgr = ((int)fgcolor >> ro) & rm;
	int fgg = ((int)fgcolor >> go) & gm;
	int fgb = ((int)fgcolor >> bo) & bm;
	int fgt = ((int)fgcolor >> to) & tm;
	int deltar = (((int)bgcolor >> ro) & rm) - fgr;
	int deltag = (((int)bgcolor >> go) & gm) - fgg;
	int deltab = (((int)bgcolor >> bo) & bm) - fgb;
	int deltat = (((int)bgcolor >> to) & tm) - fgt;
	for (i = 0; i < 256; i++)
		cs->colors[255 - i] =
			(((fgr + deltar * i / 255) & rm) << ro) |
			(((fgg + deltag * i / 255) & gm) << go) |
			(((fgb + deltab * i / 255) & bm) << bo) |
			(((fgt + deltat * i / 255) & tm) << to);

	colors_lru_array[0] = cs;
	return cs->colors;
}

int RenderChar(FT_ULong currentchar, int _sx, int _sy, int _ex, int color)
{
	int row, pitch;
	FT_UInt glyphindex;
	FT_Vector kerning;
	FT_Error err;

	currentchar &= 0xFF;

	if (currentchar == '\r') // display \r in windows edited files
	{
		if(color != -1)
		{
			if (_sx + 10 < _ex)
				RenderBox(_sx, _sy - 10, _sx + 10, _sy, GRID, color);
			else
				return -1;
		}
		return 10;
	}

	if (currentchar == '\t')
	{
		/* simulate horizontal TAB */
		return 15;
	}

	//load char

	if(!(glyphindex = FT_Get_Char_Index(face, currentchar)))
	{
		fprintf(stderr, "input <FT_Get_Char_Index for Char \"%c\" failed\n", (int)currentchar);
		return 0;
	}

	if((err = FTC_SBitCache_Lookup(cache, &desc, glyphindex, &sbit, NULL)))
	{
		fprintf(stderr, "input <FTC_SBitCache_Lookup for Char \"%c\" failed with Errorcode 0x%.2X>\n", (int)currentchar, error);
		return 0;
	}

	int _d = 0;
	if (1)
	{
		FT_UInt _i = FT_Get_Char_Index(face, 'g');
		FTC_SBit _g;
		FTC_SBitCache_Lookup(cache, &desc, _i, &_g, NULL);
		_d = _g->height - _g->top;
		_d += 1;
	}

	if(use_kerning)
	{
		FT_Get_Kerning(face, prev_glyphindex, glyphindex, ft_kerning_default, &kerning);

		prev_glyphindex = glyphindex;
		kerning.x >>= 6;
	} else
		kerning.x = 0;

	//render char

	if(color != -1) /* don't render char, return charwidth only */
	{
		if (_sx + sbit->xadvance > _ex + 5)
			return -1; /* limit to maxwidth */
		uint32_t bgcolor = *(lbb + (sy + _sy - _d - 1) * swidth + (sx + _sx + OFFSET_MIN + sbit->left));
		uint32_t fgcolor = bgra[color];
		uint32_t *colors = lookup_colors(fgcolor, bgcolor);
		uint32_t *p = lbb + (sx + _sx + sbit->left + kerning.x) + swidth * (sy + _sy - sbit->top - _d);
		uint32_t *r = p + (_ex - _sx);	/* end of usable box */
		for(row = 0; row < sbit->height; row++)
		{
			uint32_t *q = p;
			uint8_t *s = sbit->buffer + row * sbit->pitch;
			for(pitch = 0; pitch < sbit->width; pitch++)
			{
				if (*s)
					*q = colors[*s];
				q++; s++;
				if (q > r)	/* we are past _ex */
					break;
			}
			p += swidth;
			r += swidth;
		}
	}

	//return charwidth

	return sbit->xadvance + kerning.x;
}

/******************************************************************************
 * GetStringLen
 ******************************************************************************/

int GetStringLen(char *string, size_t size)
{
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

int RenderString(const char *string, int _sx, int _sy, int maxwidth, int layout, int size, int color)
{
unsigned i = 0;
int stringlen = 0, _ex = 0, charwidth = 0, found = 0;
char rstr[BUFSIZE]={0}, *rptr=rstr, rc=' ';
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
			case CENTER: if(stringlen < maxwidth) _sx += (maxwidth - stringlen)/2;
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
			if((charwidth = RenderChar(*rptr, _sx, _sy, _ex, varcolor)) == -1) return _sx; /* string > maxwidth */
			_sx += charwidth;
		}
		rptr++;
	}
	return stringlen;
}
