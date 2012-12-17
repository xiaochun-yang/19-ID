#include	<stdio.h>
#include	<sys/types.h>
#include	<sys/time.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#include	<netdb.h>
#include	<errno.h>
#include	"ccd_dc_ext.h"

/*
 *	ccd_dc_sio:
 *
 *		Perform buffered reads and writes over socket
 *		connections.  The routines below are necessary
 *		since we don't have control over the way messages
 *		are broken up over the net.
 *
 */
int 	sio_string_found(buf,idex,ss)
char	*buf;
int	idex;
char	*ss;
  {
	int	i,j,lss,bss;

	lss = strlen(ss);
	bss = idex - lss + 1;

	for(i = 0; i < bss ; i++)
	  {
	    for(j = 0; j < lss; j++)
	      if(ss[j] != buf[i + j])
		break;
	    if(j == lss)
		return(i);
	  }
	return(-1);
  }

/*
 *	read_until:
 *
 *		Reads a maximum of maxchar from the file descriptor
 *		fd into buf.  Reading terminates when the string
 *		contained in looking_for is found.  Additional
 *		characters read will be discarded.
 *
 *		The read blocks.
 *
 *		For convienence, since we usually use this routine with
 *		string handling routines, scanf's, and such, the program
 *		will append a "null" to the end of the buffer.  The number
 *		of chars gets incremented by 1.
 *
 *	  Returns:
 *
 *		-1 on an error.
 *		number of characters read on sucess.
 *		0 on EOF.
 *
 *	Note:
 *
 *		This routine should not be used when it is expected that
 *		there may be more than one "chunk" of data present on
 *		the socket, as the subsequent "chunks" or parts thereof
 *		will be thrown away.
 *
 *		Ideal for situations where data is written to a process
 *		then one batch of info is written back, and no further data
 *		should be present until ADDITIONAL data is written to the
 *		process.
 */

int	read_until(fd,buf,maxchar,looking_for)
int	fd;
char	*buf;
int	maxchar;
char	*looking_for;
  {
	int	i,j,eobuf,looklen,ret,utindex;
	fd_set	readmask;
	struct timeval	timeout;

	looklen = strlen(looking_for);
	utindex = 0;

	while(1)
	  {
		FD_ZERO(&readmask);
		FD_SET(fd,&readmask);
		timeout.tv_usec = 0;
		timeout.tv_sec = 1;
		ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, NULL);
		if(ret == 0)
			continue;
		if(ret == -1)
		  {
		    if(errno == EINTR)
			continue;	/* interrupted system calls are OK. */
		    return(-1);
		  }
		if(0 == FD_ISSET(fd,&readmask))
			continue;
		ret = read(fd,&buf[utindex],maxchar - utindex);
		if(ret == -1)
			return(-1);
		if(ret == 0)
			return(0);

		utindex += ret;
		if(-1 != (eobuf = sio_string_found(buf,utindex,looking_for)))
		  {
			eobuf += looklen;
			buf[eobuf] = '\0';
			eobuf++;

			return(eobuf);
		  }
		if(utindex == maxchar)
			return(utindex);
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
