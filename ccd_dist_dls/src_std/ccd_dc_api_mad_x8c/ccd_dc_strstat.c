#include	"ccd_dc_ext.h"

/*
 *	ccd_dc_stat:
 *
 *	Gather status information from the detector process and
 *	pass it on to the status program.  Supports more than one
 *	output format (old style, new style).
 *
 *	Robust in terms of partial status sends from the motion
 *	and beam control process.  Try to throw out lines which
 *	otherwise get garbled.
 *
 */

int	arrays_initialized  = 0;
int	output_status_style = 1;	/* 1 for andy's new control, 0 for the old one */

static int	n_mdc_updates = 0;
static int	n_ccd_updates = 0;

struct output_status_lines {
				char	*st_key;
				char	*st_value;
				int	 st_ind;
		    	   };

struct input_status_lines {
				char	*sti_key;
				int	 sti_ind;
			  };

/*
 *	This is a list of keywords which may be sent by the beam
 *	and motor control process.
 */

enum bl_key
  {
	BL_DISTANCE = 0,
	BL_PHI,
	BL_OSC_WIDTH,
	BL_N_PASSES,
	BL_TIME,
	BL_INTENSITY,
	BL_MAX_COUNT,
	BL_DIRECTORY,
	BL_FILENAME,
	BL_SCANNER_OP,
	BL_SCANNER_MSG,
	BL_SCANNER_CONTROL,
	BL_SCANNER_SHUTTER,
	BL_N_MDC_UPDATES,
	BL_MODE,
	BL_ADC,
	BL_BIN,
	BL_WAVELENGTH,
	BL_LIFT,
	BL_MDC_ALERT,
	BL_KAPPA,
	BL_OMEGA,
	BL_AXIS,
	BL_BEAM_X,
	BL_BEAM_Y,
	BL_DETECTOR_OP,
	BL_DETECTOR_PERCENT,
        BL_STEP_SIZE,
        BL_DOSE_STEP,
	BL_ATTENUATOR,
	BL_XL_ION_UP,
	BL_XL_ION_DN,
	BL_XL_ION_BEAM,
	BL_XL_HS,
	BL_XL_VS,
	BL_XL_GUARD_HS,
	BL_XL_GUARD_VS,
	BL_XL_UP_VHS,
	BL_XL_UP_HHS,
	BL_XL_DN_VHS,
	BL_XL_DN_HHS,
	BL_HSLIT,
	BL_VSLIT,
	BL_MASTER,
	BL_CLIENT_STAFF,
	BL_CLIENT_MOTOR,
	BL_CLIENT_USER,
	BL_EXPERIMENT_MODE,
	BL_END_OF_STATUS
  };

struct input_status_lines bl_key[] = 
  {
	"distance",		BL_DISTANCE,
	"phi",			BL_PHI,
	"osc_width",		BL_OSC_WIDTH,
	"n_passes",		BL_N_PASSES,
	"time",			BL_TIME,
	"intensity",		BL_INTENSITY,
	"max_count",		BL_MAX_COUNT,
	"directory",		BL_DIRECTORY,
	"filename",		BL_FILENAME,
	"scanner_op",		BL_SCANNER_OP,
	"scanner_msg",		BL_SCANNER_MSG,
	"scanner_control",	BL_SCANNER_CONTROL,
	"scanner_shutter",	BL_SCANNER_SHUTTER,
	"n_mdc_updates",	BL_N_MDC_UPDATES,
	"mode",			BL_MODE,
	"adc",			BL_ADC,
	"bin",			BL_BIN,
	"wavelength",		BL_WAVELENGTH,
	"lift",			BL_LIFT,
	"mdc_alert",		BL_MDC_ALERT,
	"kappa",		BL_KAPPA,
	"omega",		BL_OMEGA,
	"axis",			BL_AXIS,
	"beam_x",		BL_BEAM_X,
	"beam_y",		BL_BEAM_Y,
	"detector_op",		BL_DETECTOR_OP,
	"detector_percent",	BL_DETECTOR_PERCENT,
        "step_size",            BL_STEP_SIZE,
        "dose_per_step",        BL_DOSE_STEP,
	"attenuator",		BL_ATTENUATOR,
	"xl_ion_up",		BL_XL_ION_UP,
	"xl_ion_dn",		BL_XL_ION_DN,
	"xl_ion_beam",		BL_XL_ION_BEAM,
	"xl_hs",		BL_XL_HS,
	"xl_vs",		BL_XL_VS,
	"xl_guard_hs",		BL_XL_GUARD_HS,
	"xl_guard_vs",		BL_XL_GUARD_VS,
	"xl_up_vhs",		BL_XL_UP_VHS,
	"xl_up_hhs",		BL_XL_UP_HHS,
	"xl_dn_vhs",		BL_XL_DN_VHS,
	"xl_dn_hhs",		BL_XL_DN_HHS,
	"hslit",		BL_HSLIT,
	"vslit",		BL_VSLIT,
	"master",		BL_MASTER,
	"client_staff",		BL_CLIENT_STAFF,
	"client_motor",		BL_CLIENT_MOTOR,
	"client_user",		BL_CLIENT_USER,
	"experiment_mode",	BL_EXPERIMENT_MODE,
	"end_of_status",	BL_END_OF_STATUS,
	NULL,			0,
  };

enum adxc_new_ind 
  {
	NIND_DISTANCE = 0,
	NIND_LIFT,
	NIND_PHI,
	NIND_KAPPA,
	NIND_OMEGA,
	NIND_AXIS,
	NIND_OSC_START,
	NIND_OSC_END,
	NIND_OSC_WIDTH,
	NIND_MODE,
	NIND_EXPOSURE,
	NIND_DEZINGER,
	NIND_ADC,
	NIND_BIN,
	NIND_COMPRESSION,
	NIND_BEAM_X,
	NIND_BEAM_Y,
	NIND_WAVELENGTH,
	NIND_INTENSITY,
	NIND_DIRECTORY,
	NIND_CURRENT_FILENAME,
	NIND_ALERT_MSG,
	NIND_DETECTOR_OP,
	NIND_DETECTOR_PERCENT_COMPLETE,
	NIND_DETECTOR_SHUTTER,
        NIND_STEP_SIZE,
        NIND_DOSE_STEP,
	NIND_ATTENUATOR,
	NIND_BL_XL_ION_UP,
	NIND_BL_XL_ION_DN,
	NIND_BL_XL_ION_BEAM,
	NIND_BL_XL_HS,
	NIND_BL_XL_VS,
	NIND_BL_XL_GUARD_HS,
	NIND_BL_XL_GUARD_VS,
	NIND_BL_XL_UP_VHS,
	NIND_BL_XL_UP_HHS,
	NIND_BL_XL_DN_VHS,
	NIND_BL_XL_DN_HHS,
	NIND_BL_HSLIT,
	NIND_BL_VSLIT,
	NIND_BL_MASTER,
	NIND_BL_CLIENT_STAFF,
	NIND_BL_CLIENT_MOTOR,
	NIND_BL_CLIENT_USER,
	NIND_BL_EXPERIMENT_MODE,
	NIND_END_OF_STATUS
  };

struct output_status_lines adxc_new_key[] = {
	"distance",			NULL,	NIND_DISTANCE,
	"lift",				NULL,	NIND_LIFT,
	"phi",				NULL,	NIND_PHI,
	"kappa",			NULL,	NIND_KAPPA,
	"omega",			NULL,	NIND_OMEGA,
	"axis",				NULL,	NIND_AXIS,
	"osc_start",			NULL,	NIND_OSC_START,
	"osc_end",			NULL,	NIND_OSC_END,
	"osc_width",			NULL,	NIND_OSC_WIDTH,
	"mode",				NULL,	NIND_MODE,
	"exposure",			NULL,	NIND_EXPOSURE,
	"dezinger",			NULL,	NIND_DEZINGER,
	"adc",				NULL,	NIND_ADC,
	"bin",				NULL,	NIND_BIN,
	"compression",			NULL,	NIND_COMPRESSION,
	"beam_x",			NULL,	NIND_BEAM_X,
	"beam_y",			NULL,	NIND_BEAM_Y,
	"wavelength",			NULL,	NIND_WAVELENGTH,
	"intensity",			NULL,	NIND_INTENSITY,
	"directory",			NULL,	NIND_DIRECTORY,
	"current_filename",		NULL,	NIND_CURRENT_FILENAME,
	"alert_msg",			NULL,	NIND_ALERT_MSG,
	"detector_op",			NULL,	NIND_DETECTOR_OP,
	"detector_percent_complete",	NULL,	NIND_DETECTOR_PERCENT_COMPLETE,
	"detector_shutter",		NULL,	NIND_DETECTOR_SHUTTER,
        "step_size",                    NULL,   NIND_STEP_SIZE,
        "dose_per_step",                NULL,   NIND_DOSE_STEP,
	"attenuator",			NULL,	NIND_ATTENUATOR,
	"xl_ion_up",			NULL,	NIND_BL_XL_ION_UP,
	"xl_ion_dn",			NULL,	NIND_BL_XL_ION_DN,
	"xl_ion_beam",			NULL,	NIND_BL_XL_ION_BEAM,
	"xl_hs",			NULL,	NIND_BL_XL_HS,
	"xl_vs",			NULL,	NIND_BL_XL_VS,
	"xl_guard_hs",			NULL,	NIND_BL_XL_GUARD_HS,
	"xl_guard_vs",			NULL,	NIND_BL_XL_GUARD_VS,
	"xl_up_vhs",			NULL,	NIND_BL_XL_UP_VHS,
	"xl_up_hhs",			NULL,	NIND_BL_XL_UP_HHS,
	"xl_dn_vhs",			NULL,	NIND_BL_XL_DN_VHS,
	"xl_dn_hhs",			NULL,	NIND_BL_XL_DN_HHS,
	"hslit",			NULL,	NIND_BL_HSLIT,
	"vslit",			NULL,	NIND_BL_VSLIT,
	"master",			NULL,	NIND_BL_MASTER,
	"client_staff",			NULL,	NIND_BL_CLIENT_STAFF,
	"client_motor",			NULL,	NIND_BL_CLIENT_MOTOR,
	"client_user",			NULL,	NIND_BL_CLIENT_USER,
	"experiment_mode",		NULL,	NIND_BL_EXPERIMENT_MODE,
	"end_of_status",		NULL,	NIND_END_OF_STATUS,
	NULL,				NULL,	0,
			   };


enum old_status_key 
  {
	OIND_DISTANCE = 0,
	OIND_PHI,
	OIND_OSC_WIDTH,
	OIND_N_PASSES,
	OIND_TIME,
	OIND_INTENSITY,
	OIND_MAX_COUNT,
	OIND_DIRECTORY,
	OIND_FILENAME,
	OIND_SCANNER_OP,
	OIND_SCANNER_MSG,
	OIND_SCANNER_CONTROL,
	OIND_SCANNER_SHUTTER,
	OIND_N_MDC_UPDATES,
	OIND_MODE,
	OIND_ADC,
	OIND_BIN,
	OIND_WAVELENGTH,
	OIND_LIFT,
	OIND_MDC_ALERT,
	OIND_CCD_OP,
	OIND_N_CCD_UPDATES,
	OIND_END_OF_STATUS
  };

struct output_status_lines adxc_old_key[] = 
  {
	"distance",		NULL,	OIND_DISTANCE,
	"phi",			NULL,	OIND_PHI,
	"osc_width",		NULL,	OIND_OSC_WIDTH,
	"n_passes",		NULL,	OIND_N_PASSES,
	"time",			NULL,	OIND_TIME,
	"intensity",		NULL,	OIND_INTENSITY,
	"max_count",		NULL,	OIND_MAX_COUNT,
	"directory",		NULL,	OIND_DIRECTORY,
	"filename",		NULL,	OIND_FILENAME,
	"scanner_op",		NULL,	OIND_SCANNER_OP,
	"scanner_msg",		NULL,	OIND_SCANNER_MSG,
	"scanner_control",	NULL,	OIND_SCANNER_CONTROL,
	"scanner_shutter",	NULL,	OIND_SCANNER_SHUTTER,
	"n_mdc_updates",	NULL,	OIND_N_MDC_UPDATES,
	"mode",			NULL,	OIND_MODE,
	"adc",			NULL,	OIND_ADC,
	"bin",			NULL,	OIND_BIN,
	"wavelength",		NULL,	OIND_WAVELENGTH,
	"lift",			NULL,	OIND_LIFT,
	"mdc_alert",		NULL,	OIND_MDC_ALERT,
	"ccd_op",		NULL,	OIND_CCD_OP,
	"n_ccd_updates",	NULL,	OIND_N_CCD_UPDATES,
	"end_of_status",	NULL,	OIND_END_OF_STATUS,
	NULL,			NULL,	0,
  };

void	alloc_ospace(osb)
struct output_status_lines *osb;
  {
	struct output_status_lines	*p;
	int				nlines,tsize;
	char				*buf,*cpt;

	for(nlines = 0, p = osb; p->st_key != NULL; p++)
		nlines++;

	tsize = nlines * 132;

	if(NULL == (buf = (char *) calloc(tsize,sizeof (char))))
	  {
		fprintf(stderr,"alloc_ospace (ccd_dc_strstat.c): Error allocating %d bytes\n",tsize);
		exit(0);
	  }
	
	for(cpt = buf, p = osb; p->st_key != NULL; p++,cpt += 132)
	  {
	    p->st_value = cpt;
	    *(p->st_value) = '\0';
	  }
  }

char	stbuf_bl[10240];		/* holding area for beamline status */
int	stbufind_bl = 0;
char	stubuf_bl[2048];		/* contains a complete status update */
int	stindex_bl = 0;
int	isstat_bl = 0;			/* status in the buffer */

char	stbuf_det[10240];		/* holding area for detector status */
char	stubuf_det[2048];		/* contains a complete status update */
int	stindex_det = 0;
int	isstat_det = 0;			/* status in the buffer */

static	char	*stterm = "end_of_status\n";

/*
 *	This routine just reads the socket pointed to by fd until there is
 *	no data left to read.
 *
 *	Returns nchar > 0 if there was data; this is the cumulative number of
 *			  characters read.
 *
 *	        nchar = 0 if there was no data to read.
 *
 *		nchar = -1 if there is some kind of error.
 */

int	read_status_port_raw(fd,stbuf,stbufsize)
int	fd;
char	*stbuf;
int	stbufsize;
  {
	int	nread;
	fd_set	readmask;
	int	ret;
	struct timeval	timeout;

	nread = 0;

	while(1)
	  {
	    FD_ZERO(&readmask);
	    FD_SET(fd,&readmask);
	    timeout.tv_usec = 0;
	    timeout.tv_sec = 0;
	    ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	    if(ret == 0)
		return(nread);
	    if(ret == -1)
	      {
		if(errno == EINTR)
		  continue;	/* Ignore interrupted system calls */
		notify_server_eof(fd);
		return(-1);
	      }
	    if(0 == FD_ISSET(fd,&readmask))
	      {
		return(nread);
	      }
	    ret = read(fd,stbuf + nread,stbufsize - nread);
	    if(ret == -1)
	      {
		if(errno == EINTR)
		  continue;	/* Ignore interrupted system calls */
		notify_server_eof(fd);
		return(-1);
	      }
	    if(ret == 0)
	      {
		if(0)
	            fprintf(stdout,"ccd_dc_status: INFO:          read nbytes of 0 from status process\n");
		return(nread);
	      }
	    nread += ret;
	  }
  }

/*
 *	This routine covers the write call, checking for
 *	the various things which could go wrong:
 *
 *	If the connection has disappeared, notify the
 *	server and terminate the status outputting for the
 *	time being.
 *
 *	If the connection would block, just don't output any
 *	more status lines on this pass.  We'll start over with
 *	the distance on the next heartbeat update; this will
 *	get everything on the other end back in sync, since that
 *	process looks for the "distance" keyword as the synchronizing
 *	(rewinding) mechanism.
 *
 *	Returns the status associated with the write, except that
 *	any fatal error with select or such also returns -1.
 */

int	st_write(fd,buf,n)
int	fd;
char	*buf;
int	n;
  {
	int		ret;
	fd_set		readmask,writemask,exceptmask;
	struct	timeval	timeout;

	FD_ZERO(&writemask);
	FD_SET(fd,&writemask);
	timeout.tv_sec = 0;
	timeout.tv_usec = 0;
	while(1)
	  {
	    ret = select(FD_SETSIZE, (fd_set *) 0, &writemask, (fd_set *) 0, &timeout);
	    if(ret < 0)
	      {
		if(errno == EINTR)
			continue;	/* just try this again. */
	        perror("st_write in status: select error: should never happen.");
	        return(-1);
	      }
	    break;
	  }
	/*
	 *	blocked writes: just return 0; we skip the rest of the status
	 *	update on this pass.  This is not critical unless it lasts a
	 *	LONG time.
	 */
	if(ret == 0)
	  {
	    fprintf(stderr,"ccd_dc: st_write: block in status write; output terminated\n");
	    return(0);
	  }
	
	ret = write(fd,buf,n);

	if(ret <= 0)
	  {
	    notify_server_eof(fd);
	    return(ret);
	  }
	return(ret);
  }

void 	update_old_output_status(keyind,tok1,tok2,outkey)
int				keyind;
char				tok1[];
char				tok2[];
struct	output_status_lines	outkey[];
  {
	switch(keyind)
	  {
	    case BL_DISTANCE:
		strcpy(outkey[OIND_DISTANCE].st_value,tok2);
		sscanf(tok2,"%f",&stat_dist);
		break;
	    case BL_PHI:
		strcpy(outkey[OIND_PHI].st_value,tok2);
		break;
	    case BL_OSC_WIDTH:
		strcpy(outkey[OIND_OSC_WIDTH].st_value,tok2);
		break;
	    case BL_N_PASSES:
		strcpy(outkey[OIND_N_PASSES].st_value,tok2);
		break;
	    case BL_TIME:
		strcpy(outkey[OIND_TIME].st_value,tok2);
		break;
	    case BL_INTENSITY:
		strcpy(outkey[OIND_INTENSITY].st_value,tok2);
		break;
	    case BL_MAX_COUNT:
		strcpy(outkey[OIND_MAX_COUNT].st_value,tok2);
		break;
	    case BL_DIRECTORY:
		strcpy(outkey[OIND_DIRECTORY].st_value,tok2);
		break;
	    case BL_FILENAME:
		strcpy(outkey[OIND_FILENAME].st_value,tok2);
		break;
	    case BL_SCANNER_OP:
		strcpy(outkey[OIND_SCANNER_OP].st_value,tok2);
		/*
		 *	This piece attempts to determine what's really
		 *	going on.  Not a thing of beauty.
		 */
	        if(tok2[0] == '\0' && dc_in_progress == 1)
		  strcpy(outkey[OIND_CCD_OP].st_value,"detector readout");
	         else
	          if(tok2[0] == '\0' && dc_in_progress == 0)
		    strcpy(outkey[OIND_CCD_OP].st_value,"idle");
	           else
	            if(0 == strcmp("idle",tok2) && dc_in_progress == 1)
		      strcpy(outkey[OIND_CCD_OP].st_value,"detector readout");
	             else
	              if(0 == strcmp("idle",tok2) && dc_in_progress == 0)
		        strcpy(outkey[OIND_CCD_OP].st_value,"idle");
		       else
			sprintf(outkey[OIND_CCD_OP].st_value,"%s",tok2);
		break;
	    case BL_SCANNER_MSG:
		strcpy(outkey[OIND_SCANNER_MSG].st_value,tok2);
		break;
	    case BL_SCANNER_CONTROL:
		strcpy(outkey[OIND_SCANNER_CONTROL].st_value,tok2);
		break;
	    case BL_SCANNER_SHUTTER:
		strcpy(outkey[OIND_SCANNER_SHUTTER].st_value,tok2);
		break;
	    case BL_N_MDC_UPDATES:
		strcpy(outkey[OIND_N_MDC_UPDATES].st_value,tok2);
		break;
	    case BL_MODE:
		strcpy(outkey[OIND_MODE].st_value,tok2);
		break;
	    case BL_ADC:
		strcpy(outkey[OIND_ADC].st_value,tok2);
		break;
	    case BL_BIN:
		strcpy(outkey[OIND_BIN].st_value,tok2);
		break;
	    case BL_WAVELENGTH:
		strcpy(outkey[OIND_WAVELENGTH].st_value,tok2);
		sscanf(tok2,"%f",&stat_wavelength);
		break;
	    case BL_LIFT:
		strcpy(outkey[OIND_LIFT].st_value,tok2);
		break;
	    case BL_MDC_ALERT:
		strcpy(outkey[OIND_MDC_ALERT].st_value,tok2);
		break;
	    case BL_KAPPA:
		break;
	    case BL_OMEGA:
		break;
	    case BL_AXIS:
		break;
	    case BL_BEAM_X:
		break;
	    case BL_BEAM_Y:
		break;
	    case BL_DETECTOR_OP:
		break;
	    case BL_DETECTOR_PERCENT:
		break;
	    case BL_END_OF_STATUS:
		break;
	  }
  }

static int	is_exposing;

void 	update_new_output_status(keyind,tok1,tok2,outkey)
int				keyind;
char				tok1[];
char				tok2[];
struct	output_status_lines	outkey[];
  {
	char	strjunk[100];
	int	percent_complete,sstate,bin;

	switch(keyind)
	  {
	    case BL_DISTANCE:
		strcpy(outkey[NIND_DISTANCE].st_value,tok2);
		sscanf(tok2,"%f",&stat_dist);
		break;
	    case BL_PHI:
		strcpy(outkey[NIND_PHI].st_value,tok2);
		break;
	    case BL_OSC_WIDTH:
		strcpy(outkey[NIND_OSC_WIDTH].st_value,tok2);
		break;
	    case BL_N_PASSES:
		break;
	    case BL_TIME:
		strcpy(outkey[NIND_EXPOSURE].st_value,tok2);
		break;
	    case BL_INTENSITY:
		strcpy(outkey[NIND_INTENSITY].st_value,tok2);
		break;
	    case BL_MAX_COUNT:
		break;
	    case BL_DIRECTORY:
		strcpy(outkey[NIND_DIRECTORY].st_value,tok2);
		break;
	    case BL_FILENAME:
		strcpy(outkey[NIND_CURRENT_FILENAME].st_value,tok2);
		break;
	    case BL_SCANNER_OP:
		is_exposing = 0;
		if(0 == strcmp(tok2,"exposing") || 0 == strcmp(tok2,"exposing_dark_current"))
			is_exposing = 1;
		strcpy(outkey[NIND_DETECTOR_OP].st_value,tok2);
		/*
		 *	This piece attempts to determine what's really
		 *	going on.  Not a thing of beauty.
		 */
	        if(tok2[0] == '\0' && dc_in_progress == 1)
		  strcpy(outkey[NIND_DETECTOR_OP].st_value,"detector readout");
	         else
	          if(tok2[0] == '\0' && dc_in_progress == 0)
		    strcpy(outkey[NIND_DETECTOR_OP].st_value,"idle");
	           else
	            if(0 == strcmp("idle",tok2) && dc_in_progress == 1)
		      strcpy(outkey[NIND_DETECTOR_OP].st_value,"detector readout");
	             else
	              if(0 == strcmp("idle",tok2) && dc_in_progress == 0)
		        strcpy(outkey[NIND_DETECTOR_OP].st_value,"idle");
		       else
			sprintf(outkey[NIND_DETECTOR_OP].st_value,"%s",tok2);
		break;
	    case BL_SCANNER_MSG:
		if(is_exposing == 1)
		  {
			sscanf(tok2,"%s %d",strjunk,&percent_complete);
			if(percent_complete >= 0 && percent_complete <= 100)
			  sprintf(outkey[NIND_DETECTOR_PERCENT_COMPLETE].st_value,"%d",percent_complete);
			 else
			  sprintf(outkey[NIND_DETECTOR_PERCENT_COMPLETE].st_value,"%d",0);
		  }
		 else
		  sprintf(outkey[NIND_DETECTOR_PERCENT_COMPLETE].st_value,"%d",0);
		break;
	    case BL_SCANNER_CONTROL:
		break;
	    case BL_SCANNER_SHUTTER:
		strcpy(outkey[NIND_DETECTOR_SHUTTER].st_value,tok2);
		break;
	    case BL_N_MDC_UPDATES:
		break;
	    case BL_MODE:
		strcpy(outkey[NIND_MODE].st_value,tok2);
		break;
	    case BL_ADC:
		strcpy(outkey[NIND_ADC].st_value,tok2);
		break;
	    case BL_BIN:
		sscanf(tok2,"%d",&bin);
		if(bin == 1)
		  strcpy(outkey[NIND_BIN].st_value,"no");
		 else
		  strcpy(outkey[NIND_BIN].st_value,"2x2");
		break;
	    case BL_WAVELENGTH:
		strcpy(outkey[NIND_WAVELENGTH].st_value,tok2);
		sscanf(tok2,"%f",&stat_wavelength);
		break;
	    case BL_ATTENUATOR:
		strcpy(outkey[NIND_ATTENUATOR].st_value,tok2);
		sscanf(tok2,"%f",&stat_attenuator);
		break;
	    case BL_XL_ION_UP:
		strcpy(outkey[NIND_BL_XL_ION_UP].st_value, tok2);
		break;
	    case BL_XL_ION_DN:
		strcpy(outkey[NIND_BL_XL_ION_DN].st_value, tok2);
		break;
	    case BL_XL_ION_BEAM:
		strcpy(outkey[NIND_BL_XL_ION_BEAM].st_value, tok2);
		break;
	    case BL_XL_HS:
		strcpy(outkey[NIND_BL_XL_HS].st_value, tok2);
		break;
	    case BL_XL_VS:
		strcpy(outkey[NIND_BL_XL_VS].st_value, tok2);
		break;
	    case BL_XL_GUARD_HS:
		strcpy(outkey[NIND_BL_XL_GUARD_HS].st_value, tok2);
		break;
	    case BL_XL_GUARD_VS:
		strcpy(outkey[NIND_BL_XL_GUARD_VS].st_value, tok2);
		break;
	    case BL_XL_UP_VHS:
		strcpy(outkey[NIND_BL_XL_UP_VHS].st_value, tok2);
		break;
	    case BL_XL_UP_HHS:
		strcpy(outkey[NIND_BL_XL_UP_HHS].st_value, tok2);
		break;
	    case BL_XL_DN_VHS:
		strcpy(outkey[NIND_BL_XL_DN_VHS].st_value, tok2);
		break;
	    case BL_XL_DN_HHS:
		strcpy(outkey[NIND_BL_XL_DN_HHS].st_value, tok2);
		break;
	    case BL_HSLIT:
		strcpy(outkey[NIND_BL_HSLIT].st_value, tok2);
		break;
	    case BL_VSLIT:
		strcpy(outkey[NIND_BL_VSLIT].st_value, tok2);
		break;
	    case BL_MASTER:
		strcpy(outkey[NIND_BL_MASTER].st_value, tok2);
		break;
	    case BL_EXPERIMENT_MODE:
		strcpy(outkey[NIND_BL_EXPERIMENT_MODE].st_value, tok2);
		sscanf(tok2,"%f",&stat_experiment_mode);
		break;
	    case BL_CLIENT_STAFF:
		strcpy(outkey[NIND_BL_CLIENT_STAFF].st_value, tok2);
		break;
	    case BL_CLIENT_MOTOR:
		strcpy(outkey[NIND_BL_CLIENT_MOTOR].st_value, tok2);
		break;
	    case BL_CLIENT_USER:
		strcpy(outkey[NIND_BL_CLIENT_USER].st_value, tok2);
		break;
	    case BL_LIFT:
		strcpy(outkey[NIND_LIFT].st_value,tok2);
		break;
	    case BL_MDC_ALERT:
		strcpy(outkey[NIND_ALERT_MSG].st_value,tok2);
		break;
	    case BL_KAPPA:
		strcpy(outkey[NIND_KAPPA].st_value,tok2);
		break;
	    case BL_OMEGA:
		strcpy(outkey[NIND_OMEGA].st_value,tok2);
		break;
	    case BL_AXIS:
		strcpy(outkey[NIND_AXIS].st_value,tok2);
		break;
	    case BL_BEAM_X:
		strcpy(outkey[NIND_BEAM_X].st_value,tok2);
		break;
	    case BL_BEAM_Y:
		strcpy(outkey[NIND_BEAM_Y].st_value,tok2);
		break;
	    case BL_DETECTOR_OP:
		if(0)	/* we actually don't use this feature yet */
		  strcpy(outkey[NIND_DETECTOR_OP].st_value,tok2);
		break;
	    case BL_DETECTOR_PERCENT:
		break;
            case BL_STEP_SIZE:
                strcpy(outkey[NIND_STEP_SIZE].st_value,tok2);
	    case BL_END_OF_STATUS:
		break;
	  }
  }

/*
 *	process_input_buffer:
 *
 *	Take the lines in the buffer buf of length end_index
 *	and process the data one line at a time.  When done,
 *	return the end_index of processable data.  This value
 *	will be less than or equal the input end_index.  It is
 *	designed to allow processing of partial line data later.
 */

int 	process_input_buffer(buf,end_index)
char	*buf;
int	end_index;
  {
	int	bind,eind,i,j;
	char	tok1[132],tok2[132];

	for(bind = 0 ; ; )
	  {
	    /*
	     *	Find a line.
	     */

	    for(eind = bind; eind < end_index; eind++)
	      if(buf[eind] == '\n')
		break;
	    /*
	     *	return if we hit the end.
	     */

	    if(eind == end_index)
		return(eind);
	    
	    /*
	     *	Reject the line if it has unreasonable length.
	     */

	    if(eind - bind > 132)
	      {
		bind = eind + 1;
		continue;
	      }

	    /*
	     *	Split the line into two tokens: An initial key
	     *	and everything which follows it.
	     *
	     *	The first token is from the beginning to any whitespace or
	     *	the end of a line.
	     */

	    for(i = bind, j = 0; i < eind; i++,j++)
	      {
		if(buf[i] == ' ' || buf[i] == '\n' || buf[i] == '\t' || buf[i] == '\0')
		    break;
		  else
	            tok1[j] = buf[i];
	      }
	    tok1[j] = '\0';

	    /*
	     *	It is allowed to have as much white space as desired between
	     *	the first and second token.
	     */

	    i++;
	    for(; i < eind; i++)
	      if(buf[i] != ' ' && buf[i] != '\t')
		break;

	    /*
	     *	The second token is from here to the end of the line.  It is
	     *	allowed to have embedded whitespace in the second token.
	     */

	    for(j = 0; i < eind; i++,j++)
		if(buf[i] == '\n' || buf[i] == '\0')
		    break;
		  else
	      	    tok2[j] = buf[i];
	    tok2[j] = '\0';

	    /*
	     *	See which key it belongs to.
	     */

	    for(i = 0; bl_key[i].sti_key != NULL; i++)
	      if(0 == strcmp(bl_key[i].sti_key,tok1))
		{
		  if(output_status_style)
			update_new_output_status(bl_key[i].sti_ind,tok1,tok2,adxc_new_key);
		    else
			update_old_output_status(bl_key[i].sti_ind,tok1,tok2,adxc_old_key);
		}
	    bind = eind + 1;
	  }
  }

output_to_status_proc(fd,key)
int	fd;
struct	output_status_lines	key[];
  {
	int	i,ret,len_buf,cnt_buf,len_buf_save;
	char	tbuf[132],obuf[133],op_val[132];

	for(i = 0; key[i].st_key != NULL; i++)
	  {
	    if(0 == strcmp(key[i].st_key,"end_of_status"))
	      {
		sprintf(tbuf,"end_of_status\n");
	      }
	      else if(*(key[i].st_value) == '\0' || (*key[i].st_value == '\n'))
		{
		  continue;
		}
	       else
		  sprintf(tbuf,"%s %s\n",key[i].st_key,key[i].st_value);
	    
	    len_buf = strlen(tbuf);
	    cnt_buf = 0;
	    while(len_buf > 0)
	      {
	        ret = st_write(fd,&tbuf[cnt_buf],len_buf);
	        if(ret <= 0)
	          {
		    fprintf(stderr,"ccd_dc: block in status write; output terminated\n");
		    return;
	          }
	        len_buf -= ret;
	        cnt_buf += ret;
	      }
	  }
  }

/*
 *	print_status:
 *
 *	Read as much data as possible from the input socket.
 *	Identify each line by keyword, update an output list with
 *	this information, then output status.
 */

print_status(fd)
int	fd;
  {
	char	tbuf[132],obuf[133],op_val[132];
	int	ret,i,j,npass,eobuf,did_output,end_index;
	int	len_det,len_bl,looklen;

	/*
	 *	Make sure the output arrays are initialized properly.
	 */

	if(arrays_initialized == 0)
	  {
		if(output_status_style)
		  {
		    alloc_ospace(adxc_new_key);
		    strcpy(adxc_new_key[NIND_DETECTOR_OP].st_value,"idle");
		  }
		 else
		  {
		    alloc_ospace(adxc_old_key);
		    strcpy(adxc_old_key[OIND_CCD_OP].st_value,"idle");
		    n_mdc_updates = 0;
		    n_ccd_updates = 0;
		  }
		arrays_initialized = 1;
	  }
	/*
	 *	Check to see if there is anything new in the input buffers
	 */

	isstat_bl = 0;
	if(fdblstatus != -1)
	    if(0 < (ret = read_status_port_raw(fdblstatus,&stbuf_bl[stbufind_bl],10240 - stbufind_bl)))
		isstat_bl = 1;

	/*
	 *	If there was new data, process the data one line at a time and
	 *	move any "residual" to the beginning of the input buffer so the
	 *	next read concatinates to it.
	 */

	if(isstat_bl)
	  {
	    if(output_status_style == 0)	/* this only matters for old status output. */
	      {
	    	n_mdc_updates++;
		sprintf(adxc_old_key[OIND_N_MDC_UPDATES].st_value,"%d",n_mdc_updates);
	      }
	    stbufind_bl += ret;
	    end_index = process_input_buffer(stbuf_bl,stbufind_bl);
	    if(end_index != stbufind_bl)
	      for(i = end_index , j = 0; i < stbufind_bl; i++,j++)
	stbuf_bl[j] = stbuf_bl[i];
	    stbufind_bl -= end_index;
	  }

	if(output_status_style == 0)	/* this only matters for old statut output. */
	  {
		n_ccd_updates++;
		sprintf(adxc_old_key[OIND_N_CCD_UPDATES].st_value,"%d",n_ccd_updates);
		sprintf(adxc_old_key[OIND_N_MDC_UPDATES].st_value,"%d",n_mdc_updates);  /* delete when bug fixed */
	  }

 	if(fd == -1)
	    return;

	if(output_status_style)
	    output_to_status_proc(fd,adxc_new_key);
	  else
	    output_to_status_proc(fd,adxc_old_key);
  }

set_alert_msg(s)
char	*s;
  {
        char    buf1[132],buf[132];
        char    *ztime();

        strcpy(buf,"At: ");
        strcpy(buf1,ztime());
        buf1[strlen(buf1) - 5] = '\0';
        strcat(buf,&buf1[strlen(buf1) - 8]);
        strcat(buf," : ");
        strcat(buf,s);
        strcpy(adxc_new_key[NIND_ALERT_MSG].st_value,buf);

 	if(fdstat == -1)
	    return;

	if(output_status_style)
	    output_to_status_proc(fdstat,adxc_new_key);
	  else
	    output_to_status_proc(fdstat,adxc_old_key);
  }

output_status(arg)
int	arg;
  {
	print_status(fdstat);
	enqueue_fcn(output_status,0,0.05);
  }
