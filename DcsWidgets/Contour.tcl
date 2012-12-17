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
package provide DCSContour 1.0

# load standard packages
package require Iwidgets

class DCS::StaticLabel {
    inherit ::itk::Widget

    public method set { content } {
        $itk_component(label) configure -text $content
    }
    public method get { } {
        return [$itk_component(label) cget -text]
    }

    constructor { args } {
		itk_component add ring {
			frame $itk_interior.r
		}

		itk_component add prompt {
			label $itk_component(ring).p -takefocus 0
		} {
			keep -font -width -height -state -activebackground
			keep -activeforeground -background
			keep -padx -pady

			rename -relief -promptRelief promptRelief PromptRelief
			rename -foreground -promptForeground promptForeground PromptForeground
            rename -background -promptBackground promptBackground PromptBackground
			rename -width -promptWidth promptWidth PromptWidth
			rename -text -promptText promptText PromptText
			rename -anchor -promptAnchor promptAnchor PromptAnchor
		}
		
		itk_component add label {
			label $itk_component(ring).l
		} {
			keep -font -width -height -state -activebackground
			keep -activeforeground -background -foreground -relief
			keep -padx -pady -anchor
			ignore -text -textvariable
		}

		pack $itk_component(prompt) -side left
		pack $itk_component(label) -side left
		pack $itk_component(ring)

		eval itk_initialize $args
	}
	destructor {
    }
}

class DCS::Contour {
    inherit ::itk::Widget

    public method clear { }

    public method setTitle { title }

    public method setup { numRow startRowValue rowStep numColumn startColValue ColStep }

    public method addData { position value {draw 1} }

    public method allDataDone { }

    public method draw { }
    public method redraw { }

    public method drawContour { number }

    public method print { }

    ###to reserve precision, we only support zoom X2 /2
    # zoom factor will be 1-8
    #init node size = max(8, 200/numColumn)
    public method zoomIn { }
    public method zoomOut { }

    public method registerMarkMoveCallback { method_to_call } { 
        set m_markCallback $method_to_call
    }

    ##########MARK##########
    public method drawMarker { x y mark_num }
    public method removeMark { mark_num }


    private variable m_numRow 2
    private variable m_firstRowPos {0 mm}
    private variable m_rowStep {1 mm}
    private variable m_lastRowPos  {1 mm}
    private variable m_numColumn 2
    private variable m_firstColumnPos {0 mm}
    private variable m_columnStep {1 mm}
    private variable m_lastColumnPos {1 mm}
    private variable m_obj
    private variable m_contour
    private variable m_rowPlot {}
    private variable m_columnPlot {}

    private variable m_scrollRegion {0 0 200 200}

    ########zoom
    private variable m_zoomFactor 1
    ###we will keep node width == height for now
    private variable m_initNodeWidth 8
    private variable m_initNodeHeight 8
    private variable m_rawWidth
    private variable m_rawHeight

    ###marker move callback
    private variable m_markCallback ""
    private variable m_setupOK 0

    private variable m_markId1 ""
    private variable m_markId2 ""

    ##### update #######
    private variable m_dynamicUpdate 1

    private variable MAXZOOM 8
    private variable MINZOOM 1
    private variable MARK1COLOR red
    private variable MARK2COLOR green
    private variable MARK2TEXTCOLOR #008000

    private variable ROWPLOTHEIGHT 100
    private variable COLUMNPLOTWIDTH 100

    constructor { args } {
        puts "+Contour constructor"

        #create new C++ object
        set m_obj [createNewDcsScan2DData]

        itk_component add title {
            label $itk_interior.title -text "2D scan"
        } {
        }

        itk_component add pw {
            ::iwidgets::panedwindow $itk_interior.contour \
            -orient vertical
        } {
            keep -width -height
        }

        $itk_component(pw) add picture_area -margin 0
        $itk_component(pw) add text_area -margin 0
        $itk_component(pw) fraction 70 30

        set PictureSite [$itk_component(pw) childsite picture_area]
        set TextSite [$itk_component(pw) childsite text_area]

        itk_component add s_canvas {
            iwidgets::scrolledcanvas $PictureSite.canvas \
            -scrollregion $m_scrollRegion \
            -autoresize 1
        } {
        }

        itk_component add control {
            iwidgets::labeledframe $TextSite.control \
            -labeltext "Control"
        } {
        }
        set controlSite [$itk_component(control) childsite]

        itk_component add marks_f {
            iwidgets::labeledframe $TextSite.marks \
            -labeltext "Marks"
        } {
        }
        set markSite [$itk_component(marks_f) childsite]

        itk_component add dynamic {
            frame $controlSite.du
        } {
        }
        itk_component add du_cb {
            checkbutton $itk_component(dynamic).cb \
            -variable [scope m_dynamicUpdate]
        } {
        }
        itk_component add du_l {
            label $itk_component(dynamic).cl \
            -text "dyn draw"
        } {
        }

        pack $itk_component(du_cb) -side left
        pack $itk_component(du_l) -side left

        itk_component add contour1 {
            iwidgets::entryfield $controlSite.c1 \
            -command "$this drawContour 1" \
            -labeltext "contour 1" \
            -labelpos w \
            -foreground red \
            -textbackground white \
            -validate integer \
            -width 2 \
            -fixed 2
        } {
        }
        itk_component add contour2 {
            iwidgets::entryfield $controlSite.c2 \
            -command "$this drawContour 2" \
            -labeltext "contour 2" \
            -labelpos w \
            -foreground blue \
            -textbackground white \
            -validate integer \
            -width 2 \
            -fixed 2
        } {
        }

        itk_component add zoom_in {
            button $controlSite.zi -text "zoomX2" -command "$this zoomIn" -state disabled
        } {
        }
        itk_component add zoom_out {
            button $controlSite.zo -text "zoom/2" -command "$this zoomOut" -state disabled
        } {
        }

        itk_component add clear_mark1 {
            button $controlSite.cm1 -text "remove mark1" -command "$this removeMark 1" -state disabled
        } {
        }

        itk_component add clear_mark2 {
            button $controlSite.cm2 -text "remove mark2" -command "$this removeMark 2" -state disabled
        } {
        }

        $itk_component(contour1) insert end 90
        $itk_component(contour2) insert end 50
        
        pack $itk_component(dynamic) -fill x -expand 1 -side top
        pack $itk_component(contour1) -fill x -expand 1 -side top
        pack $itk_component(contour2) -fill x -expand 1 -side top
        pack $itk_component(zoom_in) -fill x -expand 1 -side top
        pack $itk_component(zoom_out) -fill x -expand 1 -side top
        pack $itk_component(clear_mark1) -fill x -expand 1 -side top
        pack $itk_component(clear_mark2) -fill x -expand 1 -side top
        

        option add *StaticLabel*PromptWidth 8
        option add *StaticLabel*PromptAnchor w
        option add *StaticLabel*Width 12
        option add *StaticLabel*Anchor w
        option add *StaticLabel*Relief sunken
        option add *StaticLabel*Background #00a040

        set text_width 16
        set text_bg #00a040

        itk_component add m11 {
            DCS::StaticLabel $markSite.m11 \
            -promptText "motor1:" \
            -promptForeground $MARK1COLOR
        } {
        }
        itk_component add m12 {
            DCS::StaticLabel $markSite.m12 \
            -promptText "motor2:" \
            -promptForeground $MARK1COLOR
        } {
        }
        itk_component add m1c {
            DCS::StaticLabel $markSite.m1c \
            -promptText "count:" \
            -promptForeground $MARK1COLOR
        } {
        }

        itk_component add m21 {
            DCS::StaticLabel $markSite.m21 \
            -promptText "motor1:" \
            -promptForeground $MARK2TEXTCOLOR
        } {
        }
        itk_component add m22 {
            DCS::StaticLabel $markSite.m22 \
            -promptText "motor2:" \
            -promptForeground $MARK2TEXTCOLOR
        } {
        }
        itk_component add m2c {
            DCS::StaticLabel $markSite.m2c \
            -promptText "count:" \
            -promptForeground $MARK2TEXTCOLOR
        } {
        }

        itk_component add d1 {
            DCS::StaticLabel $markSite.d1 \
            -promptText "delta1:"
        } {
        }
        itk_component add d2 {
            DCS::StaticLabel $markSite.d2 \
            -promptText "delta2:"
        } {
        }
        itk_component add dc {
            DCS::StaticLabel $markSite.dc \
            -promptText "delta:"
        } {
        }

        pack $itk_component(m11) -side top -pady 2
        pack $itk_component(m12) -side top -pady 2
        pack $itk_component(m1c) -side top -pady 2
        pack $itk_component(m21) -side top -pady 2
        pack $itk_component(m22) -side top -pady 2
        pack $itk_component(m2c) -side top -pady 2
        pack $itk_component(d1) -side top -pady 2
        pack $itk_component(d2) -side top -pady 2
        pack $itk_component(dc) -side top -pady 2

        pack $itk_component(s_canvas) -expand 1 -fill both

        pack $itk_component(control) -side left -anchor n
        pack $itk_component(marks_f) -side left -anchor n

        $itk_component(s_canvas) xview moveto 0
        $itk_component(s_canvas) yview moveto 0

        pack $itk_component(title) -side top -fill x
        pack $itk_component(pw) -expand 1 -fill both
        $itk_component(pw) fraction 60 40
        pack $itk_interior -expand 1 -fill both

        eval itk_initialize $args

        bind [$itk_component(s_canvas) component canvas] <B1-Motion> "$this drawMarker %x %y 1"
        bind [$itk_component(s_canvas) component canvas] <ButtonPress-1> "$this drawMarker %x %y 1"
        bind [$itk_component(s_canvas) component canvas] <ButtonRelease-1> "$this drawMarker %x %y 1"

        bind [$itk_component(s_canvas) component canvas] <B2-Motion> "$this drawMarker %x %y 1"
        bind [$itk_component(s_canvas) component canvas] <ButtonPress-2> "$this drawMarker %x %y 1"
        bind [$itk_component(s_canvas) component canvas] <ButtonRelease-2> "$this drawMarker %x %y 1"

        bind [$itk_component(s_canvas) component canvas] <B3-Motion> "$this drawMarker %x %y 2"
        bind [$itk_component(s_canvas) component canvas] <ButtonPress-3> "$this drawMarker %x %y 2"
        bind [$itk_component(s_canvas) component canvas] <ButtonRelease-3> "$this drawMarker %x %y 2"

        puts "-Contour constructor"
    }
    destructor {
        ##delete the C++ object
        rename $m_obj {}
    }
}

body DCS::Contour::setup { numRow startRowValue rowStep numColumn startColValue colStep } {
    puts "+Contour::setup $numRow {$startRowValue} $rowStep $numColumn {$startColValue} $colStep"

    set m_setupOK 0

    if {$numRow < 2} {
        log_error Contour::setup: bad numRow "$numRow"
        return
    }
    set m_numRow $numRow
    #may have units
    set y0    [lindex $startRowValue 0]
    set yStep [lindex $rowStep 0]

    if {$numColumn < 2} {
        log_error Contour::setup: bad numColumn "$numColumn"
        return
    }
    set m_numColumn $numColumn
    set x0    [lindex $startColValue 0]
    set xStep [lindex $colStep 0]

    $m_obj setup $numRow $y0 $yStep $numColumn $x0 $xStep

    ######node size
    set m_rawWidth 200
    set m_rawHeight 200
    puts "canvas w: {$m_rawWidth} h: {$m_rawHeight}"
    set rec_w [expr $m_rawWidth / $m_numColumn]
    set rec_h [expr $m_rawHeight / $m_numRow]
    set m_initNodeWidth [expr ($rec_w < $rec_h) ? $rec_w : $rec_w]
    if {$m_initNodeWidth < 8} {
        set m_initModeWidth 8
    }
    set m_initNodeHeight $m_initNodeWidth

    set m_rawWidth [expr $m_initNodeWidth * $m_numColumn]
    set m_rawHeight [expr $m_initNodeHeight * $m_numRow]

    #########save setup so that we can calculate mark to motor position
    set m_firstRowPos    $startRowValue
    set m_rowStep        $rowStep
    set m_lastRowPos     [expr $y0 + $rowStep * ($numRow - 1)]
    set m_firstColumnPos $startColValue
    set m_columnStep     $colStep
    set m_lastColumnPos  [expr $x0 + $colStep * ($numColumn - 1)]

    ######## enable zoom #########3
    set m_zoomFactor 1
    $itk_component(zoom_in) configure -state normal

    set m_setupOK 1

    puts "rectange w: {$m_initNodeWidth} h: {$m_initNodeHeight}"
    puts "-Contour::setup"
}

body DCS::Contour::addData { position value { draw 1 } } {
    puts "+Contour::addData $position $value"
    
    if {!$m_setupOK} {
        log_error need setup first
        return
    }


    set firstValue [lindex $value 0]

    set y [lindex $position 0]
    set x [lindex $position 1]

    set result [$m_obj addData $y $x $firstValue]

    if {!$result} {
        puts "Contour::addData failed"
        return
    }

    ### update GUI
    if {!$draw} {
        return
    }

    if {$result == -1} {
        redraw
    } else {
        puts "no redraw only draw 1 rectangle"
        #$result == 1
        #just draw one rectangle for this data
        #because max min did not change
        #so color of other nodes do not need to change
        set col_row [$m_obj toColumnRow $x $y]
        set c [lindex $col_row 0]
        set r [lindex $col_row 1]

        ###node size consider zoom factor
        set nodeWidth [expr $m_zoomFactor * $m_initNodeWidth]
        set nodeHeight [expr $m_zoomFactor * $m_initNodeHeight]
        set y1 [expr $r * $nodeHeight]
        set y2 [expr ($r + 1) * $nodeHeight]
        set x1 [expr $c * $nodeWidth]
        set x2 [expr ($c + 1) * $nodeWidth]
        set colorValue [$m_obj getColor $r $c]
        if {$colorValue < 0} {
            set color red
        } else {
            set color [format "\#%02x%02x%02x" $colorValue $colorValue $colorValue]
        }
        $itk_component(s_canvas) create rectangle $x1 $y1 $x2 $y2 -fill $color -outline $color -tags raw_data
    }
    puts "-Contour::addData"
}

body DCS::Contour::draw { } {

    puts "+Contour::draw"
    
    if {!$m_setupOK} {
        log_error need setup first
        return
    }


    if {$m_numRow < 2} {
        log_error bad numRow "$m_numRow"
        return
    }
    if {$m_numColumn < 2} {
        log_error bad numColumn "$m_numColumn"
        return
    }

    if {!$m_dynamicUpdate && ![$m_obj allDataDefined]} {
        return
    }

    ###node size consider zoom factor
    set nodeWidth [expr $m_zoomFactor * $m_initNodeWidth]
    set nodeHeight [expr $m_zoomFactor * $m_initNodeHeight]

    
    $itk_component(s_canvas) delete all
    $itk_component(s_canvas) create rectangle 0 0 $m_rawWidth $m_rawHeight -fill red

    $itk_component(s_canvas) create rectangle \
    $m_rawWidth 0 [expr $m_rawWidth + $COLUMNPLOTWIDTH] $m_rawHeight \
    -fill white \
    -tags special_zoom_x

    $itk_component(s_canvas) create rectangle \
    0 $m_rawHeight $m_rawWidth [expr $m_rawHeight + $ROWPLOTHEIGHT] \
    -fill white \
    -tags special_zoom_y

    #add labels
    $itk_component(s_canvas) create text 0 0 \
    -anchor sw \
    -justify left \
    -text $m_firstColumnPos

    $itk_component(s_canvas) create text $m_rawWidth 0 \
    -anchor se \
    -justify right \
    -text $m_lastColumnPos

    $itk_component(s_canvas) create text 0 0 \
    -anchor ne \
    -justify right \
    -text $m_firstRowPos

    $itk_component(s_canvas) create text 0 $m_rawHeight \
    -anchor se \
    -justify right \
    -text $m_lastRowPos

    set min_max [$m_obj getMinMax]
    $itk_component(s_canvas) create text $m_rawWidth $m_rawHeight \
    -anchor nw \
    -justify left \
    -text "min: [lindex $min_max 0]"

    $itk_component(s_canvas) create text $m_rawWidth [expr $m_rawHeight + $ROWPLOTHEIGHT] \
    -anchor sw \
    -justify left \
    -tags special_zoom_y \
    -text "max: [lindex $min_max 1]"

    for {set r 0} {$r < $m_numRow} {incr r} {
        set y1 [expr $r * $nodeHeight]
        set y2 [expr ($r + 1) * $nodeHeight]
        for {set c 0} {$c < $m_numColumn} {incr c} {
            set colorValue [$m_obj getColor $r $c]
            if {$colorValue < 0} {
                continue
            } else {
                set color [format "\#%02x%02x%02x" $colorValue $colorValue $colorValue]
            }
            set x1 [expr $c * $nodeWidth]
            set x2 [expr ($c + 1) * $nodeWidth]
            #puts "draw {$r, $c} at {$x1, $y1, $x2, $y2} with color {$color}"
            set id [$itk_component(s_canvas) create rectangle $x1 $y1 $x2 $y2 -fill $color -outline $color -tags raw_data]
        }
    }

    ###################### contour ##########################
    $m_obj setNodeSize $nodeWidth $nodeHeight
    $m_obj set1DPlotSize $ROWPLOTHEIGHT $COLUMNPLOTWIDTH
    drawContour 1
    drawContour 2
    $itk_component(s_canvas) xview moveto 0
    $itk_component(s_canvas) yview moveto 0
    set m_scrollRegion [$itk_component(s_canvas) bbox all]
    $itk_component(s_canvas) configure -scrollregion $m_scrollRegion

}

body DCS::Contour::drawContour { number } {
    
    if {!$m_setupOK} {
        log_error 2D data not ready yet 
        return
    }

    set tag contour$number

    switch -exact -- $number {
    1 { set color red }
    2 { set color blue }
    default { set color black }
    }

    $itk_component(s_canvas) delete $tag

    if {![$m_obj allDataDefined]} {
        log_warning not all data defined, contour skipped
        return
    }

    set level [$itk_component($tag) get]
    if {[isPositiveInt $level] && $level > 0 && $level < 100} {
        if {[$m_obj getContour [expr double($level) / 100.0 ]] > 0} {
            foreach segment [array names m_contour] {
                $itk_component(s_canvas) create line $m_contour($segment) -fill $color -width 2 -tags [list contour $tag]
            }
        }
    } else {
        log_warning bad $tag level: $level should be 1-99
    }
}

body DCS::Contour::redraw { } {
    puts "+Contour::redraw"
    $itk_component(s_canvas) delete all
    puts "call draw"

    $this draw

    puts "-Contour::redraw"
}

body DCS::Contour::print { } {
    set filename [file nativename "~/.bluice_print.ps"]
    $itk_component(s_canvas) postscript \
    -file $filename \
    -colormode color \
    -rotate 1

    exec lp $filename
}

body DCS::Contour::zoomIn { } {
    $itk_component(zoom_out) configure -state normal
    if {$m_zoomFactor >= $MAXZOOM} {
        log_error max zoom ($MAXZOOM) reached
        return
    }
    set old_x [lindex [$itk_component(s_canvas) xview] 0]
    set old_y [lindex [$itk_component(s_canvas) yview] 0]

    set m_zoomFactor [expr 2 * $m_zoomFactor]

    if {$m_zoomFactor >= $MAXZOOM} {
        $itk_component(zoom_in) configure -state disabled
    }

    set m_rawWidth [expr $m_rawWidth * 2]
    set m_rawHeight [expr $m_rawHeight * 2]

    $m_obj setNodeSize [expr $m_zoomFactor * $m_initNodeWidth] [expr $m_zoomFactor * $m_initNodeHeight]
    $itk_component(s_canvas) scale all 0 0 2 2

    ####special cases
    $itk_component(s_canvas) scale special_zoom_x $m_rawWidth 0 0.5 1
    $itk_component(s_canvas) scale special_zoom_y 0 $m_rawHeight 1 0.5

    set m_scrollRegion [$itk_component(s_canvas) bbox all]
    $itk_component(s_canvas) configure -scrollregion $m_scrollRegion

    $itk_component(s_canvas) xview moveto $old_x
    $itk_component(s_canvas) yview moveto $old_y
}

body DCS::Contour::zoomOut { } {
    $itk_component(zoom_in) configure -state normal
    if {$m_zoomFactor <= $MINZOOM} {
        log_error min zoom ($MINZOOM) reached
        return
    }
    set old_x [lindex [$itk_component(s_canvas) xview] 0]
    set old_y [lindex [$itk_component(s_canvas) yview] 0]

    set m_zoomFactor [expr $m_zoomFactor / 2]
    if {$m_zoomFactor <= $MINZOOM} {
        $itk_component(zoom_out) configure -state disabled
    }

    set m_rawWidth [expr $m_rawWidth / 2]
    set m_rawHeight [expr $m_rawHeight / 2]


    $m_obj setNodeSize [expr $m_zoomFactor * $m_initNodeWidth] [expr $m_zoomFactor * $m_initNodeHeight]

    $itk_component(s_canvas) scale all 0 0 0.5 0.5
    $itk_component(s_canvas) scale special_zoom_x $m_rawWidth 0 2 1
    $itk_component(s_canvas) scale special_zoom_y 0 $m_rawHeight 1 2 

    set m_scrollRegion [$itk_component(s_canvas) bbox all]
    $itk_component(s_canvas) configure -scrollregion $m_scrollRegion

    $itk_component(s_canvas) xview moveto $old_x
    $itk_component(s_canvas) yview moveto $old_y
}

body DCS::Contour::drawMarker { x y mark_num } {
    #puts "drawMarker $x $y $mark_num"
    
    if {!$m_setupOK} {
        return
    }

    set x [$itk_component(s_canvas) canvasx $x]
    set y [$itk_component(s_canvas) canvasy $y]

    set x1 0
    set y1 0
    set x2 $m_rawWidth
    set y2 $m_rawHeight
    if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
        return
    }

    $itk_component(s_canvas) delete mcursor$mark_num

    set mark_color $MARK1COLOR
    set text_color $MARK1COLOR
    if {$mark_num != 1} {
        set mark_color $MARK2COLOR
        set text_color $MARK2TEXTCOLOR
    }

    ##mark lines extend to cross row and column plots
    set x2 [expr $x2 + $COLUMNPLOTWIDTH]
    set y2 [expr $y2 + $ROWPLOTHEIGHT]

    $itk_component(s_canvas) create line $x1 $y $x2 $y \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3
    $itk_component(s_canvas) create line $x $y1 $x $y2 \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3

    #enable remove button
    $itk_component(clear_mark$mark_num) configure -state normal

    #calculate motor positions from mark
    set row [expr double($y) / ($m_zoomFactor * $m_initNodeHeight) - 0.5]
    set col [expr double($x) / ($m_zoomFactor * $m_initNodeWidth) - 0.5]

    set y0    [lindex $m_firstRowPos 0]
    set yStep [lindex $m_rowStep 0]
    set x0    [lindex $m_firstColumnPos 0]
    set xStep [lindex $m_columnStep 0]

    set motor1 [expr $y0 + $row * $yStep]
    set motor2 [expr $x0 + $col * $xStep]

    #format result as "xxxxx units"
    set text1 [format %.5g $motor1]
    set text2 [format %.5g $motor2]
    set motor1 "$text1 [lindex $m_firstRowPos 1]"
    set motor2 "$text2 [lindex $m_firstColumnPos 1]"
    
    #puts "motor1=$motor1 motor2=$motor2"

    if {[catch {
        set value [$m_obj getValue $x $y]
        } errMsg]} {
        eval log_warning value not available yet: $errMsg
        set value 0
    }
    if { int($value) != $value } {
        set value [format "%9.6f" $value]
    } else {
        set value [format "%9.0f" $value]
    }

    ###update text marker
    set text_x $x
    set text_y [expr $y - 10]
    set text_id [$itk_component(s_canvas) create text $text_x $text_y \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -fill $text_color \
    -anchor s \
    -justify center \
    -text "$text1 $text2 $value"]

    set m_markId$mark_num $text_id

    set text_box [$itk_component(s_canvas) bbox $text_id]
    $itk_component(s_canvas) create rectangle $text_box \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -outline white \
    -fill white
    $itk_component(s_canvas) raise $text_id
    

    #update mark display
    $itk_component(m${mark_num}1) set $motor1
    $itk_component(m${mark_num}2) set $motor2
    $itk_component(m${mark_num}c) set $value

    if {[$itk_component(m11) get] != "" && [$itk_component(m21) get] != ""} {
        ########## update delta between mark1 and mark2
        set m1list [$itk_component(m11) get]
        set m1 [lindex $m1list 0]
        set m2 [lindex [$itk_component(m21) get] 0]
        set d [expr $m2 -$m1]
        set units [lindex $m1list 1]
        $itk_component(d1) set "$d $units"
    
        set m1list [$itk_component(m12) get]
        set m1 [lindex $m1list 0]
        set m2 [lindex [$itk_component(m22) get] 0]
        set d [expr $m2 -$m1]
        set units [lindex $m1list 1]
        $itk_component(d2) set "$d $units"
    
        set m1list [$itk_component(m1c) get]
        set m1 [lindex $m1list 0]
        set m2 [lindex [$itk_component(m2c) get] 0]
        set d [expr $m2 -$m1]
        if { int($d) != $d } {
            set d [format "%9.6f" $d]
        } else {
            set d [format "%9.0f" $d]
        }
        $itk_component(dc) set $d
    }

    if {$m_markId1 != "" && $m_markId2 != ""} {
        set pos1 [$itk_component(s_canvas) itemcget $m_markId1 -text]
        set pos2 [$itk_component(s_canvas) itemcget $m_markId2 -text]
        set delta [list]
        foreach v1 $pos1 v2 $pos2 {
            lappend delta [expr $v2 - $v1]
        }
        set text1 [format %.5g [lindex $delta 0]]
        set text2 [format %.5g [lindex $delta 1]]
        set d [lindex $delta 2]
        if { int($d) != $d } {
            set d [format "%9.6f" $d]
        } else {
            set d [format "%9.0f" $d]
        }

        #######update delta mark#########
        set text_x $x
        set text_y [expr $y + 10]
        set text_id [$itk_component(s_canvas) create text $text_x $text_y \
        -tags [list mark mark1 mark2 mcursor1 mcursor2] \
        -anchor n \
        -justify center \
        -text "$text1 $text2 $d"]

        set text_box [$itk_component(s_canvas) bbox $text_id]
        $itk_component(s_canvas) create rectangle $text_box \
        -tags [list mark mark1 mark2 mcursor1 mcursor2] \
        -outline white \
        -fill white
        $itk_component(s_canvas) raise $text_id
    }

    #################update row plot and colum plot########
    set mark_color $MARK1COLOR
    if {$mark_num != 1} {
        set mark_color $MARK2COLOR
    }

    $itk_component(s_canvas) delete mplot$mark_num

    $m_obj getRowPlot $y
    if {[info exists m_rowPlot]} {
        set ln [llength $m_rowPlot]
        if {$ln >= 4} {
            $itk_component(s_canvas) create line $m_rowPlot \
            -fill $mark_color \
            -width 3 \
            -tags [list mark$mark_num mplot$mark_num mrplot special_zoom_y]
        } elseif {$ln == 2} {
            set x0 [lindex $m_rowPlot 0]
            set y0 [lindex $m_rowPlot 1]
            set x1 [expr $x0 - 1]
            set y1 [expr $y0 - 1]
            set x2 [expr $x0 + 1]
            set y2 [expr $y0 + 1]
            $itk_component(s_canvas) create oval $x1 $y1 $x2 $y2 \
            -fill $mark_color \
            -outline $mark_color \
            -tags [list mark$mark_num mplot$mark_num mrplot special_zoom_y]
        }
    }
    $m_obj getColumnPlot $x
    if {[info exists m_columnPlot]} {
        set ln [llength $m_columnPlot]
        if {$ln >= 4} {
            $itk_component(s_canvas) create line $m_columnPlot \
            -fill $mark_color \
            -width 3 \
            -tags [list mark$mark_num mplot$mark_num mcplot special_zoom_x]
        } elseif {$ln == 2} {
            set x0 [lindex $m_columnPlot 0]
            set y0 [lindex $m_columnPlot 1]
            set x1 [expr $x0 - 1]
            set y1 [expr $y0 - 1]
            set x2 [expr $x0 + 1]
            set y2 [expr $y0 + 1]
            $itk_component(s_canvas) create oval $x1 $y1 $x2 $y2 \
            -fill $mark_color \
            -outline $mark_color \
            -tags [list mark$mark_num mplot$mark_num mcplot special_zoom_x]
        }

    }

    #########only update motor control mark 1
    if {$mark_num != 1} {
        return
    }

    if {$m_markCallback != ""} {
        set command $m_markCallback
        lappend command $motor1 $motor2
        eval $command
    }
    return
}

body DCS::Contour::clear { } {
    #set m_markCallback ""
    set m_setupOK 0
    $itk_component(title) configure -text ""
    $itk_component(s_canvas) delete all
    $itk_component(zoom_in) configure -state disabled
    $itk_component(zoom_out) configure -state disabled

    removeMark 1
    removeMark 2
}

body DCS::Contour::setTitle { title } {
    $itk_component(title) configure -text $title
}
body DCS::Contour::allDataDone { } {
    if {![$m_obj allDataDefined]} {
        $m_obj setAllData
    }
    drawContour 1
    drawContour 2
}

body DCS::Contour::removeMark { mark_num } {
    #this will remove both mark and its plots
    $itk_component(s_canvas) delete mark$mark_num

    set m_markId$mark_num ""

    #clear up mark display
    $itk_component(m${mark_num}1) set ""
    $itk_component(m${mark_num}2) set ""
    $itk_component(m${mark_num}c) set ""

    #clear up delta display
    $itk_component(d1) set ""
    $itk_component(d2) set ""
    $itk_component(dc) set ""

    #disable this button
    $itk_component(clear_mark$mark_num) configure -state disabled
}
class DCS::Simple2DScanView {
    inherit ::itk::Widget

    itk_option define -contour1 contour1 ConTour 50 { drawContour 1 }
    itk_option define -contour2 contour2 ConTour 95 { drawContour 2 }

    public method clear { }

    public method setup { numRow startRowValue endRowValue numColumn startColValue endColValue }

    public method addData { position value {draw 1} }

    public method allDataDone { }

    public method draw { }
    public method redraw { }

    public method drawContour { number }

    public method print { }

    public method registerMarkMoveCallback { method_to_call } { 
        set m_markCallback $method_to_call
    }

    public method handleResize {winID w h} {
        if {$m_winID != $winID} {
            return
        }
        set m_drawWidth  [expr $w - 4]
        set m_drawHeight [expr $h - 4]
        #set m_drawWidth  $w
        #set m_drawHeight $h
        redraw
    }

    ##########MARK##########
    public method drawMarker { x y mark_num }
    public method removeMark { mark_num }

    public method setCurrentPosition { v h }
    private method drawCurrentPosition { }

    private variable m_numRow 2
    private variable m_firstRowPos {0 mm}
    private variable m_rowStep {1 mm}
    private variable m_lastRowPos  {1 mm}
    private variable m_numColumn 2
    private variable m_firstColumnPos {0 mm}
    private variable m_columnStep {1 mm}
    private variable m_lastColumnPos {1 mm}
    private variable m_obj
    private variable m_contour
    private variable m_rowPlot {}
    private variable m_columnPlot {}

    private variable m_scrollRegion {0 0 200 200}

    private variable m_winID "not defined yet"
    private variable m_drawWidth 0
    private variable m_drawHeight 0

    ###marker move callback
    private variable m_markCallback ""
    private variable m_setupOK 0

    private variable m_markId1 ""
    private variable m_markId2 ""

    private variable m_currentV -999
    private variable m_currentH -999

    ##### update #######
    private variable m_dynamicUpdate 1

    private variable MARK1COLOR red
    private variable MARK2COLOR green
    private variable MARK2TEXTCOLOR #008000

    constructor { args } {
        puts "+Simple2DScanView constructor"

        #create new C++ object
        set m_obj [createNewDcsScan2DData]

        itk_component add s_canvas {
            canvas $itk_interior.canvas
        } {
        }

        pack $itk_component(s_canvas) -expand 1 -fill both
        set m_winID $itk_component(s_canvas)
        bind $m_winID <Configure> "$this handleResize %W %w %h"

        eval itk_initialize $args

        bind $itk_component(s_canvas) <B1-Motion> "$this drawMarker %x %y 1"
        bind $itk_component(s_canvas) <ButtonPress-1> "$this drawMarker %x %y 1"
        bind $itk_component(s_canvas) <ButtonRelease-1> "$this drawMarker %x %y 1"

        bind $itk_component(s_canvas) <ButtonRelease-3> "$this removeMark 1"
        puts "-Simple2DScanView constructor"
    }
    destructor {
        ##delete the C++ object
        rename $m_obj {}
    }
}

body DCS::Simple2DScanView::setup { numRow startRowValue rowStep numColumn startColValue colStep } {
    puts "+Simple2DScanView::setup $numRow $startRowValue $rowStep $numColumn $startColValue $colStep"

    set m_setupOK 0

    if {$numRow < 1} {
        log_error Simple2DScanView::setup: bad numRow "$numRow"
        return
    }
    set m_numRow $numRow
    #may have units
    set y0    [lindex $startRowValue 0]
    set yStep [lindex $rowStep 0]

    if {$numColumn < 1} {
        log_error Simple2DScanView::setup: bad numColumn "$numColumn"
        return
    }
    set m_numColumn $numColumn
    set x0    [lindex $startColValue 0]
    set xStep [lindex $colStep 0]

    $m_obj setup $numRow $y0 $yStep $numColumn $x0 $xStep

    set m_firstRowPos    $startRowValue
    set m_rowStep        $rowStep
    set m_lastRowPos     [expr $startRowValue + $rowStep * ($numRow - 1)]
    set m_firstColumnPos $startColValue
    set m_columnStep     $colStep
    set m_lastColumnPos  [expr $startColValue + $colStep * ($numCol - 1)]

    set m_setupOK 1

    puts "-Simple2DScanView::setup"
}

body DCS::Simple2DScanView::addData { position value { draw 1 } } {
    puts "+Simple2DScanView::addData $position $value"
    
    if {!$m_setupOK} {
        log_error need setup first
        return
    }


    set firstValue [lindex $value 0]

    set y [lindex $position 0]
    set x [lindex $position 1]

    set result [$m_obj addData $y $x $firstValue]

    if {!$result} {
        puts "Simple2DScanView::addData failed"
        return
    }

    ### update GUI
    if {!$draw} {
        return
    }

    if {$result == -1} {
        redraw
    } else {
        puts "no redraw only draw 1 rectangle"
        #$result == 1
        #just draw one rectangle for this data
        #because max min did not change
        #so color of other nodes do not need to change
        set col_row [$m_obj toColumnRow $x $y]
        set c [lindex $col_row 0]
        set r [lindex $col_row 1]

        ###node size consider zoom factor
        set nodeWidth  [expr $m_drawWidth  / $m_numColumn]
        set nodeHeight [expr $m_drawHeight / $m_numRow]
        set y1 [expr $r * $nodeHeight]
        set y2 [expr ($r + 1) * $nodeHeight]
        set x1 [expr $c * $nodeWidth]
        set x2 [expr ($c + 1) * $nodeWidth]
        set colorValue [$m_obj getColor $r $c]
        if {$colorValue < 0} {
            set color red
        } else {
            set color [format "\#%02x%02x%02x" $colorValue $colorValue $colorValue]
        }
        $itk_component(s_canvas) create rectangle $x1 $y1 $x2 $y2 -fill $color -outline $color -tags raw_data
    }
    puts "-Simple2DScanView::addData"
}

body DCS::Simple2DScanView::draw { } {

    puts "+Simple2DScanView::draw"
    
    if {!$m_setupOK} {
        log_error need setup first
        return
    }


    if {$m_numRow < 2} {
        log_error bad numRow "$m_numRow"
        return
    }
    if {$m_numColumn < 2} {
        log_error bad numColumn "$m_numColumn"
        return
    }

    ###node size consider zoom factor
    set nodeWidth  [expr $m_drawWidth  / $m_numColumn]
    set nodeHeight [expr $m_drawHeight / $m_numRow]
    
    $itk_component(s_canvas) delete all
    $itk_component(s_canvas) create rectangle \
    0 0 [expr $m_drawWidth - 1] [expr $m_drawHeight - 1] \
    -fill red

    for {set r 0} {$r < $m_numRow} {incr r} {
        set y1 [expr $r * $nodeHeight]
        set y2 [expr ($r + 1) * $nodeHeight]
        for {set c 0} {$c < $m_numColumn} {incr c} {
            set colorValue [$m_obj getColor $r $c]
            if {$colorValue < 0} {
                continue
            } else {
                set color [format "\#%02x%02x%02x" $colorValue $colorValue $colorValue]
            }
            set x1 [expr $c * $nodeWidth]
            set x2 [expr ($c + 1) * $nodeWidth]
            #puts "draw {$r, $c} at {$x1, $y1, $x2, $y2} with color {$color}"
            set id [$itk_component(s_canvas) create rectangle $x1 $y1 $x2 $y2 -fill $color -outline $color -tags raw_data]
        }
    }

    ###################### contour ##########################
    drawContour 1
    drawContour 2
    drawCurrentPosition
    $itk_component(s_canvas) xview moveto 0
    $itk_component(s_canvas) yview moveto 0
    set m_scrollRegion [$itk_component(s_canvas) bbox all]
    $itk_component(s_canvas) configure -scrollregion $m_scrollRegion
}

body DCS::Simple2DScanView::drawContour { number } {
    
    if {!$m_setupOK} {
        log_error 2D data not ready yet 
        return
    }

    set tag contour$number

    switch -exact -- $number {
    1 { set color red }
    2 { set color blue }
    default { set color black }
    }

    $itk_component(s_canvas) delete $tag

    if {![$m_obj allDataDefined]} {
        log_warning not all data defined, contour skipped
        return
    }

    set level $itk_option(-$tag)
    if {[isPositiveInt $level] && $level > 0 && $level < 100} {
        if {[$m_obj getContour [expr double($level) / 100.0 ]] > 0} {
            foreach segment [array names m_contour] {
                $itk_component(s_canvas) create line $m_contour($segment) -fill $color -width 2 -tags [list contour $tag]
            }
        }
    } else {
        log_warning bad $tag level: $level should be 1-99
    }
}

body DCS::Simple2DScanView::redraw { } {
    puts "+Simple2DScanView::redraw"
    $itk_component(s_canvas) delete all
    puts "call draw"

    draw

    puts "-Simple2DScanView::redraw"
}

body DCS::Simple2DScanView::print { } {
    set filename [file nativename "~/.bluice_print.ps"]
    $itk_component(s_canvas) postscript \
    -file $filename \
    -colormode color \
    -rotate 1

    exec lp $filename
}

body DCS::Simple2DScanView::drawMarker { x y mark_num } {
    #puts "drawMarker $x $y $mark_num"
    
    if {!$m_setupOK} {
        return
    }

    set x [$itk_component(s_canvas) canvasx $x]
    set y [$itk_component(s_canvas) canvasy $y]

    set x1 0
    set y1 0
    set x2 [expr $m_drawWidth - 1]
    set y2 [expr $m_drawHeight - 1]
    if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
        return
    }

    $itk_component(s_canvas) delete mcursor$mark_num

    set mark_color $MARK1COLOR
    set text_color $MARK1COLOR
    if {$mark_num != 1} {
        set mark_color $MARK2COLOR
        set text_color $MARK2TEXTCOLOR
    }

    $itk_component(s_canvas) create line $x1 $y $x2 $y \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3
    $itk_component(s_canvas) create line $x $y1 $x $y2 \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3

    set nodeWidth  [expr $m_drawWidth  / $m_numColumn]
    set nodeHeight [expr $m_drawHeight / $m_numRow]
    #calculate motor positions from mark
    set row [expr double($y) / $nodeHeight - 0.5]
    set col [expr double($x) / $nodeWidth  - 0.5]

    set y0 [lindex $m_firstRowPos 0]
    set y1 [lindex $m_lastRowPos 0]
    set x0 [lindex $m_firstColumnPos 0]
    set x1 [lindex $m_lastColumnPos 0]

    set motor1 [expr double($y0) + $row * ($y1 - $y0) / ($m_numRow - 1)]
    set motor2 [expr double($x0) + $col * ($x1 - $x0) / ($m_numColumn - 1)]

    #format result as "xxxxx units"
    set text1 [format %.5g $motor1]
    set text2 [format %.5g $motor2]
    set motor1 "$text1 [lindex $m_firstRowPos 1]"
    set motor2 "$text2 [lindex $m_firstColumnPos 1]"

    if {[catch {
        set value [$m_obj getValue $x $y]
        } errMsg]} {
        eval log_warning value not available yet: $errMsg
        set value 0
    }
    if { int($value) != $value } {
        set value [format "%9.6f" $value]
    } else {
        set value [format "%5.0f" $value]
    }

    ### where to display the text
    if {$x < $m_drawWidth / 2} {
        set text_x [expr $x + 2]
        if {$y < $m_drawHeight / 2} {
            set text_y [expr $y + 2]
            set ar nw
        } else {
            set text_y [expr $y - 2]
            set ar sw
        }
    } else {
        set text_x [expr $x - 2]
        if {$y < $m_drawHeight / 2} {
            set text_y [expr $y + 2]
            set ar ne
        } else {
            set text_y [expr $y - 2]
            set ar se
        }
    }


    ###update text marker
    set text_id [$itk_component(s_canvas) create text $text_x $text_y \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -fill $text_color \
    -anchor $ar \
    -justify center \
    -text $value]

    set m_markId$mark_num $text_id

    set text_box [$itk_component(s_canvas) bbox $text_id]
    $itk_component(s_canvas) create rectangle $text_box \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -outline white \
    -fill white
    $itk_component(s_canvas) raise $text_id
    
    if {$mark_num != 1} {
        return
    }

    if {$m_markCallback != ""} {
        set command $m_markCallback
        lappend command $motor1 $motor2
        eval $command
    }
    return
}

body DCS::Simple2DScanView::clear { } {
    #set m_markCallback ""
    set m_setupOK 0
    $itk_component(s_canvas) delete all

    removeMark 1
    removeMark 2
}

body DCS::Simple2DScanView::allDataDone { } {
    if {![$m_obj allDataDefined]} {
        $m_obj setAllData
    }
    drawContour 1
    drawContour 2
}

body DCS::Simple2DScanView::removeMark { mark_num } {
    #this will remove both mark and its plots
    $itk_component(s_canvas) delete mark$mark_num

    set m_markId$mark_num ""
}
body DCS::Simple2DScanView::setCurrentPosition { v h } {
    set m_currentV $v
    set m_currentH $h
    
    if {!$m_setupOK} {
        return
    }
    drawCurrentPosition
}

body DCS::Simple2DScanView::drawCurrentPosition { } {
    set v $m_currentV
    set h $m_currentH
    set mark_num 2

    set y0 [lindex $m_firstRowPos 0]
    set y1 [lindex $m_lastRowPos 0]
    set x0 [lindex $m_firstColumnPos 0]
    set x1 [lindex $m_lastColumnPos 0]

    set row [expr (double($v) - $y0) * ($m_numRow - 1) / ($y1 - $y0)]
    set col [expr (double($h) - $x0) * ($m_numColumn - 1) / ($x1 - $x0)]

    set nodeWidth  [expr $m_drawWidth  / $m_numColumn]
    set nodeHeight [expr $m_drawHeight / $m_numRow]
    set y [expr ($row + 0.5) * $nodeHeight]
    set x [expr ($col + 0.5) * $nodeWidth]

    set x1 0
    set y1 0
    set x2 [expr $m_drawWidth - 1]
    set y2 [expr $m_drawHeight - 1]

    set v_line_width 1
    set h_line_width 1
    if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
        if {$x < $x1} {
            set v_line_width 3
            set x $x1
        }
        if {$x > $x2} {
            set v_line_width 3
            set x $x2
        }
        if {$y < $y1} {
            set h_line_width 3
            set y $y1
        }
        if {$y > $y2} {
            set h_line_width 3
            set y $y2
        }
    }

    $itk_component(s_canvas) delete mcursor$mark_num

    set mark_color $MARK1COLOR
    set text_color $MARK1COLOR
    if {$mark_num != 1} {
        set mark_color $MARK2COLOR
        set text_color $MARK2TEXTCOLOR
    }

    $itk_component(s_canvas) create line $x1 $y $x2 $y \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -dash {5 5} \
    -fill $mark_color \
    -width $h_line_width
    $itk_component(s_canvas) create line $x $y1 $x $y2 \
    -tags [list mark mark$mark_num mcursor$mark_num] \
    -dash {5 5} \
    -fill $mark_color \
    -width $v_line_width
}
class DCS::SimpleDouble2DScanView {
    inherit ::itk::Widget

    itk_option define -contour1 contour1 ConTour 50 { drawContour 1 }
    itk_option define -contour2 contour2 ConTour 95 { drawContour 2 }

    public method clear0 { }
    public method clear1 { }

    public method setup0 { setup }
    public method setup1 { setup }
    private method setupCommon { }

    public method addData0 { position value {draw 1} }
    public method addData1 { position value {draw 1} }

    public method allDataDone0 { }
    public method allDataDone1 { }

    public method draw { }
    public method redraw { }
    private method draw0 { }
    private method draw1 { }
    public method redraw0 { }
    public method redraw1 { }

    public method drawContour { number }

    public method print { }

    public method registerMarkMoveCallback { method_to_call } { 
        set m_markCallback $method_to_call
    }

    public method handleResize {winID w h} {
        if {$m_winID != $winID} {
            return
        }
        set m_drawWidth  [expr $w - 4]
        set m_drawHeight [expr $h - 4]
        #set m_drawWidth  $w
        #set m_drawHeight $h
        updatePixelParameters

        redraw
    }

    ##########MARK##########
    public method drawMarker { x y mark_num }
    public method drawMarker0 { x y mark_num }
    public method drawMarker1 { x y mark_num }
    public method removeMark { mark_num }

    public method setCurrentPosition { v0 h0 v1 h1 }
    private method drawCurrentPosition { }
    private method drawCurrentPosition0 { }
    private method drawCurrentPosition1 { }

    private method updatePixelParameters { }

    private proc displacement { segRef offsetV offsetH } {
        upvar $segRef xyList

        set old $xyList
        set result ""
        foreach {x y} $xyList {
            set x [expr $x + $offsetH]
            set y [expr $y + $offsetV]
            lappend result $x $y
        }
        set xyList $result
    }

    private method getMarkInfo0 { x y }
    private method getMarkInfo1 { x y }
    private method getXYFromPosition0 { v h }
    private method getXYFromPosition1 { v h }

    private variable m_numRow0 2
    private variable m_firstRowPos0 {0 mm}
    private variable m_rowStep0 {1 mm}
    private variable m_lastRowPos0  {1 mm}
    private variable m_numColumn0 2
    private variable m_firstColumnPos0 {0 mm}
    private variable m_columnStep0 {1 mm}
    private variable m_lastColumnPos0 {1 mm}
    private variable m_obj0

    private variable m_numRow1 2
    private variable m_firstRowPos1 {0 mm}
    private variable m_rowStep1 {1 mm}
    private variable m_lastRowPos1  {1 mm}
    private variable m_numColumn1 2
    private variable m_firstColumnPos1 {0 mm}
    private variable m_columnStep1 {1 mm}
    private variable m_lastColumnPos1 {1 mm}
    private variable m_obj1

    private variable m_contour
    private variable m_scrollRegion {0 0 200 200}

    private variable m_winID "not defined yet"
    private variable m_drawWidth 0
    private variable m_drawHeight 0

    ###marker move callback
    private variable m_markCallback ""

    private variable m_ctsSetup0
    private variable m_ctsSetup1

    private variable m_setupOK0 0
    private variable m_setupOK1 0

    private variable m_markId1 ""
    private variable m_markId2 ""

    private variable m_currentV0 -999
    private variable m_currentV1 -999
    private variable m_currentH0 -999
    private variable m_currentH1 -999

    private variable m_markX     -999
    private variable m_markY0    -999
    private variable m_markY1    -999
    private variable m_markMotorV0 ""
    private variable m_markMotorH0 ""
    private variable m_markMotorV1 ""
    private variable m_markMotorH1 ""

    ##### update #######
    private variable m_dynamicUpdate 1

    private variable MARK1COLOR red
    private variable MARK2COLOR green

    ###normalized parameters
    private variable m_offsetH0 0
    private variable m_offsetH1 0
    private variable m_cellSizeH0 0.1
    private variable m_cellSizeH1 0.1
    private common   SPACER_SIZE 4

    private variable m_startZ0
    private variable m_startZ1
    private variable m_endZ0
    private variable m_endZ1

    ### pixel parameters
    private variable m_pixel

    constructor { args } {
        puts "+SimpleDouble2DScanView constructor"

        #create new C++ object
        set m_obj0 [createNewDcsScan2DData]
        set m_obj1 [createNewDcsScan2DData]

        itk_component add s_canvas {
            canvas $itk_interior.canvas
        } {
        }

        pack $itk_component(s_canvas) -expand 1 -fill both
        set m_winID $itk_component(s_canvas)
        bind $m_winID <Configure> "$this handleResize %W %w %h"

        eval itk_initialize $args

        bind $itk_component(s_canvas) <B1-Motion> "$this drawMarker %x %y 1"
        bind $itk_component(s_canvas) <ButtonPress-1> "$this drawMarker %x %y 1"
        bind $itk_component(s_canvas) <ButtonRelease-1> "$this drawMarker %x %y 1"

        bind $itk_component(s_canvas) <ButtonRelease-3> "$this removeMark 1"
        puts "-SimpleDouble2DScanView constructor"
    }
    destructor {
        ##delete the C++ object
        rename $m_obj0 {}
        rename $m_obj1 {}
    }
}

body DCS::SimpleDouble2DScanView::setup0 { setup0 } {
    set m_setupOK0 0

    if {[llength $setup0] >= 9} {
        set m_ctsSetup0 $setup0
        set orig0 [lrange $setup0 0 5]
        set m_numRow0 [lindex $setup0 6]
        set m_numColumn0 [lindex $setup0 7]

        #may have units
        set y0 0
        set y1 [expr 1 - $m_numRow0]
        set x0 0
        set x1 [expr $m_numColumn0 - 1]

        ## this will clear all the data
        $m_obj0 setup $m_numRow0 $y0 -1.0 $m_numColumn0 $x0 1.0

        #########save setup so that we can calculate mark to motor position
        set m_firstRowPos0    $y0
        set m_rowStep0        -1.0
        set m_lastRowPos0     $y1
        set m_firstColumnPos0 $x0
        set m_collumnStep     1.0
        set m_lastColumnPos0  $x1

        set startH0 -0.5
        set endH0   [expr $m_numColumn0 - 0.5]
        set pos \
        [calculateSamplePositionDeltaFromProjection $orig0 0 0 0 0 $startH0]
        set m_startZ0 [lindex $pos 2]

        set pos \
        [calculateSamplePositionDeltaFromProjection $orig0 0 0 0 0 $endH0]
        set m_endZ0 [lindex $pos 2]

        puts "0: $m_startZ0 -- $m_endZ0"
        set m_setupOK0 1
    } else {
        set m_numRow0 0
        set m_numColumn0 0
        set m_firstRowPos0    0
        set m_rowStep0        1.0
        set m_lastRowPos0     1
        set m_firstColumnPos0 0
        set m_columnStep      1.0
        set m_lastColumnPos0  1
        set m_startZ0 ""
        set m_endZ0 ""
    }

    setupCommon
}
body DCS::SimpleDouble2DScanView::setup1 { setup1 } {
    set m_setupOK1 0

    if {[llength $setup1] >= 9} {
        set m_ctsSetup1 $setup1
        set orig1 [lrange $setup1 0 5]
        set m_numRow1 [lindex $setup1 6]
        set m_numColumn1 [lindex $setup1 7]
        set y0 0
        set y1 [expr 1 - $m_numRow1]
        set x0 0
        set x1 [expr $m_numColumn1 - 1]

        ## this will clear all the data
        $m_obj1 setup $m_numRow1 $y0 -1.0 $m_numColumn1 $x0 1.0

        set m_firstRowPos1    $y0
        set m_rowStep1        -1.0
        set m_lastRowPos1     $y1
        set m_firstColumnPos1 $x0
        set m_columnStep      1.0
        set m_lastColumnPos1  $x1

        set startH1 -0.5
        set endH1   [expr $m_numColumn1 - 0.5]
        set pos \
        [calculateSamplePositionDeltaFromProjection $orig1 0 0 0 0 $startH1]
        set m_startZ1 [lindex $pos 2]

        set pos \
        [calculateSamplePositionDeltaFromProjection $orig1 0 0 0 0 $endH1]
        set m_endZ1 [lindex $pos 2]

        puts "1: $m_startZ1 -- $m_endZ1"
        set m_setupOK1 1
    } else {
        set m_numRow1 0
        set m_numColumn1 0
        set m_firstRowPos1    0
        set m_rowStep         1.0
        set m_lastRowPos1     1
        set m_firstColumnPos1 0
        set m_columnStep      1.0
        set m_lastColumnPos1  1
        set m_startZ1 ""
        set m_endZ1 ""
    }
    setupCommon
}
body DCS::SimpleDouble2DScanView::setupCommon { } {
    if {!$m_setupOK0 && !$m_setupOk1} {
        return
    }

    ### find envelop of both setup0 and setup1 in horizontal
    if {$m_setupOK0 && $m_setupOK1} {
        set startZ [expr ($m_startZ0<$m_startZ1)?$m_startZ0:$m_startZ1]
        set endZ   [expr ($m_endZ0>$m_endZ1)?$m_endZ0:$m_endZ1]
    } elseif {$m_setupOK0} {
        set startZ $m_startZ0
        set endZ   $m_endZ0
    } else {
        set startZ $m_startZ1
        set endZ   $m_endZ1
    }

    set totalZ [expr $endZ - $startZ]
    puts "total: $startZ -- $endZ:   $totalZ"

    #### assume the whole image width is 1.0
    if {$m_setupOK0} {
        set ch0 [lindex $m_ctsSetup0 5]
        set m_offsetH0 [expr (double($m_startZ0) - $startZ) / $totalZ]
        set m_cellSizeH0 [expr double($ch0) / $totalZ]
        puts "0: offset: $m_offsetH0 cellSizeH: $m_cellSizeH0"
    }
    if {$m_setupOK1} {
        set ch1 [lindex $m_ctsSetup1 5]
        set m_offsetH1 [expr (double($m_startZ1) - $startZ) / $totalZ]
        set m_cellSizeH1 [expr double($ch1) / $totalZ]
        puts "1: offset: $m_offsetH1 cellSizeH: $m_cellSizeH1"
    }

    updatePixelParameters
    redraw
    ######## enable zoom #########3
    puts "-SimpleDouble2DScanView::setup"
}

body DCS::SimpleDouble2DScanView::addData0 { position value { draw 1 } } {
    puts "+SimpleDouble2DScanView::addData0 $position $value"
    
    if {!$m_setupOK0} {
        log_error need setup first
        return
    }


    set firstValue [lindex $value 0]

    set y [lindex $position 0]
    set x [lindex $position 1]

    set result [$m_obj0 addData $y $x $firstValue]

    if {!$result} {
        puts "SimpleDouble2DScanView::addData failed"
        return
    }

    ### update GUI
    if {!$draw} {
        return
    }

    if {$result == -1} {
        redraw0
    } else {
        puts "no redraw only draw 1 rectangle"
        #$result == 1
        #just draw one rectangle for this data
        #because max min did not change
        #so color of other nodes do not need to change
        set col_row [$m_obj0 toColumnRow $x $y]
        set c [lindex $col_row 0]
        set r [lindex $col_row 1]

        set y1 [expr $r * $m_pixel(nodeHeight)]
        set y2 [expr $y1 + $m_pixel(nodeHeight)]
        set x1 [expr $c * $m_pixel(nodeWidth0) + $m_pixel(offsetH0)]
        set x2 [expr $x1 + $m_pixel(nodeWidth0)]
        set colorValue [$m_obj0 getColor $r $c]
        if {$colorValue < 0} {
            set color red
        } else {
            set color [format "\#%02x%02x%02x" $colorValue $colorValue $colorValue]
        }
        $itk_component(s_canvas) create rectangle $x1 $y1 $x2 $y2 \
        -fill $color \
        -outline $color \
        -tags [list raw_data area0]

        drawCurrentPosition
    }
    puts "-SimpleDouble2DScanView::addData"
}

body DCS::SimpleDouble2DScanView::addData1 { position value { draw 1 } } {
    puts "+SimpleDouble2DScanView::addData1 $position $value"
    
    if {!$m_setupOK1} {
        log_error need setup first
        return
    }


    set firstValue [lindex $value 0]

    set y [lindex $position 0]
    set x [lindex $position 1]

    set result [$m_obj1 addData $y $x $firstValue]

    if {!$result} {
        puts "SimpleDouble2DScanView::addData failed"
        return
    }

    ### update GUI
    if {!$draw} {
        return
    }

    if {$result == -1} {
        redraw1
    } else {
        puts "no redraw only draw 1 rectangle"
        #$result == 1
        #just draw one rectangle for this data
        #because max min did not change
        #so color of other nodes do not need to change
        set col_row [$m_obj1 toColumnRow $x $y]
        set c [lindex $col_row 0]
        set r [lindex $col_row 1]

        set y1 [expr $r * $m_pixel(nodeHeight) + $m_pixel(offsetV1)]
        set y2 [expr $y1 + $m_pixel(nodeHeight)]
        set x1 [expr $c * $m_pixel(nodeWidth1) + $m_pixel(offsetH1)]
        set x2 [expr $x1 + $m_pixel(nodeWidth1)]
        set colorValue [$m_obj1 getColor $r $c]
        if {$colorValue < 0} {
            set color red
        } else {
            set color [format "\#%02x%02x%02x" $colorValue $colorValue $colorValue]
        }
        $itk_component(s_canvas) create rectangle $x1 $y1 $x2 $y2 \
        -fill $color \
        -outline $color \
        -tags [list raw_data area1]

        drawCurrentPosition
    }
    puts "-SimpleDouble2DScanView::addData1"
}

body DCS::SimpleDouble2DScanView::draw0 { } {
    if {!$m_setupOK0} {
        log_error need setup first
        return
    }

    $itk_component(s_canvas) delete area0
    $itk_component(s_canvas) create rectangle \
    $m_pixel(offsetH0) \
    0 \
    [expr $m_pixel(nodeWidth0) * $m_numColumn0 + $m_pixel(offsetH0) - 1] \
    [expr $m_pixel(nodeHeight) * $m_numRow0 - 1] \
    -fill red \
    -tags area0

    for {set r 0} {$r < $m_numRow0} {incr r} {
        set y1 [expr $r * $m_pixel(nodeHeight)]
        set y2 [expr $y1 + $m_pixel(nodeHeight)]
        for {set c 0} {$c < $m_numColumn0} {incr c} {
            set colorValue [$m_obj0 getColor $r $c]
            if {$colorValue < 0} {
                continue
            } else {
                set color [format "\#%02x%02x%02x" \
                $colorValue $colorValue $colorValue]
            }
            set x1 [expr $c * $m_pixel(nodeWidth0) + $m_pixel(offsetH0)]
            set x2 [expr $x1 + $m_pixel(nodeWidth0)]
            set id [$itk_component(s_canvas) \
            create rectangle $x1 $y1 $x2 $y2 \
            -fill $color \
            -outline $color \
            -tags [list raw_data area0] \
            ]
        }
    }
}
body DCS::SimpleDouble2DScanView::draw1 { } {
    if {!$m_setupOK1} {
        log_error need setup first
        return
    }

    $itk_component(s_canvas) delete area1
    $itk_component(s_canvas) create rectangle \
    $m_pixel(offsetH1) \
    $m_pixel(offsetV1) \
    [expr $m_pixel(nodeWidth1) * $m_numColumn1 + $m_pixel(offsetH1) - 1] \
    [expr $m_pixel(nodeHeight) * $m_numRow1    + $m_pixel(offsetV1) - 1] \
    -fill red \
    -tags area1
    for {set r 0} {$r < $m_numRow1} {incr r} {
        set y1 [expr $r * $m_pixel(nodeHeight) + $m_pixel(offsetV1)]
        set y2 [expr $y1 + $m_pixel(nodeHeight)]
        for {set c 0} {$c < $m_numColumn1} {incr c} {
            set colorValue [$m_obj1 getColor $r $c]
            if {$colorValue < 0} {
                continue
            } else {
                set color [format "\#%02x%02x%02x" \
                $colorValue $colorValue $colorValue]
            }
            set x1 [expr $c * $m_pixel(nodeWidth1) + $m_pixel(offsetH1)]
            set x2 [expr $x1 + $m_pixel(nodeWidth1)]
            set id [$itk_component(s_canvas) \
            create rectangle $x1 $y1 $x2 $y2 \
            -fill $color \
            -outline $color \
            -tags [list raw_data area1] \
            ]
        }
    }
}
body DCS::SimpleDouble2DScanView::draw { } {
    puts "+SimpleDouble2DScanView::draw"
    draw0
    draw1
    
    ###################### contour ##########################
    drawContour 1
    drawContour 2
    drawCurrentPosition
    $itk_component(s_canvas) xview moveto 0
    $itk_component(s_canvas) yview moveto 0
    set m_scrollRegion [$itk_component(s_canvas) bbox all]
    $itk_component(s_canvas) configure -scrollregion $m_scrollRegion
}

body DCS::SimpleDouble2DScanView::drawContour { number } {
    
    if {!$m_setupOK0 && !$m_setupOK1} {
        log_error 2D data not ready yet 
        return
    }

    set tag contour$number

    switch -exact -- $number {
    1 { set color red }
    2 { set color blue }
    default { set color black }
    }

    $itk_component(s_canvas) delete $tag

    if {$m_setupOK0} {
        if {[$m_obj0 allDataDefined]} {
            set level $itk_option(-$tag)
            if {[isPositiveInt $level] && $level > 0 && $level < 100} {
                if {[$m_obj0 getContour [expr double($level) / 100.0 ]] > 0} {
                    foreach segment [array names m_contour] {
                        set xyList $m_contour($segment)
                        displacement xyList 0 $m_pixel(offsetH0)
                        $itk_component(s_canvas) create line $xyList \
                        -fill $color \
                        -width 2 \
                        -tags [list contour $tag area0]
                    }
                }
            } else {
                log_warning bad $tag level: $level should be 1-99
            }
        }
    }
    if {$m_setupOK1} {
        if {[$m_obj1 allDataDefined]} {
            set level $itk_option(-$tag)
            if {[isPositiveInt $level] && $level > 0 && $level < 100} {
                if {[$m_obj1 getContour [expr double($level) / 100.0 ]] > 0} {
                    foreach segment [array names m_contour] {
                        set xyList $m_contour($segment)
                        displacement xyList $m_pixel(offsetV1) $m_pixel(offsetH1)
                        $itk_component(s_canvas) create line $xyList \
                        -fill $color \
                        -width 2 \
                        -tags [list contour $tag area1]
                    }
                }
            } else {
                log_warning bad $tag level: $level should be 1-99
            }
        }
    }
}

body DCS::SimpleDouble2DScanView::redraw { } {
    puts "+SimpleDouble2DScanView::redraw"
    $itk_component(s_canvas) delete all
    puts "call draw"

    draw

    puts "-SimpleDouble2DScanView::redraw"
}
body DCS::SimpleDouble2DScanView::redraw0 { } {
    $itk_component(s_canvas) delete area0
    draw0
    drawContour 1
    drawContour 2
    drawCurrentPosition
}
body DCS::SimpleDouble2DScanView::redraw1 { } {
    $itk_component(s_canvas) delete area1
    draw1
    drawContour 1
    drawContour 2
    drawCurrentPosition
}

body DCS::SimpleDouble2DScanView::print { } {
    set filename [file nativename "~/.bluice_print.ps"]
    $itk_component(s_canvas) postscript \
    -file $filename \
    -colormode color \
    -rotate 1

    exec lp $filename
}
body DCS::SimpleDouble2DScanView::getMarkInfo0 { x y } {
    if {$x < 0 || $y < 0} {
        return [list "" "" 0]
    }

    set x_on_data [expr $x - $m_pixel(offsetH0)]
    set y_on_data $y

    set row [expr double($y_on_data) / $m_pixel(nodeHeight) - 0.5]
    set col [expr double($x_on_data) / $m_pixel(nodeWidth0)  - 0.5]

    set y0     [lindex $m_firstRowPos0 0]
    set yStep  [lindex $m_rowStep0 0]
    set x0     [lindex $m_firstColumnPos0 0]
    set xStep  [lindex $m_columnStep0 0]
    set motor1 [expr $y0 + $row * $yStep]
    set motor2 [expr $x0 + $col * $xStep]
    if {[catch {
        set value [$m_obj0 getValue $x_on_data $y_on_data]
    } errMsg]} {
        log_warning value not available yet: $errMsg
        set value 0
    }

    return [list $motor1 $motor2 $value]
}
body DCS::SimpleDouble2DScanView::getMarkInfo1 { x y } {
    if {$x < 0 || $y < 0} {
        return [list "" "" 0]
    }

    set x_on_data [expr $x - $m_pixel(offsetH1)]
    set y_on_data [expr $y - $m_pixel(offsetV1)]

    set row [expr double($y_on_data) / $m_pixel(nodeHeight) - 0.5]
    set col [expr double($x_on_data) / $m_pixel(nodeWidth1)  - 0.5]

    set y0     [lindex $m_firstRowPos1 0]
    set yStep  [lindex $m_rowStep1 0]
    set x0     [lindex $m_firstColumnPos1 0]
    set xStep  [lindex $m_columnStep1 0]
    set motor1 [expr $y0 + $row * $yStep]
    set motor2 [expr $x0 + $col * $xStep]
    if {[catch {
        set value [$m_obj1 getValue $x_on_data $y_on_data]
    } errMsg]} {
        log_warning value not available yet: $errMsg
        set value 0
    }

    return [list $motor1 $motor2 $value]
}

body DCS::SimpleDouble2DScanView::drawMarker0 { x y mark_num } {
    if {!$m_setupOK0} {
        return
    }
    set markInfo0 [getMarkInfo0 $x $y]
    set mark_color $MARK1COLOR
    set text_color $MARK1COLOR

    ##### vert line must be moved.
    set m_markMotorH0 [lindex $markInfo0 1]
    $itk_component(s_canvas) create line \
    $x $m_pixel(rec0_y1) $x $m_pixel(rec0_y2) \
    -tags [list mark mark$mark_num mcursor$mark_num area0] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3

    ##### horz line may keep the old value if y is not in limits.
    if {$y >= $m_pixel(rec0_y1) && $y <= $m_pixel(rec0_y2)} {
        set m_markMotorV0 [lindex $markInfo0 0]
    } else {
        set y [lindex [getXYFromPosition0 $m_markMotorV0 $m_markMotorH0] 1]
    }
    $itk_component(s_canvas) create line \
    $m_pixel(rec0_x1) $y $m_pixel(rec0_x2) $y \
    -tags [list mark mark$mark_num mcursor$mark_num area0] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3
}
body DCS::SimpleDouble2DScanView::drawMarker1 { x y mark_num } {
    if {!$m_setupOK1} {
        return
    }
    set markInfo1 [getMarkInfo1 $x $y]
    set mark_color $MARK1COLOR
    set text_color $MARK1COLOR

    ##### vert line must be moved.
    set m_markMotorH1 [lindex $markInfo1 1]
    $itk_component(s_canvas) create line \
    $x $m_pixel(rec1_y1) $x $m_pixel(rec1_y2) \
    -tags [list mark mark$mark_num mcursor$mark_num area1] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3

    ##### horz line may keep the old value if y is not in limits.
    if {$y >= $m_pixel(rec1_y1) && $y <= $m_pixel(rec1_y2)} {
        set m_markMotorV1 [lindex $markInfo1 0]
    } else {
        set y [lindex [getXYFromPosition1 $m_markMotorV1 $m_markMotorH1] 1]
    }
    $itk_component(s_canvas) create line \
    $m_pixel(rec1_x1) $y $m_pixel(rec1_x2) $y \
    -tags [list mark mark$mark_num mcursor$mark_num area1] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3
}
body DCS::SimpleDouble2DScanView::drawMarker { x y mark_num } {
    if {!$m_setupOK0 && !$m_setupOK1} {
        return
    }

    $itk_component(s_canvas) delete mark$mark_num
    set x [$itk_component(s_canvas) canvasx $x]
    set y [$itk_component(s_canvas) canvasy $y]
    drawMarker0 $x $y $mark_num
    drawMarker1 $x $y $mark_num

    if {$mark_num != 1} {
        return
    }

    if {$m_markCallback != ""} {
        set command $m_markCallback

        if {$m_setupOK0} {
            set v0 $m_markMotorV0
            set h0 $m_markMotorH0
        } else {
            set v0 ""
            set h0 ""
        }
        if {$m_setupOK1} {
            set v1 $m_markMotorV1
            set h1 $m_markMotorH1
        } else {
            set v1 ""
            set h1 ""
        }

        lappend command $v0 $h0 $v1 $h1
        eval $command
    }
    return
}

body DCS::SimpleDouble2DScanView::clear0 { } {
    set m_setupOK0 0
    $itk_component(s_canvas) delete area0

    removeMark 1
    removeMark 2
}
body DCS::SimpleDouble2DScanView::clear1 { } {
    #set m_markCallback ""
    set m_setupOK1 0
    $itk_component(s_canvas) delete area1

    removeMark 1
    removeMark 2
}


body DCS::SimpleDouble2DScanView::allDataDone0 { } {
    if {![$m_obj0 allDataDefined]} {
        $m_obj0 setAllData
    }
    drawContour 1
    drawContour 2
}

body DCS::SimpleDouble2DScanView::allDataDone1 { } {
    if {![$m_obj1 allDataDefined]} {
        $m_obj1 setAllData
    }
    drawContour 1
    drawContour 2
}

body DCS::SimpleDouble2DScanView::removeMark { mark_num } {
    #this will remove both mark and its plots
    $itk_component(s_canvas) delete mark$mark_num

    set m_markId$mark_num ""

    set m_markX  -999
    set m_markY0 -999
    set m_markY1 -999
    set m_markMotorV0 ""
    set m_markMotorV1 ""
    set m_markMotorH0 ""
    set m_markMotorH1 ""
}
body DCS::SimpleDouble2DScanView::setCurrentPosition { v0 h0 v1 h1 } {
    set m_currentV0 $v0
    set m_currentH0 $h0
    set m_currentV1 $v1
    set m_currentH1 $h1
    
    drawCurrentPosition
}
body DCS::SimpleDouble2DScanView::updatePixelParameters { } {
    if {!$m_setupOK0 && !$m_setupOK1} {
        return
    }

    set m_pixel(nodeHeight) \
    [expr ($m_drawHeight - $SPACER_SIZE) / ($m_numRow0 + $m_numRow1)]

    if {$m_setupOK0} {
        set m_pixel(offsetH0)    [expr $m_drawWidth * $m_offsetH0]
        set m_pixel(nodeWidth0)  [expr $m_drawWidth * $m_cellSizeH0]
        set m_pixel(rec0_x1)     $m_pixel(offsetH0)

        set m_pixel(rec0_x2) \
        [expr $m_pixel(nodeWidth0) * $m_numColumn0 + $m_pixel(offsetH0) - 1]

        set m_pixel(rec0_y1)     0

        set m_pixel(rec0_y2)     [expr $m_pixel(nodeHeight) * $m_numRow0]

        $m_obj0 setNodeSize $m_pixel(nodeWidth0) $m_pixel(nodeHeight)
    }
    if {$m_setupOK1} {
        set m_pixel(offsetH1)    [expr $m_drawWidth * $m_offsetH1]
        set m_pixel(nodeWidth1)  [expr $m_drawWidth * $m_cellSizeH1]

        set m_pixel(offsetV1) \
        [expr $m_pixel(nodeHeight) * $m_numRow0 + $SPACER_SIZE]

        set m_pixel(rec1_x1) $m_pixel(offsetH1)

        set m_pixel(rec1_x2) \
        [expr $m_pixel(nodeWidth1) * $m_numColumn1 + $m_pixel(offsetH1) - 1]

        set m_pixel(rec1_y1) $m_pixel(offsetV1)

        set m_pixel(rec1_y2) [expr $m_drawHeight - 1]

        $m_obj1 setNodeSize $m_pixel(nodeWidth1) $m_pixel(nodeHeight)
    }
}
body DCS::SimpleDouble2DScanView::drawCurrentPosition { } {
    $itk_component(s_canvas) delete mcursor2

    drawCurrentPosition0
    drawCurrentPosition1
}
body DCS::SimpleDouble2DScanView::getXYFromPosition0 { v h } {
    if {$v == "" || $h == ""} {
        return [list -999 -999]
    }

    set y0    [lindex $m_firstRowPos0 0]
    set yStep [lindex $m_rowStep0 0]
    set x0    [lindex $m_firstColumnPos0 0]
    set xStep [lindex $m_columnStep0 0]

    set row [expr (double($v) - $y0) / $yStep]
    set col [expr (double($h) - $x0) / $xStep]

    set y [expr ($row + 0.5) * $m_pixel(nodeHeight)]
    set x [expr ($col + 0.5) * $m_pixel(nodeWidth0) + $m_pixel(offsetH0)]

    return [list $x $y]
}
body DCS::SimpleDouble2DScanView::getXYFromPosition1 { v h } {
    if {$v == "" || $h == ""} {
        return [list -999 -999]
    }

    set y0    [lindex $m_firstRowPos1 0]
    set yStep [lindex $m_rowStep1 0]
    set x0    [lindex $m_firstColumnPos1 0]
    set xStep [lindex $m_columnStep1 0]

    set row [expr (double($v) - $y0) / $yStep]
    set col [expr (double($h) - $x0) / $xStep]

    set y [expr ($row + 0.5) * $m_pixel(nodeHeight) + $m_pixel(offsetV1)]
    set x [expr ($col + 0.5) * $m_pixel(nodeWidth1) + $m_pixel(offsetH1)]

    return [list $x $y]
}
body DCS::SimpleDouble2DScanView::drawCurrentPosition0 { } {
    if {!$m_setupOK0} {
        return
    }
    set mark_num 2

    foreach {x y} [getXYFromPosition0 $m_currentV0 $m_currentH0] break

    set x1 $m_pixel(rec0_x1)
    set y1 $m_pixel(rec0_y1)
    set x2 $m_pixel(rec0_x2)
    set y2 $m_pixel(rec0_y2)

    set v_line_width 1
    set h_line_width 1
    if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
        if {$x < $x1} {
            set v_line_width 3
            set x $x1
        }
        if {$x > $x2} {
            set v_line_width 3
            set x $x2
        }
        if {$y < $y1} {
            set h_line_width 3
            set y $y1
        }
        if {$y > $y2} {
            set h_line_width 3
            set y $y2
        }
    }

    set mark_color $MARK1COLOR
    set text_color $MARK1COLOR
    if {$mark_num != 1} {
        set mark_color $MARK2COLOR
    }

    $itk_component(s_canvas) create line $x1 $y $x2 $y \
    -tags [list mark mark$mark_num mcursor$mark_num area0] \
    -dash {5 5} \
    -fill $mark_color \
    -width $h_line_width
    $itk_component(s_canvas) create line $x $y1 $x $y2 \
    -tags [list mark mark$mark_num mcursor$mark_num area0] \
    -dash {5 5} \
    -fill $mark_color \
    -width $v_line_width
}
body DCS::SimpleDouble2DScanView::drawCurrentPosition1 { } {
    if {!$m_setupOK1} {
        return
    }
    set mark_num 2

    foreach {x y} [getXYFromPosition1 $m_currentV1 $m_currentH1] break

    set x1 $m_pixel(rec1_x1)
    set y1 $m_pixel(rec1_y1)
    set x2 $m_pixel(rec1_x2)
    set y2 $m_pixel(rec1_y2)

    set v_line_width 1
    set h_line_width 1
    if {$x < $x1 || $x > $x2 || $y < $y1 || $y > $y2} {
        if {$x < $x1} {
            set v_line_width 3
            set x $x1
        }
        if {$x > $x2} {
            set v_line_width 3
            set x $x2
        }
        if {$y < $y1} {
            set h_line_width 3
            set y $y1
        }
        if {$y > $y2} {
            set h_line_width 3
            set y $y2
        }
    }

    set mark_color $MARK2COLOR

    $itk_component(s_canvas) create line $x1 $y $x2 $y \
    -tags [list mark mark$mark_num mcursor$mark_num area1] \
    -dash {5 5} \
    -fill $mark_color \
    -width $h_line_width
    $itk_component(s_canvas) create line $x $y1 $x $y2 \
    -tags [list mark mark$mark_num mcursor$mark_num area1] \
    -dash {5 5} \
    -fill $mark_color \
    -width $v_line_width
}


class DCS::Floating2DScanView {
    inherit ::itk::Widget

    #### for debug purpose to always display the current position cross
    itk_option define -debugShowCross debugShowCross DebugShowCross 0

    itk_option define -contour contour Contour {10 25 50 75 90} { drawContour }
    itk_option define -ridge ridge Ridge "" { drawRidge }
    itk_option define -grid grid Grid 1 { redraw }
    itk_option define -showMarkerValue showMarkerValue ShowMarkerValue 1

    #### both cross_only rectangle_only none
    itk_option define -markerStyle markerStyle MarkerStyle cross_only {
        drawCurrentPosition
    }

    ### must define method toMatrix toDisplay
    ### toMatrix { vListList index }
    ### toDisokay { vlistLIst index }
    itk_option define -valueConverter valueConverter ValueConverter ""

    itk_option define -subField subField SubField 0 {
        if {$m_setupOK} {
            refillData
        }
    }
    #following are only used with subField, no need to redraw
    itk_option define -showContour showContour ShowContour 1 {
        #drawContour
    }
    itk_option define -showRidge showRidge ShowRidge 1 {
        #drawRidge
    }
    itk_option define -showValue showValue ShowValue 1 {
        #redraw
    }


    public method clear { }
    public method setup 
    public method reposition

    public method addData { position value {draw 1} }

    public method setValues { valueList {draw 1} }

    public method allDataDone { }

    public method draw { }
    public method redraw { }
    public method refillData { }

    public method drawContour { }
    public method drawRidge { }

    public method registerMarkMoveCallback { method_to_call } { 
        set m_markCallback $method_to_call
    }

    ##########MARK##########
    ### click will not draw the mark, 
    ### just call back the marker callback if in the area
    public method click { x y }
    public method drawMarker { x y mark_num }
    public method removeMark { mark_num }

    ### similar to click
    public method getRowCol { x y }

    public method setCurrentPosition { v h }
    public method setBoxSize { h w {draw 1}}
    private method drawCurrentPosition { }

    private proc displacement { segRef offsetV offsetH } {
        upvar $segRef xyList

        set old $xyList
        set result ""
        foreach {x y} $xyList {
            set x [expr $x + $offsetH]
            set y [expr $y + $offsetV]
            lappend result $x $y
        }
        set xyList $result
    }

    private proc getColorFromLevel { level } {
        if {$level >= 50} {
            set grayScale [expr int(510 - $level * 255 / 50)]
            set color [format "#%02x0000" $grayScale]
        } elseif {$level <= 20} {
            set color yellow
        } else {
            set color green
        }
        return $color
    }

    private method getMarkInfo { x y }
    private method getXYFromPosition { v h }
    private method getWHFromWidthHeight { w h }

    private variable m_threshold -1

    private variable m_readyToDraw 0

    private variable m_numRow 2
    private variable m_firstRowPos {0 mm}
    private variable m_rowStep  {1 mm}
    private variable m_numColumn 2
    private variable m_firstColumnPos {0 mm}
    private variable m_columnStep {1 mm}
    private variable m_obj

    private variable m_contour
    private variable m_ridge

    ###marker move callback
    private variable m_markCallback ""

    private variable m_ctsSetup

    private variable m_setupOK 0

    private variable m_markId1 ""
    private variable m_markId2 ""

    #### beam position
    private variable m_currentV -999
    private variable m_currentH -999

    #### beam size
    private variable m_boxWidth 0
    private variable m_boxHeight 0

    private variable m_markMotorV ""
    private variable m_markMotorH ""

    ##### update #######
    private variable m_dynamicUpdate 1

    ### pixel parameters
    private variable m_drawWidth 0
    private variable m_drawHeight 0
    private variable m_rec_x1   0
    private variable m_rec_x2   1
    private variable m_rec_y1   0
    private variable m_rec_y2   1
    private variable m_offsetH  0
    private variable m_offsetV  0
    private variable m_nodeWidth    1
    private variable m_nodeHeight   1

    private variable m_canvas
    private variable m_myTag

    # "0", "1 exposing" "1 done" ..... "25 done"
    private variable m_progressStatus -1
    private variable m_topoMatrixValueList ""
    private variable m_displayValueList ""
    private variable m_infoList ""


	private common uniqueNameCounter 0

    private common MARK1COLOR red
    private common MARK2COLOR white

    private common COLOR_NA         #7382B9 
    #private common COLOR_EXPOSING   #c04080
    private common COLOR_EXPOSING   green
    private common COLOR_DONE       green
    private common COLOR_GRID       yellow
    private common COLOR_VALUE      brown
    private common COLOR_UNSELECT   red

    constructor { canvas args } {
        puts "+Floating2DScanView constructor"

        #set COLOR_UNSELECT [$canvas cget -background]
        puts "set COLOR_UNSELECT $COLOR_UNSELECT"

        set m_canvas $canvas
        set m_myTag area$uniqueNameCounter
        incr uniqueNameCounter

        #create new C++ object
        set m_obj [createNewDcsScan2DData]

        eval itk_initialize $args

        puts "-Floating2DScanView constructor"
    }
    destructor {
        ##delete the C++ object
        rename $m_obj {}
    }
}

body DCS::Floating2DScanView::setup { setup } {

    set m_setupOK 0
    set m_readyToDraw 0
    if {[llength $setup] < 9} {
        return 0
    }

    set m_ctsSetup $setup
    set orig [lrange $setup 0 5]
    set m_numRow [lindex $setup 6]
    set m_numColumn [lindex $setup 7]
    set m_threshold [lindex $setup 10]
    if {![string is double -strict $m_threshold]} {
        set m_threshold -1
    }
    ## TESTING no threshold
    #set m_threshold -1

    set www [expr $m_numColumn - 1]
    set hhh [expr $m_numRow    - 1]

    set y0     [expr -0.5 * $hhh]
    set yStep  1.0
    set x0     [expr -0.5 * $www]
    set xStep  1.0

    ## this will clear all the data
    $m_obj setup $m_numRow $y0 $yStep $m_numColumn $x0 $xStep

    #########save setup so that we can calculate mark to motor position
    set m_firstRowPos    $y0
    set m_rowStep        $yStep
    set m_firstColumnPos $x0
    set m_columnStep     $xStep

    set m_setupOK 1
    return 1
}
body DCS::Floating2DScanView::reposition { \
offsetV offsetH nodeHeight nodeWidth } {
    set m_offsetV    $offsetV
    set m_offsetH    $offsetH
    set m_nodeHeight $nodeHeight
    set m_nodeWidth  $nodeWidth

    set m_rec_x1     $m_offsetH
    set m_rec_x2     [expr $m_rec_x1 + $m_numColumn * $m_nodeWidth  - 1]
    set m_rec_y1     $m_offsetV
    set m_rec_y2     [expr $m_rec_y1 + $m_numRow    * $m_nodeHeight - 1]

    $m_obj setNodeSize $m_nodeWidth $m_nodeHeight

    redraw
}

body DCS::Floating2DScanView::setValues { info {draw 1} } {
    set m_readyToDraw 0
    if {!$m_setupOK} {
        log_error setValues need setup first
        return
    }
    set m_progressStatus    [lindex $info 0]
    switch -exact -- $m_progressStatus {
        paused -
        skipped -
        aborted -
        failed -
        stopped -
        done {
            set m_readyToDraw 1
        }
        default {
            #puts "not ready: $m_progressStatus"
        }
    }

    set m_infoList [lrange $info 1 end]
    #puts "$this header={$m_progressStatus} vList: $m_infoList"
    refillData
}

body DCS::Floating2DScanView::refillData { } {
    set iSub $itk_option(-subField)

    if {$itk_option(-valueConverter) == ""} {
        set m_topoMatrixValueList ""
        set m_displayValueList ""
        foreach info $m_infoList {
            set ll [llength $info]
            if {$iSub < $ll} {
                set v [lindex $info $iSub]
            } else {
                set v [lindex $info 0]
            }
            lappend m_topoMatrixValueList $v
            lappend m_displayValueList $v
        }
    } else {
        set m_topoMatrixValueList [$itk_option(-valueConverter) toMatrix  $m_infoList $iSub]
        set m_displayValueList    [$itk_option(-valueConverter) toDisplay $m_infoList $iSub]
    }

    #puts "$this valueList: $m_topoMatrixValueList"

    if {[catch {
        $m_obj setValues $m_topoMatrixValueList
    } result]} {
        log_error setValues failed: $result
    } else {
        if {!$result} {
            puts "Floating2DScanView::setValues failed"
            return
        }
    }
    redraw
}
body DCS::Floating2DScanView::addData { position value { draw 1 } } {
    puts "+Floating2DScanView::addData $position $value"
    
    if {!$m_setupOK} {
        log_error addData need setup first
        return
    }


    set firstValue [lindex $value 0]

    set y [lindex $position 0]
    set x [lindex $position 1]

    set result [$m_obj addData $y $x $firstValue]

    if {!$result} {
        puts "Floating2DScanView::addData failed"
        return
    }

    ### update GUI
    if {!$draw} {
        return
    }

    if {$result == -1} {
        redraw
    } else {
        puts "no redraw only draw 1 rectangle"
        #$result == 1
        #just draw one rectangle for this data
        #because max min did not change
        #so color of other nodes do not need to change
        set col_row [$m_obj toColumnRow $x $y]
        set c [lindex $col_row 0]
        set r [lindex $col_row 1]

        set y1 [expr $r * $m_nodeHeight + $m_offsetV]
        set y2 [expr $y1 + $m_nodeHeight]
        set x1 [expr $c * $m_nodeWidth + $m_offsetH]
        set x2 [expr $x1 + $m_nodeWidth]
        set colorValue [$m_obj getColor $r $c]
        if {$colorValue < 0} {
            set color red
        } else {
            set color [format "\#%02x%02x%02x" $colorValue $colorValue $colorValue]
        }
        $m_canvas create rectangle $x1 $y1 $x2 $y2 \
        -fill $color \
        -outline $color \
        -tags [list raw_data $m_myTag]

        drawCurrentPosition
    }
    puts "-Floating2DScanView::addData"
}

body DCS::Floating2DScanView::draw { } {
    if {!$m_setupOK} {
        #log_error draw need setup first
        return
    }

    $m_canvas delete $m_myTag

    if {$m_nodeWidth < 0 || $m_nodeHeight < 0} {
        return
    }

    set font_sizeH [expr int(0.33 * $m_nodeHeight)]
    set font_sizeW [expr int(0.33 * $m_nodeWidth)]
    if {$font_sizeH > $font_sizeW} {
        set font_size $font_sizeW
    } else {
        set font_size $font_sizeH
    }

    for {set r 0} {$r < $m_numRow} {incr r} {
        set y1 [expr $r * $m_nodeHeight + $m_offsetV]
        set y2 [expr $y1 + $m_nodeHeight]
        for {set c 0} {$c < $m_numColumn} {incr c} {
            set cellIndex [expr $r * $m_numColumn + $c]
            set cellState [lindex $m_topoMatrixValueList $cellIndex]
            set cellDisplayValue [lindex $m_displayValueList $cellIndex]
            set colorValue [$m_obj getColor $r $c]
            set stipple ""
            if {$colorValue < 0} {
                switch -exact -- $cellState {
                    NEW -
                    N -
                    NA {
                        ### unselected, show grey
                        set color $COLOR_UNSELECT
                        set stipple gray50
                    }
                    S {
                        ### selected, so show the background iamge
                        continue
                    }
                    X {
                        if {$m_readyToDraw} {
                            continue
                        }
                        set color $COLOR_EXPOSING
                    }
                    D {
                        if {$m_readyToDraw} {
                            continue
                        }
                        set color $COLOR_DONE
                    }
                    L {
                        ### value out of limits
                        ### normally a tag of failure
                        set color black
                    }
                    default {
                        set color darkred

                    }
                }
            } else {
                set color [format "\#%02x%02x%02x" \
                $colorValue $colorValue $colorValue]
            }
            set x1 [expr $c * $m_nodeWidth + $m_offsetH]
            set x2 [expr $x1 + $m_nodeWidth]
            set id [$m_canvas \
            create rectangle $x1 $y1 $x2 $y2 \
            -fill $color \
            -outline "" \
            -tags [list raw_data $m_myTag] \
            -stipple $stipple \
            ]

            if {$itk_option(-showValue) \
            && $colorValue >= 0} {
                set tx [expr ($x1 + $x2) / 2.0]
                set ty [expr ($y1 + $y2) / 2.0]
                $m_canvas \
                create text $tx $ty \
                -text $cellDisplayValue \
                -fill $COLOR_VALUE \
                -font "-family courier -size $font_size" \
                -anchor c \
                -justify center \
                -tags $m_myTag
            }
        }
    }

    #####################grid###################
    if {$itk_option(-grid)} {
        set normal_options [list -fill $COLOR_GRID -tags $m_myTag]
        for {set i 0} {$i <= $m_numRow} {incr i} {
            set options $normal_options
            if {$i != 0 && $i != $m_numRow} {
                lappend options -dash .
            } else {
                lappend options -width 2
            }

            eval $m_canvas create line \
            $m_offsetH \
            [expr $m_nodeHeight * $i + $m_offsetV - 1] \
            [expr $m_nodeWidth  * $m_numColumn + $m_offsetH - 1] \
            [expr $m_nodeHeight * $i + $m_offsetV - 1] \
            $options
        }
        for {set i 0} {$i <= $m_numColumn} {incr i} {
            set options $normal_options
            if {$i != 0 && $i != $m_numColumn} {
                lappend options -dash .
            } else {
                lappend options -width 2
            }

            eval $m_canvas create line \
            [expr $m_nodeWidth  * $i+ $m_offsetH - 1] \
            $m_offsetV \
            [expr $m_nodeWidth  * $i+ $m_offsetH - 1] \
            [expr $m_nodeHeight * $m_numRow + $m_offsetV - 1] \
            $options
        }
    }

    drawContour
    drawRidge
    drawCurrentPosition
}

body DCS::Floating2DScanView::drawContour { } {
    set tag ${m_myTag}contour
    $m_canvas delete $tag

    if {!$itk_option(-showContour)} {
        return
    }

    if {!$m_setupOK} {
        #log_error 2D data not ready yet 
        return
    }
    if {!$m_readyToDraw} {
        #puts "$this not ready to draw progress= {$m_progressStatus}"
        return
    }
    if {![$m_obj allDataDefined]} {
        $m_obj setAllData
    }

    set levelList $itk_option(-contour)
    if {$levelList == ""} {
        puts "no level defined"
        return
    }

    if {$itk_option(-subField) == 0} {
        foreach {min max} [$m_obj getMinMax] break
        if {$max < $m_threshold} {
            puts "skip contour, data not pass threshold"
            return
        }
    }

    foreach level $levelList {
        set color [getColorFromLevel $level]
        if {[$m_obj getContour [expr double($level) / 100.0 ]] > 0} {
            foreach segment [array names m_contour] {
                set xyList $m_contour($segment)
                displacement xyList $m_offsetV $m_offsetH
                $m_canvas create line $xyList \
                -fill $color \
                -width 2 \
                -tags [list contour $tag $m_myTag]
            }
        }
    }
}

body DCS::Floating2DScanView::drawRidge { } {
    set tag ${m_myTag}ridge
    $m_canvas delete $tag

    if {!$itk_option(-showRidge)} {
        return
    }
    if {[llength $itk_option(-ridge)] < 3} {
        puts "no ridge setup yet"
        return
    }
    foreach {ridgeLevel beamWidth beamSpace} $itk_option(-ridge) break
    #puts "drawRidge: { $ridgeLevel $beamWidth $beamSpace}"

    if {![string is double -strict $ridgeLevel] \
    ||  ![string is double -strict $beamWidth] \
    ||  ![string is double -strict $beamSpace]} {
        puts "wrong option ridge=$itk_option(-ridge)"
        return
    }


    if {!$m_setupOK} {
        #log_error 2D data not ready yet 
        return
    }
    if {!$m_readyToDraw} {
        #puts "$this not ready to draw progress= {$m_progressStatus}"
        return
    }

    set cellWidthMM [lindex $m_ctsSetup 5]
    set cellWidthMM [expr abs($cellWidthMM)]

    set ridgeLevel [expr $ridgeLevel / 100.0]
    set beamWidth  [expr double($beamWidth) / $cellWidthMM]
    set beamSpace  [expr double($beamSpace) / $cellWidthMM]

    if {![$m_obj allDataDefined]} {
        $m_obj setAllData
    }

    if {$itk_option(-subField) == 0} {
        foreach {min max} [$m_obj getMinMax] break
        if {$max < $m_threshold} {
            puts "skip ridge, data not pass threshold $m_threshold"
            return
        }
    }

    if {[catch {
        if {[$m_obj getRidge $ridgeLevel $beamWidth $beamSpace] > 0} {
            set RIDGE_SIZE 10
            foreach ridge [array names m_ridge] {
                set xyList $m_ridge($ridge)
                displacement xyList $m_offsetV $m_offsetH
                #puts "for RIDGE: $ridge: list: $xyList"
                #only draw line if there are more than 1 data point.
                # that means more than 3 total points
                if {[llength $xyList] > 6} {
                    $m_canvas create line $xyList \
                    -fill purple \
                    -width 4 \
                    -tags [list ridge $tag $m_myTag]
                }
                if {[llength $xyList] < 6} {
                    continue
                }
                set pointList [lrange $xyList 2 end-2]
                foreach {x y} $pointList {
                    $m_canvas create line \
                    $x [expr $y - $RIDGE_SIZE] $x [expr $y + $RIDGE_SIZE] \
                    -fill purple \
                    -width 4 \
                    -tags [list ridge $tag $m_myTag]
                }
                if {[llength $pointList] == 2} {
                    $m_canvas create line \
                    [expr $x - $RIDGE_SIZE] $y [expr $x + $RIDGE_SIZE] $y \
                    -fill purple \
                    -width 4 \
                    -tags [list ridge $tag $m_myTag]
                }
            }
        }
    } errMsg]} {
        puts "drawRidge failed: $errMsg"
    }
}

body DCS::Floating2DScanView::redraw { } {
    $m_canvas delete $m_myTag
    draw
}
body DCS::Floating2DScanView::getMarkInfo { x y } {
    if {$x < 0 || $y < 0} {
        return [list "" "" 0]
    }

    set x_on_data [expr $x - $m_offsetH]
    set y_on_data [expr $y - $m_offsetV]

    set row [expr double($y_on_data) / $m_nodeHeight - 0.5]
    set col [expr double($x_on_data) / $m_nodeWidth  - 0.5]

    set y0    [lindex $m_firstRowPos 0]
    set yStep [lindex $m_rowStep 0]
    set x0    [lindex $m_firstColumnPos 0]
    set xStep [lindex $m_columnStep 0]
    set motor1 [expr $y0 + $row * $yStep]
    set motor2 [expr $x0 + $col * $xStep]
    if {[catch {
        set value [$m_obj getValue $x_on_data $y_on_data]
    } errMsg]} {
        log_warning value not available yet: $errMsg
        set value 0
    }

    return [list $motor1 $motor2 $value]
}

body DCS::Floating2DScanView::drawMarker { x y mark_num } {
    if {!$m_setupOK} {
        return
    }

    set tag ${m_myTag}mark$mark_num

    $m_canvas delete $tag
    set x [$m_canvas canvasx $x]
    set y [$m_canvas canvasy $y]

    set markInfo [getMarkInfo $x $y]
    set mark_color $MARK1COLOR
    set text_color $MARK1COLOR

    ##### vert line must be moved.
    set m_markMotorH [lindex $markInfo 1]
    $m_canvas create line \
    $x $m_rec_y1 $x $m_rec_y2 \
    -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3

    ##### horz line may keep the old value if y is not in limits.
    if {$y >= $m_rec_y1 && $y <= $m_rec_y2} {
        set m_markMotorV [lindex $markInfo 0]
    } else {
        set y [lindex [getXYFromPosition $m_markMotorV $m_markMotorH] 1]
    }
    $m_canvas create line \
    $m_rec_x1 $y $m_rec_x2 $y \
    -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
    -dash {5 5} \
    -fill $mark_color \
    -width 3

    if {$itk_option(-showMarkerValue)} {
        ### here y maybe old y not the one from click
        set markInfo [getMarkInfo $x $y]
        set value [lindex $markInfo 2]

        if { int($value) != $value } {
            set value [format "%9.6f" $value]
        } else {
            set value [format "%5.0f" $value]
        }

        ### where to display the text
        set centerX [expr ($m_rec_x1 + $m_rec_x2) / 2.0]
        set centerY [expr ($m_rec_y1 + $m_rec_y2) / 2.0]
        if {$x < $centerX} {
            set text_x [expr $x + 2]
            if {$y < $centerY} {
                set text_y [expr $y + 2]
                set ar nw
            } else {
                set text_y [expr $y - 2]
                set ar sw
            }
        } else {
            set text_x [expr $x - 2]
            if {$y < $centerY} {
                set text_y [expr $y + 2]
                set ar ne
            } else {
                set text_y [expr $y - 2]
                set ar se
            }
        }

        ###update text marker
        set text_id [$m_canvas create text $text_x $text_y \
        -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
        -fill $text_color \
        -anchor $ar \
        -justify center \
        -text $value]

        set text_box [$m_canvas bbox $text_id]
        $m_canvas create rectangle $text_box \
        -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
        -outline white \
        -fill white
        $m_canvas raise $text_id
    }

    if {$mark_num != 1} {
        return
    }

    if {$m_markCallback != ""} {
        set command $m_markCallback

        if {$m_setupOK} {
            set v $m_markMotorV
            set h $m_markMotorH
        } else {
            set v ""
            set h ""
        }
        lappend command $v $h
        eval $command
    }
    return
}

body DCS::Floating2DScanView::click { x y } {
    if {!$m_setupOK} {
        return
    }

    ### in the area?
    set x [$m_canvas canvasx $x]
    set y [$m_canvas canvasy $y]
    if {$x < $m_rec_x1 || $x > $m_rec_x2 \
    ||  $y < $m_rec_y1 || $y > $m_rec_y2 \
    } {
        return
    }

    set markInfo [getMarkInfo $x $y]

    if {$m_markCallback != ""} {
        set command $m_markCallback
        set v [lindex $markInfo 0]
        set h [lindex $markInfo 1]
        lappend command $v $h
        eval $command
    }
}

body DCS::Floating2DScanView::getRowCol { x y } {
    if {!$m_setupOK} {
        return ""
    }

    ### in the area?
    set x [$m_canvas canvasx $x]
    set y [$m_canvas canvasy $y]
    if {$x < $m_rec_x1 || $x > $m_rec_x2 \
    ||  $y < $m_rec_y1 || $y > $m_rec_y2 \
    } {
        return ""
    }

    set markInfo [getMarkInfo $x $y]
    set v [lindex $markInfo 0]
    set h [lindex $markInfo 1]

    return [list $v $h]
}

body DCS::Floating2DScanView::clear { } {
    puts "DEBUG clear: $this"
    set m_setupOK 0
    $m_canvas delete $m_myTag

    set m_readyToDraw 0

    removeMark 1
    removeMark 2
}
body DCS::Floating2DScanView::allDataDone { } {
    if {![$m_obj allDataDefined]} {
        $m_obj setAllData
    }
    drawContour
    drawRidge
}

body DCS::Floating2DScanView::removeMark { mark_num } {
    #this will remove both mark and its plots
    $m_canvas delete mark$mark_num

    set m_markId$mark_num ""

    set m_markMotorV ""
    set m_markMotorH ""
}
body DCS::Floating2DScanView::setCurrentPosition { v h } {
    set m_currentV $v
    set m_currentH $h
    
    drawCurrentPosition
}
body DCS::Floating2DScanView::setBoxSize { h w {draw 1}} {
    set m_boxHeight $h
    set m_boxWidth $w
    
    if {$draw} {
        drawCurrentPosition
    }
}
body DCS::Floating2DScanView::getWHFromWidthHeight { w h } {
    if {$w == "" || $h == ""} {
        return [list 0 0]
    }
    set xStep [lindex $m_columnStep 0]
    set yStep [lindex $m_rowStep 0]
    set ww [expr $w * $m_nodeWidth / $xStep]
    set hh [expr $h * $m_nodeHeight / $yStep]
    return [list $ww $hh]
}
body DCS::Floating2DScanView::getXYFromPosition { v h } {
    if {$v == "" || $h == ""} {
        return [list -999 -999]
    }

    set y0    [lindex $m_firstRowPos 0]
    set yStep [lindex $m_rowStep 0]
    set x0    [lindex $m_firstColumnPos 0]
    set xStep [lindex $m_columnStep 0]

    set row [expr ($v - $y0) / $yStep]
    set col [expr ($h - $x0) / $xStep]
    set x [expr ($col + 0.5) * $m_nodeWidth  + $m_offsetH]
    set y [expr ($row + 0.5) * $m_nodeHeight + $m_offsetV]

    return [list $x $y]
}
body DCS::Floating2DScanView::drawCurrentPosition { } {
    set tag ${m_myTag}current

    $m_canvas delete $tag
    if {$itk_option(-markerStyle) == "none" \
    && !$itk_option(-debugShowCross)} {
        return
    }

    if {!$m_setupOK} {
        return
    }
    if {!$m_readyToDraw \
    && !$itk_option(-debugShowCross)} {
        #puts "$this not ready to draw progress= {$m_progressStatus}"
        return
    }

    if {$itk_option(-subField) == 0} {
        foreach {min max} [$m_obj getMinMax] break
        if {$max < $m_threshold} {
            return
        }
    }

    set mark_num 2

    foreach {x y} [getXYFromPosition $m_currentV $m_currentH] break
    foreach {w h} [getWHFromWidthHeight $m_boxWidth $m_boxHeight] break

    set outOfBoundary 0
    if {$x < $m_rec_x1} {
        set x $m_rec_x1
        set outOfBoundary 1
    }
    if {$x >= $m_rec_x2} {
        set x [expr $m_rec_x2 - 1]
        set outOfBoundary 1
    }
    if {$y < $m_rec_y1} {
        set y $m_rec_y1
        set outOfBoundary 1
    }
    if {$y >= $m_rec_y2} {
        set y [expr $m_rec_y2 - 1]
        set outOfBoundary 1
    }
    
    if {$outOfBoundary} {
        set fColor red
    } else {
        set fColor white
    }

    if {$itk_option(-markerStyle) == "both" \
    || $itk_option(-markerStyle) == "cross_only" \
    || $itk_option(-debugShowCross)} {
        #### draw a cross with white outline and black fill so that
        #### it will always show
        set cross_size 20
        set cross_in_size 2

        set offsetList [list \
        -$cross_size              -$cross_in_size \
        -$cross_in_size           -$cross_in_size \
        -$cross_in_size           -$cross_size \
        +$cross_in_size           -$cross_size \
        +$cross_in_size           -$cross_in_size \
        +$cross_size              -$cross_in_size \
        +$cross_size              +$cross_in_size \
        +$cross_in_size           +$cross_in_size \
        +$cross_in_size           +$cross_size \
        -$cross_in_size           +$cross_size \
        -$cross_in_size           +$cross_in_size \
        -$cross_size +$cross_in_size \
        ]

        set pointList ""

        foreach {x_offset y_offset} $offsetList {
            lappend pointList [expr $x + $x_offset] [expr $y + $y_offset]
        }

        $m_canvas create polygon $pointList \
        -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
        -outline black \
        -fill $fColor
    }
    if {$itk_option(-markerStyle) == "both" \
    || $itk_option(-markerStyle) == "box_only"} {
        if {$w > 0 && $h > 0 && !$outOfBoundary} {

            set x0 [expr $x - $w / 2]
            set y0 [expr $y - $h / 2]
            set x1 [expr $x + $w / 2]
            set y1 [expr $y + $h / 2]
            puts "beamsize box: $x0 $y0 $x1 $y1"

            set lineWidth 1
            set half [expr $lineWidth / 2.0]

            set ix0 [expr $x0 + $half]
            set iy0 [expr $y0 + $half]
            set ix1 [expr $x1 - $half]
            set iy1 [expr $y1 - $half]

            set ox0 [expr $x0 - $half]
            set oy0 [expr $y0 - $half]
            set ox1 [expr $x1 + $half]
            set oy1 [expr $y1 + $half]

            set clip none
            if {$y0 < $m_rec_y1 && $y1 >= $m_rec_y2} {
                set clip both
            } elseif {$y0 < $m_rec_y1} {
                set clip top
            } elseif {$y1 >= $m_rec_y2} {
                set clip bottom
            }

            if {$clip == "both"} {
                set y0 $m_rec_y1
                set iy0 $m_rec_y1
                set oy0 $m_rec_y1

                set y1 $m_rec_y2
                set iy1 $m_rec_y2
                set oy1 $m_rec_y2

                $m_canvas create line $x0 $y0 $x0 $y1 \
                -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
                -fill $fColor \
                -width $lineWidth

                $m_canvas create line $x1 $y0 $x1 $y1 \
                -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
                -fill $fColor \
                -width $lineWidth
            } elseif {$clip == "bottom"} {
                set y1 $m_rec_y2
                set iy1 $m_rec_y2
                set oy1 $m_rec_y2

                $m_canvas create line $x0 $y1 $x0 $y0 $x1 $y0 $x1 $y1\
                -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
                -fill $fColor \
                -width $lineWidth
            } elseif {$clip == "top"} {
                set y0 $m_rec_y1
                set iy0 $m_rec_y1
                set oy0 $m_rec_y1

                $m_canvas create line $x0 $y0 $x0 $y1 $x1 $y1 $x1 $y0\
                -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
                -fill $fColor \
                -width $lineWidth
            } else {
                $m_canvas create rectangle $x0 $y0 $x1 $y1 \
                -tags [list mark mark$mark_num mcursor$mark_num $m_myTag $tag] \
                -fill "" \
                -width 1 \
                -outline $fColor
            }
        }
    }
}
