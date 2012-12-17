package require Itcl

proc ISampleMountingDevice_initialize {} {
    puts "==============================="
    puts "ENTER ISampleMountingDevice_init"

	ISampleMountingDevice_create_SampleMountingDevice 

	return
}


proc ISampleMountingDevice_start { args } {
    puts "==============================="
    puts "ENTER ISampleMountingDevice_start args= $args"

    variable auto_sample_msg
    set auto_sample_msg ""
 
	global gOperation

	if { [catch "set result [list [eval $gOperation(ISampleMountingDevice,SampleMountingDevice) $args]]" error] } {
		log_error $error
		return "ERROR ISampleMountingDevice_start $error"
	}
   
	return $result
}

proc ISampleMountingDevice_create_SampleMountingDevice { } {
    puts "ENTER create_Samplexxxxxxx"
 
	global OPERATION_DIR
	global gOperation

	if { [info exists gOperation(ISampleMountingDevice,SampleMountingDevice)] } {
		if { [catch "::itcl::delete object gOperation(ISampleMountingDevice,SampleMountingDevice)" error] } {
			log_error $error
            puts "error in delete gOperation(ISam, samp)"
			return "ERROR"
		}
	}

    puts "NOT EXIST"
	
	if { [catch "namespace eval :: source $OPERATION_DIR/SAM4BL122.itcl" error] } {
        puts "error in source Sample.....itcl"
		log_error $error
		return "ERROR"
	}
    puts "SOURCE OK"

	if { [catch "set obj [SampleMountingDevice samplemountingDevice]" error] } {
        puts "error in set obj"
		log_error $error
		return "ERROR"
	}
    puts "SET OK"

	set gOperation(ISampleMountingDevice,SampleMountingDevice) $obj

    puts "create Sampl.... OK"

	return $obj
}

