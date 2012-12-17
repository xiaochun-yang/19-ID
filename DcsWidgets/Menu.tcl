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

# provide the BIWMenu package
package provide DCSMenu 1.0

# load standard packages
package require BLT
package require Iwidgets
package require BWidget

# load other BIW packages
package require DCSUtil


##########################################################################

class DCS::Menu {

	# constructor
	constructor { path } {
		set tkMenu [menu $path \
							-tearoff 0 \
							-activeborderwidth 0 \
							-activebackground $activebackground \
							-background $background ]
	}

	destructor {

		# individually delete each menu entry
		foreach menuEntry [array names entry] {
			deleteEntry $menuEntry
		}
	}

	# public variables (accessed using configure)
	public variable background lightgrey
	public variable activebackground white

	# protected data
	public variable tkMenu
	protected variable entry
	protected variable cascadeMenu

	# public member functions
	public method addLabel { name args }
	public method addCommand { name args }
	public method addCheckbox { name args }
	public method addCascade { name  args }
	public method addSeparator { name }
	public method configureEntry { name args }
	public method deleteEntry { name }

	# protected member functions
	protected method addEntry { name newEntry }
}

configbody DCS::Menu::background {

	$tkMenu configure -background $background
}


configbody DCS::Menu::activebackground {

	$tkMenu configure -activebackground $activebackground
}


body DCS::Menu::addEntry { name newEntry } {
	set entry($name) $newEntry
}


body DCS::Menu::addLabel { name args } {

	# create the label and store the object name in the entry list
	set command "DCS::MenuLabel \#auto $tkMenu $args"
	addEntry $name [eval $command]
}


body DCS::Menu::addCommand { name args } {

	# create the MenuCommand and store the object name in the entry list
	set command "DCS::MenuCommand \#auto $tkMenu $args"
	addEntry $name [eval $command]
}


body DCS::Menu::addCheckbox { name args } {
	
	set command "DCS::MenuCheckbox \#auto $tkMenu $args"
	addEntry $name [eval $command]
}


body DCS::Menu::addCascade { name args } {

	set cascadeMenu($name) [uplevel \#0 DCS::Menu \#auto $tkMenu.[DCS::getUniqueName]]
	set childTkMenu [uplevel \#0 $cascadeMenu($name) cget -tkMenu]

	# create the MenuSeparator and store the object name in the entry list
	set command  "DCS::MenuCascade \#auto $tkMenu $childTkMenu $args"
	addEntry $name [eval $command]

	return $cascadeMenu($name)
}


body DCS::Menu::addSeparator { name } {

	# create the MenuSeparator and store the object name in the entry list
	addEntry $name [DCS::MenuSeparator \#auto $tkMenu ]
}


body DCS::Menu::configureEntry { name args } {

	eval $entry($name) configure $args
}


body DCS::Menu::deleteEntry { name } {

	# destroy the entry itself
	delete object $entry($name)

	# delete the cascade menu if necessary
	if { [info exists cascadeMenu($name)] } {
		uplevel \#0 delete object $cascadeMenu($name)
	}
	
	# delete the entry from the entry array 
	unset entry($name)
}



##########################################################################

class DCS::ButtonMenu {

	# inheritance
	inherit DCS::Menu

	# constructor
	constructor { parent args } {

		# create the tk menubutton
		set tkMenuButton [menubutton $parent.[DCS::getUniqueName]]

		# specify the name of the associated tk menu
		$tkMenuButton configure -menu $tkMenuButton.menu

		# call the base class constructor passing the desired tk menu path
		DCS::Menu::constructor $tkMenuButton.menu

		# pack the tk menu button in the passed parent window
		pack $tkMenuButton -in $parent

		# handle configuration options
		eval configure $args
	} {
	}

	# destructor
	destructor {

		# first destroy the base class including the menu entries
		DCS::Menu::destructor

		# then destory the tk menu button
		destroy $tkMenuButton
	}

	# public data (accessed via configure command)
	public variable label "" { $tkMenuButton configure -text $label }

	# protected data
	protected variable tkMenuButton
}


##########################################################################

class DCS::PopupMenu {

	# inheritance
	inherit DCS::Menu

	# constructor
	constructor { args } {

		# call the base class constructor passing a unique name for the menu
		DCS::Menu::constructor .popup[DCS::getUniqueName]

		# handle configuration options
		eval configure $args
	} {
	}

	# public member functions
	public method post {}
}


body DCS::PopupMenu::post {} {

	# post the popup menu at the current mouse pointer coordinates
	tk_popup $tkMenu [winfo pointerx .] [winfo pointery .]

}



##########################################################################

class DCS::MenuField {

	# constructor
	constructor { menu args } {

		# store the name of the tk menu
		set tkMenu $menu

		# search for -before option tag in configuration options list
		set beforeIndex [lsearch $args "-before" ]                  
		if { $beforeIndex != -1 } {
			set before [lindex $args [expr $beforeIndex + 1]]
			if { [llength $before] == 1 } {
				set before [$tkMenu index [lindex $before 0] ]
			} else {
				set before [expr [$tkMenu index [lindex $before 0]] + [lindex $before 1] ]
			}
		}
	}

	# destructor
	destructor {
		# delete the entry from the menu by label if it has a label
		if { $label != "DefaultLabel" } {
			$tkMenu delete $label
		}
	}

	# public variables (accessed via configure command)
	public variable label "DefaultLabel"
	public variable state 
	public variable foreground "black"
	public variable activeforeground "black"
	public variable columnbreak 0
	public variable before end

	# protected data
	protected variable tkMenu
	protected variable oldLabel "DefaultLabel"
}


configbody DCS::MenuField::label { 
	
	$tkMenu entryconfigure $oldLabel -label $label 
	set oldLabel $label
}


configbody DCS::MenuField::state {

	$tkMenu entryconfigure $label -state $state
}


configbody DCS::MenuField::foreground {

	$tkMenu entryconfigure $label -foreground $foreground
}


configbody DCS::MenuField::activeforeground {

	$tkMenu entryconfigure $label -activeforeground $activeforeground
}


configbody DCS::MenuField::columnbreak {

	$tkMenu entryconfigure $label -columnbreak $columnbreak
}


##########################################################################

class DCS::MenuLabel {

	# inheritance
	inherit DCS::MenuField

	# constructor
	constructor { menu args } {
		
		# call the base class constructor
		eval DCS::MenuField::constructor $menu $args
	} {
		# add a command to the tk menu
		$tkMenu insert $before command -label $label -activebackground lightgrey

		# handle configuration options
		eval configure $args
	}
}



##########################################################################

class DCS::MenuCommand {

	# inheritance
	inherit DCS::MenuField

	# constructor
	constructor { menu args } {
		
		# call the base class constructor
		eval DCS::MenuField::constructor $menu $args
	} {
		# add a command to the tk menu
		$tkMenu insert $before command -command $command -label $label

		# handle configuration options
		eval configure $args
	}

	# public variables (accessed via configure command)
	public variable command "" { $tkMenu entryconfigure $label -command $command }
}


##########################################################################

class DCS::MenuCheckbox {

	# inheritance
	inherit DCS::MenuField

	# constructor
	constructor { menu args } {
		
		# call base class constructor 
		eval DCS::MenuField::constructor $menu $args

	} {
		# get a unique variable name in the global name space
		set checkboxVariable check[DCS::getUniqueName]

		# initialize the checkbox variable
		set ::$checkboxVariable 0

		# add the checkbox entry to the tk menu
		$tkMenu insert $before check -command "$this update" \
			-variable ::$checkboxVariable \
			-state normal \
			-label $label

		# handle configuration options
		eval configure $args
	}
	
	# destructor
	destructor {
		unset ::$checkboxVariable
	}

	# public variables (accessed via configure command)
	public variable callback ""
	public variable value 0
	
	# private variables
	private variable checkboxVariable

	# public member functions
	public method update {}
}


# the checkbox calls this function everytime the checkbox value changes
body DCS::MenuCheckbox::update {} {
	
	# make an internal copy of the global checkbox variable
	set value [set ::$checkboxVariable]

	# pass the value to the callback function if specified
	if { $callback != "" } {
		eval $callback $value
	}
}


configbody DCS::MenuCheckbox::value {

	# set the variable associated with the checkbox to the new value
	set ::$checkboxVariable $value

	# pass the value to the callback function if specified
	if { $callback != "" } {
		eval $callback $value
	}
}


##########################################################################

class DCS::MenuSeparator {

	# inheritance
	inherit DCS::MenuField

	# constructor
	constructor { menu args } {
		
		# call the base class constructor
		eval DCS::MenuField::constructor $menu $args
	} {
		# add a command to the tk menu
		$tkMenu insert $before separator

		# handle configuration options
		eval configure $args
	}
}


##########################################################################

class DCS::MenuCascade {

	# inheritance
	inherit DCS::MenuField

	# constructor
	constructor { parentTkMenu childTkMenu args } {
		
		# call the base class constructor
		eval DCS::MenuField::constructor $parentTkMenu $args
	} {
		# add the cascade to the tk menu
		$tkMenu insert $before cascade -menu $childTkMenu -label $label

		# handle configuration options
		eval configure $args
	}

	# protected variables
	protected variable menu
}



proc testMenu {} {
	# create the main graph popup menu
	set graphMenu [DCS::PopupMenu \#auto]
	$graphMenu addLabel title -label "Plotting Region"
	$graphMenu addSeparator sep1
	$graphMenu addCheckbox grid -label "Show grid"  -value 1
	$graphMenu addCommand zoomout -label "Zoom Out" -command "puts zoomOut"
	$graphMenu addCommand zoomout -label "View All" -command "puts zoomOutAll"
	$graphMenu addSeparator sep2
	$graphMenu addCommand open -label "Open" -command "puts handleFileOpen"
	$graphMenu addCommand save -label "Save" -command "puts handleFileSave"
	$graphMenu addCommand print -label "Print" -command "puts print"
	#$graphMenu addCommand printSetup -label "Print Setup" -command "$this printSetup"
	$graphMenu addCommand deleteAll -label "Delete All Traces" -command "puts deleteAllTraces"

	puts $graphMenu

	bind . <1> [list $graphMenu post]

}

#testMenu
