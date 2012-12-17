#include	"ccd_bl_ext.h"

#include	<termio.h>
#include	<sys/socket.h>
#include	<errno.h>
#include	<math.h>

static	int	motfd;
static	char	vmin0;
static	int	cn170debug = 0;
static	int	cn170delay1 = 0;
static	int	testdelay1 = 0;
static	int	testdelay2 = 0;

static short    cn170channo;              /* the channel number */
static int      cn170senseret[3];         /* status info for set/reset */
static char     cn170retstring[80];
static char     cn170retcopy[80];         /* a copy of the last returned string */
static char     cn170sentcopy[80];        /* a copy of the last command sent */
static char     ex_sent_str[80];
static char     ex_ret_str[80];
static int      cn170retlen;

static struct timeval	*readtimeout = NULL;
static struct timeval  readtimeval;

cn170setnoecho()
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

cn170printttymode()
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

cn170setecho()
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

int     cn170readraw()
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

                fprintf(stderr,"motor_dialog: select error (in readraw).  Should never happen.\n");
                perror("ccd_dc: select in ccd_check_alive");
		cn170setecho();
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

int     cn170writeraw(c)
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

int	cn0170_input(line)
char	*line;
  {
	int	i,j;
	char	c;

	j = 0;
	do {
	    i = cn170readraw();
	    if(i == -1)
	      {
		line[j] = '\0';
		return(1);
	      }
	    c = (char) i;
	    if(c != '\n')
		line[j++] = c;
	    } while(c != '\n');
	line[j] = '\0';
	return(0);
  }

int	cn0170_output(line)
char	*line;
 {
	int	i;

        for(i = 0; !(line[i] == '\n' || line[i] == '\0'); i++)
            cn170writeraw(line[i]);
        cn170writeraw('\r');
	return(0);
  }

struct cn0170_mdef {
			char	*cn_name;	/* the name of the motor */
			int	cn_unit;	/* the CN0170 unit number */
			char	cn_motor;	/* the CN0170 axis (X or Y) */
			int	cn_base;	/* base speed, normal operation, this axis */
			int	cn_top;		/* top speed, normal operation, this axis */
			int	cn_accel;	/* accelleration, normal operation, this axis */
			int	cn_stdeg;	/* number of steps per degree, this axis */
			int	cn_mode;	/* 0 if axis not init, 1 if normal, 2 if data collection */
			int	cn_noman;	/* 1 if no manual mode */
			int	cn_punit;	/* position unit */
			int	cn_pchan;	/* position channel */
		   };

struct cn0170_mdef kappa_motors[] = {
	"omega",  2,  'Y', 1000, 16000, 16000, 5000, 0, 0, 1,1,
	"phi",    1,  'X', 250, 1000, 1000,   50, 0, 0,    1,1,
	"kappa",  1,  'Y', 250, 1000, 1000,   50, 0, 0,    1,2,
	"2theta", 2,  'X', 250, 1000, 1000,  200, 0, 0,    0,2,
	"dist",   0,  'X', 250, 1000, 1000,  100, 0, 1,    0,0,
	NULL,     0, '\0',   0,    0,    0,    0, 0, 0,    0,0,
				    };

int	mind_motion;				/* motor in motion */

double	dist_conv = 1000. / 25.4 ;		/* brilliant: 1000 steps/inch */

int	cn0170_init(ttyname)
char	*ttyname;
  {
	char	c;
	int	i1,i2,i3,i4,i5;
	int	mind;
	char	line[132];

	if(-1 == (motfd = open(ttyname,2)))
	  {
	    fprintf(stderr,"motor_dialog: Canot open %s as kappa goniostat tty.\n",ttyname);
	    return(1);
	  }
	cn170setnoecho();

	readtimeval.tv_sec = 3;
	readtimeval.tv_usec = 0;
	readtimeout = &readtimeval;

	/*
	 *	Send out initialization sequence.
	 */
	
	cn0170_output("");
	i1 = cn0170_input(line);
	cn0170_output(".U=0;.U+1=1;.U+2=2;M1;");
	i2 = cn0170_input(line);
	i3 = cn0170_input(line);
	i4 = cn0170_input(line);
	i5 = cn0170_input(line);
	fprintf(stderr,"cn0170_init: (informational) Resposes: %d %d %d %d %d\n",i1,i2,i3,i4,i5);
	readtimeval.tv_sec = 0;
	readtimeval.tv_usec = 200000;
	for(mind = 0; NULL != kappa_motors[mind].cn_name; mind++) 
	  {
		    sprintf(line,".U%d;%cV=%d,%d;%cA=%d",kappa_motors[mind].cn_unit,
						 kappa_motors[mind].cn_motor,
						 kappa_motors[mind].cn_base,
						 kappa_motors[mind].cn_top,
						 kappa_motors[mind].cn_motor,
						 kappa_motors[mind].cn_accel);
	    	    cn0170_output(line);
	            kappa_motors[mind].cn_mode = 1;
	  }
	return(0);
  }

int	cn0170_close()
  {
	cn170setecho();
	close(motfd);
  }

cn0170_shutter(val)
int	val;
  {
	if(val == 0)
		cn0170_output(".U2;P3=0");
	    else
		cn0170_output(".U2;P3=1");
  }

cn0170_getmotval()
  {
	FILE	*fpmot;
	char	*positionfile;
	char	line[132];

	if(NULL == (positionfile = (char *) getenv("CCD_KAPPA_POSITIONS")))
	  {
	    fprintf(stderr,"cn0170_getmotval: no environment for CCD_KAPPA_POSITIONS\n");
	    return;
	  }
	if(NULL == (fpmot = fopen(positionfile,"r")))
	  {
	    fprintf(stderr,"cn0170_getmotval: cannot open %s as motor position file\n",positionfile);
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
  }

cn0170_putmotval()
  {
	FILE	*fpmot;
	char	*positionfile;

	if(NULL == (positionfile = (char *) getenv("CCD_KAPPA_POSITIONS")))
	  {
	    fprintf(stderr,"cn0170_putmotval: no environment for CCD_KAPPA_POSITIONS\n");
	    return;
	  }
	if(NULL == (fpmot = fopen(positionfile,"w")))
	  {
	    fprintf(stderr,"cn0170_putmotval: cannot create %s as motor position file\n",positionfile);
	    return;
	  }
	fprintf(fpmot,"%10.3f\n%10.3f\n%10.3f\n%10.3f\n%10.3f\n",
		stat_omega,stat_phi,stat_kappa,stat_2theta,stat_dist);
	fclose(fpmot);
  }

cn0170_check_motion()
  {
	char	line[132],line2[132];
	int	i,j;

	while(1)
	  {
	    sleep(1);
	    sprintf(line,"%cP?",kappa_motors[mind_motion].cn_motor);
	    cn0170_output(line);
	    if(cn0170_input(line))
	      {
		fprintf(stderr,"cn0170_check_motion: timeout occurred reading status\n");
		return;
	      }
	      
	    cn0170_input(line2);
	    fprintf(stderr,"cn0170_check_motion: received line: %s\n",line);
	    for(i = j = 0; line[i] != '\0';i++)
	      if(line[i] == '=')
		{
		  j = 1;
		  break;
		}
	    if(j == 1)
		break;
	    send_status();
	  }
  }

int	cn0170_dccheck()
  {
	char	line[132],line2[132];
	int	i,j;

	sprintf(line,"%cP?",kappa_motors[mind_motion].cn_motor);
	cn0170_output(line);
	if(cn0170_input(line))
	  {
		fprintf(stderr,"cn0170_check_motion: timeout occurred reading status\n");
		return(1);
	  }
	cn0170_input(line2);
	for(i = j = 0; line[i] != '\0';i++)
	  if(line[i] == '=')
		  return(1);

	return(0);
  }

int	cn0170_moveto(motstr,new_value,current_value)
char	*motstr;
double	new_value;
double	current_value;
  {
	int	mind,i_current,i_new,amt_to_move;
	double	slop,signed_slop,x1,x2,x3;
	char	line[132];

	for(mind = 0; NULL != kappa_motors[mind].cn_name; mind++) 
	  if(0 == strcmp(kappa_motors[mind].cn_name,motstr))
		break;
	if(kappa_motors[mind].cn_name == NULL)
		return(1);
	
	mind_motion = mind;

	fprintf(stderr,"cn0170_moveto: motor: %s new: %f current: %f\n",motstr,new_value,current_value);
	if(new_value == current_value)
		return(0);

	if(kappa_motors[mind].cn_mode != 1)
	  {
	    sprintf(line,".U%d;%cV=%d,%d;%cA=%d;",kappa_motors[mind].cn_unit,
						 kappa_motors[mind].cn_motor,
						 kappa_motors[mind].cn_base,
						 kappa_motors[mind].cn_top,
						 kappa_motors[mind].cn_motor,
						 kappa_motors[mind].cn_accel);
	    fprintf(stderr,"cn0170_moveto: initialize motor %s with %s\n",kappa_motors[mind].cn_name,line);
	    cn0170_output(line);
	    kappa_motors[mind].cn_mode = 1;
	  }

        /*
         *      Check to see if the requested motor position is reasonable.
         *
         *      x1 will be a value from 0 <= x1 < 360.
         */

	if(mind == 4)	/* distance */
	  {
        	x1 = new_value;
        	x2 = current_value;
		amt_to_move = (x1 - x2) * kappa_motors[mind].cn_stdeg;
		amt_to_move = - amt_to_move;
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
            case 0:     /* omega */
                if(x1 > 120. && x1 < 240.)
                  {
                    fprintf(stderr,"acs_moveto: %f (renormalized from %f) is an ILLEGAL omega value\n",x1,new_value);
                    fprintf(stderr,"            Motions are restricted to be 240 to 360, 0 to 120 (-120 < omega < 120)\n");
                    return;
                  }
                break;
            case 2:     /* kappa */
                if(x1 > 90 && x1 < 270)
                  {
                    fprintf(stderr,"acs_moveto: %f (renormalized from %f) is an ILLEGAL kappa value\n",x1,new_value);
                    fprintf(stderr,"            Motions are restricted to be 270 to 360, 0 to 90 (-90 < kappa < 90)\n");
                    return;
                  }
                break;
            case 3:     /* two theta */
                if(x1 > 45 && x1 < 315)
                  {
                    fprintf(stderr,"acs_moveto: %f (renormalized from %f) is an ILLEGAL 2theta value\n",x1,new_value);
                    fprintf(stderr,"            Motions are restricted to be 315 to 360, 0 to 45 (-45 < 2theta < 45)\n");
                    return;
                  }
                break;
            default:
                break;
          }

	if(x2 >= 180)
	  x2 -= 360.;
	if(x1 >= 180)
	  x1 -= 360.;


	x3 = x1 - x2;

	slop = 1. / (4. * kappa_motors[mind].cn_stdeg);
	if(x3 < 0)
		signed_slop = -slop;
	    else
		signed_slop = slop;

	amt_to_move = (x3 + signed_slop) * kappa_motors[mind].cn_stdeg;

skip_anglenorm:

	if(amt_to_move > 0)
		sprintf(line,".U%d;%c+%d",kappa_motors[mind].cn_unit,
					  kappa_motors[mind].cn_motor,
					  abs(amt_to_move));
	  else
	    if(amt_to_move < 0)
		sprintf(line,".U%d;%c-%d",kappa_motors[mind].cn_unit,
					  kappa_motors[mind].cn_motor,
					  abs(amt_to_move));
	      else
		return(0);
	fprintf(stderr,"cn0170_moveto: line sent: %s\n",line);
	cn0170_output(line);

	cn0170_check_motion();

	return(0);
  }

int	cn0170_manual(mode)
int	mode;
  {
	int	i,mind;
	char	line[132];

	if(mode == 0)
	  {
	    for(mind = 0; NULL != kappa_motors[mind].cn_name; mind++) 
	      {
	    	    sprintf(line,".U%d;%cJ0",kappa_motors[mind].cn_unit,
					     kappa_motors[mind].cn_motor);
		    fprintf(stderr,"cn0170_manual: outputting %s\n",line);
	    	    cn0170_output(line);

		    while(0 == cn0170_input(line));
	      }
	  }
	 else
	  {
	    for(mind = 0; NULL != kappa_motors[mind].cn_name; mind++) 
	     if(kappa_motors[mind].cn_noman == 0)
	      {
	    	    sprintf(line,".U%d;%cV=%d,%d;%cA=%d;%cJ3",kappa_motors[mind].cn_unit,
						 kappa_motors[mind].cn_motor,
						 kappa_motors[mind].cn_base,
						 kappa_motors[mind].cn_top,
						 kappa_motors[mind].cn_motor,
						 kappa_motors[mind].cn_accel,
						 kappa_motors[mind].cn_motor);
	    	    cn0170_output(line);
	            kappa_motors[mind].cn_mode = 1;
	      }
	  }
  }

int	return_position_value(motstr,mind)
char	*motstr;
int	mind;
  {
	char	line[132];

	sprintf(line,".U%d;P%d?;",kappa_motors[mind].cn_punit,kappa_motors[mind].cn_pchan);
	fprintf(stderr,"return_position_value(%s)(mind:%d): outputting %s\n",motstr,mind,line);
	cn0170_output(line);
	do {
	    if(1 == cn0170_input(line))
	      {
		fprintf(stderr,"return_position_value(%s): timeout\n",motstr);
		break;
	      }
	     fprintf(stderr,"return_position_value(%s): received %s\n",motstr,line);
	   } while(NULL == strchr(line,'='));

	return(line[8] == '1');
  }

/*
 *	Home the angles.
 */

int	cn0170_home_motor(motstr,p_mot,sec_mot)
char	*motstr;
float	*p_mot;
  {
	int	mind,mind_sec,done;
	char	line[132];

	while(0 == cn0170_input(line));

	for(mind = 0; NULL != kappa_motors[mind].cn_name; mind++) 
	  if(0 == strcmp(kappa_motors[mind].cn_name,sec_mot))
		break;

	if(kappa_motors[mind].cn_name == NULL)
		return(1);
	mind_sec = mind;
	fprintf(stderr,"ccd_bl_kappa: mind_sec: %d\n",mind_sec);

	for(mind = 0; NULL != kappa_motors[mind].cn_name; mind++) 
	  if(0 == strcmp(kappa_motors[mind].cn_name,motstr))
		break;

	if(kappa_motors[mind].cn_name == NULL)
		return(1);

	mind_motion = mind;

	while(1)
	  {
	    if(return_position_value(motstr,mind))
		done = 1;
	      else
		done = 0;
	    if(!done)
	      {
	        return_position_value(sec_mot,mind_sec);   
	        cn0170_moveto(motstr,-10.,0.0);
	      }
	     else
		break;
	  }

	while(1)
	  {
	    if(0 == return_position_value(motstr,mind))
		done = 1;
	      else
		done = 0;
	    if(!done)
	      {
	        return_position_value(sec_mot,mind_sec);   
	        cn0170_moveto(motstr,10.,0.0);
	      }
	     else
		break;
	  }
	sprintf(line,".U%d;%cV=%d,%d;%cH-;%cH;",kappa_motors[mind].cn_unit,
						 kappa_motors[mind].cn_motor,
						 kappa_motors[mind].cn_base,
						 kappa_motors[mind].cn_base,
						 kappa_motors[mind].cn_motor,
						 kappa_motors[mind].cn_motor);
	fprintf(stderr,"cn0170_home_motor(%s): outputting %s\n",motstr,line);
	cn0170_check_motion();
	kappa_motors[mind].cn_mode = 0;
  }

int	cn0170_home()
  {
	if(1 == cn0170_home_motor("kappa",&stat_kappa,"2theta"))
		return(1);
/* 
	if(1 == cn0170_home_motor("omega",&stat_omega,"2theta"))
		return(1);
	if(1 == cn0170_home_motor("2theta",&stat_2theta,"omega"))
		return(1);
 */
  }

int	cn0170_dc(motstr,width,dctime)
char	*motstr;
double	width;
double	dctime;
  {
	int	mind,i_width;
	double	slop,signed_slop,axis_velocity;
	char	line[132];

	for(mind = 0; NULL != kappa_motors[mind].cn_name; mind++) 
	  if(0 == strcmp(kappa_motors[mind].cn_name,motstr))
		break;
	if(kappa_motors[mind].cn_name == NULL)
		return(1);
	
	cn0170_shutter(1);

	mind_motion = mind;
	kappa_motors[mind].cn_mode = 2;

	slop = 1. / (4. * kappa_motors[mind].cn_stdeg);
	if(width < 0)
		signed_slop = -slop;
	    else
		signed_slop = slop;
	i_width = (width + signed_slop) * kappa_motors[mind].cn_stdeg;

	axis_velocity = i_width / dctime;
	sprintf(line,".U%d;%cV=%.2f,%.2f",kappa_motors[mind].cn_unit,
						 kappa_motors[mind].cn_motor,
						 axis_velocity,
						 axis_velocity);
	fprintf(stderr,"cn0170_dc: setup line: %s\n",line);
	cn0170_output(line);

	sprintf(line,".U%d;%c+%d",kappa_motors[mind].cn_unit,
				  kappa_motors[mind].cn_motor,i_width);

	fprintf(stderr,"cn0170_dc: motion line: %s\n",line);
	cn0170_output(line);

	/*
	 *	Make sure there is nothing residual in the cn0170's buffer.
	 */
	
	while(0 == cn0170_input(line));

	return(0);
  }
