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


set gScan(status) inactive
set gScan(file_root)  ${gBeamline(beamlineId)}_optics
set gScan(file_num) 1
set gScan(requestedDetectors) "signal reference"
set gScan(scansLoaded) 0
set gDevice(none,counts) 0
set gDevice(time,scaled) 0.0

set gDevice(none,afterShutter) 0

set gScan(convert_from_sec) 1000
set gScan(convert_from_min) 60000
set gScan(convert_from_hrs) 3600000
set gScan(overlay) 1
set gScan(mode) signal_and_reference
set gScan(min_visible_z_ordinate) 0
set gScan(max_visible_z_ordinate) 10
set gScan(requestedStop) 0

proc load_scan_dialog {} {

	# get the name of the file to open
	set filename [tk_getOpenFile]

	# make sure the file selection was not cancelled
	if { $filename != {} } {
		load_scan $filename
	}
}


proc load_scan { filename } {

	# global variables
	global gScan
	global gScanData

	# make sure file exists
	if { ! [file isfile $filename] } {
		log_error "File $filename does not exist."
		return
	}
	
	# make sure file is readable
	if { ! [file readable $filename] } {
		log_error "File $filename is not readable."
		return
	}
	
	# open the file
	if [ catch {open $filename r} fileHandle ] {
		log_error "File $filename could not be opened."
		return
	}
	
	set result [ catch {
		
	# read file header
	read_scan_file_header $fileHandle motor1 motor2 detectors filters timing
	set numDetectors [llength $detectors]
	
	# set definition to that of loaded file if definition window open
	if { [mdw_document_exists define_scan] } {
		set_definition $motor1 $motor2 $detectors $filters $timing
	}

	gets $fileHandle buffer
	gets $fileHandle buffer
	gets $fileHandle buffer
	
	# see if scan window is open
	if { [mdw_document_exists scan] } {

		# destroy scan window if new scan incompatible with previous scan
		if { $motor1 != $gScan(motor1) || $motor2 != $gScan(motor2) || \
			 [llength $detectors] != [llength $gScan(detectors) ] } {
			destroy_mdw_document scan
		}
	}
	
	# if no scan window then extract scan parameters
	if { ! [mdw_document_exists scan] } {
		extract_scan_parameters $motor1 $motor2 $detectors $timing

		set gScan(motor1) $motor1
		set gScan(motor2) $motor2
		set gScan(detectors) $detectors
		set gScan(timing) $timing
		set gScan(filters) $filters

		# calculate ordinates for scan
		calculate_scan_ordinates
	}	

	# get ready to load scan data
	get_next_scan_filenum
	set gScan(filename) [file tail $filename]
	prepare_next_scan

	# load the data
	if { $gScan(axisCount) == 1 } {
	
		catch { 
			foreach x $gScan(x_ordinates) {
				gets $fileHandle buffer
				if { $numDetectors == 1 } {
					set signal [lindex $buffer 1]
					if { $signal == {} } {
						log_error "No data for signal."
						expr 1/0
					}
					set gScanData($gScan(filename),signal,$x,0) $signal
				} else {
					set signal [lindex $buffer 1]
					set reference [lindex $buffer 2]
					set trans [lindex $buffer 3]
					set abs	[lindex $buffer 4]
					if { $signal == {} || $reference == {} || $trans == {} || $abs == {} } {
						expr 1/0
					}
					set gScanData($gScan(filename),signal,$x,0) $signal
					set gScanData($gScan(filename),reference,$x,0) $reference 
					set gScanData($gScan(filename),trans,$x,0) $trans 
					set gScanData($gScan(filename),abs,$x,0) $abs 
				}
				add_scanlog_entry $x 0
			}
		}

		# display the data 
		set gScan(motor1,position) $x
		set gScan(no_points) 0
		zoom restore

	} else {
		catch { 
			foreach x $gScan(x_ordinates) {
				foreach y $gScan(y_ordinates) {
					gets $fileHandle buffer
					if { $numDetectors == 1 } {
						set signal [lindex $buffer 2]
						if { $signal == {} } {
							expr 1/0
						}
						set gScanData($gScan(filename),signal,$x,$y) $signal
					} else {
						set signal [lindex $buffer 2]
						set reference [lindex $buffer 3]
						set trans [lindex $buffer 4]
						set abs	[lindex $buffer 5]
					if { $signal == {} || $reference == {} || $trans == {} || $abs == {} } {
							expr 1/0
						}
						set gScanData($gScan(filename),signal,$x,$y) $signal
						set gScanData($gScan(filename),reference,$x,$y) $reference
						set gScanData($gScan(filename),trans,$x,$y) $trans 
						set gScanData($gScan(filename),abs,$x,$y) $abs 
					}
					add_scanlog_entry $x $y
				}
			}
		}
		
		# display the data 
		set gScan(motor1,position) $x
		set gScan(no_points) 0
		refresh_plot
	}	
	
	} ] 
	
	if { $result } {
		log_error "Error reading file."
	}

	# close the file
	close $fileHandle
}



proc extract_scan_parameters { motor1 motor2 detectors timing } {

	# global variables
	global gScan

	# extract timing parameters
	parse_timing_parameters $timing gScan(scan_time) gScan(scan_pause) \
		gScan(scan_count) gScan(scan_period) gScan(scan_period_units)
	set gScan(scan_file_count) $gScan(scan_count)

	# determine number of scan axes
	set gScan(axisCount) [expr [ llength "$motor1 $motor2" ] / 6 ]

	# swap motor indices if motor1 is blank
	if { $motor1 == {} } {
		set motor1 $motor2
	}
	
	# extract motor1 parameters
	parse_motor_parameters $motor1 gScan(motor1,name) gScan(motor1,points) \
		gScan(motor1,start) gScan(motor1,end) gScan(motor1,step)	\
		gScan(motor1,units) gScan(motor1,unitIndex)
		
	# extract motor2 parameters if appropriate
	if { $gScan(axisCount) == 2 } {
		parse_motor_parameters $motor2 gScan(motor2,name) gScan(motor2,points) \
			gScan(motor2,start) gScan(motor2,end) gScan(motor2,step)	\
			gScan(motor2,units) gScan(motor2,unitIndex)
		set gScan(scan_file_count) $gScan(scan_count)
		set gScan(type) counts_vs_2_motors
	} else {
		set gScan(type) counts_vs_1_motor
	}
		
	# extract detector parameters
	set gScan(signal) [lindex $detectors 0]
	if { [llength $detectors] > 1 } {
		set gScan(reference) [lindex $detectors 1]
		set gScan(requestedDetectors) "signal reference"
#		set_scan_mode "signal_and_reference" 1
	} else {
		set gScan(reference) none
		set gScan(requestedDetectors) "signal"
#		set_scan_mode "signal" 1
	}

	# initialize count maximum
	if { ! [mdw_document_exists scan] } {
		set gScan(minCounts) 0
		set gScan(maxCounts) 100
		set gScan(firstPoint) 1
	}
}


proc prepare_next_scan { } {

	# global variables
	global gScan
	global gPlot
	global gDevice
	global gDefineScan
	
	incr gScan(scansLoaded)
	set gScan($gScan(filename),scanIndex) $gScan(scansLoaded)
	set gScan($gScan(filename),color) $gPlot(color,$gScan(scansLoaded))

	# destroy old scan window if overlay deselected
	if { ! $gScan(overlay) } {
		catch { destroy_mdw_document scan }
	}
	
	# bring up the scan window
	pop_scan_window
			
	clear_scanlog
		
	lappend gScan(scans) $gScan(filename)
	set gScan(show,$gScan(filename)) 1
	add_scan_legend $gScan(filename) 

	# initialize the new scan plot
	clear_scan_curves $gScan(filename)


	set gDevice(time,scaled) 0.0

}


proc repeat_scan {} {
	# global variables
	global gScan

	start_scan $gScan(motor1) $gScan(motor2) $gScan(detectors) $gScan(filters) $gScan(timing)
}


proc start_scan { motor1 motor2 detectors filters timing } {

	# global variables
	global gScan	
	global gScanlog
	global gDevice
	global gScanData
	global gPlot
	global gDefineScan
	global gUserScan
	
	# make sure we are master
	if { ! [dcss is_master] } {
		log_error "This client is not the master.  Scans are not allowed."
		return
	} 
	
	# save current value of overlay
	set gScan(overlay) $gDefineScan(overlay)

	catch { 
		destroy $gUserScan(plotFrame).menu 
		destroy $gUserScan(plotFrame).canvas
		if { $gUserScan(plotExists) } {
			set gUserScan(plotExists) 0
			destroy_scan
		}
	}

	if { $gUserScan(inUse) } {
		destroy_scan
	}

	# check if scan window open
	if { [mdw_document_exists scan] } {
	
		# destroy scan window if new scan incompatible with previous scan
		if { $motor1 != $gScan(motor1) || $motor2 != $gScan(motor2) || \
			 [llength $detectors] != [llength $gScan(detectors) ]  || \
			 $gScan(scansLoaded) > 9 } {
			destroy_mdw_document scan
		}
	}

	# fill in gScan data structure
	set gScan(motor1) $motor1
	set gScan(motor2) $motor2
	set gScan(detectors) $detectors
	set gScan(filters) $filters
	set gScan(timing) $timing
	set gScan(refresh) 0
	set gScan(aborted) 0
	set gScan(requestedStop) 0

	# extract motor parameters
	extract_scan_parameters $motor1 $motor2 $detectors $timing


	# store old motor positions as necessary
	switch $gScan(axisCount) {
		1 { 
			set gScan(motor1,oldPosition) $gDevice($gScan(motor1,name),scaled)
		}
		2 {
			set gScan(motor1,oldPosition) $gDevice($gScan(motor1,name),scaled)
			set gScan(motor2,oldPosition) $gDevice($gScan(motor2,name),scaled) 
 		}
 	}

	# make sure none of the files to be written exist
	if { $gScan(file_root) != "" } {
	
		set firstNum $gScan(file_num)
		set lastNum [expr $firstNum + $gScan(scan_file_count) - 1 ]
		
		for { set num $firstNum } { $num <= $lastNum } { incr num } {
			set filename "$gScan(file_root)_[format "%03d" $num].scan"
			if { [file exists $filename] } {
				log_error "File $filename already exists!"
				return
			}
		}
	}
	
	# set scan status to starting
	set gScan(status) starting
	updateMotorControlButtons

	# insert and remove filters as necessary
	set prev_states [set_filter_states $filters]
	eval "wait_for_devices $gDevice(foil_list)"

	# open shutter if necessary
	if { ( $gDevice($gScan(signal),afterShutter) || $gDevice($gScan(reference),afterShutter) ) && \
				$gDevice(shutter,state) == "closed" } {
		open_shutter shutter
		set gScan(close_shutter_when_done) 1	
	} else {
		set gScan(close_shutter_when_done) 0
	}

	set gScan(status) scanning

	# calculate ordinates for scan
	calculate_scan_ordinates

	# do scan_count scans
	while { 1 } {

		# open scan data file
		set gScan(filename) "$gScan(file_root)_[format "%03d" $gScan(file_num)].scan"
		if { [file exists $gScan(filename)] } {1
			log_error "File $gScan(filename) already exists!"
			return
		}
		if { [catch {set f [open $gScan(filename) w ] } ] } {
			log_error "Error opening $gScan(filename)."
			return
		}
		
		write_scan_file_header $f $gScan(filename) $motor1 $motor2 $detectors $filters $timing
		log_note "Saving scan data to $gScan(filename)."
		
		prepare_next_scan
			
		# wait for ion chambers to become inactive
		eval wait_for_devices $gScan(detectors)
		
		# do the scans and catch errors
		set code [catch {execute_scans} result]
		
		# save scan data in file
		puts $f $gScanlog(data)
		close $f
		catch {incr gScan(file_num)}

		incr gScan(scan_file_count) -1
		
		# stop scan early if so requested
		if { $gScan(requestedStop) } {
			log_warning "Scan stopped by user."
			set gScan(scanStoppedByUser) 1
			break
		} else {
			set gScan(scanStoppedByUser) 0
		}

		if { $code != 0 || $gScan(scan_file_count) <= 0 } { 
			break
		} else {
			log_note "Waiting $gScan(scan_period) $gScan(scan_period_units) for next scan..."
			set code [catch { wait_for_time [expr int($gScan(scan_period) * \
				$gScan(convert_from_$gScan(scan_period_units)))] } ]

			if { $code != 0 } {
				break
			}
		}
	}

	# close shutter if necessary
	if { $gScan(close_shutter_when_done) == 1 && $gDevice(shutter,state) == "open" } {
		close_shutter shutter
	}

	# restore filter states
	set_filter_states $prev_states
	eval "wait_for_devices $gDevice(foil_list)"

	# set the scan status to inactive
	set gScan(status) inactive
	log_note "Scan complete."
	
	# disable the end scan button
	catch { $gScan(zoomInButton) configure -state normal }
#	catch { $gScan(endScanButton) configure -state disabled }
	
	updateMotorControlButtons
	
	# move motors back to previous positions if scan successful
	if { $code == 0 || ($code == 5 && $gScan(aborted) == 0) } {
		restore_motor_position motor1 
		wait_for_devices $gScan(motor1,name)
		if { $gScan(axisCount) == 2 } {
			restore_motor_position motor2 
		}
	} else {
		log_error "Scan was aborted."
	}
		
	# return an error if appropriate
	if { $code == 5 } {
		return -code 5
	} elseif { $code > 0 } {
		error $result
	}
	
	# set completion flag
	set gScan(completionState) complete
	
	return 0
}


proc restore_motor_position { motorNum } {

	# global variables
	global gScan	
	global gDevice
	
	# get motor name
	set motor $gScan($motorNum,name) 
	
	# do nothing if motor is 'time'
	if { $motor == "time" } return
	
	log_note "Moving motor $motor back to $gScan($motorNum,oldPosition) $gDevice($motor,scaledUnits)."
	move $motor to $gScan($motorNum,oldPosition) $gDevice($motor,scaledUnits)
}


proc execute_scans {} {

	# global variables
	global gScan	

	# do the appropriate type of scan
	switch $gScan(axisCount) {
		1 { scan_one_motor }
		2 { scan_two_motors }
	}
}


proc clear_scan_curves { {scans all} } {

	# global variables
	global gScan
	
	# do all curves if default argument
	if { $scans == "all" } {
		set scans $gScan(scans)
	}
	
	foreach scan $scans {
		foreach detector "$gScan(requestedDetectors) trans abs" {
	
			# handle each type of scan
			switch $gScan(axisCount) {

				1 { 
					set gScan($scan,$detector,x_curve) ""
					set gScan($scan,$detector,derivative) ""
					} 
				
				2 {
					foreach y $gScan(y_ordinates) {
						set gScan($scan,$detector,x_curve,$y) ""
					}
					foreach x $gScan(x_ordinates) {
						set gScan($scan,$detector,y_curve,$x) ""
					}
				}
			}
		}
	}
}


proc calculate_scan_ordinates {} {

	# global variables
	global gScan

	# initialize ordinate lists
	set gScan(x_ordinates) 		{}
	set gScan(y_ordinates) 		{}
	
	# determine x ordinates
	for { set point 0 } { $point < $gScan(motor1,points) } { incr point } {
		lappend gScan(x_ordinates) [expr $gScan(motor1,start) + \
		$point * $gScan(motor1,step) ]
	}

	# determine y ordinates if a two motor scan
	if { $gScan(axisCount) == 2 } {
		for { set point 0 } { $point < $gScan(motor2,points) } { incr point } {
			lappend gScan(y_ordinates) [expr $gScan(motor2,start) + \
			$point * $gScan(motor2,step) ]
		}
	} else {
		reset_zoom
	}
}


proc recalculate_min_max_counts {} {

	# global variables
	global gScan
	global gScanData

	if { $gScan(axisCount) == 1 && ! [info exists gScan(min_visible_point) ] } {
		return
	}
		
	# reset min and max counts
	set gScan(minCounts)  1000000
	set gScan(maxCounts) -1000000
	set somethingShown 0
	
	switch $gScan(axisCount) {
		1 {
				
		# loop over each scan
		foreach scan $gScan(scans) {
		
			# make sure scan is shown
			if { ! $gScan(show,$scan) } {
				continue
			}
			
			# record that at least one scan is shown
			set somethingShown 1
			
			# loop over visible points in plot
			for { set point $gScan(min_visible_point) } { $point <= $gScan(max_visible_point) } { incr point } {
				
				# get x-ordinate of next point
				set x [lindex $gScan(x_ordinates) $point ]
								
				foreach detector $gScan(requestedTraces) {
					# get counts
					if { ! [catch { set counts $gScanData($scan,$detector,$x,0) } ] } {
						
						# update max
						if { $counts > $gScan(maxCounts) } {
							set gScan(maxCounts) $counts
						}
				
						# update min
						if { $counts < $gScan(minCounts) } {
							set gScan(minCounts) $counts
						}
					}
				}		
			}
		}
	}
	
		2 {
				
		# loop over each scan
		foreach scan $gScan(scans) {
		
			# make sure scan is shown
			if { ! $gScan(show,$scan) } {
				continue
			}
			
			# record that at least one scan is shown
			set somethingShown 1
			
			# loop over visible points in plot
			foreach x $gScan(x_ordinates) {
				foreach y $gScan(y_ordinates) {
												
					foreach detector $gScan(requestedTraces) {
				
						# get counts
						if { ! [catch { set counts $gScanData($scan,$detector,$x,$y) } ] } {
							
							# update max
							if { $counts > $gScan(maxCounts) } {
								set gScan(maxCounts) $counts
							}
				
							# update min
							if { $counts < $gScan(minCounts) } {
								set gScan(minCounts) $counts
							}
						}
					}		
				}
			}
		}
	}
	}
	
	# set default min and max values if no scans shown
	if { ! $somethingShown } {
		set gScan(minCounts) 0
		set gScan(maxCounts) 10
	}	
}





proc do_scan_counting {} {

	# global variables
	global gScan	
	global gScanlog
	global gDevice
	global gScanData

	# do the counting
	eval count $gScan(scan_time) $gScan(detectors)
	eval wait_for_devices $gScan(detectors)
	
	# determine current position in scan
	set filename $gScan(filename)
	set x $gScan(motor1,position)
	set y $gScan(motor2,position)
	
	foreach detector $gScan(requestedDetectors) {

		# store the signal detector counts
		set gScanData($filename,$detector,$x,$y) [ set $detector \
			[expr double($gDevice($gScan($detector),counts)) ] ]

	}
	
	# calculate transmission and absorbance if reference requested
	if { $gScan(reference) != "none" } {
		
		if { $reference == 0 } {
			set reference 1
		}
	
		set gScanData($filename,trans,$x,$y) [expr $signal / $reference ]
		
		if { $signal == 0 } {
			set gScanData($filename,abs,$x,$y) 100
		} else {	
			set gScanData($filename,abs,$x,$y) [expr -log($gScanData($filename,trans,$x,$y)) ]
		}
	}
	
	# update the scanlog window
	add_scanlog_entry $x $y	
			
	foreach detector $gScan(requestedTraces) {

		set counts $gScanData($filename,$detector,$x,$y)
		if { $counts > $gScan(maxCounts) } {
					set gScan(maxCounts) $counts
		}
		if { $counts < $gScan(minCounts) } {
			set gScan(minCounts) $counts
		}
	
		# update the plot curves
		switch $gScan(axisCount) {
			1 { 
				if { $x >= $gScan(min_visible_x_ordinate) && $x <= $gScan(max_visible_x_ordinate) } {
					add_point_to_curves $gScan(filename) $detector $x 
				}
			}
			2 { add_point_to_curves $gScan(filename) $detector $x $y }
		}
	}
}


proc add_scanlog_entry { x y } {

	# global variables
	global gScan
	global gScanData
	global gScanlog

	# create the scan log string
	switch $gScan(type) {
		counts_vs_1_motor		{ set output [format "%14.6f" $x] }
		counts_vs_2_motors	{ set output [format "%14.6f %14.6f" $x $y] }
	}
		
	foreach detector $gScan(requestedDetectors) {
		append output [format "%9d" [expr round($gScanData($gScan(filename),$detector,$x,$y))]]
	}
	if { $gScan(reference) != "none" } {
		append output [format "    %7.4f   " $gScanData($gScan(filename),trans,$x,$y)]
		append output [format "   %7.5f" $gScanData($gScan(filename),abs,$x,$y)]
	}

	append output "\n"
	append gScanlog(data) $output
	
	# update the scanlog window if open
	if {[mdw_document_exists scanlog] } {
		write_to_scanlog $output
	}
}


proc add_point_to_curves { scan detector {arg1 0} {arg2 0} } {

	# global variables
	global gScan
	global gScanData
	global gPlot

	switch $gScan(axisCount) {
				
		1 {
				set x $arg1
				
				set result [catch {append gScan($scan,$detector,x_curve) \
				" [get_scaled_coord_2D $x $gScanData($scan,$detector,$x,0)] " } ]
				if { $result || ! $gScan(show,derivative) } {
					return $result;
				}
				
				if { $gScan($scan,$detector,derivative) == {} } {
					set gScan($scan,$detector,derivative) 1
					set gScan($scan,$detector,y0) $gScanData($scan,$detector,$x,0)
					return 0;
				}
				
				if { $gScan($scan,$detector,derivative) == "1" } {
					set gScan($scan,$detector,derivative) 2
					set gScan($scan,$detector,y1) $gScanData($scan,$detector,$x,0)
					return 0;
				}
				
				if { $gScan($scan,$detector,derivative) == "2" } {
					set gScan($scan,$detector,derivative) ""
				}

				# calculate derivative curve
				set derivative [expr ( $gScanData($scan,$detector,$x,0) - \
					$gScan($scan,$detector,y0) ) * $gScan(z_scale) / 2 ]
				set z [expr $gPlot(z_origin) - $derivative - 155 ]
				set dx [expr $gPlot(x_origin) + \
						(($x - $gScan(motor1,step)) - $gScan(min_visible_x_ordinate)) * $gScan(x_scale)]
						append gScan($scan,$detector,derivative) " $dx $z"
				set gScan($scan,$detector,y1) $gScan($scan,$detector,y0)
				set gScan($scan,$detector,y0) $gScanData($scan,$detector,$x,0)
				return 0;
		}
		
		2 {
			set x $arg1
			set y $arg2
			if { [catch {set z $gScanData($scan,$detector,$x,$y)}] } {
				return 1
			} else {
				set coordinates " [get_scaled_coord_3D $x $y $z] "
				append gScan($scan,$detector,x_curve,$y) $coordinates
				append gScan($scan,$detector,y_curve,$x) $coordinates
				return 0
			}
		}
	}
}



proc recalculate_scan_curves { scan detector } {

	# global variables
	global gScan

	switch $gScan(axisCount) {
		
		1 {
			for { set point $gScan(min_visible_point) } { $point <= $gScan(max_visible_point) } { incr point } {
				set x [lindex $gScan(x_ordinates) $point ]
				if { [add_point_to_curves $scan $detector $x] } return
			}
		}
		
		2 {
			foreach x $gScan(x_ordinates) {
				foreach y $gScan(y_ordinates) {
					if { [add_point_to_curves $scan $detector $x $y] } return
				}
			}
		}
	}
}


proc scan_one_motor {} {

	# global variables
	global gScan
	global gDevice

	set gScan(motor2,position) 0
	set gScan(scan_num) 1
	set gScan(no_points) 1
	
	# loop over x-ordinates
	foreach gScan(motor1,position) $gScan(x_ordinates) {
		
		# stop scan if so requested
		if { $gScan(requestedStop) } {
			break
		}

		if { $gScan(motor1,name) == "time" } {
		
			set time_to_wait [ expr $gScan(motor1,position) - $gDevice(time,scaled) ]
			log_note "Waiting $time_to_wait $gScan(motor1,units) for next data point..."
			wait_for_time [expr int($time_to_wait * $gScan(convert_from_$gScan(motor1,units)))]
			set gDevice(time,scaled) $gScan(motor1,position)
		
		} else {

			# move the motor to the next scan position
			move_no_parse $gScan(motor1,name) to $gScan(motor1,position) \
				$gScan(motor1,unitIndex)
			wait_for_devices $gScan(motor1,name)
			
			if { [device::$gScan(motor1,name) cget -lastResult] != "normal" } {
				set gScan(requestedStop) 1
				break
			}

			# wait for motors to settle
			wait_for_time [expr int($gScan(scan_pause) * 1000)]
			
		}
		
		# do the scan counting
		do_scan_counting
			
		# plot the counts
		plot_counts_vs_one_motor
	
		if { $gScan(motor1,end) < $gScan(motor1,start) } {
			zoom in 
			zoom out
		}
	}
}


proc scan_two_motors {} {

	# global variables
	global gScan
	global gDevice	

	draw_counts_axis
	set gScan(scan_num) 1
	set gScan(no_points) 1

	# loop over all x-ordinates (motor 1)
	foreach gScan(motor1,position) $gScan(x_ordinates) {

		# stop scan if so requested
		if { $gScan(requestedStop) } {
			break
		}
	
		if { $gScan(motor1,name) == "time" } {
		
			set time_to_wait [ expr $gScan(motor1,position) - $gDevice(time,scaled) ]
			log_note "Waiting $time_to_wait $gScan(motor1,units) for next data point..."
			wait_for_time [expr int($time_to_wait * $gScan(convert_from_$gScan(motor1,units)))]
			set gDevice(time,scaled) $gScan(motor1,position)
		
		} else {

			# move the motor to the next scan position
			move_no_parse $gScan(motor1,name) to $gScan(motor1,position) \
				$gScan(motor1,unitIndex)
			wait_for_devices $gScan(motor1,name)

			if { [device::$gScan(motor1,name) cget -lastResult] != "normal" } {
				set gScan(requestedStop) 1
				break
			}
		}

		# loop over all y-ordinates (motor 2)
		foreach gScan(motor2,position) $gScan(y_ordinates) {
			
			# move motor2 to it's next position
			move_no_parse $gScan(motor2,name) to $gScan(motor2,position) \
				$gScan(motor1,unitIndex)
			wait_for_devices $gScan(motor2,name)
			
			if { [device::$gScan(motor2,name) cget -lastResult] != "normal" } {
				set gScan(requestedStop) 1
				break
			}

			# wait for the motors to settle
			wait_for_time [expr int($gScan(scan_pause) * 1000)]
			
			# do the scan counting
			do_scan_counting
		
			# plot the counts
			plot_counts_vs_two_motors
		}
	}
}


proc pop_scan_window { args } {

	# global variables
	global gScan
	global gUserScan

	if { $gUserScan(inUse) } {
		if { $gUserScan(plotExists) } {
			return
		} else {
			construct_scan $gUserScan(plotFrame)
			set gUserScan(plotExists) 1
			return
		}
	}

	# define the scan document if it doesn't exists
	if { $gScan(standalone) } {
		if { $gScan(scansLoaded) == 1 } {
		construct_scan .
		}
	} else { 
		if { ! [mdw_document_exists scan] } {
			create_mdw_document scan "Scan" 680 520 "construct_scan" "destroy_scan"
			catch {unset gScanData}
		}
		# show the document
		show_mdw_document scan	
	}
	
	return
}


proc construct_scan { parent } {

	# global variables
	global gScan
	global gCursor
	global gDefineScan
	global gColors
	global gDevice
	global gBitmap
	global gUserScan
		
	# create the menu frame
	set menuFrame [ frame $parent.menu		\
		-height			30								\
		-borderwidth	2								\
		-relief			raised						\
		-background 	$gColors(unhighlight) ]
	pack $menuFrame -fill x

	# make the file menu
	pack [ menubutton $menuFrame.file -text "File"	\
		-menu $menuFrame.file.menu] -side left
	set menu [menu $menuFrame.file.menu -tearoff 0]

	if { ! $gScan(standalone) } {
		$menu add command -label "Stop scan" -command "end_scan"
		$menu add separator
	}
	
	if { ! $gUserScan(inUse) } {
		$menu add command -label "Load scan" -command "load_scan_dialog"
		
		if { ! $gScan(standalone) } {
			$menu add command -label "Repeat scan" -command "repeat_scan"
		}
	}

	if { ! $gUserScan(inUse) } {
		$menu add separator
	}

	$menu add command -label "Print B&W plot" -command {print_plot bw}
	$menu add command -label "Print color plot" -command {print_plot color}	

	if { ! $gUserScan(inUse) } {
		$menu add separator
	}

	if { $gScan(standalone) } {
		$menu add command -label "Exit" \
			-command "exit"
	} else {	
		if { !$gUserScan(inUse) } {
			$menu add command -label "Close window" \
				-command "destroy_mdw_document scan"
		}
	}
	
	# turn off spline fit by default
	set gScan(spline) 0

	# make the options menu
	if { ! $gUserScan(inUse) } {
		pack [ menubutton $menuFrame.options -text "Options"	\
					 -menu $menuFrame.options.menu] -side left
		set menu [menu $menuFrame.options.menu -tearoff 0]
		if { ! $gScan(standalone) } {
			$menu add command -label "Show log" -command show_scanlog
		}
		
		if { $gScan(axisCount) == 1 } {
			$menu add check -label "Spline" -variable gScan(spline) \
				-command refresh_plot
		}
		if { $gScan(axisCount) == 2 } {
			$menu add check -label "Contour along X" -variable gScan(trace_x) \
				-command refresh_plot
			$menu add check -label "Contour along Y" -variable gScan(trace_y) \
				-command refresh_plot
			set gScan(trace_x) 1
			set gScan(trace_y) 1
		}
	}
	
	# make the mode menu
	pack [ menubutton $menuFrame.mode -text "Mode"	\
				 -menu $menuFrame.mode.menu] -side left
	set menu [menu $menuFrame.mode.menu -tearoff 0]

	set gScan(z_label,signal) "Signal Counts"
	set gScan(z_label,reference) "Reference Counts"
	set gScan(z_label,signal_and_reference) "Counts"
	set gScan(z_label,transmission) "Transmission"
	set gScan(z_label,absorbance) "Absorbance"
	
	if { $gScan(reference) != "none" } {
		if { $gUserScan(inUse) } {
			if { $gUserScan(mode) == "Sample" } {
				$menu add radio -label "Flourescence Counts" -variable gScan(mode) \
					-value "signal" -command "set_scan_mode signal"
				$menu add radio -label "Reference Ion Chamber Counts" -variable gScan(mode) \
					-value "reference" -command "set_scan_mode reference"
				$menu add radio -label "Flourescence and Reference Counts" -variable gScan(mode) \
					-value "signal_and_reference" -command "set_scan_mode signal_and_reference"
				$menu add radio -label "Sample Absorbance" -variable gScan(mode) \
					-value "trans" -command "set_scan_mode trans"
				set gScan(z_label,signal) "Flourescence Counts"
				set gScan(z_label,reference) "Reference Counts"
				set gScan(z_label,signal_and_reference) "Counts"
				set gScan(z_label,transmission) "Sample Absorbance"
			} else {
				$menu add radio -label "Signal Counts, I" -variable gScan(mode) \
					-value "signal" -command "set_scan_mode signal"
				$menu add radio -label "Reference Counts, I0" -variable gScan(mode) \
					-value "reference" -command "set_scan_mode reference"
				$menu add radio -label "Signal and Reference Counts" -variable gScan(mode) \
					-value "signal_and_reference" -command "set_scan_mode signal_and_reference"
				$menu add radio -label "Foil Transmission, I / I0" -variable gScan(mode) \
					-value "trans" -command "set_scan_mode trans"
				$menu add radio -label "Foil Absorbance, -log ( I / I0 )" -variable gScan(mode) \
					-value "abs" -command "set_scan_mode abs"	
				set gScan(z_label,signal) "Signal Counts"
				set gScan(z_label,reference) "Reference Counts"
				set gScan(z_label,signal_and_reference) "Counts"
				set gScan(z_label,transmission) "Foil Transmission"
				set gScan(z_label,absorbance) "Foil Absorbance"
			}
		}  else  {
			$menu add radio -label "Signal" -variable gScan(mode) \
				-value "signal" -command "set_scan_mode signal"
			$menu add radio -label "Reference" -variable gScan(mode) \
				-value "reference" -command "set_scan_mode reference"
			$menu add radio -label "Signal and Reference" -variable gScan(mode) \
				-value "signal_and_reference" -command "set_scan_mode signal_and_reference"
			$menu add radio -label "Transmission" -variable gScan(mode) \
				-value "trans" -command "set_scan_mode trans"
			$menu add radio -label "Absorbance" -variable gScan(mode) \
				-value "abs" -command "set_scan_mode abs"
			set gScan(z_label,signal) "Signal Counts"
			set gScan(z_label,reference) "Reference Counts"
			set gScan(z_label,signal_and_reference) "Counts"
			set gScan(z_label,transmission) "Transmission"
			set gScan(z_label,absorbance) "Absorbance"
		}
	}
	
	$menu add separator
	$menu add check -label "Show Derivative" -variable gScan(show,derivative) \
		-command refresh_plot
	
	if { [llength $gScan(detectors)] > 1 } {
		set_scan_mode "signal_and_reference" 1
	} else {
		set_scan_mode "signal" 1
	}

	# make the cursor menus
	if { $gScan(axisCount) == 1 } {
		for { set num 1 } { $num <= 2 } { incr num } {
			pack [ menubutton $menuFrame.cursor$num -text "Cursor $num"	\
				-menu $menuFrame.cursor$num.menu] -side left
			set gCursor($num,menu) [ set menu [
				menu $menuFrame.cursor$num.menu -tearoff 0 ]]	
			$menu add radio -label "Hide" 	\
				-variable gCursor($num,mode) -value "hide" 	\
				-command "set_cursor_mode $num hide"
			$menu add radio -label "Crosshair"	\
				-variable gCursor($num,mode)	-value "cross" \
				-command "set_cursor_mode $num cross"
			$menu add radio -label "Horizontal Line"	\
				-variable gCursor($num,mode)	-value "horiz" \
				-command "set_cursor_mode $num horiz"
			$menu add radio -label "Vertical Line"	\
				-variable gCursor($num,mode)	-value "vert" \
				-command "set_cursor_mode $num vert"
			$menu add radio -label "Small Cross"	\
				-variable gCursor($num,mode)	-value "small" \
				-command "set_cursor_mode $num small"
		}
	}
	
	# make the show menu
	pack [ menubutton $menuFrame.show -text "Show"	\
		-menu $menuFrame.show.menu] -side left
	set gScan(showMenu) [menu $menuFrame.show.menu -tearoff 0]
	
	# make the toolbar buttons
	if { $gScan(axisCount) == 1 } {
		pack [ menubutton $menuFrame.spacer -text "      " ] -side right
		pack [set toolbarFrame [ frame $menuFrame.toolbarFrame \
			-height 30 -bg $gColors(unhighlight)]] -side right
		pack [set gScan(zoomInButton) [button $toolbarFrame.zoomInButton \
			-command "zoom in" -state disabled -image $gBitmap(zoomin) \
			-width 19 -height 19]] -side left -pady 2 -padx 1
		pack [set gScan(zoomOutButton) [button $toolbarFrame.zoomOutButton \
			-command "zoom out" -state disabled -image $gBitmap(zoomout) \
			-width 19 -height 19]] -side left -pady 2 -padx 1
		pack [set gScan(zoomRestoreButton) [button $toolbarFrame.zoomRestoreButton \
			-command "zoom restore" -state disabled -image $gBitmap(zoomrestore) \
			-width 19 -height 19]] -side left -pady 2 -padx 1
		pack [set gScan(zoomLeftButton) [button $toolbarFrame.zoomLeftButton \
			-command "zoom left" -state disabled -image $gBitmap(zoomleft) \
			-width 19 -height 19]] -side left -pady 2 -padx 1
		pack [set gScan(zoomRightButton) [button $toolbarFrame.zoomRightButton \
			-command "zoom right" -state disabled -image $gBitmap(zoomright) \
			-width 19 -height 19]] -side left -pady 2 -padx 1	
		if { ! $gScan(standalone) } {
			pack [set gScan(stopScanButton) [button $toolbarFrame.stopScanButton \
				-command "do end_scan" -state normal -image $gBitmap(stop) \
				-width 19 -height 19]] -side left -pady 2 -padx 1	
		}
	}
		
	# enable zoom in button
	if { $gScan(axisCount) == 1 } {
		$gScan(zoomInButton) configure -state normal
	}

	# create the plotting canvas 
	if { $gUserScan(inUse) } {
		pack [set gScan(canvas) [	\
			canvas $parent.canvas -background black -width 660 -height 453 \
			-scrollregion {0 0 600 800} ] ] -expand true -fill both 
		$gScan(canvas) yview moveto 100.00
	} else {
		pack [set gScan(canvas) [	\
			canvas $parent.canvas -background black -width 600 -height 400 \
			-scrollregion {0 0 600 800}] ] -expand true -fill both 
		$gScan(canvas) yview moveto 1.00
	}
	# draw the axes
	switch $gScan(type) {
		counts_vs_time { 
			initialize_2D_plot \
				0 [expr $gScan(scan_period) * ($gScan(scan_count) -1)] \
				"Time (minutes)" "Counts"
		draw_counts_axis
 		}
		counts_vs_1_motor		{ 			
			initialize_2D_plot \
				$gScan(motor1,start) $gScan(motor1,end) \
				"$gScan(motor1,name) ($gScan(motor1,units))" "Counts"
		draw_counts_axis
 		}
		counts_vs_2_motors	{ initialize_3D_plot  \
				$gScan(motor1,start) $gScan(motor1,end) \
				"$gScan(motor1,name) ($gScan(motor1,units))"	\
				$gScan(motor2,start) $gScan(motor2,end) \
				"$gScan(motor2,name) ($gScan(motor2,units))"	\
				"Counts" }
	}
	
	# write current positions of all motors to canvas
	if { ! $gScan(standalone) && ! $gUserScan(inUse) } {
		set legend_x 	-10
		set legend_y 	250
		set step_x		140
		set step_y		7
		foreach motor $gDevice(motor_list) {
			set legend [format "%-18s %10.3f %s" \
				$motor $gDevice($motor,scaled) $gDevice($motor,scaledUnits)]
			$gScan(canvas) create text \
				$legend_x $legend_y		\
				-text $legend				\
				-fill white -anchor nw -font "courier 6"
			incr legend_y $step_y
			if { $legend_y > 334 } {
				set legend_y 250
				incr legend_x $step_x
			}
		}
	}
	
	# set up the canvas for analysis
	initialize_canvas_bindings
}

proc set_scan_mode { mode {norefresh 0} } {

	# global variables
	global gScan
	global gUserScan

	if { $mode == "next" } {
		switch $gScan(mode) {
			signal 					{ set gScan(mode) "reference" }
			reference 				{ set gScan(mode) "signal_and_reference" }
			signal_and_reference { set gScan(mode) "trans" }
			trans	 					{ set gScan(mode) "abs" }			
			abs 						{ set gScan(mode) "signal" }
		}
		if { $gScan(mode) == "abs" && $gUserScan(inUse) && $gUserScan(mode) == "Sample" } {
			set gScan(mode) "signal"
		}
	} else {
		set gScan(mode) $mode
	}
	
	switch $gScan(mode) {
		signal { 
			catch {
				$gScan(canvas) delete "reference" 
				$gScan(canvas) delete "abs"
				$gScan(canvas) delete "trans"
			}
			set z_label $gScan(z_label,signal)
			set gScan(requestedTraces) signal
		}
		reference { 
			catch {
				$gScan(canvas) delete "signal" 
				$gScan(canvas) delete "abs"
				$gScan(canvas) delete "trans"
			}
			set z_label $gScan(z_label,reference)
			set gScan(requestedTraces) reference
		}
		signal_and_reference {
			catch {
				$gScan(canvas) delete "trans"
				$gScan(canvas) delete "abs"
			}
			set z_label $gScan(z_label,signal_and_reference)
			set gScan(requestedTraces) {signal reference}
		}
		trans {
			catch {
				$gScan(canvas) delete "signal" 
				$gScan(canvas) delete "reference" 
				$gScan(canvas) delete "abs"
			}
			set z_label $gScan(z_label,transmission)
			set gScan(requestedTraces) trans
		}			
		abs {
			catch {
				$gScan(canvas) delete "signal" 
				$gScan(canvas) delete "reference" 
				$gScan(canvas) delete "trans"
			}
			set z_label $gScan(z_label,absorbance)
			set gScan(requestedTraces) abs
		}			
	}

	if { ! $norefresh } {
		refresh_plot
		set_z_label $z_label
	}
}



proc destroy_scan {} {

	# global variables
	global gScan
	global gScanData
	
	# end scan if active
	if { $gScan(status) != "inactive" } {
		end_scan
	}
	
	set gScan(scansLoaded) 0
	set gScan(scans) {}
	catch {unset gScanData}
}


proc end_scan {} {

	# global variables
	global gScan	
	
	log_warning "Stopping scan..."
	set gScan(requestedStop) 1
}


proc count { time args } {
	
	# global variables
	global gDevice

	# first check that each device is an ion chamber
	foreach device $args {
		if { ! [isDeviceType ion_chamber $device] } {
			log_error "Device $device is not an ion chamber!"
			return -1;
		}
	}
	
	# next set the status of each device to counting
	foreach device $args {
		set gDevice($device,status) counting
	}
	
	# finally send the message to the server
	dcss sendMessage "gtos_read_ion_chambers $time 0 $args"
}


proc add_scan_legend { scan } {

	# global variables
	global gScan
	global gPlot
	
	set scanNum $gScan($gScan(filename),scanIndex)

	catch { $gScan(canvas) delete $gPlot(title) }
	
	set gPlot(title) [ \
		$gScan(canvas) create text \
		150 355 -fill white -text "[format "%15s" $gScan(filename)]         [time_stamp]" \
		-anchor nw -font $gPlot(bigLegendFont) ]

	$gScan(showMenu) add check -label $scan -variable gScan(show,$scan) \
		-command "update_scan_legend_color $scan; refresh_plot"

	set gPlot(scanLegend,$scanNum) [ \
		$gScan(canvas) create text \
		$gPlot(legend_x) [expr $scanNum * 15 + 600 ] \
		-fill $gPlot(color,$scanNum) 	\
													-text "[format "%15s" [file rootname [file tail $scan]]]" \
		-anchor w -font $gPlot(smallLegendFont) ]

	$gScan(canvas) bind $gPlot(scanLegend,$scanNum) <Button-1> "toggle_scan $scan"
}


proc update_scan_legend_color { scan } {

	# global variables
	global gScan
	global gPlot
	global gColors
	
	set scanNum $gScan($scan,scanIndex)
	
	if { $gScan(show,$scan) } {
		$gScan(canvas) itemconfigure $gPlot(scanLegend,$scanNum) -fill $gPlot(color,$scanNum)
	} else {
		$gScan(canvas) itemconfigure $gPlot(scanLegend,$scanNum) -fill $gColors(verydark)
	}	
}

proc toggle_scan { scan } {

	# global variables
	global gScan

	if { $gScan(show,$scan) } {
		hide_scan $scan
	} else {
		show_scan $scan
	}
}

proc hide_scan { scan } {

	# global variables
	global gScan

	set gScan(show,$scan) 0
		
	update_scan_legend_color $scan
	refresh_plot
}


proc show_scan { scan } {

	# global variables
	global gScan

	set gScan(show,$scan) 1
		
	update_scan_legend_color $scan
	refresh_plot
}


proc get_next_scan_filenum {} {

	# global variables
	global gScan

	# find next available file number	
	for { set num $gScan(file_num) } { 1 } { incr num } {
		set filename "$gScan(file_root)_[format "%03d" $num].scan"
		if { ! [file exists $filename] } {
			break
		}
	}
	set gScan(file_num) $num
}



proc maximize { motor detector points step time } {

	# global variables
	global gDevice
	
	# make sure we are master
	if { ! [dcss is_master] } {
		log_error "This client is not the master.  Scans are not allowed."
		return
	} 

	log_note "Maximizing $detector using $motor."

	# open shutter if necessary
	if { $gDevice($detector,afterShutter) && $gDevice(shutter,state) == "closed" } {
		open_shutter shutter
		set close_shutter_when_done 1	
	} else {
		set close_shutter_when_done 0
	}

	# do the scans and catch errors
	set code [catch {execute_maximization $motor $detector $points $step $time} result]

	# close shutter if necessary
	if { $close_shutter_when_done && $gDevice(shutter,state) == "open" } {
		close_shutter shutter
	}

	log_note "Maximization complete."
	
	# return an error if appropriate
	if { $code == 5 } {
		return -code 5
	} elseif { $code > 0 } {
		error $result
	}
}


proc execute_maximization { motor detector points step time } {

	# global variables
	global gDevice

	# initialize arrays
	set positions {}
	set counts {}

	# store old position
	set oldPosition $gDevice($motor,scaled)

	# move motor to starting position
	set start [expr $gDevice($motor,scaled) - $points * $step / 2.0]
	move_no_parse $motor to $start 0

	# wait for ion chamber to become inactive and motor to reach start position
	wait_for_devices $motor $detector
	
	# loop over points
	for { set point 0 } { $point < $points } { incr point } {
		
		# move motor to next position
		set position  [expr $start + $point * $step]
		move_no_parse $motor to $position 0
		wait_for_devices $motor

		# count on ion chamber
		count $time $detector
		wait_for_devices $detector

		# store position and ion chamber reading in arrays
		lappend positions $position
		lappend counts $gDevice($detector,counts)
	}


#	log_note $positions
#	log_note $counts

	if { ! [check_sanity $points $positions $counts] } {
		move_no_parse $motor to $oldPosition 0
		wait_for_devices $motor
		log_error "Insufficient counts."
		return
		}

	set result [cal_find_peak $points $positions $counts]
	if { $result == "error" } {
		log_error "Error maximizing counts."
		return
	}
	
	# move motor to optimal position
	log_note "Optimal value = [lindex $result 0]"
	move_no_parse $motor to [lindex $result 0] 0
	wait_for_devices $motor

	# write optimized position to log 
   #set handle [open /usr/local/dcs/blu-ice/tmp/optimize.log a]	
	#puts $handle "[time_stamp] Maximizing: $motor"
	#puts $handle "$positions"
	#puts $handle "$counts"
	#puts $handle "$gDevice(table_vert,scaled) $gDevice(energy,scaled) $gDevice(detector_z,scaled)"
	#puts $handle ""
	#close $handle
 
}


proc check_sanity { points positions counts } {

	set max 0
	set min 0

	for { set i 0 } { $i < $points } { incr i } {
		
		set value [lindex $counts $i]
		
		if { $value < $min } {
			set min $value
		}
				
		if { $value > $max } {
			set max $value
		}		
	}
	
	log_note "Min = $min"
	log_note "Max = $max"
	
	return [expr ($max - $min) > 100]
}

