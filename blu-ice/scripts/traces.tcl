#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

proc traceMotorScaled { motor args } {

	# global variables
	global gDevice
	global gConfig
	global gFormat
	
	set formatted [format "%.3f" $gDevice($motor,scaled)]
	set gConfig($motor,scaled) $formatted

	set formatted [format "%.$gFormat(places,$gDevice($motor,currentScaledUnits))f" \
		[get_scaled_value_in_units $motor $gDevice($motor,currentScaledUnits) ] ]
	set gDevice($motor,scaledDisplay) $formatted
	set gDevice($motor,scaledShort) [format "%.2f" $gDevice($motor,scaled)]
}


proc traceMotorUnscaled { motor args } {

	# global variables
	global gDevice
	global gConfig
	
	set formatted  [expr round($gDevice($motor,unscaled)) ]
	set gDevice($motor,unscaledDisplay) $formatted
	set gConfig($motor,unscaled) $formatted
}


proc traceConfigScaleFactor { motor entry args } {

	# global variables
	global gDevice
	global gConfig
	
	if { [focus] == $entry } {
		if { [is_positive_float $gConfig($motor,scaleFactor) ] } {
			storeValue gConfig($motor,scaleFactor) \
				$gConfig($motor,scaleFactor)
			catch {set gConfig($motor,unscaled) 					\
				[expr round($gConfig($motor,scaled) * 	\
				 $gConfig($motor,scaleFactor)) ] }
			catch {set gConfig($motor,unscaledLowerLimit) 				\
				[expr round($gConfig($motor,scaledLowerLimit) * \
				 (1.0*$gConfig($motor,scaleFactor))) ] }
			catch { set gConfig($motor,unscaledUpperLimit) 				\
				[expr round($gConfig($motor,scaledUpperLimit) * \
				(1.0*$gConfig($motor,scaleFactor))) ] }
			catch { set gConfig($motor,unscaledBacklash) 				\
				[expr round($gConfig($motor,scaledBacklash) * \
				(1.0*$gConfig($motor,scaleFactor))) ] }			
			storeValue gConfig($motor,unscaled) \
				$gConfig($motor,unscaled)			
			storeValue gConfig($motor,unscaledLowerLimit)	\
				$gConfig($motor,unscaledLowerLimit)
			storeValue gConfig($motor,unscaledUpperLimit) \
				$gConfig($motor,unscaledUpperLimit)
			storeValue gConfig($motor,unscaledBacklash) \
				$gConfig($motor,unscaledBacklash)
			real_config_parameter_changed $motor scaleFactor
			real_config_parameter_changed $motor scaled
			real_config_parameter_changed $motor lowerLimit
			real_config_parameter_changed $motor upperLimit
			real_config_parameter_changed $motor backlash
		} elseif { [is_blank $gConfig($motor,scaleFactor) ] } {
			set gConfig($motor,unscaled) ""
			set gConfig($motor,unscaledLowerLimit) ""
			set gConfig($motor,unscaledUpperLimit) ""
			set gConfig($motor,unscaledBacklash) ""
			storeValue gConfig($motor,scaleFactor) $gConfig($motor,scaleFactor)
			storeValue gConfig($motor,unscaled) \
				$gConfig($motor,unscaled)			
			storeValue gConfig($motor,unscaledLowerLimit)	\
				$gConfig($motor,unscaledLowerLimit)
			storeValue gConfig($motor,unscaledUpperLimit) \
				$gConfig($motor,unscaledUpperLimit)
			storeValue gConfig($motor,unscaledBacklash) \
				$gConfig($motor,unscaledBacklash)
			real_config_parameter_changed $motor scaleFactor
			real_config_parameter_changed $motor scaled
			real_config_parameter_changed $motor lowerLimit
			real_config_parameter_changed $motor upperLimit
			real_config_parameter_changed $motor backlash
		} else {
			set gConfig($motor,scaleFactor) [recallValue gConfig($motor,scaleFactor)]
			tkEntrySetCursor $entry [expr [$entry index insert] - 1]
		} 	
	}		
}



proc traceScaledEntry { scaled unscaled scale entry motor parameter args } {

	# global variables
	global gConfig

	if { [focus] == $entry } {
	
		if { [is_float [set $scaled] ] } {
			if { ![is_blank [set $scale]] && [set $scale] != 0 } {
				set $unscaled [expr round( [set $scaled] * (1.0*[set $scale])) ]
				storeValue $unscaled [set $unscaled]				
			}
		storeValue $scaled [set $scaled]
		real_config_parameter_changed $motor $parameter		
		} else {
			if { [is_blank [set $scaled]] || [is_incomplete_float [set $scaled]] } {
				set $unscaled ""
				storeValue $unscaled [set $unscaled]
				storeValue $scaled [set $scaled]		
				real_config_parameter_changed $motor $parameter			
			} else {
				set $scaled [recallValue $scaled]
				tkEntrySetCursor $entry [expr [$entry index insert] - 1]
			}
		} 	
	}
}


proc traceUnscaledEntry { unscaled scaled scale entry motor parameter args } {

	# global variables
	global gConfig

	if { [focus] == $entry } {

		if { [is_int [set $unscaled] ] && ![is_blank [set $scale]] && [set $scale] != 0 } {
			set $scaled [format "%.3f" [expr [set $unscaled] / (1.0*[set $scale])] ]
			storeValue $scaled [set $scaled]				
			storeValue $unscaled [set $unscaled]
			real_config_parameter_changed $motor $parameter	
		} elseif { ([is_blank [set $unscaled]] || [is_incomplete_int [set $unscaled]] ) \
				&& ![is_blank [set $scale]] && [set $scale] != 0} {
			set $scaled ""
			storeValue $scaled [set $scaled]	
			storeValue $unscaled [set $unscaled]
			real_config_parameter_changed $motor $parameter				
		} else {
			set $unscaled [recallValue $unscaled]
			tkEntrySetCursor $entry [expr [$entry index insert] - 1]
		} 	
	}
}


proc tracePositiveIntEntry { variable entry motor parameter args } {

	# global variables
	global gConfig

	if { [focus] == $entry } {
		
		if { [is_positive_int [set $variable]] || [is_blank [set $variable]] } {
			storeValue $variable [set $variable]
			real_config_parameter_changed $motor $parameter
		} else {
			set $variable [recallValue $variable]
			tkEntrySetCursor $entry [expr [$entry index insert] - 1]
		}	
	}
}


proc traceIntEntry { variable entry motor parameter args } {

	# global variables
	global gConfig
		

	if { [focus] == $entry } {

		if { [is_int [set $variable]] || [is_blank [set $variable]] } {
			storeValue $variable [set $variable]
			real_config_parameter_changed $motor $parameter
		} else {
			set $variable [recallValue $variable]
			tkEntrySetCursor $entry [expr [$entry index insert] - 1]
		}
	}	
}


proc traceFloatEntry { variable entry args } {

	# global variables
	global gConfig
	global gDevice

	if { [focus] == $entry } {

		if { [is_incomplete_float [set $variable]] || [is_blank [set $variable]] } {
			storeValue $variable [set $variable]
		} else {
			set $variable [recallValue $variable]
			tkEntrySetCursor $entry [expr [$entry index insert] - 1]
		}
	}	
}


proc tracePositiveFloatEntry { variable entry args } {

	# global variables
	global gConfig

	if { [focus] == $entry } {

		if { [is_incomplete_positive_float [set $variable]] || [is_blank [set $variable]] } {
			storeValue $variable [set $variable]
		} else {
			set $variable [recallValue $variable]
			tkEntrySetCursor $entry [expr [$entry index insert] - 1]
		}
	}	
}


proc clearTraces { variableName } {

	# access global variable
	upvar #0 $variableName variable

	foreach trace [trace vinfo variable] {
		trace vdelete variable [lindex $trace 0] [lindex $trace 1]
	}

}
