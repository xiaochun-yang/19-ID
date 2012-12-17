/*
 * All math done with integer operataions
 * Define bit shifts.
 */

#define S 15
#define O (1<<S)
#define O2 (1<<(2*S))
#define R  (1<<(S-1))
#define R1 (1<<(S-1))

/*
 * Bad pixel flags in interpolation tables
 */
#define BADPIX 0xffffffff
#define INTFLAG 1000000


int mkcalib (signed short **out, int *outsize,
	     int *x_int, int xxsize, int xysize,
	     int *y_int, int yxsize, int yysize,
	     int xstart, int xstep, int ystart, int ystep, 
	     float pscale);

void rcalib (signed short *cal, int calsize,
	     unsigned short *indata, unsigned short *outdata,
	     int xsize, int ysize);

int calib (unsigned short *in, unsigned short *out,
	   int xsize, int ysize, signed short *cal);

int calibint (int *in, int *out,
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
