package provide Raster4BluIce 1.0

package require DCSRasterBase
package require DCSDeviceFactory

class DCS::Raster4BluIce {
	inherit DCS::RasterBase ::DCS::Component

    private variable m_deviceFactory ""
    private variable m_objCollectRaster ""
    private variable m_objRasterRunsConfig ""
    private variable m_objRasterRunsFlip ""
    private variable m_runState inactive

    public method isNodeMasked { view_index row col } {

        switch -exact -- $view_index {
            0 {
                set setup $m_setup0
                set info $m_info0
            }
            1 { 
                set setup $m_setup1
                set info $m_info1
            }
            default {
                return 0
            }
        }
        foreach {orig_x orig_y orig_z orig_a cellHeight cellWidth \
        numRow numColumn} $setup break
        set offset [expr $row * $numColumn + $col + 1]

        set mm [lindex $info $offset]
        set mm [string index $mm 0]
        if {$mm == "N"} {
            return 1
        }
        return 0
    }

    public method getRunState { } {
        return $m_runState
    }
    public method getNeedsReset { } {
        switch -exact -- $m_runState {
            inactive -
            collecting {
                return 0
            }
            complete -
            paused -
            skipped -
            default {
                return 1
            }
        }
    }
    public method getRunnable { } {
        switch -exact -- $m_runState {
            collecting -
            inactive -
            paused -
            skipped {
            }
            complete -
            default {
                return 0
            }
        }
        if {![getRasterDefined]} {
            return 0
        }
        if {[allDone]} {
            ## just in case.
            ## this should be in runstate: complete
            return 0
        }
        return 1
    }

    public method getNotRaster0 { } {
        if {$m_rasterNum != 0} {
            return 1
        } else {
            return 0
        }
    }
    public method switchRasterNumber { new_number {forced_refresh 0} } {
        if {!$forced_refresh && $new_number == $m_rasterNum} {
            return
        }

        set name raster_run$new_number
        if {[$m_deviceFactory stringExists $name]} {
            set obj [$m_deviceFactory getObjectName $name]
            set contents [$obj getContents]
            set m_runState [lindex $contents 0]
            set newFile [lindex $contents 2]
            if {$newFile != "not_exists"} {
                set dir [::config getStr rasterRun.directory]
                set newPath [file join $dir $newFile]
            } else {
                set newPath $newFile
            }
            load $new_number $newPath
            updateRegisteredComponents needs_reset
            updateRegisteredComponents run_state
            ### load already updated runnable
            #updateRegisteredComponents runnable
        } else {
            log_error wrong raster number $new_number: \
            no raster_run$new_number found

            set m_raster_num -1
        }
    }

    public method load { rasterNum path {silent 0} } {
        puts "Raster4BluIce::load $rasterNum $path $silent"

        set m_rasterNum $rasterNum
        set m_rasterPath $path

        if {[catch {
            readback $silent
        } errMsg]} {
            ### readback already sent log messages
        }

        updateRegisteredComponents all_new
        updateRegisteredComponents defined
        updateRegisteredComponents defined0
        updateRegisteredComponents defined1
        updateRegisteredComponents single_view
        updateRegisteredComponents runnable
        updateRegisteredComponents not_raster0
        updateRegisteredComponents is_inline
    }

    public method getInfo { view_index} {
        return [set m_info$view_index]
    }

    public method handleOperationEvent

    ### in deleting of the raster, the raster number will not change but
    ### the contents will change and point to next raster.
    ### so we need to refresh
    public method handleRunEvent

    ####################################################################
    ### interface to start operation to change it
    public method autoFill { } {
        $m_objRasterRunsConfig startOperation \
        auto_set $m_rasterNum
    }
    public method takeSnapshot { inline } {
        $m_objRasterRunsConfig startOperation \
        take_snapshot $m_rasterNum $inline
    }
    public method moveViewToVideo { view_index } {
        $m_objRasterRunsConfig startOperation \
        move_view_to_camera $m_rasterNum $view_index
    }
    public method moveViewToBeam { view_index } {
        $m_objRasterRunsConfig startOperation \
        move_view_to_beam $m_rasterNum $view_index 0 0
    }
    public method defineView { view_index  x1 y1 x2 y2 } {
        $m_objRasterRunsConfig startOperation \
        define_view $m_rasterNum $view_index $x1 $y1 $x2 $y2
    }
    public method moveView { view_index direction } {
        $m_objRasterRunsConfig startOperation \
        move_view $m_rasterNum $view_index $direction
    }

    public method flipNode { view_index row column } {
        ### for DEBUG if {![isNodeMasked $view_index $row $column]}
        if {[isFirstTimeNodeFlip $view_index]} {
            if {[catch {
                checkBackground $view_index $row $column
            } mList]} {
                log_error $mList
                set mList ""
            }
            set ll [llength $mList]
            if {$ll > 4} {
                puts "mask list=$mList"
                eval $m_objRasterRunsFlip startOperation \
                flip_node $m_rasterNum $view_index $mList
                return
            }
        }
        $m_objRasterRunsFlip startOperation \
        flip_node $m_rasterNum $view_index $row $column
    }

    public method flipWholeView { view_index } {
        $m_objRasterRunsConfig startOperation \
        flip_view $m_rasterNum $view_index
    }

    public method flipSingleViewMode { } {
        $m_objRasterRunsConfig startOperation \
        flip_single_view_mode $m_rasterNum
    }

    public method defaultUserSetup { } {
        $m_objRasterRunsConfig startOperation \
        resetUserSetupToDefault $m_rasterNum
    }
    public method updateUserSetup { } {
        $m_objRasterRunsConfig startOperation \
        updateUserSetup $m_rasterNum
    }
    public method setUserSetup { name value } {
        $m_objRasterRunsConfig startOperation \
        setUserSetup $m_rasterNum $name $value
    }

    public method deleteRun { } {
        $m_objRasterRunsConfig startOperation deleteRaster $m_rasterNum
    }

    public method resetRun { } {
        $m_objRasterRunsConfig startOperation resetRaster $m_rasterNum
    }

    public method isFirstTimeNodeFlip { view_index }
    public method checkBackground { view_index row col }

    ## all_new: setup0, setup1, info0, info1
    constructor { } {
        ::DCS::Component::constructor { \
            all_new      { getAll } \
            raster_setup { getRasterSetup } \
            defined      { getRasterDefined } \
            defined0     { getViewDefined 0} \
            defined1     { getViewDefined 1} \
            single_view  { isSingleView } \
            view_0_setup  { getSetup 0 } \
            view_1_setup  { getSetup 1 } \
            view_0_data   { getInfo 0 } \
            view_1_data   { getInfo 1 } \
            user_setup   { getUserSetup } \
            start        { expr 1 } \
            run_state    { getRunState } \
            needs_reset  { getNeedsReset } \
            runnable     { getRunnable } \
            not_raster0  { getNotRaster0 } \
            is_inline    { isInline } \
        } \
    } {
        set m_deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objCollectRaster [$m_deviceFactory createOperation collectRaster]
        set m_objRasterRunsConfig \
        [$m_deviceFactory createOperation rasterRunsConfig]

        set m_objRasterRunsFlip \
        [$m_deviceFactory createOperation rasterRunsFlip]

        $m_objCollectRaster    registerForAllEvents $this handleOperationEvent
        $m_objRasterRunsConfig registerForAllEvents $this handleOperationEvent
        $m_objRasterRunsFlip   registerForAllEvents $this handleOperationEvent

        for {set n 0} {$n < [::DCS::RasterBase::getMAXRUN]} {incr n} {
            set name raster_run$n
            set obj  [$m_deviceFactory getObjectName $name]
            ::mediator register $this $obj contents handleRunEvent
        }

		announceExist
    }
    destructor {
        $m_objCollectRaster    unregisterForAllEvents $this handleOperationEvent
        $m_objRasterRunsConfig unregisterForAllEvents $this handleOperationEvent
        $m_objRasterRunsFlip   unregisterForAllEvents $this handleOperationEvent
    }
}
body DCS::Raster4BluIce::handleRunEvent { run_ ready_ - contents_ -} {
    if {!$ready_} {
        return
    }

    set runNum [string range [namespace tail $run_] 10 end]
    if {$runNum != $m_rasterNum} {
        return
    }
    foreach {state label path} $contents_ break


    if {$path != $m_rasterPath} {
        switchRasterNumber $m_rasterNum 1
    } else {
        set m_runState $state
        updateRegisteredComponents run_state
        updateRegisteredComponents needs_reset
        updateRegisteredComponents runnable
    }
}
body DCS::Raster4BluIce::handleOperationEvent { msg_ } {
    foreach {evType opName opId arg1 arg2 arg3 arg4} $msg_ break

    if {$evType == "stog_start_operation" && $opName == "collectRaster"} {
        updateRegisteredComponents start
        return
    }

    if {$evType == "stog_operation_update" && $arg2 == $m_rasterNum} {
        switch -exact -- $arg1 {
            SCAN_INFO {
                set m_3DInfo $arg3
                set m_isInline [lindex $m_3DInfo 14]
                set m_isCollimator [lindex $m_3DInfo 4]
                updateRegisteredComponents raster_setup
                updateRegisteredComponents defined
                updateRegisteredComponents defined0
                updateRegisteredComponents defined1
                updateRegisteredComponents single_view
                updateRegisteredComponents runnable
                updateRegisteredComponents user_setup
                updateRegisteredComponents is_inline
            }
            RASTER_STATE {
                ## not used, may remove from the dcss and here.
                ## it was used to decide whether to disable "Skip" button.
                ## Now we separate Skip and Pause.  Skip can be always enabled.
            }
            VIEW_SETUP0 {
                set m_initializedSetup0 1
                set m_setup0 $arg3
                updateRegisteredComponents view_0_setup
            }
            VIEW_SETUP1 {
                set m_initializedSetup1 1
                set m_setup1 $arg3
                updateRegisteredComponents view_1_setup
            }
            VIEW_DATA0 {
                set m_initializedInfo0 1
                set m_info0 $arg3
                if {$m_setup0 != ""} {
                    updateRegisteredComponents view_0_data
                    updateRegisteredComponents runnable
                }
            }
            VIEW_DATA1 {
                set m_initializedInfo1 1
                set m_info1 $arg3
                if {$m_setup1 != ""} {
                    updateRegisteredComponents view_1_data
                    updateRegisteredComponents runnable
                }
            }
            VIEW_NODE0 {
                if {$m_info0 != ""} {
                    set offset [expr $arg3 + 1]
                    set v      $arg4
                    set m_info0 [lreplace $m_info0 $offset $offset $v]
                    if {$m_setup0 != ""} {
                        updateRegisteredComponents view_0_data
                        updateRegisteredComponents runnable
                    }
                }
            }
            VIEW_NODE1 {
                if {$m_info1 != ""} {
                    set offset [expr $arg3 + 1]
                    set v      $arg4
                    set m_info1 [lreplace $m_info1 $offset $offset $v]
                    if {$m_setup1 != ""} {
                        updateRegisteredComponents view_1_data
                        updateRegisteredComponents runnable
                    }
                }
            }
            USER_NORMAL {
                set m_userSetupNormal $arg3
                if {!$m_isCollimator} {
                    updateRegisteredComponents user_setup
                    updateRegisteredComponents runnable
                }
            }
            USER_MICRO {
                set m_userSetupMicro $arg3
                if {$m_isCollimator} {
                    updateRegisteredComponents user_setup
                    updateRegisteredComponents runnable
                }
            }
            default {
                ### ignore
            }
        }
    }
}
body DCS::Raster4BluIce::isFirstTimeNodeFlip { view_index } {
    switch -exact -- $view_index {
        0 {
            set status [lindex $m_info0 0]
            set info [lrange $m_info0 1 end]
        }
        1 { 
            set status [lindex $m_info1 0]
            set info [lrange $m_info1 1 end]
        }
        default {
            return 0
        }
    }

    if {$status != "new"} {
        return 0
    }
    foreach e $info {
        if {$e != "S"} {
            return 0
        }
    }
    return 1
}
body DCS::Raster4BluIce::checkBackground { view_index row col } {
    ### get snapshot path and grid info
    switch -exact -- $view_index {
        0 {
            set snapInfo [lindex $m_3DInfo 2]
            set cx [lindex $m_3DInfo 19]
            set cy [lindex $m_3DInfo 20]

            set wu  [lindex $m_3DInfo 5]
            set hu  [lindex $m_3DInfo 6]
            set numCol [lindex $m_3DInfo 8]
            set numRow [lindex $m_3DInfo 9]
        }
        1 { 
            set snapInfo [lindex $m_3DInfo 3]
            set cx [lindex $m_3DInfo 21]
            set cy [lindex $m_3DInfo 22]

            set wu  [lindex $m_3DInfo 5]
            set hu  [lindex $m_3DInfo 7]
            set numCol [lindex $m_3DInfo 8]
            set numRow [lindex $m_3DInfo 10]
        }
        default {
            return
        }
    }
    foreach {snapshot orig} $snapInfo break
    set hMM [lindex $orig 4]
    set wMM [lindex $orig 5]
    set w [expr $wu / (1000.0 * $wMM)]
    set h [expr $hu / (1000.0 * $hMM)]

    return [jpegBackgroundDetect \
    $snapshot $cx $cy $w $h $numCol $numRow $col $row]
}
