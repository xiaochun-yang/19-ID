#include	"ext.h"
#include 	<sys/types.h>
#include 	<math.h>
#include 	<unistd.h>
#include 	"filec.h"



/*
 *	Here all useful defaults are established, generally
 *	for the operating parameters of the particular CCD.
 */

/*
 *	Defaults to the EEV 1152x1242 6ph chip.
 */

initial_defaults()
  {
  	char	*cp;

  	if(NULL == (cp = (char *) getenv("CCD_MODULE_NROWS")))
		ccd_nrows = EEV_NROWS;
	    else
	    	ccd_nrows = atoi(cp);
  	if(NULL == (cp = (char *) getenv("CCD_MODULE_NCOLS")))
		ccd_ncols = EEV_NCOLS;
	    else
	    	ccd_ncols = atoi(cp);
  	if(NULL == (cp = (char *) getenv("CCD_MODULE_IMSIZE")))
		ccd_imsize = EEV_NROWS;
	    else
	    	ccd_imsize = atoi(cp);
	if(ccd_nrows > ccd_ncols)
		ccd_sqsize = ccd_nrows;
	    else
	    	ccd_sqsize = ccd_ncols;

	n_strip_ave = 0;
	use_strips = 0;
	no_pedestal_adjust = 0;
	no_pedestal_adjust_bin = 0;

	ccd_row_bin = 1;
	ccd_col_bin = 1;

	ccd_row_xfersize = ccd_imsize;
	ccd_col_xfersize = ccd_imsize;
	ccd_row_fullsize = ccd_imsize;
	ccd_col_fullsize = ccd_imsize;
	ccd_row_halfsize = ccd_imsize / 2;
	ccd_col_halfsize = ccd_imsize / 2;

	ccd_trigger_mode = CCD_TRIG_EXT;
	ccd_exp_time = 0.;
	ccd_adc = CCD_ADC_SLOW;
	ccd_timecheck = 1;

	image_kind = 0;
	save_raw_images = 1;
	reply_to_sender = 1;
	rotate_180 = 0;
	fix_bad = 0;
	rawfilename[0] = '\0';
	n_ctrl = 1;
	m_rotate[0] = 0; m_rotate[1] = 0; m_rotate[2] = 0; m_rotate[3] = 0;

	mult_host_dbfd_setup();

	compress_mode = 0;
	dzratio = 1.0;
	raw_saturated = 65535;

	req_ave = 0;

	xform_counter = 0;
  }

/*
 *	Dynamic variables get initialized here.
 */

int	dynamic_init()
  {
	char		envname[256];
	unsigned short	*uptr;
	int		*iptr;
	char		*cptr;
	int		nbytes;
	FILE		*fp;
	int		i;

	raw_header_size[0] = 0;
	raw_header_size[1] = 0;
	dkc_header_size[0] = 0;
	dkc_header_size[1] = 0;
	dkc_seen[0] = dkc_seen[1] = 0;
	raw_seen[0] = raw_seen[1] = 0;

	ccd_bufind = 0;
	ccd_data_valid[0] = 0;
	ccd_data_valid[1] = 0;

	if(n_ctrl == 1)
	    	nbytes = ccd_sqsize * ccd_sqsize * 1 * sizeof (unsigned short);
	else if(n_ctrl == 4)
	    	nbytes = ccd_sqsize * ccd_sqsize * 2 * sizeof (unsigned short);
	else if(n_ctrl == 9)
	    	nbytes = ccd_sqsize * ccd_sqsize * 3 * sizeof (unsigned short);

	if(NULL == (uptr = (unsigned short *) malloc(nbytes)))
	{
	        fprintf(stderr,"ccd_xform_api: Error allocating %d bytes for image storage.\n",nbytes);
	        fprintf(fplog,"ccd_xform_api: Error allocating %d bytes for image storage.\n",nbytes);
	        return(1);
	}
	scratch = uptr;

	nbytes = ccd_sqsize * ccd_sqsize * n_ctrl * sizeof (unsigned short);

	if(NULL == (in_data = (unsigned short *) malloc(nbytes)))
	  {
	    fprintf(stderr,"ccd_xform_api: Error allocating %d bytes for incoming image storage.\n",nbytes);
	    fprintf(fplog,"ccd_xform_api: Error allocating %d bytes for incoming image storage.\n",nbytes);
	    return(1);
	  }


	nbytes = ccd_sqsize * ccd_sqsize *  n_ctrl * sizeof (unsigned short);

	if(NULL == (uptr = (unsigned short *) malloc(nbytes)))
	  {
	    fprintf(stderr,"ccd_xform_api: Error allocating %d bytes for image storage.\n",nbytes);
	    fprintf(fplog,"ccd_xform_api: Error allocating %d bytes for image storage.\n",nbytes);
	    return(1);
	  }
	
	raw_data[0] = uptr;
	raw_data[1] = uptr;
	dkc_data[0] = uptr;
	dkc_data[1] = uptr;
	dkc_data[2] = uptr;
	dkc_data[3] = uptr;

	nbytes = CCD_HEADER_MAX;

	if(NULL == (cptr = (char *) malloc(nbytes)))
	  {
	    fprintf(stderr,"ccd_xform_api: Error allocating %d bytes for image storage.\n",nbytes);
	    fprintf(fplog,"ccd_xform_api: Error allocating %d bytes for image storage.\n",nbytes);
	    return(1);
	  }

	raw_header[0] = cptr;
	raw_header[1] = cptr;
	dkc_header[0] = cptr;
	dkc_header[1] = cptr;
	dkc_header[2] = cptr;
	dkc_header[3] = cptr;

	return(0);
  }
