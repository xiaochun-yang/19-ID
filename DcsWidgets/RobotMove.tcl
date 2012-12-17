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
package provide DCSRobotMoveList 1.0  

package require DCSDevice
package require DCSDeviceFactory
package require DCSUtil

class DCS::RobotMoveList {
	# inheritance
	inherit DCS::String

	public method setContents
	public method configureString

    public method setStartIndex

    public method getCylinderMoveContents { } {
        return $m_cylinderMoveContents
    }
    public method getPuckMoveContents { } {
        return $m_puckMoveContents
    }

    public method getAllPorts { } {
        return $m_allPort
    }
    public method getAllOriginPorts { } {
        return $m_allOrigPort
    }
    public method getAllDestinationPorts { } {
        return $m_allDestPort
    }

    private method updateMoveStatus { contents_ }
    private method initList { } {
        set m_cylinderMoveContents ""
        set m_puckMoveContents ""
        for {set i 0} {$i < 291} {incr i} {
            lappend m_cylinderMoveContents 0
            lappend m_puckMoveContents 0
        }

        set m_allPort ""
        set m_allOrigPort ""
        set m_allDestPort ""
    }
    private method updateAllListeners { } {
        updateRegisteredComponents cylinder_move_contents
        updateRegisteredComponents puck_move_contents
        updateRegisteredComponents all_ports
        updateRegisteredComponents origin_ports
        updateRegisteredComponents destination_ports
    }

    protected variable m_cylinderMoveContents
    protected variable m_puckMoveContents
    protected variable m_allPort
    protected variable m_allOrigPort
    protected variable m_allDestPort
    protected variable m_startIndex    0

    protected common PORT_ORIG 1
    protected common PORT_DEST 2

	# call base class constructor
	constructor { args } {
        initList

		# call base class constructor
		::DCS::Component::constructor \
			 { \
				contents { getContents } \
                cylinder_move_contents { getCylinderMoveContents } \
                puck_move_contents     { getPuckMoveContents } \
                all_ports              { getAllPorts } \
                origin_ports           { getAllOriginPorts } \
                destination_ports      { getAllDestinationPorts } \
			 }
	} {
        setContents normal ""
		eval configure $args
		announceExist
	}
}
body DCS::RobotMoveList::configureString { message_ } {
    #puts "config string $message_"
	configure -controller  [lindex $message_ 2] 
	set contents [lrange $message_ 3 end]

    setContents normal $contents
}

body DCS::RobotMoveList::setContents { status_ contents_ } {
    if {$lastResult != "normal"} {
        DCS::String::setContents $status_ $contents_
        return
    }

    ###we want the move status are ready when contents updated
    updateMoveStatus $contents_
    DCS::String::setContents $status_ $contents_
    updateAllListeners
}
body DCS::RobotMoveList::setStartIndex { num } {
    puts "setStartIndex $num"
    if {$num < 0} {
        log_error startIndex $num must >= 0
        set num 0
    }

    set m_startIndex $num
    if {$_contents == ""} return
    updateMoveStatus $_contents
    updateRegisteredComponents contents
    updateAllListeners
}

body DCS::RobotMoveList::updateMoveStatus { contents_ } {
    puts "RobotMoveList: $contents_"

    initList

    ###try to re-use the code for spreadsheet: mapping port to index
    set OrigListLeft ""
    set OrigListMiddle ""
    set OrigListRight ""
    set DestListLeft ""
    set DestListMiddle ""
    set DestListRight ""

    set ll [llength $contents_]
    for {set i $m_startIndex} {$i < $ll} {incr i} {
        set item [lindex $contents_ $i]
        set orig ""
        set dest ""
        if {![parseRobotMoveItem $item orig dest]} {
            continue
        }
        if {$orig != ""} {
            lappend m_allPort $orig
            lappend m_allOrigPort $orig
        }
        if {$dest != ""} {
            lappend m_allPort $dest
            lappend m_allDestPort $dest
        }

        set orig_cas [string index $orig 0]
        set dest_cas [string index $dest 0]
        switch -exact -- $orig_cas {
            l { lappend OrigListLeft   [string range $orig 1 end] }
            m { lappend OrigListMiddle [string range $orig 1 end] }
            r { lappend OrigListRight  [string range $orig 1 end] }
        }
        switch -exact -- $dest_cas {
            l { lappend DestListLeft   [string range $dest 1 end] }
            m { lappend DestListMiddle [string range $dest 1 end] }
            r { lappend DestListRight  [string range $dest 1 end] }
        }
    }
    ##generate the index list
    set origCylinderIndexList ""
    eval lappend origCylinderIndexList \
    [generateIndexMap 1 0 OrigListLeft 1] \
    [generateIndexMap 2 0 OrigListMiddle 1] \
    [generateIndexMap 3 0 OrigListRight 1]

    set origPuckIndexList ""
    eval lappend origPuckIndexList \
    [generateIndexMap 1 0 OrigListLeft 3] \
    [generateIndexMap 2 0 OrigListMiddle 3] \
    [generateIndexMap 3 0 OrigListRight 3]

    set destCylinderIndexList ""
    eval lappend destCylinderIndexList \
    [generateIndexMap 1 0 DestListLeft 1] \
    [generateIndexMap 2 0 DestListMiddle 1] \
    [generateIndexMap 3 0 DestListRight 1]

    set destPuckIndexList ""
    eval lappend destPuckIndexList \
    [generateIndexMap 1 0 DestListLeft 3] \
    [generateIndexMap 2 0 DestListMiddle 3] \
    [generateIndexMap 3 0 DestListRight 3]

    puts "origCylinder: $origCylinderIndexList"
    puts "origPuch:     $origPuckIndexList"
    puts "destCylinder: $destCylinderIndexList"
    puts "destPuch:     $destPuckIndexList"

    ###fill
    foreach index $origCylinderIndexList {
        if {$index < 0} continue
        set m_cylinderMoveContents \
        [lreplace $m_cylinderMoveContents $index $index $PORT_ORIG]
    }
    foreach index $origPuckIndexList {
        if {$index < 0} continue
        set m_puckMoveContents \
        [lreplace $m_puckMoveContents $index $index $PORT_ORIG]
    }
    foreach index $destCylinderIndexList {
        if {$index < 0} continue
        set old_value [lindex $m_cylinderMoveContents $index]
        set new_value [expr $old_value | $PORT_DEST]
        set m_cylinderMoveContents \
        [lreplace $m_cylinderMoveContents $index $index $new_value]
    }
    foreach index $destPuckIndexList {
        if {$index < 0} continue
        set old_value [lindex $m_puckMoveContents $index]
        set new_value [expr $old_value | $PORT_DEST]
        set m_puckMoveContents \
        [lreplace $m_puckMoveContents $index $index $new_value]
    }
}
