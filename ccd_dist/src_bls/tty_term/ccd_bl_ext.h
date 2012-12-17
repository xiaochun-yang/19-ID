#include	"ccd_bl_defs.h"

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

extern int	fposcom;
extern int	fposout;
extern int	fposstat;

extern char	*trntable;

extern mdc_command	mdc_queue[MAXQUEUE];
extern mdc_command	*mdc_head;
extern mdc_command	mdc_current;

extern int		end_of_command_notify;
extern int		halt_status_output;

extern	float	stat_dist;
extern	float	stat_lift;
extern	float	stat_phi;
extern	float	stat_omega;
extern	float	stat_kappa;
extern	float	stat_2theta;
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
extern	char	stat_dir[80];
extern	char	stat_fname[80];
extern	char	stat_scanner_op[80];
extern	char	stat_scanner_msg[80];
extern	char	stat_scanner_control[80];
extern	char	stat_scanner_shutter[80];
extern	char	stat_mode_msg[80];
extern	char	stat_detector_op[80];
extern	int	stat_detector_percent_complete;
extern	int	stat_adc;
extern	int	stat_bin;
extern	float	stat_xcen;
extern	float	stat_ycen;

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
extern	int	dc_abort_ctr;
extern	int	dc_error_rec;
extern	int	mdc_alert[40];

extern char	*mdc_comlit[];

extern	int	mdc_cmd_active;
extern	int	mdc_simulation;

extern	void	(*mdc_cmd_start)();
extern	int	(*mdc_cmd_progress)();
extern	void	(*mdc_read_status_fcn)();

extern	int	fdmar;
extern 	struct	esd_status_block rs;
extern	float	dt_stat;

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
extern	int	nc_pointer;
extern	int	nc_index;
extern	int	nc_x;	
extern	int	nc_y;
extern	int	nc_rec;
extern	int	nc_poff;
extern	int	scsi_id;
extern	int	scsi_controller;
extern	int	spiral_check;

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
