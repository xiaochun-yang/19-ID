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

package provide BLUICEGonioView 1.0

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
package require BLUICECanvasShapes


class DCS::HuberGoniometerView {
     inherit ::DCS::CanvasShapes

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getMotorList { } {
        return [list \
        gonio_phi \
        gonio_omega \
        gonio_kappa \
        sample_x \
        sample_y \
        sample_z \
        sample_z_corr \
        ]
    }

    constructor { args} {

        # draw and label the goniometer
        global BLC_IMAGES

        set goniometerImage [ image create photo -file "$BLC_IMAGES/gonio.gif" -palette "8/8/8"]

        place $itk_component(control) -x 220 -y 310

        set deviceFactory [DCS::DeviceFactory::getObject]
        if {[$deviceFactory motorExists sample_z_corr]} {
            set sampleZ sample_z_corr
            #only add encoder button if the sample_z_corr motor exists on this beam line.
            itk_component add setEncoder {
                SampleZEncoderSetButton $itk_component(canvas).des
            } {
            }

            place $itk_component(setEncoder) -x 500 -y 280
        } else {
            set sampleZ sample_z
        }

        # construct the goniometer widgets
        motorView gonio_phi 307 92 s 
        motorView gonio_omega 15 213 w 
        motorView gonio_kappa 400 179 w
        motorView sample_x 615 30 n um 
        motorView sample_y 615 130 n um
        motorView $sampleZ 615 230 n um



        eval itk_initialize $args

        # display photo of the goniometer
        $itk_component(canvas) create image 190 120 -anchor nw -image $goniometerImage


        #motorArrow $itk_component(canvas) $itk_component(sampleX) 180 230 {} 134 230 176 216 140 216
        motorArrow gonio_phi 292 109 { 303 100 322 105} 331 117  290 98 335 105
        motorArrow gonio_omega 185 260  {155 245 155 195 } 185 180 170 264 170 177
        motorArrow gonio_kappa 376 167 { 387 173  392 189 } 384 205 388 162 388 210

      	itk_component add joypad {
         DCS::JoyPadView $itk_component(canvas).joypad
      } {}
   
      place $itk_component(joypad) -x 700 -y 70

        eval itk_initialize $args
        $itk_component(canvas) configure -width 900 -height 350
    }

}



class DCS::MicrodiffractometerView {
     inherit ::DCS::CanvasShapes

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getMotorList { } {
        return [list \
        gonio_phi \
        gonio_vert \
        sample_x \
        sample_y \
        sample_z \
        sample_z_corr \
        ]
    }

    constructor { args} {

        # draw and label the goniometer
        global BLC_IMAGES

        set goniometerImage [ image create photo -file "$BLC_IMAGES/microDiffStages.gif" -palette "256/256/256"]

        # display photo of the goniometer
        $itk_component(canvas) create image 0 0 -anchor nw -image $goniometerImage


        set deviceFactory [DCS::DeviceFactory::getObject]
        if {[$deviceFactory motorExists sample_z_corr]} {
            set sampleZ sample_z_corr
            #only add encoder button if the sample_z_corr motor exists on this beam line.
            itk_component add setEncoder {
                SampleZEncoderSetButton $itk_component(canvas).des
            } {
            }

            place $itk_component(setEncoder) -x 475 -y 255
        } else {
            set sampleZ sample_z
        }

        # construct the goniometer widgets
        motorView gonio_phi 41 18 nw 
        motorView gonio_vert 3 145 nw 
        motorView sample_x 316 102 sw um 
        motorView sample_y 316 203 sw um
        motorView $sampleZ 316 304 sw um

        moveHotSpot gonio_phi 191 43 positive false
        moveHotSpot gonio_phi 265 43 negative false

        moveHotSpot gonio_vert 145 156 positive false
        moveHotSpot gonio_vert 145 208 negative false

        moveHotSpot $sampleZ 294 277 positive false
        moveHotSpot $sampleZ 268 298 negative false

        place $itk_component(control) -x 60 -y 310

        eval itk_initialize $args


      itk_component add joypad {
         DCS::JoyPadView $itk_component(canvas).joypad
      } {}
   
      place $itk_component(joypad) -x 550 -y 20

        eval itk_initialize $args
        $itk_component(canvas) configure -width 770 -height 350
    }

}


class DCS::JoyPadView {
     inherit ::itk::Widget

   private variable m_lastUpSpeed 0
   private variable m_lastDownSpeed 0
    private variable m_lastLeftSpeed 0
    private variable m_lastRightSpeed 0

   public method joyUp
   public method joyDown
   public method joyLeft
   public method joyRight

   private method moveVector
   private method changeVectorSpeed
   private method stopVector

   public method upRelease
   public method downRelease
   public method leftRelease
   public method rightRelease

   private method moveVertical
   private method moveLeft
   private method moveRight

   protected variable m_logger

    constructor { args} {
      set m_deviceFactory [::DCS::DeviceFactory::getObject]
      set m_logger [DCS::Logger::getObject]

        itk_component add canvas {
            canvas $itk_interior.c -width 180 -height 180
        } {
      }

       # create the sample buttons

       #add a speed scale
      itk_component add up {
          scale $itk_component(canvas).xy_plus -orient vertical \
              -length 78 -from 5000 -to 0 \
               -showvalue 0 -command "$this joyUp"
      } {}


      itk_component add down {
          scale $itk_component(canvas).xy_minus -orient vertical \
              -length 78 -from 0 -to 5000 \
               -showvalue 0 -command "$this joyDown"
      } {}


      itk_component add left {
         scale $itk_component(canvas).z_minus -orient horizontal \
               -length 78 -from 5000 -to 0 \
               -showvalue 0 -command "$this joyLeft"
      } {}

      itk_component add right {
          scale $itk_component(canvas).z_plus -orient horizontal \
              -length 78 -from 0 -to 5000 \
               -showvalue 0 -command "$this joyRight"
      } {}

       bind $itk_component(up) <ButtonRelease> "$this upRelease"
      bind $itk_component(down) <ButtonRelease> "$this downRelease"
      bind $itk_component(left) <ButtonRelease>  "$this leftRelease"
       bind $itk_component(right) <ButtonRelease> "$this rightRelease"

      place $itk_component(down) -x 80 -y 100
      place $itk_component(left) -x 0 -y 80
      place $itk_component(up) -x 80 -y 0
      place $itk_component(right) -x 100 -y 80

       # make the Phi -90 button
       itk_component add minus90 {
           DCS::MoveMotorRelativeButton $itk_interior.minus90 \
               -delta "-90" \
               -text "-90" \
               -width 2  -background #c0c0ff -activebackground #c0c0ff \
               -device ::device::gonio_phi
       } {}

       # make the Phi +90 button
       itk_component add plus90 {
           DCS::MoveMotorRelativeButton $itk_interior.plus90 \
               -delta "90" \
               -text "+90" \
               -width 2  -background #c0c0ff -activebackground #c0c0ff \
            -device ::device::gonio_phi
       } {}

      itk_component add phiText {
          label $itk_interior.label -text "Phi"
      } {}

      grid $itk_component(canvas) -row 0 -column 0 -columnspan 3 
      grid $itk_component(minus90) -row 1 -column 0
      grid $itk_component(phiText) -row 1 -column 1
      grid $itk_component(plus90) -row 1 -column 2

   }

}


body DCS::JoyPadView::joyUp { args } {
   set speed [$itk_component(up) get]

    if { $m_lastUpSpeed == 0 } {
            if { $speed != 0 } {
            #start vector move
            moveVertical 1.0 $speed
            $m_logger logNote "start vector move"
            }
        }

    if { $m_lastUpSpeed != 0 } {
        if { $speed == 0 } {    
            #stop vector move
            stopVector sample_x sample_y
            $m_logger logNote "stop vector move"
            update
            after 500 {}
            }
        }

    if { $m_lastUpSpeed != 0 } {
        if { $speed != 0 } {    
            #change vector speed
            changeVectorSpeed sample_x sample_y $speed
            }
        }

    set m_lastUpSpeed $speed
}


body DCS::JoyPadView::joyDown {args} {
   set speed [$itk_component(down) get]

    if { $m_lastDownSpeed == 0 } {
            if { $speed != 0 } {
                #start vector move
                moveVertical -1.0 [expr abs ($speed)]
                log_note "start vector move"
            }
    }
    
    if { $m_lastDownSpeed != 0 } {
        if { $speed == 0 } {    
            #stop vector move
            stopVector sample_x sample_y
            $m_logger logNote "stop vector move"
        }
    }
    
    if { $m_lastDownSpeed != 0 } {
        if { $speed != 0 } {    
            #change vector speed
            changeVectorSpeed sample_x sample_y $speed
        }
    }
    
    set m_lastDownSpeed $speed
}


body DCS::JoyPadView::joyLeft {args} {
   set speed [$itk_component(left) get]

    if { $m_lastLeftSpeed == 0 } {
            if { $speed != 0 } {
            #start vector move
            moveLeft $speed
            $m_logger logNote "start vector move"
            }
        }

    if { $m_lastLeftSpeed != 0 } {
        if { $speed == 0 } {    
            #stop vector move
            stopVector sample_z NULL
            $m_logger logNote "stop vector move"
            update
            after 500 {}
            }
        }

    if { $m_lastLeftSpeed != 0 } {
        if { $speed != 0 } {    
            #change vector speed
            changeVectorSpeed sample_z NULL $speed
            }
        }

    set m_lastLeftSpeed $speed
}

body DCS::JoyPadView::joyRight {args} {
   set speed [$itk_component(right) get]

    if { $m_lastRightSpeed == 0 } {
            if { $speed != 0 } {
            #start vector move
            moveRight $speed
            $m_logger logNote "start vector move"
            }
        }

    if { $m_lastRightSpeed != 0 } {
        if { $speed == 0 } {    
            #stop vector move
            stopVector sample_z NULL
            $m_logger logNote "stop vector move"
            update
            after 500 {}
            }
        }

    if { $m_lastRightSpeed != 0 } {
        if { $speed != 0 } {    
            #change vector speed
            changeVectorSpeed sample_z NULL $speed
            }
        }

    set m_lastRightSpeed $speed
}


body DCS::JoyPadView::moveVertical { direction speed} {
   if { [::device::sample_x cget -status] != "inactive" } return
   if { [::device::sample_y cget -status] != "inactive" } return

   set phiPos [lindex [::device::gonio_phi getScaledPosition] 0]
   set omegaPos [lindex [::device::gonio_omega getScaledPosition] 0]
   set sampleXPos [lindex [::device::sample_x getScaledPosition] 0]
   set sampleYPos [lindex [::device::sample_y getScaledPosition] 0]

    set phiDeg [expr $phiPos + $omegaPos]

    if { $direction == 1.0 } {
        set phi [expr $phiDeg / 180.0 * 3.14159]
    } else {
      set phi [expr ($phiDeg + 180.0 )/ 180.0 * 3.14159]
  }
                    
    set comp_x [expr -sin($phi) * 100 + $sampleXPos]
    set comp_y [expr cos($phi) * 100 + $sampleYPos]
    
    moveVector sample_x sample_y $comp_x $comp_y $speed
}


body DCS::JoyPadView::moveLeft { speed } {
   if { [::device::sample_z cget -status] != "inactive" } return

   set zLowerLimit [lindex [::device::sample_z getLowerLimit] 0]

    moveVector sample_z NULL $zLowerLimit 0 $speed
}

body DCS::JoyPadView::moveRight {speed} {
   if { [::device::sample_z cget -status] != "inactive" } return

   set zUpperLimit [lindex [::device::sample_z getUpperLimit] 0]

    moveVector sample_z NULL $zUpperLimit 0 $speed
}


body DCS::JoyPadView::upRelease {args} {
   $itk_component(up) set 0
   joyUp
} 

body DCS::JoyPadView::downRelease {args} {
    $itk_component(down) set 0
    joyDown
}

body DCS::JoyPadView::leftRelease {args} {
   $itk_component(left) set 0
   joyLeft
}

body DCS::JoyPadView::rightRelease {args} {
    $itk_component(right) set 0
    joyRight
}


body DCS::JoyPadView::moveVector {motor1 motor2 newPosition1 newPosition2 speed} {
   ::dcss sendMessage "gtos_start_vector_move $motor1 $motor2 $newPosition1 $newPosition2 $speed"
}

body DCS::JoyPadView::stopVector {motor1 motor2 } {
   ::dcss sendMessage "gtos_stop_vector_move $motor1 $motor2"
}

body DCS::JoyPadView::changeVectorSpeed {motor1 motor2 speed} {
    ::dcss sendMessage "gtos_change_vector_speed $motor1 $motor2 $speed"
}


class SampleZEncoderSetButton {
    inherit ::itk::Widget

    public method handleConfigure
    public method handleEditValue
    
       constructor { args } {} {
 
        set yellow #d0d000

        itk_component add frame {
           iwidgets::labeledframe $itk_interior.f -labeltext "Configure sample_z encoder:" 
        } {}

        set ring [$itk_component(frame) childsite]

        itk_component add value {
           DCS::Entry $ring.e -promptText "Enter sample_z position:" \
                 -entryWidth 10 -unitsWidth 3 -units "mm" \
                 -entryType float -decimalPlaces 4 \
                 -activeClientOnly 0 -systemIdleOnly 0
        } {}

        itk_component add apply {
           DCS::Button $ring.b -text "Set sample_z encoder" \
                 -width 25 -activebackground $yellow -background $yellow -activeClientOnly 1
        } {}

        $itk_component(apply) configure -command "$this handleConfigure"
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        $itk_component(apply) addInput "::device::sample_z_corr status inactive {supporting device}"

       pack $itk_component(frame)
       pack $itk_component(value)
       pack $itk_component(apply)

        eval itk_initialize $args
      ::mediator announceExistence $this
      ::mediator register $this ::$itk_component(value) -value handleEditValue
    }

   destructor {
      ::mediator announceDestruction $this
   }

}

body SampleZEncoderSetButton::handleConfigure {} {

    set position [lindex [$itk_component(value) get] 0]
    if {$position == "" } return

    set upperLimit [lindex [::device::sample_z_corr getUpperLimit] 0]
    set lowerLimit [lindex [::device::sample_z_corr getLowerLimit] 0]
    set lowerLimitOn [::device::sample_z_corr getLowerLimitOn]
    set upperLimitOn [::device::sample_z_corr getUpperLimitOn]
    set locked [::device::sample_z_corr getLockOn]

    set position [lindex [$itk_component(value) get] 0]

    ::device::sample_z_corr changeMotorConfiguration $position $upperLimit $lowerLimit $lowerLimitOn $upperLimitOn $locked
}


body SampleZEncoderSetButton::handleEditValue {objName_ targetReady_ alias_ value_ -} {

   if {!$targetReady_} return

   if { $value_ == "{} mm" } {
      $itk_component(apply) configure -state disabled
   } else {
      $itk_component(apply) configure -state normal
   }
}

