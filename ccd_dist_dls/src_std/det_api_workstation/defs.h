/*
 *	unix
 */

#ifdef unix
#include	<stdio.h>
#include	<math.h>
#include	<errno.h>
#include        <sys/types.h>
#include        <sys/time.h>
#include        <sys/socket.h>
#include        <netinet/in.h>
#include	<netdb.h>
#include	<signal.h>
#include	<pthread.h>
#include	<string.h>
#include	<unistd.h>
#include	<stdlib.h>
#endif /* unix */

#ifdef alpha
#include	<string.h>
#endif /* alpha */

#ifdef sgi
#undef	qmod
char	*getenv();
#endif /* sgi */

/*
 *  Win NT includes
 */

#ifdef	WINNT
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <fcntl.h>
#include <winsock.h>
#include <time.h>
#include <sys/timeb.h>
#include <malloc.h>
#include <math.h>
#include <io.h>
#include <errno.h>
#include <signal.h>
#include "windows.h"
#endif /* WINNT */

/*
 *	Compatibility
 */

#ifdef unix
#include	"win_compat.h"
#endif /* unix */

/*
 *	Device or hardware specific things.
 */

#include	"pvapi.h"

#include	"q_moddef.h"

/*
 *	Machine specific defines.
 */

#define	huge


/*
 *	Definitions concerning the particular hardware used.
 */


#define	MAX_CONTROLLERS	9

/*
 *	Total Area read out for Thomson 2K chip.
 *
 *	This is to include any extra rows/cols which are read
 *	out for reference, fiducial, or any other reason.
 */

#define T2K_ROI_XSTART          0               /* Start x for readout region, one corner */
#define T2K_ROI_XEND            1079    /* End x for readout region, one corner */
#define T2K_ROI_YSTART          2               /* Start y for readout region, one corner */
#define T2K_ROI_YEND            1063    /* End y for readout region, one corner */

#define T2K_CHAN_XSIZE  T2K_ROI_XEND + 1        /* Max size for a corner in x */
#define T2K_CHAN_YSIZE  T2K_ROI_YEND + 1        /* Max size for a corner in y */

#define T2K_ROI_XSTART_BIN      2               /* Start x for readout region, one corner */
#define T2K_ROI_XEND_BIN        1081   /* End x for readout region, one corner */
#define T2K_ROI_YSTART_BIN      2               /* Start y for readout region, one corner */
#define T2K_ROI_YEND_BIN        1063    /* End y for readout region, one corner */

/*
 *	The total size of the image you get is 4 * T2K_XSIZE * T2K_YSIZE
 */

#define	T2K_XSIZE	(T2K_ROI_XEND - T2K_ROI_XSTART + 1)
#define	T2K_YSIZE	(T2K_ROI_YEND - T2K_ROI_YSTART + 1)

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

#define	CCD_INIT_OK	0
#define	CCD_INIT_ERROR	1

#define	CCD_HEADER_MAX	4508

/*
 *	Some environment names.
 */

#define	CCD_DET_API_CPORT	"CCD_DTPORT"
#define	CCD_DET_API_DPORT	"CCD_DTDPORT"
#define	CCD_DET_COL_OFFSET	"CCD_COL_OFFSET"
#define	CCD_DET_IRQ			"CCD_DET_IRQ"
#define	CCD_DET_ADDR		"CCD_DET_ADDR"
#define	CCD_DET_NCTRL		"CCD_DET_NCTRL"
#define	CCD_DET_IFACE		"CCD_DET_IFACE"
#define	CCD_DET_OFFSET0		"CCD_DET_OFFSET0"
#define	CCD_DET_OFFSET1		"CCD_DET_OFFSET1"
#define	CCD_DET_OFFSET2		"CCD_DET_OFFSET2"
#define	CCD_DET_OFFSET3		"CCD_DET_OFFSET3"


#define	CCD_DET_API_LOGFILE	"LOG_DT_FILE"
#define	ENVIRON_INI_FILE	"CCD_API.ENV"
/*
 *	Used for fplog if no logging.
 */

#define	CCD_NULLFILE		"/dev/null"

#define	DETECTOR_DB			"detector_db.txt"

/*
 *	Buffer sizes, etc.
 */

#define	INBUFSIZE	8192
#define	RBUFSIZE	10240

#define	MAXLBUF		2500

struct input_pair  {
			int	cmd_tag;
			char	*cmd_string;
		  };

enum command_enum {
			START_CMD = 0,
			STOP_CMD,
			FLUSH_CMD,
			ABORT_CMD,
			RESET_CMD,
			SETPARAM_CMD,
			GETPARAM_CMD,
			STATUS_CMD,
			WAIT_CMD,
			EXIT_CMD,
			SHUTTER_CMD,
			TEMPREAD_CMD,
			TEMPSET_CMD,
			TEMPRAMP_CMD,
			ABORTTEMP_CMD,
			STOPR_CMD,
			STOPW_CMD,
			FLUSHB_CMD,
			FLUSHE_CMD,
			HWRESET_CMD,
			POWERUPINIT_CMD,
			LOADFILE_CMD,
			TIMESYNC_CMD,
			CLEANUP_CMD,
			HWINIT_CMD
		  };

enum modifier_enum {
			END_OF_DET_MOD = 0,
			MODE_MOD,
			TRIGGER_MOD,
			SYNCH_MOD,
			TIME_MOD,
			TIMECHECK_MOD,
			ADC_MOD,
			HW_BIN_MOD,
			ROW_BIN_MOD,
			COL_BIN_MOD,
			ROW_OFF_MOD,
			COL_OFF_MOD,
			ROW_XFER_MOD,
			COL_XFER_MOD,
			HEADER_SIZE_MOD,
			INFO_MOD,
			ALL_MOD,
			PCSHUTTER_MOD,
			J5_TRIGGER_MOD,
			STRIP_AVE_MOD,
			TEMP_READ_MOD,
			TEMP_SET_MOD,
			TEMP_RAMP_MOD,
			TEMP_TARGET_MOD,
			TEMP_FINAL_MOD,
			TEMP_INCREMENT_MOD,
			TEMP_STATUS_MOD,
			CONFIG_MOD,
			SAVE_RAW,
			TRANSFORM_IMAGE,
			IMAGE_KIND,
			XFDATAFD_MOD,
			STORED_DARK,
			LOADFILE
		      };

#define KIND_DARK_0     0
#define KIND_DARK_1     1
#define KIND_DARK_2     2
#define KIND_DARK_3     3
#define KIND_RAW_0      4
#define KIND_RAW_1      5

#define	REPLY_TERM_STRING	"end_of_det\n"
#define	REPLY_OK_STRING		"OK\n"
#define	REPLY_RETRY_STRING	"RETRY\n"
#define	REPLY_ERROR_STRING	"ERROR\n"

/*
 *	Simulation info.
 */

#define	SIM_FMT_MAR	0
#define	SIM_FMT_RAW	1

/*
 *	Registry info.  Will go into environ eventually.
 */

#define	PV_REGFILE	"C:\\PixelVision\\cn_t2k.reg"

#ifdef WINNT
WINAPI	pvUseLibraryEx(BYTE byBoardNum, LPCSTR szLibName, BOOL bUpload);
#endif /* WINNT */

void	err_msg(char *s);
void	info_msg(char *s);
int		real_module(int val);

struct chip_patch {
			int	cp_modno;
			int	cp_isvert;
			int	cp_lstart;
			int	cp_lend;
			int	cp_laddr;
			int	cp_lsize;
		  };

#define	MAX_PATCHES	10

struct	mserver_buf {
			int		mserver_alloc;
			int		mserver_index;
			int		mserver_ndet;
			int		mserver_det_bin;
			int		mserver_sw_bin;
			int		mserver_hw_bin;
			int		mserver_adc;
			int		mserver_raw_hlen;
			char		*mserver_raw_hd;
			int		mserver_raw_dlen;
			unsigned short	*mserver_raw_data;
			int		mserver_raw_action;
			int		mserver_raw_sent;
			int		mserver_kind;
			int		mserver_xform_action;
			int		mserver_cor_sent;
			int		mserver_cor_hlen;
			char		*mserver_cor_hd;
			int		mserver_cor_dlen;
			unsigned short	*mserver_cor_data;
		  };

#define	MSERVER_MAX_TABLE_LENGTH	1000

#define HW_CMD_MUTEX_NAME       "hw_mutex_cmd"
#define HW_RET_MUTEX_NAME       "hw_mutex_ret"

/*
 *      Hardare state information.
 */


#define CCD_HARDWARE_BAD        0
#define CCD_HARDWARE_OK         1

#define STATE_IDLE              0
#define STATE_ACCUM             1
#define STATE_READOUT           2

#define CCD_DET_OK              0
#define CCD_DET_RETRY           1
#define CCD_DET_FATAL           2
#define CCD_DET_NOTCONNECTED    3
#define CCD_DET_DISCONNECTED    4

#define	SUSPEND_CHKDATA			1
#define	SUSPEND_START			2
#define	SUSPEND_STOPR			4
#define	SUSPEND_STOPW			8


/*
 *	CCD type.
 */

#define	CCD_TYPE_T2K	0
#define	CCD_TYPE_EEV	1

typedef struct {
        int x1, y1;
        } Point;

typedef struct {
        int x1, y1;
        int x2, y2;
} Area;

#include	"fcns.h"
