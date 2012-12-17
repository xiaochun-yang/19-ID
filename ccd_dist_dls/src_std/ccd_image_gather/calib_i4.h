#include "../incl/export.h"
/*
 * All math done with integer operataions
 * Define bit shifts.
 */

#define S 15
#define O (1<<S)
#define O2 (1<<(2*S))
#define R  (1<<(S-1))
#define R1 (1<<(S-1))

#define ONE1 O
#define ONE2 O2

/*
 * Bad pixel flags in interpolation tables
 */
#define BADPIX 0xffffffff
#define INTFLAG 100000000

#define DARK_OFFSET 5
#define POSTNUF_END 65535

int mkcalib (signed short **out, int *outsize,
	     int *size,
	     int *x_int, int xxsize, int xysize,
	     int *y_int, int yxsize, int yysize,
	     int xstart, int xstep, int ystart, int ystep,
	     float pscale);

void rcalib (signed short *cal, int calsize,
	     unsigned short *indata,
	     unsigned short *outdata,
	     unsigned short *flag,
	     int xsize, int ysize);

EXPORTABLE
void calib_free (unsigned short *data);

EXPORTABLE
int calib_load_dark (char *filename, unsigned short **dark,
		     int *xsize, int *ysize );

EXPORTABLE
int calib_load_nuf (char *filename, unsigned short **nuf,
		    int *xsize, int *ysize );

EXPORTABLE
int calib_dark_nuf (unsigned short *input, int* output, int xsize, int 
ysize,
		    unsigned short *dark, unsigned short *nuf );

EXPORTABLE
int calib_load_postnuf (char *filename, unsigned short **postnuf );

EXPORTABLE
int calib_postnuf (int *data, int xsize, int ysize,
		   unsigned short *postnuf );

EXPORTABLE
int calib_load_distor (char *filename, signed short **cal,
		       int *calsiz, int *xsize, int *ysize );

EXPORTABLE
int calib_distor (int *input, int *out,
		  int xsize, int ysize, signed short *cal);

struct readcalp
{
  float x_center;
  float y_center;
  float x_pt_center;
  float y_pt_center;
  float x_scale;
  float y_scale;
  float ratio;
  float ver_slope;
  float horz_slope;
  float a1;
  float a;
  float b;
  float c;
  float spacing;
  float x_beam;
  float y_beam;
  int   x_size;
  int   y_size;
  int   xint_start, yint_start;
  int   xint_step, yint_step;
  int   xinv_start, yinv_start;
  int   xinv_step, yinv_step;
  float pscale;
  float pixsiz;
  int   bad_flag;
};
