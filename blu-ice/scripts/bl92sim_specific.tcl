#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

wm title . "BLU-ICE    Beamline 9-2   *******SIMULATION*********"

set gDevice(i0,afterShutter) 0
set gDevice(i1,afterShutter) 0
set gDevice(i2,afterShutter) 0
set gDevice(i_sample,afterShutter) 1

set gDevice(beamline)  "SSRL BL9-2"
set gPhoto(gonio)	[ image create photo -file "$BLC_IMAGES/gonio.gif" -palette "8/8/8"]

proc define_component_mdw_documents {} {

	create_mdw_document table "Table" 630 310 construct_new_table_window
	create_mdw_document mirror "Mirror" 660 360 construct_92_mirror_window
	create_mdw_document toroid "Toroid" 520 330 construct_toroid_window
	create_mdw_document	mono "Monochromator" 815 400 construct_92_mono_window
	create_mdw_document	gonio "Goniometer" 980 355 construct_gonio_window
	create_mdw_document	detector "Detector" 800 400 construct_detector_window
	create_mdw_document	slit0 "Stopper Slits" 400 360 construct_slit0_window
	create_mdw_document	frontend_slits "Hutch Frontend Slits" 1100 360 construct_frontend_slits_window
	create_mdw_document	frontend_aperatures "Frontend Aperatures" 1100 360 construct_frontend_aperature_window
	create_mdw_document	spare "Spare Motors" 347 170 construct_spare_window
	create_mdw_document	beamline "Beamline" 800 250 construct_beamline_window
}

proc initialize_components {} {

	# global variables
	global gDevice
	global gFont
	
	set gDevice(components) {}

	# define table
	add_component_menu_entry Table table
	create_real_motor   	table_vert_1	tv1	table 	" mm $gFont(micron) "
	create_real_motor   	table_vert_2	tv2	table 	" mm $gFont(micron) "
	create_real_motor   	table_horz_2	th2	table		" mm $gFont(micron) "
	create_real_motor		table_horz_1	th1	table		" mm $gFont(micron) "
	create_pseudo_motor	table_vert		tv		table		" mm $gFont(micron) "
	create_pseudo_motor	table_horz		th		table		" mm $gFont(micron) "
	create_pseudo_motor 	table_pitch		tp		table		{ deg mrad }
	create_pseudo_motor 	table_yaw		ty		table		{ deg mrad }
	create_pseudo_motor	table_h2_z		th2z	default		" mm $gFont(micron) "
	create_pseudo_motor	table_v1_z		tv1z	default		" mm $gFont(micron) "
	create_pseudo_motor	table_v2_z		tv2z	default    " mm $gFont(micron) "
	create_pseudo_motor	table_pivot_z	tpz	default		" mm $gFont(micron) "

	#define mirror
	add_component_menu_entry Mirror mirror
	create_real_motor mirror_vert			miv 	mirror	" mm $gFont(micron) "
	create_real_motor mirror_slit_upper	misu 	mirror	" mm $gFont(micron) "
	create_real_motor mirror_slit_lower	misl	mirror	" mm $gFont(micron) "
	create_real_motor mirror_pitch		mip	mirror	{ deg mrad }
	create_real_motor mirror_bend			mib	mirror	" mm "
	create_pseudo_motor mirror_vert_chin 	mic	default 	" mm $gFont(micron) "
	create_pseudo_motor mirror_chin_gap mcg default " mm $gFont(micron) "

	#define toroid
	add_component_menu_entry Toroid toroid
	create_real_motor toroid_vert			tov 	toroid	" mm $gFont(micron) "
	create_real_motor toroid_pitch		top	toroid	{ deg mrad }
	create_real_motor toroid_yaw			toy	toroid	{ deg mrad }
	create_real_motor toroid_bend			tob	toroid	" mm "

	# define monochromator
 	add_component_menu_entry Monochromator mono
	create_real_motor 	mono_slit_vert		mosv	mono	" mm $gFont(micron) "
	create_real_motor		mono_slit_lower	mosl	mono	" mm $gFont(micron) "
	create_real_motor 	mono_slit_spear	mosp	mono	" mm $gFont(micron) "
	create_real_motor		mono_slit_ssrl		mosr	mono	" mm $gFont(micron) "
	create_real_motor 	mono_theta			mot	mono	{ deg mrad }
	create_real_motor 	mono_encoder		mot	mono	{ deg mrad }
	create_real_motor 	mono_pitch			mop	mono	{ deg mrad }
	create_real_motor 	mono_roll			mor	mono	{ deg mrad }
	create_pseudo_motor	energy				e		mono	"eV keV $gFont(angstrom)"
	create_pseudo_motor	optimized_energy	oe		default	"eV keV $gFont(angstrom)"

	create_pseudo_motor	energyOptimizeTolerance	oet		default	" % "
	create_pseudo_motor	energyLastTimeOptimized	oelt		default	" s "
	create_pseudo_motor	energyLastOptimized	oe		default	"eV keV $gFont(angstrom)"
	create_pseudo_motor	energyOptimizedTimeout	oe		default	" s "

	create_pseudo_motor  asymmetric_cut		ac		default { deg mrad }
	create_pseudo_motor	d_spacing			ds		default " mm $gFont(micron) "
	create_pseudo_motor  mono_theta_corr   mtc   default { deg mrad }

	# define sample goniometer
	add_component_menu_entry Goniometer gonio
	create_real_motor		gonio_phi		phi	gonio		{ deg }
	create_real_motor		gonio_omega		omega	gonio		{ deg }
	create_real_motor		gonio_kappa 	kappa	gonio		{ deg }
	create_real_motor		gonio_z			gz		detector	" mm $gFont(micron) "
	create_real_motor		sample_x			sx		gonio		" mm $gFont(micron) "
	create_real_motor		sample_y			sy		gonio		" mm $gFont(micron) "
	create_real_motor		sample_z			sz		gonio		" mm $gFont(micron) "

	# define detector gantry
	add_component_menu_entry Detector detector	
	create_real_motor		detector_horz		dh		detector 	" mm $gFont(micron) "
	create_real_motor		detector_pitch		dp		detector 	{ deg mrad }
	create_real_motor		detector_vert		dv		detector 	" mm $gFont(micron) "
	create_real_motor		detector_z			dz		detector 	" mm $gFont(micron) "

	# define beamline
	add_component_menu_entry Beamline beamline	
	create_real_motor		beamline_vert_1	bv1	beamline 	" mm $gFont(micron) "
	create_real_motor		beamline_vert_2	bv2	beamline 	" mm $gFont(micron) "
	
	# define slit_0
	add_component_menu_entry "Stopper Slits" slit0
	create_real_motor		slit_0_upper		s0u	slit0 	" mm $gFont(micron) "
	create_real_motor		slit_0_lower		s0l	slit0 	" mm $gFont(micron) "
	create_real_motor		slit_0_spear		s0sp	slit0 	" mm $gFont(micron) "
	create_real_motor		slit_0_ssrl			s0ss	slit0 	" mm $gFont(micron) "
	#create_pseudo_motor	slit_0_vert_gap	s0vg	slit0 	" mm $gFont(micron) "
	#create_pseudo_motor	slit_0_vert			s0v	slit0 	" mm $gFont(micron) "
	#create_pseudo_motor	slit_0_horiz_gap	s0hg	slit0 	" mm $gFont(micron) "
	#create_pseudo_motor	slit_0_horiz 		s0h	slit0 	" mm $gFont(micron) "	

	# define frontend slits	
	add_component_menu_entry "Frontend Slits" frontend_slits
	create_real_motor		slit_1_upper		s1u	frontend_slits 	" mm $gFont(micron) "
	create_real_motor		slit_1_lower		s1l	frontend_slits 	" mm $gFont(micron) "
	create_real_motor		slit_1_spear		s1sp	frontend_slits 	" mm $gFont(micron) "
	create_real_motor		slit_1_ssrl			s1ss	frontend_slits 	" mm $gFont(micron) "
	create_real_motor		slit_2_upper		s2u	frontend_slits 	" mm $gFont(micron) "
	create_real_motor		slit_2_lower		s2l	frontend_slits 	" mm $gFont(micron) "
	create_real_motor		slit_2_spear		s2sp	frontend_slits 	" mm $gFont(micron) "
	create_real_motor		slit_2_ssrl			s2ss	frontend_slits 	" mm $gFont(micron) "

	# define frontend aperatures
	add_component_menu_entry "Frontend Aperatures" frontend_aperatures
	create_pseudo_motor	slit_1_vert_gap	s1vg	frontend_aperatures 	" mm $gFont(micron) "
	create_pseudo_motor	slit_1_vert			s1v	frontend_aperatures 	" mm $gFont(micron) "
	create_pseudo_motor	slit_1_horiz_gap	s1hg	frontend_aperatures 	" mm $gFont(micron) "
	create_pseudo_motor	slit_1_horiz		s1h	frontend_aperatures 	" mm $gFont(micron) "
	create_pseudo_motor	slit_2_vert_gap	s2vg	frontend_aperatures 	" mm $gFont(micron) "
	create_pseudo_motor	slit_2_vert			s2v	frontend_aperatures 	" mm $gFont(micron) "
	create_pseudo_motor	slit_2_horiz_gap	s2hg	frontend_aperatures 	" mm $gFont(micron) "
	create_pseudo_motor	slit_2_horiz		s2h	frontend_aperatures 	" mm $gFont(micron) "
		
	create_pseudo_motor	beam_size_x			bsx	default 	" mm $gFont(micron) "		
	create_pseudo_motor	beam_size_y			bsy	default 	" mm $gFont(micron) "

	#create_pseudo_motor	doseStoredCounts			doseStoredCounts	default 	" mm $gFont(micron) "
	#create_pseudo_motor	doseLastCounts			doseLastCounts	default 	" mm $gFont(micron) "

	# define spare motors
	add_component_menu_entry "Spare Motors" spare
	create_real_motor		spare_1			s1		spare		" mm $gFont(micron) "
	create_real_motor		spare_2			s2		spare		" mm $gFont(micron) "
	create_real_motor		dac				dac	default		" mm"

	create_real_motor		diagnostic_vert dv		default		" mm"

	create_real_motor		diagnostic_vert dv		default		" mm"
	create_real_motor		guard_shield_horiz	gsh	default		" mm $gFont(micron)"	
	create_real_motor		guard_shield_vert		gsv	default		" mm $gFont(micron)"
	create_real_motor camera_zoom	cz default 	" mm $gFont(micron) "
	create_real_motor		fluorescence_z			fz	default		" mm $gFont(micron)"

	create_pseudo_motor	doseStoredCounts		dsc	default 	" mm $gFont(micron) "
	create_pseudo_motor	doseLastCounts			dlc	default 	" mm $gFont(micron) "
	create_pseudo_motor	doseStabilityRatio	dsr	default 	" % "
	create_pseudo_motor	doseThreshold			dt		default 	" mm $gFont(micron) "
	create_pseudo_motor	doseIntegrationPeriod dip	default 	" s "
	create_pseudo_motor	maxOscTime				mot	default 	" s "

	create_pseudo_motor     box_size               bs      default         "$gFont(micron) "
	create_pseudo_motor     box_size_0             bs0     default         "$gFont(micron) "
	create_pseudo_motor     box_size_1             bs1     default         "$gFont(micron) "

	create_pseudo_motor     attenuation            attn     default         "%"

}


