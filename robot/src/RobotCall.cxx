/*
#include        <cstdio>
#include	<cstring>
#include        <cmath>
#include        <cerrno>
#include        <csignal>
#include        <sys/types.h>
#include        <sys/time.h>
#include        <sys/socket.h>
#include        <netinet/in.h>

#include        <netdb.h>
#include  	<unistd.h>
*/
#include 	"RobotCall.h"


/*
 *	read_port_raw:
 *
 *	Read data until there is none left.  Don't block.
 */

/*
int     read_port_raw(int, char*, int);
int     rep_write(int,char *,int);
int     sio_string_found(char *,int,char *);
int     read_until(int,char *,int,char *);
int     get_current_energy_from_control(double *);
int     send_wavelength_request_to_control(double *, char *);
*/

char local_control_host[]="10.0.0.4";
int  local_control_port=8059;

int	read_port_raw(int fd,char *stbuf,int stbufsize)
{	
	int	nread;
	fd_set	readmask;
	int	ret;
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
	    ret = read(fd,stbuf + nread,stbufsize - nread);
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

/*
 *	Function to do a write, with possible multiple chunks.
 *	We need this because of unknown buffering over the network.
 *
 *	The write blocks.
 *
 *	Returns the number of characters written, or -1 if an error.
 */

int	rep_write(int fd,char *buf, int count)
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

/*
 *	ccd_dc_sio:
 *
 *		Perform buffered reads and writes over socket
 *		connections.  The routines below are necessary
 *		since we don't have control over the way messages
 *		are broken up over the net.
 *
 */
int 	sio_string_found(char * buf,int idex,char * ss)
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

int	read_until(int fd,char* buf,int maxchar,char* looking_for)
{
	int	eobuf,looklen,ret,utindex;
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
 *      connect_to_host         connect to specified host & port.
 *
 *      Issue a connect to the specified host and port.  If the
 *      connection is sucessful, write the string (if non-null)
 *      msg over the socket.
 *
 *      If the operation is a sucess, returns the file descriptor
 *      for the socket via the fdnet pointer.  If this is -1, then
 *      the connection/message tranmission failed.
 *
 *      Also, returns the file descriptor if sucessful, otherwise
 *      -1.
 */

int     connect_to_host_api(int *fdnet, char *host,int port, char *msg)
{
        int     s;
        struct  sockaddr_in     server;
        int     len;
        struct  hostent *hentptr,hent;
        char    localmsg[256];

        hentptr = gethostbyname(host);
        if(hentptr == NULL)
        {
            fprintf(stderr,"connect_to_host: no hostentry for machine %s\n",host);
            *fdnet = -1;
            return(*fdnet);
        }
        hent = *hentptr;

        if(0)   /* DEBUG */
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
                fprintf(stderr,"connect_to_host_api: connection refused: %d\n",
                        WSAGetLastError ());
                closesocket(s);
#else
                perror("connect");
                close(s);
#endif /* WINNT */
                return(*fdnet);
        }
        if(0)   /* DEBUG */
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
              if(len != send(s,msg,len, 0))
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


int     get_current_energy_from_control(double *wp)
{
        int     fd;
        int     buflen;
        char    buf[100];
        char    *cp;
        float   new_energy;

        if(local_control_port == -1)
                return(-1);

        if(-1 == (fd = connect_to_host_api(&fd, local_control_host, local_control_port, NULL)))
        {
                fprintf(stderr,"get_current_energy_from_control: connection to host %s port %d was refused\n",
                        local_control_host, local_control_port);
                perror("get_current_energy_from_control");
                return(-1);
        }

        sprintf(buf, "getenergy\n");
        buflen = strlen(buf);
        if(-1 == rep_write(fd, buf, buflen))
        {
                close(fd);
                return(-1);
        }
        if(0 >= read_until(fd, buf, sizeof buf, "done"))
        {
                close(fd);
                return(-1);
        }
        if(NULL == (cp = strstr(buf, "error")))
        {
                sscanf(buf, "%f", &new_energy);
		*wp = new_energy;
         //       new_wavelength = EV_ANGSTROM / new_energy;
         //       *wp = new_wavelength;
                 fprintf(stderr,"get_current_energy_from_control: energy: %.6f\n", new_energy);
                close(fd);
                return(0);
        }
        fprintf(stderr,"get_current_energy_from_control: Error setting energy: buf: %s\n", buf);
        close(fd);
        return(-1);
}

int     send_energy_request_to_control(double *wp)
{
        int     fd;
        int     buflen;
        char    buf[100];
        char    *cp;
        float   new_energy;


        if(local_control_port == -1)
                return(-1);

        if(-1 == (fd = connect_to_host_api(&fd, local_control_host, local_control_port, NULL)))
                return(-1);

        new_energy = *wp;
        sprintf(buf, "moveenergy %.3f 1\n", new_energy);
        buflen = strlen(buf);
// to simulate the energy change, use "return(0)" here. so that the energy will not be changed. Then recompile the program.
	return(0);
        if(-1 == rep_write(fd, buf, buflen))
        {
                close(fd);
                return(-1);
        }
        if(0 >= read_until(fd, buf, sizeof buf, "done"))
        {
                close(fd);
                return(-1);
        }
        if(NULL == (cp = strstr(buf, "error")))
        {
                sscanf(buf, "%f", &new_energy);
                // new_wavelength = EV_ANGSTROM / new_energy;
                *wp = new_energy;
                close(fd);
                return(0);
        }
        fprintf(stderr,"send_energy_request_to_control: Error setting energy: buf: %s\n", buf);
        close(fd);
        return(-1);
}
