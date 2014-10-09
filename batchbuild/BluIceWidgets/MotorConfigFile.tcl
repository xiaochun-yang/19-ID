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

package provide BLUICEMotorConfigFile 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSDeviceFactory
package require DCSUtil
package require DCSConfig

class MotorConfigFileWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handleDump { }
    public method handleLoad { }
    public method handleRefresh { }
    public method handleMotorStopped { args } { }
    public method handleMotorConfiged { args } { handleRefresh }
    public method handleClick { row_num }
    public method handleSubmit { }
    public method handleCheckButton { }
    public method handleShow { }
    public method handlePrint { }

    private method parseRealMotor
    private method parsePseudoMotor
    private method parseController
    private method parseIonChamber
    private method parseShutter
    private method parseRunDefinition
    private method parseRunsDefinition
    private method parseOperation
    private method parseEncoder
    private method parseString

    private method getTrimmedLine
    private method isMotor
    private method isRealMotor

    private method createInitRows
    private method createRow

    private method getNumSelection { }

    private variable m_deviceFactory
    private variable m_motorListFromFile ""
    #m_motorListToShow is a subset of m_motorListFromFile
    #deleted or wrong type motors are removed
    private variable m_motorListToShow ""
    private variable m_settingFromFile

    private variable m_contentsFrame
    private variable m_handle

    private variable MAX_ROW 5000
    private variable FIELD_LIST
    private variable FIELD_INDEX
    private variable COLOR_NEW red
    private variable COLOR_DELETED #008000

    #rows created.  Init value will be how many rows initially created
    private variable m_numRowCreate 10

    private variable m_numRowDisplay 0

    private variable m_newMotorList ""
    private variable m_deletedMotorList ""

    private common gCheckButtonVar

    #contructor/destructor
    constructor { args  } {
        set FIELD_LIST(real_motor) [list upperLimit lowerLimit \
        scaleFactor speed acceleration backlash lowerLimitOn \
        upperLimitOn locked backlashOn reverseOn baseUnits]

        set FIELD_INDEX(real_motor,scaledPosition)  0
        set FIELD_INDEX(real_motor,upperLimit)      1
        set FIELD_INDEX(real_motor,lowerLimit)      2
        set FIELD_INDEX(real_motor,scaleFactor)     3
        set FIELD_INDEX(real_motor,speed)           4
        set FIELD_INDEX(real_motor,acceleration)    5
        set FIELD_INDEX(real_motor,backlash)        6
        set FIELD_INDEX(real_motor,lowerLimitOn)    7
        set FIELD_INDEX(real_motor,upperLimitOn)    8
        set FIELD_INDEX(real_motor,locked)          9
        set FIELD_INDEX(real_motor,backlashOn)      10
        set FIELD_INDEX(real_motor,reverseOn)       11

        set FIELD_LIST(pseudo_motor) [list upperLimit lowerLimit \
        lowerLimitOn upperLimitOn locked baseUnits]
        set FIELD_INDEX(pseudo_motor,scaledPosition)    0
        set FIELD_INDEX(pseudo_motor,upperLimit)        1
        set FIELD_INDEX(pseudo_motor,lowerLimit)        2
        set FIELD_INDEX(pseudo_motor,lowerLimitOn)      3
        set FIELD_INDEX(pseudo_motor,upperLimitOn)      4
        set FIELD_INDEX(pseudo_motor,locked)            5

        set m_deviceFactory [DCS::DeviceFactory::getObject]

        array set m_settingFromFile [list]

        itk_component add dump_frame {
            iwidgets::labeledframe $itk_interior.df \
            -labelpos nw \
            -labeltext "Better dump database before submit any changes"
        } {
        }
        set dumpSite [$itk_component(dump_frame) childsite]
        itk_component add dump {
            button $dumpSite.bt \
            -text "Dump Database into File" \
            -width 23 \
            -command "$this handleDump"
        } {
        }
        
        itk_component add dump_label {
            label $dumpSite.label \
            -text "Dumped to:"
        } {
        }
        itk_component add dump_file {
            label $dumpSite.file
        } {
        }

        itk_component add fr {
            iwidgets::labeledframe $itk_interior.lf \
            -labelpos nw \
            -labeltext "Command"
        } {
        }
        set controlSite [$itk_component(fr) childsite]

        itk_component add load {
            button $controlSite.cl \
            -text "Load Database Dump File" \
            -width 23 \
            -command "$this handleLoad"
        } {
        }

        itk_component add refresh {
            button $controlSite.rf \
            -text "Refresh" \
            -width 23 \
            -command "$this handleRefresh"
        } {
        }

        itk_component add print {
            button $controlSite.pt \
            -text "Print" \
            -width 23 \
            -command "$this handlePrint"
        } {
        }

        itk_component add submit {
            DCS::Button $controlSite.sm \
            -activebackground #d0d000 \
            -background  #d0d000 \
            -systemIdleOnly 0 \
            -activeClientOnly 1 \
            -text "Submit" \
            -width 23 \
            -command "$this handleSubmit"
        } {
        }

        set gCheckButtonVar($this,auto_refresh) 1
        set gCheckButtonVar($this,ip) 0
        set gCheckButtonVar($this,new) 0
        set gCheckButtonVar($this,deleted) 0

        itk_component add auto_refresh {
            checkbutton $controlSite.arf \
            -variable [list [::itcl::scope gCheckButtonVar($this,auto_refresh)]] \
            -text "Auto Refresh"
        } {
        }
        itk_component add include_position {
            checkbutton $controlSite.ip \
            -variable [list [::itcl::scope gCheckButtonVar($this,ip)]] \
            -text "Include Position Check" \
            -command "$this handleRefresh"
        } {
        }

        itk_component add show_new {
            checkbutton $controlSite.new \
            -variable [list [::itcl::scope gCheckButtonVar($this,new)]] \
            -text "Show new motors not in the file" \
            -foreground $COLOR_NEW \
            -command "$this handleShow"
        } {
        }

        itk_component add show_deleted {
            checkbutton $controlSite.deleted \
            -variable [list [::itcl::scope gCheckButtonVar($this,deleted)]] \
            -text "Show motors not matching current system" \
            -foreground $COLOR_DELETED \
            -command "$this handleShow"
        } {
        }

        itk_component add fileFrame {
            frame $itk_interior.ff
        } {
        }
        set fileSite $itk_component(fileFrame)

        itk_component add file_label {
            label $fileSite.f_l \
            -text "File loaded:"
        } {
        }
        itk_component add file_name {
            label $fileSite.f_n \
            -anchor w \
            -width 80
        } {
        }

        pack $itk_component(dump) -side left

        grid $itk_component(load)               -row 0 -column 0 -sticky w
        grid $itk_component(refresh)            -row 1 -column 0 -sticky w
        grid $itk_component(print)              -row 2 -column 0 -sticky w
        grid $itk_component(submit)             -row 3 -column 0 -sticky w

        grid $itk_component(auto_refresh)       -row 0 -column 2 -sticky w
        grid $itk_component(include_position)   -row 1 -column 2 -sticky w
        grid $itk_component(show_new)           -row 2 -column 2 -sticky w
        grid $itk_component(show_deleted)       -row 3 -column 2 -sticky w

        grid  columnconfigure $controlSite 0 -weight 0
        grid  columnconfigure $controlSite 1 -weight 10
        grid  columnconfigure $controlSite 2 -weight 0

        pack $itk_component(file_label) -side left
        pack $itk_component(file_name) -side left

        $itk_component(auto_refresh) select

        itk_component add contentsFrame {
            iwidgets::scrolledframe $itk_interior.ctsFrame \
            -vscrollmode static
        } {
        }
        set m_contentsFrame [$itk_component(contentsFrame) childsite]
        createInitRows

        itk_component add new {
            listbox $m_contentsFrame.newList \
            -relief flat \
            -foreground $COLOR_NEW \
            -height 0 \
            -width 0 \
            -listvar [scope m_newMotorList]
        } {
        }

        itk_component add deleted {
            listbox $m_contentsFrame.deletedList \
            -foreground $COLOR_DELETED \
            -relief flat \
            -height 0 \
            -width 0 \
            -listvar [scope m_deletedMotorList]
        } {
        }

        pack $itk_component(dump_frame) -fill x
        pack $itk_component(fr) -fill x
        pack $itk_component(fileFrame) -fill x
        pack $itk_component(contentsFrame) -expand 1 -fill both

        eval itk_initialize $args

        $itk_option(-controlSystem) register $this motorStopped handleMotorStopped
        $itk_option(-controlSystem) register $this motorConfigured handleMotorConfiged
        $itk_component(submit) configure -state disabled
        DynamicHelp::register $itk_component(submit) balloon "file not loaded"

    }
    destructor {
        $itk_option(-controlSystem) unregister $this motorStopped handleMotorStopped
        $itk_option(-controlSystem) unregister $this motorConfigured handleMotorConfiged
    }
}

body MotorConfigFileWidget::handleDump { } {
    set init_filename [::config getConfigRootName]dump[clock format [clock seconds] -format "%d%b%y%H%M%S"]
    set filename [tk_getSaveFile -initialdir /data/blctl -initialfile $init_filename]
    if {$filename == {} } return

    set dir_name [file dirname $filename]

    if {![file writable $dir_name]} {
        bell
        log_error You do not have write permission in $dir_name
        bell
        return
    }
    $itk_option(-controlSystem) sendMessage "gtos_admin dump_database $filename"

    $itk_component(dump_file) configure -text $filename
    pack $itk_component(dump_label) -side left
    pack $itk_component(dump_file) -side left
}

body MotorConfigFileWidget::handleLoad { } {
    set filename [tk_getOpenFile]

    if {$filename == {} } return

    #open file for read
    if {[catch { open $filename r } m_handle]} {
        log_error File $filename cannot be opened to read. \
        return
    }

    set m_newMotorList ""
    set m_deletedMotorList ""

    $itk_component(file_name) configure \
    -text $filename

    catch {array unset m_settingFromFile *}
    set m_motorListToShow ""

    while {! [eof $m_handle] } {
        set deviceName [getTrimmedLine]
        if {$deviceName == "" } continue

        set entryType [getTrimmedLine]
        #looking for integer for entry type
        if { ! [string is integer $entryType] } {
            continue
        }

        switch $entryType {
            1 {parseRealMotor $deviceName}
            2 {parsePseudoMotor $deviceName}
            3 {parseController $deviceName} 
            4 {parseIonChamber $deviceName}
            5 {puts "obsolete type 5"}
            6 {parseShutter $deviceName}
            7 {puts "obsolete type 7"}
            8 {parseRunDefinition $deviceName}
            9 {parseRunsDefinition $deviceName}
            10 {puts "obsolete type 10"}
            11 {parseOperation $deviceName}
            12 {parseEncoder $deviceName}
            13 {parseString $deviceName}
        }
    }
    close $m_handle

    set m_motorListToShow [lsort $m_motorListToShow]

    ###reverse check to find new motors
    set motorListFromSystem [$m_deviceFactory getMotorList]
    foreach motor $motorListFromSystem {
        if {[lsearch $m_motorListFromFile $motor] < 0} {
            lappend m_newMotorList "$motor NEW, not in the file"
        }
    }


    puts "new motors: $m_newMotorList"
    puts "deleted motor list: $m_deletedMotorList"

    if {[llength $m_newMotorList] == 0} {
        $itk_component(show_new) configure -state disabled
        DynamicHelp::register $itk_component(show_new) balloon "no new motor"
    } else {
        $itk_component(show_new) configure -state normal
        DynamicHelp::register $itk_component(show_new) balloon ""
    }
    if {[llength $m_deletedMotorList] == 0} {
        $itk_component(show_deleted) configure -state disabled
        DynamicHelp::register $itk_component(show_deleted) balloon "no deleted motor"
    } else {
        $itk_component(show_deleted) configure -state normal
        DynamicHelp::register $itk_component(show_deleted) balloon ""
    }

    handleRefresh
}
body MotorConfigFileWidget::handleRefresh { } {
    #puts "calling handleRefresh"
    if {![info exists m_settingFromFile]} {
        log_warning nothing from file
        return
    }
    if {[llength $m_motorListToShow] <= 0} {
        log_error no motor found from the file
        return
    }

    set old_numRow $m_numRowDisplay
    set m_numRowDisplay 0
    set f $m_contentsFrame

    foreach motor $m_motorListToShow {
        #puts "check motor $motor"
        set obj [$m_deviceFactory getObjectName $motor]
        if {![info exists m_settingFromFile($motor,type)]} {
            log_warning $motor not exist
            continue
        }

        if {$gCheckButtonVar($this,ip)} {
            set chkFieldList scaledPosition
        } else {
            set chkFieldList ""
        }

        switch -exact -- $m_settingFromFile($motor,type) {
            real_motor {
                eval lappend chkFieldList $FIELD_LIST(real_motor)
            }
            pseudo_motor {
                eval lappend chkFieldList $FIELD_LIST(pseudo_motor)
            }
            default {
                log_warning bad type $m_settingFromFile($motor,type) for $motor
                continue
            }
        }
        foreach field $chkFieldList {
            #puts "                $field"
            set v_from_file $m_settingFromFile($motor,$field)
            set v_current [$obj cget -$field]
            set m_settingFromFile($motor,display_$field) 0
            if {$v_from_file != $v_current} {
                #puts "add to row $m_numRowDisplay"
                if {$m_numRowDisplay == $m_numRowCreate} {
                    createRow $m_numRowCreate
                    incr m_numRowCreate
                }

                $f.ck$m_numRowDisplay configure \
                -variable [scope m_settingFromFile($motor,select_$field)]

                $f.motor$m_numRowDisplay configure \
                -text $motor
                $f.field$m_numRowDisplay configure \
                -text $field
                $f.oldV$m_numRowDisplay configure \
                -text $v_from_file
                $f.curV$m_numRowDisplay configure \
                -text $v_current

                set m_settingFromFile($motor,display_$field) 1

                incr m_numRowDisplay
                if {$m_numRowDisplay >= $MAX_ROW} {
                    log_warning reached MAX_ROW
                    break
                }
            }
        };#foreach field
    };#foreach motor

    ####display or hide the row
    if {$old_numRow > $m_numRowDisplay} {
        for {set i $m_numRowDisplay} {$i < $old_numRow} {incr i} {
            grid forget $f.ck$i $f.motor$i $f.field$i $f.oldV$i $f.curV$i
        }
    } elseif {$old_numRow < $m_numRowDisplay} {
        for {set i $old_numRow} {$i < $m_numRowDisplay} {incr i} {
            grid $f.ck$i $f.motor$i $f.field$i $f.oldV$i $f.curV$i -sticky w
        }
    }
    handleCheckButton
    handleShow
}

body MotorConfigFileWidget::handleMotorStopped { args } {
    #puts "handleMotorStopped"

    if {[info exists gCheckButtonVar($this,auto_refresh)] && \
    [info exists gCheckButtonVar($this,ip)] && \
    $gCheckButtonVar($this,auto_refresh) && \
    $gCheckButtonVar($this,ip) } {
        handleRefresh
    }
}
body MotorConfigFileWidget::handleMotorConfiged { args } {
    #puts "handleMotorStopped"

    if {[info exists gCheckButtonVar($this,auto_refresh)] && \
    $gCheckButtonVar($this,auto_refresh) } {
        handleRefresh
    }
}
body MotorConfigFileWidget::parseRealMotor { deviceName_ } {
    lappend m_motorListFromFile $deviceName_

    foreach {controller extName} [getTrimmedLine] break
    foreach {scaledPosition upperLimit lowerLimit scaleFactor speed acceleration backlash lowerLimitOn upperLimitOn locked backlashOn reverseOn circleMode baseUnits} [getTrimmedLine] break
    getTrimmedLine

    #getPermissions
    set staffPermissions [getTrimmedLine]
    set userPermissions [getTrimmedLine]

    if {![isRealMotor $deviceName_]} {
        log_warning discard $deviceName_
        return
    }

    #save to array
    set m_settingFromFile($deviceName_,type) real_motor

    foreach field {controller extName scaledPosition upperLimit lowerLimit \
    scaleFactor speed acceleration backlash lowerLimitOn upperLimitOn \
    locked backlashOn reverseOn baseUnits} {
        set m_settingFromFile($deviceName_,$field) [set $field]
        set m_settingFromFile($deviceName_,select_$field) 0
    }

    lappend m_motorListToShow $deviceName_
}



body MotorConfigFileWidget::parsePseudoMotor { deviceName_ } {
    lappend m_motorListFromFile $deviceName_
   
    foreach {controller extName} [getTrimmedLine] break
    foreach {scaledPosition upperLimit lowerLimit lowerLimitOn upperLimitOn locked circleMode baseUnits} [getTrimmedLine] break
    getTrimmedLine
    getTrimmedLine

    #getPermissions
    set staffPermissions [getTrimmedLine]
    set userPermissions [getTrimmedLine]

    if {![isMotor $deviceName_]} {
        log_warning discard $deviceName_
        return
    }

    #save to array
    set m_settingFromFile($deviceName_,type) pseudo_motor

    foreach field {controller extName scaledPosition upperLimit lowerLimit \
    lowerLimitOn upperLimitOn locked baseUnits} {
        set m_settingFromFile($deviceName_,$field) [set $field]
        set m_settingFromFile($deviceName_,select_$field) 0
    }

    lappend m_motorListToShow $deviceName_
}


body MotorConfigFileWidget::parseController { deviceName_ } {
    foreach {hostname protocol} [getTrimmedLine] break

    #we do not want to save it, so we do a little check here
    set obj [$m_deviceFactory getObjectName $deviceName_]
    if {![$m_deviceFactory deviceExists $obj]} {
        log_warning controller $deviceName_ not exist
    }
    if {![$obj isa ::DCS::DhsMonitor]} {
        log_warning $deviceName_ is not a controller
    }
    set cur_hostname [$obj cget -hostname]
    if {$cur_hostname != $hostname} {
        log_warning controller $deviceName_ hostname changed from $hostname to $cur_hostname
    }
}

body MotorConfigFileWidget::parseIonChamber {deviceName_ } {
   foreach {controller counter channel timer timer_type} [getTrimmedLine] break
}

body MotorConfigFileWidget::parseShutter {deviceName_} {
   foreach {controller status} [getTrimmedLine] break
}

body MotorConfigFileWidget::parseRunDefinition {deviceName_ } {
   getTrimmedLine
}


body MotorConfigFileWidget::parseRunsDefinition {deviceName_ } {
   getTrimmedLine
}

body MotorConfigFileWidget::parseOperation {deviceName_} {
   foreach {controller extName} [getTrimmedLine] break

   #getPermissions
   set staffPermissions [getTrimmedLine]
   set userPermissions [getTrimmedLine]
}


body MotorConfigFileWidget::parseEncoder {deviceName_ } {
   getTrimmedLine
}

body MotorConfigFileWidget::parseString { deviceName_ } {
   getTrimmedLine
}

body MotorConfigFileWidget::getTrimmedLine { } {
   set data [gets $m_handle]
   return [string trim $data]
}
body MotorConfigFileWidget::isMotor { deviceName_ } {
    set obj [$m_deviceFactory getObjectName $deviceName_]
    if {![$m_deviceFactory deviceExists $obj]} {
        log_warning $deviceName_ not exist
        lappend m_deletedMotorList "$deviceName_ DELETED, not in current system"
        return 0
    }
    if {![$obj isa ::DCS::Motor]} {
        log_warning $deviceName_ is not a motor
        lappend m_deletedMotorList "$deviceName_ is not a motor"
        return 0
    }
    if {[$obj isa ::DCS::RealMotor]} {
        log_warning $deviceName_ is a real motor
        lappend m_deletedMotorList "$deviceName_ is a real motor"
        return 0
    }
    return 1
}
body MotorConfigFileWidget::isRealMotor { deviceName_ } {
    set obj [$m_deviceFactory getObjectName $deviceName_]
    if {![$m_deviceFactory deviceExists $obj]} {
        log_warning $deviceName_ not exist
        lappend m_deletedMotorList "$deviceName_ DELETED, not in system"
        return 0
    }
    if {![$obj isa ::DCS::Motor]} {
        log_warning $deviceName_ is not a motor
        lappend m_deletedMotorList "$deviceName_ is not a motor"
        return 0
    }
    if {![$obj isa ::DCS::RealMotor]} {
        log_warning $deviceName_ is not a real motor
        lappend m_deletedMotorList "$deviceName_ is not a real motor"
        return 0
    }
    return 1
}
body MotorConfigFileWidget::createRow { i } {
    set f $m_contentsFrame
    set gCheckButtonVar($this,ck$i) 0
    checkbutton $f.ck$i -command "$this handleCheckButton"

    label $f.motor$i
    label $f.field$i
    label $f.oldV$i
    label $f.curV$i

    bind $f.motor$i <Button-1> "$this handleClick $i"
    bind $f.field$i <Button-1> "$this handleClick $i"
    bind $f.oldV$i <Button-1> "$this handleClick $i"
    bind $f.curV$i <Button-1> "$this handleClick $i"
}
body MotorConfigFileWidget::createInitRows { } {

    for {set i 0} {$i < $m_numRowCreate} {incr i} {
        createRow $i
    }
}
body MotorConfigFileWidget::handleSubmit { } {
    puts "handle submit"
    if {![info exists m_settingFromFile]} {
        log_warning nothing from file
        return
    }
    if {[llength $m_motorListToShow] <= 0} {
        log_error no motor found from the file
        return
    }

    if {$m_numRowDisplay <= 0} {
        log_error no difference found
        return
    }
    if {[getNumSelection] <= 0} {
        log_error no selection
        return
    }

    set anyChange 0
    foreach motor $m_motorListToShow {
        set obj [$m_deviceFactory getObjectName $motor]
        set needChange 0
        set config_input [$obj getMotorConfiguration]
        set type $m_settingFromFile($motor,type)
        switch -exact -- $type {
            real_motor -
            pseudo_motor {
                if {$gCheckButtonVar($this,ip)} {
                    set fieldList scaledPosition
                } else {
                    set fieldList ""
                }
                eval lappend fieldList $FIELD_LIST($type)
            }
            default {
                log_error skip in submit: bad type $type for motor $motor
                continue
            }
        }

        #DBUG
        set orig $config_input

        foreach field $fieldList {
            if {$m_settingFromFile($motor,select_$field) \
            &&  $m_settingFromFile($motor,display_$field)} {
                puts "need change"
                set needChange 1
                set v_from_file $m_settingFromFile($motor,$field)
                set index $FIELD_INDEX($type,$field)
                set config_input \
                [lreplace $config_input $index $index $v_from_file]
            }
        };#foreach field
        if {$needChange} {
            #DEBUG
            #puts "motor: $motor need reconfig:"
            #puts "old: $orig"
            #puts "new: $config_input"

            eval $obj changeMotorConfiguration $config_input

            set anyChange 1
        }
    };#foreach motor

    if {!$anyChange} {
        log_error "no change selected"
    }
}
body MotorConfigFileWidget::getNumSelection { } {
    set numSelection 0
    set f $m_contentsFrame
    for {set i 0} {$i < $m_numRowDisplay} {incr i} {
        set sel [set [$f.ck$i cget -variable]]
        if {$sel} {
            incr numSelection
        }
    }
    return $numSelection
}
body MotorConfigFileWidget::handleCheckButton { } {
    if {[getNumSelection] > 0} {
        $itk_component(submit) configure \
        -state normal
        DynamicHelp::register $itk_component(submit) balloon ""
        $itk_component(submit) updateBubble
    } else {
        $itk_component(submit) configure \
        -state disabled
        DynamicHelp::register $itk_component(submit) balloon "no selection"
    }
}
body MotorConfigFileWidget::handleShow { } {
    grid forget $itk_component(new)
    grid forget $itk_component(deleted)
    if {$gCheckButtonVar($this,new) && [llength $m_newMotorList] > 0} {
        grid $itk_component(new) -column 1 -columnspan 14 -sticky w
    }
    if {$gCheckButtonVar($this,deleted) && [llength $m_deletedMotorList] > 0} {
        grid $itk_component(deleted) -column 1 -columnspan 14 -sticky w
    }
}
body MotorConfigFileWidget::handlePrint { } {
    global env

    # make the temporary directory if needed
    file mkdir /tmp/$env(USER)

    set beamlineName [::config getConfigRootName]

    #set the filename
    set filename /tmp/$env(USER)/config_$beamlineName.txt

    #open file for write
    if {[catch { open $filename w } fileHandle]} {
        log_error tmp File $filename cannot be opened to write. \
        Comparation not printed.
        return
    }

    puts $fileHandle "# beamline   $beamlineName"
    puts $fileHandle "# date       [time_stamp]"
    puts $fileHandle "# compare against   [$itk_component(file_name) cget -text]"
    #write out
    set oneLine [format "# %-23s %-15s %-17s %-17s" motor field "value from file" "value from system"]
    puts $fileHandle $oneLine
    set f $m_contentsFrame
    for {set i 0} {$i < $m_numRowDisplay} {incr i} {
        set motor [$f.motor$i cget -text]
        set field [$f.field$i cget -text]
        set oldV [$f.oldV$i cget -text]
        set curV [$f.curV$i cget -text]
        set oneLine [format "%-25s %-15s %-17s %-17s" $motor $field $oldV $curV]
        puts $fileHandle $oneLine
    }

    if {$gCheckButtonVar($this,new) && [llength $m_newMotorList] > 0} {
        puts $fileHandle "############# NEW MOTORS #########"
        foreach line $m_newMotorList {
            puts $fileHandle $line
        }
    }
    if {$gCheckButtonVar($this,deleted) && [llength $m_deletedMotorList] > 0} {
        puts $fileHandle "############# REMOVED MOTORS #########"
        foreach line $m_deletedMotorList {
            puts $fileHandle $line
        }
    }

    close $fileHandle

    #print
    if { [catch {
        exec a2ps $filename
    } result ]} {
        log_note $result
    }
}
body MotorConfigFileWidget::handleClick { row_num } {
    set f $m_contentsFrame

    set motor [$f.motor$row_num cget -text]
    ::DCS::MotorMoveView::changeCommonDevice $motor
}
