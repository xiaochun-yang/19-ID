##########################################################################
#only for 19ID at NSLS2

package provide BLUICEGonioMotions 1.0

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

class DCS::GonioMotionsWidget {
 	inherit ::DCS::CanvasShapes

	itk_option define -mdiHelper mdiHelper MdiHelper ""

 public proc getMotorList { } {
        return [list \
        optic_vert \
        optic_horz \
        pitch \
        yaw
        ]
    }

        constructor { args} {

                place $itk_component(control) -x 150 -y 275

                # construct the table widgets
                motorView optic_vert 125  90 sw
                motorView optic_horz 300 90 sw
                motorView pitch 125 170 sw
                motorView yaw 300 170 sw
    #            motorView white_beam_slit_lower 125 250  sw
    #            motorView white_beam_slit_upper 300 250 sw

                # draw the table
                #rect_solid 180 120 250 20 40 60 40



                eval itk_initialize $args
                $itk_component(canvas) configure -width 560 -height 310

                configure -serialMove 1
        }
}
