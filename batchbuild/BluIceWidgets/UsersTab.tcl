#!/bin/sh
# the next line restarts using -*-Tcl-*-sh \
	 exec wish "$0" ${1+"$@"}
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

package provide BLUICEUsersTab 1.0

# load the required standard packages
package require Itcl
package require Iwidgets
package require BWidget
package require BLT

# load the DCS packages
package require DCSButton
package require DCSPrompt
package require DCSClientList
package require DCSLogView
package require BLUICEChangeOver
package require BLUICEClientStatusView

class UsersTab {
	inherit ::itk::Widget

	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_strClientState "offline"

	# public methods
    public method handleClientState

    ### remove after pushout for user
    public method handleStaff

	constructor { args } {
		
		#create the usersTab

        itk_component add note {
            label $itk_interior.note \
            -foreground red \
            -justify left \
            -text \
            "Your BluIce session has expired.\n\
            Please enter you Unix account name\n\
            and passord to restart the BluIce session."
        } {
        }

		itk_component add login {
			DCS::Login $itk_interior.login
		} {
		}

        itk_component add pw_h {
            iwidgets::panedwindow $itk_interior.pw -orient horizontal
        } {
        }
        $itk_component(pw_h) add top -minimum 50 -margin 2
        $itk_component(pw_h) add middle -minimum 50 -margin 2
        $itk_component(pw_h) add bottom -minimum 50 -margin 2

        set topSite    [$itk_component(pw_h) childsite 0]
        set middleSite [$itk_component(pw_h) childsite 1]
        set bottomSite [$itk_component(pw_h) childsite 2]

        $itk_component(pw_h) fraction 30 30 40


		itk_component add clientList {
			ClientStatusView $topSite.u
		} {
		}
		pack $itk_component(clientList) -expand 1 -fill both

        itk_component add notifyF {
			::DCS::TitledFrame $middleSite.fNotify \
            -labelText \
            {Notification Setup      (email addresses separated by "," )}
        } {
        }
        set notifySite [$itk_component(notifyF) childsite]

        itk_component add notify_setup {
            UserNotifySetupView $notifySite.setup
        } {
        }
        pack $itk_component(notify_setup) -expand 1 -fill both
        pack $itk_component(notifyF) -expand 1 -fill both

        itk_component add chatF {
			::DCS::TitledFrame $bottomSite.fChat \
            -labelText "Chat Room"
        } {
        }
        set chatSite [$itk_component(chatF) childsite]

        itk_component add chat_room {
            DCS::UserChatView $chatSite.chat
        } {
        }

        pack $itk_component(chat_room) -expand 1 -fill both
        pack $itk_component(chatF) -expand 1 -fill both
		
		eval itk_initialize $args
		
		grid $itk_component(note) -row 0 -column 0
		grid $itk_component(login) -row 1 -column 0
		grid $itk_component(pw_h) -row 2 -column 0 -sticky news

		grid rowconfigure $itk_interior 0 -weight 0
		grid rowconfigure $itk_interior 1 -weight 0
		grid rowconfigure $itk_interior 2 -weight 10
		grid columnconfigure $itk_interior 0 -weight 1

        $itk_option(-controlSystem) register $this clientState handleClientState
        $itk_option(-controlSystem) register $this staff handleStaff
	}
    destructor {
        $itk_option(-controlSystem) unregister $this staff handleStaff
        $itk_option(-controlSystem) unregister $this clientState handleClientState
    }
}
body UsersTab::handleClientState { name_ targetReady_ alias_ contents_ - } {
    if { ! $targetReady_} return

    set showLogin 0
    set m_strClientState $contents_
    if {$m_strClientState == "offline"} {
        if {![$itk_option(-controlSystem) cget -clientAuthed]} {
            set display "Logged Out"
            set showLogin 1
        } else {
            set socketGood [$itk_option(-controlSystem) cget -_socketGood]
            if {$socketGood} {
                set display "Logged Out by DCSS"
                set showLogin 1
            } else {
                set display "DCSS server Offline"
            }
        }
        puts "offline: $display"
    }
    if {$showLogin} {
		grid $itk_component(note) -row 0 -column 0
		grid $itk_component(login) -row 1 -column 0
    } else {
		grid forget $itk_component(note)
		grid forget $itk_component(login)
    }
}
body UsersTab::handleStaff { - targetReady_ - staff_ - } {
    if {!$targetReady_} return

    if {$staff_} {
		$itk_component(pw_h) show 1
        $itk_component(pw_h) fraction 30 30 40
    } else {
		$itk_component(pw_h) hide 1
        $itk_component(pw_h) fraction 30 70
    }
}
