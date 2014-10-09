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

package provide BLUICEFrontEndSlitsViewBL12-2 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent


package require DCSDeviceFactory
package require DCSDeviceView
package require DCSMotorControlPanel

package require BLUICECanvasShapes


class DCS::FrontEndBaseBL12-2 {
 	inherit ::DCS::CanvasShapes

    public proc getMotorList { } {
        return [list \
        attenuation \
        ]
    }

   private method addFilter
   private method addFilters
   private method getEnhancedFilterList
 
	protected method hideBeam
	protected method showBeam
   public method handleUpdateFromShutter
   public method handleUpdateFromFilter

   #array for holding
   protected variable m_filterOpenOffset
   protected variable m_filterState
   protected variable m_filterOpenColor
   protected variable m_filterClosedColor

   constructor {} {

   	# create motor view for beam attenuation
	   itk_component add attenuation {
		   ::DCS::TitledMotorEntry $itk_component(canvas).attenuation \
			   -labelText "Attenuation" \
			   -entryType float \
			   -menuChoiceDelta 10 -units "%"  -autoGenerateUnitsList 0 \
			   -decimalPlaces 1 -device ::device::attenuation
	   } {
		   keep -activeClientOnly
           keep -systemIdleOnly
		   keep -mdiHelper
	   }

      addFilters

	   place $itk_component(attenuation) -x 200 -y 70 -anchor s

		$itk_component(control) registerMotorWidget ::$itk_component(attenuation)

		#set shutterObject [$m_deviceFactory createShutter shutter]

		#::mediator register $this $shutterObject state handleUpdateFromShutter
      foreach {filter label} [getEnhancedFilterList] {
		   ::mediator register $this ::device::$filter state handleUpdateFromFilter
      }
		#::mediator register $this ::device::shutter state handleUpdateFromFilter
   }

   destructor {::mediator announceDestruction $this}

}

body DCS::FrontEndBaseBL12-2::showBeam { } {
	
	$itk_component(canvas) itemconfigure beam -fill magenta
	$itk_component(canvas) raise beam
}

body DCS::FrontEndBaseBL12-2::hideBeam { } {

	$itk_component(canvas) itemconfigure beam -fill lightgrey
	$itk_component(canvas) lower beam
}



body DCS::FrontEndBaseBL12-2::handleUpdateFromShutter { shutter_ targetReady_ - state_ -} {

	if { ! $targetReady_ } return

	switch $state_ {
		open {
			showBeam
		}
		
		closed {
			hideBeam
		}
	}
}


body DCS::FrontEndBaseBL12-2::handleUpdateFromFilter { filter_ targetReady_ - state_ - } {

   if { ! $targetReady_ } return


   set filter [$filter_ cget -deviceName]

   #return if the state is still the same so that we don't keep moving the filter by the delta value
   if { $m_filterState($filter) == $state_ } {return}

   if { $state_ == "closed" } {
      $itk_component(canvas) move $filter 0 $m_filterOpenOffset($filter)
      $itk_component(canvas) itemconfigure filter_${filter}_label -fill $m_filterClosedColor($filter)
   } else {
      $itk_component(canvas) move $filter 0 [expr -1 * $m_filterOpenOffset($filter)]
      $itk_component(canvas) itemconfigure filter_${filter}_label -fill $m_filterOpenColor($filter)
   }

   set m_filterState($filter) $state_

	#if { $filter == "shutter" } {
	#	update_beam
	#}
}

#This method assumes that there are already filters defined that start with Al_
#It will find all such filters and sort them.
#If you want to add different filters, just change this function to return a list
#in the following format: {filterName1 label1 filterName2 label2}
body DCS::FrontEndBaseBL12-2::getEnhancedFilterList {} {
   return [::config getStr bluice.filterLabelMap]
}


body DCS::FrontEndBaseBL12-2::addFilter { filter label_ x y command_} {
   draw_filter $filter $label_ \
      $x $y $command_
}

body DCS::FrontEndBaseBL12-2::addFilters {} {

   set canvas $itk_component(canvas)

	draw_ion_chamber 80 134
	ion_chamber_view i0 0 98 167

	draw_ion_chamber 555 134
	ion_chamber_view i2 2 573 168
	$canvas create line 46 137 179 137 -fill magenta -width 2

	#ion_chamber_view i_sample 3 1040 120
				
	set x 140

	foreach {filter filterLabel} [getEnhancedFilterList] {

      set m_filterState($filter) closed
      set m_filterOpenOffset($filter) 20
      set m_filterOpenColor($filter) black
      set m_filterClosedColor($filter) red 

      addFilter $filter $filterLabel $x 120 [list ::device::$filter toggle]

		$canvas create line [expr $x + 10] 137 350 137 -fill magenta -width 2

		incr x 20
	}

	set x 350
	

	$canvas create line 349 137 370 137 -fill magenta -width 2
	incr x 20

   #set m_filterState(shutter) closed
   #set m_filterOpenOffset(shutter) 20
   #set m_filterOpenColor(shutter) red 
   #set m_filterClosedColor(shutter) black
   #addFilter shutter shutter [expr $x ] 120 [list ::device::shutter toggle] 

	$canvas create line 500 137 664 137 -fill magenta -width 2 -arrow last -tag beam

}

class DCS::FrontEndApertureViewBL12-2 {
 	inherit ::DCS::FrontEndBaseBL12-2

	itk_option define -mdiHelper mdiHelper MdiHelper ""

    public proc getMotorList { } {
        return [list \
        attenuation \
        slit_2_vert \
        slit_2_vert_gap \
        slit_2_horiz \
        slit_2_horiz_gap \
        ]
    }

	constructor { args} {

		place $itk_component(control) -x 250 -y 310
		eval itk_initialize $args

      $itk_component(canvas) configure -width 700 -height 340

		draw_aperature 270 0 \
			 slit_2_vert \
			 slit_2_vert_gap \
			 slit_2_horiz \
			 slit_2_horiz_gap
		
		$itk_component(canvas) create line 369 137 438 137 -fill magenta -width 2 -tag beam
		$itk_component(canvas) create line 455 137 583 137 -fill magenta -width 2 -tag beam

		::mediator announceExistence $this
	    showBeam
	}
}
