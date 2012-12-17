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
	private variable _rootLabel
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

	#public methods
	public method setRunDefinition { startAngle endAngle delta wedgeSize inverseOn energies rootLabel runLabel energyLabels startFrame  } {}
	public method listAllFrames { } {}

	private method getMotorPositionsAtIndex { index }
	private method calculateOffsetsAtIndex { index }
}

::itcl::body runCalculator::setRunDefinition { startAngle endAngle delta wedgeSize inverseOn energies	rootLabel runLabel energyLabels startFrame } {
	set _startAngle $startAngle
	set _endAngle $endAngle
	set _delta $delta
	set _wedgeSize $wedgeSize
	set _inverseOn $inverseOn
	set _energies $energies
	set _numEnergies [llength $energies]
	
	#used for generating filenames
	set _runLabel $runLabel
	set _energyLabels $energyLabels
	set _startFrame $startFrame
	set _rootLabel $rootLabel
	set _numComponents 2	


	#calculate the number of phi-slices in a wedge
	set _framesPerPhiWedge [expr int ( $wedgeSize / $delta) ]

	#define the data collection sequence while inside a complete wedge
	set _fullWedgePattern [list $_framesPerPhiWedge [expr $inverseOn ] $_numEnergies] 

	set fullWedgeFramesPerLevel [calculateFramesPerComponentLevel $_fullWedgePattern]

	log_note "fullWedgeFramesPerLevel $fullWedgeFramesPerLevel"

	set _numCompleteWedges [expr int(( $endAngle - $startAngle )/ $wedgeSize)]

	set cnt 0
	foreach frameSize $fullWedgeFramesPerLevel {
		set _fullWedgeFramesPerLevel($cnt) $frameSize
		incr cnt
	}

	#define the data collection sequence while within a wedge fragment
	set framesPerPhiRun [expr int( ( $_endAngle - $_startAngle )/ double($_delta) ) ]
	log_note "framesPerPhiRun $framesPerPhiRun"
	#set framesPerPhiRunFragment [expr $framesPerPhiRun % $_framesPerPhiWedge]
	set framesPerPhiRunFragment [expr $framesPerPhiRun - $_framesPerPhiWedge * $_numCompleteWedges ]
	log_note "framesPerPhiRunFragment $framesPerPhiRunFragment"

	set _fragmentWedgePattern [list $framesPerPhiRunFragment [expr $inverseOn ] [llength $energies]] 
	set fragmentWedgeFramesPerLevel [calculateFramesPerComponentLevel $_fragmentWedgePattern]

	log_note "framesPerPhiRunFragment $framesPerPhiRunFragment"
	log_note "fragmentWedgeFramesPerLevel $fragmentWedgeFramesPerLevel"

	set cnt 0
	foreach frameSize $fragmentWedgeFramesPerLevel {
		set _fragmentWedgeFramesPerLevel($cnt) $frameSize
		incr cnt
	}

	#calculate the index to first frame of the wedge fragment
	set _framesPerWedge $_fullWedgeFramesPerLevel($_numComponents)
	

	set _fragmentStartIndex [expr $_framesPerWedge * $_numCompleteWedges ]
	log_note "startIndex $_fragmentStartIndex"

	#calculate the total number of frames in the run
	set _totalFrames [expr $_framesPerWedge * $_numCompleteWedges + $_fragmentWedgeFramesPerLevel($_numComponents) ]


	set framesPer180 [expr int (180.0 / double($_delta) ) ]
	log_note "$framesPer180 $framesPerPhiRun" 
	set framesPer360 [expr $framesPer180 * 2 ]
	set inverseJumpFrameIndex [expr int( ( double($framesPerPhiRun + $framesPer180 -1) ) / double($framesPer360) ) + 1]

	set _inverseStartFrame [expr $inverseJumpFrameIndex * $framesPer360  - $framesPer180 + $_startFrame ]
	log_note $_inverseStartFrame

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

::itcl::body runCalculator::getMotorPositionsAtIndex { index } {

	set result [calculateOffsetsAtIndex $index ]
	if { $index < $_fragmentStartIndex } {
		set completedWedges [lindex $result 0]
	} else {
		set completedWedges $_numCompleteWedges
	}
	set completedPhi [lindex $result 3]
	set completedInverse [lindex $result 2]
	set completedEnergies [lindex $result 1]
	set phi [expr $_startAngle + $completedPhi * $_delta + 180.0 * $completedInverse \
					 + $completedWedges * $_wedgeSize]
	set energy [lindex $_energies $completedEnergies]

	set energyLabel [lindex $_energyLabels $completedEnergies]

	#puts "$completedWedges $completedPhi"
	if { $completedInverse == 0 } {
		set frameLabel [expr $_startFrame + $completedPhi + $completedWedges * $_framesPerPhiWedge]
	} else {
		set frameLabel [expr $_inverseStartFrame + $completedPhi + $completedWedges * $_framesPerPhiWedge]
	}

	#puts $_numEnergies
	if  { $_numEnergies > 1} {
		set filename [format "%s_%s_%s_%03d" $_rootLabel $_runLabel $energyLabel $frameLabel]
	} else {
		set filename [format "%s_%s_%03d" $_rootLabel $_runLabel $frameLabel]
	}

	return [format "%s %6.1f %8.2f" $filename [expr $phi - 360.0 * int($phi/360.)] $energy]
}


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


#runCalculator run0
#run0 setRunDefinition 0.0 362.0 2.0 180.0 2 {1200} test 0 {E1 E2 E3} 1

#puts [time {set result [run0 listAllFrames]}]
#puts [llength $result]

#foreach frame $result  {
#	puts $frame
#}
