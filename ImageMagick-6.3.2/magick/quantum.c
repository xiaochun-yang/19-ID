/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%                QQQ   U   U   AAA   N   N  TTTTT  U   U  M   M               %
%               Q   Q  U   U  A   A  NN  N    T    U   U  MM MM               %
%               Q   Q  U   U  AAAAA  N N N    T    U   U  M M M               %
%               Q  QQ  U   U  A   A  N  NN    T    U   U  M   M               %
%                QQQQ   UUU   A   A  N   N    T     UUU   M   M               %
%                                                                             %
%                   Methods to Import/Export Quantum Pixels                   %
%                                                                             %
%                             Software Design                                 %
%                               John Cristy                                   %
%                               October 1998                                  %
%                                                                             %
%                                                                             %
%  Copyright 1999-2006 ImageMagick Studio LLC, a non-profit organization      %
%  dedicated to making software imaging solutions freely available.           %
%                                                                             %
%  You may not use this file except in compliance with the License.  You may  %
%  obtain a copy of the License at                                            %
%                                                                             %
%    http://www.imagemagick.org/script/license.php                            %
%                                                                             %
%  Unless required by applicable law or agreed to in writing, software        %
%  distributed under the License is distributed on an "AS IS" BASIS,          %
%  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   %
%  See the License for the specific language governing permissions and        %
%  limitations under the License.                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
*/

/*
  Include declarations.
*/
#include "magick/studio.h"
#include "magick/property.h"
#include "magick/blob.h"
#include "magick/blob-private.h"
#include "magick/color-private.h"
#include "magick/exception.h"
#include "magick/exception-private.h"
#include "magick/cache.h"
#include "magick/constitute.h"
#include "magick/delegate.h"
#include "magick/geometry.h"
#include "magick/list.h"
#include "magick/magick.h"
#include "magick/memory_.h"
#include "magick/monitor.h"
#include "magick/option.h"
#include "magick/pixel.h"
#include "magick/pixel-private.h"
#include "magick/quantum.h"
#include "magick/resource_.h"
#include "magick/semaphore.h"
#include "magick/statistic.h"
#include "magick/stream.h"
#include "magick/string_.h"
#include "magick/utility.h"

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   A c q u i r e Q u a n t u m I n f o                                       %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  AcquireQuantumInfo() allocates the QuantumInfo structure.
%
%  The format of the AcquireQuantumInfo method is:
%
%      QuantumInfo *AcquireQuantumInfo(const ImageInfo *image_info)
%
%  A description of each parameter follows:
%
%    o image_info: The image info.
%
*/
MagickExport QuantumInfo *AcquireQuantumInfo(const ImageInfo *image_info)
{
  QuantumInfo
    *quantum_info;

  assert(image_info != (ImageInfo *) NULL);
  assert(image_info->signature == MagickSignature);
  quantum_info=(QuantumInfo *) AcquireMagickMemory(sizeof(*quantum_info));
  if (quantum_info == (QuantumInfo *) NULL)
    {
      char
        *message;

      message=GetExceptionMessage(errno);
      ThrowMagickFatalException(ResourceLimitFatalError,
        "MemoryAllocationFailed",message);
      message=(char *) RelinquishMagickMemory(message);
    }
  (void) ResetMagickMemory(quantum_info,0,sizeof(*quantum_info));
  GetQuantumInfo(image_info,quantum_info);
  return(quantum_info);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   D e s t r o y Q u a n t u m I n f o                                       %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  DestroyQuantumInfo() deallocates memory associated with the QuantumInfo
%  structure.
%
%  The format of the DestroyQuantumInfo method is:
%
%      QuantumInfo *DestroyQuantumInfo(QuantumInfo *quantum_info)
%
%  A description of each parameter follows:
%
%    o quantum_info: The quantum_info info.
%
*/
MagickExport QuantumInfo *DestroyQuantumInfo(QuantumInfo *quantum_info)
{
  assert(quantum_info != (QuantumInfo *) NULL);
  assert(quantum_info->signature == MagickSignature);
  AcquireSemaphoreInfo(&quantum_info->semaphore);
  quantum_info->signature=(~MagickSignature);
  RelinquishSemaphoreInfo(quantum_info->semaphore);
  quantum_info->semaphore=DestroySemaphoreInfo(quantum_info->semaphore);
  quantum_info=(QuantumInfo *) RelinquishMagickMemory(quantum_info);
  return(quantum_info);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   E x p o r t Q u a n t u m P i x e l s                                     %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ExportQuantumPixels() transfers one or more pixel components from a user
%  supplied buffer into the image pixel cache of an image.  The pixels are
%  expected in network byte order.  It returns MagickTrue if the pixels are
%  successfully transferred, otherwise MagickFalse.
%
%  The format of the ExportQuantumPixels method is:
%
%      MagickBooleanType ExportQuantumPixels(Image *image,
%        const QuantumInfo *quantum_info,const QuantumType quantum_type,
%        const unsigned char *pixels)
%
%  A description of each parameter follows:
%
%    o image: The image.
%
%    o quantum_info: The quantum info.
%
%    o quantum_type: Declare which pixel components to transfer (red, green,
%      blue, opacity, RGB, or RGBA).
%
%    o pixels:  The pixel components are transferred from this buffer.
%
%
*/

static inline IndexPacket PushColormapIndex(Image *image,
  const unsigned long index)
{
  assert(image != (Image *) NULL);
  assert(image->signature == MagickSignature);
  if (index < image->colors)
    return((IndexPacket) index);
  (void) ThrowMagickException(&image->exception,GetMagickModule(),
    CorruptImageError,"InvalidColormapIndex","`%s'",image->filename);
  return(0);
}

static inline unsigned long PushPixelQuantum(const unsigned char *pixels,
  const unsigned long depth)
{
  register long
    i;

  register unsigned long
    quantum_bits,
    quantum;

  static const unsigned char
    *p;

  static unsigned long
    data_bits;

  if (depth == 0UL)
    {
      p=pixels;
      data_bits=8UL;
    }
  quantum=0UL;
  for (i=(long) depth; i > 0L; )
  {
    quantum_bits=(unsigned long) i;
    if (quantum_bits > data_bits)
      quantum_bits=data_bits;
    i-=quantum_bits;
    data_bits-=quantum_bits;
    quantum=(quantum << quantum_bits) |
      ((*p >> data_bits) &~ ((~0UL) << quantum_bits));
    if (data_bits == 0UL)
      {
        p++;
        data_bits=8UL;
      }
  }
  return(quantum);
}

MagickExport MagickBooleanType ExportQuantumPixels(Image *image,
  const QuantumInfo *quantum_info,const QuantumType quantum_type,
  const unsigned char *pixels)
{
#define PushCharPixel(p,pixel) \
{ \
  pixel=(unsigned char) (*(p)); \
  (p)++; \
}
#define PushDoublePixel(p,pixel) \
{ \
  pixel=(*((double *) p)); \
  pixel-=quantum_info->minimum; \
  pixel*=quantum_info->scale; \
  p+=sizeof(double); \
}
#define PushFloatPixel(p,pixel) \
{ \
  pixel=(*((float *) p)); \
  pixel-=quantum_info->minimum; \
  pixel*=quantum_info->scale; \
  p+=sizeof(float); \
}
#define PushLongPixel(p,pixel) \
{ \
  if (image->endian != LSBEndian) \
    { \
      pixel=(unsigned long) (*(p) << 24); \
      pixel|=(unsigned long) (*((p)+1) << 16); \
      pixel|=(unsigned long) (*((p)+2) << 8); \
      pixel|=(unsigned long) *((p)+3); \
    } \
  else \
    { \
      pixel=(unsigned long) *(p); \
      pixel|=(unsigned long) (*((p)+1) << 8); \
      pixel|=(unsigned long) (*((p)+2) << 16); \
      pixel|=(unsigned long) (*((p)+3) << 24); \
    } \
  (p)+=4; \
}
#define PushShortPixel(p,pixel) \
{ \
  if (image->endian != LSBEndian) \
    { \
      pixel=(unsigned short) (*(p) << 8); \
      pixel|=(unsigned short) *((p)+1); \
    } \
  else \
    { \
      pixel=(unsigned short) *(p); \
      pixel|=(unsigned short) (*((p)+1) << 8); \
    } \
  (p)+=2; \
}

  long
    bit;

  MagickSizeType
    number_pixels;

  register const unsigned char
    *p;

  register IndexPacket
    *indexes;

  register long
    x;

  register PixelPacket
    *q;

  assert(image != (Image *) NULL);
  assert(image->signature == MagickSignature);
  if (image->debug != MagickFalse)
    (void) LogMagickEvent(TraceEvent,GetMagickModule(),"%s",image->filename);
  assert(quantum_info != (QuantumInfo *) NULL);
  assert(quantum_info->signature == MagickSignature);
  assert(pixels != (const unsigned char *) NULL);
  number_pixels=GetPixelCacheArea(image);
  x=0;
  p=pixels;
  q=GetPixels(image);
  indexes=GetIndexes(image);
  switch (quantum_type)
  {
    case IndexQuantum:
    {
      if (image->storage_class != PseudoClass)
        ThrowBinaryException(ImageError,"ColormappedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 1:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-7); x+=8)
          {
            for (bit=0; bit < 8; bit++)
            {
              pixel=(unsigned char)
                (((*p) & (1 << (7-bit))) != 0 ? 0x01 : 0x00);
              indexes[x+bit]=PushColormapIndex(image,pixel);
              *q=image->colormap[indexes[x+bit]];
              q++;
            }
            p++;
          }
          for (bit=0; bit < (long) (number_pixels % 8); bit++)
          {
            pixel=(unsigned char) (((*p) & (1 << (7-bit))) != 0 ? 0x01 : 0x00);
            indexes[x+bit]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x+bit]];
            q++;
          }
          break;
        }
        case 2:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-3); x+=4)
          {
            pixel=(unsigned char) ((*p >> 6) & 0x03);
            indexes[x]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x]];
            q++;
            pixel=(unsigned char) ((*p >> 4) & 0x03);
            indexes[x+1]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x+1]];
            q++;
            pixel=(unsigned char) ((*p >> 2) & 0x03);
            indexes[x+2]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x+2]];
            q++;
            pixel=(unsigned char) ((*p) & 0x03);
            indexes[x+3]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x+3]];
            p++;
            q++;
          }
          for (bit=0; bit < (long) (number_pixels % 4); bit++)
          {
            pixel=(unsigned char) ((*p >> (2*(3-bit))) & 0x03);
            indexes[x+bit]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x+bit]];
            q++;
          }
          break;
        }
        case 4:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-1); x+=2)
          {
            pixel=(unsigned char) ((*p >> 4) & 0xf);
            indexes[x]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x]];
            q++;
            pixel=(unsigned char) ((*p) & 0xf);
            indexes[x+1]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x+1]];
            p++;
            q++;
          }
          for (bit=0; bit < (long) (number_pixels % 2); bit++)
          {
            pixel=(unsigned char) ((*p++ >> 4) & 0xf);
            indexes[x+bit]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x+bit]];
            q++;
          }
          break;
        }
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            indexes[x]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x]];
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 12:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) (number_pixels-1); x+=2)
          {
            pixel=(unsigned short) ((((*(p+1) >> 4) & 0xf) << 8) | (*p));
            indexes[x]=PushColormapIndex(image,ScaleAnyToQuantum(pixel,4095));
            *q=image->colormap[indexes[x]];
            q++;
            pixel=(unsigned short) (((*(p+1) & 0xf) << 8) | (*(p+2)));
            indexes[x+1]=PushColormapIndex(image,ScaleAnyToQuantum(pixel,4095));
            *q=image->colormap[indexes[x+1]];
            p+=3;
            q++;
          }
          for (bit=0; bit < (long) (number_pixels % 2); bit++)
          {
            pixel=(unsigned short) (((*(p+1) >> 4) & 0xf) | (*p));
            indexes[x+bit]=PushColormapIndex(image,ScaleAnyToQuantum(pixel,
              4095));
            *q=image->colormap[indexes[x+bit]];
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            indexes[x]=PushColormapIndex(image,ScaleShortToQuantum(pixel));
            *q=image->colormap[indexes[x]];
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                indexes[x]=PushColormapIndex(image,RoundToQuantum(pixel));
                *q=image->colormap[indexes[x]];
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            indexes[x]=PushColormapIndex(image,ScaleLongToQuantum(pixel));
            *q=image->colormap[indexes[x]];
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                indexes[x]=PushColormapIndex(image,RoundToQuantum(pixel));
                *q=image->colormap[indexes[x]];
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            indexes[x]=PushColormapIndex(image,ScaleAnyToQuantum(pixel,
              (1UL << image->depth)-1));
            *q=image->colormap[indexes[x]];
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
      }
      break;
    }
    case IndexAlphaQuantum:
    {
      if (image->storage_class != PseudoClass)
        ThrowBinaryException(ImageError,"ColormappedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 1:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-3); x+=4)
          {
            for (bit=0; bit < 8; bit+=2)
            {
              pixel=(unsigned char)
                (((*p) & (1 << (7-bit))) != 0 ? 0x00 : 0x01);
              indexes[x+bit/2]=(IndexPacket) (pixel == 0 ? 0 : 1);
              q->red=pixel == 0 ? 0 : QuantumRange;
              q->green=q->red;
              q->blue=q->red;
              q->opacity=((*p) & (1UL << (unsigned char) (6-bit))) == 0 ?
                TransparentOpacity : OpaqueOpacity;
              q++;
            }
            p++;
          }
          for (bit=0; bit < (long) (number_pixels % 4); bit+=2)
          {
            pixel=(unsigned char) (((*p) & (1 << (7-bit))) != 0 ? 0x00 : 0x01);
            indexes[x+bit/2]=(IndexPacket) (pixel == 0 ? 0 : 1);
            q->red=pixel == 0 ? 0 : QuantumRange;
            q->green=q->red;
            q->blue=q->red;
            q->opacity=((*p) & (1UL << (unsigned char) (6-bit))) == 0 ?
              TransparentOpacity : OpaqueOpacity;
            q++;
          }
          break;
        }
        case 2:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-1); x+=2)
          {
            pixel=(unsigned char) ((*p >> 6) & 0x03);
            indexes[x]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x]];
            q->opacity=(Quantum) (QuantumRange*((int) (*p >> 4) & 0x03)/4);
            q++;
            pixel=(unsigned char) ((*p >> 2) & 0x03);
            indexes[x+2]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x+2]];
            q->opacity=(Quantum) (QuantumRange*((int) (*p) & 0x03)/4);
            p++;
            q++;
          }
          break;
        }
        case 4:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned char) ((*p >> 4) & 0xf);
            indexes[x]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x]];
            q->opacity=(Quantum) (QuantumRange-
              (QuantumRange*((int) (*p) & 0xf)/15));
            p++;
            q++;
          }
          break;
        }
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            indexes[x]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x]];
            PushCharPixel(p,pixel);
            q->opacity=(Quantum) (QuantumRange-ScaleCharToQuantum(pixel));
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 12:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned short) ((((*(p+1) >> 4) & 0xf) << 8) | (*p));
            indexes[x]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x]];
            pixel=(unsigned short) (((*(p+1) & 0xf) << 8) | (*(p+2)));
            q->opacity=(Quantum) ((unsigned long) QuantumRange*pixel/1024);
            p+=3;
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            indexes[x]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x]];
            PushShortPixel(p,pixel);
            q->opacity=QuantumRange-ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                indexes[x]=PushColormapIndex(image,RoundToQuantum(pixel));
                *q=image->colormap[indexes[x]];
                PushFloatPixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            indexes[x]=PushColormapIndex(image,pixel);
            *q=image->colormap[indexes[x]];
            PushLongPixel(p,pixel);
            q->opacity=QuantumRange-ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                indexes[x]=PushColormapIndex(image,RoundToQuantum(pixel));
                *q=image->colormap[indexes[x]];
                PushDoublePixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            indexes[x]=PushColormapIndex(image,ScaleAnyToQuantum(pixel,
              (1UL << image->depth)-1));
            *q=image->colormap[indexes[x]];
            pixel=PushPixelQuantum(p,image->depth);
            q->opacity=QuantumRange-ScaleAnyToQuantum(pixel,
              (1UL << image->depth)-1);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
      }
      break;
    }
    case GrayQuantum:
    case GrayPadQuantum:
    {
      switch (image->depth)
      {
        case 1:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-7); x+=8)
          {
            for (bit=0; bit < 8; bit++)
            {
              pixel=(unsigned char)
                (((*p) & (1 << (7-bit))) != 0 ? 0 : 255);
              q->red=pixel == 0 ? 0 : QuantumRange;
              q->green=q->red;
              q->blue=q->red;
              q++;
            }
            p++;
          }
          for (bit=0; bit < (long) (number_pixels % 8); bit++)
          {
            pixel=(unsigned char)
              (((*p) & (1 << (7-bit))) != 0 ? 0 : 255);
            q->red=pixel == 0 ? 0 : QuantumRange;
            q->green=q->red;
            q->blue=q->red;
            q++;
          }
          break;
        }
        case 2:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-3); x+=4)
          {
            pixel=(unsigned char) ((*p >> 6) & 0x03);
            q->red=ScaleAnyToQuantum(pixel,1UL);
            q->green=q->red;
            q->blue=q->red;
            q++;
            pixel=(unsigned char) ((*p >> 4) & 0x03);
            q->red=ScaleAnyToQuantum(pixel,1UL);
            q->green=q->red;
            q->blue=q->red;
            q++;
            pixel=(unsigned char) ((*p >> 2) & 0x03);
            q->red=ScaleAnyToQuantum(pixel,1UL);
            q->green=q->red;
            q->blue=q->red;
            q++;
            pixel=(unsigned char) ((*p) & 0x03);
            q->red=ScaleAnyToQuantum(pixel,1UL);
            q->green=q->red;
            q->blue=q->red;
            p++;
            q++;
          }
          for (bit=0; bit < (long) (number_pixels % 4); bit++)
          {
            pixel=(unsigned char) ((*p >> (2*(3-bit))) & 0x03);
            q->red=ScaleAnyToQuantum(pixel,1UL);
            q->green=q->red;
            q->blue=q->red;
            q++;
          }
          break;
        }
        case 4:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-1); x+=2)
          {
            pixel=(unsigned char) ((*p >> 4) & 0xf);
            q->red=ScaleAnyToQuantum(pixel,15UL);
            q->green=q->red;
            q->blue=q->red;
            q++;
            pixel=(unsigned char) ((*p) & 0xf);
            q->red=ScaleAnyToQuantum(pixel,15UL);
            q->green=q->red;
            q->blue=q->red;
            p++;
            q++;
          }
          for (bit=0; bit < (long) (number_pixels % 2); bit++)
          {
            pixel=(unsigned char) ((*p++ >> 4) & 0xf);
            q->red=ScaleAnyToQuantum(pixel,15UL);
            q->green=q->red;
            q->blue=q->red;
            q++;
          }
          break;
        }
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->red=ScaleCharToQuantum(pixel);
            q->green=q->red;
            q->blue=q->red;
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 10:
        {
          register unsigned short
            pixel;

          if (quantum_type == GrayPadQuantum)
            {
              register unsigned long
                pixel;

              for (x=0; x < (long) (number_pixels+2)/3; x++)
              {
                PushLongPixel(p,pixel);
                q->red=ScaleAnyToQuantum((pixel >> 2) & 0x3ff,
                  (1UL << image->depth)-1);
                q->green=q->red;
                q->blue=q->red;
                q++;
                q->red=ScaleAnyToQuantum((pixel >> 12) & 0x3ff,
                  (1UL << image->depth)-1);
                q->green=q->red;
                q->blue=q->red;
                q++;
                q->red=ScaleAnyToQuantum((pixel >> 22) & 0x3ff,
                  (1UL << image->depth)-1);
                q->green=q->red;
                q->blue=q->red;
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned short) PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q->green=q->red;
            q->blue=q->red;
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 12:
        {
          register unsigned short
            pixel;

          if (quantum_type == GrayPadQuantum)
            {
              for (x=0; x < (long) (number_pixels-1); x+=2)
              {
                PushShortPixel(p,pixel);
                q->red=ScaleAnyToQuantum((unsigned long) (pixel >> 4),4095UL);
                q->green=q->red;
                q->blue=q->red;
                q++;
                PushShortPixel(p,pixel);
                q->red=ScaleAnyToQuantum((unsigned long) (pixel >> 4),4095UL);
                q->green=q->red;
                q->blue=q->red;
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              for (bit=0; bit < (long) (number_pixels % 2); bit++)
              {
                PushShortPixel(p,pixel);
                q->red=ScaleAnyToQuantum((unsigned long) (pixel >> 4),4095UL);
                q->green=q->red;
                q->blue=q->red;
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned short) PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q->green=q->red;
            q->blue=q->red;
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;
          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->red=ScaleShortToQuantum(pixel);
            q->green=q->red;
            q->blue=q->red;
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                q->green=q->red;
                q->blue=q->red;
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->red=ScaleLongToQuantum(pixel);
            q->green=q->red;
            q->blue=q->red;
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                q->green=q->red;
                q->blue=q->red;
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q->green=q->red;
            q->blue=q->red;
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
      }
      break;
    }
    case GrayAlphaQuantum:
    {
      switch (image->depth)
      {
        case 1:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-3); x+=4)
          {
            for (bit=0; bit < 8; bit+=2)
            {
              pixel=(unsigned char)
                (((*p) & (1 << (7-bit))) != 0 ? 0x00 : 0x01);
              q->red=pixel == 0 ? 0 : QuantumRange;
              q->green=q->red;
              q->blue=q->red;
              q->opacity=((*p) & (1UL << (unsigned char) (6-bit))) == 0 ?
                TransparentOpacity : OpaqueOpacity;
              q++;
            }
            p++;
          }
          for (bit=0; bit < (long) (number_pixels % 4); bit+=2)
          {
            pixel=(unsigned char) (((*p) & (1 << (7-bit))) != 0 ? 0x00 : 0x01);
            q->red=pixel == 0 ? 0 : QuantumRange;
            q->green=q->red;
            q->blue=q->red;
            q->opacity=((*p) & (1UL << (unsigned char) (6-bit))) == 0 ?
              TransparentOpacity : OpaqueOpacity;
            q++;
          }
          break;
        }
        case 2:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-1); x+=2)
          {
            pixel=(unsigned char) ((*p >> 6) & 0x03);
            q->red=ScaleAnyToQuantum(pixel,1UL);
            q->green=q->red;
            q->blue=q->red;
            q->opacity=(Quantum) (QuantumRange*((int) (*p >> 4) & 0x03)/4);
            q++;
            pixel=(unsigned char) ((*p >> 2) & 0x03);
            q->red=ScaleAnyToQuantum(pixel,1UL);
            q->green=q->red;
            q->blue=q->red;
            q->opacity=(Quantum) (QuantumRange*((int) (*p) & 0x03)/4);
            p++;
            q++;
          }
          break;
        }
        case 4:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned char) ((*p >> 4) & 0xf);
            q->red=ScaleAnyToQuantum(pixel,15UL);
            q->green=q->red;
            q->blue=q->red;
            q->opacity=(Quantum) (QuantumRange-(QuantumRange*((*p) & 0xf)/15));
            p++;
            q++;
          }
          break;
        }
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->red=ScaleCharToQuantum(pixel);
            q->green=q->red;
            q->blue=q->red;
            PushCharPixel(p,pixel);
            q->opacity=(Quantum) (QuantumRange-ScaleCharToQuantum(pixel));
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 10:
        {
          register unsigned short
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned short) PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q->green=q->red;
            q->blue=q->red;
            pixel=(unsigned short) PushPixelQuantum(p,image->depth);
            q->opacity=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 12:
        {
          register unsigned short
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned short) PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q->green=q->red;
            q->blue=q->red;
            pixel=(unsigned short) PushPixelQuantum(p,image->depth);
            q->opacity=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->red=ScaleShortToQuantum(pixel);
            q->green=q->red;
            q->blue=q->red;
            PushShortPixel(p,pixel);
            q->opacity=QuantumRange-ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                q->green=q->red;
                q->blue=q->red;
                PushFloatPixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->red=ScaleLongToQuantum(pixel);
            q->green=q->red;
            q->blue=q->red;
            PushLongPixel(p,pixel);
            q->opacity=QuantumRange-ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                q->green=q->red;
                q->blue=q->red;
                PushDoublePixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q->green=q->red;
            q->blue=q->red;
            pixel=PushPixelQuantum(p,image->depth);
            q->opacity=QuantumRange-
              ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
      }
      break;
    }
    case RedQuantum:
    case CyanQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->red=ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->red=ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->red=ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
      }
      break;
    }
    case GreenQuantum:
    case MagentaQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->green=ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->green=ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->green=ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->green=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
      }
      break;
    }
    case BlueQuantum:
    case YellowQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->blue=ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->blue=ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->blue=ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->blue=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
      }
      break;
    }
    case AlphaQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->opacity=QuantumRange-ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->opacity=QuantumRange-ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->opacity=QuantumRange-ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->opacity=QuantumRange-ScaleAnyToQuantum(pixel,
              (1UL << image->depth)-1);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
      }
      break;
    }
    case BlackQuantum:
    {
      if (image->colorspace != CMYKColorspace)
        ThrowBinaryException(ImageError,"ColorSeparatedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            indexes[x]=ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            indexes[x]=ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                indexes[x]=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            indexes[x]=ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                indexes[x]=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            indexes[x]=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
      }
      break;
    }
    case RGBQuantum:
    case RGBPadQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->red=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->green=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->blue=ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 10:
        {
          register unsigned long
            pixel;

          if (quantum_type == RGBPadQuantum)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                PushLongPixel(p,pixel);
                q->red=ScaleShortToQuantum((unsigned short)
                  (((pixel >> 22) & 0x3ff) << 6));
                q->green=ScaleShortToQuantum((unsigned short)
                  (((pixel >> 12) & 0x3ff) << 6));
                q->blue=ScaleShortToQuantum((unsigned short)
                  (((pixel >> 2) & 0x3ff) << 6));
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->red=ScaleShortToQuantum((unsigned short) (pixel << 6));
            pixel=PushPixelQuantum(p,image->depth);
            q->green=ScaleShortToQuantum((unsigned short) (pixel << 6));
            pixel=PushPixelQuantum(p,image->depth);
            q->blue=ScaleShortToQuantum((unsigned short) (pixel << 6));
            q++;
          }
          break;
        }
        case 12:
        {
          register unsigned short
            pixel;

          if (quantum_type == RGBPadQuantum)
            {
              for (x=0; x < (long) (3*number_pixels-1); x+=2)
              {
                PushShortPixel(p,pixel);
                switch (x % 3)
                {
                  default:
                  case 0:
                  {
                    q->red=ScaleShortToQuantum((unsigned short) (pixel &~ 0xf));
                    break;
                  }
                  case 1:
                  {
                    q->green=ScaleShortToQuantum((unsigned short)
                      (pixel &~ 0xf));
                    break;
                  }
                  case 2:
                  {
                    q->blue=ScaleShortToQuantum((unsigned short)
                      (pixel &~ 0xf));
                    q++;
                    break;
                  }
                }
                PushShortPixel(p,pixel);
                switch ((x+1) % 3)
                {
                  default:
                  case 0:
                  {
                    q->red=ScaleShortToQuantum((unsigned short) (pixel &~ 0xf));
                    break;
                  }
                  case 1:
                  {
                    q->green=ScaleShortToQuantum((unsigned short)
                      (pixel &~ 0xf));
                    break;
                  }
                  case 2:
                  {
                    q->blue=ScaleShortToQuantum((unsigned short)
                      (pixel &~ 0xf));
                    q++;
                    break;
                  }
                }
                p+=quantum_info->pad*sizeof(pixel);
              }
              for (bit=0; bit < (long) (3*number_pixels % 2); bit++)
              {
                PushShortPixel(p,pixel);
                switch ((x+bit) % 3)
                {
                  default:
                  case 0:
                  {
                    q->red=ScaleShortToQuantum((unsigned short) (pixel &~ 0xf));
                    break;
                  }
                  case 1:
                  {
                    q->green=ScaleShortToQuantum((unsigned short)
                      (pixel &~ 0xf));
                    break;
                  }
                  case 2:
                  {
                    q->blue=ScaleShortToQuantum((unsigned short)
                      (pixel &~ 0xf));
                    q++;
                    break;
                  }
                }
                p+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned short) PushPixelQuantum(p,image->depth);
            q->red=ScaleShortToQuantum((unsigned short) (pixel << 4));
            pixel=(unsigned short) PushPixelQuantum(p,image->depth);
            q->green=ScaleShortToQuantum((unsigned short) (pixel << 4));
            pixel=(unsigned short) PushPixelQuantum(p,image->depth);
            q->blue=ScaleShortToQuantum((unsigned short) (pixel << 4));
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->red=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->green=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->blue=ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->red=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->green=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->blue=ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->green=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->blue=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q++;
          }
          break;
        }
      }
      break;
    }
    case RGBAQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->red=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->green=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->blue=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->opacity=QuantumRange-ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->red=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->green=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->blue=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->opacity=QuantumRange-ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->red=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->green=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->blue=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->opacity=QuantumRange-ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->green=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->blue=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->opacity=QuantumRange-
              ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q++;
          }
          break;
        }
      }
      break;
    }
    case RGBOQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->red=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->green=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->blue=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->opacity=ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->red=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->green=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->blue=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->opacity=ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->opacity=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->red=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->green=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->blue=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->opacity=ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->opacity=RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->green=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->blue=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->opacity=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q++;
          }
          break;
        }
      }
      break;
    }
    case CMYKQuantum:
    {
      if (image->colorspace != CMYKColorspace)
        ThrowBinaryException(ImageError,"ColorSeparatedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->red=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->green=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->blue=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            indexes[x]=ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->red=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->green=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->blue=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            indexes[x]=ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                indexes[x]=(IndexPacket) RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->red=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->green=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->blue=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            indexes[x]=ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                indexes[x]=(IndexPacket) RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->green=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->blue=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            indexes[x]=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q++;
          }
          break;
        }
      }
      break;
    }
    case CMYKAQuantum:
    {
      if (image->colorspace != CMYKColorspace)
        ThrowBinaryException(ImageError,"ColorSeparatedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushCharPixel(p,pixel);
            q->red=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->green=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->blue=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            indexes[x]=ScaleCharToQuantum(pixel);
            PushCharPixel(p,pixel);
            q->opacity=QuantumRange-ScaleCharToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PushShortPixel(p,pixel);
            q->red=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->green=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->blue=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            indexes[x]=ScaleShortToQuantum(pixel);
            PushShortPixel(p,pixel);
            q->opacity=QuantumRange-ScaleShortToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register float
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushFloatPixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                indexes[x]=(IndexPacket) RoundToQuantum(pixel);
                PushFloatPixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PushLongPixel(p,pixel);
            q->red=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->green=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->blue=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            indexes[x]=ScaleLongToQuantum(pixel);
            PushLongPixel(p,pixel);
            q->opacity=QuantumRange-ScaleLongToQuantum(pixel);
            p+=quantum_info->pad*sizeof(pixel);
            q++;
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                PushDoublePixel(p,pixel);
                q->red=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->green=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->blue=RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                indexes[x]=(IndexPacket) RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                q->opacity=QuantumRange-RoundToQuantum(pixel);
                PushDoublePixel(p,pixel);
                p+=quantum_info->pad*sizeof(pixel);
                q++;
              }
              break;
            }
        }
        default:
        {
          register unsigned long
            pixel;

          (void) PushPixelQuantum(p,0);
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=PushPixelQuantum(p,image->depth);
            q->red=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->green=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->blue=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            indexes[x]=ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            pixel=PushPixelQuantum(p,image->depth);
            q->opacity=QuantumRange-
              ScaleAnyToQuantum(pixel,(1UL << image->depth)-1);
            q++;
          }
          break;
        }
      }
      break;
    }
    default:
      break;
  }
  return(MagickTrue);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   G e t Q u a n t u m I n f o                                               %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  GetQuantumInfo() initializes the QuantumInfo structure to default values.
%
%  The format of the GetQuantumInfo method is:
%
%      GetQuantumInfo(const ImageInfo *image_info,QuantumInfo *quantum_info)
%
%  A description of each parameter follows:
%
%    o image_info: The image info.
%
%    o quantum_info: The quantum info.
%
*/
MagickExport void GetQuantumInfo(const ImageInfo *image_info,
  QuantumInfo *quantum_info)
{
  const char
    *option;

  assert(image_info != (ImageInfo *) NULL);
  assert(image_info->signature == MagickSignature);
  assert(quantum_info != (QuantumInfo *) NULL);
  (void) ResetMagickMemory(quantum_info,0,sizeof(*quantum_info));
  option=GetImageOption(image_info,"quantum:format");
  if (option != (char *) NULL)
    quantum_info->format=(QuantumFormatType) ParseMagickOption(
      MagickQuantumFormatOptions,MagickFalse,option);
  quantum_info->minimum=0.0;
  option=GetImageOption(image_info,"quantum:minimum");
  if (option != (char *) NULL)
    quantum_info->minimum=atof(option);
  quantum_info->maximum=1.0;
  option=GetImageOption(image_info,"quantum:maximum");
  if (option != (char *) NULL)
    quantum_info->maximum=atof(option);
  if ((quantum_info->minimum == 0.0) && (quantum_info->maximum == 0.0))
    quantum_info->scale=0.0;
  else
    if (quantum_info->minimum == quantum_info->maximum)
      {
        quantum_info->scale=QuantumRange/quantum_info->minimum;
        quantum_info->minimum=0.0;
      }
    else
      quantum_info->scale=QuantumRange/(quantum_info->maximum-
        quantum_info->minimum);
  option=GetImageOption(image_info,"quantum:scale");
  if (option != (char *) NULL)
    quantum_info->scale=atof(option);
  option=GetImageOption(image_info,"quantum:polarity");
  if (option != (char *) NULL)
    quantum_info->polarity=LocaleCompare(option,"min-is-black") == 0 ? 0 : 1;
  quantum_info->pad=0;
  quantum_info->signature=MagickSignature;
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
+   I m p o r t Q u a n t u m P i x e l s                                     %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ImportQuantumPixels() transfers one or more pixel components from the image
%  pixel cache to a user supplied buffer.  The pixels are returned in network
%  byte order.  MagickTrue is returned if the pixels are successfully
%  transferred, otherwise MagickFalse.
%
%  The format of the ImportQuantumPixels method is:
%
%      MagickBooleanType ImportQuantumPixels(Image *image,
%        const QuantumInfo *quantum_info,const QuantumType quantum_type,
%        unsigned char *pixels)
%
%  A description of each parameter follows:
%
%    o image: The image.
%
%    o quantum_info: The quantum info.
%
%    o quantum_type: Declare which pixel components to transfer (RGB, RGBA,
%      etc).
%
%    o pixels:  The components are transferred to this buffer.
%
*/

static inline void PopPixelQuantum(const unsigned long depth,
  const unsigned long quantum,unsigned char *pixels)
{
  register long
    i;

  register unsigned long
    data_bits;

  static unsigned char
    *p;

  static unsigned long
    quantum_bits;

  if (depth == 0UL)
    {
      p=pixels;
      quantum_bits=8UL;
    }
  for (i=(long) depth; i > 0L; )
  {
    data_bits=(unsigned long) i;
    if (data_bits > quantum_bits)
      data_bits=quantum_bits;
    i-=data_bits;
    if (quantum_bits == 8)
      *p='\0';
    quantum_bits-=data_bits;
    *p|=(((quantum >> i) &~ ((~0UL) << data_bits)) << quantum_bits);
    if (quantum_bits == 0UL)
      {
        p++;
        quantum_bits=8UL;
      }
  }
}

MagickExport MagickBooleanType ImportQuantumPixels(Image *image,
  const QuantumInfo *quantum_info,const QuantumType quantum_type,
  unsigned char *pixels)
{
#define PopCharPixel(pixel,q) \
{ \
  *(q)++=(unsigned char) (pixel); \
}
#define PopDoublePixel(pixel,q) \
{ \
  *((double *) q)=(double) (pixel)*quantum_info->scale+quantum_info->minimum; \
  q+=sizeof(double); \
}
#define PopFloatPixel(pixel,q) \
{ \
  *((float *) q)=(float) ((double) (pixel)*quantum_info->scale+ \
    quantum_info->minimum); \
  q+=sizeof(float); \
}
#define PopLongPixel(pixel,q) \
{ \
  if (image->endian != LSBEndian) \
    { \
      *(q)++=(unsigned char) ((pixel) >> 24); \
      *(q)++=(unsigned char) ((pixel) >> 16); \
      *(q)++=(unsigned char) ((pixel) >> 8); \
      *(q)++=(unsigned char) (pixel); \
    } \
  else \
    { \
      *(q)++=(unsigned char) (pixel); \
      *(q)++=(unsigned char) ((pixel) >> 8); \
      *(q)++=(unsigned char) ((pixel) >> 16); \
      *(q)++=(unsigned char) ((pixel) >> 24); \
    } \
}
#define PopShortPixel(pixel,q) \
{ \
  if (image->endian != LSBEndian) \
    { \
      *(q)++=(unsigned char) ((pixel) >> 8); \
      *(q)++=(unsigned char) (pixel); \
    } \
  else \
    { \
      *(q)++=(unsigned char) (pixel); \
      *(q)++=(unsigned char) ((pixel) >> 8); \
    } \
}

  long
    bit;

  MagickSizeType
    number_pixels;

  register IndexPacket
    *indexes;

  register long
    i,
    x;

  register PixelPacket
    *p;

  register unsigned char
    *q;

  assert(image != (Image *) NULL);
  assert(image->signature == MagickSignature);
  if (image->debug != MagickFalse)
    (void) LogMagickEvent(TraceEvent,GetMagickModule(),"%s",image->filename);
  assert(quantum_info != (QuantumInfo *) NULL);
  assert(quantum_info->signature == MagickSignature);
  assert(pixels != (unsigned char *) NULL);
  number_pixels=GetPixelCacheArea(image);
  x=0;
  p=GetPixels(image);
  indexes=GetIndexes(image);
  q=pixels;
  switch (quantum_type)
  {
    case IndexQuantum:
    {
      if (image->storage_class != PseudoClass)
        ThrowBinaryException(ImageError,"ColormappedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 1:
        {
          register unsigned char
            pixel;

          for (x=((long) number_pixels-7); x > 0; x-=8)
          {
            pixel=(unsigned char) *indexes++;
            *q=((pixel & 0x01) << 7);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 6);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 5);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 4);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 3);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 2);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 1);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 0);
            q++;
          }
          if ((number_pixels % 8) != 0)
            {
              *q='\0';
              for (bit=7; bit >= (long) (8-(number_pixels % 8)); bit--)
              {
                pixel=(unsigned char) *indexes++;
                *q|=((pixel & 0x01) << (unsigned char) bit);
              }
              q++;
            }
          break;
        }
        case 2:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-3); x+=4)
          {
            pixel=(unsigned char) *indexes++;
            *q=((pixel & 0x03) << 6);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x03) << 4);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x03) << 2);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x03) << 0);
            q++;
          }
          if ((number_pixels % 4) != 0)
            {
              *q='\0';
              for (i=3; i >= (4-((long) number_pixels % 4)); i--)
              {
                pixel=(unsigned char) *indexes++;
                *q|=((pixel & 0x03) << ((unsigned char) i*2));
              }
              q++;
            }
          break;
        }
        case 4:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) (number_pixels-1) ; x+=2)
          {
            pixel=(unsigned char) *indexes++;
            *q=((pixel & 0xf) << 4);
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0xf) << 0);
            q++;
          }
          if ((number_pixels % 2) != 0)
            {
              pixel=(unsigned char) *indexes++;
              *q=((pixel & 0xf) << 4);
              q++;
            }
          break;
        }
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PopCharPixel(indexes[x],q);
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PopShortPixel((unsigned long) indexes[x],q);
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register float
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=(float)  indexes[x];
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PopLongPixel((unsigned long) indexes[x],q);
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          register double
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=(double) indexes[x];
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(indexes[x],
              (1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case IndexAlphaQuantum:
    {
      if (image->storage_class != PseudoClass)
        ThrowBinaryException(ImageError,"ColormappedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 1:
        {
          register unsigned char
            pixel;

          for (x=((long) number_pixels-3); x > 0; x-=4)
          {
            pixel=(unsigned char) *indexes++;
            *q=((pixel & 0x01) << 7);
            pixel=(unsigned char) (p->opacity == TransparentOpacity);
            *q|=((pixel & 0x01) << 6);
            p++;
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 5);
            pixel=(unsigned char) (p->opacity == TransparentOpacity);
            *q|=((pixel & 0x01) << 4);
            p++;
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 3);
            pixel=(unsigned char) (p->opacity == TransparentOpacity);
            *q|=((pixel & 0x01) << 2);
            p++;
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x01) << 1);
            pixel=(unsigned char) (p->opacity == TransparentOpacity);
            *q|=((pixel & 0x01) << 0);
            p++;
            q++;
          }
          if ((number_pixels % 4) != 0)
            {
              *q='\0';
              for (bit=3; bit >= (long) (4-(number_pixels % 4)); bit-=2)
              {
                pixel=(unsigned char) *indexes++;
                *q|=((pixel & 0x01) << (unsigned char) bit);
                pixel=(unsigned char) (p->opacity == TransparentOpacity);
                *q|=((pixel & 0x01) << (unsigned char) (bit-1));
                p++;
              }
              q++;
            }
          break;
        }
        case 2:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned char) *indexes++;
            *q=((pixel & 0x03) << 6);
            pixel=(unsigned char) (4*QuantumScale*p->opacity+0.5);
            *q|=((pixel & 0x03) << 4);
            p++;
            pixel=(unsigned char) *indexes++;
            *q|=((pixel & 0x03) << 2);
            pixel=(unsigned char) (4*QuantumScale*p->opacity+0.5);
            *q|=((pixel & 0x03) << 0);
            p++;
            q++;
          }
          break;
        }
        case 4:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels ; x++)
          {
            pixel=(unsigned char) *indexes++;
            *q=((pixel & 0xf) << 4);
            pixel=(unsigned char)
              (16*QuantumScale*((Quantum) (QuantumRange-p->opacity))+0.5);
            *q|=((pixel & 0xf) << 0);
            p++;
            q++;
          }
          break;
        }
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PopCharPixel(indexes[x],q);
            pixel=ScaleQuantumToChar((Quantum) (QuantumRange-p->opacity));
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            PopShortPixel((unsigned long) indexes[x],q);
            pixel=ScaleQuantumToShort((Quantum) (QuantumRange-p->opacity));
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float)  indexes[x];
                PopFloatPixel(pixel,q);
                pixel=(float)  (QuantumRange-p->opacity);
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            PopLongPixel((unsigned long) indexes[x],q);
            pixel=ScaleQuantumToLong((Quantum) (QuantumRange-p->opacity));
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register double
                  pixel;

                pixel=(double) indexes[x];
                PopDoublePixel(pixel,q);
                pixel=(double) (QuantumRange-p->opacity);
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(indexes[x],
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny((Quantum)
              (QuantumRange-p->opacity),(1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case GrayQuantum:
    case GrayPadQuantum:
    {
      switch (image->depth)
      {
        case 1:
        {
          for (x=((long) number_pixels-7); x > 0; x-=8)
          {
            *q='\0';
            if (quantum_info->polarity == 0)
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x00 : 0x01) << 7;
            else
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x01 : 0x00) << 7;
            p++;
            if (quantum_info->polarity == 0)
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x00 : 0x01) << 6;
            else
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x01 : 0x00) << 6;
            p++;
            if (quantum_info->polarity == 0)
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x00 : 0x01) << 5;
            else
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x01 : 0x00) << 5;
            p++;
            if (quantum_info->polarity == 0)
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x00 : 0x01) << 4;
            else
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x01 : 0x00) << 4;
            p++;
            if (quantum_info->polarity == 0)
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x00 : 0x01) << 3;
            else
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x01 : 0x00) << 3;
            p++;
            if (quantum_info->polarity == 0)
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x00 : 0x01) << 2;
            else
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x01 : 0x00) << 2;
            p++;
            if (quantum_info->polarity == 0)
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x00 : 0x01) << 1;
            else
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x01 : 0x00) << 1;
            p++;
            if (quantum_info->polarity == 0)
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x00 : 0x01) << 0;
            else
              *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x01 : 0x00) << 0;
            p++;
            q++;
          }
          if ((number_pixels % 8) != 0)
            {
              *q='\0';
              for (bit=7; bit >= (long) (8-(number_pixels % 8)); bit--)
              {
                if (quantum_info->polarity == 0)
                  *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x00 :
                    0x01) << bit;
                else
                  *q|=(PixelIntensity(p) > (QuantumRange/2.0) ? 0x01 :
                    0x00) << bit;
                p++;
              }
              q++;
            }
          break;
        }
        case 2:
        {
          register unsigned char
            pixel;

          for (x=0; x < ((long) number_pixels-3); x+=4)
          {
            *q='\0';
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q|=((pixel & 0x03) << 6);
            p++;
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q|=((pixel & 0x03) << 4);
            p++;
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q|=((pixel & 0x03) << 2);
            p++;
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q|=((pixel & 0x03));
            p++;
            q++;
          }
          if ((number_pixels % 4) != 0)
            {
              *q='\0';
              for (i=3; i >= (4-((long) number_pixels % 4)); i--)
              {
                pixel=(unsigned char) PixelIntensityToQuantum(p);
                *q|=(pixel << ((unsigned char) i*2));
                p++;
              }
              q++;
            }
          break;
        }
        case 4:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) (number_pixels-1) ; x+=2)
          {
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q=((pixel & 0xf) << 4);
            p++;
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q|=((pixel & 0xf) << 0);
            p++;
            q++;
          }
          if ((number_pixels % 2) != 0)
            {
              pixel=(unsigned char) PixelIntensityToQuantum(p);
              *q=((pixel & 0xf) << 4);
              p++;
              q++;
            }
          break;
        }
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(PixelIntensityToQuantum(p));
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 10:
        {
          register unsigned short
            pixel;

          if (quantum_type == GrayPadQuantum)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=ScaleQuantumToShort(PixelIntensityToQuantum(p));
                PopShortPixel(pixel >> 6,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(
              PixelIntensityToQuantum(p),(1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 12:
        {
          register unsigned short
            pixel;

          if (quantum_type == GrayPadQuantum)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=ScaleQuantumToShort(PixelIntensityToQuantum(p));
                PopShortPixel(pixel >> 4,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(
              PixelIntensityToQuantum(p),(1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(PixelIntensityToQuantum(p));
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) PixelIntensityToQuantum(p);
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(PixelIntensityToQuantum(p));
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register double
                  pixel;

                pixel=(double) PixelIntensityToQuantum(p);
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(
              PixelIntensityToQuantum(p),(1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case GrayAlphaQuantum:
    {
      switch (image->depth)
      {
        case 1:
        {
          register unsigned char
            pixel;

          for (x=((long) number_pixels-3); x > 0; x-=4)
          {
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q=(unsigned char) (((int) pixel != 0 ? 0x00 : 0x01) << 7);
            pixel=(unsigned char) (p->opacity == OpaqueOpacity ? 0x00 : 0x01);
            *q|=(((int) pixel != 0 ? 0x00 : 0x01) << 6);
            p++;
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q|=(((int) pixel != 0 ? 0x00 : 0x01) << 5);
            pixel=(unsigned char) (p->opacity == OpaqueOpacity ? 0x00 : 0x01);
            *q|=(((int) pixel != 0 ? 0x00 : 0x01) << 4);
            p++;
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q|=(((int) pixel != 0 ? 0x00 : 0x01) << 3);
            pixel=(unsigned char) (p->opacity == OpaqueOpacity ? 0x00 : 0x01);
            *q|=(((int) pixel != 0 ? 0x00 : 0x01) << 2);
            p++;
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q|=(((int) pixel != 0 ? 0x00 : 0x01) << 1);
            pixel=(unsigned char) (p->opacity == OpaqueOpacity ? 0x00 : 0x01);
            *q|=(((int) pixel != 0 ? 0x00 : 0x01) << 0);
            p++;
            q++;
          }
          if ((number_pixels % 4) != 0)
            {
              *q='\0';
              for (bit=3; bit >= (long) (4-(number_pixels % 4)); bit-=2)
              {
                pixel=(unsigned char) PixelIntensityToQuantum(p);
                *q|=(((int) pixel != 0 ? 0x00 : 0x01) << (unsigned char) bit);
                pixel=(unsigned char) (p->opacity == OpaqueOpacity ?
                  0x00 : 0x01);
                *q|=(((int) pixel != 0 ? 0x00 : 0x01) <<
                  (unsigned char) (bit-1));
                p++;
              }
              q++;
            }
          break;
        }
        case 2:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q=((pixel & 0x03) << 6);
            pixel=(unsigned char) (4*QuantumScale*p->opacity+0.5);
            *q|=((pixel & 0x03) << 4);
            p++;
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q|=((pixel & 0x03) << 2);
            pixel=(unsigned char) (4*QuantumScale*p->opacity+0.5);
            *q|=((pixel & 0x03) << 0);
            p++;
            q++;
          }
          break;
        }
        case 4:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels ; x++)
          {
            pixel=(unsigned char) PixelIntensityToQuantum(p);
            *q=((pixel & 0xf) << 4);
            pixel=(unsigned char)
              (16*QuantumScale*((Quantum) (QuantumRange-p->opacity))+0.5);
            *q|=((pixel & 0xf) << 0);
            p++;
            q++;
          }
          break;
        }
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(PixelIntensityToQuantum(p));
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar((Quantum) (QuantumRange-p->opacity));
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(PixelIntensityToQuantum(p));
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort((Quantum) (QuantumRange-p->opacity));
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) PixelIntensityToQuantum(p);
                PopFloatPixel(pixel,q);
                pixel=(float) (QuantumRange-p->opacity);
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(PixelIntensityToQuantum(p));
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong((Quantum) (QuantumRange-p->opacity));
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register double
                  pixel;

                pixel=(double) PixelIntensityToQuantum(p);
                PopDoublePixel(pixel,q);
                pixel=(double) (QuantumRange-p->opacity);
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(
              PixelIntensityToQuantum(p),(1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny((Quantum)
              (QuantumRange-p->opacity),(1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case RedQuantum:
    case CyanQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(p->red);
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(p->red);
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) p->red;
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(p->red);
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register double
                  pixel;

                pixel=(double) p->red;
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->red,
              (1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case GreenQuantum:
    case MagentaQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(p->green);
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(p->green);
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) p->green;
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(p->green);
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register double
                  pixel;

                pixel=(double) p->green;
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->green,
              (1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case BlueQuantum:
    case YellowQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(p->blue);
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(p->blue);
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) p->blue;
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(p->blue);
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register double
                  pixel;

                pixel=(double) p->blue;
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->blue,
              (1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case AlphaQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar((Quantum) (QuantumRange-p->opacity));
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort((Quantum) (QuantumRange-p->opacity));
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) (QuantumRange-p->opacity);
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong((Quantum) (QuantumRange-p->opacity));
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register double
                  pixel;

                pixel=(double) (QuantumRange-p->opacity);
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny((Quantum)
              (QuantumRange-p->opacity),(1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case BlackQuantum:
    {
      if (image->colorspace != CMYKColorspace)
        ThrowBinaryException(ImageError,"ColorSeparatedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(indexes[x]);
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(indexes[x]);
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) indexes[x];
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(indexes[x]);
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register double
                  pixel;

                pixel=(double) indexes[x];
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny((Quantum)
              indexes[x],(1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case RGBQuantum:
    case RGBPadQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(p->red);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->green);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->blue);
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 10:
        {
          register unsigned long
            pixel;

          if (quantum_type == RGBPadQuantum)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=(unsigned long) (((long) ((1023L*p->red+QuantumRange/2)/
                  QuantumRange) & 0x3ff) << 22) | (((long) (QuantumScale*(1023L*
                  p->green+QuantumRange/2)) & 0x3ff) << 12) | (((long)
                  (QuantumScale*(1023L*p->blue+QuantumRange/2)) & 0x3ff) << 2);
                PopLongPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,
              ScaleQuantumToShort(p->red) >> 6UL,q);
            PopPixelQuantum(image->depth,
              ScaleQuantumToShort(p->green) >> 6UL,q);
            PopPixelQuantum(image->depth,
              ScaleQuantumToShort(p->blue) >> 6UL,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 12:
        {
          register unsigned short
            pixel;

          if (quantum_type == RGBPadQuantum)
            {
              for (x=0; x < (long) (3*number_pixels-1); x+=2)
              {
                switch (x % 3)
                {
                  default:
                  case 0:
                  {
                    pixel=(unsigned short) (ScaleQuantumToShort(p->red) >> 4);
                    break;
                  }
                  case 1:
                  {
                    pixel=(unsigned short) (ScaleQuantumToShort(p->green) >> 4);
                    break;
                  }
                  case 2:
                  {
                    pixel=(unsigned short) (ScaleQuantumToShort(p->green) >> 4);
                    p++;
                    break;
                  }
                }
                PopShortPixel(pixel << 4,q);
                switch ((x+1) % 3)
                {
                  default:
                  case 0:
                  {
                    pixel=(unsigned short) (ScaleQuantumToShort(p->red) >> 4);
                    break;
                  }
                  case 1:
                  {
                    pixel=(unsigned short) (ScaleQuantumToShort(p->green) >> 4);
                    break;
                  }
                  case 2:
                  {
                    pixel=(unsigned short) (ScaleQuantumToShort(p->green) >> 4);
                    p++;
                    break;
                  }
                }
                PopShortPixel(pixel << 4,q);
                q+=quantum_info->pad*sizeof(pixel);
              }
              for (bit=0; bit < (long) (3*number_pixels % 2); bit++)
              {
                switch ((x+bit) % 3)
                {
                  default:
                  case 0:
                  {
                    pixel=(unsigned short) (ScaleQuantumToShort(p->red) >> 4);
                    break;
                  }
                  case 1:
                  {
                    pixel=(unsigned short) (ScaleQuantumToShort(p->green) >> 4);
                    break;
                  }
                  case 2:
                  {
                    pixel=(unsigned short) (ScaleQuantumToShort(p->green) >> 4);
                    p++;
                    break;
                  }
                }
                PopShortPixel(pixel << 4,q);
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToShort(p->red) >> 4UL,q);
            PopPixelQuantum(image->depth,
              ScaleQuantumToShort(p->green) >> 4UL,q);
            PopPixelQuantum(image->depth,ScaleQuantumToShort(p->blue) >> 4UL,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(p->red);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->green);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->blue);
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) p->red;
                PopFloatPixel(pixel,q);
                pixel=(float) p->green;
                PopFloatPixel(pixel,q);
                pixel=(float) p->blue;
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(p->red);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->green);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->blue);
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=(double) p->red;
                PopDoublePixel(pixel,q);
                pixel=(double) p->green;
                PopDoublePixel(pixel,q);
                pixel=(double) p->blue;
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->red,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->green,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->blue,
              (1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case RGBAQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(p->red);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->green);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->blue);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar((Quantum) (QuantumRange-p->opacity));
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(p->red);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->green);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->blue);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort((Quantum) (QuantumRange-p->opacity));
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) p->red;
                PopFloatPixel(pixel,q);
                pixel=(float) p->green;
                PopFloatPixel(pixel,q);
                pixel=(float) p->blue;
                PopFloatPixel(pixel,q);
                pixel=(float) (QuantumRange-p->opacity);
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(p->red);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->green);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->blue);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong((Quantum) (QuantumRange-p->opacity));
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=(double) p->red;
                PopDoublePixel(pixel,q);
                pixel=(double) p->green;
                PopDoublePixel(pixel,q);
                pixel=(double) p->blue;
                PopDoublePixel(pixel,q);
                pixel=(double) (QuantumRange-p->opacity);
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->red,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->green,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->blue,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny((Quantum)
              (QuantumRange-p->opacity),(1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case RGBOQuantum:
    {
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(p->red);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->green);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->blue);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->opacity);
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(p->red);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->green);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->blue);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->opacity);
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) p->red;
                PopFloatPixel(pixel,q);
                pixel=(float) p->green;
                PopFloatPixel(pixel,q);
                pixel=(float) p->blue;
                PopFloatPixel(pixel,q);
                pixel=(float) p->opacity;
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(p->red);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->green);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->blue);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->opacity);
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=(double) p->red;
                PopDoublePixel(pixel,q);
                pixel=(double) p->green;
                PopDoublePixel(pixel,q);
                pixel=(double) p->blue;
                PopDoublePixel(pixel,q);
                pixel=(double) p->opacity;
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->red,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->green,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->blue,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->opacity,
              (1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case CMYKQuantum:
    {
      if (image->colorspace != CMYKColorspace)
        ThrowBinaryException(ImageError,"ColorSeparatedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(p->red);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->green);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->blue);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(indexes[x]);
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(p->red);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->green);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->blue);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(indexes[x]);
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) p->red;
                PopFloatPixel(pixel,q);
                pixel=(float) p->green;
                PopFloatPixel(pixel,q);
                pixel=(float) p->blue;
                PopFloatPixel(pixel,q);
                pixel=(float) indexes[x];
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(p->red);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->green);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->blue);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(indexes[x]);
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=(double) p->red;
                PopDoublePixel(pixel,q);
                pixel=(double) p->green;
                PopDoublePixel(pixel,q);
                pixel=(double) p->blue;
                PopDoublePixel(pixel,q);
                pixel=(double) indexes[x];
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->red,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->green,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->blue,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(indexes[x],
              (1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    case CMYKAQuantum:
    {
      if (image->colorspace != CMYKColorspace)
        ThrowBinaryException(ImageError,"ColorSeparatedImageRequired",
          image->filename);
      switch (image->depth)
      {
        case 8:
        {
          register unsigned char
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToChar(p->red);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->green);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(p->blue);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar(indexes[x]);
            PopCharPixel(pixel,q);
            pixel=ScaleQuantumToChar((Quantum) (QuantumRange-p->opacity));
            PopCharPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 16:
        {
          register unsigned short
            pixel;

          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToShort(p->red);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->green);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(p->blue);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort(indexes[x]);
            PopShortPixel(pixel,q);
            pixel=ScaleQuantumToShort((Quantum) (QuantumRange-p->opacity));
            PopShortPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 32:
        {
          register unsigned long
            pixel;

          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              for (x=0; x < (long) number_pixels; x++)
              {
                register float
                  pixel;

                pixel=(float) p->red;
                PopFloatPixel(pixel,q);
                pixel=(float) p->green;
                PopFloatPixel(pixel,q);
                pixel=(float) p->blue;
                PopFloatPixel(pixel,q);
                pixel=(float) p->opacity;
                PopFloatPixel(pixel,q);
                pixel=(float) (QuantumRange-p->opacity);
                PopFloatPixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
          for (x=0; x < (long) number_pixels; x++)
          {
            pixel=ScaleQuantumToLong(p->red);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->green);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(p->blue);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong(indexes[x]);
            PopLongPixel(pixel,q);
            pixel=ScaleQuantumToLong((Quantum) (QuantumRange-p->opacity));
            PopLongPixel(pixel,q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
        case 64:
        {
          if (quantum_info->format == FloatingPointQuantumFormat)
            {
              register double
                pixel;

              for (x=0; x < (long) number_pixels; x++)
              {
                pixel=(double) p->red;
                PopDoublePixel(pixel,q);
                pixel=(double) p->green;
                PopDoublePixel(pixel,q);
                pixel=(double) p->blue;
                PopDoublePixel(pixel,q);
                pixel=(double) indexes[x];
                PopDoublePixel(pixel,q);
                pixel=(double) (QuantumRange-p->opacity);
                PopDoublePixel(pixel,q);
                p++;
                q+=quantum_info->pad*sizeof(pixel);
              }
              break;
            }
        }
        default:
        {
          register unsigned char
            pixel;

          PopPixelQuantum(0,0,q);
          for (x=0; x < (long) number_pixels; x++)
          {
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->red,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->green,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->blue,
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(indexes[x],
              (1UL << image->depth)-1),q);
            PopPixelQuantum(image->depth,ScaleQuantumToAny(p->opacity,
              (1UL << image->depth)-1),q);
            p++;
            q+=quantum_info->pad*sizeof(pixel);
          }
          break;
        }
      }
      break;
    }
    default:
      break;
  }
  return(MagickTrue);
}
