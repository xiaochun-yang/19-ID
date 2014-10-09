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
##########################################################################
#
#                       Permission Notice
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
# BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
##########################################################################


# provide the DCSDevice package
package provide DCSRunDefinition 1.0  

package require DCSDevice

## for TrimStringForXXXXX
package require DCSSpreadsheet

package require DCSDeviceFactory
package require DCSRunField

# load standard packages
#package require Iwidgets

class DCS::RunString {
	
	# inheritance
	inherit DCS::String

	public method setContents

	public method configureString

	public variable endFrame
	public variable summaryText
    public variable dirOK 0

    public common m_objRunsConfig "::device::runsConfig"

    public method getXppPulse { } {
        set t [getField exposure_time]
        if {$t == 0} {
            return 1
        }
        return [expr int(round($t * 120))]
    }
    public method setXppPulse { n } {
        set t [expr $n / 120.0]
        setField exposure_time $t
    }

    public method getField { name } {}
    public method setField { name value } {}
    public method getList { args } {}
    public method setList { args } {}

	public method setFileRoot
	public method setDirectory
	public method setDetectorMode
	public method setDistance
	public method setAttenuation
	public method setBeamStop
	public method setAxis
	public method setDelta
	public method setExposureTime
	public method setInverse
	public method setStartFrame
	public method setStartAngle
	public method setEndAngle
	public method setEndFrame
	public method setWedgeSize
	public method setEnergyList
	public method setNextFrame
   public method reset

   public method resetRun 
	
	public method handleRunDefinitionChange
	public method calculateEndFrame
   public method getNeedsResetStatus
	public method getAxisChoices
   public method getRunIndex
   public method getSummaryText

   private method adjustWedgeSize 

	# call base class constructor
	constructor { args } {
		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 status {getField status} \
					 contents { getContents } \
					 fileRoot {getField file_root } \
					 directory { getField directory } \
					 detectorMode { getField detector_mode } \
					 axis	{ getField axis_motor } \
					 delta { getField delta } \
					 exposureTime { getField exposure_time } \
                     pulse { getXppPulse }
					 inverse { getField inverse_on } \
					 startFrame { getField start_frame } \
					 startAngle { getField start_angle } \
					 endAngle { getField end_angle } \
					 wedgeSize { getField wedge_size } \
					 endFrame { cget -endFrame } \
					 summary { cget -summaryText }
					 needsReset { getNeedsResetStatus } \
                     dirOK { cget -dirOK } \
			 }
	} {
      createAttributeFromField state 0
      createAttributeFromField runLabel 2

		eval configure $args
      
        handleRunDefinitionChange $::DCS::RunField::DEFAULT

		announceExist
	}
}
body DCS::RunString::getField { name } {
    return [::DCS::RunField::getField _contents $name]
}
body DCS::RunString::setField { name value } {
    ::DCS::RunField::setField _contents $name $value
	sendContentsToServer $_contents
}
body DCS::RunString::getList { args } {
    return [eval ::DCS::RunField::getList _contents $args]
}
body DCS::RunString::setList { args } {
    eval ::DCS::RunField::setList _contents $args
	sendContentsToServer $_contents
}

body DCS::RunString::configureString { message_ } {
    #puts "config string $message_"
	configure -controller  [lindex $message_ 2] 
	set contents [lrange $message_ 3 end]

    setContents normal $contents
}

body DCS::RunString::setContents { status_ contents_ } {
    set lastResult $status_
    if {$lastResult == "normal"} {
	    handleRunDefinitionChange $contents_

	    #inform that new configuration is available
	    updateRegisteredComponents status
	    updateRegisteredComponents contents
	    updateRegisteredComponents fileRoot
	    updateRegisteredComponents directory
	    updateRegisteredComponents detectorMode
	    updateRegisteredComponents axis
	    updateRegisteredComponents delta
	    updateRegisteredComponents inverse
	    updateRegisteredComponents exposureTime
	    updateRegisteredComponents pulse
	    updateRegisteredComponents startFrame
	    updateRegisteredComponents startAngle
	    updateRegisteredComponents endAngle
	    updateRegisteredComponents endFrame
	    updateRegisteredComponents wedgeSize
	    updateRegisteredComponents needsReset
	    updateRegisteredComponents summary 
	    updateRegisteredComponents dirOK

	    updateRegisteredFieldListeners
    }

	recalcStatus
}

body DCS::RunString::handleRunDefinitionChange { runDefinition_ } {
	#puts "runString: rundef: $runDefinition_"

    set _contents $runDefinition_

    #### adjust
    foreach {runStatus runLabel} [getList status run_label] break

    if {[getRunIndex] == 0 && \
    $runStatus != "collecting" && \
    $runStatus != "inactive" } {
        puts "SHOULD NOT HAPPEN ANYMORE"
        puts "run0 ends up with $runStatus"
        ### just update local, not sending to server
        set runStatus inactive
        ::DCS::RunField::setField _contents status $runStatus
        puts "run0 local copy changed to inactive"
    }

    ##### derive
	set endFrame [calculateEndFrame]
    if {[getRunIndex] == 0} {
        set summaryText "Snapshot ( $runStatus )"
    } else {
        set summaryText "Run $runLabel ( $runStatus )"
    }

    set dir [getField directory]
    set dirOK 1
    set eList [file split $dir]
    foreach e $eList {
        if {[string equal -nocase $e username]} {
            set dirOK 0
            break
        }
    }
    #puts "dirOK $dirOK"
}

body DCS::RunString::calculateEndFrame { } {
    foreach {startAngle endAngle delta startFrame} \
    [getList start_angle end_angle delta start_frame] break

    if {$delta == 0} {
        return $startFrame
    }

    return [ expr int( ($endAngle - $startAngle ) / ($delta) -0.01 + $startFrame ) ]
}



#get the alias for the motor names
body DCS::RunString::getNeedsResetStatus {} {
    set runStatus [getField status]
	
	if {$runStatus == "complete" || $runStatus == "paused"} {return 1}

   return 0
}

#get the list of alias motors
body DCS::RunString::getAxisChoices { } {
   set choices [list Phi]

   if {! [ [DCS::DeviceFactory::getObject] deviceExists ::device::gonio_omega]} {return $choices}
   if {[::device::gonio_omega cget -locked] == 0} {
      lappend choices Omega
   }
   return $choices
}

body DCS::RunString::setFileRoot { fileRoot_  } {
    setField file_root $fileRoot_
}

body DCS::RunString::setDirectory { directory_  } {
    setField directory $directory_
}

body DCS::RunString::setDetectorMode { detectorMode_  } {
    setField detector_mode $detectorMode_
}

body DCS::RunString::setDistance { distance_  } {
    setField distance $distance_
}

body DCS::RunString::setAttenuation { att_  } {
    setField attenuation $att_
}

body DCS::RunString::setBeamStop { beamStop_ } {
    setField beam_stop $beamStop_
}

body DCS::RunString::reset {} {
    setList status inactive next_frame 0
}

body DCS::RunString::resetRun {} {
    set user [$controlSystem getUser]
    $m_objRunsConfig startOperation \
    $user resetRun [getRunIndex] [getDefaultDataDirectory $user]
}


body DCS::RunString::setAxis { axis_ } {
    set name_value_list [list axis_motor $axis_]
	if { $axis_ == "Omega" } {
        set startAngle_ [lindex [::device::gonio_omega cget -scaledPosition] 0] 
        lappend name_value_list start_angle $startAngle_ inverse_on 0
	} else {
        set startAngle_ [lindex [::device::gonio_phi cget -scaledPosition] 0]
        lappend name_value_list start_angle $startAngle_
	}
    foreach {startFrame delta} [getList start_frame delta] break

	set endAngle_ [expr ( $endFrame - $startFrame + 1) * $delta + $startAngle_ ]

    lappend name_value_list end_angle $endAngle_
    eval setList $name_value_list
}

#returns a value for an adjusted wedgesize
body DCS::RunString::adjustWedgeSize { wedgeSize_ delta_ } {
   if {$delta_ == 0} {
       return $wedgeSize_
   }
   if { $delta_ > $wedgeSize_ } {
      return $delta_
   } else {
	   return [expr int($wedgeSize_/$delta_) * $delta_ ]
   }
}

body DCS::RunString::setDelta { delta_ } {

	if { $delta_ > 179.99 } {
		set delta_ 179.99
        log_error delta resetted to $delta_
	}
	
    ### dcss has check to take out 0.0 if not allowed
	if { $delta_ < 0.0 } {
		set delta_ 0.01
        log_error delta resetted to $delta_
	}

    foreach {wedgeSize startFrame startAngle} \
    [getList wedge_size start_frame start_angle] break
	set wedgeSize_ [adjustWedgeSize $wedgeSize $delta_]
	set endAngle_ [expr ( $endFrame - $startFrame + 1) * $delta_ + $startAngle ]

    setList delta $delta_ wedge_size $wedgeSize_ end_angle $endAngle_
}


body DCS::RunString::setInverse { inverse_ } {
    setField inverse_on $inverse_
}


body DCS::RunString::setExposureTime { exposureTime_ } {
    setField exposure_time $exposureTime_
}

body DCS::RunString::setStartFrame { startFrame_ } {

	if { $startFrame_ <= 0} {
		set startFrame_ 1
	}

    foreach {startAngle delta} [getList start_angle delta] break
    
	if { $endFrame < $startFrame_ } {
		set endFrame $startFrame_
	}

	#recalculate the end angle
	set endAngle_ [expr ( $endFrame - $startFrame_ + 1) * $delta + $startAngle ] 
    setList start_frame $startFrame_ end_angle $endAngle_
}

body DCS::RunString::setStartAngle { startAngle_ } {
    foreach {startFrame delta} [getList start_frame delta] break

	set endAngle_ [expr ( $endFrame - $startFrame + 1) * $delta + $startAngle_ ]
    setList start_angle $startAngle_ end_angle $endAngle_
}

body DCS::RunString::setEndAngle { endAngle_ } {
    foreach {startFrame startAngle delta} \
    [getList start_frame start_angle delta] break

	if { $endAngle_ <= $startAngle } {
		set endAngle_ [expr $startAngle + $delta]
	}

	set endFrame [expr int(( $endAngle_ - $startAngle) / $delta -0.01 + $startFrame ) ]
	set endAngle_ [expr ( $endFrame - $startFrame + 1) * $delta + $startAngle ]
    setField end_angle $endAngle_
}

body DCS::RunString::setEndFrame { endFrame_ } {
    foreach {startFrame startAngle delta } \
    [getList start_frame start_angle delta] break

	if { $endFrame_ < $startFrame } {
		set endFrame_ $startFrame
	}
		
	set endAngle_ [expr ( $endFrame_ - $startFrame + 1) * $delta + $startAngle ] 
    setField end_angle $endAngle_
}


body DCS::RunString::setWedgeSize { wedgeSize_ } {
    set delta [getField delta]

	set wedgeSize_ [adjustWedgeSize $wedgeSize_ $delta]

    setField wedge_size $wedgeSize_
}

body DCS::RunString::setEnergyList { energyList_ } {

	set numEnergy_ [llength $energyList_]

	set energy1 0.0
	set energy2 0.0
	set energy3 0.0
	set energy4 0.0
	set energy5 0.0

	set cnt 1
	foreach energyEntry $energyList_ {
		set energy$cnt $energyEntry
		incr cnt
	}
    setList \
    num_energy $numEnergy_ \
    energy1 $energy1 \
    energy2 $energy2 \
    energy3 $energy3 \
    energy4 $energy4 \
    energy5 $energy5
}

body DCS::RunString::setNextFrame { nextFrame_ } {

    set runStatus [getField status]
    if {$runStatus == "complete" } {
        setField status paused
    }
    setField next_frame $nextFrame_
} 

body DCS::RunString::getRunIndex { } {
   #strip off the ::device::run at the beginning, return the number
   return [string range $this [expr [string first run $this] + 3] end]
}



#The run list string has the following tokens:
# 0: runCount 
# 1: currentRun
# 2: doseMode
class DCS::RunListString {
	# inheritance
	inherit DCS::String

	public method setContents
	public method configureString
   public method addNewRun	
   public method deleteRun
   public method getMaxRunCount {} {return $MAX_RUN}

   public method getRunCount {} {return $m_runCount }
   public method getCurrentRun {} {return $m_currentRun }
   public method getDoseMode {} {return $m_doseMode }
   public method setDoseMode
   public method resetAllRuns 

   private variable m_runCount 0
   private variable m_currentRun 0
   private variable m_doseMode 0

    private common MAX_RUN 17
    public common m_objRunsConfig "::device::runsConfig"

	# call base class constructor
	constructor { args } {
		
		# call base class constructor
		::DCS::Component::constructor \
         { \
            status {cget -status} \
            runCount { getRunCount } \
            currentRun { getCurrentRun } \
            doseMode { getDoseMode } \
            contents	{ getContents }
			 }
   } {
      eval configure $args

      set _contents "0 0 0 0"

		announceExist
	}

}

body DCS::RunListString::configureString { message_ } {
    #puts "runs: config : $message_"
	configure -controller  [lindex $message_ 2] 
	set contents [lrange $message_ 3 end]

    setContents normal $contents
}

body DCS::RunListString::setContents { status_ contents_ } {
    set lastResult $status_
    if {$lastResult == "normal"} {
        set _contents $contents_
        #parse the message into the object data
        foreach {m_runCount m_currentRun m_doseMode} $_contents break
	
	    #inform that new configuration is available
	    updateRegisteredComponents contents
	    updateRegisteredComponents runCount 
	    updateRegisteredComponents currentRun
	    updateRegisteredComponents doseMode
	    updateRegisteredFieldListeners
    }

	recalcStatus
}

body DCS::RunListString::setDoseMode { doseMode_ } {
 
   set runListDefinition [getContents]

   set newRunListDef [lreplace $runListDefinition 2 2 $doseMode_]
   sendContentsToServer $newRunListDef
}


body DCS::RunListString::addNewRun {} {
    $m_objRunsConfig startOperation [$controlSystem getUser] addNewRun
}


body DCS::RunListString::deleteRun { run_ } {
    $m_objRunsConfig startOperation [$controlSystem getUser] deleteRun $run_
}

body DCS::RunListString::resetAllRuns { } {
    $m_objRunsConfig startOperation [$controlSystem getUser] resetAllRuns
}

####################################################################
### 01/15/10
### This is a virtual string.  Only exists in BluIce, not in dcss.
### Each BluIce will have one, representing the current run it is
### showing.
###
### It will get update from SIL and from the real run string for
### queue.
###
### It sends setting only to SIL.
###
### 01/22/10
### The DCSS will have one run string for the queue.
### It is only valid when the system is doing the queue tasks.
### It can avoid BluIce to access the SIL server too frequently
### when the system is collecting diffraction images.
####################################################################

##### The real and virtural will use the same
##### class.

class DCS::VirtualQueueRunString {
	# inheritance
	inherit DCS::String

	public method setContents

    public method setIsTrueString { bool } {
        set m_isTrueString $bool
    }

	public method configureString

    ## for change contents from System Data in BluIce
	public method sendContentsToServer { contents } {
        if {$m_isTrueString} {
            DCS::String::sendContentsToServer $contents
        } else {
            ###DEBUG: remove this one after debug
            setContents normal $contents
        }
    }

	public variable endFrame
	public variable summaryText
    public variable dirOK 0
	public variable silMapped

    public method getField { name } {}
    public method setField { name value } {}
    public method getList { args } {}
    public method setList { args } {}

    public method deleteThis { }

    public method getID { } {
        return [getList sil_id row_id unique_id run_id]
    }

    public method setID {sil_id_ row_id_ unique_id_ run_id_ } {
        ##### should be used only for debug
        ##### cannot send to sil.  run in sil does not have these
        puts "setID called for $this: $sil_id_ $row_id_ $unique_id_ $run_id_"
        set result [::DCS::RunFieldForQueue:setList _contents \
        sil_d $sil_id_ \
        row_id $row_id_ \
        unique_id $unique_id_ \
        run_id $run_id_]

        set silMapped [calculateSilMapped]

	    updateRegisteredComponents contents
	    updateRegisteredComponents silMapped

        return $result
    }

	public method setFileRoot
	public method setDirectory
	public method setDetectorMode
    public method setResolutionMode
    public method setResolution
	public method setDistance
    public method setDoseMode
    public method setPhotonCount
	public method setAttenuation
	public method setExposureTime
	public method setBeamStop
	public method setAxis
	public method setDelta
	public method setInverse
	public method setStartFrame
	public method setStartAngle
	public method setEndAngle
	public method setEndFrame
	public method setWedgeSize
	public method setEnergyList
	public method setNextFrame
    public method reset

    public method setBeamWidth
    public method setBeamHeight
    public method setPositionId

	public method handleRunDefinitionChange
	public method calculateEndFrame
    public method getNeedsResetStatus
	public method getAxisChoices
    public method getSummaryText

    ##not sure this is the right place to implement these.
    ##they need gMotorHorz gMotorVert
    private method calculateDistance
    private method calculateResolution
    private method checkDistance
    private method adjust { name valueRef }

    private method adjustWedgeSize 

    private method calculateSilMapped

    private variable m_isTrueString 0

	# call base class constructor
	constructor { args } {
		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 pid {getField position_id} \
					 status {getField status} \
					 contents { getContents } \
					 fileRoot {getField file_root } \
					 directory { getField directory } \
					 detectorMode { getField detector_mode } \
                     resolutionMode { getField resolution_mode } \
					 axis	{ getField axis_motor } \
					 delta { getField delta } \
                     doseMode { getField dose_mode } \
                     photonCount { getField photon_count } \
					 exposureTime { getField exposure_time } \
					 inverse { getField inverse_on } \
					 startFrame { getField start_frame } \
					 startAngle { getField start_angle } \
					 endAngle { getField end_angle } \
					 wedgeSize { getField wedge_size } \
					 endFrame { cget -endFrame } \
					 summary { cget -summaryText }
					 silMapped { cget -silMapped }
					 needsReset { getNeedsResetStatus } \
                     dirOK { cget -dirOK } \
			 }
	} {
        createAttributeFromField state 5
        createAttributeFromField runLabel 7

      
        handleRunDefinitionChange $::DCS::RunFieldForQueue::DEFAULT

		eval configure $args

		announceExist
	}
}
body DCS::VirtualQueueRunString::getField { name } {
    return [::DCS::RunFieldForQueue::getField _contents $name]
}
body DCS::VirtualQueueRunString::adjust { name valueRef } {
    upvar $valueRef value

    switch -exact -- $name {
        "distance" {
            set oldValue $value
            if {![isDistanceOK value]} {
                log_error distance adjusted to $value
                return 0
            }
        }
        "exposure_time" {
            set oldValue $value
            if {![isTimeOK value]} {
                log_error exposure time adjusted to $value
                return 0
            }
        }
        "attenuation" {
            set oldValue $value
            if {![isAttenuationOK value]} {
                log_error attenuation adjusted to $value
                return 0
            }
        }
        "resolution" {
            foreach {mode cnt} [getList detector_mode num_energy] break
            set eList [getList energy1 energy2 energy3 energy4 energy5]

            for {set i 0} {$i < $cnt} {incr i} {
                set e [lindex $eList $i]
                set dt [checkDistance $e $value $mode]
                puts "for resolution=$value, energy$i dt=$dt"
                if {![isDistanceOK dt]} {
                    log_error resolution not satisfy energy[expr $i + 1] \
                    for distance limits
                    log_error resolution rollback to previous value
                    set value [getField resolution]
                    return 0
                }
            }
        }
        "resolution_mode" {
            if {$value == "1"} {
                foreach {mode rn cnt} \
                [getList detector_mode resolution num_energy] break

                set eList [getList energy1 energy2 energy3 energy4 energy5]

                for {set i 0} {$i < $cnt} {incr i} {
                    set e [lindex $eList $i]
                    set dt [checkDistance $e $rn $mode]
                    puts "for resolution=$rn, energy$i dt=$dt"
                    if {![isDistanceOK dt]} {
                        log_error resolution not satisfy energy[expr $i + 1] \
                        for distance limits
                        log_error rollback to distance mode
                        set value 0
                        return 0
                    }
                }
            }
        }
    }
    return 1
}

body DCS::VirtualQueueRunString::setField { name value } {

    if {$m_isTrueString} {
        ::DCS::RunFieldForQueue::setField _contents $name $value
	    sendContentsToServer $_contents
    }

    if {[::DCS::RunFieldForQueue::fieldIsVirtual $name]} {
        if {!$m_isTrueString} {
            log_error run field $name is virtual, no need to update sil.
            puts "run field $name is virtual, no need to update sil."
        }
        return
    }
    if {!$silMapped} {
        if {!$m_isTrueString} {
            log_error skip run modify.  $this is not mapped to sil
            puts "skip run modify.  $this is not mapped to sil"
        }
        return
    }

    ############### check ########################
    adjust $name value

    ::DCS::RunFieldForQueue::setField _contents $name $value
    set data [list $name $value]

    ############### extra ########################
    if {[::DCS::RunFieldForQueue::fieldNeedExtraUpdateDistance $name]} {
        set r_mode [getField resolution_mode]
        if {$r_mode == "1"} {
            lappend data distance [calculateDistance]
            log_warning update distance too
        } else {
            lappend data resolution [calculateResolution]
            log_warning update resolution too
        }
    }
    if {[::DCS::RunFieldForQueue::fieldNeedExtraUpdateTime $name]} {
        ##TODO:
    }

    set data [eval http::formatQuery $data]

    set usr [$controlSystem getUser]
    set SID [$controlSystem getSessionId]
    foreach {sil row unique index} [getID] break

    return [modifyRunDefinitionForQueue \
    $usr $SID \
    $sil $row $unique $index \
    $data $m_isTrueString]
}
body DCS::VirtualQueueRunString::calculateDistance { } {
    foreach {e rn mode} [getList energy1 resolution detector_mode] break
    return [checkDistance $e $rn $mode]
}
body DCS::VirtualQueueRunString::checkDistance { e rn mode } {
    global gMotorHorz
    global gMotorVert

    set offsetH [lindex [::device::$gMotorHorz getScaledPosition] 0]
    set offsetV [lindex [::device::$gMotorVert getScaledPosition] 0]

    set objDetector [::DCS::Detector::getObject]
    return [$objDetector calculateDistance $rn $e $mode $offsetH $offsetV]
}
body DCS::VirtualQueueRunString::calculateResolution { } {
    global gMotorHorz
    global gMotorVert

    set offsetH [lindex [::device::$gMotorHorz getScaledPosition] 0]
    set offsetV [lindex [::device::$gMotorVert getScaledPosition] 0]
    foreach {e dt mode} [getList energy1 distance detector_mode] break

    set objDetector [::DCS::Detector::getObject]
    return [$objDetector calculateResolution $dt $e $mode $offsetH $offsetV]
}
body DCS::VirtualQueueRunString::deleteThis { } {
    ::DCS::RunFieldForQueue::setField _contents status deleted

    if {$m_isTrueString} {
	    log_error cannot delete real string $this 
        return
    }

    if {!$silMapped} {
        log_error skip run modify.  $this is not mapped to sil
        puts "skip run modify.  $this is not mapped to sil"
        return
    }

    set usr [$controlSystem getUser]
    set SID [$controlSystem getSessionId]
    foreach {sil row unique index} [getID] break

    return [deleteRunDefinitionForQueue \
    $usr $SID \
    $sil $row $unique $index \
    ]
}
body DCS::VirtualQueueRunString::getList { args } {
    return [eval ::DCS::RunFieldForQueue::getList _contents $args]
}
body DCS::VirtualQueueRunString::setList { args } {
    eval ::DCS::RunFieldForQueue::setList _contents $args

    if {$m_isTrueString} {
	    sendContentsToServer $_contents
    } else {
        ##DEBUG: to update the stringView display from System Data
        ##DEBUG: remove after url working
        #setContents normal $_contents
    }

    if {!$silMapped} {
        if {!$m_isTrueString} {
            log_error skip run modify.  $this is not mapped to sil
            puts "skip run modify.  $this is not mapped to sil"
        }
        return
    }

    set data [list]

    set needExtraDistance 0
    set needExtraTime 0

    foreach {name value} $args {
        if {[::DCS::RunFieldForQueue::fieldIsVirtual $name]} {
            if {!$m_isTrueString} {
                log_error run field $name is virtual, \
                skipped setting $name to $value.
                puts "run field $name is virtual, skipped."
            }
        } else {
            lappend data $name $value
        }
        if {[::DCS::RunFieldForQueue::fieldNeedExtraUpdateDistance $name]} {
            set needExtraDistance 1
        }
        if {[::DCS::RunFieldForQueue::fieldNeedExtraUpdateTime $name]} {
            set needExtraTime 1
        }
    }
    if {$needExtraDistance} {
        set r_mode [getField resolution_mode]
        if {$r_mode == "1"} {
            lappend data distance [calculateDistance]
            log_warning update distance too
        } else {
            lappend data resolution [calculateResolution]
            log_warning update resolution too
        }
    }

    if {[llength $data] == 0} {
        log_warning all fields skipped, no modifu at all.
        return
    }
    set usr [$controlSystem getUser]
    set SID [$controlSystem getSessionId]
    foreach {sil row unique index} [getID] break

    set data [eval http::formatQuery $data]

    return [modifyRunDefinitionForQueue \
    $usr $SID \
    $sil $row $unique $index \
    $data $m_isTrueString]
}

body DCS::VirtualQueueRunString::configureString { message_ } {
	configure -controller  [lindex $message_ 2] 
	set contents [lrange $message_ 3 end]

    setContents normal $contents
}

body DCS::VirtualQueueRunString::setContents { status_ contents_ } {
    set lastResult $status_
    if {$lastResult == "normal"} {

	    handleRunDefinitionChange $contents_

	    #inform that new configuration is available
	    updateRegisteredComponents status
	    updateRegisteredComponents contents
	    updateRegisteredComponents fileRoot
	    updateRegisteredComponents directory
	    updateRegisteredComponents detectorMode
	    updateRegisteredComponents resolutionMode
	    updateRegisteredComponents detectorMode
	    updateRegisteredComponents axis
	    updateRegisteredComponents delta
	    updateRegisteredComponents inverse
	    updateRegisteredComponents exposureTime
	    updateRegisteredComponents doseMode
	    updateRegisteredComponents photonCount
	    updateRegisteredComponents startFrame
	    updateRegisteredComponents startAngle
	    updateRegisteredComponents endAngle
	    updateRegisteredComponents endFrame
	    updateRegisteredComponents wedgeSize
	    updateRegisteredComponents needsReset
	    updateRegisteredComponents summary 
	    updateRegisteredComponents silMapped

	    updateRegisteredFieldListeners
    }

	recalcStatus
}

body DCS::VirtualQueueRunString::handleRunDefinitionChange { runDefinition_ } {
	#puts "runString: rundef: $runDefinition_"

    ##### base class
    set _contents $runDefinition_

    ##### derive
	set endFrame [calculateEndFrame]
    set silMapped [calculateSilMapped]
    foreach {runStatus runLabel} [getList status run_label] break
    set summaryText "Run $runLabel ( $runStatus )"

    set dir [getField directory]
    set dirOK 1
    set eList [file split $dir]
    foreach e $eList {
        if {[string equal -nocase $e username]} {
            set dirOK 0
            break
        }
    }
    ##puts "dirOK $dirOK"
}

body DCS::VirtualQueueRunString::calculateEndFrame { } {
    foreach {startAngle endAngle delta startFrame} \
    [getList start_angle end_angle delta start_frame] break

	return [ expr int( ($endAngle - $startAngle ) / ($delta) -0.01 + $startFrame ) ]
}
body DCS::VirtualQueueRunString::calculateSilMapped { } {
    foreach {sil row unique index} \
    [getList sil_id row_id unique_id run_id] break

    if {$sil < 0 || $row < 0 || $unique == "" || $index < 0} {
        return 0
    } else {
        return 1
    }
}

body DCS::VirtualQueueRunString::getNeedsResetStatus {} {
    set runStatus [getField status]
	
	if {$runStatus == "complete" || $runStatus == "paused"} {return 1}

    return 0
}

#get the list of alias motors
body DCS::VirtualQueueRunString::getAxisChoices { } {
    set choices [list Phi]

    if {![[DCS::DeviceFactory::getObject] deviceExists ::device::gonio_omega]} {
        return $choices
    }
    if {[::device::gonio_omega cget -locked] == 0} {
        lappend choices Omega
    }
    return $choices
}

body DCS::VirtualQueueRunString::setFileRoot { fileRoot_  } {
    setField file_root $fileRoot_
}

body DCS::VirtualQueueRunString::setDirectory { directory_  } {
    setField directory $directory_
}

body DCS::VirtualQueueRunString::setDetectorMode { detectorMode_  } {
    setField detector_mode $detectorMode_
}

body DCS::VirtualQueueRunString::setDoseMode { mode  } {
    setField dose_mode $mode
}

body DCS::VirtualQueueRunString::setPhotonCount { number  } {
    setField photon_count $number
}

body DCS::VirtualQueueRunString::setResolutionMode { mode  } {
    setField resolution_mode $mode
}

body DCS::VirtualQueueRunString::setResolution { res  } {
    setField resolution $res
}

body DCS::VirtualQueueRunString::setDistance { distance_  } {
    setField distance $distance_
}

body DCS::VirtualQueueRunString::setAttenuation { att_  } {
    setField attenuation $att_
}

body DCS::VirtualQueueRunString::setBeamStop { beamStop_ } {
    setField beam_stop $beamStop_
}

body DCS::VirtualQueueRunString::reset {} {
    setList status inactive next_frame 0
}

body DCS::VirtualQueueRunString::setAxis { axis_ } {
    set name_value_list [list axis_motor $axis_]
	if { $axis_ == "Omega" } {
        set startAngle_ [lindex [::device::gonio_omega cget -scaledPosition] 0] 
        lappend name_value_list start_angle $startAngle_ inverse_on 0
	} else {
        set startAngle_ [lindex [::device::gonio_phi cget -scaledPosition] 0]
        lappend name_value_list start_angle $startAngle_
	}
    foreach {startFrame delta} [getList start_frame delta] break

	set endAngle_ [expr ( $endFrame - $startFrame + 1) * $delta + $startAngle_ ]

    lappend name_value_list end_angle $endAngle_
    eval setList $name_value_list
}

#returns a value for an adjusted wedgesize
body DCS::VirtualQueueRunString::adjustWedgeSize { wedgeSize_ delta_ } {
   if { $delta_ > $wedgeSize_ } {
      return $delta_
   } else {
	   return [expr int($wedgeSize_/$delta_) * $delta_ ]
   }
}
body DCS::VirtualQueueRunString::setBeamWidth { w } {
    if {$m_isTrueString} {
        setField beam_width $w
    } else {
        log_error cannot set beam size for virtual run
    }
}
body DCS::VirtualQueueRunString::setBeamHeight { h } {
    if {$m_isTrueString} {
        setField beam_height $h
    } else {
        log_error cannot set beam size for virtual run
    }
}

body DCS::VirtualQueueRunString::setPositionId { index } {
    setField position_id $index
}

body DCS::VirtualQueueRunString::setDelta { delta_ } {

	if { $delta_ > 179.99 } {
		set delta_ 179.99
        log_error delta resetted to $delta_
	}
	
	if { $delta_ <= 0.0 } {
		set delta_ 0.01
        log_error delta resetted to $delta_
	}

    foreach {wedgeSize startFrame startAngle} \
    [getList wedge_size start_frame start_angle] break
	set wedgeSize_ [adjustWedgeSize $wedgeSize $delta_]
	set endAngle_ [expr ( $endFrame - $startFrame + 1) * $delta_ + $startAngle ]

    setList delta $delta_ wedge_size $wedgeSize_ end_angle $endAngle_
}


body DCS::VirtualQueueRunString::setInverse { inverse_ } {
    setField inverse_on $inverse_
}


body DCS::VirtualQueueRunString::setExposureTime { exposureTime_ } {
    setField exposure_time $exposureTime_
}

body DCS::VirtualQueueRunString::setStartFrame { startFrame_ } {

	if { $startFrame_ <= 0} {
		set startFrame_ 1
	}

    foreach {startAngle delta} [getList start_angle delta] break
    
	if { $endFrame < $startFrame_ } {
		set endFrame $startFrame_
	}

	#recalculate the end angle
	set endAngle_ [expr ( $endFrame - $startFrame_ + 1) * $delta + $startAngle ] 
    setList start_frame $startFrame_ end_angle $endAngle_
}

body DCS::VirtualQueueRunString::setStartAngle { startAngle_ } {
    foreach {startFrame delta} [getList start_frame delta] break

	set endAngle_ [expr ( $endFrame - $startFrame + 1) * $delta + $startAngle_ ]
    setList start_angle $startAngle_ end_angle $endAngle_
}

body DCS::VirtualQueueRunString::setEndAngle { endAngle_ } {
    foreach {startFrame startAngle delta} \
    [getList start_frame start_angle delta] break

	if { $endAngle_ <= $startAngle } {
		set endAngle_ [expr $startAngle + $delta]
	}

	set endFrame [expr int(( $endAngle_ - $startAngle) / $delta -0.01 + $startFrame ) ]
	set endAngle_ [expr ( $endFrame - $startFrame + 1) * $delta + $startAngle ]
    setField end_angle $endAngle_
}

body DCS::VirtualQueueRunString::setEndFrame { endFrame_ } {
    foreach {startFrame startAngle delta } \
    [getList start_frame start_angle delta] break

	if { $endFrame_ < $startFrame } {
		set endFrame_ $startFrame
	}
		
	set endAngle_ [expr ( $endFrame_ - $startFrame + 1) * $delta + $startAngle ] 
    setField end_angle $endAngle_
}


body DCS::VirtualQueueRunString::setWedgeSize { wedgeSize_ } {
    set delta [getField delta]

	set wedgeSize_ [adjustWedgeSize $wedgeSize_ $delta]

    setField wedge_size $wedgeSize_
}

body DCS::VirtualQueueRunString::setEnergyList { energyList_ } {

	set numEnergy_ [llength $energyList_]

	set energy1 0.0
	set energy2 0.0
	set energy3 0.0
	set energy4 0.0
	set energy5 0.0

	set cnt 1
	foreach energyEntry $energyList_ {
		set energy$cnt $energyEntry
		incr cnt
	}

    foreach {mode rn_on rn} \
    [getList detector_mode resolution_mode resolution] break

    if {$rn_on == "1"} {
        for {set i 1} {$i < $cnt} {incr i} {
            set e [set energy$i]
            set dt [checkDistance $e $rn $mode]
            puts "for resolution=$rn, energy$i dt=$dt"
            if {![isDistanceOK dt]} {
                log_error resolution CANNOT be moved to $rn for energy$i
                log_error rollback energy changes
                foreach {numEnergy_ energy1 energy2 energy3 energy4 energy5} \
                [getList num_energy energy1 energy2 energy3 energy4 energy5] \
                break

                break
            }
        }
    }
    

    setList \
    num_energy $numEnergy_ \
    energy1 $energy1 \
    energy2 $energy2 \
    energy3 $energy3 \
    energy4 $energy4 \
    energy5 $energy5
}

body DCS::VirtualQueueRunString::setNextFrame { nextFrame_ } {

    set runStatus [getField status]
    if {$runStatus == "complete" } {
        setList status paused next_frame $nextFrame_
    } else {
        setField next_frame $nextFrame_
    }
} 
