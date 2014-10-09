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

#
# robot_config.tcl
#
# robot configuration window in blu-ice Setup Tab
# called by blcommon.tcl
#

package require Itcl

package provide BLUICERobotReset 1.0

package require BLUICERobot
package require DCSDeviceFactory

# ===================================================

class RobotResetWidget {
	inherit RobotBaseWidget

	private variable m_ButtonList {}
	private variable m_OpObj
	private variable m_currentStep
	private variable m_OpObjReset
    private variable m_objWaitFlag

	public method handleRobotResetStepChange
	public method performNextStep
	public method startReset
    public method moveRobotUp
    public method delayReset 
    public method skipReset 

	private method configureInstructionText

	private method createHooksToControlSystem
	private variable m_sampleMountingOpObj
	private variable m_resetStepObj
    private variable m_raiseRobot

   private variable m_deviceFactory

	constructor { args } {
		eval RobotBaseWidget::constructor $args
	} {
      set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objWaitFlag [$m_deviceFactory createString screening_msg]

        itk_component add skip_reset {
            DCS::HotButton $itk_interior.skip \
            -background yellow \
            -systemIdleOnly 1 \
            -text "Skip Reset.  I see the sample on the goniometer" \
            -confirmText "Confirm may damage multiple samples" \
            -width 42 \
            -command "$this skipReset"
        } {
        }

        itk_component add delay_reset {
            DCS::HotButton $itk_interior.delay \
            -systemIdleOnly 1 \
            -text "Move tongs out, close lid, wait for reset" \
            -confirmText "Confirm may lose sample" \
            -width 32 \
            -command "$this delayReset"
        } {
        }

		itk_component add move_robot_up {
			DCS::Button $itk_interior.up -text "Move Robot Up 5mm" \
                 -systemIdleOnly 0 \
				 -command "$this moveRobotUp" \
				 -width 17
		} {}
		itk_component add start {
			DCS::Button $itk_interior.start -text "Start" \
                 -debounceTime 1000 \
                 -systemIdleOnly 0 \
				 -command "$this startReset" \
				 -width 10
		} {}
		
		itk_component add continue {
			DCS::Button $itk_interior.cont -text "Continue" \
                 -debounceTime 1000 \
                 -systemIdleOnly 0 \
				 -command "$this performNextStep" \
				 -width 10
		} {}
		
		itk_component add abort {
			DCS::Button $itk_interior.abort -text "Abort" -background \#ffaaaa \
				 -activebackground \#ffaaaa \
				 -width 8 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font
		}

		# add a text box to the top of the dialog...
		itk_component add instructionBox {
			text $itk_interior.ib -background black -foreground white -width 60 \
				 -height 15 -tabs {24 24} \
				 -font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"
		} {}
		
		eval itk_initialize $args
		
		grid rowconfigure $itk_interior 0 -weight 0 

		grid $itk_component(instructionBox) -column 0 -row 0 -columnspan 3
		grid $itk_component(continue) -column 1 -row 1 -sticky e
		grid $itk_component(abort) -column 2 -row 1 -sticky w

        set stringObj [$m_deviceFactory createString robot_status]
        $stringObj createAttributeFromField status_num 1
		$stringObj createAttributeFromField robot_state 7
		$stringObj createAttributeFromField need_reset 3
		$itk_component(start) addInput "$stringObj robot_state idle {Robot is busy.}" 
		$itk_component(continue) addInput "$stringObj robot_state idle {Robot is busy.}" 
		$itk_component(move_robot_up) addInput "$stringObj robot_state idle {Robot is busy.}" 
		$itk_component(delay_reset) addInput "$stringObj robot_state idle {Robot is busy.}" 
		$itk_component(delay_reset) addInput "$stringObj need_reset 1 {No need to reset.}" 

		$itk_component(continue) addInput "$m_objWaitFlag contents {waiting staff input} {busy, not ready}" 
		$itk_component(move_robot_up) addInput "$m_objWaitFlag contents {waiting staff input} {busy, not ready}" 

		$itk_component(skip_reset) addInput "$stringObj robot_state idle {Robot is busy.}" 
		$itk_component(skip_reset) addInput "$stringObj noPinOnGoniometer 1 {Only for laser sensor does not detect the pin.}" 
		configureInstructionText

		#connect the abort button to the control system
		$itk_component(abort) configure -command "$itk_option(-controlSystem) abort"

	   set continueObj [$m_deviceFactory createOperation continueResetProcedure]
      $itk_component(start) addInput "$continueObj permission GRANTED {PERMISSION}"
      $itk_component(continue) addInput "$continueObj permission GRANTED {PERMISSION}"
      #treat same as continue so it only can be called inside the hutch
      $itk_component(move_robot_up) addInput "$continueObj permission GRANTED {PERMISSION}"

		::mediator announceExistence $this

		createHooksToControlSystem

		$itk_component(delay_reset) addInput "$m_sampleMountingOpObj permission GRANTED {PERMISSION}"
		$itk_component(skip_reset) addInput "$m_sampleMountingOpObj permission GRANTED {PERMISSION}"

	}
	
	destructor {
		#unregister with the string
		set strObj [$m_deviceFactory createString robotResetStep]
		::mediator announceDestruction $this
	}
}


body RobotResetWidget::createHooksToControlSystem {} {
	
	#create the hooks to the operations
	set m_sampleMountingOpObj [$m_deviceFactory createOperation ISampleMountingDevice]
    set m_raiseRobot [$m_deviceFactory createOperation raiseRobot]

	#create the hooks to the system state
	set m_resetStepObj [$m_deviceFactory createString robotResetStep]
	::mediator register $this ::$m_resetStepObj contents handleRobotResetStepChange
}

body RobotResetWidget::configureInstructionText {} {

	$itk_component(instructionBox) tag configure whiteCenter -foreground white -justify center
	$itk_component(instructionBox) tag configure redCenter -foreground red -justify center
	$itk_component(instructionBox) tag configure whiteLeft -foreground white -justify left
	$itk_component(instructionBox) tag configure redLeft -foreground red -justify left
	$itk_component(instructionBox) tag configure yellowNojust -foreground yellow

}

body RobotResetWidget::handleRobotResetStepChange { stringName_ targetReady_ alias_ robotResetState_ - } {
	
	if { !$targetReady_ } return

	set step $robotResetState_
	set m_currentStep $step

	$itk_component(instructionBox) delete 0.0 end

    grid forget $itk_component(move_robot_up)
    grid forget $itk_component(delay_reset)
    grid forget $itk_component(skip_reset)
	switch $step {
		0 {
			$itk_component(instructionBox) insert end "\n\n\n\nPlease do not attempt to push or move the robot by hand\n" whiteCenter
			$itk_component(instructionBox) insert end "unless instructed to do so.\n" whiteCenter
			$itk_component(instructionBox) insert end "Follow the on screen instructions carefully.\n" whiteCenter
			$itk_component(instructionBox) insert end "\n\n\nWarning:\nAny currently running beamline operations will be aborted!" redCenter
			
            grid forget $itk_component(continue) 
			$itk_component(continue) configure -text "Continue"
		    grid $itk_component(delay_reset) -column 0 -row 1 -sticky e
		    grid $itk_component(start) -column 1 -row 1 -sticky e
		    grid $itk_component(skip_reset) -column 0 -row 2 -columnspan 3 -sticky news
			
		}

		1 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Use the Safeguard override key to " whiteLeft
			$itk_component(instructionBox) insert end "disable the Safeguard.\n" yellowNojust

            grid forget $itk_component(start) 
		    grid $itk_component(continue) -column 1 -row 1 -sticky e
		}
		2 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Press the green hutch reset button" yellowNojust
			$itk_component(instructionBox) insert end ", if it is blinking.\n" whiteLeft
			
		}
		3 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "The robot server now performs a check to see if a Reset is allowed.\n" whiteLeft
		}
		4 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "The robot will now move the gripper arm to an accessible location\n" whiteLeft
			$itk_component(instructionBox) insert end "above the dispensing Dewar, with the lid closed.\n" whiteLeft
			$itk_component(instructionBox) insert end "\n\n\nPlease keep out of the robot path." redCenter
		}
		5 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Manually remove " yellowNojust
			$itk_component(instructionBox) insert end "any crystal from the goniometer.\n" whiteLeft
		}
		6 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "If the gripper is closed " whiteLeft
			$itk_component(instructionBox) insert end "use a heat gun to melt any excess ice\n" yellowNojust
			$itk_component(instructionBox) insert end "on the gripper.\n" whiteLeft
		}
		7 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "The robot will now open the grippers.\n" whiteLeft
		}
		8 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Please " whiteLeft
			$itk_component(instructionBox) insert end "remove the dumbbell magnet " yellowNojust
			$itk_component(instructionBox) insert end "and any crystal on it.\n" whiteLeft
		}
		9 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Please " whiteLeft
			$itk_component(instructionBox) insert end "remove any crystal " yellowNojust
			$itk_component(instructionBox) insert end "from inside the gripper cavity.\n" whiteLeft
		}
		10 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "The robot will now move the gripper to the heating chamber and\n" whiteLeft
			$itk_component(instructionBox) insert end "dry the gripper arms.\n" whiteLeft
			$itk_component(instructionBox) insert end "\n\n\nPlease keep out of the robot path." redCenter
		}
		11 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "The robot gripper will now try to retrieve a dumbbell magnet\n" whiteLeft
			$itk_component(instructionBox) insert end "from inside the dispensing Dewar.\n" whiteLeft
			$itk_component(instructionBox) insert end "If you already have a dumbbell magnet just wait for the robot\n" whiteLeft
			$itk_component(instructionBox) insert end "to complete its operation.\n" whiteLeft
			$itk_component(instructionBox) insert end "\n\n\nPlease keep out of the robot path." redCenter
		}
		12 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "The robot will now move the gripper arm to an accessible location\n" whiteLeft
			$itk_component(instructionBox) insert end "above the dispensing Dewar, with the lid closed.\n" whiteLeft
			$itk_component(instructionBox) insert end "\n\n\nPlease keep out of the robot path." redCenter
		    grid $itk_component(move_robot_up) -column 0 -row 1 -sticky e
		}
		13 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Please " whiteLeft
			$itk_component(instructionBox) insert end "remove the dumbbell magnet " yellowNojust
			$itk_component(instructionBox) insert end "and any crystal on it.\n" whiteLeft

		}
		14 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "The robot will now move the gripper to the heating chamber and\n" whiteLeft
			$itk_component(instructionBox) insert end "dry the gripper arms.\n" whiteLeft
			$itk_component(instructionBox) insert end "\n\n\nPlease keep out of the robot path." redCenter
		}
		15 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "The robot will now move the gripper arm to an accessible location\n" whiteLeft
			$itk_component(instructionBox) insert end "above the dispensing Dewar, with the lid closed.\n" whiteLeft
			$itk_component(instructionBox) insert end "\n\n\nPlease keep out of the robot path." redCenter
		}
		16 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Please " whiteLeft
			$itk_component(instructionBox) insert end "use a heat gun " yellowNojust
			$itk_component(instructionBox) insert end "to make sure the dumbbell magnet is free\n" whiteLeft
			$itk_component(instructionBox) insert end "from ice and dry.\n" whiteLeft
		}
		17 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Please " whiteLeft
			$itk_component(instructionBox) insert end "replace the dumbbell magnet " yellowNojust
			$itk_component(instructionBox) insert end "(steps a-b below)\n" whiteLeft
			$itk_component(instructionBox) insert end "a.\tRest the dumbbell magnet on the lower fingers of the gripper\n" whiteLeft
			$itk_component(instructionBox) insert end "\tarms. The fingers should rest in the grooves on the\n" whiteLeft
			$itk_component(instructionBox) insert end "\tdumbbell magnet.\n" whiteLeft
			$itk_component(instructionBox) insert end "b.\tThe flush-faced magnet (i.e. the picker magnet) should be\n" whiteLeft
			$itk_component(instructionBox) insert end "\tpositioned at the same end as the wide cavity opening.\n" whiteLeft
		}
		18 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "The robot will now return the dumbbell magnet to the dispensing\n" whiteLeft
			$itk_component(instructionBox) insert end "Dewar, move the gripper to the heating chamber and dry the\n" whiteLeft
			$itk_component(instructionBox) insert end "gripper arms.\n" whiteLeft
			$itk_component(instructionBox) insert end "\n\n\nPlease keep out of the robot path." redCenter
		}
		19 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Please " whiteLeft
			$itk_component(instructionBox) insert end "verify that the cassettes inside the Dewar " yellowNojust
			$itk_component(instructionBox) insert end "correspond to the ones loaded into the Screening Web Interface.\n" whiteLeft
		}
		20 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Please use the Search / Reset key to interlock the hutch and\n" whiteLeft
			$itk_component(instructionBox) insert end "close the hutch door.\n" whiteLeft
			$itk_component(instructionBox) insert end "A new crystal can now be mounted using the Screening Tab\n" whiteLeft
			$itk_component(instructionBox) insert end "in Blu-ice.\n" whiteLeft
		}
		21 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "Enable Safeguard " yellowNojust
			$itk_component(instructionBox) insert end "and press the Safeguard release button.\n" whiteLeft

			#Enable Safeguard and press the Safeguard release button.
			$itk_component(continue) configure -text "Finish"

		}
		99 {
			$itk_component(instructionBox) insert end "\n\n\nStep $step\n\n" whiteLeft
			$itk_component(instructionBox) insert end "x\n" whiteLeft
			$itk_component(instructionBox) insert end "\n\n\nPlease keep out of the robot path." redCenter
		}
		default {
			$itk_component(instructionBox) insert end "\n\n\n unknown step=$step" whiteCenter
			$itk_component(instructionBox) insert end "\n\n\n step=$step" redCenter
		}
	}
}

body RobotResetWidget::performNextStep {} {
	#Start the continueResetProcedure operation.  This operation should be restricted to
   #in hutch only.
	set continueObj [$m_deviceFactory createOperation continueResetProcedure]
	$continueObj startOperation
}

body RobotResetWidget::startReset {} {
 	$m_sampleMountingOpObj startOperation resetProcedure
}
body RobotResetWidget::moveRobotUp {} {
    $m_raiseRobot startOperation
}
body RobotResetWidget::delayReset {} {
 	$m_sampleMountingOpObj startOperation delayReset
}
body RobotResetWidget::skipReset {} {
 	$m_sampleMountingOpObj startOperation skipReset
}
