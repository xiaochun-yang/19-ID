/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                               A N A L I Z E                                 %
%                                                                             %
%               Methods to Compute a Information about an Image               %
%                                                                             %
%                                                                             %
%                             Software Design                                 %
%                               Bill Corbis                                   %
%                              December 1998                                  %
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
*/

/*
  Include declarations.
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <assert.h>
#include <math.h>
#include "magick/MagickCore.h"

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   A n a l y z e I m a g e                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  AnalyzeImage() computes the brightness and saturation mean and standard
%  deviation and stores these values as attributes of the image.
%
%  The format of the AnalyzeImage method is:
%
%      MagickBooleanType AnalyzeImage(Image *images,const int argc,
%        char **argv)
%
%  A description of each parameter follows:
%
%    o image: The address of a structure of type Image.
%
%    o argc: Specifies a pointer to an integer describing the number of
%      elements in the argument vector.
%
%    o argv: Specifies a pointer to a text array containing the command line
%      arguments.
%
*/
ModuleExport MagickBooleanType AnalyzeImage(Image **images,const int argc,
  char **argv)
{
#define PRECISION "%.0f"

  char
    text[MaxTextExtent];

  double
    bsumX,
    bsumX2,
    brightness_mean,
    brightness_stdev,
    ssumX,
    ssumX2,
    saturation_mean,
    saturation_stdev,
    total_pixels;

  double
    brightness,
    hue,
    saturation;

  Image
    *image;

  long
    y;

  register const PixelPacket
    *p;

  register long
    x;

  assert(images != (Image **) NULL);
  assert(*images != (Image *) NULL);
  assert((*images)->signature == MagickSignature);
  image=(*images);
  for ( ; image != (Image *) NULL; image=GetNextImageInList(image))
  {
    bsumX = 0.0,
    bsumX2 = 0.0,
    brightness_mean = 0.0,
    brightness_stdev = 0.0,
    ssumX = 0.0,
    ssumX2 = 0.0,
    saturation_mean = 0.0,
    saturation_stdev = 0.0,
    total_pixels = 0.0;
    for (y=0; y < (long) image->rows; y++)
    {
      p=AcquireImagePixels(image,0,y,image->columns,1,&image->exception);
      if (p == (const PixelPacket *) NULL)
        break;
      for (x=0; x < (long) image->columns; x++)
      {
        TransformHSB(p->red,p->green,p->blue,&hue,&saturation,&brightness);
        brightness*=QuantumRange;
        bsumX+=brightness;
        bsumX2+=brightness*brightness;
        saturation*=QuantumRange;
        ssumX+=saturation;
        ssumX2+=saturation*saturation;
        total_pixels++;
        p++;
      }
    }
    if (total_pixels <= 0.0)
      return(MagickFalse);
    brightness_mean=bsumX/total_pixels;
    (void) FormatMagickString(text,MaxTextExtent,PRECISION,brightness_mean);
    (void) SetImageProperty(image,"filter:brightness-mean",text);
    brightness_stdev=sqrt(bsumX2/total_pixels-(bsumX/total_pixels*bsumX/
      total_pixels));
    (void) FormatMagickString(text,MaxTextExtent,PRECISION,brightness_stdev);
    (void) SetImageProperty(image,"filter:brightness-standard-deviation",text);
    saturation_mean=ssumX/total_pixels;
    (void) FormatMagickString(text,MaxTextExtent,PRECISION,saturation_mean);
    (void) SetImageProperty(image,"filter:saturation-mean",text);
    saturation_stdev=sqrt(ssumX2/total_pixels-(ssumX/total_pixels*ssumX/
      total_pixels));
    (void) FormatMagickString(text,MaxTextExtent,PRECISION,saturation_stdev);
    (void) SetImageProperty(image,"filter:saturation-standard-deviation",text);
    (void) FormatMagickString(text,MaxTextExtent,PRECISION,saturation_stdev);
    (void) SetImageProperty(image,"ByteMe",text);
  }
  return(MagickTrue);
}
