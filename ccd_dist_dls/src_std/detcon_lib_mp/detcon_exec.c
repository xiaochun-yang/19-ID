#include	"detcon_ext.h"

/*
 *	Routines linking from detcon_entry.c
 *
 *	Some functions may require multiple sequencing calls into
 *	the hardware control module.
 */

exec_ccd_start_exposure()
  {
	void detcon_update_expos();

	dtc_last = CCD_LAST_START;
	if(dtc_initialized == 0)
	  {
		strcpy(dtc_status_string,"detcon_lib NOT initialized");
		return;
	  }
	dtc_state = DTC_STATE_EXPOSING;

	detcon_send_det_start();

	if(dtc_state == DTC_STATE_EXPOSING)
	  {
	    dtc_expos_msec_ticks = 0;
	    enqueue_fcn(detcon_update_expos,1000,1.0);
	  }  
  }

exec_ccd_stop_exposure()
  {
	dtc_last = CCD_LAST_STOP;
	if(dtc_initialized == 0)
	  {
		strcpy(dtc_status_string,"detcon_lib NOT initialized");
		return;
	  }

	if(dtc_state != DTC_STATE_EXPOSING)
	  {
		dtc_state = DTC_STATE_ERROR;
		strcpy(dtc_status_string,"exec_ccd_stop_exposure called with NO exposure in progress");
		return;
	  }
	detcon_send_det_stop();
  }

exec_ccd_get_image(last)
int	last;
  {
	dtc_last = CCD_LAST_GET;
	if(last == 0)
	{
		detcon_send_copy_command();
		dtc_last = CCD_LAST_GET;
	}
	else if(last == 1)
	{
		detcon_send_copy_command();
		detcon_output_detcmd(dtc_fddetcmd,"flush\n",NULL,0);
		dtc_last = CCD_LAST_IDLE;
	}
	else if(last == -1)
	{
		detcon_output_detcmd(dtc_fddetcmd,"flush\n",NULL,0);
		dtc_last = CCD_LAST_IDLE;
	}
  }

exec_initialize()
  {
	void	detcon_check_xform_return();

	dtc_state = DTC_STATE_IDLE;

	check_environ();
	apply_reasonable_defaults();

	detcon_ccd_initialize();

	detcon_server_init();

	detcon_clockstart();

	strcpy(dtc_status_string,"Idle");
	strcpy(dtc_lasterror_string,"");

	dtc_initialized = 1;

	if(1)	/* DEBUG */
		enqueue_fcn(detcon_check_xform_return,0,1.0);
  }

exec_reset()
  {
	detcon_output_detcmd(dtc_fddetcmd, "reset\n", NULL, 0);

	dtc_state = DTC_STATE_IDLE;

        strcpy(dtc_status_string,"Idle");
        strcpy(dtc_lasterror_string,"");
  }

exec_hw_reset()
  {
	detcon_output_detcmd(dtc_fddetcmd, "hwreset\n", NULL, 0);

	dtc_state = DTC_STATE_IDLE;

        strcpy(dtc_status_string,"Idle");
        strcpy(dtc_lasterror_string,"");
  }

int	exec_ccd_abort()
{
	switch(dtc_last)
	{
	case CCD_LAST_IDLE:
		break;
	case CCD_LAST_START:
		while(DTC_STATE_EXPOSING != CCDState())
		{
			if(DTC_STATE_ERROR == CCDState())
			{
				fprintf(stdout,"Error returned from CCDStartExposure()\n");
				return(0);
			}
		}
		exec_ccd_stop_exposure();
		while(DTC_STATE_IDLE != CCDState())
		{
			if(DTC_STATE_ERROR == CCDState())
			{
			    fprintf(stdout,"Error returned from CCDStopExposure()\n");
			    return(0);
			}
		}
		switch(dtc_image_kind)
		{
		case 0:		/* first dark */
			if(dtc_output_raws)
				exec_ccd_get_image(1);
			break;
		case 4:
			if(dtc_output_raws)
				exec_ccd_get_image(1);
			break;
		case 1:		/* second dark or second(only) image */
		case 5:
			exec_ccd_get_image(1);
			break;
		}
		dtc_last = CCD_LAST_IDLE;
		break;
	case CCD_LAST_STOP:
		exec_ccd_get_image(1);
		dtc_last = CCD_LAST_IDLE;
		break;
	case CCD_LAST_GET:
		exec_ccd_get_image(-1);
		dtc_last = CCD_LAST_IDLE;
		break;
	}
	return(1);
}
