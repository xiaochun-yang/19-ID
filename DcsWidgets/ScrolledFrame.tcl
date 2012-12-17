package provide DCSScrolledFrame 1.0
package require Iwidgets
#
# This is modified from iwidgets::Scrolledframe
# H_Freeze (left), V_Freeze (top), and HV_Freeze(top-left) frames are
# added to implement frozen column headers

#

# Usual options.
#
itk::usual DCS::ScrolledFrame {
    keep -activebackground -activerelief -background -borderwidth -cursor \
	 -elementborderwidth -foreground -highlightcolor -highlightthickness \
	 -jump -labelfont -troughcolor
}

# ------------------------------------------------------------------
#                            SCROLLEDFRAME
# ------------------------------------------------------------------
class DCS::ScrolledFrame {
    inherit iwidgets::Scrolledwidget

    constructor {args} {}
    destructor {}

    public method childsite {} 

    ###call these functions will trigger show that frame
    public method hfreezesite {} 
    public method vfreezesite {} 
    public method hvfreezesite {} 

    public method justify {direction} 
    public method xview {args} 
    public method yview {args} 

    protected method _configureCanvas {} 
    protected method _configureVFCanvas {} 
    protected method _configureHFCanvas {} 
    protected method _configureFrame {} 
    protected method _configureVFFrame {} 
    protected method _configureHFFrame {} 
    protected method _redisplay { }

    protected variable m_showVFSite 0
    protected variable m_showHFSite 0
    protected variable m_showHVFSite 0
    protected variable m_parent
}

#
# Use option database to override default resources of base classes.
#
option add *ScrolledFrame.width 100 widgetDefault
option add *ScrolledFrame.height 20 widgetDefault
option add *ScrolledFrame.labelPos n widgetDefault

# ------------------------------------------------------------------
#                        CONSTRUCTOR
# ------------------------------------------------------------------
body DCS::ScrolledFrame::constructor {args} {
    itk_option remove iwidgets::Labeledwidget::state

    #
    # Create a clipping frame which will provide the border for
    # relief display.
    #

    set m_parent $itk_interior
    itk_component add clipper {
	frame $itk_interior.clipper 
    } {
	usual

	keep -borderwidth -relief 
    }	
    itk_component add v_freeze_clipper {
	frame $itk_interior.v_clipper 
    } {
	usual

	keep -borderwidth -relief 
    }	
    itk_component add h_freeze_clipper {
	frame $itk_interior.h_clipper 
    } {
	usual

	keep -borderwidth -relief 
    }	
    itk_component add hv_freeze_clipper {
	frame $itk_interior.hv_clipper 
    } {
	usual

	keep -borderwidth -relief 
    }	
    #grid $itk_component(hv_freeze_clipper) -row 0 -column 0 -sticky nsew
    #grid $itk_component(h_freeze_clipper) -row 1 -column 0 -sticky nsew
    #grid $itk_component(v_freeze_clipper) -row 0 -column 1 -sticky nsew
    grid $itk_component(clipper) -row 1 -column 1 -sticky nsew
    grid rowconfigure $_interior 1 -weight 1
    grid columnconfigure $_interior 1 -weight 1

    # 
    # Create a canvas to scroll
    #
    itk_component add canvas {
	canvas $itk_component(clipper).canvas \
		-height 1.0 -width 1.0 \
                -scrollregion "0 0 1 1" \
                -xscrollcommand \
		[code $this _scrollWidget $itk_interior.horizsb] \
		-yscrollcommand \
		[code $this _scrollWidget $itk_interior.vertsb] \
	        -highlightthickness 0 -takefocus 0
    } {
	ignore -highlightcolor -highlightthickness
	keep -background -cursor
    }
    ###################DCS special#################
    itk_component add v_freeze_canvas {
	    canvas $itk_component(v_freeze_clipper).v_canvas \
		-height 26.0 \
        -width 1.0 \
        -scrollregion "0 0 1 1" \
        -xscrollcommand [code $this _scrollWidget $itk_interior.horizsb] \
	    -highlightthickness 0 \
        -takefocus 0
    } {
	    ignore -highlightcolor -highlightthickness
	    keep -background -cursor
    }
    itk_component add h_freeze_canvas {
	    canvas $itk_component(h_freeze_clipper).h_canvas \
		-height 1.0 \
        -width 1.0 \
        -scrollregion "0 0 1 1" \
		-yscrollcommand [code $this _scrollWidget $itk_interior.vertsb] \
        -highlightthickness 0 \
        -takefocus 0
    } {
	    ignore -highlightcolor -highlightthickness
	    keep -background -cursor
    }

    grid $itk_component(canvas)          -row 0 -column 0 -sticky nsew
    grid $itk_component(h_freeze_canvas) -row 0 -column 0 -sticky nsew
    grid $itk_component(v_freeze_canvas) -row 0 -column 0 -sticky nsew

    grid rowconfigure $itk_component(clipper) 0 -weight 1
    grid columnconfigure $itk_component(clipper) 0 -weight 1

    grid rowconfigure $itk_component(v_freeze_clipper) 0 -weight 1
    grid columnconfigure $itk_component(v_freeze_clipper) 0 -weight 1

    grid rowconfigure $itk_component(h_freeze_clipper) 0 -weight 1
    grid columnconfigure $itk_component(h_freeze_clipper) 0 -weight 1
    
    # 
    # Configure the command on the vertical scroll bar in the base class.
    #
    $itk_component(vertsb) configure \
	-command [code $this yview]

    #
    # Configure the command on the horizontal scroll bar in the base class.
    #
    $itk_component(horizsb) configure \
	-command [code $this xview]
    
    #
    # Handle configure events on the canvas to adjust the frame size
    # according to the scrollregion.
    #
    bind $itk_component(canvas) <Configure> [code $this _configureCanvas]
    bind $itk_component(v_freeze_canvas) <Configure> [code $this _configureVFCanvas]
    bind $itk_component(h_freeze_canvas) <Configure> [code $this _configureHFCanvas]
    
    #
    # Create a Frame inside canvas to hold widgets to be scrolled 
    #
    itk_component add -protected sfchildsite {
	frame $itk_component(canvas).sfchildsite 
    } {
	keep -background -cursor
    }
    pack $itk_component(sfchildsite) -fill both -expand yes
    $itk_component(canvas) create window 0 0 -tags frameTag \
            -window $itk_component(sfchildsite) -anchor nw

    itk_component add -protected vfchildsite {
	frame $itk_component(v_freeze_canvas).sfchildsite 
    } {
	keep -background -cursor
    }
    pack $itk_component(vfchildsite) -fill x -expand yes
    $itk_component(v_freeze_canvas) create window 0 0 -tags frameTag \
            -window $itk_component(vfchildsite) -anchor nw

    itk_component add -protected hfchildsite {
	frame $itk_component(h_freeze_canvas).sfchildsite 
    } {
	keep -background -cursor
    }
    pack $itk_component(hfchildsite) -fill y -expand yes
    $itk_component(h_freeze_canvas) create window 0 0 -tags frameTag \
            -window $itk_component(hfchildsite) -anchor nw

    set itk_interior $itk_component(sfchildsite)
    bind $itk_component(sfchildsite) <Configure> [code $this _configureFrame]
    bind $itk_component(vfchildsite) <Configure> [code $this _configureVFFrame]
    bind $itk_component(hfchildsite) <Configure> [code $this _configureHFFrame]
    
    #
    # Initialize the widget based on the command line options.
    #
    eval itk_initialize $args

    grid $itk_component(horizsb) -row 2 -column 1 -sticky we
    grid $itk_component(vertsb) -row 1 -column 2 -sticky ns
}

# ------------------------------------------------------------------
#                           DESTURCTOR
# ------------------------------------------------------------------
body DCS::ScrolledFrame::destructor {} {
}


# ------------------------------------------------------------------
#                            METHODS
# ------------------------------------------------------------------

# ------------------------------------------------------------------
# METHOD: childsite
#
# Returns the path name of the child site widget.
# ------------------------------------------------------------------
body DCS::ScrolledFrame::childsite {} {
    return $itk_component(sfchildsite)
}
body DCS::ScrolledFrame::vfreezesite {} {
    set m_showVFSite 1
    _redisplay
    return $itk_component(vfchildsite)
}
body DCS::ScrolledFrame::hfreezesite {} {
    set m_showHFSite 1
    _redisplay
    return $itk_component(hfchildsite)
}
body DCS::ScrolledFrame::hvfreezesite {} {
    set m_showHVFSite 1
    _redisplay
    return $itk_component(hv_freeze_frame)
}

# ------------------------------------------------------------------
# METHOD: justify
#
# Justifies the scrolled region in one of four directions: top,
# bottom, left, or right.
# ------------------------------------------------------------------
body DCS::ScrolledFrame::justify {direction} {
    if {[winfo ismapped $itk_component(canvas)]} {
	update idletasks
	
	switch $direction {
	    left {
		$itk_component(canvas) xview moveto 0
		$itk_component(v_freeze_canvas) xview moveto 0
	    }
	    right {
		$itk_component(canvas) xview moveto 1
		$itk_component(v_freeze_canvas) xview moveto 1
	    }
	    top {
		$itk_component(canvas) yview moveto 0
		$itk_component(h_freeze_canvas) yview moveto 0
	    }
	    bottom {
		$itk_component(canvas) yview moveto 1
		$itk_component(h_freeze_canvas) yview moveto 1
	    }
	    default {
		error "bad justify argument \"$direction\": should be\
			left, right, top, or bottom"
	    }
	}
    }
}

# ------------------------------------------------------------------
# METHOD: xview index
#
# Adjust the view in the frame so that character position index
# is displayed at the left edge of the widget.
# ------------------------------------------------------------------
body DCS::ScrolledFrame::xview {args} {
    eval $itk_component(v_freeze_canvas) xview $args
    return [eval $itk_component(canvas) xview $args]
}

# ------------------------------------------------------------------
# METHOD: yview index
#
# Adjust the view in the frame so that character position index
# is displayed at the top edge of the widget.
# ------------------------------------------------------------------
body DCS::ScrolledFrame::yview {args} {
    eval $itk_component(h_freeze_canvas) yview $args
    return [eval $itk_component(canvas) yview $args]
}

# ------------------------------------------------------------------
# PRIVATE METHOD: _configureCanvas 
#
# Responds to configure events on the canvas widget.  When canvas 
# changes size, adjust frame size.
# ------------------------------------------------------------------
body DCS::ScrolledFrame::_configureCanvas {} {
    set sr [$itk_component(canvas) cget -scrollregion]
    set srw [lindex $sr 2]
    set srh [lindex $sr 3]
    
    $itk_component(sfchildsite) configure -height $srh -width $srw
}
body DCS::ScrolledFrame::_configureVFCanvas {} {
    set sr [$itk_component(v_freeze_canvas) cget -scrollregion]
    set srw [lindex $sr 2]
    set srh [lindex $sr 3]

    $itk_component(vfchildsite) configure -height $srh -width $srw
}
body DCS::ScrolledFrame::_configureHFCanvas {} {
    set sr [$itk_component(h_freeze_canvas) cget -scrollregion]
    set srw [lindex $sr 2]
    set srh [lindex $sr 3]
    
    #$itk_component(hfchildsite) configure -height $srh -width $srw
    $itk_component(h_freeze_canvas) configure -height $srh -width $srw
    puts "SSSSSS -h $srh -w $srw"
}

# ------------------------------------------------------------------
# PRIVATE METHOD: _configureFrame 
#
# Responds to configure events on the frame widget.  When the frame 
# changes size, adjust scrolling region size.
# ------------------------------------------------------------------
body DCS::ScrolledFrame::_configureFrame {} {
    $itk_component(canvas) configure \
	    -scrollregion [$itk_component(canvas) bbox frameTag] 
}
body DCS::ScrolledFrame::_configureVFFrame {} {
    $itk_component(v_freeze_canvas) configure \
	    -scrollregion [$itk_component(v_freeze_canvas) bbox frameTag] 
}
body DCS::ScrolledFrame::_configureHFFrame {} {
    $itk_component(h_freeze_canvas) configure \
	    -scrollregion [$itk_component(h_freeze_canvas) bbox frameTag] 
}
body DCS::ScrolledFrame::_redisplay {} {
    set all [grid slaves $m_parent]
    if {$all != ""} {
        eval grid forget $all
    }
    if {$m_showHVFSite} {
        grid $itk_component(hv_freeze_clipper) -row 0 -column 0 -sticky nsew
    }
    if {$m_showHFSite} {
        grid $itk_component(h_freeze_clipper) -row 1 -column 0 -sticky nsew
    }
    if {$m_showVFSite} {
        grid $itk_component(v_freeze_clipper) -row 0 -column 1 -sticky nsew
    }
    grid $itk_component(clipper) -row 1 -column 1 -sticky nsew
    grid $itk_component(horizsb) -row 2 -column 1 -sticky we
    grid $itk_component(vertsb) -row 1 -column 2 -sticky ns
}

