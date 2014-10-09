package provide DCSGridGroupBase 1.0

package require Itcl
package require DCSPersistent
package require DCSComponent
package require DCSRunCalculatorForGridCrystal
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

### The sequence now depends on a lot of stuff.
### 1. nodes already have data.  They will be saved permanently and
###    They will be at the front of the sequence list.
### 2. current node, current column direction, row direction,
### 3. nodes state (selected, unselected, has data).
###
### So, it needs to regenerate when user changes the selection.
### For now (02/15/13), we will still use sequence index in
### collectGrid to getNextNode and getNodeInfoBySequence.
### In the future, we may change to use node index, which will not change
### with sequence queue.

class GridGroup::GridBase {
    inherit GridGroup::SelfItem

    ### hook
    protected method afterInitializeFromHuddle { } {
        #puts "calling afterInit for GridBase: $this"
        updateNumbers
        generateUserSetupDict
    }

    ############# added for operation update to get real values from grid
    ############# not from passed in parameters.
    public method getProperties { } {
        loadIfNeed

        return [list \
        $m_imageOrig \
        $d_geo \
        $d_matrix \
        $l_nodeList \
        $l_sequence2index \
        $l_index2sequence \
        ]
    }

    ### you can do it outside by getGeoProperties too.
    public method createDictForRunCalculator { }

    public method getInputPhiRange { }
    public method getCollectedPhiRange { }

    ### for events and attributes
    ### Now parameters also affect geometry, like beam size,
    ### start_angle, node_angle for crystal.
    ### So, we pass them to the GUI too.
    public method getGeoProperties { } {
        loadIfNeed
        return [list $m_imageOrig $d_geo $d_matrix $l_nodeList \
        $l_index2sequence $m_status $__hide $d_parameter]
    }
    public method indexToSequence { index } {
        loadIfNeed

        set ll [llength $l_index2sequence]
        if {$index < 0 || $index >= $ll} {
            return -1
        }
        return [lindex $l_index2sequence $index]
    }
    public method getSetupProperties { }
    public method getNodeListInfo { }
    public method getPhiNodeListForDisplay { }
    public method getAllPhiNodeList { }
    public method validUserInput { key value }
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
    public method getCloneInfo { }
    public method getSplitInfoList { }
    public method getPrefix { }
    public method getForLCLS { }
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
            complete {
                return "complete"
            }
            disabled {
                return "disabled"
            }
            setup -
            ready -
            paused -
            default {
                return 1
            }
        }
    }
    public method getPhiRunnable { } {
        if {[getNumPhiImageNeed] <= 0} {
            return 0
        }
        if {[getNextPhiNode -1] < 0} {
            puts "DEBUG getNumPhiImageNeed not return 0"
            puts "maybe user skipped phi osci with strategy"
            return 0
        }
        return 1
    }
    public method getIsMegaCrystal { } {
        # getShape will call loadIfNeed
        if {[getShape] != "crystal"} {
            return 0
        }
        if {![dict exists $d_geo segment_index_list]} {
            return 0
        }
        set segIdxList [dict get $d_geo segment_index_list]
        set ll [llength $segIdxList]
        if {$ll < 2} {
            return 0
        }
        return 1
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
    public method getSize { } {
        loadIfNeed

        set w [dict get $d_geo size_width]
        set h [dict get $d_geo size_height]

        return [list $w $h]
    }

    public method getTotalNumberPhiImage { } {
        loadIfNeed
        return [expr $_numPhiImageNeed + $_numPhiImageDone]
    }
    public method getNumPhiImageDone { } {
        loadIfNeed
        return $_numPhiImageDone
    }
    public method getNumPhiImageNeed { } {
        loadIfNeed
        return $_numPhiImageNeed
    }

    public method getNodeStatus { index } {
        loadIfNeed
        return [lindex $l_nodeList $index]
    }
    public method getPhiNodeStatus { index } {
        loadIfNeed
        set nodeList4Phi [dict get $d_matrix node_list_for_phi]
        return [lindex $nodeList4Phi $index]
    }
    public method getPhiNodeList { } {
        loadIfNeed
        return [dict get $d_matrix node_list_for_phi]
    }
    public method getNodeList { } {
        loadIfNeed
        return $l_nodeList
    }
    public method getSequenceList { } {
        loadIfNeed
        return [list $l_sequence2index $l_index2sequence]
    }
    public method getCellSize { } {
        loadIfNeed

        set w [dict get $d_matrix cell_width]
        set h [dict get $d_matrix cell_height]

        return [list $w $h]
    }
    public method getItemSize { } {
        loadIfNeed

        set w [dict get $d_geo half_width]
        set h [dict get $d_geo half_height]

        set w [expr abs($w * 2.0)]
        set h [expr abs($h * 2.0)]

        return [list $w $h]
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
    public method setSequenceList { seq2idx idx2seq }
    public method setNodeStatus { index status {current 0} }
    public method setPhiNodeStatus { index status }
    public method setNextFrame { nextFrame }
    public method getNextFrame { }
    ### also flag this is the current node and its dirction
    public method setCurrentNodeStatus { index status }
    public method setAllNodes { nList }
    public method setAllPhiNodes { nList }
    ### need this to manipulate node list from outside,
    ### used for L614 to load hole list.
    public method getAllNodesAndInfo { }
    public method reset { }
    public method resetPhiOsc { }
    public method clearIntermediaResults { }
    #### this one will not clear the nodes with results.

    ### too complicated to use setNodeStatus
    public method flipNode { index }
    ### flip crystal node needs to adjust phi for the nodes.
    public method updateAfterCrystalNodeFlip { omega {name ""} {value ""}}
    public method flipCrystalPhiNode { index }
    public method setCrystalAllPhiNode { value }
    public method getParamForFlipCrystalPhiNodeUpdate { }

    public method getNodeIndex { row column }
    public method getNodeRowAndColumn { index }
    public method getNodeLabel { index }

    #### following, argument is sequence number
    public method getNextNode { current_node }
    public method getNextPhiNode { current_node }
    public method getNodePosition { seq }
    public method sequence2index { seq }

    ###
    public method saveClosestNodeToBeam { sample_x sample_y sample_z }

    public method getCenterPosition { } {
        loadIfNeed
        return $_orig
    }
    ### the positions are affected by beam centers.
    ### crystal need index to decide which node to use as orig.
    public method getMovePosition { x y index }

    ### remove these and the code in collectGrid after
    ### energy is included in user input.
    public method setEnergyUsed { e }
    public method getEnergyUsed { } {
        loadIfNeed
        return $m_energyUsed
    }
    public method getParameter { } {
        loadIfNeed

        return $d_parameter
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
    public method setUserInput { setup omega }

    ### should be called during setting exposure time
    public method setDetectorModeAndFileExt { mode ext } {
        loadIfNeed
        dict set d_parameter mode $mode
        dict set d_parameter ext  $ext
        set _needWrite 1
    }

    public method getMatrixLog { numFmt txtFmt }

    public method newOrigIsBetter { newOrig }

    public method generateSequenceMap { }

    ### pure BluIce, no need to load or save/write
    public method getHide { } { return $__hide }
    public method setHide { h } {
        set __hide $h
    }

    public method moveCenter { horz vert } {
        if {[getShape] == "crystal"} {
            log_severe moveCenter called for crystal $this
        }
        ### this move is only on the plane of orig
        #### input signs:
        ####     horz:  + right, - left
        ####     vert:  + low,   - upper
        foreach {x0 y0 z0 a0 hMM wMM} $m_imageOrig break
        if {$wMM < 0} {
            set horz [expr -1 * $horz]
        }
        if {$hMM < 0} {
            set vert [expr -1 * $vert]
        }

        loadIfNeed
        puts "grid moveCenter for $this"
        foreach dName {d_geo d_matrix} {
            set cx [dict get [set $dName] center_x]
            set cy [dict get [set $dName] center_y]
            puts "$dName old center $cx $cy"
            set cx [expr $cx + $horz]
            set cy [expr $cy + $vert]
            puts "$dName new center $cx $cy"
            dict set $dName center_x $cx
            dict set $dName center_y $cy
        }
        set _needWrite 1
        puts "done moveCenter"
    }
    public method moveCrystal { dx dy dz }

    #### this is for operation to automatically
    #### change setup according to strategy results.
    #### It just changes start_angle for now.
    #### Interactive one is in RasterCanvas.
    public method acceptStrategy { d_strategy omega }

    public method getStrategyNode { } {
        loadIfNeed
        if {[catch {dict get $d_parameter strategy_enable} enabled]} {
            return -1
        }
        if {$enabled != "1"} {
            return -1
        }

        if {[catch {dict get $d_parameter strategy_node} nodeLabel]} {
            return -1
        }
        if {![string is integer -strict $nodeLabel]} {
            return -1
        }
        set nodeSeq [expr $nodeLabel - 1]
        set num_column  [dict get $d_matrix num_column]
        if {$nodeSeq < 0 || $nodeSeq >= $num_column} {
            return -1
        }
        return $nodeSeq
    }

    public method checkExposure { } {
        set setup [setupExposure "" ""]
        if {$setup != ""} {
            set d_parameter [dict merge $d_parameter $setup]
            puts "merged $setup to d_parameter"
            set _needWrite 1
        }
        return $setup
    }

    ## also should be called on num_column
    public method setupExposure { name value }
    private method setupLCLSExposure { name value }

    #### those add/remove may fill the section list need update to
    #### to reduce calculation.
    public method setHotSpotRowAndColumn { rows columns {sectNeedUpdate all}}
    public method addHotSpotRow { row_ }
    public method addHotSpotColumn { col_ }
    public method removeHotSpotRow { row_ }
    public method removeHotSpotColumn { col_ }

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

    private proc nodeShouldInSequenceHistory { status } {
        set v    [lindex $status 0]
        set char [string index $status 0]
        if {[string is double -strict $v] \
        || $char == "X" \
        || $char == "D" \
        } {
            return 1
        }
        return 0
    }
    private proc nodeShouldInSequence { status } {
        set v    [lindex $status 0]
        set char [string index $status 0]
        switch -exact -- $char {
            N -
            - {
                return 0
            }
            S -
            X -
            D -
            default {
                return 1
            }
        }
    }

    ### private method no need to call loadIfNeed
    private method calculateGridOrig { }
    private method checkNode { }
    private method updateNumbers { }
    private method updateCrystalPhiNumbers { }
    private method decideColumnDirection { lastCol row num_column }
    private method decideRowDirection { lastRow num_column num_row }
    private method generateUserSetupDict { }
    private method checkSequenceHistoryMap { }
    private method generateIndexMap { } {
        set num_row     [dict get $d_matrix num_row]
        set num_column  [dict get $d_matrix num_column]
        set l_index2sequence [string repeat "-1 " [expr $num_row * $num_column]]
        set s 0
        foreach idx $l_sequence2index {
            set l_index2sequence \
            [lreplace $l_index2sequence $idx $idx $s]

            incr s
        }
    }
    private method updateSectionCoords { section hotspots numCol nodeCoordsREF }

    ### these 2 will implement the algorithm.
    ### for now.  it will decide the direction to move and start from
    ### the starting position of that direction.
    ### It may not do the current node first even if the current node
    ### is selected.
    private method generateColumnList { row lastCol num_column }
    private method generateRowList { lastRow num_column num_row }


    private proc generateNumberList { start end step wrap_length } {
        if {$step == 0} {
            return ""
        }
        if {$wrap_length == 0} {
            return ""
        }

        set start       [expr int($start)]
        set end         [expr int($end)]
        set step        [expr int($step)]
        set wrap_length [expr int($wrap_length)]

        set result $start
        set point $start
        while {$point != $end} {
            set point [expr ($point + $step) % $wrap_length]
            lappend result $point
        }
        return $result
    }

    private method loadIfNeed { } {
        if {!$_allLoaded} {
            reload 1
        }
    }
    public method getBeamSize { } {
        loadIfNeed
        set collimator [dict get $d_parameter collimator]
        set use 0
        set index -1
        set bw 2.0
        set bh 2.0
        foreach {use index bw bh} $collimator break
        if {$use == "1"} {
            set bw [expr 1000.0 * $bw]
            set bh [expr 1000.0 * $bh]
        } else {
            set bw [dict get $d_parameter beam_width]
            set bh [dict get $d_parameter beam_height]
        }

        return [list $bw $bh]
    }

    protected method sequenceIsDynamic { } {
        if {[catch {dict get $d_matrix type} seqType]} {
            set seqType horz
        }

        switch -exact -- $seqType {
            default -
            horz -
            fixed_vert_zigzag -
            vert {
                return 0
            }
            zigzag {
                return 1
            }
        }
        return 0
    }

    protected method _setInputWithUpdate { name value omega }
    protected method _updatePhiOscParameterFromSelection { }

    protected method _generateSplitInfo {
        posList nodePosList nodeList frameStartREF omega
    }

    ### not allow to flip if other node following it already collected data.
    public method OKToFlipCrystalNode { index }

    #### geo:
    #### a dict (like struct in C/C++)
    ####    shape, center, angle, half_width, half_height, and local_coords.
    ####
    #### matrix:
    ####    type, center, cell_width, cell_height, num_row, num_column,
    ####    node_label_list(optional)
    ####
    ####        type: horz, vert, zigzag
    ####            horz: left to right and top down.
    ####            vert: top down then right to left.
    ####            zigzag: left to right, then right to left
    ####                    it will change when user selects/unselect nodes.
    ####                    so it is dynamic, not only depend on the shape.
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

    ## currentNodeIndex only changed by sequence and
    ## user click on node list.
    protected variable m_currentNodeIndex -1

    ### a list of index pointing to l_nodeList.
    ### the node status should NOT be "-", "S", or "N".
    ### it should be "D", "X", or a number.
    ### For now, it is only use in scan type ZIGZAG.
    ### For other type, the index of node in sequence is fixed, no change
    ### by the node status.
    ### For ZIGZAG, the position is decided by history of all node status.
    protected variable l_sequenceHistory ""

    ## orig is derived from snapshot orig ,d_matrix and beam center position.
    protected variable _orig ""
    protected variable _beamCenterX 0.5
    protected variable _beamCenterY 0.5

    protected variable _numImageNeed 0
    protected variable _numImageDone 0

    protected variable _numPhiImageNeed 0
    protected variable _numPhiImageDone 0

    ### sequence to node index
    protected variable l_sequence2index [list]
    protected variable l_index2sequence [list]

    ### user setup dictionany: generated from d_geo, d_matrix, and d_parameter
    protected variable _d_userSetup ""

    protected variable __hide 0

    protected common _CALCULATOR ""

    protected common _MAPPING_CALCULATOR ""

    protected common _USERSETUP_NAMELIST \
    [::config getStr "rastering.userSetupNameList"]

    constructor { } {
        if {$_CALCULATOR == ""} {
            set _CALCULATOR [DCS::RunCalculatorForGridCrystal ::#auto]
        }
        ### we will take care of it.
        set _clearNeedAfterWrite    1

        ### you have to put m_id and m_label here.
        ### otherwise, you need to overwide the method accessing them.
        ### which is in base class.
        set _alwaysAvailableVariableList [list m_id m_label m_sortNum]

        set _name4List [list \
        node_position_list \
        node_list_for_phi \
        position_list \
        energy_list \
        local_coords \
        anchor_coords \
        sample_coords \
        section_list \
        hotspot_to_section_map \
        ]

        set _name4Dict [list \
        strategy_info \
        ]
    }
}
body GridGroup::GridBase::getShape { } {
    loadIfNeed
    return [dict get $d_geo shape]
}
body GridGroup::GridBase::getCloneInfo { } {
    loadIfNeed

    set nodeList [list]
    foreach node $l_nodeList {
        switch -exact -- $node {
            - -
            -- -
            NEW -
            N {
                lappend nodeList $node
            }
            default {
                lappend nodeList S
            }
        }
    }
    set myNodeList4Phi [dict get $d_matrix node_list_for_phi]
    set cloneNodeList4Phi [list]
    foreach node $myNodeList4Phi {
        switch -exact -- $node {
            - -
            -- -
            NEW -
            N {
                lappend cloneNodeList4Phi $node
            }
            default {
                lappend cloneNodeList4Phi S
            }
        }

    }
    set clone_matrix $d_matrix
    dict set clone_matrix node_list_for_phi $cloneNodeList4Phi

    set parameters $d_parameter
    dict set parameters next_frame 0
    dict set parameters l_sequenceHistory {}

    return [list $m_imageOrig $d_geo $clone_matrix $nodeList $parameters]
}
body GridGroup::GridBase::getSplitInfoList { } {
    ### we will reset all parameters like they are just created:
    ### no skipped node, no strategy

    puts "getSplitInfoList for $this"

    if {![getIsMegaCrystal]} {
        puts "not a megaCrystal"
        return ""
    }

    set myPositionList    [dict get $d_geo position_list]
    set myPosSegIdxList   [dict get $d_geo segment_index_list]

    set myNodePositionList [dict get $d_matrix node_position_list]
    set myNodeSegIdxList   [dict get $d_matrix node_segment_index_list]

    set llp [llength $myPositionList]
    set lastIdx [lindex $myPosSegIdxList end]
    if {$lastIdx > $llp - 2} {
        log_error segment number not match position number
        log_error numPosition: $llp
        log_error positionList $myPositionList
        log_error segidxlist: $myPosSegIdxList
        return ""
    }

    ### try to derive omega, not ask caller to pass it in.
    set startAngle [dict get $d_parameter start_angle]
    set firstP [lindex $myNodePositionList 0]
    set a0 [lindex $firstP 3]
    set omega [expr $a0 - $startAngle]
    puts "derived omega=$omega"

    ### generate segment list same as GUI GridItemCrystal::_generateSegmentList
    set _positionSegmentList 0
    set ll [llength $myPosSegIdxList]
    for {set i 1} {$i < $ll} {incr i} {
        set nextStart  [lindex $myPosSegIdxList $i]
        set currentEnd [expr $nextStart - 1]
        lappend _positionSegmentList $currentEnd $nextStart
    }
    lappend _positionSegmentList end

    set _nodeSegmentList 0
    set ll [llength $myNodeSegIdxList]
    for {set i 1} {$i < $ll} {incr i} {
        set nextStart  [lindex $myNodeSegIdxList $i]
        set currentEnd [expr $nextStart - 1]
        lappend _nodeSegmentList $currentEnd $nextStart
    }
    lappend _nodeSegmentList end

    set result [list]
    set frameStart [dict get $d_parameter start_frame]
    foreach {pStart pEnd} $_positionSegmentList \
    {nStart nEnd} $_nodeSegmentList {

        set splitPositionList     [lrange $myPositionList $pStart $pEnd]
        set splitNodePositionList [lrange $myNodePositionList $nStart $nEnd]
        set splitNodeList         [lrange $l_nodeList         $nStart $nEnd]

        set splitInfo  [_generateSplitInfo \
        $splitPositionList \
        $splitNodePositionList \
        $splitNodeList \
        $frameStart \
        $omega]

        lappend result $splitInfo
    }
    return $result
}
body GridGroup::GridBase::getForLCLS { } {
    loadIfNeed

    if {[catch {dict get $d_geo for_lcls} forLCLS]} {
        set forLCLS 0
    }

    return $forLCLS
}
body GridGroup::GridBase::getPrefix { } {
    loadIfNeed
    return [dict get $d_parameter prefix]
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

    set shape [dict get $geo shape]
    set m_myTag $shape$m_label

    ## setGeo now needs some parameters to go on.
    set d_parameter $param

    ## no update userInput
    setGeo $snapshotId $orig $geo $matrix $nodes 0

    generateUserSetupDict
    set _needWrite 1
}
body GridGroup::GridBase::setGeo { snapshotId orig geo matrix nodes {update 1}} {
    loadIfNeed

    puts "setGeo"

    if {$snapshotId >= 0} {
        set m_defaultSnapshotId $snapshotId
    }
    set d_geo $geo
    set d_matrix $matrix
    set l_nodeList $nodes
    if {$orig != ""} {
        set m_imageOrig $orig
    }

    updateNumbers
    if {![string first ing $m_status] < 0} {
        if {$_numImageDone == 0} {
            set m_status "setup"
        } elseif {$_numImageNeed == 0} {
            set m_status "complete"
        } else {
            set m_status "paused"
        }
    }

    #puts "cal orig"
    calculateGridOrig

    #puts "if update"
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

    set shape [dict get $d_geo shape]
    if {$shape == "crystal"} {
        if {abs($dx) > 0.001} {
            puts "crystal center not right dx=$dx"
        }
        if {abs($dy) > 0.001} {
            puts "crystal center not right dy=$dy"
        }
        if {abs($dz) > 0.001} {
            puts "crystal center not right dz=$dz"
        }
        set dx 0
        set dy 0
        set dz 0
    }
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
    #puts "updateNumbers"
    set _numImageNeed 0
    set _numImageDone 0

    checkNode

    if {[catch {dict get $d_parameter processing} processingData]} {
        puts "failed to get processing from d_parameter: $processingData"
        set processingData 0

        puts "============d_parameter==========="
        dict for {key value} $d_parameter {
            puts " d_parameter: $key=$value"
        }
        puts "======================"
    }

    foreach node $l_nodeList {
        if {$node == "S"} {
            incr _numImageNeed
        } else {
            set v [lindex $node 0]
            if {[string is double -strict $v]} {
                incr _numImageDone
            } else {
                if {$processingData != "1" && $node == "D"} {
                    incr _numImageDone
                }
            }
        }
    }
    updateCrystalPhiNumbers
    #puts "end of update numbers"
}
body GridGroup::GridBase::updateCrystalPhiNumbers { } {
    set _numPhiImageNeed 0
    set _numPhiImageDone 0

    set shape [dict get $d_geo shape]
    if {$shape != "crystal"} {
        return
    }

    set nodeList4Phi [dict get $d_matrix node_list_for_phi]
    set numPhiPerNode [dict get $d_parameter num_phi_shot]

    foreach node $nodeList4Phi {
        if {[string is integer -strict $node] \
        && $node >= 0 \
        && $node <= $numPhiPerNode} {
            incr _numPhiImageDone $node
            incr _numPhiImageNeed [expr $numPhiPerNode - $node]
        }
    }
    #puts "end of update numbers"
}
body GridGroup::GridBase::decideColumnDirection { lastCol row num_column } {
    set firstSampleCol -1
    set lastSampleCol -1
    for {set col 0} {$col < $num_column} {incr col} {
        set index [expr $row * $num_column + $col]
        set node [lindex $l_nodeList $index]
        switch -exact -- $node {
            S {
                set firstSampleCol $col
                puts "got first=$col"
                break
            }
        }
    }
    if {$firstSampleCol == -1} {
        ### empty row
        puts "skip empty row"
        return [list 0 -1 -1]
    }
    for {set col [expr $num_column - 1]} {$col >= 0} {incr col -1} {
        set index [expr $row * $num_column + $col]
        set node [lindex $l_nodeList $index]
        switch -exact -- $node {
            S {
                set lastSampleCol $col
                puts "got last=$col"
                break
            }
        }
    }
    set colSign 1
    set startCol $firstSampleCol
    set endCol   $lastSampleCol
    if {$firstSampleCol != $lastSampleCol} {
        set distanceFirst [expr abs($firstSampleCol - $lastCol)]
        set distanceLast  [expr abs($lastSampleCol  - $lastCol)]

        if {$distanceFirst <= $distanceLast} {
            #set colSign 1
            #set startCol $firstSampleCol
            #set endCol   $lastSampleCol
        } else {
            set colSign -1
            set startCol $lastSampleCol
            set endCol   $firstSampleCol
        }
    }
    return [list $colSign $startCol $endCol]
}
body GridGroup::GridBase::decideRowDirection { lastRow num_column num_row } {
    set firstSampleRow -1
    set lastSampleRow -1
    for {set row 0} {$row < $num_row} {incr row} {
        for {set col 0} {$col < $num_column} {incr col} {
            set index [expr $row * $num_column + $col]
            set node [lindex $l_nodeList $index]
            switch -exact -- $node {
                S {
                    set firstSampleRow $row
                    puts "got first=$row"
                    break
                }
            }
        }
        if {$firstSampleRow >= 0} {
            break
        }
    }
    if {$firstSampleRow == -1} {
        ### empty matrix
        puts "skip empty matrix"
        return [list 0 -1 -1]
    }
    for {set row [expr $num_row - 1]} {$row >= 0} {incr row -1} {
        for {set col 0} {$col < $num_column} {incr col} {
            set index [expr $row * $num_column + $col]
            set node [lindex $l_nodeList $index]
            switch -exact -- $node {
                S {
                    set lastSampleRow $row
                    puts "got last=$row"
                    break
                }
            }
        }
        if {$lastSampleRow >= 0} {
            break
        }
    }
    set rowSign 1
    set startRow $firstSampleRow
    set endRow   $lastSampleRow
    if {$firstSampleRow != $lastSampleRow} {
        set distanceFirst [expr abs($firstSampleRow - $lastRow)]
        set distanceLast  [expr abs($lastSampleRow  - $lastRow)]

        if {$distanceFirst <= $distanceLast} {
            #set rowSign 1
            #set startRow $firstSampleRow
            #set endRow   $lastSampleRow
        } else {
            set rowSign -1
            set startRow $lastSampleRow
            set endRow   $firstSampleRow
        }
    }
    return [list $rowSign $startRow $endRow]
}
body GridGroup::GridBase::generateSequenceMap { } {
    loadIfNeed

    puts "generateSeqMap"
    set l_sequence2index ""
    set l_index2sequence ""
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
                    lappend l_index2sequence -1
                }
                default {
                    lappend l_sequence2index $i

                    ### s is [llength l_sequence2index]
                    lappend l_index2sequence $s
                    incr s
                }
            }
        }
    } elseif {$seqType == "horz_reverse"} {
        set num_row     [dict get $d_matrix num_row]
        set num_column  [dict get $d_matrix num_column]
        set l_index2sequence [string repeat "-1 " [expr $num_row * $num_column]]
        set s 0
        ##### top down
        for {set row 0} {$row < $num_row} {incr row} {
            #### right to left
            for {set col [expr $num_column -1]} {$col >=0} {incr col -1} {
                set i [expr $row * $num_column + $col]
                set node [lindex $l_nodeList $i]
                switch -exact -- $node {
                    - -
                    -- {
                    }
                    default {
                        lappend l_sequence2index $i
                        set l_index2sequence [lreplace $l_index2sequence $i $i $s]
                        incr s
                    }
                }
            }
        }
    } elseif {$seqType == "vert"} {
        set num_row     [dict get $d_matrix num_row]
        set num_column  [dict get $d_matrix num_column]
        set l_index2sequence [string repeat "-1 " [expr $num_row * $num_column]]
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
                    }
                    default {
                        lappend l_sequence2index $i
                        set l_index2sequence [lreplace $l_index2sequence $i $i $s]
                        incr s
                    }
                }
            }
        }
    } elseif {$seqType == "fixed_vert_zigzag"} {
        puts "seqType==fixed_vert_zigzag"
        #### always start from top left, then zig zag.
        #### it is not dynamic.  A node has fixed position in the sequence.
        set num_row     [dict get $d_matrix num_row]
        set num_column  [dict get $d_matrix num_column]
        set l_index2sequence [string repeat "-1 " [expr $num_row * $num_column]]
        set s 0
        #### right to left
        for {set col [expr $num_column -1]} {$col >=0} {incr col -1} {
            if {($num_column - $col) % 2} {
                for {set row 0} {$row < $num_row} {incr row} {
                    set i [expr $row * $num_column + $col]
                    set node [lindex $l_nodeList $i]
                    switch -exact -- $node {
                        - -
                        -- {
                        }
                        default {
                            lappend l_sequence2index $i
                            set l_index2sequence \
                            [lreplace $l_index2sequence $i $i $s]

                            incr s
                        }
                    }
                }
            } else {
                for {set row [expr $num_row - 1]} {$row >= 0} {incr row -1} {
                    set i [expr $row * $num_column + $col]
                    set node [lindex $l_nodeList $i]
                    switch -exact -- $node {
                        - -
                        -- {
                        }
                        default {
                            lappend l_sequence2index $i
                            set l_index2sequence \
                            [lreplace $l_index2sequence $i $i $s]

                            incr s
                        }
                    }
                }
            }
        }
    } elseif {$seqType == "zigzag"} {
        puts "seqType==zigzag"
        set num_row     [dict get $d_matrix num_row]
        set num_column  [dict get $d_matrix num_column]
        set l_index2sequence [string repeat "-1 " [expr $num_row * $num_column]]

        if {$m_currentNodeIndex < 0 && $l_sequenceHistory != ""} {
            set m_currentNodeIndex [lindex $l_sequenceHistory end]
            puts "DEBUG no current node < 0 but seqHistory=$l_sequenceHistory"
            puts "reset current node to $m_currentNodeIndex"
        }

        ### header, already processed nodes.
        set l_sequence2index $l_sequenceHistory
        set s 0
        foreach index $l_sequence2index {
            set l_index2sequence [lreplace $l_index2sequence $index $index $s]
            incr s
        }
        ### first candidate: current node.
        set lastNode $m_currentNodeIndex
        if {$lastNode < 0} {
            set lastNode [expr $num_row * $num_column - 1]
        }

        ## this is the code to do current node first.
        #set nodeStatus [lindex $l_nodeList $lastNode]
        #if {$nodeStatus == "S"} {
        #    lappend l_sequence2index $lastNode
        #    set l_index2sequence \
        #    [lreplace $l_index2sequence $lastNode $lastNode $s]
        #
        #    incr s
        #}

        set currentRow [expr $lastNode / $num_column]
        set currentCol [expr $lastNode % $num_column]
        set lastCol    $currentCol

        set rowList [generateRowList $currentRow $num_column $num_row]

        if {$rowList == ""} {
            ### all done matrix
            puts "all done seq2idx: $l_sequence2index"
            puts "all done idx2seq: $l_index2sequence"
            return
        }

        foreach row $rowList {
            puts "processnig row=$row"
            set colList [generateColumnList $row $lastCol $num_column]
            foreach col $colList {
                set index [expr $row * $num_column + $col]
                set node [lindex $l_nodeList $index]
                switch -exact -- $node {
                    S {
                        lappend l_sequence2index $index

                        set l_index2sequence \
                        [lreplace $l_index2sequence $index $index $s]

                        incr s

                        set lastCol $col
                    }
                }
            }
        }
    }
    puts "seq2idx: $l_sequence2index"
    puts "idx2seq: $l_index2sequence"

    set _needWrite 1
}
body GridGroup::GridBase::generateColumnList { row lastCol num_column } {
    foreach {colSign startCol endCol} \
    [decideColumnDirection $lastCol $row $num_column] break

    set columnList [generateNumberList $startCol $endCol $colSign $num_column]
    puts "columnList for row=$row {$columnList}"
    return $columnList
}
body GridGroup::GridBase::generateRowList { lastRow num_column num_row } {
    foreach {rowSign startRow endRow} \
    [decideRowDirection $lastRow $num_column $num_row] break

    set rowList [generateNumberList $startRow $endRow $rowSign $num_row]

    ### move currentRow to first.
    #set index [lsearch -exact $rowList $currentRow]
    #if {$index > 0} {
    #    set rowList [lreplace $rowList $index $index]
    #    set rowList [linsert  $rowList 0 $currentRow]
    #}

    puts "rowList: {$rowList}"
    return $rowList
}

body GridGroup::GridBase::checkSequenceHistoryMap { } {
    puts "checkSequenceHistoryMap"
    if {$l_sequenceHistory == ""} {
        return
    }

    ### add missed
    set i -1
    foreach node $l_nodeList {
        incr i
        if {[nodeShouldInSequenceHistory $node] \
        && [lsearch -exact $l_sequenceHistory $i] < 0} {
            lappend l_sequenceHistory $i
            log_warning node $i appended to sequenceDoneList \
            its status=$node
        }
    }

    ### remove resetted.
    set newList ""
    set anyChange 0
    foreach index $l_sequenceHistory {
        set node [lindex $l_nodeList $index]
        if {[nodeShouldInSequenceHistory $node]} {
            lappend newList $index
        } else {
            ## skip
            incr anyChange
        }
    }
    if {$anyChange} {
        set l_sequenceHistory $newList
    }
}
body GridGroup::GridBase::generateUserSetupDict { } {
    #puts "calling generateUserSetupDict for $this"
    #### non-graphic setup: can change without the graph
    set _d_userSetup $d_parameter

    set shape [dict get $d_geo shape]

    switch -exact -- $shape {
        crystal {
            set nname crystal
        }
        projective -
        trap_array -
        mesh -
        l614 {
            set nname grid
        }
        default {
            set nname raster
        }
    }

    set sumMsg "$nname $m_label $m_status"

    if {![catch {dict get $d_parameter strategy_info} stgInfo] \
    &&  ![catch {dict get $stgInfo top_dir} topDir] \
    &&  ![catch {dict get $stgInfo part_num} partId]} {
        set tail [file tail $topDir]
        append sumMsg " (strategy: $tail $partId)"
    }

    dict set _d_userSetup summary $sumMsg
    foreach name $_USERSETUP_NAMELIST {
        switch -exact -- $name {
            shape -
            for_lcls -
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
                    set v [expr abs(2.0 * $v)]
                }
            }
            item_height {
                if {[catch {dict get $d_geo half_height} v]} {
                    puts "not fully populated yet: half_height"
                    set v 0
                } else {
                    set v [expr abs(2.0 * $v)]
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
            num_column -
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
            mode -
            distance -
            delta -
            time -
            use_phi_offset -
            phi_offset -
            start_frame -
            start_angle -
            end_frame -
            end_angle -
            node_frame -
            node_angle -
            first_attenuation -
            end_attenuation -
            attenuation {
                if {[catch {dict get $d_parameter $name} v]} {
                    puts "not fully populated yet: $name"
                    set v 0
                } else {
                    ###already copied to it from d_parameter
                    continue
                }
            }
            first_single_shot -
            second_single_shot -
            end_single_shot -
            video_snapshot -
            num_phi_shot -
            processing {
                if {[catch {dict get $d_parameter $name} v]} {
                    puts "not fully populated yet: $name"
                    set v 1
                } else {
                    ###already copied to it from d_parameter
                    continue
                }
            }
            strategy_info {
                if {[catch {dict get $d_parameter $name} v]} {
                    puts "not fully populated yet: $name"
                    set v ""
                } else {
                    ###already copied to it from d_parameter
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
body GridGroup::GridBase::setUserInput { setup omega } {
    set ll [llength $setup]
    #puts "$this setUserInput ll=$ll"
    if {$ll % 2} {
        log_error bad user setup, odd length
        puts "bad user setup: {$setup}"
        return -code error BAD_INPUT
    }

    loadIfNeed

    set needUpdateGraph 0
    set bigChange 0

    dict for {name value} $setup {
        switch -exact -- $name {
            center_x -
            center_y {
                set old_v [dict get $d_geo $name]
                dict set d_geo $name $value
                if {abs($old_v - $value) > 0.1} {
                    set needUpdateGraph 1
                }
            }
            item_width {
                set old_v [dict get $d_geo half_width]
                set v [expr abs($value / 2.0)]
                if {$old_v < 0} {
                    set v [expr -1 * $v]
                }
                dict set d_geo half_width $v
                if {abs($old_v - $v) > 0.1} {
                    set needUpdateGraph 1
                }
            }
            item_height {
                set old_v [dict get $d_geo half_height]
                set v [expr abs($value / 2.0)]
                if {$old_v < 0} {
                    set v [expr -1 * $v]
                }
                dict set d_geo half_height $v
                if {abs($old_v - $v) > 0.1} {
                    set needUpdateGraph 1
                }
            }
            angle {
                set old_v [dict get $d_geo $name]
                set v [expr $value * 3.1415926 / 180.0]
                dict set d_geo $name $v
                if {abs($old_v - $v) > 0.001} {
                    set needUpdateGraph 1
                }
            }
            cell_width -
            cell_height {
                set old_v [dict get $d_matrix $name]
                dict set d_matrix $name $value
                if {abs($old_v - $value) > 0.1} {
                    set needUpdateGraph 1
                    ### in fact, these two are so important, they belong to
                    ### modifyGrid.  They code should never pass here.
                    puts "DEBUG_ERROR: cell size changed via parameters"
                }
            }
            prefix -
            directory -
            collimator {
                set old_v [dict get $d_parameter $name]
                dict set d_parameter $name $value
            }
            beam_width -
            beam_height -
            beam_stop -
            mode -
            distance -
            time -
            attenuation -
            processing {
                if {[catch {dict get $d_parameter $name} old_v]} {
                    set old_v 0
                }
                dict set d_parameter $name $value
                if {abs($old_v - $value) > 0.001} {
                }
            }
            wedge_size -
            delta -
            start_frame -
            start_angle -
            end_frame -
            end_angle -
            node_frame -
            node_angle -
            strategy_enable -
            strategy_node {
                foreach {paramChange gridChange} \
                [_setInputWithUpdate $name $value $omega] break
                if {$paramChange} {
                    incr bigChange
                }
                if {$gridChange} {
                    set needUpdateGraph 1
                }
            }
            shape {
                ### cannot update shape
                continue
            }
            default {
                if {[catch {dict get $d_parameter $name} old_v]} {
                    set old_v 0
                }
                dict set d_parameter $name $value
            }
        }
    }
    generateUserSetupDict
    set _needWrite 1
    return [list $bigChange $needUpdateGraph]
}
body GridGroup::GridBase::_setInputWithUpdate { name value omega } {
    puts "setInputWidthUpdate $name $value"

    set shape [dict get $d_geo shape]
    if {$shape != "crystal"} {
        dict set d_parameter $name $value
        return [list 0 0]
    }

    if {$omega == "direct"} {
        dict set d_parameter $name $value
        return [list 0 0]
    }

    if {[catch {dict get $d_geo for_lcls} forLCLS]} {
        set forLCLS 0
    }

    set bigChange 0
    set needUpdateGraph 0

    ## simple one.
    if {$forLCLS} {
        switch -exact -- $name {
            delta -
            start_frame -
            end_frame -
            node_frame {
                ### nothing special for these
                if {[catch {dict get $d_parameter $name} old_v]} {
                    set old_v 0
                }
                dict set d_parameter $name $value
                if {abs($old_v - $value) > 0.001} {
                }
                return [list 0 0]
            }
        }
    }

    if {[catch {dict get $d_parameter $name} old_v]} {
        set old_v 0
    }
    dict set d_parameter $name $value

    ### most complicated ones:
    set nodeList4Phi [dict get $d_matrix node_list_for_phi]
    if {$name == "strategy_enable"} {
        if {$value == "1"} {
            if {[catch {dict get $d_parameter strategy_node} oldSeq] \
            || $oldSeq != "1"} {
                set oldSeq 1
                dict set d_parameter strategy_node $oldSeq
                incr bigChange
            }
            set index [sequence2index 0]
            set status [lindex $l_nodeList $index]
            set phiStatus [lindex $nodeList4Phi $index]
            if {$status == "S"} {
                set l_nodeList [lreplace $l_nodeList $index $index "N"]
                set needUpdateGraph 1
            }
            if {$phiStatus != "N"} {
                set nodeList4Phi [lreplace $nodeList4Phi $index $index "N"]
                dict set d_matrix node_list_for_phi $nodeList4Phi
                _updatePhiOscParameterFromSelection
                set needUpdateGraph 1
            }
        } else {
            if {[catch {dict get $d_parameter strategy_node} oldSeq]} {
                return [list 1 0]
            }
            if {![string is integer -strict $oldSeq] || $oldSeq <= 0} {
                return [list 1 0]
            }
            ### label to sequence
            incr oldSeq -1

            set index [sequence2index $oldSeq]
            set status [lindex $l_nodeList $index]
            set phiStatus [lindex $nodeList4Phi $index]
            if {$status == "N" && $phiStatus == "N"} {
                set l_nodeList [lreplace $l_nodeList $index $index "S"]
                set needUpdateGraph 1
            }
        }
    } elseif {$name == "strategy_node"} {
        if {[catch {dict get $d_parameter strategy_enable} enabled] \
        || $enabled != "1"} {
            return [list 0 0]
        }
        set oldSeq $old_v
        incr oldSeq -1
        if {$oldSeq >= 0} {
            set index [sequence2index $oldSeq]
            set status    [lindex $l_nodeList $index]
            set phiStatus [lindex $nodeList4Phi $index]
            if {$status == "N" && $phiStatus == "N"} {
                set l_nodeList [lreplace $l_nodeList $index $index "S"]
                set needUpdateGraph 1
            }
        }
        ## new
        set newSeq [expr $value - 1]
        set index [sequence2index $newSeq]
        set status    [lindex $l_nodeList   $index]
        set phiStatus [lindex $nodeList4Phi $index]
        if {$status == "S"} {
            set l_nodeList [lreplace $l_nodeList $index $index "N"]
            set needUpdateGraph 1
        }
        if {$phiStatus != "N"} {
            set nodeList4Phi [lreplace $nodeList4Phi $index $index "N"]
            dict set d_matrix node_list_for_phi $nodeList4Phi
            _updatePhiOscParameterFromSelection
            set needUpdateGraph 1
        }
    }
    updateNumbers
    set currentStatus [getStatus]
    if {![string first ing $currentStatus] < 0} {
        if {$_numImageDone == 0} {
            set needUpdateStatus [setStatus "setup"]
        } elseif {$_numImageNeed == 0} {
            set needUpdateStatus [setStatus "complete"]
        } else {
            set needUpdateStatus [setStatus "paused"]
        }
    }

    ### need to change exposure, node angle but not select/unslect node:
    updateAfterCrystalNodeFlip $omega $name $value
    return [list 1 1]
}
body GridGroup::GridBase::validUserInput { name valueREF } {
    upvar $valueREF value
    loadIfNeed
    set shape [dict get $d_geo shape]

    switch -exact -- $name {
        cell_width {
            foreach {bw bh} [getBeamSize] break

            if {$value < 0.5 * $bw} {
                log_warning cell_width is less than a half of beam width
            } elseif {$value > 2 * $bw} {
                log_warning cell_width is greater than twice of beam width
            }
            set w [dict get $d_geo size_width]

            set aboutNumCol [expr int(abs($w / $value))]
            puts "w=$w step=$value aboutNumCol=$aboutNumCol"
            if {$w > 0 && $aboutNumCol < 1 && $shape != "line"} {
                log_error cell_width too big for this shape.
                set value [expr ceil(abs($w / 3.0))]
                log_error trying $value
            }
        }
        cell_height {
            foreach {bw bh} [getBeamSize] break

            if {$value < 0.5 * $bh} {
                log_warning cell_height is less than a half of beam height
            } elseif {$value > 2 * $bh} {
                log_warning cell_height is greater than twice of beam height
            }
            set h [dict get $d_geo size_height]
            set aboutNumRow [expr int(abs($h / $value))]
            puts "aboutNumRow=$aboutNumRow"
            if {$aboutNumRow < 1 && $shape != "line"} {
                log_error cell_height too big for this shape.
                set value [expr ceil(abs($h / 3.0))]
                log_error trying $value
            }
        }
    }
    return 1
}
body GridGroup::GridBase::setupExposure { name_ value_ } {
    loadIfNeed

    if {[catch {dict get $d_geo for_lcls} forLCLS]} {
        set forLCLS 0
    }

    if {$forLCLS} {
        return [setupLCLSExposure $name_ $value_]
    }

    puts "setupExposure $name_ $value_"

    set result [dict create]

    if {[catch {dict get $d_parameter wedge_size} wedgeSize]} {
        set wedgeSize 180.0
    }

    if {[catch {dict get $d_parameter delta} delta] || $delta <= 0} {
        set delta 1.0
        dict set result delta $delta
    }

    if {[catch {dict get $d_parameter start_frame} startFrame] \
    || $startFrame < 1} {
        set startFrame 1
        dict set result start_frame $startFrame
    }
    if {[catch {dict get $d_parameter start_angle} startAngle]} {
        set startAngle 0.0
        dict set result start_angle $startAngle
    }
    if {[catch {dict get $d_parameter end_frame} endFrame] \
    || $endFrame < $startFrame} {
        set endFrame $startFrame
        dict set result end_frame $endFrame
    }
    set endAngleExpect \
    [expr $startAngle + $delta * ($endFrame - $startFrame + 1)]

    puts "expected endAngle: $endAngleExpect"
    if {[catch {dict get $d_parameter end_angle} endAngle] \
    || $endAngle != $endAngleExpect} {
        set endAngle $endAngleExpect
        dict set result end_angle $endAngle
    }
    ### try to support skipped nodes.
    #set numNode [dict get $d_matrix num_column]
    set numNode 0
    foreach node $l_nodeList {
        set first [lindex $node 0]
        set fChar [string index $first 0]
        if {$fChar == "S" || [string is double -strict $first]} {
            incr numNode
        }
    }
    if {$numNode < 1} {
        set numNode 1
    }
    set nn [expr int(ceil(double($endFrame - $startFrame + 1) / $numNode))]
    if {[catch {dict get $d_parameter node_frame} nNum] || $nNum != $nn} {
        dict set result node_frame $nn
        set nNum $nn
    }
    set na [expr $nn * $delta]
    if {[catch {dict get $d_parameter node_angle} nodeAngle] \
    || $nodeAngle != $na} {
        dict set result node_angle $na
        set nodeAngle $na
    }

    switch -exact -- $name_ {
        wedge_size {
            if {abs($value_) > abs($nodeAngle)} {
                set value_ [expr abs($nodeAngle)]
                log_warning max wedge is node angle
            }
        }
        delta {
            if {$value_ <= 0} {
                set value_ 1.0
            }
            set endAngle \
            [expr $startAngle + $value_ * ($endFrame - $startFrame + 1)]
            dict set result end_angle $endAngle

            set nodeAngle [expr $nNum * $value_]
            dict set result node_angle $nodeAngle
        }
        start_frame {
            if {$value_ < 1} {
                set value_ 1
            }
            if {$endFrame < $value_} {
                set endFrame $value_
                dict set result end_frame $endFrame
            }
            set endAngle [expr $startAngle + $delta * ($endFrame - $value_ + 1)]
            dict set result end_angle $endAngle
            set nn [expr int(ceil(double($endFrame - $value_ + 1) / $numNode))]
            dict set result node_frame $nn
            set nodeAngle [expr $nn * $delta]
            dict set result node_angle $nodeAngle
            dict set result wedge_size [expr abs($nodeAngle)]
            log_warning wedge resetted to node angle
        }
        start_angle {
            set endAngle [expr $value_ + $delta * ($endFrame - $startFrame + 1)]
            dict set result end_angle $endAngle
        }
        end_frame {
            if {$value_ < $startFrame} {
                set value_ $startFrame
            }
            set endAngle [expr $startAngle + $delta * ($value_ - $startFrame + 1)]
            dict set result end_angle $endAngle
            set nn \
            [expr int(ceil(double($value_ - $startFrame + 1) / $numNode))]

            dict set result node_frame $nn

            set nodeAngle [expr $nn * $delta]
            dict set result node_angle $nodeAngle
            dict set result wedge_size [expr abs($nodeAngle)]
            log_warning wedge resetted to node angle
        }
        end_angle {
            if {$value_ < $startAngle} {
                set value_ $startAngle
            }
            set n [expr int(ceil(($value_ - $startAngle) / $delta))]

            set endFrame [expr $startFrame + $n - 1]
            dict set result end_frame $endFrame
            set nn [expr int(ceil(double($n + 1) / $numNode))]
            dict set result node_frame $nn
            set nodeAngle [expr $nn * $delta]
            dict set result node_angle $nodeAngle
            dict set result wedge_size [expr abs($nodeAngle)]
            log_warning wedge resetted to node angle

            set value_ [expr $startAngle + $delta * $n]
        }
        node_frame {
            set value_ [expr int($value_)]
            if {$value_ < 1} {
                set value_ 1
            }
            set n [expr int($value_ * $numNode)]
            set endFrame [expr $startFrame + $n - 1]
            set endAngle [expr $startAngle + $delta * $n]
            set nodeAngle [expr $value_ * $delta]
            dict set result end_frame $endFrame
            dict set result end_angle $endAngle
            dict set result node_angle $nodeAngle
            dict set result wedge_size [expr abs($nodeAngle)]
            log_warning wedge resetted to node angle
        }
        node_angle {
            if {$value_ <= 0} {
                set value_ 1.0
            }
            if {$delta == 0} {
                set nodeFrame 1
            } else {
                set nodeFrame [expr int($value_ / $delta)]
            }
            if {$nodeFrame < 1} {
                set nodeFrame 1
            }
            set newValue [expr $delta * $nodeFrame]
            if {abs($value_ - $newValue) > 0.001} {
                log_warning phi per node changed to $newValue by delta.
                set value_ $newValue
            }
            set n [expr int($nodeFrame * $numNode)]
            set endFrame [expr $startFrame + $n - 1]
            set endAngle [expr $startAngle + $delta * $n]
            dict set result end_frame $endFrame
            dict set result end_angle $endAngle
            dict set result node_frame $nodeFrame
            dict set result wedge_size [expr abs($value_)]
            log_warning wedge resetted to node angle
        }
    }
    if {$name_ != ""} {
        dict set result $name_ $value_
    }

    puts "setupExposure result=$result"
    return $result
}
body GridGroup::GridBase::setupLCLSExposure { name_ value_ } {
    puts "setupLCLSExposure $name_ $value_"

    set result [dict create]

    if {[catch {dict get $d_parameter start_angle} startAngle]} {
        set startAngle 0.0
        dict set result start_angle $startAngle
    }

    if {[catch {dict get $d_parameter node_angle} nodeAngle]} {
        set nodeAngle 1.0
        dict set result node_angle $nodeAngle
    }

    ### try to support skipped nodes.
    #set numNode [dict get $d_matrix num_column]
    set numNode 0
    foreach node $l_nodeList {
        set first [lindex $node 0]
        set fChar [string index $first 0]
        if {$fChar == "S" || [string is double -strict $first]} {
            incr numNode
        }
    }

    if {$numNode < 1} {
        set numNode 1
    }

    ## this end angle is the last position angle.
    set endAngleExpect [expr $startAngle + $nodeAngle * ($numNode - 1)]

    puts "expected endAngle: $endAngleExpect"
    if {[catch {dict get $d_parameter end_angle} endAngle] \
    || $endAngle != $endAngleExpect} {
        set endAngle $endAngleExpect
        dict set result end_angle $endAngle
    }

    switch -exact -- $name_ {
        start_angle {
            set endAngle [expr $value_ + $nodeAngle * ($numNode - 1)]
            dict set result end_angle $endAngle
        }
        end_angle {
            if {$value_ < $startAngle} {
                set value_ $startAngle
            }
            if {$numNode < 2} {
                set value_ $startAngle
                set nodeAngle 0.0
            } else {
                set nodeAngle \
                [expr double($value_ - $startAngle) / ($numNode - 1)]
            }
            dict set result node_angle $nodeAngle
        }
        node_angle {
            if {$value_ < 0.0} {
                set value_ 0.0
            }
            set endAngle [expr $startAngle + $value_ * ($numNode - 1)]
            dict set result end_angle $endAngle
        }
    }
    if {$name_ != ""} {
        dict set result $name_ $value_
    }

    puts "setupLCLSExposure result=$result"
    return $result
}
body GridGroup::GridBase::sequence2index { seq } {
    loadIfNeed

    set ll [llength $l_sequence2index]
    if {$seq < 0 || $seq >= $ll} {
        log_error bad sequence: $seq
        puts " bad sequence: $seq ll=$ll"
        return -1
    }
    return [lindex $l_sequence2index $seq]
}
body GridGroup::GridBase::setSequenceList { seq2idx_ idx2seq_ } {
    loadIfNeed

    if {$l_sequence2index == $seq2idx_ && $l_index2sequence == $idx2seq_} {
        puts "all the same skip"
        return 0
    }
    set l_sequence2index $seq2idx_
    set l_index2sequence $idx2seq_
    set _needWrite 1
    return 1
}
body GridGroup::GridBase::getNextFrame { } {
    loadIfNeed
    set shape [dict get $d_geo shape]
    if {$shape != "crystal"} {
        puts "call getNextFrame for non-crystal"
        return -1
    }
    if {[catch {dict get $d_parameter next_frame} currentValue]} {
        return 0
    }
    return $currentValue
}
body GridGroup::GridBase::setNextFrame { nextFrame } {
    loadIfNeed
    set shape [dict get $d_geo shape]

    if {$shape != "crystal"} {
        puts "call setNextFrame for non-crystal"
        return 0
    }

    if {![catch {dict get $d_parameter next_frame} currentValue] \
    && $nextFrame == $currentValue} {
        return 0
    }

    dict set d_parameter next_frame $nextFrame

    set _needWrite 1
    return 1
}
body GridGroup::GridBase::setNodeStatus { index status {current 0} } {
    puts "setNodeStatus $index {$status}"
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

    set first [lindex $status 0]

    if {($first == "D" || [string is double -strict $first]) \
    && $index == $m_currentNodeIndex \
    && [lsearch -exact $l_sequenceHistory $index] < 0} {
        ### add to history
        lappend l_sequenceHistory $index
        set _needWrite 1
    }

    if {$status == ""} {
        set status $currentStatus
    }
    if {$currentStatus == $status} {
        if {!$current || $m_currentNodeIndex == $index} {
            return 0
        }
    } else {
        set l_nodeList [lreplace $l_nodeList $index $index $status]
        updateNumbers
    }

    if {$current} {
        set m_currentNodeIndex $index
    }

    set _needWrite 1
    return 1
}
body GridGroup::GridBase::setPhiNodeStatus { index status } {
    puts "setPhiNodeStatus $index {$status}"
    loadIfNeed

    set nodeList4Phi [dict get $d_matrix node_list_for_phi]

    set ll [llength $nodeList4Phi]
    if {$index < 0 || $index >= $ll} {
        log_warning index $index out of range
        return 0
    }
    set currentStatus [lindex $nodeList4Phi $index]

    if {$status == ""} {
        set status $currentStatus
    }
    if {$currentStatus == $status} {
        return 0
    } else {
        set nodeList4Phi [lreplace $nodeList4Phi $index $index $status]
        dict set d_matrix node_list_for_phi $nodeList4Phi
        updateNumbers
    }

    set _needWrite 1
    return 1
}
body GridGroup::GridBase::setCurrentNodeStatus { index status } {
    return [setNodeStatus $index $status 1]
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
body GridGroup::GridBase::setAllPhiNodes { nList } {
    loadIfNeed

    set node4PhiList [dict get $d_matrix node_list_for_phi]

    set l1 [llength $node4PhiList]
    set l2 [llength $nList]
    if {$l1 != $l2} {
        log_error setAllPhiNodes with different length = $l2 != nodeList = $l1
        return 0
    }
    if {$node4PhiList == $nList} {
        return 0
    }
    dict set d_matrix node_list_for_phi $nList
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
            NEW -
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
    set seqHistoryChange 0
    if {$newNodeList != $l_nodeList} {
        set l_nodeList $newNodeList
        updateNumbers
        set nodeListChange 1
    }
    if {$l_sequenceHistory != ""} {
        set l_sequenceHistory ""
        set seqHistoryChange 1
    }

    if {$statusChange || $nodeListChange || $seqHistoryChange} {
        set _needWrite 1
    }
    ## this may set _needWrite to 1
    set frameChange [setNextFrame 0]

    set nodeListChange [expr $nodeListChange || $frameChange]

    return [list $statusChange $nodeListChange]
}
body GridGroup::GridBase::resetPhiOsc { } {
    loadIfNeed

    if {[dict get $d_geo shape] != "crystal" \
    || [dict get $d_geo for_lcls] != "1"} {
        return [list 0 0]
    }

    set nodeList4Phi [dict get $d_matrix node_list_for_phi]
    set ll [llength $nodeList4Phi]
    set newNodeList4ForPhi ""
    foreach node $nodeList4Phi {
        switch -exact -- $node {
            - -
            -- -
            N {
                ### no change
                lappend newNodeList $node
            }
            default {
                lappend newNodeList 0
            }
        }
    }
    set strategySeq [getStrategyNode]
    if {$strategySeq >= 0 && $strategySeq < $ll} {
        set strategyIdx [sequence2index $strategySeq]
        if {$strategyIdx >= 0 && $strategyIdx < $ll} {
            set idx $strategyIdx
            set newNodeList [lreplace $newNodeList $idx $idx N]
        }
    }

    set nodeListChange 0
    if {$newNodeList != $nodeList4Phi} {
        dict set d_matrix node_list_for_phi $newNodeList
        updateNumbers
        set nodeListChange 1
    }

    if {$nodeListChange} {
        set _needWrite 1
    }

    return [list 0 $nodeListChange]
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
body GridGroup::GridBase::getNodeRowAndColumn { index } {
    loadIfNeed

    set num_column  [dict get $d_matrix num_column]

    set row [expr $index / $num_column]
    set col [expr $index % $num_column]

    return [list $row $col]
}
body GridGroup::GridBase::getNodeIndex { row column } {
    loadIfNeed

    set num_row     [dict get $d_matrix num_row]
    set num_column  [dict get $d_matrix num_column]

    if {$column == "middle"} {
        set column [expr $num_column / 2]
    } elseif {$column == "end"} {
        set column [expr $num_column - 1]
    }

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
        return ""
    }
    if {[nodeShouldInSequenceHistory $currentStatus]} {
        log_warning no flip for node already done.
        return ""
    }
    ## so we know that the flip will not affect the l_sequenceHistory

    set cur0 [string index $currentStatus 0]
    if {$cur0 == "S"} {
        set newStatus "N"
        #set newStatus "NEW"

    } else {
        set newStatus "S"
    }

    set needUpdateWholeList 0
    set needUpdateStatus 0
    set needUpdateSequence 0

    set oldList $l_nodeList
    if {$currentStatus == "NEW"} {
        set l_nodeList [string map {NEW S} $l_nodeList]
    } else {
        set l_nodeList [string map {NEW N} $l_nodeList]
    }
    if {$l_nodeList != $oldList} {
        set needUpdateWholeList 1
    }
    set l_nodeList [lreplace $l_nodeList $index $index $newStatus]

    updateNumbers
    if {[sequenceIsDynamic]} {
        set needUpdateSequence 1
        if {$newStatus == "S"} {
            if {[lsearch -exac $l_sequence2index $index] < 0} {
                lappend l_sequence2index $index
            }
        } else {
            set seq [lindex $l_index2sequence $index]
            if {$seq >= 0} {
                set l_sequence2index \
                [lreplace $l_sequence2index $seq $seq]
            }
        }
        generateIndexMap
    }

    set currentStatus [getStatus]
    if {![string first ing $currentStatus] < 0} {
        if {$_numImageDone == 0} {
            set needUpdateStatus [setStatus "setup"]
        } elseif {$_numImageNeed == 0} {
            set needUpdateStatus [setStatus "complete"]
        } else {
            set needUpdateStatus [setStatus "paused"]
        }
    }

    set _needWrite 1
    return [list $needUpdateStatus $needUpdateWholeList $needUpdateSequence]
}
## this only can be called after some change.
body GridGroup::GridBase::updateAfterCrystalNodeFlip { \
    omega {name ""} {value ""} \
} {
    loadIfNeed

    ### we need to adjust exposure setup
    ### this will also make sure node_angle got updated.
    set setup [setupExposure $name $value]
    if {$setup != ""} {
        set d_parameter [dict merge $d_parameter $setup]
        puts "merged $setup to d_parameter"
    }

    ### we need to adjust phi for nodes.
    ### This is almost the same as regenerateOrig in the GUI.
    ### for LCLS, node_angle is a primary parameter.
    ### for SSLR, node_angle is derived from other setup.
    set phiPerNode [dict get $d_parameter node_angle]
    set startPhi   [dict get $d_parameter start_angle]
    set startAngle [expr $startPhi + $omega]

    set nodePositionList [dict get $d_matrix node_position_list]
    set newNPList [list]
    set angle $startAngle
    foreach index $l_sequence2index {
        set nodePos [lindex $nodePositionList $index]
        lappend newNPList [lreplace $nodePos 3 3 $angle]
        puts "node $index $nodePos angle changed to $angle"

        set nodeStatus [lindex $l_nodeList $index]
        set first [lindex $nodeStatus 0]
        set firstChar [string index $first 0]
        ### may change to ! "N", we know there is no "-" in vector.
        if {$firstChar == "S" \
        ||  $firstChar == "X" \
        ||  $firstChar == "D" \
        || [string is double -strict $first]} {
            set angle [expr $angle + $phiPerNode]
        }
    }

    dict set d_matrix node_position_list $newNPList

    set _needWrite 1

    return $setup
}
body GridGroup::GridBase::flipCrystalPhiNode { index } {
    loadIfNeed

    ### in fact, for crystal, this should never happen.
    ### no harm, so just leave the code here to check.
    set currentStatus [lindex $l_nodeList $index]
    if {$currentStatus == "--" || $currentStatus == "-"} {
        log_warning that node is marked as not_exists
        return [list 0 1]
    }

    if {[catch {dict get $d_parameter strategy_enable} stgEnabled]} {
        set stgEnabled 0
    }
    if {[catch {dict get $d_parameter strategy_node} stgNode]} {
        set stgNode 0
    }
    if {$stgEnabled == "1" \
    && [string is integer -strict $stgNode] \
    && $stgNode > 0} {
        set stgNodeIdx [sequence2index [expr $stgNode - 1]]
        if {$stgNodeIdx == $index} {
            log_error cannot flip strategy node
            return [list 0 1]
        }
    }

    set numPhiPerNode [dict get $d_parameter num_phi_shot]
    set nodeList4Phi  [dict get $d_matrix node_list_for_phi]
    set cur [lindex $nodeList4Phi $index]

    if {[string is integer -strict $cur] && $cur >= $numPhiPerNode} {
        log_warning this node already done phi oscillation.
        return [list 0 1]
    }

    switch -exact -- $cur {
        N {
            set newStatus 0
        }
        default {
            set newStatus N
        }
    }
    set nodeList4Phi [lreplace $nodeList4Phi $index $index $newStatus]
    dict set d_matrix node_list_for_phi $nodeList4Phi

    updateNumbers

    set needUpdateStatus 0

    set needUpdateParam [_updatePhiOscParameterFromSelection]

    set _needWrite 1
    return [list $needUpdateStatus $needUpdateParam]
}
body GridGroup::GridBase::setCrystalAllPhiNode { value } {
    puts "setCrystalAllPhiNode value=$value"
    loadIfNeed

    if {[catch {dict get $d_parameter strategy_enable} stgEnabled]} {
        set stgEnabled 0
    }
    if {[catch {dict get $d_parameter strategy_node} stgNode]} {
        set stgNode 0
    }
    set stgNodeIdx -1
    if {$stgEnabled == "1" \
    && [string is integer -strict $stgNode] \
    && $stgNode > 0} {
        set stgNodeIdx [sequence2index [expr $stgNode - 1]]
    }

    set numPhiPerNode [dict get $d_parameter num_phi_shot]
    set nodeList4Phi  [dict get $d_matrix node_list_for_phi]

    set newList [list]
    set idx -1
    foreach node $nodeList4Phi {
        incr idx
        if {$idx == $stgNodeIdx || $node == "-" || $node == "--"} {
            set newNode $node
        } elseif {[string is integer -strict $node] && $node >= $numPhiPerNode} {
            log_warning this node already done phi oscillation.
            set newNode $node
        } else {
            if {$value == "1"} {
                set newNode 0
            } else {
                set newNode N
            }
        }
        lappend newList $newNode
    }
    puts "old list $nodeList4Phi"
    puts "new list $newList"

    dict set d_matrix node_list_for_phi $newList

    updateNumbers

    set needUpdateStatus 0

    set needUpdateParam [_updatePhiOscParameterFromSelection]

    set _needWrite 1
    return [list $needUpdateStatus $needUpdateParam]
}
body GridGroup::GridBase::OKToFlipCrystalNode { index_ } {
    loadIfNeed

    set ll  [llength $l_sequence2index]
    if {$index_ < 0 || $index_ >= $ll} {
        return 0
    }
    set seq [lindex $l_index2sequence $index_]
    set leftSeq [lrange $l_sequence2index $seq end]

    foreach idx $leftSeq {
        set node [lindex $l_nodeList $idx]
        switch -exact -- $node {
            -- -
            - -
            S -
            N {
            }
            default {
                log_error some node after it already got data.
                return 0
            }
        }
    }
    return 1
}
body GridGroup::GridBase::_updatePhiOscParameterFromSelection { } {
    set nodeList4Phi [dict get $d_matrix node_list_for_phi]

    set ll [llength $nodeList4Phi]
    set strategyIdx -1
    set strategySeq [getStrategyNode]
    if {$strategySeq >= 0 && $strategySeq < $ll} {
        set strategyIdx [sequence2index $strategySeq]
    }

    set num_node [llength $nodeList4Phi]
    set seqEnd [expr $num_node - 1]
    set seqMid [expr $num_node / 2]

    set idxEnd [sequence2index $seqEnd]
    set idxMid [sequence2index $seqMid]

    set statusEnd [lindex $nodeList4Phi $idxEnd]
    set statusMid [lindex $nodeList4Phi $idxMid]

    set statusAll S
    set idx -1
    foreach node $nodeList4Phi {
        incr idx
        if {$idx == $strategyIdx} {
            continue
        }
        if {$node == "N"} {
            set statusAll "N"
            break
        }
    }

    set oldEnd [dict get $d_parameter phi_osc_end]
    set oldMid [dict get $d_parameter phi_osc_middle]
    set oldAll [dict get $d_parameter phi_osc_all]

    set anyChange 0

    if {$oldEnd} {
        if {$statusEnd == "N"} {
            dict set d_parameter phi_osc_end 0
            incr anyChange
        }
    } else {
        if {$statusEnd != "N"} {
            dict set d_parameter phi_osc_end 1
            incr anyChange
        }
    }
    if {$oldMid} {
        if {$statusMid == "N"} {
            dict set d_parameter phi_osc_middle 0
            incr anyChange
        }
    } else {
        if {$statusMid != "N"} {
            dict set d_parameter phi_osc_middle 1
            incr anyChange
        }
    }
    if {$oldAll} {
        if {$statusAll == "N"} {
            dict set d_parameter phi_osc_all 0
            incr anyChange
        }
    } else {
        if {$statusAll != "N"} {
            dict set d_parameter phi_osc_all 1
            incr anyChange
        }
    }
    return $anyChange
}
body GridGroup::GridBase::getParamForFlipCrystalPhiNodeUpdate { } {
    loadIfNeed

    set result [list]
    foreach tag {phi_osc_middle phi_osc_end phi_osc_all} {
        lappend result $tag [dict get $d_parameter $tag]
    }
    return $result
}
body GridGroup::GridBase::getNodeLabel { index } {
    loadIfNeed
    if {![dict exists $d_matrix node_label_list]} {
        return ""
    }
    set nlList [dict get $d_matrix node_label_list]
    return [lindex $nlList $index]
}
body GridGroup::GridBase::getCollectedPhiRange { } {
    loadIfNeed
    set shape [dict get $d_geo shape]

    puts "getCollectedPhiRange for $this"
    if {$shape != "crystal"} {
        puts "skip not crystal"
        return ""
    }
    if {[getForLCLS]} {
        set rangeList [list]
        set inDataSection 0
        set index -1
        foreach node $l_nodeList {
            incr index
            set nodeStatus [lindex $node 0]
            puts "checking node $index status=$nodeStatus"
            if {[string is double -strict $nodeStatus] || $nodeStatus == "D"} {
                if {!$inDataSection} {
                    set inDataSection 1
                    lappend rangeList $index
                }
            } else {
                if {$inDataSection} {
                    set inDataSection 0
                    lappend rangeList [expr $index - 1]
                }
            }
        }
        if {$inDataSection} {
            lappend rangeList $index
        }
        puts "rangeList $rangeList"
        if {$rangeList == ""} {
            return ""
        }
        set aStart [dict get $d_parameter start_angle]
        set aStep  [dict get $d_parameter node_angle]

        set phiRangeList ""
        foreach index $rangeList {
            set a [expr $aStart + $aStep * $index]
            lappend phiRangeList $a
        }
        return $phiRangeList
    } else {
        set nextFrame [getNextFrame]
        if {$nextFrame < 0} {
            ### all done
            set aStart [dict get $d_parameter start_angle]
            set delta  [dict get $d_parameter delta]
            set fStart [dict get $d_parameter start_frame]
            set fEnd   [dict get $d_parameter end_frame]

            set aEnd   [expr $aStart + $delta * ($fEnd - $fStart + 1)]

            return [list $aStart $aEnd]
        } else {
            ### we not have record for each frame, so we assume it has been
            ### started from the beginning.
            set contents [createDictForRunCalculator]

            $_CALCULATOR update $contents
            set currentFrame [$_CALCULATOR getMotorPositionsAtIndex $nextFrame]
            foreach {fname idx phi e} $currentFrame break
            set aStart [dict get $d_parameter start_angle]
            return [list $aStart $phi]
        }
    }
}
body GridGroup::GridBase::getInputPhiRange { } {
    loadIfNeed
    set shape [dict get $d_geo shape]

    puts "getInputPhiRange for $this"
    if {$shape != "crystal"} {
        puts "skip not crystal"
        return 0
    }
    if {[getForLCLS]} {
        set aStart [dict get $d_parameter start_angle]
        set aEnd   [dict get $d_parameter end_angle]
    } else {
        set aStart [dict get $d_parameter start_angle]
        set delta  [dict get $d_parameter delta]
        set fStart [dict get $d_parameter start_frame]
        set fEnd   [dict get $d_parameter end_frame]

        set aEnd   [expr $aStart + $delta * ($fEnd - $fStart + 1)]
    }
    return [expr abs($aStart - $aEnd)]
}
body GridGroup::GridBase::createDictForRunCalculator { } {
    loadIfNeed
    set shape [dict get $d_geo shape]

    if {$shape != "crystal"} {
        return [dict create]
    }

    ### create node list in sequence order
    set nodeList [list]
    foreach index $l_sequence2index {
        set node [lindex $l_nodeList $index]
        set first [lindex $node 0]
        set firstChar [string index $first 0]

        ### 10/25/13: for SSRL crystal, the node is left with "D" when it is
        ### done.  So we relax the check
        #{$firstChar == "S" || [string is double -strict $first]}
        if {[string is double -strict $first]} {
            lappend nodeList 1
        } else {
            switch -exact -- $firstChar {
                D -
                X -
                S {
                    lappend nodeList 1
                }
                default {
                    lappend nodeList 0
                }
            }
        }
    }

    set result [dict create node_sequence $nodeList run_label ""]

    foreach name {prefix start_frame start_angle end_frame delta} {
        dict set result $name [dict get $d_parameter $name]
    }

    if {[catch {dict get $d_parameter next_frame} nextFrame]} {
        set nextFrame 0
    }
    if {[catch {dict get $d_parameter wedge_size} wedgeSize]} {
        set wedgeSize 180.0
    }
    if {[catch {dict get $d_parameter inverse_beam} inverseOn]} {
        set inverseOn 0
    }

    dict set result next_frame   $nextFrame
    dict set result wedge_size   $wedgeSize
    dict set result inverse_beam $inverseOn

    if {![catch {dict get $d_parameter energy_list} eList]} {
        dict set result energy_list $eList
    }

    return $result
}
body GridGroup::GridBase::getSetupProperties { } {
    loadIfNeed

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
    set shape   [dict get $d_geo shape]
    if {[catch {dict get $d_geo for_lcls} forLCLS]} {
        set forLCLS 0
    }

    set result ""
    foreach index $l_sequence2index {
        set node [lindex $l_nodeList $index]
        lappend result $node
    }
    set labelList ""
    if {[dict exists $d_matrix node_label_list]} {
        set nlList [dict get $d_matrix node_label_list]
        foreach index $l_sequence2index {
            set nodeLabel [lindex $nlList $index]
            lappend labelList $nodeLabel
        }
    }
    if {$labelList == "" && $shape == "crystal" && $forLCLS != "1"} {
        if {[catch {
            set dContents [createDictForRunCalculator]
            $_CALCULATOR update $dContents
            set labelList [$_CALCULATOR getFrameLabelForNodeList]
        } errMsg]} {
            log_error failed to generate frame label for node: $errMsg
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
    set header [list $m_id $m_label $m_status $directory $prefix $ext $shape]

    set phiList ""
    if {$shape == "crystal" && $forLCLS == "1"} {
        set nodeList4Phi [dict get $d_matrix node_list_for_phi]
        foreach index $l_sequence2index {
            set node [lindex $nodeList4Phi $index]
            lappend phiList $node
        }
    }

    return [list $header $result $labelList $phiList]
}
body GridGroup::GridBase::getPhiNodeListForDisplay { } {
    loadIfNeed
    set shape   [dict get $d_geo shape]
    if {[catch {dict get $d_geo for_lcls} forLCLS]} {
        set forLCLS 0
    }

    if {$shape != "crystal"} {
        return ""
    }
    if {$forLCLS != "1"} {
        return ""
    }

    set nlList ""
    if {[dict exists $d_matrix node_label_list]} {
        set nlList [dict get $d_matrix node_label_list]
    }

    set nodeList4Phi [dict get $d_matrix node_list_for_phi]
    set numPhiPerNode [dict get $d_parameter num_phi_shot]

    set ll [llength $l_sequence2index]
    set seqEnd [expr $ll - 1]
    set seqMid [expr $ll / 2]

    set strategySeq [getStrategyNode]

    set result ""
    for {set i 0} {$i < $ll} {incr i} {
        set seq [expr $ll - $i - 1]
        if {$seq == $strategySeq} {
            continue
        }
        set index     [lindex $l_sequence2index $seq]
        set node      [lindex $nodeList4Phi $index]
        set nodeLabel [lindex $nlList $index]
        if {[string is integer -strict $node] \
        && $node >= 0 \
        && $node < $numPhiPerNode} {
            if {$nodeLabel == ""} {
                set nodeLabel [expr $seq + 1]
            }
            if {$seq == $seqMid} {
                append nodeLabel "(mid)"
            } elseif {$seq == $seqEnd} {
                append nodeLabel "(end)"
            }
            if {$node == 0} {
                lappend result $nodeLabel
            } else {
                lappend result $nodeLabel:[expr $numPhiPerNode - $node]
            }
        }
    }
    puts "phi node list for display: $result"
    return $result
}
body GridGroup::GridBase::getAllPhiNodeList { } {
    loadIfNeed
    set shape   [dict get $d_geo shape]
    if {[catch {dict get $d_geo for_lcls} forLCLS]} {
        set forLCLS 0
    }

    if {$shape != "crystal"} {
        return ""
    }
    if {$forLCLS != "1"} {
        return ""
    }

    set nodeList4Phi [dict get $d_matrix node_list_for_phi]

    set result ""
    foreach index $l_sequence2index {
        lappend result [lindex $nodeList4Phi $index]
    }
    return $result
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

    set ll [llength $l_sequence2index]
    if {[sequenceIsDynamic]} {
        ## just return next, we do not care the input current.
        set llDone [llength $l_sequenceHistory]
        if {$llDone >= $ll} {
            return -1
        }
        return $llDone
    }

    ### this is the code to start from current node.
    #if {$current < 0 && $m_currentNodeIndex >= 0} {
    #    set current [lsearch -exact $l_sequence2index $m_currentNodeIndex]
    #    if {$current >= 0} {
    #        set currentStatus [lindex $l_nodeList $m_currentNodeIndex]
    #        if {$currentStatus == "S"} {
    #            return $current
    #        }
    #    }
    #}

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
        set nIdx [lindex $l_sequence2index $i]
        set nSts [lindex $l_nodeList $nIdx]
        if {$nSts == "S"} {
            return $i
        }
    }
    for {set i 0} {$i < $next} {incr i} {
        if {$i == $current} {
            continue
        }
        set nIdx [lindex $l_sequence2index $i]
        set nSts [lindex $l_nodeList $nIdx]
        if {$nSts == "S"} {
            return $i
        }
    }
    return -1
}
body GridGroup::GridBase::getNextPhiNode { current } {
    loadIfNeed

    set numPhiPerNode [dict get $d_parameter num_phi_shot]
    set nodeList4Phi  [dict get $d_matrix node_list_for_phi]
    set ll [llength $l_sequence2index]

    set strategySeq [getStrategyNode]

    set next [expr $current - 1]
    if {$next < 0 || $next >= $ll} {
        ### start at the end
        set next [expr $ll - 1]
    }
    for {set i $next} {$i >= 0} {incr i -1} {
        if {$i == $current} {
            continue
        }
        if {$i == $strategySeq} {
            continue
        }
        set nIdx [lindex $l_sequence2index $i]
        set nSts [lindex $nodeList4Phi $nIdx]
        if {[string is integer -strict $nSts] \
        && $nSts >= 0 && $nSts < $numPhiPerNode} {
            return $i
        }
    }
    for {set i [expr $ll - 1]} {$i > $next} {incr i -1} {
        if {$i == $current} {
            continue
        }
        if {$i == $strategySeq} {
            continue
        }
        set nIdx [lindex $l_sequence2index $i]
        set nSts [lindex $l_nodeList $nIdx]
        if {[string is integer -strict $nSts] \
        && $nSts >= 0 && $nSts < $numPhiPerNode} {
            return $i
        }
    }
    return -1
}
body GridGroup::GridBase::saveClosestNodeToBeam { sample_x sample_y sample_z } {
    loadIfNeed

    ###_orig is the orig for grid.
    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $_orig break

    set shape [dict get $d_geo shape]
    set useGrid 1
    switch -exact -- $shape {
        l614 -
        projective -
        trap_array -
        mesh {
            set useGrid 0
        }
        default {
        }
    }
    if {$useGrid} {
        foreach {proj_v proj_h} [calculateProjectionFromSamplePosition $_orig \
        $sample_x $sample_y $sample_z 0] break

        set row_index [expr int($proj_v)]
        set col_index [expr int($proj_h)]
        puts "saveClosestNodeToBeam: proj: v=$proj_v h=$proj_h"
        puts "row=$row_index col=$col_index"

        if {$row_index < 0} {
            set row_index 0
        } elseif {$row_index >= $numRow} {
            set row_index [expr $numRow - 1]
        }
        if {$col_index < 0} {
            set col_index 0
        } elseif {$col_index >= $numColumn} {
            set col_index [expr $numColumn - 1]
        }
        set m_currentNodeIndex [expr $row_index * $numColumn + $col_index]
        generateSequenceMap
        return
    }

    ## shape l614, the holes are not aligned to grid, we have to calculate
    ## one by one
    foreach {proj_v proj_h} [calculateProjectionFromSamplePosition $_orig \
    $sample_x $sample_y $sample_z 1] break

    set localCoords [dict get $d_geo local_coords]
    if {[catch {dict get $d_geo num_anchor} numAnchorPoint]} {
        set numAnchorPoint 4
    }
    if {[catch {dict get $d_geo num_border} numBorderPoint]} {
        set numBorderPoint 4
    }
    set startIdx [expr 2 * ($numAnchorPoint + $numBorderPoint)]
    set holeCoords [lrange $localCoords $startIdx end]

    set index -1
    set m_currentNodeIndex 0
    ## just a big number
    set minD2 9e99

    foreach {x y} $holeCoords {
        incr index
        set d2 \
        [expr ($x - $proj_h) * ($x - $proj_h) + ($y - $proj_v) * ($y - $proj_v)]

        if {$d2 < $minD2} {
            set minD2 $d2
            set m_currentNodeIndex $index
        }
    }
    puts "for L614, set current node to $m_currentNodeIndex"
    generateSequenceMap
}
body GridGroup::GridBase::getNodePosition { seq } {
    loadIfNeed

    set ll [llength $l_sequence2index]
    if {$seq < 0 || $seq >= $ll} {
        log_error seq $seq out of range 0 to [expr $ll - 1]
        return -code error BAD_NODE_SEQ
    }
    set index [lindex $l_sequence2index $seq]
    set nodeLabel ""
    if {[dict exists $d_matrix node_label_list]} {
        set nlList [dict get $d_matrix node_label_list]
        set nodeLabel [lindex $nlList $index]
    }

    ###_orig is the orig for grid.
    foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
    numRow numColumn} $_orig break

    set numColumn [expr int($numColumn)]

    set row_index [expr $index / $numColumn]
    set col_index [expr $index % $numColumn]

    set shape [dict get $d_geo shape]
    switch -exact -- $shape {
        crystal {
            puts "getNodePosition for crystal seq=$seq, index=$index"
            set nodePositionList [dict get $d_matrix node_position_list]
            set pos [lindex $nodePositionList $index]
            set a $orig_a
            if {[llength $pos] < 3} {
                puts "no node position found"
                puts "node_position_list=$nodePositionList"
                set pos $_orig
            }
            foreach {x y z a} $pos break
            return [list $x $y $z $a $row_index $col_index $nodeLabel $index]
        }
        projective -
        trap_array -
        mesh {
            set localCoords [dict get $d_geo local_coords]
            if {[catch {dict get $d_geo num_anchor} numAnchorPoint]} {
                set numAnchorPoint 4
            }
            if {[catch {dict get $d_geo num_border} numBorderPoint]} {
                set numBorderPoint 4
            }
            set startIdx [expr 2 * ($numAnchorPoint + $numBorderPoint)]
            set holeCoords [lrange $localCoords $startIdx end]
            set offset0 [expr $index * 2]
            set offset1 [expr $offset0 + 1]

            set proj_h [lindex $holeCoords $offset0]
            set proj_v [lindex $holeCoords $offset1]
            set isMicron 1
        }
        l614 {
            set localCoords [dict get $d_geo local_coords]
            set holeCoords [lrange $localCoords 16 end]
            set offset0 [expr $index * 2]
            set offset1 [expr $offset0 + 1]

            set proj_h [lindex $holeCoords $offset0]
            set proj_v [lindex $holeCoords $offset1]
            set isMicron 1
        }
        line {
            set localCoords [dict get $d_geo local_coords]
            set nodeCoords [lrange $localCoords 4 end]
            set offset0 [expr $index * 2]
            set offset1 [expr $offset0 + 1]

            set proj_h [lindex $nodeCoords $offset0]
            set proj_v [lindex $nodeCoords $offset1]
            set isMicron 1
        }
        default {
            set proj_v [expr $row_index - ($numRow    - 1) / 2.0]
            set proj_h [expr $col_index - ($numColumn - 1) / 2.0]
            set isMicron 0
        }
    }
    ## It should always start from orig position.  This way will make sure
    ## the 90 degree view the position is at the same level with orig.
    foreach {dx dy dz} \
    [calculateSamplePositionDeltaFromProjection \
    $_orig $orig_x $orig_y $orig_z $proj_v $proj_h $isMicron] break

    set x [expr $orig_x + $dx]
    set y [expr $orig_y + $dy]
    set z [expr $orig_z + $dz]

    return [list $x $y $z $orig_a $row_index $col_index $nodeLabel $index]
}
body GridGroup::GridBase::getMovePosition { ux uy index } {
    loadIfNeed

    set shape [dict get $d_geo shape]
    if {$shape == "crystal"} {
        set nodePositionList [dict get $d_matrix node_position_list]
        set nodePos [lindex $nodePositionList $index]
        foreach {x0 y0 z0 a0} $nodePos break
        set nodeOrig [lreplace $_orig 0 3 $x0 $y0 $z0 $a0]
        return [calculateSamplePositionFromProjection $nodePos $uy $ux 1]
    }
    ### non-cystal is easy, no index needed.
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
body GridGroup::GridBase::moveCrystal { dx dy dz } {
    ### loadIfNeed is called in getShape
    if {[getShape] != "crystal"} {
        log_severe moveCrystal called for non-crystal: $this
        return -code error NOT_COMPATIBLE
    }
    ############## NODE LIST #############
    set nodePositionList [dict get $d_matrix node_position_list]
    set newNodePList [list]
    foreach pos $nodePositionList {
        foreach {x y z} $pos break
        set x [expr $x + $dx]
        set y [expr $y + $dy]
        set z [expr $z + $dz]
        set newPos [lreplace $pos 0 2 $x $y $z]
        lappend newNodePList $newPos
    }
    dict set d_matrix node_position_list $newNodePList

    ############# CLICKED POSITION LIST ##############
    set positionList [dict get $d_geo position_list]
    set newPList [list]
    foreach pos $positionList {
        foreach {x y z} $pos break
        set x [expr $x + $dx]
        set y [expr $y + $dy]
        set z [expr $z + $dz]
        set newPos [lreplace $pos 0 2 $x $y $z]
        lappend newPList $newPos
    }
    dict set d_geo position_list $newPList

    ######### ORIG ############
    foreach {x y z} $m_imageOrig break
    set x [expr $x + $dx]
    set y [expr $y + $dy]
    set z [expr $z + $dz]
    set m_imageOrig [lreplace $m_imageOrig 0 2 $x $y $z]

    set _needWrite 1
    return

    #######################################
    ### should not need the code below
    #######################################

    #### geo center
    foreach {horz vert} \
    [calculateSamplePositionOnVideo $m_imageOrig $m_imageOrig 1] break

    set oldx [dict get $d_geo center_x]
    set oldy [dict get $d_geo center_y]
    dict set d_geo center_x $horz
    dict set d_geo center_y $vert
    puts "geo center moved from $oldx $oldy to $horz $vert"

    set oldx [dict get $d_matrix center_x]
    set oldy [dict get $d_matrix center_y]
    dict set d_matrix center_x $horz
    dict set d_matrix center_y $vert
    puts "matrix center moved from $oldx $oldy to $horz $vert"
}
body GridGroup::GridBase::acceptStrategy { d_strategy omega } {
    if {![dict exists $d_strategy start_phi]} {
        log_error start_phi not found in the strategy
        return -code error LACK_INFO
    }
    set startAngle [dict get $d_strategy start_phi]
    if {![string is double -strict $startAngle]} {
        log_error start_phi is not a number in strategy
        return -code error BAD_INFO
    }

    ### loadIfNeed is called in getShape
    if {[getShape] != "crystal"} {
        log_severe acceptStrategy called for non-crystal: $this
        return -code error NOT_COMPATIBLE
    }
    dict set d_parameter strategy_info $d_strategy

    set setup [setupExposure start_angle $startAngle]

    set d_parameter [dict merge $d_parameter $setup]

    #### now adjust angle for each node.
    ### find out how much to adjust
    set nodePositionList [dict get $d_matrix node_position_list]
    set firstIndex [lindex $l_sequence2index 0]
    set firstNode [lindex $nodePositionList $firstIndex]
    set oldAngle [lindex $firstNode 3]
    set oldPhi   [expr $oldAngle - $omega]
    set diff [expr $startAngle - $oldPhi]

    set newNPList [list]
    foreach pos $nodePositionList {
        set oldA [lindex $pos 3]
        set newA [expr $oldA + $diff]
        set newPos [lreplace $pos 3 3 $newA]
        lappend newNPList $newPos
    }
    dict set d_matrix node_position_list $newNPList

    set _needWrite 1
    return $setup
}
body GridGroup::GridBase::_generateSplitInfo {
    split_positionList \
    split_nodePositionList \
    split_nodeList \
    frameStartREF \
    omega \
} {
    upvar $frameStartREF fStart

    set split_orig      $m_imageOrig
    set split_geo       $d_geo
    set split_matrix    $d_matrix
    set split_parameter $d_parameter

    set resetted_nodeList [list]
    set totalSelected 0
    foreach node $split_nodeList {
        switch -exact -- $node {
            - -
            -- -
            NEW -
            N {
                lappend resetted_nodeList $node
            }
            default {
                lappend resetted_nodeList S
                incr totalSelected
            }
        }
    }

    set split_numCol [llength $split_nodeList]
    set split_nodeList4Phi [string trim [string repeat "N " $split_numCol]]

    puts "nodelist: $split_nodeList"
    puts "resetted: $resetted_nodeList"
    puts "forphi: $split_nodeList4Phi"

    set firstP [lindex $split_positionList 0]
    foreach {x0 y0 z0} $firstP break
    set minX $x0
    set maxX $x0
    set minY $y0
    set maxY $y0
    set minZ $z0
    set maxZ $z0
    foreach pos $split_positionList {
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

    set cx [expr 0.5 * ($maxX + $minX)]
    set cy [expr 0.5 * ($maxY + $minY)]
    set cz [expr 0.5 * ($maxZ + $minZ)]
    set rx [expr $maxX - $minX]
    set ry [expr $maxY - $minY]
    set rz [expr $maxZ - $minZ]

    set split_orig [lreplace $split_orig 0 2 $cx $cy $cz]
    foreach {oX oY } \
    [calculateSamplePositionOnVideo $split_orig $split_orig 1] break

    set firstNP [lindex $split_nodePositionList 0]
    set a0 [lindex $firstNP 3]
    set split_startAngle [expr $a0 - $omega]
    set forLCLS [dict get $d_geo for_lcls]
    set nodeAngle [dict get $d_parameter node_angle]
    set nodeFrame [dict get $d_parameter node_frame]
    puts "nodeAngle=$nodeAngle"

    if {$forLCLS} {
        set split_endAngle [expr $split_startAngle \
        + $nodeAngle * ($totalSelected - 1)]
    } {
        set split_endAngle [expr $split_startAngle \
        + $nodeAngle * $totalSelected]
    }
    set split_startFrame $fStart
    set split_endFrame \
    [expr $split_startFrame + $nodeFrame * $totalSelected - 1]

    ## adjust for next segment
    set fStart [expr $split_endFrame + 1]

    puts "adjust geo"
    ### geo adjust
    dict set split_geo center_x $oX
    dict set split_geo center_y $oY
    dict set split_geo half_width  [expr 500.0 * $rz]
    dict set split_geo half_height [expr 500.0 * sqrt( $rx * $rx + $ry * $ry)]
    ##### crystal special
    dict set split_geo position_list $split_positionList
    dict set split_geo segment_index_list ""

    puts "adjust matrix"
    dict set split_matrix num_column $split_numCol
    dict set split_matrix center_x $oX
    dict set split_matrix center_y $oY
    ##### crystal special
    dict set split_matrix node_position_list $split_nodePositionList
    dict set split_matrix node_list_for_phi  $split_nodeList4Phi
    dict set split_matrix node_segment_index_list ""

    puts "adjust parameter"
    dict set split_parameter strategy_info ""
    dict set split_parameter strategy_enable 0
    dict set split_parameter phi_osc_middle 0
    dict set split_parameter phi_osc_end 0
    dict set split_parameter phi_osc_all 0

    dict set split_parameter start_angle $split_startAngle
    dict set split_parameter end_angle   $split_endAngle
    dict set split_parameter start_frame $split_startFrame
    dict set split_parameter end_frame   $split_endFrame

    return \
    [list $split_orig $split_geo $split_matrix $resetted_nodeList $split_parameter]
}
body GridGroup::GridBase::updateSectionCoords { \
    sectionInfo \
    hotspotCoords \
    num_column \
    nodeCoordsREF \
} {
    upvar $nodeCoordsREF nodeCoords

    foreach {hIdx0 hIdx1 hIdx2 hIdx3 nRow0 nRow1 nCol0 nCol1} $sectionInfo break
    set hIdx0 [expr $hIdx0 * 2]
    set hIdx1 [expr $hIdx1 * 2]
    set hIdx2 [expr $hIdx2 * 2]
    set hIdx3 [expr $hIdx3 * 2]

    set hot0 [lrange $hotspotCoords $hIdx0 [expr $hIdx0 + 1]]
    set hot1 [lrange $hotspotCoords $hIdx1 [expr $hIdx1 + 1]]
    set hot2 [lrange $hotspotCoords $hIdx2 [expr $hIdx2 + 1]]
    set hot3 [lrange $hotspotCoords $hIdx3 [expr $hIdx3 + 1]]

    #### the setup need points: 0, 1, 3, 2.
    set uvxyList [list \
    $nCol0 $nRow0 \
    $nCol1 $nRow0 \
    $nCol1 $nRow1 \
    $nCol0 $nRow1 \
    ]
    eval lappend uvxyList $hot0 $hot1 $hot3 $hot2

    if {$_MAPPING_CALCULATOR == ""} {
        set _MAPPING_CALCULATOR [createNewBilinearMapping]
    }

    eval $_MAPPING_CALCULATOR setup $uvxyList
    set m_mapResult ""

    for {set nRow $nRow0} {$nRow <= $nRow1} {incr nRow} {
        for {set nCol $nCol0} {$nCol <= $nCol1} {incr nCol} {
            set uvList [list $nCol $nRow]
            $_MAPPING_CALCULATOR map $uvList
            foreach {x y} $m_mapResult break
            set idxNd [expr 2 * ($nRow * $num_column + $nCol)]
            lset nodeCoords $idxNd $x
            incr idxNd
            lset nodeCoords $idxNd $y
        }
    }
}
body GridGroup::GridBase::addHotSpotRow { row_ } {
    if {![string is integer -strict $row_]} {
        log_error row $row_ is not integer
        return 0
    }

    ### loadIfNeed is called in getShape
    set shape [getShape]
    switch -exact -- $shape {
        trap_array {
            ## for now (05/27/14), only trap array is derived from net base.
        }
        default {
            log_severe setHotSpotRowAndColumn called for shape $shape
            return 0
        }
    }
    if {[catch {dict get $d_geo hot_spot_row_list} hsRows]} {
        set hsRows ""
    }
    if {[catch {dict get $d_geo hot_spot_column_list} hsCols]} {
        set hsCols ""
    }
    if {[lsearch -exact $hsRows $row_] >= 0} {
        log_warning row already has hotspot.
        return 0
    }
    set num_row [dict get $d_matrix num_row]
    if {$row_ < 0 || $row_ >= $num_row} {
        log_error row is out of range
        return 0
    }
    set newRowList $hsRows
    ### the order does not matter.
    lappend newRowList $row_

    ### no need to regenerate coords for nodes.
    return [setHotSpotRowAndColumn $newRowList $hsCols {}]
}
body GridGroup::GridBase::addHotSpotColumn { col_ } {
    if {![string is integer -strict $col_]} {
        log_error column $col_ is not integer
        return 0
    }

    ### loadIfNeed is called in getShape
    set shape [getShape]
    switch -exact -- $shape {
        trap_array {
            ## for now (05/27/14), only trap array is derived from net base.
        }
        default {
            log_severe setHotSpotRowAndColumn called for shape $shape
            return 0
        }
    }
    if {[catch {dict get $d_geo hot_spot_row_list} hsRows]} {
        set hsRows ""
    }
    if {[catch {dict get $d_geo hot_spot_column_list} hsCols]} {
        set hsCols ""
    }
    if {[lsearch -exact $hsCols $col_] >= 0} {
        log_warning column already has hotspots.
        return 0
    }
    set num_column [dict get $d_matrix num_column]
    if {$col_ < 0 || $col_ >= $num_column} {
        log_error column is out of range
        return 0
    }
    set newColList $hsCols
    ### the order does not matter.
    lappend newColList $col_

    ### no need to regenerate coords for nodes.
    return [setHotSpotRowAndColumn $hsRows $newColList {}]
}
body GridGroup::GridBase::removeHotSpotRow { row_ } {
    if {![string is integer -strict $row_]} {
        log_error row $row_ is not integer
        return 0
    }

    ### loadIfNeed is called in getShape
    set shape [getShape]
    switch -exact -- $shape {
        trap_array {
            ## for now (05/27/14), only trap array is derived from net base.
        }
        default {
            log_severe setHotSpotRowAndColumn called for shape $shape
            return 0
        }
    }
    if {[catch {dict get $d_geo hot_spot_row_list} hsRows]} {
        set hsRows ""
    }
    if {[catch {dict get $d_geo hot_spot_column_list} hsCols]} {
        set hsCols ""
    }
    set nHsCols [llength $hsCols]

    set rIndex [lsearch -exact $hsRows $row_]
    if {$rIndex < 0} {
        log_warning row does not have hotspot.
        return 0
    }
    if {$rIndex == 0} {
        log_error cannot remove edge row from hot spots.
        return 0
    }
    set num_row [dict get $d_matrix num_row]
    if {$row_ < 0 || $row_ >= $num_row} {
        log_error row is out of range
        return 0
    }
    if {$row_ == 0 || $row_ == [expr $num_row  - 1]} {
        log_error cannot remove edge row from hot spots.
        return 0
    }
    set newRowList [lreplace $hsRows $rIndex $rIndex]

    set sectList {}
    if {$nHsCols < 2} {
        set sectList all
    } else {
        set nSecCol [expr $nHsCols - 1]
        set offset0 [expr $nSecCol * ($rIndex - 1)]
        for {set i 0} {$i < $nSecCol} {incr i} {
            lappend sectList [expr $offset0 + $i]
        }
    }

    ### no need to regenerate coords for nodes.
    return [setHotSpotRowAndColumn $newRowList $hsCols $sectList]
}
body GridGroup::GridBase::removeHotSpotColumn { col_ } {
    if {![string is integer -strict $col_]} {
        log_error column is not integer
        return 0
    }

    ### loadIfNeed is called in getShape
    set shape [getShape]
    switch -exact -- $shape {
        trap_array {
            ## for now (05/27/14), only trap array is derived from net base.
        }
        default {
            log_severe setHotSpotRowAndColumn called for shape $shape
            return 0
        }
    }
    if {[catch {dict get $d_geo hot_spot_row_list} hsRows]} {
        set hsRows ""
    }
    set nHsRows [llength $hsRows]

    if {[catch {dict get $d_geo hot_spot_column_list} hsCols]} {
        set hsCols ""
    }
    set nHsCols [llength $hsCols]

    set cIndex [lsearch -exact $hsCols $col_]
    if {$cIndex < 0} {
        log_warning column does not have hotspots.
        return 0
    }
    if {$cIndex == 0} {
        log_warning edge column cannot be removed from hotspots.
        return 0
    }
    set num_column [dict get $d_matrix num_column]
    if {$col_ < 0 || $col_ >= $num_column} {
        log_error column is out of range
        return 0
    }
    if {$col_ == 0 || $col_ == [expr $num_column - 1]} {
        log_warning edge column cannot be removed from hotspots.
        return 0
    }
    set newColList [lreplace $hsCols $cIndex $cIndex]

    set sectList {}
    if {$nHsRows < 2} {
        set sectList all
    } else {
        set nSecRow [expr $nHsRows - 1]
        ### after remove on column
        set nSecCol [expr $nHsCols - 2]
        for {set i 0} {$i < $nSecRow} {incr i} {
            lappend sectList [expr $i * $nSecCol + $cIndex - 1]
        }
    }

    ### no need to regenerate coords for nodes.
    return [setHotSpotRowAndColumn $hsRows $newColList $sectList]
}
body GridGroup::GridBase::setHotSpotRowAndColumn { \
    rows_ \
    columns_ \
    {sectionListNeedUpdate all} \
} {
    ### loadIfNeed is called in getShape
    set shape [getShape]
    switch -exact -- $shape {
        trap_array {
            ## for now (05/27/14), only trap array is derived from net base.
        }
        default {
            log_severe setHotSpotRowAndColumn called for shape $shape
            return 0
        }
    }

    ### check if already done
    if {[catch {dict get $d_geo hot_spot_row_list} hsRows]} {
        set hsRows ""
    }
    if {[catch {dict get $d_geo hot_spot_column_list} hsCols]} {
        set hsCols ""
    }
    set num_row     [dict get $d_matrix num_row]
    set num_column  [dict get $d_matrix num_column]
    set lastRow [expr $num_row - 1]
    set lastCol [expr $num_column - 1]

    set rows ""
    for {set i 0} {$i < $num_row} {incr i} {
        if {$i == 0 || $i == $lastRow || [lsearch -exact $rows_ $i] >= 0} {
            lappend rows $i
        }
    }
    set columns ""
    for {set i 0} {$i < $num_column} {incr i} {
        if {$i == 0 || $i == $lastCol || [lsearch -exact $columns_ $i] >= 0} {
            lappend columns $i
        }
    }

    if {$rows == $hsRows && $columns == $hsCols} {
        ### already done, no change
        return 0
    }

    set onlyAdd 1
    foreach rr $hsRows {
        if {[lsearch -exact $rows $rr] < 0} {
            set onlyAdd 0
            break
        }
    }
    if {$onlyAdd} {
        foreach cc $hsCols {
            if {[lsearch -exact $columns $cc] < 0} {
                set onlyAdd 0
                break
            }
        }
    }

    #### retrieve all nodes
    set localCoords [dict get $d_geo local_coords]
    if {[catch {dict get $d_geo num_anchor} numAnchorPoint]} {
        set numAnchorPoint 4
    }
    if {[catch {dict get $d_geo num_border} numBorderPoint]} {
        set numBorderPoint 4
    }
    ### save border
    set startIdx [expr 2 * $numAnchorPoint]
    set endIdx   [expr 2 * ($numAnchorPoint + $numBorderPoint) - 1]
    set borderCoords [lrange $localCoords $startIdx $endIdx]

    ### save nodes
    set startIdx [expr 2 * ($numAnchorPoint + $numBorderPoint)]
    set holeCoords [lrange $localCoords $startIdx end]

    ### we will use the node position for related hotspots.
    set hotspotCoords ""
    set hotspot2SectionMap ""
    foreach r $rows {
        foreach c $columns {
            set idxNode [expr $r * $num_column + $c]
            set idxStart [expr $idxNode * 2]
            set idxEnd   [expr $idxStart + 1]
            foreach {x y} [lrange $holeCoords $idxStart $idxEnd] break
            lappend hotspotCoords $x $y
            lappend hotspot2SectionMap {}
        }
    }
    ##### generate section list and hotspot mapping
    ### hRow, hCol are about hotspot.  nRow, ncol are about node.
    set sectionList ""
    set idxSection -1

    set numHotSpotRow [llength $rows]
    set numHotSpotCol [llength $columns]
    for {set hRow 0} {$hRow < [expr $numHotSpotRow - 1]} {incr hRow} {
        set nRow0 [lindex $rows $hRow]
        set nRow1 [lindex $rows [expr $hRow + 1]]
        for {set hCol 0} {$hCol < [expr $numHotSpotCol - 1]} {incr hCol} {
            incr idxSection

            set nCol0 [lindex $columns $hCol]
            set nCol1 [lindex $columns [expr $hCol + 1]]

            set hIndex0 [expr $hRow       * $numHotSpotCol + $hCol]
            set hIndex1 [expr $hIndex0 + 1]
            set hIndex2 [expr ($hRow + 1) * $numHotSpotCol + $hCol]
            set hIndex3 [expr $hIndex2 + 1]
            lappend sectionList \
            [list $hIndex0 $hIndex1 $hIndex2 $hIndex3 \
            $nRow0 $nRow1 $nCol0 $nCol1]

            ### setup hotspot mapping to this
            foreach hIdx [list $hIndex0 $hIndex1 $hIndex2 $hIndex3] {
                set sList [lindex $hotspot2SectionMap $hIdx]
                lappend sList $idxSection
                lset hotspot2SectionMap $hIdx $sList
            }
        }
    }

    if {!$onlyAdd} {
        if {$sectionListNeedUpdate == "all"} {
            puts "updating all sections"
            foreach sectionInfo $sectionList {
                updateSectionCoords \
                $sectionInfo $hotspotCoords $num_column holeCoords
            }
        } else {
            foreach sIndex $sectionListNeedUpdate {
                puts "updating section $sIndex"
                set sectionInfo [lindex $sectionList $sIndex]

                updateSectionCoords \
                $sectionInfo $hotspotCoords $num_column holeCoords
            }
        }
    }

    #### save info
    set newLocalCoords $hotspotCoords
    eval lappend newLocalCoords $borderCoords
    eval lappend newLocalCoords $holeCoords
    dict set d_geo local_coords $newLocalCoords
    dict set d_geo num_anchor [expr $numHotSpotRow * $numHotSpotCol]
    dict set d_geo hot_spot_row_list $rows
    dict set d_geo hot_spot_column_list $columns
    dict set d_geo section_list $sectionList
    dict set d_geo hotspot_to_section_map $hotspot2SectionMap

    set _needWrite 1
    return 1
}

class GridGroup::SnapshotImage {
    inherit GridGroup::Item

    ### sortAngle is angle from "0"
    ### it can be calculated from snapshot orig and group orig.
    ### We just do not want to do the calculation again and again.
    public method initialize { id label sortAngle camera file orig }
    public method getCamera { } { return [lindex $m_orig 10] }

    public method removePersistent { } {
        file delete -force $m_imageFile

        DCSPersistentBase::removePersistent
    }

    public method getFile { } { return $m_imageFile }
    public method getOrig { } { return $m_orig }
    public method getItemIdListDefaultOnThis { } {
        return $_itemList
    }
    public method clearItemIdList { } { set _itemList "" }
    public method addItem { id } {
        if {[lsearch -exact $_itemList $id] < 0} {
            lappend _itemList $id
        }
    }
    public method deleteItem { id } {
        set index [lsearch -exact $_itemList $id]
        if {$index >= 0} {
            set _itemList [lreplace $_itemList $index $index]
        }
    }

    ### hook
    #protected method afterInitializeFromHuddle { } {
    #}

    protected variable m_imageFile ""
    protected variable m_orig ""

    protected variable _itemList ""
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

    set oCamera [lindex $orig 10]
    if {$oCamera != $camera} {
        puts "DEBUG STRANG: camera mismatch between input and orig"
        puts "orig=$orig camera=$camera"
    }

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
    public method getDefaultCamera { } { return [lindex $m_orig 10] }

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
    public method getLastGridId { } {
        set grid [lindex $lo_gridList end]
        if {$grid == ""} {
            return -1
        }
        return [$grid getId]
    }

    public method getSnapshotIdForGrid { gridId } {
        ### dict access to empty will cause segment fault and cannot catch
        if {$_gridSnapshotMap ==""} {
            return -1
        }

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
    public method getGridCellSize { gridId } {
        set grid [_get_grid $gridId]
        return [$grid getCellSize]
    }
    ### this is in micron, before rotation
    public method getGridItemSize { gridId } {
        set grid [_get_grid $gridId]
        return [$grid getItemSize]
    }
    public method getGridShape { id } {
        set grid [_get_grid $id]
        return [$grid getShape]
    }

    public method searchSnapshotId { orig }

    public proc getMAXGROUP { } { return 1 }
    public proc getMAXNUMSNAPSHOT { } { return 16 }
    public proc getMAXNUMGRID { } { return 16 }
    public proc compareItem { t1 t2 }

    public proc retrievePurpose { dict } {
        set purpose forGrid
        if {![dict exists $dict shape]} {
            return $purpose
        }
        if {![dict exists $dict for_lcls]} {
            return $purpose
        }
        set shape [dict get $dict shape]
        set forLCLS [dict get $dict for_lcls]
        switch -exact -- $shape {
            crystal {
                if {$forLCLS} {
                    set purpose forLCLSCrystal
                } else {
                    set purpose forCrystal
                }
            }
            projective -
            trap_array -
            mesh -
            l614 {
                if {$forLCLS} {
                    set purpose forL614
                } else {
                    set purpose forPXL614
                }
            }
            default {
                if {$forLCLS} {
                    set purpose forLCLS
                } else {
                    set purpose forGrid
                }
            }
        }
        return $purpose
    }

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
    public method getNextGridId { shape user crystalSts screeningParm gridPort }

    ### This method will be used in dcss and BluIce.
    public proc generatePrefixAndDirectory { user shape label crystalSts \
    screeningParm {gridPort {}}}

    ### help functions used in both DCSS and BluIce
    ### no write, no operation update messages
    protected method _add_snapshot_image { id label sortNum camera file orig }
    protected method _delete_snapshot_image { id {removePersistent 0} {forced 0} }
    protected method _add_grid { \
        snapId id label sortNum orig geo grid nodes param seq2idx idx2seq \
    }
    protected method _modify_grid { id orig geo matrix nodes seq2idx idx2seq \
    {noCheck 0} }

    protected method _modify_grid_snapshot_id { id snapshotId }
    protected method _modify_parameter { id param }
    protected method _modify_userInput { id setup omega {noCheck 0}}
    protected method _modify_detectorMode_fileExt { id mode ext }
    protected method _delete_grid { id {removePersistent 0} {forced 0} }
    protected method _get_grid { id }
    protected method _clear_all { {removePersistent 0} }
    protected method _reset { {removePresistent 0} }

    protected variable _groupId -1

    protected variable m_orig {0 0 0 0 1 1 1 1 1 1 unknown}

    protected variable m_snapshotSeqNum 1
    #### reset during initialize

    protected variable lo_snapshotList ""

    protected variable _snapshotIdMap ""
    ### _createdGridList in snapshotImage
    protected variable lo_gridList ""
    protected variable _gridIdMap ""
    protected variable _gridSnapshotMap ""

    protected variable _topDirectory ""
    protected variable _path ""

    protected variable _muteUserInputField [list \
    phi_osc_middle \
    phi_osc_end \
    phi_osc_all \
    ]

    constructor { } {
    }
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
        $ss clearItemIdList
    }
    dict for {gridId snapshotId} $_gridSnapshotMap {
        set ss [dict get $_snapshotIdMap $snapshotId]
        $ss addItem $gridId
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
body GridGroup::GridGroupBase::getNextGridId { \
shape user crystalSts scrnParm gridPort } {
    ### grid has the same id, label, and sortNum
    set ll [llength $lo_gridList]
    if {$ll == 0} {
        foreach {prefix dir} \
        [generatePrefixAndDirectory $user $shape 1 \
        $crystalSts $scrnParm $gridPort] break

        return [list 1 1 1 $prefix $dir]
    }

    set lastItem [lindex $lo_gridList end]
    set lastId   [$lastItem getId]
    set lastNum  [$lastItem getSortNum]

    set nextId   [expr $lastId + 1]
    set nextNum  [expr $lastNum + 1]

    ### label will be different
    set lastPrefix ""
    set lastLabel 0
    for {set i [expr $ll - 1]} {$i >= 0} {incr i -1} {
        set item [lindex $lo_gridList $i]
        set itemShape  [$item getShape]
        set itemLabel  [$item getLabel]
        set itemPrefix [$item getPrefix]
        switch -exact -- $itemShape {
            crystal -
            projective -
            trap_array -
            mesh -
            l614 {
                if {$itemShape == $shape} {
                    set lastLabel  $itemLabel
                    set lastPrefix $itemPrefix
                    break
                }
            }
            default {
                switch -exact -- $shape {
                    projective -
                    trap_array -
                    mesh -
                    crystal -
                    l614 {
                    }
                    default {
                        set lastLabel  $itemLabel
                        set lastPrefix $itemPrefix
                        break
                    }
                }
            }
        }
    }
    ### will need change if label is not pure number
    set nextLabel [expr $lastLabel + 1]
    foreach {prefix dir} \
    [generatePrefixAndDirectory $user $shape $nextLabel \
    $crystalSts $scrnParm $gridPort] \
    break

    set ll0 [string length $lastLabel]
    set ll1 [string length $lastPrefix]
    if {$ll1 >= $ll0} {
        set startIndex [expr $ll1 - $ll0]
        if {[string range $lastPrefix $startIndex end] == $lastLabel} {
            if {$ll1 == $ll0} {
                set prefix $nextLabel
            } else {
                set idxEnd [expr $ll1 - $ll0 - 1]
                set char [string index $lastPrefix $idxEnd]
                if {![string is integer -strict $char]} {
                    set prefix [string range $lastPrefix 0 $idxEnd]$nextLabel
                }
            }
            puts "parse lastPrefix=$lastPrefix to get next: $prefix"
        }
    }
    return [list $nextId $nextLabel $nextNum $prefix $dir]
}
body GridGroup::GridGroupBase::generatePrefixAndDirectory { \
user shape label crystalSts screeningParm {gridPort {}}} {

    set crystalId [lindex $crystalSts    0]
    set sub_dir   [lindex $crystalSts    4]
    set cnt_dir   [lindex $crystalSts    9]
    set root_dir  [lindex $screeningParm 2]

    switch -exact -- $shape {
        crystal {
            set key crystal
        }
        trap_array {
            set key trapChip
        }
        mesh {
            set key mesh
        }
        projective -
        l614 {
            set key grid
        }
        default {
            set key raster
        }
    }

    if {$crystalId == ""} {
        set prefix ${key}${label}
        set dir ""
        return [list $prefix $dir]
    }

    set prefix ${crystalId}_${key}${label}
    if {$sub_dir != "." && $sub_dir != "./" && $sub_dir != ""} {
        set dir [file join $root_dir $sub_dir]
    } else {
        if {[string range $crystalId 0 1] == "bT" \
        && [string is integer -strict $cnt_dir]} {
            set dir [file join $root_dir ${crystalId}_${cnt_dir}]
        } else {
            set dir [file join $root_dir $crystalId]
        }
    }

    set firstChar [string index $gridPort 0]
    if {[string first $firstChar "ABCDE"] >= 0} {
        set dir ${dir}_$gridPort
    }

    checkUsernameInDirectory dir $user
    set dir    [TrimStringForRootDirectoryName $dir]
    set prefix [TrimStringForCrystalID $prefix]
    return [list $prefix $dir]
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
        if {[catch {$ss removePersistent} errMsg]} {
            puts "$ss removePersistent: $errMsg"
        }
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
    seq2idx idx2seq \
} {
    #### get snapshot object
    if {![dict exists $_snapshotIdMap $snapshotId]} {
        log_error cannot find snapshot with Id=$snapshotId
        return -code error "snapshot_not_exists"
    }
    set ss [dict get $_snapshotIdMap $snapshotId]
    $ss addItem $id

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
    $grid generateSequenceMap

    puts "_add_grid setupTop"
    setupTopAndTagsForChild $grid
    $grid _generateRPath

    ###generateGridMap
    lappend lo_gridList $grid
    dict set _gridIdMap       $id $grid
    dict set _gridSnapshotMap $id $snapshotId

    puts "_add_grid seq=$seq2idx idx=$idx2seq"
    if {$seq2idx != "" && $idx2seq != ""} {
        $grid setSequenceList $seq2idx $idx2seq
    }

    set _needWrite 1

    return $grid
}
body GridGroup::GridGroupBase::_modify_grid { \
    id orig geo matrix nodes seq2idx idx2seq {noCheck 0} \
} {
    if {![dict exists $_gridIdMap $id]} {
        ### id in fact is unique in whole group
        log_error grid with id=$id not exists
        return -code error "NOT_EXISTS"
    }
    set rr [_get_grid $id]
    if {!$noCheck && ![$rr getEditable]} {
        log_error reset it to setup grid.
        return -code error CANNOT_MODIFY
    }

    # -1 means no change for defaultSnapshotImage
    $rr setGeo -1 $orig $geo $matrix $nodes

    if {$seq2idx != "" && $idx2seq != ""} {
        $rr setSequenceList $seq2idx $idx2seq
    }

    set _needWrite 1

    return $rr
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
        log_error reset it to setup parameters.
        return -code error CANNOT_MODIFY
    }

    $rr setParameter $param

    set _needWrite 1
}
body GridGroup::GridGroupBase::_modify_userInput { id setup omega {noCheck 0}} {
    if {![dict exists $_gridIdMap $id]} {
        log_error grid with id=$id not exists
        return -code error "NOT_EXISTS"
    }
    set rr [getGrid $id]

    if {!$noCheck} {
        set nameList [dict keys $setup]
        set allMute 1
        foreach name $nameList {
            if {[lsearch -exact $_muteUserInputField $name] < 0} {
                set allMute 0
                break
            }
        }

        if {!$allMute && ![$rr getEditable]} {
            log_error reset it to setup user input.
            return -code error CANNOT_MODIFY
        }
    }

    set result [$rr setUserInput $setup $omega]
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
        $snapshot deleteItem $id
    }

    if {$removePersistent} {
        if {[catch {$grid removePersistent} errMsg]} {
            puts "grid $grid removePersistent: $errMsg"
        }
    }
    delete object $grid
    set index [lsearch -exact $lo_gridList $grid]
    if {$index >= 0} {
        set lo_gridList [lreplace $lo_gridList $index $index]
    } else {
        puts "SEVERE delete grid, not found in lo_gridList"
    }

    #generateGridMap
    dict unset _gridIdMap       $id
    dict unset _gridSnapshotMap $id

    set _needWrite 1

    return $index
}
body GridGroup::GridGroupBase::_reset { {removePersistent 0} } {
    if {[catch {_clear_all $removePersistent} errMsg]} {
        log_warning clear_all failed in reset: $errMsg
    }

    if {$removePersistent} {
        if {[catch {
            file delete -force $_path
        } errMsg]} {
            log_warning delete $_path for $this failed: $errMsg
        }
    }
    set _topDirectory ""
    set _path ""
    set _groupId -1

}
body GridGroup::GridGroupBase::_clear_all { {removePersistent 0} } {
    foreach grid $lo_gridList {
        if {[catch {
            set id [$grid getId]
            set snapshotId [$grid getDefaultSnapshotId]
            if {![catch {dict get $_snapshotIdMap $snapshotId} snapshot]} {
                $snapshot deleteItem $id
            }
            if {$removePersistent} {
                if {[catch {$grid removePersistent} errMsg]} {
                    puts "grid $grid removePersistent: $errMsg"
                }
            }
        } errMsg]} {
            log_warning clean up grid $grid failed: $errMsg
        }
        delete object $grid
    }
    set lo_gridList ""
    foreach ss $lo_snapshotList {
        if {$removePersistent} {
            if {[catch {$ss removePersistent} errMsg]} {
                puts "snapshot $ss removePersistent: $errMsg"
            }
        }
        delete object $ss
    }
    set lo_snapshotList ""
    set m_snapshotSeqNum 1

    set _snapshotIdMap ""
    set _gridIdMap ""
    set _gridSnapshotMap ""
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

    ### addGrid may be called by addGroup and skip sending operation update
    public method addGrid { sendingUpdate \
    snapshotId orig geo grid nodes param cx cy x y z \
    user crystalSts screeningParm }

    public method modifyGrid { id orig geo grid nodes }
    public method modifyGridParameter { id param }
    public method modifyGridUserInput { id setup omega}
    public method modifyGridSnapshotId { id snapshotId }
    public method setDetectorModeAndFileExt { id mode ext }
    public method deleteGrid { id {forced 0} }
    public method resetGrid { id }
    public method clearGridIntermediaResults { id }

    ## clearAll just delete all grids and snapshots, but the group itself
    ## is OK.
    public method clearAll { {skip_update 0} }
    ## reset will do more than clearAll, it will set it back to
    ## before loading from file, groupId == -1.
    ## filePath == ""
    public method reset { } {
        ### no operation update
        _reset 1
    }

    public method flipGridNode { id row column }
    public method flipGridNodeBySequence { id seq }
    public method flipCrystalNode { id row column omega }
    public method flipCrystalPhiNode { id row column }
    public method setCrystalAllPhiNode { id value }
    public method getGridNodeSequenceNumberFromIndex { id index }
    public method getGridNodeLabel { id index }

    public method getGridDictForRunCalculator { id }
    public method getGridCollectedPhiRange { id }
    public method getGridInputPhiRange { id }

    ### for collecting
    public method getGridNextNode { id currentNode }
    public method getGridNextPhiNode { id currentNode }
    public method getGridNodePosition { id seq }
    public method getGridNodeStatusBySequence { id seq }
    public method getGridPhiNodeStatusBySequence { id seq }
    public method getOnGridMovePosition { id ux uy index }
    public method getGridStatus { id }
    public method getGridUserInput { id }
    public method getGridEnergyUsed { id }
    public method getGridStrategyNodeSequence { id }
    #####################
    public method getGridCamera { id }
    public method setGridBeamCenter { id x y }
    public method setGridStatus { id status }
    public method setGridNodeStatus { id index status }
    public method setGridNodeStatusBySequence { id seq status }
    public method setGridPhiNodeStatusBySequence { id seq status }
    public method setGridCurrentNodeStatusBySequence { id seq status}
    public method setGridEnergyUsed { id e }
    public method setGridSequenceList { id seq2idx idx2seq }
    public method generateGridSequenceList { id }
    ### for crystal run
    public method setGridNextFrame { id nextFrame }
    public method getGridNextFrame { id }

    public method getGridCenterPosition { id }
    public method getGridSize { id }
    public method getGridNumImageDone { id }
    public method getGridNumImageNeed { id }
    public method getGridMatrixLog { id numFmt txtFmt }

    public method getGridParameter { id }
    public method getGridForLCLS { id }

    public method getGridCloneInfo { id }
    public method getCrystalSplitInfoList { id }

    public method moveGrid { id horz vert }
    public method moveCrystal { id dx dy dz }
    public method acceptStrategy { id d_strategy omega }

    public method loadL614SampleList { id sampleList }
    public method loadTrapArraySampleList { id sampleList }
    public method setTrapArrayHotSpotRowAndColumn { id rows columns }
    public method addTrapArrayHotSpotRow { id row }
    public method removeTrapArrayHotSpotRow { id row }
    public method addTrapArrayHotSpotColumn { id col }
    public method removeTrapArrayHotSpotColumn { id col }

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
sendingUpdate snapshotId orig geo grid nodes param centerX centerY x y z\
user crystalSts screeningParm \
} {
    set shape [dict get $geo shape]

    ### this call does not care the directory, so fake gridPort
    foreach {id label sortNum prefix} \
    [getNextGridId $shape $user $crystalSts $screeningParm ""] break
    dict set param prefix $prefix

    set old_dir    [dict get $param directory]
    set new_dir    [string map "GRID_LABEL grid$id" $old_dir]
    if {$new_dir != $old_dir} {
        dict set param directory $new_dir
    }

    set obj [_add_grid $snapshotId $id $label $sortNum \
    $orig $geo $grid $nodes $param "" ""]

    $obj setBeamCenter $centerX $centerY
    ### this will generate the sequence map
    $obj saveClosestNodeToBeam $x $y $z

    if {[$obj getShape] == "crystal"} {
        $obj checkExposure
    }

    ### argument  must match _add_grid
    if {$sendingUpdate} {
        #### _add_grid may update these inputs.
        #### It is better to get them from the new grid object.
        foreach {orig geo matrix nodes seq2idx idx2seq} [$obj getProperties] break
        set param [$obj getParameter]
        send_operation_update ADD_GRID $_groupId \
        $snapshotId $id $label $sortNum $orig $geo $grid $nodes $param $seq2idx $idx2seq
    }

    _writeToFile $_path

    return $obj
}
body GridGroup::GridGroup4DCSS::modifyGrid { \
    id orig geo matrix nodes \
} {
    set grid [_modify_grid $id $orig $geo $matrix $nodes "" ""]

    if {[$grid getShape] == "crystal"} {
        set setup [$grid checkExposure]
        if {$setup != ""} {
            send_operation_update MODIFY_USER_INPUT $_groupId $id $setup
        }
    }

    $grid generateSequenceMap
    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break

    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

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
body GridGroup::GridGroup4DCSS::modifyGridUserInput { id setup omega } {
    foreach {bigChange updateGrid} \
    [_modify_userInput $id $setup $omega] break

    if {!$bigChange} {
        ## argument must match _modify_parameter
        send_operation_update MODIFY_USER_INPUT $_groupId \
        $id $setup
    } else {
        set obj [_get_grid $id]
        set param [$obj getParameter]
        send_operation_update MODIFY_USER_INPUT $_groupId \
        $id $param
    }
    if {$updateGrid} {
        set obj [_get_grid $id]
        foreach {orig geo matrix nodes seq2idx idx2seq} \
        [$obj getProperties] break

        ## argument must match _modify_grid
        send_operation_update MODIFY_GRID $_groupId \
        $id $orig $geo $matrix $nodes $seq2idx $idx2seq

        set status [$obj getStatus]
        send_operation_update GRID_STATUS $_groupId $id $status
    }

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
    set index [_delete_grid $id 1 $forced]

    send_operation_update DELETE_GRID $_groupId $id 0 $forced

    _writeToFile $_path

    return $index
}
body GridGroup::GridGroup4DCSS::clearAll { {skip_update 0} } {
    set oldGid $_groupId
    _clear_all 1

    if {!$skip_update} {
        send_operation_update CLEAR_ALL $oldGid
    }

    _writeToFile $_path
}
body GridGroup::GridGroup4DCSS::resetGrid { id } {
    set grid [_get_grid $id]
    foreach {needUpdateStatus needUpdateWholeList}       [$grid reset] break
    foreach {phiNeedUpdateStatus phiNeedUpdateWholeList} \
    [$grid resetPhiOsc] break

    if {$needUpdateStatus || $phiNeedUpdateStatus} {
        set status [$grid getStatus]
        send_operation_update GRID_STATUS $_groupId $id $status
    }

    if {$needUpdateWholeList} {
        set nodeList [$grid getNodeList]
        send_operation_update NODE_LIST $_groupId $id $nodeList
        send_operation_update NEXT_FRAME $_groupId $id 0
    }

    if {$phiNeedUpdateWholeList} {
        set nodeList [$grid getPhiNodeList]
        send_operation_update NODE_LIST_FOR_PHI $_groupId $id $nodeList
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
body GridGroup::GridGroup4DCSS::flipGridNodeBySequence { id seq } {
    set grid [_get_grid $id]
    set index [$grid sequence2index $seq]
    foreach {row col} [$grid getNodeRowAndColumn $index] break
    return [flipGridNode $id $row $col]
}
body GridGroup::GridGroup4DCSS::flipGridNode { id row column } {
    set grid [_get_grid $id]
    set index [$grid getNodeIndex $row $column]
    foreach {needUpdateStatus needUpdateWholeList needUpdateSequence} \
    [$grid flipNode $index] break

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
    if {$needUpdateSequence} {
        foreach {seq2idx idx2seq} [$grid getSequenceList] break
        send_operation_update SEQUENCE_LIST $_groupId $id $seq2idx $idx2seq
    }

    write

    return $index
}
body GridGroup::GridGroup4DCSS::flipCrystalNode { id row column omega } {
    set grid [_get_grid $id]
    if {$grid == ""} {
        return -1
    }

    set index [$grid getNodeIndex $row $column]
    if {![$grid OKToFlipCrystalNode $index]} {
        return -1
    }
    set result [$grid flipNode $index]
    if {$result == ""} {
        return -1
    }

    set setup [$grid updateAfterCrystalNodeFlip $omega]

    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break
    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

    if {$setup != ""} {
        send_operation_update MODIFY_USER_INPUT $_groupId $id $setup
    }

    set status [$grid getStatus]
    send_operation_update GRID_STATUS $_groupId $id $status

    write

    return $index
}
body GridGroup::GridGroup4DCSS::flipCrystalPhiNode { id row column } {
    set grid [_get_grid $id]
    set index [$grid getNodeIndex $row $column]
    foreach {needUpdateStatus needUpdateParam} \
    [$grid flipCrystalPhiNode $index] break

    if {$needUpdateStatus} {
        set status [$grid getStatus]
        send_operation_update GRID_STATUS $_groupId $id $status
    }

    ### let's always update the parameters.
    set setup [$grid getParamForFlipCrystalPhiNodeUpdate]
    send_operation_update MODIFY_USER_INPUT $_groupId $id $setup

    set nodeStatus [$grid getPhiNodeStatus $index]
    send_operation_update NODE_FOR_PHI $_groupId $id $index $nodeStatus

    write

    return $index
}
body GridGroup::GridGroup4DCSS::setCrystalAllPhiNode { id value } {
    set grid [_get_grid $id]
    foreach {needUpdateStatus needUpdateParam} \
    [$grid setCrystalAllPhiNode $value] break

    if {$needUpdateStatus} {
        set status [$grid getStatus]
        send_operation_update GRID_STATUS $_groupId $id $status
    }

    ### let's always update the parameters.
    set setup [$grid getParamForFlipCrystalPhiNodeUpdate]
    send_operation_update MODIFY_USER_INPUT $_groupId $id $setup

    send_operation_update NODE_LIST_FOR_PHI $_groupId $id [$grid getPhiNodeList]

    write

    return OK
}
body GridGroup::GridGroup4DCSS::setGridStatus { id status } {
    set grid [_get_grid $id]
    if {![$grid setStatus $status]} {
        return
    }

    send_operation_update GRID_STATUS $_groupId $id $status

    write
}
body GridGroup::GridGroup4DCSS::getGridNextFrame { id } {
    set grid [_get_grid $id]

    return [$grid getNextFrame]
}
body GridGroup::GridGroup4DCSS::setGridNextFrame { id nextFrame } {
    set grid [_get_grid $id]
    if {![$grid setNextFrame $nextFrame]} {
        return
    }

    send_operation_update NEXT_FRAME $_groupId $id $nextFrame

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
body GridGroup::GridGroup4DCSS::getGridNodeStatusBySequence { id seq } {
    set grid [_get_grid $id]
    set index [$grid sequence2index $seq]

    return [$grid getNodeStatus $index]
}
body GridGroup::GridGroup4DCSS::getGridPhiNodeStatusBySequence { id seq } {
    set grid [_get_grid $id]
    set index [$grid sequence2index $seq]

    return [$grid getPhiNodeStatus $index]
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
body GridGroup::GridGroup4DCSS::setGridPhiNodeStatusBySequence { \
    id seq status \
} {
    set grid [_get_grid $id]
    set index [$grid sequence2index $seq]

    if {![$grid setPhiNodeStatus $index $status]} {
        return
    }

    send_operation_update NODE_FOR_PHI $_groupId $id $index $status

    write
}
body GridGroup::GridGroup4DCSS::setGridCurrentNodeStatusBySequence { \
    id seq status \
} {
    set grid [_get_grid $id]
    set index [$grid sequence2index $seq]

    if {![$grid setCurrentNodeStatus $index $status]} {
        return
    }

    send_operation_update CURRENT_NODE $_groupId $id $index $status

    write
}
body GridGroup::GridGroup4DCSS::setGridSequenceList { id seq2idx idx2seq } {
    set grid [_get_grid $id]
    if {![$grid setSequenceList $seq2idx $idx2seq]} {
        return
    }

    send_operation_update SEQUENCE_LIST $_groupId $id $seq2idx $idx2seq

    write
}
body GridGroup::GridGroup4DCSS::generateGridSequenceList { id } {
    set grid [_get_grid $id]
    $grid generateSequenceMap
    foreach {seq2idx idx2seq} [$grid getSequenceList] break

    send_operation_update SEQUENCE_LIST $_groupId $id $seq2idx $idx2seq

    write
}
body GridGroup::GridGroup4DCSS::getGridStatus { id } {
    set grid [_get_grid $id]
    return [$grid getStatus]
}
body GridGroup::GridGroup4DCSS::getGridCamera { id } {
    set grid [_get_grid $id]
    return [$grid getCamera]
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
body GridGroup::GridGroup4DCSS::getGridNextPhiNode { id current } {
    set grid [_get_grid $id]
    return [$grid getNextPhiNode $current]
}
body GridGroup::GridGroup4DCSS::getGridNodeSequenceNumberFromIndex { id index } {
    set grid [_get_grid $id]
    return [$grid indexToSequence $index]
}
body GridGroup::GridGroup4DCSS::getGridNodePosition { id seq } {
    set grid [_get_grid $id]
    return [$grid getNodePosition $seq]
}
body GridGroup::GridGroup4DCSS::getGridStrategyNodeSequence { id } {
    set grid [_get_grid $id]
    return [$grid getStrategyNode]
}
body GridGroup::GridGroup4DCSS::getGridDictForRunCalculator { id } {
    if {[catch {_get_grid $id} grid]} {
        return ""
    }
    return [$grid createDictForRunCalculator]
}
body GridGroup::GridGroup4DCSS::getGridCollectedPhiRange { id } {
    if {[catch {_get_grid $id} grid]} {
        return ""
    }
    return [$grid getCollectedPhiRange]
}
body GridGroup::GridGroup4DCSS::getGridInputPhiRange { id } {
    if {[catch {_get_grid $id} grid]} {
        return 0
    }
    return [$grid getInputPhiRange]
}
body GridGroup::GridGroup4DCSS::getGridNodeLabel { id index } {
    set grid [_get_grid $id]
    return [$grid getNodeLabel $index]
}
body GridGroup::GridGroup4DCSS::getOnGridMovePosition { id ux uy index } {
    set grid [_get_grid $id]
    return [$grid getMovePosition $ux $uy $index]
}
body GridGroup::GridGroup4DCSS::getGridCenterPosition { id } {
    set grid [_get_grid $id]
    return [$grid getCenterPosition]
}
body GridGroup::GridGroup4DCSS::getGridSize { id } {
    set grid [_get_grid $id]
    return [$grid getSize]
}
body GridGroup::GridGroup4DCSS::getGridNumImageDone { id } {
    set grid [_get_grid $id]
    return [$grid getNumImageDone]
}
body GridGroup::GridGroup4DCSS::getGridNumImageNeed { id } {
    set grid [_get_grid $id]
    return [$grid getNumImageNeed]
}
body GridGroup::GridGroup4DCSS::getGridParameter { id } {
    set grid [_get_grid $id]
    return [$grid getParameter]
}
body GridGroup::GridGroup4DCSS::getGridCloneInfo { id } {
    set grid [_get_grid $id]
    return [$grid getCloneInfo]
}
body GridGroup::GridGroup4DCSS::getCrystalSplitInfoList { id } {
    set grid [_get_grid $id]
    return [$grid getSplitInfoList]
}
body GridGroup::GridGroup4DCSS::getGridForLCLS { id } {
    set grid [_get_grid $id]
    return [$grid getForLCLS]
}
body GridGroup::GridGroup4DCSS::setGridBeamCenter { id x y } {
    set grid [_get_grid $id]
    $grid setBeamCenter $x $y
    write
}
body GridGroup::GridGroup4DCSS::setGridEnergyUsed { id e } {
    set grid [_get_grid $id]
    if {[$grid getShape] == "crystal"} {
        ## crystal has energy or energy list in the parameter
        return
    }
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
    $grid generateSequenceMap
    send_operation_update NODE_LIST $_groupId $id $newNodeList
    foreach {seq2idx idx2seq} [$grid getSequenceList] break
    send_operation_update SEQUENCE_LIST $_groupId $id $seq2idx $idx2seq

    write
}
body GridGroup::GridGroup4DCSS::setTrapArrayHotSpotRowAndColumn { \
    id rows columns \
} {
    set grid [_get_grid $id]

    if {![$grid setHotSpotRowAndColumn $rows $columns]} {
        log_warning no change
        return OK
    }

    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break
    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

    write
    return DONE
}
body GridGroup::GridGroup4DCSS::addTrapArrayHotSpotRow { id row } {
    set grid [_get_grid $id]

    if {![$grid addHotSpotRow $row]} {
        return OK
    }

    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break
    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

    write
    return DONE
}
body GridGroup::GridGroup4DCSS::removeTrapArrayHotSpotRow { id row } {
    set grid [_get_grid $id]

    if {![$grid removeHotSpotRow $row]} {
        return OK
    }

    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break
    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

    write
    return DONE
}
body GridGroup::GridGroup4DCSS::addTrapArrayHotSpotColumn { id col } {
    set grid [_get_grid $id]

    if {![$grid addHotSpotColumn $col]} {
        return OK
    }

    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break
    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

    write
    return DONE
}
body GridGroup::GridGroup4DCSS::removeTrapArrayHotSpotColumn { id col } {
    set grid [_get_grid $id]

    if {![$grid removeHotSpotColumn $col]} {
        return OK
    }

    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break
    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

    write
    return DONE
}
body GridGroup::GridGroup4DCSS::loadTrapArraySampleList { id sampleList } {
    set grid [_get_grid $id]

    set shape [$grid getShape]
    if {$shape != "trap_array"} {
        log_error shape=$shape not trap_array
        return -code error NOT_TRAP_ARRAY
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
        set row [lsearch -exact {A B C D E F G H} $letter]
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
    $grid generateSequenceMap
    send_operation_update NODE_LIST $_groupId $id $newNodeList
    foreach {seq2idx idx2seq} [$grid getSequenceList] break
    send_operation_update SEQUENCE_LIST $_groupId $id $seq2idx $idx2seq

    write
}
body GridGroup::GridGroup4DCSS::moveGrid { id horz vert } {
    set grid [_get_grid $id]

    $grid moveCenter $horz $vert
    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break
    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

    write
}
body GridGroup::GridGroup4DCSS::moveCrystal { id dx dy dz } {
    set grid [_get_grid $id]

    $grid moveCrystal $dx $dy $dz
    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break
    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

    write
}
body GridGroup::GridGroup4DCSS::acceptStrategy { id d_strategy omega } {
    set grid [_get_grid $id]

    set setup [$grid acceptStrategy $d_strategy $omega]
    foreach {orig geo matrix nodes seq2idx idx2seq} [$grid getProperties] break
    ## argument must match _modify_grid
    send_operation_update MODIFY_GRID $_groupId \
    $id $orig $geo $matrix $nodes $seq2idx $idx2seq

    send_operation_update MODIFY_USER_INPUT $_groupId $id $setup

    write
}
