// *******************
// imgCentering.h
// *******************

#ifndef DHS_CENTERING_H
#define DHS_CENTERING_H

#include "stdio.h"
#include "strings.h"
#include "stdlib.h"
//#include "iostream.h"
#include "xos_socket.h"
#include "dhs_Camera.h"

#include "dvmbasic.h"
#include "dvmjpeg.h"
#include "dvmpnm.h"
#include "dvmcolor.h"
#include "dvmvision.h"

typedef struct ImageList
{
   BitImage* img;
   int height;
   int Index;
   struct ImageList* next;
} ImageList;

typedef struct BoundingBox
{
    int UpperLeftX;
    int UpperLeftY;
    int LowRightX;
    int LowRightY; 
} BoundingBox;

int 
DumpImageList(ImageList* picHead, 
						char* dirName);

void 
freeImageList(ImageList *head);

xos_result_t 
getImageBuffer(CameraInfo* camera_in, 
					BitImage** imgBuf);

xos_result_t 
handle_getLoopTip(CameraInfo* camera_in, 
						const char* operationHandle, 
						char* operationResult, 
						int ifaskPinPosFlag);

xos_result_t 
handle_addImageToList(CameraInfo* camera_in, 
							 int imgIndex,
							 ImageList** ImgLst, 
							 const char* operationHandle,
							 char* operationResult);

xos_result_t 
handle_findBoundingBox(ImageList** ImgLst, 
							  const char* operationHandle, 
							  const char* MethodFlag, 
							  char* operationResult);

xos_result_t 
handle_getPinDiameters(CameraInfo* camera_in, 
							  const char* operationHandle, 
							  char* operationResult, 
							  int length, 
							  int number);


int g_countObjs();
void g_dumpObjs();

#endif
