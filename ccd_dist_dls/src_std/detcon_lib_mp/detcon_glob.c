#include	"detcon_defs.h"

char 	dtc_lfname[256];	/* for logging important hardware messages */
char 	dtc_confname[256];	/* configuration file name */

int	dtc_fdcom;		/* file (socket) desc for command */
int	dtc_fdout;		/* file (socket) desc for output */
FILE	*dtc_fpout;		/* file pointer for output */
int	dtc_fdstat;		/* file (socket) desc for status */
int	dtc_fdxfcm;		/* file (socket) desc for transform */
FILE	*dtc_fplog;		/* log file for useful info */
FILE	*dtc_fpconfig;	/* file pointer for config file */
int	dtc_fddetcmd;	/* detector process command socket */
int	dtc_fddetstatus;	/* detector process status socket */
int	dtc_fdblcmd;	/* beamline process command socket */
int	dtc_fdblstatus;	/* beamline process status socket */
int     dtc_xfdatafd;           /* 1 when we've seen a connected data socket from detector program */

int	dtc_detector_sn;	/* serial number of the detector, if known */
int	dtc_output_raws;	/* 1 to output raws */
int	dtc_no_transform;	/* 1 to do no transform on line */
int	dtc_constrain_omega;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	dtc_constrain_phi;		/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	dtc_constrain_kappa;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */

FILE	*dtc_fpnull;	/* /dev/null */
int	dtc_dc_in_progress;	/* Set when data collection is in progress */
int	dtc_last = CCD_LAST_IDLE;

char 	*dtc_trntable = LOGICAL_NAME_TABLE;	/* Essentially for VMS */

char	dtc_default_suffix[20] = ".img";
int	dtc_default_imsize = 4096 * 4096 * 2;
int	dtc_state = DTC_STATE_ERROR;
int	dtc_expos_msec_ticks;
int	dtc_initialized = 0;
char	dtc_status_string[512];
char	dtc_lasterror_string[512];

/*
 *	Scanner status information.
 */

float	dtc_stat_dist;		/* current distance */
float	dtc_stat_phi;		/* current phi */
float	dtc_stat_lift;		/* current lift */
float	dtc_stat_omega;		/* current omega */
float	dtc_stat_kappa;		/* current kappa */
float	dtc_stat_start_phi;		/* starting phi value for this scan */
float	dtc_stat_start_omega;	/* starting omega */
float	dtc_stat_start_kappa;	/* strting kappa */
float	dtc_stat_osc_width;		/* oscillation range */
float	dtc_stat_time;		/* exposure time */
float	dtc_stat_dose;		/* dose units, if applicable */
float	dtc_stat_intensity;		/* intensity reading from mar */
float	dtc_stat_wavelength;	/* wavelength */
float	dtc_stat_multiplier;	/* scanner specific multiplier factor */
int	dtc_stat_axis;		/* 1 for phi, 0 for omega */
int	dtc_stat_mode;		/* 0 for time mode, 1 for dose mode */
int	dtc_stat_max_count;		/* maximum counts in an exposure */
int	dtc_stat_n_images;		/* number of images in this collection */
int	dtc_stat_n_passes;		/* number of passes per image */
int	dtc_stat_n_mdc_updates;	/* number of times mdc has update stat file */
int	dtc_stat_n_ccd_updates;	/* number of times ccd_dc has updated its OWN status file */
int	dtc_stat_image_number;	/* used to keep track of the current image number */
int	dtc_stat_adc = 0;		/* adc value (slow=0, fast = 1) */
int	dtc_stat_bin = 1;		/* 1 for 1x1, 2 for 2x2 binning */
char	dtc_stat_dir[80];		/* directory for collecting data */
char	dtc_stat_prefix[890];	/* code name + encoded run number */
char	dtc_stat_fname[80];		/* current file name */
char	dtc_stat_scanner_op[80];	/* scanner operation in progress */
char	dtc_stat_scanner_msg[80];	/* any useful scanner message */
char	dtc_stat_scanner_control[80];  /* control state */
char	dtc_stat_scanner_shutter[80];  /* state of the shutter */
char	dtc_stat_mode_msg[80];	/* collection mode: dose or time */
float	dtc_stat_xcen;		/* x beam center in mm for oblique correction */
float	dtc_stat_ycen;		/* y beam center in mm for oblique correction */
float	dtc_stat_2theta;		/* two theta of the detector */
int	dtc_stat_compress;		/* 0 for none, 1 for .Z 2 for .pck */
int	dtc_stat_anom;		/* 1 for anomalous, else 0 */
int	dtc_stat_wedge;		/* number of frames per anom mini-run */
float	dtc_stat_dzratio = 1.0;	/* ratio of 2nd/1st image expos time/dezingering */
float 	dtc_stat_step_size;         /* step size for step/dose mode */
float 	dtc_stat_dose_step;         /* dose per step for step/dose mode */
int	dtc_chip_size_x;		/* chip size in x = number of columns */
int	dtc_chip_size_y;		/* chip size in y = number of rows */
int	dtc_t2k_detector;		/* 1 if Q210/315 detector */
int	dtc_modular;		/* 1 if using modular framegrabbers */


/*
 *	Simulation timing and control.
 */

int	dtc_use_pc_shutter;
int	dtc_use_j5_trigger;
int	dtc_use_timecheck;

char	dtc_mdc_alert[80];	/* used to signal a hardware alert */

/*
 *	Variables which apply to both simulated and actual
 *	hardware operation.
 */

int	dtc_dc_stop;
int	dtc_raw_ccd_image = 0;		/* 1 if doing calibration, else 0 */
int	dtc_repeat_dark_current = 0;	/* 1 if doing repeated dark currents, else 0 */
int	dtc_dark_current_interval = 0;	/* interval in sec for recollect dark currents */
int	dtc_dark_current_time = 0;		/* time function value for last dark current */
int	dtc_dark_mode;
int	dtc_force_dark;
int	dtc_pixel_size;
int	dtc_dk_before_run;			/* 1 for dark current repeat before a run */
int	dtc_strip_ave;			/* 1 to use strip averages for dark pedistal renorm in xform */
int	dtc_image_kind;
int	dtc_lastimage;
char	dtc_filename[512];
char	dtc_comment[512];
char	dtc_det_reply[512];
char	dtc_xform_reply[512];

int	dtc_n_ctrl;				/* number of controllers */
int	dtc_n_strip_ave;			/* number of returned strip_ave values */
float	dtc_strip_ave_vals[4];		/* their values */

int	(*dtc_mdc_cmd_start)();		/* function which starts commands */
int	(*dtc_mdc_cmd_progress)();		/* function checking progress */

float	dtc_dt_stat;		/* number of seconds per status update */

/*
 *	Some timing variables useful to have.
 */

float	dtc_erase_time;	/* number of seconds it takes to erase plate */
float	dtc_scan_time;	/* number of seconds it takes to scan plate */
float	dtc_dc_erase_time;	/* slightly longer than normal erase */
int	dtc_phi_steps_deg;	/* number of steps per degree in phi */
int	dtc_dist_steps_mm;	/* number of steps per mm for the distance */
int	dtc_lift_steps_mm;	/* number of steps per mm for the lift mechanism */
int	dtc_phi_top_speed;	/* Top speed in steps/sec for phi motor */
int	dtc_phi_speed_used;	/* The actual speed for a particular operation */
int	dtc_dist_top_speed;	/* Top speed for distance in steps/mm */
int	dtc_dist_max_ref_point;	/* Number of steps for ending limit switch */
int	dtc_dist_min_ref_point;	/* Number of steps for dist at near limit switch */
int	dtc_lift_top_speed; /* Top speed for lift mechanism in steps/sec */
int	dtc_lift_max_point;		/* Number of steps for lift at the UPPER limit switch */
int	dtc_lift_min_point;		/* Number of steps for lift at the LOWER limit switch */
int	dtc_is_lift;		/* 1 if there is a lift mechanism on this machine */
int	dtc_units_per_second;	/* number of units per second/data coll */
int	dtc_units_per_dose;		/* same thing, only for dose */
int	dtc_magic_flags;		/* may need for a special purpose */
int	dtc_is_distance;		/* 1 if there is operable distance */
int	dtc_is_phi;			/* 1 if there is operable phi */
int	dtc_radius_mode;		/* 0 (default) 180 or 300 */
float	dtc_read_fast;		/* read time/FAST ADC */
float	dtc_read_slow;		/* read time/SLOW ADC */
float	dtc_read_overhead;		/* general overhead per picture */
float	dtc_bin_factor;		/* factor to apply for time if bin 2x2 */
float	dtc_time_nobin_slow;	/* readout time for slow no binned */
float	dtc_time_nobin_fast;	/* readout time for fast no binned */
float	dtc_time_bin_slow;	/* readout time for slow binned */
float	dtc_time_bin_fast;	/* readout time for fast binned */
int	dtc_is_kappa;		/* 1 if we have a kappa axis */
int	dtc_is_omega;		/* 1 if we have an omega axis */
int	dtc_def_dezinger;		/* 1 if default is to dezinger images */
int	dtc_is_2theta;		/* 1 if we have a two theta.  This is exclusive of is_lift */

int	dtc_nc_pointer;	/* neighbor code start pointer */
int	dtc_nc_index;	/* neighbor code start index */
int	dtc_nc_x;		/* neighbor code start x value */
int	dtc_nc_y;		/* neighbor code start y value */
int	dtc_nc_rec;		/* neighbor code start record value */
int	dtc_nc_poff;	/* neighbor code start pixel offset value */

int	dtc_scsi_id;	/* SCSI unit number of the MAR controller */
int	dtc_scsi_controller;	/* SCSI controller number (VMS: a = 0, b = 1, etc.) */
int	dtc_spiral_check;	/* 1 to check spiral records */

int	dtc_outfile_type;		/* 0 or ushort, 1 for int */

/*
 *	These are lower case assigned versions of
 *	the default #defines in the mdcdefs.h file.
 *
 *	They are given the initial values by the .h file
 *	but may be overridden either by the program
 * 	or by the user's configuration file.
 */


float	dtc_specific_erase_time;	/* how many sec. a simple erase command takes */
float	dtc_specific_scan_time;	/* how many seconds the scan part of the GOIPS takes */
float	dtc_specific_dc_erase_time;	/* how many seconds the erase and lock parts of GOIPS takes */
int	dtc_specific_total_valid_blocks;	/* how many blocks makes a spiral scan */
int	dtc_specific_total_pixels_x;	/* number of pixels in x */
int	dtc_specific_total_pixels_y;	/* number of pixels in y */
float	dtc_specific_multiplier;	/* This is scanner specific and should ALWAYS user specified */
int	dtc_specific_phi_steps_deg;	/* number of steps per degree for phi motor */
int	dtc_specific_dist_steps_mm;	/* number of steps per mm for the distance */
int	dtc_specific_lift_steps_mm;	/* number of steps per mm for tower lift mechanism */
int	dtc_specific_lift_top_speed; /* top speed for the lift motor (masquerading as "omega") */
int	dtc_specific_lift_max_point; /* value of lift in STEPS at the upper limit */
int	dtc_specific_lift_min_point; /* value of lift in STEPS at the lower limit */
int	dtc_specific_is_lift;	/* is there a lift mechanism on this machine? */
int	dtc_specific_phi_top_speed;	/* top speed of phi motor in steps per second */
int	dtc_specific_dist_top_speed; /* top speed of distance motor in steps per second */
int	dtc_specific_dist_max_point; /* value of distance in STEPS at the FAR distance limit */
int	dtc_specific_dist_min_point; /* value of distance in STEPS at the NEAR distance limit */
int	dtc_specific_units_per_sec;	/* units for timing exposures */
int	dtc_specific_units_per_dose; /* units for measuring exposures by dose */
float	dtc_specific_wavelength; 	/* wavelength default */
int	dtc_specific_is_distance;	/* is there a distance on this machine? */
int	dtc_specific_is_phi;	/* is there a phi motor on this machine? */
int	dtc_specific_flags;		/* sometime we may need override values */
int	dtc_specific_nc_pointer;	/* neighbor code start pointer */
int	dtc_specific_nc_index;	/* neighbor code start index */
int	dtc_specific_nc_x;		/* neighbor code start x value */
int	dtc_specific_nc_y;		/* neighbor code start y value */
int	dtc_specific_nc_rec;	/* neighbor code start record value */
int	dtc_specific_nc_poff;	/* neighbor code start pixel offset value */
int	dtc_specific_scsi_id;	/* SCSI unit number of the controller */
int	dtc_specific_scsi_controller;	/* controller number */
int	dtc_specific_spiral_check;		/* 1 to check for bad spiral records */
float	dtc_specific_read_fast;		/* read time/FAST ADC */
float	dtc_specific_read_slow;		/* read time/SLOW ADC */
float	dtc_specific_read_overhead;		/* general overhead per picture */
float	dtc_specific_bin_factor;		/* factor to apply for time if bin 2x2 */
int	dtc_specific_is_kappa;		/* 1 if we have a kappa axis */
int	dtc_specific_is_omega;		/* 1 if we have an omega axis */
int	dtc_specific_def_dezinger;		/* 1 if default is to dezinger images */
int	dtc_specific_is_2theta;		/* 1 if we have 2theta */
int	dtc_specific_pcshutter;		/* 1 if default is to dezinger images */
int	dtc_specific_dark_interval;		/* time in sec in between dark current recollects */
float	dtc_specific_pixel_size;		/* pixel size */
int	dtc_specific_compress;		/* 0 for none, 1 for .Z 2 for .pck */
int	dtc_specific_dk_before_run;		/* 1 for dark current repeat before a run */
int	dtc_specific_repeat_dark;		/* 1 for repeat dark current */
int	dtc_specific_outfile_type;		/* 0 or ushort, 1 for int */
int	dtc_specific_detector_sn;		/* detector serial number, if specified */
int	dtc_specific_no_transform;		/* 1 for no on-line transform */
int	dtc_specific_output_raws;		/* 1 for output raws */
int	dtc_specific_j5_trigger;		/* 1 to use j5 trigger for ext_sync */
int	dtc_specific_timecheck;		/* 1 to use j5 trigger for ext_sync */
int	dtc_specific_constrain_omega;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	dtc_specific_constrain_phi;		/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	dtc_specific_constrain_kappa;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
int	dtc_specific_strip_ave;		/* 1 to use strip averages for dk pedistal renorm */
int	dtc_specific_chip_size_x;		/* chip size in x = number of columns */
int	dtc_specific_chip_size_y;		/* chip size in y = number of rows */
int	dtc_specific_t2k_detector;
int	dtc_specific_modular;
