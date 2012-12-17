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


proc collectTimedBurst_initialize {} {
	# global variables 
}

proc collectTimedBurst_start { detectorMode scanMotor sessionId } {

	variable collectTimedBurstParam 

    if {$sessionId == "SID"} {
        set sessionId PRIVATE[get_operation_SID]
        puts "collectTimedBurst use operation SID: [SIDFilter $sessionId]"
    }

	set index(active) 0
	set index(message) 1

	set timeInterval [lindex $collectTimedBurstParam 10]
	set timeInterval [expr {int(1000 * $timeInterval)} ]
	set numSets 	[lindex $collectTimedBurstParam 11]


	#set user 	[lindex $collectTimedBurstParam 2]
    set usr [get_operation_user]
	set dir 	[lindex $collectTimedBurstParam 5]
    checkCollectDirectoryAllowed $dir
    impDirectoryWritable $usr $sessionId $dir

	#close the shutter, in case it is open and we need to collect dark images.
	close_shutter shutter

	if { [catch {
		for { set i 1 } { $i <= $numSets } { incr i}  {
			#replace the active and message fields
			#set collectTimedBurstParam [lreplace $collectTimedBurstParam 0 1 1 [list Collecting Set $i] ]
			
			if {$scanMotor == "none"} {
				collectOneSet $i $detectorMode "NULL" $sessionId
			} else {
				collectOneSet1 $i $detectorMode $scanMotor $sessionId
			}

			#set msg "Waiting to Start Set [expr $i + 1 ]"
			set collectTimedBurstParam [lreplace $collectTimedBurstParam 1 1 [list Waiting to Start Set [expr $i + 1]] ]
			#waiting for the next set
			if { $i < $numSets } {
				wait_for_time $timeInterval
			}
		}
	
	} errorResult ] } {
		#handle every error that could be raised during data collection
		start_recovery_operation detector_stop
		#set msg "Stopped Collecting Due to $errorResult"
		set collectTimedBurstParam [lreplace $collectTimedBurstParam 0 1 0 [list Stopped Collecting Due to $errorResult] ]
		return -code error $errorResult
	}

	set collectTimedBurstParam [lreplace $collectTimedBurstParam 0 1 0 {Collection Completed} ]
	log_note "Completed Successfully."
	return 0		
}

proc collectOneSet { setNum detectorMode motorName sessionId } {
	variable collectTimedBurstParam 
    variable runs

	set useDose [lindex $runs 2]
    
	set reuseDark 0 
	set runNum 0
	set range 0.0

	set user 	[lindex $collectTimedBurstParam 2]
	set dir 	[lindex $collectTimedBurstParam 5]
	set root 	[lindex $collectTimedBurstParam 6]
	set startPos 	[lindex $collectTimedBurstParam 7]
	set numPoints 	[lindex $collectTimedBurstParam 8]
	set stepSize	[lindex $collectTimedBurstParam 9]
	set timeInterval [lindex $collectTimedBurstParam 10]
	set numSets 	[lindex $collectTimedBurstParam 11]
	set exposureTime [lindex $collectTimedBurstParam 12]
	set numImages 	[lindex $collectTimedBurstParam 13]

	if { $motorName != "NULL" } {
		move $motorName to $startPos
		wait_for_devices $motorName
		set range [expr {$numPoints * $stepSize}]
	} 

    #log_warning [list $setNum $user $dir $root $timeInterval $numSets $exposureTime $numImages]


for { set i 1 } { $i <= $numImages } { incr i } {
	    set collectTimedBurstParam [lreplace $collectTimedBurstParam 0 1 1 [list Collecting Set $setNum, Image $i] ]
		set filename [format "%s_%0.2d_%0.2d" $root $setNum $i]
		#log_warning "filename $filename"
		set operationHandle [start_waitable_operation collectFrame \
			 $runNum \
			 $filename \
			 $dir \
			 $user \
			 $motorName \
			 shutter \
			 $range \
			 [requestExposureTime_start $exposureTime $useDose] \
			 $detectorMode \
			 0 \
			 $reuseDark \
             $sessionId ]
	
		wait_for_operation $operationHandle

		# move motor back to starting position 
		if { $motorName != "NULL" } {
			move $motorName to $startPos
			wait_for_devices $motorName
		} 
	}
	#run is complete, flush the last image out
	start_operation detector_stop
}


proc collectOneSet1 { setNum detectorMode motorName sessionId } {
	variable collectTimedBurstParam 

	set reuseDark 0 
	set runNum 0

	set user 	[lindex $collectTimedBurstParam 2]
	set dir 	[lindex $collectTimedBurstParam 5]
	set root 	[lindex $collectTimedBurstParam 6]
	set startPos 	[lindex $collectTimedBurstParam 7]
	set numPoints 	[lindex $collectTimedBurstParam 8]
	set stepSize	[lindex $collectTimedBurstParam 9]
	set timeInterval [lindex $collectTimedBurstParam 10]
	set numSets 	[lindex $collectTimedBurstParam 11]
	set exposureTime [lindex $collectTimedBurstParam 12]

	if { $motorName != "NULL" } {
		move $motorName to $startPos
		wait_for_devices $motorName
	} 

    #log_warning [list $setNum $user $dir $root $timeInterval $numSets $exposureTime $numImages]


for { set i 1 } { $i <= $numPoints } { incr i } {
	    set collectTimedBurstParam [lreplace $collectTimedBurstParam 0 1 1 [list Collecting Set $setNum, Point $i] ]
		set filename [format "%s_%0.2d_%0.2d" $root $setNum $i]
		#log_warning "filename $filename"
		set operationHandle [start_waitable_operation collectFrame \
			 $runNum \
			 $filename \
			 $dir \
			 $user \
			 NULL \
			 shutter \
			 0.0 \
			 $exposureTime \
			 $detectorMode \
			 0 \
			 $reuseDark \
             $sessionId ]
	
		wait_for_operation $operationHandle

		# move motor by stepSize 
		if { $motorName != "NULL" } {
			move $motorName by $stepSize
			wait_for_devices $motorName
		} 
	}
	#run is complete, flush the last image out
	start_operation detector_stop
}

