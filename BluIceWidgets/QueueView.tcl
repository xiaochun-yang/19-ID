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

package provide BLUICEQueueView 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSPrompt
package require DCSMotorControlPanel
package require DCSCheckbutton
package require DCSCheckbox
package require DCSAttribute
package require BLUICEDoseMode
package require BLUICERunSequenceView
package require DCSStrategyStatus
package require BLUICESamplePosition
package require BLUICEScoreView

#################################################################
#### for Queue
#################################################################

#### this class will monitor:
#### string robot_status
#### string crystalStatus
#### motor  sample_x
#### motor  sample_y
#### motor  sample_z
#### option -sampleInfo
#### to export following attributes:
####
#### reoriented
#### position_checked

class DCS::SampleStatus {
    inherit DCS::Component

    public common controlSystem ::dcss

    public variable sampleInfo ""

    public proc getObject { } {
        if {$s_object == ""} {
            set s_object [[namespace current] ::#auto]
        }

        return $s_object
    }

    public method handleRobotStatusChange
    public method handleCrystalStatusChange
    public method handleRealMotorPositionChange

    public method getReOriented { } {
        return $m_reoriented
    }
    public method getPositionChecked { } {
        return $m_position_checked
    }

    private method updateAttributes
    private method setNewAttributes { rd pd }

    private variable m_deviceFactory ""
    private variable m_objRobotStatus
    private variable m_objCrystalStatus
    private variable m_objSampleX
    private variable m_objSampleY
    private variable m_objSampleZ

    private variable m_lastSampleInfo ""
    private variable m_lastRobotStatus ""
    private variable m_lastCrystalStatus ""
    private variable m_lastSampleX 9999
    private variable m_lastSampleY 9999
    private variable m_lastSampleZ 9999

    private variable m_reoriented 0
    private variable m_position_checked 0

    private common s_object ""

    constructor { args } {
        DCS::Component::constructor { \
        reoriented getReOriented \
        position_checked getPositionChecked \
        }
    } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objRobotStatus   [$m_deviceFactory createString robot_status]
        set m_objCrystalStatus [$m_deviceFactory createString crystalStatus]
        set m_objSampleX       [$m_deviceFactory getObjectName sample_x]
        set m_objSampleY       [$m_deviceFactory getObjectName sample_y]
        set m_objSampleZ       [$m_deviceFactory getObjectName sample_z]

        eval configure $args
        announceExist

        $m_objRobotStatus  register $this contents handleRobotStatusChange
        $m_objCrystalStatus register $this contents handleCrystalStatusChange
        $m_objSampleX register $this scaledPosition handleRealMotorPositionChange
        $m_objSampleY register $this scaledPosition handleRealMotorPositionChange
        $m_objSampleZ register $this scaledPosition handleRealMotorPositionChange
    }

    destructor {
        $m_objRobotStatus unregister $this contents handleRobotStatusChange
        $m_objCrystalStatus unregister $this contents handleCrystalStatusChange
        $m_objSampleX unregister $this scaledPosition handleRealMotorPositionChange
        $m_objSampleY unregister $this scaledPosition handleRealMotorPositionChange
        $m_objSampleZ unregister $this scaledPosition handleRealMotorPositionChange
    }
}
body DCS::SampleStatus::handleRobotStatusChange { \
- targetReady_ - contents_ -  } {
    if {!$targetReady_} return

    if {$m_lastRobotStatus == $contents_} {
        return
    }

    set m_lastRobotStatus $contents_

    updateAttributes
}
body DCS::SampleStatus::handleCrystalStatusChange { \
- targetReady_ - contents_ -  } {
    if {!$targetReady_} return

    if {$m_lastCrystalStatus == $contents_} {
        return
    }

    set m_lastCrystalStatus $contents_
    updateAttributes
}
body DCS::SampleStatus::handleRealMotorPositionChange { \
device_ targetReady_ - position_ -  } {
    if {!$targetReady_} return

    foreach {value_ units_} $position_ break

    set lastC_ [string index $device_ end]
    set lastC_ [string toupper $lastC_]

    set varName m_lastSample$lastC_

    set currentValue [set $varName]
    if {$currentValue == $value_} {
        return
    }
    set $varName $value_

    updateAttributes
}
body DCS::SampleStatus::updateAttributes { } {
    if {[llength $m_lastSampleInfo] < 6} {
        setNewAttributes 0 0
        puts "sampleInfo cleared reoriented"
        return
    }

    foreach {cas row uniqueID reOrientable reOrientInfo port} \
    $m_lastSampleInfo break

    if {$cas < 1 || $row < 0 || $uniqueID == "" || $reOrientable != "1" \
    || $port == ""} {
        setNewAttributes 0 0
        puts "sampleInfo cleared reoriented"
        return
    }

    set casList [list n l m r]
    set portFromMaster [lindex $casList $cas]$port

    if {[llength $m_lastCrystalStatus] < 7} {
        setNewAttributes 0 0
        puts "crystalStatus cleared reoriented"
        return
    }
    set mounted    [lindex $m_lastCrystalStatus 3]
    set synced     [lindex $m_lastCrystalStatus 5]
    set reoriented [lindex $m_lastCrystalStatus 6]
    if {$mounted != "1" || $synced != "yes" || $reoriented != "1"} {
        setNewAttributes 0 0
        puts "crystalStatus cleared reoriented"
        return
    }

    set portRobot [lindex $m_lastRobotStatus 15]
    if {[llength $portRobot] < 3} {
        setNewAttributes 0 0
        puts "robotStatus cleared reoriented"
        return
    }

    ## now compare port with portRobot
    foreach {cas row col} $portRobot break
    set portFromRobot $cas$col$row

    if {$portFromRobot != $portFromMaster} {
        setNewAttributes 0 0
        puts "portFromRobot $portFromRobot != portFromMaster: $portFromMaster"
        return
    }

    ### now the reoriented is "1"
    if {[llength $m_lastCrystalStatus] < 8} {
        setNewAttributes 1 0
        puts "crystalStatus cleared position_checked"
        return
    }
    set checked_position [lindex $m_lastCrystalStatus 7]
    if {[llength $checked_position] < 3} {
        setNewAttributes 1 0
        puts "crystalStatus cleared position_checked"
        return
    }
    foreach {checkedX checkedY checkedZ} $checked_position break
    if {$m_lastSampleX != $checkedX \
    || $m_lastSampleY != $checkedY \
    || $m_lastSampleZ != $checkedZ} {
        setNewAttributes 1 0
        puts "position moved from checked position"
        puts "current: x=$m_lastSampleX y=$m_lastSampleY z=$m_lastSampleZ"
        return
    }
    setNewAttributes 1 1
}
configbody DCS::SampleStatus::sampleInfo {
    if {$m_lastSampleInfo == $sampleInfo} return

    set m_lastSampleInfo $sampleInfo
    updateAttributes
}
body DCS::SampleStatus::setNewAttributes { rd pd } {
    if {$m_reoriented != $rd} {
        set m_reoriented $rd
        updateRegisteredComponents reoriented
    }
    if {$m_position_checked != $pd} {
        set m_position_checked $pd
        updateRegisteredComponents position_checked
    }
}

class DCS::RunViewForQueue {
     inherit ::itk::Widget DCS::Component
    
    itk_option define -controlSystem controlsytem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -runDefinition runDefinition RunDefinition \
    ::device::virtualRunForQueue
    
    public method updateEnergyList
    public method handleRunDefinitionChange
    public method handleAxisMotorLocked 
    public method handleDetectorTypeChange

    public method deleteThisRun
    public method setToDefaultDefinition 
    public method updateDefinition 
    public method resetRun
    public method openWebIce { } {
        set user [$itk_option(-controlSystem) getUser]
        set SID [$itk_option(-controlSystem) getSessionId]
        set url [::config getWebIceShowRunStrategyUrl]

        foreach {sil_id row_id unique_id run_id} \
        [$itk_option(-runDefinition) getID] break

        append url "?userName=$user"
        append url "&SMBSessionID=$SID"
        append url "&beamline=[::config getConfigRootName]"
        append url "&silId=$sil_id"
        append url "&row=$row_id"
        append url "&uniqueId=$unique_id"

        if {$run_id >= 0} {
            append url "&runIndex=$run_id"
        } else {
            append url "&repositionId=0"
        }

        if {[catch {openWebWithBrowser $url} result]} {
            log_error "failed to open webice: $result"
        } else {
            $itk_component(webice) configure -state disabled
            after 10000 [list $itk_component(webice) configure -state normal]
        }

    }
    ##TODO: decide when it cannot be deleted
    public method getDeleteEnabled { } { return 1 }

    public method getRunDefinition {} {return $itk_option(-runDefinition)}

    private method setAxis
    private method repack
    private method repackEnergyList 
    private method setEntryComponentDirectly 

    private method addBasicInput { args }
    private method deleteBasicInput { args }

    private variable _ready 0
    private variable m_lastRunDef ""
    private variable m_deviceFactory
    private variable m_detectorObj

    private variable m_slitWidth
    private variable m_slitHeight

    private variable m_runDefList ""

    private variable m_normalRelief ""
    private variable m_normalDBgd ""

    constructor { args} {
        ::DCS::Component::constructor { runDefinition getRunDefinition \
        }
    } {
        global gMotorPhi
        global gMotorOmega
        global gMotorDistance
        global gMotorBeamStop
        global gMotorEnergy
        global gMotorVert
        global gMotorHorz

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_detectorObj [DCS::Detector::getObject]
        
        set m_slitWidth  [$m_deviceFactory getObjectName beam_size_x]
        set m_slitHeight [$m_deviceFactory getObjectName beam_size_y]

        set ring $itk_interior
        
        itk_component add summary {
            DCS::Label $ring.s \
            -attribute summary
        } {}

        # make a frame of control buttons
        itk_component add buttonsFrame {
            frame $ring.bf 
        } {}

        itk_component add defaultButton {
            DCS::Button $itk_component(buttonsFrame).def -text "Default" \
                 -width 5 -pady 0 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this setToDefaultDefinition" 
        } {}
        
        itk_component add updateButton {
            DCS::Button $itk_component(buttonsFrame).u -text "Update" \
                 -width 5 -pady 0 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this updateDefinition" 
        } {}
        
        itk_component add deleteButton {
            DCS::Button $itk_component(buttonsFrame).del -text "Delete" \
                 -width 5 -pady 0  -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this deleteThisRun"
        } {
         #rename -command -deleteCommand deleteCommand DeleteCommand
        }
        
        itk_component add resetButton {
            DCS::Button $itk_component(buttonsFrame).r -text "Reset" \
                 -width 5 -pady 0  -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this resetRun" 
        } {}

        itk_component add webice {
            DCS::Button $ring.webice \
            -text "Open WebIce to the Strategy" \
            -width 35 -pady 0  \
            -activeClientOnly 1 \
            -systemIdleOnly 0 \
            -command "$this openWebIce" 
        } {}

        itk_component add inverse {
            DCS::Checkbutton $ring.inv -text "Inverse Beam"
        }

        set WIDTH_PROMPT 14

        # make the filename root entry
        itk_component add fileRoot {
            DCS::Entry $ring.fileroot \
                 -leaveSubmit 1 \
                 -entryType field \
                 -entryWidth 24 \
                 -entryJustify center \
             -entryMaxLength 128 \
             -promptText "Prefix: " \
                 -promptWidth $WIDTH_PROMPT \
                 -shadowReference 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        } {}

        # make the data directory entry
        itk_component add directory {
            DCS::DirectoryEntry $ring.dir \
                 -leaveSubmit 1 \
                 -entryType rootDirectory \
                 -entryWidth 24 \
                 -entryJustify left \
             -entryMaxLength 128 \
             -promptText "Directory: " \
                 -promptWidth $WIDTH_PROMPT \
                 -shadowReference 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        } {}

        # make the detector mode entry
        itk_component add detectorMode {
            DCS::DetectorModeMenu $ring.dm -entryWidth 19 \
                 -promptText "Detector: " \
                 -promptWidth $WIDTH_PROMPT \
                 -showEntry 0 \
                 -entryType string \
                 -entryJustify center \
                 -promptText "Detector: " \
                 -shadowReference 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 
        } {
            keep -font
        }

        itk_component add spacer1 {
            frame $ring.spacer1
        } {}
   
        itk_component add spacer2 {
            frame $ring.spacer2
        } {}


        itk_component add resolutionMode {
            DCS::Radiobox $ring.resoutionbox \
            -state active \
            -activeClientOnly 1 \
            -systemIdleOnly 0 \
            -shadowReference 0 \
            -selectcolor red \
            -borderwidth 0 \
            -stateList {0 1} \
            -buttonLabels {"  Distance:" "Resolution:"}
        } {
        }
        set ResolutionSite \
        [[$itk_component(resolutionMode) component rbox] childsite]

        itk_component add resolution {
            DCS::MotorViewEntry $ResolutionSite.res \
                 -checkLimits -1 \
                 -leaveSubmit 1 \
                 -device ::device::resolution \
                 -entryWidth 10 -units "A" -unitsList "A" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -escapeToDefault 0 \
                 -shadowReference 0 \
                 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -autoConversion 1
        } {}
        
        itk_component add distance {
            DCS::MotorViewEntry $ResolutionSite.distance \
                 -checkLimits -1 \
                 -leaveSubmit 1 \
                 -device ::device::$gMotorDistance \
                 -entryWidth 10 -units "mm" -unitsList "mm" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -escapeToDefault 0 \
                 -shadowReference 0 \
                 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -autoConversion 1
        } {}
        grid $itk_component(distance)   -row 0 -column 1 -sticky w
        grid $itk_component(resolution) -row 1 -column 1 -sticky w
        
        itk_component add beam_stop {
            DCS::MotorViewEntry $ring.beam_stop \
                 -checkLimits -1 \
                 -leaveSubmit 1 \
                 -showPrompt 1 \
                 -promptText "Beam Stop: " \
                 -promptWidth $WIDTH_PROMPT \
                 -entryWidth 10 -units "mm" -unitsList "mm" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -escapeToDefault 0 \
                 -shadowReference 0 \
                 -device ::device::$gMotorBeamStop \
                 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -autoConversion 1
        } {}
        itk_component add axis {
            DCS::MenuEntry $ring.axis \
                 -leaveSubmit 1 \
                 -entryWidth 9 \
                 -entryType string \
                 -entryJustify center \
                 -promptText "Axis: " \
                 -promptWidth $WIDTH_PROMPT \
                 -shadowReference 0 \
                 -showEntry 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        } {
        }

        # make the width entry
        itk_component add delta {
            DCS::Entry $ring.delta -promptText "Delta: " \
                 -leaveSubmit 1 \
                 -promptWidth $WIDTH_PROMPT \
                 -entryWidth 10     \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -decimalPlaces 2 \
                 -units "deg" \
                 -shadowReference 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        } {}

        # make the exposure time frame
        itk_component add exposureTimeFrame {
            frame $ring.et
        } {}

        set timeSite $itk_component(exposureTimeFrame)

        itk_component add doseEnable {
            DCS::Checkbutton $timeSite.doseMode \
            -text "Enable Exposure Control" \
            -shadowReference 0 \
        } {}

        itk_component add photonCnt {
            DCS::Entry $timeSite.count \
            -leaveSubmit 1 \
            -shadowReference 0 \
            -promptText "Photon count: " \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth 10 \
            -units "e11" \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -systemIdleOnly 0 \
            -activeClientOnly 1
        } {}

        set m_normalRelief [$itk_component(photonCnt) cget -entryRelief]
        set m_normalDBgd [$itk_component(photonCnt) cget -disabledbackground]

        itk_component add attenuation {
            DCS::MotorViewEntry $timeSite.attenuation \
            -checkLimits -1 \
            -leaveSubmit 1 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -promptText "Attenuation: " \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth 10 \
            -units "%" \
            -unitsList "%" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -activeClientOnly 1 \
            -systemIdleOnly 0 \
            -autoConversion 1
        } {}

        itk_component add exposureTime {
            DCS::Entry $timeSite.time \
            -leaveSubmit 1 \
            -shadowReference 0 \
            -promptText "Time: " \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth 10 \
            -units "s" \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -systemIdleOnly 0 \
            -activeClientOnly 1
        } {}

        pack $itk_component(doseEnable)   -side top -anchor w
        pack $itk_component(attenuation)  -side top -anchor w
        pack $itk_component(exposureTime) -side top -anchor w
        pack $itk_component(photonCnt)    -side top -anchor w

        # make the exposures frame
        itk_component add exposureFrame {
            frame $ring.ef
        } {}

        itk_component add frameHeader {
            label $itk_component(exposureFrame).f -text "Frame" -anchor e
        } {}
        
        itk_component add angleHeader {
            DCS::Label $itk_component(exposureFrame).a -attribute -value -component $itk_component(axis)
        } {}

        itk_component add startFrame {
            DCS::Entry $itk_component(exposureFrame).sf \
            -leaveSubmit 1 \
            -shadowReference 0 \
            -promptText "Start: " \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth 6     \
            -entryType positiveInt \
            -entryJustify right \
            -systemIdleOnly 0 \
            -activeClientOnly 1
        } {}
    
        itk_component add startAngle {
            DCS::Entry $itk_component(exposureFrame).sa \
                 -leaveSubmit 1 \
                 -entryWidth 9 \
                 -entryType float \
                 -entryJustify right \
                 -units "deg" -unitsList "deg" \
                 -unitsWidth 4 \
                 -shadowReference 0 \
                 -decimalPlaces 2 \
                 -reference "::device::$gMotorPhi scaledPosition" \
                 -escapeToDefault 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -autoConversion 1
        } {}


        itk_component add endFrame {
            DCS::Entry $itk_component(exposureFrame).ef \
                 -leaveSubmit 1 \
                 -shadowReference 0 \
                 -promptText "End: " \
                 -promptWidth $WIDTH_PROMPT \
                 -entryWidth 6     \
                 -entryType positiveInt \
                 -entryJustify right \
                 -decimalPlaces 2 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
        #         -zeroPadDigits 3
        } {}
        
        itk_component add endAngle {
            DCS::Entry $itk_component(exposureFrame).ea \
                 -leaveSubmit 1 \
                 -shadowReference 0 \
                 -entryWidth 9 \
                 -entryType float \
                 -entryJustify right \
                 -units "deg" -unitsList "deg" \
                 -unitsWidth 4 \
                 -decimalPlaces 2 \
                 -reference "::device::$gMotorPhi scaledPosition" \
                 -escapeToDefault 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -autoConversion 1
        } {}

        itk_component add wedgeSize {
            DCS::MenuEntry $ring.wedge \
                 -leaveSubmit 1 \
                 -shadowReference 0 \
                 -promptText "Wedge: " -units "deg" \
                 -entryType positiveFloat \
                 -showEntry 1 \
                 -menuChoices  {30.0 45.0 60.0 90.0 180.0} \
                 -entryJustify right \
                 -promptWidth $WIDTH_PROMPT \
                 -entryWidth 9 \
                 -menuColumnBreak 9 \
                 -decimalPlaces 2 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1
             } {}
        
    
      itk_component add energyFrame {
         frame $ring.eframe
      } {}

        set energyPrompt "Energy: "

        for { set cnt 0 } { $cnt < 5 } {incr cnt} {
            
            itk_component add energy$cnt {
                DCS::MotorViewEntry $itk_component(energyFrame).e$cnt \
                     -checkLimits -1 \
                     -leaveSubmit 1 \
                     -showPrompt 1 \
                     -promptText $energyPrompt \
                     -promptWidth $WIDTH_PROMPT \
                     -unitsList eV -units eV \
                     -device ::device::$gMotorEnergy \
                     -shadowReference 0 \
                     -onSubmit "$this updateEnergyList" \
                     -entryType positiveFloat \
                     -entryJustify right \
                     -entryWidth 12 \
                     -escapeToDefault 0 \
                     -autoConversion 1 \
                     -systemIdleOnly 0 \
                     -activeClientOnly 1 \
                     -nullAllowed 1
            } {}
            
            set energyPrompt " "
        }
        #if the string for table optimization exists then require energy tracking to be enabled to enable energy definition
        if { [$m_deviceFactory stringExists optimizedEnergyParameters] } {
            set m_optimizeEnergyParamsObj [DCS::OptimizedEnergyParams::getObject]
            $itk_component(energy0) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
            $itk_component(energy1) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
            $itk_component(energy2) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
            $itk_component(energy3) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
            $itk_component(energy4) addInput [list $m_optimizeEnergyParamsObj trackingEnable "1" "Energy tracking is disabled."]
        }


        eval itk_initialize $args

        ::mediator register $this [$m_deviceFactory getObjectName $gMotorOmega] lockOn handleAxisMotorLocked
        ::mediator register $this $m_detectorObj type handleDetectorTypeChange 

        #handleDetectorTypeChange will call repack
        #repack

        #### disable delete while collect data is running.
        #### because it the dcss only remembers which run it is running
        #### and remove of a run with smaller run number will cause
        #### Bluice to display wrong information.
        #TODO TODO : do not know how to deal with this yet for queue.

        $itk_component(inverse) addInput "::$itk_component(axis) -value Phi {Inverse can only be used with phi axis.}"

        announceExist

        set _ready 1
    }
    
    destructor {
      ::mediator announceDestruction $this
    }
}

body DCS::RunViewForQueue::handleDetectorTypeChange { detector_ targetReady_ alias_ type_ - } {
    #puts "RunViewForQueue handleDetectorTypeChange $detector_ $targetReady_ $alias_ $type_"
    if {!$targetReady_} return
    repack
}
body DCS::RunViewForQueue::repack { } {
    set ring $itk_interior

    puts "repacking"
    
    pack $itk_component(summary) -pady 3 
    pack $itk_component(buttonsFrame) -pady 3
    #pack $itk_component(defaultButton) -side left -padx 3
    pack $itk_component(updateButton) -side left -padx 3
    pack $itk_component(deleteButton) -side left -padx 3
    pack $itk_component(resetButton) -side left -padx 3

    pack $itk_component(webice) -pady 1 -anchor n

    pack $itk_component(fileRoot)     -pady 1 -padx 2 -anchor w
    pack $itk_component(directory)    -pady 1 -padx 2 -anchor w
    pack $itk_component(detectorMode) -pady 1 -padx 2 -anchor w

    #pack $itk_component(spacer1) -pady 1

    pack $itk_component(resolutionMode) -padx 0 -pady 0 -anchor w
    pack $itk_component(beam_stop) -padx 2 -pady 1 -anchor w
   
    pack $itk_component(axis) -pady 1 -padx 2 -anchor w
    pack $itk_component(delta) -padx 2 -pady 1 -anchor w

    pack $itk_component(exposureTimeFrame) -padx 2 -pady 1 -anchor w
   
    #pack $itk_component(spacer2) -pady 1

    pack $itk_component(exposureFrame) -ipadx 0 -anchor w -padx 2
    grid $itk_component(frameHeader) -column 0 -row 0 -sticky e
    grid $itk_component(angleHeader) -column 1 -row 0
    grid $itk_component(startFrame) -column 0 -row 1
    grid $itk_component(startAngle) -column 1 -row 1
    grid $itk_component(endFrame) -column 0 -row 2
    grid $itk_component(endAngle) -column 1 -row 2

    pack $itk_component(inverse) -after $itk_component(exposureFrame) -pady 1 -side top -anchor n
    pack $itk_component(wedgeSize) -after $itk_component(inverse) -side top -anchor w -padx 2

    pack $itk_component(energyFrame) -anchor w -pady 1 -padx 2
    pack $itk_component(energy0) -anchor w -pady 1
    #repackEnergyList
}

body DCS::RunViewForQueue::setAxis { axis_  } {
    global gMotorPhi
    global gMotorOmega
    
    if { $axis_ == "Omega" } {
        $itk_component(startAngle) configure -reference "::device::$gMotorOmega scaledPosition"
        $itk_component(endAngle) configure -reference "::device::$gMotorOmega scaledPosition"
    }

    if { $axis_ == "Phi" } {
        $itk_component(startAngle) configure -reference "::device::$gMotorPhi scaledPosition"
        $itk_component(endAngle) configure -reference "::device::$gMotorPhi scaledPosition"
    }
    
    $itk_component(axis) setValue $axis_ 1
}

body DCS::RunViewForQueue::handleRunDefinitionChange { run_ targetReady_ alias_ runDefinition_ -  } {

    if {!$targetReady_} return

    puts "handleRunDef Change"

    foreach { \
    inverse \
    fileRoot directory \
    detectorMode resolutionMode resolution distance beamStop \
    axis delta \
    doseEnable photonCount attenuation exposureTime \
    startFrame startAngle endAngle wedgeSize \
    numEnergy energy(0) energy(1) energy(2) energy(3) energy(4) \
    } [$run_ getList \
    inverse_on \
    file_root directory \
    detector_mode resolution_mode resolution distance beam_stop \
    axis_motor delta \
    dose_mode photon_count attenuation exposure_time \
    start_frame start_angle end_angle wedge_size \
    num_energy energy1 energy2 energy3 energy4 energy5] break

    set endFrame [$run_ cget -endFrame]

    puts "count: $photonCount"


    #set directly
    setEntryComponentDirectly fileRoot $fileRoot
    setEntryComponentDirectly directory $directory
    $itk_component(detectorMode) setValueByIndex $detectorMode 1
    $itk_component(resolutionMode) setValue $resolutionMode 1
    setEntryComponentDirectly resolution $resolution
    setEntryComponentDirectly distance $distance
    setEntryComponentDirectly beam_stop $beamStop
    setEntryComponentDirectly attenuation $attenuation
    setAxis $axis
    setEntryComponentDirectly delta $delta
    $itk_component(inverse) setValue $inverse
    $itk_component(doseEnable) setValue $doseEnable
    setEntryComponentDirectly photonCnt $photonCount
    setEntryComponentDirectly exposureTime $exposureTime 
    setEntryComponentDirectly startFrame $startFrame
    setEntryComponentDirectly startAngle $startAngle
    setEntryComponentDirectly endAngle $endAngle
    setEntryComponentDirectly endFrame $endFrame
    setEntryComponentDirectly wedgeSize $wedgeSize

    if {$doseEnable == "1"} {
        $itk_component(photonCnt) configure \
        -state normal

        $itk_component(attenuation) configure \
        -state labeled

        $itk_component(exposureTime) configure \
        -state labeled
    } else {
        $itk_component(attenuation) configure \
        -state normal

        $itk_component(exposureTime) configure \
        -state normal

        $itk_component(photonCnt) configure \
        -state labeled
    }

    if {$resolutionMode == "1"} {
        $itk_component(resolution) configure \
        -state normal

        $itk_component(distance) configure \
        -state labeled
    } else {
        $itk_component(resolution) configure \
        -state labeled

        $itk_component(distance) configure \
        -state normal
    }


    #fill in the entries with the new energies
    if {$numEnergy > 5} {
        set numEnergy 5
        puts "wrong numEnergy: $numEnergy"
    }
    for { set cnt 0 } { $cnt < $numEnergy} { incr cnt} {
        setEntryComponentDirectly energy$cnt [list $energy($cnt) eV] 
    }

   #set remaining energy entries to blank    
    for { set cnt $numEnergy } { $cnt < 5} { incr cnt} {
        $itk_component(energy$cnt) setValue "" 1
    }

    repackEnergyList $numEnergy
}

body DCS::RunViewForQueue::setEntryComponentDirectly { component_ value_ } {
   $itk_component($component_) setValue $value_ 1
}

body DCS::RunViewForQueue::repackEnergyList { numEnergy_ } {

   #pack all entries with values and one with blank value, but no more than 5
    for { set cnt 0 } { $cnt < [expr $numEnergy_ + 1] && $cnt < 5} { incr cnt} {
        pack $itk_component(energy$cnt) -anchor w -pady 1
    }
    
   #unpack any remaining entries
    for { set cnt [expr $numEnergy_ + 1] } { $cnt < 5} { incr cnt} {
        pack forget $itk_component(energy$cnt)
    }
}

body DCS::RunViewForQueue::updateEnergyList {} {
    global gMotorEnergy

    if { ! $_ready } return
    
    set energyList ""
    
    for { set cnt 0 } { $cnt < 5} { incr cnt} {
        set energy($cnt) [$itk_component(energy$cnt) get]
        
        if { [lindex $energy($cnt) 0] != "" } { 
            
            if { $energy($cnt) != 0.0 } {
                lappend energyList [lindex [::units convertUnitValue $energy($cnt) eV] 0]
            }
        }
    }

    if { $energyList == "" } {set energyList [::device::$gMotorEnergy cget -scaledPosition]}

    $itk_option(-runDefinition) setEnergyList $energyList
}

body DCS::RunViewForQueue::addBasicInput { args } {
    foreach item $args {
        $itk_component($item) addInput \
        [list $itk_option(-runDefinition) state "inactive" \
        "Run must be reset before using."]
    }
}

body DCS::RunViewForQueue::deleteBasicInput { args } {
    foreach item $args {
        $itk_component($item) deleteInput \
        [list $itk_option(-runDefinition) state "inactive"]
    }
}

configbody DCS::RunViewForQueue::runDefinition {
    global gMotorDistance
    global gMotorBeamStop

    $itk_component(summary) configure -component $itk_option(-runDefinition)

    $itk_component(fileRoot) configure \
    -onSubmit "$itk_option(-runDefinition) setFileRoot %s" \
    -reference "$itk_option(-runDefinition) fileRoot" 

    $itk_component(directory) configure \
    -onSubmit "$itk_option(-runDefinition) setDirectory %s" \
    -reference "$itk_option(-runDefinition) directory"
                 
    $itk_component(detectorMode) configure \
    -onSubmit "$itk_option(-runDefinition) setDetectorMode %s"

    $itk_component(resolutionMode) configure \
    -command "$itk_option(-runDefinition) setResolutionMode %s" \
    -reference "$itk_option(-runDefinition) resolutionMode"

    $itk_component(resolution) configure \
    -onSubmit "$itk_option(-runDefinition) setResolution %s"

    $itk_component(distance) configure \
    -onSubmit "$itk_option(-runDefinition) setDistance %s"

    $itk_component(beam_stop) configure \
    -onSubmit "$itk_option(-runDefinition) setBeamStop %s" \

    $itk_component(axis) configure \
    -menuChoices [$itk_option(-runDefinition) getAxisChoices] \
    -onSubmit "$itk_option(-runDefinition) setAxis %s" \
    -reference "$itk_option(-runDefinition) axis"

    $itk_component(delta) configure \
    -onSubmit "$itk_option(-runDefinition) setDelta %s" \
    -reference "$itk_option(-runDefinition) delta"

    $itk_component(doseEnable) configure \
    -command "$itk_option(-runDefinition) setDoseMode %s" \
    -reference "$itk_option(-runDefinition) doseMode"

    $itk_component(photonCnt) configure \
    -onSubmit "$itk_option(-runDefinition) setPhotonCount %s" \
    -reference "$itk_option(-runDefinition) photonCount"

    $itk_component(attenuation) configure \
    -onSubmit "$itk_option(-runDefinition) setAttenuation %s"

    $itk_component(exposureTime) configure \
    -onSubmit "$itk_option(-runDefinition) setExposureTime %s" \
    -reference "$itk_option(-runDefinition) exposureTime"

    $itk_component(startFrame) configure \
    -onSubmit "$itk_option(-runDefinition) setStartFrame %s" \
    -reference "$itk_option(-runDefinition) startFrame"

    $itk_component(startAngle) configure \
    -onSubmit "$itk_option(-runDefinition) setStartAngle %s"
   
    $itk_component(endFrame) configure \
    -reference "$itk_option(-runDefinition) endFrame" \
    -onSubmit "$itk_option(-runDefinition) setEndFrame %s"

    $itk_component(endAngle) configure \
    -onSubmit "$itk_option(-runDefinition) setEndAngle %s"

    $itk_component(inverse) configure \
    -command "$itk_option(-runDefinition) setInverse %s" \
    -reference "$itk_option(-runDefinition) inverse"

    $itk_component(wedgeSize) configure \
    -onSubmit "$itk_option(-runDefinition) setWedgeSize %s" \
    -reference "$itk_option(-runDefinition) wedgeSize"

    if { $m_lastRunDef != "" && \
    $m_lastRunDef != $itk_option(-runDefinition) } {
        ::mediator unregister $this $m_lastRunDef contents

        $itk_component(resetButton) deleteInput \
        [list $m_lastRunDef needsReset 1]

        deleteBasicInput \
        defaultButton \
        updateButton \
        deleteButton \
        fileRoot \
        directory \
        detectorMode \
        resolutionMode \
        resolution \
        distance \
        beam_stop \
        axis \
        delta \
        doseEnable \
        photonCnt \
        attenuation \
        exposureTime \
        startFrame \
        endFrame \
        startAngle \
        endAngle \
        wedgeSize \
        inverse \
        energy0 \
        energy1 \
        energy2 \
        energy3 \
        energy4

        $itk_component(resolution) deleteInput \
        [list $itk_option(-runDefinition) resolutionMode 1]

        $itk_component(distance) deleteInput \
        [list $itk_option(-runDefinition) resolutionMode 0]

        $itk_component(photonCnt) deleteInput \
        [list $itk_option(-runDefinition) doseMode 1]

        $itk_component(attenuation) deleteInput \
        [list $itk_option(-runDefinition) doseMode 0]

        $itk_component(exposureTime) deleteInput \
        [list $itk_option(-runDefinition) doseMode 0]
    }

    if {$itk_option(-runDefinition) != "" && \
    $m_lastRunDef != $itk_option(-runDefinition) } {
        ::mediator register $this $itk_option(-runDefinition) contents \
        handleRunDefinitionChange
   
        $itk_component(resetButton) addInput \
        [list $itk_option(-runDefinition) needsReset 1 "Reset 'Paused' or 'Completed' runs only."]

        addBasicInput \
        defaultButton \
        updateButton \
        deleteButton \
        fileRoot \
        directory \
        detectorMode \
        resolutionMode \
        resolution \
        distance \
        beam_stop \
        axis \
        delta \
        doseEnable \
        photonCnt \
        attenuation \
        exposureTime \
        startFrame \
        endFrame \
        startAngle \
        endAngle \
        wedgeSize \
        inverse \
        energy0 \
        energy1 \
        energy2 \
        energy3 \
        energy4

        $itk_component(resolution) addInput \
        [list $itk_option(-runDefinition) resolutionMode 1 \
        "Only available in resolution mode"]

        $itk_component(distance) addInput \
        [list $itk_option(-runDefinition) resolutionMode 0 \
        "Only available in distance mode"]

        $itk_component(photonCnt) addInput \
        [list $itk_option(-runDefinition) doseMode 1 \
        "Only Available in exposure control mode"]

        $itk_component(attenuation) addInput \
        [list $itk_option(-runDefinition) doseMode 0 \
        "Only photon count is enabled in exposure control mode"]

        $itk_component(exposureTime) addInput \
        [list $itk_option(-runDefinition) doseMode 0 \
        "Only photon count is enabled in exposure control mode"]
    }

    set m_lastRunDef $itk_option(-runDefinition)
    repack

    #inform interested widgets that we are looking at a different run definition
    updateRegisteredComponents runDefinition
}

body DCS::RunViewForQueue::deleteThisRun {} {
   $itk_option(-runDefinition) deleteThis
}

body DCS::RunViewForQueue::resetRun {} {
   $itk_option(-runDefinition) reset 
}

body DCS::RunViewForQueue::setToDefaultDefinition { } {
    $itk_option(-runDefinition) resetRun
}

body DCS::RunViewForQueue::updateDefinition { } {
    global gMotorPhi
    global gMotorOmega
    global gMotorDistance
    global gMotorBeamStop
    global gMotorEnergy

    set attenuation [lindex [::device::attenuation getScaledPosition] 0]

    foreach motor [list $gMotorBeamStop $gMotorDistance] \
    setName [list beamstop_setting distance_setting] {
        set curP [lindex [::device::$motor getScaledPosition] 0]
        if {![::device::$motor limits_ok curP]} {
            log_warning $motor current position out of limits, using $curP
        }
        set $setName $curP
    }

    if { [$itk_component(axis) get]  == "Phi" } {
      set startAngle [lindex [::device::$gMotorPhi getScaledPosition] 0]
    } else {
      set startAngle [lindex [::device::$gMotorOmega getScaledPosition] 0]
    }
    set endFrame    [$itk_component(endFrame) get]
    set startFrame  [$itk_component(startFrame) get]
    set delta [lindex [$itk_component(delta) get] 0]
    set endAngle [expr ($endFrame - $startFrame + 1) * $delta + $startAngle]

    set resolution_setting [lindex [::device::resolution getScaledPosition] 0]

    set numEnergy 0
    set energy(1) ""
    set energy(2) ""
    set energy(3) ""
    set energy(4) ""
    set energy(5) ""

    set peakEnergy 0.0
    set remoteEnergy 0.0

    set userScanWindow [[InflectPeakRemExporter::getObject] getExporter] 
    if { [info commands $userScanWindow] != "" } {

        set peakEnergy [lindex [$userScanWindow getMadEnergy Peak] 0]
        if {$peakEnergy != "" } {
            incr numEnergy
            set energy($numEnergy) $peakEnergy
        }

        set remoteEnergy [lindex [$userScanWindow getMadEnergy Remote] 0]
        if {$remoteEnergy != "" } {
            incr numEnergy
            set energy($numEnergy) $remoteEnergy
        }

        set inflectionEnergy  [lindex [$userScanWindow getMadEnergy Inflection] 0]
        if {$inflectionEnergy != "" } {
            incr numEnergy
            set energy($numEnergy) $inflectionEnergy
        }

    }

    #try to get the filename prefix from the screening tab...
    set object [$m_deviceFactory createString crystalStatus]
    #$object createAttributeFromField current 0
    #$object createAttributeFromField subdir 4
    set fileRoot [$object getFieldByIndex 0] 

    if { $fileRoot == "" } {
        #nothing is mounted now...leave the entry alone
        set fileRoot [$itk_component(fileRoot) get]
        set directory [$itk_component(directory) get]
    } else {
        #something is mounted...get the directory from screening 
        set dirObj [$m_deviceFactory createString screeningParameters]
        set rootDir [$dirObj getFieldByIndex 2]
        set subDir [$object getFieldByIndex 4]
        set directory [file join $rootDir $subDir]
    }


    #TODO: here will need check doseMode to decide sending
    ###    attenuation and time or not
    ###   also set resolution or distance

    $itk_option(-runDefinition) setList \
    status inactive \
    file_root $fileRoot \
    directory  $directory \
    start_angle $startAngle \
    end_angle $endAngle \
    resolution $resolution_setting \
    distance $distance_setting \
    beam_stop $beamstop_setting \
    attenuation $attenuation \
    num_energy $numEnergy \
    energy1 $energy(1) \
    energy2 $energy(2) \
    energy3 $energy(3) \
    energy4 $energy(4) \
    energy5 $energy(5)
}

body DCS::RunViewForQueue::handleAxisMotorLocked { device_ targetReady_ alias_ lockedOn_ -  } {
   if { !$targetReady_ } return
   $itk_component(axis) configure -menuChoices [$itk_option(-runDefinition) getAxisChoices]
}
### display two video snapshots
class DCS::SnapshotViewForQueue {
    inherit ::itk::Widget

    itk_option define -snapshot snapshot Snapshot [list {} {}] {
        updateSnapshot
    }

    private variable m_lastSnapshot ""
    private variable m_rawImage1 ""
    private variable m_rawImage2 ""

    private variable m_rawTS1       0
    private variable m_rawTS2       0

    private variable m_rawWidth1    0
    private variable m_rawWidth2    0
    private variable m_rawHeight1   0
    private variable m_rawHeight2   0

    private variable m_snapshot1
    private variable m_snapshot2

    private variable m_winID "no defined"
    private variable m_drawWidth  0
    private variable m_drawHeight 0

    private method redrawImages
    private method updateSnapshot

    public method handleResize {winID width height} {
        if {$winID != $m_winID} {
            puts "handleResize: not mine w=$width h=$height"
            return
        }
        puts "handleResize: w=$width h=$height"
        set m_drawWidth $width
        set m_drawHeight $height
        redrawImages
    }
    constructor { args } {
        set snapSite $itk_interior

        itk_component add drawArea {
            canvas $snapSite.canvas
        } {
        }
        pack $itk_component(drawArea) -side top -expand 1 -fill both

        set m_winID $itk_component(drawArea)
        bind $m_winID <Configure> "$this handleResize %W %w %h"

        $itk_component(drawArea) config -scrollregion {0 0 352 500}

        set m_snapshot1 [image create photo -palette "256/256/256"]
        set m_snapshot2 [image create photo -palette "256/256/256"]

        $itk_component(drawArea) create image 0 0 \
        -image $m_snapshot1 \
        -anchor nw \
        -tags "snapshot1"

        $itk_component(drawArea) create image 0 250 \
        -image $m_snapshot2 \
        -anchor nw \
        -tags "snapshot2"

        set m_rawImage1 [image create photo -palette "256/256/256"]
        set m_rawImage2 [image create photo -palette "256/256/256"]

        eval itk_initialize $args
    }
}
body DCS::SnapshotViewForQueue::updateSnapshot { } {
    set jpgFile1 [lindex $itk_option(-snapshot) 0]
    set jpgFile2 [lindex $itk_option(-snapshot) 1]

    if {$jpgFile1 == "" || $jpgFile2 == ""} {
        $m_snapshot1 blank
        $m_snapshot2 blank
        set m_lastSnapshot ""
        return
    }

    if {[catch {
        set ts1      [file mtime $jpgFile1]
        set ts2      [file mtime $jpgFile2]

    } errMsg]} {
        log_error failed to read jpg files: $errMsg
        puts "failed to access time of jpg files: $errMsg"
        $m_snapshot1 blank
        $m_snapshot2 blank
        set m_lastSnapshot ""
        return
    }

    if {$m_lastSnapshot == $itk_option(-snapshot) \
    && $m_rawTS1 == $ts1 && $m_rawTS2 == $ts2} {
        puts "skip jpg update. no change"
        return
    }

    set m_lastSnapshot $itk_option(-snapshot)

    if {[catch {
        image delete $m_rawImage1
        image delete $m_rawImage2

        set m_rawImage1 \
        [image create photo -palette "256/256/256" -file $jpgFile1]

        set m_rawWidth1  [image width  $m_rawImage1]
        set m_rawHeight1 [image height $m_rawImage1]

        set m_rawImage2 \
        [image create photo -palette "256/256/256" -file $jpgFile2]

        set m_rawWidth2  [image width  $m_rawImage2]
        set m_rawHeight2 [image height $m_rawImage2]

        puts "image size : $m_rawWidth1 $m_rawHeight1 $m_rawWidth2 $m_rawHeight2"

        set m_rawTS1 $ts1
        set m_rawTS2 $ts2

        redrawImages
    } errMsg] == 1} {
        log_error failed to create image from jpg files: $errMsg
        puts "failed to create image from jpg files: $errMsg"
    }
}
body DCS::SnapshotViewForQueue::redrawImages { } {
    set w [expr $m_drawWidth - 2]
    set h [expr $m_drawHeight - 2]

    puts "redrawImage w=$w h=$h"

    if {$w < 1 || $h < 1} {
        return
    }
    if {$m_rawImage1 == "" || $m_rawImage2 == ""} {
        $m_snapshot1 blank
        $m_snapshot2 blank
        return
    }

    if {$m_rawWidth1 < 1 || $m_rawHeight1 < 1 || \
    $m_rawWidth2 < 1 || $m_rawHeight2 < 1} {
        $m_snapshot1 blank
        $m_snapshot2 blank
        return
    }

    ### 2 images
    set h [expr $h / 2 - 5]

    set xScale1 [expr double($w) / $m_rawWidth1]
    set yScale1 [expr double($h) / $m_rawHeight1]

    if {$xScale1 > $yScale1} {
        set scale1 $yScale1
    } else {
        set scale1 $xScale1
    }

    set w1 [expr int($m_rawWidth1 * $scale1)]
    set h1 [expr int($m_rawHeight1 * $scale1)]

    set xScale2 [expr double($w) / $m_rawWidth2]
    set yScale2 [expr double($h) / $m_rawHeight2]

    if {$xScale2 > $yScale2} {
        set scale2 $yScale2
    } else {
        set scale2 $xScale2
    }

    set w2 [expr int($m_rawWidth2 * $scale2)]
    set h2 [expr int($m_rawHeight2 * $scale2)]

    imageResizeBilinear     $m_snapshot1 $m_rawImage1 $w1
    #if {$scale1 >= 0.75} {
    #    imageResizeBilinear     $m_snapshot1 $m_rawImage1 $w1
    #} else {
    #    imageDownsizeAreaSample $m_snapshot1 $m_rawImage1 $w1 0 1
    #}

    if {$scale2 >= 0.75} {
        imageResizeBilinear     $m_snapshot2 $m_rawImage2 $w2
    } else {
        imageDownsizeAreaSample $m_snapshot2 $m_rawImage2 $w2 0 1
    }

    $itk_component(drawArea) coords snapshot2 0 [expr $h1 + 10]
}


class DCS::PositionViewForQueue {
     inherit ::itk::Widget DCS::Component
    
    itk_option define -controlSystem controlsytem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -cmdSwitchView cmdSwitchView CmdSwitchView ""

    ### only read/change position_id
    itk_option define -runDefinition runDefinition RunDefinition \
    ::device::virtualRunForQueue
    
    itk_option define -positionDefinition positionDefinition \
    PositionDefinition ::device::virtualPositionForQueue

    itk_option define -positionLabels positionLabels PositionLabels "" {
        puts "start -positionLabels for positionView"
        puts "data: $itk_option(-positionLabels)"
        rebuildPositionMenu

        puts "end of -positionLabels for positionView"
    }

    itk_option define -tabStyle tabStyle TabStyle 1 {
        if {$itk_option(-tabStyle)} {
            pack forget $itk_component(adjust)
            pack $itk_component(notice) -before $itk_component(position_frame)
        } else {
            pack forget $itk_component(notice)
            pack $itk_component(adjust) -before $itk_component(position_frame)
        }
    }

    private method rebuildPositionMenu { }
    private method updateTitle { }

    public method handleRunDefinitionChange
    public method handlePositionDefinitionChange

    public method changeToAdjustView { } {
        eval $itk_option(-cmdSwitchView)
    }

    public method handleMountAndReOrient
    public method handleAdjust
    public method handleViewSpots

    ### execute the config command from Title
	public method newCommand

    public method switchPosition { index }

    private method setEntryComponentDirectly 

    private variable m_lastRunDef ""
    private variable m_lastPositionId 0
    private variable m_deviceFactory

    private variable m_lastPosition ""
    private variable m_lastPositionContents ""

    private variable m_sampleStatus ""


    ### column name and field name in position
    private common s_scoreMap [list \
    [list Score     autoindex_score] \
    [list Mosaicity autoindex_mosaicity] \
    [list Rmsr      autoindex_rmsr] \
    [list Rsolution autoindex_resolution] \
    ]

    private variable m_scoreIndex

    private common s_font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"
    constructor { args} {
    } {
        global gMotorBeamWidth
        global gMotorBeamHeight

        set m_sampleStatus [DCS::SampleStatus::getObject]

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        
        set ring $itk_interior

        label $ring.l1 -text "Changing the parameters below"
        label $ring.l2 -text "needs Mount and ReOrient"

        itk_component add notice {
            label $ring.l3 -text "Tab \"Add New Position\" will be enabled\nafter sample re-oriented"
        } {
        }

        itk_component add mount {
            DCS::Button $ring.mnt \
            -text "Mount and ReOrent" \
            -command "this handleMountAndReOrient" \
            -width 27
        } {}

        itk_component add adjust {
            DCS::Button $ring.nr \
            -text "Adjust Following Parameters" \
            -command "$this changeToAdjustView" \
            -width 27
        } {}

        $itk_component(mount) addInput \
        [list $m_sampleStatus reoriented "0" \
        "Sample already re-oriented"]

        $itk_component(adjust) addInput \
        [list $m_sampleStatus reoriented "1" \
        "Mount and re-orient sample first."]

        itk_component add view_spots {
            DCS::Button $ring.spots \
            -text "View Predicted Spots" \
            -command "this handleViewSpots" \
            -width 40
        } {}

        itk_component add position_frame {
            ::DCS::TitledFrame $ring.positionF \
            -labelFont $s_font \
            -labelText "Default Position From Screening" \
        } {
        }
        set posSite [$itk_component(position_frame) childsite]

        itk_component add score_frame {
            frame $posSite.score
        } {
        }
        set scoreSite $itk_component(score_frame)

        set m_scoreIndex ""
        set ll [llength $s_scoreMap]
        for {set i 0} {$i < $ll} {incr i} {
            set field [lindex $s_scoreMap $i]
            set txt [lindex $field 0]
            set field_name [lindex $field 1]

            lappend m_scoreIndex \
            [::DCS::PositionFieldForQueue::nameToIndex $field_name]

            label $scoreSite.l$i \
            -text $txt \
            -relief groove \
            -anchor w \
            -borderwidth 1 \
            -background #c0c0ff

            itk_component add scoreF$i {
                label $scoreSite.s$i \
                -anchor w \
                -relief groove \
                -borderwidth 1 \
                -background #e0e0e0 \
            } {
            }

            grid $scoreSite.l$i -row 0 -column $i -sticky news
            grid $scoreSite.s$i -row 1 -column $i -sticky news
            grid columnconfig $scoreSite $i -weight 10
        }

        itk_component add beamSizeFrame {
            iwidgets::labeledframe $posSite.bsF \
            -labelpos nw \
            -labeltext "Beam Size" \
            -labelfont "helvetica -16 bold"
        } {}
        set sizeSite [$itk_component(beamSizeFrame) childsite]

        itk_component add cross {
            label $sizeSite.cross \
            -text "x" \
            -font "helvetica -14 bold"
        } {
        }
        itk_component add width {
            DCS::Entry $sizeSite.width \
            -shadowReference 0 \
            -reference "::device::$gMotorBeamWidth scaledPosition" \
            -showPrompt 0 \
            -state labeled \
            -entryWidth 10 \
            -units "mm" \
            -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1
        } {}

        itk_component add height {
            DCS::Entry $sizeSite.height \
            -shadowReference 0 \
            -reference "::device::$gMotorBeamHeight scaledPosition" \
            -showPrompt 0 \
            -state labeled \
            -entryWidth 10 \
            -units "mm" \
            -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1
        } {}

        pack $itk_component(width) -side left
        pack $itk_component(cross) -side left -anchor s
        pack $itk_component(height) -side left

        itk_component add snapshotFrame {
            iwidgets::labeledframe $posSite.snpF \
            -labeltext "Sample Position" \
            -labelfont "helvetica -16 bold"
        } {}
        set snapSite [$itk_component(snapshotFrame) childsite]

        itk_component add snapshot_view {
            DCS::SnapshotViewForQueue $snapSite.view
        } {
        }
        pack $itk_component(snapshot_view) -side top -expand 1 -fill both

        pack $itk_component(score_frame) -side top -fill x
        pack $itk_component(beamSizeFrame) -side top
        pack $itk_component(snapshotFrame) -side top -expand 1 -fill both

        pack $ring.l1 -side top -anchor n
        pack $ring.l2 -side top -anchor n
        pack $itk_component(mount) -side top
        pack $itk_component(notice) -anchor n
        #pack $itk_component(adjust) -side top
        pack $itk_component(position_frame) -expand 1 -fill both
        pack $itk_component(view_spots) -side bottom

        set m_rawImage1 [image create photo -palette "256/256/256"]
        set m_rawImage2 [image create photo -palette "256/256/256"]

        eval itk_initialize $args
        announceExist

        ##set m_winID $itk_interior
        ##bind $m_winID <Configure> "$this handleResize %W %w %h"

		::mediator register $this ::$itk_component(position_frame) -command newCommand
    }
    
    destructor {
      ::mediator announceDestruction $this
    }
}
body DCS::PositionViewForQueue::updateTitle { } {
    set txt "Default Position from Screening"
    if {$m_lastPositionId < 1} {
        $itk_component(position_frame) configure \
        -labelText $txt
        return
    }

    if {[llength $itk_option(-positionLabels)] > 1} {
        foreach {labelList statusList} $itk_option(-positionLabels) break
        set ll1 [llength $labelList]
        set ll2 [llength $statusList]
        if {$ll1 == $ll2 && $ll1 > 1 && $m_lastPositionId < $ll1} {
            set txt [lindex $labelList $m_lastPositionId]
        }
    }

    $itk_component(position_frame) configure \
    -labelText $txt
}

body DCS::PositionViewForQueue::rebuildPositionMenu { } {
    set cfgMenu [list "Default Position From Screening" 0]

    if {[llength $itk_option(-positionLabels)] > 1} {
        foreach {labelList statusList} $itk_option(-positionLabels) break
        set ll1 [llength $labelList]
        set ll2 [llength $statusList]
        if {$ll1 == $ll2 && $ll1 > 1} {
            ## start at 1 not 0. 0 is the default screening position
            for {set i 1} {$i < $ll1} {incr i} {
                set name   [lindex $labelList $i]
                set status [lindex $statusList $i]
                if {$status} {
                    lappend cfgMenu $name $i
                }
            }
        }
    }

    if {[llength $cfgMenu] < 4} {
        set cfgMenu ""
    }

    $itk_component(position_frame) configure \
    -configCommands $cfgMenu

    updateTitle
}

body DCS::PositionViewForQueue::handlePositionDefinitionChange { \
stringName_ targetReady_ alias_ contents_ - } {

    if {!$targetReady_} {
        return
    }
    puts "queue position: $contents_"
    ## display scores
    set ll [llength $m_scoreIndex]
    for {set i 0} {$i < $ll} {incr i} {
        set index [lindex $m_scoreIndex $i]
        ### value maybe empty
        set value [lindex $contents_ $index]
        $itk_component(scoreF$i) configure -text $value
    }

    ## update snapshots
    if {[catch {
        set snapshots [::DCS::PositionFieldForQueue::getList contents_ \
        file_box_0 file_box_1]

        $itk_component(snapshot_view) configure \
        -snapshot $snapshots
    } errMsg]} {
        puts "wrong position contents: $errMsg"
        return
    }
}
body DCS::PositionViewForQueue::newCommand { - targetReady_ - command_ -} {
	if { ! $targetReady_ } return

    if {$command_ == ""} {
        return
    }

    if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
        log_error Only Active User change change it
        return
    }
    if {$itk_option(-runDefinition) == ""} {
        log_error no run definition hooked
        return
    }
    if {![string is integer -strict $command_]} {
        log_error bad position index $command_
        return
    }

    $itk_option(-runDefinition) setField position_id $command_
}

configbody DCS::PositionViewForQueue::runDefinition {
    if { $m_lastRunDef != "" && \
    $m_lastRunDef != $itk_option(-runDefinition) } {
        ::mediator unregister $this $m_lastRunDef contents
    }

    if {$itk_option(-runDefinition) != "" && \
    $m_lastRunDef != $itk_option(-runDefinition) } {
        ::mediator register $this $itk_option(-runDefinition) contents \
        handleRunDefinitionChange
    }

    set m_lastRunDef $itk_option(-runDefinition)
}

configbody DCS::PositionViewForQueue::positionDefinition {
    if { $m_lastPosition != "" && \
    $m_lastPosition != $itk_option(-positionDefinition) } {
        ::mediator unregister $this $m_lastPosition contents
    }

    if {$itk_option(-positionDefinition) != "" && \
    $m_lastPosition != $itk_option(-positionDefinition) } {
        ::mediator register $this $itk_option(-positionDefinition) contents \
        handlePositionDefinitionChange
    }

    set m_lastPosition $itk_option(-positionDefinition)
}

body DCS::PositionViewForQueue::handleRunDefinitionChange { run_ targetReady_ alias_ runDefinition_ -  } {

    if {!$targetReady_} return

    set m_lastPositionId [$run_ getField position_id]
    updateTitle
}

class DCS::QueueView {
    inherit ::itk::Widget

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    public method handleSampleInfoChange { \
    obj_ targetReady_ alias_ contents_ -  } {
        if {!$targetReady_} return

        puts "QueueView handleSampleInfoChange $contents_"

        configure -sampleInfo $contents_
    }

    public method hook { {master ""} } {
        if {$m_master != ""} {
            puts "ERROR $this already hooked to $m_master"
            return
        }

        set m_master $master

        if {$m_master == ""} {
            set m_master [SequenceCrystals::getFirstObject]
        }
        if {$m_master != ""} {
            $m_master register $this -sampleInfo handleSampleInfoChange
            puts "hook: to $m_master"
        }
    }

    public method addChildVisibilityControl { args } {
        eval $itk_component(runView) addChildVisibilityControl $args
    }

    private variable m_master ""

    constructor { args } {
        set ring $itk_interior 

        set WIDTH_PROMPT 12

        itk_component add runView {
            DCS::RunListViewForQueue $ring.rv
        } {
            keep -sampleInfo
            keep -videoParameters
            keep -videoEnabled
            keep -mdiHelper
        }

        eval itk_initialize $args


        pack $itk_component(runView) -expand 1 -fill both
    }
    destructor {
        if {$m_master != ""} {
            $m_master unregister $this -sampleInfo handleSampleInfoChange
        }
    }
}

### the list and the label for each item are from the header of the webservice.
### This class will monitor the string sil_detail_left/middle/right and
### call web service when the row eventID changes.
### The web call will return all run labels and states, followed by
### the current run definition or the first run definition if
### current run got removed.
class DCS::RunListViewForQueue {
    inherit ::itk::Widget ::DCS::Component
    
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -controlSystem controlsytem ControlSystem "::dcss"

    itk_option define -detailString detailString DetailString \
    [list \
    ::device::sil_detail_no \
    ::device::sil_detail_left \
    ::device::sil_detail_middle \
    ::device::sil_detail_right \
    ]

    ## This only change when different row is selected on the spreadsheet.
    #######################################################################
    ## cassette_index decides which sil_detail_xxxx to monitor.
    ##                It will be used to get sil_id too.
    ##
    ## row_index      decides which rowEventID to monitor in sil_detail_xxxx
    ##                
    ## uniquID        All webice calls prefer this uniqueID, not row_index.
    ##                It can be retrieved through cassette_index and row_index
    ##                it is complicated to get it that way.
    ##                So it is supplied here.
    ##
    ## reOrientable   decide what to display
    ##
    ## reOrientInfo   It is needed to display the video snapshot and
    ##                display the diffraction images.
    ##
    ## port           It is needed to check whether current sample mounted and
    ##                re-oriented.

    ## {cassette_index row_index uniqueID reOrientable infoPath port}
    itk_option define -sampleInfo sampleInfo SampleInfo \
    {1 0 "" 1 "" A1} {
        $m_sampleStatus configure \
        -sampleInfo $itk_option(-sampleInfo)


        foreach {cas row uniqueID reOrientable reOrientInfo port} \
        $itk_option(-sampleInfo) break

        set new_SIL [getSilID $cas]
        if {$m_lastCassette != $cas || $m_lastSIL != $new_SIL \
        || $m_lastRow != $row || $m_rowUniqueID != $uniqueID \
        || $m_reOrientable != $reOrientable \
        || $m_reOrientInfo != $m_reOrientInfo} {
            set m_lastCassette $cas
            set m_lastSIL $new_SIL
            set m_lastRow $row
            set m_rowUniqueID $uniqueID
            set m_reOrientable $reOrientable
            set m_reOrientInfo $reOrientInfo

            set m_lastRunIndex 0
            $itk_component(notebook) select 0
            #$itk_component(runView) showRunView

            puts "refreshDisplay sampleInfo: $itk_option(-sampleInfo)"
            refreshDisplay
        }
    }
    private variable BROWNRED #a0352a
    private variable ACTIVEBLUE #2465be
    private variable DARK #777
   
    public method handleDetailChange
    private method refreshDisplay
    private method refreshTabs { labels states }

    ### to setup right display for ADD_RUN
    ### it will fill beam size only for run
    ### it will fill position with full information
    private method generatePositionDefinitionFromReOrientInfo { }

    public method handleSampleInfoChange

    public method handlePageSwitch { index } {
        if {$m_lastRunIndex != $index} {
            set m_lastRunIndex $index
            refreshDisplay
        }
    }

    private method getSilID { cas_index } {
        set obj [lindex $itk_option(-detailString) $cas_index]
        if {$obj == ""} {
            return -1
        }
        if {[catch {$obj getContents} contents]} {
            log_error $contents
            return -1
        }
        set result [lindex $contents 0]
        if {![string is integer -strict $result]} {
            return -1
        }

        return $result
    }

    public method handleClientStatusChange
    public method addNewRun
    public method collect

    public method addChildVisibilityControl { args } {
        eval $itk_component(runView) addChildVisibilityControl $args
    }

    private variable m_master ""
    public method hook { {master ""} } {
        if {$m_master != ""} {
            puts "ERROR $this already hooked to $m_master"
            return
        }

        set m_master $master

        if {$m_master == ""} {
            set m_master [SequenceCrystals::getFirstObject]
        }
        if {$m_master != ""} {
            $m_master register $this -sampleInfo handleSampleInfoChange
            puts "hook: to $m_master"
        }
    }
    private method updateNewRunCommand 
   
    private variable m_clientState "offline"
    private variable m_numTab 0

    private variable m_lastCassette     0
    private variable m_lastSIL          -1
    private variable m_lastRowEventID   -1
    private variable m_lastRunIndex     0

    private variable m_lastRunLabels    "" 

    private variable m_lastRow          -1
    private variable m_rowUniqueID      ""
    private variable m_reOrientable     0
    private variable m_reOrientInfo     ""
    
    private variable m_sampleStatus
    private variable m_deviceFactory
    private variable m_objVirtualRun
    private variable m_objVirtualPosition

    constructor { args } {
        set m_sampleStatus  [DCS::SampleStatus::getObject]
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objVirtualRun \
        [$m_deviceFactory createVirtualRunString virtualRunForQueue]

        set m_objVirtualPosition \
        [$m_deviceFactory createVirtualString virtualPositionForQueue]

        set ring $itk_interior
      
        # make a folder frame for holding runs
        itk_component add notebook {
            iwidgets::tabnotebook $ring.n \
            -tabpos e -gap 4 -angle 20 -width 330 -height 800 \
            -raiseselect 1 -bevelamount 4 -padx 5 \
        } {}

        #add the tab
        $itk_component(notebook) add -label " * "
        set m_numTab 1
         
        #pack the single runView widget into the first childsite 
        set childsite [$itk_component(notebook) childsite 0]
        pack $childsite
        #select the first tab to see the runView and
        # then turn off the auto configuring
        $itk_component(notebook) select 0
        $itk_component(notebook) configure -auto off
      
        itk_component add runView {
            DCS::RunTopViewForQueue $childsite.rv \
            -tabStyle 0
        } {
            keep -videoParameters
            keep -videoEnabled
            keep -sampleInfo
        }

        pack $itk_component(runView) -side left -expand 1 -fill both

        pack $itk_component(notebook) -side top -anchor n -pady 0 -expand 1 -fill both

        eval itk_initialize $args   

        foreach detail $itk_option(-detailString) {
            ::mediator register $this $detail contents handleDetailChange
        }

        ::mediator register $this ::$itk_option(-controlSystem) clientState handleClientStatusChange   

        #allow observers to know what the embedded runViewer is looking at.
        exportSubComponent runDefinition ::$itk_component(runView) 

        announceExist

   }

    destructor {
        if {$m_master != ""} {
            $m_master register $this -sampleInfo handleSampleInfoChange
        }
    }
}


body DCS::RunListViewForQueue::addNewRun {} {
    ###TODO:fill virtualRun first

    set copyFrom $m_lastRunIndex
    #set copyFrom [expr $m_numTab - 2]
    set m_lastRunIndex -1

    $itk_component(runView) showRunView
    $itk_component(runView) configure \
    -runLabels $m_lastRunLabels \
    -copyRunIndex $copyFrom \
    -displayMode ADD_RUN
}

body DCS::RunListViewForQueue::generatePositionDefinitionFromReOrientInfo { } {
    set position $::DCS::PositionFieldForQueue::DEFAULT

    if {$m_reOrientInfo == ""} {
        return $position
    }
    if {[catch {open $m_reOrientInfo r} h]} {
        log_error cannot open $m_reOrientInfo to read
        return $position
    }
    set contents [read $h]
    catch {close $h}
    array set reorient_info_array [list]
    parseReOrientInfo $contents reorient_info_array
    catch {
        ::DCS::PositionFieldForQueue::setList position \
        file_reorient_0 $reorient_info_array(REORIENT_VIDEO_FILENAME_0) \
        file_reorient_1 $reorient_info_array(REORIENT_VIDEO_FILENAME_1)
    }
    catch {
        ::DCS::PositionFieldForQueue::setList position \
        file_box_0 $reorient_info_array(REORIENT_BOX_FILENAME_0) \
        file_box_1 $reorient_info_array(REORIENT_BOX_FILENAME_1)
    }
    catch {
        ::DCS::PositionFieldForQueue::setList position \
        file_diff_0 $reorient_info_array(REORIENT_DIFF_FILENAME_0) \
        file_diff_1 $reorient_info_array(REORIENT_DIFF_FILENAME_1)
    }
    catch {
        ::DCS::PositionFieldForQueue::setList position \
        beam_width $reorient_info_array(REORIENT_BEAM_WIDTH) \
        beam_height $reorient_info_array(REORIENT_BEAM_HEIGHT)
    }
    if {[catch {
        ::DCS::PositionFieldForQueue::setList position \
        beamline $reorient_info_array(REORIENT_BEAMLINE) \
        detector_type $reorient_info_array(REORIENT_DETECTOR) \
        energy $reorient_info_array(REORIENT_ENERGY) \
        distance $reorient_info_array(REORIENT_DISTANCE) \
        beam_stop $reorient_info_array(REORIENT_BEAM_STOP) \
        attenuation $reorient_info_array(REORIENT_ATTENUATION) \
        camera_zoom $reorient_info_array(REORIENT_CAMERA_ZOOM) \
        sample_scale_factor $reorient_info_array(REORIENT_SCALE_FACTOR) \
        delta $reorient_info_array(REORIENT_DIFF_DELTA_0) \
        exposure_time $reorient_info_array(REORIENT_DIFF_EXPOSURE_TIME_0) \
        detector_mode $reorient_info_array(REORIENT_DIFF_MODE_0) \
    } errMsg]} {
        puts "set position error: $errMsg"
    }

    return $position
}
body DCS::RunListViewForQueue::refreshTabs { labels states } {
    puts "Refresh tab: $labels $states"

    set m_lastRunLabels $labels

    $itk_component(runView) configure \
    -runLabels $m_lastRunLabels \

    set numRun [llength $labels]

    set numTabNeed [expr $numRun + 1]

    if {$numTabNeed > $m_numTab} {
        set num [expr $numTabNeed - $m_numTab]
        for {set i 0} {$i < $num} {incr i} {
            $itk_component(notebook) add
        }
    } elseif {$numTabNeed < $m_numTab} {
        ## never delete the page 0.  That is the only page we really use.
        $itk_component(notebook) delete $numTabNeed end
    }

    set m_numTab $numTabNeed

    ##DEBUG
    set numTab [$itk_component(notebook) index end]
    incr numTab
    if {$m_numTab != $numTab} {
        puts "num tab from notebook is $numTab != $m_numTab"
    }

    set i 0
    foreach run_label $labels run_state $states {

        switch -exact -- $run_state {
            paused { set color $BROWNRED }
            collecting {set color red }
            inactive {set color $ACTIVEBLUE }
            complete { set color $DARK }
            default { set color red }
        }

        $itk_component(notebook) pageconfigure $i \
        -label $run_label \
        -foreground $color \
        -state normal \
        -selectforeground $color \
        -command "$this handlePageSwitch $i"

        incr i   
    }
    updateNewRunCommand 
}
body DCS::RunListViewForQueue::refreshDisplay { } {
    set m_lastRowEventID -1

    if {$m_lastSIL < 0 || $m_lastRow < 0 || $m_reOrientable != "1" \
    || $m_rowUniqueID == ""} {
        puts "refresh NOT REORIENTABLE"
        refreshTabs {} {}
        $itk_component(runView) configure \
        -displayMode NOT_REORIENTABLE
        return
    }
    if {[catch {
        set user [$itk_option(-controlSystem) getUser]
        set SID [$itk_option(-controlSystem) getSessionId]
        set run_id $m_lastRunIndex
        if {$run_id < 0} {
            ### it was on * (Add) page
            set run_id 0
        }

        set data [getRunDefinitionForQueue $user $SID \
        $m_lastSIL $m_lastRow $m_rowUniqueID \
        $run_id \
        ]

        puts "data From Web: $data"

        ### the data may not have run or position
        set run ""
        set position ""
        foreach {silid row_num unique_id row_event \
        labels states run \
        position_labels position_states position_scores position} \
        $data break
    } errMsg]} {
        log_error failed to get data from web: $errMsg
        puts "failed to get data from web: $errMsg"
        $itk_component(runView) configure \
        -displayMode NOT_REORIENTABLE
        return
    }

    puts "refresh run: $run position: $position"
    if {$silid != $m_lastSIL || $row_num != $m_lastRow \
    || $unique_id != $m_rowUniqueID} {
        puts "DEBUG: logical conflict from web ice"
        puts "sil $silid != $m_lastSIL || row $row_num != $m_lastRow"
        puts "|| unique_id $unique_id != $m_rowUniqueID"
    }
    set m_lastRowEventID $row_event
    ##TODO: recheck the row event id again
    if {$run == "" && $position == ""} {
        log_error data from sil are empty
        $itk_component(runView) configure \
        -displayMode NOT_REORIENTABLE
        return 
    }

    refreshTabs $labels $states

    if {$run == ""} {
        set run $::DCS::RunFieldForQueue::DEFAULT
    }

    if {$position == ""} {
        set position [generatePositionDefinitionFromReOrientInfo]
    }
    ###FAKE DEBUG
    #set position_labels [list p0 p1 p2 p3]
    #set position_states [list 1  1  1  1]

    $m_objVirtualRun      setContents normal $run
    $m_objVirtualPosition setContents normal $position

    set pidFromRun -1
    if {[catch {
        set pidFromRun [$m_objVirtualRun getField position_id]
        puts "pidFromRun: $pidFromRun"
    } errMsg]} {
        puts "get position_id failed from run: $errMsg"
    }
    if {![string is integer -strict $pidFromRun]} {
        set pidFromRun -1
    }

    set init_snapshots ""
    set init_name "Not Available"
    if {[catch {
        set init_snapshots [DCS::PositionFieldForQueue::getList position \
        file_box_0 file_box_1]

        set init_name [DCS::PositionFieldForQueue::getField position \
        position_name]

        puts "pidFromRun: $pidFromRun"
    } errMsg]} {
        puts "get snapshots from position failed: $errMsg"
        set init_snapshots ""
        set init_name "Not Available"
    }
    puts "init_snapshots: $init_snapshots"

    set positionLabels [list $position_labels $position_states $position_scores]
    $itk_component(runView) configure \
    -positionLabels $positionLabels \
    -positionFromRun $pidFromRun \
    -snapshot $init_snapshots \
    -positionName $init_name

    set run_index [$m_objVirtualRun getField run_id]
    if {$m_lastRunIndex != $run_index} {
        puts "new run index: $run_index"

        set m_lastRunIndex $run_index
        set page $m_lastRunIndex
        if {$page < 0} {
            set page 0
        }
        $itk_component(notebook) select $page
    }
    if {$labels == ""} {
        $itk_component(runView) configure \
        -displayMode ADD_RUN
    } else {
        $itk_component(runView) configure \
        -displayMode FULL
    }
}
body DCS::RunListViewForQueue::handleSampleInfoChange { obj_ targetReady_ alias_ contents_ -  } {
    if {!$targetReady_} return

    puts "RunLstViewForQueue handleSampleInfoChange $contents_"
    configure -sampleInfo $contents_
}
body DCS::RunListViewForQueue::handleDetailChange { detailName_ targetReady_ alias_ contents_ -  } {
    if {!$targetReady_} return

    puts "handleDetailChange: $detailName_ $contents_"
    puts "last row: $m_lastRow rowEvent: $m_lastRowEventID"

    set expecting [lindex $itk_option(-detailString) $m_lastCassette]
    if {$expecting != $detailName_} {
        return
    }
    set newSil -1
    set eventID -1
    set rowEventList {}
    foreach {newSil eventID rowEventList} $contents_ break
    set newRowEventID [lindex $rowEventList $m_lastRow]
    
    if {$newSil != $m_lastSIL || $newRowEventID != $m_lastRowEventID} {
        puts "new: $newSil $newRowEventID"
        puts "old: $m_lastSIL $m_lastRowEventID"
        set m_lastSIL $newSil
        refreshDisplay
    }
}

body DCS::RunListViewForQueue::handleClientStatusChange { control_ targetReady_ alias_ clientStatus_ -  } {
   if { !$targetReady_ } return

   if {$clientStatus_ != "active"} {
      $itk_component(notebook) pageconfigure end -state disabled
   } else {
      $itk_component(notebook) pageconfigure end -state normal 
   }

   set m_clientState $clientStatus_
}

body DCS::RunListViewForQueue::updateNewRunCommand {} {
        #configure the 'add run' star
        $itk_component(notebook) pageconfigure end \
        -label " * " \
        -command [list $this addNewRun ] 

        if {$m_clientState != "active" || $m_numTab < 2} {
            $itk_component(notebook) pageconfigure end -state disabled
        }
}

body DCS::RunListViewForQueue::collect {} {

   #puts COLLECT

    global env

    #focus .

    # set currently selected run as current run
    set currentRun [$itk_component(notebook) index select]
    if { $currentRun < 1 } {
        set currentRun 0
    }

    # if doing snapshot set end frame to next frame
    set user [$itk_option(-controlSystem) getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
    
    if { ($currentRun == 0)} {
      set collectOperation [$m_deviceFactory createOperation collectRun]
        $collectOperation startOperation 0 $user [$itk_component(runView) getReuseDarkSelection] $SID
    } else {
      set collectOperation [$m_deviceFactory createOperation collectRuns]
        # send the start message to the server
        $collectOperation startOperation $currentRun $SID
    }

}

###only sample position will be instant moved.
###other parameters are like the collecting,
###They will be moved when collecting starts.
###
#############3
### We do not want to allow user to change DIR and NAME,
### So, they are not displayed here.
### User can find out the path on Log Tab.
###
#####################################
### always dose mode
### between 2 images.
#####################################
class DCS::AdjustViewForQueue {
    inherit ::itk::Widget ::DCS::Component

    itk_option define -controlSystem controlsytem ControlSystem "::dcss"

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -runForPositionCheck runForPositionCheck RunDefinition \
    ::device::run_for_adjust

    itk_option define -runDefinition runDefinition RunDefinition \
    ::device::virtualRunForQueue

    ### needed for non-tab version
    itk_option define -cmdSwitchView cmdSwitchView CmdSwitchView ""

    itk_option define -tabStyle tabStyle TabStyle 1 {
        if {$itk_option(-tabStyle)} {
            grid forget $itk_component(cancel)
        } else {
            grid $itk_component(cancel) -row 0 -column 4 -sticky e
        }
    }

    itk_option define -positionLabels positionLabels PositionLabels "" {
        puts "start -positionLabels for adjustView"
        puts "data: $itk_option(-positionLabels)"
        puts "no calls"
    }

    private variable m_deviceFactory
    private variable m_sampleStatus

    private variable m_lastRunForPC ""
    private variable m_lastRunDef ""

    private variable m_runPosition {0 0 0}
    private variable m_checkedPosition {0 0 0}

    ## whether position is runDefinition and runforPositionCheck match
    private variable m_match 0

    private variable m_fieldMotorMap
    ### generated from m_fieldMotorMap (array)
    private variable m_fieldList

    public method handleUpdate { }
    public method handleDefault { }

    public method handleRunDefinitionChange
    public method handleRunForPositionCheckChange

    public method getMatch { } {
        return $m_match
    }

    public method addChildVisibilityControl { args } {
        eval $itk_component(video) addChildVisibilityControl $args
    }

    public method changeToRunView { } {
        eval $itk_option(-cmdSwitchView)
    }

    private method setEntryComponentDirectly 

    private method checkMatch

    constructor { args } {
        ::DCS::Component::constructor { position_match getMatch }
    } {
        global gMotorPhi
        global gMotorOmega
        global gMotorDistance
        global gMotorBeamStop
        global gMotorBeamWidth
        global gMotorBeamHeight
        global gMotorEnergy
        global gMotorVert
        global gMotorHorz


        set m_sampleStatus [DCS::SampleStatus::getObject]
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set WIDTH_PROMPT 14
        set WIDTH_ENTRY 12
        set ring $itk_interior

        # make a frame of beamsize
        itk_component add beamSizeFrame {
            iwidgets::labeledframe $ring.bsF \
            -labelpos nw \
            -labeltext "Beam Size" \
            -labelfont "helvetica -16 bold"
        } {}
        set sizeSite [$itk_component(beamSizeFrame) childsite]

        itk_component add cross {
            label $sizeSite.cross \
            -text "x" \
            -font "helvetica -14 bold"
        } {
        }
        itk_component add width {
            DCS::Entry $sizeSite.width \
            -shadowReference 0 \
            -reference "::device::$gMotorBeamWidth scaledPosition" \
            -showPrompt 0 \
            -entryWidth 10 \
            -units "mm" \
            -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1
        } {}

        set m_fieldMotorMap(beam_width) ::device::$gMotorBeamWidth

        itk_component add height {
            DCS::Entry $sizeSite.height \
            -shadowReference 0 \
            -reference "::device::$gMotorBeamHeight scaledPosition" \
            -showPrompt 0 \
            -entryWidth 10 \
            -units "mm" \
            -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1
        } {}

        set m_fieldMotorMap(beam_height) ::device::$gMotorBeamHeight

        pack $itk_component(width) -side left
        pack $itk_component(cross) -side left -anchor s
        pack $itk_component(height) -side left

        itk_component add video {
            DCS::SampleVideoAndLightControl $ring.avg_video \
            -beamWidthWidget  $itk_component(width) \
            -beamHeightWidget $itk_component(height)
        } {
            keep -videoParameters
            keep -videoEnabled 
        }

        itk_component add detectorMode {
            DCS::DetectorModeMenu $ring.dm -entryWidth 19 \
            -promptText "Detector: " \
            -promptWidth $WIDTH_PROMPT \
            -showEntry 0 \
            -entryType string \
            -entryJustify center \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 1 
        } {
            keep -font
        }

        ##### energy, distance, beamstop, attenuation
        itk_component add adjust_frame {
            frame $ring.adjustF
        } {
        }
        set adjustableSite $itk_component(adjust_frame)
        itk_component add energy {
            DCS::MotorViewEntry $adjustableSite.e \
            -leaveSubmit 1 \
            -showPrompt 1 \
            -promptText "Energy: " \
            -promptWidth $WIDTH_PROMPT \
            -unitsList eV -units eV \
            -device ::device::$gMotorEnergy \
            -shadowReference 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth $WIDTH_ENTRY \
            -escapeToDefault 0 \
            -autoConversion 1 \
            -systemIdleOnly 0 \
            -activeClientOnly 1 \
            -nullAllowed 1
        } {}

        set m_fieldMotorMap(energy1) ::device::$gMotorEnergy

        itk_component add distance {
            DCS::MotorViewEntry $adjustableSite.distance \
            -leaveSubmit 1 \
            -showPrompt 1 \
            -promptText "Distance: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::$gMotorDistance \
            -entryWidth $WIDTH_ENTRY \
            -units "mm" -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -activeClientOnly 1 \
            -systemIdleOnly 0 \
            -autoConversion 1
        } {}

        set m_fieldMotorMap(distance) ::device::$gMotorDistance

        itk_component add beam_stop {
            DCS::MotorViewEntry $adjustableSite.beam_stop \
            -leaveSubmit 1 \
            -showPrompt 1 \
            -promptText "Beam Stop: " \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth $WIDTH_ENTRY \
            -units "mm" -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -device ::device::$gMotorBeamStop \
            -activeClientOnly 1 \
            -systemIdleOnly 0 \
            -autoConversion 1
        } {}

        set m_fieldMotorMap(beam_stop) ::device::$gMotorBeamStop

        itk_component add delta {
            DCS::Entry $adjustableSite.delta -promptText "Delta: " \
            -leaveSubmit 1 \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth $WIDTH_ENTRY \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 1
        } {}

        itk_component add attenuation {
            DCS::MotorViewEntry $adjustableSite.attenuation \
            -leaveSubmit 1 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -promptText "Attenuation: " \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth $WIDTH_ENTRY \
            -units "%" \
            -unitsList "%" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -activeClientOnly 1 \
            -systemIdleOnly 0 \
            -autoConversion 1
        } {}

        set m_fieldMotorMap(attenuation) ::device::attenuation

        itk_component add exposureTime {
            DCS::Entry $adjustableSite.time \
            -leaveSubmit 1 \
            -shadowReference 0 \
            -promptText "Time: " \
            -promptWidth $WIDTH_PROMPT \
            -entryWidth $WIDTH_ENTRY \
            -units "s" \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -systemIdleOnly 0 \
            -activeClientOnly 1
        } {}

        pack $itk_component(energy) -side top -anchor w
        pack $itk_component(distance)         -anchor w
        pack $itk_component(beam_stop)        -anchor w
        pack $itk_component(delta)            -anchor w
        pack $itk_component(attenuation)      -anchor w
        pack $itk_component(exposureTime)     -anchor w

        itk_component add command_frame {
            frame $ring.commandF
        } {
        }
        set commandSite $itk_component(command_frame)

        itk_component add shortcut_frame {
            frame $ring.shortcutF
        } {
        }
        set shortcutSite $itk_component(shortcut_frame)
        itk_component add def {
            DCS::Button $shortcutSite.default \
            -text "Default" \
            -width 8 \
            -command "$this handleDefault"
        } {
        }

        itk_component add update {
            DCS::Button $shortcutSite.update \
            -text "Update" \
            -width 8 \
            -command "$this handleUpdate"
        } {
        }

        pack $itk_component(def)    -side left
        pack $itk_component(update) -side right

        itk_component add webice {
            DCS::Button $commandSite.webice \
            -text "WebIce" \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -command "$this openWebIce" 
        } {}

        label $commandSite.l1 \
        -text "or" \
        -width 4

        itk_component add check {
            DCS::Button $commandSite.check \
            -text "Check this position" \
        } {
        }
        $itk_component(check) addInput \
        [list $m_sampleStatus reoriented 1 "Mount and ReOrient Sample First"]
        $itk_component(check) addInput \
        [list $m_sampleStatus position_checked 0 "already checked"]

        itk_component add commit {
            DCS::Button $commandSite.submit \
            -text "Commit new position to run" \
        } {
        }
        $itk_component(commit) addInput \
        [list $m_sampleStatus reoriented 1 "Mount and ReOrient Sample First"]
        $itk_component(commit) addInput \
        [list $m_sampleStatus position_checked 1 "check this position first"]
        $itk_component(commit) addInput \
        [list $this position_match 0 "position already in the run"]

        itk_component add cancel {
            button $commandSite.cancel \
            -command "$this changeToRunView" \
            -text "Cancel" \
        } {
        }

        grid $itk_component(webice) -row 0 -column 0 -sticky e
        grid $commandSite.l1        -row 0 -column 1 -sticky e
        grid $itk_component(check)  -row 0 -column 2 -sticky e
        grid $itk_component(commit) -row 0 -column 3 -sticky e
        #grid $itk_component(cancel) -row 0 -column 4 -sticky e
        grid columnconfig $commandSite 4 -weight 10

        set m_fieldList [array names m_fieldMotorMap]

        itk_component add score_list_view {
            DCS::PositionListViewForQueue $ring.sl
        } {
            keep -runDefinition
            keep -positionLabels
            keep -positionFromRun
            keep -snapshot
            keep -positionName
        }

        grid $itk_component(score_list_view) \
        -row 0 -column 0 -rowspan 5 -sticky news

        grid $itk_component(video) \
        -row 0 -column 1 -sticky news

        grid $itk_component(shortcut_frame) \
        -row 1 -column 1 -sticky we

        grid $itk_component(beamSizeFrame) \
        -row 2 -column 1 -sticky w

        grid $itk_component(adjust_frame) \
        -row 3 -column 1 -sticky wn

        grid $itk_component(command_frame) \
        -row 4 -column 1 -sticky we

        grid columnconfig $ring 1 -weight 10
        grid rowconfig $ring 0 -weight 10

        eval itk_initialize $args
        announceExist
    }
}
configbody DCS::AdjustViewForQueue::runDefinition {
    if { $m_lastRunDef != "" && \
    $m_lastRunDef != $itk_option(-runDefinition) } {
        ::mediator unregister $this $m_lastRunDef contents
    }

    if {$itk_option(-runDefinition) != "" && \
    $m_lastRunDef != $itk_option(-runDefinition) } {
        ::mediator register $this $itk_option(-runDefinition) contents \
        handleRunDefinitionChange
    }

    set m_lastRunDef $itk_option(-runDefinition)
}
body DCS::AdjustViewForQueue::checkMatch { } {
    foreach {x1 y1 z1} $m_runPosition break
    foreach {x2 y2 z2} $m_checkedPosition break

    if {$x1 == ""} {
        set x1 0
    }
    if {$y1 == ""} {
        set y1 0
    }
    if {$z1 == ""} {
        set z1 0
    }

    set THRESHOLD 0.0001
    if {abs($x1 - $x2) > $THRESHOLD \
    || abs($y1 - $y2) > $THRESHOLD
    || abs($z1 - $z2) > $THRESHOLD} {
        set match 0
    } else {
        set match 1
    }

    if {$m_match != $match} {
        set m_match $match
        updateRegisteredComponents position_match
    }
}
body DCS::AdjustViewForQueue::handleUpdate { } {
    global gMotorPhi
    global gMotorOmega
    global gMotorDistance
    global gMotorBeamStop
    global gMotorEnergy
    global gMotorBeamWidth
    global gMotorBeamHeight

    ### attenuation needs check with limits from default parameters too.
    set cmdList [list $itk_option(-runForPositionCheck) setList]

    foreach name $m_fieldList {
        set motor $m_fieldMotorMap($name)
        set curP [lindex [$motor getScaledPosition] 0]

        ### this call will adjust currentPosition if needed
        if {[$motor limits_ok curP]} {
            log_warning $motor current position out of limits, using $curP
        }

        lappend cmdList $name $curP
    }

    eval $cmdList
}
configbody DCS::AdjustViewForQueue::runForPositionCheck {
    global gMotorDistance
    global gMotorBeamStop

    puts "config runForPositionCheck to $itk_option(-runForPositionCheck)"

    $itk_component(width) configure \
    -onSubmit "$itk_option(-runForPositionCheck) setBeamWidth %s"

    $itk_component(height) configure \
    -onSubmit "$itk_option(-runForPositionCheck) setBeamHeight %s"

    $itk_component(energy) configure \
    -onSubmit "$itk_option(-runForPositionCheck) setEnergyList %s"

    #$itk_component(detectorMode) configure \
    #-onSubmit "$itk_option(-runForPositionCheck) setDetectorMode %s"

    $itk_component(distance) configure \
    -onSubmit "$itk_option(-runForPositionCheck) setDistance %s"

    $itk_component(beam_stop) configure \
    -onSubmit "$itk_option(-runForPositionCheck) setBeamStop %s" \

    $itk_component(delta) configure \
    -onSubmit "$itk_option(-runForPositionCheck) setDelta %s" \
    -reference "$itk_option(-runForPositionCheck) delta"

    $itk_component(attenuation) configure \
    -onSubmit "$itk_option(-runForPositionCheck) setAttenuation %s"

    $itk_component(exposureTime) configure \
    -onSubmit "$itk_option(-runForPositionCheck) setExposureTime %s" \
    -reference "$itk_option(-runForPositionCheck) exposureTime"

    if { $m_lastRunForPC != "" && \
    $m_lastRunForPC != $itk_option(-runForPositionCheck) } {
        $m_lastRunForPC unregister \
        $this contents handleRunForPositionCheckChange
    }

    if {$itk_option(-runForPositionCheck) != "" && \
    $m_lastRunForPC != $itk_option(-runForPositionCheck) } {
        $itk_option(-runForPositionCheck) register \
        $this contents handleRunForPositionCheckChange
    }

    set m_lastRunForPC $itk_option(-runForPositionCheck)
}
body DCS::AdjustViewForQueue::handleRunDefinitionChange { run_ targetReady_ alias_ runDefinition_ -  } {

    if {!$targetReady_} return

    set m_runPosition [$run_ getList reposition_x reposition_y reposition_z]
    checkMatch
}
body DCS::AdjustViewForQueue::handleRunForPositionCheckChange { run_ targetReady_ alias_ runDefinition_ -  } {
    puts "enter handle run4PC defintion change"

    if {!$targetReady_} return

    puts "handle run4PC defintion change"

    foreach { \
    width height \
    detectorMode distance beamStop \
    delta \
    attenuation exposureTime \
    energy \
    } [$run_ getList \
    beam_width beam_height \
    detector_mode distance beam_stop \
    delta \
    attenuation exposure_time \
    energy1] break

    #set directly
    setEntryComponentDirectly width $width
    setEntryComponentDirectly height $height
    setEntryComponentDirectly energy $energy
    $itk_component(detectorMode) setValueByIndex $detectorMode 1
    setEntryComponentDirectly distance $distance
    setEntryComponentDirectly beam_stop $beamStop
    setEntryComponentDirectly attenuation $attenuation
    setEntryComponentDirectly delta $delta
    setEntryComponentDirectly exposureTime $exposureTime 

    set m_checkedPosition [$run_ getList reposition_x reposition_y reposition_z]
    checkMatch
}

body DCS::AdjustViewForQueue::setEntryComponentDirectly { component_ value_ } {
   $itk_component($component_) setValue $value_ 1
}

body DCS::AdjustViewForQueue::handleDefault { } {
    ### will change to operation later

    if {[$m_deviceFactory stringExists run_for_adjust_default]} {
        set defaultObj [$m_deviceFactory getObjectName run_for_adjust_default]
        set defaultContents [$defaultObj getContents]
        $itk_option(-runForPositionCheck) sendContentsToServer $defaultContents
    }
    
}

#### tab with runOverView or adjust view
class DCS::RunTopViewForQueue {
    inherit ::itk::Widget ::DCS::Component
    
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -controlSystem controlsytem ControlSystem "::dcss"

    itk_option define -tabStyle tabStyle TabStyle 1

    itk_option define -sampleInfo sampleInfo SampleInfo \
    {1 0 "" 1 "" A1} {
        updateAdjustTab
        showRunView
    }

    public method addChildVisibilityControl { args } {
        eval $itk_component(notebook) addChildVisibilityControl $args
    }

    public method showRunView { } {
        $itk_component(notebook) select 0
        if {!$itk_option(-tabStyle)} {
            pack forget $itk_component(run_adjust)
            pack $itk_component(run_overall) -expand 1 -fill both
            puts "showing runView"
        }
    }

    public method showAdjustView { } {
        $itk_component(notebook) select 1
        if {!$itk_option(-tabStyle)} {
            pack forget $itk_component(run_overall)
            pack $itk_component(run_adjust) -expand 1 -fill both
            puts "showing ajustView"
        }
    }


    public method handleSampleInfoChange

    ### following 2 to decide whether current sample mounted and reoriented
    ### "current sample" means the sample selected from master view
    ### set by -sampleInfo
    public method handleRobotStatusChange
    public method handleCrystalStatusChange

    public method hook { {master ""} } {
        if {$m_master != ""} {
            puts "ERROR $this already hooked to $m_master"
            return
        }

        set m_master $master

        if {$m_master == ""} {
            set m_master [SequenceCrystals::getFirstObject]
        }
        if {$m_master != ""} {
            $m_master register $this -sampleInfo handleSampleInfoChange
            puts "hook: to $m_master"
        }
    }


    private method updateAdjustTab

    private variable m_master ""

    private variable m_deviceFactory ""
    private variable m_objRobotStatus ""
    private variable m_objCrystalStatus ""
    private variable m_ctsRobotStatus ""
    private variable m_ctsCrystalStatus ""

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objRobotStatus   [$m_deviceFactory createString robot_status]
        set m_objCrystalStatus [$m_deviceFactory createString crystalStatus]

        ### even for non-tab style, we still use this tab to
        ### decide whether video got update
        itk_component add notebook {
            DCS::TabNotebook $itk_interior.n \
            -tabbackground lightgrey \
            -background lightgrey \
            -backdrop lightgrey \
            -borderwidth 2\
            -tabpos n \
            -gap -4 \
            -angle 20 \
            -raiseselect 1 \
            -bevelamount 4 \
        } {
        }

        set runSite    [$itk_component(notebook) add Run -label "RunView"]
        set adjustSite [$itk_component(notebook) add Adjust -label \
        "Add New Position"]

        ### we need to know this option before build gui
        set isTabStyle 1
        set tabOptionIndex [lsearch -exact $args "-tabStyle"]
        if {$tabOptionIndex >= 0} {
            incr tabOptionIndex
            set isTabStyle [lindex $args $tabOptionIndex]
            puts "got tabStyle=$isTabStyle"
        }

        if {!$isTabStyle} {
            set runSite    $itk_interior
            set adjustSite $itk_interior
        }

        itk_component add run_overall {
            DCS::RunOverViewForQueue $runSite.runList \
            -cmdSwitchView "$this showAdjustView"
        } {
            keep -mdiHelper
            keep -displayMode
            keep -copyRunIndex
            keep -runLabels
            keep -tabStyle
            keep -positionLabels
        }

        itk_component add run_adjust {
            DCS::AdjustViewForQueue $adjustSite.adjust \
            -cmdSwitchView "$this showRunView"
        } {
            keep -mdiHelper
            keep -videoParameters
            keep -videoEnabled
            keep -tabStyle
            keep -positionLabels
            keep -positionFromRun
            keep -snapshot
            keep -positionName
        }

        $itk_component(run_adjust) \
        addChildVisibilityControl $itk_component(notebook) activeTab Adjust

        if {$isTabStyle} {
            pack $itk_component(run_overall) -expand 1 -fill both
            pack $itk_component(run_adjust) -expand 1 -fill both
            pack $itk_component(notebook) -expand 1 -fill both
        } else {
            pack $itk_component(run_overall) -expand 1 -fill both
        }

        eval itk_initialize $args

        announceExist

        $m_objRobotStatus   register $this contents handleRobotStatusChange
        $m_objCrystalStatus register $this contents handleCrystalStatusChange

        exportSubComponent runDefinition ::$itk_component(run_overall) 
   }

    destructor {
        $m_objRobotStatus   unregister $this contents handleRobotStatusChange
        $m_objCrystalStatus unregister $this contents handleCrystalStatusChange
        if {$m_master != ""} {
            $m_master register $this -sampleInfo handleSampleInfoChange
        }
    }
}
body DCS::RunTopViewForQueue::handleSampleInfoChange { obj_ targetReady_ alias_ contents_ -  } {
    if {!$targetReady_} return

    puts "RunTopViewForQueue handleSampleInfoChange $contents_"
    configure -sampleInfo $contents_
}
body DCS::RunTopViewForQueue::handleRobotStatusChange { \
- targetReady_ - contents_ -  } {
    if {!$targetReady_} return

    set m_ctsRobotStatus $contents_

    updateAdjustTab
}
body DCS::RunTopViewForQueue::handleCrystalStatusChange { \
- targetReady_ - contents_ -  } {
    if {!$targetReady_} return

    set m_ctsCrystalStatus $contents_

    updateAdjustTab
}
body DCS::RunTopViewForQueue::updateAdjustTab { } {
    if {!$itk_option(-tabStyle)} return

    #### disable adjust tab if the sample selected from master spreadsheet
    #### is not mounted_and_reoriented.
    foreach {cas row uniqueID reOrientable reOrientInfo port} \
    $itk_option(-sampleInfo) break

    ## here reOrientable != "1" is in case it is ""
    if {$cas < 1 || $row < 0 || $uniqueID == "" || $reOrientable != "1" \
    || $port == ""} {
        puts "sampleInfo disabled tab"
        $itk_component(notebook) pageconfigure 1 -state disabled
        return
    }

    set casList [list n l m r]
    set portFromMaster [lindex $casList $cas]$port

    set mounted    [lindex $m_ctsCrystalStatus 3]
    set synced     [lindex $m_ctsCrystalStatus 5]
    set reoriented [lindex $m_ctsCrystalStatus 6]
    if {$mounted != "1" || $synced != "yes" || $reoriented != "1"} {
        puts "crystalStatus disabled tab"
        $itk_component(notebook) pageconfigure 1 -state disabled
        showRunView
        return
    }

    set portRobot [lindex $m_ctsRobotStatus 15]
    if {[llength $portRobot] < 3} {
        puts "robotStatus disabled tab"
        $itk_component(notebook) pageconfigure 1 -state disabled
        showRunView
        return
    }

    ## now compare port with portRobot
    foreach {cas row col} $portRobot break
    set portFromRobot $cas$col$row

    if {$portFromRobot != $portFromMaster} {
        puts "portFromRobot $portFromRobot != portFromMaster: $portFromMaster"
        $itk_component(notebook) pageconfigure 1 -state disabled
        showRunView
        return
    }

    ### TODO:
    ### we may check the run_for_adjust too

    #### you passed all tests:
    $itk_component(notebook) pageconfigure 1 -state normal
    return
}

## so we can easily change tab and list view level
class DCS::RunOverViewForQueue {
    inherit ::itk::Widget ::DCS::Component
    
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -controlSystem controlsytem ControlSystem "::dcss"

    itk_option define -runLabels runLabels RunLabels {} {
        set choices [list]
        foreach l $itk_option(-runLabels) {
            lappend choices Run$l
        }

        $itk_component(runIndex) configure \
        -menuChoices $choices
    }

    itk_option define -copyRunIndex copyRunIndex CopyRunIndex -1 {
        if {$itk_option(-copyRunIndex) >= 0} {
            set txt \
            Run[lindex $itk_option(-runLabels) $itk_option(-copyRunIndex)]

            $itk_component(runIndex) \
            setValue $txt 1
            pack $itk_component(copy_frame)
        } else {
            pack forget $itk_component(copy_frame)
        }
    }

    ## NOT_REORIENTABLE: just a label
    ## ADD_RUN:          a few buttons and position
    ## FULL:             run and position
    itk_option define -displayMode displayMode DisplayMode FULL {
        updateDisplayMode
    }

    private method updateDisplayMode

    public method openWebIce { } {
        set user [$itk_option(-controlSystem) getUser]
        set SID [$itk_option(-controlSystem) getSessionId]
        set url [::config getWebIceShowRunStrategyUrl]

        set positionDef [$itk_component(positionView) cget -positionDefinition]
        set contents [$positionDef getContents]
        foreach {sil row unique_id position_id} \
        [::DCS::PositionFieldForQueue::getList contents \
        sil_id row_id unique_id position_id] break

        append url "?userName=$user"
        append url "&SMBSessionID=$SID"
        append url "&beamline=[::config getConfigRootName]"
        append url "&silId=$sil"
        append url "&row=$row"
        append url "&uniqueId=$unique_id"
        append url "&repositionId=$position_id"

        if {[catch {openWebWithBrowser $url} result]} {
            log_error "failed to open webice: $result"
        } else {
            $itk_component(webice) configure -state disabled
            after 10000 [list $itk_component(webice) configure -state normal]
        }

    }

    private variable m_lastCassette     0

    private variable m_reOrientable     0
    private variable m_reOrientInfo     ""
    
    private variable m_master ""

    private variable m_lastDisplayMode "FULL"

    constructor { args } {
        global gMotorPhi
        global gMotorOmega
        global gMotorDistance
        global gMotorBeamStop
        global gMotorBeamWidth
        global gMotorBeamHeight
     
        set ring $itk_interior
        set childsite $ring
      
        itk_component add positionView {
            DCS::PositionViewForQueue $childsite.ev \
        } {
            keep -cmdSwitchView
            keep -tabStyle
            keep -positionLabels
        }

        itk_component add runView {
            DCS::RunViewForQueue $childsite.rv 
        } {}


        itk_component add preview_frame {
            frame $itk_interior.previewF
        } {
        }

        set previewSite $itk_component(preview_frame)

        itk_component add positionFrame {
            ::iwidgets::labeledframe $previewSite.lf \
            -labeltext "Current Position"
        } {
        }

        set pos [$itk_component(positionFrame) childsite]

        set WIDTH_PROMPT 12

        itk_component add beam_width {
            DCS::MotorView $pos.bw \
            -promptText "Beam Width: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::$gMotorBeamWidth \
            -positionWidth 8 \
            -decimalPlaces 2
        } {
        }

        itk_component add beam_height {
            DCS::MotorView $pos.bh \
            -promptText "Beam Height: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::$gMotorBeamHeight \
            -positionWidth 8 \
            -decimalPlaces 2
        } {
        }

        itk_component add Phi {
            DCS::MotorView $pos.phi \
            -promptText "Phi: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::$gMotorPhi \
            -positionWidth 8 \
            -decimalPlaces 2
        } {
        }

        itk_component add Omega {
            DCS::MotorView $pos.o \
            -promptText "Omega: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::$gMotorOmega \
            -positionWidth 8 \
            -decimalPlaces 2
        } {
        }

        itk_component add distance {
            DCS::MotorView $pos.dist \
            -promptText "Distance: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::$gMotorDistance \
            -positionWidth 8 \
            -decimalPlaces 2
        } {
        }

        itk_component add beam_stop {
            DCS::MotorView $pos.bs \
            -promptText "Beam Stop: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::$gMotorBeamStop \
            -positionWidth 8 \
            -decimalPlaces 2
        } {
        }

        itk_component add attenuation {
            DCS::MotorView $pos.att \
            -promptText "Attenuation: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::attenuation \
            -positionWidth 8 \
            -decimalPlaces 2
        } {
        }

        itk_component add flux {
            DCS::MotorView $pos.flux \
            -promptText "Flux: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::flux \
            -positionWidth 8 \
            -decimalPlaces 2
        } {
        }

        itk_component add energy {
            DCS::MotorView $pos.energy \
            -promptText "Energy: " \
            -promptWidth $WIDTH_PROMPT \
            -device ::device::energy \
            -positionWidth 8 \
            -decimalPlaces 2
        } {
        }

        pack $itk_component(Phi)
        pack $itk_component(Omega)
        pack $itk_component(distance)
        pack $itk_component(beam_stop)
        pack $itk_component(beam_width)
        pack $itk_component(beam_height)
        pack $itk_component(energy)
        pack $itk_component(attenuation)
        pack $itk_component(flux)

      
        itk_component add optimize {
            OptimizeButton $previewSite.optimize \
             -text "Optimize Beam" \
             -width 10
        } {
        }
        itk_component add preview {
            DCS::RunSequenceView $previewSite.rp \
            -forQueue 1 \
            -runViewWidget $itk_component(runView) 
        } {
        }
        set deviceFactory [DCS::DeviceFactory::getObject]
        grid $itk_component(positionFrame)  -row 0  -column 0 -sticky ew
        if { [$deviceFactory motorExists optimized_energy]} {
            grid $itk_component(optimize)   -row 1 -column 0 -sticky n
        }
        grid $itk_component(preview)        -row 2 -column 0 -sticky news
        grid rowconfig $previewSite 2 -weight 10

        itk_component add not_reorientable {
            label $childsite.not \
            -text "Sample Not ReOrientable" \
            -foreground red
        } {
        }

        itk_component add add_run_frame {
            frame $childsite.add_run
        } {
        }

        set addRunSite $itk_component(add_run_frame)

        label $addRunSite.l1 \
        -text "Add Run"

        itk_component add webice {
            DCS::Button $addRunSite.webice \
            -text "Open WebIce to Create New Run" \
            -width 38 -pady 0  \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -command "$this openWebIce" 
        } {
        }

        itk_component add manual {
            DCS::Button $addRunSite.manual \
            -text "Manually Create New Run" \
            -width 38 -pady 0  \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -command "$this addRunManually" 
        } {
        }

        itk_component add copy_frame {
            frame $addRunSite.copyF
        } {
        }
        itk_component add copy {
            DCS::Button $addRunSite.copyF.copy \
            -text "Copy" \
            -width 8 -pady 0  \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -command "$this copyRun" 
        } {
        }
        itk_component add runIndex {
            DCS::MenuEntry $addRunSite.copyF.index \
            -entryType string \
            -showEntry 0
        } {
        }
        pack $itk_component(copy) -side left
        pack $itk_component(runIndex)

        pack $addRunSite.l1 -side top
        pack $itk_component(webice)
        pack $itk_component(manual)
        pack $itk_component(copy)

        eval itk_initialize $args   

        #allow observers to know what the embedded runViewer is looking at.
        exportSubComponent runDefinition ::$itk_component(runView) 

        announceExist

   }

    destructor {
    }
}

body DCS::RunOverViewForQueue::updateDisplayMode { } {
    if {$itk_option(-displayMode) == $m_lastDisplayMode} {
        return
    }

    set m_lastDisplayMode $itk_option(-displayMode)

    set slaves [grid slaves $itk_interior]
    if {$slaves != ""} {
        eval grid forget $slaves
    }

    grid columnconfig $itk_interior 0 -weight 10
    grid rowconfig    $itk_interior 0 -weight 10
    switch -exact -- $m_lastDisplayMode {
        ADD_RUN {
            grid $itk_component(positionView)  -row 0 -column 0 -sticky news
            grid $itk_component(add_run_frame) -row 0 -column 1 -sticky nw
        }
        FULL {
            grid $itk_component(positionView)  -row 0 -column 0 -sticky news
            grid $itk_component(runView)       -row 0 -column 1 -sticky news
            grid $itk_component(preview_frame) -row 0 -column 2 -sticky news
        }
        NOT_REORIENTABLE -
        default {
            grid $itk_component(not_reorientable) -row 0 -column 0 -sticky news
        }
    }
}
class DCS::PositionListViewForQueue {
    inherit ::itk::Widget ::DCS::Component
    
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -controlSystem controlsytem ControlSystem "::dcss"
    itk_option define -runDefinition runDefinition RunDefinition \
    ::device::virtualRunForQueue

    itk_option define -positionName positionName PositionName "Not Available" {
        $itk_component(detail_frame) configure \
        -labeltext $itk_option(-positionName)
    }

    public method handleCurrentRowChange

    constructor { args } {
        global gMotorBeamWidth
        global gMotorBeamHeight

        itk_component add score_list_frame {
            iwidgets::labeledframe $itk_interior.scoreF \
            -labeltext "Existing Checked Positions"
        } {
        }
        set scoreSite [$itk_component(score_list_frame) childsite]

        itk_component add detail_frame {
            iwidgets::labeledframe $itk_interior.detailF \
            -labeltext "Default Position"
        } {
        }
        set detailSite [$itk_component(detail_frame) childsite]

        itk_component add score_view {
            DCS::ScoreViewForQueue $scoreSite.score
        } {
            keep -positionFromRun
            keep -positionLabels
        }
        pack $itk_component(score_view) -expand 1 -fill both

        itk_component add beamsize_frame {
            iwidgets::labeledframe $detailSite.bsF \
            -labeltext "Beam Size"
        } {
        }
        set sizeSite [$itk_component(beamsize_frame) childsite]

        itk_component add cross {
            label $sizeSite.cross \
            -text "x" \
            -font "helvetica -14 bold"
        } {
        }
        itk_component add width {
            DCS::Entry $sizeSite.width \
            -shadowReference 0 \
            -reference "::device::$gMotorBeamWidth scaledPosition" \
            -showPrompt 0 \
            -state labeled \
            -entryWidth 10 \
            -units "mm" \
            -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1
        } {}

        itk_component add height {
            DCS::Entry $sizeSite.height \
            -shadowReference 0 \
            -reference "::device::$gMotorBeamHeight scaledPosition" \
            -showPrompt 0 \
            -state labeled \
            -entryWidth 10 \
            -units "mm" \
            -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1
        } {}

        pack $itk_component(width) -side left
        pack $itk_component(cross) -side left -anchor s
        pack $itk_component(height) -side left
    

        itk_component add snapshot_view {
            DCS::SnapshotViewForQueue $detailSite.snap
        } {
            keep -snapshot
        }

        grid $itk_component(beamsize_frame) -row 0 -column 0 -sticky news
        grid $itk_component(snapshot_view)  -row 1 -column 0 -sticky news
        grid columnconfig $detailSite 0 -weight 10
        grid rowconfig    $detailSite 1 -weight 10

        
        grid $itk_component(score_list_frame) -row 0 -column 0 -sticky news
        grid $itk_component(detail_frame)     -row 1 -column 0 -sticky news
        grid columnconfig $itk_interior 0 -weight 10
        grid rowconfig    $itk_interior 1 -weight 10

        eval itk_initialize $args

        announceExist

        $itk_component(score_view) register $this currentRow \
        handleCurrentRowChange
    }

    destructor {
    }
}
body DCS::PositionListViewForQueue::handleCurrentRowChange { \
- targetReady_ - row_ - \
} {
    if {!$targetReady_} return
    puts "handle row change: $row_"
    puts "runDef: $itk_option(-runDefinition)"

    if {$itk_option(-runDefinition) == ""} return

    if {![string is integer -strict $row_] || $row_ < 0} {
        return
    }

    foreach {sil_id row_id unique_id} [$itk_option(-runDefinition) getID] break
    set user [$itk_option(-controlSystem) getUser]
    set SID [$itk_option(-controlSystem) getSessionId]

    set data [getPositionDefinitionForQueue $user $SID \
    $sil_id $row_id $unique_id $row_]

    puts "data: $data"

    ## skip labels states and scores for now
    set position [lindex $data 3]

    set snapshots [::DCS::PositionFieldForQueue::getList position \
    file_box_0 file_box_1]

    set name [::DCS::PositionFieldForQueue::getField position position_name]

    configure \
    -snapshot $snapshots \
    -positionName $name

    foreach {size_x size_y} [::DCS::PositionFieldForQueue::getList position \
    beam_width beam_height] break

    $itk_component(width) setValue $size_x 1
    $itk_component(height) setValue $size_y 1
}

### partially copied from BeamlineVideo
class DCS::SampleVideoAndLightControl {
    inherit ::itk::Widget

    private variable m_sample_id

    ### to keep the light control just under the sample video
    public method handleResize { winID width height } {
        if {$winID != $m_sample_id} return

        set req_v_w [winfo reqwidth $itk_component(sampleWidget)]
        set req_v_h [winfo reqheight $itk_component(sampleWidget)]
        set req_l_h [winfo reqheight $itk_component(light_control)]
        puts "v resize: $width $height req : $req_v_w $req_v_h"

        ############## decide the height of sampleWidget #########
        set height_available [expr $height - $req_l_h]
        if {$height_available < 0} {
            set height_available 0
        }
        set h_from_h $height_available
        puts "from height: $h_from_h"

        set h_from_w [expr $width * $req_v_h / $req_v_w]
        puts "from width $h_from_w"

        ## 240 is from observation to show the video snapshot button
        if {$h_from_h > $h_from_w} {
            if {$h_from_w < 240 && $h_from_h > 240} {
                set h_from_h 240
            } else {
                set h_from_h $h_from_w
            }
        }

        if {$h_from_h > 0} {
            place $itk_component(sampleWidget) \
            -x 0 \
            -y 0 \
            -width $width \
            -height $h_from_h
        }

        puts "place light control at 0, $h_from_h"
        place $itk_component(light_control) \
        -x 0 \
        -y $h_from_h \
        -width $width
    }

    public method addChildVisibilityControl { args } {
        eval $itk_component(sampleWidget) addChildVisibilityControl $args
    }

    constructor { args } {
        set sampleSite $itk_interior
        
        itk_component add sampleWidget {
            SamplePositioningWidget $sampleSite.s \
            [::config getImageUrl 1] \
            sample_camera_constant camera_zoom centerLoop moveSample
        } {
            keep -videoParameters
            keep -videoEnabled
            keep -beamWidthWidget
            keep -beamHeightWidget
        }

        itk_component add light_control {
            LightControlWidget $sampleSite.light
        } { 
        }

        pack $itk_component(sampleWidget) -expand 1 -fill both

        set m_sample_id $sampleSite
        bind $m_sample_id <Configure> "$this handleResize %W %w %h"

        eval itk_initialize $args
    }

}
