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

wm title . "BLU-ICE    Beamline 7-1"

set gDevice(i0,afterShutter) 0
set gDevice(i1,afterShutter) 0
set gDevice(i2,afterShutter) 0
set gDevice(i_sample,afterShutter) 1
set gDevice(i_beamstop,afterShutter) 1
set gDevice(i5,afterShutter) 1

set gDevice(beamline)  "SSRL BL7-1"
set gPhoto(gonio)	[ image create photo -file "$BLC_IMAGES/gonio.gif" -palette "8/8/8"]

proc define_component_mdw_documents {} {

	create_mdw_document table "Table" 630 310 construct_new_table_window
	create_mdw_document mirror "Mirror" 660 360 construct_11_mirror_window
	create_mdw_document	mono "Monochromator" 815 400 construct_11_mono_window
	create_mdw_document	gonio "Goniometer" 980 355 construct_gonio_window
	create_mdw_document	detector "Detector" 800 400 construct_detector_window
	create_mdw_document	frontend_slits "Hutch Frontend Slits" 1100 360 construct_frontend_slits_window
	create_mdw_document	frontend_aperatures "Frontend Aperatures" 1100 360 construct_frontend_aperature_window
	create_mdw_document	spare "Spare Motors" 347 170 construct_spare_window
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
	create_real_motor		table_horz_1	th1	table		" mm $gFont(micron) "
	create_real_motor   	table_horz_2	th2	table		" mm $gFont(micron) "
	create_pseudo_motor	table_vert		tv		table		" mm $gFont(micron) "
	create_pseudo_motor	table_horz		th		table		" mm $gFont(micron) "
	create_pseudo_motor 	table_pitch		tp		table		{ deg mrad }
	create_pseudo_motor 	table_yaw		ty		table		{ deg mrad }
	create_pseudo_motor	table_h2_z		th2z	default	" mm $gFont(micron) "
	create_pseudo_motor	table_v1_z		tv1z	default	" mm $gFont(micron) "
	create_pseudo_motor	table_v2_z		tv2z	default	" mm $gFont(micron) "
	create_pseudo_motor	table_pivot_z	tpz	default	" mm $gFont(micron) "

	#define mirror
	add_component_menu_entry Mirror mirror
	create_mdw_document mirror "Mirror" 625 420 construct_11_mirror_window
	create_real_motor mirror_vert			miv 	mirror	" mm $gFont(micron) "
	create_real_motor mirror_slit_upper	misu  mirror	" mm $gFont(micron) "
	create_real_motor mirror_slit_lower	misl	mirror	" mm $gFont(micron) "
	create_real_motor mirror_pitch		mip	mirror	{ deg mrad }
	create_real_motor mirror_bend			mib	mirror	" mm "
	create_pseudo_motor	mirror_vert_chin 	mic	mirror 	" mm $gFont(micron) "

	# define monochromator
	add_component_menu_entry Monochromator mono
	create_mdw_document	mono "Monochromator" 815 400 construct_11_mono_window
	create_real_motor		mono_slit			mos	mono	" mm $gFont(micron) "
	create_real_motor		mono_bend			mob	mono	" mm $gFont(micron) "
	create_real_motor		mono_filter			mof	mono	" mm $gFont(micron) "
	create_real_motor		mono_angle			moa	mono	{ deg mrad }
	create_pseudo_motor 	mono_theta			mot	mono	{ deg mrad }
	create_pseudo_motor	energy				e		mono	"eV keV $gFont(angstrom)"	 
	create_pseudo_motor 	d_spacing			ds		default	{ mm }
	create_pseudo_motor 	asymmetric_cut		mot	default	{ deg mrad }
	create_real_motor   	table_slide			ts		mono 		" mm $gFont(micron) "
	create_pseudo_motor 	table_2theta		t2t	mono		{ deg mrad }
	create_pseudo_motor 	table_slide_z		tsz	default		" mm $gFont(micron) "
	
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

	# define spare motors
	add_component_menu_entry "Spare Motors" spare
	create_real_motor		spare_1			s1		spare		" mm $gFont(micron) "
	create_real_motor		spare_2			s2		spare		" mm $gFont(micron) "
	create_real_motor		bpm				bpm	default		" mm $gFont(micron) "

	# define extra motors
	create_real_motor		camera_pan		cp		spare		" mm $gFont(micron) "
	create_real_motor		camera_tilt		ct		spare		" mm $gFont(micron) "
	create_real_motor		beam_stop_vert	bsv	spare		" mm $gFont(micron) "
	create_real_motor		beam_stop_horiz bsh	spare		{ deg mrad }
	create_real_motor		beam_stop_z		bsz	spare		{ deg mrad }	
	create_real_motor		guard_shield_horiz	gsh	spare		" mm $gFont(micron)"	
	create_real_motor		guard_shield_vert	gsv	spare		" mm $gFont(micron)"	

}
