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


error "The robot initialization is obsolete in the 'blu-ice' project. Do not source robot_config.tcl.  Use 'BluIceWidgets' project instead."
package require Itcl

# ===================================================

proc construct_robot_window { parent } {

        # this function uses the global variables gConfig(robot,useRobot) and gConfig(robot,robotState)
        # which will be updated in Sequence.tcl

        set handle [start_waitable_operation sequenceGetConfig getConfig robotState]
        set result [wait_for_operation $handle]
        
        global gConfig
        print "gConfig(robot,robotState)=$gConfig(robot,robotState)"
        print "gConfig(robot,useRobot)=$gConfig(robot,useRobot)"

        set m_font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"

        set top "$parent.frame"

	# Create the top frame (component container)
	frame $top -borderwidth 30
	pack $top -side top

	# Create a frame caption
	set f [frame $top.header -bd 1 -relief flat]

	set w_labeRobotState [label $f.labelRobotState -text "Robot is ready for action"]
	pack $w_labeRobotState -side top

	set w_checkUseRobot [checkbutton $f.checkuseRobot -text "Use Robot for Screening" -variable gConfig(robot,useRobot) -command "useRobot_parameter_changed" ]
	pack $w_checkUseRobot -side top

        # store the control element names in a global variable so that they can be updated after the Robot Reset Dialog
        set gConfig(robot,labeRobotState) $w_labeRobotState

        set w_reset [button $f.buttonReset -text "Reset..." -font $m_font -command "resetRobot_button_clicked"]
	pack $w_reset -side top  -pady 10 

	pack $f -side left

        # update the labeRobotState
        roboState_changed
}

# ===================================================

proc useRobot_parameter_changed {} {
print "useRobot_parameter_changed"

global gConfig
set useRobotFlag $gConfig(robot,useRobot)

# make sure that we are master
if { ! [dcss is_master] } {
    if { $useRobotFlag==0 } {
        set gConfig(robot,useRobot) "1"
    } else {
        set gConfig(robot,useRobot) "0"
    }
    log_error "This client is not the master."
    return
}

# send message to dcss
sequence actionPerformed RobotConfig setConfig useRobot $useRobotFlag
}

# ===================================================

proc resetRobot_button_clicked {} {
print "resetRobot_button_clicked - initiate the Reset Dialog"

# make sure that we are master
if { ! [dcss is_master] } {
    log_error "This client is not the master."
    return
}

global gConfig

# intialize the step counter of the reset dialog
set gConfig(robot,robotResetStep) 0

# create the dialog box
set dlg ".dialogRobotReset"
set gConfig(robot,dialogRobotReset) [iwidgets::dialogshell $dlg -title "Robot Reset"]
$dlg add continue -text "Continue" -command "continueRobotResetDialog_button_clicked"
$dlg add cancel -text "Cancel" -command "$dlg deactivate"
$dlg default continue

# add a text box to the top of the dialog...
set win [$dlg childsite]
set txt [text $win.ex -background black -foreground white -width 60 -height 15 -tabs {24 24}]
$txt tag configure whiteCenter -foreground white -justify center
$txt tag configure redCenter -foreground red -justify center
$txt tag configure whiteLeft -foreground white -justify left
$txt tag configure redLeft -foreground red -justify left
$txt tag configure yellowNojust -foreground yellow 
set gConfig(robot,textRobotResetDialog) $txt

$txt insert end "\n\n\n\nPlease do not attempt to push or move the robot by hand\n" whiteCenter
$txt insert end "unless instructed to do so.\n" whiteCenter
$txt insert end "Follow the on screen instructions carefully.\n" whiteCenter
$txt insert end "\n\n\nWarning:\nAny currently running beamline operations will be aborted!" redCenter

pack $win.ex -expand yes -fill both -padx 4 -pady 4

# disable controls in parent window
$dlg configure -modality "application"

#activate the dialog
$dlg activate

# the dialog "Robot Reset" dialog window is closed, now destroy it
destroy $dlg

# get the new robotState
set handle [start_waitable_operation sequenceGetConfig getConfig robotState]
set result [wait_for_operation $handle]

}

# ===================================================

proc continueRobotResetDialog_button_clicked {} {
print "continueRobotReset_button_clicked"

global gConfig
set dlg $gConfig(robot,dialogRobotReset)
set txt $gConfig(robot,textRobotResetDialog)

# make sure that we are master
if { ! [dcss is_master] } {
    log_error "This client is not the master."
    # close the robot reset dialog
    $dlg deactivate
    return
}

set step [incr gConfig(robot,robotResetStep)]
print "gConfig(robot,robotResetStep)=$step"

$dlg buttonconfigure continue -state disabled
set result {"normal" "RobotDHSOK"}
$txt delete 1.0 end
switch -exact -- $step {
    1 {
        # abort any runnyning beamline operations
        do_command abort

        # do not use robot for Screening
        set handle [start_waitable_operation sequenceSetConfig setConfig useRobot "0"]
        wait_for_operation $handle

        # send dismount message to dcss to reset the crystal state to "no crystal mounted"
        sequence actionPerformed RobotConfig "dismount"
        
	$txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Use the Safeguard override key to " whiteLeft
	$txt insert end "disable the Safeguard.\n" yellowNojust
    }
    2 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Press the green hutch reset button" yellowNojust
	$txt insert end ", if it is blinking.\n" whiteLeft

    }
    3 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "The robot server now performs a check to see if a Reset is allowed.\n" whiteLeft
    }
    4 {
        set handle [start_waitable_operation ISampleMountingDevice resetAllowed]
        set result [wait_for_operation $handle]
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "The robot will now move the gripper arm to an accessible location\n" whiteLeft
        $txt insert end "above the dispensing Dewar, with the lid closed.\n" whiteLeft
        $txt insert end "\n\n\nPlease keep out of the robot path." redCenter
    }
    5 {
        set handle [start_waitable_operation ISampleMountingDevice moveToCheckPoint]
        set result [wait_for_operation $handle]
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Manually remove " yellowNojust
	$txt insert end "any crystal from the goniometer.\n" whiteLeft
    }
    6 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "If the gripper is closed " whiteLeft
	$txt insert end "use a heat gun to melt any excess ice\n" yellowNojust
        $txt insert end "on the gripper.\n" whiteLeft
    }
    7 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "The robot will now open the grippers.\n" whiteLeft
    }
    8 {
        set handle [start_waitable_operation ISampleMountingDevice openGripper]
        set result [wait_for_operation $handle]
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Please " whiteLeft
	$txt insert end "remove the dumbbell magnet " yellowNojust
	$txt insert end "and any crystal on it.\n" whiteLeft
    }
    9 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Please " whiteLeft
	$txt insert end "remove any crystal " yellowNojust
	$txt insert end "from inside the gripper cavity.\n" whiteLeft
    }
    10 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "The robot will now move the gripper to the heating chamber and\n" whiteLeft
        $txt insert end "dry the gripper arms.\n" whiteLeft
        $txt insert end "\n\n\nPlease keep out of the robot path." redCenter
    }
    11 {
        set handle [start_waitable_operation ISampleMountingDevice heatGripper 10 ]
        set result [wait_for_operation $handle]
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "The robot gripper will now try to retrieve a dumbbell magnet\n" whiteLeft
        $txt insert end "from inside the dispensing Dewar.\n" whiteLeft
        $txt insert end "If you already have a dumbbell magnet just wait for the robot\n" whiteLeft
        $txt insert end "to complete its operation.\n" whiteLeft
        $txt insert end "\n\n\nPlease keep out of the robot path." redCenter
    }
    12 {
        set handle [start_waitable_operation ISampleMountingDevice check dumbbell]
        set result [wait_for_operation $handle]
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "The robot will now move the gripper arm to an accessible location\n" whiteLeft
        $txt insert end "above the dispensing Dewar, with the lid closed.\n" whiteLeft
        $txt insert end "\n\n\nPlease keep out of the robot path." redCenter
    }
    13 {
        set handle [start_waitable_operation ISampleMountingDevice moveToCheckPoint]
        set result [wait_for_operation $handle]
        if { [lindex $result 1]=="RobotDHSOK" } {
            set handle2 [start_waitable_operation ISampleMountingDevice openGripper]
            set result [wait_for_operation $handle2]
        }
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Please " whiteLeft
	$txt insert end "remove the dumbbell magnet " yellowNojust
	$txt insert end "and any crystal on it.\n" whiteLeft
    }
    14 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "The robot will now move the gripper to the heating chamber and\n" whiteLeft
        $txt insert end "dry the gripper arms.\n" whiteLeft
        $txt insert end "\n\n\nPlease keep out of the robot path." redCenter
    }
    15 {
        set handle [start_waitable_operation ISampleMountingDevice heatGripper 0]
        set result [wait_for_operation $handle]
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "The robot will now move the gripper arm to an accessible location\n" whiteLeft
        $txt insert end "above the dispensing Dewar, with the lid closed.\n" whiteLeft
        $txt insert end "\n\n\nPlease keep out of the robot path." redCenter
    }
    16 {
        set handle [start_waitable_operation ISampleMountingDevice moveToCheckPoint]
        set result [wait_for_operation $handle]
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Please " whiteLeft
	$txt insert end "use a heat gun " yellowNojust
	$txt insert end "to make sure the dumbbell magnet is free\n" whiteLeft
        $txt insert end "from ice and dry.\n" whiteLeft
    }
    17 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Please " whiteLeft
	$txt insert end "replace the dumbbell magnet " yellowNojust
	$txt insert end "(steps a-b below)\n" whiteLeft
        $txt insert end "a.\tRest the dumbbell magnet on the lower fingers of the gripper\n" whiteLeft
        $txt insert end "\tarms. The fingers should rest in the grooves on the\n" whiteLeft
        $txt insert end "\tdumbbell magnet.\n" whiteLeft
        $txt insert end "b.\tThe flush-faced magnet (i.e. the picker magnet) should be\n" whiteLeft
        $txt insert end "\tpositioned at the same end as the wide cavity opening.\n" whiteLeft
    }
    18 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "The robot will now return the dumbbell magnet to the dispensing\n" whiteLeft
        $txt insert end "Dewar, move the gripper to the heating chamber and dry the\n" whiteLeft
        $txt insert end "gripper arms.\n" whiteLeft
        $txt insert end "\n\n\nPlease keep out of the robot path." redCenter
    }
    19 {
        set handle [start_waitable_operation ISampleMountingDevice returnDumbbell]
        set result [wait_for_operation $handle]
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Please " whiteLeft
	$txt insert end "verify that the cassettes inside the Dewar " yellowNojust
	$txt insert end "correspond to the ones loaded into the Screening Web Interface.\n" whiteLeft
    }
    20 {
        # enable the usage of the robot for Screening
        set handle [start_waitable_operation sequenceSetConfig setConfig useRobot "1"]
        wait_for_operation $handle
        
        # set the Screening cassetteInfo to undefined
	global env
	set user $env(USER)
	set cassetteInfo [list $user 0 { undefined  undefined  undefined undefined }]
        sequence actionPerformed RobotConfig setConfig cassetteInfo $cassetteInfo

        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Please use the Search / Reset key to interlock the hutch and\n" whiteLeft
        $txt insert end "close the hutch door.\n" whiteLeft
        $txt insert end "A new crystal can now be mounted using the Screening Tab\n" whiteLeft
        $txt insert end "in Blu-ice.\n" whiteLeft
    }
    21 {
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "Enable Safeguard " yellowNojust
	$txt insert end "and press the Safeguard release button.\n" whiteLeft
    }
    99 {
        set handle [start_waitable_operation op3 param3]
        set result [wait_for_operation $handle]
        $txt insert end "\n\n\nStep $step\n\n" whiteLeft
        $txt insert end "x\n" whiteLeft
        $txt insert end "\n\n\nPlease keep out of the robot path." redCenter
    }
    default {
        $txt insert end "\n\n\n unknown step=$step" whiteCenter
        $txt insert end "\n\n\n step=$step" redCenter
    }
}

$dlg buttonconfigure continue -state normal

#test
#set result {"normal" "RobotDHSOK"}

if { [lindex $result 1]!="RobotDHSOK" } {
    puts "ERROR during robot reset step $step: $result"
    set indx [ expr [ lsearch -exact $result "RobotDHSError:" ] - 1 ]
    if { $indx >= 0 } {
    	set result [lreplace $result 0 $indx]
    }
    log_error "$result"
    $dlg deactivate
    return
}

if { $step==21 } {
    $dlg buttonconfigure continue -text "Finish"
}
if { $step>21 } {
    print "robot reset dialog completed"
    $dlg deactivate
}

}

# ===================================================

proc roboState_changed {} {
print "roboState_changed"
# this function will be called from sequence.tcl

# since we do not know if the control w_labeRobotState exists we catch any exception
catch {
# update the state of the control elements in Robot window
global gConfig
set w_labeRobotState $gConfig(robot,labeRobotState)
set state $gConfig(robot,robotState)
if { $state>0 } {
   $w_labeRobotState config -text "Robot reset required (state=$state)" -foreground red
} else {
   $w_labeRobotState config -text "Robot is ready for action" -foreground black
}

}

}

# ===================================================
# ===================================================
# ===================================================
# ===================================================
