package provide GridCanvas 1.0

package require Iwidgets

package require DCSComponent
package require ComponentGateExtension
package require DCSDeviceFactory
package require DCSDeviceView
package require DCSUtil
package require DCSContour
package require DCSGridGroup4BluIce

class GridGroupColor {
    #### for grid shape drawing.
    public common COLOR_RUBBERBAND       green
    public common COLOR_POLY_START       red
    public common COLOR_SHAPE_CURRENT    yellow
    public common COLOR_SHAPE            gray 
    public common COLOR_OUTLINE          green
    public common COLOR_ROTOR            green
    public common COLOR_VERTEX           red
    public common COLOR_GRID             blue

    public common COLOR_BEAM             brown
    public common COLOR_VALUE            brown

    #### for node status
    public common COLOR_NA               #7382B9
    public common COLOR_EXPOSING         #c04080
    public common COLOR_PROCESS          "dark green"
    public common COLOR_DONE             #00a040
    public common COLOR_CURRENT          #a0a0c0

    public common COLOR_UNSELECTED       red
    public common COLOR_SKIP             red
    public common COLOR_BAD              red
}
### interface needed
### too complicate to use event driven pattern.
class GridGroup::VideoImageDisplayHolder {
    inherit ::DCS::Component

    ### must export:
    ###### current_grid:  return gridId.
    ###### tool_mode:  return tool_mode, only fire when user click

    #### tool mode change triggered by other GUI.
    public method setToolMode { mode } { error }

    public method switchGroup { gId snapshotList {idMap ""} }
    public method addImageToTop { ssId idMap }
    public method moveImageToTop { ssId idMap {evenDisplayed 1} }
    public method imageShowing { ssId }
    public method addGrid { objGrid }
    public method deleteGrid { id }
    public method updateGrid { objGrid }
    public method adjustGrid { id param }
    public method setNode { id index status }
    public method setMode { id status }
    public method setBeamSize { contents }
    public method refreshMatrixDisplay { }

    public method setCurrentGrid { ssId id }
    public method clearCurrentGrid { } { error }

    public method getDisplayedSnapshotIdList { } {
        set idList ""
        for {set i 0} {$i < $m_numDisplayed} {incr i} {
            set display [lindex $m_displayList $i]
            lappend idList [$display getSnapshotId]
        }
        return $idList
    }


    protected method showDisplays { num } { error }
    ## not implemented, not used yet.
    protected method zoomOnGrid { ssId objGrid }

    ## self
    protected method setImageList { snapshotList {idMap ""}}
    protected method autoFillSnapshotDisplay { ssList }
    protected method getSnapshotDisplayIndex { id }

    ### init in constructor
    protected variable m_maxNumDisplay 0
    protected variable m_displayList [list]

    protected variable m_groupId -1
    protected variable m_numDisplayed 0
    ### we want to keep the list when we switch group
    protected variable d_idListSnapshotDisplayed ""
}
body GridGroup::VideoImageDisplayHolder::autoFillSnapshotDisplay { ssList } {
    if {$m_groupId < 0} {
        return
    }
    set idList ""
    foreach ss $ssList {
        set id [$ss getId]
        lappend idList $id
    }
    set idList [lrange $idList 0 [expr $m_numDisplayed - 1]]
    dict set d_idListSnapshotDisplayed $m_groupId $idList
}
body GridGroup::VideoImageDisplayHolder::getSnapshotDisplayIndex { ssId } {
    if {![dict exists $d_idListSnapshotDisplayed $m_groupId]} {
        return -1
    }
    set idList [dict get $d_idListSnapshotDisplayed $m_groupId]
    return [lsearch -exact $idList $ssId]
}
body GridGroup::VideoImageDisplayHolder::setBeamSize { info } {
    for {set i 0} {$i < $m_maxNumDisplay} {incr i} {
        set display [lindex $m_displayList $i]
        $display setBeamSize $info
    }
}
body GridGroup::VideoImageDisplayHolder::refreshMatrixDisplay { } {
    for {set i 0} {$i < $m_maxNumDisplay} {incr i} {
        set display [lindex $m_displayList $i]
        $display refreshMatrixDisplay
    }
}
body GridGroup::VideoImageDisplayHolder::switchGroup { gId ssList {idMap ""} } {
    if {$gId < 0} {
        set ssList ""
    }
    if {$m_groupId != $gId && $gId >= 0} {
        set m_groupId $gId
        if {![dict exists $d_idListSnapshotDisplayed $m_groupId]} {
            autoFillSnapshotDisplay $ssList
        }
    }
    set m_groupId $gId
    for {set i 0} {$i < $m_maxNumDisplay} {incr i} {
        set display [lindex $m_displayList $i]
        $display setGroupId $m_groupId
    }
    setImageList $ssList $idMap
}
body GridGroup::VideoImageDisplayHolder::setImageList { ssList {idMap ""} } {
    if {$idMap == ""} {
        set idMap [dict create]
        foreach ss $ssList {
            dict set ipMap [$ss getId] $ss
        }
    }

    set idListRaw [dict get $d_idListSnapshotDisplayed $m_groupId]
    set idList ""
    foreach id $idListRaw {
        if {![dict exists $idMap $id]} {
            log_error snapshot id=$id not exists anymore.
        } else {
            lappend idList $id
        }
    }

    set ll [llength $idList]
    if {$ll > $m_maxNumDisplay} {
        set end [expr $m_maxNumDisplay - 1]
        set idList [lrange $idList 0 $end]
        set ll $m_maxNumDisplay
    } elseif {$ll < $m_maxNumDisplay} {
        foreach ss $ssList {
            set id [$ss getId]
            if {[lsearch -exact $idList $id] < 0} {
                lappend idList $id
                incr ll
                if {$ll >= $m_maxNumDisplay} {
                    break
                }
            }
        }
    }

    #puts "displaying total: $ll"
    showDisplays $ll
    set idList [lrange $idList 0 [expr $m_numDisplayed - 1]]
    dict set d_idListSnapshotDisplayed $m_groupId $idList

    if {$ll == 0} {
        log_error gridGroup without snapshot????
        #return
    }
    for {set i 0} {$i < $ll} {incr i} {
        set display [lindex $m_displayList $i]
        set id [lindex $idList $i]
        set snapshot [dict get $idMap $id]
        $display refresh $snapshot
    }
    for {set i $ll} {$i < $m_maxNumDisplay} {incr i} {
        set display [lindex $m_displayList $i]
        $display reset
    }
}
body GridGroup::VideoImageDisplayHolder::addImageToTop { ssId idMap } {
    puts "addImageToTop: ssId=$ssId"
    if {$m_groupId < 0} {
        puts "group wrong"
        return
    }

    if {![dict exists $idMap $ssId]} {
        log_error snapshot with id=$ssId not exists
        return
    }
    if {![dict exists $d_idListSnapshotDisplayed $m_groupId]} {
        set idList ""
    } else {
        set idList [dict get $d_idListSnapshotDisplayed $m_groupId]
    }
    set index [lsearch -exact $idList $ssId]
    if {$index >= 0} {
        log_error snapshot already displayed
        return
    }
    set idList [linsert $idList 0 $ssId]
    if {$m_numDisplayed < $m_maxNumDisplay} {
        showDisplays [expr $m_numDisplayed + 1]
    }

    set idList [lrange $idList 0 [expr $m_numDisplayed - 1]]
    dict set d_idListSnapshotDisplayed $m_groupId $idList
    for {set i 0} {$i < $m_numDisplayed} {incr i} {
        set display [lindex $m_displayList $i]
        set id [lindex $idList $i]
        set snapshot [dict get $idMap $id]
        puts "refresh for i=$ id=$id ss=$snapshot"
        $display refresh $snapshot
    }
    updateRegisteredComponents snapshot_displayed
    return $index
}
body GridGroup::VideoImageDisplayHolder::moveImageToTop {
    ssId idMap {evenDisplayed 1}
} {
    puts "moveImageToTop: ssId=$ssId"
    if {$m_groupId < 0} {
        puts "group wrong"
        return -1
    }

    if {![dict exists $idMap $ssId]} {
        log_error snapshot with id=$ssId not exists
        return -1
    }
    if {![dict exists $d_idListSnapshotDisplayed $m_groupId]} {
        set idList ""
    } else {
        set idList [dict get $d_idListSnapshotDisplayed $m_groupId]
    }
    set index [lsearch -exact $idList $ssId]
    puts "index=$index"
    if {$index == 0} {
        ### already at top
        puts "already at top"
        return 0
    }
    if {$evenDisplayed} {
        if {$index > 0} {
            set idList [lreplace $idList $index $index]
        }
        set idList [linsert $idList 0 $ssId]
        set index 0
    } else {
        if {$index < 0} {
            set idList [linsert $idList 0 $ssId]
            set index 0
        } elseif {$index >= $m_numDisplayed} {
            puts "must have forgotten to cut the idList"
            set idList [lreplace $idList $index $index]
            set idList [linsert $idList 0 $ssId]
            set index 0
        } else {
            puts "not forced and it is arealdy at $index"
            return $index
        }
    }
    set idList [lrange $idList 0 [expr $m_numDisplayed - 1]]
    dict set d_idListSnapshotDisplayed $m_groupId $idList

    for {set i 0} {$i < $m_numDisplayed} {incr i} {
        set display [lindex $m_displayList $i]
        set id [lindex $idList $i]
        set snapshot [dict get $idMap $id]
        puts "refresh for i=$ id=$id ss=$snapshot"
        $display refresh $snapshot
    }
    updateRegisteredComponents snapshot_displayed
    return $index
}
body GridGroup::VideoImageDisplayHolder::imageShowing { ssId } {
    if {$m_groupId < 0} {
        return 0
    }

    if {![dict exists $d_idListSnapshotDisplayed $m_groupId]} {
        return 0
    }
    set idList [dict get $d_idListSnapshotDisplayed $m_groupId]
    set index [lsearch -exact $idList $ssId]

    if {$index >= 0} {
        return 1
    }
    return 0
}
body GridGroup::VideoImageDisplayHolder::addGrid { objGrid } {
    for {set i 0} {$i < $m_numDisplayed} {incr i} {
        set display [lindex $m_displayList $i]
        if {$display != ""} {
            $display addGrid $objGrid
        }
    }
}
body GridGroup::VideoImageDisplayHolder::deleteGrid { id } {
    for {set i 0} {$i < $m_numDisplayed} {incr i} {
        set display [lindex $m_displayList $i]
        if {$display != ""} {
            $display deleteGrid $id
        }
    }
}
body GridGroup::VideoImageDisplayHolder::updateGrid { objGrid } {
    for {set i 0} {$i < $m_numDisplayed} {incr i} {
        set display [lindex $m_displayList $i]
        if {$display != ""} {
            $display updateGrid $objGrid
        }
    }
}
body GridGroup::VideoImageDisplayHolder::adjustGrid { id param } {
    for {set i 0} {$i < $m_numDisplayed} {incr i} {
        set display [lindex $m_displayList $i]
        if {$display != ""} {
            $display adjustGrid $id $param
        }
    }
}
body GridGroup::VideoImageDisplayHolder::setNode { id index status } {
    for {set i 0} {$i < $m_numDisplayed} {incr i} {
        set display [lindex $m_displayList $i]
        if {$display != ""} {
            $display setNode $id $index $status
        }
    }
}
body GridGroup::VideoImageDisplayHolder::setMode { id gridStatus } {
    for {set i 0} {$i < $m_numDisplayed} {incr i} {
        set display [lindex $m_displayList $i]
        if {$display != ""} {
            $display setMode $id $gridStatus
        }
    }
}
body GridGroup::VideoImageDisplayHolder::setCurrentGrid { ssId id } {
    puts "+setCurrentGrid $ssId $id"
    set dIndex [getSnapshotDisplayIndex $ssId]
    if {$dIndex < 0} {
        puts "-setCurrentGrid, snapshot $ssId not displayed"
        return
    }
    set display [lindex $m_displayList $dIndex]
    if {$display == ""} {
        puts "-setCurrentGrid, display not found"
        return
    }

    $display setCurrentGrid $id

    if {$id >= 0} {
        setToolMode adjust
    }
    puts "-setCurrentGrid done"
}
body GridGroup::VideoImageDisplayHolder::zoomOnGrid { ssId objGrid } {
    set dIndex [getSnapshotDisplayIndex $ssId]
    set display [lindex $m_displayList $dIndex]
    if {$display == ""} return

    $display zoomOnGrid $objGrid
}

class GridCanvasControl {
    inherit ::DCS::ComponentGateExtension

    itk_option define -canvas canvas Canvas "" {
        if {$itk_option(-canvas) != ""} {
            $itk_option(-canvas) register $this toolMode handleToolModeEvent
        }
    }

    itk_option define -forL614 forL614 ForL614 1

    public method handleToolModeEvent { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        #puts "handleToolModeEvent: $contents_"
        onToolModeChange $contents_
    }

    public method setToolMode { mode } {
        foreach cc $itk_option(-canvas) {
            $cc setToolMode $mode
        }
        set head [string range $mode 0 3]
        if {$head == "add_"} {
            set shape [string range $mode 4 end]
            set contents [$m_objLatestUserSetup getContents]
            set dd [eval dict create $contents]
            dict set dd shape $shape
            $m_objLatestUserSetup sendContentsToServer $dd
        }
    }
    public method command { cmd args } {
        foreach cc $itk_option(-canvas) {
            eval $cc $cmd $args
        }
    }

    public method onToolModeChange { currentMode } {
        foreach name $m_toolModeList {
            if {$name == $currentMode} {
                set bg "light green"
            } else {
                set bg $m_normalBG
            }
            $itk_component($name) configure \
            -background $bg
        }
    }

    private variable m_toolModeList [list \
    add_l614 \
    add_rectangle \
    add_oval \
    add_line \
    add_polygon \
    adjust \
    pan \
    ]

    private variable m_toolModeLabel [list \
    l614_grid \
    rectangle \
    oval \
    line \
    polygon \
    modify \
    pan \
    ]

    private variable m_normalBG ""
    private variable m_objLatestUserSetup ""

    constructor { args } {
        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objLatestUserSetup \
        [$deviceFactory createString latest_raster_user_setup]

        foreach name $m_toolModeList txt $m_toolModeLabel {
            itk_component add $name {
                button $itk_interior.$name \
                -text $txt \
                -command "$this setToolMode $name"
            } {
            }
        }

        itk_component add delete {
            button $itk_interior.del \
            -text "delete" \
            -command "$this command deleteSelected"
        } {
        }
        itk_component add zoom_in {
            button $itk_interior.zin \
            -text "zoom in" \
            -command "$this command zoomIn"
        } {
        }
        itk_component add zoom_out {
            button $itk_interior.zout \
            -text "zoom out" \
            -command "$this command zoomOut"
        } {
        }

        set m_normalBG [$itk_component(zoom_out) cget -background]

        eval itk_initialize $args

        if {!$itk_option(-forL614)} {
            foreach name $m_toolModeList {
                pack $itk_component($name) -side left
            }
        } else {
            pack $itk_component(add_l614) -side left
            pack $itk_component(adjust) -side left
        }
        pack $itk_component(delete) -side left
        pack $itk_component(zoom_in) -side left
        pack $itk_component(zoom_out) -side left

        registerComponent \
        $itk_component(add_l614) \
        $itk_component(add_rectangle) \
        $itk_component(add_oval) \
        $itk_component(add_line) \
        $itk_component(add_polygon) \
        $itk_component(adjust) \
        $itk_component(delete)

        announceExist
    }
}

class GridItemHolder {
    public method isActive
    public method addItem { item {from_create 1} }
    public method removeItem { item }
    public method setCurrentItem { item {no_event 0} }
    public method clearCurrentItem { {no_event 0} }
    public method __clearCurrentItem { }

    public method registerButtonCallback { motion release }
    ### polygon needs monitor mouse while no button pressed
    public method registerImageMotionCallback { motion }
    ## it will be cleared upon toolMode change

    public method getEnclosedItems { x1 y1 x2 y2 }

    public method pixel2micron { args } {
        foreach {w h} [getDisplayPixelSize] break
        foreach {- - - - rV rH} [getDisplayOrig] break

        #puts "pixel2micron: image $w X $h size $rH $rV"
        #puts "args=$args"

        set result ""
        foreach {x y} $args {
            set ux [expr 1000.0 * $x * $rH / $w]
            set uy [expr 1000.0 * $y * $rV / $h]
            lappend result $ux $uy
        }
        #puts "Result=$result"
        return $result
    }
    public method micron2pixel { args } {
        foreach {w h} [getDisplayPixelSize] break
        foreach {- - - - rV rH} [getDisplayOrig] break

        #puts "micron2pixel: image $w X $h size $rH $rV"
        #puts "args=$args"

        set result ""
        foreach {ux uy} $args {
            set x [expr $ux * $w / $rH / 1000.0]
            set y [expr $uy * $h / $rV / 1000.0]
            lappend result $x $y
        }
        #puts "Result=$result"
        return $result
    }

    #### pixels
    public method getDisplayPixelSize { }
    #### where (sample_xyz, phi+omega) and zoom (image size in mm).
    public method getDisplayOrig { }

    public method clearNotice { }

    public method onItemClick { item row column }
    public method onItemRightClick { item row column }
    public method moveTo { item x y }

    public method zoomIn { }
    public method zoomOut { }

    public method getZoomCenterX { }
}

### I try to separate the GUI item from GridBase.
### so that the GUI can be used for something else too.

### Any change from GUI should trigger recalulcate of the informations to save.

class GridItemBase {
    public proc setDisplatFieldMaster { m } {
        set s_displayFieldMaster $m
    }
    private proc getColorFromContourLevel { level } {
        if {$level >= 50} {
            set grayScale [expr int(510 - $level * 255 / 50)]
            set color [format "#%02x0000" $grayScale]
        } elseif {$level <= 20} {
            set color yellow
        } else {
            set color green
        }
        return $color
    }
    private proc displacement { segREF x0 y0 } {
        upvar $segREF xyList
        set old $xyList
        set result ""
        foreach {x y} $old {
            if {[catch {
                set x [expr $x + $x0]
                set y [expr $y + $y0]
                lappend result $x $y
            } errMsg]} {
                puts "bad number: $errMsg"
                puts "old list: $old"
                break
            }
        }
        set xyList $result
    }

    protected proc rotateDeltaToDelta { xc yc angle dx dy } {
        set cosA [expr cos($angle)]
        set sinA [expr sin($angle)]
        set x2 [expr $cosA * $dx - $sinA * $dy]
        set y2 [expr $sinA * $dx + $cosA * $dy]
        return [list $x2 $y2]
    }
    protected proc rotateDelta { xc yc angle dx dy } {
        foreach {ndx ndy} [rotateDeltaToDelta $xc $yc $angle $dx $dy] break
        set x2 [expr $xc + $ndx]
        set y2 [expr $yc + $ndy]
        return [list $x2 $y2]
    }
    public proc rotateCalculation { xc yc angle x y } {
        set dx [expr $x - $xc]
        set dy [expr $y - $yc]
        return [rotateDelta $xc $yc $angle $dx $dy]
    }
    public proc rotateCalculationToDelta { xc yc angle x y } {
        set dx [expr $x - $xc]
        set dy [expr $y - $yc]
        return [rotateDeltaToDelta $xc $yc $angle $dx $dy]
    }
    ### outbox with rotation
    public method getCorners { } { return $m_corner }
    public method cornerPress { index x y }
    public method cornerMotion { x y }

    public method rotate { angle {radians 0} } {
        if {$radians} {
            set a $angle
        } else {
            set a [expr $angle * 3.14159 / 180.0]
        }
        set m_oAngle [expr $m_oAngle + $a]
        updateCornerAndRotor
        updateLocalCoords
        redraw 1
    }

    #### group, selected group
    public method raise { } {
        if {$m_gridOnTopOfBody} {
            $m_canvas raise $m_guiId
            $m_canvas raise grid_$m_guiId
            $m_canvas raise hotspot_$m_guiId
        } else {
            $m_canvas raise grid_$m_guiId
            $m_canvas raise $m_guiId
            $m_canvas raise hotspot_$m_guiId
        }

        ### group should be highest
        $m_canvas raise group
        $m_canvas raise beam_info
    }
    ### for now, we use the matrix center.
    public method getCenter { }
    public method getBBox { }
    public method groupRotate { centerX centerY angle {radians 0} } {
        if {$radians} {
            set a $angle
        } else {
            set a [expr $angle * 3.14159 / 180.0]
        }
        set newSelfCenter \
        [rotateCalculation $centerX $centerY $a $m_centerX $m_centerY]

        foreach {m_centerX m_centerY} $newSelfCenter break

        #set newGridCenter \
        #[rotateCalculation $centerX $centerY $a $m_gridCenterX $m_gridCenterY]
        #foreach {m_gridCenterX m_gridCenterY} $newGridCenter break
        saveShape

        set m_oAngle [expr $m_oAngle + $a]
        updateLocalCoords
        updateCornerAndRotor
        updateGrid
        redraw 1
    }
    public method groupMove { dx dy } {
        set m_centerX [expr $m_centerX + $dx]
        set m_centerY [expr $m_centerY + $dy]
        set m_gridCenterX [expr $m_gridCenterX + $dx]
        set m_gridCenterY [expr $m_gridCenterY + $dy]

        saveItemInfo
        updateCornerAndRotor

        redraw 1
    }
    public method onZoom { } {
        rezoom
    }

    public method refresh { } {
        translate
        redraw 0
    }

    public method refreshMatrixDisplay { } {
        if {$m_guiId == ""} {
            return
        }
        redrawGridMatrix
    }

    public method redraw { fromGUI }
    ### redrawHotSpots according to m_status
    ### all redraw should have a call to redrawHotSpots
    ### redrawHotSpot will call generateMatrix or rebornMatrix by fromGUI
    protected method redrawHotSpots { fromGUI }

    protected method shouldDisplay { }

    public method getShape { } {
        return "undefined"
    }

    public method setSequenceType { type } {
        set m_gridSequenceType $type
    }
    public method getSequenceType { } {
        return $m_gridSequenceType
    }

    ### for create
    public method createPress { x y }
    public method createMotion { x y }
    public method createRelease { x y }

    #### state change
    public method onJoinGroup { gg } {
        setItemStatus grouped
    }
    public method onLeaveGroup { } {
        setItemStatus normal
    }
    public method onSelected { } {
        setItemStatus selected
    }
    public method onUnselected { } { 
        setItemStatus normal
    }
    public method onSilence { } { 
        setItemStatus silent
    }
    public method onUnsilence { } { 
        ### unsilent will restore old status
        setItemStatus unsilent
    }
    
    ### selected
    public method vertexPress { index x y }
    public method vertexMotion { x y }
    public method vertexRelease { x y } {
        $m_holder onItemChange $this
    }
    public method vertexEnter { index x y cursor }
    public method enter { }
    public method leave { } { }
    public method bodyPress { x y }
    public method bodyMotion { x y }
    public method bodyRelease { x y } {
        if {$m_motionCalled} {
            $m_holder onItemChange $this
        } elseif {!$m_newCurrentItem && [getShape] != "l614"} {
            set clickInfo [getClickInfo $x $y]
            if {$clickInfo != ""} {
                foreach {row col ux uy} $clickInfo break
                if {[$m_obj getColor $row $col] < 0} {
                    $m_holder onItemClick $this $row $col
                } else {
                    $m_holder moveTo      $this $ux $uy
                }
            }
        }
    }
    public method gridPress { row col x y }
    #### use bodyMotion
    public method gridRelease { x y } {
        if {$m_motionCalled} {
            $m_holder onItemChange $this
        } elseif {!$m_newCurrentItem} {
            set clickInfo [getClickInfo $x $y]
            if {$clickInfo != ""} {
                foreach {- - ux uy} $clickInfo break
                if {[$m_obj getColor $m_pressRow $m_pressCol] < 0} {
                    $m_holder onItemClick $this $m_pressRow $m_pressCol
                } else {
                    $m_holder moveTo      $this $ux $uy
                }
            }
        }
    }

    public method getGridId { } { return $m_itemId }
    public method getItemInfo { }
    public method reborn { gridId info }
    public method updateFromInfo { info {redraw 1}}
    public method getMode { } { return $m_mode }
    public method setMode { gridStatus {redraw 1}} {
        switch -exact -- $gridStatus {
            setup {
                set m_mode adjustable
            }
            complete -
            done -
            skipped -
            skip -
            paused -
            aborted -
            pause {
                set m_mode done
            }
            default {
                set m_mode frozen
            }
        }
        redrawContour
    }

    #### initialized by another GUI to adjust grid position, size, grid cell.
    #### It will cause regenerate matrix and send modifyGrid operation
    public method adjustItem { param }

    public method setNode { index status }

    ### major operation:
    ###   translate:     from orignal to pixel
    ###   saveItemINfo:  from pixel to original
    ###   rezoom:        part of translate, only used when snapshot image
    ###                  got digitally scaled, not caused by shape change or
    ###                  view change.
    protected method translate { {onlyZoom 0} }
    protected method rezoom { }
    protected method saveItemInfo { }

    ## this is generate grid from shape and its center, fill m_nodeList
    protected method generateGridMatrix { }
    ## this is draw matrix according to m_nodeList and matrix position and size
    ## this does not re-calculate the matrix center from its shape
    protected method rebornGridMatrix { }
    protected method redrawGridMatrix { }
    protected method redrawContour { }

    protected method _draw { }

    protected method nodeStatus2Attributes { status }

    #### update are reverse of save, update are part of translate.
    protected method updateShape { {onlyZoom 0} }
    protected method updateCornerAndRotor { {onlyZoom 0} }
    protected method updateLocalCoords { {onlyZoom 0} }
    protected method updateGrid { {onlyZoom 0} }

    ### save are part of saveItemInfo
    # saveShape 
    # saveSize (this is not part of saveItemInfo and normally called
    #           immediately after the size is available or changed.
    #           It causes unnecessary calculation if you put in in
    #           SaveItemInfo during the rotation.
    # saveLocalCoords
    # saveMatrix
    protected method saveShape { } {
        #puts "saveShape center pixel: $m_centerX $m_centerY"
        set displayOrig [$m_holder getDisplayOrig]

        foreach {m_uCenterX m_uCenterY} \
        [$m_holder pixel2micron \
        $m_centerX $m_centerY] break
        #puts "saveShape center micron: $m_uCenterX $m_uCenterY"

        foreach {m_oCenterX m_oCenterY} [reverseProjection \
        $m_uCenterX $m_uCenterY $displayOrig $m_oOrig] break
        #puts "saveShape center orig: $m_oCenterX $m_oCenterY"

        if {$displayOrig != $m_oOrig} {
            #puts "saveShape oOrig=$m_oOrig display=$displayOrig"
        }
    }
    protected method saveMatrix { } {
        set displayOrig [$m_holder getDisplayOrig]

        foreach {m_uGridCenterX m_uGridCenterY m_uCellWidth m_uCellHeight} \
        [$m_holder pixel2micron \
        $m_gridCenterX $m_gridCenterY $m_cellWidth $m_cellHeight] break

        foreach {m_oGridCenterX m_oGridCenterY} [reverseProjection \
        $m_uGridCenterX $m_uGridCenterY $displayOrig $m_oOrig] break
    
        foreach {m_oCellWidth m_oCellHeight} [reverseProjectionBox \
        $m_uCellWidth $m_uCellHeight $displayOrig $m_oOrig] break

        set m_oCellWidth  [expr abs($m_oCellWidth)]
        set m_oCellHeight [expr abs($m_oCellHeight)]
        set m_uCellWidth  [expr abs($m_uCellWidth)]
        set m_uCellHeight [expr abs($m_uCellHeight)]
    }
    protected method saveLocalCoords { } {
        #puts "saveLocalCoords for $this: $m_localCoords"
        set displayOrig [$m_holder getDisplayOrig]

        set m_uLocalCoords [eval $m_holder pixel2micron $m_localCoords]
        #puts "uuuu: $m_uLocalCoords"

        #puts "uCentr: $m_uCenterX $m_uCenterY oCenter: $m_oCenterX $m_oCenterY"
        #puts "angle=$m_oAngle"

        set uCoords ""
        foreach {x y} $m_uLocalCoords {
            set ux [expr $x + $m_uCenterX]
            set uy [expr $y + $m_uCenterY]
            lappend uCoords $ux $uy
        }
        set oCoords [reverseProjectionCoords $uCoords $displayOrig $m_oOrig]
        set m_oLocalCoords ""

        set a [expr -1 * $m_oAngle]
        foreach {x y} $oCoords {
            foreach {dx dy} [rotateCalculationToDelta \
            $m_oCenterX $m_oCenterY $a $x $y] break

            lappend m_oLocalCoords $dx $dy
        }
        #puts "oooo: $m_oLocalCoords"
    }

    ## used in creation or stretch
    protected method saveSize { width height } {
        set displayOrig [$m_holder getDisplayOrig]

        foreach {uW uH} [$m_holder pixel2micron $width $height] break

        foreach {oX oY} \
        [reverseProjectionBox $uW $uH $displayOrig $m_oOrig] break

        foreach {oW oH} [rotateDeltaToDelta \
        0 0 [expr -1 * $m_oAngle] $oX $oY] break

        set m_oHalfWidth  [expr abs($oW / 2.0)]
        set m_oHalfHeight [expr abs($oH / 2.0)]
    }

    protected method showHotSpots { }
    protected method removeHotSpots { }
    protected method drawVertex { index x y {cursor sizing} }

    ### help functions
    protected method noResponse { {relax_ 0} } {
        if {!$relax_ && $m_mode != "adjustable"} {
            #puts "calling bodyPress  for non-adjustable"
            return 1
        }
        switch -exact -- $m_status {
            grouped -
            silent {
                return 1
            }
        }
        return 0
    }

    ### rotation
    public method rotorPress { xw yw }
    public method rotorMotion { x y }
    public method rotorRelease { x y } {
        $m_holder onItemChange $this
    }
    public method rotorEnter { x y }

    protected method setItemStatus { s }
    protected method drawOutline { }
    protected method drawAllVertices { }
    protected method drawRotor { }

    protected method removeAllGui { } {
        if {$m_guiId != ""} {
            $m_canvas delete $m_guiId
            $m_canvas delete hotspot_$m_guiId
            $m_canvas delete grid_$m_guiId
            $m_canvas delete item_$m_guiId

            set m_guiId ""
        }
    }

    protected method getClickInfo { x y }

    protected method contourSetup { }

    ######
    protected method calculateMatrixCenter { } {
        switch -exact -- [getShape] {
            polygon {
                #### this is generic, works on all shapes.
                set box [getBBox]
                if {[llength $box] < 4} {
                    puts "raster not ready, no bbox"
                    return ""
                }
                foreach {bx1 by1 bx2 by2} $box break

                set centerX [expr ($bx2 + $bx1) / 2.0]
                set centerY [expr ($by2 + $by1) / 2.0]
            }
            default {
                set centerX $m_centerX
                set centerY $m_centerY
            }
        }
        return [list $centerX $centerY]
    }

    protected method getNumberDisplayList { }
    protected method getContourDisplayList { }
    protected method getNumberDisplayValue { index node }
    protected method getContourDisplayValue { node }
    protected method getContourLevels { }

    public variable cursorBody fleur

    private common RASTER_NUM 1
    protected variable m_itemId ""

    protected variable m_canvas ""
    protected variable m_guiId ""
    protected variable m_mode NA
    ### template: for creation
    ### adjustable:
    ### frozen:     no more adjust
    protected variable m_status normal
    protected variable m_oldStatus normal
    # selected: draw hotspots
    # grouped:  for now, no response to any event, like silent
    # normal:   no hotspot but response to Enter, Button-1
    # silent:   no response

    protected variable m_pressX 0
    protected variable m_pressY 0
    protected variable m_pressRow -1
    protected variable m_pressCol -1
    protected variable m_indexVertex -1
    protected variable m_holder ""

    protected variable m_oOrig "0 0 0 0 0.75 1.0 1 1 0.5 0.5"
    ### These are from original.  They need translate when
    ### the holder view point changes.
    ### most of their units are microns.
    protected variable m_oCenterX 500.0
    protected variable m_oCenterY 500.0
    ### units radian: shape rotate in original frame.
    protected variable m_oAngle 0
    ### on local unrotated frame.
    protected variable m_oHalfWidth 100.0
    protected variable m_oHalfHeight 100.0
    protected variable m_oLocalCoords ""

    protected variable m_oGridCenterX 500.0
    protected variable m_oGridCenterY 500.0
    ### these are always horz and vert to the displayView
    protected variable m_oCellWidth 50.0
    protected variable m_oCellHeight 50.0

    ### in displayView with micron as units.
    ### Image zoom will use them, no need to recalculate from original.
    protected variable m_uCenterX 500.0
    protected variable m_uCenterY 500.0
    #### no halfWidth halfHeight here.  They only make sense in original
    #### non-rotated local frame.

    ### this m_uLocalCoords already counted in the rotation.
    ### Its frame is parallel to the display, centered at the m_uCenterX/Y.
    protected variable m_uLocalCoords ""
    protected variable m_uCorner \
    "400.0 400.0 600.0 400.0 600.0 600.0 400.0 600.0"

    protected variable m_uGridCenterX 500.0
    protected variable m_uGridCenterY 500.0
    protected variable m_uCellWidth   50.0
    protected variable m_uCellHeight  50.0

    ## in pixels.
    protected variable m_centerX 100
    protected variable m_centerY 200
    protected variable m_corner "50 150 150 150 150 250 50 250"
    protected variable m_rotor "100 150 100 50"

    ### on local frame just centered at m_centerX/Y.
    protected variable m_localCoords ""

    #protected variable m_gridSequenceType horz
    protected variable m_gridSequenceType vert
    protected variable m_gridCenterX 100
    protected variable m_gridCenterY 100
    protected variable m_numRow 1
    protected variable m_numCol 1
    protected variable m_cellWidth 10
    protected variable m_cellHeight 10
    protected variable m_nodeList ""
    protected variable m_frameNumList ""

    ###outline
    protected variable m_theOtherCornerX 0
    protected variable m_theOtherCornerY 0

    ### group or rectangle does not need outline
    protected variable m_showOutline 1
    ### group does not show vertex
    protected variable m_showVertexAndMatrix 1
    protected variable m_showRotor 1
    protected variable m_gridOnTopOfBody 0
    protected variable m_nodeLabelList ""

    protected variable m_motionCalled 0
    protected variable m_newCurrentItem 0

    ### C++ class for contour
    protected variable m_obj
    protected variable m_contour

    protected common s_displayFieldMaster ""

    constructor { canvas id mode holder } {
        #puts "base constructor"
        set m_itemId $RASTER_NUM
        incr RASTER_NUM

        set m_canvas $canvas
        set m_guiId $id
        set m_mode $mode
        set m_holder $holder
        set m_oOrig [$m_holder getDisplayOrig]
        set m_oCellWidth  [gCurrentGridGroup getDefaultCellWidth]
        set m_oCellHeight [gCurrentGridGroup getDefaultCellHeight]

        set m_obj [createNewDcsScan2DData]

        updateGrid
    }

    destructor {
        #puts "base destructor of $this"
        #delete the command
        rename $m_obj {}
        removeAllGui
    }
}
body GridItemBase::getClickInfo { x y } {
    if {$m_cellHeight <= 0 || $m_cellWidth <= 0} {
        return ""
    }
    set gridWidth  [expr $m_numCol * $m_cellWidth]
    set gridHeight [expr $m_numRow * $m_cellHeight]

    set x0 [expr $m_gridCenterX - $gridWidth  / 2.0]
    set y0 [expr $m_gridCenterY - $gridHeight / 2.0]
    set x1 [expr $m_gridCenterX + $gridWidth  / 2.0]
    set y1 [expr $m_gridCenterY + $gridHeight / 2.0]
    if {$x < $x0 || $x >= $x1 || $y < $y0 || $y >= $y1} {
        puts "click $x $y out of grid $x0 $y0 $x1 $y1"
        return ""
    }
    set localX [expr $x - $m_gridCenterX]
    set localY [expr $y - $m_gridCenterY]

    foreach {ux uy} [$m_holder pixel2micron $localX $localY] break

    set column [expr int($localX / $m_cellWidth  + $m_numCol / 2.0)]
    set row    [expr int($localY / $m_cellHeight + $m_numRow / 2.0)]

    return [list $row $column $ux $uy]
}
body GridItemBase::contourSetup { } {
    set w [expr $m_numCol - 1]
    set h [expr $m_numRow - 1]

    set x0 [expr -0.5 * $w]
    set y0 [expr -0.5 * $h]

    $m_obj setup $m_numRow $y0 1.0 $m_numCol $x0 1.0
    $m_obj setNodeSize $m_cellWidth $m_cellHeight
}
body GridItemBase::setItemStatus { s } {
    if {$s == "unsilent"} {
        if {$m_status != "silent"} {
            puts "DEBUG: unsilent called on not-silent: $m_status"
            return
        }
        set newS $m_oldStatus
    } else {
        set newS $s
        if {$m_status != "silent"} {
            set m_oldStatus $m_status
        }
    }
    if {$newS == $m_status} {
        return
    }
    set m_status $newS
    #puts "new status: $m_status for $this"
    if {![shouldDisplay]} {
        removeAllGui
    } else {
        if {$m_guiId == ""} {
            _draw
        }
        redrawHotSpots 0
    }
}
body GridItemBase::redrawHotSpots { fromGUI } {
    if {$m_guiId == ""} {
        return
    }

    if {$m_showVertexAndMatrix} {
        if {$fromGUI} {
            generateGridMatrix
        } else {
            rebornGridMatrix
        }
    }

    switch -exact -- [getShape] {
        line {
            set att fill
        }
        default {
            set att outline
        }
    }

    removeHotSpots
    switch -exact -- $m_status {
        selected {
            set color $GridGroupColor::COLOR_SHAPE_CURRENT
            $m_canvas itemconfigure $m_guiId -$att $color
            if {$m_mode == "adjustable"} {
                showHotSpots
            }
        }
        normal -
        silent -
        grouped -
        default {
            set color $GridGroupColor::COLOR_SHAPE
            $m_canvas itemconfigure $m_guiId -$att $color
        }
    }
}
## 4 corners with rotation
body GridItemBase::updateCornerAndRotor { {onlyZoom 0} } {
    if {!$onlyZoom} {
        set displayOrig [$m_holder getDisplayOrig]
        set oCorner ""

        set m_oHalfWidth  [expr abs($m_oHalfWidth)]
        set m_oHalfHeight [expr abs($m_oHalfHeight)]

        foreach {x y} [list \
        -$m_oHalfWidth -$m_oHalfHeight \
         $m_oHalfWidth -$m_oHalfHeight \
         $m_oHalfWidth  $m_oHalfHeight \
        -$m_oHalfWidth  $m_oHalfHeight \
        ] {
            foreach {ox oy} \
            [rotateDelta $m_oCenterX $m_oCenterY $m_oAngle $x $y] break
            lappend oCorner $ox $oy
        }
        set m_uCorner [translateProjectionCoords $oCorner $m_oOrig $displayOrig]
    }

    set m_corner [eval $m_holder micron2pixel $m_uCorner]
    ### calculate rotor
    foreach {x0 y0 x1 y1 x2 y2 x3 y3} $m_corner break
    set rot0X [expr ($x0 + $x1) / 2.0]
    set rot0Y [expr ($y0 + $y1) / 2.0]
    set dx [expr $x1 - $x2]
    set dy [expr $y1 - $y2]

    set ll [expr sqrt($dx * $dx + $dy * $dy * 1.0)]
    if {$ll > 0} {
        set rotDx [expr $dx * 15.0 / $ll]
        set rotDy [expr $dy * 15.0 / $ll]
    } else {
        set rotDx 0
        set rotDy 0
    }
    set rot1X [expr $rot0X + $rotDx]
    set rot1Y [expr $rot0Y + $rotDy]
    set m_rotor [list $rot0X $rot0Y $rot1X $rot1Y]
}
body GridItemBase::cornerPress { index x y } {
    set otherIndex [expr ($index + 2) % 4]
    set xIndex [expr $otherIndex * 2]
    set yIndex [expr $xIndex + 1]

    set m_theOtherCornerX [lindex $m_corner $xIndex]
    set m_theOtherCornerY [lindex $m_corner $yIndex]

    #puts "cornerPress at $index $x $y"
    #puts "the other is at $xIndex $m_theOtherCornerX $m_theOtherCornerY"
}
body GridItemBase::cornerMotion { x y } {
    ### should only be called when no rotation between display and orig view.
    #puts "cornerMotion at $x $y"

    set m_centerX [expr ($x + $m_theOtherCornerX) / 2.0]
    set m_centerY [expr ($y + $m_theOtherCornerY) / 2.0]
    saveShape
    saveSize \
    [expr $m_theOtherCornerX - $x] \
    [expr $m_theOtherCornerY - $y]

    updateCornerAndRotor
}

body GridItemBase::createPress { x y } {
    #puts "createPREss $x $y"
    if {$m_mode != "template"} {
        puts "calling createPress  for non-template"
        return
    }
    set m_pressX $x
    set m_pressY $y

    $m_holder clearCurrentItem

    $m_holder registerButtonCallback "$this createMotion" "$this createRelease"
}
body GridItemBase::vertexPress { index xw yw } {
    if {[noResponse]} {
        return
    }

    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]
    set m_pressX $x
    set m_pressY $y
    set m_indexVertex $index

    $m_holder registerButtonCallback "$this vertexMotion" "$this vertexRelease"
}
body GridItemBase::vertexEnter { index xw yw cursor } {
    if {[noResponse]} {
        return
    }
    $m_canvas configure \
    -cursor $cursor
}
body GridItemBase::bodyPress { xw yw } {
    puts "base bodyPRess for $this"
    set m_motionCalled 0

    ### we want to allow flip.
    if {[noResponse 1]} {
        return
    }
    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]
    set m_pressX $x
    set m_pressY $y

    #$m_holder clearHotspot
    #$m_holder clearGroup
    #showHotSpots

    ### from user click, fire the event
    set m_newCurrentItem [$m_holder setCurrentItem $this]

    $m_holder registerButtonCallback "$this bodyMotion" "$this bodyRelease"
}
body GridItemBase::gridPress { row col xw yw } {
    puts "$this gridPress $row $col"
    set m_motionCalled 0

    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]
    set m_pressX $x
    set m_pressY $y
    set m_pressRow $row
    set m_pressCol $col

    #$m_holder clearHotspot
    #$m_holder clearGroup
    #showHotSpots

    ### from user click, fire the event
    set m_newCurrentItem [$m_holder setCurrentItem $this]

    $m_holder registerButtonCallback "$this bodyMotion" "$this gridRelease"
}
body GridItemBase::enter { } {
    if {[noResponse]} {
        return
    }
    $m_canvas configure -cursor $cursorBody
}
body GridItemBase::drawVertex { index x y {cursor sizing}} {
    set x0 [expr $x - 5]
    set y0 [expr $y - 5]
    set x1 [expr $x + 5]
    set y1 [expr $y + 5]

    set id1 [$m_canvas create line $x0 $y $x1 $y \
    -tags [list hotspot hotspot_$m_guiId] \
    -fill $GridGroupColor::COLOR_VERTEX \
    -width 3]

    set id2 [$m_canvas create line $x $y0 $x $y1 \
    -tags [list hotspot hotspot_$m_guiId] \
    -fill $GridGroupColor::COLOR_VERTEX \
    -width 3]

    $m_canvas bind $id1 <Button-1>  "$this vertexPress $index %x %y"
    $m_canvas bind $id2 <Button-1>  "$this vertexPress $index %x %y"
    $m_canvas bind $id1 <Enter>     "$this vertexEnter $index %x %y $cursor"
    $m_canvas bind $id2 <Enter>     "$this vertexEnter $index %x %y $cursor"
}
body GridItemBase::bodyMotion { x y } {
    if {[noResponse]} {
        return
    }
    set firstTime 0
    if {!$m_motionCalled} {
        set firstTime 1
    }
    set m_motionCalled 1
    # change it to use redraw if one item one id pattern is broken
    set dx [expr $x - $m_pressX]
    set dy [expr $y - $m_pressY]
    $m_canvas move $m_guiId $dx $dy
    $m_canvas move hotspot_$m_guiId $dx $dy
    $m_canvas move grid_$m_guiId $dx $dy
    set m_centerX [expr $m_centerX + $dx]
    set m_centerY [expr $m_centerY + $dy]
    set m_gridCenterX [expr $m_gridCenterX + $dx]
    set m_gridCenterY [expr $m_gridCenterY + $dy]

    saveItemInfo
    updateCornerAndRotor

    set m_pressX $x
    set m_pressY $y

    if {$firstTime && $m_showVertexAndMatrix} {
        generateGridMatrix
    }
}
body GridItemBase::drawOutline { } {
    set coords [getCorners]
    ### close the loop
    foreach {x0 y0} $coords break
    set outlineCoords $coords
    lappend outlineCoords $x0 $y0

    $m_canvas create line $outlineCoords \
    -width 1 \
    -fill $GridGroupColor::COLOR_OUTLINE \
    -dash . \
    -tags [list hotspot hotspot_$m_guiId]
}
body GridItemBase::drawAllVertices { } {
    set vList [$m_canvas coords $m_guiId]
    set index -1
    foreach {x y} $vList {
        incr index
        drawVertex $index $x $y
    }
}
body GridItemBase::showHotSpots { } {
    #puts "show my vertices $this"
    if {$m_showOutline} {
        drawOutline
    }
    if {$m_showVertexAndMatrix} {
        drawAllVertices
    }

    if {$m_showRotor} {
        drawRotor
    }
    $m_canvas raise beam_info
}
body GridItemBase::drawRotor { } {
    foreach {x0 y0 x1 y1} $m_rotor break

    $m_canvas create line $x0 $y0 $x1 $y1 \
    -tags [list hotspot hotspot_$m_guiId] \
    -fill $GridGroupColor::COLOR_ROTOR

    set RR 5

    set rx0 [expr $x1 - $RR]
    set ry0 [expr $y1 - $RR]
    set rx1 [expr $x1 + $RR]
    set ry1 [expr $y1 + $RR]

    set id [$m_canvas create oval $rx0 $ry0 $rx1 $ry1 \
    -outline $GridGroupColor::COLOR_ROTOR \
    -fill $GridGroupColor::COLOR_ROTOR \
    -tags [list hotspot hotspot_$m_guiId] \
    ]

    $m_canvas bind $id <Button-1> "$this rotorPress %x %y"
    $m_canvas bind $id <Enter> "$this rotorEnter %x %y"
}
body GridItemBase::nodeStatus2Attributes { status } {
    set stipple ""
    set fill ""
    switch -exact -- $status {
        - -
        -- {
            ### the node not exists
            return ""
        }
        S {
        }
        N -
        NA -
        NEW {
            set fill $GridGroupColor::COLOR_UNSELECTED
            set stipple gray50
        }
        X {
            if {$m_mode != "done"} {
                set fill $GridGroupColor::COLOR_EXPOSING
            }
        }
        D {
            if {$m_mode != "done"} {
                set fill $GridGroupColor::COLOR_DONE
            }
        }
        default {
        }
    }
    return [list $fill $stipple]
}
body GridItemBase::rebornGridMatrix { } {
    #puts "rebornGridMatrix: center: $m_gridCenterX $m_gridCenterY"
    #puts "geo center: $m_centerX $m_centerY"

    foreach {cx cy} [calculateMatrixCenter] break
    if {abs($cx - $m_gridCenterX) > 5 || abs($cy - $m_gridCenterY) > 5} {
        log_error grid lost sync with geo shape
        log_error shape=[getShape], geoCenter: $m_centerX $m_centerY \
        grid center: $m_gridCenterX $m_gridCenterY != $cx $cy

        if {$m_status == "adjustable"} {
            generateGridMatrix
        }
        return
    }

    contourSetup
    redrawGridMatrix
}
body GridItemBase::redrawGridMatrix { } {
    set nodeColorList [getContourDisplayList]
    $m_obj setValues $nodeColorList

    set nodeLabelList [getNumberDisplayList]
    set font_sizeW [expr int(0.33 * $m_cellWidth)]
    set font_sizeH [expr int(0.33 * $m_cellHeight)]
    set font_size [expr ($font_sizeW > $font_sizeH)?$font_sizeH:$font_sizeW]
    if {$font_size > 16} {
        set font_size 16
    }

    $m_canvas delete grid_$m_guiId
    set gridWidth  [expr $m_numCol * $m_cellWidth]
    set gridHeight [expr $m_numRow * $m_cellHeight]
    set x0 [expr $m_gridCenterX - $gridWidth  / 2.0]
    set y0 [expr $m_gridCenterY - $gridHeight / 2.0]

    #puts "point0: $x0 $y0"
    set xList ""
    for {set col 0} {$col < $m_numCol + 1} {incr col} {
        set x [expr $x0 + $col * $m_cellWidth]
        lappend xList $x
    }
    set yList ""
    for {set row 0} {$row < $m_numRow + 1} {incr row} {
        set y [expr $y0 + $row * $m_cellHeight]
        lappend yList $y
    }
    
    for {set row 0} {$row < $m_numRow} {incr row} {
        set y1 [lindex $yList $row]
        set y2 [lindex $yList [expr $row + 1]]
        for {set col 0} {$col < $m_numCol} {incr col} {
            set x1 [lindex $xList $col]
            set x2 [lindex $xList [expr $col + 1]]
            set index [expr $row * $m_numCol + $col]
            set nodeStatus [lindex $nodeColorList $index]
            set nodeLabel  [lindex $nodeLabelList $index]
            set color [$m_obj getColor $row $col]
            if {$color >= 0} {
                set fill [format "\#%02x%02x%02x" $color $color $color]
                set stipple ""
            } else {
                set nodeAttrs [nodeStatus2Attributes $nodeStatus]
                if {$nodeAttrs == ""} {
                    continue
                }
                foreach {fill stipple} $nodeAttrs break
            }

            $m_canvas create polygon $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 \
            -outline $GridGroupColor::COLOR_GRID \
            -fill $fill \
            -stipple $stipple \
            -tags \
            [list grid grid_$m_guiId item_$m_guiId node_${m_guiId}_${index}]

            set tx [expr ($x1 + $x2) / 2.0]
            set ty [expr ($y1 + $y2) / 2.0]
            $m_canvas create text $tx $ty \
            -text $nodeLabel \
            -font "-family courier -size $font_size" \
            -fill $GridGroupColor::COLOR_VALUE \
            -anchor c \
            -justify center \
            -tags \
            [list grid grid_$m_guiId \
            item_$m_guiId nodeLabel_${m_guiId}_${index}]
        }
    }

    redrawContour

    $m_canvas raise $m_guiId
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info
}
body GridItemBase::redrawContour { } {
    $m_canvas delete contour_$m_guiId
    if {$m_mode != "done"} {
        return
    }
    set gridWidth  [expr $m_numCol * $m_cellWidth]
    set gridHeight [expr $m_numRow * $m_cellHeight]
    set x0 [expr $m_gridCenterX - $gridWidth  / 2.0]
    set y0 [expr $m_gridCenterY - $gridHeight / 2.0]

    $m_obj setAllData
    foreach level [getContourLevels] {
        set color [getColorFromContourLevel $level]
        if {[$m_obj getContour [expr $level / 100.0]] > 0} {
            foreach segment [array names m_contour] {
                set xyList $m_contour($segment)
                if {[catch {
                    displacement xyList $x0 $y0
                    $m_canvas create line $xyList \
                    -fill $color \
                    -width 2 \
                    -tags [list grid grid_$m_guiId item_$m_guiId \
                    contour contour_$m_guiId]
                } errMsg]} {
                    puts "segment $segment failed: $errMsg"
                    puts "list={$xyList}"
                }
            }
        }
    }
    $m_canvas raise $m_guiId
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info
}
body GridItemBase::generateGridMatrix { } {
    #puts "generateGridMatrix for $this"
    set m_nodeList ""
    $m_canvas delete grid_$m_guiId

    if {$m_cellWidth <= 0 || $m_cellHeight <= 0} {
        puts "cell size = 0"
        return
    }
    set box [getBBox]
    if {[llength $box] < 4} {
        puts "raster not ready, no bbox"
        return
    }
    foreach {bx1 by1 bx2 by2} $box break

    set m_gridCenterX [expr ($bx2 + $bx1) / 2.0]
    set m_gridCenterY [expr ($by2 + $by1) / 2.0]

    #puts "geo center: $m_centerX $m_centerY"
    #puts "grid center: $m_gridCenterX $m_gridCenterY"

    set gridWidth   [expr ($bx2 - $bx1) * 1.0]
    set gridHeight  [expr ($by2 - $by1) * 1.0]
    if {$gridWidth <= 0 || $gridHeight <= 0} {
        puts "raster not ready, box size=0"
        return
    }

    #puts "cell size: $m_cellWidth X $m_cellHeight"
    #puts "box $box"

    set m_numCol [expr int(ceil($gridWidth  / $m_cellWidth))]
    set m_numRow [expr int(ceil($gridHeight / $m_cellHeight))]

    #puts "num col: $m_numCol row: $m_numRow"

    set gridWidth  [expr $m_numCol * $m_cellWidth]
    set gridHeight [expr $m_numRow * $m_cellHeight]
    
    set x0 [expr $m_gridCenterX - $gridWidth  / 2.0]
    set y0 [expr $m_gridCenterY - $gridHeight / 2.0]
    #puts "x0=$x0 y0=$y0"

    set xList ""
    for {set col 0} {$col < $m_numCol + 1} {incr col} {
        set x [expr $x0 + $col * $m_cellWidth]
        lappend xList $x
    }
    set yList ""
    for {set row 0} {$row < $m_numRow + 1} {incr row} {
        set y [expr $y0 + $row * $m_cellHeight]
        lappend yList $y
    }
    
    for {set row 0} {$row < $m_numRow} {incr row} {
        set y1 [lindex $yList $row]
        set y2 [lindex $yList [expr $row + 1]]
        for {set col 0} {$col < $m_numCol} {incr col} {
            set x1 [lindex $xList $col]
            set x2 [lindex $xList [expr $col + 1]]
            set matchList [$m_canvas find overlapping $x1 $y1 $x2 $y2]
            if {[lsearch -exact $matchList $m_guiId] >= 0} {
                $m_canvas create polygon $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 \
                -outline $GridGroupColor::COLOR_GRID \
                -fill "" \
                -tags [list grid grid_$m_guiId item_$m_guiId]
                lappend m_nodeList S
            } else {
                ### yaml cannot handle "-"
                lappend m_nodeList --
            }
        }
    }
    saveItemInfo
    #puts "grid relative center: $m_uGridCenterX $m_uGridCenterY"

    $m_canvas raise $m_guiId
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info

    contourSetup
}
body GridItemBase::removeHotSpots { } {
    $m_canvas delete hotspot_$m_guiId
}
body GridItemBase::rotorEnter { xw yw } {
    if {[noResponse]} {
        return
    }
    $m_canvas configure \
    -cursor target
}
body GridItemBase::rotorPress { xw yw } {
    if {$m_mode != "adjustable"} {
        return
    }
    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]

    set m_pressX $x
    set m_pressY $y

    $m_holder registerButtonCallback "$this rotorMotion" "$this rotorRelease"
}
body GridItemBase::rotorMotion { x y } {
    if {$m_mode != "adjustable"} {
        return
    }
    set displayOrig [$m_holder getDisplayOrig]
    foreach {ux uy} [$m_holder pixel2micron $x $y] break
    foreach {ox oy} [reverseProjection $ux $uy $displayOrig $m_oOrig] break

    ## in item frame:
    set dx [expr $ox - $m_oCenterX]
    set dy [expr $oy - $m_oCenterY]
    if {$dx == 0 && $dy == 0} {
        return
    }

    set rc [rotateDelta 0 0 [expr -1 * $m_oAngle] $dx $dy]
    foreach {rx ry} $rc break
    ### rotor is located -90 degree
    set aa [expr atan2($ry, $rx)]

    set angle [expr $aa + 3.1415926 / 2.0]

    ### already in radians
    rotate $angle 1
}
body GridItemBase::getCenter { } {
    ### need fraction of the display.
    foreach {x y z o hh ww} $m_oOrig break
    set x [expr 0.001 * $m_uGridCenterX / $ww]
    set y [expr 0.001 * $m_uGridCenterY / $hh]
    return [list $x $y]
}
## we want to avoid the extra pixels
body GridItemBase::getBBox { } {
    set xmin 9e99
    set ymin 9e99
    set xmax -9e99
    set ymax -9e99

    foreach {x y} [$m_canvas coords $m_guiId] {
        if {$xmin > $x} {
            set xmin $x
        }
        if {$xmax < $x} {
            set xmax $x
        }
        if {$ymin > $y} {
            set ymin $y
        }
        if {$ymax < $y} {
            set ymax $y
        }
    }
    return [list $xmin $ymin $xmax $ymax]
}
body GridItemBase::getItemInfo { } {
    set displayOrig [$m_holder getDisplayOrig]
    set displayAngle  [lindex $displayOrig 3]
    set originalAngle [lindex $m_oOrig 3]
    set geoList ""
    lappend geoList shape           [getShape] 
    lappend geoList angle           $m_oAngle
    lappend geoList half_width      $m_oHalfWidth
    lappend geoList half_height     $m_oHalfHeight
    lappend geoList local_coords    $m_oLocalCoords
    set gridList ""

    #### here is the default sequenc type:
    lappend gridList type           $m_gridSequenceType
    lappend gridList num_row        $m_numRow
    lappend gridList num_column     $m_numCol
    if {$m_nodeLabelList != ""} {
        lappend gridList node_label_list $m_nodeLabelList
    }
    if {abs($displayAngle - $originalAngle) < 1} {
        ### use new, display view and orig

        set orig $displayOrig

        lappend geoList center_x        $m_uCenterX
        lappend geoList center_y        $m_uCenterY

        lappend gridList center_x       $m_uGridCenterX
        lappend gridList center_y       $m_uGridCenterY
        lappend gridList cell_width     $m_uCellWidth
        lappend gridList cell_height    $m_uCellHeight
    } else {
        ### use original view and orig

        set orig $m_oOrig

        lappend geoList center_x        $m_oCenterX
        lappend geoList center_y        $m_oCenterY

        lappend gridList center_x       $m_oGridCenterX
        lappend gridList center_y       $m_oGridCenterY
        lappend gridList cell_width     $m_oCellWidth
        lappend gridList cell_height    $m_oCellHeight
    }
    return [list $orig $geoList $gridList $m_nodeList]
}
body GridItemBase::reborn { gridId fromInfo } {
    removeAllGui
    set m_itemId $gridId

    updateFromInfo $fromInfo 0
}
body GridItemBase::updateFromInfo { info {redraw 1}} {
    foreach {orig geo grid node frame status} $info break

    set m_oOrig        $orig
    set m_oCenterX     [dict get $geo center_x]
    set m_oCenterY     [dict get $geo center_y]
    set m_oHalfWidth   [dict get $geo half_width]
    set m_oHalfHeight  [dict get $geo half_height]
    set m_oLocalCoords [dict get $geo local_coords]
    set m_oAngle       [dict get $geo angle]

    set m_oGridCenterX [dict get $grid center_x]
    set m_oGridCenterY [dict get $grid center_y]
    set m_oCellHeight  [dict get $grid cell_height]
    set m_oCellWidth   [dict get $grid cell_width]
    set m_numRow       [dict get $grid num_row]
    set m_numCol       [dict get $grid num_column]
    set m_gridSequenceType [dict get $grid type]

    set m_nodeList     $node
    set m_frameNumList ""
    foreach num $frame {
        if {$num < 0} {
            set v ""
        } else {
            set v [expr $num + 1]
        }
        lappend m_frameNumList $v
    }

    translate

    setMode $status 0

    if {$redraw} {
        redraw 0
    }
}
body GridItemBase::adjustItem { param } {
    set need 0
    dict for {key value} $param {
        switch -exact -- $key {
            cell_width {
                set m_oCellWidth $value
                set need 1
            }
            cell_height {
                set m_oCellHeight $value
                set need 1
            }
        }
    }
    if {$need} {
        updateGrid
        generateGridMatrix
        $m_holder onItemChange $this
    }
}
body GridItemBase::setNode { index status } {
    #puts "setNode for $this index=$index status=$status"
    set ll [llength $m_nodeList]
    if {$index < 0 || $index >= $ll} {
        puts "ERROR: setNode with index=$index out of range 0 - $ll"
        return
    }

    set nodeTag node_${m_guiId}_${index}
    set labelTag nodeLabel_${m_guiId}_${index}

    set m_nodeList [lreplace $m_nodeList $index $index $status]

    set contourValue [getContourDisplayValue $status]
    set labelValue   [getNumberDisplayValue $index $status]
    if {![string is double -strict $contourValue]} {
        set nodeAttrs [nodeStatus2Attributes $status]
        if {$nodeAttrs == ""} {
            $m_myCanvas delete $nodeTag
            $m_myCanvas delete $labelTag
            return
        }
        foreach {fill stipple} $nodeAttrs break
        $m_canvas itemconfigure $nodeTag \
        -fill $fill \
        -stipple $stipple

        $m_canvas itemconfigure $labelTag \
        -text $labelValue
        return
    }
    $m_canvas itemconfigure $labelTag \
    -text $labelValue \

    set result [$m_obj addDataByIndex $index $contourValue]
    if {!$result} {
        puts "$this setNode failed for index=$index status=$status"
        return
    }
    if {$result == -1} {
        redrawGridMatrix
        return
    }

    set row [expr $index / $m_numCol]
    set col [expr $index % $m_numCol]
    set color [$m_obj getColor $row $col]
    if {$color >= 0} {
        set fill [format "\#%02x%02x%02x" $color $color $color]
        set stipple ""
    } else {
        set nodeAttrs [nodeStatus2Attributes $status]
        if {$nodeAttrs == ""} {
            $m_myCanvas delete $nodeTag
            return
        }
        foreach {fill stipple} $nodeAttrs break
    }
    $m_canvas itemconfigure $nodeTag \
    -fill $fill \
    -stipple $stipple
}
body GridItemBase::updateShape { {onlyZoom 0} } {
    if {!$onlyZoom} {
        set displayOrig [$m_holder getDisplayOrig]

        foreach {m_uCenterX m_uCenterY} [translateProjection \
        $m_oCenterX $m_oCenterY $m_oOrig $displayOrig] break
    }

    foreach {m_centerX m_centerY} \
    [$m_holder micron2pixel \
    $m_uCenterX $m_uCenterY] break
}
body GridItemBase::updateLocalCoords { {onlyZoom 0} } {
    #puts "update local coords for $this o: $m_oLocalCoords"
    if {!$onlyZoom} {
        set displayOrig [$m_holder getDisplayOrig]

        set oCoords ""
        foreach {x y} $m_oLocalCoords {
            foreach {ox oy} \
            [rotateDelta $m_oCenterX $m_oCenterY $m_oAngle $x $y] break
            lappend oCoords $ox $oy
        }
        set uCoords [translateProjectionCoords $oCoords $m_oOrig $displayOrig]

        set m_uLocalCoords ""
        foreach {x y} $uCoords {
            set rx [expr $x - $m_uCenterX]
            set ry [expr $y - $m_uCenterY]
            lappend m_uLocalCoords $rx $ry
        }
    }
    set m_localCoords [eval $m_holder micron2pixel $m_uLocalCoords]
    #puts "pixel: $m_localCoords"
}
body GridItemBase::updateGrid { {onlyZoom 0} } {
    if {!$onlyZoom} {
        set displayOrig [$m_holder getDisplayOrig]

        foreach {m_uGridCenterX m_uGridCenterY} [translateProjection \
        $m_oGridCenterX $m_oGridCenterY $m_oOrig $displayOrig] break

        foreach {m_uCellWidth m_uCellHeight} [translateProjectionBox \
        $m_oCellWidth $m_oCellHeight $m_oOrig $displayOrig] break
    }

    foreach {m_gridCenterX m_gridCenterY m_cellWidth m_cellHeight} \
    [$m_holder micron2pixel \
    $m_uGridCenterX $m_uGridCenterY $m_uCellWidth $m_uCellHeight] break

    set m_cellWidth  [expr abs($m_cellWidth)]
    set m_cellHeight [expr abs($m_cellHeight)]
}

body GridItemBase::translate { {onlyZoom 0} } {
    updateShape $onlyZoom
    updateLocalCoords $onlyZoom
    updateCornerAndRotor $onlyZoom
    updateGrid $onlyZoom
}
body GridItemBase::rezoom { } {
    translate 1
}
body GridItemBase::saveItemInfo { } {
    saveShape
    saveLocalCoords
    saveMatrix
}
body GridItemBase::getNumberDisplayList { } {
    if {$s_displayFieldMaster == ""} {
        set fieldName Frame
    } else {
        set fieldName [$s_displayFieldMaster getNumberField]
    }

    switch -exact -- $fieldName {
        None {
            return ""
        }
        Frame {
            return $m_frameNumList
        }
    }
    set index [lsearch -exact $GridNodeListView::FIELD_NAME $fieldName]
    if {$index < 0} {
        log_error bad field_name $fieldName.
        return ""
    }
    set fIndex [lindex $GridNodeListView::FIELD_INDEX $index]
    set resultList ""
    foreach node $m_nodeList {
        set v [lindex $node $fIndex]
        if {[string is double -strict $v]} {
            lappend resultList $v
        } else {
            lappend resultList ""
        }
    }
    return $resultList
}
body GridItemBase::getContourDisplayList { } {
    if {$s_displayFieldMaster == ""} {
        set fieldName Spots
    } else {
        set fieldName [$s_displayFieldMaster getContourField]
    }
    switch -exact -- $fieldName {
        None {
            return ""
        }
    }
    set index [lsearch -exact $GridNodeListView::FIELD_NAME $fieldName]
    if {$index < 0} {
        log_error bad field_name for contour $fieldName.
        return ""
    }
    set fIndex [lindex $GridNodeListView::FIELD_INDEX $index]
    set resultList ""
    foreach node $m_nodeList {
        if {[llength $node] > $fIndex} {
            set v [lindex $node $fIndex]
        } else {
            set v [lindex $node 0]
        }
        lappend resultList $v
    }
    return $resultList
}
body GridItemBase::getContourLevels { } {
    if {$s_displayFieldMaster == ""} {
        return [list 10 25 50 75 90]
    } else {
        return [$s_displayFieldMaster getContourLevels]
    }
}
body GridItemBase::getContourDisplayValue { node } {
    if {$s_displayFieldMaster == ""} {
        set fieldName Spots
    } else {
        set fieldName [$s_displayFieldMaster getContourField]
    }
    switch -exact -- $fieldName {
        None {
            return ""
        }
    }
    set index [lsearch -exact $GridNodeListView::FIELD_NAME $fieldName]
    if {$index < 0} {
        log_error bad field_name for contour $fieldName.
        return ""
    }
    set fIndex [lindex $GridNodeListView::FIELD_INDEX $index]
    if {[llength $node] > $fIndex} {
        set v [lindex $node $fIndex]
    } else {
        set v [lindex $node 0]
    }
    return $v
}
body GridItemBase::getNumberDisplayValue { index node } {
    #puts "getNumberDisplayValue $index $node"

    if {$s_displayFieldMaster == ""} {
        set fieldName Frame
    } else {
        set fieldName [$s_displayFieldMaster getContourField]
    }
    switch -exact -- $fieldName {
        None {
            return ""
        }
        Frame {
            return [lindex $m_frameNumList $index]
        }
    }
    set index [lsearch -exact $GridNodeListView::FIELD_NAME $fieldName]
    if {$index < 0} {
        log_error bad field_name for contour $fieldName.
        return ""
    }
    set fIndex [lindex $GridNodeListView::FIELD_INDEX $index]
    if {[llength $node] > $fIndex} {
        set v [lindex $node $fIndex]
    } else {
        set v [lindex $node 0]
    }
    if {![string is double -strict $v]} {
        return ""
    }
    return $v
}
body GridItemBase::shouldDisplay { } {
    switch -exact -- [$m_holder cget -showItem] {
        all {
            return 1
        }
        selected_only {
            if {$m_status != "selected"} {
                return 0
            }
        }
    }

    ### check phi
    set displayOrig [$m_holder getDisplayOrig]

    set itemAngle    [lindex $m_oOrig 3]
    set displayAngle [lindex $displayOrig 3]

    set diff [expr abs($itemAngle - $displayAngle)]
    while {$diff >= 180} {
        set diff [expr $diff - 180]
    }
    if {$diff > 90} {
        set diff [expr 180 - $diff]
    }
    #puts "angle: $itemAngle $displayAngle diff=$diff"
    if {$diff < 1} {
        return 1
    }
    return 0
}

class GridItemRectangle {
    inherit GridItemBase

    proc create { c x y h }
    proc instantiate { c h gridId info }

    public method getShape { } {
        return "rectangle"
    }

    public method reborn { gridId info }

    public method redraw { fromGUI }

    ### for create
    public method createMotion { x y }
    public method createRelease { x y }

    ### selected
    public method vertexPress { index x y }
    public method vertexMotion { x y }

    protected method _draw { }

    constructor { canvas id mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        set m_showOutline 0
        #puts "rect constructor"
    }
}
body GridItemRectangle::create { c x y h } {
    #puts "enter create c=$c"
    set id [$c create polygon \
    $x $y $x $y $x $y $x $y \
    -width 1 \
    -outline $GridGroupColor::COLOR_RUBBERBAND \
    -fill "" \
    -dash . \
    -tags rubberband \
    ]

    #puts "rect id=$id"
    set item [GridItemRectangle ::#auto $c $id template $h]
    #puts "new item=$item"
    $item createPress $x $y
    return $item
}
body GridItemRectangle::createMotion { x y } {
    $m_canvas coords $m_guiId $m_pressX $m_pressY $x $m_pressY $x $y $m_pressX $y
}
body GridItemRectangle::createRelease { x y } {
    set m_mode adjustable

    $m_canvas coords $m_guiId $m_pressX $m_pressY $x $m_pressY $x $y $m_pressX $y
    $m_canvas itemconfig $m_guiId \
    -width 1 \
    -dash "" \
    -outline $GridGroupColor::COLOR_SHAPE_CURRENT \
    -fill "" \
    -tags [list raster item_$m_guiId]

    set m_centerX [expr ($m_pressX + $x) / 2.0]
    set m_centerY [expr ($m_pressY + $y) / 2.0]
    saveSize [expr $m_pressX - $x] [expr $m_pressY - $y]

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "rectange created: $m_guiId item=$this"
    #puts "coords [$m_canvas coords $m_guiId]"

    ## this will call saveItemInfo
    generateGridMatrix
    #updateCornerAndRotor

    $m_holder addItem $this
}
body GridItemRectangle::instantiate { c h gridId info } {
    #puts "enter rectangle instantiate"
    
    set item [GridItemRectangle ::#auto $c {} adjustable $h]
    $item reborn $gridId $info

    return $item
}
body GridItemRectangle::_draw { } {
    if {$m_guiId != ""} {
        puts "ERROR: _draw called for $this while m_guiId != {}"
        return
    }
    set coords [getCorners]
    set m_guiId [$m_canvas create polygon \
    $coords \
    -width 1 \
    -dash "" \
    -outline $GridGroupColor::COLOR_SHAPE \
    -fill "" \
    -tags raster \
    ]

    $m_canvas addtag item_$m_guiId withtag $m_guiId

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"
}
body GridItemRectangle::reborn { gridId info } {
    GridItemBase::reborn $gridId $info

    if {[shouldDisplay]} {
        _draw
    }

    $m_holder addItem $this 0
}
body GridItemRectangle::redraw { fromGUI } {
    if {!$fromGUI && ![shouldDisplay]} {
        removeAllGui
        return
    }
    if {$m_guiId == ""} {
        _draw
    } else {
        set coords [getCorners]
        $m_canvas coords $m_guiId $coords
    }

    redrawHotSpots $fromGUI
}
body GridItemRectangle::vertexPress { index x y } {
    #puts "vertexPress $index $x $y"
    GridItemBase::vertexPress $index $x $y
    cornerPress $index $x $y
}
body GridItemRectangle::vertexMotion { x y } {
    #puts "rectangleVertexMotion $x $y"

    cornerMotion $x $y
    redraw 1
}

class GridItemOval {
    inherit GridItemBase

    private method getOrigTrackPoint { theta }
    private method getTrackCoords { }

    private method updateTrackFromOrig { }

    proc create { c x y h }
    proc instantiate { c h gridId info } {
        set item [GridItemOval ::#auto $c {} {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }

    public method getShape { } {
        return "oval"
    }

    public method redraw { fromGUI } {
        if {!$fromGUI && ![shouldDisplay]} {
            removeAllGui
            return
        }
        if {$m_guiId == ""} {
            _draw
        } else {
            updateTrackFromOrig
            set coords [getTrackCoords]
            $m_canvas coords $m_guiId $coords
        }
        redrawHotSpots $fromGUI
    }
    public method reborn { gridId info }
    ### for create
    public method createMotion { x y }
    public method createRelease { x y }

    ### selected
    ##override so we only draw the 4 corners
    protected method drawAllVertices
    public method vertexPress { index x y }
    public method vertexMotion { x y }

    protected method _draw { }

    ### this is only used during creation
    private variable m_idExtra ""

    private common POLYGON_STEPS 32
    private common SPLINE 0

    ### we do not want to use m_xLocalCoord, because
    ### we do not want to save them or rotate them.
    private variable m_oTrackCoords ""
    private variable m_uTrackCoords ""
    private variable m_trackCoords ""

    constructor { canvas id id2 mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        #puts "oval constructor id=$id"
        set m_idExtra $id2
    }
}
## theta is angle from major axis
body GridItemOval::getOrigTrackPoint { theta } {
    set x [expr $m_oCenterX \
    + $m_oHalfWidth  * cos($theta) * cos($m_oAngle) \
    - $m_oHalfHeight * sin($theta) * sin($m_oAngle)]

    set y [expr $m_oCenterY \
    + $m_oHalfWidth  * cos($theta) * sin($m_oAngle) \
    + $m_oHalfHeight * sin($theta) * cos($m_oAngle)]

    return [list $x $y]
}
body GridItemOval::getTrackCoords { } {
    return $m_trackCoords
}
body GridItemOval::updateTrackFromOrig { } {
    #puts "updateTrackFromOrig"
    set m_oTrackCoords ""
    set stepSize [expr 2 * 3.1415926 / $POLYGON_STEPS]
    for {set i 0} {$i < $POLYGON_STEPS} {incr i} {
        set p [getOrigTrackPoint [expr $i * $stepSize]]
        eval lappend m_oTrackCoords $p
    }
    set displayOrig [$m_holder getDisplayOrig]
    set m_uTrackCoords \
    [translateProjectionCoords $m_oTrackCoords $m_oOrig $displayOrig]

    set m_trackCoords ""
    foreach {ux uy} $m_uTrackCoords {
        foreach {x y} [$m_holder micron2pixel $ux $uy] break
        lappend m_trackCoords $x $y
    }
}
body GridItemOval::create { c x y h } {
    set id [$c create oval $x $y $x $y \
    -width 1 \
    -outline $GridGroupColor::COLOR_RUBBERBAND \
    -dash . \
    -tags rubberband \
    ]

    set id2 [$c create rectangle $x $y $x $y \
    -width 1 \
    -outline $GridGroupColor::COLOR_OUTLINE \
    -dash . \
    -tags rubberband \
    ]
    set item [GridItemOval ::#auto $c $id $id2 template $h]
    #puts "new item=$item"
    $item createPress $x $y
    return $item
}
body GridItemOval::createMotion { x y } {
    #puts "oval create motion"
    $m_canvas coords $m_guiId $m_pressX $m_pressY $x $y
    $m_canvas coords $m_idExtra $m_pressX $m_pressY $x $y
}
body GridItemOval::createRelease { x y } {
    set m_mode adjustable

    set m_centerX [expr ($m_pressX + $x) / 2.0]
    set m_centerY [expr ($m_pressY + $y) / 2.0]
    saveItemInfo
    saveSize [expr $m_pressX - $x] [expr $m_pressY - $y]
    updateTrackFromOrig

    ### remove oval and use polygon to simulate
    $m_canvas delete $m_guiId
    set m_guiId [$m_canvas create polygon [getTrackCoords] \
    -width 1 \
    -smooth [expr $SPLINE > 0] \
    -splinesteps $SPLINE \
    -outline $GridGroupColor::COLOR_SHAPE_CURRENT \
    -fill "" \
    -tags raster ]

    $m_canvas addtag item_$m_guiId withtag $m_guiId

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "oval created: $m_guiId item=$this"

    $m_canvas delete $m_idExtra
    #puts "remove extra $m_idExtra"

    ## this will call saveItemInfo
    generateGridMatrix
    #updateCornerAndRotor

    $m_holder addItem $this
}
body GridItemOval::_draw { } {
    if {$m_guiId != ""} {
        puts "ERROR: _draw called for $this while m_guiId != {}"
        return
    }

    updateTrackFromOrig
    set m_guiId [$m_canvas create polygon [getTrackCoords] \
    -width 1 \
    -smooth [expr $SPLINE > 0] \
    -splinesteps $SPLINE \
    -outline $GridGroupColor::COLOR_SHAPE \
    -fill "" \
    -tags raster ]

    $m_canvas addtag item_$m_guiId withtag $m_guiId

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"
}
body GridItemOval::reborn { gridId info } {
    GridItemBase::reborn $gridId $info

    if {[shouldDisplay]} {
        _draw
    }

    #puts "oval reborn: $m_guiId item=$this"
    $m_holder addItem $this 0
}
body GridItemOval::drawAllVertices { } {
    set coords [getCorners]
    set index -1
    foreach {x y} $coords {
        incr index
        drawVertex $index $x $y
    }
}
body GridItemOval::vertexPress { index x y } {
    ### same as rectangle
    #puts "vertexPress $index $x $y"
    GridItemBase::vertexPress $index $x $y
    cornerPress $index $x $y
}
body GridItemOval::vertexMotion { x y } {
    ## the same as rectangle (again??)
    cornerMotion $x $y
    redraw 1
}

class GridItemLine {
    inherit GridItemBase

    proc create { c x y h }
    proc instantiate { c h gridId info } {
        set item [GridItemLine ::#auto $c {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }

    public method reborn { gridId info }

    public method getShape { } {
        return "line"
    }

    ### for create
    public method createMotion { x y }
    public method createRelease { x y }

    ### selected
    public method vertexMotion { x y }

    public method redraw { fromGUI }
    protected method _draw { }

    constructor { canvas id mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        #puts "line constructo"
    }
}
body GridItemLine::create { c x y h } {
    #puts "enter create c=$c"
    set id [$c create line \
    $x $y $x $y \
    -width 1 \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -dash . \
    -tags rubberband \
    ]

    #puts "line id=$id"
    set item [GridItemLine ::#auto $c $id template $h]
    #puts "new item=$item"
    $item createPress $x $y
    return $item
}
body GridItemLine::createMotion { x y } {
    $m_canvas coords $m_guiId $m_pressX $m_pressY $x $y
}
body GridItemLine::createRelease { x y } {
    set m_mode adjustable

    set m_centerX [expr ($m_pressX + $x) / 2.0]
    set m_centerY [expr ($m_pressY + $y) / 2.0]
    saveSize [expr $m_pressX - $x] [expr $m_pressY - $y]

    set m_oAngle 0
    set x1 [expr $m_pressX - $m_centerX]
    set y1 [expr $m_pressY - $m_centerY]
    set x2 [expr $x        - $m_centerX]
    set y2 [expr $y        - $m_centerY]
    set m_localCoords [list $x1 $y1 $x2 $y2]

    $m_canvas coords $m_guiId $m_pressX $m_pressY $x $y
    $m_canvas itemconfig $m_guiId \
    -width 3 \
    -fill $GridGroupColor::COLOR_SHAPE_CURRENT \
    -stipple gray50 \
    -dash "" \
    -tags [list raster item_$m_guiId]

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "line created: $m_guiId item=$this"
    #puts "1: $x1 $y1 2: $x2 $y2"

    generateGridMatrix
    #updateCornerAndRotor

    $m_holder addItem $this
}
body GridItemLine::vertexMotion { x y } {
    #puts "lineVertexMotion $x $y"
    set coords [$m_canvas coords $m_guiId]
    if {$m_indexVertex == 0} {
        set coords [lreplace $coords 0 1 $x $y]
    } else {
        set coords [lreplace $coords 2 3 $x $y]
    }
    $m_canvas coords $m_guiId $coords
    foreach {x1 y1 x2 y2} $coords break

    set m_centerX [expr ($x1 + $x2) / 2.0]
    set m_centerY [expr ($y1 + $y2) / 2.0]
    set m_oAngle 0
    saveShape
    saveSize [expr $x1 - $x2] [expr $y1 - $y2]
    updateCornerAndRotor

    set x1 [expr $x1 - $m_centerX]
    set y1 [expr $y1 - $m_centerY]
    set x2 [expr $x2 - $m_centerX]
    set y2 [expr $y2 - $m_centerY]

    set m_localCoords [list $x1 $y1 $x2 $y2]

    #puts "vertexMotion 1: $x1 $y1 2: $x2 $y2"

    redrawHotSpots 1
}
body GridItemLine::redraw { fromGUI } {
    #puts "line redraw: a=$m_oAngle = [expr 180.0 * $m_oAngle / 3.14159]"
    #puts "center at $m_centerX $m_centerY"
    if {!$fromGUI && ![shouldDisplay]} {
        removeAllGui
        return
    }
    set ll [llength $m_localCoords]
    if {$ll < 4} {
        puts "line redraw bad coords: $m_localCoords orig: $m_oLocalCoords"
        return
    }

    if {$m_guiId == ""} {
        _draw
    } else {
        foreach {x1 y1 x2 y2} $m_localCoords break
        #puts "1: $x1 $y1 2: $x2 $y2"

        set nx1 [expr $m_centerX + $x1]
        set ny1 [expr $m_centerY + $y1]
        set nx2 [expr $m_centerX + $x2]
        set ny2 [expr $m_centerY + $y2]

        $m_canvas coords $m_guiId $nx1 $ny1 $nx2 $ny2
    }

    redrawHotSpots $fromGUI
}
body GridItemLine::_draw { } {
    set ll [llength $m_localCoords]
    if {$ll < 4} {
        puts "line reborn bad coords: $m_localCoords orig: $m_oLocalCoords"
        return
    }

    foreach {x1 y1 x2 y2} $m_localCoords break
    set nx1 [expr $m_centerX + $x1]
    set ny1 [expr $m_centerY + $y1]
    set nx2 [expr $m_centerX + $x2]
    set ny2 [expr $m_centerY + $y2]

    set m_guiId [$m_canvas create line $nx1 $ny1 $nx2 $ny2 \
    -width 3 \
    -fill $GridGroupColor::COLOR_SHAPE \
    -stipple gray50 \
    -dash "" \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"
}
body GridItemLine::reborn { gridId info } {
    #puts "line reborn: a=$m_oAngle = [expr 180.0 * $m_oAngle / 3.14159]"
    GridItemBase::reborn $gridId $info

    if {[shouldDisplay]} {
        _draw
    }

    $m_holder addItem $this 0
}

class GridItemPolygon {
    inherit GridItemBase

    proc create { c x y h }
    proc instantiate { c h gridId info } {
        set item [GridItemPolygon ::#auto $c {} {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }

    public method getShape { } {
        return "polygon"
    }

    ### for create
    public method createPress { x y }

    ## special
    public method imageMotion { x y }

    public method redraw { fromGUI }
    public method reborn { gridId info }
    protected method _draw { }

    ### selected
    public method vertexMotion { x y }

    public method setStartPoint { x y } {
        set m_startX $x
        set m_startY $y
        set m_pressX $x
        set m_pressY $y
        $m_holder registerImageMotionCallback "$this imageMotion"
    }

    private method regenerateLocalCoords { }

    ##these only used during creation
    private variable m_startX 0
    private variable m_startY 0
    private variable m_idExtra ""

    private common END_DISTANCE 5

    constructor { canvas id id2 mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        #puts "polygon constructor"
        set m_idExtra $id2
    }
}
body GridItemPolygon::create { c x y h } {
    #puts "enter create c=$c"
    set id [$c create line \
    $x $y $x $y \
    -width 1 \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -dash . \
    -tags rubberband \
    ]

    ### header
    set id2 [$c create line \
    $x $y $x $y \
    -width 1 \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -dash . \
    -tags rubberband \
    ]
    set x1 [expr $x - $END_DISTANCE]
    set y1 [expr $y - $END_DISTANCE]
    set x2 [expr $x + $END_DISTANCE]
    set y2 [expr $y + $END_DISTANCE]

    $c create oval $x1 $y1 $x2 $y2 \
    -width 1 \
    -outline $GridGroupColor::COLOR_POLY_START \
    -fill $GridGroupColor::COLOR_POLY_START \
    -tags rubberband

    set item [GridItemPolygon ::#auto $c $id $id2 template $h]
    #puts "new item=$item"
    $item setStartPoint $x $y
    return $item
}
body GridItemPolygon::imageMotion { x y } {
    $m_canvas coords $m_idExtra $m_pressX $m_pressY $x $y
}

body GridItemPolygon::regenerateLocalCoords { } {

    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_centerX [expr ($x1 + $x2) / 2.0]
    set m_centerY [expr ($y1 + $y2) / 2.0]
    set m_oAngle 0
    saveShape
    saveSize [expr $x1 - $x2] [expr $y1 - $y2]
    updateCornerAndRotor


    set coords [$m_canvas coords $m_guiId]
    set m_localCoords ""
    foreach {x y} $coords {
        set lx [expr $x - $m_centerX]
        set ly [expr $y - $m_centerY]

        lappend m_localCoords $lx $ly
    }
    #saveLocalCoords
}

body GridItemPolygon::createPress { x y } {
    #puts "polygon create press $x $y"
    set dx [expr $x - $m_startX]
    set dy [expr $y - $m_startY]
    set d2 [expr $dx * $dx + $dy * $dy]
    set threshold [expr $END_DISTANCE * $END_DISTANCE]
    if {$d2 > $threshold} {
        $m_canvas insert $m_guiId end [list $x $y]
        #puts "appended point"
        set m_pressX $x
        set m_pressY $y
        return
    }

    ##### end of creation
    set coords [$m_canvas coords $m_guiId]
    #### remove first point, it is the same as second point.
    #### we used them to create first "line".    
    set coords [lrange $coords 2 end]

    set ll [llength $coords]
    if {$ll < 6} {
        ## not triangle even, we pretend you did not make this click
        return
    }

    set m_mode adjustable
    $m_canvas delete $m_guiId
    $m_canvas delete rubberband
    set m_guiId [$m_canvas create polygon $coords \
    -width 1 \
    -outline $GridGroupColor::COLOR_SHAPE_CURRENT \
    -fill "" \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    regenerateLocalCoords

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "polygon created: $m_guiId item=$this"
    #puts "coords $coords"

    generateGridMatrix
    #updateCornerAndRotor

    $m_holder addItem $this
}
body GridItemPolygon::_draw { } {
    set drawCoords ""
    foreach {lx ly} $m_localCoords {
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]
        lappend drawCoords $x $y
    }
    set m_guiId [$m_canvas create polygon $drawCoords \
    -width 1 \
    -outline $GridGroupColor::COLOR_SHAPE \
    -fill "" \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "polygon reborn: $m_guiId item=$this"
}
body GridItemPolygon::reborn { gridId info } {
    GridItemBase::reborn $gridId $info

    if {[shouldDisplay]} {
        _draw
    }

    $m_holder addItem $this 0
}
body GridItemPolygon::redraw { fromGUI } {
    if {!$fromGUI && ![shouldDisplay]} {
        removeAllGui
        return
    }
    if {$m_guiId == ""} {
        _draw
    } else {
        set drawCoords ""
        foreach {lx ly} $m_localCoords {
            set x [expr $m_centerX + $lx]
            set y [expr $m_centerY + $ly]
            lappend drawCoords $x $y
        }
        $m_canvas coords $m_guiId $drawCoords
    }
    redrawHotSpots $fromGUI
}
body GridItemPolygon::vertexMotion { x y } {
    #puts "polygonVertexMotion $x $y"
    ### line can use this code too.
    set index [expr $m_indexVertex * 2]
    $m_canvas dchars $m_guiId $index
    $m_canvas insert $m_guiId $index [list $x $y]

    regenerateLocalCoords

    redrawHotSpots 1
}
class GridItemL614 {
    inherit GridItemBase

    proc create { c x y h }
    proc instantiate { c h gridId info } {
        set item [GridItemL614 ::#auto $c {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }

    public method getShape { } {
        return "l614"
    }

    ### for create
    public method createPress { x y }

    ## special
    public method imageMotion { x y }

    public method redraw { fromGUI }
    public method reborn { gridId info }
    protected method _draw { }

    ### selected
    public method vertexMotion { x y }

    public method setStartPoint { x y } {
        #puts "L614 setStartPoint $x $y"
        set m_point0 [xyToGenericPosition $x $y]
        set m_numPointDefined 1
        $m_holder registerImageMotionCallback "$this imageMotion"
        drawPotentialPosition $m_point0
    }

    ### need to override these
    public method getItemInfo { } {
        set result [GridItemBase::getItemInfo]
        #[list $orig $geoList $gridList $m_nodeList]
        set gridList [lindex $result 2]
        dict set gridList num_column_picked $m_numColPicked
        dict set gridList num_row_picked    $m_numRowPicked
        set result [lreplace $result 2 2 $gridList]

        return $result
    }
    public method updateFromInfo { info {redraw 1}} {
        foreach {orig geo grid node frame status} $info break
        set m_numColPicked [dict get $grid num_column_picked]
        set m_numRowPicked [dict get $grid num_row_picked]

        return [GridItemBase::updateFromInfo $info $redraw]
    }
    public method setNode { index status }
    protected method generateGridMatrix { }
    protected method rebornGridMatrix { }
    protected method redrawGridMatrix { }
    protected method drawAllVertices { }

    private method drawPotentialPosition { p }
    private method calculateHolePosition

    private method regenerateLocalCoords { }

    ### we did not save it in to sample_x/y/z to avoid beamCenter involvement.
    private method xyToGenericPosition { x y } {
        foreach {uX uY} [$m_holder pixel2micron $x $y] break
        return [list $uX $uY [$m_holder getDisplayOrig]]
    }
    private method genericPositionToXY { p } {
        foreach {oX oY oOrig} $p break
        set currentOrig [$m_holder getDisplayOrig]
        foreach {ux uy} \
        [translateProjection \
        $oX $oY $oOrig $currentOrig] break
        
        return [$m_holder micron2pixel $ux $uy]
    }

    private method updateBorder { }

    private method checkPositionRelation { } {
        set currentOrig [$m_holder getDisplayOrig]

        foreach {ox0 oy0 oOrig0} $m_point0 break
        foreach {ux0 uy0} \
        [translateProjection $ox0 $oy0 $oOrig0 $currentOrig] break

        foreach {ox1 oy1 oOrig1} $m_point1 break
        foreach {ux1 uy1} \
        [translateProjection $ox1 $oy1 $oOrig1 $currentOrig] break

        foreach {ox2 oy2 oOrig2} $m_point2 break
        foreach {ux2 uy2} \
        [translateProjection $ox2 $oy2 $oOrig2 $currentOrig] break

        foreach {ox3 oy3 oOrig3} $m_point3 break
        foreach {ux3 uy3} \
        [translateProjection $ox3 $oy3 $oOrig3 $currentOrig] break

        set h1 [expr abs($ux0 - $ux2)]
        set h2 [expr abs($ux1 - $ux3)]
        set v1 [expr abs($uy0 - $uy1)]
        set v2 [expr abs($uy2 - $uy3)]

        set h [expr ($h1 + $h1) / 2.0]
        set m_numColPicked [expr round( $h / $DISTANCE_HOLE_HORZ)]
        set vPerfect [expr 2.0 * $DISTANCE_HOLE_VERT]
        set hPerfect [expr $m_numColPicked * $DISTANCE_HOLE_HORZ]
        set txt [expr $m_numColPicked + 1]
        set vTol 100
        set hTol [expr 50 * $m_numColPicked]

        set dv1 [expr abs($v1 - $vPerfect)]
        set dv2 [expr abs($v2 - $vPerfect)]
        set dh1 [expr abs($h1 - $hPerfect)]
        set dh2 [expr abs($h2 - $hPerfect)]
        if {$dv1 > $vTol} {
            log_error B1 and D1 distance=$dv1 microns not accurate
        }
        if {$dv2 > $vTol} {
            log_error B$txt and D$txt distance=$dv2 microns not accurate
        }
        if {$dh1 > $hTol} {
            log_error B1 and B$txt distance=$dh1 microns not accurate
        }
        if {$dh2 > $hTol} {
            log_error D1 and D$txt distance=$dh2 microns not accurate
        }

    }

    ##these only used during creation
    private variable m_point0 ""
    private variable m_point1 ""
    private variable m_point2 ""
    private variable m_point3 ""
    private variable m_hotSpotCoords ""
    private variable m_idExtra ""
    private variable m_numPointDefined 0

    ### extra, need to save and restore
    private variable m_numRowPicked 2
    private variable m_numColPicked 7

    private common NUM_HOLE_HORZ 16
    private common NUM_HOLE_VERT 5
    ## microns
    private common HOLE_RADIUS_LIST [list 200.0 62.5 200.0 100.0 200.0]
    private common DISTANCE_HOLE_HORZ 800
    private common DISTANCE_HOLE_VERT 400

    private common COLOR_HOLE_DONE        cyan
    private common COLOR_HOLE_WITH_SAMPLE green
    private common COLOR_HOLE_EMPTY       gray 
    private common COLOR_HOLE_LABEL       white

    constructor { canvas id mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        set m_gridOnTopOfBody 1
        set m_showOutline 0
        set m_showRotor 0
        setSequenceType horz
        set m_oCellWidth  $DISTANCE_HOLE_HORZ
        set m_oCellHeight $DISTANCE_HOLE_VERT
        updateGrid

        set m_nodeLabelList ""
        set rLabelList [list A B C D E]
        for {set row 0} {$row < $NUM_HOLE_VERT} {incr row} {
            set rowLabel [lindex $rLabelList $row]
            for {set col 0} {$col < $NUM_HOLE_HORZ} {incr col} {
                set holeLabel $rowLabel[expr $col + 1]
                lappend m_nodeLabelList $holeLabel
            }
        }

    }
}
body GridItemL614::create { c x y h } {
    #puts "enter L614 create c=$c"
    foreach {w -} [$h getDisplayPixelSize] break

    set id [$c create line \
    0 $y $w $y \
    -width 1 \
    -fill red \
    -dash . \
    -tags rubberband \
    ]

    set item [GridItemL614 ::#auto $c $id template $h]
    #puts "new item=$item"
    $item setStartPoint $x $y
    return $item
}
body GridItemL614::imageMotion { x y } {
    switch -exact -- $m_numPointDefined {
        2 {
            foreach {x0 y0} [genericPositionToXY $m_point0] break
            $m_canvas coords $m_guiId $x0 $y0 $x $y
        }
        3 {
            foreach {x1 y1} [genericPositionToXY $m_point1] break
            $m_canvas coords $m_idExtra $x1 $y1 $x $y
        }
    }
}

body GridItemL614::regenerateLocalCoords { } {
    set xMin [lindex $m_hotSpotCoords 0]
    set yMin [lindex $m_hotSpotCoords 1]
    set xMax $xMin
    set yMax $yMin
    foreach {x y} $m_hotSpotCoords {
        if {$x > $xMax} {
            set xMax $x
        }
        if {$x < $xMin} {
            set xMin $x
        }
        if {$y > $yMax} {
            set yMax $y
        }
        if {$y < $yMin} {
            set yMin $y
        }
    }
    set x1 $xMin
    set y1 $yMin
    set x2 $xMax
    set y2 $yMax

    #puts "regenerateLocalCoords: $x1 $y1 $x2 $y2"
    set m_centerX [expr ($x1 + $x2) / 2.0]
    set m_centerY [expr ($y1 + $y2) / 2.0]
    set m_oAngle 0
    ### save centerX/Y
    saveShape
    saveSize [expr $x1 - $x2] [expr $y1 - $y2]
    updateCornerAndRotor

    set m_localCoords ""
    set coords $m_hotSpotCoords
    #puts "coords=$coords"
    foreach {x y} $coords {
        set lx [expr $x - $m_centerX]
        set ly [expr $y - $m_centerY]

        lappend m_localCoords $lx $ly
    }

    ### this will append another 8 element to m_localCoords
    set akList [calculateHolePosition]

    for {set row 0} {$row < $NUM_HOLE_VERT} {incr row} {
        set ak [lindex $akList $row]
        foreach {ax kx ay ky} $ak break
        for {set col 0} {$col < $NUM_HOLE_HORZ} {incr col} {
            set index [expr $row * $m_numCol + $col]
            set x [expr $ax + $col * $kx]
            set y [expr $ay + $col * $ky]

            set lx [expr $x - $m_centerX]
            set ly [expr $y - $m_centerY]
            lappend m_localCoords $lx $ly
        }
    }
    #saveLocalCoords
}

body GridItemL614::createPress { x y } {
    puts "l614 create press $x $y numDefined=$m_numPointDefined"

    set m_point$m_numPointDefined [xyToGenericPosition $x $y]
    incr m_numPointDefined
    switch -exact -- $m_numPointDefined {
        1 {
            ## should not be here
            return
        }
        2 {
            foreach {w h} [$m_holder getDisplayPixelSize] break
            foreach {x1 y1} [genericPositionToXY $m_point1] break
            set m_idExtra [$m_canvas create line \
            0 $y1 $w $y1 \
            -width 1 \
            -fill $GridGroupColor::COLOR_RUBBERBAND \
            -dash . \
            -tags rubberband \
            ]
            return
        }
        3 {
            $m_canvas itemconfig $m_guiId \
            -width 2 \
            -fill red \
            -dash "" \
            -tags [list raster item_$m_guiId]

            return
        }
        4 {
            ### end
        }
    }

    set m_mode adjustable
    $m_canvas delete $m_guiId
    $m_canvas delete $m_idExtra
    $m_canvas delete rubberband

    ####checking
    checkPositionRelation

    foreach {x0 y0} [genericPositionToXY $m_point0] break
    foreach {x1 y1} [genericPositionToXY $m_point1] break
    foreach {x2 y2} [genericPositionToXY $m_point2] break
    foreach {x3 y3} [genericPositionToXY $m_point3] break
    set m_hotSpotCoords [list $x0 $y0 $x2 $y2 $x3 $y3 $x1 $y1]
    set coords $m_hotSpotCoords
    #puts "create coords: $coords"

    set m_guiId [$m_canvas create polygon $coords \
    -width 1 \
    -outline $GridGroupColor::COLOR_SHAPE_CURRENT \
    -fill "" \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    regenerateLocalCoords

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "l614 created: $m_guiId item=$this"
    #puts "coords $coords"

    generateGridMatrix

    $m_holder addItem $this
}
body GridItemL614::_draw { } {
    set m_hotSpotCoords ""
    set vertexCoords [lrange $m_localCoords 0 7]
    foreach {lx ly} $vertexCoords {
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]
        lappend m_hotSpotCoords $x $y
    }

    set drawCoords ""
    set bodyCoords [lrange $m_localCoords 8 15]
    foreach {lx ly} $bodyCoords {
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]
        lappend drawCoords $x $y
    }
    set m_guiId [$m_canvas create polygon $drawCoords \
    -width 2 \
    -fill "" \
    -outline $GridGroupColor::COLOR_SHAPE \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "polygon reborn: $m_guiId item=$this"
}
body GridItemL614::reborn { gridId info } {
    GridItemBase::reborn $gridId $info

    if {[shouldDisplay]} {
        _draw
    }

    $m_holder addItem $this 0
}
body GridItemL614::redraw { fromGUI } {
    if {!$fromGUI && ![shouldDisplay]} {
        removeAllGui
        return
    }
    if {$m_guiId == ""} {
        _draw
    } elseif {$m_mode == "template"} {
        #puts "template num=$m_numPointDefined"
        switch -exact -- $m_numPointDefined {
            1 {
                drawPotentialPosition $m_point0
                foreach {x0 y0} [genericPositionToXY $m_point0] break
                set coords [$m_canvas coords $m_guiId]
                foreach {- - x y} $coords break
                $m_canvas coords $m_guiId $x0 $y0 $x $y
            }
            2 {
                drawPotentialPosition $m_point0
                foreach {x0 y0} [genericPositionToXY $m_point0] break
                foreach {x1 y1} [genericPositionToXY $m_point1] break
                $m_canvas coords $m_guiId $x0 $y0 $x1 $y1
                $m_canvas itemconfig $m_guiId \
                -width 2 \
                -fill red \
                -dash "" \
                -tags [list raster item_$m_guiId]
            }
            3 {
                ## repeat "2" first
                drawPotentialPosition $m_point0
                foreach {x0 y0} [genericPositionToXY $m_point0] break
                foreach {x1 y1} [genericPositionToXY $m_point1] break
                $m_canvas coords $m_guiId $x0 $y0 $x1 $y1
                $m_canvas itemconfig $m_guiId \
                -width 2 \
                -fill red \
                -dash "" \
                -tags [list raster item_$m_guiId]

                ### do "3" own
                foreach {x2 y2} [genericPositionToXY $m_point2] break
                set coords [$m_canvas coords $m_idExtra]
                foreach {- - x y} $coords break
                $m_canvas coords $m_idExtra $x2 $y2 $x $y
            }
        }
        return
    } else {
        set m_hotSpotCoords ""
        set vertexCoords [lrange $m_localCoords 0 7]
        foreach {lx ly} $vertexCoords {
            set x [expr $m_centerX + $lx]
            set y [expr $m_centerY + $ly]
            lappend m_hotSpotCoords $x $y
        }
        updateBorder
    }
    redrawHotSpots $fromGUI
}
body GridItemL614::drawAllVertices { } {
    set coords $m_hotSpotCoords
    set index -1
    foreach {x y} $coords {
        incr index
        drawVertex $index $x $y
    }
}
body GridItemL614::vertexMotion { x y } {
    #puts "L614 hotSpotMotion $x $y"
    set index [expr $m_indexVertex * 2]

    set m_hotSpotCoords \
    [lreplace $m_hotSpotCoords $index [expr $index + 1] $x $y]

    #puts "hotSpot changed to $m_hotSpotCoords"

    regenerateLocalCoords

    updateBorder
    redrawHotSpots 1
}
body GridItemL614::drawPotentialPosition { p } {
    foreach {ox oy oOrig} $p break
    set currentOrig [$m_holder getDisplayOrig]

    $m_canvas delete ruler_$m_guiId

    ###horz ruler
    set hy [expr $oy - 100]
    for {set i 0} {$i < $NUM_HOLE_HORZ} {incr i} {
        set hx [expr $ox - $i * $DISTANCE_HOLE_HORZ]
        foreach {ux uy} [translateProjection $hx $hy $oOrig $currentOrig] break
        foreach {x y} [$m_holder micron2pixel $ux $uy] break
        set txt [expr $i + 1]
        if {$i == 0} {
            set txt "1(15)"
        }
        $m_canvas create text $x $y \
        -text $txt \
        -font "-family courier -size 16" \
        -fill $GridGroupColor::COLOR_RUBBERBAND \
        -anchor s \
        -tags [list ruler_$m_guiId rubberband item_$m_guiId]
    }
    for {set i 1} {$i < $NUM_HOLE_HORZ} {incr i} {
        set hx [expr $ox + $i * $DISTANCE_HOLE_HORZ]
        foreach {ux uy} [translateProjection $hx $hy $oOrig $currentOrig] break
        foreach {x y} [$m_holder micron2pixel $ux $uy] break
        set txt [expr $NUM_HOLE_HORZ - $i - 1]
        $m_canvas create text $x $y \
        -text $txt \
        -font "-family courier -size 16" \
        -fill $GridGroupColor::COLOR_RUBBERBAND \
        -anchor s \
        -tags [list ruler_$m_guiId rubberband item_$m_guiId]
    }

    # vert potential: just 2 positions.
    set txtList [list B D B]
    set hx [expr $ox + 100]
    set y0 [expr $oy - 2 * $DISTANCE_HOLE_VERT]
    for {set i 0} {$i < 3} {incr i} {
        set hy [expr $y0 + $i * 2 * $DISTANCE_HOLE_VERT]
        foreach {ux uy} [translateProjection $hx $hy $oOrig $currentOrig] break
        foreach {x y} [$m_holder micron2pixel $ux $uy] break
        set txt [lindex $txtList $i]
        $m_canvas create text $x $y \
        -text $txt \
        -font "-family courier -size 16" \
        -fill $GridGroupColor::COLOR_RUBBERBAND \
        -anchor e \
        -tags [list ruler_$m_guiId rubberband item_$m_guiId]
    }
}
body GridItemL614::updateBorder { } {
    set drawCoords ""
    set bodyCoords [lrange $m_localCoords 8 15]
    foreach {lx ly} $bodyCoords {
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]
        lappend drawCoords $x $y
    }
    $m_canvas coords $m_guiId $drawCoords
}
body GridItemL614::generateGridMatrix { } {
    #puts "generateGridMatrix for $this"
    ##set m_nodeList ""
    $m_canvas delete grid_$m_guiId

    set m_gridCenterX $m_centerX
    set m_gridCenterY $m_centerY

    set m_numCol $NUM_HOLE_HORZ
    set m_numRow $NUM_HOLE_VERT
    set numHole [expr $m_numCol * $m_numRow]
    if {[llength $m_nodeList] != $numHole} {
        set m_nodeList [string repeat "S " $numHole]
    }

    $m_canvas delete grid_$m_guiId
    set radiusList ""
    set currentOrig [$m_holder getDisplayOrig]
    for {set row 0} {$row < $NUM_HOLE_VERT} {incr row} {
        set r [lindex $HOLE_RADIUS_LIST $row]
        foreach {ux uy} \
        [translateProjectionBox $r $r $m_oOrig $currentOrig] break
        foreach {x y} [$m_holder micron2pixel $ux $uy] break
        lappend radiusList [list $x $y]
    }
    set holePositionList [lrange $m_localCoords 16 end]
    set index -1
    foreach {lx ly} $holePositionList {
        incr index
        set row [expr $index / $m_numCol]
        set col [expr $index % $m_numCol]

        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]

        set radiusPair [lindex $radiusList $row]
        foreach {xr yr} $radiusPair break

        set x1 [expr $x - $xr]
        set y1 [expr $y - $yr]
        set x2 [expr $x + $xr]
        set y2 [expr $y + $yr]

        $m_canvas create oval $x1 $y1 $x2 $y2 \
        -outline $GridGroupColor::COLOR_GRID \
        -tags \
        [list grid grid_$m_guiId item_$m_guiId node_${m_guiId}_${index}]
    }

    saveItemInfo

    $m_canvas raise $m_guiId
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info

    contourSetup
}
body GridItemL614::rebornGridMatrix { } {
    contourSetup
    redrawGridMatrix
}
body GridItemL614::calculateHolePosition { } {
    ## 4 points (row, col)
    ### if numColPicked==4
    ## case 1: from left
    #  D1:  (0.98, 0)
    #  D5:  (0.98, 4)
    #  B5:  (1.76, 4)
    #  B1:  (1.76, 0)
    #
    # case 2: from right
    #  D15  (0.98, 14)
    #  D11  (0.98, 10)
    #  B11  (1.76, 10)
    #  B15  (1.76, 14)

    ### check it is case 1 or case 2
    foreach {x0 y0 x1 y1 x3 y3 x2 y2} $m_localCoords break
    foreach {ux0 uy0 ux1 uy1} [$m_holder pixel2micron $x0 $y0 $x1 $y1] break

    puts "tipping check 0=($ux0, $uy0) 1=($ux1, $uy1)"
    if {$ux0 < $ux1} {
        set fromTip 0
        set firstColIndex [expr $NUM_HOLE_HORZ - 2]
        set sign -1
    } else {
        set fromTip 1
        set firstColIndex 0
        set sign 1
    }

    if {[llength $m_localCoords] > 8} {
        set m_localCoords [lrange $m_localCoords 0 7]
    }
    set x0 [expr $m_centerX + $x0]
    set y0 [expr $m_centerY + $y0]
    set x1 [expr $m_centerX + $x1]
    set y1 [expr $m_centerY + $y1]
    set x2 [expr $m_centerX + $x2]
    set y2 [expr $m_centerY + $y2]
    set x3 [expr $m_centerX + $x3]
    set y3 [expr $m_centerY + $y3]

    ##row D (bigger small hole) row B smaller small hole
    set rowDVert 0.98
    set rowBVert 1.76
    ### for shape
    set m_shapeCoords ""
    set rowVertList [list 0 2.73]

    set borderCol [expr $NUM_HOLE_HORZ - 0.5]
    set colList [list [list -1.25 $borderCol] [list $borderCol -1.25]]
    for {set row 0} {$row < 2} {incr row} {
        set rowVert [lindex $rowVertList $row]
        set factor [expr ($rowVert - $rowDVert) / ($rowBVert - $rowDVert)]

        set xRow0 [expr $x0 + ($x2 - $x0) * $factor]
        set yRow0 [expr $y0 + ($y2 - $y0) * $factor]

        set xRow1 [expr $x1 + ($x3 - $x1) * $factor]
        set yRow1 [expr $y1 + ($y3 - $y1) * $factor]

        set kx [expr $sign * ($xRow1 - $xRow0) / $m_numColPicked]
        set ky [expr $sign * ($yRow1 - $yRow0) / $m_numColPicked]

        set ax [expr $xRow0 - $firstColIndex * $kx]
        set ay [expr $yRow0 - $firstColIndex * $ky]

        set colHorzList [lindex $colList $row]
        foreach colHorz $colHorzList {
            set x [expr $ax + $kx * $colHorz]
            set y [expr $ay + $ky * $colHorz]
            set x [expr $x - $m_centerX]
            set y [expr $y - $m_centerY]
            lappend m_localCoords $x $y
        }
    }

    set result ""
    set rowVertList [list 2.14 1.76 1.36 0.98 0.58]
    for {set row 0} {$row < $NUM_HOLE_VERT} {incr row} {
        set rowVert [lindex $rowVertList $row]

        set factor [expr ($rowVert - $rowDVert) / ($rowBVert - $rowDVert)]

        set xRow0 [expr $x0 + ($x2 - $x0) * $factor]
        set yRow0 [expr $y0 + ($y2 - $y0) * $factor]

        set xRow1 [expr $x1 + ($x3 - $x1) * $factor]
        set yRow1 [expr $y1 + ($y3 - $y1) * $factor]

        set kx [expr $sign * ($xRow1 - $xRow0) / $m_numColPicked]
        set ky [expr $sign * ($yRow1 - $yRow0) / $m_numColPicked]

        set ax [expr $xRow0 - $firstColIndex * $kx]
        set ay [expr $yRow0 - $firstColIndex * $ky]

        if {$row % 2 == 0} {
            set ax [expr $ax - $kx / 2.0]
            set ay [expr $ay - $ky / 2.0]
        }
        lappend result [list $ax $kx $ay $ky]
    }
    #puts "calculatHolePosition: $result"
    return $result
}

body GridItemL614::redrawGridMatrix { } {
    set nodeColorList [getContourDisplayList]
    $m_obj setValues $nodeColorList

    set nodeLabelList [getNumberDisplayList]
    set font_sizeW [expr int(0.4 * $m_cellWidth)]
    set font_sizeH [expr int(0.4 * $m_cellHeight)]
    set font_size [expr ($font_sizeW > $font_sizeH)?$font_sizeH:$font_sizeW]

    $m_canvas delete grid_$m_guiId

    set currentOrig [$m_holder getDisplayOrig]
    set radiusList ""
    for {set row 0} {$row < $NUM_HOLE_VERT} {incr row} {
        set r [lindex $HOLE_RADIUS_LIST $row]
        foreach {ux uy} \
        [translateProjectionBox $r $r $m_oOrig $currentOrig] break
        foreach {x y} [$m_holder micron2pixel $ux $uy] break
        lappend radiusList [list $x $y]
    }

    set holePositionList [lrange $m_localCoords 16 end]
    set index -1

    foreach {lx ly} $holePositionList {
        incr index
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]

        set row [expr $index / $m_numCol]
        set col [expr $index % $m_numCol]

        set holeLabel [lindex $m_nodeLabelList $index]

        set radiusPair [lindex $radiusList $row]
        foreach {xr yr} $radiusPair break

        set x1 [expr $x - $xr]
        set x2 [expr $x + $xr]
        set y1 [expr $y - $yr]
        set y2 [expr $y + $yr]

        set nodeStatus [lindex $nodeColorList $index]
        set nodeLabel  [lindex $nodeLabelList $index]
        #set nodeAttrs [nodeStatus2Attributes $nodeStatus]
        ### customized nodeStatus2Attributes
        set fill ""
        set outline $COLOR_HOLE_WITH_SAMPLE
        switch -exact -- $nodeStatus {
            - -
            -- {
                ### the node not exists
                continue
            }
            S {
            }
            N -
            NA -
            NEW {
                set outline $COLOR_HOLE_EMPTY
            }
            X {
                if {$m_mode != "done"} {
                    set fill $GridGroupColor::COLOR_EXPOSING
                }
            }
            D {
                if {$m_mode != "done"} {
                    set fill $GridGroupColor::COLOR_DONE
                }
                set outline $COLOR_HOLE_DONE
            }
            default {
            }
        }

        set hid [$m_canvas create oval $x1 $y1 $x2 $y2 \
        -outline $outline \
        -fill $fill \
        -tags \
        [list grid grid_$m_guiId node_${m_guiId}_${index}] \
        ]
        $m_canvas bind $hid <Button-1> "$this gridPress $row $col %x %y"
        ## to trigger click inside the hole
        set hid [$m_canvas create oval $x1 $y1 $x2 $y2 \
        -outline "" \
        -fill "" \
        -tags \
        [list grid grid_$m_guiId nodehide_${m_guiId}_${index}] \
        ]
        $m_canvas bind $hid <Button-1> "$this gridPress $row $col %x %y"

        if {$nodeLabel == ""} {
            continue
        }

        #set tx $x
        #set ty $y
        #set tid [$m_canvas create text $tx $ty \
        #-text $nodeLabel \
        #-font "-family courier -size $font_size" \
        #-fill $GridGroupColor::COLOR_VALUE \
        #-anchor c \
        #-justify center \
        #-tags \
        #[list grid grid_$m_guiId \
        #nodeLabel_${m_guiId}_${index}] ]
        #$m_canvas bind $tid <Button-1> "$this gridPress $row $col %x %y"

        set lx $x
        set ly [expr $y2 + 4]
        $m_canvas create text $lx $ly \
        -text $holeLabel \
        -font "-family courier -size $font_size" \
        -fill $COLOR_HOLE_LABEL \
        -anchor n \
        -justify center \
        -tags \
        [list grid grid_$m_guiId \
        nodeLabel_${m_guiId}_${index}]
    }
    ### draw a red line on row D
    #foreach {x1 y1 x2 y2} $m_localCoords break
    #set x1 [expr $m_centerX + $x1]
    #set x2 [expr $m_centerX + $x2]
    #set y1 [expr $m_centerY + $y1]
    #set y2 [expr $m_centerY + $y2]
    #$m_canvas create line $x1 $y1 $x2 $y2 \
    #-fill red \
    #-width 4 \
    #-tags \
    #[list top_line grid grid_$m_guiId item_$m_guiId]

    redrawContour

    $m_canvas raise $m_guiId
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info
    $m_canvas raise top_line
}
body GridItemL614::setNode { index status } {
    #puts "setNode for $this index=$index status=$status"
    set ll [llength $m_nodeList]
    if {$index < 0 || $index >= $ll} {
        puts "ERROR: setNode with index=$index out of range 0 - $ll"
        return
    }

    set nodeTag node_${m_guiId}_${index}
    set nodehideTag nodehide_${m_guiId}_${index}
    set labelTag nodeLabel_${m_guiId}_${index}

    set m_nodeList [lreplace $m_nodeList $index $index $status]
    set contourValue [getContourDisplayValue $status]

    #set nodeAttrs [nodeStatus2Attributes $status]
    #if {$nodeAttrs == ""} {
    #    $m_myCanvas delete $nodeTag
    #    $m_myCanvas delete $labelTag
    #    return
    #}
    #foreach {fill stipple} $nodeAttrs break
    ### customized nodeStatus2Attributes
    set fill ""
    set outline $COLOR_HOLE_WITH_SAMPLE
    switch -exact -- $status {
        - -
        -- {
            ### the node not exists
            $m_myCanvas delete $nodeTag
            $m_myCanvas delete $nodehideTag
            $m_myCanvas delete $labelTag
            return
        }
        S {
        }
        N -
        NA -
        NEW {
            set outline $COLOR_HOLE_EMPTY
        }
        X {
            if {$m_mode != "done"} {
                set fill $GridGroupColor::COLOR_EXPOSING
            }
        }
        D {
            if {$m_mode != "done"} {
                set fill $GridGroupColor::COLOR_DONE
            }
            set outline $COLOR_HOLE_DONE
        }
        default {
        }
    }
    $m_canvas itemconfigure $nodeTag \
    -outline $outline \
    -fill $fill
}

class GridItemGroup {
    inherit GridItemBase

    proc create { c x y h }

    public method redraw { fromGUI }

    ### for create
    public method createMotion { x y }
    public method createRelease { x y }

    public method bodyPress { x y }
    public method bodyMotion { x y }
    #public method bodyRelease { x y } {
    #    raise
    #    foreach item $m_member {
    #        $m_holder onItemChange $item
    #    }
    #}

    public method rotate { angle {radians 0} } {
        #puts "group rotate a=$angle radians=$radians"
        foreach item $m_member {
            $item groupRotate $m_centerX $m_centerY $angle $radians
        }
        GridItemBase::rotate $angle $radians
        raise
    }

    public method getMemberGridIdList { } {
        set idList ""
        foreach item $m_member {
            set id [$item getGridId]
            lappend idList $id
        }
        return $idList
    }
    public method getMemberInfoList { } {
        set infoList ""
        foreach item $m_member {
            set id   [$item getGridId]
            set info [$item getItemInfo]
            lappend infoList $id $info
        }
        return $infoList
    }
    public method clearAllMember { } {
        set m_member ""
    }
    private method deleteAllMember { } {
        foreach item $m_member {
            $m_holder removeItem $item
        }
        set m_member ""
    }

    ### override to delete self up on not-selected
    ### This should be better than onUngroup.
    ### We may decide to remove those functions and directly export
    ### setItemStatus
    protected method setItemStatus { s } {
        #puts "group setItemStatus $s"
        if {$s == "unsilent" && $m_status != "silent"} {
            #puts "DEBUG: unsilent called on not-silent: $m_status"
            return
        }
        if {$s != "selected"} {
            ### only remove itself quietly
            foreach item $m_member {
                $item onLeaveGroup
            }
            set m_member ""
            #puts "delete self only"
            $m_holder removeItem $this
        }
        set m_status $s
        redrawHotSpots 0
    }

    private variable m_member ""

    constructor { canvas id mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        #puts "group constructor"
        set m_showOutline 0
        set m_showVertexAndMatrix 0
    }
    destructor {
        #puts "group destructor: member=$m_member"
        deleteAllMember
    }
}
body GridItemGroup::create { c x y h } {
    #puts "enter create c=$c"
    ### polygon no fill still inside
    set id [$c create polygon \
    $x $y $x $y $x $y $x $y \
    -width 1 \
    -outline $GridGroupColor::COLOR_OUTLINE \
    -fill "" \
    -dash . \
    -tags rubberband \
    ]

    #puts "group id=$id"
    set item [GridItemGroup ::#auto $c $id template $h]
    #puts "new item=$item"
    $item createPress $x $y
    return $item
}
body GridItemGroup::createMotion { x y } {
    $m_canvas coords $m_guiId $m_pressX $m_pressY $x $m_pressY $x $y $m_pressX $y
}
body GridItemGroup::createRelease { x y } {
    set m_mode adjustable
    set itemList [$m_holder getEnclosedItems $m_pressX $m_pressY $x $y]
    set numItem [llength $itemList]
    switch -exact -- $numItem {
        0 {
            $m_canvas delete $m_guiId
            ### do not delete $this.  Holder will do it later.
            return
        }
        1 {
            set singleItem $itemList
            $m_canvas delete $m_guiId
            $m_holder setCurrentItem $singleItem
            return
        }
        default {
        }
    }
    set m_member $itemList
    foreach item $m_member {
        $item onJoinGroup $this
    }

    ### this needs recode. TODO
    set tkItemList [$m_canvas find enclosed $m_pressX $m_pressY $x $y]
    set box [eval $m_canvas bbox $tkItemList]

    foreach {x1 y1 x2 y2} $box break
    set m_centerX [expr ($x1 + $x2) / 2.0]
    set m_centerY [expr ($y1 + $y2) / 2.0]
    saveShape
    saveSize [expr $x1 - $x2] [expr $y1 - $y2]
    updateCornerAndRotor

    $m_canvas coords $m_guiId $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2
    $m_canvas itemconfig $m_guiId \
    -width 1 \
    -dash "" \
    -outline $GridGroupColor::COLOR_SHAPE_CURRENT \
    -fill "" \
    -tags group

    $m_canvas raise $m_guiId

    $m_canvas bind $m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind $m_guiId <Enter>    "$this enter"
    $m_canvas bind $m_guiId <Leave>    "$this leave"

    #puts "group created: $m_guiId item=$this"
    #puts "coords [$m_canvas coords $m_guiId]"
    #puts "total member [llength $m_member]"

    #saveItemInfo

    $m_holder addItem $this
    $m_canvas raise beam_info
}
## not the same as Base
body GridItemGroup::bodyPress { xw yw } {
    set m_motionCalled 0
    #puts "group bodyPRess for $this"
    if {[noResponse]} {
        #puts "calling group bodyPress no response"
        return
    }
    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]
    set m_pressX $x
    set m_pressY $y

    #$m_holder setCurrentItem $this
    #puts "register call backs"
    $m_holder registerButtonCallback "$this bodyMotion" "$this bodyRelease"
}
body GridItemGroup::bodyMotion { x y } {
    #puts "group body motion"
    set dx [expr $x - $m_pressX]
    set dy [expr $y - $m_pressY]

    foreach item $m_member {
        $item groupMove $dx $dy
    }

    GridItemBase::bodyMotion $x $y
}
body GridItemGroup::redraw { fromGUI } {
    set coords [getCorners]
    $m_canvas coords $m_guiId $coords
    redrawHotSpots $fromGUI
    $m_canvas raise $m_guiId
    $m_canvas raise beam_info
}

class GridCanvas {
    inherit ::DCS::ComponentGateExtension GridItemHolder

    itk_option define -forL614 forL614 ForL614 1

    ### file/data
    itk_option define -snapshotType snapshotType SnapshotType file
    itk_option define -snapshot   snapshot   Snapshot   ""        { update }
    itk_option define -viewOrig viewOrig ViewOrig "" {
        foreach item $m_itemList {
            $item refresh
        }
        if {$m_templateItem != ""} {
            if {[catch {
                $m_templateItem refresh
            } errMsg]} {
                puts "refresh template item failed: $errMsg"
            }
        }
        ### may need to register to video orig string update
        registerVideoOrig
        if {!$m_liveVideo} {
            updateBeamPosition
        }
    }

    #### cross_only box_only both
    itk_option define -showBeamInfo showBeamInfo ShowBeamInfo both {
        updateBeamDisplay
    }

    ### all, selected_only, phi_match(default)
    itk_option define -showItem showItem ShowItem all

    itk_option define -packOption packOption PackOption "-side top"

    itk_option define -cluster cluster Cluster ""

    itk_option define -title   title   Title   ""        { redrawTitle }

    itk_option define -showNotice showNotice ShowNotice 1 { redrawNotice }

    ### wrap
    itk_option define -xscrollcommand xscrollCommand ScrollCommand ""
    itk_option define -yscrollcommand yscrollCommand ScrollCommand ""

    #itk_option define -toolMode toolMode ToolMode "pan"
    #itk_option define -toolMode toolMode ToolMode "add_oval"
    itk_option define -toolMode toolMode ToolMode "add_rectangle" {
        clearTemplateItem
        clearButtonCallback
        clearImageMotionCallback

        set tm $itk_option(-toolMode)
        if {[string equal -length 3 $tm "add"]} {
            set m_lastAddMode $tm
        }

        switch -exact -- $itk_option(-toolMode) {
            adjust {
                allItemActive
                if {$m_currentItem != ""} {
                    $m_currentItem raise
                    #puts "raise $m_currentItem"
                }
            }
            pan {
                ## order is important here
                ## clearCurrentItem may delete the group wrapper
                clearCurrentItem
                allItemDeactive
            }
            default {
                ### we may change to only call allItemAcitve only if
                ### previous toolMode is "pan"
                clearCurrentItem
                allItemActive
            }
        }
        updateRegisteredComponents toolMode
    }

    private common   MIN_ZOOM   0.5
    private common   MAX_ZOOM   10.0
    private variable m_zoom     1.0

    private variable m_lastAddMode "add_rectangle"

    protected variable m_rawImage ""
    private variable m_rawWidth    0
    private variable m_rawHeight   0

    private variable m_imageWidth  0
    private variable m_imageHeight  0

    protected variable m_viewScale 1.0

    protected variable m_snapshot

    private variable m_winID "no defined"

    private variable m_b1PressX 0
    private variable m_b1PressY 0
    private variable m_b1ReleaseX 0
    private variable m_b1ReleaseY 0
    private variable m_currentItem ""
    private variable m_templateItem ""
    private variable m_itemList ""
    private variable m_buttonCallbackMotion ""
    private variable m_buttonCallbackRelease ""
    private variable m_imageCallbackMotion ""

    private variable m_dcsCursor watch

    ### will be set by derived class
    protected variable m_remoteMode 0
    protected variable m_groupId -1
    protected variable m_snapshotId -1
    protected variable m_liveVideo 0

    ### will be used by derived class
    protected variable m_camera ""

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

    private variable m_inZoom 0

    protected variable m_drawImageOK 0
    private variable m_retryID     ""

    ### in case we decide to use iwidgets::scrolledcanvas
    protected variable m_myCanvas ""

    protected variable m_titleId ""
    protected variable m_noticeId ""

    private method redrawImage
    private method updateSnapshot

    private variable m_deviceFactory ""
    private variable m_objGridGroupConfig ""
    private variable m_objGridGroupFlip ""

    protected variable m_zoomCenterX 0.5
    protected variable m_zoomCenterY 0.5
    protected variable m_xviewInfo [list 0 1]
    protected variable m_yviewInfo [list 0 1]

    protected variable m_beamX -1
    protected variable m_beamY -1
    protected variable m_beamsizeInfo [list 0.1 0.1 white]

    protected variable m_objVideoOrig ""
    protected variable m_ctsVideoOrig ""

    public method setZoomCenterX { x } { set m_zoomCenterX $x }
    public method getZoomCenterX { } { return $m_zoomCenterX }
    ### center of current item or center of view
    public method autoZoomCenter { }

    ### we use this to calculate the current beam position on the view.
    ### It has current sample_xyz and the beamCenterXY.
    public method handleVideoOrigUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_ctsVideoOrig $contents_
        if {$m_liveVideo} {
            configure -viewOrig $contents_
        }
        updateBeamPosition
    }

    protected method updateBeamPosition { }

    ### fraction of image size
    protected method setCurrentBeamPosition { x y } {
        if {$x == $m_beamX && $y == $m_beamY} {
            return
        }
        set m_beamX $x
        set m_beamY $y
        updateBeamDisplay
    }
    public method refreshMatrixDisplay { } {
        foreach item $m_itemList {
            $item refreshMatrixDisplay
        }
    }

    #### needed for live video without any snapshot yet.
    public method registerVideoOrigExplicitly { camera }

    protected method handleNewOutput

    protected method registerVideoOrig

    ########### pan ############
    private method panClick {x y} {
        $m_myCanvas scan mark $x $y
    }
    private method panMotion { x y } {
        $m_myCanvas scan dragto $x $y 1
    }
    private method panRelease { x y } {
    }

    private method clearTemplateItem { } {
        if {$m_templateItem != ""} {
            catch {
                delete object $m_templateItem
            }
            set m_templateItem ""
        }
        $m_myCanvas delete rubberband
    }

    public method xview { args } {
        eval $m_myCanvas xview $args
    }

    public method clearNotice { } {
        if {$m_noticeId != ""} {
            $m_myCanvas delete $m_noticeId
            set m_noticeId ""
        }
    }

    public method setToolMode { mode } {
        configure -toolMode $mode
    }
    public method getToolMode { } {
        return $itk_option(-toolMode)
    }
    public method getNumberOfItem { } {
        return [llength $m_itemList]
    }
    public method getCurrentGridId { } {
        if {$m_currentItem == ""} {
            return -1
        }
        return [$m_currentItem getGridId]
    }

    public method isActive { } {
        if {!$m_remoteMode} {
            return 1
        }
        return $_gateOutput
    }

    public method onXScrollCommand { args } {
        redrawTitle
        redrawNotice

        eval $itk_component(xBar) set $args
        if {$itk_option(-xscrollcommand) != ""} {
            eval $itk_option(-xscrollcommand) $args
        }
        if {$args != $m_xviewInfo} {
            foreach {x0 x1} $args break
            foreach {savedX0 savedX1} $m_xviewInfo break
            set w [expr $x1 - $x0]
            set savedW [expr $savedX1 - $savedX0]
            if {abs($w - $savedW) > 0.001} {
                moveToZoomCenterX
            } else {
                set m_zoomCenterX [expr ($x1 + $x0) / 2.0]
            }
            set m_xviewInfo $args
        }
    }

    public method onYScrollCommand { args } {
        redrawTitle
        redrawNotice

        eval $itk_component(yBar) set $args
        if {$itk_option(-yscrollcommand) != ""} {
            eval $itk_option(-yscrollcommand) $args
        }
        if {$args != $m_yviewInfo} {
            foreach {y0 y1} $args break
            foreach {savedY0 savedY1} $m_yviewInfo break
            set h [expr $y1 - $y0]
            set savedH [expr $savedY1 - $savedY0]
            if {abs($h - $savedH) > 0.001} {
                moveToZoomCenterY
            } else {
                set m_zoomCenterY [expr ($y1 + $y0) / 2.0]
            }
            set m_yviewInfo $args
        }
    }

    public method handleImageEnter { xw yw } {
        #puts "image enter"
        switch -exact -- $itk_option(-toolMode) {
            pan {
                set cs fleur
            }
            default {
                set cs $m_dcsCursor
            }
        }
        $m_myCanvas configure \
        -cursor $cs
    }

    public method update
    public method handleButtonPress {xw yw} {
        set x [$m_myCanvas canvasx $xw]
        set y [$m_myCanvas canvasy $yw]
        if {$x < 0 || $y <0 || $x >= $m_imageWidth || $y >= $m_imageHeight} {
            return
        }
        set m_b1PressX $x
        set m_b1PRessY $y

        if {![isActive]} {
            panClick $xw $yw
            return
        }

        switch -exact -- $itk_option(-toolMode) {
            add_l614 {
                clearNotice
                ### need multiple press
                if {$m_templateItem == ""} {
                    set m_templateItem \
                    [GridItemL614::create \
                    $m_myCanvas $x $y $this]
                } else {
                    $m_templateItem createPress $x $y
                }
            }
            add_rectangle {
                ### just need one Press
                clearTemplateItem
                set m_templateItem \
                [GridItemRectangle::create \
                $m_myCanvas $x $y $this]
            }
            add_oval {
                clearTemplateItem
                set m_templateItem \
                [GridItemOval::create \
                $m_myCanvas $x $y $this]
            }
            add_line {
                clearTemplateItem
                set m_templateItem \
                [GridItemLine::create \
                $m_myCanvas $x $y $this]
            }
            add_polygon {
                ### need multiple press
                if {$m_templateItem == ""} {
                    set m_templateItem \
                    [GridItemPolygon::create \
                    $m_myCanvas $x $y $this]
                } else {
                    $m_templateItem createPress $x $y
                }
            }
            pan {
                panClick $xw $yw
            }
            adjust -
            default {
                if {$m_buttonCallbackMotion != "" \
                ||  $m_buttonCallbackRelease != ""} {
                    return
                }

                clearCurrentItem
                clearTemplateItem
                set m_templateItem \
                [GridItemGroup::create \
                $m_myCanvas $x $y $this]
            }
        }
        #puts "mode=$itk_option(-toolMode)"
    }
    public method handleButtonMotion {xw yw} {
        set x [$m_myCanvas canvasx $xw]
        set y [$m_myCanvas canvasy $yw]
        if {$x < 0 || $y <0 || $x >= $m_imageWidth || $y >= $m_imageHeight} {
            return
        }
        if {$m_buttonCallbackMotion != ""} {
            if {![isActive]} {
                log_error lost active, no more change.
                clearButtonCallback
                return
            }
            eval $m_buttonCallbackMotion $x $y
        } else {
            #puts "motion callback=={}"
            panMotion $xw $yw
        }
    }
    public method handleButtonRelease {xw yw} {
        set x [$m_myCanvas canvasx $xw]
        set y [$m_myCanvas canvasy $yw]
        if {$x < 0 || $y <0 || $x >= $m_imageWidth || $y >= $m_imageHeight} {
            return
        }
        if {$m_buttonCallbackRelease != ""} {
            if {![isActive]} {
                log_error lost active, no more change.
                clearButtonCallback
                return
            }
            eval $m_buttonCallbackRelease $x $y
        }
        clearButtonCallback
    }
    public method handleImageMotion {xw yw} {
        set x [$m_myCanvas canvasx $xw]
        set y [$m_myCanvas canvasy $yw]
        if {$x < 0 || $y <0 || $x >= $m_imageWidth || $y >= $m_imageHeight} {
            return
        }
        if {$m_imageCallbackMotion != ""} {
            eval $m_imageCallbackMotion $x $y
        }
    }

    public method handleResize {winID width height} {
        #puts "grid display resize: $winID $width $height"
        if {$m_inZoom} {
            #puts "inZoom"
            return
        }

        ### need clever so that resize and zoom button can co-exists.

        if {$m_rawWidth == 0 || $m_rawHeight == 0} {
            return
        }

        set viewWidth  [expr $width - 15]
        set viewHeight [expr $height - 15]

        set scaleW [expr 1.0 * $viewWidth / $m_rawWidth]
        set scaleH [expr 1.0 * $viewHeight / $m_rawHeight]

        set viewScale [expr ($scaleW > $scaleH)?$scaleH:$scaleW]

        if {$viewScale == $m_viewScale} {
            return
        }

        set ss [expr $viewScale / $m_viewScale]
        set m_viewScale $viewScale

        zoom [expr $m_zoom * $ss]
    }

    public method deleteSelected { } {
        #puts "deleteSelected"
        #puts "current item=$m_currentItem"

        if {$m_currentItem == "" && [llength $m_itemList] == 1} {
            set m_currentItem [lindex $m_itemList 0]
        }

        if {$m_currentItem != ""} {
            removeItem $m_currentItem
            #puts "current removed"
            set m_currentItem ""
            #puts "update current_grid in deleteSelected"
            updateRegisteredComponents current_grid
        }
    }
    public method rotate { angle {radians 0}} {
        if {$m_currentItem != ""} {
            $m_currentItem rotate $angle $radians
        }
    }
    public method getCurrentZoom { } { return $m_zoom }

    public method zoomIn { } {
        set m_inZoom 1
        if {$m_zoom < $MAX_ZOOM} {
            zoom [expr $m_zoom * 2.0]
        }
        set m_inZoom 0
    }
    public method zoomOut { } {
        set m_inZoom 1
        if {$m_zoom > $MIN_ZOOM} {
            zoom [expr $m_zoom / 2.0]
        }
        set m_inZoom 0
    }
    public method moveToZoomCenterX { } {
        set xx [$m_myCanvas xview]
        foreach {x0 x1} $xx break
        set ww [expr $x1 - $x0]
        #puts "moveToZoomCenter x=$m_zoomCenterX xx=$xx ww=$ww this=$this"
        if {$ww < 1.0} {
            set halfW [expr $ww / 2.0]
            set x0 [expr $m_zoomCenterX - $halfW]
            set x1 [expr $m_zoomCenterX + $halfW]
            #puts "first time: $x0 $x1 this=$this"
            if {$x0 < 0} {
                set x0 0
                set x1 $ww
            } elseif {$x1 > 1} {
                set x1 1
                set x0 [expr 1 - $ww]
            }
            #puts "final: $x0 $x1 for $this"
            $m_myCanvas xview moveto $x0
        }
    }
    public method moveToZoomCenterY { } {
        set yy [$m_myCanvas yview]
        foreach {y0 y1} $yy break
        set hh [expr $y1 - $y0]
        #puts "moveToZoomCenter y=$m_zoomCenterY yy=$yy hh=$hh this=$this"
        if {$hh < 1.0} {
            set halfH [expr $hh / 2.0]
            set y0 [expr $m_zoomCenterY - $halfH]
            set y1 [expr $m_zoomCenterY + $halfH]
            #puts "first time vert: $y0 $y1 for $this"
            if {$y0 < 0} {
                set y0 0
                set y1 $hh
            } elseif {$y1 > 1} {
                set y1 1
                set y0 [expr 1 - $hh]
            }
            #puts "final vert: $y0 $y1 for $this"
            $m_myCanvas yview moveto $y0
        }
    }
    public method setBeamSize { contents_ } {
        #puts "setBeamSize $contents_"
        set m_beamsizeInfo $contents_
        switch -exact -- $itk_option(-showBeamInfo) {
            both -
            box_only {
                updateBeamDisplay
            }
        }
    }

    public method handleBeamSizeUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        setBeamSize $contents_
    }

    public method zoom { scaleFactor } {
        if {$scaleFactor < $MIN_ZOOM} {
            set scaleFactor $MIN_ZOOM
        }
        if {$scaleFactor > $MAX_ZOOM} {
            set scaleFactor $MAX_ZOOM
        }
        #puts "zoom scale=$m_zoom"
        if {$scaleFactor != $m_zoom} {
            set m_zoom $scaleFactor
            redrawImage
            updateBeamDisplay
            ### we do not want to scale size of vertices, only their position.
            $m_myCanvas delete hotspot||rubberband

            foreach item $m_itemList {
                $item onZoom
                $item redraw 0
            }
        }
    }

    #implement GridItemHolder
    public method addItem { item {from_create 1}} {
        if {$item == $m_templateItem} {
            set m_templateItem ""
        }

        if {$from_create && $m_remoteMode && ![$item isa GridItemGroup]} {
            set info [$item getItemInfo]
            if {$m_liveVideo} {
                set cmd addGridFromLiveVideo
            } else {
                set cmd addGrid
            }
            eval $m_objGridGroupConfig startOperation \
            $cmd $m_groupId $m_snapshotId $info

            delete object $item
            return
        }

        lappend m_itemList $item

        setCurrentItem $item

        #puts "add item cluster= $itk_option(-cluster)"
        if {$itk_option(-cluster) != ""} {
            $itk_option(-cluster) setToolMode adjust
        } else {
            setToolMode adjust
            configure -showNotice 0
        }

        ### if in cluster, this will trigger hide notice
        updateRegisteredComponents numItem
    }
    public method removeItem { item } {
        if {$m_remoteMode} {
            if {![$item isa GridItemGroup]} {
                set gridId [$item getGridId]
                eval $m_objGridGroupConfig startOperation \
                deleteGrid $m_groupId $gridId
                return
            }
            set gridIdList [$item getMemberGridIdList]
            if {$gridIdList != ""} {
                eval $m_objGridGroupConfig startOperation \
                deleteGrid $m_groupId $gridIdList

                $item clearAllMember
            }
            ### go on delete the group
        }
        _remove_item $item
    }
    public method setCurrentItem { item {no_event 0} } {
        if {$m_currentItem != $item} {
            clearCurrentItem 1
            set m_currentItem $item
            $m_currentItem onSelected
            if {!$no_event} {
                #puts "update current_grid setCurrentItem to $item"
                updateRegisteredComponents current_grid
            }
            return 1
        } else {
            #puts "$item already current"
            return 0
        }
    }
    public method clearCurrentItem { {no_event 0} } {
        if {$itk_option(-cluster) != ""} {
            $itk_option(-cluster) clearCurrentItem 1
        } else {
            __clearCurrentItem
        }
        if {!$no_event} {
            #puts "update current_grid clearCurrentItem"
            updateRegisteredComponents current_grid
        }
    }
    public method __clearCurrentItem { } {
        if {$m_currentItem != ""} {
            ### give item a chance to do something.
            ### group item will remove itself.
            $m_currentItem onUnselected
            #puts "clear currentItem"

            set m_currentItem ""
        }
    }
    public method onItemChange { item }
    public method registerButtonCallback { motion release } {
        if {[isActive]} {
            set m_buttonCallbackMotion $motion
            set m_buttonCallbackRelease $release
        } else {
            clearButtonCallback
        }
    }
    private method clearButtonCallback { } {
        #puts "button callback cleared"
        set m_buttonCallbackMotion ""
        set m_buttonCallbackRelease ""
    }
    public method registerImageMotionCallback { motion } {
        set m_imageCallbackMotion $motion
    }
    private method clearImageMotionCallback { } {
        set m_imageCallbackMotion ""
    }
    public method getEnclosedItems { x1 y1 x2 y2 }
    public method getDisplayPixelSize { } {
        return [list $m_imageWidth $m_imageHeight]
    }
    public method getDisplayOrig { } {
        return $itk_option(-viewOrig) 
    }

    public method onItemClick { item row column }
    public method onItemRightClick { item row column } { }
    public method moveTo { item x y }

    private method allItemDeactive { } {
        foreach item $m_itemList {
            $item onSilence
        }
    }
    private method allItemActive { } {
        foreach item $m_itemList {
            $item onUnsilence
        }
    }
    protected method _remove_item { item } {
        #puts "_remove_item $item"
        if {$m_currentItem == $item} {
            set m_currentItem ""
            #puts "update current_grid in _remove_item $item"
            updateRegisteredComponents current_grid
        }
        set index [lsearch -exact $m_itemList $item]
        if {$index >= 0} {
            set m_itemList [lreplace $m_itemList $index $index]
        }
        #puts "delete object"
        delete object $item

        if {[llength $m_itemList] == 0 && $itk_option(-cluster) == ""} {
            configure -showNotice 1 -toolMode $m_lastAddMode
        }
        updateRegisteredComponents numItem
    }

    public method redrawTitle { }
    public method redrawNotice { }

    public method reset { } {
        #puts "resetting $this"
        foreach item $m_itemList {
            #puts "deleting $item"
            delete object $item
        }
        set m_itemList ""
        set m_currentItem ""
        #puts "update current_grid reset"
        updateRegisteredComponents current_grid

        $m_myCanvas delete all
        updateBeamDisplay

        set m_noticeId ""
        set m_titleId ""

        $m_rawImage blank
        $m_snapshot blank

        $m_myCanvas create image 0 0 \
        -image $m_snapshot \
        -anchor nw \
        -tags snapshot

        set m_drawImageOK 0
        if {$itk_option(-cluster) == ""} {
            configure -showNotice 1 -toolMode $m_lastAddMode
        }
        updateRegisteredComponents numItem
    }

    private method updateBeamDisplay { }

    constructor { args } {
        ::DCS::Component::constructor {
            toolMode     {getToolMode}
            numItem      {getNumberOfItem}
            current_grid {getCurrentGridId}
        }
    } {

        set m_deviceFactory [::DCS::DeviceFactory::getObject]

        set m_objGridGroupConfig \
        [$m_deviceFactory createOperation gridGroupConfig]

        set m_objGridGroupFlip [$m_deviceFactory createOperation gridGroupFlip]
        frame $itk_interior.ring
        ### need a ring so that we can set size of draw area
        itk_component add ring {
            frame $itk_interior.ring.ring2
        } {
        }

        set snapSite $itk_component(ring)

        itk_component add drawArea {
            canvas $snapSite.canvas \
            -xscrollcommand "$this onXScrollCommand" \
            -yscrollcommand "$this onYScrollCommand" \
        } {
        }
        pack $itk_component(drawArea) -expand 1 -fill both
        set m_myCanvas $itk_component(drawArea)

        itk_component add xBar {
            scrollbar $itk_interior.xbar \
            -orient horizontal \
            -command "$m_myCanvas xview"
        } {
        }

        itk_component add yBar {
            scrollbar $itk_interior.ybar \
            -orient vertical \
            -command "$m_myCanvas yview"
        } {
        }

        grid $itk_interior.ring   -row 0 -column 0 -sticky news
        grid $itk_component(xBar) -row 1 -column 0 -sticky we
        grid $itk_component(yBar) -row 0 -column 1 -sticky ns
        grid rowconfigure    $itk_interior 0 -weight 5
        grid columnconfigure $itk_interior 0 -weight 5

        registerComponent $m_myCanvas

        #set m_winID $m_myCanvas
        set m_winID $itk_interior
        bind $m_winID <Configure> "$this handleResize %W %w %h"

        $m_myCanvas config -scrollregion {0 0 352 240}

        set m_snapshot [image create photo -palette "256/256/256"]

        set imgID [$m_myCanvas create image 0 0 \
        -image $m_snapshot \
        -anchor nw \
        -tags snapshot]

        set m_rawImage [image create photo -palette "256/256/256"]

        eval itk_initialize $args
        if {$itk_option(-forL614)} {
            configure -toolMode add_l614
        }

        bind $m_myCanvas <Motion> "$this handleImageMotion %x %y"

        bind $m_myCanvas <B1-Motion> "$this handleButtonMotion %x %y"
        bind $m_myCanvas <ButtonPress-1> "$this handleButtonPress %x %y"
        bind $m_myCanvas <ButtonRelease-1> "$this handleButtonRelease %x %y"

        $m_myCanvas bind snapshot <Enter> "$this handleImageEnter %x %y"

        announceExist
        log_warning GridCanvas: $this
    }
    destructor {
        if {$m_objVideoOrig != ""} {
            $m_objVideoOrig unregister $this contents handleVideoOrigUpdate
        }
    }
}
body GridCanvas::registerVideoOrig { } {
    set camera [lindex $itk_option(-viewOrig) 10]
    registerVideoOrigExplicitly $camera
}
body GridCanvas::registerVideoOrigExplicitly { camera } {
    switch -exact -- $camera {
        sample {
            set stringName sampleVideoOrig
        }
        inline {
            set stringName inlineVideoOrig
        }
        default {
            return
        }
    }
    set obj [$m_deviceFactory createString $stringName]
    if {$obj == $m_objVideoOrig} {
        return
    }
    if {$m_objVideoOrig != ""} {
        #puts "$this unregisterd from $m_objVideoOrig"
        $m_objVideoOrig unregister $this contents handleVideoOrigUpdate
    }
    set m_objVideoOrig $obj
    if {$m_objVideoOrig != ""} {
        #puts "$this registerd to $m_objVideoOrig"
        $m_objVideoOrig register $this contents handleVideoOrigUpdate
    }
}
body GridCanvas::updateBeamPosition { } {
    set orig $itk_option(-viewOrig)
    if {[llength $orig] < 6} {
        puts "updateBeamPosition orig not ready"
        return
    }
    if {[llength $m_ctsVideoOrig] < 10} {
        puts "updateBeamPosition videoOrig not ready"
        return
    }
    foreach {x y z a h w - - beamY beamX -} $m_ctsVideoOrig break
    if {$m_liveVideo} {
        #### it will have the same values even after calculation.
        setCurrentBeamPosition $beamX $beamY
    } else {
        set pos [calculateProjectionFromSamplePosition $orig $x $y $z]
        foreach {dy dx} $pos break
        set cx [expr $dx + $beamX]
        set cy [expr $dy + $beamY]
        setCurrentBeamPosition $cx $cy
    }
}
body GridCanvas::autoZoomCenter { } {
    if {$m_currentItem != ""} {
        foreach {m_zoomCenterX m_zoomCenterY} [$m_currentItem getCenter] break
        return 1
    } else {
        set xx [$m_myCanvas xview]
        set yy [$m_myCanvas yview]
        foreach {x0 x1} $xx break
        foreach {y0 y1} $yy break
        set m_zoomCenterX [expr ($x0 + $x1) * 0.5]
        set m_zoomCenterY [expr ($y0 + $y1) * 0.5]
        return 0
    }
}
body GridCanvas::onItemClick { item row column } {
    set gridId [$item getGridId]
    eval $m_objGridGroupFlip startOperation \
    flip_node $m_groupId $gridId $row $column

}
body GridCanvas::moveTo { item x y } {
    set gridId [$item getGridId]
    if {$m_liveVideo} {
        set faceBeam 0
    } else {
        set faceBeam 1
    }
    eval $m_objGridGroupConfig startOperation \
    on_grid_move $m_groupId $gridId $x $y $faceBeam
}
body GridCanvas::update { } {
    if {$m_retryID != ""} {
        after cancel $m_retryID
        set m_retryID ""
    }
    updateSnapshot
}
body GridCanvas::updateSnapshot { } {
    if {$itk_option(-snapshot) == ""} {
        $m_rawImage blank
        $m_snapshot blank
        set m_drawImageOK 0
        #puts "jpgfile=={}"
        return
    }

    if {[catch {
        #image delete $m_rawImage
        #set m_rawImage [image create photo -palette "256/256/256"]
        $m_rawImage blank
        switch -exact -- $itk_option(-snapshotType) {
            data {
                $m_rawImage configure -file "" -data $itk_option(-snapshot)
            }
            file {
                $m_rawImage configure -file $itk_option(-snapshot)
            }
        }

        set m_rawWidth  [image width  $m_rawImage]
        set m_rawHeight [image height $m_rawImage]

        #puts "raw image size : $m_rawWidth $m_rawHeight"

        redrawImage
    } errMsg] == 1} {
        log_error failed to create image from jpg files: $errMsg
        puts "failed to create image from jpg files: $errMsg"
        set m_drawImageOK 0
        set m_retryID [after 1000 "$this update"]
    }
}
body GridCanvas::redrawImage { } {
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

    set oldImageWidth  $m_imageWidth
    set oldImageHeight $m_imageHeight

    set m_imageWidth  [expr int($m_rawWidth  * $m_zoom)]
    set m_imageHeight [expr int($m_rawHeight * $m_zoom)]

    #puts "snapshot image size: $m_imageWidth $m_imageHeight"

    if {$m_zoom >= 0.75} {
        imageResizeBilinear     $m_snapshot $m_rawImage $m_imageWidth
    } else {
        imageDownsizeAreaSample $m_snapshot $m_rawImage $m_imageWidth 0 1
    }

    $m_myCanvas config -scrollregion [list 0 0 $m_imageWidth $m_imageHeight]

    if {$m_imageWidth != $oldImageWidth || $m_imageHeight != $oldImageHeight} {
        pack forget $itk_component(ring)
        eval pack $itk_component(ring) $itk_option(-packOption)
        pack propagate $itk_component(ring) 0
        $itk_component(ring) configure \
        -width  [expr $m_imageWidth + 2] \
        -height [expr $m_imageHeight + 2]
    }
    set m_drawImageOK 1
}
body GridCanvas::handleNewOutput {} {
    #puts "handleNewOutput: $_gateOutput"
    if { $_gateOutput == 0 } {
        set m_dcsCursor watch
    } else {
        set m_dcsCursor [. cget -cursor]
    }
    updateBubble
}
body GridCanvas::getEnclosedItems { x1 y1 x2 y2 } {
    if {$x1 > $x2} {
        set tmp $x1
        set x1 $x2
        set x2 $tmp
    }
    if {$y1 > $y2} {
        set tmp $y1
        set y1 $y2
        set y2 $tmp
    }

    #puts "getEncosedItems $x1 $y1 $x2 $y2"
    set result ""
    foreach item $m_itemList {
        set box [$item getBBox]
        foreach {bx1 by1 bx2 by2} $box break
        if {$bx1 >= $x1 && $by1 >= $y1 && $bx2 <= $x2 && $by2 <= $y2} {
            lappend result $item
        }
    }
    #puts "result=$result"
    return $result
}
body GridCanvas::onItemChange { item } {
    if {[$item isa GridItemGroup]} {
        set idAndInfoList [$item getMemberInfoList]
        eval $m_objGridGroupConfig startOperation \
        modifyGrid $m_groupId $idAndInfoList
    } else {
        set gridId [$item getGridId]
        set info   [$item getItemInfo]
        $m_objGridGroupConfig startOperation \
        modifyGrid $m_groupId $gridId $info
    }
}
body GridCanvas::redrawTitle { } {
    set xx [$m_myCanvas xview]
    set yy [$m_myCanvas yview]
    foreach {x0 x1} $xx break
    foreach {y0 y1} $yy break

    set tx0 [expr $m_imageWidth  * $x0]
    set ty0 [expr $m_imageHeight * $y0]
    if {$m_titleId == ""} {
        set m_titleId [$m_myCanvas create text $tx0 $ty0 \
        -fill white \
        -anchor nw \
        -font "helvetica -16 bold" \
        -text $itk_option(-title) \
        ]
    } else {
        $m_myCanvas coords $m_titleId $tx0 $ty0
        $m_myCanvas itemconfigure $m_titleId -text $itk_option(-title)
    }
}
body GridCanvas::redrawNotice { } {
    if {!$itk_option(-showNotice) || $m_templateItem != ""} {
        if {$m_noticeId != ""} {
            $m_myCanvas delete $m_noticeId
            set m_noticeId ""
        }
        return
    }

    set xx [$m_myCanvas xview]
    set yy [$m_myCanvas yview]
    foreach {x0 x1} $xx break
    foreach {y0 y1} $yy break

    ### center
    set nx [expr $m_imageWidth  * ($x0 + $x1) / 2.0]
    set ny [expr $m_imageHeight * ($y0 + $y1) / 2.0]

    if {$m_noticeId == ""} {
        set m_noticeId [$m_myCanvas create text $nx $ny \
        -fill red \
        -font "helvetica -24 bold" \
        -text "Please create grid with tools above" \
        ]
    } else {
        $m_myCanvas coords $m_noticeId $nx $ny
    }
}

body GridCanvas::updateBeamDisplay { } {
    $m_myCanvas delete beam_info

    if {$m_beamX <= 0 || $m_beamX >= 1 || $m_beamY <= 0 || $m_beamY >= 1} {
        puts "$this beam position not valid yet"
        return
    }

    set xPixel [expr $m_beamX * $m_imageWidth]
    set yPixel [expr $m_beamY * $m_imageHeight]

    switch -exact -- $itk_option(-showBeamInfo) {
        cross_only -
        both {
            $m_myCanvas create line 0 $yPixel $m_imageWidth $yPixel \
            -tags beam_info \
            -fill $GridGroupColor::COLOR_BEAM \
            -width 1
            $m_myCanvas create line $xPixel 0 $xPixel $m_imageHeight \
            -tags beam_info \
            -fill $GridGroupColor::COLOR_BEAM \
            -width 1
        }
    }
    switch -exact -- $itk_option(-showBeamInfo) {
        box_only -
        both {
            foreach {wMM hMM color} $m_beamsizeInfo break
            foreach {w h} [calculateProjectionBoxFromBox \
            $itk_option(-viewOrig) $wMM $hMM] break

            set wPixelHalf [expr $w * $m_imageWidth  / 2.0]
            set hPixelHalf [expr $h * $m_imageHeight / 2.0]
            #puts "$this draw beamsize box: mm: $wMM $hMM w=$w h=$h"
            #puts "image size=$m_imageWidth $m_imageHeight"

            set x0 [expr $xPixel - $wPixelHalf]
            set x1 [expr $xPixel + $wPixelHalf]
            set y0 [expr $yPixel - $hPixelHalf]
            set y1 [expr $yPixel + $hPixelHalf]

            $m_myCanvas create rectangle $x0 $y0 $x1 $y1 \
            -tags beam_info \
            -outline $GridGroupColor::COLOR_BEAM \
            -width 1
        }
    }
}

class GridCanvasCluster {
    inherit DCS::Component

    public method addCanvas { c }

    ### the GridCanvas has following interface
    public method getToolMode { } { return $m_toolMode }
    public method setToolMode { mode }
    public method clearCurrentItem { {no_event 0} }
    public method deleteSelected { }
    public method zoomIn { }
    public method zoomOut { }

    public method getCurrentGridId { } {
        foreach c $m_canvasList {
            set id [$c getCurrentGridId]
            if {$id >=0} {
                return $id
            }
        }
        return -1
    }
    public method handleCurrentGridChange { - ready_ - - - } {
        ## pass up
        updateRegisteredComponents current_grid
    }

    public method handleNumItemChange { - ready_ - num - } {
        set totalItem 0
        foreach c $m_canvasList {
            set totalItem [expr $totalItem + [$c getNumberOfItem]]
        }
        if {$totalItem == 0} {
            set showNotice 1
        } else {
            set showNotice 0
        }
        foreach c $m_canvasList {
            $c configure -showNotice $showNotice
        }
    }

    public method handleXScrollCommand { starter args } {
        set left [lindex $args 0]
        if {$left == $m_currentLeft} {
            return
        }
        set m_currentLeft $left
        foreach c $m_canvasList {
            if {$c != $starter} {
                $c xview moveto $m_currentLeft
            }
        }
    }

    constructor { } {
        ::DCS::Component::constructor {
            toolMode        getToolMode
            current_grid    getCurrentGridId
        }
    } {
        announceExist
    }

    protected variable m_canvasList ""
    protected variable m_toolMode ""
    protected variable m_currentLeft -1
}
body GridCanvasCluster::addCanvas { c } {
    #puts "cluster adding $c"
    lappend m_canvasList $c

    $c configure -cluster $this
    $c configure -xscrollcommand "$this handleXScrollCommand $c"
    $c register $this numItem handleNumItemChange
    $c register $this current_grid handleCurrentGridChange
    if {$m_toolMode == ""} {
        set m_toolMode [$c getToolMode]
        updateRegisteredComponents toolMode
    } else {
        $c setToolMode $m_toolMode
    }
}
body GridCanvasCluster::setToolMode { mode } {
    foreach c $m_canvasList {
        $c setToolMode $mode
    }
    set m_toolMode $mode
    updateRegisteredComponents toolMode
}
body GridCanvasCluster::clearCurrentItem { {no_event 0} } {
    foreach c $m_canvasList {
        $c __clearCurrentItem
    }
    if {!$no_event} {
        #puts "update current_grid in cluster clearCurrentItem"
        updateRegisteredComponents current_grid
    }
}
body GridCanvasCluster::deleteSelected { } {
    foreach c $m_canvasList {
        $c deleteSelected
    }
}
body GridCanvasCluster::zoomIn { } {
    set first_c [lindex $m_canvasList 0]
    if {$first_c == ""} {
        return
    }
    set currentZoom [$first_c getCurrentZoom]
    set desiredZoom [expr $currentZoom * 2.0]

    set gotCurrent 0
    set centerX 0.5
    foreach c $m_canvasList {
        if {[$c autoZoomCenter]} {
            set centerX [$c getZoomCenterX]
            set gotCurrent 1
            #puts "got zoomCenterX=$centerX from $c"
        }
    }
    if {!$gotCurrent} {
        set centerX [$first_c getZoomCenterX]
    }

    foreach c $m_canvasList {
        $c setZoomCenterX $centerX
        $c zoom $desiredZoom
    }
}
body GridCanvasCluster::zoomOut { } {
    set first_c [lindex $m_canvasList 0]
    if {$first_c == ""} {
        return
    }
    set currentZoom [$first_c getCurrentZoom]
    set desiredZoom [expr $currentZoom / 2.0]
    foreach c $m_canvasList {
        $c zoom $desiredZoom
    }
}

### user can switch relation between snapshot and this display,
### To avoid frequent unregister/register, we use a map to 
### deal with this relationship. No register.
class GridSnapshotDisplay {
    inherit GridCanvas

    public method setGroupId { groupId } { set m_groupId $groupId }
    public method getSnapshotId { } { return $m_snapshotId }

    public method refresh { objSnapshotImage }
    public method addGrid { objGrid }
    public method deleteGrid { gridId }
    public method updateGrid { objGrid }
    public method setNode { id index status }
    public method setMode { id status }
    public method zoomOnGrid { objGrid }
    public method adjustGrid { id param }
    public method setCurrentGrid { id }

    ### snapshotImageId
    protected variable m_gridIdMap ""

    protected common SHAPE2CLASS
    protected {
        set SHAPE2CLASS [dict create \
        rectangle GridItemRectangle \
        oval      GridItemOval \
        line      GridItemLine \
        polygon   GridItemPolygon \
        l614      GridItemL614 \
        ]
    }
    constructor { liveVideo args } {
        eval GridCanvas::constructor $args
    } {
        set m_remoteMode 1
        set m_liveVideo $liveVideo
    }
}
### obj isa GridGroup::SnapshotImage
body GridSnapshotDisplay::refresh { obj } {
    reset
    
    if {!$m_liveVideo} {
        set file [$obj getFile]
        configure \
        -snapshot $file \
        -viewOrig [$obj getOrig] \
        -title    phi=[$obj getLabel]

        ##redraw snapshot
        update
    } else {
        configure \
        -title " live video"
        if {$itk_option(-snapshot) == ""} {
            set file [$obj getFile]
            configure -snapshot $file
        }
        if {$itk_option(-viewOrig) == ""} {
            configure -viewOrig [$obj getOrig]
        }
    }

    set m_camera [$obj getCamera]

    set m_snapshotId [$obj getId]
    set m_gridIdMap [dict create]
    set rasterList [::gCurrentGridGroup getGridList]
    #puts "for $obj gridList: $rasterList"
    foreach raster $rasterList {
        set gridId [$raster getId]
        set info     [$raster getGeoProperties]
    
        set geo [lindex $info 1]
        set shape [dict get $geo shape]
        if {[catch {
            dict get $SHAPE2CLASS $shape
        } class]} {
            puts "ignred bad shape $shape"
            continue
        }
        set item [${class}::instantiate $m_myCanvas $this $gridId $info]
        dict set m_gridIdMap $gridId $item
    }
}
body GridSnapshotDisplay::addGrid { raster } {
    set gridId [$raster getId]
    set info     [$raster getGeoProperties]
    
    set geo [lindex $info 1]
    set shape [dict get $geo shape]
    set class [dict get $SHAPE2CLASS $shape]
    set item [${class}::instantiate $m_myCanvas $this $gridId $info]
    dict set m_gridIdMap $gridId $item
}
body GridSnapshotDisplay::updateGrid { raster } {
    set rasterID [$raster getId]
    set info     [$raster getGeoProperties]

    set item [dict get $m_gridIdMap $rasterID]
    $item updateFromInfo $info
}
body GridSnapshotDisplay::setCurrentGrid { id } {
    #puts "$this calling setCurrentGrid $id"
    set item [dict get $m_gridIdMap $id]
    #puts "calling setCurrentItem $item"
    ### this is called by gCurrentGridGroup, no event
    setCurrentItem $item 1
}
body GridSnapshotDisplay::setNode { gridId nodeIdx nodeStatus } {
    set item [dict get $m_gridIdMap $gridId]
    $item setNode $nodeIdx $nodeStatus
}
body GridSnapshotDisplay::setMode { gridId gridStatus } {
    set item [dict get $m_gridIdMap $gridId]
    $item setMode $gridStatus
}
body GridSnapshotDisplay::deleteGrid { gridId } {
    set item [dict get $m_gridIdMap $gridId]
    _remove_item $item
}
body GridSnapshotDisplay::adjustGrid { gridId  param } {
    set item [dict get $m_gridIdMap $gridId]
    $item adjustItem $param
}

GridGroup::GridGroup4BluIce gCurrentGridGroup

class GridDisplayWidget {
    inherit ::itk::Widget ::GridGroup::VideoImageDisplayHolder

    ##### implement SnapshotImageDisplayHolder interface
    public method showDisplays { number }
    public method clearCurrentGrid { } {
        $m_cluster clearCurrentItem
    }
    public method setToolMode { mode } {
        set m_toolByExternal 1
        $m_cluster setToolMode $mode

        if {[string range $mode 0 3] == "add_"} {
            clearCurrentGrid
        }
        set m_toolByExternal 0
    }

    public method getCurrentGridId { } {
        return [$m_cluster getCurrentGridId]
    }
    public method getToolMode { } {
        return [$m_cluster getToolMode]
    }

    public method handleCurrentGridChange { - ready_ - - - } {
        ## pass up
        updateRegisteredComponents current_grid
    }
    public method handleToolModeChange { - ready_ - - - } {
        if {!$m_toolByExternal} {
            updateRegisteredComponents tool_mode
        }
    }

    protected variable m_cluster ""
    protected variable m_toolByExternal 0
    protected variable m_deviceFactory ""

    #### snapshot_displayed is for the snapshot list widget
    constructor { args } {
        DCS::Component::constructor {
            current_grid        getCurrentGridId
            tool_mode           getToolMode
            snapshot_displayed  getDisplayedSnapshotIdList
        }
    } {
        set m_deviceFactory [::DCS::DeviceFactory::getObject]

        set m_cluster [GridCanvasCluster ::\#auto]

        itk_component add rc0 {
            GridSnapshotDisplay $itk_interior.rc0 0 \
            -systemIdleOnly 0
        } {
            keep -activeClientOnly
            keep -forL614
        }

        itk_component add ssList {
            GridSnapshotListView $itk_interior.sslist
        } {
        }

        itk_component add rc1 {
            GridSnapshotDisplay $itk_interior.rc1 0 \
            -systemIdleOnly 0
        } {
            keep -activeClientOnly
            keep -forL614
        }

        $m_cluster addCanvas $itk_component(rc0)
        $m_cluster addCanvas $itk_component(rc1)

        itk_component add cc {
            GridCanvasControl $itk_interior.cc \
            -canvas $m_cluster
        } {
            keep -forL614
        }

        grid $itk_component(cc)     -row 0 -column 0 -sticky we
        grid $itk_component(rc0)    -row 1 -column 0 -sticky news
        grid $itk_component(ssList) -row 2 -column 0 -sticky we
        grid $itk_component(rc1)    -row 3 -column 0 -sticky news
        grid rowconfigure $itk_interior 1 -weight 10
        grid rowconfigure $itk_interior 3 -weight 10
        grid columnconfigure $itk_interior 0 -weight 10

        set m_maxNumDisplay 2
        set m_displayList [list $itk_component(rc0) $itk_component(rc1)]

        eval itk_initialize $args

        if {[gCurrentGridGroup getId] < 0} {
            gCurrentGridGroup switchGroupNumber 0 1
        }
        gCurrentGridGroup registerImageDisplayWidget $this

        $m_cluster register $this current_grid handleCurrentGridChange
        $m_cluster register $this toolMode      handleToolModeChange

        $this register $itk_component(ssList) snapshot_displayed handleDisplayedSSListUpdate
    }
    destructor {
        gCurrentGridGroup unregisterImageDisplayWidget $this
    }
}
body GridDisplayWidget::showDisplays { number } {
    #puts "showDisplay $number current=$m_numDisplayed"
    if {$number < 0} {
        set number 0
    }
    set max $m_maxNumDisplay
    if {$number > $max} {
        set number $max
    }
    if {$number == $m_numDisplayed} {
        return
    }
    if {$number > $m_numDisplayed} {
        for {} {$m_numDisplayed < $number} {incr m_numDisplayed} {
            set row [expr $m_numDisplayed + 1]
            if {$row >= 2} {
                ### jump ssList
                incr row
            }

            #puts "showing rc$m_numDisplayed"
            grid $itk_component(rc$m_numDisplayed) \
            -column 0 \
            -row $row \
            -sticky news
        }
    } else {
        for { } {$m_numDisplayed > $number } {incr m_numDisplayed -1} {
            set id [expr $m_numDisplayed - 1]
            #puts "removing rc$id"
            grid forget $itk_component(rc$id)
        }
    }
}

class GridSnapshotListDataHolder {
    inherit DCS::Component

    public method setIndex { index } {
        set m_atTop 0

        set m_index $index
        set ss [lindex $m_snapshotListInfo $m_index]
        foreach {label id gridNameList} $ss break
        set m_exists 1
        set m_gridNameList $gridNameList
        if {$id == $m_topId} {
            set m_atTop 1
        }
        updateRegisteredComponents exists
        updateRegisteredComponents grid_name_list
        updateRegisteredComponents at_top
    }

    public method setPhi { phi } {
        #puts "setPhi to {$phi}"
        if {![string is double -strict $phi]} {
            return
        }

        set m_phi $phi
        update
    }
    public method getId { } {
        if {$m_index < 0} {
            return -1
        }
        set ss [lindex $m_snapshotListInfo $m_index]
        set id [lindex $ss 1]

        return $id
    }

    public method setSnapshotList { ssListInfo } {
        foreach {m_snapshotListInfo m_displayedList} $ssListInfo break
        set m_topId [lindex $m_displayedList 0]
        #puts "set topId to $m_topId"
        update
    }

    public method getExists { }       { return $m_exists }
    public method getGridNameList { } { return $m_gridNameList }
    public method getAtTop { }        { return $m_atTop }

    private method update { }

    private variable m_phi 0
    private variable m_snapshotListInfo ""
    private variable m_index -1
    private variable m_topId -1
    private variable m_displayedList ""

    private variable m_exists 0
    private variable m_gridNameList ""
    private variable m_atTop 0

    constructor { args } {
        DCS::Component::constructor {
            at_top         {getAtTop}
            exists         {getExists}
            grid_name_list {getGridNameList}
        }
    } {
        announceExist
    }
}
body GridSnapshotListDataHolder::update { } {
    set m_index -1
    set m_exists 0
    set m_gridNameList ""
    set m_atTop 0

    set i -1
    foreach ss $m_snapshotListInfo {
        incr i
        foreach {label id gridNameList} $ss break
        if {abs($label - $m_phi) < 1.0} {
            #puts "found at $i label=$label"
            set m_index $i
            set m_exists 1
            #puts "set gridNamelist to $gridNameList"
            set m_gridNameList $gridNameList
            #puts "id=$id top=$m_topId"
            if {$id == $m_topId} {
                set m_atTop 1
            }
            break
        }
    }
    updateRegisteredComponents exists
    updateRegisteredComponents grid_name_list
    updateRegisteredComponents at_top
}

class GridSnapshotListView {
    inherit ::itk::Widget

    public method handlePhiChange { - ready_ - phi_ - } {
        ### this will trigger some attribute change and
        ### in turn enable/disable some buttons
        if {!$ready_} {
            return
        }
        $m_dataHolder setPhi [lindex $phi_ 0]
    }

    public method handleSSListUpdate { - ready_ - contents_ - }
    public method handleDisplayedSSListUpdate { - ready_ - contents_ - }

    public method moveToTop { } {
        set ssId [$m_dataHolder getId]
        gCurrentGridGroup moveSnapshotToTop $ssId
    }
    public method deleteSnapshot { } {
        set ssId [$m_dataHolder getId]
        $m_objOperation startOperation deleteSnapshot 0 $ssId
    }
    public method takeSnapshot { } {
        set phi [lindex [$itk_component(phi) get] 0]
        $m_objOperation startOperation addSnapshot 0 $phi
    }

    public method setValueByIndex { index value } {
        $m_dataHolder setIndex $index
        $itk_component(phi) setValue $value 1
    }

    private variable m_objOperation ""
    private variable m_dataHolder ""
    private variable m_ssList ""
    private variable m_displayedList ""
    private variable m_groupNum -1

    constructor { args } {
        set m_dataHolder [GridSnapshotListDataHolder ::\#auto]

        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objOperation  [$deviceFactory createOperation gridGroupConfig]

        itk_component add phi {
            DCS::MotorViewEntry $itk_interior.phi \
            -device ::device::gonio_phi \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Phi: " \
            -entryWidth 10 \
            -entryJustify right \
            -units "deg" \
            -unitsList "deg" \
            -entryType float \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1 \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -honorStatus 0
        } {
        }

        itk_component add topSS {
            DCS::Button $itk_interior.topSS \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -text "move to Top" \
            -command "$this moveToTop"
        } {
        }

        itk_component add addSS {
            DCS::Button $itk_interior.addSS \
            -activeClientOnly 1 \
            -systemIdleOnly 0 \
            -text "New Snapshot" \
            -command "$this takeSnapshot"
        } {
        }

        itk_component add deleteSS {
            DCS::Button $itk_interior.deleteSS \
            -activeClientOnly 1 \
            -systemIdleOnly 0 \
            -text "Delete Snapshot" \
            -command "$this deleteSnapshot"
        } {
        }
        $itk_component(topSS) addInput \
        "$m_dataHolder exists 1 {snapshot not exists}"
        $itk_component(topSS) addInput \
        "$m_dataHolder at_top 0 {already at top}"

        $itk_component(addSS) addInput \
        "$m_dataHolder exists 0 {snapshot already exists}"

        $itk_component(deleteSS) addInput \
        "$m_dataHolder exists 1 {snapshot not exists}"
        $itk_component(deleteSS) addInput \
        "$m_dataHolder grid_name_list {} {supporting device}"

        pack $itk_component(phi) -side left
        pack $itk_component(topSS) -side left
        pack $itk_component(addSS) -side left
        pack $itk_component(deleteSS) -side left

        eval itk_initialize $args
        gCurrentGridGroup register $this snapshot_list handleSSListUpdate

        #$itk_component(topSS) configure \
        #-activeClientOnly 0 \
        #-systemIdleOnly 0
        
        #$itk_component(phi) configure \
        #-activeClientOnly 0 \
        #-systemIdleOnly 0

        $itk_component(phi) register $this -value handlePhiChange
    }
    destructor {
        gCurrentGridGroup unregister $this snapshot_list handleSSListUpdate
    }
}
body GridSnapshotListView::handleSSListUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    #puts "SSListUpdate: $contents_"

    set m_ssList $contents_
    $m_dataHolder setSnapshotList [list $m_ssList $m_displayedList]

    ### regenerate menu
    set mnList ""
    set i -1
    foreach ss $m_ssList {
        incr i
        foreach {phi id nameList} $ss break
        set display $phi
        if {$nameList != ""} {
            append display " {$nameList}"
        }
        lappend mnList [list $display [list $this setValueByIndex $i $phi]]
    }
    $itk_component(phi) configure \
    -menuChoices "" \
    -extraMenuChoices $mnList

    set ll [llength $m_ssList]
    if {$ll > 0} {
        setValueByIndex $i $phi
    }
}
body GridSnapshotListView::handleDisplayedSSListUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    #puts "DisplayedSSListUpdate: $contents_"

    set m_displayedList $contents_
    $m_dataHolder setSnapshotList [list $m_ssList $m_displayedList]
}

class GridVideoWidget {
    inherit ::itk::Widget ::GridGroup::VideoImageDisplayHolder

	itk_option define -imageUrl imageUrl ImageUrl  "" {
	    restartUpdates 0
    }

	itk_option define -updatePeriod updatePeriod UpdatePeriod 1000
	itk_option define -firstUpdateWait firstUpdateWait FirstUpdateWait 5000
	itk_option define -retryPeriod retryPeriod RetryPeriod 30000
	itk_option define -videoParameters videoParameters VideoParameters {}
	itk_option define -videoEnabled videoEnabled VideoEnabled 0

    ##### implement SnapshotImageDisplayHolder interface
    public method showDisplays { number }
    public method clearCurrentGrid { } {
        $itk_component(rc0) clearCurrentItem
    }
    public method setToolMode { mode } {
        set m_toolByExternal 1
        $itk_component(rc0) setToolMode $mode

        if {[string range $mode 0 2] == "add"} {
            clearCurrentGrid
        }
        set m_toolByExternal 0
    }

    public method getCurrentGridId { } {
        return [$itk_component(rc0) getCurrentGridId]
    }
    public method getToolMode { } {
        return [$itk_component(rc0) getToolMode]
    }
    public method handleCurrentGridChange { - ready_ - - - } {
        ## pass up
        updateRegisteredComponents current_grid
    }
    public method handleToolModeChange { - ready_ - - - } {
        ### pass up
        if {!$m_toolByExternal} {
            updateRegisteredComponents tool_mode
        }
    }

    protected method getDisplay { displayIndex }

    ### from Video
	public method startUpdate
	public method finishUpdate
	public method addChildVisibilityControl
	public method handleParentVisibility
	public method restartUpdates
	private method cancelUpdates
    private method drawImage { {skipLoad 0} } {
        $itk_component(rc0) configure \
        -snapshotType data \
        -snapshot $_imageData
    }
	#add some private variables which allow the video stream
	#  to not update when the visibility is not right
	protected variable _visibility 1

	private variable _visibilityTrigger ""

	private variable _requesting 0
	private variable _fastUpdate 0
	private variable _encodingCalled 0

	protected variable m_afterID ""
    public variable _imageData ""
    private variable _token ""

    protected variable m_deviceFactory ""

    protected variable m_toolByExternal 0

    constructor { args } {
        DCS::Component::constructor {
            current_grid getCurrentGridId
            tool_mode    getToolMode
            snapshot_displayed  getDisplayedSnapshotIdList
        }
    } {
        set m_deviceFactory [::DCS::DeviceFactory::getObject]

        itk_component add rc0 {
            GridSnapshotDisplay $itk_interior.rc0 1 \
            -systemIdleOnly 0
        } {
            keep -activeClientOnly
            keep -forL614
        }

        itk_component add cc {
            GridCanvasControl $itk_interior.cc \
            -canvas $itk_component(rc0)
        } {
            keep -forL614
        }

        grid $itk_component(cc)     -row 0 -column 0 -sticky we
        grid $itk_component(rc0)    -row 1 -column 0 -sticky news
        grid rowconfigure $itk_interior 1 -weight 10
        grid columnconfigure $itk_interior 0 -weight 10

        set m_maxNumDisplay 1
        set m_displayList [list $itk_component(rc0)]

        eval itk_initialize $args

        if {[gCurrentGridGroup getId] < 0} {
            gCurrentGridGroup switchGroupNumber 0 1
        }

        if {[gCurrentGridGroup getSnapshotImageList] == ""} {
            set noSnapshotYet 1
        } else {
            set noSnapshotYet 0
        }

        set camera [gCurrentGridGroup getDefaultCamera]
        switch -exact -- $camera {
            sample {
                configure -imageUrl [::config getImageUrl 1]
            }
            inline {
                configure -imageUrl [::config getImageUrl 5]
            }
            default {
                log_error not supported camera $camera
                puts "camera {$camera} not supported, quit"
                exit
            }
        }
        if {$noSnapshotYet} {
            $itk_component(rc0) registerVideoOrigExplicitly $camera
        }

        gCurrentGridGroup registerImageDisplayWidget $this

        $itk_component(rc0) register $this current_grid handleCurrentGridChange
        $itk_component(rc0) register $this toolMode handleToolModeChange

        log_warning gridVideoView: $this
    }
    destructor {
        cancelUpdates
        gCurrentGridGroup unregisterImageDisplayWidget $this
    }
}
body GridVideoWidget::showDisplays { number } {
    set m_numDisplayed 1
}
body GridVideoWidget::getDisplay { displayIndex } {
    return $itk_component(rc0)
}

body GridVideoWidget::startUpdate {} {

	#guard against no Img Library
	if { ! [ImgLibraryAvailable] } return

    cancelUpdates

	if { ! $_requesting && $itk_option(-imageUrl) != ""} { 
		if { $_visibility && $itk_option(-videoEnabled) } {
			#puts "VIDEO $this Visible"
			
            if {$_token != ""} {
                catch {http::cleanup $_token}
                set _token ""
            }

			# grab the next image from the video server
			if {[catch {
                http::geturl ${itk_option(-imageUrl)}${itk_option(-videoParameters)}&size=large \
                -binary 1 \
                -timeout 10000 \
			    -command "$this finishUpdate"
            } _token]} {
				set _requesting 0
                log_error updating video: $_token
                puts "updating video: $_token"
                puts "imageUrl: $itk_option(-imageUrl)"

                set _token ""
				
                #here is for switch tabs or open bluice while server if offline
                restartUpdates $itk_option(-retryPeriod)
                puts "VIDEO: retry after $itk_option(-retryPeriod) seconds"
			} else {
			    set _requesting 1
            }

		} else {
		}
	} else {
		#puts "VIDEO ********** already requesting ************"
	}
}


body GridVideoWidget::finishUpdate { token } {
	#puts "VIDEO: finishUpdate: $_requesting "
	set _requesting 0

    set status [http::status $token]
    if {$status != "ok"} {
        puts "VIDEO: geturl status not ok: $status"
        restartUpdates $itk_option(-retryPeriod)
        puts "VIDEO: retry after $itk_option(-retryPeriod) seconds"
        return
    }
	# convert the image encoding to standard Tcl encoding
	if { [catch { set _imageData [http::data $token] } errorResult ] } {
		puts "VIDEO: got error $errorResult"
	}
	
    if { !$_encodingCalled } {
        set _imageData [encoding convertto iso8859-1 $_imageData]
        set _encodingCalled 1
    }


    #puts "drawImage to grid"
    set failed 0
    if {[catch drawImage errMsg]} {
        puts "drawImage error: $errMsg"
        set failed 1
    }
	
	# schedule the next update of the video image
	#set m_afterID [after $itk_option(-updatePeriod) "$this startUpdate"]

    restartUpdates $itk_option(-updatePeriod)
}

configbody GridVideoWidget::updatePeriod {
	restartUpdates 0
}

configbody GridVideoWidget::videoEnabled {
	restartUpdates 0
}

configbody GridVideoWidget::firstUpdateWait {
	
	# schedule first update
	restartUpdates $itk_option(-firstUpdateWait)
}

body GridVideoWidget::cancelUpdates {} {
	if { $m_afterID != ""} {
		# cancel the currently scheduled update of the video

		#puts "VIDEO: AFTER $m_afterID"

		after cancel $m_afterID
        set m_afterID ""
	} 
}

body GridVideoWidget::restartUpdates { time } {
    #puts "video restarting $time"
    cancelUpdates

	# schedule an update of the video immediately
	set m_afterID [after $time "$this startUpdate"]
	#puts "VIDEO restartUpdates $m_afterID"
}

body GridVideoWidget::addChildVisibilityControl { widget attribute visibleTrigger } {
	
	set _visibilityTrigger $visibleTrigger
	
	::mediator register $this ::$widget $attribute handleParentVisibility
}


body GridVideoWidget::handleParentVisibility { - targetReady - value -} {
	
	if { $targetReady == 0 } {
		set _visibility 0
	} elseif { $value != $_visibilityTrigger } {
		set _visibility 0
	} else {
		set _visibility 1
	    set _requesting 0
		restartUpdates 0
	}
}

class GridInputView {
    inherit ::itk::Widget DCS::Component

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -forL614 forL614 ForL614 1

    ### for buttons.
    public method deleteThisRun { } {
        $m_objGridGroupConfig startOperation deleteGrid \
        $m_groupId $m_gridId
    }
    public method setToDefaultDefinition { } {
        $m_objGridGroupConfig startOperation default_grid_parameter \
        $m_groupId $m_gridId
    }
    public method updateDefinition { } {
        $m_objGridGroupConfig startOperation update_grid_parameter \
        $m_groupId $m_gridId
    }
    public method resetDefinition { } {
        $m_objGridGroupConfig startOperation resetGrid \
        $m_groupId $m_gridId
    }

    public method setField { name value } {
        if {!$m_ready} {
            return
        }

        ### remove focus from the field, so that it will not set again.
        if {$name != "directory"} {
            ### directory need dropdown menu
            focus $itk_interior
        }

        #puts "setField $name {$value}"

        set param [dict create $name $value]

        if {$m_gridId >= 0} {
            switch -exact -- $name {
                cell_width -
                cell_height {
                    ### try snapshot GUI first.
                    ### they need to send the whole matrix.
                    if {![gCurrentGridGroup adjustCurrentGrid $param]} {
                        log_error cell size must adjust with image display.

                        refreshDisplay
                        return
                    }
                }
                default {
                    $m_objGridGroupConfig startOperation modifyParameter \
                    $m_groupId $m_gridId $param
                }
            }
        } else {
            switch -exact -- $name {
                shape {
                    gCurrentGridGroup setWidgetToolMode add_${value}
                }
            }
        }
        set contents [$m_objLatestUserSetup getContents]
        set dd [eval dict create $contents]

        switch -exact -- $name {
            prefix -
            directory {
                set lb [gCurrentGridGroup getCurrentGridLabel]
                if {$lb == ""} {
                    ## no current grid
                    ### this will not increase the counter.
                    ### in fact, there is no counter.
                    set lb [gCurrentGridGroup getNextGridId]
                }
                set l_lb [string length $lb]
                set l_v  [string length $value]
                if {$l_v >= $l_lb} {
                    set start [expr $l_v - $l_lb]
                    set tail [string range $value $start end]
                    if {$tail == $lb} {
                        set head ""
                        if {$l_v > $l_lb} {
                            set end [expr $l_v - $l_lb - 1]
                            set head [string range $value 0 $end]
                        }
                        set value ${head}GRID_LABEL
                    } 
                }
            }
        }

        dict set dd $name $value
        $m_objLatestUserSetup sendContentsToServer $dd
    }

    public method handleGridUpdate { - ready_ - contents_ - }

    private method refreshDisplay { }

    private common COMPONENT2KEY [list \
    fileRoot     prefix \
    directory    directory \
    shape        shape \
    cell_size    {cell_width cell_height} \
    beam_size    {beam_width beam_height collimator} \
    exposureTime time \
    delta        delta \
    distance     distance \
    beamStop     beam_stop \
    attenuation  attenuation \
    processing   processing \
    firstStill   first_single_shot \
    firstAtt     first_attenuation \
    numPhiShot   num_phi_shot \
    endStill     end_single_shot \
    endAtt       end_attenuation \
    videoShot    video_snapshot \
    ]

    private variable m_ready 0
    private variable m_objGridGroupConfig ""
    private variable m_objLatestUserSetup ""
    private variable m_groupId -1
    private variable m_snapId -1
    private variable m_gridId -1
    private variable m_d_userSetup ""

    private common PADY 2

    constructor { args} {
        global gMotorDistance
        global gMotorBeamStop
        global gMotorEnergy

        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        set m_objLatestUserSetup \
        [$deviceFactory createString latest_raster_user_setup]

        set ring $itk_interior

        itk_component add summary {
            label $ring.s
        } {}

        # make a frame of control buttons
        itk_component add buttonsFrame {
            frame $ring.bf 
        } {}
        set buttonSite $itk_component(buttonsFrame)

        itk_component add defaultButton {
            DCS::Button $buttonSite.def \
            -text "Default" \
            -width 5 \
            -pady 0 \
            -command "$this setToDefaultDefinition" 
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        
        itk_component add updateButton {
            DCS::Button $buttonSite.u \
            -text "Update" \
            -width 5 \
            -pady 0 \
            -command "$this updateDefinition" 
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        
        itk_component add deleteButton {
            DCS::Button $buttonSite.del \
            -text "Delete" \
            -width 5 \
            -pady 0 \
            -command "$this deleteThisRun"
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        
        itk_component add resetButton {
            DCS::Button $buttonSite.r -text "Reset" \
            -width 5 \
            -pady 0 \
            -command "$this resetDefinition" 
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        pack $itk_component(defaultButton) -side left -padx 3
        pack $itk_component(updateButton) -side left -padx 3
        pack $itk_component(deleteButton) -side left -padx 3
        pack $itk_component(resetButton) -side left -padx 3

        $itk_component(defaultButton) addInput \
        "::gCurrentGridGroup current_grid_editable 1 {reset first}"

        $itk_component(updateButton) addInput \
        "::gCurrentGridGroup current_grid_editable 1 {reset first}"

        $itk_component(deleteButton) addInput \
        "::gCurrentGridGroup current_grid_deletable 1 {try reset first}"

        $itk_component(resetButton) addInput \
        "::gCurrentGridGroup current_grid_resettable 1 {cannot reset}"

        itk_component add fileRoot {
            DCS::Entry $ring.fileroot \
            -leaveSubmit 1 \
            -entryType field \
            -entryWidth 30 \
            -entryJustify left \
            -entryMaxLength 128 \
            -promptText "Prefix: " \
            -promptWidth 12 \
            -shadowReference 0 \
            -onSubmit "$this setField prefix %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add directory {
            DCS::DirectoryEntry $ring.dir \
            -leaveSubmit 1 \
            -entryType rootDirectory \
            -entryWidth 30 \
            -entryJustify left \
            -entryMaxLength 128 \
            -promptText "Dir: " \
            -promptWidth 12 \
            -shadowReference 0 \
            -onSubmit "$this setField directory %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add shape {
            DCS::MenuEntry $ring.shape \
            -promptText "Shape: " \
            -promptWidth 12 \
            -state labeled \
            -menuChoices [list rectangle oval line polygon l614] \
            -onSubmit "$this setField shape %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add cell_size {
            CellSize $ring.cellSize \
            -promptText "Cell Size: " \
            -promptWidth 12 \
            -onWidthSubmit "$this setField cell_width %s" \
            -onHeightSubmit "$this setField cell_height %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add beam_size {
            BeamSizeParameter $ring.beamSize \
            -promptText "Beam Size: " \
            -promptWidth 12 \
            -onWidthSubmit "$this setField beam_width %s" \
            -onHeightSubmit "$this setField beam_height %s" \
            -onCollimatorSubmit "$this setField collimator {%s}" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add exposureTime {
            DCS::Entry $ring.time \
            -leaveSubmit 1 \
            -promptText "Time: " \
            -promptWidth 12 \
            -entryWidth 11 \
            -units "s" \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -onSubmit "$this setField time %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        
        itk_component add delta {
            DCS::Entry $ring.delta \
            -promptText "Delta: " \
            -leaveSubmit 1 \
            -promptWidth 12 \
            -entryWidth 11 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -shadowReference 0 \
            -onSubmit "$this setField delta %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add distance {
            DCS::MotorViewEntry $ring.distance \
            -checkLimits -1 \
            -menuChoiceDelta 50 \
            -device ::device::$gMotorDistance \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Distance: " \
            -promptWidth 12 \
            -entryWidth 10 \
            -units "mm" \
            -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1 \
            -onSubmit "$this setField distance %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add beamStop {
            DCS::MotorViewEntry $ring.beamStop \
            -checkLimits -1 \
            -menuChoiceDelta 5 \
            -device ::device::$gMotorBeamStop \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Beam Stop: " \
            -promptWidth 12 \
            -entryWidth 10 \
            -units "mm" \
            -unitsList "mm" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1 \
            -onSubmit "$this setField beam_stop %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add attenuation {
            DCS::MotorViewEntry $ring.attenuation \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Attenuation: " \
            -promptWidth 12 \
            -entryWidth 10 \
            -units "%" \
            -unitsList "%" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1 \
            -onSubmit "$this setField attenuation %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add processing {
            DCS::CheckbuttonRight $ring.processing \
            -text "Processing: " \
            -width 12 \
            -shadowReference 0 \
            -command "$this setField processing %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add videoShot {
            DCS::CheckbuttonRight $ring.videoShot \
            -text "Snapshot: " \
            -width 12 \
            -shadowReference 0 \
            -command "$this setField video_snapshot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        itk_component add firstStill {
            DCS::CheckbuttonRight $ring.firstStill \
            -text "First Single: " \
            -width 12 \
            -shadowReference 0 \
            -command "$this setField first_single_shot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        itk_component add firstAtt {
            DCS::MotorViewEntry $ring.firstAttenuation \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Attenuation: " \
            -promptWidth 12 \
            -entryWidth 10 \
            -units "%" \
            -unitsList "%" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1 \
            -onSubmit "$this setField first_attenuation %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }


        itk_component add endStill {
            DCS::CheckbuttonRight $ring.endStill \
            -text "Last Single: " \
            -width 12 \
            -shadowReference 0 \
            -command "$this setField end_single_shot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        itk_component add endAtt {
            DCS::MotorViewEntry $ring.end_attenuation \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Attenuation: " \
            -promptWidth 12 \
            -entryWidth 10 \
            -units "%" \
            -unitsList "%" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1 \
            -onSubmit "$this setField end_attenuation %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        itk_component add numPhiShot {
            DCS::Entry $ring.numPhiShot \
            -promptText "Num Phi Shot: " \
            -leaveSubmit 1 \
            -promptWidth 12 \
            -entryWidth 11 \
            -entryType positiveInt \
            -entryJustify right \
            -shadowReference 0 \
            -onSubmit "$this setField num_phi_shot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        eval itk_initialize $args

        if {!$itk_option(-forL614)} {
            pack $itk_component(summary) -pady $PADY 
            pack $itk_component(buttonsFrame) -pady $PADY
            pack $itk_component(fileRoot) -pady $PADY -padx 5 -anchor w
            pack $itk_component(directory) -pady $PADY -padx 5 -anchor w
            pack $itk_component(shape) -pady $PADY -padx 5 -anchor w
            pack $itk_component(cell_size) -padx 5 -pady $PADY -anchor w
            pack $itk_component(beam_size) -padx 5 -pady $PADY -anchor w
            pack $itk_component(exposureTime) -padx 5 -pady $PADY -anchor w
            pack $itk_component(delta) -padx 5 -pady $PADY -anchor w
            pack $itk_component(distance) -padx 5 -pady $PADY -anchor w
            pack $itk_component(beamStop) -padx 5 -pady $PADY -anchor w
            pack $itk_component(attenuation) -padx 5 -pady $PADY -anchor w
            pack $itk_component(processing) -padx 5 -pady $PADY -anchor w
        } else {
            $itk_component(shape) configure \
            -menuChoices l614

            label $ring.dummy1
            label $ring.dummy2
            pack $itk_component(summary) -pady $PADY 
            pack $itk_component(buttonsFrame) -pady $PADY
            pack $itk_component(fileRoot) -pady $PADY -padx 5 -anchor w
            pack $itk_component(directory) -pady $PADY -padx 5 -anchor w
            pack $itk_component(shape) -pady $PADY -padx 5 -anchor w
            pack $itk_component(cell_size) -padx 5 -pady $PADY -anchor w
            pack $itk_component(beam_size) -padx 5 -pady $PADY -anchor w
            pack $itk_component(distance) -padx 5 -pady $PADY -anchor w
            pack $itk_component(beamStop) -padx 5 -pady $PADY -anchor w
            pack $itk_component(videoShot) -padx 5 -pady $PADY -anchor w
            pack $itk_component(firstStill) -padx 5 -pady $PADY -anchor w
            pack $itk_component(firstAtt) -padx 5 -pady $PADY -anchor w
            pack $ring.dummy1
            pack $itk_component(numPhiShot) -padx 5 -pady $PADY -anchor w
            pack $itk_component(attenuation) -padx 5 -pady $PADY -anchor w
            pack $itk_component(exposureTime) -padx 5 -pady $PADY -anchor w
            pack $itk_component(delta) -padx 5 -pady $PADY -anchor w
            pack $ring.dummy2
            pack $itk_component(endStill) -padx 5 -pady $PADY -anchor w
            pack $itk_component(endAtt) -padx 5 -pady $PADY -anchor w
        }

        foreach {name -} $COMPONENT2KEY {
            $itk_component($name) addInput \
            "::gCurrentGridGroup current_grid_editable 1 {reset first}"
        }

        exportSubComponent instant_beam_size ::$itk_component(beam_size)

        announceExist

        gCurrentGridGroup register $this current_grid handleGridUpdate

        log_warning grid input: $this
    }
    destructor {
        gCurrentGridGroup unregister $this current_grid handleGridUpdate
    }
}
body GridInputView::handleGridUpdate { - ready_ - contents_ - } {
    set m_ready 0
    if {!$ready_} {
        return
    }
    set m_groupId [gCurrentGridGroup getId]
    set m_snapId  [gCurrentGridGroup getCurrentSnapshotId]
    set m_gridId  [gCurrentGridGroup getCurrentGridId]

    set ll [llength $contents_]
    if {$ll < 6} {
        set m_d_userSetup [gCurrentGridGroup getDefaultUserSetup]
        $itk_component(shape) configure -state normal
    } else {
        set m_d_userSetup [lindex $contents_ 5]
        $itk_component(shape) configure -state labeled
    }
    refreshDisplay
    set m_ready 1
}
body GridInputView::refreshDisplay { } {
    set title [dict get $m_d_userSetup summary]
    $itk_component(summary) configure -text $title

    set numError 0
    foreach {name keys} $COMPONENT2KEY {
        set value ""
        set skip 0
        foreach key $keys {
            if {[catch {dict get $m_d_userSetup $key} v]} {
                puts "cannot find $key: $v"
                set skip 1
                incr numError
            }
            lappend value $v
        }

        if {!$skip} {
            #puts "setting $name to $value"
            eval $itk_component($name) setValue $value 1
        }
    }
    if {$numError} {
        puts "failed to update, the dict=$m_d_userSetup"
        if {$m_d_userSetup == ""} {
            puts "contents=$contents_"
        }
    }
}
class GridListView {
    inherit ::DCS::ComponentGateExtension

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    private variable BROWNRED #a0352a
    private variable ACTIVEBLUE #2465be
    private variable OUTDARK    #aaa
    private variable DARK #777
    private variable m_objGridGroupConfig ""
    
    ### to pass through
    public method handleInstantBeamSizeChange { - ready_ - contents_ - } {
        if {!$ready_} return
        set m_instantBeamsize $contents_
        updateRegisteredComponents instant_beam_size
    }
    public method getInstantBeamSize { } { return $m_instantBeamsize }

    public method handleGridListUpdate

    public method handleClientStatusChange
    public method addNewGrid { }
    public method collect

    public method onTabSwitch { index } {
        if {$m_inEventHandling} {
            return
        }
        ### tell group to inform all others current grid changed.
        foreach {ssId id} [gCurrentGridGroup selectGridIndex $index] break
        if {$_gateOutput == 1} {
            set faceBeam 1
            set grpId [gCurrentGridGroup getId]
            $m_objGridGroupConfig startOperation move_to_grid \
            $grpId $id $faceBeam
        }
    }

    private method adjustNumTabs
    private method updateNewRunCommand

    private variable m_clientState "offline"
    private variable m_numGrid 0 
    private variable m_numTabs 0
    private variable m_gridStateColor  
    private variable m_gridLabel

    private variable m_currentGridIndex -1
    private variable m_gridList ""

    private variable m_instantBeamsize "0.1 0.1 red"

    private variable m_inEventHandling 0

    constructor { args } {
        ::DCS::Component::constructor {
            instant_beam_size getInstantBeamSize
        }
    } {
        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        #### copied from CollectView: GridListView
        set ring $itk_interior

        itk_component add control {
            GridGroupControl $ring.control
        } {
            keep -systemIdleOnly -activeClientOnly
        }

        itk_component add notebook {
            iwidgets::tabnotebook $ring.n \
            -background $GridGroupColor::COLOR_CURRENT \
            -borderwidth 0 \
            -tabpos w \
            -gap 4 \
            -angle 20 \
            -width 330 \
            -height 800 \
            -raiseselect 1 \
            -bevelamount 4 \
            -padx 5 \
        } {
        }

        $itk_component(notebook) add -label " * "
         
        #pack the single runView widget into the first childsite 
        set childSite [$itk_component(notebook) childsite 0]

        ### Do we need this??
        #pack $childsite

        $itk_component(notebook) select 0
        $itk_component(notebook) configure -auto off
      
        itk_component add grid_view {
            GridInputView $childSite.gview \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -forL614
        }

        pack $itk_component(grid_view) -expand 1 -fill both -anchor nw

        pack $itk_component(control) -side top -fill x -expand 1
        pack $itk_component(notebook) -side top -anchor n -pady 0 \
        -expand 1 -fill both

        eval itk_initialize $args   
        announceExist

        set maxCount [GridGroup::GridGroupBase::getMAXNUMGRID]
        for {set i 0} {$i < $maxCount} {incr i} {
            set m_gridLabel($i) X
            set m_gridStateColor($i) $ACTIVEBLUE
        }

        $itk_component(grid_view) register $this instant_beam_size handleInstantBeamSizeChange

        if {[gCurrentGridGroup getId] < 0} {
            gCurrentGridGroup switchGroupNumber 0 1
        }
        gCurrentGridGroup setGridListWidget $this

        $this register gCurrentGridGroup instant_beam_size handleInstantBeamSizeChange

        gCurrentGridGroup register $this grid_list handleGridListUpdate

        ::dcss register $this clientState handleClientStatusChange
    }
    destructor {
        gCurrentGridGroup setGridListWidget ""
        gCurrentGridGroup unregister $this grid_list handleGridListUpdate

        ::dcss unregister $this clientState handleClientStatusChange
    }
}

body GridListView::adjustNumTabs { } {
    #puts "adjustNumTabs: tabs=$m_numTabs grids=$m_numGrid"
    if {$m_numTabs == $m_numGrid} {
        return
    }
    set currentSelection [$itk_component(notebook) index select]
    if {$m_numTabs > $m_numGrid} {
        set last [expr $m_numTabs - 1]
        set end  $m_numGrid
        for {set i $last} {$i >= $end} {incr i -1} {
            $itk_component(notebook) delete $i
        }
        set m_numTabs $m_numGrid
    } else {
        set maxCount [GridGroup::GridGroupBase::getMAXNUMGRID]
        if {$m_numTabs == $maxCount} {
            ### reached max, cannot add anymore.
            return
        }
        set newNumTabs $m_numGrid
        if {$newNumTabs > $maxCount} {
            set newNumTabs $maxCount
        }
        for {set i $m_numTabs} {$i < $newNumTabs } {incr i} {
            $itk_component(notebook) insert $i
            $itk_component(notebook) pageconfigure $i \
            -state normal \
            -command "$this onTabSwitch $i" \
            -label $m_gridLabel($i) \
            -foreground $m_gridStateColor($i) \
            -selectforeground $m_gridStateColor($i)
        }
        set m_numTabs $newNumTabs
    }

    if { $currentSelection >= $m_numTabs } {
        $itk_component(notebook) select end
    }

    updateNewRunCommand
}
body GridListView::handleClientStatusChange { control_ targetReady_ alias_ clientStatus_ -  } {
    if { !$targetReady_ } return

    set maxCount [GridGroup::GridGroupBase::getMAXNUMGRID]
    #puts "client status change count: $m_numTabs max: $maxCount"


    if {$clientStatus_ != "active" && $m_numTabs < $maxCount} {
        $itk_component(notebook) pageconfigure end -state disabled
    } else {
        $itk_component(notebook) pageconfigure end -state normal 
    }

    set m_clientState $clientStatus_
}

body GridListView::updateNewRunCommand {} {
    set maxCount [GridGroup::GridGroupBase::getMAXNUMGRID]
    #puts "update: count: $m_numTabs max: $maxCount"

    if {$m_numTabs < $maxCount} {
        #configure the 'add run' star
        $itk_component(notebook) pageconfigure end \
        -label " * " \
        -command [list $this addNewGrid] 

        if {$m_clientState != "active"} {
            $itk_component(notebook) pageconfigure end -state disabled
        }
    }
}
body GridListView::addNewGrid { } {
    if {$m_inEventHandling} {
        return
    }
    gCurrentGridGroup prepareAddGrid
}
body GridListView::handleGridListUpdate { - ready_ - contents_ - } {
    #puts "handleGridListUpdate {$contents_}"
    set ll [llength $contents_]
    if {!$ready_ || $ll < 2} {
        return
    }

    set m_inEventHandling 1

    foreach {m_currentGridIndex m_gridList} $contents_ break
    set m_numGrid [llength $m_gridList]
    adjustNumTabs

    set tabIndex -1
    foreach gridInfo $m_gridList {
        incr tabIndex
        foreach {id label state} $gridInfo break
        set m_gridLabel($tabIndex) $label

        #### init means not ready to run.
        switch -exact -- $state {
            init        { set color $ACTIVEBLUE }
            setup       { set color $ACTIVEBLUE }
            ready       { set color $ACTIVEBLUE }
            paused      { set color $BROWNRED }
            collecting  { set color red }
            inactive    { set color $ACTIVEBLUE }
            complete    { set color black }
            done        { set color black }
            default     { set color red }
        }
        set m_gridStateColor($tabIndex) $color
        $itk_component(notebook) pageconfigure $tabIndex \
        -label $label \
        -foreground $color \
        -selectforeground $color
    }
    if {$m_currentGridIndex < 0} {
        $itk_component(notebook) select $m_numTabs
    } elseif {$m_currentGridIndex < $m_numTabs} {
        $itk_component(notebook) select $m_currentGridIndex
    }

    set m_inEventHandling 0
}
class GridNodeListView {
    inherit ::DCS::ComponentGateExtension

    itk_option define -font font Font "-family courior -size 16" { setFont }

    itk_option define -hideSkipped hideSkipped HideSkipped 1 { updateNodeList }

    ### event handler to updat display
    public method handleListUpdate { - ready_ - contents_ - }
    
    ### handle user click on the node line
    public method handleClick { index } {
        #puts "click on $index"
        if {!$_gateOutput} {
            return
        }

        ### color change
        setCurrentNode $index

        set grpId [gCurrentGridGroup getId]
        set ssId  [gCurrentGridGroup getCurrentSnapshotId]
        set id    [gCurrentGridGroup getCurrentGridId]
    
        set seq [lindex $m_index2sequence $index]

        set rotatePhiToFaceBeam 1

        $m_objGridGroupConfig startOperation \
        move_to_node $grpId $id $seq $rotatePhiToFaceBeam
    }
    public method handleDoubleClick { index } {
        #puts "double click on $index: dir=$m_dir prefix=$m_prefix ext=$m_ext"
        if {$m_dir != "" && $m_prefix != "" && $m_ext != ""} {
            set seq [lindex $m_index2sequence $index]
            set path [file join $m_dir ${m_prefix}_[expr $seq + 1].$m_ext]
            if {[catch {exec adxv $path &} errMsg]} {
                log_error failed to start adxv: $errMsg
            }
        }
    }

    ### select current node by other widgets.
    public method setNodeIndex { index }

    public method redisplay { } {
        configure -hideSkipped $gCheckButtonVar($this,hide)
    }

    private method setFont { }

    private method setCurrentNode { index }

    private method showLabel { } {
        pack forget $itk_component(nodeListFrame)
        pack $itk_component(noList) -side top -fill both -expand 1
    }
    private method showList { } {
        pack forget $itk_component(noList)
        pack $itk_component(nodeListFrame) -side top -fill both -expand 1
    }
    private method addMoreNode { num {display 0}}
    private method updateNodeList { }
    private method parseOneNode { sequence index contents label }
    private method displayAllNode { }

    private variable m_headerSite
    private variable m_currentNodeIndex -1
    private variable m_numNodeCreated 0
    private variable m_numNodeParsed 0
    private variable m_numNodeDisplayed 0
    private variable m_index2sequence ""

    private variable m_nodeList ""
    private variable m_labelList ""
    private variable m_dir ""
    private variable m_prefix ""
    private variable m_ext ""

    ### for convenient, it stores cell name
    private variable m_oneNode ""
    private variable m_dataWidth 0

    private variable m_objGridGroupConfig ""


    private common INIT_NODE     400
    private common MAX_NODE      800

    public  common FIELD_NAME   [list Spots Shape Res  Score Rings]
    private common FIELD_WIDTH  [list 8     8     8    8     8    ]
    public  common FIELD_INDEX  [list 0     5     3    2     4    ]
    private common FIELD_FORMAT [list %.0f  %.1f  %.1f %.1f  %.0f ]

    private common FIELD_STATUS_WIDTH 8
    private common FIELD_FRAME_WIDTH 8

    private common HEADER_IPADY         4
    private common HEADER_BACKGROUND    #c0c0ff
    private common ODD_LINE_BACKGROUND  #e0e0e0
    private common EVEN_LINE_BACKGROUND gray

    private common gCheckButtonVar

    constructor { args } {
        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        set data_header [format %-${FIELD_FRAME_WIDTH}s Frame]
        set m_dataWidth $FIELD_FRAME_WIDTH
        foreach fh $FIELD_NAME fw $FIELD_WIDTH {
            append data_header [format %-${fw}s $fh]
            incr m_dataWidth $fw
        }

        itk_component add titleFrame {
            frame $itk_interior.headerF
        } {
        }
        set titleSite $itk_component(titleFrame)

        itk_component add title {
            label $titleSite.title \
            -text "title"
        } {
        }

        #should match itk_option -hideSkipped 
        set gCheckButtonVar($this,hide) 1
        itk_component add hide {
            checkbutton $titleSite.hide \
            -variable [scope gCheckButtonVar($this,hide)] \
            -text "Hide Skipped" \
            -command "$this redisplay"
        } {
        }

        pack $itk_component(title) -side left
        pack $itk_component(hide)  -side right

        itk_component add scrolledFrame {
            DCS::ScrolledFrame $itk_interior.sf \
            -vscrollmode static \
            -hscrollmode static \
        } {
        }
        set tableSite [$itk_component(scrolledFrame) childsite]
        set m_headerSite  [$itk_component(scrolledFrame) vfreezesite]

        ### when no nodelist info, display this label
        itk_component add noList {
            label $tableSite.nl \
            -text "Create Grid First" \
        } {
        }

        itk_component add nodeListFrame {
            frame $tableSite.f
        } {
        }
        set EVEN_LINE_BACKGROUND \
        [$itk_component(nodeListFrame) cget -background]

        label $m_headerSite.ch0 \
        -background $HEADER_BACKGROUND \
        -text "Status" \
        -width $FIELD_STATUS_WIDTH \
        -anchor w \
        -relief groove \
        -borderwidth 1
    
        label $m_headerSite.ch1 \
        -background $HEADER_BACKGROUND \
        -text $data_header  \
        -width $m_dataWidth \
        -anchor w \
        -relief groove \
        -borderwidth 1

        grid $m_headerSite.ch0 $m_headerSite.ch1 \
        -row 0 -sticky news -ipady $HEADER_IPADY

        set f $itk_component(nodeListFrame)

        set m_oneNode [list $f.statusNODE $f.dataNODE]

        pack $itk_component(noList) -side top -fill both -expand 1

        pack $itk_component(titleFrame) -side top -fill x
        pack $itk_component(scrolledFrame) -side top -fill both -expand 1
        $itk_component(scrolledFrame) xview moveto 0
        $itk_component(scrolledFrame) yview moveto 0

        addMoreNode $INIT_NODE 1
        set m_numNodeDisplayed $INIT_NODE
        #set all [grid slaves $f]
        #eval grid forget $all

        eval itk_initialize $args
        announceExist

        gCurrentGridGroup register $this current_grid_node_list \
        handleListUpdate
    }
}
body GridNodeListView::addMoreNode { num {display 0}} {
    if {$m_numNodeCreated + $num > $MAX_NODE} {
        set num [expr $MAX_NODE - $m_numNodeCreated]
    }
    if {$num <=0} {
        return
    }
    #puts "adding more node: $num"
    set f $itk_component(nodeListFrame)
    set fLL [llength $FIELD_INDEX]
    for {set i 0} {$i < $num} {incr i} {
        set index $m_numNodeCreated

        label $f.status${index} \
        -anchor w \
        -relief groove \
        -borderwidth 1 \
        -text ---- \
        -width $FIELD_STATUS_WIDTH

        label $f.data${index} \
        -anchor w \
        -relief groove \
        -borderwidth 1 \
        -text "[expr $index + 1] ----" \
        -width $m_dataWidth

        bind $f.status${index} <Button-1> "$this handleClick $index"
        bind $f.data${index}   <Button-1> "$this handleClick $index"

        bind $f.status${index} <Double-1> "$this handleDoubleClick $index"
        bind $f.data${index}   <Double-1> "$this handleDoubleClick $index"

        registerComponent $f.status${index} $f.data${index}

        if {$display} {
            grid $f.status${index} $f.data${index} \
            -row $i -sticky news
        }

        incr m_numNodeCreated
    }
    #puts "adding more node: done"
}
body GridNodeListView::parseOneNode { sequence_ index_ contents_ label_ } {
    #puts "parseOneNode $index_ {$contents_} label={$label_}"

    if {$index_ % 2} {
        set bg $ODD_LINE_BACKGROUND
    } else {
        set bg $EVEN_LINE_BACKGROUND
    }

    if {$label_ == ""} {
        set line [format %-${FIELD_FRAME_WIDTH}s [expr $sequence_ + 1]]
    } else {
        set line [format %-${FIELD_FRAME_WIDTH}s $label_]
    }

    set f $itk_component(nodeListFrame)

    set first [lindex $contents_ 0]
    if {[string is double -strict $first]} {
        $f.status${index_} configure \
        -text DONE \
        -foreground white \
        -disabledforeground gray75 \
        -background $GridGroupColor::COLOR_DONE

        set bad 0
        foreach fIdx $FIELD_INDEX fmt $FIELD_FORMAT fw $FIELD_WIDTH {
            set v [lindex $contents_ $fIdx]
            if {[catch {format $fmt $v} vDisplay]} {
                puts "format failed for $v: $vDisplay"
                incr bad
                set vDisplay ----
            }
            append line [format %-${fw}s $vDisplay]
        }
        if {$bad} {
            puts "parseOneNode $index_ {$contents_}"
            puts "failed with first=double"
        }
        $f.data${index_} configure -text $line -background $bg
    } else {
        set firstChar [string index $first 0]
        switch -exact -- $firstChar {
            N {
                if {$itk_option(-hideSkipped)} {
                    return 0
                }
                set color $GridGroupColor::COLOR_SKIP
                set status SKIP
            }
            S {
                set color ""
                set status ----
            }
            X {
                set color $GridGroupColor::COLOR_EXPOSING
                set status EXPO
            }
            D {
                set color $GridGroupColor::COLOR_PROCESS
                set status PROC
            }
            default {
                set color $GridGroupColor::COLOR_BAD
                set status ----
            }
        }
        if {$color != ""} {
            $f.status${index_} configure \
            -background $color \
            -foreground white \
            -disabledforeground gray75 \
            -text $status
        } else {
            $f.status${index_} configure \
            -background $bg \
            -foreground black \
            -text $status
        }

        foreach fw $FIELD_WIDTH {
            append line [format %-${fw}s ----]
        }
        $f.data${index_} configure -text $line -background $bg
    }
    return 1
}
body GridNodeListView::updateNodeList { } {
    #puts "updateNodeList"

    ### clear the current node, we reset all colors.
    set m_currentNodeIndex -1

    set numNodePlanToParse [llength $m_nodeList]
    if {$numNodePlanToParse > $MAX_NODE} {
        set rows_cut [expr $numNodePlanToParse - $MAX_NODE]
        set numNodePlanToParse $MAX_NODE
        ## better show at its own place.
        log_warning too many nodes, $rows_cut not displayed
    }

    set moreNode [expr $numNodePlanToParse - $m_numNodeCreated]
    addMoreNode $moreNode
    setFont

    set seq -1
    set m_numNodeParsed 0
    set m_index2sequence ""
    foreach node $m_nodeList label $m_labelList {
        incr seq
        if {$m_numNodeParsed >= $numNodePlanToParse} {
            break
        }
        if {[parseOneNode $seq $m_numNodeParsed $node $label]} {
            lappend m_index2sequence $seq
            incr m_numNodeParsed
        }
    }
    #puts "updateNodeList displaying"

    displayAllNode
    #puts "updateNodeList done"
}
body GridNodeListView::handleListUpdate { - ready_ - contents_ - } {
    set ll [llength $contents_]
    if {!$ready_ || $ll < 2} {
        $itk_component(title) configure -text "Nodes not available yet"
        showLabel
        return
    }

    showList
    foreach {header m_nodeList m_labelList} $contents_ break

    set m_dir ""
    set m_prefix ""
    set m_ext ""
    foreach {id label status m_dir m_prefix m_ext} $header break

    set txt "raster $label ($status) result"
    $itk_component(title) configure -text $txt

    updateNodeList
}
body GridNodeListView::displayAllNode { } {
    if {$m_numNodeDisplayed == $m_numNodeParsed} {
        return
    }

    set f $itk_component(nodeListFrame)
    if {$m_numNodeParsed > $m_numNodeDisplayed} {
        for {set i $m_numNodeDisplayed} {$i < $m_numNodeParsed} {incr i} {
            regsub -all NODE $m_oneNode $i oneRow
            eval grid $oneRow -row $i -sticky news
        }
    } else {
        for {set i $m_numNodeParsed} {$i < $m_numNodeDisplayed} {incr i} {
            regsub -all NODE $m_oneNode $i oneRow
            eval grid forget $oneRow
        }
    }

    $itk_component(scrolledFrame) yview moveto 0
    set m_numNodeDisplayed $m_numNodeParsed
}
body GridNodeListView::setFont { } {
    set font $itk_option(-font)
    if {$font == ""} {
        return
    }
    set f $itk_component(nodeListFrame)
    set all [grid slaves $f]
    eval lappend all [grid slaves $m_headerSite]

    foreach c $all {
        $c configure -font $font
    }
}
body GridNodeListView::setCurrentNode { index_ } {
    if {$m_currentNodeIndex >= 0} {
        set seq [lindex $m_index2sequence $m_currentNodeIndex]
        ### rediplay in orignal color
        set node  [lindex $m_nodeList $seq]
        set label [lindex $m_labelList $seq]
        parseOneNode $seq $m_currentNodeIndex $node $label
    }
    set m_currentNodeIndex $index_
    if {$m_currentNodeIndex >= 0} {
        ### display in selected color
        set f $itk_component(nodeListFrame)
        $f.status${m_currentNodeIndex} configure -background $GridGroupColor::COLOR_CURRENT
        $f.data${m_currentNodeIndex}   configure -background $GridGroupColor::COLOR_CURRENT
    }
}

class GridGroupControl {
    inherit ::DCS::ComponentGateExtension

    private variable m_objCollectGridGroup ""
    private variable m_objPause ""
    private common BUTTON_WIDTH 15

    public method setNumberDisplayField { name } {
        gCurrentGridGroup setNumberField $name
    }
    public method setContourDisplayField { name } {
        gCurrentGridGroup setContourField $name
    }

    public method handleNumberFieldUpdate { - ready_ _ contents_ - }
    public method handleContourFieldUpdate { - ready_ _ contents_ - }

    public method start { } {
        set groupId [gCurrentGridGroup getId]
        if {$groupId < 0} {
            puts "bad gridGroup, not loaded yet"
            return
        }
        set gridListInfo [gCurrentGridGroup getGridListInfo]
        set index [lindex $gridListInfo 0]
        if {$index < 0} {
            puts "no current grid to start"
            return
        }
        $m_objCollectGridGroup startOperation $groupId $index
    }
    public method start_pause { } {
        set groupId [gCurrentGridGroup getId]
        if {$groupId < 0} {
            puts "bad gridGroup, not loaded yet"
            return
        }
        set gridListInfo [gCurrentGridGroup getGridListInfo]
        set index [lindex $gridListInfo 0]
        if {$index < 0} {
            puts "no current grid to start"
            return
        }
        $m_objCollectGridGroup startOperation $groupId $index pause
    }
    ### we will add skip later.
    public method pause { } {
        $m_objPause startOperation
    }

    constructor { args } {
        set deviceFactory [::DCS::DeviceFactory::getObject]

        set m_objCollectGridGroup \
        [$deviceFactory createOperation collectGridGroup]

        set m_objPause [$deviceFactory createOperation pauseDataCollection]

        itk_component add controlF {
            iwidgets::labeledframe $itk_interior.controlF \
            -labeltext Control
        } {
        }
        set controlSite [$itk_component(controlF) childsite]
        itk_component add optionF {
            iwidgets::labeledframe $itk_interior.optionF \
            -labeltext Options
        } {
        }
        set optionSite [$itk_component(optionF) childsite]

        itk_component add start {
            DCS::Button $controlSite.start \
            -width $BUTTON_WIDTH \
            -text "Start" \
            -command "$this start"
        } {
            keep -systemIdleOnly -activeClientOnly
        }
        itk_component add start_pause {
            DCS::Button $controlSite.start_pause \
            -width $BUTTON_WIDTH \
            -text "Start With Pause" \
            -command "$this start_pause"
        } {
            keep -systemIdleOnly -activeClientOnly
        }
        itk_component add pause {
            DCS::Button $controlSite.pause \
            -width $BUTTON_WIDTH \
            -text "Pause" \
            -systemIdleOnly 0 \
            -command "$this pause"
        } {
            keep -activeClientOnly
        }
        pack $itk_component(start) -side top -fill x
        pack $itk_component(start_pause) -side top -fill x
        pack $itk_component(pause) -side top -fill x

        $itk_component(start) addInput \
        "::gCurrentGridGroup current_grid_runnable 1 {cannot run}"
        $itk_component(start_pause) addInput \
        "::gCurrentGridGroup current_grid_runnable 1 {cannot run}"

        set numChoices [list None Frame]
        eval lappend numChoices $GridNodeListView::FIELD_NAME

        itk_component add numField {
            DCS::MenuEntry $optionSite.number \
            -promptText "Show Number:" \
            -promptWidth 12 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $numChoices \
            -onSubmit "$this setNumberDisplayField %s" \
        } {
        }

        set contourChoices "None"
        eval lappend contourChoices $GridNodeListView::FIELD_NAME
        itk_component add contourField {
            DCS::MenuEntry $optionSite.contour \
            -promptText "Show Contour:" \
            -promptWidth 12 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $contourChoices \
            -onSubmit "$this setContourDisplayField %s" \
        } {
        }

        pack $itk_component(numField) -side top     -fill x
        pack $itk_component(contourField) -side top -fill x

        pack $itk_component(controlF) -side left -expand 1 -fill both
        pack $itk_component(optionF)  -side left -expand 1 -fill both

        eval itk_initialize $args
        announceExist

        gCurrentGridGroup register $this number_display_field \
        handleNumberFieldUpdate
        gCurrentGridGroup register $this contour_display_field \
        handleContourFieldUpdate
    }
}
body GridGroupControl::handleNumberFieldUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }

    $itk_component(numField) setValue $contents_ 1
}
body GridGroupControl::handleContourFieldUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }

    $itk_component(contourField) setValue $contents_ 1
}

GridItemBase::setDisplatFieldMaster gCurrentGridGroup
