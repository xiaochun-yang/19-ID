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
package provide DCSMotorControlPanel 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
#package require DCSUtil 1.0
#package require DCSSet 1.0
package require DCSComponent
package require DCSButton


#This class creates three buttons: "Move,stop,abort".  Motor
#widgets can register with this object and will be moved
#when the start button is pushed.
class ::DCS::MotorControlPanel {
	inherit ::itk::Widget 
	#::DCS::ComponentGate
	itk_option define -orientation orientation Orientation "vertical"
	itk_option define -ipadx ipadx Ipadx "5"
	itk_option define -ipady ipady Ipady "5"
	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    #this option define whether all motors will be moved parallel
    #or serial
    #it is needed because some pseodo motors have the same child motors.
    #move them together will cause abort
	itk_option define -serialMove serialMove SerialMove 0

	private method updateBubble
	private method repack

	public method applyChanges
	public method cancelChanges
	public method abort
	public method registerMotorWidget { widget }
	public method unregisterMotorWidget { widget }


	protected variable _registeredMotorList ""
	private variable _unappliedChanges

	constructor { args } {

		itk_component add ring {
			frame $itk_interior.entryring
		}

		# create the apply button
		itk_component add start {
			::DCS::Button $itk_component(ring).start \
				 -text "Move" \
				 -command "$this applyChanges"
		} {
			keep -font -width -height -state
			keep -activeforeground -foreground -relief
			rename -background -buttonBackground buttonBackground ButtonBackground
			rename -activebackground -activeButtonBackground buttonBackground ButtonBackground
		}

		# create the cancel button
		itk_component add cancel {
			::DCS::Button $itk_component(ring).cancel \
				 -text "Cancel" \
				 -command "$this cancelChanges" \
                 -activeClientOnly 0 \
                 -systemIdleOnly 0
		} {
			keep -font -width -height -state
			keep -activeforeground -foreground -relief 
			rename -background -buttonBackground buttonBackground ButtonBackground
			rename -activebackground -activeButtonBackground buttonBackground ButtonBackground
		}

		# create the stop button
		itk_component add abort {
			::DCS::Button $itk_component(ring).stop \
				 -text "Abort" \
				 -background \#ffaaaa \
				 -activebackground \#ffaaaa \
				 -command "$this abort"  \
				 -activeClientOnly 0 \
                 -systemIdleOnly 0
		} {
			keep -font -width -height -state
			keep -activeforeground -foreground -relief 
		}

		set _unappliedChanges [::DCS::ComponentGate ::#auto]
		$itk_component(start) addInput "$_unappliedChanges gateOutput 0 {First make changes to a motor entry.}"

		$itk_component(cancel) addInput "$_unappliedChanges gateOutput 0 {No changes to cancel.}"

		eval itk_initialize $args
		#announceExist
	}

	destructor {
        delete object $_unappliedChanges
	}

}

body ::DCS::MotorControlPanel::registerMotorWidget { widget } {

	# add to the list of registered widgets
    if {[lsearch -exact $_registeredMotorList $widget] == -1} {
	    lappend _registeredMotorList $widget
	    $_unappliedChanges addInput "$widget -moveRequest 0 {No unapplied changes}"
	}
    #puts "after add:current list: $_registeredMotorList"
}

body ::DCS::MotorControlPanel::unregisterMotorWidget { widget } {

	# remove widget
    set index [lsearch $_registeredMotorList $widget]
    while {$index != -1} {
        set _registeredMotorList [lreplace $_registeredMotorList $index $index]
        set index [lsearch $_registeredMotorList $widget]
    }
    #puts "after remove:current list: $_registeredMotorList"

	$_unappliedChanges deleteInput "$widget -moveRequest 0 {No unapplied changes}"
}

body ::DCS::MotorControlPanel::cancelChanges {} {
	
	# cancel changes in each widget
	foreach widget $_registeredMotorList {
		$widget cancelChanges
	}
}

body ::DCS::MotorControlPanel::applyChanges {} {
	# apply changes in each widget

    if {[llength $_registeredMotorList] > 1} {
        set motors [list]
	    foreach widget $_registeredMotorList {
            set move_command [$widget getMoveCommand]
            if {$move_command != ""} {
                lappend motors $move_command
                set device [$widget cget -device]
                if {$device != ""} {
                    $device saveUndo
                }
            }
	    }

        if {[llength $motors]} {
            set m_deviceFactory [DCS::DeviceFactory::getObject]
            set opObj [$m_deviceFactory createOperation moveMotors]
            eval $opObj startOperation $itk_option(-serialMove) $motors
        }
    } else {
        ##only one
	    foreach widget $_registeredMotorList {
            $widget moveToValue
	    }
    }
}

body ::DCS::MotorControlPanel::abort {} {
	
	$itk_option(-controlSystem) abort
}


configbody ::DCS::MotorControlPanel::orientation {
	repack
}

configbody ::DCS::MotorControlPanel::ipadx {
	repack
}

configbody ::DCS::MotorControlPanel::ipady {
	repack
}


body ::DCS::MotorControlPanel::repack {} {

	pack forget $itk_component(start)
	pack forget $itk_component(cancel)
	pack forget $itk_component(abort)
	pack forget $itk_component(ring)
	
	switch $itk_option(-orientation) {
		vertical {
			pack $itk_component(start) -padx $itk_option(-ipadx) -pady $itk_option(-ipady)
			pack $itk_component(cancel) -padx $itk_option(-ipadx) -pady $itk_option(-ipady)
			pack $itk_component(abort) -padx $itk_option(-ipadx) -pady $itk_option(-ipady)
			pack $itk_component(ring)
		}

		horizontal {
			pack $itk_component(start) -side left -padx $itk_option(-ipadx) -pady $itk_option(-ipady)
			pack $itk_component(cancel) -side left -padx $itk_option(-ipadx) -pady $itk_option(-ipady)
			pack $itk_component(abort) -side left -padx $itk_option(-ipadx) -pady $itk_option(-ipady)
			pack $itk_component(ring)
		}

		default {
			return -code error "unknown orientation: $itk_option(-orientation)"
		}
	}
}



class DCS::MotorMoveView {
	inherit ::itk::Widget 

	itk_option define -mdiHelper mdiHelper MdiHelper ""
	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    public method handleSetDevice
    public method handleDeviceSelection
    public method changeDevice { motor_name } {
        $itk_component(selection) setValue $motor_name 1
        handleSetDevice $motor_name
    }
    public method changeUnits { units } {
        $itk_component(device) configure -units $units
    }
    public method handleUndo { }

    #yangb	
    public method handleHomeTo { } {
        set devObj [$itk_component(device) cget -device]
        #set value [$itk_component(device) get]
	set dname [namespace tail $devObj]
	#if { $dname  == "sample_x" || $dname  == "sample_y" || $dname  == "sample_z" } {
	#	set value "#HOMEABC"
	#	eval "::device::tripot_1" move to $value
	#} else {
		set value "home"
	        eval $devObj move to $value
	#}
        puts "move $devObj to $value"
        eval $devObj waitForDevice
	puts "homing finished"
	after 100
	if { $dname  == "gonio_phi" } {
	#	set value "#HOMA"
	#	after 20000
		set value -16
	} elseif { $dname == "gonio_kappa" } {
		set value -6.66
	} elseif { $dname == "slit_0_lower" } {
                set value 180
	} elseif { $dname == "slit_0_upper" } {
                set value 0.0
	} elseif { $dname == "slit_0_lobs" } {
                set value 180
	} elseif { $dname == "slit_0_ring" } {
                set value 0
	} elseif { $dname == "sample_x" } {
                set value -0.13
	} elseif { $dname == "sample_y" } {
                set value -0.61
	} elseif { $dname == "sample_z" } {
		set value 0.0
	} elseif { $dname == "mirror_vert" } {
		set value -0.40
	} elseif { $dname == "mirror_horz" } {
		set value -0.38
	} elseif { $dname == "mirror_pitch" } {
		set value 0.69
	} elseif { $dname == "mirror_roll" } {
		set value -0.80
	} else {
		set value 0.0
	}
	dcss sendMessage "gtos_set_motor_position $dname $value"
	after 100
	set value 0.0
#	eval $devObj waitForDevice
	eval $devObj move to $value
        eval $devObj waitForDevice
	after 100
	puts "reset home to 0.0"
    }
    #yange

    public method handleMoveTo { } {
        set devObj [$itk_component(device) cget -device]
        set value [$itk_component(device) get]
        puts "move $devObj to $value"
        $devObj saveUndo
        eval $devObj move to $value
    }
    public method handleMoveBy { } {
        set devObj [$itk_component(device) cget -device]
        set value [$itk_component(device) get]
        puts "move $devObj by $value"
        $devObj saveUndo
        eval $devObj move by $value
    }
    public method handleAbort { } {
        $itk_option(-controlSystem) abort
    }

    private variable m_deviceFactory
    private variable m_origBackground grey80

    public method repack { } 

   public method handleConfigureSelect
   public method handleScanSelect 

    #STATIC
    private common m_objList {}
    public proc changeCommonDevice { motor_name { units "" } } {
        #puts "change common device $motor_name $units"
        foreach obj $m_objList {
            $obj changeDevice $motor_name
            if {$units != ""} {
                #puts "change units: $units"
                $obj changeUnits $units
            }
        }
    }

   constructor { args } {

      set m_deviceFactory [DCS::DeviceFactory::getObject]

      # create labeled frame
	   itk_component add labeledFrame {
      frame $itk_interior.mc \
      -relief groove -borderwidth 2
      } {
         keep -background
      }

      set m_origBackground [cget -background]

      set ring $itk_component(labeledFrame)

      itk_component add moveFrame {
         frame $ring.f
      } {}


      #add the device selection menu
		itk_component add selection {
			DCS::MenuEntry $ring.name \
                 -entryMaxLength 0 \
				 -entryType string -entryWidth 25 \
				 -showEntry 0 \
                 -showPrompt 1 \
            -onSubmit [list $this handleDeviceSelection %s] \
            -activeClientOnly 0 \
            -systemIdleOnly 0
		} {
            keep -background
		}

      itk_component add position {
         DCS::MotorView $ring.phi -promptText "Position: " -promptWidth 9 -decimalPlaces 4 -positionWidth 12 -unitsWidth 8
	   } {
        }


      # construct the motor entry
      itk_component add device {
         ::DCS::MotorViewEntry $ring.motor \
         -autoGenerateUnitsList 1 \
         -activeClientOnly 0 \
         -units mm -unitsWidth 8 \
         -systemIdleOnly 0 -entryWidth 12
      } {
         keep -background
      }
	
		itk_component add config {
			::DCS::Button $ring.u \
				 -text "Configuration" \
				 -command "$this handleConfigureSelect" \
                 -activeClientOnly 0 \
                 -systemIdleOnly 0 
		} {
         keep -width
		}

		# create the apply button
		itk_component add scan {
			::DCS::Button $ring.s \
				 -text "Scan" \
				 -command "$this handleScanSelect" \
                 -activeClientOnly 0 \
                 -systemIdleOnly 0
		} {
         keep -width
		}


		# create the apply button
                itk_component add undo {
                        ::DCS::Button  $ring.cfg\
                 		-activeClientOnly 0 \
                                -text "Undo" \
                                -command "$this handleUndo"
                } {
         keep -width
                }

	#yangb
        itk_component add home_to {
                        ::DCS::Button $itk_component(moveFrame).ht \
             			-activeClientOnly 0 \
                                -text "Home" \
                                -command "$this handleHomeTo"
        } {
        }
	#yange

        itk_component add move_to {
			::DCS::Button $itk_component(moveFrame).mt \
                 		-activeClientOnly 0 \
				-text "Move to" \
				-command "$this handleMoveTo"
        } {
        }

        itk_component add move_by {
			::DCS::Button $itk_component(moveFrame).mb \
                 		-activeClientOnly 0 \
				-text "Move By" \
				-command "$this handleMoveBy"
        } {
        }

        itk_component add abort {
			::DCS::Button $ring.abort \
	        -text "Abort" \
            -background \#ffaaaa \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -width 8 \
			-command "$this handleAbort"
        } {
            keep -width
        }

      eval itk_initialize $args

        repack

		eval lappend motors [$m_deviceFactory getMotorList]
		$itk_component(selection) configure -menuChoices $motors

      #default motor selection least harmful
      changeDevice gonio_phi 

        ####register with obj list
        lappend m_objList $this
    }
	destructor {
        ####unregister with obj list
        set index [lsearch $m_objList $this]
        if {$index != -1} {
            set m_objList [lreplace $m_objList $index $index]
        }
	}
}

body DCS::MotorMoveView::repack { } {
    ##unmap everybody
    grid forget $itk_component(selection)
    grid forget $itk_component(device)
    grid forget $itk_component(undo)
    grid forget $itk_component(config)
    grid forget $itk_component(scan)
    grid forget $itk_component(home_to)
    grid forget $itk_component(move_to)
    grid forget $itk_component(move_by)
    grid forget $itk_component(abort)

    configure -background $m_origBackground
    #$itk_component(selection) configure \
    #    -promptText "Selected Motor"

    $itk_component(device) configure \
        -shadowReference 0 \
        -mismatchColor black \
        -autoMenuChoices 0 \
        -autoConversion 0 \
        -moveByEnabled 0 \
        -menuChoices  {-1000 -500 -270 -200 -180 -100 \
            -90 -50 -45 -20 -10 -5 -2 -1 -.5 -.2 -.1 \
            -.05 -.02 -.01 -.005 -.002 -.001 0.000\
            1000 500 270 200 180 100 90 50 45 20 10 5 2 1 .5 .2 .1 \
            .05 .02 .01 .005 .002 .001 0.000}


    pack $itk_component(move_by) -side left -expand yes -fill both
    pack $itk_component(move_to) -side left -expand yes -fill both
    pack $itk_component(home_to) -side left -expand yes -fill both


    grid $itk_component(selection) -column 1 -row 0 
    grid $itk_component(moveFrame) -column 2 -row 0
    grid $itk_component(undo) -column 3 -row 0
    grid $itk_component(scan) -column 4 -row 0 
 
    grid $itk_component(position) -column 1 -row 1 -sticky w
    grid $itk_component(device) -column 2 -row 1
    grid $itk_component(abort) -column 3 -row 1 
    grid $itk_component(config) -column 4 -row 1
    pack $itk_component(labeledFrame)
}

body DCS::MotorMoveView::handleSetDevice {device_} {

    set deviceObj [$m_deviceFactory getObjectName $device_]

    set oldDeviceObj [$itk_component(device) cget -device]

    $itk_component(position) configure -device $deviceObj

    set reason "{supportingDevice}"
    if {$oldDeviceObj != ""} {
        $itk_component(home_to) deleteInput "$oldDeviceObj status inactive $reason"
	$itk_component(move_to) deleteInput "$oldDeviceObj status inactive $reason"
        $itk_component(move_by) deleteInput "$oldDeviceObj status inactive $reason"
        $itk_component(undo) deleteInput "$oldDeviceObj status inactive $reason"

        $itk_component(home_to) deleteInput \
        "$oldDeviceObj permission GRANTED PERMISSION"        
        $itk_component(move_to) deleteInput \
        "$oldDeviceObj permission GRANTED PERMISSION"
        $itk_component(move_by) deleteInput \
        "$oldDeviceObj permission GRANTED PERMISSION"
        $itk_component(undo) deleteInput \
        "$oldDeviceObj permission GRANTED PERMISSION"
    }
    if {$deviceObj != ""} {
        $itk_component(home_to) addInput "$deviceObj status inactive $reason"
        $itk_component(move_to) addInput "$deviceObj status inactive $reason"
        $itk_component(move_by) addInput "$deviceObj status inactive $reason"
        $itk_component(undo) addInput "$deviceObj status inactive $reason"
        $itk_component(home_to) addInput \
        "$deviceObj permission GRANTED PERMISSION"
        $itk_component(move_to) addInput \
        "$deviceObj permission GRANTED PERMISSION"
        $itk_component(move_by) addInput \
        "$deviceObj permission GRANTED PERMISSION"
        $itk_component(undo) addInput \
        "$deviceObj permission GRANTED PERMISSION"
    }

   $itk_component(device) configure -device $deviceObj
}

body DCS::MotorMoveView::handleDeviceSelection {device_} {
    handleSetDevice $device_

    $itk_option(-mdiHelper) openMotorView $device_ 
}

body DCS::MotorMoveView::handleScanSelect {} {

   set deviceObj [$m_deviceFactory getObjectName [$itk_component(selection) get]]
   $itk_option(-mdiHelper) scanMotor $deviceObj
}

body DCS::MotorMoveView::handleConfigureSelect {} {

   $itk_option(-mdiHelper) configureMotor [$m_deviceFactory getObjectName [$itk_component(selection) get]]
}

body DCS::MotorMoveView::handleUndo { } {
     set devObj [$itk_component(device) cget -device]
     set value [$devObj getUndoPosition]
     #puts "undo:move $devObj to $value"
     $devObj saveUndo
     eval $devObj move to $value
}

