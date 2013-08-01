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


#################################################
# This class is used in both BluIce and DCSS
#################################################
package provide DCSDetectorBase 1.0

# load standard packages
package require Itcl

class DCS::DetectorBase {

    private common MAR345IMGFILEEXT [list \
    mar2300 \
    mar2000 \
    mar1600 \
    mar1200 \
    mar3450 \
    mar3000 \
    mar2400 \
    mar1800 \
    ]

	protected variable _detectorType UNKNOWN

	public method getAllModes
	public method getSupportedModes
	public method setType { newType } {set  _detectorType $newType}
	public method getType {} {return $_detectorType}
	public method getModeSizes
	public method getModeSizesByIndex
	public method getShape
	public method getModules
	public method getDetectorOverheadTime
    public method getImageFileExt { mode }

	public method getModeIndexFromModeName
	public method getModeNameFromIndex
    public method getDefaultModeIndex 

    ## help function, so we will only have one place to do the calculation.
    ## it is used both in DCSS and BluIce.
    ## DCSS: device resolution, runDefinitionForQueue
    ## BluIce: virtualRunForQueue
    public method getRingSize { mode_ offsetH_ offsetV_ }
    public method calculateResolution  { \
    distance_ energy_ mode_ offsetH_ offsetV_ }

    public method calculateDistance  { \
    resolution_ energy_ mode_ offsetH_ offsetV_ }
}
::itcl::body DCS::DetectorBase::getRingSize { mode_ offsetH_ offsetV_ } {
    ## default result
    set ringSize 0

    set offsetH_ [expr abs($offsetH_)]
    set offsetV_ [expr abs($offsetV_)]

    set detectorSize [getModeSizesByIndex $mode_]

    switch -exact -- [getShape] {
        circular {
            set detectorRadius [expr $detectorSize / 2.0]

            set detectorOffset \
            [expr sqrt($offsetH_ * $offsetH_ + $offsetV_ * $offsetV_)]

            if {$detectorOffset < $detectorRadius} {
                set ringSize [expr $detectorRadius - $detectorOffset]
            }
        }
        rectangular -
        default {
            set detectorHalfWidth [expr $detectorSize / 2.0]
            set detectorHalfHeight [expr $detectorSize / 2.0]

            if {$offsetH_ < $detectorHalfWidth && \
            $offsetV_ < $detectorHalfHeight} {
                set ringSizeH [expr $detectorHalfWidth - $offsetH_]
                set ringSizeV [expr $detectorHalfHeight - $offsetV_]

                if {$ringSizeH > $ringSizeV} {
                    set ringSize $ringSizeV
                } else {
                    set ringSize $ringSizeH
                }
            }
        }
    }
    return $ringSize
}
::itcl::body DCS::DetectorBase::calculateResolution { \
distance_ energy_ mode_ offsetH_ offsetV_ } {

    if {$distance_ <= 0} {
        return -code error no_resolution_for_0_distance
    }
    if {$energy_ <= 0} {
        return -code error no_resolution_for_0_energy
    }

    set ringSize [getRingSize $mode_ $offsetH_ $offsetV_]
    if {$ringSize <= 0} {
        return -code error 0_size_resolution_ring
    }

    set twoTheta [expr atan($ringSize / $distance_)]
    set wavelength [expr 12398.0 / $energy_]
    return [expr $wavelength / (2.0 * sin($twoTheta / 2.0))]
}
::itcl::body DCS::DetectorBase::calculateDistance { \
resolution_ energy_ mode_ offsetH_ offsetV_ } {

    if {$resolution_ <= 0} {
        return -code error 0_resolution
    }
    if {$energy_ <= 0} {
        return -code error 0_energy
    }

    set ringSize [getRingSize $mode_ $offsetH_ $offsetV_]
    if {$ringSize <= 0} {
        return -code error 0_size_resolution_ring
    }

    set wavelength [expr 12398.0 / $energy_]
    set theta [expr asin($wavelength / (2.0 * $resolution_))]
    return [expr $ringSize / tan( 2.0 * $theta)]
}

::itcl::body DCS::DetectorBase::getModeIndexFromModeName { modeName_ } {
	return [lsearch [getAllModes] $modeName_]
}

::itcl::body DCS::DetectorBase::getModeNameFromIndex { index_ } {
	return [lindex [getAllModes] $index_]
}


::itcl::body DCS::DetectorBase::getAllModes {} {

	switch $_detectorType {
		Q4CCD {
			#the following order corresponds to the detectors mode order
			return [list slow fast slow_bin fast_bin slow_dezing \
							fast_dezing slow_bin_dezing fast_bin_dezing ]
		}
		Q210CCD {
			#the following order corresponds to the detectors mode order
			return { {unbinned} unused1 binned unused2 {unbinned dezing} \
							 unused3 {binned dezing} unused4 }
		}
		Q315CCD {
			#the following order corresponds to the detectors mode order
			return { {unbinned} unused1 binned unused2 {unbinned dezing} \
							 unused3 {binned dezing} unused4 }
		}
		MAR345 {		
			#the following order corresponds to the detectors mode order
			return { {345mm x 150um}	{300mm x 150um}	{240mm x 150um} \
							 {180mm x 150um} {345mm x 100um} {300mm x 100um} \
							 {240mm x 100um} {180mm x 100um} }
		}

		MAR165 {		
			return [list normal dezingered]
		}
		
		MAR325 {		
			return [list normal dezingered]
		}
		
        PILATUS6 {
            return [list ramp pluse]
        }

		default {
			return { mode1 mode2 mode3 mode4 mode5 mode6 mode7 mode8 }
		}
	}
}


::itcl::body DCS::DetectorBase::getSupportedModes {} {

	switch $_detectorType {

		Q4CCD {
			return [list slow fast slow_bin fast_bin slow_dezing \
							fast_dezing slow_bin_dezing fast_bin_dezing]
		}

		Q210CCD {
			return [list  unbinned binned {unbinned dezing} {binned dezing} ]
		}

		Q315CCD {
			return [list  binned {binned dezing} ]
		}

		MAR345 {		
			return [list {345mm x 150um}	{300mm x 150um}	{240mm x 150um} \
							{180mm x 150um} {345mm x 100um} {300mm x 100um} \
							{240mm x 100um} {180mm x 100um} ]
		}

		MAR165 {
			return [list normal dezingered]
		}
		
		MAR325 {
			return [list normal dezingered]
		}
		
        PILATUS6 {
            return [list ramp pluse]
        }

		default {
			return [list mode1 mode2 mode3 mode4 mode5 mode6 mode7 mode8 ]
		}
	}
}

#what mode should be selected by default
::itcl::body DCS::DetectorBase::getDefaultModeIndex {} {
	#slow as default for Q4 & 345mm x 150um for MAR345 (mode 2)
   #should be 0 for q315

	switch $_detectorType {

		Q4CCD {
         return 0 
		}

		Q210CCD {
			return 2 
		}

		Q315CCD {
			return 2 
		}

		MAR345 {		
			return 2
		}

		MAR165 {
			return 0
		}
		
		MAR325 {
			return 0
		}
		
		PILATUS6 {
			return 0
		}

		default {
			return 0
		}
	}
}



::itcl::body DCS::DetectorBase::getShape { } {
	# create the resolution widget
	switch $_detectorType {
		Q4CCD {
         return rectangular
		}
		
		Q210CCD {
			return rectangular 
		}
		
		Q315CCD {
			return rectangular 
		}
		
		MAR345 {
			return circular 
		}
		
		MAR165 {
		   return circular 
		}

		MAR325 {
		   return rectangular 
		}

		PILATUS6 {
		   return rectangular 
		}

		default {
         return rectangular
		}
	}
}



::itcl::body DCS::DetectorBase::getModules { } {
	# create the resolution widget
	switch $_detectorType {
		Q4CCD {
         return 4
		}
		
		Q210CCD {
			return 4
		}
		
		Q315CCD {
			return 9
		}
		
		MAR325 {
			return 16
		}

		PILATUS6 {
			return 1
		}
		
		default {
			return 1
		}
	}
}




::itcl::body DCS::DetectorBase::getModeSizes { modeName_ } {
	set index [getModeIndexFromModeName $modeName_]
    return [getModeSizesByIndex $index]
}
::itcl::body DCS::DetectorBase::getModeSizesByIndex { index } {
	
	switch $_detectorType {
		Q4CCD {
			return 192
		}

		Q210CCD {
			return 210
		}

		Q315CCD {
			return 315
		}

		MAR345 {		
			return [lindex [list 345 300 240 180 345 300 240 180] $index ]
		}
		
		MAR165 {		
			return 165
		}
		
		MAR325 {		
			return 325
		}
		
		PILATUS6 {		
			return 423
		}

		default {
			return 100
		}
	}
}

body DCS::DetectorBase::getImageFileExt { mode } {
    switch -exact -- $_detectorType {
        MAR325 -
        MAR165  {
            return mccd
        }
        MAR345 {
            return [lindex $MAR345IMGFILEEXT $mode]
        }
        PILATUS6 {
            return cbf
        }
        Q315CCD -
        Q4CCD -
        default {
            return img
        }
    }
}

::itcl::body DCS::DetectorBase::getDetectorOverheadTime { modeName_ } {

	set index [getModeIndexFromModeName $modeName_]
	
	switch $_detectorType {
		Q4CCD {
			return [lindex {10 8 4 2 20 16 8 4} $index]
		}
		
		Q210CCD {
			return [lindex { 10 8 4 2 20 16 8 4 } $index]
		}
		
		Q315CCD {
			return [lindex { 10 8 4 2 20 16 8 4 } $index]
		}
		
		MAR345 {
			return [lindex { 90 75 60 45 115 95 75 55 } $index]
		}
		
		MAR165 {		
			return 5
		}
		
		MAR325 {		
			return 5
		}
		
		PILATUS6 {		
			return 0.1
		}

		default {
			return 10
		}
	}
}
