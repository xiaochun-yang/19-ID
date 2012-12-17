#include	"ccd_bl_ext.h"
#include	<math.h>

#ifdef WINNT

#include	"serial.h"
#include	"DevErrCode.h"

#else /* end WINNT, begin unix part */

#include	<termio.h>
#include        <sys/socket.h>
#include        <errno.h>
#include        <math.h>
#include        <sys/types.h>
#include        <fcntl.h>

#endif /* unix part */

static	int		motfd;
int				in_manual = 0;
static	char	vmin0;
static	int		cmdebug = 1;
static	int		cmdelay1 = 0;
static	int		testdelay1 = 0;
static	int		testdelay2 = 0;

static short    cmchanno;              /* the channel number */
static int      cmsenseret[3];         /* status info for set/reset */
static char     cmretstring[80];
static char     cmretcopy[80];         /* a copy of the last returned string */
static char     cmsentcopy[80];        /* a copy of the last command sent */
static char     ex_sent_str[80];
static char     ex_ret_str[80];
static int      cmretlen;

#ifdef WINNT

void	cm_settimeout(int	msec)
{
	int		i2;
	int		nSetTimeout(double dSeconds);

	if(0 != (i2 = nSetTimeout(((double) msec) / 1000.)))
	{
		fprintf(stderr,"cm_settimeout: Error returned from nSetTimeout: %d\n", i2);
	}
}

/*
 *      Return a character from the input channel.  Return -1 if
 *      this operation timed out.
 */

int     cmreadraw()
{
	int		i2;
	char	rbuf;
	char	eol;
	long	nreq;
	int		nReadRequest(char *pcBuffer, long *plReadBytes, char *pcEndOfLine);
	
	eol = '\0';
	nreq = 1;

	i2 = nReadRequest(&rbuf, &nreq, &eol);

	if(i2 == DEV_FAILED)
	{
		fprintf(stderr,"cmreadraw: nReadRequest returned error: %d\n", i2);
		return(-1);
	}
	if(i2 == DEV_TIMEOUT)
	{
		fprintf(stderr,"cmreadraw: TIMEOUT\n");
		return(-1);
	}
	return(rbuf);	/* DEV_SUCCESS */
}

int     cmwriteraw(char c)
{
	int		i2;
	char	wbuf;
	long	nreq;
	int		nWriteRequest(char *pcBuffer, long *plReadBytes);
	
	nreq = 1;
	wbuf = c;

	i2 = nWriteRequest(&wbuf, &nreq);

	if(i2 == DEV_FAILED)
	{
		fprintf(stderr,"cmwrteraw: nWriteRequest returned error: %d\n", i2);
		return(-1);
	}
	if(i2 == DEV_TIMEOUT)
	{
		fprintf(stderr,"cmwriteraw: TIMEOUT\n");
		return(-1);
	}
	return(0);	/* DEV_SUCCESS */
}
#else /* end WINNT, begin unix part */

static struct timeval	*readtimeout = NULL;
static struct timeval	readtimeval;

static int	timeout_nmsec;
static int	timeout_nsec;
static int	timeout_res_nmsec;

static	int	use_socket = 1;
static	char	*ip_hostname = "10.0.0.5";
static	int	ip_port = 3456;

cm_settimeout(int nmsec)
{
	char	*cp;

	timeout_nmsec = nmsec;
	timeout_nsec = nmsec / 1000;
	timeout_res_nmsec = timeout_nmsec - 1000 * timeout_nsec;
	if(0)
	fprintf(stdout,"cm_settimeout: timeout_(nmsec,nsec,res_nmsec) (%d,%d,%d)\n", 
			timeout_nmsec,timeout_nsec,timeout_res_nmsec);

}

cmsetnoecho()
  {
        struct termio arg;

	if(use_socket)
		return;

        if(-1 == ioctl(motfd,TCGETA,&arg))
          {
            fprintf(stderr,"Setnoecho: Error on IOCTL call to get term params\n");
            cleanexit(0);
          }
	arg.c_oflag &= ~ONLCR;
	arg.c_oflag &= ~OCRNL;
	arg.c_oflag &= ~ONOCR;
	arg.c_oflag &= ~ONLRET;
        arg.c_lflag &= ~ECHO;
        arg.c_lflag &= ~ICANON;
#ifndef alpha
	 arg.c_cflag &= ~CLOCAL;
#endif /* not an alpha */
        vmin0 = arg.c_cc[VMIN];
        arg.c_cc[VMIN] = 1;
        if(-1 == ioctl(motfd,TCSETA,&arg))
          {
            fprintf(stderr,"Setnoecho: Error on IOCTL call to set term params\n");
	    perror("IOCTL to set term params");
            cleanexit(0);
          }
  }

cmprintttymode()
  {
        struct termio arg;

	if(use_socket)
		return;

        if(-1 == ioctl(motfd,TCGETA,&arg))
          {
            fprintf(stderr,"Setnoecho: Error on IOCTL call to get term params\n");
	    perror("IOCTL to get term params");
            cleanexit(0);
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

	if(use_socket)
		return;

        if(-1 == ioctl(motfd,TCGETA,&arg))
          {
            fprintf(stderr,"Setecho: Error on IOCTL call to get term params\n");
	    perror("IOCTL to get term params");
            cleanexit(0);
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
            cleanexit(0);
          }
  }

/*
 *      Return a character from the input channel.  Return -1 if
 *      this operation timed out.
 */

int     cmreadraw()
  {
	fd_set  readmask, writemask, exceptmask;
        char    rbuf;
	int	nb;

  redo_read:

	readtimeval.tv_sec = timeout_nsec;
	readtimeval.tv_usec = 1000 * timeout_res_nmsec;
	readtimeout = &readtimeval;
	if(0)
	    fprintf(stdout,"readtimeval.tv_sec: %d readtimeval.tv_usec: %d\n",
			readtimeval.tv_sec, readtimeval.tv_usec);

        FD_ZERO(&readmask);
        FD_SET(motfd,&readmask);
        nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, readtimeout);
        if(nb == -1)
          {
                if(errno == EINTR)
		  goto redo_read;

                fprintf(stderr,"cmreadraw: select error (in readraw).  Should never happen.\n");
                perror("ccd_dc: select in ccd_check_alive");
		cmsetecho();
                cleanexit(0);
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
            if(errno == EINTR)
		  goto redo_read;
	    perror("reading tty input");
            fprintf(stderr,"readraw: error reading tty input\n");
            cleanexit(0);
          }
        return(rbuf);
  }

/*
 *      Return a character from the input channel.
 *
 *	This is specifically used to drain off input from the goniostat
 *	controller before every command.
 */

int     cmreadraw_drain(int timeout_msec)
{
	fd_set  readmask, writemask, exceptmask;
        char    rbuf;
	int	nb;
	struct timeval	*drain_readtimeout = NULL;
	struct timeval	drain_readtimeval;

  redo_read:

	drain_readtimeval.tv_sec = 0;
	drain_readtimeval.tv_usec = 1000 * timeout_msec;
	drain_readtimeout = &drain_readtimeval;

	if(0)
	    fprintf(stdout,"drain_readtimeval.tv_sec: %d drain_readtimeval.tv_usec: %d\n",
			drain_readtimeval.tv_sec, drain_readtimeval.tv_usec);

        FD_ZERO(&readmask);
        FD_SET(motfd,&readmask);
        nb = select(FD_SETSIZE, &readmask, (fd_set *) 0, (fd_set *) 0, drain_readtimeout);
        if(nb == -1)
        {
                if(errno == EINTR)
			goto redo_read;

                fprintf(stderr,"cmreadraw: select error (in readraw).  Should never happen.\n");
                perror("ccd_bl_x4a: select in cmreadraw_drain");
		return(-1);
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
        	if(errno == EINTR)
			goto redo_read;
		perror("cmreadraw_drain: reading tty input");
        	fprintf(stderr,"cmreadraw_drain: error reading tty input\n");
		return(-1);
        }
        return(rbuf);
}

int     cmwriteraw(c)
char    c;
{
        char    wbuf;
	int 	i;
        wbuf = c;

        if(-1 == write(motfd, &wbuf, 1))
        {
		fprintf(stderr,"writeraw: error writing to goniostat tty connection.\n");
		perror("writeraw");
        }
        return(0);
}
#endif /* unix part */

int	cm_input_resync_old(line)
char	*line;
{
	int	i,j;
	char	c;

	readtimeval.tv_sec = 2000;
	readtimeval.tv_usec = 0;
	readtimeout = &readtimeval;

	line[0] = '\0';
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
		line[j] = '\0';
		if(cmdebug)
		  fprintf(stderr,"%c",c);
	      }
	    } while(NULL == (char *) strstr(line,"RESYNC"));
	if(cmdebug)
	  fprintf(stderr,"\n");
	return(0);
}

int 	cm_input(char *line)
{
	int 	i,j;
	char	c;

	line[0] = '\0';
	j = 0;

	do 
	{
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
			line[j] = '\0';
			if(cmdebug)
				fprintf(stderr,"%c",c);
		}
	} while(NULL == (char *) strstr(line,"CMD_DONE"));
	
	if(cmdebug)
		fprintf(stderr,"\n");
	return(0);
}

int 	cm_input_buflim(char *line, int buflim)
{
	int 	i,j;
	char	c;

	line[0] = '\0';
	j = 0;

	do 
	{
		i = cmreadraw();
		if(i == -1)
		{
			fprintf(stderr,"cm_input_buflim: timeout detected.\n");
			if(NULL != strstr(line, "REMOTE"))
			{
				fprintf(stderr,"cm_input_buflim:  Goniostat is in MANUAL mode\n");
				in_manual = 1;
			}
			line[j] = '\0';
			return(1);
		}
		c = (char) i;
		if(c != '\r')
		{
			if(j < (buflim - 2))
			{
				line[j++] = c;
				line[j] = '\0';
				if(cmdebug)
					fprintf(stderr,"%c",c);
			}
			else
			{
				fprintf(stderr, "cm_input_buflim: BUFFER OVERRUN would occur.\n");
				line[j] = '\0';
				return(1);
			}
		}
	} while(NULL == (char *) strstr(line,"CMD_DONE"));
	
	if(cmdebug)
		fprintf(stderr,"\n");
	return(0);
}

int 	cm_input_wait(char *line, int buflim)
{
	int 	i,j;
	char	c;

	line[0] = '\0';
	j = 0;

	do 
	{
		i = cmreadraw();
		if(i == -1)
		{
			line[j] = '\0';
			return(1);
		}
		c = (char) i;
		if(c != '\r')
		{
			if(j < (buflim - 2))
			{
				line[j++] = c;
				line[j] = '\0';
				if(cmdebug)
					fprintf(stderr,"%c",c);
			}
			else
			{
				fprintf(stderr, "cm_input_buflim: BUFFER OVERRUN would occur.\n");
				line[j] = '\0';
				return(1);
			}
		}
	} while(NULL == (char *) strstr(line,"CMD_DONE"));
	
	if(cmdebug)
		fprintf(stderr,"\n");
	return(0);
}

int 	cm_input_until(char *line, int buflim, char *until_string)
{
	int 	i,j;
	char	c;

	line[0] = '\0';
	j = 0;

	do 
	{
		i = cmreadraw();
		if(i == -1)
		{
			fprintf(stderr,"cm_input_until: timeout detected.\n");
			line[j] = '\0';
			return(1);
		}
		c = (char) i;
		if(c != '\r')
		{
			if(j < (buflim - 2))
			{
				line[j++] = c;
				line[j] = '\0';
				if(cmdebug)
					fprintf(stderr,"%c",c);
			}
			else
			{
				fprintf(stderr, "cm_input_until: BUFFER OVERRUN would occur.\n");
				line[j] = '\0';
				return(1);
			}
		}
	} while(NULL == (char *) strstr(line,until_string));
	
	if(cmdebug)
		fprintf(stderr,"\n");
	return(0);
}

char	resync_buf[40960];

cm_input_resync(char *line)
{
	readtimeval.tv_sec = 2000;
	readtimeval.tv_usec = 0;
	readtimeout = &readtimeval;

	cm_input_until(resync_buf, sizeof resync_buf, "RESYNC"); 
}

int 	cm_output(char *line)
{
	int 	i;

	for(i = 0; !(line[i] == '\n' || line[i] == '\0'); i++)
	{
		(void) cmwriteraw(line[i]);
		if(cmdebug)
			fprintf(stderr,"%c",line[i]);
	}
	(void) cmwriteraw('\r');
	if(cmdebug)
		fprintf(stderr,"\n");
	return(0);
}

int 	cm_output_mult_lines(char *line)
{
	int 	i;

	for(i = 0; line[i] != '\0'; i++)
	{
		if(cmdebug)
			fprintf(stderr,"%c",line[i]);
		if(line[i] != '\n')
			(void) cmwriteraw(line[i]);
		else
			(void) cmwriteraw('\r');
	}
	return(0);
}

struct cm_mdef {
			char	*cn_name;	/* the name of the motor */
			int		cn_unit;	/* the CN0170 unit number */
			char	cn_motor;	/* the CN0170 axis (X or Y) */
			int		cn_base;	/* base speed, normal operation, this axis */
			int		cn_top;		/* top speed, normal operation, this axis */
			int		cn_accel;	/* accelleration, normal operation, this axis */
			int		cn_stdeg;	/* number of steps per degree, this axis */
			int		cn_mode;	/* 0 if axis not init, 1 if normal, 2 if data collection */
			int		cn_noman;	/* 1 if no manual mode */
			int		cn_punit;	/* position unit */
			int		cn_pchan;	/* position channel */
		   };

struct cm_mdef kappa_motors[] = {
	"omega",    1,  'Y',    0,    10,    10,  25000, 0, 0,    1,1,
	"phi",    1,  'Y',    0,    10,    10,  25000, 0, 0,    1,1,
	"kappa",  0,  'Y',  250,  1000,  1000,     50, 0, 1,    1,2,
	"2theta", 0,  'Y',  250,  1000,  1000,    200, 0, 1,    0,2,
	"dist",   2,  'X',    0,    10,    10,  12500, 0, 0,    0,0,
	NULL,     0, '\0',    0,     0,     0,      0, 0, 0,    0,0,
				    };

int		mind_motion;				/* motor in motion */

static	char	tty_opened_name[256];

int 	cm_init(char *ttyname)
{
	int		i1,i2;
	char	line[1024];
	int		port_number;
	char	*cp;

	strcpy(tty_opened_name, ttyname);

#ifdef WINNT
	i1 = strlen(ttyname);
	if(i1 == 0)
	{
		fprintf(stderr, "cm_init: NULL ttyname string; ERROR\n");
		return(1);
	}
	port_number = atoi(&ttyname[i1 - 1]);

	fprintf(stdout, "cm_init: info: COM%d will be tty port name\n", port_number);

	if(0 != (i2 = nSetPortID(port_number, eSerialType_Terminal)))
	{
		fprintf(stdout,"cm_init: Error from nSetPortID: %d\n", i2);
		return(1);
	}

	if(0 != (i2 = nOpen()))
	{
		fprintf(stdout,"cm_init: Error from nOpen: %d\n", i2);
		return(1);
	}
#else /* end WINNT, begin unix part */

	if(use_socket)
	{
		if(-1 == connect_to_host(&motfd, ip_hostname, ip_port, NULL))
		{
			fprintf(stderr,"cm_init: Cannot connect to host %s port %d for compumotor communications\n",
				ip_hostname, ip_port);
			return(1);
		}
		fprintf(stderr,"cm_init: opened motor file descriptor %d\n", motfd);
	}
	else
	{
		if(-1 == (motfd = open(ttyname, O_RDWR)))
		{
			fprintf(stderr,"cm_init: Cannot open %s as kappa goniostat tty.\n", ttyname);
			return(1);
		}
		cmsetnoecho();
	}

#endif /* unix part */

	cm_settimeout(2000);

	fprintf(stdout,"cm_init: Flushing any characters in compumotor interface.\n");
	cm_input(line);

	cm_settimeout(2000);

	if(0)
		cm_output("`CCDataCollectStart");

	/*
	 *	Send out initialization sequence.
	 */
	cm_output("`CCremote");
	cm_output("!K");
	cm_output("`msquiet");
	cm_output("`ghquiet");
	cm_output("`mbquiet");
	cm_output("PORT1");
	cm_output("ERRLVL0");
	cm_output("EOT13,10,0");
	cm_output("OUTXX0");
	cm_output("NTADDR");
	cm_output("TRACE0");
	cm_output("MINIT");
	cm_output("ECHO1");
	cm_output("SHOFF");
	cm_output("DRES 10000,19685,19685");
	cm_output("CDONE");

	cm_input(line);

	Sleep(1000);

	cm_output("RS");
	cm_input_resync(line);

	Sleep(1000);

	return(0);
}

int 	cm_sync()
{
	char	line[1024];

	cm_settimeout(2000);

	fprintf(stdout,"cm_sync: Flushing any characters in tty interface.\n");

	cm_input(line);

	fprintf(stdout,"cm_sync: Done.\n");

	return(0);
}

#ifdef WINNT
int	cm_close()
{
	int		i2;

	if(0 != (i2 = nClose()))
	{
		fprintf(stderr,"cm_close: Error from nClose: %d\n", i2);
		return(1);
	}
	return(0);
}
#else /* end WINNT, begin unix part */

int 	cm_close()
{
	cmsetecho();
	close(motfd);
}

#endif /* unix part */

void	cm_shutter(int val)
{
  	char	line[256];

	if(in_manual)
		cm_manual(0);
	if(val == 0)
		cm_output("SHOFF");
	 else
		cm_output("SHON");
	cm_output("CDONE");
	cm_input(line);
}

void	cm_getmotval()
{
	FILE	*fpmot;
	char	*positionfile;
	char	line[132];

	if(NULL == (positionfile = (char *) getenv("CCD_KAPPA_POSITIONS")))
	{
		fprintf(stderr,"cm_getmotval: no environment for CCD_KAPPA_POSITIONS\n");
		return;
	}
	if(NULL == (fpmot = fopen(positionfile,"rt")))
	{
		fprintf(stderr,"cm_getmotval: cannot open %s as motor position file\n",positionfile);
		return;
	}

	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_omega);
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_phi);
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_kappa);
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_2theta);
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_dist);
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_z);
	fclose(fpmot);
}

void	cm_getmotval_gonio(int silent)
{
	FILE	*fpmot;
	char	*positionfile;
	char	line[1024];
	char	*cp;
	float	f;
	int	cmdebug_save;
	double	htotheta(double val);

	if(silent)
	{
		cmdebug_save = cmdebug;
		cmdebug = 0;
	}

	if(NULL == (positionfile = (char *) getenv("CCD_KAPPA_POSITIONS")))
	  {
	    fprintf(stderr,"cm_getmotval: no environment for CCD_KAPPA_POSITIONS\n");
	    return;
	  }
	if(NULL == (fpmot = fopen(positionfile,"r")))
	  {
	    fprintf(stderr,"cm_getmotval: cannot open %s as motor position file\n",positionfile);
	    return;
	  }
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_omega);
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_phi);
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_kappa);
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_2theta);
	fgets(line,sizeof line,fpmot);
	sscanf(line,"%f",&stat_dist);
	fclose(fpmot);

	cm_output("GOME");
	Sleep(200);
	cm_output("CDONE");
	cm_input_buflim(line, sizeof line);
	if(NULL != (cp = (char *)strstr(line,"OMEGA_VALUE")))
	{
		cp += strlen("OMEGA_VALUE") + 1;
		sscanf(cp,"%f",&f);
		if(silent == 0)
			fprintf(stderr,"%s: omega angle value read from goniostat is: %f\n",pgmname,f);
		stat_omega = f;
	}
	else
	{
		if(silent == 0)
			fprintf(stderr,"%s: did not find string OMEGA_VALUE on a GOME call\n",pgmname);
	}

	cm_output("GDIST");
	Sleep(200);
	cm_output("CDONE");
	cm_input_buflim(line, sizeof line);
	if(NULL != (cp = (char *)strstr(line,"DISTANCE_VALUE")))
	{
		cp += strlen("DISTANCE_VALUE") + 1;
		sscanf(cp,"%f",&f);
		if(silent == 0)
			fprintf(stderr,"%s: distance value read from goniostat  is: %f\n",pgmname,f);
		if(f < (near_limit_value - 2.) || f > (far_limit_value + 2.))
		{
			fprintf(stderr,"%s: Unusual distance value; distance not set.\n",pgmname);
			set_alert_msg("Unusual distance read back; please HOME the goniostat.");
		}
		else
			stat_dist = f;
	}
	else
	{
		if(silent == 0)
			fprintf(stderr,"%s: did not find string DISTANCE_VALUE on a GDIST call\n",pgmname);
	}

	cm_output("G2THET");
	Sleep(200);
	cm_output("CDONE");
	cm_input_buflim(line, sizeof line);

	if(NULL != (cp = (char *)strstr(line,"TWOTHETA_VALUE")))
	{
		cp += strlen("TWOTHETA_VALUE") + 1;
		sscanf(cp,"%f",&f);
		if(silent == 0)
			fprintf(stderr,"%s: two-theta (mm) value read from goniostat is: %f\n",pgmname,f);
		// f = htotheta(f);
		if(silent == 0)
			fprintf(stderr,"%s: two-theta (degrees) value read from goniostat is: %f\n",pgmname,f);

		stat_2theta = f;
	}
	else
	{
		if(silent == 0)
			fprintf(stderr,"%s: did not find string TWOTHETA_VALUE on a G2THET call\n",pgmname);
	}

	if(silent)
		cmdebug = cmdebug_save;

}

void	cm_get_goniostat_values()
{
	char	line[132];
	char	*cp;
	float	f;

	cm_output("GOME");
	Sleep(1000);
	cm_output("CDONE");
	cm_input(line);
	if(NULL != (cp = (char *)strstr(line,"OMEGA_VALUE")))
	{
		cp += strlen("OMEGA_VALUE") + 1;
		sscanf(cp,"%f",&f);
		fprintf(stderr,"%s: omega angle value on startup is: %f\n",pgmname,f);
		stat_omega = f;
	}
	else
		fprintf(stderr,"%s: did not find string OMEGA_VALUE on a GOME call\n",pgmname);

	cm_output("GDIST");
	Sleep(1000);
	cm_output("CDONE");
	cm_input(line);
	if(NULL != (cp = (char *)strstr(line,"DISTANCE_VALUE")))
	{
		cp += strlen("DISTANCE_VALUE") + 1;
		sscanf(cp,"%f",&f);
		fprintf(stderr,"%s: distance value on startup is: %f\n",pgmname,f);
		if(f < (near_limit_value - 2.) || f > (far_limit_value + 2.))
		{
			fprintf(stderr,"%s: Unusual distance value; distance not set.\n",pgmname);
			set_alert_msg("Unusual distance read back; please HOME the goniostat.");
		}
		else
			stat_dist = f;
	}
	else
		fprintf(stderr,"%s: did not find string DISTANCE_VALUE on a GDIST call\n",pgmname);

	cm_output("GZ");
	Sleep(1000);
	cm_output("CDONE");
	cm_input(line);

	if(NULL != (cp = (char *)strstr(line,"Z_VALUE")))
	{
		cp += strlen("Z_VALUE") + 1;
		sscanf(cp,"%f",&f);
		fprintf(stderr,"%s: z-trans value on startup is: %f\n",pgmname,f);

		stat_z = f;
	}
	else
	{
		fprintf(stderr,"%s: did not find string Z_VALUE on a GZ call\n",pgmname);
		stat_z = 0;
	}

}

void	cm_get_specific_goniostat_value(char *which)
{
	char	line[132];
	char	*cp;
	float	f;

	if(0 == strcmp("omega", which))
	{
	cm_output("GOME");
	Sleep(1000);
	cm_output("CDONE");
	cm_input(line);
	if(NULL != (cp = (char *)strstr(line,"OMEGA_VALUE")))
	{
		cp += strlen("OMEGA_VALUE") + 1;
		sscanf(cp,"%f",&f);
		fprintf(stderr,"%s: omega angle value on startup is: %f\n",pgmname,f);
		stat_omega = f;
	}
	else
		fprintf(stderr,"%s: did not find string OMEGA_VALUE on a GOME call\n",pgmname);
	return;
	}

	if(0 == strcmp("dist", which))
	{
	cm_output("GDIST");
	Sleep(1000);
	cm_output("CDONE");
	cm_input(line);
	if(NULL != (cp = (char *)strstr(line,"DISTANCE_VALUE")))
	{
		cp += strlen("DISTANCE_VALUE") + 1;
		sscanf(cp,"%f",&f);
		fprintf(stderr,"%s: distance value on startup is: %f\n",pgmname,f);
		if(f < (near_limit_value - 2.) || f > (far_limit_value + 2.))
		{
			fprintf(stderr,"%s: Unusual distance value; distance not set.\n",pgmname);
			set_alert_msg("Unusual distance read back; please HOME the goniostat.");
		}
		else
			stat_dist = f;
	}
	else
		fprintf(stderr,"%s: did not find string DISTANCE_VALUE on a GDIST call\n",pgmname);
	return;
	}
	if(0 == strcmp("kappa", which))
	{
		cm_output("`GHKappa");
		cm_output("CDONE");
		cm_input(line);
		fprintf(stderr,"on `GHKappa, returned buffer: %s\n", line);
		return;
	}

	if(0 == strcmp("z", which))
	{
	cm_output("GZ");
	Sleep(1000);
	cm_output("CDONE");
	cm_input(line);

	if(NULL != (cp = (char *)strstr(line,"Z_VALUE")))
	{
		cp += strlen("Z_VALUE") + 1;
		sscanf(cp,"%f",&f);
		fprintf(stderr,"%s: z-trans value on startup is: %f\n",pgmname,f);

		stat_z = f;
	}
	else
	{
		fprintf(stderr,"%s: did not find string Z_VALUE on a GZ call\n",pgmname);
		stat_z = 0;
	}
	}

}


void	cm_putmotval()
{
	FILE	*fpmot;
	char	*positionfile;

	if(NULL == (positionfile = (char *) getenv("CCD_KAPPA_POSITIONS")))
	{
		fprintf(stderr,"cm_putmotval: no environment for CCD_KAPPA_POSITIONS\n");
		return;
	}
	if(NULL == (fpmot = fopen(positionfile,"wt")))
	{
		fprintf(stderr,"cm_putmotval: cannot create %s as motor position file\n",positionfile);
		return;
	}
	fprintf(fpmot,"%10.3f\n%10.3f\n%10.3f\n%10.3f\n%10.3f\n%10.3f\n",
		stat_omega,stat_phi,stat_kappa,stat_2theta,stat_dist,stat_z);
	fclose(fpmot);
}

int		cm_dccheck()
{
	char	line[1024];

	fprintf(stderr,"cm_dccheck: entered at %d\n", timeGetTime());
	while(1 == cm_input_buflim(line, sizeof line));
	fprintf(stderr,"cm_dccheck: returning at %d\n", timeGetTime());
	return(1);
}

#define	RADC	(180. / 3.1415926535)

double	thetatoh(theta)
double	theta;
{
  	static	double	d1 = 341.044;
	static	double	d2 = 763.52;

	double	c,s,t,angle,h;

	angle = theta / RADC;
	c = cos(angle);
	s = sin(angle);
	t = tan(angle);

	h = d1 * (1. - c - s * t) + d2 * t;
	return(h);
}

double	htotheta(h)
double	h;
{
  	static	double	d1 = 341.044;
	static	double	d2 = 763.52;

	double	a,b,c,beta1,beta2,sum,angle;

	a = (h - d1) * (h - d1) + d2 * d2;
	b = 2 * d1 * (h - d1);
	c = d1 * d1 - d2 * d2;
	sum = a + b + c;
	beta1 = (-b + sqrt(b * b - 4 * a * c)) / (2 * a);
	beta2 = (-b - sqrt(b * b - 4 * a * c)) / (2 * a);
	angle = RADC * acos(beta1);
	if(h < 0)
		angle = -angle;
	return(angle);
}

int		cm_moveto(char *motstr, double new_value,double current_value)
{
	int		mind, ret;
	double	x1,x2,x3;
	double	hcurrent,hnew,hdiff;
	char	line[132];

	for(mind = 0; NULL != kappa_motors[mind].cn_name; mind++) 
	  if(0 == strcmp(kappa_motors[mind].cn_name,motstr))
		break;
	if(kappa_motors[mind].cn_name == NULL)
		return(1);
	
	mind_motion = mind;
	ret = 0;

	fprintf(stderr,"cm_moveto: motor: %s new: %f current: %f\n",motstr,new_value,current_value);
	if(new_value == current_value)
		return(ret);

	if(in_manual)
		cm_manual(0);
        /*
         *      Check to see if the requested motor position is reasonable.
         *
         *      x1 will be a value from 0 <= x1 < 360.
         */

	if(mind == 4 || mind == 3)	/* distance  & lift */
	  {
        	x1 = new_value;
        	x2 = current_value;
		goto skip_anglenorm;
	  }
        x1 = new_value;
        while(x1 >= 360.)
                x1 -= 360.;
        while(x1 < 0)
                x1 += 360;
        x2 = current_value;
        while(x2 >= 360.)
                x2 -= 360.;
        while(x2 < 0)
                x2 += 360;

        switch(mind)
          {
            case 2:     /* kappa */
                if(x1 > 90 && x1 < 270)
                  {
                    fprintf(stderr,"acs_moveto: %f (renormalized from %f) is an ILLEGAL kappa value\n",x1,new_value);
                    fprintf(stderr,"            Motions are restricted to be 270 to 360, 0 to 90 (-90 < kappa < 90)\n");
                    return(1);
                  }
                break;
            case 3:     /* two theta */
                if(x1 > 45 && x1 < 358)
                  {
                    fprintf(stderr,"acs_moveto: %f (renormalized from %f) is an ILLEGAL 2theta value\n",x1,new_value);
                    fprintf(stderr,"            Motions are restricted to be 358 to 360, 0 to 45 (-2 < 2theta < 45)\n");
                    return(1);
                  }
                break;
            default:
                break;
          }

	if(x2 > 180)
	  x2 -= 360.;
	if(x1 > 180)
	  x1 -= 360.;

skip_anglenorm:

	x3 = x1 - x2;
	if(0 == mind)
	{
		if(x3 > 180)
			x3 = x3 - 360;
		else
		if(x3 < -180)
			x3 = x3 + 360;
	}

	cm_output("NOOP");	/* can't afford a botch on value output (below)! */

	if(mind == 4)	/* distance */
	  {
		cm_settimeout(1000 * (5 + (int) fabs(x3)));
		sprintf(line,"VAR13=%.3f",x3);
		cm_output(line);
		sprintf(line,"MDIST");
		cm_output(line);
	  }
	 else if(mind == 0)
	  {
		cm_settimeout(1000 * 200);
		sprintf(line,"VAR12=%.3f",x3);
		cm_output(line);
		sprintf(line,"MOME");
		cm_output(line);
	  }
	 else if(mind == 2)	/* kappa */
	  {
		cm_settimeout(1000 * 200);
		sprintf(line,"`GHIncrement Kappa %.3f",x3);
		cm_output(line);
	  }
	 else if(mind == 1)	/* phi */
	  {
		cm_settimeout(1000 * 200);
		sprintf(line,"`GHIncrement Phi %.3f",x3);
		cm_output(line);
	  }
	 else
	  {
		hcurrent = stat_2theta;
		hnew = stat_2theta + x3;
		hdiff = hnew - hcurrent;
		fprintf(stdout,"cm_moveto: stat_2theta: %f hcurrent: %f stat_2theta + x3 :%f hnew: %f hdiff: %f\n",
				stat_2theta,hcurrent,stat_2theta+x3,hnew,hdiff);
		cm_settimeout(1000 * (5 + (int) fabs(hdiff)));
		sprintf(line,"VAR9=%.3f",hdiff);
		cm_output(line);
		sprintf(line,"M2TH");
		cm_output(line);
	  }
	cm_output("CDONE");
	cm_input(line);
	if(NULL != (char *) strstr(line,"NEAR_DIST_LIMIT_HIT"))
	  {
	    set_alert_msg("Distance NEAR limit hit.");
	    stat_dist = near_limit_value;
	    fprintf(stderr,"cm_moveto: Set stat_dist to %10.2f for NEAR DISTANCE LIMIT SWITCH HIT\n",stat_dist);
	    ret=1;
	  } else if(NULL != (char *) strstr(line,"FAR_DIST_LIMIT_HIT"))
	  {
		set_alert_msg("Distance FAR limit hit.");
		stat_dist = far_limit_value;
		fprintf(stderr,"cm_moveto: Set stat_dist to %10.2f for FAR DISTANCE LIMIT SWITCH HIT\n",stat_dist);
		ret=1;
	  } else if(NULL != (char *) strstr(line,"FAR_2THETA_LIMIT_HIT"))
	  {
		set_alert_msg("POSITIVE 2THETA limit hit.");
		stat_2theta = far_2theta_limit_value;
		fprintf(stderr,"cm_moveto: Set stat_2theta to %10.2f for FAR LIMIT SWITCH HIT\n",stat_2theta);
		ret=1;
	  } else if(NULL != (char *) strstr(line,"NEAR_2THETA_LIMIT_HIT"))
	  {
		set_alert_msg("NEGATIVE 2THETA limit hit.");
		stat_2theta = near_2theta_limit_value;
		fprintf(stderr,"cm_moveto: Set stat_2theta to %10.2f for NEAR LIMIT SWITCH HIT\n",stat_2theta);
		ret=1;
	  }
	send_status();
	return(ret);
}

void	cm_setomega(val)
double	val;
{
  	char	line[256];

	sprintf(line,"VAR12=%.3f",val);
	cm_output(line);
	sprintf(line,"SOME");
	cm_output(line);
	cm_output("CDONE");
	cm_input(line);
}
void	cm_setdistance(val)
double	val;
{
  	char	line[256];

	sprintf(line,"VAR13=%.3f",val);
	cm_output(line);
	sprintf(line,"SDIST");
	cm_output(line);
	cm_output("CDONE");
	cm_input(line);
}
void	cm_set2theta(val)
double	val;
{
  	char	line[256];

	sprintf(line,"VAR9=%.3f",val);
	cm_output(line);
	sprintf(line,"S2THET");
	cm_output(line);
	cm_output("CDONE");
	cm_input(line);
}



void	cm_manual(int mode)
{
	char	line[256];
	char	*cp;
	float	f;

	if(mode == 1)
	{
		in_manual = 1;
		cm_output("`CCManual");
	}
	else
	{
		in_manual = 0;
		cm_output("`CCRemote");
		cm_output("RS");
		cm_input_resync(line);
		cm_output("GOME");
		Sleep(1000);
		cm_output("CDONE");
		cm_input(line);
		if(NULL != (cp = (char *)strstr(line,"OMEGA_VALUE")))
		{
		        cp += strlen("OMEGA_VALUE") + 1;
		        sscanf(cp,"%f",&f);
		        fprintf(stderr,"%s: omega angle value after manual is: %f\n",pgmname,f);
		        stat_omega = f;
		}
		else
		        fprintf(stderr,"%s: did not find string OMEGA_VALUE on a GOME call\n",pgmname);

		cm_output("GDIST");
		Sleep(1000);
		cm_output("CDONE");
		cm_input(line);
		if(NULL != (cp = (char *)strstr(line,"DISTANCE_VALUE")))
		{
		        cp += strlen("DISTANCE_VALUE") + 1;
		        sscanf(cp,"%f",&f);
		        fprintf(stderr,"%s: distance value after manual is: %f\n",pgmname,f);
		        if(f < near_limit_value || f > far_limit_value)
		        {
		            fprintf(stderr,"%s: Unusual distance value; distance not set.\n",pgmname);
			    set_alert_msg("Please CHECK and RESET distance value if necessary.\n");
		        }
		        else
		            stat_dist = f;
		}
		else
		        fprintf(stderr,"%s: did not find string DISTANCE_VALUE on a GDIST call\n",pgmname);
	}
}

void	cm_home()
{
	char	line[256];

	if(in_manual)
		    cm_manual(0);
	cm_settimeout(1000 * (5 + 500 / 4));
	cm_output("NOOP");
	cm_output("THHOME");
	cm_output("CDONE");
	cm_input(line);
	cm_settimeout(1000 * 200);
	cm_output("OMHOME");
	cm_output("CDONE");
	cm_input(line);
	stat_2theta = 0;
	stat_phi = 0;
	send_status();
}

void	cm_dhome()
{
	char	line[256];
	if(in_manual)
		    cm_manual(0);
	cm_settimeout(1000 * (200));
	cm_output("DHOME");
	cm_output("CDONE");
	cm_input(line);
	stat_dist = far_home_value;
}

void	cm_ohome()
{
	char	line[256];
	if(in_manual)
		    cm_manual(0);
	cm_settimeout(1000 * (200));
	cm_output("OMHOME");
	cm_output("CDONE");
	cm_input(line);
	stat_omega = 0;
}

void	cm_thhome()
{
	char	line[256];
	if(in_manual)
		    cm_manual(0);
	cm_settimeout(1000 * (200));
	cm_output("THHOME");
	cm_output("CDONE");
	cm_input(line);
	stat_2theta = 0;
}

void	cm_zhome()
{
	char	line[256];
	if(in_manual)
		    cm_manual(0);
	cm_settimeout(1000 * (200));
	cm_output("ZTHOME");
	cm_output("CDONE");
	cm_input(line);
	cm_output("PSET,,,0");
	cm_output("CDONE");
	cm_input(line);
	stat_z = 0;
}

double	cm_mz(double new_val, double old_val)
{
	char	buf[256];

	if(new_val > 70)
		return(old_val);
	if(new_val < 0)
		return(old_val);
	cm_settimeout(1000 * 240);
	sprintf(buf,"VAR14=%.3f", new_val - old_val);
	cm_output(buf);
	cm_output("MZTR");
	cm_output("CDONE");
	cm_input(buf);
	return(new_val);
}

int	cm_dc(char *motstr, double width, double dctime)
{
	int		mind;
	char	line[132];

	for(mind = 0; NULL != kappa_motors[mind].cn_name; mind++) 
	  if(0 == strcmp(kappa_motors[mind].cn_name,motstr))
		    break;
	if(kappa_motors[mind].cn_name == NULL)
		    return(1);
	    
	if(in_manual)
		    cm_manual(0);

	cm_settimeout(1000 * (200 + 2 + (int) dctime));

	sprintf(line,"VAR10=%.3f",width);
	cm_output(line);
	sprintf(line,"VAR11=%.3f",dctime);
	cm_output(line);
	strcpy(line,"SOSC");
	cm_output(line);
	cm_output("CDONE");

	return(0);
}

cm_set_halfslit(int which, int h_or_v, int val)
{
	int	num;
	char	buf[2048];

	fprintf(stderr,"cm_set_halfslit: which: %d h_or_v: %d val: %d\n",which, h_or_v, val);

	if(which == 0)
	{
		if(h_or_v == 1)
		{
			sprintf(buf, "1OUT.9-%d", val);
		}
		else
		{
			sprintf(buf, "1OUT.10-%d", val);
		}
	}
	else
	{
		if(h_or_v == 1)
		{
			sprintf(buf, "1OUT.11-%d", val);
		}
		else
		{
			sprintf(buf, "1OUT.12-%d", val);
		}
	}

	cm_output(buf);
	Sleep(100);
	cm_output("CDONE");
	cm_input(buf);
}

static	float	ion_vals[3] = {0.0, 0.0, 0.0};

double	cm_get_ion(int which)
{
	char	buf[2048],line[2048],*cp;
	float	val,vals[3];
	int	i,bad;
	int	cmdebug_save;

	if(1 || in_manual)
		return(-1.);
	cmdebug_save = cmdebug;
	cmdebug = 0;

	cm_output("RDION");
	cm_output("CDONE");
	cm_input(buf);
	
	cp = &buf[0];

	bad = 0;
	for(i = 0; i < 3; i++)
	{
		for(; *cp != '\0'; cp++)
			if(*cp == '*')
				break;
		if(*cp == '\0')
		{
			fprintf(stderr,"cm_get_ion: unexpected EOF looking for ion %d\n", i);
			bad = 1;
			break;
		}
		*cp++;
		if(*cp == '\0')
		{
			fprintf(stderr,"cm_get_ion: unexpected EOF looking for ion %d\n", i);
			bad = 1;
			break;
		}
		sscanf(cp,"%f", &vals[i]);
	}
	if(bad == 0)
	{
		for(i = 0; i < 3; i++)
			ion_vals[i] = vals[i];
	}
	else
	{
		cm_output("RS");
		cm_input_resync(line);
	}
	val = ion_vals[which];

	if(1)
		cmdebug = cmdebug_save;
	if(0)
		fprintf(stderr,"cm_get_ion: which: %d val: %8.3f\n",which, val);
	return((double) val);
}

cm_get_ion_all_old(float svals[3])
{
	char	buf[2048],line[2048],*cp;
	float	val,vals[3];
	int	i,bad;
	int	cmdebug_save;

	if(1 || in_manual)
		return;
	if(1)
	{
		cmdebug_save = cmdebug;
		cmdebug = 0;
	}

	cm_output("RDION");
	cm_output("CDONE");
	cm_input(buf);
	
	cp = &buf[0];

	bad = 0;
	for(i = 0; i < 3; i++)
	{
		for(; *cp != '\0'; cp++)
			if(*cp == '*')
				break;
		if(*cp == '\0')
		{
			fprintf(stderr,"cm_get_ion: unexpected EOF looking for ion %d\n", i);
			bad = 1;
			break;
		}
		*cp++;
		if(*cp == '\0')
		{
			fprintf(stderr,"cm_get_ion: unexpected EOF looking for ion %d\n", i);
			bad = 1;
			break;
		}
		sscanf(cp,"%f", &vals[i]);
	}
	if(bad == 0)
	{
		for(i = 0; i < 3; i++)
		{
			ion_vals[i] = vals[i];
			stat_ion[i] = vals[i];
		}
	}
	else
	{
		cm_output("RS");
		cm_input_resync(line);
	}
	for(i = 0; i < 3; i++)
		svals[i] = ion_vals[i];

	if(1)
		cmdebug = cmdebug_save;
	if(0)
		fprintf(stderr,"cm_get_ion_all: vals: %8.3f %8.3f %8.3f\n",svals[0],svals[1],svals[2]);
	return;
}

cm_get_ion_all(float svals[3])
{
	char	buf[2048],line[2048],*cp, *cp_start;
	float	val,vals[3];
	int	i,bad;
	int	cmdebug_save;

	if(0 || in_manual)
		return;

	cmdebug_save = cmdebug;
	cmdebug = 0;

	cm_settimeout(1000);
	cm_output("RDION");
	cm_output("CDONE");
	cp = buf;
	if(1 == cm_input_buflim(buf, sizeof buf))
	{
		bad = 1;
	}
	else
	{
		if(0)
		{
			fprintf(stdout,"cm_get_ion_all: buffer: ");
			for(i = 0; *(cp + i) != '\0'; i++)
				if(*(cp + i) != '\n')
					fprintf(stdout,"%c", *(cp + i));
				else
					fprintf(stdout,"<nl>");
			fprintf(stdout,"\n");
		}
		if(NULL == (cp = strstr(buf, "CMD_DONE")))
		{
			fprintf(stderr,"cm_get_ion_all: CMD_DONE not found in returned buffer.\n");
			bad = 1;
		} else
		{
			for(i = 0; cp >= buf; cp--)
				if(*cp == '\n')
				{
					i++;
					if(i == 4)
						break;
				}
			cp++;
			bad = 0;
			for(i = 0; i < 3; i++)
			{
				cp_start = cp;
				for(; *cp != '\0'; cp++)
					if(*cp == '\n')
						break;
				if(*cp == '\0')
				{
					fprintf(stderr,"cm_get_ion: unexpected EOF looking for ion %d\n", i);
					bad = 1;
					break;
				}
				*cp++;
				sscanf(cp_start,"%f", &vals[i]);
			}
		}
	}
	if(bad == 0)
	{
		for(i = 0; i < 3; i++)
		{
			ion_vals[i] = vals[i];
			stat_ion[i] = vals[i];
		}
	}
	else
	{
		cm_output("RS");
		cm_input_resync(line);
	}
	for(i = 0; i < 3; i++)
		svals[i] = ion_vals[i];

	if(1)
		cmdebug = cmdebug_save;
	if(0)
		fprintf(stderr,"cm_get_ion_all: vals: %8.3f %8.3f %8.3f\n",svals[0],svals[1],svals[2]);
	return;
}

int	cm_check_beam_avail()
{
	char	buf[2048];

	cm_output("CHKBA");
	cm_output("CDONE");
	cm_input(buf);

	if(NULL != (char *) strstr(buf, "NO_BEAM_AVAIL"))
		return(0);
	if(NULL != (char *) strstr(buf, "BEAM_AVAIL"))
		return(1);
	fprintf(stderr,"cm_check_beam_avail: Neither NO_BEAM_AVAIL or BEAM_AVAIL found on input\n");
	return(1);
}

int	cm_check_holdoff()
{
	char	buf[2048];

	cm_output("CHKHO");
	cm_output("CDONE");
	cm_input(buf);

	if(NULL != (char *) strstr(buf, "NO_HOLDOFF"))
		return(0);
	if(NULL != (char *) strstr(buf, "HOLDOFF"))
		return(1);
	fprintf(stderr,"cm_check_holdoff: Neither NO_HOLDOFF nor HOLDOFF found on input\n");
	return(1);
}

cm_set_slit(int which, double val)
{
	char	*cp, buf[2048];

	if(0)
		return;
	cm_settimeout(15000);

	cm_output("`MSTalk");
	cm_output("`MSDoneMessageOnly");

	if(0 == val)
		sprintf(buf, "`MSHome %d", which);
	else
		sprintf(buf, "`MSSet %d %.1f", which, val);
	cm_output(buf);

	cm_input_until(buf, sizeof buf, "xl_done");
	cm_output("`MSQuiet");
}

cm_get_slits()
{
	char	buf[2048];
	float 	vals[4];
	int 	i, nitems;
	int 	bad;
	char	*cp;
	int	cmdebug_save;

	if(0)
		return;
	cmdebug_save = cmdebug;
	cmdebug = 0;

	cm_settimeout(1000);

	cm_output("`MSTalk");
	cm_output("`MSDoneMessageOnly");

	cm_output("`MSGet");
	cm_output("CDONE");

	cm_input_wait(buf, 2048);

	if(0)
		fprintf(stderr,"cm_get_slits: buf: %s\n", buf);

	nitems = sscanf(&buf[0], "%f %f %f %f", &vals[0], &vals[1], &vals[2], &vals[3]);
	if(nitems < 4)
	{
		fprintf(stderr,"cm_get_slits: Not enough slit values (%d) on read\n", nitems);
	}
	else
	{
		stat_slits[0] = vals[0];
		stat_slits[1] = vals[1];
		stat_slits[2] = vals[2];
		stat_slits[3] = vals[3];
		stat_xl_hslit = stat_slits[2];
		stat_xl_vslit = stat_slits[3];
		stat_xl_guard_hslit = stat_slits[0];
		stat_xl_guard_vslit = stat_slits[1];
		if(0)
			fprintf(stdout,
			"cm_get_slits: stat_xl_hslit: %.1f stat_xl_vslit:%.1f stat_xl_guard_hslit %.1f stat_xl_guard_vslit %.1f\n",
					stat_xl_hslit, stat_xl_vslit, stat_xl_guard_hslit, stat_xl_guard_vslit);
	}

	if(1)
		return;

	bad = 1;
	if(0 == cm_input_until(buf, sizeof buf, "xl_done"))
	{
		if(0)
		{
			cp = buf;
			fprintf(stdout,"cm_get_slits: buffer: ");
			for(i = 0; *(cp + i) != '\0'; i++)
				if(*(cp + i) != '\n')
					fprintf(stdout,"%c", *(cp + i));
				else
					fprintf(stdout,"<nl>");
			fprintf(stdout,"\n");
		}
		if(NULL == (cp = strstr(buf, "xl_done")))
		{
			fprintf(stderr,"cm_get_slits: xl_done not found in returned buffer.\n");
		} else
		{
			for(i = 0; cp >= buf; cp--)
				if(*cp == '\n')
				{
					i++;
					if(i == 2)
						break;
				}
			cp++;
			nitems = sscanf(cp,"%f %f %f %f", &vals[0], &vals[1], &vals[2], &vals[3]);
			if(nitems < 4)
			{
				fprintf(stderr,"cm_get_slits: Not enough slit values (%d) on read\n", nitems);
			}
			else
			{
				bad = 0;
				stat_slits[0] = vals[0];
				stat_slits[1] = vals[1];
				stat_slits[2] = vals[2];
				stat_slits[3] = vals[3];
				stat_xl_hslit = stat_slits[0];
				stat_xl_vslit = stat_slits[1];
				stat_xl_guard_hslit = stat_slits[2];
				stat_xl_guard_vslit = stat_slits[3];
				if(0)
				fprintf(stdout,
			"cm_get_slits: stat_xl_hslit: %.1f stat_xl_vslit:%.1f stat_xl_guard_hslit %.1f stat_xl_guard_vslit %.1f\n",
					stat_xl_hslit, stat_xl_vslit, stat_xl_guard_hslit, stat_xl_guard_vslit);
			}
		}
	}
	else
	{
		if(1)
		{
			cp = buf;
			fprintf(stdout,"cm_get_slits: buffer: ");
			for(i = 0; *(cp + i) != '\0'; i++)
				if(*(cp + i) != '\n')
					fprintf(stdout,"%c", *(cp + i));
				else
					fprintf(stdout,"<nl>");
			fprintf(stdout,"\n");
		}
	}
	if(bad == 1)
	{
		cm_output("RS");
		cm_input_resync(buf);
	}
	cmdebug = cmdebug_save;
}
/*
 *	cm_cleanupforexit()
 *
 *	Perform all the nice, little things before exiting.  This
 *	procedure is only called via the SIGHUP signal, which only
 *	gets generated from ccd_daemon.
 */

void	cm_cleanupforexit()
{
  	/*
	 *	Check manual mode.  Return to computer if so.
	 *
	 *	Any angle changes inside of manual mode are read out
	 *	when control is returned to the computer.
	 */
	if(in_manual)
		cm_manual(0);
	
	/*
	 *	Put motor values out to disk.
	 */
	cm_putmotval();

	cm_output("`CCManual");
	Sleep(1000);
	fprintf(stderr,"Cleanup_for_exit: closing file descriptor %d\n", motfd);
	shutdown(motfd, 2);
}

int 	abortable_command(int no)
{
	return(0);
}

#ifdef WINNT

void	cm_abort()
{
	abort_asserted = 1;

	fprintf(stderr,"cm_abort: aborting command number: %d\n", command_in_progress);
	fflush(stderr);
	fflush(stdout);

	if(1)
	{
		cm_output("!K");
		Sleep(1000);
		cm_output("CDONE");
		_endthread();
		return;
	}

	switch(command_in_progress)
	{
	case -1:
		break;

	case MDC_COM_DMOVE:
		cm_output("!S,1");
		fprintf(stderr, "\n\n");
		fflush(stderr);
		Sleep(5000);
		break;
	case MDC_COM_LMOVE:
		cm_output("!S,,1");
		fprintf(stderr, "\n\n");
		fflush(stderr);
		Sleep(5000);
		break;
	case MDC_COM_PMOVEREL:
		cm_output("!S1");
		fprintf(stderr, "\n\n");
		fflush(stderr);
		Sleep(5000);
		break;
	case MDC_COM_PMOVE:
		fprintf(stderr,"PMOVE command: outputting !S1\n\n");
		cm_output("!S1");
		fprintf(stderr,"PMOVE command: finished outputting !S1\n");
		fprintf(stderr,"\n\n");
		fflush(stderr);
		fprintf(stderr,"sleep 5000 msec\n");
		Sleep(5000);
		fprintf(stderr,"sleep finished\n");
		fflush(stderr);
		break;
	case MDC_COM_MZ:
		cm_output("!S,,,1");
		break;
	case MDC_COM_DHOME:
		cm_output("!K");
		Sleep(1000);
		cm_output("CDONE");
		break;
	case MDC_COM_OHOME:
		cm_output("!K");
		Sleep(1000);
		cm_output("CDONE");
		break;
	case MDC_COM_THHOME:
		cm_output("!K");
		Sleep(1000);
		cm_output("CDONE");
		break;
	case MDC_COM_ZHOME:
		cm_output("!K");
		Sleep(1000);
		cm_output("CDONE");
		break;
	case MDC_COM_COLL:
		cm_output("!K");
		Sleep(1000);
		cm_output("CDONE");
		break;
	default:
		break;
	}
}

int		old_abortable_command(int no)
{
	switch(no)
	{
	case MDC_COM_DMOVE:
	case MDC_COM_LMOVE:
	case MDC_COM_PMOVEREL:
	case MDC_COM_PMOVE:
	case MDC_COM_MZ:
	case MDC_COM_DHOME:
	case MDC_COM_OHOME:
	case MDC_COM_THHOME:
	case MDC_COM_ZHOME:
	case MDC_COM_COLL:
		return(1);

	default:
		return(0);
	}
}

#endif /* WINNT */
