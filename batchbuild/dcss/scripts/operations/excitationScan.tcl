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

proc excitationScan_initialize {} {

	# global variables 

}


proc excitationScan_start { startEnergy endEnergy numChannels referenceDetector time } {
	global gStopFluorescenceScan
	set gStopFluorescenceScan 0
        
	set resolution 25
	set channels 1024

	if {$time > 60.0} {
		return -code error "Scan time is excessive (>60.0 sec)."
	}

	#open the shutter
	open_shutter shutter

	if { [catch {
		set scanHandle [start_waitable_operation acquireSpectrum 1 $channels $time]
		set result [wait_for_operation $scanHandle]

		set status [lindex $result 0]
	
		#first wait for the operation update indicating that the detector is ready
		if { $status == "update" } {
			if { [lindex $result 1] == "readyToAcquire" } {
                if {$referenceDetector != ""} {
				    #start the real time clock
				    read_ion_chambers $time $referenceDetector
				    wait_for_devices $referenceDetector
				    set referenceCounts [get_ion_chamber_counts $referenceDetector]
                } else {
				    set referenceCounts 0
                }
			} else {
				#things did not go as planned
				return -code error $result
			}
		} else {
			#the detector could not be initialized
			return -code error $result
		}
	
		#now wait for the data from the detector
		set result [wait_for_operation $scanHandle]
		set status [lindex $result 0]
	}  errorResult ] } {
		#handle every error that could be raised during the scan
		close_shutter shutter
		return -code error $errorResult
	}

	close_shutter shutter

	#check to make sure that things are normal
	if { $status != "normal" } {
		#return error
		return -code error $result
	}

	#use the data in the result...
	set percentDeadTime [lindex $result 1]

	set cnt 0
	foreach dataPoint [lrange $result 2 end] {
		set dataArray($cnt) $dataPoint
		incr cnt
	}

	set processedData [processData $resolution $channels dataArray $startEnergy $endEnergy $numChannels]
	
	return "$percentDeadTime $referenceCounts $processedData"
}


proc processData { resolution channels dataArrayRef startEnergy endEnergy requestedChannels } {
	#get the reference to the array of data.
	upvar $dataArrayRef dataArray

	set result ""

	#check that the starting point is reasonable
	if { $startEnergy < 0 } {
		puts "request out of range of detector"
		return -code error "outOfRange"
	}
	
	#check that the ending point is reasonable
	if { $endEnergy > [expr $resolution * $channels] } {
		puts "request out of range of detector"
		return -code error "outOfRange"
	}

	#extend the "real" data just a little beyond the limits
	set dataArray(-1) $dataArray(0)
	set dataArray($channels) $dataArray([expr $channels - 1])

	#get the requested resolution
	set requestedResolution [expr ($endEnergy - $startEnergy)/double($requestedChannels) ]
	
	#value holding sum of all counts over total requested range
	set total 0.0

	if { $requestedResolution < $resolution } {
		#loop over all of the requested "virtual" channels
		for  { set cnt 0 } { $cnt < $requestedChannels } { incr cnt} {
			#get the points for this requested channel
			set requestedX1 [expr $cnt * $requestedResolution + $startEnergy ]
			set requestedX2 [expr $requestedX1 + $requestedResolution ]
		
			#value holding the total area of the virtual channel
			set area 0

			#get the index into the data array closest to the requested X1 (fast search)
			set indexX1 [expr int( $requestedX1 / $resolution ) ]
		
			#between which two data points is X1 bounded?
			if { $requestedX1 < ($indexX1 * $resolution + $resolution / 2.0) } {
				#on the left side
				#use the previous point to interpolate
				set bound1_X1 [expr $indexX1 -1]
				set bound1_X2 $indexX1
			} else {
				#on the right side
				#use the next point to interpolate
				set bound1_X1 $indexX1
				set bound1_X2 [expr $indexX1 +1]
			}
		
			#get the index into the data array closest to the requested X2 point
			set indexX2 [expr int( $requestedX2 / $resolution ) ]
			if { $requestedX2 < ($indexX2 * $resolution + $resolution / 2.0) } {
				#on the left side
				if {$indexX2 == 0 } {
					#can't interpolate with previous point because it doesn't exist
					#use a simple rectangle...
					set bound2_X1 0
					set bound2_X2 0
					set offset $dataArray(0)
				} else {
					#use the previous point to interpolate
					set bound2_X1 [expr $indexX2 -1]
					set bound2_X2 $indexX2
				}
			} else {
				#on the right side
				#use the next point to interpolate
				set bound2_X1 $indexX2
				set bound2_X2 [expr $indexX2 +1]
			}
			
			#puts "$requestedX1,$requestedX2 index1_1: $bound1_X1  index1_2: $bound1_X2  index2_1: $bound2_X1  index2_2: $bound2_X2"
		
			#get the slope for interpolated line around X1
			set slope [calcSlope $bound1_X1 $dataArray($bound1_X1) $bound1_X2 $dataArray($bound1_X2)]
			set offset $dataArray($bound1_X1)
			set origin [expr $bound1_X1 * $resolution + $resolution / 2.0]
			
			if { $bound1_X1 == $bound2_X1 && $bound1_X2 == $bound2_X2 } {
				#if the bounding points are the same for X1 and X2 then the summation is complete for this virtual channel
				set a1 [integrateLine $slope $offset [expr  ($requestedX1 - $origin)/double($resolution) ] ]
				set a2 [integrateLine $slope $offset [expr  ($requestedX2 - $origin)/double($resolution) ]]
				
				set area [expr $area + $a2 - $a1 ] 
			} else {
				#get the area from two different interpolated lines.
				
				#add the area up to the higher bounding point of the first segment
				set a1 [integrateLine $slope $offset [expr ($requestedX1 - $origin)/double($resolution)] ]
				set a2 [integrateLine $slope $offset 1 ]
				set area [expr $area + $a2 - $a1 ] 
				
				#add the area in the second bounding point up to the second requested point
				#get the slope for interpolated line around X2
				set slope [calcSlope $bound2_X1 $dataArray($bound2_X1) $bound2_X2 $dataArray($bound2_X2)]
				set offset $dataArray($bound2_X1)
				set origin [expr $bound2_X1 * $resolution + $resolution / 2.0]
				
				#get the area from the bounding point up to the second requested point
				set a2 [integrateLine $slope $offset [expr  ($requestedX2 - $origin) /$resolution ]]
				set area [expr $area + $a2]
			}
			lappend result $area
			set total [expr $total + $area]
			#puts "count\[$cnt\]: $area"
		}
	} else {
		puts "requested resolution larger than actual resolution"
		#requested resolution is greater than actual detector resolution
		set area 0
		for  { set cnt 0 } { $cnt < $requestedChannels } { incr cnt} {
			#get the points for this requested channel
			set requestedX1 [expr $cnt * $requestedResolution + $startEnergy ]
			set requestedX2 [expr $requestedX1 + $requestedResolution ]
			
			set index1 [expr int ( $requestedX1 / $resolution )]
			set index2 [expr int ( $requestedX2 / $resolution )]
			
			#get the first small area
			set area [expr $dataArray($index1) * ( ($index1 + 1) * $resolution - $requestedX1 )/ double($resolution) ]
			#puts $area
		
			incr index1

			#get all of the complete areas in between
			while { $index1 != $index2 } {
				set area [expr $area + $dataArray($index1) ]
				#puts "$index1 $area $dataArray($index1)"
				incr index1
			}
		
			#get the final small area
			set area [expr $area + $dataArray($index1) * ( $requestedX2 - ($index1 * $resolution)) / double($resolution) ]
			
			#get the index into the data array closest to the requested X1 (fast search)
			#set indexX1 [expr int( $requestedX1 / $resolution ) ]
			
			lappend result $area

			set total [expr $total + $area]
			#puts "count\[$cnt\]: $area"
		}
	}
	return $result
}



proc integrateLine { slope offset x } {
	#puts "integrate: $slope * $x^2 /2.0 + $offset * $x = [expr $slope * $x * $x /2.0 + $offset * $x ]"
	return [ expr $slope * $x * $x / 2.0 + $offset * $x ]
}


proc calcSlope { x1 y1 x2 y2 } {
	#	puts "calcSlope: ($y2 - $y1)/($x2-$x1)) = [expr ($y2 - $y1)/double($x2-$x1)]"
	set deltaX [expr $x2 - $x1]

	#protect against division by zero
	if { $deltaX != 0.0 } {
		return [expr ($y2 - $y1)/double($x2-$x1)]
	} else {
		return 0.0
	}
}

