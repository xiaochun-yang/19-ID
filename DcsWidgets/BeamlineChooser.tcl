###################################################################
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
###################################################################

# login.tcl provides Dialog_Login method which brings up a dialog box
# for the user to type in a password and get back a session id.
#
# Example:
# set chooseDialog [DCS::ChooseBeamline]
# $chooseDialog wait
#
# load standard packages

package provide DCSBeamlineChooser 1.0
package require DCSTitledFrame

package require Iwidgets

# Requires these two source files
package require http

set _beamlineDialogWait 0

class DCS::BeamlineChooser {
	inherit itk::Widget
	
	public method handleOk
	public method handleCancel
	public method wait
	public method isOk
	public method getBeamline { } { return $m_beamline }
   public method handleDoubleClick 

	private method handleListSelection
	private variable m_beamline
	private variable m_ok

    private variable m_title Beaemline

	
	constructor { beamlineList {title Beamline} } {
		global env

        set m_title $title
		
		itk_component add frame {
			DCS::TitledFrame $itk_interior.label 
		} {}
		
		set cs [$itk_component(frame) childsite]

		pack $cs -expand 1 -fill both
		
		itk_component add blLabel {
			label $cs.blLabel -text "Available ${m_title}s"
		} {}
 
		itk_component add blListbox {
			::iwidgets::scrolledlistbox $cs.blListbox
		} {}

		itk_component add selectedLabel {
			label $cs.selectedLabel -text "Selected $m_title"
		} {}
 
		itk_component add selectedEntry {
			label $cs.selectedEntry -text "" -bg gray -relief sunken -justify left
		} {}

		set buttonFrame [frame $cs.bf] 

		itk_component add ok {
			button $buttonFrame.ok -text "Ok" -state normal -command "$this handleOk"
		} {}
		
		itk_component add cancel {
			button $buttonFrame.cancel -text "Cancel" -state normal -command "$this handleCancel"
		} {}

		grid $itk_component(frame) -row 0 -column 0 -sticky news

		grid $itk_component(blLabel) -row 0 -columnspan 2 -sticky w
		grid $itk_component(blListbox) -row 1 -columnspan 2 -sticky news
		grid $itk_component(selectedLabel) -row 2 -columnspan 2 -stick w
		grid $itk_component(selectedEntry) -row 3 -columnspan 2 -sticky news

		grid $buttonFrame -row 4 -column 0 -columnspan 2

		grid $itk_component(ok) -row 0 -column 0 -sticky e
		grid $itk_component(cancel) -row 0 -column 1 -sticky w

		#insert the beamlines into list box
		foreach {item} $beamlineList {
			$itk_component(blListbox) insert 0 $item
		}		
		
		# Set handler for list box selection
		$itk_component(blListbox) config -selectioncommand [::itcl::code $this handleListSelection]
		$itk_component(blListbox) config -dblclickcommand [::itcl::code $this handleDoubleClick]
		$itk_component(blListbox) sort ascending
		
		$itk_component(blListbox) selection set 1 1
		handleListSelection
	}

	destructor {

	}
}


###################################################################
# 
# Handle Ok button
# 
###################################################################
body DCS::BeamlineChooser::handleOk {} {
	global _beamlineDialogWait
	
	set m_beamline [$itk_component(selectedEntry) cget -text]
	
	set _beamlineDialogWait 1
	set m_ok 1

	pack forget $itk_interior
}

###################################################################
# 
# Handle Cancel button
# 
###################################################################
body DCS::BeamlineChooser::handleCancel {} {
	global _beamlineDialogWait
	
	set m_beamline ""
	set _beamlineDialogWait 0
	set m_ok 0
	
	pack forget $itk_interior

}

###################################################################
# 
# Handle list selection
# 
###################################################################
body DCS::BeamlineChooser::handleListSelection {} {

	set selectedIndex [$itk_component(blListbox) curselection]
	$itk_component(selectedEntry) config -text [$itk_component(blListbox) get $selectedIndex]
}

body DCS::BeamlineChooser::handleDoubleClick {} {
	handleListSelection
   handleOk
}

body DCS::BeamlineChooser::isOk { } {

	return $m_ok
	
}

body DCS::BeamlineChooser::wait {} {

	global _beamlineDialogWait

	tkwait variable _beamlineDialogWait
}


