/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%                 SSSSS  TTTTT  RRRR   EEEEE   AAA   M   M                    %
%                 SS       T    R   R  E      A   A  MM MM                    %
%                  SSS     T    RRRR   EEE    AAAAA  M M M                    %
%                    SS    T    R R    E      A   A  M   M                    %
%                 SSSSS    T    R  R   EEEEE  A   A  M   M                    %
%                                                                             %
%                                                                             %
%                     Stream image to a raw image format.                     %
%                                                                             %
%                           Software Design                                   %
%                             John Cristy                                     %
%                              July 1992                                      %
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
%  Use Stream is a lightweight utility designed to extract pixels from large
%  image files to a raw format using a minimum of system resources.  The
%  entire image or any regular portion of the image can be extracted.
%
%
*/

/*
  Include declarations.
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "wand/MagickWand.h"
#if defined(__WINDOWS__)
#include <windows.h>
#endif

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                             %
%                                                                             %
%                                                                             %
%    M a i n                                                                  %
%                                                                             %
%                                                                             %
%                                                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
*/
int main(int argc,char **argv)
{
  char
    *option;

  ExceptionInfo
    exception;

  ImageInfo
    *image_info;

  MagickBooleanType
    regard_warnings,
    status;

  register long
    i;

  InitializeMagick(*argv);
  GetExceptionInfo(&exception);
  regard_warnings=MagickFalse;
  for (i=1; i < (long) argc; i++)
  {
    option=argv[i];
    if ((strlen(option) == 1) || ((*option != '-') && (*option != '+')))
      continue;
    if ((LocaleCompare("debug",option+1) == 0) && (i < (long) (argc-1)))
      (void) SetLogEventMask(argv[++i]);
    if (LocaleCompare("regard-warnings",option+1) == 0)
      regard_warnings=MagickTrue;
    if ((LocaleCompare("version",option+1) == 0) ||
        (LocaleCompare("-version",option+1) == 0))
      {
        (void) fprintf(stdout,"Version: %s\n",
          GetMagickVersion((unsigned long *) NULL));
        (void) fprintf(stdout,"Copyright: %s\n\n",GetMagickCopyright());
        exit(0);
      }
  }
  image_info=AcquireImageInfo();
  status=StreamImageCommand(image_info,argc,argv,(char **) NULL,&exception);
  if ((status == MagickFalse) || (exception.severity != UndefinedException))
    {
      if ((exception.severity < ErrorException) &&
          (regard_warnings == MagickFalse))
        status=MagickTrue;
      CatchException(&exception);
    }
  image_info=DestroyImageInfo(image_info);
  (void) DestroyExceptionInfo(&exception);
  DestroyMagick();
  return(status == MagickFalse ? 1 : 0);
}
