
proc operateLight_SSRF_17U1_initialize { } {}
proc operateLight_SSRF_17U1_cleanup { } {}
proc operateLight_SSRF_17U1_start { which state } {

	variable sampleLightState_SSRF_17U1
	variable inlineLightState_SSRF_17U1

	if { $which == "sample"} {
		if { $state == "on"} {
			open_shutter sampleLight_SSRF_17U1
		} else {
			close_shutter sampleLight_SSRF_17U1
		}
		set sampleLightState_SSRF_17U1 $state
	} elseif { $which == "inline"} {
		if { $state == "on"} {
			open_shutter inlineLight_SSRF_17U1
		} else {
			close_shutter inlineLight_SSRF_17U1
		}
		set inlineLightState_SSRF_17U1 $state
	}
}
