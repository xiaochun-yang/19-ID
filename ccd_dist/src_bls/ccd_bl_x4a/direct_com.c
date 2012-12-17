#include	<stdio.h>
#include	<sys/types.h>
#include	<sys/time.h>
#include	<termio.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#include	<errno.h>
#include	<math.h>

static	int	socket_fd;
static	int	gonio_err;
static	int	socket_err;

static struct timeval	*readtimeout = NULL;
static struct timeval  readtimeval;

/*
 *      Return a character from the input channel.  Return -1 if
 *      this operation timed out.
 */

int     em_readraw(fd)
{
	fd_set  readmask, writemask, exceptmask;
        char    rbuf;
	int	nb;

  redo_read:

	readtimeval.tv_sec = 0;
	readtimeval.tv_usec = 0;
	readtimeout = &readtimeval;

        FD_ZERO(&readmask);
        FD_SET(fd, &readmask);
        nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, readtimeout);
        if(nb == -1)
        {
                if(errno == EINTR)
			return(-1);

                fprintf(stderr,"tty_em: select error (in readraw).  Should never happen.\n");
                perror("tty_em: select in ccd_check_alive");
                return(-2);
        }
        if(nb == 0)
        {
                return(-1);         /* timed out */
        }
        if(0 == FD_ISSET(fd, &readmask))
        {
                return(-1);         /* timed out */
        }
        if(0 >= read(fd,&rbuf,1))
        {
        	return(-2);
        }
        return(rbuf);
}

int     em_writeraw(int fd, int c)
{
	char	wbuf;
	
	wbuf = (char) c;

        if(-1 == write(fd, &wbuf, 1))
        {
        	fprintf(stderr,"writeraw: error writing tty input\n");
        	return(-2);
        }
        return(0);
}

void	read_socket_input(arg)
int	arg;
{
	int	read_res;

	while(1)
	{
		read_res = em_readraw(socket_fd);
		if(read_res == -1)
			break;
		if(read_res == -2)
		{
			gonio_err = 1;
			return;
		}
		cmwriteraw(read_res);
	}
}

void	read_gonio_input(arg)
int	arg;
{
	int	read_res, write_res;

	while(1)
	{
		read_res = cmreadraw();
		if(read_res == -1)
			break;
		write_res = em_writeraw(socket_fd, read_res);
		if(write_res == -2)
		{
			socket_err = 1;
			return;
		}
	}
}

direct_communications(int fdsocket)
{
	char	line[256];
	int	i;

	socket_fd = fdsocket;

	gonio_err = 0;
	socket_err = 0;

	readtimeval.tv_sec = 0;
	readtimeval.tv_usec = 0;
	readtimeout = &readtimeval;

	cm_settimeout(0);

	while(1)
	{
		Sleep(20);
		read_socket_input(0);
		read_gonio_input(0);

		if(gonio_err == 1 || socket_err == 1)
		{
			break;
		}
	}
}
