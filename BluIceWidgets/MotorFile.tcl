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

package provide BLUICEMotorFile 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSDeviceFactory
package require DCSUtil
package require DCSConfig

class MotorFileWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handlePrint { }
    public method handleSave { }
    public method handleLoad { }
    public method handleRefresh { }
    public method handleAutoRefresh { }
    public method handleMotorStopped { args }
    public method handleSelection { }

    private variable m_deviceFactory
    private variable m_motorList
    private variable m_fromFile

    private common gCheckButtonVar

    #contructor/destructor
    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_motorList [$m_deviceFactory getMotorList]
        #set m_motorList [lsort $m_motorList]

        itk_component add fr {
            iwidgets::labeledframe $itk_interior.lf \
            -labeltext "Command"
        } {
        }
        set controlSite [$itk_component(fr) childsite]

        itk_component add save {
            button $controlSite.cs \
            -text "Save Positions" \
            -command "$this handleSave"
        } {
        }

        itk_component add load {
            button $controlSite.cl \
            -text "Load Positions" \
            -command "$this handleLoad"
        } {
        }

        itk_component add print {
            button $controlSite.cp \
            -text "Print Positions" \
            -command "$this handlePrint"
        } {
        }

        itk_component add refresh {
            button $controlSite.rf \
            -text "Refresh" \
            -command "$this handleRefresh"
        } {
        }

        set gCheckButtonVar($this,auto_refresh) 0

        itk_component add auto_refresh {
            checkbutton $controlSite.arf \
            -variable [list [::itcl::scope gCheckButtonVar($this,auto_refresh)]] \
            -text "Auto Refresh"
            #-command "$this handleAutoRefresh"
        } {
        }

        pack $itk_component(print) -side left -expand 1 -fill x
        pack $itk_component(save) -side left -expand 1 -fill x
        pack $itk_component(load) -side left -expand 1 -fill x
        pack $itk_component(refresh) -side left -expand 1 -fill x
        pack $itk_component(auto_refresh) -side left -expand 1 -fill x

        $itk_component(auto_refresh) select

        # create labeled frame
        itk_component add motorControlFrame {
            ::DCS::TitledFrame $itk_interior.mc \
            -labelFont "helvetica -18 bold" \
            -labelText "Motor Control"
        } {
            keep -background
        }
        set motorControlFrame [ $itk_component(motorControlFrame) childsite]

        # construct the panel of control buttons
        itk_component add control {
            ::DCS::MotorControlPanel  $motorControlFrame.control \
            -width 7 \
            -orientation "horizontal" \
            -activeButtonBackground #c0c0ff  \
            -font "helvetica -14 bold"
        } {
        }

        # construct the motor widget
        itk_component add deviceViewer {
            ::DCS::TitledMotorEntry $motorControlFrame.motor \
            -labelText "Null" \
            -autoGenerateUnitsList 1 \
            -activeClientOnly 0  \
            -units mm
        } {
            keep -activeClientOnly
            keep -systemIdleOnly
            keep -mdiHelper
        }

        pack $itk_component(deviceViewer) -side left -expand 1 -fill x
        pack $itk_component(control) -side left -expand 1 -fill x

        $itk_component(control) registerMotorWidget ::$itk_component(deviceViewer)

        itk_component add contents {
            iwidgets::scrolledlistbox $itk_interior.cts \
            -selectmode single \
            -hscrollmode none \
            -textfont "courier 12 bold" \
            -width 650 \
            -height 370 \
            -selectioncommand "$this handleSelection"
        } {
        }

        pack $itk_component(fr) -fill x
        pack $itk_component(motorControlFrame) -fill x
        pack $itk_component(contents) -expand 1 -fill both

        eval itk_initialize $args

        $itk_option(-controlSystem) register $this motorStopped handleMotorStopped
    }
    destructor {
        $itk_option(-controlSystem) unregister $this motorStopped handleMotorStopped
    }
}

body MotorFileWidget::handlePrint { } {
    global env

    # make the temporary directory if needed
    file mkdir /tmp/$env(USER)

    set beamlineName [::config getConfigRootName]

    #set the filename
    set filename /tmp/$env(USER)/config_$beamlineName.txt

    #open file for write
    if {[catch { open $filename w } fileHandle]} {
        log_error tmp File $filename cannot be opened to write. \
        Configuration not printed.
        return
    }

    puts $fileHandle "# beamline   $beamlineName"
    puts $fileHandle "# date       [time_stamp]"
    #write out motor position
    foreach motorName $m_motorList {
        set obj [$m_deviceFactory getObjectName $motorName]
        set pos [$obj getScaledPosition]
        set value [lindex $pos 0]
        set units [lindex $pos 1]
        if {[$obj getMotorType] == "pseudo"} {
            set type "Scripted"
        } else {
            set type ""
        }
        set oneLine [format "%-25s %17.8f %-10s %10s" $motorName $value $units $type]
        puts $fileHandle $oneLine
    }

    close $fileHandle

    #print
    if { [catch {
        exec a2ps $filename
    } result ]} {
        log_note $result
    }
}

body MotorFileWidget::handleSave { } {
    set filename [tk_getSaveFile]

    if {$filename == {} } return

    #open file for write
    if {[catch { open $filename w } fileHandle]} {
        log_error File $filename cannot be opened to write. \
        Configuration not saved.
        return
    }

    #write header to file
    puts $fileHandle "# file       $filename"
    puts $fileHandle "# beamline   [::config getConfigRootName]"
    puts $fileHandle "# date       [time_stamp]"
    puts $fileHandle ""


    #write out motor position
    foreach motorName $m_motorList {
        set obj [$m_deviceFactory getObjectName $motorName]
        set pos [$obj getScaledPosition]
        set value [lindex $pos 0]
        set units [lindex $pos 1]
        set oneLine [format "%-18s %10.3f %s" $motorName $value $units]
        puts $fileHandle $oneLine
    }

    close $fileHandle
    log_note "Motor Positions saved to $filename"
}

body MotorFileWidget::handleLoad { } {
    set filename [tk_getOpenFile]

    if {$filename == {} } return

    #open file for read
    if {[catch { open $filename r } fileHandle]} {
        log_error File $filename cannot be opened to read. \
        return
    }

    # read header from file
    gets $fileHandle buffer
    gets $fileHandle buffer
    gets $fileHandle buffer
    gets $fileHandle buffer

    array unset m_fromFile

    set lines 0
    while { [gets $fileHandle buffer] >= 0 } {
        set m_fromFile($lines) $buffer
        incr lines
    }
    set m_fromFile(total_lines) $lines
    close $fileHandle

    handleRefresh
}
body MotorFileWidget::handleAutoRefresh { } {
    puts "auto"
    if {[info exists gCheckButtonVar($this,auto_refresh)]} {
        puts "exists gCheckButtonVar($this,auto_refresh)"
        puts "$gCheckButtonVar($this,auto_refresh)"
    }
    puts "var: [$itk_component(auto_refresh) cget -variable]"
}
body MotorFileWidget::handleRefresh { } {
    #puts "calling handleRefresh"
    if {![info exists m_fromFile(total_lines)]} {
        puts "bad contents from file cached"
        return
    }

    $itk_component(contents) clear

    for {set i 0} {$i < $m_fromFile(total_lines)} {incr i} {
        set buffer $m_fromFile($i)

        # parse the configuration line
        set motor [lindex $buffer 0]
        set value [lindex $buffer 1]
        set units [lindex $buffer 2]

        # make sure motor exists
        if { [lsearch -exact $m_motorList $motor] == -1 } {
            log_error "Motor $motor does not exist."
            continue
        }
        set obj [$m_deviceFactory getObjectName $motor]
        set baseUnits [$obj cget -baseUnits]
        if {$units != $baseUnits} {
            set value [$obj convertUnits $value $units $baseUnits]
        }
        set current_position [$obj cget -scaledPosition]
        if { abs( $value - $current_position ) > 0.001} {
            set oneLine [format "%-62s %17.8f %-10s" $buffer $current_position $baseUnits]
            $itk_component(contents) insert end $oneLine
        }
    }
}

body MotorFileWidget::handleSelection { } {
    #get the line
    set selection [$itk_component(contents) getcurselection]

    if {[llength $selection] == 0} {
        #no selection
        return
    }

    if {[$itk_component(contents) cget -selectmode] == "multiple"} {
        set line [lindex $selection 0]
    } else {
        set line $selection
    }

    set motor [lindex $line 0]
    set value [lindex $line 1]
    set units [lindex $line 2]

    #puts "selection: motor=$motor value=$value units=$units"

    set device [$m_deviceFactory getObjectName $motor]

    if {[$itk_component(deviceViewer) cget -device] != $device} {
        $itk_component(deviceViewer) configure \
        -device $device \
        -labelText $motor \
        -units [$device cget -baseUnits]
    }

    $itk_component(deviceViewer) setValue "$value $units"
}

body MotorFileWidget::handleMotorStopped { args } {
    #puts "handleMotorStopped"

    if {[info exists gCheckButtonVar($this,auto_refresh)] && \
    $gCheckButtonVar($this,auto_refresh) } {
        handleRefresh
    }
}
