
/*
 *	Useful structure definitions pertaining to the mar ips
 *	software.  In general, these are C structure definitons
 *	corresponding to an important header, record, or common block.
 */

/*
 *	This is the logical record 1 block from the log file.
 */

struct vms_header {
			char v_serial_no_scanner[17];
			char v_serial_no_controller[13];
			char v_institute[50];
			char v_address[4][40];
			char v_contact_person[40];
			char v_date_of_purchase[12];
			char v_date_of_delivery[12];
			char v_date_of_most_recent_service[12];
			char v_service_engineer[12];
			char v_date_of_previous_service[12];
			int v_number_of_services;
			int v_current_log_block;
			int v_current_log_record;
			float v_standard_R_max;
			float v_standard_R_min;
			float v_standard_phi_0;
			float v_standard_x_off;
			float v_standard_d_l;
			float v_standard_p_l;
			float v_standard_p_r;
			float v_standard_p_x;
			float v_standard_p_y;
			float v_standard_half_x;
			float v_standard_half_y;
			float v_standard_reserve;
			float v_current_R_max;
			float v_current_R_min;
			float v_current_p_l;
			float v_current_p_x;
			float v_current_p_y;
			float v_current_half_x;
			float v_current_half_y;
			float v_current_lambda;
			float v_current_2_theta;
			float v_current_reserve;
			int v_k_phi;
			int v_k_phi_1_4;
			int v_k_phi_5_4;
			int v_l_phi_off;
			int v_DIST_min_reference_point;
			int v_DIST_max_reference_point;
			int v_DISTANCE_motor_steps_per_mm;
			int v_DISTANCE_motor_max_speed;
			int v_PHI_motor_steps_per_degree;
			int v_PHI_motor_max_speed;
			int v_OMEGA_motor_steps_per_degree;
			int v_OMEGA_motor_max_speed;
			float v_OMEGA_neg_end_switch_degrees;
			float v_OMEGA_pos_end_switch_degrees;
			int v_goniometer_reserve;
			float v_high_intensity_multiplier;
			char v_Dist_min_ref_switch_exists;
			char v_Dist_max_ref_switch_exists;
			char v_X_shutter_ref_switch_exists;
			char v_OMEGA_axis_exists;
			char v_OMEGA_neg_end_switch_exists;
			char v_OMEGA_pos_end_switch_exists;
			char v_listener_id;
			char v_IMAGE_auto_scale;
		  };

struct log_record {
			int	v_date_time;
			char	v_msg_class;
			char	v_msg_number;
			short	v_msg_aux;
		  };

struct image_header
	{
        int	fr_total_pixels_x;
	int	fr_total_pixels_y;
        int	fr_lrecl;
	int	fr_max_rec;
        int	fr_overflow_pixels;
	int	fr_overflow_records;
        int	fr_counts_per_sec_start;
	int	fr_counts_per_sec_end;
        int	fr_exposure_time_sec;
        int	fr_programmed_exp_time_units;
        float	fr_programmed_exposure_time;
	float	fr_r_max;
        float	fr_r_min;
	float	fr_p_r;
        float	fr_p_l;
	float	fr_p_x;
        float	fr_p_y;
	float	fr_centre_x;
        float	fr_centre_y;
	float	fr_lambda;
        float	fr_distance;
	float	fr_phi_start;
        float	fr_phi_end;
	float	fr_omega;
        float	fr_multiplier;
	char	fr_scanning_date_time[24];
	};

struct image_header_1200
	{
	struct image_header	hi_1200;
	int			hi_1200_rest[569];
	};

struct image_header_2000
	{
	struct image_header	hi_2000;
	int			hi_2000_rest[569 + 400];
	};

struct spiral_header {
        int	sp_total_pixels_x;
	int	sp_total_pixels_y;
        int	sp_lrecl;
	int	sp_max_rec;
        int	sp_overflow_pixels;
	int	sp_overflow_records;
        int	sp_counts_per_sec_start;
	int	sp_counts_per_sec_end;
        int	sp_exposure_time_sec;
        int	sp_programmed_exp_time_units;
        float	sp_programmed_exposure_time;
	float	sp_r_max;
        float	sp_r_min;
	float	sp_p_r;
        float	sp_p_l;
	float	sp_p_x;
        float	sp_p_y;
	float	sp_centre_x;
        float	sp_centre_y;
	float	sp_lambda;
        float	sp_distance;
	float	sp_phi_start;
        float	sp_phi_end;
	float	sp_omega;
        float	sp_multiplier;
	char	sp_scanning_date_time[24];
	int	sp_nc_pointer;
	int	sp_nc_index;
	int	sp_nc_x;
	int	sp_nc_y;
	int	sp_nc_rec;
	int	sp_nc_poff;
	int	sp_rest_of_header[219 + 256];
	};

