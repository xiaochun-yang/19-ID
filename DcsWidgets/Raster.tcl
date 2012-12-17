package provide DCSRaster 1.0

package require DCSRasterBase

class DCS::Raster4DCSS {
	inherit ::DCS::RasterBase

    private variable m_beamCenterX -1.0
    private variable m_beamCenterY -1.0

    private variable m_defaultUserSetupNormal ""
    private variable m_defaultUserSetupMicro ""

    public common PROC_RANGE_CHECK ""

    public method load { rasterNum path {silent 0} } {
        puts "raster load $rasterNum $path $silent"
        set m_rasterNum $rasterNum
        set m_rasterPath $path

        readback $silent
    }

    public method initialize { path info \
    dfUserSetupNormal dfUserSetupMicro }

    ## initialize also set initial beam center.
    public method setBeamCenter { x y {forced_update 0}}
    public method defineArea { view_index x0 y0 x1 y1 }
    public method moveArea   { view_index direction }
    public method setBothUserSetup { normal micro }
    public method flip_node { view row column }
    public method flip_view { view }
    public method flip_singleViewMode { }
    public method setNodeState { view index state }
    public method setViewState { view state }
    public method setUserSetup { user_setup }
    public method setUserSetupField { name value }
    public method restoreSelection { view_index }
    public method clearResults { {forNewRaster 0} }
    ### this one will replace 'X', 'D' with 'S'
    public method clearIntermediaResults { }
    public method updatePattern { view_index pattern ext threshold }

    ### these read functions are only used by dcss
    public method getSnapshots { }
    public method getSnapshotCoordinates { view }
    public method getNodePosition { view index }
    public method getNextNode { view_index current_node }
    public method getMatrixLog { view_index numFmt txtFmt }

    #### for auto background detection
    public method automask { view args }

    private method write
    private method create2DSetup { {init_info_too 1} }
    private method offsetsToOrig { }

    private method clearCurrentExposureTimeAndEnergy { } {
        set m_userSetupNormal [lreplace $m_userSetupNormal 4 5 {} {}]
        set m_userSetupMicro  [lreplace $m_userSetupMicro  4 5 {} {}]
        set m_userSetupNormal \
        [setStringFieldWithPadding $m_userSetupNormal 9 {}]

        set m_userSetupMicro \
        [setStringFieldWithPadding $m_userSetupMicro 9 {}]
    }

    constructor { } {
    }
}
body DCS::Raster4DCSS::defineArea { view_index sx0 sy0 sx1 sy1 } {
    set inline   [lindex $m_3DInfo 14]

    set sx [expr ($sx0 + $sx1) / 2.0]
    set sy [expr ($sy0 + $sy1) / 2.0]
    set sdx [expr abs($sx1 - $sx0)]
    set sdy [expr abs($sy1 - $sy0)]
    ### sdx sdy cannot be zero.  We need widthU and heightU to pass in the sign
    if {$sdx == 0} {
        set sdx 0.00000000001
    }
    if {$sdy == 0} {
        set sdy 0.00000000001
    }

    send_operation_update snapshot area: $view_index $sx0 $sy0 $sx1 $sy1
    send_operation_update snapshot area: x=$sx y=$sy dx=$sdx dy=$sdy

    switch -exact -- $view_index {
        0 {
            set snap       [lindex $m_3DInfo 2]
            set other_snap [lindex $m_3DInfo 3]
        }
        1 {
            set snap       [lindex $m_3DInfo 3]
            set other_snap [lindex $m_3DInfo 2]
        }
        default {
            log_error wrong view_index for snapshot
            return
        }
    }
    set sorig [lindex $snap 1]
    set other_orig [lindex $other_snap 1]
    foreach {- - - - imgH imgW} $sorig break

    set widthU  [expr $sdx * $imgW * 1000.0]
    set heightU [expr $sdy * $imgH * 1000.0]

    switch -exact -- $view_index {
        0 {
            set m_3DInfo [lreplace $m_3DInfo 5 6 $widthU $heightU]
            set m_3DInfo [lreplace $m_3DInfo 12 12 1]
            set m_3DInfo [lreplace $m_3DInfo 19 20 $sx $sy]
            set other_sx [translateHorzProjection $sx $sorig $other_orig]
            set m_3DInfo [lreplace $m_3DInfo 21 21 $other_sx]
            if {![getViewDefined 1]} {
                ### we want the same size so that display looks better
                set m_3DInfo [lreplace $m_3DInfo 7 7 $heightU]
            }
        }
        1 {
            set m_3DInfo [lreplace $m_3DInfo 5 5 $widthU]
            set m_3DInfo [lreplace $m_3DInfo 7 7 $heightU]
            set m_3DInfo [lreplace $m_3DInfo 13 13 1]
            set m_3DInfo [lreplace $m_3DInfo 21 22 $sx $sy]
            set other_sx [translateHorzProjection $sx $sorig $other_orig]
            set m_3DInfo [lreplace $m_3DInfo 19 19 $other_sx]
            if {![getViewDefined 0]} {
                ### we want the same size so that display looks better
                set m_3DInfo [lreplace $m_3DInfo 6 6 $heightU]
            }
        }
    }
    if {$PROC_RANGE_CHECK != ""} {
        set m_3DInfo [$PROC_RANGE_CHECK $m_3DInfo]
    }
    create2DSetup
}
body DCS::Raster4DCSS::moveArea { view_index direction } {
    switch -exact -- $view_index {
        0 {
            set snap       [lindex $m_3DInfo 2]
            set other_snap [lindex $m_3DInfo 3]
            set w          [lindex $m_3DInfo 5]
            set h          [lindex $m_3DInfo 6]
            set nw         [lindex $m_3DInfo 8]
            set nh         [lindex $m_3DInfo 9]

            set cx         [lindex $m_3DInfo 19]
            set cy         [lindex $m_3DInfo 20]
        }
        1 {
            set snap       [lindex $m_3DInfo 3]
            set other_snap [lindex $m_3DInfo 2]
            set w          [lindex $m_3DInfo 5]
            set h          [lindex $m_3DInfo 7]
            set nw         [lindex $m_3DInfo 8]
            set nh         [lindex $m_3DInfo 10]

            set cx         [lindex $m_3DInfo 21]
            set cy         [lindex $m_3DInfo 22]
        }
        default {
            log_error wrong view_index for snapshot
            return
        }
    }

    if {$w == 0 || $h == 0 || $nw == 0 || $nh == 0} {
        log_error cannot move undefined area
        return -code error CANNOT_MOVE
    }

    set sorig [lindex $snap 1]
    set other_orig [lindex $other_snap 1]

    #### need in mm, not micron
    set stepW [expr abs(0.00025 * $w / $nw)]
    set stepH [expr abs(0.00025 * $h / $nh)]
    foreach {screenStepW screenStepH} \
    [calculateProjectionBoxFromBox $sorig $stepW $stepH] break

    puts "move $view_index $direction"
    switch -exact -- $direction {
        up {
            set cy [expr $cy - $screenStepH]
        }
        down {
            set cy [expr $cy + $screenStepH]
        }
        left {
            set cx [expr $cx - $screenStepW]
        }
        right {
            set cx [expr $cx + $screenStepW]
        }
        default {
            log_error wrong direction: $direction
            return
        }
    }
    set other_cx [translateHorzProjection $cx $sorig $other_orig]
    switch -exact -- $view_index {
        0 {
            set m_3DInfo [lreplace $m_3DInfo 19 20 $cx $cy]
            set m_3DInfo [lreplace $m_3DInfo 21 21 $other_cx]
        }
        1 {
            set m_3DInfo [lreplace $m_3DInfo 21 22 $cx $cy]
            set m_3DInfo [lreplace $m_3DInfo 19 19 $other_cx]
        }
    }
    create2DSetup
}
body DCS::Raster4DCSS::setBothUserSetup { normal micro } {
    #### field single_view is a reflect of m_3DInfo
    set index [lsearch -exact $USER_SETUP_NAME_LIST single_view]
    if {$index < 0} {
        log_error bad name single_view for raster user setup
        return -code error bad_name
    }

    set curSVM [isSingleView]
    
    if {$normal != ""} {
        set m_userSetupNormal [setStringFieldWithPadding $normal $index $curSVM]
    }
    if {$micro != ""} {
        set m_userSetupMicro  [setStringFieldWithPadding $micro $index $curSVM]
    }
    write
    send_operation_update USER_NORMAL $m_rasterNum $m_userSetupNormal
    send_operation_update USER_MICRO  $m_rasterNum $m_userSetupMicro
}
body DCS::Raster4DCSS::setBeamCenter { x y {forced_update 0} } {
    if {abs($m_beamCenterX - $x) < 0.001 \
    && abs($m_beamCenterY - $y) < 0.001 \
    && !$forced_update} {
        return
    }
    set m_beamCenterX $x
    set m_beamCenterY $y

    ### now calculate orig from the offset
    create2DSetup 0
}
body DCS::Raster4DCSS::clearResults { {forNewRaster 0} } {
    set info ""
    foreach e $m_info0 {
        set e [string index $e 0]
        if {$e != "N"} {
            set e S
        }
        lappend info $e
    }
    if {$forNewRaster} {
        set rasterStatus new
    } else {
        set rasterStatus init
    }

    set m_info0 [lreplace $info 0 0 $rasterStatus]

    set info ""
    foreach e $m_info1 {
        set e [string index $e 0]
        if {$e != "N"} {
            set e S
        }
        lappend info $e
    }
    set m_info1 [lreplace $info 0 0 $rasterStatus]

    clearCurrentExposureTimeAndEnergy

    write
    send_operation_update VIEW_DATA0  $m_rasterNum $m_info0
    send_operation_update VIEW_DATA1  $m_rasterNum $m_info1
    send_operation_update USER_NORMAL $m_rasterNum $m_userSetupNormal
    send_operation_update USER_MICRO  $m_rasterNum $m_userSetupMicro
}
body DCS::Raster4DCSS::clearIntermediaResults { } {
    set info ""
    foreach e $m_info0 {
        set fc [string index $e 0]
        if {$fc == "N"} {
            set e N
        } elseif {[string length $e] == 1} {
            set e S
        }
        lappend info $e
    }
    set m_info0 [lreplace $info 0 0 init]

    set info ""
    foreach e $m_info1 {
        set fc [string index $e 0]
        if {$fc == "N"} {
            set e N
        } elseif {[string length $e] == 1} {
            set e S
        }
        lappend info $e
    }
    set m_info1 [lreplace $info 0 0 init]

    write
    send_operation_update VIEW_DATA0  $m_rasterNum $m_info0
    send_operation_update VIEW_DATA1  $m_rasterNum $m_info1
}
body DCS::Raster4DCSS::restoreSelection { view_index } {
    set info [set m_info$view_index]

    set result init
    set info [lrange $info 1 end]

    foreach e $info {
        set e [string index $e 0]
        if {$e != "N"} {
            set e S
        } else {
            set e N
        }
        lappend result $e
    }

    set m_info$view_index $result

    write
    send_operation_update VIEW_DATA$view_index  $m_rasterNum [set m_info$view_index]
}
body DCS::Raster4DCSS::getSnapshotCoordinates { view } {
    if {$view < 0 || $view > 1} {
        log_error bad view_index $view should be 0 or 1
        return -code BAD_VIEW_INDEX
    }

    set offset [expr $view + 2]
    set snap [lindex $m_3DInfo $offset]
    set coord [lindex $snap 1]
    return $coord
}
body DCS::Raster4DCSS::getSnapshots { } {
    foreach {- - s0 s1} $m_3DInfo break
    set snap0 [lindex $s0 0]
    set snap1 [lindex $s1 0]

    return [list $snap0 $snap1]
}
body DCS::Raster4DCSS::flip_node { view_index row col } {
    set setup [set m_setup$view_index]
    set info  [set m_info$view_index]

    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $setup break

    set index [expr $row * $numColumn + $col]
    set offset [expr $index + 1]

    set rasterStatus [lindex $info 0]
    set current [lindex $info $offset]
    send_operation_update DEBUG \
    flip_node row=$row col=$col index=$index curr=$current

    set current [string index $current 0]
    switch -exact -- $current {
        N {
            set new S
        }
        default {
            set new NEW
        }
    }

    set needWholeData 0
    ### user wants to undo automask
    if {$new == "S" && $rasterStatus == "mask_${row}_${col}"} {
        set ll [expr $numRow * $numColumn]
        set needWholeData 1
        set info [string map {NEW S} $info]
        set m_info$view_index [lreplace $info 0 0 init]
    } else {
        if {$rasterStatus == "new" \
        || [string equal -length 4 $rasterStatus "mask"]} {
            set info [lreplace $info 0 0 init]
            set needWholeData 1
        }
        set oldInfo $info
        set info [string map {NEW N} $info]
        if {$oldInfo != $info} {
            set needWholeData 1
        }
        set m_info$view_index [lreplace $info $offset $offset $new]
    }

    #### check if need to change the user setup field skipXXX
    set skipShouldValue 1
    set newInfo  [set m_info$view_index]
    foreach n [lrange $newInfo 1 end] {
        set n [string index $n 0]
        if {$n != "N"} {
            set skipShouldValue 0
            break
        }
    }
    set curSkip [getUserSetupField skip$view_index]
    if {$curSkip != $skipShouldValue} {
        setUserSetupField skip$view_index $skipShouldValue
    } else {
        write
    }
    if {!$needWholeData} {
        send_operation_update VIEW_NODE$view_index $m_rasterNum $index $new
    } else {
        send_operation_update \
        VIEW_DATA$view_index $m_rasterNum [set m_info$view_index]
    }
}
body DCS::Raster4DCSS::setNodeState { view_index index state } {
    set info  [set m_info$view_index]

    #### the first element in info is raster_state
    set offset [expr $index + 1]

    set current [lindex $info $offset]
    send_operation_update DEBUG setNodeState view=$view_index index=$index curr=$current new=$state

    set m_info$view_index [lreplace $info $offset $offset $state]

    write
    send_operation_update VIEW_NODE$view_index $m_rasterNum $index $state
}
body DCS::Raster4DCSS::setViewState { view_index state } {
    set info  [set m_info$view_index]

    set current [lindex $info 0]
    send_operation_update DEBUG setViewState view=$view_index curr=$current new=$state

    set info [string map {NEW N} $info]
    set m_info$view_index [lreplace $info 0 0 $state]

    write
    send_operation_update VIEW_DATA$view_index $m_rasterNum [set m_info$view_index]
}
body DCS::Raster4DCSS::write { } {
    if {$m_rasterHandle != ""} {
        close $m_rasterHandle
        set m_rasterHandle ""
    }
    if {![catch {open $m_rasterPath w} m_rasterHandle]} {
        puts $m_rasterHandle $TAG
        puts $m_rasterHandle $m_3DInfo
        puts $m_rasterHandle $m_setup0
        puts $m_rasterHandle $m_setup1
        puts $m_rasterHandle $m_info0
        puts $m_rasterHandle $m_info1
        puts $m_rasterHandle $m_userSetupNormal
        puts $m_rasterHandle $m_userSetupMicro
        close $m_rasterHandle
        set m_rasterHandle ""
    } else {
        log_error failed to write raster to $m_rasterPath: $m_rasterHandle
        set m_rasterHandle ""
        return -code error WRONG_RASTER
    }
}
body DCS::Raster4DCSS::initialize { path info \
dfUserSetupNormal dfUserSetupMicro } {

    set m_3DInfo $info
    set m_defaultUserSetupNormal $dfUserSetupNormal
    set m_defaultUserSetupMicro  $dfUserSetupMicro

    set m_beamCenterX [lindex $m_3DInfo 19]
    set m_beamCenterY [lindex $m_3DInfo 20]

    set m_isCollimator [lindex $m_3DInfo 4]
    set m_isInline [lindex $m_3DInfo 14]

    set m_rasterPath $path
    create2DSetup
}
body DCS::Raster4DCSS::create2DSetup { {init_info_too 1} } {
    foreach {- - snap0 snap1 - w h d nw nh nd} $m_3DInfo break
    set centerH0 [lindex $m_3DInfo 19]
    set centerV0 [lindex $m_3DInfo 20]
    set centerH1 [lindex $m_3DInfo 21]
    set centerV1 [lindex $m_3DInfo 22]
    ## here centerH0 should be the same as centerH1

    set orig0 [lindex $snap0 1]
    set orig1 [lindex $snap1 1]
    foreach {x0 y0 z0 a0} $orig0 break
    foreach {x1 y1 z1 a1} $orig1 break
    ### here x0, y0, z0 should be the same as x1, y1, z1

    ### the logical: When sample_xyz is at orig0/orig1, the beam center is
    ### at (m_beamCenterX m_beamCenterY).
    ### To move the beam to the center of defined area, you will need to adjust.
    set dH0 [expr $centerH0 - $m_beamCenterX]
    set dV0 [expr $centerV0 - $m_beamCenterY]
    set dH1 [expr $centerH1 - $m_beamCenterX]
    set dV1 [expr $centerV1 - $m_beamCenterY]
    ### dH0 == dH1

    foreach {dx0 dy0 dz0} [calculateSamplePositionDeltaFromDeltaProjection \
    $orig0 $dV0 $dH0 ] break
    foreach {dx1 dy1 dz1} [calculateSamplePositionDeltaFromDeltaProjection \
    $orig1 $dV1 $dH1 ] break

    set newX0 [expr $x0 + $dx0 + $dx1]
    set newY0 [expr $y0 + $dy0 + $dy1]
    set newZ0 [expr $z0 + $dz0]

    set newX1 [expr $x1 + $dx0 + $dx1]
    set newY1 [expr $y1 + $dy0 + $dy1]
    set newZ1 [expr $z1 + $dz1]

    set newOrig0 [lreplace $orig0 0 2 $newX0 $newY0 $newZ0]
    set newOrig1 [lreplace $orig1 0 2 $newX1 $newY1 $newZ1]

    ### convert to mm
    set w [expr $w / 1000.0]
    set h [expr $h / 1000.0]
    set d [expr $d / 1000.0]

    set stepSizeW [expr $w / $nw]
    set stepSizeH [expr $h / $nh]
    set stepSizeD [expr $d / $nd]

    ### number of nodes
    set lEdge [expr $nw * $nh]
    set lFace [expr $nw * $nd]
    
    set m_3DInfo [lreplace $m_3DInfo 1 1 $newOrig0]

    set m_setup0 [list \
    $newX0 $newY0 $newZ0 $a0 \
    $stepSizeH $stepSizeW $nh $nw \
    /tmp/not_exists \
    img 0 \
    ]

    set m_setup1 [list \
    $newX1 $newY1 $newZ1 $a1 \
    $stepSizeD $stepSizeW $nd $nw \
    /tmp/not_exists \
    img 0 \
    ]
    
    if {$init_info_too} {
        set m_info0 "new [string repeat {S } $lEdge]"
        set m_info1 "new [string repeat {S } $lFace]"
    }

    if {$m_userSetupNormal == ""} {
        set m_userSetupNormal $m_defaultUserSetupNormal
    }
    if {$m_userSetupMicro == ""} {
        set m_userSetupMicro $m_defaultUserSetupMicro
    }

    clearCurrentExposureTimeAndEnergy

    write

    send_operation_update SCAN_INFO   $m_rasterNum $m_3DInfo
    send_operation_update VIEW_SETUP0 $m_rasterNum $m_setup0
    send_operation_update VIEW_SETUP1 $m_rasterNum $m_setup1
    send_operation_update VIEW_DATA0  $m_rasterNum $m_info0
    send_operation_update VIEW_DATA1  $m_rasterNum $m_info1
    send_operation_update USER_NORMAL $m_rasterNum $m_userSetupNormal
    send_operation_update USER_MICRO  $m_rasterNum $m_userSetupMicro
}
body DCS::Raster4DCSS::getNodePosition { view_index index } {
    set setup [set m_setup$view_index]

    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $setup break

    set row_index [expr $index / $numColumn]
    set col_index [expr $index % $numColumn]

    set proj_v [expr $row_index - ($numRow    - 1) / 2.0]
    set proj_h [expr $col_index - ($numColumn - 1) / 2.0]

    ## It should always start from orig position.  This way will make sure
    ## the 90 degree view the position is at the same level with orig.
    foreach {dx dy dz} \
    [calculateSamplePositionDeltaFromProjection \
    $setup $orig_x $orig_y $orig_z $proj_v $proj_h] break

    set x [expr $orig_x + $dx]
    set y [expr $orig_y + $dy]
    set z [expr $orig_z + $dz]

    return [list $x $y $z $row_index $col_index]
}
body DCS::Raster4DCSS::setUserSetup { userSetup } {
    if {$m_isCollimator} {
        set m_userSetupMicro  $userSetup
        write
        send_operation_update USER_MICRO  $m_rasterNum $m_userSetupMicro
    } else {
        set m_userSetupNormal $userSetup
        write
        send_operation_update USER_NORMAL $m_rasterNum $m_userSetupNormal
    }
}
body DCS::Raster4DCSS::updatePattern { view_index pattern ext threshold } {
    puts "raster::udatePattern view=$view_index pat=$pattern ext=$ext th=$threshold"
    set old [set m_setup$view_index]

    set m_setup$view_index [lreplace $old 8 10 $pattern $ext $threshold]

    write
    send_operation_update VIEW_SETUP$view_index $m_rasterNum [set m_setup$view_index]
    send_operation_update VIEW_DATA$view_index  $m_rasterNum [set m_info$view_index]
}
body DCS::Raster4DCSS::getNextNode { view_index current } {
    set skip_view [getUserSetupField skip$view_index]
    if {$skip_view == "1"} {
        return -1
    }

    set listState [set m_info$view_index]

    ### skip first (raster state)
    set listState [lrange $listState 1 end]
    set ll [llength $listState]

    set next [expr $current + 1]
    if {$next < 0} {
        set next 0
    }
    if {$next >= $ll} {
        set next 0
    }
    for {set i $next} {$i < $ll} {incr i} {
        if {$i == $current} {
            continue
        }
        set s [lindex $listState $i]
        if {$s == "S"} {
            return $i
        }
    }
    for {set i 0} {$i < $next} {incr i} {
        if {$i == $current} {
            continue
        }
        set s [lindex $listState $i]
        if {$s == "S"} {
            return $i
        }
    }
    return -1
}
body DCS::Raster4DCSS::getMatrixLog { view_index numFmt txtFmt } {
    set setup [set m_setup$view_index]
    set info  [set m_info$view_index]

    foreach {- - - - - - numRow numColumn} $setup break

    set result [list]

    for {set row 0} {$row < $numRow} {incr row} {
        set line ""
        for {set col 0} {$col < $numColumn} {incr col} {
            set index [expr $row * $numColumn + $col + 1]
            set node [lindex $info $index]

            # in case
            set weight [lindex $node 0]

            if {[string is double -strict $weight]} {
                set nodeDisplay [format $numFmt $weight]
            } else {
                switch -exact -- $weight {
                    NEW -
                    N {
                        set nodeDisplay Skip
                    }
                    default {
                        set nodeDisplay N/A
                    }
                }
                set nodeDisplay [format $txtFmt $nodeDisplay]
            }
            append line $nodeDisplay
        }
        lappend result $line
    }
    return $result
}
body DCS::Raster4DCSS::flip_view { view_index } {
    set setup [set m_setup$view_index]
    foreach {- - - - - - numRow numColumn} $setup break
    set ll [expr $numRow * $numColumn]

    set curSkip [getUserSetupField skip$view_index]
    if {$curSkip} {
        set newSkip 0
        set m_info$view_index "init [string repeat {S } $ll]"
    } else {
        set newSkip 1
        set m_info$view_index "init [string repeat {N } $ll]"
    }

    setUserSetupField skip$view_index $newSkip
    ##write: already calle din setUserSetupField
    send_operation_update VIEW_DATA$view_index $m_rasterNum [set m_info$view_index]
}
body DCS::Raster4DCSS::setUserSetupField { name value } {
    set index [lsearch -exact $USER_SETUP_NAME_LIST $name]
    if {$index < 0} {
        log_error bad name $name for raster user setup
        return -code error bad_name
    }
    set curUserSetup [getUserSetup]
    set newUserSetup [setStringFieldWithPadding $curUserSetup $index $value]
    setUserSetup $newUserSetup
}
body DCS::Raster4DCSS::flip_singleViewMode { } {
    set index [lsearch -exact $USER_SETUP_NAME_LIST single_view]
    if {$index < 0} {
        log_error bad name single_view for raster user setup
        return -code error bad_name
    }

    set curSVM [isSingleView]
    set curUserSetup [getUserSetup]
    if {$curSVM} {
        set m_3DInfo [lreplace $m_3DInfo 12 13 1 1]
        set newUserSetup [setStringFieldWithPadding $curUserSetup $index 0]
    } else {
        set m_3DInfo [lreplace $m_3DInfo 12 13 1 0]
        set newUserSetup [setStringFieldWithPadding $curUserSetup $index 1]
    }
    setUserSetup $newUserSetup
    send_operation_update SCAN_INFO   $m_rasterNum $m_3DInfo
}
body DCS::Raster4DCSS::automask { view_index args } {
    set ll [llength $args]
    if {$ll % 2} {
        log_error wrong number of arguments for automask
        return -code error BAD_ARGS
    }

    set setup [set m_setup$view_index]
    set info  [set m_info$view_index]

    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $setup break

    set first_row [lindex $args 0]
    set first_col [lindex $args 1]

    ### special tag so we can undo by one click
    set info [lreplace $info 0 0 mask_${first_row}_${first_col}]
    set info [string map {NEW N} $info]
    foreach {row col} $args {
        set offset [expr $row * $numColumn + $col + 1]
        set cur  [lindex $info $offset]
        if {$cur == "S"} {
            set info [lreplace $info $offset $offset NEW]
        }
    }


    #### check if need to change the user setup field skipXXX
    set skipShouldValue 1
    foreach n [lrange $info 1 end] {
        set n [string index $n 0]
        if {$n != "N"} {
            set skipShouldValue 0
            break
        }
    }
    set curSkip [getUserSetupField skip$view_index]

    set m_info$view_index $info
    if {$curSkip != $skipShouldValue} {
        setUserSetupField skip$view_index $skipShouldValue
    } else {
        write
    }
    send_operation_update \
    VIEW_DATA$view_index $m_rasterNum [set m_info$view_index]
}
