/*
 *	IOLIB: A library to access files using RMS 
 *
 *	W. W. Smith June 1987
 *
 *	Modified by cn 10/93 for use in the image plate programs.
 *
 *	These routines are no longer the same as in the multiwire
 *	software.
 *
 *	Ten simultaneous files may be operated with this routine.
 */

#include <file.h>
#include <stdio.h>
#include <descrip.h>
#include <rms.h>
#include <ssdef.h>

#define	FOFF		50
#define	FF_MAXFILES	10

int	ff_inuse[FF_MAXFILES] = {0};
int	ff_recsize[FF_MAXFILES];
int	ff_assvar[FF_MAXFILES];

/*
 *	DEC/Shell to VMS name translator.
 */

char	vms_file_name[512];

int	dec_shell_to_vms_name(un,vn)
char	*un,*vn;
  {
	char	*u1,*u2,*u3,*u4;
	char	*v1,*v2,*v3,*v4;

	*vn = '\0';
	if(*un == '\0')
		return(-1);

	if(*un == '/')
	  {
		/*
		 *	The only thing this can be is:
		 *
		 *		/device/dir/.../dir/file
		 */
		u1 = un + 1;
		for(u2 = u1; *u2 != '\0'; u2++)
		  if(*u2 == '/')
			break;
		if(*u2 == '\0')
		  {
		    fprintf(stderr,"dec_shell_to_vms_name: %s is a bad DEC/Shell file name.\n",un);
		    return(-1);
		  }
		for(v1 = vn, u4 = u1; u4 < u2;)
			*v1++ = *u4++;
		for(u4 = u2 + 1; *u4 != '\0'; u4++)
		  if(*u4 == '/')
			break;
		if(*u4 == '\0')
		  {
		    *v1++ = ':';
		    for(u4 = u2 + 1; *u4 != '\0';)
			*v1++ = *u4++;
		    *v1 = '\0';
		    return(0);
		  }
		u1 = u2 + 1;	/* points to next thing after the first slash */
		*v1++ = ':';
		*v1++ = '[';
		*v1 = '\0';

		/*
		 *	The VMS file name buffer now contains:
		 *
		 *		device:[
		 *	  or
		 *		device:name  and the routine returned above.
		 */
	  }
	 else
	  {
		/*
		 *	These must be:
		 *
		 *		./dir/.../dir/file
		 *	  or
		 *		dir/.../dir/file
		 */

		if(*un == '.')
		  {
		    u1 = un + 1;
		    if(*u1 == '\0')
		      {
			fprintf(stderr,"dec_shell_to_vms_name: %s is a bad DEC/Shell file name.\n",un);
			return(-1);
		      }
		    if(*u1 != '/')
		      {
			fprintf(stderr,"dec_shell_to_vms_name: %s is a bad DEC/Shell file name.\n",un);
			return(-1);
		      }
		    u1++;
		  }
		 else
		  u1 = un;
		v1 = vn;
		for(u4 = u1; *u4 != '\0'; u4++)
		  if(*u4 == '/')
			break;
		if(*u4 == '\0')		/* a simple name, no directory stuff */
		  {
		    for(u4 = u1; *u4 != '\0';)
			*v1++ = *u4++;
		    *v1 = '\0';
		    return(0);
		  }
		u1 = u4 + 1;		/* points to next thing after the slash */
		*v1++ = '[';
		*v1++ = '.';
		*v1 = '\0';

		/*
		 *	The VMS file name buffer now contains:
		 *
		 *		[.
		 *	  or
		 *		name	and the routine returned above.
		 */
	  }

	/*
	 *	At this point, the file specs can be translated regardless of case
	 *	dealt with above.  The name has been checked to see that it has
	 *	at least one more slash.
	 */


	while(1)
	  {
	    for(u4 = u1; *u4 != '/';)
		*v1++ = *u4++;

	    /*
	     *	If there is another slash in the file, we continue building
	     *	up the VMS directory part.  If not, put in the ] and copy
	     *	the rest of the characters out and return.
	     */

	    for(u3 = u4 + 1; *u3 != '\0'; u3++)
	      if(*u3 == '/')
		break;
	    if(*u3 == '\0')	/* no more dirs, copy and finish */
	      {
		*v1++ = ']';
		for(u3 = u4 + 1; *u3 != '\0' ;)
			*v1++ = *u3++;
		*v1 = '\0';
		return(0);
	      }
	    *v1++ = '.';	/* continue the directory spec */
	    *v1 = '\0';
	    u1 = u4 + 1;	/* next thing past the current slash */
	}
  }
/*
 *
 *	ff_open: System open call.
 *
 *	Calling sequence:
 *
 *		file_no = ff_open(path,flags,mode,recsize,nrec);
 *		char	*path;
 *		int	flags,mode,recsize,nrec;
 *
 *	Parameter  Type Contents
 *
 *	path		File name
 *	flags		Open flags, 0=read only,1=write existing file,
 *			  2=create new file for write (will supersede existing)
 *	mode		protection mode; ignored
 *	recsize		recordsize in bytes for the file.
 *	nrec		number of records in the file.
 *
 *	nrec and recsize can be anything if we are opening up an existing file.
 *
 *
 *	returns:	If open is successful, returns a positive integer which
 *			is used for subsequent calls.
 *			If unsuccessful, returns negative of error number.
 */

int ff_open(path,flags,mode,recsize,nrec)
char	*path;
int 	flags,mode,recsize,nrec;
  {
	int 	i,j,ilast,vms_flag;
	int	status,forunit;
	struct	dsc$descriptor_s for_path;

	if(-1 == dec_shell_to_vms_name(path,vms_file_name))
	  {
	    fprintf(stderr,"ff_open: bad DEC/Shell file name; open refused on %s\n",path);
	    return(-1);
	  }
	for_path.dsc$a_pointer = vms_file_name;
	for_path.dsc$w_length = strlen(vms_file_name);
	for_path.dsc$b_dtype = DSC$K_DTYPE_T;
	for_path.dsc$b_class = DSC$K_CLASS_S;

	j = -1;
	for(i = 0; i < FF_MAXFILES; i++)
	  if(ff_inuse[i] == 0)
	    {
		j = i;
		break;
	    }
	if(j == -1)
	  {
	    fprintf(stderr,"ff_open: More than %d files are open.  Cannot open more.\n",FF_MAXFILES);
	    return(-1);
	  }

	forunit = FOFF + j;
	status = ff_for_initfile(&for_path,&forunit,&flags,&recsize,&nrec);

	if(status == 0)
	  {
	    ff_inuse[j] = 1;
	    ff_recsize[j] = recsize;
	    ff_assvar[j] = 1;
	    return(j);
	  }
	 else
	    return(-1);
  }



/*
 *	Close call.
 *
 *	Calling sequence:
 *
 *		status = ff_close(fno)
 *		int	fno
 *
 *	Parameter  Type Contents
 *
 *	fno		Value returned from the ff_open call.
 *	status		Zero if successful, on failure returns negative error.
 *
 */

int ff_close(fno)
int	fno;
  {
	int	forunit;

	if(fno < 0 || fno >= FF_MAXFILES)
	  {
	    fprintf(stderr,"ff_close: fno was out of range: %d\n",fno);
	    return(-1);
	  }
	if(ff_inuse[fno] == 0)
	  {
	    fprintf(stderr,"ff_close: filenumber %d was not marked open\n",fno);
	    return(-1);
	  }

	forunit = FOFF + fno;
	ff_for_close(&forunit);
	ff_inuse[fno] = 0;
	return (0);
  }

/*
 *		nbytes = ff_read(fno,buf,nbytes)
 *		int	fno;
 *		char	*buf;
 *		int	nbytes;
 *
 *	Parameter  Type Contents
 *
 *	fno		returned value from open.
 *	buf		Buffer to be read from file.
 *	nbytes		Number of bytes to be read into BUF from file.
 *
 *	returns:	If read is successful, returns number of bytes
 *	                  actually read.
 *	                If unsuccessful, returns negative error number.
 *
 */

int	ff_read(fno,buf,nbytes)
int	fno;
char	*buf;
int	nbytes;
  {
	int	forunit;
	int	status;
	int	avar;

	avar = ff_assvar[fno];
	forunit = FOFF + fno;
	status = ff_for_read(&forunit,buf,&nbytes,&avar);
	ff_assvar[fno]++;
	return(status);
  }

/*
 *		nbytes = ff_write(fno,buf,nbytes)
 *		int	fno;
 *		char	*buf;
 *		int	nbytes;
 *
 *	Parameter  Type Contents
 *
 *	fno		returned value from open.
 *	buf		Buffer to be written to file.
 *	nbytes		Number of bytes to be written into BUF from file.
 *
 *	returns:	If read is successful, returns number of bytes
 *	                  actually read.
 *	                If unsuccessful, returns negative error number.
 *
 */

int	ff_write(fno,buf,nbytes)
int	fno;
char	*buf;
int	nbytes;
  {
	int	forunit;
	int	status;
	int	avar;

	avar = ff_assvar[fno];
	forunit = FOFF + fno;
	status = ff_for_write(&forunit,buf,&nbytes,&avar);
	ff_assvar[fno]++;
	return(status);
  }

int	ff_rewind(fno)
int	fno;
  {
	ff_assvar[fno] = 1;
	return(0);
  }

int	ff_set_rec(fno,rec)
int	fno;
int	rec;
  {
	ff_assvar[fno] = rec;
	return(0);
  }
