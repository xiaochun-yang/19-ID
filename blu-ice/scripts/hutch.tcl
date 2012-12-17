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


class HutchTab {

	# protected variables
	protected variable canvas
	protected variable frame
	protected variable applyButton
	protected variable cancelButton
	protected variable gonioPhiWidget
	protected variable gonioOmegaWidget
	protected variable detectorZWidget
	protected variable detectorYWidget
	protected variable detectorXWidget
	protected variable energyWidget
	protected variable unappliedChangesCount 0
	protected variable registeredMotorList {}
	protected variable motorWidgetMatches
	protected variable motorOfWidget
	protected variable motorWidget

	# public methods
	public method handleUpdateFromComponent
	public method cancelChanges
	public method applyChanges

	# protected methods
	protected method constructControlPanel
	protected method constructGoniometer
	protected method constructDetector
	protected method constructFrontend
	protected method constructBeamstop
	protected method constructAutomation
	protected method registerWidget
	protected method updateButtons

	constructor { path } {
	
		# global variables
		global gBeamline

		# store the path to the tab frame
		set frame $path
		
		# lay out the overall frame structure
		pack [set table [frame $frame.table]] -side top -fill both -expand true
		blt::table $table [frame $frame.00] 0,0
		blt::table $table [frame $frame.22] 2,2
		blt::table $table [frame $frame.11] 1,1
		
		# create the canvas 
		set canvas [ canvas $frame.canvas \
							  -width 1000 \
							  -height 600 ]
		pack $canvas -in $frame.11

		#bind $canvas <Button-1> "log_note %x %y"

		# construct the panel of control buttons
		constructControlPanel 0 0

		# construct the goniometer widgets
		constructGoniometer 440 250

		# construct the detector widgets
		constructDetector 0 0

		# construct the frontend widgets
		constructFrontend 0 0

		# construct the beamstop widgets
		constructBeamstop 0 0

		# create the tab notebook for holding the sample position and overview widgets
		global gColors
		set videoNotebook \
			 [
			  iwidgets::tabnotebook $canvas.notebook  \
					-tabbackground lightgrey \
					-background lightgrey \
					-backdrop lightgrey \
					-borderwidth 2\
					-tabpos n \
					-gap -4 \
					-angle 20 \
					-width 513 \
					-height 290 \
					-raiseselect 1 \
					-bevelamount 4 \
					-tabforeground $gColors(dark) \
					-padx 5 -pady 4]
		place $canvas.notebook -x 185 -y 290 

		# create an object to monitor the status of the video tabbed notebook
		uplevel \#0 TabbedNotebookStatus hutchVideoNotebookStatus

		# construct the sample position widgets
		$videoNotebook add \
			 -label "Position Sample"	\
			 -command "hutchVideoNotebookStatus configure -activeTab Sample"
		SamplePositioningWidget \#auto [$videoNotebook childsite 0] \
			-tabbedNotebookStatusObject hutchVideoNotebookStatus \
			-mainTabName "Hutch"

		# construct the hutch view widgets
		$videoNotebook add \
			 -label "View Hutch" \
			 -command "hutchVideoNotebookStatus configure -activeTab Hutch"
		HutchViewWidget \#auto [$videoNotebook childsite 1] \
			-tabbedNotebookStatusObject hutchVideoNotebookStatus \
			-mainTabName "Hutch"

		# select the sample position tab first
		$videoNotebook select 0

		# construct the resolution widgets
		ResolutionWidget \#auto $canvas.res \
			 $gBeamline(detector) \
			 HutchTab::$detectorXWidget \
			 HutchTab::$detectorYWidget \
			 HutchTab::$detectorZWidget \
			 HutchTab::$energyWidget
		place $canvas.res -x 700 -y 288

		# construct the automation widgets
		constructAutomation 5 288

		# register for changes in client state
		clientState register $this master
	}
}


body HutchTab::constructControlPanel { x y } {

	# create the apply button
	set applyButton [button $canvas.apply \
								-text "Start" \
								-font "helvetica -18 bold" \
								-width 7 \
								-state disabled \
								-bg \#c0c0ff \
								-activebackground \#c0c0ff \
								-command "$this applyChanges" ]
	place $applyButton -x 30 -y 20
	DynamicHelp::register $applyButton balloon \
		 "Starts motor moves\nto new positons"
	
	# create the cancel button
	set cancelButton [button $canvas.cancel \
								 -text "Cancel" \
								 -font "helvetica -18 bold" \
								 -width 7 \
								 -state disabled \
								 -bg \#c0c0ff \
								 -activebackground \#c0c0ff \
								 -command "$this cancelChanges" ]
	place $cancelButton -x 140 -y 20
	DynamicHelp::register $cancelButton balloon \
		 "Cancels changes to\nmotor positons"
	
	# create the stop button
	set stopButton [button $canvas.stop \
							  -text "Stop" \
							  -font "helvetica -18 bold" \
							  -width 7 \
							  -bg \#ffaaaa \
							  -activebackground \#ffaaaa \
							  -command "do_command abort" ]
	place $stopButton -x 250 -y 20
	DynamicHelp::register $stopButton balloon \
		 "Immediately stops all motors\nand halts all operations"
}


body HutchTab::constructGoniometer { x y } {

	# draw and label the goniometer
	global BLC_IMAGES
	set goniometerImage [ image create photo -file "$BLC_IMAGES/gonio.gif" -palette "8/8/8"]
	$canvas create image $x [expr $y - 190] -anchor nw -image $goniometerImage
	
	# create motor view for gonio_phi
	set gonioPhiWidget [ EditableMotorView \#auto $canvas.phi gonio_phi \
									 -label "Phi" \
									 -autoMenuChoices 0 \
									 -menuChoices {0.000 45.000 90.000 135.000 180.000 \
															 225.000 270.000 315.000 360.000} ]
	place $canvas.phi -x [expr $x + 20]  -y [expr $y - 245]
	registerWidget gonio_phi $gonioPhiWidget
	
	# create motor view for gonio_omega
	set gonioOmegaWidget [ EditableMotorView \#auto $canvas.omega gonio_omega \
										-label "Omega" \
										-menuChoiceDelta 15 ]
	place $canvas.omega -x [expr $x - 110] -y [expr $y -185]
	registerWidget gonio_omega $gonioOmegaWidget
	
	# create motor view for gonio_kappa
	set gonioKappaWidget [ EditableMotorView \#auto $canvas.kappa gonio_kappa \
										-label "Kappa" \
										-menuChoiceDelta 5 ]
	place $canvas.kappa -x [expr $x + 140] -y [expr $y - 185]
	registerWidget gonio_kappa $gonioKappaWidget
}


body HutchTab::constructDetector { x y } {

	# draw and label the detector
	global BLC_IMAGES
	global gBeamline
	switch $gBeamline(detector) {

		Q4CCD {
			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/q4_small.gif" \
											-palette "8/8/8"]
			$canvas create image 820 90 \
				 -anchor nw \
				 -image $detectorImage

			# create motor view for detector_vert
			set detectorYWidget [ EditableMotorView \#auto $canvas.detector_vert detector_vert \
											  -label "Vertical" \
											  -menuChoiceDelta 25 ]
			place $canvas.detector_vert -x 835 -y 0
			registerWidget detector_vert $detectorYWidget
			$canvas create line 900 55 900 95 -arrow both -width 3 -fill black	
			$canvas create text 910 61 -text "+" -font "courier -10 bold"
			$canvas create text 910 88 -text "-" -font "courier -10 bold"
			
			# create motor view for detector_z
			set detectorZWidget [ EditableMotorView \#auto $canvas.detector_z_corr detector_z_corr \
											  -label "Distance" \
											  -menuChoiceDelta 50 \
											  -valueType positiveFloat ]
			place $canvas.detector_z_corr -x 660 -y 125
			registerWidget detector_z_corr $detectorZWidget
			$canvas create line 796 157 821 157 -arrow first -width 3 -fill black
			$canvas create line 821 157 836 157 -arrow last  -width 3 -fill white
			$canvas create text 800 148 -text "-" -font "courier -10 bold"
			$canvas create text 835 148 -text "+" -font "courier -10 bold" -fill white
			
			# create motor view for detector_horiz
			set detectorXWidget [ EditableMotorView \#auto $canvas.detector_horz detector_horz \
											  -label "Horizontal" \
											  -menuChoiceDelta 25  ]
			place $canvas.detector_horz -x 855 -y 212
			registerWidget detector_horz $detectorXWidget
			$canvas create line 913 185 942 212 -arrow both -width 3 -fill black	
			$canvas create text 927 188 -text "+" -font "courier -10 bold"
			$canvas create text 948 207 -text "-" -font "courier -10 bold"	
		}
		
		Q315CCD {
			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/q4_small.gif" \
											-palette "8/8/8"]
			$canvas create image 820 90 \
				 -anchor nw \
				 -image $detectorImage

			# create motor view for detector_vert
			set detectorYWidget [ EditableMotorView \#auto $canvas.detector_vert detector_vert \
											  -label "Vertical" \
											  -menuChoiceDelta 25 ]
			place $canvas.detector_vert -x 835 -y 0
			registerWidget detector_vert $detectorYWidget
			$canvas create line 900 55 900 95 -arrow both -width 3 -fill black	
			$canvas create text 910 61 -text "+" -font "courier -10 bold"
			$canvas create text 910 88 -text "-" -font "courier -10 bold"
			
			# create motor view for detector_z_corr
			set detectorZWidget [ EditableMotorView \#auto $canvas.detector_z_corr detector_z_corr \
											  -label "Distance" \
											  -menuChoiceDelta 50 \
											  -valueType positiveFloat ]
			place $canvas.detector_z_corr -x 660 -y 125
			registerWidget detector_z_corr $detectorZWidget
			$canvas create line 796 157 821 157 -arrow first -width 3 -fill black
			$canvas create line 821 157 836 157 -arrow last  -width 3 -fill white
			$canvas create text 800 148 -text "-" -font "courier -10 bold"
			$canvas create text 835 148 -text "+" -font "courier -10 bold" -fill white
			
			# create motor view for detector_horiz
			set detectorXWidget [ EditableMotorView \#auto $canvas.detector_horz detector_horz \
											  -label "Horizontal" \
											  -menuChoiceDelta 25  ]
			place $canvas.detector_horz -x 855 -y 212
			registerWidget detector_horz $detectorXWidget
			$canvas create line 913 185 942 212 -arrow both -width 3 -fill black	
			$canvas create text 927 188 -text "+" -font "courier -10 bold"
			$canvas create text 948 207 -text "-" -font "courier -10 bold"	
		}

		MAR345 {

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar_small.gif" \
											-palette "8/8/8"]
			$canvas create image 815 53 \
				 -anchor nw \
				 -image $detectorImage

			# create motor view for detector_vert
			set detectorYWidget [ EditableMotorView \#auto $canvas.detector_vert detector_vert \
											  -label "Vertical" \
											  -menuChoiceDelta 25 ]
			place $canvas.detector_vert -x 835 -y 0
			registerWidget detector_vert $detectorYWidget
			$canvas create line 900 55 900 95 -arrow both -width 3 -fill black	
			$canvas create text 910 61 -text "+" -font "courier -10 bold"
			$canvas create text 910 88 -text "-" -font "courier -10 bold"
			
			# create motor view for detector_z_corr
			set detectorZWidget [ EditableMotorView \#auto $canvas.detector_z_corr detector_z_corr \
											  -label "Distance" \
											  -menuChoiceDelta 50 \
											  -valueType positiveFloat ]
			place $canvas.detector_z_corr -x 657 -y 125
			registerWidget detector_z_corr $detectorZWidget
			$canvas create line 791 157 821 157 -arrow both -width 3 -fill black
			$canvas create text 796 148 -text "-" -font "courier -10 bold"
			$canvas create text 817 148 -text "+" -font "courier -10 bold"
		
			# create motor view for detector_horiz
			set detectorXWidget [ EditableMotorView \#auto $canvas.detector_horz detector_horz \
											  -label "Horizontal" \
											  -menuChoiceDelta 25  ]
			place $canvas.detector_horz -x 855 -y 235
			registerWidget detector_horz $detectorXWidget
			$canvas create line 903 210 915 222 -arrow first -width 3 -fill white
			$canvas create line 915 222 927 234 -arrow last -width 3 -fill black
			$canvas create text 898 215 -text "+" -font "courier -10 bold" -fill white
			$canvas create text 911 232 -text "-" -font "courier -10 bold"			
		}

		MAR165 {

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar165.gif" \
											-palette "8/8/8"]
			$canvas create image 817 107 \
				 -anchor nw \
				 -image $detectorImage

			# create motor view for detector_vert
			set detectorYWidget [ EditableMotorView \#auto $canvas.detector_vert detector_vert \
											  -label "Vertical" \
											  -menuChoiceDelta 25 ]
			place $canvas.detector_vert -x 835 -y 30
			registerWidget detector_vert $detectorYWidget
			$canvas create line 900 85 900 125 -arrow both -width 3 -fill black	
			$canvas create text 910 91 -text "+" -font "courier -10 bold"
			$canvas create text 910 1288 -text "-" -font "courier -10 bold"
			
			# create motor view for detector_z_corr
			set detectorZWidget [ EditableMotorView \#auto $canvas.detector_z_corr detector_z_corr \
											  -label "Distance" \
											  -menuChoiceDelta 50 \
											  -valueType positiveFloat ]
			place $canvas.detector_z_corr -x 657 -y 125
			registerWidget detector_z_corr $detectorZWidget
			$canvas create line 791 157 821 157 -arrow both -width 3 -fill black
			$canvas create text 796 148 -text "-" -font "courier -10 bold"
			$canvas create text 817 148 -text "+" -font "courier -10 bold"
		
			# create motor view for detector_horiz
			set detectorXWidget [ EditableMotorView \#auto $canvas.detector_horz detector_horz \
											  -label "Horizontal" \
											  -menuChoiceDelta 25  ]
			place $canvas.detector_horz -x 855 -y 203
			registerWidget detector_horz $detectorXWidget
			$canvas create line 903 178 915 190 -arrow first -width 3 -fill white
			$canvas create line 915 190 927 202 -arrow last -width 3 -fill black
			$canvas create text 898 183 -text "+" -font "courier -10 bold" -fill white
			$canvas create text 911 200 -text "-" -font "courier -10 bold"			
		}
	}
}


body HutchTab::constructFrontend { x y } {

	# create the image of the frontend
	global BLC_IMAGES
	set frontendImage [ image create photo \
									-file "$BLC_IMAGES/frontend.gif" \
									-palette "8/8/8"]
	$canvas create image 50 72 -anchor nw -image $frontendImage

	# draw the label for the frontend
	label $canvas.frontendLabel \
		 -font "helvetica -18 bold" \
		 -text "Beam Collimator"
#	place $canvas.frontendLabel -x 130 -y 265

	# draw the X-ray beam
	$canvas create line 0 161 58 161 -fill magenta -width 4

	PostShutterBeamView \#auto $canvas shutter 383 163 620 163

	# create motor view for energy
	set energyWidget [ EditableMotorView \#auto $canvas.energy energy \
								  -label "Energy" \
								  -menuChoiceDelta 1000 \
								  -valueType positiveFloat \
								  -decimalPlaces 2]
	place $canvas.energy -x 15 -y 200
	registerWidget energy $energyWidget

	# create motor view for detector_horiz
	set beamWidthWidget [ EditableMotorView \#auto $canvas.beam_width beam_size_x \
									  -label "Width" \
									  -menuChoiceDelta 0.05 \
									  -valueType positiveFloat	\
									  -decimalPlaces 2 \
									  -entryWidth 5 \
									  -width 90  ]
	place $canvas.beam_width -x 211 -y 200
	registerWidget beam_size_x $beamWidthWidget

	# create motor view for detector_horiz
	set beamHeightWidget [ EditableMotorView \#auto $canvas.beam_height beam_size_y \
										-label "Height" \
										-entryWidth 5 \
										-width 90 \
										-decimalPlaces 2 \
										-menuChoiceDelta 0.05]
	place $canvas.beam_height -x 330 -y 200
	registerWidget beam_size_y $beamHeightWidget

	$canvas create text 325 233 -text "x" -font "helvetica -14 bold"
	$canvas create text 325 265 -text "Beam Size" -font "helvetica -16 bold"

	# create motor view for beam attenuation
	set attenuationWidget [ EditableMotorView \#auto $canvas.attenuation attenuation \
										 -label "Attenuation" \
										 -entryWidth 5 \
										 -width 82 \
										 -valueType positiveFloat \
										 -decimalPlaces 1 \
										 -menuChoiceDelta 10]
	place $canvas.attenuation -x 80 -y 90
	registerWidget attenuation $attenuationWidget
}


body HutchTab::constructBeamstop { x y } {

	# create the image of the frontend
	global BLC_IMAGES
	set beamstopImage [ image create photo -file "$BLC_IMAGES/beamstop.gif" -palette "8/8/8"]
	$canvas create image 570 159 -anchor nw -image $beamstopImage

	# draw the label for the frontend
	label $canvas.beamstopLabel \
		 -font "helvetica -18 bold" \
		 -text "Beamstop"
#	place $canvas.beamstopLabel -x 530 -y 265
	
	# create motor view for beamstop_z
	set beamstopWidget [ EditableMotorView \#auto $canvas.beamstop beamstop_z \
								  -label "Beamstop" \
								  -menuChoiceDelta 5 \
								  -valueType positiveFloat \
								  -decimalPlaces 3]
	place $canvas.beamstop -x 530 -y 225
	registerWidget beamstop_z $beamstopWidget

	# draw arrow for beam stop motion
	$canvas create line 580 190 620 190 -arrow both -width 3 -fill black	
	$canvas create text 613 180 -text "+" -font "courier -10 bold"
	$canvas create text 584 180 -text "-" -font "courier -10 bold"
}


body HutchTab::constructAutomation { x y } {
	
	# create labeled frame for automation buttons
	set automationFrame [LabeledFrame \#auto $canvas.automation \
										  -width 150 \
										  -height 255 \
										  -background lightgrey \
										  -labelBackground lightgrey \
										  -labelFont "helvetica -18 bold" \
										  -text "Automation" ]
	place $canvas.automation -x $x -y $y
	
	# get the internal frame of the labeled frame
	set autoFrame [$automationFrame getFrame]
	$autoFrame configure -width 150 -height 255

	# make the center loop button
	MultipleObjectsButton \#auto $autoFrame.center  {clientState master 1 \
																		  centerLoopStatus status inactive \
																		  collectRunsStatus status inactive \
																		  collectRunStatus status inactive \
																		  collectFrameStatus status inactive } \
		 -command "start_operation centerLoop" \
		 -text "Center Loop"\
		 -width 14
	place $autoFrame.center -x 10 -y 20

	# make the optimize beam button
	MultipleObjectsButton \#auto $autoFrame.optimize  {clientState master 1 \
																	 optimizeStatus status inactive \
																	 collectRunsStatus status inactive \
																	 normalizeStatus status inactive \
                                                    device::optimized_energy status inactive \
                                                    device::energy status inactive  } \
		 -command "move energyLastTimeOptimized to 0 s ; move optimized_energy by 0 eV" \
		 -text "Optimize Beam"\
		 -width 14
	place $autoFrame.optimize -x 10 -y 60

	global gBeamline
	if { 0 && $gBeamline(doubleMono) } {
		
		# make the fluorescence detector in button
		MotorMoveButton \#auto $autoFrame.flIn fluorescence_z clientState \
			 -command "move fluorescence_z to 11.0 scaled" \
			 -text "Insert Detector" \
			 -width 14 \
			 -target 11.0
		place $autoFrame.flIn -x 10 -y 100
		
		# make the fluorescence detector out button
		MotorMoveButton \#auto $autoFrame.flOut fluorescence_z clientState \
			 -command "move fluorescence_z to 74.5 scaled" \
			 -text "Retract Detector" \
			 -width 14 \
			 -target 74.5
		place $autoFrame.flOut -x 10 -y 140
	}
}


body HutchTab::registerWidget { motor widget } {

	# add to the list of registered widgets
	#lappend registeredWidgetList ::HutchTab::${widget}
	lappend registeredMotorList $motor

	set comboBox ::EditableMotorView::[$widget getComboBox]

	set motorOfWidget($comboBox) $motor
	set motorWidget($motor) $comboBox

	# store the status of the widget
	set motorWidgetMatches($motor) [$comboBox cget -referenceMatches]

	# register for changes in the widget status
	$comboBox register $this referenceMatches
} 
 

body HutchTab::handleUpdateFromComponent { component attribute value } {

	switch $attribute {

		# update button states if master status changes
		master {
			updateButtons
		}

		# update button states
		referenceMatches {
			set motorWidgetMatches($motorOfWidget($component)) $value
			updateButtons
		}
	}
}


body HutchTab::updateButtons {} {

	# count the number of unapplied changes
	set unappliedChanges 0
	foreach motor $registeredMotorList {
		if { $motorWidgetMatches($motor) == 0 } {
			incr unappliedChanges
		}
	}

	# enable cancel button if any unapplied changes
	if { $unappliedChanges > 0 } {
		$cancelButton configure -state normal
	} else {
		$cancelButton configure -state disabled
	}

	# enable apply button if any unapplied changes and client is master
	if { $unappliedChanges > 0 && [clientState cget -master]} {
		$applyButton configure -state normal
	} else {
		$applyButton configure -state disabled
	}
}


body HutchTab::cancelChanges {} {
	
	# cancel changes in each widget
	foreach motor $registeredMotorList {
		if { $motorWidgetMatches($motor) == 0 } {
			$motorWidget($motor) updateFromReference
		}
	}
}


body HutchTab::applyChanges {} {
	
	# disable the apply button
	$applyButton configure -state disabled

	# apply changes in each widget
	foreach motor $registeredMotorList {
		if { $motorWidgetMatches($motor) == 0 } {
			do_command "move $motor to [$motorWidget($motor) getValue] [$motorWidget($motor) cget -units]"
		}
	}
}


class ResolutionWidget {

	# protected variables
	protected variable detectorFace
	protected variable detectorXWidget
	protected variable detectorYWidget

	# protected methods
	protected method constructMarModeWidget

	# public methods
	public method handleUpdateFromComponent
	public method handleResolutionClick

	constructor { path detectorType xWidget yWidget zWidget eWidget } {

		# store the names of the x and y widgets
		set detectorXWidget $xWidget
		set detectorYWidget $yWidget
		
		# create the resolution widget frame
		set resolutionFrame [LabeledFrame \#auto $path \
										 -width 250 \
										 -height 255 \
										 -background lightgrey \
										 -labelBackground lightgrey \
										 -labelFont "helvetica -18 bold" \
										 -text "Resolution Predictor" ]
		
		# create the resolution widget
		switch $detectorType {
			
			Q4CCD {
				set detectorFace [RectangularDetectorFace \#auto $path.face \
											 -canvasWidth 				240 	\
											 -canvasHeight				240 	\
											 -pixelsPerMM				0.9	\
											 -detectorWidthInMM		186 	\
											 -detectorHeightInMM		186 	\
											 -moduleNumber				4
									  ]
			}
			
			Q315CCD {
				set detectorFace [RectangularDetectorFace \#auto $path.face \
											 -canvasWidth 				240 	\
											 -canvasHeight				220 	\
											 -pixelsPerMM				0.5	\
											 -detectorWidthInMM		315 	\
											 -detectorHeightInMM		315 	\
											 -moduleNumber				9
									  ]
			}
			
			
			MAR345 {
				set detectorFace [CircularDetectorFace \#auto $path.face \
											 -canvasWidth 				240 	\
											 -canvasHeight				220 	\
											 -pixelsPerMM				0.45	\
											 -detectorRadiusInMM		172.5
										
									  ]
				
				constructMarModeWidget $path.marMode 40 260
			}


			MAR165 {
				set detectorFace [CircularDetectorFace \#auto $path.face \
											 -canvasWidth 				240 	\
											 -canvasHeight				220 	\
											 -pixelsPerMM				1.0	\
											 -detectorRadiusInMM		82.5	]
			}

			
		}
		
		$detectorFace configure \
			 -detectorXWidget ::EditableMotorView::[$xWidget getComboBox] \
			 -detectorYWidget ::EditableMotorView::[$yWidget getComboBox] \
			 -detectorZWidget ::EditableMotorView::[$zWidget getComboBox] \
			 -energyWidget ::EditableMotorView::[$eWidget getComboBox] \
			 -onClick "$this handleResolutionClick"
		
		place $path.face -x 15 -y 30
	}
}


body ResolutionWidget:::constructMarModeWidget { path x y } {
	
	# create the combo box in the user frame
	set marComboBox [ComboBox \#auto $path \
								-prompt "Detector Radius:" \
								-background lightgrey \
								-unitsAnchor w \
								-entryWidth 5 \
								-value 345 \
								-units "mm" \
								-showEntry 0 \
								-type string \
						 ]
	
	$marComboBox configure\
		 -menuChoices { 180 240 300 345 }
	
	place $path -x $x -y $y

	$marComboBox register $this value
}


body ResolutionWidget::handleResolutionClick { x y } {

	# get current limits on detector position
	set horzUpperLimit [device::detector_horz getEffectiveUpperLimit]
	set horzLowerLimit [device::detector_horz getEffectiveLowerLimit]
	set vertUpperLimit [device::detector_vert getEffectiveUpperLimit]
	set vertLowerLimit [device::detector_vert getEffectiveLowerLimit]

	# enforce upper limit on horz
	if { $x > $horzUpperLimit } { 
		set x $horzUpperLimit
		log_warning "Selected detector position exceeds upper limit on horizontal travel."
	}

	# enforce lower limit on horz
	if { $x < $horzLowerLimit } { 
		set x $horzLowerLimit 
		log_warning "Selected detector position exceeds lower limit on horizontal travel."
	}

	# enforce upper limit on vert
	if { $y > $vertUpperLimit } { 
		set y $vertUpperLimit 
		log_warning "Selected detector position exceeds upper limit on vertical travel."
	}

	# enforce lower limit on vert
	if { $y < $vertLowerLimit } { 
		set y $vertLowerLimit 
		log_warning "Selected detector position exceeds lower limit on vertical travel."
	}

	# set detector x and y widgets to reflect the clicked position
	$detectorXWidget setValue $x
	$detectorYWidget setValue $y
}


body ResolutionWidget::handleUpdateFromComponent { component attribute value } {

	switch $attribute {

		value {
			# update radius of Mar detector
			$detectorFace configure -detectorRadiusInMM [expr $value / 2.0]
		}
	}
}

package require BIWVideo
class SamplePositioningWidget {

	# public variables
	public variable tabbedNotebookStatusObject
    public variable mainTabName

	# protected variables
	protected variable videoEnabled 1
	protected variable samplePositioningMotors { gonio_phi sample_x sample_y sample_z camera_zoom }
	protected variable sampleCanvas
	protected variable highlightFrame
	protected variable crosshair
	protected variable crosshairX 176
	protected variable crosshairY 120
	protected variable sampleMoving 1
	protected variable isMaster	0
	protected variable minimumHorzStep [expr 1.0/354]
	protected variable minimumVertStep [expr 1.0/240]
	protected variable sampleVideo
	protected variable videoTabName "Sample"

	# public methods
	public method handleUpdateFromComponent
	public method updateVideoRate
	public method handleVideoClick
	public method updateCrosshair
	public method updateHighlight

	# constructor
	constructor { sampleFrame args } {

		# global variables
		global gBeamline

		# evaluate configuration parameters
		eval configure $args

		# create the highlight
		set highlightFrame [frame $sampleFrame.inner -height 245 -width 354 -bg red]
		place $highlightFrame -x 149 -y 2

		set sampleCanvas [canvas $highlightFrame.canvas -height 240 -width 350]
		place $sampleCanvas -x 2 -y 3
		#$sampleCanvas configure -cursor "@crossfg.bmp crossbg.bmp  white red"
	
		# create the video image of the sample
		set sampleVideo [Video \#auto $sampleCanvas \
			${gBeamline(videoServerUrl)}${gBeamline(sampleVideoPath)} -parameters "&resolution=medium"]

		bind $sampleCanvas <Button-1> "$this handleVideoClick %x %y"
		
		# monitor state of main tabbed folder
		mainTabbedNotebookStatus register $this activeTab
		$tabbedNotebookStatusObject register $this activeTab
		
		# draw cross-hairs on image
		set crosshair [Crosshair \#auto $sampleCanvas \
								 -x $crosshairX \
								 -y $crosshairY \
								 -width 20 \
								 -height 20
							]

		# create the camera zoom label
		label $sampleFrame.zoomLabel \
			 -text "Select Zoom Level" \
			 -font "helvetica -14 bold"
		place $sampleFrame.zoomLabel -x 10 -y 5
		
		# make the low zoom button
		MotorMoveButton \#auto $sampleFrame.zoomLow camera_zoom clientState \
			 -command "move camera_zoom to 0 scaled" \
			 -text "Low" \
			 -width 2 \
			 -target 0.0
		place $sampleFrame.zoomLow -x 6 -y 32
		
		# make the medium zoom button
		MotorMoveButton \#auto $sampleFrame.zoomMed camera_zoom clientState \
			 -command "move camera_zoom to 0.75 scaled" \
			 -text "Med" \
			 -width 2 \
			 -target 0.75
		place $sampleFrame.zoomMed -x 53 -y 32
		
		# make the high zoom button
		MotorMoveButton \#auto $sampleFrame.zoomHigh camera_zoom clientState \
			 -command "move camera_zoom to 1 scaled" \
			 -text "High" \
			 -width 2 \
			 -target 1.0
		place $sampleFrame.zoomHigh -x 100 -y 32
		
		# create the fine motion label
		label $sampleFrame.fineLabel \
			 -text "Move Sample" \
			 -font "helvetica -14 bold"
		place $sampleFrame.fineLabel -x 22 -y 80

		# make the up tweak button
		ArrowOperationButton \#auto $sampleFrame.up moveSampleStatus clientState \
			 -command "start_operation moveSample 0.0 -$minimumVertStep" \
			 -direction up
		place $sampleFrame.up -x 63 -y 106
		
		# make the down tweak button
		ArrowOperationButton \#auto $sampleFrame.down moveSampleStatus clientState \
			 -command "start_operation moveSample 0.0 $minimumVertStep" \
			 -direction down
		place $sampleFrame.down -x 63 -y 150

		# make the left tweak button
		ArrowOperationButton \#auto $sampleFrame.left moveSampleStatus clientState \
			 -command "start_operation moveSample -$minimumHorzStep 0.0" \
			 -direction left
		place $sampleFrame.left -x 40 -y 128
		
		# make the right tweak button
		ArrowOperationButton \#auto $sampleFrame.right moveSampleStatus clientState \
			 -command "start_operation moveSample $minimumHorzStep 0.0" \
			 -direction right
		place $sampleFrame.right -x 86 -y 128

		# make the far left button
		ArrowOperationButton \#auto $sampleFrame.farLeft moveSampleStatus clientState \
			 -command "start_operation moveSample -0.5 0.0" \
			 -direction fastLeft
		place $sampleFrame.farLeft -x 13 -y 128

		# make the far right button
		ArrowOperationButton \#auto $sampleFrame.farRight moveSampleStatus clientState \
			 -command "start_operation moveSample 0.5 0.0" \
			 -direction fastRight
		place $sampleFrame.farRight -x 113 -y 128

		# create the phi label
		label $sampleFrame.phiLabel \
			 -text "Rotate Phi" \
			 -font "helvetica -14 bold"
		place $sampleFrame.phiLabel -x 32 -y 187
		
		# make the Phi -90 button
		MotorMoveButton \#auto $sampleFrame.minus90 gonio_phi clientState \
			 -command "move gonio_phi by -90 deg" \
			 -text "-90" \
			 -width 2
		place $sampleFrame.minus90 -x 6 -y 212
		
		# make the Phi +90 button
		MotorMoveButton \#auto $sampleFrame.plus90 gonio_phi clientState \
			 -command "move gonio_phi by 90 deg" \
			 -text "+90" \
			 -width 2
		place $sampleFrame.plus90 -x 53 -y 212
		
		# make the Phi +180 button
		MotorMoveButton \#auto $sampleFrame.plus180 gonio_phi clientState \
			 -command "move gonio_phi by 180 deg" \
			 -text "180" \
			 -width 2
		place $sampleFrame.plus180 -x 100 -y 212
		
		# set up reference to the sample positioning motor status
		foreach motor $samplePositioningMotors {
			device::$motor register $this status
		}

		# monitor position of the spindle rotation axis
		device::zoomMaxYAxis register $this scaledPosition
		device::zoomMaxXAxis register $this scaledPosition

		# register for changes in client state
		clientState register $this master
	}
}


body SamplePositioningWidget::handleVideoClick { x y } {

	# global variables
	global gDevice

	if { $isMaster && ! $sampleMoving } {
		
		set deltaX [expr ($crosshairX - $x) / $gDevice(sampleImageWidth,scaled) ]
		set deltaY [expr ($crosshairY - $y) / $gDevice(sampleImageHeight,scaled) ]
		
		start_operation moveSample $deltaX $deltaY
	}
}


body SamplePositioningWidget::handleUpdateFromComponent { component attribute value } {

	# global variables
	global gDevice

	switch $attribute {

		master {
			set isMaster $value
			updateHighlight
		}

		status {
			updateVideoRate
			updateHighlight
		}

		activeTab {
			updateVideoRate
		}

		scaledPosition {

			switch $component {
				
				::device::zoomMaxXAxis {
					set crosshairX [expr $value * $gDevice(sampleImageWidth,scaled)]
					updateCrosshair
				}

				::device::zoomMaxYAxis {
					set crosshairY [expr $value * $gDevice(sampleImageHeight,scaled)]
					updateCrosshair
				}
			}
		}
	}
}


body SamplePositioningWidget::updateCrosshair {} {

	# update the position of the crosshair
	$crosshair moveTo $crosshairX $crosshairY
}


body SamplePositioningWidget::updateHighlight {} {

	if { $isMaster && ! $sampleMoving } {

		$highlightFrame configure -bg red
	} else {

		$highlightFrame configure -bg lightgrey
	}
}


body SamplePositioningWidget::updateVideoRate {} {

	# check if any of the sample motors are moving
	set sampleMoving 0
	foreach motor $samplePositioningMotors {
		if { [device::$motor cget -status] != "inactive" } {
			set sampleMoving 1
			break
		}
	}

	# enable video only if appropriate main Blu-Ice tab and video sub-tab are currently selected
	if { [mainTabbedNotebookStatus cget -activeTab] == $mainTabName && 
		  [$tabbedNotebookStatusObject cget -activeTab] == $videoTabName } {
		set videoEnabled 1 
		$sampleVideo configure -enabled 1
	} else {
		set videoEnabled 0
		$sampleVideo configure -enabled 0
	}
	
	# switch to high video rate if sample motors moving and currently at slow rate
	if { $sampleMoving && $videoEnabled } {
		$sampleVideo configure -updatePeriod 50 -parameters "&resolution=medium"
	} else {
		$sampleVideo configure -updatePeriod 1000 -parameters "&resolution=medium"
	}
}


class HutchViewWidget {
	
	# public variables
    public variable mainTabName
	public variable tabbedNotebookStatusObject ""

	# protected variables 
	protected variable videoServerCgiPath &clock=0&date=0&text=0
	protected variable videoEnabled 1
	protected variable motorsMoving 1
	protected variable sampleVideo
	protected variable visibleMotors \
		 { gonio_phi gonio_omega gonio_kappa detector_z_corr detector_horz detector_vert beamstop_z fluorescence_z }
	protected variable httpToken
  	protected variable videoTabName "Hutch"

	# public methods
	public method handleUpdateFromComponent
	public method updateVideoRate
	public method moveToPreset
	public method updatePresetButtons

	# constructor
	constructor { frame args } {

		# global variables
		global gBeamline

		# evaluate configuration parameters	
		eval configure $args

		# create the canvas for the video image
		canvas $frame.canvas
		place $frame.canvas -x 151 -y 5

		# construct the URL for getting images of the sample

		# create the camera zoom label
		label $frame.label \
			 -text "Select Preset" \
			 -font "helvetica -14 bold"
		place $frame.label -x 25 -y 5

		# request the list of presets
		if { [catch {set httpToken [http::geturl \
			${gBeamline(videoServerUrl)}${gBeamline(ptzPath)}?query=presetposall \
			-command "$this updatePresetButtons $frame" ] } err ] } {
				log_error "Error retrieving presets for hutch video: $err"
		}
		
		# create the video image of the sample
		set sampleVideo [Video \#auto $frame.canvas \
			${gBeamline(videoServerUrl)}${gBeamline(hutchVideoPath)} -parameters "&resolution=high"]

		# monitor state of main tabbed folder
		mainTabbedNotebookStatus register $this activeTab
		$tabbedNotebookStatusObject register $this activeTab

		# set up reference to the sample positioning motor status
		foreach motor $visibleMotors {
			device::$motor register $this status
		}

		# register for changes in client state
		clientState register $this master
	}
}


body HutchViewWidget::updatePresetButtons { frame args } {
	
	# get the result of the http request
	set result [http::data $httpToken]

	# parse the result for the token names and create buttons for each
	if { [string first < $result] == -1 } {

		# replace all equal signs with spaces
		while { [set nextEqualSign [string first = $result]] != -1 } {
			set result [string replace $result $nextEqualSign $nextEqualSign " "] 
		}

		# count the tokens to parse
		set tokenCount [llength $result]
		
		# create buttons for each preset
		set y 35
		for { set i 1 } { $i < $tokenCount } { incr i 2 } {
			
			set presetName [lindex $result $i]
			set buttonPath $frame.[getUniqueName]
			OperationButton \#auto $buttonPath ptzStatus clientState \
				 -command "$this moveToPreset $presetName" \
				 -text $presetName \
				 -width 10
			place $buttonPath -x 25 -y $y
			incr y 35
		}			
	}
}


body HutchViewWidget::moveToPreset { presetName } {

	# global variables
	global gBeamline

	# disable ptz buttons
	ptzStatus configure -status active

	if { $gBeamline(liveVideo) } {
		
		# request the specified preset
		http::geturl ${gBeamline(videoServerUrl)}${gBeamline(ptzPath)}?gotoserverpresetname=$presetName
		
		# change the title text on the video to match
		http::geturl ${gBeamline(videoTitleUrl)}&text=$presetName
	}

	# reenable ptz buttons after a short delay
	after 100 "ptzStatus configure -status inactive "
}


body HutchViewWidget::handleUpdateFromComponent { component attribute value } {

	switch $attribute {

		master {
			set isMaster $value
		}

		status {
			updateVideoRate
		}

		activeTab {
			updateVideoRate
		}

		scaledPosition {
			updateCrosshair
		}
	}
}


body HutchViewWidget::updateVideoRate {} {

	# check if any of the sample motors are moving
	set motorsMoving 0
	foreach motor $visibleMotors {
		if { [device::$motor cget -status] != "inactive" } {
			set motorsMoving 1
			break
		}
	}

	# enable video only if appropriate main Blu-Ice tab and video sub-tab are currently selected
	if { [mainTabbedNotebookStatus cget -activeTab] == $mainTabName  && 
		  [$tabbedNotebookStatusObject cget -activeTab] == $videoTabName } {
		set videoEnabled 1 
		$sampleVideo configure -enabled 1
	} else {
		set videoEnabled 0
		$sampleVideo configure -enabled 0
	}
	
	# switch to high video rate if sample motors moving and currently at slow rate
	if { $motorsMoving && $videoEnabled } {
		$sampleVideo configure -updatePeriod 50  -parameters "&resolution=medium"
	} else {
		$sampleVideo configure -updatePeriod 1000 -parameters "&resolution=high"
	}
}
