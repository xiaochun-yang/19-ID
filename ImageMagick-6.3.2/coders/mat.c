/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                  M   M   AAA   TTTTT  L       AAA   BBBB                    %
%                  MM MM  A   A    T    L      A   A  B   B                   %
%                  M M M  AAAAA    T    L      AAAAA  BBBB                    %
%                  M   M  A   A    T    L      A   A  B   B                   %
%                  M   M  A   A    T    LLLLL  A   A  BBBB                    %
%                                                                             %
%                                                                             %
%                        Read MATLAB Image Format.                            %
%                                                                             %
%                              Software Design                                %
%                              Jaroslav Fojtik                                %
%                                 June 2001                                   %
%                                                                             %
%                                                                             %
%  Permission is hereby granted, free of charge, to any person obtaining a    %
%  copy of this software and associated documentation files ("ImageMagick"),  %
%  to deal in ImageMagick without restriction, including without limitation   %
%  the rights to use, copy, modify, merge, publish, distribute, sublicense,   %
%  and/or sell copies of ImageMagick, and to permit persons to whom the       %
%  ImageMagick is furnished to do so, subject to the following conditions:    %
%                                                                             %
%  The above copyright notice and this permission notice shall be included in %
%  all copies or substantial portions of ImageMagick.                         %
%                                                                             %
%  The software is provided "as is", without warranty of any kind, express or %
%  implied, including but not limited to the warranties of merchantability,   %
%  fitness for a particular purpose and noninfringement.  In no event shall   %
%  ImageMagick Studio be liable for any claim, damages or other liability,    %
%  whether in an action of contract, tort or otherwise, arising from, out of  %
%  or in connection with ImageMagick or the use or other dealings in          %
%  ImageMagick.                                                               %
%                                                                             %
%  Except as contained in this notice, the name of the ImageMagick Studio     %
%  shall not be used in advertising or otherwise to promote the sale, use or  %
%  other dealings in ImageMagick without prior written authorization from the %
%  ImageMagick Studio.                                                        %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
*/

/*
  Include declarations.
*/
#include "magick/studio.h"
#include "magick/blob.h"
#include "magick/blob-private.h"
#include "magick/color-private.h"
#include "magick/exception.h"
#include "magick/exception-private.h"
#include "magick/image.h"
#include "magick/image-private.h"
#include "magick/list.h"
#include "magick/magick.h"
#include "magick/memory_.h"
#include "magick/shear.h"
#include "magick/quantum.h"
#include "magick/static.h"
#include "magick/string_.h"
#include "magick/transform.h"

/*
  define declarations.
*/
#define FLAG_COMPLEX 0x8
#define FLAG_GLOBAL  0x4
#define FLAG_LOGICAL 0x2

/*
  Typdef declarations.
*/
typedef enum
  {
    miINT8 = 1,                 /* 8 bit signed */
    miUINT8,                    /* 8 bit unsigned */
    miINT16,                    /* 16 bit signed */
    miUINT16,                   /* 16 bit unsigned */
    miINT32,                    /* 32 bit signed */
    miUINT32,                   /* 32 bit unsigned */
    miSINGLE,                   /* IEEE 754 single precision float */
    miRESERVE1,
    miDOUBLE,                   /* IEEE 754 double precision float */
    miRESERVE2,
    miRESERVE3,
    miINT64,                    /* 64 bit signed */
    miUINT64,                   /* 64 bit unsigned */     miMATRIX,                   /* MATLAB array */
    miCOMPRESSED,               /* Compressed Data */
    miUTF8,                     /* Unicode UTF-8 Encoded Character Data */
    miUTF16,                    /* Unicode UTF-16 Encoded Character Data */
    miUTF32                     /* Unicode UTF-32 Encoded Character Data */
  } mat5_data_type;

typedef enum
  {
    mxCELL_CLASS=1,             /* cell array */
    mxSTRUCT_CLASS,             /* structure */
    mxOBJECT_CLASS,             /* object */
    mxCHAR_CLASS,               /* character array */
    mxSPARSE_CLASS,             /* sparse array */
    mxDOUBLE_CLASS,             /* double precision array */
    mxSINGLE_CLASS,             /* single precision floating point */
    mxINT8_CLASS,               /* 8 bit signed integer */
    mxUINT8_CLASS,              /* 8 bit unsigned integer */
    mxINT16_CLASS,              /* 16 bit signed integer */
    mxUINT16_CLASS,             /* 16 bit unsigned integer */
    mxINT32_CLASS,              /* 32 bit signed integer */
    mxUINT32_CLASS,             /* 32 bit unsigned integer */
    mxINT64_CLASS,              /* 64 bit signed integer */
    mxUINT64_CLASS,             /* 64 bit unsigned integer */
    mxFUNCTION_CLASS            /* Function handle */
  } arrayclasstype;

typedef struct
{
  char
    identific[124];

  unsigned short
    version;

  char
    endian[2];

  unsigned long
    unknown0,
    ObjectSize,
    unknown1,
    unknown2;

  unsigned char
    StructureFlag,
    StructureClass;

  unsigned short
    unknown5;

  unsigned long
    unknown3,
    unknown4,
    DimFlag,
    SizeX,
    SizeY,
    Flag1,
    NameFlag;
} MATHeader;

/*
  Forward declaration.
*/
static MagickBooleanType
  WriteMATImage(const ImageInfo *,Image *);

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   R e a d M A T L A B i m a g e                                             %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ReadMATImage() reads an MAT X image file and returns it.  It allocates the
%  memory necessary for the new Image structure and returns a pointer to the
%  new image.
%
%  The format of the ReadMATImage method is:
%
%      Image *ReadMATImage(const ImageInfo *image_info,ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image:  Method ReadMATImage returns a pointer to the image after
%      reading. A null image is returned if there is a memory shortage or if
%      the image cannot be read.
%
%    o image_info: Specifies a pointer to a ImageInfo structure.
%
%    o exception: return any errors or warnings in this structure.
%
*/

static void InsertByteRow(Image *image,int channel,unsigned char *p,int y)
{
  IndexPacket
    index;

  register IndexPacket
    *indexes;

  register long
    x;

  register PixelPacket
   *q;

  q=SetImagePixels(image,0,y,image->columns,1);
  if (q == (PixelPacket *) NULL)
    return;
  switch(channel)
  {
    case 0:
    {
      indexes=GetIndexes(image);
      for (x=0; x < (long) image->columns; x++)
      {
        index=(IndexPacket) (*p);
        index=ConstrainColormapIndex(image,index);
        indexes[x]=index;
        *q++=image->colormap[index];
        p++;
      }
      break;
    }
    case 1:
    {
      for (x=0; x < (long) image->columns; x++)
      {
        q->blue=ScaleCharToQuantum(*p);
        p++;
        q++;
      }
      break;
    }
    case 2:
    {
      for (x=0; x < (long) image->columns; x++)
      {
        q->green=ScaleCharToQuantum(*p);
        p++;
        q++;
      }
      break;
    }
    case 3:
    {
      for (x=0; x < (long) image->columns; x++)
      {
        q->red=ScaleCharToQuantum(*p);
        q->opacity=OpaqueOpacity;
        p++;
        q++;
      }
      break;
    }
  }
  (void) SyncImagePixels(image);
  return;
}

static void InsertComplexFloatRow(Image *image,double *p,int y,double MinVal,
  double MaxVal)
{
  MagickRealType
    f;

  register long
    x;

  register PixelPacket
    *q;

  if (MinVal == 0.0)
    MinVal=(-1.0);
  if (MaxVal == 0.0)
    MaxVal=1.0;
  q=SetImagePixels(image,0,y,image->columns,1);
  if (q == (PixelPacket *) NULL)
    return;
  for (x=0; x < (long) image->columns; x++)
  {
    if (*p > 0)
      {
        f=(*p/MaxVal)*(QuantumRange-q->red);
        if ((f+q->red) > QuantumRange)
          q->red=QuantumRange;
        else
          q->red+=(int) f;
        if ((int) f/2.0 > q->green)
          q->green=q->blue=0;
        else
          q->green=q->blue-=(int) (f/2.0);
      }
    if (*p < 0)
      {
        f=(*p/MaxVal)*(QuantumRange-q->blue);
        if ((f+q->blue) > QuantumRange)
          q->blue=QuantumRange;
        else
          q->blue+=(int) f;
        if ((int) f/2.0 > q->green)
          q->green=q->red=0;
        else
          q->green=q->red-=(int) (f/2.0);
     }
    p++;
    q++;
  }
  (void) SyncImagePixels(image);
  return;
}

static void InsertFloatRow(Image *image,double *p,int y,double MinVal,
  double MaxVal)
{
  MagickRealType
    f;

  int x;
  register PixelPacket *q;

  if (MinVal >= MaxVal)
    MaxVal=MinVal+1.0;
  q=SetImagePixels(image,0,y,image->columns,1);
  if (q == (PixelPacket *) NULL)
    return;
  for (x=0; x < (long) image->columns; x++)
  {
    f=(MagickRealType) QuantumRange*(*p-MinVal)/(MaxVal-MinVal);
    q->red=RoundToQuantum(f);
    q->green=q->red;
    q->blue=q->red;
    p++;
    q++;
  }
  (void) SyncImagePixels(image);
  return;
}

static void InsertWordRow(Image *image,int channel,unsigned char *p,int y)
{
  register long
    x;

  register PixelPacket
    *q;

  q=SetImagePixels(image,0,y,image->columns,1);
  if (q == (PixelPacket *) NULL)
    return;
  switch(channel)
  {
    case 0:
    {
      for (x=0; x < (long) image->columns; x++)
      {
        q->red=ScaleShortToQuantum(*(unsigned short *) p);
        q->green=q->red;
        q->blue=q->blue;
        q->opacity=OpaqueOpacity;
        p+=2;
        q++;
      }
      break;
    }
    case 1:
    {
      for (x=0; x < (long) image->columns; x++)
      {
        q->blue=ScaleShortToQuantum(*(unsigned short *) p);
        p+=2;
        q++;
      }
      break;
    }
    case 2:
    {
      for (x=0; x < (long) image->columns; x++)
      {
        q->green=ScaleShortToQuantum(*(unsigned short *) p);
        p+=2;
        q++;
      }
      break;
    }
    case 3:
    {
      for (x=0; x < (long) image->columns; x++)
      {
        q->red=ScaleShortToQuantum(*(unsigned short *) p);
        p+=2;
        q++;
      }
      break;
    }
  }
  (void) SyncImagePixels(image);
  return;
}

static inline size_t MagickMin(const size_t x,const size_t y)
{
  if (x < y)
    return(x);
  return(y);
}

static void ReadBlobWordLSB(Image *image,size_t len,unsigned short *data)
{
  while (len >= 2)
  {
    *data++=ReadBlobLSBShort(image);
    len-=2;
  }
  if (len > 0)
    (void) SeekBlob(image,len,SEEK_CUR);
}

static double ReadBlobDoubleLSB(Image * image)
{
  typedef union
  {
    double d;
    char chars[8];
  } dbl;

  char
    c;

  dbl
    buffer;

  static unsigned long
    lsb_first=1;

  if (ReadBlob(image,8,(unsigned char *) &buffer) == 0)
    return(0.0);
  if (*(char *) &lsb_first == 1)
    return(buffer.d);
  c=buffer.chars[0];
  buffer.chars[0]=buffer.chars[7];
  buffer.chars[7]=c;
  c=buffer.chars[1];
  buffer.chars[1]=buffer.chars[6];
  buffer.chars[6]=c;
  c=buffer.chars[2];
  buffer.chars[2]=buffer.chars[5];
  buffer.chars[5]=c;
  c=buffer.chars[3];
  buffer.chars[3]=buffer.chars[4];
  buffer.chars[4]=c;
  return(buffer.d);
}

static void ReadBlobDoublesLSB(Image *image,size_t len,double *data)
{
  while (len >= 8)
  {
    *data++=ReadBlobDoubleLSB(image);
    len-=sizeof(double);
  }
  if (len > 0)
    (void) SeekBlob(image,len,SEEK_CUR);
}

static Image *ReadMATImage(const ImageInfo *image_info,ExceptionInfo *exception)
{
  Image *image,
    *rotated_image;

  unsigned int status;
  MATHeader mat_header;
  unsigned long size;
  MagickOffsetType filepos;
  unsigned long CellType;
  long i, x;
  long ldblk;
  unsigned char *BImgBuff=NULL;
  double MinVal, MaxVal, *dblrow;
  unsigned long z, Unknown5;

  /*
     Open image file.
   */
  image=AllocateImage(image_info);
  status=OpenBlob(image_info,image,ReadBinaryBlobMode,exception);
  if (status == MagickFalse)
    {
      image=DestroyImageList(image);
      return((Image *) NULL);
    }
  /*
     Read MATLAB image.
   */
  (void) ReadBlob(image,124,(unsigned char *) &mat_header.identific);
  mat_header.version=ReadBlobLSBShort(image);
  (void) ReadBlob(image,2,(unsigned char *) &mat_header.endian);
  mat_header.unknown0=ReadBlobLSBLong(image);
  mat_header.ObjectSize=ReadBlobLSBLong(image);
  mat_header.unknown1=ReadBlobLSBLong(image);
  mat_header.unknown2=ReadBlobLSBLong(image);
  mat_header.StructureClass=ReadBlobByte(image);
  mat_header.StructureFlag=ReadBlobByte(image);
  mat_header.unknown5=ReadBlobShort(image);
  mat_header.unknown3=ReadBlobLSBLong(image);
  mat_header.unknown4=ReadBlobLSBLong(image);
  mat_header.DimFlag=ReadBlobLSBLong(image);
  mat_header.SizeX=ReadBlobLSBLong(image);
  mat_header.SizeY=ReadBlobLSBLong(image);
  if (strncmp(mat_header.identific,"MATLAB",6))
    MATLAB_KO:ThrowReaderException(CorruptImageError,"ImproperImageHeader");
  if (strncmp(mat_header.endian,"IM",2))
    goto MATLAB_KO;
  if (mat_header.unknown0 != 0x0E)
    goto MATLAB_KO;
  switch(mat_header.DimFlag)
  {
    case 8: z=1; break;         /*2D matrix*/
    case 12: z=ReadBlobLSBLong(image); /*3D matrix RGB*/
    {
       Unknown5=ReadBlobLSBLong(image);
       if (z != 3)
         ThrowReaderException(CoderError,
           "MultidimensionalMatricesAreNotSupported");
       break;
    }
    default: ThrowReaderException(CoderError,
      "MultidimensionalMatricesAreNotSupported");
  }
  mat_header.Flag1=ReadBlobLSBShort(image);
  mat_header.NameFlag=ReadBlobLSBShort(image);
  if (mat_header.StructureClass != mxCHAR_CLASS &&
      mat_header.StructureClass != mxDOUBLE_CLASS &&
      mat_header.StructureClass != mxUINT8_CLASS &&
      mat_header.StructureClass != mxUINT16_CLASS)
    goto MATLAB_KO;
  switch (mat_header.NameFlag)
  {
    case 0:
    {
      (void) ReadBlob(image,4,(unsigned char *) &size);
      size=4*(long) ((size+3+1)/4);
      (void) SeekBlob(image,size,SEEK_CUR);
      break;
    }
    case 1:
    case 2:
    case 3:
    case 4:
    {
      (void) ReadBlob(image,4,(unsigned char *) &size);
      break;
    }
    default:
      goto MATLAB_KO;
  }
  CellType=ReadBlobLSBLong(image);    /*Additional object type */
  (void) ReadBlob(image,4,(unsigned char *) &size);     /*data size */
  switch (CellType)
  {
    case 2:
    {
      image->depth=(unsigned long) MagickMin(QuantumDepth,8);         /*Byte type cell */
      ldblk=(long) mat_header.SizeX;
      if ((mat_header.StructureFlag && FLAG_COMPLEX) != 0)
        goto MATLAB_KO;
      break;
    }
    case 4:
    {
      image->depth=(unsigned long) MagickMin(QuantumDepth,16);        /*Word type cell */
      ldblk=(long) (2 * mat_header.SizeX);
      if ((mat_header.StructureFlag && FLAG_COMPLEX) != 0)
        goto MATLAB_KO;
      break;
    }
    case 9:
    {
      image->depth=(unsigned long) MagickMin(QuantumDepth,32);        /*double type cell */
      if (sizeof(double) != 8)
        ThrowReaderException(CoderError, "IncompatibleSizeOfDouble");
      if ((mat_header.StructureFlag && FLAG_COMPLEX) != 0)
        {                         /*complex double type cell */
        }
      ldblk=(long) (8 * mat_header.SizeX);
      break;
    }
    default:
      ThrowReaderException(CoderError, "UnsupportedCellTypeInTheMatrix");
  }
  image->columns=mat_header.SizeX;
  image->rows=mat_header.SizeY;
  image->colors=1l >> 8;
  if (image->columns == 0 || image->rows == 0)
    goto MATLAB_KO;
  if (CellType == 2  && z!=3)
    {
      image->colors=256;
      if (!AllocateImageColormap(image, image->colors))
      {
        NoMemory: ThrowReaderException(ResourceLimitError,
          "MemoryAllocationFailed");
      }
      for (i=0; i < (long) image->colors; i++)
      {
        image->colormap[i].red=ScaleCharToQuantum((unsigned char) i);
        image->colormap[i].green=ScaleCharToQuantum((unsigned char) i);
        image->colormap[i].blue=ScaleCharToQuantum((unsigned char) i);
      }
    }
  BImgBuff=(unsigned char *) AcquireMagickMemory(ldblk);
  if (BImgBuff == NULL)
    goto NoMemory;
  MinVal=0;
  MaxVal=0;
  if (CellType == 9)            /*Find Min and Max Values for floats */
  {
    filepos=TellBlob(image);
    for (i=0; i < (long) mat_header.SizeY; i++)
    {
      ReadBlobDoublesLSB(image, ldblk, (double *) BImgBuff);
      dblrow=(double *) BImgBuff;
      if (i == 0)
      {
        MinVal=MaxVal=*dblrow;
      }
      for (x=0; x < (long) mat_header.SizeX; x++)
      {
        if (MinVal > *dblrow)
          MinVal=*dblrow;
        if (MaxVal < *dblrow)
          MaxVal=*dblrow;
        dblrow++;
      }
    }
    (void) SeekBlob(image, filepos, SEEK_SET);
  }

  /*Main loop for reading all scanlines */
  if(z==1)
  {
    for (i=0; i < (long) mat_header.SizeY; i++)
    {
      switch (CellType)
      {
        case miUINT8:  /* Byte order */
        {
          (void) ReadBlob(image, ldblk, (unsigned char *) BImgBuff);
          InsertByteRow(image,0,BImgBuff,i);
          break;
        }
        case miUINT16:   /* Word order */
        {
          ReadBlobWordLSB(image, ldblk, (unsigned short *) BImgBuff);
          InsertWordRow(image,0,BImgBuff,i);
          break;
        }
        case miDOUBLE:
        {
          ReadBlobDoublesLSB(image, ldblk, (double *) BImgBuff);
          InsertFloatRow(image,(double *) BImgBuff,i,MinVal,MaxVal);
          break;
        }
      }
    }
  }
  else
   while(z>=1)
   {
   for (i=0; i < (long) mat_header.SizeY; i++)
    {
      switch (CellType)
      {
        case miUINT8:  /* Byte order */
        {
          (void) ReadBlob(image,ldblk,(unsigned char *) BImgBuff);
          InsertByteRow(image,z,BImgBuff,i);
          break;
        }
        case miUINT16:   /* Word order */
        {
          ReadBlobWordLSB(image, ldblk, (unsigned short *) BImgBuff);
          InsertWordRow(image,z,BImgBuff,i);
          break;
        }
        case miDOUBLE:
          goto MATLAB_KO;
      }
    }

   z--;
   }

  /*Read complex part of numbers here */
  if ((mat_header.StructureFlag && FLAG_COMPLEX) != 0)
  {
    if (CellType == 9)          /*Find Min and Max Values for complex parts of floats */
    {
      filepos=TellBlob(image);
      for (i=0; i < (long) mat_header.SizeY; i++)
      {
        ReadBlobDoublesLSB(image, ldblk, (double *) BImgBuff);
        dblrow=(double *) BImgBuff;
        if (i == 0)
        {
          MinVal=MaxVal=*dblrow;
        }
        for (x=0; x < (long) mat_header.SizeX; x++)
        {
          if (MinVal > *dblrow)
            MinVal=*dblrow;
          if (MaxVal < *dblrow)
            MaxVal=*dblrow;
          dblrow++;
        }
      }
      (void) SeekBlob(image, filepos, SEEK_SET);

      for (i=0; i < (long) mat_header.SizeY; i++)
      {
        ReadBlobDoublesLSB(image, ldblk, (double *) BImgBuff);
        InsertComplexFloatRow(image,(double *) BImgBuff,i,MinVal,MaxVal);
      }
    }
  }
  if (BImgBuff != NULL)
    BImgBuff=(unsigned char *) RelinquishMagickMemory(BImgBuff);
  CloseBlob(image);
  /*  Rotate image. */
  rotated_image=RotateImage(image, 90.0, exception);
  if (rotated_image != (Image *) NULL)
  {
    DestroyImage(image);
    image=FlopImage(rotated_image, exception);
    if (image == NULL)
      image=rotated_image;    /*Obtain something if flop operation fails */
    else
      DestroyImage(rotated_image);
  }
  return (image);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   R e g i s t e r M A T I m a g e                                           %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Method RegisterMATImage adds attributes for the MAT image format to
%  the list of supported formats.  The attributes include the image format
%  tag, a method to read and/or write the format, whether the format
%  supports the saving of more than one frame to the same file or blob,
%  whether the format supports native in-memory I/O, and a brief
%  description of the format.
%
%  The format of the RegisterMATImage method is:
%
%      RegisterMATImage(void)
%
*/
ModuleExport void RegisterMATImage(void)
{
  MagickInfo
    *entry;

  entry=SetMagickInfo("MAT");
  entry->decoder=(DecoderHandler *) ReadMATImage;
  entry->encoder=(EncoderHandler *) WriteMATImage;
  entry->seekable_stream=MagickTrue;
  entry->description=AcquireString("MATLAB image format");
  entry->module=AcquireString("MAT");
  (void) RegisterMagickInfo(entry);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   U n r e g i s t e r M A T I m a g e                                       %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Method UnregisterMATImage removes format registrations made by the
%  MAT module from the list of supported formats.
%
%  The format of the UnregisterMATImage method is:
%
%      UnregisterMATImage(void)
%
*/
ModuleExport void UnregisterMATImage(void)
{
  (void) UnregisterMagickInfo("MAT");
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   W r i t e M A T I m a g e                                                 %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  WriteMATImage() writes an image to a file in MAT X image format.
%
%  The format of the WriteMATImage method is:
%
%      MagickBooleanType WriteMATImage(const ImageInfo *image_info,Image *image)
%
%  A description of each parameter follows.
%
%    o image_info: The image info.
%
%    o image:  The image.
%
*/
static MagickBooleanType WriteMATImage(const ImageInfo *image_info,Image *image)
{
  char
    timestamp[MaxTextExtent];

  long
    y;

  MagickBooleanType
    status;

  MATHeader
    mat_header;

  register long
    x;

  register const PixelPacket
    *p;

  size_t
    pad,
    length;

  time_t
    seconds;

  /*
    Open output image file.
  */
  assert(image_info != (const ImageInfo *) NULL);
  assert(image_info->signature == MagickSignature);
  assert(image != (Image *) NULL);
  assert(image->signature == MagickSignature);
  if (image->debug != MagickFalse)
    (void) LogMagickEvent(TraceEvent,GetMagickModule(),"%s",image->filename);
  status=OpenBlob(image_info,image,WriteBinaryBlobMode,&image->exception);
  if (status == MagickFalse)
    return(status);
  seconds=time((time_t *) NULL);
  (void) FormatMagickTime(seconds,MaxTextExtent,timestamp);
  ResetMagickMemory(&mat_header,0,sizeof(MATHeader));
  FormatMagickString(mat_header.identific,MaxTextExtent,
    "MATLAB 5.0 MAT-file, Created on: %s",timestamp);
  (void) WriteBlob(image,sizeof(mat_header.identific),(unsigned char *)
    mat_header.identific);
  (void) WriteBlob(image,3,(unsigned char *) "\1IM");
  (void) WriteBlobByte(image,0x0e);
  (void) WriteBlobByte(image,0x00);
  (void) WriteBlobByte(image,0x00);
  (void) WriteBlobByte(image,0x00);
  length=3*image->rows*image->columns;
  pad=((unsigned char) (length-1) & 0x7) ^ 0x7;
  WriteBlobLSBLong(image,(unsigned long) (length+56L+pad));
  WriteBlobLSBLong(image,0x06);
  WriteBlobLSBLong(image,0x08);
  WriteBlobLSBLong(image,0x06);
  WriteBlobLSBLong(image,0);
  WriteBlobLSBLong(image,0x05);
  WriteBlobLSBLong(image,0x0C);
  WriteBlobLSBLong(image,image->rows);
  WriteBlobLSBLong(image,image->columns);
  WriteBlobLSBLong(image,3);
  WriteBlobLSBLong(image,0);
  WriteBlobLSBShort(image,1);
  WriteBlobLSBShort(image,1);
  WriteBlobLSBLong(image,'M');
  WriteBlobLSBLong(image,0x02);
  WriteBlobLSBLong(image,(unsigned long) length);
  for (y=0; y < (long) image->columns; y++)
  {
    p=AcquireImagePixels(image,y-1,0,1,image->rows-1,&image->exception);    
    for (x=0; x < (long) image->rows; x++)
    {
      WriteBlobByte(image,ScaleQuantumToChar(p->red));
      p++;
    }
  }
  for (y=0; y < (long) image->columns; y++)
  {
    p=AcquireImagePixels(image,y-1,0,1,image->rows-1,&image->exception);
    for (x=0; x < (long) image->rows; x++)
    {
      WriteBlobByte(image,ScaleQuantumToChar(p->green));
      p++;
    }
  }
  for (y=0; y < (long) image->columns; y++)
  {
    p=AcquireImagePixels(image,y-1,0,1,image->rows-1,&image->exception);
    for (x=0; x < (long) image->rows; x++)
    {
      WriteBlobByte(image,ScaleQuantumToChar(p->blue));
      p++;
    }
  }
  while (pad-- > 0)
    WriteBlobByte(image,0x00);
  CloseBlob(image);
  return(MagickTrue);
}
