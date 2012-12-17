#include	"defs.h"

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
#ifdef WINNT
		closesocket(s);
#else
		close(s);
#endif /* WINNT */
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
#ifdef WINNT
		   closesocket(s);
#else
		   close(s);
#endif /* WINNT */
		   return(*fdnet);
		  }
	     }
	}

	*fdnet = s;
	return(*fdnet);
}
