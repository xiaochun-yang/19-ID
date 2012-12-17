#include	"detcon_defs.h"

extern	int	errno;		/* system */

extern char	dtc_lfname[256];
extern char	dtc_confname[256];

extern int	dtc_fdcom;
extern int	dtc_fdout;
extern FILE	*dtc_fpout;
extern int	dtc_fdstat;
extern int	dtc_fdxfcm;
extern FILE	*dtc_fplog;
extern FILE	*dtc_fpconfig;
extern int	dtc_fddetcmd;
extern int	dtc_fddetstatus;
extern int	dtc_fdblcmd;
extern int	dtc_fdblstatus;
extern int      dtc_xfdatafd;

extern int	dtc_detector_sn;
extern int	dtc_no_transform;
extern int	dtc_output_raws;
extern int	dtc_constrain_omega;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern int	dtc_constrain_phi;		/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern int	dtc_constrain_kappa;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */

extern char	*dtc_trntable;

extern char	dtc_default_suffix[20];
extern int	dtc_default_imsize;
extern int	dtc_state;
extern int	dtc_expos_msec_ticks;
extern int	dtc_initialized;
extern char	dtc_status_string[512];
extern char	dtc_lasterror_string[512];

extern FILE	*dtc_fpnull;
extern int	dtc_dc_in_progress;
extern int	dtc_last;

extern	float	dtc_stat_dist;
extern	float	dtc_stat_lift;
extern	float	dtc_stat_phi;
extern	float	dtc_stat_omega;
extern	float	dtc_stat_kappa;
extern	float	dtc_stat_start_phi;
extern	float	dtc_stat_start_omega;
extern	float	dtc_stat_start_kappa;
extern	float	dtc_stat_osc_width;
extern	float	dtc_stat_time;
extern	float	dtc_stat_dose;
extern	float	dtc_stat_intensity;
extern	float	dtc_stat_wavelength;
extern	float	dtc_stat_multiplier;
extern	int	dtc_stat_axis;
extern	int	dtc_stat_mode;
extern	int	dtc_stat_max_count;
extern	int	dtc_stat_n_images;
extern	int	dtc_stat_n_passes;
extern	int	dtc_stat_n_mdc_updates;
extern	int	dtc_stat_n_ccd_updates;
extern	int	dtc_stat_image_number;
extern	int	dtc_stat_adc;
extern	int	dtc_stat_bin;
extern	char	dtc_stat_dir[80];
extern	char	dtc_stat_prefix[80];
extern	char	dtc_stat_fname[80];
extern	char	dtc_stat_scanner_op[80];
extern	char	dtc_stat_scanner_msg[80];
extern	char	dtc_stat_scanner_control[80];
extern	char	dtc_stat_scanner_shutter[80];
extern	char	dtc_stat_mode_msg[80];
extern	float	dtc_stat_xcen;
extern	float	dtc_stat_ycen;
extern	float	dtc_stat_2theta;
extern	int	dtc_stat_compress;
extern	int	dtc_stat_anom;
extern	int	dtc_stat_wedge;
extern	float	dtc_stat_dzratio;
extern  float   dtc_stat_step_size;
extern  float   dtc_stat_dose_step;

extern	int	dtc_use_pc_shutter;
extern	int	dtc_use_j5_trigger;
extern	int	dtc_use_timecheck;

extern	char	dtc_mdc_alert[80];

extern	int	dtc_dc_stop;
extern	int	dtc_raw_ccd_image;
extern	int	dtc_repeat_dark_current;
extern	int     dtc_dark_current_interval;      /* interval in sec for recollect dark currents */
extern	int     dtc_dark_current_time;          /* time function value for last dark current */
extern	int	dtc_dark_mode;
extern	int	dtc_force_dark;
extern	float	dtc_pixel_size;
extern	int	dtc_dk_before_run;
extern	int	dtc_strip_ave;
extern	int	dtc_image_kind;
extern	int	dtc_lastimage;
extern	char	dtc_filename[512];
extern	char	dtc_comment[512];
extern	char	dtc_det_reply[512];
extern	char	dtc_xform_reply[512];

extern	void	(*dtc_mdc_cmd_start)();
extern	int	(*dtc_mdc_cmd_progress)();

extern	float	dtc_dt_stat;

extern	float	dtc_erase_time;
extern	float	dtc_scan_time;
extern	float	dtc_dc_erase_time;
extern	int	dtc_phi_steps_deg;
extern	int	dtc_dist_steps_mm;
extern	int	dtc_phi_top_speed;
extern	int	dtc_phi_speed_used;
extern	int	dtc_dist_top_speed;
extern	int	dtc_dist_max_ref_point;
extern	int	dtc_dist_min_ref_point;
extern	int	dtc_units_per_second;
extern	int	dtc_units_per_dose;
extern	int	dtc_magic_flags;
extern	int	dtc_is_distance;
extern	int	dtc_is_phi;
extern	int	dtc_radius_mode;
extern	float	dtc_read_fast;
extern	float	dtc_read_slow;
extern	float	dtc_read_overhead;
extern	float	dtc_bin_factor;
extern	float   dtc_time_nobin_slow;    /* readout time for slow no binned */
extern	float   dtc_time_nobin_fast;    /* readout time for fast no binned */
extern	float   dtc_time_bin_slow;      /* readout time for slow binned */
extern	float   dtc_time_bin_fast;      /* readout time for fast binned */
extern	int	dtc_is_kappa;
extern	int	dtc_is_omega;
extern	int	dtc_def_dezinger;
extern	int	dtc_is_2theta;
extern	int	dtc_nc_pointer;
extern	int	dtc_nc_index;
extern	int	dtc_nc_x;	
extern	int	dtc_nc_y;
extern	int	dtc_nc_rec;
extern	int	dtc_nc_poff;
extern	int	dtc_scsi_id;
extern	int	dtc_scsi_controller;
extern	int	dtc_spiral_check;
extern	int	dtc_outfile_type;
extern	int	dtc_n_ctrl;
extern	int	dtc_n_strip_ave;
extern	float	dtc_strip_ave_vals[4];
extern	int     dtc_chip_size_x;               /* chip size in x = number of columns */
extern	int     dtc_chip_size_y;               /* chip size in y = number of rows */
extern	int	dtc_t2k_detector;
extern	int	dtc_modular;

extern	float	dtc_specific_erase_time;
extern	float	dtc_specific_scan_time;
extern	float	dtc_specific_dc_erase_time;
extern	int	dtc_specific_total_valid_blocks;
extern	int	dtc_specific_total_pixels_x;
extern	int	dtc_specific_total_pixels_y;
extern	float	dtc_specific_multiplier;
extern	int	dtc_specific_phi_steps_deg;	
extern	int	dtc_specific_dist_steps_mm;
extern	int	dtc_specific_phi_top_speed;
extern	int	dtc_specific_dist_top_speed;
extern	int	dtc_specific_dist_max_point;
extern	int	dtc_specific_dist_min_point;
extern	int	dtc_specific_units_per_sec;
extern	int	dtc_specific_units_per_dose;
extern	float	dtc_specific_wavelength;
extern	int	dtc_specific_is_distance;
extern	int	dtc_specific_is_phi;
extern	int	dtc_specific_flags;
extern	int	dtc_specific_nc_pointer;
extern	int	dtc_specific_nc_index;
extern	int	dtc_specific_nc_x;	
extern	int	dtc_specific_nc_y;
extern	int	dtc_specific_nc_rec;
extern	int	dtc_specific_nc_poff;
extern	int	dtc_specific_scsi_id;
extern	int	dtc_specific_scsi_controller;
extern	int	dtc_specific_spiral_check;

extern	int	dtc_lift_steps;
extern	int	dtc_lift_steps_mm;
extern	int	dtc_lift_top_speed;
extern	int	dtc_lift_max_point;
extern	int	dtc_lift_min_point;
extern	int	dtc_is_lift;
extern	int	dtc_specific_lift_steps_mm;
extern	int	dtc_specific_lift_top_speed;
extern	int	dtc_specific_lift_max_point;
extern	int	dtc_specific_lift_min_point;
extern	int	dtc_specific_is_lift;
extern	float	dtc_specific_read_fast;
extern	float	dtc_specific_read_slow;
extern	float	dtc_specific_read_overhead;
extern	float	dtc_specific_bin_factor;
extern	int	dtc_specific_is_kappa;
extern	int	dtc_specific_is_omega;
extern	int	dtc_specific_def_dezinger;
extern	int	dtc_specific_is_2theta;
extern	int	dtc_specific_pcshutter;
extern	int     dtc_specific_dark_interval;
extern	float	dtc_specific_pixel_size;
extern	int	dtc_specific_dk_before_run;
extern	int	dtc_specific_repeat_dark;
extern	int	dtc_specific_outfile_type;
extern	int	dtc_specific_detector_sn;
extern	int	dtc_specific_no_transform;
extern	int	dtc_specific_output_raws;
extern	int	dtc_specific_j5_trigger;
extern	int	dtc_specific_timecheck;
extern	int	dtc_specific_constrain_omega;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern	int	dtc_specific_constrain_phi;		/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern	int	dtc_specific_constrain_kappa;	/* 0 for don't care, 180 for -180:180, 360 (def) for 0-360 */
extern	int	dtc_specific_strip_ave;
extern	int     dtc_specific_chip_size_x;               /* chip size in x = number of columns */
extern	int     dtc_specific_chip_size_y;               /* chip size in y = number of rows */
extern	int	dtc_specific_t2k_detector;
extern	int	dtc_specific_modular;

