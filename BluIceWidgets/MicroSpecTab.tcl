package provide BLUICEMicroSpecTab 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
package require DCSComponent
package require DCSEntryfield

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSScale

package require BLUICEBeamSize

class SimpleImageView {
    inherit ::itk::Widget

    itk_option define -snapshot   snapshot   Snapshot   ""        { update }
    itk_option define -packOption packOption PackOption "-side right"

    itk_option define -format format Format JPEG { update }

    private variable m_rawImage ""
    private variable m_rawWidth 0
    private variable m_rawHeight 0
    
    private variable m_winID "not defined"
    private variable m_snapshot
    private variable m_drawWidth 0
    private variable m_drawHeight 0
    private variable m_imageWidth 0
    private variable m_imageHeight 0

    private variable m_drawImageOK 0
    private variable m_retryID     ""

    public method handleResize {winID width height} {
        #puts "handle Resize $width $height for $winID"
        if {$winID != $m_winID} {
            return
        }

        #set m_drawWidth  [expr $width -  2]
        #set m_drawHeight [expr $height - 2]
        set m_drawWidth  $width
        set m_drawHeight $height

        redrawImage
    }
    public method update

    private method redrawImage
    private method updateSnapshot

    constructor { args } {
    } {
        set snapSite $itk_interior

        itk_component add drawArea {
            canvas $snapSite.canvas
        } {
        }
        pack $itk_component(drawArea) -expand 1 -fill both

        set m_winID $itk_interior
        bind $m_winID <Configure> "$this handleResize %W %w %h"

        $itk_component(drawArea) config -scrollregion {0 0 704 480}

        set m_snapshot [image create photo -palette "256/256/256"]

        $itk_component(drawArea) create image 0 0 \
        -image $m_snapshot \
        -anchor nw \
        -tags "snapshot"

        set m_rawImage [image create photo -palette "256/256/256"]

        eval itk_initialize $args
    }
}
body SimpleImageView::redrawImage { } {
    if {$m_drawWidth < 1 || $m_drawHeight < 1} {
        set m_drawImageOK 0
        puts "draw size < 1"
        return
    }

    if {$m_rawImage == ""} {
        set m_drawImageOK 0
        puts "empty rawImage"
        return
    }

    if {$m_rawWidth < 1 || $m_rawHeight < 1} {
        set m_drawImageOK 0
        puts "rawImage size < 1"
        return
    }

    set xScale [expr double($m_drawWidth)  / $m_rawWidth]
    set yScale [expr double($m_drawHeight) / $m_rawHeight]

    if {$xScale > $yScale} {
        set scale $yScale
    } else {
        set scale $xScale
    }

    set m_imageWidth  [expr int($m_rawWidth  * $scale)]
    set m_imageHeight [expr int($m_rawHeight * $scale)]


    if {$scale >= 0.75} {
        imageResizeBilinear     $m_snapshot $m_rawImage $m_imageWidth
    } else {
        imageDownsizeAreaSample $m_snapshot $m_rawImage $m_imageWidth 0 1
    }

    set m_drawImageOK 1
}
body SimpleImageView::update { } {
    if {$m_retryID != ""} {
        after cancel $m_retryID
        set m_retryID ""
    }
    updateSnapshot
}
body SimpleImageView::updateSnapshot { } {
    set imgFile $itk_option(-snapshot)

    if {$imgFile == ""} {
        $m_rawImage blank
        $m_snapshot blank
        set m_drawImageOK 0
        #puts "jpgfile=={}"
        return
    }

    if {[catch {
        $m_rawImage blank
        $m_rawImage read $imgFile -format $itk_option(-format)

        set m_rawWidth  [image width  $m_rawImage]
        set m_rawHeight [image height $m_rawImage]

        redrawImage
    } errMsg] == 1} {
        log_error failed to create image from file: $errMsg
        puts "failed to create image from file: $errMsg"
        set m_drawImageOK 0
        set m_retryID [after 1000 "$this update"]
    }
}

class MicroSpecLightWidget {
    inherit ::itk::Widget

    private variable m_objString ""
    private variable m_onImage  ""
    private variable m_offImage ""

    public method handleStringUpdate { - ready_ - contents_ -} {
        if {!$ready_} {
            return
        }
        if {[catch {dict get $contents_ HALOGEN} status]} {
            set status off
        }
        if {$status == "on"} {
            set image $m_onImage
        } else {
            set image $m_offImage
        }
        $itk_component(status) configure \
        -image $image
    }
    public method turnLight { on_off } {
        if {$on_off} {
            set contents "HALOGEN on POWER on"
        } else {
            set contents "HALOGEN off"
        }
        $m_objString sendContentsToServer $contents
    }

    constructor { args } {
        global BLC_IMAGES
        set m_onImage  [image create photo \
        -file "$BLC_IMAGES/lightbulb_on.gif" \
        -palette "8/8/8"]

        set m_offImage [image create photo \
        -file "$BLC_IMAGES/lightbulb_off.gif" \
        -palette "8/8/8"]

        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objString [$deviceFactory createOperation microspecLightControl]
        $m_objString createAttributeFromKey light_state HALOGEN

        itk_component add on {
            DCS::Button $itk_interior.on \
            -text "On" \
            -width 7 \
            -command "$this turnLight 1"
        } {
        }

        itk_component add off {
            DCS::Button $itk_interior.off \
            -text "Off" \
            -width 7 \
            -command "$this turnLight 0"
        } {
        }
        $itk_component(on) addInput \
        "$m_objString light_state off {light already on}"
        $itk_component(off) addInput \
        "$m_objString light_state on {light already off}"

        itk_component add status {
            label $itk_interior.status \
            -image $m_offImage \
        } {
        }

        pack $itk_component(on) -side left
        pack $itk_component(off) -side left
        pack $itk_component(status) -side left

        eval itk_initialize $args

        $m_objString register $this contents handleStringUpdate
    }
    destructor {
        $m_objString unregister $this contents handleStringUpdate
    }
}

class MicroSpecModeWidget {
    inherit ::itk::Widget ::DCS::Component

    itk_option define -controlSystem controlSystem ControlSystem ::dcss
    itk_option define -onStartButton onStartButton OnStartButton ""

    # appearance
    private variable _lightColor     #e0e0f0
    private variable _darkColor    #c0c0ff
    private variable _darkColor2 #777
    private variable _lightRedColor #ffaaaa

    private variable _tinyFont *-helvetica-bold-r-normal--10-*-*-*-*-*-*-*
    private variable _smallFont *-helvetica-bold-r-normal--14-*-*-*-*-*-*-*
    private variable _largeFont *-helvetica-bold-r-normal--18-*-*-*-*-*-*-*
    private variable _hugeFont  *-helvetica-medium-r-normal--30-*-*-*-*-*-*-*

    protected variable m_deviceFactory
    protected variable m_objWrap
    protected variable m_objSnapshot
    protected variable m_objPhiScan
    protected variable m_objTimeScan
    protected variable m_objDoseScan
    protected variable m_objSnapshotStatus
    protected variable m_objPhiStatus
    protected variable m_objTimeStatus
    protected variable m_objDoseStatus
    protected variable m_objWrapStatus
    protected variable m_objDefault

    protected variable m_inSwitching 1

    protected variable m_snapshot

    public method handleModeSelect
    public method handleStartButton
    public method handleStopButton
    public method setAttribute { args }
    public method updateParameters { }
    public method defaultParameters { }

    public method handleRefWarningUpdate

    public method getMode { } {
        return [$itk_component(modeRadio) get]
    }

    public method setMode { mode } {
        $itk_component(modeRadio) select $mode
    }

    public method setSnapshot { mode path } {
        puts "setSnapshot $mode $path"
        if {[catch {dict get $m_snapshot $mode} currentPath]} {
            set currentPath ""
        }
        if {$currentPath == $path} {
            return
        }
        dict set m_snapshot $mode $path
        if {[getMode] == $mode} {
            puts "display $path"
            $itk_component(snapshot) configure -snapshot $path
        }
    }

    protected method getDefaultFields { mode } {
        switch -exact -- $mode {
            time_scan {
                set index 1
            }
            phi_scan {
                set index 2
            }
            dose_scan {
                set index 3
            }
            snapshot {
                set index 4
            }
            default {
                log_error unsupported mode: $mode
                return -code error unknown_mode
            }
        }
        set contents [$m_objDefault getContents]
        return [lindex $contents $index]
    }

    constructor { args } {
        ::DCS::Component::constructor {
            mode { getMode }
        }
    } {
        set m_snapshot [dict create \
        snapshot "" \
        phi_scan "" \
        time_scan "" \
        dose_scan ""]

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objWrap     [$m_deviceFactory createOperation spectrometerWrap]
        set m_objSnapshot [$m_deviceFactory createOperation microspec_snapshot]
        set m_objPhiScan  [$m_deviceFactory createOperation microspec_phiScan]
        set m_objTimeScan [$m_deviceFactory createOperation microspec_timeScan]
        set m_objDoseScan [$m_deviceFactory createOperation microspec_doseScan]

        set m_objSnapshotStatus \
        [$m_deviceFactory createString microspec_snapshot_status]

        set m_objPhiStatus \
        [$m_deviceFactory createString microspec_phiScan_status]

        set m_objTimeStatus \
        [$m_deviceFactory createString microspec_timeScan_status]

        set m_objDoseStatus \
        [$m_deviceFactory createString microspec_doseScan_status]

        set m_objWrapStatus [$m_deviceFactory createString spectroWrap_status]
        set m_objDefault [$m_deviceFactory createString microspec_default]

        foreach obj [list \
        $m_objSnapshotStatus \
        $m_objPhiStatus \
        $m_objTimeStatus \
        $m_objDoseStatus \
        ] {
            $obj createAttributeFromKey user_counter
            $obj createAttributeFromKey user_prefix
            $obj createAttributeFromKey user_dir
            $obj createAttributeFromKey start
            $obj createAttributeFromKey end
            $obj createAttributeFromKey step_size
        }
        $m_objDoseStatus createAttributeFromKey energy
        $m_objDoseStatus createAttributeFromKey attenuation
        $m_objDoseStatus createAttributeFromKey gonio_phi
        $m_objDoseStatus createAttributeFromKey beam_width
        $m_objDoseStatus createAttributeFromKey beam_height
        $m_objWrapStatus createAttributeFromKey refValid
        $m_objWrapStatus createAttributeFromKey darkValid
        $m_objWrapStatus createAttributeFromKey refWarning

        itk_component add pw_h {
            iwidgets::panedwindow $itk_interior.pwh \
            -orient horizontal
        } {
        }
        $itk_component(pw_h) add up   -minimum 50 -margin 2
        $itk_component(pw_h) add down -minimum 50 -margin 2
        set upSite   [$itk_component(pw_h) childsite 0]
        set downSite [$itk_component(pw_h) childsite 1]
        $itk_component(pw_h) fraction 70 30

        # create the scan mode radio buttons
        itk_component add modeRadio {
            iwidgets::radiobox $upSite.modeRadio \
            -labeltext "Scan Mode" \
            -labelpos nw \
            -labelfont $_smallFont \
            -selectcolor red\
            -command "$this handleModeSelect"
        } {
        }

        [$itk_component(modeRadio) component label] configure -font $_largeFont


        # create the help frame
        itk_component add helpLabeledFrame {
            iwidgets::Labeledframe $upSite.helpFrame
        }

        set helpFrame [$itk_component(helpLabeledFrame) childsite]
        pack propagate $helpFrame 1

        itk_component add helpText {
            text $helpFrame.text \
            -font $_smallFont \
            -relief flat \
            -wrap word \
            -width 36 \
            -height 2
        } {
        }
        # create the parameters labeled frame
        itk_component add parameterLabeledFrame {
            iwidgets::Labeledframe $upSite.parameterFrame \
            -labeltext "Scan Parameters" \
            -ipadx 0 \
            -labelfont $_largeFont \
            -labelpos nw
        } {
        }

        set parameterFrame [$itk_component(parameterLabeledFrame) childsite]

        itk_component add buttonF {
            frame $parameterFrame.buttonF
        } {
        }
        set buttonSite $itk_component(buttonF)

        itk_component add updateButton {
            DCS::Button $buttonSite.u \
            -text "Update" \
            -width 5 \
            -pady 0 \
            -command "$this updateParameters" 
        } {
        }

        itk_component add defaultButton {
            DCS::Button $buttonSite.d \
            -text "Default" \
            -width 5 \
            -pady 0 \
            -command "$this defaultParameters" 
        } {
        }
        pack $itk_component(defaultButton) -side left
        pack $itk_component(updateButton) -side left

        itk_component add fileCounter {
            DCS::Entry $parameterFrame.filecounter \
            -state labeled \
            -entryType string \
            -entryWidth 15 \
            -entryMaxLength 128 \
            -entryJustify center \
            -promptText "Next Scan Num" \
            -promptWidth 15 \
            -shadowReference 1 \
            -onlyMatchNumber 1 \
        } {}

        # make the filename root entry
        itk_component add fileRoot {
            DCS::Entry $parameterFrame.fileroot \
            -entryType field \
            -entryWidth 20 \
            -entryJustify center \
            -entryMaxLength 128 \
            -promptText "Prefix" \
            -promptWidth 10 \
            -shadowReference 1 \
            -onSubmit "$this setAttribute user_prefix %s" \
        } {}

        # make the data directory entry
        itk_component add directory {
            DCS::DirectoryEntry $parameterFrame.dir \
            -entryType rootDirectory \
            -entryWidth 20 \
            -entryJustify left \
            -entryMaxLength 128 \
            -promptText "Directory" \
            -promptWidth 10 \
            -shadowReference 1 \
            -entryMaxLength 128 \
            -onSubmit "$this setAttribute user_dir %s" \
        } {}

        set pmpWidth 20
        set eWidth 10

        itk_component add start {
            DCS::Entry $parameterFrame.start \
            -promptWidth $pmpWidth \
            -entryWidth $eWidth \
            -promptText "Start Phi" \
            -unitsList "deg" \
            -units "deg" \
            -leaveSubmit 1 \
            -entryType float \
            -entryJustify right \
            -autoConversion 1 \
            -shadowReference 1 \
            -onSubmit "$this setAttribute start %s" \
        } {
        }

        itk_component add end {
            DCS::Entry $parameterFrame.end \
            -promptWidth $pmpWidth \
            -entryWidth $eWidth \
            -promptText "End Phi" \
            -unitsList "deg" \
            -units "deg" \
            -leaveSubmit 1 \
            -entryType float \
            -entryJustify right \
            -autoConversion 1 \
            -shadowReference 1 \
            -onSubmit "$this setAttribute end %s" \
        } {
        }

        itk_component add step {
            DCS::Entry $parameterFrame.step \
            -promptWidth $pmpWidth \
            -entryWidth $eWidth \
            -promptText "Step" \
            -unitsList "deg" \
            -units "deg" \
            -leaveSubmit 1 \
            -entryType float \
            -entryJustify right \
            -autoConversion 1 \
            -shadowReference 1 \
            -onSubmit "$this setAttribute step_size %s" \
        } {
        }

        set mWidth 20
        itk_component add energy {
            DCS::MotorViewEntry $parameterFrame.energy \
            -alterUpdateSubmit 0 \
            -leaveSubmit 1 \
            -checkLimits -1 \
            -device ::device::energy \
            -showPrompt 1 \
            -entryType positiveFloat \
            -entryJustify right \
            -unitsList { \
            eV {-decimalPlaces 3 -promptText "Energy"} \
            keV {-decimalPlaces 4 -promptText "Energy"} \
            A {-decimalPlaces 6 -promptText "Wavelength"} \
            } \
            -entryWidth 10 \
            -promptWidth $mWidth \
            -units eV \
            -unitsWidth 3 \
            -autoConversion 1 \
            -shadowReference 1 \
            -escapeToDefault 0 \
            -onSubmit "$this setAttribute energy %s" \
            -alternateShadowReference "$m_objDoseStatus energy" \
        } {
        }

        itk_component add attenuation {
            DCS::MotorViewEntry $parameterFrame.att \
            -alterUpdateSubmit 0 \
            -checkLimits -1 \
            -leaveSubmit 1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -promptText "Attenuation" \
            -entryType positiveFloat \
            -entryJustify right \
            -unitsList % \
            -entryWidth 10 \
            -promptWidth $mWidth \
            -unitsWidth 3 \
            -units % \
            -autoConversion 1 \
            -escapeToDefault 0 \
            -shadowReference 1 \
            -onSubmit "$this setAttribute attenuation %s" \
            -alternateShadowReference "$m_objDoseStatus attenuation" \
        } {
        }

        itk_component add gonio_phi {
            DCS::MotorViewEntry $parameterFrame.phi \
            -alterUpdateSubmit 0 \
            -checkLimits -1 \
            -leaveSubmit 1 \
            -unitsList deg \
            -units deg \
            -autoMenuChoices 0 \
            -menuChoices {0.000 45.000 90.000 135.000 180.000 225.000 270.000 \
            315.000 360.000} \
            -device ::device::gonio_phi \
            -showPrompt 1 \
            -promptText "Phi" \
            -entryType float \
            -entryJustify right \
            -entryWidth 10 \
            -promptWidth $mWidth \
            -unitsWidth 3 \
            -autoConversion 1 \
            -shadowReference 1 \
            -escapeToDefault 0 \
            -onSubmit "$this setAttribute gonio_phi %s" \
            -alternateShadowReference "$m_objDoseStatus gonio_phi" \
        } {
        }

        itk_component add beam_size {
            BeamSizeEntry $parameterFrame.beam_size \
            -onWidthSubmit  "$this setAttribute beam_width %s" \
            -onHeightSubmit "$this setAttribute beam_height %s" \
            -alterUpdateSubmit 0 \
            -alternateShadowReference $m_objDoseStatus \
        } {
        }

        itk_component add snapshot {
            SimpleImageView $downSite.snapshot
        } {
        }

        itk_component add refWarning {
            label $upSite.refw \
            -text "Reference Warning" \
            -foreground red \
        } {
        }

        frame $upSite.controlF
        set controlSite $upSite.controlF

        itk_component add startButton {
            DCS::Button $controlSite.start \
            -text "Start" \
            -command "$this handleStartButton" \
            -font "helvetica -14 bold" -width 6
        } {
        }

        itk_component add stop {
            ::DCS::Button  $controlSite.stop \
            -systemIdleOnly 0 \
            -text "Stop" \
            -font "helvetica -14 bold" \
            -width 6 \
            -command "$this handleStopButton"
        } {
        }

        itk_component add abort {
            ::DCS::Button  $controlSite.abort \
            -text "Abort" \
            -background \#ffaaaa \
            -activebackground \#ffaaaa \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -font "helvetica -14 bold" \
            -width 6 \
        } {
        }

        pack $itk_component(startButton) -side left -expand 1
        pack $itk_component(stop)        -side left -expand 1
        pack $itk_component(abort)       -side left -expand 1

        $itk_component(modeRadio) add snapshot \
        -text "Snapshot" \

        $itk_component(modeRadio) add phi_scan  \
        -text "Phi-Rotation Mode"

        $itk_component(modeRadio) add time_scan \
        -text "Time Mode" \

        $itk_component(modeRadio) add dose_scan \
        -text "Monitor X-Ray Exposure"

        $itk_component(modeRadio) select phi_scan

        pack $itk_component(helpText)

        #grid rowconfigure $itk_interior 0 -weight 0
        #grid rowconfigure $itk_interior 1 -weight 0
        #grid rowconfigure $itk_interior 2 -weight 0
        #grid rowconfigure $itk_interior 3 -weight 0
        #grid rowconfigure $itk_interior 4 -weight 0
        grid rowconfigure $upSite 4 -weight 10

        grid $itk_component(modeRadio)             -row 0 -column 0 -sticky news
        grid $itk_component(helpLabeledFrame)      -row 1 -column 0 -sticky news
        grid $itk_component(parameterLabeledFrame) -row 2 -column 0 -sticky news
        grid $controlSite                          -row 4 -column 0 -sticky new

        pack $itk_component(snapshot) -side bottom -expand 1 -fill both

        pack $itk_component(pw_h) -side top -expand 1 -fill both

        ::mediator register $this $m_objWrapStatus refWarning \
        handleRefWarningUpdate

        eval itk_initialize $args
        announceExist
        set m_inSwitching 0

        $itk_component(abort) configure \
        -command "$itk_option(-controlSystem) abort"

        $itk_component(startButton) addInput \
        "$m_objWrapStatus refValid 1 {need take reference first}"
        $itk_component(startButton) addInput \
        "$m_objWrapStatus darkValid 1 {need take dark first}"
    }
}
body MicroSpecModeWidget::handleModeSelect { } {
    set m_inSwitching 1

    set currentMode [$itk_component(modeRadio) get]
    switch -exact -- $currentMode {
        default -
        phi_scan {
            set text "Determine the best phi angle to use for optical Absorbance measurements."

            set stringName $m_objPhiStatus
            set txtStart "Start Phi"
            set txtEnd   "End Phi"
            set txtStep  "Step"
            set units deg
        }
        time_scan {
            set text "Measure Absorbance Over a Range of Time"
            set stringName $m_objTimeStatus
            set txtStart "Not Used"
            set txtEnd   "Monitoring Duration"
            set txtStep  "Collect Spectrum Every"
            set units s
        }
        dose_scan {
            set text "Measure change of Absorbance with X-ray Exposure"
            set stringName $m_objDoseStatus
            set txtStart "Not Used"
            set txtEnd   "Monitoring Duration"
            set txtStep  "Collect Spectrum Every"
            set units s
        }
        snapshot {
            set text "Measure a Single Absorption Scan"
            set stringName $m_objSnapshotStatus
            set txtStart "Not Used"
            set txtEnd   "Not Used"
            set txtStep  "Not Used"
            set units ""
        }
    }
    $itk_component(helpText) delete 0.0 end
    $itk_component(helpText) insert end $text

    if {$currentMode == "snapshot"} {
        set cntPrompt "Next Shot Num"
    } else {
        set cntPrompt "Next Scan Num"
    }

    $itk_component(fileCounter)  configure \
    -promptText $cntPrompt \
    -reference "$stringName user_counter"

    $itk_component(fileRoot)  configure -reference "$stringName user_prefix"
    $itk_component(directory) configure -reference "$stringName user_dir"

    $itk_component(start) configure \
    -promptText $txtStart \
    -unitsList $units \
    -units $units \
    -reference "$stringName start"

    $itk_component(end) configure \
    -promptText $txtEnd \
    -unitsList $units \
    -units $units \
    -reference "$stringName end"

    $itk_component(step) configure \
    -promptText $txtStep \
    -unitsList $units \
    -units $units \
    -reference "$stringName step_size"

    set parameterFrame [$itk_component(parameterLabeledFrame) childsite]
    set wList [pack slaves $parameterFrame]
    if {$wList != ""} {
        eval pack forget $wList
    }

    pack $itk_component(buttonF) -side top -anchor n
    pack $itk_component(fileCounter) -side top -anchor w
    pack $itk_component(fileRoot) -side top -anchor w
    pack $itk_component(directory) -side top -anchor w

    switch -exact -- $currentMode {
        dose_scan {
            pack $itk_component(end)            -side top -anchor w
            pack $itk_component(step)           -side top -anchor w
            pack $itk_component(energy)         -side top -anchor w
            pack $itk_component(attenuation)    -side top -anchor w
            pack $itk_component(gonio_phi)      -side top -anchor w
            pack $itk_component(beam_size)      -side top -anchor e
        }
        time_scan {
            pack $itk_component(end)            -side top -anchor w
            pack $itk_component(step)           -side top -anchor w
        }
        phi_scan {
            pack $itk_component(start)          -side top -anchor w
            pack $itk_component(end)            -side top -anchor w
            pack $itk_component(step)           -side top -anchor w
        }
        snapshot {
        }
    }

    set m_inSwitching 0
    updateRegisteredComponents mode

    if {[catch {dict get $m_snapshot $currentMode} currentSnapshot]} {
        set currentSnapshot ""
    }
    $itk_component(snapshot) configure -snapshot $currentSnapshot
    puts "display $currentSnapshot"
}
body MicroSpecModeWidget::setAttribute { args } {
    if {$m_inSwitching} {
        ### skip, it is caused by switching mode and reference
        return
    }

    set ll [llength $args]
    if {[expr $ll % 2]} {
        log_error wrong number of arguments for setAttribute
        return
    }

    set currentMode [$itk_component(modeRadio) get]
    puts "setAttriubte mode=$currentMode $args"

    eval $m_objWrap startOperation set_parameters $currentMode $args
}
body MicroSpecModeWidget::updateParameters { } {
    set nvList ""
    set currentMode [$itk_component(modeRadio) get]
    set defaultField [getDefaultFields $currentMode]
    set defaultPrefix [lindex $defaultField 0]
    ##########################################
    #### dir and prefix copied from madScan
    set user [$itk_option(-controlSystem) getUser]
    set obj [$m_deviceFactory createString crystalStatus]
    set fileRoot [$obj getFieldByIndex 0]
    if {$fileRoot != ""} {
        set dirObj [$m_deviceFactory createString screeningParameters]
        set rootDir [$dirObj getFieldByIndex 2]
        set subDir  [$dirObj getFieldByIndex 4]

        set prefix ${fileRoot}_$defaultPrefix
        set dir    [file join $rootDir $subDir]
        checkUsernameInDirectory dir $user
        lappend nvList user_prefix $prefix user_dir $dir
    }

    if {$currentMode == "dose_scan"} {
        ### update motors to current position
        foreach motor {energy attenuation gonio_phi} {
            set currentPosition [lindex [::device::$motor getScaledPosition] 0]
            if {![::device::$motor limits_ok currentPosition]} {
                log_warning $motor current position is out of limits, \
                using $currentPosition
            }
            lappend nvList $motor $currentPosition
        }
        global gMotorBeamWidth
        global gMotorBeamHeight
        foreach motor [list $gMotorBeamWidth $gMotorBeamHeight] \
        key {beam_width beam_height} {
            set currentPosition [lindex [::device::$motor getScaledPosition] 0]
            if {![::device::$motor limits_ok currentPosition]} {
                log_warning $motor current position is out of limits, \
                using $currentPosition
            }
            lappend nvList $key $currentPosition
        }
    } elseif {$currentMode == "phi_scan"} {
        set currentPosition [lindex [::device::gonio_phi getScaledPosition] 0]
        lappend nvList \
        start $currentPosition \
        end [expr $currentPosition + 180.0]
    }

    eval setAttribute $nvList
}
body MicroSpecModeWidget::defaultParameters { } {
    set user [$itk_option(-controlSystem) getUser]
    set currentMode [$itk_component(modeRadio) get]
    set nvList ""
    set defaultField [getDefaultFields $currentMode]
    switch -exact -- $currentMode {
        snapshot {
            foreach {prefix dir} $defaultField break
            checkUsernameInDirectory dir $user
            lappend nvList user_prefix $prefix user_dir $dir
        }
        phi_scan -
        time_scan {
            foreach {prefix dir start end step} $defaultField break
            checkUsernameInDirectory dir $user
            lappend nvList \
            user_prefix $prefix \
            user_dir $dir \
            start $start \
            end $end \
            step_size $step

            ### start for time_scan is ignore and hardcoded to 0 in dcss.
        }
        dose_scan {
            foreach {prefix dir start end step energy att phi width height} \
            $defaultField break
            checkUsernameInDirectory dir $user
            lappend nvList \
            user_prefix $prefix \
            user_dir $dir \
            start $start \
            end $end \
            step_size $step \
            energy $energy \
            attenuation $att \
            gonio_phi $phi \
            beam_width $width \
            beam_height $height
        }
    }
    eval setAttribute $nvList
    puts "default for mode=$currentMode: $nvList"
}
body MicroSpecModeWidget::handleStartButton { } {
    set currentMode [$itk_component(modeRadio) get]
    switch -exact -- $currentMode {
        default -
        phi_scan {
            set op $m_objPhiScan
        }
        time_scan {
            set op $m_objTimeScan
        }
        dose_scan {
            set op $m_objDoseScan
        }
        snapshot {
            set op $m_objSnapshot
        }
    }
    $op startOperation

    set cmd $itk_option(-onStartButton)
    if {$cmd != ""} {
        eval $cmd
    }
}
body MicroSpecModeWidget::handleStopButton { } {
    foreach op [list \
    microspec_timeScan \
    microspec_phiScan \
    microspec_doseScan \
    microspec_snapshot \
    ] {
        $itk_option(-controlSystem) sendMessage "gtos_stop_operation $op"
    }
}
body MicroSpecModeWidget::handleRefWarningUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }

    $itk_component(refWarning) configure -text $contents_

    if {$contents_ != ""} {
        grid $itk_component(refWarning) -row 3 -column 0 -sticky n
    } else {
        grid forget $itk_component(refWarning)
    }
}
class MicroSpecPlotView {
    inherit ::itk::Widget

    public method constructor { mode args }

	private method createMarker { mark_num }

    public method setLogger { widget } { set m_logger $widget }
    public method updateLog 

    public method addToMainMenu { name label cmd } {
        $itk_component(graph) addToMainMenu $name $label $cmd
    }

    public method setWavelengthList { wList }
    public method setReference { cList }
    public method setDark { cList }
    public method setResult { mtrName phi title rList aList tList {t0 0}}
    public method setCurrentAsBaseline { }
    public method setCurrentAsOverlay { }
    public method deleteAllOverlays { }
    public method clear { } {
        if {$m_cleared} {
            return
        }

        $m_rawXVect set ""
        $m_rawYVect set ""
        $m_refYVect set ""
        $m_drkYVect set ""
        $m_absYVect set ""
        $m_trnYVect set ""
        $itk_component(graph) configure \
        -title "No data available yet" \

        $m_logger clear

        set m_cleared 1
    }

    public method setupBaseline { }

    public method changeChoice { choice } {
        switch -exact -- $choice {
            m1 {
                set mark $m_1dMarker1
                set text Marker1
            }
            m2 {
                set mark $m_1dMarker2
                set text Marker2
            }
            m3 {
                set mark $m_1dMarker3
                set text PercentMarker
            }
            zoom -
            default {
                $itk_component(graph) setupZoomButton
                set text Zoom 
                $itk_component(leftbutton) configure -text $text
                return
            }
        }
        set bg [$itk_component(graph) getBltGraph]
	    bind $bg <ButtonPress-1> "$mark drag %x %y"
	    bind $bg <B1-Motion> "$mark drag %x %y"
	    bind $bg <ButtonRelease-1> "$mark drag %x %y"
        $itk_component(leftbutton) configure -text $text
    }

    destructor {
    }

    private variable m_cleared 1
    private variable m_rawXVect
    private variable m_rawYVect
    private variable m_refYVect
    private variable m_drkYVect
    private variable m_absYVect
    private variable m_trnYVect

    private variable m_subTraceRaw ""
    private variable m_subTraceRef ""
    private variable m_subTraceDrk ""
    private variable m_subTraceAbs ""
    private variable m_subTraceTrn ""

    ### to support baseline
    private variable m_origRaw
    private variable m_origAbs
    private variable m_origTrn
    private variable m_baseRaw
    private variable m_baseAbs
    private variable m_baseTrn
    ### need to remember the labels so they can be turned on off with
    ### right label.
    private variable m_baseRawLabel ""
    private variable m_baseAbsLabel ""
    private variable m_baseTrnLabel ""

    private variable m_1dMarker1 ""
    private variable m_1dMarker2 ""
    private variable m_1dMarker3 ""

    protected variable m_baselineEnabled 0
    protected variable m_motorName ""
    protected variable m_position ""

    protected variable m_logger ""
}
body MicroSpecPlotView::constructor { args } {
    set m_rawXVect [blt::vector ::[DCS::getUniqueName]]
    set m_rawYVect [blt::vector ::[DCS::getUniqueName]]
    set m_refYVect [blt::vector ::[DCS::getUniqueName]]
    set m_drkYVect [blt::vector ::[DCS::getUniqueName]]
    set m_absYVect [blt::vector ::[DCS::getUniqueName]]
    set m_trnYVect [blt::vector ::[DCS::getUniqueName]]

    set m_origRaw [blt::vector ::[DCS::getUniqueName]]
    set m_origAbs [blt::vector ::[DCS::getUniqueName]]
    set m_origTrn [blt::vector ::[DCS::getUniqueName]]
    set m_baseRaw [blt::vector ::[DCS::getUniqueName]]
    set m_baseAbs [blt::vector ::[DCS::getUniqueName]]
    set m_baseTrn [blt::vector ::[DCS::getUniqueName]]

    set graphSite $itk_interior

    itk_component add graph {
        DCS::Graph $graphSite.g \
        -title "MicroSpectrometer" \
        -xLabel "Wavelength (nm)" \
        -yLabel "Spectrum" \
        -plotbackground white \
        -enableOverlay 1 \
        -noDelete 1
    } {
    }

    frame $itk_interior.bottom
    set buttonSite $itk_interior.bottom

    itk_component add saveBaseline {
        button $buttonSite.sb \
        -text "Use Current As Baseline" \
        -command "$this setCurrentAsBaseline"
    } {
    }

    itk_component add setOverlay {
        button $buttonSite.ovv \
        -text "Use Current As Overlay" \
        -command "$this setCurrentAsOverlay"
    } {
    }

    itk_component add deleteOverlay {
        button $buttonSite.dol \
        -text "Delete All Overlays" \
        -command "$this deleteAllOverlays"
    } {
    }

    itk_component add baseline {
        checkbutton $buttonSite.baseline \
        -text "Subtract Baseline from Current" \
        -variable [scope m_baselineEnabled] \
        -command "$this setupBaseline"
    } {
    }

    frame $buttonSite.lbFrame
    set lbSite $buttonSite.lbFrame

    itk_component add lbLabel {
        label $lbSite.label \
        -text "Left Button:"
    } {
    }
    itk_component add leftbutton {
        menubutton $lbSite.leftbutton \
        -text Zoom \
        -width 15 \
        -relief sunken \
        -background white \
        -menu $lbSite.leftbutton.menu
    } {
    }

    itk_component add lbArrow {
        label $lbSite.lbArrow \
        -image [DCS::MenuEntry::getArrowImage] \
        -width 16 \
        -anchor c \
        -relief raised
    } {
    }

    itk_component add lbMenu {
        menu $itk_component(leftbutton).menu \
        -tearoff 0 \
        -activebackground blue \
        -activeforeground white
    } {
    }
    $itk_component(lbMenu) add command \
    -label "Zoom" \
    -command "$this changeChoice zoom"

    $itk_component(lbMenu) add command \
    -label "Marker1" \
    -command "$this changeChoice m1"

    $itk_component(lbMenu) add command \
    -label "Marker2" \
    -command "$this changeChoice m2"

    $itk_component(lbMenu) add command \
    -label "PercentMarker" \
    -command "$this changeChoice m3"

    pack $itk_component(lbLabel)    -side left
    pack $itk_component(leftbutton) -side left
    pack $itk_component(lbArrow)    -side left
    
    if {[info tclversion] < 8.4} {
        set cmdP tkMbPost
        set cmdU tkMbButtonUp
    } else {
        set cmdP tk::MbPost
        set cmdU tk::MbButtonUp
    }
    bind $itk_component(lbArrow) <Button-1> \
    "$cmdP $itk_component(leftbutton) %X %Y"

    bind $itk_component(lbArrow) <ButtonRelease-1> \
    "$cmdU $itk_component(leftbutton)"

    pack $lbSite                        -side left
    pack $itk_component(setOverlay)     -side left
    pack $itk_component(deleteOverlay)  -side left
    pack $itk_component(saveBaseline)   -side left
    pack $itk_component(baseline)       -side left

    $itk_component(graph) createTrace scope {"Wavelength (nm)"} $m_rawXVect

    set m_subTraceRaw [$itk_component(graph) createSubTrace scope raw \
    {"Raw" "Counts"} $m_rawYVect -color green]

    $itk_component(graph) removeFileAccess
    $itk_component(graph) configure -yLabel Absorbance

	# create the vertical marker
    createMarker 1
    createMarker 2
    createMarker 3
    #link them into a pair to display delta
    $m_1dMarker1 configure \
    -pair $m_1dMarker2 \
    -thirdPercentMark $m_1dMarker3

    $m_1dMarker2 configure \
    -pair $m_1dMarker1 \
    -thirdPercentMark $m_1dMarker3

    $m_1dMarker3 configure \
    -firstMark $m_1dMarker1 \
    -secondMark $m_1dMarker2 \
    -percent 10.0

    pack $itk_component(graph) -side top -expand 1 -fill both
    pack $itk_interior.bottom -side bottom -fill x

    eval itk_initialize $args

    set m_subTraceRef [$itk_component(graph) createSubTrace scope ref \
    {"Reference" "Counts"} $m_refYVect -color red]

    set m_subTraceDrk [$itk_component(graph) createSubTrace scope dark \
    {"Dark" "Counts"} $m_drkYVect -color brown]

    set m_subTraceAbs [$itk_component(graph) createSubTrace scope absr \
    {"Absorbance" "Calculation"} $m_absYVect -color black]

    set m_subTraceTrn [$itk_component(graph) createSubTrace scope trns \
    {"Transmittance" "Calculation"} $m_trnYVect -color blue]
}
body MicroSpecPlotView::updateLog { } {
    set bad 0
    if {[$m_rawXVect length] ==0} {
        puts "$this updateLog: xVect length is 0"
        incr bad
    }
    if {[$m_rawYVect length] ==0} {
        puts "$this updateLog: raw length is 0"
        incr bad
    }
    if {[$m_absYVect length] ==0} {
        puts "$this updateLog: abs length is 0"
        incr bad
    }
    if {[$m_trnYVect length] ==0} {
        puts "$this updateLog: trn length is 0"
        incr bad
    }
    if {$bad} {
        return
    }

    set wList  [$m_rawXVect range 0 end]
    set rList  [$m_rawYVect range 0 end]
    set aList  [$m_absYVect range 0 end]
    set tList  [$m_trnYVect range 0 end]

    $m_logger clear
    set wWidth 10
    set rWidth 10
    set aWidth 15
    set tWidth 15

    set header [format "%${wWidth}s" "wavelength"]
    append header " "
    append header [format "%${rWidth}s" "raw"]
    append header " "
    append header [format "%${aWidth}s" "absorbance"]
    append header " "
    append header [format "%${aWidth}s" "transmittance"]
    $m_logger log_string $header warning 0

    set fmtW "%#$wWidth.1f"
    set fmtR "%$rWidth.0f"
    set fmtA "%#$aWidth.3f"
    set fmtT "%#$tWidth.3f"

    foreach w $wList r $rList a $aList t $tList {
        set line \
        "[format $fmtW $w] [format $fmtR $r] [format $fmtA $a] [format $fmtT $a]"
        $m_logger log_string $line warning 0
    }
}
body MicroSpecPlotView::createMarker { mark_num } {
    if {$mark_num != 1 && $mark_num != 2 && $mark_num != 3} return

    upvar 0 m_1dMarker$mark_num mark
    if {$mark != ""} {
        return
    }

    switch -exact -- $mark_num {
        1 {
            set mark_color red
            set mark_button 1
        }
        2 {
            set mark_color #00a040
            set mark_button 3
        }
        3 {
            set mark_color brown
            set mark_button 2
        }
    }
    set markervObj [$itk_component(graph) createCrosshairsMarker \
    "crosshairs$mark_num" -1 0 "Wavelength (nm)" "Counts" \
    -width 2 \
    -hide 1 \
    -color $mark_color \
    ]

	bind [$itk_component(graph) getBltGraph] <Control-ButtonPress-$mark_button> "$markervObj drag %x %y"
	bind [$itk_component(graph) getBltGraph] <Control-B$mark_button-Motion> "$markervObj drag %x %y"
	bind [$itk_component(graph) getBltGraph] <Control-ButtonRelease-$mark_button> "$markervObj drag %x %y"

    set mark $markervObj
}
body MicroSpecPlotView::setWavelengthList { wList } {
    set m_cleared 0
    puts "$this get wavelength=[llength $wList]"
    $m_rawXVect set $wList
}
body MicroSpecPlotView::setReference { cList } {
    set m_cleared 0
    $m_refYVect set $cList
}
body MicroSpecPlotView::setDark { cList } {
    set m_cleared 0
    $m_drkYVect set $cList
}
body MicroSpecPlotView::setCurrentAsBaseline { } {
    $m_origRaw dup $m_baseRaw
    $m_origAbs dup $m_baseAbs
    $m_origTrn dup $m_baseTrn

    set rLabel [$m_subTraceRaw getLabel]
    set m_baseRawLabel "b:$rLabel"
    set aLabel [$m_subTraceAbs getLabel]
    set tLabel [$m_subTraceTrn getLabel]
    set m_baseAbsLabel "b:$aLabel"
    set m_baseTrnLabel "b:$tLabel"
    setupBaseline
}
body MicroSpecPlotView::setCurrentAsOverlay { } {
    foreach subTrace [list $m_subTraceRaw $m_subTraceAbs $m_subTraceTrn] {
        if {![$subTrace getHide]} {
            $itk_component(graph) makeOverlay $subTrace
        }
    }
}
body MicroSpecPlotView::deleteAllOverlays { } {
    $itk_component(graph) deleteAllOverlay
}
body MicroSpecPlotView::setResult { motorName p title rList aList tList {t0 0}} {
    set m_cleared 0
    set m_motorName $motorName
    set m_position $p

    set motorDisplayName [getMotorDisplayName $m_motorName]

    $itk_component(graph) configure \
    -title $title

    $m_origRaw set $rList
    $m_origAbs set $aList
    $m_origTrn set $tList
    if {$m_baselineEnabled} {
        $m_rawYVect expr "$m_origRaw - $m_baseRaw"
        $m_absYVect expr "$m_origAbs - $m_baseAbs"
        $m_trnYVect expr "$m_origTrn - $m_baseTrn"
    } else {
        $m_origRaw dup $m_rawYVect
        $m_origAbs dup $m_absYVect
        $m_origTrn dup $m_trnYVect
    }

    set title "$motorDisplayName=[format %.3f $p]"
    $m_subTraceRaw setLabel "r:$title"
    $m_subTraceAbs setLabel "a:$title"
    $m_subTraceTrn setLabel "t:$title"
    updateLog

    if {$t0 && ![$itk_component(graph) isInZoom]} {
        set xMin [$m_rawXVect index 0]
        set xMax [$m_rawXVect index end]
        
        set yMax [lindex $aList 0]
        set yMin $yMax
        foreach y $aList {
            if {$y > $yMax} {
                set yMax $y
            } elseif {$y < $yMin} {
                set yMin $y
            }
        }

        $itk_component(graph) manualSetZoom $xMin $yMin $xMax $yMax
    }
}
body MicroSpecPlotView::setupBaseline { } {
    $itk_component(graph) deleteSubTraces base_raw
    $itk_component(graph) deleteSubTraces base_abrb
    $itk_component(graph) deleteSubTraces base_trns

    if {$m_baselineEnabled} {
        $m_rawYVect expr "$m_origRaw - $m_baseRaw"
        $m_absYVect expr "$m_origAbs - $m_baseAbs"
        $m_trnYVect expr "$m_origTrn - $m_baseTrn"

        set oRaw [$itk_component(graph) createSubTrace scope base_raw \
        {"Raw" "Counts"} $m_baseRaw -color red -isOverlay 1]
        $oRaw setLabel $m_baseRawLabel
        set oAbs [$itk_component(graph) createSubTrace scope base_abrb \
        {"Absorbance" "Calculation"} $m_baseAbs -color red -isOverlay 1]

        set oTrn [$itk_component(graph) createSubTrace scope base_trns \
        {"Transmittance" "Calculation"} $m_baseTrn -color red -isOverlay 1]

        $oAbs setLabel $m_baseAbsLabel
        $oTrn setLabel $m_baseTrnLabel
    } else {
        $m_origRaw dup $m_rawYVect
        $m_origAbs dup $m_absYVect
        $m_origTrn dup $m_trnYVect
    }
    updateLog
}
class MicroSpecHardwareView {
    inherit ::itk::Widget

    constructor { args} {
        global BLC_IMAGES
        set microSpecImage [image create photo \
        -file "$BLC_IMAGES/microspec_user.gif" \
        -palette "8/8/8"]

        itk_component add canvas {
            canvas $itk_interior.canvas
        } {
            keep -width  -height
        }

        $itk_component(canvas) create image 0 0 \
        -anchor nw \
        -image $microSpecImage

        itk_component add targetIn {
            DCS::MoveMotorsToTargetButton $itk_component(canvas).tin \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -width 8 \
            -text "Insert"
        } {
        }
        itk_component add targetMid {
            DCS::MoveMotorsToTargetButton $itk_component(canvas).tmid \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -width 8 \
            -text "Remove"
        } {
        }

        itk_component add lightF {
            iwidgets::labeledframe $itk_component(canvas).lightF \
            -labeltext "Light Control"
        } {
        }
        set lightSite [$itk_component(lightF) childsite]
        itk_component add lightControl {
            MicroSpecLightWidget $lightSite.lc
        } {
        }
        pack $itk_component(lightControl)


        $itk_component(targetIn)  addMotor ::device::microspec_z_corr 0.0
        $itk_component(targetMid) addMotor ::device::microspec_z 30.0

        place $itk_component(targetMid) -x 140 -y 20
        place $itk_component(targetIn)  -x 220 -y 20
        place $itk_component(lightF)  -x 95 -y 525

        itk_component add calF {
            iwidgets::labeledframe $itk_interior.calF \
            -labeltext "Calculation Setup"
        } {
        }
        set calSite [$itk_component(calF) childsite]

        itk_component add calSetup {
            MicroSpecCalculationSetupView $calSite.setup \
            -stringName ::device::spectro_config
        } {
        }
        pack $itk_component(calSetup) -side left -fill both -expand 0

        itk_component add plot {
            SpectrometerView $itk_interior.plot \
            -purpose user_hardware
        } {
        }

        eval itk_initialize $args

        ### this is the image size
        $itk_component(canvas) configure -width 300 -height 616

        bind $itk_component(canvas) <Button-1> { puts "%x %y" }

        grid rowconfigure    $itk_interior 1 -weight 10
        grid columnconfigure $itk_interior 1 -weight 10

        grid $itk_component(canvas) -row 0 -column 0 -rowspan 2 -sticky nw
        grid $itk_component(calF)   -row 0 -column 1 -sticky news
        grid $itk_component(plot)   -row 1 -column 1 -sticky news
    }
}

class MicroSpecDataControl {
    inherit ::itk::Widget
    
    itk_option define -onNewScan onNewScan OnNewScan ""

    private variable m_mode     ""
    private variable m_data     ""
    private variable m_plot     ""
    private variable m_video    ""
    private variable m_initSent 0
    private variable m_currentIndex -1

    ## for moveButton
    private variable m_motorName ""
    private variable m_position ""

    public method loadFromGui { } {
        set types { { MicroSpect .yaml} {{All Files} *} }
        set path [tk_getOpenFile \
        -defaultextension ".yaml" \
        -filetypes $types \
        -title "Open a MicroSpec Scan" \
        ]

        if {$path != ""} {
            loadResult $path
        }
    }

    public method loadResult { path {index ""} } {
        $m_data loadFile $path
        if {[string is integer -strict $index]} {
            puts "moving slider to $index"
            after idle [code $itk_component(slider) setPosition $index]
        }
    }

    public method handleNumDataUpdate { - ready_ - num_ - }
    public method handleNewScan { - ready_ - contents_ - }
    public method handleMessageUpdate { - ready_ - contents_ - }
    public method updateDisplay { index }
    public method moveToPosition { }
    public method saveToFile { } {
        if {$m_currentIndex < 0} {
            log_error Data not available yet.
            return
        }
        set path [tk_getSaveFile -defaultextension ".csv"]
        $m_data saveResult $m_currentIndex $path
    }
    
    constructor { mode plotWidget videoWidget args } {
        set m_mode $mode
        set m_data [MicroSpectScanResult ::\#auto $mode]
        set m_plot $plotWidget
        set m_video $videoWidget

        itk_component add progress {
            DCS::Feedback $itk_interior.bar \
            -barheight 10 \
            -steps 100 \
            -attribute progress \
            -component $m_data \
        } {
        }

        itk_component add msg {
            label $itk_interior.msg \
            -anchor w \
            -justify left \
            -relief sunken \
            -text ""
        } {
        }

        itk_component add slider {
            DCSScale $itk_interior.slider \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -orient horizontal \
            -showvalue 0 \
            -from 0 \
            -command "$this updateDisplay"
        } {
        }

        frame $itk_interior.buttonF
        set buttonSite $itk_interior.buttonF

        itk_component add title {
            label $buttonSite.lll \
            -text title
        } {
        }

        itk_component add saveButton {
            button $buttonSite.save \
            -text "Save Current Image to CSV File" \
            -command "$this saveToFile" \
        } {
        }

        itk_component add moveButton {
            DCS::Button $buttonSite.move \
            -text "Move Motor to Position" \
            -width 27 \
            -command "$this moveToPosition" \
        } {
        }

        grid columnconfigure $buttonSite 0 -weight 5
        grid columnconfigure $buttonSite 2 -weight 5

        grid $itk_component(title)      -row 0 -column 0 -sticky w
        grid $itk_component(saveButton) -row 0 -column 1 -sticky news

        if {$mode == "phi_scan"} {
            grid $itk_component(moveButton) -row 0 -column 2 -sticky e
        }

        pack $itk_component(msg) -side top -fill x -anchor w
        pack $itk_component(progress) -side top -fill x
        pack $itk_component(slider)   -side top -fill x
        pack $itk_interior.buttonF    -side top -fill x

        eval itk_initialize $args

        $m_data register $this numData  handleNumDataUpdate
        $m_data register $this new_scan handleNewScan
        $m_data register $this message  handleMessageUpdate

        $itk_component(slider) addInput \
        "$m_data ready 1 {No data available yet}"
    }
}
body MicroSpecDataControl::handleNewScan { - ready_ - num_ - } {
    if {!$ready_} {
        return
    }
    $m_plot clear
    $m_video setSnapshot $m_mode ""
    set m_initSent 0
    set m_currentIndex -1

    $itk_component(title) configure \
    -foreground black \
    -text "No data available yet"

    set cmd $itk_option(-onNewScan)
    if {$cmd != ""} {
        eval $cmd
    }
}
body MicroSpecDataControl::handleNumDataUpdate { - ready_ - num_ - } {
    if {!$ready_ || $num_ <= 0} {
        return
    }
    set end [expr $num_ - 1]

    $itk_component(slider) configure -to $end

    if {!$m_initSent} {
        $m_plot setWavelengthList [$m_data getWavelengthList]
        $m_plot setReference      [$m_data getReference]
        $m_plot setDark           [$m_data getDark]

        ## init P0 as base and zoom on it.
        updateDisplay 0
        $m_plot setCurrentAsBaseline

        set m_initSent 1
    }

    ### this will call $m_plot setResult to last point
    $itk_component(slider) setPosition $end
}
body MicroSpecDataControl::handleMessageUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }

    if {[string match -nocase *error* "$contents_"] \
    ||  [string match -nocase *fail* "$contents_"] \
    ||  [string match -nocase *abort* "$contents_"] \
    ||  [string match -nocase *warn* "$contents_"] \
    } {
        set fg red
    } else {
        set fg blue
    }
    
    $itk_component(msg) configure \
    -foreground $fg \
    -text $contents_
}
body MicroSpecDataControl::updateDisplay { index } {
    set ll [$m_data getNumberOfResult]

    if {$index < 0 || $index >= $ll} {
        set m_currentIndex -1
        puts "bad index $index"
        $m_plot clear
        $m_video setSnapshot $m_mode ""
        return
    }

    set result   [$m_data getResult $index]
    set snapshot [$m_data getVideoSnapshot $index]

    foreach {m_motorName m_position title} $result break
    set motorDisplayName [getMotorDisplayName $m_motorName]
    set units [getMotorUnits $m_motorName]

    set fg black
    set txt "Current Image: $title"
    if {[regexp -nocase warn|error|fail $title]} {
        set fg red
        set txt "$title"
    }

    $itk_component(title) configure \
    -foreground $fg \
    -text $txt

    if {$m_motorName != "time"} {
        set iPos [expr int($m_position)]
        if {$iPos == $m_position} {
            set pDisplay $iPos
        } else {
            set pDisplay [format %.3f $m_position]
        }

        $itk_component(moveButton) configure \
        -text "Move $motorDisplayName to $pDisplay $units"
    } else {
        $itk_component(moveButton) configure \
        -text "cannot move time"
    }

    eval $m_plot setResult $result [expr $index == 0]
    eval $m_video setSnapshot $snapshot

    set m_currentIndex $index
}
body MicroSpecDataControl::moveToPosition { } {
    set deviceFactory [DCS::DeviceFactory::getObject]
    set obj [$deviceFactory getObjectName $m_motorName]
    $obj move to $m_position
}
class MicroSpecTab {
    inherit ::itk::Widget

    private variable m_currentMode phi_scan
    private variable m_currentTab Plot

    public method loadResult { mode path {index ""}}
    public method loadResultByName { path {index ""}} {
        if {[file isdirectory $path]} {
            set guess \
            [glob -directory $path -types f -nocomplain *_????????_??????.yaml]
            if {[llength $guess] != 1} {
                log_error failed to find the header file automatically in $path.
                return
            }
            set path $guess
            log_warning got the head file $path
        }

        set fname [file tail $path]
        set mode phi_scan
        if {[string first dose $fname] >= 0} {
            set mode dose_scan
        } elseif {[string first time $fname] >= 0} {
            set mode time_scan
        } elseif {[string first snapshot $fname] >= 0} {
            set mode snapshot
        }
        puts "parsed mode=$mode"
        loadResult $mode $path $index
    }

    public method handleModeChange { - ready_ - mode_ -}

    public method handleTabChange { - ready_ - tab_ - }

    public method selectPlotTab { } {
        $itk_component(notebook) select 0
    }
    public method selectModeAndTab { mode } {
        $itk_component(notebook) select 0
        $itk_component(modeSelect) setMode $mode
    }

    private method parseFileName { path }

    constructor { args } {
        itk_component add pw_v {
            iwidgets::panedwindow $itk_interior.pwv \
            -orient vertical
        } {
        }
        $itk_component(pw_v) add left  -minimum 50 -margin 2
        $itk_component(pw_v) add right -minimum 50 -margin 2
        set leftSite  [$itk_component(pw_v) childsite 0]
        set rightSite [$itk_component(pw_v) childsite 1]
        $itk_component(pw_v) fraction 30 70

        itk_component add modeSelect {
            MicroSpecModeWidget $leftSite.mode
        } {
        }

        itk_component add notebook {
            DCS::TabNotebook $rightSite.nb \
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
        $itk_component(notebook) add Plot       -label Plot
        $itk_component(notebook) add Log        -label Log
        $itk_component(notebook) add Hardware   -label Hardware

        set plotSite [$itk_component(notebook) childsite 0]
        set logSite  [$itk_component(notebook) childsite 1]
        set hwSite   [$itk_component(notebook) childsite 2]

        foreach mode {snapshot phi_scan time_scan dose_scan} {
            itk_component add ${mode}Plot {
                MicroSpecPlotView $plotSite.${mode}
            } {
            }

            itk_component add ${mode}Log {
                DCS::scrolledLog $logSite.${mode}
            } {
            }
            $itk_component(${mode}Plot) setLogger $itk_component(${mode}Log)

            itk_component add ${mode}Control {
                MicroSpecDataControl $rightSite.${mode} \
                $mode $itk_component(${mode}Plot) $itk_component(modeSelect)
            } {
            }

            $itk_component(${mode}Plot) addToMainMenu loadScan "load Scan" \
            "$itk_component(${mode}Control) loadFromGui"
        }

        pack $itk_component(phi_scanPlot) -expand 1 -side top -fill both
        pack $itk_component(phi_scanLog) -expand 1 -side top -fill both
   
        itk_component add hardware {
            MicroSpecHardwareView $hwSite.hardware
        } {
        }
        pack $itk_component(hardware) -expand 1 -side top -fill both

        pack $itk_component(modeSelect) -side top -expand 1 -fill both -anchor n

        pack $itk_component(phi_scanControl) -side bottom -fill x
        pack $itk_component(notebook)        -side top -expand 1 -fill both

        #grid $itk_component(notebook)        -row 0 -column 0 -sticky news
        #grid $itk_component(phi_scanControl) -row 1 -column 0 -sticky news

        pack $itk_component(pw_v) -side left -expand 1 -fill both

        eval itk_initialize $args

        $itk_component(modeSelect) register $this mode handleModeChange
        $itk_component(notebook) register $this activeTab handleTabChange

        $itk_component(notebook) select 0

        ## switch to Plot Tab only for this BluIce, which pressed Start button
        $itk_component(modeSelect) configure \
        -onStartButton "$this selectPlotTab"

        ## switch to Plot Tab even other BluIce started the scan
        #$itk_component(time_scanControl) configure \
        #-onNewScan "$this selectModeAndTab time_scan"
        #$itk_component(phi_scanControl) configure \
        #-onNewScan "$this selectModeAndTab phi_scan"
        #$itk_component(dose_scanControl) configure \
        #-onNewScan "$this selectModeAndTab dose_scan"
        #$itk_component(snapshotControl) configure \
        #-onNewScan "$this selectModeAndTab snapshot"
    }
}
body MicroSpecTab::handleModeChange { - ready_ - mode_ - } {
    if {!$ready_} {
        return
    }
    if {$m_currentMode == $mode_} {
        return
    }
    
    pack forget $itk_component(${m_currentMode}Plot)
    pack forget $itk_component(${m_currentMode}Log)
    pack forget $itk_component(${m_currentMode}Control)

    set m_currentMode $mode_

    pack $itk_component(${m_currentMode}Plot) -expand 1 -fill both
    pack $itk_component(${m_currentMode}Log)  -expand 1 -fill both

    if {$m_currentTab != "Hardware"} {
        pack $itk_component(${m_currentMode}Control) -side bottom -fill x
    }
}
body MicroSpecTab::handleTabChange { - ready_ - tab_ - } {
    if {!$ready_} {
        return
    }
    if {$m_currentTab == $tab_} {
        return
    }

    if {$tab_ == "Hardware"} {
        pack forget $itk_component(${m_currentMode}Control)
    } elseif {$m_currentTab == "Hardware"} {
        pack $itk_component(${m_currentMode}Control) \
        -side bottom -expand 0 -fill x
    }
    
    set m_currentTab $tab_
}
body MicroSpecTab::loadResult { mode path {index ""}} {
    switch -exact -- $mode {
        snapshot -
        phi_scan -
        time_scan -
        dose_scan {
        }
        default {
            log_error wrong mode $mode, not supported
            return
        }
    }
    if {[file isdirectory $path]} {
        set guess \
        [glob -directory $path -types f -nocomplain *_????????_??????.yaml]
        if {[llength $guess] != 1} {
            log_error failed to find the header file automatically in $path.
            return
        }
        set path $guess
        log_warning got the head file $path
    } elseif {$index == ""} {
        foreach {path index} [parseFileName $path] break
        puts "got header=$path index=$index"
    }

    set obj $itk_component(${mode}Control)
    $obj loadResult $path $index

    if {$index != ""} {
        log_warning $path loaded into mode $mode with index = $index
    } else {
        log_warning $path loaded into mode $mode
    }
}
body MicroSpecTab::parseFileName { path } {
    set fDir  [file dir $path]
    set fName [file tail $path]

    set fName [file root $fName]
    set eList [split $fName _]
    set ll [llength $eList]
    switch -exact -- $ll {
        5 {
            puts "user individual file"
            foreach {id mode dd tt index} $eList break
            set headerName ${id}_${mode}_${dd}_${tt}.yaml
            set headerPath [file join $fDir $headerName]
            puts "user individual file head=$headerPath index=$index"
        }
        4 {
            set e2 [lindex $eList 2]
            if {[string length $e2] == 8} {
                puts "user header file"
                set headerPath $path
                set index ""
            } else {
                puts "system individual file"
                #### system individual file
                foreach {id mode ss index} $eList break
                set headerName ${id}_${mode}_${ss}.yaml
                set headerPath [file join $fDir $headerName]
            }
        }
        3 {
            puts "system header file"
            set headerPath $path
            set index ""
        }
        default {
            puts "bad ll=$ll eList=$eList"
            set headerPath $path
            set index ""
        }
    }
    return [list $headerPath $index]
}
