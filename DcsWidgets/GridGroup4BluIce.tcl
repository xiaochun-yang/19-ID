package provide DCSGridGroup4BluIce 1.0

package require DCSGridGroupBase

namespace import ::itcl::*

#### beamsize info: width height {collimator ...}
##### This wrapper will monitor current system beam size and collimator set up
##### and decide the color of the beam size box.
##### So it may trigger update upon grid beam size change and system beam size
##### change.
##### 
##### To make less confusion, we use call, not event to set the
##### the raw grid beam size.
class GridBeamSizeWrapper {
    inherit ::DCS::Component
    ### inherit Widget so we can use itk_option

    private variable m_hasCollimator 0

    public method getBeamSize { } { return $m_beamsize }

    public method handleSystemBeamSizeUpdate { obj_ ready_ - - - } {
        if {!$ready_} {
            return
        }
        #puts "Wrapper updateBeamSize by $obj_"
        updateBeamSize
    }

    public method handleUserCollimator    { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        set m_hasCollimator 1
        #puts "wrapper updateBeamSize by userCollimator"
        set m_sysUserCollimatorStatus $contents_
        updateBeamSize
    }

    public method setDesiredBeamSizeInfo { info_ } {
        #puts "wrapper updateBeamSize by info: $info_"
        set m_comboInfo $info_
        updateBeamSize
    }

    private method getSystemBeamSize { }
    private method getDesiredBeamSize { }
    private method updateBeamSize { }

    private variable m_matchColor white
    private variable m_beamsize [list 0.1 0.1 white]

    private variable m_comboInfo [list 100.0 100.0 [list 0 -1 2.0 2.0]]

    private variable m_sysUserCollimatorStatus    [list 0 -1 2.0 2.0]
    private variable m_sysCurrentCollimatorStatus [list 0 -1 2.0 2.0]

    constructor { args } {
        ::DCS::Component::constructor {
            grid_beam_size getBeamSize
        }
    } {
        global gMotorBeamWidth
        global gMotorBeamHeight

        set m_matchColor [::config getStr "bluice.beamMatchColor"]
        if {$m_matchColor == ""} {
            set m_matchColor white
        }

        announceExist

        ::mediator register $this ::device::$gMotorBeamWidth scaledPosition \
        handleSystemBeamSizeUpdate
        ::mediator register $this ::device::$gMotorBeamHeight scaledPosition \
        handleSystemBeamSizeUpdate

        ::mediator register $this ::device::user_collimator_status \
        contents handleUserCollimator
    }
}
body GridBeamSizeWrapper::getSystemBeamSize { } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    set userCollimator [lindex $m_sysUserCollimatorStatus 0]

    if {$m_hasCollimator && $userCollimator == "1"} {
        foreach {isMicro index width height} \
        $m_sysUserCollimatorStatus break
    } else {
        set width  [::device::$gMotorBeamWidth  cget -scaledPosition]
        set height [::device::$gMotorBeamHeight cget -scaledPosition]
        set index -1
    }
    return [list $width $height $index]
}
body GridBeamSizeWrapper::getDesiredBeamSize { } {
    foreach {w h collimator} $m_comboInfo break
    set isMicro [lindex $collimator 0]

    if {$m_hasCollimator && $isMicro == "1"} {
        foreach {isMicro index width height} $collimator break
    } else {
        ### to mm
        set width  [expr $w / 1000.0]
        set height [expr $h / 1000.0]
        set index -1
    }
    return [list $width $height $index]
}
body GridBeamSizeWrapper::updateBeamSize { } {
    set sysSize     [getSystemBeamSize]
    set desiredSize [getDesiredBeamSize]

    #puts "sysSize $sysSize desired: $desiredSize"

    foreach {sysW sysH sysIndex} $sysSize break
    foreach {dsrW dsrH dsrIndex} $desiredSize break
    if {$sysIndex != $dsrIndex \
    || abs($sysW - $dsrW) >= 0.001 \
    || abs($sysH - $dsrH) >= 0.001 \
    } {
        #puts "color red"
        set color red
    } else {
        set color $m_matchColor
    }
    foreach {old_w old_h old_color} $m_beamsize break
    if {abs($dsrW - $old_w) >= 0.0001 \
    ||  abs($dsrH - $old_h) >= 0.0001 \
    || $color != $old_color \
    } {
        set m_beamsize [list $dsrW $dsrH $color]
        updateRegisteredComponents grid_beam_size
        #puts "updated beam_size"
    } else {
        #puts "skip update beam size, no change"
    }
}

####################################################
# separate ItemDisplayControl from GridGroup4BluIce
# to prepare each canvas has its own control.
#
# We also want to keep the global control.  It will
# update all the other displayControl
#
###################################################
class GridGroup::ItemDisplayControl {
    inherit ::DCS::Component

    ### for here, the wd needs to have public method:
    ###########
    ### refrashMatrixDisplay
    ### configureOptions -showBeamInfo XXXXX
    ##########
    ### this may be removed in the future if we decide
    ### that each canvas can register to
    ### click_to_move
    ### number_display_field
    ### contour_display_field
    ### contour_display_level
    ### beam_display_option
    public method registerImageDisplayWidget { wd }
    public method unregisterImageDisplayWidget { wd }

    public method setDisplayFields { num contour }

    public method setClickToMove { yn }
    public method setNumberField { ff }
    public method setContourField { ff }
    public method setContourLevels { ll }
    public method setShowOnlyCurrentGrid { yn }
    public method setShowRasterToo { yn }
    public method setBeamDisplayOption { yn }

    public method getClickToMove { } { return $m_clickToMove }
    public method getNumberField { } {
        if {$m_clickToMove} {
            return None
        }
        return $m_numField
    }
    public method getContourField { } {
        if {$m_clickToMove} {
            return None
        }
        return $m_contourField
    }
    public method getContourLevels { } { return $m_contourLevelList }
    public method getShowOnlyCurrentGrid { } { return $m_showCurrentOnly }
    public method getShowRasterToo { } { return $m_showRasterToo }
    public method getBeamDisplayOption { } { return $m_beamDisplayOption }

    public method setMasterControl { m }

    public method handleMasterUpdate { - ready_ alias_ contents_ - } {
        if {!$ready_} {
            return
        }
        foreach {obj att} [split $alias_ ~] break

        switch -exact -- $att {
            number_display_field    { setNumberField $contents_ }
            contour_display_field   { setContourField $contents_ }
            contour_display_level   { setContourLevels $contents_ }
            beam_display_option     { setBeamDisplayOption $contents_ }
            show_only_current_grid  { setShowOnlyCurrentGrid $contents_ }
            show_raster_too         { setShowRasterToo $contents_ }
            click_to_move           { setClickToMove $contents_ }
            default { log_error not supported att $att from master }
        }
    }

    protected variable m_numField Frame
    protected variable m_contourField Spots
    protected variable m_contourLevelList "10 25 50 75 90"
    protected variable m_showCurrentOnly 0
    protected variable m_showRasterToo 0
    protected variable m_beamDisplayOption Cross_And_Box
    protected variable m_clickToMove 0

    protected common MASTER_ATTRIBUTE_LIST [list \
        number_display_field \
        contour_display_field \
        contour_display_level \
        beam_display_option \
        show_only_current_grid \
        show_raster_too \
        click_to_move \
    ]
    ### for individual canvas control, this should be just one.
    ### we want to support global control too.
    protected variable m_registeredImageWidgets ""

    protected variable m_master ""

    constructor { args } {
        ::DCS::Component::constructor {
            number_display_field    { getNumberField }
            contour_display_field   { getContourField }
            contour_display_level   { getContourLevels }
            beam_display_option     { getBeamDisplayOption }
            show_only_current_grid  { getShowOnlyCurrentGrid }
            show_raster_too         { getShowRasterToo }
            click_to_move           { getClickToMove }
        }
    } {
		announceExist
    }
}
body GridGroup::ItemDisplayControl::registerImageDisplayWidget { wd } {
    if {[lsearch -exact $m_registeredImageWidgets $wd] < 0} {
        lappend m_registeredImageWidgets $wd
    }
}
body GridGroup::ItemDisplayControl::unregisterImageDisplayWidget { wd } {
    set index [lsearch -exact $m_registeredImageWidgets $wd]
    if {$index >= 0} {
        set m_registeredImageWidgets [lreplace $m_registeredImageWidgets \
        $index $index]
    }
}
body GridGroup::ItemDisplayControl::setDisplayFields { nnnn cccc } {
    set m_numField $nnnn
    set m_contourField $cccc
    updateRegisteredComponents number_display_field
    updateRegisteredComponents contour_display_field

    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w refreshMatrixDisplay
        } errMsg]} {
            puts "failed to refreshMatrixDisplay for $this: $errMsg"
        }
    }
}
body GridGroup::ItemDisplayControl::setClickToMove { yn } {
    set m_clickToMove $yn
    updateRegisteredComponents click_to_move
    updateRegisteredComponents number_display_field
    updateRegisteredComponents contour_display_field
    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w refreshMatrixDisplay
        } errMsg]} {
            puts "failed to refreshMatrixDisplay for $this: $errMsg"
        }
    }
}
body GridGroup::ItemDisplayControl::setNumberField { sss } {
    if {$m_clickToMove} {
        updateRegisteredComponents number_display_field
        log_error cannot change while Align Visually (hides results)
        return
    }

    set m_numField $sss
    updateRegisteredComponents number_display_field
    switch -exact -- $sss {
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
body GridGroup::ItemDisplayControl::setContourField { sss } {
    if {$m_clickToMove} {
        log_error cannot change while Align Visually (hides results)
        updateRegisteredComponents contour_display_field
        return
    }

    set m_contourField $sss
    updateRegisteredComponents contour_display_field
    switch -exact -- $m_contourField {
        None {
        }
        default {
            switch -exact -- $m_numField {
                Frame -
                None {
                }
                default {
                    set m_numField $sss
                    updateRegisteredComponents number_display_field
                }
            }
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
body GridGroup::ItemDisplayControl::setContourLevels { ll } {
    set m_contourLevelList $ll
    updateRegisteredComponents contour_display_level

    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w refreshMatrixDisplay
        } errMsg]} {
            puts "failed to refreshMatrixDisplay for $this: $errMsg"
        }
    }
}
body GridGroup::ItemDisplayControl::setShowOnlyCurrentGrid { s } {
    set m_showCurrentOnly $s
    updateRegisteredComponents show_only_current_grid
}
body GridGroup::ItemDisplayControl::setShowRasterToo { s } {
    set m_showRasterToo $s
    updateRegisteredComponents show_raster_too
}
body GridGroup::ItemDisplayControl::setBeamDisplayOption { s } {
    set m_beamDisplayOption $s
    updateRegisteredComponents beam_display_option

    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w configureOptions -showBeamInfo $s
        } errMsg]} {
            puts "failed to configure showItem for $w: $errMsg"
        }
    }
}
body GridGroup::ItemDisplayControl::setMasterControl { m } {
    if {$m_master == $m} {
        return
    }
    if {$m_master != ""} {
        foreach att $MASTER_ATTRIBUTE_LIST {
            $m_master unregister $this $att handleMasterUpdate
        }
    }
    set m_master $m
    if {$m_master != ""} {
        foreach att $MASTER_ATTRIBUTE_LIST {
            $m_master register $this $att handleMasterUpdate
        }
    }
}

class GridGroup::GridGroup4BluIce {
    inherit ::GridGroup::GridGroupBase ::DCS::Component

    ### the _groupId only set after load successfully.
    private variable m_assignedGroupNum -1

    private variable m_beamsizeWrapper ""

    private variable m_deviceFactory ""
    private variable m_objGridGroupConfig ""
    private variable m_objGridGroupFlip ""
    private variable m_objCollectGrid ""

    private variable m_objLatestUserSetup ""

    private variable m_strCrystalStatus ""
    private variable m_strScreeningParameters ""
    private variable m_strCurrentL614Node ""

    ## d_currentGridIndex will survive across load from file.
    ## and it will be saved across even switching group number
    ## one per group number
    private variable d_currentGridIndex ""
    private variable m_currentGrid ""
    #### currentGrid position in the list.
    private variable m_currentGridIndex -1

    private variable m_registeredImageWidgets ""

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

    ### save a copy of the state in the string "gridGroupXX".
    ### It will be used to check resettable......
    private variable m_runState "inactive"

    private variable m_numField Frame
    private variable m_contourField Spots
    private variable m_contourLevelList "10 25 50 75 90"
    private variable m_showCurrentOnly 0
    private variable m_showRasterToo 0
    private variable m_beamDisplayOption Cross_And_Box
    private variable m_allowLookAroundWhenBusy 1
    private variable m_onlyRotatePhi 0

    private variable m_strCurrentNode ""
    private variable m_ctsCurrentNode ""

    private variable m_clickToMove 0

    public method switchGroupNumber { new_number {forced_refresh 0} }

    ### called by "*" tab, will use shape from latest user setup to call
    ### setWidgetToolMode with add_$shape
    public method prepareAddGrid { }
    public method setWidgetToolMode { mode }

    public method moveSnapshotToTop { snapshotId }
    public method getCurrentGridIndex { }
    public method getGridIndex { id }
    public method getCurrentGridId { }
    public method getCurrentSnapshotId { } {
        return [getSnapshotIdForGrid [getCurrentGridId]]
    }
    public method getCurrentGridShape { }
    public method getCurrentGridLabel { }
    ### all information needed by GUI to display the current grid, including:
    ### grid center, size, beam setup.
    public method getCurrentGridInfo { }
    public method getCurrentGridNodeListInfo { }
    public method getCurrentGridFrameListInfo { }
    public method getCurrentGridBeamSizeInfo { }
    public method getCurrentGridBeamSize { }
    public method getSnapshotListInfo { }
    public method getItemListInfo { }

    ### this is only selected node for phi and in reverse order of
    ### sequence.  It is just for display
    public method getCurrentCrystalPhiNodeListForDisplay { }
    ### this is the whole list, match sequence order.
    ### It can be used for menu, checkbutton.
    public method getCurrentCrystalAllPhiNodeList { }

    ## for attributes
    public method getCurrentGridEditable { }
    public method getCurrentGridResettable { }
    public method getCurrentGridDeletable { }
    public method getCurrentGridRunnable { }
    public method getCurrentGridPhiRunnable { }
    public method getCurrentGridHidden { }
    public method getCurrentGridFinest { }
    public method getCurrentGridPhiRange { }
    public method getCurrentGridInputPhiRange { }
    public method getCurrentGridCamera { }
    public method getCurrentItemIsMegaCrystal { }

    public method getDefaultCellWidth { }  { return $m_defaultCellWidth }
    public method getDefaultCellHeight { } { return $m_defaultCellHeight }
    public method getDefaultUserSetup { {purpose forGrid} }  {
        refreshParameter $purpose
        set result $d_userSetupForNextGrid
        foreach name {prefix directory} {
            set v [dict get $d_parameterForNextGrid $name]
            dict set result $name $v
        }
        switch -exact -- $purpose {
            forCrystal {
                dict set result summary "parameters for new crystal"
                dict set result shape crystal
                dict set result for_lcls 0
            }
            forLCLSCrystal {
                dict set result summary "parameters for new crystal"
                dict set result shape crystal
                dict set result for_lcls 1
            }
            forPXL614 {
                dict set result summary "parameters for new l614 grid"
                dict set result shape l614
                dict set result for_lcls 0
            }
            forL614 {
                dict set result for_lcls 1
                if {[catch {dict get $result shape} shape]} {
                    dict set result shape l614
                    set shape l614
                }
                switch -exact -- $shape {
                    l614 -
                    projective -
                    trap_array -
                    mesh {
                        ### OK.
                    }
                    default {
                        dict set result shape l614
                    }
                }
                dict set result summary "parameters for new $shape grid"
            }
            default {
                dict set result for_lcls 0
                if {$purpose == "forLCLS"} {
                    dict set result for_lcls 1
                }
                dict set result summary "parameters for new raster"
                if {[catch {dict get $result shape} shape]} {
                    dict set result shape rectangle
                    set shape rectangle
                }
                switch -exact -- $shape {
                    rectangle -
                    oval -
                    line -
                    polygon {
                        ### OK, no adjust
                    }
                    crystal -
                    l614 -
                    default {
                        dict set result shape rectangle
                    }
                }
            }
        }
        return $result
    }

    public method getBeamSize { } {
        return $m_gridBeamsize
    }

    public method getClickToMove { } {
        return $m_clickToMove
    }
    public method setClickToMove { yn } {
        set m_clickToMove $yn
        updateRegisteredComponents click_to_move
        updateRegisteredComponents number_display_field
        updateRegisteredComponents contour_display_field
        foreach w $m_registeredImageWidgets {
            if {[catch {
                $w refreshMatrixDisplay
            } errMsg]} {
                puts "failed to refreshMatrixDisplay for $this: $errMsg"
            }
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
    public method adjustCurrentGrid { grid_param {extra_user_param ""} }

    ### called by image display, it will that display to adjust
    public method adjustCurrentGridOnDisplay { \
        display grid_param {extra_user_param ""} \
    }

    public method validCurrentGridInput { key valueREF }
    public method setupCurrentGridExposure { name value }

    ### select current grid from gridList
    public method selectGridIndex { index }
    ### select current grid from graph
    ### also used by currentGridGroupNode to update.  So, the id can be
    ### negative means no current grid, and GUI will prepareForNewGrid.
    public method selectGridId { id }

    public method handleOperationEvent { msg_ }
    public method handleStringEvent { name_ ready_ - contents_ - }
    public method handleBeamSizeEvent { name_ ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        updateRegisteredComponents current_grid_finest
    }
    public method handleGridBeamsizeChange { caller_ ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        puts "handleGridBeamSizeChange caller =$caller_ $contents_"
        set m_gridBeamsize $contents_
        updateBeamSize
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
        } else {
            puts "got cell_width from latest: $m_defaultCellWidth"
        }

        if {[catch {dict get $d_userSetupForNextGrid cell_height} \
        m_defaultCellHeight]} {
            set m_defaultCellHeight 50.0
            puts "no cell_height in setup for next grid"
        } else {
            puts "got cell_height from latest: $m_defaultCellHeight"
        }
        set d_parameterForNextGrid $d_userSetupForNextGrid
        foreach name [GridGroup::GridBase::getParameterFieldNameList] {
            if {[catch {dict get $d_userSetupForNextGrid $name} v]} {
                log_error parameter $name not found in latest_raster_user_setup
                set v 0
                dict set d_parameterForNextGrid $name $v
            }
        }

        ### rasterView and crystalView need this update
        updateRegisteredComponents current_grid
        updateBeamSize
    }
    public method handleCurrentGridNodeChange { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        #puts "handleCurrentGridNodeChange: $contents_"
        set m_ctsCurrentNode $contents_
        updateByStringCurrentGridGroupNode
    }
    protected method updateByStringCurrentGridGroupNode { } {
        if {!$m_allowLookAroundWhenBusy} {
            set gridId [lindex $m_ctsCurrentNode 1]
            if {[string is integer -strict $gridId] && $gridId >= 0} {
                selectGridId $gridId
            } else {
                prepareAddGrid
            }
        }
    }
    public method refreshParameter { purpose } {
        set user [::dcss getUser]
        set ctxCrystalStatus [$m_strCrystalStatus       getContents]
        set ctxScreening     [$m_strScreeningParameters getContents]

        switch -exact -- $purpose {
            forCrystal -
            forLCLSCrystal {
                set shape crystal
                set keyWord crystal
            }
            forPXL614 -
            forL614 {
                if {[catch {dict get $d_userSetupForNextGrid shape} shape]} {
                    dict set d_userSetupForNextGrid shape l614
                    set shape l614
                }
                switch -exact -- $shape {
                    l614 -
                    projective -
                    trap_array -
                    mesh {
                    }
                    default {
                        set shape l614
                    }
                }
                set keyWord grid
            }
            default {
                ## any raster shape is fine
                set shape rectangle
                set keyWord raster
            }
        }

        set gridPort ""
        if {![catch {dict get $d_parameterForNextGrid on_l614_grid} onGrid] \
        && $onGrid == "1"} {
            set ctxGrid [$m_strCurrentL614Node getContents]
            foreach {l614_groupId l614_gridId l614_seq l614_label} \
            $ctxGrid break
            if {$_groupId == $l614_groupId \
            && $l614_gridId >= 0 \
            && $l614_seq >= 0} {
                set gridPort $l614_label
                puts "using l614 label $gridPort in refreshing for DefaultUserSetup"
            }
        }

        set idInfo \
        [getNextGridId $shape $user $ctxCrystalStatus $ctxScreening $gridPort]
        foreach {- lb - prefix} $idInfo break
        if {[catch {dict get $d_userSetupForNextGrid directory} directory]} {
            log_error parameter directory not found in latest_raster_user_setup
            set directory ${keyWord}_dir_$lb
        }
    
        ## this is for latest user setup, which not bound to any grid.
        set directory [string map "GRID_LABEL $keyWord$lb" $directory]

        checkUsernameInDirectory directory $user
        dict set d_parameterForNextGrid prefix $prefix
        dict set d_parameterForNextGrid directory $directory
    }

    #### for display contour
    public method setDisplayFields { nnnn cccc } {
        puts "displayFields $nnnn $cccc"
        set m_numField $nnnn
        set m_contourField $cccc
        updateRegisteredComponents number_display_field
        updateRegisteredComponents contour_display_field
    }
    public method setNumberField { sss } {
        if {$m_clickToMove} {
            updateRegisteredComponents number_display_field
            log_error cannot change while Align Visually (hides raster results)
            return
        }

        set m_numField $sss
        updateRegisteredComponents number_display_field
        switch -exact -- $sss {
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
        if {$m_clickToMove} {
            log_error cannot change while Align Visually (hides raster results)
            updateRegisteredComponents contour_display_field
            return
        }

        set m_contourField $sss
        updateRegisteredComponents contour_display_field
        switch -exact -- $m_contourField {
            None {
            }
            default {
                switch -exact -- $m_numField {
                    Frame -
                    None {
                    }
                    default {
                        set m_numField $sss
                        updateRegisteredComponents number_display_field
                    }
                }
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

        foreach w $m_registeredImageWidgets {
            if {[catch {
                $w refreshMatrixDisplay
            } errMsg]} {
                puts "failed to refreshMatrixDisplay for $this: $errMsg"
            }
        }
    }
    public method setShowOnlyCurrentGrid { s } {
        set m_showCurrentOnly $s
        updateRegisteredComponents show_only_current_grid
    }
    public method setShowRasterToo { s } {
        set m_showRasterToo $s
        updateRegisteredComponents show_raster_too
    }
    public method setBeamDisplayOption { s } {
        set m_beamDisplayOption $s
        updateRegisteredComponents beam_display_option

        foreach w $m_registeredImageWidgets {
            if {[catch {
                $w configureOptions -showBeamInfo $s
            } errMsg]} {
                puts "failed to configure showItem for $w: $errMsg"
            }
        }
    }
    public method getNumberField { } {
        if {$m_clickToMove} {
            return None
        }
        return $m_numField
    }
    public method getContourField { } {
        if {$m_clickToMove} {
            return None
        }
        return $m_contourField
    }
    public method getContourLevels { } { return $m_contourLevelList }
    public method getShowOnlyCurrentGrid { } { return $m_showCurrentOnly }
    public method getShowRasterToo { } { return $m_showRasterToo }
    public method getBeamDisplayOption { } { return $m_beamDisplayOption }
    public method getAllowLookAround { } { return $m_allowLookAroundWhenBusy }
    public method getOnlyRotatePhi { } { return $m_onlyRotatePhi }

    public method setAllowLookAround { yn } {
        #### disable change and always allowed
        return

        set m_allowLookAroundWhenBusy $yn
        updateRegisteredComponents allow_look_around_when_busy
        updateByStringCurrentGridGroupNode
    }
    public method setOnlyRotatePhi { yn } {
        set m_onlyRotatePhi $yn
        updateRegisteredComponents only_rotate_phi
    }

    public method setGridHide { id h } {
        set grid [_get_grid $id]
        $grid setHide $h
        refreshGridGui $id
    }

    public proc getSmallestBeamSize { }

    protected method clearCurrentGrid { }
    protected method setCurrentGridIndex { index }

    protected method updateSnapshotDisplay { }
    protected method updateCurrentGrid { }
    protected method refreshAll { }

    ### this will trigger wrapper to send event.
    protected method updateBeamSize { }

    ### it suppports that grid is not current grid.
    ### for example, a group move.
    protected method refreshGridGui { id }
    ### update single node for both graphic and whole list (no single node
    ### on the list yet)
    protected method refreshNodeGui { id index stats }
    protected method refreshPhiNodeGui { id index stats }

    protected method getGridLabelListOnThisSnapshot { ss } {
        set result ""
        foreach gridId [$ss getItemIdListDefaultOnThis] {
            set vv grid[getGridLabel $gridId]
            lappend result $vv
        }
        puts "gridNameList for $ss: $result"
        return $result
    }
    public method getBeamSizeInfoFromLatestUserSetup { } {
        if {[catch {dict get $d_userSetupForNextGrid beam_width} bw]} {
            set bw 100.0
        }
        if {[catch {dict get $d_userSetupForNextGrid beam_height} bh]} {
            set bh 100.0
        }
        if {[catch {dict get $d_userSetupForNextGrid collimator} cr]} {
            set cr [list 0 -1 2.0 2.0]
        }
        return [list $bw $bh $cr]
    }

    constructor { args } {
        ::DCS::Component::constructor {
            current_grid            { getCurrentGridInfo }
            snapshot_list           { getSnapshotListInfo }
            item_list               { getItemListInfo }
            current_grid_node_list  { getCurrentGridNodeListInfo }
            current_grid_frame_list { getCurrentGridFrameListInfo }
            number_display_field    { getNumberField }
            contour_display_field   { getContourField }
            contour_display_level   { getContourLevels }
            beam_display_option     { getBeamDisplayOption }
            current_grid_editable   { getCurrentGridEditable }
            current_grid_resettable { getCurrentGridResettable }
            current_grid_deletable  { getCurrentGridDeletable }
            current_grid_runnable   { getCurrentGridRunnable }
            current_grid_finest     { getCurrentGridFinest }
            show_only_current_grid  { getShowOnlyCurrentGrid }
            show_raster_too         { getShowRasterToo }
            allow_look_around_when_busy { getAllowLookAround }
            only_rotate_phi             { getOnlyRotatePhi }
            current_grid_collected_phi_range  { getCurrentGridPhiRange }
            current_grid_input_phi_range  { getCurrentGridInputPhiRange }
            current_crystal_phi_node_list_for_display { getCurrentCrystalPhiNodeListForDisplay }
            current_crystal_all_phi_node_list { getCurrentCrystalAllPhiNodeList }
            current_grid_phi_osc_runnable { getCurrentGridPhiRunnable }
            current_grid_is_mega_crystal  { getCurrentItemIsMegaCrystal }
            click_to_move                 { getClickToMove }
        }
    } {
        global gMotorBeamWidth
        global gMotorBeamHeight

        set m_beamsizeWrapper [GridBeamSizeWrapper ::\#auto]

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

        set m_strCurrentNode \
        [$m_deviceFactory createString currentGridGroupNode]

        $m_strCurrentNode register $this contents handleCurrentGridNodeChange

        set m_strCrystalStatus [$m_deviceFactory createString crystalStatus]

        set m_strScreeningParameters \
        [$m_deviceFactory createString screeningParameters]

        set m_strCurrentL614Node \
        [$m_deviceFactory createString currentL614Node]

        for {set i 0} {$i < [getMAXGROUP]} {incr i} {
            set name gridGroup$i
            set obj [$m_deviceFactory getObjectName $name]
            ::mediator register $this $obj contents handleStringEvent
        }

        eval configure $args

        set objBeamWidth  [$m_deviceFactory getObjectName $gMotorBeamWidth]
        set objBeamHeight [$m_deviceFactory getObjectName $gMotorBeamHeight]
        set objPreset     [$m_deviceFactory getObjectName collimator_preset]

        ::mediator register $this $objBeamWidth  limits handleBeamSizeEvent
        ::mediator register $this $objBeamHeight limits handleBeamSizeEvent
        ::mediator register $this $objPreset     list   handleBeamSizeEvent

        exportSubComponent grid_beam_size $m_beamsizeWrapper
		announceExist
    }
    destructor {
        $m_objGridGroupConfig unregisterForAllEvents $this handleOperationEvent
        $m_objGridGroupFlip   unregisterForAllEvents $this handleOperationEvent
        $m_objCollectGrid     unregisterForAllEvents $this handleOperationEvent
        $m_objLatestUserSetup unregister $this contents handleLatestSetupChange
        $m_strCurrentNode unregister $this contents handleCurrentGridNodeChange
    }
}
body GridGroup::GridGroup4BluIce::switchGroupNumber { \
    new_number {forced_refresh 0} \
} {
    set m_assignedGroupNum $new_number

    ##_groupId is loaded succesfully
    if {!$forced_refresh && $_groupId == $new_number} {
        return
    }

    if {$new_number < 0} {
        puts "should not have negative groupNumber $new_number for $this"
        _reset
        refreshAll
        return
    }

    set strName gridGroup$new_number
    if {![$m_deviceFactory stringExists $strName]} {
        log_error wrong gridGroup number $new_number
        _reset
        refreshAll
        return
    }

    set obj [$m_deviceFactory getObjectName $strName]
    set contents [$obj getContents]

    set label unknown
    set file not_exists
    foreach {m_runState label file} $contents break

    if {$file == "not_exists"} {
        _reset
        refreshAll
        return
    }
    set path [file join [::config getStr gridGroup.directory] $file]
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
    #puts "handleStringEvent $contents_"

    ###gridGroupXX
    set groupNum [string range [namespace tail $name_] 9 end]

    if {$groupNum != $m_assignedGroupNum} {
        puts "not this group, this=$m_assignedGroupNum event=$groupNum"
        return
    }
    switchGroupNumber $m_assignedGroupNum 1
}
body GridGroup::GridGroup4BluIce::handleOperationEvent { msg_ } {
    foreach {evType opName opId tag gid} $msg_ break

    if {$evType != "stog_operation_update" || $gid != $_groupId} {
        return
    }

    set args [lrange $msg_ 5 end]

    switch -exact -- $tag {
        FORCE_SYNC {
            puts "FORCE_SYNC $args"
            set index [lindex $args 0]
            selectGridIndex $index
        }
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
                    puts "failed to addImageToTop for $w: $errMsg"
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
            selectGridIndex $index
            updateRegisteredComponents snapshot_list
        }
        MODIFY_GRID {
            set id [lindex $args 0]
            eval _modify_grid $args 1

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
            updateRegisteredComponents current_grid_frame_list
            updateRegisteredComponents current_grid_finest
            updateRegisteredComponents current_grid_input_phi_range
            updateRegisteredComponents current_grid_collected_phi_range
            updateBeamSize
        }
        MODIFY_USER_INPUT {
            ### "1" at the end means no status check.
            eval _modify_userInput $args direct 1
            updateRegisteredComponents current_grid
            updateRegisteredComponents current_grid_node_list
            updateRegisteredComponents current_grid_frame_list
            updateRegisteredComponents current_grid_finest
            updateRegisteredComponents current_grid_input_phi_range
            updateRegisteredComponents current_grid_collected_phi_range
            updateBeamSize
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
        NODE_FOR_PHI {
            foreach {id index nodeStatus} $args break
            set grid [_get_grid $id]
            $grid setPhiNodeStatus $index $nodeStatus
            refreshPhiNodeGui $id $index $nodeStatus
        }
        NODE_LIST_FOR_PHI {
            foreach {id nodeList} $args break
            set grid [_get_grid $id]
            $grid setAllPhiNodes $nodeList

            refreshGridGui $id 
        }
        NEXT_FRAME {
            puts "got NEXT_FRAME $args"
            foreach {id nextFrame} $args break
            set grid [_get_grid $id]
            $grid setNextFrame $nextFrame
            if {$id == [getCurrentGridId]} {
                updateRegisteredComponents current_grid_frame_list
            }
        }
        CURRENT_NODE {
            foreach {id index nodeStatus} $args break
            set grid [_get_grid $id]
            $grid setCurrentNodeStatus $index $nodeStatus
            refreshNodeGui $id $index $nodeStatus
        }
        SEQUENCE_LIST {
            foreach {id seq2idx idx2seq} $args break
            set grid [_get_grid $id]
            $grid setSequenceList $seq2idx $idx2seq
            if {$id == [getCurrentGridId]} {
                updateRegisteredComponents current_grid_node_list
                updateRegisteredComponents current_grid_frame_list
                updateRegisteredComponents current_grid_input_phi_range
                updateRegisteredComponents current_grid_collected_phi_range
            }
        }
    }
}
body GridGroup::GridGroup4BluIce::selectGridId { id_ } {
    #puts "selectGridId id=$id_"

    if {$id_ < 0} {
        if {$m_currentGridIndex < 0} {
            return
        }
        clearCurrentGrid
        return
    }

    set index [getGridIndex $id_]
    if {$index < 0} {
        puts "strange, no grid with id=$id_"
        clearCurrentGrid
        return
    }

    setCurrentGridIndex $index
    foreach w $m_registeredImageWidgets {
        #puts "selectGridId w=$w"
        if {[catch {
            $w setCurrentGrid $id_
        } errMsg]} {
            puts "failed to setCurrentGrid for $w: $errMsg"
        }
    }
}
body GridGroup::GridGroup4BluIce::clearCurrentGrid { } {
    set m_currentGrid ""
    set m_currentGridIndex -1

    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w clearCurrentGrid
        } errMsg]} {
            puts "failed to clearCurrentGrid for $w: $errMsg"
        }
    }
    updateRegisteredComponents current_grid
    updateRegisteredComponents item_list
    updateRegisteredComponents current_grid_node_list
    updateRegisteredComponents current_grid_frame_list
    updateRegisteredComponents current_grid_editable
    updateRegisteredComponents current_grid_resettable
    updateRegisteredComponents current_grid_deletable
    updateRegisteredComponents current_grid_runnable
    updateRegisteredComponents current_grid_input_phi_range
    updateRegisteredComponents current_grid_collected_phi_range
    updateRegisteredComponents current_crystal_all_phi_node_list
    updateRegisteredComponents current_crystal_phi_node_list_for_display
    updateRegisteredComponents current_grid_phi_osc_runnable
    updateRegisteredComponents current_grid_is_mega_crystal
    updateBeamSize
}
body GridGroup::GridGroup4BluIce::prepareAddGrid { } {
    if {[catch {dict get $d_userSetupForNextGrid shape} shape]} {
        puts "get shape failed, maybe in system startup: $shape"
        set shape rectangle
    }
    setWidgetToolMode add_${shape}
}
body GridGroup::GridGroup4BluIce::setWidgetToolMode { mode } {
    if {[string range $mode 0 3] == "add_"} {
        clearCurrentGrid
    }
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
        set gid -1
    } else {
        dict set d_currentGridIndex $_groupId $index
        set m_currentGrid [lindex $lo_gridList $index]
        set gid [$m_currentGrid getId]
    }
    #puts "current grid index $index"
    #puts "current grid $m_currentGrid"
    set m_currentGridIndex $index
    updateRegisteredComponents current_grid
    updateRegisteredComponents item_list
    updateRegisteredComponents current_grid_node_list
    updateRegisteredComponents current_grid_frame_list
    updateRegisteredComponents current_grid_editable
    updateRegisteredComponents current_grid_resettable
    updateRegisteredComponents current_grid_deletable
    updateRegisteredComponents current_grid_runnable
    updateRegisteredComponents current_grid_finest
    updateRegisteredComponents current_grid_input_phi_range
    updateRegisteredComponents current_grid_collected_phi_range
    updateRegisteredComponents current_crystal_all_phi_node_list
    updateRegisteredComponents current_crystal_phi_node_list_for_display
    updateRegisteredComponents current_grid_phi_osc_runnable
    updateRegisteredComponents current_grid_is_mega_crystal
    updateBeamSize

    return $gid
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

    set gid  [setCurrentGridIndex $index]
    set ssId [getSnapshotIdForGrid $gid]

    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w moveImageToTop $ssId $_snapshotIdMap 0
            $w setCurrentGrid $gid
        } errMsg]} {
            puts "failed to moveImageToTop for currentGrid for $w: $errMsg"
        }
    }
    return $gid
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
            return $i
        }
    }
    return -1
}
body GridGroup::GridGroup4BluIce::getCurrentGridInfo { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getSetupProperties]
}
body GridGroup::GridGroup4BluIce::getCurrentGridLabel { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getLabel]
}
body GridGroup::GridGroup4BluIce::getCurrentGridShape { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getShape]
}
body GridGroup::GridGroup4BluIce::adjustCurrentGrid { param {extra ""} } {
    if {$m_currentGrid == ""} {
        ## tell caller that we did not do it.
        return 0
    }

    set id [$m_currentGrid getId]
    if {$extra != ""} {
        set extra [dict merge [$m_currentGrid getParameter] $extra]
    }

    set useW ""
    set maxScore -1
    foreach w $m_registeredImageWidgets {
        set score [$w getViewScoreForGrid $id]
        puts "$w score $score"
        if {$score > $maxScore} {
            set maxScore $score
            set useW $w
        }
    }

    if {$maxScore < 10} {
        log_error Please zoom in on the current grid before adjust cell size.
        return 0
    }

    if {[catch {
        $useW adjustGrid $id $param $extra
    } errMsg]} {
        puts "failed to adjustGrid for currentGrid for $w: $errMsg"
        return 0
    }
    return 1
}
body GridGroup::GridGroup4BluIce::adjustCurrentGridOnDisplay { \
display param {extra ""} } {
    if {$m_currentGrid == ""} {
        ## tell caller that we did not do it.
        return 0
    }

    set id [$m_currentGrid getId]
    if {$extra != ""} {
        set extra [dict merge [$m_currentGrid getParameter] $extra]
    }


    if {[catch {
        $display adjustGrid $id $param $extra
    } errMsg]} {
        puts "failed to adjustGrid for currentGrid for $display: $errMsg"
        return 0
    }
    return 1
}
body GridGroup::GridGroup4BluIce::validCurrentGridInput { key valueREF } {
    if {$m_currentGrid == ""} {
        return 0
    }
    upvar $valueREF value

    return [$m_currentGrid validUserInput $key value]
}
body GridGroup::GridGroup4BluIce::getCurrentGridNodeListInfo { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getNodeListInfo]
}
body GridGroup::GridGroup4BluIce::getCurrentCrystalPhiNodeListForDisplay { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getPhiNodeListForDisplay]
}
body GridGroup::GridGroup4BluIce::getCurrentCrystalAllPhiNodeList { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getAllPhiNodeList]
}
body GridGroup::GridGroup4BluIce::getCurrentGridPhiRange { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getCollectedPhiRange]
}
body GridGroup::GridGroup4BluIce::getCurrentGridInputPhiRange { } {
    if {$m_currentGrid == ""} {
        return 0
    }
    return [$m_currentGrid getInputPhiRange]
}
body GridGroup::GridGroup4BluIce::getCurrentGridCamera { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getCamera]
}
body GridGroup::GridGroup4BluIce::getCurrentGridFrameListInfo { } {
    if {$m_currentGrid == ""} {
        return [dict create]
    }
    return [$m_currentGrid createDictForRunCalculator]
}
body GridGroup::GridGroup4BluIce::getCurrentGridBeamSizeInfo { } {
    if {$m_currentGrid == ""} {
        return [getBeamSizeInfoFromLatestUserSetup]
    }
    return [$m_currentGrid getBeamSizeInfo]
}
body GridGroup::GridGroup4BluIce::getCurrentGridBeamSize { } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid getBeamSize]
}
body GridGroup::GridGroup4BluIce::registerImageDisplayWidget { wd } {
    if {[lsearch -exact $m_registeredImageWidgets $wd] < 0} {
        lappend m_registeredImageWidgets $wd
    }
    refreshAll
}
body GridGroup::GridGroup4BluIce::unregisterImageDisplayWidget { wd } {
    set index [lsearch -exact $m_registeredImageWidgets $wd]
    if {$index >= 0} {
        set m_registeredImageWidgets [lreplace $m_registeredImageWidgets \
        $index $index]
    }
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
body GridGroup::GridGroup4BluIce::getItemListInfo { } {
    set result ""
    foreach grid [getGridList] {
        set id      [$grid getId]
        ### label is the same as id for grid.
        set label   [$grid getLabel]
        set status  [$grid getStatus]
        set shape   [$grid getShape]
        set forLCLS [$grid getForLCLS]
        ### new GUI needs shape to decide whether it is crystal

        lappend result [list $id $label $status $shape $forLCLS]
    }
    return [list $m_currentGridIndex $result]
}
body GridGroup::GridGroup4BluIce::updateSnapshotDisplay { } {
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
    if {$_groupId < 0} {
        set index -1
    } elseif {![dict exists $d_currentGridIndex $_groupId]} {
        dict set d_currentGridIndex $_groupId -1
        set index -1
    } else {
        set index [dict get $d_currentGridIndex $_groupId]
    }
    ### this updateRegisteredComponents
    setCurrentGridIndex $index
}
body GridGroup::GridGroup4BluIce::updateBeamSize { } {
    $m_beamsizeWrapper setDesiredBeamSizeInfo [getCurrentGridBeamSizeInfo]
}
body GridGroup::GridGroup4BluIce::refreshAll { } {
    updateSnapshotDisplay
    updateCurrentGrid
    updateBeamSize
    updateByStringCurrentGridGroupNode
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
    if {$status == ""} {
        ## skip
        return
    }
    foreach w $m_registeredImageWidgets {
        if {[catch {
            $w setNode $id $index $status
        } errMsg]} {
            puts "failed to setNode for $w: $errMsg"
        }
    }
    if {$id == [getCurrentGridId]} {
        updateRegisteredComponents current_grid_node_list
        updateRegisteredComponents current_grid_frame_list
        updateRegisteredComponents current_grid_input_phi_range
        updateRegisteredComponents current_grid_collected_phi_range
    }
}
body GridGroup::GridGroup4BluIce::refreshPhiNodeGui {id index status} {
    if {$status == ""} {
        ## skip
        return
    }

    #foreach w $m_registeredImageWidgets {
    #    if {[catch {
    #        $w setNode $id $index $status
    #    } errMsg]} {
    #        puts "failed to setNode for $w: $errMsg"
    #    }
    #}
    if {$id == [getCurrentGridId]} {
        updateRegisteredComponents current_crystal_all_phi_node_list
        updateRegisteredComponents current_crystal_phi_node_list_for_display
        updateRegisteredComponents current_grid_phi_osc_runnable

        ## may need this if we put phi info in the node list.
        #updateRegisteredComponents current_grid_node_list
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
body GridGroup::GridGroup4BluIce::getCurrentItemIsMegaCrystal { } {
    if {$m_currentGrid == ""} {
        return 0
    }
    return [$m_currentGrid getIsMegaCrystal]
}
body GridGroup::GridGroup4BluIce::getCurrentGridPhiRunnable { } {
    if {$m_currentGrid == ""} {
        return 0
    }
    return [$m_currentGrid getPhiRunnable]
}
body GridGroup::GridGroup4BluIce::getCurrentGridHidden { } {
    if {$m_currentGrid == ""} {
        return -1
    }
    return [$m_currentGrid getHide]
}
body GridGroup::GridGroup4BluIce::getCurrentGridFinest { } {
    if {$m_currentGrid == ""} {
        return -1
    }
    foreach {- - beamW beamH} [getSmallestBeamSize] break
    ### mm to micron
    set beamW [expr abs(1000.0 * $beamW)]
    set beamH [expr abs(1000.0 * $beamH)]

    foreach {cellW cellH} [$m_currentGrid getCellSize] break
    set cellW [expr abs($cellW)]
    set cellH [expr abs($cellH)]
    
    if {$cellW >= 1.2 * $beamW || $cellH >= 1.2 * $beamH} {
        return 0
    }
    return 1
}
body GridGroup::GridGroup4BluIce::getSmallestBeamSize { } {

    set deviceFactory [::DCS::DeviceFactory::getObject]
    set gotCollimator 1
    if {![$deviceFactory stringExists collimator_preset]} {
        set gotCollimator 0
    } else {
        set strPreset [$deviceFactory getObjectName collimator_preset]
        set contents [$strPreset getContents]
        if {[llength $contents] < 2} {
            set gotCollimator 0
        }
    }
    if {!$gotCollimator} {
        global gMotorBeamWidth
        global gMotorBeamHeight

        set mtrBeamWidth  [$deviceFactory getObjectName $gMotorBeamWidth]
        set mtrBeamHeight [$deviceFactory getObjectname $gMotorBeamHeight]
        set minW [lindex [$mtrBeamWidth  getEffectiveLowerLimit] 0]
        set minH [lindex [$mtrBeamHeight getEffectiveLowerLimit] 0]
        return [list 0 -1 $minW $minH]
    }
    set strPreset [$deviceFactory getObjectName collimator_preset]
    set microList [$strPreset getMicroCollimatorList]

    set minIndex -1
    ### just a big number
    set minWidth 2000.0
    set minHeight 2000.0
    foreach collimator $microList {
        foreach {index name width height} $collimator break
        if {$width < $minWidth} {
            set minWidth $width
            set minHeight $height
            set minIndex $index
        }
    }
    return [list 1 $minIndex $minWidth $minHeight]
}
body GridGroup::GridGroup4BluIce::setupCurrentGridExposure { name value } {
    if {$m_currentGrid == ""} {
        return ""
    }
    return [$m_currentGrid setupExposure $name $value]
}
