
proc operateLight_ID19_initialize { } {}
proc operateLight_ID19_cleanup { } {}
proc operateLight_ID19_start { which state } {

	variable sampleLightState_ID19
	variable inlineLightState_ID19

	if { $which == "sample"} {
		if { $state == "on"} {
			open_shutter sampleLight_ID19
		} else {
			close_shutter sampleLight_ID19
		}
		set sampleLightState_ID19 $state
	} elseif { $which == "inline"} {
		if { $state == "on"} {
			open_shutter inlineLight_ID19
		} else {
			close_shutter inlineLight_ID19
		}
		set inlineLightState_ID19 $state
	}
}
