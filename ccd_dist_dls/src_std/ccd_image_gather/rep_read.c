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
