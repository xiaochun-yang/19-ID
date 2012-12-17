#include	<stdio.h>
#include	"../incl/ccdconv.h"
#include	"../incl/esd.h"
#include	"../incl/esd_com.h"
#include	"../incl/mardefs.h"
#include	"../incl/ccdsys.h"
#include	<errno.h>
#include	<signal.h>
#include	<stdlib.h>

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

#define	MAXREMARK	100

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
		int	cmd_col_axis;	    /* 1 for phi data collection, 0 for omega */
		int	cmd_col_n_images;   /* number of images to collect */
		int	cmd_col_n_passes;   /* number of osc passes/image */
		float	cmd_col_time;	    /* data collection time/image */
		int	cmd_col_mode;	    /* 0 = collect time, 1 dose */
		int	cmd_col_image_number; /* start image number */
		char	cmd_col_dir[132];   /* directory for output images */
		char	cmd_col_prefix[30]; /* image name prefix */
		char	cmd_col_suffix[30]; /* image name suffix */
		int	cmd_col_adc;
		int	cmd_col_bin;
		float	cmd_col_xcen;
		float	cmd_col_ycen;
		int	cmd_col_remarkc;    /* number of remark records */
		char	*cmd_col_remarkv[MAXREMARK];  /* pointers to remarks */
	       };

typedef struct mdc_command mdc_command;

enum {
		MDC_COM_EOC  =	0,
		MDC_COM_EXIT	,
		MDC_COM_CONFIG	,
		MDC_COM_STARTUP	,
		MDC_COM_ERASE	,
		MDC_COM_INIT	,
		MDC_COM_STOP	,
		MDC_COM_ABORT	,
		MDC_COM_DMOVE	,
		MDC_COM_PMOVE	,
		MDC_COM_PMOVEREL	,
		MDC_COM_DSET	,
		MDC_COM_PSET	,
		MDC_COM_LMOVE	,
		MDC_COM_LSET	,
		MDC_COM_SHUT	,
		MDC_COM_SCAN	,
		MDC_COM_OMOVE   ,
		MDC_COM_OMOVEREL	,
		MDC_COM_OSET    ,
		MDC_COM_KMOVE   ,
		MDC_COM_KSET    ,
		MDC_COM_WMOVE   ,
		MDC_COM_BL_READY,
		MDC_COM_ATTENUATE,
		MDC_COM_AUTOALIGN,
		MDC_COM_SET_MASTER,
		MDC_COM_GET_CLIENTS,
		MDC_COM_EXPERIMENT_MODE_MOVE,
		MDC_COM_HSLIT	,
		MDC_COM_VSLIT	,
		MDC_COM_XL_HS_MOVE,
		MDC_COM_XL_VS_MOVE,
		MDC_COM_XL_UP_HHS_MOVE,
		MDC_COM_XL_UP_VHS_MOVE,
		MDC_COM_XL_DN_HHS_MOVE,
		MDC_COM_XL_DN_VHS_MOVE,
		MDC_COM_OMEGA_CONT,
		MDC_COM_PHI_CONT,
		MDC_COM_OMEGA_STOP,
		MDC_COM_PHI_STOP,
		MDC_COM_COLL    ,
		MDC_COM_SNAP    ,
		MDC_COM_QLIST   ,
		MDC_COM_QFLUSH  ,
		MDC_COL_DIST    ,
		MDC_COL_PHIS    ,
		MDC_COL_OSCW    ,
		MDC_COL_NIM     ,
		MDC_COL_DEZING  ,
		MDC_COL_TIME    ,
		MDC_COL_IMNO    ,
		MDC_COL_DIR     ,
		MDC_COL_PRE     ,
		MDC_COL_SUF     ,
		MDC_COL_MODE    ,
		MDC_COL_WAVE    ,
		MDC_COL_REMARK  ,
		MDC_COL_LIFT    ,
		MDC_COL_ADC     ,
		MDC_COL_BIN     ,
		MDC_COL_CENTER  ,
		MDC_COL_KSTART  ,
		MDC_COL_OSTART  ,
		MDC_COL_AXIS  
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
