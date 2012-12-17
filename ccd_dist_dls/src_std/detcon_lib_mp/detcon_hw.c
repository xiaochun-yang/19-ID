#include	"detcon_ext.h"

/*
 *----------------------------------------------
 *
 *	Module to sequence the control of the CCD
 *	hardware modules.
 *
 *	Two processes are used to run hardware:
 *		ccd_det		controls the detector.
 *		ccd_bl		controls the beamline.
 *
 *	In this implimentation, it is assumed that
 *	ccd_bl controls all hardware EXCEPT the detector.
 *
 *----------------------------------------------
 */

static	int     tick;           /* used for clock counting */
static	int     units;          /* used for calculating percentage completion */
static	int     decrement;      /* used for pseudo-timing of things */
static	int     dcop;           /* software state used for collect & scan */
static	int     retrycnt;       /* retry count for hardware faults */
static	int     msign;          /* used in calculations */
static	float   start_val;      /* used in calculations */
static	float   delta;          /* ditto */
static	int     totimg;         /* used for deciding when data collection done */
static	int     totpass;        /* same, only for multiple passes in a single osc */
static	int     dc_abort;       /* signals a data collection abort */
static	int     dc_abort_ctr;   /* used during the abort procedure */
static	int     dc_error_rec;   /* used during data collection error recovery */

#define KIND_DARK_0     0
#define KIND_DARK_1     1
#define KIND_DARK_2     2
#define KIND_DARK_3     3
#define KIND_RAW_0      4
#define KIND_RAW_1      5

/*
 *	Routines to accurately calculate the
 *	time commands take to execute.  This
 *	is for the completeness statistics, for
 *	the most part, and does not actually
 *	alter functionality.
 */

static	time_t	tick_clock_val;

static  char    timeholder[120];

static  char    *ztime()
  {
        long    clock;
        char    *cptr;

        time(&clock);
        cptr = (char *) ctime(&clock);
        strcpy(timeholder,cptr);
        timeholder[strlen(timeholder) - 1] = '\0';
        return(timeholder);
  }

/*
 *	Turn an integer into xxx.  Used in image numbers.
 */

static void util_3digit(s1,val)
char	*s1;
int	val;
  {
	int	i,j;

	i = val;
	j = i / 100;
	*s1++ = (char ) ('0' + j);
	i = i - 100 * j;
	j = i / 10;
	*s1++ = (char ) ('0' + j);
	i = i - 10 * j;
	*s1++ = (char ) ('0' + i);
	*s1++ = '\0';
  }

/*
 *	Operation codes for the initialize command.
 *
 *	These are software state variables to keep
 *	track of which initialize phase the program
 *	is doing.
 */

#define	INITOP_ABORT	0
#define	INITOP_RESET	1
#define	INITOP_SHUTTER	2
#define	INITOP_LOADTAB	3
#define	INITOP_DISTANCE	4


/*
 *	Operation codes for the data collection command.
 *
 *	These are purely software states so the program
 *	can keep track of what part of data collection it
 *	is doing.
 */

#define	DCOP_COLLECT	0
#define	DCOP_SCAN	1
#define	DCOP_ERASE	2
#define	DCOP_RECRESET	3
#define	DCOP_RECERASE	4
#define	DCOP_RECSHUTTER	5


/*
 *	These are used to check to see if distance
 *	or phi actually move, and are used in conjunction
 *	with active_trans above.
 */

double	dtc_omega_value_saved;	/* value before a move */

/*
 *	detcon_make_header_smv  -  make a suitable SMV header.
 */

#define	SHDSIZE		20480

static	char	made_header[SHDSIZE];

detcon_make_header_smv()
  {
	char	buf[32];
	int	i;
	char	*cptr;
	char	*ztime();

	clrhd(made_header);

	/*
	 *	standard items.
	 */
	
	puthd("DIM","2",made_header);

#if defined(alpha) || defined(linux)
	puthd("BYTE_ORDER","little_endian",made_header);
#else
	puthd("BYTE_ORDER","big_endian",made_header);
#endif /* alpha */

	puthd("TYPE","unsigned_short",made_header);

	if(dtc_stat_bin == 1)
	  {
	    sprintf(buf,"%d",dtc_chip_size_x);
	    puthd("SIZE1",buf,made_header);
	    sprintf(buf,"%d",dtc_chip_size_y);
	    puthd("SIZE2",buf,made_header);
	    sprintf(buf,"%6.4f",dtc_pixel_size);
	    puthd("PIXEL_SIZE",buf,made_header);
	    puthd("BIN","none",made_header);
	  }
	 else
	  {
	    sprintf(buf,"%d",dtc_chip_size_x / 2);
	    puthd("SIZE1",buf,made_header);
	    sprintf(buf,"%d",dtc_chip_size_y / 2);
	    puthd("SIZE2",buf,made_header);
	    sprintf(buf,"%6.4f",dtc_pixel_size * 2);
	    puthd("PIXEL_SIZE",buf,made_header);
	    puthd("BIN","2x2",made_header);
	  }
	if(dtc_stat_adc == 0)
	    puthd("ADC","slow",made_header);
	  else
	    puthd("ADC","fast",made_header);
	if(0)
	{
	for(i = 0; i < dtc_n_ctrl; i++)
	  {
		sprintf(buf,"CCD_OFFSET%d",i);
		puthd(buf,"xx",made_header);
	  }
	}
	/*
	 *	adsc items.
	 */
	if(dtc_detector_sn > 0)
	  {
		sprintf(buf,"%d",dtc_detector_sn);
		puthd("DETECTOR_SN",buf,made_header);
	  }
	cptr = ztime();
	puthd("DATE",cptr,made_header);
	sprintf(buf,"%.2f",dtc_stat_time);
	puthd("TIME",buf,made_header);
	sprintf(buf,"%.3f",dtc_stat_dist);
	puthd("DISTANCE",buf,made_header);
	sprintf(buf,"%.3f",dtc_stat_osc_width);
	puthd("OSC_RANGE",buf,made_header);
	if(dtc_stat_axis == 1)
	  {
	    if(dtc_is_kappa)
	      {
		sprintf(buf,"%.3f",dtc_stat_phi);
		puthd("PHI",buf,made_header);
		puthd("OSC_START",buf,made_header);
		sprintf(buf,"%.3f",dtc_stat_omega);
		puthd("OMEGA",buf,made_header);
	        sprintf(buf,"%.3f",dtc_stat_kappa);
	        puthd("KAPPA",buf,made_header);
	      }
	     else
	      {
		sprintf(buf,"%.3f",dtc_stat_phi);
		puthd("PHI",buf,made_header);
		puthd("OSC_START",buf,made_header);
	      }
	  }
	 else
	  {
	    if(dtc_is_kappa)
	      {
		sprintf(buf,"%.3f",dtc_omega_value_saved);
		puthd("OMEGA",buf,made_header);
		puthd("OSC_START",buf,made_header);
		sprintf(buf,"%.3f",dtc_stat_phi);
		puthd("PHI",buf,made_header);
	        sprintf(buf,"%.3f",dtc_stat_kappa);
	        puthd("KAPPA",buf,made_header);
	      }
	     else
	      {
		sprintf(buf,"%.3f",dtc_stat_phi);
		puthd("PHI",buf,made_header);
		puthd("OSC_START",buf,made_header);
	      }
	  }
	if(dtc_is_2theta)
	  {
	    sprintf(buf,"%.3f",dtc_stat_2theta);
	    puthd("TWOTHETA",buf,made_header);
	  }
	if(dtc_stat_axis == 1)
	    puthd("AXIS","phi",made_header);
	  else
	    puthd("AXIS","omega",made_header);
	if(dtc_stat_wavelength == 0)
	  dtc_stat_wavelength = dtc_specific_wavelength;
	sprintf(buf,"%.4f",dtc_stat_wavelength);
	puthd("WAVELENGTH",buf,made_header);
	sprintf(buf,"%.3f",dtc_stat_xcen);
	puthd("BEAM_CENTER_X",buf,made_header);
	sprintf(buf,"%.3f",dtc_stat_ycen);
	puthd("BEAM_CENTER_Y",buf,made_header);
	padhd(made_header,512);
  }

/*
 *	Routine to record the number of msec during the exposure so
 *	that status calls can return the percentage complete.
 */

void	detcon_update_expos(msec)
int	msec;
  {
	double	x;

	dtc_expos_msec_ticks += msec;

	/*
	 *	As long as the state is exposing, continue updating.
	 */

	if(dtc_state == DTC_STATE_EXPOSING)
	  {
		x = ((double) msec + 1) / 1000.;
		enqueue_fcn(detcon_update_expos,msec,x);
	  }
  }

void	detcon_send_det_start_continue(val)
int	val;
  {
	int	i,ret;
	char	*ztime();

	if(0 == detcon_check_port_ready(dtc_fddetcmd))
	  {
		enqueue_fcn(detcon_send_det_start_continue,0,0.1);
		return;
	  }

	ret = detcon_output_detcmd_receive(dtc_fddetcmd);

	dtc_state = DTC_STATE_EXPOSING;

	if(ret != CCD_DET_OK)
	  {
		fprintf(stderr,"detcon_send_det_start_continue: Error returned\n");
		strcpy(dtc_status_string,"detcon_lib: ERROR returned from detector process");
		dtc_state = DTC_STATE_ERROR;
		return;
	  }
  }

/*
 *	Routine to send the start detector exposing command.  Main purpose
 *	here is to build up filenames.
 */

static	char	file_part1[256];
static	char	file_suffix[20];

detcon_send_det_start()
  {
	char	tempbuf[1024],tbuf[1024],infobuf[512];
	char	file_part2[256];
	char	im_3dig[4];
	int	hsize;
        int  	detret;
	double	tmp,first_delay;
	int	i,j,dark;

        if(dtc_fddetcmd == -1)
          {
                dtc_state = DTC_STATE_CONFIGDET;
                enqueue_fcn(detcon_send_det_start, 0, 1.0);     /* wait a second */
                return;
          }

        if(dtc_xfdatafd == -1)
          {
            dtc_state = DTC_STATE_CONFIGDET;
            detcon_output_detcmd(dtc_fddetcmd,"getparam\nxfdatafd\n",NULL,0);
            if(NULL != (char *) strstr(dtc_det_reply,"OK"))
                {
                    if('0' == dtc_det_reply[3])
                      {
                        enqueue_fcn(detcon_send_det_start,0,1.0);
                        return;
                      }
                    dtc_xfdatafd = 1;
                }
              else
                {
                        enqueue_fcn(detcon_send_det_start,0,1.0);
                        return;
                }
          }

	i = strlen(dtc_filename);
	strcpy(file_part1,dtc_filename);
	if(i > 4 && 0 == strcmp(dtc_default_suffix,&dtc_filename[i - 4]))
		file_part1[i-4] = '\0';
	i = strlen(file_part1);
	for(; i > 0; i--)
	  if(file_part1[i - 1] == '/')
		break;
	strcpy(file_part2,&file_part1[i]);

	switch(dtc_image_kind)
	  {
	    case KIND_DARK_0:
		strcpy(file_suffix,".dkx_0");
		dark = 1;
		break;
	    case KIND_DARK_1:
		strcpy(file_suffix,".dkx_1");
		dark = 1;
		break;
	    case KIND_DARK_2:
		strcpy(file_suffix,".dkx_2");
		dark = 1;
		break;
	    case KIND_DARK_3:
		strcpy(file_suffix,".dkx_3");
		dark = 1;
		break;
	    case KIND_RAW_0:
		strcpy(file_suffix,".imx_0");
		dark = 0;
		break;
	    case KIND_RAW_1:
		strcpy(file_suffix,".imx_1");
		dark = 0;
		break;
	  }
	if(dark == 1)
		strcpy(dtc_status_string,"Taking Dark Image");
	  else
		strcpy(dtc_status_string,"Taking Exposure");

	detcon_make_header_smv();
	gethdl(&hsize, made_header);

	sprintf(tempbuf,"start\nheader_size %d\n",hsize);

	sprintf(infobuf,"info %s%s\n",file_part2,file_suffix);

	sprintf(tbuf,"row_xfer %d\ncol_xfer %d\n",dtc_chip_size_x / dtc_stat_bin, dtc_chip_size_y / dtc_stat_bin);
	strcat(tempbuf, tbuf);

	if(dtc_use_pc_shutter)
	  {
	    if(dark)
	      strcat(tempbuf,"pcshutter 1\n");
	     else
	      strcat(tempbuf,"pcshutter 0\n");
	  }
	if(dtc_use_j5_trigger)
	      strcat(tempbuf,"j5_trigger 1\n");
	if(dtc_use_timecheck)
	      strcat(tempbuf,"timecheck 1\n");

	strcat(tempbuf,infobuf);
	sprintf(tbuf,"adc %d\nrow_bin %d\ncol_bin %d\ntime %f\n",dtc_stat_adc,dtc_stat_bin,dtc_stat_bin,dtc_stat_time);
	strcat(tempbuf,tbuf);
	if(dtc_modular)	/* for multiprocessor version */
	{
		sprintf(tbuf,"transform_image %d\nsave_raw %d\nimage_kind %d\n",
			!dtc_no_transform, dtc_output_raws, dtc_image_kind);
		strcat(tempbuf, tbuf);
	}

	detret = detcon_output_detcmd_issue(dtc_fddetcmd,tempbuf,made_header,hsize);

        first_delay = 0.1;

        dtc_state = DTC_STATE_CONFIGDET;
        enqueue_fcn(detcon_send_det_start_continue,0,first_delay);


        if (detret == CCD_DET_NOTCONNECTED) {
          dtc_dc_stop = 1;
	  dtc_state = DTC_STATE_ERROR;
	  strcpy(dtc_status_string,"Detector process NOT connected");
          set_alert_msg("ERROR: Detector control not connected.");
        }
  }

/*
 *	Routine to handle the checking of the detector read operation.
 */


void	detcon_send_det_stop_continue(val)
int	val;
  {
	int	i,ret;
	char	*ztime();

	if(0 == detcon_check_port_ready(dtc_fddetcmd))
	  {
		enqueue_fcn(detcon_send_det_stop_continue,0,0.1);
		return;
	  }

	ret = detcon_output_detcmd_receive(dtc_fddetcmd);

	if(ret != CCD_DET_OK)
	  {
	  	if(ret != CCD_DET_RETRY)
		{
		fprintf(stderr,"detcon_send_det_continue: FATAL ERROR returned\n");
		strcpy(dtc_status_string,"detcon_lib: ERROR (FATAL) returned from detector process");
		dtc_state = DTC_STATE_ERROR;
		return;
		}
		else
		{
		fprintf(stderr,"detcon_send_det_continue: RETRYABLE error signaled.\n");
		strcpy(dtc_status_string,"detcon_lib: RETRYABLE error from detector process");
		dtc_state = DTC_STATE_RETRY;
		return;
		}
	  }
	/*
 	 *	Handle "strip" readout for pedistal normalization.
	 */

	if(dtc_strip_ave)
	  {
		detcon_output_detcmd(dtc_fddetcmd,"getparam\nstrip_ave\n",NULL,0);
		if(NULL == (char *) strstr(dtc_det_reply,"OK"))
		    dtc_n_strip_ave = 0;
		  else
		    {
			dtc_n_strip_ave = sscanf(&dtc_det_reply[3],"%f %f %f %f",
				&dtc_strip_ave_vals[0],&dtc_strip_ave_vals[1],
				&dtc_strip_ave_vals[2],&dtc_strip_ave_vals[3]);
		    }
		fprintf(stdout,"output_detcmd: STRIPS        at %s: ",ztime());
		for(i = 0; i < dtc_n_strip_ave; i++)
		  fprintf(stdout,"%.3f ",dtc_strip_ave_vals[i]);
		fprintf(stdout,"\n");
		fflush(stdout);
	  }
	dtc_state = DTC_STATE_IDLE;
	strcpy(dtc_status_string,"Idle");
  }

detcon_send_det_stop()
  {
	float	first_delay;
	int	detret,i;
	char	*ztime();

	/*
	 *	Issue stop, return immediately.
	 */

	strcpy(dtc_status_string,"Reading Detector");
	detret = detcon_output_detcmd_issue(dtc_fddetcmd,"stop\n",NULL,0);

	if(detret != CCD_DET_OK)
	  {
	    strcpy(dtc_status_string,"detcon_send_det_stop: Detector process NOT connected");
	    dtc_state = DTC_STATE_ERROR;
	  }

	/*
	 *	Enqueue the checking function based on the amount of time we expect
	 *	the readout to take.
	 */

	if(dtc_stat_adc == 0 && dtc_stat_bin == 1)
	    first_delay = dtc_time_nobin_slow;
	  else
	    if(dtc_stat_adc == 0 && dtc_stat_bin == 2)
	      first_delay = dtc_time_bin_slow;
		else
		  if(dtc_stat_adc == 1 && dtc_stat_bin == 1)
		    first_delay = dtc_time_nobin_fast;
		      else
			first_delay = dtc_time_bin_fast;

	first_delay -= 0.2;

	dtc_state = DTC_STATE_READING;
	enqueue_fcn(detcon_send_det_stop_continue,0,first_delay);
  }

void	detcon_check_xform_return()
  {
	int	ret;

	if(dtc_fdxfcm == -1)
	  {
	        enqueue_fcn(detcon_check_xform_return,0,1.0);
                return;
          }

        if(0 == detcon_check_port_ready(dtc_fdxfcm))
          {
		enqueue_fcn(detcon_check_xform_return,0,1.0);
                return;
          }

        ret = detcon_output_xform_receive(dtc_fdxfcm);

        if(ret != CCD_DET_OK)
          {
                fprintf(stderr,"detcon_check_xform_return: Error returned\n");
                sprintf(dtc_status_string,"xform ERROR: %s",dtc_xform_reply);
		enqueue_fcn(detcon_check_xform_return,0,1.0);
                return;
          }

	enqueue_fcn(detcon_check_xform_return,0,1.0);
  }

detcon_send_copy_command()
  {
	int	len_xfcmd;
	char	xfcmd_buf[512];
        char    num[4];
        int     i,kind,raw_end;
	char	suffix[20],raw_suffix[20];
	char	body[512];
	char	dzstuff[100];
	int	hsize;
	int	xysize;

	gethdl(&hsize, made_header);

	xysize = dtc_chip_size_x / dtc_stat_bin;

	if(dtc_no_transform == 1)
	  sprintf(body,
 "copy\nreply 1\nrow_mm %f\ncol_mm %f\ndist_mm %f\ntwo_theta %f\nheader_size %d\nrow_xfer %d\ncol_xfer %d\nrow_bin %d\ncol_bin %d\n",
		dtc_stat_xcen,dtc_stat_ycen,dtc_stat_dist,dtc_stat_2theta,hsize,xysize,xysize,dtc_stat_bin,dtc_stat_bin);
	 else
	  sprintf(body,
 "xform\nreply 1\nrow_mm %f\ncol_mm %f\ndist_mm %f\ntwo_theta %f\nheader_size %d\nrow_xfer %d\ncol_xfer %d\nrow_bin %d\ncol_bin %d\n",
		dtc_stat_xcen,dtc_stat_ycen,dtc_stat_dist,dtc_stat_2theta,hsize,xysize,xysize,dtc_stat_bin,dtc_stat_bin);

	if(dtc_stat_compress == 1)
		strcat(body,"compress 1\n");
	    else
		strcat(body,"compress 0\n");
	if(dtc_detector_sn > 0)
	  {
		sprintf(dzstuff,"detector_sn %d\n",dtc_detector_sn);
		strcat(body,dzstuff);
	  }
	if(dtc_strip_ave)
	  {
		if(dtc_n_strip_ave == 4)
		  sprintf(dzstuff,"strip_ave %.3f_%.3f_%.3f_%.3f\n",dtc_strip_ave_vals[0],dtc_strip_ave_vals[1],
								    dtc_strip_ave_vals[2],dtc_strip_ave_vals[3]);
		 else
		  sprintf(dzstuff,"strip_ave %.3f\n",dtc_strip_ave_vals[0]);
		strcat(body,dzstuff);
	  }
	sprintf(dzstuff,"save_raw %d\n",dtc_output_raws);
	strcat(body,dzstuff);

	switch(dtc_image_kind)
	  {
	    case KIND_DARK_0:
		strcpy(suffix,".dkc");
		break;
	    case KIND_DARK_1:
		strcpy(suffix,".dkc");
		break;
	    case KIND_DARK_2:
		strcpy(suffix,".dkd");
		break;
	    case KIND_DARK_3:
		strcpy(suffix,".dkd");
		break;
	    case KIND_RAW_0:
		strcpy(suffix,dtc_default_suffix);
		break;
	    case KIND_RAW_1:
		strcpy(suffix,dtc_default_suffix);
		break;
	  }
	sprintf(dzstuff,"dzratio %f\n",dtc_stat_dzratio);
	strcat(body, dzstuff);

	sprintf(dzstuff,"outfile_type %d\n",dtc_outfile_type);
	strcat(body,dzstuff);

	if(-1 == dtc_fdxfcm)
	  {
		fprintf(stderr,"detcon_server: xform command file is NOT connected.\n");
		fprintf(stderr,"detcon_server: currently, THIS IS A WARNING\n");
	  }
	 else
	  {
		sprintf(xfcmd_buf,"%sinfile <socket>\noutfile %s%s\nrawfile %s%s\nkind %d\n",
			body,file_part1,suffix,file_part1,file_suffix,dtc_image_kind);
		strcat(xfcmd_buf,"end_of_det\n");
		len_xfcmd = strlen(xfcmd_buf);
		if(len_xfcmd != detcon_rep_write(dtc_fdxfcm,xfcmd_buf,len_xfcmd))
		  {
			fprintf(stderr,"detcon_server: xform process has disconnected.\n");
			fprintf(stderr,"detcon_server: currently, THIS IS A WARNING.\n");
			detcon_notify_server_eof(dtc_fdxfcm);
		  }
	  }
  }


detcon_ccd_hw_initial_status()
  {
	dtc_stat_start_phi = 0.;
	dtc_stat_start_omega = 0.;
	dtc_stat_start_kappa = 0.;
	dtc_stat_axis = 1;
	dtc_stat_osc_width = 1.0;
	dtc_stat_n_images = 1;
	dtc_stat_n_passes = 1;
	dtc_stat_n_ccd_updates = 0;
	dtc_stat_time = 30;
	dtc_stat_dir[0] = '\0';
	dtc_stat_fname[0] = '\0';
	strcpy(dtc_stat_scanner_op,"none");
	dtc_stat_scanner_msg[0] = '\0';
	strcpy(dtc_stat_scanner_control,"idle");
	strcpy(dtc_stat_scanner_shutter,"closed");
  }

