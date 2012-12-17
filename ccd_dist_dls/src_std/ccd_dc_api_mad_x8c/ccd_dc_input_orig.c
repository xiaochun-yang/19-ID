#include	"ccd_dc_ext.h"

/*
 *--------------------------------------------------
 *
 *	Input commands from the command input file.
 *
 *--------------------------------------------------
 */

			
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
	int	i;

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
  }

/*
 *	Routine to cover up the sins of reading from a socket
 *	connection where you cannot quite be sure how the data
 *	are being divided up as they are sent.
 *
 *	Read the input descriptor until the last four characters
 *	in the buffer are eoc\n.  Then break up the line(s) into
 *	the correct pieces for the code below to process.
 */

int	inbuf_initialized = 0;

#define	INBUFSIZE	20480

char	inbuf[INBUFSIZE];
char	*inptr;
int	inlen;

char	termstring[] = {'e','o','c','\n','\0'};

ccd_read_input()
  {
	fd_set		readmask;
	struct timeval	timeout;
	int		ret,i,j,k,n;

	if(inbuf_initialized == 0)
	  {
		inptr = inbuf;
		inlen = 0;
		inbuf_initialized = 1;
	  }

/*
 *	See if there is anything to get from the input.
 */

	if(fdcom == -1)		/* no connection yet, or closed */
	  {
		enqueue_fcn(ccd_read_input,0,1.0);
		return 0;
	  }
/*
 *	There is an open connection.
 *
 *	Read any data present.  When the eoc\n marker is
 *	found, call process_input, reset pointers, and
 *	return.
 */

	while(1)
	  {
	    FD_ZERO(&readmask);
	    FD_SET(fdcom,&readmask);
	    timeout.tv_sec = 0;
	    timeout.tv_usec = 0;
	    n = select(FD_SETSIZE,&readmask, (fd_set *) 0, (fd_set *) 0, &timeout);
	    if(n < 0)		/* this should never happen, but ... */
	      {
		fprintf(stderr,"ccd_dc: read input select error, errno = %d\n",errno);
		fprintf(fplog,"ccd_dc: read input select error errno = %d\n",errno);
		enqueue_fcn(ccd_read_input,0,1.0);
		return 0;
	      }
	    if(n == 0)		/* nothing to read */
	      {
		enqueue_fcn(ccd_read_input,0,1.0);
		return 0;
	      }
	    if(0 == FD_ISSET(fdcom,&readmask))
	      {
		enqueue_fcn(ccd_read_input,0,1.0);
		return 0;
	      }
	    ret = read(fdcom,inptr, INBUFSIZE - inlen);
	    if(ret <= 0)
	      {
		notify_server_eof(fdcom);
		enqueue_fcn(ccd_read_input,0,1.0);
		return 0;
	      }
	    *(inptr + ret) = '\0';
	    inlen += ret;
	    inptr += ret;
	    if(inlen >= 4)
	      {
		if(NULL == strstr(inbuf,termstring))
		  {
			continue;
		  }
		ccd_process_input();

		inlen = 0;
		inptr = inbuf;

		enqueue_fcn(ccd_read_input,0,1.0);
		return 0;
	      }
	  }
  }
	
/*
 *	subroutine to read the command file, parsing the input, until
 *	the "eoc" marker is found.  Set up the queues, etc., when done.
 */

static char	simplenull[] = "\n";

int	ccd_process_input()
  {
	char 		line[132];
	char		tok1[132],tok2[132];
	int		i,j,k,l,m,n,ii,jj;
	int		ncom;
	int		next;
	mdc_command	*qp;
	long		clock;
	char		*cptr;
	char		*stringpointer;
	fd_set		readmask;
	struct timeval	timeout;
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
		fprintf(stderr,"ccd_dc: WARNING: %s is an unrecognized command\n",
			tok1);
		continue;
	      }
	    
	    if(i == MDC_COM_EXIT)
	      {
		time(&clock);
		cptr = (char *) ctime(&clock);
		if(fpout != NULL)
		  {
		    fprintf(fpout,"ccd_dc: exiting immediately by request at %s\n",cptr);
		    fflush(fpout);
		  }
		fprintf(stderr,"ccd_dc: exiting immediately by request at %s\n",cptr);
	        cleanexit(GOOD_STATUS);
	      }
	    if(i == MDC_COM_STOP || i == MDC_COM_ABORT)
	      {
		if(i == MDC_COM_STOP)
		  {
			dc_stop = 1;
			fprintf(stdout,"ccd_dc_api: STOP after image seen.\n");
		  }
		   else
		     {
			dc_abort = 1;
			dc_abort_ctr = 0;
		     }
		if(fpout != NULL)
		  {
		    time(&clock);
		    cptr = (char *) ctime(&clock);
		    fprintf(fpout,"%s started %s",mdc_comlit[i],cptr);
		    fprintf(fpout,"%s done %s",mdc_comlit[i],cptr);
		    fflush(fpout);
		  }

		if(mdc_cmd_active)
		  {
		    qp = mdc_head;
		    do
		      {
			qp->cmd_used = 0;
			qp = qp->cmd_next;
		      }
		    while(qp != NULL);
		  }
		 else
		     qp->cmd_used = 0;
		mdc_head->cmd_next = NULL;
		   
/* DEBUG
		if(mdc_cmd_active)
		  {
		    mdc_head->cmd_next = NULL;
		    for(j = 0; j < MAXQUEUE; j++)
			if(&mdc_queue[j]  != mdc_head)
			  mdc_queue[j].cmd_used = 0;
		  }
		 else
		  {
		    mdc_head = NULL;
		    for(j = 0; j < MAXQUEUE; j++)
			mdc_queue[j].cmd_used = 0;
		  }
  DEBUG END */
		return 1;
	      }
	    
	    /*
	     *	Get a new queue entry from among the empties in the 
	     *	array of queue entries.  We only do this if the input
	     *	line is NOT part of a collect modifier.
	     */
	    
	    if(i < MDC_COL_DIST && i != MDC_COM_EOC)
	      {
	        for(j = k = 0; j < MAXQUEUE; j++)
	          if(mdc_queue[j].cmd_used == 0)
		    {
		      next = j;  k = 1;
		      break;
		    }
	    
	        if(k == 0)	/* we've run out of queue entries */
	          {
		    fprintf(stderr,"ccd_dc:  no input queue slots remain.\n");
		    fprintf(stderr,"\tThis is unlikely, so there must be\n");
		    fprintf(stderr,"\ta major problem.  Mardc is exiting.\n");
		    cleanexit(BAD_STATUS);
	          }

	        mdc_queue[next].cmd_no = i;
	        mdc_queue[next].cmd_err = 0;
		mdc_queue[next].cmd_value = 0;
		mdc_queue[next].cmd_used = 1;
		mdc_queue[next].cmd_col_mode = 0;
		mdc_queue[next].cmd_col_lift = -9999.;
		mdc_queue[next].cmd_col_remarkc = 0;
		mdc_queue[next].cmd_col_adc = 0;
		mdc_queue[next].cmd_col_bin = 1;
		mdc_queue[next].cmd_col_xcen = 45.;
		mdc_queue[next].cmd_col_ycen = 45.;
		mdc_queue[next].cmd_col_omegas = 0;
		mdc_queue[next].cmd_col_kappas = 0;
		mdc_queue[next].cmd_col_axis = 1;
		mdc_queue[next].cmd_col_newdark = 0;
		mdc_queue[next].cmd_col_anom = 0;
		mdc_queue[next].cmd_col_wedge = 20;
		mdc_queue[next].cmd_col_compress = 0;
		mdc_queue[next].cmd_col_blcmd[0] = '\0';
		mdc_queue[next].cmd_col_dzratio = -1.0;
		mdc_queue[next].cmd_col_dkinterval = -1;
		mdc_queue[next].cmd_col_rep_dark = -1;
		mdc_queue[next].cmd_col_dk_before = -1;
		mdc_queue[next].cmd_col_outfile_type = -1;
		mdc_queue[next].cmd_col_no_transform = -1;
		mdc_queue[next].cmd_col_output_raws = -1;

		/*
		 *	Insert this entry at the end of the list.
		 */
		
		mdc_queue[next].cmd_next = NULL;
		if(mdc_head == NULL)
		    mdc_head = &mdc_queue[next];
		 else
		  {
		    for(qp = mdc_head; qp != NULL; qp = qp->cmd_next)
		      if(qp->cmd_next == NULL)
			{
			  qp->cmd_next = &mdc_queue[next];
			  break;
			}
		  }

	      }

	    switch(i)
	      {
		case MDC_COM_DMOVE:
		case MDC_COM_PMOVE:
		case MDC_COM_PMOVEREL:
		case MDC_COM_DSET:
		case MDC_COM_PSET:
		case MDC_COM_SHUT:
		case MDC_COM_CONFIG:
		case MDC_COM_LMOVE:
		case MDC_COM_LSET:
		case MDC_COM_OMOVE:
		case MDC_COM_OSET:
		case MDC_COM_KMOVE:
		case MDC_COM_KSET:
		case MDC_COM_GONMAN:
		case MDC_COM_HOME:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%f",&mdc_queue[next].cmd_value);
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
		  if(0 == strcmp(tok2,"phi"))
		    mdc_queue[next].cmd_col_axis = 1;
		   else
		    if(0 == strcmp(tok2,"omega"))
		      mdc_queue[next].cmd_col_axis = 0;
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
		case MDC_COL_NDARK:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%d",
			&mdc_queue[next].cmd_col_newdark);
		  break;
		case MDC_COL_ANOM:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%d",
			&mdc_queue[next].cmd_col_anom);
		  break;
		case MDC_COL_WEDGE:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  sscanf(tok2,"%d",
			&mdc_queue[next].cmd_col_wedge);
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
		case MDC_COL_COMPRESS:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  mdc_queue[next].cmd_col_compress = 0;
		  if(0 == strcmp(tok2,".Z"))
		    mdc_queue[next].cmd_col_compress = 1;
		   else
		    if(0 == strcmp(tok2,".pck"))
		      mdc_queue[next].cmd_col_compress = 2;
		  break;
		case MDC_COL_DZRATIO:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  mdc_queue[next].cmd_col_dzratio = -1.0;
		  sscanf(tok2,"%f",&mdc_queue[next].cmd_col_dzratio);
		  break;
		case MDC_COL_DKIVAL:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  mdc_queue[next].cmd_col_dkinterval = -1;
		  sscanf(tok2,"%d",&mdc_queue[next].cmd_col_dkinterval);
		  break;
		case MDC_COL_DKREP:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  mdc_queue[next].cmd_col_rep_dark = -1;
		  sscanf(tok2,"%d",&mdc_queue[next].cmd_col_rep_dark);
		  break;
		case MDC_COL_DKBEF:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  mdc_queue[next].cmd_col_dk_before = -1;
		  sscanf(tok2,"%d",&mdc_queue[next].cmd_col_dk_before);
		  break;
		case MDC_COL_OFILE:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  mdc_queue[next].cmd_col_outfile_type = -1;
		  sscanf(tok2,"%d",&mdc_queue[next].cmd_col_outfile_type);
		  break;
		case MDC_COL_NO_TRANSFORM:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  mdc_queue[next].cmd_col_no_transform = -1;
		  sscanf(tok2,"%d",&mdc_queue[next].cmd_col_no_transform);
		  break;
		case MDC_COL_OUTPUT_RAWS:
		  if(0 == get_token(line,2,tok2))
		    {
		      mdc_queue[next].cmd_err = 1;
		      break;
		    }
		  mdc_queue[next].cmd_col_output_raws = -1;
		  sscanf(tok2,"%d",&mdc_queue[next].cmd_col_output_raws);
		  break;
		case MDC_COL_REMARK:
		  if(0 == get_token(line,2,tok2))
			stringpointer = simplenull;
		    else
			stringpointer = tok2;
		  if(NULL == (mdc_queue[next].cmd_col_remarkv[mdc_queue[next].cmd_col_remarkc] =
				(char *) calloc(strlen(stringpointer) + 1,sizeof (char))))
		    {
			    fprintf(stderr,"ccd_dc: error calloc memory for remark command\n");
			    cleanexit(BAD_STATUS);
		    }
		  strcpy(mdc_queue[next].cmd_col_remarkv[mdc_queue[next].cmd_col_remarkc],stringpointer);
		  mdc_queue[next].cmd_col_remarkc++;
		  break;
		case MDC_COL_BLCMD:
		  if(0 == get_token(line,2,tok2))
			mdc_queue[next].cmd_col_blcmd[0] = '\0';
		    else
			strcpy(mdc_queue[next].cmd_col_blcmd,tok2);
		  break;
	      }
	    if(i == MDC_COM_EOC)
		break;
	  }
  }

/*
 *	This function queues a special initialize
 *	command which is run when the program starts
 *	up.  ccd_heartbeat finds the queue non-empty
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
	mdc_queue[0].cmd_col_newdark = 0;
	mdc_queue[0].cmd_col_anom = 0;
	mdc_queue[0].cmd_col_wedge = 20;
	mdc_queue[0].cmd_col_blcmd[0] = '\0';
	mdc_queue[0].cmd_col_dzratio = -1.0;
	mdc_queue[0].cmd_col_dkinterval = -1;
	mdc_queue[0].cmd_col_rep_dark = -1;
	mdc_queue[0].cmd_col_dk_before = -1;
	mdc_queue[0].cmd_col_outfile_type = -1;
	mdc_queue[0].cmd_col_no_transform = -1;
	mdc_queue[0].cmd_col_output_raws = -1;

	/*
	 *	Insert this entry at the end of the list.
	 */
	
	mdc_queue[0].cmd_next = NULL;
	mdc_head = &mdc_queue[0];
  }
