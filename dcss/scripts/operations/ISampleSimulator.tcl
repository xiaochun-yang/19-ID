package require Itcl

proc ISampleMountingDevice_initialize {} {
    puts "==============================="
    puts "ENTER ISampleMountingDevice_init"
	puts "ENTER Simulator"
	ISampleMountingDevice_create_SampleMountingDevice 

	return
}


proc ISampleMountingDevice_start { args } {
    puts "==============================="
    puts "ENTER Simulator ISampleMountingDevice_start args= $args"
 
	global gOperation

	if { [catch "set result [list [eval $gOperation(ISampleMountingDevice,SampleMountingDevice) $args]]" error] } {
		log_error $error
		return "ERROR ISampleMountingDevice_start $error"
	}
   
	return $result
}

proc ISampleMountingDevice_create_SampleMountingDevice { } {
 
	global OPERATION_DIR
	global gOperation

	if { [info exists gOperation(ISampleMountingDevice,SampleMountingDevice)] } {
		if { [catch "::itcl::delete object gOperation(ISampleMountingDevice,SampleMountingDevice)" error] } {
			log_error $error
            puts "error in delete gOperation(ISam, samp)"
			return "ERROR"
		}
	}
	
	if { [catch "namespace eval :: source $OPERATION_DIR/SampleSimulator.itcl" error] } {
		log_error $error
            puts "error in source Sample.....itcl"
		return "ERROR"
	}

	if { [catch "set obj [SampleMountingDevice samplemountingDevice]" error] } {
		log_error $error
            puts "error in set obj"
		return "ERROR"
	}

	set gOperation(ISampleMountingDevice,SampleMountingDevice) $obj

    puts "create Sampl.... OK"

	return $obj
}

