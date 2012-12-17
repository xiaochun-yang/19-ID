#include	"ext.h"

		
/*
 *	Simple function which all the other code in this process calls
 *	to do an exit.  Here we can interdict and take care of any vital
 *	details making for a cleaner shutdown.
 */

void	cleanexit(status)
int	status;
  {
  	int		close(int fd);
  	
	if(command_s != -1)
	  {
		shutdown(command_s,2);
		close(command_s);
	  }
	if(data_s != -1)
	  {
		shutdown(data_s,2);
		close(data_s);
	  }
	if(sec_command_s != -1)
	  {
		shutdown(sec_command_s,2);
		close(sec_command_s);
	  }
	
	exit(0);
  }

void	wait_for_ret(char *s)
{
	char	line[20];

	fprintf(stdout,"Wait_for_ret: (%s).  Hit return to continue:\n",s);
	fgets(line,sizeof line,stdin);
}

void	handle_sigabrt(int arg)
{
	cleanexit(-1);
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
		fprintf(fplog,"det_api_socket: cannot create socket\n");
		fflush(fplog);
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
            fprintf(fplog,"ccd_dc: cannot set SO_KEEPALIVE socket option.\n");
            fflush(fplog);
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
            fprintf(fplog,"ccd_dc: cannot set SO_REUSEADDR socket option.\n");
            fflush(fplog);
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
		fprintf(fplog,"det_api_socket: cannot bind socket\n");
		fflush(fplog);
		return(-1);
	  }
	
	listen(server_s,MAX_CONTROLLERS);

	return(server_s);
  }

/*
 *	Main sequence of events for the ccd_det api.
 *
 *	arguments:
 *
 *	  ccd_det_api [-s -d dir -f fmt]
 *
 *	  -s 		Indicates a simulation run.
 *	  -d dir	Directory to obtain simulation images.
 *	  -f fmt	Format of simulation images ("mar" or "rect")
 */


int	main(int argc, char **argv)
{
	char	thishost[256];
	char	line[100];
	char	detector_db[100];
	char	*dbp;
	char	*cp;
	int 	pvec[MAX_CONTROLLERS];
	struct q_moddef qmodt[MAX_CONTROLLERS];
	int 	i,j,res;
	int 	msc_port_number;
	void	temperature_init();
	int 	ccd_powerupinit();
	int 	ccddet_init();
	int 	mserver_init();
	int	pa_modno, pa_lstart, pa_lend, pa_laddr, pa_lsize;
	char	pa_horv;
	static	char	*version_string = "V7.1.0";

	WORD    wVersionRequested;
	WSADATA wsaData;
	int     errwsastartup;

	fpout = stdout;
	fperr = stderr;

	signal(SIGABRT, handle_sigabrt);

	ccd_detector_type = CCD_TYPE_T2K;

	if(NULL != (cp = (char *) getenv("CCD_TYPE")))
	{
		if(0 == strcmp(cp, "EEV"))
			ccd_detector_type = CCD_TYPE_EEV;
	}

	switch(ccd_detector_type)
	{
		case CCD_TYPE_T2K:

			fprintf(stdout,"\tADSC T2K CCD Detector Control API %s Version\n\n",
				version_string);
			break;
		case CCD_TYPE_EEV:

			fprintf(stdout,"\tADSC EEV CCD Detector Control API %s Version\n\n",
				version_string);
			break;
	}

	if(NULL != (cp = (char *) getenv("CCD_WORKSTATION_VERBOSE")))
	{
		verbose = atoi(cp);
	}
		

	fprintf(stdout,"	Copyright 1997-2003 ADSC.  All Rights Reserved.\n\n");

	wVersionRequested = 0x0101;
	errwsastartup = WSAStartup(wVersionRequested, &wsaData);
	if(errwsastartup)
	{
        	fprintf(stdout,"det_api: error returned from WSAStartup\n");
		fflush(stdout);
        	exit(0);
	}


	ccd_use_mserver = 0;

	use_stored_dark = 0;
	use_loadfile = 0;
	det_api_module = 1;
	msc_port_number = -1;
	send_square = 0;
	control_dets = 1;
	diskbased = 0;
	strcpy(disk_dir, "");
	ccd_uniform_pedestal = 1500;

	/*
	 *	Establish reasonable defaults.
	 */
	
	if(NULL == (dbp = (char *) getenv("CCD_DETECTOR_DB")))
		strcpy(detector_db, DETECTOR_DB);
	else
		strcpy(detector_db, dbp);
	switch(ccd_detector_type)
	{
		case CCD_TYPE_T2K:

			if(control_dets == 0)
			{
				if(0 == (n_ctrl = get_moddb(qmod, MAX_CONTROLLERS, detector_db, 0)))
				{
					fprintf(stderr,"Hit return to continue db processing");
					fgets(line,sizeof line, stdin);
				}
			}
			else
			{
				if(0 == (n_ctrl = get_moddb(qmod, MAX_CONTROLLERS, detector_db, 1)))
				{
					fprintf(stderr,"Hit return to continue db processing");
					fgets(line,sizeof line, stdin);
				}
				mult_host_dbfd_setup();
			}
			break;

		case CCD_TYPE_EEV:

			if(control_dets == 0)
			{
				if(0 == (n_ctrl = get_moddb_eev(qmod, MAX_CONTROLLERS, detector_db, 0)))
				{
					fprintf(stderr,"Hit return to continue db processing");
					fgets(line,sizeof line, stdin);
				}
			}
			else
			{
				if(0 == (n_ctrl = get_moddb_eev(qmod, MAX_CONTROLLERS, detector_db, 1)))
				{
					fprintf(stderr,"Hit return to continue db processing");
					fgets(line,sizeof line, stdin);
				}
				mult_host_dbfd_setup();
			}
			break;
	}

	for(i = 0; i < MAX_CONTROLLERS; i++)
		pvec[i] = i;

	order_modules(qmod, n_ctrl, pvec);

	for(i = 0; i < n_ctrl; i++)
		qmodt[i] = qmod[pvec[i]];
	for(i = 0; i < n_ctrl; i++)
		qmod[i] = qmodt[i];
	for(i = 0; i < n_ctrl; i++)
		pv_bn[i] = qmod[i].q_bn;

	for(i = 0; i < n_ctrl; i++)
		if(control_dets == 0 && qmod[i].q_def == 1 && qmod[i].q_type != 2)
		{
			res = find_controller_info(qmod[i].q_serial, &qc[qmod[i].q_bn]);
			if(res == -1)
				fprintf(stdout,"warning: find_controller_info failed on serial %x\n",qmod[i].q_serial);
		}
		else	/* for virtual modules, fill in information in "qc" without probing hardware */
		{
			qc[qmod[i].q_bn].qc_type = qmod[i].q_type;
			qc[qmod[i].q_bn].qc_serial = qmod[i].q_serial;
			qc[qmod[i].q_bn].qc_te_gain = 0;
			qc[qmod[i].q_bn].qc_te_offset = 0;
			qc[qmod[i].q_bn].qc_te_tweak_b = 0.0;
			qc[qmod[i].q_bn].qc_te_tweak_m = 1.0;
			for(j = 0; j < 4; j++)
			{
				qc[qmod[i].q_bn].qc_offset[j] = 0;
				qc[qmod[i].q_bn].qc_gain[j] = 0;
			}
			
		}
	for(i = 0; i < n_ctrl; i++)
		if(qmod[i].q_def == 1)
			qmod[i].q_modno = which_module_number(qmod[i].q_assign);

	switch(ccd_detector_type)
	{
		case CCD_TYPE_T2K:

			print_moddb(qmod, MAX_CONTROLLERS);
			break;

		case CCD_TYPE_EEV:

			print_moddb_eev(qmod, MAX_CONTROLLERS);
			break;
	}

	if(n_ctrl == 0)
	{
		fprintf(stderr,"Number of controllers set to zero.\n");
		fprintf(stderr,"Error in database initialization.\n");
		cleanexit(0);
	}

	for(i = 0; i < MAX_CONTROLLERS; i++)
		chip_npatches[i] = 0;

	fpdiag = fopen("diagnostic.log","w");

	if(NULL != (cp = (char *) getenv("CCD_SEND_BUFSIZE")))
		ccd_send_bufsize = atoi(cp);
	else
		ccd_send_bufsize = -1;

	/*
	 *	The module database provides the host and port numbers for
	 *	this api.
	 */
	if(NULL == (cp = (char *) getenv("CCD_DTPORT")))
	{
		fprintf(stderr,"det_module: in control_dets=%d mode with no environment CCD_DTPORT\n",
				control_dets);

		cleanexit(0);
	}
	command_port_no = atoi(cp);
	fprintf(stderr,"det_module: control_det ON using command port: %d\n",command_port_no);

	(void) gethostname(thishost,sizeof thishost);
	sprintf(line,"det_api_%s.log",thishost);
	fplog = fopen(line,"w");
	if(NULL == fplog)
	{
		fprintf(stderr,"\n\nFATAL ERROR:  CANNOT CREATE LOGFILE %s\n", line);
		fprintf(stderr,"\nCHECK PERMISSIONS ON THE DIRECTORY WHERE THIS PROCESS IS RUN\n\n\n");
		fprintf(stderr,"PROGRAM EXITING\n");
		cleanexit(1);
	}

	switch(ccd_detector_type)
	{
		case CCD_TYPE_T2K:

			fprintf(fplog,"\tADSC T2K CCD Detector API %s MultiTaksing Version\n\n",
				version_string);
			break;
		case CCD_TYPE_EEV:

			fprintf(fplog,"\tADSC EEV CCD Detector API %s MultiTaksing Version\n\n",
				version_string);
			break;
	}

	fprintf(fplog ,"	Copyright 1997-2003 ADSC.  All Rights Reserved.\n\n");

	/*
	 *	Set up listener conditions for the command
	 *	and data ports.
	 *
	 *	Note: we do our own error checking on socket connection
	 *	      status and do not want the SIGPIPE signal to cause
	 *	      the process to exit.
	 */

	command_fd = -1;
	for(i = 0; i < n_ctrl; i++)
		data_fd[i] = -1;
	sec_command_fd = -1;
	if(-1 == (command_s = det_api_socket(command_port_no)))
		cleanexit(1);

	/*
	 *	Just process input commands
	 */

	process_input_control_dets();

	cleanexit(0);
		
}
