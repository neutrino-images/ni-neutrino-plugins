#ifndef __TEXT_H__
#define __TEXT_H__

#include "input.h"

extern int FSIZE_BIG;
extern int FSIZE_MED;
extern int FSIZE_SMALL;

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library library, FT_Pointer request_data, FT_Face *aface);
int RenderString(const char *string, int _sx, int _sy, int maxwidth, int layout, int size, int color);
int GetStringLen(char *string, size_t size);
void CatchTabs(char *text);

#endif
