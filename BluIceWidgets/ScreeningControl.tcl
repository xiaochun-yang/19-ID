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

#
# SequenceControl.tcl
#
# part of Screening UI
#

package require Itcl


package provide BLUICEScreeningControl 1.0
package require DCSDeviceFactory
package require DCSLabelButton
package require DCSLabel

class ScreeningControlBase {
    protected variable red #c04080
    protected variable green #00a040 
    protected variable yellow #d0d000

    protected variable m_sequenceOperation
    protected variable m_opSeqManual
    protected variable m_sequenceSetConfigOperation 

    public method handleSyncClick {} {}
    public method handleModeClick {} {}
    public method handleStartClick
    public method handleStopClick {} {}
    public method handleDismountClick {} {}
    public method handleResetClick {} {}
    public method handleSynced

    #to bell when screening stops
    public method handleStringAction
    #track mode
    protected method sendStartToServer

    protected variable m_deviceFactory
    protected variable m_logger
    protected variable m_previousState 0

    protected variable m_actionList ""
    protected variable m_crystalStatus ""
    protected variable m_screeningParameters ""

    constructor { args } {
 
        set m_deviceFactory [DCS::DeviceFactory::getObject]         
        set m_logger [DCS::Logger::getObject]         
        set m_sequenceOperation [$m_deviceFactory getObjectName sequence]
        set m_opSeqManual [$m_deviceFactory getObjectName sequenceManual]
        set m_sequenceSetConfigOperation [$m_deviceFactory getObjectName sequenceSetConfig]

        set m_crystalStatus [$m_deviceFactory createString crystalStatus]
        $m_crystalStatus createAttributeFromField current 0
        $m_crystalStatus createAttributeFromField next 1
        $m_crystalStatus createAttributeFromField mode 2
        $m_crystalStatus createAttributeFromField dismount 3
        $m_crystalStatus createAttributeFromField subdir 4
        $m_crystalStatus createAttributeFromField synced 5
        $m_crystalStatus createAttributeFromField reoriented 6

        set m_actionList [$m_deviceFactory createString screeningActionList]
        $m_actionList createAttributeFromField screeningActive 0
        ::mediator register $this $m_actionList contents handleStringAction

        set m_crystalStatus [$m_deviceFactory createString crystalStatus]
        $m_crystalStatus createAttributeFromField mode 2

        set m_screeningParameters \
        [$m_deviceFactory createString screeningParameters]

        return
    }

    destructor {
        ::mediator unregister $this $m_actionList contents
        ::mediator announceDestruction $this
    }
}



::itcl::body ScreeningControlBase::handleStartClick {} {
    #### dcss will take care of directory check with impersonal server
    sendStartToServer
}

::itcl::body ScreeningControlBase::sendStartToServer {} {
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[::dcss getSessionId]
    }

    # puts "xyangx m_sequenceOperation=$m_sequenceOperation gEncryptSID=$gEncryptSID  SID=$SID"
    $m_sequenceOperation startOperation start $SID
}

# ===================================================

::itcl::body ScreeningControlBase::handleStopClick {} {
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[::dcss getSessionId]
    }
    $m_sequenceSetConfigOperation startOperation setConfig stop 0 $SID
}

# ===================================================

::itcl::body ScreeningControlBase::handleDismountClick {} {
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[::dcss getSessionId]
    }
    $m_opSeqManual startOperation mount nN0 $SID
}

# ===================================================

::itcl::body ScreeningControlBase::handleModeClick {} {
    set current_mode [$m_crystalStatus getFieldByIndex 2]

    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[::dcss getSessionId]
    }
    if {$current_mode == "robot"} {
        $m_sequenceSetConfigOperation startOperation setConfig useRobot 0 $SID
    } else {
        $m_sequenceSetConfigOperation startOperation setConfig useRobot 1 $SID
    }
}

# ===================================================

::itcl::body ScreeningControlBase::handleSyncClick {} {
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[::dcss getSessionId]
    }
    $m_sequenceSetConfigOperation startOperation syncWithRobot 1 $SID
}

# ===================================================

::itcl::body ScreeningControlBase::handleResetClick {} {
    #trc_msg "handleResetClick"
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[::dcss getSessionId]
    }
    $m_sequenceSetConfigOperation startOperation reset $SID
}

::itcl::body ScreeningControlBase::handleStringAction { stringName_ targetReady_ alias_ contents_ - } {
    if { ! $targetReady_} return

    set value [lindex $contents_ 0]

    if {$m_previousState ==""} {
        set m_previousState 0
    }

    if {$m_previousState && !$value} {
        bell
    }
    set m_previousState $value
}


::itcl::class ScreeningControl {
    inherit ::itk::Widget ScreeningControlBase

    constructor { args } {

        #puts "constructor of screening control"

        itk_component add start {
            DCS::Button $itk_interior.buttonStart \
            -text "Start" \
            -width 8 \
            -command "$this handleStartClick"
        } {
            keep -font
        }
            
        itk_component add stop {
            DCS::Button $itk_interior.stop \
            -systemIdleOnly 0 \
            -text "Stop" \
            -width 8 \
            -command "$this handleStopClick"
        } {
            keep -font
        }

        itk_component add dismount {
            DCS::Button $itk_interior.buttonDismount \
            -text "Dismount"  -width 8 \
            -command "$this handleDismountClick"
        } {
            keep -font
        }

        itk_component add reset {
            DCS::Button $itk_interior.buttonReset \
            -systemIdleOnly 0 \
            -text "Reset Parameters" \
            -width 16 \
            -command "$this handleResetClick"
        } {
            keep -font
        }

        itk_component add abort {
            DCS::Button $itk_interior.buttonAbort \
            -text "Abort" \
            -background \#ffaaaa \
            -activebackground \#ffaaaa \
            -width 8 \
            -activeClientOnly 0 \
            -systemIdleOnly 0
        } {
            keep -font
        }

        eval itk_initialize $args

        $itk_component(start) addInput \
        "$m_actionList screeningActive 0 {Screening in progress.}"
        $itk_component(start) addInput \
        "$m_sequenceOperation permission GRANTED {PERMISSION}"
        #$itk_component(start) addInput \
        #"$m_screeningParameters dirOK 1 {set directory first}"
        $itk_component(stop) addInput "$m_actionList screeningActive 1 {Screening is not in progress.}"
        $itk_component(dismount) addInput "$m_crystalStatus dismount 1 {No sample mounted.}"
        $itk_component(dismount) addInput "$m_actionList screeningActive 0 {Screening in progress.}"
        $itk_component(reset) addInput "$m_actionList screeningActive 0 {Screening in progress.}"
        $itk_component(abort) configure -command "::dcss abort"


        ::mediator announceExistence $this

        pack $itk_component(start) -side left -pady 0
        pack $itk_component(stop) -side left -pady 0
        pack $itk_component(dismount) -side left -pady 0
        pack $itk_component(reset) -side left -pady 0
        #pack $itk_component(abort) -side left -pady 0

    }

}

::itcl::class ScreeningStatus {
    inherit ::itk::Widget ScreeningControlBase

    constructor { args } {

        #string messages
        itk_component add current {
            DCS::Label $itk_interior.current \
                 -promptText "current: " -relief sunken \
                 -promptRelief flat \
                 -promptWidth 8 \
                 -width 8
        } {
            keep -font
        }
        $itk_component(current).r.l configure -background $red 

        #string messages
        itk_component add next {
            DCS::Label $itk_interior.next \
                 -promptWidth 8 \
                 -promptText "Next: " \
                 -relief sunken -promptRelief flat \
                 -width 8
        } {
            keep -font
        }
        $itk_component(next).r.l configure -background $green 

        #string messages
        itk_component add mode {
         DCS::LabelButton $itk_interior.mode \
            -systemIdleOnly 0 \
            -command "$this handleModeClick" \
            -promptWidth 8 \
            -promptText "Mode: " \
            -relief sunken -promptRelief flat \
            -width 8
        } {
            keep -font
        }
        $itk_component(mode).r.l configure -background $green 

        itk_component add synced {
            DCS::LabelButton $itk_interior.synced \
            -command "$this handleSyncClick" \
            -systemIdleOnly 0 \
            -promptWidth 8 \
            -promptText "Synced: " \
            -relief sunken -promptRelief flat \
            -width 8
        } {
            keep -font
        }
        $itk_component(synced).r.l configure -background $green 
        
        itk_component add robot_status {
            frame $itk_interior.rstatus
        } {
        }
        itk_component add rs_prompt {
            label $itk_component(robot_status).prompt -text "Robot: " -width 8
        } {
        }
        itk_component add rs_contents {
            RobotStatusLabel $itk_component(robot_status).contents \
            -width 8 \
            -relief sunken \
            -normalBackground $green
        } {
        }

        itk_component add dose {
            DCS::DoseControlView $itk_interior.dose
        } {
        }

        eval itk_initialize $args

        $itk_component(current) configure -component $m_crystalStatus -attribute current
        $itk_component(next) configure -component $m_crystalStatus -attribute next
        $itk_component(mode) configure -component $m_crystalStatus -attribute mode 
        $itk_component(synced) configure -component $m_crystalStatus -attribute synced

        set newControlSystem ::dcss 
        $itk_component(mode) addInput \
        "$newControlSystem staff 1 {Staff only.}"
        $itk_component(mode) addInput "$m_actionList screeningActive 0 {Screening in progress.}"

        $itk_component(synced) addInput \
        "$newControlSystem  staff 1 {Staff only.}"
        $itk_component(synced) addInput "$m_actionList screeningActive 0 {Screening in progress.}"
        $itk_component(synced) addInput "$m_crystalStatus synced no {Robot and screening interface agree on currently mounted sample.}"

        ::mediator announceExistence $this

        pack $itk_component(current) -side top  -anchor w
        pack $itk_component(next) -side top  -anchor w
        pack $itk_component(mode) -side top -anchor w
        pack $itk_component(synced) -side top -anchor w

        pack $itk_component(robot_status) -side top -anchor w
        pack $itk_component(rs_prompt) -side left
        pack $itk_component(rs_contents) -side left
        #pack $itk_component(dose) -side top -anchor w
    }

}







