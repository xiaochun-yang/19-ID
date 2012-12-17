#include	"detcon_ext.h"

static int	debug_par = 0;

struct dtc_parstruct {
			int	dtc_parno;
			int	dtc_partype;
			char	*dtc_parptr;
		     };

#define	DTC_TYPE_INT	0
#define	DTC_TYPE_FLOAT	1
#define	DTC_TYPE_STRING 2

struct dtc_parstruct hwp_param[] = {
	HWP_BIN, 	DTC_TYPE_INT,	(char *) &dtc_stat_bin,
	HWP_ADC,	DTC_TYPE_INT,	(char *) &dtc_stat_adc,
	HWP_SAVE_RAW,	DTC_TYPE_INT,	(char *) &dtc_output_raws,
	HWP_DARK,	DTC_TYPE_INT,	(char *) &dtc_force_dark,
	HWP_DARK_MODE,	DTC_TYPE_INT,	(char *) &dtc_dark_mode,
	HWP_NO_XFORM,	DTC_TYPE_INT,	(char *) &dtc_no_transform,
	0,		0,		NULL,
     };

struct dtc_parstruct flp_param[] = {
	FLP_PHI,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_phi,
	FLP_OMEGA,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_omega,
	FLP_KAPPA,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_omega,
	FLP_TWOTHETA,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_2theta,
	FLP_DISTANCE,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_dist,
	FLP_WAVELENGTH,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_wavelength,
	FLP_AXIS,		DTC_TYPE_INT,		(char *) &dtc_stat_axis,
	FLP_OSC_RANGE,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_osc_width,
	FLP_TIME,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_time,
	FLP_DOSE,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_dose,
	FLP_BEAM_X,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_xcen,
	FLP_BEAM_Y,		DTC_TYPE_FLOAT,		(char *) &dtc_stat_ycen,
	FLP_COMPRESS,		DTC_TYPE_INT,		(char *) &dtc_stat_compress,
	FLP_KIND,		DTC_TYPE_INT,		(char *) &dtc_image_kind,
	FLP_FILENAME,		DTC_TYPE_STRING,	dtc_filename,
	FLP_COMMENT,		DTC_TYPE_STRING,	dtc_comment,
	FLP_LASTIMAGE,		DTC_TYPE_INT,		(char *) &dtc_lastimage,
        FLP_SUFFIX,		DTC_TYPE_STRING,	dtc_default_suffix,
        FLP_IMBYTES, 		DTC_TYPE_INT,		(char *) &dtc_default_imsize,
	0,		0,		NULL,
     };

int	detcon_set_hw_param(which_par,p_value)
int	which_par;
char	*p_value;
  {
	int	i;

	for(i = 0; NULL != hwp_param[i].dtc_parptr; i++)
	  if(which_par == hwp_param[i].dtc_parno)
	    {
		switch(hwp_param[i].dtc_partype)
		  {
		    case DTC_TYPE_INT:
			*((int *) hwp_param[i].dtc_parptr) = *((int *) p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_hw_param: (int)    set param %2d to %d\n",
				which_par,*((int *) hwp_param[i].dtc_parptr));
			break;
		    case DTC_TYPE_FLOAT:
			*((float *) hwp_param[i].dtc_parptr) = *((float *) p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_hw_param: (float)  set param %2d to %f\n",
				which_par,*((float *) hwp_param[i].dtc_parptr));
			break;
		    case DTC_TYPE_STRING:
			if(NULL == (char *) p_value)
				*hwp_param[i].dtc_parptr = '\0';
			  else
				strcpy((char *) hwp_param[i].dtc_parptr,(char *) p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_hw_param: (string) set param %2d to %s\n",
				which_par,(char *) hwp_param[i].dtc_parptr);
			break;
		  }
		return(0);
	  }
	return(1);
  }

int	detcon_set_file_param(which_par,p_value)
int	which_par;
char	*p_value;
  {
	int	i;

	for(i = 0; NULL != flp_param[i].dtc_parptr; i++)
	  if(which_par == flp_param[i].dtc_parno)
	    {
		switch(flp_param[i].dtc_partype)
		  {
		    case DTC_TYPE_INT:
			*((int *) flp_param[i].dtc_parptr) = *((int *) p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_file_param: (int)    set param %2d to %d\n",
				which_par,*((int *) flp_param[i].dtc_parptr));
			break;
		    case DTC_TYPE_FLOAT:
			*((float *) flp_param[i].dtc_parptr) = *((float *) p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_file_param: (float)  set param %2d to %f\n",
				which_par,*((float *) flp_param[i].dtc_parptr));
			break;
		    case DTC_TYPE_STRING:
			if(NULL == (char *) p_value)
				*flp_param[i].dtc_parptr = '\0';
			  else
				strcpy((char *) flp_param[i].dtc_parptr,(char *) p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_file_param: (string) set param %2d to %s\n",
				which_par,(char *) flp_param[i].dtc_parptr);
			break;
		  }
		return(0);
	  }
	return(1);
  }

int	detcon_get_hw_param(which_par,p_value)
int	which_par;
char	*p_value;
  {
	int	i;

	for(i = 0; NULL != hwp_param[i].dtc_parptr; i++)
	  if(which_par == hwp_param[i].dtc_parno)
	    {
		switch(hwp_param[i].dtc_partype)
		  {
		    case DTC_TYPE_INT:
			*((int *) p_value) = *((int *) hwp_param[i].dtc_parptr);
			break;
		    case DTC_TYPE_FLOAT:
			*((float *) p_value) = *(float *) hwp_param[i].dtc_parptr;
			break;
		    case DTC_TYPE_STRING:
			strcpy((char *) p_value, (char *) hwp_param[i].dtc_parptr);
			break;
		  }
		return(0);
	  }
	return(1);
  }

int	detcon_get_file_param(which_par,p_value)
int	which_par;
char	*p_value;
  {
	int	i;

	if(dtc_stat_bin == 1)
		dtc_default_imsize = 2 * 4096 * 4096;
	else
		dtc_default_imsize = 2 * 2048 * 2048;

	for(i = 0; NULL != flp_param[i].dtc_parptr; i++)
	  if(which_par == flp_param[i].dtc_parno)
	    {
		switch(flp_param[i].dtc_partype)
		  {
		    case DTC_TYPE_INT:
			*((int *) p_value) = *((int *) flp_param[i].dtc_parptr);
			break;
		    case DTC_TYPE_FLOAT:
			*((float *) p_value) = *((float *) flp_param[i].dtc_parptr);
			break;
		    case DTC_TYPE_STRING:
			strcpy((char *) p_value, (char *) flp_param[i].dtc_parptr);
			break;
		  }
		return(0);
	  }
	return(1);
  }

int	str_detcon_set_hw_param(which_par,p_value)
int	which_par;
char	*p_value;
  {
	int	i;
	double	atof();
	int	atoi();

	for(i = 0; NULL != hwp_param[i].dtc_parptr; i++)
	  if(which_par == hwp_param[i].dtc_parno)
	    {
		switch(hwp_param[i].dtc_partype)
		  {
		    case DTC_TYPE_INT:
			*((int *) hwp_param[i].dtc_parptr) = atoi(p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_hw_param: (int)    set param %2d to %d\n",
				which_par,*((int *) hwp_param[i].dtc_parptr));
			break;
		    case DTC_TYPE_FLOAT:
			*((float *) hwp_param[i].dtc_parptr) = atof(p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_hw_param: (float)  set param %2d to %f\n",
				which_par,*((float *) hwp_param[i].dtc_parptr));
			break;
		    case DTC_TYPE_STRING:
			if(NULL == (char *) p_value)
				*hwp_param[i].dtc_parptr = '\0';
			  else
				strcpy((char *) hwp_param[i].dtc_parptr,(char *) p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_hw_param: (string) set param %2d to %s\n",
				which_par,(char *) hwp_param[i].dtc_parptr);
			break;
		  }
		return(0);
	  }
	return(1);
  }

int	str_detcon_set_file_param(which_par,p_value)
int	which_par;
char	*p_value;
  {
	int	i;
	double	atof();
	int	atoi();

	for(i = 0; NULL != flp_param[i].dtc_parptr; i++)
	  if(which_par == flp_param[i].dtc_parno)
	    {
		switch(flp_param[i].dtc_partype)
		  {
		    case DTC_TYPE_INT:
			*((int *) flp_param[i].dtc_parptr) = atoi(p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_file_param: (int)    set param %2d to %d\n",
				which_par,*((int *) flp_param[i].dtc_parptr));
			break;
		    case DTC_TYPE_FLOAT:
			*((float *) flp_param[i].dtc_parptr) = atof(p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_file_param: (float)  set param %2d to %f\n",
				which_par,*((float *) flp_param[i].dtc_parptr));
			break;
		    case DTC_TYPE_STRING:
			if(NULL == (char *) p_value)
				*flp_param[i].dtc_parptr = '\0';
			  else
				strcpy((char *) flp_param[i].dtc_parptr,(char *) p_value);
			if(debug_par)
			fprintf(stderr,
			  "detcon_set_file_param: (string) set param %2d to %s\n",
				which_par,(char *) flp_param[i].dtc_parptr);
			break;
		  }
		return(0);
	  }
	return(1);
  }

static	char	retbuf[512];

int	str_detcon_get_hw_param(which_par,p_value)
int	which_par;
char	**p_value;
  {
	int	i;

	for(i = 0; NULL != hwp_param[i].dtc_parptr; i++)
	  if(which_par == hwp_param[i].dtc_parno)
	    {
		switch(hwp_param[i].dtc_partype)
		  {
		    case DTC_TYPE_INT:
			sprintf(retbuf,"%d",*((int *) hwp_param[i].dtc_parptr));
			*p_value = retbuf;
			break;
		    case DTC_TYPE_FLOAT:
			sprintf(retbuf,"%f",*(float *) hwp_param[i].dtc_parptr);
			*p_value = retbuf;
			break;
		    case DTC_TYPE_STRING:
			strcpy(retbuf, (char *) hwp_param[i].dtc_parptr);
			*p_value = retbuf;
			break;
		  }
		return(0);
	  }
	return(1);
  }

int	str_detcon_get_file_param(which_par,p_value)
int	which_par;
char	**p_value;
  {
	int	i;

	for(i = 0; NULL != flp_param[i].dtc_parptr; i++)
	  if(which_par == flp_param[i].dtc_parno)
	    {
		switch(flp_param[i].dtc_partype)
		  {
		    case DTC_TYPE_INT:
			sprintf(retbuf,"%d",*((int *) flp_param[i].dtc_parptr));
			*p_value = retbuf;
			break;
		    case DTC_TYPE_FLOAT:
			sprintf(retbuf,"%f",*((float *) flp_param[i].dtc_parptr));
			*p_value = retbuf;
			break;
		    case DTC_TYPE_STRING:
			strcpy(retbuf, (char *) flp_param[i].dtc_parptr);
			*p_value = retbuf;
			break;
		  }
		return(0);
	  }
	return(1);
  }
