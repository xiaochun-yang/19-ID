package provide BLUICESimpleRobot 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
#package require DCSSet 1.0
package require DCSComponent

#package require DCSProtocol
package require DCSOperationManager
#package require DCSHardwareManager
#package require DCSPrompt
#package require DCSMotorControlPanel
package require DCSCheckbutton
#package require DCSGraph
package require DCSLabel
#package require DCSFeedback
package require DCSDeviceLog
#package require DCSCheckbox
#package require DCSEntryfield
package require DCSDeviceFactory
package require DCSMenuButton
package require ComponentGateExtension
package require BLUICERobot

class RobotMountedLabel {
    inherit ::itk::Widget DCS::Component

    public method handleUpdate
    public method getValue { } {
        return $m_value
    }
    public method getRobotReady { } {
        return $m_robotReady
    }

    public method canDismount { } {
        if {!$m_robotReady} {
            return 0
        }
        return [expr ([string length $m_value] != 0) ? 1 : 0]
    }

    protected variable m_deviceFactory
    protected variable m_statusObj ""
    protected variable m_statusStr ""
    protected variable m_value ""
    protected variable m_robotReady 0

    constructor { args } {
        DCS::Component::constructor {value getValue robotReady getRobotReady dismount canDismount}
    } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_statusObj [$m_deviceFactory createString robot_status]

        itk_component add cassette {
            label $itk_interior.cas \
            -relief sunken \
            -width 7
        } {
            keep -background -foreground
        }

        itk_component add port {
            label $itk_interior.port \
            -relief sunken \
            -width 3
        } {
            keep -background -foreground
        }
        pack $itk_component(cassette) -side left -expand 1 -fill x
        pack $itk_component(port) -side left -expand 1 -fill x
        eval itk_initialize $args

        $m_statusObj register $this contents handleUpdate

        announceExist
    }
    destructor {
        $m_statusObj unregister $this contents handleUpdate
    }
}

body RobotMountedLabel::handleUpdate { stringName_ targetReady_ alias_ contents_ - } {
    if { ! $targetReady_} return

    set m_statusStr $contents_
    set status_num [lindex $m_statusStr 1]
    if {$status_num == 0 || $status_num == 1 << 30} {
        set m_robotReady 1
    } else {
        set m_robotReady 0
    }

    set mountedValue [lindex $m_statusStr 15]
    if {[llength $mountedValue] < 3} {
        set m_value ""
    } else {
        set m_value [lindex $mountedValue 0][lindex $mountedValue 2][lindex $mountedValue 1]
    }
    #puts " mounted label update: value=$m_value"

    if {$m_value == ""} {
        $itk_component(cassette) configure -text ""
        $itk_component(port) configure -text ""
    } else {
        set cas [RobotPortWidget::letter2word [string index $m_value 0]]
        $itk_component(cassette) configure -text $cas
        $itk_component(port) configure -text [string range $m_value 1 end]
    }
    updateRegisteredComponents value
    updateRegisteredComponents robotReady
    updateRegisteredComponents dismount
}

class RobotPortWidget {
#    inherit ::itk::Widget DCS::ComponentGate
    inherit ::DCS::ComponentGateExtension
    itk_option define -followReference followReference FollowReference 1
	itk_option define -controlSystem controlsytem ControlSystem ::dcss
	itk_option define -state state State normal
    itk_option define -selectedForeground selectedForeground Foreground white
    itk_option define -selectedBackground selectedBackground Background blue
    itk_option define -selected selected Selected 0 { updateColor 1 }

    protected variable m_systemIdle

    private variable m_refValue ""
    private variable m_needMount 0

    private variable m_strCassetteOwner
    private variable m_cnxCassettePermit {1 1 1 1}
    private variable m_strRobotCassette
    private variable m_cnxCassetteStatus {u u u u}
    private variable m_casStatusIndex {0 97 194}

    private common s_casNameList
    private common s_casLabelList

    public method getNeedMount { } {
        return $m_needMount
    }

    public method handleCassetteValueChange { - targetReady_ - contents_ - } {
        if {!$targetReady_} return
        #puts "cassette: {$contents_}"

        set index [lsearch -exact $s_casLabelList $contents_]

        if {$index < 0} {
            if {$contents_ != ""} {
                log_error bad cassette selection $contents_
            }
            return
        }

        set casName [lindex $s_casNameList $index]

        $itk_component(port) configure -cassette $casName

        updateColor 0
    }
    public method handleComponentValueChange { objName_ targetReady_ alias_ - - } {
        if {!$targetReady_} return

        #puts "port componentValueChange"
        updateColor 0
    }

    public method handleCassettePermitsChange
    public method handleRobotCassetteChange
    private method rebuildCassetteMenuChoices

    constructor { args } {
        DCS::Component::constructor {need_mount getNeedMount value getValue}
    } {
        set s_casNameList  [RobotBaseWidget::getCassetteNameList]
        set s_casLabelList [RobotBaseWidget::getCassetteLabelList]

        itk_component add cassette {
            DCS::MenuButton $itk_interior.cas \
            -width 6 \
            -menuChoices [lrange $s_casLabelList 1 end]
        } {
            keep -foreground -background
            keep -nullOK
        }

        itk_component add port {
            DCS::RobotPortMenuButton $itk_interior.port \
            -width 3
        } {
            keep -purpose
            keep -foreground -background
            keep -nullOK
        }

        pack $itk_component(cassette) -side left -expand 1 -fill x
        pack $itk_component(port) -side left -expand 1 -fill x
	    registerComponent $itk_component(cassette) $itk_component(port)
        eval itk_initialize $args

        #hook together
        $itk_component(cassette) register $this value handleCassetteValueChange
        $itk_component(port) register $this value handleComponentValueChange

        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_strCassetteOwner \
        [$deviceFactory createCassetteOwnerString cassette_owner]
        set m_strRobotCassette \
        [$deviceFactory createString robot_cassette]

        $m_strCassetteOwner register $this permits handleCassettePermitsChange
        $m_strRobotCassette register $this contents handleRobotCassetteChange

        announceExist
    }

    destructor {
        #$itk_component(cassette) unregister $this value handleCassetteValueChange
        #$itk_component(port) unregister $this value handleComponentValueChange
        $m_strCassetteOwner unregister $this permits handleCassettePermitsChange
        $m_strRobotCassette unregister $this contents handleRobotCassetteChange
	    unregisterComponent
    }

    public method setValue { port {direct 0}} {
        #puts "setValue: $port $direct"
        #port format lA1
        set cas [letter2word [string index $port 0]]
        set pp  [string range $port 1 end]

        $itk_component(cassette) setValue $cas $direct
        $itk_component(port) configure -cassette $cas
        $itk_component(port) setValue $pp $direct
        updateColor $direct

    }

    public method getValue { } {
        set cas [$itk_component(cassette) getValue]
        set cas [word2letter $cas]
        set pp  [$itk_component(port) getValue]
        return $cas$pp
    }

    public method handleReferenceUpdate { refName_ targetReady_ alias_ value_ -} {
        if {!$targetReady_} return
        if {$m_refValue == $value_} return

        #puts "reference update value=$value_"

        set m_refValue $value_
        if {$itk_option(-followReference) && $m_refValue != ""} {
            setValue $m_refValue 1
        } else {
            updateColor 1
        }
    }

    public method updateColor { {skipUpdate 0} args } {
        if {!$skipUpdate} {
            updateRegisteredComponents value
        }
        if {$itk_option(-purpose) == "forMount"} {
            if {$m_refValue != [getValue]} {
                configure -foreground red -background white
                set m_needMount 1
            } else {
                configure -foreground black -background white
                set m_needMount 0
            }
            updateRegisteredComponents need_mount
        } else {
            if {$itk_option(-selected)} {
                configure \
                -foreground $itk_option(-selectedForeground) \
                -background $itk_option(-selectedBackground)
            } else {
                configure \
                -foreground black \
                -background white
            }
        }
    }

    public proc letter2word { cas } {
        switch -exact $cas {
            l { return [lindex $s_casLabelList 1] }
            m { return [lindex $s_casLabelList 2] }
            r { return [lindex $s_casLabelList 3] }
            b { return align }
            n { return "" }
            default {
                if {$cas != ""} {
                    log_error bad cassette $cas
                    puts "bad cassette $cas in letter2word"
                }
                return $cas
            }
        }
    }
    public proc word2letter { cas } {
        if {$cas == "align"} {
            return b
        }
        set index [lsearch -exact $s_casLabelList $cas]
        if {$index < 0} {
            if {$cas != ""} {
                log_error bad cassette $cas
                puts "bad cassette $cas in word2letter"
            }
            return n
        }
        set casName [lindex $s_casNameList $index]
        return [string index $casName 0]
    }
}

body RobotPortWidget::handleCassettePermitsChange { - ready_ - contents_ - } {
    if {!$ready_} return

    set m_cnxCassettePermit $contents_
    rebuildCassetteMenuChoices
}
body RobotPortWidget::handleRobotCassetteChange { - ready_ - contents_ - } {
    if {!$ready_} return

    set need_refresh 0
    for {set i 0} {$i < 3} {incr i} {
        set index [lindex $m_casStatusIndex $i]
        set status [lindex $contents_ $index]
        set j [expr $i + 1]
        set old_status [lindex $m_cnxCassetteStatus $j]
        set m_cnxCassetteStatus [lreplace $m_cnxCassetteStatus $j $j $status]
        if {($old_status == "-" || $status == "-") && $old_status != $status} {
            set need_refresh 1
        }
    }
    if {$need_refresh} {
        rebuildCassetteMenuChoices
    }
}

body RobotPortWidget::rebuildCassetteMenuChoices { } {
    set choices [list]

    set location $s_casLabelList

    for {set i 1} {$i < 4} {incr i} {
        if {[lindex $m_cnxCassettePermit $i] == "1" && \
        [lindex $m_cnxCassetteStatus $i] != "-"} {
            lappend choices [lindex $location $i]
        }
    }

    $itk_component(cassette) configure \
    -menuChoices $choices
}


configbody RobotPortWidget::state {
	handleNewOutput
}

class SimpleRobotWidget {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -orientation orientation Orientation horz
    itk_option define -width width Width 0 {
        if {$itk_option(-width) > 20} {
            $itk_component(msg) configure -width [expr $itk_option(-width) - 8]
        }
    }

    protected variable m_deviceFactory
    protected variable m_opSeqManual
    protected variable m_objOpWashSample
    protected variable m_statusObj ""

    protected variable red #c04080
    protected variable green #00a040 

    protected variable m_wrap4Port
    protected variable m_wrap4RawMounted
    protected variable m_wrap4RobotReady

    protected variable m_oprobotinit
    protected variable m_opcloselid
    protected variable m_opopenlid
    protected variable m_opRMS
    protected variable m_opcoolgrabber
    protected variable m_opwarmgrabber


    public method handleMountClick { } {
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
        set port [$itk_component(port) getValue]
        set on_gonio [$itk_component(raw_mounted) getValue]
        if {$port == $on_gonio} {
            log_error mount ignored. same sample already on goniometer
        } else {
            $m_opSeqManual startOperation mount $port $SID
        }

	puts "gEncryptSID=$gEncryptSID SID=$SID port=$port m_opSeqManual=$m_opSeqManual\n"
    }
    public method handleDismountClick { } {
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
        $m_opSeqManual startOperation mount nN0 $SID
    }
    public method handleWashClick { } {
        set num_cycle [$itk_component(num_cycle) get]
        $m_objOpWashSample startOperation $num_cycle
    }

    public method setValue { value } {
        $itk_component(port) setValue $value
    }

    public method getSite { } {
        return [$itk_component(ring) childsite]
    }

    public method handleInitRobot { } {
#         $m_oprobotinit startOperation
    }

    public method handleCloselid { } {
         $m_opcloselid startOperation
    }

    public method handleMountpos { } {
        ::device::gonio_phi move to 0 deg
	::device::gonio_kappa move to 0 deg
	::device::tripot_1 move to 0.70378
       	::device::tripot_2 move to 0.35898
       	::device::tripot_3 move to 0.36494
    }

    public method handleOpenlid { } {
         $m_opopenlid startOperation
    }

    public method handleWarmgrabber { } {
         $m_opwarmgrabber startOperation
    }

    public method handleCoolgrabber { } {
         $m_opcoolgrabber startOperation
    }

    public method handleRMS { } {
         $m_opRMS startOperation
    }

    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_opSeqManual [$m_deviceFactory createOperation sequenceManual]
        set m_objOpWashSample [$m_deviceFactory createOperation washCrystal]

        set m_statusObj [$m_deviceFactory createString robot_status]
        $m_statusObj createAttributeFromField status_num 1

        set noSampleWash [::config getStr bluice.noSampleWash]

#yangx Add reset mount statu
#        set m_oprobotinit [$m_deviceFactory createOperation robotinit]
        set m_opcloselid [$m_deviceFactory createOperation close_lid]
        set m_opopenlid [$m_deviceFactory createOperation open_lid]
        set m_opwarmgrabber [$m_deviceFactory createOperation warm_up_grabber]
        set m_opcoolgrabber [$m_deviceFactory createOperation cool_down_grabber]
	set m_opRMS [$m_deviceFactory createOperation RMS]
	
        itk_component add ring {
            ::iwidgets::labeledframe $itk_interior.lf \
            -labelpos nw \
            -labelmargin 0 \
            -labeltext "Sample Mounting Robot Control"
        } {
        }

        set site [$itk_component(ring) childsite]

        itk_component add message {
            frame $site.mf
        } {
        }
        set msgSite $itk_component(message)

        itk_component add status {
            RobotStatusLabel $msgSite.status \
            -width 8 \
            -normalBackground $green
        } {
        }

        itk_component add msg {
            DCS::Label $msgSite.msg \
            -showPrompt 0 \
            -anchor w
        } {
        }
        set obj [$m_deviceFactory createString robot_sample]
	    $itk_component(msg) configure -component $obj -attribute contents
        
        itk_component add port {
            RobotPortWidget $site.port -activeClientOnly 0 -systemIdleOnly 0
        } {
        }

        itk_component add mount {
            DCS::Button $site.bm \
            -text "Mount" \
            -width 8 \
            -command "$this handleMountClick"
        } {
        }

        itk_component add raw_mounted {
            RobotMountedLabel $site.mntd \
            -background $red
        } {
        }

        itk_component add dismount {
            DCS::Button $site.bd \
            -text "Dismount" \
            -width 8 \
            -command "$this handleDismountClick"
        } {
        }

        itk_component add num_cycle {
            DCS::MenuEntry $site.cycle\
            -entryWidth 2 \
            -showEntry 1 \
            -showUnits 0 \
            -showArrow 1 \
            -showPrompt 1 \
            -promptText "times" \
            -entryType int \
            -menuChoices {0 1 2 3 4 5 6 7 8 9 10} \
            -activeClientOnly 0 \
            -systemIdleOnly 0
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }
        $itk_component(num_cycle) setValue 4

        itk_component add wash {
            DCS::HotButton $site.wash \
            -text "Start Wash" \
            -confirmText "Confirm may lose sample" \
            -width 8 \
            -command "$this handleWashClick"
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        itk_component add Init {
            DCS::HotButton $site.bi \
            -text "Initialize Robot"  \
            -confirmText "Confirm to initialize"\
            -width 20 \
            -command "$this handleInitRobot"
        } {
            keep -activeClientOnly
        }

        itk_component add Close {
            DCS::HotButton $site.bc \
            -text "Close Lid"  \
            -confirmText "Confirm"\
            -width 9 \
            -command "$this handleCloselid"
        } {
            keep -activeClientOnly
        }

        itk_component add Open {
            DCS::HotButton $site.bo \
            -text "Open Lid"  \
            -confirmText "Confirm"\
            -width 9 \
            -command "$this handleOpenlid"
        } {
            keep -activeClientOnly
        }

        itk_component add Warm {
            DCS::HotButton $site.wm \
            -text "Warm Grabber"  \
            -confirmText "Confirm"\
            -width 9 \
            -command "$this handleWarmgrabber"
        } {
            keep -activeClientOnly
        }

        itk_component add Mountpos {
            DCS::HotButton $site.mp \
            -text "Mount Position"  \
            -confirmText "Confirm"\
            -width 9 \
            -command "$this handleMountpos"
        } {
            keep -activeClientOnly
        }

        itk_component add Cool {
            DCS::HotButton $site.co \
            -text "Cool Grabber"  \
            -confirmText "Confirm"\
            -width 9 \
            -command "$this handleCoolgrabber"
        } {
            keep -activeClientOnly
        }

        itk_component add remove {
            DCS::HotButton $site.br \
            -text "Clear Mount State"  \
            -confirmText "Confirm to clear State"\
            -width 20 \
            -command "$this handleRMS"
        } {
            keep -activeClientOnly
        }

        eval itk_initialize $args

        if {$itk_option(-orientation) == "vert"} {
            $itk_component(msg) configure -width 8
            $itk_component(ring) configure -labeltext Robot

            pack $itk_component(status) -side top
            pack $itk_component(msg) -side top -expand 1 -fill x
            pack $itk_component(message) -side top
            pack $itk_component(port) -side top
            pack $itk_component(raw_mounted) -side top
            pack $itk_component(mount) -side top
            pack $itk_component(dismount) -side top
            if {$noSampleWash != "1"} {
                pack $itk_component(num_cycle) -side top
                pack $itk_component(wash) -side top
            }
        } elseif {$itk_option(-orientation) == "long"} {
            pack $itk_component(status) -side top -anchor w
            pack $itk_component(msg) -side top -anchor w

            grid $itk_component(port)        -row 0 -column 0 -sticky e
            grid $itk_component(raw_mounted) -row 1 -column 0 -sticky e
            if {$noSampleWash != "1"} {
                grid $itk_component(num_cycle)   -row 2 -column 0 -sticky e
            }

            grid $itk_component(mount)    -row 0 -column 1 -sticky w
            grid $itk_component(dismount) -row 1 -column 1 -sticky w
            if {$noSampleWash != "1"} {
                grid $itk_component(wash)     -row 2 -column 1 -sticky w -columnspan 2
            }
            grid $itk_component(message) -row 0 -column 2 -rowspan 2 -sticky news

            grid $itk_component(Init) -row 1 -column 2 -sticky w   
            grid $itk_component(Open) -row 0 -column 3 -sticky w -columnspan 2
	    grid $itk_component(Close) -row 1 -column 3  -sticky w -columnspan 2

            grid $itk_component(remove) -row 2 -column 2  -sticky w -columnspan 2
            grid $itk_component(Warm) -row 2 -column 3 -sticky w -columnspan 2
            grid $itk_component(Mountpos) -row 3 -column 3 -sticky nw -columnspan 2

            grid columnconfigure $site 0 -weight 0
            grid columnconfigure $site 1 -weight 1
            grid columnconfigure $site 2 -weight 1
	    grid columnconfigure $site 3 -weight 0

            grid rowconfigure $site 0 -weight 1
            grid rowconfigure $site 1 -weight 1
            grid rowconfigure $site 2 -weight 1
            grid rowconfigure $site 3 -weight 50
        } else {
            pack $itk_component(status) -side left
            pack $itk_component(msg) -side left -expand 1 -fill x

            grid $itk_component(message) -row 0 -column 0 -columnspan 5 -sticky news
            grid $itk_component(port) -row 1 -column 0 -sticky e
            grid $itk_component(mount) -row 1 -column 1 -sticky w
            grid $itk_component(raw_mounted) -row 2 -column 0 -sticky e
            grid $itk_component(dismount) -row 2 -column 1 -sticky w

            if {$noSampleWash != "1"} {
                grid $itk_component(num_cycle) -row 3 -column 0 -sticky news
                grid $itk_component(wash) -row 3 -column 1 -sticky news
            }

            grid rowconfigure $site 0 -weight 10
            grid rowconfigure $site 1 -weight 0
            grid rowconfigure $site 2 -weight 1

            grid columnconfigure $site 0 -weight 0
            grid columnconfigure $site 1 -weight 1
        }

        pack $itk_component(ring) -expand 1 -fill both
        pack $itk_interior
        $itk_component(port) setValue lA1

        ####hook
        set m_wrap4Port [DCS::ItkWigetWrapper ::#auto $itk_component(port) need_mount]
        set m_wrap4RawMounted [DCS::ItkWigetWrapper ::#auto $itk_component(raw_mounted) dismount]
        set m_wrap4RobotReady [DCS::ItkWigetWrapper ::#auto $itk_component(raw_mounted) robotReady]

        $itk_component(raw_mounted) register $itk_component(port) value handleReferenceUpdate

        $itk_component(mount) addInput \
        "$m_opSeqManual permission GRANTED {PERMISSION}"
        $itk_component(mount) addInput \
        "$m_wrap4RobotReady robotReady 1 {robot not ready}"
        $itk_component(mount) addInput \
        "[scope $m_wrap4Port] need_mount 1 {select a different crystal}"

        $itk_component(dismount) addInput \
        "$m_opSeqManual permission GRANTED {PERMISSION}"
        $itk_component(dismount) addInput \
        "$m_wrap4RobotReady robotReady 1 {robot not ready}"
        $itk_component(dismount) addInput \
        "$m_wrap4RawMounted dismount 1 {no crystal on goniometer}"

        $itk_component(wash) addInput \
        "$m_objOpWashSample status inactive {supporting device}"
        $itk_component(wash) addInput \
        "$m_objOpWashSample permission GRANTED {PERMISSION}"
        $itk_component(wash) addInput \
        "$m_statusObj status_num 0 {robot not ready}"
        $itk_component(wash) addInput \
        "$m_wrap4RawMounted dismount 1 {no crystal on goniometer}"
    }
    destructor {
        delete object $m_wrap4Port $m_wrap4RawMounted
    }
}

class repeatMountWidget {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -width width Width 0 {
        if {$itk_option(-width) > 20} {
            $itk_component(msg) configure -width [expr $itk_option(-width) - 8]
        }
    }

    protected variable m_deviceFactory
    protected variable m_objRepeatMount
    protected variable m_statusObj ""

    protected variable red #c04080
    protected variable green #00a040 

    public method handleMountClick { } {
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }

	puts "gEncryptSID=$gEncryptSID SID=$SID\n"

        set port [$itk_component(port) getValue]
        set num_cycle [$itk_component(num_cycle) get]

	puts "m_objRepeatMount=$m_objRepeatMount port=$port num_cycle=$num_cycle\n"
        $m_objRepeatMount startOperation $port $num_cycle $SID
    }

    public method setValue { value } {
        $itk_component(port) setValue $value
    }

    public method getSite { } {
        return [$itk_component(ring) childsite]
    }

    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_objRepeatMount [$m_deviceFactory createOperation repeatMount]
        set m_statusObj [$m_deviceFactory createString robot_status]
        $m_statusObj createAttributeFromField status_num 1

        itk_component add ring {
            ::iwidgets::labeledframe $itk_interior.lf \
            -labelpos nw \
            -labelmargin 0 \
            -labeltext "Repeat Mounting Test Control"
        } {
        }

        itk_component add log {
            DCS::DeviceLog $itk_interior.log
        } {
        }
        $itk_component(log) addDeviceObjs $m_objRepeatMount


        set site [$itk_component(ring) childsite]

        itk_component add message {
            frame $site.mf
        } {
        }
        set msgSite $itk_component(message)

        itk_component add status {
            RobotStatusLabel $msgSite.status \
            -width 8 \
            -normalBackground $green
        } {
        }

        itk_component add msg {
            DCS::Label $msgSite.msg \
            -showPrompt 0 \
            -anchor w
        } {
        }
        set obj [$m_deviceFactory createString robot_sample]
	    $itk_component(msg) configure -component $obj -attribute contents
        
        itk_component add port {
            RobotPortWidget $site.port -activeClientOnly 0 -systemIdleOnly 0
        } {
        }

        itk_component add mount {
            DCS::Button $site.bm \
            -text "Start" \
            -width 8 \
            -command "$this handleMountClick"
        } {
        }

        itk_component add raw_mounted {
            RobotMountedLabel $site.mntd \
            -background $red
        } {
        }

        itk_component add num_cycle {
            DCS::MenuEntry $site.cycle\
            -entryWidth 4 \
            -showEntry 1 \
            -showUnits 0 \
            -showArrow 1 \
            -showPrompt 1 \
            -promptText "times" \
            -entryType int \
            -menuChoices {10 20 30 40 50 60 70 80 90 100} \
            -activeClientOnly 0 \
            -systemIdleOnly 0
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }
        $itk_component(num_cycle) setValue 100

        eval itk_initialize $args

        pack $itk_component(status) -side top -anchor w
        pack $itk_component(msg) -side top -anchor w

        grid $itk_component(port)        -row 0 -column 0 -sticky e
        grid $itk_component(raw_mounted) -row 1 -column 0 -sticky e
        grid $itk_component(num_cycle)   -row 2 -column 0 -sticky e

        grid $itk_component(mount)    -row 0 -column 1 -sticky w

        grid $itk_component(message) -row 0 -column 2 -rowspan 2 -sticky news

        grid columnconfigure $site 0 -weight 0
        grid columnconfigure $site 1 -weight 0
        grid columnconfigure $site 2 -weight 1

        pack $itk_component(ring) -fill x -side top
        pack $itk_component(log) -side top -expand 1 -fill both
        pack $itk_interior
        $itk_component(port) setValue lA1

        ####hook
        $itk_component(raw_mounted) register $itk_component(port) value handleReferenceUpdate

        $itk_component(mount) addInput \
        "$m_objRepeatMount permission GRANTED {PERMISSION}"
        $itk_component(mount) addInput \
        "$m_statusObj status_num 0 {robot not ready}"
    }
    destructor {
        #$itk_component(raw_mounted) unregister $itk_component(port) value handleReferenceUpdate
    }
}
class oneLineMountWidget {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -updateString updateString UpdateString "" {
        set m_objString ""
        set m_objIndex -1
        foreach {m_objString m_objIndex} $itk_option(-updateString) break
        if {$m_objIndex == ""} {
            set m_objIndex -1
        }
    }

    protected variable m_deviceFactory
    protected variable m_opSeqManual
    protected variable m_statusObj ""
    protected variable m_wrap4Port

    #### update string field
    protected variable m_objString ""
    protected variable m_objIndex -1

    protected variable red #c04080
    protected variable green #00a040 

    public method addInput { check } {
        $itk_component(mount) addInput $check
        $itk_component(port) addInput $check
    }
    public method deleteInput { check } {
        $itk_component(mount) deleteInput $check
        $itk_component(port) deleteInput $check
    }
    public method showMountButton { yes } {
        if {$yes} {
            grid $itk_component(mount)  -row 0 -column 1 -sticky w
        } else {
            grid forget $itk_component(mount)
        }
    }

    public method getMounted { } {
        return [$itk_component(raw_mounted) getValue]
    }
    public method setValue { value {direct 0}} {
        $itk_component(port) setValue $value $direct
    }
    public method handleValueChange { name_ targetReady_ alias_ contents_ - } {
        if {!$targetReady_} return

        if {[$itk_option(-controlSystem) cget -clientState] != "active"} return

        puts "try to update string {$m_objString} {$m_objIndex} to {$contents_}"

        if {$m_objString == ""} {
            return
        }
        if {$m_objIndex == -1} {
            $m_objString sendContentsToServer $contents_
        } else {
            set oldContents [$m_objString getContents]
            set ll [llength $oldContents]
            if {$m_objIndex >= $ll} {
                set numAdd [expr $m_objIndex - $ll + 1]
                for {set i 0} {$i < $numAdd} {incr i} {
                    lappend oldContents {}
                }
            }
            set newContents \
            [lreplace $oldContents $m_objIndex $m_objIndex $contents_]
            $m_objString sendContentsToServer $newContents
        }
    }

    public method handleMountClick { } {
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
        set port [$itk_component(port) getValue]
        $m_opSeqManual startOperation mount $port $SID
    }

    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_opSeqManual [$m_deviceFactory createOperation sequenceManual]
        set m_statusObj [$m_deviceFactory createString robot_status]
        $m_statusObj createAttributeFromField status_num 1

        set site $itk_interior

        set msgSite $site

        itk_component add status {
            RobotStatusLabel $msgSite.status \
            -width 8 \
            -normalBackground $green
        } {
        }

        itk_component add msg {
            DCS::Label $msgSite.msg \
            -width 10 \
            -showPrompt 0 \
            -anchor w
        } {
        }
        set obj [$m_deviceFactory createString robot_sample]
	    $itk_component(msg) configure -component $obj -attribute contents
        
        itk_component add port {
            RobotPortWidget $site.port \
            -nullOK 1 \
            -followReference 0 \
	    -activeClientOnly 0 \
	    -systemIdleOnly 0
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        ####hide behind for update color of port
        itk_component add raw_mounted {
            RobotMountedLabel $site.mntd \
            -background $red
        } {
        }

        itk_component add mount {
            DCS::Button $site.bm \
            -text "Mount1" \
            -width 5 \
            -command "$this handleMountClick"
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        eval itk_initialize $args

        pack $itk_component(status) -side top -anchor w

        grid $itk_component(port)   -row 0 -column 0 -sticky e
        grid $itk_component(mount)  -row 0 -column 1 -sticky w
        grid $itk_component(status) -row 0 -column 2 -sticky w
        grid $itk_component(msg)    -row 0 -column 3 -sticky w
        grid columnconfigure $site 0 -weight 0
        grid columnconfigure $site 1 -weight 0
        grid columnconfigure $site 2 -weight 0
        grid columnconfigure $site 3 -weight 1

        $itk_component(port) setValue "" 1

        ####hook
        set m_wrap4Port [DCS::ItkWigetWrapper ::#auto $itk_component(port) need_mount]
        $itk_component(raw_mounted) register $itk_component(port) value handleReferenceUpdate
        $itk_component(mount) addInput \
        "$m_opSeqManual permission GRANTED {PERMISSION}"
        $itk_component(mount) addInput \
        "$m_opSeqManual status inactive {supporting device}"
        $itk_component(mount) addInput \
        "$m_statusObj status_num 0 {robot not ready}"
        $itk_component(mount) addInput \
        "[scope $m_wrap4Port] need_mount 1 {select a different crystal}"

        $itk_component(port) register $this value handleValueChange
    }
    destructor {
        delete object $m_wrap4Port
    }
}
