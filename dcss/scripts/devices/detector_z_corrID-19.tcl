# detector_z_corr.tcl


proc detector_z_corr_initialize {} {

	# specify children devices
	set_children detector_z
}


proc detector_z_corr_move { new_detector_z_corr } {

	# global variables
	variable detector_z
	global gDevice
#::dcss2 sendMessage "htos_note yangx encoder database value = $gDevice(detector_z_encoder,databasePosition) "
#::dcss2 sendMessage "htos_note yangx encoder controller     = $gDevice(detector_z_encoder,controllerPosition) "
	#this statement should only be true on start up of dhs and motors have moved, or galil has been reset.
	if { $gDevice(detector_z_encoder,databasePosition) != $gDevice(detector_z_encoder,controllerPosition) } {
		if { $gDevice(detector_z_encoder,controllerPosition) > .5 } {
			::dcss2 sendMessage "htos_note detector_z encoder movement occurred while dhs was offline"
			#handle case where movement has occured while dhs was offline
			set_encoder detector_z_encoder $gDevice(detector_z_encoder,controllerPosition)
			catch {wait_for_encoder detector_z_encoder}
		} else {
			#handle case where controller was reset
			::dcss2 sendMessage "htos_note detector_z encoder controller was reset during during shutdown of dhs"
			set_encoder detector_z_encoder $gDevice(detector_z_encoder,databasePosition)
			catch {wait_for_encoder detector_z_encoder}
		}
		
		#forget the discrepancy in the detector_z_encoder
		set $gDevice(detector_z_encoder,databasePosition) 0
		set $gDevice(detector_z_encoder,controllerPosition) 0
	}


	#before we move the motor, check encoder sanity by first comparing the encoder to the expected position
	get_encoder detector_z_encoder
	wait_for_encoder detector_z_encoder
::dcss2 sendMessage "htos_note yangx encoder value    = $gDevice(detector_z_encoder,position) "
::dcss2 sendMessage "htos_note yangx detector_z value = $detector_z "
	#calculate how far off the encoder is
	set delta [expr $gDevice(detector_z_encoder,position) - $detector_z]

	#if the difference is greater than 2 cm
	if { abs($delta) > 2.0 } {
		#unfortunately we need human intervention at this point
		::dcss2 sendMessage "htos_note detector_z is at $detector_z, encoder is at $gDevice(detector_z_encoder,position) mm"
		::dcss2 sendMessage "htos_note detector_z differs by too much ($delta mm)"
		return -code error "detector_z_encoder differs by too much"
	} elseif { abs( $delta ) > 0.01  } {
		::dcss2 sendMessage "htos_note detector_z corrected to $gDevice(detector_z_encoder,position) mm, change of $delta mm."
		#reset the detector_z position
		set detector_z $gDevice(detector_z_encoder,position)
	}

        set old_z $detector_z
	# move detector_z motor

	move detector_z to $new_detector_z_corr

	# wait for the move to complete
	if { [catch { wait_for_devices detector_z } errorResult] } {
		#wait for detector_z to slide a little
		after 200
		#poll the encoder
		get_encoder detector_z_encoder
		wait_for_encoder detector_z_encoder
		
::dcss2 sendMessage "htos_note yangx after move detector_encoder= $gDevice(detector_z_encoder,position) "
		#calculate how far off the encoder is
		set delta [expr $gDevice(detector_z_encoder,position) - $detector_z]
::dcss2 sendMessage "htos_note yangx after move the deferrnce = $delta "
		#if the difference is significant
		if { abs($delta) > 0.01 } {
			::dcss2 sendMessage "htos_note detector_z corrected to $gDevice(detector_z_encoder,position) mm, change of $delta mm."
			#reset the detector_z position
			set detector_z $gDevice(detector_z_encoder,position)
		}
        catch {
            if {[isString detector_z_accumulate]} {
                variable detector_z_accumulate
                set distance [expr abs($detector_z - $old_z)]
                set detector_z_accumulate [expr $detector_z_accumulate + $distance]
            }
        }

		return -code error $errorResult
	}
    catch {
        if {[isString detector_z_accumulate]} {
            variable detector_z_accumulate
            set distance [expr abs($detector_z - $old_z)]
            set detector_z_accumulate [expr $detector_z_accumulate + $distance]
        }
    }

	#poll the encoder
	get_encoder detector_z_encoder
	wait_for_encoder detector_z_encoder
		
	#calculate how far off the encoder is
	set delta [expr $gDevice(detector_z_encoder,position) - $detector_z]
		
	#if the difference is significant
	if { abs($delta) > 1.0 } {
		::dcss2 sendMessage "htos_note detector_z stalled. Actual position is $gDevice(detector_z_encoder,position) mm."
		return -code error "encoder"
	}

	if { abs($delta) > 0.01 } {
		::dcss2 sendMessage "htos_note detector_z corrected to $gDevice(detector_z_encoder,position) mm, change of $delta mm."
		#reset the detector_z position
		set detector_z $gDevice(detector_z_encoder,position)
	}
    	#correctTableSlide_start
}


proc detector_z_corr_set { new_detector_z_corr } {

	# global variables
	variable detector_z

	set detector_z $new_detector_z_corr
	
	#set the encoder value.
	set_encoder detector_z_encoder $new_detector_z_corr
	wait_for_encoder detector_z_encoder
}


proc detector_z_corr_update {} {

	# global variables
	variable detector_z

	return $detector_z
}


proc detector_z_corr_calculate { dz } {
	
	return $dz
}
