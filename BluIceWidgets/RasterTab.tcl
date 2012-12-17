package provide RasterTab 1.0

package require Iwidgets
package require BWidget

package require DCSComponent
package require ComponentGateExtension
package require DCSDeviceFactory
package require DCSDeviceView
package require DCSUtil
package require DCSContour
package require Raster4BluIce
#package require BLUICESamplePosition
package require BLUICEVideoNotebook

global gRaster
::DCS::Raster4BluIce ::gRaster

global gRasterTab
set gRasterTab ""

class RasterSnapshotView {
     inherit ::DCS::ComponentGateExtension

    itk_option define -snapshot   snapshot   Snapshot   ""        { update }

    itk_option define -gridInfo   gridInfo   GridInfo   {0.5 0.5 0.2 0.2 1 1} {
        #puts "$this gridInfo: $itk_option(-gridInfo)"
        update
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
        -mode draw_none \
        -grid_standalone 1 \
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
body RasterSnapshotView::update { } {
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
body RasterSnapshotView::updateSnapshot { } {
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
body RasterSnapshotView::generateGridImage { } {
    set m_flipHorz 0
    set m_flipVert 0
    if {$m_rawImage == ""} {
        $m_gridImage blank
        return
    }
    foreach {x y w h c r} $itk_option(-gridInfo) break
    if {$x <= 0 || $y <= 0 || $w == 0 || $h == 0} {
        $m_gridImage blank
        return
    }
    set x1 [expr $x - 0.5 * $w]
    set y1 [expr $y - 0.5 * $h]
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
body RasterSnapshotView::redrawImage { } {
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
body RasterSnapshotView::redrawOverlay { } {
    if {!$m_drawImageOK} {
        puts "skip overlay snapshot display not ready"
        $m_overlay configure -mode draw_none
        return
    }

    foreach {x y w h c r} $itk_option(-gridInfo) break
    if {$x <= 0 || $y <= 0 || $w == 0 || $h == 0} {
        puts "skip overlay numbers not ready $x $y $w $h"
        $m_overlay configure -mode draw_none
        return
    }
    
    $m_overlay configure \
    -mode grid_only

    set blockOffH   [expr $m_imageWidth  * $x]
    set blockOffV   [expr $m_imageHeight * $y]
    set blockWidth  [expr $m_imageWidth  * $w]
    set blockHeight [expr $m_imageHeight * $h]
    $m_overlay setGrid $blockOffH $blockOffV $blockWidth $blockHeight $c $r $COLOR_GRID
}
body RasterSnapshotView::handleNewOutput {} {
    if { $_gateOutput == 0 } {
        $itk_component(drawArea) config -cursor watch
#"@stop.xbm black"
    } else {
      set cursor [. cget -cursor]
        $itk_component(drawArea) config -cursor $cursor 
    }
    updateBubble
}

class RasterMatrixView {
    inherit ::itk::Widget ::DCS::Component

    itk_option define -controlSystem controlsytem ControlSystem "::dcss"

    ### to display diffraction image upon click on node
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

    public method handleImageUpdate0
    public method handleImageUpdate1

    ### hook to Raster4BluIce
    public method handleAllNew
    public method handleSetup0
    public method handleSetup1
    public method handleInfo0
    public method handleInfo1
    public method handleSingleViewMode { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_singleView  $contents_
        set contents [::gRaster getAll]
        handleAllNew dummy 1 dummy $contents dummy
    }

    public method handleMotorUpdate
    public method handleMarkerMovement
    private method updateCurrentPosition

    public method showDiffractionFile { index row column }

    public method handleResize { winID w h }

    public method moveToMark { area_index v h } {
        set rNum [::gRaster getRasterNumber]
        $m_objRasterRunsConfig startOperation \
        move_view_to_beam $rNum $area_index $v $h
    }

    public method handleMarkMovement0
    public method handleMarkMovement1

    public method handleSubAreaPress { x y } {
        $itk_component(s_canvas) delete -tag sub_area 
        set m_checkMotionAndRelease 0
        if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
            return
        }
        global gInlineCameraExists
        if {!$gInlineCameraExists} {
            set m_rightClick 0
            $itk_component(area0) click $x $y
            $itk_component(area1) click $x $y
            return
        }
        if {[::gRaster isInline]} {
            puts "already on micro beam"
            set m_rightClick 0
            $itk_component(area0) click $x $y
            $itk_component(area1) click $x $y
            return
        }
        set rState [lindex $m_info0 0]
        set rState [lindex $rState end]
        switch -exact -- $rState {
            paused -
            skipped -
            stopped -
            failed -
            done -
            aborted -
            {} {
                ## allow subArea
            }
            default {
                puts "raster not ready"
                set m_rightClick 0
                $itk_component(area0) click $x $y
                $itk_component(area1) click $x $y
                return
            }
        }
        set x [$itk_component(s_canvas) canvasx $x]
        set y [$itk_component(s_canvas) canvasy $y]

        set m_subAreaX0 $x
        set m_subAreaY0 $y

        if {[$itk_component(area0) getRowCol $x $y] != ""} {
            set m_subAreaViewIndex 0
            set m_checkMotionAndRelease 1
        } elseif {[$itk_component(area1) getRowCol $x $y] != ""} {
            set m_subAreaViewIndex 1
            set m_checkMotionAndRelease 1
        } else {
            set m_subAreaViewIndex -1
        }
    }
    public method handleSubAreaMotion { x y } {
        ### it may lost active while moving the mouse
        if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
            return
        }
        if {!$m_checkMotionAndRelease} {
            return
        }
        if {$m_subAreaViewIndex < 0} {
            return
        }
        set x [$itk_component(s_canvas) canvasx $x]
        set y [$itk_component(s_canvas) canvasy $y]

        if {[$itk_component(area$m_subAreaViewIndex) getRowCol $x $y] == ""} {
            return
        }
        set m_subAreaX1 $x
        set m_subAreaY1 $y

        $itk_component(s_canvas) delete -tag sub_area
        $itk_component(s_canvas) create rectangle \
        $m_subAreaX0 $m_subAreaY0 $m_subAreaX1 $m_subAreaY1 \
        -width 1 \
        -outline green \
        -dash . \
        -tags sub_area
    }
    public method handleSubAreaRelease { x y } {
        ### it may lost active while moving the mouse
        if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
            return
        }
        if {!$m_checkMotionAndRelease} {
            return
        }
        $itk_component(s_canvas) delete -tag sub_area 
        set x [$itk_component(s_canvas) canvasx $x]
        set y [$itk_component(s_canvas) canvasy $y]

        set m1 [$itk_component(area$m_subAreaViewIndex) getRowCol $x $y]
        if {$m1 == ""} {
            set m_rightClick 0
            $itk_component(area0) click $x $y
            $itk_component(area1) click $x $y
            return
        }

        set m_subAreaX1 $x
        set m_subAreaY1 $y

        if {$m_subAreaX0 == $m_subAreaX0 && $m_subAreaY0 == $m_subAreaY1} {
            puts "not move, just click"
            set m_rightClick 0
            $itk_component(area0) click $x $y
            $itk_component(area1) click $x $y
            return
        }
        
        set m0 [$itk_component(area$m_subAreaViewIndex) getRowCol \
        $m_subAreaX0 $m_subAreaY0]
        puts "subArea: $m_subAreaX0 $m_subAreaY0 $m_subAreaX1 $m_subAreaY1"
        puts "subArea: $m0 $m1"

        foreach {mv0 mh0} $m0 break
        foreach {mv1 mh1} $m1 break

        set centerV [expr ($mv0 + $mv1) / 2.0]
        set centerH [expr ($mh0 + $mh1) / 2.0]
        set projHeight  [expr abs($mv1 - $mv0) ]
        set projWidth   [expr abs($mh1 - $mh0) ]

        foreach {x y z phi} \
        [getMarkPosition $m_subAreaViewIndex $centerV $centerH] break

        set ss [set m_setup$m_subAreaViewIndex]
        foreach {width height} \
        [calculateBoxFromProjectionBox $ss $projWidth $projHeight] break

        ### to micron
        set width [expr 1000.0 * $width]
        set height [expr 1000.0 * $height]
        if {$width == 0} {
            set width 1.0
        }
        if {$height == 0} {
            set height 1.0
        }

        set parentNum [::gRaster getRasterNumber]
        puts "will call create new area $x $y $z $phi with w=$width h=$height"
        $m_objRasterRunsConfig startOperation \
        addNewRaster $parentNum 1 $x $y $z $phi $width $height

        set m_subAreaViewIndex -1
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
    public method handleRasterMsgUpdate { object_ ready_ - value_ - }

    public method updateTopo { } {
        foreach {edgeLevel beamWidth beamSpace contourLevels } \
        [getTopoInfo] break

        configure \
        -ridge [list $edgeLevel $beamWidth $beamSpace] \
        -contour $contourLevels
    }
    public method handleNormalConstantUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        puts "update normal constant"
        set m_ctsRasteringNormalConstant $contents_

        if {[::gRaster useCollimator]} {
            return
        }
        #puts "updateTopo in Normal update"
        updateTopo
    }
    public method handleMicroConstantUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_ctsRasteringMicroConstant $contents_
        puts "update micro constant"

        if {![::gRaster useCollimator]} {
            return
        }
        #puts "updateTopo in micro update"
        updateTopo
    }

    public method handleMotion { x y } {
        #puts "motion $x $y"
        set newNode ""
        if {$m_defined0 && $x > $m_pixHOff0 && $x < $m_xEnd0 && $y < $m_yEnd0} {
            set row [expr int($y / $m_pixNodeHeight)]
            set col [expr int(($x - $m_pixHOff0) / $m_pixNodeWidth0)]
            set index [expr $row * $m_numColumn0 + $col]

            ### display start from 1 not 0
            incr row
            incr col
            #puts "area 0: $row $col index=$index"
            set newNode [list 0 $index $row $col]
        } elseif {$m_defined1 && $x > $m_pixHOff1 && $x < $m_xEnd1 \
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
            #puts "calling updateHint in motion: $m_showingNode"
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
    private method initializeFromFile { path_ }

    private method updateHint { } {
        $itk_component(s_canvas) delete info_balloon

        if {$m_showingNode != ""} {
            set hint "Raster [lrange $m_showingNode 2 3]"
            set cts [generateHint $m_showingNode]
            if {$cts != ""} {
                append hint ": $cts"
            }
            #puts "new hint: $hint"
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
        if {$m_rasterRunning == "0"} {
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

    private method getMarkPosition { area_index v h } {
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

        set x [expr $x + $dx]
        set y [expr $y + $dy]
        set z [expr $z + $dz]

        return [list $x $y $z $phi]
    }

    private method getTopoInfo { } {
        if {[::gRaster useCollimator]} {
            set collimator_preset_index \
            [lindex $m_ctsRasteringMicroConstant $m_microNameIndex(collimator)]
            puts "getTopoInfo for collimator $collimator_preset_index"

            set beamSize \
            [::device::collimator_preset getCollimatorSize $collimator_preset_index]
            set beamWidth [lindex $beamSize 0]
            puts "beamSize: $beamSize width=$beamWidth"

            set contourLevels \
            [lindex $m_ctsRasteringMicroConstant $m_microNameIndex(contourLevels)]

            set ridgeLevel \
            [lindex $m_ctsRasteringMicroConstant $m_microNameIndex(ridgeLevel)]
            
            set beamSpace \
            [lindex $m_ctsRasteringMicroConstant $m_microNameIndex(beamSpace)]

            set result [list $ridgeLevel $beamWidth $beamSpace $contourLevels]
            puts "getTopoInfo result=$result"
            return $result
        } else {
            set beamWidth \
            [lindex $m_ctsRasteringNormalConstant $m_normalNameIndex(beamWd)]

            set contourLevels \
            [lindex $m_ctsRasteringNormalConstant $m_normalNameIndex(contourLevels)]

            set ridgeLevel \
            [lindex $m_ctsRasteringNormalConstant $m_normalNameIndex(ridgeLevel)]
            
            set beamSpace \
            [lindex $m_ctsRasteringNormalConstant $m_normalNameIndex(beamSpace)]

            set result [list $ridgeLevel $beamWidth $beamSpace $contourLevels]
            puts "getTopoInfo for normal beam: result=$result"
            return $result
        }
    }

    private variable m_defined0 0
    private variable m_defined1 0

    private variable m_currentRasterRun ""
    private variable m_ctsRasterRun ""
    private variable m_currentFile "not_exists"

    private variable m_rasterRunning 1
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
    private variable m_singleView 0

    private variable m_deviceFactory ""

    private variable m_objRasterMsg ""
    private variable m_objRasterRunsConfig ""

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

    private variable m_subAreaViewIndex  -1
    private variable m_subAreaX0      0
    private variable m_subAreaY0      0
    private variable m_subAreaX1      0
    private variable m_subAreaY1      0
    private variable m_checkMotionAndRelease 0

    private variable m_hintY 0

    ### we want to only display beam cross and box after all done
    private variable m_beamDisplaying 1

    ### need to pass constants: beamWidth, contourLevels, ridgeLevel, beamSpace to both matrixes
    private variable m_normalNameIndex
    private variable m_microNameIndex
    private variable m_objRasteringNormalConstant
    private variable m_objRasteringMicroConstant
    private variable m_ctsRasteringNormalConstant ""
    private variable m_ctsRasteringMicroConstant ""

    private common STATUS_FINISHED [list aborted stopped failed done]

    constructor { args } {
        ### busy means cannot skip/stop
        ::DCS::Component::constructor { \
        }
    } {
        set nameList \
        [::config getStr rastering.normalConstantNameList]
        set i 0
        foreach name $nameList {
            set m_normalNameIndex($name) $i
            incr i
        }
        set nameList \
        [::config getStr rastering.microConstantNameList]
        set i 0
        foreach name $nameList {
            set m_microNameIndex($name) $i
            incr i
        }

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objRasterMsg  [$m_deviceFactory createString raster_msg]

        set m_objRasterRunsConfig \
        [$m_deviceFactory createOperation rasterRunsConfig]

        set m_objSampleX   [$m_deviceFactory getObjectName sample_x]
        set m_objSampleY   [$m_deviceFactory getObjectName sample_y]
        set m_objSampleZ   [$m_deviceFactory getObjectName sample_z]
        set m_objOmega     [$m_deviceFactory getObjectName gonio_omega]

        set m_objRasteringNormalConstant \
        [$m_deviceFactory createString rastering_normal_constant]

        set m_objRasteringMicroConstant \
        [$m_deviceFactory createString rastering_micro_constant]

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
            keep -showRidge -ridge
        }
        itk_component add area1 {
            DCS::Floating2DScanView $graphSite.g1 $itk_component(s_canvas) \
        } {
            keep -subField -valueConverter -showContour -showValue -contour
            keep -showRidge -ridge
        }

        set m_winID $itk_interior.fG
        bind $m_winID <Configure> "$this handleResize %W %w %h"

        pack $itk_interior.fG -side left -expand 1 -fill both

        bind $itk_component(s_canvas) <ButtonPress-3> "$this handleRightClick %x %y"

        bind $itk_component(s_canvas) <ButtonPress-1> \
        "$this handleSubAreaPress %x %y"
        bind $itk_component(s_canvas) <B1-B1-Motion> \
        "$this handleSubAreaMotion %x %y"
        bind $itk_component(s_canvas) <ButtonRelease-1> \
        "$this handleSubAreaRelease %x %y"

        eval itk_initialize $args

        $m_objRasterMsg  register $this contents handleRasterMsgUpdate

        $m_objSampleX register $this scaledPosition handleMotorUpdate
        $m_objSampleY register $this scaledPosition handleMotorUpdate
        $m_objSampleZ register $this scaledPosition handleMotorUpdate

        $itk_component(area0) registerMarkMoveCallback \
        "$this handleMarkMovement0"

        $itk_component(area1) registerMarkMoveCallback \
        "$this handleMarkMovement1"

        bind $itk_component(s_canvas) <Leave> "$this killHint"
        bind $itk_component(s_canvas) <Motion> "$this handleMotion %x %y"

        ::gRaster register $this all_new      handleAllNew
        ::gRaster register $this view_0_setup handleSetup0
        ::gRaster register $this view_1_setup handleSetup1
        ::gRaster register $this view_0_data  handleInfo0
        ::gRaster register $this view_1_data  handleInfo1
        ::gRaster register $this single_view  handleSingleViewMode

        $m_objRasteringNormalConstant register $this contents handleNormalConstantUpdate
        $m_objRasteringMicroConstant  register $this contents handleMicroConstantUpdate
        set m_inConstructor 0

        announceExist
    }
    destructor {
        $m_objRasteringNormalConstant unregister $this contents handleNormalConstantUpdate
        $m_objRasteringMicroConstant  unregister $this contents handleMicroConstantUpdate
        ::gRaster unregister $this all_new      handleAllNew
        ::gRaster unregister $this view_0_setup handleSetup0
        ::gRaster unregister $this view_1_setup handleSetup1
        ::gRaster unregister $this view_0_data  handleInfo0
        ::gRaster unregister $this view_1_data  handleInfo1
        ::gRaster unregister $this single_view  handleSingleViewMode

        $m_objRasterMsg  unregister $this contents handleRasterMsgUpdate

        $m_objSampleX unregister $this scaledPosition handleMotorUpdate
        $m_objSampleY unregister $this scaledPosition handleMotorUpdate
        $m_objSampleZ unregister $this scaledPosition handleMotorUpdate
    }
}
body RasterMatrixView::showDiffractionFile { index row column } {
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
body RasterMatrixView::handleAllNew { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    foreach {scan_setup m_setup0 m_setup1 m_info0 m_info1 - -} $contents_ break

    set m_defined0 [lindex $scan_setup 12]
    set m_defined1 [lindex $scan_setup 13]
    if {$m_defined0 != "1"} {
        set m_defined0 0
    }
    if {$m_defined1 != "1"} {
        set m_defined1 0
    }

    if {$m_singleView && $m_defined0 && $m_defined1} {
        puts "not synced with single view force it"
        set m_defined1 0
    }

    set m_pattern0 [lindex $m_setup0 8]
    set m_ext0     [lindex $m_setup0 9]
    set m_pattern1 [lindex $m_setup1 8]
    set m_ext1     [lindex $m_setup1 9]

    foreach {m_startZ0 m_endZ0} [getZ $m_setup0] break
    foreach {m_startZ1 m_endZ1} [getZ $m_setup1] break

    if {$m_startZ0 != ""} {
        if {$m_startZ0 > $m_endZ0} {
            set m_ZColumnOpposite 1
        } else {
            set m_ZColumnOpposite 0
        }
    }
    if {$m_startZ1 != ""} {
        if {$m_startZ1 > $m_endZ1} {
            set m_ZColumnOpposite 1
        } else {
            set m_ZColumnOpposite 0
        }
    }

    $itk_component(area0) clear
    $itk_component(area1) clear
    set m_setup0OK 0
    set m_setup1OK 0
    if {$m_defined0 \
    && [llength $m_setup0] >= 8 \
    && [lindex $m_setup0 0] != -999} {
        set m_setup0OK [$itk_component(area0) setup $m_setup0]
    }
    if {$m_defined1 \
    && [llength $m_setup1] >= 8 \
    && [lindex $m_setup0 1] != -999} {
        set m_setup1OK [$itk_component(area1) setup $m_setup1]
    }

    if {$m_setup0OK} {
        $itk_component(area0) setValues $m_info0
    }
    if {$m_setup1OK} {
        $itk_component(area1) setValues $m_info1
    }
    
    updateNormalizedParameters
    repositionAreas
    killHint

    updateCurrentPosition
    puts "calling updateTopo in allNew"
    updateTopo
}
body RasterMatrixView::handleSetup0 { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    set m_setup0 $contents_
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
    if {$m_defined0} {
        set m_setup0OK [$itk_component(area0) setup $m_setup0]
    }
    
    updateNormalizedParameters
    repositionAreas
    killHint

    updateCurrentPosition
}
body RasterMatrixView::handleSetup1 { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    set m_setup1 $contents_
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

    if {$m_defined1} {
        set m_setup1OK [$itk_component(area1) setup $m_setup1]
    }
    
    updateNormalizedParameters
    repositionAreas
    killHint
    updateCurrentPosition
}
body RasterMatrixView::handleInfo0 { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    set m_info0 $contents_
    checkHintDisplay
    if {$m_setup0OK} {
        #puts "setValues 0: $m_info0"
        $itk_component(area0) setValues $m_info0
    }
}
body RasterMatrixView::handleInfo1 { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    set m_info1 $contents_
    checkHintDisplay
    if {$m_setup1OK} {
        #puts "setValues 1: $m_info1"
        $itk_component(area1) setValues $m_info1
    }
}
body RasterMatrixView::handleImageUpdate0 { - targetReady_ - contents_ - } {
    if {!$targetReady_} return

    set m_image0 $contents_
    repositionAreas
}
body RasterMatrixView::handleImageUpdate1 { - targetReady_ - contents_ - } {
    if {!$targetReady_} return

    set m_image1 $contents_
    repositionAreas
}
body RasterMatrixView::handleMotorUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    updateCurrentPosition
}
body RasterMatrixView::updateCurrentPosition { } {
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
body RasterMatrixView::handleRasterMsgUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    set m_rasterRunning [lindex $contents_ 0]
    checkBeamDisplay
}
body RasterMatrixView::handleResize { winID w h } {
    if {$m_winID != $winID} {
        return
    }

    puts "resize $w $h"
    set m_drawWidth  [expr $w - 4]
    set m_drawHeight [expr $h - 4]
    repositionAreas
    killHint
}
body RasterMatrixView::handleMarkMovement0 { v0 h0 } {
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
        paused -
        skipped -
        stopped -
        failed -
        done -
        aborted -
        {} {
            puts "moving area0 to $v0 $h0"
            moveToMark 0 $v0 $h0
        }
        default {
            ::gRaster flipNode 0 [expr $row - 1] [expr $col - 1]
        }
    }
}
body RasterMatrixView::handleMarkMovement1 { v1 h1 } {
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
        paused -
        skipped -
        stopped -
        failed -
        done -
        aborted -
        {} {
            puts "moving area1 to $v1 $h1"
            moveToMark 1 $v1 $h1
        }
        default {
            ::gRaster flipNode 1 [expr $row - 1] [expr $col - 1]
        }
    }
}
body RasterMatrixView::getZ { setup } {
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
body RasterMatrixView::initializeFromFile { path_ } {
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
body RasterMatrixView::updateNormalizedParameters { } {
    set zList ""

    if {$m_startZ0 != ""} {
        lappend zList $m_startZ0 $m_endZ0
    }
    if {$m_startZ1 != ""} {
        lappend zList $m_startZ1 $m_endZ1
    }

    if {[llength $zList] < 2} {
        return
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
body RasterMatrixView::repositionAreas { } {
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

    if {$m_defined0} {
        $itk_component(area0) reposition \
        0            $m_pixHOff0 $m_pixNodeHeight $m_pixNodeWidth0
    }
    if {$m_defined1} {
        $itk_component(area1) reposition \
        $m_pixVOff1 $m_pixHOff1 $m_pixNodeHeight $m_pixNodeWidth0
    }

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

        ### in all_new event, the images have not been updated yet.
        ### the images are update by another widget.
        if {$m_defined0} {
            if {[catch {imageResizeBilinear $m_img0 $img0 $gw0 $gh0} eM]} {
                puts "draw img0 failed: $eM"
            } else {
                puts "draw img0 OK"
            }
        } else {
            $m_img0 blank
            puts "clear img0"
        }

        if {$m_defined1} {
            if {[catch {imageResizeBilinear $m_img1 $img1 $gw1 $gh1} eM]} {
                puts "draw img1 failed: $eM"
            } else {
                puts "draw img1 OK"
            }
        } else {
            $m_img1 blank
            puts "clear img1"
        }

        $itk_component(s_canvas) coords snapshot0 $m_pixHOff0 0
        $itk_component(s_canvas) coords snapshot1 $m_pixHOff1 $m_pixVOff1
    }
}
body RasterMatrixView::generateHint { node } {
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
body RasterMatrixView::killHint { } {
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
    } elseif {$m_setup1OK && [llength $m_setup1] > 6} {
        foreach {- - - - cv ch} $m_setup1 break
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
class RasterUserSetupView {
    inherit ::itk::Widget

    public method handleRasterUpdate
    public method handleNormalSystemStringUpdate
    public method handleMicroSystemStringUpdate

    public method setToDefault { } {
        ::gRaster defaultUserSetup
    }
    public method updateFromCurrent { } {
        ::gRaster updateUserSetup
    }
    public method setField { name value } {
        ::gRaster setUserSetup $name $value
    }
    public method flipSingleView { } {
        ::gRaster flipSingleViewMode
    }

    private method updateDisplay

    private method addInput { } {
        foreach name $m_componentList {
            $itk_component($name) addInput \
            "::gRaster defined 1 {define raster first}"

            $itk_component($name) addInput \
            "::gRaster run_state inactive {reset raster first}"
        }
    }

    private variable m_deviceFactory ""
    private variable m_objSystemMicro ""
    private variable m_objSystemNormal ""

    private variable m_ctsUserSetup ""
    private variable m_ctsSystemMicro ""
    private variable m_ctsSystemNormal ""
    private variable m_useCollimator ""

    private variable m_microIndex
    private variable m_normalIndex

    private variable m_componentList ""

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
        set m_objSystemMicro  [$m_deviceFactory createString rastering_micro_constant]
        set m_objSystemNormal [$m_deviceFactory createString rastering_normal_constant]

        set ring $itk_interior
        itk_component add buttonsFrame {
            frame $ring.bf 
        } {}

        itk_component add defaultButton {
            DCS::Button $itk_component(buttonsFrame).def -text "Default" \
                 -width 5 -pady 0 \
                 -command "$this setToDefault" 
        } {}
        lappend m_componentList defaultButton
        
        itk_component add updateButton {
            DCS::Button $itk_component(buttonsFrame).u -text "Update" \
                 -width 5 -pady 0 \
                 -command "$this updateFromCurrent" 
        } {}
        lappend m_componentList updateButton
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
                 -autoConversion 1 \
                 -onSubmit "$this setField distance %s" \
        } {
            keep -background
        }
        lappend m_componentList distance
        
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
                 -autoConversion 1 \
                 -onSubmit "$this setField beamstop %s" \
        } {
            keep -background
        }
        lappend m_componentList beamstop

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
                 -onSubmit "$this setField delta %s" \
        } {
            keep -background
        }
        lappend m_componentList delta

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
                 -onSubmit "$this setField time %s" \
        } {
            keep -background
        }
        lappend m_componentList time

        itk_component add single {
            DCS::Checkbutton $ring.single \
            -text "Hide And Skip Second View" \
            -command "$this flipSingleView"
        } {
            keep -background
        }
        lappend m_componentList single

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
        pack $itk_component(single) -side top -anchor w
        #pack $itk_component(notice) -side top -anchor w

	    configure -background $BLUE

        addInput

        eval itk_initialize $args

        ::gRaster            register $this all_new    handleRasterUpdate
        ::gRaster            register $this user_setup handleRasterUpdate
        $m_objSystemMicro  register $this contents handleMicroSystemStringUpdate
        $m_objSystemNormal register $this contents handleNormalSystemStringUpdate
    }
    destructor {
        $m_objSystemMicro  unregister $this contents handleMicroSystemStringUpdate
        $m_objSystemNormal unregister $this contents handleNormalSystemStringUpdate
        ::gRaster            unregister $this all_new handleRasterUpdate
        ::gRaster            unregister $this user_setup handleRasterUpdate
    }
}
body RasterUserSetupView::handleRasterUpdate { - targetReady_ - - - } {
    if {!$targetReady_} {
        return
    }
    set m_ctsUserSetup  [::gRaster getUserSetup]
    set m_useCollimator [::gRaster useCollimator]
    updateDisplay
}
body RasterUserSetupView::handleMicroSystemStringUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    set m_ctsSystemMicro $contents_
    updateDisplay
}
body RasterUserSetupView::handleNormalSystemStringUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }
    puts "set system normal to $contents_"
    set m_ctsSystemNormal $contents_
    updateDisplay
}
body RasterUserSetupView::updateDisplay { } {
    global gMotorDistance
    global gMotorBeamStop

    if {[llength $m_ctsUserSetup] < 7} {
        return
    }
    switch -exact -- $m_useCollimator {
        0  {
            if {[llength $m_ctsSystemNormal] < $m_normalIndex(distMove)} {
                return
            }
        }
        1 {
            if {[llength $m_ctsSystemMicro] < $m_microIndex(distMove)} {
                return
            }
        }
        default {
            return
        }
    }

    foreach {dist stop delta time} $m_ctsUserSetup break
    set isDefault [lindex $m_ctsUserSetup 6]
    set isSingleView [lindex $m_ctsUserSetup 10]
    if {$isSingleView != "1"} {
        set isSingleView 0
    }

    if {$m_useCollimator} {
        set stopMove [lindex $m_ctsSystemMicro $m_microIndex(stopMove)]
        set distMove [lindex $m_ctsSystemMicro $m_microIndex(distMove)]
    } else {
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

    puts "single=$isSingleView"
    $itk_component(single)  setValue $isSingleView

    if {$isDefault == "1"} {
        $itk_component(notice) configure \
        -text "raster will adjust exposure time"
    } else {
        $itk_component(notice) configure \
        -text "raster will NOT adjust exposure time"
    }
}

### copied and modified from RunListView
class RasterRunListView {
    inherit ::itk::Widget ::DCS::Component
    
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -controlSystem controlsytem ControlSystem "::dcss"

   private variable BROWNRED #a0352a
   private variable ACTIVEBLUE #2465be
   private variable DARK #777

    public proc getFirstObject { } {
        return $s_object
    }
   
   public method handleRunLabelChange
   public method handleRunStateChange
   public method handleRunCountChange
   public method handleClientStatusChange
   public method addNewRun
   private method addMissingTabs
   private method deleteExtraTabs
   private method updateNewRunCommand 
   
    private common s_object ""

    private variable _ready 0
   private variable m_clientState "offline"
   private variable m_runCount 0 
   private variable m_tabs 0
   private variable m_runLabel  
   private variable m_runStateColor  
    
    private variable m_deviceFactory
    private variable m_objRuns
    private variable m_objRasterRunsConfig

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objRuns [$m_deviceFactory createString raster_runs]
        $m_objRuns createAttributeFromField runCount 0

        set m_objRasterRunsConfig \
        [$m_deviceFactory createOperation rasterRunsConfig]

      set ring $itk_interior
      
      # make a folder frame for holding runs
      itk_component add notebook {
         iwidgets::tabnotebook $ring.n \
               -tabpos e -gap 4 -angle 20 -width 330 -height 800 \
               -raiseselect 1 -bevelamount 4 -padx 5 \
      } {}

      #add the tab
      $itk_component(notebook) add -label " * "
         
      #pack the single runView widget into the first childsite 
      set childsite [$itk_component(notebook) childsite 0]
      pack $childsite
      #select the first tab to see the runView and then turn off the auto configuring
      $itk_component(notebook) select 0
      $itk_component(notebook) configure -auto off
      
        itk_component add runView {
            RasterView $childsite.rv 
        } {
            keep -diffractionImageViewer
        }


      eval itk_initialize $args   
      
      
      pack $itk_component(runView) -expand 1 -fill both
      pack $itk_component(notebook) -side top -anchor n -pady 0 \
        -expand 1 -fill both


        for { set run 0 } { $run < [::DCS::RasterBase::getMAXRUN] } { incr run } {
            set name raster_run$run
            set obj [$m_deviceFactory getObjectName $name]
            $obj createAttributeFromField state 0
            $obj createAttributeFromField runLabel 1
        
            set m_runLabel($run) "X"
            set m_runStateColor($run) $ACTIVEBLUE 
            ::mediator register $this $obj state    handleRunStateChange
            ::mediator register $this $obj runLabel handleRunLabelChange
        }

      #fill in the missing run tabs
      addMissingTabs [lindex [$m_objRuns getContents] 0  ]

      #register for interest in the number of defined runs
      ::mediator register $this $m_objRuns runCount handleRunCountChange 
    
      ::mediator register $this ::$itk_option(-controlSystem) clientState handleClientStatusChange   

      #allow observers to know what the embedded runViewer is looking at.
      exportSubComponent runDefinition ::$itk_component(runView) 

      announceExist

        if {$s_object == ""} {
            set s_object $this
        }
   }

    destructor {
    }
}


body RasterRunListView::addNewRun {} {
    if { $m_clientState != "active"} return

    $m_objRasterRunsConfig startOperation addNewRaster
}

body RasterRunListView::deleteExtraTabs { systemRunCount_ } {
    set maxCount [::DCS::RasterBase::getMAXRUN]
    puts "delete: count: $m_tabs max: $maxCount"

   #while deleting tabs don't select the last tab, which is the *.
   set currentSelection [$itk_component(notebook) index select]


   if {$m_tabs <= [expr $systemRunCount_ + 1]} return

   for {set tab $m_tabs} { $tab > [expr $systemRunCount_ + 1] } {incr tab -1} {
      if {$tab < $maxCount} {
         $itk_component(notebook) delete [expr $tab - 1]
      }
   }

   
   puts "$currentSelection , $m_tabs"


   set m_tabs $tab
   set m_runCount $systemRunCount_

   if { $currentSelection >= $m_tabs } {
      $itk_component(notebook) select [expr $m_tabs - 1]
   }

   updateNewRunCommand
}

body RasterRunListView::addMissingTabs { systemRunCount_ } {
    set maxCount     [::DCS::RasterBase::getMAXRUN]
    incr maxCount -1
    puts "add: count: $m_tabs max: $maxCount"

    if { $m_tabs > $systemRunCount_ } return
   
    for { set tab $m_tabs } { $tab <= $systemRunCount_ } {incr tab} {
        if {$tab < $maxCount} {
            $itk_component(notebook) insert $tab 
        }
        $itk_component(notebook) pageconfigure $tab \
        -state normal \
        -command "::gRaster switchRasterNumber $tab" \
        -label $m_runLabel($tab) \
        -foreground $m_runStateColor($tab) \
        -selectforeground $m_runStateColor($tab)
    }
   
    set m_tabs $tab
    set m_runCount $systemRunCount_

    set current [$itk_component(notebook) index select]
    set desired [expr $m_tabs - 1]
    if {$current != $desired} {
      $itk_component(notebook) select [expr $m_tabs - 1]
    }

    updateNewRunCommand
}

body RasterRunListView::handleClientStatusChange { control_ targetReady_ alias_ clientStatus_ -  } {
   if { !$targetReady_ } return

   set maxCount [::DCS::RasterBase::getMAXRUN]
   puts "client status change count: $m_tabs max: $maxCount"


   if {$clientStatus_ != "active" && $m_tabs < $maxCount} {
      $itk_component(notebook) pageconfigure end -state disabled
   } else {
      $itk_component(notebook) pageconfigure end -state normal 
   }

   set m_clientState $clientStatus_
}

body RasterRunListView::handleRunCountChange { run_ targetReady_ alias_ systemRunCount_ -  } {
   if { !$targetReady_ } return

   puts "RunListView::handleRunCountChange: $systemRunCount_"
   
   deleteExtraTabs $systemRunCount_
   addMissingTabs $systemRunCount_

   #$itk_component(notebook) select $systemRunCount_
}

body RasterRunListView::handleRunLabelChange { run_ targetReady_ alias_ runLabel_ -  } {
   if { !$targetReady_ } return
  
    set run [string range [namespace tail $run_] 10 end]

   puts "Setting $run label to $runLabel_"
   set m_runLabel($run) $runLabel_
 
   if { $run > $m_runCount } {
      return
   }

   $itk_component(notebook) pageconfigure $run -label $runLabel_
}


body RasterRunListView::updateNewRunCommand {} {
    set maxCount [::DCS::RasterBase::getMAXRUN]

    puts "update: count: $m_tabs max: $maxCount"

   if {$m_tabs < $maxCount} {
      #configure the 'add run' star
      $itk_component(notebook) pageconfigure end \
      -label " * " \
      -command [list $this addNewRun ] 

      if {$m_clientState != "active"} {
         $itk_component(notebook) pageconfigure end -state disabled
      }
   }
}

#Updates the colors of the run tabs based on the status of the run.
body RasterRunListView::handleRunStateChange { run_ targetReady_ alias_ runState_ -  } {
   if { !$targetReady_ } return

    set run [string range [namespace tail $run_] 10 end]
  
    #pick the color based on the status of the run
   switch $runState_ {
        paused { set color $BROWNRED }
        collecting {set color red }
        inactive {set color $ACTIVEBLUE }
        complete {
            #Always force the first run to be the same color.
            if {$run != 0 } {
                set color $DARK
            } else {
                set color black
            }
        }
      default { set color red }
   }
   
   set m_runStateColor($run) $color

    #return if the run is not defined
   if { $run > $m_runCount } return

   #configure the tab's color
   $itk_component(notebook) pageconfigure $run \
         -foreground $color -selectforeground $color
}

class RasterView {
    inherit ::itk::Widget DCS::Component

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    ### 0: no show (raster not defined)
    ### 1: show first view only
    ### 2: show second view only (not used yet. matrix cannot display second alone.
    ### 3: show both views
    private variable m_snapshotDisplayState 3

    private variable m_ctsInfo ""
    private variable m_ctsUserSetup ""

    private variable m_inConstructor 0

    private variable m_showingUserSetup 0

    private variable m_mapTab       [list Spots Shape Res  Score Rings]
    private variable m_mapSubField  [list 0     5     3    2     4   ]
    private variable m_mapDrawTopo  [list 1     0     0    0     0   ]
    private variable m_mapDrawRidge [list 1     0     0    0     0   ]
    private variable m_mapShowNum   [list 1     1     1    1     1   ]
    private variable m_mapFormat    [list %.0f  %.1f  %.1f %.1f  %.0f]
    ## now the format is only used by hint.

    private variable m_objRasterRunsConfig
    private variable m_objCollectRaster
    private variable m_objCollectRasters
    private variable m_objPause

    private common s_lastObject ""

    private common COLOR_GRID #ffffff
    private common PROMPT_WIDTH 8
    private common BUTTON_WIDTH 10

	public method addChildVisibilityControl { args } {
	    eval $itk_component(sample_video) addChildVisibilityControl $args
    }

    public method handleAreaDefining { index x1 y1 x2 y2 } {
        ::gRaster defineView $index $x1 $y1 $x2 $y2
    }

    public method deleteRun { } {
        ::gRaster deleteRun
    }
    public method resetRun { } {
        ::gRaster resetRun
    }

    public method startCollectRaster { } {
        set rasterNum [::gRaster getRasterNumber]
        if {$rasterNum < 1} {
            set rasterNum 0
        }

        set data_root [::config getDefaultDataHome]

        if {$rasterNum == 0} {
            $m_objCollectRaster startOperation $rasterNum USER SID $data_root
        } else {
            $m_objCollectRasters startOperation $rasterNum SID $data_root
        }
    }
    public method pauseCollectRaster { } {
        $m_objPause startOperation
    }

    public method skipRaster { } {
        $itk_option(-controlSystem) sendMessage {gtos_stop_operation collectRaster}
    }

    public method moveScanArea {  index dir } {
        ::gRaster moveView $index $dir
    }

    public method movePhi { index } {
        #::gRaster moveViewToVideo $index
        ::gRaster moveViewToBeam $index
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
            -x $showingX -y $showingY -anchor nw

            raise $itk_component(userSetup)
            set m_showingUserSetup 1
        }
    }

    public method hintConvert { info }

    public method showTab { index } {
        if {$m_inConstructor} {
            return
        }
        set subField [lindex $m_mapSubField $index]
        set drawContour [lindex $m_mapDrawTopo $index]
        set drawRidge   [lindex $m_mapDrawRidge $index]
        set showNum     [lindex $m_mapShowNum  $index]
        if {$subField == ""} {
            set subField 0
            log_error wrong subField index=$index list=$m_mapSubField
        }
        if {$drawContour == ""} {
            set drawContour 1
            log_error wrong drawTopo index=$index list=$m_mapDrawTopo
        }
        if {$drawRidge == ""} {
            set drawRidge 1
            log_error wrong drawRidge index=$index list=$m_mapDrawRidge
        }
        if {$showNum == ""} {
            set showNum 1
            log_error wrong showNum index=$index list=$m_mapShowNum
        }
        $itk_component(rasters) configure \
        -showContour $drawContour \
        -showRidge   $drawRidge \
        -showValue   $showNum \
        -subField    $subField \

        #puts "calling updateTopo in showTab"
        #$itk_component(rasters) updateTopo
    }

    public method handleAllNew
    public method handleRasterSetupUpdate
    public method handleUserSetupUpdate

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
    private method updateInfo { }

    constructor { args } {
        set m_inConstructor 1

        set deviceFactory [DCS::DeviceFactory::getObject]

        set m_objRasterRunsConfig \
        [$deviceFactory createOperation rasterRunsConfig]

        set m_objCollectRaster \
        [$deviceFactory createOperation collectRaster]

        set m_objCollectRasters \
        [$deviceFactory createOperation collectRasters]

        set m_objPause \
        [$deviceFactory createOperation pauseDataCollection]

        itk_component add control_frame {
            frame $itk_interior.ff
        } {
        }

        set controlSite $itk_component(control_frame)
        itk_component add bConfig {
            DCS::Button $controlSite.setup \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -text "Setup" \
            -command "$this flipUserSetup"
        } {
        }

        itk_component add bStart {
            DCS::Button $controlSite.start \
            -width $BUTTON_WIDTH \
            -text "Start" \
            -command "$this startCollectRaster"
        } {
        }

        itk_component add bPause {
            DCS::Button $controlSite.pause \
            -systemIdleOnly 0 \
            -width $BUTTON_WIDTH \
            -text "Pause" \
            -command "$this pauseCollectRaster"
        } {
        }

        itk_component add bSkip {
            DCS::Button $controlSite.skip \
            -systemIdleOnly 0 \
            -width $BUTTON_WIDTH \
            -text "Skip" \
            -command "$this skipRaster"
        } {
        }

        itk_component add bDelete {
            DCS::Button $controlSite.delete \
            -width $BUTTON_WIDTH \
            -text "Delete" \
            -command "$this deleteRun"
        } {
        }

        itk_component add bReset {
            DCS::Button $controlSite.reset \
            -width $BUTTON_WIDTH \
            -text "Reset" \
            -command "$this resetRun"
        } {
        }

        itk_component add pw {
            iwidgets::panedwindow $itk_interior.pw \
            -orient vertical
        } {
        }

        itk_component add userSetup {
            RasterUserSetupView $itk_interior.userSetup
        } {
        }

        $itk_component(pw) add left   -minimum 100 -margin 1
        $itk_component(pw) add right  -minimum 100 -margin 1
        set snapshotSite  [$itk_component(pw) childsite 0]
        set gridSite      [$itk_component(pw) childsite 1]
        $itk_component(pw) fraction 66 34

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
            RasterSnapshotView $snapSite0.s0 \
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
            RasterSnapshotView $snapSite1.s1 \
            -packOption "-side top -anchor ne" \
            -activeClientOnly 1 \
            -onAreaDefining "$this handleAreaDefining 1"
        } {
        }

        pack $itk_component(phi0_frame) -side top -fill x
        pack $itk_component(snapshot0)  -side top -expand 1 -fill both
        pack propagate $itk_component(snapshot0) 0
        ## this is to tell the image only fit its size, not ask for bigger

        pack $itk_component(phi1_frame) -side top -fill x
        pack $itk_component(snapshot1)  -side top -expand 1 -fill both
        pack propagate $itk_component(snapshot1) 0

        grid $itk_component(s_frame0) -row 0 -column 0 -sticky news
        grid $itk_component(s_frame1) -row 1 -column 0 -sticky news
        grid rowconfigure $snapshotSite 0 -weight 10
        grid rowconfigure $snapshotSite 1 -weight 10
        grid columnconfigure $snapshotSite 0 -weight 10

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
            RasterMatrixView $matrixSite.rasters \
            -hintGenerator "$this hintConvert" \
            -valueConverter $this \
            -imageSources \
            [list $itk_component(snapshot0) $itk_component(snapshot1)] \
        } {
            keep -diffractionImageViewer
        }
        pack $itk_component(rasters) -expand 1 -fill both

        $itk_component(movePhi0) addInput \
        "::gRaster defined0 1 {define raster first}"
        $itk_component(movePhi1) addInput \
        "::gRaster defined1 1 {define raster first}"
        $itk_component(moveArea0) addInput \
        "::gRaster defined0 1 {define raster first}"
        $itk_component(moveArea0) addInput \
        "::gRaster run_state inactive {reset raster first}"
        $itk_component(moveArea1) addInput \
        "::gRaster defined1 1 {define raster first}"
        $itk_component(moveArea1) addInput \
        "::gRaster run_state inactive {reset raster first}"
        $itk_component(insideGrid0) addInput \
        "::gRaster defined0 1 {define raster first}"
        $itk_component(insideGrid1) addInput \
        "::gRaster defined1 1 {define raster first}"

        $itk_component(bConfig) addInput \
        "::gRaster defined 1 {define raster first}"

        $itk_component(bStart) addInput \
        "$m_objRasterRunsConfig status inactive {busy}"
        $itk_component(bStart) addInput \
        "$m_objCollectRaster status inactive {busy}"
        $itk_component(bStart) addInput \
        "$m_objCollectRasters status inactive {busy}"
        $itk_component(bStart) addInput \
        "::gRaster runnable 1 {define or reset raster}"

        $itk_component(bPause) addInput \
        "$m_objCollectRaster status active {not running}"

        $itk_component(bSkip) addInput \
        "$m_objCollectRaster status active {not running}"
        $itk_component(bSkip) addInput \
        "::gRaster run_state collecting {not running}"

        #$itk_component(bDelete) addInput \
        #"::gRaster defined 1 {define raster first}"
        $itk_component(bDelete) addInput \
        "::gRaster run_state inactive {reset raster first}"
        $itk_component(bDelete) addInput \
        "::gRaster not_raster0 1 {cannot delete this raster}"
        $itk_component(bDelete) addInput \
        "$m_objRasterRunsConfig status inactive {busy}"
        $itk_component(bDelete) addInput \
        "$m_objCollectRaster status inactive {busy}"

        $itk_component(bReset) addInput \
        "::gRaster defined 1 {define raster first}"
        $itk_component(bReset) addInput \
        "::gRaster needs_reset 1 {only for complete and paused raster}"
        $itk_component(bReset) addInput \
        "$m_objRasterRunsConfig status inactive {busy}"
        $itk_component(bReset) addInput \
        "$m_objCollectRaster status inactive {busy}"

        pack $itk_component(bConfig) -side left
        pack $itk_component(bStart) -side left
        pack $itk_component(bPause) -side left
        pack $itk_component(bSkip) -side left

        pack $itk_component(bReset) -side right
        pack $itk_component(bDelete) -side right

        pack $itk_component(matrix) -expand 1 -fill both

        pack $itk_component(control_frame) -side top -fill x
        pack $itk_component(pw) -side top -expand 1 -fill both

        eval itk_initialize $args

        set m_inConstructor 0

        set s_lastObject $this

        puts "Raster object: $this"

        ::gRaster register $this all_new      handleAllNew
        ::gRaster register $this raster_setup handleRasterSetupUpdate
        ::gRaster register $this user_setup   handleUserSetupUpdate

        showTab 0
    }

    destructor {
        ::gRaster unregister $this all_new      handleAllNew
        ::gRaster unregister $this raster_setup handleRasterSetupUpdate
        ::gRaster unregister $this user_setup   handleUserSetupUpdate
    }
}
body RasterView::handleAllNew { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    set m_ctsInfo [lindex $contents_ 0]
    set m_ctsUserSetup [::gRaster getUserSetup]
    updateInfo
    updateExposureTime
}
body RasterView::handleRasterSetupUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    set m_ctsInfo $contents_
    updateInfo
}
body RasterView::handleUserSetupUpdate { - targetReady_ - contents_ - } {
    if {!$targetReady_} {
        return
    }

    set m_ctsUserSetup $contents_
    updateExposureTime
}
body RasterView::updateInfo { } {
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
    set woff0      [lindex $m_ctsInfo 19]
    set hoff0      [lindex $m_ctsInfo 20]
    set woff1      [lindex $m_ctsInfo 21]
    set doff1      [lindex $m_ctsInfo 22]

    if {$inlineMode != "1"} {
        set inlineMode 0
    }

    set snapshot0 [lindex $info0 0]
    set snapshot1 [lindex $info1 0]

    set orig0     [lindex $info0 1]
    set orig1     [lindex $info1 1]

    set a0        [lindex $orig0 3]
    set a1        [lindex $orig1 3]
    set cur_omega [lindex [::device::gonio_omega getScaledPosition] 0]

    if {$defined0 == "1" \
    && [string is double -strict $a0] \
    && $a0 != -999} {
        #if {$inlineMode} {
        #    set phi0 [expr $a0 - $cur_omega]
        #} else {
        #    set phi0 [expr $a0 + 90 - $cur_omega]
        #}
        set phi0 [expr $a0 - $cur_omega]
        set phi0 [format "%.1f" $phi0]
    } else {
        set phi0 ""
    }
    if {$defined1 == "1" \
    && [string is double -strict $a1] \
    && $a1 != -999} {
        #if {$inlineMode} {
        #    set phi1 [expr $a1 - $cur_omega]
        #} else {
        #    set phi1 [expr $a1 + 90 - $cur_omega]
        #}
        set phi1 [expr $a1 - $cur_omega]
        set phi1 [format "%.1f" $phi1]
    } else {
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
    if {$defined0 == "1" \
    && [string is double -strict $wu] \
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
        set h0    [expr $hu     / $hU]
    }

    if {$defined1 == "1" \
    && [string is double -strict $wu] \
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
        set d1    [expr $du     / $dU]
    }

    set newDisplayState 3
    if {$defined0 != "1"} {
        set snapshot0 ""
        set woff0 -999
        incr newDisplayState -1
    }
    if {$defined1 != "1"} {
        set snapshot1 ""
        set woff1 -999
        incr newDisplayState -2
    }
    if {$m_snapshotDisplayState != $newDisplayState} {
        pack forget \
        $itk_component(phi0_frame) \
        $itk_component(snapshot0) \
        $itk_component(phi1_frame) \
        $itk_component(snapshot1)

        set m_snapshotDisplayState $newDisplayState
        switch -exact -- $m_snapshotDisplayState {
            0 {
            }
            1 {
                pack $itk_component(phi0_frame) -side top -fill x
                pack $itk_component(snapshot0)  -side top -expand 1 -fill both
            }
            2 -
            3 -
            default {
                pack $itk_component(phi0_frame) -side top -fill x
                pack $itk_component(snapshot0)  -side top -expand 1 -fill both

                pack $itk_component(phi1_frame) -side top -fill x
                pack $itk_component(snapshot1)  -side top -expand 1 -fill both
            }
        }   
    }
    
    $itk_component(snapshot0) configure \
    -snapshot $snapshot0 \

    $itk_component(snapshot1) configure \
    -snapshot $snapshot1 \

    $itk_component(snapshot0) configure \
    -gridInfo [list $woff0 $hoff0 $w0 $h0 $nw $nh]

    $itk_component(snapshot1) configure \
    -gridInfo [list $woff1 $doff1 $w1 $d1 $nw $nd]

    puts "DEBUG grid0: [list $woff0 $hoff0 $w0 $h0 $nw $nh]"
    puts "DEBUG grid1: [list $woff1 $doff1 $w1 $d1 $nw $nd]"

    if {$defined0 == "1" || $defined1 == "1"} {
        pack $itk_component(matrix) -expand 1 -fill both
    } else {
        pack forget $itk_component(matrix) 
        hideUserSetup forced
    }
}
body RasterView::updateExposureTime { } {
    set time0 [lindex $m_ctsUserSetup 4]
    set time1 [lindex $m_ctsUserSetup 5]

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
body RasterView::hintConvert { args } {
    switch -exact -- $args {
        NEW -
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
body RasterView::cvtNoChange { vList offset } {
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
body RasterView::cvtChangeSign { vList offset } {
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
body RasterView::cvtChangeSignLimits { vList offset min max } {
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
body RasterView::toMatrix { vList offset } {
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
body RasterView::toDisplay { vList offset } {
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
body RasterView::cvtDisplayFormat { vList offset fmt } {
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
class RasterTab {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_inConstructor 0

    private variable m_sampleVideo ""
    private variable m_inlineVideo ""

    private common s_lastObject ""

    public method handleVideoViewChange { - targetReady_ - is_inline_ - } {
        if {!$targetReady_} {
            return
        }
        if {$is_inline_} {
            $itk_component(sample_video) selectView 1
        } else {
            $itk_component(sample_video) selectView 0
        }
    }
	public method addChildVisibilityControl { args } {
	    eval $itk_component(sample_video) addChildVisibilityControl $args
    }

    public method takeSnapshots { inline } {
        ::gRaster takeSnapshot $inline
    }
    public method autoFillFields { } {
        ::gRaster autoFill
    }

    public proc getObject { } {
        return $s_lastObject
    }

    constructor { args } {
        global gMotorBeamWidth
        global gMotorBeamHeight
        global gInlineCameraExists

        set m_inConstructor 1

        set deviceFactory [DCS::DeviceFactory::getObject]

        itk_component add pw {
            iwidgets::panedwindow $itk_interior.pw \
            -orient vertical
        } {
        }

        $itk_component(pw) add left   -minimum 100 -margin 1
        $itk_component(pw) add right  -minimum 100 -margin 1
        set videoSite     [$itk_component(pw) childsite 0]
        set rasterSite    [$itk_component(pw) childsite 1]
        $itk_component(pw) fraction 40 60

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

            $m_sampleVideo addInputForRaster \
            "::gRaster run_state inactive {reset raster first}"

            $m_sampleVideo configCenterLoopButton \
            -command "$this autoFillFields"

            set m_inlineVideo [$itk_component(sample_video) getInlineVideo]
            $m_inlineVideo configSnapshotButton \
            -systemIdleOnly 1 \
            -activeClientOnly 1 \
            -text "Micro Raster" \
            -command "$this takeSnapshots 1"

            $m_inlineVideo addInputForRaster \
            "::gRaster run_state inactive {reset raster first}"

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

            $m_sampleVideo addInputForRaster \
            "::gRaster run_state inactive {reset raster first}"

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

        pack $itk_component(pwv) -side top -expand 1 -fill both

        itk_component add rls {
            RasterRunListView $rasterSite.rls \
            -diffractionImageViewer $itk_component(diff_viewer) \
        } {
        }

        pack $itk_component(rls) -side top -expand 1 -fill both

        pack $itk_component(pw) -side top -expand 1 -fill both

        eval itk_initialize $args

        set m_inConstructor 0

        set s_lastObject $this

        puts "RasterTab object: $this"
        global gRasterTab
        set gRasterTab $this

        if {$gInlineCameraExists} {
            ::gRaster register $this is_inline  handleVideoViewChange
        }
    }

    destructor {
        if {$gInlineCameraExists} {
            ::gRaster unregister $this is_inline  handleVideoViewChange
        }
    }
}
