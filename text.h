#ifndef __TEXT_H__

#define __TEXT_H__

#include "shellexec.h"

extern int FSIZE_BIG;
extern int FSIZE_MED;
extern int FSIZE_SMALL;

void TranslateString(char *src);
int GetStringLen(int sx, unsigned char *string, int size);
FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library library, FT_Pointer request_data, FT_Face *aface);
void RenderString(char *string, int sx, int sy, int maxwidth, int layout, int size, int color);
void ShowMessage(char *mtitle, char *message, int wait);
void remove_tabs(char *src);

#endif
