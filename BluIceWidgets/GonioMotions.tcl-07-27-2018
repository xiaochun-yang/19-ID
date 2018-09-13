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
        yaw \
	beamstop_vert \
	beamstop_horz \
	beamstop_angle \
	beamstop_vert_offset \
	sample_vert \
	sample_optic_vert
        ]
    }

        constructor { args} {

                place $itk_component(control) -x 150 -y 410

                # construct the table widgets
                motorView optic_vert 125  70 sw
                motorView optic_horz 300 70 sw
                motorView pitch 125 130 sw
                motorView yaw 300 130 sw
		motorView sample_vert 125 190 sw
		motorView sample_optic_vert 300 190 sw
		motorView beamstop_vert 125 250 sw 
		motorView beamstop_vert_offset 300 250 sw
		motorView beamstop_horz 125 310 sw 
		motorView beamstop_angle 300 310 sw
		motorView beamstop_location 300 370 sw

		 itk_component add unit1 {
                 
                 	label $itk_component(canvas).unit1 \
                      		-text "Num" \
                      		-relief flat \
                      		-width 3 \
                  } {
                           keep -foreground
                  }

		  itk_component add pos {
                  	label $itk_component(canvas).pos \
                      		-text "1:Beam Position\n2:Load sample\n3:Yag on Beam" \
                      		-relief flat \
                      		-width 15 
                  } {
                           keep -foreground
                  }

                # draw the table
                #rect_solid 180 120 250 20 40 60 40

		place $itk_component(unit1) -x 395 -y 365 -anchor sw
		place $itk_component(pos) -x 440 -y 375 -anchor sw

                eval itk_initialize $args
                $itk_component(canvas) configure -width 580 -height 460

                configure -serialMove 1
        }
}
