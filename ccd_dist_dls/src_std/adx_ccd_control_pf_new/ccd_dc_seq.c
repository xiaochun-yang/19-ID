#include <stdio.h>
#include "ccd_dc_ext.h"
#include <Xm/Xm.h>
#include "adx.h"

/*
 *	generate_run_list(mdccp)
 *
 *	generate a list of frames in the proper directory for the
 *	run pointed to by mdccp.  The run may involve any of the
 *	MAD modes.  This file is then used to actually sequence
 *	the data collection.
 */


init_run_list()
{
	int i;
	mdc_command	mdccp;

#ifdef JUNK  /* MDC_COMMAND_STRUCTURE */

		/* These are not used in sequencing
		 */

		int	cmd_used;	/* 0 if this queue entry unused */
		struct mdc_command *cmd_next;	/* next command in queue */
		int	cmd_no;		/* the command number/this command */
		int	cmd_err;	/* 1 if there is an error */
		float	cmd_value;	/* a value field, if appropriate */
		float	cmd_col_dist;	/* distance for data collection */
		float	cmd_col_lift;	/* lift value for data collection */
		int	cmd_col_newdark;    /* 1 for a new dark current image, else 0 */
		int	cmd_col_n_passes;   /* number of osc passes/image */
		int	cmd_col_mode;	    /* 0 = collect time, 1 dose */
		int	cmd_col_adc;	    /* adc select */
		int	cmd_col_bin;	    /* bin select */
		float	cmd_col_xcen;	    /* x detector center in mm for oblique correction */
		float	cmd_col_ycen;	    /* y detector center in mm for oblique correction */
		int	cmd_col_compress;   /* 0 for none, 1 for .Z, 2 for .pck */
		float	cmd_col_dzratio;    /* ratio of 2nd picture expos time to 1st */
		int	cmd_col_dkinterval; /* interval between darks */
		int	cmd_col_rep_dark;   /* 1 to repeat darks every darkinterval seconds */
		int	cmd_col_dk_before;  /* 1 to repeat darks before each run */
		int	cmd_col_outfile_type;	/* 0 for 16 bit, 1 for 32 bit, 2 for 16 + overflow records */
		int	cmd_col_no_transform;	/* 1 to not transform data */
		int	cmd_col_output_raws;	/* 1 to output raws */
		float	cmd_col_step_size;	/* size of step for step/dose mode */
		float	cmd_col_dose_step;	/* dose per step, step/dose mode */
		float	cmd_col_do_wavelength;	/* used after runs are expanded in the queue */
		int	cmd_col_remarkc;    	/* number of remark records */
		int	cmd_col_restart_image;		/* image number for restart */
		char	*cmd_col_remarkv[MAXREMARK];  /* pointers to remarks */
		char	cmd_col_blcmd[BLCMDMAX];
		char	cmd_col_dir[132];   /* directory for output images */
		char	cmd_col_suffix[30]; /* image name suffix */


		/* These are used in sequencing
		 */

		float	cmd_col_phis;	/* phi start for data collection */
		float	cmd_col_omegas;	/* omega start for data collection */
		float	cmd_col_kappas;	/* kappa start for data collection */
		float	cmd_col_osc_width;  /* oscillation width/image */
		int	cmd_col_axis;	/* 1 for phi, 0 for omega */
		int	cmd_col_anom;	    /* 1 for anomalous data */
		int	cmd_col_wedge;	    /* wedge (#frames per batch) size for anom data */
		int	cmd_col_n_images;   /* number of images to collect */
		float	cmd_col_time;	    /* data collection time/image */
		int	cmd_col_image_number; /* start image number */
		char	cmd_col_prefix[30]; /* image name prefix */
		int	cmd_col_mad_mode;	/* 0 never, 1 per run, 2 per wedge, 3 per nframes */
		int	cmd_col_mad_nframes;	/* for mode = 3, number of frames between wavelength changes */
		int	cmd_col_mad_nwave;	/* number of wavelengths */
		float	cmd_col_mad_wavelengths[10];	/* wavelengths */
		int	cmd_col_restart_run;		/* run number for restart */

#endif /* MDC_COMMAND_STRUCTURE */

	mdccp.cmd_col_phis = 0.0;	/* arbitrary for file name generation */
	mdccp.cmd_col_omegas = 0.0;	/* arbitrary for file name generation */
	mdccp.cmd_col_kappas = 0.0;	/* arbitrary for file name generation */
	mdccp.cmd_col_osc_width = 1.0;	/* arbitrary for file name generation */
	mdccp.cmd_col_axis = 1;		/* arbitrary for file name generation */
	mdccp.cmd_col_time = 10;	/* arbitrary for file name generation */
	strcpy(mdccp.cmd_col_prefix,"test_");	/* arbitrary */

#ifdef TEST
	/* Testing */
	mdccp.cmd_col_anom =  0; 	/* Anomalous */
	mdccp.cmd_col_wedge = 5;
	mdccp.cmd_col_n_images = 100;
	mdccp.cmd_col_image_number = 7;
	mdccp.cmd_col_restart_run = 1; 	/* Run Number */
	mdccp.cmd_col_mad_mode = 1;	/* Per run */
	mdccp.cmd_col_mad_nframes = 10;
	mdccp.cmd_col_mad_nwave = 2;
	mdccp.cmd_col_mad_wavelengths[0] = 1.08;
	mdccp.cmd_col_mad_wavelengths[1] = 1.54;

	total_images = 0;
	generate_run_list(&mdccp);

#endif /* TEST */


	total_images = 0;
	mdccp.cmd_col_anom =  Collect.anomalous;
	mdccp.cmd_col_wedge = Collect.wedge;
	mdccp.cmd_col_mad_mode = Collect.mad_mode;
	mdccp.cmd_col_mad_nframes = Collect.mad_nframes;
	mdccp.cmd_col_mad_nwave = Collect.mad_nwave;
	for(i=0;i<mdccp.cmd_col_mad_nwave;i++)
		mdccp.cmd_col_mad_wavelengths[i] = Collect.mad_wavelengths[i];

	for(i=0; i <= MAX_RUNS; i++) {
		if (Run[i].nframes > 0) {
			mdccp.cmd_col_n_images = Run[i].nframes;
			mdccp.cmd_col_restart_run = Run[i].number;
			mdccp.cmd_col_image_number = Run[i].start;
			generate_run_list(&mdccp);
		}
	}
}

static	int	run_start;
static	int	run_end;

static	int	run_anom;	/* 0 no anom, 1 anom */

static	int	anom_wedge;	/* number of frames per anom wedge */

static	int	batch_ctr;
static	int	wave_ctr;
static	int	frame_ctr;
static	int	eff_runno;
static	int	eff_start;
static	int	eff_end;
static	int	wedge_side;
static	float	eff_wave;

static	int	img_ctr;
static	int	img_max;

static	float	img_time;
static FILE	*fpl;


/*
 *------------------------------------------------------------
 */

seq_wave_ival(mdccp)
mdc_command	*mdccp;
{
	char	lit_fname[4],file_name[256];
	int	i,wedge_dec;

	/*fprintf(stdout,"seq_wave_ival: eff_start: %d eff_end: %d\n",eff_start,eff_end);*/
	wedge_dec = 0;

	for(frame_ctr = eff_start; frame_ctr <= eff_end;)
	  {
	    wedge_dec++;
	    img_max = 1;

	    for(img_ctr = 0; img_ctr < img_max; img_ctr++)
	      {
		img_time = mdccp->cmd_col_time;

		parse_file_name(mdccp->cmd_col_prefix,file_name,&i);
	        strcat(file_name,"_");
	        sprintf(lit_fname,"%d",eff_runno);
	        strcat(file_name,lit_fname);
	        strcat(file_name,"_");
	        util_3digit(lit_fname,frame_ctr);
	        strcat(file_name,lit_fname);
		if (debug)
	        	fprintf(fpl,"%s %7.3f %7.5f OK Run: %d Frame: %d\n",file_name,img_time,eff_wave,eff_runno,frame_ctr);

		if (total_images >= M_RUNS * MAX_FRAMES)
			return;
		run_list[total_images].run_no = eff_runno;
		run_list[total_images].frame_no = frame_ctr;
		total_images++;

		/*
		 *	Move the angle forward 1 width amount.  This would occur in the beamline
		 *	process.  Pretend it's not here.
		 */
	      }
	    if(run_anom) {
		if(((anom_wedge - 1) == (frame_ctr - run_start) % anom_wedge) || (frame_ctr == run_end)) {
		    if(wedge_side) {
			wedge_side = 0;
			wedge_dec = 0;
			eff_runno -= 100;

			/*
			 *	Increment BOTH sets of primary and friedel wedge angle
			 *	starts whenever the transition from friedel ---> primary is made.
			 */

		      } else {
			wedge_side = 1;
			eff_runno += 100;
/*  WAS:
 *			frame_ctr -= frame_ctr - ((frame_ctr - mdccp->cmd_col_image_number) / anom_wedge) * anom_wedge;
 */
 			frame_ctr -= wedge_dec;
		      }
		  }
	      }
	    frame_ctr++;
	  }
}


do_wave_wedge(mdccp,eff_wedge)
struct	mdc_command	*mdccp;
int	eff_wedge;
{
	int	nbatches;

	wave_ctr = 0;
	eff_runno = mdccp->cmd_col_restart_run + 2 * 100 * wave_ctr;
	eff_start = run_start;
	eff_wave = mdccp->cmd_col_mad_wavelengths[wave_ctr];
	wedge_side = 0;

	/*fprintf(stdout,"do_wave_wedge: eff_runno: %d with restart_run: %d\n",eff_runno,mdccp->cmd_col_restart_run);*/

	if(eff_start + eff_wedge < run_end)
		eff_end = eff_start + eff_wedge - 1;
	  else
		eff_end = run_end;

	nbatches = 1 + (mdccp->cmd_col_n_images - 1) / eff_wedge;

	/*fprintf(stdout,"do_wave_wedge: nbatches: %d\n",nbatches);*/
	/*fprintf(stdout,"do_wave_wedge: nwave: %d\n",mdccp->cmd_col_mad_nwave);*/

	for(batch_ctr = 0; batch_ctr < nbatches; batch_ctr++)
	  {
	  	if (mdccp->cmd_col_mad_nwave < 1) {
		    wedge_side = 0;
		    eff_runno = mdccp->cmd_col_restart_run;
		    eff_wave = Collect.wavelength;
		    seq_wave_ival(mdccp);
		}
		else {
	        for(; wave_ctr < mdccp->cmd_col_mad_nwave; wave_ctr++)
	          {
		    wedge_side = 0;
		    eff_runno = mdccp->cmd_col_restart_run + 2 * 100 * wave_ctr;
		    eff_wave = mdccp->cmd_col_mad_wavelengths[wave_ctr];
		    seq_wave_ival(mdccp);
	          }
		}
		eff_start += eff_wedge;
		if(eff_start + eff_wedge <  run_end)
			eff_end = eff_start + eff_wedge - 1;
		    else
			eff_end =  run_end;
		wave_ctr = 0;
	 }
}

generate_run_list(mdccp)
mdc_command	*mdccp;
{
	int	eff_wedge;
	char	fname[256];

	if (debug) {
		sprintf(fname,"%s.runlist",mdccp->cmd_col_prefix);
		if(NULL == (fpl = fopen(fname,"a")))
	  	{
	    	fprintf(stderr,"ccd_dc_api: generate_run_list: Cannot create %s as run list\n",fname);
	    	return;
	  	}
	}
	
	run_start = mdccp->cmd_col_image_number;
	run_end   = run_start + mdccp->cmd_col_n_images - 1;
	run_anom  = mdccp->cmd_col_anom;

	switch(mdccp->cmd_col_mad_mode)
	  {
	    case 0:
		eff_wedge = 100000;
		if(mdccp->cmd_col_anom == 0)
			anom_wedge = 100000;
		  else
			anom_wedge = mdccp->cmd_col_wedge;
		do_wave_wedge(mdccp,eff_wedge);
		break;
	    case 1:
		eff_wedge = 100000;
		if(mdccp->cmd_col_anom == 0)
			anom_wedge = 100000;
		  else
			anom_wedge = mdccp->cmd_col_wedge;
		do_wave_wedge(mdccp,eff_wedge);
		break;
	    case 2:
		eff_wedge = mdccp->cmd_col_wedge;
		anom_wedge = mdccp->cmd_col_wedge;
		do_wave_wedge(mdccp,eff_wedge);
		break;
	    case 3:
		eff_wedge = mdccp->cmd_col_mad_nframes;
		anom_wedge = eff_wedge;
		do_wave_wedge(mdccp,eff_wedge);
		break;
	  }
	if (debug)
		fclose(fpl);
}

util_3digit(s1,val)
char	*s1;
int	val;
{
	int	i,j;

	i = val;
	j = i / 100;
	*s1++ = (char ) ('0' + j);
	i = i - 100 * j;
	j = i / 10;
	*s1++ = (char ) ('0' + j);
	i = i - 10 * j;
	*s1++ = (char ) ('0' + i);
	*s1++ = '\0';
}

parse_file_name(s,t,inp)
char    *s,*t;
int     *inp;
{
        int     i,j;

        j = strlen(s);
        for(i = j - 1; i > 0 && s[i] != '_'; i--);
	/*fprintf(stdout,"j: %d and i: %d after loop\n",j,i);*/
        *inp = atoi(&s[i + 1]);
        for(j = 0; j < i; j++)
          t[j] = s[j];
        t[i] = '\0';
}
