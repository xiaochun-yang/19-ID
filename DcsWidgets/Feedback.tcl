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


# provide the DCSFeedback package
package provide DCSFeedback 1.0  

# load standard packages
package require Iwidgets
package require DCSAttribute

#11/11/03: change to component and attribute like Label

class DCS::Feedback {
	
	# inheritance
	inherit AttributeDisplay

    itk_option define -barcolor barcolor Barcolor DodgerBlue

    public method handleAttributeUpdate
    public method handleComponentStatus
	
    private variable m_CurrentStep 0

    #to prevent interrupt
    private variable m_InUpdate 0

    #to hide "slight blue mark" when step is 0
    private variable m_hideColor white


	# call base class constructor
	constructor { args } {
        #eval AttributeDisplay $args
    } {

		itk_component add ring {
			frame $itk_interior.r
		} {
            keep -height -width
        }

		itk_component add feedback {
            iwidgets::feedback $itk_component(ring).f
		} {
            keep -barheight -troughcolor -steps -state -labeltext
            keep -foreground
		}

        pack $itk_component(feedback) -expand 1 -fill both
        pack $itk_component(ring) -expand 1 -fill both

		eval itk_initialize $args

        set m_hideColor [$itk_component(feedback) cget -troughcolor]
	}
	
	destructor {
	}
}

body DCS::Feedback::handleAttributeUpdate { component_ targetReady_ alias_ contents_ - } {
    #puts "handle contents $contents_"
    if { ! $targetReady_} return
    if { $m_InUpdate } return

    set m_InUpdate 1

    set text $contents_
	
    #puts "text=$text"

    set ltext [eval list $text]
    switch -exact -- [llength $ltext] {
        3 {
            #format check
            if {[lindex $ltext 1] != "of"} {
                set m_InUpdate 0
                return
            }
            set cstep [lindex $ltext 0]
            set tstep [lindex $ltext 2]
            if {! [string is digit $cstep]} {
                set m_InUpdate 0
                return
            } 
            if {! [string is digit $tstep]} {
                set m_InUpdate 0
                return
            } 

            #range check
            if {[expr "$cstep > $tstep"]} {
                set cstep $tstep
            }
    
            # update total steps if need
            if { [$itk_component(feedback) cget -steps] != $tstep} {
                $itk_component(feedback) configure -steps $tstep
                $itk_component(feedback) reset
                $itk_component(feedback) configure -barcolor $m_hideColor
                set m_CurrentStep 0
            }
            # update step
            if {$cstep != $m_CurrentStep} {
                $itk_component(feedback) reset
                if {$m_CurrentStep <= 0} {
                    $itk_component(feedback) configure -barcolor $itk_option(-barcolor)
                }
                if {$cstep != 0} {
                    $itk_component(feedback) step $cstep
                } else {
                    $itk_component(feedback) configure -barcolor $m_hideColor
                }
                #puts "done and set current to $m_CurrentStep"
            
                set m_CurrentStep $cstep
            }
        }
    }
    set m_InUpdate 0
}

body DCS::Feedback::handleComponentStatus { component_ targetReady_ alias_ status_ - } {
    #puts "handle status $status_"
	if { ! $targetReady_} return

    if { $status_ != "inactive" } {
	    $itk_component(feedback) configure -state disabled
    } else {
	    $itk_component(feedback) configure -state normal
    }
}
configbody DCS::Feedback::barcolor {
    if {$m_CurrentStep <= 0} {
        set color [$itk_component(feedback) cget -troughcolor]
    } else {
        set color $itk_option(-barcolor)
    }
    $itk_component(feedback) configure -barcolor $color
}
