/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                     L       AAA   Y   Y  EEEEE  RRRR                        %
%                     L      A   A   Y Y   E      R   R                       %
%                     L      AAAAA    Y    EEE    RRRR                        %
%                     L      A   A    Y    E      R R                         %
%                     LLLLL  A   A    Y    EEEEE  R  R                        %
%                                                                             %
%                     ImageMagick Image Layering Methods                      %
%                                                                             %
%                              Software Design                                %
%                                John Cristy                                  %
%                              Anthony Thyssen                                %
%                               January 2006                                  %
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
#include "magick/studio.h"
#include "magick/property.h"
#include "magick/color.h"
#include "magick/color-private.h"
#include "magick/composite.h"
#include "magick/effect.h"
#include "magick/exception.h"
#include "magick/exception-private.h"
#include "magick/geometry.h"
#include "magick/image.h"
#include "magick/layer.h"
#include "magick/list.h"
#include "magick/memory_.h"
#include "magick/monitor.h"
#include "magick/pixel-private.h"
#include "magick/profile.h"
#include "magick/resource_.h"
#include "magick/resize.h"
#include "magick/statistic.h"
#include "magick/string_.h"
#include "magick/transform.h"

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
+     C l e a r B o u n d s                                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ClearBounds() Clear the area specified by the bounds in an image to
%  transparency.  This is typically used to handle Background Disposal
%  for the previous frame in an animation sequence.
%
%  WARNING: no bounds checks are performed, except for the null or
%  missed image, for images that don't change. in all other cases
%  bound must fall within the image.
%
%  The format is:
%
%      void ClearBounds(Image *image,RectangleInfo *bounds)
%
%  A description of each parameter follows:
%
%    o image: The image to had the area cleared in
%
%    o bounds: the area to be clear within the imag image
%
*/
static void ClearBounds(Image *image,RectangleInfo *bounds)
{
  long
    y;

  register long
    x;

  register PixelPacket
    *q;

  if ( bounds->x < 0 ) return;

  for (y=0; y < (long) bounds->height; y++)
  {
    q=GetImagePixels(image,bounds->x,bounds->y+y,bounds->width,1);
    if (q == (PixelPacket *) NULL)
      break;
    for (x=0; x < (long) bounds->width; x++)
    {
      q->opacity=TransparentOpacity;
      q++;
    }
    if (SyncImagePixels(image) == MagickFalse)
      break;
  }
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
+     I s B o u n d s C l e a r e d                                           %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  IsBoundsCleared() tests whether any pixel in the bounds given, gets cleared
%  when going from the first image to the second image.  This is typically used
%  to check if a proposed disposal method will work successfully to generate
%  the second frame image from the first disposed form of the previous frame.
%
%  The format is:
%
%      MagickBooleanType IsBoundsCleared(const Image *image1,
%        const Image *image2,RectangleInfo bounds,ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image1, image 2: The images to check for cleared pixels
%
%    o bounds: the area to be clear within the imag image
%
%    o exception: Return any errors or warnings in this structure.
%
%  WARNING: no bounds checks are performed, except for the null or
%  missed image, for images that don't change. in all other cases
%  bound must fall within the image.
%
*/
static MagickBooleanType IsBoundsCleared(const Image *image1,
  const Image *image2,RectangleInfo *bounds,ExceptionInfo *exception)
{
  long
    y;

  register long
    x;

  register const PixelPacket
    *p,
    *q;

  if ( bounds->x< 0 ) return(MagickFalse);

  for (y=0; y < (long) bounds->height; y++)
  {
    p=AcquireImagePixels(image1,bounds->x,bounds->y+y,bounds->width,1,
        exception);
    q=AcquireImagePixels(image2,bounds->x,bounds->y+y,bounds->width,1,
        exception);
    if ((p == (const PixelPacket *) NULL) || (q == (PixelPacket *) NULL))
      break;
    for (x=0; x < (long) bounds->width; x++)
    {
      if (((double) p->opacity <= (QuantumRange/2.0)) &&
          ((double) q->opacity > (QuantumRange/2.0)))
        break;
      p++;
      q++;
    }
    if (x < (long) bounds->width)
      break;
  }
  return(y < (long) bounds->height ? MagickTrue : MagickFalse);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%     C o a l e s c e I m a g e s                                             %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  CoalesceImages() composites a set of images while respecting any page
%  offsets and disposal methods.  GIF, MIFF, and MNG animation sequences
%  typically start with an image background and each subsequent image
%  varies in size and offset.  CoalesceImages() returns a new sequence
%  where each image in the sequence is the same size as the first and
%  composited with the next image in the sequence.
%
%  The format of the CoalesceImages method is:
%
%      Image *CoalesceImages(Image *image,ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image: The image sequence.
%
%    o exception: Return any errors or warnings in this structure.
%
*/
MagickExport Image *CoalesceImages(Image *image,ExceptionInfo *exception)
{
  Image
    *coalesce_image;

  Image
    *dispose_image;

  register Image
    *next;

  RectangleInfo
    bounds;

  /*
    Coalesce the image sequence.
  */
  assert(image != (Image *) NULL);
  assert(image->signature == MagickSignature);
  if (image->debug != MagickFalse)
    (void) LogMagickEvent(TraceEvent,GetMagickModule(),"%s",image->filename);
  assert(exception != (ExceptionInfo *) NULL);
  assert(exception->signature == MagickSignature);
  coalesce_image=CloneImage(image,image->page.width,image->page.height,
    MagickTrue,exception);
  if (coalesce_image == (Image *) NULL)
    return((Image *) NULL);
  coalesce_image->page=image->page;
  coalesce_image->page.x=0;
  coalesce_image->page.y=0;
  coalesce_image->dispose=NoneDispose;
  coalesce_image->background_color.opacity=TransparentOpacity;
  (void) SetImageBackgroundColor(coalesce_image);
  dispose_image=CloneImage(coalesce_image,0,0,MagickTrue,exception);
  (void) CompositeImage(coalesce_image,CopyCompositeOp,image,image->page.x,
    image->page.y);
  next=GetNextImageInList(image);
  for ( ; next != (Image *) NULL; next=GetNextImageInList(next))
  {
    /*
      Determine the bounds that was overlaid in the previous image.
    */
    bounds=GetPreviousImageInList(next)->page;
    bounds.width=GetPreviousImageInList(next)->columns;
    bounds.height=GetPreviousImageInList(next)->rows;
    if (bounds.x < 0)
      {
        bounds.width+=bounds.x;
        bounds.x=0;
      }
    if ((long) (bounds.x+bounds.width) > (long) coalesce_image->columns)
      bounds.width=coalesce_image->columns-bounds.x;
    if (bounds.y < 0)
      {
        bounds.height+=bounds.y;
        bounds.y=0;
      }
    if ((long) (bounds.y+bounds.height) > (long) coalesce_image->rows)
      bounds.height=coalesce_image->rows-bounds.y;
    /*
      Replace the dispose image with the new coalesced image.
    */
    if (GetPreviousImageInList(next)->dispose != PreviousDispose)
      {
        dispose_image=DestroyImage(dispose_image);
        dispose_image=CloneImage(coalesce_image,0,0,MagickTrue,exception);
        if (dispose_image == (Image *) NULL)
          {
            coalesce_image=DestroyImageList(coalesce_image);
            return((Image *) NULL);
          }
      }
    /*
      Clear the overlaid area of the coalesced bounds for background disposal
    */
    if (next->previous->dispose == BackgroundDispose)
      ClearBounds(dispose_image, &bounds);
    /*
      Next image is the dispose image, overlaid with next frame in sequence.
    */
    coalesce_image->next=CloneImage(dispose_image,0,0,MagickTrue,exception);
    coalesce_image->next->previous=coalesce_image;
    coalesce_image=GetNextImageInList(coalesce_image);
    coalesce_image->matte=MagickTrue;
    (void) CompositeImage(coalesce_image,next->matte != MagickFalse ?
      OverCompositeOp : CopyCompositeOp,next,next->page.x,next->page.y);
    (void) CloneImageProperties(coalesce_image,next);
    (void) CloneImageProfiles(coalesce_image,next);
    coalesce_image->page.x=0;
    coalesce_image->page.y=0;
    /*
      Fix disposal setting of previous image, for correct animation.
      If pixel goes opaque to transparent, use background dispose.
      For both previous and current image.
    */
    if (IsBoundsCleared(GetPreviousImageInList(coalesce_image),
         coalesce_image,&bounds,exception) )
      coalesce_image->dispose=BackgroundDispose;
    else
      coalesce_image->dispose=NoneDispose;
    GetPreviousImageInList(coalesce_image)->dispose=coalesce_image->dispose;
  }
  dispose_image=DestroyImage(dispose_image);
  return(GetFirstImageInList(coalesce_image));
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%     D i s p o s e I m a g e s                                               %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  DisposeImages() returns the coalesced frames of a GIF animation as it would
%  appear after the GIF dispose method of that frame has been applied.  That
%  is it returned the appearance of each frame before the next is overlaid.
%
%  The format of the DisposeImages method is:
%
%      Image *DisposeImages(Image *image,ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image: The image sequence.
%
%    o exception: Return any errors or warnings in this structure.
%
*/
MagickExport Image *DisposeImages(Image *image,ExceptionInfo *exception)
{
  Image
    *current,
    *previous_image,
    *dispose_images;

  register Image
    *next;

  /*
    Run the image through the animation sequence
  */
  assert(image != (Image *) NULL);
  assert(image->signature == MagickSignature);
  if (image->debug != MagickFalse)
    (void) LogMagickEvent(TraceEvent,GetMagickModule(),"%s",image->filename);
  assert(exception != (ExceptionInfo *) NULL);
  assert(exception->signature == MagickSignature);
  previous_image=CloneImage(image,image->page.width,image->page.height,
    MagickTrue,exception);
  if (previous_image == (Image *) NULL)
    return((Image *) NULL);
  previous_image->page=image->page;
  previous_image->page.x=0;
  previous_image->page.y=0;
  previous_image->dispose=NoneDispose;
  previous_image->background_color.opacity=TransparentOpacity;
  (void) SetImageBackgroundColor(previous_image);
  current=CloneImage(previous_image,0,0,MagickTrue,exception);
  dispose_images=NewImageList();
  for (next=image; next != (Image *) NULL; next=GetNextImageInList(next))
  {
    /*
      Overlay this frame's image over the previous frames image
    */
    (void) CompositeImage(current,
        next->matte != MagickFalse ? OverCompositeOp : CopyCompositeOp,
        next,next->page.x,next->page.y);
    /*
      At this point the image would be displayed, for the delay period
    **
      Handle Background dispose
    */
    if (next->dispose == BackgroundDispose)
      {
        RectangleInfo
          bounds=next->page;

        bounds.width=next->columns;
        bounds.height=next->rows;
        if (bounds.x < 0)
          {
            bounds.width+=bounds.x;
            bounds.x=0;
          }
        if ((long) (bounds.x+bounds.width) > (long) current->columns)
          bounds.width=current->columns-bounds.x;
        if (bounds.y < 0)
          {
            bounds.height+=bounds.y;
            bounds.y=0;
          }
        if ((long) (bounds.y+bounds.height) > (long) current->rows)
          bounds.height=current->rows-bounds.y;
        ClearBounds(current, &bounds);
      }
    /*
      Handle Previous dispose (restore from previous, or replace previous)
    */
    if (next->dispose == PreviousDispose)
      {
        current=DestroyImage(current);
        current=CloneImage(previous_image,0,0,MagickTrue,exception);
        if (current == (Image *) NULL)
          {
            dispose_images=DestroyImageList(dispose_images);
            previous_image=DestroyImage(previous_image);
            return((Image *) NULL);
          }
      }
    else
      {
        previous_image=DestroyImage(previous_image);
        previous_image=CloneImage(current,0,0,MagickTrue,exception);
        if (previous_image == (Image *) NULL)
          {
            dispose_images=DestroyImageList(dispose_images);
            current=DestroyImage(current);
            return((Image *) NULL);
          }
      }
    /*
      Save the dispose image as the resultant image for this frame
    */
    { Image *dispose=CloneImage(current,0,0,MagickTrue,exception);
      if (dispose == (Image *) NULL)
        {
          dispose_images=DestroyImageList(dispose_images);
          previous_image=DestroyImage(previous_image);
          return((Image *) NULL);
        }
      (void) CloneImageProperties(dispose,next);
      (void) CloneImageProfiles(dispose,next);
      dispose->page.x=0;
      dispose->page.y=0;
      dispose->dispose=next->dispose;
      AppendImageToList(&dispose_images,dispose);
    }
  }
  previous_image=DestroyImage(previous_image);
  current=DestroyImage(current);
  return(GetFirstImageInList(dispose_images));
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
+     C o m p a r e P i x e l s                                               %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ComparePixels() Compare the two pixels and return true if the pixels
%  differ according to the given LayerType comparision method.
%
%  This is currently only used internally by CompareImageBounds(). It is
%  doubtful that this sub-routine will be useful outside this module.
%
%  The format of the ComparePixels method is:
%
%      MagickBooleanType *ComparePixels(const MagickLayerMethod method,
%        const MagickPixelPacket *p,const MagickPixelPacket *q)
%
%  A description of each parameter follows:
%
%    o method: What differences to look for. Must be one of
%              CompareAnyLayer, CompareClearLayer, CompareOverlayLayer.
%
%    o p, q: The pixels to test for appropriate differences.
%
*/

static MagickBooleanType ComparePixels(const MagickLayerMethod method,
  const MagickPixelPacket *p,const MagickPixelPacket *q)
{
  MagickRealType
    o1,
    o2;

  /*
    Any change in pixel values
  */
  if (method == CompareAnyLayer)
    return(IsMagickColorSimilar(p,q) == MagickFalse ? MagickTrue : MagickFalse);

  o1 = (p->matte != MagickFalse) ? p->opacity : OpaqueOpacity;
  o2 = (q->matte != MagickFalse) ? q->opacity : OpaqueOpacity;

  /*
    Pixel goes from opaque to transprency
  */
  if (method == CompareClearLayer)
    return((MagickBooleanType)
           ( (o1 <= (QuantumRange/2.0)) && (o2 > (QuantumRange/2.0)) ) );

  /*
    overlay would change first pixel by second
  */
  if (method == CompareOverlayLayer)
    {
      if (o2 > (QuantumRange/2.0))
        return MagickFalse;
      return((MagickBooleanType) (IsMagickColorSimilar(p,q) == MagickFalse));
    }
  return(MagickFalse);
}


/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
+     C o m p a r e I m a g e B o u n d s                                     %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  CompareImageBounds() Given two images return the smallest rectangular area
%  by which the two images differ, accourding to the given 'Compare...'
%  layer method.
%
%  This is currently only used internally in this module, but may eventually
%  be used by other modules.
%
%  The format of the CompareImageBounds method is:
%
%      RectangleInfo *CompareImageBounds(const MagickLayerMethod method,
%        const Image *image1, const Image *image2, ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o method: What differences to look for. Must be one of
%              CompareAnyLayer, CompareClearLayer, CompareOverlayLayer.
%
%    o image1, image2: The two images to compare.
%
%    o exception: Return any errors or warnings in this structure.
%
*/

static RectangleInfo CompareImageBounds(const Image *image1,const Image *image2,
  const MagickLayerMethod method,ExceptionInfo *exception)
{
  RectangleInfo
    bounds;

  register IndexPacket
    *indexes1,
    *indexes2;

  MagickPixelPacket
    pixel1,
    pixel2;

  register const PixelPacket
    *p,
    *q;

  long
    y;

  register long
    x;

  /*
    Set bounding box of the differences between images
  */
  GetMagickPixelPacket(image1,&pixel1);
  GetMagickPixelPacket(image2,&pixel2);
  for (x=0; x < (long) image1->columns; x++)
  {
    p=AcquireImagePixels(image1,x,0,1,image1->rows,exception);
    q=AcquireImagePixels(image2,x,0,1,image2->rows,exception);
    if ((p == (const PixelPacket *) NULL) ||
        (q == (const PixelPacket *) NULL))
      break;
    indexes1=GetIndexes(image1);
    indexes2=GetIndexes(image2);
    for (y=0; y < (long) image1->rows; y++)
    {
      SetMagickPixelPacket(p,indexes1+x,&pixel1);
      SetMagickPixelPacket(q,indexes2+x,&pixel2);
      if (ComparePixels(method,&pixel1,&pixel2))
        break;
      p++;
      q++;
    }
    if (y < (long) image1->rows)
      break;
  }
  if ( x >= (long) image1->columns) {
    /*
      Images are identical! - No need to look further
      Result in the null 'miss' image.
    */
    bounds.x=-1;
    bounds.y=-1;
    bounds.width=1;
    bounds.height=1;
    return(bounds);
  }
  bounds.x=x;
  for (x=(long) image1->columns-1; x >= 0; x--)
  {
    p=AcquireImagePixels(image1,x,0,1,image1->rows,exception);
    q=AcquireImagePixels(image2,x,0,1,image2->rows,exception);
    if ((p == (const PixelPacket *) NULL) ||
        (q == (const PixelPacket *) NULL))
      break;
    indexes1=GetIndexes(image1);
    indexes2=GetIndexes(image2);
    for (y=0; y < (long) image1->rows; y++)
    {
      SetMagickPixelPacket(p,indexes1+x,&pixel1);
      SetMagickPixelPacket(q,indexes2+x,&pixel2);
      if (ComparePixels(method,&pixel1,&pixel2))
        break;
      p++;
      q++;
    }
    if (y < (long) image1->rows)
      break;
  }
  bounds.width=(unsigned long) (x-bounds.x+1);
  for (y=0; y < (long) image1->rows; y++)
  {
    p=AcquireImagePixels(image1,0,y,image1->columns,1,exception);
    q=AcquireImagePixels(image2,0,y,image2->columns,1,exception);
    if ((p == (const PixelPacket *) NULL) ||
        (q == (const PixelPacket *) NULL))
      break;
    indexes1=GetIndexes(image1);
    indexes2=GetIndexes(image2);
    for (x=0; x < (long) image1->columns; x++)
    {
      SetMagickPixelPacket(p,indexes1+x,&pixel1);
      SetMagickPixelPacket(q,indexes2+x,&pixel2);
      if (ComparePixels(method,&pixel1,&pixel2))
        break;
      p++;
      q++;
    }
    if (x < (long) image1->columns)
      break;
  }
  bounds.y=y;
  for (y=(long) image1->rows-1; y >= 0; y--)
  {
    p=AcquireImagePixels(image1,0,y,image1->columns,1,exception);
    q=AcquireImagePixels(image2,0,y,image2->columns,1,exception);
    if ((p == (const PixelPacket *) NULL) ||
        (q == (const PixelPacket *) NULL))
      break;
    indexes1=GetIndexes(image1);
    indexes2=GetIndexes(image2);
    for (x=0; x < (long) image1->columns; x++)
    {
      SetMagickPixelPacket(p,indexes1+x,&pixel1);
      SetMagickPixelPacket(q,indexes2+x,&pixel2);
      if (ComparePixels(method,&pixel1,&pixel2))
        break;
      p++;
      q++;
    }
    if (x < (long) image1->columns)
      break;
  }
  bounds.height=(unsigned long) (y-bounds.y+1);
  return(bounds);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%     C o m p a r e I m a g e L a y e r s                                     %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  CompareImageLayers() compares each image with the next in a sequence and
%  returns the minimum bounding region of all the pixel differences (of the
%  LayerType specified) it discovers.
%
%  Images do NOT have to be the same size, though it is best that all the
%  images are 'coalesced' (images are all the same size, on a flattened
%  canvas, so as to represent exactly how an specific frame should look).
%
%  No GIF dispose methods are applied, so GIF animations must be coalesced
%  before applying this image operator to find differences to them.
%
%  The format of the CompareImageLayers method is:
%
%      Image *CompareImageLayers(const Image *images,
%        const MagickLayerMethod method,ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image: The image.
%
%    o method: The layers type to compare images with. Must be one of...
%              CompareAnyLayer, CompareClearLayer, CompareOverlayLayer.
%
%    o exception: Return any errors or warnings in this structure.
%
*/

MagickExport Image *CompareImageLayers(const Image *image,
  const MagickLayerMethod method, ExceptionInfo *exception)
{
  Image
    *image_a,
    *image_b,
    *layers;

  RectangleInfo
    *bounds;

  register const Image
    *next;

  register long
    i;

  assert(image != (const Image *) NULL);
  assert(image->signature == MagickSignature);
  if (image->debug != MagickFalse)
    (void) LogMagickEvent(TraceEvent,GetMagickModule(),"%s",image->filename);
  assert(exception != (ExceptionInfo *) NULL);
  assert(exception->signature == MagickSignature);
  assert(method == CompareAnyLayer ||
         method == CompareClearLayer ||
         method == CompareOverlayLayer);
#if 0
  /*
    Ensure the image are the same size
  */
  for (next=image; next != (Image *) NULL; next=GetNextImageInList(next))
  {
    if ((next->columns != image->columns) || (next->rows != image->rows))
      ThrowImageException(OptionError,"ImagesAreNotTheSameSize");
    /*
      FUTURE: also check they are also fully coalesced (full page settings)
    */
  }
#endif
  /*
    Allocate bounds memory.
  */
  bounds=(RectangleInfo *) AcquireMagickMemory((size_t) (GetImageListLength(
    image)-1)*sizeof(*bounds));
  if (bounds == (RectangleInfo *) NULL)
    ThrowImageException(ResourceLimitError,"MemoryAllocationFailed");
  /*
    Set up first comparision images.
  */
  image_a=CloneImage(image,image->page.width,image->page.height,
    MagickTrue,exception);
  if (image_a == (Image *) NULL)
    {
      bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
      return((Image *) NULL);
    }
  image_a->background_color.opacity=TransparentOpacity;
  (void) SetImageBackgroundColor(image_a);
  image_a->page=image->page;
  image_a->page.x=0;
  image_a->page.y=0;
  (void) CompositeImage(image_a,CopyCompositeOp,image,image->page.x,image->page.y);
  /*
    Compute the bounding box of changes for the later images
  */
  i=0;
  next=GetNextImageInList(image);
  for ( ; next != (const Image *) NULL; next=GetNextImageInList(next))
  {
    image_b=CloneImage(image_a,0,0,MagickTrue,exception);
    if (image_b == (Image *) NULL)
      {
        image_a=DestroyImage(image_a);
        bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
        return((Image *) NULL);
      }
    (void) CompositeImage(image_a,CopyCompositeOp,next,next->page.x,
                           next->page.y);
    bounds[i]=CompareImageBounds(image_b,image_a,method,exception);

    image_b=DestroyImage(image_b);
    i++;
  }
  image_a=DestroyImage(image_a);
  /*
    Clone first image in sequence.
  */
  layers=CloneImage(image,0,0,MagickTrue,exception);
  if (layers == (Image *) NULL)
    {
      bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
      return((Image *) NULL);
    }
  /*
    Deconstruct the image sequence.
  */
  i=0;
  next=GetNextImageInList(image);
  for ( ; next != (const Image *) NULL; next=GetNextImageInList(next))
  {
    image_a=CloneImage(next,0,0,MagickTrue,exception);
    if (image_a == (Image *) NULL)
      break;
    image_b=CropImage(image_a,&bounds[i],exception);
    image_a=DestroyImage(image_a);
    if (image_b == (Image *) NULL)
      break;
    AppendImageToList(&layers,image_b);
    i++;
  }
  bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
  if (next != (Image *) NULL)
    {
      layers=DestroyImageList(layers);
      return((Image *) NULL);
    }
  return(GetFirstImageInList(layers));
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%     D e c o n s t r u c t I m a g e s                                       %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  DeconstructImages() compares each image with the next in a sequence and
%  returns the minimum bounding region of all differences from the first image.
%
%
%  The format of the CompareImageLayers method is:
%
%      Image *DeconstructImages(const Image *images, ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image: The image.
%
%    o exception: Return any errors or warnings in this structure.
%
*/

MagickExport Image *DeconstructImages(const Image *images,
  ExceptionInfo *exception)
{
  return(CompareImageLayers(images,CompareAnyLayer,exception));
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
+     O p t i m i z e L a y e r F r a m e s                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  OptimizeLayerFrames() compares each image the GIF disposed forms of the
%  previous image in the sequence.  From this it attempts to select the
%  smallest cropped image to replace each frame, while preserving the results
%  of the animation.
%
%  Note that this is not easy, and may require the expandsion of the bounds
%  of previous frame, to clear pixels for the next animation frame,
%  using GIF Background Dispose method.
%
%  Currently this is only used internally, with external wrappers below.
%
%  The format of the OptimizeLayerFrames method is:
%
%      static Image *OptimizeLayerFrames(const Image *image,
%               const MagickLayerMethod method, ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image: The image.
%
%    o method: The layers type to optimize with. Must be one of...
%             OptimizeLayer, or  OptimizePlusLayer
%
%    o exception: Return any errors or warnings in this structure.
%
*/
/*
  Define a 'fake' dispose method where the frame is duplicated, with a
  extra zero time delay frame which does a BackgroundDisposal to clear the
  pixels that need to be cleared.
*/
#define DupDispose  ((DisposeType)9)
/*
  Another 'fake' dispose method used to removed frames that don't change.
*/
#define DelDispose  ((DisposeType)8)

static Image *OptimizeLayerFrames(const Image *image,
  const MagickLayerMethod method, ExceptionInfo *exception)
{
  Image
    *prev_image,
    *dup_image,
    *bgnd_image,
    *optimized_image;

  RectangleInfo
    try_bounds,
    bgnd_bounds,
    dup_bounds,
    *bounds;

  MagickBooleanType
    add_frames,
    try_cleared,
    cleared;

  DisposeType
    *disposals;

  register const Image
    *next;

  register long
    i;

  assert(image != (const Image *) NULL);
  assert(image->signature == MagickSignature);
  if (image->debug != MagickFalse)
    (void) LogMagickEvent(TraceEvent,GetMagickModule(),"%s",image->filename);
  assert(exception != (ExceptionInfo *) NULL);
  assert(exception->signature == MagickSignature);
  assert(method == OptimizeLayer ||
         method == OptimizePlusLayer);

  /*
    are we allowed to add/remove frames from animation
  */
  add_frames=method == OptimizePlusLayer ? MagickTrue : MagickFalse;
  /*
    Ensure  all the images are the same size
  */
  for (next=image; next != (Image *) NULL; next=GetNextImageInList(next))
  {
    if ((next->columns != image->columns) || (next->rows != image->rows))
      ThrowImageException(OptionError,"ImagesAreNotTheSameSize");
    /*
      FUTURE: also check they are fully coalesced (full page settings)
    */
  }
  /*
    Allocate memory (times 2 if we allow frame additions)
  */
  bounds=(RectangleInfo *) AcquireMagickMemory((size_t)
    GetImageListLength(image)*sizeof(*bounds)*(add_frames?2:1));
  if (bounds == (RectangleInfo *) NULL)
    ThrowImageException(ResourceLimitError,"MemoryAllocationFailed");
  disposals=(DisposeType *) AcquireMagickMemory((size_t)
    GetImageListLength(image)*sizeof(*disposals)*(add_frames?2:1));
  if (disposals == (DisposeType *) NULL)
    {
      bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
      ThrowImageException(ResourceLimitError,"MemoryAllocationFailed");
    }
  /*
    Initialise Previous Image as fully transparent
  */
  prev_image=CloneImage(image,image->page.width,image->page.height,
    MagickTrue,exception);
  if (prev_image == (Image *) NULL)
    {
      bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
      disposals=(DisposeType *) RelinquishMagickMemory(disposals);
      return((Image *) NULL);
    }
  prev_image->page=image->page;  /* ERROR: <-- should not be need, but is! */
  prev_image->page.x=0;
  prev_image->page.y=0;
  prev_image->dispose=NoneDispose;

  prev_image->background_color.opacity=TransparentOpacity;
  (void) SetImageBackgroundColor(prev_image);
  /*
    Figure out the area of overlay of the first frame
    No pixel could be cleared as all pixels are already cleared.
  */
  disposals[0]=NoneDispose;
  bounds[0]=CompareImageBounds(prev_image,image,CompareAnyLayer,exception);
  /*
    Compute the bounding box of changes for each pair of images.
  */
  i=1;
  bgnd_image=(Image *)NULL;
  dup_image=(Image *)NULL;
  dup_bounds.width=0;
  dup_bounds.height=0;
  dup_bounds.x=0;
  dup_bounds.y=0;
  next=GetNextImageInList(image);
  for ( ; next != (const Image *) NULL; next=GetNextImageInList(next))
  {
    /*
      Assume none disposal is the best
    */
    bounds[i]=CompareImageBounds(next->previous,next,CompareAnyLayer,exception);
    cleared=IsBoundsCleared(next->previous,next,&bounds[i],exception);
    disposals[i-1]=NoneDispose;
    if ( bounds[i].x < 0 ) {
      /*
        Image frame is exactly the same as the previous frame!
        If not adding frames Leave it to  be cropped down to a null image.
        Otherwise mark previous image for deleted, transfering its crop bounds
        to the current image.
      */
      if ( add_frames && i>=2 ) {
        disposals[i-1]=DelDispose;
        disposals[i]=NoneDispose;
        bounds[i]=bounds[i-1];
        i++;
        continue;
      }
    }
    else
      {
        /*
          Compare a none disposal against a previous disposal
        */
        try_bounds=CompareImageBounds(prev_image,next,CompareAnyLayer,exception);
        try_cleared=IsBoundsCleared(prev_image,next,&try_bounds,exception);
        if ( (!try_cleared && cleared ) ||
                try_bounds.width * try_bounds.height
                    <  bounds[i].width * bounds[i].height )
          {
            cleared=try_cleared;
            bounds[i]=try_bounds;
            disposals[i-1]=PreviousDispose;
          }

        /*
          If we are allowed lets try a complex frame duplication.
          It is useless if the previous frame already clears pixels correctly.
          This method will always clear all the pixels that need to be cleared.
        */
        dup_bounds.width=dup_bounds.height=0;
        if ( add_frames )
          {
            dup_image=CloneImage(next->previous,image->page.width,
                image->page.height,MagickTrue,exception);
            if (dup_image == (Image *) NULL)
              {
                bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
                disposals=(DisposeType *) RelinquishMagickMemory(disposals);
                prev_image=DestroyImage(prev_image);
                return((Image *) NULL);
              }
            dup_bounds=CompareImageBounds(dup_image,next,CompareClearLayer,exception);
            ClearBounds(dup_image,&dup_bounds);
            try_bounds=CompareImageBounds(dup_image,next,CompareAnyLayer,exception);
            if ( cleared ||
                   dup_bounds.width*dup_bounds.height
                      +try_bounds.width*try_bounds.height
                   < bounds[i].width * bounds[i].height )
              {
                cleared=MagickFalse;
                bounds[i]=try_bounds;
                disposals[i-1]=DupDispose;
                /* to be finalised later, if found to be optimial */
              }
            else
              dup_bounds.width=dup_bounds.height=0;
          }

        /*
          Now compare against a simple background disposal
        */
        bgnd_image=CloneImage(next->previous,image->page.width,
          image->page.height,MagickTrue,exception);
        if (bgnd_image == (Image *) NULL)
          {
            bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
            disposals=(DisposeType *) RelinquishMagickMemory(disposals);
            prev_image=DestroyImage(prev_image);
            if ( disposals[i-1] == DupDispose )
              bgnd_image=DestroyImage(bgnd_image);
            return((Image *) NULL);
          }
        bgnd_bounds=bounds[i-1];
        ClearBounds(bgnd_image,&bgnd_bounds);
        try_bounds=CompareImageBounds(bgnd_image,next,CompareAnyLayer,exception);
        try_cleared=IsBoundsCleared(bgnd_image,next,&try_bounds,exception);
        if ( try_cleared )
          {
            /*
              Straight background disposal failed to clear pixels needed!
              Lets try expanding the disposal area of the previous frame, to
              include the pixels that are cleared.  This is guaranteed
              to work, though may not be the most optimized solution.
            */
            try_bounds=CompareImageBounds(prev_image,next,CompareClearLayer,exception);
            if ( bgnd_bounds.x < 0 )
              bgnd_bounds = try_bounds;
            else
              {
                if ( try_bounds.x < bgnd_bounds.x )
                  {
                     bgnd_bounds.width+= bgnd_bounds.x-try_bounds.x;
                     if ( bgnd_bounds.width < try_bounds.width )
                       bgnd_bounds.width = try_bounds.width;
                     bgnd_bounds.x = try_bounds.x;
                  }
                else
                  {
                     try_bounds.width += try_bounds.x - bgnd_bounds.x;
                     if ( bgnd_bounds.width < try_bounds.width )
                       bgnd_bounds.width = try_bounds.width;
                  }
                if ( try_bounds.y < bgnd_bounds.y )
                  {
                     bgnd_bounds.height += bgnd_bounds.y - try_bounds.y;
                     if ( bgnd_bounds.height < try_bounds.height )
                       bgnd_bounds.height = try_bounds.height;
                     bgnd_bounds.y = try_bounds.y;
                  }
                else
                  {
                    try_bounds.height += try_bounds.y - bgnd_bounds.y;
                     if ( bgnd_bounds.height < try_bounds.height )
                       bgnd_bounds.height = try_bounds.height;
                  }
              }
            ClearBounds(bgnd_image,&bgnd_bounds);
            try_bounds=CompareImageBounds(bgnd_image,next,CompareAnyLayer,exception);
          }
        /*
          Test if this background dispose is smaller than any of the
          other methods we tryed before this (including duplicated frame)
        */
        if ( cleared ||
              bgnd_bounds.width*bgnd_bounds.height
                +try_bounds.width*try_bounds.height
              < bounds[i-1].width*bounds[i-1].height
                  +dup_bounds.width*dup_bounds.height
                  +bounds[i].width*bounds[i].height )
          {
            cleared=MagickFalse;
            bounds[i-1]=bgnd_bounds;
            bounds[i]=try_bounds;
            if ( disposals[i-1] == DupDispose )
              dup_image=DestroyImage(dup_image);
            disposals[i-1]=BackgroundDispose;
          }
      }
    /*
       Finalise choice of dispose, set new prev_image,
       and junk any extra images as appropriate,
    */
    if ( disposals[i-1] == DupDispose )
      {
         if (bgnd_image != (Image *) NULL)
           bgnd_image=DestroyImage(bgnd_image);
         prev_image=DestroyImage(prev_image);
         prev_image=dup_image, dup_image=(Image *) NULL;
         bounds[i+1]=bounds[i];
         bounds[i]=dup_bounds;
         disposals[i-1]=DupDispose;
         disposals[i]=BackgroundDispose;
         i++;
      }
    else
      {
        if ( disposals[i-1] != PreviousDispose )
          prev_image=DestroyImage(prev_image);
        if ( disposals[i-1] == BackgroundDispose )
          prev_image=bgnd_image,  bgnd_image=(Image *)NULL;
        else if (bgnd_image != (Image *) NULL)
          bgnd_image=DestroyImage(bgnd_image);
        if ( dup_image != (Image *) NULL)
          dup_image=DestroyImage(dup_image);
        if ( disposals[i-1] == NoneDispose )
          {
            prev_image=CloneImage(next->previous,image->page.width,
              image->page.height,MagickTrue,exception);
            if (prev_image == (Image *) NULL)
              {
                bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
                disposals=(DisposeType *) RelinquishMagickMemory(disposals);
                return((Image *) NULL);
              }
          }
      }
    disposals[i]=disposals[i-1];
    i++;
  }
  prev_image=DestroyImage(prev_image);
  /*
    Optimize all images in sequence.
  */
  i=0;
  next=image;
  optimized_image=NewImageList();
  while ( next != (const Image *) NULL )
  {
    prev_image=CloneImage(next,0,0,MagickTrue,exception);
    if (prev_image == (Image *) NULL)
      break;
    if ( disposals[i] == DelDispose ) {
      unsigned long time = 0;
      while ( disposals[i] == DelDispose ) {
        time += next->delay*1000/next->ticks_per_second;
        next=GetNextImageInList(next);
        i++;
      }
      time += next->delay*1000/next->ticks_per_second;
      prev_image->delay = time/100;
      prev_image->ticks_per_second = 100L;
    }
    bgnd_image=CropImage(prev_image,&bounds[i],exception);
    prev_image=DestroyImage(prev_image);
    if (bgnd_image == (Image *) NULL)
      break;
    bgnd_image->dispose=disposals[i];
    if ( disposals[i] == DupDispose ) {
      bgnd_image->delay=0;
      bgnd_image->dispose=NoneDispose;
    }
    else
      next=GetNextImageInList(next);
    AppendImageToList(&optimized_image,bgnd_image);
    i++;
  }
  bounds=(RectangleInfo *) RelinquishMagickMemory(bounds);
  disposals=(DisposeType *) RelinquishMagickMemory(disposals);
  if (next != (Image *) NULL)
    {
      optimized_image=DestroyImageList(optimized_image);
      return((Image *) NULL);
    }
  return(GetFirstImageInList(optimized_image));
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%     O p t i m i z e I m a g e L a y e r s                                   %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  OptimizeImageLayers() compares each image the GIF disposed forms of the
%  previous image in the sequence.  From this it attempts to select the
%  smallest cropped image to replace each frame, while preserving the results
%  of the GIF animation.
%
%  The format of the OptimizeImageLayers method is:
%
%      Image *OptimizeImageLayers(const Image *image,
%               ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image: The image.
%
%    o exception: Return any errors or warnings in this structure.
%
*/
MagickExport Image *OptimizeImageLayers(const Image *image,
  ExceptionInfo *exception)
{
  return OptimizeLayerFrames(image, OptimizeLayer, exception);
}

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%     O p t i m i z e P l u s I m a g e L a y e r s                           %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  OptimizeImagePlusLayers() is exactly as OptimizeImageLayers(), but may
%  also add or even remove extra frames in the animation, if it improves
%  the total number of pixels in the resulting GIF animation.
%
%  The format of the OptimizePlusImageLayers method is:
%
%      Image *OptimizePlusImageLayers(const Image *image,
%               ExceptionInfo *exception)
%
%  A description of each parameter follows:
%
%    o image: The image.
%
%    o exception: Return any errors or warnings in this structure.
%
*/
MagickExport Image *OptimizePlusImageLayers(const Image *image,
  ExceptionInfo *exception)
{
  return OptimizeLayerFrames(image, OptimizePlusLayer, exception);
}
