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

package provide BLUICEGapControl 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSDeviceFactory
package require DCSUtil
package require DCSButton

class GapControlWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getIP { number ipREF nameREF }

    public method handleClick
    public method handleOwnerUpdate
    public method handleOwnerRequestUpdate
    public method handleSyncStatusUpdate

    private variable m_deviceFactory
    private variable m_opCheckGapOwnership ""
    private variable m_strGapOwner
    private variable m_strGapOwnerRequest

    private variable m_strGap
    private variable m_strGapRequest
    private variable m_strGapReady
    private variable m_strGapStatus

    private variable m_strGapEnergySync

    #contructor/destructor
    constructor { args  } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_opCheckGapOwnership \
        [$m_deviceFactory createOperation checkGapOwnership]

        set m_strGapOwner [$m_deviceFactory createString gapOwner]
        set m_strGapOwnerRequest [$m_deviceFactory createString gapOwnerRequest]

        set m_strGap [$m_deviceFactory createString gap]
        set m_strGapRequest [$m_deviceFactory createString gapRequest]
        set m_strGapReady [$m_deviceFactory createString gapReady]
        set m_strGapStatus [$m_deviceFactory createString gapStatus]
        set m_strGapEnergySync [$m_deviceFactory createString gap_energy_sync]

        itk_component add of {
            iwidgets::Labeledframe $itk_interior.of \
            -labelpos nw \
            -labeltext "Ownership"
        } {
        }
        set ownerSite [$itk_component(of) childsite]

        itk_component add request {
            DCS::Button $ownerSite.req\
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Request" \
            -command "$m_opCheckGapOwnership startOperation"
        } { 
        }

        itk_component add owner0 {
            label $ownerSite.lo0 \
            -width 10 \
            -text "Owner:"
        } {
        }
        itk_component add owner1 {
            label $ownerSite.lo1 \
            -relief sunken \
            -background #00a040 \
            -width 12 \
            -justify left \
            -anchor w \
            -text ""
        } {
        }
        itk_component add owner2 {
            label $ownerSite.lo2 \
            -relief sunken \
            -background #00a040 \
            -width 15 \
            -justify left \
            -anchor w \
            -text ""
        } {
        }
        itk_component add owner3 {
            label $ownerSite.lo3 \
            -relief sunken \
            -background #00a040 \
            -width 35 \
            -justify left \
            -anchor w \
            -text ""
        } {
        }

        itk_component add owner_request0 {
            label $ownerSite.lor0 \
            -width 10 \
            -text "Request:"
        } {
        }
        itk_component add owner_request1 {
            label $ownerSite.lor1 \
            -relief sunken \
            -background #00a040 \
            -width 12 \
            -justify left \
            -anchor w \
            -text ""
        } {
        }
        itk_component add owner_request2 {
            label $ownerSite.lor2 \
            -relief sunken \
            -background #00a040 \
            -width 15 \
            -justify left \
            -anchor w \
            -text ""
        } {
        }
        itk_component add owner_request3 {
            label $ownerSite.lor3 \
            -relief sunken \
            -background #00a040 \
            -justify left \
            -width 35 \
            -anchor w \
            -text ""
        } {
        }

        grid $itk_component(request) -row 0 -column 1 -columnspan 3

        grid $itk_component(owner0) -column 0 -row 1
        grid $itk_component(owner1) -column 1 -row 1
        grid $itk_component(owner2) -column 2 -row 1
        grid $itk_component(owner3) -column 3 -row 1

        grid $itk_component(owner_request0) -column 0 -row 2
        grid $itk_component(owner_request1) -column 1 -row 2
        grid $itk_component(owner_request2) -column 2 -row 2
        grid $itk_component(owner_request3) -column 3 -row 2

        itk_component add sf {
            iwidgets::Labeledframe $itk_interior.sf \
            -labelpos nw \
            -labeltext "Status"
        } {
        }
        set statusSite [$itk_component(sf) childsite]

        itk_component add lgap {
            label $statusSite.lpos \
            -text "Gap"
        } {
        }

        itk_component add lgap_req {
            label $statusSite.lgap_req \
            -text "Gap Request"
        } {
        }

        itk_component add lready {
            label $statusSite.lready \
            -text "Gap Ready"
        } {
        }

        itk_component add lstatus {
            label $statusSite.lstatus \
            -text "Gap Status"
        } {
        }

        itk_component add gap {
            DCS::Label $statusSite.gap \
            -component $m_strGap \
            -attribute contents \
            -relief sunken \
            -background #00a040 \
            -width 10 \
            -padx 0 \
            -anchor w
        } {
        }

        itk_component add gap_req {
            DCS::Label $statusSite.gap_req \
            -component $m_strGapRequest \
            -attribute contents \
            -relief sunken \
            -background #00a040 \
            -width 12 \
            -padx 0 \
            -anchor w
        } {
        }

        itk_component add gap_ready {
            DCS::Label $statusSite.gap_ready \
            -component $m_strGapReady \
            -attribute contents \
            -relief sunken \
            -background #00a040 \
            -width 15 \
            -padx 0 \
            -anchor w
        } {
        }

        itk_component add gap_status {
            DCS::Label $statusSite.gap_status \
            -component $m_strGapStatus \
            -attribute contents \
            -relief sunken \
            -background #00a040 \
            -width 35 \
            -padx 0 \
            -anchor w \
        } {
        }

        grid $itk_component(lgap) -row 0 -column 0
        grid $itk_component(lgap_req) -row 0 -column 1
        grid $itk_component(lready) -row 0 -column 2
        grid $itk_component(lstatus) -row 0 -column 3

        grid $itk_component(gap) -row 1 -column 0
        grid $itk_component(gap_req) -row 1 -column 1
        grid $itk_component(gap_ready) -row 1 -column 2
        grid $itk_component(gap_status) -row 1 -column 3

        itk_component add ef {
            iwidgets::Labeledframe $itk_interior.ef \
            -labelpos nw \
            -labeltext "Sync With Energy"
        } {
        }
        set energySite [$itk_component(ef) childsite]
        itk_component add sync {
            DCS::Button $energySite.sync \
            -text "Sync" \
            -command "::device::energy move by 0"
        } { 
        }

        itk_component add sync_status {
            label $energySite.status \
            -text "gap synced with energy"
        } {
        }

        pack $itk_component(sync)
        pack $itk_component(sync_status) -expand 1 -fill x

        pack $itk_component(of) -fill x
        pack $itk_component(sf) -fill x
        pack $itk_component(ef) -fill x

        eval itk_initialize $args
        $itk_component(request) addInput \
        "$m_opCheckGapOwnership permission GRANTED {PERMISSION}"

        $m_strGapOwner register $this contents handleOwnerUpdate
        $m_strGapOwnerRequest register $this contents handleOwnerRequestUpdate
        $m_strGapEnergySync register $this contents handleSyncStatusUpdate
    }

    destructor {
        $m_strGapOwner unregister $this contents handleOwnerUpdate
        $m_strGapOwnerRequest unregister $this contents handleOwnerRequestUpdate
        $m_strGapEnergySync unregister $this contents handleSyncStatusUpdate
    }
}
body GapControlWidget::handleClick { bit_no on } {
    if {$bit_no < 0 || $bit_no >= 8} {
        log_error "bad bit_no $bit_no in control laser"
        return
    }
    set mask [expr 1 << $bit_no]

    if {$on} {
        set value 255
    } else {
        set value 0
    }
    #puts "$m_objOp startOperation 0 $value $mask"
    $m_objOp startOperation 0 $value $mask
}
body GapControlWidget::handleOwnerUpdate { - targetReady_ - contents_ -} {
    if {!$targetReady_} return

    set ipAddress unknown
    set name unknown
    getIP $contents_ ipAddress name

    $itk_component(owner1) config \
    -text $contents_
    $itk_component(owner2) config \
    -text $ipAddress
    $itk_component(owner3) config \
    -text $name
}

body GapControlWidget::handleOwnerRequestUpdate { - ready_ - contents_ -} {
    if {!$ready_} return

    set ipAddress unknown
    set name unknown
    getIP $contents_ ipAddress name

    $itk_component(owner_request1) config \
    -text $contents_
    $itk_component(owner_request2) config \
    -text $ipAddress
    $itk_component(owner_request3) config \
    -text $name
}
body GapControlWidget::getIP { number ipREF nameREF } {
    upvar $ipREF ipAddress
    upvar $nameREF name

    if {![string is double -strict $number] \
    || $number == 0.0} {
        set name ""
        set ipAddress ""
        return
    }

    ####set number [expr int($number)]
    ##this is better, can handle format like 2.25333E9
    set number [format "%.0f" $number]

    for {set i 0} {$i < 4} {incr i} {
        set n$i [expr $number % 256]
        set number [expr $number / 256]
    }

    set ipAddress $n3.$n2.$n1.$n0
    set name $ipAddress
    if {![catch { exec host $ipAddress } nameLine]} {
        if {[string first "not found" $nameLine] < 0} {
            set name [lindex $nameLine end]
        }
    } else {
        log_warning no hostname for $ipAddress
    }
}
body GapControlWidget::handleSyncStatusUpdate { - ready_ - contents_ -} {
    if {!$ready_} return

    set status [lindex $contents_ 0]

    #### we treat empty or not exist as sync
    if {$status == "0"} {
        $itk_component(sync_status) configure \
        -text "Gap not synced with energy" \
        -background red
    } else {
        $itk_component(sync_status) configure \
        -text "Gap synced with energy" \
        -background #00a040
    }
}
