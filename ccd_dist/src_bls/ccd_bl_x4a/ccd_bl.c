#include	"ccd_bl_ext.h"

/*
 *	Pohang PAL Version
 *
 *	Drives Compumotor 6K based goniostat system for the 
 *	BL4A High Flux Macromolecular Crystallography end station.
 */

/*
 *      Entries for network names, ports, etc.
 */

char	dchostname[256];
int		dcport;

void    catch_sigpipe()
{
        fprintf(stderr,"%s: caught SIGPIPE signal\n",pgmname);
}

void    catch_sighup()
{
        fprintf(stderr,"%s: caught SIGHUP signal.\n",pgmname);
	fprintf(stderr,"%s: Performing Clean Up Before Exiting Procedure.\n",pgmname);
	cm_cleanupforexit();
	cleanexit(0);
}

int 	string_found(buf,idex,ss)
char	*buf;
int		idex;
char	*ss;
{
	int		i,j,lss,bss;

	lss = strlen(ss);
	bss = idex - lss + 1;

	for(i = 0; i < bss ; i++)
	{
		for(j = 0; j < lss; j++)
			if(ss[j] != buf[i + j])
				break;
		if(j == lss)
			return(i);
	}
	return(-1);
}


/*
 *	This function establishes a listening socket end on TCP/IP
 *	port number port_no.
 *
 *	Function returns a valid descriptor for this socket on sucess,
 *	failure is indicated by messages and a -1 return.
 */

int	det_api_socket(int	port_no)
  {
	struct	sockaddr_in	from;
	int					server_s;
#ifdef unix
        int     optname,optval,optlen;
#endif /* unix */

	if(-1 == (server_s = socket(AF_INET, SOCK_STREAM, 0)))
	  {
		fprintf(stdout,"det_api_socket: cannot create socket\n");
		fflush(stdout);
		return(-1);
	  }

#ifdef unix
        /*
         *      Set the KEEPALIVE and RESUSEADDR socket options.
         */

        optname = SO_KEEPALIVE;
        optval = 1;
        optlen = sizeof (int);

        if(-1 == setsockopt(server_s,SOL_SOCKET,optname,&optval,optlen))
          {
            fprintf(stdout,"ccd_dc: cannot set SO_KEEPALIVE socket option.\n");
			fflush(stdout);
            perror("ccd_dc: setting SO_KEEPALIVE");
            cleanexit(0);
          }
        optname = SO_REUSEADDR;
        optval = 1;
        optlen = sizeof (int);

        if(-1 == setsockopt(server_s,SOL_SOCKET,optname,&optval,optlen))
          {
            fprintf(stdout,"ccd_dc: cannot set SO_REUSEADDR socket option.\n");
			fflush(stdout);
            perror("ccd_dc: setting SO_REUSEADDR");
            cleanexit(0);
          }
#endif /* unix */


	from.sin_family = AF_INET;
	from.sin_addr.s_addr = htonl(INADDR_ANY);
	from.sin_port = htons((unsigned short) port_no);

	if(bind(server_s, (struct sockaddr *) &from,sizeof from))
	  {
		fprintf(stdout,"det_api_socket: cannot bind socket\n");
		fflush(stdout);
		return(-1);
	  }
	
	listen(server_s, 5);

	return(server_s);
  }

/*
 *	Check for connection.  Return -1 if nothing pending, else return the
 *	accepted file descriptor.
 */

int	check_for_connection(int fd)
  {
	struct	sockaddr_in	from;
	int 	g;
	int		len;
	int		nb;
	fd_set	readmask;
	struct	timeval	timeout;

	timeout.tv_sec = 0;
	timeout.tv_usec = 0;

	/*
	 *	Select for read the requested server socket
	 */

	FD_ZERO(&readmask);
	FD_SET(fd,&readmask);
	nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	if(nb == -1)
	  {
	  	if(errno == EINTR)
			return(-1);
		fprintf(stderr,"ccd_det_api: check_for_connection:: select error.  Should never happen.\n");
		perror("ccd_det_api: check_for_connection:: select");
		cleanexit(0);
	  }
	if(nb == 0)
		return(-1);		/* nothing trying to connect */
	    
	/*
	 *	There is something to do.  If the listener socket is ready for read,
	 *	perform an accept on it.  If one of the others is ready to read, get
	 *	the data and output it to the screen.
	 */
	if(FD_ISSET(fd,&readmask))
	  {
	    len = sizeof from;
	    g = accept(fd, (struct sockaddr *) &from, &len);

	    if(g < 0)
	      {
	        if(errno != EINTR)
	          {
		    	fprintf(stderr,
		    		"ccd_det_api: check_for_connection:: accept error for network connection\n");
		    	perror("accept");
		    	cleanexit(0);
	          }
	      }
	  }
	return(g);
  }
/*
 *	Client process to process beam line requests from ccd_dc.
 *
 *	Sufficient internal buffering exists to store multiple
 *	command requests.
 */

char	blbuf[10240];		/* holds the entire beamline buffer */
char	blubuf[1024];		/* actually gets passed to the user */
int		blindex;

char	*looking_for = "end_of_bl\n";

int 	main(int argc, char *argv[])
{
	int 	i,j,eobuf;
	int 	looklen;
	int 	maxlen;
	fd_set	readmask;
	FILE	*fp;
	char	line[100];
	char	*cp, *ttyname;
	int 	ret;
	int 	returned_status;
	char	retbuf[256];
	struct timeval	timeout;
	int 	blport, blsport, directport;
	extern	int	in_manual;

#ifdef WINNT

	WORD    wVersionRequested;
	WSADATA wsaData;
	int     errwsastartup;

	wVersionRequested = 0x0101;
	errwsastartup = WSAStartup(wVersionRequested, &wsaData);
	if(errwsastartup)
	{
		fprintf(stdout,"ccd_bl_x4a: error returned from WSAStartup\n");
		fflush(stdout);
		cleanexit(0);
	}

	_fmode = O_BINARY;

	if(NULL == (fp = fopen("detector_env.txt", "r")))
	{
		fprintf(stderr,"WARNING: detector_env.txt not found\n");
	}
	else
	{
		while(NULL != fgets(line,sizeof line, fp))
		{
			if(line[0] == '#')
				continue;
			for(i = 0; line[i] != '\0'; i++)
				if(line[i] == '\n' || line[i] == '\r')
					line[i] = '\0';
			if(line[0] == '\0' || line[0] == '\n')
				continue;
			putenv(line);
		}
		fclose(fp);
	}
#endif /* WINNT */

#ifdef unix
	signal(SIGPIPE,catch_sigpipe);
	signal(SIGHUP,catch_sighup);
#endif /* unix */

	fdcom    = -1;
	fdstat   = -1;
	fddirect = -1;

	strcpy(pgmname, argv[0]);

	/*
	 *	Set up initial values for status.
	 */

	near_limit_value = 75.02;               /* MEASURED FOR X4A */
	far_limit_value = 674.00;               /* MEASURED FOR X4A - VALUE IS MAX DISTANCE + 2MM */

	far_home_value = (float) (far_limit_value - 2); /* DETECTOR WILL REST 2MM BACK AFTER HOMING = 672MM FOR X4A */

	near_2theta_limit_value = (float) -0.344;
	far_2theta_limit_value = (float) 42.67;

	stat_start_phi = 0.0;
	stat_osc_width = 0.0;
	stat_n_passes = 1;
	stat_time = 0.0;
	stat_intensity = 0.0;
	stat_max_count = 0;
	stat_dir[0] = '\0';
	stat_fname[0] = '\0';
	strcpy(stat_scanner_op,"idle");
	stat_scanner_msg[0] = '\0';
	stat_scanner_control[0] = '\0';
	strcpy(stat_scanner_shutter,"closed");
	stat_n_mdc_updates = 0;
	stat_mode = 0;
	stat_adc = 0;
	stat_bin = 1;
	stat_wavelength = -1;
	stat_lift = 0.0;
	mdc_alert[0] = '\0';
	dist_steps_mm = 1;
	stat_z = 0.0;
	stat_stat = 1;
	returned_to_user[0] = '\0';
	command_in_progress = -1;

	input_socket_time_grain = 50000;
	ion_check_interval = 2000000;
	ion_check_accumulator = 0;

	if(NULL == (cp = (char *) getenv("CCD_DCHOSTNAME")))
	{
		fprintf(stderr,"ccd_bl_x4a: Error: CCD_DCHOSTNAME environ undefined\n");
		cleanexit(0);
	}

	strcpy(dchostname, cp);

	if(NULL == (cp = (char *) getenv("CCD_DCPORT")))
	{
		fprintf(stderr,"ccd_bl_x4a: Error: CCD_DCPORT environ undefined\n");
		cleanexit(0);
	}

	dcport = atoi(cp);

	if(NULL == (cp = (char *) getenv("CCD_BLPORT")))
	{
		fprintf(stderr,"ccd_bl_x4a: Error CCD_BLPORT (new requirement) not defined\n");
		cleanexit(0);
	}

	blport = atoi(cp);

	if(-1 == (command_s = det_api_socket(blport)))
	{
		perror("det_api_socket for command_s on blport");
		cleanexit(1);
	}

	if(NULL == (cp = (char *) getenv("CCD_BLSTATPORT")))
	{
		fprintf(stderr,"ccd_bl_x4a: Error CCD_BLSTATPORT (new requirement) not defined\n");
		cleanexit(0);
	}

	blsport = atoi(cp);

	if(-1 == (status_s = det_api_socket(blsport)))
	{
		perror("det_api_socket for status_s on blsport");
		cleanexit(1);
	}

	if(NULL == (cp = (char *) getenv("CCD_BLDIRECTPORT")))
	{
		fprintf(stderr,"ccd_bl_x4a: WARNING: CCD_BLDIRECTPORT environment variable NOT set.\n");
		fprintf(stderr,"               OK for operation, but connections from local beamline control disabled.\n");
		direct_s = -1;
	}
	else
	{
		directport = atoi(cp);
		if(-1 == (direct_s = det_api_socket(directport)))
		{
			fprintf(stderr,"ccd_bl_x4a: WARNING: CANNOT establish server port for local beamline control.\n");
			fprintf(stderr,"               OK for operation, but connections from local beamline control disabled.\n");
		}
	}

	if(NULL == (cp = (char *) getenv("LOCAL_CONTROL_HOST")))
	{
		fprintf(stderr,"ccd_bl_x4a: WARNING: LOCAL_CONTROL_HOST environment variable NOT set.\n");
		fprintf(stderr,"               OK for operation, but WAVELENGTH/ENERGY control disabled.\n");
		local_control_port = -1;
	}
	else
	{
		strcpy(local_control_host, cp);
		if(NULL == (cp = (char *) getenv("LOCAL_CONTROL_PORT")))
		{
			fprintf(stderr,"ccd_bl_x4a: WARNING: LOCAL_CONTROL_PORT environment variable NOT set.\n");
			fprintf(stderr,"               OK for operation, but WAVELENGTH/ENERGY control disabled.\n");
			local_control_port = -1;
		}
		else
			local_control_port = atoi(cp);
	}

	looklen = strlen(looking_for);
	maxlen = sizeof blbuf;
	blindex = 0;
	fprintf(stdout,"ccd_bl_x4a: Initializing goniostat.\n");

	if(NULL == (ttyname = (char *) getenv("CCD_KAPPA_TTY")))
	{
		fprintf(stdout,"ccd_bl_x4a: Environment name CCD_KAPPA_TTY NOT found.\n");
		fprintf(stdout,"\tThis is the tty port name to which the goniostat tty is connected.\n");
		cleanexit(0);
	}

	if(-1 == cm_init(ttyname))
	{
		fprintf(stdout,"ccd_bl_x4a: ERROR initializing goniostat tty.\n");
		cleanexit(0);
	}

	ccd_bl_generic_init();

	cm_setomega(stat_omega);
	cm_setdistance(stat_dist);

	cm_get_slits();

	cm_set_halfslit(0, 0, 0);
	cm_set_halfslit(0, 1, 0);
	cm_set_halfslit(1, 0, 0);
	cm_set_halfslit(1, 0, 0);

	stat_xl_up_hhs = 0;
	stat_xl_up_vhs = 0;
	stat_xl_dn_hhs = 0;
	stat_xl_dn_vhs = 0;

	if(local_control_port != -1)
	{
		double  wavelength_temp;

		int i = get_junk();
		if(0 == get_current_wavelength_from_control(&wavelength_temp))
			stat_wavelength = wavelength_temp;
	}

	while(1)
	{
		if(fdcom == -1)
		{
			if(-1 != (fdcom = check_for_connection(command_s)))
			{
				fprintf(stderr,"ccd_bl_x4a   : connection for command accepted (fd: %d)\n",
					fdcom);
			}
			else
			{
				Sleep(1000);
				continue;
			}
		}
		if(fdstat == -1)
		{
			if(-1 != (fdstat = check_for_connection(status_s)))
			{
				fprintf(stderr,"ccd_bl_x4a   : connection for status accepted (fd: %d)\n",
					fdstat);
			}
			else
			{
				Sleep(1000);
				continue;
			}
		}
		if(fddirect == -1 && direct_s != -1)
		{
			if(-1 != (fddirect = check_for_connection(direct_s)))
			{
				fprintf(stderr,"ccd_bl_x4a   : connection for direct local beamline control accepted (fd: %d)\n",
					fdstat);
				direct_communications(fddirect);
				fprintf(stderr,"ccd_bl_x4a   : connection for direct local beamline control CLOSED (fd: %d)\n",
					fdstat);
				close(fddirect);
				fddirect = -1;
			}
		}

		FD_ZERO(&readmask);
		FD_SET(fdcom,&readmask);
		timeout.tv_usec = input_socket_time_grain;
		timeout.tv_sec = 0;
		ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
		send_status();
		if(0 == ret && 0 == in_manual)
		{
			/*
			 *	Read out the ion chambers when there is no data collection
			 *	request immediately pending (when the select times out).
			 *	This way we don't delay data collection for ion readout.
			 *
			 *	Do this read whenever we've accumulated ion_check_interval's
			 *	amount of idle time.
			 */
			
			ion_check_accumulator += input_socket_time_grain;
			if(ion_check_accumulator > ion_check_interval)
			{
				/*
				 *      Drain all input in the goniostat tty device before executing a command.
				 */
                                                                                                                                              
				while(-1 != cmreadraw_drain(20));

				if(1)
				{
					ion_check_accumulator = 0;
					cm_get_ion_all(stat_ion);
					stat_intensity = stat_ion[2];
					stat_xl_ion_beam = stat_intensity;
					stat_xl_ion_up = stat_ion[0];
					stat_xl_ion_dn = stat_ion[1];
				}
				if(1)
					cm_get_slits();
				if(1)
					cm_getmotval_gonio(1);
				if(1)
					send_status();			/* send status with new ion readings */
			}
			continue;
		}
		if(ret == -1)
		{
			if(errno == EINTR)
			{
				/*
				 *	Read out the ion chambers when there is no data collection
				 *	request immediately pending (when the select times out).
				 *	This way we don't delay data collection for ion readout.
				 *
				 *	Do this read whenever we've accumulated ion_check_interval's
				 *	amount of idle time.
				 */
				
				ion_check_accumulator += input_socket_time_grain;
				if(ion_check_accumulator > ion_check_interval)
				{
					/*
					 *      Drain all input in the goniostat tty device before executing a command.
					 */
                                                                                                                                              
					while(-1 != cmreadraw_drain(20));

					if(1)
					{
						ion_check_accumulator = 0;
						cm_get_ion_all(stat_ion);
						stat_intensity = stat_ion[2];
						stat_xl_ion_beam = stat_intensity;
						stat_xl_ion_up = stat_ion[0];
						stat_xl_ion_dn = stat_ion[1];
					}
					if(1)
						cm_get_slits();
					if(1)
						cm_getmotval_gonio(1);
					if(1)
						send_status();			/* send status with new ion readings */
				}
				continue;	/* interrupted system calls are OK. */
			}

			fprintf(stderr,"ccd_bl: Error returned from select call\n");
			/*
			 *	use to be:
			 *	cleanexit(0);
			 */
			continue;
		}
		if(0 == FD_ISSET(fdcom,&readmask))
			continue;
		ret = recv(fdcom,&blbuf[blindex],maxlen - blindex, 0);
		if(ret == -1 || ret == 0)
		{
			if(errno == EINTR)
				continue;		/* Interrupted system calls are OK */

			fprintf(stderr,"ccd_bl: ERROR on beamline socket.\n");
			fprintf(stderr,"ccd_bl: Waiting for new connection\n");
			closesocket(fdcom);
			fdcom = -1;
			fprintf(stderr,"ccd_bl: Closing down status socket as well.\n");
			closesocket(fdstat);
			fdstat = -1;
			continue;

		}

		blindex += ret;
		if(-1 != (eobuf = string_found(blbuf,blindex,looking_for)))
		{
			eobuf += looklen;
			for(i = 0; i < eobuf; i++)
				blubuf[i] = blbuf[i];
			blubuf[eobuf] = '\0';

			if(1)
			{
				fprintf(stdout,"ccd_bl_x4a: command received:\n%s", blubuf);
				fflush(stdout);
			}
			/*
			 *	The beamline control string has been received.
			 *
			 *	Call the local beamline control module to perform
			 *	desired action, if necessary.
			 */

			returned_status = local_beamline_control(blubuf);

			/*
			 *	On return, ack ccd_dc so it can continue.
			 */
			switch(returned_status)
			{
				case 0:
					sprintf(retbuf,"OK\n%s",looking_for);
					break;

				case 1:
					sprintf(retbuf,"RETRY\n%s",looking_for);
					break;

				case 2:
					sprintf(retbuf,"ERROR\n%s",looking_for);
					break;
			}
			if(returned_to_user[0] != '\0')
			{
				if(strlen(returned_to_user) != (unsigned int) send(fdcom,returned_to_user,strlen(returned_to_user), 0))
					fprintf(stderr,"ccd_bl_x4a: error writing return_to_user string %s\n",returned_to_user);

			}
			returned_to_user[0] = '\0';

			if(strlen(retbuf) != (unsigned int) send(fdcom,retbuf,strlen(retbuf), 0))
				fprintf(stderr,"ccd_bl_x4a: error writing acknowledge string %s\n",retbuf);

			for(i = eobuf, j = 0; i < blindex; i++, j++)
				blbuf[j] = blbuf[i];
			blindex -= eobuf;
		}
	}
}

int		check_abort_command()
{
	int		eobuf;
	int		maxlen;
	fd_set	readmask;
	int		ret;
	char	abortbuf[256];
	int		abortind;
	struct timeval	timeout;

	maxlen = 256;
	abortind = 0;


	FD_ZERO(&readmask);
	FD_SET(fdcom,&readmask);
	timeout.tv_usec = 500000;
	timeout.tv_sec = 0;
	ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);

	if(ret == 0)
		return(0);
	if(ret == -1)
	{
		if(errno == EINTR)
			return(0);	/* interrupted system calls are OK. */

		fprintf(stderr,"ccd_bl: Error returned from select call\n");
		return(0);
	}
	if(0 == FD_ISSET(fdcom,&readmask))
		return(0);
	ret = recv(fdcom,&abortbuf[0],maxlen, MSG_PEEK);
	if(ret == -1)
	{
			if(errno == EINTR)
				return(0);		/* Interrupted system calls are OK */

			return(0);
	}
	if(ret == 0)
	{
		return(0);
	}

	abortind += ret;

	if(abortind > 0)
	{
		fprintf(stdout,"Abort command in buffer:\n");
		fwrite(abortbuf, sizeof (char), abortind, stdout);
		fflush(stdout);
	}

	
	if(-1 != (eobuf = string_found(abortbuf,abortind,"abort")))
	{
		/*
		 *	Abort sequence has been located.  Execute
		 *	local abort command.
		 */
		fprintf(stderr,"ccd_bl_gen: ABORT SEEN while operation is in progress.\n");

		return(1);

    }
	return(0);
}

/*
 *	This stuff is experimental.
 */

#ifdef WINNT

HANDLE	abort_thread_handle;
int		abort_thread_arg;


void	scan_for_abort_thread(void *arg)
{
	void	cm_abort();

	while(1)
	{
		if(check_abort_command())
			cm_abort();
	}
}

void	scan_for_abort()
{
	fprintf(stdout,"ccd_bl_x4a: scan_for_abort: ENABLED\n");
	abort_thread_handle = (HANDLE) _beginthread(scan_for_abort_thread, 0, &abort_thread_arg);
}

void	stop_abort_thread()
{
	fprintf(stdout,"ccd_bl_x4a: STOP abort thread\n");
	TerminateThread(abort_thread_handle, 0);
}

#else /* end WINNT, begin unix part */

void	scan_for_abort()
{
}

#endif /* unix part */

/*
 *	This code is used to read the abort string when present
 *	in the input.  It should be the case that the ONLY time
 *	an "extra" command is queued while a real command is executed
 *	is when "abort" is issued.  This function below drains the
 *	socket.
 */

void	read_abort_command()
{
  int	eobuf;
  int	maxlen;
  fd_set	readmask;
  int	ret;
  char	retbuf[256];
  char	abortbuf[256];
  int	abortind;
  struct timeval	timeout;

  maxlen = 256;
  abortind = 0;

  while(1)
    {
      FD_ZERO(&readmask);
      FD_SET(fdcom,&readmask);
      timeout.tv_usec = 0;
      timeout.tv_sec = 1;
      ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
      send_status();
      if(ret == 0)
	continue;
      if(ret == -1)
	{
	  if(errno == EINTR)
	    continue;	/* interrupted system calls are OK. */

	  fprintf(stderr,"ccd_bl: Error returned from select call\n");
	  cleanexit(0);
	}
      if(0 == FD_ISSET(fdcom,&readmask))
	continue;
      ret = recv(fdcom,&abortbuf[abortind],maxlen - abortind, 0);
      if(ret == -1)
	{
	  if(errno == EINTR)
	    continue;		/* Interrupted system calls are OK */

	  fprintf(stderr,"ccd_bl: ERROR on beamline socket.\n");
	  perror("ccd_bl: read beamline socket");
	  fprintf(stderr,"ccd_bl: ccd_dc server has probably terminated.\n");
	  fprintf(stderr,"ccd_bl: program exiting.\n");
	  cleanexit(0);
	}
      if(ret == 0)
	{
	  fprintf(stderr,"ccd_bl: EOF on beamline socket connection.\n");
	  fprintf(stderr,"ccd_bl: ccd_dc server has probably terminated.\n");
	  fprintf(stderr,"ccd_bl: program exiting.\n");
	  cleanexit(0);
	}

      abortind += ret;
      if(-1 != (eobuf = string_found(abortbuf,abortind,looking_for)))
	{
	  /*
	   *	Abort sequence has been located.  Execute
	   *	local abort command.
	   */
	  fprintf(stderr,"ccd_bl_gen: ABORT SEEN while operation is in progress.\n");

	  sprintf(retbuf,"OK\n%s",looking_for);
	  if(strlen(retbuf) != (unsigned int) send(fdcom,retbuf,strlen(retbuf), 0))
	    fprintf(stderr,"ccd_bl: error writing acknowledge string %s\n",retbuf);
	  fprintf(stderr,"ccd_bl_gen: REPLIED to abort.\n");
	  return;
	}
    }
}

void	cleanexit(int status)
{

	if(fdcom != -1)
	{
		shutdown(fdcom,2);
		closesocket(fdcom);
	}
	if(fdstat != -1)
	{
		shutdown(fdstat,2);
		closesocket(fdstat);
	}
	exit(status);
}
