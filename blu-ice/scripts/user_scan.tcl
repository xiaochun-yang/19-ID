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
##   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

class UserScanWindow {
	
	# constructor
	public method constructor { parent }

	# public methods
	public method handleEnergyMarkerMove { index value }
	public method handleEnergyEntrySubmit { index }
	public method setEdge { element edgeType edgeEnergy edgeCutoff }
	public method setParameters { args }
	public method handleStartButton {}
	public method handleModeSelect {}
	public method handleReset {}
	public method handleChoochOutput { outputString }
	public method handleChoochError { errorString }
	public method getMadEnergy { index }
	public method print {}
	public method load {}
	public method save {}

	# private methods
	private method createPeriodicTable { canvas }
	private method openElementsFile {}
	private method getNextElement { fileHandle }
	private method scan {}
	private method setEnergyOrdinates {}
	private method scanEnergy {}

	# window frames
	private variable parameterFrame
	private variable definitionFrame
	private variable plotTabFrame
	private variable notebook
	private variable graph
	private variable scanTrace
	private variable helpFrame
	private variable helpText

	# entry fields
	private variable fluorescenceEnergy
	private variable startEntry
	private variable endEntry
	private variable deltaEntry
	private variable timeEntry
	private variable energyEntry
	private variable edgeEntry
	private variable edgeEnergyEntry
	private variable parameterEdgeEnergyEntry
	private variable parameterEdgeEntry
	private variable foilEntry

	# buttons
	private variable startButton
	private variable stopButton
	private variable abortButton
	private variable choochButton

	private variable modeRadio

	# appearance
	private variable light
	private variable dark

	# current scan parameters (set when start button is pushed)
	private variable scanMode
	private variable scanStart 
	private variable scanEnd 
	private variable scanDelta 
	private variable scanTime
	private variable scanPoints
	private variable scanFilters
	private variable scanMotor
	private variable scanTiming
	private variable scanEdge
	private variable signalDetector
	private variable referenceDetector

	private variable energyOrdinates
	private variable energyPosition
	private variable absorbanceData

	# private data
	private variable filters
	private variable edgeEnergy
	private variable edgeCutoff
	private variable foil_data { 
		{ "Se K" 12657.8 12590 12730 1.0 "Se" } }
#		{ "Fe K" 7112.0 7070 7150 0.5 "HA" }
#		{ "Co K" 7708.9 7670 7750 0.5 "HA" }
#		{ "Ni K" 8332.8 8290 8380 0.5 "HA" }
#	   { "Cu K" 8978.9 8930 9030 0.5 "Cu" }
}


body UserScanWindow::print {} {
	$notebook select 1
	$graph print
}


body UserScanWindow::load {} {
	$notebook select 1
	$graph handleFileOpen
}


body UserScanWindow::save {} {
	$notebook select 1
	$graph  handleFileSave
}


body UserScanWindow::constructor { parent } {

	# global variables
	global gColors
	global gFont
	global env
	global gChoochEnergy

	# set colors for background
	set light $gColors(midhighlight)
	set dark  $gColors(unhighlight) 

	set definitionFrame [frame $parent.definitionFrame -width 250 -height 800]
	pack $definitionFrame -side left -anchor n 
	pack propagate $definitionFrame 0

	# create the tab notebook for holding the periodic table and scan graph
	pack [ frame  $parent.frame ] -side left -fill both -expand true
	pack [ set notebook [
		iwidgets::tabnotebook $parent.frame.notebook  \
			-tabbackground $dark -background $light -backdrop lightgrey -borderwidth 2\
			-tabpos n -gap 4 -angle 0 -width 720 -height 570 -raiseselect 1 -bevelamount 4 \
			-tabforeground $gColors(dark) -padx 5] ] -side left -fill both -expand true -pady 10 -padx 10

	# create the two notebook tabs
	$notebook add -label "  Periodic Table  "
	$notebook add -label "Plot"
	$notebook select 0
	
	# create two frames in the plot tab
	set plotTabFrame [$notebook childsite 1]
	pack [set energyFrame [frame $plotTabFrame.energyFrame -height 60 -bg $light]] \
		-side bottom -anchor w -pady 20 -padx 35
	pack [set graphFrame [frame $plotTabFrame.graphFrame]] \
		-side bottom -fill both -expand true

	# create the user scan graph
	set graph [Graph \#auto $graphFrame \
		-title "Energy Scan" \
		-xLabel "Energy (eV)" \
		-yLabel "Absorbance" \
		-legendFont $gFont(small) \
		-background  $light \
		-tickFont $gFont(small) \
		-titleFont $gFont(large) \
		-axisLabelFont $gFont(small) ]

	# create the chooch button
	pack [set choochButton [ button $energyFrame.chooch -text "Reset" \
		-command "$this handleReset" -font $gFont(small)]] \
		-side left -padx 10

	# create the four energy entries and markers
	foreach { index color } {Inflection orange Peak darkgreen Remote blue } {

		set gChoochEnergy($index) 0.00

		# create the vertical marker
		$graph createVerticalMarker energy$index 0.25 "Energy (eV)" \
			-width 2 -color $color -callback "$this handleEnergyMarkerMove $index" \
			-textformat "%.2f"
		# create the energy entry
		set energyEntry($index) [ \
			SafeEntry \#auto $energyFrame.energy$index -prompt "$index:" \
				-entrywidth 9 -promptforeground $color -unitsforeground $color -type positive_float\
				-onsubmit "$this handleEnergyEntrySubmit $index" -units "eV" \
				-promptbackground $light -unitsbackground $light \
				-shadow 1 -reference gChoochEnergy($index) ]
		pack $energyFrame.energy$index -side left -padx 10
	}

	# create the scan mode radio buttons
	place [ set modeRadio [iwidgets::radiobox $definitionFrame.modeRadio \
									 -labeltext "Scan Mode" -labelpos nw \
									-labelfont $gFont(small) -selectcolor red\
									 -command "$this handleModeSelect" \
									 ]] -x 10 -y 20
	[$modeRadio component label] configure -font $gFont(large)

	# create the help frame
	set helpLabeledFrame [
		iwidgets::Labeledframe $definitionFrame.helpFrame ]
	place $definitionFrame.helpFrame -x 10 -y 150
	set helpFrame [$helpLabeledFrame childsite]
	$helpFrame configure -height 65 -width 205
	pack propagate $helpFrame 0
	pack [set helpText [text $helpFrame.text \
		-font $gFont(small) -relief flat -state disabled ]] -padx 10

	# create the parameters labeled frame
	set parameterLabeledFrame [
		iwidgets::Labeledframe $definitionFrame.parameterFrame \
			-labeltext "Scan Parameters" -ipadx 0 -labelpos nw ]
	place $definitionFrame.parameterFrame -x 10 -y 260
	set parameterFrame [$parameterLabeledFrame childsite]

	# create edge entry
	set parameterEdgeEntry [ \
		SafeEntry \#auto $parameterFrame.edge -prompt "Edge: "  \
		-value ""  -useEntry 1 -state disabled -justification center\
	 	-entrywidth 9  -promptwidth 9 -entrybackground grey -unitswidth 5]

	# create edge energy entry
	set parameterEdgeEnergyEntry [ \
		SafeEntry \#auto $parameterFrame.energy -prompt "Energy: "\
		-value ""  -useEntry 1 -state disabled -justification center\
	 	-entrywidth 9  -promptwidth 9 -units " eV" -entrybackground grey -unitswidth 5]

	# create foil entry
	set foilEntry [ \
		SafeEntry \#auto $parameterFrame.foil -prompt "Foil: "\
		-value ""  -useEntry 1 -state disabled -justification center\
	 	-entrywidth 9  -promptwidth 9 -useMenu 0 -useArrow 0 -unitswidth 5 \
		-entrybackground grey]

	# create start-energy entry
	set startEntry [ \
		SafeEntry \#auto $parameterFrame.start -prompt "Start:" \
		-units "eV" -value "" -type positive_float -useEntry 1 -justification right \
	 	-entrywidth 9 -disabledbackground lightgrey -promptwidth 9 -unitswidth 5]

	# create end-energy entry
	set endEntry [ \
		SafeEntry \#auto $parameterFrame.end -prompt "High:" -units "eV" \
		-value "" -type positive_float -useEntry 1 -justification right \
		-entrywidth 9 -disabledbackground lightgrey -promptwidth 9 -unitswidth 5]

	# create delta-energy entry
	set deltaEntry [ \
		SafeEntry \#auto $parameterFrame.delta -prompt "Delta:" -units "eV" \
		-value "" -type positive_float -useEntry 1 -justification right \
		-entrywidth 9 -disabledbackground lightgrey -promptwidth 9 -unitswidth 5]

	# create time entry
	set timeEntry [ \
		SafeEntry \#auto $parameterFrame.time -prompt "Time:" -units "sec" \
		-value "" -type positive_float -useEntry 1 -justification right \
		-entrywidth 9 -disabledbackground lightgrey -promptwidth 9]

	# create the start scan button
	place [set startButton \
		[button $definitionFrame.startbutton -text "Start Scan" \
		-width 10 -command "$this handleStartButton" ]] -x 60 -y 470

	place [set stopButton \
		[button $definitionFrame.stopbutton -text "Stop Scan" -state disabled \
		-width 10 -command end_scan ]] -x 60 -y 515

	place [set abortButton \
		[button $definitionFrame.abortbutton -text "Stop Motors" \
		-width 10 -command "do abort soft" -bg $gColors(lightRed)		\
		-activebackground $gColors(lightRed) ]] -x 60 -y 560
		
	pack [frame $definitionFrame.spacer4] -pady 20
	pack [frame $definitionFrame.spacer5] -pady 10

	set periodicTableFrame [$notebook childsite 0]
	$periodicTableFrame configure -background $light

	pack [set table [frame $periodicTableFrame.table -bg $light]] -side top -fill both -expand true
	blt::table $table [frame $periodicTableFrame.00 ] 0,0
	blt::table $table [frame $periodicTableFrame.22] 2,2
	blt::table $table [set periodicTableCanvas [ canvas $periodicTableFrame.canvas -width 700 -height 500]] 1,1

	$periodicTableCanvas configure -background $light
	$periodicTableCanvas create text 350 15 -font $gFont(huge) -text "Select an X-ray Absorption Edge"

	# create edge entry
	set edgeEntry [ \
		SafeEntry \#auto $periodicTableCanvas.edge -prompt "Edge: "  \
		-value ""  -useEntry 1 -state disabled -justification center\
	 	-entrywidth 9  -promptwidth 8 -promptbackground $light \
		-font $gFont(large) -entryforeground red ]
	place $periodicTableCanvas.edge -x 160 -y 70

	# create edge energy entry
	set edgeEnergyEntry [ \
		SafeEntry \#auto $periodicTableCanvas.energy -prompt "Energy: "\
		-value ""  -useEntry 1 -state disabled -justification center\
	 	-entrywidth 9  -promptwidth 8 -units " eV"  \
 		-promptbackground $light -unitsbackground $light \
		 -font $gFont(large) -entryforeground red ]
	place $periodicTableCanvas.energy -x 160 -y 105

	createPeriodicTable $periodicTableCanvas


	$modeRadio add mad -text "MAD Scan" -pady 5 -padx 50
	#$modeRadio add foil -text "Foil Scan" -pady 5 -padx 50
	$modeRadio add excitation -text "Excitation Scan" -pady 5 -padx 50
	$modeRadio select mad

	setEdge Se K 12658.0 11222.4
}



body UserScanWindow::handleModeSelect {} {

	# get the current mode
	set mode [$modeRadio get]

	# unpack all of the parameter fields
	foreach field { edge energy foil start end delta time  } {
		pack forget $parameterFrame.$field
	}

	$helpText configure -state normal 

	# pack widgets appropriate for the new mode
	switch $mode {

		excitation {
			foreach field {  edge energy time  } {
				pack $parameterFrame.$field -side top -pady 5 -anchor w
			}
			$helpText delete 1.0 end
			$helpText insert end "Scan sample using\nparameters specified\nbelow."
		}
		
		mad {
			foreach field {  edge energy time  } {
				pack $parameterFrame.$field -side top -pady 5 -anchor w
			}
			$helpText delete 1.0 end
			$helpText insert end "Scan sample to determine\npeak, inflection and\nremote energies for MAD."

		}

		foil {
			foreach field { foil start end delta time } {
				pack $parameterFrame.$field -side top -pady 5 -anchor w
			}
			$helpText delete 1.0 end
			$helpText insert end "Scan a foil to calibrate\nenergy."
		}
	}
	$helpText configure -state disabled

	# reset parameters
	setParameters
}


body UserScanWindow::getMadEnergy { index } {

	return [$energyEntry($index) get_value]
}

body UserScanWindow::handleReset {} {

	foreach index [array names energyEntry] {
		$energyEntry($index) update_from_reference
		handleEnergyEntrySubmit $index
	}
}


body UserScanWindow::handleEnergyMarkerMove { index value } {

	$energyEntry($index) set_value [format "%.2f" $value]
}


body UserScanWindow::handleEnergyEntrySubmit { index } {

	set value [$energyEntry($index) get_value]
	catch { $graph configureVerticalMarker energy$index -position $value }
}


body UserScanWindow::setEdge { element edgeType passedEdgeEnergy passedEdgeCutoff } {

	# 
	$edgeEntry set_value "${element}-${edgeType}"
	$edgeEnergyEntry set_value $passedEdgeEnergy
	$parameterEdgeEntry set_value "${element}-${edgeType}"
	$parameterEdgeEnergyEntry set_value $passedEdgeEnergy
	set edgeEnergy $passedEdgeEnergy
	set edgeCutoff $passedEdgeCutoff

	log_note "Edge cuttoff = $edgeCutoff"
	
	# update scan parameters
	setParameters
}


body UserScanWindow::setParameters { args } {

	# determine closest foil to currently selected edge
	set closestDist 20000
	
	foreach foil $foil_data {
		
		set dist [expr abs( [$edgeEnergyEntry get_value] - [lindex $foil 1] ) ]
		
		if { $dist < $closestDist } {
			set calibrationEdge [lindex $foil 0]
			set start [lindex $foil 2]
			set end [lindex $foil 3]
			set delta [lindex $foil 4]
			set filters [lindex $foil 5]
			set closestDist $dist
			
			$foilEntry set_value [lindex [lindex $foil 0] 0]
		}
	}

	# calculate edge scan parameters if not in foil mode
	if { [$modeRadio get] != "foil" } {
		
		# calculate scan parameters
#		set radius [expr $edgeEnergy / 200.0 ]
#		set start [expr int( ($edgeEnergy - $radius) / 10 ) * 10 ]
#		set end [expr int( ($edgeEnergy + $radius) / 10 + 1) * 10 ]
#		set delta [format "%.1f" [expr ($end - $start) / 40.0]]

		set start [expr $edgeEnergy - 30.0]
		set end [expr $edgeEnergy + 30.0]
		set delta 1.0
	}

	# set scan parameters
	$startEntry set_value $start
	$endEntry set_value $end
	$deltaEntry set_value $delta

	if { [$modeRadio get] == "excitation" } {
		$timeEntry set_value 10.0
	} else {
		$timeEntry set_value 1.0
	}

	set fluorescenceEnergy $edgeCutoff
}


body UserScanWindow::createPeriodicTable { canvas } {

	# global variables
	global gWindows
	global gColors
	global gFont
	
	set fileHandle [openElementsFile]
		
	while {[set elementInfo [getNextElement $fileHandle]] != "null"} {
	
	 	set atomicZ [lindex $elementInfo 0]
	 	set row [lindex $elementInfo 1]
	 	set column [lindex $elementInfo 2]
		set symbol [lindex $elementInfo 3]

		set xcoordinate [expr 8 + 38*($column-1)]
		set ycoordinate [expr 8 + 53*($row-1)]
		
		if {$row > 7} {
			set xcoordinate [expr $xcoordinate+5]
			set ycoordinate [expr $ycoordinate+5]
		}
		
		$canvas create rectangle $xcoordinate $ycoordinate [expr $xcoordinate+38] \
					 [expr $ycoordinate+53] -fill white -outline $dark
		
		$canvas create rectangle [expr $xcoordinate+1] [expr $ycoordinate+1] \
					 [expr $xcoordinate+15] \
					 [expr $ycoordinate+14] -fill $gColors(lightRed) -outline ""
		
		$canvas create text [expr $xcoordinate+2] [expr $ycoordinate+2] \
						-anchor nw -font $gFont(tiny) \
						-text $atomicZ 
						
		$canvas create text [expr $xcoordinate+16] [expr $ycoordinate+11] \
						-anchor nw -font $gFont(small) \
						-text $symbol 
						
		if { [llength $elementInfo] == 5 } {
			for {set iedge 1} {$iedge <= [lindex $elementInfo 4]} {incr iedge} {
				
				set edgeInfo [getNextElement $fileHandle]
				if { [lindex $edgeInfo 2] == "Y" } {
					set edgeType [lindex $edgeInfo 0]
					set edgeEnergy [lindex $edgeInfo 1]
					set edgeCutoff [lindex $edgeInfo 3]
					set edgeTag [format "edge%s%s" $symbol $edgeType]
					
					switch $edgeType {
						"K" {
							set xin 15
							set yin 30
							}
						"L1" {
							set xin 1
							set yin 13
							}
						"L2" {
							set xin 1
							set yin 25
							}
						"L3" {
							set xin 1
							set yin 37
							}
						"M1" {
							set xin 16
							set yin 25
							}
						"M2" {
							set xin 16
							set yin 37
							}
					}
					place [set gWindows($edgeTag) [ label $canvas.$edgeTag \
						-text $edgeType -anchor nw -fg "red" -padx 0 -pady 0 -bg white\
						-font $gFont(tiny) ]] \
						-x [expr $xcoordinate+$xin] -y [expr $ycoordinate+$yin]
	
					bind $gWindows($edgeTag) <1> "$this setEdge $symbol $edgeType $edgeEnergy $edgeCutoff"
	
				}
			}
		}
	}
	
	#close_elements_file
	close $fileHandle
}


body UserScanWindow::openElementsFile {} {

	# global variables
	global gBeamline
	global BLC_DATA

	set filename $gBeamline(periodicFile)

	# open the file
	if [ catch {set fileHandle [open $filename r] } errorResult ] {
		return -code error $errorResult
	}
	
	return $fileHandle
}


body UserScanWindow::getNextElement { fileHandle } {

	if { [gets $fileHandle buffer] > 4} {
		return $buffer
	} else {
		return "null"
	}
}


body UserScanWindow::handleStartButton {} {

	# global variables
	global gUserScan
	global gScan
	global gScanData
	global gDevice
	global BLC_DATA
	global env
	global gWindows
	global gChoochEnergy

	# return if user is not master
	if { ! [dcss is_master] } {
		log_error "This client is not the master."
		return
	}

	# make a copy of current parameters
	set scanMode [$modeRadio get]
	set scanStart [$startEntry get_value]
	set scanEnd [$endEntry get_value]
	set scanDelta [$deltaEntry get_value]
	set scanTime [$timeEntry get_value]
	set scanEdge [$edgeEntry get_value]

	# check for invalid values in the numerical entries
	foreach field { scanStart scanEnd scanDelta scanTime } {
		if { ! [is_float [set $field]] } {
			log_error "Invalid value in $field entry."
			return
		}
	}

	# reverse start and end energies if in reverse order
	if { $scanStart > $scanEnd } {
		set temp $scanStart
		set scanStart $scanEnd
		set setScanEnd $temp
	}
	
	# set the dac
	log_note "Cutoff value = $fluorescenceEnergy"
	set dacValue [expr $fluorescenceEnergy * -0.00024026 + 4.946 ]
	#move dac to $dacValue mm

	# bring up plotting pane
	$notebook select 1
	
	# disable the start button
	$startButton configure -state disabled
	
	# enable the stop button
	$stopButton configure -state normal
	update idletasks
	
	# delete all existing traces in graph
	$graph deleteAllTraces
	
	# create the new trace
	set scanTrace scan
	$graph createTrace $scanTrace {"Energy (eV)"} {}
	$graph configure -xLabel "Energy (eV)" -x2Label "" -y2Label ""


	# reset chooch energies and markers to zero
	foreach energy { Inflection Peak Remote } {
		set gChoochEnergy($energy) 0.00
		$energyEntry($energy) update_from_reference
		handleEnergyEntrySubmit $energy
	}

	# calculate energy points to scan through
	setEnergyOrdinates
	
	# set up graph depending on scan mode
	switch [$modeRadio get]  {
			
		basic {
			
			set signalDetector "i_sample"
			set referenceDetector "i2"
			set scanFilters ""

			$graph configure -title "Sample Fluorescence Scan"
			
			# create the three sub-traces
			foreach {subtrace yLabelList} \
				{	signal {"Signal Counts" "Counts"} \
						ref {"Reference Counts" "Counts"} \
						fluor {"Fluorescence"} \
					} {
						$graph createSubTrace $scanTrace $subtrace $yLabelList {}	
					}
			$graph configure -yLabel "Fluorescence"
		}
		
		mad  {
			
			set signalDetector "i_sample"
#			set signalDetector "i0"
			set referenceDetector "i0"

			set scanFilters ""
#			set scanFilters "Se"

			$graph configure -title "Fluorescence Scan of [$edgeEntry get_value] Edge"
			
			# create the three sub-traces
			foreach {subtrace yLabelList color} \
				 {	signal {"Signal Counts" "Counts"} darkgreen \
						ref {"Reference Counts" "Counts"} black \
						fluor {"Sample Fluorescence" "Fluorescence" } red \
					} {
						$graph createSubTrace $scanTrace $subtrace $yLabelList {} -color $color	
					}
			$graph configure -yLabel "Sample Fluorescence"
		}
		
		foil  {

			set signalDetector "i1"
			set referenceDetector "i0"
			set scanFilters $filters
			
			$graph configure -title  "Calibration Scan of [$foilEntry get_value] Foil"
			
			# create the three sub-traces
			foreach {subtrace yLabelList} \
				{	signal {"Signal Counts" "Counts"} \
						ref {"Reference Counts" "Counts"} \
						abs {"Absorbance"} \
					} {
						$graph createSubTrace $scanTrace $subtrace $yLabelList {}	
					}
			$graph configure -yLabel "Absorbance"

			set absorbanceData {}
		}
		excitation  {
			set signalDetector "i_sample"
			set referenceDetector "i2"
			set scanFilters ""

			$graph configure -title "Excitation Scan of [$edgeEntry get_value] Edge"
			
			# create the three sub-traces
			foreach {subtrace yLabelList color} {
				counts {"Signal Counts" "Counts"} darkgreen
			} { $graph createSubTrace $scanTrace $subtrace $yLabelList {} -color $color }
			$graph configure -yLabel "Sample Fluorescence"
			set energyOrdinates [list 12000 14000]
		}

	}

	# set x-axis limits
	#$graph setZoomDefaultX [lindex $energyOrdinates 0] [lindex $energyOrdinates end]

	set gWindows(runsStatusText) "Scanning energy..."
	$gWindows(runsStatus) configure -fg red

	# execute the scan command
	if { [$modeRadio get] == "excitation" } {

		#Inform the graph widget which trace to display
		$graph configure -yLabel [list "Counts"]

		if { [catch {

			#
			if {$scanTime > 60.0} {
				log_error "Scan time is excessive (>60.0 sec)."
				return
			}

			#prepare for the scan
			set opHandle [start_waitable_operation prepareForScan $gDevice(energy,scaled)]
			set prepareResult [wait_for_operation $opHandle]
			
			#check for errors
			set status [lindex $prepareResult 0]
			if { $status != "normal" } { return -code error $status }

			#get the excitation spectrum
			set scanHandle [start_waitable_operation excitationScan 0 25600 1024 $referenceDetector $scanTime]
			log_note "waiting for scan"
			set scanResult [wait_for_operation $scanHandle]
			
			#check for errors
			set status [lindex $scanResult 0]
			if { $status != "normal" } { return -code error $status }

			#recover from scan while graphing the results
			start_operation recoverFromScan

			#graph the results
			set energyPosition 12.5
			set firstPoint 1
			
			foreach resultCounts [lrange $scanResult 3 end] {
				$graph addToTrace $scanTrace $energyPosition $resultCounts
				
				if { $firstPoint } {
					set firstPoint 0
					$graph setZoomDefaultX 000 25000
				}
				set energyPosition [expr $energyPosition + 25.0]
			}
			set result 0
		} errorResult] } {
			#we had an error
			#log_error $errorResult
			set result 1
		}
	} else {
		set result [scan]
	}

	# calibrate energy if scan successful and doing a foil scan
	if { $result == 0 && $gScan(scanStoppedByUser) == 0 } {

		if { $scanMode == "foil" } {
			log_note "Calibrating energy..."
		
			set calibration [cal_correct_energy "Se K" $energyOrdinates $absorbanceData \
								  "$BLC_DATA/calibration_edges.dat" ]

			log_note "Result of calibration :  $calibration"

			if { $calibration == "error" } {
				log_error "Error calibrating energy."
			} else {
				set correlation [lindex $calibration 0]
				log_note "Correlation = $correlation"
				if { $correlation > 0.9 } {
					set correction [expr [lindex $calibration 1] * 180.0 / 3.141593 ]
					set newValue [expr $gDevice(mono_theta,scaled) + $correction]
					::configure mono_theta_corr position $newValue deg
					log_note "Correction to mono_theta = $correction"
				} else {
					log_warning "Calibration failed.  Correlation too low."
				}
			}
		}
	
		if { $scanMode == "mad" } {

			# make the temporary directory if needed
			file mkdir /tmp/$env(USER)

			# write scan to temporary file for chooch
			$graph saveFile "/tmp/$env(USER)/choochInput.bip"

			# extracth element symbol and edge symbol from edge string
			set splitEdge [split $scanEdge "-"]
			set element [lindex $splitEdge 0]
			set edge [lindex $splitEdge 1]

			log_note "Starting autochooch on fluorescence scan."
			
			# execute autochooch in background
			blt::bgexec choochRun \
				 -onoutput "$this handleChoochOutput" \
				 -onerror "$this handleChoochError" \
				 autochooch /tmp/$env(USER)/choochInput.bip $element $edge &

			# wait for autochooch to finish
			tkwait variable choochRun

			log_note "Autochooch is complete."
			set gWindows(runsStatusText) "Moving energy..."
			# wait for the energy move to complete
			wait_for_devices energy
		}
	}
	
	# disable the stop button and enable the start button
	set gWindows(runsStatusText) "Idle"
	$gWindows(runsStatus) configure -fg black
	$stopButton configure -state disabled
	$startButton configure -state normal
}


body UserScanWindow::handleChoochOutput { outputString } {

	# global variables
	global env
	global gChoochEnergy
	global gWindows

	# load the files output by autochooch as they become available
	foreach filename { smooth_exp.bip smooth_norm.bip fp_fpp.bip } {
		
		if { [lsearch $outputString $filename] != -1 } {
			log_note "Loading $filename"
			if { [catch {$graph openFile /tmp/$env(USER)/$filename}] } {
				log_error "Error loading $filename."
			}
		}
	}

	# extract MAD energies from Chooch output 
	foreach energy { Inflection Peak Remote } {

		if { [set index [lsearch $outputString ${energy}_info]] != -1 } {
			incr index
			set gChoochEnergy($energy) [format "%.2f" [lindex $outputString $index]]
			$energyEntry($energy) update_from_reference
			handleEnergyEntrySubmit $energy
			log_note "$energy energy is $gChoochEnergy($energy) eV"
		}
	}
	
	# split output into a list of lines
	set lineList [split $outputString \n]
	
	# handle chooch  messages
	foreach line $lineList {

		# log chooch errors
		if { [lindex $line 0] == "ERROR:" } {
			log_error "Third party program CHOOCH reports: [lreplace $line 0 0]"
		}
		
		# put chooch status into BLU-ICE status window
		if { [lindex $line 0] == "CHOOCH_STATUS:" } {
			log_note "Third party program CHOOCH reports: [set gWindows(runsStatusText) [lreplace $line 0 0]]"
		}
	}
}

body UserScanWindow::handleChoochError { errorString } {

#	log_error $errorString
}





body UserScanWindow::scan {} {
	
	# global variables
	global gScan	
	global gDevice

	set gScan(aborted) 0
	set gScan(requestedStop) 0
	set gScan(type) energy

	# store old motor positions as necessary
	set oldEnergyPosition $gDevice(energy,scaled)
	
	# set scan status to starting
	set gScan(status) starting
	updateMotorControlButtons

	# insert and remove filters as necessary
	set previousFilterStates [set_filter_states $scanFilters]

	# optimize beam line for scan if not doing a foil scan
	if { $scanMode == "mad" } {	
		set operationID [start_waitable_operation prepareForScan [expr $edgeEnergy + 100.0] ]
		wait_for_operation $operationID
	}

	# open shutter if necessary
	if { ( $gDevice($signalDetector,afterShutter) || $gDevice($referenceDetector,afterShutter) ) && \
				$gDevice(shutter,state) == "closed" } {
		open_shutter shutter
		set closeShutterWhenDone 1	
	} else {
		set closeShutterWhenDone 0
	}

	set gScan(status) scanning
	
	# wait for ion chambers to become inactive
	eval wait_for_devices $signalDetector $referenceDetector
	
	# do the scans and catch errors
	set code [catch {scanEnergy} result]
	
	# stop scan early if so requested
	if { $gScan(requestedStop) } {
		log_warning "Scan stopped by user."
		set gScan(scanStoppedByUser) 1
	} else {
		set gScan(scanStoppedByUser) 0
	}

	# close shutter if necessary
	if { $closeShutterWhenDone == 1 && $gDevice(shutter,state) == "open" } {
		close_shutter shutter
	}

	# restore filter states
	set_filter_states $previousFilterStates

	# set the scan status to inactive
	set gScan(status) inactive
	log_note "Scan complete."
	
	updateMotorControlButtons
	
	# move energy back to previous position if scan successful
	if { $code == 0 || ($code == 5 && $gScan(aborted) == 0) } {

		# recover beam line state if not doing a foil scan
		if { $scanMode == "mad" } {
			set operationID [start_waitable_operation recoverFromScan]
			wait_for_operation $operationID
		}
		
		log_note "Moving energy back to $oldEnergyPosition eV"
		set gWindows(runsStatusText) "Moving energy..."
		move energy to $oldEnergyPosition eV
		if { $scanMode != "mad" } {
			wait_for_devices energy
		}
	} else {
		log_error "Scan was aborted."
	}

	# return an error if appropriate
	if { $code == 5 } {
		return 5
	} elseif { $code > 0 } {
		error $result
	}
	
	return 0
}


body UserScanWindow::setEnergyOrdinates {} {

	# global variables
	global gBeamline

	# initialize ordinates
	set energyOrdinates 		{}

	# determine energy values for scan
	set scanPoints [expr int( ($scanEnd - $scanStart) / double($scanDelta) + 1.99) ]
	set scanEnd [expr $scanStart + ($scanPoints - 1) * $scanDelta]

	if { $scanMode == "mad" } {


		lappend energyOrdinates [expr $scanStart - 170.0]
		lappend energyOrdinates [expr $scanStart - 140.0]

		set step 20.0

		for { set energy [expr $scanStart - 120.0] } { $energy < $scanStart } { set energy [expr $energy + $step] } {
			lappend energyOrdinates $energy
			set step [expr $step -1.5]
			#print $step
		}

		for { set point 0 } { $point < $scanPoints } { incr point } {
			lappend energyOrdinates [expr $scanStart + $point * $scanDelta ]
		}
		
		set step 2
		for { set energy [expr $scanEnd + 1.5] } { $energy < [expr $scanEnd + 130.0] } { set energy [expr $energy + $step] } {
			lappend energyOrdinates $energy
			set step [expr $step + 1.5]
		}

		lappend energyOrdinates [expr $scanEnd + 150.0]
		lappend energyOrdinates [expr $scanEnd + 180.0]

	} else {

		for { set point 0 } { $point < $scanPoints } { incr point } {
			lappend energyOrdinates [expr $scanStart + $point * $scanDelta ]
		}
	}

	#reverse the energy ordinates to go with backlash
	if { $gBeamline(energyScanDir) == "DOWN" } {
		set energyOrdinates [reverseList $energyOrdinates]
	}

	#strip off energy values that are outside of the motors limits
	set energyOrdinates [trimListWithLimits $energyOrdinates [device::energy cget -lowerLimit] [device::energy cget -upperLimit]]

	#	print $energyOrdinates
}


body UserScanWindow::scanEnergy {} {

	# global variables
	global gScan
	global gDevice
	global gBeamline

	set firstPoint 1

	#print "Starting scanEnergy..."
	
	# loop over x-ordinates
	foreach energyPosition $energyOrdinates {
		
		# stop scan if so requested
		if { $gScan(requestedStop) } {
			break
		}

		#print "About to move energy to next scan position..."

		# move the motor to the next scan position
		move_no_parse energy to $energyPosition 0

		#print "Energy is moving..."

		wait_for_devices energy

		# wait for motors to settle
		wait_for_time 100
		
		if { $scanMode == "foil" } {
			# do the counting
			eval count $scanTime $signalDetector $referenceDetector
			eval wait_for_devices $signalDetector $referenceDetector

			# store the signal detector counts
			set referenceCounts [expr double($gDevice($referenceDetector,counts)) ]
			set signalCounts [expr double($gDevice($signalDetector,counts)) ]

		} else {

			set startEnergy [expr $fluorescenceEnergy - 300]
			set endEnergy [expr $fluorescenceEnergy + 300]

			set opHandle [start_waitable_operation excitationScan $startEnergy $endEnergy 1 i0 $scanTime]
			set result [wait_for_operation $opHandle]

			set status [lindex $result 0]
			if { $status == "normal" } {
				set deadTimeRatio [lindex $result 1]
				set referenceCounts [lindex $result 2]
				
				set signalCounts [lindex $result 3]
				set signalCounts [expr $signalCounts / (1 - $deadTimeRatio )]
			} else {
				log_error "scan failed"
				return
			}
		}

		
		# set reference counts to 1 if zero
		if { $referenceCounts == 0 } {
			set referenceCounts 1
		}

		if { $scanMode == "foil" } {
			
			# calculate transmission
			set absorbance [expr -log( double($signalCounts) / double($referenceCounts) ) ]

			lappend absorbanceData $absorbance
			#print $absorbanceData
			
			# add data points to graph
			$graph addToTrace $scanTrace $energyPosition \
				"$signalCounts $referenceCounts $absorbance"


		} else {

			# calculate transmission
			set fluorescence [expr double($signalCounts) / double($referenceCounts) ]
			
			# add data points to graph
			$graph addToTrace $scanTrace $energyPosition \
				"$signalCounts $referenceCounts $fluorescence"
		}
		
		if { $firstPoint } {
			set firstPoint 0

			#check to see if energy ordinates have been reversed to go with backlash
			if { $gBeamline(energyScanDir) == "DOWN" } {
				$graph setZoomDefaultX [lindex $energyOrdinates end] [lindex $energyOrdinates 0]
			} else {
				$graph setZoomDefaultX [lindex $energyOrdinates 0] [lindex $energyOrdinates end]
			}
		}
	}
}





