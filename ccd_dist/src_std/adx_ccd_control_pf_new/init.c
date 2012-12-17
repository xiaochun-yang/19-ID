#include <Xm/Xm.h>
#include <Xm/Text.h>
#include <Xm/FileSB.h>
#include <stdio.h>
#include <stdlib.h>
#include "adx.h"

/*
 * Standard includes for builtins.
 */
#include <string.h>
#include <ctype.h>
#include "creation-c.h"

init_adx(argc, argv)
int argc;
char *argv[];
{
	extern void MENU_POST();
	void timer_func();
	int i, j;
    	Arg args[16];
	char *tstr, buf[1024], key[256], value[256];
	int nrows, run, frame;
	double site_wavelength, site_energy;
	double wavelength_to_energy();

	debug = 0;
	beamline_mode = False;
	define_distance = True;
	define_offset = False;
	software_mode = False;
	beam_x = beam_y = -1000;
	n_fields = N_FIELDS;
	dezinger=False;
	file_overwrite_mode = 2; /* Fatal */
	nocontrol=False;
	show_xray_label=True;

	/*strcpy(progname,argv[0]);*/

	while(argc > 1) { 
		if(!strcmp(*++argv, "-debug")) {
			debug=True;
		}
		else 
		if(!strcmp(*argv, "-software_mode")) {
			software_mode=True;
		}
		else 
		if(!strcmp(*argv, "-define_distance")) {
			define_distance=True;
		}
		else 
		if(!strcmp(*argv, "-define_offset")) {
			define_offset=True;
		}
		else 
		if(!strcmp(*argv, "-nocontrol")) {
			nocontrol=True;
		}
		else 
		if(!strcmp(*argv, "-beamline")) {
			beamline_mode=True;
			n_fields = N_FIELDS + 1;
		}
		else 
		if(!strcmp(*argv, "-no_xray")) {
			show_xray_label=False;
		}
		else
			usage();
		/*
		else 
		if(!strcmp(*argv, "-ncolors")) {
			if (argc > 2) {
				ncolors = atoi(*++argv);
				argc--;
			}
			else {
				usage();
			}
		}
		*/
		argc--;
	}

	mar_open();

	XtSetArg(args[0], XmNx, scr_width + OPTIONSDIALOG_X);
	XtSetArg(args[1], XmNy, OPTIONSDIALOG_Y);
	XtSetValues(optionsDialog,args,2);

	XtSetArg(args[0], XmNx, scr_width + ADX_HELP_X);
	XtSetArg(args[1], XmNy, ADX_HELP_Y);
	XtSetValues(adx_helpDialog,args,2);

	XtSetArg(args[0], XmNx, scr_width + MAD_DIALOG_X);
	XtSetArg(args[1], XmNy, MAD_DIALOG_Y);
	XtSetValues(madDialog,args,2);

	XtSetArg(args[0], XmNx, scr_width + STATUSDIALOG_X);
	XtSetArg(args[1], XmNy, STATUSDIALOG_Y);
	XtSetValues(statusDialog,args,2);
    	XtManageChild(statusDialog);

	XtSetArg(args[0], XmNx, scr_width + MAIN_X - 5);
	XtSetArg(args[1], XmNy, MAIN_Y);
	XtSetValues(bulletinBoard,args,2);
    	XtManageChild(bulletinBoard);

	display = XtDisplay(statusDialog);

	image_collect_mode=TIME_MODE;
	image_compression=COMP_NONE;
	wavelength = 1.5418;
	attenuator = 0.0;

	TextFieldSetFloat4(wavelength_textField,wavelength);
	
	/*
	XtAddEventHandler(setup_arrowButton,
		ButtonPressMask, False, MENU_POST, (XtPointer)setup_popupMenu);
	XtAddEventHandler(stop_arrowButton,
		ButtonPressMask, False, MENU_POST, (XtPointer)popupMenu);
	XtAddEventHandler(display_arrowButton,
		ButtonPressMask, False, MENU_POST, (XtPointer)display_popupMenu);
	XtAddEventHandler(process_arrowButton,
		ButtonPressMask, False, MENU_POST, (XtPointer)process_popupMenu);
	 */
	 

	if (define_distance)
		XtSetSensitive(define_distance_pushButton,True);
	if (define_offset)
		XtSetSensitive(define_twotheta_pushButton,True);

	XmToggleButtonSetState(snap_slow_toggleButton,True,False);
	XmToggleButtonSetState(snap_fast_toggleButton,False,False);
	XmToggleButtonSetState(snap_bin1_toggleButton,True,False);
	XmToggleButtonSetState(snap_bin2_toggleButton,False,False);
	XmToggleButtonSetState(snap_ydc_toggleButton,False,False);
	XmToggleButtonSetState(snap_ndc_toggleButton,True,False);

	XmToggleButtonSetState(strategy_slow_toggleButton,True,False);
	XmToggleButtonSetState(strategy_fast_toggleButton,False,False);
	XmToggleButtonSetState(strategy_bin1_toggleButton,True,False);
	XmToggleButtonSetState(strategy_bin2_toggleButton,False,False);

	XmToggleButtonSetState(strategy_anomyes_toggleButton,False,False);
	XmToggleButtonSetState(strategy_anomno_toggleButton,True,False);
	/* Anomalous Wedge in Mad window */
    	XtSetSensitive(label97,False);
    	XtSetSensitive(mad_option3_toggleButton,False);

	XmToggleButtonSetState(strategy_MADyes_toggleButton,False,False);
	XmToggleButtonSetState(strategy_MADno_toggleButton,True,False);

	XmToggleButtonSetState(options_output16_toggleButton,True,False);
	XmToggleButtonSetState(options_output32_toggleButton,False,False);

	XmToggleButtonSetState(options_outputsmv_toggleButton,True,False);
	XmToggleButtonSetState(options_outputcbf_toggleButton,False,False);

	XmToggleButtonSetState(options_xform_yes,True,False);
	XmToggleButtonSetState(options_xform_no,False,False);

	XmToggleButtonSetState(options_saveraw_yes,False,False);
	XmToggleButtonSetState(options_saveraw_no,True,False);

	XmToggleButtonSetState(options_darkrun_toggleButton,True,False);
	XmToggleButtonSetState(options_darkinterval_toggleButton,False,False);
	XtSetSensitive(options_darkinterval_textField, False);
	XtSetSensitive(label32,False);

    	XtSetSensitive(label18,False);
    	XtSetSensitive(label29,False);
    	XtSetSensitive(strategy_wedge_textField,False);
	XmTextFieldSetString(strategy_wedge_textField,"5");

    	XtSetSensitive(options_deg_dose_textField,True);
	XmTextFieldSetString(options_deg_dose_textField,"0.01");

	XmToggleButtonSetState(drive_distance_pushButton,True,False);
	XmToggleButtonSetState(define_distance_pushButton,False,False);

#ifdef CHESS_CCD
	XmToggleButtonSetState(define_phi_pushButton,True,False);
	XmToggleButtonSetState(drive_phi_pushButton,False,False);
#else
	XmToggleButtonSetState(drive_phi_pushButton,True,False);
	XmToggleButtonSetState(define_phi_pushButton,False,False);
#endif /* CHESS_CCD */

	XmToggleButtonSetState(gonio_off_pushButton,False,False);  /* Manual */
	XmToggleButtonSetState(gonio_on_pushButton,True,False); /* Computer */

	XmToggleButtonSetState(drive_twotheta_pushButton,True,False);
	XmToggleButtonSetState(define_twotheta_pushButton,False,False);
	XmToggleButtonSetState(drive_kappa_pushButton,True,False);
	XmToggleButtonSetState(define_kappa_pushButton,False,False);
	XmToggleButtonSetState(drive_omega_pushButton,True,False);
	XmToggleButtonSetState(define_omega_pushButton,False,False);
	XmToggleButtonSetState(drive_wavelength_pushButton,True,False);
	XmToggleButtonSetState(define_wavelength_pushButton,False,False);

	if (image_collect_mode == DOSE_MODE) {
		XmToggleButtonSetState(strategy_time_mode_toggleButton,False,False);
		XmToggleButtonSetState(strategy_dose_mode_toggleButton,True,False);
	}
	else {
		XmToggleButtonSetState(strategy_time_mode_toggleButton,True,False);
		XmToggleButtonSetState(strategy_dose_mode_toggleButton,False,False);
	}

	if (image_compression==COMP_Z) {
		XmToggleButtonSetState(strategy_comp_none_toggleButton,False,False);
		XmToggleButtonSetState(strategy_comp_Z_toggleButton,True,False);
		XmToggleButtonSetState(strategy_comp_pck_toggleButton,False,False);
	}
	else
	if (image_compression==COMP_PCK) {
		XmToggleButtonSetState(strategy_comp_none_toggleButton,False,False);
		XmToggleButtonSetState(strategy_comp_Z_toggleButton,False,False);
		XmToggleButtonSetState(strategy_comp_pck_toggleButton,True,False);
	}
	else {
		XmToggleButtonSetState(strategy_comp_none_toggleButton,True,False);
		XmToggleButtonSetState(strategy_comp_Z_toggleButton,False,False);
		XmToggleButtonSetState(strategy_comp_pck_toggleButton,False,False);
	}

	read_config_file();

	if (sc_conf.constrain_phi == 180) {
    		Arg args[2];
   		XmString xmstr;

		/* Run(s) */
		xmstr = XmStringCreateSimple("-135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -135);
		XtSetValues(pushButton60,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -90);
		XtSetValues(pushButton61,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -45);
		XtSetValues(pushButton62,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  0");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 0);
		XtSetValues(pushButton63,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 45);
		XtSetValues(pushButton64,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 90);
		XtSetValues(pushButton65,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 135);
		XtSetValues(pushButton66,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  180");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 180);
		XtSetValues(pushButton67,args,2);
    		XmStringFree(xmstr);

		/* Manual Control */
		xmstr = XmStringCreateSimple("-135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -135);
		XtSetValues(pushButton96,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -90);
		XtSetValues(pushButton97,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -45);
		XtSetValues(pushButton98,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  0");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 0);
		XtSetValues(pushButton99,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 45);
		XtSetValues(pushButton100,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 90);
		XtSetValues(pushButton101,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 135);
		XtSetValues(pushButton102,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  180");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 180);
		XtSetValues(pushButton103,args,2);
    		XmStringFree(xmstr);
	}

	if (sc_conf.constrain_kappa == 180) {
    		Arg args[2];
   		XmString xmstr;

		/* Run(s) */
		xmstr = XmStringCreateSimple("-135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -135);
		XtSetValues(pushButton162,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -90);
		XtSetValues(pushButton163,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -45);
		XtSetValues(pushButton164,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  0");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 0);
		XtSetValues(pushButton165,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 45);
		XtSetValues(pushButton166,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 90);
		XtSetValues(pushButton167,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 135);
		XtSetValues(pushButton168,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  180");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 180);
		XtSetValues(pushButton169,args,2);
    		XmStringFree(xmstr);

		/* Manual Control */
		xmstr = XmStringCreateSimple("-135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -135);
		XtSetValues(pushButton179,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -90);
		XtSetValues(pushButton181,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -45);
		XtSetValues(pushButton183,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  0");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 0);
		XtSetValues(pushButton184,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 45);
		XtSetValues(pushButton185,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 90);
		XtSetValues(pushButton186,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 135);
		XtSetValues(pushButton187,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  180");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 180);
		XtSetValues(pushButton188,args,2);
    		XmStringFree(xmstr);
	}

	if (sc_conf.constrain_omega == 180) {
    		Arg args[2];
   		XmString xmstr;

		/* Run(s) */
		xmstr = XmStringCreateSimple("-135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -135);
		XtSetValues(pushButton170,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -90);
		XtSetValues(pushButton171,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -45);
		XtSetValues(pushButton172,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  0");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 0);
		XtSetValues(pushButton173,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 45);
		XtSetValues(pushButton174,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 90);
		XtSetValues(pushButton175,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 135);
		XtSetValues(pushButton176,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  180");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 180);
		XtSetValues(pushButton177,args,2);
    		XmStringFree(xmstr);

		/* Manual Control */
		xmstr = XmStringCreateSimple("-135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -135);
		XtSetValues(pushButton189,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -90);
		XtSetValues(pushButton190,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("-45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, -45);
		XtSetValues(pushButton191,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  0");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 0);
		XtSetValues(pushButton192,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  45");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 45);
		XtSetValues(pushButton193,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  90");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 90);
		XtSetValues(pushButton194,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  135");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 135);
		XtSetValues(pushButton195,args,2);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("  180");
		XtSetArg(args[0], XmNlabelString, xmstr);
    		XtSetArg(args[1], XmNuserData, 180);
		XtSetValues(pushButton196,args,2);
    		XmStringFree(xmstr);
	}
	if(sc_conf.t2k_detector == 1)
	{
    		Arg args[2];
   		XmString xmstr;

		/*
		 * XtUnmanageChild(strategy_fast_toggleButton);
		 * XtUnmanageChild(strategy_slow_toggleButton);
		 * XtUnmanageChild(snap_fast_toggleButton);
		 * XtUnmanageChild(snap_slow_toggleButton);
		 */
		xmstr = XmStringCreateSimple("Binning Type:");
		XtSetArg(args[0], XmNlabelString, xmstr);
		XtSetValues(strategy_adc_label, args, 1);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("SW");
		XtSetArg(args[0], XmNlabelString, xmstr);
		XtSetValues(strategy_slow_toggleButton, args, 1);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("HW");
		XtSetArg(args[0], XmNlabelString, xmstr);
		XtSetValues(strategy_fast_toggleButton, args, 1);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("Mode:");
		XtSetArg(args[0], XmNlabelString, xmstr);
		XtSetValues(status_adc_label, args, 1);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("Binning Type:");
		XtSetArg(args[0], XmNlabelString, xmstr);
		XtSetValues(snap_adc_label, args, 1);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("SW");
		XtSetArg(args[0], XmNlabelString, xmstr);
		XtSetValues(snap_slow_toggleButton, args, 1);
    		XmStringFree(xmstr);

		xmstr = XmStringCreateSimple("HW");
		XtSetArg(args[0], XmNlabelString, xmstr);
		XtSetValues(snap_fast_toggleButton, args, 1);
    		XmStringFree(xmstr);

		XmToggleButtonSetState(snap_bin1_toggleButton, False, False);
		XmToggleButtonSetState(snap_bin2_toggleButton, True, False);
 
	}
	if(sc_conf.usestop_immediate == 1)
	{
		XtSetSensitive(stopnowButton,True);
	}
	
/* PF Start */
	if(sc_conf.pf_mod == 1)
	{
		XtUnmanageChild(snap_axis_label);
		XtUnmanageChild(snapshot_axis);
		XtUnmanageChild(snap_axisOmega_toggleButton);
		XtUnmanageChild(snap_axisPhi_toggleButton);

		if(0)
		{
		XtManageChild(snap_energy_label);
		XtManageChild(snap_wave_label);
		XtManageChild(snap_energy_textField);
		XtManageChild(snap_wave_textField);
		}

		XtManageChild(status_label_energy);
		XtManageChild(status_label_wavelength);
		XtManageChild(status_energy_textField);
		XtManageChild(status_wavelength_textField);

		XtSetSensitive(drive_energy_pushButton,True);
		XtSetSensitive(define_energy_pushButton,True);
		XmToggleButtonSetState(drive_energy_pushButton,True,False);
		XmToggleButtonSetState(define_energy_pushButton,False,False);

		XtManageChild(strategy_autoal_label);
		XtManageChild(strategy_autoalevery_mode);
		XtManageChild(strategy_slit_label);
		XtManageChild(strategy_vslit_label);
		XtManageChild(strategy_hslit_label);
		XtManageChild(strategy_vslit_textField);
		XtManageChild(strategy_hslit_textField);
		XmTextFieldSetString(strategy_hslit_textField, "0.100");
		XmTextFieldSetString(strategy_vslit_textField, "0.100");

		XtManageChild(strategy_energy_label);
		XtUnmanageChild(strategy_phi_label);
		XtManageChild(strategy_atten_label);
		XtUnmanageChild(strategy_kappa_label);

		XtUnmanageChild(mc_drive_phi_radioBox);
		XtUnmanageChild(mc_drive_kappa_radioBox);
		XtUnmanageChild(mc_drive_phi_label);
		XtUnmanageChild(mc_drive_kappa_label);
		XtUnmanageChild(modify_phi_textField);
		XtUnmanageChild(modify_kappa_textField);
		XtUnmanageChild(mc_phi_apply);
		XtUnmanageChild(mc_kappa_apply);

		XtManageChild(mc_autoal_label);
		XtManageChild(mc_autoal_form);

		XtUnmanageChild(mc_wavelength_radioBox);
		XtUnmanageChild(mc_energy_radioBox);
		XmTextFieldSetString(mc_autoal_slit_textField, "0.1");
		XmToggleButtonSetState(strategy_autoaleveryno_toggleButton, True, False);
		XmToggleButtonSetState(strategy_autoaleveryyes_toggleButton, False, False);
		
	}
	else
	{
		XtUnmanageChild(mc_modify_energy_textField);
		XtUnmanageChild(mc_energy_apply);
		XtUnmanageChild(mc_energy_label);
		XtUnmanageChild(mc_energy_radioBox);
		XtUnmanageChild(drive_energy_pushButton);
		XtUnmanageChild(define_energy_pushButton);
		XtUnmanageChild(mc_atten_button);
		XtUnmanageChild(mc_atten_pulldownMenu);
	}

/* driveto_centering */

	if(sc_conf.driveto_centering)
	{
		XtUnmanageChild(driveby_form);
		XtUnmanageChild(driveby_label);
		XtManageChild(driveto_form);
		XtManageChild(driveto_label);
	}

/* PF End */

/* ADSC_SLIT and PF Start */
	
	if(sc_conf.adsc_slit == 1 || sc_conf.pf_mod == 1)
	{
		XmToggleButtonSetState(mc_vs_drive_pushButton,True,False);
		XmToggleButtonSetState(mc_hs_drive_pushButton,True,False);
	}

	if(sc_conf.adsc_4slit == 1)
	{
		XmToggleButtonSetState(mc_guard_vs_drive_pushButton,True,False);
		XmToggleButtonSetState(mc_guard_hs_drive_pushButton,True,False);
	}

	if(sc_conf.adsc_slit == 1 && sc_conf.pf_mod == 0)
	{
		XmToggleButtonSetState(mc_v_up_halfslit_out_pushButton,True,False);
		if(0)
		XmToggleButtonSetState(mc_v_up_halfslit_in_pushButton,False,False);

		XmToggleButtonSetState(mc_h_up_halfslit_out_pushButton,True,False);
		if(0)
		XmToggleButtonSetState(mc_h_up_halfslit_in_pushButton,False,False);

		XmToggleButtonSetState(mc_v_dn_halfslit_out_pushButton,True,False);
		if(0)
		XmToggleButtonSetState(mc_v_dn_halfslit_in_pushButton,False,False);

		XmToggleButtonSetState(mc_h_dn_halfslit_out_pushButton,True,False);
		if(0)
		XmToggleButtonSetState(mc_h_dn_halfslit_in_pushButton,False,False);

	}

/* ADSC_SLIT and PF End */

	read_configurable_file();

	if (sc_conf.wavelength <= 0)
		site_wavelength = 1.5418;
	else
		site_wavelength = sc_conf.wavelength;

	TextFieldSetFloat4(wavelength1_textField,site_wavelength);
	site_energy = wavelength_to_energy(site_wavelength);
	TextFieldSetFloat(energy1_textField,site_energy);

	TextFieldSetFloat4(wavelength2_textField,0.0);
	TextFieldSetFloat4(wavelength3_textField,0.0);
	TextFieldSetFloat4(wavelength4_textField,0.0);
	TextFieldSetFloat4(wavelength5_textField,0.0);
	TextFieldSetFloat(energy2_textField,0.0);
	TextFieldSetFloat(energy3_textField,0.0);
	TextFieldSetFloat(energy4_textField,0.0);
	TextFieldSetFloat(energy5_textField,0.0);

	XmToggleButtonSetState(enable_wavelength1_toggleButton,True,False);
	XmToggleButtonSetState(enable_wavelength2_toggleButton,False,False);
	XmToggleButtonSetState(enable_wavelength3_toggleButton,False,False);
	XmToggleButtonSetState(enable_wavelength4_toggleButton,False,False);
	XmToggleButtonSetState(enable_wavelength5_toggleButton,False,False);

	XmToggleButtonSetState(mad_option1_toggleButton,True,False);
	XmToggleButtonSetState(mad_option2_toggleButton,False,False);
	XmToggleButtonSetState(mad_option3_toggleButton,False,False);
	XmToggleButtonSetState(mad_option4_toggleButton,False,False);

	XtSetSensitive(energy1_textField,True);
	XtSetSensitive(wavelength1_textField,True);
	XtSetSensitive(energy2_textField,False);
	XtSetSensitive(wavelength2_textField,False);
	XtSetSensitive(energy3_textField,False);
	XtSetSensitive(wavelength3_textField,False);
	XtSetSensitive(energy4_textField,False);
	XtSetSensitive(wavelength4_textField,False);
	XtSetSensitive(energy5_textField,False);
	XtSetSensitive(wavelength5_textField,False);

	TextFieldSetInt(mad_nframes_textField,10);

	if (beamline_mode==True) {
		setup_beamline_mode();
	}

	ai_hostname[0] = '\0';
	ai_port = -1;
	ai_fd = -1;

	if(NULL != (tstr = (char *) getenv("CCD_AIHOSTNAME")))
	{
		if(NULL != (tstr = (char *) getenv("CCD_AIPORT")))
		{
			ai_port = atoi(tstr);
			strcpy(ai_hostname, (char *) getenv("CCD_AIHOSTNAME"));
			fprintf(stdout,"ai: Hostname: %s with port number: %d: try to connect\n", ai_hostname, ai_port);
			ai_fd = connect_to_host_silent(&ai_fd, ai_hostname, ai_port, NULL);
			fprintf(stdout,"ai: ai_fd after connect: %d\n", ai_fd);
		}
	}
#define START_TIMER
#ifdef START_TIMER
         XtAppAddTimeOut(XtWidgetToApplicationContext(statusDialog),
		(long)TIMER_MSEC, /* milliseconds */
		timer_func, NULL);
#endif /* START_TIMER */

	/* Initialize to some values */
	current_distance = 100.0;
	current_phi = 0.0;
	current_offset = 0.0;
	delta_phi = 1.0;

	if ( (sc_conf.wavelength > 0) && (sc_conf.wavelength < 10.0)) {
		wavelength = sc_conf.wavelength;
		TextFieldSetFloat4(wavelength_textField,wavelength);
	}

	if (debug) {
		fprintf(stderr,"wavelength = %f\n",wavelength);
		fprintf(stderr,"sc_conf.wavelength = %f\n",sc_conf.wavelength);
		fflush(stderr);
	}

	for(i=0; i < MAX_RUNS; i++) {
		Run[i].nframes = 0;
	}

	set_fSB_colors(load_method_fSB);
	set_fSB_colors(save_method_fSB);
	set_fSB_colors(delete_method_fSB);

	/* Turn off Bell */

	XtSetArg(args[0], XmNverifyBell, False);

	XtSetValues(snap_directory_textField,args,1);
	XtSetValues(snap_image_textField,args,1);
	XtSetValues(snap_distance_textField,args,1);
	XtSetValues(snap_offset_textField,args,1);
	XtSetValues(snap_phi_textField,args,1);
	XtSetValues(snap_step_size_textField,args,1);
	XtSetValues(snap_exposure_time_textField,args,1);

	mvc_return = 1;
	init_text(runtext);
	mvc_return = 0;

	if (strcmp(marcollectfile,"")) {
		mvc_return = 1;
		load_XmText(runtext, marcollectfile);
		mvc_return = 0;
	}

	if (!strcmp(marstatusfile,""))
		return;

	if (marstatusfp != NULL) {
		fprintf(stderr,"Warning: marstatusfp not NULL...\n");
		fflush(stderr);
		fclose(marstatusfp);
	}
	else {
		marstatusfp = fopen(marstatusfile,"r");
		if (marstatusfp == NULL) {
			sprintf(buf,"adx_ccd_control: init_adx: Cannot open status file: %s\n", marstatusfile);
			emess(buf);
			return;
		}
	}

	while(fgets(buf,1024,marstatusfp)!=NULL){

		/* Skip blank lines */
		if (iswhite(buf))
			continue;

		/* Get rid of trailing white space */
		while(isspace(buf[strlen(buf)-1]) )
			buf[strlen(buf)-1]= (char)NULL;

		strcpy(key,"");
		strcpy(value,"");
		sscanf(buf,"%s%s",key,value);
		if(!strncmp(key,"filename",8)){
			break;
		}
	}
	fclose(marstatusfp); marstatusfp = NULL;

	run = get_run_number(value) ;
	frame = get_frame_number(value) ;

	tstr = (char *)XmTextGetString(runtext);
	for(i=strlen(tstr);i--;) {
		if (!isspace(tstr[i]))
			break;
	}
	XtFree(tstr);
	if (i > 0)
		nrows = find_row(runtext,i)+1;
	else
		nrows = 0;

	/* Try to find "run" and "frame" in runtext
	 */

	for(i=0;i<nrows;i++) {	
		int start, total;
		double phi, delta_phi;

		extract_field(runtext,buf,i,0); /* Run */
		if (atoi(buf) == run) { /* Found Run */
			extract_field(runtext,buf,i,1); /* Start */
			start = atoi(buf);
			extract_field(runtext,buf,i,2); /* Total */
			total = atoi(buf);
			if ((frame > start) && (frame <= start+total)) { /* Found it */

				for(j=0;j<i;j++) /* Delete Previous Runs */
					XmTextReplace(runtext, 0, 0, "D");
				
				mvc_return=1;
				sprintf(buf,"%d",frame);
				insert_field(runtext,buf,0,1);		/* Start */
				sprintf(buf,"%d",total-(frame-start));
				insert_field(runtext,buf,0,2);		/* Total */

				extract_field(runtext,buf,0,5); /* Phi */
				phi = atof(buf);
				extract_field(runtext,buf,0,6); /* Delta Phi */
				delta_phi = atof(buf);
				sprintf(buf,"%1.2f",phi + (frame - start)*delta_phi);
				insert_field(runtext,buf,0,5);
				mvc_return=0;
				break;
			}
		}
	}

	if (show_xray_label == False) {
		XtUnmanageChild(xray_on_label);
		XtUnmanageChild(xray_on_label2);
		XtUnmanageChild(xray_off_label);
		XtUnmanageChild(xray_off_label2);
	}

	if (nocontrol==True) {
		disable_control();
	}
}

set_fSB_colors(fSB)
Widget fSB;
{
	int argcnt, argok;
	Widget w, parent;
    	Arg args[32];

	parent = XtParent(fSB);

	argcnt=0;
	w = XmFileSelectionBoxGetChild(fSB, XmDIALOG_DIR_LIST);
	XtSetArg(args[argcnt], XmNbackground, 
		CONVERT(parent,"White", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNtopShadowColor, 
		CONVERT(parent,"Grey65", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNbottomShadowColor, 
		CONVERT(parent,"Black", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNhighlightThickness, 0); argcnt++;
	XtSetArg(args[argcnt], XmNshadowThickness, 1); argcnt++;
	XtSetValues(w,args,argcnt);

	argcnt=0;
	w = XmFileSelectionBoxGetChild(fSB, XmDIALOG_FILTER_TEXT);
	XtSetArg(args[argcnt], XmNbackground, 
		CONVERT(parent,"White", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNtopShadowColor, 
		CONVERT(parent,"Grey65", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNbottomShadowColor, 
		CONVERT(parent,"Black", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNhighlightThickness, 0); argcnt++;
	XtSetArg(args[argcnt], XmNshadowThickness, 1); argcnt++;
	XtSetValues(w,args,argcnt);

	argcnt=0;
	w = XmFileSelectionBoxGetChild(fSB, XmDIALOG_LIST);
	XtSetArg(args[argcnt], XmNbackground, 
		CONVERT(parent,"White", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNtopShadowColor, 
		CONVERT(parent,"Grey65", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNbottomShadowColor, 
		CONVERT(parent,"Black", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNhighlightThickness, 0); argcnt++;
	XtSetArg(args[argcnt], XmNshadowThickness, 1); argcnt++;
	XtSetValues(w,args,argcnt);

	argcnt=0;
	w = XmFileSelectionBoxGetChild(fSB, XmDIALOG_TEXT);
	XtSetArg(args[argcnt], XmNbackground, 
		CONVERT(parent,"White", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNtopShadowColor, 
		CONVERT(parent,"Grey65", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNbottomShadowColor, 
		CONVERT(parent,"Black", "Pixel", 0, &argok)); argcnt++;
	XtSetArg(args[argcnt], XmNhighlightThickness, 0); argcnt++;
	XtSetArg(args[argcnt], XmNshadowThickness, 1); argcnt++;
	XtSetValues(w,args,argcnt);

	/* SEGV
	w = XmFileSelectionBoxGetChild(fSB, XmDIALOG_WORK_AREA);
	XtSetArg(args[argcnt], XmNbackground, 
		CONVERT(parent,"White", "Pixel", 0, &argok)); 
	XtSetValues(w,args,1);
	*/

	argcnt=0;
	w = XmFileSelectionBoxGetChild(fSB, XmDIALOG_APPLY_BUTTON);
	XtSetArg(args[argcnt], XmNbackground, 
		CONVERT(parent,"Peach Puff", "Pixel", 0, &argok)); argcnt++;
	XtSetValues(w,args,argcnt);

	argcnt=0;
	w = XmFileSelectionBoxGetChild(fSB, XmDIALOG_CANCEL_BUTTON);
	XtSetArg(args[argcnt], XmNbackground, 
		CONVERT(parent,"Peach Puff", "Pixel", 0, &argok)); argcnt++;
	XtSetValues(w,args,argcnt);

	argcnt=0;
	w = XmFileSelectionBoxGetChild(fSB, XmDIALOG_DEFAULT_BUTTON);
	XtSetArg(args[argcnt], XmNbackground, 
		CONVERT(parent,"Peach Puff", "Pixel", 0, &argok)); argcnt++;
	XtSetValues(w,args,argcnt);
	
	argcnt=0;
	w = XmFileSelectionBoxGetChild(fSB, XmDIALOG_HELP_BUTTON);
	XtSetArg(args[argcnt], XmNbackground, 
		CONVERT(parent,"Peach Puff", "Pixel", 0, &argok)); argcnt++;
	XtSetValues(w,args,argcnt);
}

void
timer_func()
{
	void timer_func();
	void ai_server_update();
	int  connect_to_host_silent();
	static int count=0;

	if(ai_port != -1 && ai_hostname[0] != '\0')
	{
		if(ai_fd == -1)
			ai_fd = connect_to_host_silent(&ai_fd, ai_hostname, ai_port, NULL);
		if(ai_fd != -1)
			ai_server_update();
	}
	if (calculating_strategy) 
		check_strategy_file();

	update_status(count++); /* Update the Status Window */

	/*
	if (!(count++ % 100))
		fprintf(stderr,"Called timer_func.\n");
	 */

         XtAppAddTimeOut(XtWidgetToApplicationContext(statusDialog),
		(long)TIMER_MSEC, /* milliseconds */
		timer_func, NULL);
}

read_config_file()
{
	char marconfigfile[256], str[256], field1[32], field2[32], *ptr;
	FILE *fp;

	sc_conf.usewavelength = 1;

	if (debug) {
		fprintf(stderr,"read_config_file\n");
		fflush(stderr);
	}
	if (getenv("CCD_DC_CONFIG") == NULL) {
		emess("Warning: environment variable CCD_DC_CONFIG not set");
		return;
	}
	else {
		strcpy(marconfigfile,getenv("CCD_DC_CONFIG"));
	}

	/* Determine ccd type (single module or 2x2)
	 */
	if (getenv("CCD_N_CTRL") == NULL) {
		emess("Warning: environment variable CCD_N_CTRL not set");
		configuration = CONFIG_DEFAULT;
	}
	else {
		configuration = atoi(getenv("CCD_N_CTRL"));
		if (configuration == 1)
			configuration = CONFIG_1x1;
		else
		if (configuration == 4)
			configuration = CONFIG_2x2;
		else
		if (configuration == 9)
			configuration = CONFIG_3x3;
		else {
			emess("Warning: bad setting for CCD_N_CTRL");
			configuration = CONFIG_DEFAULT;
		}
	}

	if ((fp = fopen(marconfigfile,"r"))==NULL) {
		sprintf(tmpstr,"Warning: Can not open file %s",marconfigfile);
		emess(tmpstr);
		return;
	}

	sc_conf.constrain_phi = 360;
	sc_conf.constrain_kappa = 360;
	sc_conf.constrain_omega = 360;
	sc_conf.usezero_angles = 1;
	sc_conf.usegon_manual = 1;
	sc_conf.daemon_exit = 0;
	sc_conf.t2k_detector = 0;
	sc_conf.pf_mod = 0;
	sc_conf.adsc_slit = 0;
	sc_conf.adsc_4slit = 0;
	sc_conf.usestop_immediate = 0;
	sc_conf.driveto_centering = 0;

	XmToggleButtonSetState(snap_dez_yes_toggleButton,False,False);
	XmToggleButtonSetState(snap_dez_no_toggleButton,True,False);

	while(fgets(str,sizeof(str),fp) != NULL) {
		ptr = str;
		while(*ptr && isspace(*ptr))
			ptr++;
		if (*ptr) {
			if (ptr[0] == '#') /* comment line */
				continue;
			else {
				sscanf(ptr,"%s%s\n",field1,field2);

				if (!strcmp(field1,"read_fast")) {
					sc_conf.read_fast = atof(field2);
				}
				else
				if (!strcmp(field1,"read_slow")) {
					sc_conf.read_slow = atof(field2);
				}
				else
				if (!strcmp(field1,"read_overhead")) {
					sc_conf.read_overhead = atof(field2);
				}
				else
				if (!strcmp(field1,"bin_factor")) {
					sc_conf.bin_factor = atof(field2);
				}
				else
				if (!strcmp(field1,"blocks")) {
					sc_conf.blocks = atoi(field2);
				}
				else
				if (!strcmp(field1,"pixelsx")) {
					sc_conf.pixelsx = atoi(field2);
				}
				else
				if (!strcmp(field1,"pixelsy")) {
					sc_conf.pixelsy = atoi(field2);
				}
				else
				if (!strcmp(field1,"pixel_size")) {
					sc_conf.pixelsize = atof(field2);
				}
				else
				if (!strcmp(field1,"multiplier")) {
					sc_conf.multiplier = atof(field2);
				}
				else
				if (!strcmp(field1,"phisteps")) {
					sc_conf.phisteps = atoi(field2);
				}
				else
				if (!strcmp(field1,"diststeps")) {
					sc_conf.diststeps = atoi(field2);
				}
				else
				if (!strcmp(field1,"phitop")) {
					sc_conf.phitop = atoi(field2);
				}
				else
				if (!strcmp(field1,"disttop")) {
					sc_conf.disttop = atoi(field2);
				}
				else
				if (!strcmp(field1,"distmax")) {
					sc_conf.distmax = atoi(field2);
				}
				else
				if (!strcmp(field1,"distmin")) {
					sc_conf.distmin = atoi(field2);
				}
				else
				if (!strcmp(field1,"unitsec")) {
					sc_conf.unitsec = atoi(field2);
				}
				else
				if (!strcmp(field1,"unitdose")) {
					sc_conf.unitdose = atoi(field2);
				}
				else
				if (!strcmp(field1,"wavelength")) {
					sc_conf.wavelength = atof(field2);
				}
				else
				if (!strcmp(field1,"usedistance")) {
					sc_conf.usedistance = atoi(field2);
				}
				else
				if (!strcmp(field1,"uselift")) {
					sc_conf.uselift = atoi(field2);
				}
				else
				if (!strcmp(field1,"usetwotheta") || 
				    !strcmp(field1,"use2theta")) {
					sc_conf.usetwotheta = atoi(field2);
				}
				else
				if (!strcmp(field1,"usephi")) {
					sc_conf.usephi = atoi(field2);
				}
				else
				if (!strcmp(field1,"usekappa")) {
					sc_conf.usekappa = atoi(field2);
				}
				else
				if (!strcmp(field1,"useomega")) {
					sc_conf.useomega = atoi(field2);
				}
				else
				if (!strcmp(field1,"usewavelength")) {
					sc_conf.usewavelength = atoi(field2);
				}
				else
				if (!strcmp(field1,"flags")) {
					sc_conf.flags = atoi(field2);
				}
				else
				if (!strcmp(field1,"nc_pointer")) {
					sc_conf.nc_pointer = atoi(field2);
				}
				else
				if (!strcmp(field1,"nc_index")) {
					sc_conf.nc_index = atoi(field2);
				}
				else
				if (!strcmp(field1,"nc_x")) {
					sc_conf.nc_x = atoi(field2);
				}
				else
				if (!strcmp(field1,"nc_y")) {
					sc_conf.nc_y = atoi(field2);
				}
				else
				if (!strcmp(field1,"nc_rec")) {
					sc_conf.nc_rec = atoi(field2);
				}
				else
				if (!strcmp(field1,"nc_poff")) {
					sc_conf.nc_poff = atoi(field2);
				}
				else
				if (!strcmp(field1,"scsi_id")) {
					sc_conf.scsi_id = atoi(field2);
				}
				else
				if (!strcmp(field1,"scsi_controller")) {
					sc_conf.scsi_controller = atoi(field2);
				}
				else
				if (!strcmp(field1,"spiral_check")) {
					sc_conf.spiral_check = atoi(field2);
				}
				else
				if (!strcmp(field1,"liftsteps")) {
					sc_conf.liftsteps = atoi(field2);
					sc_conf.liftsteps = abs(sc_conf.liftsteps);
				}
				else
				if (!strcmp(field1,"lifttop")) {
					sc_conf.lifttop = atoi(field2);
				}
				else
				if (!strcmp(field1,"liftmax")) {
					sc_conf.liftmax = atoi(field2);
				}
				else
				if (!strcmp(field1,"liftmin")) {
					sc_conf.liftmin = atoi(field2);
				}
				else
				if (!strcmp(field1,"dezinger")) {
					sc_conf.dezinger = atoi(field2);
				}
				else
				if (!strcmp(field1,"constrain_omega")) {
					sc_conf.constrain_omega = atoi(field2);
				}
				else
				if (!strcmp(field1,"constrain_phi")) {
					sc_conf.constrain_phi = atoi(field2);
				}
				else
				if (!strcmp(field1,"constrain_kappa")) {
					sc_conf.constrain_kappa = atoi(field2);
				}
				else
				if (!strcmp(field1,"file_overwrite_mode")) {
					file_overwrite_mode = atoi(field2);
				}
				else
				if (!strcmp(field1,"usezero_angles")) {
					sc_conf.usezero_angles = atoi(field2);
				}
				else
				if (!strcmp(field1,"usegon_manual")) {
					sc_conf.usegon_manual = atoi(field2);
				}
				else
				if (!strcmp(field1,"t2k_detector")) {
					sc_conf.t2k_detector = atoi(field2);
				}
				else
				if (!strcmp(field1,"pf_mod")) {
					sc_conf.pf_mod = atoi(field2);
				}
				else
				if (!strcmp(field1,"adsc_slit")) {
					sc_conf.adsc_slit = atoi(field2);
				}
				else
				if (!strcmp(field1,"adsc_4slit")) {
					sc_conf.adsc_4slit = atoi(field2);
				}
				else
				if (!strcmp(field1,"usestop_immediate")) {
					sc_conf.usestop_immediate = atoi(field2);
				}
				else
				if (!strcmp(field1,"driveto_centering")) {
					sc_conf.driveto_centering = atoi(field2);
				}
				else
				if (!strcmp(field1,"daemon_exit")) {
					sc_conf.daemon_exit = atoi(field2);
				}
				else
	if (!strcmp(field1,"dk_before_run")) {
		if ((int)atoi(field2) == 1) {
			XmToggleButtonSetState(options_darkrun_toggleButton,True,False);
		}
		else {
			XmToggleButtonSetState(options_darkrun_toggleButton,False,False);
		}
	}
				else
	if (!strcmp(field1,"repeat_dark")) {
		if ((int)atoi(field2) == 1) {
			XmToggleButtonSetState(options_darkinterval_toggleButton,True,False);
			XtSetSensitive(options_darkinterval_textField, True);
			XtSetSensitive(label32,True);
		}
		else {
			XmToggleButtonSetState(options_darkinterval_toggleButton,False,False);
			XtSetSensitive(options_darkinterval_textField, False);
			XtSetSensitive(label32,False);
		}
	}
	/* ASA */
				else
	if (!strcmp(field1,"outfile_type")) {
		outfile_type = atoi(field2);
		switch  (outfile_type) 
		{
			case 0:
				XmToggleButtonSetState(options_output16_toggleButton,True,False);
				XmToggleButtonSetState(options_output32_toggleButton,False,False);
				XmToggleButtonSetState(options_outputsmv_toggleButton,True,False);
				XmToggleButtonSetState(options_outputcbf_toggleButton,False,False);
				break;
			case 1:
				XmToggleButtonSetState(options_output16_toggleButton,False,False);
				XmToggleButtonSetState(options_output32_toggleButton,True,False);
				XmToggleButtonSetState(options_outputsmv_toggleButton,True,False);
				XmToggleButtonSetState(options_outputcbf_toggleButton,False,False);
				break;
			case 8:
				XmToggleButtonSetState(options_output16_toggleButton,True,False);
				XmToggleButtonSetState(options_output32_toggleButton,False,False);
				XmToggleButtonSetState(options_outputsmv_toggleButton,False,False);
				XmToggleButtonSetState(options_outputcbf_toggleButton,True,False);
				break;
			case 9:
				XmToggleButtonSetState(options_output16_toggleButton,False,False);
				XmToggleButtonSetState(options_output32_toggleButton,True,False);
				XmToggleButtonSetState(options_outputsmv_toggleButton,False,False);
				XmToggleButtonSetState(options_outputcbf_toggleButton,True,False);
				break;
			default:
				fprintf(stderr,"In config: Unknown output format: %d\n",outfile_type);
				fflush(stderr);
				XmToggleButtonSetState(options_output16_toggleButton,False,False);
				XmToggleButtonSetState(options_output32_toggleButton,False,False);
				XmToggleButtonSetState(options_outputsmv_toggleButton,True,False);
				XmToggleButtonSetState(options_outputcbf_toggleButton,False,False);
				break;
		}
				}
				else
	if (!strcmp(field1,"darkinterval")) {
		XmTextFieldSetString(options_darkinterval_textField,field2);
	}
	else
	if (!strcmp(field1,"max_deg_step")) {
		XmTextFieldSetString(options_step_textField,field2);
	}
	else
	if (!strcmp(field1,"output_raws")) {
		if ((int)atoi(field2) == 1) {
			XmToggleButtonSetState(options_saveraw_yes,True,False);
			XmToggleButtonSetState(options_saveraw_no,False,False);
		}
		else {
			XmToggleButtonSetState(options_saveraw_yes,False,False);
			XmToggleButtonSetState(options_saveraw_no,True,False);
		}
	}
	else
	if (!strcmp(field1,"no_transform")) {
		if ((int)atoi(field2) == 1) {
			XmToggleButtonSetState(options_xform_yes,False,False);
			XmToggleButtonSetState(options_xform_no,True,False);
		}
		else {
			XmToggleButtonSetState(options_xform_yes,True,False);
			XmToggleButtonSetState(options_xform_no,False,False);
		}
	}
				else {
					if (debug) {
						sprintf(tmpstr,"Debug: Unknown line in CCD_DC_CONFIG (%s)\n\n%s\n",
							marconfigfile,str);
						emess(tmpstr);
					}
				}
			}
		}
	}

	fclose(fp);

	if ((sc_conf.diststeps <= 0.0) || (sc_conf.distmax <= 0.0) || (sc_conf.distmin <= 0.0)) {
		fprintf(stderr,"Error: Distance: min = %d max = %d steps = %d\n",
			sc_conf.distmin,sc_conf.distmax,sc_conf.diststeps);
		fflush(stderr);
	}
	Limit.distmax = (double)sc_conf.distmax / sc_conf.diststeps;
	Limit.distmin = (double)sc_conf.distmin / sc_conf.diststeps;

	if (sc_conf.uselift == 1) { /* 2-theta offset */
		double temp;
		/*
		if ((sc_conf.liftsteps <= 0.0) || (sc_conf.liftmax <= 0.0) || (sc_conf.liftmin <= 0.0)) {
			fprintf(stderr,"Error: Lift: min = %d max = %d steps = %d\n",
				sc_conf.liftmin,sc_conf.liftmax,sc_conf.liftsteps);
			fflush(stderr);
		}
		*/
		Limit.liftmax = (double)sc_conf.liftmax /sc_conf.liftsteps;
		Limit.liftmin = (double)sc_conf.liftmin /sc_conf.liftsteps;
		if (Limit.liftmin > Limit.liftmax) {
			temp = Limit.liftmin;
			Limit.liftmin = Limit.liftmax;
			Limit.liftmax = temp;
		}
	}
	else {
		XmTextFieldSetString(snap_offset_textField,"0.0");
		XtSetSensitive(snap_offset_textField, False);
		XtSetSensitive(snap_offset_label, False);

		/*XtSetSensitive(mc_offset_label, False);*/
		/*XtSetSensitive(modify_offset_textField, False);*/
		/*XtSetSensitive(mc_offset_radiobox, False);*/
		/*XtSetSensitive(mc_offset_apply, False);*/
		XtSetSensitive(drive_twotheta_pushButton,False);
		XtSetSensitive(define_twotheta_pushButton,True);
		XmToggleButtonSetState(drive_twotheta_pushButton,False,False);
		XmToggleButtonSetState(define_twotheta_pushButton,True,False);
		Limit.liftmax = 0.0;
		Limit.liftmin = 0.0;
	}
	if (debug) {
		fprintf(stderr,"Limits: Dist: %f %f Lift: %f %f\n",
			Limit.distmin,Limit.distmax,Limit.liftmin,Limit.liftmax);
		fflush(stderr);
	}
	if (sc_conf.uselift != 1) { /* offset */
		XtUnmanageChild(status_label_offset);
	}
	if (sc_conf.usetwotheta != 1) { /* 2-theta */
		XtUnmanageChild(status_label_2theta);
	}
	if ((sc_conf.uselift != 1) && (sc_conf.usetwotheta != 1)) {
		XtUnmanageChild(offset_textField);
	}
	if ((sc_conf.uselift == 1) && (sc_conf.usetwotheta == 1)) {
		if(0)
		{
		fprintf(stderr,"Warning: Use both lift and twotheta?\n");
		fflush(stderr);
		}
	}

	if (sc_conf.usekappa == 1) { /* Kappa */
		XtUnmanageChild(snap_label_start_phi);
		XtUnmanageChild(snap_label_delta_phi);
		XtManageChild(snap_label_start_omega);
		XtManageChild(snap_label_delta_omega);

		XmToggleButtonSetState(snap_axisOmega_toggleButton,True,False);
		XmToggleButtonSetState(snap_axisPhi_toggleButton,False,False);
	}
	else {
		XtUnmanageChild(snap_label_start_omega);
		XtUnmanageChild(snap_label_delta_omega);
		XtManageChild(snap_label_start_phi);
		XtManageChild(snap_label_delta_phi);

		XtUnmanageChild(status_label_kappa);
		XtUnmanageChild(kappa_textField);
		XtSetSensitive(drive_kappa_pushButton,False);
		XtSetSensitive(define_kappa_pushButton,True);
		XmToggleButtonSetState(drive_kappa_pushButton,False,False);
		XmToggleButtonSetState(define_kappa_pushButton,True,False);

		XmToggleButtonSetState(snap_axisOmega_toggleButton,False,False);
		XmToggleButtonSetState(snap_axisPhi_toggleButton,True,False);
	}
	if (sc_conf.useomega == 1) { /* Omega */
		/* Should not need to do this... */
		XtManageChild(status_label_omega);
		XtManageChild(omega_textField);
		XtSetSensitive(drive_omega_pushButton,True);
		XtSetSensitive(define_omega_pushButton,True);
		XmToggleButtonSetState(drive_omega_pushButton,True,False);
		XmToggleButtonSetState(define_omega_pushButton,False,False);
	}
	else {
		XtUnmanageChild(status_label_omega);
		XtUnmanageChild(omega_textField);
		XtSetSensitive(drive_omega_pushButton,False);
		XtSetSensitive(define_omega_pushButton,True);
		XmToggleButtonSetState(drive_omega_pushButton,False,False);
		XmToggleButtonSetState(define_omega_pushButton,True,False);
	}
	if (sc_conf.usephi == 1) { /* Phi */
		/* Should not need to do this... */
		XtSetSensitive(drive_phi_pushButton,True);
		XtSetSensitive(define_phi_pushButton,True);
		XmToggleButtonSetState(drive_phi_pushButton,True,False);
		XmToggleButtonSetState(define_phi_pushButton,False,False);
	}
	else {
		XtUnmanageChild(status_label_phi);
		XtUnmanageChild(curr_phi_textField);
		XtSetSensitive(drive_phi_pushButton,False);
		XtSetSensitive(define_phi_pushButton,True);
		XmToggleButtonSetState(drive_phi_pushButton,False,False);
		XmToggleButtonSetState(define_phi_pushButton,True,False);
		XmToggleButtonSetState(snap_axisOmega_toggleButton,True,False);
		XmToggleButtonSetState(snap_axisPhi_toggleButton,False,False);
		XtUnmanageChild(snap_label_start_phi);
		XtUnmanageChild(snap_label_delta_phi);
		XtManageChild(snap_label_start_omega);
		XtManageChild(snap_label_delta_omega);
		XtSetSensitive(snap_axisPhi_toggleButton,False);
	}
	if (sc_conf.usewavelength == 1) { /* Wavelength */
		/* Should not need to do this... */
		XtSetSensitive(drive_wavelength_pushButton,True);
		XtSetSensitive(define_wavelength_pushButton,True);
		XmToggleButtonSetState(drive_wavelength_pushButton,True,False);
		XmToggleButtonSetState(define_wavelength_pushButton,False,False);
	}
	else {
		XtSetSensitive(drive_wavelength_pushButton,False);
		XtSetSensitive(define_wavelength_pushButton,True);
		XmToggleButtonSetState(drive_wavelength_pushButton,False,False);
		XmToggleButtonSetState(define_wavelength_pushButton,True,False);
	}
	if (sc_conf.usedistance == 1) { /* Distance */
		/* Should not need to do this... */
		XtSetSensitive(drive_distance_pushButton,True);
		XtSetSensitive(define_distance_pushButton,True);
		XmToggleButtonSetState(drive_distance_pushButton,True,False);
		XmToggleButtonSetState(define_distance_pushButton,False,False);
	}
	else {
		XtSetSensitive(drive_distance_pushButton,False);
		XtSetSensitive(define_distance_pushButton,True);
		XmToggleButtonSetState(drive_distance_pushButton,False,False);
		XmToggleButtonSetState(define_distance_pushButton,True,False);
	}

	if (sc_conf.usedistance == 1) { /* Distance */
		/* Should not need to do this... */
		XtSetSensitive(drive_distance_pushButton,True);
		XtSetSensitive(define_distance_pushButton,True);
		XmToggleButtonSetState(drive_distance_pushButton,True,False);
		XmToggleButtonSetState(define_distance_pushButton,False,False);
	}
	else {
		XtSetSensitive(drive_distance_pushButton,False);
		XtSetSensitive(define_distance_pushButton,True);
		XmToggleButtonSetState(drive_distance_pushButton,False,False);
		XmToggleButtonSetState(define_distance_pushButton,True,False);
	}

	if (sc_conf.usezero_angles == 0) { /* Zero Angles */
		XtSetSensitive(gonio_home_pushbutton,False);
	}
	else {
		XtSetSensitive(gonio_home_pushbutton,True);
	}
	if (sc_conf.usegon_manual == 0) { /* Goniometer Manual Control */
		XtSetSensitive(gonio_off_pushButton,False);
	}
	else {
		XtSetSensitive(gonio_off_pushButton,True);
	}
}

read_configurable_file()
{
	char marconfigurablefile[256], str[256], field1[32], field2[32], *ptr;
	FILE *fp;
	int nval=0;

	if (debug) {
		fprintf(stderr,"read_configurable_file\n");
		fflush(stderr);
	}
	if (getenv("CCD_DC_CONFIGURABLE") == NULL) {
		/*
		emess("Warning: environment variable CCD_DC_CONFIGURABLE not set");
		 */
		return;
	}
	else {
		strcpy(marconfigurablefile,getenv("CCD_DC_CONFIGURABLE"));
	}

	/* Determine ccd type (single module or 2x2)
	 */

	if ((fp = fopen(marconfigurablefile,"r"))==NULL) {
		sprintf(tmpstr,"Warning: Can not open file %s",marconfigurablefile);
		emess(tmpstr);
		return;
	}

	while(fgets(str,sizeof(str),fp) != NULL && (nval < 10)) {
		ptr = str;
		while(*ptr && isspace(*ptr))
			ptr++;
		if (*ptr) {
			if (ptr[0] == '#') /* comment line */
				continue;
			else {
				strcpy(field1,"");
				strcpy(field2,"");
				sscanf(ptr,"%s%s\n",field1,field2);

			switch  (++nval) 
			{
				case 1:
					XmTextFieldSetString(configsite_textKey1,field1);
					XmTextFieldSetString(configsite_textVal1,field2);
				break;
				case 2:
					XmTextFieldSetString(configsite_textKey2,field1);
					XmTextFieldSetString(configsite_textVal2,field2);
				break;
				case 3:
					XmTextFieldSetString(configsite_textKey3,field1);
					XmTextFieldSetString(configsite_textVal3,field2);
				break;
				case 4:
					XmTextFieldSetString(configsite_textKey4,field1);
					XmTextFieldSetString(configsite_textVal4,field2);
				break;
				case 5:
					XmTextFieldSetString(configsite_textKey5,field1);
					XmTextFieldSetString(configsite_textVal5,field2);
				break;
				case 6:
					XmTextFieldSetString(configsite_textKey6,field1);
					XmTextFieldSetString(configsite_textVal6,field2);
				break;
				case 7:
					XmTextFieldSetString(configsite_textKey7,field1);
					XmTextFieldSetString(configsite_textVal7,field2);
				break;
				case 8:
					XmTextFieldSetString(configsite_textKey8,field1);
					XmTextFieldSetString(configsite_textVal8,field2);
				break;
				case 9:
					XmTextFieldSetString(configsite_textKey9,field1);
					XmTextFieldSetString(configsite_textVal9,field2);
				break;
				case 10:
					XmTextFieldSetString(configsite_textKey10,field1);
					XmTextFieldSetString(configsite_textVal10,field2);
				break;
			}
			}
		}
	}

	fclose(fp);
}

setup_beamline_mode()
{
	Arg          args[2];
	FILE *marblfp;
	char marblfile[256];
	char str[256];
	int width, maxlen=0;

	XtSetArg(args[0], XmNwidth, 688+S_WIDTH);
	XtSetValues(strategyDialog,args,1);

	XtSetArg(args[0], XmNx, 620+S_WIDTH);
	XtSetValues(strategy_close_pushbutton,args,1);

	XtSetArg(args[0], XmNx, 550+S_WIDTH);
	XtSetValues(strategy_collect_Pushbutton,args,1);

	XtSetArg(args[0], XmNwidth, 688+S_WIDTH);
	XtSetValues(menuBar,args,1);

	/* In callbacks-c.c */
	/*
	XtSetArg(args[0], XmNwidth, 480+S_WIDTH);
	XtSetValues(runtext,args,1);
	XtSetArg(args[0], XmNwidth, 499+S_WIDTH);
	XtSetValues(scrolledWindow1,args,1);
	 */

	XtSetArg(args[0], XmNx, 680);
	XtSetArg(args[1], XmNy, 264);
	XtSetValues(beamline_label,args,2);
	XtManageChild(beamline_label);

	XtSetArg(args[0], XmNx, 663);
	XtSetArg(args[1], XmNy, 55);
	XtSetValues(bl_scrolledwindow,args,2);
	XtManageChild(bl_scrolledwindow);

	XmListDeleteAllItems (beamline_list);
	if (getenv("MARBEAMLINEFILE") != NULL) 
		strcpy(marblfile,getenv("MARBEAMLINEFILE"));
	else {
		emess("Warning: environment variable MARBEAMLINEFILE not set");
		return;
	}
	marblfp = fopen(marblfile,"r");
	if( marblfp == NULL)
		  emess("Warning: Cannot open MARBEAMLINEFILE");
	else {
		XmString items[1];

		while(fgets(str,256,marblfp) != NULL ) {
			items[0] = XmStringCreateSimple(str);
			XmListAddItems (beamline_list, items, 1, 0); /* last item */
			XmStringFree(items[0]);
			if(strlen(str) > maxlen)
				maxlen = strlen(str);
		}
	}

	/* ~10 pixels per char */
	width = 10*(maxlen+1);
	if (width > 215) {
    		XtSetArg(args[0], XmNwidth, width); 
		XtSetValues(beamline_list,args,1);
	}
}

usage() {
	fprintf(stderr,"Usage: adx [-debug] [-software_mode] [-define_distance] [-define_offset] [-beamline]\n");
	fflush(stderr);
	exit(1);
}

check_strategy_file()
{
	FILE *fp;
	char *proc_directory;

	proc_directory = (char *)XmTextFieldGetString(project_proc_dir_textField);

	strcpy(tmpstr,proc_directory);
	XtFree(proc_directory);
	strcat(tmpstr,"/");
	strcat(tmpstr,"dz_optimal_results");
	remove_white(tmpstr);

	fp = fopen(tmpstr,"r");
	if (fp == NULL)
		return;

	calculating_strategy=0;
	XtSetSensitive(optimize_apply_Pushbutton1,True);
	load_XmText2(optimimal_runs_text,fp);
	fclose(fp);
	remove(tmpstr);

}

load_XmText2(w, fp)
Widget w;
FILE *fp;
{
	char buf[BUFSIZ];
	int pos;

	/* Clear existing text... */
	XmTextReplace(w, 0, XmTextGetLastPosition(w), "");

	for (pos = 0; fgets(buf, sizeof(buf), fp); ) {
		XmTextReplace(w, pos, pos, buf);
		pos += strlen(buf);
	}
	return(0);
}


myfunc()
{
	fprintf(stderr,"TEST\n"); fflush(stderr);
}


write_configurable_file()
{
	char marconfigurablefile[256], str[256], *field1, *field2;
	char buf[2048];
	FILE *fp;

	if (debug) {
		fprintf(stderr,"write_configurable_file\n");
		fflush(stderr);
	}
	if (getenv("CCD_DC_CONFIGURABLE") == NULL) {
		emess("Warning: environment variable CCD_DC_CONFIGURABLE not set");
		return;
	}
	else {
		strcpy(marconfigurablefile,getenv("CCD_DC_CONFIGURABLE"));
	}

	if ((fp = fopen(marconfigurablefile,"w"))==NULL) {
		sprintf(tmpstr,"Warning: Can not open file %s",marconfigurablefile);
		emess(tmpstr);
		return;
	}

	sprintf(buf,"reconfig\n");

	field1 = (char *)XmTextFieldGetString(configsite_textKey1);
	field2 = (char *)XmTextFieldGetString(configsite_textVal1);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	field1 = (char *)XmTextFieldGetString(configsite_textKey2);
	field2 = (char *)XmTextFieldGetString(configsite_textVal2);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	field1 = (char *)XmTextFieldGetString(configsite_textKey3);
	field2 = (char *)XmTextFieldGetString(configsite_textVal3);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	field1 = (char *)XmTextFieldGetString(configsite_textKey4);
	field2 = (char *)XmTextFieldGetString(configsite_textVal4);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	field1 = (char *)XmTextFieldGetString(configsite_textKey5);
	field2 = (char *)XmTextFieldGetString(configsite_textVal5);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	field1 = (char *)XmTextFieldGetString(configsite_textKey6);
	field2 = (char *)XmTextFieldGetString(configsite_textVal6);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	field1 = (char *)XmTextFieldGetString(configsite_textKey7);
	field2 = (char *)XmTextFieldGetString(configsite_textVal7);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	field1 = (char *)XmTextFieldGetString(configsite_textKey8);
	field2 = (char *)XmTextFieldGetString(configsite_textVal8);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	field1 = (char *)XmTextFieldGetString(configsite_textKey9);
	field2 = (char *)XmTextFieldGetString(configsite_textVal9);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	field1 = (char *)XmTextFieldGetString(configsite_textKey10);
	field2 = (char *)XmTextFieldGetString(configsite_textVal10);
	if (!iswhite(field1) && !iswhite(field2)) {
		fprintf(fp,"%s	%s\n",field1,field2);
		sprintf(buf+strlen(buf), "%s  %s\n",field1,field2);
	}
	XtFree(field1);
	XtFree(field2);

	fclose (fp);

	if (!iswhite(buf) && (marcommandfp != NULL)) {
		strcat(buf,"eoc\n");
		fputs(buf,marcommandfp);
		fflush(marcommandfp);
	}
}

