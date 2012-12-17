#include	"ccd_dc_defs.h"

extern	int	errno;		/* system */

extern char	ifname[256];
extern char	ofname[256];
extern char	sfname[256];
extern char	simdir[256];
extern char	xfcmdn[256];
extern char	lfname[256];
extern char	confname[256];
extern char	profname[256];

extern char	fname_lead[256];
extern char	fname_dir[256];
extern char	scan_dir[256];
extern char	scan_dir_export[256];
extern char	spiralfilename[512];
extern char	spiralfilename_export[512];
extern char	cartimagename[512];

extern int	fdcom;
extern int	fdout;
extern FILE	*fpout;
extern int	fdstat;
extern int	fdxfcm;
extern FILE	*fplog;
extern int	fdspiral;
extern FILE	*fpconfig;
extern FILE	*fprun;
extern int	fddetcmd;
extern int	fddetstatus;
extern int	fdblcmd;
extern int	fdblstatus;

extern int	fposcom;
extern int	fposout;
extern int	fposstat;
extern int	detector_sn;
extern int	no_transform;
extern int	output_raws;
extern int	constrain_omega;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern int	constrain_phi;		/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern int	constrain_kappa;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */

extern char	*trntable;

extern FILE	*fpnull;
extern int	dc_in_progress;

extern mdc_command	mdc_queue[MAXQUEUE];
extern mdc_command	*mdc_head;
extern mdc_command	mdc_current;

extern	float	stat_dist;
extern	float	stat_lift;
extern	float	stat_phi;
extern	float	stat_omega;
extern	float	stat_kappa;
extern	float	stat_start_phi;
extern	float	stat_start_omega;
extern	float	stat_start_kappa;
extern	float	stat_osc_width;
extern	float	stat_time;
extern	float	stat_intensity;
extern	float	stat_wavelength;
extern	float	stat_multiplier;
extern	int	stat_axis;
extern	int	stat_mode;
extern	int	stat_max_count;
extern	int	stat_n_images;
extern	int	stat_n_passes;
extern	int	stat_n_mdc_updates;
extern	int	stat_n_ccd_updates;
extern	int	stat_image_number;
extern	int	stat_adc;
extern	int	stat_bin;
extern	char	stat_dir[80];
extern	char	stat_prefix[80];
extern	char	stat_fname[80];
extern	char	stat_scanner_op[80];
extern	char	stat_scanner_msg[80];
extern	char	stat_scanner_control[80];
extern	char	stat_scanner_shutter[80];
extern	char	stat_mode_msg[80];
extern	float	stat_xcen;
extern	float	stat_ycen;
extern	float	stat_2theta;
extern	int	stat_compress;
extern	int	stat_anom;
extern	int	stat_wedge;
extern	float	stat_dzratio;
extern  float   stat_step_size;
extern  float   stat_dose_step;
extern  float   stat_attenuator;
extern  float   stat_hslit;
extern  float   stat_vslit;
extern	float   min_velocity;           /* min data collection velocity */
extern	float   max_velocity;           /* max data collection velocity */
extern	int     allow_stills;
extern  float   stat_experiment_mode;


extern	int	use_pc_shutter;
extern	int	use_j5_trigger;
extern	int	use_timecheck;
extern	int	sim_cmd_ticks;

extern	int	tick;
extern	int	units;
extern	int	decrement;
extern	int	dcop;
extern	int	retrycnt;
extern	int	msign;
extern	float	start_val;
extern	float	delta;	
extern	int	totimg;
extern	int	totpass;
extern	int	dc_abort;
extern	int	dc_stop;
extern	int	command_rejected;
extern	int	dc_abort_ctr;
extern	int	dc_error_rec;
extern	char	mdc_alert[80];

extern char	*mdc_comlit[];

extern	int	mdc_cmd_active;
extern	int	mdc_simulation;
extern	int	raw_ccd_image;
extern	int	repeat_dark_current;
extern	int     dark_current_interval;      /* interval in sec for recollect dark currents */
extern	int     dark_current_time;          /* time function value for last dark current */
extern	float	pixel_size;
extern	int	dk_before_run;
extern	int	strip_ave;

extern	void	(*mdc_cmd_start)();
extern	int	(*mdc_cmd_progress)();

extern	int	fdmar;
extern 	struct	esd_status_block rs;
extern	float	dt_stat;
extern	float	kappa_const;

extern	int	active[MAX_CMD];
extern	int	started[MAX_CMD];
extern	int	queued[MAX_CMD];
extern	int	all_done[MAX_CMD];
extern	int	aborted[MAX_CMD];
extern	int	c_error[MAX_CMD];
extern	short	last_valid_data;
extern	short	last_command;
extern	int	mains_active;
extern	int	hv_on;
extern	int	open_xray_shutter;
extern	int	xray_shutter_open;
extern	int	lock_ip;
extern	int	ip_locked;
extern	int	open_laser_shutter;
extern	int	laser_shutter_open;
extern	int	erase_lamp_on_out;
extern	int	erase_lamp_on_ok;
extern	int	ion_chamber;
extern	int	ion_chamber_select_enab;
extern	int	distance_steps;
extern	int	phi_steps;
extern	int	omega_steps;
extern	int	waiting_for_command[MAX_CMD];
extern	int	readpointer;
extern	int	writepointer;

extern	float	erase_time;
extern	float	scan_time;
extern	float	dc_erase_time;
extern	int	phi_steps_deg;
extern	int	dist_steps_mm;
extern	int	phi_top_speed;
extern	int	phi_speed_used;
extern	int	dist_top_speed;
extern	int	dist_max_ref_point;
extern	int	dist_min_ref_point;
extern	int	units_per_second;
extern	int	units_per_dose;
extern	int	magic_flags;
extern	int	is_distance;
extern	int	is_phi;
extern	int	radius_mode;
extern	float	read_fast;
extern	float	read_slow;
extern	float	read_overhead;
extern	float	bin_factor;
extern	int	is_kappa;
extern	int	is_omega;
extern	int	def_dezinger;
extern	int	is_2theta;
extern	int     is_wavelength;          /* 1 if we have wavelength control */
extern	float   approach_start;         /* non-zero to move this far from start position, then to start position */
extern	int     chip_size_x;              /* size of the basic chip element in the detector, in pixels */
extern	int     chip_size_y;              /* size of the basic chip element in the detector, in pixels */
extern	float   bchk_time;                      /* beamstop check time */
extern	float   bchk_deltaphi;                  /* beamstop check deltaphi */
extern	int     perform_beamstop_check;         /* 1 to perform beamstop check, else 0 */
extern	int     checking_direct_beam;           /* 1 while this is in progress */
extern	char    bchk_semiphore_file[256];       /* beamstop check semiphore file name */
extern	int	madrun_naming;
extern	int	retryshort;
extern	int     ccd_modular;                    /* 1 if using modular (multiple) framegrabbers, else 0 */
extern	int     pf_mod;                    /* 1 if using modular (multiple) framegrabbers, else 0 */
extern	int     usestop_immediate;
extern	int     pitch_tune_delta;
extern	time_t  pitch_tune_last;
extern	int     bm8_mod;
extern	int	nc_pointer;
extern	int	nc_index;
extern	int	nc_x;	
extern	int	nc_y;
extern	int	nc_rec;
extern	int	nc_poff;
extern	int	scsi_id;
extern	int	scsi_controller;
extern	int	spiral_check;
extern	float	beam_xcen;
extern	float	beam_ycen;
extern	int	outfile_type;
extern	int	n_ctrl;
extern	int	n_strip_ave;
extern	float	strip_ave_vals[4];

extern	float	specific_erase_time;
extern	float	specific_scan_time;
extern	float	specific_dc_erase_time;
extern	int	specific_total_valid_blocks;
extern	int	specific_total_pixels_x;
extern	int	specific_total_pixels_y;
extern	float	specific_multiplier;
extern	int	specific_phi_steps_deg;	
extern	int	specific_dist_steps_mm;
extern	int	specific_phi_top_speed;
extern	int	specific_dist_top_speed;
extern	int	specific_dist_max_point;
extern	int	specific_dist_min_point;
extern	int	specific_units_per_sec;
extern	int	specific_units_per_dose;
extern	float	specific_wavelength;
extern	int	specific_is_distance;
extern	int	specific_is_phi;
extern	int	specific_flags;
extern	int	specific_nc_pointer;
extern	int	specific_nc_index;
extern	int	specific_nc_x;	
extern	int	specific_nc_y;
extern	int	specific_nc_rec;
extern	int	specific_nc_poff;
extern	int	specific_scsi_id;
extern	int	specific_scsi_controller;
extern	int	specific_spiral_check;

extern	int	lift_steps;
extern	int	lift_steps_mm;
extern	int	lift_top_speed;
extern	int	lift_max_point;
extern	int	lift_min_point;
extern	int	is_lift;
extern	int	specific_lift_steps_mm;
extern	int	specific_lift_top_speed;
extern	int	specific_lift_max_point;
extern	int	specific_lift_min_point;
extern	int	specific_is_lift;
extern	float	specific_read_fast;
extern	float	specific_read_slow;
extern	float	specific_read_overhead;
extern	float	specific_bin_factor;
extern	int	specific_is_kappa;
extern	int	specific_is_omega;
extern	int	specific_def_dezinger;
extern	int	specific_is_2theta;
extern	int     specific_is_wavelength;         /* 1 if we have 2theta */
extern	float   specific_approach_start;        /* non-zero to move this far from start position, then to start position */
extern	int     specific_chip_size_x;           /* size of the basic chip element in the detector, in pixels */
extern	int     specific_chip_size_y;           /* size of the basic chip element in the detector, in pixels */
extern	int	specific_pcshutter;
extern	int     specific_dark_interval;
extern	float	specific_pixel_size;
extern	int	specific_dk_before_run;
extern	int	specific_repeat_dark;
extern	int	specific_outfile_type;
extern	int	specific_detector_sn;
extern	int	specific_no_transform;
extern	int	specific_output_raws;
extern	int	specific_j5_trigger;
extern	int	specific_timecheck;
extern	int	specific_constrain_omega;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern	int	specific_constrain_phi;		/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern	int	specific_constrain_kappa;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern	int	specific_strip_ave;
extern	float   specific_bchk_time;             /* time for beamstop check */
extern	float   specific_bchk_deltaphi;         /* delta phi for beamstop check */
extern	float   specific_kappa_const;           /* kappa constant */
extern	int     specific_madrun_naming;         /* 1 for Henry's convention, 0 for cn's */
extern	int     specific_retryshort;         /* 1 to retry short exposures, mar bases */
extern	int     specific_ccd_modular;           /* 1 if we are using modular (multiple) framegrabbers */
extern	int	specific_pf_mod;
extern	int	specific_usestop_immediate;
extern	float   specific_min_velocity;
extern	float   specific_max_velocity;
extern	int     specific_allow_stills;
extern	int     specific_pitch_tune_delta;
extern	int     specific_bm8_mod;

