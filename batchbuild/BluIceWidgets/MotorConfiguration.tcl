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

package provide BLUICEMotorConfig 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSPrompt
package require DCSMotorControlPanel
package require DCSCheckbutton


class DCS::MotorConfigWidget {
 	inherit ::itk::Widget

	itk_option define -device device Device ""
	itk_option define -mdiHelper mdiHelper MdiHelper ""

	public method cancelChanges
	public method applyChanges
	public method clearSysMsg
   public method handleMotorConfig

	protected method setDevice

	protected variable _baseUnits

	protected variable _unappliedChanges ""
   protected variable m_logger

	constructor { args} {

      set yellow #d0d000

      set m_logger [DCS::Logger::getObject]

		itk_component add ring {
			frame $itk_interior.r
		}
		
		itk_component add parameterFrame {
			frame $itk_component(ring).pf
		}
		itk_component add messageFrame {
			frame $itk_component(ring).msgF
		}

		itk_component add controlFrame {
			frame $itk_component(ring).c
		}

		# make the motor name label
		itk_component add title {
			label $itk_component(ring).label -text "" \
				 -font "*-helvetica-medium-r-normal--24-*-*-*-*-*-*-*"
		} {
		}

		# create labeled frame for position and limits
		itk_component add positionTitle {
			::DCS::TitledFrame $itk_component(parameterFrame).ptitle \
				 -labelFont "helvetica -18 bold" \
				 -labelText "Positions and Limits"
		} {
			keep -background
		}

		set positionFrame [ $itk_component(positionTitle) childsite]

        ####used by RealMotorConfig
		itk_component add innerLimit {
			DCS::Entry $positionFrame.ol \
				 -entryType float -shadowReference 1 -state labeled \
				 -entryJustify right -entryWidth 10  -entryMaxLength 20 \
				 -promptText "Inner limit: "  -promptWidth 15 -unitsWidth 5 \
                 -autoConversion 1
		} {
			keep -font
		}

		itk_component add upperLimit {
			DCS::Entry $positionFrame.ul \
				 -entryType float -shadowReference 1 -state normal \
				 -entryJustify right -entryWidth 10  -entryMaxLength 20 \
				 -promptText "Upper limit: "  -promptWidth 15 -unitsWidth 5 \
				 -autoConversion 1 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font
		}

		itk_component add position {
			DCS::Entry $positionFrame.p \
				 -entryWidth 10  -entryMaxLength 20 \
				 -promptText "Position: " -promptWidth 15  -unitsWidth 5 \
				 -entryType float  -entryJustify right -shadowReference 1 -state normal\
				 -autoConversion 1 -autoGenerateUnitsList 1  -activeClientOnly 0 -systemIdleOnly 0
		} {
		}


		itk_component add lowerLimit {
			DCS::Entry $positionFrame.ll \
				 -entryWidth 10  -entryMaxLength 20 \
				 -promptText "Lower limit: " -promptWidth 15  -unitsWidth 5 \
				 -entryType float -entryJustify right  -shadowReference 1 -state normal \
				 -autoConversion 1  -activeClientOnly 0 -systemIdleOnly 0
		} {
		}

	
		# make a frame to hold the position check boxes
		itk_component add limitsOnFrame {
			frame $positionFrame.cb
		} {}

		# make the three position checkboxes
		itk_component add upperLimitOn {
			DCS::Checkbutton $itk_component(limitsOnFrame).ulo \
				 -text "Enable upper limit" \
				 -activeClientOnly 0 \
                 -systemIdleOnly 0 \
				 -shadowReference 1
		} {}

		itk_component add lowerLimitOn {
			DCS::Checkbutton $itk_component(limitsOnFrame).llo \
				 -text "Enable lower limit" \
				 -activeClientOnly 0 \
                 -systemIdleOnly 0 \
				 -shadowReference 1
		} {}

		itk_component add lockOn {
			DCS::Checkbutton $itk_component(limitsOnFrame).lo \
				 -text "Lock motor         " \
				 -activeClientOnly 0 \
                 -systemIdleOnly 0 \
				 -shadowReference 1
		} {}

        itk_component add hdSys {
            label $itk_component(messageFrame).l0 \
            -text sysMsg
        } {
        }
        itk_component add hdUsr {
            label $itk_component(messageFrame).l1 \
            -text usrMsg
        } {
        }

        itk_component add tsSys {
            DCS::Label $itk_component(messageFrame).tsSys \
            -background #00a040 \
            -showPrompt 0 \
        } {
        }
        itk_component add tsUsr {
            DCS::Label $itk_component(messageFrame).tsUsr \
            -background #00a040 \
            -showPrompt 0 \
        } {
        }

        itk_component add sysMsg {
            DCS::Entry $itk_component(messageFrame).sys \
            -nullAllowed 1 \
            -entryWidth 80 \
            -entryMaxLength 200 \
            -showPrompt 0 \
            -promptWidth 7 \
            -entryType string \
            -entryJustify left \
            -shadowReference 1 \
            -state labeled \
        } {
        }
        itk_component add usrMsg {
            DCS::Entry $itk_component(messageFrame).usr \
            -nullAllowed 1 \
            -entryWidth 80 \
            -entryMaxLength 200 \
            -showPrompt 0 \
            -promptWidth 7 \
            -entryType string \
            -entryJustify left \
            -shadowReference 1 \
            -state normal \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
        } {
        }

		# create the apply button
		itk_component add apply {
			::DCS::Button $itk_component(controlFrame).apply \
				 -text "Configure" \
				 -command "$this applyChanges" -activeClientOnly 1 \
               -activebackground $yellow \
               -background $yellow
		} {
			keep -font -width -height -state
			keep -activeforeground -foreground -relief
		}

		# create the cancel button
		itk_component add cancel {
			::DCS::Button $itk_component(controlFrame).cancel \
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
		itk_component add clear {
			::DCS::Button $itk_component(controlFrame).clear \
				 -text "Clear sysMsg" \
				 -command "$this clearSysMsg" \
                 -activeClientOnly 1 \
                 -systemIdleOnly 0
		} {
			keep -font -height -state
			keep -activeforeground -foreground -relief 
			rename -background -buttonBackground buttonBackground ButtonBackground
			rename -activebackground -activeButtonBackground buttonBackground ButtonBackground
		}


		set _unappliedChanges [namespace current]::[::DCS::ComponentGate \#auto]

		$itk_component(apply) addInput "::dcss staff 1 {Must be staff to configure a device.}"
		$itk_component(cancel) addInput "$::DCS::MotorConfigWidget::_unappliedChanges gateOutput 0 {No changes to cancel.}"
		$itk_component(clear) addInput "::dcss staff 1 {Must be staff to clear the message.}"
		
		$_unappliedChanges addInput "::$itk_component(upperLimit) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(lowerLimit) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(position) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(upperLimitOn) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(lowerLimitOn) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(lockOn) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(usrMsg) -referenceMatches 1 {No unapplied changes}"


		#pack $itk_component(title)
		#pack $itk_component(positionTitle) -side left -anchor n  -padx 5

		grid $itk_component(title) -row 0 -column 0 -columnspan 3
		grid $itk_component(positionTitle) -row 1 -column 0 -sticky news
		grid $itk_component(parameterFrame) -row 1 -column 1 -sticky news


		pack $positionFrame

		pack $itk_component(upperLimit)
		pack $itk_component(position)
		pack $itk_component(lowerLimit)
		pack $itk_component(limitsOnFrame)
		pack $itk_component(upperLimitOn)
		pack $itk_component(lowerLimitOn)
		pack $itk_component(lockOn)

        grid $itk_component(hdSys) -row 0 -column 0 -sticky nws
        grid $itk_component(hdUsr) -row 1 -column 0 -sticky nws

        grid $itk_component(tsSys) -row 0 -column 1 -sticky nws
        grid $itk_component(tsUsr) -row 1 -column 1 -sticky nws

        grid $itk_component(sysMsg) -row 0 -column 2 -sticky nws
        grid $itk_component(usrMsg) -row 1 -column 2 -sticky nws


		pack $itk_component(apply) -side left -anchor n
		pack $itk_component(cancel) -side left -anchor n
		pack $itk_component(clear) -side left -anchor n

		grid $itk_component(messageFrame) -row 2 -column 0 -columnspan 4
		grid $itk_component(controlFrame) -row 3 -column 0 -columnspan 2

        grid columnconfigure $itk_component(ring) 3 -weight 10
		#pack $itk_component(controlFrame)
		pack $itk_component(ring)
		
		eval itk_initialize $args


      ::mediator announceExistence $this
	}

	destructor {

		destroy $_unappliedChanges
      ::mediator announceDestruction $this
	}


}

body ::DCS::MotorConfigWidget::handleMotorConfig { device_ targetReady_ alias_ value_ -} {
	
	if { ! $targetReady_ } return
	
	#update the units with the current units to redraw everything and recalc the decimal places.
   $itk_component(position) autoGenerateUnitsList
	$itk_component(position) configure -units [$itk_component(position) cget -units]
}


configbody DCS::MotorConfigWidget::device {
	setDevice
}

body DCS::MotorConfigWidget::setDevice {} {

	if {$itk_option(-device) != "" } {

        set deviceName [namespace tail $itk_option(-device)]
		set _baseUnits [$itk_option(-device) cget -baseUnits]

		$itk_component(title) configure -text $deviceName

        set defaultUnits [::config getStr units.$deviceName]
        if {$defaultUnits == ""} {
            set defaultUnits $_baseUnits
        }

		
		$itk_component(position) configure  -autoGenerateUnitsList 1 -units $defaultUnits 
		$itk_component(upperLimit) configure -autoGenerateUnitsList 1 -units $defaultUnits
		$itk_component(innerLimit) configure -autoGenerateUnitsList 1 -units $defaultUnits
		$itk_component(lowerLimit) configure -autoGenerateUnitsList 1 -units $defaultUnits

		$itk_component(position) configure -reference "$itk_option(-device) scaledPosition"
		$itk_component(upperLimit) configure -reference "$itk_option(-device) upperLimit"
		$itk_component(innerLimit) configure -reference "$itk_option(-device) innerLimit"
		$itk_component(lowerLimit) configure -reference "$itk_option(-device) lowerLimit"
		
		$itk_component(lowerLimitOn) configure -reference "$itk_option(-device) lowerLimitOn"
		$itk_component(upperLimitOn) configure -reference "$itk_option(-device) upperLimitOn"
		$itk_component(lockOn) configure -reference "$itk_option(-device) lockOn"
		$itk_component(sysMsg) configure -reference "$itk_option(-device) sysMsg"
		$itk_component(usrMsg) configure -reference "$itk_option(-device) usrMsg"

        $itk_component(tsSys) configure \
        -component "$itk_option(-device)" \
        -attribute tsSysMsg

        $itk_component(tsUsr) configure \
        -component "$itk_option(-device)" \
        -attribute tsUsrMsg
		
      ::mediator register $this $itk_option(-device) limits handleMotorConfig

      #make sure the motor is ready before allowing configure.
      $itk_component(apply) addInput "$itk_option(-device) inMotion 0 Moving"
	}

	set childrenMotors [$itk_option(-device) cget -childrenDevices]
	if {$childrenMotors != "" } {

		# create labeled frame for position and limits
		itk_component add childrenTitle {
			::DCS::TitledFrame $itk_component(ring).childTitle \
				 -labelFont "helvetica -18 bold" \
				 -labelText "Children Motors"
		} {
			keep -background
		}

		grid $itk_component(childrenTitle) -row 1 -column 2

		set childFrame [ $itk_component(childrenTitle) childsite]

		itk_component add childrenMotors {
			DCS::MotorList $childFrame.\#auto $childrenMotors
		} {
			keep -mdiHelper
		}
		
		pack $itk_component(childrenMotors)
	}	

}

body DCS::MotorConfigWidget::cancelChanges {} {

	$itk_component(position) updateFromReference
	$itk_component(upperLimit) updateFromReference
	$itk_component(lowerLimit) updateFromReference

	$itk_component(lowerLimitOn) updateFromReference
	$itk_component(upperLimitOn) updateFromReference
	$itk_component(lockOn) updateFromReference

    $itk_component(usrMsg) updateFromReference
}
body DCS::MotorConfigWidget::clearSysMsg {} {

	if { $itk_option(-device) != "" } {
		$itk_option(-device) clearSystemMessage
    }
}
body DCS::MotorConfigWidget::applyChanges {} {

	if { $itk_option(-device) != "" } {
		$itk_option(-device) changeUserMessage [$itk_component(usrMsg) get]

		foreach {position positionUnits} [$itk_component(position) get] break
		foreach {upperLimit upperLimitUnits} [$itk_component(upperLimit) get] break
		foreach {lowerLimit lowerLimitUnits} [$itk_component(lowerLimit) get] break

      #guard against blank inputs	
      if {$position == "" } {
         $m_logger logError "Configuration changes not applied. Position is blank."
         return
      }

      if {$upperLimit == "" } {
         $m_logger logError "Configuration changes not applied. Upper Limit is blank."
         return
      }
	
      if {$lowerLimit == "" } {
         $m_logger logError "Configuration changes not applied. Lower Limit is blank."
         return
      }

		$itk_option(-device) changeMotorConfiguration \
			 [$itk_option(-device) convertUnits $position  $positionUnits $_baseUnits] \
			 [$itk_option(-device) convertUnits $upperLimit $upperLimitUnits $_baseUnits] \
			 [$itk_option(-device) convertUnits $lowerLimit $lowerLimitUnits $_baseUnits] \
			 [$itk_component(lowerLimitOn) get] \
			 [$itk_component(upperLimitOn) get] \
			 [$itk_component(lockOn) get]
	}
}


class DCS::RealMotorConfigWidget {
 	inherit ::DCS::MotorConfigWidget

	private method setDevice
	public method cancelChanges
	public method applyChanges
    ### need to re-arrange entries and display inner limit
    public method handleMotorConfig

	constructor {args} {

		# create labeled frame for position and limits
		itk_component add realMotorTitle {
			::DCS::TitledFrame $itk_component(parameterFrame).rtitle \
				 -labelFont "helvetica -18 bold" \
				 -labelText "Real Motor Parameters"
		} {
			keep -background
		}

		set parameterFrame [ $itk_component(realMotorTitle) childsite]


		itk_component add scaleFactor {
			DCS::Entry $parameterFrame.sf \
				 -entryWidth 10 -entryMaxLength 20 \
				 -promptText "Scale Factor: " -promptWidth 15 \
				 -entryType positiveFloat -entryJustify right -shadowReference 1 -state normal \
				 -unitsWidth 10 -autoConversion 1 -decimalPlaces 3 -precision 0.001 \
				  -activeClientOnly 0 -systemIdleOnly 0
		} {
		}

		itk_component add speed {
			DCS::Entry $parameterFrame.sp \
				 -entryWidth 10 \
				 -promptText "Speed: " -promptWidth 15 \
				 -entryType positiveInt -entryJustify right -shadowReference 1 -state normal \
				 -unitsWidth 10 -autoConversion 1  -activeClientOnly 0 -systemIdleOnly 0
		} {
		}

		itk_component add acceleration {
			DCS::Entry $parameterFrame.acc \
				 -entryWidth 10 \
				 -promptText "Accel. Time: " -promptWidth 15 \
				 -entryType positiveInt -entryJustify right -shadowReference 1 -state normal \
				 -unitsList {ms {-entryType positiveInt} s {-entryType float}} -units "ms" \
				 -unitsWidth 10 \
				 -autoConversion 1  -activeClientOnly 0 -systemIdleOnly 0
		} {
		}

		itk_component add backlash {
			DCS::Entry $parameterFrame.back \
				 -entryWidth 10 -entryMaxLength 20  -entryType int \
				 -promptText "Backlash: " -promptWidth 15 \
				 -entryJustify right -shadowReference 1 -state normal \
				 -unitsWidth 10 \
				 -autoConversion 1 -activeClientOnly 0 -systemIdleOnly 0
		} {
		}

		itk_component add backlashOn {
			DCS::Checkbutton $parameterFrame.blo \
				 -text "Enable anti backlash      " \
				 -activeClientOnly 0 \
                 -systemIdleOnly 0 \
				 -shadowReference 1
		} {}

		itk_component add reverseOn {
			DCS::Checkbutton $parameterFrame.r \
				 -text "Reverse motor direction" \
				 -activeClientOnly 0 \
                 -systemIdleOnly 0 \
				 -shadowReference 1
		} {}


		$_unappliedChanges addInput "::$itk_component(scaleFactor) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(speed) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(acceleration) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(backlash) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(backlashOn) -referenceMatches 1 {No unapplied changes}"
		$_unappliedChanges addInput "::$itk_component(reverseOn) -referenceMatches 1 {No unapplied changes}"

		grid $itk_component(realMotorTitle) -row 1 -column 1

		pack $itk_component(scaleFactor) 
		pack $itk_component(speed) 
		pack $itk_component(acceleration) 
		pack $itk_component(backlash)
		pack $itk_component(backlashOn)
		pack $itk_component(reverseOn)
 
		eval itk_initialize $args
	}
}

body ::DCS::RealMotorConfigWidget::handleMotorConfig { d_ targetReady_ a_ msg_ e_ } {
    DCS::MotorConfigWidget::handleMotorConfig $d_ $targetReady_ $a_ $msg_ $e_

    if {!$targetReady_} {
        return
    }

    foreach {- - ul ll - - - - scaleFactor backlash blOn} $msg_ break

    if {$blOn && $backlash != 0} {
        set ulV [lindex $ul 0]
        set llV [lindex $ll 0]
        set baseUnits [lindex $ul 1]
        set backlashV [expr 1.0 * $backlash / $scaleFactor]
        if {$backlash > 0} {
            pack $itk_component(innerLimit) -before $itk_component(lowerLimit)
        } else {
            pack $itk_component(innerLimit) -after $itk_component(upperLimit)
        }
    } else {
        pack forget $itk_component(innerLimit)
    }
}

body DCS::RealMotorConfigWidget::setDevice {} {
	::DCS::MotorConfigWidget::setDevice

	$itk_component(scaleFactor) configure -unitsList [list steps/$_baseUnits {-entryType positiveInt} ] -units steps/$_baseUnits
	$itk_component(speed) configure -unitsList "steps/sec {}" -units "steps/sec"
	$itk_component(backlash) configure -unitConvertor $itk_option(-device) -units steps -autoGenerateUnitsList 1
	
	$itk_component(scaleFactor) configure -reference "$itk_option(-device) scaleFactor"
	$itk_component(speed) configure -reference "$itk_option(-device) speed"
	$itk_component(acceleration) configure -reference "$itk_option(-device) acceleration"

	$itk_component(backlash) configure -reference "$itk_option(-device) backlash"
	
	$itk_component(backlashOn) configure -reference "$itk_option(-device) backlashOn"
	$itk_component(reverseOn) configure -reference "$itk_option(-device) reverseOn"
}

body DCS::RealMotorConfigWidget::cancelChanges {} {
	DCS::MotorConfigWidget::cancelChanges

	$itk_component(scaleFactor) updateFromReference
	$itk_component(acceleration) updateFromReference
	$itk_component(speed) updateFromReference

	$itk_component(backlash) updateFromReference
	$itk_component(backlashOn) updateFromReference
	$itk_component(reverseOn) updateFromReference
}

body DCS::RealMotorConfigWidget::applyChanges {} {

	if { $itk_option(-device) != "" } {
		$itk_option(-device) changeUserMessage [$itk_component(usrMsg) get]

		foreach {position positionUnits} [$itk_component(position) get] break
		foreach {upperLimit upperLimitUnits} [$itk_component(upperLimit) get] break
		foreach {lowerLimit lowerLimitUnits} [$itk_component(lowerLimit) get] break
		foreach {scaleFactor scaleFactorUnits} [$itk_component(scaleFactor) get] break
		foreach {speed speedUnits} [$itk_component(speed) get] break
		foreach {accel accelUnits} [$itk_component(acceleration) get] break
		foreach {back backUnits} [$itk_component(backlash) get] break

      #guard against blank inputs	
      if {$position == "" } {
         $m_logger logError "Configuration changes not applied. Position is blank."
         return
      }

      if {$upperLimit == "" } {
         $m_logger logError "Configuration changes not applied. Upper Limit is blank."
         return
      }
	
      if {$lowerLimit == "" } {
         $m_logger logError "Configuration changes not applied. Lower Limit is blank."
         return
      }		

      if {$scaleFactor == "" } {
         $m_logger logError "Configuration changes not applied. ScaleFactor is blank."
         return
      }		

      if {$speed == "" } {
         $m_logger logError "Configuration changes not applied. Speed is blank."
         return
      }

      if {$accel == "" } {
         $m_logger logError "Configuration changes not applied. Acceleration is blank."
         return
      }

      if {$back == "" } {
         $m_logger logError "Configuration changes not applied. Backlash is blank."
         return
      }

      if {$scaleFactor <= 0 } {
         $m_logger logError "Configuration changes not applied. ScaleFactor must be positive."
         return
      }		

      if {$speed <= 0 } {
         $m_logger logError "Configuration changes not applied. Speed must be positive."
         return
      }

      if {$accel <= 0 } {
         $m_logger logError "Configuration changes not applied. Acceleration must be positive."
         return
      }


		#puts "MOTORCONFIG position $position : $positionUnits  $_baseUnits"
		#puts "MOTORCONFIG upperLimit $upperLimit : $upperLimitUnits"

		#puts [$itk_option(-device) convertUnits $position  $positionUnits $_baseUnits]

		$itk_option(-device) changeMotorConfiguration \
			 [$itk_option(-device) convertUnits $position  $positionUnits $_baseUnits] \
			 [$itk_option(-device) convertUnits $upperLimit $upperLimitUnits $_baseUnits] \
			 [$itk_option(-device) convertUnits $lowerLimit $lowerLimitUnits $_baseUnits] \
			 $scaleFactor \
			 $speed \
			 [$itk_option(-device) convertUnits $accel $accelUnits ms] \
			 [$itk_option(-device) convertUnits $back $backUnits steps] \
			 [$itk_component(lowerLimitOn) get] \
			 [$itk_component(upperLimitOn) get] \
			 [$itk_component(lockOn) get] \
			 [$itk_component(backlashOn) get] \
			 [$itk_component(reverseOn) get]
	}
}


class DCS::MotorList {
 	inherit ::itk::Widget

	itk_option define -mdiHelper mdiHelper MdiHelper ""

	constructor { motorList args} {

		itk_component add ring {
			frame $itk_interior.r
		}

		# construct the panel of control buttons
		itk_component add control {
			::DCS::MotorControlPanel $itk_component(ring).control \
				 -width 7 -orientation "horizontal" \
				 -ipadx 4 -ipady 2  -buttonBackground #c0c0ff \
				 -activeButtonBackground #c0c0ff  -font "helvetica -14 bold"
		} {
		}

		foreach motor $motorList {
			set motorName [namespace tail $motor]
			# construct the table widgets
			itk_component add $motorName {
				::DCS::TitledMotorEntry $itk_component(ring).\#auto \
					 -activeClientOnly 0 \
                     -systemIdleOnly 0 \
					 -device $motor \
					 -labelText $motorName -autoGenerateUnitsList 1 -units [$motor cget -baseUnits]
			} {
				keep -mdiHelper
			}
			
			$itk_component(control) registerMotorWidget ::$itk_component($motorName)
			pack $itk_component($motorName)
		}

		eval itk_initialize $args

		pack $itk_component(ring)
		pack $itk_component(control)
	}
}


						
proc startMotorConfigWidget {} {

	DCS::RealMotorConfigWidget .test -device ::device::gonio_phi \
		 -buttonBackground  #c0c0ff \
		 -activeButtonBackground  #c0c0ff \
		 -width 8

	pack .test

	# create the apply button
	::DCS::ActiveButton .activeButton

	pack .activeButton

	dcss connect

	return
}
