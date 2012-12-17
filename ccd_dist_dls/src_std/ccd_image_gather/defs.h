#include	<stdio.h>
#include	<math.h>
#include	<errno.h>
#include	<signal.h>
#include	<pwd.h>
#include	<sys/types.h>
#include	<sys/time.h>
#include	<sys/socket.h>
#include	<netinet/in.h>

#ifdef alpha
#include	<string.h>
#endif /* alpha */

#include	"../incl/q_moddef.h"

/*
 *	Definitions concerning the particular hardware used.
 */

/*
 *	Actual size for the EEV CCD chip.
 */

#define	EEV_NROWS	1152
#define	EEV_NCOLS	1242

/*
 *	States and modes.
 */

#define	CCD_TRIG_TIME	0
#define	CCD_TRIG_EXT	1

#define	CCD_MODE_TIME	0
#define	CCD_MODE_DOSE	1

#define	CCD_MODE_ASYNCH	0
#define	CCD_MODE_SYNCH	1

#define	CCD_ADC_SLOW	0
#define	CCD_ADC_FAST	1

#define	CCD_START_OK	0
#define	CCD_START_ERROR	1

#define	CCD_STOP_OK	0
#define	CCD_STOP_RETRY	1
#define	CCD_STOP_ERROR	2

#define	XFORM_INIT_OK		0
#define	XFORM_INIT_ERROR	1

#define	CCD_HEADER_MAX	20480

/*
 *	Some environment names.
 */

#define	CCD_XFORM_API_CPORT	"CCD_XFPORT"
#define	CCD_DET_API_DPORT	"CCD_DTDPORT"
#define	CCD_DET_API_HOSTNAME	"CCD_DTDHOSTNAME"
#define	CCD_CALFIL		"CCD_CALFIL"
#define	CCD_NONUNF		"CCD_NONUNF"
#define	CCD_POSTNUF		"CCD_POSTNUF"
#define	CCD_N_CTRL		"CCD_N_CTRL"
#define	CCD_U_CTRL		"CCD_U_CTRL"
#define	CCD_M_ROTATE		"CCD_M_ROTATE"
#define	XFORMSTATUSFILE		"XFORMSTATUSFILE"
#define	CCD_DEZ_AVERAGE		"CCD_DEZ_AVERAGE"
#define	CCD_PEDESTAL		"CCD_PEDESTAL"
#define	CCD_X_INT		"CCD_X_INT"
#define	CCD_Y_INT		"CCD_Y_INT"
#define	CCD_CALPAR		"CCD_CALPAR"
#define	CCD_RAW_SATURATION	"CCD_RAW_SATURATION"

#define	CCD_XFORM_API_LOGFILE	"LOG_XF_FILE"

/*
 *	Used for fplog if no logging.
 */

#define	CCD_NULLFILE		"/dev/null"

/*
 *	Buffer sizes, etc.
 */

#define	INBUFSIZE	1024000
#define	RBUFSIZE	4096
#define	MERGE_HEADER_SIZE	20480

#define	SCANNING_FOR_COMMAND		0
#define	SCANNING_FOR_MODIFIERS		1
#define	SCANNING_FOR_MERGE_HEADER	2

struct input_pair {
			int	cmd_tag;
			char	*cmd_string;
		  };

enum command_enum {
			COPY_CMD = 0,
			XFORM_CMD,
			RESET_CMD,
			SETPARAM_CMD,
			GETPARAM_CMD,
			STATUS_CMD,
			EXIT_CMD
		  };

enum modifier_enum {
			END_OF_DET_MOD = 0,
			INFILE_MOD,
			OUTFILE_MOD,
			RAWFILE_MOD,
			KIND_MOD,
			SAVE_RAW_MOD,
			ROW_BIN_MOD,
			COL_BIN_MOD,
			ROW_XFER_MOD,
			COL_XFER_MOD,
			HEADER_SIZE_MOD,
			ROW_MM_MOD,
			COL_MM_MOD,
			DIST_MM_MOD,
			TWO_THETA_MOD,
			WAVE_MOD,
			REPLY_MOD,
			ALL_MOD,
			COMPRESS_MOD,
			DZRATIO_MOD,
			OUTFILE_TYPE_MOD,
			DETECTOR_SN_MOD,
			STRIP_AVE_MOD,
			MERGE_HEADER_BYTES_MOD
		      };

#define	REPLY_TERM_STRING	"end_of_det\n"
#define	REPLY_OK_STRING		"OK\n"
#define	REPLY_RETRY_STRING	"RETRY\n"
#define	REPLY_ERROR_STRING	"ERROR\n"

#define	SOCKET_STRING		"<socket>"

#define	KIND_DARK_0	0
#define	KIND_DARK_1	1
#define	KIND_DARK_2	2
#define	KIND_DARK_3	3
#define	KIND_RAW_0	4
#define	KIND_RAW_1	5

#define	MAX_CONTROLLERS	9

#define	OUTFILE_16	0
#define	OUTFILE_32	1
#define	OUTFILE_CBF	8

#define N_KIND		(4)	/* # of different kind of images */
#define MAX_MODULES	(4)	/* # of ccd chips in the array */

