#include	<stdio.h>
#include	<sys/types.h>
#include	<sys/time.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#include	<netdb.h>
#include	<errno.h>
#include	"ccd_bl_ext.h"

/*
 *	GENERIC VERSION.
 *
 *	No beamline hardware actually gets operated, but all timing which
 *	other processes need is done correctly.  To be used when we just have
 *	a detector and no goniostat, etc.
 */

/*
 *      Entries for network names, ports, etc.
 */

extern struct serverlist        dcserver;
extern struct serverlist        daserver;
extern struct serverlist	blserver;
extern struct serverlist	dtserver;
extern struct serverlist        xfserver;
extern struct serverlist        stserver;
extern struct serverlist        conserver;
extern struct serverlist        viewserver;
extern int                      ccd_communication;

#ifdef VMS
#define BAD_STATUS      2
#define GOOD_STATUS     1
#else
#define BAD_STATUS      1
#define GOOD_STATUS     0
#endif /* VMS */

void    catch_sigpipe()
  {
        fprintf(stderr,"ccd_server: caught SIGPIPE signal\n");
  }


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
 *	Client process to process beam line requests from ccd_dc.
 *
 *	Sufficient internal buffering exists to store multiple
 *	command requests.
 */

char	blbuf[10240];		/* holds the entire beamline buffer */
char	blubuf[1024];		/* actually gets passed to the user */
int	blindex;

char	*looking_for = "end_of_bl\n";

main(argc,argv)
int	argc;
char	*argv[];
  {
	int	i,j,eobuf;
	int	looklen;
	int	maxlen;
	fd_set	readmask;
	int	ret;
	int	returned_status;
	char	retbuf[256];
	struct timeval	timeout;

        signal(SIGPIPE,catch_sigpipe);

	fdcom = fdstat = -1;

	ccd_bl_generic_init();
/*
 *	Set up initial values for status.
 */

	stat_start_phi = 0.0;
	stat_osc_width = 0.0;
	stat_n_passes = 1;
	stat_time = 0.0;
	stat_intensity = 0.0;
	stat_max_count = 0.0;
	stat_dir[0] = '\0';
	stat_fname[0] = '\0';
	strcpy(stat_scanner_op,"idle");
	stat_scanner_msg[0] = '\0';
	stat_scanner_control[0] = '\0';
	strcpy(stat_scanner_shutter,"closed");
	stat_n_mdc_updates = 0;
	stat_mode = 0;
	stat_adc = 0;
	stat_bin = 1;
	stat_wavelength = 1.5418;
	stat_lift = 0.0;
	mdc_alert[0] = '\0';

	if(check_environ())
                cleanexit(BAD_STATUS);
        if(apply_reasonable_defaults())
                cleanexit(BAD_STATUS);

	if(-1 == (fdcom = connect_to_host(&fdcom,dcserver.sl_hrname,dcserver.sl_port,"connect bl_cmd")))
	  {
		fprintf(stderr,"ccd_bl: cannot establish connection with ccd_dc for command\n");
		perror("ccd_bl: connecting for command");
		exit(0);
	  }

	if(-1 == (fdstat = connect_to_host(&fdstat,dcserver.sl_hrname,dcserver.sl_port,"connect bl_status")))
	  {
		fprintf(stderr,"ccd_bl: cannot establish connection with ccd_dc for status\n");
		perror("ccd_bl: connecting for status");
		exit(0);
	  }

	looklen = strlen(looking_for);
	maxlen = sizeof blbuf;
	blindex = 0;

	while(1)
	  {
		FD_ZERO(&readmask);
		FD_SET(fdcom,&readmask);
		timeout.tv_usec = 0;
		timeout.tv_sec = 1;
		ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
		send_status();
		if(ret == 0)
			continue;
		if(ret == -1)
		  {
		    if(errno == EINTR)
			continue;	/* interrupted system calls are OK. */

		    fprintf(stderr,"ccd_bl: Error returned from select call\n");
		    cleanexit(0);
		  }
		if(0 == FD_ISSET(fdcom,&readmask))
			continue;
		ret = read(fdcom,&blbuf[blindex],maxlen - blindex);
		if(ret == -1)
		  {
		    if(errno == EINTR)
			continue;		/* Interrupted system calls are OK */

		    fprintf(stderr,"ccd_bl: ERROR on beamline socket.\n");
		    perror("ccd_bl: read beamline socket");
		    fprintf(stderr,"ccd_bl: ccd_dc server has probably terminated.\n");
		    fprintf(stderr,"ccd_bl: program exiting.\n");
		    cleanexit(0);
		  }
		if(ret == 0)
		  {
		    fprintf(stderr,"ccd_bl: EOF on beamline socket connection.\n");
		    fprintf(stderr,"ccd_bl: ccd_dc server has probably terminated.\n");
		    fprintf(stderr,"ccd_bl: program exiting.\n");
		    cleanexit(0);
		  }

		blindex += ret;
		if(-1 != (eobuf = string_found(blbuf,blindex,looking_for)))
		  {
			eobuf += looklen;
			for(i = 0; i < eobuf; i++)
				blubuf[i] = blbuf[i];
			blubuf[eobuf] = '\0';

			/*
			 *	The beamline control string has been received.
			 *
			 *	Call the local beamline control module to perform
			 *	desired action, if necessary.
			 */

			returned_status = local_beamline_control(blubuf);

			/*
			 *	On return, ack ccd_dc so it can continue.
			 */
			switch(returned_status)
			  {
			    case 0:
				sprintf(retbuf,"OK\n%s",looking_for);
				break;
			    case 1:
				sprintf(retbuf,"RETRY\n%s",looking_for);
				break;
			    case 2:
				sprintf(retbuf,"ERROR\n%s",looking_for);
				break;
			  }
			if(strlen(retbuf) != write(fdcom,retbuf,strlen(retbuf)))
			    fprintf(stderr,"ccd_bl: error writing acknowledge string %s\n",retbuf);
			fprintf(stderr,"ccd_bl_gen: REPLIED.\n");

			for(i = eobuf, j = 0; i < blindex; i++, j++)
				blbuf[j] = blbuf[i];
			blindex -= eobuf;
		  }
	  }
  }

/*
 *	This code is used to read the abort string when present
 *	in the input.  It should be the case that the ONLY time
 *	an "extra" command is queued while a real command is executed
 *	is when "abort" is issued.  This function below drains the
 *	socket.
 */

read_abort_command()
  {
	int	i,j,eobuf;
	int	looklen;
	int	maxlen;
	fd_set	readmask;
	int	ret;
	int	returned_status;
	char	retbuf[256];
	char	abortbuf[256];
	int	abortind;
	struct timeval	timeout;

	maxlen = 256;
	abortind = 0;

	while(1)
	  {
		FD_ZERO(&readmask);
		FD_SET(fdcom,&readmask);
		timeout.tv_usec = 0;
		timeout.tv_sec = 1;
		ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
		send_status();
		if(ret == 0)
			continue;
		if(ret == -1)
		  {
		    if(errno == EINTR)
			continue;	/* interrupted system calls are OK. */

		    fprintf(stderr,"ccd_bl: Error returned from select call\n");
		    cleanexit(0);
		  }
		if(0 == FD_ISSET(fdcom,&readmask))
			continue;
		ret = read(fdcom,&abortbuf[abortind],maxlen - abortind);
		if(ret == -1)
		  {
		    if(errno == EINTR)
			continue;		/* Interrupted system calls are OK */

		    fprintf(stderr,"ccd_bl: ERROR on beamline socket.\n");
		    perror("ccd_bl: read beamline socket");
		    fprintf(stderr,"ccd_bl: ccd_dc server has probably terminated.\n");
		    fprintf(stderr,"ccd_bl: program exiting.\n");
		    cleanexit(0);
		  }
		if(ret == 0)
		  {
		    fprintf(stderr,"ccd_bl: EOF on beamline socket connection.\n");
		    fprintf(stderr,"ccd_bl: ccd_dc server has probably terminated.\n");
		    fprintf(stderr,"ccd_bl: program exiting.\n");
		    cleanexit(0);
		  }

		abortind += ret;
		if(-1 != (eobuf = string_found(abortbuf,abortind,looking_for)))
		  {
			/*
			 *	Abort sequence has been located.  Execute
			 *	local abort command.
			 */
                	fprintf(stderr,"ccd_bl_gen: ABORT SEEN while operation is in progress.\n");
                	abort_abortable_operations();

			sprintf(retbuf,"OK\n%s",looking_for);
			if(strlen(retbuf) != write(fdcom,retbuf,strlen(retbuf)))
			    fprintf(stderr,"ccd_bl: error writing acknowledge string %s\n",retbuf);
			fprintf(stderr,"ccd_bl_gen: REPLIED to abort.\n");
			return;
		  }
	  }
  }

cleanexit(status)
int     status;
  {
	if(fdcom != -1)
	  {
	    shutdown(fdcom,2);
	    close(fdcom);
	  }
	if(fdstat != -1)
	  {
	    shutdown(fdstat,2);
	    close(fdstat);
	  }
	exit(status);
  }
