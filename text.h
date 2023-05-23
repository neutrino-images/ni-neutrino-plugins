/*
 * $Id: text.h,v 1.0  Exp $
 *
 * sysinfo - coolstream linux project
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

#ifndef __TEXT_H__
#define __TEXT_H__

#include "current.h"

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library library, FT_Pointer request_data, FT_Face *aface);
void RenderString(const char *_string, int _sx, int _sy, int maxwidth, int layout, size_t size, int color);
int RenderChar(FT_ULong currentchar, int _sx, int _sy, int _ex, int color);
int GetStringLen(const char *_string, size_t size);
int GetStringLen2(const char *_string, size_t size);

#endif
