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

package provide BLUICEShutterControl 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSButton
package require DCSProtocol
package require DCSDeviceFactory
package require ComponentGateExtension

####no need to support dynamic shutter name change
class ShutterView {
    inherit ::DCS::ComponentGateExtension

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -shutterName shutterName ShutterName "" {
        if {$m_objShutter != ""} {
            ::mediator unregister $this $m_objShutter state
        }

        if {$itk_option(-shutterName) != ""} {
            set m_objShutter \
            [$m_deviceFactory getObjectName $itk_option(-shutterName)]

            $itk_component(open_button) configure \
            -command "$m_objShutter open"
            $itk_component(close_button) configure \
            -command "$m_objShutter close"

            ::mediator register $this $m_objShutter state handleStateChange
            ####$m_objShutter register $this state handleStateChange
        }
    }
    itk_option define -openText openText OpenText "open"
    itk_option define -closedText closedText ClosedText "closed"
    itk_option define -openButtonLabel openButtonLabel OpenButtonLabel Open
    itk_option define -closeButtonLabel closeButtonLabel CloseButtonLabel Close
    itk_option define -buttonWidth buttonWidth ButtonWidth 10
    itk_option define -labelWidth labelWidth LabelWidth 10

    private variable m_deviceFactory
    private variable m_objShutter  ""

    public method handleStateChange { - targetReady_ - contents_ - } {
        if {!$targetReady_} return
        puts "handle state change $contents_"
        if {$contents_ == "open"} {
            set newLabel $itk_option(-openText)
        } else {
            set newLabel $itk_option(-closedText)
        }
        $itk_component(state_label) configure \
        -text $newLabel
    }

    constructor { args } {
        set m_deviceFactory [::DCS::DeviceFactory::getObject]
        itk_component add open_button {
            button $itk_interior.ob \
            -width 10
        } {
            rename -text -openButtonLabel openButtonLabel OpenButtonLabel
            rename -width -buttonWidth buttonWidth ButtonWidth
        }
        itk_component add close_button {
            button $itk_interior.cb \
            -width 10
        } {
            rename -text -closeButtonLabel closeButtonLabel CloseButtonLabel
            rename -width -buttonWidth buttonWidth ButtonWidth
        }
        itk_component add state_label {
            label $itk_interior.sl \
            -text asdfadsfda \
            -width 10
        } {
            rename -width -labelWidth labelWidth LabelWidth
        }
        grid $itk_component(open_button) $itk_component(close_button) \
        $itk_component(state_label) -sticky news

        registerComponent $itk_component(open_button) $itk_component(close_button)

		eval itk_initialize $args

        announceExist
    }
}

class ShutterControlWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    private variable m_deviceFactory
    private variable m_shutterList ""

    ### to sort the list: Al_1, Al_2, Al_4, Al_8.....
    public proc compare { e1 e2 } {
        set ss1 [regexp {^Al_([0-9]+)$} $e1 dummy num1]
        set ss2 [regexp {^Al_([0-9]+)$} $e2 dummy num2]

        if {$ss1 && $ss2} {
            return [expr $num1 - $num2]
        } elseif {$ss1} {
            return -1
        } elseif {$ss2} {
            return 1
        } else {
            return [string compare $e1 $e2]
        }
    }

    constructor { args  } {
        itk_component add headerOpen {
            label $itk_interior.ho \
            -text "OPEN"
        } {
        }
        itk_component add headerClose {
            label $itk_interior.hc \
            -text "CLOSE"
        } {
        }
        itk_component add headerState {
            label $itk_interior.hs \
            -text "STATE"
        } {
        }
        grid $itk_component(headerOpen) $itk_component(headerClose) \
        $itk_component(headerState)

        set m_deviceFactory [DCS::DeviceFactory::getObject]
	    set m_shutterList [$m_deviceFactory getShutterList]

        set m_shutterList [lsort -command ShutterControlWidget::compare $m_shutterList]

	    foreach shutter $m_shutterList {
            set goodName [string map {. _} $shutter]
	        itk_component add bo_$goodName {
                DCS::Button $itk_interior.bo$goodName \
                -text $shutter \
                -width 10 \
                -command "::device::$shutter open"
	        } {
	        }
	        itk_component add bc_$goodName {
                DCS::Button $itk_interior.bc$goodName \
                -text $shutter \
                -width 10 \
                -command "::device::$shutter close"
	        } {
	        }
	        itk_component add l_$goodName {
                DCS::Label $itk_interior.l$goodName \
                -width 10 \
                -component ::device::$shutter \
                -attribute state
	        } {
	        }
            grid $itk_component(bo_$goodName) $itk_component(bc_$goodName) \
            $itk_component(l_$goodName)
	    }

        eval itk_initialize $args
    }
}

