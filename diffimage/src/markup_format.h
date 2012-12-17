#ifndef DIFFIMAGE_MARKUP_FORMAT_H
#define DIFFIMAGE_MARKUP_FORMAT_H
/*

Image markup binary format, version 3

22 characters:
"LABELIT IMAGE MARKUP\r\n"

19 characters:
"filename %8d\r\n"
The integer value gives the number of characters in the subsequent file name

"%s\r\n"
The character string (not null-terminated) gives the file name (full path)

"       3\n" #version number

After this header, the file can contain any number of rendering blocks,
not necessarily given in a particular order.  They are simply read until
an end-of-file is encountered.  Each block has:

8 characters:
A string specifying what type of rendering will be used.
The current choices are:
"CIRCLE__" for resolution rings.  Note:  the application will obviously
           need to be extended if the data are acquired with non-zero
           two_theta.  The circles will become ellipses in this case.
"ELLIPSE_" for Bragg spot best-fit models
"DOT_____" for Bragg spot pixel maxima
"DOTFLOAT" for refined positions of Bragg spots
"CROSS___" to indicate the direct beam position

Encoding format for the following sections:
unsigned int:   "%8d\n"
int:            "%8d\n"
unsigned short: "%8d\n"
float:          "%11.5f\n"

unsigned int tag.
This 4-byte integer is treated as a list of 32 flags defining the semantics
of the rendering block.  The flags are defined in the python package
labelit.labelit.webice_support, and are repeated here:
0: 'LABELIT_ICE_RINGS',
1: 'DISTL_RESOLUTION_METHOD2',
2: 'SPOTFINDER_SPOTS',
3: 'INLIER_SPOTS',
4: 'SPOTFINDER_MAXIMA',
5: 'INPUT_BEAM',
6: 'REFINED_BEAM',
7: 'INDEXING_RESOLUTION',
8: 'INDEXING_FULLS',
9: 'INDEXING_PARTIALS',
10:'OBSERVATION_COM'
11 to 31: unused

int nitems.
An integer giving the number of items to be rendered, needed to set up
the parsing loop.

float[3] RGB.
The red, green, and blue color channels given on a saturation scale of 0 to 1.

Loop over nitems:
  The data within the loop are different for each type of rendering block.
  Units of measure are pixels for position and distance, degrees for angle:
  1. Circle
     x center, y center, radius, encoded as three floats

  2. Ellipse
     x center, y center, semi-major axis, semi-minor axis, angle
     encoded as five floats

  3. Dot
     x center, y center, encoded as two unsigned shorts

  4. Dotfloat
     x center, y center, encoded as two floats

  5. Cross
     x center, y center, radius encoded as three floats

*/
#endif
