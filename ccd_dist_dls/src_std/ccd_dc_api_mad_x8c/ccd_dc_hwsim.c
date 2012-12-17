#include	"ccd_dc_ext.h"

/*
 *	Simulate hardware here...
 */

mdc_sim_initial_status()
  {
	stat_dist = 100;
	stat_phi = 0;
	stat_start_phi = 0.;
	stat_osc_width = 1.0;
	stat_n_images = 1;
	stat_n_passes = 1;
	stat_n_ccd_updates = 0;
	stat_time = 30;
	stat_dir[0] = '\0';
	stat_fname[0] = '\0';
	strcpy(stat_scanner_op,"none");
	stat_scanner_msg[0] = '\0';
	strcpy(stat_scanner_control,"idle");
	strcpy(stat_scanner_shutter,"closed");
  }

mdc_print_command(mdccp,fp)
mdc_command	*mdccp;
FILE		*fp;
  {
	fprintf(fp,"%s",mdc_comlit[mdccp->cmd_no]);

	switch(mdccp->cmd_no)
	  {
		case MDC_COM_DMOVE:
		case MDC_COM_PMOVE:
		case MDC_COM_DSET:
		case MDC_COM_PSET:
		    fprintf(fp,"%8.2f",mdccp->cmd_value);
		    break;
		case MDC_COM_SHUT:
		    if(mdccp->cmd_value == 0)
			fprintf(fp,"off");
		      else
			fprintf(fp,"on");
		    break;
	  }
	fprintf(fp,"\n");
	if(mdccp->cmd_no == MDC_COM_COLL)
	  {
		    fprintf(fp,"\tdistance %8.2f\n",mdccp->cmd_col_dist);
		    if(is_lift == 1 && mdccp->cmd_col_lift > -1000.)
		      fprintf(fp,"\tlift %8.2f\n",mdccp->cmd_col_lift);
		    fprintf(fp,"\tphi_start %8.2f\n",mdccp->cmd_col_phis);
		    fprintf(fp,
			"\tosc_width %8.2f\n",mdccp->cmd_col_osc_width);
		    fprintf(fp,"\tn_images %d\n",mdccp->cmd_col_n_images);
		    fprintf(fp,"\tn_passes %d\n",mdccp->cmd_col_n_passes);
		    fprintf(fp,
		      "\timage_number %d\n",mdccp->cmd_col_image_number);
		    fprintf(fp,"\ttime %8.2f\n",mdccp->cmd_col_time);
		    fprintf(fp,"\tdirectory %s\n",mdccp->cmd_col_dir);
		    fprintf(fp,"\timage_prefix %s\n",mdccp->cmd_col_prefix);
		    fprintf(fp,"\timage_suffix %s\n",mdccp->cmd_col_suffix);
		    if(mdccp->cmd_col_mode == 0)
                      fprintf(fp,"\tmode: time\n");
                     else
                      if(mdccp->cmd_col_mode == 1)
                        fprintf(fp,"\tmode: dose\n");
                       else
                        if(mdccp->cmd_col_mode == 2)
                         fprintf(fp,"\tmode: spiral files only, collect by time\n");
                        else
                         if(mdccp->cmd_col_mode == 3)
                          fprintf(fp,"\tmode: spiral file without header: CALIBRATION ONLY.\n");
	  }
	if(mdccp->cmd_no == MDC_COM_SCAN)
	  {
		    fprintf(fp,
		      "\timage_number %d\n",mdccp->cmd_col_image_number);
		    fprintf(fp,"\tdirectory %s\n",mdccp->cmd_col_dir);
		    fprintf(fp,"\timage_prefix %s\n",mdccp->cmd_col_prefix);
		    fprintf(fp,"\timage_suffix %s\n",mdccp->cmd_col_suffix);
	  }
	fflush(fp);
  }

/*
 *	Routine to form a file name.
 */

make_filename(buf,mdccp)
char		*buf;
mdc_command	*mdccp;
  {
	char	num[4];
	int	i;

	i = mdccp->cmd_col_image_number;
	num[0] = '0' + i / 100;
	i = i - 100 * (i / 100);
	num[1] = '0' + i / 10;
	i = i - 10 * (i / 10);
	num[2] = '0' + i;
	num[3] = '\0';
	sprintf(buf,"%s_%s.%s",mdccp->cmd_col_prefix,num,
		mdccp->cmd_col_suffix);
  }
make_filename_double(buf,mdccp,which)
char		*buf;
mdc_command	*mdccp;
int		which;
  {
	char	num[4];
	int	i;

	i = mdccp->cmd_col_image_number;
	num[0] = '0' + i / 100;
	i = i - 100 * (i / 100);
	num[1] = '0' + i / 10;
	i = i - 10 * (i / 10);
	num[2] = '0' + i;
	num[3] = '\0';
	if(which == 0)
	  sprintf(buf,"%sy_%s.%s",mdccp->cmd_col_prefix,num,
		mdccp->cmd_col_suffix);
	 else
	  sprintf(buf,"%sx_%s.%s",mdccp->cmd_col_prefix,num,
		mdccp->cmd_col_suffix);
  }
/*
 *	Routine to form a file name, but without the .blah part
 */

make_fn_leading(buf,mdccp)
char		*buf;
mdc_command	*mdccp;
  {
	char	num[4];
	int	i;

	i = mdccp->cmd_col_image_number;
	num[0] = '0' + i / 100;
	i = i - 100 * (i / 100);
	num[1] = '0' + i / 10;
	i = i - 10 * (i / 10);
	num[2] = '0' + i;
	num[3] = '\0';
	sprintf(buf,"%s_%s",mdccp->cmd_col_prefix,num);
	strcpy(fname_dir,mdccp->cmd_col_dir);
  }

/*
 *	Routine to form a file name, but without the .blah part
 *	Use the prefix "x" always.  This is for MSDOS, primarily.
 *	Otherwise, you get filenames too long.
 */

make_fn_leading_x(buf,mdccp)
char		*buf;
mdc_command	*mdccp;
  {
	char	num[4];
	int	i;

	i = mdccp->cmd_col_image_number;
	num[0] = '0' + i / 100;
	i = i - 100 * (i / 100);
	num[1] = '0' + i / 10;
	i = i - 10 * (i / 10);
	num[2] = '0' + i;
	num[3] = '\0';
	sprintf(buf,"x_%s",num);
	strcpy(fname_dir,mdccp->cmd_col_dir);
  }
make_fn_leading_xy(buf,mdccp,which)
char		*buf;
mdc_command	*mdccp;
int		which;
  {
	char	num[4];
	int	i;

	i = mdccp->cmd_col_image_number;
	num[0] = '0' + i / 100;
	i = i - 100 * (i / 100);
	num[1] = '0' + i / 10;
	i = i - 10 * (i / 10);
	num[2] = '0' + i;
	num[3] = '\0';
	if(which == 1)
	    sprintf(buf,"y_%s",num);
	  else
	    sprintf(buf,"x_%s",num);
	strcpy(fname_dir,mdccp->cmd_col_dir);
  }

make_simfilename(buf,prefix,n)
char		*buf;
char		*prefix;
int		n;
  {
	char	num[4];
	int	i;

	i = n;
	num[0] = '0' + i / 100;
	i = i - 100 * (i / 100);
	num[1] = '0' + i / 10;
	i = i - 10 * (i / 10);
	num[2] = '0' + i;
	num[3] = '\0';
	sprintf(buf,"%s_%s.image",prefix,num);
  }

int	sim_imnumber = 1;

output_simim(mdccp)
mdc_command	*mdccp;
  {
	char	src_fname[20],src_whole[256];
	char	des_fname[20],des_whole[256];
	int	fdin,fdout;
	int	ret;
	char	buffer[1024];

	make_simfilename(src_fname,"heme",sim_imnumber);
	sprintf(src_whole,"%s%s",simdir,src_fname);
	make_filename(des_fname,mdccp);
	sprintf(des_whole,"%s%s",mdccp->cmd_col_dir,des_fname);

	if(-1 == (fdin = open(src_whole,0)))
	  {
	    fprintf(stderr,"output_simim: cannot open %s as src image\n",
		src_whole);
	    return;
	  }
	if(-1 == (fdout = creat(des_whole,0666)))
	  {
	    fprintf(stderr,"output_simim: cannot create %s as output image\n",
		des_whole);
	    return;
	  }
	
	while(1)
	  {
		ret = read(fdin,buffer,1024);
		if(ret == -1)
		  {
		    fprintf(stderr,"output_simim: error reading src image.\n");
		    return;
		  }
		if(ret == 0)
			break;
		if(ret != write(fdout,buffer,ret))
		  {
		    fprintf(stderr,"output_simim: error writing dest image.\n");
		    return;
		  }
	  }
	close(fdin);
	close(fdout);

	sim_imnumber++;
	if(sim_imnumber > 5)
		sim_imnumber = 1;
  }

/*
 *	Dummy routine to "read" the status (from the scanner), as opposed
 *	to outputting the status to disk.
 */

mdc_sim_read_status(arg)
int	arg;
  {
	enqueue_fcn(mdc_sim_read_status,0,1.0);
  }

/*
 *	Routine to start each command.
 */

mdc_sim_start(mdccp)
mdc_command	*mdccp;
  {
	double	fabs();

	strcpy(stat_scanner_control,"active");

	switch(mdccp->cmd_no)
	  {
	    case MDC_COM_INIT:
		tick = 40;
		strcpy(stat_scanner_op,"initializing");
		break;
	    case MDC_COM_ERASE:
		tick = 30;
		strcpy(stat_scanner_op,"erasing");
		break;
	    case MDC_COM_DSET:
		tick = 2;
		strcpy(stat_scanner_op,"setting distance");
		stat_dist = mdccp->cmd_value;
		break;
	    case MDC_COM_PSET:
		tick = 2;
		strcpy(stat_scanner_op,"setting phi");
		stat_phi = mdccp->cmd_value;
		break;
	    case MDC_COM_SHUT:
		tick = 2;
		strcpy(stat_scanner_op,"Shutter control");
		if(mdccp->cmd_value != 0)
			strcpy(stat_scanner_shutter,"open");
		    else
			strcpy(stat_scanner_shutter,"closed");
		break;
	    case MDC_COM_SCAN:
		tick = 40;
		strcpy(stat_scanner_op,"scanning");
		break;
	    case MDC_COM_DMOVE:
		delta = mdccp->cmd_value - stat_dist;
		tick = 2 + fabs(delta) / 20;
		start_val = stat_dist;
		units = tick - 2;
		if(delta < 0)
			msign = 1;
		    else
			msign = -1;
		strcpy(stat_scanner_op,"moving distance");
		break;
	    case MDC_COM_PMOVE:
		delta = mdccp->cmd_value - stat_phi;
		tick = 2 + fabs(delta) / 20;
		start_val = stat_phi;
		units = tick - 2;
		if(delta < 0)
			msign = 1;
		    else
			msign = -1;
		strcpy(stat_scanner_op,"moving phi");
		break;
	    case MDC_COM_COLL:
		strcpy(stat_scanner_op,"exposing");
		strcpy(stat_scanner_shutter,"open");
		tick = 2 + mdccp->cmd_col_time;
		units = tick - 2;
		stat_dist = mdccp->cmd_col_dist;
		stat_time = mdccp->cmd_col_time;
		stat_phi = mdccp->cmd_col_phis;
		stat_start_phi = stat_phi;
		stat_osc_width = mdccp->cmd_col_osc_width;
		stat_n_images = mdccp->cmd_col_n_images;
		stat_n_passes = mdccp->cmd_col_n_passes;
		strcpy(stat_dir,mdccp->cmd_col_dir);
		make_filename(stat_fname,mdccp);
		dcop = 0;
		totimg = stat_n_images;
		dc_abort = 0;
		dc_stop = 0;
		break;
	  }
  }

/*
 *	Routine to determine the progress of a command.  This is
 *	called every heartbeat.  Returns 1 when the command is finished,
 *	otherwise 0.
 */

mdc_sim_progress(mdccp)
mdc_command	*mdccp;
  {
	int	done;
	int	pdone;
	double	x;

	done = 0;

	switch(mdccp->cmd_no)
	  {
	    case MDC_COM_INIT:
		tick--;
		if(tick == 0) done = 1;
		break;
	    case MDC_COM_STARTUP:
		done = 1;
		break;
	    case MDC_COM_ERASE:
		tick--;
		pdone = 100 * ((30 - tick) / 30.);
		if(tick == 0)
			done = 1;
		    else
			sprintf(stat_scanner_msg,"erase %3d%% complete",pdone);
		break;
	    case MDC_COM_SCAN:
		tick--;
		pdone = 100 * ((40 - tick) / 40.);
		if(tick == 0)
			done = 1;
		    else
			sprintf(stat_scanner_msg,"scan %3d%% complete",pdone);
		break;
	    case MDC_COM_DSET:
	    case MDC_COM_PSET:
	    case MDC_COM_SHUT:
		tick--;
		if(tick == 0) done = 1;
		break;
	    case MDC_COM_DMOVE:
		tick--;
		x = start_val +  delta * (units - (tick - 2)) /
					((double) units);
		if(tick > 1)
			stat_dist = x;
		if(tick == 0) done = 1;
		break;
	    case MDC_COM_PMOVE:
		tick--;
		x = start_val +  delta * (units - (tick - 2)) /
					((double) units);
		if(tick > 1)
			stat_phi = x;
		if(tick == 0) done = 1;
		break;
	    case MDC_COM_COLL:
		if(dc_abort)
		  {
			done = 1;
			dc_abort = 0;
			strcpy(stat_scanner_shutter,"closed");
			break;
		  }
		tick--;
		switch(dcop)
		  {
		    case 0:
			if(tick > 1)
			  {
			    stat_phi += (1./units) * stat_osc_width;
			    pdone = 100 * 
				(units - (tick - 2)) / ((double) units);
			    sprintf(stat_scanner_msg,
			      "exposure %3d%% complete",pdone);
			  }
			if(tick == 0)
			  {
			    dcop = 1;

			    output_simim(mdccp);

			    strcpy(stat_scanner_op,"scanning");
			    strcpy(stat_scanner_shutter,"closed");
			    tick = 40;
			  }
			break;
		    case 1:
			pdone = 100 * (40 - tick) / 40.;
			sprintf(stat_scanner_msg,
				"scan %3d%% complete",pdone);
			if(tick == 0)
			  {
				dcop = 2;
				tick = 30;
				strcpy(stat_scanner_op,"erasing");
			  }
			break;
		    case 2:
			pdone = 100 * (30 - tick) / 30.;
			sprintf(stat_scanner_msg,
				"erase %3d%% complete",pdone);
			if(tick == 0)
			  {
			    totimg--;
			    if(totimg == 0 || dc_stop == 1)
			      {
				done = 1;
				dc_stop = 0;
				break;
			      }
			    mdccp->cmd_col_image_number++;
			    make_filename(stat_fname,mdccp);
			    dcop = 0;
			    tick = 2 + mdccp->cmd_col_time;
			  }
			break;
		      }
		break;
	  }
	if(done == 1)
	  {
		strcpy(stat_scanner_msg,"");
		strcpy(stat_scanner_op,"");
		strcpy(stat_scanner_control,"idle");
	  }
	return (done);
  }
