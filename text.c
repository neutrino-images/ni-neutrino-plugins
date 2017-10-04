#include "text.h"
#include "gfx.h"
#include "io.h"

int FSIZE_BIG=28;
int FSIZE_MED=24;
int FSIZE_SMALL=20;
int TABULATOR=72;

int OFFSET_MED=10;
int OFFSET_SMALL=5;
int OFFSET_MIN=2;

extern int flash;
extern int scale2res(int s);

static char *sc = "aouAOUzd",
	*su= "\xA4\xB6\xBC\x84\x96\x9C\x9F",
	*tc="\xE4\xF6\xFC\xC4\xD6\xDC\xDF\xB0";

// from neutrino/src/driver/fontrenderer.cpp
int UTF8ToUnicode(char **textp, const int utf8_encoded) // returns -1 on error
{
	int unicode_value, i;
	char *text = *textp;
	if (utf8_encoded && ((((unsigned char)(*text)) & 0x80) != 0))
	{
		int remaining_unicode_length;
		if ((((unsigned char)(*text)) & 0xf8) == 0xf0) {
			unicode_value = ((unsigned char)(*text)) & 0x07;
			remaining_unicode_length = 3;
		} else if ((((unsigned char)(*text)) & 0xf0) == 0xe0) {
			unicode_value = ((unsigned char)(*text)) & 0x0f;
			remaining_unicode_length = 2;
		} else if ((((unsigned char)(*text)) & 0xe0) == 0xc0) {
			unicode_value = ((unsigned char)(*text)) & 0x1f;
			remaining_unicode_length = 1;
		} else {
			(*textp)++;
			return -1;
		}

		*textp += remaining_unicode_length;

		for (i = 0; *text && i < remaining_unicode_length; i++) {
			text++;
			if (((*text) & 0xc0) != 0x80) {
				remaining_unicode_length = -1;
				return -1;          // incomplete or corrupted character
			}
			unicode_value <<= 6;
			unicode_value |= ((unsigned char)(*text)) & 0x3f;
		}
	} else
		unicode_value = (unsigned char)(*text);

	(*textp)++;
	return unicode_value;
}

void CopyUTF8Char(char **to, char **from)
{
	int remaining_unicode_length;
	if (!((unsigned char)(**from) & 0x80))
		remaining_unicode_length = 1;
	else if ((((unsigned char)(**from)) & 0xf8) == 0xf0)
		remaining_unicode_length = 4;
	else if ((((unsigned char)(**from)) & 0xf0) == 0xe0)
		remaining_unicode_length = 3;
	else if ((((unsigned char)(**from)) & 0xe0) == 0xc0)
		remaining_unicode_length = 2;
	else {
		(*from)++;
		return;
	}
	while (**from && remaining_unicode_length) {
		**to = **from;
		(*from)++, (*to)++, remaining_unicode_length--;
	}
}

int isValidUTF8(char *text) {
	while (*text)
		if (-1 == UTF8ToUnicode(&text, 1))
			return 0;
	return 1;
}

void TranslateString(char *src, size_t size)
{
	char *fptr = src;
	size_t src_len = strlen(src);
	char *tptr_start = alloca(src_len * 4 + 1);
	char *tptr = tptr_start;

	if (isValidUTF8(src)) {
		strncpy(tptr_start, fptr, src_len + 1);
	}
	else {
		while (*fptr) {
			int i;
			for (i = 0; tc[i] && (tc[i] != *fptr); i++);
			if (tc[i]) {
				*tptr++ = 0xC3;
				*tptr++ = su[i];
				fptr++;
			} else if (*fptr & 0x80)
				fptr++;
			else
				*tptr++ = *fptr++;
		}
		*tptr = 0;
	}

	fptr = tptr_start;
	tptr = src;
	char *tptr_end = src + size - 4;

	while (*fptr && tptr <= tptr_end) {
		if (*fptr == '~') {
			fptr++;
			int i;
			for (i = 0; sc[i] && (sc[i] != *fptr); i++);
				if (*fptr == 'd') {
					*tptr++ = 0xC2;
					*tptr++ = 0xb0;
					fptr++;
				} else if (sc[i]) {
					*tptr++ = 0xC3;
					*tptr++ = su[i];
					fptr++;
				} else {
					*tptr++ = '~';
				}
		} else {
			CopyUTF8Char(&tptr, &fptr);
		}
	}
	*tptr = 0;
}

/******************************************************************************
 * MyFaceRequester
 ******************************************************************************/

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library lib, FT_Pointer request_data __attribute__((unused)), FT_Face *aface)
{
	FT_Error result;

	result = FT_New_Face(lib, face_id, 0, aface);

	if (result)
		printf("%s <Font \"%s\" failed>\n", __plugin__, (char*)face_id);

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

	if (currentchar == '\r') // display \r in windows edited files
	{
		if(color != -1)
		{
			if (_sx + OFFSET_MED < _ex)
				RenderBox(_sx, _sy - OFFSET_MED - OFFSET_SMALL, _sx + OFFSET_MED, _sy - OFFSET_SMALL, GRID, color);
			else
				return -1;
		}
		return OFFSET_MED;
	}

	if (currentchar == '\t')
	{
		/* simulate horizontal TAB */
		return scale2res(15);
	}

	//load char

	if(!(glyphindex = FT_Get_Char_Index(face, currentchar)))
	{
		printf("%s <FT_Get_Char_Index for Char \"%c\" failed\n", __plugin__, (int)currentchar);
		return 0;
	}

	if((err = FTC_SBitCache_Lookup(cache, &desc, glyphindex, &sbit, NULL)))
	{
		printf("%s <FTC_SBitCache_Lookup for Char \"%c\" failed with Errorcode 0x%.2X>\n", __plugin__, (int)currentchar, error);
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
		if (_sx + sbit->xadvance >= _ex)
			return -1; /* limit to maxwidth */
		uint32_t fgcolor;
		uint32_t bgcolor = *(lbb + (sy + _sy - _d - 1) * swidth + (sx + _sx + sbit->left));
		if ( color == -2) /* flash */
			fgcolor = bgcolor;
		else	
			fgcolor = bgra[color];
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

int GetStringLen(int _sx, char *string, size_t size)
{
	int i, stringlen = 0;

	//reset kerning

	prev_glyphindex = 0;

	//calc len

	if(size)
		desc.width = desc.height = size;

	while(*string) {
		switch(*string) {
		case '~':
			string++;
			if(*string=='t')
				stringlen=desc.width+TABULATOR*((int)(stringlen/TABULATOR)+1);
			else if(*string=='T' && sscanf(string+1,"%4d",&i)==1) {
				string+=5;
				stringlen=scale2res(i)-_sx;
			}
			else if(*string=='l' ||
					*string=='c' ||
					*string=='r' ||
					*string=='R' ||
					*string=='G' ||
					*string=='B' ||
					*string=='Y' ||
					*string=='S' ||
					*string=='F' ||
					*string=='C') {
				string+=1;
			}
			break;
		default:
			stringlen += RenderChar(UTF8ToUnicode(&string, 1), -1, -1, -1, -1);
			break;
		}
	}

	return stringlen;
}

void CatchLF(char *text)
{
char *src, *dst;
	for (src = dst = text; *src != '\0'; src++)
	{
		*dst = *src;
		if (*dst != 0x0A) dst++;
	}
	*dst = '\0';
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
	int stringlen, _ex, charwidth, i, col;
	char rstr[BUFSIZE]={0}, *rptr=rstr;
	int varcolor=color, butcolor=color;

	//set size

	strcpy(rstr,string);

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
			switch(*rptr)
			{
				case 'R': varcolor=RED; break;
				case 'G': varcolor=GREEN; break;
				case 'Y': varcolor=YELLOW; break;
				case 'B': varcolor=BLUE1; break;
				case 'S': varcolor=color; break;
				case 'F':
					if(butcolor == CMCST)
						col = CMCIT;
					else if(butcolor == CMCIT)
						col = CMCST;
					else
						col = -2;
					varcolor = flash ? col : varcolor;
					break;
				case 't':
					_sx=TABULATOR*((int)(_sx/TABULATOR)+1);
					break;
				case 'T':
					if(sscanf(rptr+1,"%4d",&i)==1)
					{
						rptr+=4;
						_sx=scale2res(i);
					}
				break;
			}
			rptr++;
		}
		else
		{
			if((charwidth = RenderChar(UTF8ToUnicode(&rptr, 1), _sx, _sy, _ex, varcolor)) == -1) return _sx; /* string > maxwidth */
			_sx += charwidth;
		}
	}
	return stringlen;
}
