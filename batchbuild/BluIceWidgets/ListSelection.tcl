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
##########################################################################
#
#                       Permission Notice
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
# BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
##########################################################################
package provide ListSelection 1.0

# load standard packages
package require Iwidgets
package require DCSComponent
package require BLUICESimpleRobot
package require DCSUtil

class QueueListDataHolder {
    inherit ::DCS::Component

    ###only items beyond startIndex can be selected or changed
    public variable startIndex 0 {
        fixSelectList
        updateRegisteredComponents -any
    }

    ####this will decide whether update
    public variable stringName "" {
        if {$m_lastStringName != ""} {
            $m_lastStringName unregister $this contents handleStringUpdate
        }
        set m_lastStringName $stringName
        if {$m_lastStringName != ""} {
            $m_lastStringName register $this contents handleStringUpdate
        }
    }
    
    protected common MAX_NUM_ITEM 100

    protected variable m_resultList ""
    protected variable m_selectList ""
    protected variable m_numItem 0
    protected variable m_lastStringName ""

    public proc getMaxItem { } {
        return $MAX_NUM_ITEM
    }
    public method getResult { } {
        return $m_resultList
    }
    public method getSelection { } {
        return $m_selectList
    }
    public method getUpdate { } {
        return [list $m_resultList $m_selectList]
    }

    public method handleStringUpdate { name_ targetReady_ alias_ contents_ - }

    public method initialize { args }
    public method insert { index args }
    public method setSelection { map }
    public method selectOnlyOne { index }
    #selection operation
    public method moveUp { {num_step 1} }
    public method moveDown { {num_step 1} }
    public method remove { }
    public method moveTo { index }
    ###insert before selection
    public method insertHere { item }

    public method curselection { }

    public method getAnySelection { } {
        if {[curselection] == ""} {
            return 0
        } else {
            return 1
        }
    }


    private method fixSelectList { } {
        ####fix length first
        set ll [llength $m_selectList]
        if {$ll > $m_numItem} {
            set m_selectList [lreplace $m_selectList $m_numItem end]
        } elseif {$ll < $m_numItem} {
            set numExtra [expr $m_numItem - $ll]
            for {set i 0} {$i < $numExtra} {incr i} {
                lappend m_selectList 0
            }
        }
        ####fix contents
        set end $startIndex
        if {$m_numItem < $startIndex} {
            set end $m_numItem
        }
        for {set i 0} {$i < $end} {incr i} {
            set m_selectList [lreplace $m_selectList $i $i 0]
        }
    }

    #numChange means insert, remove.
    #moving up and down will not trigger
    constructor { args } {
        ::DCS::Component::constructor {
            -selection getSelection
            -result    getResult
            -any       getUpdate
            -count     getResult
            -anySelection getAnySelection
        }
    } {
        announceExist
    }
    destructor {
        if {$m_lastStringName != ""} {
            $m_lastStringName register $this contents handleStringUpdate
        }
    }
}
body QueueListDataHolder::handleStringUpdate { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    eval initialize $contents_
}
body QueueListDataHolder::initialize { args } {
    set m_resultList $args
    set m_numItem [llength $m_resultList]
    fixSelectList

    updateRegisteredComponents -result
    updateRegisteredComponents -selection
    updateRegisteredComponents -anySelection
    updateRegisteredComponents -any
    updateRegisteredComponents -count
}
body QueueListDataHolder::curselection { } {
    set result ""
    for {set i 0} {$i <$m_numItem} {incr i} {
        if {[lindex $m_selectList $i] == "1"} {
            lappend result $i
        }
    }
    return $result
}
body QueueListDataHolder::setSelection { selectList_ } {
    set ll [llength $selectList_]
    set m_selectList $selectList_
    if {$ll != 0 && $ll != $m_numItem} {
        puts "bad selectList, length{$ll} not match $m_numItem"
    }
    fixSelectList
    updateRegisteredComponents -selection
    updateRegisteredComponents -anySelection
    updateRegisteredComponents -any
}
body QueueListDataHolder::selectOnlyOne { index } {
    if {$m_numItem == 0} return

    ##clear all selection
    set m_selectList ""
    for {set i 0} {$i < $m_numItem} {incr i} {
        lappend m_selectList 0
    }
    if {$index >= $startIndex && $index < $m_numItem} {
        set m_selectList [lreplace $m_selectList $index $index 1]
    }
    updateRegisteredComponents -selection
    updateRegisteredComponents -anySelection
    updateRegisteredComponents -any
}
body QueueListDataHolder::moveUp { {num_step 1} } {
    ###copy all selected in to buffer
    set indexList [curselection]

    if {[llength $indexList] <= 0} {
        return
    }

    if {$num_step < 1} {
        puts "bad num step {$num_step} for move up"
        return
    }

    set first [lindex $indexList 0]
    set insert_index [expr $first - $num_step]
    if {$insert_index < $startIndex} {
        set insert_index $startIndex
    }

    set buffer_result ""
    set buffer_sel ""
    foreach index $indexList {
        lappend buffer_result [lindex $m_resultList $index]
        lappend buffer_sel 1
    }

    ##remove all of them from the list
    set removeList [lsort -integer -decreasing $indexList]
    set newResultList $m_resultList
    foreach index $removeList {
        set newResultList [lreplace $newResultList $index $index]
        set m_selectList [lreplace $m_selectList $index $index]
    }

    #insert the buffer back into list
    set newResultList [eval linsert [list $newResultList] $insert_index $buffer_result]
    set m_selectList [eval linsert [list $m_selectList] $insert_index $buffer_sel]

    if {$m_lastStringName == ""} {
        set m_resultList $newResultList
        updateRegisteredComponents -result
        updateRegisteredComponents -selection
        updateRegisteredComponents -anySelection
        updateRegisteredComponents -any
    } else {
        $m_lastStringName sendContentsToServer $newResultList
    }
}
body QueueListDataHolder::moveDown { {num_step 1} } {
    ###copy all selected in to buffer
    set indexList [curselection]

    if {[llength $indexList] <= 0} {
        return
    }

    if {$num_step < 1} {
        puts "bad num step {$num_step} for move down"
        return
    }

    set last [lindex $indexList end]
    set insert_index [expr $last + $num_step + 1]
    if {$insert_index >= $m_numItem} {
        set insert_index end
    }

    set buffer_result ""
    set buffer_sel ""
    foreach index $indexList {
        lappend buffer_result [lindex $m_resultList $index]
        lappend buffer_sel 1
    }

    #insert the buffer back into list before remove original items
    set newResultList $m_resultList
    set newResultList [eval linsert [list $newResultList] $insert_index $buffer_result]
    set m_selectList [eval linsert [list $m_selectList] $insert_index $buffer_sel]

    ##remove all of them from the list
    set removeList [lsort -integer -decreasing $indexList]
    foreach index $removeList {
        set newResultList [lreplace $newResultList $index $index]
        set m_selectList [lreplace $m_selectList $index $index]
    }

    if {$m_lastStringName == ""} {
        set m_resultList $newResultList
        updateRegisteredComponents -result
        updateRegisteredComponents -selection
        updateRegisteredComponents -anySelection
        updateRegisteredComponents -any
    } else {
        $m_lastStringName sendContentsToServer $newResultList
    }
}
body QueueListDataHolder::remove { } {
    set indexList [curselection]

    if {[llength $indexList] <= 0} {
        return
    }

    ##remove all of them from the list
    set removeList [lsort -integer -decreasing $indexList]
    set newResultList $m_resultList
    foreach index $removeList {
        set newResultList [lreplace $newResultList $index $index]
        set m_selectList [lreplace $m_selectList $index $index]
    }
    if {$m_lastStringName == ""} {
        set m_resultList $newResultList
        set m_numItem [llength $m_resultList]
        updateRegisteredComponents -result
        updateRegisteredComponents -count
        updateRegisteredComponents -selection
        updateRegisteredComponents -anySelection
        updateRegisteredComponents -any
    } else {
        $m_lastStringName sendContentsToServer $newResultList
    }
}
body QueueListDataHolder::insert { index args } {
    puts "insert $index $args"
    set numNew [llength $args]
    if {$numNew <= 0} {
        return
    }
    if {$m_numItem + $numNew > $MAX_NUM_ITEM} {
        log_error "reached maximum items: $MAX_NUM_ITEM"
        return
    }

    if {[string is integer -strict $index]} {
        if {$index < $startIndex} {
            set index $startIndex
        } elseif {$index > $m_numItem} {
            set index $m_numItem
        }
    }

    ###adjust
    for {set i 0} {$i < $numNew} {incr i} {
        lappend allZero 0
    }
    set newResultList [eval linsert [list $m_resultList] $index $args]
    set m_selectList [eval linsert [list $m_selectList] $index $allZero]

    if {$m_lastStringName == ""} {
        set m_resultList $newResultList
        set m_numItem [llength $m_resultList]
        updateRegisteredComponents -result
        updateRegisteredComponents -selection
        updateRegisteredComponents -anySelection
        updateRegisteredComponents -any
        updateRegisteredComponents -count
    } else {
        $m_lastStringName sendContentsToServer $newResultList
        puts "old contents: $m_resultList"
        puts "new contents: $newResultList"
    }
}
body QueueListDataHolder::insertHere { column } {
    set indexList [curselection]

    if {[llength $indexList] != 1} {
        return
    }
    set index [lindex $indexList 0]

    insert $index $column
}

###
class MoveCrystalData {
    inherit QueueListDataHolder

    #### search in order:
    ####     first selected row
    ####     first empty place
    ####     appended to the end
    public method addOrigin { port }
    public method addDestination { port }

    public method setOrigin { index port }
    public method setDestination { index port }

    private method firstEmptyOrigin { }
    private method firstEmptyDestination { }
}
body MoveCrystalData::firstEmptyOrigin { } {
    for {set i $startIndex} {$i < $m_numItem} {incr i} {
        set item [lindex $m_resultList $i]
        set orig ""
        set dest ""
        if {[parseRobotMoveItem $item orig dest] && $orig == ""} {
            return $i
        }
    }
    return -1
}
body MoveCrystalData::firstEmptyDestination { } {
    puts "first empty dest"
    for {set i $startIndex} {$i < $m_numItem} {incr i} {
        set item [lindex $m_resultList $i]
        puts "$i $item"
        set orig ""
        set dest ""
        if {[parseRobotMoveItem $item orig dest] && $dest == ""} {
            return $i
        }
        puts "{$orig} {$dest}"
    }
    return -1
}
body MoveCrystalData::addOrigin { port_ } {
    set nextOrigIndex [lindex [curselection] 0]
    if {![string is integer -strict $nextOrigIndex] || \
    $nextOrigIndex < $startIndex} {
        set nextOrigIndex [firstEmptyOrigin]
    }
    if {$nextOrigIndex >= $startIndex} {
        setOrigin $nextOrigIndex $port_
    } else {
        insert end "${port_}->"
    }
    setSelection ""
}
body MoveCrystalData::addDestination { port_ } {
    set nextDestIndex [lindex [curselection] 0]
    if {![string is integer -strict $nextDestIndex] || \
    $nextDestIndex < $startIndex} {
        set nextDestIndex [firstEmptyDestination]
    }
    if {$nextDestIndex >= $startIndex} {
        setDestination $nextDestIndex $port_
    } else {
        insert end "->${port_}"
    }
    setSelection ""
}
body MoveCrystalData::setOrigin { index_ port_ } {
    if {$index_ < 0 || $index_ >= $m_numItem} {
        log_error index $index_ out of range
        return
    }
    set item [lindex $m_resultList $index_]
    set orig ""
    set dest ""
    if {[parseRobotMoveItem $item orig dest]} {
        set newItem ${port_}->${dest}
    } else {
        set newItem ${port_}->
    }
    if {$m_lastStringName == ""} {
        set m_resultList [lreplace $m_resultList $index_ $index_ $newItem]
        updateRegisteredComponents -result
        updateRegisteredComponents -any
    } else {
        set newResultList [lreplace $m_resultList $index_ $index_ $newItem]
        $m_lastStringName sendContentsToServer $newResultList
        puts "old contents: $m_resultList"
        puts "new contents: $newResultList"
    }
}
body MoveCrystalData::setDestination { index_ port_ } {
    puts "setDest: $index_ $port_"
    if {$index_ < 0 || $index_ >= $m_numItem} {
        log_error index $index_ out of range
        return
    }
    set item [lindex $m_resultList $index_]
    set orig ""
    set dest ""
    if {[parseRobotMoveItem $item orig dest]} {
        set newItem ${orig}->$port_
    } else {
        set newItem ->$port_
    }
    if {$m_lastStringName == ""} {
        set m_resultList [lreplace $m_resultList $index_ $index_ $newItem]
        updateRegisteredComponents -result
        updateRegisteredComponents -any
    } else {
        set newResultList [lreplace $m_resultList $index_ $index_ $newItem]
        $m_lastStringName sendContentsToServer $newResultList
    }
}

#items in ColumnHeaderData are "name width"
class ColumnHeaderData {
    inherit QueueListDataHolder

    #clear can be done by passing an empty list
    public method initialize { columnList }

    public method width { index new_width }
    #shrink and expand only work when there is only one selected
    #shrink will shrink 1/4 of current width with minimum 1 character 
    #if current width is 1, the column will be removed
    public method shrink { }
    #expand will expand 1/4 of current width with minimum 1 character
    public method expand { }

}
body ColumnHeaderData::initialize { columnList_ } {
    set ll [llength $columnList_]
    for {set i 0} {$i < $ll} {incr i} {
        set column [lindex $columnList_ $i]
        set name [lindex $column 0]
        set width [lindex $column 1]
        if {![string is integer -strict $width] || $width <= 0} {
            log_warning column $name bad width "$width" changed to 10
            if {[llength $column] > 1} {
                set column [lreplace $column 1 1 10]
            } else {
                set column [list $name 10]
            }
            set columnList_ [lreplace $columnList_ $i $i $column]
        }
    }

    set m_resultList $columnList_
    set m_numItem [llength $m_resultList]
    ##clear all selection
    set m_selectList ""
    for {set i 0} {$i < $m_numItem} {incr i} {
        lappend m_selectList 0
    }

    ##result will include selection
    updateRegisteredComponents -selection
    updateRegisteredComponents -anySelection
    updateRegisteredComponents -result
    updateRegisteredComponents -count
    updateRegisteredComponents -any
}
body ColumnHeaderData::shrink { } {
    set indexList [curselection]

    if {[llength $indexList] != 1} {
        return
    }
    set index [lindex $indexList 0]
    set column [lindex $m_resultList $index]
    set width [lindex $column 1]
    if {$width < 2} {
        remove
        return
    }
    if {$width < 4} {
        set newWidth [expr $width - 1]
    } else {
        set newWidth [expr $width * 3 / 4]
    }
    set newColumn [lreplace $column 1 1 $newWidth]

    set m_resultList [lreplace $m_resultList $index $index $newColumn]
    updateRegisteredComponents -result
    updateRegisteredComponents -any
}
body ColumnHeaderData::expand { } {
    set indexList [curselection]

    if {[llength $indexList] != 1} {
        return
    }
    set index [lindex $indexList 0]
    set column [lindex $m_resultList $index]
    set width [lindex $column 1]
    if {$width < 4} {
        set newWidth [expr $width + 1]
    } elseif {$width < 8} {
        set newWidth [expr $width + 2]
    } else {
        set newWidth [expr $width * 5 / 4]
    }
    set newColumn [lreplace $column 1 1 $newWidth]

    set m_resultList [lreplace $m_resultList $index $index $newColumn]
    updateRegisteredComponents -result
    updateRegisteredComponents -any
}
body ColumnHeaderData::width { index newWidth } {
    #puts "width: $index $newWidth"
    if {$index < 0 || $index >= $m_numItem} return

    set column [lindex $m_resultList $index]
    if {$newWidth < 1} {
        remove
        return
    }
    set newColumn [lreplace $column 1 1 $newWidth]
    #puts "newColumn: $newColumn"

    set m_resultList [lreplace $m_resultList $index $index $newColumn]
    updateRegisteredComponents -result
    updateRegisteredComponents -any
}

class ColumnHeaderWidget {
    inherit ::itk::Widget

    itk_option define -dataHolder dataHolder DataHolder "" {
        if {$m_lastDataHolder != ""} {
            $m_lastCrystalListWidget unregister $this -any handleAnyChangeEvent
        }
        if {$itk_option(-dataHolder) != ""} {
            $itk_option(-dataHolder) register $this -any handleAnyChangeEvent
        }
        set m_lastDataHolder $itk_option(-dataHolder)
    }

    itk_option define -selectforeground selectforeground Selectforeground white
    itk_option define -selectbackground selectbackground Selectbackground blue

    private variable m_lastDataHolder ""

    private variable m_normalForeground black
    private variable m_normalBackground gray

    private variable MAX_COLUMN 100
    private variable INIT_COLUMN 20
    protected variable m_numColumnCreated 0
    protected variable m_numColumnisplayed 0
    protected variable m_demoSite
    protected variable m_numColumn 0

    private method redisplay { result select }

    private method createColumn { i } {
        itk_component add column$i {
            label $m_demoSite.demo$i \
            -relief groove \
            -anchor w \
            -font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"
        } {
        }
    }

    public method handleAnyChangeEvent { name_ targetReady_ alias_ contents_ - }

    constructor { args } {
        itk_component add ring {
            ::iwidgets::labeledframe $itk_interior.ring \
            -labeltext "Preview"
        } {
        }
        set wrapSite [$itk_component(ring) childsite]

        itk_component add sFrame {
            ::iwidgets::scrolledframe $wrapSite.sf \
            -height 50 \
            -vscrollmode none \
            -hscrollmode static
        } {
        }
        set m_demoSite [$itk_component(sFrame) childsite]
        for {set i 0} {$i < $INIT_COLUMN} {incr i} {
            createColumn $i
        };#for i
        set m_normalForeground [$itk_component(column0) cget -foreground]
        set m_normalBackground [$itk_component(column0) cget -background]
        set m_numColumnCreated $i
        
        itk_component add stateHeader {
            label $m_demoSite.stateHeader \
            -text "            " \
            -width 12 \
            -font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"
        } {
        }
        itk_component add checkHeader {
            checkbutton $m_demoSite.checkHeader \
            -selectcolor blue
        } {
        }

        grid $itk_component(stateHeader) $itk_component(checkHeader)
        pack $itk_component(sFrame) -side top -fill x
        pack $itk_component(ring) -side top -fill x
        eval itk_initialize $args
        redisplay "" ""
    }
}
body ColumnHeaderWidget::handleAnyChangeEvent { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    set resultList [lindex $contents_ 0]
    set selectList [lindex $contents_ 1]
    set m_numColumn [llength $resultList]

    if {$m_numColumn > $MAX_COLUMN} {
        log_warning reached maximum columns, only first $MAX_COLUMN columns accepted
        set m_numColumn $MAX_COLUMN
    }

    ###create labels if needed
    for {} {$m_numColumnCreated < $m_numColumn} {incr m_numColumnCreated} {
        createColumn $m_numColumnCreated
    }
    redisplay $resultList $selectList
}
body ColumnHeaderWidget::redisplay { resultList_  selectList_ } {
    ##clear first
    set all [grid slaves $m_demoSite]
    if {$all != ""} {
        eval grid forget $all
    }

    set all [list $itk_component(stateHeader) $itk_component(checkHeader)]

    ##display new ones if any
    for {set i 0} {$i < $m_numColumn} {incr i} {
        set column [lindex $resultList_ $i]
        set name [lindex $column 0]
        set width [lindex $column 1]

        set selected [lindex $selectList_ $i]

        if {$selected} {
            set fg $itk_option(-selectforeground)
            set bg $itk_option(-selectbackground)
        } else {
            set fg $m_normalForeground
            set bg $m_normalBackground
        }

        $itk_component(column$i) config \
        -foreground $fg \
        -background $bg \
        -text $name \
        -width $width

        lappend all $itk_component(column$i)
    }
    eval grid $all -sticky news
}

class ColumnWidthWidget {
    inherit ::itk::Widget

    itk_option define -dataHolder dataHolder DataHolder "" {
        if {$m_lastDataHolder != ""} {
            $m_lastCrystalListWidget unregister $this -any handleAnyChangeEvent
        }
        if {$itk_option(-dataHolder) != ""} {
            $itk_option(-dataHolder) register $this -any handleAnyChangeEvent
        }
        set m_lastDataHolder $itk_option(-dataHolder)
    }

    itk_option define -selectforeground selectforeground Selectforeground white
    itk_option define -selectbackground selectbackground Selectbackground blue

    #to be called if anything changed (move up, down, insert, remove, width)
    itk_option define -command command Command ""

    private method clicked { index }
    public method handleClick { index }
    public method handleFocusIn { index }
    public method handleAnyChangeEvent { name_ targetReady_ alias_ contents_ - }

    public method handleWidth { i newWidth oldWidth }

    private method redisplay { }
    private method createLine { i } {
        itk_component add name$i {
            label $m_lineSite.name$i
        } {
        }
        itk_component add width$i {
            entry $m_lineSite.width$i \
            -width 2 \
            -validate key \
            -vcmd "$this handleWidth $i %P %s"
        } {
        }
    }

    private variable m_lastDataHolder ""

    private variable MAX_COLUMN 100
    private variable INIT_COLUMN 20
    protected variable m_numLineCreated 0
    protected variable m_numLineDisplayed 0

    private variable m_normalForeground black
    private variable m_normalBackground gray

    private variable m_resultList ""
    private variable m_selectList ""

    protected variable m_lineSite

    private variable m_skipFocusIn 0

    private common gCheckButtonVar

    constructor { args } {
        itk_component add multi {
            checkbutton $itk_interior.multi \
            -text "Multiple Selection" \
            -anchor w \
            -variable [list [scope gCheckButtonVar($this,multi)]]
        } {
        }
        set gCheckButtonVar($this,multi) 0

        itk_component add outline {
            ::iwidgets::scrolledframe $itk_interior.outline \
            -hscrollmode none \
            -vscrollmode static
        } {
        }

        set m_lineSite [$itk_component(outline) childsite]

        for {set i 0} {$i < $INIT_COLUMN} {incr i} {
            createLine $i
        };#for i
        set m_normalForeground [$itk_component(name0) cget -foreground]
        set m_normalBackground [$itk_component(name0) cget -background]
        set m_numLineCreated $INIT_COLUMN
        puts "columnWidth: $m_numLineCreated lines created"

        eval itk_initialize $args
        pack $itk_component(multi) -side top -fill x
        pack $itk_component(outline) -fill both -expand 1 -side top
    }
}
body ColumnWidthWidget::redisplay { } {
    set all [grid slaves $m_lineSite]
    if {$all != ""} {
        eval grid forget $all
    }

    ####create more lines if needed
    set needed [llength $m_resultList]
    for {set i $m_numLineCreated} {$i < $needed} {incr i} {
        createLine $i
    }
    if {$i != $m_numLineCreated} {
        set m_numLineCreated $i
        puts "column width: $m_numLineCreated lines created"
    }

    set i 0
    foreach column $m_resultList selected $m_selectList {
        set name [lindex $column 0]
        set width [lindex $column 1]
        if {$selected} {
            set fg $itk_option(-selectforeground)
            set bg $itk_option(-selectbackground)
        } else {
            set fg $m_normalForeground
            set bg $m_normalBackground
        }

        $itk_component(name$i) config \
        -text $name \
        -foreground $fg \
        -background $bg

        $itk_component(width$i) config -vcmd {}
        $itk_component(width$i) delete 0 end
        $itk_component(width$i) insert 0 $width
        $itk_component(width$i) config -vcmd "$this handleWidth $i %P %s"

        grid $itk_component(name$i) $itk_component(width$i) -sticky w
        bind $itk_component(name$i) <Button-1> "$this handleClick $i"
        bind $itk_component(width$i) <FocusIn> "$this handleFocusIn $i"
        incr i
    }
    set m_numLineDisplayed $i
    #puts "selected displayed: $m_numLineDisplayed"
}

body ColumnWidthWidget::handleAnyChangeEvent { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    #puts "width: handle any change: $contents_"

    foreach {result select} $contents_ break

    ###save
    set m_resultList $result
    set m_selectList $select

    #puts "calling replay"
    redisplay
}
body ColumnWidthWidget::handleWidth { i_ newWidth_ oldWidth_ } {
    #puts "handle width $i_ $newWidth_ old: $oldWidth_"

    if {$oldWidth_ == $newWidth_} {
        return 1
    }
    if {$newWidth_ == ""} {
        return 1
    }

    if {![string is integer -strict $newWidth_] || $newWidth_ <= 0} {
        log_warning width must be a positive integer
        return 0
    }
    if {$itk_option(-dataHolder) != ""} {
        $itk_option(-dataHolder) width $i_ $newWidth_
    }
    return 1
}
body ColumnWidthWidget::handleFocusIn { index } {
    #puts "handleFocusIn $index"

    if {$m_skipFocusIn} {
        set m_skipFocusIn 0
        return
    }

    clicked $index
    #puts "end of focus in"
}
body ColumnWidthWidget::handleClick { index } {
    #puts "handleClick $index"

    set m_skipFocusIn 1
    focus $itk_component(width$index)

    clicked $index
}

body ColumnWidthWidget::clicked { index } {
    if {!$gCheckButtonVar($this,multi)} {
        set m_selectList ""
        for {set i 0} {$i < $m_numLineDisplayed} {incr i} {
            lappend m_selectList 0
        }
        set m_selectList [lreplace $m_selectList $index $index 1]
    } else {
        ###multiple selection enabled
        set old [lindex $m_selectList $index]
        if {$old} {
            set new 0
        } else {
            set new 1
        }
        set m_selectList [lreplace $m_selectList $index $index $new]
    }
    if {$itk_option(-dataHolder) != ""} {
        $itk_option(-dataHolder) setSelection $m_selectList
    }
}
class ListSelectWidget {
    inherit ::itk::Widget

    #the column names must be unique
    itk_option define -input input Input "{column1 10} {column2 20} {column3 30} {column4 40} {colulmn5 50}"

    itk_option define -preload preload PreLoad "{co2 3}"
    itk_option define -submitCommand submitCommand SubmitCommand "" {
        if {$itk_option(-submitCommand) == ""} {
            $itk_component(file_submit) config -state disabled
        } else {
            $itk_component(file_submit) config -state normal
        }
    }
    itk_option define -doneCommand doneCommand DoneCommand "" {
        if {$itk_option(-doneCommand) == ""} {
            pack forget $itk_component(file_done)
        } else {
            pack $itk_component(file_done) -side left
        }
    }
    itk_option define -presetList presetList PresetList "{mini {{column1 10} {column3 30}}}"

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    private variable m_oneInstanceBackground gray
    private variable m_oneInstanceForeground #808080

    private variable m_moreThanOneInstanceBackground red
    private variable m_moreThanOneInstanceForeground white

    protected variable m_numInput 0

    #this will hold the name only from the -input
    protected variable m_nameList ""

    #hold how many instances for each column
    #we support more than one instances per column
    protected variable m_numInstanceList ""

    protected variable m_origSite ""
    protected variable m_numLineCreated 0
    protected variable m_numLineDisplayed 0
    protected variable INIT_NUM_LINE 20
    protected variable MAX_NUM_LINE 100

    private variable m_normalForeground black
    private variable m_normalBackground gray

    private variable m_dataHolder

    protected variable MAX_PRESET 4
    protected variable m_numPresetDisplayed 0

    private common gCheckButtonVar

    public method handleSelectAll { }
    public method handlePreset { args }

    private method addColumn { column }
    public method handleAddColumnByIndex { i }
    public method handleRemoveAll { {no_display 0} }
    public method handleMove { direction }
    public method handleRemove { }

    public method handleLoad { }
    public method handleSave { }
    public method handleSubmit { }
    public method handleDone { }

    public method handleCountChangeEvent { name_ targetReady_ alias_ contents_ - }

    public method redisplay { }

    private method recount { resultList }

    constructor { args } {
        set m_dataHolder [ColumnHeaderData ::\#auto]
        $m_dataHolder register $this -count handleCountChangeEvent

        itk_component add fileFrame {
            frame $itk_interior.file
        } {
            keep -background
        }
        set fileSite $itk_component(fileFrame)

        itk_component add upperFrame {
            frame $itk_interior.upper
        } {
            keep -background
        }

        itk_component add lowerFrame {
            frame $itk_interior.lower
        } {
            keep -background
        }
        set demoSite $itk_component(lowerFrame)

        itk_component add file_load {
            button $fileSite.load \
            -text "Load From File" \
            -command "$this handleLoad"
        } {
        }

        itk_component add file_save {
            button $fileSite.save \
            -text "Save To File" \
            -command "$this handleSave"
        } {
        }

        itk_component add file_submit {
            button $fileSite.submit \
            -background #00a040 \
            -text "Apply to Screening" \
            -command "$this handleSubmit"
        } {
        }

        itk_component add file_done {
            button $fileSite.done \
            -background green \
            -text "Done" \
            -command "$this handleDone"
        } {
        }
        pack $itk_component(file_load) -side left
        pack $itk_component(file_save) -side left
        pack $itk_component(file_submit) -side left

        itk_component add originalFrame {
            ::iwidgets::labeledframe $itk_component(upperFrame).origF \
            -labeltext "Input Columns"
        } {
        }
        set originalSite [$itk_component(originalFrame) childsite]

        itk_component add presetFrame {
            frame $originalSite.preset
        } {
        }
        set presetSite $itk_component(presetFrame)

        itk_component add showAll {
            button $presetSite.all \
            -width 10 \
            -text "Full" \
            -command "$this handleSelectAll"
        } {
        }
        pack $itk_component(showAll) -side top -expand 0


        ###user defined preset
        for {set i 0} {$i < $MAX_PRESET} {incr i} {
            itk_component add user_preset$i {
                button $presetSite.preset$i \
                -width 10
            } {
            }
        }

        itk_component add orig_leftF {
            frame $originalSite.left
        } {
        }

        itk_component add multi {
            checkbutton $itk_component(orig_leftF).multi \
            -anchor w \
            -text "Multiple Instance" \
            -variable [list [scope gCheckButtonVar($this,multi)]] \
            -command "$this redisplay"
        } {
        }
        set gCheckButtonVar($this,multi) 0

        itk_component add orig_listFrame {
            ::iwidgets::scrolledframe $itk_component(orig_leftF).list\
            -hscrollmode none \
            -vscrollmode static
        } {
        }
        set m_origSite [$itk_component(orig_listFrame) childsite]

        for {set m_numLineCreated 0} {$m_numLineCreated < $INIT_NUM_LINE} {incr m_numLineCreated} {
            itk_component add line$m_numLineCreated {
                button $m_origSite.line$m_numLineCreated \
                -relief flat \
                -activebackground blue \
                -activeforeground white \
                -anchor w \
                -command "$this handleAddColumnByIndex $m_numLineCreated"
            } {
            }
        }
        set m_normalForeground [$itk_component(line0) cget -foreground]
        set m_normalBackground [$itk_component(orig_listFrame) cget -background]

        pack $itk_component(multi) -side top -fill x
        pack $itk_component(orig_listFrame) -side top -expand 1 -fill both

        pack $itk_component(presetFrame) -side left -expand 0 -fill y
        pack $itk_component(orig_leftF) -side left -expand 1 -fill both
        
        itk_component add selectedFrame {
            ::iwidgets::labeledframe $itk_component(upperFrame).selF \
            -labeltext "Display Columns"
        } {
        }
        set selectedSite [$itk_component(selectedFrame) childsite]

        itk_component add commandFrame {
            frame $selectedSite.commandF
        } {
        }
        set commandSite $itk_component(commandFrame)

        itk_component add remove_all {
            button $commandSite.ra \
            -width 10 \
            -text "Remove All" \
            -command "$this handleRemoveAll"
        } {
        }

        itk_component add move_up {
            button $commandSite.up \
            -width 10 \
            -text "Move Up" \
            -command "$this handleMove Up"
        } {
        }

        itk_component add move_down {
            button $commandSite.down \
            -width 10 \
            -text "Move Down" \
            -command "$this handleMove Down"
        } {
        }

        itk_component add remove {
            button $commandSite.remove \
            -width 10 \
            -text "Remove" \
            -command "$this handleRemove"
        } {
        }

        pack $itk_component(remove_all) -side top
        pack $itk_component(move_up) -side top
        pack $itk_component(move_down) -side top
        pack $itk_component(remove) -side top

        itk_component add selected {
            ColumnWidthWidget $selectedSite.list \
            -dataHolder $m_dataHolder
        } {
        }

        pack $itk_component(selected) -side left -expand 1 -fill both
        pack $itk_component(commandFrame) -side left -fill y

        pack $itk_component(originalFrame) -side left -expand 1 -fill both
        pack $itk_component(selectedFrame) -side left -expand 1 -fill both

        ########lower frame for demo
        itk_component add demo {
            ColumnHeaderWidget $demoSite.header \
            -dataHolder $m_dataHolder
        } {
        }
        pack $itk_component(demo) -side top -fill x

        pack $itk_component(fileFrame) -side top -fill x -pady 5 -padx 5
        pack $itk_component(upperFrame) -side top -expand 1 -fill both -padx 5
        pack $itk_component(lowerFrame) -side top -fill x -padx 5 -pady 5

        eval itk_initialize $args
    }

    destructor {
        $m_dataHolder unregister $this -count handleCountChangeEvent
    }
}

configbody ListSelectWidget::input {
    set m_numInput [llength $itk_option(-input)]
    if {$m_numInput > $MAX_NUM_LINE} {
        log_warning reached maximum lines, only first $MAX_NUM_LINE columns accepted
        set m_numInput $MAX_NUM_LINE
    }

    ###create labels if needed
    for {} {$m_numLineCreated < $m_numInput} {incr m_numLineCreated} {
        itk_component add line$m_numLineCreated {
            button $m_origSite.line$m_numLineCreated \
            -relief flat \
            -activebackground blue \
            -activeforeground white \
            -anchor w \
            -command "$this handleAddColumnByIndex $m_numLineCreated"
        } {
        }
    }

    #re-populate the new input
    set m_nameList ""
    set m_numInstanceList ""
    for {set i 0} {$i < $m_numInput} {incr i} {
        set item [lindex $itk_option(-input) $i]
        set name [lindex $item 0]
        lappend m_nameList $name
        lappend m_numInstanceList 0
    }

    set unique_num [llength [lsort -unique $m_nameList]]
    if {$unique_num != $m_numInput} {
        log_error "input column name list not unique"

        set m_numInput 0
        set m_nameList ""
        set m_numInstanceList ""
        #no display, so user cannot go on
    }
    #redisplay
    recount [$m_dataHolder getResult]
}

configbody ListSelectWidget::preload {
    $m_dataHolder initialize $itk_option(-preload)
}

configbody ListSelectWidget::presetList {
    #remove previous presets
    for {set i 0} {$i < $m_numPresetDisplayed} {incr i} {
        pack forget $itk_component(user_preset$i)
    }

    #puts "config presetList: $itk_option(-presetList)"

    set presetList [string map {\n { }} $itk_option(-presetList)]

    ##map new ones
    set m_numPresetDisplayed 0
    foreach preset $presetList {
        if {$m_numPresetDisplayed >= $MAX_PRESET} {
            log_warning maximum preset $MAX_PRESET, others discarded
            break
        }
        set name [lindex $preset 0]
        set columnList [lindex $preset 1]
        $itk_component(user_preset$m_numPresetDisplayed) configure \
        -text $name \
        -command "$this handlePreset $columnList"

        pack $itk_component(user_preset$m_numPresetDisplayed)

        incr m_numPresetDisplayed
        #puts "preset {$name}: list: {$columnList}"
    }
}
body ListSelectWidget::handleCountChangeEvent { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    recount $contents_
}
body ListSelectWidget::redisplay { } {
    if {$m_origSite == ""} return

    set all [grid slaves $m_origSite]
    if {$all != ""} {
        eval grid forget $all
    }

    for {set i 0} {$i < $m_numInput} {incr i} {
        set name [lindex $m_nameList $i]
        set num  [lindex $m_numInstanceList $i]
        if {$num <= 0} {
            set fg $m_normalForeground
            set bg $m_normalBackground
            set st normal
        } elseif {$num == 1} {
            set fg $m_oneInstanceForeground
            #set bg $m_oneInstanceBackground
            set bg $m_normalBackground
            set st [expr $gCheckButtonVar($this,multi) ? {"normal"} : {"disabled"}]
        } else {
            set fg $m_moreThanOneInstanceForeground
            set bg $m_moreThanOneInstanceBackground
            set st [expr $gCheckButtonVar($this,multi) ? {"normal"} : {"disabled"}]
        }

        $itk_component(line$i) config \
        -text $name \
        -foreground $fg \
        -background $bg \
        -state $st

        grid $itk_component(line$i) -sticky news
    }
    set m_numLineDisplayed $i
    #puts "original displayed: $m_numLineDisplayed"
}
body ListSelectWidget::handleSelectAll { } {
    $m_dataHolder initialize $itk_option(-input)

    set m_numInstanceList ""
    for {set i 0} {$i < $m_numInput} {incr i} {
        lappend m_numInstanceList 1
    }
    redisplay
}
body ListSelectWidget::addColumn { column } {
    foreach {name width} $column break
    set i [lsearch -exact $m_nameList $name]
    if {$i >= 0} {
        set old_num [lindex $m_numInstanceList $i]
        incr old_num
        set m_numInstanceList [lreplace $m_numInstanceList $i $i $old_num]
        $m_dataHolder insert end "$column"
    }
    redisplay
}
body ListSelectWidget::handleAddColumnByIndex { i } {
    set old_num [lindex $m_numInstanceList $i]

    incr old_num
    set m_numInstanceList [lreplace $m_numInstanceList $i $i $old_num]

    $m_dataHolder insert end [lindex $itk_option(-input) $i]

    redisplay
}

body ListSelectWidget::handleRemoveAll { {no_display 0} } {
    $m_dataHolder initialize ""

    set m_numInstanceList ""
    for {set i 0} {$i < $m_numInput} {incr i} {
        lappend m_numInstanceList 0
    }
    if {!$no_display} {
        redisplay
    }
}
body ListSelectWidget::handleMove { direction } {
    switch -exact -- $direction {
        Up {
            $m_dataHolder moveUp
            return
        }
        Down { 
            $m_dataHolder moveDown
            return
        }
        default {
            return
        }
    }
}
body ListSelectWidget::handleRemove { } {
    $m_dataHolder remove
}
body ListSelectWidget::handlePreset { args } {
    ###clear all first
    handleRemoveAll

    foreach column $args {
        addColumn $column
    }
}
body ListSelectWidget::handleLoad { } {
    set initDir "~/.bluice/show_column"

    if [catch "file mkdir $initDir" err_msg] {
        log_error failed to create show column directory
        #puts "failed to create show column directory"
        return
    }

    set file_name [tk_getOpenFile -defaultextension ".cln" \
    -initialdir $initDir]

    if {$file_name == ""} return

    if {[catch {open $file_name r} handle]} {
        log_error failed to open $file_name
        #puts "failed to open $file_name"
        return
    }

    ####read file
    set columnList ""
    while {[gets $handle buffer] >= 0} {
        ###safety check
        if {[regexp {[;[$\]\\]} $buffer]} {
            log_error bad file quit
            #puts "bad file, quit"
            close $handle
            return
        }
        set buffer [string trim $buffer]
        if {[string index $buffer 0] == "#"} {
            continue
        }
        set column [split $buffer]
        set name [lindex $column 0]
        set width [lindex $column 1]
        if {![string is integer -strict $width] || $width <= 0} {
            log_warning bad width "{$width}" changed to 10 for $name
            #puts "bad width {$width} changed to 10 for $name"
            set width 10
        }
        lappend columnList "$name $width"
    }
    close $handle

    #puts "loaded: $columnList"
    if {$columnList != ""} {
        $m_dataHolder initialize $columnList
    }
}
body ListSelectWidget::handleSave { } {
    set initDir "~/.bluice/show_column"

    if [catch "file mkdir $initDir" err_msg] {
        log_error failed to create show column directory
        #puts "failed to create show column directory"
        return
    }

    set file_name [tk_getSaveFile -defaultextension ".cln" \
    -initialdir $initDir]

    if {$file_name == ""} return

    if {[catch {open $file_name w} handle]} {
        log_error failed to create the file $file_name
        #puts "failed to create the file $file_name"
        return
    }
    puts $handle "# original columns when this file was created"
    foreach column $itk_option(-input) {
        set name [lindex $column 0]
        set width [lindex $column 1]
        puts $handle "# $name $width"
    }
    puts $handle "# show columns:"
    foreach column [$m_dataHolder getResult] {
        puts  $handle $column
    }
    close $handle
}
body ListSelectWidget::handleSubmit { } {
    set cmd $itk_option(-submitCommand)
    if {$cmd == ""} return

    eval $cmd [$m_dataHolder getResult]
}
body ListSelectWidget::handleDone { } {
    set cmd $itk_option(-doneCommand)
    if {$cmd == ""} return
    eval $cmd
}
body ListSelectWidget::recount { resultList_ } {
    set countList ""
    for {set i 0} {$i < $m_numInput} {incr i} {
        lappend countList 0
    }
    foreach column $resultList_ {
        set name [lindex $column 0]
        set index [lsearch -exact $m_nameList $name]
        if {$index >= 0} {
            set count [lindex $countList $index]
            incr count
            set countList [lreplace $countList $index $index $count]
        }
    }
    if {$m_numInstanceList == $countList} {
        #puts "should skip this count update"
    }
    set m_numInstanceList $countList
    redisplay
}
class MoveCrystalListView {
    inherit ::itk::Widget

    itk_option define -dataHolder dataHolder DataHolder "" {
        if {$m_lastDataHolder != ""} {
            $m_lastDataHolder unregister $this -any handleRefresh
        }
        set m_lastDataHolder $itk_option(-dataHolder)
        if {$itk_option(-dataHolder) != ""} {
            $itk_option(-dataHolder) register $this -any handleRefresh
        }
    }

    itk_option define -running running Running 0 { redisplay }

    itk_option define -selectforeground selectforeground Selectforeground white
    itk_option define -selectbackground selectbackground Selectbackground blue

    private method clicked { index }
    public method handleClick { index }
    public method handleRefresh { name_ targetReady_ alias_ contents_ - }
    public method handleSelection { name_ targetReady_ alias_ contents_ - }
    public method handleUserChangeDest { name_ targetReady_ alias_ contents_ - }

    public method handleWidth { i newWidth oldWidth }

    private method redisplay { }
    private method createLine { i } {
        itk_component add orig$i {
            label $m_lineSite.orig$i
        } {
        }
        itk_component add symbol$i {
            label $m_lineSite.sym$i -text "->"
        } {
        }
        itk_component add dest$i {
            label $m_lineSite.dest$i
        } {
        }
    }

    private variable m_lastMoveString ""
    private variable m_lastDataHolder ""

    private variable MAX_PAIR 100
    private variable INIT_PAIR 20
    protected variable m_numLineCreated 0
    protected variable m_numLineDisplayed 0

    private variable m_normalForeground black
    private variable m_normalBackground gray

    private variable m_resultList ""
    private variable m_selectList ""
    private variable m_startIndex 0

    protected variable m_lineSite

    private common gCheckButtonVar

    constructor { args } {
        itk_component add multi {
            checkbutton $itk_interior.multi \
            -text "Multiple Selection" \
            -anchor w \
            -variable [list [scope gCheckButtonVar($this,multi)]]
        } {
        }
        set gCheckButtonVar($this,multi) 0

        itk_component add outline {
            ::iwidgets::scrolledframe $itk_interior.outline \
            -hscrollmode none \
            -vscrollmode static
        } {
        }

        set m_lineSite [$itk_component(outline) childsite]

        for {set i 0} {$i < $INIT_PAIR} {incr i} {
            createLine $i
        };#for i
        set m_normalForeground [$itk_component(orig0) cget -foreground]
        set m_normalBackground [$itk_component(orig0) cget -background]
        set m_numLineCreated $INIT_PAIR
        puts "$m_numLineCreated lines created"

        #pack $itk_component(multi) -side top -fill x
        pack $itk_component(outline) -fill both -expand 1 -side top

        eval itk_initialize $args
    }
    destructor {
        if {$m_lastDataHolder != ""} {
            $m_lastDataHolder unregister $this -any handleRefresh
        }
    }
}
body MoveCrystalListView::redisplay { } {
    set all [grid slaves $m_lineSite]
    if {$all != ""} {
        eval grid forget $all
    }

    ####create more lines if needed
    set needed [llength $m_resultList]
    for {set i $m_numLineCreated} {$i < $needed} {incr i} {
        createLine $i
    }
    if {$i != $m_numLineCreated} {
        set m_numLineCreated $i
        puts "$m_numLineCreated lines created"
    }

    set i 0
    foreach item $m_resultList {
        set orig ""
        set dest ""
        parseRobotMoveItem $item orig dest
        puts "parse $item got {$orig} {$dest}"

        set selected [lindex $m_selectList $i]
        if {$selected == ""} {
            set selected 0
        }

        if {$selected} {
            set fg $itk_option(-selectforeground)
            set bg $itk_option(-selectbackground)
        } else {
            if {$i == $m_startIndex && $itk_option(-running) == "1"} {
                set fg #c04080
                set bg $m_normalBackground
            } else {
                set fg $m_normalForeground
                set bg $m_normalBackground
            }
        }
        if {$i < $m_startIndex} {
            set state disabled
        } else {
            set state normal
        }

        $itk_component(orig$i) config \
        -state $state \
        -text $orig \
        -foreground $fg \
        -background $bg

        $itk_component(symbol$i) config \
        -state $state \
        -foreground $fg \
        -background $bg

        $itk_component(dest$i) config \
        -state $state \
        -text $dest \
        -foreground $fg \
        -background $bg

        grid $itk_component(orig$i) \
        $itk_component(symbol$i) $itk_component(dest$i) -sticky we
        bind $itk_component(orig$i) <Button-1> "$this handleClick $i"
        bind $itk_component(symbol$i) <Button-1> "$this handleClick $i"
        bind $itk_component(dest$i) <Button-1> "$this handleClick $i"
        incr i
    }
    set m_numLineDisplayed $i
    if {$i == 0} {
        $itk_component(outline) yview moveto 0
    }
}

body MoveCrystalListView::handleRefresh { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    foreach {result select} $contents_ break
    set m_resultList $result
    set m_selectList $select
    set m_startIndex [$m_lastDataHolder cget -startIndex]

    redisplay
}
body MoveCrystalListView::handleSelection { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    set m_selectList $contents_

    redisplay
}
body MoveCrystalListView::handleUserChangeDest { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return
    if {$m_lastDataHolder == ""} return

    ###find index from name_
    set index [string last dest $name_]
    if {$index >= 0 && $index < $m_numLineDisplayed} {
        #skip "dest"
        set start [expr $index + 4]
        set num [string range $name_ $start end]
        if {[string is integer -strict $num]} {
            $m_lastDataHolder setDestination $num $contents_
            puts "$num dest changed to $contents_"
        }
    }

}
body MoveCrystalListView::handleClick { index } {
    if {[::dcss cget -clientState] != "active"} return
    #puts "handleClick $index"
    clicked $index
}

body MoveCrystalListView::clicked { index } {
    if {!$gCheckButtonVar($this,multi)} {
        set old [lindex $m_selectList $index]
        set m_selectList ""
        for {set i 0} {$i < $m_numLineDisplayed} {incr i} {
            lappend m_selectList 0
        }
        if {$old == "0"} {
            set new 1
        } else {
            set new 0
        }
        set m_selectList [lreplace $m_selectList $index $index $new]
    } else {
        ###multiple selection enabled
        set old [lindex $m_selectList $index]
        if {$old} {
            set new 0
        } else {
            set new 1
        }
        set m_selectList [lreplace $m_selectList $index $index $new]
    }
    if {$itk_option(-dataHolder) != ""} {
        $itk_option(-dataHolder) setSelection $m_selectList
    }
}
class MoveCrystalSelectWidget {
    inherit ::itk::Widget

    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -controlSystem controlSystem ControlSystem ::dcss

    private variable m_dataHolder

    private variable m_strRobotMove
    private variable m_strRobotCassette
    private variable m_strRobotMoveStatus
    private variable m_opMoveCrystal
    private variable m_strCassetteOwner

    private variable m_running 0

    ##map between page index and cassette index
    private variable m_cassetteIndexList {1 2 3}
    private variable m_origCasNameList \
    {orig_left_cas orig_middle_cas orig_right_cas}
    private variable m_destCasNameList \
    {dest_left_cas dest_middle_cas dest_right_cas}

    private common CASSETTE_NAME_LIST [RobotBaseWidget::getCassetteLabelList]
    private common CASSETTE_OFFSET_LIST {-1 0 97 194}

    public method handleToggleData { } {
        $m_opMoveCrystal startOperation toggle_move_data
    }
    public method handleStart { } {
        set user [$itk_option(-controlSystem) getUser]
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
        $m_opMoveCrystal startOperation start $user $SID
    }
    public method handleRemoveAll { } {
        $m_opMoveCrystal startOperation remove_all
    }
    public method handleMove { direction }
    public method handleRemove { }

    public method checkPortStatus { index value origin } {
        set status_list [$m_strRobotCassette getContents]
        set port_status [lindex $status_list $index]
        switch -exact -- $port_status {
            - {
                log_error $value not exist
                return 0
            }
            j {
                log_error $value port jam
                return 0
            }
            b {
                log_error $value bad port
                return 0
            }
            m {
                log_error $value mounted
                return 0
            }
            u {
                ##OK any cases
            }
            1 {
                if {!$origin} {
                    log_error $value occupied
                    return 0
                }
            }
            0 {
                if {$origin} {
                    log_error $value empty
                    return 0
                }
            }
            default {
                log_error $value bad port
                return 0
            }
        }

        #### return here if do not want to check repeat
        #return 1

        set allMovingPorts [$m_strRobotMove getAllPorts]
        #puts "allports: $allMovingPorts"
        if {[lsearch $allMovingPorts $value] >= 0} {
            log_error $value already in moving list
            return 0
        }
        return 1
    }

    public method addOrigPort { index value } {
        if {![checkPortStatus $index $value 1]} {
            return
        }
        $m_dataHolder addOrigin $value
    }
    public method addDestPort { index value } {
        if {![checkPortStatus $index $value 0]} {
            return
        }
        $m_dataHolder addDestination $value
    }

    public method handleResultEvent
    public method handleStringRobotMoveStatusEvent

    ##this will do both permission and display owner name
    public method handleCassettePermitChange

    constructor { args } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_strRobotMove [$deviceFactory createRobotMoveListString robot_move]
        set m_strRobotCassette [$deviceFactory createString robot_cassette]
        set m_strRobotMoveStatus [$deviceFactory createString robotMoveStatus]
        $m_strRobotMoveStatus createAttributeFromField data 0
        set m_opMoveCrystal [$deviceFactory getObjectName moveCrystal]
        set m_dataHolder [MoveCrystalData ::\#auto]
        set m_strCassetteOwner [$deviceFactory createCassetteOwnerString \
        cassette_owner]

        itk_component add orig_frame {
            frame $itk_interior.origF
        } {
        }

        set origSite $itk_component(orig_frame)
        label $origSite.label \
        -text "Origin Container" \
        -background $BaseSampleHolderView::COLOR_MOVE_ORIGIN
        if {[$origSite.label cget -background] == "black"} {
            $origSite.label configure \
            -foreground white
        }

        itk_component add nb_orig {
            iwidgets::Tabnotebook $origSite.nb_orig \
            -tabbackground gray75 \
            -tabpos n \
            -padx 0 \
            -pady 1 \
            -margin 0

        } {
        }

        itk_component add dest_frame {
            frame $itk_interior.destF
        } {
        }

        set destSite $itk_component(dest_frame)
        label $destSite.label \
        -text "Destination Container" \
        -background $BaseSampleHolderView::COLOR_MOVE_DESTINATION

        itk_component add nb_dest {
            iwidgets::Tabnotebook $destSite.nb_dest \
            -tabbackground gray75 \
            -tabpos n \
            -padx 0 \
            -pady 1 \
            -margin 0

        } {
        }

        foreach i $m_cassetteIndexList \
        o $m_origCasNameList \
        d $m_destCasNameList {
            set label  [lindex $CASSETTE_NAME_LIST $i]
            set offset [lindex $CASSETTE_OFFSET_LIST $i]
            set oSite [$itk_component(nb_orig) add -label $label]
            set dSite [$itk_component(nb_dest) add -label $label]

            itk_component add $o {
                DCSCassetteView $oSite.cv \
                -purpose forMoveOrigin \
                -offset $offset \
                -onClick "$this addOrigPort"
            } {
            }
            itk_component add $d {
                DCSCassetteView $dSite.cv \
                -purpose forMoveDestination \
                -offset $offset\
                -onClick "$this addDestPort"
            } {
            }
            pack $itk_component($o) -expand 1 -fill both
            pack $itk_component($d) -expand 1 -fill both
        }

        pack $origSite.label -side top -fill x
        pack $itk_component(nb_orig) -side top -expand 1 -fill both

        pack $destSite.label -side top -fill x
        pack $itk_component(nb_dest) -side top -expand 1 -fill both

        itk_component add selectedFrame {
            ::iwidgets::labeledframe $itk_interior.selF \
            -labeltext "Sample Move List"
        } {
        }
        set selectedSite [$itk_component(selectedFrame) childsite]

        itk_component add commandFrame {
            frame $selectedSite.commandF
        } {
        }
        set commandSite $itk_component(commandFrame)

        itk_component add remove_all {
            DCS::Button $commandSite.ra \
            -width 12 \
            -text "Clear List" \
            -command "$this handleRemoveAll"
        } {
        }

        itk_component add move_up {
            DCS::Button $commandSite.up \
            -width 12 \
            -text "Move Up" \
            -command "$this handleMove Up"
        } {
        }

        itk_component add move_down {
            DCS::Button $commandSite.down \
            -width 12 \
            -text "Move Down" \
            -command "$this handleMove Down"
        } {
        }

        itk_component add remove {
            DCS::Button $commandSite.remove \
            -width 12 \
            -text "Remove" \
            -command "$this handleRemove"
        } {
        }

        $itk_component(remove) addInput \
        "$m_dataHolder -anySelection 1 {select first}"


        #pack $itk_component(move_up) -side top
        #pack $itk_component(move_down) -side top
        pack $itk_component(remove) -side top
        pack $itk_component(remove_all) -side top

        itk_component add selected {
            MoveCrystalListView $selectedSite.list \
            -dataHolder $m_dataHolder
        } {
        }

        pack $itk_component(selected) -side top -fill both -expand 1
        pack $itk_component(commandFrame) -side top

        itk_component add bottomFrame {
            frame $itk_interior.bottom
        } {
        }
        set bottomSite $itk_component(bottomFrame)

        itk_component add start {
            DCS::Button $bottomSite.start \
            -width 10 \
            -text "Start" \
            -command "$this handleStart"
        } {
        }
        $itk_component(start) addInput \
        "$m_opMoveCrystal status inactive {supporting device}"
        $itk_component(start) addInput \
        "$m_opMoveCrystal permission GRANTED {PERMISSION}"

        itk_component add move_data {
            DCS::Checkbutton $bottomSite.data \
            -text "Update Spreadsheets" \
            -reference "$m_strRobotMoveStatus data" \
            -shadowReference 1 \
            -command "$this handleToggleData"
        } {
        }

        itk_component add message {
            label $bottomSite.msg \
            -background #00a040 \
            -relief sunken \
            -width 120
        } {
        }
        pack $itk_component(start) -side left
        pack $itk_component(move_data) -side left
        pack $itk_component(message) -side left -expand 1 -fill x

        grid columnconfigure $itk_interior 0 -weight 10
        grid columnconfigure $itk_interior 1 -weight 0
        grid columnconfigure $itk_interior 2 -weight 10
        grid rowconfigure $itk_interior 0 -weight 10

        grid $itk_component(orig_frame) -row 0 -column 0 -sticky news
        grid $itk_component(selectedFrame) -row 0 -column 1 -sticky news
        grid $itk_component(dest_frame) -row 0 -column 2 -sticky news

        grid $itk_component(bottomFrame) -row 1 -column 0 -columnspan 3 -sticky news
        $m_dataHolder configure \
        -stringName ::device::robot_move

        eval itk_initialize $args


        $m_strRobotMoveStatus register $this contents handleStringRobotMoveStatusEvent
        $m_strCassetteOwner register $this permits \
        handleCassettePermitChange
    }
    destructor {
        $m_strCassetteOwner unregister $this permits \
        handleCassettePermitChange
        $m_strRobotMoveStatus unregister $this contents handleStringRobotMoveStatusEvent
    }
}
body MoveCrystalSelectWidget::handleMove { direction } {
    switch -exact -- $direction {
        Up {
            $m_dataHolder moveUp
            return
        }
        Down { 
            $m_dataHolder moveDown
            return
        }
        default {
            return
        }
    }
}
body MoveCrystalSelectWidget::handleRemove { } {
    $m_dataHolder remove
}
body MoveCrystalSelectWidget::handleResultEvent { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    $m_strRobotMove sendContentsToServer $contents_
}
body MoveCrystalSelectWidget::handleCassettePermitChange { - ready_ - contents_ - } {
    if {!$ready_} return

    set ownerNameList [$m_strCassetteOwner getContents]

    puts "moveCrystal: new cassette permits: $contents_"
    puts "moveCrystal: ownerNameList: $ownerNameList"

    if {[lrange $contents_ 1 end] == "0 0 0"} {
        ### no permission to see any cassette
        pack forget $itk_component(nb_orig)
        pack forget $itk_component(nb_dest)
        return
    } else {
        pack $itk_component(nb_orig) -side top -expand 1 -fill both
        pack $itk_component(nb_dest) -side top -expand 1 -fill both
    }
    set nb_index -1
    set first_nb_index -1
    foreach i $m_cassetteIndexList \
    o $m_origCasNameList \
    d $m_destCasNameList {
        incr nb_index
        set p [lindex $contents_ $i]
        set ownerName [lindex $ownerNameList $i]
        set label [lindex $CASSETTE_NAME_LIST $i]
        if {$ownerName != ""} {
            append label ($ownerName)
        }
        if {$p == "1"} {
            if {$first_nb_index < 0} {
                set first_nb_index $nb_index
            }
            pack $itk_component($o) -expand 1 -fill both
            pack $itk_component($d) -expand 1 -fill both
            set state normal
        } else {
            pack forget $itk_component($o)
            pack forget $itk_component($d)
            set state disabled
        }
        $itk_component(nb_orig) pageconfigure $nb_index \
        -state $state \
        -label $label
        $itk_component(nb_dest) pageconfigure $nb_index \
        -state $state \
        -label $label
    }

    ###check to see if need to switch page
    if {$first_nb_index < 0} {
        set first_nb_index 0
    }
    set origIndex [$itk_component(nb_orig) index select]
    set destIndex [$itk_component(nb_dest) index select]
    set currentOrigCasIndex [lindex $m_cassetteIndexList $origIndex]
    set currentDestCasIndex [lindex $m_cassetteIndexList $destIndex]

    if {[lindex $contents_ $currentOrigCasIndex] != "1"} {
        $itk_component(nb_orig) select $first_nb_index
    }
    if {[lindex $contents_ $currentDestCasIndex] != "1"} {
        $itk_component(nb_dest) select $first_nb_index
    }
}
body MoveCrystalSelectWidget::handleStringRobotMoveStatusEvent { name_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} return

    if {[llength $contents_] < 4} {
        return
    }

    ###deal with message and error indicators later
    foreach {move_data running startIndex msg} $contents_ break
    $itk_component(selected) configure -running $running

    if {[string is integer -strict $startIndex] && $startIndex >= 0} {
        $m_dataHolder configure -startIndex $startIndex
    }

    $itk_component(message) configure \
    -text $msg
}
