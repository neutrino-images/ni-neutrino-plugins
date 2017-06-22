/*
 * $Id: gifdecomp.c,v 1.1 2009/12/19 19:42:49 rhabarber1848 Exp $
 *
 * tuxwetter - d-box2 linux project
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

#define HAVE_VARARGS_H
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <ctype.h>
#include <string.h>
#include "gif_lib.h"
#include "gifdecomp.h"

#ifndef TRUE
#define TRUE        1
#endif /* TRUE */
#ifndef FALSE
#define FALSE       0
#endif /* FALSE */

#define PROGRAM_NAME	"GifDecomp"
#define GIF_ASM_NAME   "Tuxwetter"
#define COMMENT_GIF_ASM    "New-Tuxwetter-Team"
#define SQR(x)     ((x) * (x))

#define GIF_MESSAGE(Msg) fprintf(stderr, "\n%s: %s\n", PROGRAM_NAME, Msg)
#define GIF_EXIT(Msg) { GIF_MESSAGE(Msg); exit(-3); }

#define printfe(format, ...) \
  (fprintf(stderr, format "\n", ## __VA_ARGS__), fflush(stderr))

#define printfef(format, ...) \
  printfe("%s " format, __func__, ## __VA_ARGS__)

static int
    InterlacedFlag = FALSE,
    InterlacedOffset[] = { 0, 4, 2, 1 }, /* The way Interlaced image should. */
    InterlacedJumps[] = { 8, 8, 4, 2 };    /* be read - offsets and jumps... */

int LoadImage(GifFileType *GifFile, GifRowType **ImageBuffer);
int DumpImage(GifFileType *GifFile, GifRowType *ImageBuffer);


void xremove(char *fname);

/******************************************************************************
* Perform the disassembly operation - take one input files into few output.   *
******************************************************************************/
int gifdecomp(char *InFileName, char *OutFileName)
{
int i, err = 0;

    GifRowType *ImageBuffer;
    char TempGifName[80];
    sprintf (TempGifName,"/tmp/tempgif.gif");
    int	ExtCode, CodeSize, FileNum = 0, FileEmpty;
    GifRecordType RecordType;
    char CrntFileName[80];
    char tempout[80];
    GifByteType *Extension, *CodeBlock;
    GifFileType *GifFileIn = NULL, *GifFileOut = NULL;
    for(i=0; i<32; i++)
    {
    	sprintf(tempout,"%s%02d.gif",OutFileName,i);
    	xremove(tempout);
    }
    xremove(TempGifName);
    /* Open input file: */
    if (InFileName != NULL) 
    {	
	if ((GifFileIn = DGifOpenFileName(InFileName, &err)) == NULL)
		QuitGifError(GifFileIn, GifFileOut, err);
    }
    if ((GifFileIn = DGifOpenFileName(InFileName, &err)) != NULL)
    {
		if ((GifFileOut = EGifOpenFileName(TempGifName, TRUE, &err)) == NULL)
		QuitGifError(GifFileIn, GifFileOut, err);
   
		if (EGifPutScreenDesc(GifFileOut,
		GifFileIn->SWidth, GifFileIn->SHeight,
		GifFileIn->SColorResolution, GifFileIn->SBackGroundColor,
		GifFileIn->SColorMap) == GIF_ERROR)
		QuitGifError(GifFileIn, GifFileOut, err);

    		/* Scan the content of the GIF file and load the image(s) in: */
    		do {
		if (DGifGetRecordType(GifFileIn, &RecordType) == GIF_ERROR)
	    	QuitGifError(GifFileIn, GifFileOut, err);

		switch (RecordType) {
	    	case IMAGE_DESC_RECORD_TYPE:
			if (DGifGetImageDesc(GifFileIn) == GIF_ERROR)
			QuitGifError(GifFileIn, GifFileOut, err);

			/* Put the image descriptor to out file: */
			if (EGifPutImageDesc(GifFileOut,
			    GifFileIn->Image.Left, GifFileIn->Image.Top,
			    GifFileIn->Image.Width, GifFileIn->Image.Height,
			    InterlacedFlag,
			    GifFileIn->Image.ColorMap) == GIF_ERROR)
			    QuitGifError(GifFileIn, GifFileOut, err);

			/* Load the image (either Interlaced or not), and dump it as */
			/* defined in GifFileOut->Image.Interlaced.		     */
			if (LoadImage(GifFileIn, &ImageBuffer) == GIF_ERROR)
			    QuitGifError(GifFileIn, GifFileOut, err);
			if (DumpImage(GifFileOut, ImageBuffer) == GIF_ERROR)
			    QuitGifError(GifFileIn, GifFileOut, err);
			break;
		    case EXTENSION_RECORD_TYPE:
			/* Skip any extension blocks in file: */
			if (DGifGetExtension(GifFileIn, &ExtCode, &Extension) == GIF_ERROR)
			    QuitGifError(GifFileIn, GifFileOut, err);
			if (EGifPutExtension(GifFileOut, ExtCode, Extension[0],
							Extension) == GIF_ERROR)
			    QuitGifError(GifFileIn, GifFileOut, err);

			/* No support to more than one extension blocks, so discard: */
			while (Extension != NULL) {
			    if (DGifGetExtensionNext(GifFileIn, &Extension) == GIF_ERROR)
				QuitGifError(GifFileIn, GifFileOut, err);
			}
			break;
		    case TERMINATE_RECORD_TYPE:
			break;
		    default:		    /* Should be traps by DGifGetRecordType. */
			break;
		}
   	 }
  	  while (RecordType != TERMINATE_RECORD_TYPE);

  	  if (DGifCloseFile(GifFileIn, &err) == GIF_ERROR)
		QuitGifError(GifFileIn, GifFileOut, err);
  	  if (EGifCloseFile(GifFileOut, &err) == GIF_ERROR)
		QuitGifError(GifFileIn, GifFileOut, err);
               
	if ((GifFileIn = DGifOpenFileName(TempGifName, &err)) == NULL)
	QuitGifError(GifFileIn, GifFileOut, err);

    
		/* Scan the content of GIF file and dump image(s) to seperate file(s): */
		do {
		sprintf(CrntFileName, "%s%02d.gif", OutFileName, FileNum++);
		if ((GifFileOut = EGifOpenFileName(CrntFileName, TRUE, &err)) == NULL)
		    QuitGifError(GifFileIn, GifFileOut, err);
		FileEmpty = TRUE;

		/* And dump out its exactly same screen information: */
		if (EGifPutScreenDesc(GifFileOut,
		    GifFileIn->SWidth, GifFileIn->SHeight,
		    GifFileIn->SColorResolution, GifFileIn->SBackGroundColor,
		    GifFileIn->SColorMap) == GIF_ERROR)
		    QuitGifError(GifFileIn, GifFileOut, err);

		do {
			if (DGifGetRecordType(GifFileIn, &RecordType) == GIF_ERROR)
			    QuitGifError(GifFileIn, GifFileOut, err);

	   		switch (RecordType) {
			case IMAGE_DESC_RECORD_TYPE:
			FileEmpty = false;
			if (DGifGetImageDesc(GifFileIn) == GIF_ERROR)
			    QuitGifError(GifFileIn, GifFileOut, err);
		 	   /* Put same image descriptor to out file: */
			if (EGifPutImageDesc(GifFileOut,
			    GifFileIn->Image.Left, GifFileIn->Image.Top,
			    GifFileIn->Image.Width, GifFileIn->Image.Height,
			    GifFileIn->Image.Interlace,
			    GifFileIn->Image.ColorMap) == GIF_ERROR)
			    QuitGifError(GifFileIn, GifFileOut, err);

			    /* Now read image itself in decoded form as we dont      */
			    /* really care what is there, and this is much faster.   */
		  	if (DGifGetCode(GifFileIn, &CodeSize, &CodeBlock) == GIF_ERROR
		     	   || EGifPutCode(GifFileOut, CodeSize, CodeBlock) == GIF_ERROR)
			   QuitGifError(GifFileIn, GifFileOut, err);
		    	while (CodeBlock != NULL)
				if (DGifGetCodeNext(GifFileIn, &CodeBlock) == GIF_ERROR ||
			   	    EGifPutCodeNext(GifFileOut, CodeBlock) == GIF_ERROR)
				    QuitGifError(GifFileIn, GifFileOut, err);
		    	break;
			case EXTENSION_RECORD_TYPE:
				FileEmpty = false;
		    		/* Skip any extension blocks in file: */
		    		if (DGifGetExtension(GifFileIn, &ExtCode, &Extension)
				    == GIF_ERROR)
				    QuitGifError(GifFileIn, GifFileOut, err);
		    		if (EGifPutExtension(GifFileOut, ExtCode, Extension[0],
							Extension) == GIF_ERROR)
				    QuitGifError(GifFileIn, GifFileOut, err);

		    		/* No support to more than one extension blocks, discard.*/
		    		while (Extension != NULL)
				if (DGifGetExtensionNext(GifFileIn, &Extension)
			   	 == GIF_ERROR)
			   	 QuitGifError(GifFileIn, GifFileOut, err);
		    		break;
			case TERMINATE_RECORD_TYPE:
		    	break;
			default:	    /* Should be traps by DGifGetRecordType. */
		    	break;
	    	}
		}
		while (RecordType != IMAGE_DESC_RECORD_TYPE &&
	               RecordType != TERMINATE_RECORD_TYPE);

		if (EGifCloseFile(GifFileOut, &err) == GIF_ERROR)
	    	    QuitGifError(GifFileIn, GifFileOut, err);
		if (FileEmpty) {
	  	  /* Might happen on last file - delete it if so: */
		    unlink(CrntFileName);
		}
  	 }
    	while (RecordType != TERMINATE_RECORD_TYPE);

    	if (DGifCloseFile(GifFileIn, &err) == GIF_ERROR)
		QuitGifError(GifFileIn, GifFileOut, err);
   	FileNum=FileNum-1; 
  	}
return FileNum;
}

/******************************************************************************
* Close both input and output file (if open), and exit.			      *
******************************************************************************/
void QuitGifError(GifFileType *GifFileIn, GifFileType *GifFileOut, int ErrorCode)
{
	const char *errstr = NULL;
//   PrintGifError();
	errstr = GifErrorString(ErrorCode);
	printfef("Failed to open file: %d (%s)", ErrorCode, errstr);

    if (GifFileIn != NULL) DGifCloseFile(GifFileIn, &ErrorCode);
    if (GifFileOut != NULL) EGifCloseFile(GifFileOut, &ErrorCode);
//    exit(EXIT_FAILURE);
}


int LoadImage(GifFileType *GifFile, GifRowType **ImageBufferPtr)
{
    int Size, i, j/*, Count*/;
    GifRowType *ImageBuffer;

    /* Allocate the image as vector of column of rows. We cannt allocate     */
    /* the all screen at once, as this broken minded CPU can allocate up to  */
    /* 64k at a time and our image can be bigger than that:		     */
    if ((ImageBuffer = (GifRowType *) malloc(GifFile->Image.Height * sizeof(GifRowType *))) == NULL) {
	printf("Failed to allocate memory required, aborted.");
	return GIF_ERROR;
	}

    Size = GifFile->Image.Width * sizeof(GifPixelType);/* One row size in bytes.*/
    for (i = 0; i < GifFile->Image.Height; i++) {
	/* Allocate the rows: */
	if ((ImageBuffer[i] = (GifRowType) malloc(Size)) == NULL) {
		printf("Failed to allocate memory required, aborted.");
		return GIF_ERROR;
	}
    }

    *ImageBufferPtr = ImageBuffer;

/*    GifQprintf("\n%s: Image %d at (%d, %d) [%dx%d]:     ",
	PROGRAM_NAME, ++ImageNum, GifFile->Image.Left, GifFile->Image.Top,
				 GifFile->Image.Width, GifFile->Image.Height);
*/
    if (GifFile->Image.Interlace) {
	/* Need to perform 4 passes on the images: */
	for (/*Count =*/ i = 0; i < 4; i++)
	    for (j = InterlacedOffset[i]; j < GifFile->Image.Height;
						 j += InterlacedJumps[i]) {
		if (DGifGetLine(GifFile, ImageBuffer[j], GifFile->Image.Width)
		    == GIF_ERROR) return GIF_ERROR;
	    }
    }
    else {
	for (i = 0; i < GifFile->Image.Height; i++) {
	    if (DGifGetLine(GifFile, ImageBuffer[i], GifFile->Image.Width)
		== GIF_ERROR) return GIF_ERROR;
	}
    }

    return GIF_OK;
}

/******************************************************************************
* Routine to dump image out. The given Image buffer should always hold the    *
* image sequencially. Image will be dumped according to IInterlaced flag in   *
* GifFile structure. Once dumped, the memory holding the image is freed.      *
* Return GIF_OK if succesful, GIF_ERROR otherwise.			      *
******************************************************************************/
int DumpImage(GifFileType *GifFile, GifRowType *ImageBuffer)
{
    int i, j/*, Count*/;

    if (GifFile->Image.Interlace) {
	/* Need to perform 4 passes on the images: */
	for (/*Count = GifFile->Image.Height,*/ i = 0; i < 4; i++)
	    for (j = InterlacedOffset[i]; j < GifFile->Image.Height;
						 j += InterlacedJumps[i]) {
		if (EGifPutLine(GifFile, ImageBuffer[j], GifFile->Image.Width)
		    == GIF_ERROR) return GIF_ERROR;
	    }
    }
    else {
	for (/*Count = GifFile->Image.Height,*/ i = 0; i < GifFile->Image.Height; i++) {
//	    GifQprintf("\b\b\b\b%-4d", Count--);
	    if (EGifPutLine(GifFile, ImageBuffer[i], GifFile->Image.Width)
		== GIF_ERROR) return GIF_ERROR;
	}
    }

    /* Free the m emory used for this image: */
    for (i = 0; i < GifFile->Image.Height; i++) free((char *) ImageBuffer[i]);
    free((char *) ImageBuffer);

    return GIF_OK;
}
