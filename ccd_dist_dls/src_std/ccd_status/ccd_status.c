/*
 *	ccd_status
 *
 *	  Gather status from various processes and activities
 *	in the ccd system.
 *
 *	  This process allows many (up to 10) processes to connect
 *	to it and receive status information.
 *
 *	  This process also is in contact with other processes in
 *	the ccd system, assuming they are running.
 */

#include	<stdio.h>
#include	<errno.h>
#include	"../incl/ccdconv.h"
#include	"../incl/ccdsys.h"

#ifndef VMS
#include	<sys/types.h>
#include	<sys/time.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#include	<netdb.h>
#else
#include	<types.h>
#include	<time.h>
#include	<socket.h>
#include	<in.h>
#include	<netdb.h>
#endif /* VMS */

/*
 *	Exit codes & status.
 */

#ifdef VMS
#define BAD_STATUS      2
#define GOOD_STATUS     1
#else
#define BAD_STATUS      1
#define GOOD_STATUS     0
#endif /* VMS */

/*
 *      Entries for network names, ports, etc.
 */

extern struct serverlist        dcserver;
extern struct serverlist        dtserver;
extern struct serverlist        blserver;
extern struct serverlist        daserver;
extern struct serverlist        xfserver;
extern struct serverlist        stserver;
extern struct serverlist        conserver;
extern struct serverlist        viewserver;

extern int                      ccd_communication;

int 	string_found(buf,idex,ss)
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
 *	Client process to output the status file from ccd_dc periodically.
 */
#define	STBUFSIZE	20480

char	stbuf[STBUFSIZE];		/* holds the entire status buffer */
int	stindex;

char	*looking_for = "end_of_status\n";

int	fddcstat;		/* file descriptor for ccd_dc status port */

main(argc,argv)
int	argc;
char	*argv[];
  {
	int	i,j,eobuf;
	int	looklen;
	FILE	*fpstat;
	fd_set	readmask;
	char	*cp,statfile[132];
	int	ret;
	struct timeval	timeout;

	fddcstat = -1;

        if(check_environ())
                cleanexit(BAD_STATUS);
        if(apply_reasonable_defaults())
                cleanexit(BAD_STATUS);

	/*
	 *	Make sure the output status file can be created.  Create
	 *	to truncate, close, and reopen r+.
	 */

	if(NULL == (cp = (char *) getenv("CCD_STATUS_FILE")))
	  {
	    fprintf(stderr,"ccd_status:  No environment variable set for CCD_STATUS_FILE.\n");
	    fprintf(stderr,"             This is used by this program to communicate status information\n");
	    fprintf(stderr,"             to the control GUI and MUST be set.\n");
	    fprintf(stderr,"ccd_status:  Exiting.\n");
	    cleanexit(0);
	  }
	strcpy(statfile,cp);
	if(NULL == (fpstat = fopen(statfile,"w")))
	  {
	    fprintf(stderr,"ccd_status:  Error creating file %s\n",statfile);
	    fprintf(stderr,"             This file is REQUIRED.  Please check CCD_STATUS_FILE environment\n");
	    fprintf(stderr,"             variable + file permissions, etc.\n");
	    fprintf(stderr,"ccd_status:  Exiting.\n");
	    cleanexit(0);
	  }
	fclose(fpstat);
	if(NULL == (fpstat = fopen(statfile,"r+")))
	  {
	    fprintf(stderr,"ccd_status:  Error reopening file %s\n after it was created and closed.",statfile);
	    fprintf(stderr,"             This file is REQUIRED.  Please check CCD_STATUS_FILE environment\n");
	    fprintf(stderr,"             variable + file permissions, etc.\n");
	    fprintf(stderr,"ccd_status:  Exiting.\n");
	    cleanexit(0);
	  }

	if(-1 == connect_to_host(&fddcstat,dcserver.sl_hrname,dcserver.sl_port,"connect status"))
	  {
		fprintf(stderr,"ccd_status: cannot establish connection with ccd_dc\n");
		cleanexit(0);
	  }

	looklen = strlen(looking_for);
	stindex = 0;

	while(1)
	  {
		FD_ZERO(&readmask);
		FD_SET(fddcstat,&readmask);
		timeout.tv_usec = 50000;
		timeout.tv_sec = 0;
		ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, NULL);
		if(ret == 0)
			continue;
		if(ret == -1)
		  {
			if(errno == EINTR)
				continue;	/* Ignore interrupted system calls */
			fprintf(stderr,"ccd_status: Error returned from select call\n");
			perror("ccd_status: select error");
			cleanexit(0);
		  }
		if(0 == FD_ISSET(fddcstat,&readmask))
			continue;
		ret = read(fddcstat, &stbuf[stindex], STBUFSIZE - stindex);
		if(ret == -1)
		  {
		    fprintf(stderr,"ccd_status: ERROR on status file, errno: %d\n",errno);
		    perror("ccd_status: read status socket");
		    fprintf(stderr,"ccd_status: ccd_dc server has probably terminated.\n");
		    fprintf(stderr,"ccd_status: program exiting.\n");
		    cleanexit(0);
		  }
		if(ret == 0)
		  {
		    fprintf(stderr,"ccd_status: EOF on status file.\n");
		    fprintf(stderr,"ccd_status: ccd_dc server has probably terminated.\n");
		    fprintf(stderr,"ccd_status: program exiting.\n");
		    cleanexit(0);
		  }
		stindex += ret;
		if(-1 != (eobuf = string_found(stbuf,stindex,looking_for)))
		  {
			eobuf += looklen;
			fseek(fpstat,0L,0);
			fwrite(stbuf,sizeof (char),eobuf,fpstat);
			fflush(fpstat);
			for(i = eobuf , j = 0; i < stindex; i++,j++)
			  stbuf[j] = stbuf[i];
			stindex -= eobuf;
		  }
	  }
  }


cleanexit(status)
int     status;
  {
	if(fddcstat != -1)
	  {
	    shutdown(fddcstat,2);
	    close(fddcstat);
	  }
	exit(status);
  }
