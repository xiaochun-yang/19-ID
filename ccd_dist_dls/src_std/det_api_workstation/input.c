#include	"ext.h"

/*
 *	This module handles input.  It initiates action when a complete
 *	command is present without errors.
 */


/*
 *	read_port_raw:
 *
 *		Read data until there is none left.  Don't block.
 */

int		read_port_raw(int fd,char *stbuf,int stbufsize)
  {
	int				nread;
	fd_set			readmask;
	int				ret;
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
	    ret = recv(fd,stbuf + nread,stbufsize - nread,0);
	    if(ret == -1)
	      {
			if(errno == EINTR)
		  	continue;	/* Ignore interrupted system calls */
			notify_server_eof(fd);
			return(-1);
	      }
	    if(ret == 0)
	      {
			notify_server_eof(fd);
			return(-1);
	      }
	    nread += ret;
	  }
  }
  
int		check_port_raw(int fd)
  {
	fd_set			readmask;
	int				ret;
	struct timeval	timeout;

	FD_ZERO(&readmask);
	FD_SET(fd,&readmask);
	timeout.tv_usec = 0;
	timeout.tv_sec = 1;
	ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	if(ret == 0)
		return(0);
	if(ret == -1)
	  {
	    if(errno == EINTR)
		    return(0);		/* Ignore interrupted system calls */
		  else
		  	return(-1);
	  }
	 return(1);
  }

int     probe_port_raw(int fd)
  {
        fd_set                  readmask;
        int                             ret;
        struct timeval  timeout;
        char                    cbuf;

        FD_ZERO(&readmask);
        FD_SET(fd,&readmask);
        timeout.tv_usec = 10000;
        timeout.tv_sec = 0;
        ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
        if(ret == 0)
                return(0);
        if(ret == -1)
          {
            if(errno == EINTR)
                    return(0);          /* Ignore interrupted system calls */
                  else
                        return(-1);
          }
         if(1 != recv(fd,&cbuf,1,MSG_PEEK))
                return(-1);
          else
                return(1);
  }

int     probe_port_raw_with_timeout(int fd, int nmicrosecs)
  {
        fd_set                  readmask;
        int                             ret;
        struct timeval  timeout;
        char                    cbuf;
	int			nsec;

	nsec = nmicrosecs / 1000000;
	nmicrosecs -= (nsec * 1000000);

        FD_ZERO(&readmask);
        FD_SET(fd,&readmask);
        timeout.tv_usec = nmicrosecs;
        timeout.tv_sec = nsec;
        ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
        if(ret == 0)
                return(0);
        if(ret == -1)
          {
            if(errno == EINTR)
                    return(0);          /* Ignore interrupted system calls */
                  else
                        return(-1);
          }
         if(1 != recv(fd,&cbuf,1,MSG_PEEK))
                return(-1);
          else
                return(1);
  }

/*
 *	Function to do a write, with possible multiple chunks.
 *	We need this because of unknown buffering over the network.
 *
 *	The write blocks.
 *
 *	Returns the number of characters written, or -1 if an error.
 */

int	rep_write(int fd, char *buf, int count)
  {
	char huge	*pos;
	int			remcount,i;

	if(count == 0)
		return(0);

	pos = buf;
	remcount = count;

	while(remcount > 0)
	  {
		i = send(fd,pos,remcount,0);
		if(i < 0)
		  {
		    fprintf(fplog,"rep_write: Error (%d) on file descriptor %d\n",errno,fd);
		    fflush(fplog);
		    perror("rep_write");
		    return(-1);
		  }
		remcount -= i;
		pos += i;
	  }
	return(count);
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
		fprintf(fplog,"ccd_det_api: check_for_connection:: select error.  Should never happen.\n");
		fflush(fplog);
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
		    	fprintf(fplog,
		    		"ccd_det_api: check_for_connection:: accept error for network connection\n");
		    	fflush(fplog);
		    	perror("accept");
		    	cleanexit(0);
	          }
	      }
	  }
	return(g);
  }

/*
 *	notify_server_eof
 *
 *	Clean up details when someone closes a connection to this
 *	server (which is fine and allowed).
 */

void	notify_server_eof(int	fd)
{
	int 	n;

	if(fd == command_fd)
	{
		fprintf(stderr,"ccd_det_api: connection for command closed at time:\n");
		fprintf(fplog,"ccd_det_api: connection for command closed at time:\n");
		close(command_fd);
		command_fd = -1;
	}
	if(fd == sec_command_fd)
	{
		fprintf(stderr,"ccd_det_api: connection for second command closed at time:\n");
		fprintf(fplog,"ccd_det_api: connection for second command closed at time:\n");
		close(sec_command_fd);
		sec_command_fd = -1;
	}
	for(n = 0; n < n_ctrl; n++)
		if(fd == data_fd[n])
		{
			fprintf(stderr,"ccd_det_api: connection for data socket %d closed at time:\n",n);
			fprintf(fplog, "ccd_det_api: connection for data socket %d closed at time:\n",n);
			close(data_fd[n]);
			data_fd[n] = -1;
		}
}

#define CCD_DET_OK              0
#define CCD_DET_RETRY           1
#define CCD_DET_FATAL           2
#define CCD_DET_NOTCONNECTED    3
#define CCD_DET_DISCONNECTED    4

static int	fddetcmd[MAX_CONTROLLERS];

#if defined(sun) || defined(linux)

/*
 *	Code to handle non-sys5 itimer/sleep behavior.  See ccd_dc_bl.c
 */

static	int	dt_ready;
static	int	dt_fd_to_check;

static	int	dt_check_fd()
  {
        fd_set  readmask;
        struct  timeval timeout;
        int     nb;
        char    buf[512];

        timeout.tv_sec = 0;
        timeout.tv_usec = 100000;
        FD_ZERO(&readmask);
        FD_SET(dt_fd_to_check,&readmask);
        nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
        if(nb == -1)
          {
                if(errno == EINTR)
                  {
                    return(0);             /* timed out */
                  }
                fprintf(stderr,"dt_check_fd: select error (on %d).  Should never happen.\n",dt_fd_to_check);
                fprintf(fplog,"dt_check_fd: select error (on %d).  Should never happen.\n",dt_fd_to_check);
                fflush(fplog);
                perror("dt_check_fd: select in dt_check_fd");
                cleanexit(0);
          }
        if(nb == 0)
          {
                return(0);         /* timed out */
          }
        if(0 == FD_ISSET(dt_fd_to_check,&readmask))
          {
                return(0);         /* timed out */
          }

        nb = recv(dt_fd_to_check,buf,512,MSG_PEEK);
        if(nb <= 0)
          {
                return(0);
          }
	dt_ready = 1;
	return(1);
  }
#endif /* sun or linux */

/*
 *	Handle communication to/from detector control process.
 */

/*
 *	Output a detector command line.
 *
 *	If the descriptor is not defined, forget it.  If the
 *	beam line command buffer does not contain anything for
 *	this run, don't output anything.
 *
 *	This causes a stall in the execution of ccd_dc.  The
 *	status should continue to update while this occurs.
 */

static	char	det_outbuf1[20480];
static	char	det_reply_single1[2048];
static	char	det_reply1[2048];

static	int	output_detcmd_single(fd,detcmd,hdptr,hdsize, reply_mode)
int	fd;
char	*detcmd;
char	*hdptr;
int	hdsize;
  {
	char	tbuf[512],temp_xx[512],*retstr;
	int		i,len,ret,detret;
	char	*ztime();

	detret = CCD_DET_OK;
	retstr = "normal";

	if(reply_mode == 2)
		goto get_reply;
	if(fd == -1)
		return(CCD_DET_NOTCONNECTED);

	if(detcmd[0] == '\0')
		return(CCD_DET_OK);

	strcpy(det_outbuf1,detcmd);

	temp_xx[0] = '\0';
	sscanf(det_outbuf1,"%s",temp_xx);
	if(0)
	  fprintf(stderr,"output_detcmd: sending:\n==========\n%s===========\n",det_outbuf1);
	fprintf(stderr,"output_detcmd: SENT          at %s: %s (%3d) %8d\n",ztime(),temp_xx,fd, timeGetTime());

	len = strlen(det_outbuf1);
	for(i = 0; i < hdsize; i++,len++)
	    det_outbuf1[len] = hdptr[i];

	ret = rep_write(fd,det_outbuf1,len);
	if(ret <= 0)
	  {
	        notify_server_eof(fd);
	        return(CCD_DET_DISCONNECTED);
	  }

	if(reply_mode == 1)
		return(detret);

get_reply:

	/*
	 *	Now check the socket for data present.
	 */

#if defined(sun) || defined(linux)
        dt_ready = 0;
        dt_fd_to_check = fd;
        while(dt_ready == 0)
	  {
		dt_check_fd();
		if(dt_ready == 0)
			clock_heartbeat();
	  }
#endif /* sun or linux*/

	ret = read_until(fd,det_reply_single1,sizeof det_reply_single1,detterm);

	if(ret <= 0)
	  {
	        notify_server_eof(fd);
	        return(CCD_DET_DISCONNECTED);
	  }

	sscanf(det_reply_single1,"%s",tbuf);
	if(0)
	  fprintf(stderr,"output_detcmd: ccd_det returned: %s\n",tbuf);
	if(0 == strcmp("RETRY1",tbuf))
	  {
		detret = CCD_DET_RETRY;
		retstr = "retry ";
          }
        else if(0 == strcmp("RETRY2",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry ";
          }
        else if(0 == strcmp("RETRY3",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry ";
          }
        else if(0 == strcmp("RETRY",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry ";
	  }
	 else
	  {
	    if(0 == strcmp("ERROR",tbuf))
	      {
		detret = CCD_DET_FATAL;
		retstr = "fatal ";
	      }
	  }
	if(verbose)
		fprintf(stderr,"output_detcmd: DONE (%s) at %s: %s (%3d) %8d\n",retstr,ztime(),temp_xx, fd, timeGetTime());
	return(detret);
  }

/*
 *	Modifications below have been made to support the "abort" call.  This call looks at
 *	ccd_state, and depending on it, completes an exposure and throws away the result or
 *	ignores the call.  This way an abort can be issued from high level code without actually
 *	knowing the state of the CCD detector.
 */

static	int 	output_detcmd(fd_array,detcmd,hdptr,hdsize)
int 	fd_array[];
char	*detcmd;
char	*hdptr;
int 	hdsize;
  {
  	int	rets[MAX_CONTROLLERS];
	int	any_error,n;
	extern	int 	q_issync[MAX_CONTROLLERS];
	int	stop_begin_time, stop_end_time;
	int	start_begin_time, start_end_time;
	int	get_begin_time, get_end_time;

	det_reply[0] = '\0';	/* to concat each reply */

	if((NULL != (char *) strstr(detcmd, "stop\n")) || (NULL != (char *) strstr(detcmd, "abort\n")))
	{
		if(ccd_state != STATE_ACCUM)
		{
			if(NULL != (char *) strstr(detcmd, "stop\n"))
			{
				fprintf(stderr,"output_detcmd: TIME (ERR!) at %s: stop : NO EXPOSURE IN PROGRESS\n",
					ztime());
				fprintf(stderr,"output_detcmd: TIME (ERR!) at %s: stop : NO STOP.\n",
					ztime());
			}
			else
			{
				fprintf(stderr,"output_detcmd: TIME (info) at %s: abort: NO EXPOSURE was in progress\n",
					ztime());
				fprintf(stderr,"output_detcmd: TIME (info) at %s: abort: no action was taken.\n",
					ztime());
			}
		}
		else
		{
		/*
		 *	Output a getparam to all framegrabbers.  This makes sure they are all
		 *	ready to do the "stop" at the same time.
		 */

		ccd_state = STATE_IDLE;		/* not strictly true, but it's not accumulating anymore */

		get_begin_time = timeGetTime();
		for(n = 0 ; n < q_ncon; n++)
			rets[n] = output_detcmd_single(fd_array[n], "getparam\nmode\nend_of_det\n", NULL, 0, 1);
		for(n = 0 ; n < q_ncon; n++)
			rets[n] = output_detcmd_single(fd_array[n], "getparam\nmode\nend_of_det\n", NULL, 0, 2);
		get_end_time = timeGetTime();
		fprintf(stderr,"output_detcmd: TIME (%s) at %s: extra     %5.3f secs.\n",
				" info ",ztime(),(get_end_time - get_begin_time) / 1000.);
		/*
		 *	Output the the stopw to all framegrabbers.  This will initiate the
		 *	readout sequence, but not wait for the readout.  Do this in the
		 *	reverse order so the master gets the readout start last.
		 *
		 *	Also be aware that the master might NOT be module 0, or in the loweest
		 *	numbered q_blocks[...].  Use q_issync to tell if a block has a master.
		 *
		 *	5/03: check return of all slave modules before sending stopr to the
		 *	master module.
		 */
		stop_begin_time = timeGetTime();
  		for(n = q_ncon - 1; n >= 0; n--)
			if(q_issync[n] == 0)
			{
		  		rets[n] = output_detcmd_single(fd_array[n], "stopr\nend_of_det\n", NULL, 0, 1);
			}
  		for(n = q_ncon - 1; n >= 0; n--)
			if(q_issync[n] == 0)
			{
		  		rets[n] = output_detcmd_single(fd_array[n], "stopr\nend_of_det\n", NULL, 0, 2);
				strcat(det_reply, det_reply_single);
			}
  		for(n = q_ncon - 1; n >= 0; n--)
			if(q_issync[n] == 1)
			{
		  		rets[n] = output_detcmd_single(fd_array[n], "stopr\nend_of_det\n", NULL, 0, 1);
			}
  		for(n = q_ncon - 1; n >= 0; n--)
			if(q_issync[n] == 1)
			{
		  		rets[n] = output_detcmd_single(fd_array[n], "stopr\nend_of_det\n", NULL, 0, 2);
				strcat(det_reply, det_reply_single);
			}

		/*
		 *	Now readout has begun on all framegrabbers, wait for the
		 *	data in the usual way, master first (which probably does not
		 *	matter).
		 */

  		for(n = 0; n < q_ncon; n++)
		{
			rets[n] = output_detcmd_single(fd_array[n], "stopw\nend_of_det\n", NULL, 0, 1);
		}

  		for(n = 0; n < q_ncon; n++)
		{
			rets[n] = output_detcmd_single(fd_array[n], "stopw\nend_of_det\n", NULL, 0, 2);
			strcat(det_reply, det_reply_single);
		}
		stop_end_time = timeGetTime();
		fprintf(stderr,"output_detcmd: TIME (%s) at %s: stop  %5.3f secs.\n",
				" info ",ztime(),(stop_end_time - stop_begin_time) / 1000.);
		if(NULL != (char *) strstr(detcmd, "abort\n"))
		{
			fprintf(stderr,"output_detcmd: TIME (%s) at %s: abort finished\n",
				" info ",ztime());
			fprintf(stderr,"output_detcmd: TIME (%s) at %s: issue reset to all framegrabbers.\n",
				" info ",ztime());
			for(n = 0; n < q_ncon; n++)
				output_detcmd_single(fd_array[n], "reset\nend_of_det\n", NULL, 0, 0);
		}
		}
	}
	else if(NULL != (char *) strstr(detcmd,"start\n"))
	{
		if(ccd_state != STATE_IDLE)
		{
			fprintf(stderr,"output_detcmd: TIME (ERR!) at %s: start: EXPOSURE ALREADY IN PROGRESS\n",
				ztime());
			fprintf(stderr,"output_detcmd: TIME (ERR!) at %s: start: NO EXPOSURE BEGUN.\n",
				ztime());

			/*
			 *	This is a bit of a mess; the only thing to do is try to get a stop to
			 *	compliment this; we don't want to signal an error.
			 */

			for(n = 0; n < q_ncon; n++)
	    			rets[n] = CCD_DET_OK;
		}
		else
		{
		ccd_state = STATE_ACCUM;
		start_begin_time = timeGetTime();
  		for(n = q_ncon - 1; n >= 0; n--)
			if(q_issync[n] == 0)
			{
				rets[n] = output_detcmd_single(fd_array[n], detcmd, NULL, 0, 1);
				strcat(det_reply, det_reply_single);
			}
  		for(n = q_ncon - 1; n >= 0; n--)
			if(q_issync[n] == 1)
			{
				rets[n] = output_detcmd_single(fd_array[n], detcmd, NULL, 0, 1);
				strcat(det_reply, det_reply_single);
			}
  		for(n = q_ncon - 1; n >= 0; n--)
			if(q_issync[n] == 0)
			{
				rets[n] = output_detcmd_single(fd_array[n], detcmd, NULL, 0, 2);
				strcat(det_reply, det_reply_single);
			}
  		for(n = q_ncon - 1; n >= 0; n--)
			if(q_issync[n] == 1)
			{
				rets[n] = output_detcmd_single(fd_array[n], detcmd, NULL, 0, 2);
				strcat(det_reply, det_reply_single);
			}
		start_end_time = timeGetTime();
		fprintf(stderr,"output_detcmd: TIME (%s) at %s: start %5.3f secs. for %s\n",
				" info ",ztime(),(start_end_time - start_begin_time) / 1000., ccd_info);
		}
	}
	else if(NULL != (char *) strstr(detcmd,"flush\n"))
	{
		/*
		 *	Output the the flushb to all framegrabbers.  This will initiate the
		 *	flush sending, but not wait for the send to complete.
		 */
  		for(n = q_ncon - 1; n >= 0; n--)
		{
			rets[n] = output_detcmd_single(fd_array[n], "flushb\nend_of_det\n", NULL, 0, 0);
			strcat(det_reply, det_reply_single);
		}

		/*
		 *	Now sending has begun on all framegrabbers, wait for the
		 *	data in the usual way.
		 */

  		for(n = 0; n < q_ncon; n++)
		{
			rets[n] = output_detcmd_single(fd_array[n], "flushe\nend_of_det\n", NULL, 0, 0);
			strcat(det_reply, det_reply_single);
		}
	}
	else if(NULL != (char *) strstr(detcmd,"timesync\n"))
	{
		/*
		 *	Output to each framegrabber AND this program (which is why this
		 *	command is trapped here).	
		 */

		sync_timers();

  		for(n = 0; n < q_ncon; n++)
		{
			rets[n] = output_detcmd_single(fd_array[n], "timesync\nend_of_det\n", NULL, 0, 0);
			strcat(det_reply, det_reply_single);
		}
	}
	else
	{
		/*
		 *	Since each detector process will parse and get the header
		 *	in the input stream if it is there, we always set the
		 *	header size to zero and pass NULL thru to hdptr.
		 */

  		for(n = 0; n < q_ncon; n++)
		{
			rets[n] = output_detcmd_single(fd_array[n], detcmd, NULL, 0, 0);
			strcat(det_reply, det_reply_single);
		}
	}

	/*
	 *	Return the worst of the errors.
	 *
	 *	Before doing this, it's important to notify the other detector
	 *	processes, if any, which did NOT receive errors to invalidate their
	 *	last data acquisition (otherwise, they attempt to transmit the data
	 *	to the transform).
	 */
	
	any_error = 0;
	for(n = 0; n < q_ncon; n++)
	    if(rets[n] != CCD_DET_OK)
	    	any_error = 1;

	if(any_error)
	  {
	  	/*
		 *	notify any other detector processes which did NOT
		 *	return an error to invalidate the last data.
		 */
		for(n = 0; n < q_ncon; n++)
			if(rets[n] == CCD_DET_OK)
				output_detcmd_single(fd_array[n], "reset\nend_of_det\n", NULL, 0, 0);

		ccd_state = STATE_IDLE;
	  }
	for(n = 0; n < q_ncon; n++)
	  if(rets[n] == CCD_DET_FATAL)
	  	return(rets[n]);
	
	for(n = 0; n < q_ncon; n++)
	  if(rets[n] == CCD_DET_RETRY)
	  	return(rets[n]);
	
	return(CCD_DET_OK);
  }

/*
 *	Main input processing routine.
 */

void	process_input_control_dets()
  {
	int 	nbytes,nbytes_pri,nbytes_sec;
	int 	res;
	int 	n, ii;
	char	*cp, *cp1, *cp3, *cp4;
	int 	input_hsize, remaining;
	int 	fd_used;
	char	*tptr;
	int 	read_until(int fd, char *buf, int size, char *term);
        int 	connect_to_host_api(int *fdnet,char *host,int port,char *msg);
        void	reply_cmd(char *reply, char *info,int fd_used);


	inbufind = 0;
	command_number = -1;
	processing_command = 0;

	for(n = 0; n < q_ncon; n++)
		fddetcmd[n] = -1;

	while(1)
	{
	    /*
	     *	If we don't have connections, try to establish.
	     */
            if(command_fd == -1)
              {
                if(-1 != (command_fd = check_for_connection(command_s)))
                  {
                    tptr = ztime();
                    fprintf(stderr,"ccd_det_api   : at %s: connection for command accepted (fd: %d)\n",
                                                        tptr,command_fd);
                    fprintf(fplog,"ccd_det_api   : at %s: connection for command accepted (fd: %d)\n",
                                                        tptr,command_fd);
                    fflush(fplog);
                  }
              }
             else
              {
                if(-1 == probe_port_raw(command_fd))
                  {
                    tptr = ztime();
                    fprintf(stderr,"ccd_det_api   : at %s: connection for command terminated (fd: %d)\n",
                                                        tptr,command_fd);
                    fprintf(fplog,"ccd_det_api   : at %s: connection for command terminated (fd: %d)\n",
                                                        tptr,command_fd);
					close(command_fd);
                    command_fd = -1;
                  }
              }
	    if(0)
	    {
            if(sec_command_fd == -1)
              {
                if(-1 != (sec_command_fd = check_for_connection(sec_command_s)))
                  {
                    tptr = ztime();
                    fprintf(stderr,"ccd_det_api   : at %s: connection for second command accepted (fd: %d)\n",
                                                        tptr,sec_command_fd);
                    fprintf(fplog,"ccd_det_api   : at %s: connection for second command accepted (fd: %d)\n",
                                                        tptr,sec_command_fd);
                    fflush(fplog);
                  }
              }
             else
              {
                if(-1 == probe_port_raw(sec_command_fd))
                  {
                    tptr = ztime();
                    fprintf(stderr,"ccd_det_api   : at %s: connection for second command terminated (fd: %d)\n",
                                                        tptr,sec_command_fd);
                    fprintf(fplog,"ccd_det_api   : at %s: connection for second command terminated (fd: %d)\n",
                                                        tptr,sec_command_fd);
					close(sec_command_fd);
                    sec_command_fd = -1;
                  }
              }
	    }
	    for(n = 0; n < q_ncon; n++)
	      if(fddetcmd[n] == -1)
              {
                if(-1 != connect_to_host_api(&fddetcmd[n],q_hostnames[n],q_ports[n],NULL))
                  {
                    tptr = ztime();
                    fprintf(stderr,"ccd_det_api   : at %s: connection for detector process %d accepted (fd: %d)\n",
                                                        tptr,n,fddetcmd[n]);
                    fprintf(fplog ,"ccd_det_api   : at %s: connection for detector process %d accepted (fd: %d)\n",
                                                        tptr,n,fddetcmd[n]);
                    fflush(fplog);
                  }
              }
             else
              {
                if(-1 == probe_port_raw(fddetcmd[n]))
                  {
                    tptr = ztime();
                    fprintf(stderr,"ccd_det_api   : at %s: connection for detector process %d terminated (fd: %d)\n",
                                                        tptr,n,fddetcmd[n]);
                    fprintf(fplog ,"ccd_det_api   : at %s: connection for detector process %d terminated (fd: %d)\n",
                                                        tptr,n,fddetcmd[n]);
		    close(fddetcmd[n]);
                    fddetcmd[n] = -1;
                  }
              }


	    /*
	     *	If we don't have a command connection, sleep and try again.
	     */
	    if(command_fd == -1 && sec_command_fd == -1)
	      {
			Sleep(1000);
			continue;
	      }
	    /*
	     *	Try to read some data from the command socket.  If none is present, sleep
	     *	and try again.
	     */
	    nbytes_pri = 0;
		nbytes_sec = 0;
		if(command_fd != -1)
			nbytes_pri = read_port_raw(command_fd,&inbuf[inbufind],INBUFSIZE - inbufind);
		else if(sec_command_fd != -1)
			nbytes_sec = read_port_raw(sec_command_fd,&inbuf[inbufind],INBUFSIZE - inbufind);

		if(nbytes_pri > 0 || nbytes_sec > 0)
		{
			if(nbytes_pri > 0)
			{
				nbytes = nbytes_pri;
				fd_used = command_fd;
			}
			else
			{
				nbytes = nbytes_sec;
				fd_used = sec_command_fd;
			}
			inbufind += nbytes;
			inbuf[inbufind] = '\0';
			if(NULL == (char *) strstr(inbuf, detterm))
			{
				/*
				 *	If an incomplete piece of a command comes through on one
				 *	socket, we must read that one to completion now.
				 */
				res = read_until(fd_used, &inbuf[inbufind], INBUFSIZE - inbufind, detterm);
				inbufind += res;
		        	if(res <= 0)
		        	{
		        		notify_server_eof(fd_used);
					continue;
				}
			}
			if(NULL != (char *) strstr(inbuf, "start\n"))
			{
				if(0)
				  fprintf(stdout,"START FOUND: buffer: \n%s\n",inbuf);
				cp1 = (char *) strstr(inbuf, detterm);
				cp1 += strlen(detterm);
				if(NULL != (cp = (char *) strstr(inbuf, "header_size")))
				{
					sscanf(cp + strlen("header_size") + 1, "%d", &input_hsize);
					remaining = input_hsize + (cp1 - &inbuf[0]) - inbufind;
					while(remaining > 0)
					{
						if(0)
						  fprintf(stdout,"control_det_input short read, need %d more\n", remaining);
						res = read(fd_used, &inbuf[inbufind], remaining);
						if(0)
						  fprintf(stdout,"control_det_input: received %d more bytes\n", res);
						if(res == -1)
						{
							continue;
						}
						inbufind += res;
						inbuf[inbufind] = '\0';
						remaining -= res;
					}
				}
				if(NULL != (cp3 = strstr(inbuf, "info ")))
				{
					cp4 = strstr(cp3,"\n");
					for(ii = 0; cp3 < cp4; ii++)
						ccd_info[ii] = *cp3++;
					ccd_info[ii] = '\0';
				}
			}
			res = output_detcmd(fddetcmd, inbuf, NULL, 0);
			switch(res)
			{
			case CCD_DET_OK:
				reply_cmd(REPLY_OK_STRING,NULL,fd_used);
				break;
			case CCD_DET_RETRY:
				reply_cmd(REPLY_RETRY_STRING,NULL,fd_used);
				break;
			case CCD_DET_FATAL:
				reply_cmd(REPLY_ERROR_STRING,NULL,fd_used);
				break;
			}
			if(NULL != (char *) strstr(inbuf, "exit\n"))
				return;
			inbufind = 0;
			continue;
		}
		else
		{
			continue;
	  	}
		
	}
  }
