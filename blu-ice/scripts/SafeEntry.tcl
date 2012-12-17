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

set arrowData {#define arrow_width 16
	#define arrow_height 16
	static unsigned char arrow_bits[] = {
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfc, 0x1f,
		0xf8, 0x0f, 0xf0, 0x07, 0xe0, 0x03, 0xc0, 0x01, 0x80, 0x00, 0x00, 0x00,
		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
}
set gSafeEntry(arrow_bitmap) [image create bitmap -data $arrowData]
set gSafeEntry(blank) "                                                                                                             "

class SafeEntry {
	
	# component widget
	private variable frame
	private variable prompt
	private variable entry
	private variable menuButton
	private variable arrowButton
	private variable menu
	private variable units

	private variable type				 
	private variable lastGoodValue	 
	private variable mutex					0

	private variable parameter
	private variable referenceVariable	{}
	private variable shadowReference		false
	private variable changeCommand		{}
	private variable submitCommand		{}

	private variable columnBreak
	private variable columnWidth
	private variable columnMargin

	private variable disabledBackground

	private variable usePrompt	false
	private variable useUnits	false
	private variable useMenu	false
	private variable useEntry	false
	private variable useArrow	false

	private variable color_light 		#f0f0ff
	private variable color_unhighlight #c0c0ff
	private variable small_font *-helvetica-bold-r-normal--14-*-*-*-*-*-*-*

	public method constructor { window args }
	destructor {
		global [get_reference_array_name]
		trace vdelete gSafeEntry($frame) w "$this trace_safe_entry" 
		trace vdelete $referenceVariable w "$this trace_reference_variable"
	}
	public method update_from_reference {}
	public method set_value { newValue }
	public method get_value {}
	public method set_menu_choices { choices }
	public method set_reference_variable { ref }
	public method enable {}
	public method disable {}

	public method trace_safe_entry { args }
	public method trace_reference_variable { args }
	public method menu_item_select { choice }
	public method update_widget_colors {}
	public method get_reference_array_name {}
	public method isDifferent {}
	public method pack_this { parameters}
	public method unpack_this {}
}



body SafeEntry::constructor { window args } {

	# global variables
	global gSafeEntry

	# assign default values
	array set parameter { 

		-reference				""
		-shadow				   0
		-value					NULL

		-font 					fixed
		-type 					"" 
		-onchange				""
		-onsubmit				""
		-state					normal
	
		-prompt					""
		-promptwidth			0
		-promptanchor 			e
		-promptforeground		black
		-promptbackground		lightgrey

		-entrywidth 	  		10
		-entryforeground		black
		-justification 		right
		-relief		  			sunken
		-background				""
		-highlightthickness 	0
		-highlightcolor 		red
		-disabledbackground	""

		-units					""
		-unitswidth				3
		-unitsanchor			w
		-unitsforeground		black
		-unitsbackground		lightgrey

		-menuchoices			""		
		-menucolwidth			0
		-menucolmargin 		0
		-menucolbreak			100

		-useArrow				0
		-useMenu					0
		-useEntry				1
	}
		
	set parameter(-font)			$small_font
	set parameter(-menufont) 	$small_font
	set parameter(-entrybackground) $color_light

	# assign passed parameters
	array set parameter $args

	# create the frame to hold the SafeEntry widgets
	set frame [frame $window]

	# create variables for storing entry values
	if { $parameter(-reference) != {} } {
		set referenceVariable $parameter(-reference)
		global [get_reference_array_name]
		if { $parameter(-value) == "NULL" || $parameter(-shadow) } {
			set gSafeEntry($frame) [set $referenceVariable]
			set lastGoodValue [set $referenceVariable]
		} else {
			set gSafeEntry($frame) $parameter(-value)
			set lastGoodValue $parameter(-value) 
		}
	} else {
		if { $parameter(-value) == "NULL" } {
			set parameter(-value) 0
		}
		set gSafeEntry($frame) $parameter(-value)
		set lastGoodValue $parameter(-value)
	}

	if { $parameter(-disabledbackground) == "" } {
		set disabledBackground $color_light
	} else {
		set disabledBackground $parameter(-disabledbackground)
	}

	# create the prompt if specified
	if { $parameter(-prompt) != "" } {
		set usePrompt 1
		pack [ set prompt [
	  		label $frame.prompt 					\
		 	-text $parameter(-prompt)			\
	  	 	-width $parameter(-promptwidth)	\
		 	-fg $parameter(-promptforeground)	\
		 	-font $parameter(-font)				\
			-anchor $parameter(-promptanchor) \
			-bg $parameter(-promptbackground)] ] -side left
	}

	# check if entry will be required
	if { $parameter(-useEntry) } {
		set useEntry 1
	} else {
		set useEntry 0
	}
	
	# create menu widgets if enabled
	if { $parameter(-useMenu) } {
		
		# set menu parameters
		set useMenu 1
		set columnBreak	$parameter(-menucolbreak)	
		set columnWidth 	$parameter(-menucolwidth)
		set columnMargin	$parameter(-menucolmargin)

		# set default menu column width
		if { $columnWidth == 0 } {
			set columnWidth $parameter(-entrywidth)
		}
	  
		# translate justification to anchor position for menu button text
		set menuButtonAnchor center
		if { $parameter(-justification) == "right" } {
			set menuButtonAnchor e
		}
		if { $parameter(-justification) == "left" } {
			set menuButtonAnchor w
		}

		# create the menubutton 
		set menuButton [ menubutton $frame.menubutton				\
			-text					$gSafeEntry($frame)						\
			-menu					$frame.menubutton.menu					\
			-font 				$parameter(-font)							\
			-width 				[expr $parameter(-entrywidth)	- 1]	\
			-background 		$color_light							\
			-activebackground $color_light							\
			-highlightcolor 	$color_light 							\
			-justify 			$parameter(-justification) 			\
			-anchor				$menuButtonAnchor							\
			-relief 				$parameter(-relief)	  					\
			-pady					1												\
			-disabledforeground black										\
			]
		
		# pack the menubutton unless told otherwise
		if { $useEntry } {
			pack [frame $frame.menuButtonFrame] -side left
			pack $menuButton -in $frame.menuButtonFrame -side left
		} else {
			pack $menuButton -side left
		}

		# create the menu of choices
		set menu [ menu $frame.menubutton.menu		\
		  	-tearoff 0										\
			-font $parameter(-menufont)				\
			-activebackground $color_unhighlight	\
			-background $color_light	 				\
			-activeborderwidth 0							\
		]

		if { $parameter(-onsubmit) != "" } {
			set submitCommand $parameter(-onsubmit)
		}

		# fill the menu with the initial choices
		$this set_menu_choices $parameter(-menuchoices)	
		
		# create the arrow button if requested
		if { $parameter(-useArrow) } {
			
			# create the arrow button
			pack [ set arrowButton [ label $frame.button	\
    				-image $gSafeEntry(arrow_bitmap) -background $color_unhighlight	\
					-width 20 -anchor c -relief raised -borderwidth 2	\
				  ] ] -side left -fill y -padx 3 -pady 1

			# bind menu posting to button click
			bind $arrowButton <Button-1> \
				"tkMbPost $menuButton %X %Y"
		}
	} else {
		set useMenu 0
	}

   # create the entry subwidget if enabled 
	if { $useEntry } {

		# create the entry field itself
		set entry [ entry $frame.entry			\
			-textvariable gSafeEntry($frame)		\
			-font $parameter(-font)					\
			-width $parameter(-entrywidth)		\
			-state $parameter(-state)				\
			-relief $parameter(-relief)			\
			-justify $parameter(-justification) \
		   -background $parameter(-entrybackground) \
			-highlightcolor $parameter(-highlightcolor) \
			-highlightthickness $parameter(-highlightthickness) \
			-foreground $parameter(-entryforeground) \
		]
	  
	  if { ! $useMenu } {
		  pack $entry -side left
	  } else {
		  place $entry -in $frame.menuButtonFrame -x 0 -y 0
	  }
	  
		# configure background if needed
		if { $parameter(-background) != "" } {
			$gSafeEntry($name,entry) configure -background $parameter(-background)
		}
	
		# set up on-submit event
		if { $parameter(-onsubmit) != "" } {
			set submitCommand $parameter(-onsubmit)
			bind $entry <FocusOut> $submitCommand
			bind $entry <Return> $submitCommand
		}

		# set up on-change event
		if { $parameter(-onchange) != "" } {
			set changeCommand $parameter(-onchange)
		}
		
		# set up the tracing on the variable if needed
		if { $parameter(-type) != "" || $parameter(-reference) != "" } {
			set type $parameter(-type)
			clearTraces gSafeEntry($frame)
			trace variable gSafeEntry($frame) w "$this trace_safe_entry"		
		}
	}
	
	#Need an on-change event even if $useEntry==0 and $useMenu==1
	# set up on-change event
	if { $parameter(-onchange) != "" } {
		set changeCommand $parameter(-onchange)
	}
	
	# create the units if specified
	if { $parameter(-units) != "" } {
		set useUnits 1
		pack [ set units [
			label $frame.units 					\
			-text $parameter(-units)			\
			-width $parameter(-unitswidth)	\
			-fg $parameter(-unitsforeground)	\
			-font $parameter(-font)				\
			-anchor $parameter(-unitsanchor) \
			-bg $parameter(-unitsbackground) ] ] -side left
	}

	# set up shadowing of reference variable if needed
	if { $parameter(-reference) != {} } {
		trace variable $referenceVariable w "$this trace_reference_variable"
		if { $parameter(-shadow) } {
			set shadowReference 1
		}
	}
}


body SafeEntry::update_widget_colors {} {

	# nothing to do if no reference variable defined
	if { $referenceVariable == "" } {
		return
	}

	# global variables
	global gSafeEntry
	global [get_reference_array_name]

	# set widget foregrounds to red if different from reference variable
	if { $gSafeEntry($frame) == [set $referenceVariable] } {
		
		if { $useEntry } {
			$entry configure -fg black
		}
		
		if { $useMenu } {
			$menuButton configure -fg black -activeforeground black -disabledforeground black
		}

	} else {

		if { $useEntry } {
			$entry configure -fg red
		}

		if { $useMenu } {
			$menuButton configure -fg red -activeforeground red -disabledforeground red
		}	 
	}
}


body SafeEntry::get_value {} {

	# global variables
	global gSafeEntry
	
	return $gSafeEntry($frame)
}


body SafeEntry::set_value { newValue } {

	# global variables
	global gSafeEntry

	# update the last good value
	set lastGoodValue $newValue
	
	# update the entry widget	
	set gSafeEntry($frame) $newValue
	
	# update the menu button if visible
	if { ! $useEntry } {
		$menuButton configure -text $newValue
	}

	# update widget colors
	update_widget_colors

	# execute event handler for dynamic entry value changes
	if { $changeCommand != {} } {
		eval $changeCommand
	}
	
}


body SafeEntry::set_reference_variable { refname } {
	global [get_reference_array_name]

	#delete old reference variable if it exists
	if { $parameter(-reference) != {} } {
		#log_note [trace vinfo $referenceVariable]
		trace vdelete $referenceVariable w "$this trace_reference_variable"
	}

	# store the new reference variable name
	set referenceVariable $refname

	# access the variable
	global [get_reference_array_name]

	# update widget values if shadowing
	if { $shadowReference } {
		set_value [set $referenceVariable]
		#need to execute the change command every time widget is updated
		# execute event handler for dynamic entry value changes
		#if { $changeCommand != {} } {
		#	eval $changeCommand
		#}
	} else {
		update_widget_colors
	}
}


body SafeEntry::trace_reference_variable { args } {

	# global variables
	global gSafeEntry
	global [get_reference_array_name]

	# update widget values if shadowing
	if { $shadowReference } {
		set_value [set $referenceVariable]
		#need to execute the change command every time widget is updated
		# execute event handler for dynamic entry value changes
		#if { $changeCommand != {} } {
		#	eval $changeCommand
		#}

	} else {
		update_widget_colors
	}
}


body SafeEntry::update_from_reference {} {

	global [get_reference_array_name]

	set_value [set $referenceVariable]
	#need to execute the change command every time widget is updated
	# execute event handler for dynamic entry value changes
	#if { $changeCommand != {} } {
	#	eval $changeCommand
	#}

}



body SafeEntry::trace_safe_entry { args } {

	# global variables
	global gSafeEntry

	if { $referenceVariable != "" } {
		update_widget_colors
	}

	# accept new value and return if not entered via entry
	if { [focus] != $entry } {
		set lastGoodValue $gSafeEntry($frame)
		return
	}

	# return if mutex taken, otherwise take the mutex
	if { $mutex } {
		return
	} else {
		set mutex 1
	}

	# store the value and execute command if value is correct type or blank
	if {  $type == {} || $type == "string" || $gSafeEntry($frame) == {} || [is_incomplete_${type} $gSafeEntry($frame)] } {
		
		# update the last good value
		set lastGoodValue $gSafeEntry($frame)
		
		# execute event handler for dynamic entry value changes
		if { $changeCommand != {} } {
			catch [eval $changeCommand]
		}
	} else {

		# otherwise restore previous value
		set gSafeEntry($frame) $lastGoodValue
		tkEntrySetCursor $entry [expr [$entry index insert] - 1]
	}	

	if { $referenceVariable != "" } {
		update_widget_colors
	}
	
	if { $useMenu } {
		$menuButton configure -text $lastGoodValue
	}

	# release the mutex
	set mutex 0
}


body SafeEntry::set_menu_choices { choices } {

	# global variables
	global gSafeEntry

	# delete any old choices
	$menu delete 0 100

	# create left margin
	set leftMargin [string range $gSafeEntry(blank) 0 $columnMargin ]

	set entryCount	0
	set colBreak 	0

	# fill the menu with the available choices
	foreach choice $choices {
      set length [string length $choice]
      set rightMargin [string range $gSafeEntry(blank) 0 [expr $columnWidth - $length - $columnMargin] ]
		$menu add command 						\
			-label "${leftMargin}${choice}${rightMargin}"	\
			 -command "$this menu_item_select \{$choice\}" -columnbreak $colBreak
		incr entryCount
		set colBreak [expr ($entryCount % $columnBreak == 0)]
	}	
}


body SafeEntry::menu_item_select { choice } {

	# global variables 
	global gSafeEntry

	# update the entry widget	
	set gSafeEntry($frame) $choice
	set lastGoodValue $choice

	# update the menu button if visible
	if { $useMenu } {
		$menuButton configure -text $choice
	}

	# call the change handler
	if { $changeCommand != {} } {
		eval $changeCommand
	}
	
	# call the submit handler
	if { $submitCommand != {} } {
		eval $submitCommand
	}

	# update colors
	if { $referenceVariable != "" } {
		update_widget_colors
	}
}


body SafeEntry::enable {} {

	if { $useEntry } {
		$entry configure -state normal -bg $color_light
	}

	if { $useMenu } {
		$menuButton configure -state normal		\
			-bg $color_light -activebackground $color_light
	}

}

body SafeEntry::disable {} {
	
	if { $useEntry } {		
		$entry configure -state disabled -bg $disabledBackground
	}

	if { $useMenu } {
		$menuButton configure -state disabled \
			-bg $disabledBackground -activebackground $disabledBackground
	}
}


######################################################################
# getArrayName -- Returns the name of the Tcl array associated
# with the passed variable.  For example [getArrayName junk(index)]
# returns "junk".  If the variable is not an array, the passed
# variable name is simply returned.
######################################################################

body SafeEntry::get_reference_array_name {} {

	if { [regexp {([^\(]*)\(} $referenceVariable match arrayName] } {
		return $arrayName
	} else {
		return $referenceVariable
	} 
}

body SafeEntry::isDifferent {} {
	# global variables
	global gSafeEntry
	global [get_reference_array_name]
	
	if { $gSafeEntry($frame) == [set $referenceVariable]} {
		return 0
	} else {
		return 1
	}
}

body SafeEntry::unpack_this {} {

	pack forget $frame

}

body SafeEntry::pack_this { parameters } {
	set pack_command [concat pack $frame $parameters]
	eval $pack_command
}
