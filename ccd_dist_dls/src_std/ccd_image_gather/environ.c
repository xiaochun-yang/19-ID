#include	"ext.h"

/*
 *	check_environ checks a number of environment names
 *	for:
 *
 *	[These are "defines" found in the defs.h file.]
 *
 *	THESE ARE REQUIRED:
 *
 *	  CCD_XFORM_API_CPORT :		tcp/ip command port number.
 *	  CCD_DET_API_DPORT :		tcp/ip data port number.
 *	  CCD_DET_API_HOSTNAME:		hostname for the detector api server.
 *	  CCD_CALFIL:			Calibration file.
 *	  CCD_NONUNF:			Nonuniformity Correction file.
 *	  XFORMSTATUSFILE		For adxv follow images.
 *
 *	THESE ARE OPTIONAL:
 *
 *	  CCD_XFORM_API_LOGFILE:	If this environment name is given, this file 
 *					(assuming it can be created) gets a duplicate of 
 *					"error" messages from the api.
 *
 *	  CCD_N_CTRL			Number of controllers/modules in the detector.
 *	  CCD_U_CTRL			A "vector" of modules which comprise the detector.
 *					"1 0 0 0" is a single module detector, "1 1 1 1" is
 *					a 4 module 2x2 array.
 *	  CCD_M_ROTATE			A vector of rotations to orient each chip correctly.
 *					Valid values are 0 -90 (or 270), 90, and 180.
 *
 *	  CCD_DEZ_AVERAGE		When this variable is defined as 1, the image
 *					dezingered from two images are AVERAGED, not SUMMED.
 *					The default is SUMMED.
 *
 *	  CCD_X_INT:			X Interpolation File (for overloads)
 *	  CCD_Y_INT:			Y Interpolation File (for overloads)
 *	  CCD_CALPAR:			Calibration parameters (for overloads)
 *
 *	  CCD_RAW_SATURATION		Values above this are considered saturated 
 *
 *	     The default for these is always a single module detector.
 */

int	check_environ()
  {
	int	c_found,d_found,h_found;
	char	*cptr;

	c_found = d_found = 0;

	if(NULL != (cptr = (char *) getenv(CCD_XFORM_API_CPORT)))
	  {
		command_port_no = atoi(cptr);
		c_found = 1;
	  }
	 else
	  {
		fprintf(stderr,"ccd_xform_api: NO environment variable %s found.\n",CCD_XFORM_API_CPORT);
		fprintf(stderr,"             This environment variable is REQUIRED to be set.\n");
	  }

	if(NULL != (cptr = (char *) getenv(CCD_DET_API_DPORT)))
	  {
		data_port_no = atoi(cptr);
		d_found = 1;
	  }
	 else
	  {
		fprintf(stderr,"ccd_xform_api: NO environment variable %s found.\n",CCD_DET_API_DPORT);
		fprintf(stderr,"             This environment variable is REQUIRED to be set.\n");
	  }
	if(NULL != (cptr = (char *) getenv(CCD_DET_API_HOSTNAME)))
	  {
		strcpy(det_hostname,cptr);
		h_found = 1;
	  }
	 else
	  {
		fprintf(stderr,"ccd_xform_api: NO environment variable %s found.\n",CCD_DET_API_HOSTNAME);
		fprintf(stderr,"             This environment variable is REQUIRED to be set.\n");
	  }
	
	if(c_found == 0 || d_found == 0 || h_found == 0)
		return(1);
	
	/*
	 *	Check for the optional environment names.
	 */
	
	if(NULL != (cptr = (char *) getenv(CCD_XFORM_API_LOGFILE)))
	  {
	    if(NULL == (fplog = fopen(cptr,"w")))
	      {
		fprintf(stderr,"ccd_xform_api: WARNING: could not create logfile: %s\n",cptr);
		fprintf(stderr,"             which was derived from the environment variable %s\n",
				CCD_XFORM_API_LOGFILE);
		fprintf(stderr,"             %s will be used for the logfile.\n",CCD_NULLFILE);
	      }
	    if(NULL == (fplog = fopen(CCD_NULLFILE,"w")))
	      {
		fprintf(stderr,"ccd_xform_api: SERIOUS ERROR: cannot open %s as logfile.\n",CCD_NULLFILE);
		fprintf(stderr,"             This file should ALWAYS be openable.\n");
		return(1);
	      }
	  }
	 else
	  if(NULL == (fplog = fopen(CCD_NULLFILE,"w")))
	    {
	      fprintf(stderr,"ccd_xform_api: SERIOUS ERROR: cannot open %s as logfile.\n",CCD_NULLFILE);
	      fprintf(stderr,"             This file should ALWAYS be openable.\n");
	      return(1);
	    }


	if(0)
	{
	if(NULL == (cptr = (char *) getenv(CCD_CALFIL)))
	  {
	      fprintf(stderr,"ccd_xform_api: SERIOUS ERROR: cannot open %s as CALFIL.\n",CCD_CALFIL);
	      fprintf(stderr,"             This file should ALWAYS be openable.\n");
	      return(1);
	  }

	if(NULL == (cptr = (char *) getenv(CCD_NONUNF)))
	  {
	      fprintf(stderr,"ccd_xform_api: SERIOUS ERROR: cannot open %s as NONUNF.\n",CCD_NONUNF);
	      fprintf(stderr,"             This file should ALWAYS be openable.\n");
	      return(1);
	  }
	if(NULL == (cptr = (char *) getenv(CCD_POSTNUF)))
	  {
	      fprintf(stderr,"ccd_xform_api: SERIOUS ERROR: cannot open %s as POSTNUF.\n",CCD_POSTNUF);
	      fprintf(stderr,"             This file should ALWAYS be openable.\n");
	      return(1);
	  }
	}
	if(NULL == (cptr = (char *) getenv(XFORMSTATUSFILE)))
	  {
	      fprintf(stderr,"ccd_xform_api: SERIOUS ERROR: cannot find environment %s as transform status file.\n",
					XFORMSTATUSFILE);
	      fprintf(stderr,"             This environment variable should ALWAYS be defined.\n");
	      return(1);
	  }
	if(NULL == (fpxfs = fopen(cptr,"w")))
	  {
		fprintf(stderr,"ccd_xform_api: WARNING: could not create xformstatusfile: %s\n",cptr);
		fprintf(stderr,"             which was derived from the environment variable %s\n",
				XFORMSTATUSFILE);
		fprintf(stderr,"             %s will be used for the logfile.\n",CCD_NULLFILE);
		if(NULL == (fpxfs = fopen(CCD_NULLFILE,"w")))
		  {
		    fprintf(stderr,"ccd_xform_api: SERIOUS ERROR: cannot open %s as logfile.\n",CCD_NULLFILE);
		    fprintf(stderr,"             This file should ALWAYS be openable.\n");
		    return(1);
		  }
		 else
			strcpy(xfsname,CCD_NULLFILE);
	  }
	 else
	  {
	   strcpy(xfsname,cptr);
	   fprintf(fpxfs,"0 <none>\n");
	   fclose(fpxfs);
	  }

	if(0)
	{
	if(NULL != (cptr = (char *) getenv(CCD_DEZ_AVERAGE)))
	  {
	    if(0 != atoi(cptr))
	      {
		req_ave = 1;
		fprintf(stderr,"ccd_xform_api: environ: AVERAGING of two images from dezingering\n");
		fprintf(stderr,"                        as opposed to summing has been specified.\n");
	      }
	  }
	if(NULL != (cptr = (char *) getenv("USE_STRIPS")))
	  {
		fprintf(stderr,"ccd_xform_api: environ: USE_STRIPS of images for pedestal check.\n");
		use_strips = 1;
	  }
	if(NULL != (cptr = (char *) getenv("NO_PEDESTAL_ADJUST")))
	  {
		fprintf(stderr,"ccd_xform_api: environ: NO_PEDESTAL_ADJUST disables pedestal adjustment.\n");
		no_pedestal_adjust = 1;
	  }
	if(NULL != (cptr = (char *) getenv("NO_PEDESTAL_ADJUST_BIN")))
	  {
		fprintf(stderr,"ccd_xform_api: environ: NO_PEDESTAL_ADJUST_BIN disables pedestal adjustment.\n");
		no_pedestal_adjust_bin = 1;
	  }
	if(NULL != (cptr = (char *) getenv(CCD_RAW_SATURATION)))
	  {
	    if(0 != atoi(cptr))
	      {
		raw_saturated = atoi(cptr);
		fprintf(stderr,"ccd_xform_api: environ: raw_saturated level set to: %d\n",raw_saturated);
	      }
	  }

	if(NULL == (cptr = (char *) getenv(CCD_X_INT)))
	  {
	      fprintf(stderr,"ccd_xform_api: WARNING: cannot open %s as CCD_X_INT.\n",CCD_X_INT);
	      fprintf(stderr,"             This file is needed to mark overflows.\n");
	  }
	if(NULL == (cptr = (char *) getenv(CCD_Y_INT)))
	  {
	      fprintf(stderr,"ccd_xform_api: WARNING: cannot open %s as CCD_Y_INT.\n",CCD_Y_INT);
	      fprintf(stderr,"             This file is needed to mark overflows.\n");
	  }
	if(NULL == (cptr = (char *) getenv(CCD_CALPAR)))
	  {
	      fprintf(stderr,"ccd_xform_api: WARNING: cannot open %s as CCD_CALPAR.\n",CCD_CALPAR);
	      fprintf(stderr,"             This file is needed to mark overflows.\n");
	  }
	}
	
	return(0);
  }
