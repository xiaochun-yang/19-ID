proc VIRTUAL_initialize {} {
	set_children VIRTUAL_real

    namespace eval PRIVATE_VIRTUAL {
        variable tolerance
        set tolerance 1.0
        if {![::config get VIRTUAL.tolerance tolerance]} {
            set tolerance -1.0
        }
        namespace export tolerance
    }
}
proc VIRTUAL_move { new_position } {
	global gDevice
    variable VIRTUAL_real
    variable PRIVATE_VIRTUAL::tolerance

	if {$tolerance > 0} {
        ####check with encoder to see if ok to move
        
        #####DO NOT call these.
        ### this will block current motor if more than 1 motors are
        ### being moved in the same time, like table_vert....
        ### we just use the last result
	    #get_encoder VIRTUAL_encoder
	    #wait_for_encoder VIRTUAL_encoder
	
	    set delta [expr $gDevice(VIRTUAL_encoder,position) - $VIRTUAL_real]

        ####DEBUG log
        catch {
            set ts [clock format [clock seconds] -format "%D-%T"]
            set contents [list $ts start VIRTUAL at $VIRTUAL_real diff: $delta]
            set ch [open VIRTUAL_laserCheck.log a]
            puts $ch $contents
            close $ch
        }

	    if {abs($delta) > $tolerance} {
		    log_warning VIRTUAL is at $VIRTUAL_real, encoder is at $gDevice(VIRTUAL_encoder,position) mm
		    log_warning VIRTUAL differs by too much ($delta mm)

            ####just log, will return error after we feel comfort with this
            #### new device
		    #return -code error "VIRTUAL_encoder_differs_by_too_much"
	    }
    }
	# move detector_z motor
	move VIRTUAL_real to $new_position

	# wait for the move to complete
	if { [catch { wait_for_devices VIRTUAL_real } errorResult] } {
		after 200
	}

	if {$tolerance > 0} {
        ####check again after move
        if {[catch {
	        get_encoder VIRTUAL_encoder
	        wait_for_encoder VIRTUAL_encoder
        } errMsg]} {
            log_warning $errMsg
            ###skip check if call failed
            return
        }
	
	    set delta [expr $gDevice(VIRTUAL_encoder,position) - $VIRTUAL_real]

        ####DEBUG log
        catch {
            set ts [clock format [clock seconds] -format "%D-%T"]
            set contents [list $ts end VIRTUAL at $VIRTUAL_real diff: $delta]
            set ch [open VIRTUAL_laserCheck.log a]
            puts $ch $contents
            close $ch
        }

	    if {abs($delta) > $tolerance} {
		    log_warning VIRTUAL stalled. Actual position is $gDevice(VIRTUAL_encoder,position) mm.
		    #return -code error "encoder"
	    }
    }
}

proc VIRTUAL_set { new_position } {
	variable VIRTUAL_real

	#set the encoder value.
	set_encoder VIRTUAL_encoder $new_position
	wait_for_encoder VIRTUAL_encoder

	set VIRTUAL_real $new_position
}

proc VIRTUAL_update {} {
	variable VIRTUAL_real

	return $VIRTUAL_real
}


proc VIRTUAL_calculate { dz } {
	return $dz
}
