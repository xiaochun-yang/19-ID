#include	"ccd_bl_ext.h"
#include <math.h>

#define MIN_ION_READ	0.05
extern	int	light_curtain_hit_status;
extern  int	NOTCONNECTED;
extern	float	stat_wavelength;

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
	cm_getmotval();

	stat_axis = 0;

	//epics_get_wavelength();
  }

static	double	motion_increment;
static	double	unit_expos;
static	int	nupdate,nexpos,nstep;

int	ccd_bl_cm_expos()
  {
	int	i;
	int	nchecked;
	double	original_angle;

	if(stat_axis == 1)
		original_angle = stat_phi;
	    else
		original_angle = stat_omega;
	while(1)
	  {
	    sleep(2);
	    nupdate++;
	    i = 100 * (nupdate / ((double)(nexpos)));
	    stat_detector_percent_complete = i;
	    sprintf(stat_scanner_msg,"exposure %d%% complete",i);
	    if(stat_axis == 1)
	    	stat_phi += motion_increment;
	      else
		stat_omega += motion_increment;
	    send_status();
	    if(nupdate >= nexpos - 1)
	        break;
	  }

	nchecked = 0;
	while(0 == cm_dccheck())
		nchecked++;

	fprintf(stderr,"ccd_bl_cm_expos: nchecked: %d\n",nchecked);

	if(light_curtain_hit_status == 1)
	{
		strcpy(mdc_alert,"LIGHT SCREEN HIT DURING DATA COLLECITON\n");
	}

	/*
	 *	End of exposure processing.
	 */

	if(stat_axis == 1)
	  {
		stat_phi = original_angle + stat_osc_width;
		if(stat_phi >= 360)
			stat_phi -= 360;
	  }
	 else
	  {
		stat_omega = original_angle + stat_osc_width;
		if(stat_omega >= 360)
			stat_omega -= 360;
	  }

	cm_putmotval();
	strcpy(stat_scanner_shutter,"closed");
	strcpy(stat_scanner_op,"");
	strcpy(stat_scanner_control,"idle");
	return(1);
  }

ccd_bl_cm_dark()
  {
	int	i;

	while(1)
	  {
	    sleep(2);
	    nupdate++;
	    i = 100 * (nupdate / ((double)(nexpos)));
	    sprintf(stat_scanner_msg,"exposure %d%% complete",i);
	    stat_detector_percent_complete = i;
	    send_status();
	    if(nupdate >= nexpos)
	        break;
	  }

	/*
	 *	End of exposure processing.
	 */

	strcpy(stat_scanner_shutter,"closed");
	strcpy(stat_scanner_op,"");
	strcpy(stat_scanner_control,"idle");
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
	int	move_stat;
	double	x1,x2,x3;
	float	acopy[3];
	double	readback_slits[2];
	int	hslit_val;
	void	output_status();
	char	im_3dig[4];
	long	ccheck;
	double	ion_result;
	double	fabs();
	extern	int	cm_in_manual();
	double	cm_get_ion(int which);
	char	*ztime();

	dc_stat = 1;
	move_stat = 0;

	fprintf(stdout,"ccd_bl_x6a   : COMD:          at %s: command is: %s\n",
				ztime(), mdc_comlit[mdc_queue[next].cmd_no]);
	epics_get_wavelength();

	send_status();

	switch(mdc_queue[next].cmd_no)
	  {
	    case MDC_COM_PMOVE:
		strcpy(stat_scanner_op,"moving_phi_(absolute)");
		send_status();
		if(0 == (move_stat = cm_moveto("phi",mdc_queue[next].cmd_value,stat_phi)))
			stat_phi = mdc_queue[next].cmd_value;
		if(stat_phi >= 360.)
			stat_phi -= 360.;
		if(stat_phi < 0.)
			stat_phi += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		send_status();
		break;

	    case MDC_COM_OMOVE:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"moving_omega_(absolute)");
		send_status();
		if(0 == (move_stat = cm_moveto("omega",mdc_queue[next].cmd_value,stat_omega)))
			stat_omega = mdc_queue[next].cmd_value;
		if(stat_omega >= 360)
			stat_omega -= 360;
		if(stat_omega < 0)
			stat_omega += 360;

		strcpy(stat_scanner_op,"idle");
		send_status();
		cm_putmotval();
		break;

	    case MDC_COM_KMOVE:
		strcpy(stat_scanner_op,"moving_kappa_(absolute)");
		if(0 == (move_stat = cm_moveto("kappa",mdc_queue[next].cmd_value,stat_kappa)))
			stat_kappa = mdc_queue[next].cmd_value;
		if(stat_kappa >= 360.)
			stat_kappa -= 360.;
		if(stat_kappa < 0.)
			stat_kappa += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;

	    case MDC_COM_LMOVE:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"moving_2theta(absolute)");
		send_status();
		if(0 == (move_stat = cm_moveto("2theta",mdc_queue[next].cmd_value,stat_2theta)))
			stat_2theta = mdc_queue[next].cmd_value;
		if(stat_2theta >= 360.)
			stat_2theta -= 360.;
		if(stat_2theta < 0.)
			stat_2theta += 360.;
		strcpy(stat_scanner_op,"idle");
		send_status();
		cm_putmotval();
		break;

	    case MDC_COM_DMOVE:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"moving_distance_(absolute)");
		send_status();
		if(mdc_queue[next].cmd_value < dist_min_ref_point)
		  {
		    fprintf(stderr,"User value of %f is too small for distance.\n",mdc_queue[next].cmd_value);
		    break;
		  }
		if(mdc_queue[next].cmd_value > dist_max_ref_point)
		  {
		    fprintf(stderr,"User value of %f is too large for distance.\n",mdc_queue[next].cmd_value);
		    break;
		  }
		if(0 == (move_stat = cm_moveto("dist",mdc_queue[next].cmd_value,stat_dist)))
			stat_dist = mdc_queue[next].cmd_value;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		send_status();
		break;

	    case MDC_COM_PMOVEREL:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"moving_omega_(relative)");
		send_status();
		if(0 == (move_stat = cm_moveto("omega",stat_omega + mdc_queue[next].cmd_value,stat_omega)))
			stat_omega += mdc_queue[next].cmd_value;
		if(stat_omega >= 360.)
			stat_omega -= 360.;
		if(stat_omega < 0.)
			stat_omega += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		send_status();
		break;

	    case MDC_COM_OMOVEREL:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"moving_omega_(relative)");
		if(0 == (move_stat = cm_moveto("omega",stat_omega + mdc_queue[next].cmd_value,stat_omega)))
			stat_omega += mdc_queue[next].cmd_value;
		if(stat_omega >= 360.)
			stat_omega -= 360.;
		if(stat_omega < 0)
			stat_omega += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;

	    case MDC_COM_PSET:
		strcpy(stat_scanner_op,"setting_phi");
		send_status();
		stat_phi = mdc_queue[next].cmd_value;
		if(stat_phi >= 360.)
			stat_phi -= 360.;
		if(stat_phi < 0)
			stat_phi += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		send_status();
		break;

	    case MDC_COM_OSET:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"setting_omega");
		stat_omega = mdc_queue[next].cmd_value;
		if(stat_omega >= 360.)
			stat_omega -= 360.;
		if(stat_omega < 0)
			stat_omega += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_setomega(stat_omega);
		cm_putmotval();
		break;

	    case MDC_COM_WSET:
			strcpy(stat_scanner_op,"setting_wavelength");
			send_status();
			/* MA We are getting now the epics value so no need for the next line
			stat_wavelength = mdc_queue[next].cmd_value;
			*/

			epics_get_wavelength(); 
			strcpy(stat_scanner_op,"idle");
			cm_putmotval();
			send_status();
			break;

	    case MDC_COM_WMOVE:
			if(NOTCONNECTED==0)
			{
				strcpy(stat_scanner_op,"moving_wavelength");
				send_status();
				stat_wavelength = mdc_queue[next].cmd_value;
				epics_move_wavelength();
				strcpy(stat_scanner_op,"idle");
				cm_putmotval();
				send_status();
			}
			else
			{
				set_alert_msg("Unable to Connect to EPICS\n");
			}
			break;

	    case MDC_COM_BL_READY:
			strcpy(stat_scanner_op,"checking_beam_ready");
			send_status();
			ion_result = cm_get_ion(0);
			fprintf(stdout,"ccd_bl_x6a   : INFO:          at %s: bl_ready found ion reading: %.2f\n",
				ztime(), ion_result);
			if(ion_result >= MIN_ION_READ)
			{
				fprintf(stdout,"ccd_bl_x6a   : RSLT:          at %s: bl_ready says beam UP: %.2f\n",
				ztime());
				strcpy(local_reply_buf, "UP ");
			}
			else
			{
				fprintf(stdout,"ccd_bl_x6a   : RSLT:          at %s: bl_ready says beam DOWN: %.2f\n",
				ztime());
				strcpy(local_reply_buf, "DOWN ");
			}
			strcpy(stat_scanner_op,"idle");
			cm_putmotval();
			send_status();
			break;

	    case MDC_COM_KSET:
		strcpy(stat_scanner_op,"setting_kappa");
		stat_kappa = mdc_queue[next].cmd_value;
		if(stat_kappa >= 360.)
			stat_kappa -= 360.;
		if(stat_kappa < 0)
			stat_kappa += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;

	    case MDC_COM_LSET:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"setting_2theta");
		stat_2theta = mdc_queue[next].cmd_value;
		if(stat_2theta > 360.)
			stat_2theta -= 360.;
		if(stat_2theta < 0)
			stat_2theta += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_set2theta(stat_2theta);
		cm_putmotval();
		break;

	    case MDC_COM_DSET:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"setting_distance");
		send_status();
		if(mdc_queue[next].cmd_value < dist_min_ref_point)
		  {
		    fprintf(stderr,"User value of %f is too small for distance.\n",mdc_queue[next].cmd_value);
		    break;
		  }
		if(mdc_queue[next].cmd_value > dist_max_ref_point)
		  {
		    fprintf(stderr,"User value of %f is too large for distance.\n",mdc_queue[next].cmd_value);
		    break;
		  }
		stat_dist = mdc_queue[next].cmd_value;
		strcpy(stat_scanner_op,"idle");
		send_status();
		fprintf(stderr,"DSET: distance setting is to %f\n",stat_dist);
		cm_setdistance(stat_dist);
		cm_putmotval();
		break;

	    case MDC_COM_GONMAN:
		if(mdc_queue[next].cmd_value == 1)
		  {
		    strcpy(stat_scanner_op,"Goniostat_in_Manual_Mode");
		    if(!cm_in_manual())
		    	cm_manual(1);
		    break;
		  }
		if(mdc_queue[next].cmd_value == 0)
		  {
		    strcpy(stat_scanner_op,"idle");
		    cm_manual(0);
		    cm_putmotval();
		    break;
		  }
		break;
	    case MDC_COM_HOME:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"Init_Gonio_Motors");
		send_status();
		cm_home();
		strcpy(stat_scanner_op,"idle");
		send_status();
		cm_putmotval();
		break;
	    case MDC_COM_SHUT:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"Operating_shutter");
		state = mdc_queue[next].cmd_value;
		if(state == 1)
			strcpy(stat_scanner_shutter,"open");
		    else
			strcpy(stat_scanner_shutter,"closed");
		cm_shutter(state);
		strcpy(stat_scanner_op,"idle");
		break;

	    case MDC_COM_XL_HS_MOVE:
		strcpy(stat_scanner_op,"Moving_Horiz_Slits");
		cm_set_slit(0, mdc_queue[next].cmd_value);
		cm_get_slits(readback_slits);
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
		cm_set_slit(1, mdc_queue[next].cmd_value);
		cm_get_slits(readback_slits);
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
		cm_set_halfslit(0, 0, hslit_val);
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
		cm_set_halfslit(0, 1, hslit_val);
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
		cm_set_halfslit(1, 0, hslit_val);
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
		cm_set_halfslit(1, 1, hslit_val);
		stat_xl_dn_vhs = hslit_val;
		strcpy(stat_scanner_op,"idle");
		stat_onetime[MDC_COM_XL_DN_VHS_MOVE] = 1;
		break;

	    case MDC_COM_COLL:
		if(cm_in_manual())
			cm_manual(0);
		strcpy(stat_scanner_op,"exposing");
		strcpy(stat_scanner_msg,"exposure 0% complete");
		strcpy(stat_scanner_control,"active");
		nexpos = mdc_queue[next].cmd_col_time / 2;
		if(nexpos==0)
			nexpos=1;
		if(mdc_queue[next].cmd_col_osc_width > 0)
			motion_increment = mdc_queue[next].cmd_col_osc_width / nexpos;
		 else
			motion_increment = 0;
		if(mdc_queue[next].cmd_col_mode == 5)
			motion_increment = 0;
		stat_osc_width = mdc_queue[next].cmd_col_osc_width;
		unit_expos = 2.0;
		stat_time = mdc_queue[next].cmd_col_time;
		stat_adc = mdc_queue[next].cmd_col_adc;
		stat_bin = mdc_queue[next].cmd_col_bin;
		stat_axis = mdc_queue[next].cmd_col_axis;
		stat_start_omega = stat_omega;
		stat_start_kappa = stat_kappa;
		stat_start_phi = stat_phi;
		strcpy(stat_dir,mdc_queue[next].cmd_col_dir);
		util_3digit(im_3dig,mdc_queue[next].cmd_col_image_number);
		sprintf(stat_fname,"%s_%s.%s",mdc_queue[next].cmd_col_prefix,im_3dig,mdc_queue[next].cmd_col_suffix);
		nupdate = 0;
		if(mdc_queue[next].cmd_col_mode == 5)
		  {
		    strcpy(stat_scanner_op,"exposing_dark_current");
		    strcpy(stat_scanner_shutter,"closed");
		    ccd_bl_cm_dark();
		  }
		 else
		  {
		    if(stat_axis == 0)
		    	cm_dc("omega",stat_osc_width,stat_time);
		    else
		    	cm_dc("phi",stat_osc_width,stat_time);
		    strcpy(stat_scanner_op,"exposing");
		    strcpy(stat_scanner_shutter,"open");
		    ccd_bl_cm_expos();
		  }
		break;

	    default:
		break;
	  }
	send_status();
        fprintf(stdout,"ccd_bl_x6a   : INFO:          at %s: (o, p, k, d, 2th): (%.2f %.2f %.2f %.2f %.2f)\n",
                                ztime(), stat_omega, stat_phi, stat_dist, stat_2theta);

	if(move_stat == 1)
	{
		dc_stat = 0;
		cm_manual(0);
	}
	return(dc_stat);
  }
