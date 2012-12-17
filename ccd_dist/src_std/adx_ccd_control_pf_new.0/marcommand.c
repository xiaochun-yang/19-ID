#include <stdio.h>
#include <stdlib.h>
#include <Xm/Xm.h>
#include <Xm/TextF.h>
#include "adx.h"

#include "creation-c.h"

marcommand(command, value)
int command;
double value;
{
	char *directory, *prefix;
	static int scan_number = 1;
	FILE *flog; /* logfile */
	char filename[256];

	if (debug) {
		fprintf(stderr,"command: %d value: %1.5f\n", command,value);
		fflush(stderr);
	}

	if(marcommandfp==NULL){
		if (debug) {
			fprintf(stderr,"marcommandfp=NULL\n");
			fflush(stderr);
		}
		emess("Error: no command file");
		return(0);
	}

	switch(command){
	case DRIVE_PHI:
		set_gonio_computer();
		if (debug) {
			fprintf(stderr,"CCD: Drive Phi: %1.5f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"phi_move %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case DRIVE_PHI_REL:
		set_gonio_computer();
		if (debug) {
			fprintf(stderr,"CCD: Drive Phi Relative: %1.5f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"phi_move_rel %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case SET_PHI:
		if (debug) {
			fprintf(stderr,"CCD: Set Phi: %1.5f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"phi_set %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case DRIVE_KAPPA:
		set_gonio_computer();
		if (debug) {
			fprintf(stderr,"CCD: Drive Kappa: %1.5f\n",value);
			fflush(stderr);
		}
		/*
		fprintf(stderr,"Drive Kappa %1.3f: Not yet implemented.\n",value);
		fflush(stderr);
		 */
		fprintf(marcommandfp,"kappa_move %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case SET_KAPPA:
		if (debug) {
			fprintf(stderr,"CCD: Set Kappa: %1.5f\n",value);
			fflush(stderr);
		}
		/*
		fprintf(stderr,"Set Kappa %1.3f: Not yet implemented.\n",value);
		fflush(stderr);
		 */
		fprintf(marcommandfp,"kappa_set %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case DRIVE_OMEGA:
		set_gonio_computer();
		if (debug) {
			fprintf(stderr,"CCD: Drive Omega: %1.5f\n",value);
			fflush(stderr);
		}
		/*
		fprintf(stderr,"Drive Omega %1.3f: Not yet implemented.\n",value);
		fflush(stderr);
		 */
		fprintf(marcommandfp,"omega_move %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case SET_OMEGA:
		if (debug) {
			fprintf(stderr,"CCD: Set Omega: %1.5f\n",value);
			fflush(stderr);
		}
		/*
		fprintf(stderr,"Set Omega %1.3f: Not yet implemented.\n",value);
		fflush(stderr);
		 */
		fprintf(marcommandfp,"omega_set %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case DRIVE_OMEGA_REL:
		set_gonio_computer();
		if (debug) {
			fprintf(stderr,"CCD: Drive Omega Relative: %1.5f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"omega_move_rel %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case DRIVE_DISTANCE:
		set_gonio_computer();
		if (debug) {
			fprintf(stderr,"CCD: Drive Distance: %1.5f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"distance_move %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case SET_DISTANCE:
		if (debug) {
			fprintf(stderr,"CCD: Set Distance: %1.5f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"distance_set %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case DRIVE_OFFSET:
		set_gonio_computer();
		if (debug) {
			fprintf(stderr,"CCD: Drive Lift (offset): %1.5f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"lift_move %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case SET_OFFSET:
		if (debug) {
			fprintf(stderr,"CCD: Set Lift (offset): %1.5f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"lift_set %1.5f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case OPEN_SHUTTER:
		if (debug) {
			fprintf(stderr,"CCD: Open Shutter.\n");
			fflush(stderr);
		}
		fprintf(marcommandfp,"shutter 1\neoc\n");
		fflush(marcommandfp);
		break;
	case CLOSE_SHUTTER:
		if (debug) {
			fprintf(stderr,"CCD: Close Shutter.\n");
			fflush(stderr);
		}
		fprintf(marcommandfp,"shutter 0\neoc\n");
		fflush(marcommandfp);
		break;
	case STOP:
		if (debug) {
			fprintf(stderr,"CCD: Stop.\n");
			fflush(stderr);
		}
		fprintf(marcommandfp,"stop\neoc\n");
		fflush(marcommandfp);

		strcpy(tmpstr,image_directory);
		strcat(tmpstr,"/LOGFILE");
		if ((flog = fopen(tmpstr,"a")) != NULL) {
			get_current_filename(filename);
			fprintf(flog,"STOP After %s\n",filename);
			fprintf(flog,"\n");
			fflush(flog);
			fclose(flog);
		}
		break;
	case ABORT:
		if (debug) {
			fprintf(stderr,"CCD: Abort.\n");
			fflush(stderr);
		}
		fprintf(marcommandfp,"abort\neoc\n");
		fflush(marcommandfp);

		strcpy(tmpstr,image_directory);
		strcat(tmpstr,"/LOGFILE");
		if ((flog = fopen(tmpstr,"a")) != NULL) {
			get_current_filename(filename);
			fprintf(flog,"STOP Immediately. Current Image: %s\n",filename);
			fprintf(flog,"\n");
			fflush(flog);
			fclose(flog);
		}
		break;
	case FLUSH_QUEUE:
		if (debug) {
			fprintf(stderr,"CCD: Flush Queue.\n");
			fflush(stderr);
		}
		fprintf(marcommandfp,"queue_flush\neoc\n");
		fflush(marcommandfp);
		break;
	case LIST_QUEUE:
		if (debug) {
			fprintf(stderr,"CCD: List Queue.\n");
			fflush(stderr);
		}
		fprintf(marcommandfp,"queue_list\neoc\n");
		fflush(marcommandfp);
		break;
	case HOME:
		if (debug) {
			fprintf(stderr,"CCD: home.\n");
			fflush(stderr);
		}
		fprintf(marcommandfp,"home\neoc\n");
		fflush(marcommandfp);
		break;
	case GON_MANUAL:
		if (debug) {
			fprintf(stderr,"CCD: gon_manual.\n");
			fflush(stderr);
		}
		fprintf(marcommandfp,"gon_manual %d\neoc\n",(int)(value));
		fflush(marcommandfp);
		break;
	case DRIVE_WAVELENGTH:
		set_gonio_computer();
		if (debug) {
			fprintf(stderr,"CCD: Drive Wavelength: %1.6f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"wavelength_move %1.6f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case SET_WAVELENGTH:
		if (debug) {
			fprintf(stderr,"CCD: Set Wavelength: %1.6f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"wavelength_set %1.6f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case SET_ATTENUATOR:
		if (debug) {
			fprintf(stderr,"CCD: Set Attenuator: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"attenuate %.1f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case AUTOALIGN:
		if (debug) {
			fprintf(stderr,"CCD: Autoalign: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"autoalign %.1f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case XL_HS:
		if (debug) {
			fprintf(stderr,"CCD: Set XL Horiz Slits: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"xl_hs_move %.3f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case XL_VS:
		if (debug) {
			fprintf(stderr,"CCD: Set XL Vert Slits: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"xl_vs_move %.3f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case XL_GUARD_HS:
		if (debug) {
			fprintf(stderr,"CCD: Set XL Guard Horiz Slits: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"xl_guard_hs_move %.3f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case XL_GUARD_VS:
		if (debug) {
			fprintf(stderr,"CCD: Set XL Guard Vert Slits: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"xl_guard_vs_move %.3f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case XL_UP_HHS:
		if (debug) {
			fprintf(stderr,"CCD: Set XL Upstream Horiz Halfslit: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"xl_up_hhs_move %.1f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case XL_UP_VHS:
		if (debug) {
			fprintf(stderr,"CCD: Set XL Upstream Vert Halfslit: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"xl_up_vhs_move %.1f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case XL_DN_HHS:
		if (debug) {
			fprintf(stderr,"CCD: Set XL Downstream Horiz Halfslit: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"xl_dn_hhs_move %.1f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case XL_DN_VHS:
		if (debug) {
			fprintf(stderr,"CCD: Set XL Downstream Vert Halfslit: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"xl_dn_vhs_move %.1f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case HS:
		if (debug) {
			fprintf(stderr,"CCD: Set Horiz Slits: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"hslit_move %.3f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case VS:
		if (debug) {
			fprintf(stderr,"CCD: Set Vert Slits: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"vslit_move %.3f\neoc\n",value);
		fflush(marcommandfp);
		break;
	case EM:
		if (debug) {
			fprintf(stderr,"CCD: Set Experiment Mode: %f\n",value);
			fflush(stderr);
		}
		fprintf(marcommandfp,"experiment_mode_move %.1f\neoc\n",value);
		fflush(marcommandfp);
		break;
	default:
		fprintf(stderr,"CCD: Unknown Command: %d\n",command);
		fflush(stderr);
		return(-1);
		break;
	}
	return(1);
}

marcommand_string(command, string)
int	command;
char	*string;
{
	if (debug) {
		fprintf(stderr,"CCD: Request PF STARS Master to be %s\n", string);
		fflush(stderr);
		}
	fprintf(marcommandfp, "set_master %s\neoc\n", string);
	fflush(marcommandfp);
}


mar_open()
{
	int	com_mode;
	char	*ptr,*getenv();

	if (getenv("MARSTATUSFILE") != NULL)
		strcpy(marstatusfile,getenv("MARSTATUSFILE"));
	else
		emess("Warning: environment variable MARSTATUSFILE not set");

	com_mode = 0;
	if(NULL != (ptr = getenv("MAR_COMMUNICATION")))
	  {
	    if(0 == strcmp(ptr,"tcp-ip"))
		com_mode = 1;
	  }
	if(NULL != (ptr = getenv("CCD_COMMUNICATION")))
	  {
	    if(0 == strcmp(ptr,"tcp-ip"))
		com_mode = 1;
	  }

	if (nocontrol == False) {
	if(com_mode == 0)
	  {
	    if(getenv("MARCOMMANDFILE") != NULL) 
	      {
		strcpy(marcommandfile,getenv("MARCOMMANDFILE"));
		/* open command file in append mode for writing */
		marcommandfp = fopen(marcommandfile,"a");
		if( marcommandfp == NULL)
		  emess("Warning: Cannot open MARCOMMANDFILE");
	      }
	    else
		emess("Warning: environment variable MARCOMMANDFILE not set");
	  }
	else
	  {
	    connect_to_dcserver(&marcommandfp);
	  }
	}
	else {
		marcommandfp = fopen("/dev/null","a");
		fprintf(stderr,"Openned /dev/null. marcommandfp=%d\n",marcommandfp);
		fflush(stderr);
	}

	if (getenv("MARCOLLECTFILE") != NULL)
		strcpy(marcollectfile,getenv("MARCOLLECTFILE"));
	else
		emess("Warning: environment variable MARCOLLECTFILE not set");
}

emess(str)
char *str;
{
	fprintf(stderr,"%s\n",str);
	fflush(stderr);
}

get_current_filename(filename)
char *filename;
{
	FILE *fp;
	char buf[256], key[256], value[256];

	strcpy(filename,"????");

	if (!strcmp(marstatusfile,""))
		return;

	fp = fopen(marstatusfile,"r");
	if (fp == NULL) {
		sprintf(buf,"Can not open status file: %s\n", marstatusfile);
		emess(buf);
		return;
	}

	while(fgets(buf,256,fp)!=NULL){

		/* Skip blank lines */
		if (iswhite(buf))
			continue;

		/* Get rid of trailing white space */
		while(isspace(buf[strlen(buf)-1]) )
			buf[strlen(buf)-1]= '\0';

		if (!strncmp(buf,"end_of_status",strlen("end_of_status")))
			break;

		strcpy(key,"");
		strcpy(value,"");
		sscanf(buf,"%s%*[ \t]%[^\n]",key,value);
		if(!strncmp(key,"current_filename",16)){
			remove_white(value);
			strcpy(filename,value);
		}
	}
	fclose(fp);
}

set_gonio_computer()
{
	XmToggleButtonSetState(gonio_off_pushButton,False,False);  /* Manual */
	XmToggleButtonSetState(gonio_on_pushButton,True,False); /* Computer */
}
