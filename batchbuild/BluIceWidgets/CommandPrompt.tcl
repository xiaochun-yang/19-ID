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

#this package implement all commands that can be used in user-writen
#scripts.
#it is a replacement for old bluice commands.

package provide BLUICECommandPrompt 1.0  

package require DCSDevice
package require DCSDeviceFactory
package require DCSRunSequenceCalculator
package require DCSScriptCommand

class DCS::CommandPrompt {
    inherit ::itk::Widget

    protected variable m_history

    protected variable m_idleCheck 1

    public method do_it { } {
        set cmd [$itk_component(command) get]
        if {$cmd == "disable_system_idle_check"} {
            set m_idleCheck 0
            log_warning system_idle check disabled
            return
        }
        if {$cmd == "enable_system_idle_check"} {
            set m_idleCheck 1
            log_warning system_idle check enabled
            return
        }

        if {$m_idleCheck && [catch assertSystemIdle msg]} {
            log_error $msg
            return
        }

        puts "command=$cmd"
        $m_history add $cmd
        $itk_component(command) delete 0 end

        ########execute the command
        log_note "command: $cmd"
        set code [catch {namespace eval ::nScripts $cmd} result]

        if {$code == 5} {
            log_error  "Command interrupted"
        } elseif {$code != 0} {
            log_error "Command failed: $result"
        }
    }

    public method prev { } {
        $itk_component(command) delete 0 end
        $itk_component(command) insert 0 [$m_history getPrev]
    }
    public method next { } {
        $itk_component(command) delete 0 end
        $itk_component(command) insert 0 [$m_history getNext]
    }

    constructor { } {
        set m_history [DCS::CommandHistory \#auto]

        namespace eval ::nScripts init_device_variables

        itk_component add ring {
            frame $itk_interior.cmd_f \
            -borderwidth 2 \
            -relief groove \
            -height 20
        } {
        }

        itk_component add prompt {
            button $itk_component(ring).prompt \
            -text Command \
            -background white \
            -padx 1 \
            -pady 2 \
            -state disabled
        } {
        }

        itk_component add command {
            entry $itk_component(ring).command \
            -background white
        } {
        }

        pack $itk_component(prompt) -side left
        pack $itk_component(command) -side left -expand 1 -fill both
        pack $itk_component(ring) -fill x

        eval itk_initialize

        bind $itk_component(command) <Return> "$this do_it"
        bind $itk_component(command) <Up> "$this prev"
        bind $itk_component(command) <Down> "$this next"
    }
}
