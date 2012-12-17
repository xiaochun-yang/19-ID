#include	"detcon_ext.h"

/*
 *	Module to handle the network connections for
 *	the data collection server.
 *
 *	First, detcon_server_init() is called to initialize
 *	the network handling code.
 *
 *	Second, detcon_server_update() is called at heartbeat
 *	to determine if a connection is requested.  If so,
 *	a notation is made for this socket and an accept is done.
 *
 *	All active sockets are tested for read select.
 *	A socket for which a connection has been accepted
 *	but for which no purpose has been established must
 *	first present:
 *
 *	connect <purpose>
 *
 *	where <purpose> is:
 *
 *		command
 *		output
 *		status
 *		xform
 *		det_cmd
 *		det_status
 *		bl_cmd
 *		bl_status
 *
 *	Once the purpose of the connection has been established,
 *	the usual file descriptors are prepared for this socket
 *	so that the rest of the code works properly.
 *
 *	Notations of socket connections which close or otherwise
 *	die are also made.
 */


/*
 *      Entries for network names, ports, etc.
 */

extern struct serverlist        dcserver;
extern struct serverlist        daserver;
extern struct serverlist        xfserver;
extern struct serverlist        stserver;
extern struct serverlist	dtserver;
extern struct serverlist	dtdserver;
extern struct serverlist	blserver;
extern struct serverlist        conserver;
extern struct serverlist        viewserver;
extern int                      ccd_communication;

#define	MAX_FDS		10

#define	COMMAND_ID	0
#define	OUTPUT_ID	1
#define	STATUS_ID	2
#define	XFORM_ID	3
#define	DET_CMD_ID	4
#define	DET_STATUS_ID	5
#define	BL_CMD_ID	6
#define	BL_STATUS_ID	7

static 	char	*connect_types[] = {
				"command",
				"output",
				"status",
				"bl_cmd",
				"bl_status",
				NULL
			    };
static 	int	connect_ids[] = {
			  COMMAND_ID,
			  OUTPUT_ID,
			  STATUS_ID,
			  BL_CMD_ID,
			  BL_STATUS_ID,
			  -1,
			};

static 	int	valid_fds[MAX_FDS];

static 	int	server_s = -1;

static 	int	connected_fds[MAX_FDS];

void	detcon_catch_sigpipe()
  {
	fprintf(stderr,"detcon_server: caught SIGPIPE signal\n");
  }

char	*detcon_timestamp(fp)
FILE	*fp;
  {
	long	clock;

	time(&clock);
	fprintf(fp,"timestamp: %s",(char *) ctime(&clock));
	fflush(fp);
  }

/*
 *	connect_to_host_api		connect to specified host & port.
 *
 *	Issue a connect to the specified host and port.  If the
 *	connection is sucessful, write the string (if non-null)
 *	msg over the socket.
 *
 *	If the operation is a sucess, returns the file descriptor
 *	for the socket via the fdnet pointer.  If this is -1, then
 *	the connection/message tranmission failed.
 *
 *	Also, returns the file descriptor if sucessful, otherwise
 *	-1.
 */

static	int	connect_to_host_api(fdnet,host,port,msg)
int	*fdnet;
char	*host;
int	port;
char	*msg;
  {
	int	s;
	struct	sockaddr_in	server;
	int	len;
	struct	hostent	*hentptr,hent;
	char	localmsg[256];

	hentptr = gethostbyname(host);
	if(hentptr == NULL)
	  {
	    fprintf(stderr,"connect_to_host_api: no hostentry for machine %s\n",host);
	    *fdnet = -1;
	    return(*fdnet);
	  }
	hent = *hentptr;

	if(0)	/* DEBUG */
	  fprintf(stdout,"connect_to_host_api: establishing network connection to host %s, port %d\n",host,port);

	if(-1 == (s = socket(AF_INET, SOCK_STREAM, 0)))
	  {
		perror("connect_to_host_api: socket creation");
	    	*fdnet = -1;
		return(*fdnet);
	  }

	server.sin_family = AF_INET;
	server.sin_addr = *((struct in_addr *) hent.h_addr);
	server.sin_port = htons(port);

	if(connect(s, (struct sockaddr *) &server,sizeof server) < 0)
	  {
		*fdnet = -1;
		close(s);
		return(*fdnet);
	  }
	if(0)	/* DEBUG */
	  fprintf(stdout,"connect_to_host_api: connection established with host on machine %s, port %d.\n",host,port);
	if(msg != NULL)
	  {
	    strcpy(localmsg,msg);
	    len = strlen(msg);
	    localmsg[len] = '\0';
	    if(len > 0)
	      {
	      len++;
	      if(len != write(s,msg,len))
		{
		  fprintf(stdout,"connect_to_host_api: failure writing connect string (%s) command to host.\n",msg);
		  *fdnet = -1;
		  close(s);
		  return(*fdnet);
		}
	      }
	  }

	*fdnet = s;
	return(*fdnet);
  }

/*
 *	Return 1 if the port has data, else 0.  Disconnects are discovered elsewhere.
 *	A disconnected port is marked as "done", i.e., 1.
 */

int	detcon_check_port_ready(fd)
int	fd;
  {
        fd_set  readmask, writemask, exceptmask;
        struct  timeval timeout;
        int     nb;
        char    buf[512];

        timeout.tv_sec = 0;
        timeout.tv_usec = 0;
        FD_ZERO(&readmask);
        FD_SET(fd,&readmask);
        nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
        if(nb == -1)
          {
                if(errno == EINTR)
                  {
                    return(0);             /* timed out */
                  }
                fprintf(stderr,"detcon_check_port_ready: select error (on %d).  Should never happen.\n",fd);
                detcon_timestamp(dtc_fplog);
                fprintf(dtc_fplog,"detcon_check_port_ready: select error (on %d).  Should never happen.\n",fd);
                fflush(dtc_fplog);
                perror("detcon_check_port_ready: select in dt_check_fd");
                detcon_cleanexit(0);
          }
        if(nb == 0)
          {
                return(0);         /* no data ready */
          }
        if(0 == FD_ISSET(fd,&readmask))
          {
                return(0);         /* no data ready*/
          }

        nb = recv(fd,buf,512,MSG_PEEK);
        if(nb == 0)
          {
                return(0);
          }
	return(1);
  }

/*
 *	This is to facilitate the discovery of disconnections.
 *
 *	For some purposes, like status and command, the disconnect
 *	of the remote process is discovered in a timely fashon.
 *
 *	This routine checks a connection like the transform command.
 *	In general, it should be a write only socket and written only
 *	occasionally.
 */

detcon_check_alive(key)
int	key;
  {
	fd_set	readmask, writemask, exceptmask;
	struct	timeval	timeout;
	int	nb;
	char	buf[512];

	if(valid_fds[key] == -1)
		return;

	timeout.tv_sec = 0;
	timeout.tv_usec = 0;
	FD_ZERO(&readmask);
	FD_SET(valid_fds[key],&readmask);
	nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	if(nb == -1)
	  {
		if(errno == EINTR)
		  {
		    enqueue_fcn(detcon_check_alive,key,5.0);
		    return;		/* timed out */
		  }
		fprintf(stderr,"detcon_server: select error (detcon_check_alive on %d).  Should never happen.\n",key);
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: select error (detcon_check_alive on %d).  Should never happen.\n",key);
		fflush(dtc_fplog);
		perror("detcon_server: select in detcon_check_alive");
		detcon_cleanexit(0);
	  }
	if(nb == 0)
	  {
		enqueue_fcn(detcon_check_alive,key,5.0);
		return;		/* timed out */
	  }
	if(0 == FD_ISSET(valid_fds[key],&readmask))
	  {
		enqueue_fcn(detcon_check_alive,key,5.0);
		return;		/* timed out */
	  }

	nb = recv(valid_fds[key],buf,512,MSG_PEEK);
	if(nb <= 0)
	  {
		detcon_notify_server_eof(valid_fds[key]);
		return;
	  }
	enqueue_fcn(detcon_check_alive,key,5.0);
  }
/*
 *	This is to facilitate the discovery of disconnections.
 *
 *	Used with other servers.
 *
 *	For some purposes, like status and command, the disconnect
 *	of the remote process is discovered in a timely fashon.
 *
 *	This routine checks a connection like the transform command.
 *	In general, it should be a write only socket and written only
 *	occasionally.
 */

detcon_check_alive_server(int key_p)
  {
	fd_set	readmask, writemask, exceptmask;
	struct	timeval	timeout;
	int	nb;
	char	buf[512];

	if(key_p == -1)
		return;

	timeout.tv_sec = 0;
	timeout.tv_usec = 0;
	FD_ZERO(&readmask);
	FD_SET(key_p,&readmask);
	nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	if(nb == -1)
	  {
		if(errno == EINTR)
		  {
		    enqueue_fcn(detcon_check_alive_server,key_p,5.0);
		    return;		/* timed out */
		  }
		fprintf(stderr,"detcon_server: select error (detcon_check_alive_server on %d).  Should never happen.\n",key_p);
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: select error (detcon_check_alive_server on %d).  Should never happen.\n",key_p);
		fflush(dtc_fplog);
		perror("detcon_server: select in detcon_check_alive_server");
		detcon_cleanexit(0);
	  }
	if(nb == 0)
	  {
		enqueue_fcn(detcon_check_alive_server,key_p,5.0);
		return;		/* timed out */
	  }
	if(0 == FD_ISSET(key_p,&readmask))
	  {
		enqueue_fcn(detcon_check_alive_server,key_p,5.0);
		return;		/* timed out */
	  }

	nb = recv(key_p,buf,512,MSG_PEEK);
	if(nb <= 0)
	  {
		detcon_notify_server_eof(key_p);
		return;
	  }
	enqueue_fcn(detcon_check_alive_server,key_p,5.0);
  }

detcon_server_init()
  {
	struct	sockaddr_in	from;
	int	i;
	int	optname,optval,optlen;

	signal(SIGPIPE,detcon_catch_sigpipe);
	dtc_fddetcmd = -1;
	dtc_fdxfcm = -1;

	for(i = 0; i < MAX_FDS; i++)
		connected_fds[i] = -1;
	for(i = 0; i < MAX_FDS; i++)
		valid_fds[i] = -1;

	if(-1 == (server_s = socket(AF_INET, SOCK_STREAM, 0)))
	  {
	  	detcon_timestamp(dtc_fplog);
		fprintf(stderr,"detcon_server: cannot create socket\n");
		fprintf(dtc_fplog,"detcon_server: cannot create socket\n");
		fflush(dtc_fplog);
		detcon_cleanexit(0);
	  }
	/*
	 *	Set the KEEPALIVE and RESUSEADDR socket options.
	 */
	
	optname = SO_KEEPALIVE;
	optval = 1;
	optlen = sizeof (int);

	if(-1 == setsockopt(server_s,SOL_SOCKET,optname,&optval,optlen))
	  {
	    detcon_timestamp(dtc_fplog);
	    fprintf(stderr,"detcon_server: cannot set SO_KEEPALIVE socket option.\n");
	    fprintf(dtc_fplog,"detcon_server: cannot set SO_KEEPALIVE socket option.\n");
	    fflush(dtc_fplog);
	    perror("detcon_server: setting SO_KEEPALIVE");
	    detcon_cleanexit(0);
	  }

	optname = SO_REUSEADDR;
	optval = 1;
	optlen = sizeof (int);

	if(-1 == setsockopt(server_s,SOL_SOCKET,optname,&optval,optlen))
	  {
	    detcon_timestamp(dtc_fplog);
	    fprintf(stderr,"detcon_server: cannot set SO_REUSEADDR socket option.\n");
	    fprintf(dtc_fplog,"detcon_server: cannot set SO_REUSEADDR socket option.\n");
	    fflush(dtc_fplog);
	    perror("detcon_server: setting SO_REUSEADDR");
	    detcon_cleanexit(0);
	  }

	from.sin_family = AF_INET;
	from.sin_addr.s_addr = htonl(INADDR_ANY);
	from.sin_port = htons(dcserver.sl_port);
	from.sin_port = htons(atoi((char *) getenv("DTC_DCPORT")));

	if(bind(server_s, (struct sockaddr *) &from,sizeof from))
	  {
		fprintf(stderr,"detcon_server: cannot bind socket\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: cannot bind socket\n");
		fflush(dtc_fplog);
		detcon_cleanexit(0);
	  }
	
	listen(server_s,5);
  }

detcon_check_other_servers()
  {
	if(dtc_fddetcmd == -1)
	  {
	    if(-1 != connect_to_host_api(&dtc_fddetcmd,dtserver.sl_hrname,dtserver.sl_port,NULL))
	      {
		fprintf(stderr,"detcon_server: connection established with hostname: %s with fd: %d for detector control\n",
			dtserver.sl_hrname,dtc_fddetcmd);
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection established with hostname: %s with fd: %d for detector control\n",
			dtserver.sl_hrname,dtc_fddetcmd);
		fflush(dtc_fplog);
		enqueue_fcn(detcon_check_alive_server,dtc_fddetcmd,1.0);
	      }
	  }
	if(dtc_fdxfcm == -1)
	  {
	    if(-1 != connect_to_host_api(&dtc_fdxfcm,xfserver.sl_hrname,xfserver.sl_port,NULL))
	      {
		fprintf(stderr,"detcon_server: connection established with hostname: %s with fd: %d for transform control\n",
			xfserver.sl_hrname,dtc_fdxfcm);
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection established with hostname: %s with fd: %d for transform control\n",
			xfserver.sl_hrname,dtc_fdxfcm);
		fflush(dtc_fplog);
		enqueue_fcn(detcon_check_alive_server,dtc_fdxfcm,1.0);
	      }
	  }
  }

detcon_notify_server_eof(fd)
int	fd;
  {
	int	i;

	for(i = 0; i < MAX_FDS; i++)
	  if(valid_fds[i] == fd)
		break;
	if(i == MAX_FDS)
	  {
	    if(fd == dtc_fdxfcm)
	      {
		close(dtc_fdxfcm);
		dtc_fdxfcm = -1;
		fprintf(stderr,"detcon_server: connection for transform command closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for transform command closed\n");
		fflush(dtc_fplog);
                dtc_dc_stop = 1;
                set_alert_msg(
                 "ERROR: Connection to transform program or CCD lost.");
		return;
	      }
	     else
	    if(fd == dtc_fddetcmd)
	      {
		close(dtc_fddetcmd);
		dtc_fddetcmd = -1;
		fprintf(stderr,"detcon_server: connection for ccd_det command closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for ccd_det command closed\n");
		fflush(dtc_fplog);
                dtc_dc_stop = 1;
                set_alert_msg("ERROR: Lost contact with CCD controller.");
		return;
	      }
	     else
	      {
	        fprintf(stderr,"detcon_server: weird descriptor (%d) given to detcon_notify_server_eof\n",fd);
	        detcon_timestamp(dtc_fplog);
	        fprintf(dtc_fplog,"detcon_server: weird descriptor (%d) given to detcon_notify_server_eof\n",fd);
	        fflush(dtc_fplog);
	        return;
	      }
	  }
	switch(i)
	  {
	    case COMMAND_ID:
		close(dtc_fdcom);
		dtc_fdcom = -1;
		fprintf(stderr,"detcon_server: connection for command closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for command closed\n");
		fflush(dtc_fplog);
		break;
	    case OUTPUT_ID:
		close(dtc_fdout);
		fclose(dtc_fpout);
		dtc_fdout = -1;
		dtc_fpout = NULL;
		fprintf(stderr,"detcon_server: connection for output closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for output closed\n");
		fflush(dtc_fplog);
		break;
	    case STATUS_ID:
		close(dtc_fdstat);
		dtc_fdstat = -1;
		fprintf(stderr,"detcon_server: connection for status closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for status closed\n");
		fflush(dtc_fplog);
		break;
	    case XFORM_ID:
		close(dtc_fdxfcm);
		dtc_fdxfcm = -1;
		fprintf(stderr,"detcon_server: connection for transform command closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for transform command closed\n");
		fflush(dtc_fplog);
                dtc_dc_stop = 1;
                set_alert_msg(
                 "ERROR: Connection to transform program or CCD lost.");
		break;
	    case DET_CMD_ID:
		close(dtc_fddetcmd);
		dtc_fddetcmd = -1;
		fprintf(stderr,"detcon_server: connection for ccd_det command closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for ccd_det command closed\n");
		fflush(dtc_fplog);
                dtc_dc_stop = 1;
                set_alert_msg("ERROR: Lost contact with CCD controller.");
		break;
	    case DET_STATUS_ID:
		close(dtc_fddetstatus);
		dtc_fddetstatus = -1;
		fprintf(stderr,"detcon_server: connection for ccd_det status closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for ccd_det status closed\n");
		fflush(dtc_fplog);
		break;
	    case BL_CMD_ID:
		close(dtc_fdblcmd);
		dtc_fdblcmd = -1;
		fprintf(stderr,"detcon_server: connection for ccd_bl command closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for ccd_bl command closed\n");
		fflush(dtc_fplog);
		break;
	    case BL_STATUS_ID:
		close(dtc_fdblstatus);
		dtc_fdblstatus = -1;
		fprintf(stderr,"detcon_server: connection for ccd_bl status closed\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection for ccd_bl status closed\n");
		fflush(dtc_fplog);
                dtc_dc_stop = 1;
                set_alert_msg("Beam Line Control connection DROPPED.");
		break;
	    default:
		break;
	  }
	valid_fds[i] = -1;
	for(i = 0; i < MAX_FDS; i++)
	  if(connected_fds[i] == fd)
	    {
		connected_fds[i] = -1;
		break;
	    }
  }

detcon_server_update(arg)
int	arg;
  {
	struct	sockaddr_in	from;
	int 	g;
	int	len;
	char	buf[512],string1[512],string2[512];
	int	nb;
	int	i,j,k;
	fd_set	readmask, writemask, exceptmask;
	struct	timeval	timeout;
	int	got_valid;
	int	bufindex,ii,jj;
	int	connection_terminated;

	timeout.tv_sec = 0;
	timeout.tv_usec = 0;

	got_valid = -1;

	/*
	 *	Select for read the server socket + any
	 *	file descriptors which have been accepted
	 *	for connection but NOT validated.
	 */

	FD_ZERO(&readmask);
	FD_SET(server_s,&readmask);
	for(i = 0; i < MAX_FDS; i++)
	  if(connected_fds[i] != -1)
	    {
	      for(j = 0, k = -1; j < MAX_FDS; j++)
		if(connected_fds[i] == valid_fds[j])
		  {
		    k = j;
		    break;
		  }
	      if(k == -1)	/* connected but not validated */
		FD_SET(connected_fds[i],&readmask);
	    }
	nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	if(nb == -1)
	  {
		fprintf(stderr,"detcon_server: select error.  Should never happen.\n");
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: select error.  Should never happen.\n");
		fflush(dtc_fplog);
		perror("detcon_server: select");
		detcon_cleanexit(0);
	  }
	if(nb == 0)
	  {
		detcon_check_other_servers();
		enqueue_fcn(detcon_server_update,0,1.0);
		return;		/* timed out */
	  }
	    
	/*
	 *	There is something to do.  If the listener socket is ready for read,
	 *	perform an accept on it.  If one of the others is ready to read, get
	 *	the data and output it to the screen.
	 */
	if(FD_ISSET(server_s,&readmask))
	  {
	    len = sizeof from;
	    g = accept(server_s, (struct sockaddr *) &from, &len);

	    if(g < 0)
	      {
	        if(errno != EINTR)
	          {
		    fprintf(stderr,"detcon_server: accept error for network connection\n");
		    detcon_timestamp(dtc_fplog);
		    fprintf(dtc_fplog,"detcon_server: accept error for network connection\n");
		    fflush(dtc_fplog);
		    perror("accept");
		    detcon_cleanexit(0);
	          }
	      }
	     else
	      {
		fprintf(stderr,"detcon_server: connection accepted from: %s with fd: %d\n",inet_ntoa(from.sin_addr), g);
		detcon_timestamp(dtc_fplog);
		fprintf(dtc_fplog,"detcon_server: connection accepted from: %s with fd:\n",inet_ntoa(from.sin_addr), g);
		fflush(dtc_fplog);
		for(i = 0, j = -1; i < MAX_FDS; i++)
		  if(connected_fds[i] == -1)
		    {
			connected_fds[i] = g;
			j = 0;
			break;
		    }
		if(j == -1)
		  {
		    fprintf(stderr,"detcon_server: all %d connection slots used up.\n",MAX_FDS);
		    detcon_timestamp(dtc_fplog);
		    fprintf(dtc_fplog,"detcon_server: all %d connection slots used up.\n",MAX_FDS);
		    fflush(dtc_fplog);
		    detcon_cleanexit(0);
		  }
	      }
	  }
	for(i = 0; i < MAX_FDS; i++)
	  if(connected_fds[i] != -1)
	    {
	      if(FD_ISSET(connected_fds[i],&readmask))
	        {
		  connection_terminated = 0;
		  for(bufindex = 0; ;)
		    {
		      nb = read(connected_fds[i],&buf[bufindex],sizeof buf);
		      if(nb <= 0)
		        {
			  if(errno == EINTR)
				continue;
		          fprintf(stderr,"detcon_server: unvalidated connection terminated by client on fd: %d\n",connected_fds[i]);
			  detcon_timestamp(dtc_fplog);
		          fprintf(dtc_fplog,"detcon_server: unvalidated connection terminated by client on fd: %d\n",connected_fds[i]);
			  fflush(dtc_fplog);
			  if(nb < 0)
			    {
			      fprintf(stderr,"detcon_server: error returned on unvalidated connection termination:\n");
			      perror("detcon_server: unvalidated connection termination:");
			    }
			   else
			      fprintf(stderr,"detcon_server: EOF on unvalidated connection termination.\n");
		          close(connected_fds[i]);
		          connected_fds[i] = -1;
			  connection_terminated = 1;
		          break;
		        }
		      bufindex += nb;
		      for(ii = 0, jj = 0; ii < bufindex; ii++)
			if(buf[ii] == '\0')
				jj = 1;
		      if(jj == 1)
			break;
		    }
		  if(connection_terminated == 1)
			continue;
		  string1[0] = '\0'; string2[0] = '\0';
		  sscanf(buf,"%s%s",string1,string2);
		  if(0 != strcmp(string1,"connect"))
		    {
		      fprintf(stderr,"detcon_server: incorrect connection protocal on fd %d: %s\n",connected_fds[i],buf);
		      detcon_timestamp(dtc_fplog);
		      fprintf(dtc_fplog,"detcon_server: incorrect connection protocal on fd %d: %s\n",connected_fds[i],buf);
		      fflush(dtc_fplog);
		      close(connected_fds[i]);
		      connected_fds[i] = -1;
		      continue;
		    }
		  for(j = 0; connect_types[j] != NULL; j++)
		    if(0 == strcmp(string2,connect_types[j]))
		        break;
		  if(connect_types[j] == NULL)
		    {
		      fprintf(stderr,"detcon_server: incorrect connection protocal on fd %d: %s\n",connected_fds[i],buf);
		      detcon_timestamp(dtc_fplog);
		      fprintf(dtc_fplog,"detcon_server: incorrect connection protocal on fd %d: %s\n",connected_fds[i],buf);
		      fflush(dtc_fplog);
		      close(connected_fds[i]);
		      connected_fds[i] = -1;
		      continue;
		     }
		   if(valid_fds[connect_ids[j]] != -1)
		     {
		       fprintf(stderr,"detcon_server: This is a second connection for purpose %s which is not allowed:\n",string2);
		       fprintf(stderr,"        The original connection must be terminated first.\n");
		       fprintf(stderr,"        Connection on fd %d is refused.\n",connected_fds[i]);
		       fprintf(dtc_fplog,"detcon_server: This is a second connection for purpose %s which is not allowed:\n",string2);
		       fprintf(dtc_fplog,"        The original connection must be terminated first.\n");
		       fprintf(dtc_fplog,"        Connection on fd %d is refused.\n",connected_fds[i]);
		       fflush(dtc_fplog);
		       close(connected_fds[i]);
		       connected_fds[i] = -1;
		       continue;
		     }
		   valid_fds[connect_ids[j]] = connected_fds[i];
		   got_valid = connect_ids[j];
		   fprintf(stderr,"detcon_server: connection validated for %s on fd %d\n",string2,connected_fds[i]);
		   detcon_timestamp(dtc_fplog);
		   fprintf(dtc_fplog,"detcon_server: connection validated for %s on fd %d\n",string2,connected_fds[i]);
		   fflush(dtc_fplog);
		}
	    }
	/*
	 *	Clean up some details in case we got a new valid
	 *	connection.
	 */

	switch(got_valid)
	  {
	    case COMMAND_ID:
		dtc_fdcom = valid_fds[got_valid];
		break;
	    case OUTPUT_ID:
		dtc_fdout = valid_fds[got_valid];
		dtc_fpout = fdopen(dtc_fdout,"r+");
		break;
	    case STATUS_ID:
		dtc_fdstat = valid_fds[got_valid];
		break;
	    case XFORM_ID:
		dtc_fdxfcm = valid_fds[got_valid];
		enqueue_fcn(detcon_check_alive,XFORM_ID,1.0);
		break;
	    case DET_CMD_ID:
		dtc_fddetcmd = valid_fds[got_valid];
		enqueue_fcn(detcon_check_alive,DET_CMD_ID,1.0);
		break;
	    case DET_STATUS_ID:
		dtc_fddetstatus = valid_fds[got_valid];
		enqueue_fcn(detcon_check_alive,DET_STATUS_ID,1.0);
		break;
	    case BL_CMD_ID:
		dtc_fdblcmd = valid_fds[got_valid];
		enqueue_fcn(detcon_check_alive,BL_CMD_ID,1.0);
		break;
	    case BL_STATUS_ID:
		dtc_fdblstatus = valid_fds[got_valid];
		enqueue_fcn(detcon_check_alive,BL_STATUS_ID,1.0);
		break;
	    default:
		break;
	  }
	detcon_check_other_servers();
	enqueue_fcn(detcon_server_update,0,1.0);
	return;		/* timed out */
  }

detcon_cleanexit(status)
int	status;
  {
	fprintf(stderr,"detcon_server: shutting down with status %d\n",status);
	if(server_s != -1)
	  {
		shutdown(server_s,2);
		close(server_s);
	  }
	/*
	 *	Always exit with good status. (No one cares about the exit status; why cause problesm?)
	 */
#ifdef VMS
	exit(1);
#else
	exit(0);
#endif /* VMS */
  }
