#include	<stdio.h>
#include	<termio.h>
#include	<sys/types.h>
#include	<sys/time.h>
#include	<sys/socket.h>
#include	<errno.h>
#include	<math.h>

static	int	motfd;
static	int	keybdfd;
static	char	vmin0;
static	int	cmdebug = 1;
static	int	cmdelay1 = 0;
static	int	testdelay1 = 0;
static	int	testdelay2 = 0;

static short    cmchanno;              /* the channel number */
static int      cmsenseret[3];         /* status info for set/reset */
static char     cmretstring[80];
static char     cmretcopy[80];         /* a copy of the last returned string */
static char     cmsentcopy[80];        /* a copy of the last command sent */
static char     ex_sent_str[80];
static char     ex_ret_str[80];
static int      cmretlen;

static struct timeval	*readtimeout = NULL;
static struct timeval  readtimeval;

cmsetnoecho()
  {
        struct termio arg;

        if(-1 == ioctl(motfd,TCGETA,&arg))
          {
            fprintf(stderr,"Setnoecho: Error on IOCTL call to get term params\n");
            exit(0);
          }
	arg.c_oflag &= ~ONLCR;
	arg.c_oflag &= ~OCRNL;
	arg.c_oflag &= ~ONOCR;
	arg.c_oflag &= ~ONLRET;
        arg.c_lflag &= ~ECHO;
        arg.c_lflag &= ~ICANON;
	arg.c_cflag &= ~CLOCAL;
        vmin0 = arg.c_cc[VMIN];
        arg.c_cc[VMIN] = 1;
        if(-1 == ioctl(motfd,TCSETA,&arg))
          {
            fprintf(stderr,"Setnoecho: Error on IOCTL call to set term params\n");
            exit(0);
          }
  }

cmprintttymode()
  {
        struct termio arg;

        if(-1 == ioctl(motfd,TCGETA,&arg))
          {
            fprintf(stderr,"Setnoecho: Error on IOCTL call to get term params\n");
            exit(0);
          }
	fprintf(stderr,"tty modes:\n");
	fprintf(stderr,"c_iflag: %x (octal %o)\n",arg.c_iflag,arg.c_iflag);
	fprintf(stderr,"c_oflag: %x (octal %o)\n",arg.c_oflag,arg.c_oflag);
	fprintf(stderr,"c_lflag: %x (octal %o)\n",arg.c_lflag,arg.c_lflag);
	fprintf(stderr,"c_cflag: %x (octal %o)\n",arg.c_cflag,arg.c_cflag);
  }

cmsetecho()
  {
        struct termio arg;

        if(-1 == ioctl(motfd,TCGETA,&arg))
          {
            fprintf(stderr,"Setecho: Error on IOCTL call to get term params\n");
            exit(0);
          }
	arg.c_oflag |= ONLCR;
	arg.c_oflag |= OCRNL;
	arg.c_oflag |= ONOCR;
	arg.c_oflag |= ONLRET;
        arg.c_lflag |= ECHO;
        arg.c_lflag |= ICANON;
	arg.c_cflag |= CLOCAL;
        arg.c_cc[VMIN] = vmin0;
        if(-1 == ioctl(motfd,TCSETA,&arg))
          {
            fprintf(stderr,"Setecho: Error on IOCTL call to set term params\n");
            exit(0);
          }
  }

/*
 *      Return a character from the input channel.  Return -1 if
 *      this operation timed out.
 */

int     cm_loop()
  {
	fd_set  readmask, writemask, exceptmask;
        char    rbuf;
	int	nb,ret;

  redo_read:
	while(1)
	  {
            FD_ZERO(&readmask);
            FD_SET(motfd,&readmask);
	    FD_SET(keybdfd,&readmask);
            nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, NULL);
            if(nb == -1)
              {
                if(errno == EINTR)
		  continue;

                fprintf(stderr,"cm_loop: select error (in readraw).  Should never happen.\n");
                perror("cm_loop: select in ccd_check_alive");
		cmsetecho();
                exit(0);
              }
            if(nb == 0)
              {
		continue;
              }
            if(0 != FD_ISSET(motfd, &readmask))
	      {
                ret == read(motfd,&rbuf,1);
		if(ret == -1)
                  {
                    fprintf(stderr,"cm_loop: error reading tty input\n");
                    exit(0);
                  }
		 else
		  if(ret == 0)
		    {
		      fprintf(stderr,"cm_loop: EOF on motor file descriptor\n");
		      return;
		    }
		    else
		     write(1,&rbuf,1);
	      }
            if(0 != FD_ISSET(keybdfd, &readmask))
	      {
                ret == read(keybdfd,&rbuf,1);
		if(ret == -1)
                  {
                    fprintf(stderr,"cm_loop: error reading tty input\n");
                    exit(0);
                  }
		 else
		  if(ret == 0)
		    {
		      fprintf(stderr,"cm_loop: EOF on users input tty file descriptor\n");
		      return;
		    }
		   else
		  	write(motfd,&rbuf,1);
	      }
	  }
  }

int     cmwriteraw(c)
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

cmreadraw()
  {
  }
int	cm_input(line)
char	*line;
  {
	int	i,j;
	char	c;

	j = 0;
	do {
	    i = cmreadraw();
	    if(i == -1)
	      {
		fprintf(stderr,"cm_input: timeout detected\n");
		line[j] = '\0';
		return(1);
	      }
	    c = (char) i;
	    if(c != '\r')
	      {
		line[j++] = c;
		if(cmdebug)
		  fprintf(stderr,"%c",c);
	      }
	    } while(c != '>');
	i = cmreadraw();
	if(i == -1)
	  {
		fprintf(stderr,"cm_input: timeout detected\n");
		line[j] = '\0';
		return(1);
	  }
	line[j] = (char) i;
	if(cmdebug)
	  fprintf(stderr,"%c",line[j]);
	j++;
	line[j] = '\0';
	return(0);
  }

int	cm_output(line)
char	*line;
 {
	int	i;

        for(i = 0; !(line[i] == '\n' || line[i] == '\0'); i++)
	  {
            cmwriteraw(line[i]);
	    if(cmdebug)
	      fprintf(stderr,"%c",line[i]);
	  }
        cmwriteraw('\n');
	if(cmdebug)
	  fprintf(stderr,"\n");
	return(0);
  }

int	cm_init(ttyname)
char	*ttyname;
  {
	char	c;
	int	i1,i2,i3,i4,i5;
	int	mind;
	char	line[132];

	if(-1 == (motfd = open(ttyname,2)))
	  {
	    fprintf(stderr,"cm_init: Canot open %s as kappa goniostat tty.\n",ttyname);
	    return(1);
	  }
	cmsetnoecho();

	readtimeval.tv_sec = 2;
	readtimeval.tv_usec = 0;
	readtimeout = &readtimeval;

	/*
	 *	Send out initialization sequence.
	 */
	
	return(0);
  }

int	cm_close()
  {
	cmsetecho();
	close(motfd);
  }

main(argc,argv)
int	argc;
char	*argv[];
  {
	if(argc < 2)
	  {
	    fprintf(stderr,"Usage: tty_term <tty-device-name>\n");
	    exit(0);
	  }
	keybdfd = 0;
	cm_init(argv[1]);

	cm_loop();

	exit(0);
  }
