#include	"ccd_dc_ext.h"

/*
 *	generate_run_list(mdccp)
 *
 *	generate a list of frames in the proper directory for the
 *	run pointed to by mdccp.  The run may involve any of the
 *	MAD modes.  This file is then used to actually sequence
 *	the data collection.
 */


static	int	run_start;
static	int	run_end;

static	int	run_anom;	/* 0 no anom, 1 anom */

static	int	anom_wedge;	/* number of frames per anom wedge */

static	int	eff_axis;
static	float	eff_width;

static	float	cur_omega;
static	float	cur_phi;
static	float	cur_kappa;

static	int	batch_ctr;
static	int	wave_ctr;
static	int	run_ctr;
static	int	frame_ctr;
static	int	wedge_ctr;
static	int	doing_dark;
static	int	did_dark = 0;
static	int	eff_runno;
static	int	eff_start;
static	int	eff_end;
static	int	wedge_side;
static	float	eff_wave;
static	int	eff_first;

static	int	img_ctr;
static	int	img_max;

static	float	img_time;
static	float	cur_omega;
static	float	cur_phi;
static	float	cur_kappa;

static	float	p_wedge_omega;
static	float	p_wedge_phi;
static	float	p_wedge_kappa;

static	float	f_wedge_omega;
static	float	f_wedge_phi;
static	float	f_wedge_kappa;

static FILE	*fpl;


/*
 *------------------------------------------------------------
 */

seq_wave_ival(mdccp)
mdc_command	*mdccp;
  {
	char	lit_fname[4],file_name[256];
	int	i,wedge_dec;
	double	out_ang;

	fprintf(stdout,"seq_wave_ival: INFO:          eff_start: %d eff_end: %d\n",eff_start,eff_end);
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
	        fprintf(fpl,"%s %7.3f %7.5f ",file_name,img_time,eff_wave);
		if(doing_dark == 0) {
		    if(eff_axis == 1)
		    {
			out_ang = cur_phi;
			if(out_ang >= constrain_phi)
				out_ang -= 360;
			if(out_ang < (constrain_phi - 360))
				out_ang += 360;

			fprintf(fpl,"%9.3f %9.3f %9.3f\n", cur_omega, out_ang, cur_kappa);
		    }
		    else
		    {
			out_ang = cur_omega;
			if(out_ang >= constrain_omega)
				out_ang -= 360;
			if(out_ang < (constrain_omega - 360))
				out_ang += 360;
			fprintf(fpl,"%9.3f %9.3f %9.3f\n",out_ang,cur_phi,cur_kappa);
		    }
		  }
		 else
			fprintf(fpl,"\n");

		/*
		 *	Move the angle forward 1 width amount.  This would occur in the beamline
		 *	process.  Pretend it's not here.
		 */

		  if(eff_axis == 1) {
		    cur_phi += eff_width;
		    if(cur_phi >= 360)
			cur_phi -= 360;
		  }
		 else {
		    cur_omega += eff_width;
		    if(cur_omega >= 360)
			cur_omega -= 360;
		  }

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

			if(eff_axis == 1) {
				p_wedge_phi   += anom_wedge * eff_width;
				f_wedge_phi   += anom_wedge * eff_width;
			  }
			 else {
				p_wedge_omega += anom_wedge * eff_width;
				f_wedge_omega += anom_wedge * eff_width;
			      }

			cur_omega = p_wedge_omega;
			cur_phi   = p_wedge_phi;
			cur_kappa = p_wedge_kappa;
		      } else {
			wedge_side = 1;
			eff_runno += 100;
/*  WAS:
 *			frame_ctr -= frame_ctr - ((frame_ctr - mdccp->cmd_col_image_number) / anom_wedge) * anom_wedge;
 */
 			frame_ctr -= wedge_dec;
			cur_omega = f_wedge_omega;
			cur_phi   = f_wedge_phi;
			cur_kappa = f_wedge_kappa;
		      }
		  }
	      }
	    frame_ctr++;
	  }
  }

initialize_angles(mdccp)
mdc_command	*mdccp;
  {
	float	euler_angs[3],kappa_angs[3];

	/*
	 *	Angles.
	 */
	fprintf(stdout,"init_angles  : INFO:          eff_start: %d with eff_first: %d\n",eff_start,eff_first);

	if(mdccp->cmd_col_axis == 1) {

	/*
	 *	Takes into account a kappa gonio rotating phi, but wanting to set either
	 *	omega or kappa non-zero for the run.
	 */

	if(is_omega)
	{
		p_wedge_omega = mdccp->cmd_col_omegas;
		f_wedge_omega = p_wedge_omega;
	}
	else
	{
		p_wedge_omega = 0;
		f_wedge_omega = 0;
	}
	cur_omega = p_wedge_omega;

	if(is_kappa)
	{
		p_wedge_kappa = mdccp->cmd_col_kappas;
		f_wedge_kappa = p_wedge_kappa;
	}
	else
	{
		p_wedge_kappa = 0;
		f_wedge_kappa = 0;
	}
	cur_kappa = p_wedge_kappa;

	p_wedge_phi = mdccp->cmd_col_phis + (((eff_start - eff_first) / anom_wedge) * anom_wedge) * mdccp->cmd_col_osc_width;
	f_wedge_phi = p_wedge_phi + 180;
	if(p_wedge_phi >= 360)
		p_wedge_phi -= 360;
	if(f_wedge_phi >= 360)
		f_wedge_phi -= 360;

	if(wedge_side)
		cur_phi = f_wedge_phi;
	  else
		cur_phi = p_wedge_phi;

	cur_phi += (eff_start - eff_first -  (anom_wedge * ((eff_start - eff_first) / anom_wedge))) * mdccp->cmd_col_osc_width;
	if(cur_phi >= 360)
		cur_phi -= 360;
	  }
	 else {
	    p_wedge_omega = mdccp->cmd_col_omegas + (((eff_start - eff_first) / anom_wedge) * anom_wedge) * mdccp->cmd_col_osc_width;
	    p_wedge_phi = mdccp->cmd_col_phis;
	    p_wedge_kappa = mdccp->cmd_col_kappas;

	    if(p_wedge_omega >= 360)
	    	p_wedge_omega -= 360.;

	    cur_omega = p_wedge_omega;
	    cur_phi   = p_wedge_phi;
	    cur_kappa = p_wedge_kappa;

	    if(is_kappa)
	    {
		kappa_angs[0] = p_wedge_omega;
		kappa_angs[1] = p_wedge_phi;
		kappa_angs[2] = p_wedge_kappa;
		ktoe(kappa_angs, euler_angs);
		euler_angs[1] += 180.;
		euler_angs[2] = - euler_angs[2];
		etok(euler_angs, kappa_angs);
		f_wedge_omega = kappa_angs[0];
		f_wedge_phi   = kappa_angs[1];
		f_wedge_kappa = kappa_angs[2];
	    }
	    else
	    {
		f_wedge_omega = p_wedge_omega + 180.;
		f_wedge_phi   = p_wedge_phi;
		f_wedge_kappa = p_wedge_kappa;
		if(f_wedge_omega >= 360)
			f_wedge_omega -= 360.;
	    }

	    if(wedge_side == 1) {
	        cur_omega = f_wedge_omega;
	        cur_phi   = f_wedge_phi;
	        cur_kappa = f_wedge_kappa;
	      }
	    // cur_omega += (eff_start - eff_first -  (anom_wedge * ((eff_start - 1) / anom_wedge))) * mdccp->cmd_col_osc_width;
	    if(cur_omega >= 360)
	    	cur_omega -= 360;
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

	fprintf(stdout,"do_wave_wedge: INFO:          eff_runno: %d with restart_run: %d\n",
			eff_runno,mdccp->cmd_col_restart_run);
	eff_width = mdccp->cmd_col_osc_width;
	eff_axis  = mdccp->cmd_col_axis;

	if(eff_start + eff_wedge < run_end)
		eff_end = eff_start + eff_wedge - 1;
	  else
		eff_end = run_end;

	nbatches = 1 + (mdccp->cmd_col_n_images - 1) / eff_wedge;

	fprintf(stdout,"do_wave_wedge: INFO:          nbatches: %d\n",nbatches);
	fprintf(stdout,"do_wave_wedge: INFO:          nwave: %d\n",mdccp->cmd_col_mad_nwave);

	for(batch_ctr = 0; batch_ctr < nbatches; batch_ctr++)
	  {
	        for(; wave_ctr < mdccp->cmd_col_mad_nwave; wave_ctr++)
	          {
		    wedge_side = 0;
		    eff_runno = mdccp->cmd_col_restart_run + 2 * 100 * wave_ctr;
		    eff_wave = mdccp->cmd_col_mad_wavelengths[wave_ctr];
	    	    initialize_angles(mdccp);
		    seq_wave_ival(mdccp);
	          }
		eff_start += eff_wedge;
		if(eff_start + eff_wedge <=  run_end)
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

	sprintf(fname,"%s/%s.runlist",mdccp->cmd_col_dir,mdccp->cmd_col_prefix);
	if(NULL == (fpl = fopen(fname,"w")))
	  {
	    fprintf(stderr,"ccd_dc_api: generate_run_list: Cannot create %s as run list\n",fname);
	    return;
	  }
	
	kappa_init(50.0);

	run_start = mdccp->cmd_col_image_number;
	eff_first = run_start;
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
	fclose(fpl);
  }
