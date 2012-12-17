#include	"ccd_bl_ext.h"

double  f100(a)
double  a;
  {
        double  crud;

        if(a < 0) crud = -.002;
                else
                  crud = .002;
        return(a/100. + crud);
  }

/*
 *	Initialize hardware, etc.
 */

ccd_bl_generic_init()
  {
	stat_phi = 0;
	stat_dist = 100;
	stat_axis = 1;
	stat_kappa = 0;
	stat_omega = 0;
  }

static	double	motion_increment;
static	double	unit_expos;
static	int	nupdate,nexpos,nstep;
static	int	waiting_state;

ccd_bl_generic_expos()
  {
	int	i;

	while(1)
	  {
	    usleep((int) (unit_expos * 1000000));
	    /*
 	     *	Check for abort.
	     */
	    if(probe_port_raw(fdcom))
	      {
		read_abort_command();
		goto finish_up_exposure;
	      }

	    nupdate++;
	    i = 100 * (nupdate / ((double)(nexpos)));
	    sprintf(stat_scanner_msg,"exposure %d%% complete",i);
	    if(stat_axis == 1)
	    	stat_phi += motion_increment;
	      else
		stat_omega += motion_increment;
	    send_status();
	    if(nupdate >= nexpos)
	        break;
	  }
	    
	/*
	 *	End of exposure processing.
	 */
finish_up_exposure:

	strcpy(stat_scanner_shutter,"closed");
	stat_scanner_op[0] = '\0';
	stat_scanner_msg[0] = '\0';
	strcpy(stat_scanner_control,"idle");
	waiting_state = 0;
	strcpy(stat_scanner_op,"idle");
  }

ccd_bl_generic_dark()
  {
	int	i;

	while(1)
	  {
	    usleep((int) (unit_expos * 1000000));
	    /*
 	     *	Check for abort.
	     */
	    if(probe_port_raw(fdcom))
	      {
		read_abort_command();
		goto finish_up_dark;
	      }
	    nupdate++;
	    i = 100 * (nupdate / ((double)(nexpos)));
	    sprintf(stat_scanner_msg,"exposure %d%% complete",i);
	    if(stat_axis == 1)
	    	stat_phi += motion_increment;
	      else
		stat_omega += motion_increment;
	    send_status();
	    if(nupdate >= nexpos)
	        break;
	  }
	    
	/*
	 *	End of exposure processing.
	 */
finish_up_dark:

	strcpy(stat_scanner_shutter,"closed");
	stat_scanner_op[0] = '\0';
	stat_scanner_msg[0] = '\0';
	strcpy(stat_scanner_control,"idle");
	waiting_state = 0;
	strcpy(stat_scanner_op,"idle");
  }

/*
 *	This executes a command.
 *
 *	Currently, the only commands recognized are:
 *
 *	    Shutter control
 *	    Phi control
 *	    Data collection.
 *
 *	All the others are ignored.
 */

int	ccd_bl_generic_cmd(next)
int	next;
  {
	int	state;
	double	x1,x2,x3;
	float	acopy[3];
	void	output_status();
	char	im_3dig[4];
	int	returned_status;
	int	hslit_val;
	FILE	*fp_bl_ready;

	returned_status = 0;		/* 0 will indicate OK, 1 retryable error, 2 FATAL error 
					 * Set the returned status to 1 or 2 in the individual case
					 * statement below when an error occurs 
					 */

	fprintf(stderr,"ccd_bl_gen: command: %s\n",mdc_comlit[mdc_queue[next].cmd_no]);
	switch(mdc_queue[next].cmd_no)
	  {
	    case MDC_COM_PMOVE:
		strcpy(stat_scanner_op,"moving_phi_(absolute)");
		stat_phi = mdc_queue[next].cmd_value;
		if(stat_phi > 360.)
			stat_phi -= 360.;
		if(stat_phi < -360.)
			stat_phi += 360.;
		strcpy(stat_scanner_op,"idle");
		break;

	    case MDC_COM_OMOVE:
		strcpy(stat_scanner_op,"moving_omega_(absolute)");
		stat_omega = mdc_queue[next].cmd_value;
		if(stat_omega > 360.)
			stat_omega -= 360.;
		if(stat_omega < -360.)
			stat_omega += 360.;
		strcpy(stat_scanner_op,"idle");
		break;

	    case MDC_COM_KMOVE:
		strcpy(stat_scanner_op,"moving_kappa_(absolute)");
		stat_kappa = mdc_queue[next].cmd_value;
		if(stat_omega > 360.)
			stat_kappa -= 360.;
		if(stat_kappa < -360.)
			stat_kappa += 360.;
		strcpy(stat_scanner_op,"idle");
		break;
	    case MDC_COM_WMOVE:
		strcpy(stat_scanner_op,"moving_wavelength");
		stat_wavelength = mdc_queue[next].cmd_value;
		fprintf(stdout,"\n\nccd_bl_gen: WAVELENGTH set to %8.4f\n\n\n",stat_wavelength);
		send_status();
		sleep(1);
		send_status();
		sleep(1);
		strcpy(stat_scanner_op,"idle");
		break;

	    case MDC_COM_DMOVE:
		strcpy(stat_scanner_op,"moving_distance_(absolute)");
		stat_dist = mdc_queue[next].cmd_value;
		strcpy(stat_scanner_op,"idle");
		break;

	    case MDC_COM_PMOVEREL:
		strcpy(stat_scanner_op,"moving_phi_(relative)");
		stat_phi += mdc_queue[next].cmd_value;
		if(stat_phi > 360.)
			stat_phi -= 360.;
		if(stat_phi < -360.)
			stat_phi += 360.;
		strcpy(stat_scanner_op,"idle");
		break;

	    case MDC_COM_OMOVEREL:
		strcpy(stat_scanner_op,"moving_omega_(relative)");
		stat_omega += mdc_queue[next].cmd_value;
		if(stat_omega > 360.)
			stat_omega -= 360.;
		if(stat_omega < -360.)
			stat_omega += 360.;
		strcpy(stat_scanner_op,"idle");
		break;
	    case MDC_COM_PSET:
		strcpy(stat_scanner_op,"setting_phi");
		stat_phi = mdc_queue[next].cmd_value;
		if(stat_phi > 360.)
			stat_phi -= 360.;
		if(stat_phi < -360.)
			stat_phi += 360.;
		strcpy(stat_scanner_op,"idle");
		returned_status = 2;
		strcpy(mdc_alert,"It is not allowed to set PHI\n");
		break;

	    case MDC_COM_OSET:
		strcpy(stat_scanner_op,"setting_omega");
		stat_omega = mdc_queue[next].cmd_value;
		if(stat_omega > 360.)
			stat_omega -= 360.;
		if(stat_phi < -360.)
			stat_omega += 360.;
		strcpy(stat_scanner_op,"idle");
		break;

	    case MDC_COM_KSET:
		strcpy(stat_scanner_op,"setting_kappa");
		stat_kappa = mdc_queue[next].cmd_value;
		if(stat_kappa > 360.)
			stat_kappa -= 360.;
		if(stat_kappa < -360.)
			stat_kappa += 360.;
		strcpy(stat_scanner_op,"idle");
		break;

	    case MDC_COM_SHUT:
		strcpy(stat_scanner_op,"Operating_shutter");
		state = mdc_queue[next].cmd_value;
		if(state == 1)
			strcpy(stat_scanner_shutter,"open");
		    else
			strcpy(stat_scanner_shutter,"closed");
		strcpy(stat_scanner_op,"idle");
		break;

	    case MDC_COM_BL_READY:
		if(NULL != (fp_bl_ready = fopen("beam_down", "r")))
		{
			fclose(fp_bl_ready);
			strcpy(bl_returned_string, "DOWN");
			strcpy(stat_scanner_op,"Holding_on_beam_down");
		}
		else
		{
			strcpy(bl_returned_string, "UP");
			strcpy(stat_scanner_op,"idle");
		}
		break;

		case MDC_COM_ATTENUATE:
			break;
		case MDC_COM_AUTOALIGN:
			break;
		case MDC_COM_SET_MASTER:
			break;
		case MDC_COM_GET_CLIENTS:
			break;
		case MDC_COM_EXPERIMENT_MODE_MOVE:
			break;
		case MDC_COM_HSLIT:
			break;
		case MDC_COM_VSLIT:
			break;
	    case MDC_COM_XL_HS_MOVE:
		strcpy(stat_scanner_op,"Moving_Horiz_Slits");
		stat_xl_hslit = mdc_queue[next].cmd_value;
		strcpy(stat_scanner_op,"idle");
		stat_onetime[MDC_COM_XL_HS_MOVE] = 1;
		send_status();
		sleep(1);
		send_status();
		sleep(1);
		send_status();
		stat_onetime[MDC_COM_XL_HS_MOVE] = 0;
		break;
	    case MDC_COM_XL_VS_MOVE:
		strcpy(stat_scanner_op,"Moving_Vert_Slits");
		stat_xl_vslit = mdc_queue[next].cmd_value;
		strcpy(stat_scanner_op,"idle");
		stat_onetime[MDC_COM_XL_VS_MOVE] = 1;
		send_status();
		sleep(1);
		send_status();
		sleep(1);
		send_status();
		stat_onetime[MDC_COM_XL_VS_MOVE] = 0;
		break;
	    case MDC_COM_XL_UP_HHS_MOVE:
		if(mdc_queue[next].cmd_value > 0)
			hslit_val = 1;
		else
			hslit_val = 0;
		strcpy(stat_scanner_op,"Moving_Up_Horiz_Halfslit");
		stat_xl_up_hhs = hslit_val;
		strcpy(stat_scanner_op,"idle");
		stat_onetime[MDC_COM_XL_UP_HHS_MOVE] = 1;
		break;
	    case MDC_COM_XL_UP_VHS_MOVE:
		if(mdc_queue[next].cmd_value > 0)
			hslit_val = 1;
		else
			hslit_val = 0;
		strcpy(stat_scanner_op,"Moving_Up_Vert_Halfslit");
		stat_xl_up_vhs = hslit_val;
		strcpy(stat_scanner_op,"idle");
		stat_onetime[MDC_COM_XL_UP_VHS_MOVE] = 1;
		break;
	    case MDC_COM_XL_DN_HHS_MOVE:
		if(mdc_queue[next].cmd_value > 0)
			hslit_val = 1;
		else
			hslit_val = 0;
		strcpy(stat_scanner_op,"Moving_Dn_Horiz_Halfslit");
		stat_xl_dn_hhs = hslit_val;
		strcpy(stat_scanner_op,"idle");
		stat_onetime[MDC_COM_XL_DN_HHS_MOVE] = 1;
		break;
	    case MDC_COM_XL_DN_VHS_MOVE:
		if(mdc_queue[next].cmd_value > 0)
			hslit_val = 1;
		else
			hslit_val = 0;
		strcpy(stat_scanner_op,"Moving_Dn_Vert_Halfslit");
		stat_xl_dn_vhs = hslit_val;
		strcpy(stat_scanner_op,"idle");
		stat_onetime[MDC_COM_XL_DN_VHS_MOVE] = 1;
		break;
	    case MDC_COM_COLL:
		strcpy(stat_scanner_op,"exposing");
		strcpy(stat_scanner_msg,"exposure 0% complete");
		strcpy(stat_scanner_control,"active");
		unit_expos = 0.2;
		nexpos = (mdc_queue[next].cmd_col_time + .1) / unit_expos;
		if(nexpos == 0)
			nexpos = 1;
		if(mdc_queue[next].cmd_col_osc_width > 0)
			motion_increment = mdc_queue[next].cmd_col_osc_width / nexpos;
		 else
			motion_increment = 0;
		if(mdc_queue[next].cmd_col_mode == 5)
			motion_increment = 0;
		stat_osc_width = mdc_queue[next].cmd_col_osc_width;
		strcpy(stat_scanner_shutter,"open");
		stat_time = mdc_queue[next].cmd_col_time;
		stat_adc = mdc_queue[next].cmd_col_adc;
		stat_bin = mdc_queue[next].cmd_col_bin;
		stat_axis = mdc_queue[next].cmd_col_axis;
		stat_start_omega = stat_omega;
		stat_start_kappa = stat_kappa;
		strcpy(stat_dir,mdc_queue[next].cmd_col_dir);
		util_3digit(im_3dig,mdc_queue[next].cmd_col_image_number);
		sprintf(stat_fname,"%s_%s.%s",mdc_queue[next].cmd_col_prefix,im_3dig,mdc_queue[next].cmd_col_suffix);
		nupdate = 0;
		waiting_state = 1;
                if(mdc_queue[next].cmd_col_mode == 5)
                {
                    strcpy(stat_scanner_op,"exposing_dark_current");
                    strcpy(stat_scanner_shutter,"closed");
		    ccd_bl_generic_dark();
                }
                else if(mdc_queue[next].cmd_col_mode == 6)
		{
		    if(stat_axis == 1)
			stat_phi = mdc_queue[next].cmd_col_phis;
		    else
			stat_omega = mdc_queue[next].cmd_col_omegas;
                    strcpy(stat_scanner_op,"exposing");
                    strcpy(stat_scanner_shutter,"open");
		    ccd_bl_generic_expos();
		}
		else
                {
                    strcpy(stat_scanner_op,"exposing");
                    strcpy(stat_scanner_shutter,"open");
		    ccd_bl_generic_expos();
                }
		break;

	    default:
		break;
	  }
	return(returned_status);
  }

/*
 *	This function gets called when an abort is see WHILE
 *	an operation is in progress.
 */

abort_abortable_operations()
  {
  }
