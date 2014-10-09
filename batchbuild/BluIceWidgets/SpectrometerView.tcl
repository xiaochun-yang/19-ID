package provide BLUICESpectrometerView 1.0

package require DCSGraph
package require DCSDeviceFactory
package require DCSScale
package require DCSLogger

class SpectrometerView {
    inherit ::itk::Widget

    ### wrap: display spectrometerWrap result
    ### raw:  display get_spectrum result (low level)
    ### scan: data are fed through methods.
    itk_option define -purpose purpose Purpose wrap {
        switch -exact -- $itk_option(-purpose) {
            user_hardware {
                $itk_component(graph) configure \
                -title "Reference and Dark" \
                -yLabel Counts

                pack forget $itk_component(progress)
                pack forget $itk_component(once) \
                $itk_component(saveFile) \
                $itk_component(setOverlay) \
                $itk_component(saveBaseline) \
                $itk_component(baseline) \
                $itk_component(long)

                $itk_component(lbMenu) delete 3
            }
            raw {
                $itk_component(graph) configure -yLabel Raw
                pack forget $itk_component(progress)
            }
            wrap {
                pack forget $itk_component(progress)
            }
            scan -
            default {
                pack forget $itk_component(once)
                pack forget $itk_component(long)
            }
        }
    }

    itk_option define -scanSaveCmd scanSaveCmd ScanSaveCmd ""

    itk_option define -hideSaveAndMoveButton hideButton HideButton 0 {
        if {$itk_option(-hideSaveAndMoveButton)} {
            pack forget $itk_component(saveFile)
            pack forget $itk_component(move)
        }
    }

    public method constructor { args }

    private method registerForOperation
	private method createMarker { mark_num }

    private method runOperation { num } {
        switch -exact -- $itk_option(-purpose) {
            raw {
                $m_objRawOperation startOperation $num
            }
            wrap {
                $m_objWrapOperation startOperation acquire $num
            }
            default {
                puts "not supported"
            }
        }
    }
    public method startOnce { } {
        runOperation 1
    }
    public method startForLong { } {
        runOperation 10000
    }
    public method saveToFile { }
    protected method saveCurrentToFile { path }
    protected method saveCurrentRawToFile { path }
    protected method saveCurrentWrapToFile { path }
    protected method loadReference { }
    protected method loadDark { }

    public method handleRawOperationEvent
    public method handleWrapOperationEvent
    public method handleWrapStatusEvent
    public method updateWrapLog 
    public method updateRawLog 
    public method updateDarkAndReferenceLog 

    public method setWavelengthList { wList }
    public method setReference { cList }
    public method setDark { cList }
    public method setResult { mtrName phi timestamp rList aList tList fn {t0 0}}
    public method setCurrentAsBaseline { }
    public method setCurrentAsOverlay { }
    public method clear { } {
        $m_rawYVect set ""
        $m_absYVect set ""
        $m_trnYVect set ""
    }
    public method clearAll { } {
        clear
        $m_refYVect set ""
        $m_drkYVect set ""
    }

    public method setupBaseline { }

    public method showMoveButton { show } {
        if {$show} {
            pack $itk_component(move) -side right
        } else {
            pack forget $itk_component(move)
        }
    }
    public method move { } {
        set objMotor [$m_deviceFactory getObjectName $m_motorName]
        $objMotor move to $m_position
    }

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
    private method handleWrapOperationEventForUserHardware

    destructor {
        $m_objRawOperation  unRegisterForAllEvents $this handleRawOperationEvent
        $m_objWrapOperation unRegisterForAllEvents $this handleWrapOperationEvent
        $m_objWrapStatus unregister $this contents handleWrapStatusEvent
    }

    private variable m_deviceFactory
    private variable m_objRawOperation
    private variable m_objWrapOperation
    private variable m_objWrapStatus

    private variable m_numElmOverlay 0
    private variable m_rawXVect
    private variable m_rawYVect
    private variable m_refXVect
    private variable m_refYVect
    private variable m_drkXVect
    private variable m_drkYVect
    private variable m_absXVect
    private variable m_absYVect
    private variable m_trnXVect
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

    ### need these for save to file
    protected variable m_sample_x ""
    protected variable m_sample_y ""
    protected variable m_sample_z ""
    protected variable m_sample_a ""
    protected variable m_iTime
    protected variable m_nAvg
    protected variable m_bWidth
    protected variable m_timestamp ""

    protected variable m_baselineEnabled 0
    protected variable m_motorName ""
    protected variable m_position ""
    protected variable m_fileName ""
    protected variable m_overlayCounter 1

    #### for user_hardware
    protected variable m_refPath
    protected variable m_refITime -1
    protected variable m_refAvg -1
    protected variable m_refBcWidth -1
    protected variable m_refTS -1
    protected variable m_drkPath
    protected variable m_drkITime -1
    protected variable m_drkAvg -1
    protected variable m_drkBcWidth -1
    protected variable m_drkTS -1
}
body SpectrometerView::constructor { args } {
    set dir [::config getStr "spectrometer.directory"]
    set bid [::config getConfigRootName]
    set m_refPath [file join $dir $bid reference_${bid}.yaml]
    set m_drkPath [file join $dir $bid dark_${bid}.yaml]

    set m_rawXVect [blt::vector ::[DCS::getUniqueName]]
    set m_rawYVect [blt::vector ::[DCS::getUniqueName]]
    set m_refXVect [blt::vector ::[DCS::getUniqueName]]
    set m_refYVect [blt::vector ::[DCS::getUniqueName]]
    set m_drkXVect [blt::vector ::[DCS::getUniqueName]]
    set m_drkYVect [blt::vector ::[DCS::getUniqueName]]
    set m_absXVect [blt::vector ::[DCS::getUniqueName]]
    set m_absYVect [blt::vector ::[DCS::getUniqueName]]
    set m_trnXVect [blt::vector ::[DCS::getUniqueName]]
    set m_trnYVect [blt::vector ::[DCS::getUniqueName]]

    set m_origRaw [blt::vector ::[DCS::getUniqueName]]
    set m_origAbs [blt::vector ::[DCS::getUniqueName]]
    set m_origTrn [blt::vector ::[DCS::getUniqueName]]
    set m_baseRaw [blt::vector ::[DCS::getUniqueName]]
    set m_baseAbs [blt::vector ::[DCS::getUniqueName]]
    set m_baseTrn [blt::vector ::[DCS::getUniqueName]]

    set m_deviceFactory [DCS::DeviceFactory::getObject]
    set m_objRawOperation  [$m_deviceFactory createOperation get_spectrum]
    set m_objWrapOperation [$m_deviceFactory createOperation spectrometerWrap]
    set m_objWrapStatus    [$m_deviceFactory createString spectroWrap_status]
    $m_objWrapStatus createAttributeFromKey scan_progress scan_progress


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

    $itk_component(notebook) add Graph -label Graph
    $itk_component(notebook) add Log   -label Log

    set graphSite [$itk_component(notebook) childsite 0]
    set logSite   [$itk_component(notebook) childsite 1]

    itk_component add graph {
        DCS::Graph $graphSite.g \
        -title "Spectrometer" \
        -xLabel "Wavelength (nm)" \
        -yLabel "Spectrum" \
        -plotbackground white \
        -noDelete 1
    } {
    }

    itk_component add log {
        DCS::scrolledLog $logSite.l
    } {
    }

    itk_component add progress {
        DCS::Feedback $itk_interior.bar \
        -barheight 10 \
        -steps 100 \
        -component $m_objWrapStatus -attribute scan_progress
    } {
    }

    frame $itk_interior.bottom
    set buttonSite $itk_interior.bottom

    itk_component add once {
        DCS::Button $buttonSite.once \
        -text "Run Once" \
        -width 17 \
        -command "$this startOnce" \
        -activeClientOnly 1 \
        -systemIdleOnly 0
    } {
    }
    itk_component add long {
        DCS::Button $buttonSite.long \
        -text "Run Continuously" \
        -width 17 \
        -command "$this startForLong" \
        -activeClientOnly 1 \
        -systemIdleOnly 0
    } {
    }
    itk_component add move {
        DCS::Button $buttonSite.move \
        -text "Move Motor to Position" \
        -width 27 \
        -command "$this move" \
        -activeClientOnly 1 \
        -systemIdleOnly 1
    } {
    }

    $itk_component(once) addInput \
    "$m_objRawOperation status inactive {supporting device}"
    $itk_component(once) addInput \
    "$m_objWrapOperation status inactive {supporting device}"
    $itk_component(long) addInput \
    "$m_objRawOperation status inactive {supporting device}"
    $itk_component(long) addInput \
    "$m_objWrapOperation status inactive {supporting device}"

    itk_component add saveFile {
        button $buttonSite.save \
        -text "Save" \
        -width 17 \
        -command "$this saveToFile"
    } {
    }
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

    pack $itk_component(lbLabel)           -side left
    pack $itk_component(leftbutton)           -side left
    pack $itk_component(lbArrow)           -side left
    
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
    pack $itk_component(once)           -side left
    pack $itk_component(saveFile)       -side left
    pack $itk_component(setOverlay)     -side left
    pack $itk_component(saveBaseline)   -side left
    pack $itk_component(baseline)       -side left
    pack $itk_component(long)           -side right

    $itk_component(graph) createTrace scope {"Wavelength (nm)"} $m_rawXVect

    $itk_component(graph) removeFileAccess
    #$itk_component(graph) setShowZero 1
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
    pack $itk_component(log)   -side top -expand 1 -fill both

    pack $itk_component(notebook) -side top -expand 1 -fill both
    pack $itk_component(progress) -side top -fill x
    pack $itk_interior.bottom -side bottom -fill x

    eval itk_initialize $args

    switch -exact -- $itk_option(-purpose) {
        raw {
            set m_subTraceRaw [$itk_component(graph) createSubTrace scope raw \
            {"Raw" "Counts"} $m_rawYVect -color green]
        }
        user_hardware {
            set m_subTraceRef [$itk_component(graph) createSubTrace scope ref \
            {"Reference" "Counts"} $m_refYVect -color red]

            set m_subTraceDrk [$itk_component(graph) createSubTrace scope dark \
            {"Dark" "Counts"} $m_drkYVect -color brown]
        }
        default {
            set m_subTraceRaw [$itk_component(graph) createSubTrace scope raw \
            {"Raw" "Counts"} $m_rawYVect -color green]

            set m_subTraceRef [$itk_component(graph) createSubTrace scope ref \
            {"Reference" "Counts"} $m_refYVect -color red]

            set m_subTraceDrk [$itk_component(graph) createSubTrace scope dark \
            {"Dark" "Counts"} $m_drkYVect -color brown]

            set m_subTraceAbs [$itk_component(graph) createSubTrace scope absr \
            {"Absorbance" "Calculation"} $m_absYVect -color black]

            set m_subTraceTrn [$itk_component(graph) createSubTrace scope trns \
            {"Transmittance" "Calculation"} $m_trnYVect -color blue]
        }
    }

    registerForOperation
    $m_objWrapStatus register $this contents handleWrapStatusEvent
    $itk_component(notebook) select 0
}
body SpectrometerView::registerForOperation { } {
    $m_objRawOperation  registerForAllEvents $this handleRawOperationEvent
    $m_objWrapOperation registerForAllEvents $this handleWrapOperationEvent
}
body SpectrometerView::handleRawOperationEvent { msg_ } {
    if {$itk_option(-purpose) != "raw"} {
        return
    }

    foreach {type name id status arg1 arg2 arg3} $msg_ break

    switch -exact -- $type {
        stog_start_operation {
            $itk_component(log) clear
            return
        }
        stog_operation_update -
        stog_operation_completed -
        default {
            ##continue
        }
    }
    if {$status != "normal"} {
        if {$type == "stog_operation_completed"} {
            updateRawLog
        }
        return
    }

    set llw [llength $arg1]
    set llr [llength $arg2]
    if {$llw != $llr} {
        puts "wavelength and readings not the same length $llw!=$llr"
        return
    }
    puts "updating raw ll=$llw"
    
    set m_timestamp [clock format [clock seconds] -format "%D %T"]
    $m_rawXVect set $arg1

    $m_origRaw set $arg2
    if {$m_baselineEnabled} {
        $m_rawYVect expr "$m_origRaw - $m_baseRaw"
    } else {
        $m_origRaw dup $m_rawYVect
    }
    if {$type == "stog_operation_completed"} {
        updateRawLog
    }
    
}
body SpectrometerView::handleWrapStatusEvent { - ready_ - contents_ - } {
    if {$itk_option(-purpose) != "user_hardware"} {
        return
    }
    if {!$ready_} {
        set refValid 0
        set drkValid 0
    } else {
        if {[catch {dict get $contents_ refValid} refValid]} {
            set refValid 0
        }
        if {[catch {dict get $contents_ darkValid} drkValid]} {
            set drkValid 0
        }
    }
    if {!$refValid} {
        set refITime -1
        set refAvg -1
        set refBcWidth -1
        set refTS -1
    } else {
        set refITime   [dict get $contents_ refIntegrationTime]
        set refAvg     [dict get $contents_ refScansToAverage]
        set refBcWidth [dict get $contents_ refBoxcarWidth]
        set refTS      [dict get $contents_ refTimestamp] 
    }
    if {!$drkValid} {
        set drkITime -1
        set drkAvg -1
        set drkBcWidth -1
        set drkTS -1
    } else {
        set drkITime   [dict get $contents_ darkIntegrationTime]
        set drkAvg     [dict get $contents_ darkScansToAverage]
        set drkBcWidth [dict get $contents_ darkBoxcarWidth]
        set drkTS      [dict get $contents_ darkTimestamp] 
    }

    set needUpdateLog 0

    if {$m_refITime   != $refITime \
    ||  $m_refAvg     != $refAvg \
    ||  $m_refBcWidth != $refBcWidth \
    ||  $m_refTS      != $refTS} {
        puts "calling loadReference because"
        puts "$m_refITime   != $refITime "
        puts "$m_refAvg     != $refAvg"
        puts "$m_refBcWidth != $refBcWidth"
        puts "$m_refTS      != $refTS"


        set m_refITime    $refITime
        set m_refAvg      $refAvg
        set m_refBcWidth  $refBcWidth
        set m_refTS       $refTS

        loadReference
        set needUpdateLog 1
    }
    if {$m_drkITime   != $drkITime \
    ||  $m_drkAvg     != $drkAvg \
    ||  $m_drkBcWidth != $drkBcWidth \
    ||  $m_drkTS      != $drkTS} {
        set m_drkITime    $drkITime
        set m_drkAvg      $drkAvg
        set m_drkBcWidth  $drkBcWidth
        set m_drkTS       $drkTS

        loadDark
        set needUpdateLog 1
    }
    if {$needUpdateLog} {
        updateDarkAndReferenceLog 
    }
}
body SpectrometerView::updateRawLog { } {
    $itk_component(log) clear

    if {[$m_rawXVect length] ==0 \
    ||  [$m_rawYVect length] ==0} {
        return
    }

    set wList [$m_rawXVect range 0 end]
    set rList [$m_rawYVect range 0 end]

    set wWidth 15
    set rWidth 15

    set header [format "%${wWidth}s" "wavelength"]
    append header " "
    append header [format "%${rWidth}s" "raw"]
    $itk_component(log) log_string $header warning 0

    set fmtW "%#$wWidth.3f"
    set fmtR "%$rWidth.3f"

    foreach w $wList r $rList {
        set line "[format $fmtW $w] [format $fmtR $r]"
        $itk_component(log) log_string $line warning 0
    }
}
body SpectrometerView::handleWrapOperationEventForUserHardware { msg_ } {
    foreach {type name id arg1 arg2 arg3} $msg_ break

    switch -exact -- $type {
        stog_start_operation {
            return
        }
        stog_operation_update -
        default {
            ##continue
        }
        stog_operation_completed {
        }
    }
    switch -exact -- $arg1 {
        REFERENCE -
        DARK {
            set wList $arg2
            set cList $arg3
            set l1 [llength $wList]
            set l2 [llength $cList]
            if {$l1 != $l2} {
                puts "l1 != l2 l1=$l1 l2=$l2"
                return
            }
        }
    }
    switch -exact -- $arg1 {
        REF_CONDITION {
            puts "got REF_CONDITION : $arg2"
            foreach {m_refITime m_refAvg m_refBcWidth - ts} $arg2 break
            set m_refTS [clock format $ts -format "%D %T"]
            return
        }
        REFERENCE {
            puts "got REFERENCE"
            $m_rawXVect set $wList
            $m_refYVect set $cList
            return
        }
        DARK_CONDITION {
            puts "got DARK_CONDITION : $arg2"
            foreach {m_drkITime m_drkAvg m_drkBcWidth - ts} $arg2 break
            set m_drkTS [clock format $ts -format "%D %T"]
            return
        }
        DARK {
            puts "got DARK"
            $m_rawXVect set $wList
            $m_drkYVect set $cList
            return
        }
        default {
            puts "skip unknown tag: $arg1"
            return
        }
    }
}
body SpectrometerView::handleWrapOperationEvent { msg_ } {
    if {$itk_option(-purpose) == "user_hardware"} {
        handleWrapOperationEventForUserHardware $msg_
        return
    }

    if {$itk_option(-purpose) != "wrap"} {
        return
    }
    
    foreach {type name id arg1 arg2 arg3} $msg_ break

    switch -exact -- $type {
        stog_start_operation {
            $itk_component(log) clear
            return
        }
        stog_operation_update -
        default {
            ##continue
        }
        stog_operation_completed {
            updateWrapLog
        }
    }
    switch -exact -- $arg1 {
        ABSORBANCE -
        TRANSMITTANCE -
        REFERENCE -
        DARK -
        RAW {
            set wList $arg2
            set cList $arg3
            set l1 [llength $wList]
            set l2 [llength $cList]
            if {$l1 != $l2} {
                puts "l1 != l2 l1=$l1 l2=$l2"
                return
            }
        }
    }
    switch -exact -- $arg1 {
        CONDITION {
            foreach {m_iTime m_nAvg m_bWidth} $arg2 break
            return
        }
        SAMPLE_POSITION {
            foreach {m_sample_x m_sample_y m_sample_z m_sample_a} $arg2 break
            return
        }
        RAW {
            set m_timestamp [clock format [clock seconds] -format "%D %T"]
            $m_rawXVect set $wList
            $m_origRaw  set $cList

            set rList [$m_refYVect range 0 end]
            set dList [$m_drkYVect range 0 end]
            set absorbanceCList ""
            set transmittanceCList ""
            if {[catch {
                foreach s $cList r $rList d $dList {
                    set ref [expr $r - $d]
                    set trn [expr $s - $d]
                    if {$ref > 0 && $trn > 0} {
                        set t [expr 1.0 * $trn / $ref]
                        set a [expr -log10( $t )]
                    } else {
                        set a 0.0
                        set t 0.0
                    }

                    lappend absorbanceCList $a
                    lappend transmittanceCList $t
                }
                $m_origAbs set $absorbanceCList
                $m_origTrn set $transmittanceCList
            } errMsg]} {
                puts "calculate failed: $errMsg"
            }

            if {$m_baselineEnabled} {
                $m_rawYVect expr "$m_origRaw - $m_baseRaw"
                $m_absYVect expr "$m_origAbs - $m_baseAbs"
                $m_trnYVect expr "$m_origTrn - $m_baseTrn"
            } else {
                $m_origRaw dup $m_rawYVect
                $m_origAbs dup $m_absYVect
                $m_origTrn dup $m_trnYVect
            }
        }
        ABSORBANCE {
            return
            $m_rawXVect set $wList
            $m_origAbs set $cList
            if {$m_baselineEnabled} {
                $m_absYVect expr "$m_origAbs - $m_baseAbs"
            } else {
                $m_origAbs dup $m_absYVect
            }
        }
        TRANSMITTANCE {
            return
            $m_rawXVect set $wList
            $m_origTrn set $cList
            if {$m_baselineEnabled} {
                $m_trnYVect expr "$m_origTrn - $m_baseTrn"
            } else {
                $m_origTrn dup $m_trnYVect
            }
        }
        REFERENCE {
            puts "got REFERENCE"
            $m_rawXVect set $wList
            $m_refYVect set $cList
            return
        }
        DARK {
            $m_rawXVect set $wList
            $m_drkYVect set $cList
            return
        }
        default {
            puts "skip unknown tag: $arg1"
            return
        }
    }
}
body SpectrometerView::updateWrapLog { } {
    if {[$m_rawXVect length] ==0 \
    ||  [$m_rawYVect length] ==0 \
    ||  [$m_absYVect length] ==0 \
    ||  [$m_trnYVect length] ==0} {
        return
    }

    set wList  [$m_rawXVect range 0 end]
    set rList  [$m_rawYVect range 0 end]
    set aList  [$m_absYVect range 0 end]
    set tList  [$m_trnYVect range 0 end]

    $itk_component(log) clear
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
    $itk_component(log) log_string $header warning 0

    set fmtW "%#$wWidth.3f"
    set fmtR "%$rWidth.3f"
    set fmtA "%#$aWidth.3f"
    set fmtT "%#$tWidth.3f"

    foreach w $wList r $rList a $aList t $tList {
        set line \
        "[format $fmtW $w] [format $fmtR $r] [format $fmtA $a] [format $fmtT $a]"
        $itk_component(log) log_string $line warning 0
    }
}
body SpectrometerView::updateDarkAndReferenceLog { } {
    if {[$m_rawXVect length] ==0 \
    || ([$m_refYVect length] == 0 && [$m_drkYVect length] == 0)} {
        $itk_component(log) clear
        return
    }

    set wList    [$m_rawXVect range 0 end]
    if {[$m_refYVect length] > 0} {
        set refList  [$m_refYVect range 0 end]
    } else {
        set refList  ""
    }
    if {[$m_drkYVect length] > 0} {
        set drkList  [$m_drkYVect range 0 end]
    } else {
        set drkList  ""
    }

    $itk_component(log) clear
    set wWidth 10
    set refWidth 10
    set drkWidth 10

    set header [format "%${wWidth}s" "wavelength"]
    if {$refList != ""} {
        append header " "
        append header [format "%${refWidth}s" "reference"]
    }
    if {$drkList != ""} {
        append header " "
        append header [format "%${drkWidth}s" "dark"]
    }
    $itk_component(log) log_string $header warning 0

    set fmtW "%#$wWidth.3f"
    set fmtR "%$refWidth.3f"
    set fmtD "%$drkWidth.3f"

    if {$drkList == ""} {
        set lineCmd {set line "[format $fmtW $w] [format $fmtR $r]"}
    } elseif {$refList == ""} {
        set lineCmd {set line "[format $fmtW $w] [format $fmtD $d]"}
    } else {
        set lineCmd \
        {set line "[format $fmtW $w] [format $fmtR $r] [format $fmtD $d]"}
    }

    foreach w $wList r $refList d $drkList {
        eval $lineCmd
        $itk_component(log) log_string $line warning 0
    }
}
body SpectrometerView::createMarker { mark_num } {
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
body SpectrometerView::setWavelengthList { wList } {
    $m_rawXVect set $wList
    #$m_refXVect set $wList
    #$m_absXVect set $wList

    set numElement [$m_rawXVect length]
    if {$m_numElmOverlay != $numElement} {
        $itk_component(graph) zoomOutAll
        set m_numElmOverlay $numElement
    }
}
body SpectrometerView::setReference { cList } {
    $m_refYVect set $cList
}
body SpectrometerView::setDark { cList } {
    $m_drkYVect set $cList
}
body SpectrometerView::setCurrentAsBaseline { } {
    $m_origRaw dup $m_baseRaw
    $m_origAbs dup $m_baseAbs
    $m_origTrn dup $m_baseTrn

    set rLabel [$m_subTraceRaw getLabel]
    set m_baseRawLabel "b:$rLabel"
    if {$itk_option(-purpose) != "raw" \
    &&  $itk_option(-purpose) != "user_hardware"} {
        set aLabel [$m_subTraceAbs getLabel]
        set tLabel [$m_subTraceTrn getLabel]
        set m_baseAbsLabel "b:$aLabel"
        set m_baseTrnLabel "b:$tLabel"
    }
    setupBaseline
}
body SpectrometerView::setCurrentAsOverlay { } {
    set m_numElmOverlay [$m_rawXVect length]
    set fName [file rootname $m_fileName]
    set overlayName $fName
    if {$overlayName == ""} {
        set overlayName overlay$m_overlayCounter
        incr m_overlayCounter
    }

    $itk_component(graph) makeOverlay scope $overlayName
}
body SpectrometerView::setResult { motorName p title rList aList tList \
fileName {t0 0}} {
    set m_motorName $motorName
    set m_position $p
    set m_fileName $fileName

    set motorDisplayName [getMotorDisplayName $m_motorName]

    if {$m_motorName != "time" \
    &&  $m_motorName != "snapshot" \
    && !$itk_option(-hideSaveAndMoveButton)} {
        $itk_component(move) configure \
        -text "Move $motorDisplayName to [format {%.3f} $m_position]"
        showMoveButton 1
    } else {
        showMoveButton 0
    }

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

    if {$m_motorName == "snapshot"} {
        set title "snapshot"
    } else {
        set title "$motorDisplayName=[format %.3f $p]"
    }
    $m_subTraceRaw setLabel "r:$title"
    $m_subTraceAbs setLabel "a:$title"
    $m_subTraceTrn setLabel "t:$title"
    updateWrapLog

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
body SpectrometerView::saveToFile { } {
    if {$itk_option(-purpose) == "scan"} {
        if {$itk_option(-scanSaveCmd) != ""} {
            eval $itk_option(-scanSaveCmd)
        }
        return
    }
    set types [list [list CSV .csv]]
    set filename [tk_getSaveFile \
    -defaultextension ".csv" \
    -filetypes $types \
    ]

    saveCurrentToFile $filename
}
body SpectrometerView::saveCurrentToFile { path } {
    switch -exact -- $itk_option(-purpose) {
        user_hardware -
        raw {
            saveCurrentRawToFile $path
        }
        wrap {
            saveCurrentWrapToFile $path
        }
    }
}
body SpectrometerView::loadReference { } {
    puts "loadReference"
    $m_refYVect set ""
    if {$m_refITime == -1} {
        return
    }
    if {[catch {
        ::yaml::yaml2huddle -file $m_refPath
    } hhhh]} {
        log_error load reference failed: $hhhh
        return
    }
    set title [huddle gets $hhhh TITLE]
    if {$title != "spectrometer_reference"} {
        log_error wrong yamle file, TITLE = $title != spectrometer_reference
        return
    }
    set rfWList [huddle gets $hhhh wavelengthList]
    set rfCList [huddle gets $hhhh countList]

    $m_rawXVect set $rfWList
    $m_refYVect set $rfCList
}
body SpectrometerView::loadDark { } {
    $m_drkYVect set ""
    if {$m_drkITime == -1} {
        return
    }
    if {[catch {
        ::yaml::yaml2huddle -file $m_drkPath
    } hhhh]} {
        log_error load dark failed: $hhhh
        return
    }
    set title [huddle gets $hhhh TITLE]
    if {$title != "spectrometer_dark"} {
        log_error wrong yamle file, TITLE = $title != spectrometer_dark
        return
    }

    set dkWList         [huddle gets $hhhh wavelengthList]
    set dkCList         [huddle gets $hhhh countList]

    $m_rawXVect set $dkWList
    $m_drkYVect set $dkCList
}
body SpectrometerView::saveCurrentWrapToFile { path } {
    if {[catch {open $path w} handle]} {
        log_error failed to open $path to write
        return
    }
    

    set header "wavelength,reference,dark"
    append header ",raw,absorbance,transmittance"
    append header ",timestamp"
    append header ",integrationTime,scansToAverage,boxcarWidth"
    append header ",sample_x,sample_y,sample_z,sample_angle(phi+omega)"
    puts $handle $header

    set firstLine ",,"
    append firstLine ",,,"
    append firstLine ",$m_timestamp"
    append firstLine ",$m_iTime,$m_nAvg,$m_bWidth"
    append firstLine ",$m_sample_x,$m_sample_y,$m_sample_z,$m_sample_a"
    puts $handle $firstLine

    set wList  [$m_rawXVect range 0 end]
    set rfList [$m_refYVect range 0 end]
    set dkList [$m_drkYVect range 0 end]
    set rList  [$m_rawYVect range 0 end]
    set aList  [$m_absYVect range 0 end]
    set tList  [$m_trnYVect range 0 end]

    foreach w $wList rf $rfList d $dkList \
    r $rList a $aList t $tList {
        set line "$w,$rf,$d"
        append line ",$r,$a,$t"
        append line ","
        append line ",,,"
        append line ",,,"
        puts $handle $line
    }
    close $handle
    log_warning saved wrap result to file $path
}
body SpectrometerView::saveCurrentRawToFile { path } {
    if {[catch {open $path w} handle]} {
        log_error failed to open $path to write
        return
    }
    

    set header "wavelength,raw"
    puts $handle $header

    set wList  [$m_rawXVect range 0 end]
    set rList  [$m_rawYVect range 0 end]
    foreach w $wList r $rList {
        set line "$w,$r"
        puts $handle $line
    }
    close $handle
    log_warning saved raw result to file $path
}
body SpectrometerView::setupBaseline { } {
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
        if {$itk_option(-purpose) != "raw" \
        &&  $itk_option(-purpose) != "user_hardware"} {
            set oAbs [$itk_component(graph) createSubTrace scope base_abrb \
            {"Absorbance" "Calculation"} $m_baseAbs -color red -isOverlay 1]

            set oTrn [$itk_component(graph) createSubTrace scope base_trns \
            {"Transmittance" "Calculation"} $m_baseTrn -color red -isOverlay 1]

            $oAbs setLabel $m_baseAbsLabel
            $oTrn setLabel $m_baseTrnLabel
        }
    } else {
        $m_origRaw dup $m_rawYVect
        $m_origAbs dup $m_absYVect
        $m_origTrn dup $m_trnYVect
    }
    if {$itk_option(-purpose) != "raw" \
    &&  $itk_option(-purpose) != "user_hardware"} {
        updateWrapLog
    } else {
        updateRawLog
    }
}

#### it can load from the file and listen to the operation update message.
#### loading from file takes quite long, so it only does it when it starts up.
####
class MicroSpectScanResult {
    inherit ::DCS::Component

    public method loadFile { path {fullLoad 0}}
    public method loadResultInBackground { }

    public method getWavelengthList { } { return $m_wavelength }
    public method getResult { index }
    public method getVideoSnapshot { index }
    public method saveResult { index path }
    public method getReference { }     { return $m_reference }
    public method getDark { }           { return $m_dark }
    public method getReady { }          { return $m_ready }
    public method getNumberOfResult { } { return $m_numResult }
    public method getProgress { } { return $m_progress }
    public method getMessage { } { return $m_message }
    ### for event
    public method isNewScan { } { return 1 }
    public method getStatus { } { return $m_status }

    public method handleStringUpdate { name_ ready_ - contents_ - }
    public method handleOperationEvent { msg_ }

    protected method init { update }
    protected method setResult { index dd }
    protected method setResultFromRaw { index dd } {
        calculateFromRaw dd
        setResult $index $dd
    }
    protected method loadResultFile { index }
    protected method loadAllResultIfNeed { }

    protected method calculateFromRaw { dd }

    protected variable m_status offline
    protected variable m_mode ""
    protected variable m_deviceFactory ""
    protected variable m_objStatus ""
    protected variable m_objOperation ""
    protected variable m_ready 0
    protected variable m_numResult 0
    protected variable m_numPoint 0
    protected variable m_progress "100 of 100"
    protected variable m_message ""
    protected variable m_reference ""
    protected variable m_saturatedRefCount 65535
    protected variable m_dark ""
    protected variable m_wavelength ""
    protected variable m_result ""
    protected variable m_motorName ""
    protected variable m_path ""
    protected variable m_fileLoaded ""
    protected variable m_fileFromString ""

    protected variable m_sysDir ""
    protected variable m_fileList ""
    protected variable m_doseRate 0
    ### need these for save to file
    protected variable m_sample_x ""
    protected variable m_sample_y ""
    protected variable m_sample_z ""
    protected variable m_sample_a ""
    protected variable m_iTime
    protected variable m_nAvg
    protected variable m_bWidth

    protected variable m_numSaturated 0

    ### in operation will ignore filename in status string
    protected variable m_inOperation 0

    protected common SATURATED_RAW_COUNT 65535

    constructor { {mode ""} } {
        ::DCS::Component::constructor {
            status   { getStatus }
            ready    { getReady }
            new_scan { isNewScan }
            numData  { getNumberOfResult }
            progress { getProgress }
            message  { getMessage }
        }
    } {
        set m_mode $mode

        set dir [::config getStr "spectrometer.directory"]
        set bid [::config getConfigRootName]
        set m_sysDir [file join $dir $bid]

        set m_deviceFactory [::DCS::DeviceFactory::getObject]

        switch -exact -- $m_mode {
            snapshot {
                set opName microspec_snapshot
                set stName microspec_snapshot_status
            }
            phi_scan {
                set opName microspec_phiScan
                set stName microspec_phiScan_status
            }
            time_scan {
                set opName microspec_timeScan
                set stName microspec_timeScan_status
            }
            dose_scan {
                set opName microspec_doseScan
                set stName microspec_doseScan_status
            }
            default {
                ### motor_scan/scan_motor
                set opName spectrometerWrap
                set stName spectroWrap_status
            }
        }

        set m_objStatus [$m_deviceFactory createString $stName]
        set m_objOperation   [$m_deviceFactory createOperation $opName]
        $m_objStatus createAttributeFromKey scan_progress

        $m_objStatus register $this contents handleStringUpdate
        $m_objOperation registerForAllEvents $this handleOperationEvent

        announceExist
    }
    destructor {
        $m_objStatus unregister $this contents handleStringUpdate
        $m_objOperation unRegisterForAllEvents $this handleOperationEvent
    }
}
body MicroSpectScanResult::init { update } {
    set m_ready 0
    set m_numPoint 0
    set m_numResult 0
    set m_reference ""
    set m_saturatedRefCount 65535
    set m_dark ""
    set m_wavelength ""
    set m_result ""
    set m_samplePosition ""
    set m_fileLoaded ""
    set m_doseRate 0

    if {$update} {
        updateRegisteredComponents new_scan
        updateRegisteredComponents ready
    }
}
body MicroSpectScanResult::handleStringUpdate { name_ ready_ - contents_ - } {
    if {!$ready_} {
        set m_status offline
        updateRegisteredComponents status
        init 1
        return
    }
    set m_status inactive
    updateRegisteredComponents status

    if {[catch {
        dict get $contents_ scan_progress
    } m_progress]} {
        log_error $m_progress
        log_error scan_progress not found in string [namespace tail $name_]
        set m_progress "100 of 100"
    }
    updateRegisteredComponents progress

    if {[catch {
        dict get $contents_ message
    } m_message]} {
        log_error $m_message
        log_error message not found in string [namespace tail $name_]
        set m_message ""
    }
    updateRegisteredComponents message

    if {[catch {
        dict get $contents_ scan_result
    } filename]} {
        log_error $filename
        log_error scan_result not found in string [namespace tail $name_]
        return
    }

    if {$filename == $m_fileFromString} {
        return
    }
    set m_fileFromString $filename

    if {$m_inOperation} {
        return
    }

    if {$filename == "clear" || $filename == ""} {
        init 1
        return
    }

    puts "for $this fn=$filename loaded=$m_fileLoaded"
    if {$filename == $m_fileLoaded} {
        return
    }

    set dir [::config getStr "spectrometer.directory"]
    set bid [::config getConfigRootName]
    set path [file join $dir $bid $filename]
    loadFile $path
}
body MicroSpectScanResult::loadFile { path_ {fullLoad 0}} {
    if {$path_ == ""} {
        set path_ $m_path
    }
    set dir [file dirname $path_]
    set now [clock format [clock seconds] -format "%D %T"]
    puts "loading file: $now"
    if {[catch {
        ::yaml::yaml2huddle -file $path_
    } hhhh]} {
        log_error read file failed: $hhhh
        init 1
        return
    }
    set now [clock format [clock seconds] -format "%D %T"]
    puts "done loading file: $now"

    ### motor and mode compatible check
    set motor [huddle gets $hhhh motorName]
    switch -exact -- $m_mode {
        phi_scan {
            switch -exact -- $motor {
                snapshot -
                gonio_phi {
                }
                default {
                    log_error only can load phi_scan or snapshot
                }
            }
        }
        dose_scan -
        time_scan {
            switch -exact -- $motor {
                time -
                dose {
                }
                default {
                    log_error only can load time_scan or dose_scan
                }
            }
        }
        default {
            if {$motor != "snapshot"} {
                log_error only can load snapshot
                return
            }
        }
    }

    set m_motorName  [huddle gets $hhhh motorName]
    set m_numPoint   [huddle gets $hhhh numPoint]
    set m_reference  [huddle gets $hhhh reference]
    set m_dark       [huddle gets $hhhh dark]
    set m_wavelength [huddle gets $hhhh wavelength]
    set m_fileList   [huddle gets $hhhh scan_result]
    set m_sample_x   [huddle gets $hhhh sample_x]
    set m_sample_y   [huddle gets $hhhh sample_y]
    set m_sample_z   [huddle gets $hhhh sample_z]
    set m_sample_a   [huddle gets $hhhh sample_angle]
    set m_iTime      [huddle gets $hhhh integrationTime]
    set m_nAvg       [huddle gets $hhhh scansToAverage]
    set m_bWidth     [huddle gets $hhhh boxcarWidth]
    set m_numResult  [llength $m_fileList]
    if {[catch {
        huddle gets $hhhh reference_threshold
    } m_saturatedRefCount]} {
        set m_saturatedRefCount 65535
        log_warning reference_threshold not defined, assuming 65535
    }
    puts "numResult=$m_numResult numPoint=$m_numPoint"

    set m_doseRate 0
    set keys [huddle keys $hhhh]
    if {[lsearch -exact $keys dose_rate] >= 0} {
        set m_doseRate [huddle gets $hhhh dose_rate]
    }

    if {$m_numResult > 0} {
        set m_ready 1
    }

    set m_result ""
    if {$m_numResult > 0} {
        if {$fullLoad} {
            foreach file $m_fileList {
                set path [file join $dir $file]
                puts "loading $path"
                if {[catch {
                    ::yaml::yaml2dict -file -types str $path
                } dd]} {
                    log_error read scan result file $path failed: $hhhh
                    return
                }
                calculateFromRaw dd
                lappend m_result $dd
            }
        } else {
            set file [lindex $m_fileList end]
            set path [file join $dir $file]
            if {[catch {
                ::yaml::yaml2dict -file -types str $path
            } dd]} {
                log_error read scan result file $path failed: $hhhh
                return
            }
            calculateFromRaw dd
            set n [expr $m_numResult - 1]
            set m_result [string repeat "{} " $n]
            lappend m_result $dd
            loadResultInBackground
        }
    }
    set m_progress "$m_numResult of $m_numPoint"
    updateRegisteredComponents new_scan
    updateRegisteredComponents ready
    updateRegisteredComponents numData
    updateRegisteredComponents progress

    set m_path $path_
    set m_fileLoaded [file tail $m_path]
    puts "set file loaded to $m_fileLoaded"
    set m_fileFromString "LOADED_FROM_FILE"
}
body MicroSpectScanResult::loadAllResultIfNeed { } {
    set index -1
    foreach rr $m_result {
        incr index
        if {$rr == ""} {
            loadResultFile $index
        }
    }
}
body MicroSpectScanResult::loadResultInBackground { } {
    return

    set ll [llength $m_result]
    if {$ll == 0} {
        return
    }
    set last [expr $ll - 1]
    for {set index $last} {$index >= 0} {incr index -1} {
        set rr [lindex $m_result $index]
        if {$rr == ""} {
            after 1000 "$this loadResultInBackground"
            loadResultFile $index
            break
        }
    }
}
body MicroSpectScanResult::loadResultFile { index } {
    set dir [file dirname $m_path]
    set file [lindex $m_fileList $index]
    puts "loading scan result $index from $file"
    if {$file == ""} {
        log_error no file for index = $index in scan
    }
    set path [file join $dir $file]
    if {[catch {
        ::yaml::yaml2dict -file -types str $path
    } dd]} {
        log_error read scan result file $path failed: $hhhh
        return
    }
    calculateFromRaw dd
    set m_result [setStringFieldWithPadding $m_result $index $dd]
}
body MicroSpectScanResult::getResult { index } {
    set h [lindex $m_result $index]
    if {$h == ""} {
        loadResultFile $index
        set h [lindex $m_result $index]
    } else {
        puts "result ready for index=$index"
    }

    set fileName    [lindex $m_fileList $index]

    set position    [dict get $h position]
    set timestamp   [dict get $h timestamp]
    set raw         [dict get $h raw]
    if {[catch {
        set absor   [dict get $h absorbance]
    } errMsg]} {
        set absor   ""
    }
    if {[catch {
        set trans   [dict get $h transmittance]
    } errMsg]} {
        set trans   ""
    }
    if {[catch {
        set dose   [dict get $h dose]
    } errMsg]} {
        set dose ""
    }

    set motorDisplayName [getMotorDisplayName $m_motorName]
    set units [getMotorUnits $m_motorName]

    set displayFName [file rootname $fileName]
    if {$m_numSaturated} {
        set title "WARNING: saturated $displayFName "
    } else {
        set title "$displayFName "
    }

    if {$m_motorName == "snapshot"} {
        append title "Snapshot"
    } else {
        append title "${motorDisplayName}=[format %.3f ${position}] $units"
    }

    puts "motor=$m_motorName dose=$dose"

    if {$m_motorName == "dose"} {
        if {![string is double -strict $dose] || $dose < 0} {
            set dose 0
        }
        append title "/Estimated Dose=[format %.0f $dose] Gy"
    } elseif {[string is double -strict $dose] && $dose > 0} {
        append title "/Estimated Dose=[format %.0f $dose] Gy"
    } elseif {$m_motorName == "time" && $m_doseRate > 0} {
        #### old scan data
        set dose [expr $position * $m_doseRate]
        append title "/Estimated Dose=[format %.0f $dose] Gy"
    }

    return [list $m_motorName $position $title $raw $absor $trans $fileName]
}
body MicroSpectScanResult::getVideoSnapshot { index } {
    set dir [file dirname $m_path]
    if {$m_mode != "phi_scan"} {
        return [list $m_mode [file rootname $m_path].jpg]
    }

    set file [lindex $m_fileList $index]
    if {$file == ""} {
        log_error no file for index = $index in scan
        return [list $m_mode ""]
    }
    set base [file rootname $file].jpg
    return [list $m_mode [file join $dir $base]]
}
body MicroSpectScanResult::saveResult { index path } {
    if {[catch {open $path w} handle]} {
        log_error failed to open $path to write
        return
    }
    set header "wavelength,reference,dark"
    append header ",raw,absorbance,transmittance"
    append header ",motorName,position,timestamp"
    append header ",integrationTime,scansToAverage,boxcarWidth"
    append header ",sample_x,sample_y,sample_z,sample_angle(phi+omega)"
    puts $handle $header

    set result [getResult $index]
    foreach {mName p ts rList aList tList} $result break

    set firstLine ",,"
    append firstLine ",,,"
    append firstLine ",$m_motorName,$p,$ts"
    append firstLine ",$m_iTime,$m_nAvg,$m_bWidth"
    append firstLine ",$m_sample_x,$m_sample_y,$m_sample_z,$m_sample_a"
    puts $handle $firstLine

    foreach w $m_wavelength rf $m_reference d $m_dark \
    r $rList a $aList t $tList {
        set line "$w,$rf,$d"
        append line ",$r,$a,$t"
        append line ",,,"
        append line ",,,"
        append line ",,,"
        puts $handle $line
    }
    close $handle
    log_warning saved scan index=$index to file $path
}
body MicroSpectScanResult::setResult { index dd } {
    puts "setResult for $index numResult=$m_numResult"
    if {$index == $m_numResult} {
        ### this is the case monitoring operations
        #set newScan [expr ($m_numResult == 0)?1:0]
        lappend m_result $dd
        incr m_numResult
        if {$m_numResult > 0} {
            set m_ready 1
        }
        #if {$newScan} {
        #    updateRegisteredComponents new_scan
        #}
        updateRegisteredComponents ready
        updateRegisteredComponents numData
    } elseif {$index < $m_numResult} {
        set current [lindex $m_result $index]
        set newDD [dict merge $current $dd]
        set m_result [lreplace $m_result $index $index $newDD]
        updateRegisteredComponents numData
    } else {
        set current [lindex $m_result $index]
        set newDD [dict merge $current $dd]
        set m_result [setStringFieldWithPadding $m_result $index $newDD]
        set m_numResult [llength $m_result]
        updateRegisteredComponents numData
    }
}
body MicroSpectScanResult::calculateFromRaw { ddRef } {
    upvar $ddRef dd

    set rawCList [dict get $dd raw]

    set absorbanceCList ""
    set transmittanceCList ""

    set m_numSaturated 0
    foreach s $rawCList r $m_reference d $m_dark {
        if {$s < $SATURATED_RAW_COUNT && $r < $m_saturatedRefCount} {
            set ref [expr $r - $d]
            set trn [expr $s - $d]
        } else {
            set ref 0
            set trn 0
            incr m_numSaturated
        }

        if {$ref > 0 && $trn > 0} {
            set t [expr 1.0 * $trn / $ref]
            set a [expr -log10( $t )]
        } else {
            set a 0.0
            set t 0.0
        }

        lappend absorbanceCList $a
        lappend transmittanceCList $t
    }
    dict set dd absorbance   $absorbanceCList
    dict set dd transmittance $transmittanceCList
}
body MicroSpectScanResult::handleOperationEvent { msg_ } {
    set arg1 ""
    set arg2 ""
    set arg3 ""
    set arg4 ""
    set arg5 ""
    set arg6 ""
    foreach {type name id arg1 arg2 arg3 arg4 arg5 arg6} $msg_ break

    switch -exact -- $type {
        stog_start_operation {
            set m_inOperation 1
            switch -exact -- $m_mode {
                phi_scan {
                    ### this is not necessary.
                    ### the operation will set scan_result to "" to clear
                    ### the results
                    init 1

                    set m_motorName gonio_phi
                }
                snapshot {
                    init 1
                    set m_motorName snapshot
                }
                time_scan -
                dose_scan {
                    ### this is not necessary.
                    ### the operation will set scan_result to "" to clear
                    ### the results
                    init 1

                    set m_motorName time
                }
                default {
                    if {$arg1 == "scan_motor" || $arg1 == "motor_scan"} {
                        init 1
                        foreach {- - - - m_motorName - - - -} \
                        $msg_ break
                        puts "motorname $m_motorName"
                    }
                }
            }
            return
        }
        stog_operation_completed {
            set m_inOperation 0
            return
        }
        stog_operation_update -
        default {
            set m_inOperation 1
            ##continue
        }
    }

    switch -exact -- $arg1 {
        SCAN_WAVELENGTH {
            puts "got wavelength list"
            set m_wavelength $arg2
        }
        SCAN_REFERENCE {
            puts "got background"
            set m_reference $arg2
        }
        SCAN_DARK {
            puts "got dark"
            set m_dark $arg2
        }
        SCAN_HEADER_FILE {
            set m_fileLoaded $arg2
            set m_path [file join $m_sysDir $m_fileLoaded]
            puts "got header file from operation: $m_fileLoaded"
        }
        SCAN_DOSE_RATE {
            set m_doseRate $arg2
            puts "got dose rate: $m_doseRate"
        }
        SCAN_FILE {
            set index $arg2
            set file  $arg3
            set m_fileList [setStringFieldWithPadding $m_fileList $index $file]
        }
        EXTENDED_SCAN_RAW -
        SCAN_RAW {
            set index $arg2
            set position $arg3
            set timestamp $arg4
            set rawList $arg5
            set dose    $arg6
            puts "get dose=$dose from operation"
            set dd [dict create \
            position    $position \
            timestamp   $timestamp \
            raw         $rawList \
            dose        $dose \
            ]
            #setResult $index $dd
            setResultFromRaw $index $dd
        }
        SCAN_SAMPLE_POSITION {
            foreach {m_sample_x m_sample_y m_sample_z m_sample_a} $arg2 break
        }
        SCAN_CONDITION {
            foreach {m_iTime m_nAvg m_bWidth} $arg2 break
        }
        default {
            puts "skip unknown tag: $arg1"
            return
        }
    }
}

class MicroSpectUserView {
    inherit ::itk::Widget

    public method save2File { } {
        set path [tk_getSaveFile -defaultextension ".csv"]
        set index [$itk_component(slider) get]
        $m_data saveResult $index $path
    }

    public method handleNumDataUpdate { - ready_ - contents - }
    public method handleNewScan { - ready_ - contents - }
    public method updateDisplay { index }

    protected variable m_data ""
    protected variable m_initSent 0

    constructor { args } {
        itk_component add plot {
            SpectrometerView $itk_interior.plot \
            -purpose scan \
            -scanSaveCmd "$this save2File"
        } {
        }
        itk_component add slider {
            scale $itk_interior.slider \
            -orient horizontal \
            -showvalue 0 \
            -from 0
        } {
        }

        ##### data
        set m_data [MicroSpectScanResult ::\#auto]

        $m_data register $this numData  handleNumDataUpdate
        $m_data register $this new_scan handleNewScan

        #$itk_component(slider) addInput \
        #"$m_data ready 1 {data not ready}"

        
        $itk_component(slider) configure \
        -command "$this updateDisplay"

        pack $itk_component(plot) -side top -fill both -expand 1
        pack $itk_component(slider) -side bottom -fill x


        eval itk_initialize $args
    }
    destructor {
        delete object $m_data
    }
}
body MicroSpectUserView::handleNewScan { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    $itk_component(plot) clear
    set m_initSent 0
}
body MicroSpectUserView::handleNumDataUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    if {$contents_ <= 0} {
        return
    }
    set end [expr $contents_ -1]
    $itk_component(slider) configure \
    -to $end

    if {!$m_initSent} {
        $itk_component(plot) setWavelengthList [$m_data getWavelengthList]
        $itk_component(plot) setReference [$m_data getReference]
        $itk_component(plot) setDark [$m_data getDark]

        set result [$m_data getResult 0]
        eval $itk_component(plot) setResult $result 1
        $itk_component(plot) setCurrentAsBaseline

        set m_initSent 1
    }
    $itk_component(slider) set $end
}
body MicroSpectUserView::updateDisplay { index } {
    set ll [$m_data getNumberOfResult]

    if {$index < 0 || $index >= $ll} {
        puts "bad index $index"
        $itk_component(plot) clear
        return
    }

    set result [$m_data getResult $index]

    eval $itk_component(plot) setResult $result [expr $index == 0]
}
