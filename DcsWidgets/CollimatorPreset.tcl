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
package provide DCSCollimatorPreset 1.0

package require DCSDevice
package require DCSDeviceFactory

###wrap DCS string for collimator_preset
### only one instance will exist.
### only one instance will parse the string to decide
### the list of collimators that are user accessible.
class DCS::CollimatorPreset {
    # inheritance
    inherit DCS::String

    public method setContents
    public method configureString

    ### micro_beam == 1, display==1
    public method getMicroCollimatorList { } {
        return $m_microList
    }
    ### only display == 1
    public method getCollimatorList { } {
        return $m_list4user
        
    }

    public method getCollimatorInfo { index } {
        set item [lindex $_contents $index]

        set micro [lindex $item $m_indexMicro]
        set w     [lindex $item $m_indexWidth]
        set h     [lindex $item $m_indexHeight]

        ### format need match string "user_collimator_status"
        return    [list $micro $index $w $h]
    }

    public method getCollimatorSize { index } {
        set item [lindex $_contents $index]
        set w [lindex $item $m_indexWidth]
        set h [lindex $item $m_indexHeight]
        return [list $w $h]
    }

    public method getCollimatorName { index } {
        set item [lindex $_contents $index]
        set name [lindex $item $m_indexName]
        return $name
    }
    private method generateList { contents_ }

    private variable m_indexName -1
    private variable m_indexDisplay -1
    private variable m_indexMicro -1
    private variable m_indexWidth -1
    private variable m_indexHeight -1

    private variable m_microList ""
    private variable m_list4user ""

    # call base class constructor
    constructor { args } {
        # call base class constructor
        ::DCS::Component::constructor \
             { \
                status      {cget -status} \
                contents    { getContents } \
                permission  {getPermission} \
                list        {getMicroCollimatorList} \
                list4user   {getCollimatorList} \
             }
    } {
        #### find index for interested fields
        set nameList [::config getStr collimatorPresetNameList]
        set m_indexName   [lsearch -exact $nameList name]
        set m_indexDisplay [lsearch -exact $nameList display]
        set m_indexMicro  [lsearch -exact $nameList is_micron_beam]
        set m_indexWidth  [lsearch -exact $nameList width]
        set m_indexHeight [lsearch -exact $nameList height]


        setContents normal [list "" "" "" ""]
        eval configure $args
        announceExist

    }
}
body DCS::CollimatorPreset::configureString { message_ } {
    #puts "config string $message_"
    configure -controller  [lindex $message_ 2] 
    set contents [lrange $message_ 3 end]

    setContents normal $contents
}
body DCS::CollimatorPreset::generateList { contents_ } {
    set m_microList ""
    set m_list4user ""
    set index -1
    foreach preset $contents_ {
        incr index
        set display  [lindex $preset $m_indexDisplay]
        set micro [lindex $preset $m_indexMicro]
        if {$display != "1"} {
            continue
        }
        set name   [lindex $preset $m_indexName]
        set width  [lindex $preset $m_indexWidth]
        set height [lindex $preset $m_indexHeight]
        set item [list $index $name $width $height]
        
        if {$micro == "1"} {
            lappend m_microList $item
            lappend m_list4user $item
        } else {
            lappend m_list4user [list $index $name]
        }
    }
}

body DCS::CollimatorPreset::setContents { status_ contents_ } {
    if {$lastResult != "normal"} {
        DCS::String::setContents $status_ $contents_
        return
    }

    ###we want the permits are ready when contents updated
    ###we also want the contents are ready when permits udpated
    generateList $contents_
    DCS::String::setContents $status_ $contents_
    updateRegisteredComponents list
    updateRegisteredComponents list4user
}

