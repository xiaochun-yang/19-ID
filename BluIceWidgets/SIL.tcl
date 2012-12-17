package provide BLUICESIL 1.0
package require Itcl
package require Iwidgets

class SILImage {
    inherit itk::Widget

    itk_option define -width width Width 0 {}
    itk_option define -foreground foreground Foreground black
    itk_option define -clickCommand clickCommand ClickCommand ""
    itk_option define -contents contents Contents ""

    private variable m_expanded 0
    private variable m_rowNameList ""
    private variable m_numRow 0
    private variable m_resultReady1 0
    private variable m_resultReady2 0
    private variable m_resultReady3 0

    ##save dir so we can get full path when we need it.
    private variable m_dir1 ""
    private variable m_dir2 ""
    private variable m_dir3 ""

    #colors
    private variable m_LINKCOLOR #0000ff

    public method isExpanded { } {
        return $m_expanded
    }
    public method resultReady { } {
        return [expr $m_resultReady1 || $m_resultReady2 || $m_resultReady3]
    }

    public method expand { } {
        set m_expanded 1
        repaint
    }
    public method shrink { } {
        set m_expanded 0
        repaint
    }

    public method flip { } {
        if {$m_expanded} {
            shrink
        } elseif {[resultReady]} {
            expand
        } else {
        }
    }
    public method handleNameClick { col_ } {
        set name [$itk_component(name$col_) cget -text]
        if {$name == "" || [resultReady]} {
            handleClick
        } else {
            set column [expr $col_ + 1]
            set dir [set m_dir$column]
            set fullpath [file join $dir $name]
            viewImageFile $fullpath
        }
    }

    public method repaint { }
    public method handleClick { } {
        if {$itk_option(-clickCommand) == ""} {
            set m_expanded [expr !$m_expanded]
            repaint
        } else {
            eval $itk_option(-clickCommand)
        }
    }
    public method handleLinkClick { row_ col_ } {
        puts "link clicked row: $row_ $col_"
        set column [expr $col_ + 1]
        set dir [set m_dir$column]
        set name [$itk_component(row_value${row_}_$col_) cget -text]
        set ext [file extension $name]
        set fullpath [file join $dir $name]
        puts "full path: {$fullpath}"

        viewImageFile $fullpath
    }

    private method do_contents { num contents }
    private method do_jpgLink { num contents }
    private method do_imgLink { num contents }
    private method do_analysisResult { num contents }

    constructor { args} {
        lappend m_rowNameList \
        "diffraction image" \
        "video image" \
        "quality" \
        "spot shape" \
        "resolution estimate" \
        "number of ice rings" \
        "diffraction strength" \
        "DISTIL score"

        set m_numRow [llength $m_rowNameList]

        itk_component add shrinkFrame {
            frame $itk_interior.shrink -relief groove -borderwidth 1
        } {
            keep -background
        }
        set shrinkSite $itk_component(shrinkFrame)
        itk_component add expandFrame {
            frame $itk_interior.expand -relief groove -borderwidth 1
        } {
        }
        set expandSite $itk_component(expandFrame)

        for {set col 0} {$col < 3} {incr col} {
            itk_component add name$col {
                label $shrinkSite.name$col \
                -width 20 \
                -anchor w
            } {
                keep -font -relief -background -activeforeground
            }
            bind $itk_component(name$col) <Button-1> "$this handleNameClick $col"
        }
        grid $itk_component(name0) $itk_component(name1) $itk_component(name2)
        grid columnconfigure $shrinkSite 0 -pad 11
        grid columnconfigure $shrinkSite 1 -pad 11

        set row_no 1
        foreach rowName $m_rowNameList {
            itk_component add row_label$row_no {
                label $expandSite.rowl$row_no \
                -anchor e \
                -width 20 \
                -text $rowName
            } {
                keep -font -relief -background -foreground -activeforeground
            }
            bind $itk_component(row_label$row_no) <Button-1> "$this handleClick"

            for {set col 0} {$col < 3} {incr col} {
                itk_component add row_value${row_no}_$col {
                    label $expandSite.rowv$row_no$col \
                    -background #A0A0A0 \
                    -width 15 \
                    -anchor w
                } {
                }
                if {$row_no > 2} {
                    bind $itk_component(row_value${row_no}_$col) <Button-1> "$this handleClick"
                } else {
                    bind $itk_component(row_value${row_no}_$col) <Button-1> "$this handleLinkClick $row_no $col"
                    $itk_component(row_value${row_no}_$col) configure \
                    -foreground $m_LINKCOLOR
                }
            };#for col

            incr row_no
        }
        for {set i 1} {$i <= $m_numRow} {incr i} {
            grid $itk_component(row_label$i) -row $i -column 0 -sticky e
            grid $itk_component(row_value${i}_0) -row $i -column 1 -sticky news
            grid $itk_component(row_value${i}_1) -row $i -column 2 -sticky news
            grid $itk_component(row_value${i}_2) -row $i -column 3 -sticky news
        }
        grid $itk_component(shrinkFrame) -row 0 -column 0 -sticky news
        grid rowconfigure $itk_interior 0 -weight 1
        grid columnconfigure $itk_interior 0 -weight 1

        eval itk_initialize $args

        repaint
    }
}

body SILImage::repaint { } {

    if {!$m_expanded} {
        grid remove $itk_component(expandFrame)
        grid $itk_component(shrinkFrame) -row 0 -column 0 -sticky news
    } else {
        grid remove $itk_component(shrinkFrame)
        grid $itk_component(expandFrame) -row 0 -column 0 -sticky news
    }
    #update
    #puts "in repaint: [grid bbox $itk_interior]"
}
body SILImage::do_jpgLink { num contents } {
    set display_text $contents
    set col [expr $num - 1]

    $itk_component(row_value2_$col) configure \
    -text $display_text

    if {$display_text != "" &&
    [$itk_component(name$col) cget -text] == ""} {
        $itk_component(name$col) configure \
        -text $display_text
    }
}
body SILImage::do_imgLink { num contents } {
    set display_text $contents
    set col [expr $num - 1]

    $itk_component(row_value1_$col) configure \
    -text $display_text

    $itk_component(name$col) configure \
    -text $display_text
}
body SILImage::do_analysisResult { num contents } {
    set col [expr $num - 1]

    set num_row [expr $m_numRow - 2]

    set resultReady 0
    for {set i 0} {$i < $num_row} {incr i} {
        set value [lindex $contents $i]
        set index [expr $i + 3]
        $itk_component(row_value${index}_$col) configure \
        -text $value
        if {$value != ""} {
            set resultReady 1
        }
    }
    set m_resultReady$num $resultReady
    if {$resultReady} {
        $itk_component(name$col) configure \
        -foreground $m_LINKCOLOR

        #prevent foreground color change again
    } else {
        $itk_component(name$col) configure \
        -foreground $itk_option(-foreground)
    }
}
body SILImage::do_contents { num contents } {
    #we only display last image in each group
    set last [lindex $contents end]

    set dir [lindex $last 0]
    set name [lindex $last 1]
    set jpeg [lindex $last 2]

    set m_dir$num $dir

    do_imgLink $num $name
    do_jpgLink $num $jpeg
    do_analysisResult $num [lrange $last 6 end]
}
configbody SILImage::foreground {
    if {!$m_resultReady1} {
        $itk_component(name0) configure -foreground $itk_option(-foreground)
    }
    if {!$m_resultReady2} {
        $itk_component(name1) configure -foreground $itk_option(-foreground)
    }
    if {!$m_resultReady3} {
        $itk_component(name2) configure -foreground $itk_option(-foreground)
    }
}
configbody SILImage::contents {
    #puts "contents: {$itk_option(-contents)}"
    set contents1 [lindex $itk_option(-contents) 0]
    set contents2 [lindex $itk_option(-contents) 1]
    set contents3 [lindex $itk_option(-contents) 2]
    do_contents 1 $contents1
    do_contents 2 $contents2
    do_contents 3 $contents3
}

#this is to display results from auto index
class SILScore {
    inherit itk::Widget

    itk_option define -foreground foreground Foreground black
    itk_option define -clickCommand clickCommand ClickCommand ""
    itk_option define -analysisResult analysisResult AnalysisResult "" {
        for {set i 0} {$i < 5} {incr i} {
            set value [lindex $itk_option(-analysisResult) $i]
            $itk_component(row_value$i) configure \
            -text $value
        }
        set value [lindex $itk_option(-analysisResult) 0]
        if {[llength $itk_option(-analysisResult)] == 5} {
            $itk_component(score) configure \
            -text $value \
            -foreground $m_LINKCOLOR

            bind $itk_component(score) <Button-1> "$this handleClick"
            set m_resultReady 1
        } else {
            $itk_component(score) configure \
            -text $value \
            -foreground $itk_option(-foreground)

            bind $itk_component(score) <Button-1> ""
            set m_resultReady 0
        }
    }

    protected variable m_expanded 0

    private variable m_rowNameList ""
    private variable m_numRow 0
    private variable m_resultReady 0
    private variable m_LINKCOLOR #0000ff

    public method isExpanded { } {
        return $m_expanded
    }

    public method resultReady { } {
        return $m_resultReady
    }

    public method expand { } {
        set m_expanded 1
        repaint
    }
    public method shrink { } {
        set m_expanded 0
        repaint
    }
    public method repaint { }
    public method handleClick { } {
        if {$itk_option(-clickCommand) == ""} {
            set m_expanded [expr !$m_expanded]
            repaint
        } else {
            eval $itk_option(-clickCommand)
        }
    }

    constructor { args} {
        lappend m_rowNameList \
        "score" \
        "unit cell" \
        "mosaicity" \
        "rmsr" \
        "bravais lattice"

        set m_numRow [llength $m_rowNameList]

        set ring $itk_interior
        itk_component add score {
            label $ring.score \
            -anchor w
        } {
                keep -font -relief -background -activeforeground
        }

        set row_no 0
        foreach rowName $m_rowNameList {
            itk_component add row_label$row_no {
                label $ring.rowl$row_no \
                -width 20 \
                -anchor e \
                -text $rowName
            } {
                keep -font -relief -background -foreground -activeforeground
            }
            bind $itk_component(row_label$row_no) <Button-1> "$this handleClick"
            itk_component add row_value$row_no {
                label $ring.rowv$row_no \
                -background #a0a0a0 \
                -width 20 \
                -anchor w
            } {
            }
            bind $itk_component(row_value$row_no) <Button-1> "$this handleClick"

            incr row_no
        }

        eval itk_initialize $args

        repaint
    }
}

body SILScore::repaint { } {
    if {!$m_expanded} {
        for {set i 0} {$i < $m_numRow} {incr i} {
            grid forget $itk_component(row_label$i) $itk_component(row_value$i)
        }

        #grid $itk_component(score) -row 0 -column 0 -sticky w
        pack $itk_component(score) -side left
    } else {
        pack forget $itk_component(score)

        for {set i 0} {$i < $m_numRow} {incr i} {
            grid $itk_component(row_label$i) -row $i -column 0 -sticky e
            grid $itk_component(row_value$i) -row $i -column 1 -sticky w
        }
    }
}
configbody SILScore::foreground {
    if {!$m_resultReady} {
        $itk_component(score) configure -foreground $itk_option(-foreground)
    }
}

##################test
if {0} {
SILImage .cc
.cc configure -jpgLink /data/jsong/adfasdf.jpg
.cc configure -imgLink /data/jsong/adfasdf.img
.cc configure -analysisResult "good 2 3 circule 3A"
SILScore .ss
.ss configure -analysisResult "61 {12 34 45 80 56 45} 45 34 {1 2 3}"
pack .cc
pack .ss
}
