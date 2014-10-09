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

package provide BLUICEMicroSpecView 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSEntryfield

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSMotorControlPanel
package require BLUICECanvasShapes
package require BLUICEMotorLockView

class MicroSpecCalculationSetupView {
    inherit ::DCS::StringFieldViewBase

    public method getBaseReady { } {
        if {[llength $m_extendBase] < 3} {
            return 0
        }
        return 1
    }


    public method handleValidSetupUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_ctsValid $contents_
        updateValidChoice
        updateExtendChoice
    }
    protected method updateValidChoice { } {
        $itk_component(valid_menu) delete 0 end
        set nItem 0
        foreach ss $m_ctsValid {
            if {$nItem > 0} {
                $itk_component(valid_menu) add separator
            }
            incr nItem

            foreach {t a b} $ss break
            set t [expr $t / 1000.0]

            set nAvg 1
            $itk_component(valid_menu) add command \
            -label [format "%6.3f %4d %3d" $t $nAvg $b] \
            -command "$this setConfigFromMenu $t $nAvg $b"

            set nAvg $AVERAGE_STEP
            while {$nAvg < $a} {
                $itk_component(valid_menu) add command \
                -label [format "%6.3f %4d %3d" $t $nAvg $b] \
                -command "$this setConfigFromMenu $t $nAvg $b"

                incr nAvg $AVERAGE_STEP
            }

            if {$a > 1} {
                set nAvg $a
                $itk_component(valid_menu) add command \
                -label [format "%6.3f %4d %3d" $t $nAvg $b] \
                -command "$this setConfigFromMenu $t $nAvg $b"
            }
        }
        
    }
    
    public method setConfigFromMenu { t a b } {
        foreach en {eITime eNAvg eBWidth} v [list $t $a $b] {
            $itk_component($en) delete 0 end
            $itk_component($en) insert 0 $v
        }
    }

    public method setExtendBaseFromMenu { input_ } {
        set m_extendBase $input_

        if {$m_extendBase == ""} {
            set txt "------"
        } else {
            foreach {t a b} $input_ break
            set txt [format "%.2f s" $t]
        }
        $itk_component(extend_base) configure \
        -text $txt


        updateRegisteredComponents base_ready
    }

    public method saveReference { } {
        $m_objSpecWrap startOperation save_reference
    }
    public method saveDark { } {
        $m_objSpecWrap startOperation save_dark
    }
    public method extendRef { } {
        if {[llength $m_extendBase] < 3} {
            log_error bad base condition "{$m_extendBase}" for extending.
            return
        }
        set iTime [$itk_component(eITime) get]
        $m_objSpecWrap startOperation extend_reference_from_condition \
        $iTime $m_extendBase
    }

    ### called by StringXXXDisplay
    public method setDisplayLabel { name value } {
        $itk_component($name) configure \
        -text $value

        if {$name == "rValid"} {
            if {$value == "1"} {
                set color beige
            } else {
                set color red
            }
            foreach ww [list \
            rValid \
            rITime \
            rAvg \
            rBCW \
            rStamp \
            ] {
                $itk_component($ww) configure \
                -background $color
            }
        } elseif {$name == "dValid"} {
            if {$value == "1"} {
                set color beige
            } else {
                set color red
            }
            foreach ww [list \
            dValid \
            dITime \
            dAvg \
            dBCW \
            dStamp \
            ] {
                $itk_component($ww) configure \
                -background $color
            }
        }
    }

    public method setToDefault { } {
        set dddd [$m_objDefault getContents]
        set dddd [lindex $dddd 0]
        foreach {it avg bw} $dddd break
        if {[string is double  -strict $it] \
        &&  [string is integer -strict $avg] \
        &&  [string is integer -strict $bw] \
        } {
            foreach ee {eITime eNAvg eBWidth} \
            vv [list $it $avg $bw] {
                $itk_component($ee) delete 0 end
                $itk_component($ee) insert 0 $vv
            }
        }
    }


    protected method setContents { contents_ } {
        DCS::StringFieldViewBase::setContents $contents_
        updateExtendChoice
    }
    protected method updateExtendChoice { } {
        set iTime  [$itk_component(eITime)  get]
        set nAvg   [$itk_component(eNAvg)   get]
        set bWidth [$itk_component(eBWidth) get]

        if {![string is double -strict $iTime] \
        ||  ![string is double -strict $nAvg] \
        ||  ![string is double -strict $bWidth] \
        } {
            return
        }

        puts "updateExtendChoice: for {$iTime} {$nAvg} {$bWidth}"
        puts "valid: $m_ctsValid"

        set etdChoice ""
        foreach cfg $m_ctsValid {
            puts "checking $cfg"
            foreach {cTime cAvg cWidth} $cfg break
            set cTime [expr $cTime / 1000.0]
            if {$iTime > $cTime && $nAvg <= $cAvg && $bWidth == $cWidth} {
                lappend etdChoice [format "%6.3f %4d %3d" $cTime $cAvg $cWidth]
                puts "added"
            }
        }
        $itk_component(extend_menu) delete 0 end
        setExtendBaseFromMenu [lindex $etdChoice 0]
        foreach choice $etdChoice {
            foreach {t nAvg b} $choice break
            set txt [format "%6.3f %4d %3d" $t $nAvg $b]
            $itk_component(extend_menu) add command \
            -label $txt \
            -command "$this setExtendBaseFromMenu {$choice}"
        }
    }

    private variable m_objSpecWrap ""
    private variable m_objDefault ""
    private variable m_objValid ""
    private variable m_ctsValid ""
    private variable m_displayWrapStatus ""
    private variable m_extendBase ""

    private common AVERAGE_STEP 5

    constructor { args } {
        DCS::Component::constructor {
            base_ready getBaseReady
        }
    } {
        global BLC_IMAGES
        set onImage  [image create photo \
        -file "$BLC_IMAGES/lightbulb_on.gif" \
        -palette "256/256/256"]

        set offImage [image create photo \
        -file "$BLC_IMAGES/lightbulb_off.gif" \
        -palette "256/256/256"]

        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objSpecWrap   [$deviceFactory createOperation spectrometerWrap]
        set m_objDefault    [$deviceFactory createString microspec_default]
        set m_objValid      [$deviceFactory createString microspec_validSetup]
        set objWrapStatus   [$deviceFactory createString spectroWrap_status]
        $objWrapStatus      createAttributeFromKey darkValid

        label $m_site.cfg_l0 \
        -text "Current Configure"

        set rf groove
        label $m_site.cfg_l1 -relief $rf -borderwidth 2 -text "Time (s)"
        label $m_site.cfg_l2 -relief $rf -borderwidth 2 -text "Average"
        label $m_site.cfg_l3 -relief $rf -borderwidth 2 -text "Boxcar"

        itk_component add msg {
            DCS::MessageBoard $m_site.msg \
            -foreground blue \
            -background beige \
        } {
        }
        $itk_component(msg) addStrings spectro_config_msg

        itk_component add saveRef {
            DCS::Button $m_site.save_ref \
            -command "$this saveReference" \
            -image $onImage
        } {
        }
        itk_component add saveDark {
            DCS::Button $m_site.save_dark \
            -command "$this saveDark" \
            -image $offImage
        } {
        }
        $itk_component(saveRef) addInput \
        "$m_objSpecWrap permission GRANTED {PERMISSION}"
        $itk_component(saveDark) addInput \
        "$m_objSpecWrap permission GRANTED {PERMISSION}"

        label $m_site.ms_l10 -anchor e -text "Reference"
        label $m_site.ms_l20 -anchor e -text "Dark"

        set rf groove
        label $m_site.ms_l00 -relief $rf -borderwidth 2 -text "Name"
        label $m_site.ms_l01 -relief $rf -borderwidth 2 -text "Retake"
        label $m_site.ms_l02 -relief $rf -borderwidth 2 -text "Time (s)"
        label $m_site.ms_l03 -relief $rf -borderwidth 2 -text "Average"
        label $m_site.ms_l04 -relief $rf -borderwidth 2 -text "Boxcar"
        label $m_site.ms_l06 -relief $rf -borderwidth 2 -text "Time Stamp"

        label $m_site.warning \
        -foreground brown \
        -text "Please make sure sample is out of beam position before taking reference."

        set extendSite [frame $m_site.extendF]
        itk_component add extend {
            DCS::Button $extendSite.extendButton \
            -command "$this extendRef" \
            -text "Extend from" \
        } {
        }

        itk_component add extend_base {
            label $extendSite.base \
            -width 6 \
            -text "------" \
            -background beige \
        } {
        }

        itk_component add extend_choice {
            menubutton $extendSite.choice \
            -menu $extendSite.choice.menu \
            -image [DCS::MenuEntry::getArrowImage] \
            -width 16 \
            -anchor c \
            -relief raised \
        } {
        }
        itk_component add extend_menu {
            menu $extendSite.choice.menu \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0 \
        } {
        }
        pack $itk_component(extend) -side left
        pack $itk_component(extend_base) -side left
        pack $itk_component(extend_choice) -side left

        ### rValid and dValid are kept to receive number and change color of
        ### rStamp and dStamp.
        set displayLabelList [list \
        rValid refValid \
        dValid darkValid \
        rITime refIntegrationTime \
        dITime darkIntegrationTime \
        rAvg   refScansToAverage \
        dAvg   darkScansToAverage \
        rBCW   refBoxcarWidth \
        dBCW   darkBoxcarWidth \
        rStamp refTimestamp \
        dStamp darkTimestamp \
        ]

        foreach {name key} $displayLabelList {
            itk_component add $name {
                label $m_site.msV$name \
                -relief sunken \
                -background tan \
                -text $name
            } {
            }
        }

        $itk_component(rStamp) configure -width 20
        $itk_component(dStamp) configure -width 20

        set m_entryList [list \
        eITime  0 \
        eNAvg   1 \
        eBWidth 2 \
        ]

        set widthList [list 5 3 2]

        foreach {name index} $m_entryList width $widthList {
            itk_component add $name {
                entry $m_site.$name \
                -background white \
                -width $width \
                -justify center \
                -validate all \
                -vcmd [list $this updateEntryColor $name $index %P]
            } {
            }
        }

        itk_component add valid {
            menubutton $m_site.valid \
            -menu $m_site.valid.menu \
            -image [DCS::MenuEntry::getArrowImage] \
            -width 16 \
            -anchor c \
            -relief raised \
        } {
        }
        itk_component add valid_menu {
            menu $m_site.valid.menu \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0 \
        } {
        }

        frame $m_site.buttonF
        ### copied from base class
        itk_component add myApply {
            button $m_site.buttonF.apply \
            -text "Apply" \
            -command "$this applyChanges" \
        } {
        }
        itk_component add myCancel {
            button $m_site.buttonF.cancel \
            -text "Cancel" \
            -command "$this cancelChanges" \
        } {
        }

        itk_component add myDefault {
            button $m_site.buttonF.default \
            -text "Default" \
            -command "$this setToDefault" \
        } {
        }

        pack $itk_component(myApply) -side left
        pack $itk_component(myCancel) -side left
        pack $itk_component(myDefault) -side left

        grid forget $itk_component(apply) $itk_component(cancel)

        grid columnconfigure $m_site 0 -weight 0
        grid columnconfigure $m_site 1 -weight 0
        grid columnconfigure $m_site 2 -weight 0 
        grid columnconfigure $m_site 6 -weight 10

        grid x x $m_site.cfg_l1 $m_site.cfg_l2 $m_site.cfg_l3

        grid $m_site.cfg_l0 - \
        $itk_component(eITime) \
        $itk_component(eNAvg) \
        $itk_component(eBWidth) \
        $itk_component(valid) \
        $m_site.buttonF -sticky news

        grid $itk_component(msg) - - - - - - -sticky news

        grid $m_site.ms_l00 \
        $m_site.ms_l01 \
        $m_site.ms_l06  - - -sticky news

        grid $m_site.ms_l20 \
        $itk_component(saveDark) \
        $itk_component(dStamp)  - - -sticky news

        grid $m_site.warning - - - - - - - -sticky w

        grid $m_site.ms_l10 \
        $itk_component(saveRef) \
        $itk_component(rStamp) - - -sticky news

        ### Aina 02/23/13 email, hide the extend function
        #grid x $extendSite -sticky news
        
        registerComponent $itk_component(myApply)

        eval itk_initialize $args

        announceExist

        setContents [$_lastStringName getContents]

        set m_displayWrapStatus [DCS::StringDictDisplayBase ::\#auto $this]

        $m_displayWrapStatus setLabelList $displayLabelList

        $m_displayWrapStatus configure \
        -stringName ::device::spectroWrap_status

        $m_objValid register $this contents handleValidSetupUpdate

        $itk_component(extend) addInput \
        "$m_objSpecWrap permission GRANTED {PERMISSION}"
        $itk_component(extend) addInput \
        "$this base_ready 1 {No suitable reference found to extend}"
        $itk_component(extend) addInput \
        "$objWrapStatus darkValid 1 {Take Dark First}"
    }
    destructor {
        delete object $m_displayWrapStatus
        $m_objValid unregister $this contents handleValidSetupUpdate
    }
}

class DCS::MicroSpecAlignmentView {
    inherit ::itk::Widget

    private variable m_deviceFactory
    private variable m_opISample
    private variable m_statusObj

	public method mountPin { tool_num }
	public method dismountPin

	constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_opISample [$m_deviceFactory createOperation ISampleMountingDevice]
        set m_statusObj [$m_deviceFactory createString robot_status]
        $m_statusObj createAttributeFromField status_num 1
        $m_statusObj createAttributeFromField mounted 15

        itk_component add robot {
            iwidgets::Labeledframe $itk_interior.robot \
            -labelfont "helvetica -16 bold" \
            -labelpos nw \
            -labeltext "Pin"
        } {
        }
        set robotSite [$itk_component(robot) childsite]

        itk_component add mountII {
            DCS::Button $robotSite.m2 -command "$this mountPin 1" \
            -width 22 \
            -anchor w \
            -text "Mount MicroSpec Pin(B)"
        } {
        }

        itk_component add dismount {
            DCS::Button $robotSite.d -command "$this dismountPin" \
            -width 22 \
            -anchor w \
            -text "Dismount Alignment Pin"
        } {
        }

        foreach item {mountII dismount} {
            $itk_component($item) addInput \
            "$m_opISample permission GRANTED {PERMISSION}"

            $itk_component($item) addInput \
            "$m_opISample status inactive {supporting device}"

            $itk_component($item) addInput \
            "$m_statusObj status_num 0 {robot not ready}"
        }
        $itk_component(mountII) addInput \
        "$m_statusObj mounted {} {dismount first}"
        $itk_component(dismount) addInput \
        "$m_statusObj OKToDismountTool 1 {alignment pin not mounted}"

        grid $itk_component(mountII)    -row 0 -column 0 -sticky w
        grid $itk_component(dismount)   -row 1 -column 0 -sticky w
        
        itk_component add lock {
            iwidgets::Labeledframe $itk_interior.lock \
            -labelfont "helvetica -16 bold" \
            -labelpos nw \
            -labeltext "Lock Motors"
        } {
        }
        set lockSite [$itk_component(lock) childsite]

        itk_component add lockMotors {
            MotorLockView $lockSite.lock \
            -width 400 \
            -height 260 \
            -motorList [list \
            microspec_vert \
            microspec_horz \
            microspec_lens_1_z \
            microspec_lens_1_vert1 \
            microspec_lens_1_vert2 \
            microspec_lens_1_horz1 \
            microspec_lens_1_horz2 \
            ]
        } {
        }
        pack $itk_component(lockMotors) -side top -fill both -expand 1

        pack $itk_component(robot) -side top
        pack $itk_component(lock) -side top

        eval itk_initialize $args
    }
}
body DCS::MicroSpecAlignmentView::mountPin { tool_num } {
    $m_opISample startOperation mountBeamLineTool $tool_num
}
body DCS::MicroSpecAlignmentView::dismountPin {} {
    $m_opISample startOperation dismountBeamLineTool
}

class DCS::MicroSpecMotorView {
     inherit ::DCS::CanvasShapes

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getMotorList { } {
        return [list \
        microspec_z_corr \
        microspec_vert \
        microspec_horz \
        microspec_lens_1_z \
        microspec_lens_1_vert1 \
        microspec_lens_1_vert2 \
        microspec_lens_1_vert \
        microspec_lens_1_pitch \
        microspec_lens_1_horz1 \
        microspec_lens_1_horz2 \
        microspec_lens_1_horz \
        microspec_lens_1_yaw \
        ]
    }

    constructor { args} {
        global BLC_IMAGES
        set microSpecImage [ image create photo -file "$BLC_IMAGES/microspec.gif" -palette "8/8/8"]

        $itk_component(canvas) create image 0 0 \
        -anchor nw \
        -image $microSpecImage

        place $itk_component(control) -x 10 -y 550

        set deviceFactory [DCS::DeviceFactory::getObject]
        motorView microspec_horz 387 140 sw mm 
        motorView microspec_vert 320 57 e  mm
        motorView microspec_z_corr 130 250 n mm

        motorView microspec_lens_1_z 300 436 n mm

        motorView microspec_lens_1_vert1 500 194 sw mm
        motorView microspec_lens_1_vert2 590 197 nw mm

        motorView microspec_lens_1_horz1 611 263 nw mm
        motorView microspec_lens_1_horz2 584 403 sw mm

        motorView microspec_lens_1_vert  480 500 sw mm
        motorView microspec_lens_1_pitch 480 500 nw mm
        motorView microspec_lens_1_horz  650 500 sw mm
        motorView microspec_lens_1_yaw   650 500 nw mm

        $itk_component(canvas) create rectangle 470 447 820 554 \
        -outline black \
        -width 3 \
        -tags need_top

        $itk_component(canvas) create text 820 447 \
        -anchor se \
        -text "lens 1 pseudo motors" \
        -font "helvetica -16 bold" \
        -tags need_top

        $itk_component(canvas) create line 465 435 640 435 \
        -width 3 \
        -arrow first \
        -arrowshape {20 20 4} \
        -tags need_top

        moveHotSpot microspec_vert 326  24 positive
        moveHotSpot microspec_vert 326 100 negative
        moveHotSpot microspec_horz 467 152 positive
        moveHotSpot microspec_horz 412 170 negative
        moveHotSpot microspec_z_corr 102 231 positive
        moveHotSpot microspec_z_corr 187 247 negative

        moveHotSpot microspec_lens_1_vert1 491 187 positive
        moveHotSpot microspec_lens_1_vert1 452 206 negative
        moveHotSpot microspec_lens_1_vert2 581 207 positive
        moveHotSpot microspec_lens_1_vert2 537 232 negative

        moveHotSpot microspec_lens_1_horz1 602 286 positive
        moveHotSpot microspec_lens_1_horz1 544 271 negative
        moveHotSpot microspec_lens_1_horz2 577 392 positive
        moveHotSpot microspec_lens_1_horz2 525 380 negative

        moveHotSpot microspec_lens_1_z 397 447 positive
        moveHotSpot microspec_lens_1_z 385 492 negative

        itk_component add targetIn {
            DCS::MoveMotorsToTargetButton $itk_component(canvas).tin \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -width 8 \
            -text "In"
        } {
        }
        itk_component add targetMid {
            DCS::MoveMotorsToTargetButton $itk_component(canvas).tmid \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -width 8 \
            -text "Half Way"
        } {
        }
        itk_component add targetOut {
            DCS::MoveMotorsToTargetButton $itk_component(canvas).tout \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -width 8 \
            -text "Out"
        } {
        }
        $itk_component(targetIn)  addMotor ::device::microspec_z_corr 0.0
        $itk_component(targetMid) addMotor ::device::microspec_z 30.0
        $itk_component(targetOut) addMotor ::device::microspec_z upperLimit

        place $itk_component(targetOut) -x 20  -y 330
        place $itk_component(targetMid) -x 100 -y 330
        place $itk_component(targetIn)  -x 180 -y 330

        eval itk_initialize $args

        $itk_component(canvas) configure -width 840 -height 600 

        #$itk_component(canvas) raise need_top
    }
}

class MicroSpecDefaultLevel2View {
    inherit ::DCS::StringFieldLevel2ViewBase

    protected method addEntries { site width args } {
        foreach name $args {
            itk_component add $name {
                entry $site.$name \
                -width $width \
                -justify right \
                -background white \
            } {
            }
        }
    }
    protected method addLeftJustifiedEntries { site width args } {
        foreach name $args {
            itk_component add $name {
                entry $site.$name \
                -width $width \
                -justify left \
                -background white \
            } {
            }
        }
    }

    constructor { args } {
        set m_entryList ""

        itk_component add configF {
            iwidgets::labeledframe $m_site.cF \
            -labeltext "Device Config"
        } {
        }
        set configSite [$itk_component(configF) childsite]
        label $configSite.l0 -text "Int. Time (s)" -relief groove
        label $configSite.l1 -text "Average" -relief groove
        label $configSite.l2 -text "Boxcar" -relief groove
        label $configSite.l3 -text "Light (VIS or UV_VIS)" -relief groove
        addEntries $configSite 10 iTime avg bcWidth light
        grid $configSite.l0 $configSite.l1 $configSite.l2 $configSite.l3 \
        -sticky news

        grid $itk_component(iTime) $itk_component(avg) $itk_component(bcWidth) \
        $itk_component(light) \
        -sticky news

        lappend m_entryList \
        iTime   0 0 \
        avg     0 1 \
        bcWidth 0 2 \
        light   5 0

        itk_component add timeF {
            iwidgets::labeledframe $m_site.tF \
            -labeltext "Time Scan"
        } {
        }
        set timeSite [$itk_component(timeF) childsite]
        label $timeSite.l0 -text "Prefix"
        label $timeSite.l1 -text "Directory"
        label $timeSite.l2 -text "Start Time"
        label $timeSite.l3 -text "End Time"
        label $timeSite.l4 -text "Step"
        label $timeSite.l22 -text "s"
        label $timeSite.l32 -text "s"
        label $timeSite.l42 -text "s"
        addLeftJustifiedEntries $timeSite 20 tPrefix tDir
        addEntries $timeSite 7  tStart tEnd tStep

        grid $timeSite.l0 -row 0 -column 0 -sticky e
        grid $timeSite.l1 -row 1 -column 0 -sticky e
        #grid $timeSite.l2 -row 2 -column 0 -sticky e
        grid $timeSite.l3 -row 3 -column 0 -sticky e
        grid $timeSite.l4 -row 4 -column 0 -sticky e

        grid $itk_component(tPrefix) -row 0 -column 1 -columnspan 2 -sticky news
        grid $itk_component(tDir)    -row 1 -column 1 -columnspan 2 -sticky news
        #grid $itk_component(tStart)  -row 2 -column 1 -sticky news
        grid $itk_component(tEnd)    -row 3 -column 1 -sticky news
        grid $itk_component(tStep)   -row 4 -column 1 -sticky news

        #grid $timeSite.l22 -row 2 -column 2 -sticky w
        grid $timeSite.l32 -row 3 -column 2 -sticky w
        grid $timeSite.l42 -row 4 -column 2 -sticky w

        #tStart      1 2
        lappend m_entryList \
        tPrefix     1 0 \
        tDir        1 1 \
        tEnd        1 3 \
        tStep       1 4

        itk_component add phiF {
            iwidgets::labeledframe $m_site.pF \
            -labeltext "Phi Scan"
        } {
        }
        set phiSite [$itk_component(phiF) childsite]
        label $phiSite.l0 -text "Prefix"
        label $phiSite.l1 -text "Directory"
        label $phiSite.l2 -text "Start Phi"
        label $phiSite.l3 -text "End Phi"
        label $phiSite.l4 -text "Step"
        label $phiSite.l22 -text "deg"
        label $phiSite.l32 -text "deg"
        label $phiSite.l42 -text "deg"
        addLeftJustifiedEntries $phiSite 20 pPrefix pDir
        addEntries $phiSite 7  pStart pEnd pStep

        grid $phiSite.l0 -row 0 -column 0 -sticky e
        grid $phiSite.l1 -row 1 -column 0 -sticky e
        grid $phiSite.l2 -row 2 -column 0 -sticky e
        grid $phiSite.l3 -row 3 -column 0 -sticky e
        grid $phiSite.l4 -row 4 -column 0 -sticky e

        grid $itk_component(pPrefix) -row 0 -column 1 -columnspan 2 -sticky news
        grid $itk_component(pDir)    -row 1 -column 1 -columnspan 2 -sticky news
        grid $itk_component(pStart)  -row 2 -column 1 -sticky news
        grid $itk_component(pEnd)    -row 3 -column 1 -sticky news
        grid $itk_component(pStep)   -row 4 -column 1 -sticky news

        grid $phiSite.l22 -row 2 -column 2 -sticky w
        grid $phiSite.l32 -row 3 -column 2 -sticky w
        grid $phiSite.l42 -row 4 -column 2 -sticky w

        lappend m_entryList \
        pPrefix     2 0 \
        pDir        2 1 \
        pStart      2 2 \
        pEnd        2 3 \
        pStep       2 4

        itk_component add doseF {
            iwidgets::labeledframe $m_site.dF \
            -labeltext "Dose Scan"
        } {
        }
        set doseSite [$itk_component(doseF) childsite]
        label $doseSite.l0 -text "Prefix"
        label $doseSite.l1 -text "Directory"
        label $doseSite.l2 -text "Start Time"
        label $doseSite.l3 -text "End Time"
        label $doseSite.l4 -text "Step"
        label $doseSite.l5 -text "Energy"
        label $doseSite.l6 -text "Attenuation"
        label $doseSite.l7 -text "Phi"
        label $doseSite.l8 -text "Beam Width"
        label $doseSite.l9 -text "Beam Height"
        label $doseSite.l22 -text "s"
        label $doseSite.l32 -text "s"
        label $doseSite.l42 -text "s"
        label $doseSite.l52 -text "eV"
        label $doseSite.l62 -text "%"
        label $doseSite.l72 -text "deg"
        label $doseSite.l82 -text "mm"
        label $doseSite.l92 -text "mm"
        addLeftJustifiedEntries $doseSite 20 dPrefix dDir
        addEntries $doseSite 7  dStart dEnd dStep
        addEntries $doseSite 10 dEnergy dAtt dPhi dWidth dHeight

        grid $doseSite.l0 -row 0 -column 0 -sticky e
        grid $doseSite.l1 -row 1 -column 0 -sticky e
        #grid $doseSite.l2 -row 2 -column 0 -sticky e
        grid $doseSite.l3 -row 3 -column 0 -sticky e
        grid $doseSite.l4 -row 4 -column 0 -sticky e
        grid $doseSite.l5 -row 5 -column 0 -sticky e
        grid $doseSite.l6 -row 6 -column 0 -sticky e
        grid $doseSite.l7 -row 7 -column 0 -sticky e
        grid $doseSite.l8 -row 8 -column 0 -sticky e
        grid $doseSite.l9 -row 9 -column 0 -sticky e

        grid $itk_component(dPrefix) -row 0 -column 1 -columnspan 2 -sticky news
        grid $itk_component(dDir)    -row 1 -column 1 -columnspan 2 -sticky news
        #grid $itk_component(dStart)  -row 2 -column 1 -sticky news
        grid $itk_component(dEnd)    -row 3 -column 1 -sticky news
        grid $itk_component(dStep)   -row 4 -column 1 -sticky news
        grid $itk_component(dEnergy) -row 5 -column 1 -sticky news
        grid $itk_component(dAtt)    -row 6 -column 1 -sticky news
        grid $itk_component(dPhi)    -row 7 -column 1 -sticky news
        grid $itk_component(dWidth)  -row 8 -column 1 -sticky news
        grid $itk_component(dHeight) -row 9 -column 1 -sticky news

        #grid $doseSite.l22 -row 2 -column 2 -sticky w
        grid $doseSite.l32 -row 3 -column 2 -sticky w
        grid $doseSite.l42 -row 4 -column 2 -sticky w
        grid $doseSite.l52 -row 5 -column 2 -sticky w
        grid $doseSite.l62 -row 6 -column 2 -sticky w
        grid $doseSite.l72 -row 7 -column 2 -sticky w
        grid $doseSite.l82 -row 8 -column 2 -sticky w
        grid $doseSite.l92 -row 9 -column 2 -sticky w

        #dStart      3 2
        lappend m_entryList \
        dPrefix     3 0 \
        dDir        3 1 \
        dEnd        3 3 \
        dStep       3 4 \
        dEnergy     3 5 \
        dAtt        3 6 \
        dPhi        3 7 \
        dWidth      3 8 \
        dHeight     3 9

        itk_component add snapshotF {
            iwidgets::labeledframe $m_site.sstF \
            -labeltext "Snapshot"
        } {
        }
        set snapshotSite [$itk_component(snapshotF) childsite]
        label $snapshotSite.l0 -text "Prefix"
        label $snapshotSite.l1 -text "Directory"
        addLeftJustifiedEntries $snapshotSite 20 sPrefix sDir

        grid $snapshotSite.l0 -row 0 -column 0 -sticky e
        grid $snapshotSite.l1 -row 1 -column 0 -sticky e

        grid $itk_component(sPrefix) -row 0 -column 1 -columnspan 2 -sticky news
        grid $itk_component(sDir)    -row 1 -column 1 -columnspan 2 -sticky news

        lappend m_entryList \
        sPrefix     4 0 \
        sDir        4 1 \

        grid $itk_component(configF) - - -
        grid \
        $itk_component(snapshotF) \
        $itk_component(phiF) \
        $itk_component(timeF) \
        $itk_component(doseF) \
        -sticky n

        foreach {name index0 index1} $m_entryList {
            set cmd [list $this updateEntryColor $name $index0 $index1 %P]
            $itk_component($name) configure \
            -validate all \
            -vcmd $cmd
        }

        eval itk_initialize $args
        announceExist
    }
}

class MicroSpecWindowView {
    inherit ::itk::Widget

    ### for StringXXDisplay
    public method setDisplayLabel { name value } {
        $itk_component($name) configure \
        -text $value

        if {$name == "currentIndex"} {
            ### put here the code to update the "set "field 
        }

    }
    public method refresh { } {
        $m_objSpecWrap startOperation refresh_wavelength_full_list
    }

    public method getIndex { } {
        set wl [$itk_component(wavelength) get]
        if {![string is double -strict $wl] || $wl <= 0} {
            log_error bad wavelength
            return
        }
        $m_objSpecWrap startOperation wavelength_to_index $wl
    }
    public method setCutoff { } {
        set index [$itk_component(start_index) get]
        if {![string is integer -strict $index] || $index < 0} {
            log_error bad index
            return
        }
        $m_objSpecWrap startOperation set_window_cutoff $index
    }

    private variable m_objSpecWrap
    private variable m_objValid
    private variable m_objWindowConfig
    private variable m_displayWLInfo
    private variable m_objBulbString ""

    constructor { args } {
        set deviceFactory   [DCS::DeviceFactory::getObject]
        set m_objBulbString [$deviceFactory createString spectroWrap_config]
        set m_objSpecWrap   [$deviceFactory createOperation spectrometerWrap]
        set m_objValid      [$deviceFactory createString microspec_validSetup]
        set m_objWindowConfig \
        [$deviceFactory createString spectro_window_config]

        $m_objWindowConfig createAttributeFromKey VIS
        $m_objWindowConfig createAttributeFromKey UV_VIS

        itk_component add fullF {
            iwidgets::labeledframe $itk_interior.fullF \
            -labeltext "Introduction"
        } {
        }
        set fullSite [$itk_component(fullF) childsite]

        set ctsNote \
        "The lightsource used for this system contains a halogen bulb "
        append ctsNote \
        "(producing light in the visible range) "
        append ctsNote \
        "and a deuterium bulb (producing light in the UV range).  "
        append ctsNote \
        "For measurements one may use either the halogen bulb alone (Vis) "
        append ctsNote \
        "or both the halogen and deuterium bulb (UV-Vis).  "
        append ctsNote \
        "These two choices have two different high energy cutoff settings "
        append ctsNote \
        "that are configurable here."

        label $fullSite.note \
        -text $ctsNote \
        -justify left \
        -wraplength 450 \
        -takefocus 0

        set ctsFoot \
        "Note: As UV can damage samples, the default is to only use "
        append ctsFoot \
        "the halogen bulb for measurements.  "
        append ctsFoot \
        "For safety, both lights are powered off when the hutch door is open."

        label $fullSite.foot \
        -text $ctsFoot \
        -justify left \
        -wraplength 450 \
        -takefocus 0

        label $fullSite.separator -anchor w -text ""

        set line0F [frame $fullSite.line0]
        label $line0F.l0 -text "Raw data array supported by hardware has "
        label $line0F.l1 -text " elements."

        set line1F [frame $fullSite.line1]
        label $line1F.l0 -text "Wavelength of the first element is "
        label $line1F.l1 -text " nanometer."

        set line2F [frame $fullSite.line2]
        label $line2F.l0 -text "Wavelength of the last element is "
        label $line2F.l1 -text " nanometer."

        label $fullSite.line6 -anchor w -text ""

        label $fullSite.line7 -anchor w -text \
        "Here is a help function to find out the array index from desired"

        label $fullSite.line8 -anchor w -text \
        "wavelength. The relationship is not purely linear."

        itk_component add length {
            label $line0F.ll \
            -justify right \
            -width 10 \
            -relief sunken \
            -background beige \
        } {
        }
        itk_component add first {
            label $line1F.first \
            -justify right \
            -width 10 \
            -relief sunken \
            -background beige \
        } {
        }
        itk_component add last {
            label $line2F.last \
            -justify right \
            -width 10 \
            -relief sunken \
            -background beige \
        } {
        }
        itk_component add refreshButton {
            DCS::Button $line2F.button \
            -text "Refresh" \
            -command "$this refresh" \
        } {
        }
        $itk_component(refreshButton) addInput \
        "$m_objSpecWrap permission GRANTED {PERMISSION}"

        pack $line0F.l0 $itk_component(length) $line0F.l1 -side left
        pack $line1F.l0 $itk_component(first)  $line1F.l1 -side left
        pack $line2F.l0 $itk_component(last)   $line2F.l1 \
        $itk_component(refreshButton) -side left

        pack $fullSite.note -side top -fill x
        pack $fullSite.separator -side top -fill x
        pack $line0F -side top -fill x
        pack $line1F -side top -fill x
        pack $line2F -side top -fill x
        pack $fullSite.line6 -side top -fill x
        pack $fullSite.line7 -side top -fill x
        pack $fullSite.line8 -side top -fill x

        itk_component add convertF {
            iwidgets::labeledframe $fullSite.cvtF \
            -labeltext "Get Index From Wavelength"
        } {
        }
        set cvtSite [$itk_component(convertF) childsite]

        label $cvtSite.l00 -text "wavelegnth(nm)" -justify right
        label $cvtSite.l10 -text "wavelegnth(nm)" -justify right
        label $cvtSite.l12 -text "index" -justify right

        itk_component add cvtButton {
            DCS::Button $cvtSite.button \
            -text "Convert" \
            -command "$this getIndex" \
        } {
        }
        $itk_component(cvtButton) addInput \
        "$m_objSpecWrap permission GRANTED {PERMISSION}"

        itk_component add wavelength {
            entry $cvtSite.wl \
            -justify right \
            -background white \
            -width 6 \
        } {
        }

        itk_component add currentWL {
            label $cvtSite.curW \
            -justify right \
            -width 10 \
            -relief sunken \
            -background beige \
        } {
        }
        itk_component add currentIndex {
            label $cvtSite.curI \
            -justify right \
            -width 10 \
            -relief sunken \
            -background beige \
        } {
        }
        grid $cvtSite.l00 -row 0 -column 0 -sticky e
        grid $itk_component(wavelength) -row 0 -column 1 -sticky news
        grid $itk_component(cvtButton)  -row 0 -column 2 -columnspan 2 -sticky w
        grid $cvtSite.l10 -row 1 -column 0 -sticky e
        grid $itk_component(currentWL) -row 1 -column 1 -sticky news
        grid $cvtSite.l12 -row 1 -column 2 -sticky e
        grid $itk_component(currentIndex) -row 1 -column 3

        pack $itk_component(convertF) -side top -fill x

        label $fullSite.separator2 -anchor w -text ""
        pack $fullSite.separator2 -side top -fill x
        pack $fullSite.foot -side top -fill x

        set displayLabelList [list \
        length       0 \
        first        1 \
        last         2 \
        currentWL    3 \
        currentIndex 4 \
        ]

        itk_component add windowCfgF {
            iwidgets::labeledframe $itk_interior.ccfgF \
            -labeltext "Cut Off Window Setup"
        } {
        }
        set cfgSite [$itk_component(windowCfgF) childsite]
        itk_component add windowCfg {
            MicroSpecWindowConfigView $cfgSite.ccfg
        } {
        }
        pack $itk_component(windowCfg) -side top

        pack $itk_component(fullF) -side top
        pack $itk_component(windowCfgF) -side top

        eval itk_initialize $args

        set m_displayWLInfo [DCS::StringFieldDisplayBase ::\#auto $this]
        $m_displayWLInfo setLabelList $displayLabelList

        $m_displayWLInfo configure \
        -stringName ::device::microspec_wavelength_info
    }
    destructor {
    }
}
class DCS::MicroSpecStaffView {
    inherit ::itk::Widget

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method runBatch { } {
        $m_objSpecWrap startOperation system_batch
    }
    public method deleteSetup { } {
        $m_objSpecWrap startOperation clear_setup_files
    }

    public proc getMotorList { } {
        return [list \
        microspec_z_corr \
        microspec_vert \
        microspec_horz \
        microspec_lens_1_z \
        microspec_lens_1_vert1 \
        microspec_lens_1_vert2 \
        microspec_lens_1_vert \
        microspec_lens_1_pitch \
        microspec_lens_1_horz1 \
        microspec_lens_1_horz2 \
        microspec_lens_1_horz \
        microspec_lens_1_yaw \
        ]
    }

    private variable m_objSpecWrap ""

    constructor { args } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objSpecWrap   [$deviceFactory createOperation spectrometerWrap]

        itk_component add notebook {
            DCS::TabNotebook $itk_interior.nb \
            -tabbackground lightgrey \
            -background lightgrey \
            -backdrop lightgrey \
            -borderwidth 2 \
            -tabpos n \
            -angle 20 \
            -raiseselect 1 \
            -bevelamount 4 \
        } {
        }
        $itk_component(notebook) add Motor      -label MotorView
        $itk_component(notebook) add Wrap       -label Wrap_Config
        $itk_component(notebook) add Calculate  -label "Calculation Setup"
        $itk_component(notebook) add Cutoff     -label "Hardware Cutoff Setup"
        $itk_component(notebook) add IonChamber -label "Ion Chamber Setup"
        $itk_component(notebook) add Alignment  -label "Alignment"

        set motorSite [$itk_component(notebook) childsite 0]
        set wrapSite  [$itk_component(notebook) childsite 1]
        set calSite   [$itk_component(notebook) childsite 2]
        set cutSite   [$itk_component(notebook) childsite 3]
        set ionSite   [$itk_component(notebook) childsite 4]
        set alignSite [$itk_component(notebook) childsite 5]

        itk_component add motorView {
            DCS::MicroSpecMotorView $motorSite.motor \
        } {
            keep -mdiHelper
        }
        pack $itk_component(motorView) -side top -expand 1 -fill both

        itk_component add wrap_config {
            
            DCS::SpectrometerWrapConfigView $wrapSite.config \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
        } {
        }
        pack $itk_component(wrap_config) -side top

        itk_component add lightControl {
            MicroSpecLightWidget $calSite.lc 0 \
            -labeltext "Select Light" \
        } {
        }

        itk_component add batchF {
            iwidgets::labeledframe $calSite.bF \
            -labeltext "batch setup"
        } {
        }
        set batchSite [$itk_component(batchF) childsite]

        itk_component add batch_setup {
            DCS::MicroSpecSystemBatchLevel2View $batchSite.batch \
        } {
        }
        pack $itk_component(batch_setup)

        itk_component add batchButton {
            DCS::Button $calSite.batchButton \
            -text "Generate Batch Darks and References" \
            -command "$this runBatch"
        } {
        }
        itk_component add deleteSetup {
            DCS::HotButton $calSite.deleteSetup \
            -text "Delete ALL Darks and References" \
            -confirmText "Confirm to delete ALL" \
            -width 31 \
            -command "$this deleteSetup"
        } {
        }

        pack $itk_component(lightControl) -side top
        pack $itk_component(batchF) -side top
        pack $itk_component(batchButton) -side top
        pack $itk_component(deleteSetup) -side top

        itk_component add cutoff {
            MicroSpecWindowView $cutSite.cutoff
        } {
        }
    
        pack $itk_component(cutoff) -side top

        itk_component add ion_chamber {
            MicroSpecIonView $ionSite.ion_chamber
        } {
        }
        pack $itk_component(ion_chamber) -side top

        itk_component add alignment {
            DCS::MicroSpecAlignmentView $alignSite.al
        } {
        }
        pack $itk_component(alignment) -side top

        pack $itk_component(notebook) -side top -fill both -expand 1

        $itk_component(notebook) select 0
        eval itk_initialize $args
    }
}

class MicroSpecWindowConfigView {
    inherit ::DCS::StringDictFieldViewBase

    ### OVERRIDE
    public method applyChanges { } {
        set bulb [lindex [$m_objBulbString getContents] 5]
        switch -exact -- $bulb {
            VIS {
                set sName vis_start_set
                set eName vis_end_set
            }
            UV_VIS {
                set sName uv_vis_start_set
                set eName uv_vis_end_set
            }
            default {
                log_error not supported light setup: $bulb
                return
            }
        }
        set start [$itk_component($sName) get]
        set end   [$itk_component($eName) get]

        if {![string is integer -strict $start] \
        ||  ![string is integer -strict $end] \
        || $start < 0 \
        || $end < 0 \
        || $start >= $end} {
            log_error bad index
            return
        }
        $m_objSpectroWrap startOperation set_window_cutoff $start $end
    }

    public method deleteSetup { } {
        $m_objSpectroWrap startOperation clear_setup_files
    }
    public method selectLight { } {
        set bulb [lindex [$m_objBulbString getContents] 5]
        if {$bulb == "VIS"} {
            set newBulb "UV_VIS"
        } else {
            set newBulb "VIS"
        }
        $m_objSpectroWrap startOperation set_bulb $newBulb
    }

    public method handleBulbUpdate { - ready_ - contents_ - } {

        if {!$ready_ } {
            set contents_ ""
        }

        ### restore the cut offs from their string
        cancelChanges

        set m_ctsBulbString $contents_

        set bulb [lindex $contents_ 5]

        switch -exact -- $bulb {
            VIS {
                grid forget $itk_component(vis_cut_start)
                grid forget $itk_component(vis_cut_end)
                grid forget $itk_component(uv_vis_start_set)
                grid forget $itk_component(uv_vis_end_set)

                grid $itk_component(vis_start_set) \
                -row 0 -column 1 -sticky news
                grid $itk_component(vis_end_set) \
                -row 0 -column 3 -sticky news

                grid $itk_component(uv_vis_cut_start) \
                -row 1 -column 1 -sticky news
                grid $itk_component(uv_vis_cut_end) \
                -row 1 -column 3 -sticky news
            }
            UV_VIS {
                grid forget $itk_component(vis_start_set)
                grid forget $itk_component(vis_end_set)
                grid forget $itk_component(uv_vis_cut_start)
                grid forget $itk_component(uv_vis_cut_end)

                grid $itk_component(vis_cut_start) -row 0 -column 1 -sticky news
                grid $itk_component(vis_cut_end)   -row 0 -column 3 -sticky news

                grid $itk_component(uv_vis_start_set) \
                -row 1 -column 1 -sticky news
                grid $itk_component(uv_vis_end_set) \
                -row 1 -column 3 -sticky news
            }
            default {
                grid forget $itk_component(vis_start_set)
                grid forget $itk_component(vis_end_set)
                grid forget $itk_component(uv_vis_start_set)
                grid forget $itk_component(uv_vis_end_set)

                grid $itk_component(vis_cut_start) -row 0 -column 1 -sticky news
                grid $itk_component(vis_cut_end)   -row 0 -column 3 -sticky news

                grid $itk_component(uv_vis_cut_start) \
                -row 1 -column 1 -sticky news
                grid $itk_component(uv_vis_cut_end) \
                -row 1 -column 3 -sticky news
            }
        }
    }

    private variable m_objSpectroWrap ""
    private variable m_objBulbString ""
    private variable m_objValidString ""

    constructor { args } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objBulbString  [$deviceFactory createString spectroWrap_config]
        set m_objValidString [$deviceFactory createString microspec_validSetup]
        set m_objSpectroWrap \
        [$deviceFactory createOperation spectrometerWrap]

        set m_labelList [list \
        vis_cut_start    VIS    0 \
        vis_cut_end      VIS    1 \
        uv_vis_cut_start UV_VIS 0 \
        uv_vis_cut_end   UV_VIS 1 \
        ]

        set m_entryList [list \
        vis_start_set    VIS    0 \
        vis_end_set      VIS    1 \
        uv_vis_start_set UV_VIS 0 \
        uv_vis_end_set   UV_VIS 1 \
        ]

        itk_component add light_choice {
            DCSRadiobox $m_site.light_choice \
            -stateList [list VIS UV_VIS] \
            -buttonLabels [list \
            "Start Index for Visible Light Only" \
            "Start Index for Visible + UV"] \
            -shadowReference 1 \
            -selectcolor red\
            -reference "$m_objBulbString bulb" \
            -command "$this selectLight" \
            -labeltext "" \
            -borderwidth 0 \
        } {
        }

        set chcSite [[$itk_component(light_choice) component rbox] childsite]

        foreach {name key index} $m_labelList {
            itk_component add $name {
                label $chcSite.$name \
                -width 4 \
                -anchor e \
                -relief sunken \
                -background beige \
            } {
            }
        }

        foreach {name key index} $m_entryList {
            set cmd [list $this updateEntryColor $name $key $index %P]

            itk_component add $name {
                entry $chcSite.$name \
                -width 4 \
                -background white \
                -justify right \
                -validate all \
                -vcmd $cmd \
            } {
            }
        }

        itk_component add end_v_l {
            label $chcSite.evl \
            -text "Window End Index"
        } {
        }
        itk_component add end_u_l {
            label $chcSite.eul \
            -text "Window End Index"
        } {
        }

        label $itk_interior.warning \
        -foreground brown \
        -text "delete ALL dark and reference to enable Apply Button"

        itk_component add deleteSetup {
            DCS::HotButton $itk_interior.deleteSetup \
            -background yellow \
            -text "Delete ALL Darks and References" \
            -confirmText "Confirm to delete ALL" \
            -width 31 \
            -command "$this deleteSetup"
        } {
        }

        grid $itk_component(vis_cut_start)      -row 0 -column 1 -sticky news
        grid $itk_component(end_v_l)            -row 0 -column 2 -sticky e
        grid $itk_component(vis_cut_end)        -row 0 -column 3 -sticky news

        grid $itk_component(uv_vis_cut_start)   -row 1 -column 1 -sticky news
        grid $itk_component(end_u_l)            -row 1 -column 2 -sticky e
        grid $itk_component(uv_vis_cut_end)     -row 1 -column 3 -sticky news

        addInput \
        "$m_objSpectroWrap permission GRANTED {PERMISSION}"

        addInput \
        "$m_objValidString contents {} {delete All dark and reference first}"

        pack $itk_component(light_choice) -fill both -expand 1

        ### grid these lower than Apply and Cancel.
        grid $itk_interior.warning -row 2 -column 0 -columnspan 2
        grid $itk_component(deleteSetup) -row 3 -column 0 -columnspan 2

        eval itk_initialize $args
        announceExist
        configure \
        -stringName ::device::spectro_window_config \
        -buttonBackground #c0c0ff

        $m_objBulbString register $this contents handleBulbUpdate
    }
    destructor {
        $m_objBulbString unregister $this contents handleBulbUpdate
    }
}

class MicroSpecIonView {
    inherit ::itk::Widget

    private variable m_objLightControl

    constructor { args } {
        itk_component add ff {
            iwidgets::labeledframe $itk_interior.fF \
            -labeltext "Ion Chamber Setup (units: nm)"
        } {
        }

        set strSite [$itk_component(ff) childsite]

        itk_component add config {
            DCS::MicroSpecIonChamberLevel2View $strSite.ion_chamber \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
        } {
        }
        pack $itk_component(config) -side top

        itk_component add lightControl {
            MicroSpecLightWidget $itk_interior.lc 1 \
            -labeltext "Light" \
        } {
        }

        pack $itk_component(ff) -side top
        pack $itk_component(lightControl) -side top

        eval itk_initialize $args
    }
}
