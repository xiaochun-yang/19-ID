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
package provide DCSCheckbox 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory
package require ComponentGateExtension

class DCS::Checkbox {
# 	inherit ::itk::Widget ::DCS::ComponentGate
    inherit ::DCS::ComponentGateExtension
    itk_option define -trigger trigger Trigger  ""
    itk_option define -stringName stringName StringName ""
    itk_option define -itemList itemList ItemList {}
    itk_option define -command command Command ""


    # Variables to remember which component this entry is currently
    # using for a reference.
    private variable _lastStringName ""
    private variable _length 0
    private variable _indexList ""

    private variable _inStringUpdate 0
    private variable _strContents ""
    private variable _state normal

    public method handleStringConfigure
    public method doCommand
#	protected method handleNewOutput
	private method handleNewOutput
    private   method setString
    private   method updateDisplay
    private variable m_deviceFactory

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        itk_component add cx {
            iwidgets::checkbox $itk_interior.cx
        } {
            keep -orient -labeltext -labelfont -labelpos
            keep -borderwidth -labelmargin
        }
        pack $itk_component(cx) -expand 1 -fill both
        registerComponent $itk_component(cx)
        eval itk_initialize $args
        announceExist
    }

    destructor {
        if {$_lastStringName != ""} {
            set StrObj [$m_deviceFactory createString $_lastStringName]
            $StrObj unregister $this contents handleStringConfigure
        }
    }
}


body DCS::Checkbox::handleNewOutput { } {
    if {$_length == 0} return
    ::DCS::ComponentGateExtension::handleNewOutput
}

configbody DCS::Checkbox::trigger {
    if {$itk_option(-trigger) != ""} {
	    addInput $itk_option(-trigger)
    }
}

configbody DCS::Checkbox::stringName {
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

configbody DCS::Checkbox::itemList {
    ####remove all old one
    for {set i 0} {$i < $_length} {incr i} {
        $itk_component(cx) delete b$i
    }
    set _indexList ""

    set ll [llength $itk_option(-itemList)]
    set bn 0
    if {$ll > 0} {
        foreach {label index} $itk_option(-itemList) {
            if {[string is integer -strict $index]} {
                $itk_component(cx) add b$bn -text "$label"
                incr bn
                lappend _indexList $index
            } else {
                puts "wrong format of itemList"
            }
        }
        $itk_component(cx) configure -command "$this doCommand"
    }
    set old_length $_length
    set _length $bn
    if {$_length != [llength $_indexList]} {
        puts "error _indexList: $_indexList"
        puts "length: $_length"
    }
    updateDisplay
    if {$old_length ==0} {
        ###process pending new output
 #       if {$_length == 0} return
        handleNewOutput
    }
}

body ::DCS::Checkbox::setString {} {
    if {$_inStringUpdate} return

    if {$_lastStringName == ""} return
    set StrObj [$m_deviceFactory createString $_lastStringName]
    set text [eval $StrObj getContents]
    set textList [eval list $text]

    for {set i 0} {$i < $_length} {incr i} {
        set index [lindex $_indexList $i]
        if {[eval $itk_component(cx) get $i]} {
            set textList [lreplace $textList $index $index 1]
        } else {
            set textList [lreplace $textList $index $index 0]
        }
    }
    $StrObj sendContentsToServer $textList
}

body ::DCS::Checkbox::doCommand {} {
    #set string first, then call the command if any
    setString
	if {$itk_option(-command) != ""} {
	    eval $itk_option(-command)
    }
}

body DCS::Checkbox::handleStringConfigure { name_ ready_ alias_ contents_ - } {
	if { ! $ready_} {
        return
    }
    set _strContents $contents_
    updateDisplay
}
    
body DCS::Checkbox::updateDisplay { } {
    if {$_length == 0} return

    set _inStringUpdate 1
    set old_state [$itk_component(cx) cget -state]
    #if {[catch "$itk_component(cx) cget -state" old_state]} {
    #    puts "no item yet"
    #    puts "length: $_length"
    #    puts "items: $itk_option(-itemList)"
    #    
    #    set _inStringUpdate 0
    #    return
    #}
    if {$old_state == "disabled"} {
        $itk_component(cx) config -state normal
    }
    set textlist [eval list $_strContents]
    for {set i 0} {$i < $_length} {incr i} {
        set index [lindex $_indexList $i]
        set text [lindex $textlist $index]
        if {$text == "1" } {
            $itk_component(cx) select $i
        } else {
            $itk_component(cx) deselect $i
        }
    }
    if {$old_state == "disabled"} {
        $itk_component(cx) config -state $old_state
    }
    set _inStringUpdate 0
}
