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


proc show_scanlog {} {

	# global variables
	global gScan
	global gScanlog

	# create the scanlog window if not around
	if { ![mdw_document_exists scanlog] } {
		
		# create the header
		switch $gScan(type) {
			counts_vs_time 		{ 
				set header "        time  " }
			counts_vs_1_motor		{ 
				set header [format "  %10s  " [get_motor_abbrev $gScan(motor1,name)] ] }
			counts_vs_2_motors	{ 
				set header [format "  %10s     %10s  " [get_motor_abbrev $gScan(motor1,name)] \
					[get_motor_abbrev $gScan(motor2,name)] ] }
		}
		foreach detector $gScan(detectors) {
			append header [format "  %6s " $detector]		
		}
		
		if { $gScan(reference) != "none" } {
			append header "  Transmission  Absorbance"
		}

		# bring up the scan log window
		pop_scanlog_window $header

		# write current data to scanlog
		write_to_scanlog $gScanlog(data)
				
	} else {
	
		# show the document
		show_mdw_document scanlog
	}
}


proc pop_scanlog_window { header args } {

	# destroy the scanlog document if it already exists
	if {[mdw_document_exists scanlog] } {
		destroy_mdw_document scanlog	
	}
			
	set headerWidth [expr [ font measure "courier 10 bold" $header ] + 50]
	log_note $header
	
	create_mdw_document scanlog "Scan Log" $headerWidth 300 \
		[list construct_scanlog $header] "destroy_scanlog"
	
	# show the document
	show_mdw_document scanlog

	return
}



proc construct_scanlog { header parent } {

	# global variables
	global gScanlog
	global gColors
	
	pack [frame $parent.headerFrame \
		-relief sunken -borderwidth 2] -side top -expand true -fill both
	pack [ set gScanlog(label) [ label $parent.headerFrame.label 	\
		-text $header -font "courier 10 bold"  	\
		-background $gColors(unhighlight) -anchor w] ] 	\
		-expand true -fill both -side left
	
	# create the scrolled text region
	pack [frame $parent.textFrame -relief sunken -borderwidth 2] \
		-side top -expand true -fill both
	set gScanlog(window) [scrolledText $parent.textFrame.text \
		-relief sunken -background $gColors(light) -font "courier 10 bold" -state disabled ]
}


proc clear_scanlog {} {

	# global variables
	global gScanlog
	
	# clear scan log data
	set gScanlog(data) {}

	catch {
	# enable modification of text window
	$gScanlog(window) configure -state normal

	# delete everything in it
	$gScanlog(window) delete 1.0 end	

	# disable modification of text window
	$gScanlog(window) configure -state disabled
		
	# scroll window to show results
	$gScanlog(window) see end
	}
}


proc write_to_scanlog { string } {

	# global variables
	global gScanlog
	
	# enable modification of text window
	$gScanlog(window) configure -state normal
	
	# write the string	
	$gScanlog(window) insert end "$string"
	
	# disable modification of text window
	$gScanlog(window) configure -state disabled
		
	# scroll window to show results
	$gScanlog(window) see end
}


proc destroy_scanlog {} {
}
