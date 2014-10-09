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

package provide DCSRunSequenceCalculator 1.0

package require DCSRunField
package require DCSConfig

class ::DCS::RunSequenceCalculator {
    inherit ::DCS::RunField

    private variable m_contents ""
	private variable _energyLabels [list E1 E2 E3 E4 E5]

	#calculated variables
	private variable _fullWedgePattern
	private variable _fullWedgeFramesPerLevel
	private variable _fragmentWedgePattern
	private variable _fragmentWedgeFramesPerLevel
	private variable _fragmentStartIndex
	private variable _totalFrames
	private variable _numCompleteWedges
	private variable _numComponents 2
	public variable _framesPerWedge
	private variable _inverseStartFrame
	public variable _framesPerPhiWedge
    public variable _framesPerPhiRunFragment 
    private variable _completedLevelsInWedge

    ###### this is the only way to change this class
	public method updateRunDefinition { message_ } {}
    public method returnLastFrame { } {}

    ###### accessor
    public method getField { name } {
        return [::DCS::RunField::getField m_contents $name]
    }
    public method getList { args } {
        return [eval ::DCS::RunField::getList m_contents $args]
    }
    public method getEnergies { } {
        return [getList energy1 energy2 energy3 energy4 energy5]
    }

    public method getFullWedgeFramesPerLevel { } {
     return [list $_fullWedgeFramesPerLevel(0) \
                  $_fullWedgeFramesPerLevel(1) \
                  $_fullWedgeFramesPerLevel(2)] }

    public method getFragmentWedgeFramesPerLevel { } {
     return [list $_fragmentWedgeFramesPerLevel(0) \
                  $_fragmentWedgeFramesPerLevel(1) \
                  $_fragmentWedgeFramesPerLevel(2)] }

	#public methods
	public method listAllFrames { } {}

	public method getMotorPositionsAtIndex { index }
	public method getTotalFrames {} { return $_totalFrames }

    public method calculateCompletedLevelsInWedge { index } 

    ### temperary to do something for each wedge
	public method getWedgeCompletedAtIndex { index }

	private method calculateOffsetsAtIndex { index }
}

body ::DCS::RunSequenceCalculator::updateRunDefinition { message_ } {
    puts "updateRunDefinition $message_ for $this"

    if {$m_contents == $message_} return

    set ll_m [llength $message_]
    set ll_f [getNumField]
    if {$ll_f > $ll_m} {
        log_error "wrong run definition"
        puts "wrong run definition: f: $ll_f m: $ll_m"
        return
    }
    if {$ll_f != $ll_m} {
        log_warning "wrong run definition length not match fields"
        puts "wrong run definition: f: $ll_f m: $ll_m"
    }
    set m_contents $message_
        
    foreach \
    {wedgeSize delta inverseOn numEnergies startAngle endAngle startFrame} \
    [getList \
    wedge_size delta inverse_on num_energy start_angle end_angle start_frame]\
    break

    puts "$wedgeSize $delta $inverseOn $numEnergies $startAngle $endAngle $startFrame"

	#calculate the number of phi-slices in a wedge
    if {$delta == 0} {
	    set _framesPerPhiWedge 1
    } else {
	    set _framesPerPhiWedge \
        [expr int ( ($wedgeSize + 0.0000001) / double( $delta)) ]
    }

	#define the data collection sequence while inside a complete wedge
	set _fullWedgePattern [list $_framesPerPhiWedge [expr $inverseOn + 1 ] $numEnergies] 

	set fullWedgeFramesPerLevel [calculateFramesPerComponentLevel $_fullWedgePattern]

	#log_note "fullWedgeFramesPerLevel $fullWedgeFramesPerLevel"

	set _numCompleteWedges [expr int(( $endAngle - $startAngle )/ $wedgeSize + 0.00001)]

	set cnt 0
	foreach frameSize $fullWedgeFramesPerLevel {
		set _fullWedgeFramesPerLevel($cnt) $frameSize
		incr cnt
	}

	#define the data collection sequence while within a wedge fragment
    if {$delta == 0} {
	    set framesPerPhiRun 1
    } else {
	    set framesPerPhiRun [expr int( ( $endAngle - $startAngle +0.000001)/ double($delta) + 0.00001 ) ]
    }
	#log_note "int (  $endAngle - $startAngle ) / double($delta) ) = $framesPerPhiRun "

	#log_note "framesPerPhiRun $framesPerPhiRun"
	#set framesPerPhiRunFragment [expr $framesPerPhiRun % $_framesPerPhiWedge]
	set _framesPerPhiRunFragment [expr $framesPerPhiRun - $_framesPerPhiWedge * $_numCompleteWedges ]
	#log_note "framesPerPhiRunFragment $_framesPerPhiRunFragment"

	set _fragmentWedgePattern [list $_framesPerPhiRunFragment [expr $inverseOn + 1 ] $numEnergies] 
	set fragmentWedgeFramesPerLevel [calculateFramesPerComponentLevel $_fragmentWedgePattern]

	#log_note "framesPerPhiRunFragment $_framesPerPhiRunFragment"
	#log_note "fragmentWedgeFramesPerLevel $fragmentWedgeFramesPerLevel"

	set cnt 0
	foreach frameSize $fragmentWedgeFramesPerLevel {
		set _fragmentWedgeFramesPerLevel($cnt) $frameSize
		incr cnt
	}

	#calculate the index to first frame of the wedge fragment
	set _framesPerWedge $_fullWedgeFramesPerLevel($_numComponents)

	set _fragmentStartIndex [expr $_framesPerWedge * $_numCompleteWedges ]
	#log_note "startIndex $_fragmentStartIndex"

	#calculate the total number of frames in the run
	set _totalFrames [expr $_framesPerWedge * $_numCompleteWedges + $_fragmentWedgeFramesPerLevel($_numComponents) ]

    if {$delta == 0} {
	    set framesPer180 1
    } else {
	    set framesPer180 [expr int (180.00001 / double($delta) ) ]
    }
	#puts " framesPer180: $framesPer180         framesPerPhiRun: $framesPerPhiRun" 
	set framesPer360 [expr $framesPer180 * 2 ]
	set inverseJumpFrameIndex [expr int( ( double($framesPerPhiRun + $framesPer180 - 0.9999999) ) / double($framesPer360) + 0.000001 ) + 1]

	#puts "************ framesPer360: $framesPer360, framesPerPhiRun $framesPerPhiRun, inverseJumpFrameIndex:   $inverseJumpFrameIndex "

	set _inverseStartFrame [expr $inverseJumpFrameIndex * $framesPer360  - $framesPer180 + $startFrame  ]
	#log_note $_inverseStartFrame

	return
}


body ::DCS::RunSequenceCalculator::calculateOffsetsAtIndex { index } {

	set completedLevels ""
	set levelIndex $index

	if { $index < $_fragmentStartIndex } {
		#start at the outermost level (e.g. energy wedge)
		for {set cnt $_numComponents } { $cnt >= 0 } { incr cnt -1 } {
			set framesPerThisLevel $_fullWedgeFramesPerLevel($cnt)
			
			set completed [expr int($levelIndex/$_fullWedgeFramesPerLevel($cnt))]
			incr levelIndex [expr -1 * $completed * $framesPerThisLevel ]
			
			lappend completedLevels $completed
		}
	} else {
		incr levelIndex [expr -1 * $_fragmentStartIndex ]
		#start at the outermost level (e.g. energy wedge)
		for {set cnt $_numComponents } { $cnt >= 0 } { incr cnt -1 } {
			set framesPerThisLevel $_fragmentWedgeFramesPerLevel($cnt)
		
			set completed [expr int($levelIndex/$framesPerThisLevel)]
			incr levelIndex [expr -1 * $completed * $framesPerThisLevel ]
			
			lappend completedLevels $completed
		}
	}
	lappend completedLevels $levelIndex
	#puts $completedLevels
	return $completedLevels
	
}

#Takes an absolute index into a run, and calculates the motor positions at
#that frame.
body ::DCS::RunSequenceCalculator::getMotorPositionsAtIndex { index } {

	set result [calculateOffsetsAtIndex $index ]

	set completedPhi [lindex $result 3]
	set completedInverse [lindex $result 2]
	set completedEnergies [lindex $result 1]

	#if we are not in a wedge fragment
	if { $index < $_fragmentStartIndex } {
		set completedWedges [lindex $result 0]
        set numConsPhi [expr $_framesPerPhiWedge - $completedPhi]
	} else {
		set completedWedges $_numCompleteWedges
        set numConsPhi [expr $_framesPerPhiRunFragment - $completedPhi]
	}

	#calculate phi position
    foreach {startAngle delta wedgeSize startFrame numEnergies fileroot runLabel} \
    [getList \
    start_angle delta wedge_size start_frame num_energy file_root run_label] break
    set energies [getEnergies]
	#puts "*************Completed Phi: $completedPhi Completed Wedges:  $completedWedges"
	set phi [expr $startAngle + $completedPhi * $delta + 180.0 * $completedInverse \
					 + $completedWedges * $wedgeSize]

	#calculate energy position
	set energy [lindex $energies $completedEnergies]

	#calculate label
	set energyLabel [lindex $_energyLabels $completedEnergies]

	#puts "$completedWedges $completedPhi"
	if { $completedInverse == 0 } {
		set frameLabel [expr $startFrame + $completedPhi + $completedWedges * $_framesPerPhiWedge]
	} else {
		set frameLabel [expr $_inverseStartFrame + $completedPhi + $completedWedges * $_framesPerPhiWedge]
	}

    set frameFormat [::config getFrameCounterFormat]
	
	if  { $numEnergies > 1} {
		set fileRootNoIndex [format "%s_%s_%s" $fileroot $runLabel $energyLabel ]
		set filename [format "${fileRootNoIndex}_$frameFormat" $frameLabel]
	} else {
		set fileRootNoIndex [format "%s_%s" $fileroot $runLabel]
		set filename [format "${fileRootNoIndex}_$frameFormat" $frameLabel]
	}

    ### we use sub_dir, not the combined $directory/$sub_dir.  This way, easy to spot what we chanted.
    set iE [expr int($energy)]
    set iME [expr round($energy * 1000) % 1000]

    set sub_dir [format "%s_%dd%03d" $energyLabel $iE $iME]

	##return [format "%s %6.2f %8.2f" $filename [expr $phi - 360.0 * int($phi/360.0)] $energy]
	return [format "%s %6.2f %8.2f %s %d %d %s" \
    $filename $phi $energy $fileRootNoIndex $frameLabel $numConsPhi $sub_dir]
}

body ::DCS::RunSequenceCalculator::getWedgeCompletedAtIndex { index } {

	set result [calculateOffsetsAtIndex $index ]

	#if we are not in a wedge fragment
	if { $index < $_fragmentStartIndex } {
		set completedWedges [lindex $result 0]
	} else {
		set completedWedges $_numCompleteWedges
	}
    return $completedWedges
}
#Returns a list of all frames in a defined run.
body ::DCS::RunSequenceCalculator::listAllFrames { } {
	set allFrames ""
	#loop over all frames

	for { set index 0} { $index < $_totalFrames} { incr index } {
		set result [getMotorPositionsAtIndex $index ]

		lappend allFrames $result
	}
	return $allFrames
}

body ::DCS::RunSequenceCalculator::returnLastFrame { } {
    return [getMotorPositionsAtIndex [expr $_totalFrames - 1 ] ]
}
#For calculating time for run
body ::DCS::RunSequenceCalculator::calculateCompletedLevelsInWedge { index } {

    set completedLevels ""
    set _completedLevelsInWedge ""
    set levelIndex $index

    if { $index < $_fragmentStartIndex } {
        #start at the outermost level (e.g. energy wedge)
        for {set cnt $_numComponents } { $cnt >= 0 } { incr cnt -1 } {
            set framesPerThisLevel $_fullWedgeFramesPerLevel($cnt)

            set completed [expr int($levelIndex/$_fullWedgeFramesPerLevel($cnt))]
            incr levelIndex [expr -1 * $completed * $framesPerThisLevel ]

            lappend completedLevels $completed
        }
    } else {
        incr levelIndex [expr -1 * $_fragmentStartIndex ]
        #start at the outermost level (e.g. energy wedge)
        for {set cnt $_numComponents } { $cnt >= 0 } { incr cnt -1 } {
            set framesPerThisLevel $_fragmentWedgeFramesPerLevel($cnt)

            set completed [expr int($levelIndex/$framesPerThisLevel)]
            incr levelIndex [expr -1 * $completed * $framesPerThisLevel ]

            lappend completedLevels $completed
        }
    }
    lappend completedLevels $levelIndex
    lappend completedLevels $_fragmentStartIndex
    #puts $completedLevels
    foreach value $completedLevels  {
           lappend _completedLevelsInWedge $value
    }
    return $_completedLevelsInWedge

}

class ::DCS::RunSequenceCalculatorForQueue {
    inherit ::DCS::RunFieldForQueue

    private variable m_contents ""
	private variable _energyLabels [list E1 E2 E3 E4 E5]

	#calculated variables
	private variable _fullWedgePattern
	private variable _fullWedgeFramesPerLevel
	private variable _fragmentWedgePattern
	private variable _fragmentWedgeFramesPerLevel
	private variable _fragmentStartIndex
	private variable _totalFrames
	private variable _numCompleteWedges
	private variable _numComponents 2
	public variable _framesPerWedge
	private variable _inverseStartFrame
	public variable _framesPerPhiWedge
    public variable _framesPerPhiRunFragment 

    ###### this is the only way to change this class
	public method updateRunDefinition { message_ } {}

    ###### accessor
    public method getField { name } {
        return [::DCS::RunFieldForQueue::getField m_contents $name]
    }
    public method getList { args } {
        return [eval ::DCS::RunFieldForQueue::getList m_contents $args]
    }
    public method getEnergies { } {
        return [getList energy1 energy2 energy3 energy4 energy5]
    }

	#public methods
	public method listAllFrames { } {}

	public method getMotorPositionsAtIndex { index }
	public method getTotalFrames {} { return $_totalFrames }

	private method calculateOffsetsAtIndex { index }
}

body ::DCS::RunSequenceCalculatorForQueue::updateRunDefinition { message_ } {
    puts "updateRunDefinition $message_ for $this"

    if {$m_contents == $message_} return

    set ll_m [llength $message_]
    set ll_f [getNumField]
    if {$ll_f > $ll_m} {
        log_error "wrong run definition"
        puts "wrong run definition: f: $ll_f m: $ll_m"
        return
    }
    if {$ll_f != $ll_m} {
        log_warning "wrong run definition length not match fields"
        puts "wrong run definition: f: $ll_f m: $ll_m"
    }
    set m_contents $message_
        
    foreach \
    {wedgeSize delta inverseOn numEnergies startAngle endAngle startFrame} \
    [getList \
    wedge_size delta inverse_on num_energy start_angle end_angle start_frame]\
    break

    puts "$wedgeSize $delta $inverseOn $numEnergies $startAngle $endAngle $startFrame"

	#calculate the number of phi-slices in a wedge
    if {$delta == 0} {
	    set _framesPerPhiWedge 1
    } else {
	    set _framesPerPhiWedge [expr int ( ($wedgeSize + 0.0000001) / double( $delta)) ]
    }

	#define the data collection sequence while inside a complete wedge
	set _fullWedgePattern [list $_framesPerPhiWedge [expr $inverseOn + 1 ] $numEnergies] 

	set fullWedgeFramesPerLevel [calculateFramesPerComponentLevel $_fullWedgePattern]

	#log_note "fullWedgeFramesPerLevel $fullWedgeFramesPerLevel"

	set _numCompleteWedges [expr int(( $endAngle - $startAngle )/ $wedgeSize + 0.00001)]

	set cnt 0
	foreach frameSize $fullWedgeFramesPerLevel {
		set _fullWedgeFramesPerLevel($cnt) $frameSize
		incr cnt
	}

	#define the data collection sequence while within a wedge fragment
    if {$delta == 0} {
	    set framesPerPhiRun 1
    } else {
	    set framesPerPhiRun [expr int( ( $endAngle - $startAngle +0.000001)/ double($delta) + 0.00001 ) ]
    }
	#log_note "int (  $endAngle - $startAngle ) / double($delta) ) = $framesPerPhiRun "

	#log_note "framesPerPhiRun $framesPerPhiRun"
	#set framesPerPhiRunFragment [expr $framesPerPhiRun % $_framesPerPhiWedge]
	set _framesPerPhiRunFragment [expr $framesPerPhiRun - $_framesPerPhiWedge * $_numCompleteWedges ]
	#log_note "framesPerPhiRunFragment $_framesPerPhiRunFragment"

	set _fragmentWedgePattern [list $_framesPerPhiRunFragment [expr $inverseOn + 1 ] $numEnergies] 
	set fragmentWedgeFramesPerLevel [calculateFramesPerComponentLevel $_fragmentWedgePattern]

	#log_note "framesPerPhiRunFragment $_framesPerPhiRunFragment"
	#log_note "fragmentWedgeFramesPerLevel $fragmentWedgeFramesPerLevel"

	set cnt 0
	foreach frameSize $fragmentWedgeFramesPerLevel {
		set _fragmentWedgeFramesPerLevel($cnt) $frameSize
		incr cnt
	}

	#calculate the index to first frame of the wedge fragment
	set _framesPerWedge $_fullWedgeFramesPerLevel($_numComponents)

	set _fragmentStartIndex [expr $_framesPerWedge * $_numCompleteWedges ]
	#log_note "startIndex $_fragmentStartIndex"

	#calculate the total number of frames in the run
	set _totalFrames [expr $_framesPerWedge * $_numCompleteWedges + $_fragmentWedgeFramesPerLevel($_numComponents) ]

    if {$delta == 0} {
	    set framesPer180 1
    } else {
	    set framesPer180 [expr int (180.00001 / double($delta) ) ]
    }
	#puts " framesPer180: $framesPer180         framesPerPhiRun: $framesPerPhiRun" 
	set framesPer360 [expr $framesPer180 * 2 ]
	set inverseJumpFrameIndex [expr int( ( double($framesPerPhiRun + $framesPer180 - 0.9999999) ) / double($framesPer360) + 0.000001 ) + 1]

	#puts "************ framesPer360: $framesPer360, framesPerPhiRun $framesPerPhiRun, inverseJumpFrameIndex:   $inverseJumpFrameIndex "

	set _inverseStartFrame [expr $inverseJumpFrameIndex * $framesPer360  - $framesPer180 + $startFrame  ]
	#log_note $_inverseStartFrame

	return
}


body ::DCS::RunSequenceCalculatorForQueue::calculateOffsetsAtIndex { index } {

	set completedLevels ""
	set levelIndex $index

	if { $index < $_fragmentStartIndex } {
		#start at the outermost level (e.g. energy wedge)
		for {set cnt $_numComponents } { $cnt >= 0 } { incr cnt -1 } {
			set framesPerThisLevel $_fullWedgeFramesPerLevel($cnt)
			
			set completed [expr int($levelIndex/$_fullWedgeFramesPerLevel($cnt))]
			incr levelIndex [expr -1 * $completed * $framesPerThisLevel ]
			
			lappend completedLevels $completed
		}
	} else {
		incr levelIndex [expr -1 * $_fragmentStartIndex ]
		#start at the outermost level (e.g. energy wedge)
		for {set cnt $_numComponents } { $cnt >= 0 } { incr cnt -1 } {
			set framesPerThisLevel $_fragmentWedgeFramesPerLevel($cnt)
		
			set completed [expr int($levelIndex/$framesPerThisLevel)]
			incr levelIndex [expr -1 * $completed * $framesPerThisLevel ]
			
			lappend completedLevels $completed
		}
	}
	lappend completedLevels $levelIndex
	#puts $completedLevels
	return $completedLevels
	
}

#Takes an absolute index into a run, and calculates the motor positions at
#that frame.
body ::DCS::RunSequenceCalculatorForQueue::getMotorPositionsAtIndex { index } {

	set result [calculateOffsetsAtIndex $index ]

	set completedPhi [lindex $result 3]
	set completedInverse [lindex $result 2]
	set completedEnergies [lindex $result 1]

	#if we are not in a wedge fragment
	if { $index < $_fragmentStartIndex } {
		set completedWedges [lindex $result 0]
        set numConsPhi [expr $_framesPerPhiWedge - $completedPhi]
	} else {
		set completedWedges $_numCompleteWedges
        set numConsPhi [expr $_framesPerPhiRunFragment - $completedPhi]
	}

	#calculate phi position
    foreach {startAngle delta wedgeSize startFrame numEnergies fileroot runLabel} \
    [getList \
    start_angle delta wedge_size start_frame num_energy file_root run_label] break
    set energies [getEnergies]
	#puts "*************Completed Phi: $completedPhi Completed Wedges:  $completedWedges"
	set phi [expr $startAngle + $completedPhi * $delta + 180.0 * $completedInverse \
					 + $completedWedges * $wedgeSize]

	#calculate energy position
	set energy [lindex $energies $completedEnergies]

	#calculate label
	set energyLabel [lindex $_energyLabels $completedEnergies]

	#puts "$completedWedges $completedPhi"
	if { $completedInverse == 0 } {
		set frameLabel [expr $startFrame + $completedPhi + $completedWedges * $_framesPerPhiWedge]
	} else {
		set frameLabel [expr $_inverseStartFrame + $completedPhi + $completedWedges * $_framesPerPhiWedge]
	}

    set frameFormat [::config getFrameCounterFormat]
	
	if  { $numEnergies > 1} {
		set fileRootNoIndex [format "%s_%s_%s" $fileroot $runLabel $energyLabel ]
		set filename [format "${fileRootNoIndex}_$frameFormat" $frameLabel]
	} else {
		set fileRootNoIndex [format "%s_%s" $fileroot $runLabel]
		set filename [format "${fileRootNoIndex}_$frameFormat" $frameLabel]
	}

	##return [format "%s %6.2f %8.2f" $filename [expr $phi - 360.0 * int($phi/360.0)] $energy]
	return [format "%s %6.2f %8.2f %s %d %d" $filename $phi $energy $fileRootNoIndex $frameLabel $numConsPhi ]
}

#Returns a list of all frames in a defined run.
body ::DCS::RunSequenceCalculatorForQueue::listAllFrames { } {
	set allFrames ""
	#loop over all frames

	for { set index 0} { $index < $_totalFrames} { incr index } {
		set result [getMotorPositionsAtIndex $index ]

		lappend allFrames $result
	}
	return $allFrames
}


proc calculateFramesPerComponentLevel { componentRange } {

	set numComponents [llength $componentRange]
	
	set framesPerComponentLevel [list [lindex $componentRange 0]]

	set lastCnt 0
	for { set cnt 1} { $cnt < $numComponents } {incr cnt } {
		lappend framesPerComponentLevel [expr [lindex $componentRange $cnt] * [lindex $framesPerComponentLevel $lastCnt]]
		set lastCnt $cnt
	}
	return $framesPerComponentLevel
}
