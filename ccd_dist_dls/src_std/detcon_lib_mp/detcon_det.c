#include	"detcon_ext.h"

#if defined(sun) || defined(linux)

/*
 *	Code to handle non-sys5 itimer/sleep behavior.  See ccd_dc_bl.c
 */

static	int	dt_ready;
static	int	dt_fd_to_check;

static	int	dt_check_fd()
  {
        fd_set  readmask, writemask, exceptmask;
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
                detcon_timestamp(dtc_fplog);
                fprintf(dtc_fplog,"dt_check_fd: select error (on %d).  Should never happen.\n",dt_fd_to_check);
                fflush(dtc_fplog);
                perror("dt_check_fd: select in dt_check_fd");
                detcon_cleanexit(0);
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

static  char    timeholder[120];

static  char    *ztime()
  {
        long    clock;
        char    *cptr;

        time(&clock);
        cptr = (char *) ctime(&clock);
        strcpy(timeholder,cptr);
        timeholder[strlen(timeholder) - 1] = '\0';
        return(timeholder);
  }

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
 *	The second argument is a string, which can be null, to
 *	be prepended onto the beam line command argument (third
 *	argument).  This is how the detector control program
 *	can distinguish between "before", "during", and "after"
 *	runs (in case it cares).
 *
 *	If the string is sucessfully written, we read the socket.
 *	When data is present, or an error occurs, we are done.
 *
 *	This causes a stall in the execution of ccd_dc.  The
 *	status should continue to update while this occurs.
 */

static	char	*detterm = "end_of_det\n";

static	char	det_outbuf[20480];

detcon_output_detcmd(fd,detcmd,hdptr,hdsize)
int	fd;
char	*detcmd;
char	*hdptr;
int	hdsize;
  {
	char	tbuf[512],temp_xx[512],tmpret[40],*retstr;
	int	i,len,ret,detret;

	detret = CCD_DET_OK;
	retstr = "normal";

	if(fd == -1)
		return(CCD_DET_NOTCONNECTED);

	if(detcmd[0] == '\0')
		return(CCD_DET_OK);

	strcpy(det_outbuf,detcmd);
	strcat(det_outbuf,detterm);

	if(0)
	  fprintf(stderr,"output_detcmd: sending:\n==========\n%s===========\n",det_outbuf);
	 else
	  {
	    if(detcmd[0] != '\0')
	      {
		sscanf(det_outbuf,"%s",temp_xx);
		fprintf(stderr,"detcon_output: SENT          at %s: %s\n",ztime(),temp_xx);
	      }
	  }

	len = strlen(det_outbuf);
	for(i = 0; i < hdsize; i++,len++)
	    det_outbuf[len] = hdptr[i];

	ret = detcon_rep_write(fd,det_outbuf,len);
	if(ret <= 0)
	  {
	    detcon_notify_server_eof(fd);
	    return(CCD_DET_DISCONNECTED);
	  }

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

	ret = detcon_read_until(fd,dtc_det_reply,sizeof dtc_det_reply,detterm);

	if(ret <= 0)
	  {
	        detcon_notify_server_eof(fd);
	        return(CCD_DET_DISCONNECTED);
	  }

	sscanf(dtc_det_reply,"%s",tbuf);
	if(0)
	  fprintf(stderr,"output_detcmd: ccd_det returned: %s\n",tbuf);
	if(0 == strcmp("RETRY1",tbuf))
	  {
		detret = CCD_DET_RETRY;
		retstr = "retry";
          }
        else if(0 == strcmp("RETRY2",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
          }
        else if(0 == strcmp("RETRY3",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
          }
        else if(0 == strcmp("RETRY",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
	  }
	 else
	  {
	    if(0 == strcmp("ERROR",tbuf))
	      {
		detret = CCD_DET_FATAL;
		retstr = "fatal";
	      }
	  }
	fprintf(stderr,"detcon_output: DONE (%s) at %s: %s\n",retstr,ztime(),temp_xx);
	return(detret);
  }

/*
 *	Issue the command and return.  Data ready on the return from this command
 *	will be checked elsewhere.
 */

int	detcon_output_detcmd_issue(fd,detcmd,hdptr,hdsize)
int	fd;
char	*detcmd;
char	*hdptr;
int	hdsize;
  {
	char	tbuf[512],temp_xx[512],tmpret[40],*retstr;
	int	i,len,ret,detret;

	detret = CCD_DET_OK;
	retstr = "normal";

	if(fd == -1)
		return(CCD_DET_NOTCONNECTED);

	if(detcmd[0] == '\0')
		return(CCD_DET_OK);

	strcpy(det_outbuf,detcmd);
	strcat(det_outbuf,detterm);

	if(0)
	  fprintf(stderr,"output_detcmd: sending:\n==========\n%s===========\n",det_outbuf);
	 else
	  {
	    if(detcmd[0] != '\0')
	      {
		sscanf(det_outbuf,"%s",temp_xx);
		fprintf(stderr,"detcon_issue : SENT          at %s: %s\n",ztime(),temp_xx);
	      }
	  }

	len = strlen(det_outbuf);
	for(i = 0; i < hdsize; i++,len++)
	    det_outbuf[len] = hdptr[i];

	ret = detcon_rep_write(fd,det_outbuf,len);
	if(ret <= 0)
	  {
	    detcon_notify_server_eof(fd);
	    return(CCD_DET_DISCONNECTED);
	  }

	return(CCD_DET_OK);
  }

/*
 *	Once data ready on the detector socket has been determined, this
 *	routine will be called to receive the return info from the W95 PC.
 */

int	detcon_output_detcmd_receive(fd)
int	fd;
  {
	char	tbuf[512],tmpret[40],*retstr;
	int	i,len,ret,detret;
	/*
	 *	Now check the socket for data present.
	 */

	ret = detcon_read_until(fd,dtc_det_reply,sizeof dtc_det_reply,detterm);

	if(ret <= 0)
	  {
	        detcon_notify_server_eof(fd);
	        return(CCD_DET_DISCONNECTED);
	  }

	retstr = "normal";
	detret = CCD_DET_OK;
	sscanf(dtc_det_reply,"%s",tbuf);
	if(1)
		fprintf(stderr,"detcon_recv'd: INFO          at %s: detector returned %s\n",ztime(),tbuf);
	if(0 == strcmp("RETRY1",tbuf))
	  {
		detret = CCD_DET_RETRY;
		retstr = "retry";
          }
        else if(0 == strcmp("RETRY2",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
          }
        else if(0 == strcmp("RETRY3",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
          }
        else if(0 == strcmp("RETRY",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
	  }
	 else
	  {
	    if(0 == strcmp("ERROR",tbuf))
	      {
		detret = CCD_DET_FATAL;
		retstr = "fatal";
	      }
	  }
	fprintf(stderr,"detcon_recv'd: DONE (%s) at %s\n",retstr,ztime());
	return(detret);
  }

int	detcon_output_xform_receive(fd)
int	fd;
  {
	char	tbuf[512],tmpret[40],*retstr;
	int	i,len,ret,detret;
	/*
	 *	Now check the socket for data present.
	 */

	ret = detcon_read_until(fd,dtc_xform_reply,sizeof dtc_xform_reply,detterm);

	if(ret <= 0)
	  {
	        detcon_notify_server_eof(fd);
	        return(CCD_DET_DISCONNECTED);
	  }

	retstr = "normal";
	detret = CCD_DET_OK;
	sscanf(dtc_xform_reply,"%s",tbuf);
	if(1)
	  fprintf(stderr," xform_recv'd: RTRN          at %s: %s\n",ztime(),retstr);
	if(0 == strcmp("RETRY1",tbuf))
	  {
		detret = CCD_DET_RETRY;
		retstr = "retry";
          }
        else if(0 == strcmp("RETRY2",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
          }
        else if(0 == strcmp("RETRY3",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
          }
        else if(0 == strcmp("RETRY",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
	  }
	 else
	  {
	    if(0 == strcmp("ERROR",tbuf))
	      {
		detret = CCD_DET_FATAL;
		retstr = "fatal";
	      }
	  }
	fprintf(stderr," xform_recv'd: DONE (%s) at %s\n",retstr,ztime());
	return(detret);
  }
