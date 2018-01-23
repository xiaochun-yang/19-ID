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

package provide BLUICEStatusBar 1.0

# load the required standard packages
package require Itcl
package require Iwidgets
package require BWidget

# load the DCS packages
package require DCSButton
package require DCSPrompt
package require DCSLabel
package require DCSDeviceFactory


#The Destroyer class is used to kill the application quickly.
#I'm created this class for the following reasons:
# 1) I couldn't find a way to trap the SIGHUP signal.
# 2) The incr widget components are destroyed before the top destructor is executed.
# 3) Looking up the stack in a destructor doesn't tell you who is destroying it and why.
# 4) Calling all of the destructors in an application takes almost as long as creating the app!
#
# How to use:  Add this component to widgets that only will get destroyed when the application
# is being destroyed.  For example, in blu-ice the status bar is such a widget.  You can
# also just add it to the . window path.
#
# Caveats: The destructors for the widgets seem to be called in the order that they were created.
# This means that you should add this component before all of the other components are created.
# It may be that if you add many components at the same level, that the destructors may be
# called in a different order (I don't know).  You would have to play with this order after add components
# at the same level.
 
class Destroyer {
	inherit ::itk::Widget


   constructor {args} {
   }

   destructor {killFast}

   private method killFast {} {
      global errorInfo

      #check for an error message that is always there on clean shutdown
      if { [string first .help_shell $errorInfo] == -1 } {
         #print the last error
         puts $errorInfo
      }

      #kill this process with a strong kill signal.
      exec kill -9 [pid]
   }
}

###display spear current
###and also beamlineOpenState
class SpearStatus {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handleOpenStateChange
    public method handleBeamCurrentChange
    public method handleStatusChange
    public method handleStateChange

    public method handleParameterChange

    private method updateLabel

    private variable m_deviceFactory
    private variable m_strOpenState
    private variable m_strBeamCurrent
    private variable m_strParameters
    private variable m_strState

    private variable m_ctsBeamCurrent 0.0
    private variable m_ctsOpenState   Closed
    private variable m_ctsParameter ""
    private variable m_ctsState Down

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_strOpenState [$m_deviceFactory createString beamlineOpenState]
        set m_strBeamCurrent [$m_deviceFactory createString spear_current]
        set m_strParameters [$m_deviceFactory createString optimizedEnergyParameters]
        set m_strState [$m_deviceFactory createString spearState]

        itk_component add ll {
            label $itk_interior.ll \
            -width 14 \
            -text "Ring Current: "
        } {
            keep -background
            keep -font
        }

        itk_component add current {
            label $itk_interior.cur \
            -justify right \
            -text "unknown" \
            -relief sunken
        } {
            keep -background
            keep -font
            keep -width
        }

        itk_component add mm {
            label $itk_interior.mm \
            -text mA
        } {
            keep -background
            keep -font
        }

        pack $itk_component(ll) -side left
        pack $itk_component(current) -side left
        pack $itk_component(mm) -side left
        eval itk_initialize $args

        $m_strBeamCurrent register $this contents handleBeamCurrentChange
        $m_strBeamCurrent register $this status   handleStatusChange
        $m_strOpenState   register $this contents handleOpenStateChange
        $m_strParameters  register $this contents handleParameterChange
        $m_strState       register $this contents handleStateChange

    }
    destructor {
        $m_strBeamCurrent unregister $this contents handleBeamCurrentChange
        $m_strBeamCurrent unregister $this status   handleStatusChange
        $m_strOpenState   unregister $this contents handleOpenStateChange
        $m_strParameters  unregister $this contents handleParameterChange
        $m_strState       unregister $this contents handleStateChange
    }
}
body SpearStatus::handleOpenStateChange { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctsOpenState $contents_

    updateLabel
}

body SpearStatus::handleStateChange { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctsState $contents_

    updateLabel
}

body SpearStatus::updateLabel { } {
    set local_copy $m_ctsBeamCurrent

    set tt "Ring Current:"
    set fg black
    if {$m_ctsOpenState == "Closed"} {
        $itk_component(ll) configure \
        -text "Ring Closed:" \
        -foreground red
        return
    }
#    if {$m_ctsState != "Beams"} {
#        $itk_component(ll) configure \
#        -text "Ring $m_ctsState:" \
#        -foreground red
#        return
#    }

    if {$m_ctsState != "Beams"} {
        $itk_component(ll) configure \
        -text "Ring Current:" \
        -foreground red
        return
    }


    if {![string is double -strict $m_ctsBeamCurrent]} {
        $itk_component(ll) configure \
        -text "Ring Closed: " \
        -foreground red
        return
    }

    set checkSpearCurrent [lindex $m_ctsParameter 32]
    set minCurrent        [lindex $m_ctsParameter 33]

    if {$checkSpearCurrent == "1" \
    && [string is double -strict $minCurrent] \
    && $m_ctsBeamCurrent < $minCurrent} {
        $itk_component(ll) configure \
        -text "Ring Cur. Low:" \
        -foreground red
        return
    }

    $itk_component(ll) configure \
    -text "Ring Current:" \
    -foreground black
}

body SpearStatus::handleBeamCurrentChange { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctsBeamCurrent $contents_
    updateLabel

    if {[string is double -strict $contents_]} {
        set display [format "%.3f" $contents_]

    } else {
        set display $contents_
    }
    $itk_component(current) configure -text $display
#	log_error "yangxx display=$display"
}
body SpearStatus::handleStatusChange { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    if {$contents_ != "inactive"} {
        $itk_component(current) configure -text unknow
    }
}
body SpearStatus::handleParameterChange { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctsParameter $contents_
    updateLabel
}

###display LCLS XPP status.
### the logical is copied from XRayLaserStatus.edl
class LCLSStatus {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handleNEHLight
    public method handleNEHStopper
    public method handleXppStopper
    public method handleS3Stopper
    public method handlePosOut
    public method handleBeamCurrentChange
    public method handleStatusChange

    private method updateLabel

    private variable m_deviceFactory

    private variable m_strNEHLightState
    private variable m_strNEHStopper
    private variable m_strXppStopper
    private variable m_strS3Stopper
    private variable m_strXppPosOut
    private variable m_strBeamCurrent

    private variable m_ctxNEHLight   0
    private variable m_ctxNEHStopper   1
    private variable m_ctxXppStopper   1
    private variable m_ctxS3Stopper 1
    private variable m_ctxXppPosOut 1
    private variable m_ctsBeamCurrent 0.0

    private variable m_origBG gray

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_strXppStopper [$m_deviceFactory createString xppStopperRBV]
        set m_strNEHStopper [$m_deviceFactory createString xppNEHStopper]
        set m_strNEHLightState [$m_deviceFactory createString xppNEHLightState]
        set m_strBeamCurrent [$m_deviceFactory createString xppPeakCurrent]
        set m_strS3Stopper [$m_deviceFactory createString xppS3topper]
        set m_strXppPosOut [$m_deviceFactory createString xppPOSOUT]

        itk_component add ll {
            label $itk_interior.ll \
            -width 14 \
            -text "LCLS Current: "
        } {
            keep -background
            keep -font
        }
        set m_origBG [$itk_component(ll) cget -background]

        itk_component add current {
            label $itk_interior.cur \
            -justify right \
            -text "unknown" \
            -relief sunken
        } {
            keep -background
            keep -font
            keep -width
        }

        itk_component add mm {
            label $itk_interior.mm \
            -text A
        } {
            keep -background
            keep -font
        }

        pack $itk_component(ll) -side left
        pack $itk_component(current) -side left
        pack $itk_component(mm) -side left
        eval itk_initialize $args

        $m_strBeamCurrent register $this contents handleBeamCurrentChange
        $m_strBeamCurrent register $this status   handleStatusChange
        $m_strXppStopper   register $this contents handleXppStopper
        $m_strNEHStopper   register $this contents handleNEHStopper
        $m_strNEHLightState   register $this contents handleNEHLight
        $m_strS3Stopper   register $this contents handleS3Stopper
        $m_strXppPosOut   register $this contents handlePosOut

    }
    destructor {
        $m_strBeamCurrent unregister $this contents handleBeamCurrentChange
        $m_strBeamCurrent unregister $this status   handleStatusChange
        $m_strXppStopper   unregister $this contents handleXppStopper
        $m_strNEHStopper   unregister $this contents handleNEHStopper
        $m_strNEHLightState unregister $this contents handleNEHLight
        $m_strS3Stopper   unregister $this contents handleS3Stopper
        $m_strXppPosOut   unregister $this contents handlePosOut
    }
}
body LCLSStatus::handleXppStopper { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctxXppStopper $contents_
    updateLabel
}
body LCLSStatus::handleS3Stopper { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctxS3Stopper $contents_
    updateLabel
}
body LCLSStatus::handlePosOut { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctxXppPosOut $contents_
    updateLabel
}

body LCLSStatus::handleNEHStopper { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctxNEHStopper $contents_

    updateLabel
}
body LCLSStatus::handleNEHLight { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctxNEHLight $contents_

    updateLabel
}

body LCLSStatus::updateLabel { } {
    if {$m_ctxS3Stopper != "0" && $m_ctxXppPosOut != "0"} {
        $itk_component(ll) configure \
        -text "XPP No Laser:" \
        -foreground red \
        -background black

        return
    }
    if {$m_ctxNEHStopper != "0"} {
        $itk_component(ll) configure \
        -text "NEH Stopper:" \
        -foreground red \
        -background black

        return
    }

    if {![string is double -strict $m_ctxXppStopper] \
    || abs($m_ctxXppStopper) >= 13.5} {
        $itk_component(ll) configure \
        -text "XPP Stopper:" \
        -background yellow \
        -foreground red

        return
    }
    if {[string is double -strict $m_ctsBeamCurrent] \
    && $m_ctsBeamCurrent < 2000} {
        $itk_component(ll) configure \
        -text "LCLS Cur. Low:" \
        -background yellow \
        -foreground red

        return
    }

    $itk_component(ll) configure \
    -text "XPP Open:" \
    -background purple \
    -foreground black
}
body LCLSStatus::handleBeamCurrentChange { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    set m_ctsBeamCurrent $contents_
    updateLabel

    if {[string is double -strict $contents_]} {
        set display [format "%.0f" $contents_]

    } else {
        set display $contents_
    }
    $itk_component(current) configure -text $display
}
body LCLSStatus::handleStatusChange { name_ targetReady_ - contents_ - } {
    if { ! $targetReady_} return

    if {$contents_ != "inactive"} {
        $itk_component(current) configure -text unknow
    }
}

class TimeWidget {
   inherit ::itk::Widget
 
   private common midhighlight #e0e0f0
   private common smallFont *-helvetica-bold-r-normal--14-*-*-*-*-*-*-*

   public method updateTime

   constructor {args} {  
	   # the time widget

      itk_component add time { 
	      iwidgets::timefield $itk_interior.t \
		      -relief flat -textbackground $midhighlight  \
		   -textfont $smallFont
      } {}

      eval itk_initialize $args
   
      bind $itk_interior <FocusIn> {focus . }

      pack $itk_component(time) -side right
   
	   updateTime
   }

}

body TimeWidget::updateTime {} {

	#$itk_component(time) configure -state normal
	$itk_component(time) show
	#$itk_component(time) configure -state disabled

	after 950 [list $this updateTime]
}
class SystemStatus {
    inherit ::itk::Widget

    public method handleClientState
    public method handleSystemStatus

    public method updateDisplay { }

    private variable m_objSystemStatus

    private variable m_strClientState "offline"
    private variable m_strSystemStatus [list "Detector Ready" black #00a040]

    #options
	itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_objSystemStatus [$m_deviceFactory createString system_status]

        itk_component add ring {
            frame $itk_interior.r
        }
        itk_component add label {
            label $itk_component(ring).l \
            -text "" \
            -state active \
            -justify left \
            -anchor w
        } {
            keep -width -relief -font
        }
        pack $itk_component(label)
        pack $itk_component(ring)

        eval itk_initialize $args

        #register with updates
        $itk_option(-controlSystem) register $this clientState handleClientState
        $m_objSystemStatus          register $this contents handleSystemStatus
    }
    destructor {
        $itk_option(-controlSystem) unregister $this clientState handleClientState

        $m_objSystemStatus          unregister $this contents handleSystemStatus
    }
}
body SystemStatus::handleClientState { name_ targetReady_ alias_ contents_ - } {
    if { ! $targetReady_} return

    #puts "handleClientState $contents_"
    set m_strClientState $contents_
    updateDisplay
}
body SystemStatus::handleSystemStatus { name_ targetReady_ alias_ contents_ - } {
    if { ! $targetReady_} return

    #puts "handleSystemStatus $contents_"

    set m_strSystemStatus $contents_

    updateDisplay
}
body SystemStatus::updateDisplay { } {
    if {$m_strClientState == "offline"} {
        if {![$itk_option(-controlSystem) cget -clientAuthed]} {
            set display "Logged Out"
        } else {
            set socketGood [$itk_option(-controlSystem) cget -_socketGood]
            if {$socketGood} {
                set display "Logged Out by DCSS"
            } else {
                set display "DCSS server Offline"
            }
        }

        $itk_component(label) config \
        -text $display \
        -foreground black \
        -activeforeground black \
        -background red \
        -activebackground red 
        return
    }

    if {[llength $m_strSystemStatus] >= 3} {
        foreach {display fg bg} $m_strSystemStatus break
    } else {
        set display "system_status not defined"
        set fg black
        set bg red
    }

    $itk_component(label) config \
    -text $display \
    -foreground $fg \
    -activeforeground $fg \
    -background $bg \
    -activebackground $bg
}
class StatusBar {
	inherit ::itk::Widget

	itk_option define -controlSystem controlSystem ControlSystem "::dcss"
	itk_option define -validSessionCallback validSessionCallback ValidSessionCallback ""

   public method handleShutter
   public method handleXppShutter
   public method handleXppSetupConfig
   public method updateShutterDisplay
   public method toggleShutter { } {
   	if { $m_shutterState == "closed" } {
		set bp [lindex [::device::beamstop_horz getScaledPosition] 0]
		if {abs([expr $bp - 359]) > 0.2} {
            		set answer \
                	[tk_messageBox \
               		-icon question \
               		-type yesno \
               		-title Message \
               		-parent . \
               		-message "Beamstop is off the beam center! Do you want to open the Shutter?"]          
        		if { $answer == "yes" } {
				$m_objShutter open
                		puts "Yes open it beamstop=$bp"
        		} else {
                		puts "no don't open it"
        		}
		} else {
			$m_objShutter open
		}
   	} elseif {$m_shutterState == "open"} {
		$m_objShutter close
	}	
   #     log_error no control.
    }

    public method saveSnapshot { ask } {
        global env

        update
        set imgSnapshot [image create photo -palette "256/256/256" -format window -data .]

        ### file path
        set tsForFileName [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
        set filePath [file join ~$env(USER) bluice_snapshot_$tsForFileName.jpg]
        if {$ask} {
            set types [list [list JPEG .jpg]]

            set cmd [list tk_getSaveFile \
            -filetypes $types \
            -defaultextension $m_previousExt \
            -initialdir $m_previousDir \
            ]

            if {$m_previousPrefix != "" \
            && [string is integer -strict $m_previousNumDig] \
            && [string is integer -strict $m_previousCounter]} {
                set next [expr $m_previousCounter + 1]
                set lNext [format "%0${m_previousNumDig}d" $next]

                set nextFile ${m_previousPrefix}$lNext$m_previousExt

                lappend cmd -initialfile $nextFile
            }

            set filePath [eval $cmd]

            if {$filePath == ""} {
                return
            }

            set m_previousDir [file dirname $filePath]

            if {[catch {
                parseFileNameForCounter $filePath \
                m_previousPrefix m_previousNumDig m_previousCounter \
                m_previousExt
            } errMsg]} {
                set m_previousPrefix ""
                set m_previousNumDig ""
                set m_previousCounter ""
            }
        }

        if {[catch {
            $imgSnapshot write $filePath -format {jpeg -quality 100}
        } errMsg]} {
            log_error failed to save snapshot: $errMsg
        } else {
            log_warning snapshot saved to $filePath
        }
        image delete $imgSnapshot
    }


    private variable m_deviceFactory
    private variable m_logger

    global env
    private variable m_previousDir ~$env(USER)
    private variable m_previousPrefix ""
    private variable m_previousNumDig ""
    private variable m_previousCounter ""
    private variable m_previousExt ".jpg"

    private variable m_shutterState closed
    private variable m_xppShutterState closed
    private variable m_ctxXppSetupConfig ""

    private variable m_objShutter ""
    private variable m_objXppShutter ""

   #colors
   private common midhighlight #e0e0f0
   private common smallFont *-helvetica-bold-r-normal--14-*-*-*-*-*-*-*
	# public methods
	constructor { args } {
		
      set m_deviceFactory [DCS::DeviceFactory::getObject]
      set m_logger [DCS::Logger::getObject]

      itk_component add destroyer {
         Destroyer $itk_interior.destroyer
      } {}


        itk_component add clientStatusLabel {
            label $itk_interior.cs -text "User:"
        } {
            keep -background
            keep -font
        }

		itk_component add activeButton {
			# create the apply button
			::DCS::ActiveButton $itk_interior.active -width 6
		} {
         keep -background
         keep -font
		}
		
		# create the stop button
		itk_component add abort {
			::DCS::Button $itk_interior.stop \
				 -text "Abort" \
				 -background \#ffaaaa \
				 -activebackground \#ffaaaa \
				 -activeClientOnly 0 -width 8 -systemIdleOnly 0
		} {
			keep -font -height -state
			keep -activeforeground -foreground -relief 
		}


		#string messages
		itk_component add dcss_status {
			SystemStatus $itk_interior.sysStatus \
				 -relief sunken -width 50
		} {
            keep -font
		}

		itk_component add l_shutter {
			label $itk_interior.l_shutter \
            -text "Shutter: "
		} {
         keep -background
         keep -font
		}
		
		itk_component add shutter {
			label $itk_interior.shutter \
			-relief sunken -width 8
		} {
         keep -font
		}

        if {[::config getConfigRootName] == "BL-XPP"} {
            set acceleratorStatusClass LCLSStatus
        } else {
            set acceleratorStatusClass SpearStatus
        }

        itk_component add accl_status {
            $acceleratorStatusClass $itk_interior.accl_status \
            -width 8
        } {
            keep -background
            keep -font
        }
		

      itk_component add time {
         TimeWidget $itk_interior.t
      } {}
	

        global BLC_IMAGES
        set ssImg [image create photo -file $BLC_IMAGES/camera.jpg]

		itk_component add snapshot {
			label $itk_interior.snapshot \
            -image $ssImg \
		} {
		}
        bind $itk_component(snapshot) <Button-1> "$this saveSnapshot 0"
        bind $itk_component(snapshot) <Button-3> "$this saveSnapshot 1"

		eval itk_initialize $args

		set m_objShutter [$m_deviceFactory createShutter shutter]
        $m_objShutter register $this state handleShutter

        if {[::config getConfigRootName] == "BL-XPP"} {
		    set m_objXppShutter [$m_deviceFactory createShutter xppShutter]
            set objXppSetupConfig \
            [$m_deviceFactory createString xpp_setup_config]

            $m_objXppShutter register $this state handleXppShutter
            $objXppSetupConfig register $this contents handleXppSetupConfig
        }

		$itk_component(abort) configure \
        -command "$itk_option(-controlSystem) abort"
        #grid columnconfigure $itk_interior 0 -pad 5 
		grid $itk_component(dcss_status) -row 0 -column 0 -sticky w -padx 5
		grid $itk_component(accl_status) -row 0 -column 1 -sticky w -padx 5
		grid $itk_component(abort) -row 0 -column 2 -sticky w
		grid $itk_component(clientStatusLabel) -row 0 -column 3 -sticky w
		grid $itk_component(activeButton) -row 0 -column 4 -sticky w
		grid $itk_component(l_shutter) -row 0 -column 5 -sticky w -padx 5
		grid $itk_component(shutter) -row 0 -column 6 -sticky w -padx 5
		grid $itk_component(time) -row 0 -column 7 -sticky w
		grid $itk_component(snapshot) -row 0 -column 8 -sticky e

        grid columnconfig $itk_interior 8 -weight 10

		#bind a click on the shutter to toggle the state.  Replace this with a button!
		#bind $itk_component(shutter) <Button-1> "$m_objShutter toggle"
		bind $itk_component(shutter) <Button-1> "$this toggleShutter"
  
      configure -background $midhighlight
      #configure -disabledbackground $midhighlight
      configure -font $smallFont

      ::mediator announceExistence $this
	}
}

body StatusBar::handleShutter { - targetReady_ alias_ status_ -} {
    if {! $targetReady_} return
    set m_shutterState $status_
    updateShutterDisplay
}
body StatusBar::handleXppShutter { - targetReady_ alias_ status_ -} {
    if {! $targetReady_} return
    set m_xppShutterState $status_
    updateShutterDisplay
}
body StatusBar::handleXppSetupConfig { - ready_ - contents_ - } {
    if {! $ready_} return
    set m_ctxXppSetupConfig $contents_
    updateShutterDisplay
}
body StatusBar::updateShutterDisplay { } {
    set usePulsePicker [lindex $m_ctxXppSetupConfig 5]
    if {$usePulsePicker == "1"} {
        $itk_component(l_shutter) config \
        -text "XPP Shutter:"

        set status $m_xppShutterState
    } else {
        $itk_component(l_shutter) config \
        -text "Shutter:"
        set status $m_shutterState
    }
    set red #c04080
    if {$status == "open"} {
        set background $red
    } else {
        set background $midhighlight 
    }
    $itk_component(shutter) config \
    -text $status \
    -background $background
}
   
proc testStatusBar { } {
	
	StatusBar .test
	pack .test
}

#testStatusBar
