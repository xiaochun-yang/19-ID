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
# ===================================================

package provide BLUICEScoreView 1.0

package require Itcl
package require Iwidgets
#namespace import ::itcl::*

package require DCSComponent


### will upgrade to a scrollable, header configurable spreadsheet.

class DCS::ScoreViewForQueue {
    inherit ::itk::Widget ::DCS::Component

    itk_option define -positionFromRun positionFromRun PositionFromRun -1

    itk_option define -positionLabels positionLabels PositionLabels "" {
        setPositionLabels $itk_option(-positionLabels)
    }

    private common MAX_ROW 10
    protected variable m_numRowParsed  0
    protected variable m_numRowDisplayed  0
    private variable m_preSelect -1
    private variable m_indexRed -1
    private variable m_indexUsed -1
    private variable m_indexSelect 0
    
    private variable m_dataMap ""

    private variable m_header [list \
    Name \
    Score \
    Mosaicity \
    Rmsr \
    Resolution \
    ]

    private variable m_scoreIndex [list \
    0 \
    1 \
    3 \
    4 \
    6 \
    ]
    private variable m_widthList [list 10 6 6 6 6]
    private variable m_rowCellList ""
    private variable m_numColumn 5

    private variable m_headerSite
    private variable m_bodySite

    public method setPositionLabels { data }
    public method getCurrentRow { } {
        return [lindex $m_dataMap $m_indexSelect]
    }

    # contructor / destructor
    constructor {args} {
        ::DCS::Component::constructor {currentRow getCurrentRow }
    } {
        frame $itk_interior.headerF
        set m_headerSite $itk_interior.headerF
        frame $itk_interior.bodyF
        set m_bodySite $itk_interior.bodyF

        ### header
        set i 0
        foreach h $m_header w $m_widthList {
            label $m_headerSite.header$i \
            -text $h \
            -width $w \
            -anchor w \
            -relief groove \
            -background #c0c0ff \
            -borderwidth 1

            incr i
        }
        displayHeader

        #body
        set numLabels $m_numColumn
        puts "create labels for scores row=$MAX_ROW col=$numLabels"
        for {set row 0} {$row < $MAX_ROW} {incr row} {
            for {set col 0} {$col < $numLabels} {incr col} {
                label $m_bodySite.cell${row}_${col} \
                -width [lindex $m_widthList $col] \
                -anchor w \
                -relief groove \
                -borderwidth 1

                bind $m_bodySite.cell${row}_${col} \
                <Button-1> "$this handleCellClick $row $i"
            }
        }
        pack $itk_interior.headerF -side top -expand 1 -fill x
        pack $itk_interior.bodyF -side top -expand 1 -fill both


        eval itk_initialize $args
        announceExist

        set m_indexSelect 0
        setCellColor 1
    }


    private method unMapAll { }
    private method displayHeader { }
    private method applyWidth { }
    private method displayAllRow { }
    private method updateUsed { }

    private method setCellColor { all }
    private method rowConfig { row_no args }

    public method handleCellClick { index col} {}

    # public methods

    private method updateView
    private method parseOneRow { row_no contents }
}

# ===================================================

configbody DCS::ScoreViewForQueue::positionFromRun {
    set i [lindex $itk_option(-positionFromRun) 0]

    puts "got positionFromRun=$i"
    if {$i < 0 || $i >= $m_numRowParsed} {
        set m_indexUsed -1
    } else {
        set m_indexUsed [lsearch -exact $m_dataMap $i]
    }
    puts "result m_indexUsed=$m_indexUsed"

    if {$m_indexUsed < 0} {
        set m_indexSelect 0
    } else {
        set m_indexSelect $m_indexUsed
    }
    updateUsed
    setCellColor 1

    
}
body DCS::ScoreViewForQueue::setPositionLabels { data } {
    if {[llength $data] < 3} return

    foreach {nameList stateList scoreList} $data break

    puts "position labeles: $nameList"
    puts "position states:  $stateList"
    puts "position scores:  $scoreList"

    set ll1 [llength $nameList]
    set ll2 [llength $stateList]
    set ll3 [llength $scoreList]
    if {$ll1 != $ll2 || $ll1 != $ll3} {
        puts "ERROR: scoreList bad"
        return
    }

    ## generate data
    set m_dataMap ""
    set data ""
    set i 0
    foreach name $nameList state $stateList score $scoreList {
        if {$state} {
            set oneRow $name
            eval lappend oneRow $score
            lappend data $oneRow
            lappend m_dataMap $i
        }
        incr i
    }
    updateView $data
}

body DCS::ScoreViewForQueue::unMapAll { } {
    set allList [grid slaves $m_bodySite]
    if {[llength $allList] > 0} {
        eval grid forget $allList
    }
    set m_numRowDisplayed 0
}
body DCS::ScoreViewForQueue::displayHeader { } {
    set m_rowCellList ""
    for {set i 0} {$i < $m_numColumn} {incr i} {
        grid $m_headerSite.header$i -row 0 -column $i -sticky news
        lappend m_rowCellList $m_bodySite.cellROW_$i
    }
}
body DCS::ScoreViewForQueue::applyWidth { } {
    for {set col 0} {$col < $m_numColumn} {incr col} {
        $m_headerSite.header$col configure \
        -width [lindex $m_widthList $col]
    }

    for {set row 0} {$row < $MAX_ROW} {incr row} {
        for {set col 0} {$col < $m_numColumn} {incr col} {
            $m_bodySite.cell${row}_${col} configure \
            -width [lindex $m_widthList $col]
        }
    }
}
body DCS::ScoreViewForQueue::parseOneRow { row_no contents } {
    #puts "parseOneRow $row_no"

    set n_data [llength $contents]
    for {set i 0} {$i < $m_numColumn} {incr i} {
        set index [lindex $m_scoreIndex $i]
        if {$index < 0} {
            continue
        }
        set obj $m_bodySite.cell${row_no}_${i}
        
        set new_contents [lindex $contents $index]
        set new_contents [string trim $new_contents]
        set new_contents [string map {\n { }} $new_contents]

        if {[catch {
            if {[string first " " $new_contents] < 0 \
            && [string is double -strict $new_contents] \
            && ![string is integer $new_contents]} {
                set new_contents [format "%.3f" $new_contents]
            }
            $obj configure \
            -text $new_contents
        } errMsg]} {
            puts "ERROR in parseOneRow for $row_no: $errMsg"
        }
    }
}
body DCS::ScoreViewForQueue::displayAllRow { } {
    #puts "displayAllRow: parsed: $m_numRowParsed displayed: $m_numRowDisplayed"
    if {$m_numRowParsed == $m_numRowDisplayed} {
        return
    }

    if {$m_numRowParsed > $m_numRowDisplayed} {
        for {set row $m_numRowDisplayed} {$row < $m_numRowParsed} {incr row} {
            regsub -all ROW $m_rowCellList $row oneRow
            eval grid $oneRow -sticky news -row $row
        }
    } else {
        for {set row $m_numRowParsed} {$row < $m_numRowDisplayed} {incr row} {
            regsub -all ROW $m_rowCellList $row oneRow
            eval grid forget $oneRow
        }
    }

    set m_numRowDisplayed $m_numRowParsed
}

body DCS::ScoreViewForQueue::updateUsed { } {
    if {$m_indexRed >= 0} {
        rowConfig  $m_indexRed -foreground black
        set m_indexRed -1
    }
    if {$m_indexUsed >= 0} {
        set red #c04080
        rowConfig $m_indexUsed -foreground $red
        set m_indexRed $m_indexUsed
    }
}

::itcl::body DCS::ScoreViewForQueue::updateView { data } {
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
    updateUsed
    setCellColor 1
}

# ===================================================

body DCS::ScoreViewForQueue::rowConfig { row_no args } {
    for {set i 0} {$i < $m_numColumn} {incr i} {
        eval $m_bodySite.cell${row_no}_$i config $args
    }
}
::itcl::body DCS::ScoreViewForQueue::setCellColor { all } {
    # show selected row with darkblue background

    set blue #a0a0c0

    set nElements $MAX_ROW 
    
    set gray [$m_bodySite cget -background]

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

    set nCol [llength $m_widthList]

    for {set row 0} {$row < $nElements} {incr row} {
        if {$row % 2} {
            set bb #e0e0e0
        } else {
            set bb $gray
        }
        rowConfig $row -background $bb
    }
    rowConfig $m_indexSelect -background $blue
    set m_preSelect $m_indexSelect
}

::itcl::body DCS::ScoreViewForQueue::handleCellClick { index col} {

    puts "handleCellClick=$index $col"
    
    set m_indexSelect $index
    
    setCellColor 0
    updateRegisteredComponents currentRow
}
