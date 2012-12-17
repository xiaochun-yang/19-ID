# cryo_m_shield_flow.tcl


proc cryo_m_shield_flow_initialize {} {

	# specify children devices
	set_children
	set_siblings
}


proc cryo_m_shield_flow_move { new_flow } {
    cryojet_set_shield_flow $new_flow
}


proc cryo_m_shield_flow_set { new_flow } {
}

proc cryo_m_shield_flow_update {} {
	if {[catch {cryojet_get_shield_flow} result]} {
        log_error "failed to read cryojet shield flow $result"
        return 0
    }
    return $result
}
