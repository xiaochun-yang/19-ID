package provide GridCanvas 1.0

package require Iwidgets

package require DCSComponent
package require ComponentGateExtension
package require DCSDeviceFactory
package require DCSDeviceView
package require DCSUtil
package require DCSContour
package require DCSGridGroup4BluIce
package require BLUICEEnergyList

#set gGridPurpose forL614
set gGridPurpose forCrystal
#set gGridPurpose "forLCLS"
set gGridPurpose "forGrid"

### We have projective mapping and bilinear mapping.
### Bilinear mapping is good for rectangle mapping.
### Equal interval on the lines parallel to rectangle edges will have
### equal interval on the mapping. Lines will still be lines if they are
### parallel to the edge.
###
### Projective mapping is good on views with very tilted object.  One end
### is much closer to the camera than the other end.
### It needs the object by rigid, no bend.
### Any lines on the object will be still lines on the view but equal interval
### is not preserved.
###
### For bent object, it is better to use bilinear with sections.
### Each section is bilinear interpolated.
###
### In practical, we found bilinear is more tolerant than projective.
### So, we intend to all use bilinear for now.

class BilinearMapping {
    public method quickSetup { uvxyList } {
        eval $m_obj setup $uvxyList
    }
    public method quickMap { uvList } {
        $m_obj map $uvList
        return $m_mapResult
    }

    protected variable m_obj
    protected variable m_mapResult ""

    ##### bilinear mapping:
    ##### x= xa + xb * u + xc * v + xd * u * v
    ##### y= ya + yb * u + yc * v + yd * u * v
    constructor { } {
        set m_obj [createNewBilinearMapping]
        puts "got bilinear obj: $m_obj"
    }
    destructor {
        rename $m_obj {}
    }
}

class ProjectiveMapping {
    public method reset { }
    public method setup { uvxyList }
    public method ready { } { return $m_ready }
    public method map { uvList }
    public method show { }

    public method quickSetup { uvxyList }
    public method quickMap { uvList }

    protected variable m_obj
    protected variable m_mapResult ""

    ##### projective mapping:
    ##### x= (au+bv+c)/(gu+hv+1)
    ##### y= (du+ev+f)/(gu+hv+1)

    protected variable m_ready 0
    protected variable m_a 0.0
    protected variable m_b 0.0
    protected variable m_c 0.0
    protected variable m_d 0.0
    protected variable m_e 0.0
    protected variable m_f 0.0
    protected variable m_g 0.0
    protected variable m_h 0.0

    ##### transfer input (u v) to unit square.
    protected variable m_uOffset 0.0
    protected variable m_uScale 1.0
    protected variable m_vOffset 0.0
    protected variable m_vScale 1.0

    constructor { } {
        set m_obj [createNewProjectiveMapping]
    }
    destructor {
        rename $m_obj {}
    }
}
body ProjectiveMapping::reset { } {
    set m_ready 0
}
body ProjectiveMapping::quickSetup { uvxyList } {
    eval $m_obj setup $uvxyList
}
body ProjectiveMapping::quickMap { uvList } {
    $m_obj map $uvList
    return $m_mapResult
}
body ProjectiveMapping::setup { uvxyList } {
    foreach {u0 v0 u1 v1 u2 v2 u3 v3 x0 y0 x1 y1 x2 y2 x3 y3} $uvxyList break

    if {$v0 != $v1 || $u1 != $u2 || $v2 != $v3 || $u3 != $u0} {
        puts "not supported yet, only rectangle"
        ## generic quadulateral
    } else {
        ## normal rectangle 
        if {$u0 == $u1 || $v1 == $v2} {
            puts "bad anchor points"
            return
        }

        set m_uOffset $u0
        set m_uScale [expr 1.0 / ($u1 - $u0)]

        set m_vOffset $v0
        set m_vScale [expr 1.0 / ($v2 - $v1)]

        ## now the anchor points are:
        ## 0 0 x0 y0
        ## 1 0 x1 y1
        ## 1 1 x2 y2
        ## 0 1 x3 y3

        #### formular
        set dx1 [expr $x1 - $x2]
        set dy1 [expr $y1 - $y2]
        set dx2 [expr $x3 - $x2]
        set dy2 [expr $y3 - $y2]
        set sx  [expr $x0 - $x1 + $x2 - $x3]
        set sy  [expr $y0 - $y1 + $y2 - $y3]

        if {$sx == 0 && $sy == 0} {
            ##parallelogram
            set m_a [expr $x1 - $x0]
            set m_b [expr $x2 - $x1]
            set m_c $x0
            set m_d [expr $y1 - $y0]
            set m_e [expr $y2 - $y1]
            set m_f $y0
            set m_g 0.0
            set m_h 0.0

            set m_ready 1
            return
        }
        set dd  [expr $dx1 * $dy2 - $dx2 * $dy1]
        set ddg [expr $sx  * $dy2 - $dx2 * $sy]
        set ddh [expr $dx1 * $sy  - $sx  * $dy1]

        set m_g [expr $ddg / double($dd)]
        set m_h [expr $ddh / double($dd)]
        set m_a [expr $x1 - $x0 + $m_g * $x1]
        set m_b [expr $x3 - $x0 + $m_h * $x3]
        set m_c $x0
        set m_d [expr $y1 - $y0 + $m_g * $y1]
        set m_e [expr $y3 - $y0 + $m_h * $y3]
        set m_f $y0
        set m_ready 1
    }
}
body ProjectiveMapping::map { uvList } {
    set ll [llength $uvList]
    if {$ll % 2} {
        puts "wrong number of coordinuates"
        return -code error bad_input_coords
    }
    if {!$m_ready} {
        puts "not ready"
        return -code error not_ready
    }
    set result ""
    foreach {u v} $uvList {
        set un [expr ($u - $m_uOffset) * $m_uScale]
        set vn [expr ($v - $m_vOffset) * $m_vScale]

        set mm [expr $m_g * $un + $m_h * $vn + 1.0]
        set mx [expr $m_a * $un + $m_b * $vn + $m_c]
        set my [expr $m_d * $un + $m_e * $vn + $m_f]

        set x [expr $mx / $mm]
        set y [expr $my / $mm]

        lappend result $x $y
    }

    return $result
}
body ProjectiveMapping::show { } {
    if {!$m_ready} {
        puts "NOT READY"
        return
    }
    foreach name {m_a m_b m_c m_d m_e m_f m_g m_h} {
        puts "$name= [set $name]"
    }
}

### test
#set aaaa [ProjectiveMapping ::/#auto]
#set p0 [list 0 0 0 0]
#set p1 [list 1 0 40 0]
#set p2 [list 1 1 30 30]
#set p3 [list 0 1 10 20]

#$aaaa setup [list $p0 $p1 $p2 $p3]
#$aaaa show

#set uvList [list 0 0 0 0.5 0.5 0 0.5 0.5 1 1]
#set xyList [$aaaa map $uvList]
#foreach {x y} $xyList {
#    puts "xy=$x $y"
#}




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

    #### tool mode change triggered by other GUI.
    public method setToolMode { mode } { error }

    public method switchGroup { gId snapshotList {idMap ""} }
    public method addImageToTop { ssId idMap }
    public method moveImageToTop { ssId idMap {evenDisplayed 1} }
    public method imageShowing { ssId }
    public method addGrid { objGrid }
    public method deleteGrid { id }
    public method updateGrid { objGrid }
    public method getViewScoreForGrid { id }
    public method adjustGrid { id param {extra ""} }
    public method setNode { id index status }
    public method setMode { id status }
    public method setBeamSize { contents }
    public method refreshMatrixDisplay { }

    public method setCurrentGrid { id }
    public method clearCurrentGrid { } { error }

    public method configureOptions { args } {
        for {set i 0} {$i < $m_maxNumDisplay} {incr i} {
            set display [lindex $m_displayList $i]
            if {[catch {
                eval $display configure $args
            } errMsg]} {
                log_error set option failed for $display: $errMsg
            }
        }
    }

    public method getDisplayedSnapshotIdList { } {
        set idList ""
        for {set i 0} {$i < $m_numDisplayed} {incr i} {
            set display [lindex $m_displayList $i]
            lappend idList [$display getSnapshotId]
        }
        return $idList
    }

    protected method getMaxViewScoreForGrid { id }

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

    #### set by derived class.  It is used to skip moveImageToTop
    protected variable m_liveVideo 0
}
body GridGroup::VideoImageDisplayHolder::autoFillSnapshotDisplay { ssList } {
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
        set idMap ""
    }
    set m_groupId $gId
    for {set i 0} {$i < $m_maxNumDisplay} {incr i} {
        set display [lindex $m_displayList $i]
        $display setGroupId $m_groupId
    }
    setImageList $ssList $idMap
}
body GridGroup::VideoImageDisplayHolder::setImageList { ssList {idMap ""} } {
    puts "setImageList {$ssList}"
    if {![dict exists $d_idListSnapshotDisplayed $m_groupId]} {
        autoFillSnapshotDisplay $ssList
    }

    if {$idMap == ""} {
        set idMap [dict create]
        foreach ss $ssList {
            dict set ipMap [$ss getId] $ss
        }
    }

    set idListRaw [dict get $d_idListSnapshotDisplayed $m_groupId]
    set idList ""
    foreach id $idListRaw {
        if {[dict exists $idMap $id]} {
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

    for {set i 0} {$i < $ll} {incr i} {
        set display [lindex $m_displayList $i]
        set id [lindex $idList $i]
        set snapshot [dict get $idMap $id]
        $display refresh $snapshot
        puts "refresh $i"
    }
    for {set i $ll} {$i < $m_maxNumDisplay} {incr i} {
        set display [lindex $m_displayList $i]
        $display reset
        puts "reset $i"
    }
}
body GridGroup::VideoImageDisplayHolder::addImageToTop { ssId idMap } {
    puts "addImageToTop: ssId=$ssId"
    if {$m_groupId < 0} {
        puts "group wrong"
        return -1
    }

    if {$m_liveVideo} {
        return 0
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
    if {$index >= 0} {
        log_error snapshot already displayed
        return $index
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
        puts "refresh for i=$i id=$id ss=$snapshot"
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

    if {$m_liveVideo} {
        return 0
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
body GridGroup::VideoImageDisplayHolder::adjustGrid { id param {extra ""} } {
    foreach {score index} [getMaxViewScoreForGrid $id] break
    set display [lindex $m_displayList $index]
    if {$display != ""} {
        puts "using $display on $this to perform adjustGrid $id"
        $display adjustGrid $id $param $extra
    }
}
body GridGroup::VideoImageDisplayHolder::getViewScoreForGrid { id } {
    foreach {score index} [getMaxViewScoreForGrid $id] break

    return $score
}
body GridGroup::VideoImageDisplayHolder::getMaxViewScoreForGrid { id } {
    set maxScore -1.0
    set index -1
    for {set i 0} {$i < $m_numDisplayed} {incr i} {
        set display [lindex $m_displayList $i]
        if {$display != ""} {
            set score [$display getViewScoreForGrid $id]
            puts "display $display score $score for $this"
            if {$score > $maxScore} {
                set maxScore $score
                set index $i
            }
        }
    }
    return [list $maxScore $index]
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
body GridGroup::VideoImageDisplayHolder::setCurrentGrid { id } {
    puts "+setCurrentGrid $id"
    for {set i 0} {$i < $m_maxNumDisplay} {incr i} {
        set display [lindex $m_displayList $i]
        if {[catch {
            $display setCurrentGrid $id
        } errMsg]} {
            log_error setCurrentGrid failed for $display: $errMsg
        }
    }

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

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -canvas canvas Canvas "" {
        if {$itk_option(-canvas) != ""} {
            $itk_option(-canvas) register $this toolMode handleToolModeEvent
        }
    }

    ### forGrid, forL614, forCrystal
    itk_option define -purpose purpose Purpose $gGridPurpose { repack }

    public proc toolModeMappingByPurpose { mode purpose } {
        if {$mode == "adjust"} {
            return $mode
        }
        switch -exact -- $purpose {
            forCrystal -
            forLCLSCrystal {
                return add_crystal
            }
            forPXL614 -
            forL614 {
                switch -exact -- $mode {
                    add_trap_array -
                    add_mesh -
                    add_l164 {
                        return $mode
                    }
                }
                return add_l614
            }
        }
        switch -exact -- $mode {
            add_l614 -
            add_trap_array -
            add_mesh -
            add_crystal {
                return "add_rectangle"
            }
        }
        return $mode
    }

    public method addInputToDeleteAndHide { trigger_ } {
        foreach name {delete hide} {
            $itk_component($name) addInput $trigger_
        }
    }

    public method handleToolModeEvent { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        #puts "handleToolModeEvent: $contents_"
        onToolModeChange $contents_
    }

    public method setToolMode { mode } {
        gCurrentGridGroup setWidgetToolMode $mode
        set head [string range $mode 0 3]
        if {$head == "add_"} {
            set shape [string range $mode 4 end]
            set contents [$m_objLatestUserSetup getContents]
            set dd [eval dict create $contents]
            dict set dd shape $shape
            $m_objLatestUserSetup sendContentsToServer $dd
        }
        if {$mode == "add_crystal"} {
            if {[catch {
                if {$itk_option(-mdiHelper) != ""} {
                    $itk_option(-mdiHelper) openToolChest define_crystal
                }
            } errMsg]} {
                puts "open define_crystal failed: $errMsg"
            }
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
        if {$currentMode == "adjust"} {
            pack $itk_component(delete) -after $itk_component(adjust) -side left
        } else {
            pack forget $itk_component(delete) $itk_component(hide) 
        }

    }

    private method repack { } {
        set all [pack slaves $itk_interior]
        if {$all != ""} {
            eval pack forget $all
        }
        switch -exact -- $itk_option(-purpose) {
            forLCLS -
            forGrid {
                foreach name $m_toolModeList {
                    switch -exact -- $name {
                        add_l614 -
                        add_crystal -
                        add_trap_array -
                        add_mesh {
                            ## skip
                        }
                        default {
                            pack $itk_component($name) -side left
                        }
                    }
                }
            }
            forPXL614 -
            forL614 {
                pack $itk_component(add_l614) -side left
                pack $itk_component(add_trap_array) -side left
                pack $itk_component(add_mesh) -side left
                pack $itk_component(adjust) -side left
            }
            forCrystal -
            forLCLSCrystal {
                pack $itk_component(add_crystal) -side left
                pack $itk_component(adjust) -side left
            }
            default {
                foreach name $m_toolModeList {
                    pack $itk_component($name) -side left
                }
            }
        }

        pack $itk_component(delete) -side left
        #pack $itk_component(hide) -side left
        pack $itk_component(zoom_in) -side left
        pack $itk_component(zoom_out) -side left
    }

    private variable m_toolModeList [list \
    add_l614 \
    add_trap_array \
    add_mesh \
    add_rectangle \
    add_oval \
    add_line \
    add_polygon \
    add_crystal \
    adjust \
    ]

    private variable m_toolModeLabel [list \
    grid \
    trap_array \
    mesh \
    projective \
    rectangle \
    oval \
    line \
    polygon \
    "define new crystal" \
    modify \
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
            DCS::Button $itk_interior.del \
            -text "delete" \
            -command "$this command deleteSelected"
        } {
        }
        $itk_component(delete) addInput \
        "::gCurrentGridGroup current_grid_deletable 1 {try reset first}"

        itk_component add hide {
            DCS::Button $itk_interior.hide \
            -text "hide" \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -command "$this command hideSelected"
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

        registerComponent \
        $itk_component(add_l614) \
        $itk_component(add_trap_array) \
        $itk_component(add_mesh) \
        $itk_component(add_rectangle) \
        $itk_component(add_oval) \
        $itk_component(add_line) \
        $itk_component(add_polygon) \
        $itk_component(add_crystal) \
        $itk_component(adjust) \
        $itk_component(delete)

        announceExist
    }
}
class GridCanvasPositioner {
    inherit ::DCS::ComponentGateExtension

    itk_option define -holder holder Holder ""

    private variable m_objGridGroupConfig ""

    public method sizeGrid { act } {
        set gridId [gCurrentGridGroup getCurrentGridId]
        if {$gridId < 0} {
            return
        }
        foreach {w h} [gCurrentGridGroup getGridItemSize $gridId] break
        set stepSize [lindex [$itk_component(moveStep) get] 0]

        set shape [gCurrentGridGroup getGridShape $gridId]
        switch -exact -- $shape {
            projective -
            trap_array -
            mesh -
            crystal -
            l614 {
                #log_error sizing not supported for $shape
                #return
            }
        }

        set param [dict create]
        switch -exact -- $act {
            horzExpand {
                if {$shape == "line" && $w == 0} {
                    return
                }
                set w [expr $w + $stepSize]
                set param [dict create item_width $w]
            }
            horzShrink {
                if {$w > $stepSize} {
                    set w [expr $w - $stepSize]
                    set param [dict create item_width $w]
                } elseif {$shape == "line" && $h > 0 && $w > 0} {
                    set param [dict create item_width 0]
                } else {
                    log_error too small to shrink
                    return
                }
            }
            vertExpand {
                if {$shape == "line" && $h == 0} {
                    return
                }
                set h [expr $h + $stepSize]
                set param [dict create item_height $h]
            }
            vertShrink {
                if {$h > $stepSize} {
                    set h [expr $h - $stepSize]
                    set param [dict create item_height $h]
                } elseif {$shape == "line" && $h > 0 && $w > 0} {
                    set param [dict create item_height 0]
                } else {
                    log_error too small to shrink
                    return
                }
            }
        }
        if {$param == ""} {
            return
        }

        puts "sizeGrid: param=$param"

        if {$itk_option(-holder) == ""} {
            if {![gCurrentGridGroup adjustCurrentGrid $param]} {
                log_error moving must be done with image display.
            }
        } else {
            if {![gCurrentGridGroup adjustCurrentGridOnDisplay \
            $itk_option(-holder)  $param]} {
                log_error moving must be done with image display.
            }
        }
    }

    public method moveGrid { dir } {
        set gridId [gCurrentGridGroup getCurrentGridId]
        if {$gridId < 0} {
            return
        }
        set stepSize [lindex [$itk_component(moveStep) get] 0]
        switch -exact -- $dir {
            left {
                set horz [expr -1 * $stepSize]
                set vert 0
            }
            right {
                set horz $stepSize
                set vert 0
            }
            up {
                set horz 0
                set vert [expr -1 * $stepSize]
            }
            down {
                set horz 0
                set vert $stepSize
            }
            default {
                return
            }
        }
        if {[gCurrentGridGroup getCurrentGridShape] == "crystal"} {
            set param [dict create \
            move_crystal [list $horz $vert] \
            ]

            if {$itk_option(-holder) == ""} {
                if {![gCurrentGridGroup adjustCurrentGrid $param]} {
                    log_error moving crystal must be done with image display.
                }
            } else {
                if {![gCurrentGridGroup adjustCurrentGridOnDisplay \
                $itk_option(-holder)  $param]} {
                    log_error moving crystal must be done with image display.
                }
            }
            return
        }
        set groupId [gCurrentGridGroup getId]
        $m_objGridGroupConfig startOperation moveGrid \
        $groupId $gridId $horz $vert
    }

    constructor { args } {
        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        itk_component add moveGridFrame {
            frame $itk_interior.moveF
        } {
        }
        set moveSite $itk_component(moveGridFrame)
        itk_component add moveLabel {
            label $moveSite.label \
            -text "Positioning: "\
            -anchor e \
        } {
        }
        pack $itk_component(moveLabel) -side left
        itk_component add moveStep {
            ::DCS::MenuEntry $moveSite.padStep \
            -leaveSubmit 1 \
	        -decimalPlaces 1 \
            -menuChoices {1 2 5 10 20 50 100 200 500 1000 2000} \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 1 \
        } {
        }
        $itk_component(moveStep) setValue 10.0
        pack $itk_component(moveStep) -side left
        foreach dir {left right up down} {
            itk_component add button_$dir {
                DCS::ArrowButton $moveSite.$dir $dir \
			    -debounceTime 100  \
                -background #c0c0ff \
                -command "$this moveGrid $dir"
            } {
            }
            pack $itk_component(button_$dir) -side left
            $itk_component(button_$dir) addInput \
            "::gCurrentGridGroup current_grid_editable 1 {reset first}"

            registerComponent $itk_component(button_$dir)
        }
        itk_component add sizeLabel {
            label $moveSite.sslabel \
            -text "   Sizing:"\
            -anchor e \
        } {
        }
        pack $itk_component(sizeLabel) -side left
        foreach act {horzExpand horzShrink vertExpand vertShrink} {
            itk_component add button_$act {
                DCS::ArrowButton $moveSite.$act $act \
			    -debounceTime 100  \
                -background #c0c0ff \
                -command "$this sizeGrid $act"
            } {
            }
            pack $itk_component(button_$act) -side left
            $itk_component(button_$act) addInput \
            "::gCurrentGridGroup current_grid_editable 1 {reset first}"

            registerComponent $itk_component(button_$act)
        }

        pack $itk_component(moveGridFrame)
        eval itk_initialize $args
        
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

    public method setNotice { txt {color blue}}

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

    public method onItemClick { item row column }
    public method onItemRightClick { item row column }
    public method moveTo { item x y index }

    public method zoomIn { }
    public method zoomOut { }

    public method getZoomCenterX { }
}

### I try to separate the GUI item from GridBase.
### so that the GUI can be used for something else too.

### Any change from GUI should trigger recalulcate of the informations to save.

class GridItemBase {
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

    public method match { matchList } {
        foreach guiId $m_allGuiIdList {
            if {[lsearch -exact $matchList $guiId] >= 0} {
                return 1
            }
        }
        if {[lsearch -exact $matchList grid_$m_guiId] >= 0} {
            return 1
        }
        if {[lsearch -exact $matchList hotspot_$m_guiId] >= 0} {
            return 1
        }

        return 0
    }

    ### for phi check. If grid is almost 90 degree from view,
    ### it is better not adjust from vdieo.
    public method adjustableOnVideo { {relax_ 0} } {
        if {![shouldDisplay]} {
            return 0
        }
        set showDetail [lindex [shouldShowDetail] 0]
        if {!$showDetail} {
            return 0
        }

        if {$m_mode != "adjustable" && !$relax_} {
            return 0
        }

        if {$m_manualTranslate} {
            # this is 3D, no phi check.
            return 1
        }

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
        if {$diff < 88.0} {
            return 1
        } else {
            return 0
        }
    }

    ### outbox with rotation
    public method getCorners { } { return $m_corner }
    public method cornerPress { index x y }
    public method cornerMotion { x y }

    public method rotateFromVideo { startAngle endAngle {radians 0} } {
        if {$radians} {
            set av0 $startAngle
            set av1 $endAngle
        } else {
            set av0 [expr $startAngle * 3.14159 / 180.0]
            set av1 [expr $endAngle   * 3.14159 / 180.0]
        }
        ### startAngle and endAngle are in video view
        ### now in my plane.
        set a0 [angleVideoToFrame $av0]
        set a1 [angleVideoToFrame $av1]

        return [GridItemBase::rotate [expr $a1 - $a0] 1]
    }

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
            foreach guiId $m_allGuiIdList {
                $m_canvas raise $guiId
            }
            $m_canvas raise grid_$m_guiId
        } else {
            $m_canvas raise grid_$m_guiId
            foreach guiId $m_allGuiIdList {
                $m_canvas raise $guiId
            }
        }

        $m_canvas raise group
        $m_canvas raise beam_info
        $m_canvas raise hotspot_$m_guiId
    }
    ### for now, we use the matrix center.
    public method getCenter { }
    public method getBBox { }
    public method groupRotate { centerX centerY start end {radians 0} } {
        if {$radians} {
            set av0 $start
            set av1 $end
        } else {
            set av0 [expr $start * 3.14159 / 180.0]
            set av1 [expr $end   * 3.14159 / 180.0]
        }
        set da [expr $av1 - $av0]
        set newSelfCenter \
        [rotateCalculation $centerX $centerY $da $m_centerX $m_centerY]

        foreach {m_centerX m_centerY} $newSelfCenter break

        #set newGridCenter \
        #[rotateCalculation $centerX $centerY $a $m_gridCenterX $m_gridCenterY]
        #foreach {m_gridCenterX m_gridCenterY} $newGridCenter break
        saveShape

        set a0 [angleVideoToFrame $av0]
        set a1 [angleVideoToFrame $av1]
        set a  [expr $a1 - $a0]

        set m_oAngle [expr $m_oAngle + $a]
        updateLocalCoords
        updateCornerAndRotor
        updateGrid
        redraw 1

        #comparing to rotate, this one also updateGrid.
    }
    ### group move needs rework too, needs pass in the video frame change.
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
        foreach {showDetail diffA} [shouldShowDetail] break

        if {$m_showVertexAndMatrix && $showDetail} {
            redrawGridMatrix
        } else {
            $m_canvas delete grid_$m_guiId
        }
        if {$m_showVertexAndMatrix && !$showDetail && $m_status == "selected"} {
            foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
            $m_canvas create text $x2 $y1 \
            -text "[format %+.0f $diffA] degrees to see grid" \
            -font "-family courier -size 12" \
            -fill $GridGroupColor::COLOR_SHAPE_CURRENT \
            -anchor se \
            -justify right \
            -tags \
            [list grid grid_$m_guiId \
            item_$m_guiId]
        }
    }

    public method redraw { fromGUI }
    ### redrawHotSpots according to m_status
    ### all redraw should have a call to redrawHotSpots
    ### redrawHotSpot will call generateMatrix or rebornMatrix by fromGUI
    protected method redrawHotSpots { fromGUI }

    public method shouldDisplay { }

    ### this is more strict than first half of shoulldDisplay
    public proc itemFitPurpose { \
        purpose shape forLCLS {allowRasterForCrystal 0} \
    }

    public method shouldShowDetail { }

    public method getShape { } {
        return "undefined"
    }

    public method setForLCLS { one_or_zero } {
        ## this will be passed to grid in geo with key "for_lcls"
        ## also read back from geo info.
        set m_forLCLS $one_or_zero
    }
    public method getForLCLS { } { return $m_forLCLS }

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

    ### user can adjust grid size by typing numbers in micron.
    ### very similar to vertexMotion 
    ### so, this base method can be used by rectange and oval,
    ### others may need to override.
    public method manualScale { w h } {
        if {[string is double -strict $w]} {
            set w [expr abs($w)]
            if {$m_oHalfWidth < 0} {
                set w [expr -1 * $w]
            }
            if {$m_oHalfWidth != 0} {
                set scaleW [expr 0.5 * $w / $m_oHalfWidth]
                set newLocalCoords ""
                foreach {x y} $m_oLocalCoords {
                    set ox [expr $x * $scaleW]
                    lappend newLocalCoords $ox $y
                }
                set m_oLocalCoords $newLocalCoords
            }
            set m_oHalfWidth  [expr $w / 2.0]
            ## m_oItemWidth will be recalculated in redraw 1
        }
        if {[string is double -strict $h]} {
            set h [expr abs($h)]
            if {$m_oHalfHeight < 0} {
                set h [expr -1 * $h]
            }
            if {$m_oHalfHeight != 0} {
                set scaleH [expr 0.5 * $h / $m_oHalfHeight]
                set newLocalCoords ""
                foreach {x y} $m_oLocalCoords {
                    set oy [expr $scaleH * $y]
                    lappend newLocalCoords $x $oy
                }
                set m_oLocalCoords $newLocalCoords
            }
            set m_oHalfHeight [expr $h / 2.0]
        }
        updateLocalCoords
        updateCornerAndRotor
        redraw 1

        return 1
    }
    
    ### selected
    public method vertexPress { index x y }
    public method vertexMotion { x y } {
        ### rectangle and orval should use this.
        ### others have to override.
        cornerMotion $x $y
        redraw 1
    }
    public method vertexRelease { x y } {
        $m_holder onItemChange $this
    }
    public method vertexEnter { index x y cursor }
    public method enter { }
    public method leave { } { }
    ### matchList will pass in if called by BeamInfoPress
    public method bodyPress { x y {matchList {}} }
    public method bodyMotion { x y }
    public method bodyRelease { x y } {
        set shape [getShape]
        if {$m_motionCalled} {
            $m_holder onItemChange $this
        } elseif {!$m_newCurrentItem \
        && $shape != "l614" \
        && $shape != "projective" \
        && $shape != "trap_array" \
        && $shape != "mesh" \
        && $shape != "crystal" \
        && $shape != "line" \
        } {
            set clickInfo [getClickInfo $x $y]
            if {$clickInfo != ""} {
                foreach {row col ux uy} $clickInfo break
                if {[isNodeDone $row $col]} {
                    set index [expr $row * $m_numCol + $col]
                    $m_holder moveTo $this $ux $uy $index
                } else {
                    $m_holder onItemClick $this $row $col
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
            set clickInfo [getClickInfo $x $y $m_pressRow $m_pressCol]
            if {$clickInfo != ""} {
                foreach {- - ux uy} $clickInfo break
                if {[isNodeDone $m_pressRow $m_pressCol]} {
                    set index [expr $m_pressRow * $m_numCol + $m_pressCol]
                    $m_holder moveTo $this $ux $uy $index
                } else {
                    $m_holder onItemClick $this $m_pressRow $m_pressCol
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

    protected method updateFromParameter { parameter {must_have 1} } {}

    #### initialized by another GUI to adjust grid position, size, grid cell.
    #### It will cause regenerate matrix and send modifyGrid operation
    public method adjustItem { param {extra ""} }
    public method getItemSizeInPixel { } {
        if {![shouldDisplay]} {
            return [list 0 0]
        }
        return [list [expr abs($m_itemWidth)] [expr abs($m_itemHeight)]]
    }

    public method setNode { index status }

    public method getHide { } {
        return $m_hide
    }
    public method setHide { h } {
        puts "trying set  hide=$h for $this"
        set m_hide $h
        refresh
    }

    ### major operation:
    ###   translate:     from orignal to pixel
    ###   saveItemInfo:  from pixel to original
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
        if {$m_manualTranslate} return

        #puts "saveShape center pixel: $m_centerX $m_centerY"
        set displayOrig [$m_holder getDisplayOrig]

        foreach {m_uCenterX m_uCenterY} \
        [$m_holder pixel2micron \
        $m_centerX $m_centerY] break
        #puts "saveShape center micron: $m_uCenterX $m_uCenterY"
        if {[catch {
            foreach {m_oCenterX m_oCenterY} [reverseProjection \
            $m_uCenterX $m_uCenterY $displayOrig $m_oOrig] break
        } errMsg]} {
            return
        }
        #puts "saveShape center orig: $m_oCenterX $m_oCenterY"

        if {$displayOrig != $m_oOrig} {
            #puts "saveShape oOrig=$m_oOrig display=$displayOrig"
        }
    }
    protected method saveMatrix { } {
        if {$m_manualTranslate} return

        set displayOrig [$m_holder getDisplayOrig]

        foreach {m_uGridCenterX m_uGridCenterY m_uCellWidth m_uCellHeight} \
        [$m_holder pixel2micron \
        $m_gridCenterX $m_gridCenterY $m_cellWidth $m_cellHeight] break

        if {[catch {
            foreach {m_oGridCenterX m_oGridCenterY} [reverseProjection \
            $m_uGridCenterX $m_uGridCenterY $displayOrig $m_oOrig] break
    
            foreach {m_oCellWidth m_oCellHeight} [reverseProjectionBox \
            $m_uCellWidth $m_uCellHeight $displayOrig $m_oOrig] break
        } errMsg]} {
            return
        }

        ### item size is saved right after it changes.
        #foreach {m_uItemWidth m_uItemHeight} \
        #[$m_holder pixel2micron \
        #$m_itemWidth $m_itemHeight] break

        #foreach {m_oItemWidth m_oItemHeight} [reverseProjectionBox \
        #$m_uItemWidth $m_uItemHeight $displayOrig $m_oOrig] break
    }
    protected method saveLocalCoords { } {
        if {$m_manualTranslate} return


        #puts "saveLocalCoords for $this: $m_localCoords"
        set displayOrig [$m_holder getDisplayOrig]
        set displaySize [$m_holder getDisplayPixelSize]
        $s_quickTransObj setup $m_oOrig $displayOrig $displaySize \
        $m_oAngle $m_uCenterX $m_uCenterY $m_oCenterX $m_oCenterY

        $s_quickTransObj saveLocalCoords
    }

    ## used in creation or stretch
    protected method saveSize { width height } {
        if {$m_manualTranslate} return

        set displayOrig [$m_holder getDisplayOrig]

        foreach {uW uH} [$m_holder pixel2micron $width $height] break

        if {[catch {
            foreach {oX oY} \
            [reverseProjectionBox $uW $uH $displayOrig $m_oOrig] break
        } errMsg]} {
            return
        }

        foreach {oW oH} [rotateDeltaToDelta \
        0 0 [expr -1 * $m_oAngle] $oX $oY] break

        ### m_oHalfSize can be forced to positive too, will not affect anything
        set m_oHalfWidth  [expr $oW / 2.0]
        set m_oHalfHeight [expr $oH / 2.0]
    }

    ### item size is for camera zoom.
    ### they are really from the GUI.
    ### you can calculate them from shape, geo and angle.
    protected method saveItemSize { } {
        if {[catch {
            foreach {m_uItemWidth m_uItemHeight} \
            [$m_holder pixel2micron $m_itemWidth $m_itemHeight] break

            set displayOrig [$m_holder getDisplayOrig]

            foreach {m_oItemWidth m_oItemHeight} [reverseProjectionBox \
            $m_uItemWidth $m_uItemHeight $displayOrig $m_oOrig] break
        } errMsg]} {
            puts "failed to saveItemSize: $errMsg"
            return 0
        } else {
            return 1
        }
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
        if {![adjustableOnVideo $relax_]} {
            return 1
        }
        if {[$m_displayControl getClickToMove]} {
            return 1
        }
        return 0
    }

    public method getTKItems { } {
        if {$m_guiId == ""} {
            return ""
        }
        set result $m_allGuiIdList
        lappend result hotspot_$m_guiId grid_$m_guiId item_$m_guiId

        return $result
    }

    ### rotation
    public method rotorPress { xw yw }
    public method rotorMotion { x y }
    public method rotorRelease { x y } {
        $m_holder onItemChange $this
    }

    public method getItemStatus { } { return $m_status }
    public method rotorEnter { x y }

    protected method angleFrameToVideo { a }
    protected method angleVideoToFrame { a }

    protected method setItemStatus { s }
    protected method drawOutline { }
    protected method drawAllVertices { }
    protected method drawRotor { }

    protected method removeAllGui { } {
        foreach guiId $m_allGuiIdList {
            $m_canvas delete $guiId
        }
        set m_allGuiIdList ""

        $m_canvas delete hotspot_$m_guiId
        $m_canvas delete grid_$m_guiId
        $m_canvas delete item_$m_guiId

        set m_guiId ""
    }

    #### gridRelease will call with row and column
    protected method getClickInfo { x y {row ""} {column ""} }
    protected method isNodeDone { row col } {
        set index [expr $row * $m_numCol + $col]
        if {$index < 0 || $index >= $m_numCol * $m_numRow} {
            return 0
        }
        set status [lindex $m_nodeList $index]
        set first [lindex $status 0]
        if {[string is double -strict $first]} {
            return 1
        }
        switch -exact -- $status {
            D {
                return 1
            }
        }
        return 0
    }

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

    ### still needs to honor - and --, not existing nodes.
    protected method generateEmptyDisplayList { }

    protected method getNumberDisplayList { }
    protected method getContourDisplayList { }
    protected method getNumberDisplayValue { index node }
    protected method getContourDisplayValue { node }
    protected method getContourLevels { }

    ### these two may replace or replaced by xyToGenericPosition
    protected method xyToSamplePosition { x y } {
        set displayOrig [$m_holder getDisplayOrig]
        foreach {uX uY} [$m_holder pixel2micron $x $y] break
        set pos [calculateSamplePositionFromVideoClick $displayOrig $uX $uY 1]

        return $pos
    }
    protected method samplePositionToXy { pos } {
        set displayOrig [$m_holder getDisplayOrig]
        foreach {uX uY} \
        [calculateSamplePositionOnVideo $displayOrig $pos 1] break

        foreach {x y} [$m_holder micron2pixel $uX $uY] break

        return [list $x $y $uX $uY]
    }
    public variable cursorBody fleur

    private common RASTER_NUM 1
    protected variable m_itemId ""

    protected variable m_canvas ""
    protected variable m_guiId ""
    protected variable m_allGuiIdList ""
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

    ### we need to remember the init press position.
    ### m_pressX and m_pressY are updated during motion.
    ### Following are not updated.
    protected variable m_initPressX 0
    protected variable m_initPressY 0

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
    protected variable m_oItemWidth  100.0
    protected variable m_oItemHeight 100.0

    protected variable m_extraUserParameters ""

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

    protected variable m_uItemWidth  100.0
    protected variable m_uItemHeight 100.0

    ## in pixels.
    protected variable m_centerX 100
    protected variable m_centerY 200
    protected variable m_corner "50 150 150 150 150 250 50 250"
    protected variable m_rotor "100 150 100 50"

    ### on local frame just centered at m_centerX/Y.
    protected variable m_localCoords ""

    #protected variable m_gridSequenceType horz
    ### variable in pixels normally are positive.
    #protected variable m_gridSequenceType vert
    ###protected variable m_gridSequenceType zigzag
    #protected variable m_gridSequenceType fixed_vert_zigzag
    protected variable m_gridSequenceType horz_reverse
    protected variable m_gridCenterX 100
    protected variable m_gridCenterY 100
    protected variable m_numRow 1
    protected variable m_numCol 1
    protected variable m_cellWidth 10
    protected variable m_cellHeight 10
    protected variable m_itemWidth  100
    protected variable m_itemHeight 100
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
    ####
    #### "crystal" will do call translate ans save by itself.
    #### It is 3-D object, not a 2-D plane crossing phi axis.
    protected variable m_manualTranslate 0

    protected variable m_motionCalled 0
    protected variable m_newCurrentItem 0

    protected variable m_hide 0

    protected variable m_forLCLS 0

    ### C++ class for contour
    protected variable m_obj
    protected variable m_contour

    protected variable m_displayControl ""

    protected common s_quickTransObj [createNewDcsCoordsTranslate]

    constructor { canvas id mode holder } {


        #puts "base constructor"
        set m_itemId $RASTER_NUM
        incr RASTER_NUM

        set m_canvas $canvas
        set m_guiId $id
        set m_allGuiIdList $id
        set m_mode $mode
        set m_holder $holder
        set m_oOrig [$m_holder getDisplayOrig]
        set m_displayControl [$m_holder getDisplayControl]
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
body GridItemBase::getClickInfo { x y {row ""} {column ""} } {
    puts "getClickInfo $x $y for $this"
    if {$m_cellHeight == 0 || $m_cellWidth == 0} {
        return ""
    }
    set gridWidth  [expr abs($m_numCol * $m_cellWidth)]
    set gridHeight [expr abs($m_numRow * $m_cellHeight)]

    puts "DEBUG: numCol=$m_numCol cellWidth=$m_cellWidth"
    puts "DEBUG: gridwidth=$gridWidth center at $m_gridCenterX"

    ### shape l614, the center is at anchor points center, not real center.
    set shape [getShape]
    switch -exact -- $shape {
        line -
        crystal -
        projective -
        trap_array -
        mesh -
        l614 {
            ## no check
        }
        default {
            #### grid for others never rotate, alway level and vert.
            set x0 [expr $m_gridCenterX - $gridWidth  / 2.0]
            set y0 [expr $m_gridCenterY - $gridHeight / 2.0]
            set x1 [expr $m_gridCenterX + $gridWidth  / 2.0]
            set y1 [expr $m_gridCenterY + $gridHeight / 2.0]
            if {$x < $x0 || $x >= $x1 || $y < $y0 || $y >= $y1} {
                puts "click $x $y out of grid $x0 $y0 $x1 $y1"
                return ""
            }
        }
    }
    set localX [expr $x - $m_gridCenterX]
    set localY [expr $y - $m_gridCenterY]

    foreach {ux uy} [$m_holder pixel2micron $x $y] break

    set displayOrig [$m_holder getDisplayOrig]
    if {[catch {
        foreach {ox oy} [reverseProjection $ux $uy $displayOrig $m_oOrig] break
    } errMsg]} {
        puts "reverseProjection for getClickInfo failed: $errMsg"
        return ""
    }
    set oxLocal [expr $ox - $m_oGridCenterX]
    set oyLocal [expr $oy - $m_oGridCenterY]

    if {$column == ""} {
        set column [expr int($localX / $m_cellWidth  + $m_numCol / 2.0)]
    }
    if {$row == ""} {
        set row    [expr int($localY / $m_cellHeight + $m_numRow / 2.0)]
    }

    return [list $row $column $oxLocal $oyLocal]
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

    foreach {showDetail diffA} [shouldShowDetail] break

    if {$m_showVertexAndMatrix && $showDetail} {
        if {$fromGUI} {
            generateGridMatrix
        } else {
            rebornGridMatrix
        }
    } else {
        $m_canvas delete grid_$m_guiId
    }

    switch -exact -- [getShape] {
        crystal -
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
            foreach guiId $m_allGuiIdList {
                $m_canvas itemconfigure $guiId -$att $color
            }
            if {[adjustableOnVideo]} {
                showHotSpots
            } elseif {!$showDetail} {
                foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
                $m_canvas create text $x2 $y1 \
                -text "[format %+.0f $diffA] degrees to see grid" \
                -font "-family courier -size 12" \
                -fill $GridGroupColor::COLOR_SHAPE_CURRENT \
                -anchor se \
                -justify right \
                -tags \
                [list grid grid_$m_guiId \
                item_$m_guiId]
            }
        }
        normal -
        silent -
        grouped -
        default {
            set color $GridGroupColor::COLOR_SHAPE
            foreach guiId $m_allGuiIdList {
                $m_canvas itemconfigure $guiId -$att $color
            }
        }
    }
}
## 4 corners with rotation
body GridItemBase::updateCornerAndRotor { {onlyZoom 0} } {
    if {$m_manualTranslate} return

    if {!$onlyZoom} {
        set displayOrig [$m_holder getDisplayOrig]
        set oCorner ""

        set hw [expr abs($m_oHalfWidth)]
        set hh [expr abs($m_oHalfHeight)]

        foreach {x y} [list \
        -$hw -$hh \
         $hw -$hh \
         $hw  $hh \
        -$hw  $hh \
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
        $m_holder registerButtonCallback "" ""
        return
    }
    set m_pressX $x
    set m_pressY $y
    set m_initPressX $x
    set m_initPressY $y

    $m_holder clearCurrentItem

    $m_holder registerButtonCallback "$this createMotion" "$this createRelease"
}
body GridItemBase::vertexPress { index xw yw } {
    if {[noResponse]} {
        $m_holder registerButtonCallback "" ""
        return
    }

    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]
    set m_pressX $x
    set m_pressY $y
    set m_initPressX $x
    set m_initPressY $y
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
body GridItemBase::bodyPress { xw yw {matchList {}} } {
    puts "base bodyPRess for $this"

    if {[$m_displayControl getClickToMove]} {
        puts "skip, in click_to_move"
        return
    }

    set m_motionCalled 0

    ### we want to allow flip.
    if {[noResponse 1]} {
        puts "noResponse, so quit"
        $m_holder clearCurrentItem
        $m_holder registerButtonCallback "" ""
        return
    }

    if {$matchList != "" && $m_showVertexAndMatrix} {
        puts "called from beamClick matchlist=$matchList"
        ## vertex first
        set pattern hotspot_${m_guiId}_*
        set index [lsearch -glob $matchList $pattern]
        if {$index >= 0} {
            set tag [lindex $matchList $index]
            puts "search vertex get tag=$tag"
            set vIdx -1
            scan $tag "hotspot_${m_guiId}_%d" vIdx
            if {$vidx >= 0} {
                puts "forward to vertextPress"
                vertexPress $vidx $xw $yw
            }
            return
        }
        ### search node
        set pattern node_${m_guiId}_*
        set index [lsearch -glob $matchList $pattern]
        if {$index >= 0} {
            set tag [lindex $matchList $index]
            puts "search node get tag=$tag"
            set nIdx -1
            scan $tag "node_${m_guiId}_%d" nIdx
            if {$nIdx >= 0} {
                set row [expr $nIdx / $m_numCol]
                set col [expr $nIdx % $m_numCol]
                puts "forward to gridPress"
                gridPress $row $col $xw $yw
            }
            return
        }
    }

    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]
    set m_pressX $x
    set m_pressY $y
    set m_initPressX $x
    set m_initPressY $y

    #showHotSpots

    ### from user click, fire the event
    set m_newCurrentItem [$m_holder setCurrentItem $this]

    $m_holder registerButtonCallback "$this bodyMotion" "$this bodyRelease"
}
body GridItemBase::gridPress { row col xw yw } {
    puts "$this gridPress $row $col"
    set callLevel [info level]
    for {set i 0} {$i <= $callLevel} {incr i} {
        set cmd [info level $i]
        puts "level $i=$cmd"
    }
    
    set m_motionCalled 0

    if {[noResponse 1]} {
        puts "noResponse, so quit"
        $m_holder registerButtonCallback "" ""
        return
    }

    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]
    set m_pressX $x
    set m_pressY $y
    set m_initPressX $x
    set m_initPressY $y
    set m_pressRow $row
    set m_pressCol $col

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
    if {$m_guiId == ""} {
        return
    }

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
    foreach guiId $m_allGuiIdList {
        $m_canvas move $guiId $dx $dy
    }
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
    if {$m_guiId == ""} {
        return
    }
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
    set index -1
    foreach guiId $m_allGuiIdList {
        set vList [$m_canvas coords $guiId]
        foreach {x y} $vList {
            incr index
            drawVertex $index $x $y
        }
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
    $m_canvas raise hotspot_$m_guiId
}
body GridItemBase::drawRotor { } {
    if {$m_guiId == ""} {
        return
    }

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

        if {[adjustableOnVideo]} {
            generateGridMatrix
        }
        return
    }

    contourSetup
    redrawGridMatrix
}
body GridItemBase::redrawGridMatrix { } {
    if {$m_guiId == ""} {
        return
    }
    if {![shouldDisplay]} {
        removeAllGui
        return
    }
    set nodeColorList [getContourDisplayList]
    $m_obj setValues $nodeColorList

    set nodeLabelList [getNumberDisplayList]
    set font_sizeW [expr int(abs(0.33 * $m_cellWidth))]
    set font_sizeH [expr int(abs(0.33 * $m_cellHeight))]
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

    set noFill 0
    if {[string first only [getContourLevels]] >= 0} {
        set noFill 1
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
            if {$noFill} {
                set fill ""
                set stipple ""
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

    foreach guiId $m_allGuiIdList {
        $m_canvas raise $guiId
    }
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info
    $m_canvas raise hotspot_$m_guiId
}
body GridItemBase::redrawContour { } {
    $m_canvas delete contour_$m_guiId
    if {$m_mode != "done"} {
        return
    }

    if {$m_guiId == ""} {
        # this is must.  This method is also called by "setMode"
        return
    }

    set gridWidth  [expr $m_numCol * $m_cellWidth]
    set gridHeight [expr $m_numRow * $m_cellHeight]
    set x0 [expr $m_gridCenterX - $gridWidth  / 2.0]
    set y0 [expr $m_gridCenterY - $gridHeight / 2.0]

    $m_obj setAllData
    foreach level [getContourLevels] {
        if {![string is double -strict $level]} {
            continue
        }
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
    foreach guiId $m_allGuiIdList {
        $m_canvas raise $guiId
    }
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info
    $m_canvas raise hotspot_$m_guiId
}
body GridItemBase::generateGridMatrix { } {
    if {$m_guiId == ""} {
        return
    }
    #puts "generateGridMatrix for $this"
    set m_nodeList ""
    $m_canvas delete grid_$m_guiId

    if {$m_cellWidth == 0 || $m_cellHeight == 0} {
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

    set m_itemWidth   [expr ($bx2 - $bx1) * 1.0]
    set m_itemHeight  [expr ($by2 - $by1) * 1.0]
    if {$m_itemWidth <= 0 && $m_itemHeight <= 0} {
        puts "raster not ready, box size=0"
        return
    }
    if {![saveItemSize]} {
        return
    }

    #puts "cell size: $m_cellWidth X $m_cellHeight"
    #puts "item size $m_itemWidth X $m_itemHeight"
    #puts "item size ooo: $m_oItemWidth X $m_oItemHeight"
    #puts "box $box"

    set m_numCol [expr int(ceil(abs($m_itemWidth  / $m_cellWidth)))]
    set m_numRow [expr int(ceil(abs($m_itemHeight / $m_cellHeight)))]

    if {$m_numCol < 1} {
        set m_numCol 1
    }
    if {$m_numRow < 1} {
        set m_numRow 1
    }
    contourSetup

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
            set touch 0
            foreach guiId $m_allGuiIdList {
                if {[lsearch -exact $matchList $guiId] >= 0} {
                    set touch 1
                    break
                }
            }
            if {$touch} {
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

    foreach guiId $m_allGuiIdList {
        $m_canvas raise $guiId
    }
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info
    $m_canvas raise hotspot_$m_guiId
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
    if {![adjustableOnVideo]} {
        $m_holder registerButtonCallback "" ""
        return
    }
    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]

    set m_pressX $x
    set m_pressY $y
    set m_initPressX $x
    set m_initPressY $y

    $m_holder registerButtonCallback "$this rotorMotion" "$this rotorRelease"
}
### use updateLocalCoords as reference to read this code.
body GridItemBase::angleFrameToVideo { a } {
    set displayOrig [$m_holder getDisplayOrig]
    set x [expr cos($a)]
    set y [expr sin($a)]
    foreach {ox oy} [rotateDelta $m_oCenterX $m_oCenterY $m_oAngle $x $y] break
    foreach {ux uy} [translateProjection $ox $oy $m_oOrig $displayOrig] break
    foreach {x y} [$m_holder micron2pixel $ux $uy] break
    set dx [expr $x - $m_centerX]
    set dy [expr $y - $m_centerY]

    set angle [expr atan2($dy, $dx)]
    return $angle
}
## use saveLocalCoords as reference for this code.
body GridItemBase::angleVideoToFrame { a } {
    set displayOrig [$m_holder getDisplayOrig]
    set xLocal [expr cos($a)]
    set yLocal [expr sin($a)]

    foreach {uxLocal uyLocal} [$m_holder pixel2micron $xLocal $yLocal] break
    set ux [expr $uxLocal + $m_uCenterX]
    set uy [expr $uyLocal + $m_uCenterY]

    if {[catch {
        foreach {ox oy} [reverseProjection $ux $uy $displayOrig $m_oOrig] break
    } errMsg]} {
        return $a
    }
    set a [expr -1 * $m_oAngle]
    foreach {dx dy} [rotateCalculationToDelta \
    $m_oCenterX $m_oCenterY $a $ox $oy] break

    set aa [expr atan2($dy, $dx)]
    return $aa
}
body GridItemBase::rotorMotion { x y } {
    if {![adjustableOnVideo]} {
        return
    }
    set displayOrig [$m_holder getDisplayOrig]

    set dx2 [expr $x - $m_centerX]
    set dy2 [expr $y - $m_centerY]
    set dx1 [expr $m_pressX - $m_centerX]
    set dy1 [expr $m_pressY - $m_centerY]
    set m_pressX $x
    set m_pressY $y

    if {$dx2 == 0 && $dy2 == 0} {
        return
    }
    if {$dx1 == 0 && $dy1 == 0} {
        return
    }
    set aa1 [expr atan2($dy1, $dx1)]
    set aa2 [expr atan2($dy2, $dx2)]

    rotateFromVideo $aa1 $aa2 1
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

    foreach guiId $m_allGuiIdList {
        foreach {x y} [$m_canvas coords $guiId] {
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
    lappend geoList size_width      $m_oItemWidth
    lappend geoList size_height     $m_oItemHeight
    lappend geoList for_lcls        $m_forLCLS
    set gridList ""

    #### here is the default sequenc type:
    lappend gridList type           $m_gridSequenceType
    lappend gridList num_row        $m_numRow
    lappend gridList num_column     $m_numCol
    if {$m_nodeLabelList != ""} {
        lappend gridList node_label_list $m_nodeLabelList
    }
    if {abs($displayAngle - $originalAngle) < 1 && !$m_manualTranslate} {
        ### use new, display view and orig

        set orig $displayOrig

        lappend geoList center_x        $m_uCenterX
        lappend geoList center_y        $m_uCenterY

        lappend gridList center_x       $m_uGridCenterX
        lappend gridList center_y       $m_uGridCenterY
        lappend gridList cell_width     [expr abs($m_uCellWidth)]
        lappend gridList cell_height    [expr abs($m_uCellHeight)]
    } else {
        ### use original view and orig

        set orig $m_oOrig

        lappend geoList center_x        $m_oCenterX
        lappend geoList center_y        $m_oCenterY

        lappend gridList center_x       $m_oGridCenterX
        lappend gridList center_y       $m_oGridCenterY
        lappend gridList cell_width     [expr abs($m_oCellWidth)]
        lappend gridList cell_height    [expr abs($m_oCellHeight)]
    }
    return [list $orig $geoList $gridList $m_nodeList $m_extraUserParameters]
}
body GridItemBase::reborn { gridId fromInfo } {
    removeAllGui
    set m_itemId $gridId

    updateFromInfo $fromInfo 0
}
body GridItemBase::updateFromInfo { info {redraw 1}} {
    foreach {orig geo grid node frame status hide parameter} $info break

    set m_oOrig        $orig
    set m_oCenterX     [dict get $geo center_x]
    set m_oCenterY     [dict get $geo center_y]
    set m_oHalfWidth   [dict get $geo half_width]
    set m_oHalfHeight  [dict get $geo half_height]
    set m_oLocalCoords [dict get $geo local_coords]
    set m_oAngle       [dict get $geo angle]
    set m_oItemWidth   [dict get $geo size_width]
    set m_oItemHeight  [dict get $geo size_height]

    if {[catch {dict get $geo for_lcls} m_forLCLS]} {
        set m_forLCLS 0
    }

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
    if {[dict exists $grid node_label_list]} {
        set m_nodeLabelList [dict get $grid node_label_list]
    }

    translate
    ### use m_numRow, m_numCol, m_oCellHeight, m_oCellWidth
    contourSetup

    setMode $status 0

    set m_hide $hide

    if {$redraw} {
        redraw 0
    }
}
body GridItemBase::adjustItem { param {extra ""} } {
    puts "adjustItem param=$param extra=$extra for $this"
    set need 0
    set m_extraUserParameters ""
    dict for {key value} $param {
        switch -exact -- $key {
            cell_width {
                set m_oCellWidth $value
                set m_extraUserParameters $extra
                updateFromParameter $extra
                updateGrid
                generateGridMatrix
                set need 1
            }
            cell_height {
                set m_oCellHeight $value
                set m_extraUserParameters $extra
                updateFromParameter $extra
                updateGrid
                generateGridMatrix
                set need 1
            }
            item_width {
                #set m_oHalfWidth [expr $value / 2.0]
                set m_extraUserParameters $extra
                if {[manualScale $value ""]} {
                    set need 1
                }
            }
            item_height {
                #set m_oHalfHeight [expr $value / 2.0]
                set m_extraUserParameters $extra
                if {[manualScale "" $value]} {
                    set need 1
                }
            }
            by_exposure_setup {
                set m_extraUserParameters $extra
                updateFromParameter $extra
                updateGrid
                generateGridMatrix
                set need 1
            }
            default {
                log_error unsupported adjust: $key $value
            }
        }
    }
    if {$need} {
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

    set noFill 0
    if {[string first only [getContourLevels]] >= 0} {
        set noFill 1
    }
    
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
        if {$noFill} {
            set fill ""
            set stipple ""
        }
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
    if {$noFill} {
        set fill ""
        set stipple ""
    }
    $m_canvas itemconfigure $nodeTag \
    -fill $fill \
    -stipple $stipple
}
body GridItemBase::updateShape { {onlyZoom 0} } {
    if {$m_manualTranslate} return
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
    if {$m_manualTranslate} return

    set displayOrig [$m_holder getDisplayOrig]
    set displaySize [$m_holder getDisplayPixelSize]
    $s_quickTransObj setup $m_oOrig $displayOrig $displaySize \
    $m_oAngle $m_uCenterX $m_uCenterY $m_oCenterX $m_oCenterY

    $s_quickTransObj updateLocalCoords $onlyZoom
}
body GridItemBase::updateGrid { {onlyZoom 0} } {
    if {$m_manualTranslate} return

    if {!$onlyZoom} {
        set displayOrig [$m_holder getDisplayOrig]

        foreach {m_uGridCenterX m_uGridCenterY} [translateProjection \
        $m_oGridCenterX $m_oGridCenterY $m_oOrig $displayOrig] break

        foreach {m_uCellWidth m_uCellHeight} [translateProjectionBox \
        $m_oCellWidth $m_oCellHeight $m_oOrig $displayOrig] break

        foreach {m_uItemWidth m_uItemHeight} [translateProjectionBox \
        $m_oItemWidth $m_oItemHeight $m_oOrig $displayOrig] break
    }

    foreach {m_gridCenterX m_gridCenterY m_cellWidth m_cellHeight} \
    [$m_holder micron2pixel \
    $m_uGridCenterX $m_uGridCenterY $m_uCellWidth $m_uCellHeight] break

    foreach {m_itemWidth m_itemHeight} \
    [$m_holder micron2pixel \
    $m_uItemWidth $m_uItemHeight] break
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
    if {$m_displayControl == ""} {
        set fieldName Frame
    } else {
        set fieldName [$m_displayControl getNumberField]
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
body GridItemBase::generateEmptyDisplayList { } {
    set resultList ""
    foreach node $m_nodeList {
        switch -exact -- $node {
            -- -
            - {
                set v -
            }
            default {
                set v ""
            }
        }
        lappend resultList $v
    }
    return $resultList
}
body GridItemBase::getContourDisplayList { } {
    if {$m_displayControl == ""} {
        set fieldName Spots
    } else {
        set fieldName [$m_displayControl getContourField]
    }
    switch -exact -- $fieldName {
        None {
            return [generateEmptyDisplayList]
        }
    }
    set index [lsearch -exact $GridNodeListView::FIELD_NAME $fieldName]
    if {$index < 0} {
        log_error bad field_name for contour $fieldName.
        return [generateEmptyDisplayList]
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
    if {$m_displayControl == ""} {
        return [list 10 25 50 75 90]
    } else {
        return [$m_displayControl getContourLevels]
    }
}
body GridItemBase::getContourDisplayValue { node } {
    if {$m_displayControl == ""} {
        set fieldName Spots
    } else {
        set fieldName [$m_displayControl getContourField]
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

    if {$m_displayControl == ""} {
        set fieldName Frame
    } else {
        set fieldName [$m_displayControl getNumberField]
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
body GridItemBase::itemFitPurpose { \
    purpose shape forLCLS {allowRasterForCrystal 0} \
} {
    ### also change shouldDisplay if you change here.
    if {$shape == "group"} {
        ## this should not happen though
        return 1
    }

    switch -exact -- $purpose {
        forAll -
        forLCLSAll {
        }
        forCrystal {
            if {$forLCLS} {
                return 0
            }
            switch -exact -- $shape {
                crystal {
                }
                l614 -
                projective -
                trap_array -
                mesh {
                    return 0
                }
                default {
                    if {!$allowRasterForCrystal} {
                        return 0
                    } else {
                        return -1
                    }
                }
            }
        }
        forLCLSCrystal {
            if {!$forLCLS} {
                return 0
            }
            switch -exact -- $shape {
                crystal {
                }
                l614 -
                projective -
                trap_array -
                mesh {
                    return 0
                }
                default {
                    if {!$allowRasterForCrystal} {
                        return 0
                    } else {
                        return -1
                    }
                }
            }
        }
        forL614 {
            if {!$forLCLS} {
                return 0
            }
            switch -exact -- $shape {
                l614 -
                projective -
                trap_array -
                mesh {
                }
                default {
                    return 0
                }
            }
        }
        forPXL614 {
            if {$forLCLS} {
                return 0
            }
            switch -exact -- $shape {
                l614 -
                projective -
                trap_array -
                mesh {
                }
                default {
                    return 0
                }
            }
        }
        forLCLS {
            if {!$forLCLS} {
                return 0
            }
            switch -exact -- $shape {
                l614 -
                projective -
                trap_array -
                mesh -
                crystal {
                    return 0
                }
            }
        }
        forGrid {
            if {$forLCLS} {
                return 0
            }
            switch -exact -- $shape {
                l614 -
                projective -
                trap_array -
                mesh -
                crystal {
                    return 0
                }
            }
        }
        default {
            switch -exact -- $shape {
                l614 -
                projective -
                trap_array -
                mesh -
                crystal {
                    return 0
                }
            }
        }
    }
    return 1
}
body GridItemBase::shouldDisplay { } {
    ### filter for purpose too
    ### change here may need to modify itemFitPurpose too
    set purpose [$m_holder cget -purpose]
    set shape [getShape]
    set forLCLS [getForLCLS]
    set showRaster [$m_holder cget -showRasterToo]

    if {$shape == "group"} {
        return 1
    }
    set fit [itemFitPurpose $purpose $shape $forLCLS $showRaster]
    if {$fit == 0} {
        return 0
    }
    if {$fit == -1} {
        set m_status silent
    }

    set style [$m_holder cget -showItem]
    #puts "shouldDisplay style=$style"
    switch -exact -- $style {
        selected_only {
            if {$m_status != "selected"} {
                return 0
            }
            return 1
        }
        all {
            #puts "shouldDisplay for all hide=$m_hide for $this"
            if {$m_hide} {
                return 0
            }
            return 1
        }
        phi_match -
        default {
            if {$m_hide} {
                return 0
            }
            ## continue below to check phi
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
body GridItemBase::shouldShowDetail { } {
    set shape [getShape]
    set forLCLS [getForLCLS]

    if {$shape == "group" || $shape == "crystal"} {
        return 1
    }

    ### check phi
    set displayOrig [$m_holder getDisplayOrig]

    set itemAngle    [lindex $m_oOrig 3]
    set displayAngle [lindex $displayOrig 3]

    set diff [expr $itemAngle - $displayAngle]
    while {$diff <= -180} {
        set diff [expr $diff + 360.0]
    }
    while {$diff > 180} {
        set diff [expr $diff - 360.0]
    }

    if {abs($diff) <= 45.0} {
        return [list 1 $diff]
    }

    return [list 0 $diff]
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
    puts "enter rectangle instantiate"
    
    set item [GridItemRectangle ::#auto $c {} adjustable $h]
    puts "create item $item"
    $item reborn $gridId $info

    puts "after reborn"
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
    set m_allGuiIdList $m_guiId

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

    set m_allGuiIdList $m_guiId

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

    set m_allGuiIdList $m_guiId

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

    ###override, we want the grid box follows the line.
    protected method generateGridMatrix { }
    protected method redrawGridMatrix { }
    protected method rebornGridMatrix { } {
        contourSetup
        redrawGridMatrix
    }

    constructor { canvas id mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        #puts "line constructo"
        setSequenceType horz
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

    set m_allGuiIdList $m_guiId

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
body GridItemLine::generateGridMatrix { } {
    if {$m_guiId == ""} {
        return
    }
    #puts "generateGridMatrix for $this"
    set m_nodeList ""
    $m_canvas delete grid_$m_guiId

    if {$m_cellWidth == 0 || $m_cellHeight == 0} {
        puts "cell size = 0"
        return
    }
    set ll [llength $m_localCoords]
    if {$ll < 4} {
        puts "line reborn bad coords: $m_localCoords orig: $m_oLocalCoords"
        return
    }

    foreach {x1 y1 x2 y2} $m_localCoords break
    puts "line point $x1 $y1 $x2 $y2"
    set newLocal [list $x1 $y1 $x2 $y2]
    set bx1 [expr $m_centerX + $x1]
    set by1 [expr $m_centerY + $y1]
    set bx2 [expr $m_centerX + $x2]
    set by2 [expr $m_centerY + $y2]
    puts "line point $bx1 $by1 $bx2 $by2"

    set m_gridCenterX [expr ($bx2 + $bx1) / 2.0]
    set m_gridCenterY [expr ($by2 + $by1) / 2.0]

    #puts "geo center: $m_centerX $m_centerY"
    #puts "grid center: $m_gridCenterX $m_gridCenterY"

    set m_itemWidth   [expr abs($bx2 - $bx1) * 1.0]
    set m_itemHeight  [expr abs($by2 - $by1) * 1.0]
    if {$m_itemWidth <= 0 && $m_itemHeight <= 0} {
        puts "raster not ready, box size=0"
        return
    }
    if {![saveItemSize]} {
        return
    }

    puts "cell size: $m_cellWidth X $m_cellHeight"
    puts "item size $m_itemWidth X $m_itemHeight"
    puts "item size ooo: $m_oItemWidth X $m_oItemHeight"
    #puts "box $box"

    set numColX [expr int(ceil(abs($m_itemWidth  / $m_cellWidth)))]
    set numColY [expr int(ceil(abs($m_itemHeight / $m_cellHeight)))]
    puts "numCol X=$numColX Y=$numColY"

    if {$numColY > $numColX} {
        set m_numCol $numColY
        set gridSize [expr abs($m_cellHeight * $numColY)]
        set line_k   [expr double($bx2 - $bx1) / ($by2 - $by1)]
        set line_a   [expr $bx2 - $line_k * $by2]
        puts "line k=$line_k a=$line_a"
        
        if {$by1 <= $by2} {
            set stepY [expr abs($m_cellHeight)]
            set y0    [expr $m_gridCenterY - $gridSize / 2.0 + $stepY / 2.0]
        } else {
            set stepY [expr -1 * abs($m_cellHeight)]
            set y0    [expr $m_gridCenterY + $gridSize / 2.0 + $stepY / 2.0]
        }
        set stepX [expr $stepY * $line_k]
        set x0    [expr $line_k * $y0 + $line_a]
    } else {
        set m_numCol $numColX
        set gridSize [expr abs($m_cellWidth * $numColX)]
        set line_k   [expr double($by2 - $by1) / ($bx2 - $bx1)]
        set line_a   [expr $by2 - $line_k * $bx2]
        puts "line k=$line_k a=$line_a"

        if {$bx1 <= $bx2} {
            set stepX [expr abs($m_cellWidth)]
            set x0    [expr $m_gridCenterX - $gridSize / 2.0 + $stepX / 2.0]
        } else {
            set stepX [expr -1 * abs($m_cellWidth)]
            set x0    [expr $m_gridCenterX + $gridSize / 2.0 + $stepX / 2.0]
        }
        set stepY [expr $stepX * $line_k]
        set y0    [expr $line_k * $x0 + $line_a]
    }
    puts "zero at: $x0 $y0 step: $stepX $stepY"

    set m_numRow 1

    if {$m_numCol < 1} {
        set m_numCol 1
    }
    contourSetup

    set m_nodeList [string repeat "S " $m_numCol]

    set halfCW [expr abs($m_cellWidth / 2.0)]
    set halfCH [expr abs($m_cellHeight / 2.0)]
    for {set i 0} {$i < $m_numCol} {incr i} {
        puts "calculate center xy"
        set x [expr $x0 + $stepX * $i]
        set y [expr $y0 + $stepY * $i]
        puts "append to local coords"
        lappend newLocal [expr $x -$m_centerX] [expr $y - $m_centerY]

        puts "cell coords"
        set cx1 [expr $x - $halfCW]
        set cy1 [expr $y - $halfCH]
        set cx2 [expr $x + $halfCW]
        set cy2 [expr $y + $halfCH]

        $m_canvas create polygon $cx1 $cy1 $cx2 $cy1 $cx2 $cy2 $cx1 $cy2 \
        -outline $GridGroupColor::COLOR_GRID \
        -fill "" \
        -tags [list grid grid_$m_guiId item_$m_guiId]
    }
    set m_localCoords $newLocal
    saveItemInfo
    #puts "grid relative center: $m_uGridCenterX $m_uGridCenterY"

    $m_canvas raise $m_guiId
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info
    $m_canvas raise hotspot_$m_guiId
}
body GridItemLine::redrawGridMatrix { } {
    if {$m_guiId == ""} {
        return
    }
    if {![shouldDisplay]} {
        removeAllGui
        return
    }
    set nodeColorList [getContourDisplayList]
    $m_obj setValues $nodeColorList

    set nodeLabelList [getNumberDisplayList]
    set font_sizeW [expr int(abs(0.33 * $m_cellWidth))]
    set font_sizeH [expr int(abs(0.33 * $m_cellHeight))]
    set font_size [expr ($font_sizeW > $font_sizeH)?$font_sizeH:$font_sizeW]
    if {$font_size > 16} {
        set font_size 16
    }

    set noFill 0
    if {[string first only [getContourLevels]] >= 0} {
        set noFill 1
    }
    
    $m_canvas delete grid_$m_guiId
    set gridXYList [lrange $m_localCoords 4 end]
    set halfCW [expr abs($m_cellWidth / 2.0)]
    set halfCH [expr abs($m_cellHeight / 2.0)]
    set index -1
    foreach {lx ly} $gridXYList {
        incr index

        set x [expr $lx + $m_centerX]
        set y [expr $ly + $m_centerY]

        set x1 [expr $x - $halfCW]
        set y1 [expr $y - $halfCH]
        set x2 [expr $x + $halfCW]
        set y2 [expr $y + $halfCH]

        set nodeStatus [lindex $nodeColorList $index]
        set nodeLabel  [lindex $nodeLabelList $index]
        set color [$m_obj getColor 0 $index]
        if {$color >= 0} {
            set fill [format "\#%02x%02x%02x" $color $color $color]
            set stipple ""
        } else {
            set nodeAttrs [nodeStatus2Attributes $nodeStatus]
            if {$nodeAttrs == ""} {
                puts "for line, should not be here nodeStatus=$nodeStatus"
                continue
            }
            foreach {fill stipple} $nodeAttrs break
        }
        if {$noFill} {
            set fill ""
            set stipple ""
        }

        set hid [$m_canvas create polygon $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 \
        -outline $GridGroupColor::COLOR_GRID \
        -fill $fill \
        -stipple $stipple \
        -tags \
        [list grid grid_$m_guiId item_$m_guiId node_${m_guiId}_${index}] \
        ]
        $m_canvas bind $hid <Button-1> "$this gridPress 0 $index %x %y"

        set tx [expr ($x1 + $x2) / 2.0]
        set ty [expr ($y1 + $y2) / 2.0]
        set hid [$m_canvas create text $tx $ty \
        -text $nodeLabel \
        -font "-family courier -size $font_size" \
        -fill $GridGroupColor::COLOR_VALUE \
        -anchor c \
        -justify center \
        -tags \
        [list grid grid_$m_guiId \
        item_$m_guiId nodeLabel_${m_guiId}_${index}] \
        ]
        $m_canvas bind $hid <Button-1> "$this gridPress 0 $index %x %y"
    }

    $m_canvas delete contour_$m_guiId

    $m_canvas raise $m_guiId
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    ### group should be highest
    $m_canvas raise group
    $m_canvas raise beam_info
    $m_canvas raise hotspot_$m_guiId
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

    private method updateStartPoint { } {
        if {[llength $m_positionList] == 0} {
            return
        }
        set start [lindex $m_positionList 0]
        foreach {x y} [samplePositionToXy $start] break
        set m_startX $x
        set m_startY $y

        set x1 [expr $x - $END_DISTANCE]
        set y1 [expr $y - $END_DISTANCE]
        set x2 [expr $x + $END_DISTANCE]
        set y2 [expr $y + $END_DISTANCE]
        $m_canvas coords polygon_start_point $x1 $y1 $x2 $y2

        set end [lindex $m_positionList end]
        foreach {x y} [samplePositionToXy $end] break
        set m_pressX $x
        set m_pressY $y
    }

    public method setStartPoint { x y } {
        set startP [xyToSamplePosition $x $y]
        ### sim coords, first 2 points are the same.
        set m_positionList [list $startP $startP]

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

    ### only used during creation on GUI
    private variable m_positionList ""

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
    -tags [list rubberband polygon_start_point]

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
        lappend m_positionList [xyToSamplePosition $x $y]
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

    set m_allGuiIdList $m_guiId
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

    set m_allGuiIdList $m_guiId
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
    } elseif {$m_mode == "template"} {
        set drawCoords [list]
        foreach pos $m_positionList {
            foreach {x y} [samplePositionToXy $pos] break
            lappend drawCoords $x $y
        }
        $m_canvas coords $m_guiId $drawCoords
        updateStartPoint
        return
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

    public method manualScale { w h } {
        log_error Sizing not supported by L614 Grid 

        ## no need to update
        return 0
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
        set m_point0 [xyToSamplePosition $x $y]
        set m_numPointDefined 1
        $m_holder registerImageMotionCallback "$this imageMotion"
        drawPotentialPosition $m_point0
    }

    ### need to override these
    public method getItemInfo { } {
        set result [GridItemBase::getItemInfo]
        #[list $orig $geoList $gridList $m_nodeList $m_extraUserParameters]
        set gridList [lindex $result 2]
        dict set gridList num_column_picked $m_numColPicked
        dict set gridList num_row_picked    $m_numRowPicked
        dict set gridList cell_width        $DISTANCE_HOLE_HORZ
        dict set gridList cell_height       $DISTANCE_HOLE_VERT
        set result [lreplace $result 2 2 $gridList]

        return $result
    }
    public method updateFromInfo { info {redraw 1}} {
        foreach {orig geo grid node frame status hide parameter} $info break
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

    private method updateBorder { }

    private method checkPositionRelation { } {
        set currentOrig [$m_holder getDisplayOrig]

        foreach {x0 y0 z0} $m_point0 break
        foreach {x1 y1 z1} $m_point1 break
        foreach {x2 y2 z2} $m_point2 break
        foreach {x3 y3 z3} $m_point3 break

        foreach {uy0 ux0} \
        [calculateProjectionFromSamplePosition $currentOrig $x0 $y0 $z0 1] break

        foreach {uy1 ux1} \
        [calculateProjectionFromSamplePosition $currentOrig $x1 $y1 $z1 1] break

        foreach {uy2 ux2} \
        [calculateProjectionFromSamplePosition $currentOrig $x2 $y2 $z2 1] break

        foreach {uy3 ux3} \
        [calculateProjectionFromSamplePosition $currentOrig $x3 $y3 $z3 1] break

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
    #### NodeListView needs hole radius to create sub-raster
    public  common HOLE_RADIUS_LIST [list 200.0 62.5 200.0 100.0 200.0]
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
        setSequenceType zigzag
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

    $h setNotice "Click B15\n "

    return $item
}
body GridItemL614::imageMotion { x y } {
    switch -exact -- $m_numPointDefined {
        2 {
            foreach {x0 y0} [samplePositionToXy $m_point0] break
            $m_canvas coords $m_guiId $x0 $y0 $x $y
        }
        3 {
            foreach {x1 y1} [samplePositionToXy $m_point1] break
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

    set m_point$m_numPointDefined [xyToSamplePosition $x $y]
    incr m_numPointDefined
    switch -exact -- $m_numPointDefined {
        1 {
            ## should not be here
            return
        }
        2 {
            foreach {w h} [$m_holder getDisplayPixelSize] break
            foreach {x1 y1} [samplePositionToXy $m_point1] break
            set m_idExtra [$m_canvas create line \
            0 $y1 $w $y1 \
            -width 1 \
            -fill $GridGroupColor::COLOR_RUBBERBAND \
            -dash . \
            -tags rubberband \
            ]
            $m_holder setNotice "1. Click >> to move and center between D1 and B1.\n2. Click D1"
            return
        }
        3 {
            $m_canvas itemconfig $m_guiId \
            -width 2 \
            -fill red \
            -dash "" \
            -tags [list raster item_$m_guiId]

            $m_holder setNotice "Click B1\n "
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

    foreach {x0 y0} [samplePositionToXy $m_point0] break
    foreach {x1 y1} [samplePositionToXy $m_point1] break
    foreach {x2 y2} [samplePositionToXy $m_point2] break
    foreach {x3 y3} [samplePositionToXy $m_point3] break

    ### to allow 0 1 2 3 or 0 1 3 2 in click
    set ddy0 [expr $y1 - $y0]
    set ddy2 [expr $y3 - $y2]
    if {$ddy0 * $ddy2 >= 0} {
        set m_hotSpotCoords [list $x0 $y0 $x2 $y2 $x3 $y3 $x1 $y1]
    } else {
        set m_hotSpotCoords [list $x0 $y0 $x3 $y3 $x2 $y2 $x1 $y1]
    }
    set coords $m_hotSpotCoords
    #puts "create coords: $coords"

    set m_guiId [$m_canvas create polygon $coords \
    -width 1 \
    -outline $GridGroupColor::COLOR_SHAPE_CURRENT \
    -fill "" \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    set m_allGuiIdList $m_guiId

    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize

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

    set m_allGuiIdList $m_guiId

    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize

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
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                set coords [$m_canvas coords $m_guiId]
                foreach {- - x y} $coords break
                $m_canvas coords $m_guiId $x0 $y0 $x $y
            }
            2 {
                drawPotentialPosition $m_point0
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                foreach {x1 y1} [samplePositionToXy $m_point1] break
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
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                foreach {x1 y1} [samplePositionToXy $m_point1] break
                $m_canvas coords $m_guiId $x0 $y0 $x1 $y1
                $m_canvas itemconfig $m_guiId \
                -width 2 \
                -fill red \
                -dash "" \
                -tags [list raster item_$m_guiId]

                ### do "3" own
                foreach {x2 y2} [samplePositionToXy $m_point2] break
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
    foreach {px py} [samplePositionToXy $p] break

    $m_canvas delete ruler_$m_guiId

    foreach {dx100 dy100 hole_horz hole_vert} \
    [$m_holder micron2pixel 100 100 \
    $DISTANCE_HOLE_HORZ $DISTANCE_HOLE_VERT] break

    ###horz ruler
    set y [expr $py - $dy100]
    for {set i 0} {$i < $NUM_HOLE_HORZ} {incr i} {
        set x [expr $px - $i * $hole_horz]
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
        set x [expr $px + $i * $hole_horz]
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
    set x [expr $px + $dx100]
    set y0 [expr $py - 2 * $hole_vert]
    for {set i 0} {$i < 3} {incr i} {
        set y [expr $y0 + $i * 2 * $hole_vert]
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
    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize
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
        # remove 2 not-exists holes B16 E16
        set m_nodeList [lreplace $m_nodeList 31 31 --]
        set m_nodeList [lreplace $m_nodeList 63 63 --]
    }
    contourSetup

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
    $m_canvas raise hotspot_$m_guiId
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
    #  B1:  (1.76, 0)
    #  D5:  (0.98, 4)
    #  B5:  (1.76, 4)
    #
    # case 2: from right
    #  D15  (0.98, 14)
    #  B15  (1.76, 14)
    #  D11  (0.98, 10)
    #  B11  (1.76, 10)

    ### check it is case 1 or case 2
    foreach {x0 y0 x1 y1 x3 y3 x2 y2} $m_localCoords break
    foreach {ux0 uy0 ux1 uy1} [$m_holder pixel2micron $x0 $y0 $x1 $y1] break

    puts "tipping check 0=($ux0, $uy0) 1=($ux1, $uy1)"
    if {$ux0 < $ux1} {
        ### from tip to base
        set firstColIndex [expr $NUM_HOLE_HORZ - 2]
        set sign -1
    } else {
        ### from base to tip
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
    if {$m_displayControl == ""} {
        set fieldName Frame
    } else {
        set fieldName [$m_displayControl getNumberField]
    }

    set nodeColorList [getContourDisplayList]

    if {$nodeColorList == [generateEmptyDisplayList]} {
        $m_obj setValues ""
    } else {
        $m_obj setValues $nodeColorList
    }

    set nodeLabelList [getNumberDisplayList]
    set font_sizeW [expr int(abs(0.4 * $m_cellWidth))]
    set font_sizeH [expr int(abs(0.4 * $m_cellHeight))]
    set font_size [expr ($font_sizeW > $font_sizeH)?$font_sizeH:$font_sizeW]
    if {$font_size > 16} {
        set font_size 16
    }

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
                set c_row [expr $index / $m_numCol]
                set c_col [expr $index % $m_numCol]
                set color      [$m_obj getColor $c_row $c_col]
                if {$color >= 0} {
                    set fill [format "\#%02x%02x%02x" $color $color $color]
                 }
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

        #puts "draw label index=$index label=$holeLabel"

        if {$fieldName != "Frame"} {
            continue
        }

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
    $m_canvas raise hotspot_$m_guiId
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

    set noFill 0
    if {[string first only [getContourLevels]] >= 0} {
        set noFill 1
    }
    
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
            set c_row [expr $index / $m_numCol]
            set c_col [expr $index % $m_numCol]
            set color      [$m_obj getColor $c_row $c_col]
            if {$color >= 0} {
                set fill [format "\#%02x%02x%02x" $color $color $color]
             }
        }
    }
    if {$noFill} {
        set fill ""
    }
    $m_canvas itemconfigure $nodeTag \
    -outline $outline \
    -fill $fill
}


class GridItemGroup {
    inherit GridItemBase

    proc create { c x y h }

    public method getShape { } {
        return "group"
    }

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

    public method mergeCrystals { }

    public method rotate { angle {radians 0} } {
        if {$radians} {
            set dav $angle
        } else {
            set dav [expr $angle * 3.1415926 / 180.0]
        }

        set a0 $m_oAngle
        set av0 [angleFrameToVideo $a0]
        set av1 [expr $av0 + $dav]

        rotateFromVideo $av0 $av1 1
    }
    public method rotateFromVideo { start end {radians 0} } {
        foreach item $m_member {
            $item groupRotate $m_centerX $m_centerY $start $end $radians
        }
        GridItemBase::rotateFromVideo $start $end $radians
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
        set m_itemId group$m_itemId
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
    set tkItemList ""
    foreach item $m_member {
        $item onJoinGroup $this
        eval lappend tkItemList [$item getTKItems]
    }
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

    saveItemInfo

    #setItemStatus selected
    $m_holder setCurrentItem $this

    $m_canvas raise beam_info
    $m_canvas raise hotspot_$m_guiId
}
## not the same as Base
body GridItemGroup::bodyPress { xw yw } {
    set m_motionCalled 0
    #puts "group bodyPRess for $this"
    if {[noResponse]} {
        #puts "calling group bodyPress no response"
        $m_holder registerButtonCallback "" ""
        return
    }
    set x [$m_canvas canvasx $xw]
    set y [$m_canvas canvasy $yw]
    set m_pressX $x
    set m_pressY $y
    set m_initPressX $x
    set m_initPressY $y

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
    $m_canvas raise hotspot_$m_guiId
}
body GridItemGroup::mergeCrystals { } {
    set ll [llength $m_member]
    if {$ll < 2} {
        return
    }

    ### checking
    set allOK 1
    foreach item $m_member {
        if {[$item getShape] != "crystal"} {
            log_error member is not crystal
            set allOK 0
        }
        if {![$item adjustableOnVideo]} {
            log_error member is not editable
            set allOK 0
        }
    }
    if {!$allOK} {
        return
    }
    set first [lindex $m_member 0]
    set others [lrange $m_member 1 end]

    $first merge $others

    $m_holder clearCurrentItem
}

##### The Crystal is different from normal GridItem:
##### Its points are saved in sample position format.
##### They are not limited on the plane of its view.
##### It can be anywhere in the space.
##### It must regenerate "grid", center, and outline by itself every time
##### when anything changes, like video view change, or vertex motion.
##### Its "grid" is one row.  Every node center is on the line.
##### For now (04/25/13), we only support horz cut.
##### 01/13/14: adding support for multiple segments.
class GridItemCrystal {
    inherit GridItemBase

    ### x y in input is more flexible than get it from sample_xyz in proc.
    proc create { c x y h }
    proc instantiate { c h gridId info } {
        puts "Crystal instantiate"
        set item [GridItemCrystal ::#auto $c {} {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }

    #### pos is sample_xyz, may be orig, including a, and other info.
    #### but only first 3 fields be used.
    proc createCrystal { c pos h }
    #### add position to current segment
    public method addPosition { pos }
    #### end current segment
    public method endSegment { pos }
    #### end crystal
    public method endCrystal { pos }

    public method manualScale { w h } {
        if {[llength $m_positionList] != 2} {
            log_error Sizing only suppported for crystals defined by 2 points.
            return 0
        }
        if {[string is double -strict $w] && $m_oItemWidth != 0} {
            set scale [expr abs($w / $m_oItemWidth)]
        } elseif {[string is double -strict $h] && $m_oItemHeight != 0} {
            set scale [expr abs($h / $m_oItemHeight)]
        } else {
            return 0
        }

        ### expand or shrink along the 3D line.
        foreach {p0 p1} $m_positionList break
        foreach {x0 y0 z0} $p0 break
        foreach {x1 y1 z1} $p1 break


        set xc [expr ($x0 + $x1) / 2.0]
        set yc [expr ($y0 + $y1) / 2.0]
        set zc [expr ($z0 + $z1) / 2.0]

        set nx0 [expr $xc + ($x0 - $xc) * $scale]
        set ny0 [expr $yc + ($y0 - $yc) * $scale]
        set nz0 [expr $zc + ($z0 - $zc) * $scale]
        set nx1 [expr $xc + ($x1 - $xc) * $scale]
        set ny1 [expr $yc + ($y1 - $yc) * $scale]
        set nz1 [expr $zc + ($z1 - $zc) * $scale]

        puts "MANUAL_SCALE old: $x0 $y0 $z0,  $x1 $y1 $z1"
        puts "MANUAL_SCALE new: $nx0 $ny0 $nz0,  $nx1 $ny1 $nz1"

        set np0 [list $nx0 $ny0 $nz0]
        set np1 [list $nx1 $ny1 $nz1]

        set m_positionList [list $np0 $np1]
        redrawHotSpots 1
        return 1
    }

    public method getShape { } {
        return "crystal"
    }

    public method isMegaCrystal { } {
        set llSeg [llength $_segmentList]

        if {$llSeg >= 4} {
            return 1
        }
        return 0
    }

    #### merge help methods
    public method getInfo4Merge { } {
        return [list $m_positionList $m_segmentStartIdxList]
    }
    public method merge { itemList } {
        ## maybe we should add check here, though caller already checked.

        if {[llength $m_segmentStartIdxList] == 0} {
            lappend m_segmentStartIdxList 0
        }

        foreach item $itemList {
            set ll [llength $m_positionList]
            foreach {p seg} [$item getInfo4Merge] break
            if {$seg == ""} {
                lappend seg 0
            }
            eval lappend m_positionList $p
            foreach startIdx $seg {
                set newIdx [expr $startIdx + $ll]
                lappend m_segmentStartIdxList $newIdx
            }
        }
        puts "merge new seg: $m_segmentStartIdxList"
        _generateSegmentList
        #regenerateLocalCoords
        #saveItemSize
        redraw 1

        ### force redraw all
        #removeAllGui

        ## now regenerate
        #$m_holder onItemChange $this
        $m_holder mergeItems $this $itemList
    }

    ### for create
    public method createPress { x y }

    ## special
    public method redraw { fromGUI }
    public method reborn { gridId info }
    protected method _draw { }
    protected method _generateSegmentList { }

    ### selected
    public method vertexMotion { x y }

    ### need to do something to enable drag and drop.
    public method bodyRelease { x y } {
        if {$m_motionCalled} {
            set dx [expr $x - $m_initPressX]
            set dy [expr $y - $m_initPressY]
            dragMove $dx $dy
        }
        ::GridItemBase::bodyRelease $x $y
    }
    public method gridRelease { x y } {
        if {$m_motionCalled} {
            set dx [expr $x - $m_initPressX]
            set dy [expr $y - $m_initPressY]
            dragMove $dx $dy
        }
        ::GridItemBase::gridRelease $x $y
    }
    public method groupMove { dx dy } {
        dragMove $dx $dy
        ::GridItemBase::groupMove $dx $dy
    }

    public method setStartPosition { x y pos } {
        set m_positionList ""
        set m_xyList ""
        lappend m_positionList $pos
        lappend m_xyList $x $y
    }

    public method setStartPoint { x y } {
        set m_pressX $x
        set m_pressY $y

        set pos [xyToSamplePosition $x $y]
        setStartPosition $x $y $pos
    }
    public method setEndPoint { x y } {
        set m_endX $x
        set m_endY $y
        set m_pressX $x
        set m_pressY $y

        set x1 [expr $x - $END_DISTANCE]
        set y1 [expr $y - $END_DISTANCE]
        set x2 [expr $x + $END_DISTANCE]
        set y2 [expr $y + $END_DISTANCE]
        $m_canvas coords crystal_end_point $x1 $y1 $x2 $y2
    }

    ### need to override these
    public method getItemInfo { } {
        set result [GridItemBase::getItemInfo]
        set geo [lindex $result 1]
        set grid [lindex $result 2]
        set parameter [lindex $result 4]
        dict set geo  position_list $m_positionList
        dict set geo  segment_index_list  $m_segmentStartIdxList
        dict set grid node_segment_index_list $m_nodeSegmentIdxList
        dict set grid node_position_list $m_nodePositionList
        dict set grid node_list_for_phi  $m_nodeList4XFELPhi
        dict set parameter strategy_info $m_d_strategyInfo
        dict set parameter strategy_enable $m_enableStrategy
        dict set parameter phi_osc_middle      $m_collectPhiOscAtMiddle
        dict set parameter phi_osc_end         $m_collectPhiOscAtEnd
        dict set parameter phi_osc_all         $m_collectPhiOscAtAll

        set result [lreplace $result 1 2 $geo $grid]
        set result [lreplace $result 4 4 $parameter]
        return $result
    }

    protected method updateFromParameter { parameter {must_have 1} } {
        if {$parameter == ""} return

        set mustHaveList [list \
        delta \
        start_angle start_frame end_frame \
        collimator beam_width beam_height]

        if {$must_have} {
            set numError 0
            foreach name $mustHaveList {
                if {![dict exists $parameter $name]} {
                    log_error no $name in parameter
                    incr numError
                }
            }
            if {$numError > 0} {
                puts "parameter=$parameter"
                return
            }
        }
        if {[dict exists $parameter start_angle]} {
            set m_startAngle [dict get $parameter start_angle]
        }
        if {[dict exists $parameter delta]} {
            set m_delta [dict get $parameter delta]
        }
        if {[dict exists $parameter start_frame] \
        &&  [dict exists $parameter end_frame]} {
            set nStart     [dict get $parameter start_frame]
            set nEnd       [dict get $parameter end_frame]
            set m_numFrame [expr $nEnd - $nStart + 1]
        }

        if {[dict exists $parameter node_angle]} {
            set m_nodeAngle [dict get $parameter node_angle]
        }

        if {[dict exists $parameter collimator] \
        &&  [dict exists $parameter beam_width] \
        &&  [dict exists $parameter beam_height]} {
            set collimator   [dict get $parameter collimator]
            set use 0
            set index -1
            set bw 2.0
            set bh 2.0
            foreach {use index bw bh} $collimator break
            if {$use == "1"} {
                set m_beamWidth  [expr 1000.0 * $bw]
                set m_beamHeight [expr 1000.0 * $bh]
            } else {
                puts "beam size"
                set m_beamWidth  [dict get $parameter beam_width]
                set m_beamHeight [dict get $parameter beam_height]
            }
        }
        if {[dict exists $parameter strategy_info]} {
            set m_d_strategyInfo [dict get $parameter strategy_info]
        } else {
            set m_d_strategyInfo [dict create]
        }

        if {[dict exists $parameter strategy_enable]} {
            set m_enableStrategy [dict get $parameter strategy_enable]
        } else {
            set m_enableStrategy 0
        }
        if {!$m_forLCLS} {
            set m_enableStrategy 0
        }
        if {[dict exists $parameter phi_osc_middle]} {
            set m_collectPhiOscAtMiddle [dict get $parameter phi_osc_middle]
        } else {
            set m_collectPhiOscAtMiddle 0
        }
        if {[dict exists $parameter phi_osc_end]} {
            set m_collectPhiOscAtEnd [dict get $parameter phi_osc_end]
        } else {
            set m_collectPhiOscAtEnd 0
        }
        if {[dict exists $parameter phi_osc_all]} {
            set m_collectPhiOscAtAll [dict get $parameter phi_osc_all]
        } else {
            set m_collectPhiOscAtAll 0
        }
    }
    public method updateFromInfo { info {redraw 1} } {
        puts "Crystal updateFromInfo"
        set parameter ""
        set ll [llength $info]
        puts "ll=$ll"
        foreach {orig geo grid node frame status hide parameter} $info break

        set m_positionList [dict get $geo position_list]
        if {[dict exists $geo segment_index_list]} {
            set m_segmentStartIdxList  [dict get $geo segment_index_list]
        } else {
            set m_segmentStartIdxList ""
        }
        _generateSegmentList

        set m_nodePositionList [dict get $grid node_position_list]
        if {![dict exists $grid node_segment_index_list]} {
            set m_nodeSegmentIdxList ""
        } else {
            set m_nodeSegmentIdxList [dict get $grid node_segment_index_list]
        }

        set m_nodeList4XFELPhi ""
        if {[dict exists $grid node_list_for_phi]} {
            set m_nodeList4XFELPhi [dict get $grid node_list_for_phi]
        }

        updateFromParameter $parameter

        puts "calling base updateFromInfo"
        GridItemBase::updateFromInfo $info 0
        if {$redraw} {
            puts "call redraw 0"
            redraw 0
        }
        puts "done Crystal updateFromInfo"
    }

    private method regenerateLocalCoords { }

    ### For 2 points, we want the orig at the center of them and
    ### both of them on the orig plane.
    ### For 3 points and more, we will just use first and last points to
    ### do the same setup as for 2 points.
    ### affected by parameters: start_angle, beam_width, delta,
    ### start_frame, end_frame
    private method regenerateOrig { }
    private method findPositionAlongLine { startIdx endIdx z direction }

    protected method generateGridMatrix { }
    protected method redrawGridMatrix { }
    protected method rebornGridMatrix { } {
        contourSetup
        redrawGridMatrix
    }
    protected method getClickInfo { x y {row ""} {column ""} }

    ### enable drag to move
    protected method dragMove { dx dy }

    ##these only used during creation
    private variable m_endX 0
    private variable m_endY 0
    private variable m_idExtra ""

    private variable m_positionList ""
    private variable m_xyList ""
    private variable m_segmentStartIdxList ""

    ### generated from m_segmentStartIdxList
    private variable _segmentList [list 0 end]

    private variable m_nodePositionList ""

    ### split needs these
    private variable m_nodeSegmentIdxList ""

    ### for phi-ocsilation 
    private variable m_nodeList4XFELPhi ""

    #### exposure setup
    private variable m_objOmega   ::device::gonio_omega
    private variable m_startAngle 0.0
    private variable m_delta  1.0
    private variable m_numFrame  180
    private variable m_beamWidth  10.0
    private variable m_beamHeight 10.0

    ### for lcls crystal
    private variable m_nodeAngle 1.0
    private variable m_d_strategyInfo [dict create]

    ### for lcls crystal and maybe for ssrl crystal too
    private variable m_enableStrategy 0
    private variable m_collectPhiOscAtMiddle 0
    private variable m_collectPhiOscAtEnd 0
    private variable m_collectPhiOscAtAll 0

    private common END_DISTANCE 5

    constructor { canvas id id2 mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        set m_idExtra $id2

        set m_manualTranslate 1
        set m_showOutline 0
        set m_showRotor 0
        set m_gridOnTopOfBody 1
        setSequenceType horz
    }
}
body GridItemCrystal::create { c x y h } {
    #puts "enter create c=$c"
    set id [$c create line \
    $x $y $x $y \
    -width 1 \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -dash . \
    -tags rubberband \
    ]

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
    -tags [list rubberband crystal_end_point]

    set item [GridItemCrystal ::#auto $c $id $id2 template $h]
    #puts "new item=$item"
    $item setStartPoint $x $y

    ##### Crystal needs parameter to generate correct matrix.

    set pp [$h cget -purpose]

    $item updateFromParameter [gCurrentGridGroup getDefaultUserSetup $pp]

    $h setNotice "3D center end position before click it"

    return $item
}
body GridItemCrystal::createCrystal { c pos h } {
    ## no instant yet, so we have to calculate directly.
    #foreach {x y} [samplePositionToXy $pos] break
    set displayOrig [$h getDisplayOrig]
    foreach {uX uY} \
    [calculateSamplePositionOnVideo $displayOrig $pos 1] break

    foreach {x y} [$h micron2pixel $uX $uY] break

    set id [$c create line \
    $x $y $x $y \
    -width 1 \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -dash . \
    -tags rubberband \
    ]

    set id2 [$c create line \
    $x $y $x $y \
    -width 1 \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -dash . \
    -tags rubberband \
    ]

    set item [GridItemCrystal ::#auto $c $id $id2 template $h]
    $item setStartPosition $x $y $pos

    ##### Crystal needs parameter to generate correct matrix.
    set pp [$h cget -purpose]
    $item updateFromParameter [gCurrentGridGroup getDefaultUserSetup $pp]

    return $item
}
body GridItemCrystal::addPosition { pos } {
    foreach {x y} [samplePositionToXy $pos] break

    lappend m_positionList $pos
    lappend m_xyList $x $y

    redraw 1
}
body GridItemCrystal::endSegment { pos } {
    addPosition $pos

    set ll [llength $m_positionList]
    if {[llength $m_segmentStartIdxList] == 0} {
        lappend m_segmentStartIdxList 0
    }
    lappend m_segmentStartIdxList $ll
    _generateSegmentList

    redraw 1
}
body GridItemCrystal::endCrystal { pos } {
    addPosition $pos

    set m_mode adjustable
    redraw 1

    $m_holder addItem $this
}
body GridItemCrystal::regenerateLocalCoords { } {
    foreach {x1 y1 x2 y2} [eval $m_canvas bbox $m_allGuiIdList] break
    set m_centerX [expr ($x1 + $x2) / 2.0]
    set m_centerY [expr ($y1 + $y2) / 2.0]
    set m_gridCenterX $m_centerX
    set m_gridCenterY $m_centerY
    set m_oAngle 0
    updateCornerAndRotor
}

body GridItemCrystal::createPress { x y } {
    #puts "polygon create press $x $y"
    set dx [expr $x - $m_endX]
    set dy [expr $y - $m_endY]
    set d2 [expr $dx * $dx + $dy * $dy]
    set threshold [expr $END_DISTANCE * $END_DISTANCE]
    if {$d2 > $threshold} {
        $m_canvas insert $m_guiId end [list $x $y]
        setEndPoint $x $y

        lappend m_xyList $x $y
        lappend m_positionList [xyToSamplePosition $x $y]

        $m_holder setNotice "click the red last position to end"

        return
    }

    ##### end of creation
    $m_holder setNotice ""
    set m_mode adjustable
    removeAllGui
    $m_canvas delete rubberband
    set m_guiId [$m_canvas create line $m_xyList \
    -width 3 \
    -fill $GridGroupColor::COLOR_SHAPE_CURRENT \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    set m_allGuiIdList $m_guiId

    generateGridMatrix
    regenerateLocalCoords

    ### if not enable this, please remove tag "item_XXX" from the nodes.
    ### because the node has its own click callbacks.
    #$m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind $m_guiId <Button-1> "$this bodyPress %x %y"

    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    $m_holder addItem $this
}
body GridItemCrystal::_generateSegmentList { } {
    puts "_generateSegmentList for $this"
    set ll [llength $m_segmentStartIdxList]
    if {$ll < 2} {
        set _segmentList [list 0 end]
        puts "_generateSegmentList no segment, return 0 end"
        return
    }
    set _segmentList 0
    for {set i 1} {$i < $ll} {incr i} {
        set nextStart [lindex $m_segmentStartIdxList $i]
        set currentEnd [expr $nextStart - 1]
        lappend _segmentList $currentEnd $nextStart
    }
    lappend _segmentList end
    puts "segmentList $_segmentList"
}
body GridItemCrystal::_draw { } {
    puts "Crystal _draw"
    set m_xyList ""
    foreach pos $m_positionList {
        foreach {x y} [samplePositionToXy $pos] break
        lappend m_xyList $x $y

        ### used as last position
        set m_pressX $x
        set m_pressY $y
    }
    #puts "xy list=$m_xyList"

    foreach guiId $m_allGuiIdList {
        $m_canvas delete $guiId
    }
    set m_allGuiIdList ""
    foreach {segStart segEnd} $_segmentList {
        #puts "segment: $segStart $segEnd"
        set idxStart [expr $segStart * 2]
        if {$segEnd == "end"} {
            set idxEnd end
        } else {
            set idxEnd   [expr $segEnd  * 2 + 1]
        }
        #puts "idx: $idxStart $idxEnd"
        set xySegList [lrange $m_xyList $idxStart $idxEnd]
        #puts "xySegList: $xySegList"
        if {[llength $xySegList] == 2} {
            set xySegList [eval lappend xySegList $xySegList]
        }

        set guiId [$m_canvas create line $xySegList \
        -width 3 \
        -fill $GridGroupColor::COLOR_SHAPE \
        -tags raster \
        ]
        lappend m_allGuiIdList $guiId
    }
    set m_guiId [lindex $m_allGuiIdList 0]

    foreach guiId $m_allGuiIdList {
        $m_canvas addtag item_$m_guiId withtag $guiId
        $m_canvas bind $guiId <Button-1> "$this bodyPress %x %y"
    }

    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    puts "done"
}
body GridItemCrystal::reborn { gridId info } {
    puts "Crystal reborn, calling base"

    GridItemBase::reborn $gridId $info

    puts "calling _draw"
    if {[shouldDisplay]} {
        _draw
    }

    puts "calling addItem"
    $m_holder addItem $this 0
}
body GridItemCrystal::redraw { fromGUI } {
    puts "Crystal redraw"
    if {!$fromGUI && ![shouldDisplay]} {
        puts "Crystal redraw skip, not from GUI and should not display"
        removeAllGui
        return
    }

    set llSeg [llength $_segmentList]
    set llGui [llength $m_allGuiIdList]
    if {$llSeg != 2 * $llGui} {
        ### caused by merge, need redraw from scrach.
        removeAllGui
    }

    if {$m_guiId == ""} {
        _draw
    } elseif {$m_mode == "template"} {
        removeAllGui
        _draw

        set displayOrig [$m_holder getDisplayOrig]
        foreach {cx cy} [samplePositionToXy $displayOrig] break

        set lastIdx [lindex $m_segmentStartIdxList end]
        if {[string is integer -strict $lastIdx] \
        && $lastIdx > [llength $m_positionList]} {
            $m_canvas coords $m_idExtra [list $cx $cy $cx $cy]
        } else {
            $m_canvas coords $m_idExtra [list $m_pressX $m_pressY $cx $cy]
        }

        regenerateLocalCoords
        generateGridMatrix
        return
    } else {
        ### view changed, need redraw them.
        set m_xyList ""
        foreach pos $m_positionList {
            foreach {x y} [samplePositionToXy $pos] break
            lappend m_xyList $x $y

            set m_pressX $x
            set m_pressY $y
        }
        foreach {idxStart idxEnd} $_segmentList guiId $m_allGuiIdList {
            puts "redraw seg $idxStart $idxEnd"
            set idxStart [expr $idxStart * 2]
            if {$idxEnd != "end"} {
                set idxEnd   [expr $idxEnd  * 2 + 1]
            }
            set segXYList [lrange $m_xyList $idxStart $idxEnd]
            puts "xy: $segXYList"
            $m_canvas coords $guiId $segXYList
        }

        regenerateLocalCoords
    }
    redrawHotSpots $fromGUI

    set box [getBBox]
    if {[llength $box] < 4} {
        puts "raster not ready, no bbox"
        return
    }
    foreach {bx1 by1 bx2 by2} $box break

    set m_itemWidth   [expr ($bx2 - $bx1) * 1.0]
    set m_itemHeight  [expr ($by2 - $by1) * 1.0]
    saveItemSize
}
body GridItemCrystal::vertexMotion { x y } {
    set llSeg [llength $_segmentList]
    set llGui [llength $m_allGuiIdList]
    if {$llSeg != 2 * $llGui} {
        log_error software internal error: segment not match guiID
        return
    }
    foreach {segStartIdx segEndIdx} $_segmentList guiId $m_allGuiIdList {
        if {$m_indexVertex >= $segStartIdx \
        && ($segEndIdx == "end" || $m_indexVertex <= $segEndIdx)} {
            set index [expr ($m_indexVertex - $segStartIdx) * 2]
            $m_canvas dchars $guiId $index
            $m_canvas insert $guiId $index [list $x $y]
            break
        }
    }

    regenerateLocalCoords
    set idx1 [expr $m_indexVertex * 2]
    set idx2 [expr $idx1 + 1]
    set m_xyList [lreplace $m_xyList $idx1 $idx2 $x $y]

    foreach {uX uY} [$m_holder pixel2micron $x $y] break
    set displayOrig [$m_holder getDisplayOrig]

    set myPos [lindex $m_positionList $m_indexVertex]
    set newPos \
    [adjustSamplePositionFromVideoClick $displayOrig $uX $uY $myPos 1]

    set m_positionList [lreplace $m_positionList \
    $m_indexVertex $m_indexVertex $newPos]

    redrawHotSpots 1
}
body GridItemCrystal::dragMove { dx dy } {
    puts "dragMove $dx $dy"
    foreach {uDX uDY} [$m_holder pixel2micron $dx $dy] break
    set displayOrig [$m_holder getDisplayOrig]

    set oldList $m_positionList
    set m_positionList [list]
    foreach pos $oldList {
        set newPos [adjustSamplePositionFromVideoDisplacement \
        $displayOrig $uDX $uDY $pos 1]

        lappend m_positionList $newPos
    }
    generateGridMatrix
    #redrawHotSpots 1
}
### private method, no safety check
body GridItemCrystal::findPositionAlongLine { startIdx endIdx z_ dir_ } {
    set posList [lrange $m_positionList $startIdx $endIdx]    

    set posList [lsort -real -index 2 $posList]

    ###find which section to use.
    set sec -1
    foreach pos $posList {
        incr sec
        set pZ [lindex $pos 2]
        if {$dir_ > 0} {
            if {$z_ <= $pZ} {
                break
            }
        } else {
            if {$z_ >= $pZ} {
                break
            }
        }
    }
    incr sec -1
    if {$sec < 0} {
        set sec 0
    }
    set p0 [lindex $posList $sec]
    incr sec
    set p1 [lindex $posList $sec]
    foreach {x0 y0 z0} $p0 break
    foreach {x1 y1 z1} $p1 break

    set dx [expr $x1 - $x0]
    set dy [expr $y1 - $y0]
    set dz [expr $z1 - $z0]
    set scaleX [expr double($dx) / $dz]
    set scaleY [expr double($dy) / $dz]

    set dz [expr $z_ - $z0]
    set dx [expr $scaleX * $dz]
    set dy [expr $scaleY * $dz]

    set x [expr $x0 + $dx]
    set y [expr $y0 + $dy]

    return [list $x $y $z_]
}
body GridItemCrystal::regenerateOrig { } {
    if {$m_oCellWidth == 0} {
        log_error cell width ==0, skip
        return
    }
    set omega [$m_objOmega cget -scaledPosition]
    set ca [expr $omega + $m_startAngle]
    puts "startAngle=$m_startAngle, omega=$omega"

    set minStepZ [expr abs($m_oCellWidth / 1000.0)]
    set bw [expr $m_beamWidth / 1000.0]
    set m_numRow 1

    set firstP [lindex $m_positionList 0]
    foreach {x0 y0 z0} $firstP break
    set allMinX $x0
    set allMaxX $x0
    set allMinY $y0
    set allMaxY $y0
    set allMinZ $z0
    set allMaxZ $z0

    ##### node position list
    set m_nodePositionList [list]
    set m_nodeSegmentIdxList [list]

    ### only fill x, y, z.  All angle = start_angle.
    ## angle will be adjusted later.
    foreach {segStartIdx segEndIdx} $_segmentList {
        lappend m_nodeSegmentIdxList [llength $m_nodePositionList]
        set posList [lrange $m_positionList $segStartIdx $segEndIdx]
        set firstP [lindex $posList 0]
        foreach {x0 y0 z0} $firstP break
        set minX $x0
        set maxX $x0
        set minY $y0
        set maxY $y0
        set minZ $z0
        set maxZ $z0

        foreach pos $posList {
            foreach {x y z} $pos break
            if {$x < $minX} {
                set minX $x
            } elseif {$x > $maxX} {
                set maxX $x
            }
            if {$y < $minY} {
                set minY $y
            } elseif {$y > $maxY} {
                set maxY $y
            }
            if {$z < $minZ} {
                set minZ $z
            } elseif {$z > $maxZ} {
                set maxZ $z
            }
        }
        if {$minX < $allMinX} {
            set allMinX $minX
        }
        if {$maxX > $allMaxX} {
            set allMaxX $maxX
        }
        if {$minY < $allMinY} {
            set allMinY $minY
        }
        if {$maxY > $allMaxY} {
            set allMaxY $maxY
        }
        if {$minZ < $allMinZ} {
            set allMinZ $minZ
        }
        if {$maxZ > $allMaxZ} {
            set allMaxZ $maxZ
        }
        set cx [expr 0.5 * ($minX + $maxX)]
        set cy [expr 0.5 * ($minY + $maxY)]
        set cz [expr 0.5 * ($minZ + $maxZ)]
        set rx [expr $maxX - $minX]
        set ry [expr $maxY - $minY]
        set rz [expr $maxZ - $minZ]

        if {$rz - $bw < $minStepZ} {
            set nPos [list $cx $cy $cz $ca]
            lappend m_nodePositionList $nPos
            continue
        }
        set numNode [expr int(($rz - $bw) / $minStepZ) + 1]
        set stepZ [expr ($rz - $bw) / ($numNode - 1)]
        set halfSegWidth [expr 0.5 * $numNode * $stepZ]
        ### this is to decide whether already from tip
        ### or follow user click.
        #if {$cz > $z0} {
            set startZ [expr $cz - $halfSegWidth + 0.5 * $stepZ]
        #} else {
        #    set startZ [expr $cz + $halfGridWidth - 0.5 * $stepZ]
        #    set stepZ [expr -1 * $stepZ]
        #}
        for {set i 0} {$i < $numNode} {incr i} {
            set nZ [expr $startZ + $i * $stepZ]
            ## here only needs sign of stepZ as direction.
            set nPos [findPositionAlongLine $segStartIdx $segEndIdx $nZ $stepZ]
            lappend nPos $ca
            lappend m_nodePositionList $nPos
        }
    }
    set m_numCol [llength $m_nodePositionList]
    contourSetup

    if {!$m_forLCLS} {
        set m_enableStrategy 0
    }

    if {$m_enableStrategy == "1"} {
        set numNode4Phi [expr $m_numCol - 1]
    } else {
        set numNode4Phi $m_numCol
    }

    ### find out phiPerNode
    if {$m_forLCLS} {
        puts "for LCLS, m_nodeAngle=$m_nodeAngle"
        set endAngle [expr $m_startAngle + ($numNode4Phi - 1) * $m_nodeAngle]
        dict set m_extraUserParameters end_angle $endAngle
        puts "for LCLS, set extra end_angle to $endAngle"
        dict set m_extraUserParameters node_frame 1
    } else {
        set numFrmPerNode [expr int(ceil(double($m_numFrame) / $numNode4Phi))]
        set m_nodeAngle    [expr $m_delta * $numFrmPerNode]
        puts "not for LCLS, m_nodeAngle=$m_nodeAngle"
        puts "delta=$m_delta, framePerNode=$numFrmPerNode"
        dict set m_extraUserParameters node_angle $m_nodeAngle
        dict set m_extraUserParameters node_frame $numFrmPerNode
    }

    set m_nodeList         [string repeat "S " $m_numCol]
    set m_nodeList4XFELPhi [string repeat "N " $m_numCol]


    if {$m_enableStrategy == "1"} {
        set m_nodeList [lreplace $m_nodeList 0 0 N]
        set startI 0
    } else {
        set startI 1
    }

    ### adjust angle
    set posWithAngleList [list]
    set firstPos [lindex $m_nodePositionList 0]
    lappend posWithAngleList $firstPos
    set remainPosList [lrange $m_nodePositionList 1 end]

    set i $startI
    foreach pos $remainPosList {
        set angle [expr $ca + $i * $m_nodeAngle]
        set posA [lreplace $pos 3 3 $angle]
        lappend posWithAngleList $posA
        incr i
    }
    set m_nodePositionList $posWithAngleList

    ### options
    if {$m_collectPhiOscAtMiddle} {
        set ll [llength $m_nodeList4XFELPhi]
        set mm [expr $ll / 2]
        set m_nodeList4XFELPhi [lreplace $m_nodeList4XFELPhi $mm $mm 0]
    }
    if {$m_collectPhiOscAtEnd} {
        set m_nodeList4XFELPhi [lreplace $m_nodeList4XFELPhi end end 0]
    }
    if {$m_collectPhiOscAtAll} {
        set m_nodeList4XFELPhi [string repeat "0 " $m_numCol]
        if {$m_enableStrategy == "1"} {
            set m_nodeList4XFELPhi [lreplace $m_nodeList4XFELPhi 0 0 N]
        }
    }

    ## whole crystal parameters:
    set cx [expr 0.5 * ($allMinX + $allMaxX)]
    set cy [expr 0.5 * ($allMinY + $allMaxY)]
    set cz [expr 0.5 * ($allMinZ + $allMaxZ)]
    set rx [expr $allMaxX - $allMinX]
    set ry [expr $allMaxY - $allMinY]
    set rz [expr $allMaxZ - $allMinZ]

    set m_oOrig [lreplace $m_oOrig 0 2 $cx $cy $cz]
    ### saveShape
    foreach {m_oCenterX m_oCenterY} \
    [calculateSamplePositionOnVideo $m_oOrig $m_oOrig 1] break
    set m_uCenterX     $m_oCenterX
    set m_uCenterY     $m_oCenterY
    set m_oGridCenterX $m_oCenterX
    set m_oGridCenterY $m_oCenterY
    set m_uGridCenterX $m_oCenterX
    set m_uGridCenterY $m_oCenterY
    puts " center at video: $m_oCenterX $m_oCenterY"
    puts "orig=$m_oOrig"

    puts "range $rx $ry $rz"
    ## saveSize
    set m_oHalfWidth  [expr 500.0 * $rz]
    set m_oHalfHeight [expr 500.0 * sqrt($rx * $rx + $ry * $ry)]
}

body GridItemCrystal::generateGridMatrix { } {
    puts "Crystal generateGridMatrix for $this"
    if {$m_guiId == ""} {
        puts "guiId empty, skip"
        puts "m_itemId=$m_itemId"
        puts "canvas=$m_canvas"
        return
    }

    regenerateOrig

    $m_canvas delete grid_$m_guiId

    if {$m_oCellWidth == 0 || $m_oCellHeight == 0} {
        puts "cell size =0 skip generate matrix"
        return
    }

    ### for crystal drawing, rectangle of "cell" is the beam area
    foreach {m_cellWidth m_cellHeight} [$m_holder micron2pixel \
    $m_beamWidth $m_beamHeight] break
    if {$m_cellWidth == 0 || $m_cellHeight == 0} {
        puts "cell size =0 because holder not ready skip generate matrix"
        return
    }

    ## this one, no need. already called in regenerateOrig and no contour
    ## for crysta, so the cell size not important.
    ##contourSetup

    set m_gridCenterX $m_centerX
    set m_gridCenterY $m_centerY
    foreach {m_uGridCenterX m_uGridCenterY} [$m_holder pixel2micron \
    $m_gridCenterX $m_gridCenterY] break
    set m_oGridCenterX $m_uGridCenterX
    set m_oGridCenterY $m_uGridCenterY

    set halfW [expr abs($m_cellWidth  / 2.0)]
    set halfH [expr abs($m_cellHeight / 2.0)]

    set displayOrig [$m_holder getDisplayOrig]
    set index -1
    foreach pos $m_nodePositionList {
        incr index
        foreach {x y} [samplePositionToXy $pos] break
        foreach {hw hh} \
        [translateProjectionBox $halfW $halfH $pos $displayOrig] break

        set x1 [expr $x - $hw]
        set x2 [expr $x + $hw]
        set y1 [expr $y - $hh]
        set y2 [expr $y + $hh]
        $m_canvas create polygon $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 \
        -outline $GridGroupColor::COLOR_GRID \
        -fill "" \
        -tags [list grid grid_$m_guiId item_$m_guiId node_${m_guiId}_${index}]
    }

    foreach guiId $m_allGuiIdList {
        $m_canvas raise $guiId
    }
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    $m_canvas raise group
    $m_canvas raise beam_info
    $m_canvas raise hot_spot_$m_guiId
}
body GridItemCrystal::redrawGridMatrix { } {
    puts "Crystal redrawGridMatrix"
    if {$m_guiId == ""} {
        puts "Crystal redrawGridMatrix skip empty guiId"
        return
    }
    if {![shouldDisplay]} {
        removeAllGui
        puts "Crystal redrawGridMatrix skip shouldl not display"
        return
    }

    set nodeColorList [getContourDisplayList]
    $m_obj setValues $nodeColorList

    set nodeLabelList [getNumberDisplayList]

    $m_canvas delete grid_$m_guiId

    if {$m_oCellWidth == 0 || $m_oCellHeight == 0} {
        puts "Crystal redrawGridMatrix skip, cell size 0"
        return
    }

    set m_uCellWidth  $m_oCellWidth
    set m_uCellHeight $m_oCellHeight
    foreach {m_cellWidth m_cellHeight} [$m_holder micron2pixel \
    $m_beamWidth $m_beamHeight] break

    if {$m_cellWidth == 0 || $m_cellHeight == 0} {
        puts "Crystal redrawGridMatrix skip, holder not ready"
        return
    }

    set m_gridCenterX $m_centerX
    set m_gridCenterY $m_centerY
    foreach {m_uGridCenterX m_uGridCenterY} [$m_holder pixel2micron \
    $m_gridCenterX $m_gridCenterY] break
    set m_oGridCenterX $m_uGridCenterX
    set m_oGridCenterY $m_uGridCenterY

    set halfW [expr abs($m_cellWidth  / 2.0)]
    set halfH [expr abs($m_cellHeight / 2.0)]

    set font_sizeW [expr int(abs(0.33 * $m_cellWidth))]
    set font_sizeH [expr int(abs(0.33 * $m_cellHeight))]
    set font_size [expr ($font_sizeW > $font_sizeH)?$font_sizeH:$font_sizeW]
    if {$font_size > 16} {
        set font_size 16
    }

    set noFill 0
    if {[string first only [getContourLevels]] >= 0} {
        set noFill 1
    }
    
    set displayOrig [$m_holder getDisplayOrig]
    set index -1
    foreach pos $m_nodePositionList {
        incr index
        foreach {x y} [samplePositionToXy $pos] break
        foreach {hw hh} \
        [translateProjectionBox $halfW $halfH $pos $displayOrig] break

        set x1 [expr $x - $hw]
        set x2 [expr $x + $hw]
        set y1 [expr $y - $hh]
        set y2 [expr $y + $hh]
        set nodeStatus [lindex $nodeColorList $index]
        set nodeLabel  [lindex $nodeLabelList $index]
        set color      [$m_obj getColor 0 $index]
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
        if {$noFill} {
            set fill ""
            set stipple ""
        }

        set hid [$m_canvas create polygon $x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 \
        -outline $GridGroupColor::COLOR_GRID \
        -fill $fill \
        -stipple $stipple \
        -tags [list grid grid_$m_guiId item_$m_guiId node_${m_guiId}_${index}]]

        $m_canvas bind $hid <Button-1> "$this gridPress 0 $index %x %y"

        set tx [expr ($x1 + $x2) / 2.0]
        set ty [expr ($y1 + $y2) / 2.0]
        set hid [$m_canvas create text $tx $ty \
        -text $nodeLabel \
        -font "-family courier -size $font_size" \
        -fill $GridGroupColor::COLOR_VALUE \
        -anchor c \
        -justify center \
        -tags \
        [list grid grid_$m_guiId item_$m_guiId \
        nodeLabel_${m_guiId}_${index}]]

        $m_canvas bind $hid <Button-1> "$this gridPress 0 $index %x %y"
    }

    #redrawContour

    foreach guiId $m_allGuiIdList {
        $m_canvas raise $guiId
    }
    if {$m_gridOnTopOfBody} {
        $m_canvas raise grid_$m_guiId
    }

    $m_canvas raise group
    $m_canvas raise beam_info
    $m_canvas raise hot_spot_$m_guiId
}
body GridItemCrystal::getClickInfo { x y {row ""} {column ""} } {
    puts "getClickInfo $x $y $row $column for crystal $this"
    if {$m_cellHeight == 0 || $m_cellWidth == 0} {
        return ""
    }

    set ll [llength $m_nodePositionList]
    if {$row != "0" \
    || ![string is integer -strict $column] \
    || $column < 0 \
    || $column >= $ll} {
        puts "bad row or column"
        return ""
    }

    set nodePos [lindex $m_nodePositionList $column]
    foreach {x0 y0 z0 a0} $nodePos break
    set nodeOrig [lreplace $m_oOrig 0 3 $x0 $y0 $z0 $a0]
    set displayOrig [$m_holder getDisplayOrig]

    foreach {nodeCenterX nodeCenterY nodeCenterUX nodeCenterUY} \
    [samplePositionToXy $nodePos] break
    puts "samplePostionToXy $nodeCenterX $nodeCenterY $nodeCenterUX $nodeCenterUY"

    foreach {nodeCenterOX nodeCenterOY} \
    [reverseProjection $nodeCenterUX $nodeCenterUY \
    $displayOrig $nodeOrig] break

    puts "nodeCenterO $nodeCenterOX $nodeCenterOY"

    foreach {ux uy} [$m_holder pixel2micron $x $y] break

    if {[catch {
        foreach {ox oy} [reverseProjection $ux $uy $displayOrig $nodeOrig] break
    } errMsg]} {
        puts "reverseProjection for getClickInfo failed: $errMsg"
        return ""
    }
    puts "u: $ux $uy o: $ox $oy"
    set oxLocal [expr $ox - $nodeCenterOX]
    set oyLocal [expr $oy - $nodeCenterOY]

    puts "result [list $row $column $oxLocal $oyLocal]"

    return [list $row $column $oxLocal $oyLocal]
}

class GridCanvas {
    inherit ::DCS::ComponentGateExtension GridItemHolder

    itk_option define -purpose purpose Purpose $gGridPurpose

    itk_option define -onKeyEnter onKeyEnter OnKeyEnter ""

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
        updateBeamPosition
    }

    #### cross_only box_only both
    itk_option define -showBeamInfo showBeamInfo ShowBeamInfo both {
        updateBeamDisplay
    }

    ### all, selected_only, phi_match(default)
    itk_option define -showItem showItem ShowItem all {
        foreach item $m_itemList {
            $item refresh
        }
    }

    itk_option define -showRasterToo showRasterToo ShowRasterToo 0 {
        foreach item $m_itemList {
            $item refresh
        }
    }

    itk_option define -packOption packOption PackOption "-side top"

    itk_option define -cluster cluster Cluster ""

    itk_option define -title   title   Title   ""        { redrawTitle }

    itk_option define -noticeWidget noticeWidget NoticeWidget "" {
        redrawNotice
    }

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
                if {[string range $itk_option(-toolMode) 0 3] == "add_"} {
                    allItemDeactive
                } else {
                    allItemActive
                }
            }
        }
        updateRegisteredComponents toolMode
    }

    itk_option define -allowLookAround allowLookAround AllowLookAround 0 {
        handleNewOutput
    }

    private common   MIN_ZOOM   1
    private common   MAX_ZOOM   8.0

    protected variable m_rawImage ""
    private variable m_rawWidth    0
    private variable m_rawHeight   0

    #### m_zoom is defined as ratio between displayed image size and view size.
    #### it is NOT raw image size, it is about displayed image size.
    #### m_zoom is only used in image display, not graphics.
    #### graphics is decided by the viewOrig and the displayed image size.
    #### m_zoom == 1 means no scroll bar needed.  image just takes the whole
    #### view.
    #### We also enforce that m_zoom >=1.  You can reduce the window size
    #### if you want a smaller display.
    private variable m_zoom     1.0
    private variable m_viewWidth   0
    private variable m_viewHeight  0
    #### m_zoom, m_viewWidth, and m_viewHeight will decide m_imageWidth and
    #### m_imageHeight.
    #### image raw width and height are also used to decide ratio between
    #### m_imageWidth and m_imageHeight.
    private variable m_imageWidth  0
    private variable m_imageHeight  0


    private variable m_lastAddMode "add_rectangle"

    protected variable m_snapshot

    private variable m_winID "no defined"

    private variable m_b1PressX 0
    private variable m_b1PressY 0
    private variable m_b1ReleaseX 0
    private variable m_b1ReleaseY 0
    protected variable m_currentItem ""
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
    protected variable m_noticeContents ""
    protected variable m_noticeColor red

    private variable m_deviceFactory ""
    protected variable m_objGridGroupConfig ""
    private variable m_objGridGroupFlip ""
    private variable m_objMoveMotors ""

    protected variable m_zoomCenterX 0.5
    protected variable m_zoomCenterY 0.5
    protected variable m_xviewInfo [list 0 1]
    protected variable m_yviewInfo [list 0 1]

    protected variable m_beamX -1
    protected variable m_beamY -1
    protected variable m_beamsizeInfo [list 0.1 0.1 white]

    protected variable m_objVideoOrig ""
    protected variable m_ctsVideoOrig ""

    protected variable m_gridIdMap [dict create]

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
        } else {
            updateBeamPosition
        }
    }

    public method handleBeamClick { wx wy } {
        #puts "puts handleBeamClick"
        set x [$m_myCanvas canvasx $wx]
        set y [$m_myCanvas canvasy $wy]
        set matchList [$m_myCanvas find overlapping $x $y $x $y]
        if {$matchList == ""} {
            ## never happen, at least you are click on the image.
            return
        }
        set matchTagList ""
        foreach id $matchList {
            set tagList [$m_myCanvas gettags $id]
            if {$tagList != ""} {
                eval lappend matchTagList $tagList
            }
        }
        if {$matchTagList != ""} {
            eval lappend matchList $matchTagList
        }
        #puts "matchList $matchList"
        ### search in reverse order
        set ll [llength $m_itemList]
        for {set i [expr $ll - 1]} {$i >= 0} {incr i -1} {
            set item [lindex $m_itemList $i]
            #puts "check item $item"
            if {[$item match $matchList]} {
                $item bodyPress $wx $wy $matchList
            }
        }
    }

    public method createCrystalTemplate { } {
        ##TODO: add tool mode and current template check
        clearTemplateItem
        set orig [getDisplayOrig]
        set m_templateItem \
        [GridItemCrystal::createCrystal $m_myCanvas $orig $this]

        switch -exact -- $itk_option(-purpose) {
            forLCLS -
            forLCLSCrystal -
            forL614 {
                if {[catch {$m_templateItem setForLCLS 1} errMsg]} {
                    puts "failed to set forLCLS: $errMsg"
                }
            }
        }
    }
    public method getTemplateItem { } {
        return $m_templateItem
    }
    public method getCurrentItem { } {
        return $m_currentItem
    }

    ### sim click on video: move the clicked point to beam center
    public method handleClickToCenter { x y }

    public method handleShowOnlyCurrentGridUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        if {$contents_} {
            configure -showItem selected_only
        } else {
            configure -showItem all
        }
    }
    public method handleShowRasterTooUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        configure -showRasterToo $contents_
    }


    ### it needs window size and the image be ready to do the first time
    ### drawing.
    private method firstTimeDrawImage

    private method redrawImage
    private method redrawGraphics
    private method updateSnapshot
    protected method updateBeamPosition { }

    ### fraction of image size
    protected method setCurrentBeamPosition { x y } {
        ##this will update the beam size too.
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
                ### in case of group item.
                $m_templateItem onUnselected

                delete object $m_templateItem
            }
            set m_templateItem ""
        }
        $m_myCanvas delete rubberband
    }

    public method xview { args } {
        eval $m_myCanvas xview $args
    }

    public method setToolMode { mode } {
        set ll 0
        set anySelected 0
        foreach item $m_itemList {
            set shape   [$item getShape]
            set forLCLS [$item getForLCLS]
            if {[::GridItemBase::itemFitPurpose \
            $itk_option(-purpose) $shape $forLCLS] \
            } {
                incr ll
                if {[$item getItemStatus] == "selected"} {
                    incr anySelected
                }
            }
        }

        puts "$this setToolMode $mode ll=$ll"
        if {$ll == 0} {
            puts "empty itemList"
            switch -exact -- $itk_option(-purpose) {
                forCrystal -
                forLCLSCrystal {
                    puts "forCrystal , change mode to add_crystal"
                    set mode add_crystal
                }
                forPXL614 -
                forL614 {
                    switch -exact -- $mode {
                        add_l614 -
                        add_trap_array -
                        add_mesh {
                        }
                        default {
                            set mode add_l614
                        }
                    }
                }
                default {
                    switch -exact -- $mode {
                        add_crystal {
                            set mode add_rectangle
                        }
                        default {
                            if {[string range $mode 0 3] != "add_"} {
                                set mode add_rectangle
                            }
                        }
                    }
                }
            }
        }
        set mode [GridCanvasControlCombo::toolModeMappingByPurpose \
        $mode $itk_option(-purpose)]
        puts "$this final mode $mode"
        configure -toolMode $mode

        if {$mode == "adjust" && $anySelected == 0} {
            setNotice "Click to select an item first"
        }
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
        if {![$m_currentItem shouldDisplay]} {
            return -1
        }
        return [$m_currentItem getGridId]
    }
    public method getCurrentGridShape { } {
        if {$m_currentItem == ""} {
            return ""
        }
        if {![$m_currentItem shouldDisplay]} {
            return ""
        }
        return [$m_currentItem getShape]
    }
    public method getCurrentItemDisplayed { } {
        puts "$this getCurrentItemDisplay"
        if {$m_currentItem == ""} {
            puts "0 no currentItem"
            return 0
        }
        if {![$m_currentItem shouldDisplay]} {
            puts "0 should not display"
            return 0
        }
        set ss [$m_currentItem getItemStatus]
        if {$ss != "selected"} {
            puts "current $m_currentItem status = $ss != selected"
            return 0
        }
        return 1
    }
    public method getCurrentItemIsGroup { } {
        puts "$this getCurrentItemIsGroup"
        if {$m_currentItem == ""} {
            puts "0 no currentItem"
            return 0
        }
        if {[$m_currentItem getShape] != "group"} {
            return 0
        }
        return 1
    }
    public method getCurrentItemIsMegaCrystal { } {
        if {$m_currentItem == ""} {
            puts "0 no currentItem"
            return 0
        }
        if {[$m_currentItem getShape] != "crystal"} {
            return 0
        }
        if {![$m_currentItem isMegaCrystal]} {
            return 0
        }
        return 1
    }

    public method isActive { } {
        if {!$m_remoteMode} {
            return 1
        }
        return $_gateOutput
    }

    public method onXScrollCommand { args } {
        redrawTitle

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
    public method DefineCrystalFirstClick { } {
        set orig [getDisplayOrig]
        set cy [lindex $$orig 8]
        set cx [lindex $$orig 9]

        set x [expr $m_imageWidth * $cx]
        set y [expr $m_imageHeight * $cy]
        set m_b1PressX $x
        set m_b1PRessY $y

        if {$m_templateItem != ""} {
            log_warning alrealy in create some item.
            clearTemplateItem
        }
        set m_templateItem [GridItemCrystal::create $m_myCanvas $x $y $this]

        switch -exact -- $itk_option(-purpose) {
            forLCLS -
            forLCLSCrystal -
            forL614 {
                if {[catch {$m_templateItem setForLCLS 1} errMsg]} {
                    puts "failed to set forLCLS: $errMsg"
                }
            }
        }
    }
    public method DefineCrystalSecondClick { } {
        set orig [getDisplayOrig]
        set cy [lindex $$orig 8]
        set cx [lindex $$orig 9]

        set x [expr $m_imageWidth * $cx]
        set y [expr $m_imageHeight * $cy]
        $m_templateItem createPress $x $y
        $m_templateItem createPress $x $y
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
            #panClick $xw $yw
            return
        }

        if {[$m_displayControl getClickToMove]} {
            handleClickToCenter $x $y
            return
        }

        set part [string range $itk_option(-toolMode) 0 3]
        if {$part == "add_"} {
            switch -exact -- $itk_option(-purpose) {
                forPXL614 -
                forL614 {
                    switch -exact -- $itk_option(-toolMode) {
                        add_l614 -
                        add_trap_array -
                        add_mesh {
                            ###OK
                        }
                        default {
                            configure -toolMode add_l614
                        }
                    }
                }
                forLCLSCrystal {
                    if {$itk_option(-toolMode) != "add_crystal"} {
                        configure -toolMode add_crystal
                    }
                }
            }
        }

        switch -exact -- $itk_option(-toolMode) {
            add_mesh {
                ### need multiple press
                if {$m_templateItem == ""} {
                    set m_templateItem \
                    [GridItemMesh::create \
                    $m_myCanvas $x $y $this]
                } else {
                    $m_templateItem createPress $x $y
                }
            }
            add_trap_array {
                ### need multiple press
                if {$m_templateItem == ""} {
                    set m_templateItem \
                    [GridItemNetBase::create \
                    $m_myCanvas $x $y $this]
                } else {
                    $m_templateItem createPress $x $y
                }
            }
            add_l614 {
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
            add_crystal {
                handleClickToCenter $x $y
            }
            pan {
                panClick $xw $yw
                return
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
        switch -exact -- $itk_option(-purpose) {
            forLCLS -
            forLCLSCrystal -
            forL614 {
                if {$m_templateItem != ""} {
                    if {[catch {$m_templateItem setForLCLS 1} errMsg]} {
                        puts "failed to set forLCLS: $errMsg"
                    }
                }
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
            clearButtonCallback
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
    public method handleKeyPress { k xw yw} {
        set x [$m_myCanvas canvasx $xw]
        set y [$m_myCanvas canvasy $yw]
        puts "key pressed k=$k x=$x y=$y"
        if {$k == 36 && $itk_option(-onKeyEnter) != ""} {
            eval $itk_option(-onKeyEnter)
        }
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
        puts "grid display resize: $winID $width $height"
        set m_viewWidth  [expr $width - 15]
        set m_viewHeight [expr $height - 15]

        if {$m_inZoom} {
            puts "inZoom"
            return
        }

        #set m_zoom 1.0
        #firstTimeDrawImage
        ### the same as above:
        set m_drawImageOK 0
        zoom 1.0
    }

    public method deleteSelected { } {
        #puts "deleteSelected"
        #puts "current item=$m_currentItem"

        if {$m_currentItem == ""} {
            return 0
        }

        removeItem $m_currentItem
        #puts "current removed"
        set m_currentItem ""
        updateRegisteredComponents current_item_display
        updateRegisteredComponents current_item_group
        updateRegisteredComponents current_item_shape
        return 1
    }
    public method hideSelected { } {
        if {$itk_option(-showItem) == "selected_only"} {
            log_error cannot hide current while only display current grid.
            return
        }
        puts "hideSelected"
        puts "current item=$m_currentItem"

        if {$m_currentItem != ""} {
            set id [$m_currentItem getGridId]
            gCurrentGridGroup setGridHide $id 1
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
            Both -
            Box -
            box -
            Box_Only -
            box_only {
                updateBeamDisplay
            }
        }
    }

    public method handleBeamSizeUpdate { caller_ ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        setBeamSize $contents_
    }

    public method zoom { scaleFactor } {
        puts "zoom $scaleFactor"
        set scaleFactor [expr abs(double($scaleFactor))]

        if {$scaleFactor < $MIN_ZOOM} {
            set scaleFactor $MIN_ZOOM
        }
        if {$scaleFactor > $MAX_ZOOM} {
            set scaleFactor $MAX_ZOOM
        }
        set m_zoom $scaleFactor
        return [firstTimeDrawImage]
    }

    #implement GridItemHolder
    public method addItem { item {from_create 1}} {
        if {$item == $m_templateItem} {
            set m_templateItem ""
        }

        if {$from_create && $m_remoteMode && ![$item isa GridItemGroup]} {
            set info [$item getItemInfo]
            set geoInfo [lindex $info 1]
            if {[catch {dict get $geoInfo for_lcls} iForLCLS]} {
                set iForLCLS 0
            }
            switch -exact -- $itk_option(-purpose) {
                forPXL614 -
                forCrystal -
                forGrid {
                    if {$iForLCLS} {
                        log_error leaked forLCLS, \
                        please report to software engineer
                        delete object $item
                        return
                    }
                }
                forLCLS -
                forLCLSCrystal -
                forL614 {
                    if {!$iForLCLS} {
                        log_error leaked forLCLS, \
                        please report to software engineer
                        delete object $item
                        return
                    }
                }
                default {
                }
            }

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

        #setCurrentItem $item

        if {$itk_option(-cluster) != ""} {
            $itk_option(-cluster) setToolMode adjust
        } else {
            setToolMode adjust
            setNotice ""
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
            updateRegisteredComponents current_item_display
            updateRegisteredComponents current_item_group
            updateRegisteredComponents current_item_shape
            if {!$no_event && ![$item isa GridItemGroup]} {
                gCurrentGridGroup selectGridId [$item getGridId]
            }
            return 1
        } else {
            #puts "$item already current"
            return 0
        }
    }
    public method clearCurrentItem { {no_event 0} } {
            __clearCurrentItem
    }
    public method __clearCurrentItem { } {
        if {$m_currentItem != ""} {
            ### give item a chance to do something.
            ### group item will remove itself.
            $m_currentItem onUnselected
            #puts "clear currentItem"

            set m_currentItem ""
            updateRegisteredComponents current_item_display
            updateRegisteredComponents current_item_group
            updateRegisteredComponents current_item_shape
        }
    }
    public method mergeItems { item deleteList }
    public method onItemChange { item }
    public method registerButtonCallback { motion release } {
        if {[isActive]} {
            set m_buttonCallbackMotion $motion
            set m_buttonCallbackRelease $release
        } else {
            clearButtonCallback
        }
    }

    public method setNotice { txt {color blue}} {
        set m_noticeContents $txt
        set m_noticeColor $color
        redrawNotice
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
        if {$itk_option(-viewOrig) == ""} {
            return "0.0 0.0 0.0 0.0 1.0 -1.0 1 1 0.5 0.5 unknown"
        }
        return $itk_option(-viewOrig) 
    }

    public method onItemClick { item row column }
    public method onItemRightClick { item row column } { }
    public method moveTo { item x y index}

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
            updateRegisteredComponents current_item_display
            updateRegisteredComponents current_item_group
            updateRegisteredComponents current_item_shape
        }
        if {$m_currentItem != "" && [$m_currentItem getShape] == "group"} {
            clearCurrentItem
        }

        set index [lsearch -exact $m_itemList $item]
        if {$index >= 0} {
            set m_itemList [lreplace $m_itemList $index $index]
        }
        #puts "delete object"
        delete object $item

        if {[llength $m_itemList] == 0 && $itk_option(-cluster) == ""} {
            setNotice "use tools above to define new item"
            configure -toolMode $m_lastAddMode
        }
        updateRegisteredComponents numItem
    }

    public method redrawTitle { }
    public method redrawNotice { }

    public method setupRightClick { cmd } {
        bind $m_myCanvas <Button-3> $cmd
    }

    public method reset { } {
        puts "resetting $this"
        foreach item $m_itemList {
            #puts "deleting $item"
            delete object $item
        }
        set m_gridIdMap [dict create]
        set m_itemList ""
        set m_currentItem ""
        #set m_groupId -1
        set m_snapshotId -1

        $m_myCanvas delete all

        set m_titleId ""

        $m_rawImage blank
        $m_snapshot blank

        $m_myCanvas create image 0 0 \
        -image $m_snapshot \
        -anchor nw \
        -tags snapshot

        set m_drawImageOK 0
        if {$itk_option(-cluster) == ""} {
            configure -toolMode $m_lastAddMode
        }
        updateRegisteredComponents numItem
        updateRegisteredComponents current_item_display
        updateRegisteredComponents current_item_group
        updateRegisteredComponents current_item_shape
    }

    ## derive class should implment
    public method refresh { objSnapshotImage } { error "not implement refresh" }

    private method updateBeamDisplay { }

    public method setDisplayControl { m } {
        if {$m_displayControl == $m} {
            return
        }
        if {$m_displayControl != ""} {
            $m_displayControl unregister $this show_only_current_grid \
            handleShowOnlyCurrentGridUpdate

            $m_displayControl unregister $this show_raster_too \
            handleShowRasterTooUpdate
        }
        set m_displayControl $m
        if {$m_displayControl != ""} {
            $m_displayControl register $this show_only_current_grid \
            handleShowOnlyCurrentGridUpdate

            $m_displayControl register $this show_raster_too \
            handleShowRasterTooUpdate
        }
    }
    public method getDisplayControl { } { return $m_displayControl }

    protected variable m_displayControl ::gCurrentGridGroup

    constructor { args } {
        ::DCS::Component::constructor {
            toolMode     {getToolMode}
            numItem      {getNumberOfItem}
            current_item_display {getCurrentItemDisplayed}
            current_item_group   {getCurrentItemIsGroup}
            current_item_shape   {getCurrentGridShape}
        }
    } {

        set m_deviceFactory [::DCS::DeviceFactory::getObject]

        set m_objGridGroupConfig \
        [$m_deviceFactory createOperation gridGroupConfig]

        set m_objGridGroupFlip [$m_deviceFactory createOperation gridGroupFlip]
        set m_objMoveMotors [$m_deviceFactory createOperation moveMotors]

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

        switch -exact -- $itk_option(-purpose) {
            forPXL614 -
            forL614 {
                configure -toolMode add_l614
            }
            forCrystal {
                configure -toolMode add_crystal
            }
        }

        bind $m_myCanvas <Motion> "$this handleImageMotion %x %y"

        bind $m_myCanvas <B1-Motion> "$this handleButtonMotion %x %y"
        bind $m_myCanvas <ButtonPress-1> "$this handleButtonPress %x %y"
        bind $m_myCanvas <ButtonRelease-1> "$this handleButtonRelease %x %y"

        bind $m_myCanvas <KeyPress> "$this handleKeyPress %k %x %y"

        $m_myCanvas bind snapshot <Enter> "$this handleImageEnter %x %y"

        announceExist

        gCurrentGridGroup register $this grid_beam_size handleBeamSizeUpdate

        if {$m_displayControl != ""} {
            $m_displayControl register $this show_only_current_grid \
            handleShowOnlyCurrentGridUpdate

            $m_displayControl register $this show_raster_too \
            handleShowRasterTooUpdate
        }
    }
    destructor {
        if {$m_objVideoOrig != ""} {
            $m_objVideoOrig unregister $this contents handleVideoOrigUpdate
        }
        gCurrentGridGroup unregister $this grid_beam_size handleBeamSizeUpdate

        if {$m_displayControl != ""} {
            $m_displayControl unregister $this show_only_current_grid \
            handleShowOnlyCurrentGridUpdate

            $m_displayControl unregister $this show_raster_too \
            handleShowRasterTooUpdate
        }
    }
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
    set orig [getDisplayOrig]
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
body GridCanvas::moveTo { item x y index } {
    set gridId [$item getGridId]
    if {$m_liveVideo} {
        set orig [getDisplayOrig]
        set camera [lindex $orig 10]
        set facing $camera
    } else {
        set facing beam
    }
    eval $m_objGridGroupConfig startOperation \
    on_grid_move $m_groupId $gridId $x $y $facing $index
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

        if {!$m_drawImageOK} {
            firstTimeDrawImage
        } else {
            redrawImage
        }
    } errMsg] == 1} {
        set m_drawImageOK 0
        if {!$m_liveVideo} {
            ## live video has its own retry
            log_error failed to create image from jpg files: $errMsg
            puts "failed to create image from jpg files: $errMsg"
            set m_retryID [after 1000 "$this update"]
        }
    }
}
body GridCanvas::firstTimeDrawImage { } {
    ### check information ready or not.
    if {$m_rawWidth < 1 || $m_rawHeight < 1} {
        $m_snapshot blank
        set m_drawImageOK 0
        puts "rawImage size < 1"
        return 0
    }
    if {$m_viewWidth < 1 || $m_viewHeight < 1} {
        $m_snapshot blank
        set m_drawImageOK 0
        puts "view size < 1"
        return 0
    }
    if {$m_zoom < 1.0} {
        set m_zoom 1.0
    }

    #### calculate image display size from
    #### 1. view size
    #### 2. raw image size (need width height ratio)
    #### 3. zoom

    set oldImageWidth  $m_imageWidth
    set oldImageHeight $m_imageHeight

    set ww [expr $m_viewWidth  * $m_zoom]
    set hh [expr $m_viewHeight * $m_zoom]
    set rW [expr double($ww) / $m_rawWidth]
    set rH [expr double($hh) / $m_rawHeight]

    if {$rW <= $rH} {
        set m_imageWidth  [expr int($m_viewWidth * $m_zoom)]
        set m_imageHeight \
        [expr int($m_imageWidth * $m_rawHeight / $m_rawWidth)]
    } else {
        set m_imageHeight [expr int($m_viewHeight * $m_zoom)]
        set m_imageWidth \
        [expr int($m_imageHeight * $m_rawWidth / $m_rawHeight)]
    }

    puts "setupImageSize: old $oldImageWidth X $oldImageHeight"
    puts "setupImageSize: new $m_imageWidth X $m_imageHeight"

    if {$m_imageWidth == 0 || $m_imageHeight == 0} {
        set m_drawImageOK 0
        return 0
    }

    $m_myCanvas config -scrollregion [list 0 0 $m_imageWidth $m_imageHeight]

    if {$m_imageWidth != $oldImageWidth \
    || $m_imageHeight != $oldImageHeight} {
        pack forget $itk_component(ring)
        eval pack $itk_component(ring) $itk_option(-packOption)
        pack propagate $itk_component(ring) 0
        $itk_component(ring) configure \
        -width  [expr $m_imageWidth + 2] \
        -height [expr $m_imageHeight + 2]
    }

    set m_drawImageOK 1
    redrawImage
    redrawGraphics

    return 1
}
body GridCanvas::redrawGraphics { } {
    updateBeamDisplay
    ### we do not want to scale size of vertices, only their position.
    $m_myCanvas delete hotspot||rubberband

    foreach item $m_itemList {
        $item onZoom
        $item redraw 0
    }
}
body GridCanvas::redrawImage { } {
    set ss [expr 1.0 * $m_imageWidth / $m_rawWidth]

    if {$ss >= 0.75} {
        imageResizeBilinear     $m_snapshot $m_rawImage $m_imageWidth
    } else {
        imageDownsizeAreaSample $m_snapshot $m_rawImage $m_imageWidth 0 1
    }
}
body GridCanvas::handleNewOutput {} {
    #puts "handleNewOutput: $_gateOutput"
    if { $_gateOutput == 0 && !$itk_option(-allowLookAround)} {
        set m_dcsCursor watch
        $itk_component(drawArea) configure -state disabled
    } else {
        set m_dcsCursor [. cget -cursor]
        $itk_component(drawArea) configure -state normal 
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
        #puts "mode= [$item getMode] for $item"
        if {![$item adjustableOnVideo]} {
            continue
        }
        set box [$item getBBox]
        foreach {bx1 by1 bx2 by2} $box break
        if {$bx1 >= $x1 && $by1 >= $y1 && $bx2 <= $x2 && $by2 <= $y2} {
            lappend result $item
        }
    }
    #puts "result=$result"
    return $result
}
body GridCanvas::mergeItems { item deleteList } {
    if {[$item isa GridItemGroup]} {
        log_error group item detected.
        return
    } else {
        set gridId [$item getGridId]
        set info   [$item getItemInfo]

        set argList [list $gridId $info]
        foreach ii $deleteList {
            set gridId [$ii getGridId]
            lappend argList $gridId delete
        }

        eval $m_objGridGroupConfig startOperation \
        modifyGrid $m_groupId $argList
    }
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
    if {$itk_option(-noticeWidget) != ""} {
        $itk_option(-noticeWidget) drawNotice $m_noticeContents $m_noticeColor
    }
}

body GridCanvas::updateBeamDisplay { } {
    $m_myCanvas delete beam_info

    if {$m_beamX <= 0 || $m_beamX >= 1 || $m_beamY <= 0 || $m_beamY >= 1} {
        puts "$this beam position not valid yet"
        puts "viewOrig=$itk_option(-viewOrig)"
        return
    }

    if {!$m_drawImageOK} {
        puts "image not ready for beam display"
        return
    }

    set xPixel [expr $m_beamX * $m_imageWidth]
    set yPixel [expr $m_beamY * $m_imageHeight]

    switch -exact -- $itk_option(-showBeamInfo) {
        cross_only -
        Cross_Only -
        Cross -
        cross -
        cross_and_box -
        Cross_And_Box -
        Both -
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
        Box -
        box -
        Box_Only -
        box_only -
        cross_and_box -
        Cross_And_Box -
        Both -
        both {
            foreach {wMM hMM color} $m_beamsizeInfo break
            foreach {w h} [calculateProjectionBoxFromBox \
            [getDisplayOrig] $wMM $hMM] break

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
            -outline $color \
            -width 1
        }
    }
    $m_myCanvas bind beam_info <Button-1> "$this handleBeamClick %x %y"
    if {$m_currentItem != ""} {
        $m_currentItem raise
    }
}
body GridCanvas::handleClickToCenter { x_ y_ } {
    global gSampleMotorSerialMove

    set orig $itk_option(-viewOrig)
    if {[llength $orig] < 11} {
        log_error no valid viewOrig found to handle the click
        return
    }
    foreach {- - - - - - - - cy cx -} $orig break

    ### convert pixel to fraction
    set hh [expr double($x_) / $m_imageWidth]
    set vv [expr double($y_) / $m_imageHeight]

    set dh [expr $hh - $cx]
    set dv [expr $vv - $cy]

    foreach {dx dy dz} [calculateSamplePositionDeltaFromDeltaProjection \
    $orig $dv $dh] break

    set cmd1 [list sample_x by $dx]
    set cmd2 [list sample_y by $dy]
    set cmd3 [list sample_z by $dz]

    $m_objMoveMotors startOperation $gSampleMotorSerialMove $cmd1 $cmd2 $cmd3
}

class GridCanvasCluster {
    inherit DCS::Component

    public method addCanvas { c }

    ### the GridCanvas has following interface
    public method getToolMode { } { return $m_toolMode }
    public method setToolMode { mode }
    public method clearCurrentItem { {no_event 0} }
    public method deleteSelected { }
    public method hideSelected { }
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
}
body GridCanvasCluster::deleteSelected { } {
    foreach c $m_canvasList {
        if {[$c deleteSelected]} {
            break
        }
    }
}
body GridCanvasCluster::hideSelected { } {
    foreach c $m_canvasList {
        $c hideSelected
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

    public method setGroupId { groupId } {
        puts "setGroupId to $groupId for $this"
        set m_groupId $groupId
    }
    public method getSnapshotId { } { return $m_snapshotId }

    public method refresh { objSnapshotImage }
    public method addGrid { objGrid }
    public method deleteGrid { gridId }
    public method updateGrid { objGrid }
    public method setNode { id index status }
    public method setMode { id status }
    public method zoomOnGrid { objGrid }

    ## this will decide which image display to use to adjsut grid cell size.
    ## For now, it is the min of grid width and height in pixels.
    public method getViewScoreForGrid { id }
    public method adjustGrid { id param {extra ""} }

    public method setCurrentGrid { id }

    protected common SHAPE2CLASS
    protected {
        set SHAPE2CLASS [dict create \
        rectangle GridItemRectangle \
        oval      GridItemOval \
        line      GridItemLine \
        polygon   GridItemPolygon \
        l614      GridItemL614 \
        crystal   GridItemCrystal \
        projective GridItemProjectiveBase \
        trap_array GridItemNetBase \
        mesh       GridItemMesh \
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
    puts "display $this refresh $obj"
    reset
    
    if {!$m_liveVideo} {
        set oldCamera [lindex [getDisplayOrig] 10]
        set file [$obj getFile]
        configure \
        -snapshot $file \
        -viewOrig [$obj getOrig] \
        -title    phi=[$obj getLabel]

        set newCamera [$obj getCamera]
        if {$newCamera != $oldCamera} {
            puts "switching camear: from $oldCamera to $newCamera"
        }
        registerVideoOrigExplicitly $newCamera

        ##redraw snapshot
        update
        set m_snapshotId [$obj getId]
    } else {
        configure \
        -title " live video"

        set m_snapshotId -1
    }

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

    if {$m_currentItem == $item} {
        updateRegisteredComponents current_item_display
        updateRegisteredComponents current_item_group
    }
}
body GridSnapshotDisplay::setCurrentGrid { id } {
    #puts "$this calling setCurrentGrid $id"
    if {$m_gridIdMap == ""} {
        puts "display setCurrentGrid no item for grid yet"
        return
    }
    if {![dict exists $m_gridIdMap $id]} {
        puts "display setCurrentGrid item not found for gridId=$id"
        return
    }

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

    dict unset m_gridIdMap $gridId
}
body GridSnapshotDisplay::adjustGrid { gridId  param {extra ""} } {
    if {![catch {dict get $param move_crystal} moveCrystal] \
    && [llength $moveCrystal] >= 2} {
        foreach {horz vert} $moveCrystal break
        set orig [getDisplayOrig]
        foreach {x0 y0 z0 a0 vMM hMM} $orig break
        if {$vMM < 0} {
            set vert [expr -1 * $vert]
        }
        if {$hMM < 0} {
            set horz [expr -1 * $horz]
        }

        foreach {dx dy dz} [calculateSamplePositionDeltaFromDeltaProjection \
        [getDisplayOrig] $vert $horz 1] break

        dict set param move_crystal [list $dx $dy $dz]
        puts "convert horz=$horz vert=$vert to $dx $dy $dz"

        $m_objGridGroupConfig startOperation \
        moveCrystal $m_groupId $gridId $dx $dy $dz

        return
    }

    set item [dict get $m_gridIdMap $gridId]
    $item adjustItem $param $extra
}
body GridSnapshotDisplay::getViewScoreForGrid { gridId } {
    set item [dict get $m_gridIdMap $gridId]
    foreach {w h} [$item getItemSizeInPixel] break

    set shape [$item getShape]
    switch -exact -- $shape {
        crystal {
            return $w
        }
        line {
            return [expr sqrt($w * $w + $h * $h)]
        }
        default {
            return [expr ($w>$h)?$h:$w]
        }
    }

}

GridGroup::GridGroup4BluIce gCurrentGridGroup

class GridDisplayWidget {
    inherit ::itk::Widget ::GridGroup::VideoImageDisplayHolder

    itk_option define -mdiHelper mdiHelper MdiHelper ""

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

    public method handleToolModeChange { - ready_ - - - } {
        if {!$m_toolByExternal} {
            updateRegisteredComponents tool_mode
        }
    }
    public method handleAllowLookAroundUpdate { - ready_ - contents_ -} {
        if {!$ready_} return

        configure -allowLookAround $contents_
    }

    protected variable m_cluster ""
    protected variable m_toolByExternal 0
    protected variable m_deviceFactory ""

    #### snapshot_displayed is for the snapshot list widget
    constructor { args } {
        DCS::Component::constructor {
            tool_mode           getToolMode
            snapshot_displayed  getDisplayedSnapshotIdList
        }
    } {
        set m_liveVideo 0
        set m_deviceFactory [::DCS::DeviceFactory::getObject]

        set m_cluster [GridCanvasCluster ::\#auto]

        itk_component add rc0 {
            GridSnapshotDisplay $itk_interior.rc0 $m_liveVideo \
            -systemIdleOnly 0
        } {
            keep -activeClientOnly
            keep -purpose
            keep -allowLookAround
        }

        itk_component add ssList {
            GridSnapshotListView $itk_interior.sslist
        } {
        }

        itk_component add rc1 {
            GridSnapshotDisplay $itk_interior.rc1 $m_liveVideo \
            -systemIdleOnly 0
        } {
            keep -activeClientOnly
            keep -purpose
            keep -allowLookAround
        }

        $m_cluster addCanvas $itk_component(rc0)
        $m_cluster addCanvas $itk_component(rc1)

        itk_component add cc {
            GridCanvasControl $itk_interior.cc \
            -canvas $m_cluster
        } {
            keep -purpose
            keep -mdiHelper
        }
        itk_component add pos {
            GridCanvasPositioner $itk_interior.pos \
            -holder $this \
        } {
        }

        grid $itk_component(cc)     -row 0 -column 0 -sticky we
        grid $itk_component(pos)    -row 1 -column 0 -sticky w
        grid $itk_component(rc0)    -row 2 -column 0 -sticky news
        grid $itk_component(ssList) -row 3 -column 0 -sticky we
        grid $itk_component(rc1)    -row 4 -column 0 -sticky news
        grid rowconfigure $itk_interior 2 -weight 10
        grid rowconfigure $itk_interior 4 -weight 10
        grid columnconfigure $itk_interior 0 -weight 10

        set m_maxNumDisplay 2
        set m_displayList [list $itk_component(rc0) $itk_component(rc1)]

        eval itk_initialize $args

        if {[gCurrentGridGroup getId] < 0} {
            gCurrentGridGroup switchGroupNumber 0 1
        }
        gCurrentGridGroup registerImageDisplayWidget $this

        $m_cluster register $this toolMode      handleToolModeChange

        $this register $itk_component(ssList) snapshot_displayed \
        handleDisplayedSSListUpdate

        gCurrentGridGroup register $this allow_look_around_when_busy \
        handleAllowLookAroundUpdate
    }
    destructor {
        gCurrentGridGroup unregisterImageDisplayWidget $this

        gCurrentGridGroup unregister $this allow_look_around_when_busy \
        handleAllowLookAroundUpdate
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
            #puts "showing rc$m_numDisplayed"
            grid $itk_component(rc$m_numDisplayed)
        }
    } else {
        for { } {$m_numDisplayed > $number } {incr m_numDisplayed -1} {
            set id [expr $m_numDisplayed - 1]
            #puts "removing rc$id"
            grid remove $itk_component(rc$id)
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

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -purpose purpose Purpose $gGridPurpose {
        switch -exact -- $itk_option(-purpose) {
            forCrystal {
                $m_displayControl setMasterControl ""
            }
            default {
                $m_displayControl setMasterControl ::gCurrentGridGroup
            }
        }
    }

    itk_option define -camera camera Camera inline {
        #puts "config -camera $itk_option(-camera) for $this"
        setCamera
    }

	itk_option define -imageUrl imageUrl ImageUrl  "" {
	    restartUpdates 0
    }

	itk_option define -updatePeriod updatePeriod UpdatePeriod 1000
	itk_option define -firstUpdateWait firstUpdateWait FirstUpdateWait 5000
	itk_option define -retryPeriod retryPeriod RetryPeriod 30000
	itk_option define -videoParameters videoParameters VideoParameters {}
	itk_option define -videoEnabled videoEnabled VideoEnabled 0
    itk_option define -filters filters Filters "" {
	    restartUpdates 0
    }

    public method DefineCrystalFirstClick { } {
        $itk_component(rc0) DefineCrystalFirstClick
    }
    public method DefineCrystalSecondClick { } {
        $itk_component(rc0) DefineCrystalSecondClick
    }

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
    public method handleToolModeChange { - ready_ - - - } {
        ### pass up
        if {!$m_toolByExternal} {
            updateRegisteredComponents tool_mode
        }
    }
    public method handleAllowLookAroundUpdate { - ready_ - contents_ -} {
        if {!$ready_} return

        configure -allowLookAround $contents_
    }

    public method handleFiltersUpdate { filters } {
        puts "new filters: $filters"
        if {$filters == ""} {
            configure -filters ""
        } else {
            configure -filters "&filter=$filters"
        }
    }
    public method handleRightClick { } {
        $m_filters show
    }

    public method getIsInline { } {
        if {$itk_option(-camera) == "inline"} {
            return 1
        } else {
            return 0
        }
    }

    protected method setCamera { }

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

    protected variable m_filters ""

    protected variable m_displayControl ""

    constructor { args } {
        DCS::Component::constructor {
            tool_mode    getToolMode
            snapshot_displayed  getDisplayedSnapshotIdList
            value               getIsInline
        }
    } {

        set m_displayControl [GridGroup::ItemDisplayControl ::\#auto]

        set m_liveVideo 1
        set m_deviceFactory [::DCS::DeviceFactory::getObject]

        set m_filters [VideoFilter \#auto]
        $m_filters setupCallback "$this handleFiltersUpdate"

        itk_component add control {
            GridCanvasControlCombo $itk_interior.control \
            -holder $this \
        } {
            keep -purpose
            keep -mdiHelper
            keep -camera
        }
        $itk_component(control) setDisplayControl $m_displayControl

        itk_component add rc0 {
            GridSnapshotDisplay $itk_interior.rc0 $m_liveVideo \
            -systemIdleOnly 0 \
            -noticeWidget $itk_component(control) \
        } {
            keep -activeClientOnly
            keep -purpose
            keep -allowLookAround
        }
        $itk_component(rc0) setDisplayControl $m_displayControl

        set className [::config getStr bluice.lightClass]
        if {$className == ""} {
            set className ComboLightControlWidget
        }
        itk_component add light_control {
            $className $itk_interior.light
        } { 
        }

        $itk_component(control) configure \
        -canvas $itk_component(rc0)


        itk_component add optionFrame {
            iwidgets::labeledframe $itk_interior.optionF \
            -labeltext "Options for Display" \
            -labelfont "helvetica -16 bold" \
        } {
        }
        set optionSite [$itk_component(optionFrame) childsite]

        itk_component add display_options {
            GridItemDisplayOptionWidget $optionSite.options \
            -displayControl $m_displayControl \
        } {
            keep -purpose
        }
        pack $itk_component(display_options) -expand 1 -fill both

        itk_component add moveFrame {
            iwidgets::labeledframe $itk_interior.moveF \
            -labeltext "Sample Positioning Tool" \
            -labelfont "helvetica -16 bold" \
        } {
        }
        set moveSite [$itk_component(moveFrame) childsite]

        itk_component add move {
            PositionControlWidget $moveSite.moveSample
        } {
            keep -camera
            keep -purpose
        }
        pack $itk_component(move) -expand 1 -fill both

        grid $itk_component(control) -row 0 -column 0 -sticky news \
        -columnspan 2

        grid $itk_component(optionFrame) -row 1 -column 0 -sticky new
        grid $itk_component(moveFrame)   -row 2 -column 0 -sticky wes
        grid $itk_component(rc0) \
        -row 1 -column 1 -sticky news -rowspan 2

        grid $itk_component(light_control) -row 3 -column 0 -sticky news \
        -columnspan 2

        grid rowconfigure $itk_interior 1 -weight 10
        grid columnconfigure $itk_interior 1 -weight 10

        set m_maxNumDisplay 1
        set m_displayList [list $itk_component(rc0)]

        eval itk_initialize $args
        announceExist

        if {[gCurrentGridGroup getId] < 0} {
            gCurrentGridGroup switchGroupNumber 0 1
        }

        gCurrentGridGroup registerImageDisplayWidget $this
        $m_displayControl registerImageDisplayWidget $this

        $itk_component(rc0) register $this toolMode handleToolModeChange

        gCurrentGridGroup register $this allow_look_around_when_busy \
        handleAllowLookAroundUpdate

        $itk_component(rc0) register $itk_component(control) \
        current_item_display handleCurrentItemDisplayed

        $itk_component(rc0) register $itk_component(move) \
        current_item_shape handleCurrentItemShapeUpdate

        $itk_component(rc0) register $itk_component(move) \
        toolMode handleToolModeUpdate

        $itk_component(rc0) setupRightClick "$this handleRightClick"

        $itk_component(light_control) configure \
        -switchWrap $this
    }
    destructor {
        delete object $m_displayControl

        cancelUpdates
        gCurrentGridGroup unregisterImageDisplayWidget $this

        gCurrentGridGroup unregister $this allow_look_around_when_busy \
        handleAllowLookAroundUpdate
    }
}
body GridVideoWidget::setCamera { } {
    switch -exact -- $itk_option(-camera) {
        sample {
            configure -imageUrl [::config getImageUrl 1]
        }
        inline {
            configure -imageUrl [::config getImageUrl 5]
        }
        default {
            log_error not supported camera $camera
            puts "camera {$itk_option(-camera)} not supported"
            exit
        }
    }
    $itk_component(rc0) registerVideoOrigExplicitly $itk_option(-camera)
    updateRegisteredComponents value
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
            if {$_token != ""} {
                catch {http::cleanup $_token}
                set _token ""
            }

			# grab the next image from the video server
			if {[catch {
                http::geturl ${itk_option(-imageUrl)}${itk_option(-videoParameters)}&size=large$itk_option(-filters) \
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

    itk_option define -purpose purpose Purpose $gGridPurpose {
        set m_cellFollowBeamSize 1
        switch -exact -- $itk_option(-purpose) {
            forLCLS -
            forLCLSCrystal -
            forPXL614 -
            forL614 {
                set m_cellFollowBeamSize 0
            }
            forCrystal {
                set m_cellFollowBeamSize 2
            }
            default {
                set m_cellFollowBeamSize 1
            }
        }
        switch -exact -- $itk_option(-purpose) {
            forCrystal -
            forLCLSCrystal {
                $itk_component(shape) configure \
                -menuChoices crystal
            }
            forPXL614 -
            forL614 {
                $itk_component(shape) configure \
                -menuChoices [list l614 trap_array mesh]
            }
            default {
                $itk_component(shape) configure \
                -menuChoices [list rectangle oval line polygon]
            }
        }

        ## only forCrystal displat the energyList 
        switch -exact -- $itk_option(-purpose) {
            forCrystal {
                $itk_component(resolution) configure \
                -energyWidget $itk_component(energyList)

                $itk_component(csize_to_bsize) configure \
                -text "To 1/2 Beam Size"

                $itk_component(step_to_bsize) configure \
                -text "To 1/2 Beam Width"
            }
            default {
                $itk_component(resolution) configure \
                -energyWidget ::device::energy

                $itk_component(csize_to_bsize) configure \
                -text "To Beam Size"

                $itk_component(step_to_bsize) configure \
                -text "To Beam Width"
            }
        }

        switchView $itk_option(-purpose)
    }

    ### because raster view and crystal view, "current" grid may be raster
    ### when there is no "crystal".
    itk_option define -onNew onNew OnNew 1 {
        refreshGrid
        updateRegisteredComponents on_new
    }

    ### for buttons.
    public method startNodeStrategy { } {
        set index [gCurrentGridGroup getGridIndex $m_gridId]
        $m_objCollectGrid startOperation $m_groupId $index \
        do_strategy_with_phi_osc
    }
    public method startPhiOsc { } {
        set index [gCurrentGridGroup getGridIndex $m_gridId]
        $m_objCollectGrid startOperation $m_groupId $index \
        do_phi_osc
    }

    public method deleteThisRun { } {
        $m_objGridGroupConfig startOperation deleteGrid \
        $m_groupId $m_gridId
    }
    public method copyThisItem { } {
        $m_objGridGroupConfig startOperation copyGrid \
        $m_groupId $m_gridId
    }

    public method getAttributeWrapper { } {
        return $m_attWrapper
    }

    ### moved from DCSS operation to here because for crystal, parameters
    ### change may trigger matrix changes.
    ### We already have framework to deal with this in GUI.
    public method setToDefaultDefinition { }
    public method updateDefinition { }

    private method getL614Port { {onGrid {}} }
    private method generateParamForUpdate { }
    private method setupDefaultExposure { paramREF }
    private method getDirectoryByOnL614Grid { onGrid }

    public method resetDefinition { } {
        $m_objGridGroupConfig startOperation resetGrid \
        $m_groupId $m_gridId
    }
    public method zoomOnGrid { } {
        set facing "orig"
        set onlyPhi 0
        set zoomOn 1
        $m_objGridGroupConfig startOperation move_to_grid \
        $m_groupId $m_gridId $facing $onlyPhi $zoomOn
    }
    public method hideGrid { } {
        gCurrentGridGroup setGridHide $m_gridId 1
    }
    public method showGrid { } {
        gCurrentGridGroup setGridHide $m_gridId 0
    }
    public method setCellSizeToBeamSize { } {
        if {!$m_ready} {
            return
        }
        set bSize [gCurrentGridGroup getCurrentGridBeamSize]
        if {$bSize == "" || $itk_option(-onNew)} {
            ## this is changing the latest user parameter string.
            set contents [$m_objLatestUserSetup getContents]
            set dd [eval dict create $contents]

            set latestBeamSize [$itk_component(beam_size) getBeamSize]
            foreach {bwMM bhMM color} $latestBeamSize break
            set bw [expr 1000.0 * $bwMM]
            set bh [expr 1000.0 * $bhMM]

            switch -exact -- $m_cellFollowBeamSize {
                2 {
                    dict set dd cell_width  [expr int($bw / 2.0)]
                    dict set dd cell_height [expr int($bh / 2.0)]
                }
                0 -
                1 -
                default {
                    dict set dd cell_width  [expr int($bw)]
                    dict set dd cell_height [expr int($bh)]
                }
            }

            $m_objLatestUserSetup sendContentsToServer $dd
            return
        }
        foreach {bw bh} $bSize break
        switch -exact -- $m_cellFollowBeamSize {
            2 {
                set extraParam [list cell_width [expr $bw / 2.0] \
                cell_height [expr $bh / 2.0]]
            }
            0 -
            1 -
            default {
                set extraParam [list cell_width $bw cell_height $bh]
            }
        }
        if {![gCurrentGridGroup adjustCurrentGrid $extraParam]} {
            log_error cell size must adjust with image display.
        }
    }

    public method updateDoseExposureTime { }
    public method handleDoseModeChange { - ready_ - mode_ - }
    public method handleDoseFactorChange { - ready_ - - - }

    public method setStrategyField { name value } {
        if {!$m_ready} {
            return
        }
        $m_objStrategySoftOnly startOperation set_field $name $value
    }

    private method collectRangeCheck { name valueREF } {
        upvar $valueREF value

        set collectDefault [$m_objDefaultCollectSetup getContents]

        switch -exact -- $name {
            delta {
                ### hardcoded
                set vMin 0.01
                set vMax 179.99
            }
            time {
                set vMin [lindex $collectDefault 3]
                set vMax [lindex $collectDefault 4]
            }
            attenuation {
                set vMin [lindex $collectDefault 5]
                set vMax [lindex $collectDefault 6]
            }
            default {
                return
            }
        }
        if {$vMin > $vMax} {
            set tmp $vMin
            set vMin $vMax
            set vMax $tmp
        }
        if {$value < $vMin} {
            log_warning using $name min value: $vMin
            set value $vMin
        } elseif {$value > $vMax} {
            log_warning using $name max value: $vMax
            set value $vMax
        }
    }

    public method setField { name value } {
        if {!$m_ready} {
            return
        }

        ### remove focus from the field, so that it will not set again.
        #if {$name != "directory"} {
        #    ### directory need dropdown menu
        #    focus $itk_interior
        #}

        #puts "setField $name {$value}"

        #### range check for helical
        switch -exact -- $itk_option(-purpose) {
            forCrystal {
                collectRangeCheck $name value
            }
            forLCLS -
            forGrid -
            forLCLSCrystal -
            forL614 -
            forPXL614 -
            default {
            }
        }

        set param [dict create $name $value]

        if {$name == "position_gap"} {
            ### position_gap is a pseudo field, need to convert to
            ### cell_width

            set beamSizeInfo [$itk_component(beam_size) getBeamSize]
            set beamWidth [lindex $beamSizeInfo 0]
            set bwInU [expr $beamWidth * 1000.0]
            set name cell_width
            set value [expr $value + $bwInU]
            if {$value <= 0.0} {
                log_error bad Position Gap.  It should not overlap more than beam width.
                refreshDisplay
                return
            }
        }

        if {$m_gridId >= 0} {
            switch -exact -- $name {
                item_width -
                item_height -
                cell_width -
                cell_height {
                    #### these need tk GUI to generate new matrix.
                    #### As long as adjustGrid is called, the matrix
                    #### will be reset to default (regenerate).
                    if {![gCurrentGridGroup validCurrentGridInput \
                    $name value]} {
                        refreshDisplay
                        return
                    }
                    set param [dict create $name $value]
                    ### try snapshot GUI first.
                    ### they need to send the whole matrix.
                    if {![gCurrentGridGroup adjustCurrentGrid $param]} {
                        log_error cell size must adjust with image display.

                        refreshDisplay
                        return
                    }
                }
                collimator {
                    #### In crystal, we need both beam size and cell size 
                    #### to calculate number of nodes.
                    #### So, these need GUI help too.
                    #### To do pure math for these is not too complicated.
                    #### They are just lines.
                    #### May change to obj update in dcss in the future.
                    set oldInfo \
                    [gCurrentGridGroup getCurrentGridBeamSizeInfo]
                    set use [lindex $value 0]
                    if {$use == "1"} {
                        foreach {- - bw bh} $value break
                        set bw [expr 1000.0 * $bw]
                        set bh [expr 1000.0 * $bh]
                    } else {
                        foreach {bw bh -} $oldInfo break
                    }
                    set oldCellWidth  [dict get $m_d_userSetup cell_width]
                    set oldCellHeight [dict get $m_d_userSetup cell_height]
                    set extraParam ""

                    switch -exact -- $m_cellFollowBeamSize {
                        1 {
                            dict set extraParam cell_width $bw
                            dict set extraParam cell_height $bh
                        }
                        2 {
                            dict set extraParam cell_width  [expr $bw / 2.0]
                            dict set extraParam cell_height [expr $bh / 2.0]
                        }
                        0 -
                        default {
                            dict set extraParam cell_width $oldCellWidth
                            dict set extraParam cell_height $oldCellHeight
                        }
                    }

                    if {![gCurrentGridGroup adjustCurrentGrid $extraParam \
                    $param]} {
                        log_error beam size must adjust with image display.
                        refreshDisplay
                    }
                }
                beam_width {
                    set oldCellWidth  [dict get $m_d_userSetup cell_width]
                    set extraParam ""
                    switch -exact -- $m_cellFollowBeamSize {
                        1 {
                            set extraParam [list cell_width $value]
                        }
                        2 {
                            set extraParam [list cell_width [expr $value / 2.0]]
                        }
                        0 -
                        default {
                            set extraParam [list cell_width $oldCellWidth]
                        }
                    }
                    if {![gCurrentGridGroup adjustCurrentGrid $extraParam \
                    $param]} {
                        log_error beam size must adjust with image display.
                        refreshDisplay
                    }
                }
                beam_height {
                    set oldCellHeight [dict get $m_d_userSetup cell_height]
                    set extraParam ""
                    switch -exact -- $m_cellFollowBeamSize {
                        1 {
                            set extraParam [list cell_height $value]
                        }
                        2 {
                            set extraParam \
                            [list cell_height [expr $value / 2.0]]
                        }
                        0 -
                        default {
                            set extraParam [list cell_height $oldCellHeight]
                        }
                    }
                    if {![gCurrentGridGroup adjustCurrentGrid $extraParam \
                    $param]} {
                        log_error beam size must adjust with image display.
                        refreshDisplay
                    }
                }
                phi_osc_middle -
                phi_osc_end {
                    #### we use to use flip_phi_node middle/end to do it.
                    $m_objGridGroupConfig startOperation flip_phi_node \
                    $m_groupId $m_gridId 0 [string range $name 8 end]
                }
                phi_osc_all {
                    $m_objGridGroupConfig startOperation set_all_phi_node \
                    $m_groupId $m_gridId $value
                }
                on_l614_grid {
                    set dir [getDirectoryByOnL614Grid $value]
                    dict set param directory $dir
                    $m_objGridGroupConfig startOperation modifyParameter \
                    $m_groupId $m_gridId $param
                }
                default {
                    ### these are done in dcss with class.
                    ### They may be simple change, like detector distance.
                    ### Maybe trigger a group update, including angle of
                    ### node position, like start_angle.
                    ### Maybe even change node selection,
                    ### like strategy_enable, strategy_nodoe.

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

        ##################
        #### update latest_user_raster_setup
        ##################

        set contents [$m_objLatestUserSetup getContents]
        set dd [eval dict create $contents]

        switch -exact -- $name {
            beam_width {
                switch -exact -- $m_cellFollowBeamSize {
                    1 {
                        dict set dd cell_width  [expr int($value)]
                    }
                    2 {
                        dict set dd cell_width  [expr int($value / 2.0)]
                    }
                }
            }
            beam_height {
                switch -exact -- $m_cellFollowBeamSize {
                    1 {
                        dict set dd cell_height [expr int($value)]
                    }
                    2 {
                        dict set dd cell_height [expr int($value / 2.0)]
                    }
                }
            }
            collimator {
                set oldCellWidth  [dict get $m_d_userSetup cell_width]
                set oldCellHeight [dict get $m_d_userSetup cell_height]
                set use [lindex $value 0]
                if {$use == "1"} {
                    foreach {- - bw bh} $value break
                    set bw [expr 1000.0 * $bw]
                    set bh [expr 1000.0 * $bh]
                } else {
                    set bw [dict get $dd beam_width]
                    set bh [dict get $dd beam_height]
                }
                switch -exact -- $m_cellFollowBeamSize {
                    1 {
                        dict set dd cell_width  [expr int($bw)]
                        dict set dd cell_height [expr int($bh)]
                    }
                    2 {
                        dict set dd cell_width  [expr int($bw / 2.0)]
                        dict set dd cell_height [expr int($bh / 2.0)]
                    }
                }
            }
            on_l614_grid {
                set dir [getDirectoryByOnL614Grid $value]
                dict set dd directory $dir
            }
        }

        dict set dd $name $value
        $m_objLatestUserSetup sendContentsToServer $dd
    }

    public method handleGridUpdate { - ready_ - contents_ - }
    public method handlePhiNodeListUpdate { - ready_ - contents_ - }

    public method getCurrentViewStyle { } { return $m_currentView }
    public method getIsCrystal { } {
        switch -exact -- $m_currentView {
            forCrystal -
            forLCLSCrystal {
                return 1
            }
        }
        return 0
    }
    public method getOnNew { } {
        return $itk_option(-onNew)
    }

    public method updateShowResolution { } {
        if {$gCheckButtonVar($this,showRes)} {
            pack $itk_component(resolution) \
            -before $itk_component(distanceFrame)
        } else {
            pack forget $itk_component(resolution)
        }
    }

    public method moveGrid { dir } {
        if {!$m_ready} {
            return
        }
        if {$m_gridId < 0} {
            return
        }
        set stepSize [lindex [$itk_component(moveStep) get] 0]
        switch -exact -- $dir {
            left {
                set horz [expr -1 * $stepSize]
                set vert 0
            }
            right {
                set horz $stepSize
                set vert 0
            }
            up {
                set horz 0
                set vert [expr -1 * $stepSize]
            }
            down {
                set horz 0
                set vert $stepSize
            }
            default {
                return
            }
        }
        if {[getIsCrystal]} {
            set param [dict create \
            move_crystal [list $horz $vert] \
            ]
            if {![gCurrentGridGroup adjustCurrentGrid $param]} {
                log_error moving crystal must be done with image display.
            }
            return
        }
        $m_objGridGroupConfig startOperation moveGrid \
        $m_groupId $m_gridId $horz $vert
    }

    private method refreshGrid { }

    private method refreshDisplay { }

    private method refreshHideShowDisplay { hide }

    private method switchView { type }

    private method repackExposureTime { }

    private common COMPONENT2KEY [list \
    fileRoot     prefix \
    directory    directory \
    shape        shape \
    beam_size    {beam_width beam_height collimator} \
    cell_size    {cell_width cell_height} \
    item_size    {item_width item_height} \
    step_size    cell_width \
    exposureTime time \
    delta        delta \
    distance     distance \
    beamStop     beam_stop \
    attenuation  attenuation \
    processing   processing \
    firstStill   first_single_shot \
    secondStill  second_single_shot \
    secondReverse  second_single_reverse_beam \
    firstAtt     first_attenuation \
    phiOsc       phi_osc \
    numPhiShot   num_phi_shot \
    endStill     end_single_shot \
    endAtt       end_attenuation \
    videoShot    video_snapshot \
    allowPhiOffset use_phi_offset \
    phiOffset      phi_offset \
    numColumn      num_column \
    startFrame     start_frame \
    startAngle     start_angle \
    endFrame       end_frame \
    endAngle       end_angle \
    nodeFrame      node_frame \
    nodeAngle      node_angle \
    inverseOn      inverse_beam \
    wedgeSize      wedge_size \
    energyList     energy_list \
    lclsNodeAngle  node_angle \
    lclsStartAngle start_angle \
    lclsEndAngle   end_angle \
    stillAtt          first_attenuation \
    phiOscMiddle      phi_osc_middle \
    phiOscEnd         phi_osc_end \
    phiOscAll         phi_osc_all \
    onGrid            on_l614_grid \
    detectorMode      mode \
    ]

    private variable m_ready 0
    private variable m_objCollectGrid ""
    private variable m_objGridGroupConfig ""
    private variable m_objLatestUserSetup ""
    private variable m_objDefaultUserSetup ""
    private variable m_objDefaultCollectSetup ""
    private variable m_objPhi ""
    private variable m_objEnergy ""
    private variable m_objCrystalStatus ""
    private variable m_objScreeningParameters ""
    private variable m_objCurrentL614Node ""
    private variable m_groupId -1
    private variable m_snapId -1
    private variable m_gridId -1
    private variable m_d_userSetup ""

    private variable m_origGridContents ""

    ### for dose mode
    private variable m_objRuns ""
    private variable m_doseMode 0

    private variable m_strInput ""
    private variable m_objStrategySoftOnly ""

    ### to dynamically switch display
    ### forGrid, forCrystal or forL614
    protected variable m_currentView unknown

    private variable m_origBG ""
    private variable m_origFG ""
    private variable m_origABG ""
    private variable m_origAFG ""

    private variable m_cellFollowBeamSize 1

    private variable m_attWrapper ""

    private common PADY 2

    private common PROMPT_WIDTH 15

    private common gCheckButtonVar

    constructor { args} {
        ::DCS::Component::constructor {
            current_view_style getCurrentViewStyle
            is_crystal         getIsCrystal
            on_new             getOnNew
        }
    } {
        global gMotorDistance
        global gMotorBeamStop
        global gMotorEnergy
        global gMotorPhi
        global gMotorBeamWidth
        global gMotorBeamHeight
        global gMotorHorz
        global gMotorVert

        set gCheckButtonVar($this,showRes) 0

        set m_attWrapper [CurrentGridAttributeWrapper ::\#auto]
        $m_attWrapper setup gCurrentGridGroup $this

        set deviceFactory [::DCS::DeviceFactory::getObject]

        set m_objCollectGrid [$deviceFactory createOperation collectGrid]

        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        set m_objLatestUserSetup \
        [$deviceFactory createString latest_raster_user_setup]

        set m_objDefaultUserSetup \
        [$deviceFactory createString default_raster_user_setup]

        set m_objDefaultCollectSetup \
        [$deviceFactory createString collect_default]

        set m_objPhi    [$deviceFactory getObjectName $gMotorPhi]
        set m_objEnergy [$deviceFactory getObjectName energy]

        set m_objCrystalStatus [$deviceFactory createString crystalStatus]

        set m_objScreeningParameters \
        [$deviceFactory createString screeningParameters]

        set m_objCurrentL614Node \
        [$deviceFactory createString currentL614Node]

        set m_objRuns [$deviceFactory createString runs]

        set m_strInput [$deviceFactory createString multiStrategy_input]
        $m_strInput createAttributeFromKey space_group
        $m_strInput createAttributeFromKey phi_range

        set m_objStrategySoftOnly \
        [$deviceFactory createOperation multiCrystalStrategySoftOnly]


        set ring $itk_interior
        label $ring.dummy0
        label $ring.dummy1
        label $ring.dummy2
        label $ring.dummy3

        itk_component add labelFirstNode {
            label $ring.firstNode \
            -text "=======================First Node========================"
        } {
            keep -font
        }

        itk_component add labelOtherNode {
            label $ring.otherNode \
            -text "=======================Other Node========================"
        } {
            keep -font
        }

        itk_component add labelPhiOsc {
            label $ring.phi_osc \
            -text "======================Phi Oscillation===================="
        } {
            keep -font
        }

        itk_component add labelLast {
            label $ring.last_do \
            -text "---------Collect Phi Osc After Data Collecting-------------------"
        } {
            keep -font
        }

        itk_component add labelEachPosition {
            label $ring.each_position \
            -text "---------------------Each Position-----------------------"
        } {
            keep -font
        }

        itk_component add summary {
            label $ring.s
        } {
            keep -font
        }

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
            keep -font
        }
        
        itk_component add updateButton {
            DCS::Button $buttonSite.u \
            -text "Update" \
            -width 5 \
            -pady 0 \
            -command "$this updateDefinition" 
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        
        itk_component add deleteButton {
            DCS::Button $buttonSite.del \
            -text "Delete" \
            -width 5 \
            -pady 0 \
            -command "$this deleteThisRun"
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add copyButton {
            DCS::Button $buttonSite.cpy \
            -text "Copy" \
            -width 3 \
            -pady 0 \
            -command "$this copyThisItem"
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        
        itk_component add resetButton {
            DCS::Button $buttonSite.r -text "Reset" \
            -width 4 \
            -pady 0 \
            -command "$this resetDefinition" 
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add hideButton {
            button $buttonSite.hide \
            -pady 0 \
            -text "Hide" \
            -width 3 \
            -command "$this hideGrid"
        } {
            keep -font
        }
        itk_component add showButton {
            button $buttonSite.show \
            -pady 0 \
            -background green \
            -text "Show" \
            -width 3 \
            -command "$this showGrid"
        } {
            keep -font
        }
        itk_component add zoomButton {
            DCS::Button $buttonSite.zoom \
            -pady 0 \
            -text "zoom" \
            -command "$this zoomOnGrid"
        } {
            keep -font
        }

        pack $itk_component(defaultButton) -side left -padx 1
        pack $itk_component(updateButton) -side left -padx 1
        pack $itk_component(deleteButton) -side left -padx 1
        pack $itk_component(copyButton) -side left -padx 1
        pack $itk_component(resetButton) -side left -padx 1
        pack $itk_component(zoomButton) -side left -padx 1

        $itk_component(defaultButton) addInput \
        "$m_attWrapper current_grid_editable 1 {reset first}"

        $itk_component(updateButton) addInput \
        "$m_attWrapper current_grid_editable 1 {reset first}"

        $itk_component(deleteButton) addInput \
        "$m_attWrapper current_grid_deletable 1 {try reset first}"

        $itk_component(resetButton) addInput \
        "$m_attWrapper current_grid_resettable 1 {cannot reset}"

        itk_component add fileRoot {
            DCS::Entry $ring.fileroot \
            -leaveSubmit 1 \
            -entryType field \
            -entryWidth 30 \
            -entryJustify left \
            -entryMaxLength 128 \
            -promptText "Prefix: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 0 \
            -onSubmit "$this setField prefix %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add dirFrame {
            frame $ring.dirF
        } {
        }

        set dirSite $itk_component(dirFrame)

        itk_component add directory {
            DCS::Entry $dirSite.dir \
            -leaveSubmit 1 \
            -entryType rootDirectory \
            -entryWidth 30 \
            -entryJustify left \
            -entryMaxLength 128 \
            -promptText "Dir: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 0 \
            -onSubmit "$this setField directory %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add onGrid {
            DCS::Checkbutton $dirSite.onGrid \
            -text "On Grid" \
            -shadowReference 0 \
            -command "$this setField on_l614_grid %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        pack $itk_component(directory) -side left -anchor w

        itk_component add shape {
            DCS::MenuEntry $ring.shape \
            -promptText "Shape: " \
            -promptWidth $PROMPT_WIDTH \
            -state labeled \
            -menuChoices [list rectangle oval line polygon l614 trap_array mesh] \
            -onSubmit "$this setField shape %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add cellSizeFrame {
            frame $ring.csizeF
        } {
        }
        set cellSite $itk_component(cellSizeFrame)

        itk_component add cell_size {
            CellSize $cellSite.cellSize \
            -promptText "Step Size: " \
            -promptWidth $PROMPT_WIDTH \
            -onWidthSubmit "$this setField cell_width %s" \
            -onHeightSubmit "$this setField cell_height %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add csize_to_bsize {
            DCS::Button $cellSite.setcell \
            -text "To Beam Size" \
            -command "$this setCellSizeToBeamSize"
        } {
            keep -font
        }
        set m_origBG [$itk_component(csize_to_bsize) cget -background]
        set m_origFG [$itk_component(csize_to_bsize) cget -foreground]
        set m_origABG [$itk_component(csize_to_bsize) cget -activebackground]
        set m_origAFG [$itk_component(csize_to_bsize) cget -activeforeground]

        pack $itk_component(cell_size) -anchor w -side left
        pack $itk_component(csize_to_bsize) -anchor w -side left

        itk_component add gap {
            ::DCS::MenuEntry $ring.gap \
            -promptText "Position Gap:" \
            -promptWidth $PROMPT_WIDTH \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -menuChoices {-10 0 10 20 50 100 150 200} \
            -entryType float \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 1 \
            -autoConversion 1 \
            -escapeToDefault 0 \
            -onSubmit "$this setField position_gap %s"
        } {
            keep -font
        }

        itk_component add stepSizeFrame {
            frame $ring.stepSizeF
        } {
        }
        set stepSite $itk_component(stepSizeFrame)
        itk_component add step_size {
            ::DCS::MenuEntry $stepSite.step \
            -promptText "Step Size:" \
            -promptWidth $PROMPT_WIDTH \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -menuChoices {10 20 25 30 40 50 100 150 200} \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 1 \
            -autoConversion 1 \
            -escapeToDefault 0 \
            -onSubmit "$this setField cell_width %s"
        } {
            keep -font
        }
        itk_component add step_to_bsize {
            DCS::Button $stepSite.setcell \
            -text "To Beam Width" \
            -command "$this setCellSizeToBeamSize"
        } {
            keep -font
        }
        pack $itk_component(step_size) -anchor w -side left
        pack $itk_component(step_to_bsize) -anchor w -side left

        itk_component add item_size {
            CellSize $ring.itemSize \
            -promptText "Shape Size: " \
            -promptWidth $PROMPT_WIDTH \
            -onWidthSubmit "$this setField item_width %s" \
            -onHeightSubmit "$this setField item_height %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add beam_size {
            BeamSizeParameter $ring.beamSize \
            -alterUpdateSubmit 0 \
            -promptText "Beam Size: " \
            -promptWidth $PROMPT_WIDTH \
            -onWidthSubmit "$this setField beam_width %s" \
            -onHeightSubmit "$this setField beam_height %s" \
            -onCollimatorSubmit "$this setField collimator {%s}" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add moveGridFrame {
            frame $ring.moveF
        } {
        }
        set moveSite $itk_component(moveGridFrame)
        itk_component add moveLabel {
            label $moveSite.label \
            -text "Positioning: "\
            -width $PROMPT_WIDTH \
            -anchor e \
        } {
            keep -font
        }
        pack $itk_component(moveLabel) -side left
        itk_component add moveStep {
            ::DCS::MenuEntry $moveSite.padStep \
            -leaveSubmit 1 \
	        -decimalPlaces 1 \
            -menuChoices {1 2 5 10 20 25 30 40 50 100 200 500 1000 2000} \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 1 \
        } {
            keep -font
        }
        $itk_component(moveStep) setValue 10.0
        pack $itk_component(moveStep) -side left
        foreach dir {left right up down} {
            itk_component add button_$dir {
                DCS::ArrowButton $moveSite.$dir $dir \
			    -debounceTime 100  \
                -background #c0c0ff \
                -command "$this moveGrid $dir"
            } {
                keep -font
            }
            pack $itk_component(button_$dir) -side left
        }

        itk_component add timeFrame {
            frame $ring.timeF
        } {
        }
        set timeSite $itk_component(timeFrame)

        itk_component add exposureTime {
            DCS::Entry $timeSite.time \
            -leaveSubmit 1 \
            -promptText "Time: " \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -units "s" \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -onSubmit "$this setField time %s" \
            -onChange "$this updateDoseExposureTime" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add multiply {
            label $timeSite.m \
            -text "*"
        } {
            keep -font
        }
        itk_component add doseFactor {
            label $timeSite.df \
            -text "dose factor"
        } {
            keep -font
        }
        itk_component add equals {
            label $timeSite.eq \
            -text "="
        } {
            keep -font
        }
        itk_component add doseExposureTime {
            label $timeSite.dt \
            -text "time"
        } {
            keep -font
        }
        pack $itk_component(exposureTime) \
        -padx 5 -pady $PADY -anchor w -side left
        
        itk_component add delta {
            DCS::Entry $ring.delta \
            -promptText "Delta: " \
            -leaveSubmit 1 \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -shadowReference 0 \
            -onSubmit "$this setField delta %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add detectorMode {
            DCS::DetectorModeMenu $ring.detector_mode \
            -entryWidth 19 \
            -promptText "Detector: " \
            -promptWidth $PROMPT_WIDTH \
            -showEntry 0 \
            -entryType string \
            -entryJustify center \
            -promptText "Detector: " \
            -shadowReference 0 \
            -onSubmit "$this setField mode %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add distanceFrame {
            frame $ring.distanceF \
        } {
        }
        set distanceSite $itk_component(distanceFrame)

        itk_component add distance {
            DCS::MotorViewEntry $distanceSite.distance \
            -checkLimits -1 \
            -menuChoiceDelta 50 \
            -device ::device::$gMotorDistance \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Distance: " \
            -promptWidth $PROMPT_WIDTH \
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
            keep -font
        }

        itk_component add showResolution {
            checkbutton $distanceSite.showRes \
            -variable [scope gCheckButtonVar($this,showRes)] \
            -text "Show Resolution" \
            -command "$this updateShowResolution" \
        } {
        }
        pack $itk_component(distance) -side left
        pack $itk_component(showResolution) -side left

        itk_component add beamStop {
            DCS::MotorViewEntry $ring.beamStop \
            -checkLimits -1 \
            -menuChoiceDelta 5 \
            -device ::device::$gMotorBeamStop \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Beam Stop: " \
            -promptWidth $PROMPT_WIDTH \
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
            keep -font
        }

        itk_component add attenuation {
            DCS::MotorViewEntry $ring.attenuation \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Attenuation: " \
            -promptWidth $PROMPT_WIDTH \
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
            keep -font
        }

        itk_component add processing {
            DCS::CheckbuttonRight $ring.processing \
            -text "Processing: " \
            -width $PROMPT_WIDTH \
            -shadowReference 0 \
            -command "$this setField processing %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add phiOffsetFrame {
            frame $ring.phiOffsetF
        } {
        }
        set phiOffsetSite $itk_component(phiOffsetFrame)


        itk_component add allowPhiOffset {
            DCS::CheckbuttonRight $phiOffsetSite.enable \
            -text "Phi Offset:" \
            -width $PROMPT_WIDTH \
            -shadowReference 0 \
            -command "$this setField use_phi_offset %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add phiOffset {
            DCS::MotorViewEntry $phiOffsetSite.value \
            -checkLimits 0 \
            -menuChoiceDelta 10 \
            -showPrompt 0 \
            -leaveSubmit 1 \
            -entryWidth 10 \
            -units "deg" \
            -unitsList "deg" \
            -entryType float \
            -entryJustify right \
            -escapeToDefault 0 \
            -shadowReference 0 \
            -autoConversion 1 \
            -onSubmit "$this setField phi_offset %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        grid $itk_component(allowPhiOffset) -row 0 -column 0 -sticky w
        grid $itk_component(phiOffset) -row 0 -column 1 -sticky w
        grid columnconfigure $phiOffsetSite 1 -weight 10

        itk_component add videoShot {
            DCS::CheckbuttonRight $ring.videoShot \
            -text "Video Shot:" \
            -width $PROMPT_WIDTH \
            -shadowReference 0 \
            -command "$this setField video_snapshot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add firstFrame {
            frame $ring.firstF
        } {
        }
        set firstSite $itk_component(firstFrame)

        itk_component add firstStill {
            DCS::CheckbuttonRight $firstSite.firstStill \
            -text "First Still: " \
            -width $PROMPT_WIDTH \
            -shadowReference 0 \
            -command "$this setField first_single_shot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add secondStill {
            DCS::CheckbuttonRight $firstSite.secondStill \
            -text "Second Still: " \
            -width $PROMPT_WIDTH \
            -shadowReference 0 \
            -command "$this setField second_single_shot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add secondReverse {
            DCS::Checkbutton $firstSite.secondReverse \
            -text "Reverse Beam" \
            -shadowReference 0 \
            -command "$this setField second_single_reverse_beam %s" \
            -onBackground yellow \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add firstAtt {
            DCS::MotorViewEntry $firstSite.attenuation \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText " Attenuation:" \
            -entryWidth 7 \
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
            keep -font
        }

        grid $itk_component(firstStill)  -row 0 -column 0 -sticky w
        grid $itk_component(firstAtt)    -row 0 -column 1 -sticky w
        grid $itk_component(secondStill) -row 1 -column 0 -sticky w
        grid $itk_component(secondReverse) -row 1 -column 1 -sticky w
        grid columnconfigure $firstSite 1 -weight 10

        itk_component add endSingleFrame {
            frame $ring.endSingleF
        } {
        }
        set endSite $itk_component(endSingleFrame)

        itk_component add endStill {
            DCS::CheckbuttonRight $endSite.endStill \
            -text "Last Still: " \
            -width $PROMPT_WIDTH \
            -shadowReference 0 \
            -command "$this setField end_single_shot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add endAtt {
            DCS::MotorViewEntry $endSite.end_attenuation \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText " Attenuation:" \
            -entryWidth 7 \
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
            keep -font
        }
        pack $itk_component(endStill) $itk_component(endAtt) -side left

        itk_component add numColumn {
            DCS::Entry $ring.numColumn \
            -state labeled \
            -promptText "Num Position: " \
            -leaveSubmit 1 \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -entryType positiveInt \
            -entryJustify right \
            -shadowReference 0 \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add phiFrame {
            frame $ring.phiF
        }
        set phiSite $itk_component(phiFrame)

        itk_component add phiOsc {
            DCS::CheckbuttonRight $phiSite.enable \
            -text "Phi Oscillation: " \
            -width $PROMPT_WIDTH \
            -shadowReference 0 \
            -command "$this setField phi_osc %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add numPhiShot {
            DCS::Entry $phiSite.numPhiShot \
            -promptText "Num Phi Shot: " \
            -leaveSubmit 1 \
            -entryWidth 2 \
            -entryType positiveInt \
            -entryJustify right \
            -shadowReference 0 \
            -onSubmit "$this setField num_phi_shot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        pack $itk_component(phiOsc) $itk_component(numPhiShot) -side left

        itk_component add exposureFrame {
            frame $ring.exposureFrame
        } {
        }
        set expSite $itk_component(exposureFrame)

        itk_component add frameHeader {
            label $expSite.ff -text "Frame" -anchor e
        } {
            keep -font
        }
        
        itk_component add angleHeader {
            label $expSite.fa -text "Phi" -anchor e
        } {
            keep -font
        }

        itk_component add startFrame {
            DCS::Entry $expSite.sf \
                 -leaveSubmit 1 \
                 -promptText "Start: " \
                 -promptWidth $PROMPT_WIDTH \
                 -entryWidth 6     \
                 -entryType positiveInt \
                 -entryJustify right \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -onSubmit "$this setField start_frame %s" \
        } {
            keep -font
        }
    
        itk_component add startAngle {
            DCS::Entry $expSite.sa \
                 -leaveSubmit 1 \
                 -entryWidth 9 \
                 -entryType float \
                 -entryJustify right \
                 -units "deg" -unitsList "deg" \
                 -unitsWidth 4 \
                 -shadowReference 0 \
                 -decimalPlaces 2 \
                 -reference "::device::$gMotorPhi scaledPosition" \
                 -escapeToDefault 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -autoConversion 1 \
                 -onSubmit "$this setField start_angle %s" \
        } {
            keep -font
        }

        itk_component add endFrame {
            DCS::Entry $expSite.ef \
                 -leaveSubmit 1 \
                 -promptText "End: " \
                 -promptWidth $PROMPT_WIDTH \
                 -entryWidth 6     \
                 -entryType positiveInt \
                 -entryJustify right \
                 -decimalPlaces 2 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -onSubmit "$this setField end_frame %s" \
        } {
            keep -font
        }
        
        itk_component add endAngle {
            DCS::Entry $expSite.ea \
                 -leaveSubmit 1 \
                 -shadowReference 0 \
                 -entryWidth 9 \
                 -entryType float \
                 -entryJustify right \
                 -units "deg" -unitsList "deg" \
                 -unitsWidth 4 \
                 -shadowReference 0 \
                 -decimalPlaces 2 \
                 -reference "::device::$gMotorPhi scaledPosition" \
                 -escapeToDefault 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -autoConversion 1 \
                 -onSubmit "$this setField end_angle %s" \
        } {
            keep -font
        }

        itk_component add nodeFrame {
            DCS::Entry $expSite.nf \
                 -promptText "Each Position:" \
                 -promptWidth $PROMPT_WIDTH \
                 -entryWidth 6     \
                 -entryType positiveInt \
                 -entryJustify right \
                 -decimalPlaces 2 \
                 -onSubmit "$this setField node_frame %s" \
        } {
            keep -font
        }
        
        itk_component add nodeAngle {
            DCS::Entry $expSite.na \
            -entryWidth 9 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" -unitsList "deg" \
            -shadowReference 0 \
            -onSubmit "$this setField node_angle %s" \
        } {
            keep -font
        }
        grid $itk_component(frameHeader) -column 0 -row 0 -sticky e
        grid $itk_component(angleHeader) -column 1 -row 0

        grid $itk_component(startFrame)  -column 0 -row 1
        grid $itk_component(startAngle)  -column 1 -row 1

        grid $itk_component(endFrame)  -column 0 -row 2
        grid $itk_component(endAngle)  -column 1 -row 2

        grid $itk_component(nodeFrame)  -column 0 -row 3
        grid $itk_component(nodeAngle)  -column 1 -row 3

        itk_component add lclsExposureFrame {
            frame $ring.lclsexposureFrame
        } {
        }
        set lclsSite $itk_component(lclsExposureFrame)
        itk_component add lclsAngleHeader {
            label $lclsSite.fa \
            -text "Phi" -anchor w \
            -width $PROMPT_WIDTH \
        } {
            keep -font
        }
        itk_component add lclsStartAngle {
            DCS::Entry $lclsSite.sa \
                 -promptText "Start: " \
                 -promptWidth $PROMPT_WIDTH \
                 -leaveSubmit 1 \
                 -entryWidth 9 \
                 -entryType float \
                 -entryJustify right \
                 -units "deg" -unitsList "deg" \
                 -unitsWidth 4 \
                 -shadowReference 0 \
                 -decimalPlaces 2 \
                 -reference "::device::$gMotorPhi scaledPosition" \
                 -escapeToDefault 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -autoConversion 1 \
                 -onSubmit "$this setField start_angle %s" \
        } {
            keep -font
        }
        itk_component add lclsEndAngle {
            DCS::Entry $lclsSite.ea \
                 -leaveSubmit 1 \
                 -promptText "End: " \
                 -promptWidth $PROMPT_WIDTH \
                 -shadowReference 0 \
                 -entryWidth 9 \
                 -entryType float \
                 -entryJustify right \
                 -units "deg" -unitsList "deg" \
                 -unitsWidth 4 \
                 -shadowReference 0 \
                 -decimalPlaces 2 \
                 -reference "::device::$gMotorPhi scaledPosition" \
                 -escapeToDefault 0 \
                 -systemIdleOnly 0 \
                 -activeClientOnly 1 \
                 -autoConversion 1 \
                 -onSubmit "$this setField end_angle %s" \
        } {
            keep -font
        }

        itk_component add lclsNodeAngle {
            DCS::Entry $lclsSite.lclsna \
            -leaveSubmit 1 \
            -promptText "Step Size: " \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 9 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" -unitsList "deg" \
            -unitsWidth 4 \
            -shadowReference 0 \
            -onSubmit "$this setField node_angle %s" \
        } {
            keep -font
        }
        grid $itk_component(lclsAngleHeader) -column 0 -row 0 -sticky e
        grid $itk_component(lclsNodeAngle)   -column 0 -row 1
        grid $itk_component(lclsStartAngle)  -column 0 -row 2
        grid $itk_component(lclsEndAngle)    -column 0 -row 3

        itk_component add inverseOn {
            DCS::CheckbuttonRight $ring.inverseOn \
            -text "Inverse Beam:" \
            -width $PROMPT_WIDTH \
            -shadowReference 0 \
            -command "$this setField inverse_beam %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add wedgeSize {
            DCS::MenuEntry $ring.wedgeSize \
            -promptText "Wedge: " \
            -leaveSubmit 1 \
            -promptWidth $PROMPT_WIDTH \
            -showEntry 1 \
            -entryWidth 11 \
            -entryType positiveFloat \
            -menuChoices {30.0 45.0 60.0 90.0 180.0} \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -shadowReference 0 \
            -onSubmit "$this setField wedge_size %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add energyList {
            DynamicEnergyListView $ring.energyList \
            -onSubmit "$this setField energy_list {%s}"
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add startPhiOsc {
            DCS::Button $ring.startPhiOsc \
            -text "Start Collect Phi Oscillation" \
            -command "$this startPhiOsc"
        } {
            keep -font
        }
        $itk_component(startPhiOsc) addInput \
        "::gCurrentGridGroup current_grid_phi_osc_runnable 1 {no need}"

        itk_component add stillAtt {
            DCS::MotorViewEntry $ring.stillAtt \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Attenuation: " \
            -promptWidth $PROMPT_WIDTH \
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
            keep -font
        }

        itk_component add phiOscSelectionFrame {
            frame $ring.phiOscSelectionFrame
        } {
        }

        itk_component add labelOnPosition {
            label $ring.phiOscSelectionFrame.ll \
            -text "on Position:" \
        } {
            keep -font
        }

        set phiOscSelSite [frame $ring.phiOscSelectionFrame.buttonF]

        itk_component add phiOscMiddle {
            DCS::Checkbutton $phiOscSelSite.phiOscMiddle \
            -text "Middle" \
            -shadowReference 0 \
            -command "$this setField phi_osc_middle %s" \
            -systemIdleOnly 0 \
        } {
            keep -activeClientOnly
            keep -font
        }
        itk_component add phiOscEnd {
            DCS::Checkbutton $phiOscSelSite.phiOscEnd \
            -text "End" \
            -shadowReference 0 \
            -command "$this setField phi_osc_end %s" \
            -systemIdleOnly 0 \
        } {
            keep -activeClientOnly
            keep -font
        }
        itk_component add phiOscAll {
            DCS::Checkbutton $phiOscSelSite.phiOscAll \
            -text "All" \
            -shadowReference 0 \
            -command "$this setField phi_osc_all %s" \
            -systemIdleOnly 0 \
        } {
            keep -activeClientOnly
            keep -font
        }

        grid $itk_component(phiOscAll) \
        $itk_component(phiOscMiddle) \
        $itk_component(phiOscEnd)

        grid columnconfigure $phiOscSelSite 1 -weight 10

        pack $ring.phiOscSelectionFrame.ll -side left

        pack $phiOscSelSite -side left -fill x -expand 1

        itk_component add phiNodeList {
            DCS::Entry $ring.phiNodeList \
            -state labeled \
            -promptText "Position List: " \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 30 \
            -entryJustify left \
            -entryMaxLength 1024 \
            -entryType string \
            -shadowReference 0 \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add resolution {
            DCS::ResolutionWidget $ring.resolution \
            -detectorBackground #c0c0ff \
            -detectorForeground white \
            -detectorXWidget ::device::$gMotorHorz \
            -detectorYWidget ::device::$gMotorVert \
            -detectorZWidget $itk_component(distance) \
            -beamstopZWidget $itk_component(beamStop) \
            -externalModeWidget $itk_component(detectorMode) \
        } {
        }

        eval itk_initialize $args

        foreach {name -} $COMPONENT2KEY {
            switch -exact -- $name {
                phiOscMiddle -
                phiOscEnd -
                phiOscAll -
                allowPhiOffset -
                phiOffset {
                    ## allow change without reset
                    continue
                }
            }
            $itk_component($name) addInput \
            "$m_attWrapper current_grid_editable 1 {reset first}"
        }

        foreach name {csize_to_bsize step_to_bsize \
        button_left button_right button_up button_down} {
            $itk_component($name) addInput \
            "$m_attWrapper current_grid_editable 1 {reset first}"
        }

        exportSubComponent instant_beam_size ::$itk_component(beam_size)

        announceExist

        gCurrentGridGroup register $this current_grid handleGridUpdate
        gCurrentGridGroup register $this \
        current_crystal_phi_node_list_for_display handlePhiNodeListUpdate

        ::mediator register $this $m_objRuns doseMode handleDoseModeChange

        ::mediator register $this [DCS::DoseFactor::getObject] doseFactor \
        handleDoseFactorChange

        $itk_component(deleteButton) addInput \
        "$this on_new 0 {this is default}"

        $itk_component(copyButton) addInput \
        "$this on_new 0 {this is default}"

        $itk_component(resetButton) addInput \
        "$this on_new 0 {this is default}"

        $itk_component(zoomButton) addInput \
        "$this on_new 0 {this is default}"
    }
    destructor {
        gCurrentGridGroup unregister $this \
        current_crystal_phi_node_list_for_display handlePhiNodeListUpdate

        gCurrentGridGroup unregister $this current_grid handleGridUpdate

        ::mediator announceDestruction $this
    }
}
body GridInputView::switchView { type } {
    puts "switchView $type"

    if {$m_currentView == $type} {
        updateRegisteredComponents current_view_style
        updateRegisteredComponents is_crystal
        return
    }

    set all [pack slaves $itk_interior]
    if {$all != ""} {
        eval pack forget $all
    }

    switch -exact -- $type {
        forL614 {
            set ring $itk_interior

            pack $itk_component(summary) -pady $PADY 
            pack $itk_component(buttonsFrame) -pady $PADY
            pack $itk_component(shape) -pady $PADY -padx 5 -anchor w
            pack $itk_component(fileRoot) -pady $PADY -padx 5 -anchor w
            pack $itk_component(dirFrame) -pady $PADY -padx 5  -anchor w
            pack forget $itk_component(onGrid)
            pack $itk_component(distanceFrame) -padx 5 -pady $PADY -anchor w

            pack $ring.dummy0
            pack $itk_component(phiOffsetFrame)  -padx 5 -pady $PADY -anchor w
            pack $itk_component(videoShot)  -padx 5 -pady $PADY -anchor w

            grid $itk_component(firstStill)
            grid $itk_component(firstAtt)
            grid $itk_component(secondStill)
            grid $itk_component(secondReverse)
            pack $itk_component(firstFrame) -padx 5  -pady $PADY -anchor w

            pack $itk_component(phiOsc) -side left -before $itk_component(numPhiShot)
            pack $itk_component(phiFrame) -padx 5 -pady $PADY -anchor w

            pack $itk_component(attenuation) -padx 5 -pady $PADY -anchor w
            pack $itk_component(timeFrame) -pady $PADY -anchor w
            pack $itk_component(delta) -padx 5 -pady $PADY -anchor w
            pack $itk_component(endSingleFrame) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(processing) -padx 5 -pady $PADY -anchor w
        }
        forCrystal {
            set includeStill [::config getInt helicalIncludeStill 0]
            pack $itk_component(summary) -pady $PADY 
            pack $itk_component(buttonsFrame) -pady $PADY
            pack $itk_component(fileRoot) -pady $PADY -padx 5 -anchor w
            pack $itk_component(dirFrame) -pady $PADY -padx 5  -anchor w
            pack forget $itk_component(onGrid)
            pack $itk_component(beam_size) -padx 5 -pady $PADY -anchor w

            ### pick one of following
            pack $itk_component(stepSizeFrame) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(gap) -padx 5 -pady $PADY -anchor w

            #pack $itk_component(moveGridFrame) -padx 5 -pady $PADY -anchor w

            pack $itk_component(detectorMode) -padx 5 -pady $PADY -anchor w
            pack $itk_component(distanceFrame) -padx 5 -pady $PADY -anchor w
            pack $itk_component(beamStop) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(resolution) -padx 5 -pady $PADY
            pack $itk_component(attenuation) -padx 5 -pady $PADY -anchor w
            pack $itk_component(timeFrame) -pady $PADY -anchor w
            pack $itk_component(delta) -padx 5 -pady $PADY -anchor w

            pack $itk_component(numColumn) -padx 5 -pady $PADY -anchor w
            pack $itk_component(exposureFrame) -padx 5 -anchor w

            pack $itk_component(inverseOn) -padx 5 -pady $PADY -anchor w
            pack $itk_component(wedgeSize) -padx 5 -pady $PADY -anchor w
            pack $itk_component(energyList) -padx 5 -anchor w
            if {$includeStill} {
                grid $itk_component(firstStill)
                grid $itk_component(firstAtt)
                grid remove $itk_component(secondStill)
                grid remove $itk_component(secondReverse)
                pack $itk_component(firstFrame) -padx 5  -pady $PADY -anchor w
            }
        }
        forLCLSCrystal {
            set ring $itk_interior

            pack $itk_component(summary) -pady $PADY 
            pack $itk_component(buttonsFrame) -pady $PADY
            pack $itk_component(fileRoot) -pady $PADY -padx 5 -anchor w
            pack $itk_component(dirFrame) -pady $PADY -padx 5  -anchor w
            pack $itk_component(onGrid) -side left
            pack $itk_component(distanceFrame) -padx 5 -pady $PADY -anchor w
            pack $itk_component(stillAtt) -padx 5 -pady $PADY -anchor w
            grid remove $itk_component(firstStill)
            grid remove $itk_component(firstAtt)
            grid  $itk_component(secondStill)
            grid  remove $itk_component(secondReverse)
            pack $itk_component(firstFrame) -padx 5  -pady $PADY -anchor w

            #$itk_component(beam_size) configure -state labeled
            pack $itk_component(beam_size) -padx 5 -pady $PADY -anchor w

            ### pick one of following
            pack $itk_component(stepSizeFrame) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(gap) -padx 5 -pady $PADY -anchor w

            #pack $itk_component(moveGridFrame) -padx 5 -pady $PADY -anchor w

            pack $itk_component(numColumn) -padx 5 -pady $PADY -anchor w
            pack $itk_component(lclsExposureFrame) -padx 5 -anchor w
            #pack $itk_component(processing) -padx 5 -pady $PADY -anchor w

            pack $ring.dummy1
            pack $ring.phi_osc -anchor w
            pack $ring.last_do -anchor w
            pack $itk_component(phiOscSelectionFrame) -padx 5 -pady $PADY -anchor w
            pack $itk_component(phiNodeList) -padx 5 -pady $PADY -anchor w
            pack $ring.each_position -anchor w

            pack forget $itk_component(phiOsc)
            $itk_component(numPhiShot) configure \
            -promptWidth $PROMPT_WIDTH
            pack $itk_component(phiFrame) \
            -side top \
            -padx 5 \
            -pady $PADY \
            -anchor w

            pack $itk_component(attenuation) -padx 5 -pady $PADY -anchor w
            pack $itk_component(timeFrame) \
            -side top \
            -pady $PADY -anchor w

            pack $itk_component(delta) \
            -side top \
            -padx 5 -pady $PADY -anchor w

            pack $itk_component(startPhiOsc) -padx 5 -pady $PADY -anchor w
        }
        forLCLS -
        forLCLSGrid {
            set ring $itk_interior

            pack $itk_component(summary) -pady $PADY 
            pack $itk_component(buttonsFrame) -pady $PADY
            pack $itk_component(shape) -pady $PADY -padx 5 -anchor w
            pack $itk_component(beam_size) -padx 5 -pady $PADY -anchor w
            pack $itk_component(cellSizeFrame) -padx 5 -pady $PADY -anchor w

            #pack $itk_component(item_size) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(moveGridFrame) -padx 5 -pady $PADY -anchor w

            pack $ring.dummy0
            pack $itk_component(fileRoot) -pady $PADY -padx 5 -anchor w
            pack $itk_component(dirFrame) -pady $PADY -padx 5  -anchor w
            pack $itk_component(onGrid) -side left
            pack $itk_component(distanceFrame) -padx 5 -pady $PADY -anchor w
            pack $itk_component(stillAtt) -padx 5 -pady $PADY -anchor w

            #pack $ring.dummy1
            #pack $itk_component(phiOffsetFrame)  -padx 5 -pady $PADY -anchor w
            #pack $itk_component(videoShot)  -padx 5 -pady $PADY -anchor w
            grid remove $itk_component(firstStill)
            grid remove $itk_component(firstAtt)
            grid  $itk_component(secondStill)
            grid  remove $itk_component(secondReverse)
            pack $itk_component(firstFrame) -padx 5  -pady $PADY -anchor w
            #pack $itk_component(phiFrame) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(timeFrame) -pady $PADY -anchor w
            #pack $itk_component(delta) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(endSingleFrame) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(processing) -padx 5 -pady $PADY -anchor w
        }
        forPXL614 {
            set ring $itk_interior

            pack $itk_component(summary) -pady $PADY 
            pack $itk_component(buttonsFrame) -pady $PADY
            pack $itk_component(shape) -pady $PADY -padx 5 -anchor w
            pack $itk_component(fileRoot) -pady $PADY -padx 5 -anchor w
            pack $itk_component(dirFrame) -pady $PADY -padx 5  -anchor w
            pack forget $itk_component(onGrid)
            pack $itk_component(beam_size) -padx 5 -pady $PADY -anchor w
            pack $itk_component(distanceFrame) -padx 5 -pady $PADY -anchor w
            pack $itk_component(beamStop) -padx 5 -pady $PADY -anchor w

            pack $ring.dummy0
            pack $itk_component(phiOffsetFrame)  -padx 5 -pady $PADY -anchor w
            pack $itk_component(videoShot)  -padx 5 -pady $PADY -anchor w

            grid $itk_component(firstStill)
            grid $itk_component(firstAtt)
            grid $itk_component(secondStill)
            grid $itk_component(secondReverse)
            pack $itk_component(firstFrame) -padx 5  -pady $PADY -anchor w

            pack $itk_component(phiOsc) -side left -before $itk_component(numPhiShot)
            pack $itk_component(phiFrame) -padx 5 -pady $PADY -anchor w
            pack $itk_component(attenuation) -padx 5 -pady $PADY -anchor w

            pack $itk_component(timeFrame) -pady $PADY -anchor w
            pack $itk_component(delta) -padx 5 -pady $PADY -anchor w
            pack $itk_component(endSingleFrame) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(processing) -padx 5 -pady $PADY -anchor w
        }
        default {
            ### forGrid
            pack $itk_component(summary) -pady $PADY 
            pack $itk_component(buttonsFrame) -pady $PADY
            pack $itk_component(fileRoot) -pady $PADY -padx 5 -anchor w
            pack $itk_component(dirFrame) -pady $PADY -padx 5  -anchor w
            pack forget $itk_component(onGrid)
            pack $itk_component(shape) -pady $PADY -padx 5 -anchor w
            pack $itk_component(beam_size) -padx 5 -pady $PADY -anchor w
            pack $itk_component(cellSizeFrame) -padx 5 -pady $PADY -anchor w

            #pack $itk_component(item_size) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(moveGridFrame) -padx 5 -pady $PADY -anchor w

            pack $itk_component(distanceFrame) -padx 5 -pady $PADY -anchor w
            pack $itk_component(beamStop) -padx 5 -pady $PADY -anchor w
            pack $itk_component(attenuation) -padx 5 -pady $PADY -anchor w
            pack $itk_component(timeFrame) -pady $PADY -anchor w
            pack $itk_component(delta) -padx 5 -pady $PADY -anchor w
            #pack $itk_component(processing) -padx 5 -pady $PADY -anchor w
        }
    }

    repackExposureTime

    set m_currentView $type
    updateRegisteredComponents current_view_style
    updateRegisteredComponents is_crystal
}
body GridInputView::refreshHideShowDisplay { hide } {
    if {$itk_option(-onNew)} {
        pack forget $itk_component(showButton)
        pack forget $itk_component(hideButton)
        return
    }

    puts "show_hide: $hide"
    switch -exact -- $hide {
        0 {
            pack forget $itk_component(showButton)
            pack $itk_component(hideButton) -side left
        }
        1 {
            pack forget $itk_component(hideButton)
            pack $itk_component(showButton) -side left
        }
        -1 -
        default {
            pack forget $itk_component(showButton)
            pack forget $itk_component(hideButton)
        }
    }
}
body GridInputView::handleGridUpdate { - ready_ - contents_ - } {
    set m_ready 0
    if {!$ready_} {
        return
    }
    set m_origGridContents $contents_
    refreshGrid
}
body GridInputView::refreshGrid { } {
    set m_groupId [gCurrentGridGroup getId]
    set m_snapId  [gCurrentGridGroup getCurrentSnapshotId]

    if {$itk_option(-onNew)} {
        set m_gridId -1
    } else {
        set m_gridId  [gCurrentGridGroup getCurrentGridId]
    }

    set ll [llength $m_origGridContents]
    if {$ll < 6 || $itk_option(-onNew)} {
        set m_d_userSetup [gCurrentGridGroup getDefaultUserSetup $itk_option(-purpose)]
        switch -exact -- $itk_option(-purpose) {
            forL614 -
            forPXL614 -
            forLCLS -
            forGrid {
                $itk_component(shape) configure -state normal
            }
            forCrystal -
            forLCLSCrystal - 
            default {
                $itk_component(shape) configure -state labeled
            }
        }
        $itk_component(fileRoot) configure -state labeled
    } else {
        set m_d_userSetup [lindex $m_origGridContents 5]
        $itk_component(shape) configure -state labeled
        $itk_component(fileRoot) configure -state normal
    }
    refreshDisplay
    refreshHideShowDisplay [gCurrentGridGroup getCurrentGridHidden]
    set m_ready 1
    updateDoseExposureTime
}
body GridInputView::handlePhiNodeListUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    $itk_component(phiNodeList) setValue $contents_ 1
}
body GridInputView::refreshDisplay { } {
    set title [dict get $m_d_userSetup summary]
    $itk_component(summary) configure -text $title

    if {[catch {dict get $m_d_userSetup shape} shape]} {
        set shape unknown
    }
    if {[catch {dict get $m_d_userSetup for_lcls} forLCLS]} {
        set forLCLS 0
    }

    puts "refreshDisplay shape=$shape purpose=$itk_option(-purpose) forLCLS=$forLCLS"

    switch -exact -- $shape {
        projective -
        trap_array -
        mesh -
        l614 {
            if {$forLCLS} {
                switchView forL614
            } else {
                switchView forPXL614
            }
        }
        crystal {
            if {$forLCLS} {
                switchView forLCLSCrystal
            } else {
                switchView forCrystal
            }
        }
        default {
            if {$forLCLS} {
                switchView forLCLSGrid
            } else {
                switchView forGrid
            }
        }
    }


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

    ### highlight "To Beam Size" button if not match
    ### get beamSize
    if {[catch {dict get $m_d_userSetup collimator} clmtr]} {
        set clmtr [list 0 -1 2.0 2.0]
    }
    set microBeam 0
    set index -1
    set cbw 2.0
    set cbh 2.0
    foreach {microBeam index cbw cbh} $clmtr break
    if {$microBeam} {
        set bw [expr $cbw * 1000.0]
        set bh [expr $cbh * 1000.0]
    } else {
        if {[catch {dict get $m_d_userSetup beam_width} bw]} {
            set bw 0
        }
        if {[catch {dict get $m_d_userSetup beam_height} bh]} {
            set bh 0
        }
    }
    ### get cell size.
    if {[catch {dict get $m_d_userSetup cell_width} cw]} {
        set cw 0
    }
    if {[catch {dict get $m_d_userSetup cell_height} ch]} {
        set ch 0
    }

    switch -exact -- $m_cellFollowBeamSize {
        2 {
            set bw [expr 0.5 * $bw]
            set bh [expr 0.5 * $bh]
        }
    }

    if {abs($bw - $cw) >= 0.1 || abs($bh - $ch) >= 0.1} {
        $itk_component(csize_to_bsize) configure \
        -background  green \
        -activebackground green

        $itk_component(step_to_bsize) configure \
        -background  green \
        -activebackground green

        puts "cell: $cw $ch beam: $bw $bh for $this"
    } else {
        $itk_component(csize_to_bsize) configure \
        -background $m_origBG \
        -activebackground $m_origABG

        $itk_component(step_to_bsize) configure \
        -background $m_origBG \
        -activebackground $m_origABG

        puts "cell: $cw $cw beam: $bw $bh OK for $this"
    }

    #### special:
    if {$shape == "crystal"} {
        foreach {v u} [$itk_component(delta) get] break
        set fStart [$itk_component(startFrame) get]
        set fEnd   [$itk_component(endFrame)   get]
        set nNode  [$itk_component(numColumn)  get]
        if {$fStart < 1} {
            set fSTart 1
        }
        if {$fEnd < $fStart} {
            set fEnd $fStart
        }
        if {$nNode < 1} {
            set nNode 1
        }

        set framePerNode [expr int(ceil(double($fEnd - $fStart + 1) / $nNode))]

        #### gap update
        set beamSizeInfo [$itk_component(beam_size) getBeamSize]
        set beamWidth [lindex $beamSizeInfo 0]
        set bwInU [expr $beamWidth * 1000.0]
        set cellSize [$itk_component(cell_size) getValue]
        set cellWidth [lindex $cellSize 0]
        set gap [expr $cellWidth - $bwInU]
        $itk_component(gap) setValue $gap 1
    }

    if {$numError} {
        puts "failed to update, the dict=$m_d_userSetup"
        if {$m_d_userSetup == ""} {
            puts "contents=$contents_"
        }
    }
}
body GridInputView::getL614Port { {onGrid {}} } {
    set gridPort ""

    if {$onGrid == ""} {
        if {[catch {dict get $m_d_userSetup on_l614_grid} onGrid]} {
            set onGrid 0
        }
    }

    if {$onGrid == "1"} {
        set ctxCurrentL614Node [$m_objCurrentL614Node getContents]
        foreach {l614_groupId l614_gridId l614_seq l614_label} \
        $ctxCurrentL614Node break

        if {$l614_groupId == $m_groupId \
        && $l614_gridId >= 0 \
        && $l614_seq >= 0} {
            set gridPort $l614_label
            puts "using l614 port label: $gridPort"
        }
    }
    return $gridPort
}
body GridInputView::getDirectoryByOnL614Grid { onGrid } {
    set shape            [gCurrentGridGroup getCurrentGridShape]
    set label            [gCurrentGridGroup getCurrentGridLabel]

    set latestContents   [$m_objLatestUserSetup     getContents]
    set ctxCrystalStatus [$m_objCrystalStatus       getContents]
    set ctxScreening     [$m_objScreeningParameters getContents]
    set user             [::dcss getUser]

    set gridPort [getL614Port $onGrid]
    foreach {prefix dir} \
    [::GridGroup::GridGroupBase::generatePrefixAndDirectory \
    $user \
    $shape \
    $label \
    $ctxCrystalStatus \
    $ctxScreening \
    $gridPort \
    ] break

    if {$dir == ""} {
        ### no sample mounted
        set dir [dict get $latestContents directory]
    }

    return $dir
}
body GridInputView::generateParamForUpdate { } {
    puts "generateParam"
    global gMotorDistance
    global gMotorBeamStop
    global gMotorBeamWidth
    global gMotorBeamHeight

    set shape            [gCurrentGridGroup getCurrentGridShape]
    set label            [gCurrentGridGroup getCurrentGridLabel]

    set latestContents   [$m_objLatestUserSetup     getContents]
    set ctxCrystalStatus [$m_objCrystalStatus       getContents]
    set ctxScreening     [$m_objScreeningParameters getContents]
    set user             [::dcss getUser]

    set gridPort [getL614Port]
    foreach {prefix dir} \
    [::GridGroup::GridGroupBase::generatePrefixAndDirectory \
    $user \
    $shape \
    $label \
    $ctxCrystalStatus \
    $ctxScreening \
    $gridPort \
    ] break

    if {$dir == ""} {
        ### no sample mounted
        set dir [dict get $latestContents directory]
    }

    set param [dict create prefix $prefix directory $dir]
    replaceUsernameAndGridLabelInDictionary param $user $label

    set deviceFactory [::DCS::DeviceFactory::getObject]
    set microBeam 0
    if {[$deviceFactory stringExists user_collimator_status]} {
        set obj [$deviceFactory getObjectName user_collimator_status]
        set contents [$obj getContents]
        if {[llength $contents] >= 4} {
            dict set param collimator $contents
            foreach {microBeam index cbw cbh} $contents break
        } else {
            dict set param collimator  [list 0 -1 2.0 2.0]
            set microBeam 0
            set index -1
            set cbw 2.0
            set cbh 2.0
        }
        if {$microBeam} {
            set cellWidth  $cbw
            set cellHeight $cbh
        }
        
        puts "collimator $contents"
    } else {
        dict set param collimator  [list 0 -1 2.0 2.0]
    }
    puts "getting"
    set bw [::device::$gMotorBeamWidth  cget -scaledPosition]
    set bh [::device::$gMotorBeamHeight cget -scaledPosition]
    set distance [::device::$gMotorDistance cget -scaledPosition]
    set beamStop [::device::$gMotorBeamStop cget -scaledPosition]
    set att      [::device::attenuation     cget -scaledPosition]

    if {!$microBeam} {
        set cellWidth  $bw
        set cellHeight $bh
    }

    puts "setting"
    set oldCellWidth  [dict get $m_d_userSetup cell_width]
    set oldCellHeight [dict get $m_d_userSetup cell_height]
    set newCellWidth  [expr 1000.0 * $cellWidth]
    set newCellHeight [expr 1000.0 * $cellHeight]

    dict set param beam_width  [expr 1000.0 * $bw]
    dict set param beam_height [expr 1000.0 * $bh]
    switch -exact -- $m_cellFollowBeamSize {
        1 {
            dict set param cell_width  $newCellWidth
            dict set param cell_height $newCellHeight
        }
        2 {
            dict set param cell_width  [expr $newCellWidth / 2.0]
            dict set param cell_height [expr $newCellHeight / 2.0]
        }
    }
    dict set param distance    $distance
    dict set param beam_stop   $beamStop

    switch -exact -- $itk_option(-purpose) {
        forCrystal -
        forGrid -
        forPXL614 {
            dict set param attenuation [expr $att + 0.0001]
        }
        forLCLSCrystal -
        forL614 -
        forLCLS -
        default {
            dict set param attenuation 80.0
        }
    }
    dict set param first_attenuation 0.0
    dict set param end_attenuation 0.0

    #### start_angle to current phi
    set phi [$m_objPhi cget -scaledPosition]

    set camera [gCurrentGridGroup getCurrentGridCamera]
    puts "grid camera=$camera"
    if {$camera != ""} {
        set offset [::config getStr "camera_view_phi.$camera"]
        puts "offset=$offset"
        if {[string is double -strict $offset]} {
            set phi [expr $phi - $offset]
        }
    }

    set extParam [gCurrentGridGroup setupCurrentGridExposure start_angle $phi]
    set param [dict merge $param $extParam]

    #### energy_list is complicated.
    set numEnergy 0
    set eList [list]
    set peakEnergy 0.0
    set remoteEnergy 0.0

    set userScanWindow [[InflectPeakRemExporter::getObject] getExporter] 
    if { [info commands $userScanWindow] != "" } {
        set peakEnergy [lindex [$userScanWindow getMadEnergy Peak] 0]
        if {$peakEnergy != "" } {
            lappend eList $peakEnergy
        }

        set remoteEnergy [lindex [$userScanWindow getMadEnergy Remote] 0]
        if {$remoteEnergy != "" } {
            lappend eList $remoteEnergy
        }

        set inflectionEnergy \
        [lindex [$userScanWindow getMadEnergy Inflection] 0]
        if {$inflectionEnergy != "" } {
            lappend eList $inflectionEnergy
        }
    }
    if {[llength $eList] == 0} {
        set energy [$m_objEnergy cget -scaledPosition]
        set eList $energy
    }
    dict set param energy_list $eList

    return $param
}
body GridInputView::setupDefaultExposure { paramREF } {
    upvar $paramREF param
    set phi [$m_objPhi cget -scaledPosition]
    set camera [gCurrentGridGroup getCurrentGridCamera]
    puts "grid camera=$camera"
    if {$camera != ""} {
        set offset [::config getStr "camera_view_phi.$camera"]
        puts "offset=$offset"
        if {[string is double -strict $offset]} {
            set phi [expr $phi - $offset]
        }
    }

    set energy [$m_objEnergy cget -scaledPosition]

    dict set param delta 1.0
    dict set param start_frame 1
    dict set param end_frame   180
    set extParam [gCurrentGridGroup setupCurrentGridExposure start_angle $phi]
    foreach {name value} $extParam {
        dict set param $name $value
    }

    dict set param inverse_beam 0
    dict set param wedge_size   180.0
    dict set param energy_list  $energy
}
body GridInputView::setToDefaultDefinition { } {
    puts "Default"
    set shape [gCurrentGridGroup getCurrentGridShape]
    if {$shape == "" || $itk_option(-onNew)} {
        $m_objGridGroupConfig startOperation default_grid_parameter \
        $itk_option(-purpose)
        return
    }

    ### update the string latest first
    set defaultContents [$m_objDefaultUserSetup getContents]
    set latestContents  [$m_objLatestUserSetup  getContents]

    set latestContents [dict merge $latestContents $defaultContents]
    setupDefaultExposure latestContents

    $m_objLatestUserSetup sendContentsToServer $latestContents

    ######################################
    #### now update the grid if any
    set user   [::dcss getUser]
    set label  [gCurrentGridGroup getCurrentGridLabel]
    set ctxCrystalStatus [$m_objCrystalStatus       getContents]
    set ctxScreening     [$m_objScreeningParameters getContents]

    set gridPort [getL614Port]
    foreach {prefix dir} \
    [::GridGroup::GridGroupBase::generatePrefixAndDirectory \
    $user \
    $shape \
    $label \
    $ctxCrystalStatus \
    $ctxScreening \
    $gridPort \
    ] break

    if {$dir == ""} {
        ### no sample mounted
        set dir [dict get $latestContents directory]
    }
    dict set defaultContents prefix $prefix
    dict set defaultContents directory $dir
    setupDefaultExposure defaultContents

    set param [dict create]
    switch -exact -- $shape {
        l614 -
        projective -
        trap_array -
        mesh {
            dict set param by_exposure_setup 0
        }
    }
    foreach name {cell_width cell_height} {
        set v [dict get $defaultContents $name]
        dict unset defaultContents $name
        switch -exact -- $shape {
            l614 -
            projective -
            trap_array -
            mesh {
            }
            default {
                dict set param $name $v
            }
        }
    }
    if {$shape == "crystal"} {
        ### the default should get from collect_default, not
        ### default_raster_user_setup]
        set collectDefault [$m_objDefaultCollectSetup getContents]
        foreach {delta time att} $collectDefault break
        puts "crystal change default to collect default:"
        puts "delta=$delta time=$time attenuation=$att"
        dict set defaultContents delta       $delta
        dict set defaultContents time        $time

        switch -exact -- $itk_option(-purpose) {
            forCrystal {
                dict set defaultContents attenuation $att
                #### following parameter use update
                set paramFromUpdate [generateParamForUpdate]
                foreach tag {distance beam_stop beam_width beam_height \
                collimator} {
                    if {[dict exists $paramFromUpdate $tag]} {
                        set v [dict get $paramFromUpdate $tag]
                        dict set defaultContents $tag $v
                    }
                }
                foreach tag {cell_width cell_height} {
                    if {[dict exists $paramFromUpdate $tag]} {
                        set v [dict get $paramFromUpdate $tag]
                        dict set param $tag $v
                    }
                }
            }
            forGrid -
            forPXL614 {
                dict set defaultContents attenuation $att
            }
            forLCLSCrystal -
            forL614 -
            forLCLS -
            default {
                dict set defaultContents attenuation 80.0
            }
        }
        dict set defaultContents first_attenuation 0.0
        dict set defaultContents end_attenuation 0.0
    }

    if {![gCurrentGridGroup adjustCurrentGrid $param $defaultContents]} {
        log_error crystal Default must be done with image display.
        refreshDisplay
    }
}
body GridInputView::updateDefinition { } {
    set shape [gCurrentGridGroup getCurrentGridShape]
    if {$shape == "" || $itk_option(-onNew)} {
        $m_objGridGroupConfig startOperation update_grid_parameter \
        $m_groupId -1 $m_cellFollowBeamSize $itk_option(-purpose)
        return
    }

    set param [generateParamForUpdate]
    puts "param=$param"

    set geoParam [dict create]

    ### update latest
    set latestContents [$m_objLatestUserSetup  getContents]
    set latestContents [dict merge $latestContents $param]
    setupDefaultExposure latestContents
    $m_objLatestUserSetup sendContentsToServer $latestContents

    set anyGeoChange 0
    foreach name {cell_width cell_height} {
        if {[dict exists $param $name]} {
            set v [dict get $param $name]
            dict unset param $name
            switch -exact -- $shape {
                l614 -
                projective -
                trap_array -
                mesh {
                }
                default {
                    dict set geoParam $name $v
                    incr anyGeoChange
                }
            }
        }
    }
    if {!$anyGeoChange} {
        set geoParam [dict create by_exposure_setup 0]
    }

    puts "calling adjustGrid with $geoParam"

    if {![gCurrentGridGroup adjustCurrentGrid $geoParam $param]} {
        log_error crystal Default must be done with image display.
        refreshDisplay
    }
}
body GridInputView::handleDoseModeChange { - ready_ - mode_ - } {
    if {!$ready_} return

    set m_doseMode $mode_
    updateDoseExposureTime
    repackExposureTime
}
body GridInputView::handleDoseFactorChange { - ready_ - - - } {
    if {!$ready_} return

    updateDoseExposureTime
}
body GridInputView::updateDoseExposureTime { } {
    set exposureTime [lindex [$itk_component(exposureTime) get] 0]
    if {![isFloat $exposureTime]} {
        return
    }
    set fg black
    if {$m_doseMode} {
        set e [lindex [$itk_component(energyList) getEnergyList] 0 0]
        set beamSizeInfo [$itk_component(beam_size) getBeamSize]
        foreach {w h} $beamSizeInfo break
        set a [lindex [$itk_component(attenuation) get] 0]

        set runSituation [list [clock seconds] $e $w $h $a]
        set doseFactor \
        [[DCS::DoseFactor::getObject] estimateNewDoseFactor $runSituation]

        puts "updateDose with $runSituation"

        if {[string first * $doseFactor] >= 0} {
            set fg red
        }
        $itk_component(doseFactor) configure \
        -foreground $fg \
        -text $doseFactor

        set doseTime [expr $exposureTime * $doseFactor]

    } else {
        set doseTime $exposureTime
    }

    $itk_component(doseExposureTime) configure \
    -foreground $fg \
    -text [format "%.2f" $doseTime]
}
body GridInputView::repackExposureTime { } {
    if {$m_currentView == "forCrystal" && $m_doseMode} {
        pack $itk_component(multiply) -side left
        pack $itk_component(doseFactor) -side left
        pack $itk_component(equals) -side left
        pack $itk_component(doseExposureTime) -side left
    } else {
        pack forget $itk_component(multiply)
        pack forget $itk_component(doseFactor)
        pack forget $itk_component(equals)
        pack forget $itk_component(doseExposureTime)
    }
}
class GridListView {
    inherit ::DCS::ComponentGateExtension

    itk_option define -purpose purpose Purpose $gGridPurpose {
        if {$itk_option(-purpose) == "forLCLSCrystal"} {
            pack $itk_component(strategy) -side top -fill x -expand 1 -before $itk_component(control) -anchor w
        }
    }
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -allowLookAround allowLookAround AllowLookAround 0 {
        handleNewOutput
    }

    private variable BROWNRED #a0352a
    private variable ACTIVEBLUE #2465be
    private variable OUTDARK    #aaa
    private variable DARK #777
    private variable m_objGridGroupConfig ""
    private variable m_onlyPhi 0
    
    ### to pass through
    public method handleInstantBeamSizeChange { - ready_ - contents_ - } {
        if {!$ready_} return
        set m_instantBeamsize $contents_
        updateRegisteredComponents instant_beam_size
    }
    public method getInstantBeamSize { } { return $m_instantBeamsize }

    public method handleItemListUpdate
    public method handleAllowLookAroundUpdate { - ready_ - contents_ -} {
        if {!$ready_} return

        configure -allowLookAround $contents_
    }
    public method handleOnlyPhiUpdate { - ready_ - contents_ -} {
        if {!$ready_} return

        set m_onlyPhi $contents_
    }

    public method handleClientStatusChange
    public method addNewGrid { }
    public method collect

    public method highlightStartButton { } {
        $itk_component(control) highlightStartButton
    }
    public method dehighlightStartButton { } {
        $itk_component(control) dehighlightStartButton
    }

    public method onTabSwitch { index } {
        #puts "onTabSwitch $index"
        if {$m_inEventHandling} {
            puts "skip in event processing"
            return
        }
        dehighlightStartButton
        set id $m_itemIdMap($index)
        gCurrentGridGroup selectGridId $id
        switch -exact -- [gCurrentGridGroup getCurrentGridShape] {
            l614 -
            projective -
            trap_array -
            mesh {
                return
            }
        }
        if {$_gateOutput == 1 && $id >= 0} {
            puts "move_to_grid $id"
            set facing "orig"
            set grpId [gCurrentGridGroup getId]
            set zoomOn 0
            $m_objGridGroupConfig startOperation move_to_grid \
            $grpId $id $facing $m_onlyPhi $zoomOn
        }
    }
    protected method handleNewOutput { } {
        #puts "$this handleNewOutput: gate $_gateOutput allow $itk_option(-allowLookAround)"
        if { $_gateOutput == 0 && !$itk_option(-allowLookAround)} {
            $itk_component(notebook) configure -state disabled
        } else {
            $itk_component(notebook) configure -state normal 
            set maxCount [GridGroup::GridGroupBase::getMAXNUMGRID]
            if {$m_numTabs >= $maxCount} {
                $itk_component(notebook) pageconfigure end -state disabled
            }
        }
        updateBubble
    }

    private method adjustNumTabs
    private method updateNewRunCommand
    private method filterItemList { contents_ }

    private variable m_numGrid 0 
    private variable m_numTabs 0
    private variable m_gridStateColor  
    private variable m_itemLabel
    private variable m_itemIdMap

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

        itk_component add strategy {
            #GridPhiOscWithStrategyView $ring.stg
            #GridSingleShotStrategyView $ring.stg
            GridComboStrategyView $ring.stg
        } {
            keep -systemIdleOnly -activeClientOnly
            keep -onStart
            keep -purpose
            keep -font
        }

        itk_component add control {
            GridGroupControl $ring.control
        } {
            keep -systemIdleOnly -activeClientOnly
            keep -onStart
            keep -purpose
            keep -font
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
         
        $itk_component(notebook) select 0
        $itk_component(notebook) configure -auto off
      
        #pack the single runView widget into the first childsite 
        set childSite [$itk_component(notebook) childsite 0]

        itk_component add grid_view {
            GridInputView $childSite.gview \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -purpose
            keep -font
        }

        pack $itk_component(grid_view) -expand 1 -fill both -anchor nw

        pack $itk_component(control) -side top -fill x -expand 1
        pack $itk_component(notebook) -side top -anchor n -pady 0 \
        -expand 1 -fill both

        eval itk_initialize $args   
        exportSubComponent on_new ::$itk_component(grid_view)
        announceExist

        $itk_component(control) addInputToSkip \
        "::$itk_component(grid_view) is_crystal 0 {no skip for collecting}"

        $itk_component(control) addInputToStart \
        "::$itk_component(grid_view) on_new 0 {just latest user input}"

        set wrapper [$itk_component(grid_view) getAttributeWrapper]
        $itk_component(strategy) setWrapper $wrapper

        $itk_component(strategy) addInputToStart \
        "::$itk_component(grid_view) on_new 0 {just latest user input}"

        set maxCount [GridGroup::GridGroupBase::getMAXNUMGRID]
        for {set i 0} {$i < $maxCount} {incr i} {
            set m_itemLabel($i) X
            set m_itemIdMap($i) -1
            set m_gridStateColor($i) $ACTIVEBLUE
        }

        $itk_component(grid_view) register $this instant_beam_size handleInstantBeamSizeChange

        if {[gCurrentGridGroup getId] < 0} {
            gCurrentGridGroup switchGroupNumber 0 1
        }

        #$this register gCurrentGridGroup instant_beam_size handleInstantBeamSizeChange

        gCurrentGridGroup register $this item_list handleItemListUpdate
        gCurrentGridGroup register $this allow_look_around_when_busy \
        handleAllowLookAroundUpdate

        gCurrentGridGroup register $this only_rotate_phi \
        handleOnlyPhiUpdate

        $itk_component(grid_view) register ::$itk_component(control) \
        current_view_style \
        handleViewStyleUpdate
    }
    destructor {
        gCurrentGridGroup unregister $this item_list handleItemListUpdate

        gCurrentGridGroup unregister $this allow_look_around_when_busy \
        handleAllowLookAroundUpdate

        gCurrentGridGroup unregister $this only_rotate_phi \
        handleOnlyPhiUpdate
    }
}

body GridListView::adjustNumTabs { } {
    puts "$this adjustNumTabs: tabs=$m_numTabs grids=$m_numGrid"
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
            -command "$this onTabSwitch $i" \
            -label $m_itemLabel($i) \
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
body GridListView::updateNewRunCommand {} {
    set maxCount [GridGroup::GridGroupBase::getMAXNUMGRID]
    #puts "update: count: $m_numTabs max: $maxCount"

    if {$m_numTabs < $maxCount} {
        #configure the 'add run' star
        $itk_component(notebook) pageconfigure end \
        -label " * " \
        -command [list $this addNewGrid] 
    }
}
body GridListView::addNewGrid { } {
    if {$m_inEventHandling} {
        puts "skip addNewGrid in event"
        return
    }
    gCurrentGridGroup prepareAddGrid
}
body GridListView::filterItemList { contents_ } {
    ### modify here may need to update: GridItemBase::shouldDisplay  too.
    puts "filterItemList $contents_"
    foreach {currentItemIndex itemList} $contents_ break

    set newCurrent -1
    set idx -1
    set idxNew -1
    set newList ""
    foreach itemInfo $itemList {
        incr idx
        foreach {id label state shape forLCLS} $itemInfo break
        if {![::GridItemBase::itemFitPurpose \
        $itk_option(-purpose) $shape $forLCLS] \
        } {
            continue
        }
        incr idxNew
        lappend newList $itemInfo
        if {$idx == $currentItemIndex} {
            set newCurrent $idxNew
        }
    }

    return [list $newCurrent $newList]
}
body GridListView::handleItemListUpdate { - ready_ - contents_ - } {
    puts "$this handleItemListUpdate {$contents_}"
    set ll [llength $contents_]
    if {!$ready_ || $ll < 2} {
        return
    }

    set m_inEventHandling 1

    set filteredContents [filterItemList $contents_]

    foreach {m_currentGridIndex m_gridList} $filteredContents break
    set m_numGrid [llength $m_gridList]
    adjustNumTabs

    set tabIndex -1
    foreach gridInfo $m_gridList {
        incr tabIndex
        foreach {id label state} $gridInfo break
        set m_itemLabel($tabIndex) $label
        set m_itemIdMap($tabIndex) $id

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

        puts "$this notebook page $tabIndex label=$label"
    }
    if {$m_currentGridIndex < 0} {
        $itk_component(notebook) select $m_numTabs
        $itk_component(grid_view) configure -onNew 1
        $itk_component(strategy) configure -onNew 1
    } elseif {$m_currentGridIndex < $m_numTabs} {
        $itk_component(notebook) select $m_currentGridIndex
        $itk_component(grid_view) configure -onNew 0
        $itk_component(strategy) configure -onNew 0
    }

    set m_inEventHandling 0
}

class GridNodeListView {
    inherit ::DCS::ComponentGateExtension

    itk_option define -font font Font "-family courior -size 16" { setFont }

    itk_option define -onNew onNew OnNew 1 { refresh }

    itk_option define -hideSkipped hideSkipped HideSkipped 1 { updateNodeList }

    ### for the future to click on node to add/remove from phi-osc list.
    itk_option define -holdView holdView HoldView 0 {
        if {!$itk_option(-holdView)} {
            makeSureCurrentNodeShown
        }
    }

    itk_option define -diffViewer diffViewer DiffViewer ""

    public method handleOnNewChange { - ready_ - contents_ - } {
        #puts "$this handleOnNew change: $ready_ $contents_"
        if {!$ready_} {
            return
        }
        configure -onNew $contents_
    }

    ### event handler to updat display
    public method handleListUpdate { - ready_ - contents_ - }

    public method handleCurrentNodeUpdate { - ready_ - contents_ -}
    
    ### handle user click on the node line
    public method handleClick { index wx wy } {
        switch -exact -- $m_leftChoice {
            all {
                moveToNode $index
                sendToAdxv $index
            }
            adxv {
                sendToAdxv $index
            }
            diff {
                if {![sendToDiffViewer $index]} {
                    log_error no diff image yet.
                }
            }
            right {
                handleRightClick $index $wx $wy
            }
            move -
            default {
                moveToNode $index
            }
        }
    }
    public method sendToAdxv { index } {
        if {![sendToDiffViewer $index]} {
            log_error no diff image yet.
            return
        }

        if {$m_dir != "" && $m_prefix != "" && $m_ext != ""} {
            set seq   [lindex $m_index2sequence $index]
            set label [lindex $m_labelList $seq]
            if {$label == ""} {
                set cnt [format $m_cntFormat [expr $seq + 1]]
                set path [file join $m_dir ${m_prefix}_${cnt}.$m_ext]
            } else {
                set id    [gCurrentGridGroup getCurrentGridId]
                set shape    [gCurrentGridGroup getGridShape $id]
                switch -exact -- $shape {
                    l614 -
                    projective -
                    trap_array -
                    mesh {
                        set path [file join $m_dir \
                        ${m_prefix}_${label}_firstShot.$m_ext]
                    }
                    default {
                        set path [file join $m_dir ${m_prefix}_${label}.$m_ext]
                    }
                }
            }
            set objAdxv [GridAdxvView::getObject]

            if {[catch {$objAdxv displayFile $path} errMsg]} {
                puts "displayFile faile: $errMsg"
            }
        }
    }
    public method moveToNode { index } {
        sendToDiffViewer $index

        if {!$_gateOutput} {
            return
        }

        set grpId [gCurrentGridGroup getId]
        set ssId  [gCurrentGridGroup getCurrentSnapshotId]
        set id    [gCurrentGridGroup getCurrentGridId]
    
        set seq [lindex $m_index2sequence $index]

        set facing beam

        $m_objGridGroupConfig startOperation \
        move_to_node $grpId $id $seq $facing
    }
    public method sendToDiffViewer { index } {
        set f $itk_component(nodeListFrame)
        set nodeStatus [$f.status${index} cget -text]
        switch -exact -- $nodeStatus {
            PROC -
            DONE {
                ### OK to continue
            }
            default {
                return 0
            }
        }
        if {$m_dir == "" || $m_prefix == "" || $m_ext == ""} {
            return 0
        }

        if {$itk_option(-diffViewer) == ""} {
            return 1
        }
        set seq   [lindex $m_index2sequence $index]
        set label [lindex $m_labelList $seq]
        if {$label == ""} {
            set cnt [format $m_cntFormat [expr $seq + 1]]
            set path [file join $m_dir ${m_prefix}_${cnt}.$m_ext]
        } else {
            set id    [gCurrentGridGroup getCurrentGridId]
            set shape    [gCurrentGridGroup getGridShape $id]
            switch -exact -- $shape {
                l614 -
                projective -
                trap_array -
                mesh {
                    set path [file join $m_dir \
                    ${m_prefix}_${label}_firstShot.$m_ext]
                }
                default {
                    set path [file join $m_dir ${m_prefix}_${label}.$m_ext]
                }
            }
        }
        if {[catch {
            $itk_option(-diffViewer) showFile $path
        } errMsg]} {
            puts "showDiff failed: $errMsg"
        }
        return 1
    }

    public method handleRightClick { index x y } {
        #############################
        ### prepare data
        #############################
        set grpId [gCurrentGridGroup getId]
        set id    [gCurrentGridGroup getCurrentGridId]
        set cellSize [gCurrentGridGroup getGridCellSize $id]
        set shape    [gCurrentGridGroup getGridShape $id]
        foreach {cw ch} $cellSize break
    
        set seq   [lindex $m_index2sequence $index]
        set label [lindex $m_labelList $seq]
        $itk_component(commandView) setup \
        $grpId $id $seq $cw $ch $m_itemLabel $label $shape

        #############################
        ### now show the widget.
        #############################
        set win [winfo parent $itk_component(commandView)]

        set x0 [winfo rootx $win]
        set y0 [winfo rooty $win]
        puts "rightclick $index $x $y x0=$x0 y0=$y0"

        set width  [winfo width  $win]
        set height [winfo height $win]

        set floatWidth  [winfo reqwidth  $itk_component(commandView)]
        set floatHeight [winfo reqheight $itk_component(commandView)]

        ### pointer position on this window
        set px [expr $x - $x0]
        set py [expr $y - $y0]
        ### try to fit the floating to the display

        if {$py > $height / 2} {
            if {$py < $floatHeight} {
                set py $floatHeight
                if {$py > $height} {
                    set py $height
                }
            }
            set aa s
        } else {
            if {$py > ($height - $floatHeight)} {
                set py [expr $height - $floatHeight]
                if {$py < 0} {
                    set py 0
                }
            }
            set aa n
        }
        if {$px > $width / 2} {
            if {$px < $floatWidth} {
                set px $floatWidth
                if {$px > $width} {
                    set px $width
                }
            }
            append aa e
        } else {
            if {$px > ($width - $floatWidth)} {
                set px [expr $width - $floatWidth]
                if {$px < 0} {
                    set px 0
                }
            }
            append aa w
        }

        place $itk_component(commandView) \
        -x $px \
        -y $py \
        -anchor $aa

        raise $itk_component(commandView) \
    }

    ### select current node by other widgets.
    public method setNodeIndex { index }

    public method redisplay { } {
        configure -hideSkipped $gCheckButtonVar($this,hide)
    }
    public method setHold { } {
        configure -holdView $gCheckButtonVar($this,hold)
    }

    public method setChoice { name } {
        set m_leftChoice $name
        $itk_component(leftButton) configure \
        -text $m_lbLabel($name)
    }

    public method showShortcut { } {
        puts "show shortcut"
        set win [winfo parent $itk_component(commandView)]
        set x0 [winfo rootx  $win]
        set y0 [winfo rooty  $win]

        set win $itk_component(shortcut)
        set x [winfo rootx  $win]
        set y [winfo rooty  $win]
        set w [winfo width  $win]
        set h [winfo height $win]

        set px [expr $x + $w - $x0]
        set py [expr $y + $h - $y0]

        place $itk_component(shortcutFrame) \
        -x $px \
        -y $py \
        -anchor ne \

        raise $itk_component(shortcutFrame)
    }

    private method setFont { }

    private method setCurrentNode { index }

    private method makeSureCurrentNodeShown { }

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

    private method updateCurrentNode { }

    private method refresh { }

    private variable m_headerSite
    private variable m_currentNodeIndex -1
    private variable m_numNodeCreated 0
    private variable m_numNodeParsed 0
    private variable m_numNodeDisplayed 0
    private variable m_index2sequence ""

    private variable m_origListContents ""
    private variable m_itemLabel ""
    private variable m_nodeList ""
    private variable m_labelList ""
    private variable m_dir ""
    private variable m_prefix ""
    private variable m_ext ""
    private variable m_shape ""

    ### for convenient, it stores cell name
    private variable m_oneNode ""
    private variable m_dataWidth 0

    private variable m_objGridGroupConfig ""
    private variable m_strCurrentNode ""
    private variable m_ctsCurrentNode ""

    private variable m_cntFormat "%05d"

    private variable m_lbLabel
    private variable m_leftChoice move

    private common INIT_NODE     800
    private common MAX_NODE      800

    public  common FIELD_NAME   [list Spots {Spot Shape} Resolution  Score Rings]
    private common FIELD_WIDTH  [list 8     14           14          8     8    ]
    public  common FIELD_INDEX  [list 0     5            3           2     4    ]
    private common FIELD_FORMAT [list %.0f  %.1f         %.1f        %.1f  %.0f ]

    private common FIELD_STATUS_WIDTH 8
    private common FIELD_FRAME_WIDTH 8

    private common HEADER_IPADY         4
    private common HEADER_BACKGROUND    #c0c0ff
    private common ODD_LINE_BACKGROUND  #e0e0e0
    private common EVEN_LINE_BACKGROUND gray

    private common gCheckButtonVar

    constructor { args } {
        set m_lbLabel(move)     "Center Node in Beam"
        set m_lbLabel(adxv)     "Send to ADXV"
        set m_lbLabel(all)      "Adxv and Center"
        set m_lbLabel(diff)     "View in BluIce"
        set m_lbLabel(right)    "Sub-Raster Menu"

        set m_cntFormat [::config getFrameCounterFormat]

        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        set m_strCurrentNode [$deviceFactory createString currentGridGroupNode]

        set data_header [format %-${FIELD_FRAME_WIDTH}s Frame]
        set m_dataWidth $FIELD_FRAME_WIDTH
        foreach fh $FIELD_NAME fw $FIELD_WIDTH {
            append data_header [format %-${fw}s $fh]
            incr m_dataWidth $fw
        }
        ### special field warning_messages
        append data_header [format %-20s "Warning"]
        incr m_dataWidth 20

        itk_component add titleFrame {
            frame $itk_interior.headerF
        } {
        }
        set titleSite $itk_component(titleFrame)

        itk_component add title {
            label $titleSite.title \
            -anchor w \
            -text "title"
        } {
        }

        set lbSite [frame $titleSite.lbFrame]

        itk_component add lbLabel {
            label $lbSite.label \
            -text "Left Button Action:"
        } {
        }
        itk_component add leftButton {
            menubutton $lbSite.leftButton \
            -text $m_lbLabel(move) \
            -anchor w \
            -width 20 \
            -relief sunken \
            -background white \
            -menu $lbSite.leftButton.menu
        } {
        }
        itk_component add lbArrow {
            label $lbSite.lbArrow \
            -image [DCS::MenuEntry::getArrowImage] \
            -width 16 \
            -anchor c \
            -relief raised \
        } {
        }
        itk_component add lbMenu {
            menu $lbSite.leftButton.menu \
            -tearoff 0 \
            -activebackground blue \
            -activeforeground white \
        } {
        }
        foreach name {move adxv all diff right} {
            $itk_component(lbMenu) add command \
            -label $m_lbLabel($name) \
            -command "$this setChoice $name"
        }
        pack $itk_component(lbLabel) -side left
        pack $itk_component(leftButton) -side left
        pack $itk_component(lbArrow) -side left
        bind $itk_component(lbArrow) <Button-1> \
        "tk::MbPost $itk_component(leftButton) %X %Y"

        bind $itk_component(lbArrow) <ButtonRelease-1> \
        "tk::MbButtonUp $itk_component(leftButton)"

        #should match itk_option -hideSkipped 
        set gCheckButtonVar($this,hide) 1
        set gCheckButtonVar($this,hold) 0
        itk_component add hide {
            checkbutton $titleSite.hide \
            -variable [scope gCheckButtonVar($this,hide)] \
            -text "Hide Skipped" \
            -command "$this redisplay"
        } {
        }
        itk_component add hold {
            checkbutton $titleSite.hold \
            -variable [scope gCheckButtonVar($this,hold)] \
            -text "Hold View" \
            -command "$this setHold"
        } {
        }

        itk_component add shortcutFrame {
            frame $itk_interior.shortcutF \
            -background #a0a0c0
        } {
        }
        set scSite $itk_component(shortcutFrame)
        label $scSite.l1 \
        -background #a0a0c0 \
        -text "Ctrl+Click:  Center Node in Beam"

        label $scSite.l2 \
        -background #a0a0c0 \
        -text "Shift+Click: Send to ADXV"

        label $scSite.l3 \
        -background #a0a0c0 \
        -text "RightClick:  Sub-Raster Menu"

        pack $scSite.l1 -side top -anchor w
        pack $scSite.l2 -side top -anchor w
        pack $scSite.l3 -side top -anchor w

        itk_component add shortcut {
            button $titleSite.shortcut \
            -text "Shortcut Hints"
        } {
        }
        bind $itk_component(shortcut) <Button-1> "$this showShortcut"

        bind $itk_component(shortcut) <ButtonRelease-1> \
        "place forget $itk_component(shortcutFrame)"

        grid $itk_component(title) -row 0 -column 0 -sticky w
        grid $lbSite               -row 0 -column 1 -sticky ns
        grid $itk_component(shortcut) -row 0 -column 2 -sticky w
        grid $itk_component(hold)  -row 0 -column 3 -sticky e
        grid $itk_component(hide)  -row 0 -column 4 -sticky e

        grid columnconfigure $titleSite 0 -weight 10
        grid columnconfigure $titleSite 2 -weight 10

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
            -text "Use Heads Up Display to define item first" \
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

        itk_component add commandView {
            GridNodeCommandView $itk_interior.cView
        } {
        }
        eval itk_initialize $args
        announceExist

        gCurrentGridGroup register $this current_grid_node_list \
        handleListUpdate

        $m_strCurrentNode register $this contents handleCurrentNodeUpdate
    }
    destructor {
        gCurrentGridGroup unregister $this current_grid_node_list \
        handleListUpdate

        $m_strCurrentNode unregister $this contents handleCurrentNodeUpdate
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

        bind $f.status${index} <Button-1> "$this handleClick $index %X %Y"
        bind $f.data${index}   <Button-1> "$this handleClick $index %X %Y"

        bind $f.status${index} <Control-Button-1> "$this moveToNode $index"
        bind $f.data${index}   <Control-Button-1> "$this moveToNode $index"

        bind $f.status${index} <Shift-Button-1> "$this sendToAdxv $index"
        bind $f.data${index}   <Shift-Button-1> "$this sendToAdxv $index"

        registerComponent $f.status${index} $f.data${index}

        bind $f.status${index} <Button-3> "$this handleRightClick $index %X %Y"
        bind $f.data${index}   <Button-3> "$this handleRightClick $index %X %Y"


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
        set v [lindex $contents_ 8]
        append line [format %-20s $v]
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
        append line [format %-20s ----]
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
    $itk_component(commandView) handleLeave

    if {!$ready_} {
        set contents_ ""
    }

    set m_origListContents $contents_
    refresh
}
body GridNodeListView::refresh { } {

    set ll [llength $m_origListContents]
    if {$ll < 2 || $itk_option(-onNew)} {
        $itk_component(title) configure -text "Nodes not available yet"
        showLabel
        return
    }

    showList
    set m_labelList ""
    foreach {header m_nodeList m_labelList} $m_origListContents break

    set m_dir ""
    set m_prefix ""
    set m_ext ""
    foreach {id label status m_dir m_prefix m_ext m_shape} $header break

    set m_itemLabel $label

    switch -exact -- $m_shape {
        crystal {
            set txt "crystal $label ($status)"
            $itk_component(noList) configure \
            -text "Use Heads Up Display to define crystal first"
        }
        mesh -
        projective -
        trap_array -
        l614 {
            set txt "grid $label ($status)"
            $itk_component(noList) configure \
            -text "Use Heads Up Display to define grid first"
        }
        default {
            set txt "raster $label ($status)"
            $itk_component(noList) configure \
            -text "Use Heads Up Display to define raster first"
        }
    }

    $itk_component(title) configure -text $txt

    updateNodeList
    updateCurrentNode
}
body GridNodeListView::handleCurrentNodeUpdate { - ready_ - contents_ - } {
    set ll [llength $contents_]
    if {!$ready_ || $ll < 3} {
        set m_ctsCurrentNode "-1 -1 -1 -1"
    } else {
        set m_ctsCurrentNode $contents_
    }
    updateCurrentNode
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
body GridNodeListView::updateCurrentNode { } {
    set cGroup -1
    set cGridId -1
    set cSeq -1
    set cLabel -1
    foreach {cGroup cGridId cSeq cLabel} $m_ctsCurrentNode break

    set ourGroup  [gCurrentGridGroup getId]
    set ourGridId [gCurrentGridGroup getCurrentGridId]
    if {$ourGroup != $cGroup || $ourGridId != $cGridId} {
        setCurrentNode -1
    } else {
        set index [lsearch -exact $m_index2sequence $cSeq]
        puts "got current node index=$index"
        setCurrentNode $index
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
        set status [$f.status${m_currentNodeIndex} cget -text]
        if {$status != "EXPO"} {
            $f.status${m_currentNodeIndex} configure \
            -background $GridGroupColor::COLOR_CURRENT
        }
        $f.data${m_currentNodeIndex} configure \
        -background $GridGroupColor::COLOR_CURRENT
    }
    if {!$itk_option(-holdView)} {
        makeSureCurrentNodeShown
    }
}
body GridNodeListView::makeSureCurrentNodeShown { } {
    if {$m_currentNodeIndex >= 0} {
        foreach {vStart vEnd} [$itk_component(scrolledFrame) yview] break
        set curNodeTop [expr 1.0 * $m_currentNodeIndex / $m_numNodeDisplayed]
        set curNodeBottom \
         [expr 1.0 * ($m_currentNodeIndex + 1) / $m_numNodeDisplayed]

        if {$curNodeTop < $vStart} {
            $itk_component(scrolledFrame) yview moveto $curNodeTop
        } elseif {$curNodeBottom > $vEnd} {
            set vv [expr $curNodeBottom - $vEnd + $vStart]
            $itk_component(scrolledFrame) yview moveto $vv
        }
    } else {
        $itk_component(scrolledFrame) yview moveto 0
    }
}

class GridGroupControl {
    inherit ::DCS::ComponentGateExtension

    itk_option define -onStart onStart OnStart ""
    itk_option define -purpose purpose Purpose $gGridPurpose {
        switch -exact -- $itk_option(-purpose) {
            forPXL614 -
            forLCLSCrystal {
                grid $itk_component(numField)
                grid $itk_component(contourField)
                grid $itk_component(contourLevel)
                grid $itk_component(showRasterToo)
            }
            forCrystal {
                grid remove $itk_component(numField)
                grid remove $itk_component(contourField)
                grid remove $itk_component(contourLevel)
                grid $itk_component(showRasterToo)
            }
            default {
                grid $itk_component(numField)
                grid $itk_component(contourField)
                grid $itk_component(contourLevel)
                grid remove $itk_component(showRasterToo)
            }
        }
    }

    private variable m_opGridGroupConfig ""
    private variable m_objCollectGridGroup ""
    private variable m_objPause ""
    private variable m_objAdxv ""

    private variable m_strInput ""
    private variable m_objStrategy ""

    private variable m_strBYKick ""

    private variable m_origBG ""
    private variable m_origFG ""
    private variable m_origABG ""
    private variable m_origAFG ""

    private common BUTTON_WIDTH 15
    private common gCheckButtonVar

    ## switch view acccording to what is displayed.
    public method handleViewStyleUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        switch -exact -- $contents_ {
            forPXL614 -
            forL614 {
                grid $itk_component(start)
                grid remove $itk_component(start_no_osc)
                grid $itk_component(start_pause)
                grid $itk_component(skip)
                grid $itk_component(pause)
                grid remove $itk_component(clear_all)
                grid remove $itk_component(webice)
                grid $itk_component(adxvFollow)
                grid remove $itk_component(autoModify)
                grid $itk_component(autoMount)
            }
            forLCLSCrystal {
                ### lcls long crystal
                grid $itk_component(start)
                grid remove $itk_component(start_no_osc)
                grid remove $itk_component(start_pause)
                grid remove $itk_component(skip)
                grid $itk_component(pause)
                grid $itk_component(clear_all)
                grid remove $itk_component(webice)
                grid $itk_component(adxvFollow)
                grid $itk_component(autoModify)
                grid remove $itk_component(autoMount)
            }
            forLCLS -
            forLCLSGrid {
                grid $itk_component(start)
                grid remove $itk_component(start_no_osc)
                grid remove $itk_component(start_pause)
                grid $itk_component(skip)
                grid $itk_component(pause)
                grid $itk_component(clear_all)
                grid remove $itk_component(webice)
                grid $itk_component(adxvFollow)
                grid remove $itk_component(autoModify)
                grid remove $itk_component(autoMount)
            }
            forCrystal {
                # long crystal
                grid $itk_component(start)
                grid remove $itk_component(start_no_osc)
                grid remove $itk_component(start_pause)
                grid remove $itk_component(skip)
                grid $itk_component(pause)
                grid $itk_component(clear_all)
                grid $itk_component(webice)
                grid $itk_component(adxvFollow)
                grid remove $itk_component(autoModify)
                grid remove $itk_component(autoMount)
            }
            default {
                ### forGrid
                grid $itk_component(start)
                grid remove $itk_component(start_no_osc)
                grid remove $itk_component(start_pause)
                grid $itk_component(skip)
                grid $itk_component(pause)
                grid remove $itk_component(clear_all)
                grid remove $itk_component(webice)
                grid $itk_component(adxvFollow)
                grid remove $itk_component(autoModify)
                grid remove $itk_component(autoMount)
            }
        }
    }

    public method setNumberDisplayField { args } {
        gCurrentGridGroup setNumberField "$args"
    }
    public method setContourDisplayField { args } {
        gCurrentGridGroup setContourField "$args"
    }
    public method setContourLevels { args } {
        gCurrentGridGroup setContourLevels "$args"
    }
    public method setBeamDisplayOption { name } {
        gCurrentGridGroup setBeamDisplayOption $name
    }
    public method setShowOnly { v } {
        gCurrentGridGroup setShowOnlyCurrentGrid $v
    }
    public method setShowRaster { v } {
        gCurrentGridGroup setShowRasterToo $v
    }
    public method setAdxvFollowLastImage { } {
        $m_objAdxv setFollowLastImageCollected \
        $gCheckButtonVar($this,adxvFollow)
    }
    public method setStrategyInput { name value } {
        $m_objStrategy startOperation set_field $name $value
    }
    public method setAllowLookAround { v } {
        gCurrentGridGroup setAllowLookAround $v
    }
    public method setOnlyPhi { v } {
        gCurrentGridGroup setOnlyRotatePhi $v
    }

    public method addInputToSkip { trigger_ } {
        $itk_component(skip) addInput $trigger_
    }

    public method addInputToStart { trigger_ } {
        foreach name {start start_no_osc start_pause skip} {
            $itk_component($name) addInput $trigger_
        }
    }

    public method start { } {
        dehighlightStartButton
        puts "start"
        set groupId [gCurrentGridGroup getId]
        if {$groupId < 0} {
            puts "bad gridGroup, not loaded yet"
            return
        }
        set gridListInfo [gCurrentGridGroup getItemListInfo]
        set index [lindex $gridListInfo 0]
        if {$index < 0} {
            puts "no current grid to start"
            return
        }
        set shape [lindex $gridListInfo 1 $index 3]
        if {![checkShape $shape]} {
            return
        }

        $m_objCollectGridGroup startOperation $groupId $index

        #### 
        gCurrentGridGroup setDisplayFields Frame Spots

        if {[catch { eval $itk_option(-onStart) } errMsg]} {
            puts "onStart failed: $errMsg"
        }
    }
    public method startWithoutPhiOsc { } {
        puts "start"
        set groupId [gCurrentGridGroup getId]
        if {$groupId < 0} {
            puts "bad gridGroup, not loaded yet"
            return
        }
        set gridListInfo [gCurrentGridGroup getItemListInfo]
        set index [lindex $gridListInfo 0]
        if {$index < 0} {
            puts "no current grid to start"
            return
        }
        set shape [lindex $gridListInfo 1 $index 3]
        if {![checkShape $shape]} {
            return
        }

        $m_objCollectGridGroup startOperation $groupId $index no_phi_osc

        #### 
        gCurrentGridGroup setDisplayFields Frame Spots

        if {[catch { eval $itk_option(-onStart) } errMsg]} {
            puts "onStart failed: $errMsg"
        }
    }
    public method start_pause { } {
        set groupId [gCurrentGridGroup getId]
        if {$groupId < 0} {
            puts "bad gridGroup, not loaded yet"
            return
        }
        set gridListInfo [gCurrentGridGroup getItemListInfo]
        set index [lindex $gridListInfo 0]
        if {$index < 0} {
            puts "no current grid to start"
            return
        }
        set shape [lindex $gridListInfo 1 $index 3]
        if {![checkShape $shape]} {
            return
        }

        $m_objCollectGridGroup startOperation $groupId $index pause
    }
    ### we will add skip later.
    public method pause { } {
        $m_objPause startOperation
    }

    public method skip { } {
        set groupId [gCurrentGridGroup getId]
        if {$groupId < 0} {
            puts "bad gridGroup, not loaded yet"
            return
        }
        set gridListInfo [gCurrentGridGroup getItemListInfo]
        set index [lindex $gridListInfo 0]
        if {$index < 0} {
            puts "no current grid to start"
            return
        }
        set shape [lindex $gridListInfo 1 $index 3]
        if {![checkShape $shape]} {
            return
        }

        set opStatus [$m_objCollectGridGroup cget -status]
        if {$opStatus == "active"} {
            ::dcss sendMessage {gtos_stop_operation collectGrid}
        } else {
            $m_objCollectGridGroup startOperation $groupId $index skip_to_next
        }
    }

    public method clear_all { } {
        $m_opGridGroupConfig startOperation cleanup_for_user_change_over
    }

    public method openWebIceStrategy { } {
        set SID [$itk_option(-controlSystem) getSessionId]
        set user [$itk_option(-controlSystem) getUser]
        set beamline [::config getConfigRootName]
        set url [::config getCollectStrategyNewRunUrl]

        if {[string first ? $url] >= 0 } {
            append url "&SMBSessionID=$SID"
        } else {
            append url "?SMBSessionID=$SID"
        }
        append url "&userName=$user"
        append url "&beamline=$beamline"

        puts "webice url: $url"

        if {[catch "openWebWithBrowser $url" result]} {
            log_error "open webice failed: $result"
        } else {
            $itk_component(webice) configure -state disabled
            after 10000 [list $itk_component(webice) configure -state normal]
        }
    }

    private method checkShape { shape } {
        switch -exact -- $itk_option(-purpose) {
            forCrystal -
            forLCLSCrystal {
                if {$shape != "crystal"} {
                    log_error on start on crystal
                    return 0
                }
                return 1
            }
            forPXL614 -
            forL614 {
                switch -exact -- $shape {
                    l614 -
                    projective -
                    trap_array -
                    mesh {
                    }
                    default {
                        log_error on start on L614 Grid
                        return 0
                    }
                }
                return 1
            }
            default {
                switch -exact -- $shape {
                    crystal -
                    projective -
                    trap_array -
                    mesh -
                    l614 {
                        log_error on start on raster
                        return 0
                    }
                }
            }
        }
        return 1
    }

    public method highlightStartButton { } {
        $itk_component(start) configure \
        -background blue \
        -activebackground blue \
        -foreground white \
        -activeforeground white
    }
    public method dehighlightStartButton { } {
        $itk_component(start) configure \
        -background $m_origBG \
        -activebackground $m_origABG \
        -foreground $m_origFG \
        -activeforeground $m_origFG
    }

    constructor { args } {
        set m_objAdxv [GridAdxvView::getObject]
        set deviceFactory [::DCS::DeviceFactory::getObject]

        set m_objCollectGridGroup \
        [$deviceFactory createOperation collectGridGroup]

        set m_opGridGroupConfig [$deviceFactory createOperation gridGroupConfig]

        set m_objPause [$deviceFactory createOperation pauseDataCollection]
        set m_strInput [$deviceFactory createString multiStrategy_input]
        $m_strInput createAttributeFromKey auto_modify
        $m_strInput createAttributeFromKey auto_mount

        set m_objStrategy [$deviceFactory createOperation multiCrystalStrategySoftOnly]

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

        set gCheckButtonVar($this,adxvFollow) \
        [$m_objAdxv getFollowingLastImageCollected]

        itk_component add adxvFollow {
            checkbutton $controlSite.adxvFollow \
            -justify left \
            -anchor w \
            -variable [scope gCheckButtonVar($this,adxvFollow)] \
            -text "Adxv Autoload" \
            -command "$this setAdxvFollowLastImage"
        } {
            keep -font
        }
        itk_component add autoModify {
            DCS::Checkbutton $controlSite.modify \
            -text "Modify Strategy" \
            -reference "$m_strInput auto_modify" \
            -shadowReference 1 \
            -command "$this setStrategyInput auto_modify %s" \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
        } {
            keep -font
        }
        itk_component add autoMount {
            DCS::Checkbutton $controlSite.mount \
            -text "Mount Next" \
            -reference "$m_strInput auto_mount" \
            -shadowReference 1 \
            -command "$this setStrategyInput auto_mount %s" \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
        } {
            keep -font
        }

        itk_component add start {
            DCS::Button $controlSite.start \
            -width $BUTTON_WIDTH \
            -text "Start" \
            -command "$this start"
        } {
            keep -systemIdleOnly -activeClientOnly
            keep -font
        }
        set m_origBG [$itk_component(start) cget -background]
        set m_origFG [$itk_component(start) cget -foreground]
        set m_origABG [$itk_component(start) cget -activebackground]
        set m_origAFG [$itk_component(start) cget -activeforeground]



        itk_component add start_no_osc {
            DCS::Button $controlSite.startWithOcs \
            -width $BUTTON_WIDTH \
            -text "Start Without Phi Osc" \
            -command "$this startWithoutPhiOsc"
        } {
            keep -systemIdleOnly -activeClientOnly
            keep -font
        }
        itk_component add start_pause {
            DCS::Button $controlSite.start_pause \
            -width $BUTTON_WIDTH \
            -text "Start With Pause" \
            -command "$this start_pause"
        } {
            keep -systemIdleOnly -activeClientOnly
            keep -font
        }
        itk_component add pause {
            DCS::Button $controlSite.pause \
            -width $BUTTON_WIDTH \
            -text "Pause" \
            -systemIdleOnly 0 \
            -command "$this pause"
        } {
            keep -activeClientOnly
            keep -font
        }
        itk_component add skip {
            DCS::Button $controlSite.skip \
            -width $BUTTON_WIDTH \
            -text "Skip" \
            -systemIdleOnly 0 \
            -command "$this skip"
        } {
            keep -activeClientOnly
            keep -font
        }
        itk_component add clear_all {
            DCS::HotButton $controlSite.clear_all \
            -width $BUTTON_WIDTH \
            -text "Delete All" \
            -confirmText "Are you sure?" \
            -command "$this clear_all"
        } {
            keep -activeClientOnly
            keep -font
        }

        itk_component add webice {
            button $controlSite.webice \
            -text "WebIce Strategy" \
            -width $BUTTON_WIDTH \
            -foreground blue \
            -command "$this openWebIceStrategy"
        } {
        }

        grid $itk_component(start)          -row 0 -sticky w
        grid $itk_component(start_no_osc) -row 1 -sticky w
        grid $itk_component(start_pause)    -row 2 -sticky w
        grid $itk_component(pause)          -row 3 -sticky w
        grid $itk_component(skip)           -row 4 -sticky w
        grid $itk_component(clear_all)      -row 5 -sticky w
        grid $itk_component(webice)         -row 6 -sticky w
        grid $itk_component(adxvFollow)     -row 7 -sticky w
        grid $itk_component(autoModify)     -row 8 -sticky w
        grid $itk_component(autoMount)      -row 9 -sticky w

        $itk_component(start) addInput \
        "::gCurrentGridGroup current_grid_runnable 1 {cannot run}"

        if {[$deviceFactory stringExists xppBYKickCheck1]} {
            set m_strBYKick [$deviceFactory createString xppBYKickCheck1]
            $itk_component(start) addInput \
            "$m_strBYKick contents 0 {need full LCLS beam}"
        }

        $itk_component(start_no_osc) addInput \
        "::gCurrentGridGroup current_grid_runnable 1 {cannot run}"

        $itk_component(start_pause) addInput \
        "::gCurrentGridGroup current_grid_runnable 1 {cannot run}"

        $itk_component(start_no_osc) addInput \
        "::gCurrentGridGroup current_grid_phi_osc_runnable 1 {no need}"

        set numChoices $GridNodeListView::FIELD_NAME
        set numChoices [linsert $numChoices 0 None Frame]

        set ENTRY_WIDTH 12

        itk_component add numField {
            DCS::MenuEntry $optionSite.number \
            -entryWidth $ENTRY_WIDTH \
            -promptText "Show Number:" \
            -promptWidth 13 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $numChoices \
            -reference "::gCurrentGridGroup number_display_field" \
            -shadowReference 1 \
            -onSubmit "$this setNumberDisplayField %s" \
        } {
            keep -font
        }

        $itk_component(numField) addInput \
        "::gCurrentGridGroup click_to_move 0 {Disabled by Align Visually}"

        set  contourChoices $GridNodeListView::FIELD_NAME
        set contourChoices [linsert $contourChoices 0 None]
        itk_component add contourField {
            DCS::MenuEntry $optionSite.contour \
            -entryWidth $ENTRY_WIDTH \
            -promptText "Show Contour:" \
            -promptWidth 13 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $contourChoices \
            -reference "::gCurrentGridGroup contour_display_field" \
            -shadowReference 1 \
            -onSubmit "$this setContourDisplayField %s" \
        } {
            keep -font
        }

        $itk_component(contourField) addInput \
        "::gCurrentGridGroup click_to_move 0 {Disabled by Align Visually}"

        set levelChoices [list \
        "10 25 50 75 90" \
        50 \
        "50 line only" \
        "50 90" \
        ]
        itk_component add contourLevel {
            DCS::MenuEntry $optionSite.level \
            -entryWidth $ENTRY_WIDTH \
            -promptText "Contour Levels:" \
            -promptWidth 13 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $levelChoices \
            -reference "::gCurrentGridGroup contour_display_level" \
            -shadowReference 1 \
            -onSubmit "$this setContourLevels %s" \
        } {
            keep -font
        }

        set beamChoices "Cross Box Cross_And_Box None"
        itk_component add beamInfo {
            DCS::MenuEntry $optionSite.binfo \
            -entryWidth $ENTRY_WIDTH \
            -promptText "Show Beam:" \
            -promptWidth 13 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $beamChoices \
            -reference "::gCurrentGridGroup beam_display_option" \
            -shadowReference 1 \
            -onSubmit "$this setBeamDisplayOption %s" \
        } {
            keep -font
        }

        itk_component add onlyShowCurrent {
            DCS::Checkbutton $optionSite.onlyCurrent \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -justify left \
            -anchor w \
            -text "Only Show Current Item" \
            -shadowReference 1 \
            -reference "::gCurrentGridGroup show_only_current_grid" \
            -command "$this setShowOnly %s" \
            -onBackground yellow \
        } {
            keep -font
        }

        itk_component add lookaround {
            DCS::Checkbutton $optionSite.lookaround \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -justify left \
            -anchor w \
            -text "Allow Look Around When Busy" \
            -shadowReference 1 \
            -reference "::gCurrentGridGroup allow_look_around_when_busy" \
            -command "$this setAllowLookAround %s"
        } {
            keep -font
        }

        itk_component add onlyPhi {
            DCS::Checkbutton $optionSite.onlyPhi \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -justify left \
            -anchor w \
            -text "Only Rotate Phi" \
            -shadowReference 1 \
            -reference "::gCurrentGridGroup only_rotate_phi" \
            -command "$this setOnlyPhi %s" \
            -onBackground yellow \
        } {
            keep -font
        }

        itk_component add showRasterToo {
            DCS::Checkbutton $optionSite.rasterToo \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -justify left \
            -anchor w \
            -text "Show Rasters" \
            -shadowReference 1 \
            -reference "::gCurrentGridGroup show_raster_too" \
            -command "$this setShowRaster %s" \
            -onBackground yellow \
        } {
            keep -font
        }

        grid $itk_component(numField)           -row 0 -column 0 -sticky w
        grid $itk_component(contourField)       -row 1 -column 0 -sticky w
        grid $itk_component(contourLevel)       -row 2 -column 0 -sticky w
        grid $itk_component(beamInfo)           -row 3 -column 0 -sticky w
        grid $itk_component(onlyShowCurrent)    -row 4 -column 0 -sticky w
        grid $itk_component(onlyPhi)            -row 5 -column 0 -sticky w
        ##### 10/23/13: always allow look around
        ##### real code change in GridGroup4BluIce:
        ##### the atribute is alway enabled.
        #grid $itk_component(lookaround)         -row 5 -column 0 -sticky w
        grid $itk_component(showRasterToo)      -row 6 -column 0 -sticky w

        pack $itk_component(controlF) -side left -expand 1 -fill both
        pack $itk_component(optionF)  -side left -expand 1 -fill both

        eval itk_initialize $args
        announceExist
    }
}
class GridNodeCommandView {
    inherit ::itk::Widget

    public method setup {groupNum gridId seq \
    cellWidth cellHeight gridLabel nodeLabel shape } {
        set m_grpNum $groupNum
        set m_gridId $gridId
        set m_seq    $seq
        set m_cellWidth  [expr double(abs($cellWidth))]
        set m_cellHeight [expr double(abs($cellHeight))]
        set cellSizeTxt [format "%.1fX%.1fum" $m_cellWidth $m_cellHeight]

        if {$gridLabel == ""} {
            set gridLabel $gridid
        }
        if {$nodeLabel == ""} {
            set nodeLabel [expr $seq + 1]
        }

        switch -exact -- $shape {
            crystal {
                set m_cellDiameter 0.0
                set title \
                "Crystal $gridLabel Frame $nodeLabel cellSize $cellSizeTxt"
            }
            l614 {
                set firstChar [string index $nodeLabel 0]
                set index [lsearch -exact [list A B C D E] $firstChar]
                if {$index >= 0} {
                    set radius [lindex $GridItemL614::HOLE_RADIUS_LIST $index]
                    set m_cellDiameter [expr $radius * 2.0]
                } else {
                    log_error L614 Node missing label
                    set m_cellDiameter 100.0
                }

                set title \
                "Grid $gridLabel Frame $nodeLabel hole diameter $m_cellDiameter"
            }
            default {
                set m_cellDiameter 0.0
                set title \
                "Raster $gridLabel Frame $nodeLabel cellSize $cellSizeTxt"
            }
        }
        catch {
            $itk_component(typeRadio) delete 0
            $itk_component(typeRadio) delete 0
            $itk_component(typeRadio) delete 0
        }
        if {$shape == "l614"} {
            $itk_component(typeRadio) add round \
            -text $MSG_ROUND
        } else {
            $itk_component(typeRadio) add line \
            -text $MSG_LINE
            $itk_component(typeRadio) add rectangle \
            -text $MSG_RECTANGLE
        }
        $itk_component(typeRadio) select 0

        $itk_component(topFrame) configure \
        -labeltext $title

        updateRectangleSize
    }
    public method createLineGrid { } {
        set length [lindex [$itk_component(lineLength) get] 0]
        ### this one is not used for now.
        set facing inline
        $m_opGridGroupConfig startOperation addLineGridForNode \
        $m_grpNum $m_gridId $m_seq $facing $length

        handleLeave
    }
    public method createRectangleGrid { } {
        set recSize [$itk_component(rectangleSize) getValue]
        foreach {w h} $recSize break

        set minBeamSize [GridGroup::GridGroup4BluIce::getSmallestBeamSize]
        set facing inline

        $m_opGridGroupConfig startOperation addRectangleGridForNode \
        $m_grpNum $m_gridId $m_seq $facing $w $h $minBeamSize


        handleLeave
    }
    public method createRoundGrid { } {
        set facing inline
        set step [$itk_component(roundStep) getValue]
        foreach {w h} $step break
        $m_opGridGroupConfig startOperation addRoundGridForNode \
        $m_grpNum $m_gridId $m_seq $facing $m_cellDiameter $w $h
        
        handleLeave
    }
    public method handleLeave { } {
        place forget $itk_interior
    }

    public method handleTypeSelect { } {
        switch -exact -- [$itk_component(typeRadio) get] {
            line {
                pack forget $itk_component(rectangleFrame)
                pack forget $itk_component(roundFrame)
                pack $itk_component(lineFrame) -side top -fill both -expand 1
            }
            rectangle {
                pack forget $itk_component(lineFrame)
                pack forget $itk_component(roundFrame)
                pack $itk_component(rectangleFrame) \
                -side top -fill both -expand 1
            }
            round {
                pack forget $itk_component(lineFrame)
                pack forget $itk_component(rectangleFrame)
                pack $itk_component(roundFrame) \
                -side top -fill both -expand 1
            }
        }
    }

    public method handleScaleFactorUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        updateRectangleSize
    }
    private method updateRectangleSize { } {
        set scaleFactor [$itk_component(scaleChoice) getValue]
        switch -exact -- $scaleFactor {
            CellX1 {
                set w $m_cellWidth
                set h $m_cellHeight
            }
            CellX1.5 {
                set w [expr 1.5 * $m_cellWidth]
                set h [expr 1.5 * $m_cellHeight]
            }
            CellX2 {
                set w [expr 2.0 * $m_cellWidth]
                set h [expr 2.0 * $m_cellHeight]
            }
            CellX3 {
                set w [expr 3.0 * $m_cellWidth]
                set h [expr 3.0 * $m_cellHeight]
            }
            default {
                return
            }
        }
        $itk_component(rectangleSize) setValue $w $h
    }

    private variable m_colorBlue #a0a0c0
    private variable m_grpNum -1
    private variable m_gridId -1
    private variable m_seq -1

    private variable m_cellWidth 10.0
    private variable m_cellHeight 10.0
    ## for l614 hole, will parse from node label
    private variable m_cellDiameter 100.0

    private variable m_opGridGroupConfig ""

    private common MSG_LINE      "90 Degree Line Raster With the Same Parameters"
    private common MSG_RECTANGLE "Rectangle Raster With Minimum Beam Size"
    private common MSG_ROUND     "Round Raster Cover the Hole"

    constructor { args } {
        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_opGridGroupConfig [$deviceFactory createOperation gridGroupConfig]

        itk_component add topFrame {
            ::iwidgets::labeledframe $itk_interior.topF \
            -relief groove \
            -labeltext "command view" \
        } {
            keep -background
        }
        set cmdSite [$itk_component(topFrame) childsite]

        itk_component add typeRadio {
            iwidgets::radiobox $cmdSite.typeRadio \
            -labeltext "Raster Type" \
            -labelpos nw \
            -selectcolor red \
            -command "$this handleTypeSelect"
        } {
            keep -background
        }
        $itk_component(typeRadio) add line \
        -text $MSG_LINE
        $itk_component(typeRadio) add rectangle \
        -text $MSG_RECTANGLE
        $itk_component(typeRadio) add round \
        -text $MSG_ROUND
        

        pack $itk_component(typeRadio) -side top -fill x

        itk_component add lineFrame {
            frame $cmdSite.lineF
        } {
            keep -background
        }
        set lineSite $itk_component(lineFrame)
        itk_component add rectangleFrame {
            frame $cmdSite.recF
        } {
            keep -background
        }
        set recSite $itk_component(rectangleFrame)
        itk_component add roundFrame {
            frame $cmdSite.roundF
        } {
            keep -background
        }
        set roundSite $itk_component(roundFrame)

        itk_component add createLine {
            DCS::Button $lineSite.cmdLine \
            -text "Create" \
            -command "$this createLineGrid"
        } {
        }
        itk_component add cancel1 {
            button $lineSite.cancel \
            -text "Cancel" \
            -command "$this handleLeave"
        } {
        }
        itk_component add lineLength {
            DCS::Entry $lineSite.linelen \
            -background #a0a0c0 \
            -leaveSubmit 1 \
            -promptText "Line Raster Length:" \
            -entryWidth 6 \
            -entryType positiveFloat \
            -decimalPlaces 1 \
            -entryJustify right \
            -units "um"
        } {
            keep -background
        }
        grid $itk_component(lineLength) -
        grid $itk_component(createLine) $itk_component(cancel1)
        
        itk_component add cancel2 {
            button $recSite.cancel \
            -text "Cancel" \
            -command "$this handleLeave"
        } {
        }

        itk_component add createRectangle {
            DCS::Button $recSite.cmdRectange \
            -text "Create" \
            -command "$this createRectangleGrid"
        } {
        }

        $itk_component(createRectangle) addInput \
        "::gCurrentGridGroup current_grid_finest 0 {already with finest cell size}"
        itk_component add scaleFrame {
            frame $recSite.scaleF
        } {
            keep -background
        }

        set scaleSite $itk_component(scaleFrame)

        itk_component add scaleLabel {
            label $scaleSite.ll \
            -text "Rectangle Raster Size:" \
            -anchor e \
        } {
            keep -background
        }

        itk_component add rectangleSize {
            CellSize $scaleSite.recSize \
            -promptText "=" \
        } {
            keep -background
        }

        itk_component add scaleChoice {
            DCS::MenuButton $scaleSite.sfactor \
            -width 7 \
            -menuChoices [list CellX1 CellX1.5 CellX2 CellX3 Input]
        } {
            keep -background
        }
        $itk_component(scaleChoice) setValue "CellX1.5"

        $itk_component(rectangleSize) addInput \
        "::$itk_component(scaleChoice) value Input {Change Size to Input to enable}"

        grid $itk_component(scaleLabel)    -column 0 -row 0 -sticky e
        grid $itk_component(scaleChoice)   -column 1 -row 0
        grid $itk_component(rectangleSize) -column 2 -row 0

        grid $itk_component(scaleFrame) -
        grid $itk_component(createRectangle) $itk_component(cancel2)

        itk_component add createRound {
            DCS::Button $roundSite.cmdLine \
            -text "Create" \
            -command "$this createRoundGrid"
        } {
        }
        itk_component add cancel3 {
            button $roundSite.cancel \
            -text "Cancel" \
            -command "$this handleLeave"
        } {
        }
        itk_component add roundStep {
            CellSize $roundSite.step \
            -promptText "Step Size:" \
        } {
            keep -background
        }

        pack $itk_component(topFrame) -expand 1 -fill both

        puts "setting init value"
        $itk_component(lineLength) setValue 200.0
        $itk_component(rectangleSize) setValue 100.0 40.0
        $itk_component(typeRadio) select 0
        $itk_component(roundStep) setValue 20.0 20.0

        grid $itk_component(roundStep) -
        grid $itk_component(createRound) $itk_component(cancel3)


        configure -background $m_colorBlue

        eval itk_initialize $args
        puts "constructor done"

        $itk_component(scaleChoice) register $this value handleScaleFactorUpdate
    }

}
#### so that all widgets here can access it.
class GridAdxvView {
    public variable adxvUseSocket 1

    public proc getObject { } { return gGridAdxvView }

    public method displayFile { path {focus 1}}
    public method setFollowLastImageCollected { ff } {
        set m_followLastImage $ff
        if {$m_followLastImage} {
            displayLastImageCollected
        }
    }
    public method getFollowingLastImageCollected { } {
        return $m_followLastImage
    }

    #############################################
    public method handleLastImageCollected { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_ctsLastImage $contents_
        if {$m_inEvent} return
        if {$m_followLastImage} {
            set m_inEvent 1
            displayLastImageCollected
            set m_inEvent 0
        }
    }

    private proc getWinIdListFromTitle { title timeSpan {excludingList ""} }
    private method checkAdxvRunning { }
    private method startAdxv { filePath }
    private method startAdxvWithSocket { filePath }
    private method startAdxvWithAutoload { filePath }

    private method displayLastImageCollected { } {
        if {$m_ctsLastImage != ""} {
            displayFile $m_ctsLastImage 0
            if {$m_fileDisplayed != $m_ctsLastImage} {
                displayFile $m_ctsLastImage 0
            }
        }
    }

    private variable m_adxvWinId ""
    private variable m_adxvSock ""
    private variable m_adxvXformPath ""
    private variable m_adxvXformCounter 1

    private variable m_followLastImage 0
    private variable m_strLastImage ""
    private variable m_ctsLastImage ""

    private variable m_inEvent 0
    private variable m_fileDisplayed ""

    constructor { } {
        set m_adxvXformPath [file join /tmp adxvXFORM_[pid]]

        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_strLastImage [$deviceFactory createString lastImageCollected]

        $m_strLastImage register $this contents handleLastImageCollected
    }
    destructor {
        $m_strLastImage unregister $this contents handleLastImageCollected
    }
}
body GridAdxvView::getWinIdListFromTitle { title timeSpan {exclusive ""} } {
    set result ""

    set tNow [clock seconds]
    set tExpire [expr $tNow + $timeSpan]
    set tStart $tNow
    set found 0
    while {$tNow <= $tExpire} {
        if {[catch {
            set lines [exec wmctrl -l | grep "$title"]
        } errMsg]} {
            puts "failed to get window id: $errMsg"
            if {$timeSpan == 0} {
                return ""
            }
        } else {
            set lineList [split $lines \n]
            foreach line $lineList {
                set id [lindex $line 0]
                set tt [lrange $line 3 end]
                if {$tt == $title}  {
                    if {[lsearch -exact $exclusive $id] < 0} {
                        lappend result $id
                        incr found
                        puts "found adxv windowid=$id"
                    } else {
                        puts "skip $id, excluded in $exclusive"
                    }
                }
            }
            if {$found} {
                break
            }
        }
        set tNow [clock seconds]
        set dd [expr $tNow - $tStart]
        puts "time=$dd, still trying"
    }
    return $result
}
body GridAdxvView::startAdxv { filePath } {
    if {$adxvUseSocket} {
        return [startAdxvWithSocket $filePath]
    } else {
        return [startAdxvWithAutoload $filePath]
    }
}
body GridAdxvView::startAdxvWithSocket { filePath } {
    puts "trying wmctrl to search title Adxv"
    if {$m_adxvSock == ""} {
        set clientID [::dcss cget -clientID]
        if {![string is integer -strict $clientID]} {
            log_error no clientID found
            set m_adxvSock 8100
        } else {
            set m_adxvSock [expr 8100 + $clientID % 100]
        }
        log_warning using socket $m_adxvSock for adxv
        puts "using socket $m_adxvSock for adxv"
    }
    set wmctrlAvailable 1
    if {[catch {exec wmctrl -l} errMsg]} {
        log_error wmctrl failed: $errMsg
        log_error need wmctrl to search and raise adxv
        set wmctrlAvailable 0
    }
    set previousList ""
    if {$wmctrlAvailable} {
        set previousList [getWinIdListFromTitle "Adxv" 0]
    }
    set m_adxvWinId ""
    if {[catch {exec adxv -socket $m_adxvSock &} errMsg]} {
        log_error failed to start adxv: $errMsg
        return 0
    }
    if {!$wmctrlAvailable} {
        return 1
    }

    set m_adxvWinId [getWinIdListFromTitle "Adxv" 5 $previousList]
    puts "winid for Adxv: {$m_adxvWinId}"
    set ll [llength $m_adxvWinId]
    switch -exact -- $ll {
        0 {
            puts "strange, no window Id found for adxv"
            return 1
        }
        1 {
            puts "just one windwod with title=Adxv, that is it"
            #return 1
        }
    }
    if {[catch {socket localhost $m_adxvSock} sock]} {
        puts "open socket to adxv failed: $sock"
        return 0
    }
    puts $sock "load_image $filePath"
    flush $sock
    close $sock

    if {$ll == 1} {
        return 1
    }

    set candidateList [getWinIdListFromTitle "Adxv - $filePath" 5]
    puts "winid for Adxv - path: {$candidateList}"

    ### find the one.
    set result ""
    foreach id $m_adxvWinId {
        if {[lsearch -exact $candidateList $id] >= 0} {
            lappend result $id
        }
    }
    puts "intersection={$result}"
    if {[llength $result] != 1} {
        puts "strange, intersection={$result}"
        set m_adxvWinId [lindex $m_adxvWinId 0]
    } else {
        set m_adxvWinId $result
        puts "found it id=$result"
    }
    return 1
}
body GridAdxvView::startAdxvWithAutoload { filePath } {
    puts "trying wmctrl to search title Adxv"
    set wmctrlAvailable 1
    if {[catch {exec wmctrl -l} errMsg]} {
        log_error wmctrl failed: $errMsg
        log_error need wmctrl to search and raise adxv
        set wmctrlAvailable 0
    }
    ### prepare
    if {[catch {open $m_adxvXformPath w} fh]} {
        log_error failed to open adxv XFORMSTATUSFILE $m_adxvXformPath: $fh
        return 0
    }
    incr m_adxvXformCounter
    puts $fh "$m_adxvXformCounter $filePath"
    close $fh

    set previousList ""
    set title "Adxv - $filePath"
    if {$wmctrlAvailable} {
        set previousList [getWinIdListFromTitle $title 0]
    }
    set m_adxvWinId ""

    set ::env(XFORMSTATUSFILE) $m_adxvXformPath
    if {[catch {exec adxv -autoload &} errMsg]} {
        log_error failed to start adxv: $errMsg
        return 0
    }
    if {!$wmctrlAvailable} {
        return 1
    }

    set m_adxvWinId [getWinIdListFromTitle $title 5 $previousList]
    puts "winid for Adxv: {$m_adxvWinId}"
    set ll [llength $m_adxvWinId]
    switch -exact -- $ll {
        0 {
            puts "strange, no window Id found for adxv"
            return 1
        }
        1 {
            puts "just one windwod with title=Adxv, that is it"
            return 1
        }
        default {
            puts "more than one: {$m_adxvWinId}"
            set m_adxvWinId [lindex $m_adxvWinId 0]
        }
    }
    return 1
}
body GridAdxvView::checkAdxvRunning { } {
    if {$adxvUseSocket} {
        set adxvCmd "adxv -socket $m_adxvSock"
    } else {
        set adxvCmd "adxv -autoload"
    }

    set myPid [pid]
    if {[catch {exec ps --ppid $myPid -o cmd=} myList]} {
        puts "ps failed: $myList"
        return 0
    }
    set myList [split $myList \n]
    foreach cmd $myList {
        puts "checking cmd=$cmd"
        if {$cmd == $adxvCmd} {
            return 1
        }
    }
    puts "adxv not running"
    return 0
}
body GridAdxvView::displayFile { path {focus 1}} {
    if {![checkAdxvRunning]} {
        puts "trying to start adxv"
        set m_adxvWinId ""
        if {![startAdxv $path]} {
            return
        }
    } else {
        if {$adxvUseSocket} {
            if {[catch {socket localhost $m_adxvSock} sock]} {
                log_error failed to open socket to adxv: $sock
                puts "failed to open socket: $sock "
                return
            }
            puts "load_image $path"
            puts $sock "load_image $path"
            flush $sock
            close $sock
        } else {
            puts "load_image $path into $m_adxvXformPath"
            if {[catch {open $m_adxvXformPath w} fh]} {
                log_error failed to open XFORMSTATUSFILE $m_adxvXformPath: $fh
                return
            }
            incr m_adxvXformCounter
            puts $fh "$m_adxvXformCounter $path"
            flush $fh
            close $fh
            puts "$m_adxvXformCounter $path"
        }
    }
    set m_fileDisplayed $path

    if {!$focus || $m_adxvWinId == ""} return
    puts "then raise it with id=$m_adxvWinId"
    if {[catch {exec wmctrl -i -a $m_adxvWinId} errMsg]} {
        puts "failed to raild adxv window: $errMsg"
    }
}

class GridStrategyView {
    inherit ::itk::Widget DCS::Component

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method start { num } {
        set myD [dict create]
        foreach name {directory prefix distance beam_stop \
        beam_width beam_height collimator} {
            set v [dict get $m_d_userSetup $name]
            dict set myD $name $v
        }
        puts "input: [$m_strInput getContents]"
        puts "attenuation=[$itk_component(attenuation) get]"
        puts "num images=$num"
        $m_objMultiCrystalStrategy startOperation calculate $num $myD
    }

    public method newTop { } {
        $m_objMultiCrystalStrategy startOperation new_top
    }

    public method setField { name value } {
        ## more control and flexible than direct string change.
        $m_objStrategySoftOnly startOperation set_field $name $value
    }

    public method update { } {
        #set v [lindex [::device::attenuation getScaledPosition] 0]
        #set v [expr $v + 0.0001]
        ###### attenuation $v \

        ### to be safe, we will only update phi range.
        ### attenuation will be changed from stringView directly.
        ### This is required by Aina to prevent user mess up with it.

        $m_objStrategySoftOnly startOperation set_field \
        phi_range [::gCurrentGridGroup getCurrentGridInputPhiRange]
    }
    public method applyPhi { } {
        set v [lindex [$itk_component(stgStartPhi) get] 0]

        if {![string is double -strict $v]} {
            puts "bad start_phi, not a number"
            return
        }

        set stgContents [$m_strResult getContents]

        set expParam \
        [gCurrentGridGroup setupCurrentGridExposure start_angle $v]

        lappend expParam strategy_info $stgContents

        set param [dict create by_exposure_setup 0]
        if {![gCurrentGridGroup adjustCurrentGrid $param \
        $expParam]} {
            log_error exposure setup must adjust with image display.
        } else {
            dict set stgContents message "Copied to Crystal Setup"
            $m_strResult sendContentsToServer $stgContents
        }

    }
    public method applyModify { } {
        set range [$itk_component(modify_range) get]

        set top    [$itk_component(gridTopDir) get]
        set matrix [$itk_component(gridMatrix) get]
        set part   [$itk_component(gridPartNum) get]

        set argument [dict create \
        TOP_DIR $top \
        MATRIX  $matrix \
        PART    $part \
        RANGES  $range]

        eval $m_objStrategySoftOnly startOperation correct_range $argument
    }
    public method applyModifyFromCrystal { } {
        set start [lindex [$itk_component(gridStartPhi) get] 0]
        set end   [lindex [$itk_component(gridEndPhi) get] 0]
        if {$start == "" || $end == "" || $start == $end} {
            set range [$itk_component(modify_range) get]
        } else {
            set range [list $start $end]
        }

        set top    [$itk_component(gridTopDir) get]
        set matrix [$itk_component(gridMatrix) get]
        set part   [$itk_component(gridPartNum) get]

        set argument [dict create \
        TOP_DIR $top \
        MATRIX  $matrix \
        PART    $part \
        RANGES  $range]

        eval $m_objStrategySoftOnly startOperation correct_range $argument
    }

    public method setMountAfterModify { v } {
        eval $m_objStrategySoftOnly startOperation \
        set_field auto_mount_after_modify $v
    }
    public method mountNext { } {
        $m_objSequence startOperation mount_next
    }

    public method deleteRange { } {
        set top    [$itk_component(gridTopDir) get]
        set matrix [$itk_component(gridMatrix) get]
        set part   [$itk_component(gridPartNum) get]

        set argument [dict create \
        TOP_DIR $top \
        MATRIX  $matrix \
        PART    $part \
        RANGES  {}]

        eval $m_objStrategySoftOnly startOperation correct_range $argument
    }
    public method refreshLatest { } {
        $m_objStrategySoftOnly startOperation refresh_latest
    }
    public method clearStrategy { } {
        $m_objGridGroupConfig startOperation modifyParameter \
        $m_groupId $m_gridId {strategy_info {}}
    }

    public method handleGridUpdate { - ready_ - contents_ - }
    public method handleCollectedUpdate { - ready_ - contents_ - }
    public method handleLatestUpdate { - ready_ - contents_ - }
    public method handleInputUpdate { - ready_ - contents_ - }

    public method getLatest { key } {
        if {[catch {dict get $m_ctsLatest $key} value]} {
            puts "getLatest $key faile: $value"
            set value ""
        }
        return $value
    }

    public method setDisplayLabel { name value } {
        puts "setDisplayLabel $name $value"

        switch -exact -- $name {
            stgStatus {
                if {$value == "ready"} {
                    set color #00a040
                } elseif {[string first ERROR $value] >= 0} {
                    set color red
                } else {
                    set color #d0d000
                }
                $itk_component($name) configure \
                -background $color \
                -text $value
            }
            stgMsg -
            stgTopDir -
            stgMatrix -
            stgStartPhi -
            stgEndPhi -
            stgPartNum {
                $itk_component($name) setValue $value 1
            }
        }
    }

    public method getStartPhi { } { return $m_startPhi }
    public method getEndPhi { } { return $m_endPhi }
    public method getPartID { } { return $m_partID }
    public method getTopDir { } { return $m_topDir }
    public method getMatrix { } { return $m_matrix }

    private method refreshDisplay { }

    private variable m_groupId -1
    private variable m_snapId -1
    private variable m_gridId -1
    private variable m_d_userSetup [dict create]

    private variable m_objMultiCrystalStrategy ""
    private variable m_objStrategySoftOnly ""
    private variable m_objGridGroupConfig ""
    private variable m_objSequence ""
    private variable m_strInput ""
    private variable m_strResult ""
    private variable m_strStatus ""
    private variable m_strLatest ""
    private variable m_ctsLatest ""
    private variable m_statusDisplay ""
    private variable m_startPhi 0
    private variable m_endPhi 0
    private variable m_partID -1
    private variable m_topDir invalid
    private variable m_matrix invalid
    private variable m_origBTBG ""

    private common PROMPT_WIDTH 15

    private common ENTRY_STATE normal

    constructor { args } {
        ::DCS::Component::constructor {
            start_phi {getStartPhi}
            end_phi   {getEndPhi}
            part_num  {getPartID}
            top_dir   {getTopDir}
            matrix    {getMatrix}
            latest_top_dir   {getLatest TOP_DIR}
            latest_matrix    {getLatest MATRIX}
            latest_part_num  {getLatest PART}
            latest_start_phi {getLatest START_PHI}
            latest_end_phi   {getLatest END_PHI}
        }
    } {
        set deviceFactory [::DCS::DeviceFactory::getObject]

        set m_objMultiCrystalStrategy \
        [$deviceFactory createOperation multiCrystalStrategy]

        set m_objStrategySoftOnly \
        [$deviceFactory createOperation multiCrystalStrategySoftOnly]

        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        set m_objSequence \
        [$deviceFactory createOperation sequence]

        set m_strInput  [$deviceFactory createString multiStrategy_input]
        set m_strResult [$deviceFactory createString multiStrategy_result]
        set m_strStatus [$deviceFactory createString multiStrategy_status]
        set m_strLatest [$deviceFactory createString multiCrystalLatestStrategy]

        $m_strInput createAttributeFromKey top_dir
        $m_strInput createAttributeFromKey space_group
        $m_strInput createAttributeFromKey phi_range
        $m_strInput createAttributeFromKey attenuation
        $m_strInput createAttributeFromKey num_part
        $m_strInput createAttributeFromKey auto_mount_after_modify
        $m_strInput createAttributeFromKey manual_range

        $m_strResult createAttributeFromKey stg_status status

        $m_strStatus createAttributeFromKey enable_calculate
        $m_strStatus createAttributeFromKey enable_modify

        itk_component add strategyInputFrame {
            ::iwidgets::labeledframe $itk_interior.inputF \
            -relief groove \
            -labeltext "Strategy Input" \
        } {
        }
        set inputSite [$itk_component(strategyInputFrame) childsite]

        itk_component add topDirFrame {
            frame $inputSite.topDirF
        } {
        }
        set topDirSite $itk_component(topDirFrame)

        itk_component add top_dir {
            DCS::Entry $topDirSite.dir \
            -state $ENTRY_STATE \
            -leaveSubmit 1 \
            -entryType rootDirectory \
            -entryWidth 80 \
            -entryJustify left \
            -entryMaxLength 128 \
            -promptText "Top Dir: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 1 \
            -reference "$m_strInput top_dir" \
            -onSubmit "$this setField top_dir %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        itk_component add new_top {
            DCS::Button $topDirSite.new \
            -text "New" \
            -command "$this newTop"
        } {
        }
        pack \
        $itk_component(top_dir) \
        -side left

        itk_component add attenuation {
            DCS::Entry $inputSite.attenuation \
            -state $ENTRY_STATE \
            -reference "::device::attenuation scaledPosition" \
            -showPrompt 1 \
            -promptText "Attenuation: " \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 10 \
            -units "%" \
            -unitsList "%" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -autoConversion 1 \
            -shadowReference 1 \
            -alterUpdateSubmit 0 \
            -alternateShadowReference "$m_strInput attenuation" \
            -onSubmit "$this setField attenuation %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        itk_component add update {
            DCS::Button $inputSite.new \
            -text "Update" \
            -command "$this update"
        } {
        }
        pack $itk_component(attenuation) $itk_component(update) -side left

        itk_component add space_group {
            DCS::Entry $inputSite.spaceGroup \
            -state $ENTRY_STATE \
            -leaveSubmit 1 \
            -entryType field \
            -entryWidth 20 \
            -entryJustify left \
            -entryMaxLength 100 \
            -promptText "SpaceGroup: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 1 \
            -reference "$m_strInput space_group" \
            -onSubmit "$this setField space_group %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }

        itk_component add phi_range {
            DCS::Entry $inputSite.phiRange \
            -promptText "Phi Range: " \
            -leaveSubmit 1 \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -shadowReference 1 \
            -alterUpdateSubmit 0 \
            -alternateShadowReference "$m_strInput phi_range" \
            -reference "::gCurrentGridGroup current_grid_input_phi_range" \
            -onSubmit "$this setField phi_range %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
        }
        grid $itk_component(topDirFrame) -row 0 -column 0 -columnspan 2 -sticky w
        grid $itk_component(space_group) -row 1 -column 0 -sticky w
        grid $itk_component(attenuation) -row 2 -column 0 -sticky w
        grid $itk_component(phi_range)   -row 3 -column 0 -sticky w

        grid $itk_component(update) -row 3 -column 1 -sticky w

        grid columnconfigure $inputSite 1 -weight 10

        $itk_component(update) addInput \
        "$m_strStatus enable_calculate 1 Disabled"


        itk_component add controlFrame {
            frame $itk_interior.controlF
        } {
        }
        set controlSite $itk_component(controlFrame)

        itk_component add startOne {
            DCS::Button $controlSite.one \
            -text "Start 1 Image Strategy" \
            -command "$this start 1" \
        } {
        }
        itk_component add startTwo {
            DCS::Button $controlSite.two \
            -text "Start 2 Image Strategy" \
            -command "$this start 2" \
        } {
        }
        label $controlSite.l0 \
        -text "Status:" \
        -width $PROMPT_WIDTH \
        -anchor e \
        -justify right

        itk_component add stgStatus {
            label $controlSite.stgStatus \
            -justify left \
            -relief sunken \
            -background tan \
            -width 30 \
            -text status
        } {
        }

        itk_component add stgMsg {
            DCS::Entry $controlSite.topMsg \
            -state labeled \
            -promptText "Message:" \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 30 \
            -entryJustify left \
            -entryMaxLength 1280 \
            -showUnits 0 \
            -entryType string \
            -shadowReference 0 \
        } {
        }
        $itk_component(startOne) addInput \
        "$m_strStatus enable_calculate 1 Disabled"
        $itk_component(startTwo) addInput \
        "$m_strStatus enable_calculate 1 Disabled"

        grid $itk_component(startOne)   -row 0 -column 0 -sticky w
        grid $itk_component(startTwo)   -row 1 -column 0 -sticky w
        grid $controlSite.l0             -row 0 -column 1 -sticky e
        grid $itk_component(stgStatus)  -row 0 -column 2 -sticky w
        grid $itk_component(stgMsg)     -row 1 -column 1 -columnspan 2 -sticky w

        grid columnconfig $controlSite 2 -weight 10

        itk_component add resultFrame {
            ::iwidgets::labeledframe $itk_interior.resultF \
            -labeltext "Strategy Calculation Results"
        } {
        }
        set resultSite [$itk_component(resultFrame) childsite]
        set m_statusDisplay [DCS::StringDictDisplayBase ::\#auto $this]

        set displayLabelList [list \
        stgStatus   status \
        stgMsg      message \
        stgTopDir   top_dir \
        stgPartNum  part_num \
        stgMatrix   matrix \
        stgStartPhi start_phi \
        stgEndPhi   end_phi \
        ]

        itk_component add stgTopDir {
            DCS::Entry $resultSite.topDir \
            -state labeled \
            -promptText "Top Dir:" \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 30 \
            -entryJustify right \
            -entryMaxLength 1280 \
            -showUnits 0 \
            -entryType field \
            -shadowReference 0 \
        } {
        }
        itk_component add stgMatrix {
            DCS::Entry $resultSite.matrix \
            -state labeled \
            -promptText "Matrix:" \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 30 \
            -entryJustify left \
            -entryMaxLength 128 \
            -showUnits 0 \
            -entryType field \
            -shadowReference 0 \
        } {
        }
        itk_component add stgStartPhi {
            DCS::Entry $resultSite.startPhi \
            -state labeled \
            -promptText "Start Phi:" \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 8 \
            -entryType float \
            -entryJustify right \
            -decimalPlaces 1 \
            -units "deg" \
            -shadowReference 0 \
        } {
        }
        itk_component add stgEndPhi {
            DCS::Entry $resultSite.endPhi \
            -state labeled \
            -promptText "End Phi:" \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 8 \
            -entryType float \
            -entryJustify right \
            -decimalPlaces 1 \
            -units "deg" \
            -shadowReference 0 \
        } {
        }
        itk_component add stgPartNum {
            DCS::Entry $resultSite.partNum \
            -state labeled \
            -promptText "Part ID:" \
            -promptWidth $PROMPT_WIDTH \
            -showUnits 0 \
            -entryWidth 8 \
            -entryType int \
            -entryJustify right \
            -shadowReference 0 \
        } {
        }
        itk_component add gridTopDir {
            DCS::Entry $resultSite.gridTtopDir \
            -state labeled \
            -showPrompt 0 \
            -entryWidth 30 \
            -entryJustify right \
            -entryMaxLength 1280 \
            -showUnits 0 \
            -entryType field \
            -shadowReference 0 \
        } {
        }
        itk_component add gridMatrix {
            DCS::Entry $resultSite.gridMatrix \
            -state labeled \
            -showPrompt 0 \
            -entryWidth 30 \
            -entryJustify left \
            -entryMaxLength 128 \
            -showUnits 0 \
            -entryType field \
            -shadowReference 0 \
        } {
        }
        itk_component add gridStartPhi {
            DCS::Entry $resultSite.gridStartPhi \
            -state labeled \
            -showPrompt 0 \
            -entryWidth 8 \
            -entryType float \
            -entryJustify right \
            -decimalPlaces 1 \
            -units "deg" \
            -shadowReference 0 \
        } {
        }
        itk_component add gridEndPhi {
            DCS::Entry $resultSite.gridEndPhi \
            -state labeled \
            -showPrompt 0 \
            -entryWidth 8 \
            -entryType float \
            -entryJustify right \
            -decimalPlaces 1 \
            -units "deg" \
            -shadowReference 0 \
        } {
        }
        itk_component add gridPartNum {
            DCS::Entry $resultSite.gridPartNum \
            -state labeled \
            -showPrompt 0 \
            -showUnits 0 \
            -entryWidth 8 \
            -entryType int \
            -entryJustify right \
            -shadowReference 0 \
        } {
        }
        itk_component add latestTopDir {
            DCS::Entry $resultSite.latestTtopDir \
            -state labeled \
            -showPrompt 0 \
            -entryWidth 30 \
            -entryJustify right \
            -entryMaxLength 1280 \
            -showUnits 0 \
            -entryType field \
            -shadowReference 1 \
        } {
        }
        itk_component add latestMatrix {
            DCS::Entry $resultSite.latestMatrix \
            -state labeled \
            -showPrompt 0 \
            -entryWidth 30 \
            -entryJustify left \
            -entryMaxLength 128 \
            -showUnits 0 \
            -entryType field \
            -shadowReference 1 \
        } {
        }
        itk_component add latestStartPhi {
            DCS::Entry $resultSite.latestStartPhi \
            -state labeled \
            -showPrompt 0 \
            -entryWidth 8 \
            -entryType float \
            -entryJustify right \
            -decimalPlaces 1 \
            -units "deg" \
            -shadowReference 1 \
        } {
        }
        itk_component add latestEndPhi {
            DCS::Entry $resultSite.latestEndPhi \
            -state labeled \
            -showPrompt 0 \
            -entryWidth 8 \
            -entryType float \
            -entryJustify right \
            -decimalPlaces 1 \
            -units "deg" \
            -shadowReference 1 \
        } {
        }
        itk_component add latestPartNum {
            DCS::Entry $resultSite.latestPartNum \
            -state labeled \
            -showPrompt 0 \
            -showUnits 0 \
            -entryWidth 8 \
            -entryType int \
            -entryJustify right \
            -shadowReference 1 \
        } {
        }

        $m_statusDisplay setLabelList $displayLabelList

        $m_statusDisplay configure -stringName $m_strResult

        itk_component add applyPhi {
            DCS::Button $resultSite.apply \
            -text "Copy To Current Crystal" \
            -command "$this applyPhi"
        } {
        }
        itk_component add clearPhi {
            DCS::Button $resultSite.clear \
            -text "Remove From Current Crystal" \
            -command "$this clearStrategy"
        } {
        }

        $itk_component(applyPhi) addInput \
        "$m_strResult stg_status ready {Strategy not ready}"

        itk_component add auto_mount {
            DCS::Checkbutton $resultSite.autoMount \
            -shadowReference 1 \
            -reference "$m_strInput auto_mount_after_modify" \
            -text "Mount Next After Modify" \
            -command "$this setMountAfterModify %s" \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
        } {
        }

        ### this will follow manual_range in input, which will be updated
        ### by calculate.
        itk_component add modify_range {
            DCS::Entry $resultSite.range \
            -leaveSubmit 1 \
            -showPrompt 0 \
            -showUnits 0 \
            -entryWidth 20 \
            -entryMaxLength 120 \
            -entryType string \
            -entryJustify left \
            -shadowReference 1 \
            -reference "$m_strInput manual_range" \
            -onSubmit "$this setField manual_range {%s}" \
        } {
        }
        itk_component add mount_next {
            DCS::Button $resultSite.mount \
            -text "Mount Next Crystal" \
            -command "$this mountNext" \
        } {
        }
        itk_component add copy_from_crystal {
            DCS::Button $resultSite.autoModify \
            -text "Apply Auto Modify" \
            -command "$this applyModifyFromCrystal" \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
        } {
        }
        itk_component add apply_modify {
            DCS::Button $resultSite.manualModify \
            -text "Manual Modify" \
            -command "$this applyModify" \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
        } {
        }
        itk_component add delete_range {
            DCS::Button $resultSite.deleteStg \
            -text "Delete Strategy Part" \
            -command "$this deleteRange" \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
        } {
        }
        itk_component add refresh {
            DCS::Button $resultSite.refresh \
            -text "Refresh" \
            -command "$this refreshLatest" \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
        } {
        }

        label $resultSite.cHeader0 -text "Result of Calculation"
        label $resultSite.cHeader1 -text "Current Crystal"
        label $resultSite.cHeader2 -text "Latest"

        set m_origBTBG [$itk_component(delete_range) cget -background]
        grid $resultSite.cHeader0 -column 0 -row 0 -columnspan 2 -sticky news
        grid $resultSite.cHeader1 -column 2 -row 0 -sticky news
        grid $resultSite.cHeader2 -column 3 -row 0 -sticky nws -columnspan 2


        grid $itk_component(stgTopDir)  -column 0 -row 3 -columnspan 2 -sticky w
        grid $itk_component(stgMatrix)  -column 0 -row 4 -columnspan 2 -sticky w
        grid $itk_component(stgPartNum) -column 0 -row 5 -columnspan 2 -sticky w
        grid $itk_component(stgStartPhi) -column 0 -row 6 -columnspan 2 -sticky w
        grid $itk_component(stgEndPhi)  -column 0 -row 7 -columnspan 2 -sticky w

        grid $itk_component(gridTopDir)   -column 2 -row 3 -sticky w
        grid $itk_component(gridMatrix)   -column 2 -row 4 -sticky w
        grid $itk_component(gridPartNum)  -column 2 -row 5 -sticky w
        grid $itk_component(gridStartPhi) -column 2 -row 6 -sticky w
        grid $itk_component(gridEndPhi)   -column 2 -row 7 -sticky w

        grid $itk_component(latestTopDir)   -column 3 -row 3 -sticky w -columnspan 2
        grid $itk_component(latestMatrix)   -column 3 -row 4 -sticky w -columnspan 2
        grid $itk_component(latestPartNum)  -column 3 -row 5 -sticky w -columnspan 2
        grid $itk_component(latestStartPhi) -column 3 -row 6 -sticky w -columnspan 2
        grid $itk_component(latestEndPhi)   -column 3 -row 7 -sticky w -columnspan 2


        grid $itk_component(applyPhi)   -column 0 -row 8 -columnspan 2 -sticky e
        grid $itk_component(clearPhi)   -column 0 -row 9 -columnspan 2 -sticky e

        grid $itk_component(auto_mount)         -row 8 -column 2 -sticky w
        grid $itk_component(copy_from_crystal)  -row 9 -column 2 -sticky w
        grid $itk_component(delete_range)       -row 10 -column 2 -sticky w
        grid $itk_component(mount_next)         -row 11 -column 2 -sticky w

        grid $itk_component(modify_range)       -row 8 -column 3 -sticky w
        grid $itk_component(apply_modify)       -row 9 -column 3 -sticky w
        grid $itk_component(refresh)            -row 10 -column 3 -sticky w

        grid columnconfigure $resultSite 3 -weight 10

        itk_component add log {
            DCS::DeviceLog $itk_interior.log
        } {
        }

        $itk_component(log) addDeviceObjs \
        ::device::multiCrystalStrategy \
        ::device::multiCrystalCalcStrategy \
        ::device::multiCrystalModifyStrategy \
        

        pack $itk_component(strategyInputFrame) -side top -fill x
        pack $itk_component(controlFrame) -side top -fill x
        pack $itk_component(resultFrame) -side top -fill x
        pack $itk_component(log) -side top -expand 1 -fill both
        
        eval itk_initialize $args
        announceExist

        if {[gCurrentGridGroup getId] < 0} {
            gCurrentGridGroup switchGroupNumber 0 1
        }
        gCurrentGridGroup register $this current_grid handleGridUpdate
        gCurrentGridGroup register $this current_grid_collected_phi_range handleCollectedUpdate

        $itk_component(stgStartPhi) configure \
        -reference "$this start_phi"
        $itk_component(stgEndPhi) configure \
        -reference "$this end_phi"
        $itk_component(stgPartNum) configure \
        -reference "$this part_num"
        $itk_component(stgTopDir) configure \
        -reference "$this top_dir"
        $itk_component(stgMatrix) configure \
        -reference "$this matrix"

        $itk_component(gridStartPhi) configure \
        -reference "$this latest_start_phi"
        $itk_component(gridEndPhi) configure \
        -reference "$this latest_end_phi"
        $itk_component(gridPartNum) configure \
        -reference "$this latest_part_num"
        $itk_component(gridTopDir) configure \
        -reference "$this latest_top_dir"
        $itk_component(gridMatrix) configure \
        -reference "$this latest_matrix"

        $itk_component(latestStartPhi) configure \
        -reference "$this latest_start_phi"
        $itk_component(latestEndPhi) configure \
        -reference "$this latest_end_phi"
        $itk_component(latestPartNum) configure \
        -reference "$this latest_part_num"
        $itk_component(latestTopDir) configure \
        -reference "$this latest_top_dir"
        $itk_component(latestMatrix) configure \
        -reference "$this latest_matrix"

        $m_strInput  register $this contents handleInputUpdate
        $m_strLatest register $this contents handleLatestUpdate
    }
    destructor {
        gCurrentGridGroup unregister $this current_grid handleGridUpdate
        gCurrentGridGroup unregister $this current_grid_collected_phi_range handleCollectedUpdate
        $m_strInput       unregister $this contents     handleInputUpdate
        $m_strLatest      unregister $this contents     handleLatestUpdate
    }
}
body GridStrategyView::handleInputUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    if {[catch {dict get $contents_ auto_mount_after_modify} mountEnabled]} {
        set mountEnabled 0
    }
    if {$mountEnabled == "1"} {
        set bg yellow
    } else {
        set bg $m_origBTBG
    }
    foreach name {copy_from_crystal apply_modify delete_range} {
        $itk_component($name) configure -background $bg
    }
}
body GridStrategyView::handleLatestUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }

    if {[catch {dict get $contents_ STRATEGY} m_ctsLatest]} {
        puts "latest strategy update failed, no STRATEGY: $m_ctsLatest"
        set m_ctsLatest [dict create]
    }
    updateRegisteredComponents latest_top_dir
    updateRegisteredComponents latest_matrix
    updateRegisteredComponents latest_part_num
    updateRegisteredComponents latest_start_phi
    updateRegisteredComponents latest_end_phi
}
body GridStrategyView::handleGridUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    set m_groupId [gCurrentGridGroup getId]
    set m_snapId  [gCurrentGridGroup getCurrentSnapshotId]
    set m_gridId  [gCurrentGridGroup getCurrentGridId]

    set ll [llength $contents_]
    if {$ll < 6} {
        set m_d_userSetup [gCurrentGridGroup getDefaultUserSetup forLCLSCrystal]
    } else {
        set m_d_userSetup [lindex $contents_ 5]
    }
    refreshDisplay
}
body GridStrategyView::handleCollectedUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    set start ""
    set end ""
    foreach {start end} $contents_ break
    $itk_component(gridStartPhi) setValue $start 1
    $itk_component(gridEndPhi)   setValue $end 1
}
body GridStrategyView::refreshDisplay { } {
    set shape   [dict get $m_d_userSetup shape]
    if {[catch {dict get $m_d_userSetup for_lcls} forLCLS]} {
        set forLCLS 0
    }

    puts "refreshDisplay shape=$shape forLCLS=$forLCLS"

    if {$shape != "crystal"} {
        puts "skip, not crystal"
        return
    }

    set v      [dict get $m_d_userSetup delta]
    set fStart [dict get $m_d_userSetup start_frame]
    set fEnd   [dict get $m_d_userSetup end_frame]

    if {[catch {dict get $m_d_userSetup num_column} nNode]} {
        set nNode 1
    }
    if {$fStart < 1} {
        set fSTart 1
    }
    if {$fEnd < $fStart} {
        set fEnd $fStart
    }
    if {$nNode < 1} {
        set nNode 1
    }

    if {$forLCLS} {
        set phiPerNode [dict get $m_d_userSetup node_angle]
        set phiRange [expr $phiPerNode * ($nNode - 1)]
    } else {
        set phiRange [expr $v * ($fEnd - $fStart + 1)]
    }

    set m_startPhi [dict get $m_d_userSetup start_angle]
    set m_endPhi [expr $m_startPhi + $phiRange]
    if {[catch {dict get $m_d_userSetup strategy_info} stgInfo]} {
        set m_partID -1
        set m_topDir "invalid"
        set m_matrix "invalid"
    } else {
        if {[catch {dict get $stgInfo part_num} m_partID]} {
            set m_partID -1
        }
        if {[catch {dict get $stgInfo top_dir} m_topDir]} {
            set m_topDir "invalid"
        }
        if {[catch {dict get $stgInfo matrix} m_matrix]} {
            set m_matrix "invalid"
        }
    }

    $itk_component(gridTopDir) setValue $m_topDir 1
    $itk_component(gridMatrix) setValue $m_matrix 1
    $itk_component(gridPartNum) setValue $m_partID 1

    updateRegisteredComponents start_phi
    updateRegisteredComponents end_phi
    updateRegisteredComponents part_num 
    updateRegisteredComponents top_dir
    updateRegisteredComponents matrix
}
#### like ItemCrystal but no GUI
class GridAbstractCrystal {

    protected variable m_oOrig "0 0 0 0 0.75 1.0 1 1 0.5 0.5"
    ### These are from original.  They need translate when
    ### the holder view point changes.
    ### most of their units are microns.
    protected variable m_oCenterX -500.0
    protected variable m_oCenterY -500.0
    ### on local unrotated frame.
    protected variable m_oHalfWidth -100.0
    protected variable m_oHalfHeight -100.0

    protected variable m_oGridCenterX -500.0
    protected variable m_oGridCenterY -500.0
    ### these are always horz and vert to the displayView
    protected variable m_oCellWidth -50.0
    protected variable m_oCellHeight -50.0
    protected variable m_extraUserParameters ""

    protected variable m_numRow 1
    protected variable m_numCol 1
    protected variable m_nodeList ""

    public variable m_forLCLS 0

    ###ItemCrystal
    private variable m_positionList ""
    private variable m_nodePositionList ""
    private variable m_nodeList4XFELPhi ""
    private variable m_startAngle 0.0
    private variable m_delta  1.0
    private variable m_numFrame  180
    private variable m_beamWidth  10.0
    private variable m_beamHeight 10.0
    private variable m_nodeAngle 1.0
    private variable m_d_strategyInfo [dict create]
    private variable m_enableStrategy 0
    private variable m_collectPhiOscAtMiddle 0
    private variable m_collectPhiOscAtEnd 0
    private variable m_collectPhiOscAtAll 0

    ### exact copy from ItemCrystal
    protected method updateFromParameter { parameter {must_have 1} } {
        if {$parameter == ""} return

        set mustHaveList [list \
        delta \
        start_angle start_frame end_frame \
        collimator beam_width beam_height]

        if {$must_have} {
            set numError 0
            foreach name $mustHaveList {
                if {![dict exists $parameter $name]} {
                    log_error no $name in parameter
                    incr numError
                }
            }
            if {$numError > 0} {
                puts "parameter=$parameter"
                return
            }
        }
        if {[dict exists $parameter start_angle]} {
            set m_startAngle [dict get $parameter start_angle]
        }
        if {[dict exists $parameter delta]} {
            set m_delta [dict get $parameter delta]
        }
        if {[dict exists $parameter start_frame] \
        &&  [dict exists $parameter end_frame]} {
            set nStart     [dict get $parameter start_frame]
            set nEnd       [dict get $parameter end_frame]
            set m_numFrame [expr $nEnd - $nStart + 1]
        }

        if {[dict exists $parameter node_angle]} {
            set m_nodeAngle [dict get $parameter node_angle]
        }

        if {[dict exists $parameter collimator] \
        &&  [dict exists $parameter beam_width] \
        &&  [dict exists $parameter beam_height]} {
            set collimator   [dict get $parameter collimator]
            set use 0
            set index -1
            set bw 2.0
            set bh 2.0
            foreach {use index bw bh} $collimator break
            if {$use == "1"} {
                set m_beamWidth  [expr 1000.0 * $bw]
                set m_beamHeight [expr 1000.0 * $bh]
            } else {
                puts "beam size"
                set m_beamWidth  [dict get $parameter beam_width]
                set m_beamHeight [dict get $parameter beam_height]
            }
        }
        if {[dict exists $parameter strategy_info]} {
            set m_d_strategyInfo [dict get $parameter strategy_info]
        } else {
            set m_d_strategyInfo [dict create]
        }

        if {[dict exists $parameter strategy_enable]} {
            set m_enableStrategy [dict get $parameter strategy_enable]
        } else {
            set m_enableStrategy 0
        }
        if {!$m_forLCLS} {
            set m_enableStrategy 0
        }
        if {[dict exists $parameter phi_osc_middle]} {
            set m_collectPhiOscAtMiddle [dict get $parameter phi_osc_middle]
        } else {
            set m_collectPhiOscAtMiddle 0
        }
        if {[dict exists $parameter phi_osc_end]} {
            set m_collectPhiOscAtEnd [dict get $parameter phi_osc_end]
        } else {
            set m_collectPhiOscAtEnd 0
        }
        if {[dict exists $parameter phi_osc_all]} {
            set m_collectPhiOscAtAll [dict get $parameter phi_osc_all]
        } else {
            set m_collectPhiOscAtAll 0
        }
    }

    public method getItemInfo { }

    public method setup { origList } {
        set m_positionList $origList
        set m_oOrig [lindex $origList 0]

        set m_oCellWidth  [gCurrentGridGroup getDefaultCellWidth]
        set m_oCellHeight [gCurrentGridGroup getDefaultCellHeight]

        if {$m_forLCLS} {
            set pp forLCLSCrystal
        } else {
            set pp forCrystal
        }
        updateFromParameter [gCurrentGridGroup getDefaultUserSetup $pp]

        regenerateOrig
    }
    private method regenerateOrig { }
    private method findPositionAlongLine { z direction }
    constructor { } {
    }
}
## exact copy from ItemCrystal
body GridAbstractCrystal::regenerateOrig { } {
    set firstP [lindex $m_positionList 0]
    foreach {x0 y0 z0} $firstP break
    puts "regenerateOrig first=$firstP" 

    set minX $x0
    set maxX $x0
    set minY $y0
    set maxY $y0
    set minZ $z0
    set maxZ $z0
    foreach pos $m_positionList {
        foreach {x y z} $pos break
        if {$x < $minX} {
            set minX $x
        } elseif {$x > $maxX} {
            set maxX $x
        }
        if {$y < $minY} {
            set minY $y
        } elseif {$y > $maxY} {
            set maxY $y
        }
        if {$z < $minZ} {
            set minZ $z
        } elseif {$z > $maxZ} {
            set maxZ $z
        }
    }
    set cx [expr 0.5 * ($minX + $maxX)]
    set cy [expr 0.5 * ($minY + $maxY)]
    set cz [expr 0.5 * ($minZ + $maxZ)]
    set rx [expr $maxX - $minX]
    set ry [expr $maxY - $minY]
    set rz [expr $maxZ - $minZ]

    puts "center $cx $cy $cz"

    set omega [::device::gonio_omega cget -scaledPosition]
    set ca [expr $omega + $m_startAngle]
    puts "startAngle=$m_startAngle, omega=$omega"

    set m_oOrig [lreplace $m_oOrig 0 2 $cx $cy $cz]
    ### saveShape
    foreach {m_oCenterX m_oCenterY} \
    [calculateSamplePositionOnVideo $m_oOrig $m_oOrig 1] break
    set m_uCenterX     $m_oCenterX
    set m_uCenterY     $m_oCenterY
    set m_oGridCenterX $m_oCenterX
    set m_oGridCenterY $m_oCenterY
    set m_uGridCenterX $m_oCenterX
    set m_uGridCenterY $m_oCenterY
    puts " center at video: $m_oCenterX $m_oCenterY"
    puts "orig=$m_oOrig"

    puts "range $rx $ry $rz"
    ## saveSize
    set m_oHalfWidth  [expr 500.0 * $rz]
    set m_oHalfHeight [expr 500.0 * sqrt($rx * $rx + $ry * $ry)]

    ##### node position list
    set m_nodePositionList ""
    set m_nodeList ""
    set m_nodeList4XFELPhi ""
    if {$m_oCellWidth == 0} {
        log_error cell width ==0, skip node positions.
        return
    }
    set stepZ [expr abs($m_oCellWidth / 1000.0)]
    set bw [expr $m_beamWidth / 1000.0]
    set m_numRow 1

    if {$rz - $bw < $stepZ} {
        set m_numCol 1
        set nPos [list $cx $cy $cz $ca]
        lappend m_nodePositionList $nPos
        lappend m_nodeList "S"
        lappend m_nodeList4XFELPhi "N"
        return
    }
    ### at least 2 shots.
    ### rz - bw >= stepZ
    set m_numCol [expr int(($rz - $bw) / $stepZ) + 1]

    #set stepZ [expr ($rz - $m_numCol * $bw) / ($m_numCol - 1)]
    ### same as above
    set stepZ [expr ($rz - $bw) / ($m_numCol - 1)]
    set halfGridWidth [expr 0.5 * $m_numCol * $stepZ]

    ### this is to decide whether already from tip
    ### or follow user click.
    #if {$cz > $z0} {
        set startZ [expr $cz - $halfGridWidth + 0.5 * $stepZ]
    #} else {
    #    set startZ [expr $cz + $halfGridWidth - 0.5 * $stepZ]
    #    set stepZ [expr -1 * $stepZ]
    #}

    if {!$m_forLCLS} {
        set m_enableStrategy 0
    }

    if {$m_enableStrategy == "1"} {
        set numNode4Phi [expr $m_numCol - 1]
    } else {
        set numNode4Phi $m_numCol
    }

    ### find out phiPerNode
    if {$m_forLCLS} {
        puts "for LCLS, m_nodeAngle=$m_nodeAngle"
        set endAngle [expr $m_startAngle + ($numNode4Phi - 1) * $m_nodeAngle]
        dict set m_extraUserParameters end_angle $endAngle
        puts "for LCLS, set extra end_angle to $endAngle"
    } else {
        set numFrmPerNode [expr int(ceil(double($m_numFrame) / $numNode4Phi))]
        set m_nodeAngle    [expr $m_delta * $numFrmPerNode]
        puts "not for LCLS, m_nodeAngle=$m_nodeAngle"
        puts "delta=$m_delta, framePerNode=$numFrmPerNode"
        dict set m_extraUserParameters node_angle $m_nodeAngle
        dict set m_extraUserParameters node_frame $numFrmPerNode
    }

    set m_nodeList4XFELPhi [string repeat "N " $m_numCol]

    if {$m_enableStrategy == "1"} {
        set nZ $startZ
        set nA $ca
        ## here only needs sign of stepZ as direction.
        set nPos [findPositionAlongLine $nZ $stepZ]
        lappend nPos $nA
        lappend m_nodePositionList $nPos
        ### flag skip first node in normal collecting.
        lappend m_nodeList "N"

        for {set i 1} {$i < $m_numCol} {incr i} {
            set nZ [expr $startZ + $i * $stepZ]
            ## here nA is one step lag 
            set nA [expr $ca + ($i - 1) * $m_nodeAngle]
            ## here only needs sign of stepZ as direction.
            set nPos [findPositionAlongLine $nZ $stepZ]
            lappend nPos $nA
            lappend m_nodePositionList $nPos
            lappend m_nodeList "S"
        }
    } else {
        for {set i 0} {$i < $m_numCol} {incr i} {
            set nZ [expr $startZ + $i * $stepZ]
            set nA [expr $ca + $i * $m_nodeAngle]
            ## here only needs sign of stepZ as direction.
            set nPos [findPositionAlongLine $nZ $stepZ]
            lappend nPos $nA
            lappend m_nodePositionList $nPos
            lappend m_nodeList "S"
        }
    }
    if {$m_collectPhiOscAtMiddle} {
        set ll [llength $m_nodeList4XFELPhi]
        set mm [expr $ll / 2]
        set m_nodeList4XFELPhi [lreplace $m_nodeList4XFELPhi $mm $mm 0]
    }
    if {$m_collectPhiOscAtEnd} {
        set m_nodeList4XFELPhi [lreplace $m_nodeList4XFELPhi end end 0]
    }
    if {$m_collectPhiOscAtAll} {
        set m_nodeList4XFELPhi [string repeat "0 " $m_numCol]
        if {$m_enableStrategy == "1"} {
            set m_nodeList4XFELPhi [lreplace $m_nodeList4XFELPhi 0 0 N]
        }
    }
}
body GridAbstractCrystal::findPositionAlongLine { z_ dir_ } {
    
    ###find which section to use.
    set sec -1
    foreach pos $m_positionList {
        incr sec
        set pZ [lindex $pos 2]
        if {$dir_ > 0} {
            if {$z_ <= $pZ} {
                break
            }
        } else {
            if {$z_ >= $pZ} {
                break
            }
        }
    }
    incr sec -1
    if {$sec < 0} {
        set sec 0
    }
    set p0 [lindex $m_positionList $sec]
    incr sec
    set p1 [lindex $m_positionList $sec]
    foreach {x0 y0 z0} $p0 break
    foreach {x1 y1 z1} $p1 break

    set dx [expr $x1 - $x0]
    set dy [expr $y1 - $y0]
    set dz [expr $z1 - $z0]
    set scaleX [expr double($dx) / $dz]
    set scaleY [expr double($dy) / $dz]

    set dz [expr $z_ - $z0]
    set dx [expr $scaleX * $dz]
    set dy [expr $scaleY * $dz]

    set x [expr $x0 + $dx]
    set y [expr $y0 + $dy]

    return [list $x $y $z_]
}

body GridAbstractCrystal::getItemInfo { } {
    set geo [dict create]
    dict set geo shape           crystal
    dict set geo angle           0.0
    dict set geo half_width      $m_oHalfWidth
    dict set geo half_height     $m_oHalfHeight
    dict set geo local_coords    ""
    dict set geo size_width      0.0
    dict set geo size_height     0.0
    dict set geo for_lcls        $m_forLCLS
    dict set geo center_x        $m_oCenterX
    dict set geo center_y        $m_oCenterY

    puts "abstract crystal info: for_lcls=$m_forLCLS"

    set grid [dict create]
    dict set grid type           horz
    dict set grid num_row        $m_numRow
    dict set grid num_column     $m_numCol
    dict set grid center_x       $m_oGridCenterX
    dict set grid center_y       $m_oGridCenterY
    dict set grid cell_width     [expr abs($m_oCellWidth)]
    dict set grid cell_height    [expr abs($m_oCellHeight)]

    set parameter $m_extraUserParameters

    ###ItemCrystal
    dict set geo  position_list $m_positionList

    dict set grid node_position_list $m_nodePositionList
    dict set grid node_list_for_phi  $m_nodeList4XFELPhi

    dict set parameter strategy_info    $m_d_strategyInfo
    dict set parameter strategy_enable  $m_enableStrategy
    dict set parameter phi_osc_middle   $m_collectPhiOscAtMiddle
    dict set parameter phi_osc_end      $m_collectPhiOscAtEnd
    dict set parameter phi_osc_all      $m_collectPhiOscAtAll

    return [list $m_oOrig $geo $grid $m_nodeList $parameter]
}

class PositionControlWidget {
    inherit ::itk::Widget

    itk_option define -camera camera Camera inline {
        if {$m_objZoom != ""} {
            $itk_component(zoomLow)  removeMotor $m_objZoom 0.0
            $itk_component(zoomMed)  removeMotor $m_objZoom 0.75
            $itk_component(zoomHigh) removeMotor $m_objZoom 1.0
            set m_objZoom ""
        }

        switch -exact -- $itk_option(-camera) {
            inline {
                set m_objZoom \
                [$m_deviceFactory getObjectName inline_camera_zoom]

                set m_opMoveFraction \
                [$m_deviceFactory createOperation inlineMoveSample]
            }
            sample {
                set m_objZoom \
                [$m_deviceFactory getObjectName camera_zoom]

                set m_opMoveFraction \
                [$m_deviceFactory createOperation moveSample]
            }
            default {
                log_error camera $itk_option(-camera) not supported
                puts "camera $itk_option(-camera) not supported"
            }
        }
        $itk_component(zoomLow)  addMotor $m_objZoom 0.0
        $itk_component(zoomMed)  addMotor $m_objZoom 0.75
        $itk_component(zoomHigh) addMotor $m_objZoom 1.0
    }
    itk_option define -purpose purpose Purpose grid {
        if {$itk_option(-purpose) == "forL614" \
        ||  $itk_option(-purpose) == "forPXL614"} {
            puts "in option, forL614 set step size to 0.8mm"
            setPadStep 800
        }
    }

    public method startFocusMove { dir } {
        if {$itk_option(-camera) == "inline"} {
            set sign 1
        } else {
            set sign -1
        }
        set stepSize [lindex [$itk_component(inPadStep) get] 0]
        if {$stepSize ==0} {
            return
        }
        set dd [expr $dir * $sign * $stepSize]
        $m_opStepFocus startOperation $itk_option(-camera) $dd
    }

    private method startStepMove { dir } {
        if {$itk_option(-camera) == "inline"} {
            set sign 1
        } else {
            set sign -1
        }
        set stepSize [lindex [$itk_component(inPadStep) get] 0]
        if {$stepSize ==0} {
            return
        }
        switch -exact -- $dir {
            left {
                set horz [expr -1 * $sign * $stepSize]
                set vert 0
            }
            right {
                set horz [expr $sign * $stepSize]
                set vert 0
            }
            up {
                set horz 0
                set vert $stepSize
            }
            down {
                set horz 0
                set vert [expr -1 * $stepSize]
            }
            default {
                return
            }
        }
        $m_opMoveDistance startOperation $itk_option(-camera) $horz $vert
    }

    public method padLeft { } {
        startStepMove left
    }
    public method padRight { } {
        startStepMove right
    }
    public method padUp { } {
        startStepMove up
    }
    public method padDown { } {
        startStepMove down
    }
    public method padFastLeft { } {
        if {$itk_option(-camera) == "inline"} {
            set dd -11200
        } else {
            set dd 11200
        }
        if {$itk_option(-purpose) == "forL614" \
        ||  $itk_option(-purpose) == "forPXL614"} {
            $m_opMoveDistance startOperation $itk_option(-camera) $dd 0
        } else {
            $m_opMoveFraction startOperation -0.5 0.0
        }
    }
    public method padFastRight { } {
        if {$itk_option(-camera) == "inline"} {
            set dd 11200
            if {$m_currentItemShape == "trap_array" \
            ||  $m_toolMode == "add_trap_array"} {
                puts "moving 16.850 mm"
                set dd 14850
            }
        } else {
            set dd -11200
            if {$m_currentItemShape == "trap_array" \
            ||  $m_toolMode == "add_trap_array"} {
                puts "moving -16.850 mm"
                set dd -14850
            }
        }
        if {$itk_option(-purpose) == "forL614" \
        ||  $itk_option(-purpose) == "forPXL614"} {
            $m_opMoveDistance startOperation $itk_option(-camera) $dd 0
        } else {
            $m_opMoveFraction startOperation 0.5 0.0
        }
    }
    public method setPadStep { s } {
        $itk_component(padStep) setValue $s 1
        $itk_component(inPadStep) setValue $s 1
    }

    public method rotatePhiStep { s } {
        set step [lindex [$itk_component(phiStep) get] 0]
        set step [expr ${s}1 * $step]

        $m_objPhi move by $step
    }
    public method zoomStep { s } {
        set curPos [lindex [$m_objZoom getScaledPosition] 0]
        set tgtPos [expr $curPos $s 0.1]

        ### honor limits even they are disabled.
        if {![$m_objZoom limits_ok tgtPos 1]} {
            if {abs($tgtPos - $curPos) < 0.001} {
                if {$s == "-"} {
                    log_error already at lower limit.
                } else {
                    log_error already at upper limit.
                }
                return
            }
            if {$s == "-"} {
                log_warning moving to lower limit: $tgtPos
            } else {
                log_warning moving to upper limit: $tgtPos
            }
        }

        $m_objZoom move to $tgtPos
    }

    public method handleCurrentItemShapeUpdate { - ready_ - shape_ - } {
        if {!$ready_} {
            set m_currentItemShape ""
        } else {
            set m_currentItemShape $shape_
        }
    }
    public method handleToolModeUpdate { - ready_ - mode_ - } {
        if {!$ready_} {
            set m_toolMode ""
        } else {
            set m_toolMode $mode_
        }
    }

    protected variable m_currentItemShape ""
    protected variable m_toolMode ""
    protected variable m_deviceFactory ""
    protected variable m_objPhi ""
    protected variable m_opMoveDistance ""
    protected variable m_opStepFocus ""
    protected variable m_opMoveFraction ""
    protected variable m_objZoom ""

    private common PHI_BUTTON_STEP_SIZE [::config getInt "phiButtonStepSize" 10]

    constructor { args } {
        set m_deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objPhi [$m_deviceFactory getObjectName gonio_phi]
        set m_opMoveDistance \
        [$m_deviceFactory createOperation moveSampleOnVideo]

        set m_opStepFocus [$m_deviceFactory createOperation moveSampleOutVideo]

        itk_component add zoomLabel {
            label $itk_interior.zoomLabel \
            -text "Select Zoom Level" \
            -font "helvetica -14 bold" \
        } {
        }
        itk_component add zoomFrame {
            frame $itk_interior.zoomFrame
        }
        set zoomSite $itk_component(zoomFrame)

        itk_component add zoomLow {
            DCS::MoveMotorsToTargetButton $zoomSite.zoomLow \
            -text "Low" \
            -width 2  \
            -background #c0c0ff \
            -activebackground #c0c0ff \
        } {
        }

        itk_component add zoomMed {
            DCS::MoveMotorsToTargetButton $zoomSite.zoomMed \
            -text "Med" \
            -width 2  \
            -background #c0c0ff \
            -activebackground #c0c0ff \
        } {
        }

        itk_component add zoomHigh {
            DCS::MoveMotorsToTargetButton $zoomSite.zoomHigh \
            -text "High" \
            -width 2 \
            -background #c0c0ff \
            -activebackground #c0c0ff \
        } {
        }
        itk_component add zoomMinus {
            ::DCS::ArrowButton $zoomSite.zoomMinus minus \
            -debounceTime 100  \
            -background #c0c0ff \
            -command "$this zoomStep -"
        } {
        }
        itk_component add zoomPlus {
            ::DCS::ArrowButton $zoomSite.zoomPlus plus \
            -debounceTime 100  \
            -background #c0c0ff \
            -command "$this zoomStep +"
        } {
        }
        pack $itk_component(zoomMinus) -side left
        pack $itk_component(zoomLow) -side left
        pack $itk_component(zoomMed) -side left
        pack $itk_component(zoomHigh) -side left
        pack $itk_component(zoomPlus) -side left

        ########### step size ###########
        itk_component add moveStepF {
            frame $itk_interior.msf
        } {
        }
        set mstepSite $itk_component(moveStepF)
        itk_component add moveSampleLabel {
            label $mstepSite.sampleLabel \
            -text "Move Sample" \
            -font "helvetica -14 bold" \
		}

        set padStepChoices [::config getStr "arrowPadStepSize"]
        if {$padStepChoices == ""} {
            set padStepChoices "5 10 15 20 50 100 200"
        }

        itk_component add padStep {
            ::DCS::MenuEntry $mstepSite.padStep \
            -leaveSubmit 1 \
	        -decimalPlaces 1 \
            -menuChoices $padStepChoices \
            -showPrompt 0 \
            -showEntry 1 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 1 \
            -onSubmit "$this setPadStep %s"
        } {
        }
        pack $itk_component(moveSampleLabel) -side left
        pack $itk_component(padStep) -side left

        itk_component add arrowPad {
            DCS::ArrowPad $itk_interior.ap \
            -activeClientOnly 1 \
            -debounceTime 100 \
            -buttonBackground #c0c0ff \
		} {
		}
        set padSite [$itk_component(arrowPad) getRing]

        itk_component add inPadStep {
            ::DCS::MenuEntry $padSite.padStep \
            -showArrow 0 \
            -leaveSubmit 1 \
	        -decimalPlaces 1 \
            -menuChoices $padStepChoices \
            -showPrompt 0 \
            -showEntry 1 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -showUnits 0 \
            -onSubmit "$this setPadStep %s"
        } {
        }
        grid $itk_component(inPadStep) -column 2 -row 2

        set showFocusButton [::config getInt "bluice.showFocusButton" 0]
        if {$showFocusButton} {
            itk_component add focusIn {
                ::DCS::ArrowButton $padSite.focusIn far \
			    -debounceTime 100  \
                -background #c0c0ff \
                -command "$this startFocusMove 1"
            } {
            }
            grid $itk_component(focusIn) -column 0 -row 1
    
            itk_component add focusOut {
                ::DCS::ArrowButton $padSite.focusOut near \
			    -debounceTime 100  \
                -background #c0c0ff \
                -command "$this startFocusMove -1"
            } {
            }
            grid $itk_component(focusOut) -column 4 -row 1
        }

        ########## phi step + -
        itk_component add phiStepF {
            frame $itk_interior.phiStepF
        } {
        }
        set pstepSite $itk_component(phiStepF)

        itk_component add phiLabel {
            label $pstepSite.phiLabel \
            -text "Rotate Phi" \
            -font "helvetica -14 bold" \
        } {
        }
        pack $itk_component(phiLabel) -side left

        itk_component add phiStep {
            ::DCS::MenuEntry $pstepSite.phiStep \
            -leaveSubmit 1 \
            -decimalPlaces 1 \
            -menuChoices {20 30 40 45 50 60 70 80} \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList deg \
            -units deg \
            -showUnits 1 \
        } {
        }
        itk_component add phiPlus {
            ::DCS::ArrowButton $pstepSite.phiPlus plus \
            -debounceTime 100  \
            -background #c0c0ff \
            -command "$this rotatePhiStep +"
        } {
        }
        itk_component add phiMinus {
            ::DCS::ArrowButton $pstepSite.phiMinus minus \
            -debounceTime 100  \
            -background #c0c0ff \
            -command "$this rotatePhiStep -"
        } {
        }
        pack $itk_component(phiStep) -side left
        pack $itk_component(phiPlus) -side left
        pack $itk_component(phiMinus) -side left

        #### phi buttons
        itk_component add phiFrame {
            frame $itk_interior.p
        } {
        }
        set phiSite $itk_component(phiFrame)

        itk_component add minus1 {
            DCS::MoveMotorRelativeButton $phiSite.minus1 \
            -delta "-$PHI_BUTTON_STEP_SIZE" \
            -text "-$PHI_BUTTON_STEP_SIZE" \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -device $m_objPhi \
        } {
        }

        itk_component add plus1 {
            DCS::MoveMotorRelativeButton $phiSite.plus1 \
            -delta "$PHI_BUTTON_STEP_SIZE" \
            -text "+$PHI_BUTTON_STEP_SIZE" \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -device $m_objPhi \
        } {
        }

        itk_component add minus90 {
            DCS::MoveMotorRelativeButton $phiSite.minus90 \
            -delta "-90" \
            -text "-90" \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -device $m_objPhi \
        } {
        }

        # make the Phi +90 button
        itk_component add plus90 {
            DCS::MoveMotorRelativeButton $phiSite.plus90 \
            -delta "90" \
            -text "+90" \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -device $m_objPhi \
        } {
        }

        itk_component add plus180 {
            DCS::MoveMotorRelativeButton $phiSite.plus180 \
            -delta "180" \
            -text "+180" \
            -width 2 \
            -background #c0c0ff \
            -activebackground #c0c0ff \
            -device $m_objPhi \
        } {
        }
        pack $itk_component(minus1) -side left
        pack $itk_component(plus1) -side left
        pack $itk_component(minus90) -side left
        pack $itk_component(plus90) -side left
        pack $itk_component(plus180) -side left

        eval itk_initialize $args

        $itk_component(arrowPad) configure \
        -leftCommand      "$this padLeft" \
        -upCommand        "$this padUp" \
        -downCommand      "$this padDown" \
        -rightCommand     "$this padRight" \
        -fastLeftCommand  "$this padFastLeft" \
        -fastRightCommand "$this padFastRight"

        foreach arrow {left right fastLeft fastRight} {
            $itk_component(arrowPad) addInput $arrow \
            "::device::sample_z status inactive {supporting device}"
        }

        foreach arrow { up down } {
            $itk_component(arrowPad) addInput $arrow \
            "::device::sample_y status inactive {supporting device}"

            $itk_component(arrowPad) addInput $arrow \
            "::device::sample_x status inactive {supporting device}"
        }

        $itk_component(zoomLow)  addMotor $m_objZoom 0.0
        $itk_component(zoomMed)  addMotor $m_objZoom 0.75
        $itk_component(zoomHigh) addMotor $m_objZoom 1.0

        # pack the components
        pack $itk_component(zoomLabel) -anchor n -side top
        pack $itk_component(zoomFrame) -anchor n -side top
        pack $itk_component(moveStepF) -anchor n -side top
        pack $itk_component(arrowPad)  -anchor n -side top
        pack $itk_component(phiStepF)  -anchor n -side top
        pack $itk_component(phiFrame)  -anchor n -side top

        set minStep [::config getStr "arrowPadDefaultStepSize"]
        if {$minStep == ""} {
            set minStep [lindex $padStepChoices 0]
        }
        $itk_component(padStep) setValue $minStep
        $itk_component(phiStep) setValue 45.0

        if {$itk_option(-purpose) == "forL614" \
        ||  $itk_option(-purpose) == "forPXL614"} {
            puts "forL614 set step size to 0.8mm"
            setPadStep 800
        }

    }
}
### merge CanvasControl, notice and positioning into one
class GridCanvasControlCombo {
    inherit ::DCS::ComponentGateExtension

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -canvas canvas Canvas "" {
        if {$itk_option(-canvas) != ""} {
            $itk_option(-canvas) register $this toolMode handleToolModeEvent
        }
    }

    ### forGrid, forL614, forCrystal
    itk_option define -purpose purpose Purpose $gGridPurpose {
        repack

        switch -exact -- $itk_option(-purpose) {
            forLCLS -
            forLCLSCrystal -
            forL614 {
                $m_itemCrystal configure -m_forLCLS 1
                puts "set m_forLCLS to 1"
            }
            default {
                $m_itemCrystal configure -m_forLCLS 0
                puts "set m_forLCLS to 0"
            }
        }
    }

    itk_option define -camera camera Camera inline {
        if {$m_strCameraOrig != ""} {
            $m_strCameraOrig unregister $this contents handleCameraOrigUpdate
            set m_strCameraOrig ""
        }
        switch -exact -- $itk_option(-camera) {
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
        set m_strCameraOrig [$m_deviceFactory createString $stringName]
        $m_strCameraOrig register $this contents handleCameraOrigUpdate
    }

    public proc toolModeMappingByPurpose { mode purpose } {
        puts "tool mapping by purupse mode=$mode purpose=$purpose"
        if {$mode == "adjust"} {
            return $mode
        }
        switch -exact -- $purpose {
            forCrystal -
            forLCLSCrystal {
                return add_crystal
            }
            forPXL614 -
            forL614 {
                switch -exact -- $mode {
                    add_l614 -
                    add_trap_array -
                    add_mesh {
                        puts "return mode=$mode"
                        return $mode
                    }
                }
                return add_l614
            }
        }
        switch -exact -- $mode {
            add_l614 -
            add_trap_array -
            add_mesh -
            add_crystal {
                return "add_rectangle"
            }
        }
        return $mode
    }

    public method handleCameraOrigUpdate { - ready_ - position_ - }

    public method handleCurrentItemDisplayed { obj_ ready_ - contents_ - } {

        if {!$ready_} {
            return
        }
        set m_currentItemDisplayed $contents_
        set m_currentItemIsGroup [$obj_ getCurrentItemIsGroup]
        set m_currentItemIsMegaCrystal [$obj_ getCurrentItemIsMegaCrystal]
        refresh
    }

    public method handleToolModeEvent { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set mode [toolModeMappingByPurpose \
        $contents_ $itk_option(-purpose)]
        onToolModeChange $mode

        set m_currentToolMode $mode
        refresh
    }
    public method handleCurrentItemRunnableUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_currentItemRunnable $contents_
        refresh
    }

    public method setClickToMove { yn } {
        if {$m_displayControl == ""} {
            log_error no display master defined
            return
        }

        $m_displayControl setClickToMove $yn
        refresh
    }

    public method setToolMode { mode } {
        gCurrentGridGroup setWidgetToolMode $mode
        set head [string range $mode 0 3]
        if {$head == "add_"} {
            ### info Parameter Setup widget 
            set shape [string range $mode 4 end]
            set contents [$m_strLatestUserSetup getContents]
            set dd [eval dict create $contents]
            dict set dd shape $shape
            $m_strLatestUserSetup sendContentsToServer $dd
        }
        if {$mode == "add_crystal"} {
            set m_defineCrystalState 0
            ##refresh
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
    public method getMaybeAtEnd { } {
        if {$m_zMoved} {
            return 1
        }
        return 0
    }
    public method saveStart { }
    public method savePosition { }
    public method saveEndSegment { }
    public method saveEndCrystal { }
    public method mergeGroupCrystals { }
    public method splitMegaCrystal { }
    public method cancel { }

    ###may remove later
    public method getNoticeComponent { } { return $itk_component(notice) }

    public method drawNotice { txt {color blue} } {
        $itk_component(notice) configure \
        -text $txt \
        -foreground $color
    }

    public method setDisplayControl { m } {
        set m_displayControl $m

        set key $m
        if {$key != ""} {
            lappend key click_to_move
        }
        $itk_component(clickToMove) configure \
        -reference $key

        refresh
    }

    private method highlightStartButton { }

    private method repack { } {
        set all [pack slaves $itk_interior.topButtonFrame]
        if {$all != ""} {
            eval pack forget $all
        }
        switch -exact -- $itk_option(-purpose) {
            forLCLS -
            forGrid {
                foreach name $m_toolModeList {
                    switch -exact -- $name {
                        add_l614 -
                        add_trap_array -
                        add_mesh -
                        add_crystal {
                            ### skip
                        }
                        default {
                            pack $itk_component($name) -side left
                        }
                    }
                }
            }
            forPXL614 -
            forL614 {
                pack $itk_component(add_l614) -side left
                pack $itk_component(add_trap_array) -side left
                pack $itk_component(add_mesh) -side left
                pack $itk_component(adjust) -side left
            }
            forCrystal {
                pack $itk_component(add_crystal) -side left
                pack $itk_component(adjust) -side left
            }
            forLCLSCrystal {
                pack $itk_component(add_crystal) -side left
                pack $itk_component(adjust) -side left
            }
            default {
                foreach name $m_toolModeList {
                    pack $itk_component($name) -side left
                }
            }
        }
        pack $itk_component(clickToMove) -side left
    }
    private method addCrystalToSystem { }
    private method refresh { }

    private variable m_toolModeList [list \
    add_l614 \
    add_trap_array \
    add_mesh \
    add_rectangle \
    add_oval \
    add_line \
    add_polygon \
    add_crystal \
    adjust \
    ]

    private variable m_toolModeLabel [list \
    grid \
    trap_array \
    mesh \
    rectangle \
    oval \
    line \
    polygon \
    "define new crystal" \
    modify \
    ]

    private variable m_itemCrystal ""

    ### init:        "Save" will create the template class from current position
    ### in_segment:  "Save" will add position to current segment.
    ### new_segment: "Save" will create new segment from current position
    ###
    ### "End Crystal" button will always end crystal definition.
    ### "End Segment" will start a new segment.
    ###     In both "End"s cases, last position will be ignored
    ###     if it is within 10 pixels of previous one.
    private variable m_defineCrystalState 0
    private variable m_startPosition ""
    private variable m_endPosition ""
    private variable m_currentItemDisplayed 0
    private variable m_currentToolMode 0
    private variable m_currentItemRunnable 0
    private variable m_currentItemIsGroup 0
    private variable m_currentItemIsMegaCrystal 0

    private variable m_zMoved 0
    private variable m_phiMoved 0

    private variable m_deviceFactory ""
    private variable m_strLatestUserSetup ""
    private variable m_opGridGroupConfig ""
    private variable m_strCameraOrig ""
    private variable m_normalBG ""

    private variable m_displayControl ::gCurrentGridGroup

    constructor { args } {
        ::DCS::Component::constructor {
            maybe_at_end  {getMaybeAtEnd}
        }
    } {
        set m_itemCrystal [GridAbstractCrystal #auto]

        set m_deviceFactory [::DCS::DeviceFactory::getObject]
        set m_strLatestUserSetup \
        [$m_deviceFactory createString latest_raster_user_setup]

        set m_opGridGroupConfig \
        [$m_deviceFactory createOperation gridGroupConfig]

        set topSite [frame $itk_interior.topButtonFrame]
        set subSite [frame $itk_interior.subButtonFrame]

        itk_component add notice {
            label $itk_interior.notice \
            -font "helvetica -16 bold" \
            -foreground red \
            -background "light green" \
            -relief sunken \
            -text "notice" \
            -justify left \
            -anchor w \
        } {
        }

        foreach name $m_toolModeList txt $m_toolModeLabel {
            itk_component add $name {
                button $topSite.$name \
                -text $txt \
                -command "$this setToolMode $name"
            } {
            }
        }
        itk_component add clickToMove {
            DCS::Checkbutton $topSite.clickToMove \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -justify left \
            -anchor w \
            -text "Align Visually (hides results)" \
            -shadowReference 1 \
            -reference "$m_displayControl click_to_move" \
            -command "$this setClickToMove %s" \
            -onBackground yellow \
        } {
        }

        itk_component add zoom_in {
            button $subSite.zin \
            -text "zoom in" \
            -command "$this command zoomIn"
        } {
        }
        itk_component add zoom_out {
            button $subSite.zout \
            -text "zoom out" \
            -command "$this command zoomOut"
        } {
        }

        itk_component add delete {
            DCS::Button $subSite.del \
            -text "delete" \
            -command "$this command deleteSelected"
        } {
        }
        $itk_component(delete) addInput \
        "::gCurrentGridGroup current_grid_deletable 1 {try reset first}"

        itk_component add hide {
            DCS::Button $subSite.hide \
            -text "hide" \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -command "$this command hideSelected"
        } {
        }
        itk_component add b0 {
            DCS::Button $subSite.b0 \
            -background blue \
            -activebackground blue \
            -foreground white \
            -activeforeground white \
            -command "$this saveStart" \
            -text "Save"
        } {
        }

        itk_component add b1 {
            DCS::Button $subSite.b1 \
            -background blue \
            -activebackground blue \
            -foreground white \
            -activeforeground white \
            -command "$this savePosition" \
            -text "Save Position"
        } {
        }
        itk_component add b2 {
            DCS::Button $subSite.b2 \
            -background blue \
            -activebackground blue \
            -foreground white \
            -activeforeground white \
            -command "$this saveEndSegment" \
            -text "Save and End Segment"
        } {
        }
        itk_component add b3 {
            DCS::Button $subSite.b3 \
            -background blue \
            -activebackground blue \
            -foreground white \
            -activeforeground white \
            -command "$this saveEndCrystal" \
            -text "Save"
        } {
        }
        itk_component add b4 {
            DCS::Button $subSite.b4 \
            -background blue \
            -activebackground blue \
            -foreground white \
            -activeforeground white \
            -command "$this mergeGroupCrystals" \
            -text "Merge into Mega Crystal"
        } {
        }

        itk_component add b5 {
            DCS::Button $subSite.b5 \
            -command "$this splitMegaCrystal" \
            -text "Split Mega Crystal"
        } {
        }
        $itk_component(b5) addInput \
        "::gCurrentGridGroup current_grid_deletable 1 {try reset first}"

        itk_component add pos {
            GridCanvasPositioner $subSite.pos \
        } {
            keep -holder
        }

        set m_normalBG [$itk_component(zoom_out) cget -background]

        eval itk_initialize $args

        registerComponent \
        $itk_component(add_l614) \
        $itk_component(add_trap_array) \
        $itk_component(add_mesh) \
        $itk_component(add_rectangle) \
        $itk_component(add_oval) \
        $itk_component(add_line) \
        $itk_component(add_polygon) \
        $itk_component(add_crystal) \
        $itk_component(adjust) \
        $itk_component(delete)

        pack $itk_interior.topButtonFrame -side top -fill x
        pack $itk_component(notice) -side top -fill x
        pack $itk_interior.subButtonFrame -side top -fill x

        announceExist

        $itk_component(b1) addInput \
        "$this maybe_at_end 1 {Need to move away from starting end}"

        $itk_component(b2) addInput \
        "$this maybe_at_end 1 {Need to move away from starting end}"

        $itk_component(b3) addInput \
        "$this maybe_at_end 1 {Need to move away from starting end}"

        gCurrentGridGroup register $this current_grid_runnable \
        handleCurrentItemRunnableUpdate
    }
    destructor {
        if {$m_strCameraOrig != ""} {
            $m_strCameraOrig unregister $this contents handleCameraOrigUpdate
            set m_strCameraOrig ""
        }

        gCurrentGridGroup unregister $this current_grid_runnable \
        handleCurrentItemRunnableUpdate
    }
}
body GridCanvasControlCombo::handleCameraOrigUpdate { - ready_ - contents_ -} {
    if {!$ready_} {
        return
    }
    if {$m_defineCrystalState == 0 || [llength $m_startPosition] < 4} {
        set m_zMoved 0
        set m_phiMoved 0
        updateRegisteredComponents maybe_at_end
        return
    }

    foreach {x y z a} $contents_ break
    foreach {x0 y0 z0 a0} $m_startPosition break

    set m_zMoved   [expr abs($z - $z0) > 0.001]

    ## phi may move back it is OK
    if {abs($a - $a0) >= 5.0} {
        set m_phiMoved 1
    }
    updateRegisteredComponents maybe_at_end
    #refresh
}
body GridCanvasControlCombo::saveStart { } {
    if {$m_strCameraOrig == ""} {
        log_error need -camera
    }
    set m_startPosition [$m_strCameraOrig getContents]
    set m_zMoved 0
    set m_phiMoved 0
    set m_defineCrystalState 1
    refresh

    command createCrystalTemplate
}
body GridCanvasControlCombo::savePosition { } {
    if {$m_strCameraOrig == ""} {
        log_error need -camera
        return
    }
    if {[llength $m_startPosition] < 4} {
        log_error need to define Start Position first
        return
    }
    set m_endPosition [$m_strCameraOrig getContents]

    set temp [$itk_option(-canvas) getTemplateItem]
    $temp addPosition $m_endPosition
    refresh
}
body GridCanvasControlCombo::saveEndSegment { } {
    if {$m_strCameraOrig == ""} {
        log_error need -camera
        return
    }
    if {[llength $m_startPosition] < 4} {
        log_error need to define Start Position first
        return
    }
    set m_endPosition [$m_strCameraOrig getContents]

    #addCrystalToSystem
    set temp [$itk_option(-canvas) getTemplateItem]
    $temp endSegment $m_endPosition

    refresh
}
body GridCanvasControlCombo::saveEndCrystal { } {
    if {$m_strCameraOrig == ""} {
        log_error need -camera
        return
    }
    if {[llength $m_startPosition] < 4} {
        log_error need to define Start Position first
        return
    }
    set m_endPosition [$m_strCameraOrig getContents]

    #addCrystalToSystem
    set temp [$itk_option(-canvas) getTemplateItem]
    $temp endCrystal $m_endPosition

    set m_defineCrystalState 0
    set m_currentToolMode adjust
    refresh

    highlightStartButton
}
body GridCanvasControlCombo::mergeGroupCrystals { } {
    if {$m_strCameraOrig == ""} {
        log_error need -camera
        return
    }
    set temp [$itk_option(-canvas) getCurrentItem]
    $temp mergeCrystals

    set m_currentToolMode adjust
    refresh

    highlightStartButton
}
body GridCanvasControlCombo::splitMegaCrystal { } {
    if {$m_strCameraOrig == ""} {
        log_error need -camera
        return
    }

    set temp [$itk_option(-canvas) getCurrentItem]
    set gridId [$temp getGridId]
    set groupId [gCurrentGridGroup getId]
    eval $m_opGridGroupConfig startOperation splitMegaCrystal $groupId $gridId

    set m_currentToolMode adjust
    refresh

    highlightStartButton
}
body GridCanvasControlCombo::highlightStartButton { } {
    if {$itk_option(-mdiHelper) != ""} {
        $itk_option(-mdiHelper) highlightStartButton
    }
}
body GridCanvasControlCombo::addCrystalToSystem { } {
    puts "send crystal to system"
    set origList [list $m_startPosition $m_endPosition]

    $m_itemCrystal setup $origList

    set groupId [gCurrentGridGroup getId]

    set info [$m_itemCrystal getItemInfo]
    set cmd addGridFromLiveVideo
    eval $m_opGridGroupConfig startOperation $cmd $groupId -1 $info
}
body GridCanvasControlCombo::refresh { } {
    set all [pack slaves $itk_interior.subButtonFrame]
    if {$all != ""} {
        eval pack forget $all
    }
    pack $itk_component(zoom_out) -side right 
    pack $itk_component(zoom_in) -side right

    if {$itk_option(-canvas) != ""} {
        $itk_option(-canvas) configure -onKeyEnter ""
    }

    if {$m_displayControl != "" && [$m_displayControl getClickToMove]} {
        drawNotice "Click to move sample into the x-ray beam."
        return
    }

    switch -exact -- $m_currentToolMode {
        adjust {
            if {$m_currentItemDisplayed} {
                if {$m_currentItemIsGroup} {
                    switch -exact -- $itk_option(-purpose) {
                        forLCLSCrystal {
                            drawNotice "Click button to merge"
                            pack $itk_component(b4) -side left
                            if {$itk_option(-canvas) != ""} {
                                $itk_option(-canvas) configure \
                                -onKeyEnter "$this mergeGroupCrystals"
                            }
                        }
                        forCrystal -
                        forLCLS -
                        forPXL614 -
                        forL614 -
                        forGrid -
                        default {
                            drawNotice "Grouped."
                        }
                    }
                } elseif {$m_currentItemRunnable == "1"} {
                    switch -exact -- $itk_option(-purpose) {
                        forCrystal {
                            drawNotice "Use Helical Collect interface to start data collection."
                        }
                        forLCLS {
                            drawNotice "Use Raster Collect interface to start data collection."
                        }
                        forLCLSCrystal {
                            drawNotice "Use Helical Collect interface to start data collection."
                        }
                        forPXL614 -
                        forL614 {
                            drawNotice "Use Grid Collect interface to start data collection.\n"
                        }
                        forGrid -
                        default {
                            drawNotice "Use Raster Setup interface to start data collection."
                        }
                    }
                } elseif {$m_currentItemRunnable == "disabled"} {
                    drawNotice "Current item disabled."
                } else {
                    drawNotice \
                    "Already done data collection.  Please reset it if you want to recollect."
                }

                if {!$m_currentItemIsGroup} {
                    pack $itk_component(pos) -side left
                    pack $itk_component(delete) -side left
                    #pack $itk_component(hide) -side left
                    if {$m_currentItemIsMegaCrystal} {
                        pack $itk_component(b5) -side left
                        if {$itk_option(-canvas) != ""} {
                            $itk_option(-canvas) configure \
                            -onKeyEnter "$this splitMegaCrystal"
                        }
                    }
                }
            } else {
                drawNotice "Select item by clicking on it below"
            }
        }
        add_crystal {
            switch -exact -- $m_defineCrystalState {
                0 {
                    drawNotice "1. Use Sample Positioning Tools and phi to center one end of your crystal into the x-ray beam.\n2. Click the Save button."
                    pack $itk_component(b0) -side left
                    if {$itk_option(-canvas) != ""} {
                        $itk_option(-canvas) configure \
                        -onKeyEnter "$this saveStart"
                    }
                }
                1 {
                    drawNotice "1. Now position the other end of your crystal into the x-ray beam in the same manner.\n2. Click the Save button. (Save button disabled until start & end position differ)."
                    #pack $itk_component(b1) -side left
                    #pack $itk_component(b2) -side left
                    pack $itk_component(b3) -side left
                    if {$itk_option(-canvas) != ""} {
                        $itk_option(-canvas) configure \
                        -onKeyEnter "$this saveEndCrystal"
                    }
                }
            }
        }
        add_rectangle -
        add_oval -
        add_line {
            drawNotice "Click, hold and drag, then release to define the area."
        }
        add_polygon {
            drawNotice "Click to add points.  Click starting red to end."
        }
        add_l614 {
            drawNotice "1. Center between D15 and B15,\n2. Click D15"
        }
        add_mesh {
            drawNotice "1. Center between Anchor 1 and Anchor 2,\n2. Click Anchor 1"
        }
        add_trap_array {
            drawNotice "1. Center at A1,\n2. Click A1 Trap"
        }
    }
}

#### onNew will enable editable and disable resettable, deletable, runnable.
class CurrentGridAttributeWrapper {
    inherit ::DCS::Component

    public method setup { obj input } {
        $obj register $this current_grid_editable   handleEditable
        $obj register $this current_grid_resettable handleResettable
        $obj register $this current_grid_deletable  handleDeletable

        ::mediator register $this $input on_new handleOnNew
        #$input register $this on_new handleOnNew
    }

    public method getEditable { } {
        if {$m_onNew} {
            return 1
        }
        return $m_editable
    }
    public method getResettable { } {
        if {$m_onNew} {
            return 0
        }
        return $m_resettable
    }
    public method getDeletable { } {
        if {$m_onNew} {
            return 0
        }
        return $m_deletable
    }
    #######
    public method handleOnNew { - ready_ - contents_  - } {
        if {!$ready_} {
            return
        }
        set m_onNew $contents_
        updateRegisteredComponents current_grid_editable
        updateRegisteredComponents current_grid_resettable
        updateRegisteredComponents current_grid_deletable
    }
    public method handleEditable { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_editable $contents_
        updateRegisteredComponents current_grid_editable
    }
    public method handleResettable { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_resettable $contents_
        updateRegisteredComponents current_grid_resettable
    }
    public method handleDeletable { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_deletable $contents_
        updateRegisteredComponents current_grid_deletable
    }

    protected variable m_editable 0
    protected variable m_resettable 0
    protected variable m_deletable 0
    protected variable m_onNew 1

    constructor { args } {
        ::DCS::Component::constructor {
            current_grid_editable   { getEditable }
            current_grid_resettable { getResettable }
            current_grid_deletable  { getDeletable }
        }
    } {
        eval configure $args

        announceExist
    }
}

class GridPhiOscWithStrategyView {
    inherit ::itk::Widget DCS::Component

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -purpose purpose Purpose $gGridPurpose
    itk_option define -onStart onStart OnStart ""

    ### because raster view and crystal view, "current" grid may be raster
    ### when there is no "crystal".
    itk_option define -onNew onNew OnNew 1 {
        refreshGrid
    }

    public method setWrapper { w } {
        foreach {name -} $COMPONENT2KEY {
            $itk_component($name) addInput \
            "$w current_grid_editable 1 {reset first}"
        }

        foreach name {top_dir space_group} {
            $itk_component($name) addInput \
            "$w current_grid_editable 1 {reset first}"
        }
    }
    public method addInputToStart { trigger_ } {
        $itk_component(startStrategy) addInput $trigger_
    }


    ### for buttons.
    public method startNodeStrategy { } {
        set index [gCurrentGridGroup getGridIndex $m_gridId]
        $m_objCollectGrid startOperation $m_groupId $index \
        do_strategy_with_phi_osc
    }

    public method setStrategyField { name value } {
        if {!$m_ready} {
            return
        }
        $m_objStrategySoftOnly startOperation set_field $name $value
    }

    public method setField { name value } {
        if {!$m_ready} {
            return
        }

        set param [dict create $name $value]

        if {$m_gridId >= 0} {
                    ### these are done in dcss with class.
                    ### They may be simple change, like detector distance.
                    ### Maybe trigger a group update, including angle of
                    ### node position, like start_angle.
                    ### Maybe even change node selection,
                    ### like strategy_enable, strategy_nodoe.

                    $m_objGridGroupConfig startOperation modifyParameter \
                    $m_groupId $m_gridId $param
        }

        ##################
        #### update latest_user_raster_setup
        ##################

        set contents [$m_objLatestUserSetup getContents]
        set dd [eval dict create $contents]

        dict set dd $name $value
        $m_objLatestUserSetup sendContentsToServer $dd
    }

    public method handleGridUpdate { - ready_ - contents_ - }
    public method handlePhiNodeListUpdate { - ready_ - contents_ - }

    public method showStrategy { yn } {
        if {$yn == "1"} {
            grid $itk_component(xfelStrategyFrame)
        } else {
            grid remove $itk_component(xfelStrategyFrame)
        }
    }

    private method refreshGrid { }

    private method refreshDisplay { }

    private common COMPONENT2KEY [list \
    exposureTime        time \
    delta               delta \
    attenuation         attenuation \
    strategyNode        strategy_node \
    numPhiShot          num_phi_shot \
    cbPhiOscEnabled     phi_osc_on_strategy \
    cbStrategyEnabled   strategy_enable \
    ]

    private variable m_ready 0
    private variable m_objCollectGrid ""
    private variable m_objGridGroupConfig ""
    private variable m_objLatestUserSetup ""
    private variable m_groupId -1
    private variable m_snapId -1
    private variable m_gridId -1
    private variable m_d_userSetup ""

    private variable m_origGridContents ""

    private variable m_strInput ""
    private variable m_objStrategySoftOnly ""

    private common PADY 2

    private common PROMPT_WIDTH 15

    constructor { args} {
        global gMotorDistance
        global gMotorBeamStop
        global gMotorEnergy
        global gMotorPhi
        global gMotorBeamWidth
        global gMotorBeamHeight

        set deviceFactory [::DCS::DeviceFactory::getObject]

        set m_objCollectGrid [$deviceFactory createOperation collectGrid]

        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        set m_objLatestUserSetup \
        [$deviceFactory createString latest_raster_user_setup]

        set m_strInput [$deviceFactory createString multiStrategy_input]
        $m_strInput createAttributeFromKey space_group
        $m_strInput createAttributeFromKey phi_range
        $m_strInput createAttributeFromKey top_dir

        set m_objStrategySoftOnly \
        [$deviceFactory createOperation multiCrystalStrategySoftOnly]

        itk_component add cbStrategyEnabled {
            DCS::Checkbutton $itk_interior.firstNodeStg \
            -text "Do Strategy Calculation Before Collecting Data" \
            -shadowReference 0 \
            -command "$this setField strategy_enable %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add xfelStrategyFrame {
            iwidgets::labeledframe $itk_interior.xfelstgF \
            -labeltext "Strategy Calculation Setup" \
            -labelfont "helvetica -16 bold" \
        } {
        }
        set stgSite [$itk_component(xfelStrategyFrame) childsite]

        itk_component add strategyNode {
            DCS::MenuEntry $stgSite.node \
            -menuChoices {1 2 3} \
            -promptWidth $PROMPT_WIDTH \
            -promptText "Position Num: " \
            -showEntry 0 \
            -showUnits 0 \
            -entryWidth 11 \
            -entryType positiveInt \
            -entryJustify right \
            -onSubmit "$this setField strategy_node %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add attenuation {
            DCS::MotorViewEntry $stgSite.attenuation \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Attenuation: " \
            -promptWidth $PROMPT_WIDTH \
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
            keep -font
        }

        itk_component add exposureTime {
            DCS::Entry $stgSite.time \
            -leaveSubmit 1 \
            -promptText "Time: " \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -units "s" \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -onSubmit "$this setField time %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add delta {
            DCS::Entry $stgSite.delta \
            -promptText "Delta: " \
            -leaveSubmit 1 \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -shadowReference 0 \
            -onSubmit "$this setField delta %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add space_group {
            DCS::Entry $stgSite.spaceGroup \
            -state normal \
            -leaveSubmit 1 \
            -entryType field \
            -entryWidth 20 \
            -entryJustify left \
            -entryMaxLength 100 \
            -promptText "SpaceGroup: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 1 \
            -reference "$m_strInput space_group" \
            -onSubmit "$this setStrategyField space_group %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add top_dir {
            DCS::Entry $stgSite.top_dir \
            -state normal \
            -leaveSubmit 1 \
            -entryType rootDirectory \
            -entryWidth 40 \
            -entryJustify left \
            -entryMaxLength 128 \
            -promptText "Top Dir: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 1 \
            -reference "$m_strInput top_dir" \
            -onSubmit "$this setStrategyField top_dir %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add phi_range {
            DCS::Entry $stgSite.phiRange \
            -promptText "Phi Range: " \
            -state labeled \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -reference "::gCurrentGridGroup current_grid_input_phi_range" \
            -shadowReference 1 \
        } {
            keep -font
        }

        itk_component add cbPhiOscEnabled {
            DCS::Checkbutton $stgSite.doPhiOsc \
            -text "Do Phi Osic While Waiting for Strategy Result" \
            -shadowReference 0 \
            -command "$this setField phi_osc_on_strategy %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add numPhiShot {
            DCS::Entry $stgSite.numPhiShot \
            -promptText "Num Phi Shot: " \
            -leaveSubmit 1 \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 2 \
            -entryType positiveInt \
            -entryJustify right \
            -shadowReference 0 \
            -onSubmit "$this setField num_phi_shot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add startStrategy {
            DCS::Button $stgSite.start \
            -text "Start Strategy Calculation" \
            -command "$this startNodeStrategy"
        } {
            keep -font
        }

        grid $itk_component(strategyNode)       -row 0 -column 0 -sticky w
        grid $itk_component(attenuation)        -row 1 -column 0 -sticky w
        grid $itk_component(exposureTime)       -row 2 -column 0 -sticky w
        grid $itk_component(delta)              -row 3 -column 0 -sticky w
        grid $itk_component(space_group)        -row 4 -column 0 -sticky w
        grid $itk_component(top_dir)            -row 5 -column 0 -sticky w
        grid $itk_component(phi_range)          -row 6 -column 0 -sticky w
        grid $itk_component(cbPhiOscEnabled)    -row 7 -column 0 -sticky w
        grid $itk_component(numPhiShot)         -row 8 -column 0 -sticky w
        grid $itk_component(startStrategy)      -row 9 -column 0 -sticky w

        grid $itk_component(cbStrategyEnabled) -row 0 -column 0 -sticky w
        grid $itk_component(xfelStrategyFrame) -row 1 -column 0 -sticky w
        grid remove $itk_component(xfelStrategyFrame)

        grid columnconfigure $itk_interior 0 -weight 10
        eval itk_initialize $args

        announceExist

        $itk_component(startStrategy) addInput \
        "::gCurrentGridGroup current_grid_runnable 1 {cannot run}"

        gCurrentGridGroup register $this current_grid handleGridUpdate
    }
    destructor {
        gCurrentGridGroup unregister $this current_grid handleGridUpdate

        ::mediator announceDestruction $this
    }
}
body GridPhiOscWithStrategyView::handleGridUpdate { - ready_ - contents_ - } {
    set m_ready 0
    if {!$ready_} {
        return
    }
    set m_origGridContents $contents_
    refreshGrid
}
body GridPhiOscWithStrategyView::refreshGrid { } {
    set m_groupId [gCurrentGridGroup getId]
    set m_snapId  [gCurrentGridGroup getCurrentSnapshotId]

    if {$itk_option(-onNew)} {
        set m_gridId -1
    } else {
        set m_gridId  [gCurrentGridGroup getCurrentGridId]
    }

    set ll [llength $m_origGridContents]
    if {$ll < 6 || $itk_option(-onNew)} {
        set m_d_userSetup [gCurrentGridGroup getDefaultUserSetup $itk_option(-purpose)]
    } else {
        set m_d_userSetup [lindex $m_origGridContents 5]
    }
    refreshDisplay
    set m_ready 1
}
body GridPhiOscWithStrategyView::refreshDisplay { } {
    puts "STRATEGE refreshDisplay:"
    if {[catch {dict get $m_d_userSetup shape} shape]} {
        set shape unknown
    }
    if {[catch {dict get $m_d_userSetup for_lcls} forLCLS]} {
        set forLCLS 0
    }
    if {$shape != "crystal" || $forLCLS != "1"} {
        return
    }

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
            eval $itk_component($name) setValue $value 1
        }
    }

    if {[catch {dict get $m_d_userSetup num_column} nNode]} {
        set nNode 1
    }
    set mChoice [list]
    for {set i 1} {$i <= $nNode} {incr i} {
        lappend mChoice $i
    }
    puts "node choices: $mChoice"
    $itk_component(strategyNode) configure \
    -menuChoices $mChoice

    if {[catch {dict get $m_d_userSetup strategy_enable} yn]} {
        set yn 0
    }
    showStrategy $yn

    if {$numError} {
        puts "failed to update, the dict=$m_d_userSetup"
        if {$m_d_userSetup == ""} {
            puts "contents=$contents_"
        }
    }
}

class VideoFilter {
    public method setupCallback { cmd } {
        set m_callback $cmd
    }

    public method show { } {
        $m_menu post
    }

    public method updateOnValue { index v } {
        set m_onList [lreplace $m_onList $index $index $v]

        updateFilters
    }
    public method updateFilters { } {
        if {$m_callback == ""} { return }

        set filters ""
        foreach v $m_onList k $m_keyList {
            if {$v} {
                append filters $k
            }
        }
        set cmd $m_callback
        lappend cmd $filters
        eval $cmd
    }

    private variable m_menu ""

    private variable m_labelList [list \
    "Grayscale" \
    "Exposure 2x" \
    "Gamma 1.5" \
    "Gamma 1.6" \
    "Equalize Colors" \
    "Edge Tracing" \
    "Custom Color Curve" \
    ]

    private variable m_keyList [list \
    "grayscale;" \
    "2xExposure;" \
    "gamma15;" \
    "gamma16;" \
    "equalize;" \
    "edge;" \
    "curve;" \
    ]

    private variable m_onList [list 0 0 0 0 0 0 0]

    private variable m_callback ""
 
    constructor { } {
        set m_menu [DCS::PopupMenu \#auto]
        $m_menu addLabel title -label "Filters"

        set index -1
        foreach ll $m_labelList {
            incr index
            $m_menu addCheckbox chk$index \
            -label $ll \
            -callback "$this updateOnValue $index" \
            -value 0
        }
    }
}
class GridSingleShotStrategyView {
    inherit ::itk::Widget DCS::Component

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -purpose purpose Purpose $gGridPurpose
    itk_option define -onStart onStart OnStart ""

    ### because raster view and crystal view, "current" grid may be raster
    ### when there is no "crystal".
    itk_option define -onNew onNew OnNew 1 {
        refreshGrid
    }

    public method setWrapper { w } {
        foreach {name -} $COMPONENT2KEY {
            $itk_component($name) addInput \
            "$w current_grid_editable 1 {reset first}"
        }

        foreach name {top_dir space_group} {
            $itk_component($name) addInput \
            "$w current_grid_editable 1 {reset first}"
        }
    }
    public method addInputToStart { trigger_ } {
        $itk_component(startStrategy) addInput $trigger_
    }


    ### for buttons.
    public method startNodeStrategy { } {
        set index [gCurrentGridGroup getGridIndex $m_gridId]
        $m_objCollectGrid startOperation $m_groupId $index \
        do_strategy_with_single_shot
    }

    public method setStrategyField { name value } {
        if {!$m_ready} {
            return
        }
        $m_objStrategySoftOnly startOperation set_field $name $value
    }

    public method setField { name value } {
        if {!$m_ready} {
            return
        }

        set param [dict create $name $value]

        if {$m_gridId >= 0} {
                    ### these are done in dcss with class.
                    ### They may be simple change, like detector distance.
                    ### Maybe trigger a group update, including angle of
                    ### node position, like start_angle.
                    ### Maybe even change node selection,
                    ### like strategy_enable, strategy_nodoe.

                    $m_objGridGroupConfig startOperation modifyParameter \
                    $m_groupId $m_gridId $param
        }

        ##################
        #### update latest_user_raster_setup
        ##################

        set contents [$m_objLatestUserSetup getContents]
        set dd [eval dict create $contents]

        dict set dd $name $value
        $m_objLatestUserSetup sendContentsToServer $dd
    }

    public method handleGridUpdate { - ready_ - contents_ - }
    public method handlePhiNodeListUpdate { - ready_ - contents_ - }

    public method showStrategy { yn } {
        if {$yn == "1"} {
            grid $itk_component(xfelStrategyFrame)
        } else {
            grid remove $itk_component(xfelStrategyFrame)
        }
    }

    private method refreshGrid { }

    private method refreshDisplay { }

    private common COMPONENT2KEY [list \
    strategyNode        strategy_node \
    cbStrategyEnabled   strategy_enable \
    ]

    private variable m_ready 0
    private variable m_objCollectGrid ""
    private variable m_objGridGroupConfig ""
    private variable m_objLatestUserSetup ""
    private variable m_groupId -1
    private variable m_snapId -1
    private variable m_gridId -1
    private variable m_d_userSetup ""

    private variable m_origGridContents ""

    private variable m_strInput ""
    private variable m_objStrategySoftOnly ""

    private common PADY 2

    private common PROMPT_WIDTH 15

    constructor { args} {
        set deviceFactory [::DCS::DeviceFactory::getObject]

        set m_objCollectGrid [$deviceFactory createOperation collectGrid]

        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        set m_objLatestUserSetup \
        [$deviceFactory createString latest_raster_user_setup]

        set m_strInput [$deviceFactory createString multiStrategy_input]
        $m_strInput createAttributeFromKey space_group
        $m_strInput createAttributeFromKey phi_range
        $m_strInput createAttributeFromKey top_dir
        $m_strInput createAttributeFromKey attenuation

        set m_objStrategySoftOnly \
        [$deviceFactory createOperation multiCrystalStrategySoftOnly]

        itk_component add cbStrategyEnabled {
            DCS::Checkbutton $itk_interior.firstNodeStg \
            -text "Do Strategy Calculation Before Collecting Data" \
            -shadowReference 0 \
            -command "$this setField strategy_enable %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add xfelStrategyFrame {
            iwidgets::labeledframe $itk_interior.xfelstgF \
            -labeltext "Strategy Calculation Setup" \
            -labelfont "helvetica -16 bold" \
        } {
        }
        set stgSite [$itk_component(xfelStrategyFrame) childsite]

        itk_component add strategyNode {
            DCS::MenuEntry $stgSite.node \
            -menuChoices {1 2 3} \
            -promptWidth $PROMPT_WIDTH \
            -promptText "Position Num: " \
            -showEntry 0 \
            -showUnits 0 \
            -entryWidth 11 \
            -entryType positiveInt \
            -entryJustify right \
            -onSubmit "$this setField strategy_node %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add attenuation {
            DCS::MotorViewEntry $stgSite.attenuation \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -promptText "Attenuation: " \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 10 \
            -units "%" \
            -unitsList "%" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -autoConversion 1 \
            -shadowReference 1 \
            -alterUpdateSubmit 0 \
            -alternateShadowReference "$m_strInput attenuation" \
            -onSubmit "$this setStrategyField attenuation %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add space_group {
            DCS::Entry $stgSite.spaceGroup \
            -state normal \
            -leaveSubmit 1 \
            -entryType field \
            -entryWidth 20 \
            -entryJustify left \
            -entryMaxLength 100 \
            -promptText "SpaceGroup: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 1 \
            -reference "$m_strInput space_group" \
            -onSubmit "$this setStrategyField space_group %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add top_dir {
            DCS::Entry $stgSite.top_dir \
            -state normal \
            -leaveSubmit 1 \
            -entryType rootDirectory \
            -entryWidth 40 \
            -entryJustify left \
            -entryMaxLength 128 \
            -promptText "Top Dir: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 1 \
            -reference "$m_strInput top_dir" \
            -onSubmit "$this setStrategyField top_dir %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add phi_range {
            DCS::Entry $stgSite.phiRange \
            -promptText "Phi Range: " \
            -state labeled \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -reference "::gCurrentGridGroup current_grid_input_phi_range" \
            -shadowReference 1 \
        } {
            keep -font
        }

        itk_component add startStrategy {
            DCS::Button $stgSite.start \
            -text "Start Strategy Calculation" \
            -command "$this startNodeStrategy"
        } {
            keep -font
        }

        grid $itk_component(strategyNode)       -row 0 -column 0 -sticky w
        grid $itk_component(attenuation)        -row 1 -column 0 -sticky w
        grid $itk_component(space_group)        -row 4 -column 0 -sticky w
        grid $itk_component(top_dir)            -row 5 -column 0 -sticky w
        grid $itk_component(startStrategy)      -row 9 -column 0 -sticky w

        grid $itk_component(cbStrategyEnabled) -row 0 -column 0 -sticky w
        grid $itk_component(xfelStrategyFrame) -row 1 -column 0 -sticky w
        grid remove $itk_component(xfelStrategyFrame)

        grid columnconfigure $itk_interior 0 -weight 10
        eval itk_initialize $args

        announceExist

        $itk_component(startStrategy) addInput \
        "::gCurrentGridGroup current_grid_runnable 1 {cannot run}"

        gCurrentGridGroup register $this current_grid handleGridUpdate
    }
    destructor {
        gCurrentGridGroup unregister $this current_grid handleGridUpdate

        ::mediator announceDestruction $this
    }
}
body GridSingleShotStrategyView::handleGridUpdate { - ready_ - contents_ - } {
    set m_ready 0
    if {!$ready_} {
        return
    }
    set m_origGridContents $contents_
    refreshGrid
}
body GridSingleShotStrategyView::refreshGrid { } {
    set m_groupId [gCurrentGridGroup getId]
    set m_snapId  [gCurrentGridGroup getCurrentSnapshotId]

    if {$itk_option(-onNew)} {
        set m_gridId -1
    } else {
        set m_gridId  [gCurrentGridGroup getCurrentGridId]
    }

    set ll [llength $m_origGridContents]
    if {$ll < 6 || $itk_option(-onNew)} {
        set m_d_userSetup [gCurrentGridGroup getDefaultUserSetup $itk_option(-purpose)]
    } else {
        set m_d_userSetup [lindex $m_origGridContents 5]
    }
    refreshDisplay
    set m_ready 1
}
body GridSingleShotStrategyView::refreshDisplay { } {
    puts "STRATEGE refreshDisplay:"
    if {[catch {dict get $m_d_userSetup shape} shape]} {
        set shape unknown
    }
    if {[catch {dict get $m_d_userSetup for_lcls} forLCLS]} {
        set forLCLS 0
    }
    if {$shape != "crystal" || $forLCLS != "1"} {
        return
    }

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
            eval $itk_component($name) setValue $value 1
        }
    }

    if {[catch {dict get $m_d_userSetup num_column} nNode]} {
        set nNode 1
    }
    set mChoice [list]
    for {set i 1} {$i <= $nNode} {incr i} {
        lappend mChoice $i
    }
    puts "node choices: $mChoice"
    $itk_component(strategyNode) configure \
    -menuChoices $mChoice

    if {[catch {dict get $m_d_userSetup strategy_enable} yn]} {
        set yn 0
    }
    showStrategy $yn

    if {$numError} {
        puts "failed to update, the dict=$m_d_userSetup"
        if {$m_d_userSetup == ""} {
            puts "contents=$contents_"
        }
    }
}
class GridResolutionView {
    inherit ::itk::Widget DCS::Component

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -purpose purpose Purpose $gGridPurpose

    public method handleGridUpdate { - ready_ - contents_ - }

    constructor { args } {
        global gMotorHorz
        global gMotorVert

        itk_component add resolution {
            DCS::ResolutionWidget $itk_interior.res \
            -detectorBackground #c0c0ff \
            -detectorForeground white \
            -detectorXWidget ::device::$gMotorHorz \
            -detectorYWidget ::device::$gMotorVert \
        } {
        }

        pack $itk_component(resolution) -expand 1 -fill both

        eval itk_initialize $args
        announceExist

        gCurrentGridGroup register $this current_grid handleGridUpdate
    }
    destructor {
        gCurrentGridGroup unregister $this current_grid handleGridUpdate

        ::mediator announceDestruction $this
    }
}
body GridResolutionView::handleGridUpdate { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    set ll [llength $contents_]
    if {$ll < 6} {
        set d_userSetup \
        [gCurrentGridGroup getDefaultUserSetup $itk_option(-purpose)]
    } else {
        set d_userSetup [lindex $contents_ 5]
        set contentsPurpose \
        [::GridGroup::GridGroupBase::retrievePurpose $d_userSetup]
        if {$contentsPurpose != $itk_option(-purpose)} {
            puts "RESOLUTION: purpose option=$itk_option(-purpose) contents=$contentsPurpose"
            set d_userSetup \
            [gCurrentGridGroup getDefaultUserSetup $itk_option(-purpose)]
        }
    }
    if {![dict exists $d_userSetup distance] \
    ||  ![dict exists $d_userSetup beam_stop]} {
        return
    }
    set e [lindex [::device::energy getScaledPosition] 0]
    switch -exact -- $itk_option(-purpose) {
        forLCLSCrystal -
        forCrystal {
            set e [lindex [dict get $d_userSetup energy_list] 0]
        }
    }

    set d [dict get $d_userSetup distance]
    set b [dict get $d_userSetup beam_stop]

    puts "RESOLUTION d=$d b=$b e=$e"

    $itk_component(resolution) configure \
    -beamEnergy $e \
    -detectorZInMM $d \
    -beamstopZInMM $b

    ## not sure why this, just copied
    $itk_component(resolution) updateDetectorGraphicsAsync

    set modeIndex [dict get $d_userSetup mode]
    $itk_component(resolution) setMode $modeIndex
}

class GridComboStrategyView {
    inherit ::itk::Widget DCS::Component

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    itk_option define -purpose purpose Purpose $gGridPurpose
    itk_option define -onStart onStart OnStart ""

    ### because raster view and crystal view, "current" grid may be raster
    ### when there is no "crystal".
    itk_option define -onNew onNew OnNew 1 {
        refreshGrid
    }

    public method setWrapper { w } {
        foreach {name -} $COMPONENT2KEY {
            $itk_component($name) addInput \
            "$w current_grid_editable 1 {reset first}"
        }

        foreach name {top_dir space_group} {
            $itk_component($name) addInput \
            "$w current_grid_editable 1 {reset first}"
        }
    }
    public method addInputToStart { trigger_ } {
        $itk_component(startStrategy) addInput $trigger_
    }


    ### for buttons.
    public method startNodeStrategy { } {
        set index [gCurrentGridGroup getGridIndex $m_gridId]

        if {[$itk_component(typeRadio) get] == "phi_osc"} {
            $m_objCollectGrid startOperation $m_groupId $index \
            do_strategy_with_phi_osc
        } else {
            $m_objCollectGrid startOperation $m_groupId $index \
            do_strategy_with_single_shot
        }
    }

    public method setStrategyField { name value } {
        if {!$m_ready} {
            return
        }
        $m_objStrategySoftOnly startOperation set_field $name $value
    }

    public method setField { name value } {
        if {!$m_ready} {
            return
        }

        set param [dict create $name $value]

        if {$m_gridId >= 0} {
                    ### these are done in dcss with class.
                    ### They may be simple change, like detector distance.
                    ### Maybe trigger a group update, including angle of
                    ### node position, like start_angle.
                    ### Maybe even change node selection,
                    ### like strategy_enable, strategy_nodoe.

                    $m_objGridGroupConfig startOperation modifyParameter \
                    $m_groupId $m_gridId $param
        }

        ##################
        #### update latest_user_raster_setup
        ##################

        set contents [$m_objLatestUserSetup getContents]
        set dd [eval dict create $contents]

        dict set dd $name $value
        $m_objLatestUserSetup sendContentsToServer $dd
    }

    public method handleGridUpdate { - ready_ - contents_ - }
    public method handlePhiNodeListUpdate { - ready_ - contents_ - }

    public method showStrategy { yn } {
        if {$yn == "1"} {
            grid $itk_component(xfelStrategyFrame)
        } else {
            grid remove $itk_component(xfelStrategyFrame)
        }
    }
    public method handleTypeSelect { } {
        switch -exact -- [$itk_component(typeRadio) get] {
            phi_osc {
                grid remove $itk_component(stgAtt)
                grid $itk_component(attenuation)
                grid $itk_component(exposureTime)
                grid $itk_component(delta)
                grid $itk_component(cbPhiOscEnabled)
                grid $itk_component(numPhiShot)
            }
            single_shot -
            default {
                grid $itk_component(stgAtt)
                grid remove $itk_component(attenuation)
                grid remove $itk_component(exposureTime)
                grid remove $itk_component(delta)
                grid remove $itk_component(cbPhiOscEnabled)
                grid remove $itk_component(numPhiShot)
            }
        }
    }
    private method refreshGrid { }

    private method refreshDisplay { }

    private common COMPONENT2KEY [list \
    exposureTime        time \
    delta               delta \
    attenuation         attenuation \
    strategyNode        strategy_node \
    numPhiShot          num_phi_shot \
    cbPhiOscEnabled     phi_osc_on_strategy \
    cbStrategyEnabled   strategy_enable \
    ]

    private variable m_ready 0
    private variable m_objCollectGrid ""
    private variable m_objGridGroupConfig ""
    private variable m_objLatestUserSetup ""
    private variable m_groupId -1
    private variable m_snapId -1
    private variable m_gridId -1
    private variable m_d_userSetup ""

    private variable m_origGridContents ""

    private variable m_strInput ""
    private variable m_objStrategySoftOnly ""

    private common PADY 2

    private common PROMPT_WIDTH 15

    constructor { args} {
        global gMotorDistance
        global gMotorBeamStop
        global gMotorEnergy
        global gMotorPhi
        global gMotorBeamWidth
        global gMotorBeamHeight

        set deviceFactory [::DCS::DeviceFactory::getObject]

        set m_objCollectGrid [$deviceFactory createOperation collectGrid]

        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        set m_objLatestUserSetup \
        [$deviceFactory createString latest_raster_user_setup]

        set m_strInput [$deviceFactory createString multiStrategy_input]
        $m_strInput createAttributeFromKey space_group
        $m_strInput createAttributeFromKey phi_range
        $m_strInput createAttributeFromKey top_dir
        $m_strInput createAttributeFromKey attenuation

        set m_objStrategySoftOnly \
        [$deviceFactory createOperation multiCrystalStrategySoftOnly]

        itk_component add cbStrategyEnabled {
            DCS::Checkbutton $itk_interior.firstNodeStg \
            -text "Do Strategy Calculation Before Collecting Data" \
            -shadowReference 0 \
            -command "$this setField strategy_enable %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add xfelStrategyFrame {
            iwidgets::labeledframe $itk_interior.xfelstgF \
            -labeltext "Strategy Calculation Setup" \
            -labelfont "helvetica -16 bold" \
        } {
        }
        set stgSite [$itk_component(xfelStrategyFrame) childsite]

        itk_component add typeRadio {
            iwidgets::radiobox $stgSite.typeRadio \
            -orient horizontal \
            -labeltext "Strategy Image Type" \
            -labelpos nw \
            -selectcolor red \
            -command "$this handleTypeSelect" \
        } {
            keep -background
        }
        $itk_component(typeRadio) add single_shot \
        -text "Single Shot"
        $itk_component(typeRadio) add phi_osc \
        -text "Phi Oscillation"

        itk_component add strategyNode {
            DCS::MenuEntry $stgSite.node \
            -menuChoices {1 2 3} \
            -promptWidth $PROMPT_WIDTH \
            -promptText "Position Num: " \
            -showEntry 0 \
            -showUnits 0 \
            -entryWidth 11 \
            -entryType positiveInt \
            -entryJustify right \
            -onSubmit "$this setField strategy_node %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add attenuation {
            DCS::MotorViewEntry $stgSite.attenuation \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -leaveSubmit 1 \
            -promptText "Attenuation: " \
            -promptWidth $PROMPT_WIDTH \
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
            keep -font
        }

        itk_component add exposureTime {
            DCS::Entry $stgSite.time \
            -leaveSubmit 1 \
            -promptText "Time: " \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -units "s" \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -onSubmit "$this setField time %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }
        itk_component add delta {
            DCS::Entry $stgSite.delta \
            -promptText "Delta: " \
            -leaveSubmit 1 \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -shadowReference 0 \
            -onSubmit "$this setField delta %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add stgAtt {
            DCS::MotorViewEntry $stgSite.stgatt \
            -checkLimits -1 \
            -menuChoiceDelta 10 \
            -device ::device::attenuation \
            -showPrompt 1 \
            -promptText "Attenuation: " \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 10 \
            -units "%" \
            -unitsList "%" \
            -entryType positiveFloat \
            -entryJustify right \
            -escapeToDefault 0 \
            -autoConversion 1 \
            -shadowReference 1 \
            -alterUpdateSubmit 0 \
            -alternateShadowReference "$m_strInput attenuation" \
            -onSubmit "$this setStrategyField attenuation %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add space_group {
            DCS::Entry $stgSite.spaceGroup \
            -state normal \
            -leaveSubmit 1 \
            -entryType field \
            -entryWidth 20 \
            -entryJustify left \
            -entryMaxLength 100 \
            -promptText "SpaceGroup: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 1 \
            -reference "$m_strInput space_group" \
            -onSubmit "$this setStrategyField space_group %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add top_dir {
            DCS::Entry $stgSite.top_dir \
            -state normal \
            -leaveSubmit 1 \
            -entryType rootDirectory \
            -entryWidth 40 \
            -entryJustify left \
            -entryMaxLength 128 \
            -promptText "Top Dir: " \
            -promptWidth $PROMPT_WIDTH \
            -shadowReference 1 \
            -reference "$m_strInput top_dir" \
            -onSubmit "$this setStrategyField top_dir %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add phi_range {
            DCS::Entry $stgSite.phiRange \
            -promptText "Phi Range: " \
            -state labeled \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 11 \
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -reference "::gCurrentGridGroup current_grid_input_phi_range" \
            -shadowReference 1 \
        } {
            keep -font
        }

        itk_component add cbPhiOscEnabled {
            DCS::Checkbutton $stgSite.doPhiOsc \
            -text "Do Phi Osic While Waiting for Strategy Result" \
            -shadowReference 0 \
            -command "$this setField phi_osc_on_strategy %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add numPhiShot {
            DCS::Entry $stgSite.numPhiShot \
            -promptText "Num Phi Shot: " \
            -leaveSubmit 1 \
            -promptWidth $PROMPT_WIDTH \
            -entryWidth 2 \
            -entryType positiveInt \
            -entryJustify right \
            -shadowReference 0 \
            -onSubmit "$this setField num_phi_shot %s" \
        } {
            keep -activeClientOnly -systemIdleOnly
            keep -font
        }

        itk_component add startStrategy {
            DCS::Button $stgSite.start \
            -text "Start Strategy Calculation" \
            -command "$this startNodeStrategy"
        } {
            keep -font
        }

        grid $itk_component(typeRadio)          -row 0 -column 0 -sticky w
        grid $itk_component(strategyNode)       -row 1 -column 0 -sticky w
        grid $itk_component(attenuation)        -row 2 -column 0 -sticky w
        grid $itk_component(stgAtt)             -row 3 -column 0 -sticky w
        grid $itk_component(exposureTime)       -row 4 -column 0 -sticky w
        grid $itk_component(delta)              -row 5 -column 0 -sticky w
        grid $itk_component(space_group)        -row 6 -column 0 -sticky w
        grid $itk_component(top_dir)            -row 7 -column 0 -sticky w
        grid $itk_component(phi_range)          -row 8 -column 0 -sticky w
        grid $itk_component(cbPhiOscEnabled)    -row 9 -column 0 -sticky w
        grid $itk_component(numPhiShot)         -row 10 -column 0 -sticky w
        grid $itk_component(startStrategy)      -row 11 -column 0 -sticky w

        grid $itk_component(cbStrategyEnabled) -row 0 -column 0 -sticky w
        grid $itk_component(xfelStrategyFrame) -row 1 -column 0 -sticky w
        grid remove $itk_component(xfelStrategyFrame)

        grid columnconfigure $itk_interior 0 -weight 10
        eval itk_initialize $args

        announceExist

        $itk_component(startStrategy) addInput \
        "::gCurrentGridGroup current_grid_runnable 1 {cannot run}"

        gCurrentGridGroup register $this current_grid handleGridUpdate

        $itk_component(typeRadio) select 0
    }
    destructor {
        gCurrentGridGroup unregister $this current_grid handleGridUpdate

        ::mediator announceDestruction $this
    }
}
body GridComboStrategyView::handleGridUpdate { - ready_ - contents_ - } {
    set m_ready 0
    if {!$ready_} {
        return
    }
    set m_origGridContents $contents_
    refreshGrid
}
body GridComboStrategyView::refreshGrid { } {
    set m_groupId [gCurrentGridGroup getId]
    set m_snapId  [gCurrentGridGroup getCurrentSnapshotId]

    if {$itk_option(-onNew)} {
        set m_gridId -1
    } else {
        set m_gridId  [gCurrentGridGroup getCurrentGridId]
    }

    set ll [llength $m_origGridContents]
    if {$ll < 6 || $itk_option(-onNew)} {
        set m_d_userSetup [gCurrentGridGroup getDefaultUserSetup $itk_option(-purpose)]
    } else {
        set m_d_userSetup [lindex $m_origGridContents 5]
    }
    refreshDisplay
    set m_ready 1
}
body GridComboStrategyView::refreshDisplay { } {
    puts "STRATEGE refreshDisplay:"
    if {[catch {dict get $m_d_userSetup shape} shape]} {
        set shape unknown
    }
    if {[catch {dict get $m_d_userSetup for_lcls} forLCLS]} {
        set forLCLS 0
    }
    if {$shape != "crystal" || $forLCLS != "1"} {
        return
    }

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
            eval $itk_component($name) setValue $value 1
        }
    }

    if {[catch {dict get $m_d_userSetup num_column} nNode]} {
        set nNode 1
    }
    set mChoice [list]
    for {set i 1} {$i <= $nNode} {incr i} {
        lappend mChoice $i
    }
    puts "node choices: $mChoice"
    $itk_component(strategyNode) configure \
    -menuChoices $mChoice

    if {[catch {dict get $m_d_userSetup strategy_enable} yn]} {
        set yn 0
    }
    showStrategy $yn

    if {$numError} {
        puts "failed to update, the dict=$m_d_userSetup"
        if {$m_d_userSetup == ""} {
            puts "contents=$contents_"
        }
    }
}
class GridItemDisplayOptionWidget {
    inherit ::DCS::ComponentGateExtension

    itk_option define -purpose purpose Purpose $gGridPurpose {
        switch -exact -- $itk_option(-purpose) {
            forPXL614 -
            forLCLSCrystal {
                grid $itk_component(numField)
                grid $itk_component(contourField)
                grid $itk_component(contourLevel)
                grid $itk_component(showRasterToo)
            }
            forCrystal {
                grid remove $itk_component(numField)
                grid remove $itk_component(contourField)
                grid remove $itk_component(contourLevel)
                grid $itk_component(showRasterToo)
            }
            default {
                grid $itk_component(numField)
                grid $itk_component(contourField)
                grid $itk_component(contourLevel)
                grid remove $itk_component(showRasterToo)
            }
        }
    }

    itk_option define -displayControl displayControl DisplayMaster "" {
        if {$itk_option(-displayControl) != $m_displayControl} {
            if {$m_displayControl != ""} {
                $itk_component(numField) deleteInput \
                "$m_displayControl click_to_move"

                $itk_component(contourField) deleteInput \
                "$m_displayControl click_to_move"
            }

            set m_displayControl $itk_option(-displayControl)

            foreach {name att} \
            {numField       number_display_field \
            contourField    contour_display_field \
            contourLevel    contour_display_level \
            beamInfo        beam_display_option \
            onlyShowCurrent show_only_current_grid \
            showRasterToo   show_raster_too} {
                set key $m_displayControl
                if {$key != ""} {
                    lappend key $att
                }

                $itk_component($name) configure \
                -reference $key
            }
            if {$m_displayControl != ""} {
                $itk_component(numField) addInput \
                "$m_displayControl click_to_move 0 {Disabled By Align Visually}"

                $itk_component(contourField) addInput \
                "$m_displayControl click_to_move 0 {Disabled By Align Visually}"
            }
        }
    }

    public method setNumberDisplayField { args } {
        if {$itk_option(-displayControl) == ""} {
            log_error no displayControl defined
            return
        }
        $itk_option(-displayControl) setNumberField "$args"
    }
    public method setContourDisplayField { args } {
        if {$itk_option(-displayControl) == ""} {
            log_error no displayControl defined
            return
        }
        $itk_option(-displayControl) setContourField "$args"
    }
    public method setContourLevels { args } {
        if {$itk_option(-displayControl) == ""} {
            log_error no displayControl defined
            return
        }
        $itk_option(-displayControl) setContourLevels "$args"
    }
    public method setBeamDisplayOption { name } {
        if {$itk_option(-displayControl) == ""} {
            log_error no displayControl defined
            return
        }
        $itk_option(-displayControl) setBeamDisplayOption $name
    }
    public method setShowOnly { v } {
        if {$itk_option(-displayControl) == ""} {
            log_error no displayControl defined
            return
        }
        $itk_option(-displayControl) setShowOnlyCurrentGrid $v
    }
    public method setShowRaster { v } {
        if {$itk_option(-displayControl) == ""} {
            log_error no displayControl defined
            return
        }
        $itk_option(-displayControl) setShowRasterToo $v
    }
    private variable m_displayControl ""

    constructor { args } {
        set numChoices $GridNodeListView::FIELD_NAME
        set numChoices [linsert $numChoices 0 None Frame]

        set ENTRY_WIDTH 12

        itk_component add numField {
            DCS::MenuEntry $itk_interior.number \
            -entryWidth $ENTRY_WIDTH \
            -promptText "Show Number:" \
            -promptWidth 13 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $numChoices \
            -shadowReference 1 \
            -onSubmit "$this setNumberDisplayField %s" \
        } {
            keep -font
        }

        set contourChoices $GridNodeListView::FIELD_NAME
        set contourChoices [linsert $contourChoices 0 None]
        itk_component add contourField {
            DCS::MenuEntry $itk_interior.contour \
            -entryWidth $ENTRY_WIDTH \
            -promptText "Show Contour:" \
            -promptWidth 13 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $contourChoices \
            -shadowReference 1 \
            -onSubmit "$this setContourDisplayField %s" \
        } {
            keep -font
        }

        set levelChoices [list \
        "10 25 50 75 90" \
        50 \
        "50 line only" \
        "50 90" \
        ]
        itk_component add contourLevel {
            DCS::MenuEntry $itk_interior.level \
            -entryWidth $ENTRY_WIDTH \
            -promptText "Contour Levels:" \
            -promptWidth 13 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $levelChoices \
            -shadowReference 1 \
            -onSubmit "$this setContourLevels %s" \
        } {
            keep -font
        }

        set beamChoices "Cross Box Cross_And_Box None"
        itk_component add beamInfo {
            DCS::MenuEntry $itk_interior.binfo \
            -entryWidth $ENTRY_WIDTH \
            -promptText "Show Beam:" \
            -promptWidth 13 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -showEntry 0 \
            -menuChoices $beamChoices \
            -shadowReference 1 \
            -onSubmit "$this setBeamDisplayOption %s" \
        } {
            keep -font
        }

        itk_component add onlyShowCurrent {
            DCS::Checkbutton $itk_interior.onlyCurrent \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -justify left \
            -anchor w \
            -text "Only Show Current Item" \
            -shadowReference 1 \
            -command "$this setShowOnly %s" \
            -onBackground yellow \
        } {
            keep -font
        }

        itk_component add showRasterToo {
            DCS::Checkbutton $itk_interior.rasterToo \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -justify left \
            -anchor w \
            -text "Show Rasters" \
            -shadowReference 1 \
            -command "$this setShowRaster %s" \
            -onBackground yellow \
        } {
            keep -font
        }

        grid $itk_component(numField)           -row 0 -column 0 -sticky w
        grid $itk_component(contourField)       -row 1 -column 0 -sticky w
        grid $itk_component(contourLevel)       -row 2 -column 0 -sticky w
        grid $itk_component(beamInfo)           -row 3 -column 0 -sticky w
        grid $itk_component(onlyShowCurrent)    -row 4 -column 0 -sticky w
        grid $itk_component(showRasterToo)      -row 5 -column 0 -sticky w

        eval itk_initialize $args
        announceExist
    }
}

class GridItemProjectiveBase {
    inherit GridItemBase

    proc create { c x y h }
    proc instantiate { c h gridId info } {
        set item [GridItemProjectiveBase ::#auto $c {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }

    public method getShape { } {
        return "projective"
    }

    public method manualScale { w h } {
        log_error Sizing not supported by Projective Grid 

        ## no need to update
        return 0
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
        set m_point0 [xyToSamplePosition $x $y]
        set m_numPointDefined 1
        $m_holder registerImageMotionCallback "$this imageMotion"
        drawPotentialPosition $m_point0
    }
    public method getItemInfo { } {
        set result [GridItemBase::getItemInfo]
        #[list $orig $geoList $gridList $m_nodeList $m_extraUserParameters]
        set geoList [lindex $result 1]
        dict set geoList num_anchor $m_numAnchorPoint
        dict set geoList num_border $m_numBorderPoint
        set result [lreplace $result 1 1 $geoList]

        return $result
    }
    public method updateFromInfo { info {redraw 1}} {
        foreach {orig geo grid node frame status hide parameter} $info break
        if {[catch {dict get $geo num_anchor} m_numAnchorPoint]} {
            set m_numAnchorPoint 4
        }
        if {[catch {dict get $geo num_border} m_numBorderPoint]} {
            set m_numBorderPoint 4
        }
        return [GridItemBase::updateFromInfo $info $redraw]
    }

    public method setNode { index status }
    protected method generateGridMatrix { }
    protected method rebornGridMatrix { }
    protected method redrawGridMatrix { }
    protected method drawAllVertices { }

    protected method drawPotentialPosition { p }
    protected method calculateHolePosition

    protected method regenerateLocalCoords { }

    protected method updateBorder { }

    protected method generateBorderFromAnchor { }

    ##these only used during creation
    protected variable m_point0 ""
    protected variable m_point1 ""
    protected variable m_point2 ""
    protected variable m_point3 ""
    protected variable m_hotSpotCoords ""
    protected variable m_idExtra ""
    protected variable m_numPointDefined 0
    protected variable m_anchorPosList ""
    ### empty m_borderPosList will use m_anchorPosList
    protected variable m_borderPosList ""
    protected variable m_samplePosList ""
    protected variable m_numAnchorPoint 4
    protected variable m_numBorderPoint 4

    ## microns
    protected variable m_hole_radius 60.0

    protected common COLOR_HOLE_DONE        cyan
    protected common COLOR_HOLE_WITH_SAMPLE green
    protected common COLOR_HOLE_EMPTY       gray 
    protected common COLOR_HOLE_LABEL       white

    constructor { canvas id mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        set m_gridOnTopOfBody 1
        set m_showOutline 0
        set m_showRotor 0
        setSequenceType zigzag
    }
}
body GridItemProjectiveBase::create { c x y h } {
    #puts "enter Trap create c=$c"
    foreach {w -} [$h getDisplayPixelSize] break

    set id [$c create line \
    0 $y $w $y \
    -width 1 \
    -fill red \
    -dash . \
    -tags rubberband \
    ]

    set item [GridItemProjectiveBase ::#auto $c $id template $h]
    #puts "new item=$item"
    $item setStartPoint $x $y

    $h setNotice "Anchor Point 2\n "

    return $item
}
body GridItemProjectiveBase::imageMotion { x y } {
    switch -exact -- $m_numPointDefined {
        2 {
            foreach {x0 y0} [samplePositionToXy $m_point0] break
            $m_canvas coords $m_guiId $x0 $y0 $x $y
        }
        3 {
            foreach {x1 y1} [samplePositionToXy $m_point1] break
            $m_canvas coords $m_idExtra $x1 $y1 $x $y
        }
    }
}

body GridItemProjectiveBase::regenerateLocalCoords { } {
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

    #### setup projective mapping
    foreach {u0 v0 u1 v1 u2 v2 u3 v3} $m_anchorPosList break
    foreach {x0 y0 x3 y3 x2 y2 x1 y1} $m_hotSpotCoords break

    set x0 [expr $x0 - $m_centerX]
    set x1 [expr $x1 - $m_centerX]
    set x2 [expr $x2 - $m_centerX]
    set x3 [expr $x3 - $m_centerX]
    set y0 [expr $y0 - $m_centerY]
    set y1 [expr $y1 - $m_centerY]
    set y2 [expr $y2 - $m_centerY]
    set y3 [expr $y3 - $m_centerY]

    set uvxyList $m_anchorPosList
    lappend uvxyList $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3

    gGridBilinearCalculator quickSetup $uvxyList

    ### border for now, just use the anchor points
    set xyList [gGridBilinearCalculator quickMap $m_borderPosList]
    eval lappend m_localCoords $xyList

    set xyList [gGridBilinearCalculator quickMap $m_samplePosList]
    eval lappend m_localCoords $xyList
    #saveLocalCoords
}

body GridItemProjectiveBase::createPress { x y } {
    puts "Projective create press $x $y numDefined=$m_numPointDefined"

    set m_point$m_numPointDefined [xyToSamplePosition $x $y]
    incr m_numPointDefined
    switch -exact -- $m_numPointDefined {
        1 {
            ## should not be here
            return
        }
        2 {
            foreach {w h} [$m_holder getDisplayPixelSize] break
            foreach {x1 y1} [samplePositionToXy $m_point1] break
            set m_idExtra [$m_canvas create line \
            0 $y1 $w $y1 \
            -width 1 \
            -fill $GridGroupColor::COLOR_RUBBERBAND \
            -dash . \
            -tags rubberband \
            ]
            $m_holder setNotice "1. Click >> to move and center between 2 anchor points of other end.\n2. Click Anchor3"
            return
        }
        3 {
            $m_canvas itemconfig $m_guiId \
            -width 2 \
            -fill red \
            -dash "" \
            -tags [list raster item_$m_guiId]

            $m_holder setNotice "Click Anchor4\n "
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

    foreach {x0 y0} [samplePositionToXy $m_point0] break
    foreach {x1 y1} [samplePositionToXy $m_point1] break
    foreach {x2 y2} [samplePositionToXy $m_point2] break
    foreach {x3 y3} [samplePositionToXy $m_point3] break

    set sz0 [lindex $m_point0 2]
    set sz2 [lindex $m_point2 2]
    if {$sz0 > $sz2 || [getShape] == "mesh"} {
        set m_hotSpotCoords [list $x0 $y0 $x1 $y1 $x3 $y3 $x2 $y2]
    } else {
        set m_hotSpotCoords [list $x2 $y2 $x3 $y3 $x1 $y1 $x0 $y0]
    }
    set coords $m_hotSpotCoords
    #puts "create coords: $coords"

    set m_guiId [$m_canvas create polygon $coords \
    -width 1 \
    -outline $GridGroupColor::COLOR_SHAPE_CURRENT \
    -fill "" \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    set m_allGuiIdList $m_guiId

    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize

    regenerateLocalCoords

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "l614 created: $m_guiId item=$this"
    #puts "coords $coords"

    generateGridMatrix

    $m_holder addItem $this
}
body GridItemProjectiveBase::_draw { } {
    set m_hotSpotCoords ""
    set endIdx [expr 2 * $m_numAnchorPoint - 1]
    set vertexCoords [lrange $m_localCoords 0 $endIdx]
    foreach {lx ly} $vertexCoords {
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]
        lappend m_hotSpotCoords $x $y
    }

    set drawCoords ""
    set startIdx [expr 2 * $m_numAnchorPoint]
    set endIdx   [expr $startIdx + 2 * $m_numBorderPoint - 1]
    set bodyCoords [lrange $m_localCoords $startIdx $endIdx]
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

    set m_allGuiIdList $m_guiId

    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "polygon reborn: $m_guiId item=$this"
}
body GridItemProjectiveBase::reborn { gridId info } {
    GridItemBase::reborn $gridId $info

    if {[shouldDisplay]} {
        _draw
    }

    $m_holder addItem $this 0
}
body GridItemProjectiveBase::redraw { fromGUI } {
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
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                set coords [$m_canvas coords $m_guiId]
                foreach {- - x y} $coords break
                $m_canvas coords $m_guiId $x0 $y0 $x $y
            }
            2 {
                drawPotentialPosition $m_point0
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                foreach {x1 y1} [samplePositionToXy $m_point1] break
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
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                foreach {x1 y1} [samplePositionToXy $m_point1] break
                $m_canvas coords $m_guiId $x0 $y0 $x1 $y1
                $m_canvas itemconfig $m_guiId \
                -width 2 \
                -fill red \
                -dash "" \
                -tags [list raster item_$m_guiId]

                ### do "3" own
                foreach {x2 y2} [samplePositionToXy $m_point2] break
                set coords [$m_canvas coords $m_idExtra]
                foreach {- - x y} $coords break
                $m_canvas coords $m_idExtra $x2 $y2 $x $y
            }
        }
        return
    } else {
        set m_hotSpotCoords ""
        set endIdx [expr 2 * $m_numAnchorPoint - 1]
        set vertexCoords [lrange $m_localCoords 0 $endIdx]
        foreach {lx ly} $vertexCoords {
            set x [expr $m_centerX + $lx]
            set y [expr $m_centerY + $ly]
            lappend m_hotSpotCoords $x $y
        }
        updateBorder
    }
    redrawHotSpots $fromGUI
}
body GridItemProjectiveBase::drawAllVertices { } {
    set coords $m_hotSpotCoords
    set index -1
    foreach {x y} $coords {
        incr index
        drawVertex $index $x $y
    }
}
body GridItemProjectiveBase::vertexMotion { x y } {
    #puts "L614 hotSpotMotion $x $y"
    set index [expr $m_indexVertex * 2]

    set m_hotSpotCoords \
    [lreplace $m_hotSpotCoords $index [expr $index + 1] $x $y]

    #puts "hotSpot changed to $m_hotSpotCoords"

    regenerateLocalCoords

    updateBorder
    redrawHotSpots 1
}
body GridItemProjectiveBase::drawPotentialPosition { p } {
    foreach {px py} [samplePositionToXy $p] break

    foreach {u0 v0 u1 v1 u2 v2 u3 v3} $m_anchorPosList break

    set horz [expr abs($u2 - $u0)]
    set vert [expr abs($v2 - $v0)]

    #puts "anchorlist: $m_anchorPosList"
    #puts "horz=$horz vert=$vert"

    $m_canvas delete ruler_$m_guiId

    foreach {dx100 dy100 ruler_horz ruler_vert} \
    [$m_holder micron2pixel 100 100 $horz $vert] break

    ### 1 of "Anchor 1" (already clicked)
    set y [expr $py - $dy100]
    set x $px
    $m_canvas create text $x $y \
    -text "Anchor 1" \
    -font "-family courier -size 16" \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -anchor s \
    -tags [list ruler_$m_guiId rubberband item_$m_guiId]

    ### 2 of "Anchor 2": one above 1, the other below
    set x [expr $px + $dx100]
    for {set i 0} {$i < 2} {incr i} {
        set y [expr $py + (2 * $i - 1) * $ruler_vert]
        $m_canvas create text $x $y \
        -text "Anchor 2" \
        -font "-family courier -size 16" \
        -fill $GridGroupColor::COLOR_RUBBERBAND \
        -anchor e \
        -tags [list ruler_$m_guiId rubberband item_$m_guiId]
    }

    #### 2 of "Anchor 3": one left, the other right
    set y [expr $py - $dy100]
    for {set i 0} {$i < 2} {incr i} {
        set x [expr $px + (2 * $i - 1) * $ruler_horz]
        $m_canvas create text $x $y \
        -text "Amchor 3" \
        -font "-family courier -size 16" \
        -fill $GridGroupColor::COLOR_RUBBERBAND \
        -anchor s \
        -tags [list ruler_$m_guiId rubberband item_$m_guiId]
    }

    #### 4 of "Anchor 4"
    for {set i 0} {$i < 2} {incr i} {
        set y [expr $py + (2 * $i - 1) * $ruler_vert]
        for {set j 0} {$j < 2} {incr j} {
            set x [expr $px + (2 * $j - 1) * $ruler_horz]
            $m_canvas create text $x $y \
            -text "Amchor 4" \
            -font "-family courier -size 16" \
            -fill $GridGroupColor::COLOR_RUBBERBAND \
            -anchor s \
            -tags [list ruler_$m_guiId rubberband item_$m_guiId]
        }
    }
}
body GridItemProjectiveBase::updateBorder { } {
    set drawCoords ""
    set startIdx [expr 2 * $m_numAnchorPoint]
    set endIdx   [expr $startIdx + 2 * $m_numBorderPoint - 1]
    set bodyCoords [lrange $m_localCoords $startIdx $endIdx]
    foreach {lx ly} $bodyCoords {
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]
        lappend drawCoords $x $y
    }
    $m_canvas coords $m_guiId $drawCoords
    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize
}
body GridItemProjectiveBase::generateGridMatrix { } {
    #puts "generateGridMatrix for $this"
    ##set m_nodeList ""
    $m_canvas delete grid_$m_guiId

    set m_gridCenterX $m_centerX
    set m_gridCenterY $m_centerY

    set numHole [llength $m_samplePosList]
    set numHole [expr $numHole / 2 ]
    if {[llength $m_nodeList] != $numHole} {
        set m_nodeList [string repeat "S " $numHole]
    }
    contourSetup

    $m_canvas delete grid_$m_guiId
    set currentOrig [$m_holder getDisplayOrig]
    set r $m_hole_radius
    foreach {ux uy} \
    [translateProjectionBox $r $r $m_oOrig $currentOrig] break
    foreach {xr yr} [$m_holder micron2pixel $ux $uy] break

    set startIdx [expr 2 * ($m_numAnchorPoint + $m_numBorderPoint)]
    set holePositionList [lrange $m_localCoords $startIdx end]
    set index -1
    foreach {lx ly} $holePositionList {
        incr index

        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]

        set x1 [expr $x - $xr]
        set y1 [expr $y - $yr]
        set x2 [expr $x + $xr]
        set y2 [expr $y + $yr]

        $m_canvas create rectangle $x1 $y1 $x2 $y2 \
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
    $m_canvas raise hotspot_$m_guiId
}
body GridItemProjectiveBase::rebornGridMatrix { } {
    contourSetup
    redrawGridMatrix
}

body GridItemProjectiveBase::redrawGridMatrix { } {
    if {$m_displayControl == ""} {
        set fieldName Frame
    } else {
        set fieldName [$m_displayControl getNumberField]
    }

    set nodeColorList [getContourDisplayList]

    if {$nodeColorList == [generateEmptyDisplayList]} {
        $m_obj setValues ""
    } else {
        $m_obj setValues $nodeColorList
    }

    set nodeLabelList [getNumberDisplayList]
    set font_sizeW [expr int(abs(0.4 * $m_cellWidth))]
    set font_sizeH [expr int(abs(0.4 * $m_cellHeight))]
    set font_size [expr ($font_sizeW > $font_sizeH)?$font_sizeH:$font_sizeW]
    if {$font_size > 16} {
        set font_size 16
    }

    $m_canvas delete grid_$m_guiId

    set currentOrig [$m_holder getDisplayOrig]
    set r $m_hole_radius
    foreach {ux uy} \
    [translateProjectionBox $r $r $m_oOrig $currentOrig] break
    foreach {xr yr} [$m_holder micron2pixel $ux $uy] break

    set startIdx [expr 2 * ($m_numAnchorPoint + $m_numBorderPoint)]
    set holePositionList [lrange $m_localCoords $startIdx end]
    set index -1
    foreach {lx ly} $holePositionList {
        incr index
        set row [expr $index / $m_numCol]
        set col [expr $index % $m_numCol]

        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]

        set holeLabel [lindex $m_nodeLabelList $index]

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
                set c_row [expr $index / $m_numCol]
                set c_col [expr $index % $m_numCol]
                set color      [$m_obj getColor $c_row $c_col]
                if {$color >= 0} {
                    set fill [format "\#%02x%02x%02x" $color $color $color]
                 }
            }
        }

        set hid [$m_canvas create rectangle $x1 $y1 $x2 $y2 \
        -outline $outline \
        -fill $fill \
        -tags \
        [list grid grid_$m_guiId node_${m_guiId}_${index}] \
        ]
        $m_canvas bind $hid <Button-1> "$this gridPress $row $col %x %y"
        ## to trigger click inside the hole
        set hid [$m_canvas create rectangle $x1 $y1 $x2 $y2 \
        -outline "" \
        -fill "" \
        -tags \
        [list grid grid_$m_guiId nodehide_${m_guiId}_${index}] \
        ]
        $m_canvas bind $hid <Button-1> "$this gridPress $row $col %x %y"

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

        #puts "draw label index=$index label=$holeLabel"

        if {$fieldName != "Frame"} {
            continue
        }

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
    $m_canvas raise hotspot_$m_guiId
}
body GridItemProjectiveBase::setNode { index status } {
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

    set noFill 0
    if {[string first only [getContourLevels]] >= 0} {
        set noFill 1
    }
    
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
            set c_row [expr $index / $m_numCol]
            set c_col [expr $index % $m_numCol]
            set color      [$m_obj getColor $c_row $c_col]
            if {$color >= 0} {
                set fill [format "\#%02x%02x%02x" $color $color $color]
             }
        }
    }
    if {$noFill} {
        set fill ""
    }
    $m_canvas itemconfigure $nodeTag \
    -outline $outline \
    -fill $fill
}
body GridItemProjectiveBase::generateBorderFromAnchor { } {
    set m_borderPosList $m_anchorPosList
    set m_numBorderPoint [expr [llength $m_borderPosList] / 2]
}
class GridItemTrapArray {
    inherit GridItemProjectiveBase

    proc create { c x y h }
    proc instantiate { c h gridId info } {
        set item [GridItemTrapArray ::#auto $c {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }
    public method getShape { } {
        return "trap_array"
    }
    #public method getItemInfo { } {
    #    set result [GridItemProjectiveBase::getItemInfo]
    #    #[list $orig $geoList $gridList $m_nodeList $m_extraUserParameters]
    #    set gridList [lindex $result 2]
    #    dict set gridList cell_width        $DISTANCE_HOLE_HORZ
    #    dict set gridList cell_height       $DISTANCE_HOLE_VERT
    #    set result [lreplace $result 2 2 $gridList]

    #    return $result
    #}

    public method setupSourcePositions { anchorList borderList pList row col } {
        set m_anchorPosList $anchorList
        set m_borderPosList $borderList
        set m_numAnchorPoint [expr [llength $m_anchorPosList] / 2]
        set m_numBorderPoint [expr [llength $m_borderPosList] / 2]
        if {$m_numBorderPoint == 0} {
            generateBorderFromAnchor
        }

        set m_nodeLabelList ""
        set m_samplePosList ""
        foreach p $pList {
            foreach {label u v} $p break
            lappend m_nodeLabelList $label
            lappend m_samplePosList $u $v
        }

        set m_numRow $row
        set m_numCol $col
    }

    protected common DISTANCE_HOLE_HORZ 150.0
    protected common DISTANCE_HOLE_VERT 300.0

    constructor { canvas id mode holder } {
        GridItemProjectiveBase::constructor $canvas $id $mode $holder
    } {
        set m_oCellWidth  $DISTANCE_HOLE_HORZ
        set m_oCellHeight $DISTANCE_HOLE_VERT
        set m_hole_radius 15.0

        ####
        set anchorList [list \
        0.0     0.0 \
        14850.0 0.0 \
        14850.0 2100.0 \
        0.0     2100.0 \
        ]

        set borderList [list \
        -300.0  -300.0 \
        15150.0 -300.0 \
        15150.0 2400.0 \
        -300.0  2400.0 \
        ]


        set pList ""
        set labelList [list A B C D E F G H]
        for {set row 0} {$row < 8} {incr row} {
            set v [expr 300.0 * $row]
            set ll0 [lindex $labelList $row]
            for {set col 0} {$col < 100} {incr col} {
                set u [expr $col * 150.0]
                set ll $ll0[expr $col + 1]
                set p [list $ll $u $v]
                lappend pList $p
            }
        }

        setupSourcePositions $anchorList $borderList $pList 8 100
        updateGrid
    }
}
body GridItemTrapArray::create { c x y h } {
    #puts "enter Trap create c=$c"
    foreach {w -} [$h getDisplayPixelSize] break

    set id [$c create line \
    0 $y $w $y \
    -width 1 \
    -fill red \
    -dash . \
    -tags rubberband \
    ]

    set item [GridItemTrapArray ::#auto $c $id template $h]
    #puts "new item=$item"
    $item setStartPoint $x $y

    $h setNotice "Anchor Point 2\n "

    return $item
}
class GridItemMesh {
    inherit GridItemProjectiveBase

    public proc create { c x y h }
    public proc instantiate { c h gridId info } {
        set item [GridItemMesh ::#auto $c {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }

    protected proc retrieveSampleLocation { path }

    public method getShape { } {
        return "mesh"
    }
    public method setupSourcePositions { anchorCoords sampleCoords }

    ### need to override these
    public method getItemInfo { } {
        set result [GridItemProjectiveBase::getItemInfo]
        #[list $orig $geoList $gridList $m_nodeList $m_extraUserParameters]
        set geoList [lindex $result 1]
        dict set geoList anchor_coords $m_anchorPosList
        dict set geoList sample_coords $m_samplePosList
        set result [lreplace $result 1 1 $geoList]

        return $result
    }
    public method updateFromInfo { info {redraw 1}} {
        foreach {orig geo grid node frame status hide parameter} $info break
        set m_anchorPosList [dict get $geo anchor_coords]
        set m_samplePosList [dict get $geo sample_coords]
        set numSample [expr [llength $m_samplePosList] / 2]

        set m_nodeLabelList ""
        for {set i 1} {$i <= $numSample} {incr i} {
            lappend m_nodeLabelList $i
        }
        generateBorderFromAnchor

        return [GridItemProjectiveBase::updateFromInfo $info $redraw]
    }

    protected common s_anchorCoords ""
    protected common s_sampleCoords ""

    constructor { canvas id mode holder } {
        GridItemProjectiveBase::constructor $canvas $id $mode $holder
    } {
        ### for text size
        set m_oCellWidth  160.0
        set m_oCellHeight 160.0
        set m_hole_radius 10.0
        set m_oItemWidth 1000.0
        set m_oItemHeight 1000.0
        setSequenceType horz
        updateGrid
    }
}
body GridItemMesh::create { c x y h } {
    #puts "enter mesh create c=$c"
    set deviceFactory [::DCS::DeviceFactory::getObject]
    set strCrystalStatus  [$deviceFactory createString crystalStatus]
    set ctxCrystalStatus  [$strCrystalStatus getContents]
    set filePath [lindex $ctxCrystalStatus 7]
    if {$filePath == ""} {
        log_error no sample location file found
        return ""
    }
    set filePath [file join ~ $filePath]
    if {![retrieveSampleLocation $filePath]} {
        log_error failed to parse $filePath
        return ""
    }

    foreach {w -} [$h getDisplayPixelSize] break

    set id [$c create line \
    0 $y $w $y \
    -width 1 \
    -fill red \
    -dash . \
    -tags rubberband \
    ]

    set item [GridItemMesh ::#auto $c $id template $h]
    #puts "new item=$item"
    $item setupSourcePositions $s_anchorCoords $s_sampleCoords
    $item setStartPoint $x $y


    $h setNotice "Anchor Point 2\n "

    return $item
}
body GridItemMesh::setupSourcePositions { anchorCoords sampleCoords } {
    set m_nodeLabelList ""
    set m_anchorPosList $anchorCoords
    set m_numAnchorPoint [expr [llength $m_anchorPosList] / 2]
    generateBorderFromAnchor
    set m_samplePosList $sampleCoords

    set numSample [expr [llength $m_samplePosList] / 2]

    for {set i 1} {$i <= $numSample} {incr i} {
        lappend m_nodeLabelList $i
    }

    set m_numRow 1
    set m_numCol $numSample
}

body GridItemMesh::retrieveSampleLocation { path } {
    set s_anchorCoords ""
    set s_sampleCoords ""


    if {[catch {open $path r} h]} {
        log_error cannot open $path to read
        return 0
    }
    set contents [read -nonewline $h]
    close $h
    set contents [split $contents \n]

    set num 0
    foreach line $contents {
        if {[string index $line 0] == "#"} {
            ### skip the line
            continue
        }
        incr num
        switch -exact -- $num {
            1 -
            2 -
            3 -
            4 {
                if {[string range $line 0 8] != "anchor$num: "} {
                    log_error bad header $line
                    return 0
                }
                set coords [string range $line 9 end]
                foreach {x y} $coords break
                if {[string is double -strict $x] \
                &&  [string is double -strict $y]} {
                    set anchorP$num [list $x $y]
                } else {
                    log_error bad anchor coords $line
                    return 0
                }
            }
            default {
                foreach {x y} $line break
                if {[string is double -strict $x] \
                &&  [string is double -strict $y]} {
                    lappend s_sampleCoords $x $y
                } else {
                    log_error bad sample coords $line at $num
                    return 0
                }
            }
        }
    }

    set s_anchorCoords $anchorP1
    eval lappend s_anchorCoords $anchorP3 $anchorP4 $anchorP2
    return 1
}
class GridItemTrapArrayLinear {
    inherit GridItemBase

    proc create { c x y h }
    proc instantiate { c h gridId info } {
        set item [GridItemTrapArrayLinear ::#auto $c {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }

    public method getShape { } {
        return "trap_array"
    }

    public method manualScale { w h } {
        log_error Sizing not supported by L614 Grid 

        ## no need to update
        return 0
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
        set m_point0 [xyToSamplePosition $x $y]
        set m_numPointDefined 1
        $m_holder registerImageMotionCallback "$this imageMotion"
        drawPotentialPosition $m_point0
    }

    ### need to override these
    public method getItemInfo { } {
        set result [GridItemBase::getItemInfo]
        #[list $orig $geoList $gridList $m_nodeList $m_extraUserParameters]
        set gridList [lindex $result 2]
        dict set gridList num_column_picked $m_numColPicked
        dict set gridList num_row_picked    $m_numRowPicked
        dict set gridList cell_width        $DISTANCE_HOLE_HORZ
        dict set gridList cell_height       $DISTANCE_HOLE_VERT
        set result [lreplace $result 2 2 $gridList]

        return $result
    }
    public method updateFromInfo { info {redraw 1}} {
        foreach {orig geo grid node frame status hide parameter} $info break
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

    private method updateBorder { }

    private method checkPositionRelation { } {
        set currentOrig [$m_holder getDisplayOrig]

        foreach {x0 y0 z0} $m_point0 break
        foreach {x1 y1 z1} $m_point1 break
        foreach {x2 y2 z2} $m_point2 break
        foreach {x3 y3 z3} $m_point3 break

        foreach {uy0 ux0} \
        [calculateProjectionFromSamplePosition $currentOrig $x0 $y0 $z0 1] break

        foreach {uy1 ux1} \
        [calculateProjectionFromSamplePosition $currentOrig $x1 $y1 $z1 1] break

        foreach {uy2 ux2} \
        [calculateProjectionFromSamplePosition $currentOrig $x2 $y2 $z2 1] break

        foreach {uy3 ux3} \
        [calculateProjectionFromSamplePosition $currentOrig $x3 $y3 $z3 1] break

        set h1 [expr abs($ux0 - $ux1)]
        set h2 [expr abs($ux2 - $ux3)]
        set v1 [expr abs($uy0 - $uy3)]
        set v2 [expr abs($uy2 - $uy1)]

        set h [expr ($h1 + $h1) / 2.0]

        ## we want to allow 99, 89, 79...9
        set m_numColPicked [expr round( $h / ($DISTANCE_HOLE_HORZ * 10.0))]
        set m_numColPicked [expr $m_numColPicked * 10 - 1]
        puts "DEBUG num column picked $m_numColPicked"
        if {$m_numColPicked < 9} {
            set m_numColPicked 9
        }
        if {$m_numColPicked >= $NUM_HOLE_HORZ} {
            set m_numColPicked [expr $NUM_HOLE_HORZ -1]
            puts "DEBUG forced back to $m_numColPicked"
        }

        set vPerfect [expr 7.0 * $DISTANCE_HOLE_VERT]
        set hPerfect [expr $m_numColPicked * $DISTANCE_HOLE_HORZ]
        set txt [expr $m_numColPicked + 1]
        set vTol 100
        set hTol [expr 50 * $m_numColPicked]

        puts "DEBUG num column picked $m_numColPicked"

        set dv1 [expr abs($v1 - $vPerfect)]
        set dv2 [expr abs($v2 - $vPerfect)]
        set dh1 [expr abs($h1 - $hPerfect)]
        set dh2 [expr abs($h2 - $hPerfect)]
        if {$dv1 > $vTol} {
            log_error A1 and H1 distance=$dv1 microns not accurate
        }
        if {$dv2 > $vTol} {
            log_error A$txt and H$txt distance=$dv2 microns not accurate
        }
        if {$dh1 > $hTol} {
            log_error A1 and H$txt distance=$dh1 microns not accurate
        }
        if {$dh2 > $hTol} {
            log_error H1 and H$txt distance=$dh2 microns not accurate
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
    private variable m_numRowPicked 7
    private variable m_numColPicked 9

    private common NUM_HOLE_HORZ 100
    private common NUM_HOLE_VERT 8
    ## microns
    #### NodeListView needs hole radius to create sub-raster
    private common DISTANCE_HOLE_HORZ 150.0
    private common DISTANCE_HOLE_VERT 300.0

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
    }
}
body GridItemTrapArrayLinear::create { c x y h } {
    #puts "enter L614 create c=$c"
    foreach {w -} [$h getDisplayPixelSize] break

    set id [$c create line \
    0 $y $w $y \
    -width 1 \
    -fill red \
    -dash . \
    -tags rubberband \
    ]

    set item [GridItemTrapArrayLinear ::#auto $c $id template $h]
    #puts "new item=$item"
    $item setStartPoint $x $y

    $h setNotice "Click A100\n "

    return $item
}
body GridItemTrapArrayLinear::imageMotion { x y } {
    switch -exact -- $m_numPointDefined {
        1 {
            foreach {x0 y0} [samplePositionToXy $m_point0] break
            $m_canvas coords $m_guiId $x0 $y0 $x $y
        }
        3 {
            foreach {x2 y2} [samplePositionToXy $m_point2] break
            $m_canvas coords $m_idExtra $x2 $y2 $x $y
        }
    }
}

body GridItemTrapArrayLinear::regenerateLocalCoords { } {
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
        for {set col 0} {$col <= $m_numColPicked} {incr col} {
            set index [expr $row * $m_numCol + $col]
            set x [expr $ax + $col * $kx]
            set y [expr $ay + $col * $ky]

            set lx [expr $x - $m_centerX]
            set ly [expr $y - $m_centerY]
            lappend m_localCoords $lx $ly
        }
    }
    set m_nodeLabelList ""
    set rLabelList [list A B C D E F G H]
    for {set row 0} {$row < $NUM_HOLE_VERT} {incr row} {
        set rowLabel [lindex $rLabelList $row]
        for {set col 0} {$col <= $m_numColPicked} {incr col} {
            set holeLabel $rowLabel[expr $col + 1]
            lappend m_nodeLabelList $holeLabel
        }
    }

    #saveLocalCoords
}

body GridItemTrapArrayLinear::createPress { x y } {
    puts "TrapArray create press $x $y numDefined=$m_numPointDefined"

    set m_point$m_numPointDefined [xyToSamplePosition $x $y]
    incr m_numPointDefined
    switch -exact -- $m_numPointDefined {
        1 {
            ## should not be here
            return
        }
        3 {
            foreach {w h} [$m_holder getDisplayPixelSize] break
            foreach {x2 y2} [samplePositionToXy $m_point2] break
            set m_idExtra [$m_canvas create line \
            0 $y2 $w $y2 \
            -width 1 \
            -fill $GridGroupColor::COLOR_RUBBERBAND \
            -dash . \
            -tags rubberband \
            ]
            $m_holder setNotice "1. Click << to move to H1.\n2. Click H1"
            return
        }
        2 {
            $m_canvas itemconfig $m_guiId \
            -width 2 \
            -fill red \
            -dash "" \
            -tags [list raster item_$m_guiId]

            foreach {x0 y0 z0} $m_point0 break
            foreach {x1 y1 z1} $m_point1 break

            set currentOrig [$m_holder getDisplayOrig]
            foreach {uy0 ux0} \
            [calculateProjectionFromSamplePosition $currentOrig $x0 $y0 $z0 1] break

            foreach {uy1 ux1} \
            [calculateProjectionFromSamplePosition $currentOrig $x1 $y1 $z1 1] break

            set h [expr abs($ux0 - $ux1)]
            set m_numColPicked [expr round( $h / ($DISTANCE_HOLE_HORZ * 10.0))]
            set m_numColPicked [expr $m_numColPicked * 10 - 1]
            puts "DEBUG num column picked $m_numColPicked"
            if {$m_numColPicked < 9} {
                set m_numColPicked 9
            }
            if {$m_numColPicked >= $NUM_HOLE_HORZ} {
                set m_numColPicked [expr $NUM_HOLE_HORZ -1]
                puts "DEBUG forced back to $m_numColPicked"
            }

            $m_holder setNotice "Click H[expr $m_numColPicked + 1]\n "
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

    foreach {x0 y0} [samplePositionToXy $m_point0] break
    foreach {x1 y1} [samplePositionToXy $m_point1] break
    foreach {x2 y2} [samplePositionToXy $m_point2] break
    foreach {x3 y3} [samplePositionToXy $m_point3] break
    set m_hotSpotCoords [list $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3]
    set coords $m_hotSpotCoords
    #puts "create coords: $coords"

    set m_guiId [$m_canvas create polygon $coords \
    -width 1 \
    -outline $GridGroupColor::COLOR_SHAPE_CURRENT \
    -fill "" \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    set m_allGuiIdList $m_guiId

    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize

    regenerateLocalCoords

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "l614 created: $m_guiId item=$this"
    #puts "coords $coords"

    generateGridMatrix

    $m_holder addItem $this
}
body GridItemTrapArrayLinear::_draw { } {
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

    set m_allGuiIdList $m_guiId

    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "polygon reborn: $m_guiId item=$this"
}
body GridItemTrapArrayLinear::reborn { gridId info } {
    GridItemBase::reborn $gridId $info

    if {[shouldDisplay]} {
        _draw
    }

    $m_holder addItem $this 0
}
body GridItemTrapArrayLinear::redraw { fromGUI } {
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
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                set coords [$m_canvas coords $m_guiId]
                foreach {- - x y} $coords break
                $m_canvas coords $m_guiId $x0 $y0 $x $y
            }
            2 {
                drawPotentialPosition $m_point0
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                foreach {x1 y1} [samplePositionToXy $m_point1] break
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
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                foreach {x1 y1} [samplePositionToXy $m_point1] break
                $m_canvas coords $m_guiId $x0 $y0 $x1 $y1
                $m_canvas itemconfig $m_guiId \
                -width 2 \
                -fill red \
                -dash "" \
                -tags [list raster item_$m_guiId]

                ### do "3" own
                foreach {x2 y2} [samplePositionToXy $m_point2] break
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
body GridItemTrapArrayLinear::drawAllVertices { } {
    set coords $m_hotSpotCoords
    set index -1
    foreach {x y} $coords {
        incr index
        drawVertex $index $x $y
    }
}
body GridItemTrapArrayLinear::vertexMotion { x y } {
    #puts "L614 hotSpotMotion $x $y"
    set index [expr $m_indexVertex * 2]

    set m_hotSpotCoords \
    [lreplace $m_hotSpotCoords $index [expr $index + 1] $x $y]

    #puts "hotSpot changed to $m_hotSpotCoords"

    regenerateLocalCoords

    updateBorder
    redrawHotSpots 1
}
body GridItemTrapArrayLinear::drawPotentialPosition { p } {
    foreach {px py} [samplePositionToXy $p] break

    $m_canvas delete ruler_$m_guiId

    set distance_mark_horz [expr $DISTANCE_HOLE_HORZ *  10]
    set distance_mark_vert [expr $DISTANCE_HOLE_VERT * 7]
    foreach {dx100 dy100 mark_horz mark_vert hole_horz hole_vert} \
    [$m_holder micron2pixel 100 100 \
    $distance_mark_horz $distance_mark_vert \
    $DISTANCE_HOLE_HORZ $DISTANCE_HOLE_VERT] break

    ### 1 of "Anchor 1" (already clicked)
    set y [expr $py - $dy100]
    set x $px
    $m_canvas create text $x $y \
    -text "A1" \
    -font "-family courier -size 16" \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -anchor s \
    -tags [list ruler_$m_guiId rubberband item_$m_guiId]

    ### 2 of "Anchor 2": one above 1, the other below
    set x [expr $px + $dx100]
    for {set i 0} {$i < 2} {incr i} {
        set y [expr $py + (2 * $i - 1) * $mark_vert]
        $m_canvas create text $x $y \
        -text "H1" \
        -font "-family courier -size 16" \
        -fill $GridGroupColor::COLOR_RUBBERBAND \
        -anchor e \
        -tags [list ruler_$m_guiId rubberband item_$m_guiId]
    }

    #### 2 of "Anchor 3": one left, the other right
    set numMark [expr $NUM_HOLE_HORZ / 10]
    set y [expr $py - $dy100]
    set x0 [expr $px - $hole_horz]
    for {set i 1} {$i <= $numMark} {incr i} {
        set x [expr $x0 + $i * $mark_horz]
        set txt A[expr $i * 10 ]
        $m_canvas create text $x $y \
        -text $txt \
        -font "-family courier -size 16" \
        -fill $GridGroupColor::COLOR_RUBBERBAND \
        -anchor s \
        -tags [list ruler_$m_guiId rubberband item_$m_guiId]
    }
}
body GridItemTrapArrayLinear::updateBorder { } {
    set drawCoords ""
    set bodyCoords [lrange $m_localCoords 8 15]
    foreach {lx ly} $bodyCoords {
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]
        lappend drawCoords $x $y
    }
    $m_canvas coords $m_guiId $drawCoords
    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize
}
body GridItemTrapArrayLinear::generateGridMatrix { } {
    #puts "generateGridMatrix for $this"
    ##set m_nodeList ""
    $m_canvas delete grid_$m_guiId

    set m_gridCenterX $m_centerX
    set m_gridCenterY $m_centerY

    set m_numCol [expr $m_numColPicked + 1]
    set m_numRow $NUM_HOLE_VERT
    set numHole [expr $m_numCol * $m_numRow]
    if {[llength $m_nodeList] != $numHole} {
        set m_nodeList [string repeat "S " $numHole]
    }
    contourSetup

    $m_canvas delete grid_$m_guiId
    set radiusList ""
    set currentOrig [$m_holder getDisplayOrig]
    set r 10.0
    foreach {ux uy} \
    [translateProjectionBox $r $r $m_oOrig $currentOrig] break
    foreach {xr yr} [$m_holder micron2pixel $ux $uy] break

    set holePositionList [lrange $m_localCoords 16 end]
    set index -1
    foreach {lx ly} $holePositionList {
        incr index
        set row [expr $index / $m_numCol]
        set col [expr $index % $m_numCol]

        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]

        set x1 [expr $x - $xr]
        set y1 [expr $y - $yr]
        set x2 [expr $x + $xr]
        set y2 [expr $y + $yr]

        $m_canvas create rectangle $x1 $y1 $x2 $y2 \
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
    $m_canvas raise hotspot_$m_guiId
}
body GridItemTrapArrayLinear::rebornGridMatrix { } {
    contourSetup
    redrawGridMatrix
}
body GridItemTrapArrayLinear::calculateHolePosition { } {
    ## 4 points (row, col)
    ### if numColPicked==4
    ## case 1: from left
    #  D1:  (0.98, 0)
    #  B1:  (1.76, 0)
    #  D5:  (0.98, 4)
    #  B5:  (1.76, 4)
    #
    # case 2: from right
    #  D15  (0.98, 14)
    #  B15  (1.76, 14)
    #  D11  (0.98, 10)
    #  B11  (1.76, 10)

    ### check it is case 1 or case 2
    foreach {x0 y0 x1 y1 x3 y3 x2 y2} $m_localCoords break
    foreach {ux0 uy0 ux1 uy1} [$m_holder pixel2micron $x0 $y0 $x1 $y1] break

    puts "tipping check 0=($ux0, $uy0) 1=($ux1, $uy1)"
    if {$ux0 > $ux1} {
        ### from tip to base
        #set firstColIndex [expr $NUM_HOLE_HORZ - 1]
        set firstColIndex $m_numColPicked
        set sign -1
    } else {
        ### from base to tip
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
    set rowAVert 0.0
    set rowHVert 2.1
    ### for shape
    set m_shapeCoords ""
    set rowVertList [list -0.3 2.4]

    #set borderCol [expr $NUM_HOLE_HORZ - 0.5]
    #set borderCol [expr $m_numColPicked + 0.5]
    set borderCol [expr $m_numColPicked + 1.25]
    set colList [list [list -1.25 $borderCol] [list $borderCol -1.25]]
    for {set row 0} {$row < 2} {incr row} {
        set rowVert [lindex $rowVertList $row]
        set factor [expr ($rowVert - $rowAVert) / ($rowHVert - $rowAVert)]

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
    set rowVertList [list 0.0 0.3 0.6 0.9 1.2 1.5 1.8 2.1]
    for {set row 0} {$row < $NUM_HOLE_VERT} {incr row} {
        set rowVert [lindex $rowVertList $row]

        set factor [expr ($rowVert - $rowAVert) / ($rowHVert - $rowAVert)]

        set xRow0 [expr $x0 + ($x2 - $x0) * $factor]
        set yRow0 [expr $y0 + ($y2 - $y0) * $factor]

        set xRow1 [expr $x1 + ($x3 - $x1) * $factor]
        set yRow1 [expr $y1 + ($y3 - $y1) * $factor]

        set kx [expr $sign * ($xRow1 - $xRow0) / $m_numColPicked]
        set ky [expr $sign * ($yRow1 - $yRow0) / $m_numColPicked]

        set ax [expr $xRow0 - $firstColIndex * $kx]
        set ay [expr $yRow0 - $firstColIndex * $ky]

        lappend result [list $ax $kx $ay $ky]
    }
    #puts "calculatHolePosition: $result"
    return $result
}

body GridItemTrapArrayLinear::redrawGridMatrix { } {
    if {$m_displayControl == ""} {
        set fieldName Frame
    } else {
        set fieldName [$m_displayControl getNumberField]
    }

    set nodeColorList [getContourDisplayList]

    if {$nodeColorList == [generateEmptyDisplayList]} {
        $m_obj setValues ""
    } else {
        $m_obj setValues $nodeColorList
    }

    set nodeLabelList [getNumberDisplayList]
    set font_sizeW [expr int(abs(0.4 * $m_cellWidth))]
    set font_sizeH [expr int(abs(0.4 * $m_cellHeight))]
    set font_size [expr ($font_sizeW > $font_sizeH)?$font_sizeH:$font_sizeW]
    if {$font_size > 16} {
        set font_size 16
    }

    $m_canvas delete grid_$m_guiId

    set currentOrig [$m_holder getDisplayOrig]
    set radiusList ""
    set r 10
    foreach {ux uy} \
    [translateProjectionBox $r $r $m_oOrig $currentOrig] break
    foreach {xr yr} [$m_holder micron2pixel $ux $uy] break

    set holePositionList [lrange $m_localCoords 16 end]
    set index -1

    foreach {lx ly} $holePositionList {
        incr index
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]

        set row [expr $index / $m_numCol]
        set col [expr $index % $m_numCol]

        set holeLabel [lindex $m_nodeLabelList $index]

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
                set c_row [expr $index / $m_numCol]
                set c_col [expr $index % $m_numCol]
                set color      [$m_obj getColor $c_row $c_col]
                if {$color >= 0} {
                    set fill [format "\#%02x%02x%02x" $color $color $color]
                 }
            }
        }

        set hid [$m_canvas create rectangle $x1 $y1 $x2 $y2 \
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

        #puts "draw label index=$index label=$holeLabel"

        if {$fieldName != "Frame"} {
            continue
        }

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
    $m_canvas raise hotspot_$m_guiId
}
body GridItemTrapArrayLinear::setNode { index status } {
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

    set noFill 0
    if {[string first only [getContourLevels]] >= 0} {
        set noFill 1
    }
    
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
            set c_row [expr $index / $m_numCol]
            set c_col [expr $index % $m_numCol]
            set color      [$m_obj getColor $c_row $c_col]
            if {$color >= 0} {
                set fill [format "\#%02x%02x%02x" $color $color $color]
             }
        }
    }
    if {$noFill} {
        set fill ""
    }
    $m_canvas itemconfigure $nodeTag \
    -outline $outline \
    -fill $fill
}

class GridItemNetBase {
    inherit GridItemBase

    proc create { c x y h }
    proc instantiate { c h gridId info } {
        set item [GridItemNetBase ::#auto $c {} adjustable $h]
        $item reborn $gridId $info
        return $item
    }

    public method getShape { } {
        return "trap_array"
    }

    public method manualScale { w h } {
        log_error Sizing not supported by L614 Grid 

        ## no need to update
        return 0
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
        set m_point0 [xyToSamplePosition $x $y]
        set m_numPointDefined 1
        $m_holder registerImageMotionCallback "$this imageMotion"
        drawPotentialPosition2
    }

    ### need to override these
    public method getItemInfo { } {
        set result [GridItemBase::getItemInfo]
        #[list $orig $geoList $gridList $m_nodeList $m_extraUserParameters]
        set geoList [lindex $result 1]
        dict set geoList num_anchor $m_numAnchorPoint
        dict set geoList num_border $m_numBorderPoint
        dict set geoList hot_spot_row_list $m_hotSpotRowUsed
        dict set geoList hot_spot_column_list $m_hotSpotColUsed
        dict set geoList section_list $m_sectionList
        dict set geoList hotspot_to_section_map $m_hotSpot2SectionMap
        set result [lreplace $result 1 1 $geoList]

        return $result
    }
    public method updateFromInfo { info {redraw 1}} {
        foreach {orig geo grid node frame status hide parameter} $info break
        set m_hotSpotRowUsed [dict get $geo hot_spot_row_list]
        set m_hotSpotColUsed [dict get $geo hot_spot_column_list]
        set m_sectionList [dict get $geo section_list]
        puts "got sectionList= $m_sectionList"
        set m_hotSpot2SectionMap [dict get $geo hotspot_to_section_map]
        if {[catch {dict get $geo num_anchor} m_numAnchorPoint]} {
            set m_numAnchorPoint 4
        }
        if {[catch {dict get $geo num_border} m_numBorderPoint]} {
            set m_numBorderPoint 4
        }

        return [GridItemBase::updateFromInfo $info $redraw]
    }
    public method setNode { index status }

    protected method generateSectionInfo { }

    protected method generateGridMatrix { }
    protected method rebornGridMatrix { }
    protected method redrawGridMatrix { }
    protected method drawAllVertices { }

    protected method drawPotentialPosition2 { }
    protected method drawPotentialPosition3 { }
    protected method drawPotentialPosition4 { }

    ### this one will fill the initial hotspot positions.
    protected method firstTimeGenerateLocalCoords { }

    protected method regenerateLocalCoords { hotSpotindex }

    protected method updateBorder { }

    ### can override.
    protected method getNodeLabel { row col } {
        if {$row == "MAX"} {
            set row [expr $m_maxNumRow - 1]
        }
        if {$col == "MAX"} {
            set col [expr $m_maxNumCol - 1]
        }
        if {$row < 25} {
            return [binary format c [expr $row + 65]][expr $col + 1]
        }
        return "R[expr $row + 1]C[expr $col + 1]"
    }

    protected method checkPositionRelation { } {
        set currentOrig [$m_holder getDisplayOrig]

        foreach {x0 y0 z0} $m_point0 break
        foreach {x1 y1 z1} $m_point1 break
        foreach {x2 y2 z2} $m_point2 break
        foreach {x3 y3 z3} $m_point3 break

        foreach {uy0 ux0} \
        [calculateProjectionFromSamplePosition $currentOrig $x0 $y0 $z0 1] break

        foreach {uy1 ux1} \
        [calculateProjectionFromSamplePosition $currentOrig $x1 $y1 $z1 1] break

        foreach {uy2 ux2} \
        [calculateProjectionFromSamplePosition $currentOrig $x2 $y2 $z2 1] break

        foreach {uy3 ux3} \
        [calculateProjectionFromSamplePosition $currentOrig $x3 $y3 $z3 1] break

        set h1 [expr abs($ux0 - $ux1)]
        set h2 [expr abs($ux2 - $ux3)]
        set v1 [expr abs($uy0 - $uy3)]
        set v2 [expr abs($uy2 - $uy1)]

        set vPerfect [expr [expr $m_numRow - 1] * $m_oCellHeight]
        set hPerfect [expr [expr $m_numCol - 1] * $m_oCellWidth]
        set vTol [expr 50 * $m_numRow]
        set hTol [expr 50 * $m_numCol]

        set dv1 [expr abs($v1 - $vPerfect)]
        set dv2 [expr abs($v2 - $vPerfect)]
        set dh1 [expr abs($h1 - $hPerfect)]
        set dh2 [expr abs($h2 - $hPerfect)]
        if {$dv1 > $vTol} {
            set lb1 [getNodeLabel 0                    0]
            set lb2 [getNodeLabel [expr $m_numRow - 1] 0]
            log_error $lb1 and $lb2 distance=$dv1 microns not accurate
        }
        if {$dv2 > $vTol} {
            set lb1 [getNodeLabel 0                    [expr $m_numCol - 1]]
            set lb2 [getNodeLabel [expr $m_numRow - 1] [expr $m_numCol - 1]]
            log_error $lb1 and $lb2 distance=$dv2 microns not accurate
        }
        if {$dh1 > $hTol} {
            set lb1 [getNodeLabel 0 0]
            set lb2 [getNodeLabel 0 [expr $m_numCol - 1]]
            log_error $lb1 and $lb2 distance=$dh1 microns not accurate
        }
        if {$dh2 > $hTol} {
            set lb1 [getNodeLabel [expr $m_numRow - 1] 0]
            set lb2 [getNodeLabel [expr $m_numRow - 1] [expr $m_numCol - 1]]
            log_error $lb1 and $lb2 distance=$dh2 microns not accurate
        }
    }

    ##these only used during creation
    protected variable m_point0 ""
    protected variable m_point1 ""
    protected variable m_point2 ""
    protected variable m_point3 ""
    protected variable m_hotSpotCoords ""
    protected variable m_idExtra ""
    protected variable m_numPointDefined 0
    protected variable m_numAnchorPoint 4
    protected variable m_numBorderPoint 4

    #### derived class must set in constructor:
    protected variable m_maxNumCol 100
    protected variable m_maxNumRow 8
    protected variable m_oCellWidth 150.0
    protected variable m_oCellHeight 300.0
    ### m_allowedXXX will be used to generate the ruler for
    #potential click points.
    ## the max num row or column is optional at the end.
    protected variable m_allowedNumColList [list 10 20 30 40 50 60 70 80 90 100]
    protected variable m_allowedNumRowList [list 4 8]
    ## index from 0
    protected variable m_extraHotSpotColList [list 19 39 59 79]
    protected variable m_extraHotSpotRowList 4

    ### generated by createPress at last point
    ### from extraHotSpot row and column list.
    ### These are the raw data save to item.
    protected variable m_hotSpotColUsed [list 0 19]
    protected variable m_hotSpotRowUsed [list 0 4 7]
    ### following information can be derived from hotSpotCol/RowUsed,
    ### but they are frequently used when hotspot was dragged.
    ### so, we save them and directly use them to speed up the drag update.
    ## each section:
    ## 4 hotspot index, node start row, end row, start col, end col.
    protected variable m_sectionList ""
    ### each hotspot can have 1, 2, or 4 affected sections.
    protected variable m_hotSpot2SectionMap ""

    ### hotSpot must follow order normal matrix order
    ### (0, 0), (0, 19), (0, 29), (7, 0), (7, 19), (7, 29).
    ### nodes between them will be bilinear interpolate from the rectangle.
    ### drag one hotspot may cause max 4 sections to remap.

    protected common COLOR_HOLE_DONE        cyan
    protected common COLOR_HOLE_WITH_SAMPLE green
    protected common COLOR_HOLE_EMPTY       gray 
    protected common COLOR_HOLE_LABEL       white

    constructor { canvas id mode holder } {
        GridItemBase::constructor $canvas $id $mode $holder
    } {
        set m_gridOnTopOfBody 1
        set m_showOutline 0
        set m_showRotor 0
        setSequenceType horz
        set m_oCellWidth  $m_oCellWidth
        set m_oCellHeight $m_oCellHeight
        updateGrid
    }
}
body GridItemNetBase::create { c x y h } {
    #puts "enter L614 create c=$c"
    foreach {w -} [$h getDisplayPixelSize] break

    set id [$c create line \
    0 $y $w $y \
    -width 1 \
    -fill red \
    -dash . \
    -tags rubberband \
    ]

    set item [GridItemNetBase ::#auto $c $id template $h]
    #puts "new item=$item"
    $item setStartPoint $x $y

    set label [$item getNodeLabel 0 MAX]

    $h setNotice "Click $label\n "

    return $item
}
body GridItemNetBase::imageMotion { x y } {
    switch -exact -- $m_numPointDefined {
        1 {
            foreach {x0 y0} [samplePositionToXy $m_point0] break
            $m_canvas coords $m_guiId $x0 $y0 $x $y
        }
        3 {
            foreach {x2 y2} [samplePositionToXy $m_point2] break
            $m_canvas coords $m_idExtra $x2 $y2 $x $y
        }
    }
}
body GridItemNetBase::generateSectionInfo { } {
    set m_sectionList ""
    ### init m_hotSpot2SectionMap
    set nR [llength $m_hotSpotRowUsed]
    set nC [llength $m_hotSpotColUsed]
    set nHotSpot [expr $nR * $nC]
    set m_hotSpot2SectionMap [string repeat "{} " $nHotSpot]
    set m_hotSpot2SectionMap [string trim $m_hotSpot2SectionMap]

    ### hRow, hCol are about hotspot.  nRow, ncol are about node.
    set idxSection -1
    for {set hRow 0} {$hRow < [expr $nR - 1]} {incr hRow} {
        set nRow0 [lindex $m_hotSpotRowUsed $hRow]
        set nRow1 [lindex $m_hotSpotRowUsed [expr $hRow + 1]]
        for {set hCol 0} {$hCol < [expr $nC - 1]} {incr hCol} {
            incr idxSection

            set nCol0 [lindex $m_hotSpotColUsed $hCol]
            set nCol1 [lindex $m_hotSpotColUsed [expr $hCol + 1]]

            set hIndex0 [expr $hRow * $nC + $hCol]
            set hIndex1 [expr $hIndex0 + 1]
            set hIndex2 [expr ($hRow + 1) * $nC + $hCol]
            set hIndex3 [expr $hIndex2 + 1]
            lappend m_sectionList \
            [list $hIndex0 $hIndex1 $hIndex2 $hIndex3 $nRow0 $nRow1 $nCol0 $nCol1]

            ### setup hotspot mapping to this
            foreach hIdx [list $hIndex0 $hIndex1 $hIndex2 $hIndex3] {
                set sList [lindex $m_hotSpot2SectionMap $hIdx]
                lappend sList $idxSection
                lset m_hotSpot2SectionMap $hIdx $sList
            }
        }
    }
}

body GridItemNetBase::firstTimeGenerateLocalCoords { } {
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

    set m_centerX [expr ($x1 + $x2) / 2.0]
    set m_centerY [expr ($y1 + $y2) / 2.0]
    set m_oAngle 0
    ### save centerX/Y
    saveShape
    saveSize [expr $x1 - $x2] [expr $y1 - $y2]
    updateCornerAndRotor

    #### setup projective mapping
    foreach {x0 y0 x1 y1 x2 y2 x3 y3} $m_hotSpotCoords break
    set idxLastCol [expr $m_numCol - 1]
    set idxLastRow [expr $m_numRow - 1]

    set uvxyList [list 0 0 $idxLastCol 0 $idxLastCol $idxLastRow 0 $idxLastRow]

    set x0 [expr $x0 - $m_centerX]
    set x1 [expr $x1 - $m_centerX]
    set x2 [expr $x2 - $m_centerX]
    set x3 [expr $x3 - $m_centerX]
    set y0 [expr $y0 - $m_centerY]
    set y1 [expr $y1 - $m_centerY]
    set y2 [expr $y2 - $m_centerY]
    set y3 [expr $y3 - $m_centerY]

    lappend uvxyList $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3
    gGridBilinearCalculator quickSetup $uvxyList
    puts "firstSetup: $uvxyList"

    ### fill the hotspot list
    set hotSpotList ""
    set m_hotSpotRowUsed ""
    set m_numAnchorPoint 0
    for {set row 0} {$row < $m_numRow} {incr row} {
        if {$row !=0 && $row != $idxLastRow \
        && [lsearch -exact $m_extraHotSpotRowList $row] < 0} {
            continue
        }
        lappend m_hotSpotRowUsed $row
    }
    set m_hotSpotColUsed ""
    for {set col 0} {$col < $m_numCol} {incr col} {
        if {$col != 0 && $col != $idxLastCol \
        && [lsearch -exact $m_extraHotSpotColList $col] < 0} {
            continue
        }
        lappend m_hotSpotColUsed $col
    }

    set hotSpotUVList ""
    set m_numAnchorPoint 0
    foreach row $m_hotSpotRowUsed {
        foreach col $m_hotSpotColUsed {
            lappend hotSpotUVList $col $row
            incr m_numAnchorPoint
        }
    }
    set m_localCoords [gGridBilinearCalculator quickMap $hotSpotUVList]

    ### use m_hotSpotRowUsed and m_hotspotColUsed to fill up the information
    ### about sections.
    generateSectionInfo

    ## for sure we will have 4 or more hotspots

    #### may not needed, the obj will be delete after this. just in case.
    set m_hotSpotCoords ""
    foreach {x y} $m_localCoords {
        set x [expr $x + $m_centerX]
        set y [expr $y + $m_centerY]
        lappend m_hotSpotCoords $x $y
    }

    ### border for now, just use the anchor points
    set borderRow0 -1
    #set borderRow1 [expr $lastRow + 1]
    set borderRow1 $m_numRow
    set borderCol0 -1
    #set borderCol1 [expr $lastCol + 1]
    set borderCol1 $m_numCol
    set borderuvList [list \
    $borderCol0 $borderRow0 \
    $borderCol1 $borderRow0 \
    $borderCol1 $borderRow1 \
    $borderCol0 $borderRow1 \
    ]

    set xyList [gGridBilinearCalculator quickMap $borderuvList]
    eval lappend m_localCoords $xyList

    ### now all the nodes
    set uvList ""
    set m_nodeLabelList ""
    for {set row 0} {$row < $m_numRow} {incr row} {
        for {set col 0} {$col < $m_numCol} {incr col} {
            lappend uvList $col $row
            lappend m_nodeLabelList [getNodeLabel $row $col]
        }
    }
    set xyList [gGridBilinearCalculator quickMap $uvList]
    puts "init xyList $xyList for uvList=$uvList"
    eval lappend m_localCoords $xyList
}

body GridItemNetBase::createPress { x y } {
    puts "NetBase create press $x $y numDefined=$m_numPointDefined"

    set m_point$m_numPointDefined [xyToSamplePosition $x $y]
    incr m_numPointDefined
    switch -exact -- $m_numPointDefined {
        1 {
            ## should not be here
            return
        }
        3 {
            foreach {w h} [$m_holder getDisplayPixelSize] break
            foreach {x2 y2} [samplePositionToXy $m_point2] break
            set m_idExtra [$m_canvas create line \
            0 $y2 $w $y2 \
            -width 1 \
            -fill $GridGroupColor::COLOR_RUBBERBAND \
            -dash . \
            -tags rubberband \
            ]

            ### calculate numRowPicked
            foreach {x1 y1 z1} $m_point1 break
            foreach {x2 y2 z2} $m_point2 break

            set currentOrig [$m_holder getDisplayOrig]
            foreach {uy1 ux1} \
            [calculateProjectionFromSamplePosition $currentOrig $x1 $y1 $z1 1] break

            foreach {uy2 ux2} \
            [calculateProjectionFromSamplePosition $currentOrig $x2 $y2 $z2 1] break

            set v [expr abs($uy1 - $uy2)]
            set numRowPicked [expr round( $v / $m_oCellHeight ) + 1]
            puts "DEBUG num row picked $numRowPicked"
            set m_numRow $m_maxNumRow
            foreach allowedNumRow $m_allowedNumRowList {
                if {$allowedNumRow >= $numRowPicked} {
                    set m_numRow $allowedNumRow
                    break
                }
            }

            if {$m_numRow > $m_maxNumRow} {
                set m_numRow $m_maxNumRow 
                puts "DEBUG forced back to $m_numRow"
            }

            drawPotentialPosition4
            set label [getNodeLabel [expr $m_numRow - 1] 0]
            $m_holder setNotice \
            "1. Click << to move to $label.\n2. Click $label"
            return
        }
        2 {
            $m_canvas itemconfig $m_guiId \
            -width 2 \
            -fill red \
            -dash "" \
            -tags [list raster item_$m_guiId]

            foreach {x0 y0 z0} $m_point0 break
            foreach {x1 y1 z1} $m_point1 break

            set currentOrig [$m_holder getDisplayOrig]
            foreach {uy0 ux0} \
            [calculateProjectionFromSamplePosition $currentOrig $x0 $y0 $z0 1] break

            foreach {uy1 ux1} \
            [calculateProjectionFromSamplePosition $currentOrig $x1 $y1 $z1 1] break

            set h [expr abs($ux0 - $ux1)]
            set numColPicked [expr round( $h / $m_oCellWidth ) + 1]
            puts "DEBUG num column picked $numColPicked"
            set m_numCol $m_maxNumCol
            foreach allowedNumCol $m_allowedNumColList {
                if {$allowedNumCol >= $numColPicked} {
                    set m_numCol $allowedNumCol
                    break
                }
            }


            if {$m_numCol > $m_maxNumCol} {
                set m_numCol $m_maxNumCol 
                puts "DEBUG forced back to $m_numCol"
            }

            set label \
            [getNodeLabel [expr $m_maxNumRow - 1] [expr $m_numCol - 1]]

            drawPotentialPosition3
            $m_holder setNotice "Click $label\n "
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

    foreach {x0 y0} [samplePositionToXy $m_point0] break
    foreach {x1 y1} [samplePositionToXy $m_point1] break
    foreach {x2 y2} [samplePositionToXy $m_point2] break
    foreach {x3 y3} [samplePositionToXy $m_point3] break
    set m_hotSpotCoords [list $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3]
    set coords $m_hotSpotCoords
    #puts "create coords: $coords"

    set m_guiId [$m_canvas create polygon $coords \
    -width 1 \
    -outline $GridGroupColor::COLOR_SHAPE_CURRENT \
    -fill "" \
    -tags raster \
    ]
    $m_canvas addtag item_$m_guiId withtag $m_guiId

    set m_allGuiIdList $m_guiId

    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize

    firstTimeGenerateLocalCoords

    generateGridMatrix

    ### it will be deleted anyway during addItem
    #$m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    #$m_canvas bind item_$m_guiId <Enter>    "$this enter"
    #$m_canvas bind item_$m_guiId <Leave>    "$this leave"

    $m_holder addItem $this
}
body GridItemNetBase::_draw { } {
    set m_hotSpotCoords ""
    set endIdx [expr 2 * $m_numAnchorPoint - 1]
    set vertexCoords [lrange $m_localCoords 0 $endIdx]
    foreach {lx ly} $vertexCoords {
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]
        lappend m_hotSpotCoords $x $y
    }
    set drawCoords ""
    set startIdx [expr 2 * $m_numAnchorPoint]
    set endIdx   [expr $startIdx + 2 * $m_numBorderPoint - 1]
    set bodyCoords [lrange $m_localCoords $startIdx $endIdx]
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

    set m_allGuiIdList $m_guiId

    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize

    $m_canvas bind item_$m_guiId <Button-1> "$this bodyPress %x %y"
    $m_canvas bind item_$m_guiId <Enter>    "$this enter"
    $m_canvas bind item_$m_guiId <Leave>    "$this leave"

    #puts "polygon reborn: $m_guiId item=$this"
}
body GridItemNetBase::reborn { gridId info } {
    GridItemBase::reborn $gridId $info

    if {[shouldDisplay]} {
        _draw
    }

    $m_holder addItem $this 0
}
body GridItemNetBase::redraw { fromGUI } {
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
                drawPotentialPosition2
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                set coords [$m_canvas coords $m_guiId]
                foreach {- - x y} $coords break
                $m_canvas coords $m_guiId $x0 $y0 $x $y
            }
            2 {
                drawPotentialPosition3
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                foreach {x1 y1} [samplePositionToXy $m_point1] break
                $m_canvas coords $m_guiId $x0 $y0 $x1 $y1
                $m_canvas itemconfig $m_guiId \
                -width 2 \
                -fill red \
                -dash "" \
                -tags [list raster item_$m_guiId]
            }
            3 {
                ## repeat "2" first
                drawPotentialPosition4
                foreach {x0 y0} [samplePositionToXy $m_point0] break
                foreach {x1 y1} [samplePositionToXy $m_point1] break
                $m_canvas coords $m_guiId $x0 $y0 $x1 $y1
                $m_canvas itemconfig $m_guiId \
                -width 2 \
                -fill red \
                -dash "" \
                -tags [list raster item_$m_guiId]

                ### do "3" own
                foreach {x2 y2} [samplePositionToXy $m_point2] break
                set coords [$m_canvas coords $m_idExtra]
                foreach {- - x y} $coords break
                $m_canvas coords $m_idExtra $x2 $y2 $x $y
            }
        }
        return
    } else {
        set m_hotSpotCoords ""
        set endIdx [expr 2 * $m_numAnchorPoint - 1]
        set vertexCoords [lrange $m_localCoords 0 $endIdx]
        foreach {lx ly} $vertexCoords {
            set x [expr $m_centerX + $lx]
            set y [expr $m_centerY + $ly]
            lappend m_hotSpotCoords $x $y
        }
        updateBorder
    }
    redrawHotSpots $fromGUI
}
body GridItemNetBase::drawAllVertices { } {
    set coords $m_hotSpotCoords
    set index -1
    foreach {x y} $coords {
        incr index
        drawVertex $index $x $y
    }
}
body GridItemNetBase::vertexMotion { x y } {
    #puts "L614 hotSpotMotion $x $y"
    set index [expr $m_indexVertex * 2]

    set m_hotSpotCoords \
    [lreplace $m_hotSpotCoords $index [expr $index + 1] $x $y]

    #puts "hotSpot changed to $m_hotSpotCoords"

    ### try to only update affected local Coords
    regenerateLocalCoords $m_indexVertex

    updateBorder
    redrawHotSpots 1
}
body GridItemNetBase::regenerateLocalCoords { idxHotSpot } {
    set coords $m_hotSpotCoords
    set newLocal ""
    foreach {x y} $coords {
        set lx [expr $x - $m_centerX]
        set ly [expr $y - $m_centerY]
        lappend newLocal $lx $ly
    }
    set endIdx [expr 2 * $m_numAnchorPoint - 1]
    set saveLocal [lrange $m_localCoords [expr $endIdx + 1] end]
    set m_localCoords $newLocal
    eval lappend m_localCoords $saveLocal

    set sectionAffected [lindex $m_hotSpot2SectionMap $idxHotSpot]
    puts "for hotspot $idxHotSpot got affected list $sectionAffected"
    foreach idxSection $sectionAffected {
        set info [lindex $m_sectionList $idxSection]
        puts "for section $idxSection info=$info"
        foreach {hIdx0 hIdx1 hIdx2 hIdx3 nRow0 nRow1 nCol0 nCol1} $info break
        set hIdx0 [expr $hIdx0 * 2]
        set hIdx1 [expr $hIdx1 * 2]
        set hIdx2 [expr $hIdx2 * 2]
        set hIdx3 [expr $hIdx3 * 2]

        set hot0 [lrange $newLocal $hIdx0 [expr $hIdx0 + 1]]
        set hot1 [lrange $newLocal $hIdx1 [expr $hIdx1 + 1]]
        set hot2 [lrange $newLocal $hIdx2 [expr $hIdx2 + 1]]
        set hot3 [lrange $newLocal $hIdx3 [expr $hIdx3 + 1]]

        #### the setup need points: 0, 1, 3, 2.
        set uvxyList [list \
        $nCol0 $nRow0 \
        $nCol1 $nRow0 \
        $nCol1 $nRow1 \
        $nCol0 $nRow1 \
        ]
        eval lappend uvxyList $hot0 $hot1 $hot3 $hot2
        gGridBilinearCalculator quickSetup $uvxyList
        set startIdx [expr 2 * ($m_numAnchorPoint + $m_numBorderPoint)]
        for {set nRow $nRow0} {$nRow <= $nRow1} {incr nRow} {
            for {set nCol $nCol0} {$nCol <= $nCol1} {incr nCol} {
                set uvList [list $nCol $nRow]
                set xyList [gGridBilinearCalculator quickMap $uvList]
                foreach {x y} $xyList break
                set idxNd [expr 2 * ($nRow * $m_numCol + $nCol) + $startIdx]
                lset m_localCoords $idxNd $x
                incr idxNd
                lset m_localCoords $idxNd $y
            }
        }
    }

}
body GridItemNetBase::drawPotentialPosition2 { } {
    foreach {px py} [samplePositionToXy $m_point0] break
    $m_canvas delete ruler_$m_guiId

    foreach {dx100 dy100 cell_horz cell_vert} \
    [$m_holder micron2pixel 100 100 $m_oCellWidth $m_oCellHeight] break

    ## point 1, already clicked.
    set lb1 [getNodeLabel 0 0]
    set y $py
    set x $px
    $m_canvas create text $x $y \
    -text $lb1 \
    -font "-family courier -size 16" \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -anchor n \
    -tags [list ruler_$m_guiId rubberband item_$m_guiId]

    #set y [expr $py - $dy100]
    set y $py 
    set colList $m_allowedNumColList
    if {[lindex $m_allowedNumColList end] < $m_numCol} {
        lappend colList $m_numCol
    }
    foreach allowedNumCol $colList {
        set uFromP0 [expr $m_oCellWidth * [expr $allowedNumCol - 1]]
        foreach {pixelFromP0 -} [$m_holder micron2pixel $uFromP0 0] break
        set x [expr $px + $pixelFromP0]
        set label [getNodeLabel 0 [expr $allowedNumCol - 1]]

        $m_canvas create text $x $y \
        -text $label \
        -font "-family courier -size 16" \
        -fill $GridGroupColor::COLOR_RUBBERBAND \
        -anchor n \
        -tags [list ruler_$m_guiId rubberband item_$m_guiId]
    }
}
body GridItemNetBase::drawPotentialPosition3 { } {
    $m_canvas delete ruler_$m_guiId

    foreach {px py} [samplePositionToXy $m_point1] break
    foreach {dx100 dy100 cell_horz cell_vert} \
    [$m_holder micron2pixel 100 100 $m_oCellWidth $m_oCellHeight] break

    set idxCol [expr $m_numCol - 1]
    set x $px 
    foreach allowedNumRow $m_allowedNumRowList {
        set idxRow [expr $allowedNumRow - 1]
        set vFromP1 [expr $m_oCellHeight * $idxRow]
        foreach {- pixelFromP1} [$m_holder micron2pixel 0 $vFromP1] break
        set y [expr $py - $pixelFromP1]
        set label [getNodeLabel $idxRow $idxCol]

        $m_canvas create text $x $y \
        -text $label \
        -font "-family courier -size 16" \
        -fill $GridGroupColor::COLOR_RUBBERBAND \
        -anchor s \
        -tags [list ruler_$m_guiId rubberband item_$m_guiId]
    }
}
body GridItemNetBase::drawPotentialPosition4 { } {
    $m_canvas delete ruler_$m_guiId

    ### we will just derive it from P0, P1, and P2
    foreach {px0 py0} [samplePositionToXy $m_point0] break
    foreach {px1 py1} [samplePositionToXy $m_point1] break
    foreach {px2 py2} [samplePositionToXy $m_point2] break

    set dx [expr $px2 - $px1]
    set dy [expr $py2 - $py1]

    set px3 [expr $px0 + $dx]
    set py3 [expr $py0 + $dy]

    foreach {dx100 dy100 cell_horz cell_vert} \
    [$m_holder micron2pixel 100 100 $m_oCellWidth $m_oCellHeight] break

    set x $px3
    set y $py3
    set label [getNodeLabel [expr $m_numRow - 1] 0]
    $m_canvas create text $x $y \
    -text $label \
    -font "-family courier -size 16" \
    -fill $GridGroupColor::COLOR_RUBBERBAND \
    -anchor s \
    -tags [list ruler_$m_guiId rubberband item_$m_guiId]
}
body GridItemNetBase::updateBorder { } {
    set drawCoords ""
    set startIdx [expr 2 * $m_numAnchorPoint]
    set endIdx   [expr $startIdx + 2 * $m_numBorderPoint - 1]
    set bodyCoords [lrange $m_localCoords $startIdx $endIdx]
    foreach {lx ly} $bodyCoords {
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]
        lappend drawCoords $x $y
    }
    $m_canvas coords $m_guiId $drawCoords
    foreach {x1 y1 x2 y2} [$m_canvas bbox $m_guiId] break
    set m_itemWidth   [expr ($x2 - $x1) * 1.0]
    set m_itemHeight  [expr ($y2 - $y1) * 1.0]

    saveItemSize
}
body GridItemNetBase::generateGridMatrix { } {
    #puts "generateGridMatrix for $this"
    ##set m_nodeList ""
    $m_canvas delete grid_$m_guiId

    set m_gridCenterX $m_centerX
    set m_gridCenterY $m_centerY

    set numHole [expr $m_numCol * $m_numRow]
    if {[llength $m_nodeList] != $numHole} {
        set m_nodeList [string repeat "S " $numHole]
    }
    contourSetup

    $m_canvas delete grid_$m_guiId
    set radiusList ""
    set currentOrig [$m_holder getDisplayOrig]
    set r 10.0
    foreach {ux uy} \
    [translateProjectionBox $r $r $m_oOrig $currentOrig] break
    foreach {xr yr} [$m_holder micron2pixel $ux $uy] break

    set startIdx [expr 2 * ($m_numAnchorPoint + $m_numBorderPoint)]
    set holePositionList [lrange $m_localCoords $startIdx end]
    set index -1
    foreach {lx ly} $holePositionList {
        incr index
        set row [expr $index / $m_numCol]
        set col [expr $index % $m_numCol]

        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]

        set x1 [expr $x - $xr]
        set y1 [expr $y - $yr]
        set x2 [expr $x + $xr]
        set y2 [expr $y + $yr]

        $m_canvas create rectangle $x1 $y1 $x2 $y2 \
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
    $m_canvas raise hotspot_$m_guiId
}
body GridItemNetBase::rebornGridMatrix { } {
    contourSetup
    redrawGridMatrix
}

body GridItemNetBase::redrawGridMatrix { } {
    if {$m_displayControl == ""} {
        set fieldName Frame
    } else {
        set fieldName [$m_displayControl getNumberField]
    }

    set nodeColorList [getContourDisplayList]

    if {$nodeColorList == [generateEmptyDisplayList]} {
        $m_obj setValues ""
    } else {
        $m_obj setValues $nodeColorList
    }

    set nodeLabelList [getNumberDisplayList]
    set font_sizeW [expr int(abs(0.4 * $m_cellWidth))]
    set font_sizeH [expr int(abs(0.4 * $m_cellHeight))]
    set font_size [expr ($font_sizeW > $font_sizeH)?$font_sizeH:$font_sizeW]
    if {$font_size > 16} {
        set font_size 16
    }

    $m_canvas delete grid_$m_guiId

    set currentOrig [$m_holder getDisplayOrig]
    set radiusList ""
    set r 10
    foreach {ux uy} \
    [translateProjectionBox $r $r $m_oOrig $currentOrig] break
    foreach {xr yr} [$m_holder micron2pixel $ux $uy] break

    set startIdx [expr 2 * ($m_numAnchorPoint + $m_numBorderPoint)]
    set holePositionList [lrange $m_localCoords $startIdx end]
    set index -1
    foreach {lx ly} $holePositionList {
        incr index
        set x [expr $m_centerX + $lx]
        set y [expr $m_centerY + $ly]

        set row [expr $index / $m_numCol]
        set col [expr $index % $m_numCol]

        set holeLabel [lindex $m_nodeLabelList $index]

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
                set c_row [expr $index / $m_numCol]
                set c_col [expr $index % $m_numCol]
                set color      [$m_obj getColor $c_row $c_col]
                if {$color >= 0} {
                    set fill [format "\#%02x%02x%02x" $color $color $color]
                 }
            }
        }

        set hid [$m_canvas create rectangle $x1 $y1 $x2 $y2 \
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

        #puts "draw label index=$index label=$holeLabel"

        if {$fieldName != "Frame"} {
            continue
        }

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
    $m_canvas raise hotspot_$m_guiId
}
body GridItemNetBase::setNode { index status } {
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

    set noFill 0
    if {[string first only [getContourLevels]] >= 0} {
        set noFill 1
    }
    
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
            set c_row [expr $index / $m_numCol]
            set c_col [expr $index % $m_numCol]
            set color      [$m_obj getColor $c_row $c_col]
            if {$color >= 0} {
                set fill [format "\#%02x%02x%02x" $color $color $color]
             }
        }
    }
    if {$noFill} {
        set fill ""
    }
    $m_canvas itemconfigure $nodeTag \
    -outline $outline \
    -fill $fill
}

GridAdxvView gGridAdxvView
#ProjectiveMapping gGridProjectiveCalculator
BilinearMapping   gGridBilinearCalculator
