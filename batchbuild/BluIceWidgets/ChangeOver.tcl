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

package provide BLUICEChangeOver 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

package require DCSProtocol
package require DCSOperationManager
package require DCSLabel
package require DCSDeviceFactory

class ChangeOverWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handleAll { } {
        $m_opChangeOver startOperation all
    }
    public method handleClearCassetteOwner { } {
        $m_opChangeOver startOperation clear_cassette_owner
    }
    public method handleRequestGapOwnership { } {
        $m_opChangeOver startOperation get_gap
    }
    public method handleNewUserLog { } {
        $m_opChangeOver startOperation clear_user_log
    }
    public method handleNewUserChat { } {
        $m_opChangeOver startOperation clear_user_chat
    }
    public method handleNewUserNotify { } {
        $m_opChangeOver startOperation clear_user_notify
    }
    public method handleClearRuns { } {
        $m_opChangeOver startOperation clear_run
    }

    public method handleClearMounted { } {
        $m_opChangeOver startOperation clear_mounted
    }

    public method handleResetAllPorts { } {
        $m_opChangeOver startOperation reset_all_port
    }

    public method handleClearSpreadsheet { } {
        $m_opChangeOver startOperation clear_spreadsheet
    }

    public method handleDefaultRobot { } {
        $m_opChangeOver startOperation reset_robot_attribute
    }
    public method handleDefaultScreen { } {
        $m_opChangeOver startOperation reset_screening
    }

    public method handleDefaultOptimization { } {
        $m_opChangeOver startOperation reset_optimization
    }

    public method handleClearSortingList { } {
        $m_opChangeOver startOperation clear_sort
    }

    private variable m_deviceFactory

    private variable m_opChangeOver ""
    private variable m_opCheckGapOwnership ""

    #contructor/destructor
    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_opChangeOver [$m_deviceFactory createOperation changeOver]
        if {[$m_deviceFactory deviceExists ::device::checkGapOwnership]} {
            set m_opCheckGapOwnership [$m_deviceFactory createOperation \
            checkGapOwnership]
        }

        itk_component add fr {
            iwidgets::labeledframe $itk_interior.lf \
            -labeltext "User Change Over"
        } {
        }
        set controlSite [$itk_component(fr) childsite]

        itk_component add all {
            DCS::Button $controlSite.all \
            -text "Do all of following" \
            -command "$this handleAll" \
            -activebackground yellow 
        } {
        }
        itk_component add clear_runs {
            DCS::Button $controlSite.cr \
            -text "Delete All Run Definitions Between User Groups" \
            -command "$this handleClearRuns" \
            -activebackground yellow 
        } {
        }

        itk_component add clear_mounted {
            DCS::Button $controlSite.cm \
            -text "Clear Robot Mounted" \
            -command "$this handleClearMounted" \
            -activebackground yellow 
        } {
        }

        itk_component add reset_all_ports {
            DCS::Button $controlSite.rap \
            -text "Reset All Ports" \
            -command "$this handleResetAllPorts" \
            -activebackground yellow 
        } {
        }

        itk_component add clear_spreadsheet {
            DCS::Button $controlSite.cs \
            -text "Clear spreadsheet" \
            -command "$this handleClearSpreadsheet" \
            -activebackground yellow 
        } {
        }

        itk_component add robot_default {
            DCS::Button $controlSite.rd \
            -text "Robot Default Settings" \
            -command "$this handleDefaultRobot" \
            -activebackground yellow 
        } {
        }

        itk_component add user_log {
            DCS::Button $controlSite.userLog \
            -text "Clear User Log" \
            -command "$this handleNewUserLog" \
            -activebackground yellow 
        } {
        }

        itk_component add user_chat {
            DCS::Button $controlSite.userChat \
            -text "Clear User Chat" \
            -command "$this handleNewUserChat" \
            -activebackground yellow 
        } {
        }

        itk_component add user_notify {
            DCS::Button $controlSite.userNotify \
            -text "Clear User Notify" \
            -command "$this handleNewUserNotify" \
            -activebackground yellow 
        } {
        }

        itk_component add screen_default {
            DCS::Button $controlSite.sd \
            -text "Reset Screening Parameters" \
            -command "$this handleDefaultScreen" \
            -activebackground yellow 
        } {
        }

        itk_component add optimization_default {
            DCS::Button $controlSite.od \
            -text "Reset Optimization Parameters" \
            -command "$this handleDefaultOptimization" \
            -activebackground yellow 
        } {
        }

        itk_component add gap_owner {
            DCS::Button $controlSite.gap \
            -text "Get Gap Ownership" \
            -command "$this handleRequestGapOwnership" \
            -activebackground yellow 
        } {
        }

        itk_component add cas_owner {
            DCS::Button $controlSite.casowner \
            -text "Clear Cassette Owner" \
            -command "$this handleClearCassetteOwner" \
            -activebackground yellow 
        } {
        }

        itk_component add sorting {
            DCS::Button $controlSite.sorting \
            -text "Clear Sorting List" \
            -command "$this handleClearSortingList" \
            -activebackground yellow 
        } {
        }

        pack $itk_component(all) -side top -expand 1 -fill x
        pack $itk_component(all) -side top -expand 1 -fill x
        pack $itk_component(clear_runs) -side top -expand 1 -fill x
        pack $itk_component(clear_mounted) -side top -expand 1 -fill x
        pack $itk_component(reset_all_ports) -side top -expand 1 -fill x
        pack $itk_component(clear_spreadsheet) -side top -expand 1 -fill x
        pack $itk_component(robot_default) -side top -expand 1 -fill x
        pack $itk_component(user_log) -side top -expand 1 -fill x
        pack $itk_component(user_chat) -side top -expand 1 -fill x
        pack $itk_component(user_notify) -side top -expand 1 -fill x
        pack $itk_component(screen_default) -side top -expand 1 -fill x
        pack $itk_component(optimization_default) -side top -expand 1 -fill x
        if {$m_opCheckGapOwnership != ""} {
            pack $itk_component(gap_owner) -side top -expand 1 -fill x
        }
        pack $itk_component(cas_owner) -side top -expand 1 -fill x
        pack $itk_component(sorting) -side top -expand 1 -fill x

        pack $itk_component(fr) -expand 1 -fill both
        #pack $itk_component($itk_interior) -expand 1 -fill both

        eval itk_initialize $args
    }
    destructor {
    }
}

class NotifyView {
 	inherit ::itk::Widget

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -width width Width 10

    itk_option define -valueString valueString ValueString log_mail_map

    public method handleValueChange
    public method refresh
    public method updateDisplay
    public method submit

    private variable m_deviceFactory

    private variable m_currentValueString ""
    private variable m_numItemShow 0

    private variable m_valueContents ""
    private variable m_nameList ""
    private variable m_valueList ""

    private common gCheckButtonVar

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        itk_component add control_f {
            frame $itk_interior.control_f
        } {
        }
        set control_frame $itk_component(control_f)
        itk_component add submit {
            DCS::Button $control_frame.submit \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Submit" \
            -command "$this submit"
        } {
        }
        itk_component add cancel {
            DCS::Button $control_frame.cancel \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Cancel" \
            -command "$this refresh"
        } {
        }
        pack $itk_component(submit) -side left
        pack $itk_component(cancel) -side left

        itk_component add sf {
            iwidgets::scrolledframe $itk_interior.sf \
            -vscrollmode static \
        } {
        }
        set root_frame [$itk_component(sf) childsite]
        ##########create staff list
        ::config getRange notify.staff_list staffList
        set i 0
        set m_nameList ""
        foreach staff $staffList {
            set name [lindex $staff 0]
            set address [lindex $staff 1]
            lappend m_nameList $address

            set gCheckButtonVar($this,item$i) 0
            itk_component add item$i {
                checkbutton $root_frame.item$i \
                -text $name \
                -command "$this updateDisplay" \
                -variable [list [::itcl::scope gCheckButtonVar($this,item$i)]]
            } {
            }
            itk_component add value$i {
                label $root_frame.value$i \
                -text $address
            } {
            }

            grid $itk_component(item$i) $itk_component(value$i) \
            -row $i -sticky w


            incr i
        }
        set m_numItemShow $i

        pack $itk_component(control_f) -fill x
        pack $itk_component(sf) -expand 1 -fill both
        eval itk_initialize $args
    }

    destructor {
        if {$m_currentValueString != ""} {
            ##### unregister current one
            set objValue [$m_deviceFactory createString $m_currentValueString]
		    $objValue unregister $this contents handleValueChange
        }
    }
}
configbody NotifyView::valueString {
    set newValueString $itk_option(-valueString)

    if {$m_currentValueString != $newValueString} {
        if {$m_currentValueString != ""} {
            ##### unregister current one
            set objValue [$m_deviceFactory createString $m_currentValueString]
		    $objValue unregister $this contents handleValueChange
            $itk_component(submit) deleteInput "$objValue permission"
        }
        if {$newValueString != ""} {
            ########### register new one
            set objValue [$m_deviceFactory createString $newValueString]
		    $objValue register $this contents handleValueChange
            $itk_component(submit) addInput "$objValue permission GRANTED PERMISSION"
            
        }
        ########### save ##############
        set m_currentValueString $newValueString
    }
}
body NotifyView::handleValueChange { name_ ready_ alias_ contents_ - } {
    if {!$ready_}  return

    #puts "notify view handleValueChange: $contents_"
    set contents_ [lindex [lindex $contents_ 0] 2]
    #puts "trimmed contents: $contents_"

    set contents_ [split $contents_ ,]

    if {$m_valueContents == $contents_} {
        #puts "skip"
        return
    }
    set m_valueContents $contents_

    refresh
}

body NotifyView::refresh { } {
    set i 0
    set m_valueList ""
    foreach name $m_nameList {
        if {[lsearch -exact $m_valueContents $name] >= 0} {
            set value 1
            #puts "found $i ($name)"
        } else {
            set value 0
        }
        lappend m_valueList $value
        set gCheckButtonVar($this,item$i) $value
        incr i
    }

    updateDisplay
}
body NotifyView::updateDisplay { } {
    set anyChange 0
    for {set i 0} {$i < $m_numItemShow} {incr i} {
        if {$gCheckButtonVar($this,item$i) == [lindex $m_valueList $i]} {
            $itk_component(item$i) config \
            -foreground black \
            -activeforeground black
        } else {
            set anyChange 1
            $itk_component(item$i) config \
            -foreground red \
            -activeforeground red
        }
    }
    if {$anyChange} {
        $itk_component(submit) config -state normal
    } else {
        $itk_component(submit) config -state disabled
    }
}
body NotifyView::submit { } {
    if {$m_currentValueString == ""} {
        puts "no value string defined"
        return
    }

    set newList ""
    #### generate email list
    for {set i 0} {$i < $m_numItemShow} {incr i} {
        if {$gCheckButtonVar($this,item$i)} {
            lappend newList [lindex $m_nameList $i]
        }
    }
    #puts "newlist: $newList"

    #set hardwareSevere ".*hardware.*"
    set hardwareSevere ".*"

    lappend hardwareSevere severe
    lappend hardwareSevere [join $newList ,]

    set objValue [$m_deviceFactory createString $m_currentValueString]
    set oldContents [$objValue getContents]
    set newContents [lreplace $oldContents 0 0 $hardwareSevere]
    #puts "new contents: $newContents"
    $objValue sendContentsToServer $newContents
}
class UserNotifySetupView {
 	inherit ::itk::Widget

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -width width Width 10

    public method handleStaffChange
    public method handleSetupChange
    public method handleListChange
    public method refresh
    public method updateDisplay
    public method submit
    public method test
    public method clear

    private variable m_deviceFactory

    private variable m_currentValueString ""
    private variable m_numItemShow 0
    private variable m_isStaff 0
    private variable m_numItemStaff 0
    private variable m_numItemUser 0

    private variable m_setupContents ""
    private variable m_userContents ""
    private variable m_nameList ""
    private variable m_valueList ""

    private variable m_strUserNotifySetup
    private variable m_strUserNotifyList
    private variable m_opUserNotify

    private common gCheckButtonVar

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_strUserNotifySetup \
        [$m_deviceFactory createString user_notify_setup]

        set m_strUserNotifyList \
        [$m_deviceFactory createString user_notify_list]

        set m_opUserNotify \
        [$m_deviceFactory createOperation userNotify]

        itk_component add control_f {
            frame $itk_interior.control_f
        } {
        }
        set control_frame $itk_component(control_f)
        itk_component add submit {
            DCS::Button $control_frame.submit \
            -debounceTime 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Submit" \
            -command "$this submit"
        } {
        }
        itk_component add cancel {
            DCS::Button $control_frame.cancel \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Cancel" \
            -command "$this refresh"
        } {
        }
        itk_component add clear {
            DCS::Button $control_frame.clear \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Clear All" \
            -command "$this clear"
        } {
        }
        itk_component add test {
            DCS::Button $control_frame.test \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Send Test Message" \
            -command "$this test"
        } {
        }
        pack $itk_component(submit) -side left
        pack $itk_component(cancel) -side left
        pack $itk_component(clear) -side right 
        pack $itk_component(test) -side right

	    itk_component add userList {
            iwidgets::Scrolledtext $itk_interior.userList \
            -hscrollmode none \
            -textbackground white \
            -textfont -*-courier-bold-r-*-*-12-*-*-*-*-*-*-* \
            -wrap word
        } {
        }

        ###this one does not fire
        #bind [$itk_component(userList) component text] <<Modified>> "+$this updateDisplay"

        bind $itk_component(userList) <Enter> "+$this updateDisplay"
        bind $itk_component(userList) <Leave> "+$this updateDisplay"
        bind [$itk_component(userList) component text] <KeyRelease> "+$this updateDisplay"
        bind [$itk_component(userList) component text] <ButtonRelease> "+$this updateDisplay"

        itk_component add sf {
            iwidgets::scrolledframe $itk_interior.sf \
            -hscrollmode none \
            -vscrollmode static
        } {
        }
        set root_frame [$itk_component(sf) childsite]
        set operationList ""
        set staffOperationList ""
        ::config getRange userNotify.operation_list operationList
        ::config getRange staffNotify.operation_list staffOperationList

        set m_numItemUser  [llength $operationList]
        set m_numItemStaff [llength $staffOperationList]

        ##merge these 2
        #foreach item $staffOperationList {
        #    lappend operationList $item
        #}
        set operationList [concat $operationList $staffOperationList]

        set i 0
        set m_nameList ""
        foreach op $operationList {
            set name [lindex $op 0]
            set contents [lrange $op 1 end]
            lappend m_nameList $contents

            puts "adding item$i: $name $contents"

            set gCheckButtonVar($this,item$i) 0
            itk_component add item$i {
                checkbutton $root_frame.item$i \
                -text $name \
                -command "$this updateDisplay" \
                -variable [list [::itcl::scope gCheckButtonVar($this,item$i)]]
            } {
            }

            if {$i < $m_numItemUser} {
                grid $itk_component(item$i) -row $i -sticky w
            }

            incr i
        }
        set m_numItemShow $m_numItemUser

        grid $itk_component(control_f) - -sticky news
        grid $itk_component(userList) $itk_component(sf) -sticky news

        grid columnconfigure $itk_interior 0 -weight 10
        grid columnconfigure $itk_interior 1 -weight 1

        grid rowconfigure $itk_interior 1 -weight 1

	    $m_strUserNotifySetup register $this contents handleSetupChange
	    $m_strUserNotifyList  register $this contents handleListChange
        $itk_component(submit) addInput \
        "$m_opUserNotify permission GRANTED PERMISSION"

        $itk_component(test) addInput \
        "$m_opUserNotify permission GRANTED PERMISSION"

        $itk_component(clear) addInput \
        "$m_opUserNotify permission GRANTED PERMISSION"

        eval itk_initialize $args

        $itk_option(-controlSystem) register $this staff handleStaffChange
    }

    destructor {
        $itk_option(-controlSystem) unregister $this staff handleStaffChange
	    $m_strUserNotifySetup unregister $this contents handleSetupChange
	    $m_strUserNotifyList  unregister $this contents handleListChange
    }
}
body UserNotifySetupView::handleStaffChange { - ready_ - contents_ - } {
    if {!$ready_} return

    if {$contents_ == $m_isStaff} return

    set m_isStaff $contents_

    if {$m_isStaff} {
        for {set i 0} {$i < $m_numItemStaff} {incr i} {
            set index [expr $m_numItemUser + $i]
            grid $itk_component(item$index) -row $index -sticky w
        }
        set m_numItemShow [expr $m_numItemUser + $m_numItemStaff]
        refresh
    } else {
        for {set i 0} {$i < $m_numItemStaff} {incr i} {
            set index [expr $m_numItemUser + $i]
            grid forget $itk_component(item$index)
        }
        set m_numItemShow $m_numItemUser
    }
}
body UserNotifySetupView::handleSetupChange { name_ ready_ alias_ contents_ - } {
    if {!$ready_}  return

    #puts "notify view handleSetupChange: $contents_"
    set m_setupContents $contents_
    refresh
}

body UserNotifySetupView::handleListChange { name_ ready_ alias_ contents_ - } {
    if {!$ready_}  return

    set m_userContents $contents_
    refresh
}
body UserNotifySetupView::refresh { } {
    set i 0
    set m_valueList ""
    foreach name $m_nameList {
        set value 1
        foreach op_name $name {
            if {[lsearch -exact $m_setupContents $op_name] < 0} {
                set value 0
            }
        }

        lappend m_valueList $value
        set gCheckButtonVar($this,item$i) $value
        incr i
    }

    $itk_component(userList) clear
    $itk_component(userList) insert 0.0 $m_userContents my_tag

    updateDisplay
}
body UserNotifySetupView::updateDisplay { } {
    set anyChange 0
    for {set i 0} {$i < $m_numItemShow} {incr i} {
        if {$gCheckButtonVar($this,item$i) == [lindex $m_valueList $i]} {
            $itk_component(item$i) config \
            -foreground black \
            -activeforeground black
        } else {
            set anyChange 1
            $itk_component(item$i) config \
            -foreground red \
            -activeforeground red
        }
    }

    set ourList [$itk_component(userList) get 0.0 end]
    set ourList [string trim $ourList]
    #puts "ourList {$ourList}"
    #puts "userContents: {$m_userContents}"
    if {[string compare $m_userContents $ourList]} {
        set anyChange 1
        $itk_component(userList) configure \
        -foreground red
    } else {
        $itk_component(userList) configure \
        -foreground black
    }
}
body UserNotifySetupView::submit { } {
    set newList ""
    for {set i 0} {$i < $m_numItemShow} {incr i} {
        if {$gCheckButtonVar($this,item$i)} {
            set cmd "lappend newList [lindex $m_nameList $i]"
            eval $cmd
        }
    }
    $m_opUserNotify startOperation setup [$itk_component(userList) get 0.0 end] $newList
}
body UserNotifySetupView::test { } {
    $m_opUserNotify startOperation test
}
body UserNotifySetupView::clear { } {
    $m_opUserNotify startOperation clear_all
}
