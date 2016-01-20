# mirror_horz.tcl


proc mirror_horz_initialize {} {

	# specify children devices
	set_children mirror_horz_motor
}


proc mirror_horz_move { new_mirror_horz } {

	# global variables
	variable mirror_horz_motor
	global gDevice
#::dcss2 sendMessage "htos_note yangx encoder database value = $gDevice(mirror_horz_motor_encoder,databasePosition) "
#::dcss2 sendMessage "htos_note yangx encoder controller     = $gDevice(mirror_horz_motor_encoder,controllerPosition) "
	#this statement should only be true on start up of dhs and motors have moved, or galil has been reset.
	if { $gDevice(mirror_horz_motor_encoder,databasePosition) != $gDevice(mirror_horz_motor_encoder,controllerPosition) } {
		if { $gDevice(mirror_horz_motor_encoder,controllerPosition) > .5 } {
			::dcss2 sendMessage "htos_note mirror_horz_motor encoder movement occurred while dhs was offline"
			#handle case where movement has occured while dhs was offline
			set_encoder mirror_horz_motor_encoder $gDevice(mirror_horz_motor_encoder,controllerPosition)
			catch {wait_for_encoder mirror_horz_motor_encoder}
		} else {
			#handle case where controller was reset
			::dcss2 sendMessage "htos_note mirror_horz_motor encoder controller was reset during during shutdown of dhs"
			set_encoder mirror_horz_motor_encoder $gDevice(mirror_horz_motor_encoder,databasePosition)
			catch {wait_for_encoder mirror_horz_motor_encoder}
		}
		
		#forget the discrepancy in the mirror_horz_motor_encoder
		set $gDevice(mirror_horz_motor_encoder,databasePosition) 0
		set $gDevice(mirror_horz_motor_encoder,controllerPosition) 0
	}


	#before we move the motor, check encoder sanity by first comparing the encoder to the expected position
	get_encoder mirror_horz_motor_encoder
	wait_for_encoder mirror_horz_motor_encoder
::dcss2 sendMessage "htos_note yangx encoder value    = $gDevice(mirror_horz_motor_encoder,position) "
::dcss2 sendMessage "htos_note yangx mirror_horz_motor value = $mirror_horz_motor "
	#calculate how far off the encoder is
	set delta [expr $gDevice(mirror_horz_motor_encoder,position) - $mirror_horz_motor]

	#if the difference is greater than 2 cm
	if { abs($delta) > 2.0 } {
		#unfortunately we need human intervention at this point
		::dcss2 sendMessage "htos_note mirror_horz_motor is at $mirror_horz_motor, encoder is at $gDevice(mirror_horz_motor_encoder,position) mm"
		::dcss2 sendMessage "htos_note mirror_horz_motor differs by too much ($delta mm)"
		return -code error "mirror_horz_motor_encoder differs by too much"
	} elseif { abs( $delta ) > 0.01  } {
		::dcss2 sendMessage "htos_note mirror_horz_motor corrected to $gDevice(mirror_horz_motor_encoder,position) mm, change of $delta mm."
		#reset the mirror_horz_motor position
		set mirror_horz_motor $gDevice(mirror_horz_motor_encoder,position)
	}

        set old_z $mirror_horz_motor
	# move mirror_horz_motor motor

	move mirror_horz_motor to $new_mirror_horz

	# wait for the move to complete
	if { [catch { wait_for_devices mirror_horz_motor } errorResult] } {
		#wait for mirror_horz_motor to slide a little
		after 200
		#poll the encoder
		get_encoder mirror_horz_motor_encoder
		wait_for_encoder mirror_horz_motor_encoder
		
::dcss2 sendMessage "htos_note yangx after move detector_encoder= $gDevice(mirror_horz_motor_encoder,position) "
		#calculate how far off the encoder is
		set delta [expr $gDevice(mirror_horz_motor_encoder,position) - $mirror_horz_motor]
::dcss2 sendMessage "htos_note yangx after move the deferrnce = $delta "
		#if the difference is significant
		if { abs($delta) > 0.01 } {
			::dcss2 sendMessage "htos_note mirror_horz_motor corrected to $gDevice(mirror_horz_motor_encoder,position) mm, change of $delta mm."
			#reset the mirror_horz_motor position
			set mirror_horz_motor $gDevice(mirror_horz_motor_encoder,position)
		}
        catch {
            if {[isString mirror_horz_motor_accumulate]} {
                variable mirror_horz_motor_accumulate
                set distance [expr abs($mirror_horz_motor - $old_z)]
                set mirror_horz_motor_accumulate [expr $mirror_horz_motor_accumulate + $distance]
            }
        }

		return -code error $errorResult
	}
    catch {
        if {[isString mirror_horz_motor_accumulate]} {
            variable mirror_horz_motor_accumulate
            set distance [expr abs($mirror_horz_motor - $old_z)]
            set mirror_horz_motor_accumulate [expr $mirror_horz_motor_accumulate + $distance]
        }
    }

	#poll the encoder
	get_encoder mirror_horz_motor_encoder
	wait_for_encoder mirror_horz_motor_encoder
		
::dcss2 sendMessage "htos_note yangx after move mirroe_encoder= $gDevice(mirror_horz_motor_encoder,position) "

::dcss2 sendMessage "htos_note yangx after move mirror motor = $mirror_horz_motor "
	#calculate how far off the encoder is
	set delta [expr $gDevice(mirror_horz_motor_encoder,position) - $mirror_horz_motor]
		
::dcss2 sendMessage "htos_note yangx after move the deferrnce = $delta "
	#if the difference is significant
	if { abs($delta) > 1.0 } {
		::dcss2 sendMessage "htos_note mirror_horz_motor stalled. Actual position is $gDevice(mirror_horz_motor_encoder,position) mm."
		return -code error "encoder"
	}

	if { abs($delta) > 0.01 } {
		::dcss2 sendMessage "htos_note mirror_horz_motor corrected to $gDevice(mirror_horz_motor_encoder,position) mm, change of $delta mm."
		#reset the mirror_horz_motor position
		set mirror_horz_motor $gDevice(mirror_horz_motor_encoder,position)
	}
    	#correctTableSlide_start
}


proc mirror_horz_set { new_mirror_horz } {

	# global variables
	variable mirror_horz_motor

	set mirror_horz_motor $new_mirror_horz
	
	#set the encoder value.
	set_encoder mirror_horz_motor_encoder $new_mirror_horz
	wait_for_encoder mirror_horz_motor_encoder
}


proc mirror_horz_update {} {

	# global variables
	variable mirror_horz_motor

	return $mirror_horz_motor
}


proc mirror_horz_calculate { dz } {
	
	return $dz
}
