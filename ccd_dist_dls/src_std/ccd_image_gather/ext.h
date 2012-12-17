#include	"defs.h"

/*
 *	Having to do with the network.
 */

extern	int	command_s;		/* listens on this socket */
extern	int	data_s;			/* listens on this socket */
extern	int	command_port_no;	/* TCPIP port number for commands */
extern	int	data_port_no;		/* TCPIP port number for data */
extern	int	command_fd;		/* file descriptor for commands after connection */
extern	int	data_fd[MAX_CONTROLLERS];		/* file descriptor for data after connection */
extern	char	det_hostname[512];	/* hostname for detector api server */
extern	int     standalone;             /* 1 if we are running standalone (no connect to det server) */
extern	int	reply_to_sender;	/* 1 if we reply to sender after command, 0 if no reply */
extern	int	compress_mode;		/* 0 for no compress, 1 for .Z, 2 for .pck */
extern	char	xfsname[256];		/* transform status name */

/*
 *	Having to do with sizes, shapes, and coordinates.
 */

extern	int	ccd_sqsize;		/* max(nrows,ncols) for any chip */
extern	int	ccd_imsize;		/* actual size of transformed image per module */
extern	int	ccd_nrows;		/* number of rows in the ccd */
extern	int	ccd_ncols;		/* number of columns in the ccd */
extern	int	ccd_row_xfersize;	/* number of rows to be sent to user */
extern	int	ccd_col_xfersize;	/* number of cols to be sent to user */
extern	int	ccd_row_fullsize;	/* number of rows in a square, full size image */
extern	int	ccd_col_fullsize;	/* number of cols in a square, full size image */
extern	int	ccd_row_halfsize;	/* number of rows in a square, half size image */
extern	int	ccd_col_halfsize;	/* number of cols in a square, half size image */

extern	int	ccd_row_bin;		/* binning factor along rows */
extern	int	ccd_col_bin;		/* binning factor along cols */
extern	int	binned_data;		/* 1 for 2x2 binned, else 0 for 1x2.  Only allowed ones at this point */
extern	int	det_bin;		/* 1 for 1x1, 2 for 2x2, a convienence */
extern	int	unbinned_fast;		/* 1 for unbinned fast data */
extern	int	outfile_type;		/* 0 for ushort, 1 for long (32bit), 2 for ushort + overflow */
extern	int	detector_sn;		/* detector serial number */

extern	int     image_kind;             /* 0 = first dark, 1 = second dark, 2 = first raw, 3 = second raw */
extern	int     save_raw_images;        /* 1 to save raw images */
extern	int	rotate_180;		/* 1 to rotate final image by 180, else 0 */
extern	int	fix_bad;		/* 1 to fix a bad col */
extern	int	req_ave;		/* 1 for averages from dez. images, else 0 for sums from dez images */

extern	float   row_mm;                 /* beam center value along rows in mm */
extern	float   col_mm;                 /* beam center value along cols in mm */
extern	float   dist_mm;                /* distance from xtal to detector along normal */
extern	float   two_theta;              /* two theta of the detector */
extern	float   wave;                   /* wavelength */
extern	float	dzratio;		/* ratio of 2nd to first exposure for dezingering */
extern	int	raw_saturated;		/* values greated than this are assumed saturated in a raw */
extern	int	int_saturated;		/* value in xformed file meaining saturated */
extern	int	input_images;		/* 1 if the images are input from previously written raws */

/*
 *	Operational paramters.
 */

extern	int	ccd_trigger_mode;	/* 1 for ext_trig, 0 for timed exposure */
extern	int	ccd_timedose_mode;	/* 0 for time, 1 for dose */
extern	double	ccd_exp_time;		/* exposure time, if needed */
extern	int	ccd_adc;		/* 0 for slow, 1 for fast */
extern	int	ccd_timecheck;		/* 1 for a rationality check on timing, else 0 */
extern	int	ccd_synch;		/* 1 for synchronous, 0 for asynch */

/*
 *	Data (image) storage.
 */


extern	unsigned short  *raw_data[2];           /* data from the CCD goes here */
extern	int             raw_data_size[2];       /* number of words in the above image (to transmit) */
extern	char            *raw_header[2];         /* copy of the header, if any, for the image above */
extern	int             raw_header_size[2];     /* size of the header for each image */

extern	unsigned short  *dkc_data[4];           /* data from the CCD goes here */
extern	int             dkc_data_size[4];       /* number of words in the above image (to transmit) */
extern	char            *dkc_header[4];         /* copy of the header, if any, for the image above */
extern	int             dkc_header_size[4];     /* size of the header for each image */

extern	int		ccd_data_valid[2];	/* data valid marker for each image */
extern	int		ccd_bufind;		/* index of the image number (0 or 1) for current image */

extern	int		*ccd_inbuf;		/* input buffer before transformation */
extern	int		*ccd_oubuf;		/* output buffer after transformation */

extern	unsigned short	*scratch;		/* scratch area for memory rearrangement */
extern	unsigned short	*in_data;		/* holding area for incoming data */
extern	unsigned short	*in_rdata;		/* incoming data, enlarged and rotated */

/*
 *	Miscellaneous stuff.
 */

extern	FILE	*fplog;				/* used for logging events to a file */
extern	FILE	*fpxfs;				/* xform status file */
extern	FILE	*fpout;
extern	FILE	*fperr;
extern	FILE	*fpg;
extern	int	xform_counter;			/* xform status file output counter */

/*
 *	Input buffering, etc.
 */

extern	char	inbuf[INBUFSIZE];
extern	int	inbufind;
extern	char	merge_header[MERGE_HEADER_SIZE];
extern	int	merge_header_bytes;

extern	char	replybuf[RBUFSIZE];
extern	int	rbufind;

extern	int	command_number;			/* from the command enum */
extern	int	processing_command;		/* state variable during parse */
extern	int	input_header_size;		/* current value for header size in bytes */
extern	int	merge_header_ind;
extern	char	input_header[CCD_HEADER_MAX];	/* storage for same */

extern	char	infilename[512];		/* input file name */
extern	char	outfilename[512];		/* output file name */
extern	char	rawfilename[512];		/* output for raw file */

extern signed   short *ccd_calfil;		/* CALFIL - Calibration File */
extern unsigned short *ccd_nonunf;		/* NONUNF - Nonuniformity Correction File */
extern unsigned short *ccd_postnuf;		/* POSTNUF - Nonuniformity Correction File */
extern unsigned short *ccd_nonunf_fast;         /* fast unbinned nonunf file */
extern unsigned short *ccd_postnuf_fast;        /* fast unbinned nonunf file */
extern int      *ccd_x_int;			/* CCD_X_INT - X Interpolation File */
extern int      *ccd_y_int;			/* CCD_Y_INT - X Interpolation File */
extern struct readcalp ccd_calpar;		/* CCD_CALPAR - Calibration parameters */
extern int ccd_xint_size[2];			/* Size of ccd_x_int[] */
extern int ccd_yint_size[2];			/* Size of ccd_y_int[] */

extern signed   short *ccd_calfil_2x2;		/* CALFIL 2x2 binned - Calibration File */
extern unsigned short *ccd_nonunf_2x2;		/* NONUNF 2x2 binned - Nonuniformity Correction File */
extern unsigned short *ccd_postnuf_2x2;		/* POSTNUF 2x2 - Nonuniformity Correction File */
extern int      *ccd_x_int_2x2;			/* CCD_X_INT - X Interpolation File */
extern int      *ccd_y_int_2x2;			/* CCD_Y_INT - X Interpolation File */
extern struct readcalp ccd_calpar_2x2;		/* CCD_CALPAR - Calibration parameters */
extern int ccd_xint_size_2x2[2];		/* Size of ccd_x_int[] */
extern int ccd_yint_size_2x2[2];		/* Size of ccd_y_int[] */

extern	int     dkc_seen[4];                    /* 1 when the image has been seen (& usable) */
extern	int     raw_seen[2];                    /* 1 when the image has been seen (& usable) */
extern	int	did_dezingering;		/* 1 when the images have been dezingered, else 0 */

extern	int	n_ctrl;				/* number of controllers */
extern	int	m_rotate[MAX_CONTROLLERS];	/* ccd chip rotations */
extern	int     n_strip_ave;                    /* number of strip averages set */
extern	float	sav[MAX_CONTROLLERS];		/* strip values from pc ccd_det */
extern	float	sav_i[2][MAX_CONTROLLERS];
extern	float	sav_c[MAX_CONTROLLERS];
extern	float	sav_d[MAX_CONTROLLERS];
extern	int	use_strips;
extern	int	no_pedestal_adjust;
extern	int	no_pedestal_adjust_bin;
extern	int	dSAV[MAX_CONTROLLERS];
extern	int	dSAV_thomson[MAX_CONTROLLERS][4];
extern  double  ped_dk[N_KIND][MAX_MODULES][4];
extern  double  ped_im[N_KIND][MAX_MODULES][4];

/*
 *      data base detector definition.
 */

extern  struct q_moddef qm[MAX_CONTROLLERS];

/*
 *      host, port database
 */

extern  int     q_ncon;                                 /* number of connections which need to be made */
extern  char    q_hostnames[MAX_CONTROLLERS][256];      /* host name */
extern  int     q_ports[MAX_CONTROLLERS];               /* port numbers */
extern	int	q_dports[MAX_CONTROLLERS];
extern	int	q_sports[MAX_CONTROLLERS];

extern	int	q_blocks[MAX_CONTROLLERS][MAX_CONTROLLERS];
extern	int	q_states[MAX_CONTROLLERS];
