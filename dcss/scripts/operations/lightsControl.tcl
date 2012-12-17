#
#
#                        Copyright 2003
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
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

proc lightsControl_initialize {} {
    global gLightsControlAvailable
    ### -1 means not checked yet
    set gLightsControlAvailable -1

    namespace eval ::lightsControl {
        set BACK_LIGHT_BOARD -1
        set BACK_LIGHT_CHANNEL -1
        set SIDE_LIGHT_BOARD -1
        set SIDE_LIGHT_CHANNEL -1
        set INLINE_LIGHT_BOARD -1
        set INLINE_LIGHT_CHANNEL -1

        set cfgBackLight [::config getStr light.back]
        if {[llength $cfgBackLight] == 2} {
            foreach {BACK_LIGHT_BOARD BACK_LIGHT_CHANNEL} \
            $cfgBackLight break
            puts "backlight: $cfgBackLight"
        } else {
            puts "WARNING: cannot light.back in config file"
        }
        set cfgSideLight [::config getStr light.side]
        if {[llength $cfgSideLight] == 2} {
            foreach {SIDE_LIGHT_BOARD SIDE_LIGHT_CHANNEL} \
            $cfgSideLight break
            puts "sidelight: $cfgSideLight"
        } else {
            puts "cannot light.side in config file"
        }

        set cfgInlineLight [::config getStr light.inline_dim]
        if {[llength $cfgInlineLight] >= 2} {
            foreach {INLINE_LIGHT_BOARD INLINE_LIGHT_CHANNEL} \
            $cfgInlineLight break
        }

        set inlineMotor aoDaq$INLINE_LIGHT_BOARD$INLINE_LIGHT_CHANNEL

        ###### save restore
        set INLINE_ON_VALUE 5.0
        set savedBack 0
        set savedSide 5
        set savedInline $INLINE_ON_VALUE
        set savedHutch on

	}
}
proc lightsControl_start { cmd args } {
    switch -exact -- $cmd {
        check_availability {
            if {![lightsControl_checkAvailable]} {
                send_operation_update light control not available
                return
            }
            if {[lightsControl_backLightAvailable]} {
                send_operation_update back light control available
            }
            if {[lightsControl_sideLightAvailable]} {
                send_operation_update side light control available
            }
            if {[lightsControl_inlineLightAvailable]} {
                send_operation_update inline light control available
            }
            if {[lightsControl_hutchLightAvailable]} {
                send_operation_update hutch light control available
            }
        }
        list_restore {
            variable ::lightsControl::savedBack
            variable ::lightsControl::savedSide
            variable ::lightsControl::savedInline
                send_operation_update saved: $savedBack $savedSide $savedInline
        }
        setup {
            foreach {arg1 arg2} $args break
            if {$arg1 == "sample_tip"} {
                return [eval lightsControl_setupForSampleTip $arg2]
            } elseif {$arg1 == "inline_tip"} {
                return [eval lightsControl_setupForInlineTip $arg2]
            } elseif {$arg1 == "inline_insert"} {
                return [eval lightsControl_setupForInlineInsert insert $arg2]
            } elseif {$arg1 == "inline_remove"} {
                return [eval lightsControl_setupForInlineInsert remove $arg2]
            } elseif {$arg1 == "visex"} {
                return [eval lightsControl_setupForVisex $arg2]
            } else {
                return [eval lightsControl_setup $args]
            }
        }
        save {
            lightsControl_saveForRestore
        }
        restore {
            lightsControl_restore
        }
        back_light {
            ### no save current
            return [lightsControl_turnBackLight $args]
        }
        side_light {
            ### no save current
            return [lightsControl_turnSideLight $args]
        }
        inline_light {
            ### no save current
            return [lightsControl_turnInlineLight $args]
        }
        hutch_light {
            return [lightsControl_turnHutchLight $args]
        }
    }
}
proc lightsControl_checkAvailable { } {
    global gOperation

    set available 1

    if {![info exists gOperation(setDigOut,hardwareHost)]} {
        puts "light control not avaialble: setDigOut"
        set available 0
    }
    if {![info exists gOperation(setAnalogOut,hardwareHost)]} {
        puts "light control not avaialble: setAnalogOut"
        set available 0
    }

    return $available
}
proc lightsControl_available { } {
    global gLightsControlAvailable

    if {$gLightsControlAvailable < 0} {
        set gLightsControlAvailable [lightsControl_checkAvailable]
    }

    return $gLightsControlAvailable
}
proc lightsControl_backLightAvailable { } {
    variable ::lightsControl::BACK_LIGHT_BOARD
    variable ::lightsControl::BACK_LIGHT_CHANNEL
    variable digitalOutStatus$BACK_LIGHT_BOARD

    if {![lightsControl_available]} {
        return 0
    }

    if {$BACK_LIGHT_BOARD < 0 || $BACK_LIGHT_CHANNEL < 0} {
        return 0
    }

    if {![isString digitalOutStatus$BACK_LIGHT_BOARD]} {
        return 0
    }

    return 1
}
proc lightsControl_sideLightAvailable { } {
    variable ::lightsControl::SIDE_LIGHT_BOARD
    variable ::lightsControl::SIDE_LIGHT_CHANNEL
    variable analogOutStatus$SIDE_LIGHT_BOARD

    if {![lightsControl_available]} {
        return 0
    }

    if {$SIDE_LIGHT_BOARD < 0 || $SIDE_LIGHT_CHANNEL} {
        return 0
    }

    if {![isString analogOutStatus$SIDE_LIGHT_BOARD]} {
        return 0
    }

    return 1
}

proc lightsControl_inlineLightAvailable { } {
    variable ::lightsControl::INLINE_LIGHT_BOARD
    variable ::lightsControl::INLINE_LIGHT_CHANNEL
    variable analogOutStatus$INLINE_LIGHT_BOARD

    if {![lightsControl_available]} {
        return 0
    }

    if {$INLINE_LIGHT_BOARD < 0 || $INLINE_LIGHT_CHANNEL < 0} {
        return 0
    }

    if {![isString analogOutStatus$INLINE_LIGHT_BOARD]} {
        return 0
    }

    return 1
}
proc lightsControl_hutchLightAvailable { } {
    return [isString hutch_lights]
}
proc lightsControl_restore { } {
    variable ::lightsControl::savedBack
    variable ::lightsControl::savedSide
    variable ::lightsControl::savedInline
    variable ::lightsControl::savedHutch

    puts "lights restore"
    if {[lightsControl_backLightAvailable]} {
        puts "restore back light to $savedBack"
        __lightsControl_backLight $savedBack
    }
    if {[lightsControl_sideLightAvailable]} {
        puts "restore side light to $savedSide"
        __lightsControl_sideLight $savedSide
    }

    ### no need for restoring inline light
    ### it may do more harm than good.
    ### it is controlled by insert/remove.
    #if {[lightsControl_inlineLightAvailable]} {
    #    __lightsControl_inlineLight $savedInline
    #}
    if {[lightsControl_hutchLightAvailable]} {
        puts "restore side light to $savedSide"
        __lightsControl_hutchLight $savedHutch
    }
}

proc lightsControl_saveForRestore { } {
    if {[lightsControl_backLightAvailable]} {
        set currentOn [__lightsControl_isBackLightOn]
        __lightsControl_save Back 1 $currentOn
    }
    if {[lightsControl_sideLightAvailable]} {
        set currentValue [__lightsControl_getSideLightValue]
        __lightsControl_save Side 1 $currentValue
    }
    if {[lightsControl_inlineLightAvailable]} {
        set currentValue [__lightsControl_getInlineLightValue]
        __lightsControl_save Inline 1 $currentValue
    }
    if {[lightsControl_hutchLightAvailable]} {
        set currentValue [__lightsControl_getHutchLightValue]
        __lightsControl_save Hutch 1 $currentValue
    }
}
proc lightsControl_turnBackLight { on {saveCurrent4restore 0} } {
    if {![lightsControl_backLightAvailable]} {
        ### no change
        return 0
    }

    set currentOn [__lightsControl_isBackLightOn]
    __lightsControl_save Back $saveCurrent4restore $currentOn

    __lightsControl_backLight $on

    if {$currentOn == $on} {
        return 0
    } else {
        return 1
    }
}

proc lightsControl_turnSideLight { value {saveCurrent4restore 0} } {
    if {![lightsControl_sideLightAvailable]} {
        ### no change
        return 0
    }

    set currentValue [__lightsControl_getSideLightValue]
    __lightsControl_save Side $saveCurrent4restore $currentValue

    __lightsControl_sideLight $value

    ### range 0-5
    if {abs($currentValue - $value) < 0.1} {
        return 0
    } else {
        return 1
    }
}

proc lightsControl_turnInlineLight { value {saveCurrent4restore 0} } {
    variable ::lightsControl::INLINE_ON_VALUE

    if {![lightsControl_inlineLightAvailable]} {
        ### no change
        return 0
    }

    if {$value == "on"} {
        variable ::lightsControl::inlineMotor
        foreach {lL uL} [getGoodLimits $inlineMotor] break
        set value $uL
        #set value $INLINE_ON_VALUE
    }

    set currentValue [__lightsControl_getInlineLightValue]
    __lightsControl_save Inline $saveCurrent4restore $currentValue

    __lightsControl_inlineLight $value

    ### range 0-5
    if {abs($currentValue - $value) < 0.1} {
        return 0
    } else {
        return 1
    }
}
proc lightsControl_turnHutchLight { value {saveCurrent4restore 0} } {
    if {![lightsControl_hutchLightAvailable]} {
        ### no change
        return 0
    }
    switch -exact -- $value {
        on -
        off {
        }
        default {
            return 0
        }
    }

    set currentValue [__lightsControl_getHutchLightValue]
    __lightsControl_save Hutch $saveCurrent4restore $currentValue

    __lightsControl_hutchLight $value
    set newValue [__lightsControl_getHutchLightValue]

    ### range 0-5
    if {$currentValue == $newValue} {
        return 0
    } else {
        return 1
    }
}
proc lightsControl_setup { back side inline hutch {saveCurrent 0} } {
    set anyChange 0
    if {[lightsControl_turnBackLight $back $saveCurrent]} {
        incr anyChange
    }
    if {[lightsControl_turnSideLight $side $saveCurrent]} {
        incr anyChange
    }
    if {[lightsControl_turnInlineLight $inline $saveCurrent]} {
        incr anyChange
    }
    if {[lightsControl_turnHutchLight $hutch $saveCurrent]} {
        incr anyChange
    }
    return $anyChange
}
proc lightsControl_setupForSampleTip { {saveCurrent 0} } {
    puts "lights setup for sample tip"
    return [lightsControl_setup 1 0.0 0.0 - $saveCurrent]
}
proc lightsControl_setupForInlineTip { {saveCurrent 0} } {
    variable ::lightsControl::INLINE_ON_VALUE
    puts "lights setup for inline tip"
    variable ::lightsControl::inlineMotor
    foreach {lL uL} [getGoodLimits $inlineMotor] break
    set value $uL
    return [lightsControl_setup 0 0.0 $value - $saveCurrent]
}
proc lightsControl_setupForInlineInsert { insert_or_remove {saveCurrent 0} } {
    variable ::lightsControl::INLINE_ON_VALUE

    if {$insert_or_remove == "insert"} {
        variable ::lightsControl::inlineMotor
        foreach {lL uL} [getGoodLimits $inlineMotor] break
        set value $uL
        lightsControl_turnInlineLight $value $saveCurrent
    } else {
        lightsControl_turnInlineLight 0 $saveCurrent
    }
}
proc lightsControl_setupForVisex { {saveCurrent 0} } {
    puts "lights setup for visex"
    return [lightsControl_setup 0 0.0 0.0 off $saveCurrent]
}

proc __lightsControl_save { light save value } {
    variable ::lightsControl::savedBack
    variable ::lightsControl::savedSide
    variable ::lightsControl::savedInline
    variable ::lightsControl::savedHutch

    if {$save} {
        set saved$light $value
    }
}
proc __lightsControl_isBackLightOn { } {
    variable ::lightsControl::BACK_LIGHT_BOARD
    variable ::lightsControl::BACK_LIGHT_CHANNEL
    variable digitalOutStatus$BACK_LIGHT_BOARD

    set doStatus  [set digitalOutStatus$BACK_LIGHT_BOARD]
    set backLight [lindex $doStatus $BACK_LIGHT_CHANNEL]

    ### backligh 0: on
    if {$backLight == 0} {
        return 1
    } else {
        return 0
    }
}
proc __lightsControl_backLight { on } {
    variable ::lightsControl::BACK_LIGHT_BOARD
    variable ::lightsControl::BACK_LIGHT_CHANNEL

    set mask [expr 1 << $BACK_LIGHT_CHANNEL]
    if {$on} {
        set value 0
    } else {
        set value $mask
    }
    set op_handle [start_waitable_operation setDigOut \
    $BACK_LIGHT_BOARD $value $mask]

    wait_for_operation_to_finish $op_handle
}

proc __lightsControl_getSideLightValue { } {
    variable ::lightsControl::SIDE_LIGHT_BOARD
    variable ::lightsControl::SIDE_LIGHT_CHANNEL
    variable analogOutStatus$SIDE_LIGHT_BOARD

    set aoStatus [set analogOutStatus$SIDE_LIGHT_BOARD]
    set sideLight [lindex $aoStatus $SIDE_LIGHT_CHANNEL]
    return $sideLight
}
proc __lightsControl_sideLight { value } {
    variable ::lightsControl::SIDE_LIGHT_BOARD
    variable ::lightsControl::SIDE_LIGHT_CHANNEL

    set op_handle [start_waitable_operation setAnalogOut \
    $SIDE_LIGHT_BOARD $SIDE_LIGHT_CHANNEL $value]

    wait_for_operation_to_finish $op_handle
}

proc __lightsControl_getInlineLightValue { } {
    variable ::lightsControl::INLINE_LIGHT_BOARD
    variable ::lightsControl::INLINE_LIGHT_CHANNEL
    variable analogOutStatus$INLINE_LIGHT_BOARD

    set aoStatus [set analogOutStatus$INLINE_LIGHT_BOARD]
    set inlineLight [lindex $aoStatus $INLINE_LIGHT_CHANNEL]
    return $inlineLight
}
proc __lightsControl_inlineLight { value } {
    variable ::lightsControl::INLINE_LIGHT_BOARD
    variable ::lightsControl::INLINE_LIGHT_CHANNEL

    set op_handle [start_waitable_operation setAnalogOut \
    $INLINE_LIGHT_BOARD $INLINE_LIGHT_CHANNEL $value]

    wait_for_operation_to_finish $op_handle
}
proc __lightsControl_getHutchLightValue { } {
    variable hutch_lights

    return [lindex $hutch_lights 0]
}
proc __lightsControl_hutchLight { value } {
    variable hutch_lights

    set hutch_lights $value
    wait_for_strings hutch_lights

    set rb [lindex $hutch_lights 0]
    if {$rb != $value} {
        set msg [lindex $hutch_lights 1]
        if {$msg != ""} {
            log_warning set hutch light to $value failed: $msg
        } else {
            log_warning restore hutch light to $value failed: $rb
        }
    }
}
