#this is menubutton+menu no DCS connection yet.
package provide DCSMenuButton 1.0  

package require Iwidgets
package require DCSLogger
package require DCSComponent
package require ComponentGateExtension
class DCS::MenuButton {
    inherit ::itk::Widget DCS::Component

    itk_option define -nullOK nullOK NullOK 0
    itk_option define -menuChoices menuChoices MenuChoices "" {
        repack
    }
    itk_option define -menuColumnBreak menuColumnBreak MenuColumnBreak 35 {
        repack
    }

    constructor { args } {
        DCS::Component::constructor {value getValue}
    } {
        itk_component add mb {
            menubutton $itk_interior.mb \
            -menu $itk_interior.mb.menu \
            -relief sunken \
            -background white
        } {
            keep -direction -state -width -foreground -background
        }

        itk_component add mn {
            menu $itk_interior.mb.menu \
            -postcommand "$this selectDefault" \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0
        } {
        }
        pack $itk_component(mb)
        eval itk_initialize $args

        announceExist
    }

    destructor {
    }

    private method repack { }

    public method setValue { value {direct 0} } {
        if {$itk_option(-nullOK)} {
            if {$value == "" || \
            [lsearch $itk_option(-menuChoices) $value] >= 0} {
                $itk_component(mb) configure -text $value
            } else {
                log_error \
                "bad value $value, only accept {$itk_option(-menuChoices)}"
                $itk_component(mb) configure -text ""
            }
        } else {
            if {[lsearch $itk_option(-menuChoices) $value] >= 0} {
                $itk_component(mb) configure -text $value
            } else {
                log_error \
                "bad value $value, only accept {$itk_option(-menuChoices)}"
            }
        }
        if {!$direct} {
            updateRegisteredComponents value
        }
    }
    public method getValue { } {
        return [$itk_component(mb) cget -text]
    }

    public method selectDefault { } {
        set current [getValue]
        if {$current != ""} {
            catch {$itk_component(mn) activate $current}
        }
    }
}
body DCS::MenuButton::repack { } {
    $itk_component(mn) delete 0 end

    set colBreak $itk_option(-menuColumnBreak)
    if {$colBreak <= 0} {
        set colBreak 35
    }

    set numChoice 0
    foreach choice $itk_option(-menuChoices) {
        $itk_component(mn) add command \
        -label $choice \
        -command "$this setValue $choice" \
        -hidemargin 1 \
        -columnbreak [expr ($numChoice % $colBreak) == 0]

        incr numChoice
    }
}

class DCS::DropdownMenu {
#    inherit ::itk::Widget ::DCS::ComponentGate
    inherit ::DCS::ComponentGateExtension
    itk_option define -state state State normal
    
    protected variable m_systemIdle
    public method removeAll { } {
        $itk_component(mn) delete 0 end
    }
    public method add { args } {
        eval $itk_component(mn) add $args
    }
    constructor { args } {
        itk_component add mb {
            menubutton $itk_interior.mb \
            -menu $itk_interior.mb.menu \
            -relief raised
        } {
			keep -text -font -width -height
            keep -activebackground -disabledforeground
			keep -activeforeground -background -foreground
			keep -padx -pady
            keep -state
        }

        itk_component add mn {
            menu $itk_interior.mb.menu \
            -tearoff 0
        } {
        }

		# create the arrow button
		itk_component add arrowButton {
			label $itk_interior.arrowButton	\
            -image [DCS::MenuEntry::getArrowImage] \
            -width 16 \
            -anchor c \
            -relief raised
		} {
		}

		if { [info tclversion] < 8.4 } {
			# bind menu posting to button click on the "fake" menu button
			bind $itk_component(arrowButton) <Button-1> \
				 "tkMbPost $itk_component(mb) %X %Y"
			bind $itk_component(arrowButton) <ButtonRelease-1> \
				 "tkMbButtonUp $itk_component(mb)"
		} else {
			# bind menu posting to button click on the "fake" menu button
			bind $itk_component(arrowButton) <Button-1> \
				 "tk::MbPost $itk_component(mb) %X %Y"
			bind $itk_component(arrowButton) <ButtonRelease-1> \
				 "tk::MbButtonUp $itk_component(mb)"
		}

        grid $itk_component(mb) -row 0 -column 0 -sticky news
        grid $itk_component(arrowButton) -row 0 -column 1 -sticky news
	registerComponent $itk_component(mb)
	eval itk_initialize $args

        announceExist
    }
    destructor {
        unregisterComponent
    }
}
configbody DCS::DropdownMenu::state {
    if {$itk_option(-state) != "disabled"} {
        handleNewOutput
    }
}

class DCS::RobotPortMenuButton {
    inherit ::itk::Widget DCS::Component

    itk_option define -nullOK nullOK NullOK 0
    itk_option define -cassette cassette Cassette left { repack }
    itk_option define -purpose purpose Purpose forMount { repack }

    public method setValue { value {direct 0} } {
        if {$direct} {
            $itk_component(mb) configure -text $value
            return
        }

        if {$itk_option(-nullOK)} {
            if {$value == "" || \
            [lsearch $m_validChoiceList $value] >= 0} {
                $itk_component(mb) configure -text $value
            } else {
                log_error \
                "bad value $value, only accept {$m_validChoiceList}"
                $itk_component(mb) configure -text ""
            }
        } else {
            if {[lsearch $m_validChoiceList $value] >= 0} {
                $itk_component(mb) configure -text $value
            } else {
                log_error \
                "bad value $value, only accept {$m_validChoiceList}"
            }
        }
        updateRegisteredComponents value
    }
    public method getValue { } {
        return [$itk_component(mb) cget -text]
    }

    public method selectDefault { } {
        set current [getValue]
        if {$current != ""} {
            catch {$itk_component(mn) activate $current}
        }
    }
    public method repack { }

    public method handlePortStatusEvent

    private method setupUnknown { }
    private method setupBad { }
    private method setupNormal { portStatusList }
    private method setupPuck { portStatusList }
    private method setupCSC { portStatusList }

    private common EVEN_COLOR #808080
    private common ODD_COLOR  #80f0f0

    private variable m_unknownList [list \
    A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 A12 A13 A14 A15 A16 \
    B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11 B12 B13 B14 B15 B16 \
    C1 C2 C3 C4 C5 C6 C7 C8 C9 C10 C11 C12 C13 C14 C15 C16 \
    D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 \
    E1 E2 E3 E4 E5 E6 E7 E8 E9 E10 E11 E12 E13 E14 E15 E16 \
    F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 F13 F14 F15 F16 \
    G1 G2 G3 G4 G5 G6 G7 G8 G9 G10 G11 G12 G13 G14 G15 G16 \
    H1 H2 H3 H4 H5 H6 H7 H8 H9 H10 H11 H12 H13 H14 H15 H16 \
    I1 I2 I3 I4 I5 I6 I7 I8 I9 I10 I11 I12 I13 I14 I15 I16 \
    J1 J2 J3 J4 J5 J6 J7 J8 J9 J10 J11 J12 J13 J14 J15 J16 \
    K1 K2 K3 K4 K5 K6 K7 K8 K9 K10 K11 K12 K13 K14 K15 K16 \
    L1 L2 L3 L4 L5 L6 L7 L8 L9 L10 L11 L12 L13 L14 L15 L16]

    private variable m_unknownColor [list \
    $EVEN_COLOR $EVEN_COLOR \
    $ODD_COLOR  $ODD_COLOR \
    $EVEN_COLOR $EVEN_COLOR \
    $ODD_COLOR  $ODD_COLOR \
    $EVEN_COLOR \
    $ODD_COLOR  \
    $EVEN_COLOR \
    $ODD_COLOR \
    $EVEN_COLOR \
    $ODD_COLOR \
    $EVEN_COLOR \
    $ODD_COLOR]

    private variable m_normalList [list \
    A1 A2 A3 A4 A5 A6 A7 A8 \
    B1 B2 B3 B4 B5 B6 B7 B8 \
    C1 C2 C3 C4 C5 C6 C7 C8 \
    D1 D2 D3 D4 D5 D6 D7 D8 \
    E1 E2 E3 E4 E5 E6 E7 E8 \
    F1 F2 F3 F4 F5 F6 F7 F8 \
    G1 G2 G3 G4 G5 G6 G7 G8 \
    H1 H2 H3 H4 H5 H6 H7 H8 \
    I1 I2 I3 I4 I5 I6 I7 I8 \
    J1 J2 J3 J4 J5 J6 J7 J8 \
    K1 K2 K3 K4 K5 K6 K7 K8 \
    L1 L2 L3 L4 L5 L6 L7 L8]

    private variable m_puckList [list \
    A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 A12 A13 A14 A15 A16 \
    B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11 B12 B13 B14 B15 B16 \
    C1 C2 C3 C4 C5 C6 C7 C8 C9 C10 C11 C12 C13 C14 C15 C16 \
    D1 D2 D3 D4 D5 D6 D7 D8 D9 D10 D11 D12 D13 D14 D15 D16 \
    E1 E2 E3 E4 E5 E6 E7 E8 E9 E10 E11 E12 E13 E14 E15 E16 \
    F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 F13 F14 F15 F16 \
    G1 G2 G3 G4 G5 G6 G7 G8 G9 G10 G11 G12 G13 G14 G15 G16 \
    H1 H2 H3 H4 H5 H6 H7 H8 H9 H10 H11 H12 H13 H14 H15 H16 \
    I1 I2 I3 I4 I5 I6 I7 I8 I9 I10 I11 I12 I13 I14 I15 I16 \
    J1 J2 J3 J4 J5 J6 J7 J8 J9 J10 J11 J12 J13 J14 J15 J16 \
    K1 K2 K3 K4 K5 K6 K7 K8 K9 K10 K11 K12 K13 K14 K15 K16 \
    L1 L2 L3 L4 L5 L6 L7 L8 L9 L10 L11 L12 L13 L14 L15 L16]

    private variable m_cscList [list \
    A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 A12 A13 A14 A15 A16 A17 A18 A19]

    private variable m_validChoiceList ""

    private variable m_strRobotCassette
    private variable m_ctxRobotCassette ""

    constructor { args } {
        DCS::Component::constructor {value getValue}
    } {
        set m_validChoiceList $m_unknownList

        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_strRobotCassette [$deviceFactory createString robot_cassette]

        itk_component add mb {
            menubutton $itk_interior.mb \
            -menu $itk_interior.mb.menu \
            -relief sunken \
            -background white
        } {
            keep -direction -state -width -foreground -background
        }

        itk_component add mn {
            menu $itk_interior.mb.menu \
            -postcommand "$this selectDefault" \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0
        } {
        }
        pack $itk_component(mb)
        eval itk_initialize $args

        announceExist

        $m_strRobotCassette register $this contents handlePortStatusEvent
    }
    destructor {
        $m_strRobotCassette unregister $this contents handlePortStatusEvent
    }
}
body DCS::RobotPortMenuButton::handlePortStatusEvent { name_ targetReady_ - contents_ - } {
    if {!$targetReady_} return

    set m_ctxRobotCassette $contents_
    repack
}

body DCS::RobotPortMenuButton::repack { } {
    if {$m_ctxRobotCassette == ""} return

    switch -exact  -- $itk_option(-cassette) {
        left    { set start 0}
        middle  { set start 97 }
        right   { set start 194 }
        default { return }
    }
    set cas_status [lindex $m_ctxRobotCassette $start]

    incr start
    set end [expr $start + 95]
#puts "yangx cas_status = $cas_status start = $start  end = $end"
    set portStatusList [lrange $m_ctxRobotCassette $start $end]
#puts "yangx portStatusList = $portStatusList "
    switch -exact -- $cas_status {
        u { setupUnknown }
        2 -
        1 { setupNormal $portStatusList }
        3 { setupPuck $portStatusList }
        4 { setupCSC $portStatusList }
        default { setupBad }
    }
}

body DCS::RobotPortMenuButton::setupUnknown { } {
    $itk_component(mn) delete 0 end

    set i 0
    foreach port $m_unknownList {
        set color_index [expr $i / 8]
        set bg [lindex $m_unknownColor $color_index]
        $itk_component(mn) add command \
        -label $port \
        -command "$this setValue $port" \
        -background $bg \
        -hidemargin 1 \
        -columnbreak [expr ($i % 8) == 0]

        incr i
    }

    set m_validChoiceList $m_unknownList
}
body DCS::RobotPortMenuButton::setupBad { } {
    $itk_component(mn) delete 0 end

    set m_validChoiceList ""
}

body DCS::RobotPortMenuButton::setupNormal { portStatusList } {
    $itk_component(mn) delete 0 end

    set i 0
    set m_validChoiceList ""
    foreach port $m_normalList {
        set color_index [expr $i / 8]
        if {$color_index % 2} {
            set bg $ODD_COLOR
        } else {
            set bg $EVEN_COLOR
        }
        ###status: u 0 1 m - j b
        set status [lindex $portStatusList $i]
        switch -exact -- $status {
            u {
                set state normal
            }
            0 {
                if {$itk_option(-purpose) == "forMoveDestination"} {
                    set state normal
                } else {
                    set state disabled
                }
            }
            1 {
                if {$itk_option(-purpose) == "forMoveDestination"} {
                    set state disabled
                } else {
                    set state normal 
                }

            }
            default {
                set state disabled
            }
        }
        if {$state == "normal"} {
            lappend m_validChoiceList $port
        }
    
        $itk_component(mn) add command \
        -state $state \
        -label $port \
        -command "$this setValue $port" \
        -background $bg \
        -hidemargin 1 \
        -columnbreak [expr ($i % 8) == 0]

        incr i
    }
}

body DCS::RobotPortMenuButton::setupPuck { portStatusList } {
    $itk_component(mn) delete 0 end

    set i 0
    set m_validChoiceList ""
#yangx add
    switch -exact  -- $itk_option(-cassette) {
	#A1 start at 0
        left    { set start 0}
	#E1 start at 64
        middle  { set start 64 }
	#I1 start at 129
        right   { set start 128 }
        default { return }
    }
    #set end [expr $start + 95]
    set m_puckLists [lrange $m_puckList $start end]
	
    foreach port $m_puckLists {
        set color_index [expr $i / 16]
        if {$color_index % 2} {
            set bg $ODD_COLOR
        } else {
            set bg $EVEN_COLOR
        }
        ###status: u 0 1 m - j b
        set status [lindex $portStatusList $i]
        switch -exact -- $status {
            u {
                set state normal
            }
            0 {
                if {$itk_option(-purpose) == "forMoveDestination"} {
                    set state normal
                } else {
                    set state disabled
                }
            }
            1 {
                if {$itk_option(-purpose) == "forMoveDestination"} {
                    set state disabled
                } else {
                    set state normal 
                }

            }
            default {
                set state disabled
            }
        }
        if {$state == "normal"} {
            lappend m_validChoiceList $port
        }
    
        $itk_component(mn) add command \
        -state $state \
        -label $port \
        -command "$this setValue $port" \
        -background $bg \
        -hidemargin 1 \
        -columnbreak [expr ($i % 8) == 0]

        incr i
    }
#puts "yangx i = $i m_validChoiceList = $m_validChoiceList"
#puts "yangx m_puckLists =$m_puckLists"
}
body DCS::RobotPortMenuButton::setupCSC { portStatusList } {
    $itk_component(mn) delete 0 end

    set i 0
    set m_validChoiceList ""
    foreach port $m_cscList {
        set color_index [expr $i / 5]
        if {$color_index % 2} {
            set bg $ODD_COLOR
        } else {
            set bg $EVEN_COLOR
        }
        ###status: u 0 1 m - j b
        set status [lindex $portStatusList $i]
        switch -exact -- $status {
            u {
                set state normal
            }
            0 {
                if {$itk_option(-purpose) == "forMoveDestination"} {
                    set state normal
                } else {
                    set state disabled
                }
            }
            1 {
                if {$itk_option(-purpose) == "forMoveDestination"} {
                    set state disabled
                } else {
                    set state normal 
                }

            }
            default {
                set state disabled
            }
        }
        if {$state == "normal"} {
            lappend m_validChoiceList $port
        }
    
        $itk_component(mn) add command \
        -state $state \
        -label $port \
        -command "$this setValue $port" \
        -background $bg \
        -hidemargin 1 \
        -columnbreak [expr ($i % 5) == 0]

        incr i
    }
}
