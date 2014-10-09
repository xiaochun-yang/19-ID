package provide DCSRunCalculatorForGridCrystal 1.0

package require Itcl
package require dict
#namespace import ::itcl::*

package require DCSConfig

### contents of dictionary:
### num_node
### run_label
### file_root
### directory
### start_frame
### start_angle
### end_frame
### delta
### wedge_size
### energy_list
### inverse_beam (0 or 1)

class ::DCS::RunCalculatorForGridCrystal {
    ## raw dict
    private variable m_dContents

    ### retrieve from m_dContents
    private variable m_nodeSeq [list 1]
    ### following 2 are derived from m_nodeSeq
    private variable m_numNodeSelected 1
    ### this contains only selected node.
    private variable m_nodeIdx2Seq [list 0]

    private variable m_runLabel ""
    private variable m_prefix ""
    private variable m_startFrame 1
    private variable m_startAngle 0.0
    private variable m_endFrame   1
    private variable m_delta      1.0
    private variable m_wedgeSize  180.0
    private variable m_energyList 12000.0
    private variable m_inverseOn 0

    #### calculated from m_dContents
    private variable m_numEnergy 1
    private variable m_reverseOffset 180
    private variable m_numPhiPerNode 1
    private variable m_numFramePerNode 1
    private variable m_numPhiPerFullWedge 1
    private variable m_numFrameFullWedge 1
    private variable m_totalFrames 1

    ### to let runSequenceView can use this the same way \
    ### as RunSequenceCalculator.
    public method getField { name } {
        return [dict get $m_dContents $name]
    }

    public method update { dContents_ }
    public method getMotorPositionsAtIndex { index_ }
    public method getTotalFrames { } { return $m_totalFrames }

    public method getCenterPhiForNode { nodeSequence }

    public method getFrameLabelForNodeList { }

    constructor { } {
        set m_dContents [dict create]
    }

}
body ::DCS::RunCalculatorForGridCrystal::update { dContents_ } {
    set m_dContents $dContents_

    set m_nodeSeq    [dict get $m_dContents node_sequence]
    set m_runLabel   [dict get $m_dContents run_label]
    set m_prefix     [dict get $m_dContents prefix]
    set m_startFrame [dict get $m_dContents start_frame]
    set m_startAngle [dict get $m_dContents start_angle]
    set m_endFrame   [dict get $m_dContents end_frame]
    set m_delta      [dict get $m_dContents delta]
    set m_wedgeSize  [dict get $m_dContents wedge_size]
    set m_energyList [dict get $m_dContents energy_list]
    set m_inverseOn  [dict get $m_dContents inverse_beam]

    set m_numNodeSelected 0
    set m_nodeIdx2Seq [list]
    set seq 0
    foreach node $m_nodeSeq {
        if {$node == "1"} {
            incr m_numNodeSelected
            lappend m_nodeIdx2Seq $seq
        }

        incr seq
    }
    if {$m_numNodeSelected < 1} {
        set m_numNodeSelected 1
        set m_nodeIdx2Seq [list 0]
    }

    set m_startFrame [expr int($m_startFrame)]
    set m_startAngle [expr double($m_startAngle)]
    set m_endFrame   [expr int($m_endFrame)]
    set m_delta      [expr double($m_delta)]
    set m_wedgeSize  [expr double($m_wedgeSize)]
    set m_inverseOn  [expr int($m_inverseOn)]



    set m_numEnergy  [llength $m_energyList]

    set numPhi [expr $m_endFrame - $m_startFrame + 1]
    set m_reverseOffset 180
    while {$m_reverseOffset < $numPhi} {
        incr m_reverseOffset 360
    }

    set m_numPhiPerNode      [expr int(ceil(double($numPhi) / $m_numNodeSelected))]
    set m_numPhiPerFullWedge [expr int(($m_wedgeSize + 0.0000001) / $m_delta)]

    set m_totalFrames       [expr $numPhi * $m_numEnergy]
    set m_numFramePerNode   [expr $m_numPhiPerNode * $m_numEnergy]
    set m_numFrameFullWedge [expr $m_numPhiPerFullWedge * $m_numEnergy]
    if {$m_inverseOn} {
        set m_totalFrames        [expr 2 * $m_totalFrames]
        set m_numFramePerNode    [expr 2 * $m_numFramePerNode]
        set m_numFrameFullWedge  [expr 2 * $m_numFrameFullWedge]
    }

    #puts "per node: phi: $m_numPhiPerNode frame: $m_numFramePerNode"
    #puts "per wedge: phi $m_numPhiPerFullWedge frame: $m_numFrameFullWedge"
}
body ::DCS::RunCalculatorForGridCrystal::getFrameLabelForNodeList { } {
    set frameFormat [::config getFrameCounterFormat]

    set result [list]
    set i 0
    foreach node $m_nodeSeq {
        if {$node != "1"} {
            lappend result -1
        } else {
            set num [expr $m_startFrame + $i * $m_numFramePerNode]
            set label [format $frameFormat $num]
            lappend result $label
            incr i
        }
    }

    return $result
}
body ::DCS::RunCalculatorForGridCrystal::getCenterPhiForNode { \
seqNode } {

    set idxNode [lsearch -exact $m_nodeIdx2Seq $seqNode]
    if {$idxNode < 0} {
        return -code error wrong_node_sequence
    }

    return [expr $m_startAngle + $m_delta * ($idxNode + 0.5) * $m_numFramePerNode]
}
body ::DCS::RunCalculatorForGridCrystal::getMotorPositionsAtIndex { \
index_ } {
    set index_ [expr int($index_)]
    #if {$index_ % 10 == 0} {
    #puts "getMotorPositionsAtIndex: index=$index_"
    #}

    ### which node, works for last node not full
    set idxNode   [expr $index_ / $m_numFramePerNode]
    set idxInNode [expr $index_ % $m_numFramePerNode]
    set numFrameThisNode $m_numFramePerNode
    if {$idxNode >= $m_numNodeSelected - 1} {
        ## last node
        set numFrameThisNode \
        [expr $m_totalFrames - $m_numFramePerNode * $idxNode]
    }
    #if {$index_ % 10 == 0} {
    #puts "node=$idxNode, in node: frames: $numFrameThisNode offset $idxInNode"
    #}

    ### which wedge in the node, works for last node not full and
    ### last wedge not full.
    set idxWedge   [expr $idxInNode / $m_numFrameFullWedge]
    set idxInWedge [expr $idxInNode % $m_numFrameFullWedge]
    set numWedgeThisNode \
    [expr ($numFrameThisNode + $m_numFrameFullWedge - 1) / $m_numFrameFullWedge]
    #if {$index_ % 10 == 0} {
    #puts "wedge=$idxWedge inNode: wedges: $numWedgeThisNode offset=$idxInWedge"
    #}

    ### which energy
    set totalFrameInThisWedge $m_numFrameFullWedge
    if {$idxWedge >= $numWedgeThisNode - 1} {
        set totalFrameInThisWedge \
        [expr $numFrameThisNode - $m_numFrameFullWedge * $idxWedge]
    }
    
    set numFramePerEnergyInThisWedge \
    [expr $totalFrameInThisWedge / $m_numEnergy]

    set idxEnergy [expr $idxInWedge / $numFramePerEnergyInThisWedge]

    set idxInEnergy [expr $idxInWedge % $numFramePerEnergyInThisWedge]

    #if {$index_ % 10 == 0} {
    #puts "energy=$idxEnergy, in wedge, frames:$totalFrameInThisWedge"
    #puts "numFramePerEnergy: $numFramePerEnergyInThisWedge"
    #}
    
    ### now create result
    set startIdxPhiNode  [expr $idxNode * $m_numPhiPerNode]
    set startIdxPhiWedge \
    [expr $startIdxPhiNode + $idxWedge * $m_numPhiPerFullWedge]

    set idxPhi       [expr $startIdxPhiWedge + $idxInEnergy]
    set myPhi        [expr $m_startAngle + $m_delta * $idxPhi]
    set myFrameLabel [expr $m_startFrame + $idxPhi]
    set continuePhiInThisWedge $numFramePerEnergyInThisWedge

    set half [expr $numFramePerEnergyInThisWedge / 2]
    ### now inverse beam on or not
    if {$m_inverseOn && $idxInEnergy >= $half} {
        #puts "in wedege idx=$idxInWedge >= half $half"
        set idxPhi [expr $idxPhi - $half]
        set myPhi        [expr $m_startAngle + $m_delta * $idxPhi + 180.0]
        set myFrameLabel [expr $m_startFrame + $idxPhi + $m_reverseOffset]
    }
    if {$m_inverseOn} {
        set continuePhiInThisWedge [expr $numFramePerEnergyInThisWedge / 2]
    }
    set myNumPhiContinue \
    [expr $continuePhiInThisWedge - $idxInWedge % $continuePhiInThisWedge]

    #if {$index_ % 10 == 0} {
    #puts "phi idx=$idxPhi phi=$myPhi label=$myFrameLabel"
    #puts "continuous phi: $myNumPhiContinue"
    #}

    set nodeSeq [lindex $m_nodeIdx2Seq $idxNode]

    set nodeLabel P[expr $nodeSeq + 1]

    set myEnergy [lindex $m_energyList $idxEnergy]
    set energyLabel E[expr $idxEnergy + 1]

    set iE  [expr int($myEnergy)]
    set iME [expr round($myEnergy * 1000) % 1000]
    set sub_dir [format "%s_%dd%03d" $energyLabel $iE $iME]

    set frameFormat [::config getFrameCounterFormat]
    #set frameFormat %05d
    set fileRootNoIndex $m_prefix
    if {$m_runLabel != ""} {
        append fileRootNoIndex _$m_runLabel
    }

    ### 06/27/13 decided to take out node position from file name.
    ### Instead, we will add node position to the log.
    ### This way, the diffraction image viewer will be easy to 
    ### go next and go previous.
    ### User can look at the log file to find out the node position
    ### for each image if they need it.
    #if {$m_numNodeSelected > 1} {
    #    append fileRootNoIndex _$nodeLabel
    #}

    if {$m_numEnergy > 1} {
        append fileRootNoIndex _$energyLabel
    }
    set filename ${fileRootNoIndex}_[format $frameFormat $myFrameLabel]

    return [format "%s %d %6.2f %8.2f %s %d %d" \
    $filename $nodeSeq $myPhi $myEnergy $fileRootNoIndex \
    $myFrameLabel $myNumPhiContinue]
}

#set myInput [dict create]
#dict set myInput num_node 4
#dict set myInput run_label    "3"
#dict set myInput prefix       "crystalA1"
#dict set myInput start_frame  11
#dict set myInput start_angle  5.0
#dict set myInput end_frame    100
#dict set myInput delta        1.0
#dict set myInput wedge_size   18.0
#dict set myInput energy_list  [list 12000.0 13000.0]
#dict set myInput energy_list  12000.0
#dict set myInput inverse_beam 1

#::DCS::RunCalculatorForGridCrystal mymy

#mymy update $myInput

#set totalFrame [mymy getTotalFrames]
#puts "total : $totalFrame"

#for {set i 0} {$i < $totalFrame} {incr i} {
#    puts "[mymy getMotorPositionsAtIndex $i]"
#}

