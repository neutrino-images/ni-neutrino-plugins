/*
 * sysinfo
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
#define _GNU_SOURCE

#include "text.h"
#include "gfx.h"

int FSIZE_BIG=28;
int FSIZE_MED=24;
int FSIZE_SMALL=20;
int FSIZE_VSMALL=16;

int OFFSET_MED=10;
int OFFSET_SMALL=5;
int OFFSET_MIN=2;


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

#include <stdbool.h>
#include <string.h>

void TranslateString(char *src, size_t size)
{
    const char *su = "\xA4\xB6\xBC\x84\x96\x9C\x9F";
    const char *tc = "\xE4\xF6\xFC\xC4\xD6\xDC\xDF\xB0";
    size_t src_len = strlen(src);
    char *fptr = alloca(src_len * 4 + 1);
    char *tptr = src;
    size_t remaining_size = size - 1;  // Reserve 1 byte for null-terminator

    if (isValidUTF8(src))
        return;

    strncpy(fptr, src, src_len * 4);
    fptr[src_len * 4] = '\0';  // Ensure null-termination

    while (*fptr && remaining_size > 0)
    {
        int i;
        for (i = 0; tc[i] && (tc[i] != *fptr); i++);

        if (tc[i])
        {
            if (remaining_size >= 2)
            {
                *tptr++ = 0xC3;
                *tptr++ = su[i];
                fptr++;
                remaining_size -= 2;
            }
            else
            {
                break;  // Insufficient space for translation, stop processing
            }
        }
        else if (*fptr & 0x80)
        {
            fptr++;
        }
        else
        {
            if (remaining_size >= 1)
            {
                *tptr++ = *fptr++;
                remaining_size--;
            }
            else
            {
                break;  // Insufficient space for character, stop processing
            }
        }
    }

    *tptr = '\0';
}

/******************************************************************************
 * MyFaceRequester
 ******************************************************************************/

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library library, FT_Pointer request_data __attribute__((unused)), FT_Face *aface)
{
	FT_Error result;

	result = FT_New_Face(library, face_id, 0, aface);

	if (result)
		printf("%s <Font \"%s\" failed>\n", __plugin__, (char*)face_id);

	return result;
}

/******************************************************************************
 * Colors
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

/******************************************************************************
 * RenderChar
 ******************************************************************************/

int RenderChar(FT_ULong currentchar, int _sx, int _sy, int _ex, int color)
{
	int row, pitch;
	FT_UInt glyphindex;
	FT_Vector kerning;
	FT_Error err;

	int _d = 0;
	if (1)
	{
		FT_UInt _i = FT_Get_Char_Index(face, 'g');
		FTC_SBit _g;
		if ((err = FTC_SBitCache_Lookup(cache, &desc, _i, &_g, NULL)))
		{
			printf("%s <FTC_SBitCache_Lookup for Char \"%c\" failed with Errorcode 0x%.2X>\n", __plugin__, (int)currentchar, err);
			return 0;
		}
		_d = _g->height - _g->top;
		_d += 1;
	}

	//load char
	if (!(glyphindex = FT_Get_Char_Index(face, currentchar)))
	{
		printf("%s <FT_Get_Char_Index for Char \"%c\" failed>\n", __plugin__, (int)currentchar);
		return 0;
	}

	FTC_SBit sbit;
	if ((err = FTC_SBitCache_Lookup(cache, &desc, glyphindex, &sbit, NULL)))
	{
		printf("%s <FTC_SBitCache_Lookup for Char \"%c\" failed with Errorcode 0x%.2X>\n", __plugin__, (int)currentchar, err);
		return 0;
	}

	if (use_kerning)
	{
		FT_Get_Kerning(face, prev_glyphindex, glyphindex, FT_KERNING_DEFAULT, &kerning);
		prev_glyphindex = glyphindex;
		kerning.x >>= 6;
	}
	else
	{
		kerning.x = 0;
	}

	//render char
	if (color != -1) /* don't render char, return charwidth only */
	{
		if (_sx + sbit->xadvance >= _ex)
			return -1; /* limit to maxwidth */

		uint32_t bgcolor = *(lbb + (_sy - _d - 1) * swidth + (_sx + OFFSET_MIN + sbit->left));
		uint32_t fgcolor = bgra[color];
		uint32_t *colors = lookup_colors(fgcolor, bgcolor);
		uint32_t *p = lbb + (_sx + sbit->left + kerning.x) + swidth * (_sy - sbit->top - _d);
		uint32_t *r = p + (_ex - _sx); /* end of usable box */

		for (row = 0; row < sbit->height; row++)
		{
			uint32_t *q = p;
			uint8_t *s = sbit->buffer + row * sbit->pitch;
			for (pitch = 0; pitch < sbit->width; pitch++)
			{
				if (*s)
					*q = colors[*s];
				q++;
				s++;
				if (q > r) /* we are past _ex */
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

int GetStringLen(const char *string, size_t size)
{
	int stringlen = 0;

	desc.width = desc.height = size;

	//reset kerning
	prev_glyphindex = 0;

	while(*string)
	{
		stringlen += RenderChar(*string, -1, -1, -1, -1);
		string++;
	}

	return stringlen;
}

/******************************************************************************
 * RenderString
 ******************************************************************************/

void RenderString(const char *_string, int _sx, int _sy, int maxwidth, int layout, size_t size, int color)
{
	int stringlen, _ex, charwidth;
	int len = strlen(_string);
	char *string = alloca(len * 4 + 1);
	strcpy(string, _string);
	TranslateString(string, len * 4 + 1);

	desc.height = desc.width = size;

	//set alignment
	if (layout != LEFT)
	{
		stringlen = GetStringLen(_string, size);

		switch(layout)
		{
			case CENTER:
					if (stringlen < maxwidth) _sx += (maxwidth - stringlen)/2;
					break;

			case RIGHT:
					if (stringlen < maxwidth) _sx += maxwidth - stringlen;
		}
	}

	//reset kerning
	prev_glyphindex = 0;


	//render string
	_ex = _sx + maxwidth;
	while(*string != '\0' && *string != '\n')
	{
		if ((charwidth = RenderChar(UTF8ToUnicode(&string, 1), _sx, _sy, _ex, color)) == -1)
			return; /* string > maxwidth */
		_sx += charwidth;
	}
}
