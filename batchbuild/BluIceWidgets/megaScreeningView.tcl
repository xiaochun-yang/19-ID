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

package provide BLUICEMegaScreeningView 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSButton
package require DCSEntry
package require DCSDeviceFactory
package require BLUICERobot

class MegaScreeningListWrap {
    inherit ::DCS::Component

    public variable threshold 1

    public method setNum { num } {
        set m_num $num
        updateRegisteredComponents enough_data
    }

    public method getEnoughData { } {
        return [expr ($m_num >= $threshold)?1:0]
    }
    private variable m_num 0

    constructor { args } {
        ::DCS::Component::constructor { enough_data { getEnoughData } }
    } {
        announceExist
    }
}

class MegaScreeningInfoWrap {
    inherit ::DCS::Component

    public method getLeftOK { } {
        return $m_leftOK
    }
    public method getMiddleOK { } {
        return $m_middleOK
    }
    public method getRightOK { } {
        return $m_rightOK
    }
    public method update { cassetteInfo } {
        foreach {l m r} $cassetteInfo break
        set m_leftOK [expr ![string equal $l "undefined"]]
        set m_middleOK [expr ![string equal $m "undefined"]]
        set m_rightOK [expr ![string equal $r "undefined"]]

        updateRegisteredComponents leftOK
        updateRegisteredComponents middleOK
        updateRegisteredComponents rightOK
    }
    private variable m_leftOK 0
    private variable m_middleOK 0
    private variable m_rightOK 0

    constructor { args } {
        ::DCS::Component::constructor { \
        leftOK   { getLeftOK } \
        middleOK { getMiddleOK } \
        rightOK  { getRightOK } \
        }
    } {
        announceExist
    }
}
class MegaScreeningCassetteExistWrap {
    inherit ::DCS::Component

    public method getLeftOK { } {
        return $m_leftOK
    }
    public method getMiddleOK { } {
        return $m_middleOK
    }
    public method getRightOK { } {
        return $m_rightOK
    }
    public method update { contents } {
        set statusLeft   [lindex $contents 0]
        set statusMiddle [lindex $contents 97]
        set statusRight  [lindex $contents 194]

        set OKLeft   [expr ![string equal $statusLeft "-"]]
        set OKMiddle [expr ![string equal $statusMiddle "-"]]
        set OKRight  [expr ![string equal $statusRight "-"]]

        if {$m_leftOK != $OKLeft} {
            set m_leftOK $OKLeft
            updateRegisteredComponents leftOK
        }
        if {$m_middleOK != $OKMiddle} {
            set m_middleOK $OKMiddle
            updateRegisteredComponents middleOK
        }
        if {$m_rightOK != $OKRight} {
            set m_rightOK $OKRight
            updateRegisteredComponents rightOK
        }
    }
    private variable m_leftOK 0
    private variable m_middleOK 0
    private variable m_rightOK 0

    constructor { args } {
        ::DCS::Component::constructor { \
        leftOK   { getLeftOK } \
        middleOK { getMiddleOK } \
        rightOK  { getRightOK } \
        }
    } {
        announceExist
    }
}
class MegaScreeningView {
    inherit ::itk::Widget ::DCS::Component

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    private variable m_deviceFactory
    private variable m_opMega
    private variable m_strSequenceDeviceState
    private variable m_strCassetteOwner
    private variable m_strMegaCassetteList
    private variable m_strMegaSyncDir
    private variable m_strRobotCassette

    ###this one to addInput
    private variable m_opSequence

    private variable m_cassetteList {undefined undefineid undefined}
    private variable m_permit {1 1 1}
    private variable m_megaCassetteList ""

    private variable m_listHolder
    private variable m_infoHolder
    private variable m_existHolder

    public method handleCassetteInfoChange
    public method handleCassettePermitChange
    public method handleMegaCassetteListChange
    public method handleRobotCassetteChange
    public method addCassette { cas }
    public method start { }
    public method clear { }

    public method setSelection { contents } {
        if {$contents == $m_megaCassetteList} {
            set bg #00a040
        } else {
            set bg red
        }
        $itk_component(selection) configure \
        -text $contents \
        -background $bg

        set ll [llength $contents]
        $m_listHolder setNum $ll
    }
    public method setDirectory { cas dir } {
        #puts "setDir $cas $dir"
        #puts "state: [$itk_component(${cas}_dir) getState]"
        set index -1
        switch -exact -- $cas {
            left { set index 0 }
            middle { set index 1 }
            right { set index 2 }
            default { return }
        }
        if {[$itk_component(${cas}_dir) getState] != "normal"} {
            #puts "skip not normal"
            return
        }
        set old [$m_strMegaSyncDir getContents]
        set ll [llength $old]
        switch -exact -- $ll {
            0 { set old [list {} {} {}] }
            1 { lappend old {} {} }
            2 { lappend old {} }
        }
        set old_dir [lindex $old $index]
        if {$old_dir != $dir} {
            set new [lreplace $old $index $index $dir]
            $m_strMegaSyncDir sendContentsToServer $new
        } else {
            #puts "skip same"
        }
    }

    private method updateDisplay
    private method updateSelection

    constructor { args } {
        set m_listHolder [MegaScreeningListWrap ::#auto]
        set m_infoHolder [MegaScreeningInfoWrap ::#auto]
        set m_existHolder [MegaScreeningCassetteExistWrap ::#auto]
        set user [::dcss getUser]
        set m_deviceFactory [::DCS::DeviceFactory::getObject]
        set m_opMega [$m_deviceFactory createOperation megaScreening]
        set m_strSequenceDeviceState \
        [$m_deviceFactory createString sequenceDeviceState]
        set m_strCassetteOwner \
        [$m_deviceFactory createCassetteOwnerString cassette_owner]
        set m_strMegaCassetteList \
        [$m_deviceFactory createString megaCassetteList]
        set m_strMegaSyncDir \
        [$m_deviceFactory createString megaScreeningSyncDir]
        set m_strRobotCassette \
        [$m_deviceFactory createString robot_cassette]

        $m_strMegaSyncDir createAttributeFromField left 0
        $m_strMegaSyncDir createAttributeFromField middle 1
        $m_strMegaSyncDir createAttributeFromField right 2

        set m_opSequence [$m_deviceFactory createOperation sequence]

        set ring $itk_interior

        set casNameList  [RobotBaseWidget::getCassetteNameList]
        set casLabelList [RobotBaseWidget::getCassetteLabelList]

        for {set i 1} {$i < 4} {incr i} {
            set cas [lindex $casNameList $i]
            set cLabel [lindex $casLabelList $i]
            itk_component add ${cas}_frame {
                iwidgets::Labeledframe $ring.${cas}_f \
                -labelpos nw \
                -labeltext "$cLabel cassette"
            } {
            }
            set cs [$itk_component(${cas}_frame) childsite]

            itk_component add $cas {
                DCS::Button $cs.$cas \
                -text "add" \
                -width 12 \
                -command "$this addCassette $cas"
            } {
            }

            itk_component add ${cas}_info {
                label $cs.${cas}Info \
                -text undefined
            } {
            }
            itk_component add ${cas}_dir {
                DCS::Entry $cs.${cas}_dir \
                -promptText "Directory:" \
                -entryType rootDirectory \
                -reference "$m_strMegaSyncDir ${cas}" \
                -shadowReference 1 \
                -leaveSubmit 1 \
                -onSubmit "$this setDirectory $cas %s" \
                -entryWidth 60
            } {
            }
            $itk_component(${cas}_dir) setValue "/data/$user/$cas" 1

            $itk_component($cas) addInput \
            "$m_strCassetteOwner ${cas}_permit 1 {no permit to access}"
            $itk_component(${cas}_dir) addInput \
            "$m_strCassetteOwner ${cas}_permit 1 {no permit to access}"
            $itk_component($cas) addInput \
            "$m_infoHolder ${cas}OK 1 {spreadsheet undefined}"
            $itk_component($cas) addInput \
            "$m_existHolder ${cas}OK 1 {cassette not exist}"

            grid columnconfigure $cs 0 -weight 0
            grid columnconfigure $cs 1 -weight 2
            grid $itk_component($cas) $itk_component(${cas}_info) -sticky w
            grid $itk_component(${cas}_dir) -columnspan 2 -sticky w

            grid $itk_component(${cas}_frame) -sticky w

        }

        itk_component add s_frame {
            frame $ring.s_f
        } {
        }
        set ss $itk_component(s_frame)

        itk_component add selection {
            label $ss.selection \
            -anchor w \
            -background #00a040
        } {
        }
        itk_component add s_label {
            label $ss.s_label \
            -text "Selected cassettes and order: "
        } {
        }
        pack $itk_component(s_label) -side left
        pack $itk_component(selection) -side left -expand 1 -fill x
        grid $itk_component(s_frame) -sticky news

        itk_component add c_frame {
            frame $ring.c_f
        } {
        }
        set cmds $itk_component(c_frame)
        itk_component add start {
            DCS::Button $cmds.start \
            -text Start \
            -command "$this start"
        } {
        }
        itk_component add clear {
            DCS::Button $cmds.clear \
            -text Clear \
            -command "$this clear"
        } {
        }
        pack $itk_component(start) -side left
        pack $itk_component(clear) -side right

        grid $itk_component(c_frame) -sticky news

		eval itk_initialize $args

        $itk_component(start) addInput "$m_opMega status inactive {supporting device}"
        $itk_component(start) addInput "$m_opSequence status inactive {supporting device}"
        $itk_component(start) addInput "$m_listHolder enough_data 1 {add cassette first}"

        ::mediator register $this $m_strSequenceDeviceState contents handleCassetteInfoChange
        ::mediator register $this $m_strCassetteOwner permits handleCassettePermitChange
        ::mediator register $this $m_strMegaCassetteList contents handleMegaCassetteListChange
        ::mediator register $this $m_strRobotCassette contents handleRobotCassetteChange
        announceExist
    }

    destructor {
        ::mediator unregister $this $m_strSequenceDeviceState contents
        ::mediator unregister $this $m_strCassetteOwner permits
        ::mediator unregister $this $m_strMegaCassetteList contents
        ::mediator unregister $this $m_strRobotCassette contents
    }
}
body MegaScreeningView::handleCassettePermitChange { - ready_ - contents_ - } {
    if {!$ready_} return

    set m_permit [lrange $contents_ 1 3]
    updateDisplay

    ##check if need to remove cassette from selection
    set curSelect [$itk_component(selection) cget -text]
    foreach \
    cas {left middle right} \
    info $m_cassetteList \
    permit $m_permit {
        if {!$permit} {
            set index [lsearch -exact $curSelect $cas]
            if {$index >= 0} {
                set curSelect [lreplace $curSelect $index $index]
            }
        }
    }
    if {$curSelect != [$itk_component(selection) cget -text]} {
        setSelection $curSelect
    }
}
body MegaScreeningView::handleCassetteInfoChange { - ready_ - contents_ -} {
    if {!$ready_} return

    set m_cassetteList [lrange [lindex $contents_ 2] 1 3]
    updateDisplay
    $m_infoHolder update $m_cassetteList
}
body MegaScreeningView::handleMegaCassetteListChange { - ready_ - contents_ - } {
    if {!$ready_} return

    set ll [llength $contents_]
    if {$ll % 2} {
        log_error "bad contents of string megaCassetteList: $contents_"
        return
    }

    set m_megaCassetteList [list]
    ### retrieve cassette names from the list
    foreach {cas dir} $contents_ {
        switch -exact -- $cas {
            l {
                lappend m_megaCassetteList left
            }
            m {
                lappend m_megaCassetteList middle
            }
            r {
                lappend m_megaCassetteList right
            }
        }
    }

    setSelection $m_megaCassetteList
}
body MegaScreeningView::handleRobotCassetteChange { - ready_ - contents_ - } {
    if {!$ready_} return

    $m_existHolder update $contents_
}

body MegaScreeningView::updateDisplay { } {
    foreach \
    cas {left middle right} \
    info $m_cassetteList \
    permit $m_permit {
        if {$permit} {
            $itk_component(${cas}_info) configure \
            -text $info
        } else {
            $itk_component(${cas}_info) configure \
            -text NOT_PERMIT_TO_ACCESS
        }
    }
}
body MegaScreeningView::addCassette { cas } {
    set curSelect [$itk_component(selection) cget -text]

    if {[lsearch -exact $curSelect $cas] < 0} {
        lappend curSelect $cas
        setSelection $curSelect
    }
}
body MegaScreeningView::start { } {
    set curSelect [$itk_component(selection) cget -text]
    if {[llength $curSelect] < 1} {
        log_error "select cassettes first"
        return
    }

    ###create opeartino argument
    set user [$itk_option(-controlSystem) getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set sid SID
    } else {
        set sid  PRIVATE[$itk_option(-controlSystem) getSessionId]
    }

    set param [list $user $sid]

    foreach cas $curSelect {
        lappend param [string index $cas 0]
        lappend param [$itk_component(${cas}_dir) get]
    }
    eval $m_opMega startOperation $param
}
body MegaScreeningView::clear { } {
    setSelection {}
}
