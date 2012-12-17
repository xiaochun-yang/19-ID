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

proc genericFScan_initialize {} {
    namespace eval ::genericFScan {
        array set bandwidthArray [list]

        set bandwidthArray(fd_fluor)    [list 0    25000]
        set bandwidthArray(fd_nickel)   [list 7100 7700]
        set bandwidthArray(fd_cobalt)   [list 6630 7230]
        set bandwidthArray(fd_tungsten) [list 7762 10062]
        ### following are dynamic, will be filled during run time
        set bandwidthArray(fd_bw_generic)  [list 7762 10062]
        set bandwidthArray(fd_band_width)  [list 7762 10062]

        set pendingFScanList ""
    }
}

proc genericFScan_start { time } {
	global gStopFluorescenceScan

    variable ::genericFScan::bandwidthArray
    variable ::genericFScan::pendingFScanList

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
			if { [lindex $result 1] != "readyToAcquire" } {
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
	set dataArray(-1) $dataArray(0)
	set dataArray($channels) $dataArray([expr $channels - 1])

    set result [list fd_deadtime $percentDeadTime]

    set listCopy $pendingFScanList
    set pendingFScanList ""

    foreach name $listCopy {
        foreach {start end} $bandwidthArray($name) break
	    set value [processGenericFScanData $resolution $channels dataArray $start $end]
        lappend result $name $value
    }

    return $result
}
proc genericFScan_clearAsk { } {
    variable ::genericFScan::pendingFScanList

    set pendingFScanList ""
}
proc genericFScan_addAsk { args } {
    variable ::genericFScan::bandwidthArray
    variable ::genericFScan::pendingFScanList

    foreach name $args {
        if {$name == "fd_deadtime"} {
            ### dead time always on
            continue
        }
        if {![info exists bandwidthArray($name)]} {
            log_error $name not supported in generic fluorescent scan
            return -code error not_supported
        }
        if {[lsearch -exact $pendingFScanList $name] < 0} {
            lappend pendingFScanList $name
        }
        switch -exact -- $name {
            fd_bw_generic {
                variable bw_generic_const
                set bandwidthArray(fd_bw_generic) $bw_generic_const
            }
            fd_band_width {
                variable energy
                set start [expr $energy - 300]
                set end   [expr $energy + 300]
                set bandwidthArray(fd_band_width)  [list $start $end]
            }
        }
    }
}

proc processGenericFScanData { resolution channels dataArrayRef startEnergy endEnergy } {
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

	set area 0
	set index1 [expr int ( $startEnergy / $resolution )]
	set index2 [expr int ( $endEnergy / $resolution )]
			
    #get the first small area
	set area [expr $dataArray($index1) * ( ($index1 + 1) * $resolution - $startEnergy )/ double($resolution) ]
	incr index1

	#get all of the complete areas in between
	while { $index1 != $index2 } {
		set area [expr $area + $dataArray($index1) ]
		#puts "$index1 $area $dataArray($index1)"
		incr index1
	}
		
	#get the final small area
	set area [expr $area + $dataArray($index1) * ( $endEnergy - ($index1 * $resolution)) / double($resolution) ]
			
	return $area
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

