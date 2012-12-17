package provide BLUICECryojet 1.0

# load standard packages
package require Iwidgets
#package require BWidget 1.2.1

# load other DCS packages
package require DCSUtil
package require DCSComponent

package require DCSOperationManager
package require DCSLabel
package require DCSCheckbutton
package require DCSEntry
package require DCSRadiobox
package require DCSEntryfield
package require DCSDeviceFactory
package require DCSTitledFrame
class AnnealWidget {
    inherit ::itk::Widget

	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_deviceFactory
    private variable m_objOpAnneal
    private variable m_objStrAnnealConfig ""

    public method handleStart { } {
        set time [$itk_component(time) get]
        puts "time=$time"
        set time_seconds [eval ::units convertUnits $time s]
        puts "time in seconds $time_seconds"
        $m_objOpAnneal startOperation $time_seconds
    }
    public method handleConfigChange { name_ ready_ alias_ contents_ - }

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objOpAnneal [$m_deviceFactory createOperation cryojet_anneal]

        set ring $itk_interior

        itk_component add not_available {
            label $ring.not \
            -text "not available on this beamline"
        } {
        }

        itk_component add time {
            DCS::MenuEntry $ring.time\
            -showEntry 1 \
            -showArrow 1 \
            -showPrompt 1 \
            -promptText "Anneal Time" \
            -entryType float \
            -unitsList "s {-decimalPlaces 3}" \
            -units s \
            -menuChoices {0 1 2 3 4 5 6 7 8 9 10} \
            -autoConversion 1 \
	    -activeClientOnly 0 \
	    -systemIdleOnly 1
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        itk_component add start {
            DCS::HotButton $ring.start \
            -text "Start Sample Annealing" \
            -confirmText "Confirm may destroy sample" \
            -width 23 \
            -command "$this handleStart"
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

		itk_component add abort {
			::DCS::Button $ring.stop \
				 -text "Abort" \
				 -background \#ffaaaa \
				 -activebackground \#ffaaaa \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font -height -state
			keep -activeforeground -foreground -relief 
		}

        $itk_component(start) addInput \
        "$m_objOpAnneal permission GRANTED {PERMISSION}"
        $itk_component(start) addInput \
        "$m_objOpAnneal status inactive {supporting device}"

        grid $itk_component(not_available)

        eval itk_initialize $args
		$itk_component(abort) configure -command "$itk_option(-controlSystem) abort"

        if {[$m_deviceFactory stringExists anneal_config]} {
            set m_objStrAnnealConfig \
            [$m_deviceFactory getObjectName anneal_config]

            $m_objStrAnnealConfig register $this contents handleConfigChange
        }
    }

    destructor {
        if {$m_objStrAnnealConfig != ""} {
            $m_objStrAnnealConfig unregister $this contents handleConfigChange
        }
    }
}
body AnnealWidget::handleConfigChange { name_ ready_ alias_ contents_ - } {
    set available 1
    if {!$ready_} {
        set available 0
    } else {
        foreach value $contents_ {
            if {$value < 0} {
                set available 0
                break
            }
        }
    }
    if {![$m_deviceFactory motorExists sample_flow]} {
        set available 0
    }

    set all [grid slaves $itk_interior]
    if {[llength $all] > 0} {
        eval grid forget [grid slaves $itk_interior]
    }
    if {$available} {
        grid $itk_component(time) -row 0 -column 0 -sticky w
        grid $itk_component(start) -row 0 -column 1 -sticky w
        grid $itk_component(abort) -row 0 -column 2 -sticky w
    } else {
        grid $itk_component(not_available)
    }
}
class AnnealConfigWidget {
    inherit ::itk::Widget

	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    constructor { args } {

        set site $itk_interior

        itk_component add min_flow {
            DCS::Entryfield $site.min_flow \
            -validate real \
            -fixed 3 -width 12 \
            -labeltext "minimum flow after shut off" \
            -labelpos w \
            -offset 0 \
            -stringName anneal_config
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }
        itk_component add off_flow {
            DCS::Entryfield $site.off_flow \
            -validate real \
            -fixed 3 -width 12 \
            -labeltext "flow during shut off" \
            -labelpos w \
            -offset 1 \
            -stringName anneal_config
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }
        itk_component add prepare {
            DCS::Entryfield $site.prepare \
            -validate real \
            -fixed 4 -width 12 \
            -labeltext "prepare time (s)" \
            -labelpos w \
            -offset 2\
            -stringName anneal_config
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }
        itk_component add max_time {
            DCS::Entryfield $site.max_time \
            -validate integer \
            -fixed 2 -width 12 \
            -labeltext "max anneal time (s)" \
            -labelpos w \
            -offset 3 \
            -stringName anneal_config
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        #align
        iwidgets::Labeledwidget::alignlabels \
        [$itk_component(min_flow) getEntryfield] \
        [$itk_component(off_flow) getEntryfield] \
        [$itk_component(prepare) getEntryfield] \
        [$itk_component(max_time) getEntryfield]

        global gIsDeveloper
        if {$gIsDeveloper} {
            pack $itk_component(min_flow) -side top
            pack $itk_component(off_flow) -side top
            pack $itk_component(prepare) -side top
            pack $itk_component(max_time) -side top
        } else {
            #only pack these
            pack $itk_component(prepare) -side top
            pack $itk_component(max_time) -side top
        }
        eval itk_initialize $args
    }
}
class CryojetWidget {
    inherit ::itk::Widget
	 
	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_deviceFactory
    private variable m_objTempSetMotor
    private variable m_objSampleFlowMotor
	private variable m_objShieldFlowMotor
	private variable m_objControlShutter
	private variable m_objModeShutter
	private variable m_objRealTempMotor
	
    public method setDefaultValues { } {
        $itk_component(c_sample_flow) setValue 8.0
        $itk_component(c_shield_flow) setValue 4.0
        $itk_component(c_temp_setpoint) setValue 100.0
		$itk_component(temp_radio) setValue "open"
		[$itk_component(lock_console) component checkbutton] "select"
		$itk_component(temp_radio) updateTextColor
		$itk_component(lock_console) updateTextColor
    }

	public method applyChanges

	public method cancelChanges

    constructor { args } {

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objTempSetMotor [$m_deviceFactory createPseudoMotor temp_setpoint -baseUnits "K"]
        set m_objSampleFlowMotor [$m_deviceFactory createPseudoMotor sample_flow -baseUnits "L/min"]
		set m_objShieldFlowMotor [$m_deviceFactory createPseudoMotor shield_flow -baseUnits "L/min"]
		set m_objRealTempMotor [$m_deviceFactory createPseudoMotor temperature -baseUnits "K"]
		set m_objModeShutter [$m_deviceFactory createShutter cryojet_mode]
		set m_objControlShutter [$m_deviceFactory createShutter cryojet_control]

        set control_site $itk_interior
        set status_site $itk_interior

        itk_component add def_val_frame {
            frame $itk_interior.def_val_frame
        } {
        }
        set def_val_site $itk_component(def_val_frame)
        itk_component add def_value {
            DCS::Button $def_val_site.default_value \
            -width 20 \
            -text "Restore Default Settings" \
            -command "$this setDefaultValues"  \
            -activeClientOnly 1 \
            -systemIdleOnly 1
        } {
        }
        grid $itk_component(def_value) -row 0 -column 0 -sticky nsew
        
        itk_component add lock_console  {
			DCS::Checkbutton $control_site.lock_console \
			-state active \
			-text "Lock Console" \
			-activeClientOnly 1 \
			-systemIdleOnly 1 \
			-reference "$m_objControlShutter state" \
			-shadowReference true \
			-onvalue "closed" \
			-offvalue "open"
		} {
		}
		grid $itk_component(lock_console) -row 1 -column 0 -sticky w

		itk_component add temp_radio {
			DCS::Radiobox $control_site.rbox \
			-state active \
			-labeltext "Temperature Control" \
			-activeClientOnly true \
			-systemIdleOnly false \
			-reference "$m_objModeShutter state" \
			-shadowReference true \
			-stateList {"open" "closed"} \
			-buttonLabels {"As cold as possible" "Temperature setpoint:"}
		} {
		}
		set temp_control_site [[$itk_component(temp_radio) component rbox] childsite]

        itk_component add c_temp_setpoint {
            DCS::MotorViewEntry $temp_control_site.c_temp_setpoint \
            -promptText "" \
            -units "K" \
            -entryJustify right \
            -decimalPlaces 2 \
            -entryType float \
            -entryWidth 10 \
            -activeClientOnly 1 \
            -systemIdleOnly  1 \
            -reference "$m_objTempSetMotor scaledPosition" \
            -shadowReference 1
        } {
        }


        itk_component add c_sample_flow {
            DCS::TitledMotorEntry $control_site.c_sample_flow \
            -labelText "Sample Flow" \
            -unitsList L/min  \
            -decimalPlaces 2 \
            -unitsWidth 4 \
            -entryWidth 10 \
            -systemIdleOnly 1 \
            -activeClientOnly 1
        } {
            keep -honorStatus -mdiHelper
        }
        itk_component add c_shield_flow {
            DCS::TitledMotorEntry $control_site.c_shield_flow \
            -labelText "Shield Flow" \
            -unitsList L/min \
            -unitsWidth 4 \
            -entryWidth 10 \
            -decimalPlaces 2 \
            -activeClientOnly 1 \
            -systemIdleOnly 1
        } {
            keep -honorStatus -mdiHelper
        }

		set status_background #00a040
		set status_foreground black
        itk_component add realTemp_frame {
            DCS::TitledFrame $status_site.realTemp_frame \
            -labelText "Jet Temperature"
        } {
        }
        set real_temp_site [$itk_component(realTemp_frame) childsite]
		itk_component add s_temp_real {
			DCS::MotorLabel $real_temp_site.s_temp_real \
			-component $m_objRealTempMotor \
			-attribute scaledPosition \
            -formatString "%.2f" \
			-background $status_background \
			-foreground $status_foreground \
			-width 14 \
			-anchor center
		} {
		}

		itk_component add apply {
			DCS::Button $itk_interior.apply \
			-text "Apply" \
			-command "$this applyChanges" \
			-activeClientOnly true \
			-systemIdleOnly 1
		} {
			keep -font -state -activeforeground -foreground -relief
		}

		itk_component add cancel {
			DCS::Button $itk_interior.cancel \
			-text "Cancel" \
			-command "$this cancelChanges" \
			-activeClientOnly false \
			-systemIdleOnly  false \
		} {
			keep -font -state
			keep -activeforeground -foreground -relief
		}
        $itk_component(c_temp_setpoint) configure \
            -device [$m_deviceFactory getObjectName temp_setpoint]

        $itk_component(c_sample_flow) configure \
            -device [$m_deviceFactory getObjectName sample_flow]

        $itk_component(c_shield_flow) configure \
            -device [$m_deviceFactory getObjectName shield_flow]

		$itk_component(c_temp_setpoint) addInput "::$itk_component(temp_radio) -value closed {Must select temperature setpoint}"
        
		
		pack $itk_component(s_temp_real) -side bottom -fill both 

        grid $itk_component(def_val_frame) -row 0 -column 0 -columnspan 1 -sticky nsew
        grid $itk_component(temp_radio) -row 3 -column 0 -sticky nsew

        # grids within the radiobox
        grid $itk_component(c_temp_setpoint) -row 1 -column 1 -sticky w

        grid $itk_component(c_sample_flow) -row 4 -column 0 -sticky nsew
        grid $itk_component(c_shield_flow) -row 5 -column 0 -sticky nsew
        grid $itk_component(realTemp_frame) -row 2 -column 0 -sticky nsew
		grid $itk_component(apply) -row 6 -column 0 -sticky nw
		grid $itk_component(cancel) -row 6 -column 0 -sticky ne

        eval itk_initialize $args
   }

    destructor {
    }
}

body CryojetWidget::applyChanges {} {
	$itk_component(c_sample_flow) moveToValue
	$itk_component(c_shield_flow) moveToValue
	$itk_component(c_temp_setpoint) moveToValue

	set tempRadioState [$itk_component(temp_radio) get]
	if { $tempRadioState != [$m_objModeShutter cget -state]} {
		$m_objModeShutter toggle
	}
	set controlState [$itk_component(lock_console) get]
	if { $controlState != [$m_objControlShutter cget -state]} {
		$m_objControlShutter toggle
	}
}
body CryojetWidget::cancelChanges {} {

	$itk_component(c_sample_flow) cancelChanges
	$itk_component(c_shield_flow) cancelChanges
	$itk_component(c_temp_setpoint) cancelChanges

	set tempRadioState [$itk_component(temp_radio) get]
	if { $tempRadioState != [$m_objModeShutter cget -state] } {
		$itk_component(temp_radio) setValue [$m_objModeShutter cget -state]
	}
	set controlState [$itk_component(lock_console) get]
	if { $controlState != [$m_objControlShutter cget -state]} {
		[$itk_component(lock_console) component checkbutton] toggle
		$itk_component(lock_console) updateTextColor
	}
}

class BlockAnnealWidget {
    inherit ::itk::Widget

	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_deviceFactory
    private variable m_objOpCryoBlock
    private variable m_objOpDO
    private variable m_objStrCryoBlockConst

    public method handleStart { } {
        set time [$itk_component(time) get]
        puts "time=$time"
        set time_seconds [eval ::units convertUnits $time s]
        puts "time in seconds $time_seconds"
        $m_objOpCryoBlock startOperation $time_seconds
    }
    public method handleForcedOpen { } {
        $m_objOpDO startOperation 0 0 1
    }

    public method handleConfigChange { name_ ready_ alias_ contents_ - }

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objOpCryoBlock [$m_deviceFactory createOperation cryoBlock]
        set m_objOpDO [$m_deviceFactory createOperation setDigOut]
        set m_objStrCryoBlockConst [$m_deviceFactory createString cryo_block_constant]

        set ring $itk_interior

        itk_component add not_available {
            label $ring.not \
            -text "not available on this beamline"
        } {
        }

        itk_component add time {
            DCS::MenuEntry $ring.time\
            -showEntry 1 \
            -showArrow 1 \
            -showPrompt 1 \
            -promptText "Block time" \
            -entryType float \
            -unitsList "s {-decimalPlaces 3}" \
            -units s \
            -menuChoices {0.05 0.5 1 1.5 2 2.5 3 3.5 4 4.5 5} \
            -autoConversion 1 \
	    -activeClientOnly 0 \
	    -systemIdleOnly 0
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
            keep -state
        }

        itk_component add start {
            DCS::HotButton $ring.start \
            -text "Start Sample Annealing" \
            -confirmText "Confirm may destroy sample" \
            -width 23 \
            -command "$this handleStart"
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
            keep -state
        }

		itk_component add abort {
			::DCS::Button $ring.stop \
				 -text "Abort" \
				 -background \#ffaaaa \
				 -activebackground \#ffaaaa \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font -height -state
			keep -activeforeground -foreground -relief 
		}
		itk_component add open {
			::DCS::Button $ring.open \
                 -command "$this handleForcedOpen" \
				 -text "Forced Open" \
				 -background \#ffaaaa \
				 -activebackground \#ffaaaa \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font -height -state
			keep -activeforeground -foreground -relief 
		}

        $itk_component(start) addInput \
        "$m_objOpCryoBlock permission GRANTED {PERMISSION}"
        $itk_component(start) addInput \
        "$m_objOpCryoBlock status inactive {supporting device}"

        eval itk_initialize $args
		$itk_component(abort) configure -command "$itk_option(-controlSystem) abort"

        $m_objStrCryoBlockConst register $this contents handleConfigChange
    }

    destructor {
        $m_objStrCryoBlockConst unregister $this contents handleConfigChange
    }
}
body BlockAnnealWidget::handleConfigChange { name_ ready_ alias_ contents_ - } {
    set available 1
    if {!$ready_} {
        set available 0
    } else {
        set max_time [lindex $contents_ 0]
        if {$max_time == "" || $max_time <= 0} {
            set available 0
        }
    }

    set all [grid slaves $itk_interior]
    if {[llength $all] > 0} {
        eval grid forget [grid slaves $itk_interior]
    }

    if {!$available} {
        puts "cryo block not available"
        grid $itk_component(not_available)
    } else {
        puts "cryo block available"
        grid $itk_component(time) -row 0 -column 0 -sticky w
        grid $itk_component(start) -row 0 -column 1 -sticky w
        grid $itk_component(abort) -row 0 -column 2 -sticky w
        #if abort not work, this button will not work either.
        #grid $itk_component(open) -row 0 -column 3 -sticky w
    }
}

