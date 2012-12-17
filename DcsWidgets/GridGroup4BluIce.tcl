package provide DCSGridGroup4BluIce 1.0

package require DCSGridGroupBase

namespace import ::itcl::*

#### beamsize info: width height {collimator ...}
class ComboBeamSizeWrapper {
    inherit ::DCS::Component
    ### inherit Widget so we can use itk_option

    public variable honorCollimator 1 {
        if {$honorCollimator} {
            ::mediator register $this ::device::user_collimator_status \
            contents handleUserCollimator

            ::mediator register $this ::device::_collimator_status \
            contents handleCurrentCollimator
        } else {
            ::mediator unregister $this ::device::user_collimator_status \
            contents
            ::mediator unregister $this ::device::_collimator_status \
            contents
        }
    }

    public method getBeamSize { } { return $m_beamsize }

    public method handleSystemBeamSizeUpdate { - ready_ - - - } {
        if {!$ready_} {
            return
        }
        updateBeamSize
    }

    public method handleUserCollimator    { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_sysUserCollimatorStatus $contents_
        updateBeamSize
    }
    public method handleCurrentCollimator { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_sysUserCollimatorStatus $contents_
        updateBeamSize
    }

    public method handleDesiredBeamSizeUpdate { - ready_ - info_ - } {
        if {!$ready_} {
            return
        }
        set ll [llength $info_]
        if {$ll < 2} {
            return
        }
        #puts "handle deisred beamSize update: $info_"
        setBeamSizeInfo $info_
    }
    ## or
    public method setBeamSizeInfo { info_ } {
        set m_comboInfo $info_
        updateBeamSize
    }

    private method getSystemBeamSize { }
    private method getDesiredBeamSize { }
    private method updateBeamSize { }

    private variable m_beamsize [list 0.1 0.1 white]

    private variable m_comboInfo [list 100.0 100.0 [list 0 -1 2.0 2.0]]

    private variable m_sysUserCollimatorStatus    [list 0 -1 2.0 2.0]
    private variable m_sysCurrentCollimatorStatus [list 0 -1 2.0 2.0]

    constructor { args } {
        ::DCS::Component::constructor {
            beam_size getBeamSize
        }
    } {
        global gMotorBeamWidth
        global gMotorBeamHeight

        announceExist

        ::mediator register $this ::device::$gMotorBeamWidth scaledPosition \
        handleSystemBeamSizeUpdate
        ::mediator register $this ::device::$gMotorBeamHeight scaledPosition \
        handleSystemBeamSizeUpdate
    }
}
body ComboBeamSizeWrapper::getSystemBeamSize { } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    set userCollimator [lindex $m_sysUserCollimatorStatus 0]
    set currCollimator [lindex $m_sysCurrentCollimatorStatus 0]

    if {$honorCollimator \
    && ($userCollimator == "1" || $currCollimator == "1") \
    } {
        if {$userCollimator} {
            foreach {isMicro index width height} \
            $m_sysUserCollimatorStatus break
        } else {
            foreach {isMicro index width height} \
            $m_sysCurrentCollimatorStatus break
        }
    } else {
        set width  [::device::$gMotorBeamWidth  cget -scaledPosition]
        set height [::device::$gMotorBeamHeight cget -scaledPosition]
        set index -1
    }
    return [list $width $height $index]
}
body ComboBeamSizeWrapper::getDesiredBeamSize { } {
    foreach {w h collimator} $m_comboInfo break
    set isMicro [lindex $collimator 0]

    if {$honorCollimator && $isMicro} {
        foreach {isMicro index width height} $collimator break
    } else {
        ### to mm
        set width  [expr $w / 1000.0]
        set height [expr $h / 1000.0]
        set index -1
    }
    return [list $width $height $index]
}
body ComboBeamSizeWrapper::updateBeamSize { } {
    set sysSize     [getSystemBeamSize]
    set desiredSize [getDesiredBeamSize]

    #puts "sysSize $sysSize desired: $desiredSize"

    foreach {sysW sysH sysIndex} $sysSize break
    foreach {dsrW dsrH dsrIndex} $desiredSize break
    if {$sysIndex != $dsrIndex \
    || abs($sysW - $dsrW) >= 0.001 \
    || abs($sysH - $dsrH) >= 0.001 \
    } {
        set color red
    } else {
        set color white
    }
    foreach {old_w old_h old_color} $m_beamsize break
    if {abs($dsrW - $old_w) >= 0.0001 \
    ||  abs($dsrH - $old_h) >= 0.0001 \
    || $color != $old_color \
    } {
        set m_beamsize [list $dsrW $dsrH $color]
        updateRegisteredComponents beam_size
        #puts "updated beam_size"
    }
}

#### interface style change:
#### We want support mulitple GUI by single one GridGroup4BluIce.
#### So, we have use "registerViewWidget"
#### "setSnapshotWidget" anymore.

class GridGroup::GridGroup4BluIce {
    inherit ::GridGroup::GridGroupBase ::DCS::Component

    private variable m_beamsizeWrapper ""

    private variable m_deviceFactory ""
    private variable m_objGridGroupConfig ""
    private variable m_objGridGroupFlip ""
    private variable m_objCollectGrid ""

    private variable m_objLatestUserSetup ""

    ## d_currentGridIndex will survive across load from file.
    ## and it will be saved across even switching group number
    ## one per group number
    private variable d_currentGridIndex ""
    private variable m_currentGrid ""
    #### currentGrid position in the list.
    private variable m_currentGridIndex -1

    private variable m_registeredImageWidgets ""

    ## this widgets must export instant_beam_size
    ## must handle current_grid grid_list and shape
    private variable m_gridListWidget ""

    ### how to update it:
    ### 1. latest user setup (now)
    ### 2. last grid
    ### 3. current grid
    private variable d_userSetupForNextGrid ""

    #### following 3 are created from d_userSetupForNextGrid
    private variable d_parameterForNextGrid ""
    ### in microns
    private variable m_defaultCellWidth 50.0
    private variable m_defaultCellHeight 50.0

    private variable m_gridBeamsize "0.01 0.01 white"
    ### from m_gridListWidget
    private variable m_instantBeamsize  "0.01 0.01 white"


    ### save a copy of the state in the string "gridGroupXX".
    ### It will be used to check resettable......
    private variable m_runState "inactive"

    private variable m_numField Spots
    private variable m_contourField Spots
    private variable m_contourLevelList "10 25 50 75 90"

    public method switchGroupNumber { new_number {forced_refresh 0} }

    ### only need one
    public method clearCurrentGrid { {caller_ ""} }
    ### called be "*" tab
    public method prepareAddGrid { }

    public method setWidgetToolMode { mode }

    public method moveSnapshotToTop { snapshotId }
    public method setCurrentGridIndex { index }
    public method getCurrentGridIndex { }
    public method getGridIndex { id }
    public method getCurrentGridId { }
    public method getCurrentSnapshotId { } {
        return [getSnapshotIdForGrid [getCurrentGridId]]
    }
    public method getCurrentGridLabel { }
    ### all information needed by GUI to display the current grid, including:
    ### grid center, size, beam setup.
    public method getShapeFromGUI { }
    public method getCurrentGridInfo { }
    public method getCurrentGridNodeListInfo { }
    public method getCurrentGridBeamSizeInfo { }
    public method getSnapshotListInfo { }
    public method getGridListInfo { }

    ## for attributes
    public method getCurrentGridEditable { }
    public method getCurrentGridResettable { }
    public method getCurrentGridDeletable { }
    public method getCurrentGridRunnable { }


    public method getDefaultCellWidth { }  { return $m_defaultCellWidth }
    public method getDefaultCellHeight { } { return $m_defaultCellHeight }
    public method getDefaultParameter { }  { 
        refreshParameter
        return $d_parameterForNextGrid
    }
    public method getDefaultUserSetup { }  {
        refreshParameter
        set result $d_userSetupForNextGrid
        foreach name {prefix directory} {
            set v [dict get $d_parameterForNextGrid $name]
            dict set result $name $v
        }
        dict set result summary "parameters for new raster"
        return $result
    }

    public method getBeamSize { } {
        if {$m_gridListWidget == ""} {
            return $m_gridBeamsize
        } else {
            return $m_instantBeamsize
        }
    }

    ############ for snapshot display
    ############ GUI will display max 2.
    ############ wd has to be a derived class from 
    #### GridGroup::VideoImageDisplayHolder
    public method registerImageDisplayWidget { wd }
    public method unregisterImageDisplayWidget { wd }
    #### they also called by add/delete snapshots.

    ### called by userInput widget
    public method adjustCurrentGrid { param }

    public method setGridListWidget { wd }
    ### select current grid from gridList
    public method selectGridIndex { index }

    public method handleOperationEvent { msg_ }
    public method handleStringEvent { name_ ready_ - contents_ - }
    public method handleGUICurrentGridChange { - ready_ - contents_ - }
    public method handleGUIToolModeChange { - ready_ - contents_ - }
    public method handleInstantBeamSizeChange { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        #puts "handleInstantBeamSizeChange $contents_"
        set m_instantBeamsize $contents_
        updateBeamSize
    }
    public method handleGridBeamsizeChange { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_gridBeamsize $contents_
        if {$m_gridListWidget == ""} {
            updateBeamSize
        }
    }
    public method handleLatestSetupChange { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set d_userSetupForNextGrid [eval dict create $contents_]
        if {[catch {dict get $d_userSetupForNextGrid cell_width} \
        m_defaultCellWidth]} {
            set m_defaultCellWidth 50.0
            puts "no cell_width in setup for next grid"
        }
        if {[catch {dict get $d_userSetupForNextGrid cell_height} \
        m_defaultCellHeight]} {
            set m_defaultCellHeight 50.0
            puts "no cell_height in setup for next grid"
        }
        set d_parameterForNextGrid $d_userSetupForNextGrid
        foreach name [GridGroup::GridBase::getParameterFieldNameList] {
            if {[catch {dict get $d_userSetupForNextGrid $name} v]} {
                log_error parameter $name not found in latest_raster_user_setup
                set v 0
                dict set d_parameterForNextGrid $name $v
            }
        }
        if {[getCurrentGridId] < 0} {
            updateRegisteredComponents current_grid
        }
    }
    public method refreshParameter { } {
        set lb [getNextGridId]
        if {[catch {dict get $d_userSetupForNextGrid prefix} prefix]} {
            log_error parameter prefix not found in latest_raster_user_setup
            set prefix raster$lb
        }
        if {[catch {dict get $d_userSetupForNextGrid directory} directory]} {
            log_error parameter directory not found in latest_raster_user_setup
            set directory raster_dir$lb
        }
        set prefix    [string map "GRID_LABEL $lb" $prefix]
        set directory [string map "GRID_LABEL $lb" $directory]

        set user [::dcss getUser]
        checkUsernameInDirectory directory $user
        dict set d_parameterForNextGrid prefix $prefix
        dict set d_parameterForNextGrid directory $directory
    }

    #### for display contour
    public method setNumberField { sss } {
        set m_numField $sss
        updateRegisteredComponents number_display_field
        switch -exact -- $sss {
            None -
            Frame {
            }
            default {
                set m_contourField $sss
                updateRegisteredComponents contour_display_field
            }
        }
        foreach w $m_registeredImageWidgets {
            if {[catch {
                $w refreshMatrixDisplay
            } errMsg]} {
                puts "failed to refreshMatrixDisplay for $this: $errMsg"
            }
        }
    }
    public method setContourField { sss } {
        set m_contourField $sss
        updateRegisteredComponents contour_display_field
        switch -exact -- $m_numField {
            None -
            Frame {
            }
            default {
                set m_numField $sss
                updateRegisteredComponents number_display_field
            }
        }
        foreach w $m_registeredImageWidgets {
            if {[catch {
                $w refreshMatrixDisplay
            } errMsg]} {
                puts "failed to refreshMatrixDisplay for $this: $errMsg"
            }
        }
    }
    public method setContourLevels { ll } {
        set m_contourLevelList $ll
        updateRegisteredComponents contour_display_level
    }
    public method getNumberField { } { return $m_numField }
    public method getContourField { } { return $m_contourField }
    public method getContourLevels { } { return $m_contourLevelList }

    protected method updateSnapshotDisplay { }
    protected method updateCurrentGrid { }
    protected method updateBeamSize { }
    protected method refreshAll { }

    protected method refreshGridGui { id }
    protected method refreshNodeGui { id index stats }

    protected method getGridLabelListOnThisSnapshot { ss } {
        set result ""
        foreach gridId [$ss getGridIdListDefaultOnThis] {
            set vv grid[getGridLabel $gridId]
            lappend result $vv
        }
        puts "gridNameList for $ss: $result"
        return $result
    }

    constructor { args } {
        ::DCS::Component::constructor {
            shape         { getShapeFromGUI }
            current_grid  { getCurrentGridInfo }
            snapshot_list { getSnapshotListInfo }
            grid_list     { getGridListInfo }
            current_grid_node_list { getCurrentGridNodeListInfo }
            current_grid_beam_size { getCurrentGridBeamSizeInfo }
            number_display_field   { getNumberField }
            contour_display_field { getContourField }
            contour_display_level { getContourLevels }
            current_grid_editable   { getCurrentGridEditable }
            current_grid_resettable { getCurrentGridResettable }
            current_grid_deletable  { getCurrentGridDeletable }
            current_grid_runnable   { getCurrentGridRunnable }
        }
    } {
        set m_deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objGridGroupConfig \
        [$m_deviceFactory createOperation gridGroupConfig]
        set m_objGridGroupFlip \
        [$m_deviceFactory createOperation gridGroupFlip]
        set m_objCollectGrid \
        [$m_deviceFactory createOperation collectGrid]

        $m_objGridGroupConfig registerForAllEvents $this handleOperationEvent
        $m_objGridGroupFlip   registerForAllEvents $this handleOperationEvent
        $m_objCollectGrid     registerForAllEvents $this handleOperationEvent

        set m_objLatestUserSetup \
        [$m_deviceFactory createString latest_raster_user_setup]

        $m_objLatestUserSetup register $this contents handleLatestSetupChange

        for {set i 0} {$i < [getMAXGROUP]} {incr i} {
            set name gridGroup$i
            set obj [$m_deviceFactory getObjectName $name]
            ::mediator register $this $obj contents handleStringEvent
        }
        set m_beamsizeWrapper [ComboBeamSizeWrapper ::\#auto \
        -honorCollimator [$m_deviceFactory operationExists collimatorMove] \
        ]

        eval configure $args
		announceExist

        $this register $m_beamsizeWrapper current_grid_beam_size \
        handleDesiredBeamSizeUpdate

        $m_beamsizeWrapper register $this beam_size handleGridBeamsizeChange
    }
    destructor {
        $m_objGridGroupConfig unregisterForAllEvents $this handleOperationEvent
        $m_objGridGroupFlip   unregisterForAllEvents $this handleOperationEvent
        $m_objCollectGrid     unregisterForAllEvents $this handleOperationEvent
        $m_objLatestUserSetup unregister $this contents handleLatestSetupChange
    }
}
body GridGroup::GridGroup4BluIce::switchGroupNumber { \
    new_number {forced_refresh 0} \
} {
    if {!$forced_refresh && $_groupId == $new_number} {
        return
    }
    if {$_groupId == $new_number} {
        set numChanged 0
    } else {
        set numChanged 1
    }

    set strName gridGroup$new_number
    if {![$m_deviceFactory stringExists $strName]} {
        log_error wrong gridGroup number $new_number
        set _groupId -1
        return
    }

    set obj [$m_deviceFactory getObjectName $strName]
    set contents [$obj getContents]
    foreach {m_runState label file} $contents break

    if {$file == "not_exists"} {
        set path $file
    } else {
        set path [file join [::config getStr gridGroup.directory] $file]
    }
    ## this will set _groupId to new_number
    load $new_number $path

    refreshAll
}
body GridGroup::GridGroup4BluIce::handleStringEvent { \
    name_ ready_ - contents_ - \
} {
    if {!$ready_} {
        return
    }

    ###gridGroupXX
    set groupNum [string range [namespace tail $name_] 9 end]

    if {$groupNum != $_groupId} {
        return
    }
    switchGroupNumber $_groupId 1
}
body GridGroup::GridGroup4BluIce::handleOperationEvent { msg_ } {
    foreach {evType opName opId tag gid} $msg_ break

    if {$evType != "stog_operation_update" || $gid != $_groupId} {
        return
    }

    set args [lrange $msg_ 5 end]

    switch -exact -- $tag {
        ADD_SNAPSHOT {
            set id [lindex $args 0]
            eval _add_snapshot_image $args

            ### current grid update
            #none

            ### snapshot update
            updateRegisteredComponents snapshot_list
            foreach w $m_registeredImageWidgets {
                if {[catch {
                    $w addImageToTop $id $_snapshotIdMap
                } errMsg]} {
                    puts "failed to moveImageToTop for $w: $errMsg"
                }
            }
        }
        DELETE_SNAPSHOT {
            set id [lindex $args 0]
            eval _delete_snapshot_image $args

            ### current grid update
            ### this updateRegisteredComponents
            updateCurrentGrid

            ### snapshot update
            foreach w $m_registeredImageWidgets {
                if {[catch {
                    if {[$w imageShowing $id]} {
                        $w switchGroup \
                        $_groupId $lo_snapshotList $_snapshotIdMap
                    }
                } errMsg]} {
                    puts "failed to delete snapshot for $w: $errMsg"
                }
            }
            updateRegisteredComponents snapshot_list
        }
        ADD_GRID {
            set gg [eval _add_grid $args]

            ### current grid update
            set ll [llength $lo_gridList]
            set index [expr $ll - 1]
            ### this updateRegisteredComponents
            setCurrentGridIndex $index

            ### snapshot update
            foreach w $m_registeredImageWidgets {
                if {[catch {
                    $w addGrid $gg
                } errMsg]} {
                    puts "failed to addGrid for $w: $errMsg"
                }
            }
            updateRegisteredComponents snapshot_list
        }
        MODIFY_GRID {
            set id [lindex $args 0]
            eval _modify_grid $args

            refreshGridGui $id 
        }
        MODIFY_GRID_SNAPSHOT_ID {
            eval _modify_grid_snapshot_id $args

            updateRegisteredComponents snapshot_list
        }
        MODIFY_PARAMETER {
            eval _modify_parameter $args

            updateRegisteredComponents current_grid
            updateRegisteredComponents current_grid_node_list
            updateRegisteredComponents current_grid_beam_size
        }
        MODIFY_USER_INPUT {
            eval _modify_userInput $args
            updateRegisteredComponents current_grid
            updateRegisteredComponents current_grid_node_list
            updateRegisteredComponents current_grid_beam_size
        }
        SET_DETECTOR_MODE_EXT {
            eval _modify_detectorMode_fileExt $args
            ### no GUI update
        }
        DELETE_GRID {
            #puts "DELETE_GRID $args"
            set id [lindex $args 0]
            set index   [getGridIndex $id]
            set current [getCurrentGridIndex]
            #puts "index=$index current=$current"

            eval _delete_grid $args

            ### this updateRegisteredComponents
            updateCurrentGrid

            ### snapshot update
            foreach w $m_registeredImageWidgets {
                if {[catch {
                    $w deleteGrid $id
                } errMsg]} {
                    puts "failed to deleteGrid for $w: $errMsg"
                }
            }

            ### after the deletation, the next grid should become current grid.
            ### that may cross snapshot.  So, it needs following code.
            selectGridIndex $index
            updateRegisteredComponents snapshot_list
        }
        CLEAR_ALL {
            _clear_all
            refreshAll
        }
        GRID_STATUS {
            foreach {id status} $args break
            set grid [_get_grid $id]
            $grid setStatus $status

            ### we may add something trimmer than this.
            refreshGridGui $id 
            updateRegisteredComponents current_grid_editable
            updateRegisteredComponents current_grid_resettable
            updateRegisteredComponents current_grid_deletable
            updateRegisteredComponents current_grid_runnable
        }
        NODE_LIST {
            foreach {id nodeList} $args break
            set grid [_get_grid $id]
            $grid setAllNodes $nodeList

            refreshGridGui $id 
        }
        NODE {
            #puts "get NODE"
            foreach {id index nodeStatus} $args break
            set grid [_get_grid $id]
            $grid setNodeStatus $index $nodeStatus
            refreshNodeGui $id $index $nodeStatus
            #puts "done NODE"
        }
    }
}
body GridGroup::GridGroup4BluIce::handleGUICurrentGridChange { \
    caller_ rdy_ - id_ - \
} {
    #puts "handleGUICurrentGridChange caller=$caller_ ready=$rdy_ id=$id_"
    if {!$rdy_} {
        return
    }
    if {$id_ < 0} {
        if {$m_currentGridIndex < 0} {
            return
        }
        clearCurrentGrid $caller_
        return
    }

    set idx -1
    foreach grid $lo_gridList {
        incr idx
        set gid [$grid getId]
        if {$gid == $id_} {
            set ssId [getSnapshotIdForGrid $gid]
            ### this updateRegisteredComponents
            setCurrentGridIndex $idx
            foreach w $m_registeredImageWidgets {
                #puts "handleGUICurrentGridChange w=$w"
                ## this check is not necessary for now.
                ## caller has flag to ignore the callback by itself.
                if {$w != $caller_} {
                    if {[catch {
                        $w setCurrentGrid $ssId $gid
                    } errMsg]} {
                        puts "failed to setCurrentGrid for $w: $errMsg"
                    }
                } else {
                    #puts "skip update calling $w"
                }
            }

            return
        }
    }
    puts "strange, grid widh id=$id_ not found"
}
body GridGroup::GridGroup4BluIce::handleGUIToolModeChange {- rdy_ - mode_ -} {
    if {!$rdy_} {
        return
    }
    set header [string range $mode_ 0 3]
    if {$header == "add_"} {
        clearCurrentGrid

        set shape [string range $mode_ 4 end]
        dict set d_userSetupForNextGrid shape  $shape
        updateRegisteredComponents shape
    }
}
body GridGroup::GridGroup4BluIce::clearCurrentGrid { {caller_ ""} } {
    set m_currentGrid ""
    set m_currentGridIndex -1

    foreach w $m_registeredImageWidgets {
        if {[catch {
            if {$w != $caller_} {
                $w clearCurrentGrid
            }
        } errMsg]} {
            puts "failed to clearCurrentGrid for $w: $errMsg"
        }
    }
    updateRegisteredComponents current_grid
    updateRegisteredComponents grid_list
    updateRegisteredComponents current_grid_node_list
    updateRegisteredComponents current_grid_beam_size
    updateRegisteredComponents current_grid_editable
    updateRegisteredComponents current_grid_resettable
    updateRegisteredComponents current_grid_deletable
    updateRegisteredComponents current_grid_runnable
}
body GridGroup::GridGroup4BluIce::prepareAddGrid { } {
    clearCurrentGrid

    set shape [dict get $d_userSetupForNextGrid shape]
    setWidgetToolMode add_${shape}
}
body GridGroup::GridGroup4BluIce::setWidgetToolMode { mode } {
    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w setToolMode $mode
        } errMsg]} {
            puts "failed to setToolMode for $w: $errMsg"
        }
    }
}
body GridGroup::GridGroup4BluIce::setCurrentGridIndex { index } {
    #puts "setCurrentGridIndex $index"
    #puts "gridList: $lo_gridList"
    set ll [llength $lo_gridList]
    if {$index < 0} {
        set index 0
    }
    if {$index >= $ll} {
        set index [expr $ll - 1]
    }
    if {$ll == 0} {
        dict set d_currentGridIndex $_groupId -1
        set m_currentGrid ""
    } else {
        dict set d_currentGridIndex $_groupId $index
        set m_currentGrid [lindex $lo_gridList $index]
    }
    #puts "current grid index $index"
    #puts "current grid $m_currentGrid"
    set m_currentGridIndex $index
    updateRegisteredComponents current_grid
    updateRegisteredComponents grid_list
    updateRegisteredComponents current_grid_node_list
    updateRegisteredComponents current_grid_beam_size
    updateRegisteredComponents current_grid_editable
    updateRegisteredComponents current_grid_resettable
    updateRegisteredComponents current_grid_deletable
    updateRegisteredComponents current_grid_runnable
}
body GridGroup::GridGroup4BluIce::moveSnapshotToTop { snapshotId } {
    puts "moveSnapshotToTop: $snapshotId"
    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w moveImageToTop $snapshotId $_snapshotIdMap
        } errMsg]} {
            puts "failed to moveImageToTop $w: $errMsg"
        }
    }
}
body GridGroup::GridGroup4BluIce::selectGridIndex { index } {
    #puts "selectGridIndex $index"
    #puts "gridList: $lo_gridList"
    set ll [llength $lo_gridList]
    if {$ll == 0} {
        puts "no grid defined yet"
        return -1
    }

    if {$index < 0} {
        set index 0
    }
    if {$index >= $ll} {
        set index [expr $ll - 1]
        puts "set to last grid in the list"
    }
    set grid [lindex $lo_gridList $index]
    set gid [$grid getId]
    set ssId [getSnapshotIdForGrid $gid]
    dict set d_currentGridIndex $_groupId $index
    set m_currentGrid [lindex $lo_gridList $index]
    set m_currentGridIndex $index

    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w moveImageToTop $ssId $_snapshotIdMap 0
            $w setCurrentGrid $ssId $gid
        } errMsg]} {
            puts "failed to moveImageToTop for currentGrid for $w: $errMsg"
        }
    }
    updateRegisteredComponents current_grid
    updateRegisteredComponents current_grid_node_list
    updateRegisteredComponents current_grid_beam_size
    updateRegisteredComponents current_grid_editable
    updateRegisteredComponents current_grid_resettable
    updateRegisteredComponents current_grid_deletable
    updateRegisteredComponents current_grid_runnable
    return [list $ssId $gid]
}
body GridGroup::GridGroup4BluIce::getCurrentGridId { } {
    if {$m_currentGrid == ""} {
        return -1
    }
    return [$m_currentGrid getId]
}
body GridGroup::GridGroup4BluIce::getCurrentGridIndex { } {
    if {$_groupId < 0} {
        return -1
    }
    if {![dict exists $d_currentGridIndex $_groupId]} {
        return -1
    }
    return [dict get $d_currentGridIndex $_groupId]
}
body GridGroup::GridGroup4BluIce::getGridIndex { id } {
    set ll [llength $lo_gridList]
    if {$ll == 0} {
        return -1
    }
    if {![dict exists $_gridIdMap $id]} {
        return -1
    }
    set i -1
    foreach grid $lo_gridList {
        incr i
        if {[$grid getId] == $id} {
            break
        }
    }
    return $i
}
body GridGroup::GridGroup4BluIce::getCurrentGridInfo { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getSetupProperties]
}
body GridGroup::GridGroup4BluIce::getShapeFromGUI { } {
    return [dict get $d_userSetupForNextGrid shape]
}
body GridGroup::GridGroup4BluIce::getCurrentGridLabel { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getLabel]
}
body GridGroup::GridGroup4BluIce::adjustCurrentGrid { param } {
    if {$m_currentGrid == ""} {
        ## tell caller that we did not do it.
        return 0
    }

    set id [$m_currentGrid getId]
    set any 0
    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w adjustGrid $id $param 
            incr any
        } errMsg]} {
            puts "failed to adjustGrid for currentGrid for $w: $errMsg"
        }
    }
    return $any
}
body GridGroup::GridGroup4BluIce::getCurrentGridNodeListInfo { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getNodeListInfo]
}
body GridGroup::GridGroup4BluIce::getCurrentGridBeamSizeInfo { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getBeamSizeInfo]
}
body GridGroup::GridGroup4BluIce::registerImageDisplayWidget { wd } {
    if {[lsearch -exact $m_registeredImageWidgets $wd] < 0} {
        lappend m_registeredImageWidgets $wd
        $wd register $this current_grid handleGUICurrentGridChange
        $wd register $this tool_mode    handleGUIToolModeChange
    }
    refreshAll
}
body GridGroup::GridGroup4BluIce::unregisterImageDisplayWidget { wd } {
    set index [lsearch -exact $m_registeredImageWidgets $wd]
    if {$index >= 0} {
        set m_registeredImageWidgets [lreplace $m_registeredImageWidgets \
        $index $index]

        $wd unregister $this current_grid handleGUICurrentGridChange
        $wd unregister $this tool_mode    handleGUIToolModeChange
    }
}
body GridGroup::GridGroup4BluIce::setGridListWidget { wd } {
    set m_gridListWidget $wd
    #refreshAll
}
body GridGroup::GridGroup4BluIce::getSnapshotListInfo { } {
    set ssList [getSnapshotImageList]
    set infoList ""
    set displayedList ""
    foreach ss $ssList {
        set label    [$ss getLabel]
        set id       [$ss getId]
        set nameList [getGridLabelListOnThisSnapshot $ss]

        lappend infoList [list $label $id $nameList]
    }
    return $infoList
}
body GridGroup::GridGroup4BluIce::getGridListInfo { } {
    set result ""
    foreach grid [getGridList] {
        set id     [$grid getId]
        ### label is the same as id for grid.
        set label  [$grid getLabel]
        set status [$grid getStatus]

        lappend result [list $id $label $status]
    }
    return [list $m_currentGridIndex $result]
}
body GridGroup::GridGroup4BluIce::updateSnapshotDisplay { } {
    if {$_groupId < 0} return

    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w switchGroup $_groupId $lo_snapshotList $_snapshotIdMap
        } errMsg]} {
            puts "failed to switchGroup for $w: $errMsg"
        }
    }
    updateRegisteredComponents snapshot_list
}
body GridGroup::GridGroup4BluIce::updateCurrentGrid { } {
    if {$_groupId < 0} return

    if {![dict exists $d_currentGridIndex $_groupId]} {
        dict set d_currentGridIndex $_groupId -1
        set index -1
    } else {
        set index [dict get $d_currentGridIndex $_groupId]
    }
    ### this updateRegisteredComponents
    setCurrentGridIndex $index
}
body GridGroup::GridGroup4BluIce::updateBeamSize { } {
    if {$_groupId < 0} return

    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w setBeamSize [getBeamSize]
        } errMsg]} {
            puts "failed to setBeamSize for $w: $errMsg"
        }
    }
}
body GridGroup::GridGroup4BluIce::refreshAll { } {
    updateSnapshotDisplay
    updateCurrentGrid
    updateBeamSize
}
body GridGroup::GridGroup4BluIce::refreshGridGui { id } {
    ### current grid update
    if {$id == [getCurrentGridId]} {
        updateCurrentGrid
    }

    ### snapshot update
    set gg [dict get $_gridIdMap $id]
    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w updateGrid $gg
        } errMsg]} {
            puts "failed to updateGrid for $w: $errMsg"
        }
    }
}
body GridGroup::GridGroup4BluIce::refreshNodeGui {id index status} {
    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w setNode $id $index $status
        } errMsg]} {
            puts "failed to setNode for $w: $errMsg"
        }
    }
    if {$id == [getCurrentGridId]} {
        updateRegisteredComponents current_grid_node_list
    }
}
body GridGroup::GridGroup4BluIce::getCurrentGridEditable { } {
    if {$m_currentGrid == ""} {
        return 1
    }
    return [$m_currentGrid getEditable]
}
body GridGroup::GridGroup4BluIce::getCurrentGridResettable { } {
    if {$m_currentGrid == ""} {
        return 0
    }
    return [$m_currentGrid getResettable]
}
body GridGroup::GridGroup4BluIce::getCurrentGridDeletable { } {
    if {$m_currentGrid == ""} {
        return 0
    }
    return [$m_currentGrid getDeletable]
}
body GridGroup::GridGroup4BluIce::getCurrentGridRunnable { } {
    if {$m_currentGrid == ""} {
        return 0
    }
    return [$m_currentGrid getRunnable]
}
