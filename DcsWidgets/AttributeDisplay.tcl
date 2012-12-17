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
package provide DCSAttribute 1.0  

# load standard packages
package require Iwidgets


#this is base class for displaying attribute of a component.
#used at least by DCSAttributeDisplay DCS::Feedback
class DCS::AttributeDisplay {
    
    # inheritance
    inherit ::itk::Widget

    itk_option define -component component Component ""
    itk_option define -attribute attribute Attribute ""

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    
    #need to be override by derived classes
    public method handleAttributeUpdate
    public method handleComponentStatus
    
    private method unregisterLast
    private method registerNew
    
    private variable _lastComponent ""
    private variable _lastAttribute ""


    # call base class constructor
    constructor { args } {} {
        eval itk_initialize $args
    }
    
    destructor {
		 #sometimes the component that is referencing may already be destroyed
		 catch {
			 if {$_lastComponent != ""} {
				 $_lastComponent unregister $this $itk_option(-attribute) handleAttributeUpdate
				 $_lastComponent unregister $this status handleComponentStatus
			 }
		 }
    }
}

configbody DCS::AttributeDisplay::attribute {
    set attribute $itk_option(-attribute)
    if { $attribute != $_lastAttribute } {
        unregisterLast
        registerNew
    }
}

configbody DCS::AttributeDisplay::component {
    set component $itk_option(-component)
    if { $component != $_lastComponent } {
        unregisterLast
        registerNew
    }
}

body DCS::AttributeDisplay::unregisterLast {} {
    if { $_lastComponent == "" || $_lastAttribute == "" } return

    $_lastComponent unregister $this $_lastAttribute handleAttributeUpdate
    $_lastComponent unregister $this status handleComponentStatus

    set _lastComponent ""
    set _lastAttribute ""
}

body DCS::AttributeDisplay::registerNew {} {
    set component $itk_option(-component)
    set attribute $itk_option(-attribute)

    if { $component == "" || $attribute == "" } return

    $component register $this $attribute handleAttributeUpdate
    $component register $this status handleComponentStatus
    
    # store the name of the device for next time
    set _lastComponent $component
    set _lastAttribute $attribute
}

body DCS::AttributeDisplay::handleAttributeUpdate { component_ targetReady_ alias_ contents_ - } {
}

body DCS::AttributeDisplay::handleComponentStatus { component_ targetReady_ alias_ status_ - } {
}
