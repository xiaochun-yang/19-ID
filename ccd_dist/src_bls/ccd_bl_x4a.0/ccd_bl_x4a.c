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

void	ccd_bl_generic_init()
{
	void	cm_getmotval_gonio(int silent);

	cm_getmotval_gonio(0);

	stat_axis = 0;
}

static	double	motion_increment;
static	double	unit_expos;
static	int	nupdate,nexpos,nstep;

ccd_bl_cm_expos_old()
  {
	int	i;
	int	nchecked;
	double	original_angle;

	if(stat_axis == 1)
		original_angle = stat_omega;
	    else
		original_angle = stat_omega;
	while(1)
	  {
	    Sleep(2000);
	    nupdate++;
	    i = (int) (100 * (nupdate / ((double)(nexpos))));
	    stat_detector_percent_complete = i;
	    sprintf(stat_scanner_msg,"exposure %d%% complete",i);
	    if(stat_axis == 1)
	    	stat_omega += (float) motion_increment;
	      else
		stat_omega += (float) motion_increment;
	    send_status();
	    if(nupdate >= nexpos - 1)
	        break;
	  }

	nchecked = 0;
	while(0 == cm_dccheck())
		nchecked++;

	fprintf(stderr,"ccd_bl_cm_expos: nchecked: %d\n",nchecked);

	/*
	 *	End of exposure processing.
	 */

	if(stat_axis == 1)
	  {
		stat_omega = (float) (original_angle + stat_osc_width);
		if(stat_omega >= 360)
			stat_omega -= 360;
	  }
	 else
	  {
		stat_omega = (float) (original_angle + stat_osc_width);
		if(stat_omega >= 360)
			stat_omega -= 360;
	  }

	cm_putmotval();
	strcpy(stat_scanner_shutter,"closed");
	strcpy(stat_scanner_op,"");
	strcpy(stat_scanner_control,"idle");
  }

ccd_bl_cm_dark_old()
  {
	int	i;

	while(1)
	  {
	    Sleep(2000);
	    nupdate++;
	    i = (int) (100 * (nupdate / ((double)(nexpos))));
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

ccd_bl_cm_expos(double actual_time)
{
	int	i, done, res, nchecked;
	double	remaining_exposure, this_time;
	struct	timespec	req, rem;
	double	original_angle;

	fprintf(stdout,"ccd_bl_cm_expos: actual_time: %.2f unit_expos: %.2f nexpos: %d\n", 
		actual_time, unit_expos, nexpos);
	remaining_exposure = actual_time;

	if(stat_axis == 1)
		original_angle = stat_omega;
	    else
		original_angle = stat_omega;

	while(1)
	{
	    if(fabs(remaining_exposure) < 0.01)
		break;
	    if(remaining_exposure >= unit_expos)
		this_time = unit_expos;
	    else
		this_time = remaining_exposure;
	    req.tv_sec = (int) this_time;
	    this_time = this_time - (double) req.tv_sec;
	    if(this_time <= 0)
		req.tv_nsec = 0;
	    else
		req.tv_nsec = (long) (this_time * 1000000000);
	    if(req.tv_nsec > 999999999)
		req.tv_nsec = 999999999;
	    while(1)
	    {
		res = nanosleep(&req, &rem);
		if(res == -1)
		{
		    if(errno == EINTR)
		    {
			req = rem;
			continue;
		    }
		}
		break;
	    }
	    if(stat_axis == 1)
	    	stat_omega += motion_increment;
	      else
		stat_omega += motion_increment;
	    remaining_exposure -= this_time;
	    nupdate++;
	    i = 100 * (nupdate / ((double)(nexpos)));
	    sprintf(stat_scanner_msg,"exposure %d%% complete",i);
	    stat_detector_percent_complete = i;
	    send_status();
	    if(nupdate >= nexpos - 1)
	        break;
	}

	nchecked = 0;
	while(0 == cm_dccheck())
		nchecked++;

	fprintf(stderr,"ccd_bl_cm_expos: nchecked: %d\n",nchecked);

	/*
	 *	End of exposure processing.
	 */

	if(stat_axis == 1)
	  {
		stat_omega = original_angle + stat_osc_width;
		if(stat_omega >= 360)
			stat_omega -= 360;
	  }
	 else
	  {
		stat_omega = original_angle + stat_osc_width;
		if(stat_omega >= 360)
			stat_omega -= 360;
	  }

	strcpy(stat_scanner_shutter,"closed");
	strcpy(stat_scanner_op,"");
	strcpy(stat_scanner_control,"idle");
}

ccd_bl_cm_dark(double actual_time)
{
	int	i, done, res;
	double	remaining_exposure, this_time;
	struct	timespec	req, rem;

	fprintf(stdout,"ccd_bl_cm_dark: actual_time: %.2f unit_expos: %.2f nexpos: %d\n", 
		actual_time, unit_expos, nexpos);
	remaining_exposure = actual_time;
	while(1)
	  {
	    if(fabs(remaining_exposure) < 0.01)
		break;
	    if(remaining_exposure >= unit_expos)
		this_time = unit_expos;
	    else
		this_time = remaining_exposure;
	    req.tv_sec = (int) this_time;
	    this_time = this_time - (double) req.tv_sec;
	    if(this_time <= 0)
		req.tv_nsec = 0;
	    else
		req.tv_nsec = (long) (this_time * 1000000000);
	    if(req.tv_nsec > 999999999)
		req.tv_nsec = 999999999;
	    while(1)
	    {
		res = nanosleep(&req, &rem);
		if(res == -1)
		{
		    if(errno == EINTR)
		    {
			req = rem;
			continue;
		    }
		}
		break;
	    }
	    remaining_exposure -= this_time;
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

#define   EV_ANGSTROM     (12398.4243)

int	send_wavelength_request_to_control(double *wp, char *err_msg)
{
	int	fd;
	int	buflen;
	char	buf[100];
	char	*cp, *cp2;
	float	new_energy, new_wavelength;

	*err_msg = '\0';

	if(local_control_port == -1)
		return(-1);

	if(-1 == (fd = connect_to_host_api(&fd, local_control_host, local_control_port, NULL)))
		return(-1);

	new_energy = EV_ANGSTROM / *wp;
	sprintf(buf, "moveenergy %.3f 1\n", new_energy);
	buflen = strlen(buf);
	if(-1 == rep_write(fd, buf, buflen))
	{
		close(fd);
		return(-1);
	}
	if(0 >= read_until(fd, buf, sizeof buf, "done"))
	{
		close(fd);
		return(-1);
	}
	if(NULL == (cp = strstr(buf, "error")))
	{
		sscanf(buf, "%f", &new_energy);
		new_wavelength = EV_ANGSTROM / new_energy;
		*wp = new_wavelength;
		close(fd);
		return(0);
	}
	fprintf(stderr,"send_wavelength_request_to_control: Error setting wavelength: buf: %s\n", buf);
	close(fd);
	return(-1);
}

int	get_current_wavelength_from_control(double *wp)
{
	int	fd;
	int	buflen;
	char	buf[100];
	char	*cp;
	float	new_energy, new_wavelength;

	if(local_control_port == -1)
		return(-1);

	if(-1 == (fd = connect_to_host_api(&fd, local_control_host, local_control_port, NULL)))
	{
		fprintf(stderr,"get_current_wavelength_from_control: connection to host %s port %d was refused\n",
			local_control_host, local_control_port);
		perror("get_current_wavelength_from_control");
		return(-1);
	}

	sprintf(buf, "getenergy\n");
	buflen = strlen(buf);
	if(-1 == rep_write(fd, buf, buflen))
	{
		close(fd);
		return(-1);
	}
	if(0 >= read_until(fd, buf, sizeof buf, "done"))
	{
		close(fd);
		return(-1);
	}
	if(NULL == (cp = strstr(buf, "error")))
	{
		sscanf(buf, "%f", &new_energy);
		new_wavelength = EV_ANGSTROM / new_energy;
		*wp = new_wavelength;
		fprintf(stderr,"get_current_wavelength_from_control: got wavelength: %.6f\n", new_wavelength);
		close(fd);
		return(0);
	}
	fprintf(stderr,"get_current_wavelength_from_control: Error setting wavelength: buf: %s\n", buf);
	close(fd);
	return(-1);
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

int		ccd_bl_generic_cmd(int next)
{
	double	wavelength_temp;

	int	state;
	double	time_used;
	void	output_status();
	int 	cm_sync();
	char	im_3dig[4];
	int 	time_cmd_start, time_cmd_end;
	double	time_cmd;
	int	hslit_val;
	char	err_msg[100], err_msg_buf[120];
	extern	int	in_manual;
	void	cm_get_goniostat_values();
	void	cm_get_specific_goniostat_value(char *which);
	void	scan_for_abort();
	void	stop_abort_thread();
	int 	abortable_command();

	returned_to_user[0] == '\0';

	if(0)
		fprintf(stderr,"ccd_bl_x4a: command_number: %d command: %s\n",
				mdc_queue[next].cmd_no, mdc_comlit[mdc_queue[next].cmd_no]);

	if(in_manual)
		cm_manual(0);

	time_cmd_start = timeGetTime();

	command_in_progress = mdc_queue[next].cmd_no;
	abort_asserted = 0;
	if(abortable_command(command_in_progress))
	{
		scan_for_abort();
	}

	/*
	 *	Drain all input in the goniostat tty device before executing a command.
	 */

	while(-1 != cmreadraw_drain(20));

	if(mdc_queue[next].cmd_no == MDC_COM_COLL)
		ion_check_interval = 4000000;	
	else
		ion_check_interval = 2000000;	
	
	switch(mdc_queue[next].cmd_no)
	  {
	    case MDC_COM_PMOVE:
		strcpy(stat_scanner_op,"moving_omega_(absolute)");
		send_status();
		if(0 == cm_moveto("omega",mdc_queue[next].cmd_value,stat_omega))
			stat_omega = mdc_queue[next].cmd_value;
		if(stat_omega >= 360.)
			stat_omega -= 360.;
		if(stat_omega < 0.)
			stat_omega += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		send_status();
		break;

	    case MDC_COM_OMOVE:
		strcpy(stat_scanner_op,"moving_omega_(absolute)");
		send_status();
		if(0 == cm_moveto("omega",mdc_queue[next].cmd_value,stat_omega))
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
		if(0 == cm_moveto("kappa",mdc_queue[next].cmd_value,stat_kappa))
			stat_kappa = mdc_queue[next].cmd_value;
		if(stat_kappa >= 360.)
			stat_kappa -= 360.;
		if(stat_kappa < 0.)
			stat_kappa += 360.;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;

	    case MDC_COM_LMOVE:
		strcpy(stat_scanner_op,"moving_2theta(absolute)");
		send_status();
		if(0 == cm_moveto("2theta",mdc_queue[next].cmd_value,stat_2theta))
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
		strcpy(stat_scanner_op,"moving_distance_(absolute)");
		send_status();
		if(mdc_queue[next].cmd_value < near_limit_value)
		  {
		    fprintf(stderr,"User value of %f is too small for distance.\n",mdc_queue[next].cmd_value);
		    break;
		  }
		if(mdc_queue[next].cmd_value > far_limit_value)
		  {
		    fprintf(stderr,"User value of %f is too large for distance.\n",mdc_queue[next].cmd_value);
		    break;
		  }
		if(0 == cm_moveto("dist",mdc_queue[next].cmd_value,stat_dist))
			stat_dist = mdc_queue[next].cmd_value;
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		send_status();
		break;

	    case MDC_COM_PMOVEREL:
		strcpy(stat_scanner_op,"moving_omega_(relative)");
		send_status();
		if(0 == cm_moveto("omega",stat_omega + mdc_queue[next].cmd_value,stat_omega))
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
		strcpy(stat_scanner_op,"moving_omega_(relative)");
		if(0 == cm_moveto("omega",stat_omega + mdc_queue[next].cmd_value,stat_omega))
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
	    case MDC_COM_WMOVE:
		strcpy(stat_scanner_op,"moving_wavelength");
		send_status();
		wavelength_temp = mdc_queue[next].cmd_value;
		if(local_control_port != -1)
		{
			if(send_wavelength_request_to_control(&wavelength_temp, err_msg))
			{
				sprintf(err_msg_buf, "ERROR MOVING WAVELENGTH: %s", err_msg);
				set_alert_msg(err_msg_buf);
			}
		}
		stat_wavelength = (float) wavelength_temp;
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
		strcpy(stat_scanner_op,"setting_distance");
		send_status();
		if(mdc_queue[next].cmd_value < near_limit_value)
		  {
		    fprintf(stderr,"User value of %f is too small for distance.\n",mdc_queue[next].cmd_value);
		    break;
		  }
		if(mdc_queue[next].cmd_value > far_limit_value)
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
		    cm_manual(1);
		    break;
		  }
		if(mdc_queue[next].cmd_value == 0)
		  {
		    strcpy(stat_scanner_op,"idle");
		    cm_manual(0);
		    break;
		  }
		break;
	    case MDC_COM_HOME:
		set_alert_msg("Please HOME the goniostat in the HUTCH manually.");
		strcpy(stat_scanner_op,"idle");
		break;
	    case MDC_COM_DHOME:
		strcpy(stat_scanner_op,"Initializing_Goniostat_Distance");
		cm_dhome();
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;
	    case MDC_COM_OHOME:
		strcpy(stat_scanner_op,"Initializing_Goniostat_Omega");
		cm_ohome();
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;
	    case MDC_COM_THHOME:
		strcpy(stat_scanner_op,"Initializing_Goniostat_2Theta");
		cm_thhome();
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;
	    case MDC_COM_ZHOME:
		strcpy(stat_scanner_op,"Initializing_Goniostat_Z_Trans");
		cm_zhome();
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;
	    case MDC_COM_MZ:
		strcpy(stat_scanner_op,"Moving_Z_Translation");
		stat_z = (float) cm_mz(mdc_queue[next].cmd_value, stat_z);
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;

		case MDC_COM_RETURN_DIST:
			cm_get_specific_goniostat_value("dist");
			sprintf(returned_to_user, "%.3f ", stat_dist);
			break;
		case MDC_COM_RETURN_OMEGA:
			cm_get_specific_goniostat_value("omega");
			sprintf(returned_to_user, "%.3f ", stat_omega);
			break;
		case MDC_COM_RETURN_2THETA:
			sprintf(returned_to_user, "%.3f ", stat_2theta);
			break;
		case MDC_COM_RETURN_Z:
			cm_get_specific_goniostat_value("z");
			sprintf(returned_to_user, "%.5f", stat_z);
			break;
		case MDC_COM_RETURN_ALL:
			cm_get_goniostat_values();
			sprintf(returned_to_user, "%.3f %.3f %.3f %.5f ", stat_dist, stat_omega, stat_2theta, stat_z);
			break;

	    case MDC_COM_SYNC:
		strcpy(stat_scanner_op,"Sync_Compumotor_Interface");
		cm_sync();
		strcpy(stat_scanner_op,"idle");
		cm_putmotval();
		break;
		case MDC_COM_GETGON:
			cm_get_goniostat_values();
			break;

	    case MDC_COM_STAT:
		strcpy(stat_scanner_op,"Toggle_status_output");
		state = (int) mdc_queue[next].cmd_value;
		if(state == 1)
			stat_stat = 1;
		else
			stat_stat = 0;
		strcpy(stat_scanner_op,"idle");
		break;
	    case MDC_COM_SHUT:
		strcpy(stat_scanner_op,"Operating_shutter");
		state = (int) mdc_queue[next].cmd_value;
		if(state == 1)
			strcpy(stat_scanner_shutter,"open");
		else
			strcpy(stat_scanner_shutter,"closed");
		cm_shutter(state);
		strcpy(stat_scanner_op,"idle");
		break;

		case MDC_COM_ABORT:
			fprintf(stdout,"Abort command received through normal command interface\n");
			break;

	    case MDC_COM_XL_HS_MOVE:
		strcpy(stat_scanner_op,"Moving_Horiz_Slits");
		send_status();
		cm_set_slit(2, mdc_queue[next].cmd_value);
		cm_get_slits();
		strcpy(stat_scanner_op,"idle");
		send_status();
		break;
	    case MDC_COM_XL_VS_MOVE:
		strcpy(stat_scanner_op,"Moving_Vert_Slits");
		send_status();
		cm_set_slit(3, mdc_queue[next].cmd_value);
		cm_get_slits();
		strcpy(stat_scanner_op,"idle");
		send_status();
		break;
	    case MDC_COM_XL_GUARD_HS_MOVE:
		strcpy(stat_scanner_op,"Moving_Horiz_Guard_Slits");
		send_status();
		cm_set_slit(2, mdc_queue[next].cmd_value);
		cm_get_slits();
		strcpy(stat_scanner_op,"idle");
		send_status();
		break;
	    case MDC_COM_XL_GUARD_VS_MOVE:
		strcpy(stat_scanner_op,"Moving_Vert_Guard_Slits");
		send_status();
		cm_set_slit(3, mdc_queue[next].cmd_value);
		cm_get_slits();
		strcpy(stat_scanner_op,"idle");
		send_status();
		break;
	    case MDC_COM_XL_UP_HHS_MOVE:
		if(mdc_queue[next].cmd_value > 0)
			hslit_val = 1;
		else
			hslit_val = 0;
		strcpy(stat_scanner_op,"Moving_Up_Horiz_Halfslit");
		send_status();
		cm_set_halfslit(0, 0, hslit_val);
		stat_xl_up_hhs = hslit_val;
		strcpy(stat_scanner_op,"idle");
		send_status();
		break;
	    case MDC_COM_XL_UP_VHS_MOVE:
		if(mdc_queue[next].cmd_value > 0)
			hslit_val = 1;
		else
			hslit_val = 0;
		strcpy(stat_scanner_op,"Moving_Up_Vert_Halfslit");
		send_status();
		cm_set_halfslit(0, 1, hslit_val);
		stat_xl_up_vhs = hslit_val;
		strcpy(stat_scanner_op,"idle");
		send_status();
		break;
	    case MDC_COM_XL_DN_HHS_MOVE:
		if(mdc_queue[next].cmd_value > 0)
			hslit_val = 1;
		else
			hslit_val = 0;
		strcpy(stat_scanner_op,"Moving_Dn_Horiz_Halfslit");
		send_status();
		cm_set_halfslit(1, 0, hslit_val);
		stat_xl_dn_hhs = hslit_val;
		strcpy(stat_scanner_op,"idle");
		send_status();
		break;
	    case MDC_COM_XL_DN_VHS_MOVE:
		if(mdc_queue[next].cmd_value > 0)
			hslit_val = 1;
		else
			hslit_val = 0;
		strcpy(stat_scanner_op,"Moving_Dn_Vert_Halfslit");
		send_status();
		cm_set_halfslit(1, 1, hslit_val);
		stat_xl_dn_vhs = hslit_val;
		strcpy(stat_scanner_op,"idle");
		send_status();
		break;

	    case MDC_COM_GET_WAVELENGTH:
		strcpy(stat_scanner_op,"Getting_Wavelength");
		send_status();

		if(local_control_port != -1)
		{
			double wavelength_temp;

			if(0 == get_current_wavelength_from_control(&wavelength_temp))
				stat_wavelength = wavelength_temp;
			sprintf(returned_to_user, "%.6f", stat_wavelength);
		}

		strcpy(stat_scanner_op,"idle");
		send_status();
		sleep(1);
		break;

	    case MDC_COM_COLL:

		time_used = mdc_queue[next].cmd_col_time;
		stat_time = (float) time_used;
		strcpy(stat_scanner_msg,"exposure 0% complete");
		strcpy(stat_scanner_control,"active");
		unit_expos = 0.25;
		nexpos = (int) time_used / unit_expos;
		if(nexpos == 0)
			nexpos = 1;
		if(mdc_queue[next].cmd_col_osc_width > 0)
			motion_increment = mdc_queue[next].cmd_col_osc_width / nexpos;
		 else
			motion_increment = 0;
		if(mdc_queue[next].cmd_col_mode == 5)
			motion_increment = 0;
		stat_osc_width = mdc_queue[next].cmd_col_osc_width;
		stat_adc = mdc_queue[next].cmd_col_adc;
		stat_bin = mdc_queue[next].cmd_col_bin;
		stat_axis = mdc_queue[next].cmd_col_axis;
		stat_start_omega = stat_omega;
		stat_start_kappa = stat_kappa;
		strcpy(stat_dir,mdc_queue[next].cmd_col_dir);
		util_3digit(im_3dig,mdc_queue[next].cmd_col_image_number);
		sprintf(stat_fname,"%s_%s.%s",mdc_queue[next].cmd_col_prefix,im_3dig,mdc_queue[next].cmd_col_suffix);
		nupdate = 0;
		if(mdc_queue[next].cmd_col_mode == 5)
		  {
		    strcpy(stat_scanner_op,"exposing_dark_current");
		    strcpy(stat_scanner_shutter,"closed");
		    ccd_bl_cm_dark(stat_time);
		  }
		 else
		  {
		    if(stat_axis == 1)
			cm_dc("omega",stat_osc_width,time_used);
		      else
			cm_dc("omega",stat_osc_width,time_used);
		    strcpy(stat_scanner_op,"exposing");
		    strcpy(stat_scanner_shutter,"open");
		    ccd_bl_cm_expos(stat_time);
		  }
		break;

	    default:
		break;
	}
	time_cmd_end = timeGetTime();
	time_cmd = (time_cmd_end - time_cmd_start) / 1000.;

	fprintf(stderr,
		"ccd_bl_cm: (info) (om,dist,2th,z): (%8.3f,%8.2f,%8.2f, %6.3f) (%8.3f msec)\n",
				stat_omega,stat_dist,stat_2theta, stat_z, time_cmd);

	if(mdc_queue[next].cmd_no == MDC_COM_COLL)
		ion_check_accumulator = 0;

#ifdef  WINNT 
	if(abortable_command(command_in_progress))
		stop_abort_thread();
#endif /* WINNT */

	command_in_progress = -1;

	if(abort_asserted)
		cm_sync();
	abort_asserted = 0;

	return(0);
}
