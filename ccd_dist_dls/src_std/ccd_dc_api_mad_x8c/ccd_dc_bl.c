#include	"ccd_dc_ext.h"

/*
 *	Custom sun (i.e., non-sys5 behavior) code to cover the fact that
 *	the interval timer is disabled whenever the system sleeps.
 */

int	bl_ready;
int	bl_fd_to_check;

int	bl_check_fd()
  {
        fd_set  readmask, writemask, exceptmask;
        struct  timeval timeout;
        int     nb;
        char    buf[512];

        timeout.tv_sec = 0;
        timeout.tv_usec = 50000;
        FD_ZERO(&readmask);
        FD_SET(bl_fd_to_check,&readmask);
        nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
        if(nb == -1)
          {
                if(errno == EINTR)
                  {
                    return(0);             /* timed out */
                  }
		return(-1);
          }
        if(nb == 0)
          {
                return(0);         /* timed out */
          }
        if(0 == FD_ISSET(bl_fd_to_check,&readmask))
          {
                return(0);         /* timed out */
          }

        nb = recv(bl_fd_to_check,buf,512,MSG_PEEK);
        if(nb <= 0)
          {
                return(0);
          }
	bl_ready = 1;
	return(1);
  }

/*
 *	Handle communication to/from beam line control process.
 */

/*
 *	Output a beam line command line.
 *
 *	If the descriptor is not defined, forget it.  If the
 *	beam line command buffer does not contain anything for
 *	this run, don't output anything.
 *
 *	The second argument is a string, which can be null, to
 *	be prepended onto the beam line command argument (third
 *	argument).  This is how the beam line control program
 *	can distinguish between "before", "during", and "after"
 *	runs (in case it cares).
 *
 *	If the string is sucessfully written, we read the socket.
 *	When data is present, or an error occurs, we are done.
 *
 *	This causes a stall in the execution of ccd_dc.  The
 *	status should continue to update while this occurs.
 */

char	*blterm = "end_of_bl\n";

output_blcmd(fd,prestring,blcmd)
int	fd;
char	*prestring;
char	*blcmd;
  {
	char	tbuf[512],temp_xx[512],*retstr;
	int	i,ret,blret;
	fd_set	readmask,writemask,exceptmask;
	char	*cp;

	blret = CCD_BL_OK;
	retstr = "normal";

	if(fd == -1)
		return(CCD_BL_NOTCONNECTED);

	if(blcmd[0] == '\0')
		return(CCD_BL_OK);

	/*
	 *	Prepare the command string and output it.
	 */
	if(prestring == NULL || prestring[0] == '\0')
		sprintf(tbuf,"%s\n%s",blcmd,blterm);
	  else
		sprintf(tbuf,"%s\n%s\n%s",prestring,blcmd,blterm);

	if(0)
	  fprintf(stdout,"output_blcmd: sending:\n==========\n%s===========\n",tbuf);
	 else
	  {
	    if(blcmd[0] != '\0')
	      {
		sscanf(blcmd,"%s",temp_xx);
		fprintf(stdout,"output_blcmd : SENT:          at %s: %s\n",ztime(),temp_xx);
	      }
	  }
	ret = rep_write(fd,tbuf,strlen(tbuf));
	if(ret <= 0)
	  {
	    notify_server_eof(fd);
	    return(CCD_BL_DISCONNECTED);
	  }

	/*
	 *	Now check the socket for data present.
	 */

#if defined(sun) || defined(linux)
	/*
 	 * For non sys5 systems, just check the file descriptor
	 * with a timeout almost the same as we would use with the
	 * itimer and call what IT (the itimer) would, namely, the
	 * heartbeat function.
	 */

	bl_ready = 0;
	bl_fd_to_check = fd;
	while(bl_ready == 0)
	  {
		if(-1 == bl_check_fd())
		  {
	            notify_server_eof(fd);
	            return(CCD_BL_DISCONNECTED);
		  }
		if(bl_ready == 0)
			clock_heartbeat();
	  }
#endif /* sun or linux*/

	ret = read_until(fd,tbuf,sizeof tbuf,blterm);
	if(ret <= 0)
	  {
	        notify_server_eof(fd);
	        return(CCD_BL_DISCONNECTED);
	  }
#ifdef X8C
	if(1)
	{
		fprintf(stdout,"ccd_dc_bl: Beamline reply:\n%s",tbuf);
	}
#endif /* X8C */

	bl_returned_string[0] = '\0';
	if(NULL != (cp = (char *) strstr(tbuf, "OK")))
	{
		for(i = 0; (&tbuf[i]) < cp; i++)
			bl_returned_string[i] = tbuf[i];
		bl_returned_string[i] = '\0';
		if(bl_returned_string[0] != '\0');
			fprintf(stdout,"output_blcmd : RETS: %s\n",bl_returned_string);
	}
	strcpy(bl_reply, tbuf);

	if(NULL != (char *) strstr(bl_reply, "RETRY"))
	{
		blret = CCD_BL_RETRY;
		retstr = "retry";
	}
	else
	{
		if(NULL != (char *) strstr(bl_reply, "ERROR"))
		{
			blret = CCD_BL_FATAL;
			retstr = "fatal";
		}
	}
	if(blret == CCD_BL_RETRY)
		fprintf(stdout,"output_blcmd : DONE: (%s)  at %s: %s\n",retstr,ztime(),temp_xx);
	else if(blret == CCD_BL_FATAL)
		fprintf(stdout,"output_blcmd : DONE: (%s)  at %s: %s\n",retstr,ztime(),temp_xx);
	else
		fprintf(stdout,"output_blcmd : DONE: (%s) at %s: %s\n",retstr,ztime(),temp_xx);

	*((char *) strstr(bl_reply, blterm)) = '\0';
	return(blret);
  }

void    short_exposure_stall(val,fd)
int     val;
int	fd;
  {
	time_t	start_time,end_time;
	int	i_start_time,i_end_time,i_total_time;

	bl_ready = 0;
	bl_fd_to_check = fd;
	time(&start_time);
	i_start_time = (int) start_time;
        fprintf(stdout,"output_blcmd:  STALL         at %s: for %d seconds\n",ztime(),val);

	do
	  {
		bl_check_fd();
		clock_heartbeat();
		time(&end_time);
		i_end_time = (int) end_time;
		i_total_time = i_end_time - i_start_time;
	  } while(i_total_time < val);

        fprintf(stdout,"output_blcmd:  END STALL     at %s:\n",ztime());
        strcpy(stat_scanner_op,"Contine_after_short_exp");
        return;
  }
