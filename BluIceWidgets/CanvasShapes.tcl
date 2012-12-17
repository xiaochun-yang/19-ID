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

package provide BLUICECanvasShapes 1.0



class DCS::CanvasShapes {
 	inherit ::itk::Widget

   protected variable m_deviceFactory

	itk_option define -mdiHelper mdiHelper MdiHelper ""

   private variable _topColor #c0c0ff
   private variable _frontColor #c0c0ff
   private variable _sideColor #c0c0ff

   protected method rect_solid
   protected method motorArrow
   protected method moveHotSpot
   protected method motorBlueArrow
   protected method draw_slit 
   protected method draw_four_slits 
   protected method draw_filter
   protected method draw_aperature
   protected method draw_aperature_base
   protected method draw_ion_chamber
   protected method ion_chamber_view
   protected method motorView 

    ########## need override ########
    ##### it has to be available before instantiation,
    ##### so, it is proc not method
    public method getMotorList { } { return "" }

	constructor { args} {

      set m_deviceFactory [::DCS::DeviceFactory::getObject]

		itk_component add canvas {
			canvas $itk_interior.c 
		} {
         keep -width -height
      }

		# construct the panel of control buttons
		itk_component add control {
			::DCS::MotorControlPanel $itk_component(canvas).control \
				 -width 7 -orientation "horizontal" \
				 -ipadx 4 -ipady 2  -buttonBackground #c0c0ff \
				 -activeButtonBackground #c0c0ff  -font "helvetica -14 bold"
		} {
            keep -serialMove
		}

      #The following 'bind' line can be uncommented to allow canvas to print x,y coordinate when clicked.
      #    This is helpful when designing new layouts for optics views, etc.
      bind $itk_component(canvas) <Button-1> { puts "%x %y" }
 
      pack $itk_interior -expand yes -fill both
      pack $itk_component(canvas)
   }
}


body DCS::CanvasShapes::rect_solid { x y width height depth skewleft skewright {topColor \#c0c0ff} {frontColor \#b0b0ee} {sideColor \#a0a0dd} {tag null}} {
	
	set x0 [expr $x + $skewleft]
	set y0 $y
	set x1 [expr $x + $width + $skewright]
	set y1 $y
	set x2 [expr $x + $width]
	set y2 [expr $y + $depth]
	set x3 $x
	set y3 $y2
	set x4 $x
	set y4 [expr $y3 + $height]
	set x5 $x2
	set y5 $y4
	set x6 $x1
	set y6 [expr $y1 + $height]
	
	if { $depth > 10 } {
		set y6 [expr $y6 - .04 * double($height) ]
	}
	
	$itk_component(canvas) create poly $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3 \
		 -fill $topColor -tag $tag
	$itk_component(canvas) create line $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3 $x0 $y0 \
		 -tag $tag
	
	$itk_component(canvas) create rectangle $x3 $y3 $x5 $y5 \
		 -fill $frontColor -tag $tag
	
	$itk_component(canvas) create poly $x1 $y1 $x2 $y2 $x5 $y5 $x6 $y6 \
		 -fill $sideColor -tag $tag
	$itk_component(canvas) create line $x1 $y1 $x2 $y2 $x5 $y5 $x6 $y6 $x1 $y1 \
		 -tag $tag
	
}	

										
body DCS::CanvasShapes::motorArrow { motor upX upY midCoord downX downY \
							 {plus_x NULL} {plus_y NULL} {minus_x NULL} {minus_y NULL} } {
	
    if { ! [$m_deviceFactory motorExists $motor]} {
        return
    }
         
	# draw the arrow
	set arrow \
		 [ eval $itk_component(canvas) create line $upX $upY $midCoord $downX $downY \
				 -arrow both -smooth true -splinesteps 100 -width 5 \
				 -fill black ]


	# draw plus sign
	if { $plus_x != "NULL" && $plus_y != "NULL" } {
		moveHotSpot $motor $plus_x $plus_y positive
	} 

	# draw minus sign
	if { $minus_x != "NULL" && $minus_y != "NULL" } {
		moveHotSpot $motor $minus_x $minus_y negative
	}
	
}

#set visible to false if the background already has the + and -
body DCS::CanvasShapes::moveHotSpot { motor x y direction {visible true} } {

    if { ! $visible } {
        set text " "
    } else {
        if { $direction =="positive" } {set text "+"}
        if { $direction =="negative" } {set text "-"}
    }

    set btn [ $itk_component(canvas) create text $x $y -text "$text" -font *-courier-bold-r-normal--14-*-*-*-*-*-*-*]
		$itk_component(canvas) bind $btn <Button-1> "$itk_component($motor) moveBy $direction"
}

body DCS::CanvasShapes::motorBlueArrow { motor upX upY midCoord downX downY \
							 {plus_x NULL} {plus_y NULL} {minus_x NULL} {minus_y NULL} } {
	
	# draw the arrow
	set arrow \
		 [ eval $itk_component(canvas) create line $upX $upY $midCoord $downX $downY \
				 -arrow last -smooth true -splinesteps 100 -width 5 \
				 -fill blue ]


	# draw plus sign
	if { $plus_x != "NULL" && $plus_y != "NULL" } {
		moveHotSpot $motor $plus_x $plus_y positive
	} 

	# draw minus sign
	if { $minus_x != "NULL" && $minus_y != "NULL" } {
		moveHotSpot $motor $minus_x $minus_y negative
	}
}

body DCS::CanvasShapes::draw_slit { x y } {
	rect_solid $x $y 5 50 20 30 30
}


body DCS::CanvasShapes::draw_four_slits { x y leftMotor rightMotor upperMotor lowerMotor } {
	motorView $leftMotor [expr $x + 297] [expr $y + 80] s 
	motorView $rightMotor [expr $x + 80] [expr $y + 180] n 
	motorView $lowerMotor [expr $x + 217] [expr $y + 235] n 
	motorView $upperMotor [expr $x + 185] [expr $y + 33] e 	

	# draw the ssrl slit
	motorArrow $leftMotor \
      [expr $x + 258] [expr $y + 87] {} [expr $x + 224] [expr $y + 110] \
      [expr $x + 255] [expr $y + 102] [expr $x + 233] [expr $y + 117]
	draw_slit [expr $x + 191] [expr $y + 81]

	# draw the spear slit
	draw_slit [expr $x + 149] [expr $y + 109]

	motorArrow $rightMotor \
		 [expr $x + 152] [expr $y + 155] {} [expr $x + 118] [expr $y + 178] \
		 [expr $x + 143] [expr $y + 148] [expr $x + 123] [expr $y + 163]

	# draw the lower slit
	draw_slit [expr $x + 180] [expr $y + 130]

	motorArrow $lowerMotor \
		 [expr $x + 198] [expr $y + 190] {} [expr $x +  198] [expr $y + 235] \
		 [expr $x + 208] [expr $y + 195] [expr $x +  208] [expr $y + 230]


	# draw the upper slit
	draw_slit [expr $x + 180] [expr $y + 65]

	motorArrow $upperMotor \
		 [expr $x + 198] [expr $y + 32] {} [expr $x + 198] [expr $y + 77] \
		 [expr $x + 188] [expr $y + 37] [expr $x + 188] [expr $y + 72]



}

body DCS::CanvasShapes::draw_filter { filter label x y command {thickness 2} } {
	set gColors(light)				#f0f0ff
	set gColors(side)					#a0a0dd
	set gColors(front)				#b0b0ee
	set gColors(top)					#c0c0ff	
	
	# draw the label for the filter
	$itk_component(canvas) bind [$itk_component(canvas) create text \
		[expr $x + 10] [expr $y - 30] -text $label \
		-tag filter_${filter}_label] \
		<Button-1> $command 
	
	# draw the filter
	rect_solid $x $y $thickness 25 10 15 15 $gColors(top) $gColors(front) $gColors(side) $filter
	
	$itk_component(canvas) bind $filter <Button-1> $command
}

body DCS::CanvasShapes::draw_aperature { x y vertMotor vertGapMotor horizMotor horizGapMotor } {

	set gColors(light)				#f0f0ff
	set gColors(side)					#a0a0dd
	set gColors(front)				#b0b0ee
	set gColors(top)					#c0c0ff

    draw_aperature_base [expr $x + 167] [expr $y +100] 32 100 16 20

    if {$vertGapMotor != ""} {
	    motorView $vertGapMotor [expr $x + 280] [expr $y + 95] s
	    # draw the vertical gap
	    motorArrow $vertGapMotor \
		 [expr $x + 224] [expr $y + 101] {} [expr $x + 224] [expr $y + 127] \
		 [expr $x + 234] [expr $y + 104] [expr $x + 234] [expr $y + 123]
    }

    if {$horizMotor != ""} {
	    # draw the horizontal translation
	    motorView $horizMotor [expr $x + 100] [expr $y + 190] n

	    motorArrow $horizMotor \
		 [expr $x + 177] [expr $y + 158] {} [expr $x + 139] [expr $y + 189] \
		 [expr $x + 159] [expr $y + 159] [expr $x + 139] [expr $y + 175]

    }
    
    if {$horizGapMotor != ""} {
	    motorView $horizGapMotor [expr $x + 275] [expr $y + 215] n

	    # draw the horizontal gap
	    motorArrow $horizGapMotor \
		 [expr $x +  227] [expr $y + 194] {} [expr $x + 207] [expr $y + 213] \
		 [expr $x + 232] [expr $y + 198] [expr $x + 223] [expr $y + 212]
    }

    if {$vertMotor != ""} {
	    motorView $vertMotor [expr $x + 177] [expr $y + 45] e

	    # draw the vertical translation
	    motorArrow $vertMotor \
		 [expr $x + 190] [expr $y + 66] {} [expr $x + 190] [expr $y + 111] \
		 [expr $x + 180] [expr $y + 71] [expr $x + 180] [expr $y + 105]
    }
}


body DCS::CanvasShapes::draw_aperature_base { x y width height frame_width frame_height} {

	set gColors(light)				#f0f0ff
	set gColors(side)					#a0a0dd
	set gColors(front)				#b0b0ee
	set gColors(top)					#c0c0ff
    
	$itk_component(canvas) create poly $x [expr $y + $height + $frame_height + 1] [expr $x + $frame_width] [expr $y + $height + $frame_height + 1] [expr $x + $width + $frame_width -2] [expr $y + $height -3] [expr $x + $width] [expr $y + $height -3] -fill $gColors(top) -outline black
	$itk_component(canvas) create rect [expr $x + $width + 1] $y [expr $x + $width + $frame_width -2] [expr $y + $height -3] -fill $gColors(front) 
	set result [$itk_component(canvas) create rect [expr $x + 1] [expr $y + $frame_height ] [expr $x + $frame_width] [expr $y + $height + $frame_height] -fill $gColors(front)]
	$itk_component(canvas) create poly [expr $x ] [expr $y + $frame_height + 1] [expr $x + $frame_width] [expr $y + $frame_height + 1] [expr $x + $width + $frame_width -2] $y [expr $x + $width] $y -fill $gColors(top) -outline black

    return $result
}




body DCS::CanvasShapes::draw_ion_chamber { x y } {
	set gColors(light)				#f0f0ff
	set gColors(side)					#a0a0dd
	set gColors(front)				#b0b0ee
	set gColors(top)					#c0c0ff

	set width 20
	set height 15
	set length 20
	
	set x0 $x
	set x1 [expr $x0 + $width]
	set x2 [expr $x0 + 15]
	set x3 [expr $x2 + $width]
	set x4 [expr $x0 + $width/2 + 7.5]
	set x5 [expr $x0 - 5 ]
	set x6 [expr $x3 + 5 ]
	
	set y0 $y
	set y1 [expr $y0 - 10]
	set y2 [expr $y0 + $height]
	set y3 [expr $y2 - 10]
	set y5 [expr $y0 - 5 ]
	set y4 [expr $y5 - $length]
	set y7 [expr $y5 + $height + $length]
	set y8 [expr $y4]
	set y9 [expr $y7]
	
	$itk_component(canvas) create oval $x5 $y8 $x6 $y9 -fill $gColors(light) -outline $gColors(top) 
	$itk_component(canvas) create poly $x0 $y0 $x1 $y0 $x3 $y1 $x2 $y1 -fill $gColors(front) -outline black
	$itk_component(canvas) create poly $x0 $y2 $x1 $y2 $x3 $y3 $x2 $y3 -fill $gColors(side) -outline black
	$itk_component(canvas) create line $x4 $y4 $x4 $y5 -fill black -width 2
	$itk_component(canvas) create line $x4 $y2 $x4 $y7 -fill black -width 2
}



body DCS::CanvasShapes::ion_chamber_view { detector subscript x y } {

	set frame [frame $itk_component(canvas).i${detector}frame -relief groove \
		-borderwidth 2 -width 100 -height 30]

	$itk_component(canvas) create window $x $y -window $frame -anchor n

	place [ label $frame.i$detector -text "I" -font "courier 12 bold" ] \
		-x 0 -y 0
	place [ label $frame.i${detector}sub -text $subscript -font "helvetica 10 bold" ] \
		-x 10 -y 6
	
	#place [label $frame.i${detector}val -foreground $gColors(counts) -font $gFont(small) \
	#	-textvariable gDevice($detector,cps) -anchor e -width 8] -x 25 -y 0
}

body DCS::CanvasShapes::motorView { motor x y {anchor ""} {units_ "" }} {

   set device [$m_deviceFactory getObjectName $motor]
#set s 1
#set motor1 $motor$s
	itk_component add $motor {
		::DCS::TitledMotorEntry $itk_component(canvas).$motor \
		   -autoGenerateUnitsList 1 \
         -labelText $motor
	} {
		keep -mdiHelper
	}
    
    if { ! [$m_deviceFactory motorExists $motor]} {
        return
    }
         
   $itk_component($motor) configure -device $device

   if {$anchor != "" } {
      place $itk_component($motor) -x $x -y $y -anchor $anchor
   } else {
      place $itk_component($motor) -x $x -y $y 
   }

   if {$units_ != "" } {
      $itk_component($motor) configure -units $units_
   }

   $itk_component(control) registerMotorWidget ::$itk_component($motor)

}
