package require Itcl

proc ISampleMountingDeviceSoftOnly_initialize {} {
}


proc ISampleMountingDeviceSoftOnly_start { args } {
	global gOperation
    
    set methodName [lindex $args 0]
    switch -exact -- $methodName {
        doTableCALCalculation -
        doTableCALVertCal -
        calculateTableSetup -
        fillSafeDistanceArray -
        fillMoveList -
        getGonioCALDATA -
        getDeltaGonioPosFromMotor -
        getDeltaGonioPosFromFutureMotor -
        resetLaserSensorForMotors -
        getReadAnalogResult -
        addUsersToBarcode -
        updateCassetteOwnerFromBarcode -
        getDeltaGonioPosFromDisplacementSensor {
        }
        default {
            return -code error "ERROR ISampleMountingDeviceSoftOnly: not support $methodName"
        }
    }

	if { [catch "set result [list [eval $gOperation(ISampleMountingDevice,SampleMountingDevice) $args]]" error] } {
		log_error $error
		return "ERROR ISampleMountingDeviceSoftOnly_start $error"
	}
	return $result
}
