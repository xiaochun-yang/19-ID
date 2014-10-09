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

package provide BLUICEMotorLockView 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSDeviceFactory
package require DCSUtil
package require DCSConfig

class MotorLockView {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -motorList motorList MotorList ""

    public method handleCheckButton { }
    public method handleButtonAll { }
    public method redisplay { }

    public method handleLockedUpdate

    public method lockMotor { index } {
        set motorName [lindex $itk_option(-motorList) $index]
        set obj [$m_deviceFactory getObjectName $motorName]
        $obj setLock 1
    }
    public method unlockMotor { index } {
        set motorName [lindex $itk_option(-motorList) $index]
        set obj [$m_deviceFactory getObjectName $motorName]
        $obj setLock 0
    }
    public method lockAll { lock } {
        set row -1
        foreach motorName $itk_option(-motorList) {
            incr row
            if {$gCheckButtonVar($this,chk$row)} {
                set obj [$m_deviceFactory getObjectName $motorName]
                $obj setLock $lock
                puts "set lock to $motorName"
            }
        }
    }

    private method adjustRows
    private method addRows
    private method getNumSelection { }

    private variable m_deviceFactory
    private variable m_motorList ""
    private variable m_tableSite
    private variable m_numRowCreated 0
    private variable m_numRowDisplayed 0

    private variable m_anySelectedWrap

    private common gCheckButtonVar

    private common EVEN_BACKGROUND #A0A0A0
    private common ODD_BACKGROUND  #C0C0C0

    #contructor/destructor
    constructor { args  } {
        set m_anySelectedWrap [::DCS::ManualInputWrapper ::#auto]
        $m_anySelectedWrap setValue 0

        set m_deviceFactory [DCS::DeviceFactory::getObject]

        itk_component add fr {
            frame $itk_interior.lf
        } {
        }
        set controlSite $itk_component(fr)

        set gCheckButtonVar($this,hide) 0
        itk_component add hide {
            checkbutton $controlSite.hide \
            -variable [scope gCheckButtonVar($this,hide)] \
            -text "Hide Unselected" \
            -command "$this redisplay"
        } {
        }
        pack $itk_component(hide) -side right

        itk_component add contentsFrame {
            iwidgets::scrolledframe $itk_interior.ctsFrame \
            -vscrollmode static
        } {
            keep -width -height
        }
        set m_tableSite [$itk_component(contentsFrame) childsite]
        set f $m_tableSite
        set gCheckButtonVar($this,all) 1
        itk_component add all {
            checkbutton $f.all \
            -text "All" \
            -command "$this handleButtonAll" \
            -variable [scope gCheckButtonVar($this,all)]
        } {
        }

        itk_component add aLock {
            DCS::Button $f.lockAll \
            -text "Lock All" \
            -foreground red \
            -command "$this lockAll 1"
        } {
        }

        itk_component add aUnlock {
            DCS::Button $f.unlockAll \
            -text "Unlock All" \
            -command "$this lockAll 0"
        } {
        }

        foreach com {aLock aUnlock} {
            $itk_component($com) addInput \
            "$m_anySelectedWrap value 1 {No motor selected}"
        }

        grid $itk_component(all) \
        $itk_component(aLock) $itk_component(aUnlock) -sticky w

        set ODD_BACKGROUND [$f.all cget -background]

        addRows 10

        pack $itk_component(fr) -fill x
        pack $itk_component(contentsFrame) -expand 1 -fill both

        eval itk_initialize $args
    }
    destructor {
        delete object $m_anySelectedWrap
        foreach motorName $m_motorList {
            set obj [$m_deviceFactory getObjectName $motorName]
            $obj unregister $this lockOn handleLockedUpdate
        }
    }
}

body MotorLockView::handleCheckButton { } {
    set n [getNumSelection]
    puts "n=$n"

    if {$n > 0} {
        $m_anySelectedWrap setValue 1
    } else {
        $m_anySelectedWrap setValue 0
    }

    if {$n == $m_numRowDisplayed} {
        if {!$gCheckButtonVar($this,all)} {
            $itk_component(all) select
        }
    } else {
        if {$gCheckButtonVar($this,all)} {
            $itk_component(all) deselect
        }
    }

    if {$gCheckButtonVar($this,hide)} {
        redisplay
    }

    if {$n == 0 && $gCheckButtonVar($this,hide)} {
        set gCheckButtonVar($this,hide) 0
        redisplay
    }
}
body MotorLockView::getNumSelection { } {
    set numSelection 0
    set f $m_tableSite
    for {set i 0} {$i < $m_numRowDisplayed} {incr i} {
        set sel [set [$f.chk$i cget -variable]]
        if {$sel} {
            incr numSelection
        }
    }
    return $numSelection
}
body MotorLockView::handleLockedUpdate { name_ ready_ - value_ - } {
    if {!$ready_} return

    set name [$name_ cget -deviceName]
    set index [lsearch -exact $m_motorList $name]
    if {$index >= 0} {
        if {$value_ == "1"} {
            set fg red
        } else {
            set fg black
        }
        $itk_component(chk$index) configure -foreground $fg
    }
}
body MotorLockView::handleButtonAll { } {
    for {set i 0} {$i < $m_numRowDisplayed} {incr i} {
        set gCheckButtonVar($this,chk$i) $gCheckButtonVar($this,all)
    }
    handleCheckButton
    if {$gCheckButtonVar($this,hide)} {
        redisplay
    }
}
body MotorLockView::redisplay { } {
    set n [getNumSelection]
    if {$n == 0 && $gCheckButtonVar($this,hide)} {
        set gCheckButtonVar($this,hide) 0
    }

    set f $m_tableSite

    set hideUnselected $gCheckButtonVar($this,hide)

    ## it is OK without remove all first.
    set numToCheck [llength $itk_option(-motorList)]
    for {set i 0} {$i < $numToCheck} {incr i} {
        if {$hideUnselected && !$gCheckButtonVar($this,chk$i)} {
            grid remove $f.chk$i $f.lock$i $f.unlock$i
        } else {
            grid $f.chk$i $f.lock$i $f.unlock$i -sticky nws
        }
    }
}
body MotorLockView::addRows { num } {
    for {set i 0} {$i < $num} {incr i} {
        set gCheckButtonVar($this,chk$m_numRowCreated) 1
        itk_component add chk$m_numRowCreated {
            checkbutton $m_tableSite.chk$m_numRowCreated \
            -text "unknown motor" \
            -command "$this handleCheckButton" \
            -variable [scope gCheckButtonVar($this,chk$m_numRowCreated)] \
        } {
        }
        itk_component add lock$m_numRowCreated {
            DCS::Button $m_tableSite.lock$m_numRowCreated \
            -text "Lock" \
            -foreground red \
            -command "$this lockMotor $m_numRowCreated" \
        } {
        }
        itk_component add unlock$m_numRowCreated {
            DCS::Button $m_tableSite.unlock$m_numRowCreated \
            -text "Unlock" \
            -command "$this unlockMotor $m_numRowCreated" \
        } {
        }

        incr m_numRowCreated
    }
}
body MotorLockView::adjustRows { num } {
    if {$num == $m_numRowCreated} {
        return
    }
    if {$num > $m_numRowCreated} {
        addRows [expr $num - $m_numRowCreated]
        ##this will make m_numRowCreated == num
    }

    while {$m_numRowDisplayed < $num} {
        grid $itk_component(chk$m_numRowDisplayed) \
        -row [expr $m_numRowDisplayed + 1] \
        -column 0 \
        -sticky nws

        grid $itk_component(lock$m_numRowDisplayed) \
        -row [expr $m_numRowDisplayed + 1] \
        -column 1 \
        -sticky nws

        grid $itk_component(unlock$m_numRowDisplayed) \
        -row [expr $m_numRowDisplayed + 1] \
        -column 2 \
        -sticky nws

        incr m_numRowDisplayed
    }

    while {$m_numRowDisplayed > $num} {
        set slaves [grid slaves $m_tableSite -row $m_numRowDisplayed]
        eval grid forget $slaves
        incr m_numRowDisplayed -1
    }
}
configbody MotorLockView::motorList {
    if {$m_motorList != ""} {
        foreach motorName $m_motorList {
            set obj [$m_deviceFactory getObjectName $motorName]
            $obj unregister $this lockOn handleLockedUpdate
        }
    }
    set num [llength $itk_option(-motorList)]
    adjustRows $num
    set row 0
    foreach motorName $itk_option(-motorList) {
        $itk_component(chk$row) configure -text $motorName
        incr row
    }

    ### this line must be before registers.
    set m_motorList $itk_option(-motorList)
    foreach motorName $m_motorList {
        set obj [$m_deviceFactory getObjectName $motorName]
        $obj register $this lockOn handleLockedUpdate
    }
}
