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
package provide DCSUserAlignBeamStatus 1.0

package require DCSDevice
package require DCSDeviceFactory

# load standard packages

###wrap DCS string for user_align_beam_status
### only one instance will exist.
### only one instance will parse the string to decide
### whether any of the aligmnents is enabled
class DCS::UserAlignBeamStatus {
    # inheritance
    inherit DCS::String

    public method setContents
    public method configureString

    public method getAnyEnabled { } {
        return $m_anyEnabled
    }

    private method checkAnyEnabled { contents_ } {
        foreach {enable1 enable2} $contents_ break
        if {$enable1 == ""} {
            set enable1 0
        }
        if {$enable2 == ""} {
            set enable2 0
        }
        if {$enable1 || $enable2} {
            set m_anyEnabled 1
        } else {
            set m_anyEnabled 2
        }
    }

    private variable m_anyEnabled 0

    # call base class constructor
    constructor { args } {
        # call base class constructor
        ::DCS::Component::constructor \
             { \
                status      {cget -status} \
                contents    { getContents } \
                permission  {getPermission} \
                anyEnabled  {getAnyEnabled} \
             }
    } {
        #### find index for interested fields
        setContents normal [list 0 0 0 0 0 0]
        eval configure $args
        announceExist

    }
}
body DCS::UserAlignBeamStatus::configureString { message_ } {
    #puts "config string $message_"
    configure -controller  [lindex $message_ 2] 
    set contents [lrange $message_ 3 end]

    setContents normal $contents
}
body DCS::UserAlignBeamStatus::setContents { status_ contents_ } {
    if {$lastResult != "normal"} {
        DCS::String::setContents $status_ $contents_
        return
    }

    ###we want the permits are ready when contents updated
    ###we also want the contents are ready when permits udpated
    checkAnyEnabled $contents_
    DCS::String::setContents $status_ $contents_
    updateRegisteredComponents anyEnabled
}
