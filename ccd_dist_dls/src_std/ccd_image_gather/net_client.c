#include	<stdio.h>
#include	<sys/types.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#include	<netdb.h>
#include	<errno.h>

#ifdef	alpha
#include	<string.h>
#endif /* alpha */

/*
 *	connect_to_host_api		connect to specified host & port.
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

int	connect_to_host_api(fdnet,host,port,msg)
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
	    fprintf(stderr,"connect_to_host_api: no hostentry for machine %s\n",host);
	    *fdnet = -1;
	    return(*fdnet);
	  }
	hent = *hentptr;

	if(0)	/* DEBUG */
	  fprintf(stdout,"connect_to_host_api: establishing network connection to host %s, port %d\n",host,port);

	if(-1 == (s = socket(AF_INET, SOCK_STREAM, 0)))
	  {
		perror("connect_to_host_api: socket creation");
	    	*fdnet = -1;
		return(*fdnet);
	  }

	server.sin_family = AF_INET;
	server.sin_addr = *((struct in_addr *) hent.h_addr);
	server.sin_port = htons(port);

	if(connect(s, (struct sockaddr *) &server,sizeof server) < 0)
	  {
		*fdnet = -1;
		close(s);
		return(*fdnet);
	  }
	if(0)	/* DEBUG */
	  fprintf(stdout,"connect_to_host_api: connection established with host on machine %s, port %d.\n",host,port);
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
		  fprintf(stdout,"connect_to_host_api: failure writing connect string (%s) command to host.\n",msg);
		  *fdnet = -1;
		  close(s);
		  return(*fdnet);
		}
	      }
	  }

	*fdnet = s;
	return(*fdnet);
  }
