#include	"ccd_dc_defs.h"

char ifname[256];	/* translated command file name */
char ofname[256];	/* translated output file name */
char sfname[256];	/* translated status file name */
char simdir[256];	/* translated directory name for fake images */
char xfcmdn[256];	/* ip_xform command name */
char lfname[256];	/* for logging important hardware messages */
char confname[256];	/* configuration file name */
char profname[256];	/* profile file name */

char fname_lead[256];	/* leading part of output images */
char fname_dir[256];	/* the directory part */
char scan_dir[256];	/* used to store the spiral files */
char scan_dir_export[256];	/* used to store the spiral files with exported NFS directory name of scan_dir */
char spiralfilename[512];	/* used to contain spiral file name */
char spiralfilename_export[512];	/* exported spiral file name */
char cartimagename[512];	/* what the spiral file will transform to */
char	bl_returned_string[1024];

int	fdcom;		/* file (socket) desc for command */
int	fdout;		/* file (socket) desc for output */
FILE	*fpout;		/* file pointer for output */
int	fdstat;		/* file (socket) desc for status */
int	fdxfcm;		/* file (socket) desc for transform */
FILE	*fplog;		/* log file for useful info */
FILE	*fpconfig;	/* file pointer for config file */
FILE	*fprun;		/* used in run file generation */
int	fddetcmd;	/* detector process command socket */
int	fddetstatus;	/* detector process status socket */
int	fdblcmd;	/* beamline process command socket */
int	fdblstatus;	/* beamline process status socket */

int	fposcom;	/* current file position for command */
int	fposout;	/* current file position for output */
int	fposstat;	/* current file position for status */
int	detector_sn;	/* serial number of the detector, if known */
int	output_raws;	/* 1 to output raws */
int	no_transform;	/* 1 to do no transform on line */
int	constrain_omega;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	constrain_phi;		/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	constrain_kappa;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */

FILE	*fpnull;	/* /dev/null */
int	dc_in_progress;	/* Set when data collection is in progress */

char *trntable = LOGICAL_NAME_TABLE;	/* Essentially for VMS */

mdc_command	mdc_queue[MAXQUEUE];	/* queue of scanner commands */
mdc_command	*mdc_head;		/* points to first queue member */
mdc_command	mdc_current;		/* current command being executed */

/*
 *	Scanner status information.
 */

float	stat_dist;		/* current distance */
float	stat_phi;		/* current phi */
float	stat_lift;		/* current lift */
float	stat_omega;		/* current omega */
float	stat_kappa;		/* current kappa */
float	stat_start_phi;		/* starting phi value for this scan */
float	stat_start_omega;	/* starting omega */
float	stat_start_kappa;	/* strting kappa */
float	stat_osc_width;		/* oscillation range */
float	stat_time;		/* exposure time */
float	stat_intensity;		/* intensity reading from mar */
float	stat_wavelength;	/* wavelength */
float	stat_multiplier;	/* scanner specific multiplier factor */
int	stat_axis;		/* 1 for phi, 0 for omega */
int	stat_mode;		/* 0 for time mode, 1 for dose mode */
int	stat_max_count;		/* maximum counts in an exposure */
int	stat_n_images;		/* number of images in this collection */
int	stat_n_passes;		/* number of passes per image */
int	stat_n_mdc_updates;	/* number of times mdc has update stat file */
int	stat_n_ccd_updates;	/* number of times ccd_dc has updated its OWN status file */
int	stat_image_number;	/* used to keep track of the current image number */
int	stat_adc;		/* adc value (slow=0, fast = 1) */
int	stat_bin = 0;		/* 1 for 1x1, 2 for 2x2 binning */
char	stat_dir[80];		/* directory for collecting data */
char	stat_prefix[890];	/* code name + encoded run number */
char	stat_fname[80];		/* current file name */
char	stat_scanner_op[80];	/* scanner operation in progress */
char	stat_scanner_msg[80];	/* any useful scanner message */
char	stat_scanner_control[80];  /* control state */
char	stat_scanner_shutter[80];  /* state of the shutter */
char	stat_mode_msg[80];	/* collection mode: dose or time */
float	stat_xcen;		/* x beam center in mm for oblique correction */
float	stat_ycen;		/* y beam center in mm for oblique correction */
float	stat_2theta;		/* two theta of the detector */
int	stat_compress;		/* 0 for none, 1 for .Z 2 for .pck */
int	stat_anom;		/* 1 for anomalous, else 0 */
int	stat_wedge;		/* number of frames per anom mini-run */
float	stat_dzratio = 1.0;	/* ratio of 2nd/1st image expos time/dezingering */
float 	stat_step_size;         /* step size for step/dose mode */
float 	stat_dose_step;         /* dose per step for step/dose mode */
float	stat_attenuator;	/* attenuator amount */
float	stat_hslit;		/* horiz slit amount */
float	stat_vslit;		/* vertical slit amount */
float	min_velocity;		/* min data collection velocity */
float	max_velocity;		/* max data collection velocity */
int	allow_stills;
float	stat_experiment_mode;	/* 0 for unknown, 1-8 valid modes */

/*
 *	Simulation timing and control.
 */

int	use_pc_shutter;
int	use_j5_trigger;
int	use_timecheck;
int	sim_cmd_ticks;		/* when goes to zero, the command is done */

int	tick;		/* used for clock counting */
int	units;		/* used for calculating percentage completion */
int	decrement;	/* used for pseudo-timing of things */
int	dcop;		/* software state used for collect & scan */
int	retrycnt;	/* retry count for hardware faults */
int	msign;		/* used in calculations */
float	start_val;	/* used in calculations */
float	delta;		/* ditto */
int	totimg;		/* used for deciding when data collection done */
int	totpass;	/* same, only for multiple passes in a single osc */
int	dc_abort;	/* signals a data collection abort */
int	dc_stop;	/* signals a stop after current exposure */
int	command_rejected;	/* 1 if the command was rejected by ccd_hw_start */
int	dc_abort_ctr;	/* used during the abort procedure */
int	dc_error_rec;	/* used during data collection error recovery */
char	mdc_alert[80];	/* used to signal a hardware alert */

char	*mdc_comlit[] = {
			"eoc",
			"exit",
			"config",
			"startup",
			"erase",
			"initialize",
			"stop",
			"abort",
			"distance_move",
			"phi_move",
			"phi_move_rel",
			"distance_set",
			"phi_set",
			"lift_move",
			"lift_set",
			"wavelength_move",
			"wavelength_set",
			"shutter",
			"scan",
			"omega_move",
			"omega_move_rel",
			"omega_set",
			"kappa_move",
			"kappa_set",
			"collect",
			"snap",
			"gon_manual",
			"home",
			"attenuate",
			"autoalign",
                        "set_master",
                        "get_clients",
                        "experiment_mode_move",
                        "hslit_move",
                        "vslit_move",
			"xl_hs_move",
			"xl_vs_move",
			"xl_up_hhs_move",
			"xl_up_vhs_move",
			"xl_dn_hhs_move",
			"xl_dn_vhs_move",
			"xl_guard_hs_move",
			"xl_guard_vs_move",
			"holding",
			"queue_list",
			"queue_flush",
			"distance",
			"phi_start",
			"osc_width",
			"n_images",
			"de_zinger",
			"time",
			"image_number",
			"directory",
			"image_prefix",
			"image_suffix",
			"mode",
			"wavelength",
			"remark",
			"lift",
			"adc",
			"bin",
			"center",
			"kappa_start",
			"omega_start",
			"axis",
			"newdark",
			"anomalous",
			"wedge",
			"compress",
			"blcmd",
			"dzratio",
			"darkinterval",
			"repeat_dark",
			"dk_before_run",
			"outfile_type",
			"no_transform",
			"output_raw",
			"step_size",
			"dose_per_step",
			"mad",
			"mad_wave",
			"restart_run",
			"restart_image",
			"atten_run",
			"autoal_run",
			"hslit_run",
			"vslit_run",
			NULL
			};

/*
 *	Variables which apply to both simulated and actual
 *	hardware operation.
 */

int	mdc_cmd_active;			/* 1 if we have an active command */
int	mdc_simulation;			/* 1 if simulation, 0 if actual hardware */
int	raw_ccd_image = 0;		/* 1 if doing calibration, else 0 */
int	repeat_dark_current = 0;	/* 1 if doing repeated dark currents, else 0 */
int	dark_current_interval = 0;	/* interval in sec for recollect dark currents */
int	dark_current_time = 0;		/* time function value for last dark current */
int	pixel_size;
int	dk_before_run;			/* 1 for dark current repeat before a run */
int	strip_ave;			/* 1 to use strip averages for dark pedistal renorm in xform */

int	n_ctrl;				/* number of controllers */
int	n_strip_ave;			/* number of returned strip_ave values */
float	strip_ave_vals[4];		/* their values */

int	(*mdc_cmd_start)();		/* function which starts commands */
int	(*mdc_cmd_progress)();		/* function checking progress */

int	fdmar;			/* file descriptor for mar */
struct	esd_status_block rs;	/* raw sataus block */
float	dt_stat;		/* number of seconds per status update */
float	kappa_const;		/* kappa goniostat constant, usually about 50 degrees */

/*
 *	Hardware scanner status.
 */

int	active[MAX_CMD];
int	started[MAX_CMD];
int	queued[MAX_CMD];
int	all_done[MAX_CMD];
int	aborted[MAX_CMD];
int	c_error[MAX_CMD];
short	last_valid_data;
short	last_command;
int	mains_active;
int	hv_on;
int	open_xray_shutter;
int	xray_shutter_open;
int	lock_ip;
int	ip_locked;
int	open_laser_shutter;
int	laser_shutter_open;
int	erase_lamp_on_out;
int	erase_lamp_on_ok;
int	ion_chamber;
int	ion_chamber_select_enab;
int	distance_steps;
int	phi_steps;
int	lift_steps;
int	omega_steps;
int	waiting_for_command[MAX_CMD];
int	readpointer;
int	writepointer;

/*
 *	Some timing variables useful to have.
 */

float	erase_time;	/* number of seconds it takes to erase plate */
float	scan_time;	/* number of seconds it takes to scan plate */
float	dc_erase_time;	/* slightly longer than normal erase */
int	phi_steps_deg;	/* number of steps per degree in phi */
int	dist_steps_mm;	/* number of steps per mm for the distance */
int	lift_steps_mm;	/* number of steps per mm for the lift mechanism */
int	phi_top_speed;	/* Top speed in steps/sec for phi motor */
int	phi_speed_used;	/* The actual speed for a particular operation */
int	dist_top_speed;	/* Top speed for distance in steps/mm */
int	dist_max_ref_point;	/* Number of steps for ending limit switch */
int	dist_min_ref_point;	/* Number of steps for dist at near limit switch */
int	lift_top_speed; /* Top speed for lift mechanism in steps/sec */
int	lift_max_point;		/* Number of steps for lift at the UPPER limit switch */
int	lift_min_point;		/* Number of steps for lift at the LOWER limit switch */
int	is_lift;		/* 1 if there is a lift mechanism on this machine */
int	units_per_second;	/* number of units per second/data coll */
int	units_per_dose;		/* same thing, only for dose */
int	magic_flags;		/* may need for a special purpose */
int	is_distance;		/* 1 if there is operable distance */
int	is_phi;			/* 1 if there is operable phi */
int	radius_mode;		/* 0 (default) 180 or 300 */
float	read_fast;		/* read time/FAST ADC */
float	read_slow;		/* read time/SLOW ADC */
float	read_overhead;		/* general overhead per picture */
float	bin_factor;		/* factor to apply for time if bin 2x2 */
int	is_kappa;		/* 1 if we have a kappa axis */
int	is_omega;		/* 1 if we have an omega axis */
int	def_dezinger;		/* 1 if default is to dezinger images */
int	is_2theta;		/* 1 if we have a two theta.  This is exclusive of is_lift */
int     is_wavelength;          /* 1 if we have wavelength control */
float   approach_start;         /* non-zero to move this far from start position, then to start position */
int     chip_size_x;            /* size of the basic chip element in the detector, in pixels */
int     chip_size_y;            /* size of the basic chip element in the detector, in pixels */
float   bchk_time;                      /* beamstop check time */
float   bchk_deltaphi;                  /* beamstop check deltaphi */
int     perform_beamstop_check;         /* 1 to perform beamstop check, else 0 */
int     checking_direct_beam;           /* 1 while this is in progress */
char    bchk_semiphore_file[256];       /* beamstop check semiphore file name */
int	madrun_naming;
int	retryshort;			/* 1 to retry short exposures (mar base) */
int	ccd_modular;			/* 1 if using modular (multiple) framegrabbers, else 0 */
int	pf_mod;			/* 1 if using modular (multiple) framegrabbers, else 0 */
int	usestop_immediate;
int     pitch_tune_delta;
time_t  pitch_tune_last = 0;
int	bm8_mod;
char	bl_reply[512];
int	bl_is_server;
int	beam_sense;
int	t2k_detector;
int	adsc_slit;
int	adsc_4slit;

int	nc_pointer;	/* neighbor code start pointer */
int	nc_index;	/* neighbor code start index */
int	nc_x;		/* neighbor code start x value */
int	nc_y;		/* neighbor code start y value */
int	nc_rec;		/* neighbor code start record value */
int	nc_poff;	/* neighbor code start pixel offset value */

int	scsi_id;	/* SCSI unit number of the MAR controller */
int	scsi_controller;	/* SCSI controller number (VMS: a = 0, b = 1, etc.) */
int	spiral_check;	/* 1 to check spiral records */

float	beam_xcen;		/* x beam center in mm for oblique correction */
float	beam_ycen;		/* y beam center in mm for oblique correction */
int	outfile_type;		/* 0 or ushort, 1 for int */

/*
 *	These are lower case assigned versions of
 *	the default #defines in the mdcdefs.h file.
 *
 *	They are given the initial values by the .h file
 *	but may be overridden either by the program
 * 	or by the user's configuration file.
 */


float	specific_erase_time;	/* how many sec. a simple erase command takes */
float	specific_scan_time;	/* how many seconds the scan part of the GOIPS takes */
float	specific_dc_erase_time;	/* how many seconds the erase and lock parts of GOIPS takes */
int	specific_total_valid_blocks;	/* how many blocks makes a spiral scan */
int	specific_total_pixels_x;	/* number of pixels in x */
int	specific_total_pixels_y;	/* number of pixels in y */
float	specific_multiplier;	/* This is scanner specific and should ALWAYS user specified */
int	specific_phi_steps_deg;	/* number of steps per degree for phi motor */
int	specific_dist_steps_mm;	/* number of steps per mm for the distance */
int	specific_lift_steps_mm;	/* number of steps per mm for tower lift mechanism */
int	specific_lift_top_speed; /* top speed for the lift motor (masquerading as "omega") */
int	specific_lift_max_point; /* value of lift in STEPS at the upper limit */
int	specific_lift_min_point; /* value of lift in STEPS at the lower limit */
int	specific_is_lift;	/* is there a lift mechanism on this machine? */
int	specific_phi_top_speed;	/* top speed of phi motor in steps per second */
int	specific_dist_top_speed; /* top speed of distance motor in steps per second */
int	specific_dist_max_point; /* value of distance in STEPS at the FAR distance limit */
int	specific_dist_min_point; /* value of distance in STEPS at the NEAR distance limit */
int	specific_units_per_sec;	/* units for timing exposures */
int	specific_units_per_dose; /* units for measuring exposures by dose */
float	specific_wavelength; 	/* wavelength default */
int	specific_is_distance;	/* is there a distance on this machine? */
int	specific_is_phi;	/* is there a phi motor on this machine? */
int	specific_flags;		/* sometime we may need override values */
int	specific_nc_pointer;	/* neighbor code start pointer */
int	specific_nc_index;	/* neighbor code start index */
int	specific_nc_x;		/* neighbor code start x value */
int	specific_nc_y;		/* neighbor code start y value */
int	specific_nc_rec;	/* neighbor code start record value */
int	specific_nc_poff;	/* neighbor code start pixel offset value */
int	specific_scsi_id;	/* SCSI unit number of the controller */
int	specific_scsi_controller;	/* controller number */
int	specific_spiral_check;		/* 1 to check for bad spiral records */
float	specific_read_fast;		/* read time/FAST ADC */
float	specific_read_slow;		/* read time/SLOW ADC */
float	specific_read_overhead;		/* general overhead per picture */
float	specific_bin_factor;		/* factor to apply for time if bin 2x2 */
int	specific_is_kappa;		/* 1 if we have a kappa axis */
int	specific_is_omega;		/* 1 if we have an omega axis */
int	specific_def_dezinger;		/* 1 if default is to dezinger images */
int	specific_is_2theta;		/* 1 if we have 2theta */
int     specific_is_wavelength;         /* 1 if we have 2theta */
float   specific_approach_start;        /* non-zero to move this far from start position, then to start position */
int     specific_chip_size_x;           /* size of the basic chip element in the detector, in pixels */
int     specific_chip_size_y;           /* size of the basic chip element in the detector, in pixels */
int	specific_pcshutter;		/* 1 if default is to dezinger images */
int	specific_dark_interval;		/* time in sec in between dark current recollects */
float	specific_pixel_size;		/* pixel size */
int	specific_compress;		/* 0 for none, 1 for .Z 2 for .pck */
int	specific_dk_before_run;		/* 1 for dark current repeat before a run */
int	specific_repeat_dark;		/* 1 for repeat dark current */
int	specific_outfile_type;		/* 0 or ushort, 1 for int */
int	specific_detector_sn;		/* detector serial number, if specified */
int	specific_no_transform;		/* 1 for no on-line transform */
int	specific_output_raws;		/* 1 for output raws */
int	specific_j5_trigger;		/* 1 to use j5 trigger for ext_sync */
int	specific_timecheck;		/* 1 to use j5 trigger for ext_sync */
int	specific_constrain_omega;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	specific_constrain_phi;		/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	specific_constrain_kappa;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	specific_strip_ave;		/* 1 to use strip averages for dk pedistal renorm */
float   specific_bchk_time;             /* time for beamstop check */
float   specific_bchk_deltaphi;         /* delta phi for beamstop check */
float   specific_kappa_const;           /* kappa constant */
int     specific_madrun_naming;         /* 1 for Henry's convention, 0 for cn's */
int	specific_retryshort;		/* 1 to retry short exposures (mar bases) */
int	specific_ccd_modular;		/* 1 if we are using modular (multiple) framegrabbers */
int	specific_pf_mod;		/* 1 if we are running under PF mods */
float	specific_min_velocity;
float	specific_max_velocity;
int	specific_allow_stills;
int	specific_pitch_tune_delta;
int	specific_bm8_mod;
int	specific_usestop_immediate;
int	specific_bl_is_server;
int	specific_beam_sense;
int	specific_t2k_detector;
int	specific_adsc_slit;
int	specific_adsc_4slit;
