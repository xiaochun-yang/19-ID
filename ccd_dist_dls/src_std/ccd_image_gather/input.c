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

int	read_port_raw(fd,stbuf,stbufsize)
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
	    timeout.tv_sec = 1;
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
		notify_server_eof(fd);
		return(-1);
	      }
	    nread += ret;
	  }
  }

/*
 *	Function to do a write, with possible multiple chunks.
 *	We need this because of unknown buffering over the network.
 *
 *	The write blocks.
 *
 *	Returns the number of characters written, or -1 if an error.
 */

int	rep_write(fd,buf,count)
int	fd,count;
char	*buf;
  {
	char	*pos;
	int	remcount,i;

	if(count == 0)
		return(0);

	pos = buf;
	remcount = count;

	while(remcount > 0)
	  {
		i = write(fd,pos,remcount);
		if(i < 0)
		  {
		    timestamp(fplog);
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
 *	Function to do a read, with possible multiple chunks.
 *	We need this because of unknown buffering over the network.
 *
 *	The read blocks.
 *
 *	Returns the number of characters read, or -1 if an error.
 */

int	rep_read(fd,buf,count)
int	fd,count;
char	*buf;
  {
	char	*pos;
	int	remcount,i;

	if(count == 0)
		return(0);

	pos = buf;
	remcount = count;

	while(remcount > 0)
	  {
		i = read(fd,pos,remcount);
		if(i < 0)
		  {
		    timestamp(fplog);
		    fprintf(fplog,"rep_read: Error (%d) on file descriptor %d\n",errno,fd);
		    fflush(fplog);
		    perror("rep_read");
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
	int	len;
	int	nb;
	int	i,j,k;
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
		fprintf(stderr,"ccd_image_gather: check_for_connection:: select error.  Should never happen.\n");
		timestamp(fplog);
		fprintf(fplog,"ccd_image_gather: check_for_connection:: select error.  Should never happen.\n");
		fflush(fplog);
		perror("ccd_image_gather: check_for_connection:: select");
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
		    fprintf(stderr,"ccd_image_gather: check_for_connection:: accept error for network connection\n");
		    timestamp(fplog);
		    fprintf(fplog,"ccd_image_gather: check_for_connection:: accept error for network connection\n");
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

notify_server_eof(int	fd)
  {
  	int	n;
	char	*ztime();

	if(fd == command_fd)
	  {
	    fprintf(stderr,"ccd_image_gather: connection for command closed at time: %s\n",ztime());
	    fprintf(fplog,"ccd_image_gather: connection for command closed at time: %s\n",ztime());
	    close(command_fd);
	    command_fd = -1;
	    return;
	  }
	for(n = 0; n < q_ncon; n++)
	  {
		if(fd == data_fd[n])
		  {
		    fprintf(stderr,
		      "ccd_image_gather: connection for detector process %d  closed at time: %s\n",n, ztime());
		    fprintf(fplog,
		      "ccd_image_gather: connection for detector process %d  closed at time: %s\n",n, ztime());
		    close(data_fd[n]);
		    data_fd[n] = -1;
		    return;
		  }
	  }
  }

/*
 *	Main input processing routine.
 */

process_input()
{
  	int 	m,n;
	int 	nbytes;
	int 	res;
	int 	n_id_read;
	char	id_buf[80];
	char	*cp;
	int	mod_id;
	int	fd;

	inbufind = 0;
	command_number = -1;
	processing_command = SCANNING_FOR_COMMAND;
	merge_header_bytes = 0;

	while(1)
	{
	    /*
	     *	For the command input, we check for a connection.
	     */

	    if(command_fd == -1)
	      {
		if(-1 != (command_fd = check_for_connection(command_s)))
		  {
		    inbufind = 0;
		    command_number = -1;
		    processing_command = SCANNING_FOR_COMMAND;
		    fprintf(stderr,"ccd_image_gather: connection for command accepted (fd: %d)\n",command_fd);
		  }
	      }
	    /*
	     *	Loop thru the possible grabber hosts and ports.
	     */

	    for(n = 0; n < q_ncon; n++)
	    for(m = 0; m < q_states[n]; m++)
	    {
		if(data_fd[q_blocks[n][m]] == -1)
	          {
			if(-1 != (fd = connect_to_host_api(&data_fd[q_blocks[n][m]],q_hostnames[n],q_dports[n],NULL)))
			{
				if(NULL != (char *) getenv("CCD_IDENTIFY_DATA_MODULE"))
				{
					n_id_read = read(data_fd[q_blocks[n][m]], id_buf, sizeof id_buf);
					if(n_id_read > 0)
					{
						id_buf[n_id_read] = '\0';
						if(NULL == (cp = (char *) strstr(id_buf, "module_")))
						{
							fprintf(stderr,"ccd_image_gather: WARNING: module_ string NOT FOUND on id reply\n");
							data_fd[q_blocks[n][m]] = fd;
		    					fprintf(stderr,"ccd_image_gather: connection for data accepted host: %s port: %d (fd: %d) id: %s\n",
								q_hostnames[n],q_dports[n],data_fd[q_blocks[n][m]], id_buf);
						}
						else
						{
							cp += strlen("module_");
							mod_id = (int)(*cp - '0');
							data_fd[mod_id] = fd;
		    					fprintf(stderr,"ccd_image_gather: connection for data accepted host: %s port: %d (fd: %d) (module %d) id: %s\n",
								q_hostnames[n],q_dports[n],data_fd[mod_id], mod_id, id_buf);
						}
					}
					else
					{
		    				fprintf(stderr,"ccd_image_gather: connection for data accepted host: %s port: %d (fd: %d)\n",
							q_hostnames[n],q_dports[n],data_fd[q_blocks[n][m]]);
						data_fd[q_blocks[n][m]] = fd;
					}
				}
				else
				{
		    			fprintf(stderr,"ccd_image_gather: connection for data accepted host: %s port: %d (fd: %d)\n",
						q_hostnames[n],q_dports[n],data_fd[q_blocks[n][m]]);
					data_fd[q_blocks[n][m]] = fd;
				}
			}
		  }
	    }
	    
	    /*
	     *	If we don't have a command connection, sleep and try again.
	     */

	    if(command_fd == -1)
	      {
		sleep(1);
		continue;
	      }

	    /*
	     *	Try to read some data from the command socket.  If none is present, sleep
	     *	and try again.
	     */
	    
	    if(-1 == (nbytes = read_port_raw(command_fd,&inbuf[inbufind],INBUFSIZE - inbufind)))
		continue;

	    if(nbytes == 0)
	    {
		continue;
	    }
	    inbufind += nbytes;

	    inbuf[inbufind] = '\0';
	    if(0)
	    	fprintf(stdout,"%s", inbuf);
	    while(NULL != (char *) strstr(inbuf, "end_of_det\n"))
	    {
	    	res = process_buffer();

	    	if(res == 1)
	    	{
			if(execute_command())
				return;		/* program has been requested to exit */
	
			command_number = -1;
			merge_header_bytes = 0;
			continue;
		}
		else
			break;
	    }
	}
}
