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
package provide DCSStrategyStatus 1.0  

package require DCSDevice
package require DCSDeviceFactory

# load standard packages


###wrap DCS string for strategy_status so that
###only one instance will read and parse the file per BluIce
class DCS::StrategyStatus {
	
	# inheritance
	inherit DCS::String

    ### hide normal disabled
    public variable button_status
    public variable labeltext

    public variable background
    public variable groupname_list
    public variable rundef_list
    public variable warning_list
    public variable help_msg

	public method setContents
	public method configureString

    private method specialSetContents

    private variable m_numRun 0

    private common STATUS_WIDTH 8

	# call base class constructor
	constructor { args } {
		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 contents { getContents } \
			 }
	} {
        setContents normal "not_ready dummy"
		eval configure $args
		announceExist
	}
}
body DCS::StrategyStatus::configureString { message_ } {
    #puts "config string $message_"
	configure -controller  [lindex $message_ 2] 
	set contents [lrange $message_ 3 end]

    setContents normal $contents
}
body DCS::StrategyStatus::specialSetContents { contents_ } {
    set status [lindex $contents_ 0]

    ####more strict check
    switch -exact -- $status {
        ready {
            ### go further to parse the file
        }
        errorSvr {
            set button_status disabled
            set background red
            set labeltext [string range $status 0 $STATUS_WIDTH]
            set help_msg "failed to access the result file"
            return
        }
        pending -
        running -
        not_ready {
            set button_status disabled
            set background ""
            set labeltext [string range $status 0 $STATUS_WIDTH]
            set help_msg $status
            return
        }
        default {
            ###ignore this message
            puts "bad contents for strategy_status, ignored {$contents_}"
            return
        }
    }

    #### ready, parse the file ####
    set fullPath [lindex $contents_ 1]
    if {[string index $fullPath 0] != "/"} {
        set button_status disabled
        set background red
        set labeltext [string range $fullPath 0 $STATUS_WIDTH]
        set help_msg $fullPath
        return
    }

    #############################################
    set url [::config getStrategyStatusUrl]
    append url "?beamline=[::config getConfigRootName]"
    append url "&file=$fullPath"
    puts "strategyStatus: $url"

    if {[catch {
        set token [http::geturl $url -timeout 8000]
        checkHttpStatus $token
        set result [http::data $token]
        http::cleanup $token
    } errMsg]} {
        puts "failed to get file: $errMsg"
        set button_status disabled
        set background red
        set labeltext error
        set help_msg "failed to read result file"
        return
    }
    #puts "full file: $result"

    ##########remove this part after web service return error
    if {[string first <html> $result] == 0} {
        puts "failed to get file: strange contents: {$result}"
        set button_status disabled
        set background red
        set labeltext error
        set help_msg "failed to read result file"
        return
    }

    set file_status [lindex $result 0]
    set file_contents [lindex $result 1]
    puts "file_status: $file_status"

    #### more strict check the first line too ####
    switch -exact -- $file_status {
        error {
            set button_status disabled
            set background red
            set labeltext error
            set help_msg [strategyParseError $file_contents]
            return
        }
        done {
            ### go further parse the file for spacegroup
        }
        default {
            set button_status disabled
            set background red
            set labeltext error
            set help_msg "maybe corrupted file"
            return
        }
    }

    set rundef_list ""
    set groupname_list ""
    set warning_list ""
    strategyParseSpaceGroup $file_contents 0 groupname_list rundef_list warning_list

    set m_numRun [llength $groupname_list]
    puts "total groups: $m_numRun"


    if {$m_numRun < 1} {
        set button_status disabled
        set background red
        set labeltext noSpcGrp
        set help_msg "no spacegroup found"
        return
    }

    ##### any warning message will  turn on color yellow
    set anyWarning 0
    foreach groupWarning $warning_list {
        foreach warning $groupWarning {
            if {$warning != ""} {
                log_warning $warning
                set anyWarning 1
            }
        }
    }

    puts "enable the button"
    set button_status normal
    if {$anyWarning} {
        set background yellow
    } else {
        set background ""
    }
    set labeltext ""
    set help_msg ""
}

body DCS::StrategyStatus::setContents { status_ contents_ } {
    if {$lastResult != "normal"} {
        DCS::String::setContents $status_ $contents_
        return
    }

    if {[catch {
        specialSetContents $contents_
    } errMsg]} {
        log_error Corrupted Strategy File.  Please report to programmer
        log_error $errMsg
        set button_status disabled
        set background red
        set labeltext error
        set help_msg "failed to read result file"
    }

    DCS::String::setContents $status_ $contents_
}
