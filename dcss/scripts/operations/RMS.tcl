#this operation is for remove the mounted status when some thing wrong
proc RMS_initialize {} {
}

proc RMS_start { } {
    variable ::nScripts::robot_cassette
    variable ::nScripts::robot_status

    set robot_cassette {3 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 3 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 3 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1}

    set robot_status {status: 0 need_reset: 0 need_cal: 0 state: idle warning: {} cal_msg: {Gonio Cal: Done} cal_step: {100 of 100} mounted: {} pin_lost: 0 pin_mounted: 213 manual_mode: 0 need_mag_cal: 0 need_cas_cal: 0 need_clear: 0}
#    the following can be used for moving gonio to the mount position
#    and some other actions to get rebot ready for the next mount. 
#    it's used in SSRF.

#    set operationHandle [eval start_waitable_operation prepareForRobot 1]
#    set result [wait_for_operation $operationHandle]
    log_error "Reset the Robot status, Bluice recovery finished! Before continue using the Robot, you MUST contact the staff to check the robot real status"
    log_error "Reset the Robot status, Bluice recovery finished! Before continue using the Robot, you MUST contact the staff to check the robot real status"
    log_error "Reset the Robot status, Bluice recovery finished! Before continue using the Robot, you MUST contact the staff to check the robot real status"
}
	
