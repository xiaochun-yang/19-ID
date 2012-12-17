package provide DCSGridGroupBase 1.0

package require Itcl
package require DCSPersistent
package require DCSComponent
namespace import ::itcl::*

####################################################
# This is for rastering V3.
####################################################
# top class GridGroup
# GridGroup has grids, snapshot.
#   each grid has one default snapshot, on which it changed geo properties.
#
#   snapshot can be shared between grids.
#
#   There may be more than one snapshots with the same phi angle.
#   They may have different zoom or sample position.
#
#   Snapshot list is sorted and {unique maybe} for phi.
#   It will have the latest accessed snapshot if there are more than one for
#   for that phi.

#################################################################
# list structure of basic elements:
# ORIG: orig_x orig_y orig_z orig_angle cell_vert cell_horz num_row num_column 
#       zoom_center_vert zooom_center_horz camera
############
#       orig_angle=phi+omega to face the beam
#       cell_vert and cell_horz are for scaling from mm to row and column
#
#       For GridGroup, the cell_vert and cell_horz are the snapshot image
#       size in mm. Default num_row and num_column are "1".
#

#######################################################
# In grid, the coords are microns from the upper left corner of the image.
#
# To speed up rotation and keep the accuracy, we defined local coords,
# which is at the center of the shape.
class GridGroup::Item {
    inherit DCSPersistentBase

    public method getId { } { return $m_id }
    public method getLabel { } { return $m_label }
    public method getSortNum { } { return $m_sortNum }

    protected variable m_id     -1
    protected variable m_label  "not_defined"
    protected variable m_sortNum 0

    constructor { } {
    }
}
### this is for grid, it has its own file for persistent.
class GridGroup::SelfItem {
    inherit DCSSelfPersistent

    public method getId { } { return $m_id }
    public method getLabel { } { return $m_label }
    public method getSortNum { } { return $m_sortNum }

    protected variable m_id     -1
    protected variable m_label  "not_defined"
    protected variable m_sortNum 0

    constructor { } {
    }
}

#not used yet
class GridGroup::Peak {
    inherit GridGroup::Item

    public method setGridId { id } {
        set _gridId $id
    }

    protected variable m_height 0
    protected variable m_cut 0
    ### geo: units: column, row.
    protected variable m_ridge_start {0 0}
    protected variable m_ridge_end {0 0}
    protected variable _gridId ""
    protected variable m_borderCoords ""

    ### for vector
    protected variable m_positionStart {0 0 0}
    protected variable m_positionEnd {0 0 0}
    protected variable m_angle 0
}

class GridGroup::GridBase {
    inherit GridGroup::SelfItem

    ### hook
    protected method afterInitializeFromHuddle { } {
        #puts "calling afterInit for GridBase: $this"
        updateNumbers
        generateSequenceMap
        generateUserSetupDict
    }

    ### for events and attributes
    public method getGeoProperties { } {
        loadIfNeed
        return [list $m_imageOrig $d_geo $d_matrix $l_nodeList \
        $_index2sequence $m_status]
    }
    public method getSetupProperties { }
    public method getNodeListInfo { }
    public method getBeamSizeInfo { }
    public method getStatus { } {
        loadIfNeed
        return $m_status
    }
    public method getEditable { } {
        if {[getStatus] == "setup"} {
            return 1
        } else {
            return 0
        }
    }
    public method getCamera { }
    public method getShape { }
    public method getDeletable { } { return [getEditable] }
    public method getResettable { } {
        if {[getStatus] == "setup"} {
            return 0
        } else {
            return 1
        }
    }
    public method getRunnable { } {
        set status [getStatus]
        switch -exact -- $status {
            complete -
            disabled {
                return 0
            }
            setup -
            ready -
            paused -
            default {
                return 1
            }
        }
    }
    public method getTotalNumberImage { } {
        loadIfNeed
        return [expr $_numImageNeed + $_numImageDone]
    }
    public method getNumImageDone { } {
        loadIfNeed
        return $_numImageDone
    }
    public method getNumImageNeed { } {
        loadIfNeed
        return $_numImageNeed
    }
    public method getNodeStatus { index } {
        loadIfNeed
        return [lindex $l_nodeList $index]
    }
    public method getNodeList { } {
        loadIfNeed
        return $l_nodeList
    }
    public method getDefaultSnapshotId { } {
        loadIfNeed
        return $m_defaultSnapshotId
    }

    ### this one will not trigger need to write.
    public method setBeamCenter { x y }

    public method setGeo { snapshotId orig geo matrix nodes {update 1}}
    public method setParameter { param }
    public method setSnapshotId { snapshotId }
    public method initialize { id label sortNum \
        snapshotId orig geo matrix nodes param \
    }

    public method setStatus { status } {
        loadIfNeed
        if {$m_status == $status} {
            return 0
        }
        set m_status $status
        generateUserSetupDict
        set _needWrite 1
        return 1
    }
    public method setNodeStatus { index status }
    public method setAllNodes { nList }
    ### need this to manipulate node list from outside,
    ### used for L614 to load hole list.
    public method getAllNodesAndInfo { }
    public method reset { }
    public method clearIntermediaResults { }
    #### this one will not clear the nodes with results.

    ### too complicated to use setNodeStatus
    public method flipNode { index }

    public method getNodeIndex { row column }

    #### following, argument is sequence number
    public method getNextNode { current_node }
    public method getNodePosition { seq }
    public method sequence2index { seq }

    public method getCenterPosition { } {
        loadIfNeed
        return $_orig
    }
    ### the positions are affected by beam centers.
    public method getMovePosition { x y }

    ### remove these and the code in collectGrid after
    ### energy is included in user input.
    public method setEnergyUsed { e }
    public method getEnergyUsed { } {
        loadIfNeed
        return $m_energyUsed
    }

    ### for Grid non-graphic input
    public method getUserInput { } {
        loadIfNeed
        if {$_d_userSetup == ""} {
            puts "usersetup == empty for $this"
            generateUserSetupDict
        }
        return $_d_userSetup
    }
    public method setUserInput { setup }

    ### should be called during setting exposure time
    public method setDetectorModeAndFileExt { mode ext } {
        loadIfNeed
        dict set d_parameter mode $mode
        dict set d_parameter ext  $ext
        set _needWrite 1
    }

    public method getMatrixLog { numFmt txtFmt }

    public method newOrigIsBetter { newOrig }

    ## must be subset of _USERSETUP_NAMELIST 
    public proc getParameterFieldNameList { } {
        return [list \
        prefix \
        directory \
        collimator \
        beam_width \
        beam_height \
        time \
        delta \
        distance \
        attenuation \
        processing \
        ]
    }

    ### private method no need to call loadIfNeed
    private method calculateGridOrig { }
    private method checkNode { }
    private method updateNumbers { }
    private method generateSequenceMap { }
    private method generateUserSetupDict { }

    private method loadIfNeed { } {
        if {!$_allLoaded} {
            reload 1
        }
    }

    #### geo:
    #### a dict (like struct in C/C++)
    ####    shape, center, angle, half_width, half_height, and local_coords.
    ####
    #### matrix:
    ####    type, center, cell_width, cell_height, num_row, num_column,
    ####    node_label_list(optional)
    ####
    ####        type: horz or vert
    ####            horz: left to right and top down.
    ####            vert: top down then right to left.
    ####
    #### parameter:
    ####    prefix
    ####    directory
    ####    beam size
    ####    distance
    ####    beam_stop
    ####    exposure time
    ####    delta
    #### following 2 are derived from exposure time by caller
    ####    detector_mode
    ####    file_extension
    ####
    ####
    ####
    ####
    protected variable m_imageOrig ""
    protected variable m_defaultSnapshotId -1
    protected variable d_geo ""
    protected variable d_matrix ""
    protected variable d_parameter ""

    ########### for grid run
    protected variable m_status "setup"

    protected variable m_energyUsed 0.0

    protected variable l_nodeList ""

    ## orig is derived from snapshot orig ,d_matrix and beam center position.
    protected variable _orig ""
    protected variable _beamCenterX 0.5
    protected variable _beamCenterY 0.5

    protected variable _numImageNeed 0
    protected variable _numImageDone 0

    ### sequence to node index
    protected variable _sequence2index [list]
    protected variable _index2sequence [list]

    ### user setup dictionany: generated from d_geo, d_matrix, and d_parameter
    protected variable _d_userSetup ""

    protected common _USERSETUP_NAMELIST \
    [::config getStr "rastering.userSetupNameList"]

    constructor { } {
        ### we will take care of it.
        set _clearNeedAfterWrite    1

        ### you have to put m_id and m_label here.
        ### otherwise, you need to overwide the method accessing them.
        ### which is in base class.
        set _alwaysAvailableVariableList [list m_id m_label m_sortNum]
    }
}
body GridGroup::GridBase::getShape { } {
    loadIfNeed
    return [dict get $d_geo shape]
}
body GridGroup::GridBase::getCamera { } {
    loadIfNeed
    set camera [lindex $m_imageOrig 10]
    if {$camera == ""} {
        puts "grid getCamera got empty, orig={$m_imageOrig}"
    }

    return $camera
}
body GridGroup::GridBase::setBeamCenter { x y } {
    #puts "setBeamCenter for $this x=$x y=$y"
    loadIfNeed
    set _beamCenterX $x
    set _beamCenterY $y

    calculateGridOrig
}
body GridGroup::GridBase::initialize {
    id label sortNum snapshotId orig geo matrix nodes param
} {
    set _allLoaded 1
    set m_id $id
    set m_label $label
    set m_sortNum $sortNum

    set m_myTag grid$m_label

    ## no update userInput
    setGeo $snapshotId $orig $geo $matrix $nodes 0

    set prefix [dict get $param prefix]
    append prefix $label
    dict set param prefix $prefix
    ## this will update userInput
    setParameter $param

    set _needWrite 1
}
body GridGroup::GridBase::setGeo { snapshotId orig geo matrix nodes {update 1}} {
    loadIfNeed

    if {$snapshotId >= 0} {
        set m_defaultSnapshotId $snapshotId
    }
    set d_geo $geo
    set d_matrix $matrix
    set l_nodeList $nodes
    if {$orig != ""} {
        set m_imageOrig $orig
    }
    set m_status "setup"

    updateNumbers
    generateSequenceMap

    calculateGridOrig

    if {$update} {
        generateUserSetupDict
    }
    set _needWrite 1
}
body GridGroup::GridBase::setSnapshotId { snapshotId } {
    loadIfNeed

    set m_defaultSnapshotId $snapshotId
    set _needWrite 1
}
body GridGroup::GridBase::setParameter { param } {
    loadIfNeed

    set d_parameter [dict merge $d_parameter $param]
    generateUserSetupDict
    set _needWrite 1
}
body GridGroup::GridBase::calculateGridOrig { } {
    ### the logical: When sample_xyz is at m_imageOrig, the beam center is
    ### at (_beamCenterX _beamCenterY).
    ### To move the beam to the center of grid, you will need to adjust.
    foreach {x0 y0 z0 a0 hMM wMM} $m_imageOrig break

    set umBeamX [expr $_beamCenterX * $wMM * 1000.0]
    set umBeamY [expr $_beamCenterY * $hMM * 1000.0]

    ### the units are micron for most of them.
    set center_x    [dict get $d_matrix center_x]
    set center_y    [dict get $d_matrix center_y]
    set cell_width  [dict get $d_matrix cell_width]
    set cell_height [dict get $d_matrix cell_height]
    set num_row     [dict get $d_matrix num_row]
    set num_column  [dict get $d_matrix num_column]

    set dH [expr $center_x - $umBeamX]
    set dV [expr $center_y - $umBeamY]
    foreach {dx dy dz} [calculateSamplePositionDeltaFromDeltaProjection \
    $m_imageOrig $dV $dH 1] break

    set newX [expr $x0 + $dx]
    set newY [expr $y0 + $dy]
    set newZ [expr $z0 + $dz]
    set newA $a0
    set cellWmm [expr $cell_width  / 1000.0]
    set cellHmm [expr $cell_height / 1000.0]

    ## pay attention to cell size order
    set _orig \
    [list $newX $newY $newZ $newA $cellHmm $cellWmm $num_row $num_column]
    #puts "grid orig: $_orig"
}
body GridGroup::GridBase::checkNode { } {
    #puts "checkNode: d_matrix=$d_matrix"
    set num_row     [dict get $d_matrix num_row]
    set num_column  [dict get $d_matrix num_column]

    set num_node [expr $num_row * $num_column]
    set ll [llength $l_nodeList]
    if {$ll != $num_node} {
        log_warning length of nodes $ll not match \
        row $num_row X column $num_column

    }
}
body GridGroup::GridBase::updateNumbers { } {
    set _numImageNeed 0
    set _numImageDone 0

    checkNode

    foreach node $l_nodeList {
        if {$node == "S"} {
            incr _numImageNeed
        } else {
            set v [lindex $node 0]
            if {[string is double -strict $v]} {
                incr _numImageDone
            } else {
                set shape [dict get $d_geo shape]
                if {$shape == "l614" && $node == "D"} {
                    incr _numImageDone
                }
            }
        }
    }
}
body GridGroup::GridBase::generateSequenceMap { } {
    set _sequence2index ""
    set _index2sequence ""
    if {[catch {dict get $d_matrix type} seqType]} {
        set seqType horz
    }
    if {$seqType == "horz"} {
        set i -1
        set s 0
        foreach node $l_nodeList {
            incr i
            switch -exact -- $node {
                - -
                -- {
                    lappend _index2sequence -1
                }
                default {
                    lappend _sequence2index $i

                    ### s is [llength _sequence2index]
                    lappend _index2sequence $s
                    incr s
                }
            }
        }
    } else {
        set num_row     [dict get $d_matrix num_row]
        set num_column  [dict get $d_matrix num_column]
        set _index2sequence [string repeat "-1 " [expr $num_row * $num_column]]
        set s 0
        #### right to left
        for {set col [expr $num_column -1]} {$col >=0} {incr col -1} {
            ##### top down
            for {set row 0} {$row < $num_row} {incr row} {
                set i [expr $row * $num_column + $col]
                set node [lindex $l_nodeList $i]
                switch -exact -- $node {
                    - -
                    -- {
                        lappend _index2sequence -1
                    }
                    default {
                        lappend _sequence2index $i
                        set _index2sequence [lreplace $_index2sequence $i $i $s]
                        incr s
                    }
                }
            }
        }
    }
    #puts "seq2idx: $_sequence2index"
    #puts "idx2seq: $_index2sequence"
}
body GridGroup::GridBase::generateUserSetupDict { } {
    #puts "calling generateUserSetupDict for $this"
    #### non-graphic setup: can change without the graph
    set _d_userSetup $d_parameter
    dict set _d_userSetup summary "grid $m_label $m_status"
    foreach name $_USERSETUP_NAMELIST {
        switch -exact -- $name {
            shape -
            center_x -
            center_y {
                if {[catch {dict get $d_geo $name} v]} {
                    puts "not fully populated yet: $name"
                    set v 0
                }
            }
            item_width {
                if {[catch {dict get $d_geo half_width} v]} {
                    puts "not fully populated yet: half_width"
                    set v 0
                } else {
                    set v [expr 2.0 * $v]
                }
            }
            item_height {
                if {[catch {dict get $d_geo half_height} v]} {
                    puts "not fully populated yet: half_height"
                    set v 0
                } else {
                    set v [expr 2.0 * $v]
                }
            }
            angle {
                if {[catch {dict get $d_geo $name} v]} {
                    puts "not fully populated yet: $name"
                    set v 0
                } else {
                    ### to degree
                    set v [expr $v * 180.0 / 3.1415926]
                }
            }
            cell_width -
            cell_height {
                if {[catch {dict get $d_matrix $name} v]} {
                    puts "not fully populated yet: $name"
                    set v 0
                }
            }
            prefix -
            directory -
            collimator -
            beam_width -
            beam_height -
            beam_stop -
            distance -
            delta -
            time -
            attenuation {
                if {[catch {dict get $d_parameter $name} v]} {
                    puts "not fully populated yet: $name"
                    set v 0
                } else {
                    continue
                }
            }
            processing {
                if {[catch {dict get $d_parameter $name} v]} {
                    puts "not fully populated yet: $name"
                    set v 1
                } else {
                    continue
                }
            }
            default {
                log_severe new item $name not supported in userSetup
                log_error namelist=$_USERSETUP_NAMELIST
                continue
            }
        }
        dict set _d_userSetup $name $v
    }
}
body GridGroup::GridBase::setUserInput { setup } {
    set ll [llength $setup]
    #puts "$this setUserInput ll=$ll"
    if {$ll % 2} {
        log_error bad user setup, odd length
        puts "bad user setup: {$setup}"
        return -code error BAD_INPUT
    }

    loadIfNeed

    set needUpdateGraph 0

    set anyChange 0

    dict for {name value} $setup {
        switch -exact -- $name {
            center_x -
            center_y {
                set old_v [dict get $d_geo $name]
                dict set d_geo $name $value
                if {abs($old_v - $value) > 0.1} {
                    incr anyChange
                    set needUpdateGraph 1
                }
            }
            item_width {
                set old_v [dict get $d_geo half_width]
                set v [expr abs($value / 2.0)]
                dict set d_geo half_width $v
                if {abs($old_v - $v) > 0.1} {
                    incr anyChange
                    set needUpdateGraph 1
                }
            }
            item_height {
                set old_v [dict get $d_geo half_height]
                set v [expr abs($value / 2.0)]
                dict set d_geo half_height $v
                if {abs($old_v - $v) > 0.1} {
                    incr anyChange
                    set needUpdateGraph 1
                }
            }
            angle {
                set old_v [dict get $d_geo $name]
                set v [expr $value * 3.1415926 / 180.0]
                dict set d_geo $name $v
                if {abs($old_v - $v) > 0.001} {
                    incr anyChange
                    set needUpdateGraph 1
                }
            }
            cell_width -
            cell_height {
                set old_v [dict get $d_matrix $name]
                dict set d_matrix $name $value
                if {abs($old_v - $value) > 0.1} {
                    incr anyChange
                    set needUpdateGraph 1
                }
            }
            prefix -
            directory -
            collimator {
                set old_v [dict get $d_parameter $name]
                dict set d_parameter $name $value
                if {$old_v != $value} {
                    incr anyChange
                }
            }
            beam_width -
            beam_height -
            beam_stop -
            distance -
            delta -
            time -
            attenuation -
            processing {
                if {[catch {dict get $d_parameter $name} old_v]} {
                    incr anyChange
                    set old_v 0
                }
                dict set d_parameter $name $value
                if {abs($old_v - $value) > 0.001} {
                    incr anyChange
                }
            }
            shape {
                ### cannot update shape
                continue
            }
            default {
                if {[catch {dict get $d_parameter $name} old_v]} {
                    incr anyChange
                    set old_v 0
                }
                dict set d_parameter $name $value
                if {$old_v != $value} {
                    incr anyChange
                }
            }
        }
    }
    generateUserSetupDict
    if {$anyChange} {
        set _needWrite 1
    }
    return [list $anyChange $needUpdateGraph]
}
body GridGroup::GridBase::sequence2index { seq } {
    set ll [llength $_sequence2index]
    if {$seq < 0 || $seq >= $ll} {
        log_error bad sequence: $seq
        puts " bad sequence: $seq ll=$ll"
        return -1
    }
    return [lindex $_sequence2index $seq]
}
body GridGroup::GridBase::setNodeStatus { index status } {
    loadIfNeed

    set ll [llength $l_nodeList]
    if {$index < 0 || $index >= $ll} {
        log_warning index $index out of range
        return 0
    }
    set currentStatus [lindex $l_nodeList $index]
    if {$currentStatus == "--" || $currentStatus == "-"} {
        log_warning that node is marked as not_exists
        return 0
    }
    set old_status [lindex $l_nodeList $index]
    if {$old_status == $status} {
        return 0
    }
    set l_nodeList [lreplace $l_nodeList $index $index $status]
    updateNumbers

    set _needWrite 1
    return 1
}
body GridGroup::GridBase::setEnergyUsed { e } {
    loadIfNeed

    if {$m_energyUsed == $e} {
        return 0
    }

    set m_energyUsed $e

    set _needWrite 1
    return 1
}
body GridGroup::GridBase::setAllNodes { nList } {
    loadIfNeed

    set l1 [llength $l_nodeList]
    set l2 [llength $nList]
    if {$l1 != $l2} {
        log_error setAllNodes with different length = $l2 != nodeList = $l1
        return 0
    }
    if {$l_nodeList == $nList} {
        return 0
    }

    set l_nodeList $nList
    updateNumbers
    set _needWrite 1
    return 1
}
body GridGroup::GridBase::reset { } {
    loadIfNeed

    set statusChange  [setStatus "setup"]
    setEnergyUsed 0.0

    set newNodeList ""
    foreach node $l_nodeList {
        switch -exact -- $node {
            - -
            -- -
            N {
                ### no change
                lappend newNodeList $node
            }
            default {
                lappend newNodeList S
            }
        }
    }
    set nodeListChange 0
    if {$newNodeList != $l_nodeList} {
        set l_nodeList $newNodeList
        updateNumbers
        set nodeListChange 1
    }

    if {$statusChange || $nodeListChange} {
        set _needWrite 1
    }
    return [list $statusChange $nodeListChange]
}
body GridGroup::GridBase::clearIntermediaResults { } {
    loadIfNeed

    set statusChange [setStatus "setup"]

    set newNodeList ""
    foreach node $l_nodeList {
        switch -exact -- $node {
            - -
            -- -
            D -
            N {
                ### no change
                lappend newNodeList $node
            }
            default {
                if {[string length $node] <= 1} {
                    lappend newNodeList S
                } else {
                    lappend newNodeList $node
                }
            }
        }
    }
    set nodeListChange 0
    if {$newNodeList != $l_nodeList} {
        set l_nodeList $newNodeList
        updateNumbers
        set nodeListChange 1
    }

    if {$statusChange || $nodeListChange} {
        set _needWrite 1
    }
    return [list $statusChange $nodeListChange]
}
body GridGroup::GridBase::getNodeIndex { row column } {
    loadIfNeed

    set num_row     [dict get $d_matrix num_row]
    set num_column  [dict get $d_matrix num_column]

    if {$row < 0 || $row >= $num_row || $column < 0 || $column >= $num_column} {
        log_error node position invalid row=$row column=$column.
        return -code error INVALIDE_POSITION
    }
    set index [expr $row * $num_column + $column]
    return $index
}
body GridGroup::GridBase::flipNode { index } {
    loadIfNeed

    set currentStatus [lindex $l_nodeList $index]
    if {$currentStatus == "--" || $currentStatus == "-"} {
        log_warning that node is marked as not_exists
        return [list 0 0]
    }
    set first [lindex $currentStatus 0]
    if {[string is double -strict $first] && $first > 0} {
        log_warning no flip for node already done.
        return [list 0 0]
    }
    set cur0 [string index $first 0]
    if {$cur0 == "D"} {
        log_warning no flip for node already has image.
        return [list 0 0]
    }
    if {$cur0 == "N"} {
        set newStatus "S"
    } else {
        set newStatus "N"
        #set newStatus "NEW"
    }

    set needUpdateWholeList 0
    set needUpdateStatus 0
    set oldList $l_nodeList
    if {$newStatus == "S"} {
        set l_nodeList [string map {NEW S} $l_nodeList]
    } else {
        set l_nodeList [string map {NEW N} $l_nodeList]
    }
    if {$l_nodeList != $oldList} {
        set needUpdateWholeList 1
    }
    set l_nodeList [lreplace $l_nodeList $index $index $newStatus]

    updateNumbers
    if {$_numImageNeed == 0} {
        set needUpdateStatus [setStatus "complete"]
    } elseif {$_numImageDone == 0} {
        set needUpdateStatus [setStatus "setup"]
    } else {
        set needUpdateStatus [setStatus "paused"]
    }

    set _needWrite 1
    return [list $needUpdateStatus $needUpdateWholeList]
}
body GridGroup::GridBase::getSetupProperties { } {
    loadIfNeed

    set status [getStatus]

    ### _d_userSetup is generated but for convenient, we include it too.

    if {$_d_userSetup == ""} {
        puts "usersetup == empty for $this"
        generateUserSetupDict
    }

    return [list \
    $m_status \
    $_numImageNeed \
    $_numImageDone \
    $d_matrix  \
    $d_parameter \
    $_d_userSetup \
    ]
}
body GridGroup::GridBase::getAllNodesAndInfo { } {
    loadIfNeed

    set num_row     [dict get $d_matrix num_row]
    set num_column  [dict get $d_matrix num_column]
    set result [list $num_row $num_column $l_nodeList]
    return $result
}
body GridGroup::GridBase::getNodeListInfo { } {
    loadIfNeed

    set result ""
    foreach index $_sequence2index {
        set node [lindex $l_nodeList $index]
        lappend result $node
    }
    set labelList ""
    if {[dict exists $d_matrix node_label_list]} {
        set nlList [dict get $d_matrix node_label_list]
        foreach index $_sequence2index {
            set nodeLabel [lindex $nlList $index]
            lappend labelList $nodeLabel
        }
    }

    if {[catch {dict get $d_parameter directory} directory]} {
        set directory ""
    }
    if {[catch {dict get $d_parameter prefix} prefix]} {
        set prefix ""
    }
    if {[catch {dict get $d_parameter ext} ext]} {
        set ext ""
    }
    set header [list $m_id $m_label $m_status $directory $prefix $ext]

    return [list $header $result $labelList]
}
body GridGroup::GridBase::getBeamSizeInfo { } {
    loadIfNeed

    set w [dict get $d_parameter beam_width]
    set h [dict get $d_parameter beam_height]
    if {[catch {dict get $d_parameter collimator} collimator]} {
        set collimator ""
        ### this will work too
        #set collimator "0 -1 2.0 2.0"
    }
    return [list $w $h $collimator]
}
body GridGroup::GridBase::getNextNode { current } {
    loadIfNeed

    set ll [llength $_sequence2index]

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
        set nIdx [lindex $_sequence2index $i]
        set nSts [lindex $l_nodeList $nIdx]
        if {$nSts == "S"} {
            return $i
        }
    }
    for {set i 0} {$i < $next} {incr i} {
        if {$i == $current} {
            continue
        }
        set nIdx [lindex $_sequence2index $i]
        set nSts [lindex $l_nodeList $nIdx]
        if {$nSts == "S"} {
            return $i
        }
    }
    return -1
}
body GridGroup::GridBase::getNodePosition { seq } {
    loadIfNeed

    set ll [llength $_sequence2index]
    if {$seq < 0 || $seq >= $ll} {
        log_error seq $seq out of range 0 to [expr $ll - 1]
        return -code error BAD_NODE_SEQ
    }
    set index [lindex $_sequence2index $seq]
    set nodeLabel ""
    if {[dict exists $d_matrix node_label_list]} {
        set nlList [dict get $d_matrix node_label_list]
        set nodeLabel [lindex $nlList $index]
    }

    ###_orig is the orig for grid.
    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $_orig break

    set row_index [expr $index / $numColumn]
    set col_index [expr $index % $numColumn]

    set shape [dict get $d_geo shape]
    if {$shape == "l614"} {
        set localCoords [dict get $d_geo local_coords]
        set holeCoords [lrange $localCoords 16 end]
        set offset0 [expr $index * 2]
        set offset1 [expr $offset0 + 1]

        set proj_h [lindex $holeCoords $offset0]
        set proj_v [lindex $holeCoords $offset1]
        set isMicron 1
    } else {

        set proj_v [expr $row_index - ($numRow    - 1) / 2.0]
        set proj_h [expr $col_index - ($numColumn - 1) / 2.0]
        set isMicron 0
    }
    ## It should always start from orig position.  This way will make sure
    ## the 90 degree view the position is at the same level with orig.
    foreach {dx dy dz} \
    [calculateSamplePositionDeltaFromProjection \
    $_orig $orig_x $orig_y $orig_z $proj_v $proj_h $isMicron] break

    set x [expr $orig_x + $dx]
    set y [expr $orig_y + $dy]
    set z [expr $orig_z + $dz]

    return [list $x $y $z $orig_a $row_index $col_index $nodeLabel]
}
body GridGroup::GridBase::getMovePosition { ux uy } {
    loadIfNeed

    return [calculateSamplePositionFromProjection $_orig $uy $ux 1]
}
body GridGroup::GridBase::getMatrixLog { numFmt txtFmt } {
    loadIfNeed

    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $_orig break

    set result [list]

    for {set row 0} {$row < $numRow} {incr row} {
        set line ""
        for {set col 0} {$col < $numColumn} {incr col} {
            set index [expr $row * $numColumn + $col]
            set node [lindex $l_nodeList $index]
            set weight [lindex $node 0]

            if {[string is double -strict $weight]} {
                set nodeDisplay [format $numFmt $weight]
            } else {
                switch -exact -- $weight {
                    NEW -
                    N {
                        set nodeDisplay Skip
                    }
                    -- -
                    - {
                        set nodeDisplay ""
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
body GridGroup::GridBase::newOrigIsBetter { newOrig } {
    loadIfNeed

    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth} $_orig break
    foreach {new_x  new_y  new_z  new_a  newH       newW} $newOrig break
    if {abs($orig_a - $new_a) > 1} {
        puts "strange, it should not get here orig_a=$orig_a new_a=$new_a"
        return 0
    }
    if {abs($cellWidth) >= abs($newW)} {
        ### no zoom in change.
        puts "newOrig is NOT better, no zoom in"
        return 0
    }

    ### we check matrix fits in the old and new view.
    set center_x    [dict get $d_matrix center_x]
    set center_y    [dict get $d_matrix center_y]
    set cell_width  [dict get $d_matrix cell_width]
    set cell_height [dict get $d_matrix cell_height]
    set num_row     [dict get $d_matrix num_row]
    set num_column  [dict get $d_matrix num_column]

    set halfW       [expr $num_column * $cell_width  / 2.0]
    set halfH       [expr $num_row    * $cell_height / 2.0]

    set x0          [expr $center_x - $halfW]
    set y0          [expr $center_y - $halfH]
    set x1          [expr $center_x + $halfW]
    set y1          [expr $center_y + $halfH]

    set oldCoords [list $x0 $y0 $x1 $y1]
    set newCoords [translateProjectionCoords $oldCoords $_orig $newOrig]
    foreach {newX0 newY0 newX1 newY1} $newCoords break

    if {$newX0 < 0 || $newX1 < 0 || $newY0 < 0 || $newY1 < 0} {
        puts "newOrig is NOT better, exceed 0 border"
        return 0
    }
    set newWu [expr $newW * 1000.0]
    set newHu [expr $newH * 1000.0]
    if {$newX0 >= $newWu || $newX1 >= $newWu \
    ||  $newY0 >= $newHu || $newY0 >= $newHu} {
        puts "newOrig is NOT better, exceed border"
        return 0
    }

    return 1
}

class GridGroup::SnapshotImage {
    inherit GridGroup::Item

    ### sortAngle is angle from "0"
    ### it can be calculated from snapshot orig and group orig.
    ### We just do not want to do the calculation again and again.
    public method initialize { id label sortAngle camera file orig }
    public method getCamera { } { return $m_camera }

    public method removePersistent { } {
        file delete -force $m_imageFile

        DCSPersistentBase::removePersistent
    }

    public method getFile { } { return $m_imageFile }
    public method getOrig { } { return $m_orig }
    public method getGridIdListDefaultOnThis { } {
        return $_gridList
    }
    public method clearGridIdList { } { set _gridList "" }
    public method addGrid { id } {
        if {[lsearch -exact $_gridList $id] < 0} {
            lappend _gridList $id
        }
    }
    public method deleteGrid { id } {
        set index [lsearch -exact $_gridList $id]
        if {$index >= 0} {
            set _gridList [lreplace $_gridList $index $index]
        }
    }

    ### hook
    #protected method afterInitializeFromHuddle { } {
    #}

    protected variable m_imageFile ""
    protected variable m_orig ""
    protected variable m_camera sample

    protected variable _gridList ""
}
body GridGroup::SnapshotImage::initialize { \
    id label sortAngle camera file orig \
} {
    set _allLoaded 1
    set m_tagFileName snapshot$id

    set m_id $id
    set m_label $label
    set m_sortNum $sortAngle

    set m_imageFile $file
    set m_orig      $orig
    set m_camera    $camera

    set _needWrite 1
}

class GridGroup::GridGroupBase {
    inherit DCSPersistentBase DCSPersistentBaseTop

    public method getTopDirectory { } { return $_topDirectory }

    public method getAllFileRPath { } {
        set result ${m_rPathFromTop}.yaml
        #puts "getAllFileRPath: first, self={$result}"
        eval lappend result [getAllSubFileRPath]
        #puts "getAllFileRPath: at the end {$result}"
        return $result
    }

    public method getId { } { return $_groupId }
    public method getDefaultCamera { } { return $m_camera }

    ### These 2 lists are sorted
    public method getSnapshotImageList { } { return $lo_snapshotList }
    public method getSnapshotFileList { }
    public method getGridList { } { return $lo_gridList }
    public method getGridByIndex { index } {
        set ll [llength $lo_gridList]
        if {$index < 0 || $index >= $ll} {
            return ""
        }
        return [lindex $lo_gridList $index]
    }
    public method getGrid { id } {
        return [_get_grid $id]
    }
    ###The grid should only be used for reading access.
    ###The grid object is invalid once load again.
    public method getGridIdByIndex { index } {
        set grid [getGridByIndex $index]
        if {$grid == ""} {
            return -1
        }
        return [$grid getId]
    }

    public method getSnapshotIdForGrid { gridId } {
        if {[catch {dict get $_gridSnapshotMap $gridId} ssId]} {
            return -1
        }
        return $ssId
    }

    ### used in dcss to send notes.
    public method getGridLabel { gridId } {
        set grid [_get_grid $gridId]
        return [$grid getLabel]
    }

    public method searchSnapshotId { orig }

    public proc getMAXGROUP { } { return 1 }
    public proc getMAXNUMSNAPSHOT { } { return 16 }
    public proc getMAXNUMGRID { } { return 16 }
    public proc compareItem { t1 t2 }

    protected method sortSnapshot
    protected method sortGrid
    protected method updateSnapshotIdMap { }
    protected method generateGridMap { }
    protected method linkSnapshotToGrid { }

    public method load { id path {silent 0}}

    ### hook
    protected method afterInitializeFromHuddle { } {
        #puts "calling afterInit for $this"
        sortSnapshot
        updateSnapshotIdMap
        generateGridMap
        linkSnapshotToGrid
    }

    ## both snapshot Id and grid Id are unique in group.
    protected method getNextSnapshotId { }
    ### need display this on the "*" tab
    public method getNextGridId { }
    ### help functions used in both DCSS and BluIce
    ### no write, no operation update messages
    protected method _add_snapshot_image { id label sortNum camera file orig }
    protected method _delete_snapshot_image { id {removePersistent 0} {forced 0} }
    protected method _add_grid { \
        snapId id label sortNum orig geo grid nodes param \
    }
    protected method _modify_grid { id orig geo matrix nodes }
    protected method _modify_grid_snapshot_id { id snapshotId }
    protected method _modify_parameter { id param }
    protected method _modify_userInput { id setup }
    protected method _modify_detectorMode_fileExt { id mode ext }
    protected method _delete_grid { id {removePersistent 0} {forced 0} }
    protected method _get_grid { id }
    protected method _clear_all { }

    protected variable _groupId -1

    protected variable m_orig {0 0 0 0 1 1 1 1}

    protected variable m_snapshotSeqNum 1
    #### reset during initialize
    protected variable m_camera sample

    protected variable lo_snapshotList ""

    protected variable _snapshotIdMap ""
    ### _createdGridList in snapshotImage
    protected variable lo_gridList ""
    protected variable _gridIdMap ""
    protected variable _gridSnapshotMap ""

    protected variable _topDirectory ""
    protected variable _path ""

}
### this is for copy files to user directory
#### TODO: add the snapshot files from each grid to this list too.
body GridGroup::GridGroupBase::getSnapshotFileList { } {
    set result ""
    foreach ss $lo_snapshotList {
        lappend result [$ss getFile]
    }
    return $result
}
body GridGroup::GridGroupBase::linkSnapshotToGrid { } {
    foreach ss $lo_snapshotList {
        $ss clearGridIdList
    }
    dict for {gridId snapshotId} $_gridSnapshotMap {
        set ss [dict get $_snapshotIdMap $snapshotId]
        $ss addGrid $gridId
    }
}
body GridGroup::GridGroupBase::generateGridMap { } {
    set _gridIdMap [dict create]
    set _gridSnapshotMap [dict create]
    foreach grid $lo_gridList {
        set snapshotId [$grid getDefaultSnapshotId]
        set id         [$grid getId]
        dict set _gridIdMap $id $grid
        dict set _gridSnapshotMap $id $snapshotId
    }
    if {$lo_gridList != ""} {
        sortGrid
    }

    #puts "grid list: {$lo_gridList}"
}
body GridGroup::GridGroupBase::updateSnapshotIdMap { } {
    set _snapshotIdMap ""
    foreach ss $lo_snapshotList {
        set id [$ss getId]
        dict set _snapshotIdMap $id $ss
    }
}
body GridGroup::GridGroupBase::compareItem { t1 t2 } {
    set n1 [$t1 getSortNum]
    set n2 [$t2 getSortNum]

    if {$n1 > $n2} {
        return 1
    } elseif {$n1 == $n2} {
        return 0
    } else {
        return -1
    }
}
body GridGroup::GridGroupBase::sortSnapshot { } {
    if {$lo_snapshotList != ""} {
        set ss [lindex $lo_snapshotList 0]
        set m_camera [$ss getCamera]
    }

    set lo_snapshotList [lsort -command [code compareItem] $lo_snapshotList]
}
body GridGroup::GridGroupBase::sortGrid { } {
    set lo_gridList [lsort -command [code compareItem] $lo_gridList]
}
body GridGroup::GridGroupBase::load { id path {silent 0} } {
    if {$path == "not_exists"} {
        log_error gridGroup not exsits
        return -code error not_exsits
    }
    set _topDirectory [file dirname $path]
    set m_myTag [file rootname [file tail $path]]
    _setTopAndTags $this ""

    if {$id == $_groupId && $path == $_path && ![needLoad]} {
        ### no need to reload
        #puts "no need to load for $this from $path, checking other files"
        checkRegisteredSelfPersistentObjects
        return
    }

    set _registeredObjectList ""

    set _groupId $id
    set _path $path
    _loadFromFile $path $silent
    _generateRPath
    #puts "after load rPath=$m_rPathFromTop"
}
body GridGroup::GridGroupBase::getNextSnapshotId { } {
    ### snapshots are sorted by phi from starting position

    set currentMaxId -1
    foreach ss $lo_snapshotList {
        set id [$ss getId]
        if {$id > $currentMaxId} {
            set currentMaxId $id
        }
    }
    set nextId [expr $currentMaxId + 1]
    return $nextId
}
body GridGroup::GridGroupBase::getNextGridId { } {
    ### grid has the same id, label, and sortNum
    set nextGridId 1
    if {$lo_gridList != ""} {
        set lastGrid [lindex $lo_gridList end]
        set lastGridId [$lastGrid getSortNum]
        set nextGridId [expr $lastGridId + 1]
    }
    return $nextGridId
}
body GridGroup::GridGroupBase::_add_snapshot_image { \
    id label sortNum camera file orig \
} {
    if {[dict exists $_snapshotIdMap $id]} {
        log_error snapshot with $id already exists.
        return -code error SNAPSHOT_ALREADY_EXISTS
    }
    set ss [::GridGroup::SnapshotImage ::\#auto]
    $ss initialize $id $label $label $camera $file $orig
    setupTopAndTagsForChild $ss
    ## $ss generateRPath

    lappend lo_snapshotList $ss

    sortSnapshot
    updateSnapshotIdMap
    #generateGridMap

    set _needWrite 1
    return $ss
}
body GridGroup::GridGroupBase::_delete_snapshot_image { id {removePersistent 0} {forced 0} } {
    if {![dict exists $_snapshotIdMap $id]} {
        log_error snapshot with $id not exists
        return -code error SNAPSHOT_NOT_EXISTS
    }
    set ll [llength $lo_snapshotList]
    if {$ll < 2} {
        log_error cannot delete the last snapshot in group.
        return -code error LAST_SNAPSHOT
    }

    set ss [dict get $_snapshotIdMap $id]
    if {!$forced} {
        set found 0
        set errMsg "need to remove"
        foreach grid $lo_gridList {
            set ssId [$grid getDefaultSnapshotId]
            if {$ssId == $id} {
                append errMsg " grid[$grid getLabel]"
                incr found
            }
        }
        if {$found} {
            eval log_error $errMsg
            return -code error STILL_GRID_ON_IT
        }
    }

    if {$removePersistent} {
        $ss removePersistent
    }
    delete object $ss

    set index [lsearch -exact $lo_snapshotList $ss]
    while {$index >= 0} {
        set lo_snapshotList [lreplace $lo_snapshotList $index $index]
        set index [lsearch -exact $lo_snapshotList $ss]
    }
    #updateSnapshotIdMap
    dict unset _snapshotIdMap $id
    #sortSnapshot
    #updateSnapshotIdMap
    generateGridMap

    set _needWrite 1
}
body GridGroup::GridGroupBase::_add_grid { \
    snapshotId id label sortNum orig geo matrix nodes param \
} {
    #### get snapshot object
    if {![dict exists $_snapshotIdMap $snapshotId]} {
        log_error cannot find snapshot with Id=$snapshotId
        return -code error "snapshot_not_exists"
    }
    set ss [dict get $_snapshotIdMap $snapshotId]
    $ss addGrid $id

    if {[dict exists $_gridIdMap $id]} {
        ### id in fact is unique in whole group
        log_error grid with id=$id already exists
        return -code error "ALREADY_EXISTS"
    }
    set grid [::GridGroup::GridBase ::\#auto]

    if {$orig == ""} {
        set orig [$ss getOrig]
    }

    puts "_add_grid initing grid"
    $grid initialize $id $label $sortNum \
    $snapshotId $orig $geo $matrix $nodes $param

    puts "_add_grid setupTop"
    setupTopAndTagsForChild $grid
    $grid _generateRPath

    ###generateGridMap
    lappend lo_gridList $grid
    dict set _gridIdMap       $id $grid
    dict set _gridSnapshotMap $id $snapshotId

    set _needWrite 1

    return $grid
}
body GridGroup::GridGroupBase::_modify_grid { \
    id orig geo matrix nodes \
} {
    if {![dict exists $_gridIdMap $id]} {
        ### id in fact is unique in whole group
        log_error grid with id=$id not exists
        return -code error "NOT_EXISTS"
    }
    set rr [_get_grid $id]
    if {![$rr getEditable]} {
        log_error reset it to setup.
        return -code error CANNOT_MODIFY
    }

    # -1 means no change for defaultSnapshotImage
    $rr setGeo -1 $orig $geo $matrix $nodes

    set _needWrite 1
}
body GridGroup::GridGroupBase::_modify_grid_snapshot_id { id snapshotId } {
    if {![dict exists $_gridIdMap $id]} {
        ### id in fact is unique in whole group
        log_error grid with id=$id not exists
        return -code error "NOT_EXISTS"
    }
    set rr [_get_grid $id]
    if {![$rr getEditable]} {
        log_error reset it to setup.
        return -code error CANNOT_MODIFY
    }

    $rr setSnapshotId $snapshotId

    generateGridMap
    linkSnapshotToGrid
    set _needWrite 1
}
body GridGroup::GridGroupBase::_modify_parameter { id param } {
    if {![dict exists $_gridIdMap $id]} {
        ### id in fact is unique in whole group
        log_error grid with id=$id not exists
        return -code error "NOT_EXISTS"
    }
    set rr [_get_grid $id]
    if {![$rr getEditable]} {
        log_error reset it to setup.
        return -code error CANNOT_MODIFY
    }

    $rr setParameter $param

    set _needWrite 1
}
body GridGroup::GridGroupBase::_modify_userInput { id setup } {
    if {![dict exists $_gridIdMap $id]} {
        log_error grid with id=$id not exists
        return -code error "NOT_EXISTS"
    }

    set rr [getGrid $id]
    if {![$rr getEditable]} {
        log_error reset it to setup.
        return -code error CANNOT_MODIFY
    }

    set result [$rr setUserInput $setup]
    set anyChange [lindex $result 0]
    if {$anyChange} {
        set _needWrite 1
    }
    return $result
}
body GridGroup::GridGroupBase::_modify_detectorMode_fileExt { id mode ext } {
    if {![dict exists $_gridIdMap $id]} {
        ### id in fact is unique in whole group
        log_error grid with id=$id not exists
        return -code error "NOT_EXISTS"
    }

    set rr [getGrid $id]
    $rr setDetectorModeAndFileExt $mode $ext

    set _needWrite 1
}
body GridGroup::GridGroupBase::_delete_grid { id {removePersistent 0} {forced 0} } {
    if {![dict exists $_gridIdMap $id]} {
        ### id in fact is unique in whole group
        log_error grid with id=$id not exists
        return -code error "NOT_EXISTS"
    }

    set grid [dict get $_gridIdMap $id]
    if {![$grid getDeletable]} {
        log_error reset it before delete.
        return -code error CANNOT_DELETE
    }

    set snapshotId [$grid getDefaultSnapshotId]
    if {![catch {dict get $_snapshotIdMap $snapshotId} snapshot]} {
        $snapshot deleteGrid $id
    }

    if {$removePersistent} {
        #puts "calling removePersistent"
        $grid removePersistent
    }
    delete object $grid
    set index [lsearch -exact $lo_gridList $grid]
    if {$index >= 0} {
        set lo_gridList [lreplace $lo_gridList $index $index]
    }

    #generateGridMap
    dict unset _gridIdMap       $id
    dict unset _gridSnapshotMap $id

    set _needWrite 1
}
body GridGroup::GridGroupBase::_clear_all { } {
    foreach grid $lo_gridList {
        set id [$grid getId]
        set snapshotId [$grid getDefaultSnapshotId]
        if {![catch {dict get $_snapshotIdMap $snapshotId} snapshot]} {
            $snapshot deleteGrid $id
        }
        $grid removePersistent
        delete object $grid
    }
    set lo_gridList ""
    foreach ss $lo_snapshotList {
        $ss removePersistent
        delete object $ss
    }
    set lo_snapshotList ""
    set m_snapshotSeqNum 1

    afterInitializeFromHuddle
    set _needWrite 1
}
body GridGroup::GridGroupBase::_get_grid { id } {
    if {![dict exists $_gridIdMap $id]} {
        ### id in fact is unique in whole group
        log_error grid with id=$id not exists
        return -code error "NOT_EXISTS"
    }
    set grid [dict get $_gridIdMap $id]
    return $grid
}
body GridGroup::GridGroupBase::searchSnapshotId { orig } {
    foreach {x y z a h w} $orig break

    set ssId -1
    foreach ss $lo_snapshotList {
        set sOrig [$ss getOrig]
        foreach {sx sy sz sa sh sw} $sOrig break
        if {abs($sx - $x) < 0.001 \
        &&  abs($sy - $y) < 0.001 \
        &&  abs($sz - $z) < 0.001 \
        &&  abs($sa - $a) < 0.1 \
        &&  abs($sh - $h) < 0.001 \
        &&  abs($sw - $w) < 0.001} {
            set ssId [$ss getId]
            break
        }
    }
    return $ssId
}

##### move into separate file later
class GridGroup::GridGroup4DCSS {
    inherit ::GridGroup::GridGroupBase

    public method getSnapshotSequenceNumber { } { return $m_snapshotSeqNum }

    ### this is the entrance to "create" a new GridGroup.
    ### 2 snapshots, no grids on them.
    public method initialize { id path orig snapshot0 {snapshot1 {}} }
    ### snapshotX: jpg orig camera label
    public method getOrig { } { return $m_orig }

    public method addSnapshotImage { label sortAngle camera file orig }
    public method deleteSnapshotImage { id {forced 0} }

    public method addGrid { snapshotId orig geo grid nodes param }
    public method modifyGrid { id orig geo grid nodes }
    public method modifyGridParameter { id param }
    public method modifyGridUserInput { id setup }
    public method modifyGridSnapshotId { id snapshotId }
    public method setDetectorModeAndFileExt { id mode ext }
    public method deleteGrid { id {forced 0} }
    public method resetGrid { id }
    public method clearGridIntermediaResults { id }
    public method clearAll { }

    public method flipGridNode { id row column }

    ### for collecting
    public method getGridNextNode { id currentNode }
    public method getGridNodePosition { id seq }
    public method getOnGridMovePosition { id ux uy }
    public method getGridStatus { id }
    public method getGridUserInput { id }
    public method getGridEnergyUsed { id }
    #####################
    public method setGridBeamCenter { id x y }
    public method setGridStatus { id status }
    public method setGridNodeStatus { id index status }
    public method setGridNodeStatusBySequence { id seq status }
    public method setGridEnergyUsed { id e }

    public method getGridCenterPosition { id }
    public method getGridNumImageDone { id }
    public method getGridNumImageNeed { id }
    public method getGridMatrixLog { id numFmt txtFmt }

    public method loadL614SampleList { id sampleList }

    public method write { }

    ### should not have any persistent variable.
    constructor { } {
        ### we will take care of it.
        set _clearNeedAfterWrite    1
        set _loadAll                0
    }
}
body GridGroup::GridGroup4DCSS::write { } {
    if {[needWrite]} {
        _writeToFile $_path
    } else {
        flushRegisteredSelfPersistentObjects
    }
}
body GridGroup::GridGroup4DCSS::addSnapshotImage { \
    label sortAngle camera file orig \
} {
    incr m_snapshotSeqNum

    set id [getNextSnapshotId]

    ## this one set _needWrite 1
    set ss [_add_snapshot_image $id $label $sortAngle $camera $file $orig]

    send_operation_update ADD_SNAPSHOT $_groupId \
    $id $label $sortAngle $camera $file $orig

    _writeToFile $_path

    return $ss
}
body GridGroup::GridGroup4DCSS::initialize { \
    id path orig snapshot0 {snapshot1 {}} \
} {
    set _allLoaded 1
    set _groupId $id
    set _path $path
    set _topDirectory [file dirname $path]
    set m_orig $orig
    set m_myTag [file rootname [file tail $path]]
    _setTopAndTags $this ""


    foreach ss $lo_snapshotList {
        #$ss removePersistent
        delete object $ss
    }
    set lo_snapshotList ""
    set _gridSnapshotMap ""

    set m_snapshotSeqNum 2
    set ss0 [::GridGroup::SnapshotImage ::\#auto]
    #puts "got ss0: {$snapshot0}"
    eval $ss0 initialize $snapshot0
    setupTopAndTagsForChild $ss0

    set m_camera [$ss0 getCamera]
    ### you can check snapshot orig with group orig
    ### they should only diff in angle

    #puts "in initialize: add snapshot $ss0 to list"
    lappend lo_snapshotList $ss0
    if {$snapshot1 != ""} {
        incr m_snapshotSeqNum
        set ss1 [::GridGroup::SnapshotImage ::\#auto]
        eval $ss1 initialize $snapshot1
        setupTopAndTagsForChild $ss1
        lappend lo_snapshotList $ss1
    }

    sortSnapshot
    updateSnapshotIdMap
    generateGridMap

    ### use write if it may not needed.
    #puts "calling _writeToFile"
    _writeToFile $_path
}
body GridGroup::GridGroup4DCSS::deleteSnapshotImage { id {forced 0} } {
    _delete_snapshot_image $id 1 $forced

    send_operation_update DELETE_SNAPSHOT $_groupId $id 0 $forced

    _writeToFile $_path
}
body GridGroup::GridGroup4DCSS::addGrid { \
snapshotId orig geo grid nodes param \
} {
    set id [getNextGridId]

    set old_dir    [dict get $param directory]
    set old_prefix [dict get $param prefix]
    set new_dir    [string map "GRID_LABEL $id" $old_dir]
    set new_prefix [string map "GRID_LABEL $id" $old_prefix]
    if {$new_dir != $old_dir} {
        dict set param directory $new_dir
    }
    if {$new_prefix != $old_prefix} {
        dict set param prefix $new_prefix
    }

    set obj [_add_grid $snapshotId $id $id $id $orig $geo $grid $nodes $param]

    ### argument  must match _add_grid
    send_operation_update ADD_GRID $_groupId \
    $snapshotId $id $id $id $orig $geo $grid $nodes $param

    _writeToFile $_path

    return $obj
}
body GridGroup::GridGroup4DCSS::modifyGrid { \
    id orig geo matrix nodes \
} {
    _modify_grid $id $orig $geo $matrix $nodes

    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes

    write
}
body GridGroup::GridGroup4DCSS::modifyGridSnapshotId { id snapshotId } {
    _modify_grid_snapshot_id $id $snapshotId

    ## argument must match _modify_parameter
    send_operation_update MODIFY_GRID_SNAPSHOT_ID $_groupId \
    $id $snapshotId

    write
}
body GridGroup::GridGroup4DCSS::modifyGridParameter { id param } {
    _modify_parameter $id $param

    ## argument must match _modify_parameter
    send_operation_update MODIFY_PARAMETER $_groupId \
    $id $param

    write
}
### unlike others, this setup normally is just one name and one value.
### it will just merge, not replace the whole _d_userSetup
body GridGroup::GridGroup4DCSS::modifyGridUserInput { id setup } {
    foreach {anyChange updateGUI} \
    [_modify_userInput $id $setup] break

    ## argument must match _modify_parameter
    send_operation_update MODIFY_USER_INPUT $_groupId \
    $id $setup

    #if {!$anyChange} {
    #    puts "skip write in user input, no real change"
    #}
    write
}
body GridGroup::GridGroup4DCSS::setDetectorModeAndFileExt { id mode ext } {
    _modify_detectorMode_fileExt $id $mode $ext

    ## argument must match _modify_parameter
    send_operation_update SET_DETECTOR_MODE_EXT $_groupId \
    $id $mode $ext

    write
}
body GridGroup::GridGroup4DCSS::deleteGrid { id {forced 0} } {
    _delete_grid $id 1 $forced

    send_operation_update DELETE_GRID $_groupId $id 0 $forced

    _writeToFile $_path
}
body GridGroup::GridGroup4DCSS::clearAll { } {
    _clear_all

    send_operation_update CLEAR_ALL $_groupId

    _writeToFile $_path
}
body GridGroup::GridGroup4DCSS::resetGrid { id } {
    set grid [_get_grid $id]
    foreach {needUpdateStatus needUpdateWholeList} [$grid reset] break

    if {$needUpdateStatus} {
        set status [$grid getStatus]
        send_operation_update GRID_STATUS $_groupId $id $status
    }

    if {$needUpdateWholeList} {
        set nodeList [$grid getNodeList]
        send_operation_update NODE_LIST $_groupId $id $nodeList
    }

    write
}
body GridGroup::GridGroup4DCSS::clearGridIntermediaResults { id } {
    set grid [_get_grid $id]
    foreach {needUpdateStatus needUpdateWholeList} \
    [$grid clearIntermediaResults] break

    if {$needUpdateStatus} {
        set status [$grid getStatus]
        send_operation_update GRID_STATUS $_groupId $id $status
    }

    if {$needUpdateWholeList} {
        set nodeList [$grid getNodeList]
        send_operation_update NODE_LIST $_groupId $id $nodeList
    }

    write
}
body GridGroup::GridGroup4DCSS::flipGridNode { id row column } {
    set grid [_get_grid $id]
    set index [$grid getNodeIndex $row $column]
    foreach {needUpdateStatus needUpdateWholeList} [$grid flipNode $index] break

    if {$needUpdateStatus} {
        set status [$grid getStatus]
        send_operation_update GRID_STATUS $_groupId $id $status
    }

    if {$needUpdateWholeList} {
        set nodeList [$grid getNodeList]
        send_operation_update NODE_LIST $_groupId $id $nodeList
    } else {
        set nodeStatus [$grid getNodeStatus $index]
        send_operation_update NODE $_groupId $id $index $nodeStatus
    }

    write
}
body GridGroup::GridGroup4DCSS::setGridStatus { id status } {
    set grid [_get_grid $id]
    if {![$grid setStatus $status]} {
        return
    }

    send_operation_update GRID_STATUS $_groupId $id $status

    write
}
body GridGroup::GridGroup4DCSS::setGridNodeStatus { \
    id index status \
} {
    set grid [_get_grid $id]
    if {![$grid setNodeStatus $index $status]} {
        return
    }

    send_operation_update NODE $_groupId $id $index $status

    write
}
body GridGroup::GridGroup4DCSS::setGridNodeStatusBySequence { \
    id seq status \
} {
    set grid [_get_grid $id]
    set index [$grid sequence2index $seq]
    if {![$grid setNodeStatus $index $status]} {
        return
    }

    send_operation_update NODE $_groupId $id $index $status

    write
}
body GridGroup::GridGroup4DCSS::getGridStatus { id } {
    set grid [_get_grid $id]
    return [$grid getStatus]
}
body GridGroup::GridGroup4DCSS::getGridUserInput { id } {
    set grid [_get_grid $id]
    return [$grid getUserInput]
}
body GridGroup::GridGroup4DCSS::getGridEnergyUsed { id } {
    set grid [_get_grid $id]
    return [$grid getEnergyUsed]
}
body GridGroup::GridGroup4DCSS::getGridNextNode { id current } {
    set grid [_get_grid $id]
    return [$grid getNextNode $current]
}
body GridGroup::GridGroup4DCSS::getGridNodePosition { id seq } {
    set grid [_get_grid $id]
    return [$grid getNodePosition $seq]
}
body GridGroup::GridGroup4DCSS::getOnGridMovePosition { id ux uy } {
    set grid [_get_grid $id]
    return [$grid getMovePosition $ux $uy]
}
body GridGroup::GridGroup4DCSS::getGridCenterPosition { id } {
    set grid [_get_grid $id]
    return [$grid getCenterPosition]
}
body GridGroup::GridGroup4DCSS::getGridNumImageDone { id } {
    set grid [_get_grid $id]
    return [$grid getNumImageDone]
}
body GridGroup::GridGroup4DCSS::getGridNumImageNeed { id } {
    set grid [_get_grid $id]
    return [$grid getNumImageNeed]
}
body GridGroup::GridGroup4DCSS::setGridBeamCenter { id x y } {
    set grid [_get_grid $id]
    $grid setBeamCenter $x $y
    write
}
body GridGroup::GridGroup4DCSS::setGridEnergyUsed { id e } {
    set grid [_get_grid $id]
    if {[$grid setEnergyUsed $e]} {
        write
    }
}
body GridGroup::GridGroup4DCSS::getGridMatrixLog { id nFmt tFmt} {
    set grid [_get_grid $id]
    return [$grid getMatrixLog $nFmt $tFmt]
}
body GridGroup::GridGroup4DCSS::loadL614SampleList { id sampleList } {
    set grid [_get_grid $id]

    set shape [$grid getShape]
    if {$shape != "l614"} {
        log_error shape=$shape not l614
        return -code error NOT_L614
    }

    set allNodeInfo [$grid getAllNodesAndInfo]
    foreach {numRow numColumn nodeList} $allNodeInfo break

    ### first, turn all to unselected.
    ### similar to  clearIntermediaResults
    set newNodeList ""
    foreach node $nodeList {
        switch -exact -- $node {
            - -
            -- -
            D -
            N {
                ### no change
                lappend newNodeList $node
            }
            default {
                if {[string length $node] <= 1} {
                    lappend newNodeList N
                } else {
                    lappend newNodeList $node
                }
            }
        }
    }

    foreach sample $sampleList {
        ### get index from the position
        set letter [string index $sample 0]
        set row [lsearch -exact {A B C D E} $letter]
        if {$row < 0} {
            log_warning igored sample hole: $sample
            continue
        }
        set col [string range $sample 1 end]
        ## we start from 0
        set col [expr $col - 1]
        set index [expr $row * $numColumn + $col]
        set oldStatus [lindex $newNodeList $index]
        if {$oldStatus == "N"} {
            set newNodeList [lreplace $newNodeList $index $index S]
        }
    }
    if {$newNodeList == $nodeList} {
        log_warning no change
        return 0
    }

    $grid setAllNodes $newNodeList
    send_operation_update NODE_LIST $_groupId $id $newNodeList

    write
}
