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


set gSafeEntry(mutex) 0
set gBlank "                                                                                                             "


proc panedWindow { master pane1 pane2 args } {

	# global variables
	global gPanedWindow

	# assign default values to those not passed
	array set parameter { 
		-orient		vertical
		-percent 	0.5
		-gripcolor	gray50
	}

	# assign passed parameters
	array set parameter $args

	# get parent and widget names
	set parent [getWindowParent $master]
	set name [getWindowName $master]

	# store the requested percentage
	set gPanedWindow($name,percent) $parameter(-percent)

	# store the names of the panes
	set gPanedWindow($name,pane1) 	$pane1
	set gPanedWindow($name,pane2) 	$pane2
	set gPanedWindow($name,master) 	$master
	
	# create the grip
	set gPanedWindow($name,grip) [
		frame $parent.grip -background $parameter(-gripcolor) \
		-width 10 -height 10 -bd 1 -relief raised ]
		
	# place the panes and grip depending on orientation
	if { $parameter(-orient) == "vertical" } {
		set gPanedWindow($name,orient) Y
		place $gPanedWindow($name,pane1) -in $master -x 0 -rely 0.0 -anchor nw \
			-relwidth 1.0 -height -1
		place $gPanedWindow($name,pane2) -in $master -x 0 -rely 1.0 -anchor sw \
			-relwidth 1.0 -height -1
		place $gPanedWindow($name,grip) -in $master -anchor c -relx 0.95
		$master configure -cursor sb_v_double_arrow
		$gPanedWindow($name,grip) configure -cursor sb_v_double_arrow
	} else {
		set gPanedWindow($name,orient) X
		place $gPanedWindow($name,pane1) -in $master -y 0 -relx 0.0 -anchor nw \
			-relheight 1.0 -width -1
		place $gPanedWindow($name,pane2) -in $master -y 0 -relx 1.0 -anchor ne \
			-relheight 1.0 -width -1
		place $gPanedWindow($name,grip) -in $master -anchor c -rely 0.95
		$master configure -background black -cursor sb_h_double_arrow
		$gPanedWindow($name,grip) configure -cursor sb_h_double_arrow
	}
	
	$pane1 configure -cursor "left_ptr"
	$pane2 configure -cursor "left_ptr"

	# set up bindings
	bind $master <Configure> "panedWindowUpdate $name"
	bind $gPanedWindow($name,grip) <ButtonPress-1>	\
		"panedWindowDrag $name %$gPanedWindow($name,orient)"
	bind $gPanedWindow($name,grip) <B1-Motion>	\
		"panedWindowDrag $name %$gPanedWindow($name,orient)"
	bind $gPanedWindow($name,grip) <ButtonRelease-1>	\
		"panedWindowStop $name %$gPanedWindow($name,orient)"
	
	bind $master <ButtonPress-1>	\
		"panedWindowDrag $name %$gPanedWindow($name,orient)"
	bind $master <B1-Motion>	\
		"panedWindowDrag $name %$gPanedWindow($name,orient)"
	bind $master <ButtonRelease-1>	\
		"panedWindowStop $name %$gPanedWindow($name,orient)"
	
	# do the initial layout
	panedWindowUpdate $name
}


proc panedWindowDrag { name D } {

	# global variables
	global gPanedWindow

	if { [ info exists gPanedWindow($name,lastD) ] } {
		set delta [ expr (double($gPanedWindow($name,lastD)) - $D) \
			/ $gPanedWindow($name,size) ]
		set gPanedWindow($name,percent) \
			[ expr $gPanedWindow($name,percent) - $delta ]
		if { $gPanedWindow($name,percent) < 0.0 } {
			set gPanedWindow($name,percent) 0.0
		} elseif { $gPanedWindow($name,percent) > 1.0 } {
			set gPanedWindow($name,percent) 1.0
		}
		panedWindowUpdate $name
	}
	set gPanedWindow($name,lastD) $D
}


proc panedWindowStop { name args } {

	# global variables
	global gPanedWindow

	catch { unset gPanedWindow($name,lastD) }
}


proc panedWindowUpdate { name } {

	# global variables
	global gPanedWindow

	if { $gPanedWindow($name,orient) == "X" } {
		place $gPanedWindow($name,pane1) \
			-relwidth $gPanedWindow($name,percent)
		place $gPanedWindow($name,pane2) \
			-relwidth [expr 1.0 - $gPanedWindow($name,percent)]
		place $gPanedWindow($name,grip) \
			-relx $gPanedWindow($name,percent)
		set gPanedWindow($name,size) [winfo width $gPanedWindow($name,master) ]
	} else {
		#if { [expr int($gPanedWindow($name,percent) * 100) % 4] == 0 } { }
		place $gPanedWindow($name,pane1) \
			-relheight $gPanedWindow($name,percent)
		place $gPanedWindow($name,pane2) \
			-relheight [expr 1.0 - $gPanedWindow($name,percent)]
		place $gPanedWindow($name,grip) \
			-rely $gPanedWindow($name,percent)
		set gPanedWindow($name,size) [winfo height $gPanedWindow($name,master) ]
	}
}


proc scrolledText { window args } {

	# global variables
	global gScrolledText

	# assign default values to those not passed
	array set parameter { 
		-font fixed
		-background gray
		-state normal
		-relief raised
		-wrap none
	}

	# assign passed parameters
	array set parameter $args

	# get parent and widget names
	set parent [getWindowParent $window]
	set name [getWindowName $window]

	# create and pack the frame to hold the text and scrollbar widgets
	pack [ set gScrolledText($name,frame) [
		frame $window -relief flat ] ] -expand yes -fill both

	set gScrolledText($name,text) $window.text
	set gScrolledText($name,yscroll) $window.yscroll
	
	# create and pack the text widget
	pack [ text $window.text	\
		-yscrollcommand "$gScrolledText($name,yscroll) set" 	\
		-background $parameter(-background)							\
		-state $parameter(-state)										\
		-relief $parameter(-relief)									\
		-font $parameter(-font)											\
		-wrap $parameter(-wrap)											\
		-borderwidth 0														\
		-width 1 ] \
		-side left -expand yes -fill both

	# create and pack the scrollbar widget
	pack [ scrollbar $window.yscroll 	\
		-command "$gScrolledText($name,text) yview" ] \
		-side left -fill y

	# return the text widget
	return $gScrolledText($name,text)
}



proc scrolledCanvas { window args } {

	# global variables
	global gScrolledCanvas

	# assign default values to those not passed
	array set parameter { 
		-background gray
		-incr			1
		-window		NULL
		-height		0
		-width		0
	}

	# assign passed parameters
	array set parameter $args

	# get parent and widget names
	set parent [getWindowParent $window]
	set name [getWindowName $window]

	# create and pack the frame to hold the text and scrollbar widgets
	pack [ set gScrolledCanvas($name,frame) [
		frame $window -relief flat ] ] -expand yes -fill both

	set gScrolledCanvas($name,canvas) $window.canvas
	set gScrolledCanvas($name,yscroll) $window.yscroll
	
	# create and pack the text widget
	pack [ canvas $window.canvas	\
		-scrollregion "0 0 $parameter(-width) $parameter(-height)"	\
		-yscrollcommand "$gScrolledCanvas($name,yscroll) set" \
		-yscrollincrement $parameter(-incr)							\
		-background $parameter(-background)							\
		-borderwidth 0														\
		-width 1 ] \
		-side left -expand 1 -fill both

		
	# place a frame on the scrolling canvas
	if { $parameter(-window) != "NULL" } {
		$gScrolledCanvas($name,canvas) create window 0 0 	\
			-anchor nw -window $parameter(-window)
	}	
	
	# create and pack the scrollbar widget
	pack [ scrollbar $window.yscroll 	\
		-command "$gScrolledCanvas($name,canvas) yview" ] \
		-side left -fill y

	# return the canvas widget
	return $gScrolledCanvas($name,canvas)
}



proc labeledFrame { window args } {

	# global variables
	global gLabeledFrame
	global gFont

	# assign default values to those not passed
	array set parameter { 
		-label	""
		-width 	100
		-height	100
		-x			1
		-y			14
	}

	set parameter(-font) $gFont(large)

	# assign passed parameters
	array set parameter $args
	
	# get parent and widget names
	set parent [getWindowParent $window]
	set name [getWindowName $window]

	# create a canvas to draw the labeled frame in
	set canvasHeight [expr $parameter(-height) + 30]
	set canvasWidth  [expr $parameter(-width)  + 20]
	set gLabeledFrame($name,canvas) [
		canvas $window -width $canvasWidth -height $canvasHeight ]
		
	# create a frame inside the canvas to make the border
	set borderHeight [expr $parameter(-height) + 15]
	set borderWidth  [expr $parameter(-width)  + 11]
	set gLabeledFrame($name,border) [
		frame $window.border -width $borderWidth -height $borderHeight	\
		-relief groove -borderwidth 2]
	place $gLabeledFrame($name,border) -x 5 -y 15
	
	# create the label
	set gLabeledFrame($name,label) [
		label $window.label -text $parameter(-label) -font $parameter(-font) ]
	place $gLabeledFrame($name,label) -x 15 -y 5
	
	# create the frame to draw in
	set gLabeledFrame($name,frame) [
		frame $window.border.frame	\
		-height $parameter(-height) -width $parameter(-width) ]
	place $gLabeledFrame($name,frame) -x $parameter(-x) -y $parameter(-y)

	return $gLabeledFrame($name,canvas)
}


proc safe_entry_set_state { name state } {

	# global variables
	global gSafeEntry
	global gColors

	if { $state == "normal" } {
		$gSafeEntry($name,entry) configure -state normal \
			-bg $gColors(light)
	} else {
		$gSafeEntry($name,entry) configure -state disabled \
			-bg lightgrey
	}
	

}


proc getSafeEntryValue { name } {

	# global variables
	global gSafeEntry
	
	return [set $gSafeEntry($name,variable)]
}


proc setSafeEntryValue { name value } {

	# global variables
	global gSafeEntry
	
	set $gSafeEntry($name,variable) $value
}


proc safeEntry { window args } {

	# global variables
	global gSafeEntry
	
	# assign default values
	array set parameter { 
		-justification			right
		-width 					10
		-variable 				"" 
		-font 					fixed 
		-type 					"" 
		-command 				""
		-label					""
		-units					""
		-labelwidth				0
		-unitswidth				0
		-labelanchor			e
		-unitsanchor			w
		-state					normal
		-relief					sunken
		-background				""
		-highlightthickness 	0
		-highlightcolor 		red
		-onsubmit				""
		-unitsforeground		black
		-name						""
	}
	
	# assign passed parameters
	array set parameter $args

	# get parent and widget names
	set parent [getWindowParent $window]
	
	if { $parameter(-name) != "" } {
		set name $parameter(-name)
	} else {
		set name [getWindowName $window]
	}

	if { $parameter(-variable) == "" } {
		set parameter(-variable) gSafeEntry($name,value)
	}
	
	set gSafeEntry($name,variable) $parameter(-variable)

   # access variable if assigned
   if { [ info exists $parameter(-variable) ] } {
   	global [getArrayName $par(variable)]
  	}

	# create the frame to hold the labels and entry 
	set gSafeEntry($name,frame) [
		frame $window ]
		
	# create the label if specified
	if { $parameter(-label) != "" } {
		pack [ set gSafeEntry($name,label) [
			label $window.label 					\
			-text $parameter(-label)			\
			-width $parameter(-labelwidth)	\
			-font $parameter(-font)				\
			-anchor $parameter(-labelanchor) ] ] -side left
	}
	
   # create the entry subwidget 

   pack [ set gSafeEntry($name,entry) [
		entry $window.entry						\
		-textvariable $parameter(-variable)	\
		-font $parameter(-font)					\
		-width $parameter(-width)				\
		-state $parameter(-state)				\
		-relief $parameter(-relief)			\
		-justify $parameter(-justification) \
		-highlightcolor $parameter(-highlightcolor) \
		-highlightthickness $parameter(-highlightthickness) ] ] -side left
	
	if { $parameter(-background) != "" } {
		$gSafeEntry($name,entry) configure -background $parameter(-background)
	}
	
	if { $parameter(-onsubmit) != "" } {
		bind $gSafeEntry($name,entry) <FocusOut> $parameter(-onsubmit)
		bind $gSafeEntry($name,entry) <Return> $parameter(-onsubmit)
	}

	# create the units if specified
	if { $parameter(-units) != "" } {
		pack [ set gSafeEntry($name,units) [
			label $window.units 					\
			-text $parameter(-units)			\
			-width $parameter(-unitswidth)	\
			-fg $parameter(-unitsforeground)	\
			-font $parameter(-font)				\
			-anchor $parameter(-unitsanchor) ] ] -side left
	}
	
   # set up the tracing on the variable if needed
   if { $parameter(-type) != "" } {
   	setSafeEntryTrace $parameter(-variable) $gSafeEntry($name,entry) \
   		$parameter(-type) $parameter(-command)
   }

	# return the megawidget
	return $gSafeEntry($name,frame)
}



proc setSafeEntryTrace { variable entry type command } {

	# global variables
	global gSafeEntry
	global [getArrayName $variable]
	
	# set the value of the variable to null string if undefined
	if { ! [info exists $variable] } {
		set $variable ""
	}
	
	# set up the trace on the variable
	clearTraces $variable
	storeValue $variable [set $variable]
	trace variable $variable w \
		"[list traceSafeEntry $variable $entry $type $command]"
}


proc traceSafeEntry { variable entry type command args } {

	# global variables
	global gSafeEntry
	global [getArrayName $variable]

	# return immediately if change wasn't made in the entry field
	if { [focus] != $entry } {
		storeValue $variable [set $variable]
		return
	}

	# return if mutex taken, otherwise take the mutex
	if { $gSafeEntry(mutex) } {
		return
	} else {
		set gSafeEntry(mutex) 1
	}

	# store the value and execute command if value is correct type or blank
	if { [set $variable] == {} || [is_incomplete_${type} [set $variable]] } {
		storeValue $variable [set $variable]
		eval $command
	} else {
		# otherwise restore previous value
		set $variable [recallValue $variable]
		tkEntrySetCursor $entry [expr [$entry index insert] - 1]
	}	
	
	# release the mutex
	set gSafeEntry(mutex) 0
	
}


######################################################################
# getArrayName -- Returns the name of the Tcl array associated
# with the passed variable.  For example [getArrayName junk(index)]
# returns "junk".  If the variable is not an array, the passed
# variable name is simply returned.
######################################################################

proc getArrayName { variable } {

	if { [regexp {([^\(]*)\(} $variable match arrayName] } {
		return $arrayName
	} else {
		return $variable
	} 
}
	

######################################################################
# getWindowName -- Returns the last component of a window path.  For
# example [getWindowName .frame.junk.window] returns "window".  The null
# string is returned if the windowPath does not contain a period.
######################################################################

proc getWindowName { windowPath } {

	if { [regexp {\.([^\.]*)$} $windowPath match window] } {
		return $window
	} else {
		return ""
	}
}


######################################################################
# getWindowParent -- Returns the parent of the passed window. For
# example [getWindowName .frame.junk.window] returns ".frame.junk". The
# null string is returned if the windowPath does not contain a period.
######################################################################

proc getWindowParent { windowPath } {

	if { [regexp {^(.*)\.([^\.]*)$} $windowPath match parent] } {
		return $parent
	} else {
		return ""
	}
}


proc comboBoxSetChoices { name choices } {

	# global variables
	global gComboBox
	global gBlank
	
	# delete any old choices
	$gComboBox($name,menu) delete 0 100

	# create left margin
	set leftMargin [string range $gBlank 0 $gComboBox($name,cmargin) ]

	set entryCount	0
	set colBreak 	0

	# fill the menu with the available choices
	foreach choice $choices {
      set length [string length $choice]
      set rightMargin [string range $gBlank 0 [expr $gComboBox($name,cwidth) - $length - $gComboBox($name,cmargin)] ]
		$gComboBox($name,menu) add command 						\
			-label "${leftMargin}${choice}${rightMargin}"	\
			-command "comboBoxSelect $name $choice" -columnbreak $colBreak
		incr entryCount
		set colBreak [expr ($entryCount % $gComboBox($name,cbreak) == 0)]
	}	
}


proc combo_box_set_state { name state } {

	# global variables
	global gComboBox
	global gColors
	
	if { $state == "normal" } {
		$gComboBox($name,menubutton) configure -state normal		\
			-bg $gColors(light) -activebackground $gColors(light)
	} else {
		$gComboBox($name,menubutton) configure -state disabled \
			-bg lightgrey -activebackground lightgrey
	}
}


proc comboBox { window args } {

	# global variables
	global gComboBox
	global gColors
	global gFont
	global gBitmap
	
	# assign default values
	array set parameter {		
		-choices				""		
		-width 				10				
		-type 				"" 					
		-command 			""						
		-justify 			center
		-cwidth				0
		-cmargin 			0
		-cbreak				100
		-noentry				0	
		-prompt				""
		-promptwidth		10
		-promptanchor 		e
		-name					""
		}
		
	set parameter(-font)			$gFont(small)
	set parameter(-menufont) 	$gFont(small)
	
	# assign passed parameters
	array set parameter $args

	# get parent and widget names
	set parent [getWindowParent $window]

	if { $parameter(-name) != "" } {
		set name $parameter(-name)
	} else {
		set name [getWindowName $window]
	}

   # access variable
   global [getArrayName $parameter(-variable)]
	set gComboBox($name,variable) $parameter(-variable)
	
	set gComboBox($name,command) 	$parameter(-command)	
	set gComboBox($name,cbreak)	$parameter(-cbreak)
	
	# create the frame 
	set gComboBox($name,frame) [ frame $window ]
	
	# set permanent parameters
	set gComboBox($name,cwidth) 	$parameter(-cwidth)
	set gComboBox($name,cmargin)	$parameter(-cmargin)
	
	# create the prompt if needed
	if { $parameter(-prompt) != "" } {
		pack [
			label  $window.prompt 				\
			-text  $parameter(-prompt) 		\
			-width $parameter(-promptwidth)	\
			-font  $parameter(-font)			\
			-anchor $parameter(-promptanchor)	\
		] -side left
	}
	
   # create the menubutton 
   set gComboBox($name,menubutton) [
		menubutton $window.menubutton							\
		-text					[set $parameter(-variable)	]	\
		-menu					$window.menubutton.menu			\
		-font 				$parameter(-font)					\
		-width 				$parameter(-width)				\
		-background 		$gColors(light)					\
		-activebackground $gColors(light)					\
		-highlightcolor 	$gColors(light) 					\
		-justify 			$parameter(-justify) 			\
		-relief 				sunken								\
		-pady					1										\
		-disabledforeground black								\
		]
	
	$gComboBox($name,menubutton) configure -height -1
	
	# pack the menubutton unless told otherwise
	if { $parameter(-noentry) != -1 } {
		pack $gComboBox($name,menubutton) -side left
	}
	
	# create the menu of choices
	set gComboBox($name,menu) [
		menu $window.menubutton.menu					\
			-tearoff 0										\
			-font $parameter(-menufont)				\
			-activebackground $gColors(unhighlight)\
			-background $gColors(light) 				\
			-activeborderwidth 0							\
	]
	
	
	# fill the menu with the available choices
	comboBoxSetChoices $name $parameter(-choices)	

	# create the arrow button
	pack [ set gComboBox($name,button) [
		label $window.button	\
    	-image $gBitmap(arrow) -background $gColors(unhighlight) 		\
		-width 20 -anchor c -relief raised -borderwidth 2	\
    ] ] -side left -fill y -padx 3 -pady 1
	bind $gComboBox($name,button) <Button-1> \
		"tkMbPost $gComboBox($name,menubutton) %X %Y"

	# set up trace on variable to update the button
	clearTraces $gComboBox($name,variable)
	trace variable $parameter(-variable) w \
		"comboBoxTraceVariable $name" 
	comboBoxTraceVariable $name

	# return the megawidget
	return $gComboBox($name,frame)
}

proc comboBoxTraceVariable { name args } {

	# global variables
	global gComboBox
	global [getArrayName $gComboBox($name,variable)]
	
	if { [winfo exists $gComboBox($name,menubutton)] } {
		$gComboBox($name,menubutton) configure 	\
			-text [set $gComboBox($name,variable)]
	} else {
		# otherwise clear trace
		clearTraces $gComboBox($name,variable)
	}
}

proc comboBoxSelect { name choice } {

	global gComboBox
	global [getArrayName $gComboBox($name,variable)]
	set $gComboBox($name,variable) $choice
	
	$gComboBox($name,menubutton) configure -text $choice
	if { $gComboBox($name,command) != "" } {
		eval $gComboBox($name,command) $choice
	}

}


