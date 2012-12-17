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

runCalculator runSequence
runSequence setRunDefinition 1.0 2.0 1.0 180.0 0 1 {10000 11000 12000 13000 14000} test 1 "E1 E2 E3 E4 E5" 1

set gDefineRun(runCount) 0
set gDefineRun(maxRuns) 16
set gDefineRun(runCount) 0
set gDefineRun(isActive) 0
set gDefineRun(currentRun) 0
set gDefineRun(currentTabView) 0
set gDefineRun(standardOptions) \
	{ fileroot directory axis startframe endframe \
	delta }
set gDefineRun(standardEntries) { distanceEntry wedgesize startAngleEntry endAngleEntry}
set gDefineRun(axisChoices) { gonio_phi gonio_omega }

#not all collection modes are supported by DCSS yet.
#Add new functions to modeChoicesSupported as developed

switch $gBeamline(detector) {
	Q4CCD {
		#the following order corresponds to the detectors mode order
		set gDefineRun(modeChoices) \
			{ slow fast slow_bin fast_bin slow_dezing \
				  fast_dezing slow_bin_dezing fast_bin_dezing }
		#the following list is used to display the modes that we want the users to have. The
		# order should not be important.  The list must be a subset of the gDefine(modeChoices) list.
		set gDefineRun(modeChoicesSupported) { slow fast slow_bin fast_bin slow_dezing \
																 fast_dezing slow_bin_dezing fast_bin_dezing }
		set gDefineRun(modeOverheadTime) { 10 8 4 2 20 16 8 4 }
	}
	Q315CCD {
		#the following order corresponds to the detectors mode order
		set gDefineRun(modeChoices) \
			 { {unbinned} unused1 binned unused2 {unbinned dezing} \
					 unused3 {binned dezing} unused4 }
		#the following list is used to display the modes that we want the users to have. The
		# order should not be important.  The list must be a subset of the gDefine(modeChoices) list.
		set gDefineRun(modeChoicesSupported) {  {unbinned} {unbinned dezing} binned {binned dezing} }
		set gDefineRun(modeOverheadTime) { 10 8 4 2 20 16 8 4 }
	}
	MAR345 {		
		#the following order corresponds to the detectors mode order
		set gDefineRun(modeChoices) \
			 { {345mm x 150um}	{300mm x 150um}	{240mm x 150um} \
					 {180mm x 150um} {345mm x 100um} {300mm x 100um} \
					 {240mm x 100um} {180mm x 100um} }
		#the modeSizes variable can be used to make calculations on the selected mode.
		set gDefineRun(modeSizes) {345 300 240 180 345 300 240 180}
		set gDefineRun(modeOverheadTime) { 90 75 60 45 115 95 75 55 }
		#the following list is used to display the modes that we want the users to have. The
		# order should not be important.  The list must be a subset of the gDefine(modeChoices) list.
		set gDefineRun(modeChoicesSupported) \
			 { {345mm x 150um}	{300mm x 150um}	{240mm x 150um} \
					 {180mm x 150um} {345mm x 100um} {300mm x 100um} \
					 {240mm x 100um} {180mm x 100um} }
	}
	MAR165 {		
		#the following order corresponds to the detectors mode order
		set gDefineRun(modeChoices)	{ {normal}	{dezingered} }
		#the following list is used to display the modes that we want the users to have. The
		# order should not be important.  The list must be a subset of the gDefine(modeChoices) list.
		set gDefineRun(modeChoicesSupported)  { {normal}	{dezingered} }
	}
}

set gReswidget(detectorMode) [lindex $gDefineRun(modeChoicesSupported) 0]

set gDefineRun(runStatusStrings) {inactive collecting paused complete}


proc construct_collect_window {} {

	# global variables
	global gWindows
	global gColors
	global gFont
	global gDevice
	global gLabeledFrame
	global gDefineScan
	global gDefineRun
	global gBeamline

	# get frame to construct
	set frame $gWindows(Collect,frame)
	
	# make the run definition frame
	pack [ set gWindows(collect,runs,frame) [ \
		 frame $frame.runs -width 330 -height 580 ]] \
		-side right -anchor n -expand 0 -fill y

	# make a folder frame for holding runs
	pack [ set gWindows(runs,notebook) [ iwidgets::tabnotebook $gWindows(collect,runs,frame).notebook \
		-tabpos e -gap 4 -angle 20 -width 330 -height 800 \
		-raiseselect 1 -bevelamount 4 -tabforeground $gColors(dark) -padx 5 ] ] \
		-side top -anchor n -pady 20


	# create the run control buttons
	pack [set controlFrame [frame $frame.controls \
		-width 100 -height 700 ]] \
		-side right -anchor n -pady 20 -expand 0 -fill both

	#make the diffimage frame
	pack [set gWindows(collect,diffimage,frame) [ frame $frame.diffimage ]] \
		 -side left -anchor n -expand 1 -fill both 

	# create the diffimage object
	Diffimage lastImage $gWindows(collect,diffimage,frame) $gBeamline(diffImageServerHost) $gBeamline(diffImageServerPort) 500 500

	# make the data collection button
	set gWindows(runs,startbutton) [MultipleObjectsButton \#auto $controlFrame.startbutton \
													{clientState master 1 \
														  collectRunsStatus status inactive \
														  collectRunStatus status inactive \
														  collectFrameStatus status inactive \
														  centerLoopStatus status inactive \
														  moveSampleStatus status inactive \
														  optimizeStatus status inactive \
														  device::detector_z status inactive \
														  device::gonio_phi status inactive } \
													-command "run_handle_start_button" \
													-text "Collect"\
													-width 10 -font $gFont(small) ]
	pack $controlFrame.startbutton

	set gWindows(runs,stopbutton) [MultipleObjectsButton \#auto $controlFrame.stopbutton \
												  {clientState master 1 \
														 collectRunsStatus status active \
														 collectRunStatus status active \
														 collectFrameStatus status active } \
												  -command "start_operation pauseDataCollection" \
												  -text "Pause"\
												  -width 10 -font $gFont(small) ]
	pack $controlFrame.stopbutton -pady 4

	pack [set gWindows(runs,abortbutton) \
				 [button $controlFrame.abortbutton -text "Abort" \
						-width 10 -command "do abort soft" -bg $gColors(lightRed)	\
						-activebackground $gColors(lightRed) -font $gFont(small) ]] \
		 -anchor n -pady 2

	#DynamicHelp::register $gWindows(runs,abortbutton) balloon \
	#	 "Stops all motors and \nstops data collection"


#	pack [frame $controlFrame.spacer1] -pady 5
	
	pack [frame $controlFrame.position -relief raised -borderwidth 1] \
		 -side top -anchor w -pady 3 -padx 3  -fill both -expand 1
	pack [label $controlFrame.position.label -text "Current Position" -font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"] -side top -anchor n -pady 3 -padx 20

#		 -font "*-helvetica-bold-r-normal--18-*-*-*-*-*-*-*"] 

	foreach {motor alias} { 
		gonio_phi Phi 
		gonio_omega Omega
		gonio_kappa Kappa
		detector_z Distance
		} {
		pack [frame $controlFrame.position.$motor] -side top -anchor w -pady 3
		pack [label $controlFrame.position.$motor.label -text "$alias:"\
		 	-font $gDefineScan(font) -justify right -width 9 -anchor e] \
			-side left
		pack [label $controlFrame.position.$motor.value -textvariable gDevice($motor,scaledShort) \
		 	-font $gDefineScan(font) -width 7 -justify right -anchor e] \
		 	-side left 
	}
	
	pack [frame $controlFrame.doseMode -relief raised -borderwidth 1] \
		 -side top -anchor w -pady 3 -padx 3 -fill both -expand 1
	pack [label $controlFrame.doseMode.label -text "Dose Mode" \
        -font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"] -side top -anchor n -pady 3 -padx 20	

	#add a check box for dose mode.
	set gDefineRun(doseMode) 0

	pack [set doseModeEnableFrame [frame $controlFrame.doseMode.enableFrame]] -pady 2 -side top -anchor w

	pack [set gDefineRun(runs,doseModeLabel) [\
      label $doseModeEnableFrame.text -text " Enable:" \
	   -font $gDefineScan(font) -foreground black -disabledforeground $gColors(darkgrey) ]] \
      -side left
	
	pack [set gWindows(runs,doseModeButton) [checkbutton $doseModeEnableFrame.button \
	 			-text "" \
	 			-variable gDefineRun(doseMode) \
	 			-command "update_runs_to_server" \
	 			-foreground  $gColors(units) -disabledforeground $gColors(darkgrey) \
				-activeforeground  $gColors(units) -activebackground lightgrey] ] \
		 		-side left
	
	pack [frame $controlFrame.doseMode.beam] -side top -anchor w -pady 3
	pack [label $controlFrame.doseMode.beam.label -text "Dose Factor:"\
				 -font $gDefineScan(font) -justify right -width 12 -anchor e] \
		 -side left
	
	set gDevice(doseStoredCounts,scaled) 1
	set gDevice(doseLastCounts,scaled) 1
	calculateDoseFactor
	pack [label $controlFrame.doseMode.beam.value -textvariable gWindows(runs,doseFactor) \
				 -font $gDefineScan(font) -width 8 -justify left -anchor e] \
		 -side left
	
	trace variable gDevice(doseStoredCounts,scaled) w "calculateDoseFactor"
	trace variable gDevice(doseLastCounts,scaled) w "calculateDoseFactor"

	# make the center loop button
	set gWindows(runs,beamNormalize) [MultipleObjectsButton \#auto $controlFrame.doseMode.beamNormalizeButton \
													  {clientState master 1 \
															 collectRunsStatus status inactive \
															 collectRunStatus status inactive \
															 collectFrameStatus status inactive \
															 normalizeStatus status inactive \
															 optimizeStatus status inactive } \
													  -command "start_operation normalize" \
													  -text "Normalize"\
													  -width 10 ]

	pack $controlFrame.doseMode.beamNormalizeButton


	DynamicHelp::register $gWindows(runs,beamNormalize) balloon \
		 " Uses the current ion chamber reading to set 'Dose Factor' to 1.0."

	# make the run sequence frame
	pack [ set gWindows(collect,runsequence) [ frame $controlFrame.runsequence \
	    -relief raised -borderwidth 1]] \
	    -side top -anchor w -fill both -expand 1

	pack [label $controlFrame.runsequence.labeltext -text "Run Sequence" -font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"] -side top -anchor n -pady 0 -padx 10

	RunSequenceViewer runViewer $controlFrame.runSequence runSequence -_entrySelectCommand set_next_frame \
		 -font "*-courier-bold-r-normal--12-*-*-*-*-*-*-*" -_width 15 \
		 -_collectedFrameColor grey60 -_collectingFrameColor red -_uncollectedFrameColor black
	
	pack $controlFrame.runSequence -fill both -expand true

	# add the new run tab
	run_add_star_button

	# add run zero
	run_add zero
	
	# select run tab
	$gWindows(runs,notebook) select 0

	trace variable gWindows(runs,doseFactor) w "updateExposureTimes"

}


proc run_handle_start_button {} {

	# global variables
	global gDefineRun
	global gWindows
	global env

	# take focus from any edited entry fields and handle changes
	focus .
	update
	
	# set currently selected run as current run
	set gDefineRun(currentRun) [$gWindows(runs,notebook) index select]
	if { $gDefineRun(currentRun) < 1 } {
		set gDefineRun(currentRun) 0
	}
	update_runs_to_server
	update_run_to_server $gDefineRun(currentRun)	

	# if doing snapshot set end frame to next frame
	if { ($gDefineRun(currentRun) == 0)} {
		start_operation collectRun 0 $env(USER) $gDefineRun(reuseDark)
	} else {
		# send the start message to the server
		start_operation collectRuns $gDefineRun(currentRun)
	}
}


proc run_update_widget_states { run } {
	
	# global variables
	global gDefineRun
	global gColors
	global gBeamline

	# set state of standard run parameters
	
	foreach entry { fileroot directory delta } {
		safe_entry_set_state run$entry$run disabled
	}

	if { [info command wedgesize($run)] != ""} {
		detectorMode($run) disable
		collectTimeEntry($run) disable
		energyEntry($run,1) disable
		energyEntry($run,2) disable	
		energyEntry($run,3) disable
		energyEntry($run,4) disable	
		energyEntry($run,5) disable
		wedgesize($run) disable
		distanceEntry($run) disable
		startAngleEntry($run) disable
		endAngleEntry($run) disable
	}
	$gDefineRun($run,inversebutton) configure -state disabled

	# set state of run frame and angle entries
	safe_entry_set_state runframestart$run disabled
	safe_entry_set_state runframeend$run disabled
		
	# disable combo boxes
	foreach box { axis } {
		combo_box_set_state run$box$run disabled
	}
		
	# disable the run buttons
	foreach button { default reset delete Update } {
		$gDefineRun($run,button$button) configure -state disabled
	}
		

	#puts [dcss is_master]
	# enable some things if master
	if { [dcss is_master] } {
		# enable the end run entries

		if { $run == 0 && ($gDefineRun($run,runStatus) == "complete" || \
			$gDefineRun($run,runStatus) == "paused" ) } {
			set gDefineRun($run,runStatus) "inactive"
			}
		
		switch $gDefineRun($run,runStatus) {
	
			inactive {
				# set state of standard run parameters
				foreach entry { fileroot directory delta } {
					safe_entry_set_state run$entry$run normal
				}
			
				# set state of run frame and angle entries
					safe_entry_set_state runframestart$run normal
					safe_entry_set_state runframeend$run normal

			
				# enable combo boxes
				foreach box { axis } {
					combo_box_set_state run$box$run normal
				}
		
				# enable the run buttons
				$gDefineRun($run,buttondefault) configure -state normal
				$gDefineRun($run,buttonUpdate) configure -state normal
				$gDefineRun($run,buttondelete) configure -state normal

				detectorMode($run) enable
				collectTimeEntry($run) enable
				distanceEntry($run) enable
				startAngleEntry($run) enable
				endAngleEntry($run) enable

				if {[energyEntry($run,4) get_value] != ""} {
					energyEntry($run,5) enable	
				}
				if {[energyEntry($run,3) get_value] != ""} {
					energyEntry($run,4) enable	
				}
				if {[energyEntry($run,2) get_value] != ""} {
					energyEntry($run,3) enable
				}
				
				if { $gBeamline(moveableEnergy) } {
					energyEntry($run,1) enable	
					energyEntry($run,2) enable	
				} else {
					energyEntry($run,1) disable
					energyEntry($run,2) disable
				}

				wedgesize($run) enable
				#inverse beam not selectable for omega oscillations
				if { $gDefineRun($run,axis) == "gonio_omega" } {
					$gDefineRun($run,inversebutton) configure -state disabled
					$gDefineRun($run,inversebeamlabel) configure -foreground $gColors(darkgrey)
				} else {
					$gDefineRun($run,inversebutton) configure -state normal
					$gDefineRun($run,inversebeamlabel) configure -foreground black
				}
			}

			complete {		
				$gDefineRun($run,buttondelete) configure -state normal
				$gDefineRun($run,buttonreset) configure -state normal
			}
					
			paused {
				$gDefineRun($run,buttonreset) configure -state normal
			}
		}
	}	
	
	if { $run == 0 } {
		$gDefineRun($run,buttonreset) configure -state disabled
		$gDefineRun($run,buttondelete) configure -state disabled
	} else {
		# show run start or next frame as appropriate
		run_show_start_frame $run
	}
	
	#This next line needs to be here, but it ends up calling
	# the update_run_sequence 3 times per change in the run.
	update_run_sequence $run
}

 
proc run_update_control_buttons {} {

	# global variables
	global gDefineRun
	global gWindows
	global gMode

	if { ! [dcss is_master] } {
		#$gWindows(runs,startbutton) configure -state disabled
		#$gWindows(runs,stopbutton) configure -state disabled
		$gWindows(runs,doseModeButton) configure -state disabled
		#safe_entry_set_state currentRun disabled
		return		
	}

	#$gWindows(runs,stopbutton) configure -state normal

	if { [collectRunsStatus cget -status] == "active" } {
		$gWindows(runs,doseModeButton) configure -state disabled
		#safe_entry_set_state currentRun disabled
		return
	} else {
		$gWindows(runs,doseModeButton) configure -state normal
		#safe_entry_set_state currentRun normal
		return
	}
}
 

proc run_handle_become_master {} {

	# global variables
	global gDefineRun
	global gWindows
	
	# enable the star tab
	$gWindows(runs,notebook) pageconfigure end -state normal
	
	# enable entry fields for each run
	for { set run 0 } { $run <= $gDefineRun(runCount) } { incr run } {
		run_update_widget_states $run
	}

	# enable the run control buttons as appropriate
	run_update_control_buttons
}


proc run_handle_become_slave {} {

	# global variables
	global gSafeEntry
	global gDefineRun
	global gWindows

	# disable the new tab tab if it is visible
	if { $gDefineRun(runCount) < $gDefineRun(maxRuns) } {
		$gWindows(runs,notebook) pageconfigure end -state disabled
	}
	
	# disable entry fields for each run
	for { set run 0 } { $run <= $gDefineRun(runCount) } { incr run } {
		run_update_widget_states $run
	}

	# enable the run control buttons as appropriate
	run_update_control_buttons
}




proc run_add { {init none} } {
	
	# global variables
	global gWindows
	global gColors
	global gFont
	global gDevice
	global gLabeledFrame
	global gDefineScan
	global gDefineRun
	global addingRun
	global gBeamline

	if {$init == "zero"} {
		set run 0
		set init none
	} else {
		incr gDefineRun(runCount)
		set run $gDefineRun(runCount)
	}
	
   set gDefineRun($run,label) 0
	set gDefineRun($run,inversebeam) 0
	set gDefineRun($run,multiwave) 0 

	run_get_next_label $run

	# insert the new run tab
	$gWindows(runs,notebook) insert $run -label $gDefineRun($run,label)

	$gWindows(runs,notebook) pageconfigure $run \
		 -command "update_current_tab_view $run;update_run_sequence $run"

	$gWindows(runs,notebook) select $run

	# get the name of the associated child frame
	set gWindows(run_$run,frame) [$gWindows(runs,notebook) childsite $run]

	# fill each page of the run notebook
	set frame $gWindows(run_$run,frame)

	# set run status
	set gDefineRun($run,runStatus) "inactive"

	# make the run label
	pack [ frame $frame.header ] -pady 6
	pack [ label $frame.header.label -text "Run " ] -side left
	pack [ label $frame.header.labelVar -textvariable gDefineRun($run,label) ] -side left
	pack [ label $frame.header.label2 -text " ( " ] -side left
	pack [ label $frame.header.status \
		-textvariable gDefineRun($run,runStatus) ] -side left -padx 0
	pack [ label $frame.header.label3 -text ")" ] -side left

	if { $init == "none" && ! [info exists gDefineRun($run,fileroot)] } {
		set init default
	}

	# set initial values of fields according to mode
	switch $init {
		default 	{ run_set_to_defaults $run
			set gDefineRun(0,startframe) 001	
		}
		previous	{ run_set_to_previous $run }
	}

	# make a frame of control buttons
	pack [ frame $frame.buttons ] -pady 10

	pack [ set gDefineRun($run,buttondefault) \
		[button $frame.buttons.default -text "Default" \
		-font $gFont(small) -width 5 -pady 0 -state disabled\
			 -command "run_handle_default_button $run" ]] -side left -padx 3
	pack [ set gDefineRun($run,buttonUpdate) \
		[button $frame.buttons.update -text "Update" \
		-font $gFont(small) -width 5 -pady 0 -state disabled\
			 -command "run_handle_update_button $run" ]] -side left -padx 3
	pack [ set gDefineRun($run,buttondelete) \
		[button $frame.buttons.delete -text "Delete" \
			 -font $gFont(small) -width 5 -pady 0 -state disabled \
			 -command "run_delete $run"]] -side left -padx 3
	pack [ set gDefineRun($run,buttonreset) \
		[button $frame.buttons.reset -text "Reset" \
		-font $gFont(small) -width 5 -pady 0 -state disabled \
			 -command "run_reset $run; update_run_to_server $run"]] -side left -padx 3
	
	# make the filename root entry
	pack [ safeEntry $frame.fileroot -name runfileroot$run	\
		-variable gDefineRun($run,fileroot) -width 19 	\
		-font $gDefineScan(font) -justification center\
		-label "Prefix: " -labelwidth 12 -labelanchor e \
		-unitsthickness 1 -state disabled \
		-units "" -onsubmit "update_run_to_server $run"] \
		-pady 4 -padx 5 -anchor w

	# make the data directory entry
	pack [ safeEntry $frame.directory -name rundirectory$run 	\
		-variable gDefineRun($run,directory) -width 19 	\
		-font $gDefineScan(font) -justification center \
		-label "Directory: " -labelwidth 12 -labelanchor e \
		-unitsthickness 1 -state disabled \
		-units "" -onsubmit "update_run_to_server $run"] \
		-pady 4 -padx 5 -anchor w

	# make the detector mode entry
	global gBeamline

	if { $gBeamline(detector) == "MAR345" } {

		SafeEntry detectorMode($run) $frame.mode$run \
			 -onsubmit "update_run_to_server $run" \
			 -menuchoices $gDefineRun(modeChoicesSupported) \
			 -font $gDefineScan(font) -name runmode$run \
			 -disabledbackground lightgrey \
			 -prompt "Mode: " -promptwidth 12 -entrywidth 15 -justification center \
			 -anchor c -useMenu 1 -useArrow 1 -useEntry 0 \
			 -reference gReswidget(detectorMode) -shadow 0 -type string 
	} else  {
		SafeEntry detectorMode($run) $frame.mode$run \
			 -onsubmit "update_run_to_server $run" \
			 -menuchoices $gDefineRun(modeChoicesSupported) \
			 -font $gDefineScan(font) -name runmode$run \
			 -disabledbackground lightgrey \
			 -prompt "Mode: " -promptwidth 12 -entrywidth 15 -justification center \
			 -anchor c -useMenu 1 -useArrow 1 -useEntry 0 \
			 -type string
	}

	detectorMode($run) disable
	pack $frame.mode$run -pady 4 -padx 3 -anchor w

	# make the detector mode entry
	#pack [comboBox $frame.mode$run -choices $gDefineRun(modeChoicesSupported) \
	\#	-font $gDefineScan(font) -name runmode$run \
	\#	-variable gDefineRun($run,mode) -menufont $gDefineScan(font) \
	\#	-width 15 -cwidth 15 -prompt "Mode: " -promptwidth 12 \
	\#	-command "update_run_to_server $run" \
	\#	-unitsthickness 1 -state disabled \
	\# -reference gReswidget(detectorMode) -shadow 0 -type string \
	\#	-onsubmit "update_run_to_server $run"] \
	\#	-pady 4 -padx 3 -anchor w	

	pack [ frame $frame.spacer1 ] -pady 5

	# make the energy entry
		
	# make the distance entry
	pack [ frame $frame.distance ] -padx 4 -pady 4 -anchor w

	SafeEntry distanceEntry($run) $frame.distance.entry -name rundistance$run	\
		-prompt "Distance: " -promptwidth 12 -labelanchor e \
		-reference gDevice(detector_z,scaled) -shadow 0 \
		-width 10 -units " mm"\
		-font $gDefineScan(font) -type positive_float \
		-unitsthickness 1 -unitsforeground $gColors(units) \
		-onsubmit "update_run_to_server $run" \
		-disabledbackground lightgrey  \

	distanceEntry($run) disable
	distanceEntry($run) pack_this {-side left}

	# make oscillation axis combo box
	pack [ comboBox $frame.axis$run -choices $gDefineRun(axisChoices) \
		-font $gDefineScan(font) -name runaxis$run\
		-variable gDefineRun($run,axis) -menufont $gDefineScan(font) \
		-width 9 -cwidth 8 -prompt "Axis: " -promptwidth 12 \
		-command "run_update_angle $run" \
      -state disabled \
		-onsubmit "update_run_to_server $run"] \
		-pady 4 -padx 4 -anchor w

	# make the width entry
	pack [ safeEntry $frame.delta -name rundelta$run	\
		-label "Delta: " -labelwidth 12 -labelanchor e \
		-variable gDefineRun($run,delta) -width 10 	\
		-font $gDefineScan(font) -type positive_float -units " deg" \
		-unitsthickness 1 -unitsforeground $gColors(units) -state disabled \
		-onsubmit "run_change_frame_angle $run end; update_run_to_server $run"] \
		-padx 5 -pady 4 -anchor w



	pack [set timeEntryFrame [frame $frame.time]] -pady 2 -side top -anchor w


		SafeEntry collectTimeEntry($run) $timeEntryFrame.time \
			-prompt "Time:" -promptwidth 7 -units "s * " \
		 -shadow 0 \
		 -value 1  -onsubmit "update_run_to_server $run" \
		 -onchange "calculate_exposure_time $run" \
		 -type positive_float \
		 -useMenu 0 -useArrow 1 -useEntry 1 -justification right \
		 -entrywidth 6 -menucolbreak 5 -disabledbackground lightgrey \
		 -font $gDefineScan(font) -unitsforeground $gColors(units)  -labelwidth 12

		pack $timeEntryFrame.time -anchor w -pady 2 -side left



# make the time entry
#	pack [ safeEntry $timeEntryFrame.time -name runtime$run \ 
#		-label "Time:" -labelwidth 7 -labelanchor e \ 
#		-variable gDefineRun($run,time) -width 6 	\ 
#		-font $gDefineScan(font) -type positive_float -units " / " \ 
#		-unitsthickness 1 -unitsforeground $gColors(units) \ 
#				  -onsubmit "update_run_to_server $run;calculate_exposure_time $run" -onchange "calculate_exposure_time $run" -state disabled ] \ 
#		-padx 5 -pady 6 -anchor w -side left


	pack [label $timeEntryFrame.doseFactor -textvariable gWindows(runs,doseFactor) \
				 -font $gDefineScan(font) -width 5 -justify left -anchor e -foreground $gColors(units)] \
		 -side left

	pack [label $timeEntryFrame.equation -text "="  -font $gDefineScan(font) -width 3 -justify left -anchor e] -side left

	calculate_exposure_time $run
	pack [label $timeEntryFrame.actualTime -textvariable gDefineRun($run,exposureTime) \
				 -font $gDefineScan(font) -width 7 -justify left -anchor e -foreground $gColors(units)] \
		 -side left

	pack [ frame $frame.spacer2 ] -pady 5

	# make the exposures frame
	pack [ frame $frame.exp ]
	pack [ frame $frame.exp.heading ] -anchor w
	pack [ label $frame.exp.heading.frame \
		-text "                 Frame" -fg $gColors(units)\
		-font $gDefineScan(font) ] -side left -anchor w
	pack [ label $frame.exp.heading.axis -width 10 \
		-textvariable gDefineRun($run,axis) \
		-font $gDefineScan(font) -fg $gColors(units)] -side left -anchor w

	set gWindows($run,startframe) [ frame $frame.exp.start ]


	if { $run == 0 } {
		pack [ safeEntry $frame.exp.start.framenum -name runframestart$run	\
					 -label "Start: " -labelwidth 11 -labelanchor e \
					 -variable gDefineRun($run,startframe) -width 6 	\
					 -font $gDefineScan(font) -type positive_int \
					 -unitsthickness 1 -state disabled -foreground grey\
					 -onsubmit "run_change_frame_num $run start;update_run_to_server $run"] \
			-side left -padx 5

		set angleList [list [expr $gDevice(gonio_phi,scaledShort) + 90] [expr $gDevice(gonio_phi,scaledShort) - 90]]
		SafeEntry startAngleEntry($run) $frame.exp.start.angle \
			-shadow 0 \
			-reference gDevice(gonio_phi,scaledShort) \
			-entrywidth 6 \
			-font $gDefineScan(font) -type float \
			-onsubmit "run_change_frame_angle $run start;update_run_to_server $run" \
			-disabledbackground lightgrey \
			-units " deg" \
			-unitswidth 4 -unitsforeground $gColors(units) \
			-useMenu 1 -menuchoices $angleList -useArrow 1
	} else {
		pack [ safeEntry $frame.exp.start.framenum -name runframestart$run	\
					 -label "Start: " -labelwidth 7 -labelanchor e \
					 -variable gDefineRun($run,startframe) -width 6 	\
					 -font $gDefineScan(font) -type positive_int \
					 -unitsthickness 1 -state disabled -foreground grey\
					 -onsubmit "run_change_frame_num $run start;update_run_to_server $run"] \
			-side left -padx 5
		
		SafeEntry startAngleEntry($run) $frame.exp.start.angle \
			-shadow 0 \
			-reference gDevice(gonio_phi,scaledShort) \
			-entrywidth 6 \
			-font $gDefineScan(font) -type float \
			-onsubmit "run_change_frame_angle $run start;update_run_to_server $run" \
			-disabledbackground lightgrey \
			-units " deg" \
			-unitswidth 4 -unitsforeground $gColors(units)
	}

	startAngleEntry($run) disable
	startAngleEntry($run) pack_this {-side left}

	set gWindows($run,endframe) [ frame $frame.exp.end ]
	pack [ safeEntry $frame.exp.end.framenum  -name runframeend$run	\
				 -label "End: " -labelwidth 7 -labelanchor e \
				 -variable gDefineRun($run,endframe) -width 6 	\
				 -font $gDefineScan(font) -type positive_int \
				 -unitsthickness 1 -state disabled -foreground grey\
				 -onsubmit "run_change_frame_num $run end;update_run_to_server $run"] \
		-side left -padx 5
	
	SafeEntry endAngleEntry($run) $frame.exp.end.angle \
		-shadow 0 \
		-reference gDevice(gonio_phi,scaledShort) \
		-entrywidth 6 \
		-font $gDefineScan(font) -type float \
		-onsubmit "run_change_frame_angle $run end;update_run_to_server $run" \
		-disabledbackground lightgrey \
		-units " deg" \
		-unitswidth 4 -unitsforeground $gColors(units) 

	endAngleEntry($run) disable
	endAngleEntry($run) pack_this {-side left}

	pack $gWindows($run,startframe) -pady 6
	pack $gWindows($run,endframe) -pady 6


	pack [frame $frame.inverseframe] -pady 2 -side top -anchor w


	pack [set gDefineRun($run,inversebeamlabel) [\
		  label $frame.inverseframe.text -text "Inverse Beam:  " \
		  -font $gDefineScan(font) -foreground black]] \
		 -side left
	
	pack [set gDefineRun($run,inversebutton) [checkbutton $frame.inverseframe.button \
			-text "(phi axis only)" \
			-variable gDefineRun($run,inversebeam) \
			-command "update_run_to_server $run" \
			-foreground  $gColors(units) -disabledforeground $gColors(darkgrey) \
			-activeforeground  $gColors(units) -activebackground lightgrey] ] \
		-side left 



	#install
	set wedgeList [ list 30 45 60 90 180]

	SafeEntry wedgesize($run) $frame.wedgesize -prompt "Wedge:" -units "deg" \
		-shadow 0 \
		-value 90 -onsubmit "update_run_to_server $run" \
		-type positive_float \
		-useMenu 1 -menuchoices $wedgeList -useArrow 1 -useEntry 1 -justification right \
		-promptwidth 12 -entrywidth 9 -menucolbreak 9 -disabledbackground lightgrey \
		-font $gDefineScan(font) -unitsforeground $gColors(units)  -labelwidth 12
	
	pack $frame.wedgesize -anchor w -side top
	
	set energyPrompt "Energy:"

	set energyValue  [format "%.2f" $gDevice(energy,scaled)]
	for { set energy_cnt 1 } { $energy_cnt < 6 } {incr energy_cnt} {

		SafeEntry energyEntry($run,$energy_cnt) $frame.energy$energy_cnt \
			-prompt $energyPrompt -promptwidth 12 -units "eV" \
			-reference gDevice(energy,scaledDisplay) -shadow 0 \
			-value $energyValue  -onsubmit "update_energy_list $run;update_run_to_server $run" \
			-type positive_float \
			-useMenu 0 -useArrow 1 -useEntry 1 -justification right \
			-entrywidth 9 -menucolbreak 5 -disabledbackground lightgrey \
			-font $gDefineScan(font) -unitsforeground $gColors(units)  -labelwidth 12

		pack $frame.energy$energy_cnt -anchor w -pady 2

		set energyPrompt " "

		set energyValue ""
	}

	# delete star tab if no room
	if { $gDefineRun(runCount) == $gDefineRun(maxRuns) } {
		$gWindows(runs,notebook) delete [expr $gDefineRun(maxRuns) + 1]
	}

	# unpack some widgets if run 0
	if { $run == 0 } {
		pack forget $frame.listbox
		pack forget $frame.inverseWedge
		pack forget $gWindows($run,endframe)
		$gDefineRun($run,buttondefault) configure -state normal
		$gDefineRun($run,buttonUpdate) configure -state normal
		$gDefineRun($run,buttonreset) configure -state disabled
		$gDefineRun($run,buttondelete) configure -state disabled

		pack forget $gDefineRun(0,inversebeamlabel);
		pack forget $gDefineRun(0,inversebutton)

		pack forget $frame.energy2
		pack forget $frame.energy3
		pack forget $frame.energy4
		pack forget $frame.energy5
		pack forget $frame.wedgesize

		set gDefineRun(reuseDark) 0
		pack [frame $frame.forcedark] -pady 12 -side top

		if { $gBeamline(detector) == "Q4CCD" || $gBeamline(detector) == "Q315CCD" || $gBeamline(detector) == "MAR165" } {
			pack [set gDefineRun(reuseDarkLabel) \
						[label $frame.forcedark.text \
							 -text "Use last dark:  " \
							 -font $gDefineScan(font) \
							 -foreground black]] \
				-side left
			
			pack [set gDefineRun(reuseDarkButton) \
						[checkbutton $frame.forcedark.button -text "" \
							 -variable gDefineRun(reuseDark) \
							 -foreground  $gColors(units) \
							 -disabledforeground $gColors(darkgrey) \
							 -activeforeground $gColors(units) \
							 -activebackground lightgrey] ] \
				-side left
		}
	}

	#handle initial values for new objects
	switch $init {
		default 	{
			run_set_entries_to_defaults $run
		}
		previous	{
			run_set_entries_to_previous $run
		}
	}

	# update the run window
	run_update_widget_states $run
}

proc run_show_start_frame { run } {

	# global variables
	global gWindows
	
	pack $gWindows($run,startframe) -pady 6 -before $gWindows($run,endframe)
}


proc runs_change_current_run {} {
	
	# global variables
	global gDefineRun

	if { ! [is_positive_int $gDefineRun(currentRun)] ||
		$gDefineRun(currentRun) > $gDefineRun(runCount) ||
		$gDefineRun(currentRun) < 1 } {
		set gDefineRun(currentRun) 0
	}
	
	update_runs_to_server
	update_active_run_tab
}

proc update_active_run_tab {} {

	# global variables
	global gDefineRun
	global gWindows
	
#	set run $gDefineRun(currentRun)
#	$gWindows(runs,notebook) select $run
#	$gWindows(runs,notebook) pageconfigure $run -foreground red 
}


proc run_change_frame_num { run line {fromserver 0} } {
	
	# global variables
	global gDefineRun

	if { ! [is_positive_int $gDefineRun($run,${line}frame)] } {
		run_restore_value $run ${line}frame
	}

	if { $line == "start" } {
		if { ! $fromserver } {
			set gDefineRun($run,nextframe) 0;

			#frame definitions start from 001
			if {$gDefineRun($run,startframe) < 1} {set gDefineRun($run,startframe) 1}
			
			if { $run == 0 } {
				set gDefineRun($run,endframe) $gDefineRun($run,startframe)
			}
		}
		run_change_frame_num $run end
	} else {
		#strip off the zeroes in front
		set frame [string trimleft $gDefineRun($run,${line}frame) 0]
#		log_note "run_change_frame_num $run"
		set firstframe [string trimleft $gDefineRun($run,startframe) 0]
		if { $frame < $firstframe } {
			set frame $firstframe
			set gDefineRun($run,${line}frame) $firstframe
		}
		
		if { $line == "end" } {
			endAngleEntry($run) set_value \
				 [expr ( $frame - $firstframe + 1) * $gDefineRun($run,delta) + \
						[startAngleEntry($run) get_value] ] 
		} else {
			startAngleEntry($run) set_value \
				 [expr ( $frame - $firstframe )  * $gDefineRun($run,delta) + \
						[startAngleEntry($run) get_value] ]
		}
	}
}


proc run_change_frame_angle { run line {fromserver 0} } {
	# global variables
	global gDefineRun
	global gDevice

	# reset value if garbage value entered
	#if { ! [is_float $gDefineRun($run,${line}angle)] } {
	#	run_restore_value $run ${line}angle
	#}
	
	if { ! [is_float $gDefineRun($run,delta)] } {
		run_restore_value $run delta
	}

	if { [startAngleEntry($run) get_value] == "" } {
		if { $gDefineRun($run,axis) == "gonio_phi"} {
			startAngleEntry($run) set_value $gDevice(gonio_phi,scaledShort)
		} else {
			startAngleEntry($run) set_value $gDevice(gonio_omega,scaledShort)
		}
	}

	if { [endAngleEntry($run) get_value] == "" } {
		endAngleEntry($run) set_value [expr [startAngleEntry($run) get_value] + $gDefineRun($run,delta) ]
	}


	#strip off extra digits from entry before doing any calculations
	startAngleEntry($run) set_value [format "%.2f" [startAngleEntry($run) get_value]]
	set gDefineRun($run,delta) [format "%.2f" $gDefineRun($run,delta)]
	
	if { $gDefineRun($run,delta) == 0 } {
		run_restore_value $run delta
	}

	if { $line == "start" } {
		if { ! $fromserver } {
			set gDefineRun($run,nextframe) 0
		}
		run_change_frame_num $run end
	} else {
		if { [endAngleEntry($run) get_value] < [startAngleEntry($run) get_value] } {
			endAngleEntry($run) set_value [startAngleEntry($run) get_value]
		}	
		set gDefineRun($run,endframe) \
			[ expr int(([endAngleEntry($run) get_value] - [startAngleEntry($run) get_value]) / \
							  $gDefineRun($run,delta) -0.01 + [string trimleft $gDefineRun($run,startframe) 0] ) ]
		set frame [string trimleft $gDefineRun($run,endframe) 0]
		set firstframe [string trimleft $gDefineRun($run,startframe) 0]
		endAngleEntry($run) set_value [expr ( $frame - $firstframe + 1) * $gDefineRun($run,delta) + [startAngleEntry($run) get_value] ]
	}
	endAngleEntry($run) set_value [format "%.2f" [endAngleEntry($run) get_value]]


	if { [info command wedgesize($run)] != ""} {
		if { $gDefineRun($run,delta) > [wedgesize($run) get_value] } {
			wedgesize($run) set_value $gDefineRun($run,delta)
		}
		wedgesize($run) set_value [expr [expr int([wedgesize($run) get_value]/$gDefineRun($run,delta)) * $gDefineRun($run,delta) ] ]
	}

	#add +90 & -90 for angle selection for run 0
	if { $run == 0} {
		if { $gDefineRun(0,axis) == "gonio_phi"} {
			set angle_plus90 [expr [startAngleEntry(0) get_value] + 90 +360 ]
			set angle_plus90 [expr $angle_plus90 - 360.0 * ( int($angle_plus90 / 360))]
			set angle_minus90 [expr [startAngleEntry(0) get_value] - 90 +360 ]
			set angle_minus90 [expr $angle_minus90 - 360.0 * ( int($angle_minus90 / 360))]
			set angleList [list $angle_minus90 $angle_plus90 ]
		} else {
			set angle_plus90 [expr [startAngleEntry(0) get_value] + 90 ]
			set angle_minus90 [expr [startAngleEntry(0) get_value] - 90 ]
			if { $angle_plus90 <= $gDevice(gonio_omega,scaledUpperLimit) && $angle_plus90 >= $gDevice(gonio_omega,scaledLowerLimit) } {
				set angleList [list $angle_plus90]
			} elseif { $angle_minus90 <= $gDevice(gonio_omega,scaledUpperLimit) && $angle_minus90 >= $gDevice(gonio_omega,scaledLowerLimit) } {
				set angleList [list $angle_minus90]
			} else {
				set angleList [startAngleEntry(0) get_value]
			}
		}
		startAngleEntry(0) set_menu_choices $angleList
	}
}


proc update_runs_to_server { args } {

	# global variables
	global gDefineRun
	
	# do nothing if not master
	if { ! [dcss is_master] } return

	#log_note  "gtos_configure_runs runs $gDefineRun(runCount) $gDefineRun(currentRun)"
	dcss sendMessage "gtos_configure_runs runs $gDefineRun(runCount) $gDefineRun(currentRun) $gDefineRun(doseMode)"
}
	


proc update_run_to_server { run args } {

	# global variables
	global gDefineRun
	global gDevice

	# do nothing if not master
	if { ! [dcss is_master] } return

	if { $run == "end" } {
		set run $gDefineRun(runCount)
	}

	if { ! [is_word $gDefineRun($run,fileroot)] } {
		run_restore_value $run fileroot
	}

	if { ! [is_word $gDefineRun($run,directory)] } {
		run_restore_value $run directory
	}

#	if { ! [is_float $gDefineRun($run,startangle)] } {
#		run_restore_value $run startangle
#	}

#	if { ! [is_float $gDefineRun($run,nextangle)] } {
#		run_restore_value $run nextangle
#	}
	
#	if { ! [is_float $gDefineRun($run,endangle)] } {
#		run_restore_value $run endangle
#	}

	if { ! [is_positive_int [string trimleft $gDefineRun($run,startframe) 0] ] } {
		run_restore_value $run startframe
	}

	if { ! [is_positive_int $gDefineRun($run,nextframe)] } {
		run_restore_value $run nextframe
	}

	#if { ! [is_positive_int $gDefineRun($run,endframe)] } {
	#	log_error  $gDefineRun($run,nextframe)
	#	run_restore_value $run endframe
	#}

	if { ! [is_positive_float $gDefineRun($run,delta)] } {
		run_restore_value $run delta
	}

	#pull in current energy if it is null
	if { [energyEntry($run,1) get_value] == "" || [energyEntry($run,1) get_value] == 0.0 } {
		energyEntry($run,1) set_value [format "%.2f" $gDevice(energy,scaled)]
	}

	set energyList [list [energyEntry($run,1) get_value] ]


	set numEnergy 1
	#fill in zeroes where empty energies are
	for {set cnt 2} {$cnt <= 5} {incr cnt} {
		if { [energyEntry($run,$cnt) get_value] == ""} {
			lappend energyList "0"
		} else {
			set numEnergy $cnt
			lappend energyList [energyEntry($run,$cnt) get_value]
		}
	}


	#Do some final sanity checks before we send off the definition to the server
	if {[wedgesize($run) get_value] == "" } {
		wedgesize($run) set_value 180.0
	}
	
	if {[distanceEntry($run) get_value] == "" } {
		distanceEntry($run) set_value [format "%.3f" $gDevice(detector_z,scaled)]
	}
	
	if {[collectTimeEntry($run) get_value] == "" || [collectTimeEntry($run) get_value]< 0 } {
		collectTimeEntry($run) set_value [format "%.3f" 1]
	}
	
	if { $gDefineRun($run,delta) > 179.99 } {
		set gDefineRun($run,delta) 179.99
	}

	if { $gDefineRun($run,delta) == 0.0 } {
		set gDefineRun($run,delta) 0.01
	}

	#send the new run definition
	dcss sendMessage "gtos_configure_run run$run $gDefineRun($run,runStatus) \
		 $gDefineRun($run,nextframe) $gDefineRun($run,label) \
		 $gDefineRun($run,fileroot) $gDefineRun($run,directory) [trim $gDefineRun($run,startframe)]\
		 $gDefineRun($run,axis) \
		 [startAngleEntry($run) get_value] [endAngleEntry($run) get_value] \
		 $gDefineRun($run,delta) [wedgesize($run) get_value] \
		 [collectTimeEntry($run) get_value] \
		 [distanceEntry($run) get_value] \
		 $numEnergy $energyList \
		 [lsearch $gDefineRun(modeChoices) [detectorMode($run) get_value] ] \
		 $gDefineRun($run,inversebeam)"

}


proc run_delete { run } {

	# global variables
	global gDevice
	global gDefineRun
	global gWindows
	
	#following is a temporary (I hope) patch to prevent users from deleting a
	#run that preceeds a currently active run.  Currently DCSS really
	#gets confused if this is allowed to happen.
	if { [collectRunsStatus cget -status] == "active"  } {
		log_error "Stop data collection before deleting runs."
		return
	}

	# do nothing if only one run defined
	if { $gDefineRun(runCount) < 1 } return

	$gDefineRun($run,buttondelete) configure -state disabled

	# replace this tab's label with the next tab's label
	$gWindows(runs,notebook) pageconfigure $run -label " "

	if { $run >= [expr $gDefineRun(runCount) -0] } {
		$gWindows(runs,notebook) select [expr $run -1]
	} else {
		$gWindows(runs,notebook) select $run
	}

	set runcnt $run

	while { $runcnt < $gDefineRun(runCount) } {
		run_set_to_next $runcnt
		incr runcnt
		}

	#update the runs starting furthest away from current run.
	while { $runcnt >= $run } {
		update_run_to_server $runcnt
		incr runcnt -1
		}

	set run $gDefineRun(runCount)
	delete object detectorMode($run)
	delete object collectTimeEntry($run)
	delete object distanceEntry($run)
	delete object wedgesize($run)
	delete object energyEntry($run,1)
	delete object energyEntry($run,2)
	delete object energyEntry($run,3)
	delete object energyEntry($run,4)
	delete object energyEntry($run,5)
	delete object startAngleEntry($run)
	delete object endAngleEntry($run)
	$gWindows(runs,notebook) delete $gDefineRun(runCount)

	incr gDefineRun(runCount) -1

	if { $gDefineRun(runCount) == [expr $gDefineRun(maxRuns) - 1] } {
		run_add_star_button

	update
	}

	update_runs_to_server

	return

}


proc run_reset { run } {

	# global variables
	global gDevice
	global gDefineRun
	global gWindows

	# do nothing if not master
	if { ! [dcss is_master] } return

	if { $run == "end" } {
		set run $gDefineRun(runCount)
	}

	# set run status to inactive
	set gDefineRun($run,runStatus) "inactive"

	# set next frame number to 1
	set gDefineRun($run,nextframe) 0;
	#run_change_frame_num $run next
	
	# send reset message to server
	#update_run_to_server $run
	start_operation detector_reset_run $run
}



proc run_add_star_button {} {

	# global variables
	global gWindows
	global gDefineRun

	$gWindows(runs,notebook) add -label " * " \
		-command "run_handle_star_button"

	#disable the star button if not master
	if { ! [dcss is_master] } {
		$gWindows(runs,notebook) pageconfigure end -state disabled
	}

}

proc run_handle_star_button {} {

	global gWindows
	global gDefineRun
	
	if { [dcss is_master] } {
		
		#prevent users from adding multiple runs too quickly
		$gWindows(runs,notebook) pageconfigure [expr $gDefineRun(runCount) + 1] -state disabled
		
		run_add previous
#		update_run_to_server end
#		run_reset end
#		update_runs_to_server
		run_reset end
		update_runs_to_server
		update_run_to_server end
	}


}


proc run_set_to_defaults { run } {
	
	# global variables
	global gDevice
	global gDefineRun
	global env
	
	set gDefineRun($run,fileroot) "test"
	set gDefineRun($run,directory) "/data/$env(USER)"
	set gDefineRun($run,axis) "gonio_phi"
   set gDefineRun($run,axisLastChoice) "gonio_phi"

	set gDefineRun($run,nextframe) 0
#	set gDefineRun($run,startangle) [format "%.1f" $gDevice(gonio_phi,scaled)]
#	set gDefineRun($run,nextangle) $gDefineRun($run,startangle)
	set gDefineRun($run,startframe) 001	
	set gDefineRun($run,endframe) 001
#	set gDefineRun($run,endangle) [format "%.1f" [expr $gDefineRun($run,startangle) + 1]]
	set gDefineRun($run,delta) 1.000
#	set gDefineRun($run,time) 1
	#set gDefineRun($run,energy) [format "%.2f" $gDevice(energy,scaled)]
	#set gDefineRun($run,mode) [lindex $gDefineRun(modeChoices) 0]
	#detectorMode($run) set_value  [lindex $gDefineRun(modeChoices) 0]
}


proc run_set_entries_to_defaults { run } {
	global gDevice
	global gDefineRun
	global gBeamline

	if { $gBeamline(detector) == "Q315CCD" } {
		#binned as default for Q315CCD
		detectorMode($run) set_value  [lindex $gDefineRun(modeChoices) 2]
	} else {
		#slow as default for Q4 & 345mm x 150um for MAR345
		detectorMode($run) set_value  [lindex $gDefineRun(modeChoices) 0]
	}

	distanceEntry($run) set_value [format "%.3f" $gDevice(detector_z,scaled)]
	energyEntry($run,1) set_value [format "%.2f" $gDevice(energy,scaled)]
	energyEntry($run,2) set_value  ""
	energyEntry($run,3) set_value  ""
	energyEntry($run,4) set_value  ""
	energyEntry($run,5) set_value  ""

	update_energy_list $run

	wedgesize($run) set_value 180.0
	startAngleEntry($run) set_value [format "%.2f" $gDevice(gonio_phi,scaled)]
	endAngleEntry($run) set_value [expr [format "%.2f" $gDevice(gonio_phi,scaled)] +1]
}


proc run_set_to_previous { run } {
	
	# global variables
	global gDevice
	global gDefineRun
	
	# do nothing if no previous tab
	if { $run < 1 } return
	
	# get index of previous tab
	set prev [expr $run - 1]
	
	# set each field to value in previous tab
	foreach field $gDefineRun(standardOptions) {
		set gDefineRun($run,$field) $gDefineRun($prev,$field)
	}

	set gDefineRun($run,inversebeam) $gDefineRun($prev,inversebeam)

   set gDefineRun($run,axisLastChoice) $gDefineRun($prev,axisLastChoice)

	# but reset the next frame number
	set gDefineRun($run,nextframe) 0;
	#run_change_frame_num $run next
}

proc run_set_entries_to_previous {run} {
	# do nothing if no previous tab
	if { $run < 1 } return	
	# get index of previous tab
	set prev [expr $run - 1]

	collectTimeEntry($run) set_value [collectTimeEntry($prev) get_value]
	wedgesize($run) set_value [wedgesize($prev) get_value]
	energyEntry($run,1) set_value [energyEntry($prev,1) get_value]
	energyEntry($run,2) set_value [energyEntry($prev,2) get_value]
	energyEntry($run,3) set_value [energyEntry($prev,3) get_value]
	energyEntry($run,4) set_value [energyEntry($prev,4) get_value]
	energyEntry($run,5) set_value [energyEntry($prev,5) get_value]
	distanceEntry($run) set_value [distanceEntry($prev) get_value]
	startAngleEntry($run) set_value [startAngleEntry($prev) get_value]
	endAngleEntry($run) set_value [endAngleEntry($prev) get_value]
	detectorMode($run) set_value [detectorMode($prev) get_value]
}



proc run_set_to_next { run } {
	
	# global variables
	global gDevice
	global gDefineRun
	global gWindows	

	set next [expr $run + 1]
	
	# set each field to value in next tab
	foreach field $gDefineRun(standardOptions) {
		set gDefineRun($run,$field) $gDefineRun($next,$field)
	}

	set gDefineRun($run,nextframe) $gDefineRun($next,nextframe) 

	set gDefineRun($run,runStatus) $gDefineRun($next,runStatus)
	set gDefineRun($run,label) $gDefineRun($next,label)

	set gDefineRun($run,inversebeam) $gDefineRun($next,inversebeam)
	set gDefineRun($run,axisLastChoice) $gDefineRun($next,axisLastChoice)

	collectTimeEntry($run) set_value [collectTimeEntry($next) get_value]
	wedgesize($run) set_value [wedgesize($next) get_value]
	energyEntry($run,1) set_value [energyEntry($next,1) get_value]
	energyEntry($run,2) set_value [energyEntry($next,2) get_value]
	energyEntry($run,3) set_value [energyEntry($next,3) get_value]
	energyEntry($run,4) set_value [energyEntry($next,4) get_value]
	energyEntry($run,5) set_value [energyEntry($next,5) get_value]
	distanceEntry($run) set_value [distanceEntry($next) get_value]
	startAngleEntry($run) set_value [startAngleEntry($next) get_value]
	endAngleEntry($run) set_value [endAngleEntry($next) get_value]
	detectorMode($run) set_value [detectorMode($next) get_value]
}

proc run_copy { from to } {
	
	# global variables
	global gDevice
	global gDefineRun
	
	# set each field to value in previous tab
	foreach field $gDefineRun(standardOptions) {
		set gDefineRun($to,$field) $gDefineRun($from,$field)
	}
}


proc construct_setup_window {} {
	
	# global variables
	global gWindows
	global gColors
	global gFont
	global gDevice

	# get frame to construct
	set frame $gWindows(Setup,frame)
	
	pack [ set gWindows(control,frame) [ 	\
		frame $frame.control	-height 100 -borderwidth 2 -relief flat ] ] -fill x

	create_motor_control $frame.control
	
	pack [ set gWindows(mdw,frame) [frame $frame.mdw \
		-relief sunken -borderwidth 1 ]] -fill both -expand true
	initialize_mdw_window

	
	
}


proc save_run_values { run } {

	# global variables
	global gDefineRun
	
	# set each field to value in previous tab
	foreach field $gDefineRun(standardOptions) {
		if { [info exists gDefineRun($run,fileroot)] } {
			set gDefineRun($run,$field,save) $gDefineRun($run,$field)
		}
	}
}


proc run_restore_value { run field } {
	
	# global variables
	global gDefineRun
	
	set gDefineRun($run,$field) $gDefineRun($run,$field,save) 
}


proc run_update_angle {run axis} {
	global gDefineRun
	global gDevice

   #The axisLastChoice variable is only used to avoid  updating the startangle
   #simply by re-selecting the axis angle.
 


	if { ($axis == "gonio_phi") && ( $gDefineRun($run,axisLastChoice) != "gonio_phi" ) } {
		startAngleEntry($run) set_value $gDevice(gonio_phi,scaledShort)
	}
	if { $axis == "gonio_omega" } {
		if {$gDefineRun($run,axisLastChoice) != "gonio_omega"} {
			startAngleEntry($run) set_value $gDevice(gonio_omega,scaledShort)
		}
		set gDefineRun($run,inversebeam) 0
	}

	endAngleEntry($run) set_value [expr [startAngleEntry($run) get_value] + $gDefineRun($run,delta) ] 


	update_run_to_server $run

   set gDefineRun($run,axisLastChoice) $axis
}


#This routine gets the next available sequential number for
#the run tab.
proc run_get_next_label {run} {

	global gDefineLabelList
	global gDefineRun


#  the label of the tab is the previous tab's label plus one.
   if {$run != 0 } {
      set gDefineRun($run,label) [expr $gDefineRun([expr $run - 1],label) + 1]
   }
}

proc run_configure_label { run label } {
   global gWindows
	global gDefineRun

	if { $run <= $gDefineRun(runCount) } {
		 # replace this tab's label with the next tab's label
		 $gWindows(runs,notebook) pageconfigure $run -label $label
		}

}


proc update_run_sequence {run} {
   global gDefineRun
	global gBeamline
	global gDevice

	#return if we are not on the run tab that was just updated
	if { $gDefineRun(currentTabView) != $run} {
		return
	}
	
	if { [info command wedgesize($run)] == ""} return

	set energy_list [list [energyEntry($run,1) get_value] \
							  [energyEntry($run,2) get_value] \
							  [energyEntry($run,3) get_value] \
							  [energyEntry($run,4) get_value] \
							  [energyEntry($run,5) get_value] ]

	set energyList  "[energyEntry($run,1) get_value] [energyEntry($run,2) get_value] \
						[energyEntry($run,3) get_value] [energyEntry($run,4) get_value] \
                  [energyEntry($run,5) get_value] "

	runSequence setRunDefinition 	\
		 [startAngleEntry($run) get_value] \
		 [endAngleEntry($run) get_value] \
		 $gDefineRun($run,delta) \
		 [wedgesize($run) get_value] \
		 $gDefineRun($run,inversebeam) \
		 [llength $energyList] \
		 $energyList $gDefineRun($run,fileroot) \
		 $gDefineRun($run,label) \
		 "E1 E2 E3 E4 E5" \
		 [trim $gDefineRun($run,startframe)]
 
	runSequence configure -nextFrame  $gDefineRun($run,nextframe)

	if { $run == 0 } {
		#show one frame only
		runViewer configure -_snapShotView 1
	} else {
		runViewer configure -_snapShotView 0
	}
	
	#show the current frame
	runViewer focusOnCurrentFrame
}

	
proc calculateTotalCollectionTime { numberFrames exposureTime detectorMode oscTime } {
	global gDefineRun
	global gWindows
	
	if { $gDefineRun(doseMode) } {
		set doseExposureTime [expr $exposureTime * $gWindows(runs,doseFactor) ]
	} else {
		set doseExposureTime $exposureTime
	}
	

	#log_note "$numberFrames $exposureTime $detectorMode $oscTime "
	set estimatedTime [expr $numberFrames *                          \
								  ($doseExposureTime +                          \
								  ($doseExposureTime / $oscTime) * 2.0 +        \
								  [lindex $gDefineRun(modeOverheadTime) $detectorMode] )  ]
	puts $estimatedTime
	return [secondsToHours $estimatedTime]
} 

proc secondsToHours { seconds } {
	set hours [expr int($seconds / 3600)]
	set minutes [expr  int($seconds) % 3600 /60 ] 
	set remainingSeconds [expr  (int($seconds) % 3600) %60 ] 

	if { $hours > 0} {
		return "$hours Hours, $minutes minutes, $remainingSeconds seconds"
	} elseif { $minutes > 0 } {
		return "$minutes minutes, $remainingSeconds seconds"
	} else {
		return "$remainingSeconds seconds"
	}
}


proc update_current_tab_view {run} {
	global gDefineRun
	set gDefineRun(currentTabView) $run

}

#this routine sets the "*" in the run sequence window
proc set_next_frame { newFrame } {
	global gDefineRun
	
	set run $gDefineRun(currentTabView)

	if { ![dcss is_master] } return
	

	#make sure that this run can be editted
	if { $gDefineRun($run,runStatus) == "collecting" || \
				$gDefineRun($run,runStatus) == "complete" } {
		return
	}

	set gDefineRun($gDefineRun(currentTabView),nextframe) $newFrame
	update_run_to_server $gDefineRun(currentTabView)
}

proc update_energy_list { run } {
	set energyList [list [energyEntry($run,1) get_value] \
							 [energyEntry($run,2) get_value] \
							 [energyEntry($run,3) get_value] \
							 [energyEntry($run,4) get_value] \
							 [energyEntry($run,5) get_value] ]


	set cnt 1
	foreach energy $energyList {
		if { $energy != ""} {
			energyEntry($run,$cnt) set_value $energy
			incr cnt
		}
	}
	
	for {} { $cnt <= 5} {incr cnt} {
		energyEntry($run,$cnt) set_value ""
	}

}


proc run_handle_default_button { run } { 
global gDefineRun

	run_set_to_defaults $run
	run_set_entries_to_defaults $run
#	if {$run == 0} {
#		set gDefineRun(reuseDark) 1
#	}

	update_run_to_server $run
}


proc run_handle_update_button { run } { 

	global gDefineRun
	global gDevice
	global gBeamline 

	# copy detector mode from hutch window
	if { $gBeamline(detector) == "MAR345" } {
		detectorMode($run) update_from_reference 
	}

	if { $gDefineRun($run,axis) == "gonio_phi" } {
		startAngleEntry($run) set_value $gDevice(gonio_phi,scaledShort)
	} else {
		startAngleEntry($run) set_value $gDevice(gonio_omega,scaledShort)
	}

	distanceEntry($run) set_value [format "%.3f" $gDevice(detector_z,scaled)]

	set inflectionEnergy  [userScanWindow getMadEnergy Inflection]
	set peakEnergy [userScanWindow getMadEnergy Peak]
	set remoteEnergy   [userScanWindow getMadEnergy Remote]

	set madEnergyList " $peakEnergy $remoteEnergy $inflectionEnergy"
	
	foreach index { 1 2 3 4 5 } {
		energyEntry($run,$index) set_value ""
	}

	if { $run == 0 } {
		#run 0 always updates from current energy position.
		energyEntry($run,1) set_value $gDevice(energy,scaled)
	} else {
		#try to use the mad values from the scan tab.
		set index 1
		foreach energy $madEnergyList {
			if { $energy > 0.0 } {
				energyEntry($run,$index) set_value $energy
				incr index
			}
		}
		
		if { $index == 1 } {
			energyEntry($run,1) set_value $gDevice(energy,scaled)
		}
	}

	update_energy_list $run 

	update_run_to_server $run
}




proc construct_client_window {} {
	
	# global variables
	global gWindows
	global gColors
	global gFont
	global gDevice
	global clientList
	global gUserData

	# get frame to construct
	set frame $gWindows(Users,frame)
	
	pack [ set gWindows(clients,frame) [ 	\
		frame $frame.clientlist -width 400	-height 200 -borderwidth 2 -relief flat ] ] -fill x -padx 50
	
	pack [ set clientList [iwidgets::scrolledlistbox \
									  $gWindows(clients,frame).clientlist -labeltext "Users" \
									  -vscrollmode dynamic -hscrollmode dynamic \
									  -selectmode single -textfont "courier 12 bold" \
									  -background lightgrey -textbackground lightgrey \
									  -state normal \
									  -labelfont "*-helvetica-bold-r-normal--16-*-*-*-*-*-*-*" ]] -expand 1 -fill both

	set gUserData(permitLevel) 1

	#pack [ button $frame.updateClientList -text "Update" -command "dcss sendMessage gtos_inquire_gui_clients" -font $gFont(small) ]
}

proc calculateDoseFactor { args} {
	variable gWindows
	variable gDevice
	variable gDefineRun

	if { $gDevice(doseStoredCounts,scaled) != 0} {
		set gWindows(runs,doseFactor) [format "%1.2f" \
		[expr double($gDevice(doseStoredCounts,scaled)) /  \
			double($gDevice(doseLastCounts,scaled)) ] ]
	} else {
		set gWindows(runs,doseFactor) 0
	}
	
	log_note "most recent counts   = $gDevice(doseLastCounts,scaled)"
	log_note "normalization counts = $gDevice(doseStoredCounts,scaled)"
	log_note "New dose factor = $gWindows(runs,doseFactor)"

}

proc calculate_exposure_time {run} {
#global
	variable gWindows
	variable gDevice
	variable gDefineRun

	print "calculate_exposure_time"
	
	#if { ![info exists collectTimeEntry($run)] } return

	set gDefineRun($run,exposureTime) [format "%3.1fs" [expr [collectTimeEntry($run) get_value] * $gWindows(runs,doseFactor)]]
	
	print $gDefineRun($run,exposureTime)

}


proc updateExposureTimes { args} {
	variable gDefineRun
	# enable entry fields for each run
	for { set run 0 } { $run <= $gDefineRun(runCount) } { incr run } {
		calculate_exposure_time $run
	}
}


#Updates the colors of the run tabs based on the status of the run.
proc updateRunColors { runNumber } {
	global gDefineRun
	global gWindows
	global gColors

	#return if the run is not defined
	if { $runNumber > $gDefineRun(runCount) } return

	#pick the color based on the status of the run
	switch $gDefineRun($runNumber,runStatus) {
		paused { set color $gColors(brownRed) }
		collecting {set color red }
		inactive {set color $gColors(activeBlue) }
		complete {
			#Always force the first run to be the same color.
			if {$runNumber != 0 } {
				set color $gColors(dark) 
			} else {
				set color black
			}
		}
	}
	
	#set the color
	$gWindows(runs,notebook) pageconfigure $runNumber \
		 -foreground $color -selectforeground $color
}
