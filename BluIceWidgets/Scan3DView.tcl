package provide Scan3DView 1.0

package require Iwidgets
package require BWidget

package require DCSComponent
package require ComponentGateExtension
package require DCSDeviceFactory
package require DCSDeviceView
package require DCSUtil
package require DCSContour
#package require BLUICESamplePosition
package require BLUICEVideoNotebook

global gRasterTab
set gRasterTab ""

class SnapshotWidthGridView {
     inherit ::DCS::ComponentGateExtension

    itk_option define -snapshot   snapshot   Snapshot   ""        { update }
    itk_option define -beamCenter beamCenter BeamCenter {0.5 0.5} {
        update
        #redrawOverlay
        #generateGridImage
    }

    itk_option define -gridInfo   gridInfo   GridInfo   {0.0 0.0 0.2 0.2 1 1} {
        #puts "$this gridInfo: $itk_option(-gridInfo)"
        update
        #redrawOverlay
        #generateGridImage
    }

    itk_option define -onAreaDefining onAreaDefining OnAreaDefining ""

    itk_option define -packOption packOption PackOption "-side top"

    itk_option define -showInsideGrid showInsideGrid ShowInsideGrid 1 {
        $m_overlay configure \
        -grid_border_only [expr !$itk_option(-showInsideGrid)]
    }

    private variable m_rawImage ""
    private variable m_gridImage ""
    private variable m_flipHorz    0
    private variable m_flipVert    0

    private variable m_rawWidth    0
    private variable m_rawHeight   0

    private variable m_imageWidth  0
    private variable m_imageHeight  0

    private variable m_snapshot

    private variable m_winID "no defined"
    private variable m_drawWidth  0
    private variable m_drawHeight 0

    # This ring decide the boundary of the image.
    # Without it, the whole canvas is the image and will sense the mouse click.
    # It needs the ratio of the image width and height.
    # The ratio will be calculated from the first image and
    # we assume it does not change.
    # 
    # Another way is to get it from the sample camera parameters.
    #
    # You also can adjust it every time when you get an image.
    private variable m_ringSet    0

    private variable m_drawImageOK 0
    private variable m_retryID     ""

    private variable m_overlay ""

    private variable m_b1PressX 0
    private variable m_b1PressY 0

    private variable m_b1ReleaseX 0
    private variable m_b1ReleaseY 0

    private common COLOR_GRID yellow

    private method redrawImage
    private method redrawOverlay
    private method updateSnapshot

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

    private method generateGridImage

    protected method handleNewOutput

    public method update
    public method getGridImage { } {
        return [list $m_gridImage $m_flipHorz $m_flipVert]
    }

    public method handleImageClick {x y} {
        $itk_component(drawArea) delete -tag dash_area
	    if { $_gateOutput == 1 } {
            set x [$itk_component(drawArea) canvasx $x]
            set y [$itk_component(drawArea) canvasy $y]

            set m_b1PressX $x
            set m_b1PressY $y
        }
    }
    public method handleImageMotion {x y} {
	    if { $_gateOutput == 1 } {
            set x [$itk_component(drawArea) canvasx $x]
            set y [$itk_component(drawArea) canvasy $y]

            set m_b1ReleaseX $x
            set m_b1ReleaseY $y
            $itk_component(drawArea) delete -tag dash_area
            $itk_component(drawArea) create rectangle \
            $m_b1PressX $m_b1PressY $m_b1ReleaseX $m_b1ReleaseY \
            -width 1 \
            -outline green \
            -dash . \
            -tags dash_area
        }
    }
    public method handleImageRelease {x y} {
	    if { $_gateOutput != 1 } {
            return
        }
        $itk_component(drawArea) delete -tag dash_area
        if {$m_imageWidth <=0 || $m_imageHeight <=0} {
            log_error NO IMAGE displayed, click ignored
            return
        }

        set x [$itk_component(drawArea) canvasx $x]
        set y [$itk_component(drawArea) canvasy $y]

        set m_b1ReleaseX $x
        set m_b1ReleaseY $y

        if {$m_b1PressX  < 0 || $m_b1PressX   >= $m_imageWidth \
        || $m_b1PressY   < 0 || $m_b1PressY   >= $m_imageHeight \
        || $m_b1ReleaseX < 0 || $m_b1ReleaseX >= $m_imageWidth \
        || $m_b1ReleaseY < 0 || $m_b1ReleaseY >= $m_imageHeight \
        } {
            puts "clicked empty area"
            return
        }

        set x0 [expr double($m_b1PressX) / $m_imageWidth]
        set x1 [expr double($m_b1ReleaseX) / $m_imageWidth]
        set y0 [expr double($m_b1PressY) / $m_imageHeight]
        set y1 [expr double($m_b1ReleaseY) / $m_imageHeight]

        set cmd $itk_option(-onAreaDefining)
        if {$cmd != ""} {
            eval $cmd $x0 $y0 $x1 $y1
        }
    }

    public method handleResize {winID width height} {
        puts "handle Resize $width $height for $winID"
        if {$winID != $m_winID} {
            return
        }

        #set m_drawWidth  [expr $width -  2]
        #set m_drawHeight [expr $height - 2]
        set m_drawWidth  $width
        set m_drawHeight $height

        if {![initializeRingSize]} {
            return
        }

        redrawImage
        redrawOverlay
    }
    constructor { args } {
        ::DCS::Component::constructor { gridImage getGridImage }
    } {

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

        set m_overlay [DCS::Crosshair \#auto $itk_component(drawArea) \
        -mode draw_none
        ]

        #set m_winID $itk_component(drawArea)
        set m_winID $itk_interior
        bind $m_winID <Configure> "$this handleResize %W %w %h"

        $itk_component(drawArea) config -scrollregion {0 0 352 240}

        set m_snapshot [image create photo -palette "256/256/256"]

        $itk_component(drawArea) create image 0 0 \
        -image $m_snapshot \
        -anchor nw \
        -tags "snapshot"

        set m_rawImage [image create photo -palette "256/256/256"]
        set m_gridImage [image create photo -palette "256/256/256"]

        eval itk_initialize $args

        ### we need support of defining scan area like on the video
        bind $itk_component(drawArea) <B1-Motion> "$this handleImageMotion %x %y"
        bind $itk_component(drawArea) <ButtonPress-1> "$this handleImageClick %x %y"
        bind $itk_component(drawArea) <ButtonRelease-1> "$this handleImageRelease %x %y"

        announceExist
    }
}
body SnapshotWidthGridView::update { } {
    if {$m_retryID != ""} {
        after cancel $m_retryID
        set m_retryID ""
    }
    updateSnapshot
    redrawOverlay
    catch {
        generateGridImage
        updateRegisteredComponents gridImage
    }
}
body SnapshotWidthGridView::updateSnapshot { } {
    set jpgFile $itk_option(-snapshot)

    if {$jpgFile == ""} {
        $m_rawImage blank
        $m_snapshot blank
        set m_drawImageOK 0
        puts "jpgfile=={}"
        return
    }

    if {[catch {
        $m_rawImage blank
        $m_rawImage configure -file $jpgFile

        set m_rawWidth  [image width  $m_rawImage]
        set m_rawHeight [image height $m_rawImage]

        puts "image size : $m_rawWidth $m_rawHeight"

        redrawImage
    } errMsg] == 1} {
        log_error failed to create image from jpg files: $errMsg
        puts "failed to create image from jpg files: $errMsg"
        set m_drawImageOK 0
        set m_retryID [after 1000 "$this update"]
    }
}
body SnapshotWidthGridView::generateGridImage { } {
    set m_flipHorz 0
    set m_flipVert 0
    if {$m_rawImage == ""} {
        $m_gridImage blank
        return
    }
    foreach {x y} $itk_option(-beamCenter) break
    foreach {offH offV w h c r} $itk_option(-gridInfo) break
    if {$x <= 0 || $y <= 0 || $w == 0 || $h == 0} {
        $m_gridImage blank
        return
    }
    set x1 [expr $x + $offH - 0.5 * $w]
    set y1 [expr $y + $offV - 0.5 * $h]
    set x2 [expr $x1 + $w]
    set y2 [expr $y1 + $h]

    #puts "grid $this fraction: $x1 $y1 $x2 $y2"
    if {$x1 < 0} {
        set x1 0
    }
    if {$y1 < 0} {
        set y1 0
    }
    if {$x2 > 1} {
        set x2 1
    }
    if {$y2 > 1} {
        set y2 1
    }

    set x1 [expr int($x1 * $m_rawWidth)]
    set y1 [expr int($y1 * $m_rawHeight)]
    set x2 [expr int($x2 * $m_rawWidth)]
    set y2 [expr int($y2 * $m_rawHeight)]
    puts "pixel: $x1 $y1 $x2 $y2"

    if {$x1 < 0 || $y1 < 0 || $x2 < 0 || $y2 < 0} {
        $m_gridImage blank
        return
    }
    $m_gridImage copy $m_rawImage -from $x1 $y1 $x2 $y2 -shrink
    if {$w < 0} {
        set m_flipHorz 1
        puts "set flipHorz to 1"
    }
    if {$h < 0} {
        set m_flipVert 1
        puts "set flipVert to 1"
    }
}
body SnapshotWidthGridView::redrawImage { } {
    if {$m_drawWidth < 1 || $m_drawHeight < 1} {
        set m_drawImageOK 0
        puts "draw size < 1"
        return
    }
    if {$m_rawImage == ""} {
        $m_snapshot blank
        set m_drawImageOK 0
        puts "empty rawImage"
        return
    }

    if {$m_rawWidth < 1 || $m_rawHeight < 1} {
        $m_snapshot blank
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

    puts "snapshot draw  size: $m_drawWidth $m_drawHeight"
    puts "snapshot image size: $m_imageWidth $m_imageHeight"

    if {$scale >= 0.75} {
        imageResizeBilinear     $m_snapshot $m_rawImage $m_imageWidth
    } else {
        imageDownsizeAreaSample $m_snapshot $m_rawImage $m_imageWidth 0 1
    }

    #### This is set ring size for every new image.
    #$itk_component(ring) configure \
    #-width $m_imageWidth \
    #-height $m_imageHeight

    set m_drawImageOK 1
}
body SnapshotWidthGridView::redrawOverlay { } {
    if {!$m_drawImageOK} {
        puts "skip overlay snapshot display not ready"
        $m_overlay configure -mode draw_none
        return
    }

    foreach {x y} $itk_option(-beamCenter) break
    foreach {offH offV w h c r} $itk_option(-gridInfo) break
    if {$x <= 0 || $y <= 0 || $w == 0 || $h == 0} {
        puts "skip overlay numbers not ready $x $y $w $h"
        $m_overlay configure -mode draw_none
        return
    }
    
    $m_overlay configure \
    -mode grid_only

    set crosshairX [expr $m_imageWidth  * $x]
    set crosshairY [expr $m_imageHeight * $y]

    $m_overlay moveTo $crosshairX $crosshairY

    set blockOffH   [expr $m_imageWidth  * $offH]
    set blockOffV   [expr $m_imageHeight * $offV]
    set blockWidth  [expr $m_imageWidth  * $w]
    set blockHeight [expr $m_imageHeight * $h]
    $m_overlay setGrid $blockOffH $blockOffV $blockWidth $blockHeight $c $r $COLOR_GRID
}
body SnapshotWidthGridView::handleNewOutput {} {
    if { $_gateOutput == 0 } {
        $itk_component(drawArea) config -cursor watch
#"@stop.xbm black"
    } else {
      set cursor [. cget -cursor]
        $itk_component(drawArea) config -cursor $cursor 
    }
    updateBubble
}

class Scan3DMatrixView {
    inherit ::itk::Widget ::DCS::Component

    ## for beamsize
    itk_option define -beamWidthWidget beamWidthWidget BeamWidthWidget ""
    itk_option define -beamHeightWidget beamHeightWidget BeamHeightWidget ""

    itk_option define -diffractionImageViewer diffractionImageViewer \
    DiffractionImageViewer ""

    ### no dynamic
    itk_option define -imageSources imageSources ImageSources "" {
        if {$itk_option(-imageSources) != ""} {
            foreach {s0 s1} $itk_option(-imageSources) break
            $s0 register $this gridImage handleImageUpdate0
            $s1 register $this gridImage handleImageUpdate1
        }
    }

    itk_option define -hintGenerator hintGenerator HintGenerator ""

    public method getState { } {
        return $m_rasterState
    }
    public method getBusy { } {
        if {[string first ing $m_rasterState] >= 0} {
            return 1
        } else {
            return 0
        }
    }

    public method getUptodate { } {
        if {$m_info0Initialized \
        && $m_info1Initialized \
        && $m_setup0Initialized \
        && $m_setup1Initialized} {
            return 1
        }
        if {$m_ctsScan3DStatus == $m_currentFile} {
            return 1
        } else {
            return 0
        }
    }

    public method handleImageUpdate0
    public method handleImageUpdate1

    public method handleMotorUpdate
    public method handleMarkerMovement
    private method updateCurrentPosition
    private method updateBeamsize {{draw 1}}

    public method handleOperationEvent
    public method handleFileNameChange

    public method showDiffractionFile { index row column }

    public method handleResize { winID w h }

    public method moveToMark { area_index v h } {
        set x [lindex [$m_objSampleX getScaledPosition] 0]
        set y [lindex [$m_objSampleY getScaledPosition] 0]
        set z [lindex [$m_objSampleZ getScaledPosition] 0]
        set o [lindex [$m_objOmega   getScaledPosition] 0]

        set setup [set m_setup$area_index]

        set a [lindex $setup 3]
        set phi [expr $a - $o]

        foreach {dx dy dz} \
        [calculateSamplePositionDeltaFromProjection \
        $setup $x $y $z $v $h] break
        puts "$dx $dy $dz phi=$phi"
        $m_objMoveMotors startOperation 0 \
        "gonio_phi to $phi" \
        "sample_x by $dx" "sample_y by $dy" "sample_z by $dz"
    }

    public method handleMarkMovement0
    public method handleMarkMovement1

    public method handleClick { x y } {
        set m_rightClick 0
        $itk_component(area0) click $x $y
        $itk_component(area1) click $x $y
    }
    public method handleRightClick { x y } {
        set m_rightClick 1
        $itk_component(area0) click $x $y
        $itk_component(area1) click $x $y
    }
    public method removeMark { mark_num } {
        $itk_component(area0) removeMark $mark_num
        $itk_component(area1) removeMark $mark_num
    }
    public method handleBeamsizeUpdate { object_ ready_ - value_ - }
    public method handleRasterStateUpdate { object_ ready_ - value_ - }

    public method handleMotion { x y } {
        #puts "motion $x $y"
        set newNode ""
        if {$x > $m_pixHOff0 && $x < $m_xEnd0 \
        && $y < $m_yEnd0} {
            set row [expr int($y / $m_pixNodeHeight)]
            set col [expr int(($x - $m_pixHOff0) / $m_pixNodeWidth0)]
            set index [expr $row * $m_numColumn0 + $col]

            ### display start from 1 not 0
            incr row
            incr col
            #puts "area 0: $row $col index=$index"
            set newNode [list 0 $index $row $col]
        } elseif {$x > $m_pixHOff1 && $x < $m_xEnd1 \
        && $y > $m_pixVOff1 && $y < $m_yEnd1} {
            set row [expr int(($y - $m_pixVOff1) / $m_pixNodeHeight)]
            set col [expr int(($x - $m_pixHOff1) / $m_pixNodeWidth1)]
            set index [expr $row * $m_numColumn1 + $col]

            ### display start from 1 not 0
            incr row
            incr col
            #puts "area 1: $row $col index=$index"
            set newNode [list 1 $index $row $col]
        }
        if {$m_showingNode != $newNode} {
            killHint
            set m_showingNode $newNode
            puts "calling updateHint in motion: $m_showingNode"
            updateHint
        }
    }

    public method killHint { }
    private method generateHint { node }

    private method repositionAreas { }
    private proc getZ { orig }
    private proc emptyToZero { value } {
        if {[string is double -strict $value]} {
            return $value
        }
        return 0
    }
    private method updateNormalizedParameters
    # changed to public so that it can be used in loading the previous rasters.
    public method initializeFromFile { path_ }

    private method handleSetup0
    private method handleSetup1
    private method updateRasterState

    private method updateHint { } {
        $itk_component(s_canvas) delete info_balloon

        if {$m_showingNode != ""} {
            set hint "Raster [lrange $m_showingNode 2 3]"
            set cts [generateHint $m_showingNode]
            if {$cts != ""} {
                append hint ": $cts"
            }
            puts "new hint: $hint"
            $itk_component(s_canvas) create text 10 $m_hintY \
            -font "helvetica -12 bold" \
            -fill black \
            -text $hint \
            -anchor nw \
            -tags info_balloon
        } else {
            ## to display the raster size
            killHint
        }
    }
    private method checkHintDisplay { } {
        if {$m_showingNode != ""} {
            foreach {view_index index} $m_showingNode break
            incr index
            if {$view_index == 0} {
                set newInfo [lindex $m_info0 $index]
            } else {
                set newInfo [lindex $m_info1 $index]
            }
            if {$newInfo != $m_showingInfo} {
                #puts "newInfo=$newInfo"
                #puts "oldInfo=$m_showingInfo"
                updateHint
            }
        }
    }
    private method checkBeamDisplay { } {
        #puts "checking beam display"
        if {$m_rasterState == "idle"} {
            set shouldDisplay 1
        } else {
            set shouldDisplay 0
        }
        #puts "should show=$shouldDisplay"
        if {$m_beamDisplaying != $shouldDisplay} {
            set m_beamDisplaying $shouldDisplay
            if {$m_beamDisplaying} {
                $itk_component(area0) configure \
                -markerStyle cross_only
                $itk_component(area1) configure \
                -markerStyle cross_only
                puts "set beaminfo to both"
            } else {
                $itk_component(area0) configure \
                -markerStyle none
                $itk_component(area1) configure \
                -markerStyle none
                puts "set beaminfo to none"
            }
        }
    }

    private variable m_rasterState idle
    private variable m_setup0Initialized 0
    private variable m_setup1Initialized 0
    private variable m_info0Initialized 0
    private variable m_info1Initialized 0
    private variable m_setup0OK 0
    private variable m_setup1OK 0
    private variable m_setup0 ""
    private variable m_info0 ""
    private variable m_setup1 ""
    private variable m_info1 ""
    private variable m_objManualRastering ""
    private variable m_objScan3DFlip ""
    private variable m_objScan3DSetup ""
    private variable m_objScan3DStatus ""
    private variable m_objRasterState ""

    private variable m_ctsScan3DStatus ""
    private variable m_currentFile "not_exists"

    private variable m_image0 ""
    private variable m_image1 ""

    ### generated from m_setup0 and m_setup1
    private variable m_pattern0 ""
    private variable m_pattern1 ""
    private variable m_ext0 ""
    private variable m_ext1 ""

    private variable m_objSampleX
    private variable m_objSampleY
    private variable m_objSampleZ
    private variable m_objOmega

    private variable m_objMoveMotors

    private variable m_winID "not defined yet"
    private variable m_drawWidth 0
    private variable m_drawHeight 0

    ###normalized parameters
    private variable m_offsetH0 0
    private variable m_offsetH1 0
    private variable m_cellSizeH0 0.1
    private variable m_cellSizeH1 0.1
    private common   SPACER_SIZE 40

    ### sample_z
    private variable m_startZ0 ""
    private variable m_startZ1 ""
    private variable m_endZ0   ""
    private variable m_endZ1   ""

    private variable m_ZColumnOpposite 1

    private variable m_img0 ""
    private variable m_img1 ""

    private variable m_rightClick 0

    private variable m_inConstructor 1

    ### for handle motion
    ## node height is the same for both raster displays.
    private variable m_showingNode   ""
    private variable m_showingInfo   ""
    private variable m_pixNodeHeight  0
    private variable m_numRow0     0
    private variable m_numColumn0  0
    ##private variable m_pixVOff0  0;##always 0
    private variable m_pixHOff0       0
    private variable m_pixNodeWidth0  0
    private variable m_numRow1        0
    private variable m_numColumn1     0
    private variable m_pixVOff1       0
    private variable m_pixHOff1       0
    private variable m_pixNodeWidth1  0
    ###derived
    private variable m_yEnd0          0
    private variable m_yEnd1          0
    private variable m_xEnd0          0
    private variable m_xEnd1          0

    private variable m_beamsizeContents "0 0 white"

    private variable m_hintY 0

    ### we want to only display beam cross and box after all done
    private variable m_beamDisplaying 1

    private common STATUS_FINISHED [list aborted stopped failed done]

    constructor { args } {
        ### busy means cannot skip/stop
        ::DCS::Component::constructor { \
            state    {getState} \
            busy     {getBusy} \
            uptodate {getUptodate} \
        }
    } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objScan3DStatus    [$deviceFactory createString scan3DStatus]
        set m_objRasterState     [$deviceFactory createString rasterState]

        set m_objManualRastering [$deviceFactory createOperation manualRastering]
        set m_objScan3DFlip      [$deviceFactory createOperation scan3DFlip]
        set m_objScan3DSetup     [$deviceFactory createOperation scan3DSetup]

        set m_objSampleX   [$deviceFactory getObjectName sample_x]
        set m_objSampleY   [$deviceFactory getObjectName sample_y]
        set m_objSampleZ   [$deviceFactory getObjectName sample_z]
        set m_objOmega     [$deviceFactory getObjectName gonio_omega]

        set m_objMoveMotors [$deviceFactory getObjectName moveMotors]

        ###hidden
        itk_component add beamsize {
            BeamsizeToDisplay $itk_interior.beamsize \
        } {
            keep -beamWidthWidget
            keep -beamHeightWidget
        }
        $itk_component(beamsize) configure \
        -honorCollimator [$deviceFactory operationExists collimatorMove]

        frame $itk_interior.fG
        set graphSite $itk_interior.fG
        set controlSite $itk_interior

        itk_component add s_canvas {
            canvas $graphSite.canvas
        } {
        }
        pack $itk_component(s_canvas) -expand 1 -fill both

        set m_img0 [image create photo -palette "256/256/256"]
        set m_img1 [image create photo -palette "256/256/256"]

        $itk_component(s_canvas) create image 0 0 \
        -image $m_img0 \
        -anchor nw \
        -tags "snapshot0"

        $itk_component(s_canvas) create image 0 0 \
        -image $m_img1 \
        -anchor nw \
        -tags "snapshot1"

        itk_component add area0 {
            DCS::Floating2DScanView $graphSite.g0 $itk_component(s_canvas) \
        } {
            keep -subField -valueConverter -showContour -showValue -contour
        }
        itk_component add area1 {
            DCS::Floating2DScanView $graphSite.g1 $itk_component(s_canvas) \
        } {
            keep -subField -valueConverter -showContour -showValue -contour
        }

        set m_winID $itk_interior.fG
        bind $m_winID <Configure> "$this handleResize %W %w %h"

        pack $itk_interior.fG -side left -expand 1 -fill both

        bind $itk_component(s_canvas) <ButtonPress-1> "$this handleClick %x %y"
        bind $itk_component(s_canvas) <ButtonPress-3> "$this handleRightClick %x %y"

        eval itk_initialize $args

        $m_objScan3DStatus register $this contents handleFileNameChange
        $m_objRasterState  register $this contents handleRasterStateUpdate

        $m_objManualRastering registerForAllEvents $this handleOperationEvent
        $m_objScan3DSetup     registerForAllEvents $this handleOperationEvent
        $m_objScan3DFlip      registerForAllEvents $this handleOperationEvent

        $m_objSampleX register $this scaledPosition handleMotorUpdate
        $m_objSampleY register $this scaledPosition handleMotorUpdate
        $m_objSampleZ register $this scaledPosition handleMotorUpdate

        $itk_component(area0) registerMarkMoveCallback \
        "$this handleMarkMovement0"

        $itk_component(area1) registerMarkMoveCallback \
        "$this handleMarkMovement1"

        bind $itk_component(s_canvas) <Leave> "$this killHint"
        bind $itk_component(s_canvas) <Motion> "$this handleMotion %x %y"

        set m_inConstructor 0

        $itk_component(beamsize) register $this beamsize handleBeamsizeUpdate

        announceExist
    }
    destructor {
        $m_objManualRastering unregisterForAllEvents $this handleOperationEvent
        $m_objScan3DSetup     unregisterForAllEvents $this handleOperationEvent
        $m_objScan3DFlip      unregisterForAllEvents $this handleOperationEvent

        $m_objRasterState  unregister $this contents handleRasterStateUpdate
        $m_objScan3DStatus unregister $this contents handleFileNameChange

        $m_objSampleX unregister $this scaledPosition handleMotorUpdate
        $m_objSampleY unregister $this scaledPosition handleMotorUpdate
        $m_objSampleZ unregister $this scaledPosition handleMotorUpdate
    }
}
body Scan3DMatrixView::showDiffractionFile { index row column } {
    puts "Enter show diff: $index $row $column"
    if {$itk_option(-diffractionImageViewer) == ""} {
        return
    }

    switch -exact -- $index {
        0 {
            set pattern $m_pattern0
            set ext    $m_ext0
        }
        1 {
            set pattern $m_pattern1
            set ext    $m_ext1
        }
        default {
            return
        }
    }
    if {$pattern == "" || $ext == ""} {
        log_error image file not ready
        return
    }
    set path [format $pattern $row $column].${ext}
    puts "show diff image: $path"
    $itk_option(-diffractionImageViewer) showFile $path
}
body Scan3DMatrixView::handleFileNameChange { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    set m_ctsScan3DStatus [lindex $contents_ 0]

    if {$m_info0Initialized \
    && $m_info1Initialized \
    && $m_setup0Initialized \
    && $m_setup1Initialized} {
        updateRegisteredComponents uptodate
        return
    }
    puts "handlefile name: $contents_"

    if {$m_ctsScan3DStatus == ""} {
        updateRegisteredComponents uptodate
        return
    }

    set m_info0Initialized [initializeFromFile $m_ctsScan3DStatus]
    set m_info1Initialized $m_info0Initialized
    set m_setup0Initialized $m_info0Initialized
    set m_setup1Initialized $m_info0Initialized

    updateRegisteredComponents uptodate
}
body Scan3DMatrixView::updateRasterState { } {
    if {$m_rasterState == ""} {
        set m_rasterState idle
    }
    checkBeamDisplay

    updateRegisteredComponents state
    updateRegisteredComponents busy
}
body Scan3DMatrixView::handleSetup0 { {reloadInfo 1} } {
    set m_pattern0 [lindex $m_setup0 8]
    set m_ext0     [lindex $m_setup0 9]

    foreach {m_startZ0 m_endZ0} [getZ $m_setup0] break

    if {$m_startZ0 != ""} {
        if {$m_startZ0 > $m_endZ0} {
            set m_ZColumnOpposite 1
        } else {
            set m_ZColumnOpposite 0
        }
    }

    $itk_component(area0) clear
    set m_setup0OK 0
    if {[llength $m_setup0] < 8 || [lindex $m_setup0 0] == -999} {
        return
    }
    set m_setup0OK [$itk_component(area0) setup $m_setup0]
    if {$m_setup0OK && $reloadInfo} {
        #puts "setValues for 0: $m_info0"
        $itk_component(area0) setValues $m_info0
    }
    
    updateNormalizedParameters
    repositionAreas
    killHint

    updateBeamsize 0
    updateCurrentPosition
}
body Scan3DMatrixView::handleImageUpdate0 { - targetReady_ - contents_ - } {
    if {!$targetReady_} return

    set m_image0 $contents_
    repositionAreas
}
body Scan3DMatrixView::handleImageUpdate1 { - targetReady_ - contents_ - } {
    if {!$targetReady_} return

    set m_image1 $contents_
    repositionAreas
}
body Scan3DMatrixView::handleMotorUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    updateCurrentPosition
}
body Scan3DMatrixView::updateCurrentPosition { } {
    set x [lindex [$m_objSampleX getScaledPosition] 0]
    set y [lindex [$m_objSampleY getScaledPosition] 0]
    set z [lindex [$m_objSampleZ getScaledPosition] 0]

    if {[llength $m_setup0] > 5} {
        set pos0 [calculateProjectionFromSamplePosition $m_setup0 $x $y $z]
        foreach {v0 h0} $pos0 break
    } else {
        set v0 -999
        set h0 -999
    }
    #puts "v0=$v0 h0=$h0"

    if {[llength $m_setup1] > 5} {
        set pos1 [calculateProjectionFromSamplePosition $m_setup1 $x $y $z]
        foreach {v1 h1} $pos1 break
    } else {
        set v1 -999
        set h1 -999
    }
    #puts "v1=$v1 h1=$h1"
    $itk_component(area0) setCurrentPosition $v0 $h0
    $itk_component(area1) setCurrentPosition $v1 $h1
}
body Scan3DMatrixView::handleRasterStateUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    set m_rasterState $contents_
    updateRasterState
}
body Scan3DMatrixView::handleBeamsizeUpdate { object_ ready_ - value_ - } {
    if {!$ready_} return

    set m_beamsizeContents $value_
    updateBeamsize
}
body Scan3DMatrixView::updateBeamsize { {draw 1} } {

    foreach {w h c} $m_beamsizeContents break

    puts "raster beamsize $w $h $c"

    if {[llength $m_setup0] > 5} {
        set box0 [calculateProjectionBoxFromBox $m_setup0 $w $h]
        foreach {bw0 bh0} $box0 break
    } else {
        set bw0 0
        set bh0 0
    }
    if {[llength $m_setup1] > 5} {
        set box1 [calculateProjectionBoxFromBox $m_setup1 $w $h]
        foreach {bw1 bh1} $box1 break
    } else {
        set bw1 0
        set bh1 0
    }
    puts "box size 0: $bw0 $bh0 1: $bw1 $bh1"
    #### setBoxSize Vert Horz draw
    $itk_component(area0) setBoxSize $bh0 $bw0 $draw
    $itk_component(area1) setBoxSize $bh1 $bw1 $draw
}
body Scan3DMatrixView::handleSetup1 { {reloadInfo 1} } {
    set m_pattern1 [lindex $m_setup1 8]
    set m_ext1     [lindex $m_setup1 9]

    foreach {m_startZ1 m_endZ1} [getZ $m_setup1] break
    if {$m_startZ1 != ""} {
        if {$m_startZ1 > $m_endZ1} {
            set m_ZColumnOpposite 1
        } else {
            set m_ZColumnOpposite 0
        }
    }

    $itk_component(area1) clear
    set m_setup1OK 0
    if {[llength $m_setup1] < 8 || [lindex $m_setup1 0] == -999} {
        return
    }
    set m_setup1OK [$itk_component(area1) setup $m_setup1]
    if {$m_setup1OK && $reloadInfo} {
        #puts "setValues for 1: $m_info1"
        $itk_component(area1) setValues $m_info1
    }
    
    updateNormalizedParameters
    repositionAreas
    killHint
    updateBeamsize 0
    updateCurrentPosition
}
body Scan3DMatrixView::handleOperationEvent { message_ } {
    ### we are only interested in the operation completed message.
    ### It will trigger drawing contour even the data is not fully available.
    foreach {eventType opName opId arg1 arg2 arg3} $message_ break

    #### all through this operation but we only care the rastering, not setup.
    switch -exact -- $eventType {
        stog_operation_completed {
            if {$opName == "manualRastering"} {
                set header0 [lindex $m_info0 0]
                set status0 [lindex $header0 2]
                set header1 [lindex $m_info1 0]
                set status1 [lindex $header1 2]
                switch -exact -- $status0 {
                    "" -
                    done -
                    failed -
                    stopped {
                        ### done and stopped are handled by the matrix itself.
                        ### for "", we do not want to draw contour if no data.
                    }
                    default {
                        $itk_component(area0) allDataDone
                    }
                }
                switch -exact -- $status1 {
                    "" -
                    done -
                    failed -
                    stopped {
                    }
                    default {
                        $itk_component(area1) allDataDone
                    }
                }
                if {$m_rasterState != "idle"} {
                    set m_rasterState idle
                    updateRasterState
                }
            }
        }
        stog_operation_update {
            switch -exact -- $arg1 {
                RASTER_STATE {
                    ## we are using the string now
                    #set m_rasterState $arg2
                    #updateRasterState
                }
                VIEW_SETUP0 {
                    set m_setup0Initialized 1
                    set m_setup0 $arg2
                    handleSetup0 0
                    updateRegisteredComponents uptodate
                }
                VIEW_SETUP1 {
                    set m_setup1Initialized 1
                    set m_setup1 $arg2
                    handleSetup1 0
                    updateRegisteredComponents uptodate
                }
                VIEW_DATA0 {
                    set m_info0Initialized 1
                    set m_info0 $arg2
                    checkHintDisplay
                    if {$m_setup0OK} {
                        #puts "setValues 0: $m_info0"
                        $itk_component(area0) setValues $m_info0
                    }
                    updateRegisteredComponents uptodate
                }
                VIEW_DATA1 {
                    set m_info1Initialized 1
                    set m_info1 $arg2
                    checkHintDisplay
                    if {$m_setup1OK} {
                        #puts "setValues 1: $m_info1"
                        $itk_component(area1) setValues $m_info1
                    }
                    updateRegisteredComponents uptodate
                }
                VIEW_NODE0 {
                    if {$m_info0Initialized} {
                        set offset $arg2
                        set v      $arg3
                        set m_info0 [lreplace $m_info0 $offset $offset $v]
                        if {$offset == 0} {
                        } else {
                            checkHintDisplay
                        }
                        if {$m_setup0OK} {
                            #puts "setValues node 0: $m_info0"
                            $itk_component(area0) setValues $m_info0
                        }
                    } else {
                        puts "may lost VIEW0 update $arg2 $arg3"
                    }
                }
                VIEW_NODE1 {
                    if {$m_info1Initialized} {
                        set offset $arg2
                        set v      $arg3
                        set m_info1 [lreplace $m_info1 $offset $offset $v]
                        if {$offset == 0} {
                        } else {
                            checkHintDisplay
                        }
                        if {$m_setup1OK} {
                            #puts "setValues node 1: $m_info1"
                            $itk_component(area1) setValues $m_info1
                        }
                    } else {
                        puts "may lost VIEW1 update $arg2 $arg3"
                    }
                }
            }
        }
    }
}
body Scan3DMatrixView::handleResize { winID w h } {
    if {$m_winID != $winID} {
        return
    }

    puts "resize $w $h"
    set m_drawWidth  [expr $w - 4]
    set m_drawHeight [expr $h - 4]
    repositionAreas
    killHint
}
body Scan3DMatrixView::handleMarkMovement0 { v0 h0 } {
    set h [lindex $m_setup0 6]
    set w [lindex $m_setup0 7]
    set row [expr int($v0 + $h / 2.0) + 1]
    set col [expr int($h0 + $w / 2.0) + 1]
    puts "v0=$v0 h0=$h0 h=$h w=$w"
    if {$m_rightClick} {

        set index [expr ($row - 1) * $w + $col]
        set state [lindex $m_info0 $index]
        set state [lindex $state 0]
        puts "row=$row col=$col index=$index state=$state"
        if {[string is double -strict $state] || $state == "D"} {
            showDiffractionFile 0 $row $col
        } else {
            log_warning Diffraction Image not available for VIEW 1 $row $col
            puts "info: $m_info0"
        }
        return
    }
    set rState [lindex $m_info0 0]
    set rState [lindex $rState end]
    switch -exact -- $rState {
        stopped -
        failed -
        done -
        aborted -
        {} {
            puts "moving area0 to $v0 $h0"
            moveToMark 0 $v0 $h0
        }
        default {
            $m_objScan3DFlip startOperation 0 [expr $row - 1] [expr $col - 1]
        }
    }
}
body Scan3DMatrixView::handleMarkMovement1 { v1 h1 } {
    set h [lindex $m_setup1 6]
    set w [lindex $m_setup1 7]
    set row [expr int($v1 + $h / 2.0) + 1]
    puts "v1=$v1 h1=$h1 h=$h w=$w"
    set col [expr int($h1 + $w / 2.0) + 1]
    if {$m_rightClick} {
        set index [expr ($row - 1) * $w + $col]
        set state [lindex $m_info1 $index]
        set state [lindex $state 0]
        puts "row=$row col=$col index=$index state=$state"
        if {[string is double -strict $state] || $state == "D"} {
            showDiffractionFile 1 $row $col
        } else {
            log_warning Diffraction Image not available for VIEW 2 $row $col
            puts "info: $m_info1"
        }
        return
    }
    set rState [lindex $m_info1 0]
    set rState [lindex $rState end]
    switch -exact -- $rState {
        stopped -
        failed -
        done -
        aborted -
        {} {
            puts "moving area1 to $v1 $h1"
            moveToMark 1 $v1 $h1
        }
        default {
            $m_objScan3DFlip startOperation 1 [expr $row - 1] [expr $col - 1]
        }
    }
}
body Scan3DMatrixView::getZ { setup } {
    if {[llength $setup] < 8} {
        return [list "" ""]
    }

    set numRow    [lindex $setup 6]
    set numColumn [lindex $setup 7]

    set startH [expr -0.5 * $numColumn]
    set endH   [expr  0.5 * $numColumn]

    set pos \
    [calculateSamplePositionDeltaFromProjection $setup 0 0 0 0 $startH]

    set startZ [lindex $pos 2]

    set pos \
    [calculateSamplePositionDeltaFromProjection $setup 0 0 0 0 $endH]

    set endZ [lindex $pos 2]

    return [list $startZ $endZ]
}
body Scan3DMatrixView::initializeFromFile { path_ } {
    set m_info0Initialized 0
    set m_info1Initialized 0
    set m_setup0Initialized 0
    set m_setup1Initialized 0

    if {![catch {open $path_ r} handle]} {
        gets $handle m_setup0
        gets $handle m_setup1
        gets $handle m_info0
        gets $handle m_info1
        close $handle

        ## they will load info too
        handleSetup0
        handleSetup1
        set m_currentFile $path_
        return 1
    } else {
        log_error failed to readback raster information: $handle
        return 0
    }
}
body Scan3DMatrixView::updateNormalizedParameters { } {
    set zList ""

    if {$m_startZ0 != ""} {
        lappend zList $m_startZ0 $m_endZ0
    }
    if {$m_startZ1 != ""} {
        lappend zList $m_startZ1 $m_endZ1
    }
    set zMin [lindex $zList 0]
    set zMax $zMin
    foreach z $zList {
        if {$zMin > $z} {
            set zMin $z
        }
        if {$zMax < $z} {
            set zMax $z
        }
    }
    set totalZ [expr $zMax - $zMin]
    puts "z: 0: $m_startZ0 $m_endZ0 1: $m_startZ1 $m_endZ1"

    puts "total: $totalZ:  $zMin -- $zMax"

    if {$m_startZ0 != ""} {
        set ch0 [lindex $m_setup0 5]
        if {$m_ZColumnOpposite} {
            set m_offsetH0 [expr (double($zMax)      - $m_startZ0) / $totalZ]
        } else {
            set m_offsetH0 [expr (double($m_startZ0) - $zMin)    / $totalZ]
        }
        set m_cellSizeH0 [expr abs(double($ch0)) / $totalZ]
        puts "0: offset: $m_offsetH0 cellSizeH: $m_cellSizeH0"
    }
    if {$m_startZ1 != ""} {
        set ch1 [lindex $m_setup1 5]
        if {$m_ZColumnOpposite} {
            set m_offsetH1 [expr (double($zMax)      - $m_startZ1) / $totalZ]
        } else {
            set m_offsetH1 [expr (double($m_startZ1) - $zMin)    / $totalZ]
        }
        set m_cellSizeH1 [expr abs(double($ch1)) / $totalZ]
        puts "1: offset: $m_offsetH1 cellSizeH: $m_cellSizeH1"
    }
}
body Scan3DMatrixView::repositionAreas { } {
    if {[llength $m_setup0] < 8 || [llength $m_setup1] < 8} {
        return
    }
    if {[lindex $m_setup0 0] == -999 || [lindex $m_setup1 0] == -999} {
        return
    }
    set m_numRow0    [emptyToZero [lindex $m_setup0 6]]
    set m_numColumn0 [emptyToZero [lindex $m_setup0 7]]
    set m_numRow1    [emptyToZero [lindex $m_setup1 6]]
    set m_numColumn1 [emptyToZero [lindex $m_setup1 7]]

    if {$m_numRow0 <= 0 \
    || $m_numRow0 <= 0 \
    || $m_numColumn0 <= 0 \
    || $m_numColumn1 <= 0 \
    } {
        return
    }


    set m_pixNodeHeight \
    [expr ($m_drawHeight - $SPACER_SIZE) / ($m_numRow0 + $m_numRow1)]

    if {$m_startZ0 != ""} {
        set m_pixHOff0       [expr $m_drawWidth * $m_offsetH0]
        set m_pixNodeWidth0  [expr $m_drawWidth * $m_cellSizeH0]
    } else {
        set m_pixHOff0       0
        set m_pixNodeWidth0  0
    }
    
    if {$m_startZ1 != ""} {
        set m_pixHOff1       [expr $m_drawWidth * $m_offsetH1]
        set m_pixNodeWidth1  [expr $m_drawWidth * $m_cellSizeH1]
        set m_pixVOff1       [expr $m_pixNodeHeight  * $m_numRow0 + $SPACER_SIZE]
        set m_hintY          [expr $m_pixNodeHeight  * $m_numRow0 + 10]
    } else {
        set m_pixHOff1       0
        set m_pixNodeWidth1  0
        set m_pixVOff1       0
        set m_hintY          10
    }
    set m_yEnd0 [expr $m_pixNodeHeight * $m_numRow0]
    set m_yEnd1 [expr $m_pixNodeHeight * $m_numRow1 + $m_pixVOff1]
    set m_xEnd0 [expr $m_pixNodeWidth0 * $m_numColumn0 + $m_pixHOff0]
    set m_xEnd1 [expr $m_pixNodeWidth1 * $m_numColumn1 + $m_pixHOff1]


    $itk_component(area0) reposition \
    0            $m_pixHOff0 $m_pixNodeHeight $m_pixNodeWidth0
    $itk_component(area1) reposition \
    $m_pixVOff1 $m_pixHOff1 $m_pixNodeHeight $m_pixNodeWidth0

    puts "0: 0            $m_pixHOff0 $m_pixNodeHeight $m_pixNodeWidth0"
    puts "1: $m_pixVOff1 $m_pixHOff1 $m_pixNodeHeight $m_pixNodeWidth0"

    set gridWidth0  [expr int($m_pixNodeWidth0 * $m_numColumn0)]
    set gridHeight0 [expr int($m_pixNodeHeight * $m_numRow0)]
    set gridWidth1  [expr int($m_pixNodeWidth1 * $m_numColumn1)]
    set gridHeight1 [expr int($m_pixNodeHeight * $m_numRow1)]

    puts "grid size: $gridWidth0 $gridHeight0 $gridWidth1 $gridHeight1"

    if {$gridWidth0 > 10 \
    && $gridHeight0 > 10 \
    && $gridWidth1 >  10 \
    && $gridHeight1 > 10 \
    && [llength $m_image0] > 2 \
    && [llength $m_image1] > 2 \
    } {
        foreach {img0 flipHorz0 flipVert0} $m_image0 break
        foreach {img1 flipHorz1 flipVert1} $m_image1 break

        set gw0 $gridWidth0
        set gh0 $gridHeight0
        set gw1 $gridWidth1
        set gh1 $gridHeight1
        if {$flipHorz0} {
            set gw0 [expr -1 * $gridWidth0]
            puts "get flipHorz0"
        }
        if {$flipVert0} {
            set gh0 [expr -1 * $gridHeight0]
        }
        if {$flipHorz1} {
            set gw1 [expr -1 * $gridWidth1]
            puts "get flipHorz1"
        }
        if {$flipVert1} {
            set gh1 [expr -1 * $gridHeight1]
        }

        imageResizeBilinear $m_img0 $img0 $gw0 $gh0
        imageResizeBilinear $m_img1 $img1 $gw1 $gh1
        $itk_component(s_canvas) coords snapshot0 $m_pixHOff0 0
        $itk_component(s_canvas) coords snapshot1 $m_pixHOff1 $m_pixVOff1
    }
}
body Scan3DMatrixView::generateHint { node } {
    foreach {view_index index} $node break
    incr index

    if {$view_index == 0} {
        set m_showingInfo [lindex $m_info0 $index]
    } else {
        set m_showingInfo [lindex $m_info1 $index]
    }
    if {$itk_option(-hintGenerator) == ""} {
        return $m_showingInfo
    }
    return [eval $itk_option(-hintGenerator) $m_showingInfo]
}
body Scan3DMatrixView::killHint { } {
    set m_showingNode ""
    set m_showingInfo ""
    $itk_component(s_canvas) delete info_balloon

    if {$m_setup0OK && [llength $m_setup0] > 6} {
        foreach {- - - - cv ch} $m_setup0 break
        set cv [expr abs($cv)]
        set ch [expr abs($ch)]
        set hint "Raster Size: [format %.3f $ch] X [format %.3f $cv] mm"
        $itk_component(s_canvas) create text 10 $m_hintY \
        -font "helvetica -12 bold" \
        -fill black \
        -text $hint \
        -anchor nw \
        -tags info_balloon
    }
}
class RasteringViewTab {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_objScan3DSetup ""
    private variable m_objManualRastering ""
    private variable m_objScan3DStatus ""

    private variable m_objUserSetupNormal ""
    private variable m_objUserSetupMicro ""
    private variable m_ctsUserSetupNormal ""
    private variable m_ctsUserSetupMicro ""

    private variable m_objInfo ""
    private variable m_ctsInfo ""
    private variable m_centerX  0.5
    private variable m_centerY  0.5
    private variable m_inlineCenterX  0.5
    private variable m_inlineCenterY  0.5

    private variable m_objSampleCameraConstant ""
    private variable m_objInlineCameraConstant ""

    private variable m_indexX 0
    private variable m_indexY 0

    private variable m_inConstructor 0

    private variable m_sampleVideo ""
    private variable m_inlineVideo ""

    private variable m_showingUserSetup 0

    private variable m_mapTab      [list Spots Shape Res  Score Rings]
    private variable m_mapSubField [list 0     5     3    2     4   ]
    private variable m_mapDrawTopo [list 1     0     0    0     0   ]
    private variable m_mapShowNum  [list 1     1     1    1     1   ]
    private variable m_mapFormat   [list %.0f  %.1f  %.1f %.1f  %.0f]
    ## now the format is only used by hint.

    private common s_lastObject ""

    private common COLOR_GRID #ffffff
    private common PROMPT_WIDTH 8
    private common BUTTON_WIDTH 10

    public method handleOperationEvent

    public method handleInfoChange
    public method handleBeamCenterChange
    public method handleInlineBeamCenterChange

    public method handleUserSetupNormalChange
    public method handleUserSetupMicroChange

	public method addChildVisibilityControl { args } {
	    eval $itk_component(sample_video) addChildVisibilityControl $args
    }

    public method takeSnapshots { inline } {
        $m_objScan3DSetup startOperation take_snapshot $inline
    }
    public method handleAreaDefining { index x1 y1 x2 y2 } {
        set cmd [list $m_objScan3DSetup startOperation \
        define_scan_area_on_snapshot $index $x1 $y1 $x2 $y2]

        if {![$itk_component(rasters) getUptodate]} {
            lappend cmd $m_ctsInfo
        }
        eval $cmd
    }

    public method autoFillFields { } {
        $m_objScan3DSetup startOperation auto_set
    }

    public method startScan3D { } {
        $m_objScan3DSetup startOperation start
    }

    public method stopScan3D { } {
        $itk_option(-controlSystem) sendMessage {gtos_stop_operation scan3DSetup}
        $itk_option(-controlSystem) sendMessage {gtos_stop_operation manualRastering}
    }

    public method moveScanArea {  index dir } {
        set cmd [list $m_objScan3DSetup startOperation \
        move_scan_area_on_snapshot $index $dir]

        if {![$itk_component(rasters) getUptodate]} {
            lappend cmd $m_ctsInfo
        }
        eval $cmd
    }

    public method changeScanAreaSize { name action } {
        set cmd [list $m_objScan3DSetup startOperation \
        resize_scan_area_on_snapshot $name $action]

        if {![$itk_component(rasters) getUptodate]} {
            lappend cmd $m_ctsInfo
        }
        eval $cmd
    }

    public method handleSubmit

    public method movePhi { index } {
        ### "1" means move phi only
        $m_objScan3DSetup startOperation move_to_snapshot $index 1
    }

    public method getGridImages { } {
        return [list \
        [$itk_component(snapshot0) getGridImage] \
        [$itk_component(snapshot1) getGridImage] \
        ]
    }

    public proc getObject { } {
        return $s_lastObject
    }

    public method showInsideGrid { index value } {
        $itk_component(snapshot$index) configure \
        -showInsideGrid $value
    }

    public method hideUserSetup { args } {
        if {$args == "forced"} {
            place forget $itk_component(userSetup)
            set m_showingUserSetup 0
            return
        }

        puts "hide $args"
        foreach {px py} $args break
        if {[catch {
            set x0 [winfo rootx $itk_component(userSetup)]
            set y0 [winfo rooty $itk_component(userSetup)]
            set w  [winfo width $itk_component(userSetup)]
            set h  [winfo height $itk_component(userSetup)]
        } errMsg]} {
            puts "got error: $errMsg"
            place forget $itk_component(userSetup)
            set m_showingUserSetup 0
        }
        set x1 [expr $x0 + $w]
        set y1 [expr $y0 + $h]
        if {$px > $x0 && $px < $x1 && $py > $y0 && $py < $y1} {
            puts "should be enter the drop down menu"
            return
        }
        
        place forget $itk_component(userSetup)
        set m_showingUserSetup 0
    }
    public method flipUserSetup { } {
        if {$m_showingUserSetup} {
            hideUserSetup forced
        } else {
            set xx0 [winfo rootx $itk_interior]
            set xx1 [winfo rootx $itk_component(bConfig)]
            set showingX [expr $xx1 - $xx0]
            set showingY 40
            puts "xx0=$xx0 xx1=$xx1 diff=$showingX"

            place $itk_component(userSetup) \
            -x $showingX -y $showingY -anchor n

            raise $itk_component(userSetup)
            set m_showingUserSetup 1
        }
    }

    public method hintConvert { info }
    public method handleRasterStateChange { - targetReady_ - state_ - } {
        puts "raster state: $state_"

        if {$state_ == "raster0" } {
            $itk_component(bStop) configure \
            -text "Skip"
        } else {
            $itk_component(bStop) configure \
            -text "Stop"
        }
    }

    public method showTab { index } {
        if {$m_inConstructor} {
            return
        }
        set subField [lindex $m_mapSubField $index]
        set drawContour [lindex $m_mapDrawTopo $index]
        set showNum     [lindex $m_mapShowNum  $index]
        if {$subField == ""} {
            set subField 0
            log_error wrong subField index=$index list=$m_mapSubField
        }
        if {$drawContour == ""} {
            set drawContour 1
            log_error wrong drawTopo index=$index list=$m_mapDrawTopo
        }
        if {$showNum == ""} {
            set showNum 1
            log_error wrong showNum index=$index list=$m_mapShowNum
        }
        $itk_component(rasters) configure \
        -showContour $drawContour \
        -showValue   $showNum \
        -subField    $subField \
    }

    ##############
    # interface for valueConverter
    ##############
    public method toMatrix { infoList offset }
    public method toDisplay { infoList offset }

    ## help function for toMatrix
    private method cvtNoChange   { infoList offset }
    private method cvtChangeSign { infoList offset }
    private method cvtChangeSignLimits { infoList offset min max }

    ## help function for toDisplay
    private method cvtDisplayFormat { infoList offset format }

    private method updateExposureTime
    private method updateInfo { {from_file {}} }

    ###########################################
    # to load previous raster
    ###########################################
    public method loadFile { path }

    public method uptodate { } {
        set contents [$m_objScan3DStatus getContents]
        set path [lindex $contents 0]
        loadFile $path
    }

    constructor { args } {
        global gMotorBeamWidth
        global gMotorBeamHeight
        global gInlineCameraExists

        set m_inConstructor 1
        set mList [::config getStr sampleCameraConstantsNameList]
        set m_indexX [lsearch -exact $mList zoomMaxXAxis]
        set m_indexY [lsearch -exact $mList zoomMaxYAxis]

        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objScan3DSetup     [$deviceFactory createOperation scan3DSetup]
        set m_objManualRastering \
        [$deviceFactory createOperation manualRastering]

        set m_objScan3DStatus [$deviceFactory createString scan3DStatus]

        set m_objInfo [$deviceFactory createString scan3DSetup_info]
        $m_objInfo createAttributeFromField match 0
        $m_objInfo createAttributeFromField collimator 4
        $m_objInfo createAttributeFromField width 5
        $m_objInfo createAttributeFromField height 6
        $m_objInfo createAttributeFromField depth 7
        $m_objInfo createAttributeFromField np_w 8
        $m_objInfo createAttributeFromField np_h 9
        $m_objInfo createAttributeFromField np_d 10
        $m_objInfo createAttributeFromField view_index 11
        $m_objInfo createAttributeFromField first_area_defined 12
        $m_objInfo createAttributeFromField second_area_defined 13
        $m_objInfo createAttributeFromField inline_view         14

        set m_objUserSetupNormal [$deviceFactory createString raster_user_setup_normal]
        $m_objUserSetupNormal createAttributeFromField delta 2
        $m_objUserSetupNormal createAttributeFromField time  3
        set m_objUserSetupMicro  [$deviceFactory createString raster_user_setup_micro]
        $m_objUserSetupMicro createAttributeFromField delta 2
        $m_objUserSetupMicro createAttributeFromField time  3

        set m_objSampleCameraConstant [$deviceFactory createString \
        sample_camera_constant]

        set m_objInlineCameraConstant [$deviceFactory createString \
        inline_sample_camera_constant]

        itk_component add pw {
            iwidgets::panedwindow $itk_interior.pw \
            -orient vertical
        } {
        }

        itk_component add userSetup {
            Scan3DUserSetup $itk_interior.userSetup
        } {
        }
        ### only hide upon click the Setup button again
        #bind $itk_component(userSetup) <Leave> "$this hideUserSetup %X %Y"

        $itk_component(pw) add left   -minimum 100 -margin 1
        $itk_component(pw) add middle -minimum 100 -margin 1
        $itk_component(pw) add right  -minimum 100 -margin 1
        set videoSite     [$itk_component(pw) childsite 0]
        set snapshotSite  [$itk_component(pw) childsite 1]
        set gridSite      [$itk_component(pw) childsite 2]
        $itk_component(pw) fraction 40 40 20

        itk_component add pwv {
            iwidgets::panedwindow $videoSite.pwt \
            -orient horizontal
        } {
        }
        $itk_component(pwv) add top     -minimum 100 -margin 1
        $itk_component(pwv) add bottom  -minimum 100 -margin 1
        set sampleSite      [$itk_component(pwv) childsite 0]
        set diffSite      [$itk_component(pwv) childsite 1]
        $itk_component(pwv) fraction 50 50

        if {$gInlineCameraExists} {
            itk_component add sample_video {
                DCS::BeamlineVideoNotebook $sampleSite.v \
                [list COMBO_SAMPLE_ONLY COMBO_INLINE_ONLY] \
                -beamWidthWidget ::device::$gMotorBeamWidth \
                -beamHeightWidget ::device::$gMotorBeamHeight \
                -brightness 20 \
            } {
                keep -videoParameters
                keep -videoEnabled
            }

            set m_sampleVideo [$itk_component(sample_video) getSampleVideo]
            $m_sampleVideo configSnapshotButton \
            -systemIdleOnly 1 \
            -activeClientOnly 1 \
            -text "Normal Raster" \
            -command "$this takeSnapshots 0"

            $m_sampleVideo configCenterLoopButton \
            -command "$this autoFillFields"

            set m_inlineVideo [$itk_component(sample_video) getInlineVideo]
            $m_inlineVideo configSnapshotButton \
            -systemIdleOnly 1 \
            -activeClientOnly 1 \
            -text "Micro Raster" \
            -command "$this takeSnapshots 1"

            $m_inlineVideo configCenterLoopButton \
            -command "$this autoFillFields"
        } else {
            itk_component add sample_video {
                DCS::BeamlineVideoNotebook $sampleSite.v \
                Sample \
                -beamWidthWidget ::device::$gMotorBeamWidth \
                -beamHeightWidget ::device::$gMotorBeamHeight \
                -brightness 20 \
            } {
                keep -videoParameters
                keep -videoEnabled
            }

            set m_sampleVideo [$itk_component(sample_video) getSampleVideo]
            $m_sampleVideo configSnapshotButton \
            -systemIdleOnly 1 \
            -activeClientOnly 1 \
            -text "Normal Raster" \
            -command "$this takeSnapshots 0"

            $m_sampleVideo configCenterLoopButton \
            -command "$this autoFillFields"

        }
        itk_component add diff_viewer {
            DiffImageViewer $diffSite.d \
            -showPause 1 \
            -filenameJustify right \
            -orientation landscape \
            -imageServerHost [::config getImgsrvHost] \
            -imageServerHttpPort [::config getImgsrvHttpPort] \
            -brightness 20 \
        } {
        }

        pack $itk_component(sample_video) \
        -side bottom -expand 1 -fill both -anchor s
        pack $itk_component(diff_viewer) -side top -expand 1 -fill both

        itk_component add s_frame0 {
            frame $snapshotSite.f0
        } {
        }
        itk_component add s_frame1 {
            frame $snapshotSite.f1
        } {
        }

        set snapSite0 $itk_component(s_frame0)
        set snapSite1 $itk_component(s_frame1)

        itk_component add phi0_frame {
            frame $snapSite0.phi0F
        } {
        }

        itk_component add phi0 {
            label $snapSite0.phi0F.phi0 \
            -text "Phi=0"
        } {
        }

        itk_component add time0 {
            label $snapSite0.phi0F.time0 \
            -text ""
        } {
        }

        itk_component add movePhi0 {
            DCS::Button $snapSite0.phi0F.move0 \
            -text "Move to" \
            -command "$this movePhi 0"
        } {
        }
        itk_component add moveArea0 {
            DCS::AreaMoveArrows $snapSite0.phi0F.ma0 \
	        -leftCommand  "$this moveScanArea 0 left" \
            -rightCommand "$this moveScanArea 0 right" \
            -upCommand    "$this moveScanArea 0 up" \
            -downCommand  "$this moveScanArea 0 down" \
        } {
        }
        itk_component add insideGrid0 {
            DCS::Checkbutton $snapSite0.phi0F.ingrid0 \
            -text "Show Grid" \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -command "$this showInsideGrid 0 %s"
        } {
        }
        $itk_component(insideGrid0) setValue 1

        pack $itk_component(movePhi0) -side left
        pack $itk_component(phi0)     -side left
        pack $itk_component(moveArea0)     -side right
        pack $itk_component(insideGrid0)     -side right
        pack $itk_component(time0)         -side top -expand 1 -fill both

        itk_component add snapshot0 {
            SnapshotWidthGridView $snapSite0.s0 \
            -packOption "-side top -anchor ne" \
            -activeClientOnly 1 \
            -onAreaDefining "$this handleAreaDefining 0"
        } {
        }

        itk_component add phi1_frame {
            frame $snapSite1.phi1F
        } {
        }

        itk_component add phi1 {
            label $snapSite1.phi1F.phil \
            -anchor s \
            -text "Phi=0"
        } {
        }

        itk_component add time1 {
            label $snapSite1.phi1F.time1 \
            -text ""
        } {
        }

        itk_component add movePhi1 {
            DCS::Button $snapSite1.phi1F.move1 \
            -text "Move to" \
            -command "$this movePhi 1"
        } {
        }
        itk_component add moveArea1 {
            DCS::AreaMoveArrows $snapSite1.phi1F.ma1 \
	        -leftCommand  "$this moveScanArea 1 left" \
            -rightCommand "$this moveScanArea 1 right" \
            -upCommand    "$this moveScanArea 1 up" \
            -downCommand  "$this moveScanArea 1 down" \
        } {
        }
        itk_component add insideGrid1 {
            DCS::Checkbutton $snapSite1.phi1F.ingrid1 \
            -text "Show Grid" \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -command "$this showInsideGrid 1 %s"
        } {
        }
        $itk_component(insideGrid1) setValue 1

        pack $itk_component(movePhi1) -side left
        pack $itk_component(phi1)     -side left
        pack $itk_component(moveArea1)     -side right
        pack $itk_component(insideGrid1)   -side right
        pack $itk_component(time1)         -side top -expand 1 -fill both

        itk_component add snapshot1 {
            SnapshotWidthGridView $snapSite1.s1 \
            -packOption "-side top -anchor ne" \
            -activeClientOnly 1 \
            -onAreaDefining "$this handleAreaDefining 1"
        } {
        }

        pack $itk_component(phi0_frame) -side top -fill x
        pack $itk_component(snapshot0)  -side top -expand 1 -fill both

        pack $itk_component(phi1_frame) -side top -fill x
        pack $itk_component(snapshot1)  -side top -expand 1 -fill both

        grid $itk_component(s_frame0) -row 0 -column 0 -sticky news
        grid $itk_component(s_frame1) -row 1 -column 0 -sticky news
        grid rowconfigure $snapshotSite 0 -weight 10
        grid rowconfigure $snapshotSite 1 -weight 10
        grid columnconfigure $snapshotSite 0 -weight 10

        itk_component add control_frame {
            frame $gridSite.ff
        } {
        }

        set controlSite $itk_component(control_frame)
        itk_component add bConfig {
            button $controlSite.setup \
            -text "Setup" \
            -command "$this flipUserSetup"
        } {
        }

        itk_component add bStart {
            DCS::Button $controlSite.start \
            -width $BUTTON_WIDTH \
            -text "Start" \
            -command "$this startScan3D"
        } {
        }

        itk_component add bStop {
            DCS::Button $controlSite.stop \
            -systemIdleOnly 0 \
            -width $BUTTON_WIDTH \
            -text "Stop" \
            -command "$this stopScan3D"
        } {
        }

        itk_component add matrix {
            iwidgets::tabnotebook $gridSite.matrix \
            -tabpos n \
            -raiseselect 1 \
            -equaltabs 0 \
        } {
        }

        set i 0
        foreach l $m_mapTab {
            $itk_component(matrix) add -label $l -command "$this showTab $i"
            incr i
        }
        set matrixSite [$itk_component(matrix) childsite 0]
        #pack $matrixSite
        $itk_component(matrix) select 0
        $itk_component(matrix) configure -auto off

        itk_component add rasters {
            Scan3DMatrixView $matrixSite.rasters \
            -beamWidthWidget ::device::$gMotorBeamWidth \
            -beamHeightWidget ::device::$gMotorBeamHeight \
            -diffractionImageViewer $itk_component(diff_viewer) \
            -hintGenerator "$this hintConvert" \
            -valueConverter $this \
            -imageSources \
            [list $itk_component(snapshot0) $itk_component(snapshot1)] \
        } {
        }
        pack $itk_component(rasters) -expand 1 -fill both

        $itk_component(rasters) register $this state handleRasterStateChange

        $itk_component(movePhi0) addInput \
        "$m_objInfo first_area_defined 1 {define raster first}"
        $itk_component(movePhi1) addInput \
        "$m_objInfo second_area_defined 1 {define raster first}"
        $itk_component(moveArea0) addInput \
        "$m_objInfo first_area_defined 1 {define raster first}"
        $itk_component(moveArea1) addInput \
        "$m_objInfo second_area_defined 1 {define raster first}"
        $itk_component(insideGrid0) addInput \
        "$m_objInfo first_area_defined 1 {define raster first}"
        $itk_component(insideGrid1) addInput \
        "$m_objInfo second_area_defined 1 {define raster first}"

        $itk_component(bStart) addInput \
        "$m_objScan3DSetup status inactive {busy}"
        $itk_component(bStart) addInput \
        "$m_objManualRastering status inactive {busy}"
        $itk_component(bStart) addInput \
        "$m_objInfo first_area_defined 1 {define raster first}"
        $itk_component(bStart) addInput \
        "$m_objInfo second_area_defined 1 {define raster first}"
        $itk_component(bStart) addInput \
        "::$itk_component(rasters) uptodate 1 {previous rasters loaded}"

        $itk_component(bStop) addInput \
        "$m_objManualRastering status active {not running}"
        $itk_component(bStop) addInput \
        "::$itk_component(rasters) busy 0 {busy}"

        ######### Uncomment if do not want user to re-use snapshots of history
        #$itk_component(moveArea0) addInput \
        #"::$itk_component(rasters) uptodate 1 {previous rasters loaded}"
        #$itk_component(moveArea1) addInput \
        #"::$itk_component(rasters) uptodate 1 {previous rasters loaded}"
        #$itk_component(snapshot0) addInput \
        #"::$itk_component(rasters) uptodate 1 {previous rasters loaded}"
        #$itk_component(snapshot1) addInput \
        #"::$itk_component(rasters) uptodate 1 {previous rasters loaded}"

        pack $itk_component(bConfig) -side left
        pack $itk_component(bStart) -side left
        pack $itk_component(bStop) -side left

        pack $itk_component(control_frame) -side top -fill x
        pack $itk_component(matrix) -expand 1 -fill both

        pack $itk_component(pwv) -side top -expand 1 -fill both

        pack $itk_component(pw) -side top -expand 1 -fill both

        eval itk_initialize $args

        $m_objSampleCameraConstant \
        register $this contents handleBeamCenterChange

        $m_objInlineCameraConstant \
        register $this contents handleInlineBeamCenterChange

        $m_objInfo register $this contents handleInfoChange

        $m_objUserSetupNormal register $this contents handleUserSetupNormalChange
        $m_objUserSetupMicro  register $this contents handleUserSetupMicroChange

        $m_objManualRastering registerForAllEvents $this handleOperationEvent

        set m_inConstructor 0

        set s_lastObject $this



        puts "RasterTab object: $this"
        global gRasterTab
        set gRasterTab $this
    }

    destructor {
        $m_objManualRastering unregisterForAllEvents $this handleOperationEvent
        $m_objUserSetupNormal unregister $this contents handleUserSetupNormalChange
        $m_objUserSetupMicro  unregister $this contents handleUserSetupMicroChange

        $m_objInfo unregister $this contents handleInfoChange

        $m_objInlineCameraConstant \
        unregister $this contents handleInlineBeamCenterChange

        $m_objSampleCameraConstant \
        unregister $this contents handleBeamCenterChange
    }
}
body RasteringViewTab::handleBeamCenterChange { - targetReady_ - contents_ - } {
    global gInlineCameraExists

    if {!$targetReady_} {
        set m_centerX -999
        set m_centerY -999
    } else {
        set m_centerX [lindex $contents_ $m_indexX]
        set m_centerY [lindex $contents_ $m_indexY]
    }

    set currentInlineMode [lindex $m_ctsInfo 14]
    if {!$gInlineCameraExists || $currentInlineMode != "1"} {
        $itk_component(snapshot0) configure -beamCenter [list $m_centerX $m_centerY]
        $itk_component(snapshot1) configure -beamCenter [list $m_centerX $m_centerY]
    }
}

body RasteringViewTab::handleOperationEvent { message_ } {
    ### here we are only interested in the operation started message.
    ### it will turn off the pause on diffImageViewer
    foreach {eventType opName opId arg1 arg2 arg3} $message_ break

    #### all through this operation but we only care the rastering, not setup.
    switch -exact -- $eventType {
		stog_start_operation {
            $itk_component(diff_viewer) unPause
        }
    }
}
body RasteringViewTab::handleInlineBeamCenterChange { - targetReady_ - contents_ - } {
    global gInlineCameraExists

    if {!$targetReady_} {
        set m_inlineCenterX -999
        set m_inlineCenterY -999
    } else {
        set m_inlineCenterX [lindex $contents_ $m_indexX]
        set m_inlineCenterY [lindex $contents_ $m_indexY]
    }

    set currentInlineMode [lindex $m_ctsInfo 14]
    if {$gInlineCameraExists && $currentInlineMode == "1"} {
        $itk_component(snapshot0) configure -beamCenter [list $m_inlineCenterX $m_inlineCenterY]
        $itk_component(snapshot1) configure -beamCenter [list $m_inlineCenterX $m_inlineCenterY]
    }
}
body RasteringViewTab::handleUserSetupNormalChange { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    set m_ctsUserSetupNormal $contents_
    updateExposureTime
}
body RasteringViewTab::handleUserSetupMicroChange { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    set m_ctsUserSetupMicro $contents_
    updateExposureTime
}


body RasteringViewTab::handleInfoChange { - targetReady_ - contents_ - } {
    global gInlineCameraExists

    if {!$targetReady_} {
        return
    }
    set m_ctsInfo $contents_
    updateInfo
}
body RasteringViewTab::updateInfo { {from_file {}} } {
    set w0 999
    set w1 999
    set h0 999
    set d1 999
    set woff0 0
    set woff1 0
    set hoff0 0
    set doff1 0

    set match     [lindex $m_ctsInfo 0]
    set orig      [lindex $m_ctsInfo 1]
    set info0     [lindex $m_ctsInfo 2]
    set info1     [lindex $m_ctsInfo 3]
    set wu        [lindex $m_ctsInfo 5]
    set hu        [lindex $m_ctsInfo 6]
    set du        [lindex $m_ctsInfo 7]
    set nw        [lindex $m_ctsInfo 8]
    set nh        [lindex $m_ctsInfo 9]
    set nd        [lindex $m_ctsInfo 10]
    set view_index [lindex $m_ctsInfo 11]
    set defined0  [lindex $m_ctsInfo 12]
    set defined1  [lindex $m_ctsInfo 13]
    set inlineMode [lindex $m_ctsInfo 14]
    set hoffu0      [lindex $m_ctsInfo 15]
    set voffu0      [lindex $m_ctsInfo 16]
    set hoffu1      [lindex $m_ctsInfo 17]
    set voffu1      [lindex $m_ctsInfo 18]
    set soffh0      [lindex $m_ctsInfo 19]
    set soffv0      [lindex $m_ctsInfo 20]
    set soffh1      [lindex $m_ctsInfo 21]
    set soffv1      [lindex $m_ctsInfo 22]

    if {$inlineMode != "1"} {
        set inlineMode 0
    }

    set snapshot0 [lindex $info0 0]
    set snapshot1 [lindex $info1 0]

    if {$from_file != ""} {
        set dir [file dirname $from_file]
        set ss0 [file tail $snapshot0]
        set ss1 [file tail $snapshot1]

        set snapshot0 [file join $dir $ss0]
        set snapshot1 [file join $dir $ss1]
    }

    set orig0     [lindex $info0 1]
    set orig1     [lindex $info1 1]

    set a0        [lindex $orig0 3]
    set a1        [lindex $orig1 3]
    set cur_omega [lindex [::device::gonio_omega getScaledPosition] 0]

    if {[string is double -strict $a0] \
    && [string is double -strict $a1] \
    && $a0 != -999 \
    && $a1 != -999} {
        if {$inlineMode} {
            set phi0 [expr $a0 - $cur_omega]
            set phi1 [expr $a1 - $cur_omega]
        } else {
            set phi0 [expr $a0 + 90 - $cur_omega]
            set phi1 [expr $a1 + 90 - $cur_omega]
        }
        set phi0 [format "%.1f" $phi0]
        set phi1 [format "%.1f" $phi1]

    } else {
        set phi0 ""
        set phi1 ""
    }
    $itk_component(phi0) configure \
    -text "Phi=$phi0"
    $itk_component(phi1) configure \
    -text "Phi=$phi1"

    updateExposureTime

    set hMM0  [lindex $orig0 4]
    set wMM0  [lindex $orig0 5]
    set hMM1  [lindex $orig1 4]
    set wMM1  [lindex $orig1 5]
    if {[string is double -strict $wu] \
    && [string is double -strict $hu] \
    && [string is double -strict $wMM0] \
    && [string is double -strict $hMM0] \
    && $wMM0 != 0  \
    && $hMM0 != 0 \
    } {
        ## mm to micron
        set wU   [expr $wMM0 * 1000.0]
        set hU   [expr $hMM0 * 1000.0]

        set w0    [expr $wu     / $wU]
        set woff0 [expr $soffh0 / $wU]

        set h0    [expr $hu     / $hU]
        set hoff0 [expr $soffv0 / $hU]
    }

    if {[string is double -strict $wu] \
    && [string is double -strict $du] \
    && [string is double -strict $wMM1] \
    && [string is double -strict $hMM1] \
    && $wMM1 != 0  \
    && $hMM1 != 0 \
    } {
        ## mm to micron
        set wU   [expr $wMM1 * 1000.0]
        set dU   [expr $hMM1 * 1000.0]

        set w1    [expr $wu     / $wU]
        set woff1 [expr $soffh1 / $wU]

        set d1    [expr $du     / $dU]
        set doff1 [expr $soffv1 / $dU]
    }
    $itk_component(snapshot0) configure \
    -snapshot $snapshot0 \

    $itk_component(snapshot1) configure \
    -snapshot $snapshot1 \

    $itk_component(snapshot0) configure \
    -gridInfo [list $woff0 $hoff0 $w0 $h0 $nw $nh]

    $itk_component(snapshot1) configure \
    -gridInfo [list $woff1 $doff1 $w1 $d1 $nw $nd]

    if {$defined0 == "1" || $defined1 == "1"} {
        pack $itk_component(control_frame) -side top
        pack $itk_component(matrix) -expand 1 -fill both
    } else {
        pack forget $itk_component(control_frame) $itk_component(matrix) 
    }

    ###########################################################
    ###########################################################
    ###### We did not draw grid on the video for now.
    ###### If want to enable it, please also enable the match check
    ###### in the dcss code (trigger).
    return
    ###########################################################
    ###########################################################


    if {$match == "" || $match == "0"} {
        #$m_sampleVideo configure \
        #-mode cross_only
        #if {$gInlineCameraExists} {
        #    $m_inlineVideo configure \
        #    -mode cross_only
        #}
        return
    }

    switch -exact -- $match {
        1 {
            if {$inlineMode} {
                set inline_grid "$hoffu0 $voffu0 $wu $hu $nw $nh $COLOR_GRID"
                set sample_grid "$hoffu1 $voffu1 $wu $du $nw $nd $COLOR_GRID"
            } else {
                set sample_grid "$hoffu0 $voffu0 $wu $hu $nw $nh $COLOR_GRID"
                set inline_grid "$hoffu1 $voffu1 $wu $du $nw $nd $COLOR_GRID"
            }
        }
        2 {
            if {$inlineMode} {
                set inline_grid "$hoffu1 $voffu1 $wu $du $nw $nd $COLOR_GRID"
                set sample_grid "$hoffu0 $voffu0 $wu $hu $nw $nh $COLOR_GRID"
            } else {
                set sample_grid "$hoffu1 $voffu1 $wu $du $nw $nd $COLOR_GRID"
                set inline_grid "$hoffu0 $voffu0 $wu $hu $nw $nh $COLOR_GRID"
            }
        }
    }
    eval $m_sampleVideo setGrid $sample_grid
    if {$gInlineCameraExists} {
        eval $m_inlineVideo setGrid $inline_grid
    }

}
body RasteringViewTab::handleSubmit { name index } {
    if {$m_inConstructor} {
        return
    }

    set clientState [$itk_option(-controlSystem) cget -clientState]
    if {$clientState != "active"} {
        puts "not active"
        return
    }   

    set v [lindex [$itk_component($name) get] 0]

    set oldContents [$m_objInfo getContents]
    set old_v [lindex $oldContents $index]
    if {$old_v == $v} {
        return
    }
    puts "in handleSubmit name=$name index=$index v=$v old=$old_v"
    $m_objScan3DSetup startOperation set $index $v
}
body RasteringViewTab::updateExposureTime { } {
    set collimator [lindex $m_ctsInfo 4]

    if {$collimator == "1"} {
        set ss $m_ctsUserSetupMicro
    } else {
        set ss $m_ctsUserSetupNormal
    }
    set time0 [lindex $ss 4]
    set time1 [lindex $ss 5]

    set display0 ""
    set display1 ""

    if {[string is double -strict $time0]} {
        set display0 "Time=[format {%.4f} $time0] s"
    }
    if {[string is double -strict $time1]} {
        set display1 "Time=[format {%.4f} $time1] s"
    }

    $itk_component(time0) configure \
    -text $display0

    $itk_component(time1) configure \
    -text $display1
}
body RasteringViewTab::hintConvert { args } {
    switch -exact -- $args {
        N {
            return "Skip"
        }
        S {
            return ""
        }
        X {
            return "Exposing"
        }
        D {
            return "Analyzing"
        }
        {} {
            return ""
        }
    }
    if {[llength $args] == 1} {
        return $args
    }
    set result ""
    foreach l $m_mapTab subField $m_mapSubField fmt $m_mapFormat {
        if {$fmt == "skip"} {
            continue
        }
        set v   [lindex $args $subField]
        set vv  [format $fmt $v]
        set vvv "${l} = $vv; "
        append result $vvv
    }
    return $result
}
body RasteringViewTab::cvtNoChange { vList offset } {
    set result ""
    foreach info $vList {
        if {[llength $info] > $offset} {
            lappend result [lindex $info $offset]
        } else {
            lappend result [lindex $info 0]
        }
    }
    return $result
}
body RasteringViewTab::cvtChangeSign { vList offset } {
    set result ""
    foreach info $vList {
        if {[llength $info] > $offset} {
            set v [lindex $info $offset]
        } else {
            set v [lindex $info 0]
        }
        if {[string is double -strict $v]} {
            set v [expr -1 * $v]
        }
        lappend result $v
    }
    return $result
}
body RasteringViewTab::cvtChangeSignLimits { vList offset min max } {
    set result ""
    foreach info $vList {
        if {[llength $info] > $offset} {
            set v [lindex $info $offset]
        } else {
            set v [lindex $info 0]
        }
        if {[string is double -strict $v]} {
            if {$v >= $min && $v <= $max} {
                set v [expr -1 * $v]
            } else {
                set v L
            }
        }
        lappend result $v
    }
    return $result
}
body RasteringViewTab::toMatrix { vList offset } {
    switch -exact -- $offset {
        0 {
            ## spots
            return [cvtNoChange $vList $offset]
        }
        1 {
            ## overload spots
            return [cvtNoChange $vList $offset]
        }
        2 {
            ## score
            return [cvtNoChange $vList $offset]
        }
        3 {
            ## resolution
            return [cvtChangeSignLimits $vList $offset 1.0 30.0]
        }
        4 {
            ## ice rings
            return [cvtChangeSign $vList $offset]
        }
        5 {
            ## spot shape
            return [cvtChangeSignLimits $vList $offset 1.0 4.9]
        }
        6 {
            ## diffraction strength
        }
        7 {
            ## integrated intensity
        }
        default {
            return [cvtNoChange $vList $offset]
        }
    }
}
body RasteringViewTab::toDisplay { vList offset } {
    switch -exact -- $offset {
        0 {
            ## spots
            return [cvtDisplayFormat $vList $offset %.0f]
        }
        1 {
            ## overload spots
            return [cvtDisplayFormat $vList $offset %.0f]
        }
        2 {
            ## score
            return [cvtDisplayFormat $vList $offset %.1f]
        }
        3 {
            ## resolution
            return [cvtDisplayFormat $vList $offset %.1f]
        }
        4 {
            ## ice rings
            return [cvtDisplayFormat $vList $offset %.0f]
        }
        5 {
            ## spot shape
            return [cvtDisplayFormat $vList $offset %.1f]
        }
        6 {
            ## diffraction strength
        }
        7 {
            ## integrated intensity
        }
        default {
            return [cvtDisplayFormat $vList $offset %.0f]
        }
    }
}
body RasteringViewTab::cvtDisplayFormat { vList offset fmt } {
    set result ""
    foreach info $vList {
        if {[llength $info] > $offset} {
            set v [lindex $info $offset]
        } else {
            set v [lindex $info 0]
        }
        if {[string is double -strict $v]} {
            set v [format $fmt $v]
        }
        lappend result $v
    }
    return $result
}
body RasteringViewTab::loadFile { path } {
    if {[catch {open $path r} handle]} {
        log_error failed to open file $path: $handle
        return
    }
    ## skip raster setup and info
    gets $handle
    gets $handle
    gets $handle
    gets $handle
    gets $handle m_ctsInfo
    gets $handle user_setup
    close $handle

    set collimator [lindex $m_ctsInfo 4]

    if {$collimator == "1"} {
        set m_ctsUserSetupMicro $user_setup
    } else {
        set m_ctsUserSetupNormal $user_setup
    }

    updateInfo $path
    $itk_component(rasters) initializeFromFile $path

    $itk_component(rasters) updateRegisteredComponents uptodate
}
class RasteringConfigView {
    inherit ::itk::Widget

    constructor { args } {
        itk_component add left {
            iwidgets::Labeledframe $itk_interior.left \
            -labelfont "helvetica -24 bold" \
            -labelpos n \
            -labeltext "Normal Raster"
        }
        set leftSite [$itk_component(left) childsite]

        itk_component add right {
            iwidgets::Labeledframe $itk_interior.right \
            -labelfont "helvetica -24 bold" \
            -labelpos n \
            -labeltext "Micro Raster"
        }
        set rightSite [$itk_component(right) childsite]

        itk_component add normal {
            DCS::RasteringNormalConfigView $leftSite.normal
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        pack $itk_component(normal) -expand 1 -fill both

        set deviceFactory [DCS::DeviceFactory::getObject]
        if {[$deviceFactory operationExists collimatorMove]} {
            itk_component add micro {
                DCS::RasteringMicroConfigView $rightSite.micro
            } {
                keep -activeClientOnly -systemIdleOnly
            }
        } else {
            itk_component add micro {
                label $rightSite.micro \
                -text "no collimator or rastering_micro_constant not exists"
            } {
            }
        }
        pack $itk_component(micro) -expand 1 -fill both

        grid $itk_component(left) $itk_component(right) -sticky news
        grid columnconfigure $itk_interior 0 -weight 1
        grid columnconfigure $itk_interior 1 -weight 1
        grid rowconfigure $itk_interior 0 -weight 1
    }
}

class Scan3DUserSetup {
    inherit ::itk::Widget

    public method handleNormalUserStringUpdate
    public method handleNormalSystemStringUpdate
    public method handleMicroUserStringUpdate
    public method handleMicroSystemStringUpdate
    public method handleInfoUpdate

    public method setToDefault { } {
        $m_objScan3DUserSetup startOperation user_setup_default
    }
    public method updateFromCurrent { } {
        $m_objScan3DUserSetup startOperation user_setup_update
    }
    public method setField { name value } {
        $m_objScan3DUserSetup startOperation user_setup_set $name $value
    }

    private method updateDisplay

    private variable m_deviceFactory ""
    private variable m_objUserMicro ""
    private variable m_objUserNormal ""
    private variable m_objSystemMicro ""
    private variable m_objSystemNormal ""
    private variable m_objInfo ""

    private variable m_ctsUserMicro ""
    private variable m_ctsUserNormal ""
    private variable m_ctsSystemMicro ""
    private variable m_ctsSystemNormal ""
    private variable m_useCollimator ""

    private variable m_objScan3DSetup ""
    private variable m_objScan3DUserSetup ""
    ### change through operation to check the limits

    private variable m_microIndex
    private variable m_normalIndex

    private common BLUE #a0a0c0

    private method generateIndex { } {
        set MICRO_NAMELIST [::config getStr "rastering.microConstantNameList"]
        set NORMAL_NAMELIST [::config getStr "rastering.normalConstantNameList"]

        foreach name {stopMove distMove} {
            set m_microIndex($name)  [lsearch -exact $MICRO_NAMELIST $name]
            set m_normalIndex($name) [lsearch -exact $NORMAL_NAMELIST $name]
        }
    }

    constructor { args } {
        generateIndex

        global gMotorDistance
        global gMotorBeamStop
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objUserMicro    [$m_deviceFactory createString raster_user_setup_micro]
        set m_objUserNormal   [$m_deviceFactory createString raster_user_setup_normal]
        set m_objSystemMicro  [$m_deviceFactory createString rastering_micro_constant]
        set m_objSystemNormal [$m_deviceFactory createString rastering_normal_constant]
        set m_objInfo         [$m_deviceFactory createString scan3DSetup_info]

        set m_objScan3DSetup     [$m_deviceFactory createOperation scan3DSetup]
        set m_objScan3DUserSetup [$m_deviceFactory createOperation scan3DUserSetup]

        set ring $itk_interior
        itk_component add buttonsFrame {
            frame $ring.bf 
        } {}

        itk_component add defaultButton {
            DCS::Button $itk_component(buttonsFrame).def -text "Default" \
                 -width 5 -pady 0 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this setToDefault" 
        } {}
        
        itk_component add updateButton {
            DCS::Button $itk_component(buttonsFrame).u -text "Update" \
                 -width 5 -pady 0 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -command "$this updateFromCurrent" 
        } {}
        pack $itk_component(defaultButton) $itk_component(updateButton) -side left
        
        itk_component add distance {
            DCS::MotorViewEntry $ring.distance \
                -checkLimits -1 \
                -menuChoiceDelta 50 \
                 -device ::device::$gMotorDistance \
                 -showPrompt 1 \
                 -leaveSubmit 1 \
                 -promptText "Distance: " \
                 -promptWidth 12 \
                 -entryWidth 10 -units "mm" -unitsList "mm" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -escapeToDefault 0 \
                 -shadowReference 0 \
                 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -autoConversion 1 \
                 -onSubmit "$this setField distance %s" \
        } {
            keep -background
        }
        
        itk_component add beamstop {
            DCS::MotorViewEntry $ring.beamstop \
                -checkLimits -1 \
                -menuChoiceDelta 5 \
                 -device ::device::$gMotorBeamStop \
                 -showPrompt 1 \
                 -leaveSubmit 1 \
                 -promptText "Beam Stop: " \
                 -promptWidth 12 \
                 -entryWidth 10 -units "mm" -unitsList "mm" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -escapeToDefault 0 \
                 -shadowReference 0 \
                 -activeClientOnly 1 \
                 -systemIdleOnly 0 \
                 -autoConversion 1 \
                 -onSubmit "$this setField beamstop %s" \
        } {
            keep -background
        }
        itk_component add delta {
            DCS::Entry $ring.delta -promptText "Delta: " \
                 -leaveSubmit 1 \
                 -promptWidth 12 \
                 -entryWidth 10     \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -decimalPlaces 2 \
                 -units "deg" \
                 -shadowReference 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -onSubmit "$this setField delta %s" \
        } {
            keep -background
        }
        itk_component add time {
            DCS::Entry $ring.time \
                 -leaveSubmit 1 \
                 -promptText "Time: " \
                 -promptWidth 12 \
                 -entryWidth 10     \
                 -units "s" \
                 -entryType positiveFloat \
                 -entryJustify right \
                 -decimalPlaces 4 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -onSubmit "$this setField time %s" \
        } {
            keep -background
        }

        itk_component add notice {
            label $ring.notice \
            -text "time status"
        } {
            keep -background
        }
        
        pack $itk_component(buttonsFrame) -side top -anchor w
        pack $itk_component(distance) -side top -anchor w
        pack $itk_component(beamstop) -side top -anchor w
        pack $itk_component(delta) -side top -anchor w
        pack $itk_component(time) -side top -anchor w
        #pack $itk_component(notice) -side top -anchor w

        foreach item {defaultButton updateButton distance beamstop delta time} {
            $itk_component($item) addInput "$m_objScan3DSetup status inactive {busy}"
        }

	    configure -background $BLUE
        eval itk_initialize $args

        $m_objUserMicro    register $this contents handleMicroUserStringUpdate
        $m_objUserNormal   register $this contents handleNormalUserStringUpdate
        $m_objSystemMicro  register $this contents handleMicroSystemStringUpdate
        $m_objSystemNormal register $this contents handleNormalSystemStringUpdate
        $m_objInfo         register $this contents handleInfoUpdate

    }
    destructor {
        $m_objUserMicro    unregister $this contents handleMicroUserStringUpdate
        $m_objUserNormal   unregister $this contents handleNormalUserStringUpdate
        $m_objSystemMicro  unregister $this contents handleMicroSystemStringUpdate
        $m_objSystemNormal unregister $this contents handleNormalSystemStringUpdate
        $m_objInfo         unregister $this contents handleInfoUpdate
    }
}
body Scan3DUserSetup::handleMicroUserStringUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    set m_ctsUserMicro $contents_
    updateDisplay
}
body Scan3DUserSetup::handleNormalUserStringUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    set m_ctsUserNormal $contents_
    updateDisplay
}
body Scan3DUserSetup::handleMicroSystemStringUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    set m_ctsSystemMicro $contents_
    updateDisplay
}
body Scan3DUserSetup::handleNormalSystemStringUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    puts "set system normal to $contents_"
    set m_ctsSystemNormal $contents_
    updateDisplay
}
body Scan3DUserSetup::handleInfoUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    set m_useCollimator [lindex $contents_ 4]
    updateDisplay
}
body Scan3DUserSetup::updateDisplay { } {


    global gMotorDistance
    global gMotorBeamStop
    switch -exact -- $m_useCollimator {
        0  {
            if {[llength $m_ctsUserNormal] < 7} {
                return
            }
            if {[llength $m_ctsSystemNormal] < $m_normalIndex(distMove)} {
                return
            }
        }
        1 {
            if {[llength $m_ctsUserMicro] < 7} {
                return
            }
            if {[llength $m_ctsSystemMicro] < $m_microIndex(distMove)} {
                return
            }
        }
        default {
            return
        }
    }

    if {$m_useCollimator} {
        foreach {dist stop delta time} $m_ctsUserMicro break
        set isDefault [lindex $m_ctsUserMicro 6]
        set stopMove [lindex $m_ctsSystemMicro $m_microIndex(stopMove)]
        set distMove [lindex $m_ctsSystemMicro $m_microIndex(distMove)]
    } else {
        foreach {dist stop delta time} $m_ctsUserNormal break
        set isDefault [lindex $m_ctsUserNormal 6]
        set stopMove [lindex $m_ctsSystemNormal $m_normalIndex(stopMove)]
        set distMove [lindex $m_ctsSystemNormal $m_normalIndex(distMove)]
    }

    puts "move: stop=$stopMove dist=$distMove"
    if {$stopMove == "0"} {
        set stop [::device::$gMotorBeamStop cget -scaledPosition]
    }
    if {$distMove == "0"} {
        set dist [::device::$gMotorDistance cget -scaledPosition]
    }

    $itk_component(time)  setValue $time 1
    $itk_component(delta) setValue $delta 1

    $itk_component(distance) setValue $dist 1
    $itk_component(beamstop) setValue $stop 1

    if {$distMove == "0"} {
        $itk_component(distance) configure \
        -state labeled
    } else {
        $itk_component(distance) configure \
        -state normal
    }
    if {$stopMove == "0"} {
        $itk_component(beamstop) configure \
        -state labeled
    } else {
        $itk_component(beamstop) configure \
        -state normal
    }

    if {$isDefault == "1"} {
        $itk_component(notice) configure \
        -text "raster will adjust exposure time"
    } else {
        $itk_component(notice) configure \
        -text "raster will NOT adjust exposure time"
    }
}
