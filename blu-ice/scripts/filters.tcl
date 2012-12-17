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



proc toggle_shutter { shutter } {

	# global variables
	global gDevice

	# check if filter exists
	if {! [info exists gDevice($shutter,state)] } {
		log_error "No such filter $filter."
		return	
	}
	
	# make sure this client is the master
	if { ! [dcss is_master] } {
		log_error "This client is not the master.  Filters may not\
		be inserted or removed."
		return
	}

	# insert or remove filter depending on current state
	if { $gDevice($shutter,state) == "closed" } {	
		do open_shutter $shutter
	} else {
		do close_shutter $shutter
	}
}



proc open_shutter { shutter { time 0 } } {

	# global variables
	global gDevice
	
	dcss sendMessage "gtos_set_shutter_state $shutter open"	

	if { $time != 0 } {
		wait_for_time [expr int($time * 1000)]
		close_shutter $shutter
	}
}

proc o { args } { eval "open_shutter $args" }

proc close_shutter { shutter } {

	# global variables
	global gDevice
	
	dcss sendMessage "gtos_set_shutter_state $shutter closed"	
}



proc set_filter_states { new_state } {

	# global variables
	global gDevice
	
	# initialize previous state
	set prev_state ""
	
	foreach filter $gDevice(foil_list) {
		if { $gDevice($filter,state) == "closed" } {
			lappend prev_state $filter
			if { [lsearch $new_state $filter] == -1 } {
				log_note "Removing $filter..."
				open_shutter $filter
			}
		} else {
			if { [lsearch $new_state $filter] != -1 } {
				log_note "Inserting $filter..."
				close_shutter $filter
			}
		}		 
	}
	
	# return the previous state
	return $prev_state
}

	
	

proc set_filter_state { filter state } {

	#global variables
	global gDevice

	# check if filter exists
	if {! [info exists gDevice($filter,state)] } {
		log_error "No such filter $filter."
		return	
	}
	
	# make sure this client is the master
	if { ! [dcss is_master] } {
		log_error "This client is not the master.  Filters may not\
		be inserted or removed."
		return
	}
	
	# set status of filter appropriately 
	if { $state == "closed" } {
		set gDevice($filter,status) "closing"
		dcss sendMessage "gtos_set_shutter_state $filter closed"
	} else {
		set gDevice($filter,status) "opening"
		dcss sendMessage "gtos_set_shutter_state $filter open"
	}
}


proc insert_filter { filter } {
	set_filter_state $filter closed
}

proc remove_filter { filter } {
	set_filter_state $filter open
}


proc update_shutter_menu {} {

	# global variables
	global gDevice
	global gMenu
	global gWindows
	
	if { $gDevice(shutter,state) == "closed" } {
		$gMenu(shutter) entryconfigure 1 -state disabled
		$gMenu(shutter) entryconfigure 0 -state normal
		set gDevice(shutterStatusText) "Closed"
		$gWindows(shutterStatus) configure -fg black
	} else {
		$gMenu(shutter) entryconfigure 0 -state disabled
		$gMenu(shutter) entryconfigure 1 -state normal	
		set gDevice(shutterStatusText) "Open"
		$gWindows(shutterStatus) configure -fg red
	}
}


# shortcuts for insert_filter remove_filter command
proc i 		{ filter } { close_shutter $filter }
proc insert { filter } { close_shutter $filter }
proc r 		{ filter } { open_shutter $filter }
proc remove { filter } { open_shutter $filter }
