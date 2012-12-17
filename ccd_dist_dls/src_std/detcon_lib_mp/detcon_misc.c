#include	"detcon_ext.h"

/*
 *-------------------------------------------
 *
 *	Miscellaneous routines in this module.
 *
 *-------------------------------------------
 */

/*
 *	ccd_initialize
 *
 *	ccd_initialize translates logical names
 *	into actual file names (environment for
 *	UNIX, logical name table for VMS) and
 *	opens them in their appropriate states.
 *
 *	Next, ccd_initialize assigns default values
 *	of scanner times or attributes to the
 *	variables labled "specific...".
 *
 *	Then ccd_initialize reads the user's
 *	configuration file and alters the
 *	"specific..." variables based on that
 *	file's contents.
 *
 *	Finally, the "specific..." variables are
 *	used to assign values to variables which
 *	the scanner actually uses.
 *
 *	So the order of precedence:
 *
 *	  1)	mardefs.h	(lowest)
 *	  2)	user config	(next)
 *	  3)	values from profile (highest)
 */

detcon_ccd_initialize()
  {
	long	clock;
	char	*cptr;

	dtc_fpout = NULL;
	dtc_fplog = NULL;
	dtc_fpconfig = NULL;
	dtc_fdcom = dtc_fdout = dtc_fdstat = dtc_fdxfcm = -1;
	dtc_xfdatafd = -1;

	if(NULL == (dtc_fpnull = fopen("/dev/null","r+")))
	  {
	    fprintf(stderr,"ccd_dc: ccd_initialize: cannot open /dev/null\n");
	    exit(0);
	  }

	detcon_ccd_init_files();
/*
 *	Log the time to the errorlog for startup
 */
	time(&clock);
	cptr = (char *) ctime(&clock);
	fprintf(dtc_fplog,"=============================\n");
	fprintf(dtc_fplog,"ccd_dc: started %s\n",cptr);
	fprintf(dtc_fplog,"=============================\n");

	detcon_ccd_init_defaults();
	detcon_ccd_init_config(dtc_fpnull);
	detcon_ccd_init_vars();
	strcpy(dtc_mdc_alert,"");
	dtc_dc_in_progress = 0;
	dtc_time_nobin_slow = 0.5;
	dtc_time_nobin_fast = 0.5;
	dtc_time_bin_slow = 0.20;
	dtc_time_bin_fast = 0.20;
  }

/*
 *	This routine assigns the first round of
 *	values to the "specific..." variables.
 *
 *	The defaults come from this programs
 * 	ccd_dc_defs.h file.  Variables which change
 *	from scanner to scanner or from some
 *	other reason will be altered in the next
 *	phase of initialization.
 */

detcon_ccd_init_defaults()
  {
	dtc_specific_erase_time = SPECIFIC_ERASE_TIME;
	dtc_specific_scan_time = SPECIFIC_SCAN_TIME;
	dtc_specific_dc_erase_time = SPECIFIC_DC_ERASE_TIME;	
	dtc_specific_total_valid_blocks = SPECIFIC_TOTAL_VALID_BLOCKS;
	dtc_specific_total_pixels_x = SPECIFIC_TOTAL_PIXELS_X;
	dtc_specific_total_pixels_y = SPECIFIC_TOTAL_PIXELS_Y;
	dtc_specific_multiplier = SPECIFIC_MULTIPLIER;
	dtc_specific_phi_steps_deg = SPECIFIC_PHI_STEPS_DEG;
	dtc_specific_dist_steps_mm = SPECIFIC_DIST_STEPS_MM;
	dtc_specific_lift_steps_mm = SPECIFIC_LIFT_STEPS_MM;
	dtc_specific_phi_top_speed = SPECIFIC_PHI_TOP_SPEED;
	dtc_specific_dist_top_speed = SPECIFIC_DIST_TOP_SPEED;
	dtc_specific_lift_top_speed = SPECIFIC_LIFT_TOP_SPEED;
	dtc_specific_dist_max_point = SPECIFIC_DIST_MAX_POINT;
	dtc_specific_dist_min_point = SPECIFIC_DIST_MIN_POINT;
	dtc_specific_lift_max_point = SPECIFIC_LIFT_MAX_POINT;
	dtc_specific_lift_min_point = SPECIFIC_LIFT_MIN_POINT;
	dtc_specific_units_per_sec = SPECIFIC_UNITS_PER_SEC;
	dtc_specific_units_per_dose = SPECIFIC_UNITS_PER_DOSE;
	dtc_specific_wavelength = SPECIFIC_WAVELENGTH;
	dtc_specific_is_distance = SPECIFIC_IS_DIST;
	dtc_specific_is_phi = SPECIFIC_IS_PHI;
	dtc_specific_is_lift = SPECIFIC_IS_LIFT;
	dtc_specific_flags = SPECIFIC_FLAGS;
	dtc_specific_nc_pointer = SPECIFIC_NC_POINTER;
	dtc_specific_nc_index = SPECIFIC_NC_INDEX;
	dtc_specific_nc_x = SPECIFIC_NC_X;	
	dtc_specific_nc_y = SPECIFIC_NC_Y;
	dtc_specific_nc_rec = SPECIFIC_NC_REC;
	dtc_specific_nc_poff = SPECIFIC_NC_POFF;
	dtc_specific_scsi_id = SPECIFIC_SCSI_ID;
	dtc_specific_scsi_controller = SPECIFIC_SCSI_CONTROLLER;
	dtc_specific_spiral_check = SPECIFIC_SPIRAL_CHECK;
	dtc_specific_read_fast = SPECIFIC_READ_FAST;
	dtc_specific_read_slow = SPECIFIC_READ_SLOW;
	dtc_specific_read_overhead = SPECIFIC_READ_OVERHEAD;
	dtc_specific_bin_factor = SPECIFIC_BIN_FACTOR;
	dtc_specific_is_kappa = SPECIFIC_IS_KAPPA;
	dtc_specific_is_omega = SPECIFIC_IS_OMEGA;
	dtc_specific_def_dezinger = SPECIFIC_DEF_DEZINGER;
	dtc_specific_is_2theta = SPECIFIC_IS_2THETA;
	dtc_specific_pcshutter = SPECIFIC_PCSHUTTER;
	dtc_specific_dark_interval = SPECIFIC_DARK_INTERVAL;
	dtc_specific_pixel_size = SPECIFIC_PIXEL_SIZE;
	dtc_specific_dk_before_run = SPECIFIC_DK_BEFORE_RUN;
	dtc_specific_repeat_dark = dtc_repeat_dark_current; 
	dtc_specific_outfile_type = SPECIFIC_OUTFILE_TYPE;
	dtc_specific_detector_sn = SPECIFIC_DETECTOR_SN;
	dtc_specific_no_transform = SPECIFIC_NO_TRANSFORM;
	dtc_specific_output_raws = SPECIFIC_OUTPUT_RAWS;
	dtc_specific_j5_trigger = SPECIFIC_J5_TRIGGER;
	dtc_specific_timecheck = SPECIFIC_TIMECHECK;
	dtc_specific_constrain_omega = SPECIFIC_CONSTRAIN_OMEGA;
	dtc_specific_constrain_phi   = SPECIFIC_CONSTRAIN_PHI;
	dtc_specific_constrain_kappa = SPECIFIC_CONSTRAIN_KAPPA;
	dtc_specific_strip_ave = SPECIFIC_STRIP_AVE;
        dtc_specific_chip_size_x = SPECIFIC_CHIP_SIZE_X;
	dtc_specific_chip_size_y = SPECIFIC_CHIP_SIZE_Y;
	dtc_specific_t2k_detector = SPECIFIC_T2K_DETECTOR;
	dtc_specific_modular = SPECIFIC_MODULAR;
  }

/*
 *	This routine initializes scanner global
 *	variables now that the program has decided
 *	what the specific parameters actually are.
 */

detcon_ccd_init_vars()
  {

	dtc_dt_stat = 1.0;
	dtc_erase_time = dtc_specific_erase_time;
	dtc_dc_erase_time = dtc_specific_dc_erase_time;
	dtc_scan_time = dtc_specific_scan_time;
	dtc_phi_steps_deg = dtc_specific_phi_steps_deg;
	dtc_dist_steps_mm = dtc_specific_dist_steps_mm;
	dtc_lift_steps_mm = dtc_specific_lift_steps_mm;
	dtc_phi_top_speed = dtc_specific_phi_top_speed;
	dtc_dist_top_speed = dtc_specific_dist_top_speed;
	dtc_lift_top_speed = dtc_specific_lift_top_speed;
	dtc_dist_max_ref_point = dtc_specific_dist_max_point;
	dtc_dist_min_ref_point = dtc_specific_dist_min_point;
	dtc_lift_max_point = dtc_specific_lift_max_point;
	dtc_lift_min_point = dtc_specific_lift_min_point;
	dtc_units_per_second = dtc_specific_units_per_sec;
	dtc_units_per_dose = dtc_specific_units_per_dose;
	dtc_stat_wavelength = dtc_specific_wavelength;
	dtc_stat_multiplier = dtc_specific_multiplier;
	dtc_magic_flags = dtc_specific_flags;
	dtc_is_distance = dtc_specific_is_distance;
	dtc_is_phi = dtc_specific_is_phi;
	dtc_is_lift = dtc_specific_is_lift;
	dtc_read_fast = dtc_specific_read_fast;
	dtc_read_slow = dtc_specific_read_slow;
	dtc_read_overhead = dtc_specific_read_overhead;
	dtc_bin_factor = dtc_specific_bin_factor;
	dtc_is_kappa = dtc_specific_is_kappa;
	dtc_is_omega = dtc_specific_is_omega;
	dtc_def_dezinger = dtc_specific_def_dezinger;
	dtc_is_2theta = dtc_specific_is_2theta;
	dtc_use_pc_shutter = dtc_specific_pcshutter;
	dtc_use_j5_trigger = dtc_specific_j5_trigger;
	dtc_use_timecheck = dtc_specific_timecheck;
	dtc_dark_current_interval = dtc_specific_dark_interval;
	dtc_pixel_size = dtc_specific_pixel_size;
	dtc_dk_before_run = dtc_specific_dk_before_run;
	dtc_repeat_dark_current = dtc_specific_repeat_dark;
	dtc_strip_ave = dtc_specific_strip_ave;
        dtc_chip_size_x = dtc_specific_chip_size_x;
        dtc_chip_size_y = dtc_specific_chip_size_y;
	dtc_t2k_detector = dtc_specific_t2k_detector;
	dtc_modular = dtc_specific_modular;
 

	dtc_nc_pointer = dtc_specific_nc_pointer;
	dtc_nc_index = dtc_specific_nc_index;
	dtc_nc_x = dtc_specific_nc_x;	
	dtc_nc_y = dtc_specific_nc_y;
	dtc_nc_rec = dtc_specific_nc_rec;
	dtc_nc_poff = dtc_specific_nc_poff;

	dtc_stat_mode = 0;
	dtc_scsi_id = dtc_specific_scsi_id;
	dtc_scsi_controller = dtc_specific_scsi_controller;
	dtc_spiral_check = dtc_specific_spiral_check;

	dtc_stat_xcen = 45.;
	dtc_stat_ycen = 45.;

	dtc_outfile_type = dtc_specific_outfile_type;
	dtc_detector_sn = dtc_specific_detector_sn;
	dtc_raw_ccd_image = dtc_specific_no_transform;
	dtc_output_raws = dtc_specific_output_raws;
	dtc_constrain_omega = dtc_specific_constrain_omega;
	dtc_constrain_phi   = dtc_specific_constrain_phi;
	dtc_constrain_kappa = dtc_specific_constrain_kappa;

	dtc_default_imsize = dtc_chip_size_x * dtc_chip_size_y * 2 * dtc_n_ctrl;

  }

/*
 *	This routine handles the name translation
 *	and file opens, leaving all in their proper
 *	state.
 *
 *	Network version:
 *	  Open up the log file.
 *	  Open up the config file.
 *	  Open up the profile file.
 */

detcon_ccd_init_files()
  {
	int	i;
	char	temp[50];

	/*
	 *	Translate logical names.
	 */

	if(0 == trnlog(dtc_trntable,CCD_DC_LOCAL_LOG,dtc_lfname))
	  {
	    fprintf(stderr,
	      "Please set the logical name or environment variable.\n");
	    fprintf(stderr,
	      "Then re-execute ccd_dc.\n");
	    detcon_cleanexit(BAD_STATUS);
	  }
        if(0 == trnlog(dtc_trntable,CCD_DC_CONFIG,dtc_confname))
          {
            fprintf(stderr,
              "Please set the logical name or environment variable.\n");
            fprintf(stderr,
              "Then re-execute ccd_dc.\n");
            detcon_cleanexit(BAD_STATUS);
          }
        if(0 != trnlog(dtc_trntable,CCD_N_CTRL,temp))
	    sscanf(temp,"%d",&dtc_n_ctrl);
	  else
	    dtc_n_ctrl = 1;

	/*
	 *	Open up log file only.
	 */
	
	if(NULL == (dtc_fplog = fopen(dtc_lfname,OPENA_REC)))
	  {
	    fprintf(stderr,"Cannot open %s as mar log file\n",dtc_lfname);
	    detcon_cleanexit(BAD_STATUS);
	  }

  }

/*
 *	detcon_ccd_init_config
 *
 *	This routine allows the user to override default
 *	values for the scanner specific variables from
 *	a configuration file.
 *
 *	The format of the configuration file is:
 *
 *	keyword		value
 *
 *	The user may specify as little of the formal
 *	keyword as is necessary for unambiguous
 *	determination of the keyword.
 */

/*
 *	keywords:
 */

struct config_key {
			char	*key_name;
			char	*key_abbr;
			int	key_value;
		  };

enum {
	KEY_ERASE_TIME	=      0,
	KEY_SCAN_TIME		,
	KEY_DC_ERASE_TIME	,
	KEY_TOTAL_VALID_BLOCKS	,
	KEY_TOTAL_PIXELS_X	,
	KEY_TOTAL_PIXELS_Y	,
	KEY_MULTIPLIER		,
	KEY_PHI_STEPS_DEG	,
	KEY_DIST_STEPS_MM	,
	KEY_PHI_TOP_SPEED	,
	KEY_DIST_TOP_SPEED	,
	KEY_DIST_MAX_POINT	,
	KEY_DIST_MIN_POINT	,
	KEY_UNITS_PER_SEC	,
	KEY_UNITS_PER_DOSE	,
	KEY_WAVELENGTH		,
	KEY_IS_DIST		,
	KEY_IS_PHI		,
	KEY_FLAGS		,
	KEY_NC_POINTER		,
	KEY_NC_INDEX		,
	KEY_NC_X		,
	KEY_NC_Y		,
	KEY_NC_REC		,
	KEY_NC_POFF		,
	KEY_SCSI_ID		,
	KEY_SCSI_CONTROLLER	,
	KEY_SPIRAL_CHECK	,
	KEY_LIFT_STEPS_MM       ,
	KEY_LIFT_TOP_SPEED      ,
	KEY_LIFT_MAX_POINT      ,
	KEY_LIFT_MIN_POINT      ,
	KEY_IS_LIFT             ,
	KEY_READ_FAST		,
	KEY_READ_SLOW		,
	KEY_READ_OVERHEAD	,
	KEY_BIN_FACTOR		,
	KEY_USEKAPPA		,
	KEY_USEOMEGA		,
	KEY_DEZINGER		,
	KEY_USE2THETA		,
	KEY_PCSHUTTER		,
	KEY_DARKINTERVAL	,
	KEY_PIXEL_SIZE		,
	KEY_DK_BEFORE_RUN	,
	KEY_REPEAT_DARK		,
	KEY_OUTFILE_TYPE	,
	KEY_DETECTOR_SN		,
	KEY_NO_TRANSFORM	,
	KEY_OUTPUT_RAWS		,
	KEY_J5_TRIGGER		,
	KEY_TIMECHECK		,
	KEY_CONSTRAIN_OMEGA	,
	KEY_CONSTRAIN_PHI	,
	KEY_CONSTRAIN_KAPPA	,
	KEY_STRIP_AVE		,
	KEY_BCHK_TIME		,
	KEY_BCHK_DELTAPHI	,
	KEY_USEWAVELENGTH	,
	KEY_APPROACH_START	,
	KEY_CHIP_SIZE_X		,
	KEY_CHIP_SIZE_Y		,
	KEY_KAPPA_CONST		,
	KEY_DAEMON_EXIT		,
	KEY_USEZERO_ANGLES	,
	KEY_USEGON_MANUAL	,
	KEY_MADRUN_NAMING	,
	KEY_RETRYSHORT		,
	KEY_T2K_DETECTOR	,
	KEY_MODULAR
  };
struct config_key detcon_config_list[] = 
  {
		"erasetime","erasetime",KEY_ERASE_TIME, 
		"scantime","scantime",KEY_SCAN_TIME,
		"dcerasetime","dcerasetime",KEY_DC_ERASE_TIME,
		"blocks","blocks",KEY_TOTAL_VALID_BLOCKS,
		"pixelsx","pixelsx", KEY_TOTAL_PIXELS_X,
		"pixelsy","pixelsy",KEY_TOTAL_PIXELS_Y,
		"multiplier","multiplier",KEY_MULTIPLIER,
		"phisteps","phis",KEY_PHI_STEPS_DEG,
		"diststeps","dists",KEY_DIST_STEPS_MM,
		"phitop","phitop",KEY_PHI_TOP_SPEED,
		"disttop","disttop",KEY_DIST_TOP_SPEED,
		"distmax","distmax",KEY_DIST_MAX_POINT,
		"distmin","distmin",KEY_DIST_MIN_POINT,
		"unitsec","unitsec",KEY_UNITS_PER_SEC,
		"unitdose","unitdose",KEY_UNITS_PER_DOSE,
		"wavelength","wavelength",KEY_WAVELENGTH,
		"usedistance","usedistance",KEY_IS_DIST,
		"usephi","usephi",KEY_IS_PHI,
		"flags","flags",KEY_FLAGS,
		"nc_pointer","nc_pointer",KEY_NC_POINTER,
		"nc_index","nc_index",KEY_NC_INDEX,
		"nc_x","nc_x",KEY_NC_X,
		"nc_y","nc_y",KEY_NC_Y,
		"nc_rec","nc_rec",KEY_NC_REC,
		"nc_poff","nc_poff",KEY_NC_POFF,
		"scsi_id","scsi_id",KEY_SCSI_ID,
		"scsi_controller","scsi_controller",KEY_SCSI_CONTROLLER,
		"spiral_check","spiral_check",KEY_SPIRAL_CHECK,
		"liftsteps","liftsteps",KEY_LIFT_STEPS_MM,
		"lifttop","lifttop",KEY_LIFT_TOP_SPEED,
		"liftmax","liftmax",KEY_LIFT_MAX_POINT,
		"liftmin","liftmin",KEY_LIFT_MIN_POINT,
		"uselift","uselift",KEY_IS_LIFT,
		"read_fast","read_fast",KEY_READ_FAST,
		"read_slow","read_slow",KEY_READ_SLOW,
		"read_overhead","read_overhead",KEY_READ_OVERHEAD,
		"bin_factor","bin_factor",KEY_BIN_FACTOR,
		"usekappa","usekappa",KEY_USEKAPPA,
		"useomega","useomega",KEY_USEOMEGA,
		"dezinger","dezinger",KEY_DEZINGER,
		"use2theta","use2theta",KEY_USE2THETA,
		"pcshutter","pcshutter",KEY_PCSHUTTER,
		"darkinterval","darkinterval",KEY_DARKINTERVAL,
		"pixel_size","pixel_size",KEY_PIXEL_SIZE,
		"dk_before_run","dk_before_run",KEY_DK_BEFORE_RUN,
		"repeat_dark","repeat_dark",KEY_REPEAT_DARK,
		"outfile_type","outfile_type",KEY_OUTFILE_TYPE,
		"detector_sn","detector_sn",KEY_DETECTOR_SN,
		"no_transform","no_transform",KEY_NO_TRANSFORM,
		"output_raws","output_raws",KEY_OUTPUT_RAWS,
		"j5_trigger","j5_trigger",KEY_J5_TRIGGER,
		"timecheck","timecheck",KEY_TIMECHECK,
		"constrain_omega","timecheck",KEY_CONSTRAIN_OMEGA,
		"constrain_phi","timecheck",KEY_CONSTRAIN_PHI,
		"constrain_kappa","timecheck",KEY_CONSTRAIN_KAPPA,
		"strip_ave","strip_ave",KEY_STRIP_AVE,
                "chip_size_x","chip_size_x",KEY_CHIP_SIZE_Y,
                "chip_size_y","chip_size_y",KEY_CHIP_SIZE_X,
		"t2k_detector", "t2k_detector", KEY_T2K_DETECTOR,
		"modular", "modular", KEY_MODULAR,
		NULL,NULL,0,
  };

detcon_ccd_init_config(fpmsg)
FILE	*fpmsg;
  {
	char	tname[256];
	char	line[132];
	char	string1[132],string2[132];
	int	i,j;

	strcpy(tname,dtc_confname);

	if(NULL == (dtc_fpconfig = fopen(tname,"r")))
	  {
	    fprintf(stderr,"ccd_dc: config: cannot open config file %s\n",tname);
	    fprintf(dtc_fplog,"ccd_dc: config: cannot open config file %s\n",tname);
	    fflush(dtc_fplog);
	    return;
	  }

	while(NULL != fgets(line,sizeof line,dtc_fpconfig))
	  {
	    if(line[0] == '!' || line[0] == '#')
	      {
		fprintf(fpmsg,"%s",line);
		fprintf(dtc_fplog,"%s",line);
		continue;
	      }
	    i = sscanf(line,"%s%s",string1,string2);
	    if(i != 2)
	      {
		fprintf(stderr,"ccd_dc: config: not enough params (need 2):\n");
		fprintf(stderr,"%s",line);
		fprintf(stderr,"ccd_dc: config: ignoring that line.\n");
		continue;
	      }
	    j = 0;
	    for(i = 0; detcon_config_list[i].key_name != NULL; i++)
	      if(0 == strncmp(detcon_config_list[i].key_abbr,string1,strlen(detcon_config_list[i].key_abbr)))
		{
			j = 1;
			break;
		}
	    if(j == 0)
	      {
		fprintf(stderr,"ccd_dc: config: unrecognized keyword:\n");
		fprintf(stderr,"%s",line);
		fprintf(stderr,"ccd_dc: config: ignoring that line.\n");
		continue;
	      }
	    switch(detcon_config_list[i].key_value)
	      {
		case	KEY_ERASE_TIME:
			sscanf(string2,"%f",&dtc_specific_erase_time);
			fprintf(fpmsg,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_erase_time);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_erase_time);
			break;
		case	KEY_SCAN_TIME:
			sscanf(string2,"%f",&dtc_specific_scan_time);
			fprintf(fpmsg,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_scan_time);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_scan_time);
			break;
		case	KEY_DC_ERASE_TIME:
			sscanf(string2,"%f",&dtc_specific_dc_erase_time);
			fprintf(fpmsg,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_dc_erase_time);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_dc_erase_time);
			break;
		case	KEY_TOTAL_VALID_BLOCKS:
			sscanf(string2,"%d",&dtc_specific_total_valid_blocks);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_total_valid_blocks);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_total_valid_blocks);
			break;
		case	KEY_TOTAL_PIXELS_X:
			sscanf(string2,"%d",&dtc_specific_total_pixels_x);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_total_pixels_x);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_total_pixels_x);
			break;
		case	KEY_TOTAL_PIXELS_Y:
			sscanf(string2,"%d",&dtc_specific_total_pixels_y);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_total_pixels_y);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_total_pixels_y);
			break;
		case	KEY_MULTIPLIER:
			sscanf(string2,"%f",&dtc_specific_multiplier);
			fprintf(fpmsg,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_multiplier);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_multiplier);
			break;
		case	KEY_PHI_STEPS_DEG:
			sscanf(string2,"%d",&dtc_specific_phi_steps_deg);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_phi_steps_deg);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_phi_steps_deg);
			break;
		case	KEY_DIST_STEPS_MM:
			sscanf(string2,"%d",&dtc_specific_dist_steps_mm);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dist_steps_mm);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dist_steps_mm);
			break;
		case	KEY_PHI_TOP_SPEED:
			sscanf(string2,"%d",&dtc_specific_phi_top_speed);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_phi_top_speed);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_phi_top_speed);
			break;
		case	KEY_DIST_TOP_SPEED:
			sscanf(string2,"%d",&dtc_specific_dist_top_speed);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dist_top_speed);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dist_top_speed);
			break;
		case	KEY_DIST_MAX_POINT:
			sscanf(string2,"%d",&dtc_specific_dist_max_point);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dist_max_point);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dist_max_point);
			break;
		case	KEY_DIST_MIN_POINT:
			sscanf(string2,"%d",&dtc_specific_dist_min_point);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dist_min_point);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dist_min_point);
			break;
		case	KEY_UNITS_PER_SEC:
			sscanf(string2,"%d",&dtc_specific_units_per_sec);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_units_per_sec);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_units_per_sec);
			break;
		case	KEY_UNITS_PER_DOSE:
			sscanf(string2,"%d",&dtc_specific_units_per_dose);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_units_per_dose);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_units_per_dose);
			break;
		case	KEY_WAVELENGTH:
			sscanf(string2,"%f",&dtc_specific_wavelength);
			fprintf(fpmsg,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_wavelength);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %10.2f\n",
				detcon_config_list[i].key_name,dtc_specific_wavelength);
			break;
		case	KEY_IS_DIST:
			sscanf(string2,"%d",&dtc_specific_is_distance);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_distance);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_distance);
			break;
		case	KEY_IS_PHI:
			sscanf(string2,"%d",&dtc_specific_is_phi);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_phi);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_phi);
			break;
		case	KEY_FLAGS:
			sscanf(string2,"%d",&dtc_specific_flags);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_flags);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_flags);
			break;
		case	KEY_NC_POINTER:
			sscanf(string2,"%d",&dtc_specific_nc_pointer);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_pointer);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_pointer);
			break;
		case	KEY_NC_INDEX:
			sscanf(string2,"%d",&dtc_specific_nc_index);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_index);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_index);
			break;
		case	KEY_NC_X:
			sscanf(string2,"%d",&dtc_specific_nc_x);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_x);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_x);
			break;
		case	KEY_NC_Y:
			sscanf(string2,"%d",&dtc_specific_nc_y);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_y);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_y);
			break;
		case	KEY_NC_REC:
			sscanf(string2,"%d",&dtc_specific_nc_rec);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_rec);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_rec);
			break;
		case	KEY_NC_POFF:
			sscanf(string2,"%d",&dtc_specific_nc_poff);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_poff);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_nc_poff);
			break;
		case	KEY_SCSI_ID:
			sscanf(string2,"%d",&dtc_specific_scsi_id);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_scsi_id);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_scsi_id);
			break;
		case	KEY_SCSI_CONTROLLER:
			sscanf(string2,"%d",&dtc_specific_scsi_controller);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_scsi_controller);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_scsi_controller);
			break;
		case	KEY_SPIRAL_CHECK:
			sscanf(string2,"%d",&dtc_specific_spiral_check);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",detcon_config_list[i].key_name,dtc_specific_spiral_check);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",detcon_config_list[i].key_name,dtc_specific_spiral_check);
			break;
		case	KEY_LIFT_STEPS_MM:
			sscanf(string2,"%d",&dtc_specific_lift_steps_mm);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_lift_steps_mm);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_lift_steps_mm);
			break;
		case	KEY_LIFT_TOP_SPEED:
			sscanf(string2,"%d",&dtc_specific_lift_top_speed);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_lift_top_speed);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_lift_top_speed);
			break;
		case	KEY_LIFT_MAX_POINT:
			sscanf(string2,"%d",&dtc_specific_lift_max_point);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_lift_max_point);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_lift_max_point);
			break;
		case	KEY_LIFT_MIN_POINT:
			sscanf(string2,"%d",&dtc_specific_lift_min_point);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_lift_min_point);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_lift_min_point);
			break;
		case	KEY_IS_LIFT:
			sscanf(string2,"%d",&dtc_specific_is_lift);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_lift);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_lift);
			break;
		case	KEY_READ_FAST:
			sscanf(string2,"%f",&dtc_specific_read_fast);
			fprintf(fpmsg,"ccd_dc: config: %s set to %5.2f\n",
				detcon_config_list[i].key_name,dtc_specific_read_fast);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %5.2f\n",
				detcon_config_list[i].key_name,dtc_specific_read_fast);
			break;
		case	KEY_READ_SLOW:
			sscanf(string2,"%f",&dtc_specific_read_slow);
			fprintf(fpmsg,"ccd_dc: config: %s set to %5.2f\n",
				detcon_config_list[i].key_name,dtc_specific_read_slow);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %5.2f\n",
				detcon_config_list[i].key_name,dtc_specific_read_slow);
			break;
		case	KEY_READ_OVERHEAD:
			sscanf(string2,"%f",&dtc_specific_read_overhead);
			fprintf(fpmsg,"ccd_dc: config: %s set to %5.2f\n",
				detcon_config_list[i].key_name,dtc_specific_read_overhead);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %5.2f\n",
				detcon_config_list[i].key_name,dtc_specific_read_overhead);
			break;
		case	KEY_BIN_FACTOR:
			sscanf(string2,"%f",&dtc_specific_bin_factor);
			fprintf(fpmsg,"ccd_dc: config: %s set to %5.2f\n",
				detcon_config_list[i].key_name,dtc_specific_bin_factor);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %5.2f\n",
				detcon_config_list[i].key_name,dtc_specific_bin_factor);
			break;
		case	KEY_USEKAPPA:
			sscanf(string2,"%d",&dtc_specific_is_kappa);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_kappa);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_kappa);
			break;
		case	KEY_USEOMEGA:
			sscanf(string2,"%d",&dtc_specific_is_omega);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_omega);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_omega);
			break;
		case	KEY_DEZINGER:
			sscanf(string2,"%d",&dtc_specific_def_dezinger);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_def_dezinger);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_def_dezinger);
			break;
		case	KEY_USE2THETA:
			sscanf(string2,"%d",&dtc_specific_is_2theta);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_2theta);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_2theta);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_is_2theta);
			break;
		case	KEY_PCSHUTTER:
			sscanf(string2,"%d",&dtc_specific_pcshutter);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_pcshutter);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_pcshutter);
			break;
		case	KEY_DARKINTERVAL:
			sscanf(string2,"%d",&dtc_specific_dark_interval);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dark_interval);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dark_interval);
			break;
		case	KEY_PIXEL_SIZE:
			sscanf(string2,"%f",&dtc_specific_pixel_size);
			fprintf(fpmsg,"ccd_dc: config: %s set to %f\n",
				detcon_config_list[i].key_name,dtc_specific_pixel_size);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %f\n",
				detcon_config_list[i].key_name,dtc_specific_pixel_size);
			break;
		case	KEY_DK_BEFORE_RUN:
			sscanf(string2,"%d",&dtc_specific_dk_before_run);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dk_before_run);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_dk_before_run);
			break;
		case	KEY_REPEAT_DARK:
			sscanf(string2,"%d",&dtc_specific_repeat_dark);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_repeat_dark);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_repeat_dark);
			break;
		case	KEY_DETECTOR_SN:
			sscanf(string2,"%d",&dtc_specific_detector_sn);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_detector_sn);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_detector_sn);
			break;
		case	KEY_NO_TRANSFORM:
			sscanf(string2,"%d",&dtc_specific_no_transform);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_no_transform);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_no_transform);
			break;
		case	KEY_OUTPUT_RAWS:
			sscanf(string2,"%d",&dtc_specific_output_raws);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_output_raws);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_output_raws);
			break;
		case	KEY_J5_TRIGGER:
			sscanf(string2,"%d",&dtc_specific_j5_trigger);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_j5_trigger);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_j5_trigger);
			break;
		case	KEY_STRIP_AVE:
			sscanf(string2,"%d",&dtc_specific_strip_ave);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_strip_ave);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_strip_ave);
			break;
		case	KEY_TIMECHECK:
			sscanf(string2,"%d",&dtc_specific_timecheck);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_timecheck);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_timecheck);
			break;
		case	KEY_CONSTRAIN_OMEGA:
			sscanf(string2,"%d",&dtc_specific_constrain_omega);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_constrain_omega);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_constrain_omega);
			break;
		case	KEY_CONSTRAIN_PHI:
			sscanf(string2,"%d",&dtc_specific_constrain_phi);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_constrain_phi);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_constrain_phi);
			break;
		case	KEY_CONSTRAIN_KAPPA:
			sscanf(string2,"%d",&dtc_specific_constrain_kappa);
			fprintf(fpmsg,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_constrain_kappa);
			fprintf(dtc_fplog,"ccd_dc: config: %s set to %d\n",
				detcon_config_list[i].key_name,dtc_specific_constrain_kappa);
			break;
		case	KEY_OUTFILE_TYPE:
			if(0 == strcmp(string2,"signed_long") ||
			   0 == strcmp(string2,"int"))
				dtc_outfile_type = 1;
			if(dtc_outfile_type == 0)
			  {
			    fprintf(fpmsg,"ccd_dc: config: %s set to unsigned_short\n",
				detcon_config_list[i].key_name);
			    fprintf(dtc_fplog,"ccd_dc: config: %s set to unsigned_short\n",
				detcon_config_list[i].key_name);
			  }
			 else
			  {
			    fprintf(fpmsg,"ccd_dc: config: %s set to signed_long\n",
				detcon_config_list[i].key_name);
			    fprintf(dtc_fplog,"ccd_dc: config: %s set to signed_long\n",
				detcon_config_list[i].key_name);
			  }
			break;
                case    KEY_CHIP_SIZE_X:
                        sscanf(string2,"%d",&dtc_specific_chip_size_x);
                        fprintf(fpmsg,"detcon config: %s set to %d\n",
                                detcon_config_list[i].key_name,dtc_specific_chip_size_x);
                        fprintf(dtc_fplog,"detcon config: %s set to %d\n",
                                detcon_config_list[i].key_name,dtc_specific_chip_size_x);
                        fprintf(stderr,"detcon config: %s set to %d\n",
                                detcon_config_list[i].key_name,dtc_specific_chip_size_x);
                        break;
                case    KEY_CHIP_SIZE_Y:
                        sscanf(string2,"%d",&dtc_specific_chip_size_y);
                        fprintf(fpmsg,"detcon config: %s set to %d\n",
                                detcon_config_list[i].key_name,dtc_specific_chip_size_y);
                        fprintf(dtc_fplog,"detcon config: %s set to %d\n",
                                detcon_config_list[i].key_name,dtc_specific_chip_size_y);
                        fprintf(stderr,"detcon config: %s set to %d\n",
                                detcon_config_list[i].key_name,dtc_specific_chip_size_y);
                        break;
                case    KEY_MODULAR:
                        sscanf(string2,"%d",&dtc_specific_modular);
                        fprintf(fpmsg,"detcon config: %s set to %d\n",
                                detcon_config_list[i].key_name,dtc_specific_modular);
                        fprintf(dtc_fplog,"detcon config: %s set to %d\n",
                                detcon_config_list[i].key_name,dtc_specific_modular);
                        fprintf(stderr,"detcon config: %s set to %d\n",
                                detcon_config_list[i].key_name,dtc_specific_modular);
                        break;
	      }
	  }
	fflush(dtc_fplog);
	fclose(dtc_fpconfig);
  }

static	char	timeholder[120];

static	char	*ztime()
  {
	long	clock;
	char	*cptr;

	time(&clock);
	cptr = (char *) ctime(&clock);
	strcpy(timeholder,cptr);
	timeholder[strlen(timeholder) - 1] = '\0';
	return(timeholder);
  }
