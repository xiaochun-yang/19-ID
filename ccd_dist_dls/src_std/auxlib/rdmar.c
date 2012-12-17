#ifndef vms
#include <malloc.h>
#endif
#include <stdio.h>
#include <string.h>
#include "filec.h"

static void mar_putheader (char *h, char* header);
static void mar_getover (unsigned int *a, int n, int* x, int* y, int* val);
static int mar_getnover (char *h);

int rdmar (char* filename, char** head, int *lhead,
	   char** array, int* naxis, int* axis, int *type)
     
{
  int readl, remain;
  int i, j, k;
  int istat, bo, cbo, dim;
  char s[80], byteo[80];
  int lun=1;
  int lflag;
  int is1, is2;
  int  llen, n, val; 
  int  martest[512];
  char marhead[2000];
  int nover;

  int filec_debug = filec_getdebug();

  *array = 0;
  *head = 0;

  cbo = getbo ();


  j = strlen(filename);
  if ( filec_debug)
    printf("Opening file: %s\n", filename);
  dskbor_ ( &lun, filename, &j, &istat);
  if ( istat != 0 ) return -1;

  /*
   * While reading the header, have to wait before proceding
   */
  lflag = (1==1);
  if ( filec_debug )
    printf("Reading header\n");
  dskbwr_ ( &lun, &lflag );
  
  /*
   * The header should be at least 512 bytes
   * Get the first 512 bytes to get the header length
   */
  readl = 512;
  dskbr_ ( &lun, marhead, &readl, &istat);
  if ( filec_debug )
    printf("Read Completion status : %d\n", istat);
  if ( istat != 0 ) goto close;

/*
 * I am not sure if this is true, but it seems that mar images
 * are always in big_endian format (bo=1)
 */
  memcpy (martest, marhead, 8);
  if ( filec_debug )
    {
      if ( cbo == 0 ) 
	printf ("This computer is little endian\n");
      else 
	printf ("This computer is big endian\n");
    }

  if ( cbo == 0 ) swpbyt (1, 8, (char*) martest);
  if ( filec_debug )
    printf("Checking if mar image %d %d \n", *martest, *(martest+1));

  if ( (*martest == 2000 && *(martest+1) == 2000 ) ||
      (*martest == 1200 && *(martest+1) == 1200 ) )
    {
      is1 = *martest; is2 = *(martest+1);

      if ( filec_debug )
	printf("Read MAR Image Plate (%d x %d)\n", is1, is2);

      /*
       * Read the rest of the header
       */
      readl = is1*2-512;
      dskbr_ ( &lun, marhead, &readl, &istat);

      nover = mar_getnover (marhead);
      if ( filec_debug )
	printf("Number of overflow pixels %d\n", nover);

      *lhead = 4096;
      *head = malloc (4096);
      memset (*head, 0, 4096);
      clrhd (*head);
      mar_putheader (marhead, *head);

      *naxis = 2; axis[0] = is1; axis[1] = is2;
      puthd ("DIM", "2", *head);
      sprintf (s, "%d", is1);
      puthd ("SIZE1", s, *head);
      sprintf (s, "%d", is1);
      puthd ("SIZE2", s, *head);

      if ( filec_debug )
	printf("Updated Header        : \n%s<END\n", *head);
      if ( nover <= 0 ) 
	{
	  unsigned int *data;
	  *type = SMV_UNSIGNED_SHORT;
	  puthd ("TYPE", "unsigned_short", *head);
	  readl = is1 * is2 * sizeof (unsigned short);
	  data = malloc (readl);
	  *array = (char*) data;
	  dskbr_ ( &lun, (char*) data, &readl, &istat);
	  if ( cbo == 0 ) swpbyt(0, readl, (char*) data);
	}
      else
	{
	  unsigned short *a;
	  unsigned int *b;
	  int x, y, val;
	  int datal;
	  int *data;

	  *type = SMV_SIGNED_LONG;
	  /*
	   * Make space for the (long) int data
	   */
	  datal = is1 * is2 * sizeof (int);
	  data = malloc (datal);
	  *array = (char*) data;

	  /*
	   * Read the unsigned short data into the 
	   * space created for the int data
	   */
	  readl = is1 * is2 * sizeof (unsigned short);
	  a = (unsigned short*) data;
	  dskbr_ ( &lun, (char*) a, &readl, &istat);
	  if ( cbo == 0 ) swpbyt(0, readl, (char*) a);

	  /*
	   * Convert unsigned to long int, starting from the back
	   */
	  j = is1*is2-1;
	  for (i=j; i>=0; i--) data[i] = (int) a[i];
	  
	  /*
	   * Read in the overflow records (two ints for each overflow)
	   */
	  readl = nover * sizeof (unsigned int) * 2;
	  b = (unsigned int*) malloc(readl);
	  dskbr_ ( &lun, (char*) b, &readl, &istat);
	  if ( cbo == 0 ) swpbyt(1, readl, (char*) b);
	  
	  /*
	   * Fill in the overflows
	   */
	  for (i=0; i<nover; i++)
	    {
	      mar_getover (b, i, &x, &y, &val);
	      if ( filec_debug )
		printf ("Overflow (%d,%d) : %d\n", x, y, val);
	      data[y*is1+x] = val;
	    }

	  /*
	   * Free the overflow space
	   */
	  free ( (char*) b);
	}
      
      if ( filec_debug )
	printf("Read Completion status : %d\n", istat);
      
    }
  else
      istat = -1;

  /*
   * Close the file
   */
  
 close:
  if ( filec_debug )
    printf("Done reading MAR image (size %d x %d) (istat %d)\n", 
	   is1, is2, istat);
  if ( istat != 0 ) 
    dskbcr_ (&lun, &i);
  else
    dskbcr_ (&lun, &istat);

  
  if ( filec_debug )
    printf("RDMAR completion status %d\n", istat);
  if ( istat != 0 )
    {
      if ( *array != 0 ) free (*array);
      if ( *head != 0 ) free (*head);
      return istat;
    }
  else
    return 0;
}

/****************************************************************/
struct mar_image_header
{
  int     total_pixels_x;
  int     total_pixels_y;
  int     lrecl;
  int     max_rec;
  int     overflow_pixels;
  int     overflow_records;
  int     counts_per_sec_start;
  int     counts_per_sec_end;
  int     exposure_time_sec;
  int     programmed_exp_time_units;
  float   programmed_exposure_time;
  float   r_max;
  float   r_min;
  float   p_r;
  float   p_l;
  float   p_x;
  float   p_y;
  float   centre_x;
  float   centre_y;
  float   lambda;
  float   distance;
  float   phi_start;
  float   phi_end;
  float   omega;
  float   multiplier;
  char    scanning_date_time[24];
};

static int nover, marsize;
static int mar_getnover (char *h)
{
  struct mar_image_header *mh;
  mh = (struct mar_image_header*) h;
  marsize = mh->total_pixels_x;
  nover = mh->overflow_pixels;
  if ( getbo() == 0 ) swpbyt (1, 1, (char*) (&nover) );
  return nover;
}

static void mar_getover (unsigned int *a, int n, int* x, int* y, int* val)
{
  int t;
  if ( n < nover && marsize > 0)
    {
      t = *(a+2*n) - 1;
      *x = t % marsize;
      *y = t / marsize;
      *val = *(a+2*n + 1);
    }
}

static void mar_putheader (char *h, char* header)
{
  struct mar_image_header *mh;
  char s[80];

  mh = (struct mar_image_header*) h;
 
  puthd ("comment", "Converted MAR image", header);
  sprintf (s, "%d", mh->total_pixels_x);
  puthd ("total_pixels_x", s, header);
  sprintf (s, "%d", mh->total_pixels_y);
  puthd ("total_pixels_y", s, header);
  sprintf (s, "%d", mh->lrecl);
  puthd ("lrecl", s, header);
  sprintf (s, "%d", mh->max_rec);
  puthd ("max_rec", s, header);
  sprintf (s, "%d", mh->overflow_pixels);
  puthd ("overflow_pixels", s, header);
  sprintf (s, "%d", mh->overflow_records);
  puthd ("overflow_records", s, header);
  sprintf (s, "%d", mh->counts_per_sec_start);
  puthd ("counts_per_sec_start", s, header);
  sprintf (s, "%d", mh->counts_per_sec_end);
  puthd ("counts_per_sec_end", s, header);
  sprintf (s, "%d", mh->exposure_time_sec);
  puthd ("exposure_time_sec", s, header);

  sprintf (s, "%f", mh->programmed_exp_time_units);
  puthd ("programmed_exp_time_units", s, header);
  sprintf (s, "%f", mh->programmed_exposure_time);
  puthd ("programmed_exposure_time", s, header);
  sprintf (s, "%f", mh->r_max);
  puthd ("r_max", s, header);
  sprintf (s, "%f", mh->r_min);
  puthd ("r_min", s, header);
  sprintf (s, "%f", mh->p_r);
  puthd ("p_r", s, header);
  sprintf (s, "%f", mh->p_l);
  puthd ("p_l", s, header);
  sprintf (s, "%f", mh->p_x);
  puthd ("p_x", s, header);
  sprintf (s, "%f", mh->p_y);
  puthd ("p_y", s, header);
  sprintf (s, "%f", mh->centre_x);
  puthd ("centre_x", s, header);
  sprintf (s, "%f", mh->centre_y);
  puthd ("centre_y", s, header);
  sprintf (s, "%f", mh->lambda);
  puthd ("lambda", s, header);
  sprintf (s, "%f", mh->distance);
  puthd ("distance", s, header);
  sprintf (s, "%f", mh->phi_start);
  puthd ("phi_start", s, header);
  sprintf (s, "%f", mh->phi_end);
  puthd ("phi_end", s, header);
  sprintf (s, "%f", mh->omega);
  puthd ("omega", s, header);
  sprintf (s, "%f", mh->multiplier);
  puthd ("multiplier", s, header);

  strncpy (s, mh->scanning_date_time, 24);
  s[24]=0;
  puthd ("scanning_date_time", s, header);
}
