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


proc initialize_components {} {

	# global variables
	global gDevice
	global gFont
	global gPhoto
	global BLC_IMAGES
	global gBeamline

	# set the relative order of ion chambers versus the shutter
	set gDevice(i0,afterShutter) 0
	set gDevice(i1,afterShutter) 0
	set gDevice(i2,afterShutter) 0
	set gDevice(i_sample,afterShutter) 1
	set gDevice(i_beamstop,afterShutter) 1
	set gDevice(i5,afterShutter) 1
	set gDevice(a0,afterShutter) 1
	set gDevice(a1,afterShutter) 1
	set gDevice(a2,afterShutter) 1
	set gDevice(a3,afterShutter) 1
	set gDevice(a4,afterShutter) 1
	set gDevice(a5,afterShutter) 1
	set gDevice(a6,afterShutter) 1
	set gDevice(a7,afterShutter) 1	

	set gPhoto(gonio)	[ image create photo -file "$BLC_IMAGES/gonio.gif" -palette "8/8/8"]
	
	set gDevice(components) {}

	# define table
	create_mdw_document table "Table" 630 310 construct_new_table_window
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
	create_pseudo_motor	table_v2_z		tv2z	default  " mm $gFont(micron) "
	create_pseudo_motor	table_pivot_z	tpz	default	" mm $gFont(micron) "

	# define mirror
	add_component_menu_entry Mirror mirror
	create_real_motor mirror_vert				miv 	mirror	" mm $gFont(micron) "
	create_real_motor mirror_slit_upper		misu 	mirror	" mm $gFont(micron) "
	create_real_motor mirror_slit_lower		misl	mirror	" mm $gFont(micron) "
	create_real_motor mirror_pitch			mip	mirror	{ mrad deg }
	create_real_motor mirror_bend				mib	mirror	" mm "
	create_pseudo_motor mirror_vert_chin 	mic	mirror 	" mm $gFont(micron) "
	create_pseudo_motor mirror_chin_gap 	mcg 	default 	" mm $gFont(micron) "

	if { $gBeamline(upwardMirror) } {
		create_mdw_document mirror 	"Mirror" 	660 420 construct_upward_mirror_window
	} else {
		create_mdw_document mirror    "Mirror" 	660 360 construct_downward_mirror_window
	}

	# define the energy devices
	create_pseudo_motor	energy						e		mono		"eV keV $gFont(angstrom)"
	create_pseudo_motor  asymmetric_cut				ac		default 	{ deg mrad }
	create_pseudo_motor	d_spacing					ds		default 	" mm $gFont(micron) "
	create_pseudo_motor	optimized_energy			oe		default	"eV keV $gFont(angstrom)"
 	create_pseudo_motor  energyOptimizeTolerance oet   default  "eV keV $gFont(angstrom)"
	create_pseudo_motor	energyLastTimeOptimized	oelt	default	" s "
	create_pseudo_motor	energyLastOptimized		oe		default	"eV keV $gFont(angstrom)"
	create_pseudo_motor	energyOptimizedTimeout	oe		default	" s "
	create_pseudo_motor	energyLastOptimizedTable oe	default	" mm $gFont(micron) "
	create_pseudo_motor	energyOptimizeEnable oe	default	" mm $gFont(micron) "

	# define sample goniometer
	create_mdw_document gonio "Goniometer" 980 355 construct_gonio_window
	add_component_menu_entry Goniometer gonio
	create_real_motor		gonio_phi		phi	gonio		{ deg }
	create_real_motor		gonio_omega		omega	gonio		{ deg }
	create_real_motor		gonio_kappa 	kappa	gonio		{ deg }
	create_real_motor		gonio_z			gz		detector	" mm $gFont(micron) "
	create_real_motor		sample_x			sx		gonio		" mm $gFont(micron) "
	create_real_motor		sample_y			sy		gonio		" mm $gFont(micron) "
	create_real_motor		sample_z			sz		gonio		" mm $gFont(micron) "

	# define detector gantry
	create_mdw_document detector "Detector" 800 400 construct_detector_window
	add_component_menu_entry Detector detector	
	create_real_motor		detector_horz		 dh		detector 	" mm $gFont(micron) "
	create_real_motor		detector_pitch		 dp		detector 	{ deg mrad }
	create_real_motor		detector_vert		 dv		detector 	" mm $gFont(micron) "
	create_real_motor		detector_z			 dz		detector 	" mm $gFont(micron) "
	create_pseudo_motor	detector_z_corr dze	   default 	" mm $gFont(micron) "
	
	create_mdw_document DetectorControlPanel "Detector Control" 600 800 construct_detector_control_panel destroy_detector_control_panel
	add_component_menu_entry detectorControl DetectorControlPanel
	create_pseudo_motor detectorControlPanel detectorControl DetectorControlPanel	" mm "

	# define frontend slits	
	create_mdw_document frontend_slits "Hutch Frontend Slits" 1100 360 construct_frontend_slits_window
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
	create_mdw_document frontend_aperatures "Frontend Aperatures" 1100 360 construct_frontend_aperature_window
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

	# create the beamstop motors
	create_real_motor 	beamstop_z			bsz	default	" mm $gFont(micron) "
	create_real_motor 	beamstop_hor		bsh	default	" mm $gFont(micron) "
	create_real_motor 	beamstop_ver		bsv	default	" mm $gFont(micron) "
	create_real_motor		guard_shield_horiz		gsh	default	" mm $gFont(micron)"	
	create_real_motor		guard_shield_vert			gsv	default	" mm $gFont(micron)"

	# define spare motors
	create_mdw_document spare "Spare Motors" 347 170 construct_spare_window
	add_component_menu_entry "Spare Motors" spare
	create_real_motor		spare_1				s1		spare			" mm $gFont(micron) "
	create_real_motor		spare_2				s2		spare			" mm $gFont(micron) "

	# create the dose devices
	create_pseudo_motor	doseStoredCounts			dsc	default 	" counts "
	create_pseudo_motor	doseLastCounts				dlc	default 	" counts "
	create_pseudo_motor	doseStabilityRatio		dsr	default 	" % "
	create_pseudo_motor	doseThreshold				dt		default 	" counts "
	create_pseudo_motor	doseIntegrationPeriod 	dip	default 	" s "
	create_pseudo_motor	maxOscTime					mot	default 	" s "

	# create the attenuation device
	create_pseudo_motor     attenuation            attn     default         "%"

	# create the sample camera zoom devices
	create_real_motor 	camera_zoom					cz 	default 	" mm $gFont(micron) "
	create_pseudo_motor	zoomMinScale	zmins	default 	" mm "
	create_pseudo_motor	zoomMedScale	zmeds	default 	" mm "
	create_pseudo_motor	zoomMaxScale	zmaxs	default 	" mm "
	create_pseudo_motor	zoomMinYAxis	zminy	default 	" % "
	create_pseudo_motor	zoomMedYAxis	zmedy	default 	" % "
	create_pseudo_motor	zoomMaxYAxis	zmaxy	default 	" % "
	create_pseudo_motor  zoomMaxXAxis   zmaxx default  " % "
	create_pseudo_motor  sampleImageWidth siw default  " mm "
	create_pseudo_motor  sampleImageHeight sih default  " mm "
	create_pseudo_motor  sampleAspectRatio scar default  " mm "


	#add simulated motor for diagnostic tests
	create_real_motor		sim_motor	sim	default		" mm $gFont(micron)"	
	create_real_motor		fluorescence_z				fz		default	" mm $gFont(micron)"

	# handle differences between beam lines
	if { $gBeamline(doubleMono) } {

		# define monochromator
		create_mdw_document mono 		"Monochromator" 	815 400 construct_92_mono_window
		add_component_menu_entry Monochromator mono
		create_real_motor 	mono_slit_vert		mosv	mono		" mm $gFont(micron) "
		create_real_motor		mono_slit_lower	mosl	mono		" mm $gFont(micron) "
		create_real_motor 	mono_slit_spear	mosp	mono		" mm $gFont(micron) "
		create_real_motor		mono_slit_ssrl		mosr	mono		" mm $gFont(micron) "
		create_real_motor 	mono_theta			mot	mono		{ deg mrad }
		create_real_motor 	mono_encoder		mot	mono		{ deg mrad }
		create_real_motor 	mono_pitch			mop	mono		{ deg mrad }
		create_real_motor 	mono_roll			mor	mono		{ deg mrad }
		create_pseudo_motor  mono_theta_corr   mtc   default 	{ deg mrad }

		# define beamline
		create_mdw_document beamline 	"Beamline" 			800 250 construct_beamline_window
		add_component_menu_entry Beamline beamline	
		create_real_motor		mono_vert	bv1	beamline 	" mm $gFont(micron) "
		create_real_motor		beam_pipe_vert	bv2	beamline 	" mm $gFont(micron) "
		
		# define slit_0
		create_mdw_document slit0 		"Stopper Slits" 	400 360 construct_slit0_window
		add_component_menu_entry "Stopper Slits" slit0
		create_real_motor		slit_0_upper		s0u	slit0 	" mm $gFont(micron) "
		create_real_motor		slit_0_lower		s0l	slit0 	" mm $gFont(micron) "
		create_real_motor		slit_0_spear		s0sp	slit0 	" mm $gFont(micron) "
		create_real_motor		slit_0_ssrl			s0ss	slit0 	" mm $gFont(micron) "
		
		#define toroid
		create_mdw_document toroid 	"Toroid" 			520 330 construct_toroid_window
		add_component_menu_entry Toroid toroid
		create_real_motor toroid_vert			tov 	toroid	" mm $gFont(micron) "
		create_real_motor toroid_pitch		top	toroid	{ deg mrad }
		create_real_motor toroid_yaw			toy	toroid	{ deg mrad }
		create_real_motor toroid_bend			tob	toroid	" mm "
		
		create_real_motor		dac					dac	default		" mm"
		create_real_motor		diagnostic_vert 	dv		default		" mm"

	} else {

		# define monochromator
		create_mdw_document mono 	"Monochromator" 	815 400 construct_11_mono_window
		add_component_menu_entry Monochromator mono
		create_real_motor		mono_slit			mos	mono		" mm $gFont(micron) "
		create_real_motor		mono_bend			mob	mono		" mm $gFont(micron) "
		create_real_motor		mono_filter			mof	mono		" mm $gFont(micron) "
		create_real_motor		mono_angle			moa	mono		{ deg mrad }
		create_pseudo_motor 	mono_theta			mot	mono		{ deg mrad } 
		create_real_motor   	table_slide			ts		mono 		" mm $gFont(micron) "
		create_pseudo_motor 	table_2theta		t2t	mono		{ deg mrad }
		create_pseudo_motor 	table_slide_z		tsz	default	" mm $gFont(micron) "
		create_pseudo_motor  table_vert_offset tvo   default " mm $gFont(micron) "
		create_pseudo_motor  table_slide_offset tso  default " mm $gFont(micron) "

		# define the beam position monitor motor
		create_real_motor		bpm				bpm	default		" mm $gFont(micron) "
	}


	# create all shutters
	namespace eval device {
		
		# the main beam shutter
		Shutter shutter

		# the attenuator foils
		Shutter Al_1
		Shutter Al_2
		Shutter Al_4
		Shutter Al_8
		Shutter Al_16
		Shutter Al_32
		Shutter Al_0.5
		
		# the heavy atom foils
		Shutter Se
		Shutter Cu
		Shutter Sr
		Shutter HA
	}

	# create operation status objects
	OperationStatus requestCollectedImageStatus
	OperationStatus centerLoopStatus
	OperationStatus collectRunsStatus
	OperationStatus collectRunStatus
	OperationStatus collectFrameStatus
	OperationStatus moveSampleStatus
	OperationStatus optimizeStatus
	OperationStatus ptzStatus
	OperationStatus normalizeStatus
	OperationStatus pauseDataCollectionStatus

	# define shutter information
	if { $gBeamline(doubleMono) } {
		set gDevice(attenuator_list) {Al_1 Al_2 Al_4 Al_8 Al_16 Al_32 Al_0.5}
	} else {
		set gDevice(attenuator_list) {Al_1 Al_2 Al_4 Al_8 Al_16 Al_32}
	}

	set gDevice(Al_1,description) 1
	set gDevice(Al_2,description) 2
	set gDevice(Al_4,description) 4
	set gDevice(Al_8,description) 8
	set gDevice(Al_16,description) 16
	set gDevice(Al_32,description) 32
	set gDevice(Al_0.5,description) 0.5

	set gDevice(Al_1,openOffset)  -22
	set gDevice(Al_2,openOffset)  -22
	set gDevice(Al_4,openOffset)  -22
	set gDevice(Al_8,openOffset)  -22
	set gDevice(Al_16,openOffset) -22
	set gDevice(Al_32,openOffset) -22
	set gDevice(Al_0.5,openOffset) -22

	set gDevice(Al_1,state) closed
	set gDevice(Al_2,state) closed
	set gDevice(Al_4,state) closed
	set gDevice(Al_8,state) closed
	set gDevice(Al_16,state) closed
	set gDevice(Al_32,state) closed
	set gDevice(Al_0.5,state) closed

	set gDevice(Al_1,graphicState) unset
	set gDevice(Al_2,graphicState) unset
	set gDevice(Al_4,graphicState) unset
	set gDevice(Al_8,graphicState) unset
	set gDevice(Al_16,graphicState) unset
	set gDevice(Al_32,graphicState) unset
	set gDevice(Al_0.5,graphicState) unset

	set gDevice(Al_1,hutchGraphicState) unset
	set gDevice(Al_2,hutchGraphicState) unset
	set gDevice(Al_4,hutchGraphicState) unset
	set gDevice(Al_8,hutchGraphicState) unset
	set gDevice(Al_16,hutchGraphicState) unset
	set gDevice(Al_32,hutchGraphicState) unset
	set gDevice(Al_0.5,hutchGraphicState) unset

	set gDevice(Al_1,type) filter
	set gDevice(Al_2,type) filter
	set gDevice(Al_4,type) filter
	set gDevice(Al_8,type) filter
	set gDevice(Al_16,type) filter
	set gDevice(Al_32,type) filter
	set gDevice(Al_0.5,type) filter

	set gDevice(Al_1,openColor) black
	set gDevice(Al_2,openColor) black
	set gDevice(Al_4,openColor) black
	set gDevice(Al_8,openColor) black
	set gDevice(Al_16,openColor) black
	set gDevice(Al_32,openColor) black
	set gDevice(Al_0.5,openColor) black

	set gDevice(Al_1,closedColor) red
	set gDevice(Al_2,closedColor) red
	set gDevice(Al_4,closedColor) red
	set gDevice(Al_8,closedColor) red
	set gDevice(Al_16,closedColor) red
	set gDevice(Al_32,closedColor) red
	set gDevice(Al_0.5,closedColor) red

#	set gDevice(one_attenuator) {atten}
	set gDevice(atten,description) Attenuator
	set gDevice(atten,state) 0
	set gDevice(atten,hutchGraphicState) unset
	set gDevice(atten,type) filter

	set gDevice(foil_list) { Se }

	set gDevice(Se,description) Se
	set gDevice(Se,state) closed
	set gDevice(Se,closedColor) red
	set gDevice(Se,openColor) black
	set gDevice(Se,graphicState) unset
	set gDevice(Se,hutchGraphicState) unset
	set gDevice(Se,openOffset) -22
	set gDevice(Se,type) filter

	set gDevice(shutter,openOffset) 22
	set gDevice(shutter,state) closed
	set gDevice(shutter,graphicState) unset
	set gDevice(shutter,hutchGraphicState) unset
	set gDevice(shutter,type) shutter
	set gDevice(shutter,closedColor) black
	set gDevice(shutter,openColor) red
}




proc construct_table_window { parent } {

	# create the canvas to draw the table in
	set canvas [
		canvas $parent.canvas				\
			-width 660 							\
			-height 320							\
			-highlightthickness 0	]
	place $canvas -x -15 -y -5

	bind $canvas <Button-1> "activate_mdw_document table"
	bind $parent <Button-1> "activate_mdw_document table"

	# draw the table
	rect_solid $canvas 180 120 250 20 40 60 40

	# create views for each motor
	motorView $canvas table_vert_1 190  90 s
	motorView $canvas table_vert 	 330  90 s 
	motorView $canvas table_vert_2 470  90 s
	motorView $canvas table_horz 	 242 197 n
	motorView $canvas table_horz_2 400 197 n
	motorView $canvas table_yaw 	 143 137 e 105 45 7
	motorView $canvas table_pitch  507 137 w 105 45 7
	
	# create arrow for each motor
	motorArrow $canvas table_vert_1 210  90 {} 210 140 222 94 222 140
	motorArrow $canvas table_vert   330  90 {} 330 140	342 94 342 140
	motorArrow $canvas table_vert_2 450  90 {} 450 140 462 95 462 140
	motorArrow $canvas table_horz   305 170 {} 272 197 313 172 291 196
	motorArrow $canvas table_horz_2 430 170 {} 403 197 442 177 422 196
	motorArrow $canvas table_yaw    165 165 {125 137} 200 135 154 172 186 125
	motorArrow $canvas table_pitch  470  110 {500 120 500 160} 470 170 486 104 486 176

#	global gColors
#	$canvas create bitmap 90 8 -bitmap "@locked_padlock.bit" \
#		-foreground red
	
#bind $canvas <Button-1> "log %x %y"	
}



proc construct_detector_window { parent } {

	# create the canvas to draw in
	set canvas [
		canvas $parent.canvas				\
			-width 850 							\
			-height 420							\
			-highlightthickness 0	]
	place $canvas -x 20 -y -35

	bind $canvas <Button-1> "activate_mdw_document detector"
	bind $parent <Button-1> "activate_mdw_document detector"

	# draw the table
	rect_solid $canvas 80 220 430 20 60 85 65

	# draw the goniometer trolley
	rect_solid $canvas 130 190 50 20 80 100 95

	# draw the gantry trolley
	rect_solid $canvas 410 190 60 20 80 95 90

	# draw the back vertical beam
	rect_solid $canvas 482 61 35 150 8 10 9
	
	# draw the detector
	rect_solid $canvas 423 90 120 60 20 30 27

	# draw the front vertical beam
	rect_solid $canvas 443 82 40 160 8 10 9

	# draw the gantry top bar
	rect_solid $canvas 443 50 40 20 30 50 43

	motorView $canvas gonio_z 135 203 e  120 45 10
	motorArrow $canvas gonio_z 180 230 {} 134 230 176 216 140 216
 
	motorView $canvas detector_z 590 235 w  117 45 10
	motorArrow $canvas detector_z 590 230 {} 525 230 584 219 535 219
	
	motorView $canvas detector_horz 400 314 n  120 45 10
	motorArrow $canvas detector_horz 440 280 {} 400 313 447 284 419 310
	
	motorView $canvas detector_pitch 620 120 w 125 45 9
	motorArrow $canvas detector_pitch  580 95 {610 105 610 145} 580 155 594 88 593 161
	
	motorView $canvas detector_vert 417 209 se 120 45 10
	motorArrow $canvas detector_vert  432 170 {} 432 240 420 176 420 234

	# draw the x-ray beam
#	$canvas create line 20 160 220 160  -fill red -width 2 -arrow last

#	bind $canvas <Button-1> "log %x %y"
}



proc construct_toroid_window { parent } {
	
	# create the canvas to draw the mirror in
	set canvas [
		canvas $parent.canvas				\
			-width 560 							\
			-height 320							\
			-highlightthickness 0	]
	place $canvas -x -30 -y -5

	bind $canvas <Button-1> "activate_mdw_document toroid"
	bind $parent <Button-1> "activate_mdw_document toroid"

	# draw a support
	#rect_solid $canvas 230 131 20 40 30 25 25

	# draw the 
	rect_solid $canvas 140 130 200 10 20 30 20

	# draw the x-ray beam
	$canvas create line 119 80 255 140 400 80 -fill red -width 2 -arrow last

	motorView $canvas toroid_bend 265 80 s
	motorView $canvas toroid_pitch 401 137 w 115 45 8
	motorView $canvas toroid_vert 264 216 n
	motorView $canvas toroid_yaw 	170 205 e 105 45 7
	
	motorArrow $canvas toroid_vert 255 162 {} 255 212 266 168 266 206
	motorArrow $canvas toroid_pitch  360 110 {390 120 390 160} 360 170 376 104 373 177
	motorArrow $canvas toroid_yaw 125 150 {75 132} 150 130 117 158 142 118

#	bind $canvas <Button-1> "log %x %y"
}


proc construct_beamline_window { parent } {

	# create the canvas to draw the table in
	set canvas [
		canvas $parent.canvas				\
			-width 800 							\
			-height 320							\
			-highlightthickness 0	]
	place $canvas -x -25 -y -15

	bind $canvas <Button-1> "activate_mdw_document beamline"
	bind $parent <Button-1> "activate_mdw_document beamline"

	# draw the blue rail
	rect_solid $canvas 80 160 520 20 5 9 6

	# create views for each motor
	motorView $canvas mono_vert 120 110 s 140 45 13
	motorView $canvas beam_pipe_vert 560 110 s 140 45 13
	motorArrow $canvas mono_vert 120 113 {} 120 163
	motorArrow $canvas beam_pipe_vert 570 113 {} 570 163
	}



proc construct_gonio_window { parent } {

	# global variables
	global gPhoto
	global gBitmap
	global gButton
	global gSpeedScale
	global joyspeed	
 
	# create the canvas to draw the mirror in
	set canvas [
		canvas $parent.canvas				\
			-width 1000 							\
			-height 500							\
			-highlightthickness 0	]
	place $canvas -x -5 -y -15

	bind $canvas <Button-1> "activate_mdw_document gonio"
	bind $parent <Button-1> "activate_mdw_document gonio"

	# display photo of the goniometer
	$canvas create image 190 120 -anchor nw -image $gPhoto(gonio)
	
	motorView $canvas gonio_omega 15 213 w
	motorView $canvas gonio_kappa 435 179 w
	motorView $canvas gonio_phi 307 92 s

	motorView $canvas sample_x 650 30 n
	motorView $canvas sample_y 650 130 n
	motorView $canvas sample_z 650 230 n
	
	motorArrow $canvas gonio_omega 185 260  {155 245 155 195 } 185 180 170 264 170 177
	motorArrow $canvas gonio_phi 292 109 { 303 100 322 105} 331 117  290 98 335 105
	motorArrow $canvas gonio_kappa  411 167 { 422 173  427 189 } 419 205 423 162 427 210

	# create the joypad frame
	place [iwidgets::Labeledframe $parent.joypadframe \
		-labeltext "Joypad" -labelpos n -ipadx 5 -ipady 5] -x 730 -y 50
	set joypadframe [ $parent.joypadframe childsite ]
	
	# create the sample buttons
	pack [set canvas [canvas $joypadframe.canvas -width 180 -height 180]] -pady 1 -padx 5
	#place [button $canvas.zplus -image $gBitmap(rightarrow) ] -x 48 -y 24
	#place [button $canvas.zminus -image $gBitmap(leftarrow) ] -x 0 -y 24
	#place [set gButton(xplus) [button $canvas.xplus -image $gBitmap(uparrow) ]] -x 24 -y 0
	#place [set gButton(xminus) [button $canvas.xminus -image $gBitmap(downarrow) ]] -x 24 -y 48

	#add a speed scale

	set joyspeed(xyUp) 0
	set joyspeed(xy_last) 0

	place [scale $canvas.xy_plus -orient vertical \
				 -length 78 -from 5000 -to 0        \
				 -variable joyspeed(xyUp)           \
				 -showvalue 0                       \
				 -command joyUp]  -x 80 -y 0
	bind $canvas.xy_plus <ButtonRelease>  {
		set joyspeed(xyUp) 0
		joyUp
		} 

	set joyspeed(xyDown) 0
	set joyspeed(xy_last) 0
	place [scale $canvas.xy_minus -orient vertical \
				 -length 78 -from 0 -to 5000         \
				 -variable joyspeed(xyDown)          \
				 -showvalue 0                       \
				 -command joyDown]  -x 80 -y 100

	bind $canvas.xy_minus <ButtonRelease>  {
		set joyspeed(xyDown) 0
		joyDown
		}

	set joyspeed(zRight) 0
	set joyspeed(zLeft) 0
	set joyspeed(z_last) 0

	place [scale $canvas.z_minus -orient horizontal \
				  -length 78 -from 5000 -to 0          \
				  -variable joyspeed(zLeft)          \
				  -showvalue 0								\
				  -command joyLeft]  -x 0 -y 80
	bind $canvas.z_minus <ButtonRelease>  {
		set joyspeed(zLeft) 0
		joyLeft
		}

	place [scale $canvas.z_plus -orient horizontal \
				  -length 78 -from 0 -to 5000         \
				  -variable joyspeed(zRight)          \
				  -showvalue 0								\
				  -command joyRight] -x 100 -y 80
	bind $canvas.z_plus <ButtonRelease>  {
		set joyspeed(zRight) 0
		joyRight
		}

	# create the phi increment/decrement buttons
	pack [ set phiframe [frame $joypadframe.phiframe]] -pady 2
	pack [ button $phiframe.minus -text "- 90" -padx -8  -pady 0 -command "do move gonio_phi by -90 deg"] -side left
	pack [ label $phiframe.label -text "Phi" ] -side left -padx 10
	pack [ button $phiframe.plus -text "+ 90" -padx -8  -pady 0 -command "do move gonio_phi by 90 deg" ] -side left
	
	#bind $canvas.zplus <ButtonPress> { catch { zplushandler } }
	#bind $canvas.zminus <ButtonPress>  { catch { zminushandler } }

	#bind the xplus buttons
	#xplusrelease
	
	#bind $canvas.zplus <ButtonRelease> "do abort_motor sample_z soft"
	#bind $canvas.zminus <ButtonRelease> "do abort_motor sample_z soft"
	#bind $canvas.xplus <ButtonRelease> {
	#	 do vector_stop_move sample_x sample_y
	#	 after 500 xplusrelease }
	#bind $canvas.xminus <ButtonRelease> {
	#	 do vector_stop_move sample_x sample_y
	#	 after 500 xplusrelease }
	
	#bind $canvas <Button-1> "log %x %y"	

}

proc joyUp {args} {
	global joyspeed

	if { $joyspeed(xy_last) == 0 } {
			if { $joyspeed(xyUp) != 0 } {
			#start vector move
			xplushandler 1.0 $joyspeed(xyUp)
			log_note "start vector move"
			}
		}

	if { $joyspeed(xy_last) != 0 } {
		if { $joyspeed(xyUp) == 0 } {	
			#stop vector move
			do vector_stop_move sample_x sample_y
			log_note "stop vector move"
			update
			after 500 {}
			}
		}

	if { $joyspeed(xy_last) != 0 } {
		if { $joyspeed(xyUp) != 0 } {	
			#change vector speed
			do vector_change_speed sample_x sample_y $joyspeed(xyUp)
#			log_note "change vector speed"
			}
		}

	set joyspeed(xy_last) $joyspeed(xyUp)

	#log_note "XY speed at $speed steps/s"
	}


proc joyDown {args} {
	global joyspeed

	if { $joyspeed(xy_last) == 0 } {
			if { $joyspeed(xyDown) != 0 } {
				#start vector move
				xplushandler -1.0 [expr abs ($joyspeed(xyDown))]
				log_note "start vector move"
			}
	}
	
	if { $joyspeed(xy_last) != 0 } {
		if { $joyspeed(xyDown) == 0 } {	
			#stop vector move
			do vector_stop_move sample_x sample_y
			log_note "stop vector move"
		}
	}
	
	if { $joyspeed(xy_last) != 0 } {
		if { $joyspeed(xyDown) != 0 } {	
			#change vector speed
			do vector_change_speed sample_x sample_y $joyspeed(xyDown)
			#			log_note "change vector speed"
		}
	}
	
	set joyspeed(xy_last) $joyspeed(xyDown)

	#log_note "XY speed at $speed steps/s"
	}


proc joyLeft {args} {
	global joyspeed

	if { $joyspeed(z_last) == 0 } {
			if { $joyspeed(zLeft) != 0 } {
			#start vector move
			zminushandler $joyspeed(zLeft)
			log_note "start vector move"
			}
		}

	if { $joyspeed(z_last) != 0 } {
		if { $joyspeed(zLeft) == 0 } {	
			#stop vector move
			do vector_stop_move sample_z NULL
			log_note "stop vector move"
			update
			after 500 {}
			}
		}

	if { $joyspeed(z_last) != 0 } {
		if { $joyspeed(zLeft) != 0 } {	
			#change vector speed
			do vector_change_speed sample_z NULL $joyspeed(zLeft)
#			log_note "change vector speed"
			}
		}

	set joyspeed(z_last) $joyspeed(zLeft)
	}

proc joyRight {args} {
	global joyspeed

	if { $joyspeed(z_last) == 0 } {
			if { $joyspeed(zRight) != 0 } {
			#start vector move
			zplushandler $joyspeed(zRight)
			log_note "start vector move"
			}
		}

	if { $joyspeed(z_last) != 0 } {
		if { $joyspeed(zRight) == 0 } {	
			#stop vector move
			do vector_stop_move sample_z NULL
			log_note "stop vector move"
			update
			after 500 {}
			}
		}

	if { $joyspeed(z_last) != 0 } {
		if { $joyspeed(zRight) != 0 } {	
			#change vector speed
			do vector_change_speed sample_z NULL $joyspeed(zRight)
#			log_note "change vector speed"
			}
		}

	set joyspeed(z_last) $joyspeed(zRight)
	}

#proc xplusrelease {} {
#
#	# global variables
#	global gButton
# 
# 	update
# 
# 	bind $gButton(xplus) <ButtonPress> {xplushandler 1.0}
#	bind $gButton(xminus) <ButtonPress> {xplushandler -1.0}
#}


proc xplushandler { direction speed} {

	# global variables
	global gDevice
	global gButton

	if { $gDevice(sample_x,status) != "inactive" || \
			  $gDevice(sample_y,status) != "inactive" } {
 		return
	}
	
	set motor1 sample_x
	set motor2 sample_y
	
	set phiDeg [expr $gDevice(gonio_phi,scaled) + $gDevice(gonio_omega,scaled)]

#	if { ([expr abs($phiDeg)] < 0.01) ||  ([expr abs($phiDeg) - 180.0] < 0.01) } {
#		set motor1 NULL
#	} else {		
#		
#		if { ([expr abs($phiDeg) - 90.0 ] < 0.01) || ([expr abs($phiDeg) - 270.0 ] < 0.01) } {
#			set motor2 NULL
#		}
#	}
		
	if { $direction == 1.0 } {
		set phi [expr $phiDeg / 180.0 * 3.14159]
	} else {
	  set phi [expr ($phiDeg + 180.0 )/ 180.0 * 3.14159]
  }
					
	set comp_x [expr -sin($phi) * 100 + $gDevice(sample_x,scaled)]
	set comp_y [expr cos($phi) * 100 + $gDevice(sample_y,scaled)]
	
	do move_vector_no_parse $motor1 $motor2 $comp_x $comp_y $speed
}

proc zminushandler {speed} {

	# global variables
	global gDevice

	if { $gDevice(sample_z,status) != "inactive" } {
 		return
 	}

	do move_vector_no_parse sample_z NULL $gDevice(sample_z,scaledLowerLimit) 0 $speed
}

proc zplushandler {speed} {

	# global variables
	global gDevice

	if { $gDevice(sample_z,status) != "inactive" } {
 		return
 	}

	do move_vector_no_parse sample_z NULL $gDevice(sample_z,scaledUpperLimit) 0 $speed
}


proc construct_spare_window { parent } {

	# global variables
	global gPhoto

	# create the canvas to draw the mirror in
	set canvas [
		canvas $parent.canvas				\
			-width 800 							\
			-height 500							\
			-highlightthickness 0	]
	place $canvas -x -5 -y -15

	bind $canvas <Button-1> "activate_mdw_document spare"
	bind $parent <Button-1> "activate_mdw_document spare"

	motorView $canvas spare_1 100 30 n
	motorView $canvas spare_2 250 30 n
	
	motorArrow $canvas spare_1 50 122 {}  150 122 55 132 145 132
	motorArrow $canvas spare_2 200 122 {}  300 122 205 132 295 132

	bind $canvas <Button-1> "log %x %y"	

}


proc construct_slit0_window { parent } {

# create the canvas to draw in
	set canvas [
		canvas $parent.canvas				\
			-width 500							\
			-height 400							\
			-highlightthickness 0	]
	place $canvas -x 0 -y 10

	bind $canvas <Button-1> "activate_mdw_document slit0"
	bind $parent <Button-1> "activate_mdw_document slit0"

	draw_four_slits $canvas 0 0 slit_0
	draw_ion_chamber $canvas 280 134
	$canvas create line 42 137 149 137 -fill red -width 2
	$canvas create line 185 137 369 137 -fill red -width 2 -arrow last
	ion_chamber_view $canvas i0 0 305 165
	
#bind $canvas <Button-1> "log %x %y"	

}


proc update_filter_canvas { filter } {

	# global variables 
	global gDevice
	global gCanvas
	global gDefineScan
	global gColors

	if { $gDevice($filter,graphicState) ==  $gDevice($filter,state)  } {
		return
	}
	
	if { $gDevice($filter,graphicState) == "unset"  && $gDevice($filter,state) == "closed" } {
		set gDevice($filter,graphicState) closed
		#if { $filter == "shutter" } update_user_beam
		return
	}
	
	
	if { $gDevice($filter,state) == "closed" } {
		#the following catches should be replace with check to see if mdw object exists
		catch {
			$gCanvas(frontend_slits) move $filter 0 [expr -1 * $gDevice($filter,openOffset)]
			$gCanvas(frontend_slits) itemconfigure filter_${filter}_label -fill $gDevice($filter,closedColor)
		}
		catch {
			$gCanvas(frontend_aperatures) move $filter 0 [expr -1 * $gDevice($filter,openOffset)]
			$gCanvas(frontend_aperatures) itemconfigure filter_${filter}_label -fill $gDevice($filter,closedColor)
		}
		
		#$gCanvas(userCanvas) move $filter 0 [expr -1 * $gDevice($filter,openOffset)]
		#$gCanvas(userCanvas) itemconfigure filter_${filter}_label -fill $gDevice($filter,closedColor)
		

	} else {
		catch {
			$gCanvas(frontend_slits) move $filter 0  $gDevice($filter,openOffset)
			$gCanvas(frontend_slits) itemconfigure filter_${filter}_label -fill  $gDevice($filter,openColor)
		}
		catch {
			$gCanvas(frontend_aperatures) move $filter 0 $gDevice($filter,openOffset)
			$gCanvas(frontend_aperatures) itemconfigure filter_${filter}_label -fill  $gDevice($filter,openColor)
		}
		
		#$gCanvas(userCanvas) move $filter 0 $gDevice($filter,openOffset)
		#$gCanvas(userCanvas) itemconfigure filter_${filter}_label -fill $gDevice($filter,openColor)
	}

	set gDevice($filter,graphicState) $gDevice($filter,state)

	if { $filter == "shutter" } {
		update_beam
	}
	catch { scan_filter_button_command $filter }
}
	
proc update_beam {} {

	# global variables 
	global gDevice
	global gCanvas

	set state $gDevice(shutter,state)
	
	if { $state == "open" } {
		show_beam beam
	} else {
		hide_beam beam
	}
}


proc show_beam { tag } {
	
	# global variables 
	global gCanvas

	catch {
		$gCanvas(frontend_slits) itemconfigure $tag -fill red
		$gCanvas(frontend_slits) raise $tag	
	}
	
	catch {
		$gCanvas(frontend_aperatures) itemconfigure $tag -fill red
		$gCanvas(frontend_aperatures) raise $tag	
	}
}

proc hide_beam { tag } {

	# global variables 
	global gCanvas
	
	catch {
		$gCanvas(frontend_slits) itemconfigure $tag -fill lightgrey
		$gCanvas(frontend_slits) lower $tag
	}
	catch {
		$gCanvas(frontend_aperatures) itemconfigure $tag -fill lightgrey
		$gCanvas(frontend_aperatures) lower $tag
	}
}


proc frontend_common { canvas } {

	# global variables 
	global gDevice
	global gCanvas
	global gFont

	draw_ion_chamber $canvas 80 134
	ion_chamber_view $canvas i0 0 98 167

	draw_ion_chamber $canvas 555 134
	ion_chamber_view $canvas i1 1 573 168

	draw_ion_chamber $canvas 900 134
	ion_chamber_view $canvas i2 2 918 168
	$canvas create line 46 137 179 137 -fill red -width 2

	ion_chamber_view $canvas i_sample 3 1040 120
				
	set x 140

	foreach filter $gDevice(attenuator_list) {
		draw_filter $filter $gDevice($filter,description) $canvas $x 120 \
			"toggle_shutter $filter"
		$canvas create line [expr $x + 10] 137 350 137 -fill red -width 2
		incr x 20
	}

	foreach filter $gDevice(foil_list) {
		draw_filter $filter $filter $canvas $x 120 \
			"toggle_shutter $filter"
		$canvas create line [expr $x + 10] 137 350 137 -fill red -width 2
		incr x 20
	}

	set x 350
	
	# draw the label for the shutter
	$canvas bind [$canvas create text [expr $x + 30] 110 -text "Shutter" \
		-font $gFont(tiny) -tag filter_shutter_front_label] \
		<Button-1> "toggle_shutter shutter" 

	$canvas create line 349 137 370 137 -fill red -width 2
	incr x 20

	draw_filter shutter "" $canvas $x 121 "toggle_shutter shutter" 5
	$canvas create line 800 137 964 137 -fill red -width 2 -arrow last -tag beam

}

proc construct_frontend_slits_window { parent } {

	# global variables 
	global gCanvas
	
	# create the canvas to draw in
	set canvas [
		canvas $parent.canvas				\
			-width 1200							\
			-height 600							\
			-highlightthickness 0	]
	place $canvas -x -30 -y 10

	bind $canvas <Button-1> "activate_mdw_document frontend_slits"
	bind $parent <Button-1> "activate_mdw_document frontend_slits"
	
	set gCanvas(frontend_slits) $canvas

	frontend_common $canvas

	$canvas create line 369 137 419 137 -fill red -width 2 -tag beam
	$canvas create line 455 137 764 137 -fill red -width 2 -tag beam
	
	draw_four_slits $canvas 270 0 slit_1

	draw_four_slits $canvas 615 0 slit_2

	update_beam

#bind $canvas <Button-1> "log %x %y"	
}


proc construct_frontend_aperature_window { parent } {

	# global variables 
	global gCanvas

	# create the canvas to draw in
	set canvas [
		canvas $parent.canvas				\
			-width 1200							\
			-height 600							\
			-highlightthickness 0	]
	place $canvas -x -30 -y 10

	bind $canvas <Button-1> "activate_mdw_document frontend_aperatures"
	bind $parent <Button-1> "activate_mdw_document frontend_aperatures"
	
	set gCanvas(frontend_aperatures) $canvas

	frontend_common $canvas

	$canvas create line 369 137 438 137 -fill red -width 2 -tag beam
	$canvas create line 455 137 783 137 -fill red -width 2 -tag beam
	
	draw_aperature $canvas 270 0 slit_1

	draw_aperature $canvas 615 0 slit_2
	
	update_beam

#bind $canvas <Button-1> "log %x %y"	
}




proc draw_aperature { canvas x y name } {
	
	# global variables
	global gColors
	
	$canvas create poly [expr $x + 167] 221 [expr $x + 183] 221 \
		[expr $x + 213] 197 [expr $x + 199] 197 -fill $gColors(top) -outline black
	$canvas create rect [expr $x + 200] 100 [expr $x + 213] 197 -fill $gColors(front) 
	$canvas create rect [expr $x + 168] 120 [expr $x + 183] 220 -fill $gColors(front) 	
	$canvas create poly [expr $x + 167] 121 [expr $x + 183] 121 \
		[expr $x + 213] 100 [expr $x + 199] 100 -fill $gColors(top) -outline black
	
	# draw the vertical gap
	motorArrow $canvas ${name}_vert_gap \
		[expr $x + 224] [expr $y + 101] {} [expr $x + 224] [expr $y + 127] \
		[expr $x + 234] [expr $y + 104] [expr $x + 234] [expr $y + 123]
	motorView $canvas ${name}_vert_gap [expr $x + 280] [expr $y + 95] s 125 43 11

	# draw the horizontal translation
	motorView $canvas ${name}_horiz [expr $x + 100] [expr $y + 190] n 
	motorArrow $canvas ${name}_horiz \
		[expr $x + 177] [expr $y + 158] {} [expr $x + 139] [expr $y + 189] \
		[expr $x + 159] [expr $y + 159] [expr $x + 139] [expr $y + 175]

	# draw the horizontal gap
	motorArrow $canvas ${name}_horiz_gap \
		[expr $x +  227] [expr $y + 194] {} [expr $x + 207] [expr $y + 213] \
		[expr $x + 232] [expr $y + 198] [expr $x + 223] [expr $y + 212]
	motorView $canvas ${name}_horiz_gap [expr $x + 275] [expr $y + 215] n 132 43 11

	# draw the vertical translation
	motorArrow $canvas ${name}_vert \
		 [expr $x + 190] [expr $y + 66] {} [expr $x + 190] [expr $y + 111] \
		 [expr $x + 180] [expr $y + 71] [expr $x + 180] [expr $y + 105]
	motorView $canvas ${name}_vert [expr $x + 177] [expr $y + 45] e 		
}


proc draw_four_slits { canvas x y name } {
	
	# draw the ssrl slit
	motorArrow $canvas ${name}_ssrl \
		[expr $x + 258] [expr $y + 87] {} [expr $x + 224] [expr $y + 110] \
		[expr $x + 255] [expr $y + 102] [expr $x + 233] [expr $y + 117]
	draw_slit $canvas [expr $x + 191] [expr $y + 81]
	motorView $canvas ${name}_ssrl [expr $x + 297] [expr $y + 80] s 

	# draw the spear slit
	draw_slit $canvas [expr $x + 149] [expr $y + 109]
	motorView $canvas ${name}_spear [expr $x + 80] [expr $y + 180] n 
	motorArrow $canvas ${name}_spear \
		[expr $x + 152] [expr $y + 155] {} [expr $x + 118] [expr $y + 178] \
		[expr $x + 143] [expr $y + 148] [expr $x + 123] [expr $y + 163]

	# draw the lower slit
	draw_slit $canvas [expr $x + 180] [expr $y + 130]
	motorArrow $canvas ${name}_lower \
		[expr $x + 198] [expr $y + 190] {} [expr $x +  198] [expr $y + 235] \
		[expr $x + 208] [expr $y + 195] [expr $x +  208] [expr $y + 230]
	motorView $canvas ${name}_lower [expr $x + 217] [expr $y + 235] n 

	# draw the upper slit
	draw_slit $canvas [expr $x + 180] [expr $y + 65]
	motorArrow $canvas ${name}_upper \
		 [expr $x + 198] [expr $y + 32] {} [expr $x + 198] [expr $y + 77] \
		 [expr $x + 188] [expr $y + 37] [expr $x + 188] [expr $y + 72]
	motorView $canvas ${name}_upper [expr $x + 185] [expr $y + 33] e 
		
}



proc draw_slit { canvas x y } {
	rect_solid $canvas $x $y 5 50 20 30 30
}


proc draw_filter { filter label canvas x y command {thickness 2} } {
	
	# global variables
	global gDevice
	global gFont
	global gFilter
	
	# draw the label for the filter
	$canvas bind [$canvas create text \
		[expr $x + 10] [expr $y - 30] -text $label \
		-font $gFont(tiny) -tag filter_${filter}_label] \
		<Button-1> $command 
	
	# raise the filter if not inserted
	if { $gDevice($filter,state) == "closed" } {
		#incr y [expr -1 * $gDevice($filter,openOffset)]
		$canvas itemconfigure filter_${filter}_label -fill $gDevice($filter,closedColor)
	} else {
		$canvas itemconfigure filter_${filter}_label -fill $gDevice($filter,openColor)
		incr y $gDevice($filter,openOffset)
	}
	
	# draw the filter
	rect_solid $canvas $x $y $thickness 25 10 15 15 $filter
	
	$canvas bind $filter <Button-1> $command
}



proc draw_ion_chamber { canvas x y } {

	# global variables
	global gColors
	
	set width 20
	set height 15
	set length 20
	
	set x0 $x
	set x1 [expr $x0 + $width]
	set x2 [expr $x0 + 15]
	set x3 [expr $x2 + $width]
	set x4 [expr $x0 + $width/2 + 7.5]
	set x5 [expr $x0 - 5 ]
	set x6 [expr $x3 + 5 ]
	
	set y0 $y
	set y1 [expr $y0 - 10]
	set y2 [expr $y0 + $height]
	set y3 [expr $y2 - 10]
	set y5 [expr $y0 - 5 ]
	set y4 [expr $y5 - $length]
	set y7 [expr $y5 + $height + $length]
	set y8 [expr $y4]
	set y9 [expr $y7]
	
	$canvas create oval $x5 $y8 $x6 $y9 -fill $gColors(light) -outline $gColors(top) 
	$canvas create poly $x0 $y0 $x1 $y0 $x3 $y1 $x2 $y1 -fill $gColors(front) -outline black
	$canvas create poly $x0 $y2 $x1 $y2 $x3 $y3 $x2 $y3 -fill $gColors(side) -outline black
	$canvas create line $x4 $y4 $x4 $y5 -fill black -width 2
	$canvas create line $x4 $y2 $x4 $y7 -fill black -width 2
}

set gScan(poll) 0


proc poll_ion_chambers {} {

        # global variables
        global gScan

        if { [dcss is_master] && $gScan(status) == "inactive" && $gScan(poll) == 1 } {
                dcss sendMessage "gtos_read_ion_chambers 4.7 0 i0 i1 i2"
                after 5000 poll_ion_chambers
        }
}


proc construct_upward_mirror_window { parent } {
	
	# create the canvas to draw the mirror in
	set canvas [
		canvas $parent.canvas				\
			-width 660 							\
			-height 380							\
			-highlightthickness 0	]
	place $canvas -x -15 -y -10

	bind $canvas <Button-1> "activate_mdw_document mirror"
	bind $parent <Button-1> "activate_mdw_document mirror"

	# draw the lower slit
	rect_solid $canvas 160 152 5 50 20 30 30

	# draw the mirror
	rect_solid $canvas 240 190 200 10 20 30 20

	# draw the x-ray beam
	$canvas create line 64 129 349 198 612 110 -fill red -width 2 -arrow last

	# draw the upper slit
	rect_solid $canvas 200 97 5 50 20 30 30

	motorView $canvas mirror_slit_upper 122 112 s 140 45 13
	motorView $canvas mirror_vert_chin 349 282 n 140 45 13
	motorView $canvas mirror_slit_lower 176 262 n 140 45 13
	motorView $canvas mirror_pitch 500 197 w 115 45 8
	motorView $canvas mirror_vert 356 128 s
	motorView $canvas mirror_bend 544 303 n 
	
	motorArrow $canvas mirror_vert 350 132 {} 350 182 361 139 361 179
	motorArrow $canvas mirror_vert_chin 350 232 {} 350 282 361 239 361 279
	motorArrow $canvas mirror_slit_upper 217 59 {} 217 109 205 64 205 102
	motorArrow $canvas mirror_slit_lower 178 212 {} 178 262 191 217 191 258 
#	motorArrow $canvas mirror_pitch  460 235 {490 225 490 185} 460 175 481 238 480 173 
	motorArrow $canvas mirror_pitch 460 175 {490 185 490 225 } 460 235 480 173 481 238 	
	motorArrow $canvas mirror_bend 620 322 {} 620 372 631 329 631 369

	#bind $canvas <Button-1> "log %x %y"
}


proc construct_downward_mirror_window { parent } {
	
	# create the canvas to draw the mirror in
	set canvas [
		canvas $parent.canvas				\
			-width 660 							\
			-height 380							\
			-highlightthickness 0	]
	place $canvas -x 15 -y 10

	bind $canvas <Button-1> "activate_mdw_document mirror"
	bind $parent <Button-1> "activate_mdw_document mirror"

	# draw the lower slit
	rect_solid $canvas 160 152 5 50 20 30 30

	# draw the x-ray beam
	$canvas create line 27 183 355 135 612 180 -fill red -width 2 -arrow last

	# draw the upper slit
	rect_solid $canvas 200 97 5 50 20 30 30

	# draw the mirror
	rect_solid $canvas 240 110 200 10 20 30 20

	motorView $canvas mirror_slit_upper 122 112 s 140 45 13
	motorView $canvas mirror_vert_chin 349 182 n 140 45 13
	motorView $canvas mirror_bend 544 220 n
	motorView $canvas mirror_slit_lower 78 187 n 140 45 13
	motorView $canvas mirror_pitch 500 107 w 115 45 8
	motorView $canvas mirror_vert 356 68 s

	motorArrow $canvas mirror_vert 355 72 {} 355 122 366 79 366 119
	motorArrow $canvas mirror_slit_upper 217 59 {} 217 109 205 64 205 102
	motorArrow $canvas mirror_slit_lower 178 212 {} 178 262 191 217 191 258 
	motorArrow $canvas mirror_pitch  460 145 {490 135 490 95} 460 85 481 148 480 83 
}





proc construct_92_mono_window { parent } {

	# create the canvas to draw in
	set canvas [
		canvas $parent.canvas				\
			-width 800							\
			-height 400							\
			-highlightthickness 0	]
	place $canvas -x -5 -y 10

	bind $canvas <Button-1> "activate_mdw_document mono"
	bind $parent <Button-1> "activate_mdw_document mono"

	set x 50
	set y 9
	set name mono_slit
	
	# draw the ssrl slit 
	motorArrow $canvas mono_slit_ssrl 308 96 {} 274 119 305 111 283 126
	draw_slit $canvas 241 90
	motorView $canvas mono_slit_ssrl 347 89 s 120 43 10

	# draw the spear slit
	draw_slit $canvas 199 118
	motorView $canvas mono_slit_spear 120 189 n 130 43 11
	motorArrow $canvas mono_slit_spear 202 164 {} 168 187 193 157 173 172

	# draw the lower slit
	draw_slit $canvas 230 139
	motorArrow $canvas mono_slit_lower 248 199 {} 248 244 258 204 258 239
	motorView $canvas mono_slit_lower 267 244 n  130 43 11

	# draw the vert slit
	draw_slit $canvas 230 74
	motorArrow $canvas mono_slit_vert 248 41 {} 248 86 238 46 238 81 
	motorView $canvas mono_slit_vert 230 42 e 120 43 10

	# draw the fixed crystal 
	rect_solid $canvas 400 195 100 10 20 30 20	

	# draw the x-ray beam
	$canvas create line 68 105  199 140 -fill red -width 2
	$canvas create line 235 149 461 205 561 180 733 225 -fill red -width 2 -arrow last

	# draw the moving crystal 
	rect_solid $canvas 500 160 100 10 20 30 20

	motorView $canvas mono_pitch 645 130 w 130 45 10
	motorArrow $canvas mono_pitch  610 205 {640 195 640 155} 610 145 625 213 625 138

	motorView $canvas mono_roll 485 150 s 115 45 8
	motorArrow $canvas mono_roll 470 165 { 480 150 490 170 480 190 } 470 175 463 158 463 181
	$canvas create line 486 156 489 162 489 178 483 187 -fill lightgrey
		
	motorView $canvas mono_theta 515 263 n 115 45 8
	motorArrow $canvas mono_theta  540 230 {530 260 490 260} 480 230 551 238 467 241
	
	motorView $canvas energy 725 226 n

	$canvas create line 508 171 460 171 -fill blue -width 2
	
#bind $canvas <Button-1> "log %x %y"	

}


proc construct_11_mono_window { parent } {

	# global variables
	global gColors

	# create the canvas to draw in
	set canvas [
		canvas $parent.canvas				\
			-width 800							\
			-height 400							\
			-highlightthickness 0	]
	place $canvas -x -5 -y 10

	bind $canvas <Button-1> "activate_mdw_document mono"
	bind $parent <Button-1> "activate_mdw_document mono"

	set x 50
	set y 9
	set name mono_slit
	
	# draw the spear slit
	draw_slit $canvas 199 118
	motorView $canvas mono_slit 150 189 n 130 43 11
	motorArrow $canvas mono_slit 202 164 {} 168 187 193 157 173 172

	# draw the x-ray beam
	$canvas create line 67 158  199 144 -fill red -width 2
		# draw the crystal 
	rect_solid $canvas 270 110 130 30 5 7 3
	$canvas create line 235 140 331 129 733 175 -fill red -width 2 -arrow last

	motorView $canvas mono_angle 337 89 s 115 45 8
#	motorArrow $canvas mono_angle 335 84 { 315 94 335 104 355 94 } 340 84 323 77 346 77 
	$canvas create line 338 113 338 95 -fill blue -width 2
		
	motorView $canvas mono_theta 337 192 n 115 45 8
	motorArrow $canvas mono_theta 335 164 { 315 174 335 184 355 174 } 340 164 323 157 346 157 
	$canvas create line 338 190 338 147 -fill blue -width 2
	
	motorView $canvas energy 725 150 s

	motorView $canvas mono_bend 438 110 sw 115 45 8
	motorArrow $canvas mono_bend 403 128 {} 438 105 409 111 430 96

	$canvas create poly 360 175 380 175 645 205 635 205 360 175 \
		-fill $gColors(top)
	$canvas create line 360 175 400 175 645 205 605 205 360 175
		
	$canvas create poly 360 176 360 185 605 217 605 207 360 176 \
		-fill $gColors(front)		
	$canvas create line 360 176 360 185 605 217 605 206
		
	$canvas create poly 605 217 605 206 645 206 645 217 605 217 \
		-fill $gColors(front)	
	$canvas create line 605 217 605 205 645 205 645 217 605 217

	motorArrow $canvas table_slide 562 226 {} 604 226 567 236 600 236
	motorView $canvas table_slide 559 248 n
				
	motorArrow $canvas table_2theta 650 230 {725 227} 675 210  655 241  679 201
	motorView $canvas table_2theta 659 232 nw
				
	bind $canvas <Button-1> "log %x %y"	
}





proc construct_new_table_window { parent } {

	# create the canvas to draw the table in
	set canvas [
		canvas $parent.canvas				\
			-width 660 							\
			-height 320							\
			-highlightthickness 0	]
	place $canvas -x -15 -y -5

	bind $canvas <Button-1> "activate_mdw_document table"
	bind $parent <Button-1> "activate_mdw_document table"

	# draw the table
	rect_solid $canvas 180 120 250 20 40 60 40

	# create views for each motor
	motorView $canvas table_vert_1 190  90 s
	motorView $canvas table_vert 	 330  90 s 
	motorView $canvas table_vert_2 470  90 s
	motorView $canvas table_horz_1 135 197 n
	motorView $canvas table_horz 	 275 197 n
	motorView $canvas table_horz_2 415 197 n
	motorView $canvas table_yaw 	 143 137 e 105 45 7
	motorView $canvas table_pitch  507 137 w 105 45 7
	
	# create arrow for each motor
	motorArrow $canvas table_vert_1 210  90 {} 210 140 222 94 222 140
	motorArrow $canvas table_vert   330  90 {} 330 140	342 94 342 140
	motorArrow $canvas table_vert_2 450  90 {} 450 140 462 95 462 140
	motorArrow $canvas table_horz_1  190 170 {} 158 197 198 172 176 196
	motorArrow $canvas table_horz   305 170 {} 272 197 313 172 291 196
	motorArrow $canvas table_horz_2 430 170 {} 403 197 442 177 422 196
	motorArrow $canvas table_yaw    165 165 {125 137} 200 135 154 172 186 125
	motorArrow $canvas table_pitch  470  110 {500 120 500 160} 470 170 486 104 486 176

#	global gColors
#	$canvas create bitmap 90 8 -bitmap "@locked_padlock.bit" \
#		-foreground red
	
#bind $canvas <Button-1> "log %x %y"	
}


proc handle_network_error {} {

	# global variables
	global gWindows
	
	set gWindows(networkStatusText) "Offline"
	$gWindows(networkStatus) configure -fg black
	
	log_note "Disconnecting from server..."
	
	$gWindows(networkMenu) entryconfigure 0 -state disabled
	$gWindows(networkMenu) entryconfigure 1 -state disabled
	$gWindows(networkMenu) entryconfigure 2 -state disabled
	
	catch { close $socket }	
}
