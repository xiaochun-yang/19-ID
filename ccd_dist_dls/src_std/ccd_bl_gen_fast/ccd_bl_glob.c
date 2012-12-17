#include	"ccd_bl_defs.h"

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

int	fdcom;		/* file (socket) desc for command */
int	fdout;		/* file (socket) desc for output */
FILE	*fpout;		/* file pointer for output */
int	fdstat;		/* file (socket) desc for status */
int	fdxfcm;		/* file (socket) desc for transform */
FILE	*fplog;		/* log file for useful info */
int	fdspiral;	/* file descriptor for spiral data */
FILE	*fpconfig;	/* file pointer for config file */

int	fposcom;	/* current file position for command */
int	fposout;	/* current file position for output */
int	fposstat;	/* current file position for status */

char *trntable = LOGICAL_NAME_TABLE;	/* Essentially for VMS */

mdc_command	mdc_queue[MAXQUEUE];	/* queue of scanner commands */
mdc_command	*mdc_head;		/* points to first queue member */
mdc_command	mdc_current;		/* current command being executed */

int	end_of_command_notify;		/* set to 1 when a command finishes */
int	halt_status_output;		/* 1 to stop outputting status info */

/*
 *	Scanner status information.
 */

float	stat_dist;		/* current distance */
float	stat_phi;		/* current phi */
float	stat_lift;		/* current lift */
float	stat_omega;		/* current omega */
float	stat_kappa;		/* current kappa */
float	stat_start_phi;		/* starting phi value for this scan */
float	stat_start_omega;	/* starting omega value for this scan */
float	stat_start_kappa;	/* starting kappa value for this scan */
float	stat_osc_width;		/* oscillation range */
float	stat_time;		/* exposure time */
float	stat_intensity;		/* intensity reading from mar */
float	stat_wavelength;	/* wavelength */
float	stat_multiplier;	/* scanner specific multiplier factor */
int	stat_axis;		/* current axis */
int	stat_mode;		/* 0 for time mode, 1 for dose mode */
int	stat_max_count;		/* maximum counts in an exposure */
int	stat_n_images;		/* number of images in this collection */
int	stat_n_passes;		/* number of passes per image */
int	stat_n_mdc_updates;	/* number of times mdc has update stat file */
char	stat_dir[80];		/* directory for collecting data */
char	stat_fname[80];		/* current file name */
char	stat_scanner_op[80];	/* scanner operation in progress */
char	stat_scanner_msg[80];	/* any useful scanner message */
char	stat_scanner_control[80];  /* control state */
char	stat_scanner_shutter[80];  /* state of the shutter */
char	stat_mode_msg[80];	/* collection mode: dose or time */
int	stat_adc;
int	stat_bin;


/*
 *	Simulation timing and control.
 */

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
int	dc_abort_ctr;	/* used during the abort procedure */
int	dc_error_rec;	/* used during data collection error recovery */
char	mdc_alert[120];	/* used to signal a hardware alert */

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
			"shutter",
			"scan",
                        "omega_move",
			"omega_move_rel",
                        "omega_set",
                        "kappa_move",
                        "kappa_set",
			"wavelength_move",
			"collect",
			"snap",
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
			NULL
			};

/*
 *	Variables which apply to both simulated and actual
 *	hardware operation.
 */

int	mdc_cmd_active;		/* 1 if we have an active command */
int	mdc_simulation;		/* 1 if simulation, 0 if actual hardware */

int	(*mdc_cmd_start)();		/* function which starts commands */
int	(*mdc_cmd_progress)();		/* function checking progress */
int	(*mdc_read_status_fcn)();	/* function to read status */

int	fdmar;			/* file descriptor for mar */
struct	esd_status_block rs;	/* raw sataus block */
float	dt_stat;		/* number of seconds per status update */

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

int	nc_pointer;	/* neighbor code start pointer */
int	nc_index;	/* neighbor code start index */
int	nc_x;		/* neighbor code start x value */
int	nc_y;		/* neighbor code start y value */
int	nc_rec;		/* neighbor code start record value */
int	nc_poff;	/* neighbor code start pixel offset value */

int	scsi_id;	/* SCSI unit number of the MAR controller */
int	scsi_controller;	/* SCSI controller number (VMS: a = 0, b = 1, etc.) */
int	spiral_check;	/* 1 to check spiral records */
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
int	specific_spiral_check;	/* 1 to check for bad spiral records */
