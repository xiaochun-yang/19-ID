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

package require Itcl

::itcl::class runCalculator {
	#set variables
	private variable _startAngle
	private variable _endAngle
	private variable _delta
	private variable _wedgeSize
	private variable _inverseOn
	private variable _energies

	#set variables used in generating filenames
	private variable _fileroot
	private variable _runLabel
	private variable _energyLabels
	private variable _startFrame

	#calculated variables
	private variable _fullWedgePattern
	private variable _fullWedgeFramesPerLevel
	private variable _fragmentWedgePattern
	private variable _fragmentWedgeFramesPerLevel
	private variable _fragmentStartIndex
	private variable _totalFrames
	private variable _numCompleteWedges
	private variable _numComponents
	private variable _framesPerWedge
	private variable _inverseStartFrame
	private variable _framesPerPhiWedge
	private variable _numEnergies

	#public variables (no calculations use these, should be put in a parent class)
	public variable runStatus
	public variable fileroot
	public variable directory
	public variable exposureTime
	public variable distance
	public variable beamStop
	public variable axisMotor
	public variable modeIndex
	public variable nextFrame
	public variable enabled
	public variable energyList

	#public methods
	public method setRunDefinition { startAngle endAngle delta wedgeSize inverseOn numEnergy energies fileroot runLabel energyLabels startFrame  } {}
	public method listAllFrames { } {}

	public method getMotorPositionsAtIndex { index }
	private method calculateOffsetsAtIndex { index }
	public method getTotalFrames {} { return $_totalFrames }
	public method getDelta {} { return $_delta }
	public method getStartAngle {} { return $_startAngle }
	public method getNumEnergies {} { return $_numEnergies }
	public method getRunLabel {} { return $_runLabel }
	public method getStartFrame {} { return $_startFrame }
	public method getWedgeSize {} { return $_wedgeSize }
	public method getInverseMode {} { return $_inverseOn }
	public method getFileRoot {} { return $_fileroot }
	public method getEndAngle {} { return $_endAngle }
}

::itcl::body runCalculator::setRunDefinition { startAngle endAngle delta wedgeSize inverseOn numEnergy energies fileroot runLabel energyLabels startFrame } {
	set _startAngle $startAngle
	set _endAngle $endAngle
	set _delta $delta
	set _wedgeSize $wedgeSize
	set _inverseOn $inverseOn
	set _energies $energies

	set _numEnergies $numEnergy
	if { $_numEnergies > [llength $energies] } {
		log_error "Not enough energy positions."
	}

	#used for generating filenames
	set _runLabel $runLabel
	set _energyLabels $energyLabels
	set _startFrame $startFrame
	set _fileroot $fileroot
	set _numComponents 2	


	#calculate the number of phi-slices in a wedge
	set _framesPerPhiWedge [expr int ( ($wedgeSize + 0.0000001) / double( $delta)) ]

	#define the data collection sequence while inside a complete wedge
	set _fullWedgePattern [list $_framesPerPhiWedge [expr $inverseOn + 1 ] $_numEnergies] 

	set fullWedgeFramesPerLevel [calculateFramesPerComponentLevel $_fullWedgePattern]

	#log_note "fullWedgeFramesPerLevel $fullWedgeFramesPerLevel"

	set _numCompleteWedges [expr int(( $endAngle - $startAngle )/ $wedgeSize + 0.00001)]

	set cnt 0
	foreach frameSize $fullWedgeFramesPerLevel {
		set _fullWedgeFramesPerLevel($cnt) $frameSize
		incr cnt
	}

	#define the data collection sequence while within a wedge fragment
	set framesPerPhiRun [expr int( ( $_endAngle - $_startAngle +0.000001)/ double($_delta) + 0.00001 ) ]
	#log_note "int (  $_endAngle - $_startAngle ) / double($_delta) ) = $framesPerPhiRun "

	#log_note "framesPerPhiRun $framesPerPhiRun"
	#set framesPerPhiRunFragment [expr $framesPerPhiRun % $_framesPerPhiWedge]
	set framesPerPhiRunFragment [expr $framesPerPhiRun - $_framesPerPhiWedge * $_numCompleteWedges ]
	#log_note "framesPerPhiRunFragment $framesPerPhiRunFragment"

	set _fragmentWedgePattern [list $framesPerPhiRunFragment [expr $inverseOn + 1 ] $_numEnergies] 
	set fragmentWedgeFramesPerLevel [calculateFramesPerComponentLevel $_fragmentWedgePattern]

	#log_note "framesPerPhiRunFragment $framesPerPhiRunFragment"
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


	set framesPer180 [expr int (180.00001 / double($_delta) ) ]
	#puts " framesPer180: $framesPer180         framesPerPhiRun: $framesPerPhiRun" 
	set framesPer360 [expr $framesPer180 * 2 ]
	set inverseJumpFrameIndex [expr int( ( double($framesPerPhiRun + $framesPer180 - 0.9999999) ) / double($framesPer360) + 0.000001 ) + 1]

	#puts "************ framesPer360: $framesPer360, framesPerPhiRun $framesPerPhiRun, inverseJumpFrameIndex:   $inverseJumpFrameIndex "

	set _inverseStartFrame [expr $inverseJumpFrameIndex * $framesPer360  - $framesPer180 + $_startFrame  ]
	#log_note $_inverseStartFrame

	return
}


::itcl::body runCalculator::calculateOffsetsAtIndex { index } {

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
::itcl::body runCalculator::getMotorPositionsAtIndex { index } {

	set result [calculateOffsetsAtIndex $index ]

	#if we are not in a wedge fragment
	if { $index < $_fragmentStartIndex } {
		set completedWedges [lindex $result 0]
	} else {
		set completedWedges $_numCompleteWedges
	}
	set completedPhi [lindex $result 3]
	set completedInverse [lindex $result 2]
	set completedEnergies [lindex $result 1]

	#calculate phi position
	#puts "*************Completed Phi: $completedPhi Completed Wedges:  $completedWedges"
	set phi [expr $_startAngle + $completedPhi * $_delta + 180.0 * $completedInverse \
					 + $completedWedges * $_wedgeSize]

	#calculate energy position
	set energy [lindex $_energies $completedEnergies]

	#calculate label
	set energyLabel [lindex $_energyLabels $completedEnergies]

	#puts "$completedWedges $completedPhi"
	if { $completedInverse == 0 } {
		set frameLabel [expr $_startFrame + $completedPhi + $completedWedges * $_framesPerPhiWedge]
	} else {
		set frameLabel [expr $_inverseStartFrame + $completedPhi + $completedWedges * $_framesPerPhiWedge]
	}

	#format the string
#	if { $_totalFrames > 999 } {
#		set frameFormat "%04d"
#	} else {
		set frameFormat "%03d"
#	}
	
	if  { $_numEnergies > 1} {
		set filename [format "%s_%s_%s_$frameFormat" $_fileroot $_runLabel $energyLabel $frameLabel]
	} else {
		set filename [format "%s_%s_$frameFormat" $_fileroot $_runLabel $frameLabel]
	}

	return [format "%s %6.2f %8.2f" $filename [expr $phi - 360.0 * int($phi/360.0)] $energy]
}

#Returns a list of all frames in a defined run.
::itcl::body runCalculator::listAllFrames { } {
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
