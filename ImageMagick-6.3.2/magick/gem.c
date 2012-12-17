/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%                              GGGG  EEEEE  M   M                             %
%                             G      E      MM MM                             %
%                             G GG   EEE    M M M                             %
%                             G   G  E      M   M                             %
%                              GGGG  EEEEE  M   M                             %
%                                                                             %
%                                                                             %
%                    Graphic Gems - Graphic Support Methods                   %
%                                                                             %
%                               Software Design                               %
%                                 John Cristy                                 %
%                                 August 1996                                 %
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
%
*/

/*
  Include declarations.
*/
#include "magick/studio.h"
#include "magick/color-private.h"
#include "magick/draw.h"
#include "magick/gem.h"
#include "magick/image.h"
#include "magick/image-private.h"
#include "magick/log.h"
#include "magick/memory_.h"
#include "magick/pixel-private.h"
#include "magick/quantum.h"
#include "magick/random_.h"
#include "magick/resize.h"
#include "magick/transform.h"
#include "magick/signature.h"

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   C o n s t r a s t                                                         %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Contrast() enhances the intensity differences between the lighter and darker
%  elements of the image.
%
%  The format of the Contrast method is:
%
%      void Contrast(const int sign,Quantum *red,Quantum *green,Quantum *blue)
%
%  A description of each parameter follows:
%
%    o sign: A positive value enhances the contrast otherwise it is reduced.
%
%    o red, green, blue: A pointer to a pixel component of type Quantum.
%
*/
MagickExport void Contrast(const int sign,Quantum *red,Quantum *green,
  Quantum *blue)
{
  double
    brightness,
    hue,
    saturation;

  /*
    Enhance contrast: dark color become darker, light color become lighter.
  */
  assert(red != (Quantum *) NULL);
  assert(green != (Quantum *) NULL);
  assert(blue != (Quantum *) NULL);
  hue=0.0;
  saturation=0.0;
  brightness=0.0;
  TransformHSB(*red,*green,*blue,&hue,&saturation,&brightness);
  brightness+=0.5*sign*(0.5*(sin(MagickPI*(brightness-0.5))+1.0)-brightness);
  if (brightness > 1.0)
    brightness=1.0;
  else
    if (brightness < 0.0)
      brightness=0.0;
  HSBTransform(hue,saturation,brightness,red,green,blue);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   E x p a n d A f f i n e                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ExpandAffine() computes the affine's expansion factor, i.e. the square root
%  of the factor by which the affine transform affects area. In an affine
%  transform composed of scaling, rotation, shearing, and translation, returns
%  the amount of scaling.
%
%  The format of the ExpandAffine method is:
%
%      double ExpandAffine(const AffineMatrix *affine)
%
%  A description of each parameter follows:
%
%    o expansion: Method ExpandAffine returns the affine's expansion factor.
%
%    o affine: A pointer the the affine transform of type AffineMatrix.
%
*/
MagickExport double ExpandAffine(const AffineMatrix *affine)
{
  assert(affine != (const AffineMatrix *) NULL);
  return(sqrt(fabs(affine->sx*affine->sy-affine->rx*affine->ry)));
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   G e t O p t i m a l K e r n e l W i d t h                                 %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  GetOptimalKernelWidth() computes the optimal kernel radius for a convolution
%  filter.  Start with the minimum value of 3 pixels and walk out until we drop
%  below the threshold of one pixel numerical accuracy.
%
%  The format of the GetOptimalKernelWidth method is:
%
%      unsigned long GetOptimalKernelWidth(const double radius,
%        const double sigma)
%
%  A description of each parameter follows:
%
%    o width: Method GetOptimalKernelWidth returns the optimal width of
%      a convolution kernel.
%
%    o radius: The radius of the Gaussian, in pixels, not counting the center
%      pixel.
%
%    o sigma: The standard deviation of the Gaussian, in pixels.
%
*/

static inline double MagickMax(const double x,const double y)
{
  if (x > y)
    return(x);
  return(y);
}

static inline double MagickMin(const double x,const double y)
{
  if (x < y)
    return(x);
  return(y);
}

MagickExport unsigned long GetOptimalKernelWidth1D(const double radius,
  const double sigma)
{
  long
    width;

  MagickRealType
    normalize,
    value;

  register long
    u;

  (void) LogMagickEvent(TraceEvent,GetMagickModule(),"...");
  assert(sigma != 0.0);
  if (radius > 0.0)
    return((unsigned long) (MagickMax(2.0*radius+1.0,3.0)+0.5));
  for (width=5; ;)
  {
    normalize=0.0;
    for (u=(-width/2); u <= (width/2); u++)
      normalize+=exp(-((double) u*u)/(2.0*sigma*sigma))/(MagickSQ2PI*sigma);
    u=width/2;
    value=exp(-((double) u*u)/(2.0*sigma*sigma))/(MagickSQ2PI*sigma)/normalize;
    if ((long) (QuantumRange*value) <= 0)
      break;
    width+=2;
  }
  return((unsigned long) (width-2));
}

MagickExport unsigned long GetOptimalKernelWidth2D(const double radius,
  const double sigma)
{

  long
    width;

  MagickRealType
    alpha,
    normalize,
    value;

  register long
    u,
    v;

  assert(sigma != 0.0);
  (void) LogMagickEvent(TraceEvent,GetMagickModule(),"...");
  if (radius > 0.0)
    return((unsigned long) (MagickMax(2.0*radius+1.0,3.0)+0.5));
  for (width=5; ;)
  {
    normalize=0.0;
    for (v=(-width/2); v <= (width/2); v++)
    {
      for (u=(-width/2); u <= (width/2); u++)
      {
        alpha=exp(-((double) u*u+v*v)/(2.0*sigma*sigma));
        normalize+=alpha/(2.0*MagickPI*sigma*sigma);
      }
    }
    v=width/2;
    value=exp(-((double) v*v)/(2.0*sigma*sigma))/(MagickSQ2PI*sigma)/normalize;
    if ((long) (QuantumRange*value) <= 0)
      break;
    width+=2;
  }
  return((unsigned long) (width-2));
}

MagickExport unsigned long  GetOptimalKernelWidth(const double radius,
  const double sigma)
{
  return(GetOptimalKernelWidth1D(radius,sigma));
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   H S B T r a n s f o r m                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  HSBTransform() converts a (hue, saturation, brightness) to a (red, green,
%  blue) triple.
%
%  The format of the HSBTransformImage method is:
%
%      void HSBTransform(const double hue,const double saturation,
%        const double brightness,Quantum *red,Quantum *green,Quantum *blue)
%
%  A description of each parameter follows:
%
%    o hue, saturation, brightness: A double value representing a
%      component of the HSB color space.
%
%    o red, green, blue: A pointer to a pixel component of type Quantum.
%
*/
MagickExport void HSBTransform(const double hue,const double saturation,
  const double brightness,Quantum *red,Quantum *green,Quantum *blue)
{
  MagickRealType
    f,
    h,
    p,
    q,
    t;

  /*
    Convert HSB to RGB colorspace.
  */
  assert(red != (Quantum *) NULL);
  assert(green != (Quantum *) NULL);
  assert(blue != (Quantum *) NULL);
  if (saturation == 0.0)
    {
      *red=RoundToQuantum((MagickRealType) QuantumRange*brightness);
      *green=(*red);
      *blue=(*red);
      return;
    }
  h=6.0*(hue-floor(hue));
  f=h-floor((double) h);
  p=brightness*(1.0-saturation);
  q=brightness*(1.0-saturation*f);
  t=brightness*(1.0-(saturation*(1.0-f)));
  switch ((int) h)
  {
    case 0:
    default:
    {
      *red=RoundToQuantum((MagickRealType) QuantumRange*brightness);
      *green=RoundToQuantum((MagickRealType) QuantumRange*t);
      *blue=RoundToQuantum((MagickRealType) QuantumRange*p);
      break;
    }
    case 1:
    {
      *red=RoundToQuantum((MagickRealType) QuantumRange*q);
      *green=RoundToQuantum((MagickRealType) QuantumRange*brightness);
      *blue=RoundToQuantum((MagickRealType) QuantumRange*p);
      break;
    }
    case 2:
    {
      *red=RoundToQuantum((MagickRealType) QuantumRange*p);
      *green=RoundToQuantum((MagickRealType) QuantumRange*brightness);
      *blue=RoundToQuantum((MagickRealType) QuantumRange*t);
      break;
    }
    case 3:
    {
      *red=RoundToQuantum((MagickRealType) QuantumRange*p);
      *green=RoundToQuantum((MagickRealType) QuantumRange*q);
      *blue=RoundToQuantum((MagickRealType) QuantumRange*brightness);
      break;
    }
    case 4:
    {
      *red=RoundToQuantum((MagickRealType) QuantumRange*t);
      *green=RoundToQuantum((MagickRealType) QuantumRange*p);
      *blue=RoundToQuantum((MagickRealType) QuantumRange*brightness);
      break;
    }
    case 5:
    {
      *red=RoundToQuantum((MagickRealType) QuantumRange*brightness);
      *green=RoundToQuantum((MagickRealType) QuantumRange*p);
      *blue=RoundToQuantum((MagickRealType) QuantumRange*q);
      break;
    }
  }
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   H S L T r a n s f o r m                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  HSLTransform() converts a (hue, saturation, luminosity) to a (red, green,
%  blue) triple.
%
%  The format of the HSLTransformImage method is:
%
%      void HSLTransform(const double hue,const double saturation,
%        const double luminosity,Quantum *red,Quantum *green,Quantum *blue)
%
%  A description of each parameter follows:
%
%    o hue, saturation, luminosity: A double value representing a
%      component of the HSL color space.
%
%    o red, green, blue: A pointer to a pixel component of type Quantum.
%
*/

static inline MagickRealType HueToRGB(MagickRealType m1,MagickRealType m2,
  MagickRealType hue)
{
  if (hue < 0.0)
    hue+=1.0;
  if (hue > 1.0)
    hue-=1.0;
  if ((6.0*hue) < 1.0)
    return(m1+6.0*(m2-m1)*hue);
  if ((2.0*hue) < 1.0)
    return(m2);
  if ((3.0*hue) < 2.0)
    return(m1+6.0*(m2-m1)*(2.0/3.0-hue));
  return(m1);
}

MagickExport void HSLTransform(const double hue,const double saturation,
  const double luminosity,Quantum *red,Quantum *green,Quantum *blue)
{
  MagickRealType
    b,
    g,
    r,
    m1,
    m2;

  /*
    Convert HSL to RGB colorspace.
  */
  assert(red != (Quantum *) NULL);
  assert(green != (Quantum *) NULL);
  assert(blue != (Quantum *) NULL);
  if (luminosity <= 0.5)
    m2=luminosity*(saturation+1.0);
  else
    m2=luminosity+saturation-luminosity*saturation;
  m1=2.0*luminosity-m2;
  r=HueToRGB(m1,m2,hue+1.0/3.0);
  g=HueToRGB(m1,m2,hue);
  b=HueToRGB(m1,m2,hue-1.0/3.0);
  *red=RoundToQuantum(QuantumRange*r);
  *green=RoundToQuantum(QuantumRange*g);
  *blue=RoundToQuantum(QuantumRange*b);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   H W B T r a n s f o r m                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  HWBTransform() converts a (hue, whiteness, blackness) to a (red, green,
%  blue) triple.
%
%  The format of the HWBTransformImage method is:
%
%      void HWBTransform(const double hue,const double whiteness,
%        const double blackness,Quantum *red,Quantum *green,Quantum *blue)
%
%  A description of each parameter follows:
%
%    o hue, whiteness, blackness: A double value representing a
%      component of the HWB color space.
%
%    o red, green, blue: A pointer to a pixel component of type Quantum.
%
*/
MagickExport void HWBTransform(const double hue,const double whiteness,
  const double blackness,Quantum *red,Quantum *green,Quantum *blue)
{
  MagickRealType
    b,
    f,
    g,
    n,
    r,
    v;

  register long
    i;

  /*
    Convert HWB to RGB colorspace.
  */
  assert(red != (Quantum *) NULL);
  assert(green != (Quantum *) NULL);
  assert(blue != (Quantum *) NULL);
  v=1.0-blackness;
  if (hue == 0.0)
    {
      *red=(Quantum) (QuantumRange*v+0.5);
      *green=(Quantum) (QuantumRange*v+0.5);
      *blue=(Quantum) (QuantumRange*v+0.5);
      return;
    }
  i=(long) floor(hue);
  f=hue-i;
  if ((i & 0x01) != 0)
    f=1.0-f;
  n=whiteness+f*(v-whiteness);  /* linear interpolation */
  switch (i)
  {
    default:
    case 6:
    case 0: r=v; g=n; b=whiteness; break;
    case 1: r=n; g=v; b=whiteness; break;
    case 2: r=whiteness; g=v; b=n; break;
    case 3: r=whiteness; g=n; b=v; break;
    case 4: r=n; g=whiteness; b=v; break;
    case 5: r=v; g=whiteness; b=n; break;
  }
  *red=(Quantum) (QuantumRange*r+0.5);
  *green=(Quantum) (QuantumRange*g+0.5);
  *blue=(Quantum) (QuantumRange*b+0.5);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   H u l l                                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Hull() implements the eight hull algorithm described in Applied Optics, Vol
%  24, No. 10, 15 May 1985, "Geometric filter for Speckle Reduction", by Thomas
%  R Crimmins.  Each pixel in the image is replaced by one of its eight of its
%  surrounding pixels using a polarity and negative hull function.
%
%  The format of the Hull method is:
%
%      void Hull(const long x_offset,const long y_offset,
%        const unsigned long columns,const unsigned long rows,Quantum *f,
%        Quantum *g,const int polarity)
%
%  A description of each parameter follows:
%
%    o x_offset, y_offset: An integer value representing the offset of the
%      current pixel within the image.
%
%    o columns, rows: Specifies the number of rows and columns in the image.
%
%    o polarity: An integer value declaring the polarity (+,-).
%
%    o f, g: A pointer to an image pixel and one of it's neighbor.
%
*/
MagickExport void Hull(const long x_offset,const long y_offset,
  const unsigned long columns,const unsigned long rows,Quantum *f,Quantum *g,
  const int polarity)
{
  long
    y;

  MagickRealType
    v;

  register long
    x;

  register Quantum
    *p,
    *q,
    *r,
    *s;

  assert(f != (Quantum *) NULL);
  assert(g != (Quantum *) NULL);
  p=f+(columns+2);
  q=g+(columns+2);
  r=p+(y_offset*((long) columns+2)+x_offset);
  for (y=0; y < (long) rows; y++)
  {
    p++;
    q++;
    r++;
    if (polarity > 0)
      for (x=(long) columns; x > 0; x--)
      {
        v=(MagickRealType) (*p);
        if ((MagickRealType) *r >= (v+(MagickRealType) ScaleCharToQuantum(2)))
          v+=ScaleCharToQuantum(1);
        *q=(Quantum) v;
        p++;
        q++;
        r++;
      }
    else
      for (x=(long) columns; x > 0; x--)
      {
        v=(MagickRealType) (*p);
        if ((MagickRealType) *r <= (v-(MagickRealType) ScaleCharToQuantum(2)))
          v-=(long) ScaleCharToQuantum(1);
        *q=(Quantum) v;
        p++;
        q++;
        r++;
      }
    p++;
    q++;
    r++;
  }
  p=f+(columns+2);
  q=g+(columns+2);
  r=q+(y_offset*((long) columns+2)+x_offset);
  s=q-(y_offset*((long) columns+2)+x_offset);
  for (y=0; y < (long) rows; y++)
  {
    p++;
    q++;
    r++;
    s++;
    if (polarity > 0)
      for (x=(long) columns; x > 0; x--)
      {
        v=(MagickRealType) (*q);
        if (((MagickRealType) *s >=
             (v+(MagickRealType) ScaleCharToQuantum(2))) &&
            ((MagickRealType) *r > v))
          v+=ScaleCharToQuantum(1);
        *p=(Quantum) v;
        p++;
        q++;
        r++;
        s++;
      }
    else
      for (x=(long) columns; x > 0; x--)
      {
        v=(MagickRealType) (*q);
        if (((MagickRealType) *s <=
             (v-(MagickRealType) ScaleCharToQuantum(2))) &&
            ((MagickRealType) *r < v))
          v-=(MagickRealType) ScaleCharToQuantum(1);
        *p=(Quantum) v;
        p++;
        q++;
        r++;
        s++;
      }
    p++;
    q++;
    r++;
    s++;
  }
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   I n t e r p o l a t e P i x e l C o l o r                                 %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  InterpolatePixelColor() applies bi-linear or tri-linear interpolation
%  between a pixel and it's neighbors.
%
%  The format of the InterpolateColor method is:
%
%      MagickPixelPacket InterpolateColor(const Image *image,
%        ViewInfo *view_info,InterpolatePixelMethod method,const double x,
%        const double y,ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image: The image.
%
%    o image_view: The image cache view.
%
%    o type:  the type of pixel color interpolation.
%
%    o x,y: A double representing the current (x,y) position of the pixel.
%
%    o exception: Return any errors or warnings in this structure.
%
*/

static inline MagickRealType CubicWeightingFunction(const MagickRealType x)
{
  MagickRealType
    alpha,
    gamma;

  alpha=MagickMax(x+2.0,0.0);
  gamma=1.0*alpha*alpha*alpha;
  alpha=MagickMax(x+1.0,0.0);
  gamma-=4.0*alpha*alpha*alpha;
  alpha=MagickMax(x+0.0,0.0);
  gamma+=6.0*alpha*alpha*alpha;
  alpha=MagickMax(x-1.0,0.0);
  gamma-=4.0*alpha*alpha*alpha;
  return(gamma/6.0);
}

static double MeshInterpolate(const PointInfo *delta,const double p,
  const double x,const double y)
{
  return(delta->x*x+delta->y*y+(1.0-delta->x-delta->y)*p);
}

static inline long NearestNeighbor(MagickRealType x)
{
  if (x >= 0.0)
    return((long) (x+0.5));
  return((long) (x-0.5));
}

MagickExport MagickPixelPacket InterpolatePixelColor(const Image *image,
  ViewInfo *image_view,InterpolatePixelMethod method,const double x,
  const double y,ExceptionInfo *exception)
{
  MagickPixelPacket
    pixel,
    pixels[16];

  MagickRealType
    alpha[16],
    gamma;

  PointInfo
    delta;

  register const PixelPacket
    *p;

  register IndexPacket
    *indexes;

  register long
    i;

  assert(image != (Image *) NULL);
  assert(image->signature == MagickSignature);
  assert(image_view != (ViewInfo *) NULL);
  GetMagickPixelPacket(image,&pixel);
  switch (method)
  {
    case AverageInterpolatePixel:
    {
      p=AcquireCacheView(image_view,(long) floor(x)-1,(long) floor(y)-1,
        4,4,exception);
      if (p == (const PixelPacket *) NULL)
        return(pixel);
      indexes=GetCacheViewIndexes(image_view);
      for (i=0; i < 16L; i++)
      {
        GetMagickPixelPacket(image,pixels+i);
        SetMagickPixelPacket(p,indexes+i,pixels+i);
        alpha[i]=1.0;
        if (image->matte != MagickFalse)
          {
            alpha[i]=QuantumScale*((MagickRealType) QuantumRange-p->opacity);
            pixels[i].red*=alpha[i];
            pixels[i].green*=alpha[i];
            pixels[i].blue*=alpha[i];
            if (image->colorspace == CMYKColorspace)
              pixels[i].index*=alpha[i];
          }
        gamma=alpha[i];
        gamma=1.0/(fabs((double) gamma) <= MagickEpsilon ? 1.0 : gamma);
        pixel.red+=gamma*0.0625*pixels[i].red;
        pixel.green+=gamma*0.0625*pixels[i].green;
        pixel.blue+=gamma*0.0625*pixels[i].blue;
        if (image->matte != MagickFalse)
          pixel.opacity+=0.0625*pixels[i].opacity;
        if (image->colorspace == CMYKColorspace)
          pixel.index+=gamma*0.0625*pixels[i].index;
        p++;
      }
      break;
    }
    case BicubicInterpolatePixel:
    {
      long
        n;

      MagickRealType
        dx,
        dy;

      register long
        j;

      p=AcquireCacheView(image_view,(long) floor(x)-1,(long) floor(y)-1,
        4,4,exception);
      if (p == (const PixelPacket *) NULL)
        return(pixel);
      indexes=GetCacheViewIndexes(image_view);
      n=0;
      delta.x=x-floor(x);
      delta.y=y-floor(y);
      for (i=(-1); i < 3L; i++)
      {
        dy=CubicWeightingFunction((MagickRealType) i-delta.y);
        for (j=(-1); j < 3L; j++)
        {
          GetMagickPixelPacket(image,pixels+n);
          SetMagickPixelPacket(p,indexes+n,pixels+n);
          alpha[n]=1.0;
          if (image->matte != MagickFalse)
            {
              alpha[n]=QuantumScale*((MagickRealType) QuantumRange-p->opacity);
              pixels[n].red*=alpha[n];
              pixels[n].green*=alpha[n];
              pixels[n].blue*=alpha[n];
              if (image->colorspace == CMYKColorspace)
                pixels[n].index*=alpha[n];
            }
          dx=CubicWeightingFunction(delta.x-(MagickRealType) j);
          gamma=alpha[n];
          gamma=1.0/(fabs((double) gamma) <= MagickEpsilon ? 1.0 : gamma);
          pixel.red+=gamma*dx*dy*pixels[n].red;
          pixel.green+=gamma*dx*dy*pixels[n].green;
          pixel.blue+=gamma*dx*dy*pixels[n].blue;
          if (image->matte != MagickFalse)
            pixel.opacity+=dx*dy*pixels[n].opacity;
          if (image->colorspace == CMYKColorspace)
            pixel.index+=gamma*dx*dy*pixels[n].index;
          n++;
          p++;
        }
      }
      break;
    }
    case BilinearInterpolatePixel:
    default:
    {
      p=AcquireCacheView(image_view,(long) floor(x),(long) floor(y),2,2,
        exception);
      if (p == (const PixelPacket *) NULL)
        return(pixel);
      indexes=GetCacheViewIndexes(image_view);
      for (i=0; i < 4L; i++)
      {
        GetMagickPixelPacket(image,pixels+i);
        SetMagickPixelPacket(p,indexes+i,pixels+i);
        alpha[i]=1.0;
        if (image->matte != MagickFalse)
          {
            alpha[i]=QuantumScale*((MagickRealType) QuantumRange-p->opacity);
            pixels[i].red*=alpha[i];
            pixels[i].green*=alpha[i];
            pixels[i].blue*=alpha[i];
            if (image->colorspace == CMYKColorspace)
              pixels[i].index*=alpha[i];
          }
        p++;
      }
      delta.x=x-floor(x);
      delta.y=y-floor(y);
      gamma=(((1.0-delta.y)*((1.0-delta.x)*alpha[0]+delta.x*alpha[1])+delta.y*
        ((1.0-delta.x)*alpha[2]+delta.x*alpha[3])));
      gamma=1.0/(fabs((double) gamma) <= MagickEpsilon ? 1.0 : gamma);
      pixel.red=gamma*((1.0-delta.y)*((1.0-delta.x)*pixels[0].red+delta.x*
        pixels[1].red)+delta.y*((1.0-delta.x)*pixels[2].red+delta.x*
        pixels[3].red));
      pixel.green=gamma*((1.0-delta.y)*((1.0-delta.x)*pixels[0].green+delta.x*
        pixels[1].green)+delta.y*((1.0-delta.x)*pixels[2].green+
        delta.x*pixels[3].green));
      pixel.blue=gamma*((1.0-delta.y)*((1.0-delta.x)*pixels[0].blue+delta.x*
        pixels[1].blue)+delta.y*((1.0-delta.x)*pixels[2].blue+delta.x*
        pixels[3].blue));
      if (image->matte != MagickFalse)
        pixel.opacity=((1.0-delta.y)*((1.0-delta.x)*pixels[0].opacity+delta.x*
          pixels[1].opacity)+delta.y*((1.0-delta.x)*pixels[2].opacity+delta.x*
          pixels[3].opacity));
      if (image->colorspace == CMYKColorspace)
        pixel.index=gamma*((1.0-delta.y)*((1.0-delta.x)*pixels[0].index+delta.x*
          pixels[1].index)+delta.y*((1.0-delta.x)*pixels[2].index+delta.x*
          pixels[3].index));
      break;
    }
    case FilterInterpolatePixel:
    {
      Image
        *crop_image,
        *zoom_image;

      RectangleInfo
        geometry;

      geometry.width=4;
      geometry.height=4;
      geometry.x=(long) (x-1.5);
      geometry.y=(long) (y-1.5);
      crop_image=CropImage(image,&geometry,exception);
      if (crop_image == (Image *) NULL)
        break;
      zoom_image=ZoomImage(crop_image,1,1,exception);
      crop_image=DestroyImage(crop_image);
      if (zoom_image == (Image *) NULL)
        break;
      p=AcquireImagePixels(zoom_image,0,0,1,1,exception);
      if (p == (const PixelPacket *) NULL)
        {
          zoom_image=DestroyImage(zoom_image);
          return(pixel);
        }
      indexes=GetIndexes(zoom_image);
      GetMagickPixelPacket(image,pixels);
      SetMagickPixelPacket(p,indexes,&pixel);
      zoom_image=DestroyImage(zoom_image);
      break;
    }
    case IntegerInterpolatePixel:
    {
      p=AcquireCacheView(image_view,(long) floor(x+0.5),(long) floor(y+0.5),1,1,
        exception);
      if (p == (const PixelPacket *) NULL)
        return(pixel);
      indexes=GetCacheViewIndexes(image_view);
      GetMagickPixelPacket(image,pixels);
      SetMagickPixelPacket(p,indexes,&pixel);
      break;
    }
    case MeshInterpolatePixel:
    {
      PointInfo
        luminance;

      p=AcquireCacheView(image_view,(long) floor(x),(long) floor(y),
        2,2,exception);
      if (p == (const PixelPacket *) NULL)
        return(pixel);
      indexes=GetCacheViewIndexes(image_view);
      for (i=0; i < 4L; i++)
      {
        GetMagickPixelPacket(image,pixels+i);
        SetMagickPixelPacket(p,indexes+i,pixels+i);
        alpha[i]=1.0;
        if (image->matte != MagickFalse)
          {
            alpha[i]=QuantumScale*((MagickRealType) QuantumRange-p->opacity);
            pixels[i].red*=alpha[i];
            pixels[i].green*=alpha[i];
            pixels[i].blue*=alpha[i];
            if (image->colorspace == CMYKColorspace)
              pixels[i].index*=alpha[i];
          }
        p++;
      }
      delta.x=x-floor(x);
      delta.y=y-floor(y);
      luminance.x=MagickPixelLuminance(pixels+0)-MagickPixelLuminance(pixels+3);
      luminance.y=MagickPixelLuminance(pixels+1)-MagickPixelLuminance(pixels+2);
      if (fabs(luminance.x) < fabs(luminance.y))
        {
          /*
            Diagonal 0-3 NW-SE.
          */
          if (delta.x <= delta.y)
            {
              /*
                Bottom-left triangle  (pixel:2, diagonal: 0-3).
              */
              delta.y=1.0-delta.y;
              gamma=MeshInterpolate(&delta,alpha[2],alpha[3],alpha[0]);
              gamma=1.0/(fabs((double) gamma) <= MagickEpsilon ? 1.0 : gamma);
              pixel.red=gamma*MeshInterpolate(&delta,pixels[2].red,
                pixels[3].red,pixels[0].red);
              pixel.green=gamma*MeshInterpolate(&delta,pixels[2].green,
                pixels[3].green,pixels[0].green);
              pixel.blue=gamma*MeshInterpolate(&delta,pixels[2].blue,
                pixels[3].blue,pixels[0].blue);
              if (image->matte != MagickFalse)
                pixel.opacity=gamma*MeshInterpolate(&delta,pixels[2].opacity,
                  pixels[3].opacity,pixels[0].opacity);
              if (image->colorspace == CMYKColorspace)
                pixel.index=gamma*MeshInterpolate(&delta,pixels[2].index,
                  pixels[3].index,pixels[0].index);
            }
          else
            {
              /*
                Top-right triangle (pixel:1, diagonal: 0-3).
              */
              delta.x=1.0-delta.x;
              gamma=MeshInterpolate(&delta,alpha[1],alpha[0],alpha[3]);
              gamma=1.0/(fabs((double) gamma) <= MagickEpsilon ? 1.0 : gamma);
              pixel.red=gamma*MeshInterpolate(&delta,pixels[1].red,
                pixels[0].red,pixels[3].red);
              pixel.green=gamma*MeshInterpolate(&delta,pixels[1].green,
                pixels[0].green,pixels[3].green);
              pixel.blue=gamma*MeshInterpolate(&delta,pixels[1].blue,
                pixels[0].blue,pixels[3].blue);
              if (image->matte != MagickFalse)
                pixel.opacity=gamma*MeshInterpolate(&delta,pixels[1].opacity,
                  pixels[0].opacity,pixels[3].opacity);
              if (image->colorspace == CMYKColorspace)
                pixel.index=gamma*MeshInterpolate(&delta,pixels[1].index,
                  pixels[0].index,pixels[3].index);
            }
        }
      else
        {
          /*
            Diagonal 1-2 NE-SW.
          */
          if (delta.x <= (1.0-delta.y))
            {
              /*
                Top-left triangle (pixel 0, diagonal: 1-2).
              */
              gamma=MeshInterpolate(&delta,alpha[0],alpha[1],alpha[2]);
              gamma=1.0/(fabs((double) gamma) <= MagickEpsilon ? 1.0 : gamma);
              pixel.red=gamma*MeshInterpolate(&delta,pixels[0].red,
                pixels[1].red,pixels[2].red);
              pixel.green=gamma*MeshInterpolate(&delta,pixels[0].green,
                pixels[1].green,pixels[2].green);
              pixel.blue=gamma*MeshInterpolate(&delta,pixels[0].blue,
                pixels[1].blue,pixels[2].blue);
              if (image->matte != MagickFalse)
                pixel.opacity=gamma*MeshInterpolate(&delta,pixels[0].opacity,
                  pixels[1].opacity,pixels[2].opacity);
              if (image->colorspace == CMYKColorspace)
                pixel.index=gamma*MeshInterpolate(&delta,pixels[0].index,
                  pixels[1].index,pixels[2].index);
            }
          else
            {
              /*
                Bottom-right triangle (pixel: 3, diagonal: 1-2).
              */
              delta.x=1.0-delta.x;
              delta.y=1.0-delta.y;
              gamma=MeshInterpolate(&delta,alpha[3],alpha[2],alpha[1]);
              gamma=1.0/(fabs((double) gamma) <= MagickEpsilon ? 1.0 : gamma);
              pixel.red=gamma*MeshInterpolate(&delta,pixels[3].red,
                pixels[2].red,pixels[1].red);
              pixel.green=gamma*MeshInterpolate(&delta,pixels[3].green,
                pixels[2].green,pixels[1].green);
              pixel.blue=gamma*MeshInterpolate(&delta,pixels[3].blue,
                pixels[2].blue,pixels[1].blue);
              if (image->matte != MagickFalse)
                pixel.opacity=gamma*MeshInterpolate(&delta,pixels[3].opacity,
                  pixels[2].opacity,pixels[1].opacity);
              if (image->colorspace == CMYKColorspace)
                pixel.index=gamma*MeshInterpolate(&delta,pixels[3].index,
                  pixels[2].index,pixels[1].index);
            }
        }
      break;
    }
    case NearestNeighborInterpolatePixel:
    {
      p=AcquireCacheView(image_view,NearestNeighbor(x),NearestNeighbor(y),1,1,
        exception);
      if (p == (const PixelPacket *) NULL)
        return(pixel);
      indexes=GetCacheViewIndexes(image_view);
      GetMagickPixelPacket(image,pixels);
      SetMagickPixelPacket(p,indexes,&pixel);
      break;
    }
  }
  return(pixel);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   M o d u l a t e H S B                                                     %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ModulateHSB() modulates the hue, saturation, and brightness of an image.
%
%  The format of the ModulateHSB method is:
%
%      void ModulateHSB(const double percent_hue,
%        const double percent_saturation,const double percent_brightness,
%        Quantum *red,Quantum *green,Quantum *blue)
%
%  A description of each parameter follows:
%
%    o percent_hue, percent_saturation, percent_brightness: A double value
%      representing the percent change in a component of the HSB color space.
%
%    o red, green, blue: A pointer to a pixel component of type Quantum.
%
*/
MagickExport void ModulateHSB(const double percent_hue,
  const double percent_saturation,const double percent_brightness,
  Quantum *red,Quantum *green,Quantum *blue)
{
  double
    brightness,
    hue,
    saturation;

  /*
    Increase or decrease color brightness, saturation, or hue.
  */
  assert(red != (Quantum *) NULL);
  assert(green != (Quantum *) NULL);
  assert(blue != (Quantum *) NULL);
  TransformHSB(*red,*green,*blue,&hue,&saturation,&brightness);
  hue+=0.5*(0.01*percent_hue-1.0);
  while (hue < 0.0)
    hue+=1.0;
  while (hue > 1.0)
    hue-=1.0;
  saturation*=0.01*percent_saturation;
  brightness*=0.01*percent_brightness;
  HSBTransform(hue,saturation,brightness,red,green,blue);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   M o d u l a t e H S L                                                     %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ModulateHSL() modulates the hue, saturation, and brightness of an image.
%
%  The format of the ModulateHSL method is:
%
%      void ModulateHSL(const double percent_hue,
%        const double percent_saturation,const double percent_luminosity,
%        Quantum *red,Quantum *green,Quantum *blue)
%
%  A description of each parameter follows:
%
%    o percent_hue, percent_saturation, percent_luminosity: A double value
%      representing the percent change in a component of the HSL color space.
%
%    o red, green, blue: A pointer to a pixel component of type Quantum.
%
*/
MagickExport void ModulateHSL(const double percent_hue,
  const double percent_saturation,const double percent_luminosity,
  Quantum *red,Quantum *green,Quantum *blue)
{
  double
    hue,
    luminosity,
    saturation;

  /*
    Increase or decrease color luminosity, saturation, or hue.
  */
  assert(red != (Quantum *) NULL);
  assert(green != (Quantum *) NULL);
  assert(blue != (Quantum *) NULL);
  TransformHSL(*red,*green,*blue,&hue,&saturation,&luminosity);
  hue+=0.5*(0.01*percent_hue-1.0);
  while (hue < 0.0)
    hue+=1.0;
  while (hue > 1.0)
    hue-=1.0;
  saturation*=0.01*percent_saturation;
  luminosity*=0.01*percent_luminosity;
  HSLTransform(hue,saturation,luminosity,red,green,blue);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   M o d u l a t e H W B                                                     %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ModulateHWB() modulates the hue, whiteness, and blackness of an image.
%
%  The format of the ModulateHWB method is:
%
%      void ModulateHWB(const double percent_hue,
%        const double percent_whiteness,const double percent_blackness,
%        Quantum *red,Quantum *green,Quantum *blue)
%
%  A description of each parameter follows:
%
%    o percent_hue, percent_whiteness, percent_blackness: A double value
%      representing the percent change in a component of the HWB color space.
%
%    o red, green, blue: A pointer to a pixel component of type Quantum.
%
*/
MagickExport void ModulateHWB(const double percent_hue,
  const double percent_whiteness,const double percent_blackness,
  Quantum *red,Quantum *green,Quantum *blue)
{
  double
    blackness,
    hue,
    whiteness;

  /*
    Increase or decrease color blackness, whiteness, or hue.
  */
  assert(red != (Quantum *) NULL);
  assert(green != (Quantum *) NULL);
  assert(blue != (Quantum *) NULL);
  TransformHWB(*red,*green,*blue,&hue,&whiteness,&blackness);
  hue+=0.5*(0.01*percent_hue-1.0);
  while (hue < 0.0)
    hue+=1.0;
  while (hue > 1.0)
    hue-=1.0;
  blackness*=0.01*percent_blackness;
  whiteness*=0.01*percent_whiteness;
  HWBTransform(hue,whiteness,blackness,red,green,blue);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   T r a n s f o r m H S B                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  TransformHSB() converts a (red, green, blue) to a (hue, saturation,
%  brightness) triple.
%
%  The format of the TransformHSB method is:
%
%      void TransformHSB(const Quantum red,const Quantum green,
%        const Quantum blue,double *hue,double *saturation,double *brightness)
%
%  A description of each parameter follows:
%
%    o red, green, blue: A Quantum value representing the red, green, and
%      blue component of a pixel..
%
%    o hue, saturation, brightness: A pointer to a double value representing a
%      component of the HSB color space.
%
*/
MagickExport void TransformHSB(const Quantum red,const Quantum green,
  const Quantum blue,double *hue,double *saturation,double *brightness)
{
  MagickRealType
    delta,
    max,
    min;

  /*
    Convert RGB to HSB colorspace.
  */
  assert(hue != (double *) NULL);
  assert(saturation != (double *) NULL);
  assert(brightness != (double *) NULL);
  max=(MagickRealType) (red > green ? red : green);
  if ((MagickRealType) blue > max)
    max=(MagickRealType) blue;
  min=(MagickRealType) (red < green ? red : green);
  if ((MagickRealType) blue < min)
    min=(MagickRealType) blue;
  *hue=0.0;
  *saturation=0.0;
  *brightness=(double) (QuantumScale*max);
  if (max == 0.0)
    return;
  *saturation=(double) (1.0-min/max);
  delta=max-min;
  if (delta == 0.0)
    return;
  if ((MagickRealType) red == max)
    *hue=(double) ((green-(MagickRealType) blue)/delta);
  else
    if ((MagickRealType) green == max)
      *hue=(double) (2.0+(blue-(MagickRealType) red)/delta);
    else
      *hue=(double) (4.0+(red-(MagickRealType) green)/delta);
  *hue/=6.0;
  if (*hue < 0.0)
    *hue+=1.0;
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   T r a n s f o r m H S L                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  TransformHSL() converts a (red, green, blue) to a (hue, saturation,
%  luminosity) triple.
%
%  The format of the TransformHSL method is:
%
%      void TransformHSL(const Quantum red,const Quantum green,
%        const Quantum blue,double *hue,double *saturation,double *luminosity)
%
%  A description of each parameter follows:
%
%    o red, green, blue: A Quantum value representing the red, green, and
%      blue component of a pixel..
%
%    o hue, saturation, luminosity: A pointer to a double value representing a
%      component of the HSL color space.
%
*/
MagickExport void TransformHSL(const Quantum red,const Quantum green,
  const Quantum blue,double *hue,double *saturation,double *luminosity)
{
  MagickRealType
    b,
    delta,
    g,
    max,
    min,
    r;

  /*
    Convert RGB to HSL colorspace.
  */
  assert(hue != (double *) NULL);
  assert(saturation != (double *) NULL);
  assert(luminosity != (double *) NULL);
  r=QuantumScale*red;
  g=QuantumScale*green;
  b=QuantumScale*blue;
  max=MagickMax(r,MagickMax(g,b));
  min=MagickMin(r,MagickMin(g,b));
  *hue=0.0;
  *saturation=0.0;
  *luminosity=(double) ((min+max)/2.0);
  delta=max-min;
  if (delta == 0.0)
    return;
  *saturation=(double) (delta/((*luminosity < 0.5) ? (min+max) :
    (2.0-max-min)));
  if (r == max)
    *hue=(double) (g == min ? 5.0+(max-b)/delta : 1.0-(max-g)/delta);
  else
    if (g == max)
      *hue=(double) (b == min ? 1.0+(max-r)/delta : 3.0-(max-b)/delta);
    else
      *hue=(double) (r == min ? 3.0+(max-g)/delta : 5.0-(max-r)/delta);
  *hue/=6.0;
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%   T r a n s f o r m H W B                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  TransformHWB() converts a (red, green, blue) to a (hue, whiteness,
%  blackness) triple.
%
%  The format of the TransformHWB method is:
%
%      void TransformHWB(const Quantum red,const Quantum green,
%        const Quantum blue,double *hue,double *whiteness,double *blackness)
%
%  A description of each parameter follows:
%
%    o red, green, blue: A Quantum value representing the red, green, and
%      blue component of a pixel.
%
%    o hue, whiteness, blackness: A pointer to a double value representing a
%      component of the HWB color space.
%
*/
MagickExport void TransformHWB(const Quantum red,const Quantum green,
  const Quantum blue,double *hue,double *whiteness,double *blackness)
{
  MagickRealType
    f;

  register long
    i;

  Quantum
    v,
    w;

  /*
    Convert RGB to HWB colorspace.
  */
  assert(hue != (double *) NULL);
  assert(whiteness != (double *) NULL);
  assert(blackness != (double *) NULL);
  w=RoundToQuantum(MagickMin((double) red,MagickMin((double) green,(double)
    blue)));
  v=RoundToQuantum(MagickMax((double) red,MagickMax((double) green,(double)
    blue)));
  *blackness=(double) (QuantumRange-v)/(double) QuantumRange;
  if (v == w)
    {
      *hue=0.0;
      *whiteness=1.0-(*blackness);
      return;
    }
  f=(red == w) ? (MagickRealType) green-blue : ((green == w) ?
    (MagickRealType) blue-red : (MagickRealType) red-green);
  i=(red == w) ? 3 : ((green == w) ? 5 : 1);
  *hue=(double) (i-f/(v-w));
  *whiteness=(double) w/(double) QuantumRange;
}
