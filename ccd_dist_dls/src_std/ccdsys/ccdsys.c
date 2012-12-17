#include	<stdio.h>

#include	<sys/types.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#include	<netdb.h>
#include	<errno.h>
#include	"../incl/ccdsys.h"

/*
 *	Check to see if the daemon permits a connection, and if
 *	so, record the socket.
 */

check_for_daemon(fdnet,name,port)
int	*fdnet;
char	*name;
int	port;
  {
	int	s;
	struct	sockaddr_in	server;
	int 	g;
	int	len;
	char	buf[512];
	int	nb;
	FILE	*fp;
	struct	hostent	*hentptr,hent;

	hentptr = gethostbyname(name);
	if(hentptr == NULL)
	  {
	    fprintf(stderr,"ccdsys: no hostentry for machine %s\n",name);
	    *fdnet = -1;
	    return(1);
	  }
	hent = *hentptr;

	if(-1 == (s = socket(AF_INET, SOCK_STREAM, 0)))
	  {
		perror("ccdsys: cannot create socket");
	    	*fdnet = -1;
		return(1);
	  }

	server.sin_family = AF_INET;
	server.sin_addr = *((struct in_addr *) hent.h_addr);
	server.sin_port = htons(port);

	if(connect(s, (struct sockaddr *) &server,sizeof server) < 0)
	  {
		*fdnet = -1;
		return(1);
	  }

	*fdnet = s;
	return(0);
  }

ensure_proper_bind(hname,port)
char	*hname;
int	port;
  {
  }

/*
 *-----------------------------------------------------
 *
 *	ccdsys  -  control the startup/shutdown/restart
 *		   of the Mar Image Plate software.
 *
 *
 *	This version differs from the regular ccdsys in that
 *	all but data collection is controlled from this program.
 *	Data collecion is assumed to run on another system
 *	to which this one is connected via NFS.
 *------------------------------------------------------
 *
 *	This program executes in the following manner:
 *
 *	  o	When started, it attempts to make a connection
 *		via a network socket to the ccd_daemon.
 *		If the connection is sucessful, then the user's
 *		wishes are transmitted to the daemon.
 *
 *	  o	If no daemon is present, indicated by a refused
 *		connection, then a daemon is started and the user's
 *		wishes are transmitted as above to the daemon.
 *
 *------------------------------------------------------
 *
 *	ccdsys is invoked in one of three ways:
 *
 *	ccdsys startup
 *
 *			Starts up the processes specified by the
 *			environment variables.
 *
 *	ccdsys shutdown
 *			Shuts down the five (or six) processes which
 *			are involved in running the CCD hardware.
 */

/*
 *	Entries for network names, ports, etc.
 */

extern struct serverlist        dcserver;
extern struct serverlist	dtserver;
extern struct serverlist	blserver;
extern struct serverlist        daserver;
extern struct serverlist        xfserver;
extern struct serverlist        stserver;
extern struct serverlist        conserver;
extern struct serverlist        viewserver;
extern int                      ccd_communication;

int	fddaemon;	/* file descriptor to daemon */
int	use_tty_output;	/* 1 if we are going to have ccdsys_daemon use tty instead of log files */

#ifdef VMS
#define	BAD_STATUS	2
#define GOOD_STATUS	1
#else
#define	BAD_STATUS	1
#define	GOOD_STATUS	0
#endif /* VMS */

/*
 *	These are the various argument options the program can take.
 */

char	*options[] = {
			"startup",
			"shutdown",
			"status",
			"exit",
			"initialize",
			NULL
		     };

enum {
	OPT_STARTUP = 0,
	OPT_SHUTDOWN,
	OPT_STATUS,
	OPT_EXIT,
	OPT_INIT
     };

#define	OPT_BAD		-1

int	optnums[] = {
		    OPT_STARTUP,
		    OPT_SHUTDOWN,
		    OPT_STATUS,
		    OPT_EXIT,
		    OPT_INIT,
		    OPT_BAD
		    };

startup_daemon()
  {
	int	pid;
	char	execname[256];
	char	*ccdsys_home;
	char	*getenv();

	pid = fork();

	if(pid == -1)
	  {
		perror("ccdsys: fork");
		fprintf(stderr,"ccdsys: cannot fork process.  This is a serious error\n");
		fprintf(stderr,"            and you need system help.\n");
		exit(BAD_STATUS);
	  }
	if(pid == 0)	/* child process */
	  {
		ccdsys_home = getenv("CCDHOME");
		strcpy(execname,daserver.sl_srname);
		if(use_tty_output == 0)
		{
		if(-1 == execlp(execname,execname,NULL))
		  {
		    perror("ccdsys: execlp");
		    fprintf(stderr,"ccdsys: cannot exec ccdsys_daemon.  This is a serious\n");
		    fprintf(stderr,"            problem and you need system help.\n");
		    exit(BAD_STATUS);
		  }
		}
		else
		{
		if(-1 == execlp(execname,execname,"-tty",NULL))
		  {
		    perror("ccdsys: execlp");
		    fprintf(stderr,"ccdsys: cannot exec ccdsys_daemon.  This is a serious\n");
		    fprintf(stderr,"            problem and you need system help.\n");
		    exit(BAD_STATUS);
		  }
		}
	  }
  }

usage(fp)
FILE	*fp;
  {
	fprintf(fp,"Usage: ccdsys [-flags] <option>\n");
	fprintf(fp,"       ccdsys status     to find out what is running\n");
	fprintf(fp,"       ccdsys startup    to start ccd software\n");
	fprintf(fp,"       ccdsys shutdown   to shutdown ccd software & daemon\n");
	fprintf(fp,"       ccdsys exit       same as shutdown\n");
	fprintf(fp,"       ccdsys initialize to start up daemon but not processes on a machine.\n");
	fprintf(fp,"                         This is typically used on a machine NOT executing the\n");
	fprintf(fp,"                         primary data collection API but rather just some part\n");
	fprintf(fp,"                         like beamline control only.\n");
  }

#define	EOMSG	"<eom>"

#define	MAXSERVERS	10
main(argc,argv)
int	argc;
char	*argv[];
  {
	int	i,j,nn,n,useropt,ntry,daemonresult;
	int	started_daemonresult;
	int	re_connect_count;
	char	buf[2048];
	struct	serverlist	*slp[MAXSERVERS];
	char	local_host_name[256];
	char	*cp;
	char	*strstr();
	char	*getenv();

	use_tty_output = 1;
	ntry = 0;

	while(argc > 1 && argv[1][0] == '-')
	  {
	    if(0 == strcmp(argv[1],"-log"))
		use_tty_output = 0;
	     else
	      if(0 == strcmp(argv[1],"-tty"))
		use_tty_output = 1;
	     else
	       {
		 fprintf(stderr,"ccdsys: %s is an unknown flag.\n",argv[1]);
		 usage(stderr);
		 exit(BAD_STATUS);
	       }
	    argv++;
	    argc--;
	  }

	if(argc != 2)
	  {
		usage(stderr);
		exit(BAD_STATUS);
	  }
	
	for(i = 0; options[i] != NULL; i++)
	  if(0 == strcmp(options[i],argv[1]))
		break;
	
	if(optnums[i] == -1)
	  {
		usage(stderr);
		exit(BAD_STATUS);
	  }
	useropt = i;


	if(NULL == getenv("CCDHOME"))
	  {
	    fprintf(stderr,"\n\nccdsys:  The environment variable CCDHOME is not set.\n");
	    fprintf(stderr,"             Most likely, the file containing these environment\n");
	    fprintf(stderr,"             variables was not sourced.  Please do so and\n");
	    fprintf(stderr,"             reexecute ccdsys.\n");
	    cleanexit(BAD_STATUS);
	  }
        if(check_environ())
                cleanexit(BAD_STATUS);
        if(apply_reasonable_defaults())
                cleanexit(BAD_STATUS);

	started_daemonresult = -1;
	re_connect_count = 0;

re_connect:

	daemonresult = check_for_daemon(&fddaemon,daserver.sl_hrname,daserver.sl_port);

	if(daemonresult == 1)
	  {
	    if(useropt == OPT_STATUS)
	      {
		fprintf(stderr,"ccdsys: daemon is not running.\n");
		fprintf(stderr,"            This means other processes may not be running.\n");
		fprintf(stderr,"            Use the   ps   command to check.\n");
		exit(GOOD_STATUS);
	      }
		
	    /*
	     *	The daemon is not running.  Start it.
	     */

	    fprintf(stderr,"ccdsys: Starting ccdsys_daemon.\n");
	    fprintf(stderr,"            One moment while this process starts up.\n");

	    ensure_proper_bind(daserver.sl_hrname,daserver.sl_port);

	    startup_daemon();

	    sleep(5);

	    started_daemonresult = check_for_daemon(&fddaemon,daserver.sl_hrname,daserver.sl_port);
	    if(started_daemonresult == 1)
	      {
	        fprintf(stderr,"ccdsys: cannot connect to ccdsys_daemon after startup.\n");
	        exit(BAD_STATUS);
	      }
	  }


/*
 *	The daemon is present and a connection has been established to it.
 *
 *	Send the relevant command to it.
 */

	i = strlen(options[useropt]);

	if(i != write(fddaemon,options[useropt],i))
	  {
	    if(daemonresult == 1)
	      {
	        perror("ccdsys: write to daemon: ");
	        fprintf(stderr,"ccdsys: write to daemon failed.\n");
	        fprintf(stderr,"            Since the daemon was already running when this error occurred, you\n");
	        fprintf(stderr,"            should probably check and kill all likely processes running on this\n");
	        fprintf(stderr,"            machine, wait a minute or so, then execute ccdsys again.\n");
	        exit(GOOD_STATUS);
	      }
	     else
	      {
		perror("ccdsys: write to daemon: ");
	        fprintf(stderr,"ccdsys: write to daemon failed.\n");
		re_connect_count++;
		if(re_connect_count == 1)
		  {
	            fprintf(stderr,"            The daemon was running when ccdsys was entered, or was in the\n");
	            fprintf(stderr,"            process of shutting down.  We will try to revive it and reconnect\n");
	            fprintf(stderr,"            to it.  Sleep 5 seconds in any case.\n");
		    sleep(5);
		    goto re_connect;
		  }
	        fprintf(stderr,"            One reconnect attempt has failed, so you\n");
	        fprintf(stderr,"            should probably check and kill all likely processes running on this\n");
	        fprintf(stderr,"            machine, wait a minute or so, then execute ccdsys again.\n");
	        exit(GOOD_STATUS);
	      }
	  }

/*
 *	Read this socket connection until eof is found.
 */

	while(1)
	  {
		i = read(fddaemon,buf,sizeof buf);
		if(i == 0)
			break;
		if(i == -1)
		  {
			fprintf(stderr,"ccdsys_neccdsys: Error reading message from daemon.  You need system help.\n");
			exit(BAD_STATUS);
		  }
		cp = strstr(buf,EOMSG);
		if(cp == NULL)
			write(1,buf,i);
		  else
		    {
			*cp = '\0';
			write(1,buf,cp - buf);
			break;
		    }
	  }
	close(fddaemon);

	if(useropt == OPT_INIT)
		exit(GOOD_STATUS);

	/*
	 *	Extend this arrangement to trying to contact daemons on
	 *	the appropriate port number on all machines listed in
	 *	the environment.
	 */

	slp[0] = &dcserver;
	slp[1] = &blserver;
	slp[2] = &daserver;
	slp[3] = &xfserver;
	slp[4] = &stserver;

	n = 5;

	gethostname(local_host_name,256);

	fprintf(stderr,"ccdsys: checking for daemons on machines other than %s\n",local_host_name);

	for(nn = 0; nn < n; nn++)
	  {
	    if(slp[nn] == NULL)
		continue;
	    if(0 == strcmp(slp[nn]->sl_hrname, local_host_name))
		continue;

	    fprintf(stderr,"ccdsys: Looking for a connection to a daemon on hostname %s\n",slp[nn]->sl_hrname);
	    daemonresult = check_for_daemon(&fddaemon,slp[nn]->sl_hrname,daserver.sl_port);

	    if(daemonresult == 1)
	      {
		fprintf(stderr,"ccdsys:  Warning:  no daemon running on hostname %s\n",slp[nn]->sl_hrname);
		fprintf(stderr,"         This is OK if you intend to start the processes\n");
		fprintf(stderr,"         belonging to that host by hand.  Otherwise, all processes\n");
		fprintf(stderr,"         can be started automatically if ccdsys -tty initialize\n");
		fprintf(stderr,"         is executed on hostname %s AND you execute ccdsys -tty startup\n",slp[nn]->sl_hrname);
		fprintf(stderr,"         again on THIS host.\n");
		for(j = 0; j < n; j++)
		  if(j != nn && slp[j] != NULL)
		    if(0 == strcmp(slp[nn]->sl_hrname,slp[j]->sl_hrname))
			slp[j] = NULL;
		slp[nn] = NULL;
		continue;
	      }
	    fprintf(stderr,"ccdsys: Contact made with ccd_daemon running on hostname %s.\n",slp[nn]->sl_hrname);
	/*
	 *	The daemon is present and a connection has been established to it.
	 *
	 *	Send the relevant command to it.
	 */

	    i = strlen(options[useropt]);

	    if(i != write(fddaemon,options[useropt],i))
	      {
	        perror("ccdsys: write to daemon: ");
	        fprintf(stderr,"ccdsys: write to daemon failed on hostname %s.\n",slp[nn]->sl_hrname);
	        fprintf(stderr,"            Since the daemon was already running when this error occurred, you\n");
	        fprintf(stderr,"            should probably check and kill all likely processes running on this\n");
	        fprintf(stderr,"            machine, wait a minute or so, then execute ccdsys again.\n");
	   	goto finish_up;
	      }

	/*
	 *	Read this socket connection until eof is found.
	 */

	    while(1)
	      {
		i = read(fddaemon,buf,sizeof buf);
		if(i == 0)
			break;
		if(i == -1)
		  {
			fprintf(stderr,"ccdsys: Error reading message from daemon.  You need system help.\n");
			goto finish_up;
		  }
		cp = strstr(buf,EOMSG);
		if(cp == NULL)
			write(1,buf,i);
		  else
		    {
			*cp = '\0';
			write(1,buf,cp - buf);
			break;
		    }
	      }
finish_up:

	    close(fddaemon);
	    for(j = 0; j < n; j++)
	      if(j != nn && slp[j] != NULL)
		if(0 == strcmp(slp[nn]->sl_hrname,slp[j]->sl_hrname))
		  slp[j] = NULL;
	    slp[nn] = NULL;
	  }

	exit(GOOD_STATUS);
  }

cleanexit(status)
int	status;
  {
	exit(status);
  }
