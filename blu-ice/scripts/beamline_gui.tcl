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


######################################################################
# create_top_window -- creates and configures the top level window
######################################################################

proc create_top_window {} {

	# global variables
	global gScan
	global gBeamline
	
	# indicate that we are running full blc gui
	set gScan(standalone) 0

	# make top level window horizontally resizable only 
	wm resizable . 1 1
	
	# set size and initial position of top level window
	wm geometry . =1000x740+100+100

	# set the name of the icon
	wm iconname . "BLU-ICE"

	# set the title for the GUI
	wm title . $gBeamline(title)
}



######################################################################
# create_main_windows -- creates and packs the main windows
######################################################################

proc create_main_windows {} {

	# global variables
	global gWindows
	global gColors

	# create the main menu
	set gWindows(menu,frame) [	frame .menu \
											 -height 30 \
											 -borderwidth 2 \
											 -relief raised \
											 -background $gColors(unhighlight) ]
	pack $gWindows(menu,frame) \
		 -fill x

	# create each menu
	ice_create_file_menu
	ice_create_component_menu
	ice_create_shutter_menu
	ice_create_network_menu
	ice_create_view_menu
	ice_create_options_menu
#	ice_create_window_menu
	ice_create_help_menu
	
	# create the main windows 
	create_status_window
	create_folder_window
	create_command_entry_window
	create_log_window
	
	# set up global bindings
	bind all <Control-c> {do abort soft}
	bind all <Control-y> {do abort hard}
}


proc create_folder_tabs {} {

	# global variables
	global gWindows

	construct_collect_window
	construct_setup_window

	# set up the hutch tab
	HutchTab \#auto $gWindows(Hutch,frame)
	
	# set up user scan window
	UserScanWindow userScanWindow $gWindows(Scan,frame)

	construct_client_window
}


######################################################################
# ice_create_file_menu -- creates the File menu and its entries
######################################################################

proc ice_create_file_menu {} {

	global gWindows

	# create the file menu button
	set menu [create_main_menu_entry file File left 0]
	
	# add commands to the file menu
	
	$menu add command -label "Print configuration" \
		-command "do print_all_motor_positions"
	
	$menu add command -label "Load configuration" \
		-command {load_configuration}
	
	$menu add command -label "Save configuration" \
		-command {save_current_configuration}
			
	$menu add separator
	
	$menu add command -label "Load scan (staff only)" \
		-command {null_function} -command "load_scan_dialog"
			
	$menu add separator
	
	$menu add command -label "Load energy scan" \
		 -command {$gWindows(notebook) select [$gWindows(notebook) index "Scan"]; userScanWindow load}

	$menu add command -label "Save energy scan" \
		 -command {$gWindows(notebook) select [$gWindows(notebook) index "Scan"]; userScanWindow save}

	$menu add command -label "Print energy scan" \
		 -command {$gWindows(notebook) select [$gWindows(notebook) index "Scan"]; userScanWindow print}

	$menu add separator
	
	$menu add command -label "Exit" -underline 1	\
		-command {exit}
}


proc create_status_window {} {

	# global variables
	global gWindows
	global gColors
	global gFont
	
	# create the status frame
	pack [ set gWindows(status,frame) [ 	\
		frame .status -height 25 -borderwidth 2 -relief sunken \
		-background $gColors(midhighlight) -borderwidth 0] ] \
		-fill x -side bottom

	# the time widget
	pack [ set gWindows(timefield) [iwidgets::timefield $gWindows(status,frame).timefield \
		-relief flat -textbackground $gColors(midhighlight)  \
		-textfont $gFont(small) ]] -side right
	update_timefield

	# the shutter status widget
	pack [ set gWindows(shutterStatusFrame) [	\
		frame $gWindows(status,frame).shutterFrame ]] -side right -padx 10
	pack [ set gWindows(shutterStatusLabel) [	\
		label $gWindows(status,frame).shutterFrame.shuttertext -text "Shutter: " \
		-font $gFont(small) -background $gColors(midhighlight)]] -side left
	pack [ set gWindows(shutterStatus) [	\
		label $gWindows(status,frame).shutterFrame.shutter -textvariable gDevice(shutterStatusText) \
		-font $gFont(small) -background $gColors(midhighlight) -relief sunken \
		-width 7 -justify c]] -side left
	 bind $gWindows(status,frame).shutterFrame.shutter <1> "toggle_shutter shutter" 
	 bind $gWindows(status,frame).shutterFrame.shuttertext <1> "toggle_shutter shutter" 

	# the network status widget
	set gWindows(networkStatusText) "Offline"
	pack [ set gWindows(networkStatusFrame) [	\
		frame $gWindows(status,frame).networkFrame ]] -side right -padx 10
	pack [ set gWindows(networkStatusLabel) [	\
		label $gWindows(status,frame).networkFrame.networktext -text "Network: " \
		-font $gFont(small) -background $gColors(midhighlight)]] -side left
	pack [ set gWindows(networkStatus) [	\
		label $gWindows(status,frame).networkFrame.network -textvariable gWindows(networkStatusText) \
		-font $gFont(small) -background $gColors(midhighlight) -relief sunken \
		-width 7 -justify c]] -side left
	bind $gWindows(status,frame).networkFrame.network <1> "toggle_masterhood" 
	bind $gWindows(status,frame).networkFrame.networktext <1> "toggle_masterhood"

	# the energy status widget
	pack [ set gWindows(energyStatusFrame) [	\
		frame $gWindows(status,frame).energyFrame ]] -side right -padx 10
	pack [ set gWindows(energyStatusLabel) [	\
		label $gWindows(status,frame).energyFrame.energytext -text "Energy:" \
		-font $gFont(small) -background $gColors(midhighlight)]] -side left
	pack [ set gWindows(energyStatus) [	\
		label $gWindows(status,frame).energyFrame.network \
		-textvariable gDevice(energy,scaledDisplay) -fg red \
		-font $gFont(small) -background $gColors(midhighlight) \
		-width 8 -justify c -relief sunken]] -side left
	pack [ set gWindows(energyUnits) [	\
		label $gWindows(status,frame).energyFrame.energyunits -text "eV" \
		-font $gFont(small) -background $gColors(midhighlight) -width 4\
		-textvariable gDevice(energy,currentScaledUnits) -anchor w]] -side left
	bind $gWindows(energyUnits) <1> "handleScaledValueDoubleClick energy"
	bind $gWindows(energyStatus) <1> "handleScaledValueDoubleClick energy"
	bind $gWindows(energyStatusLabel) <1> "handleScaledValueDoubleClick energy"

	# the data collection status widget
	set gWindows(runsStatusText) "Idle"
	pack [ set gWindows(runsStatusFrame) [	\
		frame $gWindows(status,frame).runsFrame ]] -side left -padx 10
	pack [ set gWindows(runsStatusLabel) [	\
		label $gWindows(status,frame).runsFrame.runstext -text "" \
		-font $gFont(small) -background $gColors(midhighlight)]] -side left
	pack [ set gWindows(runsStatus) [	\
		label $gWindows(status,frame).runsFrame.runs -textvariable gWindows(runsStatusText) \
		-font $gFont(small) -background $gColors(midhighlight) -relief sunken \
		-width 30 -justify c]] -side left
}

proc create_command_entry_window {} {

	# global variables
	global gWindows
	global gColors
	global gFont
	
	
	# the command entry window
	pack [ set gWindows(command,frame) [ 	\
		frame $gWindows(paned,frame).command -borderwidth 2 -relief groove -height 20 ] ] -fill x 
		
	# the command entry itself
	pack [ set gWindows(command,prompt) [ \
		button $gWindows(command,frame).prompt -text "Command" \
		-background white \
		-padx 1 -pady 2 \
		-state disabled \
      -disabledforeground $gColors(verydark) \
      -font verytiny ] ] \
		-side left

	# the command entry itself
	pack [ set gWindows(command,entry) [ \
		entry $gWindows(command,frame).entry -textvariable gWindows(command,command) \
		-background white] ] \
		-side left -expand 1 -fill both

	bind $gWindows(command,entry) <Return> 	do_typed_command
	bind $gWindows(command,entry) <Up>			do_history_up
	bind $gWindows(command,entry) <Down>		do_history_down
	
	bind $gWindows(command,entry) <Control-a> {
		set i [$gWindows(command,entry) index insert];
		$gWindows(command,entry) insert $i $gFont(angstrom); 
		break
		}

	bind $gWindows(command,entry) <Control-m> {
		set i [$gWindows(command,entry) index insert];
		$gWindows(command,entry) insert $i $gFont(micro); 
		break
		}
	
	initialize_history

	#default is disabled
	pack forget $gWindows(command,frame)
}

proc create_log_window {} {

	# global variables
	global gWindows
	global gColors
	global gFont

	set gWindows(text,text) [ scrolledText $gWindows(text,frame).scrolling_area	\
		-font "*-helvetica-medium-r-normal--18-*-*-*-*-*-*-*" -background white 	\
		-state disabled ]

	$gWindows(text,text) tag add input 1.0 end
	$gWindows(text,text) tag configure input -foreground black \
		-font "*-*-*-i-*--18-*-*-*-*-*-*-*"
	$gWindows(text,text) tag add output 1.0 end
	$gWindows(text,text) tag configure output -foreground $gColors(text)
	$gWindows(text,text) tag add error 1.0 end
	$gWindows(text,text) tag configure error -foreground $gColors(error)
	$gWindows(text,text) tag add warning 1.0 end
	$gWindows(text,text) tag configure warning -foreground $gColors(warning)
	$gWindows(text,text) tag add note 1.0 end
	$gWindows(text,text) tag configure note -foreground $gColors(note)
}


proc create_folder_window {} {

	# global variables
	global gWindows
	global gColors
	global gFont
	
	# the paned window holding the mdw and text windows
	set gWindows(paned,frame) [ frame .paned -height 670 ]

	# pack the paned window
	pack $gWindows(paned,frame) \
		 -expand yes \
		 -fill both
 
	# create the frame to contain the main tabbed folder notebook
	set gWindows(folder,frame) [frame $gWindows(paned,frame).folder \
		-relief sunken -borderwidth 2 ]
 
	# create the frame to contain the text log window
	set gWindows(text,frame) [frame $gWindows(paned,frame).text \
		-relief flat ]

	# place the notebook and log window frames into the paned window
	panedWindow $gWindows(paned,frame) $gWindows(folder,frame) $gWindows(text,frame) \
		-percent .96 -gripcolor $gColors(unhighlight)

	# create the tabbed notebook status object
	TabbedNotebookStatus mainTabbedNotebookStatus

	# create the main tabbed notebook
	set gWindows(notebook) [ iwidgets::tabnotebook $gWindows(folder,frame).notebook \
				 -backdrop $gColors(highlight5) \
				 -tabforeground $gColors(dark) \
				 -tabpos n \
				 -angle 20 \
				 -width 900 \
				 -height 800 \
				 -raiseselect 1 \
				 -bevelamount 4 ]

	# pack the notebook
	pack $gWindows(notebook) \
		 -expand yes \
		 -fill both

	# create the main tabs 
	#gw foreach tab { Hutch Collect Scan Users Setup } 
	foreach tab { Hutch Collect Scan Users Setup } {

		# add the tab
		$gWindows(notebook) add \
			 -label $tab \
			 -command "mainTabbedNotebookStatus configure -activeTab $tab"

		# store the child frame for later use
		set gWindows($tab,frame) [$gWindows(notebook) childsite $tab]
	}

	# select the Hutch tab
	$gWindows(notebook) select [$gWindows(notebook) index "Hutch"]
}



proc update_timefield {} {

	# global variables
	global gWindows	
	
	[$gWindows(timefield) component time] configure -state normal
	$gWindows(timefield) show
	[$gWindows(timefield) component time] configure -state disabled
	#update_polled_motors

	after 1000 update_timefield
}


######################################################################
# create_component_menu -- creates the component menu and its entries
######################################################################

proc ice_create_component_menu {} {

	# global variables
	global gDevice
	
	# create the component menu button
	set gMenu(component) [create_main_menu_entry component Component left 0]	

	# add components to menu
	foreach {label component} $gDevice(components) {
		$gMenu(component) add command -label $label \
			-command "show_mdw_document $component"
	}
}


proc add_component_menu_entry { label component } {

	# global variables
	global gDevice
	
	lappend gDevice(components) $label $component
}


######################################################################
# create_network_menu -- creates the network menu and its entries
######################################################################

proc ice_create_network_menu {} {

	# global variables
	global gWindows

	# create the component menu button
	set menu [create_main_menu_entry network Network left 0]
	
	$menu add command -label "Become master" \
		 -command { dcss sendMessage "gtos_become_master noforce" } \
		 -state disabled
	
	$menu add command -label "Become master by force" \
		 -command { dcss sendMessage "gtos_become_master force" }
	
	$menu add command -label "Become slave" \
		 -command { dcss sendMessage "gtos_become_slave" } \
		 -state disabled
		
	set gWindows(networkMenu) $menu
}

######################################################################
# create_shutter_menu -- creates the shutter menu and its entries
######################################################################
	
proc ice_create_shutter_menu {} {

	# global variables
	global gMenu

	# create the action menu button
	set menu [create_main_menu_entry shutter Shutter left 0]

	$menu add command -label "Open shutter" \
		-command "do open_shutter shutter"

	$menu add command -label "Close shutter" \
		-command "do close_shutter shutter"

	set gMenu(shutter) $menu
}



######################################################################
# create_shutter_menu -- creates the Shutter menu and its entries
######################################################################

proc ice_create_view_menu {} {

	# global variables
	global gWindows

	# create the view menu button
	set menu [create_main_menu_entry view View left 0]

	# add the show status button
	$menu add command -label "Show Motors Status" \
		-command "pop_motors_status"

	# add the reset status button
	$menu add command -label "Reset Current Motor" \
		-command {do "reset_motor"}

	# add the reset status button
	$menu add command -label "Reset All Motors" \
		-command {do "reset_motor all"}
}


######################################################################
# create_options_menu -- creates the Options menu and its entries
######################################################################

proc ice_create_options_menu {} {

	# global variables
	global gWindows
	global gCommandPrompt
	global gDebugComments

	# create the options menu button
	set menu [create_main_menu_entry options Options left 0]

	# add the poll ion chambers option
	$menu add check -label "Poll Ion Chambers" \
		-variable gScan(poll)

	# add the define scan options menu
	$menu add cascade -label "Define Scan"	\
		-menu [create_define_scan_options_menu $menu.defineScan]

	$menu add check -label "Command Prompt" \
		-variable gCommandPrompt -command enable_command_entry_window
	
	$menu add check -label "Display Diagnostic Messages" \
		-variable gDebugComments

	# add the show status button
	$menu add command -label "Display last image" \
		-command "requestLastImage"
}

proc enable_command_entry_window {  } {
	global gWindows
	global gCommandPrompt
	global commandEnabled
	
	#this routine has been called before
	if { $gCommandPrompt == 1} {
		pack $gWindows(command,frame)  -fill x -before $gWindows(text,text)
	} else {
		pack forget $gWindows(command,frame)
	}
}

######################################################################
# create_window_menu -- creates the window menu.  Its entries are 
# created and managed by the mdw_lib routines.
######################################################################

proc ice_create_window_menu {} {

	# global variables
	global gWindows

	# make the menubar button
	menubutton $gWindows(menu,frame).window	\
		-text "Window"									\
		-menu $gWindows(menu,frame).window.m	\
		-underline 0
		
	# pack menubar button onto menubar
	pack $gWindows(menu,frame).window			\
		-side left -padx 2
}


######################################################################
# create_help_menu -- creates the help menu and its entries
######################################################################

proc ice_create_help_menu {} {

	# global variables
	global BLC_IMAGES

	# create the help menu button
	set menu [create_main_menu_entry help Help right 0]

	$menu add command -label "Support Staff" \
		 -command {exec netscape http://smb.slac.stanford.edu/public/php/staffpage.php & }

	$menu add command -label "BLU-ICE Manual" \
		 -command {exec netscape http://smb.slac.stanford.edu/public/datacollect/BluIce/ & }

	$menu add command -label "MAD Data Collection Help" \
		 -command {exec netscape http://smb.slac.stanford.edu/public/datacollect/mad_collect.html & }

	$menu add separator

	$menu add command -label "About BLU-ICE" \
		 -command "create_splash_screen $BLC_IMAGES/splash.gif; after 10000 destroy_splash_screen"
}


######################################################################
# create_main_menu_entry -- Creates a main menu entry based on the 
# arguments.  First makes the menubutton, packs it, and then makes
# the menu associated with the menu button.  Returns the menu widget.
######################################################################

proc create_main_menu_entry { name text side under } {

	# global variables
	global gWindows
	
	# derive the menu name
	set menu $gWindows(menu,frame).$name.${name}Menu
	
	# make the menubar button
	eval "menubutton $gWindows(menu,frame).$name	\
		-text $text											\
		-menu $menu											\
		-underline $under"
	
	# pack menubar button onto menubar
	pack $gWindows(menu,frame).$name	\
		-side $side -padx 2
		
	# make the menu itself
	menu $menu -tearoff 0
	
	# return the new menu for convenience of caller
	return $menu
}	
	

class TabbedNotebookStatus {

	# inheritance
	inherit Component	

	public variable activeTab 	"" 		{updateRegisteredComponents activeTab }

	# constructor
	constructor { args } {

		# call base class constructor
		Component::constructor { 	
			activeTab 				{cget -activeTab} \		 
		}
	} {
		eval configure $args
	}
}

