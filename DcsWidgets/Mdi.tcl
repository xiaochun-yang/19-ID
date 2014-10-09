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

# provide the BIWMDI package
package provide DCSMdi 1.0

# load standard packages
package require Itcl
package require Iwidgets
#package require BWidget 1.2.1

# load other BIW packages
package require DCSUtil


##########################################################################

class DCS::MDICanvas {
	inherit ::itk::Widget

	# public variables (accessed using configure)
	public variable background lightgrey

	# protected data
	protected variable _parentWidget
	protected variable _document
	protected variable _id
	protected variable width
	protected variable height
	protected variable _activeDocument ""

    protected variable m_canvas ""

	# public member functions
	public method addDocument
	public method addIwidget
	public method configureDocument { name args }
	public method deleteDocument { name }
	public method activateDocument { name }
	public method showDocument { name }
	public method hideDocument { name }
	public method maximizeDocument { name }
	public method restoreDocument { name }
	public method resizeDocument { name width height }
	public method getWidth {}
	public method getHeight {}
	public method documentExists { name }
	public method getDocumentInternalFrame { name }

    public method autoresize { } {
	    set bbox [$m_canvas bbox all] 

        if {[llength $bbox] < 4} {
            ### no document, empty canvas
            return
        }

        foreach {x1 y1 x2 y2} $bbox break

        #if {$x1 > 0} { set x1 0}
        #if {$y1 > 0} { set y1 0}
        ### we not allow place above 0
        set x1 0
        set y1 0

        $m_canvas configure \
        -scrollregion [list $x1 $y1 $x2 $y2] \
    }

    public method getDocumentsInfo { }

    public method placeDocument { name x y } {
        catch { $m_canvas coord $_id($name) $x $y }
        autoresize
    }

	# public helper functions
	public method updateSize {}

    public method resetView { } {
        $itk_component(canvas) xview moveto 0.0
        $itk_component(canvas) yview moveto 0.0
    }

	constructor { parentWidget_ args } {
		array set _id {}
		set _parentWidget $parentWidget_

		array set document {}

		itk_component add ring {
			frame $itk_interior.r
		}

		itk_component add canvas {
			iwidgets::scrolledcanvas $itk_component(ring).mdiCanvas \
            -hscrollmode dynamic \
            -vscrollmode dynamic \
		} {
			keep -background -relief -borderwidth
		}

        set m_canvas [$itk_component(canvas) component canvas]

		pack $itk_component(ring)  -fill both -expand 1
		pack $itk_component(canvas) -fill both -expand 1
		
		# catch all canvas resize events
		#bind $itk_component(canvas) <Configure> "$this updateSize"
        #bind $itk_component(canvas) <Button-1> { puts "%x %y" }
		bind $m_canvas <Configure> "$this updateSize"
        bind $m_canvas <Button-1> { puts "%x %y" }

   
		# configure the new mdi canvas
		eval itk_initialize $args

		# force Tk to draw the canvas
		#update idletasks
	}
	
	destructor {

		# individually delete each document
		foreach documentName [array names documentList] {
			deleteDocument $documentName
		}

		# destroy the canvas
		#destroy $itk_component(canvas)
	}

}

body DCS::MDICanvas::documentExists { name } {
	return [info exists _document($name)]
}
body DCS::MDICanvas::getDocumentsInfo { } {
    set result ""
    foreach name [array names _document] {
        lappend result [$_document($name) getGeo]
    }
    return $result
}

body DCS::MDICanvas::addDocument { name args } {

	# create the new document and add it to the list of documents
	#set document($name) [eval {DCS::MdiDocument \#auto $name $this $itk_component(canvas)} $args]

	set path $m_canvas.$name

	set _document($name) [eval {DCS::MdiDocument $path $name $this } $args]

    set x [$_document($name) cget -x]
    set y [$_document($name) cget -y]
    set resizable [$_document($name) cget -resizable]

	puts "MDI: $_document($name)"
    set _id($name) [$itk_component(canvas) create window $x $y \
    -anchor nw \
    -window $path]

    puts "set _id($name) to $_id($name)"

    $_document($name) setAttachedToCanvas

	# activate the document
	activateDocument $name

	update
    autoresize

    if {!$resizable} {
        after 500 "$this autoresize"
    }

	# return the internal frame of the new document
	return [$path getInternalFrame]
}


body DCS::MDICanvas::getDocumentInternalFrame { name } {

	# return the internal frame of the new document
	return [$_document($name) getInternalFrame]
}


body DCS::MDICanvas::configureDocument { name args } {

	eval {$_document($name) configure} $args
}


body DCS::MDICanvas::deleteDocument { name } {

	#change the current pointer to a watch/clock to show the system is busy
	blt::busy hold . -cursor watch
	update

	#remove the itk_component
	if {[ catch {
      $_parentWidget itk_component delete $name

	   # destroy the entry itself
	   destroy $_document($name)

	   # delete the documemt from the document list 
	   unset _document($name)
   } err ] } {
      #print the error message that we caught in the destructor
      global errorInfo
      puts $errorInfo
   }

	blt::busy release .

    autoresize
}


body DCS::MDICanvas::updateSize {} {
	# get new width and height of canvas
	set width  [winfo width  $m_canvas]
	set height [winfo height $m_canvas]

	# set all maximized windows back to unmaximized state
	foreach name [array names _document] {
		$_document($name) setupMaximizeWidgets
	}

    autoresize
}


body DCS::MDICanvas::getWidth {} {
    return $width
}


body DCS::MDICanvas::getHeight {} {
    return $height
}


configbody DCS::MDICanvas::background {

	$m_canvas configure -background $background
}



body DCS::MDICanvas::maximizeDocument { name } {

	$_document($name) maximize
}


body DCS::MDICanvas::activateDocument { name } {

	# deactivate the last active document
	catch { $_document($_activeDocument) deactivate }

	# activate the specified window
	$_document($name) activateWindow

	# store the name of the new active window
	set _activeDocument $name

}


##########################################################################


class DCS::MdiDocument {
	inherit ::itk::Widget

	# protected variables
	protected variable _docName
	protected variable tkCanvas
	protected variable mdiCanvas
	protected variable hideButton
	protected variable isShown
	protected variable isActive
	protected variable oldX
	protected variable oldY
	protected variable oldWidth
	protected variable oldHeight
	protected variable cursor

    protected variable m_attachedToCanvas 0

	# public variables (accessed via configure command)

	itk_option define -resizable resizable Resizable 0
	itk_option define -titleInactiveBackground titleInactiveBackground TitleInactiveBackground grey
	itk_option define -titleActiveBackground titleActiveBackground TitleActiveBackground blue
	
    itk_option define -fontResizable fontResizable FontResizable 0

	public variable title ""
	public variable x 10
	public variable y 10
	public variable width 100
	public variable height 100
	public variable minWidth
	public variable maxWidth
	public variable minHeight
	public variable maxHeight
	public variable borderColor lightgrey
	public variable buttonBackground lightgrey
	public variable dragX
	public variable dragY
	public variable resizeX
	public variable resizeY
	public variable activationCallback {}
	public variable destructionCallback {}

    public variable increaseFontCallback { }
    public variable decreaseFontCallback { }

	# public method
    public method setAttachedToCanvas { } { set m_attachedToCanvas 1 }
	public method getInternalFrame
	public method activate
	public method deactivate
	public method maximize 
	public method restore
	public method kill
	public method setupMaximizeWidgets
	public method setupRestoreWidgets
	public method activateWindow
	public method startDrag
	public method drag
	public method enterExternalFrame
	public method startResize
	public method resize

    public method fontSizePlus { } {
        if {$increaseFontCallback != ""} {
            eval $increaseFontCallback
        }
    }
    public method fontSizeMinus { } {
        if {$decreaseFontCallback != ""} {
            eval $decreaseFontCallback
        }
    }

    public method getGeo { } {
        return [list $_docName $x $y $width $height]
    }

	# common bitmap definitions
	private common systemButtonImage
	set systemButtonImage [image create bitmap -data \
		"#define system_width 16
		#define system_height 16
		static unsigned char system_bits[] = {
   	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0x7f,
   	0xfe, 0x7f, 0x06, 0x60, 0x06, 0x60, 0xfe, 0x7f, 0xfe, 0x7f, 0x00, 0x00,
   	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"]

	private common hideButtonImage
	set hideButtonImage [image create bitmap -data \
		"#define hide_width 16
		#define hide_height 16
		static unsigned char hide_bits[] = {
   	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xe0, 0x07,
   	0xe0, 0x07, 0x60, 0x06, 0x60, 0x06, 0xe0, 0x07, 0xe0, 0x07, 0x00, 0x00,
   	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"]

	private common maximizeButtonImage
	set maximizeButtonImage [image create bitmap -data \
		"#define maximize_width 16
		#define maximize_height 16
		static unsigned char maximize_bits[] = {
  	 	0x00, 0x00, 0xfe, 0x7f, 0xfe, 0x7f, 0x06, 0x60, 0x06, 0x60, 0x06, 0x60,
   	0x06, 0x60, 0x06, 0x60, 0x06, 0x60, 0x06, 0x60, 0x06, 0x60, 0x06, 0x60,
   	0x06, 0x60, 0xfe, 0x7f, 0xfe, 0x7f, 0x00, 0x00};"]

	private common restoreButtonImage
	set restoreButtonImage [image create bitmap -data \
		"#define restore_width 16
		#define restore_height 16
		static unsigned char restore_bits[] = {
   	0x00, 0x00, 0xe0, 0x7f, 0xe0, 0x7f, 0x60, 0x60, 0xfe, 0x67, 0xfe, 0x67,
   	0x06, 0x66, 0x06, 0x66, 0x06, 0x66, 0x06, 0x66, 0x06, 0x7e, 0x06, 0x7e,
   	0x06, 0x06, 0xfe, 0x07, 0xfe, 0x07, 0x00, 0x00};"]

	private common killButtonImage
	set killButtonImage [image create bitmap -data \
		"#define kill_width 16
		#define kill_height 16
		static unsigned char kill_bits[] = {
   	0x00, 0x00, 0x00, 0x00, 0x0c, 0x30, 0x1c, 0x38, 0x38, 0x1c, 0x70, 0x0e,
   	0xe0, 0x07, 0xc0, 0x03, 0xc0, 0x03, 0xe0, 0x07, 0x70, 0x0e, 0x38, 0x1c,
   	0x1c, 0x38, 0x0c, 0x30, 0x00, 0x00, 0x00, 0x00};"]

	# constructor
	constructor { name_ mdiCanvas_ args } {

		set _docName $name_

		set mdiCanvas $mdiCanvas_


		itk_component add ring {
			frame $itk_interior.r -relief raised -borderwidth 2
		} 
		# set up bindings for resizing the document
		bind $itk_component(ring) <Enter> "$this enterExternalFrame %X %Y"
		bind $itk_component(ring) <Motion> "$this enterExternalFrame %X %Y"
		bind $itk_component(ring) <Leave> "$itk_component(ring) configure -cursor left_ptr"
		bind $itk_component(ring) <1> "$this startResize %X %Y"
		bind $itk_component(ring) <B1-Motion> "$this resize %X %Y"

		# create the titlebar frame
		itk_component add titlebar {
			frame $itk_component(ring).titlebar
		}

		pack $itk_component(titlebar) -side top -expand true -fill x
		bind $itk_component(titlebar) <Enter> \
			 "$itk_component(titlebar) configure -cursor left_ptr; $itk_component(ring) configure -cursor left_ptr"

		# create the internal frame
		itk_component add internalFrame {
			frame $itk_component(ring).internal
		} {
			keep -width -height
		}

		pack $itk_component(internalFrame) -side top -expand true -fill both -padx 3 -pady 3

		bind $itk_component(internalFrame) <Enter> \
			 "$itk_component(internalFrame) configure -cursor left_ptr; $itk_component(ring) configure -cursor left_ptr"

		# create the system button
		set systemMenu $itk_component(titlebar).system.menu

		itk_component add systemButton {
			menubutton $itk_component(titlebar).system \
				 -relief raised -width 18 -height 18 \
				 -image $systemButtonImage \
				 -background $buttonBackground \
				 -activebackground $buttonBackground \
				 -menu $systemMenu
		} {
		}

		pack $itk_component(systemButton) -side left -padx 2 
		bind $itk_component(systemButton) <Enter> "$itk_component(systemButton) configure -cursor hand2"

		# make doubleclicks of the system button kill the window
		bind $itk_component(systemButton) <Double-1> "$this kill; break"

		# create the system menu
		itk_component add systemMenu {
			menu $systemMenu -tearoff 0
		} {
		}

		$itk_component(systemMenu) add command -label "Maximize" -command "$this maximize"
		$itk_component(systemMenu) add separator
		$itk_component(systemMenu) add command -label "Close" -command "$this kill"

		# create the title label
		itk_component add titleLabel {
			label $itk_component(titlebar).title -foreground white -font "helvetica -14 bold"
		} {
			#rename -foreground -titleForeground titleForeground TitleForeground
		}

		pack $itk_component(titleLabel) -side left -fill x -expand 1

		# make doubleclicks of the title bar maximize the window
		bind $itk_component(titleLabel) <Double-1> "$this maximize"

		# make singleclicks activate the window
		bind $itk_component(titleLabel) <1> "$this activate; $this startDrag %X %Y"

		# allow movement of the window by dragging title bar
		bind $itk_component(titleLabel) <B1-Motion> "$itk_component(titleLabel) configure -cursor fleur;$this drag %X %Y"

		# note when cursor enters title label
		bind $itk_component(titleLabel) <Enter> "$itk_component(titleLabel) configure -cursor hand2"
		bind $itk_component(titleLabel) <ButtonRelease-1> "$itk_component(titleLabel) configure -cursor hand2"

		# create the kill button
		itk_component add killButton {
			button $itk_component(titlebar).kill \
				 -image $killButtonImage \
				 -background $buttonBackground \
				 -activebackground $buttonBackground \
				 -command "$this kill"
		} {
		}

		pack $itk_component(killButton) -side right	
		bind $itk_component(killButton) <Enter> "$itk_component(killButton) configure -cursor hand2"

		# create the maximize button
		itk_component add maximize {
			button $itk_component(titlebar).maximize \
				 -background $buttonBackground \
				 -activebackground $buttonBackground
		} {
		}

		pack $itk_component(maximize) -side right
		bind $itk_component(maximize) <Enter> "$itk_component(maximize) configure -cursor hand2"

		# set up the bindings for the maximize widgets
		setupMaximizeWidgets

		# create the hide button
		itk_component add hide {
			button $itk_component(titlebar).hide \
				 -image $hideButtonImage \
				 -background $buttonBackground \
				 -activebackground $buttonBackground
		} {
		}

		#pack $itk_component(hide) -side right
		bind $itk_component(hide) <Enter> "$itk_component(hide) configure -cursor hand2"

		pack $itk_component(ring)

		# configure the new document
		eval itk_initialize $args

        if {$itk_option(-fontResizable)} {
		    $itk_component(systemMenu) add separator
		    $itk_component(systemMenu) add command \
            -label "font size +" \
            -command "$this fontSizePlus"

		    $itk_component(systemMenu) add command \
            -label "font size -" \
            -command "$this fontSizeMinus"
        }
	}

	# destructor
	destructor {
		
		# delete the Tk frames and buttons
		#destroy $itk_component(ring)

		# call destruction callback function
		if { $destructionCallback != {} } {
			eval $destructionCallback $_docName
		}
	}
}



body DCS::MdiDocument::startResize { startX startY } {

	if { $cursor != "left_ptr" } {
		
		set resizeX $startX
		set resizeY $startY
	}
}


body DCS::MdiDocument::resize { X Y } {

	# return immediately if not resizable
	if { ! $itk_option(-resizable)} {
		return
	}

	# return immediately if not near an edge
	if { $cursor == "left_ptr" } {
		return
	}

	set newX $x
	set newY $y
	set newHeight $height
	set newWidth $width

	if { [string match "*left*" $cursor] } {
		set newWidth [expr $width - $X + $resizeX]
		set newX [expr $x + $X - $resizeX]
	}

	if { [string match "*right*" $cursor] } {
		set newWidth [expr $width + $X - $resizeX]
	}


	if { [string match "*top*" $cursor] } {
		set newHeight [expr $height - $Y + $resizeY]
		set newY [expr $y + $Y - $resizeY]
	}

	if { [string match "*bottom*" $cursor] } {
		set newHeight [expr $height + $Y - $resizeY]	
	}

	if { $newHeight < 40 } {
		return
	}

	set height $newHeight
	set width $newWidth

	# replace old mouse positions
	set resizeX $X
	set resizeY $Y

	# reframe size according to new height and width
	$itk_component(internalFrame) configure -height $height -width $width

    ## this will place it at x y
	configure -x $newX -y $newY

	# prepare window for maximize
	setupMaximizeWidgets
}


body DCS::MdiDocument::enterExternalFrame { cursorX cursorY } {
	# bring title bar back into view of off the top of the canvas
	if { $y < 0 } {
		configure -y 0
	}

	# get position and size of external frame
	set frameX [winfo rootx $itk_interior]
	set frameY [winfo rooty $itk_interior]
	set frameHeight [winfo height $itk_interior]
	set frameWidth [winfo width $itk_interior]

	# get relative positions of cursor to window borders
	set deltaLeft [expr abs($cursorX - $frameX)]
	set deltaRight [expr abs($cursorX - $frameX - $frameWidth)]
	set deltaTop [expr abs($cursorY - $frameY)]
	set deltaBottom [expr abs($cursorY - $frameY - $frameHeight)]

	# set default cursor
	set cursor left_ptr

	# check if cursor on left edge
	if { $deltaLeft < 10 } {
		set cursor left_side
	}

	# check if cursor on right edge
	if { $deltaRight < 10 } {
		set cursor right_side
	}

	# check if cursor is on top edge
	if { $deltaTop < 10 } {
		if { $cursor == "left_side" } {
			set cursor top_left_corner
		} else {
			if { $cursor == "right_side" } {
				set cursor top_right_corner
			} else {	
				set cursor top_side
			}
		}
	}

	# check if cursor is on bottom edge
	if { $deltaBottom < 10 } {
		if { $cursor == "left_side" } {
			set cursor bottom_left_corner
		} else {
			if { $cursor == "right_side" } {
				set cursor bottom_right_corner
			} else {	
				set cursor bottom_side
			}
		}
	}

	# set the cursor to the resulting value
	$itk_component(ring) configure -cursor $cursor
}


body DCS::MdiDocument::startDrag { startX startY } {
	set dragX $startX
	set dragY $startY
}


body DCS::MdiDocument::drag { newX newY } {
	configure \
    -x [expr $x + $newX - $dragX] \
	-y [expr $y + $newY - $dragY]

	set dragX $newX
	set dragY $newY


	setupMaximizeWidgets
}

body DCS::MdiDocument::getInternalFrame {} {

	return $itk_component(internalFrame)
}


body DCS::MdiDocument::maximize {} {

	# return immediately if not resizable
	if { ! $itk_option(-resizable)} {
		return
	}

	# store old position and size of document
	set oldX $x
	set oldY $y
	set oldWidth $width
	set oldHeight $height

	# change size and position of document to fit MDI canvas
	$this configure -x 0 -y 0 \
		 -width [expr [$mdiCanvas getWidth] - 4 ] \
		 -height [expr [$mdiCanvas getHeight] - 28 ]

	# setup maximize buttons to restore window size
	setupRestoreWidgets

	# activate the window
	activate
}


body DCS::MdiDocument::deactivate {} {

	# unhighlight the title bar
	$itk_component(titleLabel) configure -background $itk_option(-titleInactiveBackground)
}

body DCS::MdiDocument::activate {} {

	$mdiCanvas activateDocument $_docName
}


body DCS::MdiDocument::activateWindow {} {

	# raise the window to the top
	raise $itk_interior

	# highlight the title bar
	$itk_component(titleLabel) configure -background $itk_option(-titleActiveBackground)

	# call activation callback function
	if { $activationCallback != {} } {
		eval $activationCallback $_docName
	}
}


body DCS::MdiDocument::restore {} {

	# change size and position of document to fit MDI canvas
	$this configure -x $oldX -y $oldY \
		 -width $oldWidth -height $oldHeight

	# restore the maximize image and functionality 
	setupMaximizeWidgets
}


body DCS::MdiDocument::setupMaximizeWidgets {} {

	# restore the maximize image and functionality
	$itk_component(maximize) configure -image $maximizeButtonImage \
		 -command "$this maximize"

	# make doubleclicks of the title bar maximize the window
	bind $itk_component(titleLabel) <Double-1> "$this maximize"
}


body DCS::MdiDocument::setupRestoreWidgets {} {

	# change the image on the maximize button to show the restore image 
	$itk_component(maximize) configure -image $restoreButtonImage \
		 -command "$this restore"

	# make doubleclicks of the title bar restore the window
	bind $itk_component(titleLabel) <Double-1> "$this restore"
}


body DCS::MdiDocument::kill {} {

	# request MDI canvas to delete the document
	$mdiCanvas deleteDocument $_docName
}


configbody DCS::MdiDocument::title {

	$itk_component(titleLabel) configure -text $title

}

configbody DCS::MdiDocument::width {

	$itk_component(internalFrame) configure -width $width
}

configbody DCS::MdiDocument::height {

	$itk_component(internalFrame) configure -height $height
}

configbody DCS::MdiDocument::x {
    if {$m_attachedToCanvas} {
        $mdiCanvas placeDocument $_docName $x $y
    }
}

configbody DCS::MdiDocument::y {
    if {$m_attachedToCanvas} {
        $mdiCanvas placeDocument $_docName $x $y
    }
}

configbody DCS::MdiDocument::borderColor {
	$itk_component(ring) configure -background $borderColor
}

configbody DCS::MdiDocument::resizable {

	if { $itk_option(-resizable) } {
		#if it is resizable then don't pack to the internal size
		pack propagate $itk_component(internalFrame) 0
		pack $itk_component(maximize) -side right -after $itk_component(killButton)
		$itk_component(systemMenu) entryconfigure "Maximize" -state normal
	} else {
		#if it isn't resizable then just pack to the internal size
		pack propagate $itk_component(internalFrame) 1
		pack forget $itk_component(maximize)
		$itk_component(systemMenu) entryconfigure "Maximize" -state disabled
	}
}


proc testMDI {} {

	DCS::MDICanvas .test
	pack .test  -side top -fill both -expand true
	

	set childsite [.test addDocument internal]

	#puts "$childsite"

	button $childsite.b
	pack $childsite.b
	pack $childsite

}



#testMDI
