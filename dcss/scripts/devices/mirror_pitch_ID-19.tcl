# mirror_pitch.tcl


proc mirror_pitch_initialize {} {

	# specify children devices
	set_children mirror_pitch_motor
}


proc mirror_pitch_move { new_mirror_pitch } {

	# global variables
	variable mirror_pitch_motor
	global gDevice
#::dcss2 sendMessage "htos_note yangx encoder database value = $gDevice(mirror_pitch_motor_encoder,databasePosition) "
#::dcss2 sendMessage "htos_note yangx encoder controller     = $gDevice(mirror_pitch_motor_encoder,controllerPosition) "
	#this statement should only be true on start up of dhs and motors have moved, or galil has been reset.
	if { $gDevice(mirror_pitch_motor_encoder,databasePosition) != $gDevice(mirror_pitch_motor_encoder,controllerPosition) } {
		if { $gDevice(mirror_pitch_motor_encoder,controllerPosition) > .5 } {
			::dcss2 sendMessage "htos_note mirror_pitch_motor encoder movement occurred while dhs was offline"
			#handle case where movement has occured while dhs was offline
			set_encoder mirror_pitch_motor_encoder $gDevice(mirror_pitch_motor_encoder,controllerPosition)
			catch {wait_for_encoder mirror_pitch_motor_encoder}
		} else {
			#handle case where controller was reset
			::dcss2 sendMessage "htos_note mirror_pitch_motor encoder controller was reset during during shutdown of dhs"
			set_encoder mirror_pitch_motor_encoder $gDevice(mirror_pitch_motor_encoder,databasePosition)
			catch {wait_for_encoder mirror_pitch_motor_encoder}
		}
		
		#forget the discrepancy in the mirror_pitch_motor_encoder
		set $gDevice(mirror_pitch_motor_encoder,databasePosition) 0
		set $gDevice(mirror_pitch_motor_encoder,controllerPosition) 0
	}


	#before we move the motor, check encoder sanity by first comparing the encoder to the expected position
	get_encoder mirror_pitch_motor_encoder
	wait_for_encoder mirror_pitch_motor_encoder
::dcss2 sendMessage "htos_note yangx encoder value    = $gDevice(mirror_pitch_motor_encoder,position) "
::dcss2 sendMessage "htos_note yangx mirror_pitch_motor value = $mirror_pitch_motor "
	#calculate how far off the encoder is
	set delta [expr $gDevice(mirror_pitch_motor_encoder,position) - $mirror_pitch_motor]

	#if the difference is greater than 2 cm
	if { abs($delta) > 2.0 } {
		#unfortunately we need human intervention at this point
		::dcss2 sendMessage "htos_note mirror_pitch_motor is at $mirror_pitch_motor, encoder is at $gDevice(mirror_pitch_motor_encoder,position) mm"
		::dcss2 sendMessage "htos_note mirror_pitch_motor differs by too much ($delta mm)"
		return -code error "mirror_pitch_motor_encoder differs by too much"
	} elseif { abs( $delta ) > 0.01  } {
		::dcss2 sendMessage "htos_note mirror_pitch_motor corrected to $gDevice(mirror_pitch_motor_encoder,position) mm, change of $delta mm."
		#reset the mirror_pitch_motor position
		set mirror_pitch_motor $gDevice(mirror_pitch_motor_encoder,position)
	}

        set old_z $mirror_pitch_motor
	# move mirror_pitch_motor motor

	move mirror_pitch_motor to $new_mirror_pitch

	# wait for the move to complete
	if { [catch { wait_for_devices mirror_pitch_motor } errorResult] } {
		#wait for mirror_pitch_motor to slide a little
		after 200
		#poll the encoder
		get_encoder mirror_pitch_motor_encoder
		wait_for_encoder mirror_pitch_motor_encoder
		
::dcss2 sendMessage "htos_note yangx after move detector_encoder= $gDevice(mirror_pitch_motor_encoder,position) "
		#calculate how far off the encoder is
		set delta [expr $gDevice(mirror_pitch_motor_encoder,position) - $mirror_pitch_motor]
::dcss2 sendMessage "htos_note yangx after move the deferrnce = $delta "
		#if the difference is significant
		if { abs($delta) > 0.01 } {
			::dcss2 sendMessage "htos_note mirror_pitch_motor corrected to $gDevice(mirror_pitch_motor_encoder,position) mm, change of $delta mm."
			#reset the mirror_pitch_motor position
			set mirror_pitch_motor $gDevice(mirror_pitch_motor_encoder,position)
		}
        catch {
            if {[isString mirror_pitch_motor_accumulate]} {
                variable mirror_pitch_motor_accumulate
                set distance [expr abs($mirror_pitch_motor - $old_z)]
                set mirror_pitch_motor_accumulate [expr $mirror_pitch_motor_accumulate + $distance]
            }
        }

		return -code error $errorResult
	}
    catch {
        if {[isString mirror_pitch_motor_accumulate]} {
            variable mirror_pitch_motor_accumulate
            set distance [expr abs($mirror_pitch_motor - $old_z)]
            set mirror_pitch_motor_accumulate [expr $mirror_pitch_motor_accumulate + $distance]
        }
    }

	#poll the encoder
	get_encoder mirror_pitch_motor_encoder
	wait_for_encoder mirror_pitch_motor_encoder
		
::dcss2 sendMessage "htos_note yangx after move mirroe_encoder= $gDevice(mirror_pitch_motor_encoder,position) "

::dcss2 sendMessage "htos_note yangx after move mirror motor = $mirror_pitch_motor "
	#calculate how far off the encoder is
	set delta [expr $gDevice(mirror_pitch_motor_encoder,position) - $mirror_pitch_motor]
		
::dcss2 sendMessage "htos_note yangx after move the deferrnce = $delta "
	#if the difference is significant
	if { abs($delta) > 1.0 } {
		::dcss2 sendMessage "htos_note mirror_pitch_motor stalled. Actual position is $gDevice(mirror_pitch_motor_encoder,position) mm."
		return -code error "encoder"
	}

	if { abs($delta) > 0.01 } {
		::dcss2 sendMessage "htos_note mirror_pitch_motor corrected to $gDevice(mirror_pitch_motor_encoder,position) mm, change of $delta mm."
		#reset the mirror_pitch_motor position
		set mirror_pitch_motor $gDevice(mirror_pitch_motor_encoder,position)
	}
    	#correctTableSlide_start
}


proc mirror_pitch_set { new_mirror_pitch } {

	# global variables
	variable mirror_pitch_motor

	set mirror_pitch_motor $new_mirror_pitch
	
	#set the encoder value.
	set_encoder mirror_pitch_motor_encoder $new_mirror_pitch
	wait_for_encoder mirror_pitch_motor_encoder
}


proc mirror_pitch_update {} {

	# global variables
	variable mirror_pitch_motor

	return $mirror_pitch_motor
}


proc mirror_pitch_calculate { dz } {
	
	return $dz
}
