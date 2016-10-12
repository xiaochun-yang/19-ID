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

package provide BLUICEResolution 1.0


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
	package require DCSPrompt
	package require DCSMotorControlPanel


class DCS::DetectorFace {
 	inherit ::itk::Widget

	itk_option define -detectorXInMM detectorXInMM DetectorXinMM 0.0
	itk_option define -detectorYInMM detectorYInMM DetectorYinMM 0.0
	itk_option define -detectorZInMM	detectorZInMM DetectorZinMM 100.0
	itk_option define -beamstopZInMM	beamstopZInMM BeamstopZinMM 40.0
	itk_option define -beamEnergy beamEnergy BeamEnergy .992
	itk_option define -maxRingSizeInPixels maxRingSizeInPixels MaxRingSizeInPixels 2000
	itk_option define -minRingSizeInPixels	minRingSizeInPixels MinRingSizeInPixels 0.1
	itk_option define -minRingGapInPixels	minRingGapInPixels MinRingGapInPixels 15
	itk_option define -resolutionFont resolutionFont ResolutionFont "helvetica -14 bold"
	itk_option define -onClick onClick OnClick ""
	itk_option define -detectorXWidget detectorXWidget DetectorXWidget ""
	itk_option define -detectorYWidget detectorYWidget DetectorYWidget ""
	itk_option define -detectorZWidget detectorZWidget DetectorZWidget ""
	itk_option define -beamstopXWidget beamstopXWidget BeamstopXWidget ""
        itk_option define -beamstopYWidget beamstopYWidget BeamstopYWidget ""
        itk_option define -beamstopZWidget beamstopZWidget BeamstopZWidget ""
	itk_option define -energyWidget energyWidget EnergyWidget ""
	itk_option define -detectorForeground detectorForeground DetectorForeground ""

	# protected data
	protected variable canvasOriginX 0
	protected variable canvasOriginY 0
	protected variable detectorXInPixels
	protected variable detectorYInPixels
	protected variable detectorOffsetAngle
	protected variable beamOffsetAngle
	protected variable detectorOffsetInMM
	protected variable detectorOffsetInPixels
	protected variable updateOutstanding 0
	protected variable pixelsPerMM 1.0

    ## to support dyamic configure (change after constructor)
    protected variable m_xWidget ""
    protected variable m_yWidget ""
    protected variable m_zWidget ""
    protected variable m_bWidget ""
    protected variable m_eWidget ""

	# protected member functions
	protected method updateDetectorGraphics {} {}
	protected method drawResolutionRing
	protected method drawResolutionText
	protected method drawResolutionArc
	protected method drawDirectBeamMark
	protected method drawBeamstopRing
	protected method clearCanvas
	protected method drawDetector {} {}
	protected method drawResolutionRings {} {}
	protected method calculateDetectorParameters {}
   protected method calcPixelsPerMM

	# public methods
	public method clickHandler { newClickX newClickY }
	public method handleResize
	public method handleUpdateFromX
	public method handleUpdateFromY
	public method handleUpdateFromZ
	public method handleUpdateFromB
	public method handleUpdateFromBH
	public method handleUpdateFromBV
	public method handleUpdateFromE

	public method updateDetectorGraphicsAsync
	public method handleAsyncUpdate

	# base class constructor
	constructor { args } {

		# create canvas
		itk_component add canvas {
			canvas $itk_interior.c
		} {
			rename -background -detectorBackground background Background
			#rename -fg -detectorForeground foreground Foreground
		}

		grid $itk_component(canvas) -row 0 -column 0 -sticky news
    	grid columnconfigure $itk_interior 0 -weight 1
    	grid rowconfigure $itk_interior 0 -weight 1

		# set up mouse click and drag bindings
		bind $itk_component(canvas) <Button-1> \
			 "$this clickHandler %x %y"
		bind $itk_component(canvas) <B1-Motion> \
			 "$this clickHandler %x %y"
		
		bind $itk_component(canvas) <Configure> \
			 [list $this handleResize]

		# get configuration options
		eval itk_initialize $args
		
		::mediator announceExistence $this
	}

	destructor { 
        if {$m_xWidget != ""} {
	        ::mediator unregister $this $m_xWidget -value
        }
        if {$m_yWidget != ""} {
	        ::mediator unregister $this $m_yWidget -value
        }
        if {$m_zWidget != ""} {
	        ::mediator unregister $this $m_zWidget -value
        }
        if {$m_bWidget != ""} {
	        ::mediator unregister $this $m_bWidget -value
        }
        if {$m_eWidget != ""} {
	        ::mediator unregister $this $m_eWidget -value
        }
    }
}


configbody DCS::DetectorFace::detectorXWidget {
    if {$m_xWidget != ""} {
	    ::mediator unregister $this $m_xWidget -value
    }

	if {$itk_option(-detectorXWidget) != ""} {
	    ::mediator register $this ::$itk_option(-detectorXWidget) \
        -value handleUpdateFromX
    }
    set m_xWidget ::$itk_option(-detectorXWidget)
}

configbody DCS::DetectorFace::detectorYWidget {
    if {$m_yWidget != ""} {
	    ::mediator unregister $this $m_yWidget -value
    }

	if {$itk_option(-detectorYWidget) != ""} {
	    ::mediator register $this ::$itk_option(-detectorYWidget) \
        -value handleUpdateFromY
    }
    set m_yWidget ::$itk_option(-detectorYWidget)
}

configbody DCS::DetectorFace::detectorZWidget {
    if {$m_zWidget != ""} {
	    ::mediator unregister $this $m_zWidget -value
    }

	if {$itk_option(-detectorZWidget) != ""} {
	    ::mediator register $this ::$itk_option(-detectorZWidget) \
        -value handleUpdateFromZ
    }
    set m_zWidget ::$itk_option(-detectorZWidget)
}

configbody DCS::DetectorFace::beamstopXWidget {
        if {$itk_option(-beamstopXWidget) == ""} return

        ::mediator register $this ::$itk_option(-beamstopXWidget) -value handleUpdateFromBH
}

configbody DCS::DetectorFace::beamstopYWidget {
        if {$itk_option(-beamstopYWidget) == ""} return

        ::mediator register $this ::$itk_option(-beamstopYWidget) -value handleUpdateFromBV
}

configbody DCS::DetectorFace::beamstopZWidget {
    if {$m_bWidget != ""} {
	    ::mediator unregister $this $m_bWidget -value
    }

	if {$itk_option(-beamstopZWidget) != ""} {
	    ::mediator register $this ::$itk_option(-beamstopZWidget) \
        -value handleUpdateFromB
    }
    set m_bWidget ::$itk_option(-beamstopZWidget)
}

configbody DCS::DetectorFace::energyWidget {
    if {$m_eWidget != ""} {
	    ::mediator unregister $this $m_eWidget -value
    }

	if {$itk_option(-energyWidget) != ""} {
	    ::mediator register $this ::$itk_option(-energyWidget) \
        -value handleUpdateFromE
    }
    set m_eWidget ::$itk_option(-energyWidget)
}

body DCS::DetectorFace::handleUpdateFromX { object_ targetReady_ - value_ -} {

	if { !$targetReady_ } { return}

	foreach {value units} $value_ break;

	set value [$object_ convertUnits $value $units mm]

	configure -detectorXInMM $value
	
	updateDetectorGraphicsAsync
}

body DCS::DetectorFace::handleUpdateFromY { object_ targetReady_ - value_ -} {

	if { !$targetReady_ } { return}

	foreach {value units} $value_ break; 
	set value [$object_ convertUnits $value $units mm]

	configure -detectorYInMM $value

	updateDetectorGraphicsAsync
}

body DCS::DetectorFace::handleUpdateFromZ { object_ targetReady_ - value_ -} {
	
	if { !$targetReady_ } { return}
	
	foreach {value units} $value_ break; 
	set value [$object_ convertUnits $value $units mm]

	configure -detectorZInMM $value

	updateDetectorGraphicsAsync
}

body DCS::DetectorFace::handleUpdateFromB { object_ targetReady_ - value_ -} {
	
	if { !$targetReady_ } { return}
	
	foreach {value units} $value_ break; 
	set value [$object_ convertUnits $value $units mm]

	configure -beamstopZInMM $value

	updateDetectorGraphicsAsync
}

body DCS::DetectorFace::handleUpdateFromBH { object_ targetReady_ - value_ -} {

        if { !$targetReady_ } { return}

        foreach {value units} $value_ break;
        set value [$object_ convertUnits $value $units mm]

        #configure -beamstopXInMM $value

        updateDetectorGraphicsAsync
}

body DCS::DetectorFace::handleUpdateFromBV { object_ targetReady_ - value_ -} {

        if { !$targetReady_ } { return}

        foreach {value units} $value_ break;
        set value [$object_ convertUnits $value $units mm]

        #configure -beamstopYInMM $value

        updateDetectorGraphicsAsync
}

body DCS::DetectorFace::handleUpdateFromE { object_ targetReady_ - value_ -} {
	
	if { !$targetReady_ } { return }
	
	foreach {value units} $value_ break;
	set value [$object_ convertUnits $value $units eV]

	configure -beamEnergy $value
	
	updateDetectorGraphicsAsync
}


body DCS::DetectorFace::updateDetectorGraphicsAsync {} {
	
	incr updateOutstanding 
		
	if { $updateOutstanding == 1 } {

		after idle $this handleAsyncUpdate
	}
}


body DCS::DetectorFace::handleAsyncUpdate {} {

#	log_note "Resolution aggregation = $updateOutstanding"
	set updateOutstanding 0
	updateDetectorGraphics
}


body DCS::DetectorFace::calculateDetectorParameters {} {

	# convert detector coordinates from mm to pixels
	set detectorXInPixels [expr $itk_option(-detectorXInMM) * $pixelsPerMM]
	set detectorYInPixels [expr $itk_option(-detectorYInMM) * $pixelsPerMM]

	# calculate detector offset distance in mm and pixels
	set detectorOffsetInMM [expr sqrt(($itk_option(-detectorXInMM)*$itk_option(-detectorXInMM))+($itk_option(-detectorYInMM)*$itk_option(-detectorYInMM)))]
	set detectorOffsetInPixels [expr $detectorOffsetInMM * $pixelsPerMM]
	
	# calculate angle of detector offset from beam and vice versa
	if { $detectorOffsetInMM > 1 } {
		set detectorOffsetAngle [expr atan2($itk_option(-detectorYInMM), $itk_option(-detectorXInMM))]
		set beamOffsetAngle [expr atan2(-$itk_option(-detectorYInMM), $itk_option(-detectorXInMM)) + acos(-1)]
	} else {
		set detectorOffsetAngle 0.0
		set beamOffsetAngle 0.0
	}
}


#redraw for any of the following reasons.
configbody DCS::DetectorFace::detectorXInMM { updateDetectorGraphics }
configbody DCS::DetectorFace::detectorYInMM { updateDetectorGraphics }
configbody DCS::DetectorFace::detectorZInMM { updateDetectorGraphics }
configbody DCS::DetectorFace::beamEnergy { updateDetectorGraphics }
configbody DCS::DetectorFace::maxRingSizeInPixels { updateDetectorGraphics }
configbody DCS::DetectorFace::minRingSizeInPixels { updateDetectorGraphics }
configbody DCS::DetectorFace::minRingGapInPixels { updateDetectorGraphics }

body DCS::DetectorFace::clickHandler { clickX clickY } {

	# convert clicked pixel coordinates to detector coordinates in mm
	set clickXInMM [expr ($clickX - $canvasOriginX) / $pixelsPerMM ]
	set clickYInMM [expr ($clickY - $canvasOriginY) / $pixelsPerMM ]

	# call the registered event handler if define
	if { $itk_option(-onClick) != "" } {
		eval $itk_option(-onClick) $clickXInMM $clickYInMM
	}
}



body DCS::DetectorFace::handleResize { } {

   calcPixelsPerMM
   updateDetectorGraphics
}

body DCS::DetectorFace::calcPixelsPerMM {} {
	# query and store new image size
	set width [winfo width $itk_component(canvas)]
	set height [winfo height $itk_component(canvas)]

   set border 60
	
   set conservativeSizeX  [expr double ($width -$border)]
   set conservativeSizeY  [expr double ($height -$border)]

   if {$conservativeSizeX <= 0} return
   if {$conservativeSizeY <= 0} return

   if {$width > $height} {
      set pixelsPerMM [expr $conservativeSizeY / double($itk_option(-detectorWidthInMM)) ]
   } else {
      set pixelsPerMM [expr $conservativeSizeX / double($itk_option(-detectorHeightInMM))]
   }

	set canvasOriginX [expr $width / 2]
	set canvasOriginY [expr $height / 2]
}


body DCS::DetectorFace::drawResolutionRing { ringRadiusInMM {fill 0} } {

	# get ring radius in units of pixels
	set ringRadiusInPixels [expr $ringRadiusInMM * $pixelsPerMM]
	
	# draw the ring if scaled radius is reasonable
	if { $ringRadiusInPixels > $itk_option(-minRingSizeInPixels) && $ringRadiusInPixels < $itk_option(-maxRingSizeInPixels) } {
		
        if {$fill} {
		    $itk_component(canvas) create oval \
			 [expr $canvasOriginX + $detectorXInPixels - $ringRadiusInPixels] \
			 [expr $canvasOriginY + $detectorYInPixels - $ringRadiusInPixels] \
			 [expr $canvasOriginX + $detectorXInPixels + $ringRadiusInPixels] \
			 [expr $canvasOriginY + $detectorYInPixels + $ringRadiusInPixels] \
             -fill \#606060 \
			 -tags rings \
			 -outline red
        } else {
		    $itk_component(canvas) create oval \
			 [expr $canvasOriginX + $detectorXInPixels - $ringRadiusInPixels] \
			 [expr $canvasOriginY + $detectorYInPixels - $ringRadiusInPixels] \
			 [expr $canvasOriginX + $detectorXInPixels + $ringRadiusInPixels] \
			 [expr $canvasOriginY + $detectorYInPixels + $ringRadiusInPixels] \
			 -tags rings \
			 -outline red
        }
	}
}


body DCS::DetectorFace::drawResolutionArc { ringRadiusInMM angleAtMidpoint } {

	# get ring radius in units of pixels
	set ringRadiusInPixels [expr $ringRadiusInMM * $pixelsPerMM]

	# calculate angular start of arc in degrees
	set startingAngle [expr $angleAtMidpoint * 180.0 / acos(-1) - 20 ]

	# draw the arc if scaled radius is reasonable
	if { $ringRadiusInPixels > $itk_option(-minRingSizeInPixels) && $ringRadiusInPixels < $itk_option(-maxRingSizeInPixels) } {
		
		$itk_component(canvas) create arc \
			 [expr $canvasOriginX + $detectorXInPixels - $ringRadiusInPixels] \
			 [expr $canvasOriginY + $detectorYInPixels - $ringRadiusInPixels] \
			 [expr $canvasOriginX + $detectorXInPixels + $ringRadiusInPixels] \
			 [expr $canvasOriginY + $detectorYInPixels + $ringRadiusInPixels] \
			 -start $startingAngle \
			 -extent 40 \
			 -style arc \
			 -outline red \
			 -tags rings
	}
}


body DCS::DetectorFace::drawResolutionText { x y ringRadiusInMM } { 

	if { $itk_option(-detectorZInMM) > 0 && $itk_option(-beamEnergy) > 0 } {
		
		# calculate the resolution of the ring from its radius
		set twoTheta [expr atan($ringRadiusInMM / $itk_option(-detectorZInMM)) ]
		set wavelength [expr 12398.0 / $itk_option(-beamEnergy) ]
		set dSpacing [expr $wavelength / (2*sin($twoTheta/2.0))]

		# draw the resolution text on the canvas
		$itk_component(canvas) create text $x $y \
			 -text [format "%.2f A" $dSpacing] \
			 -font $itk_option(-resolutionFont) \
			 -tags rings
	}
}

body DCS::DetectorFace::drawDirectBeamMark {} {

	# redraw the beam point with a radius of 1 pixel
	drawResolutionRing [expr 1.0 / $pixelsPerMM]
}

body DCS::DetectorFace::drawBeamstopRing {} {
    if {[isFloat $itk_option(-beamstopZInMM)] && \
    [isFloat $itk_option(-detectorZInMM)] && \
    $itk_option(-beamstopZInMM) != 0} {
        set radius [expr $itk_option(-detectorZInMM) * 0.8 / $itk_option(-beamstopZInMM)]

        set text_x [expr $canvasOriginX + $detectorXInPixels]

        set text_y [expr $canvasOriginY + $detectorYInPixels - \
        $radius * $pixelsPerMM - 4]

	    drawResolutionRing $radius 1
        drawResolutionText $text_x $text_y $radius
    }
}

body DCS::DetectorFace::clearCanvas {} {

	# erase the circular detector face and the resolution rings
	$itk_component(canvas) delete detector
	$itk_component(canvas) delete rings
}


body DCS::DetectorFace::updateDetectorGraphics {} {
	
	if { [isFloat $itk_option(-detectorXInMM)] \
				&& [isFloat $itk_option(-detectorYInMM)] \
				&& [isFloat $itk_option(-detectorZInMM)] } {
		
		# calculate characteristics of detector
		calculateDetectorParameters
		
		# erase the detector and resolution rings
		clearCanvas

		# draw the detector face
		drawDetector
		
        # draw beam stop shadow
		drawBeamstopRing

		# draw the direct beam point
		drawDirectBeamMark

		# draw resolution rings
		drawResolutionRings
	}
}
	
############################################

class DCS::DetectorShapeOverlay {
	# inherit from the generic detector
	inherit ::DCS::DetectorFace

	# extra public data for circular detectors
	itk_option define -detectorRadiusInMM detectorRadius DetectorRadius 150.0
	itk_option define -shape shape Shape circular

	# protected member data
	protected variable detectorRadiusInPixels

	# protected helper methods
	protected method getResolutionTextCoordinates
	protected method getCornerRing
	protected method drawOppositeCornerArc
	protected method getResolutionRings

	# overridden member functions
	protected method drawDetector
	protected method drawResolutionRings
	protected method calculateDetectorParameters

	# extra public data for rectangular detectors
	itk_option define -detectorWidthInMM detectorWidthInMM DetectorWidthInMM		186
	itk_option define -detectorHeightInMM detetorHeightInMM DetectorHeightInMM		186
	itk_option define -moduleNumber moduleNumber ModuleNumber			4

	# protected member data
	protected variable detectorWidthInPixels
	protected variable detectorHeightInPixels
	protected variable detectorHalfWidthInPixels
	protected variable detectorHalfHeightInPixels

	# constructor just calls base class constructor
	constructor { args } { 
		#puts $args
		#eval DCS::DetectorFace::constructor $args
		#updateDetectorGraphics
	} {
		eval itk_initialize $args
	}
}


configbody DCS::DetectorShapeOverlay::detectorRadiusInMM {

	if {[isFloat $itk_option(-detectorRadiusInMM)] && $itk_option(-detectorRadiusInMM) > 0} {
		updateDetectorGraphics
	}
}


body DCS::DetectorShapeOverlay::calculateDetectorParameters {} {

	# call base class function
	DCS::DetectorFace::calculateDetectorParameters
	
	switch $itk_option(-shape) {

		circular {
			# convert detector radius from mm to pixels
			set detectorRadiusInPixels [expr $itk_option(-detectorRadiusInMM) * $pixelsPerMM]
		}
		
		rectangular {
			# precalculate detector parameters
			set detectorWidthInPixels [expr $pixelsPerMM * $itk_option(-detectorWidthInMM) ]
			set detectorHeightInPixels  [expr $pixelsPerMM * $itk_option(-detectorHeightInMM) ]
			set detectorHalfWidthInPixels [ expr $detectorWidthInPixels / 2 ]
			set detectorHalfHeightInPixels  [ expr $detectorHeightInPixels / 2 ]			
		}
	}
}


body DCS::DetectorShapeOverlay::drawDetector {} {

	switch $itk_option(-shape) {
		
		circular {

			# draw the detector face if not too large
			if { $detectorRadiusInPixels < $itk_option(-maxRingSizeInPixels) } {
				
				$itk_component(canvas) create oval \
					 [expr $canvasOriginX - $detectorRadiusInPixels ] \
					 [expr $canvasOriginY - $detectorRadiusInPixels ] \
					 [expr $canvasOriginX + $detectorRadiusInPixels ] \
					 [expr $canvasOriginY + $detectorRadiusInPixels ] \
					 -fill $itk_option(-detectorForeground) \
					 -tags detector
			}
		}

		rectangular {
			# draw the detector face
			$itk_component(canvas) create poly  \
				 [expr $canvasOriginX - $detectorHalfWidthInPixels  ] \
				 [expr $canvasOriginY - $detectorHalfHeightInPixels ] \
				 [expr $canvasOriginX + $detectorHalfWidthInPixels  ] \
				 [expr $canvasOriginY - $detectorHalfHeightInPixels ] \
				 [expr $canvasOriginX + $detectorHalfWidthInPixels  ] \
				 [expr $canvasOriginY + $detectorHalfHeightInPixels ] \
				 [expr $canvasOriginX - $detectorHalfWidthInPixels  ] \
				 [expr $canvasOriginY + $detectorHalfHeightInPixels ] \
				 -fill $itk_option(-detectorForeground) \
				 -tags detector \
				 -outline black \
				 -width 1
			

         set numOfLines [expr sqrt( $itk_option(-moduleNumber) ) ]
         set moduleWidthInPixels [expr $detectorHeightInPixels / $numOfLines ]
         set originX [expr $canvasOriginX - $detectorWidthInPixels / 2 ]
         set originY [expr $canvasOriginY - $detectorHeightInPixels / 2 ]

         for {set i 1} { $i < $numOfLines } {incr i} {
   		   # draw the module lines
				# draw horizontal line
				$itk_component(canvas) create line \
						 [expr $originX ] \
						 [expr $originY + $moduleWidthInPixels * $i ] \
						 [expr $originX + $detectorWidthInPixels ] \
						 [expr $originY + $moduleWidthInPixels * $i ] \
						 -tags detector \
						 -fill grey
					
				# draw horizontal line
				$itk_component(canvas) create line \
						 [expr $originX + $moduleWidthInPixels * $i ] \
						 [expr $originY ] \
						 [expr $originX + $moduleWidthInPixels * $i ] \
						 [expr $originY + $detectorHeightInPixels ] \
						 -tags detector \
						 -fill grey
			}
		}
	}
}

body DCS::DetectorShapeOverlay::drawResolutionRings {} {

	switch $itk_option(-shape) {
		
		circular {


			# calculate distance between beam center and edge of detector
			set signedBeamToDetectorEdge [expr $itk_option(-detectorRadiusInMM) - $detectorOffsetInMM]
			set beamToDetectorEdge [expr abs($signedBeamToDetectorEdge)]
			
			# draw inner resolution ring if beam far enough from edge of detector
			if { [expr abs( $detectorOffsetInPixels - $detectorRadiusInPixels)] > 10} {
				
				# draw the ring itself
				drawResolutionRing $beamToDetectorEdge
				
				# draw the resolution text
				drawResolutionText \
					 [expr $canvasOriginX + $detectorRadiusInPixels * cos($detectorOffsetAngle) ] \
					 [expr $canvasOriginY + $detectorRadiusInPixels * sin($detectorOffsetAngle) ] \
					 $beamToDetectorEdge
			}

			# draw and label outer resolution arc if beam far enough from center of detector
			if { $detectorOffsetInPixels > 2 } {
				
				# calculate radius of arc
				set arcRadius [expr 2.0 * $itk_option(-detectorRadiusInMM) - $signedBeamToDetectorEdge]
				
				# draw the arc
				drawResolutionArc $arcRadius $beamOffsetAngle
				
				# draw the resolution text
				drawResolutionText \
					 [expr $canvasOriginX + $detectorXInPixels + \
							$arcRadius * $pixelsPerMM * cos($beamOffsetAngle)] \
					 [expr $canvasOriginY + $detectorYInPixels - \
							$arcRadius * $pixelsPerMM * sin($beamOffsetAngle)] \
					 $arcRadius
			}
		}

		rectangular {
			# redraw inside full circle & set resolution
			set ringList [getResolutionRings]
	
			set radius 0
			
			foreach ring $ringList {

				set radius [lindex $ring 0]
				set textX [lindex $ring 1]
				set textY [lindex $ring 2]
				
				drawResolutionRing $radius
				drawResolutionText $textX $textY $radius 
			}
			
			drawOppositeCornerArc $radius
		}
	}
}


body DCS::DetectorShapeOverlay::getResolutionRings {} {
	
	# calculate the four distances from the beam center to the detector edges
	set left "[expr abs($itk_option(-detectorXInMM) + $itk_option(-detectorWidthInMM) / 2.0)] left"
	set top  "[expr abs($itk_option(-detectorYInMM) + $itk_option(-detectorHeightInMM) / 2.0 )] top"
	set right  "[expr abs($itk_option(-detectorXInMM) - $itk_option(-detectorWidthInMM)  / 2.0 )] right" 
	set bottom "[expr abs($itk_option(-detectorYInMM) - $itk_option(-detectorHeightInMM) / 2.0 )] bottom" 
	
	# make a sorted list of the distances
	set edgeList [lsort -index 0 -real [list $left $top $right $bottom]]
	
	# initialize a pruned list of radii
	set textVisibleList {}

	# eliminate rings not tangent to actual edges of detector
	foreach edge $edgeList {
		
		set radius [lindex $edge 0]
		set position [lindex $edge 1]

		set ringVisibleResult [getResolutionTextCoordinates $position $radius]
		set ringVisible [lindex $ringVisibleResult 0]

		if { $ringVisible } {

			set x [lindex $ringVisibleResult 1]
			set y [lindex $ringVisibleResult 2]
			lappend textVisibleList [list $radius $x $y]
		} 
	}
	
	# calculate corner ring if no tangent rings
	if { $textVisibleList == {} } {
		set textVisibleList [list [getCornerRing]]
	}

	set lastRadius 0.0

	# initialize a pruned list of radii
	set ringVisibleList {}

	# eliminate rings too close to the edge or to each other
	foreach edge $textVisibleList {
		
		set radius [lindex $edge 0]

		if { abs($radius - $lastRadius) > $itk_option(-minRingGapInPixels) / $pixelsPerMM } {
			lappend ringVisibleList $edge
			set lastRadius $radius
		} 
	}

	return $ringVisibleList
}


body DCS::DetectorShapeOverlay::drawOppositeCornerArc { largestRingRadius } {
		
	# handle top left corner
	if { $itk_option(-detectorXInMM) <= 0 && $itk_option(-detectorYInMM) <= 0 } { 
		set x [expr $canvasOriginX + $detectorWidthInPixels/2]
		set y [expr $canvasOriginY + $detectorHeightInPixels/2]
	}
	
	# handle top right corner
	if { $itk_option(-detectorXInMM) >= 0 && $itk_option(-detectorYInMM) <= 0 } { 
		set x [expr $canvasOriginX - $detectorWidthInPixels/2]
		set y [expr $canvasOriginY + $detectorHeightInPixels/2]
	}
	
	# handle bottom left corner
	if { $itk_option(-detectorXInMM) <= 0 && $itk_option(-detectorYInMM) >= 0 } { 
		set x [expr $canvasOriginX + $detectorWidthInPixels/2]
		set y [expr $canvasOriginY - $detectorHeightInPixels/2]
	}
	
	# handle bottom right corner
	if { $itk_option(-detectorXInMM) >= 0 && $itk_option(-detectorYInMM) >= 0 } { 
		set x [expr $canvasOriginX - $detectorWidthInPixels/2]
		set y [expr $canvasOriginY - $detectorHeightInPixels/2]
	}
	
	set deltaX [expr $x - $detectorXInPixels - $canvasOriginX]
	set deltaY [expr $y - $detectorYInPixels - $canvasOriginY]
	set radius [expr sqrt( ($deltaX * $deltaX) + ($deltaY * $deltaY) ) / $pixelsPerMM ]
	
	if { $radius - $largestRingRadius > $itk_option(-minRingGapInPixels) } {
		set angle [expr atan2(-$deltaY, $deltaX)]
		drawResolutionArc $radius $angle
		drawResolutionText $x $y $radius
	}
}


body DCS::DetectorShapeOverlay::getCornerRing {} {

	# handle top left corner
	if { $itk_option(-detectorXInMM) < 0 && $itk_option(-detectorYInMM) < 0 } { 
		set x [expr $canvasOriginX - $detectorWidthInPixels/2]
		set y [expr $canvasOriginY - $detectorHeightInPixels/2]
	}
	
	# handle top right corner
	if { $itk_option(-detectorXInMM) > 0 && $itk_option(-detectorYInMM) < 0 } { 
		set x [expr $canvasOriginX + $detectorWidthInPixels/2]
		set y [expr $canvasOriginY - $detectorHeightInPixels/2]
	}
	
	# handle bottom left corner
	if { $itk_option(-detectorXInMM) < 0 && $itk_option(-detectorYInMM) > 0 } { 
		set x [expr $canvasOriginX - $detectorWidthInPixels/2]
		set y [expr $canvasOriginY + $detectorHeightInPixels/2]
	}
	
	# handle bottom right corner
	if { $itk_option(-detectorXInMM) > 0 && $itk_option(-detectorYInMM) > 0 } { 
		set x [expr $canvasOriginX + $detectorWidthInPixels/2]
		set y [expr $canvasOriginY + $detectorHeightInPixels/2]
	}
	
	set deltaX [expr $x - $detectorXInPixels - $canvasOriginX]
	set deltaY [expr $y - $detectorYInPixels - $canvasOriginY]
	set radius [expr sqrt( ($deltaX * $deltaX) + ($deltaY * $deltaY) ) / $pixelsPerMM ]
	
	return [list $radius $x $y]
}


body DCS::DetectorShapeOverlay::getResolutionTextCoordinates { position ringRadiusInMM } {

	set ringVisible 0

	switch $position {

		left {
			set x [expr $canvasOriginX - $detectorWidthInPixels / 2.0]
			set y [expr $canvasOriginY + $detectorYInPixels]
			if { abs($canvasOriginY - $y) < $detectorHeightInPixels/2 } {
				set ringVisible 1
			}
		}

		right {
			set x [expr $canvasOriginX + $detectorWidthInPixels / 2.0]
			set y [expr $canvasOriginY + $detectorYInPixels]
			if { abs($canvasOriginY - $y) < $detectorHeightInPixels/2.0 } {
				set ringVisible 1
			}
		}

		top {
			set x [expr $canvasOriginX + $detectorXInPixels]
			set y [expr $canvasOriginY - $detectorHeightInPixels / 2.0]
			if { abs($canvasOriginX - $x) < $detectorWidthInPixels/2.0 } {
				set ringVisible 1
			}
		}

		bottom {
			set x [expr $canvasOriginX + $detectorXInPixels]
			set y [expr $canvasOriginY + $detectorHeightInPixels / 2.0]
			if { abs($canvasOriginX - $x) < $detectorWidthInPixels/2.0 } {
				set ringVisible 1
			}
		}
	}

	return "$ringVisible $x $y"
}


configbody DCS::DetectorShapeOverlay::detectorWidthInMM {

	if {[isFloat $itk_option(-detectorWidthInMM)] && $itk_option(-detectorWidthInMM) > 0} {
		updateDetectorGraphics
	}
}


configbody DCS::DetectorShapeOverlay::detectorHeightInMM {

	if {[isFloat $itk_option(-detectorHeightInMM)] && $itk_option(-detectorHeightInMM) > 0} {
		updateDetectorGraphics
	}
}


configbody DCS::DetectorShapeOverlay::moduleNumber {
	
	if {$itk_option(-moduleNumber) == 1 || $itk_option(-moduleNumber) == 4 || $itk_option(-moduleNumber) == 9} {
		updateDetectorGraphics
	}
}



class DCS::ResolutionWidget {
	inherit DCS::DetectorShapeOverlay


	itk_option define -deviceNamespace deviceNamespace DeviceNamespace ::device
	itk_option define -detectorType detectorType DetectorType Q210CCD
	itk_option define -detectorHorzDevice detectorHorzDevice DetectorHorzDevice ""
	itk_option define -detectorVertDevice detectorVertDevice DetectorVertDevice ""
    itk_option define -externalModeWidget externalModeWidget ExternalModeWidget ""
	
	public method handleDetectorTypeChange
	# protected methods
	public method changeMode { args }

    public method setMode { index } {
        set modeWidget $itk_option(-externalModeWidget)
        if {$modeWidget == ""} {
            set modeWidget $itk_component(detectorMode)
        }

        set currentIndex [$modeWidget selectDetectorMode]
        if {$index == $currentIndex} {
            puts "DEBUG: skip setMode, no change"
            return
        }
        puts "RESOLUTION mode: current=$currentIndex new=$index"
        if {[catch {
            $modeWidget setValueByIndex $index
        } errMsg]} {
            puts "failed to setMode: $errMsg"
        }
    }

    private method showModeWidget { } {
	    if {$itk_option(-detectorType) == "MAR345" && \
        $itk_option(-externalModeWidget) == ""} {
	        grid $itk_component(detectorMode) -row 1 -column 0
        } else {
	        grid forget $itk_component(detectorMode)
	    }
    }
	
	# public methods
	public method handleResolutionClick

   private variable _detectorObject
   private variable m_lastExternalModeWidget ""


	constructor { args } {

   	# make the detector mode entry
	   itk_component add detectorMode {
			DCS::DetectorModeMenu $itk_interior.dm -entryWidth 19 \
				 -promptText "Detector: " \
				 -promptWidth 12 \
				 -showEntry 0 \
				 -entryType string \
				 -entryJustify center \
				 -promptText "Mode: " \
				 -shadowReference 0 \
             -systemIdleOnly 0 \
				 -activeClientOnly 0
		 } {
				 keep -font
		 }

      $itk_component(detectorMode) configure -onSubmit "$this changeMode"


		#create on object for watching the detector
		set _detectorObject [DCS::Detector::getObject]
      eval itk_initialize $args
		::mediator register $this ::$_detectorObject type handleDetectorTypeChange


      #uncomment follow to enable click
		#configure -onClick "$this handleResolutionClick"
	}
    destructor {
        if {$m_lastExternalModeWidget != ""} {
            #### may be already deleted.
            catch {
                $m_lastExternalModeWidget unregister $this -value changeMode
            }
        }
    }
}

configbody DCS::ResolutionWidget::externalModeWidget {
    if {$m_lastExternalModeWidget != ""} {
        $m_lastExternalModeWidget unregister $this -value changeMode
    }
    showModeWidget
    set m_lastExternalModeWidget $itk_option(-externalModeWidget)
    if {$m_lastExternalModeWidget != "" } {
        $m_lastExternalModeWidget register $this -value changeMode
    }
}

configbody DCS::ResolutionWidget::detectorType {
    showModeWidget

   $itk_component(detectorMode) setValueByIndex [$_detectorObject getDefaultModeIndex] 1

   configure -shape [$_detectorObject getShape]
   configure -moduleNumber [$_detectorObject getModules]

   changeMode
}

body DCS::ResolutionWidget::changeMode { args } {
    if {[llength $args] > 2 && ![lindex $args 1]} {
        #not ready
        return
    }

    set modeWidget $itk_option(-externalModeWidget)
    if {$modeWidget == ""} {
        set modeWidget $itk_component(detectorMode)
    }

    set size [$_detectorObject getModeSizes [$modeWidget get]]

    if {$size == ""} {
        return
    }

	configure -detectorRadiusInMM	[expr $size / 2.0]
	configure -detectorWidthInMM $size
	configure -detectorHeightInMM $size
   handleResize
}


body DCS::ResolutionWidget::handleResolutionClick { x y } {

	if { $itk_option(-deviceNamespace) == ""} return

	set deviceNamespace $itk_option(-deviceNamespace)

	# get current limits on detector position.  drop units, assuming mm
	set horzUpperLimit [lindex [ $itk_option(-detectorHorzDevice) getEffectiveUpperLimit] 0]
	set horzLowerLimit [lindex [ $itk_option(-detectorHorzDevice) getEffectiveLowerLimit] 0]
	set vertUpperLimit [lindex [ $itk_option(-detectorVertDevice) getEffectiveUpperLimit] 0]
	set vertLowerLimit [lindex [ $itk_option(-detectorVertDevice) getEffectiveLowerLimit] 0]

	# enforce upper limit on horz
	if { $x > $horzUpperLimit } { 
		set x $horzUpperLimit
		#log_warning "Selected detector position exceeds upper limit on horizontal travel."
	}

	# enforce lower limit on horz
	if { $x < $horzLowerLimit } { 
		set x $horzLowerLimit 
		#log_warning "Selected detector position exceeds lower limit on horizontal travel."
	}

	# enforce upper limit on vert
	if { $y > $vertUpperLimit } { 
		set y $vertUpperLimit 
		#log_warning "Selected detector position exceeds upper limit on vertical travel."
	}

	# enforce lower limit on vert
	if { $y < $vertLowerLimit } { 
		set y $vertLowerLimit 
		#log_warning "Selected detector position exceeds lower limit on vertical travel."
	}

	# set detector x and y widgets to reflect the clicked position
	$itk_option(-detectorXWidget) setValue $x
	$itk_option(-detectorYWidget) setValue $y
}


body DCS::ResolutionWidget::handleDetectorTypeChange { detector_ targetReady_ alias_ type_ -  } {

	if { ! $targetReady_} return

	configure -detectorType $type_
}


class DCS::ResolutionControlWidget {
 	inherit ::itk::Widget

	itk_option define -deviceNamespace deviceNamespace DeviceNamespace ::device
	itk_option define -mdiHelper mdiHelper MdiHelper ""


	public method destructor
   private variable m_deviceFactory

	constructor { args } {
        global gMotorDistance

      set m_deviceFactory [DCS::DeviceFactory::getObject]
   
		itk_component add control {
			::DCS::MotorControlPanel $itk_interior.control -width 8 -orientation "horizontal" -ipadx 8 -ipady 5 -buttonBackground #c0c0ff -activeButtonBackground #c0c0ff
		} { 
		}

		# create canvas
		itk_component add resolution {
			DCS::ResolutionWidget $itk_interior.res \
				 -detectorBackground lightblue \
				 -detectorForeground white
		} {
			keep -detectorBackground -detectorForeground
			keep -detectorHorzDevice -detectorVertDevice
		}

      itk_component add motorFrame {
         frame $itk_interior.mf
      } {}

		itk_component add detectorYWidget {
			::DCS::TitledMotorEntry $itk_component(motorFrame).detector_vert \
				 -labelText "Vertical"  -unitsList default \
				 -menuChoiceDelta 25  -units mm -unitsWidth 4 \
				 -entryWidth 10
		} {
			keep -activeClientOnly
            keep -systemIdleOnly
            keep -honorStatus
			keep -mdiHelper
			rename -device detectorVertDevice detectorVertDevice DetectorVertDevice
		}

		itk_component add detectorZWidget {
			# create motor view for detector_z
			::DCS::TitledMotorEntry $itk_component(motorFrame).detector_z_corr \
				 -labelText "Distance" -unitsList default \
             -menuChoiceDelta 50 \
				 -entryType positiveFloat -units mm -unitsWidth 4 \
				 -entryWidth 10 \
                 -device [$m_deviceFactory getObjectName $gMotorDistance]
		} {
			keep -activeClientOnly
            keep -systemIdleOnly
            keep -honorStatus
			keep -mdiHelper
		}

		itk_component add detectorXWidget {
			# create motor view for detector_horz
			::DCS::TitledMotorEntry $itk_component(motorFrame).detector_horz \
				 -unitsList default \
	          -menuChoiceDelta 25 \
				 -labelText "Horizontal" -units mm -unitsWidth 4 \
				 -entryWidth 10
		} {
			keep -activeClientOnly
            keep -systemIdleOnly
            keep -honorStatus
			keep -mdiHelper
			rename -device detectorHorzDevice detectorHorzDevice DetectorHorzDevice
		}

		itk_component add energyWidget {
			# create motor view for detector_horiz
			::DCS::TitledMotorEntry $itk_component(motorFrame).energy \
				 -entryWidth 10 \
				 -autoGenerateUnitsList 0 \
            -unitsList {A {-decimalPlaces 5 -menuChoiceDelta 0.1} eV {-decimalPlaces 3 -menuChoiceDelta 1000} keV {-decimalPlaces 6 -menuChoiceDelta 1.0}} \
				 -unitsWidth 4 \
				 -units eV 
		} {
			keep -activeClientOnly
            keep -systemIdleOnly
            keep -honorStatus
			keep -mdiHelper
			rename -device energyDevice energyDevice EnergyDevice
		}

		itk_component add beamstopZWidget {
			# create motor view for beamstop_z
			::DCS::TitledMotorEntry $itk_component(motorFrame).beamstop_z \
				 -labelText "Beamstop" -unitsList default \
                 		 -menuChoiceDelta 50 \
				 -entryType positiveFloat -units mm -unitsWidth 4 \
				 -entryWidth 10
		} {
			keep -activeClientOnly
            		keep -systemIdleOnly
            		keep -honorStatus
			keep -mdiHelper
			rename -device beamstopDevice beamstopDevice BeamstopDevice
		}

                itk_component add beamstopXWidget {
                        # create motor view for beamstop_z
                        ::DCS::TitledMotorEntry $itk_component(motorFrame).beamstop_horz \
                                 -labelText "Beamstop_horz" -unitsList default \
		                 -menuChoiceDelta 50 \
                                 -entryType positiveFloat -units mm -unitsWidth 4 \
                                 -entryWidth 10
                } {
                        keep -activeClientOnly
            		keep -systemIdleOnly
            		keep -honorStatus
                        keep -mdiHelper
                        rename -device beamstopHorzDevice beamstopHorzDevice BeamstopHorzDevice
                }

                itk_component add beamstopYWidget {
                        # create motor view for beamstop_z
                        ::DCS::TitledMotorEntry $itk_component(motorFrame).beamstop_vert \
                                 -labelText "Beamstop_vert" -unitsList default \
                                 -menuChoiceDelta 50 \
                                 -entryType positiveFloat -units mm -unitsWidth 4 \
                                 -entryWidth 10
                } {
                        keep -activeClientOnly
                        keep -systemIdleOnly
                        keep -honorStatus
                        keep -mdiHelper
                        rename -device beamstopVertDevice beamstopVertDevice BeamstopVertDevice
                }

		# get configuration options
		eval itk_initialize $args
		
		$itk_component(control) registerMotorWidget ::$itk_component(detectorXWidget)
		$itk_component(control) registerMotorWidget ::$itk_component(detectorYWidget)
		$itk_component(control) registerMotorWidget ::$itk_component(detectorZWidget)
		$itk_component(control) registerMotorWidget ::$itk_component(beamstopXWidget)
                $itk_component(control) registerMotorWidget ::$itk_component(beamstopYWidget)
                $itk_component(control) registerMotorWidget ::$itk_component(beamstopZWidget)
		$itk_component(control) registerMotorWidget ::$itk_component(energyWidget)
	

		#let the resolution widget know the names of the motor widgets
		$itk_component(resolution) configure -detectorXWidget $itk_component(detectorXWidget)
		$itk_component(resolution) configure -detectorYWidget $itk_component(detectorYWidget)
		$itk_component(resolution) configure -detectorZWidget $itk_component(detectorZWidget)
		$itk_component(resolution) configure -beamstopXWidget $itk_component(beamstopXWidget)
                $itk_component(resolution) configure -beamstopYWidget $itk_component(beamstopYWidget)
                $itk_component(resolution) configure -beamstopZWidget $itk_component(beamstopZWidget)
		$itk_component(resolution) configure -energyWidget $itk_component(energyWidget)

		
		::mediator announceExistence $this

     grid $itk_component(resolution) -row 0 -column 0 -sticky news
		grid $itk_component(motorFrame) -row 0 -column 1
		grid $itk_component(control)  -row 1 -column 0

    	grid columnconfigure $itk_interior 0 -weight 1
    	grid rowconfigure $itk_interior 0 -weight 1

		grid $itk_component(detectorYWidget) -row 0 -column 0 
		grid $itk_component(detectorXWidget) -row 1 -column 0
		grid $itk_component(detectorZWidget) -row 2 -column 0
                grid $itk_component(beamstopXWidget) -row 3 -column 0
                grid $itk_component(beamstopYWidget) -row 4 -column 0
		grid $itk_component(beamstopZWidget) -row 5 -column 0
		grid $itk_component(energyWidget) -row 6 -column 0
	
	}
}


body DCS::ResolutionControlWidget::destructor {} {
	mediator announceDestruction $this

}



proc testResolution {} {
	
	option add *Entry*activebackground white

	option add *foreground black
	#option add *background lightblue
	
	option add *MotorViewEntry*menuBackground white
	option add *MotorViewEntry*font  "*-helvetica-bold-r-normal--12-*-*-*-*-*-*-*"
	option add *MotorViewEntry*Mismatch  red
	option add *MotorViewEntry*Match  black
	option add *MotorViewEntry*activebackground #c0c0ff
	option add *Entry*activebackground white


	#option add *MotorControlPanel.background #c0c0ff
	option add *Button.background grey widgetDefault
	
	
	option add *Button*foreground red
	option add *Button*activebackground #c0c0ff
	
	option add *MenuEntry*Label*activebackground #c0c0ff
	option add *MenuEntry*Label*background #c0c0ff
	option add *ActiveButton*activeBackground #c0c0ff
	option add *ActiveButton*background #c0c0ff
	
	
	source ../blu-ice/defaultMotors.tcl
	namespace eval ::device createDefaultMotors
	
	catch {load /usr/local/dcs/tcl_clibs/linux64/tcl_clibs.so dcs_c_library}
	source ../blu-ice/defaultMotors.tcl
	#set up a list of default motors
#	namespace eval ::device createDefaultMotors
	
	#create the deviceManager
	
	DCS::DcssUserProtocol dcss smblx5 15242 -_reconnectTime 1000
	::DCS::OperationManager operationManager -deviceNamespace ::device

	dcss connect


	DCS::ResolutionControlWidget .test \
		 -detectorHorzDevice ::device::detector_horz \
		 -detectorVertDevice ::device::detector_vert \
		 -detectorZDevice ::device::detector_z_corr \
		 -beamstopZDevice ::device::beamstop_z \
		 -energyDevice ::device::energy -detectorType Q210CCD
	
	pack .test

	# create the apply button
	::DCS::ActiveButton .activeButton

	pack .activeButton


	after 5000 {.test configure -detectorType Q315CCD}
	after 5000 {.test configure -detectorType Q210CCD}
	after 8000 {.test configure -detectorType MAR345}
	after 12000 {.test configure -detectorType Q4CCD}
	after {3000 } {::mediator printStatus}

	return
}



#testResolution
