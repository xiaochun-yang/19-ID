#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

#
# SequenceCrystals.tcl
#
# part of Screening UI
# used by Sequence.tcl
#

# ===================================================

package provide BLUICESequenceCrystals 1.0

package require Itcl
package require http
package require Iwidgets
package require BWidget


package require DCSEntry
package require DCSDeviceFactory
package require DCSSpreadsheet
package require DCSMessageBoard
package require DCSScrolledFrame
package require DCSStrategyStatus

package require ListSelection
package require BLUICESIL

global gTmpQList
set gTmpQList ""

class SequenceCrystals {
    inherit ::itk::Widget ::DCS::Component

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    # contructor / destructor
    constructor {args} {
    ::DCS::Component::constructor {-crystalNameList getCrystalNameList \
    -sampleInfo getSampleInfo}
} {
    }
    public method destructor


#    private variable MAX_ROW        100
#yangx change to 192 to cover 12 puck (16sample on each puck)     
    private variable MAX_ROW        192
    private variable MAX_COL        100
    private variable INIT_NUM_LABEL     20
    private variable INIT_NUM_ENTRY     0
    private variable INIT_NUM_SILIMAGE  1

    private variable IMAGES_WIDTH       66
    private variable DEFAULT_WIDTH      10

    protected variable m_numRowParsed  0
    protected variable m_numRowDisplayed  0
    #how many columns will be displayed
    private variable m_nColumn      0
    #how many columnes defined (may include hidden ones)
    private variable m_numColumnDefined 0

    private variable m_numLabelCreated  0
    private variable m_numEntryCreated  0
    private variable m_numSILCreated    0
    private variable m_numLabelUsed     0
    private variable m_numEntryUsed     0
    private variable m_numSILUsed       0
    private variable m_numEditUsed      0

    private variable m_SILID           -1
    private variable m_SILEventID      -1

    #internal states
    protected variable m_indexSelect 0
    protected variable m_indexMounted -1
    protected variable m_indexNext 0

    protected variable m_indexEdit -1
    protected variable m_editCellList ""

    private variable m_preSelect -1
    private variable m_indexRed -1
    

    #local copy of config
    private variable m_updateDataUrl ""
    private variable m_crystalDataUrl ""
    private variable m_cassetteDataUrl ""

    #column mapping between data and view
    private variable m_reservedName "Port Images"
    private variable m_reservedType "label SILImage"
    private variable m_columnMap ""
    #each elment of list will be: component_prefix type index_of_data width
    #type will define how to update the cell: label entry SILImage

    private variable m_headerCellList ""
    private variable m_rowCellList ""

    #this is a hardcoded header for old service
    private variable m_defaultHeader {
        {Port 4 readonly}
        {CrystalID 8 readonly}
        {Protein 8 readonly}
        {Comment 35}
        {Directory 22 readonly}
        {FreezingCond 12 readonly}
        {CrystalCond 72 readonly}
        {Metal 5 readonly}
        {Priority 8 readonly}
        {Person 8 readonly}
        {CrystalURL 25 readonly}
        {ProteinURL 25 readonly}
    }

    private variable m_defaultMini {
        {Port 4}
        {CrystalID 10}
        {Protein 8}
    }
    private variable m_defaultResult {
        {Port 4}
        {CrystalID 8}
        {SystemWarning 15}
        {Score 10}
        {UnitCell 20}
        {Mosaicity 8}
        {Rmsr 8}
        {BravaisLattice 10}
        {Resolution 10}
        {Images 66}
    }


    #it will be overrided immediately by DCSS message upon connection.
    #set by "Update" button to current login user 
    #set by DCSS message to sync with other user's "Update" button 
    private variable m_user "ana"

    private variable m_cassetteListIndex 0
    private variable m_cassetteList {}
    private variable m_crystalList {}
    private variable m_currentCassetteStatus u
    private variable m_indexMap {}
    private variable m_portStatusList {}
    private variable m_lastListUpdateTime 0
    private variable m_mode robot

    ##where are the Port and ID in the columns
    private variable m_PortIndex         -1
    private variable m_IDIndex           -1
    ### if column "Selected" is found, changes of selected button
    ### will be sent to server to save it
    ### dcss will honor the Selected column when it loads the spreadsheet.
    private variable m_SelectedIndex     -1

    private variable m_UniqueIDIndex     -1
    private variable m_reOrientableIndex -1
    private variable m_reOrientInfoIndex -1

    private variable m_currentHeader ""
    private variable m_currentHeaderNameOnly ""
    private variable m_originalAllColumn ""
    private variable m_columnConfigLabel "Full"

    private variable m_clientState offline

    # layout configuration
    private variable m_font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"

    ######data+view model########
    private variable m_headerSelected -1
    private variable m_headerAction ""
    private variable m_headerClickedXPos "0"
    private variable m_headerInMotion 0
    private variable m_menuClicked -1
    private variable m_showColumnData ""
    private variable m_showColumnInited 0
    private variable m_columnConfigResult ""
    private variable m_columnConfigResultNameOnly ""

    private variable m_normalBackground gray
    private variable m_normalForeground black

    #the frozen header site
    private variable m_headerSite

    #these are relative coordate from grid bbox
    private variable m_headerWidthArray
    private variable m_headerBboxArray
    private variable m_needRefreshHeaderInfo 0

    #these are root geometry from winfo rootx rooty width height
    private variable m_selectedHeaderPos "0 0 0 0"
    private variable m_postedMenuPos "0 0 0 0"

    private variable WIDTH_SENSOR 5

    private common s_firstObj ""

    # private methods
    private method getNameWidth { column }
    private method fixHeader { header }
    private method parseHeader { header {forced 0} }
    private method createLabel { how_many_more }
    private method createEntry { how_many_more }
    private method createSILImage { how_many_more }
    private method getNewLabel { }
    private method getNewEntry { }
    private method getNewSILImage { }

    private method unMapAll { }
    private method displayHeader { }
    private method resetHeaderColor { }
    private method parseOneRow { row_no contents }
    private method applyWidth { }
    private method displayAllRow { }

    private method createCrystalSequenceFrame { } {}
    private method CreateCellsAndInitScrollbars
    private method setCellColor { all }
    private method rowConfig { row_no args }
    private method setCurrentActionColor
    private method getCheckbox { index } {}
    private method setCheckbox { index value } {}
    private method bindEventHandlers
    private method calculateNewHeaderIndex { x }

    public method handleHeaderCheckbox
    public method handleCellCheckbox { index} {}
    public method handleCellClick { index col} {}
    public method handleCellMap { row col }
    public method handleNextCrystalClick { index} {}
    public method handleHeaderEnter { i X Y }
    public method handleHeaderLeave { i X Y }
    public method handleHeaderPress { i X Y }
    public method handleHeaderMotion { i X Y }
    public method handleHeaderCursor { i X Y }
    public method handleHeaderRelease { i X Y }
    public method handleHeaderDoubleClick { i X Y }
    public method handleHeaderMap { i }
    public method handleMenuEnter { X Y }
    public method handleMenuLeave { X Y }
    public method handleMenuClick { }
    public method handleMenuUnmap { }
    public method handleColumnMenu { cmd }
    public method handleColumnInsert { name width }
    public method handlePreset { cmd }

    public method handleCassetteSelect
    public method handleCassetteChange
    public method handleCrystalSelectionChange
    public method handleModeChange

    public method handleClientStateChange

    public method handlePortStatusChange

    public method getCrystalNameList { }

    public method getSampleInfo { }

    public method handleUpdateClick {} {}
    public method handleLoadClick {} {}
    public method handleDownloadClick {} {}
    public method handleWebClick {} {}
    public method handleWebIceClick {} {}

    public method handleColumnConfigResultEvent { name_ targetReady_ alias_ contents_ - }
    public method handleColumnEditDone { }
    public method handleColumnEditApply { args }

    private method sendUpdateCassetteRequest { beamlineName user } {}
    private method loadCassetteListFromUrl { beamlineName user } {}
    private method refreshCrystalList { {force_update 0}} {}
    private method loadWebData { url } {}
    private method openWeb { url } {}
    private method sendCheckBoxStates {} {}
    private method trc_msg { text } {}
    private method rebuildCassetteMenuChoices

    private method redisplayWholeSpreadsheet { data }
    private method updateRows { data }

    #methods for starting operations
    private method sendNextCrystalToServer
    private method sendCassetteInfoToServer
    private method sendCrystalListStatesToServer

    #methods for observing operations
    private variable m_sequenceOperation ""

    private method setCassetteInfo
    private method setCrystalListStates
    private method setNextCrystal
    private method setCurrentCrystal

    private method getCrystalStatus { index }

    # public methods
    public method setConfig { attribute value} {}

    private variable beamlineName ""
    private variable m_deviceFactory
    private variable m_robotCassetteObj;#port status
    private variable m_crystalStatusObj;#mode: robot/manual

    private variable m_sil_event_idObj
    
    private method updateCrystalListView

    public method editOneRow { row_no_ }
    public method handleEditClick {} {}
    public method handleDiscardClick {} {}

    public method handleRowUpdateEvent

    public method getSpreadsheetUpdate { }

    private method saveCurrentColumnConfig { }
    private method loadCurrentColumnConfig { }

    private method isColumnConfigEqual { config1 config2 }

    ###re-get grid bbox of headers
    private method refreshHeaderInfo { }

    public proc getGeometry { window }

    public proc getFirstObject { } {
        return $s_firstObj
    }

    private variable m_objCassetteOwner
    private variable m_cassettePermits "1 1 1 1"
    public method handleCassettePermitsChange

    private variable m_casStatusIndex {0 97 194}
    private variable m_cassetteStatus {u u u u}

    private variable m_allCassetteMenuChoices
}

# ===================================================

body SequenceCrystals::constructor {args} {
    array set m_headerWidthArray [list]
    array set m_headerBboxArray [list]
    set m_showColumnData [ColumnHeaderData ::\#auto]

    loadCurrentColumnConfig

    $m_showColumnData register $this -result handleColumnConfigResultEvent

    set beamlineName [::config getConfigRootName]

    set m_crystalDataUrl [::config getCrystalDataUrl] 
    set m_cassetteDataUrl [::config getCassetteDataUrl]
    set m_updateDataUrl [::config getCrystalUpdateDataUrl]

    #m_user will be the default "ana"
    trc_msg "beamlineName=$beamlineName"

    set m_deviceFactory [DCS::DeviceFactory::getObject]
    set m_robotCassetteObj [$m_deviceFactory createString robot_cassette]
    set m_crystalStatusObj [$m_deviceFactory createString crystalStatus]
    set m_sil_event_idObj  [$m_deviceFactory createString sil_event_id]
    #must be same as in screening control
    $m_crystalStatusObj createAttributeFromField mode 2

    set m_objCassetteOwner \
    [$m_deviceFactory createCassetteOwnerString cassette_owner]

    set m_cassetteList {undefined undefined undefined undefined}
    set m_crystalList {}
    
    createCrystalSequenceFrame
    
    eval itk_initialize $args
    set m_sequenceOperation [$m_deviceFactory getObjectName sequenceSetConfig]
    
    #DynamicHelp::register $itk_component(update) balloon "Update crystal cassette information\n(is disabled if a crsytal is mounted)"
    #DynamicHelp::register $itk_component(cassette) balloon "Select a cassette from beamline dewar\n(is disabled if a crsytal is mounted)"
    
    bindEventHandlers

    set strCrystalStatus [$m_deviceFactory createString crystalStatus]
    $strCrystalStatus createAttributeFromField mounted 3
    set strScreeningAction [$m_deviceFactory createString screeningActionList]
    $strScreeningAction createAttributeFromField screeningActive 0

    $itk_component(cassette) addInput "$strCrystalStatus mounted 0 {Cannot change cassette while sample is mounted}"
    $itk_component(cassette) addInput "$strScreeningAction screeningActive 0 {Screening in progress}"
    $itk_component(update) addInput "$strCrystalStatus mounted 0 {Cannot change cassette while sample is mounted}"
    $itk_component(update) addInput "$strScreeningAction screeningActive 0 {Screening in progress}"

    ::mediator register $this ::device::sequenceDeviceState contents handleCassetteChange
    ::mediator register $this ::device::crystalSelectionList contents handleCrystalSelectionChange
    ::mediator register $this ::device::robot_cassette contents handlePortStatusChange
    ::mediator register $this ::device::crystalStatus mode handleModeChange
    ::mediator register $this ::device::sil_event_id contents handleRowUpdateEvent

    
    ::mediator register $this $itk_option(-controlSystem) clientState handleClientStateChange

    ::mediator register $this $m_objCassetteOwner permits handleCassettePermitsChange 
    ::mediator announceExistence $this

    if {$s_firstObj == ""} {
        set s_firstObj $this
    }
}

body SequenceCrystals::destructor {} {
    ::mediator unregister $this ::device::sequenceDeviceState contents
    ::mediator unregister $this ::device::crystalSelectionList contents
    ::mediator unregister $this ::device::robot_cassette contents
    ::mediator unregister $this ::device::crystalStatus mode
    ::mediator unregister $this ::device::sil_event_id contents
    ::mediator unregister $this $itk_option(-controlSystem) clientState
    $m_showColumnData unregister $this -result handleColumnConfigResultEvent
    ::mediator unregister $this $m_objCassetteOwner permits
}

body SequenceCrystals::handleColumnConfigResultEvent { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    #puts "columnconfig: $contents_"

    if {$m_columnConfigResult == $contents_} {
        #puts "no change, skip reconfig columns"
        return
    }

    set m_columnConfigResult $contents_
    set m_columnConfigResultNameOnly ""
    foreach column $m_columnConfigResult {
        set name [lindex $column 0]
        lappend m_columnConfigResultNameOnly $name
    }

    if {$m_currentHeader == ""} {
        ###init
        return
    }

    saveCurrentColumnConfig 

    ##force reparse
    parseHeader $m_currentHeader 1
    ##force refresh
    unMapAll
    applyWidth
    displayHeader
    setCellColor 1
    updateCrystalListView $m_crystalList
    setCurrentActionColor
}
body SequenceCrystals::resetHeaderColor { } {
    for {set index 0} {$index < $m_nColumn} {incr index} {
        $m_headerSite.header$index config \
        -background $m_normalBackground \
        -foreground $m_normalForeground
    }
}
body SequenceCrystals::handleHeaderEnter { i_ X_ Y_ } {
    #puts "header enter: $i_"

    if {$m_headerInMotion} {
        return
    }
    if {$m_headerSelected == $i_} {
        return
    }

    if {$m_needRefreshHeaderInfo} {
        refreshHeaderInfo
        set m_needRefreshHeaderInfo 0
    }


    if {$m_headerSelected >= 0} {
        #puts "un select $m_headerSelected"
        $m_headerSite.header$m_headerSelected config \
        -foreground $m_normalForeground \
        -background $m_normalBackground
    }

    $m_showColumnData selectOnlyOne $i_
    $m_headerSite.header$i_ config \
    -foreground white \
    -background blue
    set m_headerSelected $i_

    set m_selectedHeaderPos [getGeometry $m_headerSite.header$i_]
    foreach {x y w h} $m_selectedHeaderPos break
    set X_ [expr $X_ - 30]
    set Y_ [expr $y + $h]

    $m_headerSite.menu post $X_ $Y_

    set m_postedMenuPos [getGeometry $m_headerSite.menu]
    
    #puts "menu pos: $m_postedMenuPos"
}
body SequenceCrystals::handleHeaderLeave { i_ X_ Y_ } {
    #puts "header leave: $i_"

    if {$m_headerInMotion} {
        return
    }

    set m_selectedHeaderPos [getGeometry $m_headerSite.header$i_]
    foreach {X Y W H} $m_selectedHeaderPos break
    foreach {x y w h} $m_postedMenuPos break

    if {$X_ >= $x && $X_ <= ($x + $w) && $Y_ >= $Y && $Y_ <= ($y + $h)} {
        #puts "in the menu"
        return
    } else {
        #puts "out of menu too"
    }

    $m_headerSite.menu unpost
}
body SequenceCrystals::handleMenuEnter { X_ Y_ } {
    #puts "menu enter"
    set m_menuClicked -1
}
body SequenceCrystals::handleMenuLeave { X_ Y_ } {
    #puts "menu leave: $X_ $Y_"

    if {$m_menuClicked >= 0} {
        #puts "clicked, no change"
        return
    }

    foreach {x y w h} $m_selectedHeaderPos break
    #puts "header: $x $y $w $h"
    if {$X_ >= $x && $X_ <= ($x+$w) && $Y_ >= $y && $Y_ <= ($y+$h)} {
        #puts "in header"
        return
    }

    $m_headerSite.menu unpost
}
body SequenceCrystals::handleMenuClick { } {
    #puts "menu click"
    set m_menuClicked 0
}
body SequenceCrystals::handleMenuUnmap { } {
    #puts "menu unmap"
    if {$m_headerSelected >= 0} {
        #puts "unselect header $m_headerSelected"
        $m_headerSite.header$m_headerSelected config \
        -foreground $m_normalForeground \
        -background $m_normalBackground
    }
    set m_headerSelected -1
}
body SequenceCrystals::handleHeaderPress { i_ x_ y_ } {
    #puts "header click: $i_ $x_ $y_"
    set m_headerClickedXPos $x_
    $m_headerSite.float config \
    -text [$m_headerSite.header$i_ cget -text] \
    -width [$m_headerSite.header$i_ cget -width]

    ####check if very close to left border
    set col [expr $i_ + 2]
    if {$x_ + $WIDTH_SENSOR >= $m_headerWidthArray($col)} {
        set m_headerAction width
        $m_headerSite.header$i_ config -cursor right_tee
    } else {
        set m_headerAction move
        $m_headerSite.header$i_ config -cursor left_side
    }
    $m_headerSite.menu unpost
}
body SequenceCrystals::handleHeaderDoubleClick { i_ x_ y_ } {
    #puts "header double click: $i_ $x_ $y_"
    #### change width to max of current contents

    if {$i_ < 0} {
        set selected [$m_showColumnData curselection]
        #puts "selected: $selected"
        if {[llength $selected] == 1} {
            set i_ [lindex $selected 0]
            #puts "handle menu set i to $i_"
        }
    }
    if {$i_ < 0} {
        #puts "m_headerSelected < 0 skip"
        return
    }

    set max_len 1;#0 mean unlimited
    set col [expr $i_ + 2]
    for {set row 0} {$row < $m_numRowDisplayed} {incr row} {
        set cell [grid slaves $itk_component(crystalList) -row $row -column $col]
        if {$cell != ""} {
            #puts "row $row col $col {[$cell cget -text]}"
            if {[catch {
                set ll [string length [$cell cget -text]]
            } errMsg]} {
                set ll 0
            }
            if {$ll > $max_len} {
                set max_len $ll
            }
        }
    }
    $m_showColumnData width $i_ $max_len
}
body SequenceCrystals::handleHeaderRelease { i_ x_ y_ } {
    #puts "header release: $i_ $x_ $y_"
    set m_headerInMotion 0
    place forget $m_headerSite.float
    set col [expr $i_ + 2]
    foreach {x y w h} $m_headerBboxArray($col) break

    if {$m_headerAction == "width"} {
        if {$x_ <= 0} {
            $m_showColumnData remove
            return
        }
        set old_width [$m_headerSite.header$i_ cget -width]
        set col [expr $i_ + 2]
        set new_width [expr $old_width * $x_ / $m_headerWidthArray($col) + 1]
        #puts "header pixel width $m_headerWidthArray($col)"

        #puts "width changed from $old_width to $new_width"
        if {$new_width == $old_width} {
            return
        }
        $m_showColumnData width $i_ $new_width
    } else {
        set new_index [calculateNewHeaderIndex [expr $x + $x_]]
        #puts "index old: $i_ new $new_index"
        if {$new_index == "end"} {
            set new_index $m_nColumn
        }
        if {$new_index == $i_ || $new_index == $i_ + 1} {
            ### no change
            return
        } elseif {$new_index < $i_} {
            $m_showColumnData moveUp [expr $i_ - $new_index]
        } else {
            $m_showColumnData moveDown [expr $new_index - $i_ - 1]
        }
    }
}
body SequenceCrystals::handleHeaderMotion { i_ x_ y_ } {
    #puts "header motion: $i_ $x_ $y_"

    #flag do not post menu
    set m_headerInMotion 1

    set col [expr $i_ + 2]
    foreach {x y w h} $m_headerBboxArray($col) break
    if {$m_headerAction == "width"} {

        if {$x_ > 0} {
            place $m_headerSite.float -x $x -y $y -width $x_ -height $h
            raise $m_headerSite.float
        } else {
            place forget $m_headerSite.float
        }
    } else {
        place $m_headerSite.float -x [expr $x + $x_ - $m_headerClickedXPos] -y $y -width $w -height $h
        raise $m_headerSite.float
    }
}
body SequenceCrystals::handleHeaderCursor { i_ x_ y_ } {
    #puts "header cursor $i_ $x_ $y_"
    if {$x_ + $WIDTH_SENSOR >= $m_headerWidthArray([expr $i_ + 2])} {
        $m_headerSite.header$i_ config -cursor right_tee
    } else {
        $m_headerSite.header$i_ config -cursor right_side
    }
}
body SequenceCrystals::handleHeaderMap { i_ } {
    #puts "header map: $i_"
    set col [expr $i_ + 2]
    set m_headerBboxArray($col) [grid bbox $m_headerSite $col 0]
    set m_headerWidthArray($col) [lindex $m_headerBboxArray($col) 2]
    #puts " col $col geometry: $m_headerBboxArray($col)"
}

body SequenceCrystals::handleColumnMenu { cmd_ } {
    #puts "column: $cmd_"
    place forget $itk_component(columnMenu)
    resetHeaderColor

    switch -exact -- $cmd_ {
        hide {
            $m_showColumnData remove
        }
        left {
            $m_showColumnData moveUp
        }
        right {
            $m_showColumnData moveDown
        }
        shrink {
            $m_showColumnData shrink
        }
        expand {
            $m_showColumnData expand
        }
        default {
            puts "bad command for column menu: $cmd_"
        }
    }
}
body SequenceCrystals::handleColumnInsert { name_ width_ } {
    $m_showColumnData insertHere "$name_ $width_"
}
body SequenceCrystals::handlePreset { cmd_ } {
    #puts "handle preset $cmd_"
    switch $cmd_ {
        orig {
            $m_showColumnData initialize $m_originalAllColumn
            set m_columnConfigLabel "Full"
            $itk_component(stateHeader) config -text $m_columnConfigLabel
        }
        mini {
            $m_showColumnData initialize $m_defaultMini
            set m_columnConfigLabel "Simple"
            $itk_component(stateHeader) config -text $m_columnConfigLabel
        }
        result {
            $m_showColumnData initialize $m_defaultResult
            set m_columnConfigLabel "Results"
            $itk_component(stateHeader) config -text $m_columnConfigLabel
        }
        edit {
            pack forget $itk_component(scrolledFrame)
            $itk_component(edit_column) config \
            -preload "$m_columnConfigResult" \
            -doneCommand "$this handleColumnEditDone" \
            -submitCommand "$this handleColumnEditApply"
            ##show the widgets
            pack $itk_component(edit_column) -side left -expand 1 -fill both
        }
        save {
            $itk_component(edit_column) config \
            -preload "$m_columnConfigResult"
            $itk_component(edit_column) handleSave
        }
        load {
            $itk_component(edit_column) config \
            -submitCommand "$this handleColumnEditApply"
            $itk_component(edit_column) handleLoad
            $itk_component(edit_column) handleSubmit
        }
        refresh {
            refreshCrystalList 1
        }
        default {
            puts "not support $cmd_ yet"
        }
    }
}
# ===================================================

body SequenceCrystals::createLabel { how_many_more } {
    set f $itk_component(crystalList)
    for {set i 0} {$i < $how_many_more} {incr i} {
        for {set row 0} {$row < $MAX_ROW} {incr row} {
            label $f.label${m_numLabelCreated}_$row \
            -font $m_font \
            -anchor w \
            -relief groove \
            -borderwidth 1
        };#for row
        incr m_numLabelCreated
    };#for i
    puts "m_numLabelCreated=$m_numLabelCreated"
}
body SequenceCrystals::createEntry { how_many_more } {
    set f $itk_component(crystalList)
    for {set i 0} {$i < $how_many_more} {incr i} {
        for {set row 0} {$row < $MAX_ROW} {incr row} {
            entry $f.entry${m_numEntryCreated}_$row -font $m_font
        };#for row
        incr m_numEntryCreated
    };#for i
    puts "m_numEntryCreated=$m_numEntryCreated"
}
body SequenceCrystals::createSILImage { how_many_more } {
    set f $itk_component(crystalList)
    for {set i 0} {$i < $how_many_more} {incr i} {
        for {set row 0} {$row < $MAX_ROW} {incr row} {
            SILImage $f.silImage${m_numSILCreated}_$row \
            -font $m_font
        };#for row
        incr m_numSILCreated
    };#for i
    puts "m_numSILCreated=$m_numSILCreated"
}
body SequenceCrystals::getNewLabel { } {
    set available [expr $m_numLabelCreated -$m_numLabelUsed]
    if {$available <= 0} {
        if {$m_numLabelCreated >= $MAX_COL} {
            return -code error "too many columns exceed MAX_COL=$MAX_COL"
        }
        set num_to_create [expr 2 - $available]
        createLabel $num_to_create
    }
    set result $m_numLabelUsed
    incr m_numLabelUsed
    return $result
}
body SequenceCrystals::getNewEntry { } {
    set available [expr $m_numEntryCreated -$m_numEntryUsed]
    if {$available <= 0} {
        if {$m_numEntryCreated >= $MAX_COL} {
            return -code error "too many columns exceed MAX_COL=$MAX_COL"
        }
        set num_to_create [expr 2 - $available]
        createEntry $num_to_create
    }
    set result $m_numEntryUsed
    incr m_numEntryUsed
    return $result
}
body SequenceCrystals::getNewSILImage { } {
    set available [expr $m_numSILCreated -$m_numSILUsed]
    if {$available <= 0} {
        if {$m_numSILCreated >= $MAX_COL} {
            return -code error "too many columns exceed MAX_COL=$MAX_COL"
        }
        set num_to_create [expr 2 - $available]
        createSILImage $num_to_create
    }
    set result $m_numSILUsed
    incr m_numSILUsed
    return $result
}
body SequenceCrystals::unMapAll { } {
    ##clear grid columnconfig first
    foreach {num_col num_row} [grid size $m_headerSite] break

    set allList [grid slaves $m_headerSite]
    if {[llength $allList] > 0} {
        eval grid forget $allList
    }
    set m_numRowDisplayed 0
    set allList [grid slaves $itk_component(crystalList)]
    if {[llength $allList] > 0} {
        eval grid forget $allList
    }
    set m_numRowDisplayed 0

    set f $itk_component(crystalList)
    for {set i 0} {$i < $num_col} {incr i} {
        grid columnconfigure $f $i -pad 0
        grid columnconfigure $m_headerSite $i -pad 0
    }
}
body SequenceCrystals::displayHeader { } {
    set f $itk_component(crystalList)

    set m_headerCellList [list $itk_component(stateHeaderFrame) \
    $itk_component(checkHeader)]
    set m_rowCellList [list $f.stateROW $f.checkROW]
    set m_editCellList [list $f.stateROW $f.checkROW]
    for {set i 0} {$i < $m_nColumn} {incr i} {
        set column [lindex $m_columnMap $i]
        set obj  [lindex $column 0]
        set type [lindex $column 1]
        set name [lindex $column 3]
        set width [lindex $column 4]
        if {$width ==""} {
            set width 0
        }
        $m_headerSite.header$i configure \
        -text $name \
        -width $width

        lappend m_headerCellList $m_headerSite.header$i
        lappend m_rowCellList $f.${obj}_ROW
        if {$type == "entry"} {
            lappend m_editCellList $f.edit$i
        } else {
            lappend m_editCellList $f.${obj}_ROW
        }
    }
    eval grid $m_headerCellList -stick news
}
body SequenceCrystals::applyWidth { } {
    #puts "applyWidth"
    set f $itk_component(crystalList)

    for {set i 0} {$i < $m_nColumn} {incr i} {
        set column [lindex $m_columnMap $i]
        set obj   [lindex $column 0]
        set type  [lindex $column 1]
        set width [lindex $column 4]

        $f.edit$i config -width $width

        for {set row 0} {$row < $MAX_ROW} {incr row} {
            $f.${obj}_$row config \
            -width $width

            bind $f.${obj}_$row <Button-1> "$this handleCellClick $row $i"
            bind $f.${obj}_$row <Map> "$this handleCellMap $row $i"
            if {$type == "SILImage"} {
                $f.${obj}_$row config -clickCommand "$this handleCellClick $row $i"
            }
        }
    }
}
body SequenceCrystals::parseOneRow { row_no contents } {
    #puts "parseOneRow $row_no"

    set n_data [llength $contents]
    if {$n_data != $m_numColumnDefined && $row_no == 0} {
        puts "warning column defined: $m_numColumnDefined data: $n_data"
    }

    set f $itk_component(crystalList)

    for {set i 0} {$i < $m_nColumn} {incr i} {
        set column [lindex $m_columnMap $i]
        
        set obj   [lindex $column 0]
        set type  [lindex $column 1]
        set index [lindex $column 2]

        set new_contents [lindex $contents $index]
        set new_contents [string trim $new_contents]
        set new_contents [string map {\n { }} $new_contents]

        switch -exact -- $type {
            label {
                $f.${obj}_$row_no config \
                -text $new_contents
            }
            entry {
                ###same as label
                $f.${obj}_$row_no config \
                -text $new_contents

                ### extra
                if {$row_no == $m_indexEdit} {
                    $f.edit$i delete 0 end
                    $f.edit$i insert 0 $new_contents
                }
            }
            SILImage {
                $f.${obj}_$row_no config \
                -contents $new_contents
            }
        }
    }
}
body SequenceCrystals::displayAllRow { } {
    #puts "displayAllRow: parsed: $m_numRowParsed displayed: $m_numRowDisplayed"
    if {$m_numRowParsed == $m_numRowDisplayed} {
        return
    }

    set f $itk_component(crystalList)
    if {$m_numRowParsed > $m_numRowDisplayed} {
        for {set row $m_numRowDisplayed} {$row < $m_numRowParsed} {incr row} {
            regsub -all ROW $m_rowCellList $row oneRow
            eval grid $oneRow -sticky news -row $row
            grid $f.state$row -sticky we
        }
    } else {
        for {set row $m_numRowParsed} {$row < $m_numRowDisplayed} {incr row} {
            regsub -all ROW $m_rowCellList $row oneRow
            eval grid forget $oneRow
        }
    }
    ####move view to top
    $itk_component(scrolledFrame) yview moveto 0

    set m_numRowDisplayed $m_numRowParsed
}
body SequenceCrystals::getNameWidth { column } {
    set name [lindex $column 0]
    set width [lindex $column 1]
    if {$name == ""} {
        log_error "empty column definition"
        return -code error "bad spreadsheet header: empty column name"
    }
    if {$name == "Images" && $width != $IMAGES_WIDTH} {
        puts "fixheader: set Images width to $IMAGES_WIDTH"
        set width $IMAGES_WIDTH
    } else {
        if {![string is integer -strict $width] || $width <= 0} {
            set width $DEFAULT_WIDTH
            puts "fixheader: changed column $name width to default $DEFAULT_WIDTH"
        }
    }
    return [list $name $width]
}
body SequenceCrystals::fixHeader { header } {
    #make sure each header at least has name and width
    #no name will cause an error
    #no width will lead to insert a default width
    set result ""
    foreach column $header {
        set new_column [getNameWidth $column]
        eval lappend new_column [lrange $column 2 end]
        lappend result $new_column
    }
    return $result
}
body SequenceCrystals::parseHeader { header {forced 0} } {
    puts "parseHeader $header"
    #puts "forced: $forced"

    set header [fixHeader $header]

    if {$m_currentHeader == $header && !$forced} {
        #puts "same as old header, skip"
        return 0
    }

    if {[llength $header] < 3} {
        log_error "bad spreadsheet header: too short $header"
        return -code error "bad spreadsheet header: too less columns defined"
    }

    if {$m_currentHeader != $header} {
        ###reset m_columnConfigResult to ORIGINAL if it matches original
        if {$m_columnConfigResult == $m_originalAllColumn} {
            set m_columnConfigResult ORIGINAL
            set m_showColumnInited 0
        }

        set foundPort 0
        set m_currentHeaderNameOnly ""
        set m_originalAllColumn ""
        $itk_component(menu_insert) delete 0 end
        foreach column $header {
            set name [lindex $column 0]
            set width [lindex $column 1]
            set attributes [lindex $column 2]

            if {[string equal -nocase $name "Port"]} {
                set foundPort 1
            }
            
            lappend m_currentHeaderNameOnly $name

            if {[lsearch $attributes hide] >= 0} {
                continue
            }

            lappend m_originalAllColumn "$name $width"
            $itk_component(menu_insert) add command \
            -label $name \
            -command "$this handleColumnInsert $name $width"
        }
        if {!$foundPort} {
            return -code error "bad spreadsheet header: no Port column defined"
        }
        set m_currentHeader $header
        set m_numColumnDefined [llength $header]
        $itk_component(edit_column) config \
        -input "$m_originalAllColumn"

        set m_PortIndex [lsearch $m_currentHeaderNameOnly "Port"]
        set m_IDIndex   [lsearch $m_currentHeaderNameOnly "CrystalID"]
        if {$m_IDIndex < 0} {
            set m_IDIndex $m_PortIndex
        }
        set m_SelectedIndex   [lsearch $m_currentHeaderNameOnly "Selected"]
        if {$m_SelectedIndex >= 0} {
            puts "Selected column found at $m_SelectedIndex"
        }
        set m_UniqueIDIndex   [lsearch $m_currentHeaderNameOnly "UniqueID"]
        if {$m_UniqueIDIndex >= 0} {
            puts "UniqueID column found at $m_UniqueIDIndex"
        }

        set m_reOrientableIndex [lsearch $m_currentHeaderNameOnly "ReOrientable"]
        if {$m_reOrientableIndex >= 0} {
            puts "reOrientable column found at $m_reOrientableIndex"
        }

        set m_reOrientInfoIndex [lsearch $m_currentHeaderNameOnly "ReOrientInfo"]
        if {$m_reOrientInfoIndex >= 0} {
            puts "reOrientInfo column found at $m_reOrientInfoIndex"
        }
    }

    set m_columnMap ""
    set m_numLabelUsed 0
    set m_numEntryUsed 0
    set m_numSILUsed 0
    set m_numEditUsed 0

    if {$m_columnConfigResult == "" || $m_columnConfigResult == "ORIGINAL"} {
        for {set index 0} {$index < $m_numColumnDefined} {incr index} {
            set column [lindex $header $index]

            ##########name##########
            set name [lindex $column 0]
            ##########width##########
            set width [lindex $column 1]
            ##########type##########
            set r_index [lsearch -exact $m_reservedName $name]
            if {$r_index >= 0} {
                set type [lindex $m_reservedType $r_index]
            } else {
                ### decide type from attributes
                set attributes [lindex $column 2]
                set type entry
                if {[lsearch $attributes readonly] >= 0} {
                    set type label
                }
                if {[lsearch $attributes hide] >= 0} {
                    continue
                }
            }

            switch -exact -- $type {
                entry -
                label {
                    set obj label[getNewLabel]
                }
                SILImage {
                    set obj silImage[getNewSILImage]
                }
            }

            #####save to mapping
            lappend m_columnMap "$obj $type $index $name $width"
        };#for column
        set m_columnConfigResult $m_originalAllColumn 
        set m_columnConfigResultNameOnly ""
        foreach column $m_columnConfigResult {
            set name [lindex $column 0]
            lappend m_columnConfigResultNameOnly $name
        }
    } else {
        foreach column $m_columnConfigResult {
            foreach {name width} [getNameWidth $column] break
            set index [lsearch $m_currentHeaderNameOnly $name]
            if {$index < 0} {
                log_error column $name dicarded, not found in data
                continue
            }
            set orig_column [lindex $header $index]
            ##########type##########
            set r_index [lsearch -exact $m_reservedName $name]
            if {$r_index >= 0} {
                set type [lindex $m_reservedType $r_index]
            } else {
                ### decide type from attributes
                set attributes [lindex $orig_column 2]
                set type entry
                if {[lsearch $attributes readonly] >= 0} {
                    set type label
                }
                if {[lsearch $attributes hide] >= 0} {
                    continue
                }
            }
            switch -exact -- $type {
                entry -
                label {
                    set obj label[getNewLabel]
                }
                SILImage {
                    set obj silImage[getNewSILImage]
                }
            }
            #####save to mapping
            lappend m_columnMap "$obj $type $index $name $width"
        }
    }


    set m_nColumn [llength $m_columnMap]
    #puts "map: $m_columnMap"


    if {!$m_showColumnInited} {
        $m_showColumnData initialize $m_columnConfigResult 
        set m_showColumnInited 1
    }

    #####enable/disable insert menu#####
    set multiInstance 0
    ##### menu_insert has the same list of m_originalAllColumn
    set ll [llength $m_originalAllColumn]
    for {set i 0} {$i < $ll} {incr i} {
        set name [$itk_component(menu_insert) entrycget $i -label]
        set index [lsearch $m_columnConfigResultNameOnly $name]

        if {$multiInstance || $index < 0} {
            $itk_component(menu_insert) entryconfigure $i -state normal
        } else {
            $itk_component(menu_insert) entryconfigure $i -state disabled
        }
    }

    return 1
}
::itcl::body SequenceCrystals::createCrystalSequenceFrame { } {
    #puts "createCrystal frame"
    # Create a frame caption
    itk_component add header {
        frame $itk_interior.header
    } {
    }

    itk_component add cassette {
        DCS::MenuEntry $itk_component(header).selectCassette \
        -activeClientOnly 1 \
        -systemIdleOnly 0 \
        -entryWidth 28 \
        -entryMaxLength 150 \
        -promptText "Cassette:" \
        -dropdownAnchor w \
        -showEntry 0
    } {}

    itk_component add update {
        DCS::Button $itk_component(header).buttonUpdate -text {Update} -font $m_font -padx 0
    } {
    }

    rebuildCassetteMenuChoices

    itk_component add load {
        button $itk_component(header).buttonLoad \
        -text Import \
        -font $m_font \
        -padx 0 \
        -command "$this handleLoadClick"
    } {
    }

    itk_component add download {
        button $itk_component(header).download \
        -text {Export} \
        -font $m_font \
        -padx 0 \
        -command "$this handleDownloadClick"
    } {
    }

    itk_component add web {
        DCS::DropdownMenu $itk_component(header).buttonWeb \
        -systemIdleOnly 0 \
        -activeClientOnly 0 \
        -text "Web" \
        -state normal

    } {
    }

    $itk_component(web) add command \
    -label Spreadsheet \
    -foreground blue \
    -command "$this handleWebClick"

    $itk_component(web) add command \
    -label WebIce \
    -foreground blue \
    -command "$this handleWebIceClick"

    itk_component add edit {
        DCS::Button $itk_component(header).edit \
        -systemIdleOnly 0 \
        -activeClientOnly 0 \
        -width 6 \
        -text Edit \
        -command "$this handleEditClick"
    } {
    }

    # Create a scrolling canvas for the Table
    itk_component add crystalFrame {
        frame $itk_interior.c
    }

    itk_component add edit_column {
        ListSelectWidget $itk_component(crystalFrame).edit_column \
        -background #c04080 \
        -presetList "[list [list Simple $m_defaultMini] [list Results $m_defaultResult]]"
    } {
    }

    itk_component add scrolledFrame {
        #::iwidgets::scrolledframe $itk_component(crystalFrame).canvas -vscrollmode static -hscrollmode static
        DCS::ScrolledFrame $itk_component(crystalFrame).canvas -vscrollmode static -hscrollmode static
    } {}

    set childsite [$itk_component(scrolledFrame) childsite]
    set m_headerSite [$itk_component(scrolledFrame) vfreezesite]

    itk_component add crystalList {
        frame $childsite.f
    } {
    }

    itk_component add noAccess {
        label $childsite.nn \
        -text "access to cassette denied"
    } {
    }

    pack $itk_component(crystalList) -expand yes -fill both

    set ch $itk_component(crystalList)

    set gray [$ch cget -background]

    itk_component add stateHeaderFrame {
        frame $m_headerSite.stateHeaderF \
    } {
    }
    bind $itk_component(stateHeaderFrame) <Map> "$this handleHeaderMap -2"

    itk_component add stateHeaderPrompt {
        label $itk_component(stateHeaderFrame).prompt \
        -text "View:"
    } {
    }
    itk_component add stateHeader {
        menubutton $itk_component(stateHeaderFrame).text \
        -text $m_columnConfigLabel \
        -width 5 \
        -menu $itk_component(stateHeaderFrame).text.menu \
        -relief sunken \
        -activebackground blue \
        -activeforeground white \
        -font $m_font \
        -anchor w \
        -background white
    } {}
    itk_component add stateHeaderArrow {
        label $itk_component(stateHeaderFrame).img \
        -image [DCS::MenuEntry::getArrowImage] \
        -width 16 \
        -anchor c \
        -relief raised
    } {
    }
    pack $itk_component(stateHeaderPrompt) -side left
    pack $itk_component(stateHeader) -side left -expand 1 -fill both
    pack $itk_component(stateHeaderArrow) -side left
	if { [info tclversion] < 8.4 } {
        bind $itk_component(stateHeaderArrow) <Button-1> \
        "tkMbPost $itk_component(stateHeader) %X %Y"
        bind $itk_component(stateHeaderArrow) <ButtonRelease-1> \
        "tkMbButtonUp $itk_component(stateHeader)"
	} else {
        bind $itk_component(stateHeaderArrow) <Button-1> \
        "tk::MbPost $itk_component(stateHeader) %X %Y"
        bind $itk_component(stateHeaderArrow) <ButtonRelease-1> \
        "tk::MbButtonUp $itk_component(stateHeader)"
    }


    itk_component add stateHeaderMenu {
        menu $itk_component(stateHeader).menu \
        -tearoff 0 \
        -activebackground blue \
        -activeforeground white
    }

    $itk_component(stateHeaderMenu) add command \
    -label "Full View" \
    -command "$this handlePreset orig"

    $itk_component(stateHeaderMenu) add command \
    -label "Simple View" \
    -command "$this handlePreset mini"

    if {[::config getLockSILUrl] != ""} {
        $itk_component(stateHeaderMenu) add command \
        -label "Results View" \
        -command "$this handlePreset result"
    }

    $itk_component(stateHeaderMenu) add separator

    $itk_component(stateHeaderMenu) add command \
    -label "Save Custom View" \
    -command "$this handlePreset save"

    $itk_component(stateHeaderMenu) add command \
    -label "Load Custom View" \
    -command "$this handlePreset load"

    ####no need any more after we can drag and change width online
    #$itk_component(stateHeaderMenu) add command \
    #-label "Customize" \
    #-command "$this handlePreset edit"

    $itk_component(stateHeaderMenu) add separator

    $itk_component(stateHeaderMenu) add command \
    -label "Refresh" \
    -command "$this handlePreset refresh"

    itk_component add checkHeader {
        ::DCS::Checkbutton $m_headerSite.checkHeader -selectcolor blue -systemIdleOnly 0
    } {} 
    bind $itk_component(checkHeader) <Map> "$this handleHeaderMap -1"

    #$itk_component(stateHeader) config -background $gray
    $itk_component(checkHeader) config -background $gray
    
    #floating header
    label $m_headerSite.float \
    -relief groove \
    -font $m_font \
    -anchor w \
    -borderwidth 1 \
    -background green
    # create the column headers
    for {set i 0} {$i < $MAX_COL} {incr i} {
        label $m_headerSite.header$i \
        -relief groove \
        -font $m_font \
        -anchor w \
        -borderwidth 1 \
        -background #c0c0ff
        #-background $gray

        bind $m_headerSite.header$i <Enter> "+$this handleHeaderEnter $i %X %Y"
        bind $m_headerSite.header$i <Leave> "+$this handleHeaderLeave $i %X %Y"
        bind $m_headerSite.header$i <Button-1> "+$this handleHeaderPress $i %x %y"
        bind $m_headerSite.header$i <Double-Button-1> "+$this handleHeaderDoubleClick $i %x %y"
        bind $m_headerSite.header$i <Button-2> "+$this handleHeaderDoubleClick $i %x %y"
        bind $m_headerSite.header$i <ButtonRelease-1> "+$this handleHeaderRelease $i %x %y"
        bind $m_headerSite.header$i <B1-Motion> "+$this handleHeaderMotion $i %x %y"
        bind $m_headerSite.header$i <Motion> "+$this handleHeaderCursor $i %x %y"
        bind $m_headerSite.header$i <Map> "+$this handleHeaderMap $i"
    }

    itk_component add columnMenu {
        menu $m_headerSite.menu \
        -tearoff 0 \
        -activebackground blue \
        -activeforeground white
    } {
    }

        bind $m_headerSite.menu <Enter> "+$this handleMenuEnter %X %Y"
        bind $m_headerSite.menu <Leave> "+$this handleMenuLeave %X %Y"
        bind $m_headerSite.menu <Button-1> "+$this handleMenuClick"
        bind $m_headerSite.menu <Unmap> "+$this handleMenuUnmap"

    set m_normalForeground [$m_headerSite.header0 cget -foreground]
    set m_normalBackground [$m_headerSite.header0 cget -background]

    CreateCellsAndInitScrollbars

    createLabel $INIT_NUM_LABEL
    createEntry $INIT_NUM_ENTRY
    createSILImage $INIT_NUM_SILIMAGE

        $itk_component(columnMenu) add command \
        -label "hide" \
        -command "$this handleColumnMenu hide"

        $itk_component(columnMenu) add command \
        -label "<-max->" \
        -command "$this handleHeaderDoubleClick -1 0 0"

        $itk_component(columnMenu) add cascade \
        -label "insert" \
        -menu $itk_component(columnMenu).insert

        itk_component add menu_insert {
            menu $itk_component(columnMenu).insert \
            -tearoff 0 \
            -activebackground blue \
            -activeforeground white
        } {
        }

    #####create entrys for editing
    set f $itk_component(crystalList)
    for {set i 0} {$i < $MAX_ROW} {incr i} {
        entry $f.edit$i -font $m_font -background white
        bind $f.edit$i <Escape> "$this handleDiscardClick"
    }

    set m_indexSelect 0
    setCellColor 1
    #setCurrentActionColor

    itk_component add crystal_msg {
        DCS::MessageBoard $itk_interior.msg \
        -width 50
    } {
    }
    $itk_component(crystal_msg) addStrings scn_crystal_msg

    pack $itk_component(cassette) -side left

    if {[::config getLockSILUrl] == ""} {
        pack $itk_component(update) -side left
        pack $itk_component(load) -side left
        pack $itk_component(web) -side left
    } else {
        pack $itk_component(web) -side left
        pack $itk_component(load) -side left
        pack $itk_component(download) -side left
        pack $itk_component(edit) -side left
    }

    pack $itk_component(header) -side top -fill x -expand false
    pack $itk_component(scrolledFrame) -side left -fill both -expand true
    pack $itk_component(crystalFrame) -side top -fill both -expand true
    pack $itk_component(crystal_msg) -side top -fill x
}

::itcl::body SequenceCrystals::rebuildCassetteMenuChoices { } {
    set cassetteChoices ""
    set m_allCassetteMenuChoices ""

    set locationList [RobotBaseWidget::getCassetteLabelList]
    set i -1
    foreach cassette $m_cassetteList {
        incr i
        set location [lindex $locationList $i]
        set permit   [lindex $m_cassettePermits $i]
        set status   [lindex $m_cassetteStatus $i]
        if {$status == "-"} {
            set text "$location: NOT_EXIST"
        } else {
            if {$permit == "1"} {
                set text "$location: $cassette"
            } else {
                set text "$location: NOT_PERMIT_TO_ACCESS"
            }
        }
        lappend m_allCassetteMenuChoices $text
        if {$status != "-" || $i == $m_cassetteListIndex} {
            lappend cassetteChoices $text
        }
    }
    
    $itk_component(cassette) configure -menuChoices $cassetteChoices

    #puts "first cassette value:  [lindex $cassetteChoices $index_]"
    #$itk_component(cassette) configure -onSubmit ""
    $itk_component(cassette) setValue \
    [lindex $m_allCassetteMenuChoices $m_cassetteListIndex] 1
    #$itk_component(cassette) config -onSubmit "$this handleCassetteSelect"

    #puts "CHOICES $cassetteChoices"
}



# ===================================================

::itcl::body SequenceCrystals::CreateCellsAndInitScrollbars {} {

    set f $itk_component(crystalList)

    # Create and grid the data entries
    for {set i 0} {$i < $MAX_ROW} {incr i} {
        label $f.state$i \
        -font $m_font \
        -text $i \
        -width 12
        ::DCS::Checkbutton $f.check$i -selectcolor blue -systemIdleOnly 0

        bind $f.state$i <Map> "$this handleCellMap $i -2"
        bind $f.check$i <Map> "$this handleCellMap $i -1"
    }
}


::itcl::body SequenceCrystals::updateCrystalListView { data } {
    set f $itk_component(crystalList)

    # Create and grid the data entries
    set m_numRowParsed [llength $data]
    if {$m_numRowParsed > $MAX_ROW} {
        set rows_cut [expr "$m_numRowParsed - $MAX_ROW"]
        set m_numRowParsed $MAX_ROW
        trc_msg "too many rows: $rows_cut rows discarded"
    }
    
    for {set i 0} {$i < $m_numRowParsed} {incr i} {
        set row_contents [lindex $data $i]
        parseOneRow $i $row_contents
    }

    displayAllRow
}

# ===================================================

body SequenceCrystals::rowConfig { row_no args } {
    set f $itk_component(crystalList)
    for {set i 0} {$i < $m_nColumn} {incr i} {
        set column [lindex $m_columnMap $i]
        set obj [lindex $column 0]
        eval $f.${obj}_$row_no config $args
    }
}
::itcl::body SequenceCrystals::setCellColor { all } {
    # show selected row with darkblue background

    ###here is a place more than necessary
    #updateRegisteredComponents -sampleInfo

    set blue #a0a0c0

    set nElements $MAX_ROW 
    set sel $m_indexSelect
    
    set f $itk_component(crystalList)

    set gray [$f cget -background]

    if {!$all} {
        if {$m_indexSelect == $m_preSelect} return

        if {$m_preSelect >=0 } {
            set row $m_preSelect
            if {$row % 2} {
                set bb #e0e0e0
            } else {
                set bb $gray
            }
            rowConfig $m_preSelect -background $bb
        }
        if {$m_indexSelect >= 0} {
            rowConfig $m_indexSelect -background $blue
        }
        set m_preSelect $m_indexSelect
        return
    }
    
    # reset all cells to gray
    for {set i 0} {$i < $m_nColumn} {incr i} {
        set column [lindex $m_columnMap $i]
        set obj [lindex $column 0]
        for {set row 0} {$row < $nElements} {incr row} {
            if {$row % 2} {
                set bb #e0e0e0
            } else {
                set bb $gray
            }
            $f.${obj}_$row config \
            -background $bb
        }
        $f.${obj}_$sel config \
        -background $blue
    }
    set m_preSelect $m_indexSelect
}

# ===================================================
::itcl::body SequenceCrystals::setCurrentActionColor { } {
    # show current action with red arrow
    set red #c04080
    set green #00a040
    set yellow #d0d000

    set f $itk_component(crystalList)    
    #get default background color
    set gray [$f cget -background]

    set honorPortStatus 0
    if {$m_mode == "robot" && $m_cassetteListIndex > 0 && $m_cassetteListIndex < 4} {
        set honorPortStatus 1
    }


    ## take care of pink row
    if {$m_indexRed >= 0} {
        rowConfig  $m_indexRed -foreground black
        set m_indexRed -1
    }

    # reset all cells to gray
    for {set i 0} {$i < $m_numRowDisplayed} {incr i} {
        set item $f.state$i
        set display_text [expr $i +1]
        if {$honorPortStatus} {
            set port_status [getCrystalStatus $i]
            switch -exact -- $port_status {
                j {
                    append display_text " port jam"
                }
                b {
                    append display_text " port bad"
                }
                - {
                    append display_text " no port"
                }
                0 {
                    append display_text " empty"
                }
            }
        }
        $item config -text $display_text

        ######if the multi pink rows happen again, take out the comment
        #rowConfig $i -foreground black

        #treat the currently mounted sample special
        if { $i == $m_indexMounted } {
            $item config -text "Mounted->" 
            bind $item <Enter> "" 
		    bind $item <Leave> ""

            # set text color red
            $item config -background $red
            rowConfig $i -foreground $red
            set m_indexRed $m_indexMounted
            continue
        }

        if { $i == $m_indexNext } {
           $item config -text "Mount Next->" 
           $item config -background $green
           bind $item <Enter> "" 
		   bind $item <Leave> ""
           continue
        }
         
        if {[string length $display_text] > 3} {
            $item config -background grey85
            bind $item <Enter> ""
	        bind $item <Leave> ""
        } elseif {$m_clientState != "active"} {
            $item config -background #c0c0ff 
            bind $item <Enter> ""
	        bind $item <Leave> ""
        } else {
            $item config -background #c0c0ff 
            #Let the user know what will happen if they click
            bind $item <Enter> [list $item config -text "Mount Next->"]
	        bind $item <Leave> [list $item config -text $display_text ]
        }
    }
    
}

# ===================================================


::itcl::body SequenceCrystals::getCheckbox { index_ } {
    
    set check $itk_component(crystalList).check$index_ 
    
    return [$check get]
}

# ===================================================

::itcl::body SequenceCrystals::setCheckbox { index_ value_ } {

    set check $itk_component(crystalList).check$index_ 

    $check setValue $value_
}

# ===================================================

::itcl::body SequenceCrystals::bindEventHandlers { } {
    
    $itk_component(cassette) config -onSubmit "$this handleCassetteSelect"
    $itk_component(update) config -command "$this handleUpdateClick"
    $itk_component(checkHeader) config -command "$this handleHeaderCheckbox"
    
    set f $itk_component(crystalList)
    for {set i 0} {$i < $MAX_ROW} {incr i} {
        bind $f.state$i <Button-1> "$this handleNextCrystalClick $i"
        $f.check$i config -command "$this handleCellCheckbox $i"
    }
}

::itcl::body SequenceCrystals::calculateNewHeaderIndex { x_ } {
    #puts "calculateNewHeaderIndex $x_"
    for {set i 0} {$i < $m_nColumn} {incr i} {
        set col [expr $i + 2]
        foreach {x y w h} $m_headerBboxArray($col) break
        #puts "header $i col: $col $x $y $w $h"
        if {$x_ <= ($x + $w)} {
            return $i
        }
    }
    return end
}

# ===================================================

::itcl::body SequenceCrystals::handleHeaderCheckbox {} {
    # the checkbox in the header of the table was selected
    
    # find out the state of the checkbox
    set boxState [$itk_component(checkHeader) get]
    
    #trc_msg "handleHeaderCheckbox=$boxState"
    
    # set all CellCheckboxes to this state
    for {set i 0} {$i < $m_numRowDisplayed} {incr i} {
        if { $i==$m_indexMounted } {
            continue
        }
        setCheckbox $i $boxState
    }
    sendCheckBoxStates
}


# ===================================================

::itcl::body SequenceCrystals::handleCellCheckbox { index} {
    trc_msg "handleCellCheckbox= $index"
    sendCheckBoxStates
}

::itcl::body SequenceCrystals::getSampleInfo { } {
    set line [lindex $m_crystalList $m_indexSelect]
    set uniqueID [lindex $line $m_UniqueIDIndex]
    set reOrientable [lindex $line $m_reOrientableIndex]
    set reOrientInfo [lindex $line $m_reOrientInfoIndex]
    set port         [lindex $line $m_PortIndex]

    return [list \
    $m_cassetteListIndex \
    $m_indexSelect \
    $uniqueID \
    $reOrientable \
    $reOrientInfo \
    $port \
    ]
}

# ===================================================

::itcl::body SequenceCrystals::handleCellClick { index col} {

    trc_msg "handleCellClick=$index $col"
    
    set m_indexSelect $index
    updateRegisteredComponents -sampleInfo
    
    setCellColor 0
    setCurrentActionColor

    #deal with special
    set column [lindex $m_columnMap $col]
    set obj [lindex $column 0]
    set type  [lindex $column 1]

    set f $itk_component(crystalList)
    switch -exact -- $type {
        label {
            set contents [$f.${obj}_$index cget -text]
            if {[string equal -nocase -length 6 $contents "http://"]} {
                openWeb $contents
            }
        }
        SILImage {
            $f.${obj}_$index flip
        }
    }

    #if in edit mode, move to current line
    if {$m_indexEdit >= 0} {
        editOneRow $index
    }
}

::itcl::body SequenceCrystals::handleCellMap { row col} {
    #puts "cell map $row $col"
    if {$row != $m_numRowDisplayed - 1} return
    #puts "cell map $row $col"

    incr col 2
    #puts "cellMap row $row col $col"
    foreach {x y w h} [grid bbox $itk_component(crystalList) $col $row] break
    #puts "cell: $x $y $w $h"

    if {[info exists m_headerWidthArray($col)]} {
        set header_w $m_headerWidthArray($col)
        #puts "header width: $header_w"
        if {$header_w > $w} {
            puts "set pad [expr $header_w - $w] for column $col"
            grid columnconfigure $itk_component(crystalList) $col -pad [expr $header_w - $w]
        } elseif {$header_w < $w} {
            puts "!!!!header $header_w < cell $w in width for column $col"
            grid columnconfigure $m_headerSite $col -pad [expr $w - $header_w]
            set m_needRefreshHeaderInfo 1
        }
    }
}
# ===================================================

::itcl::body SequenceCrystals::handleNextCrystalClick { index } {
    trc_msg "handleNextCrystalClick= $index"
    
    #set m_indexNext $index
    #setCheckbox $index 1
    
    #setCurrentActionColor
    sendNextCrystalToServer $index
}

body SequenceCrystals::handleClientStateChange {  Name_ targetReady_ alias_ state_ - } {
    if { ! $targetReady_} return
    #puts "handle client state change: $state_"

    set m_clientState $state_

    set f $itk_component(crystalList)

    #setting all entry state
    set entry_state disabled
    if {$m_clientState == "active"} {
        set entry_state normal
    }
    for {set row 0} {$row < $MAX_ROW} {incr row} {
        for {set i 0} {$i < $m_numEntryCreated} {incr i} {
            $f.entry${i}_$row config -state $entry_state
        }
    }

    #enable/disable hooving mount next->
    setCurrentActionColor 
}
#this is the handler for the string change
::itcl::body SequenceCrystals::handleCrystalSelectionChange {  stringName_ targetReady_ alias_ crystalSelectState_ - } {
    if { ! $targetReady_} return

    if {$crystalSelectState_ == ""} return
    #puts "handle Crystal selection"

    setCurrentCrystal [lindex $crystalSelectState_ 0]
    setNextCrystal [lindex $crystalSelectState_ 1]
    setCrystalListStates [lindex $crystalSelectState_ 2]
}

::itcl::body SequenceCrystals::handlePortStatusChange {  stringName_ targetReady_ alias_ portStatusList_ - } {
    if { ! $targetReady_} return
    #puts "handle port status change: $portStatusList_"

    set need_refresh 0
    for {set i 0} {$i < 3} {incr i} {
        set index [lindex $m_casStatusIndex $i]
        set status [lindex $portStatusList_ $index]
        set j [expr $i + 1]
        set old_status [lindex $m_cassetteStatus $j]
        set m_cassetteStatus [lreplace $m_cassetteStatus $j $j $status]
        if {($old_status == "-" || $status == "-") && $old_status != $status} {
            set need_refresh 1
        }
    }
    if {$need_refresh} {
        rebuildCassetteMenuChoices
        refreshCrystalList 1
    }

    set m_portStatusList $portStatusList_

    if {$m_mode == "robot" && $m_cassetteListIndex > 0 && $m_cassetteListIndex <=3} {
        set cassette_index [expr 97 * ($m_cassetteListIndex - 1)]
        set cassette_status [lindex $m_portStatusList $cassette_index]
        if {$m_currentCassetteStatus != $cassette_status} {
            set m_currentCassetteStatus $cassette_status
            set m_indexMap [generateIndexMap $m_cassetteListIndex $m_PortIndex \
            m_crystalList $m_currentCassetteStatus]
            #puts "re-map index: $m_indexMap"
        }
        ###update crystal status
        setCurrentActionColor
    }
}
::itcl::body SequenceCrystals::handleModeChange {  stringName_ targetReady_ alias_ mode_ - } {
    if { ! $targetReady_} return

    #puts "mode changed to: $mode_"

    set m_mode $mode_
    setCurrentActionColor
}

# ===================================================

::itcl::body SequenceCrystals::handleCassetteSelect {} {

    trc_msg "SequenceCrystals::handleCassetteSelect"
    
    trc_msg "beamlineName=$beamlineName"

    #get the index of the value selected
    set cassetteDescription [$itk_component(cassette) get]

    #puts "CASSETTE LIST: $m_cassetteList"
    #puts "SELECTED CASSETTE $cassetteDescription"

    set cassetteListIndex \
    [lsearch $m_allCassetteMenuChoices $cassetteDescription]
    if {[lindex $m_cassettePermits $cassetteListIndex] != "1" || \
    [lindex $m_cassetteStatus $cassetteListIndex] == "-"} {
        log_error "not allowed to select $cassetteDescription"
        ##rollback the selection
        rebuildCassetteMenuChoices
        return
    }

    set m_user [$itk_option(-controlSystem) getUser]

    set cassetteInfo [list [list $m_user $cassetteListIndex $m_cassetteList]]
    sendCassetteInfoToServer $cassetteInfo

    return
}


#this is the handler for the string change
::itcl::body SequenceCrystals::handleCassetteChange {  stringName_ targetReady_ alias_ cassetteInfo_ - } {


    if { ! $targetReady_} return

    if {$cassetteInfo_ == ""} return
    #puts "CASSETTECHANGE: $cassetteInfo_"

    set m_user [lindex $cassetteInfo_ 0]
    set m_cassetteListIndex [lindex $cassetteInfo_ 1]
    set m_cassetteList [lindex $cassetteInfo_ 2]
    
    rebuildCassetteMenuChoices
    refreshCrystalList 1
}

# ===================================================

::itcl::body SequenceCrystals::handleLoadClick {} {
    set types {
        {{MS Excel} {.xls}}
        {{All Files} *}
    }
    set filename [tk_getOpenFile \
                  -title "Select Spreadsheet to upload" \
                  -filetypes $types \
                  -initialdir [file nativename ~] ]
    if {$filename == ""} {
        return
    }
    set SID [$itk_option(-controlSystem) getSessionId]
    set SID [getTicketFromSessionId $SID]
    set userName [$itk_option(-controlSystem) getUser]

    if {$userName == "jcsg"} {
        set sheetName beam_rpt
    } else {
        set sheetName Sheet1
    }

    $itk_component(load) configure -state disabled
    set failed [catch {loadSpreadSheet $userName $SID $m_cassetteListIndex $filename $sheetName} errorMsg]
    $itk_component(load) configure -state normal

    if {$failed} {
        log_error "upload file failed: $errorMsg"
        return
    }
}
::itcl::body SequenceCrystals::handleDownloadClick {} {
    set types {
        {{MS Excel} {.xls}}
        {{All Files} *}
    }
    set filename [tk_getSaveFile \
                  -title "Select file to save spreadsheet" \
                  -defaultextension ".xls" \
                  -filetypes $types \
                  -initialdir [file nativename ~] ]
    if {$filename == ""} {
        return
    }
    set SID [$itk_option(-controlSystem) getSessionId]
    set SID [getTicketFromSessionId $SID]
    set userName [$itk_option(-controlSystem) getUser]

    $itk_component(download) configure -state disabled
    set failed [catch {downloadSil $userName $SID $m_SILID $filename } errorMsg]
    $itk_component(download) configure -state normal

    if {$failed} {
        log_error "download file failed: $errorMsg"
        return
    }
}
::itcl::body SequenceCrystals::handleWebClick {} {
    set SID [$itk_option(-controlSystem) getSessionId]
    set userName [$itk_option(-controlSystem) getUser]
    set url [::config getCassetteInfoUrl]
    append url "?SMBSessionID=$SID&userName=$userName"
    if {[catch "openWebWithBrowser $url" result]} {
        log_error "start mozilla failed: $result"
    } else {
        $itk_component(web) configure -state disabled
        after 10000 [list $itk_component(web) configure -state normal]
    }
}
::itcl::body SequenceCrystals::handleWebIceClick {} {
    set user [$itk_option(-controlSystem) getUser]
    set SID [$itk_option(-controlSystem) getSessionId]
    set url [::config getViewScreeningStrategyUrl]
    append url "?SMBSessionID=$SID&userName=$user&beamline=$beamlineName"
    if {[catch "openWebWithBrowser $url" result]} {
        log_error "start mozilla failed: $result"
    } else {
        $itk_component(web) configure -state disabled
        after 10000 [list $itk_component(web) configure -state normal]
    }
}

body SequenceCrystals::handleEditClick {} {
    if {$m_indexEdit >= 0} {
        #puts "submit pressed"
        ########## should submit to server, for now copy contents back
        #copy over contents
        set f $itk_component(crystalList)

        set data_to_submit ""
        for {set i 0} {$i < $m_nColumn} {incr i} {
            set column [lindex $m_columnMap $i]
            set obj   [lindex $column 0]
            set type  [lindex $column 1]
            set name  [lindex $column 3]
            if {$type == "entry"} {
                set new_contents [$f.edit$i get]
                set old_contents [$f.${obj}_$m_indexEdit cget -text]
                set new_contents [string trim $new_contents]
                set old_contents [string trim $old_contents]
                if {$new_contents != $old_contents} {
                    lappend data_to_submit $name $new_contents
                }
            }
        }

        if {$data_to_submit != ""} {
            set SID [$itk_option(-controlSystem) getSessionId]
            set SID [getTicketFromSessionId $SID]
            set user [$itk_option(-controlSystem) getUser]
            set data_to_submit [eval http::formatQuery $data_to_submit]
            set uniqueID [lindex [lindex $m_crystalList $m_indexEdit] \
            $m_UniqueIDIndex]

            editSpreadsheet $user $SID $m_SILID $m_indexEdit $data_to_submit \
            $uniqueID
        }

        $itk_component(edit) config \
        -text Edit

        editOneRow -1
    } else {
        $itk_component(edit) config \
        -text Submit

        editOneRow $m_indexSelect
    }
}
body SequenceCrystals::handleDiscardClick {} {
    editOneRow -1
    $itk_component(edit) config \
    -text Edit
}
::itcl::body SequenceCrystals::handleUpdateClick {} {
    trc_msg "SequenceCrystals::handleUpdateClick"


    trc_msg "beamlineName=$beamlineName"

    #change username to current Blu-Ice login username
    set user [$itk_option(-controlSystem) getUser]
    if {$user == ""} {
        trc_msg "not login yet"
        return
    }

    if {![sendUpdateCassetteRequest $beamlineName $user]} {
        trc_msg "authorization from url failed"
        return
    }

    set m_user $user

    set m_cassetteList [loadCassetteListFromUrl $beamlineName $m_user]

    set cassetteInfo [list [list $m_user $m_cassetteListIndex $m_cassetteList]]
    
    #puts "sendCassetteInfoToServer $cassetteInfo"
    sendCassetteInfoToServer $cassetteInfo
}

# ===================================================
# ===================================================

::itcl::body SequenceCrystals::refreshCrystalList { {force_update 0}} {
    if {[lindex $m_cassettePermits $m_cassetteListIndex] == "1" && \
    [lindex $m_cassetteStatus $m_cassetteListIndex] != "-"} {
        pack forget $itk_component(noAccess)
        pack $itk_component(crystalList) -expand 1 -fill both
    } else {
        pack forget $itk_component(crystalList)
        pack $itk_component(noAccess)
    }

    set SID [$itk_option(-controlSystem) getSessionId]
    set SID [getTicketFromSessionId $SID]
    set user [$itk_option(-controlSystem) getUser]

    set data [string map {\n { }} [getSpreadsheetFromWeb $beamlineName $user $SID $m_cassetteListIndex $m_cassetteList]]

    redisplayWholeSpreadsheet $data
}
::itcl::body SequenceCrystals::redisplayWholeSpreadsheet { data } {
    $itk_component(scrolledFrame) xview moveto 0
    $itk_component(scrolledFrame) yview moveto 0
    set cassette_index [expr 97 * ($m_cassetteListIndex - 1)]
    set cassette_status [lindex $m_portStatusList $cassette_index]
    set m_currentCassetteStatus $cassette_status
    ####check first item to decide the data is from old service or new service
    set first [lindex $data 0]
    set ll_first [llength $first]
    if {$ll_first == 1} {
        ##### new service
        set m_SILID $first
        set m_SILEventID [lindex $data 1]
        set cmd [lindex $data 2]
        set header [lindex $data 3]
        set m_crystalList [lrange $data 4 end]
        $itk_component(edit) config -state normal
        $itk_component(download) config -state normal
        DynamicHelp::register $itk_component(edit) balloon ""
        DynamicHelp::register $itk_component(download) balloon ""
        puts "SIL ID: $m_SILID Event ID: $m_SILEventID"
        log_note BluIce reports: SIL $m_SILID $m_SILEventID
    } else {
        #### old service, using default header
        set m_SILID "old"
        set header $m_defaultHeader
        if {$ll_first <= 0} {
            set m_crystalList ""
            log_error Failed to display spreadsheet, please Refresh or reselect cassette.
            log_error Failed to display spreadsheet, please Refresh or reselect cassette.
            log_error Failed to display spreadsheet, please Refresh or reselect cassette.
            log_error Failed to display spreadsheet, please Refresh or reselect cassette.
        }
        set m_crystalList $data
        $itk_component(edit) config -state disabled
        $itk_component(download) config -state disabled
        DynamicHelp::register $itk_component(edit) balloon "edit not available old spreadsheet"
        DynamicHelp::register $itk_component(download) balloon "download not available old spreadsheet"

        set contents_to_send [lindex $m_crystalList 0]
        log_note BluIce reports: SIL $m_SILID $contents_to_send

    }

    set header_changed [parseHeader $header]
    if {$header_changed} {
        unMapAll
        applyWidth
        displayHeader
        setCellColor 1
    }

    set m_indexMap [generateIndexMap $m_cassetteListIndex $m_PortIndex \
    m_crystalList $m_currentCassetteStatus]
    #puts "map index: $m_indexMap"
    updateCrystalListView $m_crystalList
    setCurrentActionColor
    updateRegisteredComponents -crystalNameList
    updateRegisteredComponents -sampleInfo
}
body SequenceCrystals::updateRows { data } {
    foreach row_data $data {
        set row_index [lindex $row_data 0]
        set row_contents [lindex $row_data 1]

        if {$row_index < 0 || $row_index >= $m_numRowParsed} {
            puts "row index $row_index is out of range \[0,$m_numRowParsed) for update"
            continue
        }

        set old_contents [lindex $m_crystalList $row_index]
        set old_port [lindex $old_contents $m_PortIndex]
        set new_port [lindex $row_contents $m_PortIndex]
        if {$old_port != $new_port} {
            puts "row $row_index new port {$new_port} does not match old {$old_port}"
            continue
        }
        #puts "updating row: $row_index with $row_contents"
        set m_crystalList [lreplace $m_crystalList $row_index $row_index $row_contents]

        ## catch i
        if {[catch {
            parseOneRow $row_index $row_contents
        } errMsg]} {
            log_error parse row $row_index failed: $errMsg
        }
    }
    updateRegisteredComponents -sampleInfo
}
# ===================================================

::itcl::body SequenceCrystals::sendUpdateCassetteRequest { beamlineName user } {
    set SID [$itk_option(-controlSystem) getSessionId]
    set SID [getTicketFromSessionId $SID]
    trc_msg "SequenceCrystals::sendUpdateCassetteRequest $beamlineName $user"
    set url "$m_updateDataUrl?forBeamLine=${beamlineName}&forUser=${user}"
    append url "&accessID=$SID"
    trc_msg "$url"
    if { [catch {
        set token [http::geturl $url -timeout 8000]
        upvar #0 $token state
        set status $state(status)
        set replystatus $state(http)
        set replycode [lindex $replystatus 1]
    } err] } {
        puts "$err $url"
        set status "ERROR $err $url"
    }
    if { $status!="ok" } {
        # error
        set msg "ERROR SequenceCrystals::sendUpdateCassetteRequest http::geturl status=$status"
        trc_msg $msg
        return 0
    } elseif { $replycode!=200 } {
        # error -> use the default option list
        set msg "ERROR SequenceCrystals::sendUpdateCassetteRequest http::geturl replycode=$replycode"
        trc_msg $msg
        #puts "SequenceCrystals::sendUpdateCassetteRequest $replystatus"
        http::cleanup $token
        return 0
    } else {
        set totalsize $state(totalsize)
        set currentsize $state(currentsize)
        trc_msg "totalsize=$totalsize"
        trc_msg "currentsize=$currentsize"
        set response "No response from server"
        if { $currentsize>1} {
            set response $state(body)
        }
        trc_msg "SequenceCrystals::sendUpdateCassetteRequest $response"
        http::cleanup $token
        return 1
    }
}

# ===================================================

::itcl::body SequenceCrystals::loadCassetteListFromUrl { beamlineName user } {
    trc_msg "SequenceCrystals::loadCassetteListFromUrl $beamlineName $user"
    set cassetteList {undefined undefined undefined undefined}
    
    # load the cassette list from the web server
    set SID [$itk_option(-controlSystem) getSessionId]
    set SID [getTicketFromSessionId $SID]
    set url "$m_cassetteDataUrl"
    append url "?accessID=$SID"
    append url "&forBeamLine=$beamlineName"
    append url "&forUser=${user}"
    set webData [loadWebData $url]
    if { [llength $webData]<1 } {
        # try it a second time
        set webData [loadWebData $url]
    }
    set num_item [llength $webData]
    if {$num_item > 0 && $num_item < 5} {
        # we have got a tcl list
        set cassetteList $webData
    }
    
    #clean up the cassetteList
    
    foreach cassette $cassetteList {
        lappend cleanCassetteList [trim $cassette]
    }

    #puts "CASSETTELIST from URL $cleanCassetteList"

    return $cleanCassetteList
}

# ===================================================

::itcl::body SequenceCrystals::loadWebData { url } {

    trc_msg "SequenceCrystals::loadWebData"
    trc_msg "$url"
    set data ""
    if { [catch {
        set token [http::geturl $url -timeout 12000]
        upvar #0 $token state
        set status $state(status)
        set replystatus $state(http)
        set replycode [lindex $replystatus 1]
    } err] } {
        log_error "$err $url"
        set status "ERROR $err $url"
    }

    if { $status!="ok" } {
        # error -> use the default crystal list
        set msg "ERROR SequenceCrystals::loadWebData http::geturl status=$status"
        trc_msg "$msg"
    } elseif { $replycode!=200 } {
        # error -> use the default option list
        set msg "ERROR SequenceCrystals::loadWebData http::geturl replycode=$replycode"
        trc_msg $msg
        #puts "SequenceCrystals::loadWebData $replystatus"
        http::cleanup $token
    } else {
        set totalsize $state(totalsize)
        set currentsize $state(currentsize)
        trc_msg "totalsize=$totalsize"
        trc_msg "currentsize=$currentsize"
        if { $currentsize>10} {
            set dd $state(body)
            if { [string range $dd 0 3]=="<Err" || [string first "\{" [string range $dd 0 5] ]<0 } {
                set msg "ERROR SequenceCrystals::loadWebData - Web server returned: $dd"
                trc_msg $msg
            } else {
                set d [lindex $dd 0]
                set data $d
            }
        }
        http::cleanup $token
    }
    
    return $data
}

# ===================================================

body SequenceCrystals::openWeb { url } {
    
    if { [string length $url]<8 } {
        # this can not be a valid url
        return
    }
    if {[catch "openWebWithBrowser $url" result]} {
        log_error "start mozilla failed: $result"
    }
}


# ===================================================
# ===================================================

::itcl::body SequenceCrystals::sendCheckBoxStates {} {
    set crystalListStates {}
    trc_msg "sendCheckBoxStates m_numRowDisplayed=$m_numRowDisplayed"
    for {set i 0} {$i < $m_numRowDisplayed} {incr i} {
        set crystalListStates [concat $crystalListStates [getCheckbox $i]]
    }

    trc_msg "the list=$crystalListStates"
    sendCrystalListStatesToServer $crystalListStates
}




# ===================================================

::itcl::body SequenceCrystals::trc_msg { text } {
    puts "$text"
    #print "$text"
}

# ===================================================
# ===================================================

::itcl::body SequenceCrystals::sendCassetteInfoToServer { cassetteInfo_ } {
    #puts "sendCassetteInfoToServer $cassetteInfo_ --"
    if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
        return
    }

    #update spreadsheet before doing anything
    #if {[catch getSpreadsheetUpdate errmsg]} {
    #    log_error "getSpreadsheetUpdate failed"
    #}

    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
    set _operationId [eval $m_sequenceOperation startOperation setConfig cassetteInfo $cassetteInfo_ $SID]
}

::itcl::body SequenceCrystals::sendNextCrystalToServer { index_ } {
    if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
        return
    }

    #update spreadsheet before doing anything
    #if {[catch getSpreadsheetUpdate errmsg]} {
    #    log_error "getSpreadsheetUpdate failed"
    #}

    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
    set _operationId [eval $m_sequenceOperation startOperation  setConfig nextCrystal $index_ $SID]
}

::itcl::body SequenceCrystals::sendCrystalListStatesToServer { crystalListStates_ } {
    if {[$itk_option(-controlSystem) cget -clientState] != "active"} {
        return
    }

    #update spreadsheet before doing anything
    #if {[catch getSpreadsheetUpdate errmsg]} {
    #    log_error "getSpreadsheetUpdate failed"
    #}
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
    }

    set _operationId [eval $m_sequenceOperation startOperation setConfig crystalListStates [list $crystalListStates_] $SID]
}


::itcl::body SequenceCrystals::setCrystalListStates { value_ } {
    
    set nElements $MAX_ROW
    
    #truncate existing list of crystals
    if { $nElements> [llength $value_] } {
        set nElements [llength $value_]
    }
    
    for {set i 0} {$i < $nElements} {incr i} {
        setCheckbox $i [lindex $value_ $i]
    }
}

::itcl::body SequenceCrystals::setNextCrystal { index_ } {
    
    if { $m_indexNext!=$index_ } {
        if { $index_ < 0 } {
            set index_ -1
        }

        set m_indexNext $index_
        setCurrentActionColor
    }
}

::itcl::body SequenceCrystals::setCurrentCrystal { index_ } {
    if { $m_indexMounted != $index_ } {
        set m_indexMounted $index_
        setCurrentActionColor
    }
}

::itcl::body SequenceCrystals::getCrystalNameList { } {
    set nameList {}
    if {$m_IDIndex < 0} {
        return ""
    }

    foreach row $m_crystalList {
        set name [lindex $row $m_IDIndex]
        if {$name == "null" || $name == "NULL" || $name == "" || $name == "0"} {
            append name ([lindex $row $m_PortIndex])
        }
        lappend nameList $name
    }
    return $nameList
}
::itcl::body SequenceCrystals::getCrystalStatus { index } {
    set port_index [lindex $m_indexMap $index]

    if {$port_index == ""} {
        return -
    }
    if {![string is digit $port_index]} {
        return -
    }
    if {$index < 0} {
        return -
    }

    return [lindex $m_portStatusList $port_index]
}
body SequenceCrystals::editOneRow { row_no_ } {
    if {$m_indexEdit == $row_no_} return

    #puts "edit one row: $row_no_ prev: $m_indexEdit"

    set f $itk_component(crystalList)
    ####hide previous edit row if exists
    if {$m_indexEdit >= 0} {
        #set row_index [expr $m_indexEdit + 1]
        set row_index $m_indexEdit
        set edit_cells [place slaves $f]
        foreach cell $edit_cells {
            place forget $cell
        }
    }

    ###### map row with edit
    if {$row_no_ >= 0} {
        #set row_index [expr $row_no_ + 1]
        set row_index $row_no_
        #copy over contents
        set f $itk_component(crystalList)

        for {set i 0} {$i < $m_nColumn} {incr i} {
            set column [lindex $m_columnMap $i]
            set obj   [lindex $column 0]
            set type  [lindex $column 1]
            if {$type == "entry"} {
                set column_index [expr $i + 2]
                set contents [$f.${obj}_$row_no_ cget -text]
                $f.edit$i delete 0 end
                $f.edit$i insert 0 $contents
                foreach {x y w h} [grid bbox $f $column_index $row_index] break
                place $f.edit$i -x $x -y $y -width $w -height $h
            }
        }
    }

    set m_indexEdit $row_no_
}

# ===================================================
body SequenceCrystals::saveCurrentColumnConfig { } {
    #puts "save current column config"

    set initDir "~/.bluice/show_column"

    if [catch "file mkdir $initDir" err_msg] {
        log_error failed to create show column directory
        #puts "failed to create show column directory"
        return
    }

    set file_name [file join $initDir ".default.cln"]
    if {[catch {open $file_name w} handle]} {
        log_error failed to create the file $file_name
        #puts "failed to create the file $file_name"
        return
    }
    puts $handle "# uncomment ORIGINAL to display original all columns"
    puts $handle "#ORIGINAL"
    puts $handle "# uncomment MINI to display system defined minimum columns"
    puts $handle "#MINI"
    puts $handle "# uncomment RESULT to display system defined results columns"
    puts $handle "#RESULT"
    puts $handle "###########################################"
    puts $handle "#  current system displaying:"

    if {[isColumnConfigEqual $m_columnConfigResult $m_originalAllColumn]} {
        puts $handle ORIGINAL
        set m_columnConfigLabel "Full"
        $itk_component(stateHeader) config -text $m_columnConfigLabel
    } elseif {[isColumnConfigEqual $m_columnConfigResult $m_defaultMini]} {
        puts $handle MINI
        set m_columnConfigLabel "Simple"
        $itk_component(stateHeader) config -text $m_columnConfigLabel
    } elseif {[isColumnConfigEqual $m_columnConfigResult $m_defaultResult]} {
        puts $handle RESULT
        set m_columnConfigLabel "Results"
        $itk_component(stateHeader) config -text $m_columnConfigLabel
    } else {
        #puts "current: $m_columnConfigResult"
        #puts "all: $m_originalAllColumn"
        #puts "mini: $m_defaultMini"
        #puts "result: $m_defaultResult"
        puts $handle $m_columnConfigResult
        set m_columnConfigLabel "Customed"
        $itk_component(stateHeader) config -text $m_columnConfigLabel
    }
    close $handle
}
body SequenceCrystals::loadCurrentColumnConfig { } {
    puts "load current column config"
    set initDir "~/.bluice/show_column"

    if [catch "file mkdir $initDir" err_msg] {
        log_error failed to create show column directory
        puts "failed to create show column directory"
        return
    }

    set file_name [file join $initDir ".default.cln"]
    if {[catch {open $file_name r} handle]} {
        #puts "failed to open the file $file_name"
        return
    }

    ####read file
    set columnList ""
    while {[gets $handle buffer] >= 0} {
        ###safety check
        if {[regexp {[;[$\]\\]} $buffer]} {
            puts "bad file, quit"
            close $handle
            return
        }
        set buffer [string trim $buffer]
        if {[string index $buffer 0] == "#"} {
            continue
        }
        if {[string equal -nocase -length 8 $buffer ORIGINAL]} {
            set columnList ORIGINAL
            break
        } elseif {[string equal -nocase -length 4 $buffer MINI]} {
            set columnList MINI
            break
        } elseif {[string equal -nocase -length 6 $buffer RESULT]} {
            set columnList RESULT
            break
        } elseif {$buffer != ""} {
            #user define
            set columnList $buffer
            break
        }
    }
    close $handle
    if {$columnList == ""} {
        set columnList ORIGINAL
    }
    puts "load initial column list: $columnList"
    if {$columnList == "" || $columnList == "ORIGINAL"} {
        $m_showColumnData initialize ""
        set m_columnConfigLabel "Full"
    } elseif {$columnList == "MINI"} {
        $m_showColumnData initialize $m_defaultMini
        set m_columnConfigLabel "Simple"
        set m_showColumnInited 1
    } elseif {$columnList == "RESULT"} {
        $m_showColumnData initialize $m_defaultResult
        set m_columnConfigLabel "Results"
        set m_showColumnInited 1
    } else {
        $m_showColumnData initialize $columnList
        set m_columnConfigLabel "Customed"
    }
}
body SequenceCrystals::handleColumnEditDone { } {
    pack forget $itk_component(edit_column)
    pack $itk_component(scrolledFrame) -side left -expand 1 -fill both
}
body SequenceCrystals::handleColumnEditApply { args } {
    $m_showColumnData initialize "$args"
}
body SequenceCrystals::handleRowUpdateEvent { stringName_ targetReady_ alias_ contents_ - } {
    #puts "handleRowUpdateEvent"

    ####do some check
    if {!$targetReady_} return

    if {![string is integer -strict $m_SILID] || $m_SILID < 0} {
        #puts "spreadsheet not loaded yet, skip update"
        return
    }

    #puts "contents: $contents_"

    if {[llength $contents_] < 2} {
        #puts "length of contents{$contents_} < 2"
        return
    }
    foreach {sil_id sil_event_id} $contents_ break

    if {$sil_id != $m_SILID} {
        puts "{$sil_id} != $m_SILID from string"
        #log_error "bad sil_id {$sil_id} != $m_SILID from string"
        return
    }
    if {$sil_event_id == $m_SILEventID} {
        puts "no new event, skip"
        return
    }
    if {$sil_event_id < $m_SILEventID} {
        puts "sil_event_id {$sil_event_id} <= $m_SILEventID from string is not new"
        #log_error "sil_event_id {$sil_event_id} <= $m_SILEventID from string is not new"
        return
    }

    getSpreadsheetUpdate
}
body SequenceCrystals::getSpreadsheetUpdate { } {
    ### get changes from the web
    set userName [$itk_option(-controlSystem) getUser]
    set SID [$itk_option(-controlSystem) getSessionId]
    set SID [getTicketFromSessionId $SID]
    set eventID [expr $m_SILEventID + 1]
    set data [getSpreadsheetChangesSince $userName $SID $m_SILID $eventID]
    #puts "row update data: $data"
    ###check###
    set silID [lindex $data 0]
    set eventID [lindex $data 1]
    set cmd [lindex $data 2]
    if {$silID == $m_SILID && $eventID == $m_SILEventID} {
        #puts "no changes"
        return
    }
    if {$silID != $m_SILID} {
        #puts "SILID changed from $m_SILID to $silID"
        if {$cmd != "load"} {
            puts "SILID changed but cmd != load"
            return
        }
    }
    if {$cmd == "load"} {
        ##SILID and EventID will get update inside
        redisplayWholeSpreadsheet $data
        return
    }
    ###update rows
    set rowData [lrange $data 3 end]
    updateRows $rowData
    set m_SILID $silID
    set m_SILEventID $eventID
    log_note BluIce reports: SIL $m_SILID $m_SILEventID
}
body SequenceCrystals::refreshHeaderInfo { } {
    #puts "refresh header info"
    for {set i -2} {$i < $m_nColumn} {incr i} {
        handleHeaderMap $i
    }
}
body SequenceCrystals::getGeometry { window } {
    set x [winfo rootx $window]
    set y [winfo rooty $window]
    set w [winfo width $window]
    set h [winfo height $window]

    return "$x $y $w $h"
}
body SequenceCrystals::isColumnConfigEqual { config1 config2 }  {
    set l1 [llength $config1]
    set l2 [llength $config2]
    if {$l1 != $l2} {
        #puts "length not the same"
        return 0
    }
    foreach column1 $config1 column2 $config2 {
        foreach {name1 width1} $column1 {name2 width2} $column2 break
        if {$name1 != $name2} {
            #puts "$name1 != $name2"
            return 0
        }
        if {$width1 != $width2} {
            #puts "$name1 width: $width1 !- $width2"
            return 0
        }
    }
    return 1
}
body SequenceCrystals::handleCassettePermitsChange { - ready_ - contents_ - } {
    if {!$ready_} return

    set m_cassettePermits $contents_

    rebuildCassetteMenuChoices
    
    refreshCrystalList 1
}
# ===================================================
#// main

#set top .ex
#SequenceCrystals crystals $top



# ===================================================


proc testSequenceCrystals {} {
    SequenceCrystals .test
    pack .test
}
