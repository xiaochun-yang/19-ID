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

package provide BLUICEHutchOverview 1.0

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
package require DCSScriptCommand


class OptimizeButton {
    inherit DCS::Button

    public method handleStart
   
    public variable m_optimizeEnergyParamsObj 
 
   	constructor { args} {
 
        eval itk_initialize $args

        configure -command "$this handleStart"
         set m_deviceFactory [DCS::DeviceFactory::getObject]

         if { [$m_deviceFactory stringExists optimizedEnergyParameters] } {
            set m_optimizeEnergyParamsObj [DCS::OptimizedEnergyParams::getObject]
            addInput "$m_optimizeEnergyParamsObj optimizeEnable 1 {Table optimizations are disabled.}"
         }

         announceExist
    }
}

body OptimizeButton::handleStart {} {

    $m_optimizeEnergyParamsObj setLastOptimizedTime 0

    ::device::optimized_energy move by 0 eV
}

class LoadButton {
    	
	inherit DCS::Button
    
	public method handleStart
    
#	public variable m_loadParamsObj

        constructor { args} {

        	eval itk_initialize $args

        	configure -command "$this handleStart"
         	#set m_deviceFactory [DCS::DeviceFactory::getObject]

         	#if { [$m_deviceFactory stringExists optimizedEnergyParameters] } {
            	#	set m_optimizeEnergyParamsObj [DCS::OptimizedEnergyParams::getObject]
            	#	addInput "$m_optimizeEnergyParamsObj optimizeEnable 1 {Table optimizations are disabled.}"
         	#}

         	#announceExist
#		set m_loadParamsObj 0
    	}
}

body LoadButton::handleStart {} {

#	::device::gonio_phi move to 180 deg
#	::device::gonio_kappa move to 90 deg

        #this is for move sample_x/y/z to robot mount/unmount position
#       ::device::gonio_phi move to 0 deg
#       ::device::gonio_kappa move to 0 deg

        set text [.pw.pane0.childsite.bluice.n.canvas.notebook.cs.page1.cs.h.hutch.c.load cget -text]
        if {$text == "Ion/In"} {
                set text "Ion/Out"
                ::device::ion_det_ext open
                ::device::ion_det_ret close
     #          ::device::gonio_kappa move to 180 deg

        } else {
                set text "Ion/In"
                ::device::ion_det_ext close
                ::device::ion_det_ret open
        }

	.pw.pane0.childsite.bluice.n.canvas.notebook.cs.page1.cs.h.hutch.c.load configure -text $text
}

class DCS::HutchOverview {
 	inherit ::itk::Widget
	
	itk_option define -detectorType detectorType DetectorType Q315CCD
	itk_option define -mdiHelper mdiHelper MdiHelper ""
	itk_option define -attenuationDevice attenuationDevice AttenuationDevice ""

    public proc getMotorList { } {
        global gMotorBeamWidth
        global gMotorBeamHeight
        global gMotorBeamStop

        return [list \
        $gMotorBeamWidth \
        $gMotorBeamHeight \
        $gMotorBeamStop \
        ]
    }
	
	public variable withSampleVideo 0
	public variable withHutchVideo 0

	# protected variables
	protected variable canvas

	# protected methods
	protected method constructGoniometer
	protected method constructDetector
	protected method constructFrontend
	protected method constructBeamstop
	protected method constructAttenuation
	protected method constructAutomation
	#yang added
	#protected method constructHalfslits

	public method handleUpdateFromShutter
	public method handleDetectorTypeChange

	private variable _detectorObject

   	public method getDetectorHorzWidget {} {return $itk_component(detector_horz)}
	public method getDetectorVertWidget {} {return $itk_component(detector_vert)} 
	public method getDetectorZWidget {} {return $itk_component(detector_z)}
	public method getBeamstopZWidget {} {return $itk_component(beamstop)}
        #public method getBeamstopHorzWidget {} {return $itk_component(beamstop_horz)}
        #public method getBeamstopVertWidget {} {return $itk_component(beamstop_vert)}
	public method getEnergyWidget {} {return $itk_component(energy)}
	public method getBeamWidthWidget {} {return $itk_component(beamWidth)}
	public method getBeamHeightWidget {} {return $itk_component(beamHeight)}

	#yang added
	public method handleShutter1
	public method handleShutter2
	public method handleShutter3
        public method handleShutter4
	public method handleBeamCurrentChange0
	public method handleBeamCurrentChange1

   
   	private variable m_deviceFactory
	private variable m_strBeamCurrent0
	private variable m_strBeamCurrent1

	constructor { args} {
		# call base class constructor
		::DCS::Component::constructor {}
		} {
      		set m_deviceFactory [DCS::DeviceFactory::getObject]

		itk_component add canvas {
			canvas $itk_interior.c -width 1000 -height 295
		}

		# construct the panel of control buttons
		itk_component add control {
			::DCS::MotorControlPanel $itk_component(canvas).control \
				 -width 7 -orientation "horizontal" \
				 -ipadx 0 -ipady 0  -buttonBackground #c0c0ff \
				 -activeButtonBackground #c0c0ff  -font "helvetica -14 bold"
		} {
		}
			 
		place $itk_component(control) -x 30 -y 10

		# construct the goniometer widgets
		constructGoniometer 420 270

		# construct the detector widgets
		itk_component add detector_vert {
			::DCS::TitledMotorEntry $itk_component(canvas).detector_vert \
				 -unitsList default \
				 -menuChoiceDelta 20  -units mm -unitsWidth 4 \
				 -entryWidth 10 \
				 -labelText "Vertical" \
                		 -activeClientOnly 1 
		} {
		   keep -systemIdleOnly
		   keep -mdiHelper
		   rename -device detectorVertDevice detectorVertDevice DetectorVertDevice
		}
		
		itk_component add detector_z {
			# create motor view for detector_z
			::DCS::TitledMotorEntry $itk_component(canvas).detector_z \
                -checkLimits -1 \
				 -labelText "Distance" -unitsList default \
             			 -menuChoiceDelta 50 \
				 -entryType positiveFloat -units mm -unitsWidth 3 \
				 -entryWidth 8 \
                		 -activeClientOnly 1 
               			# -systemIdleOnly 0 \
               			# -honorStatus 0
		} {
			keep -systemIdleOnly
			keep -mdiHelper
			rename -device detectorZDevice detectorZDevice DetectorZDevice
		}

		itk_component add detector_horz {
			# create motor view for detector_horiz
			::DCS::TitledMotorEntry $itk_component(canvas).detector_horz \
				 -unitsList default \
				 -menuChoiceDelta 50  -units mm -unitsWidth 4 \
				 -entryWidth 10 \
				 -labelText "Horizontal" \
               			 -activeClientOnly 1 
		} {
			keep -systemIdleOnly
			keep -mdiHelper
			rename -device detectorHorzDevice detectorHorzDevice DetectorHorzDevice
		}
		
		itk_component add energy {
			# create motor view for detector_horiz
			::DCS::TitledMotorEntry $itk_component(canvas).energy \
				 -labelText "Energy" \
                 -checkLimits -1 \
				 -entryWidth 10 \
				 -autoGenerateUnitsList 0 \
           			 -unitsList {A {-decimalPlaces 5 -menuChoiceDelta 0.1} eV {-decimalPlaces 3 -menuChoiceDelta 1000} keV {-decimalPlaces 6 -menuChoiceDelta 1.0}} \
				 -unitsWidth 4 \
        		        -activeClientOnly 1 
		} {
			keep -systemIdleOnly
			keep -mdiHelper
			rename -device energyDevice energyDevice EnergyDevice
		}

		place $itk_component(canvas).energy -x 10 -y 220

      #only add optimize button if the optimized_energy motor exists on this beam line.
      if { [$m_deviceFactory motorExists optimized_energy]} {

		   itk_component add optimize {
			   # make the optimize beam button
			   OptimizeButton $itk_component(canvas).optimize \
				 -text "Optimize Beam" \
				 -width 10
		   } {
			   keep -foreground
		   }

		place $itk_component(optimize) -x 15 -y 255
      }
	
		itk_component add load {
                           # make the optimize beam button
                           LoadButton $itk_component(canvas).load \
				 -text "Ion/In" \
				 -font "courier -14 bold"\
                                 -width 8 \
				 -background #c0c0ff \
				 -activebackground #c0c0ff
                   } {
                           keep -foreground
                   }
                place $itk_component(load) -x 288 -y 10
#puts "yangx this =$this  itk_component= $itk_component(load)\n"
	        for {set i 0} {$i < 2} {incr i} {

                	itk_component add ioncurrent$i {
                           # make the optimize beam button
                           label $itk_component(canvas).ioncurrent$i \
                                 -text "00000" \
				 -relief sunken \
                                 -width 5 \
                                 -background #c0c0ff \
                                 -activebackground #c0c0ff
                 	} {
                           keep -foreground
                 	}
		}
                place $itk_component(ioncurrent0) -x 355 -y 90
		place $itk_component(ioncurrent1) -x 565 -y 125
#		place $itk_component(ioncurrent2) -x 375 -y 180

		$itk_component(control) registerMotorWidget ::$itk_component(detector_vert)
		$itk_component(control) registerMotorWidget ::$itk_component(detector_horz)
		$itk_component(control) registerMotorWidget ::$itk_component(detector_z)
		$itk_component(control) registerMotorWidget ::$itk_component(energy)


		# construct the frontend widgets
		constructFrontend 0 0

		# construct the beamstop widgets
		constructBeamstop 0 0

		#create on object for watching the detector
		set _detectorObject [DCS::Detector::getObject]

		pack $itk_component(canvas)
	        eval itk_initialize $args

		::mediator register $this ::$_detectorObject type handleDetectorTypeChange

		::mediator announceExistence $this

      		set m_deviceFactory [DCS::DeviceFactory::getObject]
		set shutterObject [$m_deviceFactory createShutter shutter]
	        set m_strBeamCurrent1 [$m_deviceFactory createString analogInStatus3]
		$m_strBeamCurrent1 register $this contents handleBeamCurrentChange1
		set m_strBeamCurrent0 [$m_deviceFactory createString analogInStatus2]
		$m_strBeamCurrent0 register $this contents handleBeamCurrentChange0
	        
		::mediator register $this $shutterObject state handleUpdateFromShutter
	
#yangx add to get rid of the canvas borderline (the borderline appears when you enter the
#motion numbers.
		$itk_component(canvas) configure -borderwidth 0 -highlightthickness 0
	
		return
	}
    
    destructor { }
}

body DCS::HutchOverview::destructor {} {
	$m_strBeamCurrent0 unregister $this contents handleBeamCurrentChange0
	mediator announceDestruction $this
	
	$m_strBeamCurrent1 unregister $this contents handleBeamCurrentChange1
	mediator announceDestruction $this
}


#draw the postshutter view of the beam
body DCS::HutchOverview::handleUpdateFromShutter { shutter_ targetReady_ - state_ -} {

	if { ! $targetReady_ } return

	switch $state_ {
		
		open {
			$itk_component(canvas) itemconfigure postShutterBeam -fill magenta
			$itk_component(canvas) raise postShutterBeam
		}
		
		closed {
			$itk_component(canvas) itemconfigure postShutterBeam -fill lightgrey
			$itk_component(canvas) lower postShutterBeam
		}
	}
}



body DCS::HutchOverview::constructGoniometer { x y } {

	# draw and label the goniometer
#	global BLC_IMAGES

#	set goniometerImage [ image create photo -file "$BLC_IMAGES/xyz.gif" -palette "8/8/8"]
	
#	itk_component add goniometerImage {
	#	$itk_component(canvas) create image [expr $x + 10]  [expr $y - 190] -anchor nw -image $goniometerImage
#	}

	itk_component add phi {
		# create motor view for gonio_phi
		::DCS::TitledMotorEntry $itk_component(canvas).phi \
			 -labelText "Phi" \
			 -autoMenuChoices 0 \
			 -shadowReference 1 \
			 -units "deg" -menuChoices {0.000 45.000 90.000 135.000 180.000 \
							 225.000 270.000 315.000 360.000}  \
          		 -activeClientOnly 1
	}  {
        	keep -systemIdleOnly
		keep -mdiHelper
		rename -device gonioPhiDevice gonioPhiDevice GonioPhiDevice
	}

	place $itk_component(phi) -x [expr $x + 150]  -y [expr $y - 215]
	
	
	# create motor view for gonio_omega
	itk_component add omega {
		::DCS::TitledMotorEntry $itk_component(canvas).omega \
			 -labelText "Omega"  -autoGenerateUnitsList 0 \
			 -unitsWidth 4 -unitsList {deg {-menuChoiceDelta 15}} -activeClientOnly 1
	} {
       keep -systemIdleOnly
		keep -mdiHelper
		rename -device gonioOmegaDevice gonioOmegaDevice GonioOmegaDevice
	}

#yange	place $itk_component(omega) -x [expr $x - 110] -y [expr $y -185]
	
	# create motor view for gonio_kappa
	itk_component add kappa {
		::DCS::TitledMotorEntry $itk_component(canvas).kappa \
			 -labelText "Kappa" \
			 -autoMenuChoices 0 \
			 -shadowReference 1 \
                         -units "deg" -menuChoices {0.000 45.000 90.000 135.000 180.000 \
                                                         225.000 270.000 315.000 360.000}  \
			 -activeClientOnly 1
	} {
        	keep -systemIdleOnly
		keep -mdiHelper
		rename -device gonioKappaDevice gonioKappaDevice GonioKappaDevice
	}

	place $itk_component(kappa) -x [expr $x + 10] -y [expr $y - 225]

	$itk_component(control) registerMotorWidget ::$itk_component(phi)
	$itk_component(control) registerMotorWidget ::$itk_component(omega)
	$itk_component(control) registerMotorWidget ::$itk_component(kappa)

}

body DCS::HutchOverview::constructFrontend { x y } {

	# create the image of the frontend
	global BLC_IMAGES
#	set frontendImage [ image create photo \
#									-file "$BLC_IMAGES/beampath-gonio-4.gif" \
#									-palette "12/12/12"]
set frontendImage [ image create photo \
                   -file "$BLC_IMAGES/beampath-stage-stop-1.gif" \
                   -palette "12/12/12"]
	$itk_component(canvas) create image 60 98 -anchor nw -image $frontendImage

	# draw the label for the frontend
	label $itk_component(canvas).frontendLabel \
		 -font "helvetica -18 bold" \
		 -text "Beam Collimator"

	#	place $itk_component(canvas).frontendLabel -x 130 -y 265

	# draw the X-ray beam entering the collimator
	$itk_component(canvas) create line 20 147 63 147 -fill magenta -width 4

	# draw the beam after the shutter
	$itk_component(canvas) create line 410 163 565 163 -fill magenta -width 2 -tag postShutterBeam
	
	#$energyWidget addInput "${deviceNamespace}::mono_theta status inactive {supporting device}"

	#$itk_component(control) registerMotorWidget ::$energyWidget

	# create motor view for detector_horiz
	itk_component add beamWidth {
		::DCS::TitledMotorEntry $itk_component(canvas).beam_width \
            -updateValueOnMatch 1 \
			 -labelText "Beam Width" \
			 -entryWidth 5 \
			  -autoGenerateUnitsList 0 \
         		  -unitsList {mm {-entryType positiveFloat -menuChoiceDelta 0.1}  um {-entryType positiveInt -menuChoiceDelta 100} }\
			  -activeClientOnly 1
	} {
        	keep -systemIdleOnly
		keep -mdiHelper
		rename -device beamWidthDevice beamWidthDevice BeamWidthDevice
	}

	# create motor view for detector_horiz

#	itk_component add beamHeight {
#		::DCS::TitledMotorEntry $itk_component(canvas).beam_height \
#			 -labelText "Beam Height" \
#			 -entryWidth 5 -autoGenerateUnitsList 0 \
#         -unitsList {mm {-entryType positiveFloat -menuChoiceDelta 0.1} } -activeClientOnly 1
#	} {
#        	keep -systemIdleOnly
#		keep -mdiHelper
#		rename -device beamHeightDevice beamHeightDevice BeamHeightDevice
#	}

       # create motor view for detector_horiz
        itk_component add beamHeight {
                ::DCS::TitledMotorEntry $itk_component(canvas).beam_height \
                         -labelText "Beam Height" \
                         -entryWidth 5 \
			 -autoGenerateUnitsList 0 \
                         -unitsList {mm {-entryType positiveFloat -menuChoiceDelta 0.1} um {-entryType positiveInt -menuChoiceDelta 100} }\
			 -activeClientOnly 1
        } {
                keep -systemIdleOnly
                keep -mdiHelper
                rename -device beamHeightDevice beamHeightDevice BeamHeightDevice
        }

	$itk_component(canvas) create text 322 253 -text "x" -font "helvetica -14 bold"


	place $itk_component(beamWidth) -x 211 -y 220
	place $itk_component(beamHeight) -x 330 -y 220
	
	$itk_component(control) registerMotorWidget ::$itk_component(beamWidth)
	$itk_component(control) registerMotorWidget ::$itk_component(beamHeight)	

#   	constructAttenuation
	#constructHalfslits
}

#body DCS::HutchOverview::constructHalfslits { } {


#                itk_component add shutteruh {
#                        label $itk_component(canvas).shutteruh \
#                        -relief ridge -width 4
#                } {
#         		keep -font
#                }
#
#                itk_component add shutteruv {
#                        label $itk_component(canvas).shutteruv \
#                        -relief ridge -width 4
#                } {
#                        keep -font
#                }
#
#                itk_component add shutterdh {
#                        label $itk_component(canvas).shutterdh \
#                        -relief ridge -width 4
#                } {
#                        keep -font
#                }
#
#                itk_component add shutterdv {
#                        label $itk_component(canvas).shutterdv \
#                        -relief ridge -width 4
#                } {
#                        keep -font
#                }
#
#                itk_component add shutterLabel {
#                        # create the shutter label
#                        label $itk_component(canvas).shutterLabel \
#                                 -text "Half Slits" \
#                                 -font "helvetica -14 bold"
#                }
#
#                itk_component add shutterLabelH {
#                        # create the shutter label
#                        label $itk_component(canvas).shutterLabelH \
#                                 -text "H" \
#                                 -font "helvetica -14 bold"
#                }
#
#                itk_component add shutterLabelV {
#                        # create the shutter label
#                        label $itk_component(canvas).shutterLabelV \
#                                 -text "V" \
#                                 -font "helvetica -14 bold"
#                }
#
#		place $itk_component(shutterLabelH) -x 10 -y 110
#		place $itk_component(shutterLabelV) -x 10 -y 130
#		place $itk_component(shutterLabel) -x 100 -y 110
#
#		place $itk_component(shutteruh) -x 37 -y 110
#		place $itk_component(shutteruv) -x 37 -y 130
#                place $itk_component(shutterdh) -x 223 -y 110
#                place $itk_component(shutterdv) -x 223 -y 130
#
#                set shutterObject [$m_deviceFactory createShutter hslit_up_h]
#	        $shutterObject register $this state handleShutter1
#                #bind a click on the shutter to toggle the state.  Replace this with a button!
#                bind $itk_component(shutteruh) <Button-1> "$shutterObject toggle"
#
#                set shutterObject [$m_deviceFactory createShutter hslit_up_v]
#                $shutterObject register $this state handleShutter2
#		bind $itk_component(shutteruv) <Button-1> "$shutterObject toggle"
#
#                set shutterObject [$m_deviceFactory createShutter hslit_dn_h]
#                $shutterObject register $this state handleShutter3
#                bind $itk_component(shutterdh) <Button-1> "$shutterObject toggle"
#
#                set shutterObject [$m_deviceFactory createShutter hslit_dn_v]
#                $shutterObject register $this state handleShutter4
#                bind $itk_component(shutterdv) <Button-1> "$shutterObject toggle"
#}
#
body DCS::HutchOverview::handleBeamCurrentChange0 { name_ targetReady_ - contents_ - } {

    if { ! $targetReady_} return
    #puts "contents=$contents_ \n"
    if { $contents_ == "" } return

    for {set i 0} {$i < 1} {incr i} {
           set value [lindex $contents_ $i]
           $itk_component(ioncurrent0) configure \
                -text [format "%.3f" $value] \
                -state normal
      }
}

body DCS::HutchOverview::handleBeamCurrentChange1 { name_ targetReady_ - contents_ - } {

    if { ! $targetReady_} return
    #puts "contents=$contents_ \n"
    if { $contents_ == "" } return

    for {set i 0} {$i < 1} {incr i} {
           set value [lindex $contents_ $i]
           $itk_component(ioncurrent1) configure \
                -text [format "%.3f" $value] \
                -state normal
      }
}


#body DCS::HutchOverview::handleBeamCurrentChange { name_ targetReady_ - contents_ - } {
#after 10000
#namespace eval ::nScripts {
#	read_ion_chambers 0.1 i1
#	set i1_reading [get_ion_chamber_counts i1]}

#    if { ! $targetReady_} return
#    puts "contents=$contents_ \n"
#    if { $contents_ == "" } return
    # read_ion_chambers ::device::i1  
#     nScripts::read_ion_chambers 0.1 i2 
#     wait_for_devices ::device::i1 device::i2
#     set i1_reading [nScript::get_ion_chamber_counts i1]		
#     set i2_reading [nScript::get_ion_chamber_counts i1]		
   
#    $itk_component(ioncurrent0) configure -text [format "%.3f" $i1_reading] -state normal 
#    $itk_component(ioncurrent1) configure -text [format "%.3f" $i2_reading] -state normal 

#    for {set i 0} {$i < 2} {incr i} {
#           set value [lindex $contents_ $i]
#           $itk_component(ioncurrent$i) configure \
#                -text [format "%.3f" $value] \
#                -state normal
#      }

    #if {[string is double -strict $contents_]} {
    #    set display [format "%.3f" $contents_]
    #} else {
    #    set display $contents_
    #}
    #$itk_component(ioncurrent) configure -text $display
#    log_error "yangxx display=$display"
#}

body DCS::HutchOverview::handleShutter1 { - targetReady_ alias_ status_ -} {
    if {! $targetReady_} return

    set red #c04080
    set midhighlight #e0e0f0
    if {$status_ == "open"} {
        set background $red
	set status_ "in"
    } else {
        set background $midhighlight
	set status_ "out"
    }
    $itk_component(shutteruh) config \
    -text $status_ \
    -background $background
}

body DCS::HutchOverview::handleShutter2 { - targetReady_ alias_ status_ -} {
    if {! $targetReady_} return

    set red #c04080
    set midhighlight #e0e0f0
    if {$status_ == "open"} {
        set background $red
	set status_ "in"
    } else {
        set background $midhighlight
	set status_ "out"
    }
    $itk_component(shutteruv) config \
    -text $status_ \
    -background $background
}

body DCS::HutchOverview::handleShutter3 { - targetReady_ alias_ status_ -} {
    if {! $targetReady_} return

    set red #c04080
    set midhighlight #e0e0f0
    if {$status_ == "open"} {
        set background $red
        set status_ "in"
    } else {
        set background $midhighlight
        set status_ "out"
    }
    $itk_component(shutterdh) config \
    -text $status_ \
    -background $background
}

body DCS::HutchOverview::handleShutter4 { - targetReady_ alias_ status_ -} {
    if {! $targetReady_} return

    set red #c04080
    set midhighlight #e0e0f0
    if {$status_ == "open"} {
        set background $red
	set status_ "in"
    } else {
        set background $midhighlight
	set status_ "out"
    }
    $itk_component(shutterdv) config \
    -text $status_ \
    -background $background
}

body DCS::HutchOverview::constructAttenuation { } {

   if { ![$m_deviceFactory motorExists attenuation]} return

    set deci [::config getInt decimal.attenuation 1]

	# create motor view for beam attenuation
	itk_component add attenuation {
		::DCS::TitledMotorEntry $itk_component(canvas).attenuation \
			 -labelText "Attenuation" \
			 -entryType positiveFloat \
			 -menuChoiceDelta 10 -units "%"  -autoGenerateUnitsList 0 \
			 -decimalPlaces $deci \
         -activeClientOnly 0
	} {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device attenuationDevice attenuationDevice AttenuationDevice
	}


	place $itk_component(attenuation) -x 80 -y 90
	$itk_component(control) registerMotorWidget ::$itk_component(attenuation)
}

body DCS::HutchOverview::constructBeamstop { x y } {

	# create the image of the frontend
	global BLC_IMAGES
#	set beamstopImage [ image create photo -file "$BLC_IMAGES/beamstop.gif" -palette "8/8/8"]
#	$itk_component(canvas) create image 570 159 -anchor nw -image $beamstopImage

	# draw the label for the frontend
#	label $itk_component(canvas).beamstopLabel \
		 -font "helvetica -18 bold" \
		 -text "Beamstop"
	#	place $itk_component(canvas).beamstopLabel -x 530 -y 265
	
	# create motor view for beamstop_z
	itk_component add beamstop {
		::DCS::TitledMotorEntry $itk_component(canvas).beamstop \
			 -labelText "Beamstop" \
			 -menuChoiceDelta 5 \
			 -entryType positiveFloat \
			 -decimalPlaces 3 -units mm \
             		 -activeClientOnly 0 \
             		 -systemIdleOnly 0 \
             		 -honorStatus 0
	} {
		keep -mdiHelper
		rename -device beamstopDevice beamstopDevice BeamstopDevice
	}


        # create motor view for beamstop_horz
#        itk_component add beamstop_horz {
#                ::DCS::TitledMotorEntry $itk_component(canvas).beamstop_horz \
#                         -labelText "Beamstop_horz" \
#                         -menuChoiceDelta 0.1 \
#			 -autoGenerateUnitsList 0 \
#                         -entryType positiveFloat \
#                         -decimalPlaces 3 -units mm \
#             		 -activeClientOnly 1
#        } {
#		keep -systemIdleOnly
#                keep -mdiHelper
#                rename -device beamstopHorzDevice beamstopHorzDevice BeamstopHorzDevice
#        }

        # create motor view for beamstop_vert
#        itk_component add beamstop_vert {
#                ::DCS::TitledMotorEntry $itk_component(canvas).beamstop_vert \
#                         -labelText "Beamstop_vert" \
#                         -menuChoiceDelta 0.1 \
#			 -autoGenerateUnitsList 0 \
#                         -entryType positiveFloat \
#                         -decimalPlaces 3 -units mm \
#        		 -activeClientOnly 1 
#        } {
#		keep -systemIdleOnly
#                keep -mdiHelper
#                rename -device beamstopVertDevice beamstopVertDevice BeamstopVertDevice
#        }
#
      place $itk_component(beamstop) -x 530 -y 225
#       place $itk_component(beamstop_horz) -x 610 -y 180
#        place $itk_component(beamstop_vert) -x 530 -y 225

	# For vertical beamstop
#        $itk_component(canvas) create line 515 240 515 270 -arrow both -width 3 -fill black
#        $itk_component(canvas) create text 525 240 -text "+" -font "courier -10 bold" 
#        $itk_component(canvas) create text 525 270 -text "-" -font "courier -10 bold" 

	# For horizontal beamstop
#	$itk_component(canvas) create line 570 200 600 170 -arrow both -width 3 -fill black
#        $itk_component(canvas) create text 585 200 -text "+" -font "courier -10 bold" 
#        $itk_component(canvas) create text 605 175 -text "-" -font "courier -10 bold" 

        $itk_component(control) registerMotorWidget ::$itk_component(beamstop)
#        $itk_component(control) registerMotorWidget ::$itk_component(beamstop_horz)
#        $itk_component(control) registerMotorWidget ::$itk_component(beamstop_vert)

	# draw arrow for beam stop motion
#	$itk_component(canvas) create line 580 190 620 190 -arrow both -width 3 -fill black	
#	$itk_component(canvas) create text 613 180 -text "+" -font "courier -10 bold"
#	$itk_component(canvas) create text 584 180 -text "-" -font "courier -10 bold"
}

body DCS::HutchOverview::handleDetectorTypeChange { detector_ targetReady_ alias_ type_ -  } {
	
	if { ! $targetReady_} return
	configure -detectorType $type_
}


configbody DCS::HutchOverview::detectorType {

	# draw and label the detector
	global BLC_IMAGES

	set x 0
	set y 0

	#delete any old graphic items from a previous detector configuration
	$itk_component(canvas) delete detectorItems

	#draw the detector items
	switch $itk_option(-detectorType) {

		Q4CCD {

			place $itk_component(detector_vert) -x 835 -y 0
			place $itk_component(detector_z) -x 835 -y 235
		#yang	place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/q4_big2.gif" \
											-palette "8/8/8"]
			$itk_component(canvas) create image 820 45 \
				 -anchor nw \
				 -image $detectorImage -tag detectorItems
			
			$itk_component(canvas) create line 900 55 900 80 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 910 80 -text "-" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 925 230 955 230 -arrow both -width 3 -fill black -tag detectorItems
		#	$itk_component(canvas) create line 821 225 836 225 -arrow last  -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create text 920 230 -text "-" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 965 230 -text "+" -font "courier -10 bold" -fill black -tag detectorItems
			
#yang			$itk_component(canvas) create line 913 185 942 212 -arrow both -width 3 -fill black	 -tag detectorItems
#yang			$itk_component(canvas) create text 927 188 -text "+" -font "courier -10 bold" -tag detectorItems
#yang			$itk_component(canvas) create text 948 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}
		
		Q315CCD {
			place $itk_component(detector_vert) -x 835 -y 0 
			place $itk_component(detector_z) -x 660 -y 125
	#		place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/q4_small.gif" \
											-palette "8/8/8" ]

			$itk_component(canvas) create image 820 90 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems
			
			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold"	-tag detectorItems
			
			$itk_component(canvas) create line 796 157 821 157 -arrow first -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create line 821 157 836 157 -arrow last  -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create text 800 148 -text "-" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 835 148 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			
#yang			$itk_component(canvas) create line 913 185 942 212 -arrow both -width 3 -fill black	-tag detectorItems
#yang			$itk_component(canvas) create text 927 188 -text "+" -font "courier -10 bold"	-tag detectorItems
#yang			$itk_component(canvas) create text 948 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}

		MAR345 {
			place $itk_component(detector_vert) -x 835 -y 0
			place $itk_component(detector_z) -x 657 -y 125
			place $itk_component(detector_horz) -x 855 -y 235

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar_small.gif" \
											-palette "8/8/8"]

			$itk_component(canvas) create image 815 53 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems

			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black 	-tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold" 	-tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold" 	-tag detectorItems
			
			$itk_component(canvas) create line 791 157 821 157 -arrow both -width 3 -fill black 	-tag detectorItems
			$itk_component(canvas) create text 796 148 -text "-" -font "courier -10 bold" 	-tag detectorItems
			$itk_component(canvas) create text 817 148 -text "+" -font "courier -10 bold" 	-tag detectorItems
		
			$itk_component(canvas) create line 903 210 915 222 -arrow first -width 3 -fill white	-tag detectorItems
			$itk_component(canvas) create line 915 222 927 234 -arrow last -width 3 -fill black	-tag detectorItems
			$itk_component(canvas) create text 898 215 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			$itk_component(canvas) create text 911 232 -text "-" -font "courier -10 bold"		-tag detectorItems
		}

		MAR165 {

			place $itk_component(detector_vert) -x 835 -y 30
			place $itk_component(detector_z) -x 657 -y 125
			place $itk_component(detector_horz) -x 855 -y 203

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar165.gif" \
											-palette "8/8/8"]
			$itk_component(canvas) create image 817 107 \
				 -anchor nw \
				 -image $detectorImage -tag detectorItems

			$itk_component(canvas) create line 900 85 900 125 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 91 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 910 1288 -text "-" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 791 157 821 157 -arrow both -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 796 148 -text "-" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 817 148 -text "+" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 903 178 915 190 -arrow first -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create line 915 190 927 202 -arrow last -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 898 183 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
			$itk_component(canvas) create text 911 200 -text "-" -font "courier -10 bold"	-tag detectorItems
		}
		MAR325 {
			place $itk_component(detector_vert) -x 835 -y 0 
			place $itk_component(detector_z) -x 660 -y 125
			place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar325.gif" \
											-palette "8/8/8" ]

			$itk_component(canvas) create image 820 90 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems
			
			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold"	-tag detectorItems
			
			$itk_component(canvas) create line 796 157 821 157 -arrow first -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create line 821 157 836 157 -arrow last  -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create text 800 148 -text "-" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 835 148 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			
			$itk_component(canvas) create line 913 185 942 212 -arrow both -width 3 -fill black	-tag detectorItems
			$itk_component(canvas) create text 927 188 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 948 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}


		PILATUS6 {
			place $itk_component(detector_vert) -x 835 -y 0 
			place $itk_component(detector_z) -x 660 -y 125
			place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/pilatus6.gif" \
											-palette "8/8/8" ]

			$itk_component(canvas) create image 830 90 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems
			
			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold"	-tag detectorItems
			
			$itk_component(canvas) create line 796 157 821 157 -arrow first -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create line 821 157 836 157 -arrow last  -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create text 800 148 -text "-" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 835 148 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			
			$itk_component(canvas) create line 913 185 942 212 -arrow both -width 3 -fill black	-tag detectorItems
			$itk_component(canvas) create text 927 188 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 948 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}




		default {
			place $itk_component(detector_vert) -x 835 -y 30
			place $itk_component(detector_z) -x 657 -y 125
	#yang		place $itk_component(detector_horz) -x 855 -y 203

			$itk_component(canvas) create line 900 85 900 125 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 91 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 910 1288 -text "-" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 791 157 821 157 -arrow both -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 796 148 -text "-" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 817 148 -text "+" -font "courier -10 bold" -tag detectorItems
			
#yang			$itk_component(canvas) create line 903 178 927 202 -arrow both -width 3 -fill black -tag detectorItems
#yang			$itk_component(canvas) create text 898 183 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
#yang			$itk_component(canvas) create text 911 200 -text "-" -font "courier -10 bold"	-tag detectorItems

		}
	}
}







class DCS::DetectorPositionView {
 	inherit ::DCS::CanvasShapes

	itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getMotorList { } {
        return [list \
        detector_z_corr \
        detector_z \
        gonio_z \
        detector_vert \
        detector_horz \
        ]
    }

	constructor { args} {

		place $itk_component(control) -x 30 -y 80

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      if { [$m_deviceFactory motorExists detector_z_corr]} {
        set detectorZ detector_z_corr

        #only add encoder button if the detector_z_corr motor exists on this beam line.
		   itk_component add setEncoder {
			   # make the optimize beam button
			    DetectorDistanceEncoderSetButton $itk_component(canvas).des
		   } {
		   }

		   place $itk_component(setEncoder) -x 470 -y 300 
      } else {
        set detectorZ detector_z
      }


      if { [$m_deviceFactory motorExists gonio_z]} {
         motorView gonio_z 135 203 e
		   motorArrow gonio_z 180 230 {} 134 230 176 216 140 216
      }

		# construct the slit 0 widgets
		motorView $detectorZ 590 235 w
      motorView detector_vert 417 209 se
      motorView detector_horz 400 314 n

		# draw the table
		rect_solid 80 220 430 20 60 85 65

      if { [$m_deviceFactory motorExists gonio_z]} {

		# draw the goniometer trolley
		rect_solid 130 190 50 20 80 100 95

        }

		# draw the gantry trolley
		rect_solid 410 190 60 20 80 95 90

		# draw the back vertical beam
		rect_solid 482 61 35 150 8 10 9
	
		# draw the detector
		rect_solid 423 90 120 60 20 30 27
		
		# draw the front vertical beam
		rect_solid 443 82 40 160 8 10 9
		
		# draw the gantry top bar
		rect_solid 443 50 40 20 30 50 43
		
		motorArrow $detectorZ 590 230 {} 525 230 584 219 535 219
		motorArrow detector_horz 440 280 {} 400 313 447 284 419 310
		motorArrow detector_vert 432 170 {} 432 240 420 176 420 234

		#place $itk_component(detectorPitchDevice) 620 120 w 125 45 9
		#motorArrow $itk_component(canvas) $itk_component(detectorPitch)  580 95 {610 105 610 145} 580 155 594 88 593 161
	
		eval itk_initialize $args
		$itk_component(canvas) configure -width 750 -height 420
	}
}



class DetectorDistanceEncoderSetButton {
    inherit ::itk::Widget

    public method handleConfigure
    public method handleEditValue
    
   	constructor { args } {} {
 
        set yellow #d0d000

        itk_component add frame {
           iwidgets::labeledframe $itk_interior.f -labeltext "Configure detector_z encoder:" 
        } {}

        set ring [$itk_component(frame) childsite]

        itk_component add value {
           DCS::Entry $ring.e -promptText "Enter detector_z position:" \
				 -entryWidth 10 -unitsWidth 3 -units "mm" \
				 -entryType positiveFloat -decimalPlaces 4 \
				 -activeClientOnly 0 -systemIdleOnly 0
        } {}

        itk_component add apply {
           DCS::Button $ring.b -text "Set detector_z encoder" \
				 -width 25 -activebackground $yellow -background $yellow -activeClientOnly 1
        } {}

        $itk_component(apply) configure -command "$this handleConfigure"
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        $itk_component(apply) addInput "::device::detector_z_corr status inactive {supporting device}"

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

body DetectorDistanceEncoderSetButton::handleConfigure {} {

    set position [lindex [$itk_component(value) get] 0]
    if {$position == "" } return

    #set position [::device::detector_z_corr getScaledPosition]
    set upperLimit [lindex [::device::detector_z_corr getUpperLimit] 0]
    set lowerLimit [lindex [::device::detector_z_corr getLowerLimit] 0]
    set lowerLimitOn [::device::detector_z_corr getLowerLimitOn]
    set upperLimitOn [::device::detector_z_corr getUpperLimitOn]
    set locked [::device::detector_z_corr getLockOn]

    set position [lindex [$itk_component(value) get] 0]

    ::device::detector_z_corr changeMotorConfiguration $position $upperLimit $lowerLimit $lowerLimitOn $upperLimitOn $locked
}


body DetectorDistanceEncoderSetButton::handleEditValue {objName_ targetReady_ alias_ value_ -} {

   if {!$targetReady_} return

   if { $value_ == "{} mm" || [lindex $value_ 0] == 0.0 } {
      $itk_component(apply) configure -state disabled
   } else {
      $itk_component(apply) configure -state normal
   }
}

