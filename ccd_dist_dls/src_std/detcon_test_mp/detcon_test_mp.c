#include	<stdio.h>
#include	"../incl/detcon_par.h"
#include	"../incl/detcon_state.h"

static	int	bin;
static	int	adc;
static	int	output_raws;
static	int	no_transform;
static	int	flp_kind;
static	float	beam_xcen;
static	float	beam_ycen;
static	int	compress;
static	int	dist;
static	int	twotheta;
static	int	axis;
static	float	wave;
static	char	infobuf[256];
static	float	stat_time;
static	float	osc_width;
static	float	phi;

main(argc,argv)
int	argc;
char	*argv[];
  {
	int	clock_time,clock_start;
	int	last_image;
	int	nimages,totimages;
	char	buf[100];
	char	prefix[100];
	int	ex_time;
	int	start, end, dez, n;

	bin = 1;
	adc = 0;
	output_raws = 1;
	no_transform = 0;
	flp_kind = 0;
	beam_xcen = 90;
	beam_ycen = 90;
	compress = 0;
	dist = 40;
	twotheta = 0;
	axis = 1;
	wave = 1.5418;
	stat_time = 30;
	osc_width = 1.0;
	phi = 0.0;

	if(argc < 8)
	{
		fprintf(stderr,"detcon_test_mp bin prefix dez noxform start end time\n");
		exit(0);
	}

	bin = atoi(argv[1]);
	strcpy(prefix, argv[2]);
	dez = atoi(argv[3]);
	no_transform = atoi(argv[4]);
	start = atoi(argv[5]);
	end = atoi(argv[6]);
	ex_time = atoi(argv[7]);
	stat_time = ex_time;

	if(no_transform)
		output_raws = 1;
	else
		output_raws = 0;

	CCDInitialize();

	system("sleep 5");	/* immune to interrupt bounce outs */

	while(DTC_STATE_IDLE  != CCDState())
	  {
		fprintf(stdout,"%s\n",CCDState());
	  }

	/*
 	 *	These parameters define the state of the CCD's hardware and the
	 *	disposition of output images, via the transform.
	 */

        CCDSetHwPar(HWP_BIN,&bin);
        CCDSetHwPar(HWP_ADC,&adc);
        CCDSetHwPar(HWP_SAVE_RAW,&output_raws);
        CCDSetHwPar(HWP_NO_XFORM,&no_transform);

	/*
 	 *	Nice to have these paramters set for the header of the image.
	 */

	CCDSetFilePar(FLP_KIND,&flp_kind);
	CCDSetFilePar(FLP_FILENAME,infobuf);
	CCDSetFilePar(FLP_TIME,&stat_time);
        CCDSetFilePar(FLP_BEAM_X, &beam_xcen);
        CCDSetFilePar(FLP_BEAM_Y, &beam_ycen);
        CCDSetFilePar(FLP_COMPRESS, &compress);
        CCDSetFilePar(FLP_COMMENT,NULL);
        CCDSetFilePar(FLP_DISTANCE,&dist);
        CCDSetFilePar(FLP_TWOTHETA,&twotheta);
        CCDSetFilePar(FLP_AXIS,&axis);
        CCDSetFilePar(FLP_WAVELENGTH,&wave);
        CCDSetFilePar(FLP_OSC_RANGE,&osc_width);
	CCDSetFilePar(FLP_PHI,&phi);

	totimages = end - start + 1;

	for(nimages = 0; nimages < 2; nimages++)
	  {
	    /*
	     *	Set the kind of exposure.  nimages = 0,1 for dark, regular imgaes after.
	     *
	     *	Also, set the filename.
	     */
	    sprintf(buf,"%s_%03d", prefix, start);
	    flp_kind = nimages;

	    CCDSetFilePar(FLP_FILENAME,buf);
	    CCDSetFilePar(FLP_KIND,&flp_kind);
	    
	    CCDStartExposure();
	    while(DTC_STATE_EXPOSING != CCDState())
	      {
		if(DTC_STATE_ERROR == CCDState())
		  {
		    fprintf(stdout,"Error returned from CCDStartExposure()\n");
		    exit(0);
		  }
	      }
	    fprintf(stdout,"stalling for %d seconds, simulating exposure\n", ex_time);
	    time(&clock_start);
	    while(1)
	      {
	        time(&clock_time);
	        if(clock_time - clock_start > ex_time)
		    break;
	      }
	    CCDStopExposure();
	    while(DTC_STATE_IDLE != CCDState())
	      {
		if(DTC_STATE_ERROR == CCDState())
		  {
		    fprintf(stdout,"Error returned from CCDStartExposure()\n");
		    exit(0);
		  }
	      }
	    last_image = 0;
	    CCDSetFilePar(FLP_LASTIMAGE, &last_image);
	    CCDGetImage();
	  }

	for(nimages = start; nimages <= end; nimages++)
	for(n = dez; n >= 0; n--)
	  {
	    /*
	     *	Set the kind of exposure.  nimages = 0,1 for dark, regular imgaes after.
	     *
	     *	Also, set the filename.
	     */
	    sprintf(buf,"%s_%03d", prefix, nimages);
	    if(n == 1)
	    	flp_kind = 4;
	    else
	    	flp_kind = 5;

	    CCDSetFilePar(FLP_FILENAME,buf);
	    CCDSetFilePar(FLP_KIND,&flp_kind);
	    
	    CCDStartExposure();
	    while(DTC_STATE_EXPOSING != CCDState())
	      {
		if(DTC_STATE_ERROR == CCDState())
		  {
		    fprintf(stdout,"Error returned from CCDStartExposure()\n");
		    exit(0);
		  }
	      }
	    fprintf(stdout,"stalling for %d seconds, simulating exposure\n", ex_time);
	    time(&clock_start);
	    while(1)
	      {
	        time(&clock_time);
	        if(clock_time - clock_start > ex_time)
		    break;
	      }
	    CCDStopExposure();
	    while(DTC_STATE_IDLE != CCDState())
	      {
		if(DTC_STATE_ERROR == CCDState())
		  {
		    fprintf(stdout,"Error returned from CCDStartExposure()\n");
		    exit(0);
		  }
	      }
	    if(nimages == end && flp_kind == 5)
		last_image = 1;
	      else
		last_image = 0;
	    CCDSetFilePar(FLP_LASTIMAGE, &last_image);
	    CCDGetImage();
	  }
	fprintf(stdout,"Done.\n");
	fprintf(stdout,"Wait 10 seconds for all images to be collected by gather\n");
	system("sleep 10");
	fprintf(stdout,"Exiting normally\n");
	exit(0);
  }
