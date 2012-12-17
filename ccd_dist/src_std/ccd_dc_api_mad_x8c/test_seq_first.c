#include	<stdio.h>

/*
 *	Program to explore the complexity and issues involved
 *	in MAD sequencing of data collection.  Do this before
 *	implimenting this in ccd_dc_hw.c
 */

#define	N_RUNS	10
#define	N_WAVE	5


int	run_nruns;
char	*run_dir;
char	*run_name;
int	run_runno[N_RUNS];
int	run_times[N_RUNS];
int	run_start[N_RUNS];
int	run_end[N_RUNS];

int	wave_nwave;
float	wave_values[N_WAVE];

int	wave_mode;	/* 0 never, 1 each run, 2 each anom wedge, 3 every n frames */
int	run_anom;	/* 0 no anom, 1 anom */

int	anom_wedge;	/* number of frames per anom wedge */
int	wave_nframes;	/* number of frames between wavelength changes */

int	dz_mode;	/* 0 no dezingering, 1 for regular dezingering, 1 variable time dezingering */
int	dz_nd;		/* number of images going into dark image dezingering */
int	dz_nx;		/* number of images going into xray image dezingering */
float	dz_dzratio;	/* ratio of 1st / second image time */

int	dk_before_run;	/* 1 do a dark current before each run */
int	dk_everytsec;	/* do a dark every "t" seconds, -1 to ignore */

int	restart_run = -1;	/* run restart number */
int	restart_frame = -1;	/* frame restart number */

setup_runs()
  {
	run_nruns = 2;

	run_runno[0] = 1;
	run_times[0] = 30;
	run_start[0] = 1;
	run_end[0] = 20;

	run_runno[1] = 2;
	run_times[1] = 15;
	run_start[1] = 1;
	run_end[1] = 3;

	wave_nwave = 2;
	wave_values[0] = 1.5418;
	wave_values[1] = 1.7390;

	wave_mode = 1;
	run_anom = 1;

	anom_wedge = 5;
	wave_nframes = 10;

	dz_mode = 1;
	dz_nd = 2;
	dz_nx = 2;
	dz_dzratio = 1.0;

	dk_before_run = 1;
	dk_everytsec = -1;

	run_dir = ".";
	run_name = "seq";

	restart_run = -1;
	restart_frame = -1;
  }

int	batch_ctr;
int	wave_ctr;
int	run_ctr;
int	frame_ctr;
int	wedge_ctr;
int	doing_dark;
int	did_dark = 0;
int	eff_runno;
int	eff_start;
int	eff_wedge;
int	eff_end;
int	wedge_side;
float	eff_wave;

int	img_ctr;
int	img_max;

float	img_time;

seq_wave_normal()
  {
	char	lit_fname[4],file_name[256];

	for(frame_ctr = eff_start; frame_ctr <= run_end[run_ctr];)
	  {
	    if(doing_dark) {
	      img_max = dz_nd;
	      if(dz_mode == 2)
	          img_max *= 2;
	     }
	    else
	      img_max = dz_nx;

	    for(img_ctr = 0; img_ctr < img_max; img_ctr++)
	      {
		if(dz_mode == 2) {
		    if(img_ctr >= img_max / 2)
		      img_time = run_times[run_ctr] * dz_dzratio;
		     else
		      img_time = run_times[run_ctr];
		  }
		 else
		    img_time = run_times[run_ctr];

	        strcpy(file_name,run_dir);
	        strcat(file_name,"/");
	        strcat(file_name,run_name);
	        strcat(file_name,"_");
	        sprintf(lit_fname,"%d",eff_runno);
	        strcat(file_name,lit_fname);
	        strcat(file_name,"_");
	        util_3digit(lit_fname,frame_ctr);
	        strcat(file_name,lit_fname);
	        if(doing_dark)
			strcat(file_name,".dkx_");
	         else
			strcat(file_name,".imx_");
	        sprintf(lit_fname,"%d",img_ctr);
	        strcat(file_name,lit_fname);
	        fprintf(stdout,"File: %s t: %6.2f wave: %6.4f\n",file_name,img_time,eff_wave);
	      }
	    if(doing_dark == 0 && run_anom) {
		if(((anom_wedge - 1) == (frame_ctr - run_start[run_ctr]) % anom_wedge) || (frame_ctr == run_end[run_ctr])) {
		    if(wedge_side) {
			wedge_side = 0;
			eff_runno -= 100;
		      } else {
			wedge_side = 1;
			eff_runno += 100;
			frame_ctr -= frame_ctr - ((frame_ctr - run_start[run_ctr]) / anom_wedge) * anom_wedge;
		      }
		  }
	      }
	    if(doing_dark == 0)
		frame_ctr++;
	      else
		{
		  doing_dark = 0;
		  did_dark = 1;
		}
	  }
  }

seq_wave_ival()
  {
	char	lit_fname[4],file_name[256];

	for(frame_ctr = eff_start; frame_ctr <= eff_end;)
	  {
	    if(doing_dark) {
	      img_max = dz_nd;
	      if(dz_mode == 2)
	          img_max *= 2;
	     }
	    else
	      img_max = dz_nx;

	    for(img_ctr = 0; img_ctr < img_max; img_ctr++)
	      {
		if(dz_mode == 2) {
		    if(img_ctr >= img_max / 2)
		      img_time = run_times[run_ctr] * dz_dzratio;
		     else
		      img_time = run_times[run_ctr];
		  }
		 else
		    img_time = run_times[run_ctr];

	        strcpy(file_name,run_dir);
	        strcat(file_name,"/");
	        strcat(file_name,run_name);
	        strcat(file_name,"_");
	        sprintf(lit_fname,"%d",eff_runno);
	        strcat(file_name,lit_fname);
	        strcat(file_name,"_");
	        util_3digit(lit_fname,frame_ctr);
	        strcat(file_name,lit_fname);
	        if(doing_dark)
			strcat(file_name,".dkx_");
	         else
			strcat(file_name,".imx_");
	        sprintf(lit_fname,"%d",img_ctr);
	        strcat(file_name,lit_fname);
	        fprintf(stdout,"File: %s t: %6.2f wave: %6.4f\n",file_name,img_time,eff_wave);
	      }
	    if(doing_dark == 0 && run_anom) {
		if(((anom_wedge - 1) == (frame_ctr - run_start[run_ctr]) % anom_wedge) || (frame_ctr == run_end[run_ctr])) {
		    if(wedge_side) {
			wedge_side = 0;
			eff_runno -= 100;
		      } else {
			wedge_side = 1;
			eff_runno += 100;
			frame_ctr -= frame_ctr - ((frame_ctr - run_start[run_ctr]) / anom_wedge) * anom_wedge;
		      }
		  }
	      }
	    if(doing_dark == 0)
		frame_ctr++;
	      else
		{
		  doing_dark = 0;
		  did_dark = 1;
		}
	  }
  }

do_run_wave_normal()
  {
	for(run_ctr = 0; run_ctr < run_nruns; run_ctr++)
	  {
		doing_dark = 0;
		if(dk_before_run == 0 && did_dark == 0)
			doing_dark = 1;
		if(dk_before_run == 1)
			doing_dark = 1;

		wedge_side = 0;
		eff_runno = run_runno[run_ctr];
		eff_start = run_start[run_ctr];
		eff_wave = wave_values[0];
		if(restart_run != -1) {
		    eff_runno = restart_run;
		    eff_start = restart_frame;
		    if(run_runno[run_ctr] == restart_run)
			wedge_side = 0;
		      else 
			wedge_side = 1;
		    restart_run = -1;
		    restart_frame = -1;
		  }

		seq_wave_normal();
	  }
  }

do_wave_erun()
  {
	for(run_ctr = 0; run_ctr < run_nruns; run_ctr++)
	  {
	    doing_dark = 0;
	    if(dk_before_run == 0 && did_dark == 0)
		doing_dark = 1;
	    if(dk_before_run == 1)
		doing_dark = 1;

	    if(restart_run != -1) {
		wave_ctr = restart_run / 200;
		eff_wave = wave_values[wave_ctr];
		wedge_side = (restart_run / 100) % 2;
		eff_runno = restart_run;
		eff_start = restart_frame;
	      }
	     else
		wave_ctr = 0;

	    eff_end = run_end[run_ctr];

	    for(; wave_ctr < wave_nwave; wave_ctr++)
	      {
		if(restart_run == -1) {
		    wedge_side = 0;
		    eff_runno = run_runno[run_ctr] + 2 * 100 * wave_ctr;
		    eff_start = run_start[run_ctr];
		    eff_wave = wave_values[wave_ctr];
		  } else {
		      restart_run = -1;
		      restart_frame = -1;
		    }

		seq_wave_ival();
	      }
	  }
  }

do_wave_wedge()
  {
	int	nbatches;

	for(run_ctr = 0; run_ctr < run_nruns; run_ctr++)
	  {
	    doing_dark = 0;
	    if(dk_before_run == 0 && did_dark == 0)
		doing_dark = 1;
	    if(dk_before_run == 1)
		doing_dark = 1;

	    if(restart_run != -1) {
		wave_ctr = restart_run / 200;
		eff_wave = wave_values[wave_ctr];
		wedge_side = (restart_run / 100) % 2;
		eff_runno = restart_run;
		eff_start = restart_frame;
	      }
	     else {
		wave_ctr = 0;
		eff_runno = run_runno[run_ctr] + 2 * 100 * wave_ctr;
		eff_start = run_start[run_ctr];
		eff_wave = wave_values[wave_ctr];
		wedge_side = 0;
	      }
	    if(eff_start + eff_wedge < run_end[run_ctr])
		eff_end = eff_start + eff_wedge - 1;
	    else
		eff_end = run_end[run_ctr];

	    nbatches = 1 + (run_end[run_ctr] - eff_start) / eff_wedge;

	    for(batch_ctr = 0; batch_ctr < nbatches; batch_ctr++)
	      {
	        for(; wave_ctr < wave_nwave; wave_ctr++)
	          {
		    if(restart_run == -1) {
		      wedge_side = 0;
		      eff_runno = run_runno[run_ctr] + 2 * 100 * wave_ctr;
		      eff_wave = wave_values[wave_ctr];
		    } else {
		        restart_run = -1;
		        restart_frame = -1;
		      }

		    seq_wave_ival();
	          }
		eff_start += eff_wedge;
		if(eff_start + eff_wedge < run_end[run_ctr])
			eff_end = eff_start + eff_wedge - 1;
		    else
			eff_end = run_end[run_ctr];
		wave_ctr = 0;
	      }
	  }
  }

main(argc,argv)
int	argc;
char	*argv[];
  {
	setup_runs();

	switch(wave_mode)
	  {
	    case 0:
		eff_wedge = 100000;
		do_wave_wedge();
		break;
	    case 1:
		eff_wedge = 100000;
		do_wave_wedge();
		break;
	    case 2:
		eff_wedge = anom_wedge;
		do_wave_wedge();
		break;
	    case 3:
		eff_wedge = wave_nframes;
		do_wave_wedge();
		break;
	  }
	exit(0);
  }
