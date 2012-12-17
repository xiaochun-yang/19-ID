# cryo_m_temp.tcl


proc cryo_m_temp_initialize {} {

	# specify children devices
	set_children
	set_siblings
}


proc cryo_m_temp_move { new_temp } {
    cryojet_set_temperature $new_temp
}


proc cryo_m_temp_set { new_cryo_m_temp } {
}

proc cryo_m_temp_update {} {
	if {[catch {cryojet_get_register 0} result]} {
        log_error "failed to read back cryojet temperature setting: $result"
        return 0
    }
    return $result
}
