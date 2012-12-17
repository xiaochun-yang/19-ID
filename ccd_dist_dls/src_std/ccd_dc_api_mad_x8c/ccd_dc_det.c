#include	"ccd_dc_ext.h"

#if defined(sun) || defined(linux)

/*
 *	Code to handle non-sys5 itimer/sleep behavior.  See ccd_dc_bl.c
 */

int	dt_ready;
int	dt_fd_to_check;

int	dt_check_fd()
  {
        fd_set  readmask, writemask, exceptmask;
        struct  timeval timeout;
        int     nb;
        char    buf[512];

        timeout.tv_sec = 0;
        timeout.tv_usec = 50000;
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
                timestamp(fplog);
                fprintf(fplog,"dt_check_fd: select error (on %d).  Should never happen.\n",dt_fd_to_check);
                fflush(fplog);
                perror("dt_check_fd: select in dt_check_fd");
                cleanexit(BAD_STATUS);
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

char	*detterm = "end_of_det\n";

char	det_outbuf[20480];
char	det_reply[2048];

output_detcmd(fd,detcmd,hdptr,hdsize)
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

	temp_xx[0] = '\0';
	sscanf(det_outbuf,"%s",temp_xx);
	if(0)
	  fprintf(stdout,"output_detcmd: sending:\n==========\n%s===========\n",det_outbuf);
	fprintf(stdout,"output_detcmd: SENT:          at %s: %s\n",ztime(),temp_xx);

	len = strlen(det_outbuf);
	for(i = 0; i < hdsize; i++,len++)
	    det_outbuf[len] = hdptr[i];

	ret = rep_write(fd,det_outbuf,len);
	if(ret <= 0)
	  {
	    notify_server_eof(fd);
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

	ret = read_until(fd,det_reply,sizeof det_reply,detterm);

	if(ret <= 0)
	  {
	        notify_server_eof(fd);
	        return(CCD_DET_DISCONNECTED);
	  }

	sscanf(det_reply,"%s",tbuf);
	if(0)
	  fprintf(stdout,"output_detcmd: ccd_det returned: %s\n",tbuf);
	if(0 == strcmp("RETRY1",tbuf))
	  {
		detret = CCD_DET_RETRY;
		retstr = "retry";
system("$RUNFILES/logit ccd_retry_controller_error");
          }
        else if(0 == strcmp("RETRY2",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
system("$RUNFILES/logit ccd_retry_exp_too_short");
          }
        else if(0 == strcmp("RETRY3",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
system("$RUNFILES/logit ccd_retry_exp_too_long");
          }
        else if(0 == strcmp("RETRY",tbuf))
          {
                detret = CCD_DET_RETRY;
                retstr = "retry";
system("$RUNFILES/logit ccd_retry");
	  }
	 else
	  {
	    if(0 == strcmp("ERROR",tbuf))
	      {
		detret = CCD_DET_FATAL;
		retstr = "fatal";
	      }
	  }
	if(0 != (char *) strstr(retstr, "retry"))
		fprintf(stdout,"output_detcmd: DONE: (%s)  at %s: %s\n",retstr,ztime(),temp_xx);
	else if(0 != (char *) strstr(retstr, "fatal"))
		fprintf(stdout,"output_detcmd: DONE: (%s)  at %s: %s\n",retstr,ztime(),temp_xx);
	else
		fprintf(stdout,"output_detcmd: DONE: (%s) at %s: %s\n",retstr,ztime(),temp_xx);
	return(detret);
  }
