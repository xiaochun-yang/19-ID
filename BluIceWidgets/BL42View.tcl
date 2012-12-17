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

package provide BLUICEBL42Overview 1.0

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



class DCS::BL42Overview {
 	inherit ::itk::Widget
	
	itk_option define -detectorType detectorType DetectorType Q315CCD
	itk_option define -mdiHelper mdiHelper MdiHelper ""
	
	public variable withSampleVideo 0
	public variable withHutchVideo 0

	# protected variables
	protected variable canvas

	# protected methods
	protected method constructGoniometer
	protected method constructDetector
	protected method constructFrontend
	protected method constructBeamstop
	protected method constructAutomation

	public method handleUpdateFromShutter
	public method handleDetectorTypeChange

	private variable _detectorObject

	constructor { args} {
		# call base class constructor
		::DCS::Component::constructor {}
	} {
		itk_component add ring {
			frame $itk_interior.r
		}

		itk_component add canvas {
			canvas $itk_component(ring).c -width 1000 -height 285
		}

		# construct the panel of control buttons
		itk_component add control {
			::DCS::MotorControlPanel $itk_component(canvas).control \
				 -width 7 -orientation "horizontal" \
				 -ipadx 4 -ipady 5  -buttonBackground #c0c0ff \
				 -activeButtonBackground #c0c0ff  -font "helvetica -14 bold"
		} {
		}
			 
		place $itk_component(control) -x 680 -y 10

		# construct the goniometer widgets
		constructGoniometer 250 210

		# construct the detector widgets
		itk_component add detector_vert {
			::DCS::TitledMotorEntry $itk_component(canvas).detector_vert \
				 -unitsList default \
				 -menuChoiceDelta 25  -units mm -unitsWidth 4 \
				 -entryWidth 10 \
				 -labelText "Vertical"  
		} {
			keep -activeClientOnly
            		keep -systemIdleOnly
			keep -mdiHelper
			rename -device detectorVertDevice detectorVertDevice DetectorVertDevice
		}
		
#		itk_component add detector_z {
#			# create motor view for detector_z
#			::DCS::TitledMotorEntry $itk_component(canvas).detector_z_corr \
#				 -labelText "Distance" -unitsList default \
#             			 -menuChoiceDelta 50 \
#				 -entryType positiveFloat -units mm -unitsWidth 3 \
#				 -entryWidth 8
#		} {
#			keep -activeClientOnly
#            		keep -systemIdleOnly
#			keep -mdiHelper
#			rename -device detectorZDevice detectorZDevice DetectorZDevice
#		}

		itk_component add detector_horz {
			# create motor view for detector_horiz
			::DCS::TitledMotorEntry $itk_component(canvas).detector_horz \
				 -unitsList default \
				 -menuChoiceDelta 25  -units mm -unitsWidth 4 \
				 -entryWidth 10 \
				 -labelText "Horizontal"
		} {
			keep -activeClientOnly
            		keep -systemIdleOnly
			keep -mdiHelper
			rename -device detectorHorzDevice detectorHorzDevice DetectorHorzDevice
		}
		
		itk_component add energy {
			# create motor view for detector_horiz
			::DCS::TitledMotorEntry $itk_component(canvas).energy \
				 -labelText "Energy" \
				 -entryWidth 10 \
				 -autoGenerateUnitsList 0 \
            			 -unitsList {A {-decimalPlaces 5 -menuChoiceDelta 0.1} eV {-decimalPlaces 3 -menuChoiceDelta 1000} keV {-decimalPlaces 6 -menuChoiceDelta 1.0}} \
				 -unitsWidth 4 
		} {
			keep -activeClientOnly
            		keep -systemIdleOnly
			keep -mdiHelper
			rename -device energyDevice energyDevice EnergyDevice
		}

		place $itk_component(canvas).energy -x 845 -y 200


		itk_component add scope {
			# create motor view for scope
			::DCS::TitledMotorEntry $itk_component(canvas).scope \
				 -labelText "Scope" \
				 -entryWidth 10 \
				 -autoGenerateUnitsList 0 \
        		 	 -unitsWidth 4 -unitsList {mm {-entryType positiveFloat -menuChoiceDelta 0.05}} \
				 -device ::device::beamstop_z
		} {
			keep -activeClientOnly
            		keep -systemIdleOnly
			keep -mdiHelper
		}
		place $itk_component(canvas).scope -x 550 -y 200

		itk_component add optimize {
			# make the optimize beam button
			OptimizeButton $itk_component(canvas).optimize \
				 -text "Optimize Beam" \
				 -width 10
		} {
			keep -foreground
		}


		place $itk_component(optimize) -x 845 -y 255


		$itk_component(control) registerMotorWidget ::$itk_component(detector_vert)
		$itk_component(control) registerMotorWidget ::$itk_component(scope)
		$itk_component(control) registerMotorWidget ::$itk_component(detector_horz)
#		$itk_component(control) registerMotorWidget ::$itk_component(detector_z)
		$itk_component(control) registerMotorWidget ::$itk_component(energy)


		# construct the frontend widgets
		constructFrontend 0 0

		# construct the beamstop widgets
#		constructBeamstop 0 0

		pack $itk_component(ring)
		pack $itk_component(canvas)


		eval itk_initialize $args
		
		#create on object for watching the detector
		set _detectorObject [DCS::Detector::getObject]
		::mediator register $this ::$_detectorObject type handleDetectorTypeChange

		::mediator announceExistence $this

      		set m_deviceFactory [DCS::DeviceFactory::getObject]
		set shutterObject [$m_deviceFactory createShutter shutter]
		::mediator register $this $shutterObject state handleUpdateFromShutter
		
		return
	}
}

body DCS::ResolutionControlWidget::destructor {} {
	mediator announceDestruction $this
}


#draw the postshutter view of the beam
body DCS::BL42Overview::handleUpdateFromShutter { shutter_ targetReady_ - state_ -} {

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



body DCS::BL42Overview::constructGoniometer { x y } {

	# draw and label the goniometer
	global BLC_IMAGES

	set goniometerImage [ image create photo -file "$BLC_IMAGES/stage.gif" -palette "8/8/8"]
	
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
						 225.000 270.000 315.000 360.000}  
	}  {
		keep -activeClientOnly
        	keep -systemIdleOnly
		keep -mdiHelper
		rename -device gonioPhiDevice gonioPhiDevice GonioPhiDevice
	}

	place $itk_component(phi) -x [expr $x + 115]  -y [expr $y - 200]
	
	
#	# create motor view for gonio_omega
#	itk_component add omega {
#		::DCS::TitledMotorEntry $itk_component(canvas).omega \
#			 -labelText "Omega"  -autoGenerateUnitsList 0 \
#			 -unitsWidth 4 -unitsList {deg {-menuChoiceDelta 15}} \
#			 -device ::device::gonio_omega
#	} {
#		keep -activeClientOnly
#        	keep -systemIdleOnly
#		keep -mdiHelper
#	}

#	place $itk_component(omega) -x [expr $x + 115] -y [expr $y -185]
	
#	# create motor view for gonio_kappa
#	itk_component add kappa {
#		::DCS::TitledMotorEntry $itk_component(canvas).kappa \
#			 -labelText "Kappa"  -autoGenerateUnitsList 0 \
#          		 -unitsWidth 4 -unitsList {deg {-menuChoiceDelta 5 -precision .001}} 
#	} {
#		keep -activeClientOnly
#        	keep -systemIdleOnly
#		keep -mdiHelper
#		rename -device gonioKappaDevice gonioKappaDevice GonioKappaDevice
#	}

#	place $itk_component(kappa) -x [expr $x - 125] -y [expr $y - 185]


	# create motor view for sample stage vertical
	itk_component add stagev {
		::DCS::TitledMotorEntry $itk_component(canvas).stagev \
			 -labelText "Vertical"  -autoGenerateUnitsList 0 \
          		 -unitsWidth 4 -unitsList {mm {-entryType float -menuChoiceDelta 0.05}} \
			 -device ::device::sample_z
	} {
		keep -activeClientOnly
        	keep -systemIdleOnly
		keep -mdiHelper
	}

	place $itk_component(stagev) -x [expr $x + 115] -y [expr $y -50]
	
	# create motor view for sample stage horizontal
	itk_component add stageh {
		::DCS::TitledMotorEntry $itk_component(canvas).stageh \
			 -labelText "Horizontal"  -autoGenerateUnitsList 0 \
          		 -unitsWidth 4 -unitsList {mm {-entryType float -menuChoiceDelta 0.05}} \
			 -device ::device::sample_x 
	} {
		keep -activeClientOnly
        	keep -systemIdleOnly
		keep -mdiHelper
	}

	place $itk_component(stageh) -x [expr $x + 115] -y [expr $y - 1]

	$itk_component(control) registerMotorWidget ::$itk_component(phi)
	$itk_component(control) registerMotorWidget ::$itk_component(stagev)
	$itk_component(control) registerMotorWidget ::$itk_component(stageh)
}

body DCS::BL42Overview::constructFrontend { x y } {

	# create the image of the frontend
	global BLC_IMAGES
	set frontendImage [ image create photo \
		-file "$BLC_IMAGES/frontendn.gif" \
		-palette "8/8/8"]
	$itk_component(canvas) create image 605 72 -anchor nw -image $frontendImage

	# draw the label for the frontend
	label $itk_component(canvas).frontendLabel \
		 -font "helvetica -18 bold" \
		 -text "Beam Collimator"

	#	place $itk_component(canvas).frontendLabel -x 130 -y 265

	# draw the X-ray beam entering the collimator
	$itk_component(canvas) create line 947 161 1000 161 -fill magenta -width 4

	# draw the beam after the shutter
	$itk_component(canvas) create line 383 163 620 163 -fill magenta -width 2 -tag postShutterBeam
	
	#$energyWidget addInput "${deviceNamespace}::mono_theta status inactive {supporting device}"

	#$itk_component(control) registerMotorWidget ::$energyWidget

#	# create motor view for detector_horiz
#	itk_component add beamWidth {
#		::DCS::TitledMotorEntry $itk_component(canvas).beam_width \
#			 -labelText "Beam Width" \
#			 -entryWidth 5  -autoGenerateUnitsList 0 \
#        		 -unitsList {mm {-entryType positiveFloat -menuChoiceDelta 0.05}}
#	} {
#		keep -activeClientOnly
#        	keep -systemIdleOnly
#		keep -mdiHelper
#		rename -device beamWidthDevice beamWidthDevice BeamWidthDevice
#	}

#	# create motor view for detector_horiz
#	itk_component add beamHeight {
#		::DCS::TitledMotorEntry $itk_component(canvas).beam_height \
#			 -labelText "Beam Height" \
#			 -entryWidth 5 -autoGenerateUnitsList 0 \
#        		 -unitsList {mm {-entryType positiveFloat -menuChoiceDelta 0.05} }
#	} {
#		keep -activeClientOnly
#        	keep -systemIdleOnly
#		keep -mdiHelper
#		rename -device beamHeightDevice beamHeightDevice BeamHeightDevice
#	}


#	$itk_component(canvas) create text 703 233 -text "x" -font "helvetica -14 bold"

	# create motor view for beam attenuation
	itk_component add attenuation {
		::DCS::TitledMotorEntry $itk_component(canvas).attenuation \
			 -labelText "Attenuation" \
			 -entryType positiveFloat \
			 -menuChoiceDelta 10 -units "%"  -autoGenerateUnitsList 0 \
			 -decimalPlaces 1
	} {
		keep -activeClientOnly
        	keep -systemIdleOnly
		keep -mdiHelper
		rename -device attenuationDevice attenuationDevice AttenuationDevice
	}

#	place $itk_component(beamWidth) -x 710 -y 200
#	place $itk_component(beamHeight) -x 590 -y 200
	place $itk_component(attenuation) -x 805 -y 90
	
#	$itk_component(control) registerMotorWidget ::$itk_component(beamWidth)
#	$itk_component(control) registerMotorWidget ::$itk_component(beamHeight)	
	$itk_component(control) registerMotorWidget ::$itk_component(attenuation)
}


body DCS::BL42Overview::constructBeamstop { x y } {

	# create the image of the frontend
	global BLC_IMAGES
	set beamstopImage [ image create photo -file "$BLC_IMAGES/beamstopn.gif" -palette "8/8/8"]
	$itk_component(canvas) create image 350 159 -anchor nw -image $beamstopImage

	# draw the label for the frontend
	label $itk_component(canvas).beamstopLabel \
		 -font "helvetica -18 bold" \
		 -text "Beamstop"
	#	place $itk_component(canvas).beamstopLabel -x 530 -y 265
	
	# create motor view for beamstop_z
	itk_component add beamstop {
		::DCS::TitledMotorEntry $itk_component(canvas).beamstop \
			 -labelText "Beamstop" \
			 -menuChoiceDelta 5 \
			 -entryType positiveFloat \
			 -decimalPlaces 3 -units mm
	} {
		keep -activeClientOnly
        	keep -systemIdleOnly
		keep -mdiHelper
		rename -device beamstopDevice beamStopDevice BeamStopDevice
	}


	place $itk_component(beamstop) -x 330 -y 225
	$itk_component(control) registerMotorWidget ::$itk_component(beamstop)

	# draw arrow for beam stop motion
	$itk_component(canvas) create line 367 190 407 190 -arrow both -width 3 -fill black	
	$itk_component(canvas) create text 403 180 -text "-" -font "courier -10 bold"
	$itk_component(canvas) create text 369 180 -text "+" -font "courier -10 bold"
}

body DCS::BL42Overview::handleDetectorTypeChange { detector_ targetReady_ alias_ type_ -  } {
	
	if { ! $targetReady_} return
	configure -detectorType $type_
}


configbody DCS::BL42Overview::detectorType {

	# draw and label the detector
	global BLC_IMAGES

	set x 0
	set y 0

	#delete any old graphic items from a previous detector configuration
	$itk_component(canvas) delete detectorItems

	#draw the detector items
	switch $itk_option(-detectorType) {

		Q4CCD {

			place $itk_component(canvas).detector_vert -x 15 -y 0
#			place $itk_component(canvas).detector_z_corr -x 205 -y 125
			place $itk_component(canvas).detector_horz -x 0 -y 212

			set detectorImage [ image create photo \
				-file "$BLC_IMAGES/q4_smalln.gif" \
				-palette "8/8/8"]
			$itk_component(canvas) create image 18 90 \
				 -anchor nw \
				 -image $detectorImage -tag detectorItems
			
			$itk_component(canvas) create line 100 55 100 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 90 61 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 90 88 -text "-" -font "courier -10 bold" -tag detectorItems
			
#			$itk_component(canvas) create line 177 157 202 157 -arrow last -width 3 -fill black -tag detectorItems
#			$itk_component(canvas) create line 162 157 177 157 -arrow first  -width 3 -fill white -tag detectorItems
#			$itk_component(canvas) create text 200 148 -text "-" -font "courier -10 bold" -tag detectorItems
#			$itk_component(canvas) create text 165 148 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
			
			$itk_component(canvas) create line 58 212 87 185 -arrow both -width 3 -fill black	 -tag detectorItems
			$itk_component(canvas) create text 73 188 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 52 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}
		
		Q315CCD {
			place $itk_component(canvas).detector_vert -x 15 -y 0 
#			place $itk_component(canvas).detector_z_corr -x 205 -y 125
			place $itk_component(canvas).detector_horz -x 0 -y 212

			set detectorImage [ image create photo \
				-file "$BLC_IMAGES/q4_smalln.gif" \
				-palette "8/8/8" ]

			$itk_component(canvas) create image 18 90 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems
			
			$itk_component(canvas) create line 100 55 100 95 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 90 61 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 90 88 -text "-" -font "courier -10 bold"	-tag detectorItems
			
#			$itk_component(canvas) create line 177 157 202 157 -arrow last -width 3 -fill black -tag detectorItems
#			$itk_component(canvas) create line 162 157 177 157 -arrow first  -width 3 -fill white -tag detectorItems
#			$itk_component(canvas) create text 200 148 -text "-" -font "courier -10 bold"	-tag detectorItems
#			$itk_component(canvas) create text 165 148 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			
			$itk_component(canvas) create line 58 212 87 185 -arrow both -width 3 -fill black	-tag detectorItems
			$itk_component(canvas) create text 73 188 -text "+" -font "courier -10 bold"	-tag detectorItems
			$itk_component(canvas) create text 52 207 -text "-" -font "courier -10 bold"	-tag detectorItems
		}

		MAR345 {
			place $itk_component(canvas).detector_vert -x 15 -y 0
#			place $itk_component(canvas).detector_z_corr -x 205 -y 125
			place $itk_component(canvas).detector_horz -x 0 -y 235

			set detectorImage [ image create photo \
				-file "$BLC_IMAGES/mar_smalln.gif" \
				-palette "8/8/8"]

			$itk_component(canvas) create image 18 53 \
				 -anchor nw \
				 -image $detectorImage 	-tag detectorItems

			$itk_component(canvas) create line 100 55 100 95 -arrow both -width 3 -fill black 	-tag detectorItems	
			$itk_component(canvas) create text 90 61 -text "+" -font "courier -10 bold" 	-tag detectorItems
			$itk_component(canvas) create text 90 88 -text "-" -font "courier -10 bold" 	-tag detectorItems
			
#			$itk_component(canvas) create line 177 157 202 157 -arrow both -width 3 -fill black 	-tag detectorItems
#			$itk_component(canvas) create text 204 148 -text "-" -font "courier -10 bold" 	-tag detectorItems
#			$itk_component(canvas) create text 183 148 -text "+" -font "courier -10 bold" 	-tag detectorItems
		
			$itk_component(canvas) create line 85 222 97 210 -arrow last -width 3 -fill white	-tag detectorItems
			$itk_component(canvas) create line 73 234 85 222 -arrow first -width 3 -fill black	-tag detectorItems
			$itk_component(canvas) create text 102 215 -text "+" -font "courier -10 bold" -fill white	-tag detectorItems
			$itk_component(canvas) create text 89 232 -text "-" -font "courier -10 bold"		-tag detectorItems
		}

		MAR165 {

			place $itk_component(canvas).detector_vert -x 15 -y 30
#			place $itk_component(canvas).detector_z_corr -x 205 -y 125
			place $itk_component(canvas).detector_horz -x 0 -y 203

			set detectorImage [ image create photo \
				-file "$BLC_IMAGES/mar165n.gif" \
				-palette "8/8/8"]
			$itk_component(canvas) create image 18 107 \
				 -anchor nw \
				 -image $detectorImage -tag detectorItems

			$itk_component(canvas) create line 100 85 100 125 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 90 91 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 90 120 -text "-" -font "courier -10 bold" -tag detectorItems
			
#			$itk_component(canvas) create line 177 157 202 157 -arrow both -width 3 -fill black -tag detectorItems
#			$itk_component(canvas) create text 202 148 -text "-" -font "courier -10 bold" -tag detectorItems
#			$itk_component(canvas) create text 177 148 -text "+" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 85 190 97 178 -arrow last -width 3 -fill white -tag detectorItems
			$itk_component(canvas) create line 73 202 85 190 -arrow first -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 102 183 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
			$itk_component(canvas) create text 89 200 -text "-" -font "courier -10 bold"	-tag detectorItems
		}
		default {
			place $itk_component(canvas).detector_vert -x 15 -y 30
#			place $itk_component(canvas).detector_z_corr -x 205 -y 125
			place $itk_component(canvas).detector_horz -x 0 -y 203

			$itk_component(canvas) create line 100 85 100 125 -arrow both -width 3 -fill black -tag detectorItems	
			$itk_component(canvas) create text 90 91 -text "+" -font "courier -10 bold" -tag detectorItems
			$itk_component(canvas) create text 90 120 -text "-" -font "courier -10 bold" -tag detectorItems
			
#			$itk_component(canvas) create line 179 157 202 157 -arrow both -width 3 -fill black -tag detectorItems
#			$itk_component(canvas) create text 204 148 -text "-" -font "courier -10 bold" -tag detectorItems
#			$itk_component(canvas) create text 183 148 -text "+" -font "courier -10 bold" -tag detectorItems
			
			$itk_component(canvas) create line 73 202 97 178 -arrow both -width 3 -fill black -tag detectorItems
			$itk_component(canvas) create text 102 183 -text "+" -font "courier -10 bold" -fill white -tag detectorItems
			$itk_component(canvas) create text 89 200 -text "-" -font "courier -10 bold"	-tag detectorItems

		}
	}
}


