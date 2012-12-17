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
package provide DCSButton 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory
package require ComponentGateExtension


class DCS::Button {
#	inherit ::itk::Widget ::DCS::ComponentGate
    inherit ::DCS::ComponentGateExtension

    itk_option define -state state State "normal"
    itk_option define -debounceTime debounceTime DebounceTime 200
    itk_option define -command command Command ""
    public method handleClick {}

    ###override base class function to handle debounce
    public method handleNewOutput {}

    ### give derived class a chance to run command without hooking to -command
    protected method internalOnCommand { } { }

	constructor { args } {
	    if { [info tclversion] < 8.4 } {
		    itk_component add button {
			    # create the button
			    button $itk_interior.b -command "$this handleClick"
		    } {
			    keep -text -font -width -height -image
                keep -activebackground -disabledforeground
			    keep -activeforeground -background -foreground -relief
			    keep -padx -pady
                keep -anchor
		    }
        } else {
		    itk_component add button {
			    # create the button
			    button $itk_interior.b -command "$this handleClick"
		    } {
			    keep -text -font -width -height -image
                keep -activebackground -disabledforeground
			    keep -activeforeground -background -foreground -relief
			    keep -padx -pady -overrelief
                keep -anchor
		    }
        }

		bind $itk_component(button) <Enter> "focus %W; focus ."

		pack $itk_component(button)
		registerComponent $itk_component(button)
		eval itk_initialize $args
		announceExist
	}

	destructor {
		unregisterComponent
	}

}
configbody DCS::Button::state {
    handleNewOutput
}

body DCS::Button::handleNewOutput { } {
    if {$itk_option(-state) != "disabled"} {
        DCS::ComponentGateExtension::handleNewOutput
    } else {
        $itk_component(button) configure -state disabled
    }
}

body DCS::Button::handleClick {} {
    if {$itk_option(-debounceTime) > 0} {
	    configure -state disabled

	    if { [catch {eval $itk_option(-command)} err] } {
		    puts $err
	    }

        if {[catch internalOnCommand err]} {
            puts $err
        }

	    after $itk_option(-debounceTime) [list $this configure -state normal]
    } else {
	    if { [catch {eval $itk_option(-command)} err] } {
		    puts $err
	    }

        if {[catch internalOnCommand err]} {
            puts $err
        }
    }
}


class DCS::ActiveButton {

	# inheritance
	inherit ::DCS::Button

	itk_option define -activeColor activeColor ActiveColor  red
	itk_option define -passiveColor passiveColor PassiveColor black
	itk_option define -controlSystem controlsytem ControlSystem ::dcss

	private variable _clientState offline

	public method changeClientState 
	public method handleClick {}
   public method updateState

	constructor { args } {
		
      configure -activeClientOnly 0
      configure -systemIdleOnly 0

		configure -command "$this handleClick"
      configure -pady 1
		eval itk_initialize $args
      configure -debounceTime 2000
		announceExist
	}
}

configbody DCS::ActiveButton::controlSystem {

	# set up reference to the client's state
	::mediator register $this ::$itk_option(-controlSystem) clientState changeClientState
}

body DCS::ActiveButton::handleClick {} {


	switch $_clientState {
		passive {
	    #$itk_component(button) configure -text "Requesting"
	    configure -state disabled
        update
        $itk_option(-controlSystem) becomeActive
      }
		active {
	    #$itk_component(button) configure -text "Releasing"
	    configure -state disabled
        update
        $itk_option(-controlSystem) becomePassive
      }

		default {}
	}

	after $itk_option(-debounceTime) [list $this configure -state normal]
}


body DCS::ActiveButton::changeClientState { - targetReady alias value - } {
	
    set _clientState $value
    updateState

}


body DCS::ActiveButton::updateState { } {
	switch $_clientState {
		active {
#			$itk_component(button) configure -state normal
			$itk_component(button) configure -text "Active"
			$itk_component(button) configure -relief sunken
			$itk_component(button) configure -foreground $itk_option(-activeColor)
			$itk_component(button) configure -activeforeground $itk_option(-activeColor)
		}
		passive {
#			$itk_component(button) configure -state normal
			$itk_component(button) configure -text "Passive"
			$itk_component(button) configure -relief sunken 
			$itk_component(button) configure -foreground $itk_option(-passiveColor)
			$itk_component(button) configure -activeforeground $itk_option(-passiveColor)
		}
		offline {
#			$itk_component(button) configure -state disabled
			$itk_component(button) configure -text "Offline"
			$itk_component(button) configure -relief sunken
		}
		default {
#			$itk_component(button) configure -state disabled
			$itk_component(button) configure -text "Unknown"
			$itk_component(button) configure -relief sunken
		}
	}
}

class DCS::ArrowButton {
	
	# inheritance
	inherit ::DCS::Button

	# public variables
	public variable direction right

	public common leftArrowImage
	set leftArrowImage [image create bitmap -data \
		"#define hide_width 16
		#define hide_height 16
    	static unsigned char hide_bits[] = {
   0x00, 0x00, 0x00, 0x04, 0x00, 0x06, 0x00, 0x07, 0x80, 0x07, 0xc0, 0x07,
   0xe0, 0x07, 0xf0, 0x07, 0xf8, 0x07, 0xf0, 0x07, 0xe0, 0x07, 0xc0, 0x07,
   0x80, 0x07, 0x00, 0x07, 0x00, 0x06, 0x00, 0x04};"]	\

	public common fastLeftArrowImage
	set fastLeftArrowImage [image create bitmap -data \
		"#define hide_width 16
		#define hide_height 16
    	static unsigned char hide_bits[] = {
  0x00, 0x00, 0x80, 0x80, 0xc0, 0xc0, 0xe0, 0xe0, 0xf0, 0xf0, 0xf8, 0xf8,
   0xfc, 0xfc, 0xfe, 0xfe, 0xff, 0xff, 0xfe, 0xfe, 0xfc, 0xfc, 0xf8, 0xf8,
   0xf0, 0xf0, 0xe0, 0xe0, 0xc0, 0xc0, 0x80, 0x80};"]

	public common rightArrowImage
	set rightArrowImage [image create bitmap -data \
		"#define maximize_width 16
		#define maximize_height 16
		static unsigned char maximize_bits[] = {
   0x00, 0x00, 0x40, 0x00, 0xc0, 0x00, 0xc0, 0x01, 0xc0, 0x03, 0xc0, 0x07,
   0xc0, 0x0f, 0xc0, 0x1f, 0xc0, 0x3f, 0xc0, 0x1f, 0xc0, 0x0f, 0xc0, 0x07,
   0xc0, 0x03, 0xc0, 0x01, 0xc0, 0x00, 0x40, 0x00};"]

	public common fastRightArrowImage
	set fastRightArrowImage [image create bitmap -data \
		"#define right_width 16
      #define right_height 16
      static unsigned char right_bits[] = {
      0x00, 0x00, 0x01, 0x01, 0x03, 0x03, 0x07, 0x07, 0x0f, 0x0f, 0x1f, 0x1f,
      0x3f, 0x3f, 0x7f, 0x7f, 0xff, 0xff, 0x7f, 0x7f, 0x3f, 0x3f, 0x1f, 0x1f,
     0x0f, 0x0f, 0x07, 0x07, 0x03, 0x03, 0x01, 0x01};"]

	public common upArrowImage
	set upArrowImage [image create bitmap -data \
		"#define restore_width 16
		#define restore_height 16
		static unsigned char restore_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x80, 0x03, 0xc0, 0x07,
   0xe0, 0x0f, 0xf0, 0x1f, 0xf8, 0x3f, 0xfc, 0x7f, 0xfe, 0xff, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"]

	public common downArrowImage
	set downArrowImage [image create bitmap -data \
		"#define kill_width 16
		#define kill_height 16
		static unsigned char kill_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0xff,
   0xfc, 0x7f, 0xf8, 0x3f, 0xf0, 0x1f, 0xe0, 0x0f, 0xc0, 0x07, 0x80, 0x03,
   0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};"]

	public common horzExpandArrowImage
	set horzExpandArrowImage [image create bitmap -data \
		"#define hide_width 16
		#define hide_height 16
    	static unsigned char hide_bits[] = {
    0x40, 0x01,
    0x60, 0x03,
    0x70, 0x07,
    0x78, 0x0f,
    0x7c, 0x1f,
    0x7e, 0x3f,
    0x7f, 0x7f,
    0x7f, 0xff,
    0x7f, 0x7f,
    0x7e, 0x3f,
    0x7c, 0x1f,
    0x78, 0x0f,
    0x70, 0x07,
    0x60, 0x03,
    0x40, 0x01,
    0x00, 0x00
    };"]

	public common horzShrinkArrowImage
	set horzShrinkArrowImage [image create bitmap -data \
		"#define right_width 16
      #define right_height 16
      static unsigned char right_bits[] = {
    0x00, 0x00,
    0x01, 0x80,
    0x03, 0xc0,
    0x07, 0xe0,
    0x0f, 0xf0,
    0x1f, 0xf8,
    0x3f, 0xfc,
    0x7f, 0xfe,
    0xff, 0xff,
    0x7f, 0xfe,
    0x3f, 0xfc,
    0x1f, 0xf8,
    0x0f, 0xf0,
    0x07, 0xe0,
    0x03, 0xc0,
    0x01, 0x80
    };"]

	public common vertShrinkArrowImage
	set vertShrinkArrowImage [image create bitmap -data \
		"#define restore_width 16
		#define restore_height 16
		static unsigned char restore_bits[] = {
   0xfe, 0xff, 0xfc, 0x7f, 0xf8, 0x3f, 0xf0, 0x1f, 0xe0, 0x0f, 0xc0, 0x07, 0x80, 0x03, 0x00, 0x01
   0x01, 0x00, 0x80, 0x03, 0xc0, 0x07, 0xe0, 0x0f, 0xf0, 0x1f, 0xf8, 0x3f, 0xfc, 0x7f, 0xfe, 0xff};"]

	public common vertExpandArrowImage
	set vertExpandArrowImage [image create bitmap -data \
		"#define kill_width 16
		#define kill_height 16
		static unsigned char kill_bits[] = { 0x00, 0x00,
   0x80, 0x03, 0xc0, 0x07, 0xe0, 0x0f, 0xf0, 0x1f, 0xf8, 0x3f, 0xfc, 0x7f,
   0xfe, 0xff, 0x00, 0x00, 0xfe, 0xff, 0xfc, 0x7f, 0xf8, 0x3f, 0xf0, 0x1f,
   0xe0, 0x0f, 0xc0, 0x07, 0x80, 0x03};"]

	constructor { direction  args } {
		
		# handle configuration options
		eval itk_initialize $args
		
		switch $direction {
			left -
			fastLeft -
			right -
			fastRight -
			up -
			down -
            horzExpand -
            horzShrink -
            vertExpand -
            vertShrink {
				$itk_component(button) configure -image [set ${direction}ArrowImage]
            }
		}
	}
}




class DCS::ArrowPad {
	
	# inheritance
	inherit itk::Widget

	itk_option define -leftCommand leftCommand LeftCommand ""
	itk_option define -rightCommand rightCommand RightCommand ""
	itk_option define -upCommand upCommand UpCommand ""
	itk_option define -downCommand downCommand DownCommand ""

	itk_option define -fastLeftCommand fastLeftCommand FastLeftCommand ""
	itk_option define -fastRightCommand fastRightCommand FastRightCommand ""

	public method addInput

	constructor { args } {
		
		itk_component add upArrow {
			DCS::ArrowButton $itk_interior.u up
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add downArrow {
			DCS::ArrowButton $itk_interior.d down
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add leftArrow {
			DCS::ArrowButton $itk_interior.l left
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add rightArrow {
			DCS::ArrowButton $itk_interior.r right
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}


		itk_component add fastLeftArrow {
			DCS::ArrowButton $itk_interior.fl fastLeft
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add fastRightArrow {
			DCS::ArrowButton $itk_interior.fr fastRight
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		# handle configuration options
		eval itk_initialize $args

      #grid rowconfigure $itk_interior 2 -weight 1
      #grid columnconfigure $itk_interior 2 -weight 1
	}
}

configbody ::DCS::ArrowPad::upCommand {
	if {$itk_option(-upCommand) != "" } {
		$itk_component(upArrow) configure -command $itk_option(-upCommand)
		grid $itk_component(upArrow) -column 2 -row 1 -sticky n
	}
}

configbody ::DCS::ArrowPad::downCommand {
	if {$itk_option(-downCommand) != "" } {
		$itk_component(downArrow) configure -command $itk_option(-downCommand)
		grid $itk_component(downArrow) -column 2 -row 3 -sticky s
	}
}

configbody ::DCS::ArrowPad::leftCommand {
	if {$itk_option(-leftCommand) != "" } {
		$itk_component(leftArrow) configure -command $itk_option(-leftCommand)
		grid $itk_component(leftArrow) -column 1 -row 2 -sticky e
	}
}

configbody ::DCS::ArrowPad::rightCommand {
	if {$itk_option(-rightCommand) != "" } {
		$itk_component(rightArrow) configure -command $itk_option(-rightCommand)
		grid $itk_component(rightArrow) -column 3 -row 2 -sticky w
	}
}

configbody ::DCS::ArrowPad::fastLeftCommand {
	if {$itk_option(-fastLeftCommand) != "" } {
		$itk_component(fastLeftArrow) configure -command $itk_option(-fastLeftCommand)
		grid $itk_component(fastLeftArrow) -column 0 -row 2
	}
}

configbody ::DCS::ArrowPad::fastRightCommand {
	if {$itk_option(-fastRightCommand) != "" } {
		$itk_component(fastRightArrow) configure -command $itk_option(-fastRightCommand)
		grid $itk_component(fastRightArrow) -column 4 -row 2
	}
}

#overide the base class definition.
body DCS::ArrowPad::addInput { direction_ input_ } {
	switch $direction_ {

		all {
			$itk_component(upArrow) addInput $input_
			$itk_component(downArrow) addInput $input_
			$itk_component(leftArrow) addInput $input_
			$itk_component(rightArrow) addInput $input_
			$itk_component(fastLeftArrow) addInput $input_
			$itk_component(fastRightArrow) addInput $input_
		}

		up { $itk_component(upArrow) addInput $input_ }
		
		down { $itk_component(downArrow) addInput $input_ }

		left { $itk_component(leftArrow) addInput $input_ }
		
		right { $itk_component(rightArrow) addInput $input_ }

		fastLeft { $itk_component(fastLeftArrow) addInput $input_ }
		
		fastRight { $itk_component(fastRightArrow) addInput $input_ }
	}
}


class DCS::HotButton {
 	inherit ::itk::Widget

    itk_option define -hotTime hotTime HotTime 3000
    itk_option define -style style Style "one_button"
    itk_option define -text text Text "button"
    itk_option define -confirmText confirmText ConfirmText ""
    itk_option define -confirmBackground confirmBackground ConfirmBackground "red" {
        $itk_component(button2) configure -background $itk_option(-confirmBackground)
    }
    itk_option define -command command Command ""

    private variable m_normalBackground
    private variable m_armed 0
    private variable m_after ""

    public method addInput { args } {
        eval $itk_component(button1) addInput $args
        eval $itk_component(button2) addInput $args
    }
    public method deleteInput { args } {
        eval $itk_component(button1) deleteInput $args
        eval $itk_component(button2) deleteInput $args
    }

    private method arm { } {
        if {$itk_option(-style) == "one_button"} {
            if {$itk_option(-confirmText) != ""} {
                $itk_component(button1) configure \
                -text $itk_option(-confirmText)
            }
            $itk_component(button1) configure \
            -background $itk_option(-confirmBackground)
        } else {
            $itk_component(button2) configure \
            -state normal
        }
        set m_armed 1
        set m_after [after $itk_option(-hotTime) "$this reset"]
    }

    public method reset { } {
        set m_armed 0
        if {$itk_option(-style) == "one_button"} {
            $itk_component(button1) configure \
            -text $itk_option(-text) \
            -background $m_normalBackground
        } else {
            $itk_component(button2) configure \
            -state disabled
        }
    }
    public method repack { } {
        pack forget $itk_component(button1)
        pack forget $itk_component(button2)
        if {$itk_option(-style) == "one_button"} {
            pack $itk_component(button1) -side top
        } else {
            pack $itk_component(button1) -side top
            pack $itk_component(button2) -side top
        }
        reset
        
    }
    public method handleClick1 { } {
        if {!$m_armed} {
            arm
        } else {
            if {$itk_option(-style) == "one_button"} {
                handleClick2
            } else {
                after cancel $m_after
                reset
            }
        }
        
    }
    public method handleClick2 { } {
        if {$m_armed} {
            after cancel $m_after
            if {$itk_option(-command) != ""} {
                eval $itk_option(-command)
            }
            reset
        } else {
            puts "button2 clicked while not armed"
            $itk_component(button2) configure -state disabled
        }
    }

    constructor { args } {
        itk_component add ring {
            frame $itk_interior.ring
        } {
        }
        set site $itk_component(ring)

        itk_component add button1 {
            DCS::Button $site.b1 \
            -command "$this handleClick1"
        } {
            keep -controlSystem
	        keep -activeClientOnly
	        keep -systemIdleOnly
	        keep -controlSystem
	        keep -debounceTime
	        keep -background
            keep -text
            keep -width
            keep -font
            keep -state
        }
        itk_component add button2 {
            DCS::Button $site.b2 \
            -debounceTime 0 \
            -command "$this handleClick2"
        } {
            keep -controlSystem
	        keep -activeClientOnly
	        keep -systemIdleOnly
	        keep -controlSystem
            keep -width
            keep -font
            keep -state
            rename -text -confirmText confirmText ConfirmText
        }

		eval itk_initialize $args

        set m_normalBackground [$itk_component(button1) cget -background]

        repack
        pack $itk_component(ring) -expand 1 -fill both
    }
}

class DCS::HorizontalAreaArrows {
	
	# inheritance
	inherit itk::Widget

	itk_option define -leftCommand leftCommand LeftCommand ""
	itk_option define -rightCommand rightCommand RightCommand ""
	itk_option define -expandCommand expandCommand ExpandCommand ""
	itk_option define -shrinkCommand shrinkCommand ShrinkCommand ""

	public method addInput

	constructor { args } {
		
		itk_component add leftArrow {
			DCS::ArrowButton $itk_interior.l left
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add rightArrow {
			DCS::ArrowButton $itk_interior.r right
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add expandArrow {
			DCS::ArrowButton $itk_interior.e horzExpand
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add shrinkArrow {
			DCS::ArrowButton $itk_interior.s horzShrink
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		eval itk_initialize $args
	}
}

configbody ::DCS::HorizontalAreaArrows::leftCommand {
	if {$itk_option(-leftCommand) != "" } {
		$itk_component(leftArrow) configure \
        -command $itk_option(-leftCommand)
		grid $itk_component(leftArrow) -column 0 -row 0 -sticky w
	}
}

configbody ::DCS::HorizontalAreaArrows::expandCommand {
	if {$itk_option(-expandCommand) != "" } {
		$itk_component(expandArrow) configure \
        -command $itk_option(-expandCommand)
		grid $itk_component(expandArrow) -column 1 -row 0 -sticky w
	}
}

configbody ::DCS::HorizontalAreaArrows::shrinkCommand {
	if {$itk_option(-shrinkCommand) != "" } {
		$itk_component(shrinkArrow) configure \
        -command $itk_option(-shrinkCommand)
		grid $itk_component(shrinkArrow) -column 2 -row 0 -sticky w
	}
}

configbody ::DCS::HorizontalAreaArrows::rightCommand {
	if {$itk_option(-rightCommand) != "" } {
		$itk_component(rightArrow) configure \
        -command $itk_option(-rightCommand)
		grid $itk_component(rightArrow) -column 3 -row 0 -sticky w
	}
}

#overide the base class definition.
body DCS::HorizontalAreaArrows::addInput { input_ } {
			$itk_component(leftArrow) addInput $input_
			$itk_component(rightArrow) addInput $input_
			$itk_component(expandArrow) addInput $input_
			$itk_component(shrinkArrow) addInput $input_
}

class DCS::VerticalAreaArrows {
	# inheritance
	inherit itk::Widget

	itk_option define -upCommand upCommand UpCommand ""
	itk_option define -downCommand downCommand DownCommand ""
	itk_option define -expandCommand expandCommand ExpandCommand ""
	itk_option define -shrinkCommand shrinkCommand ShrinkCommand ""

	public method addInput

	constructor { args } {
		
		itk_component add upArrow {
			DCS::ArrowButton $itk_interior.u up
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add downArrow {
			DCS::ArrowButton $itk_interior.d down
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add expandArrow {
			DCS::ArrowButton $itk_interior.e vertExpand
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add shrinkArrow {
			DCS::ArrowButton $itk_interior.s vertShrink
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		eval itk_initialize $args
	}
}

configbody ::DCS::VerticalAreaArrows::upCommand {
	if {$itk_option(-upCommand) != "" } {
		$itk_component(upArrow) configure \
        -command $itk_option(-upCommand)
		grid $itk_component(upArrow) -column 0 -row 0 -sticky w
	}
}

configbody ::DCS::VerticalAreaArrows::expandCommand {
	if {$itk_option(-expandCommand) != "" } {
		$itk_component(expandArrow) configure \
        -command $itk_option(-expandCommand)
		grid $itk_component(expandArrow) -column 0 -row 1 -sticky w
	}
}

configbody ::DCS::VerticalAreaArrows::shrinkCommand {
	if {$itk_option(-shrinkCommand) != "" } {
		$itk_component(shrinkArrow) configure \
        -command $itk_option(-shrinkCommand)
		grid $itk_component(shrinkArrow) -column 0 -row 2 -sticky w
	}
}

configbody ::DCS::VerticalAreaArrows::downCommand {
	if {$itk_option(-downCommand) != "" } {
		$itk_component(downArrow) configure \
        -command $itk_option(-downCommand)
		grid $itk_component(downArrow) -column 0 -row 3 -sticky w
	}
}

#overide the base class definition.
body DCS::VerticalAreaArrows::addInput { input_ } {
			$itk_component(upArrow) addInput $input_
			$itk_component(downArrow) addInput $input_
			$itk_component(expandArrow) addInput $input_
			$itk_component(shrinkArrow) addInput $input_
}

class DCS::AreaMoveArrows {
	# inheritance
	inherit itk::Widget

	itk_option define -leftCommand leftCommand LeftCommand ""
	itk_option define -rightCommand rightCommand RightCommand ""
	itk_option define -upCommand upCommand UpCommand ""
	itk_option define -downCommand downCommand DownCommand ""

	public method addInput

	constructor { args } {
		
		itk_component add upArrow {
			DCS::ArrowButton $itk_interior.u up
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add downArrow {
			DCS::ArrowButton $itk_interior.d down
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}
		
		itk_component add leftArrow {
			DCS::ArrowButton $itk_interior.l left
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		itk_component add rightArrow {
			DCS::ArrowButton $itk_interior.r right
		} {
			keep -activeClientOnly
			keep -systemIdleOnly
			keep -debounceTime
			keep -state
			rename -background -buttonBackground buttonBackground ButtonBackground
		}

		eval itk_initialize $args
	}
}

configbody ::DCS::AreaMoveArrows::upCommand {
	if {$itk_option(-upCommand) != "" } {
		$itk_component(upArrow) configure \
        -command $itk_option(-upCommand)
		grid $itk_component(upArrow) -column 1 -row 0 -sticky w
	}
}

configbody ::DCS::AreaMoveArrows::downCommand {
	if {$itk_option(-downCommand) != "" } {
		$itk_component(downArrow) configure \
        -command $itk_option(-downCommand)
		grid $itk_component(downArrow) -column 2 -row 0 -sticky w
	}
}

configbody ::DCS::AreaMoveArrows::leftCommand {
	if {$itk_option(-leftCommand) != "" } {
		$itk_component(leftArrow) configure \
        -command $itk_option(-leftCommand)
		grid $itk_component(leftArrow) -column 0 -row 0 -sticky w
	}
}

configbody ::DCS::AreaMoveArrows::rightCommand {
	if {$itk_option(-rightCommand) != "" } {
		$itk_component(rightArrow) configure \
        -command $itk_option(-rightCommand)
		grid $itk_component(rightArrow) -column 3 -row 0 -sticky w
	}
}

#overide the base class definition.
body DCS::AreaMoveArrows::addInput { input_ } {
    $itk_component(upArrow) addInput $input_
    $itk_component(downArrow) addInput $input_
    $itk_component(leftArrow) addInput $input_
    $itk_component(rightArrow) addInput $input_
}

