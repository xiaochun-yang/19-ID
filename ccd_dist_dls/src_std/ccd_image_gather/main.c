#include	"ext.h"

/*
 *	Simple function which all the other code in this process calls
 *	to do an exit.  Here we can interdict and take care of any vital
 *	details making for a cleaner shutdown.
 */

void	cleanexit(status)
int	status;
  {
	fprintf(stderr,"ccd_xform_api: shutting down with status %d\n",status);

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
	exit(0);
  }

/*
 *	Catch the sigpipe signal but don't take any action.
 */

void	catch_sigpipe()
  {
	fprintf(stderr,"ccd_xform_api: caught SIGPIPE signal\n");
	notify_server_eof(command_fd);
  }

/*
 *	Catch the sigpipe signal but don't take any action.
 */

void	catch_sighup()
  {
	fprintf(stderr,"ccd_xform_api: caught SIGHUP signal.\n");
	fprintf(stderr,"ccd_xform_api: Exiting normally.\n");
	cleanexit(0);
  }

/*
 *	Simple timestamp.
 */

void	timestamp(fp)
FILE    *fp;
  {
        int    clock;

        time(&clock);
        fprintf(fp,"timestamp: %s",(char *) ctime(&clock));
        fflush(fp);
  }

/*
 *	This function establishes a listening socket end on TCP/IP
 *	port number port_no.
 *
 *	Function returns a valid descriptor for this socket on sucess,
 *	failure is indicated by messages and a -1 return.
 */

int	api_socket(int	port_no)
  {
	struct	sockaddr_in	from;
	int	optname,optval,optlen;
	int	server_s;

	if(-1 == (server_s = socket(AF_INET, SOCK_STREAM, 0)))
	  {
	  	timestamp(fplog);
		fprintf(stderr,"api_socket: cannot create socket\n");
		fprintf(fplog,"api_socket: cannot create socket\n");
		fflush(fplog);
		return(-1);
	  }
	/*
	 *	Set the KEEPALIVE and RESUSEADDR socket options.
	 */
	
	optname = SO_KEEPALIVE;
	optval = 1;
	optlen = sizeof (int);

	if(-1 == setsockopt(server_s,SOL_SOCKET,optname,&optval,optlen))
	  {
	    timestamp(fplog);
	    fprintf(stderr,"api_socket: cannot set SO_KEEPALIVE socket option.\n");
	    fprintf(fplog,"api_socket: cannot set SO_KEEPALIVE socket option.\n");
	    fflush(fplog);
	    perror("api_socket: setting SO_KEEPALIVE");
	    return(-1);
	  }

	optname = SO_REUSEADDR;
	optval = 1;
	optlen = sizeof (int);

	if(-1 == setsockopt(server_s,SOL_SOCKET,optname,&optval,optlen))
	  {
	    timestamp(fplog);
	    fprintf(stderr,"api_socket: cannot set SO_REUSEADDR socket option.\n");
	    fprintf(fplog,"api_socket: cannot set SO_REUSEADDR socket option.\n");
	    fflush(fplog);
	    perror("api_socket: setting SO_REUSEADDR");
	    return(-1);
	  }

	from.sin_family = AF_INET;
	from.sin_addr.s_addr = htonl(INADDR_ANY);
	from.sin_port = htons(port_no);

	if(bind(server_s, (struct sockaddr *) &from,sizeof from))
	  {
		fprintf(stderr,"api_socket: cannot bind socket\n");
		timestamp(fplog);
		fprintf(fplog,"api_socket: cannot bind socket\n");
		fflush(fplog);
		return(-1);
	  }
	
	listen(server_s,5);

	return(server_s);
  }

usage(fp)
FILE	*fp;
  {
	fprintf(stderr,"Usage: ccd_xform_api [-sa]\n");
	return;
  }


/*
 *	Main sequence of events for the ccd_xform api.
 *
 *	arguments:
 *			-sa	standalone
 */


int	main(int argc, char **argv)
  {
	int 	check_environ();
	int 	dynamic_init();
	int 	n;
	char	*cptr;
	char	det_dbname[256];
	char	buf[256];

	fpout = stdout;
	fperr = stderr;
	standalone = 0;
	input_images = 0;
	reply_to_sender = 0;		/* should be default */

	sprintf(buf,"%s/ccd_image_gather.log",getenv("HOME"));
	if(NULL == (fpg = fopen(buf,"a+")))
	{
		fprintf(stderr,"ccd_image_gather: WARNING: log file %s could not be created\n",buf);
	}
	/*
	 *	Establish reasonable defaults.
	 */
	
	initial_defaults();

	/*
	 *	Obtain environment information, which
	 *	may also override defaults established above.
	 *
	 *	If 1 is returned, there was a major problem
	 *	(like no network port numbers specified).
	 */
	
	if(check_environ())
		cleanexit(1);
	
	/*
	 *	Set up listener conditions for the command
	 *	and data ports.
	 *
	 *	Note: we do our own error checking on socket connection
	 *	      status and do not want the SIGPIPE signal to cause
	 *	      the process to exit.
	 */
	
	signal(SIGPIPE, catch_sigpipe);	
	signal(SIGHUP, catch_sighup);	

	command_fd = -1;

	if(-1 == (command_s = api_socket(command_port_no)))
		cleanexit(1);
	
	/*
	 *	Set up dynamic objects.
	 */
	if(NULL == (cptr = (char *) getenv("CCD_DETECTOR_DB")))
		strcpy(det_dbname, cptr);
	else
		strcpy(det_dbname, "detector_db.txt");
	n_ctrl = get_moddb(qm, MAX_CONTROLLERS, cptr, 1);

	for(n = 0; n < n_ctrl; n++)
		data_fd[n] = -1;

	if(dynamic_init())
		cleanexit(1);

	/*
	 *	Process input.
	 */
	
	process_input();

	/*
	 *	If process_input actually returns, an "exit" has been sent
	 *	to the process.  It's actually useful to have a way to do
	 *	this other than just killing the program, especially if this
	 *	is on a PC.
	 */

	cleanexit(0);
  }
