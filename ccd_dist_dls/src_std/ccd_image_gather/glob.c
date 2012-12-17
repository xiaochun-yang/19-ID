#include	"defs.h"
#include 	"../incl/filec.h"

/*
 *	Having to do with the network.
 */

int 	command_s;		/* listens on this socket */
int 	data_s;			/* listens on this socket */
int 	command_port_no;	/* TCPIP port number for commands */
int 	data_port_no;		/* TCPIP port number for data */
int 	command_fd;		/* file descriptor for commands after connection */
int 	data_fd[MAX_CONTROLLERS];		/* file descriptor for data after connection */
char	det_hostname[512];	/* hostname for detector api server */
int 	standalone;		/* 1 if we are running standalone (no connect to det server) */
int 	reply_to_sender;	/* 1 if we reply to sender after a command, 0 for no reply */
int 	compress_mode;		/* 0 for no compres, 1 for .Z 2 for .pck */
char	xfsname[256];		/* transform status file name */

/*
 *	Having to do with sizes, shapes, and coordinates.
 */

int 	ccd_sqsize;		/* really max(nrows,ncols) for a chip */
int 	ccd_imsize;		/* actual size of transformed images per module */
int 	ccd_nrows;		/* number of rows in the ccd */
int 	ccd_ncols;		/* number of columns in the ccd */
int 	ccd_row_xfersize;	/* number of rows to be sent to user */
int 	ccd_col_xfersize;	/* number of cols to be sent to user */
int 	ccd_row_fullsize;	/* number of rows in a square, full size image */
int 	ccd_col_fullsize;	/* number of cols in a square, full size image */
int 	ccd_row_halfsize;	/* number of rows in a square, half size image */
int 	ccd_col_halfsize;	/* number of cols in a square, half size image */

int	ccd_row_bin;		/* binning factor along rows */
int	ccd_col_bin;		/* binning factor along cols */
int	binned_data;		/* 1 for binned, 0 for non-binned.  Currently allow 1x1 or 2x2, that's it */
int	det_bin;		/* 1 for no bin, 2 for 2x2, a convienence */
int	unbinned_fast;		/* 1 for unbinned fast adc data */
int	outfile_type;		/* See defs.h */
int	detector_sn;		/* detector serial number */

int	image_kind;		/* 0 = first dark, 1 = second dark, 2 = first raw, 3 = second raw */
int	save_raw_images;	/* 1 to save raw images */
int	rotate_180;		/* 1 to rotate final image by 180, else 0 */
int	fix_bad;		/* 1 to fix a bad col, else 0 */
int	req_ave;		/* 1 if averages from dezingered images, else 0 for sums from dez. images */

float	row_mm;			/* beam center value along rows in mm */
float	col_mm;			/* beam center value along cols in mm */
float	dist_mm;		/* distance from xtal to detector along normal */
float	two_theta;		/* two theta of the detector */
float	wave;			/* wavelength */
float	dzratio;		/* ratio of 2nd exposure time to first on dezingering */
int	raw_saturated;		/* values above this are assumed saturated in a raw */
int	int_saturated;		/* value in integer array >= this is saturated */
int	input_images;		/* 1 if the images are input from prev. written raws */

/*
 *	Operational paramters.
 */

int	ccd_trigger_mode;	/* 1 for ext_trig, 0 for timed exposure */
int	ccd_timedose_mode;	/* 0 for time, 1 for dose */
double	ccd_exp_time;		/* exposure time, if needed */
int	ccd_adc;		/* 0 for slow, 1 for fast */
int	ccd_timecheck;		/* 1 for a rationality check on timing, else 0 */
int	ccd_synch;		/* 1 for synchronous, 0 for asynch */

/*
 *	Data (image) storage.
 */

unsigned short	*raw_data[2];		/* data from the CCD goes here */
int		raw_data_size[2];	/* number of words in the above image (to transmit) */
char		*raw_header[2];		/* copy of the header, if any, for the image above */
int		raw_header_size[2];	/* size of the header for each image */

unsigned short	*dkc_data[4];		/* data from the CCD goes here */
int		dkc_data_size[4];	/* number of words in the above image (to transmit) */
char		*dkc_header[4];		/* copy of the header, if any, for the image above */
int		dkc_header_size[4];	/* size of the header for each image */

int		ccd_data_valid[2];	/* data valid marker for each image */
int		ccd_bufind;		/* index of the image number (0 or 1) for current image */

int		*ccd_inbuf;		/* input holding buffer before transformation */
int		*ccd_oubuf;		/* output holding buffer after transformation */

unsigned short	*scratch;		/* scratch area for memory rearrangement */
unsigned short	*in_data;		/* incoming data holding area */
unsigned short	*in_rdata;		/* incoming data, enlarged and rotated properly */

/*
 *	Miscellaneous stuff.
 */

FILE	*fplog;				/* used for logging events to a file */
FILE	*fpxfs;				/* xform status file */
FILE	*fpout;
FILE	*fperr;
FILE	*fpg;
int	xform_counter;			/* xform status file output counter */

/*
 *	Input buffering, etc.
 */

char	inbuf[INBUFSIZE];
int	inbufind;
char	merge_header[MERGE_HEADER_SIZE];
int	merge_header_bytes;

char	replybuf[RBUFSIZE];
int	rbufind;

int	command_number;			/* from the command enum */
int	processing_command;		/* state variable during parse */
int	input_header_size;		/* current value for header size in bytes */
int	merge_header_ind;
char	input_header[CCD_HEADER_MAX];	/* storage for same */

char	infilename[512];		/* input file name */
char	outfilename[512];		/* output file name */
char	rawfilename[512];		/* output for raw file name */

signed   short *ccd_calfil=NULL;	/* CALFIL - Calibration File */
unsigned short *ccd_nonunf=NULL;	/* NONUNF - Nonuniformity Correction File */
unsigned short *ccd_postnuf=NULL;	/* POSTNUF - Nonuniformity Correction File */

unsigned short *ccd_nonunf_fast = NULL;		/* fast unbinned nonunf file */
unsigned short *ccd_postnuf_fast = NULL;	/* fast unbinned nonunf file */

int *ccd_x_int=NULL;			/* DISTOR.x_int - X Interpolation File */
int *ccd_y_int=NULL;			/* DISTOR.y_int - Y Interpolation File */
struct readcalp ccd_calpar;		/* DISTOR.calpar - Calibration params */
int ccd_xint_size[2];			/* Size of ccd_x_int[] */
int ccd_yint_size[2];			/* Size of ccd_y_int[] */

signed   short *ccd_calfil_2x2=NULL;	/* CALFIL 2x2 binned - Calibration File */
unsigned short *ccd_nonunf_2x2=NULL;	/* NONUNF 2x2 binned- Nonuniformity Correction File */
unsigned short *ccd_postnuf_2x2=NULL;	/* POSTNUF 2x2 - Nonuniformity Correction File */

int *ccd_x_int_2x2=NULL;		/* DISTOR.x_int 2x2 binned - X Interpolation File */
int *ccd_y_int_2x2=NULL;		/* DISTOR.y_int 2x2 binned - Y Interpolation File */
struct readcalp ccd_calpar_2x2;		/* DISTOR.calpar 2x2 binned - Calibration params */
int ccd_xint_size_2x2[2];		/* Size of ccd_x_int_2x2[] */
int ccd_yint_size_2x2[2];		/* Size of ccd_y_int_2x2[] */

int	dkc_seen[4];			/* 1 when the image has been seen (& usable) */
int	raw_seen[2];			/* 1 when the image has been seen (& usable) */
int	did_dezingering;		/* 1 when the images were dezingered, else 0 */

int	n_ctrl;				/* number of controllers */
int	m_rotate[MAX_CONTROLLERS];	/* array of ccd chip rotations */

int	n_strip_ave;			/* number of strip averages set */
float	sav[MAX_CONTROLLERS];		/* pedestal values from CCD edge strip */
float	sav_i[2][MAX_CONTROLLERS];
float	sav_c[MAX_CONTROLLERS];
float	sav_d[MAX_CONTROLLERS];
int	use_strips;			/* 1 to use the strip averaging method */
int	no_pedestal_adjust;		/* 1 for no pedestal adjustment */
int	no_pedestal_adjust_bin;		/* 1 for no pedestal adjust just on binning */
int	dSAV[MAX_CONTROLLERS];		/* save the deltas */
int	dSAV_thomson[MAX_CONTROLLERS][4];	/* save the deltas */
double  ped_dk[N_KIND][MAX_MODULES][4];	/* Store the pedestal values for darks */
double  ped_im[N_KIND][MAX_MODULES][4];	/* Store the pedestal values for images */

/*
 *      data base detector definition.
 */

struct q_moddef qm[MAX_CONTROLLERS];

/*
 *      host, port database
 */

int     q_ncon;                                 /* number of connections which need to be made */
char    q_hostnames[MAX_CONTROLLERS][256];      /* host name */
int     q_ports[MAX_CONTROLLERS];               /* port numbers */
int	q_dports[MAX_CONTROLLERS];
int	q_sports[MAX_CONTROLLERS];

int	q_blocks[MAX_CONTROLLERS][MAX_CONTROLLERS];	/* assigned data blocks from each connection */
int	q_states[MAX_CONTROLLERS];
