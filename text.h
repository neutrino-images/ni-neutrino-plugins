#ifndef __TEXT_H__

#define __TEXT_H__

#include "tuxwetter.h"

FT_Error MyFaceRequester(FTC_FaceID face_id, FT_Library library, FT_Pointer request_data, FT_Face *aface);
int RenderString(char *string, int _sx, int _sy, int maxwidth, int layout, int size, int color);
void TranslateString(char *src, size_t size);
int GetStringLen(int _sx, char *string, size_t size);
void CatchTabs(char *text);
void ShowMessage(char *message, int wait);

#endif
