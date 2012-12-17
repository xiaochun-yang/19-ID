#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<sys/types.h>
#include	<sys/time.h>
#include	<termio.h>
#include	<sys/socket.h>
#include	<netinet/in.h>
#include	<errno.h>
#include	<math.h>

static	int	motfd;


static struct timeval	*readtimeout = NULL;
static struct timeval  readtimeval;

/*
 *      Return a character from the input channel.  Return -1 if
 *      this operation timed out.
 */

int     em_readraw()
  {
	fd_set  readmask, writemask, exceptmask;
        char    rbuf;
	int	nb;

  redo_read:

        FD_ZERO(&readmask);
        FD_SET(motfd,&readmask);
        nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, readtimeout);
        if(nb == -1)
          {
                if(errno == EINTR)
		  goto redo_read;

                fprintf(stderr,"tty_em_socket: select error (in readraw).  Should never happen.\n");
                perror("tty_em_socket: select in ccd_check_alive");
                exit(0);
          }
        if(nb == 0)
          {
                return(-1);         /* timed out */
          }
        if(0 == FD_ISSET(motfd, &readmask))
          {
                return(-1);         /* timed out */
          }


        if(-1 == read(motfd,&rbuf,1))
          {
            fprintf(stderr,"readraw: error reading tty input\n");
            exit(0);
          }
        return(rbuf);
  }

int     em_writeraw(c)
char    c;
  {
        char    wbuf;
        wbuf = c;

        if(-1 == write(motfd,&wbuf,1))
          {
            fprintf(stderr,"writeraw: error writing tty input\n");
            exit(0);
          }
        return(0);
  }

int	em_init_socket(char *host, char *port)
{
	char	c;
	int	i1,i2,i3,i4,i5;
	int	portnum;
	int	mind;
	char	line[132];

	portnum = atoi(port);

	if(-1 == connect_to_host(&motfd, host, portnum, NULL))
	{
	    fprintf(stderr,"tty_em_socket: Cannot connect to port %s on host %s for goniostat control.\n",
		host, port);
	    return(1);
	}

	readtimeval.tv_sec = 0;
	readtimeval.tv_usec = 0;
	readtimeout = &readtimeval;

	return(0);
}

int	em_close()
  {
	close(motfd);
  }

void	read_mot(arg)
int	arg;
  {
	int	i;
	char	c;
	char	cprev;

	cprev = '\0';

	while(-1 != (i = em_readraw()))
	  {
	    c = i & 0xff;
	    if(c != '\r')
	      {
		if(cprev == '\n' && c == '\n')
		  {
		    cprev = c;
		  }
		 else
		  {
		    cprev = c;
	            write(1,&c,1);
		  }
	      }
	  }
	enqueue_fcn(read_mot,arg,0.1);
  }

main(argc,argv)
int	argc;
char	*argv[];
  {
	char	line[256];
	int	i;
	FILE	*fp;

	if(argc < 2)
	{
	    fprintf(stderr,"Usage: tty_em_socket host port\n");
	    exit(0);
	}
	if(em_init_socket(argv[1], argv[2]))
	    exit(0);

	init_clock();

	enqueue_fcn(read_mot,0,0.1);

	while(NULL != fgets(line,sizeof line, stdin))
	{
	    if(line[0] == '@')
	    {
		line[strlen(line) - 1] = '\0';

		if(NULL == (fp = fopen(&line[1],"r")))
		{
			fprintf(stderr,"tty_em_socket: cannot open %s as file to download\n", &line[1]);
			continue;
		}
		while(NULL != fgets(line, sizeof line, fp))
		{
	    		for(i = 0; line[i] != '\n'; i++)
				em_writeraw(line[i]);
	    		em_writeraw('\r');
			usleep(100000);
		}
		fclose(fp);
		continue;
	    }

	    for(i = 0; line[i] != '\n'; i++)
		em_writeraw(line[i]);
	    em_writeraw('\r');
	}
	em_close();
	fprintf(stderr,"em_tty: Exiting on user's EOF\n");
  }
