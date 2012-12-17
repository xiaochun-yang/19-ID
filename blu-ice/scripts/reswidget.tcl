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


proc res_change_detector_mode {} {
	
	# global variables
	global gReswidget
	global gDefineRun

	# get the current detector mode
	set mode [detectorModeEntry get_value]
	set gReswidget(detectorMode) $mode

	set modeNum [lsearch $gDefineRun(modeChoices) [detectorModeEntry get_value] ]

	# set the size of the detector
	set size [lindex $gDefineRun(modeSizes) $modeNum]

	set gReswidget(diameter) $size
}


proc initialize_reswidget { resolcanvas {detectormodel Q4CCD}  } {

	# global variables
	global gWindows
	global gColors
	global gFont
	global gDevice
	global gCanvas
	global gPhoto
	global gBitmap
	global gButton
	global gSpeedScale
	global joyspeed
	global gReswidget
	global gMenuChoices
	global gSafeEntry
	global gOctantProximity

	#this value tells which edges of the detector are closest
	# edge 1 is upper; edge 2 is right; edge 3 lower; edge 4 left
	set gOctantProximity(8)  {1 4 2 3}
	set gOctantProximity(9)  {1 2 4 3}
	set gOctantProximity(11) {2 1 3 4}
	set gOctantProximity(15) {2 3 1 4}
	set gOctantProximity(7) {3 2 4 1}
	set gOctantProximity(6) {3 4 2 1}
	set gOctantProximity(4) {4 3 1 2}
	set gOctantProximity(0) {4 1 3 2}
	set gOctantProximity(8,corner) 1
	set gOctantProximity(9,corner) 2
	set gOctantProximity(11,corner) 2
	set gOctantProximity(15,corner) 3
	set gOctantProximity(7,corner) 3
	set gOctantProximity(6,corner) 4
	set gOctantProximity(4,corner) 4
	set gOctantProximity(0,corner) 1
	
	#square edge of detector face in mm
	set gReswidget(Xsize,Q4CCD) 188
	set gReswidget(Ysize,Q4CCD) 188
	set gReswidget(Xsize,Q315CCD) 315
	set gReswidget(Ysize,Q315CCD) 315
	set gReswidget(Xsize,MAR345) 345
	set gReswidget(Ysize,MAR345) 345

	set gReswidget(detector_z) 100.0
	set gReswidget(detector_horz) 0
	set gReswidget(detector_vert) 0
	set gReswidget(energy) 12384

	#diameter of detector face in mm
	set gReswidget(diameter) 345

	set gReswidget(resolcanvas) $resolcanvas

	set canvaswidth [lindex [$resolcanvas configure -width] 4]
	set canvasheight [lindex [$resolcanvas configure -height] 4]

	set gReswidget(xDetCenter) [expr $canvaswidth/2]
	set gReswidget(yDetCenter) [expr $canvasheight/2]
	
	if {($detectormodel == "MAR345")} {
		
		#standard conversion factor from millimeters to pixels
		set gReswidget(mm2pix) [expr 150.0/$gReswidget(diameter) ]
		
		set gReswidget(Xsize) $gReswidget(Xsize,$detectormodel) 
		set gReswidget(Ysize) $gReswidget(Ysize,$detectormodel) 		

		set xDetSize [expr int($gReswidget(mm2pix)*double($gReswidget(diameter)))]
		set yDetSize [expr int($gReswidget(mm2pix)*double($gReswidget(diameter)))]
		
		set xDetPos [expr ($canvaswidth-$xDetSize)/2]
		set yDetPos [expr ($canvasheight-$yDetSize)/2]
		
		$resolcanvas create oval $xDetPos $yDetPos \
			[expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize] \
			-fill white -outline $gColors(dark) -tag detectorface
	
		set xBeam [expr $xDetPos+($xDetSize/2)]
		set yBeam [expr $yDetPos+($yDetSize/2)]
		
		$resolcanvas create oval [expr $xBeam-2] [expr $yBeam-2] \
			[expr $xBeam+2] [expr $yBeam+2] -fill red -outline red -tag myoval
		
		$resolcanvas create arc $xDetPos $yDetPos [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize] \
			-extent 359.9 -outline red -width 1 -start 0 -style arc -tag innercircle
		
		$resolcanvas create arc [expr $xDetPos+($xDetSize/2)-sqrt(0.5)*$xDetSize] \
			[expr $yDetPos+($yDetSize/2)-sqrt(0.5)*$yDetSize] \
			[expr $xDetPos+($xDetSize/2)+sqrt(0.5)*$xDetSize] \
			[expr $yDetPos+($yDetSize/2)+sqrt(0.5)*$yDetSize] \
			-extent 60 -outline red -width 1 -start 120 -style arc -tag outerarc
		
		$resolcanvas create text [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize/2] \
			-font $gFont(small) -text "init A" -tag textinner
		
		$resolcanvas create text [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize/2] \
			-font $gFont(small) -text "init A" -tag textarc

		$resolcanvas create text [expr 5] [expr $yDetPos+$yDetSize+20] \
			-font $gFont(tiny) -anchor w -text "MOSFLM" -tag mosflm
		
		adjust_widgetMar_arcs
		
		clearTraces gReswidget(detector_z)
		clearTraces gReswidget(detector_horz)
		clearTraces gReswidget(detector_vert)
		clearTraces gReswidget(energy)
		clearTraces gReswidget(diameter)
		
		trace variable gReswidget(detector_z) w "adjust_widgetMar_arcs"
		trace variable gReswidget(detector_horz) w "adjust_widgetMar_arcs"
		trace variable gReswidget(detector_vert) w "adjust_widgetMar_arcs"
		trace variable gReswidget(energy) w "adjust_widgetMar_arcs"
		trace variable gReswidget(diameter) w "adjust_widgetMar_arcs"
		
		bind $resolcanvas <Button-1> {
			#Note: mouse click gives new det. position rounded off to nearest mm
			detector_horzHorizontal set_value [expr int((double (%x)-$gReswidget(xDetCenter))/$gReswidget(mm2pix))]
			detector_vertVertical set_value   [expr int((double (%y)-$gReswidget(yDetCenter))/$gReswidget(mm2pix))]       	
		}
	} elseif {($detectormodel == "Q4CCD" || $detectormodel == "Q315CCD")} {


		set gReswidget(resolcanvas) $resolcanvas 
		
		set gReswidget(Xsize) $gReswidget(Xsize,$detectormodel) 
		set gReswidget(Ysize) $gReswidget(Ysize,$detectormodel) 

		#standard conversion factor from millimeters to pixels
		set gReswidget(mm2pix) [expr 150.0/$gReswidget(Xsize) ]
		
		set xDetSize [expr int($gReswidget(mm2pix)*double($gReswidget(Xsize)))]
		set yDetSize [expr int($gReswidget(mm2pix)*double($gReswidget(Ysize)))]
		
		set xDetPos [expr ($canvaswidth-$xDetSize)/2]
		set yDetPos [expr ($canvasheight-$yDetSize)/2]
		
		$resolcanvas create rectangle $xDetPos $yDetPos \
			[expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize] \
			-fill white -outline $gColors(dark)
		
		switch $detectormodel {
			"Q4CCD" {
				$resolcanvas create line [expr $xDetPos+$xDetSize/2] $yDetPos \
					[expr $xDetPos+$xDetSize/2] [expr $yDetPos+$yDetSize] -fill gray -width 1
				$resolcanvas create line $xDetPos [expr $yDetPos+$yDetSize/2] \
					[expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize/2]  -fill gray -width 1
			}
			"Q315CCD" {
				$resolcanvas create line [expr $xDetPos+$xDetSize/3] $yDetPos \
					[expr $xDetPos+$xDetSize/3] [expr $yDetPos+$yDetSize] -fill gray -width 1
				$resolcanvas create line $xDetPos [expr $yDetPos+$yDetSize/3] [expr $xDetPos+$xDetSize] \
					[expr $yDetPos+$yDetSize/3]  -fill gray -width 1
				$resolcanvas create line [expr $xDetPos+2*$xDetSize/3] $yDetPos \
					[expr $xDetPos+2*$xDetSize/3] [expr $yDetPos+$yDetSize] -fill gray -width 1
				$resolcanvas create line $xDetPos [expr $yDetPos+2*$yDetSize/3] \
					[expr $xDetPos+$xDetSize] [expr $yDetPos+2*$yDetSize/3]  -fill gray -width 1	
			}
		}
		
		set xBeam [expr $xDetPos+($xDetSize/2)]
		set yBeam [expr $yDetPos+($yDetSize/2)]
		
		$resolcanvas create oval [expr $xBeam-2] [expr $yBeam-2] \
			[expr $xBeam+2] [expr $yBeam+2] -fill red -outline red -tag myoval
		
		$resolcanvas create arc $xDetPos $yDetPos [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize] \
			-extent 359.9 -outline red -width 1 -start 0 -style arc -tag innercircle
		
		$resolcanvas create arc $xDetPos $yDetPos [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize] \
			-extent 359.9 -outline red -width 1 -start 0 -style arc -tag circle2
		
		$resolcanvas create arc $xDetPos $yDetPos [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize] \
			-extent 359.9 -outline red -width 1 -start 0 -style arc -tag circle3
		
		$resolcanvas create arc $xDetPos $yDetPos [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize] \
			-extent 359.9 -outline red -width 1 -start 0 -style arc -tag circle4
		
		$resolcanvas create arc [expr $xDetPos+($xDetSize/2)-sqrt(0.5)*$xDetSize] \
			[expr $yDetPos+($yDetSize/2)-sqrt(0.5)*$yDetSize] \
			[expr $xDetPos+($xDetSize/2)+sqrt(0.5)*$xDetSize] \
			[expr $yDetPos+($yDetSize/2)+sqrt(0.5)*$yDetSize] \
			-extent 30 -outline red -width 1 -start 120 -style arc -tag outerarc
		
		$resolcanvas create text [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize/2] \
			-font $gFont(small) -text "init A" -tag textinner
		
		$resolcanvas create text [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize/2] \
			-font $gFont(small) -text "init A" -tag text2
		
		$resolcanvas create text [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize/2] \
			-font $gFont(small) -text "init A" -tag text3
		
		$resolcanvas create text [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize/2] \
			-font $gFont(small) -text "init A" -tag text4
		
		$resolcanvas create text [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize/2] \
			-font $gFont(small) -text "init A" -tag textarc
		
		$resolcanvas create text [expr $canvaswidth/2] [expr $yDetPos+$yDetSize+40] \
			-font $gFont(tiny) -anchor c -text "MOSFLM" -tag mosflm
		
		adjust_widget_arcs
		
		clearTraces gReswidget(detector_z)
		clearTraces gReswidget(detector_horz)
		clearTraces gReswidget(detector_vert)
		clearTraces gReswidget(energy)
		
		trace variable gReswidget(detector_z) w "adjust_widget_arcs"
		trace variable gReswidget(detector_horz) w "adjust_widget_arcs"
		trace variable gReswidget(detector_vert) w "adjust_widget_arcs"
		trace variable gReswidget(energy) w "adjust_widget_arcs"
		
		bind $resolcanvas <Button-1> {
			#Note: mouse click gives new det. position rounded off to nearest mm
			detector_horzHorizontal set_value [expr int((double (%x)-$gReswidget(xDetCenter))/$gReswidget(mm2pix))]
			detector_vertVertical set_value   [expr int((double (%y)-$gReswidget(yDetCenter))/$gReswidget(mm2pix))]       	
			
			
			#resHorizontal set_value [expr int($gReswidget(Xsize)* \
				#	(-0.5 + ((double (%x)-$xDetPos)/$xDetSize)))]
			#resVertical set_value   [expr int($gReswidget(Ysize)* \
				#	(-0.5 + ((double (%y)-$yDetPos)/$yDetSize)))]       	
		}		
	}
}


proc adjust_widgetMar_arcs {args} {

	global gFont
	global gReswidget
	global gBeamline
	global gDevice

	if { ! $gBeamline(moveableEnergy) } {
		
		set gReswidget(energy) $gDevice(energy,scaled)
	}

	set resolcanvas $gReswidget(resolcanvas)
	
	#Detector size in pixels
	set xDetSize [expr int($gReswidget(mm2pix)*double($gReswidget(diameter)))]
	set yDetSize [expr int($gReswidget(mm2pix)*double($gReswidget(diameter)))]
	
	set canvaswidth [lindex [$resolcanvas configure -width] 4]
	set canvasheight [lindex [$resolcanvas configure -height] 4]

	set xDetPos [expr ($canvaswidth-$xDetSize)/2]
	set yDetPos [expr ($canvasheight-$yDetSize)/2]

	$resolcanvas coords detectorface $xDetPos $yDetPos [expr $xDetPos+$xDetSize] [expr $yDetPos+$yDetSize]
	
	#calculate pixel coordinates of direct beam within the resolcanvas
	set x [expr int($gReswidget(detector_horz)*$gReswidget(mm2pix)+$gReswidget(xDetCenter))]
	set y [expr int($gReswidget(detector_vert)*$gReswidget(mm2pix)+$gReswidget(yDetCenter))]

	$resolcanvas coords myoval [expr $x-2] [expr $y-2] [expr $x+2] [expr $y+2] 
	
	#calculate distance from direct beam to plate center--in mm first
	set rCenterOffset [expr sqrt($gReswidget(detector_horz)*$gReswidget(detector_horz)+\
								$gReswidget(detector_vert)*$gReswidget(detector_vert))]
	

	#now convert this to pixels
	set pixCenterOffset [expr int($gReswidget(mm2pix)*double($rCenterOffset))]
	
	#adjust the innercircle
	#calculate fractional radius of innercircle
	
	#if {($gReswidget(xDetCenter)!=$x)} {
		set angle [expr atan2([expr double($gReswidget(yDetCenter)-$y)],[expr double($x-$gReswidget(xDetCenter))])]
	#} else {
	#	set angle 0
	#}

	if {([expr abs([expr $pixCenterOffset - ($xDetSize/2)])] > 10)} {
		set radius [expr abs([expr ($xDetSize/2) - $pixCenterOffset])]
		set textoff          [expr ($xDetSize/2) - $pixCenterOffset]

		

		set maxres [format "%5.2fA" \
			[mm_to_angstrom_res [expr abs([expr ($gReswidget(diameter)/2.0)-$rCenterOffset])]]]


		$resolcanvas coords textinner \
		[expr $x + int (0.9 * double ($textoff) * cos ($angle))] \
		[expr $y - int (0.9 * double ($textoff) * sin ($angle))]
		$resolcanvas itemconfigure textinner -text "$maxres"
	} else {
		set radius 2
		$resolcanvas itemconfigure textinner -text ""
	}	
	$resolcanvas coords innercircle [expr $x-$radius] [expr $y-$radius] [expr $x+$radius] [expr $y+$radius]


	#adjust the outer-corner arc
	if {([expr abs($pixCenterOffset)] > 10)} {
		set radius [expr ($xDetSize/2) + $pixCenterOffset]
		set maxres [format "%5.2fA" \
			[mm_to_angstrom_res [expr abs([expr ($gReswidget(diameter)/2.0)+$rCenterOffset])]]]
		$resolcanvas coords textarc \
		[expr $x - int (0.95 * double ($radius) * cos ($angle))] \
		[expr $y + int (0.95 * double ($radius) * sin ($angle))]
		$resolcanvas itemconfigure textarc -text "$maxres"

	} else {
		set radius 2
		$resolcanvas itemconfigure textarc -text ""
	}	
	$resolcanvas coords outerarc [expr $x-$radius] [expr $y-$radius] [expr $x+$radius] [expr $y+$radius]
	$resolcanvas itemconfigure outerarc -start [expr ($angle*180.0/3.14159)-30+180]
	
	$resolcanvas itemconfigure mosflm -text "Mosflm/Denzo beam x \
	[format "%.1f" [expr $gReswidget(detector_vert)+(double($gReswidget(Ysize))/2.0)]] y \
	[format "%.1f" [expr $gReswidget(detector_horz)+(double($gReswidget(Xsize))/2.0)]]"
}

proc adjust_widget_arcs {args} {
	global gOctantProximity
	global gFont
	global gReswidget

	set resolcanvas $gReswidget(resolcanvas)
	
	#Detector size in pixels
	set xDetSize [expr int($gReswidget(mm2pix)*double($gReswidget(Xsize)))]
	set yDetSize [expr int($gReswidget(mm2pix)*double($gReswidget(Ysize)))]
		
	set canvaswidth [lindex [$resolcanvas configure -width] 4]
	set canvasheight [lindex [$resolcanvas configure -height] 4]

	set xDetPos [expr ($canvaswidth-$xDetSize)/2]
	set yDetPos [expr ($canvasheight-$yDetSize)/2]

	#calculate pixel coordinates of direct beam within the resolcanvas
	set x [expr int($xDetPos+$xDetSize*(0.5+(double($gReswidget(detector_horz))/$gReswidget(Xsize))))]
	set y [expr int($yDetPos+$yDetSize*(0.5+(double($gReswidget(detector_vert))/$gReswidget(Ysize))))]

	$resolcanvas coords myoval [expr $x-2] [expr $y-2] [expr $x+2] [expr $y+2] 
	
	#compute fractional coordinates on detector face
	set xfrac [expr (double($x)-$xDetPos)/$xDetSize]
	set yfrac [expr (double($y)-$yDetPos)/$yDetSize]
	set octant [which_octant $xfrac $yfrac]
	set edgelist $gOctantProximity($octant)
	set corner $gOctantProximity($octant,corner)

	#adjust the innercircle
	#calculate fractional radius of innercircle
	set gReswidget(radius,1) [get_radius $xfrac $yfrac [lindex $edgelist 0]]
	set radius $gReswidget(radius,1)
	
	set yTextOffset [get_ytoffset $corner ]
	set xTextOffset [get_xtoffset $corner ]

	if {$radius < 0.05 && $radius > -0.05} {
		$resolcanvas coords innercircle [expr $xDetPos+$xfrac*$xDetSize] [expr $yDetPos+$yfrac*$yDetSize]\
							[expr $xDetPos+$xfrac*$xDetSize] [expr $yDetPos+$yfrac*$yDetSize]
		$resolcanvas itemconfigure textinner -text ""
		set oldradius 0
	} else {
		$resolcanvas coords innercircle [expr $xDetPos+($xfrac-$radius)*$xDetSize] \
							[expr $yDetPos+($yfrac-$radius)*$yDetSize] \
							[expr $xDetPos+($xfrac+$radius)*$xDetSize] \
							[expr $yDetPos+($yfrac+$radius)*$yDetSize]
		$resolcanvas coords textinner [expr $xDetPos+($xfrac+$xTextOffset*abs($radius))*$xDetSize] \
									[expr $yDetPos+($yfrac+$yTextOffset*abs($radius))*$yDetSize]
		set maxres [format "%5.2fA" [angstrom_res $radius]]
		$resolcanvas itemconfigure textinner -text "$maxres"
		set oldradius $radius
	}

	#adjust the outer-corner arc
	set corner_arc [get_corner_parameters $xfrac $yfrac $corner]
	$resolcanvas coords outerarc [expr $xDetPos+($xfrac-[lindex $corner_arc 0])*$xDetSize] \
							[expr $yDetPos+($yfrac-[lindex $corner_arc 0])*$yDetSize] \
							[expr $xDetPos+($xfrac+[lindex $corner_arc 0])*$xDetSize] \
							[expr $yDetPos+($yfrac+[lindex $corner_arc 0])*$yDetSize]
	$resolcanvas itemconfigure outerarc -start [expr [lindex $corner_arc 1]-15]
	set maxres [format "%5.2fA" [angstrom_res [lindex $corner_arc 0]]]
	$resolcanvas itemconfigure textarc -text "$maxres"
	$resolcanvas coords textarc [expr $xDetPos+[lindex $corner_arc 2]*$xDetSize] \
									[expr $yDetPos+[lindex $corner_arc 3]*$yDetSize]

	#adjust circle 2
	set radius [get_radius $xfrac $yfrac [lindex $edgelist 1]]

	if {$radius - abs($oldradius) < 0.12} {
		$resolcanvas coords circle2 [expr $xDetPos+$xfrac*$xDetSize] [expr $yDetPos+$yfrac*$yDetSize]\
							[expr $xDetPos+$xfrac*$xDetSize] [expr $yDetPos+$yfrac*$yDetSize]
		$resolcanvas itemconfigure text2 -text ""
	} else {
		$resolcanvas coords circle2 [expr $xDetPos+($xfrac-$radius)*$xDetSize] \
							[expr $yDetPos+($yfrac-$radius)*$yDetSize] \
							[expr $xDetPos+($xfrac+$radius)*$xDetSize] \
							[expr $yDetPos+($yfrac+$radius)*$yDetSize]
		$resolcanvas coords text2 [expr $xDetPos+($xfrac+$xTextOffset*$radius)*$xDetSize] \
									[expr $yDetPos+($yfrac+$yTextOffset*$radius)*$yDetSize]
		set maxres [format "%5.2fA" [angstrom_res $radius]]
		$resolcanvas itemconfigure text2 -text "$maxres"
		set oldradius $radius
	}
	#get arc_limits $xfrac $yfrac $radius [lindex $edgelist 0]

	#adjust circle 3
	set radius [get_radius $xfrac $yfrac [lindex $edgelist 2]]
	if {$radius - $oldradius < 0.12} {
		$resolcanvas coords circle3 [expr $xDetPos+$xfrac*$xDetSize] [expr $yDetPos+$yfrac*$yDetSize]\
							[expr $xDetPos+$xfrac*$xDetSize] [expr $yDetPos+$yfrac*$yDetSize]
		$resolcanvas itemconfigure text3 -text ""
	} else {
		$resolcanvas coords circle3 [expr $xDetPos+($xfrac-$radius)*$xDetSize] \
							[expr $yDetPos+($yfrac-$radius)*$yDetSize] \
							[expr $xDetPos+($xfrac+$radius)*$xDetSize] \
							[expr $yDetPos+($yfrac+$radius)*$yDetSize]
		$resolcanvas coords text3 [expr $xDetPos+($xfrac+$xTextOffset*$radius)*$xDetSize] \
									[expr $yDetPos+($yfrac+$yTextOffset*$radius)*$yDetSize]
		set maxres [format "%5.2fA" [angstrom_res $radius]]
		$resolcanvas itemconfigure text3 -text "$maxres"
		set oldradius $radius
	}
	#get arc_limits $xfrac $yfrac $radius [lindex $edgelist 0]
	
	#adjust circle 4
	set radius [get_radius $xfrac $yfrac [lindex $edgelist 3]]
	if {$radius - $oldradius < 0.12} {
		$resolcanvas coords circle4 [expr $xDetPos+$xfrac*$xDetSize] [expr $yDetPos+$yfrac*$yDetSize]\
							[expr $xDetPos+$xfrac*$xDetSize] [expr $yDetPos+$yfrac*$yDetSize]
		$resolcanvas itemconfigure text4 -text ""
	} else {
		$resolcanvas coords circle4 [expr $xDetPos+($xfrac-$radius)*$xDetSize] \
							[expr $yDetPos+($yfrac-$radius)*$yDetSize] \
							[expr $xDetPos+($xfrac+$radius)*$xDetSize] \
							[expr $yDetPos+($yfrac+$radius)*$yDetSize]
		$resolcanvas coords text4 [expr $xDetPos+($xfrac+$xTextOffset*$radius)*$xDetSize] \
									[expr $yDetPos+($yfrac+$yTextOffset*$radius)*$yDetSize]
		set maxres [format "%5.2fA" [angstrom_res $radius]]
		$resolcanvas itemconfigure text4 -text "$maxres"
		set oldradius $radius
	}
	#get arc_limits $xfrac $yfrac $radius [lindex $edgelist 0]
	
	$resolcanvas itemconfigure mosflm -text "Mosflm/Denzo beam x \
	[format "%.1f" [expr $gReswidget(detector_vert)+(double($gReswidget(Ysize))/2.0)]] y \
	[format "%.1f" [expr $gReswidget(detector_horz)+(double($gReswidget(Xsize))/2.0)]]"
}


proc mm_to_angstrom_res { mm } {

	global gReswidget
	global gScale
	global gFont
	
	#gReswidget(detector_z) is the sample to detector distance in mm
	#gReswidget(energy) is always given in eV since that is the default unit
	#convert to angstroms by dividing into 12398=  gScale(eV,$gFont(angstrom))
	#assume detector is square so Xsize = Ysize, the size of det face in mm

	if { ($gReswidget(energy) > 0.0) && ($gReswidget(detector_z) > 0.0) && $mm > 0.0 } {

		set Lambda [expr 12398.0/$gReswidget(energy)]
		set theta [expr 0.5 * atan2 ($mm, $gReswidget(detector_z))]
		
		return [expr $Lambda / (2 * sin (abs($theta))) ]
	} else {
		return 0.0
	}


}

proc which_octant {x y} {

	#x and y are given as fractional coordinates on the detector face with
	#(0,0) being in the upper left corner
	
	set register 0
	if {$x > 0.5}    {incr register 1}
	if {$x+$y > 1.0} {incr register 2}
	if {$y > 0.5}    {incr register 4}
	if {$x > $y}     {incr register 8}
	return $register
}


proc get_radius {x y edge} {
	# in this procedure x & y are fractional coordinates
	if {$edge == 1} {return $y}
	if {$edge == 2} {return [expr 1.0 - $x]}
	if {$edge == 3} {return [expr 1.0 - $y]}
	if {$edge == 4} {return $x}
}

proc get_corner_parameters {x y corner} {
	# in this procedure x & y are fractional coordinates

	switch $corner {
		1 {
			set xcorner 1.0
			set ycorner 1.0
		  }
		2 {
			set xcorner 0.0
			set ycorner 1.0
		  }
		3 {
			set xcorner 0.0
			set ycorner 0.0
		  }
		4 {
			set xcorner 1.0
			set ycorner 0.0
		  }
	}
		set radius [expr hypot(($x-$xcorner),($y-$ycorner))]
		set angle [expr -90+180*atan2(($xcorner-$x),($ycorner-$y))/3.141592]

		return [list $radius $angle $xcorner $ycorner] 
}

proc get_xtoffset {corner} {
	set factor 0.26
	switch $corner {
		1 {
			return $factor
		  }
		2 {
			return [expr -$factor]
		  }
		3 {
			return [expr -$factor]
		  }
		4 {
			return $factor
		  }
	}
}

proc get_ytoffset {corner} {
	set factor 0.96
	switch $corner {
		1 {
			return $factor
		  }
		2 {
			return $factor
		  }
		3 {
			return [expr -$factor]
		  }
		4 {
			return [expr -$factor]
		  }
	}
}

proc angstrom_res {rfrac} {
	global gReswidget
	global gScale
	global gFont
	global gBeamline
	global gDevice
	
	#gReswidget(detector_z) is the sample to detector distance in mm
	#gReswidget(energy) is always given in eV since that is the default unit
	#convert to angstroms by dividing into 12398=  gScale(eV,$gFont(angstrom))
	#assume detector is square so Xsize = Ysize, the size of det face in mm

	if { ! $gBeamline(moveableEnergy) } {
		set gReswidget(energy) $gDevice(energy,scaled)
	}

	if { ($gReswidget(energy) > 0.0) && ($gReswidget(detector_z) > 0.0) } {
		set Lambda [expr 12398.0/$gReswidget(energy)]
		set theta [expr 0.5 * atan2 ($rfrac*$gReswidget(Xsize), $gReswidget(detector_z))]
		return [expr $Lambda / (2 * sin (abs($theta))) ]
	} else {
		return 0.0
	}
	
	
}


