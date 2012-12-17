#include	"ccd_bl_ext.h"

/*
 *	Handle status file updates.
 */

/*
 *	Pad out the null terminated string in_line with blanks out to
 *	n characters, with outline[n-1] being a newline, outline[n]
 *	a null.  Thus, outline should be one more character longer
 *	than you wish to have in the output file.
 */

pad_to_n_old(in_line,n,outline)
char	*in_line,*outline;
int	n;
  {
	int	i,j;

	for(i = 0;i < n - 1; i++)
	  if(in_line[i] != '\0')
		outline[i] = in_line[i];
	    else
		break;
	for(j = i ;j < n - 1; j++)
		outline[j] = ' ';
	outline[n-1] = '\n';
	outline[n] = '\0';
  }

pad_to_n(in_line,n,outline)
char	*in_line,*outline;
int	n;
  {
	int	i;

	strcpy(outline,in_line);
	i = strlen(outline);
	outline[i] = '\n';
	outline[i+1] = '\0';
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
	ret = select(FD_SETSIZE, (fd_set *) 0, &writemask, (fd_set *) 0, &timeout);
	if(ret < 0)
	  {
	    perror("st_write in status: select error: should never happen.");
	    return(-1);
	  }
	/*
	 *	blocked writes: just return 0; we skip the rest of the status
	 *	update on this pass.  This is not critical unless it lasts a
	 *	LONG time.
	 */
	if(ret == 0)
	    return(0);
	
	ret = write(fd,buf,n);

	if(ret <= 0)
	    return(ret);
	return(n);
  }

print_status(fd)
int	fd;
  {
	char	tbuf[120],obuf[81];
	double	f100();

	if(fd == -1)
		return;
	stat_n_mdc_updates++;

	sprintf(tbuf,"distance %8.2f",stat_dist);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	if(stat_axis == 1)
	  {
	    sprintf(tbuf,"phi %8.2f",stat_phi);
	    pad_to_n(tbuf,80,obuf);
	    if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	    sprintf(tbuf,"start_phi %8.2f",stat_start_phi);
	    pad_to_n(tbuf,80,obuf);
	    if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	  }
	 else
	  {
	    sprintf(tbuf,"omega %8.2f",stat_omega);
	    pad_to_n(tbuf,80,obuf);
	    if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	    sprintf(tbuf,"start_omega %8.2f",stat_start_omega);
	    pad_to_n(tbuf,80,obuf);
	    if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	  }
	sprintf(tbuf,"osc_width %8.2f",stat_osc_width);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"n_passes %d",stat_n_passes);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"time %8.2f",stat_time);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"intensity %8.2f",stat_intensity);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"max_count %d",stat_max_count);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"directory %s",stat_dir);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"filename %s",stat_fname);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"scanner_op %s",stat_scanner_op);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"scanner_msg %s",stat_scanner_msg);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"scanner_control %s",stat_scanner_control);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"scanner_shutter %s",stat_scanner_shutter);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"n_mdc_updates %d",stat_n_mdc_updates);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	if(stat_mode != 1)
		strcpy(tbuf,"mode time");
	  else
		strcpy(tbuf,"mode dose");
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;

	if(stat_adc == 0)
		strcpy(tbuf,"adc slow");
	  else
		strcpy(tbuf,"adc fast");
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"bin %d",stat_bin);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;

	sprintf(tbuf,"wavelength %7.4f",stat_wavelength);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"lift %8.2f",stat_lift);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	sprintf(tbuf,"mdc_alert %s",mdc_alert);
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
	strcpy(tbuf,"end_of_status");
	pad_to_n(tbuf,80,obuf);
	if(strlen(obuf) != st_write(fd,obuf,strlen(obuf))) return;
  }

send_status()
  {
	print_status(fdstat);
  }
