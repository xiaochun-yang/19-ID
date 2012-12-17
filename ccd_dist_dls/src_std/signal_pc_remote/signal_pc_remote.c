/*
 *	unix
 */

#ifdef unix
#include	<stdio.h>
#include	<math.h>
#include	<errno.h>
#include        <sys/types.h>
#include        <sys/time.h>
#include        <sys/socket.h>
#include        <netinet/in.h>
#include	<netdb.h>
#endif /* unix */

#ifdef alpha
#include	<string.h>
#endif /* alpha */


/*
 *  Win NT includes
 */

#ifdef	WINNT
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <fcntl.h>
#include <winsock.h>
#include <time.h>
#include <sys/timeb.h>
#include <malloc.h>
#include <math.h>
#include <io.h>
#include <errno.h>
#include "windows.h"
#endif /* WINNT */

/*
 *	Compatibility
 */

#ifdef unix
#include	"win_compat.h"
#define		closesocket	close
#endif /* unix */


/*
 *	read_port_raw:
 *
 *		Read data until there is none left.  Don't block.
 */

static	int		read_port_raw(int fd,char *stbuf,int stbufsize)
{
	int				nread;
	fd_set			readmask;
	int				ret;
	struct timeval	timeout;

	nread = 0;

	while(1)
	  {
	    FD_ZERO(&readmask);
	    FD_SET(fd,&readmask);
	    timeout.tv_usec = 0;
	    timeout.tv_sec = 0;
	    ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	    if(ret == 0)
			return(nread);
	    if(ret == -1)
	      {
			if(errno == EINTR)
		  	  continue;	/* Ignore interrupted system calls */
			return(-1);
	      }
	    if(0 == FD_ISSET(fd,&readmask))
	      {
			return(nread);
	      }
	    ret = recv(fd,stbuf + nread,stbufsize - nread,0);
	    if(ret == -1)
	      {
			if(errno == EINTR)
		  	continue;	/* Ignore interrupted system calls */
			return(-1);
	      }
	    if(ret == 0)
	      {
			return(-1);
	      }
	    nread += ret;
	  }
}
  
static	int		check_port_raw(int fd)
{
	fd_set			readmask;
	int				ret;
	struct timeval	timeout;

	FD_ZERO(&readmask);
	FD_SET(fd,&readmask);
	timeout.tv_usec = 0;
	timeout.tv_sec = 1;
	ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	if(ret == 0)
		return(0);
	if(ret == -1)
	  {
	    if(errno == EINTR)
		    return(0);		/* Ignore interrupted system calls */
		  else
		  	return(-1);
	  }
	 return(1);
}

static	int     probe_port_raw(int fd)
{
        fd_set                  readmask;
        int                             ret;
        struct timeval  timeout;
        char                    cbuf;

        FD_ZERO(&readmask);
        FD_SET(fd,&readmask);
        timeout.tv_usec = 10000;
        timeout.tv_sec = 0;
        ret = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
        if(ret == 0)
                return(0);
        if(ret == -1)
          {
            if(errno == EINTR)
                    return(0);          /* Ignore interrupted system calls */
                  else
                        return(-1);
          }
         if(1 != recv(fd,&cbuf,1,MSG_PEEK))
                return(-1);
          else
                return(1);
}

/*
 *	connect_to_host		connect to specified host & port.
 *
 *	Issue a connect to the specified host and port.  If the
 *	connection is sucessful, write the string (if non-null)
 *	msg over the socket.
 *
 *	If the operation is a sucess, returns the file descriptor
 *	for the socket via the fdnet pointer.  If this is -1, then
 *	the connection/message tranmission failed.
 *
 *	Also, returns the file descriptor if sucessful, otherwise
 *	-1.
 */

static	int	connect_to_host_api(fdnet,host,port,msg)
int	*fdnet;
char	*host;
int	port;
char	*msg;
{
	int	s;
	struct	sockaddr_in	server;
	int	len;
	struct	hostent	*hentptr,hent;
	char	localmsg[256];

	hentptr = gethostbyname(host);
	if(hentptr == NULL)
	{
	    fprintf(stderr,"connect_to_host: no hostentry for machine %s\n",host);
	    *fdnet = -1;
	    return(*fdnet);
	}
	hent = *hentptr;

	if(0)	/* DEBUG */
	  fprintf(stdout,"connect_to_host: establishing network connection to host %s, port %d\n",host,port);

	if(-1 == (s = socket(AF_INET, SOCK_STREAM, 0)))
	{
		perror("connect_to_host: socket creation");
	    	*fdnet = -1;
		return(*fdnet);
	}

	server.sin_family = AF_INET;
	server.sin_addr = *((struct in_addr *) hent.h_addr);
	server.sin_port = htons((unsigned short) port);

	if(connect(s, (struct sockaddr *) &server,sizeof server) < 0)
	{
		*fdnet = -1;
		closesocket(s);
		return(*fdnet);
	}
	if(0)	/* DEBUG */
		fprintf(stdout,
		"connect_to_host: connection established with host on machine %s, port %d.\n",
					host,port);
	if(msg != NULL)
	{
	    strcpy(localmsg,msg);
	    len = (int) strlen(msg);
	    localmsg[len] = '\0';
	    if(len > 0)
	    {
	      len++;
	      if(len != write(s,msg,len))
		  {
		  fprintf(stdout,"connect_to_host: failure writing connect string (%s) command to host.\n",msg);
		  *fdnet = -1;
		   closesocket(s);
		   return(*fdnet);
		  }
	     }
	}

	*fdnet = s;
	return(*fdnet);
}

#ifdef SIGNAL_PC_REMOTE_MAIN

main(argc, argv)
int	argc;
char	*argv[];
{
	int	command_fd;
	int	probe_state;
	int	command_port_no;
	int	i, cmd, nb, probe_stat;
	char	host[256];
	char	function[256];
	char	reply[100];
	static 	int	no_warnings = 1;

	if(argc < 4)
	{
		fprintf(stderr,"Usage: signal_pc_remote host port function\n");
		exit(0);
	}

	strcpy(host, argv[1]);
	command_port_no = atoi(argv[2]);
	strcpy(function, argv[3]);

	if(0 == strcmp(function, "NULL"))
	{
		/*
		 *	Old-style.
		 */

	        if(-1 != (command_fd = connect_to_host(&command_fd, host, command_port_no, NULL)))
	        {
	        	fprintf(stderr,"signal_pc_remote   : connection for command accepted from remote (fd: %d)\n",
	                                                        command_fd);
	        }
	        else
	        {
			fprintf(stderr,"signal_pc_remote: REMOTE STARTUP PROGRAM NOT RUNNING\n");
			exit(0);
		}
		/*
		 *	Wait around until the socket has been close by remote program.
		 */
		for(i = 0; i < 20; i++)
		{
			if(-1 == probe_port_raw(command_fd))
			{
				fprintf(stderr,"signal_pc_remote: remote TASK_SUCESS\n");
				exit(0);
			}
			sleep(1);
		}
		fprintf(stderr,"signal_pc_remote: timeout: remote TASK_FAIL\n");
		exit(0);
	}

	/*
	 *	New-style, where we give a function:
	 *
	 *	restart		stop and restart the det_module_plus
	 *	shutdown	stop the det_module_plus
	 *	status		return the state, running or not_running.
	 *
	 *	Status will be used by quantum console to figure out if it
	 *	should restart the api or not.  In general, if it's running
	 *	it may be connected to the unix workstation and it would
	 *	be bad to restart it.
	 */

	cmd = -1;
	if(0 == strcmp(function, "restart"))
		cmd = 0;
	else if(0 == strcmp(function, "shutdown"))
		cmd = 1;
	else if(0 == strcmp(function, "status"))
		cmd = 2;
	if(cmd == -1)
	{
		fprintf(stderr,"signal_pc_remote: ERROR: %s is an unknown function\n", function);
		exit(0);
	}
	if(-1 != (command_fd = connect_to_host(&command_fd, host, command_port_no, function)))
	{
		fprintf(stderr,"signal_pc_remote   : connection for command accepted from remote (fd: %d)\n",
		command_fd);
	}
	else
	{
		if(no_warnings == 0)
			fprintf(stderr,"signal_pc_remote: REMOTE STARTUP PROGRAM NOT RUNNING\n");
		exit(0);
	}
	for(i = 0; i < 5; i++)
	{
		if(0 == (probe_stat = probe_port_raw(command_fd)))
		{
			sleep(1);
			continue;
		}
		if(-1 == probe_stat)
		{
			if(no_warnings == 0)
				fprintf(stdout,"signal_pc_remote: ERROR no_reply_received\n");
			closesocket(command_fd);
			exit(0);
		}
		if(1 == probe_stat)
		{
			nb = read_port_raw(command_fd, reply, sizeof reply);
			if(nb <= 0)
			{
				if(no_warnings == 0)
					fprintf(stdout,"signal_pc_remote: ERROR no_reply_received\n");
				closesocket(command_fd);
				exit(0);
			}
			reply[nb] = '\0';
			fprintf(stdout,"signal_pc_remote: %s", reply);
			closesocket(command_fd);
			exit(0);
		}
	}
	if(no_warnings == 0)
		fprintf(stdout,"signal_pc_remote: ERROR no_reply_received_timeout\n");
	closesocket(command_fd);
	exit(0);

}

#endif /* SIGNAL_PC_REMOTE_MAIN */
