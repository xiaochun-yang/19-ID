##########################################################################
#only for 19ID at NSLS2

package provide BLUICEWBControl 1.0

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

class DCS::WBControlWidget {
 	inherit ::DCS::CanvasShapes

	itk_option define -mdiHelper mdiHelper MdiHelper ""

 public proc getMotorList { } {
        return [list \
        white_beam_filter1 \
        white_beam_filter2 \
#        white_beam_filter_1 \
#        white_beam_filter_2 \
        white_beam_mask_x \
        white_beam_mask_z \
        white_beam_slit_upper \
        white_beam_slit_lower
        ]
    }

        constructor { args} {

                place $itk_component(control) -x 150 -y 275

                # construct the table widgets
                motorView white_beam_filter1 125  90 sw
                motorView white_beam_filter2 300 90 sw
             #  motorView white_beam_filter_1 125  90 sw
             #  motorView white_beam_filter_2 300 90 sw
                motorView white_beam_mask_x 125 170 sw
                motorView white_beam_mask_z 300 170 sw
                motorView white_beam_slit_lower 125 250  sw
                motorView white_beam_slit_upper 300 250 sw

                # draw the table
                #rect_solid 180 120 250 20 40 60 40
		itk_component add unit1 {
                  # make the optimize beam button
                  label $itk_component(canvas).unit1 \
                      -text "Num" \
                      -relief flat \
                      -width 4 \
              	} {
                           keep -foreground
              	}
		itk_component add unit2 {
                  # make the optimize beam button
                  label $itk_component(canvas).unit2 \
                      -text "Num" \
                      -relief flat \
                      -width 4 \
              	} {
                           keep -foreground
              	}
		place $itk_component(unit1) -x 220 -y 85 -anchor sw
		place $itk_component(unit2) -x 395 -y 85 -anchor sw
		
              #        -background #c0c0ff \
              #        -activebackground #c0c0ff

                eval itk_initialize $args
                $itk_component(canvas) configure -width 560 -height 310

                configure -serialMove 1
        }
}
