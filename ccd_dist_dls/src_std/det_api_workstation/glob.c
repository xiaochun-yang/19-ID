#include	"defs.h"

/*
 *	These module definitions are on the "receiving side"
 */
FILE			*fperr;
FILE			*fpout;
FILE			*fpdiag;
FILE			*fplog;

int			verbose = 1;

int 			n_ctrl;
int 			u_ctrl[MAX_CONTROLLERS];
BYTE			pv_bn[MAX_CONTROLLERS];
struct q_moddef		qmod[MAX_CONTROLLERS];
struct q_conkind	qc[MAX_CONTROLLERS];
time_t			tmp_sample_time;

char			somsg[1024];
char			semsg[1024];

double			read_temp_val[MAX_CONTROLLERS];
double			set_temp_value;
double			ramp_temp_value;

int 			diskbased;
int 			send_square;
int 			control_dets;
char			disk_dir[256];
int 			det_api_module;
int 			save_raw;
int 			transform_image;
int 			image_kind;
int 			data_fd[MAX_CONTROLLERS];
int				ccd_serial_number;
int				ccd_uniform_pedestal;
int				env_detector_sn;

struct chip_patch	mod_patches[MAX_CONTROLLERS][MAX_PATCHES];
int 			chip_npatches[MAX_CONTROLLERS];
struct chip_patch	mod_patches_hb[MAX_CONTROLLERS][MAX_PATCHES];
int 			chip_npatches_hb[MAX_CONTROLLERS];
int			ccd_temp_update_sec;
int			ccd_command_idle_sec;
int			ccd_cycle_temp_count;
int			ccd_send_bufsize;

/*
 *	mserver globals, threads, and mutexes.
 */

int			ccd_use_mserver;
int			mserver_table_length;
int			mserver_mem_limit;
int			mserver_mem_use;

struct mserver_buf	*dp_table;

int			mserver_active_index;
int			mserver_insert_index;

#ifdef unix

pthread_mutex_t	h_mutex_mem = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t	mserver_active_index_cond  = PTHREAD_COND_INITIALIZER;
pthread_mutex_t	mserver_insert_index_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t	h_mutex_table  = PTHREAD_COND_INITIALIZER;
pthread_t	mserver_dispatcher_thread;

#endif /* unix */

#ifdef WINNT

HANDLE		h_mserver_dispatcher_thread;
HANDLE		h_mutex_mem;
HANDLE		h_mutex_table;

#endif /* WINNT */

/*
 *	hw dispatcher mutexes, threads.
 */

int 	hw_cmd_no;
int 	hw_cmd_ret;
int 	hw_thread_running;

#ifdef unix

pthread_cond_t	h_mutex_hw_cmd  = PTHREAD_COND_INITIALIZER;
pthread_cond_t	h_mutex_hw_ret  = PTHREAD_COND_INITIALIZER;
pthread_cond_t	h_mutex_hw_th_start  = PTHREAD_COND_INITIALIZER;
pthread_t	h_hw_thread;
HANDLE		h_hw_cmd_start_event;
HANDLE		h_hw_cmd_finish_event;

#endif /* unix */

#ifdef WINNT

HANDLE		h_hw_thread;
HANDLE		h_mutex_hw_cmd;
HANDLE		h_mutex_hw_ret;
HANDLE		h_mutex_hw_th_start;
HANDLE		h_hw_cmd_start_event;
HANDLE		h_hw_cmd_finish_event;

#endif /* WINNT */

int 	command_s;              /* listens on this socket */
int 	data_s;                 /* listens on this socket */
int 	command_port_no;        /* TCPIP port number for commands */
int 	data_port_no;           /* TCPIP port number for data */
int 	command_fd;             /* file descriptor for commands after connection */
int 	sec_command_s;  /* for secondary command entry */
int 	sec_command_fd;
int 	sec_command_port_no;

char   *detterm = "end_of_det\n";

/*
 *      data base detector definition for the "sending side"
 */

struct q_moddef qm[MAX_CONTROLLERS];

/*
 *      host, port database
 */

int 	q_ncon;                                 /* number of connections which need to be made */
char	q_hostnames[MAX_CONTROLLERS][256];      /* host name */
int 	q_ports[MAX_CONTROLLERS];               /* port numbers */
int 	q_dports[MAX_CONTROLLERS];              /* data ports */
int 	q_sports[MAX_CONTROLLERS];              /* secondary command ports */


int 	q_blocks[MAX_CONTROLLERS][MAX_CONTROLLERS];     /* assigned data blocks from each connection */
int 	q_states[MAX_CONTROLLERS];
int 	q_issync[MAX_CONTROLLERS];

int 	q_nctrl;                                                                /* number of modules */

int	q_ncols_raw = -1;
int	q_nrows_raw = -1;
int	q_image_size = -1;

int 	ccd_detector_type = CCD_TYPE_T2K;

int 	ccd_adc;
int 	ccd_trigger_mode;
int 	ccd_row_bin;
double  ccd_exp_time;

int 	ccd_state = STATE_IDLE;
int 	ccd_hardware = CCD_HARDWARE_BAD;
int 	ccd_synch;			/* 1 for synchoronous operation, 0 for asynchronous operation */

char *reply_term = REPLY_TERM_STRING;

char    replybuf[RBUFSIZE];
int 	rbufind;

char    det_outbuf[20480];
char    det_reply_single[10240+512];
char    det_reply[10240+512];

char            inbuf[INBUFSIZE];
int                     inbufind;
int                     command_number;                                 /* from the command enum */
int                     processing_command;                             /* state variable during parse */
int                     input_header_size;                              /* current value for header size in bytes */
int                     input_header_ind;
char            input_header[CCD_HEADER_MAX];   /* storage for same */

char            ccd_info[256];                                  /* just an informational tag for log files */

struct input_pair command_list[] =
  {
        START_CMD,                      "start",
        STOP_CMD,                       "stop",
        FLUSH_CMD,                      "flush",
        ABORT_CMD,                      "abort",
        RESET_CMD,                      "reset",
        SETPARAM_CMD,           "setparam",
        GETPARAM_CMD,           "getparam",
        STATUS_CMD,                     "status",
        WAIT_CMD,                       "wait",
        EXIT_CMD,                       "exit",
        SHUTTER_CMD,            "shutter",
        TEMPREAD_CMD,           "temp_read",
        TEMPSET_CMD,            "temp_set",
        TEMPRAMP_CMD,           "temp_ramp",
        ABORTTEMP_CMD,          "abort_temp",
        STOPR_CMD,                      "stopr",
        STOPW_CMD,                      "stopw",
        FLUSHB_CMD,                     "flushb",
        FLUSHE_CMD,                     "flushe",
        HWRESET_CMD,            "hwreset",
        POWERUPINIT_CMD,        "powerupinit",
        LOADFILE_CMD,           "loadfile",
        TIMESYNC_CMD,           "timesync",
        -1,                                     NULL,
  };

struct input_pair modifier_list[] =
  {
        END_OF_DET_MOD,         "end_of_det",
        MODE_MOD,               "mode",
        TRIGGER_MOD,            "trigger",
        SYNCH_MOD,              "synch",
        TIME_MOD,               "time",
        TIMECHECK_MOD,          "timecheck",
        ADC_MOD,                "adc",
		HW_BIN_MOD,				"hw_bin",
        ROW_BIN_MOD,            "row_bin",
        COL_BIN_MOD,            "col_bin",
        ROW_OFF_MOD,            "row_off",
        COL_OFF_MOD,            "col_off",
        ROW_XFER_MOD,           "row_xfer",
        COL_XFER_MOD,           "col_xfer",
        HEADER_SIZE_MOD,        "header_size",
        INFO_MOD,               "info",
        ALL_MOD,                "all",
        PCSHUTTER_MOD,          "pcshutter",
        J5_TRIGGER_MOD,         "j5_trigger",
        STRIP_AVE_MOD,          "strip_ave",
        TEMP_READ_MOD,          "temp_read",
        TEMP_SET_MOD,           "temp_set",
        TEMP_RAMP_MOD,          "temp_ramp",
        TEMP_TARGET_MOD,        "temp_target",
        TEMP_FINAL_MOD,         "temp_final",
        TEMP_STATUS_MOD,        "temp_status",
        TEMP_INCREMENT_MOD,     "temp_increment",
        CONFIG_MOD,             "config",
        SAVE_RAW,               "save_raw",
        TRANSFORM_IMAGE,        "transform_image",
        IMAGE_KIND,             "image_kind",
        XFDATAFD_MOD,           "xfdatafd",
	STORED_DARK,		"stored_dark",
	LOADFILE,		"loadfile",
        -1,                     NULL
  };

int             ccd_nrows;              /* number of rows in the ccd */
int             ccd_ncols;              /* number of columns in the ccd */
int             ccd_row_off;            /* origin along the rows for sending to user */
int             ccd_col_off;            /* origin along the cols for sending to user */
int             ccd_row_xfersize;       /* number of rows to be sent to user */
int             ccd_col_xfersize;       /* number of cols to be sent to user */

int             ccd_row_bin;            /* binning factor along rows */
int             ccd_col_bin;            /* binning factor along cols */

/*
 *      Operational paramters.
 */

int             ccd_trigger_mode;       /* 1 for ext_trig, 0 for timed exposure */
int             ccd_timedose_mode;      /* 0 for time, 1 for dose */
double  ccd_exp_time;           /* exposure time, if needed */
int             ccd_adc;                /* 0 for slow, 1 for fast */
int             ccd_timecheck;          /* 1 for a rationality check on timing, else 0 */
int     ccddet_usej5;
int      ccddet_j5shutter;  /* 1 to operate suuter w/expos */
float   strip_ave[MAX_CONTROLLERS];

double  current_temp[MAX_CONTROLLERS];
double  target_temp[MAX_CONTROLLERS];
double  final_temp[MAX_CONTROLLERS];
double  increment_temp[MAX_CONTROLLERS];
int     temp_moving[MAX_CONTROLLERS];
int		no_temp_readback;

/* 	ldcon.c old globals */

/*
 *      This variable controls the mode of data collection,
 *      either real or fake.
 */

int     internal_transform = 1;

int     ccddet_mode = 1;        /* default is real data for now */
int     ccddet_usej5 = 0;
int     ccddet_j5on = 0x00f0;
int     ccddet_j5off = 0x0000;
/*
 *      Kludgy shutter also uses j5.
 */
int     ccddet_j5shutter = 0;
int     ccddet_j5shutteron = 0x00C0;
int     ccddet_j5shutteroff = 0x0000;

float   det_time;
int     det_adc;
int     det_bin;
int     use_trigger;
int     previous_bin = 1;       /* used to reset ROI when it changes */
int     sw_bin = 1;
int     do_sw_bin = 0;
int		hw_bin = 0;
int 	retry_on_bin_change = 0;

char    harray[2][CCD_HEADER_MAX];
int     harray_size[2];
unsigned short  dbuf[MAXLBUF];
int     bdbuf[MAXLBUF];

DWORD   pv_bn_pcioff = 0x40;
DWORD   pv_start_exttrig = 0x0c;
DWORD   pv_end_exttrig = 0x08;
int     pv_gentimeout = 3500;

int     mem_allocated[MAX_CONTROLLERS] = {0};
long    buffer_size;
HANDLE  hglb[MAX_CONTROLLERS][2];
HANDLE  hglbi[MAX_CONTROLLERS][2];
void     *lpvBuf;
void     *lpvBuffer[MAX_CONTROLLERS];
void     *lpvBuffer_1[MAX_CONTROLLERS];
void     *lpvarray[2][MAX_CONTROLLERS];
char     lpv_raw_header[2][MAX_CONTROLLERS][CCD_HEADER_MAX];
void     *lpvimage[2][MAX_CONTROLLERS];
char     lpv_image_header[2][MAX_CONTROLLERS][CCD_HEADER_MAX];
HANDLE   hFh[2][MAX_CONTROLLERS];
int      lpvcollected[2];
int      raw_action[2];
int      xform_action[2];
int      kind_action[2];
int      lpvwhich;
int      initialize_flag = 0;
int             done_flag;
int             controller_ok;
unsigned int    error_code;
unsigned int    status;
int             sensor_x, sensor_y;

int             current_adc;
int             current_trig;
double          current_time;
char            timecopy[256];
char            disk_files[2][256];

int             t2k_chan_xsize = T2K_CHAN_XSIZE;
int             t2k_chan_ysize = T2K_CHAN_YSIZE;
WORD            t2k_roi_xstart = T2K_ROI_XSTART;
WORD            t2k_roi_ystart = T2K_ROI_YSTART;
WORD            t2k_roi_xend   = T2K_ROI_XEND;
WORD            t2k_roi_yend   = T2K_ROI_YEND;

int 	t2k_xsize          = T2K_ROI_XEND - T2K_ROI_XSTART + 1;
int 	t2k_ysize          = T2K_ROI_YEND - T2K_ROI_YSTART + 1;

int 	start_exposure_time;    /* these are used to give net total exp time */
int 	end_exposure_time;
int 	precise_start_time;
int 	precise_end_time;

int 	local_header_size;
int 	ccd_hw_abort;
int 	local_ccd_col_off[MAX_CONTROLLERS];

int 	dbg_suspend;
int	use_stored_dark = 0;
int	use_loadfile = 0;
char	loadfile_name[256];
