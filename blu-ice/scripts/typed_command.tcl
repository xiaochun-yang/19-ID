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


proc log_to_file { string } {

	if { [dcss is_master] } {
		print $string
	}
}


proc log_string { string type } {

	# global variables
	global gWindows
	
	# enable modification of text window
	$gWindows(text,text) configure -state normal	


	set time [time_stamp]
	$gWindows(text,text) insert end "\n$time  " output
	$gWindows(text,text) insert end "$string" $type
	
	log_to_file "$time  $string"
	
	# disable modification of text window
	$gWindows(text,text) configure -state disabled
		
	# scroll window to show results
	$gWindows(text,text) see end
}

proc log { args } { log_string "[join $args]" output }
proc log_command { args } { log_string "[join $args]" input }
proc log_error { args } { log_string "ERROR: [join $args]" error }
proc log_warning { args } { log_string "WARNING: [join $args]" warning }
proc log_note { args } { log_string "NOTE: [join $args]" note }



proc do { args } {

	# global variables
	global gWindows
	global errorInfo
		
	# concatenate arguments to create the command
	set command [join $args]
		
	# echo the command
	log_command $command
	
	# execute the command at the global level and catch errors
	set code [ catch {uplevel #0 $command} result ] 

	# add command to history list
	add_history $command
	
	# return an error if 
	if { $code == 5 } {
		log_error "Command interrupted."
		return -code error
	} elseif { $code != 0 } {
		log_error "$result"
	}
}	


proc do_command { args } {

	catch { eval "do $args" }
}


proc do_typed_command {} {
	
	# global variables
	global gWindows
	
	# carry out typed command
	catch { do_script $gWindows(command,command) }
	
	# clear the command entry window
	set gWindows(command,command) ""
}


proc initialize_history {} {

	# global variables
	global history
	
	set history(max)			 100
	set history(head)				0
	set history(tail)				0
	set history(current)			0
}


proc add_history {command} {

	# global variables
	global history

	set history(command,$history(head)) $command	
	set history(head) [history_next $history(head)]
	set history(current) $history(head)
	if { $history(head) == $history(tail) } {
		set history(tail) [history_next $history(tail)]
	}
}


proc do_history_up {} {

	global history
	global gWindows

	if { $history(current) == -1 } {
		set history(current) $history(head)
	}
	
	if { $history(current) != $history(tail) } {
		set history(current) [history_prev $history(current)]
		set gWindows(command,command) $history(command,$history(current))
		$gWindows(command,entry) icursor end
	}
}
	

proc do_history_down {} {

	global history
	global gWindows


	if { $history(current) == -1 } return
	
	if { $history(current) != [history_prev $history(head)] } {
		set history(current) [history_next $history(current)] 	
		set gWindows(command,command) $history(command,$history(current))
		$gWindows(command,entry) icursor end
	} else {
		set gWindows(command,command) ""
		set history(current) -1
	}
}
		
	
proc history_prev { index } {
	
	global history

	expr (($index - 1) % $history(max))
	
}
	
	
proc history_next { index } {

	global history
	
	expr (($index + 1) % $history(max))
	
}
	

proc script { filename } {
	
	catch [source $filename]
	log_note "Script $filename completed."
}


proc do_script { args } {

	# global variables
	global gWindows
	global errorInfo
		
	# concatenate arguments to create the command
	set command [join $args]
		
	# echo the command
	log_command $command
	
	# execute the command at the global level and catch errors
	set code [ catch {namespace eval nScripts $command} result ] 

	# add command to history list
	add_history $command
	
	# return an error if 
	if { $code == 5 } {
		log_error "Command interrupted."
		return -code error
	} elseif { $code != 0 } {
		log_error "$result"
	}
}	


