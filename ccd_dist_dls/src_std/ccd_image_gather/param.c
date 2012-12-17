#include	"ext.h"

/*
 *	This module contains the "action" routines for the
 *	comands set up in parse.c
 */

/*
 *	setparam_action(no,str)  -  set a parameter.
 *
 *	Returns 1 if there is a problem, else 0 if OK.
 */

int	setparam_action(int no, char *str)
  {
	double	atof();

	if(*str == '\0')
	    return(1);

	switch(no)
	  {
	    case END_OF_DET_MOD:
		break;
	    case ROW_BIN_MOD:
		ccd_row_bin = atoi(str);
		break;
	    case COL_BIN_MOD:
		ccd_col_bin = atoi(str);
		if(ccd_col_bin == 2)
			binned_data = 1;
		    else
			binned_data = 0;
		det_bin = binned_data + 1;
		break;
	    case ROW_XFER_MOD:
		ccd_row_xfersize = atoi(str);
		if(n_ctrl == 4)
			ccd_row_xfersize *= 2;
		break;
	    case COL_XFER_MOD:
		ccd_col_xfersize = atoi(str);
		if(n_ctrl == 4)
			ccd_col_xfersize *= 2;
		break;
	    case HEADER_SIZE_MOD:
		input_header_size = atoi(str);
		break;
	    case MERGE_HEADER_BYTES_MOD:
		merge_header_bytes = atoi(str);
		break;
	    case INFILE_MOD:
		strcpy(infilename,str);
		break;
	    case OUTFILE_MOD:
		strcpy(outfilename,str);
		break;
	    case RAWFILE_MOD:
		strcpy(rawfilename,str);
		break;
	    case KIND_MOD:
		image_kind = atoi(str);
		break;
	    case SAVE_RAW_MOD:
		save_raw_images = atoi(str);
		break;
	    case ROW_MM_MOD:
		row_mm = atof(str);
		break;
	    case COL_MM_MOD:
		col_mm = atof(str);
		break;
	    case DIST_MM_MOD:
		dist_mm = atof(str);
		break;
	    case TWO_THETA_MOD:
		two_theta = atof(str);
		break;
	    case WAVE_MOD:
		wave = atof(str);
		break;
	    case REPLY_MOD:
		reply_to_sender = atoi(str);
		break;
	    case COMPRESS_MOD:
		compress_mode = atoi(str);
		break;
	    case DZRATIO_MOD:
		dzratio = atof(str);
		break;
	    case OUTFILE_TYPE_MOD:
		outfile_type = atoi(str);
		break;
            case DETECTOR_SN_MOD:
                detector_sn = atoi(str);
                break;
	    case STRIP_AVE_MOD:
		n_strip_ave = sscanf(str,"%f_%f_%f_%f",&sav[0],&sav[1],&sav[2],&sav[3]);
		break;
	  }
	return(0);
  }

/*
 *	getparam_action(no)  -  get a parameter.
 *
 *	Concatinate the "parameter" value to "replybuf".
 *	When the command is actually executed, the contents
 *	of this buffer will be returned.
 *
 *	Exception:  In the case of "all", dump all parameters
 *		    to replybuf.
 */

int	getparam_action(int no)
  {
	char	buf[256];

	switch(no)
	  {
	    case END_OF_DET_MOD:
		break;
	    case ROW_BIN_MOD:
		sprintf(buf,"row_bin %d\n",ccd_row_bin);
		strcat(replybuf,buf);
		break;
	    case COL_BIN_MOD:
		sprintf(buf,"col_bin %d\n",ccd_col_bin);
		strcat(replybuf,buf);
		break;
	    case ROW_XFER_MOD:
		sprintf(buf,"row_xfer %d\n",ccd_row_xfersize);
		strcat(replybuf,buf);
		break;
	    case COL_XFER_MOD:
		sprintf(buf,"col_xfer %d\n",ccd_col_xfersize);
		strcat(replybuf,buf);
		break;
	    case HEADER_SIZE_MOD:
		sprintf(buf,"header_size %d\n",input_header_size);
		strcat(replybuf,buf);
		break;
	    case INFILE_MOD:
		sprintf(buf,"infile %s\n",infilename);
		strcat(replybuf,buf);
		break;
	    case OUTFILE_MOD:
		sprintf(buf,"outfile %s\n",outfilename);
		strcat(replybuf,buf);
		break;
	    case RAWFILE_MOD:
		sprintf(buf,"rawfile %s\n",rawfilename);
		strcat(replybuf,buf);
		break;
	    case KIND_MOD:
		sprintf(buf,"kind %d\n",image_kind);
		strcat(replybuf,buf);
		break;
	    case SAVE_RAW_MOD:
		sprintf(buf,"save_raw %d\n",save_raw_images);
		strcat(replybuf,buf);
		break;
	    case ROW_MM_MOD:
		sprintf(buf,"row_mm %9.3f\n",row_mm);
		strcat(replybuf,buf);
		break;
	    case COL_MM_MOD:
		sprintf(buf,"col_mm %9.3f\n",col_mm);
		strcat(replybuf,buf);
		break;
	    case DIST_MM_MOD:
		sprintf(buf,"dist_mm %9.3f\n",dist_mm);
		strcat(replybuf,buf);
		break;
	    case TWO_THETA_MOD:
		sprintf(buf,"two_theta %9.3f\n",two_theta);
		strcat(replybuf,buf);
		break;
	    case WAVE_MOD:
		sprintf(buf,"wave %9.3f\n",wave);
		strcat(replybuf,buf);
		break;
	    case REPLY_MOD:
		sprintf(buf,"reply %d\n",reply_to_sender);
		strcat(replybuf,buf);
		break;
	    case COMPRESS_MOD:
		sprintf(buf,"compress %d\n",compress_mode);
		strcat(replybuf,buf);
		break;
	    case DZRATIO_MOD:
		sprintf(buf,"dzratio %f\n",dzratio);
		strcat(replybuf,buf);
		break;
	    case OUTFILE_TYPE_MOD:
		sprintf(buf,"outfile_type %d\n",outfile_type);
		strcat(replybuf,buf);
		break;
            case DETECTOR_SN_MOD:
                sprintf(buf,"detector_sn %d\n",detector_sn);
                strcat(replybuf,buf);
                break;
	    case ALL_MOD:
		sprintf(buf,"row_bin %d\n",ccd_row_bin);
		strcat(replybuf,buf);
		sprintf(buf,"col_bin %d\n",ccd_col_bin);
		strcat(replybuf,buf);
		sprintf(buf,"row_xfer %d\n",ccd_row_xfersize);
		strcat(replybuf,buf);
		sprintf(buf,"col_xfer %d\n",ccd_col_xfersize);
		strcat(replybuf,buf);
		sprintf(buf,"header_size %d\n",input_header_size);
		strcat(replybuf,buf);
		sprintf(buf,"infile %s\n",infilename);
		strcat(replybuf,buf);
		sprintf(buf,"outfile %s\n",outfilename);
		strcat(replybuf,buf);
		sprintf(buf,"rawfile %s\n",rawfilename);
		strcat(replybuf,buf);
		sprintf(buf,"kind %d\n",image_kind);
		strcat(replybuf,buf);
		sprintf(buf,"save_raw %d\n",save_raw_images);
		strcat(replybuf,buf);
		sprintf(buf,"row_mm %9.3f\n",row_mm);
		strcat(replybuf,buf);
		sprintf(buf,"col_mm %9.3f\n",col_mm);
		strcat(replybuf,buf);
		sprintf(buf,"dist_mm %9.3f\n",dist_mm);
		strcat(replybuf,buf);
		sprintf(buf,"two_theta %9.3f\n",two_theta);
		strcat(replybuf,buf);
		sprintf(buf,"wave %9.3f\n",wave);
		strcat(replybuf,buf);
		sprintf(buf,"dzratio %f\n",dzratio);
		strcat(replybuf,buf);
		sprintf(buf,"outfile_type %d\n",outfile_type);
		strcat(replybuf,buf);
                sprintf(buf,"detector_sn %d\n",detector_sn);
                strcat(replybuf,buf);
		sprintf(buf,"reply %d\n",reply_to_sender);
		strcat(replybuf,buf);
		break;
	  }
	rbufind = strlen(replybuf);
	return(0);
  }
