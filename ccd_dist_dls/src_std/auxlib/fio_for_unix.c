#include	<stdio.h>
#include	<errno.h>

/*
 *	The subroutines in this module are designed to
 *	do two things:
 *
 *	1)	Error recovery for read/write/open
 *		in case we have a recoverable disk
 *		error.
 *
 *	2)	In the VMS version, we call ff_blah
 *		instead of blah to do open/read/write
 *		etc, because fortran IO is faster.
 *
 *		These routine allow us to use the same
 *		calling sequences for both systems and
 *		get rid of a bunch of ifdef's.
 */

int	ff_write(fd,buf,size)
int	fd;
char	*buf;
int	size;
  {
	long    clock;
	char    *cptr;
	int	retry;
	int	position;

	position = lseek(fd,0L,1);	/* current position */

	for(retry = 0; retry == 0;)
	  {
	    if(size != write(fd,buf,size))
	      {
		time(&clock);
		cptr = (char *) ctime(&clock);
		fprintf(stderr,"ff_write: error at time %s",cptr);
		if(errno == EIO)
		  {
		    fprintf(stderr,"\tThe error is (possibly) recoverable.\n");
		    sleep(2);
		    lseek(fd,position,0);
		  }
		 else
		  {
		    fprintf(stderr,"\tThe error is not recoverable.\n");
		    return(-1);
		  }
	      }
	     else
		retry = 1;
	  }
	return(size);
  }

/*
 *	Reading the neighbour code generates an error when the
 *	end of file is reached.  We don't echo this error.
 */

int	ff_read(fd,buf,size)
int	fd;
char	*buf;
int	size;
  {
	long    clock;
	char    *cptr;
	int	retry;
	int	position;

	position = lseek(fd,0L,1);	/* current position */

	for(retry = 0; retry == 0;)
	  {
	    if(size != read(fd,buf,size))
	      {
		if(errno == EIO)
		  {
		    time(&clock);
		    cptr = (char *) ctime(&clock);
		    fprintf(stderr,"ff_read: error at time %s",cptr);
		    fprintf(stderr,"\tThe error is (possibly) recoverable.\n");
		    sleep(2);
		    lseek(fd,position,0);
		  }
		 else
		  {
		    return(-1);
		  }
	      }
	     else
		retry = 1;
	  }
	return(size);
  }

ff_close(fd)
int	fd;
  {
	close(fd);
  }

int	ff_open(name,mode,mask,recsize,nrec)
char	*name;
int	mode,mask,recsize,nrec;
  {
	long    clock;
	char    *cptr;
	int	fd;
	int	retry;

	if(mode == 1)
	  {
	    for(retry = 0; retry == 0;)
	      {
		if(-1 == (fd = creat(name,mask)))
		  {
		    time(&clock);
		    cptr = (char *) ctime(&clock);
		    fprintf(stderr,"ff_open: error opening file %s at time %s",name,cptr);
		    if(errno == EIO)
		      {
		        fprintf(stderr,"\tError is (probably) recoverable\n");
		        sleep(2);
		      }
		     else
		      {
		        fprintf(stderr,"\tError is not recoverable\n");
		        return(-1);
		      }
		  }
		 else
		   retry = 1;
	      }
	    return(fd);
	  }
	 else
	  {
	    for(retry = 0; retry == 0;)
	      {
		if(-1 == (fd = open(name,mode)))
		  {
		    time(&clock);
		    cptr = (char *) ctime(&clock);
		    fprintf(stderr,"ff_open: error opening file %s at time %s",name,cptr);
		    if(errno == EIO)
		      {
		        fprintf(stderr,"\tError is (probably) recoverable\n");
		        sleep(2);
		      }
		     else
		      {
		        fprintf(stderr,"\tError is not recoverable\n");
		        return(-1);
		      }
		  }
		 else
		   retry = 1;
	      }
	    return(fd);
	  }
  }

ff_rewind(fd)
int	fd;
  {
	lseek(fd,0L,0);
  }
