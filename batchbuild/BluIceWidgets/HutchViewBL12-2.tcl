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

package provide BLUICEHutchOverviewBL12-2 1.0

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
package require BLUICECollimatorCheckbutton

class DCS::HutchOverviewBL12-2 {
 	inherit ::itk::Widget
	
	itk_option define -detectorType detectorType DetectorType Q315CCD
	itk_option define -mdiHelper mdiHelper MdiHelper ""
	itk_option define -detectorZDevice detectorZDevice DetectorZDevice ""
	itk_option define -attenuationDevice attenuationDevice AttenuationDevice ""
	itk_option define -detectorVertDevice detectorVertDevice DetectorVertDevice ""
	itk_option define -detectorHorzDevice detectorHorzDevice DetectorHorzDevice ""

    public proc getMotorList { } {
        global gMotorBeamWidth
        global gMotorBeamHeight
        return [list \
        $gMotorBeamWidth \
        $gMotorBeamHeight \
        beam_stop_z \
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

	public method handleUpdateFromShutter
	public method handleDetectorTypeChange
	public method handleUserCollimatorStatusChange
    public method handleCurrentCollimatorStatusChange
    private method updateBeamSize

    public method handleUserAlignBeam { } {
        $m_opUserAlignBeam startOperation forced
    }

	private variable _detectorObject

   public method getDetectorHorzWidget {} {return $itk_component(detector_horz)}
	public method getDetectorVertWidget {} {return $itk_component(detector_vert)} 
	public method getDetectorZWidget {} {return $itk_component(detector_z)}
	public method getBeamstopZWidget {} {return $itk_component(beamstop)}
	public method getEnergyWidget {} {return $itk_component(energy)}
	public method getBeamWidthWidget {} {return $itk_component(beamWidth)}
	public method getBeamHeightWidget {} {return $itk_component(beamHeight)}
   
    private variable m_deviceFactory
    private variable m_strUserCollimatorStatus
    private variable m_strCurrentCollimatorStatus ""
    private variable m_strUserAlignBeamStatus
    private variable m_opUserAlignBeam
    private variable m_strRobotStatus

    private variable m_ctsUserCollimator    "0 -1 2 2"
    private variable m_ctsCurrentCollimator "0 -1 2 2"

	constructor { args} {
		# call base class constructor
		::DCS::Component::constructor {}
	} {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_strUserCollimatorStatus [$m_deviceFactory createString \
        user_collimator_status]
        $m_strUserCollimatorStatus createAttributeFromField isMicroBeam 0

        set m_strCurrentCollimatorStatus [$m_deviceFactory createString \
        collimator_status]
        $m_strCurrentCollimatorStatus createAttributeFromField isMicroBeam 0

        set m_strUserAlignBeamStatus \
        [$m_deviceFactory createUserAlignBeamStatusString \
        user_align_beam_status]

        set m_strRobotStatus \
        [$m_deviceFactory createString robot_status]

        set m_opUserAlignBeam  [$m_deviceFactory createOperation userAlignBeam]

		itk_component add canvas {
			canvas $itk_interior.c -width 1000 -height 285
		}

		# construct the panel of control buttons
		itk_component add control {
			::DCS::MotorControlPanelForcedMove $itk_component(canvas).control \
                -serialMove 1 \
				 -width 7 -orientation "horizontal" \
				 -ipadx 0 -ipady 0  -buttonBackground #c0c0ff \
				 -activeButtonBackground #c0c0ff  -font "helvetica -14 bold"
		} {
		}
			 
		place $itk_component(control) -x 30 -y 10

		# construct the goniometer widgets
		constructGoniometer 300 175

		# construct the detector widgets
		itk_component add detector_vert {
			::DCS::TitledMotorEntry $itk_component(canvas).detector_center_vert_offset \
				 -unitsList default \
				 -menuChoiceDelta 25  -units mm -unitsWidth 4 \
				 -entryWidth 10 \
				 -labelText "Vertical Offset" \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -honorStatus 0 \
                -device ::device::detector_center_vert_offset
		} {
		   keep -mdiHelper
		}
		
		itk_component add detector_z {
			# create motor view for detector_z
			::DCS::TitledMotorEntry $itk_component(canvas).detector_z \
				 -labelText "Distance" -unitsList default \
             -menuChoiceDelta 50 \
				 -entryType positiveFloat -units mm -unitsWidth 3 \
				 -entryWidth 8 \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -honorStatus 0
		} {
			keep -mdiHelper
			rename -device detectorZDevice detectorZDevice DetectorZDevice
		}

		itk_component add detector_horz {
			# create motor view for detector_horiz
			::DCS::TitledMotorEntry $itk_component(canvas).detector_horz \
				 -unitsList default \
				 -menuChoiceDelta 25  -units mm -unitsWidth 4 \
				 -entryWidth 10 \
				 -labelText "Horizontal Offset" \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -honorStatus 0 \
                -device ::device::detector_center_horz_offset
		} {
			keep -mdiHelper
		}
		
		itk_component add energy {
			# create motor view for detector_horiz
			::DCS::TitledMotorEntry $itk_component(canvas).energy \
				 -labelText "Energy" \
				 -entryWidth 10 \
				 -autoGenerateUnitsList 0 \
            -unitsList {A {-decimalPlaces 5 -menuChoiceDelta 0.1} eV {-decimalPlaces 3 -menuChoiceDelta 1000} keV {-decimalPlaces 6 -menuChoiceDelta 1.0}} \
				 -unitsWidth 4 \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -honorStatus 0
		} {
			keep -mdiHelper
			rename -device energyDevice energyDevice EnergyDevice
		}

		place $itk_component(canvas).energy -x 15 -y 190


        itk_component add optimize {
            DCS::Button $itk_component(canvas).optimize \
            -text "Optimize Beam" \
            -width 10 \
            -command "$this handleUserAlignBeam"
        } {
            keep -foreground
        }

        place $itk_component(optimize) -x 15 -y 255

        $itk_component(optimize) addInput \
        "$m_strUserAlignBeamStatus anyEnabled 1 {Opmization Disabled}"
        $itk_component(optimize) addInput \
        "$m_strRobotStatus OKToAlignBeam 1 {Dismount First}"
        $itk_component(optimize) addInput \
        "$m_strRobotStatus status_num 0 {Robot Not Ready}"

      set cfgShowCollimator [::config getInt bluice.showCollimator 1]
      if {$cfgShowCollimator \
      && [$m_deviceFactory operationExists collimatorMove]} {
		   itk_component add collimator {
			    CollimatorDropdown $itk_component(canvas).collimator
		   } {
		   }

		place $itk_component(collimator) -x 230 -y 245
      }

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

        $itk_component(control) configure \
        -forcedMotorMoveList [list \
        ::$itk_component(detector_z) \
        ::$itk_component(beamstop) \
        ]

		::mediator register $this ::$_detectorObject type handleDetectorTypeChange
		::mediator register $this $m_strUserCollimatorStatus    contents  handleUserCollimatorStatusChange
		::mediator register $this $m_strCurrentCollimatorStatus contents  handleCurrentCollimatorStatusChange

		::mediator announceExistence $this

      set m_deviceFactory [DCS::DeviceFactory::getObject]
		set shutterObject [$m_deviceFactory createShutter shutter]
		::mediator register $this $shutterObject state handleUpdateFromShutter
		
		return
	}
    
    destructor { }
}

body DCS::HutchOverviewBL12-2::destructor {} {
	mediator announceDestruction $this
}


#draw the postshutter view of the beam
body DCS::HutchOverviewBL12-2::handleUpdateFromShutter { shutter_ targetReady_ - state_ -} {

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



body DCS::HutchOverviewBL12-2::constructGoniometer { x y } {

	# draw and label the goniometer
	global BLC_IMAGES

	set goniometerImage [ image create photo -file "$BLC_IMAGES/microDiffHutchView.gif" -palette "256/256/256"]
	
#	itk_component add goniometerImage {
		$itk_component(canvas) create image $x [expr $y - 190] -anchor nw -image $goniometerImage
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

	place $itk_component(phi) -x [expr $x +50 ]  -y [expr $y -172 ]
	
	
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

	#place $itk_component(omega) -x [expr $x - 110] -y [expr $y -185]
	
	# create motor view for gonio_kappa
	itk_component add kappa {
		::DCS::TitledMotorEntry $itk_component(canvas).kappa \
			 -labelText "Kappa"  -autoGenerateUnitsList 0 \
          -unitsWidth 4 -unitsList {deg {-menuChoiceDelta 5 -precision .001}} -activeClientOnly 1
	} {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device gonioKappaDevice gonioKappaDevice GonioKappaDevice
	}

	#place $itk_component(kappa) -x [expr $x + 140] -y [expr $y - 185]

	$itk_component(control) registerMotorWidget ::$itk_component(phi)
	#$itk_component(control) registerMotorWidget ::$itk_component(omega)
	#$itk_component(control) registerMotorWidget ::$itk_component(kappa)

}

body DCS::HutchOverviewBL12-2::constructFrontend { x y } {

	# create the image of the frontend
	global BLC_IMAGES
	set frontendImage [ image create photo \
									-file "$BLC_IMAGES/frontend.gif" \
									-palette "256/256/256"]
	$itk_component(canvas) create image 50 52 -anchor nw -image $frontendImage

	# draw the label for the frontend
	label $itk_component(canvas).frontendLabel \
		 -font "helvetica -18 bold" \
		 -text "Beam Collimator"

	#	place $itk_component(canvas).frontendLabel -x 130 -y 265

	# draw the X-ray beam entering the collimator
	$itk_component(canvas) create line 0 141 58 141 -fill magenta -width 4

	# draw the beam after the shutter
	$itk_component(canvas) create line 383 140 644 140 -fill magenta -width 2 -tag postShutterBeam
	
	#$energyWidget addInput "${deviceNamespace}::mono_theta status inactive {supporting device}"

	#$itk_component(control) registerMotorWidget ::$energyWidget

	# create motor view for detector_horiz
	itk_component add beamWidth {
		::DCS::TitledMotorEntry $itk_component(canvas).beam_width \
        -updateValueOnMatch 1 \
        -precision 0.001 \
        -labelText "Beam Width" \
        -entryWidth 5 \
        -autoGenerateUnitsList 0 \
        -autoMenuChoices 0 \
        -units mm \
        -activeClientOnly 1 \
        -menuChoices [list 0.050 0.060 0.070 0.075 0.080 0.100] \
        -entryType positiveFloat \
	} {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device beamWidthDevice beamWidthDevice BeamWidthDevice
	}

	# create motor view for detector_horiz
	itk_component add beamHeight {
		::DCS::TitledMotorEntry $itk_component(canvas).beam_height \
        -updateValueOnMatch 1 \
        -precision 0.001 \
		-labelText "Beam Height" \
        -entryWidth 5 \
        -autoGenerateUnitsList 0 \
        -autoMenuChoices 0 \
        -units mm \
        -entryType positiveFloat \
        -menuChoices \
        [list 0.015 0.020 0.025 0.030 0.040 0.050 0.075 0.100 0.200] \
        -activeClientOnly 1 \
	} {
        keep -systemIdleOnly
		keep -mdiHelper
		rename -device beamHeightDevice beamHeightDevice BeamHeightDevice
	}

	itk_component add collimatorBeamWidth {
		::DCS::TitledMotorEntry $itk_component(canvas).collimator_width \
             -precision 0.001 \
			 -labelText "Beam Width" \
			 -entryWidth 5  -autoGenerateUnitsList 0 \
             -units mm \
             -entryType positiveFloat \
             -menuChoiceDelta 0.05 \
             -activeClientOnly 1
	} {
        keep -systemIdleOnly
		keep -mdiHelper
	}

	itk_component add collimatorBeamHeight {
		::DCS::TitledMotorEntry $itk_component(canvas).collimator_height \
             -precision 0.001 \
			 -labelText "Beam Height" \
			 -entryWidth 5 -autoGenerateUnitsList 0 \
             -units mm \
             -entryType positiveFloat \
             -menuChoiceDelta 0.05 \
             -activeClientOnly 1
	} {
        keep -systemIdleOnly
		keep -mdiHelper
	}

    $itk_component(collimatorBeamWidth) addInput \
    "$m_strUserCollimatorStatus isMicroBeam 0 {collimator selected}"
    $itk_component(collimatorBeamWidth) addInput \
    "$m_strCurrentCollimatorStatus isMicroBeam 0 {collimator inserted}"

    $itk_component(collimatorBeamHeight) addInput \
    "$m_strUserCollimatorStatus isMicroBeam 0 {collimator selected}"
    $itk_component(collimatorBeamHeight) addInput \
    "$m_strCurrentCollimatorStatus isMicroBeam 0 {collimator inserted}"

	#$itk_component(canvas) create text 320 223 -text "x" -font "helvetica -14 bold"
    itk_component add cross {
        label $itk_component(canvas).cross \
        -text "x" \
        -font "helvetica -14 bold"
    } {
    }

	place $itk_component(beamWidth) -x 206 -y 190
    place $itk_component(cross) -x 320 -y 223
	place $itk_component(beamHeight) -x 330 -y 190
	
	$itk_component(control) registerMotorWidget ::$itk_component(beamWidth)
	$itk_component(control) registerMotorWidget ::$itk_component(beamHeight)	

   constructAttenuation

}

body DCS::HutchOverviewBL12-2::constructAttenuation { } {

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


	place $itk_component(attenuation) -x 80 -y 70
	$itk_component(control) registerMotorWidget ::$itk_component(attenuation)
}

body DCS::HutchOverviewBL12-2::constructBeamstop { x y } {

	# create the image of the frontend
	global BLC_IMAGES
	#set beamstopImage [ image create photo -file "$BLC_IMAGES/beamstop.gif" -palette "256/256/256"]
	#$itk_component(canvas) create image 570 159 -anchor nw -image $beamstopImage

	# draw the label for the frontend
	#label $itk_component(canvas).beamstopLabel \
	#	 -font "helvetica -18 bold" \
	#	 -text "Beamstop"
	#	place $itk_component(canvas).beamstopLabel -x 530 -y 265
	
	# create motor view for beamstop_z
	itk_component add beamstop {
		::DCS::TitledMotorEntry $itk_component(canvas).beamstop \
             -extraDevice ::device::beamstop_z \
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


	place $itk_component(beamstop) -x 595 -y 60 
	$itk_component(control) registerMotorWidget ::$itk_component(beamstop)

	# draw arrow for beam stop motion
	#$itk_component(canvas) create line 580 190 620 190 -arrow both -width 3 -fill black	
	#$itk_component(canvas) create text 613 180 -text "+" -font "courier -10 bold"
	#$itk_component(canvas) create text 584 180 -text "-" -font "courier -10 bold"
}

body DCS::HutchOverviewBL12-2::handleDetectorTypeChange { detector_ targetReady_ alias_ type_ -  } {
	
	if { ! $targetReady_} return
	configure -detectorType $type_
}

body DCS::HutchOverviewBL12-2::handleUserCollimatorStatusChange { - targetReady_ alias_ contents_ -  } {
	if { ! $targetReady_} return
    if {[llength $contents_] < 4} {
        return
    }
    puts "BeamSizeView user collimator: $contents_"
    set m_ctsUserCollimator $contents_
    updateBeamSize
}
body DCS::HutchOverviewBL12-2::handleCurrentCollimatorStatusChange { - targetReady_ alias_ contents_ -  } {
	if { ! $targetReady_} return
    if {[llength $contents_] < 4} {
        return
    }
    puts "BeamSizeView system collimator: $contents_"
    set m_ctsCurrentCollimator $contents_
    updateBeamSize
}
body DCS::HutchOverviewBL12-2::updateBeamSize { } {
    set userWillUseCollimator [lindex $m_ctsUserCollimator 0]
    set currentCollimatorIn   [lindex $m_ctsCurrentCollimator 0]

    if {$userWillUseCollimator || $currentCollimatorIn} {
	    place forget $itk_component(beamWidth)
	    place forget $itk_component(beamHeight)

	    $itk_component(beamWidth)  cancelChanges
	    $itk_component(beamHeight) cancelChanges

        #### current setting has higher priority
        if {$currentCollimatorIn} {
            foreach {isMicro index w h} $m_ctsCurrentCollimator break
        } else {
            foreach {isMicro index w h} $m_ctsUserCollimator break
        }

	    $itk_component(collimatorBeamWidth)  setValue $w
	    $itk_component(collimatorBeamHeight) setValue $h
	    place $itk_component(collimatorBeamWidth) -x 206 -y 190
	    place $itk_component(collimatorBeamHeight) -x 330 -y 190
    } else {
	    place forget $itk_component(collimatorBeamWidth)
	    place forget $itk_component(collimatorBeamHeight)

	    place $itk_component(beamWidth) -x 206 -y 190
	    place $itk_component(beamHeight) -x 330 -y 190
    }
}

configbody DCS::HutchOverviewBL12-2::detectorType {

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
			place $itk_component(detector_z) -x 660 -y 125
			place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/q4_small.gif" \
											-palette "256/256/256"]
			$itk_component(canvas) create image 820 90 \
				 -anchor nw \
				 -image $detectorImage -tag detectorItems
			
			$itk_component(canvas) create line 900 55 900 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 61 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 910 88 -text "-" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 796 157 821 157 -arrow first -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create line 821 157 836 157 -arrow last  -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create text 800 148 -text "-" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 835 148 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
			
			$itk_component(canvas) create line 913 185 942 212 -arrow both -width 3 -fill black	 -tag detectorItems
			$itk_component(canvas) create text 927 188 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 948 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}
		
		Q315CCD {
			place $itk_component(detector_vert) -x 835 -y 0 
			place $itk_component(detector_z) -x 660 -y 125
			place $itk_component(detector_horz) -x 855 -y 212

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/q4_small.gif" \
											-palette "256/256/256" ]

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

		MAR345 {
			place $itk_component(detector_vert) -x 835 -y 0
			place $itk_component(detector_z) -x 657 -y 125
			place $itk_component(detector_horz) -x 855 -y 235

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar_small.gif" \
											-palette "256/256/256"]

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

			place $itk_component(detector_vert) -x 780 -y 30
			place $itk_component(detector_z) -x 657 -y 125
			place $itk_component(detector_horz) -x 855 -y 172

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar165.gif" \
											-palette "256/256/256"]
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
			place $itk_component(detector_vert) -x 750 -y 00 
			place $itk_component(detector_z) -x 710 -y 171
			place $itk_component(detector_horz) -x 851 -y 205

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/mar325+arrows.gif" ]	

			$itk_component(canvas) create image 800 00 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems
			
		}


		PILATUS6 {
			place $itk_component(detector_vert) -x 750 -y 00 
			place $itk_component(detector_z) -x 710 -y 176
			place $itk_component(detector_horz) -x 851 -y 205

			set detectorImage [ image create photo \
											-file "$BLC_IMAGES/pilatus6+arrows.gif" ]	

			$itk_component(canvas) create image 800 20 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems
			
		}


		default {
			place $itk_component(detector_vert) -x 835 -y 30
			place $itk_component(detector_z) -x 657 -y 125
			place $itk_component(detector_horz) -x 855 -y 203

			$itk_component(canvas) create line 900 85 900 125 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 910 91 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 910 1288 -text "-" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 791 157 821 157 -arrow both -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 796 148 -text "-" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 817 148 -text "+" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 903 178 927 202 -arrow both -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 898 183 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
			$itk_component(canvas) create text 911 200 -text "-" -font "courier -10 bold"	-tag detectorItems

		}
	}
}





class ::DCS::MotorControlPanelForcedMove {
	inherit ::DCS::MotorControlPanel 
	#::DCS::ComponentGate
	itk_option define -forcedMotorMoveList forcedMotorMoveList ForcedMotorMoveList ""

	public method applyChanges
	constructor { args } {

		eval itk_initialize $args
		#announceExist
	}




}

### copied and modified from MotorControlPanel
body ::DCS::MotorControlPanelForcedMove::applyChanges {} {
    set motors [list]
    foreach widget $_registeredMotorList {
        set move_command [$widget getMoveCommand]
        if {$move_command != ""} {
            lappend motors $move_command
            set device [$widget cget -device]
            if {$device != ""} {
                $device saveUndo
            }
        } elseif {[lsearch $itk_option(-forcedMotorMoveList) $widget] != -1} {
            set device [$widget cget -device]
            set motorName [$device cget -deviceName]
            set move_command "$motorName by 0"
            lappend motors $move_command
        }
    }

    if {[llength $motors]} {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set opObj [$deviceFactory createOperation moveMotors]
        eval $opObj startOperation $itk_option(-serialMove) $motors
    }
}
