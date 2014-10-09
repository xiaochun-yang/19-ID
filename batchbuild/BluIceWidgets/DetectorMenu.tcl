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


# provide the DCSDevice package
package provide BLUICEDetectorMenu 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSDetector
package require DCSEntry

#extend the menu entry to select for detector mode types.
#The widget registers for interest in the current detector type.
#
class DCS::DetectorModeMenu {
	inherit DCS::MenuEntry

	private variable _detectorObject
	private variable _modeIndex 0

	protected method replace%sWithValue
	public method setValueByIndex

	public method selectDetectorMode

    public method setValue

	public method handleDetectorTypeChange

	constructor { args } {

		#create on object for watching the detector
		set _detectorObject [DCS::Detector::getObject]

		::mediator register $this ::$_detectorObject supportedModes handleDetectorTypeChange

		eval itk_initialize $args

        setValueByIndex [$_detectorObject getDefaultModeIndex] 1
		
		announceExist
		updateEntryColor
		set _ready 1
	}
}

body ::DCS::DetectorModeMenu::selectDetectorMode {} {
	
	set modeName [get]
	set _modeIndex [$_detectorObject getModeIndexFromModeName $modeName]

	return $_modeIndex
}


body DCS::DetectorModeMenu::handleDetectorTypeChange { detector_ targetReady_ alias_ modes_ -  } {

	if { ! $targetReady_} return

	configure -menuChoices $modes_

	setValueByIndex $_modeIndex 1
	
}


body DCS::DetectorModeMenu::replace%sWithValue { command_ } {

	set first [ string first %s $command_ ]

	if {$first == -1} { return $command_} 

	set replacedStr  [string range $command_ 0 [expr $first -1]][selectDetectorMode][string range $command_ [expr $first+2] end]
	
	return $replacedStr
}


body ::DCS::DetectorModeMenu::setValueByIndex { value_ {directAccess_ 0} } {
	
	set _modeIndex $value_

	set value [$_detectorObject getModeNameFromIndex $value_]

	DCS::Entry::setValue $value $directAccess_
}

body ::DCS::DetectorModeMenu::setValue { value_ {directAccess_ 0} } {
    if {![string is integer -strict $value_] \
    || $value_ < 0} {
	    return [DCS::Entry::setValue $value_ $directAccess_]
    }
	set value [$_detectorObject getModeNameFromIndex $value_]

    if {$value != ""} {
	    set _modeIndex $value_
	    return [DCS::Entry::setValue $value $directAccess_]
    }

    ## now trouble: we will just display it

	return [DCS::Entry::setValue $value_ $directAccess_]
}

