# VIRTUAL.tcl
#This template is used to create the standard virtual motor.
#Virtual motors behave like regular motors except that
#moving the motor is the same as setting the motor.
#The "motor's" position is persistant across multiple starts of dcss.
#Updating the motor returns current position.

proc VIRTUAL_initialize {} {

	# specify children devices
	set_children
}


proc VIRTUAL_move { new_VIRTUAL } {

	# global variables
	variable VIRTUAL

	set VIRTUAL $new_VIRTUAL
}


proc VIRTUAL_set { new_VIRTUAL } {

	# global variables
	variable VIRTUAL
	
	set VIRTUAL $new_VIRTUAL
}


proc VIRTUAL_update {} {
	# global variables
	variable VIRTUAL
	
	# return current value.
	return $VIRTUAL
}


