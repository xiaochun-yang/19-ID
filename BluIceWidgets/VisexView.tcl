package provide VisexView 1.0

package require ComponentGateExtension

class VisexFormatGenerator {
    inherit ::itk::Widget

    public method reset { } {
        $itk_component(cut_low_start) setValue 0
        $itk_component(cut_high_start) setValue 0

        $itk_component(cut_low_slide) set 0
        $itk_component(cut_high_slide) set 100

        #set gScale($this,low) 0
        #set gScale($this,high) 100
        #generateFormatFromLow 0
    }
    public method default { } { 
        $itk_component(cut_low_start) setValue 99
        $itk_component(cut_high_start) setValue 99

        $itk_component(cut_low_slide) set 99.5
        $itk_component(cut_high_slide) set 99.95
        #set gScale($this,low) 99.5
        #set gScale($this,high) 99.95
        #generateFormatFromLow 0
    }

    public method setLowStart { s } {
        $itk_component(cut_low_slide) configure -from $s
    }
    public method setHighStart { s } {
        $itk_component(cut_high_slide) configure -from $s
    }
    public method generateFormatFromLow { - } {
        if {$m_inProcessing} {
            puts "already in processing"
            return
        }
        set m_inProcessing 1
        set ll $gScale($this,low)
        set hh $gScale($this,high)
        if {$ll > $hh} {
            set gScale($this,high) $ll
            set hh $ll
        }

        set format count_cut_${ll}_${hh}
        puts "new format $format"
        $m_imageWidget setFormat $format
        set m_inProcessing 0
    }
    public method generateFormatFromHigh { - } {
        if {$m_inProcessing} {
            puts "already in processing"
            return
        }
        set m_inProcessing 1
        set ll $gScale($this,low)
        set hh $gScale($this,high)
        if {$ll > $hh} {
            set gScale($this,low) $hh
            set ll $hh
        }

        set format count_cut_${ll}_${hh}
        puts "new format $format"
        $m_imageWidget setFormat $format
        set m_inProcessing 0
    }

    constructor { w_img args } {
        set gScale($this,low) 99.5
        set gScale($this,high) 99.95

        set m_imageWidget $w_img

        set controlSite $itk_interior

        itk_component add reset {
            button $controlSite.reset \
            -text Reset \
            -width 7 \
            -command "$this reset"
        } {
        }

        itk_component add default {
            button $controlSite.default \
            -text Default \
            -width 7 \
            -command "$this default"
        } {
        }

        itk_component add cut_low_start {
            DCS::Entry $controlSite.lowStart \
            -systemIdleOnly 0 \
            -decimalPlaces 1 \
            -activeClientOnly 0 \
            -leaveSubmit 1 \
            -state normal \
            -promptText "LoCut Slide Start:" \
            -promptWidth 18 \
            -entryWidth 5     \
            -entryType positiveFloat \
            -entryJustify right \
            -units "%" \
            -onSubmit "$this setLowStart %s" 
        } {
        }
        itk_component add cut_high_start {
            DCS::Entry $controlSite.highStart \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -decimalPlaces 1 \
            -leaveSubmit 1 \
            -state normal \
            -promptText "HiCut Slide Start:" \
            -promptWidth 18 \
            -entryWidth 5     \
            -entryType positiveFloat \
            -entryJustify right \
            -units "%" \
            -onSubmit "$this setHighStart %s" 
        } {
        }
        itk_component add cut_low_slide {
            scale $controlSite.lowCut \
            -orient horizontal \
            -to 100.0 \
            -variable [list [::itcl::scope gScale($this,low)]] \
            -resolution 0.01 \
            -command "$this generateFormatFromLow"
        } {
        }
        itk_component add cut_high_slide {
            scale $controlSite.highCut \
            -orient horizontal \
            -to 100.0 \
            -variable [list [::itcl::scope gScale($this,high)]] \
            -resolution 0.01 \
            -command "$this generateFormatFromHigh"

        } {
        }

        $itk_component(cut_low_start) setValue 99.0
        $itk_component(cut_high_start) setValue 99.0

        grid $itk_component(reset)          -row 0 -column 0 -sticky ews
        grid $itk_component(default)        -row 1 -column 0 -sticky ews
        grid $itk_component(cut_low_start)  -row 0 -column 1 -sticky ews
        grid $itk_component(cut_high_start) -row 1 -column 1 -sticky ews
        grid $itk_component(cut_low_slide)  -row 0 -column 2 -sticky news
        grid $itk_component(cut_high_slide) -row 1 -column 2 -sticky news

        grid columnconfigure $controlSite 2 -weight 10
        eval itk_initialize $args
    }

    private variable m_imageWidget ""
    private variable m_inProcessing 0

    private common gScale
}


class VisexImageView {
    inherit ::DCS::ComponentGateExtension

    ### need to enable first if want it to show.
    ### here is for GUI to turn it on/off
    itk_option define -showBeamPosition showBeamPosition ShowBeamPosition 0 {
        updateCurrentPosition
    }

    itk_option define -snapshot   snapshot   Snapshot   ""        { update }
    itk_option define -packOption packOption PackOption "-side right"

    itk_option define -format format Format pgm16 { update }

    #### this is special for visex.
    itk_option define -resultIndex resultIndex ResultIndex 0

    itk_option define -showPercent showPercent ShowPercent 50.0 {
        updateShowParameters
        updateCurrentPosition
        #refreshSnapshot
    }
    ### these will change with showPercent if they are not 0.5
    private variable m_imageCenterX 0.5
    private variable m_imageCenterY 0.5
    ### fraction of the whole image
    private variable m_rawImageX0 0
    private variable m_rawImageY0 0
    private variable m_rawImageX1 1.0
    private variable m_rawImageY1 1.0
    ### this will update above parameters based on:
    ### showPercent, visex camera center_x/y
    ### raw image size
    private method updateShowParameters { } {
        puts "updateShowParameters"
        if {$m_ctsConstant == ""} {
            puts "skip, camera parameters not ready yet"
            return
        }

        if {$itk_option(-showPercent) >= 100 \
        ||  $itk_option(-showPercent) <= 0} {
            set m_imageCenterX [lindex $m_ctsConstant $m_indexMap(center_x)]
            set m_imageCenterY [lindex $m_ctsConstant $m_indexMap(center_y)]
            set m_rawImageX0 0
            set m_rawImageY0 0
            set m_rawImageX1 1.0
            set m_rawImageY1 1.0
            puts "percent=100"
            return
        }
        set cx [lindex $m_ctsConstant $m_indexMap(center_x)]
        set cy [lindex $m_ctsConstant $m_indexMap(center_y)]
        
        set half [expr $itk_option(-showPercent) / 200.0]
        set x0 [expr $cx - $half]
        set x1 [expr $cx + $half]
        set y0 [expr $cy - $half]
        set y1 [expr $cy + $half]
        set cx 0.5
        set cy 0.5
        puts "direct: $x0 $y0 $x1 $y1"

        if {$x0 < 0} {
            set dx [expr 0 - $x0]

            set x0 0
            set x1 [expr $x1 + $dx]
            set cx [expr $cx + $dx]
        } elseif {$x1 > 1.0} {
            set dx [expr 1.0 - $x1]

            set x0 [expr $x0 + $dx]
            set x1 1
            set cx [expr $cx + $dx]
        }

        if {$y0 < 0} {
            set dy [expr 0 - $y0]

            set y0 0
            set y1 [expr $y1 + $dy]
            set cy [expr $cy + $dy]
        } elseif {$y1 > 1.0} {
            set dy [expr 1.0 - $y1]

            set y0 [expr $y0 + $dy]
            set y1 1
            set cy [expr $cy + $dy]
        }
        puts "final: $x0 $y0 $x1 $y1 center: $cx $cy"
        set m_imageCenterX $cx
        set m_imageCenterY $cy
        set m_rawImageX0 $x0
        set m_rawImageY0 $y0
        set m_rawImageX1 $x1
        set m_rawImageY1 $y1
    }

    private variable m_rawImage ""
    private variable m_showImage ""
    private variable m_rawWidth 0
    private variable m_rawHeight 0
    private variable m_imageWidth 0
    private variable m_imageHeight 0
    
    private variable m_winID "not defined"
    private variable m_snapshot
    private variable m_drawWidth 0
    private variable m_drawHeight 0

    private variable m_ringSet 0
    private variable m_drawImageOK 0
    private variable m_retryID     ""

    private variable m_dirImage ""

    private variable m_strResult ""
    private variable m_ctsResult ""

    private variable m_strCondition ""
    private variable m_ctsCondition ""

    private variable m_overlay ""
    private variable m_objSampleX ""
    private variable m_objSampleY ""
    private variable m_objSampleZ ""
    private variable m_objCameraZoom ""
    private variable m_objInlineZoom ""
    private variable m_strOrig ""
    private variable m_ctsOrig ""
    private variable m_strConstant ""
    private variable m_ctsConstant ""
    private variable m_indexMap

    private variable m_cameraZoom 0

    private variable m_objMoveSample ""

    private method initializeRingSize { } {
        if {$m_rawWidth <= 0} {
            puts "cannot set ring size yet, no image"
            return 0
        }
        set imageRatio [expr 1.0 * $m_rawHeight / $m_rawWidth]
        set areaRatio  [expr 1.0 * $m_drawHeight / $m_drawWidth]

        if {$imageRatio >= $areaRatio} {
            set ringHeight $m_drawHeight
            set ringWidth [expr $ringHeight / $imageRatio]
        } else {
            set ringWidth $m_drawWidth
            set ringHeight [expr $ringWidth * $imageRatio]
        }

        pack forget $itk_component(ring)
        eval pack $itk_component(ring) $itk_option(-packOption)
        pack propagate $itk_component(ring) 0

        $itk_component(ring) configure \
        -width $ringWidth \
        -height $ringHeight

        set m_ringSet 1

        return 1
    }
    public method handleResize {winID width height} {
        #puts "handle Resize $width $height for $winID"
        if {$winID != $m_winID} {
            return
        }

        #set m_drawWidth  [expr $width -  2]
        #set m_drawHeight [expr $height - 2]
        set m_drawWidth  $width
        set m_drawHeight $height

        $itk_component(drawArea) coords notes \
        [expr $m_drawWidth / 2.0] [expr $m_drawHeight / 2.0]

        if {![initializeRingSize]} {
            return
        }

        redrawImage
        updateCurrentPosition
    }
    private method refreshSnapshot { } {
        if {$m_dirImage == ""} {
            puts "dirImage == empty"
            return
        }

        set match [lindex $m_ctsCondition 0]
        if {$match == "" || $match == 0 || $match >= 1.01} {
            configure -snapshot ""
            puts "hiding match= $match "
            return
        }
        set fn [lindex $m_ctsResult $itk_option(-resultIndex)]
        if {$fn == ""} {
            puts "fn={} result=$m_ctsResult"
            puts "resultIndex=$itk_option(-resultIndex)"
            configure -snapshot ""
            return
        }
        set fn [lindex $fn 0]
        set imageFile [file join $m_dirImage $fn]
        puts "visex file = $imageFile"
        configure \
        -showPercent [expr 100.0 * $match] \
        -snapshot $imageFile
    }
    public method handleConditionUpdate {- ready_ - contents_ -} {
        if {!$ready_} {
            return
        }
        set m_ctsCondition $contents_
        puts "condition update: $m_ctsCondition"
        refreshSnapshot
        updateCurrentPosition
        updateRegisteredComponents enableLowZoom
        updateRegisteredComponents available
        updateRegisteredComponents displayed
    }

    public method handleResultUpdate {- ready_ - contents_ -} {
        if {!$ready_} {
            return
        }

        set m_ctsResult $contents_
        refreshSnapshot
        updateCurrentPosition
        updateRegisteredComponents displayed
    }
    public method handleCameraZoomUpdate {- ready_ - contents_ -} {
        if {!$ready_} {
            return
        }
        set camera [lindex $m_ctsOrig 8]
        switch -exact -- $camera {
            sample {
                set m_cameraZoom [lindex [$m_objCameraZoom getScaledPosition] 0]
            }
            inline {
                set m_cameraZoom [lindex [$m_objInlineZoom getScaledPosition] 0]
            }
            default {
                return
            }
        }
        updateRegisteredComponents enableMedZoom
        updateRegisteredComponents enableHighZoom
    }

    public method update

    public method writeImageData { filename } {
        $m_rawImage write $filename -format JPEG
    }

    public method enableBeamPositionDisplay { }
    public method handleMotorUpdate
    public method handleOrigUpdate
    public method handleCameraConstantUpdate
    private method updateCurrentPosition { }

    public method enableClickMove { }
    public method handleClick { x y } {
        if {$_gateOutput != 1} {
            return
        }
        set x [$itk_component(drawArea) canvasx $x]
        set y [$itk_component(drawArea) canvasy $y]

        if {$m_imageWidth <= 0 || $m_imageHeight <= 0} {
            return
        }
        if {$x < 0 || $x >= $m_imageWidth || $y < 0 || $y >= $m_imageHeight} {
            return
        }

        ### here the signs are opposite of normal "moveSample".
        ### visexMoveSample is implemented with orig_move_to_marker"
        set dx [expr double($x) / $m_imageWidth  - $m_imageCenterX]
        set dy [expr double($y) / $m_imageHeight - $m_imageCenterY]

        puts "startOperation $dx $dy"
        set dx [expr $dx * $itk_option(-showPercent) / 100.0]
        set dy [expr $dy * $itk_option(-showPercent) / 100.0]
        puts "after scaled by showPercent: $dx $dy"
        $m_objMoveSample startOperation $dx $dy
    }

    protected method handleNewOutput

    private method redrawImage
    private method updateSnapshot

    public method getEnableLowZoom { } {
        set m [lindex $m_ctsCondition 0]
        if {$m == 0 || $m == 1} {
            return 0
        }
        return 1
    }
    public method getAvailable { } {
        set m [lindex $m_ctsCondition 0]
        if {![string is double -strict $m] || $m == 0} {
            return 0
        }
        return 1
    }
    public method getDisplayed { } {
        if {$itk_option(-snapshot) == ""} {
            return 0
        }
        return 1
    }
    public method getEnableMedZoom { } {
        if {abs($m_cameraZoom - 0.75) < 0.01} {
            return 0
        }
        return 1
    }
    public method getEnableHighZoom { } {
        if {abs($m_cameraZoom - 1.0) < 0.01} {
            return 0
        }
        return 1
    }

    #### available does not mean the snapshot is displayed.
    #### if showPercent is > 100%, the image will not be displayed but
    #### available == 1 so that zoom buttons will be enabled to bring
    #### the image back to display
    constructor { args } {
        ::DCS::Component::constructor {
            available      getAvailable
            displayed      getDisplayed
            enableLowZoom  getEnableLowZoom
            enableMedZoom  getEnableMedZoom
            enableHighZoom getEnableHighZoom
        }
    } {
        set nameList [::config getStr visexCameraConstantsNameList]
        foreach name {center_x center_y} {
            set m_indexMap($name) [lsearch -exact $nameList $name]
            puts "$name is at $m_indexMap($name)"
        }

        set m_dirImage [::config getStr "dcss.binary_message_location"]
        if {$m_dirImage != ""} {
            set m_dirImage [file join $m_dirImage [::config getConfigRootName]]
        } else {
            puts "dcss.binary_message_location not defined in config file"
        }

        ### need a ring so that we can set size of draw area
        itk_component add ring {
            frame $itk_interior.ring
        } {
        }

        set snapSite $itk_component(ring)

        itk_component add drawArea {
            canvas $snapSite.canvas
        } {
        }
        pack $itk_component(drawArea) -expand 1 -fill both
        pack $itk_component(ring) -expand 1 -fill both

        registerComponent $itk_component(drawArea)

        set m_winID $itk_interior
        bind $m_winID <Configure> "$this handleResize %W %w %h"

        $itk_component(drawArea) config -scrollregion {0 0 768 512}

        set m_snapshot [image create photo -palette "256/256/256"]
        #set m_snapshot [image create photo -palette 256]

        $itk_component(drawArea) create text 200 100 \
        -text "retake Emission Snapshot" \
        -font "helvetica -14 bold" \
        -tags "notes"

        $itk_component(drawArea) create image 0 0 \
        -image $m_snapshot \
        -anchor nw \
        -tags "snapshot"

        set m_rawImage [image create photo -palette "256/256/256"]
        #set m_rawImage [image create photo -palette 256]
        set m_showImage [image create photo -palette "256/256/256"]

        eval itk_initialize $args

        announceExist

        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_strResult [$deviceFactory createString visexResult]
        $m_strResult register $this contents handleResultUpdate
        set m_strCondition [$deviceFactory createString visex_snapshot_save]
        $m_strCondition register $this contents handleConditionUpdate

        set m_objCameraZoom [$deviceFactory getObjectName camera_zoom]
        $m_objCameraZoom register $this scaledPosition handleCameraZoomUpdate
        if {[$deviceFactory motorExists inline_camera_zoom]} {
            set m_objInlineZoom \
            [$deviceFactory getObjectName inline_camera_zoom]
            $m_objInlineZoom register $this scaledPosition \
            handleCameraZoomUpdate
        }

    }
    destructor {
        $m_strCondition unregister $this contents handleConditionUpdate
        $m_strResult unregister $this contents handleResultUpdate
        if {$m_overlay != ""} {
            $m_objSampleX  unregister $this scaledPosition handleMotorUpdate
            $m_objSampleY  unregister $this scaledPosition handleMotorUpdate
            $m_objSampleZ  unregister $this scaledPosition handleMotorUpdate
            $m_strOrig     unregister $this contents       handleOrigUpdate
            $m_strConstant unregister $this contents handleCameraConstantUpdate
        }
        $m_objCameraZoom unregister $this scaledPosition handleCameraZoomUpdate
        if {$m_objInlineZoom != ""} {
            $m_objInlineZoom unregister $this scaledPosition \
            handleCameraZoomUpdate
        }
    }
}
body VisexImageView::handleMotorUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    updateCurrentPosition
}
body VisexImageView::handleOrigUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    set m_ctsOrig $contents_

    updateCurrentPosition
}
body VisexImageView::handleCameraConstantUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    set m_ctsConstant $contents_

    updateShowParameters
    updateCurrentPosition
    refreshSnapshot
    updateRegisteredComponents displayed
}
body VisexImageView::enableBeamPositionDisplay { } {
    set m_overlay [DCS::Crosshair \#auto $itk_component(drawArea) \
    -color purple \
    -mode draw_none \
    -width 20 \
    -height 20]

    set deviceFactory [::DCS::DeviceFactory::getObject]
    set m_objSampleX   [$deviceFactory getObjectName sample_x]
    set m_objSampleY   [$deviceFactory getObjectName sample_y]
    set m_objSampleZ   [$deviceFactory getObjectName sample_z]
    set m_strOrig      [$deviceFactory createString visex_snapshot_orig]
    set m_strConstant  [$deviceFactory createString visex_camera_constant]

    $m_objSampleX  register $this scaledPosition handleMotorUpdate
    $m_objSampleY  register $this scaledPosition handleMotorUpdate
    $m_objSampleZ  register $this scaledPosition handleMotorUpdate
    $m_strOrig     register $this contents       handleOrigUpdate
    $m_strConstant register $this contents       handleCameraConstantUpdate

    configure -showBeamPosition 1
}
body VisexImageView::updateCurrentPosition { } {
    if {$m_overlay == ""} return

    if {!$m_drawImageOK || !$itk_option(-showBeamPosition)} {
        $m_overlay configure -mode draw_none
        return
    }
    if {[llength $m_ctsOrig] < 5} {
        $m_overlay configure -mode draw_none
        return
    }
    set x [lindex [$m_objSampleX getScaledPosition] 0]
    set y [lindex [$m_objSampleY getScaledPosition] 0]
    set z [lindex [$m_objSampleZ getScaledPosition] 0]
    set pos [calculateProjectionFromSamplePosition $m_ctsOrig $x $y $z]
    foreach {v h} $pos break

    set v [expr $v * 100.0 / $itk_option(-showPercent)]
    set h [expr $h * 100.0 / $itk_option(-showPercent)]

    #puts "from orig pos=$pos scaled to: $v $h"
    #puts "camera center = $m_imageCenterY $m_imageCenterX"
    set v [expr $m_imageCenterY + $v]
    set h [expr $m_imageCenterX + $h]

    set crosshairX [expr $h * $m_imageWidth]
    set crosshairY [expr $v * $m_imageHeight]

    $m_overlay configure -mode cross_only
    $m_overlay moveTo $crosshairX $crosshairY
}
body VisexImageView::enableClickMove { } {
    set deviceFactory [::DCS::DeviceFactory::getObject]
    set m_objMoveSample [$deviceFactory createOperation visexMoveSample]
    bind $itk_component(drawArea) <ButtonPress-1> "$this handleClick %x %y"
}
body VisexImageView::redrawImage { } {
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

    #### This is set it only once.
    #### latter part there is a comment-out code to do it every time.
    if {!$m_ringSet && ![initializeRingSize]} {
        return
    }

    set xScale [expr double($m_drawWidth)  / $m_rawWidth]
    set yScale [expr double($m_drawHeight) / $m_rawHeight]

    if {$xScale > $yScale} {
        set scale $yScale
    } else {
        set scale $xScale
    }

    set m_imageWidth  [expr int($m_rawWidth * $scale)]
    set m_imageHeight [expr int($m_rawHeight * $scale)]

    #puts "snapshot draw  size: $m_drawWidth $m_drawHeight"
    #puts "snapshot image size: $m_imageWidth $m_imageHeight"

    $itk_component(drawArea) coords notes \
    [expr $m_imageWidth / 2.0] [expr $m_imageHeight / 2.0]



    if {$itk_option(-showPercent) >= 100 \
    ||  $itk_option(-showPercent) <= 0} {
        if {$scale >= 0.75} {
            imageResizeBilinear     $m_snapshot $m_rawImage $m_imageWidth
        } else {
            imageDownsizeAreaSample $m_snapshot $m_rawImage $m_imageWidth 0 1
        }
    } else {
        set x0 [expr int($m_rawImageX0 * $m_rawWidth)]
        set x1 [expr int($m_rawImageX1 * $m_rawWidth)]
        set y0 [expr int($m_rawImageY0 * $m_rawHeight)]
        set y1 [expr int($m_rawImageY1 * $m_rawHeight)]
        puts "percent=$itk_option(-showPercent) ROI=$x0 $y0 $x1 $y1"
        $m_showImage copy $m_rawImage -from $x0 $y0 $x1 $y1 -shrink
        set scale [expr $scale * 100.0 / $itk_option(-showPercent)]
        if {$scale >= 0.75} {
            imageResizeBilinear     $m_snapshot $m_showImage $m_imageWidth
        } else {
            imageDownsizeAreaSample $m_snapshot $m_showImage $m_imageWidth 0 1
        }
    }

    #### This is set ring size for every new image.
    #$itk_component(ring) configure \
    #-width $m_imageWidth \
    #-height $m_imageHeight

    set m_drawImageOK 1
}
body VisexImageView::update { } {
    if {$m_retryID != ""} {
        after cancel $m_retryID
        set m_retryID ""
    }
    updateSnapshot
}
body VisexImageView::updateSnapshot { } {
    set pgmFile $itk_option(-snapshot)

    if {$pgmFile == ""} {
        $m_rawImage blank
        $m_snapshot blank
        set m_drawImageOK 0
        #puts "jpgfile=={}"
        return
    }

    if {[catch {
        $m_rawImage blank
        #puts "visex calling image with file=$pgmFile"
        #$m_rawImage read $pgmFile -format pgm16_auto_scale
        $m_rawImage read $pgmFile -format $itk_option(-format)

        set m_rawWidth  [image width  $m_rawImage]
        set m_rawHeight [image height $m_rawImage]

        #puts "visex image size : $m_rawWidth $m_rawHeight"

        redrawImage
        ##updateCurrentPosition
    } errMsg] == 1} {
        log_error failed to create image from pgm files: $errMsg
        puts "failed to create image from pgm files: $errMsg"
        set m_drawImageOK 0
        set m_retryID [after 1000 "$this update"]
    }
}
body VisexImageView::handleNewOutput {} {
    if { $_gateOutput == 0 } {
        $itk_component(drawArea) config -cursor watch
    } else {
      set cursor [. cget -cursor]
        $itk_component(drawArea) config -cursor $cursor 
    }
    updateBubble
}

class VisexInfoView {
    inherit ::DCS::StringFieldLevel2ViewBase

    constructor { offset args } {
        itk_component add pixelFrame {
            iwidgets::Labeledframe $m_site.pixelF \
            -labelfont "helvetica -16 bold" \
            -labelpos nw \
            -labeltext "Pixel Info"
        } {
        }
        set pixelSite [$itk_component(pixelFrame) childsite]

        itk_component add geoFrame {
            iwidgets::Labeledframe $m_site.geoF \
            -labelfont "helvetica -16 bold" \
            -labelpos nw \
            -labeltext "Geometry Info"
        } {
        }
        set geoSite [$itk_component(geoFrame) childsite]
        #puts "geoSite=$geoSite"

        ##### pixel site #######
        label $pixelSite.l00 -text "min:"
        label $pixelSite.l10 -text "max:"
        label $pixelSite.l20 -text "saturated:"
        grid $pixelSite.l00 -row 0 -column 0 -sticky e
        grid $pixelSite.l10 -row 1 -column 0 -sticky e
        grid $pixelSite.l20 -row 2 -column 0 -sticky e

        set pixelComName [list pMin pMax pNum]
        set i 1
        foreach name $pixelComName {
            itk_component add $name {
                label $pixelSite.$name \
                -anchor e \
                -background #00a040 \
                -width 6 \
                -text $name
            } {
            }
            lappend m_labelList $name $offset $i
            set row [expr $i - 1]
            grid $itk_component($name) -row $row -column 1 -sticky news \
            -padx 1 -pady 1
            incr i
        }
        grid columnconfigure $pixelSite 1 -weight 10

        label $geoSite.l01 -text "horz"
        label $geoSite.l02 -text "vert"
        label $geoSite.l10 -text "center:"
        label $geoSite.l20 -text "deviation:"

        grid $geoSite.l01 -row 0 -column 1
        grid $geoSite.l02 -row 0 -column 2
        grid $geoSite.l10 -row 1 -column 0 -sticky e
        grid $geoSite.l20 -row 2 -column 0 -sticky e

        set geoComName [list centerx centery devx devy]
        set i 4
        foreach name $geoComName {
            itk_component add $name {
                label $geoSite.$name \
                -width 5 \
                -anchor e \
                -background #00a040 \
                -text $name
            } {
            }
            lappend m_labelList $name $offset $i
            incr i
        }

        grid $itk_component(centerx) -row 1 -column 1 -sticky news  \
        -padx 1 -pady 1
        grid $itk_component(centery) -row 1 -column 2 -sticky news  \
        -padx 1 -pady 1
        grid $itk_component(devx) -row 2 -column 1 -sticky news  \
        -padx 1 -pady 1
        grid $itk_component(devy) -row 2 -column 2 -sticky news  \
        -padx 1 -pady 1
        grid columnconfigure $geoSite 1 -weight 10
        grid columnconfigure $geoSite 2 -weight 10

        pack $itk_component(pixelFrame) -side left -fill x
        pack $itk_component(geoFrame) -side left -fill x

        grid forget $itk_component(apply) $itk_component(cancel)

        eval itk_initialize $args
        announceExist

    }
}
class VisexResultView {
    inherit ::itk::Widget

    public method reset { } {
        $itk_component(process) reset
    }

    public method setFormat { fmt } {
        $itk_component(imageDisplay) configure -format pgm16_$fmt
    }

    constructor { offset args } {
        set titleList [list Background Raw Result]
        set title [lindex $titleList $offset]

        itk_component add title {
            label $itk_interior.title \
            -text $title
        } {
        }

        itk_component add imageRawDisplay {
            VisexImageView $itk_interior.imageRaw \
            -resultIndex $offset
        } {
        }

        itk_component add imageDisplay {
            VisexImageView $itk_interior.image \
            -format pgm16_normalize \
            -resultIndex $offset
        } {
        }

        itk_component add process {
            VisexFormatGenerator $itk_interior.process $this
        } {
        }

        itk_component add infoDisplay {
            VisexInfoView $itk_interior.info $offset \
            -stringName ::device::visexResult
        } {
        }

        pack $itk_component(title) -side top -fill x
        pack $itk_component(imageRawDisplay) -side top -fill both -expand 1
        pack $itk_component(imageDisplay) -side top -fill both -expand 1
        pack $itk_component(infoDisplay) -side bottom -fill x
        pack $itk_component(process) -side bottom -fill x
        eval itk_initialize $args
    }
}

class VisexStatusView {
    inherit ::DCS::StringFieldViewBase

    constructor { args } {
        itk_component add statusFrame {
            iwidgets::Labeledframe $m_site.statusF \
            -labelfont "helvetica -16 bold" \
            -labelpos nw \
            -labeltext "Status"
        } {
        }
        set statusSite [$itk_component(statusFrame) childsite]
        label $statusSite.l0 -text "State: "
        label $statusSite.l1 -text "Temperature:"
        label $statusSite.l2 -text "C"

        itk_component add cState {
            label $statusSite.cState \
            -background #00a040 \
            -width 20 \
            -text state
        } {
        }
        itk_component add cTemperature {
            label $statusSite.cTemp \
            -background #00a040 \
            -width 5 \
            -text temp
        } {
        }
        set m_labelList [list cState 0 cTemperature 1]
        
        grid $statusSite.l0 $itk_component(cState) \
        $statusSite.l1 $itk_component(cTemperature) $statusSite.l2 -padx 1

        pack $itk_component(statusFrame) -side top -fill both -expand 1

        grid forget $itk_component(apply) $itk_component(cancel)
        eval itk_initialize $args
        announceExist

        configure -stringName ::device::visexStatus
    }
}

class VisexControlView {
    inherit ::itk::Widget

    public method start { } {
        $m_opSnapshot startOperation visex
    }
    public method setExposureTime { t } {
        set cur [$m_strParameters getContents]
        set nn  [lreplace $cur 0 0 $t]
        $m_strParameters sendContentsToServer $nn
    }

    private variable m_strParameters ""
    private variable m_opSnapshot ""

    constructor { args } {
        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_strParameters [$deviceFactory createString visexParameters]
        #set m_opSnapshot    [$deviceFactory createOperation visexSnapshot]
        set m_opSnapshot    [$deviceFactory createOperation videoVisexSnapshot]

        $m_strParameters createAttributeFromField exposure_time 0

        itk_component add controlFrame {
            iwidgets::Labeledframe $itk_interior.controlF \
            -labelfont "helvetica -16 bold" \
            -labelpos nw \
            -labeltext "Control"
        } {
        }
        set controlSite [$itk_component(controlFrame) childsite]
        itk_component add start {
            DCS::Button $controlSite.start \
            -text "Start" \
            -command "$this start"
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        itk_component add exposureTime {
            DCS::Entry $controlSite.time \
            -leaveSubmit 1 \
            -state normal \
            -promptText "Exposure Time:" \
            -promptWidth 14 \
            -entryWidth 10     \
            -entryType positiveFloat \
            -entryJustify right \
            -units "s" \
            -shadowReference 1 \
            -reference "$m_strParameters exposure_time" \
            -onSubmit "$this setExposureTime %s" 
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        pack $itk_component(start) $itk_component(exposureTime) -side left
        pack $itk_component(controlFrame) -side left -expand 1 -fill x

        eval itk_initialize $args
    }
}
class VisexAttributeView {
    inherit ::itk::Widget

    public method setTemperature { t } {
        set cur [$m_strAttribute getContents]
        set nn  [lreplace $cur 0 0 $t]
        $m_strAttribute sendContentsToServer $nn
    }
    public method setIntensity { t } {
        set cur [$m_strAttribute getContents]
        set nn  [lreplace $cur 1 1 $t]
        $m_strAttribute sendContentsToServer $nn
    }

    private variable m_strAttribute ""

    constructor { args } {
        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_strAttribute [$deviceFactory createString visexAttribute]

        $m_strAttribute createAttributeFromField temperature 0
        $m_strAttribute createAttributeFromField intensity 1

        itk_component add attributeFrame {
            iwidgets::Labeledframe $itk_interior.attributeF \
            -labelfont "helvetica -16 bold" \
            -labelpos nw \
            -labeltext "Attribute Settings"
        } {
        }
        set attributeSite [$itk_component(attributeFrame) childsite]

        itk_component add temperature {
            DCS::Entry $attributeSite.t \
            -decimalPlaces 1 \
            -leaveSubmit 1 \
            -state normal \
            -promptText "Temperature:" \
            -promptWidth 14 \
            -entryWidth 10     \
            -entryType float \
            -entryJustify right \
            -units "C" \
            -shadowReference 1 \
            -reference "$m_strAttribute temperature" \
            -onSubmit "$this setTemperature %s" 
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        itk_component add intensity {
            DCS::Entry $attributeSite.i \
            -leaveSubmit 1 \
            -state normal \
            -promptText "Light Intensity (1-7):" \
            -promptWidth 24 \
            -entryWidth 2     \
            -entryType positiveInt \
            -entryJustify right \
            -shadowReference 1 \
            -reference "$m_strAttribute intensity" \
            -onSubmit "$this setIntensity %s" 
        } {
            keep -systemIdleOnly
            keep -activeClientOnly
        }

        pack $itk_component(temperature) $itk_component(intensity) -side left
        pack $itk_component(attributeFrame) -side left -expand 1 -fill x

        eval itk_initialize $args
    }
}
class VisexStaffView {
    inherit ::itk::Widget

    public method setFormat { fmt } {
        $itk_component(resultImage) setFormat $fmt
    }
    public method setBackgroundFormat { fmt } {
        $itk_component(backgroundImage) setFormat $fmt
    }
    public method setRawFormat { fmt } {
        $itk_component(rawImage) setFormat $fmt
    }

    constructor { args } {
        itk_component add pw {
            iwidgets::panedwindow $itk_interior.pw \
            -orient vertical
        } {
        }
        $itk_component(pw) add left   -minimum 100 -margin 1
        $itk_component(pw) add middle -minimum 100 -margin 1
        $itk_component(pw) add right  -minimum 100 -margin 1

        set backgroundSite [$itk_component(pw) childsite 0]
        set rawSite        [$itk_component(pw) childsite 1]
        set resultSite     [$itk_component(pw) childsite 2]
        $itk_component(pw) fraction 33.333 33.333 33.334

        set i 0
        foreach name {background raw result} {
            set site [set ${name}Site]

            itk_component add ${name}Image {
                VisexResultView $site.result $i
            } {
            }

            pack $itk_component(${name}Image) \
            -side top \
            -fill both \
            -expand 1

            incr i
        }

        $itk_component(backgroundImage) reset
        $itk_component(rawImage) reset

        frame $itk_interior.controlF
        set controlSite $itk_interior.controlF

        itk_component add status {
            VisexStatusView $controlSite.status
        } {
        }

        itk_component add attribute {
            VisexAttributeView $controlSite.attribute
        } {
        }

        itk_component add control {
            VisexControlView $controlSite.control
        } {
        }

        pack $itk_component(status) -side left
        pack $itk_component(attribute) -side left
        pack $itk_component(control) -side left

        pack $itk_interior.controlF -side top -fill x
        pack $itk_component(pw) -side top -fill both -expand 1 -anchor n

        eval itk_initialize $args
        log_error visex staff view: $this
    }
}
class VisexUserView {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem ::dcss

    itk_option define -saveVideoCmd saveVideoCmd SaveVideoCmd ""

    private variable m_objSnapshot ""
    private variable m_objMoveSample ""
    private variable m_objRotatePhi ""
    private variable m_objZoom ""
    private variable m_strSnapshotOrig ""
    protected variable minimumHorzStep [expr 1.0/354]
    protected variable minimumVertStep [expr 1.0/240]

    ### sample, inline or visex.  visex means it is standalone.
    private variable  m_matchView sample


    public method setFormat { f } {
        $itk_component(imageDisplay) configure -format pgm16_$f
    }

    public method reset { } {
        $itk_component(process) reset
    }

    public method showCrosshair { yes_ } {
        $itk_component(imageDisplay) configure -showBeamPosition $yes_
    }

    public method refresh { } {
        $m_objSnapshot startOperation $m_matchView
    }

    public method rotatePhiBy { delta_ } {
        $m_objRotatePhi startOperation $delta_
    }

    public method changeZoom { z } {
        $m_objZoom startOperation $z $m_matchView
    }

    public method saveSnapshot { } {
        set user [$itk_option(-controlSystem) getUser]

        set hint ""
        if {[catch {
            set contents [::device::robot_status getContents]
            set sampleOnGoniometer [lindex $contents 15]
            if {[llength $sampleOnGoniometer] == 3} {
                foreach {cas row col} $sampleOnGoniometer break
                set hint ${cas}${col}${row}.jpg
            }
        } errMsg]} {
            puts "failed to get filename from sample on goniometer: $errMsg"
        }

        set types [list [list JPEG .jpg]]
        set fileName [tk_getSaveFile \
        -initialdir /data/$user \
        -filetypes $types \
        -defaultextension .jpg \
        -initialfile $hint \
        ]
    
        if {$fileName == ""} {
            return
        }

        #### generate filenames for pgm16 and video snapshot
        set dir [file dirname $fileName]
        set pre [file tail $fileName]
        set pre [file rootname $pre]

        set fNPGM16 [file join $dir ${pre}.pgm]

        #### save image first
        $itk_component(imageDisplay) writeImageData $fileName
        log_warning visex image saved to $fileName

        #### save PGM16
        set fSource [$itk_component(imageDisplay) cget -snapshot]
        if {[catch {
            file copy -force $fSource $fNPGM16
            log_warning visex PGM16 image saved to $fNPGM16
        } errMsg]} {
            log_error failed to save PGM16 image: $errMsg
        }

        if {$itk_option(-saveVideoCmd) != ""} {
            eval $itk_option(-saveVideoCmd) $dir $pre
        } else {
            #log_warning no saveVideoCmd defined, skip video snapshot saving
        }
    }

    constructor { view enableSampleControl args } {
        set m_matchView $view

        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objSnapshot \
        [$deviceFactory createOperation videoVisexSnapshot]

        set m_objMoveSample \
        [$deviceFactory createOperation visexMoveSample]

        set m_objRotatePhi \
        [$deviceFactory createOperation visexRotatePhi]

        set m_objZoom \
        [$deviceFactory createOperation visexZoom]

        set m_strSnapshotOrig \
        [$deviceFactory createString visex_snapshot_orig]
        $m_strSnapshotOrig createAttributeFromField source 8

        itk_component add imageDisplay {
            VisexImageView $itk_interior.image \
            -format pgm16_normalize \
            -resultIndex 2
        } {
            keep -packOption
        }

        $itk_component(imageDisplay) enableBeamPositionDisplay
        $itk_component(imageDisplay) enableClickMove

        itk_component add process {
            VisexFormatGenerator $itk_interior.process $this
        } {
        }

        frame $itk_interior.controlF
        set controlSite $itk_interior.controlF

        itk_component add showBeamPosition {
            DCS::Checkbutton $controlSite.beam \
            -text "Show Beam Position" \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -command "$this showCrosshair %s"
        } {
        }
        $itk_component(showBeamPosition) setValue 1


        itk_component add save {
            DCS::Button $controlSite.save \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Save Snapshot" \
            -command "$this saveSnapshot"

        } {
        }
        $itk_component(save) addInput \
        "::$itk_component(imageDisplay) displayed 1 {no Snapshot displayed}"

        itk_component add refresh {
            ::DCS::Button $controlSite.snapshot \
            -text "Emission Snapshot" \
            -command "$this refresh"
        } {
        }

        itk_component add zoomLabel {
            label $controlSite.zoomLabel \
            -text "Select Zoom Level" \
            -font "helvetica -14 bold"
        } {
        }
        set zoomSite $controlSite.zoomFrame
        frame $zoomSite

        itk_component add zoomLow {
            ::DCS::Button $zoomSite.zLow \
            -text "Low" \
            -command "$this changeZoom low"
        } {
        }
        itk_component add zoomMed {
            ::DCS::Button $zoomSite.zMed \
            -text "Med" \
            -command "$this changeZoom med"
        } {
        }
        itk_component add zoomHigh {
            ::DCS::Button $zoomSite.zHigh \
            -text "High" \
            -command "$this changeZoom high"
        } {
        }
        pack $itk_component(zoomLow) -side left
        pack $itk_component(zoomMed) -side left
        pack $itk_component(zoomHigh) -side left

        foreach name {zoomLow zoomMed zoomHigh} {
            $itk_component($name) addInput \
            "::$itk_component(imageDisplay) available 1 {retake snapshot first}"
        }
        $itk_component(zoomLow) addInput \
        "::$itk_component(imageDisplay) enableLowZoom 1 {already at low zoom}"
        $itk_component(zoomMed) addInput \
        "::$itk_component(imageDisplay) enableMedZoom 1 {already at med zoom}"
        $itk_component(zoomHigh) addInput \
        "::$itk_component(imageDisplay) enableHighZoom 1 {already at high zoom}"

        # make the Phi +90 button
        itk_component add plus90 {
            DCS::Button $controlSite.plus90 \
            -text "Rotate Phi 90 and Take Snapshot" \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -command "$this rotatePhiBy 90"
        } {
        }
        $itk_component(plus90) addInput \
        "::$itk_component(imageDisplay) displayed 1 {no Snapshot displayed}"

        pack $itk_component(showBeamPosition) -side top
        pack $itk_component(refresh) -side top
        pack $itk_component(zoomLabel) -side top
        pack $zoomSite -side top
        pack $itk_component(plus90) -side top
        pack $itk_component(save) -side top

        grid $itk_interior.controlF       -row 0 -column 0 -sticky n
        grid $itk_component(imageDisplay) -row 0 -column 1 -sticky news
        grid $itk_component(process) -row 1 -column 0 -columnspan 2 -sticky we

        grid columnconfigure $itk_interior 1 -weight 10
        grid rowconfigure $itk_interior 0 -weight 10

        eval itk_initialize $args
    }
}

class VisexTab {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_inConstructor 0

    private variable m_sampleVideo ""
    private variable m_inlineVideo ""

    private variable m_objVisexSnapshot ""

    public method addChildVisibilityControl { args } {
        eval $itk_component(sample_video) addChildVisibilityControl $args
    }

    public method takeSnapshots { inline } {
        if {$inline} {
            set from inline
        } else {
            set from sample
        }
        $m_objVisexSnapshot startOperation $from
    }

    public method saveAllVideoSnapshot { dir pre } {
        if {$m_sampleVideo != ""} {
            if {[catch {
                set filename [file join $dir ${pre}_sampleVideo.jpg]
                $m_sampleVideo saveVideoSnapshot $filename
            } errMsg]} {
                log_error failed to save sample video snapshot: $errMsg
            }
        }
        if {$m_inlineVideo != ""} {
            if {[catch {
                set filename [file join $dir ${pre}_inlineVideo.jpg]
                $m_inlineVideo saveVideoSnapshot $filename
            } errMsg]} {
                log_error failed to save inline video snapshot: $errMsg
            }
        }
    }

    constructor { args } {
        global gMotorBeamWidth
        global gMotorBeamHeight
        global gInlineCameraExists

        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objVisexSnapshot [$deviceFactory createOperation \
        videoVisexSnapshot]

        itk_component add pw {
            iwidgets::panedwindow $itk_interior.pw \
            -orient horizontal
        } {
        }

        $itk_component(pw) add top     -minimum 100 -margin 1
        $itk_component(pw) add bottom  -minimum 100 -margin 1
        set visexSite [$itk_component(pw) childsite 0]
        set videoSite [$itk_component(pw) childsite 1]
        $itk_component(pw) fraction 48 52

        if {$gInlineCameraExists} {
            itk_component add sample_video {
                DCS::BeamlineVideoNotebook $videoSite.v \
                [list COMBO_SAMPLE_ONLY COMBO_INLINE_ONLY] \
                -beamWidthWidget ::device::$gMotorBeamWidth \
                -beamHeightWidget ::device::$gMotorBeamHeight \
                -brightness 20 \
            } {
                keep -videoParameters
                keep -videoEnabled
                keep -packOption
            }

            set m_sampleVideo [$itk_component(sample_video) getSampleVideo]
            $m_sampleVideo configSnapshotButton \
            -systemIdleOnly 1 \
            -activeClientOnly 1 \
            -text "Emission Snapshot" \
            -command "$this takeSnapshots 0"

            set m_inlineVideo [$itk_component(sample_video) getInlineVideo]
            $m_inlineVideo configSnapshotButton \
            -systemIdleOnly 1 \
            -activeClientOnly 1 \
            -text "Emission Snapshot" \
            -command "$this takeSnapshots 1"

        } else {
            itk_component add sample_video {
                DCS::BeamlineVideoNotebook $videoSite.v \
                Sample \
                -beamWidthWidget ::device::$gMotorBeamWidth \
                -beamHeightWidget ::device::$gMotorBeamHeight \
                -brightness 20 \
            } {
                keep -videoParameters
                keep -videoEnabled
                keep -packOption
            }

            set m_sampleVideo [$itk_component(sample_video) getSampleVideo]
            $m_sampleVideo configSnapshotButton \
            -systemIdleOnly 1 \
            -activeClientOnly 1 \
            -text "Emission Snapshot" \
            -command "$this takeSnapshots 0"
        }

        itk_component add visex {
            VisexUserView $visexSite.v sample 0 \
            -saveVideoCmd "$this saveAllVideoSnapshot"
        } {
            keep -packOption
        }
        pack $itk_component(sample_video) \
        -side bottom -expand 1 -fill both -anchor s

        pack $itk_component(visex) -side bottom -expand 1 -fill both

        pack $itk_component(pw) -side left -expand 1 -fill both
        eval itk_initialize $args
    }
}
