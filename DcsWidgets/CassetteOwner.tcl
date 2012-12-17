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
package provide DCSCassetteOwner 1.0  

package require DCSDevice
package require DCSDeviceFactory

# load standard packages


###wrap DCS string for cassette_owner so that
### only one instance will exist.
### only one instance will parse the string to decide
### whether show or hide the cassette
class DCS::CassetteOwner {
	
	# inheritance
	inherit DCS::String

	public method setContents
	public method configureString

    public method getPermits { } {
        return $m_permits
    }

    public method getNoCassettePermit { } {
        return [lindex $m_permits 0]
    }
    public method getLeftCassettePermit { } {
        return [lindex $m_permits 1]
    }
    public method getMiddleCassettePermit { } {
        return [lindex $m_permits 2]
    }
    public method getRightCassettePermit { } {
        return [lindex $m_permits 3]
    }

    public method handleUserChange { args } {
        updatePermits $_contents
        updateAllListeners
    }

    public method handleStaffChange { args } {
        eval DCS::Device::handleStaffChange $args

        updatePermits $_contents
        updateAllListeners
    }

    private method updatePermits { contents_ }
    private method updateAllListeners { } {
        updateRegisteredComponents permits
        updateRegisteredComponents no_permit
        updateRegisteredComponents left_permit
        updateRegisteredComponents middle_permit
        updateRegisteredComponents right_permit
    }

    private variable m_permits [list 1 1 1 1]

	# call base class constructor
	constructor { args } {
		# call base class constructor
		::DCS::Component::constructor \
			 { \
				contents { getContents } \
                permits { getPermits } \
                no_permit { getNoCassettePermit }
                left_permit { getLeftCassettePermit }
                middle_permit { getMiddleCassettePermit }
                right_permit { getRightCassettePermit }
			 }
	} {
        setContents normal [list "" "" "" ""]
		eval configure $args
		announceExist

        $controlSystem register $this user handleUserChange
        $controlSystem register $this staff handleStaffChange

	}
}
body DCS::CassetteOwner::configureString { message_ } {
    #puts "config string $message_"
	configure -controller  [lindex $message_ 2] 
	set contents [lrange $message_ 3 end]

    setContents normal $contents
}

body DCS::CassetteOwner::setContents { status_ contents_ } {
    if {$lastResult != "normal"} {
        DCS::String::setContents $status_ $contents_
        return
    }

    ###we want the permits are ready when contents updated
    ###we also want the contents are ready when permits udpated
    updatePermits $contents_
    DCS::String::setContents $status_ $contents_
    updateAllListeners
}

body DCS::CassetteOwner::updatePermits { contents_ } {
    set user [$controlSystem getUser]
    set staff [$controlSystem getStaff]
    set m_permits [list 0 0 0 0]
    if {$staff} {
        set m_permits [list 1 1 1 1]
    } else {
        for {set i 0} {$i < 4} {incr i} {
            set owner [lindex $contents_ $i]
            if {$owner == "" || [lsearch -exact $owner $user] >= 0} {
                set m_permits [lreplace $m_permits $i $i 1]
            }
        }
    }
    #puts "cassette permit: $m_permits"
}
