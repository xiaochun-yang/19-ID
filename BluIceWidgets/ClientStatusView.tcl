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

# load standard packages
package require Itcl

package provide BLUICEClientStatusView 1.0

package require Iwidgets
package require DCSPrompt
package require DCSTitledFrame
package require DCSButton


class ClientStatusView {
    inherit ::itk::Widget DCS::Component

    private variable m_clientList ""
    private variable m_showHandBack 0

    public variable deviceNamespace ::device
    public variable controlSystem ::dcss
    public method handleNewClientList

    ### handle both staff and active
    public method handleClientStatus

    public method handleNewCommand { - ready_ - command_ - } {
        if {!$ready_} {
            return
        }
        switch -exact -- $command_ {
            hand_back_control {
                $controlSystem sendMessage "gtos_admin hand_back_masters"
            }
            default {
                log_error unsupported command $command_
            }
        }
    }

    private method updateClientList
    
    constructor { args } {
        itk_component add ring {
            frame $itk_interior.ring
        }
        
        itk_component add TitledFrame {
            ::DCS::TitledFrame $itk_component(ring).l -labelText "Users"
        } {
            keep -labelFont -labelPadX -labelBackground -labelForeground
        }

        set childsite [$itk_component(ring).l childsite]

        itk_component add clientLog {
            # create the button
            DCS::scrolledLog $childsite.log
        } {
            keep -background -relief -width -height
        }

        eval itk_initialize $args    

        set clientList [DCS::ClientList::getObject] 
        ::mediator register $this $clientList clientList handleNewClientList
        ::mediator register $this $controlSystem clientState handleClientStatus
        ::mediator register $this $controlSystem staff       handleClientStatus
        ::mediator register $this ::$itk_component(TitledFrame) -command handleNewCommand

      announceExist

        pack $itk_component(clientLog) -expand yes -fill both
        pack $itk_component(TitledFrame) -expand yes -fill both
        pack $itk_component(ring) -expand yes -fill both
    }

    destructor {
        
    }

}

body ClientStatusView::handleClientStatus { - ready_ - - -} {
    set clientState [$controlSystem cget -clientState]
    if {$clientState == "active"} {
        set isActive 1
    } else {
        set isActive 0
    }
    set isStaff [$controlSystem getStaff]

    if {$isStaff && $isActive} {
        set m_showHandBack 1
    } else {
        set m_showHandBack 0
    }
    updateClientList
}

body ClientStatusView::handleNewClientList { - targetReady_ alias clientList_ -} {

    if { !$targetReady_ } return

    set m_clientList $clientList_
    updateClientList
}
body ClientStatusView::updateClientList { } {
    set numPreviousMaster 0
    $itk_component(clientLog) clear

    $itk_component(clientLog) log_string [format "%10s %25s %8s %12s %10s" {} {User Name} {Staff} {Roaming} {Location}] warning 0

    set booleanText "No Yes"

    foreach client $m_clientList {
        foreach {dummy clientId accountName name remoteStatus \
        jobtitle staff remoteAccess host display isMaster wasMaster} \
        $client break
        
        #log_note "got client info"
        if { [string index $display 0] == ":" } {
            set display $host$display
        }

        if {$name != "DCSS"} {
            if {$isMaster} {
                $itk_component(clientLog) log_string \
                [format "%10s %25s %8s %12s %10s %20s" \
                "Active-->" $name \
                [lindex $booleanText $staff] \
                [lindex $booleanText $remoteAccess] \
                $remoteStatus $display ] error 0
            } else {
                if {$wasMaster == "1" && $m_showHandBack} {
                    $itk_component(clientLog) log_string \
                    [format "%10s %25s %8s %12s %10s %20s" \
                    {} \
                    $name \
                    [lindex $booleanText $staff] \
                    [lindex $booleanText $remoteAccess] \
                    $remoteStatus $display ] note 0

                    incr numPreviousMaster
                } else {
                    $itk_component(clientLog) log_string \
                    [format "%10s %25s %8s %12s %10s %20s" \
                    {} \
                    $name \
                    [lindex $booleanText $staff] \
                    [lindex $booleanText $remoteAccess] \
                    $remoteStatus $display ] command 0
                }
            }
        }
    }

    if {$numPreviousMaster > 0} {
        $itk_component(TitledFrame) configure \
        -labelForeground blue \
        -configCommands [list "Hand Back Control" hand_back_control]
    } else {
        $itk_component(TitledFrame) configure \
        -labelForeground black \
        -configCommands [list]
    }
}

class OperationStatusView {
    inherit ::itk::Widget DCS::Component

    public method handleStatusChange

    public variable deviceNamespace ::device
    public variable controlSystem dcss
    public variable targetOperations {}
    private variable _status
    
    constructor { args } {
        itk_component add ring {
            frame $itk_interior.ring
        }
        
        itk_component add TitledFrame {
            ::DCS::TitledFrame $itk_component(ring).l -labelText "Operations"
        } {
            keep -labelFont -labelPadX -labelBackground -labelForeground
        }

        set childsite [$itk_component(ring).l childsite]

        itk_component add operationLog {
            # create the button
            DCS::scrolledLog $childsite.log
        } {
            keep -background -relief -width
        }

        eval itk_initialize $args    

        pack $itk_component(operationLog) -expand yes -fill both
        pack $itk_component(TitledFrame) -expand yes -fill both
        pack $itk_component(ring) -expand yes -fill both
        
        announceExist
    }
}

configbody OperationStatusView::targetOperations {
    foreach {operation} $itk_option(-targetOperations) {
        ::mediator register $this ${deviceNamespace}::$operation status handleStatusChange
        set _status(${deviceNamespace}::${operation}.status) inactive
    }
}


body OperationStatusView::handleStatusChange { - - alias message - } {

    set _status($alias) $message 

    $itk_component(operationLog) clear
    
    foreach {operation} $itk_option(-targetOperations) {
        if {[info commands ${deviceNamespace}::${operation}] != "" } {
            set logmsg  [format "%20s %10s %40s" $operation $_status(${deviceNamespace}::${operation}.status) [${deviceNamespace}::${operation} cget -lastResult] ]
            $itk_component(operationLog) log_string $logmsg warning 0
        }
    }
}
