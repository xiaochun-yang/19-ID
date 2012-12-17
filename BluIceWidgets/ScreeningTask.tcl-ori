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

package provide BLUICEScreeningTask 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSDeviceFactory
package require BLUICESequenceActions

class ScreeningTaskWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -crystalListWidget crystalListWidget CrystalListWidget "" {
        if {$m_lastCrystalListWidget != ""} {
            $m_lastCrystalListWidget unregister $this -crystalNameList handleCrystalNameListEvent
        }
        if {$itk_option(-crystalListWidget) != ""} {
            $itk_option(-crystalListWidget) register $this -crystalNameList handleCrystalNameListEvent
        }
        set m_lastCrystalListWidget $itk_option(-crystalListWidget)
    }

    #methods
    public method refresh { }
    public method handleCrystalSelectionEvent
    public method handleActionEvent
    public method handleCrystalNameListEvent

    private method checkCrystal { c_index init_act_index { current 0 } }
    private method getCrystalID { c_index } {
        if {$c_index < 0} {
            return invalid
        }

        if {$m_crystalNameList == ""} {
            return $c_index
        }

        set result [lindex $m_crystalNameList $c_index]
        if {$result == ""} {
            return $c_index
        }
        return $result
    }

	public variable m_font  "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"
    protected variable m_deviceFactory
    protected variable m_newCurrentCrystal -1
    protected variable m_newNextCrystal -1
    protected variable m_currentCrystal -1
    protected variable m_nextCrystal -1
    protected variable m_lastCrystal -1
    protected variable m_crystalSelectionList {}
    protected variable m_currentAction -1
    protected variable m_running 0
    protected variable m_nextAction -1
    protected variable m_screeningActionList {}


    protected variable m_numActions 1

    protected variable m_ActionNameList [list \
    "Mount Next Crystal " \
    "Loop Alignment     " \
    "Stop               " \
    "JPEG Snapshot      " \
    "Collect Image      " \
    "Rotate             " \
    "JPEG Snapshot      " \
    "Collect Image      " \
    "Stop               " \
    "Rotate             " \
    "JPEG Snapshot      " \
    "Collect Image      " \
    "Excitation Scan    " \
    "ReOrient Sample    " \
    "Run Queue Task     " \
    "Stop               "]

    protected variable m_EndName "Dismount"

    #changed by handleCrystalListEvent if hooked.
    protected variable m_crystalNameList ""

    private variable m_lastCrystalListWidget ""

    #grey out after stop: changed by checkCrystal
    private variable m_afterStop 0
    private variable m_stopIndexList ""

    #contructor/destructor
    constructor { args  } {
        ## generate m_ActionNameList
        set m_ActionNameList ""
        set m_stopIndexList ""
        set i 0
        foreach item $ScreeningActionList::S_ACTION_STRUCTURE {
            foreach {a_index a_name} $item break
            lappend m_ActionNameList $a_name
            if {[string equal -length 4 $a_name "Stop"]} {
                lappend m_stopIndexList $i
            }
            incr i
        }

        puts "stopIndexList:  $m_stopIndexList"

        set m_numActions [llength $m_ActionNameList]

        itk_component add textWidget {
            ::iwidgets::scrolledtext $itk_interior.text\
            -wrap none \
            -textfont $m_font \
            -labeltext "Screening Tasks" \
            -labelpos nw \
            -disabledforeground black -hscrollmode none
        } {
            keep -width -height
        }

        pack $itk_component(textWidget) -expand 1 -fill both
        pack $itk_interior -expand 1 -fill both

        eval itk_initialize $args

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set objCrystalSelectionList [$m_deviceFactory createString \
        crystalSelectionList]
        set objScreeningActionList [$m_deviceFactory createString \
        screeningActionList]

        $objCrystalSelectionList register $this contents handleCrystalSelectionEvent
        $objScreeningActionList register $this contents handleActionEvent

        bind $itk_component(textWidget) <Button-1> "$this refresh"
        #puts "endof constructor of task"
    }
    destructor {
        set objCrystalSelectionList [$m_deviceFactory createString \
        crystalSelectionList]
        set objScreeningActionList [$m_deviceFactory createString \
        screeningActionList]

        $objCrystalSelectionList unregister $this contents handleCrystalSelectionEvent
        $objScreeningActionList unregister $this contents handleActionEvent
        if {$m_lastCrystalListWidget != ""} {
            #### that widget may already been deleted.
            catch {
                $m_lastCrystalListWidget unregister $this crystalNameList handleCrystalNameListEvent
            }
        }
    }
}

body ScreeningTaskWidget::handleCrystalSelectionEvent { stringName_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return
    if {[llength $contents_] < 3} return

    set m_newCurrentCrystal [lindex $contents_ 0]
    set m_newNextCrystal [lindex $contents_ 1]
    set m_crystalSelectionList [lindex $contents_ 2]
    refresh
}
body ScreeningTaskWidget::handleActionEvent { stringName_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    set m_currentCrystal $m_newCurrentCrystal
    set m_nextCrystal $m_newNextCrystal

    if {[llength $contents_] < 4} return

    set m_running [lindex $contents_ 0]
    set m_currentAction [lindex $contents_ 1]
    set m_nextAction [lindex $contents_ 2]
    set m_screeningActionList [lindex $contents_ 3]

    #enforce currentAction
    if {!$m_running} {
        set m_currentAction -1
    }
    if {$m_currentAction >= $m_numActions} {
        set m_currentAction -1
    }

    #enforce nextAction
    if {$m_nextAction >= $m_numActions} {
        set m_nextAction -1
    }
    if {$m_nextAction >= 0 && \
    [lindex $m_screeningActionList $m_nextAction] != "1"} {
        set m_nextAction -1
    }

    refresh
}
body ScreeningTaskWidget::handleCrystalNameListEvent { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return
    set m_crystalNameList $contents_
    refresh
}

######################
#######################
# current crystal
#       current action (if running)
#       next action
#
# next crystal
#       current action mounting (current task)
#       loop action selections
#
# loop all other selected crystals
#       loop action selections
#
# dismount the last crystal
#
body ScreeningTaskWidget::refresh { } {
    if {!$m_running || $m_currentAction != 0} {
        set m_currentCrystal $m_newCurrentCrystal
        set m_nextCrystal $m_newNextCrystal
    }
    set m_afterStop 0

    set m_lastCrystal -1

    $itk_component(textWidget) configure -state normal
    $itk_component(textWidget) clear

    if {[llength $m_screeningActionList] < $m_numActions} {
        $itk_component(textWidget) configure -state disabled
        return
    }

    ########### SPECIAL CASE: dismount button pressed #######
    if {$m_running && $m_currentAction < 0} {
        set line "$m_EndName"
        if {$m_currentCrystal >= 0} {
            append line " [getCrystalID $m_currentCrystal]"
        }
        append line "\n"
        $itk_component(textWidget) insert end $line current
        $itk_component(textWidget) tag configure current \
        -background \#c04080
        return
    }

    #in event handler, we already made sure
    #if {!$m_running} { set m_currentAction -1 }
    ######### current crystal ################
    if {$m_currentCrystal >= 0} {
        if {$m_currentAction > 0} {
            set line [getCrystalID $m_currentCrystal]
            append line "    [lindex $m_ActionNameList $m_currentAction]\n"
            $itk_component(textWidget) insert end $line current
            $itk_component(textWidget) tag configure current \
            -background \#c04080
            set m_lastCrystal $m_currentCrystal
        }
        if {$m_currentAction != 0 && $m_nextAction > 0} {
            if {![checkCrystal $m_currentCrystal $m_nextAction 1]} {
                $itk_component(textWidget) configure -state disabled
                return
            }
        }
    }

    ################ next crystal ###############
    if {$m_nextCrystal >= 0} {
        if {$m_currentAction == 0} {
            set line [getCrystalID $m_nextCrystal]
            append line "    [lindex $m_ActionNameList $m_currentAction]\n"
            $itk_component(textWidget) insert end $line current
            $itk_component(textWidget) tag configure current \
            -background \#c04080
            set start_act 1
        } else {
            set start_act 0
        }

        if {$m_nextAction >= 0} {
            if {![checkCrystal $m_nextCrystal $start_act]} {
                $itk_component(textWidget) configure -state disabled
                return
            }
        }
    }

    if {$m_nextAction < 0} {
        return
    }
    ################## loop other crystals ###########
    set max_cry [llength $m_crystalSelectionList]
    for {set p_cry [expr 1 + $m_nextCrystal]} {$p_cry < $max_cry} {incr p_cry} {
        if {![checkCrystal $p_cry 0]} {
            $itk_component(textWidget) configure -state disabled
            return
        }
    }
    for {set p_cry 0} {$p_cry < $m_nextCrystal} {incr p_cry} {
        if {![checkCrystal $p_cry 0]} {
            $itk_component(textWidget) configure -state disabled
            return
        }
    }

    ################### end ##################
    set end_is_currentTask 0
    if {$m_lastCrystal == -1 && $m_currentCrystal >= 0} {
        set m_lastCrystal $m_currentCrystal
        if {$m_running && $m_currentAction == 0} {
            set end_is_currentTask 1
        }
    }

    if {$m_lastCrystal != -1} {
        set line "[getCrystalID $m_lastCrystal]    $m_EndName\n"
        if {$end_is_currentTask} {
            $itk_component(textWidget) insert end $line current
            $itk_component(textWidget) tag configure current \
            -background \#c04080
        } elseif {$m_afterStop} {
            $itk_component(textWidget) insert end $line after_stop
            $itk_component(textWidget) tag configure after_stop \
            -foreground grey50
        } else {
            $itk_component(textWidget) insert end $line
        }
    }
}
body ScreeningTaskWidget::checkCrystal { c_index init_act_index { current 0 } } {
    if {$current || ($c_index != $m_currentCrystal && \
    [lindex $m_crystalSelectionList $c_index] == "1")} {
        for {set p_act $init_act_index} {$p_act < $m_numActions} {incr p_act} {
            if {[lindex $m_screeningActionList $p_act]} {
                set line "[getCrystalID $c_index]    [lindex $m_ActionNameList $p_act] \n"
                if {$m_afterStop} {
                    $itk_component(textWidget) insert end $line after_stop
                    $itk_component(textWidget) tag configure after_stop \
                    -foreground grey50
                } else {
                    $itk_component(textWidget) insert end $line
                }

                set m_lastCrystal $c_index

                if {[lsearch -exact $m_stopIndexList $p_act] >= 0} {
                    set m_afterStop 1
                }
            }
        }
    }
    return 1
}
