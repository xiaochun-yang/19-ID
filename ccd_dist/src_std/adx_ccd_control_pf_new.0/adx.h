/* Commands sent to marcommand() */

#define DRIVE_PHI		(0)
#define SET_PHI			(1)
#define DRIVE_DISTANCE		(2)
#define SET_DISTANCE		(3)
#define OPEN_SHUTTER		(4)
#define CLOSE_SHUTTER		(5)
#define STOP			(6)
#define ABORT			(7)
#define INITIALIZE		(8)
#define ERASE			(9)
#define SCAN			(10)
#define FLUSH_QUEUE		(11)
#define LIST_QUEUE		(12)
#define CONFIGURE		(13)
#define DRIVE_OFFSET    	(14)
#define SET_OFFSET      	(15)
#define	DRIVE_PHI_REL		(16)
#define DRIVE_KAPPA		(17)
#define SET_KAPPA		(18)
#define DRIVE_OMEGA		(19)
#define SET_OMEGA		(20)
#define HOME			(21)
#define GON_MANUAL		(22)
#define DRIVE_WAVELENGTH	(23)
#define SET_WAVELENGTH		(24)
#define	SET_ATTENUATOR		(25)
#define AUTOALIGN		(26)
#define XL_HS			(27)
#define XL_VS			(28)
#define XL_UP_HHS		(29)
#define XL_UP_VHS		(30)
#define XL_DN_HHS		(31)
#define XL_DN_VHS		(32)
#define	HS			(33)
#define	VS			(34)
#define	EM			(35)
#define MAKE_MASTER		(36)
#define	DRIVE_OMEGA_REL		(37)
#define XL_GUARD_HS		(38)
#define XL_GUARD_VS		(39)

#define TIME_MODE		(0)	/* Collect in time mode */
#define DOSE_MODE		(1)	/* Collect in dose mode */
#define COMP_NONE 		(0)	/* No compression */
#define COMP_Z    		(1)	/* Unix .Z compression */
#define COMP_PCK  		(2)	/* Mar .pck compression */

#define CONFIG_1x1  		(0)	/* single module ccd */
#define CONFIG_2x2  		(1)	/* 2x2 ccd */
#define CONFIG_3x3  		(2)	/* 3x3 ccd */
#define CONFIG_DEFAULT 		(0)	/* default */
#define MAR_SMALL 	 	(0)	/* Small Scanner (180) */
#define MAR_LARGE 		(1)	/* Large Scanner (300) */

/* Initial Positions for Windows ( Relative to upper right corner ) */

#define MAIN_X			(-410)
#define MAIN_Y			(32)
#define STATUSDIALOG_X		(-259)
#define STATUSDIALOG_Y		(32)
#define MANUALCONTROLDIALOG_X	(-900)
#define MANUALCONTROLDIALOG_Y	(150)
#define SNAPSHOTDIALOG_X	(-850)
#define SNAPSHOTDIALOG_Y	(200)
#define STRATEGYDIALOG_X	(-800)
#define STRATEGYDIALOG_Y	(250)
#define OPTIONSDIALOG_X		(-446)
#define OPTIONSDIALOG_Y		(336)
#define PROJECTDIALOG_X		(-600)
#define PROJECTDIALOG_Y		(250)
#define OPTIMIZEDIALOG_X	(-600)
#define OPTIMIZEDIALOG_Y	(350)
#define METHOD_FSB_X		(-650)
#define METHOD_FSB_Y		(450)
#define LOCALDIALOG_X		(-850)
#define LOCALDIALOG_Y		(200)

#define ADX_HELP_X		(-750)
#define ADX_HELP_Y		(300)

#define ERRORDIALOG_X		(-825)
#define ERRORDIALOG_Y		(400)

#define DISKFULL_DIALOG_X	(-480)
#define DISKFULL_DIALOG_Y	(506)

#define MAD_DIALOG_X		(-550)
#define MAD_DIALOG_Y		(200)

#define TIMER_MSEC		(50) /* Timer interval to read status file */

#define N_FIELDS 		(12)	/* Number of fields in Runs window */
#define BAD_FIELD		(-9999)
#define FIELD_INT		(0)
#define FIELD_FLOAT		(1)

/* Maximum number of characters (including newline) per line */
#define MAX_CHAR		(beamline_mode==True?M_MAX_CHAR:90) 
#define M_MAX_CHAR		(118) 

#define FIELD_LENGTH(i) 	(fld[i].col_end-fld[i].col_start+1)
#define SPACE_CHAR 		' '

#define MAX_RUNS		(999)	/* Maximum Run number */
#define M_RUNS			(10)	/* Max Run's used in completion calculation */
#define MAX_FRAMES		(999)	/* Maximum # of frames in each run for completion calculation */

#define DOSE_SCALE		(1.0)	/* Conversion from dose to time */

#define WEAK_BEAM		(10.0)	/* Threshold for a "weak beam" */

#define PHI_AXIS		(0)
#define KAPPA_AXIS		(1)
#define OMEGA_AXIS		(2)

/* Scanner configuration information. Configuration file 
 * is specified in the environment variable MARCONFIGFILE. 
 * This is usually $MARHOME/tables/config
 */

typedef struct {
	float read_fast;
	float read_slow;
	float read_overhead;
	float bin_factor;
	int blocks;
	int pixelsx;
	int pixelsy;
	double multiplier;
	int phisteps;
	int diststeps;
	int phitop;
	int disttop;
	int distmax;
	int distmin;
	int unitsec;
	int unitdose;
	float wavelength;
	int usedistance;
	int uselift;
	int usetwotheta;
	int usephi;
	int usekappa;
	int useomega;
	int usewavelength;
	int flags;
	int nc_pointer;
	int nc_index;
	int nc_x;
	int nc_y;
	int nc_rec;
	int nc_poff;
	int scsi_id;
	int scsi_controller;
	int spiral_check;
	int liftmin;
	int liftmax;
	int lifttop;
	int liftsteps;
	int dezinger;

	/*   0 - do nothing
	 * 180 - values from -180 to +180
	 * 360 - values from 0 to 360
	 */
	int constrain_kappa;
	int constrain_omega;
	int constrain_phi;
	float pixelsize;
	int usezero_angles;
	int usegon_manual;
	int daemon_exit;
	int t2k_detector;
	int pf_mod;
	int adsc_slit;
	int adsc_4slit;
	int usestop_immediate;
	int driveto_centering;
} ScannerConfig;

typedef struct {
	int col_start;
	int col_end;
	int space;
} FieldStruct;

typedef struct {
	int number;  /* Run Number */
	int start;   /* Starting Frame */
	int nframes; /* Number of Frames */
	double distance;
	double offset;
	double phi;
	double kappa;
	double omega;
	char axis[32];
	double delta_phi;
	double exposure;
	char dzngr[8];
	char blstr[256];
} RunStruct;


typedef struct {
	int mode;
	int bin;
	int adc;
	int no_transform;
	int output_raw;
	char directory[256];
	char prefix[64];
	char suffix[32];
	double wavelength;
	double step_size; /* Added by Marian */

	int compression;
	int anomalous;
	int wedge;
	float center_x, center_y;
	int outfile_type;
	int dk_before_run;
	int repeat_dark;
	int darkinterval;

	int mad_mode;
	int mad_nwave;
	int mad_nframes;
	float mad_wavelengths[10];
} CollectStruct;

typedef struct {
	double liftmin;
	double liftmax;
	double distmin;
	double distmax;
} LimitStruct;

typedef struct {
	short run_no;
	short frame_no;
} Run_List;

int wtoi();	/* TextField widget to integer */
double wtof();	/* TextField widget to float */
double atof();
double TextFieldGetFloat();

#ifdef DECLARE_ADX_GLOBALS
#define GLOBAL
#else
#define GLOBAL extern
#endif

GLOBAL ScannerConfig sc_conf;
GLOBAL FieldStruct fld[N_FIELDS+1];	/* +1 for beamline_mode */

GLOBAL char image_directory[256];
GLOBAL char image_prefix[256];
GLOBAL char image_suffix[256];

GLOBAL double current_distance;	 /* Current Distance */
GLOBAL double current_phi;	 /* Current Phi */
GLOBAL double current_kappa;	 /* Current Kappa */
GLOBAL double current_omega;	 /* Current Omega */
GLOBAL double current_offset;	 /* Current Offset */
GLOBAL double wavelength;	 /* Wavelength */
GLOBAL double delta_phi;	 /* Step size */
GLOBAL double attenuator;	 /* Attenuator used, if any */

GLOBAL double beam_intensity;	 /* Beam Intensity */
GLOBAL double beam_intensity_0;	 /* Beam Intensity at start of run */
GLOBAL char image_filename[256]; /* Image File Name */
GLOBAL char image_prev_filename[256]; /* Previous Image File Name */

GLOBAL RunStruct Run[MAX_RUNS+1]; /* Run information for each run */
GLOBAL CollectStruct Collect;	 /* Information for each set of runs */
GLOBAL LimitStruct Limit;	 /* Limits for lift & distance */

GLOBAL Run_List run_list[M_RUNS * MAX_FRAMES];
GLOBAL int total_images;

GLOBAL int configuration;	 /* CONFIG_1x1 or CONFIG_2x2 */
GLOBAL int image_collect_mode;	 /* TIME_MODE or DOSE_MODE */
GLOBAL int image_adc_mode;	 /* 0 or 1 */
GLOBAL int image_bin_mode;	 /* 1 or 2 */
GLOBAL int xform_mode;		 /* 1 or 2 */
GLOBAL int saveraw_mode;	 /* 1 or 2 */
GLOBAL int image_compression;	 /* COMP_NONE, COMP_Z or COMP_PCK */
GLOBAL int outfile_type;	 /* 0 (16), 1 (32), 2 (16 + ovf) */

GLOBAL Display *display;
GLOBAL int scr_width;	 	 /* Width of Screen (in pixels) */
GLOBAL int scr_height;	 	 /* Height of Screen (in pixels) */

GLOBAL char tmpstr[256];	 /* Temporary storage string */
GLOBAL char error_msg[1024];	 /* Error messages */

GLOBAL char marcommandfile[128]; /* MAR Command file */
GLOBAL char marstatusfile[128];  /* MAR Status file */
GLOBAL char marcollectfile[128];  /* MAR Collect file */

GLOBAL FILE *marcommandfp; 	 /* MAR Command file pointer */
GLOBAL FILE *marstatusfp;  	 /* MAR Status file pointer */

GLOBAL int mvc_return;

GLOBAL int collecting;		/* Collectin data or Idle */
GLOBAL int debug;		/* debug flag */
GLOBAL int beamline_mode;	/* -beamline flag (no hardware) */
GLOBAL int software_mode;	/* -s flag (no hardware) */
GLOBAL int define_distance;	/* -define_distance flag (allow define distance) */
GLOBAL int define_offset;	/* -define_offset flag (allow define offset) */

GLOBAL int n_fields;	/* Number of fields in run setup window */

GLOBAL int dezinger;	
GLOBAL int file_overwrite_mode;	 /* 0 - do nothing, 1 - warning, 2 - fatal */
GLOBAL int nocontrol;
GLOBAL int show_xray_label;

/* Set Insertion Point to End of Text Field */
#define XmTextSetInsertionEnd(w) XmTextSetInsertionPosition(w, XmTextGetLastPosition(w))

#define S_WIDTH (200)	/* Increment in width of strategyDialog in beamline_mode */

GLOBAL int calculating_strategy; /* Number of fields in run setup window */

GLOBAL float beam_x, beam_y;
