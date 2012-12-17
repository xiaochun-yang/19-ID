#include	"ccd_bl_ext.h"

/*
 *--------------------------------------------------
 *
 *	Input commands via local beamline control.
 *
 *--------------------------------------------------
 */

/*
 *	Routine to parse a set of input lines to one of
 *	several clients of ccd_dc.  This currently includes
 *
 *		ccd_bl
 *		ccd_det
 *		ccd_xform
 *
 *	The input to each program looks like:
 *
 *		directive
 *		command
 *		   .
 *		   .
 *		   .
 *		command
 *		end_marker
 *
 *	Where "directive" is something meaningful to the particular
 *	process.  It always stands alone on the first line.
 *
 *	"command" is a '\n' terminated substring.
 *
 *	"end_marker" is an end marker specific to the process.
 *
 *	When finished with the parsing, the program sets the global
 *		int	ccdparse_linec
 *	to the number of lines found and the global
 *		char	*ccdparse_linev[]
 *	to the breaks in the lines.  The '\n's are replaced with \'0'
 *	for the convienece of string handline routines.
 *
 *	Additionally, each line is broken up into strings (separated by
 *	spaces or '\0' is the delimeter).  The global
 *		int	ccdparse_subc[MAXLINES];
 *	contains the number of substrings in each line.
 *	The global
 *		char	*ccdparse_subv[MAXLINES][MAXSUB]
 *	the pointers to each.
 */

#define	MAXLINES	100
#define	MAXSUB		10

int		ccdparse_linec;
char	*ccdparse_linev[MAXLINES];
int		ccdparse_subc[MAXLINES];
char	*ccdparse_subv[MAXLINES][MAXSUB];

ccd_parse1(buf)
char	*buf;
  {
	int	i,n;
	char	*p,*q;
	ccdparse_linec = 0;

	for(p = buf, i = 0; buf[i] != '\0'; i++)
	  if(buf[i] == '\n')
	    {
		ccdparse_linev[ccdparse_linec] = p;
		ccdparse_linec++;
		buf[i] = '\0';
		p = &buf[i+1];
	    }
	if(p != &buf[i])
	  {
		ccdparse_linev[ccdparse_linec] = p;
		ccdparse_linec++;
	  }

	for(n = 0; n < ccdparse_linec; n++)
	  {
	    ccdparse_subc[n] = 0;
	    for(p = q = ccdparse_linev[n]; *q != '\0'; q++)
	      if(*q == ' ')
		{
		  ccdparse_subv[n][ccdparse_subc[n]] = p;
		  ccdparse_subc[n]++;
		  *q = '\0';
		  p = q + 1;
		}
	    if(p != q)
	      {
		  ccdparse_subv[n][ccdparse_subc[n]] = p;
		  ccdparse_subc[n]++;
	      }
	  }
  }
			
/*
 *	subroutine to obtain the nth token (non-white-space grouping)
 *	from a character string.  Return 1 if there is an identifiable
 *	token, 0 if none can be found.  Copy the token to the character
 *	string tok if found.
 *
 *	1 is the first token, 2 the second, just for the record.
 */

int	get_token(c,n,tok)
char	*c,*tok;
int	n;
{
	char	*cp,*sp,*ep;
	int		i;

	sp = c;

	for(i = 0; i < n; i++)
	{
	    /*
	     *	Motor thru white space.
	     */
		for(cp = sp; ; cp++)
		{
			if(*cp == '\n' || *cp == '\0')
				return 0;
			if(*cp == ' ' || *cp == '\t')
				continue;
			break;
		}
	    for(ep = cp; ; ep++)
		if(*ep == ' ' || *ep == '\t' || *ep == '\n' || *ep == '\0')
			break;

		if(i == (n - 1))
		{
			for(sp = cp; sp < ep; )
				*tok++ = *sp++;
			*tok++ = '\0';
			return 1;
		}
		sp = ep;
	}
	return(1);
}

int	inbuf_initialized = 0;

char	inbuf[2048];
char	*inptr;
int	inlen;

char	termstring[] = {'e','o','c','\n','\0'};

/*
 *	subroutine to read the command file, parsing the input, until
 *	the "eoc" marker is found.  Set up the queues, etc., when done.
 */

static char	simplenull[] = "\n";

int	mdc_process_input(next)
{
	char 		line[132];
	char		tok1[132],tok2[132];
	int		i,j,ii,jj;
	char		*stringpointer;
	int		bindex;

/*
 *	Loop through the lines contained in inbuf
 *	and pass them thru to the parsing code below.
 */

	bindex = 0;

	while(1)
	  {
	    if(bindex >= inlen)
		break;
	    for(ii = bindex, jj = 0; ii < inlen; ii++,jj++)
	      {
		line[jj] = inbuf[ii];
		if(line[jj] == '\n')
		  {
		    line[jj+1] = '\0';
		    bindex = ii + 1;
		    break;
		  }
	      }
	    if(0 == get_token(line,1,tok1))
		continue;	/* just ignore white space... */
	    
	    for(i = j = 0; mdc_comlit[i] != NULL; i++)
	      if(0 == strcmp(mdc_comlit[i],tok1))
		{
			j = 1;
			break;
		}
	    if(j == 0)
	      {
		fprintf(stderr,"mardc: %s is an unrecognized command\n",
			tok1);
		cleanexit(BAD_STATUS);
	      }
	    
	    if(i == MDC_COM_EXIT)
	      {
	        cleanexit(GOOD_STATUS);
	      }
	    
	    /*
	     *	Get a new queue entry from among the empties in the 
	     *	array of queue entries.  We only do this if the input
	     *	line is NOT part of a collect modifier.
	     */
	    
	    if(i < MDC_COL_DIST && i != MDC_COM_EOC)
	      {
	        mdc_queue[next].cmd_no = i;
	        mdc_queue[next].cmd_err = 0;
		mdc_queue[next].cmd_value = 0;
		mdc_queue[next].cmd_used = 1;
		mdc_queue[next].cmd_col_mode = 0;
		mdc_queue[next].cmd_col_lift = -9999.;
		mdc_queue[next].cmd_col_remarkc = 0;
		/*
		 *	These are given defaults (this is a beamline prog, not a data collection prog).
		 */
		mdc_queue[next].cmd_col_n_images = 1;		/* one image only */
		mdc_queue[next].cmd_col_n_passes = 1;		/* one pass only */
		mdc_queue[next].cmd_col_dir[0] = '\0';		/* No file output from this prog occurs */
		mdc_queue[next].cmd_col_prefix[0] = '\0';	/* No file output from this prog occurs */
		mdc_queue[next].cmd_col_suffix[0] = '\0';	/* No file output from this prog occurs */
		mdc_queue[next].cmd_col_image_number = 1;	/* No file output from this prog occurs */
		mdc_queue[next].cmd_col_mode = 4;		/* Specifies beamline operation ONLY */
		mdc_queue[next].cmd_col_bin = 1;
		mdc_queue[next].cmd_col_adc = 0;
		mdc_queue[next].cmd_col_omegas = 0;
		mdc_queue[next].cmd_col_kappas = 0;
		mdc_queue[next].cmd_col_axis = 1;

		/*
		 *	Data collection parameters which MUST be specified are:
		 *
		 *		distance
		 *		lift
		 *		phi start
		 *		oscillation width
		 *		time
		 *
		 *	These comprise the physical parameters which the program must know in
		 *	order to use the base as a data collection platform ONLY.
		 */

	      }

	    switch(i)
	      {
		case MDC_COM_DMOVE:
		case MDC_COM_PMOVE:
		case MDC_COM_PMOVEREL:
		case MDC_COM_OMOVEREL:
		case MDC_COM_DSET:
		case MDC_COM_PSET:
		case MDC_COM_SHUT:
		case MDC_COM_CONFIG:
		case MDC_COM_LMOVE:
		case MDC_COM_LSET:
		case MDC_COM_OMOVE:
		case MDC_COM_KMOVE:
		case MDC_COM_OSET:
		case MDC_COM_KSET:
		case MDC_COM_GONMAN:
		case MDC_COM_HOME:
		case MDC_COM_WSET:
		case MDC_COM_WMOVE:
		case MDC_COM_DHOME:
		case MDC_COM_OHOME:
		case MDC_COM_THHOME:
		case MDC_COM_ZHOME:
		case MDC_COM_MZ:
		case MDC_COM_BL_READY:
		case MDC_COM_STAT:
		case MDC_COM_SYNC:
		case MDC_COM_RETURN_DIST:
		case MDC_COM_RETURN_OMEGA:
		case MDC_COM_RETURN_2THETA:
		case MDC_COM_RETURN_Z:
		case MDC_COM_RETURN_ALL:
                case MDC_COM_XL_HS_MOVE:
                case MDC_COM_XL_VS_MOVE:
                case MDC_COM_XL_UP_HHS_MOVE:
                case MDC_COM_XL_UP_VHS_MOVE:
                case MDC_COM_XL_DN_HHS_MOVE:
                case MDC_COM_XL_DN_VHS_MOVE:
                case MDC_COM_XL_GUARD_HS_MOVE:
                case MDC_COM_XL_GUARD_VS_MOVE:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%f",&mdc_queue[next].cmd_value);
		  break;
		case MDC_COM_GET_WAVELENGTH:
			break;
		case MDC_COM_ABORT:
			fprintf(stderr,"ccd_bl_abort:  ABORT Seen with no command in progress\n");
			break;
		case MDC_COM_GETGON:
			break;
		case MDC_COL_DIST:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%f",
			&mdc_queue[next].cmd_col_dist);
		  break;
		case MDC_COL_PHIS:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%f",
			&mdc_queue[next].cmd_col_phis);
		  break;
                case MDC_COL_OSTART:
                  if(0 == get_token(line,2,tok2))
                    {
                      mdc_queue[next].cmd_err = 1;
                      break;
                    }
                  sscanf(tok2,"%f",
                        &mdc_queue[next].cmd_col_omegas);
                  break;
                case MDC_COL_KSTART:
                  if(0 == get_token(line,2,tok2))
                    {
                      mdc_queue[next].cmd_err = 1;
                      break;
                    }
                  sscanf(tok2,"%f",
                        &mdc_queue[next].cmd_col_kappas);
                  break;
                case MDC_COL_AXIS:
                  if(0 == get_token(line,2,tok2))
                    {
                      mdc_queue[next].cmd_err = 1;
                      break;
                    }
                  mdc_queue[next].cmd_col_axis = 1;
                  sscanf(tok2,"%d",
                        &mdc_queue[next].cmd_col_axis);
		  break;
		case MDC_COL_OSCW:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%f",
			&mdc_queue[next].cmd_col_osc_width);
		  break;
		case MDC_COL_NIM:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%d",
			&mdc_queue[next].cmd_col_n_images);
		  break;
		case MDC_COL_DEZING:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
                  sscanf(tok2,"%d",
                        &mdc_queue[next].cmd_col_n_passes);
                  mdc_queue[next].cmd_col_n_passes++;
		  break;
		case MDC_COL_TIME:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%f",
			&mdc_queue[next].cmd_col_time);
		  break;
		case MDC_COL_IMNO:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%d",
			&mdc_queue[next].cmd_col_image_number);
		  break;
		case MDC_COL_DIR:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  strcpy(mdc_queue[next].cmd_col_dir,tok2);
		  break;
		case MDC_COL_PRE:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  strcpy(mdc_queue[next].cmd_col_prefix,tok2);
		  break;
		case MDC_COL_SUF:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  strcpy(mdc_queue[next].cmd_col_suffix,tok2);
		  break;
		case MDC_COL_MODE:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  if(0 == strcmp("spiral",tok2))
		    {
		      mdc_queue[next].cmd_col_mode = 2;
		      break;
		    }
		  if(0 == strcmp("calibration",tok2))
		    {
			mdc_queue[next].cmd_col_mode = 3;
			break;
		    }
		  if(0 == strcmp("beamline_dc",tok2))
		    {
			mdc_queue[next].cmd_col_mode = 4;
			break;
		    }
		  if(0 == strcmp("darkcurrent_dc",tok2))
		    {
			mdc_queue[next].cmd_col_mode = 5;
			break;
		    }
		  if(0 == strcmp("time",tok2))
		    mdc_queue[next].cmd_col_mode = 0;
		   else
		    mdc_queue[next].cmd_col_mode = 1;
		  break;
		case MDC_COL_WAVE:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
 		  sscanf(tok2,"%f",&stat_wavelength);
		  break;
		case MDC_COL_LIFT:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%f",
			&mdc_queue[next].cmd_col_lift);
		  break;
		case MDC_COL_ADC:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%d",
			&mdc_queue[next].cmd_col_adc);
		  break;
		case MDC_COL_BIN:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%d",
			&mdc_queue[next].cmd_col_bin);
		  break;
                case MDC_COL_CENTER:
                  if(0 == get_token(line,2,tok2))
                    {
                      mdc_queue[next].cmd_err = 1;
                      break;
                    }
                  sscanf(tok2,"%f",
                        &mdc_queue[next].cmd_col_xcen);
                  if(0 == get_token(line,3,tok2))
                    {
                      mdc_queue[next].cmd_err = 1;
                      break;
                    }
                  sscanf(tok2,"%f",
                        &mdc_queue[next].cmd_col_ycen);
                  break;
		case MDC_COL_REMARK:
		  if(0 == get_token(line,2,tok2))
			stringpointer = simplenull;
		    else
			stringpointer = tok2;
		  if(NULL == (mdc_queue[next].cmd_col_remarkv[mdc_queue[next].cmd_col_remarkc] =
				(char *) calloc(strlen(stringpointer) + 1,sizeof (char))))
		    {
			    fprintf(stderr,"mardc: error calloc memory for remark command\n");
			    cleanexit(BAD_STATUS);
		    }
		  strcpy(mdc_queue[next].cmd_col_remarkv[mdc_queue[next].cmd_col_remarkc],stringpointer);
		  mdc_queue[next].cmd_col_remarkc++;
		  break;
	      }
	    if(i == MDC_COM_EOC)
		break;
	  }
	return(0);
}

/*
 *	This function queues a special initialize
 *	command which is run when the program starts
 *	up.  mdc_heartbeat finds the queue non-empty
 *	when it starts up, causing the init to execute.
 *
 *	This one has a value of 1 to indicate that
 *	distance initialization is NOT done.
 */

mdc_queue_init_command()
  {

	mdc_queue[0].cmd_no = MDC_COM_STARTUP;
	mdc_queue[0].cmd_err = 0;
	mdc_queue[0].cmd_value = 1;
	mdc_queue[0].cmd_used = 1;
	mdc_queue[0].cmd_col_mode = 0;
	mdc_queue[0].cmd_col_remarkc = 0;

	/*
	 *	Insert this entry at the end of the list.
	 */
	
	mdc_queue[0].cmd_next = NULL;
	mdc_head = &mdc_queue[0];
  }

/*
 *	This module performs local beamline control before, during, and
 *	after exposures are taken.
 *
 *	When it is finished, its return will signal to mardc_net that
 *	data collection may resume.
 *
 *	"buf" is a null terminated string containing information passed
 *	to mardc_net via the control GUI.  It is of the form:
 *
 *	prefix string_1 ... string_n suffix
 *
 *	Where:
 *
 *	  prefix is:
 *			before		This call occurs just before the
 *					first image in a run is to be
 *					collected.  Beam line stability and
 *					correct oprating conditions may be
 *					checked here before starting the run.
 *
 *			during		This call occurs after each image has
 *					been taken.  It is mostly designed for
 *					the future where we might want to do
 *					something in between each image.  It
 *					can also check here to make sure that
 *					the beamline is still functioning properly.
 *
 *			after		This call occurs after the last image in
 *					a run.  Functions which need to be done
 *					after a run should be performed here.
 *
 *	string_1 thru string_n are the "macros" passed from the GUI.  They
 *		are totally locally defined.
 *
 *	suffix is the string "end_of_bl\n" so that beamline_net can tell the
 *		end of the command.  Note that when sockets are used one might
 *		not get all the data in one read so we need an end marker.
 */

/*
 *	Command types which can be received by beamline control.
 */

char	*blcmdtypes[] = {
			"cmd",
			"before",
			"during",
			"after",
			NULL
			};

#define	BL_CMD		0
#define	BL_BEFORE	1
#define BL_DURING	2
#define	BL_AFTER	3

/*
 *	This prototype control program just writes its input to
 *	the standard output (which then gets logged in a disk file).
 */

int		local_beamline_control(char *buf)
  {
	int	i,j,n;
	int	cmdno;

	ccd_parse1(buf);

	/*
	 *	Figure out the action based on what has been transmitted.
	 */
	
	if(ccdparse_linec == 0)
		return(0);		/* nothing in the buffer... */

	cmdno = -1;
	for(n = 0; blcmdtypes[n] != NULL; n++)
	  if(0 == strcmp(blcmdtypes[n],ccdparse_subv[n][0]))
	    {
		cmdno = n;
		break;
	    }
	if(cmdno == -1)
		return(0);		/* not recognizable */
	
	switch(cmdno)
	  {
	    case BL_CMD:
		if(ccdparse_linec < 2)
			return(0);		/* nothing but cmd\n end_of_bl\n in the string... */

		inlen = 0;
		inbuf[0] = '\0';
		for(i = 1; i < ccdparse_linec - 1; i++)
		  {
		    for(j = 0; j < ccdparse_subc[i]; j++)
		      {
			strcat(inbuf,ccdparse_subv[i][j]);
			strcat(inbuf," ");
		      }
		    strcat(inbuf,"\n");
		  }
		strcat(inbuf,"eoc\n");
		inlen = strlen(inbuf);
		mdc_process_input(0);
		ccd_bl_generic_cmd(0);
		break;
	    case BL_BEFORE:
	    case BL_DURING:
	    case BL_AFTER:
		break;
	  }
	return(0);
  }
