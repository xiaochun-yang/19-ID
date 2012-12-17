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

proc madScan_initialize {} {
    global OPERATION_DIR

    namespace eval ::madScan {set userName ""}
    
    ### they will be used to generate the raw data file
    variable ::madScan::userName
    variable ::madScan::sessionId
    variable ::madScan::rawExpFilename
    variable ::madScan::hd
	 # Hashtable of energy and raw scan data
    variable ::madScan::rawData
	 # List of energies
    variable ::madScan::energies

    set userName ""
    set sessionId ""
    set rawExpFilename ""
    set hd "read header file failed\n"

    #### this one better use local file access, not impersonal service.
    #### the file may not exist on remote machine
    set header_file [file join $OPERATION_DIR madScanBipHeader.txt]

    if {[catch "open $header_file" handle]} {
        log_warning open header file for madScan bip file failed
    } else {
        set hd [read $handle]
        close $handle
    }
}


proc madScan_start { userName_ sessionId_ directory_ fileRoot_ selectedEdge_ edgeEnergy_ edgeCutoff_ scanTime_} {
	variable ::madScan::userName
	variable ::madScan::sessionId
	variable ::madScan::rawExpFilename
   variable ::madScan::energies

    #####this one is also used by excitation scan
    variable scan_msg

    puts "checkUsernameIndir"
    checkUsernameInDirectory directory_ $userName_

    if [catch {block_all_motors;unblock_all_motors} errMsg] {
        log_error $errMsg
        puts "MUST wait all motors stop moving to start"
        log_error "MUST wait all motors stop moving to start"
        return -code error "MUST wait all motors stop moving to start"
    }
    if {$sessionId_ == "SID"} {
        set sessionId_ PRIVATE[get_operation_SID]
        puts "use operation SID: [SIDFilter $sessionId_]"
    }

    ################# check directory #####################
    if {[catch {
        impDirectoryWritable $userName_ $sessionId_ $directory_
    } errMsg]} {
        log_error directory $directory_ check failed: $errMsg
        return -code error "directory not writable"
    }

    #### save info for file creataion
    set userName $userName_
    set sessionId $sessionId_
    set rawExpFilename [file join $directory_ "${fileRoot_}raw_exp.bip"]
	 
	 # Read raw input scan file
	 madScan_readInputScanFile $selectedEdge_

    global gDevice    
    variable energy
    variable attenuation
    variable beamlineID
   variable sharedSession
   variable madScanStatus

    global gStopFluorescenceScan
    set gStopFluorescenceScan 0

   set index(active) 0
   set index(message) 1
   set index(user) 2
   set index(directory) 3
   set index(fileRoot) 4
   set index(edge) 5
   set index(energy) 6
   set index(cutoff) 7
   set index(time) 8
   set index(madResult) 9
   set index(exciteResult) 10

   #replace everything up to the result fields
   set madScanStatus [lreplace $madScanStatus 0 $index(time) 1 {Optimizing fluorescence signal.} $userName_ $directory_ $fileRoot_ $selectedEdge_ [list $edgeEnergy_ eV] [list $edgeCutoff_ eV] [list $scanTime_ s]]

   log_note "Starting fluorescence scan of $selectedEdge_ edge."

    #############user log ######
    user_log_note madscan "============== $userName_ start =========="
    user_log_note madscan "edge       $selectedEdge_"
    user_log_note madscan "edgeEnergy $edgeEnergy_"
    user_log_note madscan "scanTime   $scanTime_"
    user_log_note madscan "directory  $directory_"
    user_log_note madscan "fileRoot   $fileRoot_"
    user_log_note madscan "crystal    [user_log_get_current_crystal]"

    # store old motor positions as necessary
    set filterStatusList [getAllFilterStatus]

   log_warning $filterStatusList
    
    if { [catch {
        ### info madScan is running
        variable in_madScan

        set scan_msg "prepare for scan"
        set operationID [start_waitable_operation prepareForScan [expr $edgeEnergy_ + 100.0] ]
        wait_for_operation $operationID

        ##### record system status after prepare
        user_log_note madscan "after prepareForScan"
        user_log_system_status madscan
                
		  set energyOrdinates $energies
		  
        set lowerLimit $gDevice(energy,scaledLowerLimit)
        set upperLimit $gDevice(energy,scaledUpperLimit)
        set energyOrdinates [trimListWithLimits $energyOrdinates $lowerLimit $upperLimit]
        set energyOrdinates [energyRangeSpecialCheck $energyOrdinates]
        
        # do the scans and catch errors
        set scanData [scanEnergy $energyOrdinates $selectedEdge_ $edgeCutoff_ $scanTime_]

      set atom [lindex [split $selectedEdge_ -] 0]
      set edge [lindex [split $selectedEdge_ -] 1]

      #handle shared user directory
      set sharedUser [lindex $sharedSession 0]
      set sharedSessionId [lindex $sharedSession 1]
      set sharedDirectory [lindex $sharedSession 2]
      if {$sharedUser == ""} {set sharedUser NULL}
      if {$sharedSessionId == ""} {set sharedSessionId NULL}
      if {$sharedDirectory == ""} {set sharedDirectory NULL}

      set choochId [start_waitable_operation runAutochooch $userName_ $sessionId_ $directory_ $fileRoot_ $sharedUser $sharedSessionId $sharedDirectory $atom $edge $beamlineID $scanData]

      set scan_msg "recover from scan"
      # move energy back to previous position if scan successful
      set operationID [start_waitable_operation recoverFromScan]
        
      set scan_msg "waiting for runAutoChooch"
     #strip off the normal
      set result [lrange [wait_for_operation_to_finish $choochId] 1 end]

        user_log_note madscan "autochooch $result"
        user_log_note madscan "=================end==========================="

      set madScanStatus [lreplace $madScanStatus $index(madResult) $index(madResult) $result]

      catch {wait_for_operation $operationID}

    } errorResult ] } {
      variable madScanStatus
      set madScanStatus [lreplace $madScanStatus 0 $index(message) 0 "Scan failed: $errorResult."]

      log_error "Fluorescence scan of $selectedEdge_ edge failed: $errorResult"
      user_log_error madscan "Fluorescence scan of $selectedEdge_ edge failed: $errorResult"
      user_log_note madscan "=================end==========================="

      log_warning "Restoring attenuators."
        
        # restore filter states
      restoreFilterStatus $filterStatusList
        close_shutter shutter 1
        set scan_msg "error: $errorResult"
   
        return -code error $errorResult
    }

    # restore filter states
   restoreFilterStatus $filterStatusList
    close_shutter shutter 1

   set scan_msg ""
   set madScanStatus [lreplace $madScanStatus 0 $index(message) 0 "Scan completed normally."]
    return $result
}

#this function returns a list with all values outside of the limits removed
proc trimListWithLimits { fullList lowLimit highLimit } {
    ##### check inputs
    set ll_full [llength $fullList]
    if {$ll_full == 0} {
        log_error madScan empty energy list to trim
        set scan_msg "error: empty energy list"
        return -code error "empty energy list to trim"
    }

    if {$lowLimit > $highLimit} {
        log_warning energy lowLimit is bigger than the highLimit
        ###swap them
        set tmp_low $lowLimit
        set lowLimit $highLimit
        set highLimit $tmp_low
    }
    
    set newList ""
    foreach element $fullList {
        if { ($element > $lowLimit) && ($element < $highLimit) } {
            lappend newList $element
        } else {
            log_warning $element removed from scan list because out of range
        }
    }

    set ll_new  [llength $newList]
    if {$ll_new == 0} {
        log_error ALL energy points are trimmed by limits
        log_error limits low: $lowLimit high: $highLimit
        log_error energy points before trim: $fullList
        set scan_msg "error: all energy points trimmed"
        return -code error "ALL energy points are trimmed by limits"
    }

    return $newList
}

###may change to trim too.
proc energyRangeSpecialCheck { fullList } {
    global gEnergyRangeCheck

    set first [lindex $fullList 0]
    set last  [lindex $fullList end]
    if {[string is double -strict $first] && \
    [string is double -strict $last] && \
    [info exists gEnergyRangeCheck] && \
    $gEnergyRangeCheck != ""} {
        if {$first > $last} {
            set tttt $first
            set first $last
            set last $tttt
        }

        foreach callback $gEnergyRangeCheck {
            eval $callback $first $last
        }
    }

    return $fullList
}

#this function returns a list in the reverse order
proc reverseList { forwardList } {
    set reverseList ""

    foreach element $forwardList {
        set reverseList [linsert $reverseList 0 $element]
    }

    return $reverseList
}


proc scanEnergy { energyOrdinates_ selectedEdge_ edgeCutoff_ scanTime_ } {
   variable ::madScan::rawData
   variable ::madScan::energies
    variable scan_msg

    variable madScanStatus

    #bring the motor into scope
    variable energy

    set index(message) 1

    # wait for ion chambers to become inactive
    set referenceDetector i0
    eval wait_for_devices $referenceDetector

    set madData ""

    set totalCnt [llength $energyOrdinates_]
    if {$totalCnt == 0} {
        set scan_msg "error: no energy point"
        return -code error "no energy point to scan"
    }

    set cnt 0
    set skipped_cnt 0

    set avgDeadTime 0.0
	 
	 set deadTimeRatio 0.0

    madScan_createBIPFileHeader

    # loop over x-ordinates
    foreach energyPosition $energyOrdinates_ {
        incr cnt

        set madScanStatus [lreplace $madScanStatus $index(message) $index(message) "Scanning point $cnt of $totalCnt."]

        set scan_msg "scanning point $cnt of $totalCnt"

        checkFluorescenceScanStopped 

        # move the motor to the next scan position
        move energy to $energyPosition
        wait_for_devices energy
        
        # wait for motors to settle
        wait_for_time 100

        set startEnergy [expr $edgeCutoff_ - 300]
        set endEnergy [expr $edgeCutoff_ + 300]
        
        set opHandle [start_waitable_operation excitationScan $startEnergy $endEnergy 1 $referenceDetector $scanTime_]
        set result [wait_for_operation $opHandle]
        
        #parse the result
        if {[llength $result] < 4} {
            set scan_msg "error: wrong result from excitationScan"
            return -code error "excitationScan returned wrong result: $result"
        }

       set deadTimePercent [expr int( $deadTimeRatio * 100.0 )]%
		 log_note for scan $cnt dead time ratio is $deadTimePercent
		 
		 set dataPoint [split $rawData($energyPosition) " "]
		 set signalCounts [lindex $dataPoint 1]
		 set referenceCounts [lindex $dataPoint 2]
		 set fluorescence [lindex $dataPoint 3]
		 
#		 user_log_note "en=$energyPosition dataPoint=$dataPoint signalCounts=$signalCounts referenceCounts=$referenceCounts fluorescence=$fluorescence"
       
        #update this point
        send_operation_update $selectedEdge_ $energyPosition $signalCounts $referenceCounts $fluorescence $deadTimePercent

        user_log_note madscan scan$cnt $energyPosition $signalCounts $referenceCounts $fluorescence $deadTimePercent

        madScan_appendResultToBIPFile $energyPosition $signalCounts $referenceCounts $fluorescence

        lappend madData $energyPosition $fluorescence
    }
    
    set cnt [expr $cnt - $skipped_cnt]
    if {$cnt > 0} {
        set avgDeadTime [expr $avgDeadTime / $cnt]
    }
    set deadTimePercent [expr int( $avgDeadTime * 100.0 )]%
    log_note average dead time ratio: $deadTimePercent
    
    user_log_note madscan "averate dead time ration $deadTimePercent"
    return $madData
}

proc generateMadEnergyOrdinates { edgeEnergy_ } {

    set scanDelta 1.0
    
    set veryLowZoneStart  [expr $edgeEnergy_ - 200.0]
    set veryLowZoneEnd [expr $edgeEnergy_ - 170.0]
    
    set lowZoneStart [expr $edgeEnergy_ - 150.0]
    set lowZoneEnd [expr $edgeEnergy_ - 30]
    
    set midZoneStart $lowZoneEnd
    set midZoneEnd [expr $edgeEnergy_ + 30]

    #Why recalculate the midZone again?
    set fineScanPoints [expr int( ($midZoneEnd - $midZoneStart) / double($scanDelta) ) + 1 ]
    #set midZoneEnd [expr $midZoneStart + ($fineScanPoints - 1) * $scanDelta]
    
    set highZoneStart [expr $midZoneEnd + 1.5]
    set highZoneEnd [expr $edgeEnergy_ + 160.0]
    
    set veryHighZoneStart  [expr $edgeEnergy_ + 180.0]
    set veryHighZoneEnd [expr $edgeEnergy_ + 210.0]


    #start building the list of energy positions
    lappend energyOrdinates $veryLowZoneStart
    lappend energyOrdinates $veryLowZoneEnd
    
    #scan with a decreasing step size
    set step 20.0
    for { set ordinate $lowZoneStart } { $ordinate < $lowZoneEnd } { set ordinate [expr $ordinate + $step] } {
        lappend energyOrdinates $ordinate
        set step [expr $step -1.5]
        #print $step
    }

    #scan the middle zone with a fixed stepsize
    for { set point 0 } { $point < $fineScanPoints } { incr point } {
        lappend energyOrdinates [expr $midZoneStart + $point * $scanDelta ]
    }
    
    #scan with an increasing step size
    set step 2
    for { set ordinate $highZoneStart } { $ordinate < $highZoneEnd } { set ordinate [expr $ordinate + $step] } {
        lappend energyOrdinates $ordinate
        set step [expr $step + 1.5]
    }

    #add points for very coarse higher energy readings
    lappend energyOrdinates $veryHighZoneStart
    lappend energyOrdinates $veryHighZoneEnd
    
    #reverse the energy ordinates to go with backlash
    
    #if { $gBeamline(energyScanDir) == "DOWN" } {
    #    set energyOrdinates [reverseList $energyOrdinates]
    #}

    #strip off energy values that are outside of the motors limits
    #set energyOrdinates [trimListWithLimits $energyOrdinates [device::energy cget -lowerLimit] [device::energy cget -upperLimit]]
    
    return $energyOrdinates
}
proc madScan_createBIPFileHeader { } {
    variable ::madScan::userName
    variable ::madScan::sessionId
    variable ::madScan::rawExpFilename
    variable ::madScan::hd

    if {$userName == "" || $sessionId == "" || $rawExpFilename == "" || \
    $hd == ""} {
        log_warning not enough info to create raw bip file
        return
    }

    if {[catch {
        impWriteFile $userName $sessionId $rawExpFilename $hd false
    } eMsg]} {
        log_warning write header for $rawExpFilename failed
    }
}
proc madScan_appendResultToBIPFile { x y1 y2 y3 } {
    variable ::madScan::userName
    variable ::madScan::sessionId
    variable ::madScan::rawExpFilename

    if {$userName == "" || $sessionId == "" || $rawExpFilename == ""} {
        log_warning not enough info to append raw bip file
        return
    }

    set contents "$x $y1 $y2 $y3\n"
    if {[catch {
        impAppendTextFile $userName $sessionId $rawExpFilename $contents
    } eMsg]} {
        log_warning save raw data to $rawExpFilename failed
    }
	 
}

# Read raw scan data from input file for a given element and edge.
proc madScan_readInputScanFile { edge_ } {

	global DCS_DIR
   variable ::madScan::rawData
   variable ::madScan::energies
	
	array set rawData {}
	set energies {}
	
	# Location of input raw scan data in bip files, e.g. Cu-K.bip, Se-K.bip, Fe-L1.bip.
	set scanFile "$DCS_DIR/dcss/examples/MAD/${edge_}.bip"
	set defScanFile "$DCS_DIR/dcss/examples/MAD/default.bip"

	if {[catch "open $scanFile" handle]} {
		log_warning "Cannot open scan file $scanFile"
		if {[catch "open $defScanFile" handle]} {
			log_warning "Cannot open default scan file $defScanFile"
			return
		}
	}
	
	# Read file
	set start 0
	while {[gets $handle line] != -1} {
		if { $start == 1 } {
			set words [split $line " "]
			set en [lindex $words 0]
			lappend energies $en
			set rawData($en) "$line"
#			puts "Got scan data energy=$en scan=$rawData($en)"
		} else {
			if { $line == "_sub_trace.y3" } {
				set start 1
			}
		}
	}
		
	close $handle
		
}
