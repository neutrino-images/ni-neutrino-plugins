#ifndef __TEXT_H__

#define __TEXT_H__

#include "input.h"

extern int FSIZE_BIG;
extern int FSIZE_MED;
extern int FSIZE_SMALL;

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library library, FT_Pointer request_data, FT_Face *aface);
int RenderString(char *string, int sx, int sy, int maxwidth, int layout, int size, int color);
int GetStringLen(unsigned char *string, int size);
void CatchTabs(char *text);

#endif
