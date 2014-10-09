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

package provide BLUICERobot 1.0

# load standard packages
package require Iwidgets
package require Img

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

#package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
#package require DCSHardwareManager
#package require DCSPrompt
#package require DCSMotorControlPanel
package require DCSCheckbutton
#package require DCSGraph
package require DCSLabel
package require DCSFeedback
package require DCSDeviceLog
package require DCSCheckbox
package require DCSEntryfield
package require DCSDeviceFactory
package require BLUICECassetteView

class RobotBaseWidget {
    inherit ::itk::Widget

    #variables
    protected common s_cassetteNameList [list no left middle right]
    ##default cassette labels, OVERRIDE by bluice.cassetteLabel.xxx
    protected common s_cassetteLabelList [list no left middle right]

    protected variable m_OpList [list ISampleMountingDevice \
                                  get_robotstate \
                                  prepare_mount_crystal \
                                  mount_crystal \
                                  prepare_dismount_crystal \
                                  dismount_crystal \
                                  prepare_mount_next_crystal \
                                  mount_next_crystal \
                                  prepare_move_crystal \
                                  move_crystal \
                                  robot_standby \
                                  robot_config \
                                  robot_calibrate]

    #methods
    public proc getCassetteNameList { } {
        return $s_cassetteNameList
    }
    public proc getCassetteLabelList { } {
        return $s_cassetteLabelList
    }
    public proc initCassetteLabelList { }
    protected method registerAllButtons

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -normalBackground normalBackground NormalBackground green
    itk_option define -warningBackground warningBackground WarningBackground red
    itk_option define -systemIdleOnly systemIdleOnly SystemIdleOnly 0

    protected variable m_deviceFactory

    protected variable m_statusObj ""
    protected variable m_stateObj ""
    protected variable m_opRobotConfig ""
    protected variable m_opISample ""

    protected variable m_supportBarcode 0

    #contructor/destructor
    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_supportBarcode [$m_deviceFactory operationExists flash_barcode]

        #puts "ENTER constructor"
        set m_statusObj [$m_deviceFactory createString robot_status]
        $m_statusObj createAttributeFromField status_num 1
        $m_statusObj createAttributeFromField need_reset 3
        $m_statusObj createAttributeFromField need_cal 5
        $m_statusObj createAttributeFromField robot_state 7
        $m_statusObj createAttributeFromField warning 9
        $m_statusObj createAttributeFromField cal_msg 11
        $m_statusObj createAttributeFromField cal_step 13
        $m_statusObj createAttributeFromField mounted 15
        $m_statusObj createAttributeFromField pin_lost 17
        $m_statusObj createAttributeFromField pin_mounted 19
        $m_statusObj createAttributeFromField in_manual 21
        $m_statusObj createAttributeFromField need_mag_cal 23
        $m_statusObj createAttributeFromField need_cas_cal 25
        $m_statusObj createAttributeFromField need_clear 27
        $m_statusObj createAttributeFromField in_tool 29
        $m_statusObj createAttributeFromField extra_status_num 31
        $m_statusObj createAttributeFromField in_barcode_setup 33
        $m_statusObj createAttributeFromField in_barcode_read  35

        set m_stateObj [$m_deviceFactory createString robot_state]
        $m_stateObj createAttributeFromField sample 0
        $m_stateObj createAttributeFromField magnet 1
        $m_stateObj createAttributeFromField point 2
        $m_stateObj createAttributeFromField ln2 3
        $m_stateObj createAttributeFromField port 4
        $m_stateObj createAttributeFromField perm_pin_mounted 5
        $m_stateObj createAttributeFromField perm_pin_lost 6
        $m_stateObj createAttributeFromField pin_mounted_before_lost 7
        $m_stateObj createAttributeFromField sample_on 8
        $m_stateObj createAttributeFromField perm_pin_stripped 9
        $m_stateObj createAttributeFromField pin_stripped 10
        $m_stateObj createAttributeFromField tong_port 11
        $m_stateObj createAttributeFromField picker_port 12
        $m_stateObj createAttributeFromField placer_port 13
        $m_stateObj createAttributeFromField perm_puck_pin_mounted 14
        $m_stateObj createAttributeFromField puck_pin_mounted 15
        $m_stateObj createAttributeFromField perm_pin_moved 16
        $m_stateObj createAttributeFromField perm_puck_pin_moved 17

        set m_opRobotConfig [$m_deviceFactory createOperation robot_config]
        set m_opISample [$m_deviceFactory createOperation \
                               ISampleMountingDevice]

        eval itk_initialize $args
    }
    destructor {
    }
}
body RobotBaseWidget::registerAllButtons { buttonList } {
    foreach buttonComponent $buttonList {
        $itk_component($buttonComponent) addInput \
        "$m_statusObj robot_state idle {supporting device}"
        #check robot online
        $itk_component($buttonComponent) addInput \
        "$m_statusObj status inactive {supporting device}"
    }
}
body RobotBaseWidget::initCassetteLabelList { } {
    for {set i 0} {$i < 4} {incr i} {
        set casName [lindex $s_cassetteNameList $i]
        set cfgName bluice.cassetteLabel.$casName
        set cfgValue [::config getStr $cfgName]
        if {$cfgValue != ""} {
            set s_cassetteLabelList \
            [lreplace $s_cassetteLabelList $i $i $cfgValue]
            puts "cassetteLabel.$casName set to $cfgValue"
        }
    }
}

# it display labels in enable/disabled style according to the related bit value
class RobotStatusWidget {
    inherit RobotBaseWidget 

    public method handleStringConfigure
    public method handleExtraStringConfigure
    public method handleStringStatus

    #variables
    private variable m_ComNameList {}
    private variable m_ComMaskList {}
    private variable m_ListLength 0

    ### extra
    private variable m_ExtraComNameList {}
    private variable m_ExtraComMaskList {}
    private variable m_ExtraListLength 0

    
    protected variable m_deviceFactory

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -normalBackground normalBackground NormalBackground green
    itk_option define -warningBackground warningBackground WarningBackground red
    itk_option define -value value Value "0" \
    { 
        if {[regexp {^0+$} $itk_option(-value)] && $itk_option(-extra) == 0} {
            #turn on Zero
            $itk_component(zero_label) configure -state active
        } else {
            $itk_component(zero_label) configure -state disabled 
        }

        set value $itk_option(-value)
        #puts "value=$value"

        if {$value == "DHS offline"} {
            $itk_component(dhs_dwn) configure -state active
            set value 0
        } else {
            $itk_component(dhs_dwn) configure -state disabled
        }
        if {[regexp {^[0-9]+$} $value]} {
            #set all others
            for {set i 0} {$i < $m_ListLength} {incr i} {
                set mask    [lindex $m_ComMaskList $i]
                set comName [lindex $m_ComNameList $i]
                #puts "i=$i mask=$mask"
                set bbb [expr "$value & $mask"]
                #puts "bbb=$bbb"
                if {$bbb != 0} then {
                    $itk_component($comName) configure -state active
                } else {
                    $itk_component($comName) configure -state disabled
                }
            }
        }
    }

    itk_option define -extra extra Value "0" \
    { 
        set extra $itk_option(-extra)
        if {$extra == ""} {
            set extra 0
        }

        if {[regexp {^0+$} $itk_option(-value)] && $extra == 0} {
            $itk_component(zero_label) configure -state active
        } else {
            $itk_component(zero_label) configure -state disabled 
        }

        set value $extra
        puts "extra=$value"

        #set all others
        for {set i 0} {$i < $m_ExtraListLength} {incr i} {
            set mask    [lindex $m_ExtraComMaskList $i]
            set comName [lindex $m_ExtraComNameList $i]
            #puts "i=$i mask=$mask"
            set bbb [expr "$value & $mask"]
            #puts "bbb=$bbb"
            if {$bbb != 0} then {
                $itk_component($comName) configure -state active
            } else {
                $itk_component($comName) configure -state disabled
            }
        }
    }

    private method add_bit { parent name bitNum text } {
        itk_component add $name {
            label $parent.l$bitNum -text $text
        } {
            rename -activebackground warningBackground warningBackground WarningBackground
        }
        set mask [expr "1 << $bitNum"]
        lappend m_ComNameList $name
        lappend m_ComMaskList $mask
        set m_ListLength [llength $m_ComNameList]
    }
    
    private method add_extra_bit { parent name bitNum text } {
        itk_component add $name {
            label $parent.l$bitNum -text $text
        } {
        }
        set mask [expr "1 << $bitNum"]
        lappend m_ExtraComNameList $name
        lappend m_ExtraComMaskList $mask
        set m_ExtraListLength [llength $m_ExtraComNameList]
    }
    
    constructor { args } {
        #base class
        eval RobotBaseWidget::constructor $args
    } {
        global gIsDeveloper

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set sampleObj [$m_deviceFactory createString robot_sample]
        #puts "adding frames"
        itk_component add ring {
            frame $itk_interior.r
        } {
            keep -width -height
        }

        itk_component add f_upper {
            frame $itk_component(ring).f_u
        } {
        }

        itk_component add f_status {
            frame $itk_component(f_upper).f_d
        } {
        }

        #puts "add labeldframes"
        itk_component add f_need {
            iwidgets::Labeledframe $itk_component(f_status).f_n \
            -labelpos nw \
            -labeltext "need"
        } {
        }
        set frame_need [$itk_component(f_need) childsite ]
	    pack propagate $frame_need 1

        #puts "add f_in"
        itk_component add f_in {
            iwidgets::Labeledframe $itk_component(f_status).f_i \
            -labelpos nw \
            -labeltext "mode"
        } {
        }
        set frame_in [$itk_component(f_in) childsite ]
	    pack propagate $frame_in 1

        #puts "add f_reason"
        itk_component add f_reason {
            iwidgets::Labeledframe $itk_component(ring).f_r \
            -labelpos n \
            -labeltext "reason"
        } {
        }
        set frame_reason [$itk_component(f_reason) childsite ]
	    pack propagate $frame_reason 1

        #puts "add f_state"
        itk_component add f_state {
            iwidgets::Labeledframe $itk_component(f_upper).f_s \
            -labelpos nw \
            -labeltext "state"
        } {
        }
        set frame_state [$itk_component(f_state) childsite ]
	    pack propagate $frame_state 1
        #puts "adding items"

        itk_component add mounted {
            DCS::Label $frame_state.mntd \
            -component $m_statusObj \
            -attribute mounted \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "sample on gonio: "
        } {
        }

        itk_component add pinlost {
            DCS::Label $frame_state.pinlost \
            -component $m_statusObj \
            -attribute pin_lost \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "# pin lost: "
        } {
        }

        itk_component add counter_frame {
            frame $frame_state.f_counter
        } {
        }

        itk_component add pinmounted {
            DCS::Label $itk_component(counter_frame).pinmnt \
            -component $m_statusObj \
            -attribute pin_mounted \
            -width 4 \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "# pin mounted: "
        } {
        }

        itk_component add puckpinmounted {
            DCS::Label $itk_component(counter_frame).pkpinmnt \
            -component $m_stateObj \
            -attribute puck_pin_mounted \
            -width 4 \
            -promptWidth 12 \
            -promptAnchor w \
            -promptText " from puck: "
        } {
        }

        itk_component add reset_cnt {
            DCS::Button $itk_component(counter_frame).reset_cnt \
            -systemIdleOnly 0 \
            -width 14 \
            -text "Reset Counter" \
            -command "" 
        } {
        }
        pack $itk_component(pinmounted) -side left
        pack $itk_component(puckpinmounted) -side left
        pack $itk_component(reset_cnt) -side left


        itk_component add sample_state {
            DCS::Label $frame_state.ss \
            -width 60 -anchor w \
            -component $m_stateObj \
            -attribute sample \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "sample state: "
        } {
        }

        itk_component add magnet_state {
            DCS::Label $frame_state.ms \
            -width 60 \
            -anchor w \
            -component $m_stateObj \
            -attribute magnet \
            -promptAnchor w \
            -promptWidth 18 \
            -promptText "magnet state: "
        } {
        }

        itk_component add current_point {
            DCS::Label $frame_state.cp \
            -width 10 \
            -anchor w \
            -component $m_stateObj \
            -attribute point \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "current point: "
        } {
        }

        itk_component add has_ln2 {
            DCS::Label $frame_state.ln \
            -width 30 \
            -anchor w \
            -component $m_stateObj \
            -attribute ln2 \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "LN2: "
        } {
        }

        itk_component add current_port {
            DCS::Label $frame_state.pt \
            -width 30 \
            -anchor w \
            -component $m_stateObj \
            -attribute port \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "current port: "
        } {
        }

        itk_component add sample_msg {
            DCS::Label $frame_state.smsg \
            -width 60 \
            -anchor w \
            -component $sampleObj \
            -attribute contents \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "message: "
        } {
        }

        itk_component add perm_mounted_num {
            DCS::Label $frame_state.pmn \
            -width 60 \
            -anchor w \
            -component $m_stateObj \
            -attribute perm_pin_mounted \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "Perm. M#: "
        } {
        }

        itk_component add perm_mounted_num_puck {
            DCS::Label $frame_state.ppmn \
            -width 60 \
            -anchor w \
            -component $m_stateObj \
            -attribute perm_puck_pin_mounted \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "Perm. M# puck: "
        } {
        }

        itk_component add perm_lost_num {
            DCS::Label $frame_state.pln \
            -width 60 \
            -anchor w \
            -component $m_stateObj \
            -attribute perm_pin_lost \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "Perm. L#: "
        } {
        }

        itk_component add mnt_before_lost {
            DCS::Label $frame_state.mbl \
            -width 60 \
            -anchor w \
            -component $m_stateObj \
            -attribute pin_mounted_before_lost \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "Mounted # BL: "
        } {
        }

        itk_component add perm_stripped_num {
            DCS::Label $frame_state.psn \
            -width 60 \
            -anchor w \
            -component $m_stateObj \
            -attribute perm_pin_stripped \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "Perm. Stripped"
        } {
        }

        itk_component add stripped_frame {
            frame $frame_state.f_stripped
        } {
        }
        itk_component add stripped_num {
            DCS::Label $itk_component(stripped_frame).sn \
            -width 4 \
            -anchor w \
            -component $m_stateObj \
            -attribute pin_stripped \
            -promptWidth 18 \
            -promptAnchor w \
            -promptText "# Stripped"
        } {
        }
        itk_component add reset_stripped {
            DCS::Button $itk_component(stripped_frame).reset \
            -systemIdleOnly 0 \
            -text "Reset Stripped" \
            -width 14 \
            -command "" 
        } {
        }
        pack $itk_component(stripped_num) -side left
        pack $itk_component(reset_stripped) -side left

        #puts "adding bits"
        add_bit $frame_need nd_clr 0 "2. staff inspection"
        add_bit $frame_need nd_rst 1 "3. reset procedure"
        add_bit $frame_need nd_calm 2 "4. toolset calibration"
        add_bit $frame_need nd_calc 3 "5. cassette calibration"
        add_bit $frame_need nd_calg 4 "6. goniometer calibration"
        add_bit $frame_need nd_calb 5 "1. initial calibration"
        add_bit $frame_need nd_usra 6 "7. user action"

        add_bit $frame_reason r_ptjm   7 "port jam"
        add_bit $frame_reason r_estop  8 "emergency stop"
        add_bit $frame_reason r_safeg  9 "safe guard latched"
        add_bit $frame_reason r_nhome 10 "not at home"
        add_bit $frame_reason r_llerr 11 "software error"
        add_bit $frame_reason r_lidjm 12 "lid jam"
        add_bit $frame_reason r_grpjm 13 "gripper jam"
        add_bit $frame_reason r_lstmg 14 "magnet missing"
        add_bit $frame_reason r_colld 15 "collision"
        add_bit $frame_reason r_initp 16 "initialize error"
        add_bit $frame_reason r_tolrn 17 "toolset error"
        add_bit $frame_reason r_ln2ll 18 "LN2 level"
        add_bit $frame_reason r_heatr 19 "heater failure"
        add_bit $frame_reason r_casst 20 "cassette seating"
        add_bit $frame_reason r_pinls 21 "pin lost"
        add_bit $frame_reason r_state 22 "wrong state"
        add_bit $frame_reason r_tmout 23 "timeout in LN2"
        add_bit $frame_reason r_inprt 24 "port occupied"
        add_bit $frame_reason r_abort 25 "internal abort"
        add_bit $frame_reason r_unrch 26 "gonio unreachable"
        add_bit $frame_reason r_extnl 27 "motor reconfig"

        add_bit       $frame_in in_rst 28 "resetting"
        add_bit       $frame_in in_cal 29 "calibration"
        add_bit       $frame_in in_btl 30 "manual alignment-pin CAL"
        add_bit       $frame_in in_mnl 31 "manual gonio CAL"
        add_extra_bit $frame_in in_bcr  0 "manual barcode reader"
        add_extra_bit $frame_in in_ln2  2 "ln2 standby"
        add_extra_bit $frame_in in_rht  3 "reheating tongs"

        itk_component add zero_label {
            label $frame_in.in_nml -text "Normal"
        } {
            rename -activebackground normalBackground normalBackground NormalBackground
        }

        itk_component add dhs_dwn {
            label $frame_in.in_dwn -text "DHS Offline"
        } {
        }
        $itk_component(dhs_dwn) configure -activebackground red

        itk_component add do_clear {
            DCS::Button $frame_need.do_clr     \
            -systemIdleOnly 0 \
            -text "Inspected" \
            -command "" 
        } {
        }


        #puts "configure items"
        $itk_component(zero_label) configure -activebackground green
        $itk_component(in_ln2)     configure -activebackground green

        $itk_component(in_rst) configure -activebackground yellow
        $itk_component(in_cal) configure -activebackground yellow
        $itk_component(in_btl) configure -activebackground yellow
        $itk_component(in_mnl) configure -activebackground yellow
        $itk_component(in_bcr) configure -activebackground yellow
        $itk_component(in_rht) configure -activebackground yellow
        $itk_component(dhs_dwn) configure -activebackground red

        #rgeometry management
        #puts "packing"


        grid $itk_component(nd_calb) -sticky w -columnspan 2
        grid $itk_component(nd_clr) $itk_component(do_clear) -sticky w
        grid $itk_component(nd_rst) -sticky w -columnspan 2
        grid $itk_component(nd_calm) -sticky w -columnspan 2
        grid $itk_component(nd_calc) -sticky w -columnspan 2
        grid $itk_component(nd_calg) -sticky w -columnspan 2
        grid $itk_component(nd_usra) -sticky w -columnspan 2

        grid $itk_component(r_estop) -row 0 -column 0 -sticky w -sticky w
        grid $itk_component(r_safeg) -row 1 -column 0 -sticky w
        grid $itk_component(r_nhome) -row 2 -column 0 -sticky w
        grid $itk_component(r_llerr) -row 3 -column 0 -sticky w
        grid $itk_component(r_ptjm)  -row 4 -column 0 -sticky w
        grid $itk_component(r_lidjm) -row 0 -column 1 -sticky w
        grid $itk_component(r_grpjm) -row 1 -column 1 -sticky w
        grid $itk_component(r_lstmg) -row 2 -column 1 -sticky w
        grid $itk_component(r_colld) -row 3 -column 1 -sticky w
        grid $itk_component(r_initp) -row 0 -column 2 -sticky w
        grid $itk_component(r_tolrn) -row 1 -column 2 -sticky w
        grid $itk_component(r_ln2ll) -row 2 -column 2 -sticky w
        grid $itk_component(r_heatr) -row 3 -column 2 -sticky w
        grid $itk_component(r_casst) -row 0 -column 3 -sticky w
        grid $itk_component(r_pinls) -row 1 -column 3 -sticky w
        grid $itk_component(r_state) -row 2 -column 3 -sticky w
        grid $itk_component(r_tmout) -row 3 -column 3 -sticky w
        grid $itk_component(r_inprt) -row 0 -column 4 -sticky w
        grid $itk_component(r_abort) -row 1 -column 4 -sticky w
        grid $itk_component(r_unrch) -row 2 -column 4 -sticky w
        grid $itk_component(r_extnl) -row 3 -column 4 -sticky w

        grid $itk_component(zero_label) -row 0 -column 0 -sticky w
        grid $itk_component(in_ln2)     -row 1 -column 0 -sticky w
        grid $itk_component(dhs_dwn)    -row 2 -column 0 -sticky w
        grid $itk_component(in_rst)     -row 3 -column 0 -sticky w

        grid $itk_component(in_cal)     -row 0 -column 1 -sticky w
        grid $itk_component(in_btl)     -row 1 -column 1 -sticky w
        grid $itk_component(in_mnl)     -row 2 -column 1 -sticky w
        grid $itk_component(in_bcr)     -row 3 -column 1 -sticky w
        grid $itk_component(in_rht)     -row 4 -column 1 -sticky w

        pack $itk_component(counter_frame) -anchor w
        pack $itk_component(stripped_frame) -anchor w
        pack $itk_component(pinlost) -anchor w
        pack $itk_component(mounted) -anchor w
        pack $itk_component(sample_state) -anchor w
        pack $itk_component(magnet_state) -anchor w
        pack $itk_component(current_point) -anchor w
        pack $itk_component(has_ln2) -anchor w
        pack $itk_component(current_port) -anchor w
        pack $itk_component(sample_msg) -anchor w


        if {$gIsDeveloper} {
            pack $itk_component(perm_mounted_num) -anchor w
            pack $itk_component(perm_mounted_num_puck) -anchor w
            pack $itk_component(perm_lost_num) -anchor w
            pack $itk_component(perm_stripped_num) -anchor w
            pack $itk_component(mnt_before_lost) -anchor w
        }

        pack $itk_component(f_in) -expand 1 -fill both
        pack $itk_component(f_need) -expand 1 -fill both

        pack $itk_component(f_status) -side left -expand 1 -fill both
        pack $itk_component(f_state) -side left -expand 1 -fill both

        pack $itk_component(f_upper) -expand 1 -fill both
        pack $itk_component(f_reason) -expand 1 -fill both

        pack $itk_component(ring) -expand 1 -fill both

        eval itk_initialize $args

        #register with the string
        $m_statusObj register $this status_num handleStringConfigure
        $m_statusObj register $this extra_status_num handleExtraStringConfigure
        $m_statusObj register $this status handleStringStatus
        #puts "packing done"
        registerAllButtons {do_clear reset_cnt reset_stripped}
        $itk_component(do_clear) addInput \
        "$m_statusObj need_reset 0 {need reset}"
        $itk_component(do_clear) addInput \
        "$m_opISample status inactive {supporting device}"

        #add the disable of the button based on operation permissions
        $itk_component(do_clear) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $itk_component(reset_cnt) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $itk_component(reset_stripped) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"

        $itk_component(do_clear) addInput \
        "$m_statusObj in_manual 0 {not valid in gonio manual mode}"
        $itk_component(do_clear) addInput \
        "$m_statusObj in_tool 0 {not valid in alignment pin manual mode}"

        if {$m_supportBarcode} {
            $itk_component(do_clear) addInput \
            "$m_statusObj in_barcode_setup 0 {not valid in barcode manual mode}"
            $itk_component(do_clear) addInput \
            "$m_statusObj in_barcode_read 0 {not valid in barcode reading mode}"
        }

        #link button with command
        $itk_component(do_clear) configure \
            -command "$m_opRobotConfig startOperation clear"
        $itk_component(reset_cnt) configure \
            -command "$m_opRobotConfig startOperation reset_mounted_counter"
        $itk_component(reset_stripped) configure \
            -command "$m_opRobotConfig startOperation reset_stripped_counter"
    }
    destructor {
        #unregister with the string
        $m_statusObj unregister $this extra_status_num \
        handleExtraStringConfigure

	    $m_statusObj unregister $this status_num handleStringConfigure
	    $m_statusObj unregister $this status handleStringStatus
    }
}

body RobotStatusWidget::handleStringConfigure { stringName_ targetReady_ alias_ contents_ - } {
    #puts "handle string content $contents_"
    if { ! $targetReady_} return

    #check if in offline state
    if {$itk_option(-value) == "DHS offline"} return

    configure -value $contents_
}

body RobotStatusWidget::handleExtraStringConfigure { \
stringName_ targetReady_ alias_ contents_ - } {

    #puts "handle extra content $contents_"
    if { ! $targetReady_} return

    if {$contents_ == ""} {
        set contents_ 0
    }

    configure -extra $contents_
}

body RobotStatusWidget::handleStringStatus { stringName_ targetReady_ alias_ status_ - } {
    #puts "handle status $status_"
    if { ! $targetReady_} return

    if { $status_ != "inactive" } {
        #puts "offline"
        configure -value "DHS offline"
    } else {
        set value [$m_statusObj getFieldByIndex status_num]
        set extra [$m_statusObj getFieldByIndex extra_status_num]
        if {$extra == ""} {
            set extra 0
        }

        configure \
        -value $value \
        -extra $extra
    }
}


#only display one line of text
class RobotStatusLabel {
    inherit ::itk::Widget

    public method handleStringConfigure
    public method handleExtraStringConfigure
    public method handleBusy
    public method handleStringStatus

    private variable m_deviceFactory
    private variable m_busy 0

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -normalBackground normalBackground NormalBackground green
    itk_option define -warningBackground warningBackground WarningBackground red
    itk_option define -value value Value "0" { 
        update
    }
    itk_option define -extra extra Value "0" { 
        update
    }

    private method update { } {
        set value $itk_option(-value)
        set extra $itk_option(-extra)
        if {$extra == ""} {
            set extra 0
        }

        if {$value == "DHS offline"} {
            $itk_component(label) configure \
            -text "Offline" \
            -activebackground $itk_option(-warningBackground)
        } elseif {[regexp {^[0-9]+$} $value]} {
            if {[regexp {^[0]+$} $value]} {
                if {$extra != 0} {
                    if {[expr $extra & 3]} { 
                        $itk_component(label) configure \
                        -text "In barcode CAL" \
                        -activebackground $itk_option(-warningBackground)
                    } elseif {[expr $extra & [expr "1 << 3"]]} { 
                        $itk_component(label) configure \
                        -text "Busy" \
                        -activebackground yellow
                    } elseif {[expr $extra & [expr "1 << 2"]]} { 
                        $itk_component(label) configure \
                        -text "Standby" \
                        -activebackground $itk_option(-normalBackground)
                    } else {
                        $itk_component(label) configure \
                        -text "Busy unknown extra state" \
                        -activebackground yellow
                    }
                } else {
                    if {$m_busy} {
                        $itk_component(label) configure \
                        -text "Busy" \
                        -activebackground yellow
                    } else {
                        $itk_component(label) configure \
                        -text "Normal" \
                        -activebackground $itk_option(-normalBackground)
                    }
                }
            } elseif {[expr $value & [expr "1 << 28"]]} { 
                $itk_component(label) configure \
                -text "Resetting" \
                -activebackground $itk_option(-warningBackground)
            } elseif {[expr "$value & 2"] != 0} {
                $itk_component(label) configure \
                -text "Reset" \
                -activebackground $itk_option(-warningBackground)
            } elseif {[expr $value & [expr "1 << 6"]]} { 
                $itk_component(label) configure \
                -text "UserAction" \
                -activebackground $itk_option(-warningBackground)
            } elseif {[expr $value & [expr "1 << 29"]]} { 
                $itk_component(label) configure \
                -text "In CAL" \
                -activebackground $itk_option(-warningBackground)
            } elseif {[expr $value & [expr "1 << 30"]]} { 
                $itk_component(label) configure \
                -text "ToolMode" \
                -activebackground $itk_option(-warningBackground)
            } elseif {[expr $value & [expr "1 << 31"]]} { 
                $itk_component(label) configure \
                -text "MAN CAL" \
                -activebackground $itk_option(-warningBackground)
            } elseif {[expr "$value & 60"] != 0} {
                $itk_component(label) configure \
                -text "CAL" \
                -activebackground $itk_option(-warningBackground)
            } elseif {[expr "$value & 1"] != 0} {
                $itk_component(label) configure \
                -text "Inspect" \
                -activebackground $itk_option(-warningBackground)
            } else {
                $itk_component(label) configure \
                -text "NotReady" \
                -activebackground $itk_option(-warningBackground)
    	    }
        }
    }

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        itk_component add ring {
            frame $itk_interior.r
        }
        itk_component add label {
            label $itk_component(ring).l -text "" -state active
        } {
            keep -width -relief
        }
        pack $itk_component(label)
        pack $itk_component(ring)

        eval itk_initialize $args

        #register with the string
        set strObj [$m_deviceFactory createString robot_status]
        $strObj register $this status_num handleStringConfigure
        $strObj register $this extra_status_num handleExtraStringConfigure
        $strObj register $this robot_state handleBusy
        $strObj register $this status handleStringStatus
    }
    destructor {
        #unregister with the string
        set strObj [$m_deviceFactory createString robot_status]
        $strObj unregister $this extra_status_num handleExtraStringConfigure
	    $strObj unregister $this status_num handleStringConfigure
        $strObj unregister $this robot_state handleBusy
	    $strObj unregister $this status handleStringStatus
    }
}
body RobotStatusLabel::handleStringConfigure { stringName_ targetReady_ alias_ contents_ - } {
    if { ! $targetReady_} return

    if {$itk_option(-value) == "DHS offline"} return
    configure -value $contents_
}
body RobotStatusLabel::handleExtraStringConfigure { stringName_ targetReady_ alias_ contents_ - } {
    if { ! $targetReady_} return

    if {$contents_ == ""} {
        set contents_ 0
    }

    configure -extra $contents_
}
body RobotStatusLabel::handleBusy { stringName_ targetReady_ alias_ contents_ - } {
    if { ! $targetReady_} return

    #log_note "handleBusy: $contents_"

    if {$contents_ == "idle" } {
        set m_busy 0
    } else {
        set m_busy 1
    }

    if {$itk_option(-value) == "DHS offline"} return

    if {$itk_option(-value) != 0} return
    if {$itk_option(-extra) != 0} return
    update
}

body RobotStatusLabel::handleStringStatus { stringName_ targetReady_ alias_ status_ - } {
    #puts "handle status $status_"
        if { ! $targetReady_} return

    if { $status_ != "inactive" } {
        configure -value "DHS offline"
    } else {
        set strObj [$m_deviceFactory createString robot_status]
        configure \
        -value [$strObj getFieldByIndex status_num] \
        -extra [$strObj getFieldByIndex extra_status_num]
    }
}

class RobotControlWidget {
    inherit RobotBaseWidget

    public method handleSilConfigUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set enableFastMode [lindex $contents_ 4]
        set lastIndex [$itk_component(notebook) index end]
        puts "fastModeEnabled=$enableFastMode, lastTabIndex=$lastIndex"
        if {$enableFastMode == "1"} {
            if {$lastIndex < 7} {
                set fastSite [$itk_component(notebook) add -label "Fast_Mode"]
                itk_component add fast_info {
                    RobotFastModeWidget $fastSite.info
                } {
                }
                pack $itk_component(fast_info) -side top
            }
        } else {
            if {$lastIndex >= 7} {
                set curIndex [$itk_component(notebook) index select]
                $itk_component(notebook) delete $lastIndex
                if {$curIndex < 0 || $curIndex >= $lastIndex} {
                    $itk_component(notebook) view 0
                }
            }
        }
    }

    private variable m_strSilConfig ""

    constructor { args } {
        eval RobotBaseWidget::constructor $args
    } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_strSilConfig [$deviceFactory createString sil_config]

        itk_component add notebook {
            iwidgets::Tabnotebook $itk_interior.nb -tabpos n -height 400
        } {
        }
        itk_component add rstate {
            DCS::Label $itk_interior.rs \
            -width 60 \
            -anchor w\
            -component $m_statusObj \
            -attribute robot_state \
            -promptWidth 20 \
            -promptAnchor w \
            -promptText "Current Operation: "
        } {
        }
        itk_component add warning_msg {
            DCS::Label $itk_interior.wl \
            -width 60 -anchor w \
            -component $m_statusObj \
            -attribute warning \
            -promptWidth 20 \
            -promptAnchor w \
            -promptText "warning: " \
            -foreground Red
        } {
        }

        #create all of the pages
        set StatusSite [$itk_component(notebook) add -label "Status"]
        set ResetSite [$itk_component(notebook) add -label "Reset"]
        set CalibrateSite [$itk_component(notebook) add -label "Calibrate"]
        set LogSite [$itk_component(notebook) add -label "Log"]
        set ProbeSite [$itk_component(notebook) add -label "Probe"]
        set ConfigSite [$itk_component(notebook) add -label "Advanced"]
        set SampleZSite [$itk_component(notebook) add -label "Sample_z"]
        $itk_component(notebook) view 0
        
        itk_component add probe {
          RobotProbeWidget $ProbeSite.cs -systemIdleOnly 0
        } {
            keep -mdiHelper
        }

        itk_component add calibrate {
          RobotCalibrationWidget $CalibrateSite.cs -systemIdleOnly 0
        } {
        }

        itk_component add config {
          RobotConfigurationWidget $ConfigSite.cs -systemIdleOnly 0
        } {
        }

        itk_component add sample_z {
            SampleZAdjustWidget $SampleZSite.z
        } {
        }

        itk_component add reset {
          RobotResetWidget $ResetSite.cs
        } {
        }

        itk_component add log {
            DCS::DeviceLog $LogSite.l \
            -logStyle all
        } {
        }
        eval $itk_component(log) addOperations $m_OpList
        $itk_component(log) addLogSenders robot

        itk_component add status {
            RobotStatusWidget $StatusSite.s
        } {
        }

        eval itk_initialize $args

        pack $itk_component(probe) -expand yes -fill both
        pack $itk_component(calibrate) -expand yes -fill both
        pack $itk_component(log) -expand yes -fill both

        pack $itk_component(status) -expand yes -fill both
        pack $itk_component(config) -expand yes -fill both
        pack $itk_component(reset) -expand yes -fill both
        pack $itk_component(sample_z) -expand 1 -fill both
        pack $itk_component(notebook) -expand 1 -fill both
        pack $itk_component(rstate)
        pack $itk_component(warning_msg)
        pack $itk_interior -expand yes -fill both

        $m_strSilConfig register $this contents handleSilConfigUpdate
    }


    destructor {
        $m_strSilConfig unregister $this contents handleSilConfigUpdate
    }
}

class RobotConfigurationWidget {
    inherit RobotBaseWidget

    public method openDocument { } {
        if {[catch {
            openWebWithBrowser [::config getStr document.robot_advanced]
        } errMsg]} {
            log_error $errMsg
            log_error $errMsg
            log_error $errMsg
        } else {
            $itk_component(strip_doc) configure -state disabled
            after 10000 [list $itk_component(strip_doc) configure -state normal]
        }
    }

    constructor { args } {
        eval RobotBaseWidget::constructor $args
    } {

        global gIsDeveloper

        itk_component add left_pane {
            frame $itk_interior.left
        } {
        }

        set ring $itk_component(left_pane)

        itk_component add check {
            DCS::Checkbox $ring.check \
            -orient vertical \
            -itemList {\
            "probe cassette" 1 \
            "probe port" 2 \
            "check magnet" 4 \
            "Check Sample on Picker" 13 \
            "strict dismount" 9 \
            "Wash Before Mount" 12 \
            "scan barcode during Mount" 5 \
            "collect forces information" 6 \
            "reheat tong if gripper jam" 7 \
            "LN2 filling abort CAL" 10 \
            "debug mode" 8 \
            } \
            -stringName robot_attribute
        } {
            keep -systemIdleOnly
        }
        frame $ring.f_auto_check
        set checkSite $ring.f_auto_check
        itk_component add check_sample_xyz {
            DCS::Checkbox $checkSite.xyz \
            -itemList [list auto_check_sample_xyz 29] \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
        ### use this to disable check sample on change
        set objASC [$m_deviceFactory getObjectName auto_sample_const]
        $objASC createAttributeFromField system_on 29

        itk_component add check_sample_on {
            DCS::Checkbox $checkSite.sample_on \
            -itemList [list sample_on 9] \
            -stringName check_sample_const
        } {
            keep -systemIdleOnly
        }
        $itk_component(check_sample_on) addInput \
        "$objASC system_on 1 {must turn on auto_check_sample_xyz to use this}"

        itk_component add pin {
            DCS::Entryfield $ring.pin    \
            -validate integer \
            -fixed 3 -width 4 \
            -labeltext "Pin lost threshold to abort" \
            -labelpos e \
            -offset 3 \
            -stringName robot_attribute
        } {
            keep -systemIdleOnly
        }
        frame $ring.f_strip
        set stripSite $ring.f_strip
        itk_component add strip {
            DCS::Entryfield $stripSite.strip    \
            -validate integer \
            -fixed 3 -width 4 \
            -labeltext "Pin strip threshold to abort" \
            -labelpos e \
            -offset 11 \
            -stringName robot_attribute
        } {
            keep -systemIdleOnly
        }
        itk_component add strip_doc {
            button $stripSite.doc \
            -text "Document" \
            -command "$this openDocument"
        } {
        }
        pack $itk_component(strip) -side left -anchor w
        pack $itk_component(strip_doc) -side left -anchor w

        frame $ring.button_frame

        set buttonSite $ring.button_frame

        itk_component add chk_heater {
            DCS::Button $buttonSite.ck_htr \
            -text "Check Heater" \
            -width 15 \
            -command "$m_opRobotConfig startOperation check_heater"
        } {
            keep -systemIdleOnly
        }

        itk_component add chk_gripper {
            DCS::Button $buttonSite.ck_grp \
            -text "Check Gripper" \
            -width 15 \
            -command "$m_opRobotConfig startOperation check_gripper"
        } {
            keep -systemIdleOnly
        }

        itk_component add chk_lid {
            DCS::Button $buttonSite.ck_lid \
            -text "Check Lid" \
            -background yellow \
            -width 15 \
            -command "$m_opRobotConfig startOperation check_lid"
        } {
            keep -systemIdleOnly
        }

        itk_component add chk_toolset {
            DCS::Button $buttonSite.ck_tls \
            -text "Check Toolset" \
            -width 15 \
            -command "$m_opISample startOperation calibrateMagnet 0 1"
        } {
            keep -systemIdleOnly
        }

        itk_component add heat_tongs {
            DCS::Button $buttonSite.heat_tong \
            -text "Heat Tongs" \
            -width 15 \
            -command "$m_opRobotConfig startOperation heat_tongs 60"
        } {
            keep -systemIdleOnly
        }

        grid $itk_component(chk_toolset) -column 0 -row 0
        grid $itk_component(chk_heater)  -column 0 -row 1
        grid $itk_component(chk_gripper) -column 0 -row 2
        grid $itk_component(chk_lid)     -column 0 -row 3
        grid $itk_component(heat_tongs)  -column 1 -row 1

        registerAllButtons {chk_heater chk_gripper chk_lid chk_toolset heat_tongs}
        $itk_component(chk_toolset) addInput \
        "$m_statusObj in_manual 0 {not valid in gonio manual mode}"
        $itk_component(chk_toolset) addInput \
        "$m_statusObj in_tool 0 {not valid in alignment pin manual mode}"
        $itk_component(chk_toolset) addInput \
        "$m_statusObj need_reset 0 {do reset first}"
        $itk_component(chk_toolset) addInput \
        "$m_statusObj need_clear 0 {need staff inspection}"
        if {$m_supportBarcode} {
            $itk_component(chk_toolset) addInput \
            "$m_statusObj in_barcode_setup 0 {not valid in barcode manual mode}"
            $itk_component(chk_toolset) addInput \
            "$m_statusObj in_barcode_read 0 {not valid in barcode read mode}"
        }
        $itk_component(heat_tongs) addInput \
        "$m_statusObj status_num 0 {robot not ready}"
        $itk_component(heat_tongs) addInput \
        "$m_stateObj point P0 {robot not at home}"

        $itk_component(chk_toolset) addInput \
        "$m_opISample permission GRANTED {PERMISSION}"
        $itk_component(chk_heater) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $itk_component(chk_gripper) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $itk_component(chk_lid) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $itk_component(heat_tongs) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"

        eval itk_initialize $args

        pack $buttonSite -side top -anchor w
        pack $itk_component(check_sample_xyz) -side left -anchor w
        pack $itk_component(check_sample_on) -side left -anchor w

        pack $itk_component(pin) -side top -anchor w
        pack $stripSite -side top -anchor w
        pack $checkSite -side top -anchor w
        pack $itk_component(check) -side top -anchor w

        itk_component add right_pane {
            RobotIOWidget $itk_interior.right
        } {
            keep -systemIdleOnly
        }

        #pack $itk_component(left_pane) -side left -expand 1 -fill both
        pack $itk_component(left_pane) -side left
        pack $itk_component(right_pane) -side right
    }

    destructor {
    }
}

class RobotStripperWidget {
    inherit RobotBaseWidget

    constructor { args } {
        eval RobotBaseWidget::constructor $args
    } {
        set ring $itk_interior

        itk_component add prepare {
            DCS::Button $ring.prepare\
            -text "Standby" \
            -width 15 \
            -command "$m_opRobotConfig startOperation stripper_take_dumbbell"
        } {
            keep -systemIdleOnly
        }

        itk_component add run {
            DCS::Button $ring.run \
            -text "Run 1 cycle" \
            -width 15 \
            -command "$m_opRobotConfig startOperation stripper_run"
        } {
            keep -systemIdleOnly
        }

        itk_component add end {
            DCS::Button $ring.end \
            -text "Go Home" \
            -width 15 \
            -command "$m_opRobotConfig startOperation stripper_go_home"
        } {
            keep -systemIdleOnly
        }

        registerAllButtons {prepare run end}
        $itk_component(prepare) addInput \
        "$m_statusObj in_manual 0 {not valid in gonio manual mode}"
        $itk_component(prepare) addInput \
        "$m_statusObj in_tool 0 {not valid in alignment pin manual mode}"
        $itk_component(prepare) addInput \
        "$m_statusObj need_reset 0 {do reset first}"
        $itk_component(prepare) addInput \
        "$m_statusObj need_clear 0 {need staff inspection}"

        $itk_component(run) addInput \
        "$m_statusObj in_manual 0 {not valid in gonio manual mode}"
        $itk_component(run) addInput \
        "$m_statusObj in_tool 0 {not valid in alignment pin manual mode}"
        $itk_component(run) addInput \
        "$m_statusObj need_reset 0 {do reset first}"
        $itk_component(run) addInput \
        "$m_statusObj need_clear 0 {need staff inspection}"

        $itk_component(end) addInput \
        "$m_statusObj in_manual 0 {not valid in gonio manual mode}"
        $itk_component(end) addInput \
        "$m_statusObj in_tool 0 {not valid in alignment pin manual mode}"
        $itk_component(end) addInput \
        "$m_statusObj need_reset 0 {do reset first}"
        $itk_component(end) addInput \
        "$m_statusObj need_clear 0 {need staff inspection}"

        $itk_component(prepare) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $itk_component(run) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $itk_component(end) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"

        if {$m_supportBarcode} {
            $itk_component(prepare) addInput \
            "$m_statusObj in_barcode_setup 0 {not valid in barcode manual mode}"
            $itk_component(prepare) addInput \
            "$m_statusObj in_barcode_read 0 {not valid in barcode read mode}"

            $itk_component(run) addInput \
            "$m_statusObj in_barcode_setup 0 {not valid in barcode manual mode}"
            $itk_component(run) addInput \
            "$m_statusObj in_barcode_read 0 {not valid in barcode read mode}"

            $itk_component(end) addInput \
            "$m_statusObj in_barcode_setup 0 {not valid in barcode manual mode}"
            $itk_component(end) addInput \
            "$m_statusObj in_barcode_read 0 {not valid in barcode read mode}"
        }
        eval itk_initialize $args

        pack $itk_component(prepare) -side top -anchor w
        pack $itk_component(run) -side top -anchor w
        pack $itk_component(end) -side top -anchor w
    }

    destructor {
    }
}

class RobotCalibrationWidget {
    inherit RobotBaseWidget

    public method start { operation }

    private variable m_ButtonList {}
    private variable m_objStrTS

    constructor { args } {
        eval RobotBaseWidget::constructor $args
    } {
        set stringObj [$m_deviceFactory createString robot_cal_config]
        set m_objStrTS [$m_deviceFactory createString ts_robot_cal]

        $stringObj createAttributeFromField auto 0
        $stringObj createAttributeFromField magnet 1
        $stringObj createAttributeFromField cassette 2
        $stringObj createAttributeFromField goniometer 3
        $stringObj createAttributeFromField find_mag 4
        $stringObj createAttributeFromField quick 5
        $stringObj createAttributeFromField lcst 6
        $stringObj createAttributeFromField mcst 7
        $stringObj createAttributeFromField rcst 8

        $m_objStrTS createAttributeFromField toolset 0
        $m_objStrTS createAttributeFromField left 1
        $m_objStrTS createAttributeFromField middle 2
        $m_objStrTS createAttributeFromField right 3
        $m_objStrTS createAttributeFromField gonio 4
        $m_objStrTS createAttributeFromField align 5
        $m_objStrTS createAttributeFromField alignII 6
        $m_objStrTS createAttributeFromField barcode 7

        itk_component add sf {
            iwidgets::scrolledframe $itk_interior.sf \
            -vscrollmode static
        } {
        }
        set ring [$itk_component(sf) childsite]

        #compose command site
        itk_component add detailed_msg {
            DCS::Checkbox $ring.detail \
            -itemList {"display detailed message" 0} \
            -stringName robot_attribute
        } {
            keep -systemIdleOnly
        }

        #full toolset calibration
        itk_component add mag_full {
            DCS::Button $ring.full_mag \
            -text "Toolset" \
            -command "$this start FullToolset"
        } {
            keep -systemIdleOnly
        }
        lappend m_ButtonList mag_full

        itk_component add cas_do {
            DCS::Button $ring.cas_do     \
            -text "Cassette" \
            -command "$this start calibrateCassette"
        } {
            keep -systemIdleOnly
        }
        lappend m_ButtonList cas_do
        itk_component add cas_cfg {
            DCS::Checkbox $ring.cas_cfg \
            -orient horizontal \
            -itemList [list l 6 m 7 r 8] \
            -stringName robot_cal_config
        } {
            keep -systemIdleOnly
        }
        lappend m_ButtonList cas_cfg

        itk_component add gonio_do {
            DCS::Button $ring.gonio_do     \
            -text "Goniometer" \
            -command "$this start calibrateGoniometer"
        } {
            #keep -systemIdleOnly
            #this one we want to disable during any run
        }
        itk_component add gonio_manual {
            iwidgets::Labeledframe $ring.fr_gonio_manual \
            -labelpos nw \
            -labeltext "manual gonio calibration"
        } {
        }
        set frame_manual [$itk_component(gonio_manual) childsite ]
	    pack propagate $frame_manual 1

        itk_component add gonio_move {
            DCS::Button $frame_manual.move     \
            -text "Move To Standby" \
            -width 22 \
            -command "$this start moveToGoniometer"
        } {
        }
        itk_component add gonio_save {
            DCS::Button $frame_manual.save     \
            -text "Save Current Position" \
            -background red \
            -width 22 \
            -command "$this start teachGoniometer"
        } {
        }
        itk_component add gonio_home {
            DCS::Button $frame_manual.home     \
            -text "Go Home" \
            -width 22 \
            -command "$this start moveHome"
        } {
        }

        pack $itk_component(gonio_move) -side top -anchor w
        pack $itk_component(gonio_save) -side top -anchor w
        pack $itk_component(gonio_home) -side top -anchor w

        lappend m_ButtonList gonio_do gonio_move gonio_save gonio_home

        itk_component add bt_do {
            DCS::HotButton $ring.bt_do     \
            -text "Alignment Pin A" \
            -confirmText "Confirm Pin REMOVED" \
            -width 20 \
            -command "$this start calibrateBeamLineTool"
        } {
        }

        ###################################################
        itk_component add bt_manual {
            iwidgets::Labeledframe $ring.fr_bt_manual \
            -labelpos nw \
            -labeltext "manual calibration"
        } {
        }
        set frame_btmanual [$itk_component(bt_manual) childsite ]
	    pack propagate $frame_btmanual 1

        itk_component add bt_move {
            DCS::Button $frame_btmanual.move     \
            -text "Move To Standby" \
            -width 22 \
            -command "$this start moveToBeamlineTool"
        } {
        }
        itk_component add bt_save {
            DCS::Button $frame_btmanual.save     \
            -text "Save Current Position" \
            -background red \
            -width 22 \
            -command "$this start teachBeamlineTool"
        } {
        }
        itk_component add bt_home {
            DCS::Button $frame_btmanual.home     \
            -text "Go Home" \
            -width 22 \
            -command "$this start jumpHome"
        } {
        }
        pack $itk_component(bt_move) -side top -anchor w
        pack $itk_component(bt_save) -side top -anchor w
        pack $itk_component(bt_home) -side top -anchor w

        lappend m_ButtonList bt_do bt_move bt_save bt_home

        itk_component add btII_do {
            DCS::HotButton $ring.btII_do     \
            -text "Alignment Pin B" \
            -confirmText "Confirm Pin REMOVED" \
            -width 20 \
            -command "$this start calibrateBeamLineToolII"
        } {
        }

        ###################################################
        itk_component add btII_manual {
            iwidgets::Labeledframe $ring.fr_btII_manual \
            -labelpos nw \
            -labeltext "manual calibration"
        } {
        }
        set frame_btIImanual [$itk_component(btII_manual) childsite ]
	    pack propagate $frame_btIImanual 1

        itk_component add btII_move {
            DCS::Button $frame_btIImanual.move     \
            -text "Move To Standby" \
            -width 22 \
            -command "$this start moveToBeamlineToolII"
        } {
        }
        itk_component add btII_save {
            DCS::Button $frame_btIImanual.save     \
            -text "Save Current Position" \
            -background red \
            -width 22 \
            -command "$this start teachBeamlineToolII"
        } {
        }
        itk_component add btII_home {
            DCS::Button $frame_btIImanual.home     \
            -text "Go Home" \
            -width 22 \
            -command "$this start jumpHome"
        } {
        }
        pack $itk_component(btII_move) -side top -anchor w
        pack $itk_component(btII_save) -side top -anchor w
        pack $itk_component(btII_home) -side top -anchor w

        lappend m_ButtonList btII_do btII_move btII_save btII_home

        ###################################################
        itk_component add bc_manual {
            iwidgets::Labeledframe $ring.fr_barcode \
            -labelpos nw \
            -labeltext "barcode position setup"
        } {
        }
        set frame_barcode [$itk_component(bc_manual) childsite ]
	    pack propagate $frame_barcode 1

        itk_component add bc_move {
            DCS::Button $frame_barcode.move     \
            -text "Move To Barcode Reader" \
            -width 22 \
            -command "$this start moveToBarcodeReader"
        } {
        }
        itk_component add bc_save {
            DCS::Button $frame_barcode.save     \
            -text "Save Current Position" \
            -background red \
            -width 22 \
            -command "$this start teachBarcodeReader"
        } {
        }
        itk_component add bc_home {
            DCS::Button $frame_barcode.home     \
            -text "Go Home" \
            -width 22 \
            -command "$this start moveHome"
        } {
        }

        pack $itk_component(bc_move) -side top -anchor w
        pack $itk_component(bc_save) -side top -anchor w
        pack $itk_component(bc_home) -side top -anchor w

        lappend m_ButtonList bc_move bc_save bc_home

        itk_component add cal_msg {
            DCS::Label $itk_interior.calmsg \
            -component $m_statusObj -attribute cal_msg -promptText "cal msg: "
        } {
        }

        #compose progress bar
        itk_component add feedback {
            DCS::Feedback $itk_interior.fb \
            -height 40 \
            -steps 100 \
            -component $m_statusObj -attribute cal_step
        } {
        }

        itk_component add ts_toolset {
            DCS::Label $ring.ts_toolset \
            -component $m_objStrTS \
            -attribute toolset \
            -promptWidth 10 \
            -promptAnchor w \
            -promptText "TS toolset:"
        } {
        }

        itk_component add ts_cassetteF {
            frame $ring.ts_cassette_frame
        } {
        }

        itk_component add ts_left_cassette {
            DCS::Label $itk_component(ts_cassetteF).ts_left \
            -component $m_objStrTS \
            -attribute left \
            -promptWidth 10 \
            -promptAnchor w \
            -promptText "TS left:"
        } {
        }

        itk_component add ts_middle_cassette {
            DCS::Label $itk_component(ts_cassetteF).ts_middle \
            -component $m_objStrTS \
            -attribute middle \
            -promptWidth 10 \
            -promptAnchor w \
            -promptText "TS middle:"
        } {
        }

        itk_component add ts_right_cassette {
            DCS::Label $itk_component(ts_cassetteF).ts_right \
            -component $m_objStrTS \
            -attribute right \
            -promptWidth 10 \
            -promptAnchor w \
            -promptText "TS right:"
        } {
        }
        grid $itk_component(ts_left_cassette)   -column 0 -row 0 -sticky w
        grid $itk_component(ts_middle_cassette) -column 0 -row 1 -sticky w
        grid $itk_component(ts_right_cassette)  -column 0 -row 2 -sticky w

        itk_component add ts_goniometer {
            DCS::Label $ring.ts_gonio \
            -component $m_objStrTS \
            -attribute gonio \
            -promptWidth 10 \
            -promptAnchor w \
            -promptText "TS Gonio:"
        } {
        }

        itk_component add ts_alignmentPin {
            DCS::Label $ring.ts_align \
            -component $m_objStrTS \
            -attribute align \
            -promptWidth 10 \
            -promptAnchor w \
            -promptText "TS Align A:"
        } {
        }

        itk_component add ts_alignmentPinII {
            DCS::Label $ring.ts_alignII \
            -component $m_objStrTS \
            -attribute alignII \
            -promptWidth 10 \
            -promptAnchor w \
            -promptText "TS Align B:"
        } {
        }

        itk_component add ts_barcode {
            DCS::Label $ring.ts_barcode \
            -component $m_objStrTS \
            -attribute barcode \
            -promptWidth 10 \
            -promptAnchor w \
            -promptText "TS Barcode:"
        } {
        }

        itk_component add oneFrame {
            frame $ring.oneFrame
        } {
        }
        itk_component add oneButton {
            DCS::Button $itk_component(oneFrame).do \
            -text "Calibrations" \
            -command "$this start oneCalibrate"
        } {
            keep -systemIdleOnly
        }
        itk_component add oneConfig {
            DCS::Checkbox $itk_component(oneFrame).cfg \
            -orient horizontal \
            -itemList [list toolset 1 cassette 2 gonio 3] \
            -stringName robot_cal_config
        } {
            keep -systemIdleOnly
        }
        lappend m_ButtonList oneButton oneConfig
        pack $itk_component(oneButton) -side left
        pack $itk_component(oneConfig) -side left

        eval itk_initialize $args

        registerAllButtons $m_ButtonList
        foreach buttonComponent $m_ButtonList {
            $itk_component($buttonComponent) addInput \
            "$m_opISample permission GRANTED {PERMISSION}"
            $itk_component($buttonComponent) addInput \
            "$m_opISample status inactive {supporting device}"

            switch -exact -- $buttonComponent {
                gonio_save -
                gonio_home {
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj in_manual 1 {only valid after Move To Gonio Standby}"
                }
                btII_save -
                btII_home {
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj in_tool 1 {only valid after Move To Alignment Pin Standby}"
                    $itk_component($buttonComponent) addInput \
                    "$m_stateObj OKForPinB 1 {only valid for Alignment Pin B}"
                }
                bt_save -
                bt_home {
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj in_tool 1 {only valid after Move To Alignment Pin Standby}"
                    $itk_component($buttonComponent) addInput \
                    "$m_stateObj OKForPinA 1 {only valid for Alignment Pin A}"
                }
                bc_save -
                bc_home {
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj in_barcode_setup 1 {only valid after Move To barcode reader}"
                }
                default {
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj in_manual 0 {not valid in manual mode}"
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj in_tool 0 {not valid in manual mode}"
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj need_reset 0 {do reset first}"
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj need_clear 0 {need staff inspection}"
                    if {$m_supportBarcode} {
                        $itk_component($buttonComponent) addInput \
                        "$m_statusObj in_barcode_setup 0 {not valid in manual mode}"
                        $itk_component($buttonComponent) addInput \
                        "$m_statusObj in_barcode_read 0 {not valid in barcode read mode}"
                    }
                }
            }
            switch -exact -- $buttonComponent {
                cas_do {
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj need_mag_cal 0 {do toolset calibration first}"
                }
                gonio_move -
                gonio_do {
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj need_cas_cal 0 {do cassette calibration first}"
                    $itk_component($buttonComponent) addInput \
                    "$m_statusObj need_mag_cal 0 {do toolset calibration first}"
                }
            }
        }

        grid $itk_component(detailed_msg)   -column 0 -row 0 -sticky w \
        -columnspan 3
        grid $itk_component(mag_full)       -column 0 -row 1 -sticky w
        grid $itk_component(cas_do)         -column 0 -row 2 -sticky w
        grid $itk_component(gonio_do)       -column 0 -row 3 -sticky w
        grid $itk_component(bt_do)          -column 0 -row 4 -sticky w
        grid $itk_component(btII_do)        -column 0 -row 5 -sticky w
        #####

        grid $itk_component(cas_cfg)        -column 1 -row 2 -sticky w
        grid $itk_component(gonio_manual)   -column 1 -row 3 -sticky w
        grid $itk_component(bt_manual)      -column 1 -row 4 -sticky w
        grid $itk_component(btII_manual)    -column 1 -row 5 -sticky w
        grid $itk_component(bc_manual)      -column 1 -row 6 -sticky w

        grid $itk_component(oneFrame)           -column 2 -row 0 -sticky w
        grid $itk_component(ts_toolset)         -column 2 -row 1 -sticky w
        grid $itk_component(ts_cassetteF)       -column 2 -row 2 -sticky w
        grid $itk_component(ts_goniometer)      -column 2 -row 3 -sticky w
        grid $itk_component(ts_alignmentPin)    -column 2 -row 4 -sticky w
        grid $itk_component(ts_alignmentPinII)  -column 2 -row 5 -sticky w
        grid $itk_component(ts_barcode)         -column 2 -row 6 -sticky w

        grid columnconfigure $ring 2 -weight 1

        grid $itk_component(sf)             -column 0 -row 0 -sticky news
        grid $itk_component(cal_msg)        -column 0 -row 6 -sticky w
        grid $itk_component(feedback)       -column 0 -row 7 -sticky news

        grid rowconfigure $itk_interior    0 -weight 1
        grid columnconfigure $itk_interior 0 -weight 1

        #grid $itk_interior -sticky news
    }


    destructor {
    }
}
body RobotCalibrationWidget::start { operation } {
    set strObj [$m_deviceFactory createString robot_cal_config]
    switch -exact -- $operation {
        FullToolset {
            set opID [eval $m_opISample startOperation calibrateMagnet 1 0]
        }
        calibrateMagnet {
            #generate arguments
            set fm [$strObj getFieldByIndex find_mag]
            set qk [$strObj getFieldByIndex quick]
            set opID [eval $m_opISample startOperation $operation $fm $qk]
        }
        calibrateCassette {
            set l [$strObj getFieldByIndex lcst]
            set m [$strObj getFieldByIndex mcst]
            set r [$strObj getFieldByIndex rcst]
            set cas ""
            if {$r} {
                set cas r
            } 
            if {$m} {
                if {$cas == ""} {
                    set cas m
                } else {
                    set cas m$cas
                }
            }
            if {$l} {
                if {$cas == ""} {
                    set cas l
                } else {
                    set cas l$cas
                }
            }
            puts "calibrate cassettes: $cas"
            if {$cas == ""} {
                error "must select at least one cassette"
            } else {
                set opID [eval $m_opISample \
                startOperation $operation $cas 0]
            }
        }
        calibrateGoniometer {
            set opID [eval $m_opISample startOperation $operation 0]
        }
        calibrateBeamLineTool {
            set opID [eval $m_opISample startOperation $operation 0 0]
        }
        calibrateBeamLineToolII {
            set opID [eval $m_opISample startOperation calibrateBeamLineTool 0 1]
        }
        oneCalibrate -
        moveToGoniometer -
        teachGoniometer -
        jumpHome -
        moveHome -
        moveToBarcodeReader -
        teachBarcodeReader {
            set opID [eval $m_opISample startOperation $operation]
        }
        moveToBeamlineTool -
        teachBeamlineTool {
            set opID [eval $m_opISample startOperation $operation 0]
        }
        moveToBeamlineToolII {
            set opID [eval $m_opISample startOperation moveToBeamlineTool 1]
        }
        teachBeamlineToolII {
            set opID [eval $m_opISample startOperation teachBeamlineTool 1]
        }
    }
}

class RobotProbeWidget {
    inherit RobotBaseWidget

    protected variable m_probeObj

    protected variable m_objScanIdConfig

    public method start_probe { } {
        set callSAM [::config getInt "robot.probeThroughSAM" 0]
        if {$callSAM} {
            if {$m_opISample == ""} return
            eval $m_opISample startOperation probe
        } else {
            if {$m_opRobotConfig == ""} return
            set content [$m_probeObj getContents]
            eval $m_opRobotConfig startOperation probe $content
        }
    }
    public method reset_all_cassette { } {
        if {$m_opRobotConfig == ""} return
        $m_opRobotConfig startOperation reset_cassette
    }
    public method open_lid { } {
        $m_opRobotConfig startOperation ll_open_lid
    }

    public method handleClick { index name }
    public method handleClickAll { value start end }

    public method handleRightClick { index state }
    public method handleRightClickAll { start length state }

    public method handleReset { cas }
    public method handleRestore { cas }
    public method handleScanId { cas }

    constructor { args } {
        eval RobotBaseWidget::constructor $args
    } {

        set m_probeObj [$m_deviceFactory createString robot_probe]
        set m_objScanIdConfig \
        [$m_deviceFactory createString scanId_config]

        $m_objScanIdConfig createAttributeFromField scanId_left   0
        $m_objScanIdConfig createAttributeFromField scanId_middle 1
        $m_objScanIdConfig createAttributeFromField scanId_right  2

        itk_component add upper {
            frame $itk_interior.upper
        } {
        }
        itk_component add lower {
            iwidgets::Labeledframe $itk_interior.lower \
            -labelpos nw \
            -labeltext "select cassettes and ports"
        } {
        }
        set lowerSite [$itk_component(lower) childsite]
	    pack propagate $lowerSite 1

        itk_component add start {
            DCS::Button $itk_component(upper).start \
            -text "probe" \
            -command "$this start_probe"
        } {
            keep -systemIdleOnly -activeClientOnly
        }

        itk_component add reset {
            DCS::Button $itk_component(upper).reset \
            -text "reset all to unknown" \
            -command "$this reset_all_cassette"
        } {
            keep -systemIdleOnly -activeClientOnly
        }
        registerAllButtons reset
        $itk_component(reset) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"

        itk_component add open_lid {
            DCS::Button $itk_component(upper).openLid \
            -text "open lid" \
            -command "$this open_lid"
        } {
            keep -systemIdleOnly -activeClientOnly
        }
        registerAllButtons open_lid
        $itk_component(open_lid) addInput \
        "$m_opISample permission GRANTED {PERMISSION}"

        pack $itk_component(start) -side left
        pack $itk_component(reset) -side left
        pack $itk_component(open_lid) -side left
        pack $itk_component(upper) -side top

        itk_component add nb_select {
            iwidgets::Tabnotebook $lowerSite.nb -tabpos n
        } {
        }

        foreach {dummy lL lM lR} $s_cassetteLabelList break
        set LeftSite [$itk_component(nb_select) add -label $lL]
        set MiddleSite [$itk_component(nb_select) add -label $lM]
        set RightSite [$itk_component(nb_select) add -label $lR]
        $itk_component(nb_select) view 0

        itk_component add left_cas {
            DCSCassetteView $LeftSite.cv \
            -purpose forProbe \
            -offset 0 \
            -forceString "robot_force_left" \
            -onReset "$this handleReset l" \
            -onRestore "$this handleRestore l" \
            -onScanId "$this handleScanId l" \
            -onClick "$this handleClick" \
            -onClickAll "$this handleClickAll" \
            -onRightClick "$this handleRightClick" \
            -onRightClickAll "$this handleRightClickAll"
        } {
            keep -systemIdleOnly -activeClientOnly
            keep -mdiHelper
        }
        set comReset [$itk_component(left_cas) component reset]
        $comReset  addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $comReset  addInput \
        "$m_opISample status inactive {supporting device}"

        set comRestore [$itk_component(left_cas) component restore]
        $comRestore  addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $comRestore  addInput \
        "$m_opISample status inactive {supporting device}"

        itk_component add middle_cas {
            DCSCassetteView $MiddleSite.cv \
            -purpose forProbe \
            -offset 97 \
            -forceString "robot_force_middle" \
            -onReset "$this handleReset m" \
            -onRestore "$this handleRestore m" \
            -onScanId "$this handleScanId m" \
            -onClick "$this handleClick" \
            -onClickAll "$this handleClickAll" \
            -onRightClick "$this handleRightClick" \
            -onRightClickAll "$this handleRightClickAll"
        } {
            keep -systemIdleOnly -activeClientOnly
            keep -mdiHelper
        }
        set comReset [$itk_component(middle_cas) component reset]
        $comReset  addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $comReset  addInput \
        "$m_opISample status inactive {supporting device}"

        set comRestore [$itk_component(middle_cas) component restore]
        $comRestore  addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $comRestore  addInput \
        "$m_opISample status inactive {supporting device}"

        itk_component add right_cas {
            DCSCassetteView $RightSite.cv \
            -purpose forProbe \
            -offset 194 \
            -forceString "robot_force_right" \
            -onReset "$this handleReset r" \
            -onRestore "$this handleRestore r" \
            -onScanId "$this handleScanId r" \
            -onClick "$this handleClick" \
            -onClickAll "$this handleClickAll" \
            -onRightClick "$this handleRightClick" \
            -onRightClickAll "$this handleRightClickAll"
        } {
            keep -systemIdleOnly -activeClientOnly
            keep -mdiHelper
        }
        set comReset [$itk_component(right_cas) component reset]
        $comReset  addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $comReset  addInput \
        "$m_opISample status inactive {supporting device}"

        set comRestore [$itk_component(right_cas) component restore]
        $comRestore  addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $comRestore  addInput \
        "$m_opISample status inactive {supporting device}"

        pack $itk_component(left_cas) -expand 1 -fill both -side left
        pack $itk_component(middle_cas) -expand 1 -fill both -side left
        pack $itk_component(right_cas) -expand 1 -fill both -side left

        pack $itk_component(nb_select) -expand 1 -fill both
        pack $itk_component(lower) -expand 1 -fill both

        registerAllButtons start
        $itk_component(start) addInput \
        "$m_opRobotConfig permission GRANTED {PERMISSION}"
        $itk_component(start) addInput \
        "$m_statusObj need_reset 0 {do reset first}"
        $itk_component(start) addInput \
        "$m_statusObj need_clear 0 {need staff inspection}"
        $itk_component(start) addInput \
        "$m_statusObj in_manual 0 {not valid in manual mode}"
        $itk_component(start) addInput \
        "$m_statusObj in_tool 0 {not valid in manual mode}"
        $itk_component(start) addInput \
        "$m_statusObj need_mag_cal 0 {do toolset calibration first}"
        $itk_component(start) addInput \
        "$m_statusObj need_cas_cal 0 {do cassette calibration first}"
        $itk_component(start) addInput \
        "$m_opISample status inactive {supporting device}"
        if {$m_supportBarcode} {
            $itk_component(start) addInput \
            "$m_statusObj in_barcode_setup 0 {not valid in manual mode}"
            $itk_component(start) addInput \
            "$m_statusObj in_barcode_read 0 {not valid in barcode read mode}"
        } else {
            $itk_component(left_cas)    hideScanId
            $itk_component(middle_cas)  hideScanId
            $itk_component(right_cas)   hideScanId
        }
    }
}
body RobotProbeWidget::handleClick { index name } {
    set old_contents [$m_probeObj getContents]
    set old_value [lindex $old_contents $index]

    ### flip
    if {$old_value} {
        set new_value 0
    } else {
        set new_value 1
    }
    set new_contents [lreplace $old_contents $index $index $new_value]
    $m_probeObj sendContentsToServer $new_contents
}
body RobotProbeWidget::handleClickAll { value start end } {
    set contents [$m_probeObj getContents]

    for {set i $start} {$i < $end} {incr i} {
        set contents [lreplace $contents $i $i $value]
    }

    $m_probeObj sendContentsToServer $contents

    if {!$m_supportBarcode} {
        return
    }
    if {$value != "0" && $value != "1"} {
        return
    }
    switch -exact -- $start {
        0 { set i 0 }
        97 { set i 1 }
        194 { set i 2 }
        default { return }
    }
    set oldContents [$m_objScanIdConfig getContents]
    set newContents [lreplace $oldContents $i $i $value]
    $m_objScanIdConfig sendContentsToServer $newContents
}
body RobotProbeWidget::handleRightClick { index state } {
    eval $m_opRobotConfig startOperation set_index_state $index 1 $state
}
body RobotProbeWidget::handleRightClickAll { start length state } {
    eval $m_opRobotConfig startOperation set_index_state $start $length $state
}
body RobotProbeWidget::handleReset { cas } {
    eval $m_opRobotConfig startOperation set_port_state ${cas}X0 u
}
body RobotProbeWidget::handleRestore { cas } {
    eval $m_opRobotConfig startOperation restore_cassette $cas
}


body RobotProbeWidget::handleScanId { cas } {
    puts "handleScanId $cas"
    switch -exact -- $cas {
        l { set i 0 }
        m { set i 1 }
        r { set i 2 }
        default { return }
    }

    set oldContents [$m_objScanIdConfig getContents]
    set oldV [lindex $oldContents $i]
    if {$oldV == "1"} {
        set newV 0
    } else {
        set newV 1
    }
    set newContents [lreplace $oldContents $i $i $newV]
    $m_objScanIdConfig sendContentsToServer $newContents
}
class RobotIOWidget {
    inherit RobotBaseWidget

    #options
    private variable m_inputObj ""
    private variable m_outputObj ""

    private variable m_bgColor
    private variable m_onColor #00a040

    #contructor/destructor

    private variable m_inputLabelList {"LN2 Valve Closed" \
                                       "LN2 Level Normal" \
                                       "LN2 AutoFill OFF" \
                                       "in3" \
                                       "in4" \
                                       "in5" \
                                       "in6" \
                                       "in7" \
                                       "Gripper Opened" \
                                       "Gripper Closed" \
                                       "in10" \
                                       "Lid Closed" \
                                       "Lid Opened" \
                                       "Heater Hot" \
                                       "in14" \
                                       "in15"}

    private variable m_outputLabelList {"out0" \
                                        "Close Gripper" \
                                        "out2" \
                                        "Open Lid" \
                                        "out4" \
                                        "out5" \
                                        "out6" \
                                        "out7" \
                                        "out8" \
                                        "out9" \
                                        "out10" \
                                        "out11" \
                                        "out12" \
                                        "Dry Air" \
                                        "Heater" \
                                        "out15"}


    public method handleStringInputEvent
    public method handleStringOutputEvent

    public method handleOutputClick { index } {
        $m_opRobotConfig startOperation hw_output_switch $index

        #if {$index == 3 && [$itk_component(out_v$index) cget -text] == ""} {
        #    $m_opRobotConfig startOperation ll_open_lid
        #} else {
        #    $m_opRobotConfig startOperation hw_output_switch $index
        #}
    }

    constructor { args  } {
        eval RobotBaseWidget::constructor $args
    } {
        global gIsDeveloper

        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_inputObj [$m_deviceFactory createString robot_input]
        set m_outputObj [$m_deviceFactory createString robot_output]

        itk_component add ring {
            frame $itk_interior.r
        } {
            keep -width -height
        }

        itk_component add input_label {
            label $itk_component(ring).input_label -text "INPUT"
        } {
        }
        itk_component add output_label {
            label $itk_component(ring).output_label -text "OUTPUT"
        } {
        }
        itk_component add space {
            label $itk_component(ring).space -text "         "
        } {
        }

        set m_bgColor [$itk_component(input_label) cget -background]

        grid $itk_component(input_label) -row 0 -column 0 -sticky e
        grid $itk_component(output_label) -row 0 -column 4 -sticky w
        grid $itk_component(space) -row 0 -column 2

        for {set i 0} {$i < 16} {incr i} {
            itk_component add in_l$i {
                label $itk_component(ring).il$i \
                -text [lindex $m_inputLabelList $i] \
                -anchor e
            } {
            }
            itk_component add in_v$i {
                label $itk_component(ring).iv$i \
                -text " " \
                -width 1 \
                -anchor w
            } {
            }
                itk_component add out_v$i {
                    DCS::Button $itk_component(ring).ov$i \
                    -disabledforeground blue \
                    -text " " \
                    -width 1 \
                    -padx 0 \
                    -pady 0 \
                    -command "$m_opRobotConfig startOperation hw_output_switch $i" \
                    -foreground blue

                } {
                    keep -systemIdleOnly
                }
                registerAllButtons out_v$i
                $itk_component(out_v$i) addInput \
                "$m_opRobotConfig permission GRANTED {PERMISSION}"
            itk_component add out_l$i {
                label $itk_component(ring).ol$i \
                -text [lindex $m_outputLabelList $i] \
                -anchor w
            } {
            }

            set row [expr "$i + 1"]

            grid $itk_component(in_l$i) -row $row -column 0 -sticky e
            grid $itk_component(in_v$i) -row $row -column 1 -sticky w
            grid $itk_component(out_v$i) -row $row -column 3 -sticky e
            grid $itk_component(out_l$i) -row $row -column 4 -sticky w
        }

        pack $itk_component(ring) -expand 1 -fill both
        pack $itk_interior -expand 1 -fill both

        $m_inputObj register $this contents handleStringInputEvent
        $m_outputObj register $this contents handleStringOutputEvent

        eval itk_initialize $args
    }

    destructor {
        $m_inputObj unregister $this contents handleStringInputEvent
        $m_outputObj unregister $this contents handleStringOutputEvent
    }
}

body RobotIOWidget::handleStringInputEvent { stringName_ targetReady_ alias_ contents_ - } {
    #puts "handle string content $contents_"
    if { ! $targetReady_} return

    for {set i 0} {$i < 16} {incr i} {
        set value [lindex $contents_ $i]
        if {$value == ""} {
            set value 0
        }
        set on_color $m_onColor
        if {$i == 2} {
            set on_color red
        }
        if {$value} {
            $itk_component(in_v$i) config \
            -background $on_color
        } else {
            $itk_component(in_v$i) config \
            -background $m_bgColor
        }
    }
}
body RobotIOWidget::handleStringOutputEvent { stringName_ targetReady_ alias_ contents_ - } {
    #puts "handle string content $contents_"
    if { ! $targetReady_} return

    for {set i 0} {$i < 16} {incr i} {
        set value [lindex $contents_ $i]
        if {$value == ""} {
            set value 0
        }
        if {$value} {
            $itk_component(out_v$i) config \
            -text "#"
        } else {
            $itk_component(out_v$i) config \
            -text " "
        }
    }
}

class RobotMountWidget {
    inherit RobotBaseWidget

    protected variable red #c04080
    protected variable m_cassetteObj
    protected variable m_strCassetteOwner

    protected variable m_cassetteStatusLeft u
    protected variable m_cassetteStatusMiddle u
    protected variable m_cassetteStatusRight u
    protected variable m_cntsCassetteOwner "{} {} {} {}"

    protected variable m_leftIndex    -1
    protected variable m_middleIndex  -1
    protected variable m_rightIndex   -1

    protected method refreshIndex { } {
        set index 0
        if {$m_leftIndex >=0} {
            set m_leftIndex $index
            incr index
        }
        if {$m_middleIndex >=0} {
            set m_middleIndex $index
            incr index
        }
        if {$m_rightIndex >=0} {
            set m_rightIndex $index
            incr index
        }

        puts "new index: $m_leftIndex $m_middleIndex $m_rightIndex"

        $itk_component(nb_select) select 0
    }

    protected method updateLeftLabel { } {
        if {$m_cassetteStatusLeft != "-"} {
            if {$m_leftIndex < 0} {
                addLeftCassette
                refreshIndex
            }

            set casLabel [lindex $s_cassetteLabelList 1]

            set newLabel "${casLabel}($m_cassetteStatusLeft)"
            set owner [lindex $m_cntsCassetteOwner 1]
            if {$owner != ""} {
                if {[llength $owner] > 1} {
                    append newLabel " [lindex $owner 0]..."
                } else {
                    append newLabel " $owner"
                }
            }
            $itk_component(nb_select) pageconfigure $m_leftIndex \
            -label $newLabel
        } else {
            if {$m_leftIndex >= 0} {
                $itk_component(nb_select) delete $m_leftIndex
                set m_leftIndex -1
                refreshIndex
            }
        }
    }
    protected method updateMiddleLabel { } {
        if {$m_cassetteStatusMiddle != "-"} {
            if {$m_middleIndex < 0} {
                addMiddleCassette
                refreshIndex
            }

            set casLabel [lindex $s_cassetteLabelList 2]
            set newLabel "${casLabel}($m_cassetteStatusMiddle)"
            set owner [lindex $m_cntsCassetteOwner 2]
            if {$owner != ""} {
                if {[llength $owner] > 1} {
                    append newLabel " [lindex $owner 0]..."
                } else {
                    append newLabel " $owner"
                }
            }
            $itk_component(nb_select) pageconfigure $m_middleIndex \
            -label $newLabel
        } else {
            if {$m_middleIndex >= 0} {
                $itk_component(nb_select) delete $m_middleIndex
                set m_middleIndex -1
                refreshIndex
            }
        }
    }
    protected method updateRightLabel { } {
        if {$m_cassetteStatusRight != "-"} {
            if {$m_rightIndex < 0} {
                addRightCassette
                refreshIndex
            }

            set casLabel [lindex $s_cassetteLabelList 3]
            set newLabel "${casLabel}($m_cassetteStatusRight)"
            set owner [lindex $m_cntsCassetteOwner 3]
            if {$owner != ""} {
                if {[llength $owner] > 1} {
                    append newLabel " [lindex $owner 0]..."
                } else {
                    append newLabel " $owner"
                }
            }
            $itk_component(nb_select) pageconfigure $m_rightIndex \
            -label $newLabel
        } else {
            if {$m_rightIndex >= 0} {
                $itk_component(nb_select) delete $m_rightIndex
                set m_rightIndex -1
                refreshIndex
            }
        }
    }

    public method setValue { index value } {
        set status_list [$m_cassetteObj getContents]
        set port_status [lindex $status_list $index]
        switch -exact -- $port_status {
            1 -
            u {
                ####OK
            }
            - {
                log_error $value port not exist
                return
            }
            0 {
                log_error $value empty port
                return
            }
            j {
                log_error $value port jam
                return
            }
            m {
                log_error $value mounted
                return
            }
            default {
                log_error $value bad port
                return
            }
        }

        $itk_component(mount) setValue $value
    }

    public method handleLeftCassetteStatusChange
    public method handleMiddleCassetteStatusChange
    public method handleRightCassetteStatusChange

    public method handleCassettePermitsChange

    private method addLeftCassette { } {
        set leftLabel [lindex $s_cassetteLabelList 1]
        set end [$itk_component(nb_select) index end]
        if {$end < 0} {
            set LeftSite [$itk_component(nb_select) add -label $leftLabel]
        } else {
            set LeftSite [$itk_component(nb_select) insert 0 -label $leftLabel]
        }
        itk_component add left_cas {
            DCSCassetteView $LeftSite.cv \
            -purpose forMount \
            -offset 0\
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -onClick "$this setValue"
        } {
            keep -systemIdleOnly
        }
        pack $itk_component(left_cas) -expand 1 -fill both
        set m_leftIndex 0
    }
    private method addMiddleCassette { } {
        set middleLabel [lindex $s_cassetteLabelList 2]
        if {$m_rightIndex < 0} {
            set MiddleSite [$itk_component(nb_select) add -label $middleLabel]
            set m_middleIndex [$itk_component(nb_select) index end]
        } else {
            set MiddleSite \
            [$itk_component(nb_select) insert $m_rightIndex -label $middleLabel]
            set m_middleIndex $m_rightIndex
        }
        itk_component add middle_cas {
            DCSCassetteView $MiddleSite.cv \
            -purpose forMount \
            -offset 97 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -onClick "$this setValue"
        } {
            keep -systemIdleOnly
        }
        pack $itk_component(middle_cas) -expand 1 -fill both
    }
    private method addRightCassette { } {
        set rightLabel [lindex $s_cassetteLabelList 2]
        set RightSite [$itk_component(nb_select) add -label $rightLabel]
        itk_component add right_cas {
            DCSCassetteView $RightSite.cv \
            -purpose forMount \
            -offset 194 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -onClick "$this setValue"
        } {
            keep -systemIdleOnly
        }
        pack $itk_component(right_cas) -expand 1 -fill both
        set m_rightIndex [$itk_component(nb_select) index end]
    }

    constructor { args } {
        eval RobotBaseWidget::constructor $args
    } {
        set m_cassetteObj [$m_deviceFactory createString robot_cassette]
        $m_cassetteObj createAttributeFromField left_status 0
        $m_cassetteObj createAttributeFromField middle_status 97
        $m_cassetteObj createAttributeFromField right_status 194

        set m_strCassetteOwner [$m_deviceFactory createCassetteOwnerString cassette_owner]

        itk_component add upper {
            frame $itk_interior.upper
        } {
        }
        set lowerSite $itk_interior


        itk_component add mount {
            SimpleRobotWidget $itk_component(upper).mount \
            -orientation long \
            -activeClientOnly 1 \
            -systemIdleOnly 1
        } {
        }
        #$itk_component(mount) configure -width 40

        pack $itk_component(mount) -expand 1 -fill both
        pack $itk_component(upper) -expand 1 -fill both

        itk_component add nb_select {
            iwidgets::Tabnotebook $lowerSite.nb \
            -tabbackground gray75 \
            -tabpos n \
            -padx 0 \
            -pady 1 \
            -margin 0

        } {
        }
        addLeftCassette
        addMiddleCassette
        addRightCassette
        $itk_component(nb_select) view 0

        grid $itk_component(nb_select) -row 3 -column 0 -columnspan 3 -sticky news -in [$itk_component(mount) getSite]
        eval itk_initialize $args

        $m_cassetteObj register $this left_status handleLeftCassetteStatusChange
        $m_cassetteObj register $this middle_status handleMiddleCassetteStatusChange
        $m_cassetteObj register $this right_status handleRightCassetteStatusChange

        $m_strCassetteOwner register $this permits handleCassettePermitsChange
    }
    destructor {
        $m_cassetteObj unregister $this left_status handleLeftCassetteStatusChange
        $m_cassetteObj unregister $this middle_status handleMiddleCassetteStatusChange
        $m_cassetteObj unregister $this right_status handleRightCassetteStatusChange
        $m_strCassetteOwner unregister $this permits handleCassettePermitsChange
    }
}
body RobotMountWidget::handleLeftCassetteStatusChange { stringName_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    set m_cassetteStatusLeft $contents_
    updateLeftLabel
}
body RobotMountWidget::handleMiddleCassetteStatusChange { stringName_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    set m_cassetteStatusMiddle $contents_
    updateMiddleLabel
}
body RobotMountWidget::handleRightCassetteStatusChange { stringName_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    set m_cassetteStatusRight $contents_
    updateRightLabel
}
body RobotMountWidget::handleCassettePermitsChange { - ready_ - contents_ - } {
    if {!$ready_} return

    set m_cntsCassetteOwner [$m_strCassetteOwner getContents]

    set first_permit -1
    set needChangePage 0
    set current [$itk_component(nb_select) index select]

    if {$m_leftIndex >= 0} {
        if {[lindex $contents_ 1] == "1"} {
            pack $itk_component(left_cas) -expand 1 -fill both
            set stateL normal
            if {$first_permit == -1} {
                set first_permit $m_leftIndex
            }
        } else {
            pack forget $itk_component(left_cas)
            set stateL disabled
            if {$current == $m_leftIndex} {
                set needChangePage 1
            }
        }
        $itk_component(nb_select) pageconfigure $m_leftIndex -state $stateL
    }
    if {$m_middleIndex >= 0} {
        if {[lindex $contents_ 2] == "1"} {
            pack $itk_component(middle_cas) -expand 1 -fill both
            set stateM normal
            if {$first_permit == -1} {
                set first_permit $m_middleIndex
            }
        } else {
            pack forget $itk_component(middle_cas)
            set stateM disabled
            if {$current == $m_middleIndex} {
                set needChangePage 1
            }
        }
        $itk_component(nb_select) pageconfigure $m_middleIndex -state $stateM
    }
    if {$m_rightIndex >= 0} {
        if {[lindex $contents_ 3] == "1"} {
            pack $itk_component(right_cas) -expand 1 -fill both
            set stateR normal
            if {$first_permit == -1} {
                set first_permit $m_rightIndex
            }
        } else {
            pack forget $itk_component(right_cas)
            set stateR disabled
            if {$current == $m_rightIndex} {
                set needChangePage 1
            }
        }
        $itk_component(nb_select) pageconfigure $m_rightIndex -state $stateR
    }

    updateLeftLabel
    updateMiddleLabel
    updateRightLabel


    if {!$needChangePage} return

    if {$first_permit >=0} {
        $itk_component(nb_select) select $first_permit
        return
    }
    #### we can hide everything or
    $itk_component(nb_select) select 0
}

class ForceView {
    inherit ::itk::Widget

    itk_option define -statusString statusString StatusString ""
    itk_option define -offset offset Offset 0
    itk_option define -showCassette showCassette ShowCassette 0

    protected variable m_deviceFactory
    protected variable m_currentStatusString ""

    protected variable m_origBackground
    protected variable m_origForeground

    private method unregisterLastStatus
    private method registerNewStatus

    protected method setPortColor { port_num }

    public method handleStringStatusEvent

    #need override
    public method handleClick { button_name } { }

    #contructor/destructor
    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        #puts "ForceView constructor"
        #GUI building
        itk_component add body {
            frame $itk_interior.body
        } {
            keep -background
        }

        itk_component add note {
            label $itk_interior.note \
            -text "port jam threshold: 9"
        } {
        }

        #puts "adding header"
        #head
        itk_component add cas_label {
            label $itk_interior.cas_l -text "cassette top: " 
        } {
            keep -background
            keep -padx -pady
        }

        itk_component add b0 {
            label $itk_interior.b0 \
            -relief groove \
            -width 6 \
            -text ""
        } {
            keep -padx -pady
        }

        set m_origBackground [$itk_component(b0) cget -background]
        set m_origForeground [$itk_component(b0) cget -foreground]

        #body
        foreach rowHead {1 2 3 4 5 6 7 8} {
            itk_component add rh$rowHead {
                label $itk_component(body).rh$rowHead -text "$rowHead"
            } {
                keep -background
                keep -padx -pady
            }
        }

        #puts "adding column head"
        foreach columnHead {A B C D E F G H I J K L} {
            itk_component add ch$columnHead {
                label $itk_component(body).ch$columnHead -text "$columnHead"
            } {
                keep -background
                keep -padx -pady
            }
        }


        #puts "adding port"
        for {set p_index 1} {$p_index <= 96} {incr p_index} {
            itk_component add b$p_index {
                label $itk_component(body).b$p_index \
                -width 4 \
                -relief groove \
                -text "$p_index"
            } {
                keep -padx -pady
            }
        }

        eval itk_initialize $args

        #puts "packing columnhead"
        grid x \
        $itk_component(chA) $itk_component(chB) $itk_component(chC) \
        $itk_component(chD) $itk_component(chE) $itk_component(chF) \
        $itk_component(chG) $itk_component(chH) $itk_component(chI) \
        $itk_component(chJ) $itk_component(chK) $itk_component(chL)

        #puts "packing rowshead"
        for {set i 1} {$i <= 8} {incr i} {
            grid $itk_component(rh$i) -row $i -column 0
        }

        #puts "packing ports"
        for {set p_index 1} {$p_index <= 96} {incr p_index} {
            set row [expr "($p_index - 1) % 8 + 1"]
            set column [expr "int(($p_index - 1) / 8) + 1"]
            grid $itk_component(b$p_index) -row $row -column $column
        }

        #puts "packing frames"
        if {$itk_option(-showCassette)} {
            grid $itk_component(cas_label)  -row 0 -column 0 -sticky e
            grid $itk_component(b0)         -row 0 -column 1 -sticky w
        }
        grid $itk_component(note)       -row 1 -column 0 -columnspan 2
        grid $itk_component(body)       -row 2 -column 0 -columnspan 2 -stick news
    }

    destructor {
        unregisterLastStatus
    }
}
configbody ForceView::statusString {
    set newString $itk_option(-statusString)

    if {$newString != $m_currentStatusString} {
        unregisterLastStatus
        registerNewStatus
    }
}

body ForceView::setPortColor { port_num } {
    set pb $itk_component(b$port_num)
    set value [$pb cget -text]

    if {[string is double -strict $value] && abs( $value) > 9} {
        set bg red
    } elseif {$value == "BBBB"} {
        set bg red
    } else {
        set bg $m_origBackground
    }
    $pb configure \
    -background $bg
}
body ForceView::unregisterLastStatus { } {
    if {$m_currentStatusString == "" } return

    set statusObj [$m_deviceFactory createString $m_currentStatusString]
    
    $statusObj unregister $this contents handleStringStatusEvent
    
    set m_currentStatusString ""
}

body ForceView::registerNewStatus { } {
    set newStatusString $itk_option(-statusString)

    if {$newStatusString == ""} return

    set statusObj [$m_deviceFactory createString $newStatusString]
    
    $statusObj register $this contents handleStringStatusEvent
    
    set m_currentStatusString $newStatusString
}

body ForceView::handleStringStatusEvent { stringName_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    set ll [llength $contents_]

    set offset $itk_option(-offset)

    for {set i 0} {$i < 97} {incr i} {
        set index [expr "$i + $offset"]
        set value [lindex $contents_ $index]
        $itk_component(b$i) config -text "$value"
        setPortColor $i
    }
}

class PortJamUserActionWidget {
    inherit RobotBaseWidget 
    constructor { args } {
        #base class
        eval RobotBaseWidget::constructor $args
    } {
        itk_component add note1 {
            label $itk_interior.note1 \
            -font "helvetica -14 bold" \
            -text "\nAction Required: Sample Pin Return Error\n "
        } {
            keep -background
        }
        itk_component add note2 {
            label $itk_interior.note2 \
            -wraplength 300 \
            -justify left \
            -text "The sample pin may not have been returned into the cassette properly.  To ensure proper robot operation a stripping procedure needs to be performed.  Although your pin has most likely been returned into the cassette, this may result in the loss of your sample pin."
        } {
            keep -background
        }
        itk_component add note3 {
            label $itk_interior.note3 \
            -justify left \
            -anchor w \
            -text "\nStripped pins may not be retrieved.                     \n "
        } {
            keep -background
        }
        itk_component add note4 {
            label $itk_interior.note4 \
            -text "Would you like to proceed?"
        } {
            keep -background
        }

        itk_component add strip {
            DCS::Button $itk_interior.strip \
            -width 46 \
            -text "Yes - perform stripping operation to continue screening" \
            -command "$m_opISample startOperation portJamUserAction strip"
        } {
        }
        $itk_component(strip) addInput \
        "$m_opISample status inactive {supporting device}"

        itk_component add reset {
            DCS::Button $itk_interior.reset \
            -text "No - user-support staff must be contacted to continue" \
            -width 46 \
            -command "$m_opISample startOperation portJamUserAction reset"
        } {
        }
        $itk_component(reset) addInput \
        "$m_opISample status inactive {supporting device}"

        registerAllButtons [list strip reset]

        eval itk_initialize $args

        pack $itk_component(note1) -side top
        pack $itk_component(note2) -side top
        pack $itk_component(note3) -side top
        pack $itk_component(note4) -side top
        pack $itk_component(strip) -side top
        pack $itk_component(reset) -side top
    }
}
class SampleZAdjustWidget {
    inherit RobotBaseWidget 

    private method setValue { value } {
        set old_contents [$m_strTableSetup getContents]
        set ll [llength $old_contents]
        if {$ll < 5} {
            set num [expr 5 - $ll]
            for {set i 0} {$i < $num} {incr i} {
                lappend old_contents ""
            }
        }
        set new_contents [lreplace $old_contents 4 4 $value]
        $m_strTableSetup sendContentsToServer $new_contents
    }

    public method handleResize { winID width height } {
        if {$winID != $m_parent_id} return

        $itk_component(note1) config -wraplength $width
        $itk_component(note2) config -wraplength $width
        $itk_component(note3) config -wraplength $width
        $itk_component(note4) config -wraplength $width
    }

    public method reset { } {
        setValue 0.0
    }
    public method copy { } {
        set value [$m_objSampleZ getScaledPosition]
        set value [lindex $value 0]
        setValue $value
    }

    private variable m_strTableSetup
    private variable m_objSampleZ

    private variable m_parent_id

    constructor { args } {
        #base class
        eval RobotBaseWidget::constructor $args
    } {
        global BLC_IMAGES

        set m_strTableSetup [$m_deviceFactory createString table_setup]
        set m_objSampleZ [$m_deviceFactory getObjectName sample_z]

        itk_component add note1 {
            label $itk_interior.n1 \
            -font "helvetica -20 bold" \
            -text "default sample_z adjustment"
        } {
            keep -background
        }


        set    contents "The default position for sample_z after a pin "
        append contents "is mounted by SAM is 0.0 as shown in the figure "
        append contents "below in red."
        itk_component add note2 {
            label $itk_interior.n2 \
            -anchor w \
            -justify left \
            -font "helvetica -14 bold" \
            -text $contents \
            -wraplength 500
        } {
            keep -background
        }


        set photoName [image create photo pin_photo1 -file $BLC_IMAGES/pin.jpg]
        itk_component add pin_image {
            label $itk_interior.pin \
            -image pin_photo1
        } {
        }

        itk_component add pin_note {
            label $itk_interior.pin_note \
            -anchor c \
            -justify center \
            -font "helvetica -14 bold" \
            -text "Standard 18 mm Copper Magnetic Pin" \
            -wraplength 300
        } {
            keep -background
        }
        set    contents "For batches of pins longer or shorter than a standard "
        append contents "18mm Hampton pin, this sample_z setting may be "
        append contents "modified below.  (This will make loop auto-centering "
        append contents "faster for non-standard pin lengths.) To do this, "
        append contents "manually center the non-standard pin and click "
        append contents "\"save current sample_z\"."
        itk_component add note3 {
            label $itk_interior.n3 \
            -anchor w \
            -justify left \
            -font "helvetica -14 bold" \
            -text $contents \
            -wraplength 500
        } {
            keep -background
        }


        set    contents "To go back to the default setting \"reset to 0\" "
        append contents "in the box below or using the change-over-assistant "
        append contents "to restore the default settings."
        itk_component add note4 {
            label $itk_interior.n4 \
            -anchor w \
            -justify left \
            -font "helvetica -14 bold" \
            -text $contents \
            -wraplength 500
        } {
            keep -background
        }

        itk_component add copy {
            DCS::Button $itk_interior.copy \
            -background yellow \
            -width 22 \
            -text "save current sample_z" \
            -command "$this copy"
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        itk_component add value {
            DCS::Entryfield $itk_interior.value \
            -validate real \
            -fixed 5 \
            -width 6 \
            -labeltext "manually input      " \
            -labelpos e \
            -offset 4 \
            -stringName table_setup
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        itk_component add reset {
            DCS::Button $itk_interior.reset \
            -background #008000 \
            -width 22 \
            -text "reset to 0" \
            -command "$this reset"
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        pack $itk_component(note1) -side top
        pack $itk_component(note2) -side top -expand 1 -fill x -anchor w
        pack $itk_component(pin_image) -side top -expand 1 -fill x -anchor s
        pack $itk_component(pin_note) -side top -expand 1 -fill x -anchor n
        pack $itk_component(note3) -side top -expand 1 -fill x -anchor w
        pack $itk_component(note4) -side top -expand 1 -fill x -anchor w
        pack $itk_component(copy) -side top
        pack $itk_component(value) -side top
        pack $itk_component(reset) -side top
    
        eval itk_initialize $args

        ########## hook resize
        set m_parent_id $itk_interior
        bind $m_parent_id <Configure> "$this handleResize %W %w %h"
    }
}


#### string will be robot_attribute,
#### display robot_reheat_info
#### one check box mapped to sil_config.
class RobotFastModeWidget {
    inherit ::DCS::StringFieldViewBase

    public method setDisplayLabel { name value } {
        $itk_component($name) configure \
        -text $value

        switch -exact -- $name {
            td_reheat -
            td_reset {
                if {[string first overdue $value] >= 0} {
                    $itk_component($name) configure \
                    -background red
                } else {
                    $itk_component($name) configure \
                    -background #00a040
                }
            }
        }
    }
    public method setDisplayState { name s } {
        $itk_component($name) configure \
        -state $s

        ### add some special code upon change
    }

    public method setTopEnable { s } {
        set contents [$m_objSilConfig getContents]
        set newContents [setStringFieldWithPadding $contents 4 $s]
        $m_objSilConfig sendContentsToServer $newContents
    }

    public method refresh { } {
        $m_opRobotSoftSet startOperation sync_time_now [clock seconds]
    }

    public method goHome { } {
        $m_opRobotStandby startOperation
    }
    public method forceReheat { } {
        $m_opRobotStandby startOperation reheat_tong forced now=[clock seconds]
    }

    private variable m_deviceFactory ""
    private variable m_objSilConfig ""
    private variable m_objInfo ""

    private variable m_attributeDisplay ""

    private variable m_opRobotSoftSet ""
    private variable m_opRobotStandby ""

    constructor { args } {
        set m_entryList [list \
        spanReheat 14 \
        cntMax 15 \
        spanHeating 16 \
        spanHome 17 \
        ]

        set m_labelList [list \
        ti_spanReheat 14 \
        ti_spanHeating 16 \
        ti_spanHome 17 \
        ]

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objSilConfig  [$m_deviceFactory createString sil_config]
        $m_objSilConfig createAttributeFromField robot_fast_mode 4

        set m_objInfo  [$m_deviceFactory createString robot_reheat_info]
        $m_objInfo createAttributeFromKey standby

        set m_opRobotSoftSet [$m_deviceFactory createOperation robot_soft_set]
        set m_opRobotStandby [$m_deviceFactory createOperation robot_standby]

        set statusObj [$m_deviceFactory createString robot_status]
        $statusObj createAttributeFromField need_reset 3
        $statusObj createAttributeFromField robot_state 7
        $statusObj createAttributeFromField need_clear 27

        itk_component add fastEnable {
			DCS::Checkbutton $m_site.topEnable \
            -text "Enable LN2 Standby" \
            -command "$this setTopEnable %s" \
            -shadowReference 1 \
            -reference "$m_objSilConfig robot_fast_mode" \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
        } {
        }

        itk_component add statusFrame {
            iwidgets::Labeledframe $m_site.statusF \
            -labelpos nw \
            -labeltext "Status" \
        } {
        }
        set statusSite [$itk_component(statusFrame) childsite]
        itk_component add stateStandby {
            label $statusSite.standby \
            -text "In LN2 Standby" \
            -activebackground green \
        } {
        }
        itk_component add stateTimer {
            label $statusSite.timer \
            -text "Timer Running" \
            -activebackground green \
        } {
        }
        itk_component add stateReheating {
            label $statusSite.reheat \
            -text "Reheating Tongs" \
            -activebackground yellow \
        } {
        }
        grid $itk_component(stateStandby) $itk_component(stateTimer) \
        $itk_component(stateReheating) -sticky news

        itk_component add countFrame {
            iwidgets::Labeledframe $m_site.cntF \
            -labelpos nw \
            -labeltext "Sample Count Before Reheat Tongs" \
        } {
        }
        set cntSite [$itk_component(countFrame) childsite]

        label $cntSite.l0 -text "Max Count"
        label $cntSite.l1 -text "Current Count"
        label $cntSite.l2 -text "Remain Count"

        set cmd [list $this updateEntryColor cntMax 15 %P]
        itk_component add cntMax {
            entry $cntSite.max \
            -justify right \
            -width 6 \
            -background white \
            -validate all \
            -vcmd $cmd
        } {
        }

        itk_component add cntCur {
            label $cntSite.cur \
            -relief sunken \
            -width 6\
            -anchor e \
            -background #00a040 \
            -text cntCur
        } {
        }

        itk_component add cntRmn {
            label $cntSite.remain \
            -relief sunken \
            -width 6\
            -anchor e \
            -background #00a040 \
            -text cntCur
        } {
        }
        grid $cntSite.l0 $cntSite.l1 $cntSite.l2 -sticky news
        grid $itk_component(cntMax) $itk_component(cntCur) $itk_component(cntRmn) -sticky news

        itk_component add spanFrame {
            iwidgets::Labeledframe $m_site.spanF \
            -labelpos nw \
            -labeltext "Time Span (seconds)" \
        } {
        }
        set spanSite [$itk_component(spanFrame) childsite]
        label $spanSite.l0 -text "Reheat Tong"
        label $spanSite.l1 -text "Go Home"
        label $spanSite.l2 -text "Reset"
        label $spanSite.l3 -text "Heating"

        set cmd [list $this updateEntryColor spanReheat 14 %P]
        itk_component add spanReheat {
            entry $spanSite.reheat \
            -justify right \
            -width 8 \
            -background white \
            -validate all \
            -vcmd $cmd
        } {
        }

        itk_component add ti_spanReheat {
            label $spanSite.txtReheat \
            -relief sunken \
            -width 8 \
            -anchor e \
            -background #00a040 \
            -text spanReheat
        } {
        }

        set cmd [list $this updateEntryColor spanHome 17 %P]
        itk_component add spanHome {
            entry $spanSite.home \
            -justify right \
            -width 8 \
            -background white \
            -validate all \
            -vcmd $cmd
        } {
        }

        itk_component add ti_spanHome {
            label $spanSite.txtHome \
            -relief sunken \
            -width 8 \
            -anchor e \
            -background #00a040 \
            -text spanHome
        } {
        }

        itk_component add spanReset {
            label $spanSite.reset \
            -relief sunken \
            -width 8 \
            -anchor e \
            -background tan \
            -text spanReset
        } {
        }

        itk_component add ti_spanReset {
            label $spanSite.txtReset \
            -relief sunken \
            -width 8 \
            -anchor e \
            -background #00a040 \
            -text spanReset
        } {
        }

        set cmd [list $this updateEntryColor spanHeating 15 %P]
        itk_component add spanHeating {
            entry $spanSite.heating \
            -justify right \
            -width 8 \
            -background white \
            -validate all \
            -vcmd $cmd
        } {
        }

        itk_component add ti_spanHeating {
            label $spanSite.txtHeating \
            -relief sunken \
            -width 8 \
            -anchor e \
            -background #00a040 \
            -text spanHeating
        } {
        }

        grid $spanSite.l0 $spanSite.l1 $spanSite.l2 $spanSite.l3
        grid $itk_component(spanReheat) $itk_component(spanHome) \
        $itk_component(spanReset) $itk_component(spanHeating) -sticky news

        grid $itk_component(ti_spanReheat) $itk_component(ti_spanHome) \
        $itk_component(ti_spanReset) $itk_component(ti_spanHeating) -sticky news

        itk_component add lastFrame {
            iwidgets::Labeledframe $m_site.lastF \
            -labelpos nw \
            -labeltext "TimeStamp for Latest Action" \
        } {
        }
        set lastSite [$itk_component(lastFrame) childsite]
        label $lastSite.l0 -text "Heat Tong"
        label $lastSite.l1 -text "Go in LN2"
        label $lastSite.l2 -text "System Idle"
        itk_component add ts_lastHeat {
            label $lastSite.heat \
            -relief sunken \
            -width 17 \
            -anchor e \
            -background #00a040 \
            -text lastheat
        } {
        }

        itk_component add ts_lastInLN2 {
            label $lastSite.ln2 \
            -relief sunken \
            -width 17 \
            -anchor e \
            -background #00a040 \
            -text lastinln2
        } {
        }

        itk_component add ts_lastIdle {
            label $lastSite.idle \
            -relief sunken \
            -width 17 \
            -anchor e \
            -background #00a040 \
            -text lastIdle
        } {
        }

        grid $lastSite.l0 $lastSite.l1 $lastSite.l2 -sticky news

        grid $itk_component(ts_lastHeat) \
        $itk_component(ts_lastInLN2) \
        $itk_component(ts_lastIdle) \
        -sticky news

        itk_component add triggerFrame {
            iwidgets::Labeledframe $m_site.triggerF \
            -labelpos nw \
            -labeltext "Trigger Time" \
        } {
        }
        set triggerSite [$itk_component(triggerFrame) childsite]

        label $triggerSite.l0 -text "Reheat"
        label $triggerSite.l1 -text "Go Home"
        label $triggerSite.l2 -text "Reset"
        label $triggerSite.l3 -text "Time"
        label $triggerSite.l4 -text "Remain"

        itk_component add ts_triggerReheat {
            label $triggerSite.trgReheat \
            -relief sunken \
            -width 17 \
            -anchor e \
            -background #00a040 \
            -text nextHeat
        } {
        }

        itk_component add ts_triggerHome {
            label $triggerSite.trgHome \
            -relief sunken \
            -width 17 \
            -anchor e \
            -background #00a040 \
            -text nextHome
        } {
        }

        itk_component add ts_triggerReset {
            label $triggerSite.trgReset \
            -relief sunken \
            -width 17 \
            -anchor e \
            -background #00a040 \
            -text nextReset
        } {
        }

        itk_component add td_reheat {
            label $triggerSite.tdReheat \
            -relief sunken \
            -width 17 \
            -anchor e \
            -background #00a040 \
            -text reheatLeft
        } {
        }

        itk_component add td_home {
            label $triggerSite.tdHome \
            -relief sunken \
            -width 17 \
            -anchor e \
            -background #00a040 \
            -text homeLeft
        } {
        }

        itk_component add td_reset {
            label $triggerSite.tdReset \
            -relief sunken \
            -width 17 \
            -anchor e \
            -background #00a040 \
            -text resetLeft
        } {
        }

        itk_component add bReheat {
            ::DCS::Button $triggerSite.bReheat \
            -systemIdleOnly 0 \
            -text "Force Reheat" \
            -width 12 \
            -command "$this forceReheat" \
        } {
        }

        itk_component add bGoHome {
            ::DCS::Button $triggerSite.bGoHome \
            -systemIdleOnly 0 \
            -text "Go Home" \
            -width 12 \
            -command "$this goHome" \
        } {
        }

        itk_component add bRefresh {
            button $triggerSite.bRefresh \
            -background #00a040 \
            -text "Refresh" \
            -command "$this refresh" \
        } {
        }

        grid $itk_component(bRefresh) \
        $triggerSite.l0 $triggerSite.l1 $triggerSite.l2 -sticky news

        grid $triggerSite.l3 \
        $itk_component(ts_triggerReheat) \
        $itk_component(ts_triggerHome) \
        $itk_component(ts_triggerReset) -sticky ews

        grid x $itk_component(bReheat) \
        $itk_component(bGoHome)

        grid $triggerSite.l4 $itk_component(td_reheat) $itk_component(td_home) \
        $itk_component(td_reset) -sticky news


        ############## TOP level #############
        grid $itk_component(fastEnable) -sticky w
        grid $itk_component(statusFrame) -sticky w
        grid $itk_component(countFrame) -sticky w
        grid $itk_component(spanFrame) -sticky w
        grid $itk_component(lastFrame) -sticky w
        grid $itk_component(triggerFrame) -sticky w


        set displayLabelList [list \
        spanReset           reset_span \
        ti_spanReset        reset_span \
        ts_lastHeat         tm_heat \
        ts_lastInLN2        tm_ln2 \
        ts_lastIdle         tm_idle \
        ts_triggerReheat    trigger_reheat \
        ts_triggerHome      trigger_go_home \
        ts_triggerReset     trigger_reset \
        td_reheat           reheat_time_left \
        td_home             go_home_time_left \
        td_reset            reset_time_left \
        cntRmn              sample_count_left \
        cntCur              sample_count \
        ]

        set displayStateList [list \
        stateStandby    standby \
        stateTimer      timer \
        stateReheating  reheat \
        ]

        set m_attributeDisplay [DCS::StringDictDisplayBase ::\#auto $this]
        $m_attributeDisplay setLabelList $displayLabelList
        $m_attributeDisplay setStateList $displayStateList

        $m_attributeDisplay configure -stringName $m_objInfo

        foreach bb {bReheat bGoHome} {
            $itk_component($bb) addInput \
            "$m_objInfo standby 1 {Only When Robot Standby in LN2}"

            $itk_component($bb) addInput \
            "$statusObj robot_state idle {supporting device}"

            $itk_component($bb) addInput \
            "$statusObj need_reset 0 {need reset}"

            $itk_component($bb) addInput \
            "$statusObj need_clear 0 {need staff inspection}"
        }

        eval itk_initialize $args
		announceExist

        configure \
        -systemIdleOnly 0 \
        -activeClientOnly 0 \
        -stringName ::device::robot_attribute
    }
    destructor {
        delete object $m_attributeDisplay
    }
}


RobotBaseWidget::initCassetteLabelList
