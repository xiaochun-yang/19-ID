#include	<stdio.h>
#include	<sys/types.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#include	<netdb.h>
#include	<errno.h>
#include	"../incl/ccdsys.h"

/*
 *      Entries for network names, ports, etc.
 */

extern struct serverlist        dcserver;
extern struct serverlist        daserver;
extern struct serverlist        xfserver;
extern struct serverlist        stserver;
extern struct serverlist        conserver;
extern struct serverlist        viewserver;
extern int                      mar_communication;

/*
 *	Client process to connect the adx gui to the
 *	ccd_dc process.
 */


static	int	command_socket = -1;

#ifdef NOT_USED
shutdown_command_connection()
  {
	if(command_socket != -1)
		close(command_socket);
  }
#endif /* NOT_USED */

connect_to_dcserver(fpp)
FILE	**fpp;
  {
	FILE	*fp;

	if(check_environ()) {
	  *fpp = NULL;
	  return;
	}
        if(apply_reasonable_defaults()) {
	  *fpp = NULL;
	  return;
	}

	if(-1 == connect_to_host(&command_socket,dcserver.sl_hrname,dcserver.sl_port,"connect command"))
	  {
	    fprintf(stderr,"adx_ccd_network: cannot connect to ccd_dc data collection server.\n");
	    *fpp = NULL;
	    return;
	  }
	fprintf(stdout,"adx: connection established to ccd_dc.\n");
	fp = fdopen(command_socket,"r+");
	*fpp = fp;
	return;
  }

/*
 *	connect_to_host_silent		connect to specified host & port, no messages
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

int	connect_to_host_silent(fdnet,host,port,msg)
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
		if(0)
			fprintf(stderr,"connect_to_host: no hostentry for machine %s\n",host);
	    *fdnet = -1;
	    return(*fdnet);
	}
	hent = *hentptr;

	if(0)	/* DEBUG */
		fprintf(stdout,"connect_to_host: establishing network connection to host %s, port %d\n",host,port);

	if(-1 == (s = socket(AF_INET, SOCK_STREAM, 0)))
	{
		if(0)
			perror("connect_to_host: socket creation");
	    	*fdnet = -1;
		return(*fdnet);
	}

	server.sin_family = AF_INET;
	server.sin_addr = *((struct in_addr *) hent.h_addr);
	server.sin_port = htons(port);

	if(connect(s, (struct sockaddr *) &server,sizeof server) < 0)
	{
		if(0)
			perror("connect_to_host: connect");
		close(s);
		*fdnet = -1;
		return(*fdnet);
	}
	if(0)	/* DEBUG */
		fprintf(stdout,"connect_to_host: connection established with host on machine %s, port %d.\n",host,port);
	if(msg != NULL)
	{
		strcpy(localmsg,msg);
		len = strlen(msg);
		localmsg[len] = '\0';
		if(len > 0)
		{
			len++;
			if(len != write(s,msg,len))
			{
				if(0)
					fprintf(stdout,
						"connect_to_host: failure writing connect string (%s) command to host.\n",msg);
				close(s);
				*fdnet = -1;
				return(*fdnet);
			}
		}
	}

	*fdnet = s;
	return(*fdnet);
}

/*
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
		    perror("rep_write");
		    return(-1);
		}
		remcount -= i;
		pos += i;
	}
	return(count);
}

int     probe_port_raw_with_timeout(int fd, int nmicrosecs)
{
        fd_set		readmask;
        int 		ret;
        struct timeval  timeout;
        char		cbuf;
	int 		nsec;

	nsec = nmicrosecs / 1000000;
	nmicrosecs -= (nsec * 1000000);

	FD_ZERO(&readmask);
	FD_SET(fd,&readmask);
	timeout.tv_usec = nmicrosecs;
	timeout.tv_sec = nsec;
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
