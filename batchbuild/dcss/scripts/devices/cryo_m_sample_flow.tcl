# cryo_m_sample_flow.tcl


proc cryo_m_sample_flow_initialize {} {

	# specify children devices
	set_children
	set_siblings
}


proc cryo_m_sample_flow_move { new_flow } {
    cryojet_set_sample_flow $new_flow
}


proc cryo_m_sample_flow_set { new_flow } {
}

proc cryo_m_sample_flow_update {} {
	if {[catch {cryojet_get_sample_flow} result]} {
        log_error "failed to read cryojet sample flow $result"
        return 0
    }
    return $result
}
