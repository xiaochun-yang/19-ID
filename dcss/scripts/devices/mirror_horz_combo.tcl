proc mirror_horz_combo_initialize {} {
	set_children mirror_horz
}

proc mirror_horz_combo_move { new_mirror_horz_combo } {
    variable mirror_horz
    variable mirror_horz_combo_offset

    if {[llength $mirror_horz_combo_offset] < 2} {
        log_error wrong offsets for mirror_horz_combo move
        return -code error WRONG_OFFSET
    }

    foreach {spear_offset ssrl_offset} $mirror_horz_combo_offset break

	# calculate destinations for real motors
	set new_mirror_horz $new_mirror_horz_combo
    set new_mirror_slit_spear [expr $new_mirror_horz + $spear_offset]
    set new_mirror_slit_ssrl  [expr $new_mirror_horz + $ssrl_offset]

	#check to see if the move can be completed by the real motors
	assertMotorLimit mirror_horz $new_mirror_horz
	assertMotorLimit mirror_slit_spear $new_mirror_slit_spear
	assertMotorLimit mirror_slit_ssrl  $new_mirror_slit_ssrl

	if { $new_mirror_horz < $mirror_horz } {
		move mirror_slit_spear to $new_mirror_slit_spear
		wait_for_devices mirror_slit_spear

		move mirror_horz to $new_mirror_horz
		wait_for_devices mirror_horz

		move mirror_slit_ssrl to $new_mirror_slit_ssrl
		wait_for_devices mirror_slit_ssrl
	} else {
		move mirror_slit_ssrl to $new_mirror_slit_ssrl
		wait_for_devices mirror_slit_ssrl

		move mirror_horz to $new_mirror_horz
		wait_for_devices mirror_horz

		move mirror_slit_spear to $new_mirror_slit_spear
		wait_for_devices mirror_slit_spear
	}
}


proc mirror_horz_combo_set { new_mirror_horz_combo } {
    variable mirror_horz_combo_offset
	variable mirror_horz
	variable mirror_slit_spear
	variable mirror_slit_ssrl

    set mirror_horz $new_mirror_horz_combo

    set spear_offset [expr $mirror_slit_spear - $new_mirror_horz_combo]
    set ssrl_offset  [expr $mirror_slit_ssrl  - $new_mirror_horz_combo]

    if {[llength $mirror_horz_combo_offset] > 2} {
        set mirror_horz_combo_offset [lreplace $mirror_horz_combo_offset \
        0 1 $spear_offset $ssrl_offset]
    } else {
        set mirror_horz_combo_offset [list $spear_offset $ssrl_offset]
    }
}

proc mirror_horz_combo_update {} {
	variable mirror_horz

	return $mirror_horz
}

proc mirror_horz_combo_calculate { mh } {
	return $mh
}

