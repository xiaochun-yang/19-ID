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
package provide DCSTitledFrame 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

##########################################################################

class ::DCS::TitledFrame {

	# inheritance
	inherit ::itk::Widget ::DCS::Component

	# public variables related to the entry widget
	itk_option define -labelFont labelFont LabelFont *-helvetica-bold-r-normal--12-*-*-*-*-*-*-*
	itk_option define -labelText labelText LabelText ""
	itk_option define -labelPadX labelPadx LabelPadx "10"
	itk_option define -configCommands configCommands ConfigCommands ""
	itk_option define -onAnyClick onAnyClick OnAnyClick "" {
        if {$itk_option(-onAnyClick) != ""} {

            $itk_component(configmenu) configure \
            -postcommand $itk_option(-onAnyClick)

            #bind $itk_component(ring) <Button-1> $itk_option(-onAnyClick)
            #bind $itk_component(spacer1) <Button-1> $itk_option(-onAnyClick)
            bind $itk_component(border) <Button-1> $itk_option(-onAnyClick)
            bind $itk_component(spacer2) <Button-1> $itk_option(-onAnyClick)
            bind $itk_component(user) <Button-1> $itk_option(-onAnyClick)
            bind $itk_component(label) <Button-1> $itk_option(-onAnyClick)
        }
    }

	#private methods
	private method updateLabel {}
	private variable _lastCommand ""
	
	# public methods
	public method childsite {}
	public method pushNewCommand
	public method getLastCommand

	# protected methods
	protected method updateWidget {}

	# constructor
	constructor { args } { 
		# call base class constructor
		::DCS::Component::constructor { -command getLastCommand }
	} {
		# create the frames
		itk_component add ring {
			frame $itk_interior.ring
		} { }

		itk_component add spacer1 {
			frame $itk_interior.ring.s 
		} { }

		itk_component add border {
			frame $itk_interior.ring.b  -relief groove -borderwidth 2
		} { }

		itk_component add spacer2 {
			frame $itk_interior.ring.b.s  
		} { }

		itk_component add user {
			frame $itk_interior.ring.b.c
		}

		# create the label at the level of the outer hull, allowing
		# it to overwrite the grooved frame of the border component
		itk_component add label {
			menubutton $itk_component(ring).l -relief flat -cursor hand2 -justify left -padx 0 -pady 0 \
				 -menu $itk_component(ring).l.menu
		} {
			rename -width -unitsWidth unitswidth UnitsWidth
			rename -foreground -labelForeground foreground Foreground
			rename -background -labelBackground background Background
			rename -disabledforeground -labelForeground foreground Foreground
		}

		itk_component add configmenu {
			menu $itk_component(label).menu -tearoff 0 -activebackground green -background blue
		} {
			keep -background -foreground
		}
		
		pack $itk_component(spacer1) 
		pack $itk_component(spacer2) 
		pack $itk_component(border) -expand yes -fill both
		pack $itk_component(user) -pady 2 -padx 2  -expand yes -fill both
		place $itk_component(label) -x 10
		pack $itk_component(ring) -expand yes -fill both

		raise $itk_component(label)
		eval itk_initialize $args

		announceExist
	}

}

configbody ::DCS::TitledFrame::configCommands {

	set count 0
	
	if {$itk_option(-configCommands) != "" } {
		
		$itk_component(configmenu) delete 0 last
		
		foreach {label command} $itk_option(-configCommands) {
			
			$itk_component(configmenu) add command -label $label -command [list $this pushNewCommand $command]
			incr count
		}
		$itk_component(label) configure -state normal
	} else {
		#The menu won't appear if there are no config commands
		$itk_component(label) configure -state disabled
	}
}

body ::DCS::TitledFrame::pushNewCommand { command_ } {
	
	set _lastCommand $command_
	
	updateRegisteredComponents -command
}

body ::DCS::TitledFrame::getLastCommand {} {
	return $_lastCommand
}

#
configbody ::DCS::TitledFrame::labelFont {
	updateLabel
}

configbody ::DCS::TitledFrame::labelText {

	$itk_component(label) configure -text $itk_option(-labelText)
	
	updateLabel
}

configbody ::DCS::TitledFrame::labelPadX {

	place $itk_component(label) -x $itk_option(-labelPadX)
	
	updateLabel
}

#handles slightly fancy packing and placing of the label over the
#grooved frame. 
body ::DCS::TitledFrame::updateLabel {} {

	#change the text
	$itk_component(label) configure -font $itk_option(-labelFont)
	
	#get the metrics for the font that is used
	array set fontMetrics [font metrics [$itk_component(label) cget -font]]
	
	#calculate half the height of a letter for this font
	set midpoint [expr int ($fontMetrics(-linespace) / 2)]

	#calculate how much space is needed for the label for this font.
	set textWidth [expr [font measure $itk_option(-labelFont) $itk_option(-labelText) ] +  $itk_option(-labelPadX) * 2]
	
	$itk_component(spacer1) configure -height [expr $midpoint +2] -width $textWidth
	$itk_component(spacer2) configure -height [expr $midpoint +2] -width $textWidth
}

body ::DCS::TitledFrame::childsite {} {
	return $itk_component(user)
}
