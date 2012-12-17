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

# provide the DCSEntry package
package provide DCSTabNotebook 1.0

# load other DCS packages
package require DCSComponent

package require Iwidgets


#The DCS Notebook inherits directly from the Iwidgets notebook
#but also 
class ::DCS::TabNotebook {

	inherit ::iwidgets::Tabnotebook ::DCS::Component

	#inherit ::DCS::ComponentGate

	itk_option define -activeTab activeTab ActiveTab ""
	itk_option define -parentTab parentTab ParentTab ""

	public method destructor

	public method add
	public method insert
	
	public method addChildVisibilityControl
	public method handleParentVisibility
	public method getActiveTab

	private variable _visibility 1
	private variable _visibilityTrigger ""

	constructor { args } {
		
		# call base class constructor
		Component::constructor { 	
			activeTab 				{getActiveTab} \		 
		}
	} {
		
		eval itk_initialize $args
		announceExist
	}
	

}

#overload the basic add function
body DCS::TabNotebook::add { tabName args} {
	
	#force the notebook to update registered objects when the tab changes
	set command "$this configure -activeTab $tabName"
	
	#call the baseclass add method
	eval iwidgets::Tabnotebook::add $args -command [list $command]
}

#overload the basic add function
body DCS::TabNotebook::insert { tabName args} {
	
	#force the notebook to update registered objects when the tab changes
	set command "$this configure -activeTab $tabName"
	
	#call the baseclass add method
	eval iwidgets::Tabnotebook::insert $args -command [list $command]
}

#overload the basic add function
configbody DCS::TabNotebook::activeTab {
	#puts "NOTEBOOK: $itk_option(-activeTab)"

	set _activeTab $itk_option(-activeTab)
	updateRegisteredComponents activeTab
}

body DCS::TabNotebook::addChildVisibilityControl { widget attribute visibleTrigger } {

	#puts "NOTEBOOK: $itk_option(-activeTab)"
	updateRegisteredComponents activeTab
	
	set _visibilityTrigger $visibleTrigger
	
	::mediator register $this ::$widget $attribute handleParentVisibility
}

body DCS::TabNotebook::handleParentVisibility { - targetReady - value -} {

	if { $targetReady == 0 } {
		set _visibility 0
	} elseif { $value != $_visibilityTrigger } {
		set _visibility 0
	} else {
		set _visibility 1
	}

	#puts "NOTEBOOK: visibility $_visibility"

	updateRegisteredComponents activeTab
}

body DCS::TabNotebook::getActiveTab {} {
	
	if {$_visibility == 1} {
		#return the current tab
		return $itk_option(-activeTab)
	} else {
		return invisible
	}
}


#overload the basic add function
body DCS::TabNotebook::destructor {} {
	announceDestruction
}


proc testTabNotebook {} {
	DCS::TabNotebook .test 	\
		 -tabbackground lightgrey -background lightgrey \
		 -backdrop lightgrey -borderwidth 2\
		 -tabpos n -gap -4 -angle 20 -raiseselect 1 \
		 -bevelamount 4 -padx 5 -pady 4

	# construct the hutch view widgets
	.test add Hutch -label "View Hutch"
	# construct the hutch view widgets
	.test add Sample -label "Position Sample"
	# construct the hutch view widgets
	.test insert Test 1 -label "Test insert"


	set inside [DCS::TabNotebook [.test childsite 0].inside 	\
						 -tabbackground lightgrey -background lightgrey \
						 -backdrop lightgrey -borderwidth 2\
						 -tabpos n -gap -4 -angle 20 -raiseselect 1 \
						 -bevelamount 4 -padx 5 -pady 4]

	$inside addChildVisibilityControl .test activeTab Hutch
	
	# construct the hutch view widgets
	$inside add InsideHutch -label "inside Hutch"
	# construct the hutch view widgets
	$inside add InsideSample -label "inside Sample"

	::mediator register 

	pack .test
	pack $inside

}

#testTabNotebook
