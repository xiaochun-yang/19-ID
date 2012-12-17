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
package provide DCSEntryfield 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory
package require ComponentGateExtension


class DCS::Entryfield {
# 	inherit ::itk::Widget ::DCS::ComponentGate
	inherit ::DCS::ComponentGateExtension
	itk_option define -trigger trigger Trigger  ""

    itk_option define -stringName stringName StringName ""
    itk_option define -offset offset Offset 0
    itk_option define -command command Command ""
	itk_option define -state state State "normal"

	# Variables to remember which component this entry is currently
	# using for a reference.
	private variable _lastStringName ""

    public method handleStringConfigure
    public method doCommand

    public method getEntryfield { } {
        return $itk_component(entryfield)
    }

    private   method setString

   private variable m_deviceFactory

	constructor { args } {

      set m_deviceFactory [DCS::DeviceFactory::getObject]

		itk_component add ring {
			frame $itk_interior.r
		}
		itk_component add entryfield {
            iwidgets::entryfield $itk_component(ring).ef -command "$this doCommand"
		} {
            keep -background -foreground -labeltext -labelpos
            keep -fixed -invalid -textfont -validate -show -width
            keep -justify
		}
		pack $itk_component(entryfield) -expand 1 -fill both
		pack $itk_component(ring) -expand 1 -fill both
		#registerComponent $itk_component(entryfield)
		registerComponent $itk_interior
		eval itk_initialize $args
        announceExist
	}

    destructor {
        unregisterComponent
        if {$_lastStringName != ""} {
            set StrObj [$m_deviceFactory createString $_lastStringName]
            $StrObj unregister $this contents handleStringConfigure
        }
    }
}


configbody DCS::Entryfield::trigger {
    if {$itk_option(-trigger) != ""} {
	    addInput $itk_option(-trigger)
    }
}
configbody DCS::Entryfield::state {
    if {$itk_option(-state) == "normal"} {
        $itk_component(entryfield) configure \
        -state normal \
        -textbackground white
    } else {
        $itk_component(entryfield) configure \
        -textbackground lightgrey \
        -state disabled
    }
}

configbody DCS::Entryfield::stringName {
	set stringName $itk_option(-stringName)

	if { $stringName != "" && $stringName != $_lastStringName } {
		#unregister
        if {$_lastStringName != ""} {
            set StrObj [$m_deviceFactory createString $_lastStringName]
		    $StrObj unregister $this contents handleStringConfigure
            deleteInput $StrObj status
        }

        set StrObj [$m_deviceFactory createString $stringName]
		$StrObj register $this contents handleStringConfigure
        addInput "$StrObj status inactive {supporting device}"

		# store the name of the device for next time
		set _lastStringName $stringName
	}
}

body ::DCS::Entryfield::setString {} {
    if {$_lastStringName == ""} return
    set StrObj [$m_deviceFactory createString $_lastStringName]
    set text [eval $StrObj getContents]
    set textList [eval list $text]

    set index $itk_option(-offset)
    set text [$itk_component(entryfield) get]
    set textList [lreplace $textList $index $index "$text"]
    $StrObj sendContentsToServer $textList
}

body ::DCS::Entryfield::doCommand {} {
    #set string first, then call the command if any
    setString
	if {$itk_option(-command) != ""} {
	    eval $itk_option(-command)
    }
}

body DCS::Entryfield::handleStringConfigure { name_ ready_ alias_ contents_ - } {
	if { ! $ready_} return
    set textlist [eval list $contents_]
    set text [lindex $textlist $itk_option(-offset)]

    set state [$itk_component(entryfield) cget -state]
    if {$state != "normal"} {
        $itk_component(entryfield) configure -state normal
    }

	$itk_component(entryfield) clear
    if {$text != ""} {
	    $itk_component(entryfield) insert 0 $text
    }
    if {$state != "normal"} {
        $itk_component(entryfield) configure -state $state
    }
}
