#ifndef HAVE_FILEC

#define HAVE_FILEC
/*
 * Routines to deal with byte order
 */
int getbo(void);
int swpbyt(int mode, int length, char* array);

/*
 * Routines to deal with the header
 */
void clrhd ( char* header );
void gethd ( char* field, char* value, char* header );
int gethdl ( int* headl, char* head );
int gethddl ( int* headl, char* head );
int gethdn ( int n, char* field, char* value, char* header );
void puthd (char* field, char* value, char* header);
void padhd (char* header, int size);

/*
 * utility routine to generate a filename from a template and a number
 */
void namfil (char* tmpfil, int num, char* filnam);

/*
 * Routines to read/write colortables
 */
int rdctbl ( char* filename, char* red, char* green, char* blue, int* ncolor,
	    int* control, int* ncontrol, int* cmode );
int wrctbl (char* filename, char* red, char* green, char* blue, int ncolor,
	    int* control, int ncontrol, int* mode );

/*
 * Read just the header of a file
 */
int rdhead ( char* filename, char* head );
int wrhead (char* filename, char* head );


/*
 * Old style (FORTRAN compatiable) routines to read/write
 * MAD (unsigned short) images
 */
int rdmad  ( char* filename, char* head, short* array, 
	    int as1, int as2, int* is1, int* is2 );

int wrmad  (char* filename, char* head, short* array, 
	    int as1, int as2, int is1, int is2 );

int wrswap (char* filename, char* head, short* array, 
	    int as1, int as2, int is1, int is2 );

/*
 * Newer routines to read/write files
 */
int rdfile (char* filename, char** head, int *lhead,
	    char** array, int* naxis, int* axis, int *type);

int rdfits (char* filename, char** head, int *lhead,
	    char** array, int* naxis, int* axis, int *type);

int rdlum (char* filename, char** head, int *lhead,
	   char** array, int* naxis, int* axis, int *type);

int rdmar (char* filename, char** head, int *lhead,
	   char** array, int* naxis, int* axis, int *type);

int rdsmv (char* filename, char** head, int* lhead,
	   char** array, int* naxis, int* axis, int *type);


int wrfile  (char* filename, char* head, char* array, 
	     int naxis, int* axis, int type );

int wrrlmsb (char* filename, char* head, char* array, 
	     int naxis, int* axis, int type );

int filec_getdebug (void);
void filec_setdebug (int state);

#define SMV_UNKNOWN          0
#define SMV_SIGNED_BYTE      1
#define SMV_UNSIGNED_BYTE    2
#define SMV_SIGNED_SHORT     3
#define SMV_UNSIGNED_SHORT   4
#define SMV_SIGNED_LONG      5
#define SMV_UNSIGNED_LONG    6
#define SMV_FLOAT            7
#define SMV_DOUBLE           8
#define SMV_COMPLEX          9
#define SMV_DCOMPLEX         10
#define SMV_ASCII            11
#define SMV_BIT              12

#define FILE_NOT_FOUND            -1
#define ERROR_READING_FILE        -2
#define ERROR_OPENING_FILE        -3
#define UNKNOWN_FILETYPE          -4
#define USER_CANCELLED            -5
#define SUCCESS                    0

#ifdef VAX11C
void dskbor (int* lun, struct descr* filename, int* lfilename, int* istat);
void dskbow (int* lun, struct descr* filename, int* lfilename, 
	     int* size, int* istat);
void dskbcr (int* lun, int* istat);
void dskbcw (int* lun, int* istat);
void dskbr  (int* lun, char* data, int* ldata, int* istat);
void dskbw  (int* lun, char* data, int* ldata, int* istat);
void dskbwr (int* lun, int* lflag);
void dskbww (int* lun, int* lflag);

#else
void dskbor_ (int* lun, char* filename, int* lfilename, int* istat);
void dskbow_ (int* lun, char * filename, int* lfilename, 
	      int* size, int* istat);
void dskbcr_ (int* lun, int* istat);
void dskbcw_ (int* lun, int* istat);
void dskbr_  (int* lun, char* data, int* ldata, int* istat);
void dskbw_  (int* lun, char* data, int* ldata, int* istat);
void dskbwr_ (int* lun, int* lflag);
void dskbww_ (int* lun, int* lflag);

#endif

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
};

int rdcal ( char* filename, struct readcalp *c );
#endif
