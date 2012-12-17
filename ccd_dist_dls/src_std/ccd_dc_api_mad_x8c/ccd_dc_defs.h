#include	<stdio.h>
#include	"../incl/ccdconv.h"
#include	"../incl/esd.h"
#include	"../incl/esd_com.h"
#include	"../incl/ccddefs.h"
#include	"../incl/ccdsys.h"
#include	<errno.h>
#include	<signal.h>
#include	<math.h>

#ifndef VMS
#include	<sys/types.h>
#include	<sys/time.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#else
#include	<types.h>
#include	<time.h>
#include	<socket.h>
#include	<in.h>
#include	"../incl/vms_select.h"
#endif /* VMS */

#ifdef VMS
#define	GOOD_STATUS	1
#define	BAD_STATUS	2
#else
#define	GOOD_STATUS	0
#define	BAD_STATUS	1
#endif /* VMS */

#define	CCD_N_CTRL		"CCD_N_CTRL"

#define	CCD_DET_OK		0
#define	CCD_DET_RETRY		1
#define	CCD_DET_FATAL		2
#define	CCD_DET_NOTCONNECTED	3
#define	CCD_DET_DISCONNECTED	4

#define	CCD_BL_OK		10
#define	CCD_BL_RETRY		11
#define	CCD_BL_FATAL		12
#define	CCD_BL_NOTCONNECTED	13
#define	CCD_BL_DISCONNECTED	14

#define	MAXREMARK	100
#define	BLCMDMAX	256

struct mdc_command {
		int	cmd_used;	/* 0 if this queue entry unused */
		struct mdc_command *cmd_next;	/* next command in queue */
		int	cmd_no;		/* the command number/this command */
		int	cmd_err;	/* 1 if there is an error */
		float	cmd_value;	/* a value field, if appropriate */
		float	cmd_col_dist;	/* distance for data collection */
		float	cmd_col_lift;	/* lift value for data collection */
		float	cmd_col_phis;	/* phi start for data collection */
		float	cmd_col_omegas;	/* omega start for data collection */
		float	cmd_col_kappas;	/* kappa start for data collection */
		float	cmd_col_osc_width;  /* oscillation width/image */
		int	cmd_col_axis;	/* 1 for phi, 0 for omega */
		int	cmd_col_newdark;    /* 1 for a new dark current image, else 0 */
		int	cmd_col_anom;	    /* 1 for anomalous data */
		int	cmd_col_wedge;	    /* wedge (#frames per batch) size for anom data */
		int	cmd_col_n_images;   /* number of images to collect */
		int	cmd_col_n_passes;   /* number of osc passes/image */
		float	cmd_col_time;	    /* data collection time/image */
		int	cmd_col_mode;	    /* 0 = collect time, 1 dose */
		int	cmd_col_image_number; /* start image number */
		char	cmd_col_dir[132];   /* directory for output images */
		char	cmd_col_prefix[30]; /* image name prefix */
		char	cmd_col_suffix[30]; /* image name suffix */
		int	cmd_col_adc;	    /* adc select */
		int	cmd_col_bin;	    /* bin select */
		float	cmd_col_xcen;	    /* x detector center in mm for oblique correction */
		float	cmd_col_ycen;	    /* y detector center in mm for oblique correction */
		int	cmd_col_compress;   /* 0 for none, 1 for .Z, 2 for .pck */
		float	cmd_col_dzratio;    /* ratio of 2nd picture expos time to 1st */
		int	cmd_col_dkinterval; /* interval between darks */
		int	cmd_col_rep_dark;   /* 1 to repeat darks every darkinterval seconds */
		int	cmd_col_dk_before;  /* 1 to repeat darks before each run */
		int	cmd_col_outfile_type;	/* 0 for 16 bit, 1 for 32 bit, 2 for 16 + overflow records */
		int	cmd_col_no_transform;	/* 1 to not transform data */
		int	cmd_col_output_raws;	/* 1 to output raws */
		float	cmd_col_step_size;	/* size of step for step/dose mode */
		float	cmd_col_dose_step;	/* dose per step, step/dose mode */
		float	cmd_col_atten_run;	/* attenuator amount for this run */
		float	cmd_col_hslit_run;	/* horiz slit amount for this run */
		float	cmd_col_vslit_run;	/* vertical slit amount for this run */
		float	cmd_col_autoal_run;	/* autoalign every run */
		float	cmd_col_run_wave;
		int	cmd_col_mad_mode;	/* 0 never, 1 per run, 2 per wedge, 3 per nframes */
		int	cmd_col_mad_nframes;	/* for mode = 3, number of frames between wavelength changes */
		int	cmd_col_mad_nwave;	/* number of wavelengths */
		float	cmd_col_mad_wavelengths[10];	/* wavelengths */
		float	cmd_col_do_wavelength;	/* used after runs are expanded in the queue */
		int	cmd_col_remarkc;    	/* number of remark records */
		int	cmd_col_restart_run;		/* run number for restart */
		int	cmd_col_restart_image;		/* image number for restart */
		char	*cmd_col_remarkv[MAXREMARK];  /* pointers to remarks */
		char	cmd_col_blcmd[BLCMDMAX];
	       };

typedef struct mdc_command mdc_command;

enum {
	MDC_COM_EOC = 0,
	MDC_COM_EXIT,
	MDC_COM_CONFIG,
	MDC_COM_STARTUP,
	MDC_COM_ERASE,
	MDC_COM_INIT,
	MDC_COM_STOP,
	MDC_COM_ABORT,
	MDC_COM_DMOVE,
	MDC_COM_PMOVE,
	MDC_COM_PMOVEREL,
	MDC_COM_DSET,
	MDC_COM_PSET,
	MDC_COM_LMOVE,
	MDC_COM_LSET,
	MDC_COM_WMOVE,
	MDC_COM_WSET,
	MDC_COM_SHUT,
	MDC_COM_SCAN,
	MDC_COM_OMOVE,
	MDC_COM_OMOVEREL,
	MDC_COM_OSET,
	MDC_COM_KMOVE,
	MDC_COM_KSET,
	MDC_COM_COLL,
	MDC_COM_SNAP,
	MDC_COM_GONMAN,
	MDC_COM_HOME,
	MDC_COM_AMOVE,
	MDC_COM_AUTOALIGN,
	MDC_COM_SET_MASTER,
	MDC_COM_GET_CLIENTS,
	MDC_COM_EXPERIMENT_MODE_MOVE,
	MDC_COM_HSLIT,
	MDC_COM_VSLIT,
	MDC_COM_XL_HS_MOVE,
	MDC_COM_XL_VS_MOVE,
	MDC_COM_XL_UP_HHS_MOVE,
	MDC_COM_XL_UP_VHS_MOVE,
	MDC_COM_XL_DN_HHS_MOVE,
	MDC_COM_XL_DN_VHS_MOVE,
	MDC_COM_XL_GUARD_HS_MOVE,
	MDC_COM_XL_GUARD_VS_MOVE,
	MDC_COM_HOLDING,
	MDC_COM_QLIST,
	MDC_COM_QFLUSH,
	MDC_COL_DIST,
	MDC_COL_PHIS,
	MDC_COL_OSCW,
	MDC_COL_NIM,
	MDC_COL_DEZING,
	MDC_COL_TIME,
	MDC_COL_IMNO,
	MDC_COL_DIR,
	MDC_COL_PRE,
	MDC_COL_SUF,
	MDC_COL_MODE,
	MDC_COL_WAVE,
	MDC_COL_REMARK,
	MDC_COL_LIFT,
	MDC_COL_ADC,
	MDC_COL_BIN,
	MDC_COL_CENTER,
	MDC_COL_KSTART,
	MDC_COL_OSTART,
	MDC_COL_AXIS,
	MDC_COL_NDARK,
	MDC_COL_ANOM,
	MDC_COL_WEDGE,
	MDC_COL_COMPRESS,
	MDC_COL_BLCMD,
	MDC_COL_DZRATIO,
	MDC_COL_DKIVAL,
	MDC_COL_DKREP,
	MDC_COL_DKBEF,
	MDC_COL_OFILE,
	MDC_COL_NO_TRANSFORM,
	MDC_COL_OUTPUT_RAWS,	
	MDC_COL_STEP_SIZE,
	MDC_COL_DOSE_STEP,
	MDC_COL_MAD,
	MDC_COL_MAD_WAVE,
	MDC_COL_RESTART_RUN,
	MDC_COL_RESTART_IMAGE,
	MDC_COL_ATTEN_RUN,
	MDC_COL_AUTOAL_RUN,
	MDC_COL_HSLIT_RUN,
	MDC_COL_VSLIT_RUN
	};

#define	MAXQUEUE	100

#define	MAX_CMD		16

/*
 *	These are defines which are common to all
 *	scanners.  They form the first level
 *	initialization to the programs specific
 *	scanner variables.  These values may be
 *	overridden by a user supplied configuration
 *	table.
 */

#define	SPECIFIC_PHI_STEPS_DEG	(500)
#define	SPECIFIC_DIST_STEPS_MM	(100)
#define	SPECIFIC_PHI_TOP_SPEED	(2000)
#define	SPECIFIC_DIST_TOP_SPEED	(1000)
#define	SPECIFIC_DIST_MAX_POINT	(42500)
#define	SPECIFIC_DIST_MIN_POINT	(6500)
#define	SPECIFIC_UNITS_PER_SEC	(1000)
#define	SPECIFIC_UNITS_PER_DOSE	(1000)
#define	SPECIFIC_WAVELENGTH	(1.5418)
#define	SPECIFIC_IS_DIST	(1)
#define	SPECIFIC_IS_PHI		(1)
#define	SPECIFIC_MULTIPLIER	(4.)
#define	SPECIFIC_FLAGS		(0)
#define	SPECIFIC_LIFT_STEPS_MM	(100)
#define	SPECIFIC_LIFT_TOP_SPEED (1000)
#define	SPECIFIC_LIFT_MAX_POINT	(15000)
#define	SPECIFIC_LIFT_MIN_POINT	(0)
#define	SPECIFIC_IS_LIFT	(0)

#define	SPECIFIC_NC_POINTER	(0)
#define	SPECIFIC_NC_INDEX	(0)
#define	SPECIFIC_NC_X		(0)
#define	SPECIFIC_NC_Y		(0)
#define	SPECIFIC_NC_REC		(0)
#define	SPECIFIC_NC_POFF	(0)

#define	SPECIFIC_SCSI_ID	(2)
#define	SPECIFIC_SCSI_CONTROLLER	(0)
#define	SPECIFIC_SPIRAL_CHECK	(1)

#define	SPECIFIC_READ_FAST	(2.2)
#define	SPECIFIC_READ_SLOW	(8.7)
#define	SPECIFIC_READ_OVERHEAD	(1.0)
#define	SPECIFIC_BIN_FACTOR	(2.7)
#define	SPECIFIC_IS_KAPPA	(0)
#define	SPECIFIC_IS_OMEGA	(0)
#define	SPECIFIC_DEF_DEZINGER	(0)
#define	SPECIFIC_IS_2THETA	(0)
#define	SPECIFIC_PCSHUTTER	(0)
#define	SPECIFIC_DARK_INTERVAL	(0)
#define	SPECIFIC_PIXEL_SIZE	(0.085)
#define	SPECIFIC_DK_BEFORE_RUN	(1)
#define	SPECIFIC_OUTFILE_TYPE	(0)
#define	SPECIFIC_DETECTOR_SN	(-1)
#define	SPECIFIC_NO_TRANSFORM	(0)
#define	SPECIFIC_OUTPUT_RAWS	(0)
#define	SPECIFIC_J5_TRIGGER	(0)
#define	SPECIFIC_TIMECHECK	(0)
#define	SPECIFIC_CONSTRAIN_OMEGA	(360)
#define	SPECIFIC_CONSTRAIN_PHI		(360)
#define	SPECIFIC_CONSTRAIN_KAPPA	(360)
#define	SPECIFIC_STRIP_AVE	(0)
#define SPECIFIC_BCHK_TIME      (2.)
#define SPECIFIC_BCHK_DELTAPHI  (0.1)
#define SPECIFIC_IS_WAVELENGTH  (0)
#define SPECIFIC_APPROACH_START (0.0)
#define SPECIFIC_CHIP_SIZE_X      (1152)
#define SPECIFIC_CHIP_SIZE_Y      (1152)
#define SPECIFIC_KAPPA_CONST    (50.0)
#define SPECIFIC_MADRUN_NAMING  (0)
#define SPECIFIC_RETRYSHORT  	(0)
#define	SPECIFIC_CCD_MODULAR	(0)
#define SPECIFIC_PF_MOD         (0)
#define SPECIFIC_USESTOP_IMMEDIATE       (0)
#define	SPECIFIC_MIN_VELOCITY	(.0001)
#define	SPECIFIC_MAX_VELOCITY	(100.0)
#define	SPECIFIC_ALLOW_STILLS	(0)
#define	SPECIFIC_PITCH_TUNE_DELTA (0)
#define SPECIFIC_BM8_MOD	(0)
#define SPECIFIC_BL_IS_SERVER	(0)
#define	SPECIFIC_BEAM_SENSE	(0)
#define	SPECIFIC_T2K_DETECTOR	(0)
#define	SPECIFIC_ADSC_SLIT	(0)

/*
 *	These are scanner specific values, in the
 *	sense that they differ from TYPE of scanner.
 *
 *	They form the first level initialization to
 *	the programs specific scanner variables.
 *	These values may be overridden by a user
 *	supplied configration file.
 *
 *	Possible defines: (ONLY one may be defined)
 *
 *	#define	SCANNER_TYPE_BIG_BIG	1
 *	#define	SCANNER_TYPE_SMALL_HOLE	1
 */

#define	SCANNER_TYPE_SMALL_HOLE	1

#ifdef SCANNER_TYPE_BIG_BIG

#define	SPECIFIC_ERASE_TIME		(40.)
#define	SPECIFIC_SCAN_TIME		(136.)
#define	SPECIFIC_DC_ERASE_TIME		(70.)
#define	SPECIFIC_TOTAL_VALID_BLOCKS	(11952)
#define	SPECIFIC_TOTAL_PIXELS_X		(2000)
#define	SPECIFIC_TOTAL_PIXELS_Y		(2000)

#endif /* SCANNER_TYPE_BIG_BIG */

#ifdef SCANNER_TYPE_SMALL_HOLE

#define	SPECIFIC_ERASE_TIME		(34.)
#define	SPECIFIC_SCAN_TIME		(100.)
#define	SPECIFIC_DC_ERASE_TIME		(39.)
#define SPECIFIC_TOTAL_VALID_BLOCKS	(4224)
#define	SPECIFIC_TOTAL_PIXELS_X		(1200)
#define	SPECIFIC_TOTAL_PIXELS_Y		(1200)

#endif /* SCANNER_TYPE_SMALL_HOLE */

#ifdef SCANNER_TYPE_SMALL

#define	SPECIFIC_ERASE_TIME		(34.)
#define	SPECIFIC_SCAN_TIME		(75.)
#define	SPECIFIC_DC_ERASE_TIME		(54.)
#define SPECIFIC_TOTAL_VALID_BLOCKS	(4352)
#define	SPECIFIC_TOTAL_PIXELS_X		(1200)
#define	SPECIFIC_TOTAL_PIXELS_Y		(1200)
#define	SPECIFIC_MULTIPLIER		(4.)

#endif /* SCANNER_TYPE_SMALL */


enum tak_fancymode_type_enum {
    			TAK_FANCYMODE_OTHER = 0,
			TAK_FANCYMODE_DBM,
			TAK_FANCYMODE_GSA,
			TAK_FANCYMODE_FBSA,
			TAK_FANCYMODE_RBSA,
			TAK_FANCYMODE_LM,
			TAK_FANCYMODE_CC,
			TAK_FANCYMODE_EXAFSM,
			TAK_FANCYMODE_DC
			     };


#define	CF_BL_READY		0
#define	CF_BL_NOTREADY_BEFORE	1
#define	CF_BL_NOTREADY_AFTER	2
