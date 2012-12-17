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
##   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

# provide the DCSEntry package
package provide DCSPeriodicTable 1.0

# load standard packages
package require Iwidgets
package require BWidget
package require DCSComponent
package require DCSEntry

class DCS::PeriodicTable {
	inherit ::itk::Widget ::DCS::ComponentGate

	itk_option define -periodicFile periodicFile PeriodicFile "unknown"
	itk_option define -tinyFont tinyFont TinyFont "helvetica -10 bold"
	itk_option define -smallFont smallFont SmallFont "helvetica -14 bold"
	itk_option define -largeFont largeFont LargeFont "helvetica -18 bold"
	itk_option define -hugeFont hugeFont HugeFont "helvetica -30 bold"
	itk_option define -darkColor darkColor DarkColor 	#c0c0ff
	itk_option define -lightColor lightColor LightColor #e0e0f0
	itk_option define -lightRed lightRed LightRed #ffaaaa

    itk_option define -energyDevice energyDevice EnergyDevice \
    "::device::energy" {
        if {$m_lastEnergyDevice != ""} {
            $m_lastEnergyDevice unregister $this limits \
            handleEnergyLimitsChange
        }
        set m_lastEnergyDevice $itk_option(-energyDevice)
        if {$m_lastEnergyDevice != ""} {
            $m_lastEnergyDevice register $this limits \
            handleEnergyLimitsChange
        }
    }
	
	private variable _selectedEdge
	private variable _selectedEnergy
	private variable _passedEdgeCutoff
	private variable m_lastEnergyDevice ""
    private variable m_edgeList ""
    private variable m_displayedEdgeList ""

    private variable m_edgeData

    ###
    public method getDataByEdgeName { name } {
        if {[info exists m_edgeData($name)]} {
            return $m_edgeData($name)
        } else {
            log_warning edge $name not found
            return ""
        }
    }

	# public methods
	public method setEdge 
	public method getSelectedEdge {} {return $_selectedEdge}
	public method getSelectedEnergy {} {return $_selectedEnergy}
	public method getPassedEdgeCutoff {} {return $_passedEdgeCutoff}
	public method getCurrentEdgeParameters
	public method convertUnits

    public method getDisplayedEdgeList { } {
        return $m_displayedEdgeList
    }


    public method handleEnergyLimitsChange

	# private methods
	private method createPeriodicTable
	private method openElementsFile {}
	private method displayPeriodicFileError
	private method getNextElement { fileHandle }

	
	constructor { args } { ::DCS::Component::constructor { -edge getSelectedEdge \
																				  -energy getSelectedEnergy \
																				  -passedEdgeCutoff getPassedEdgeCutoff \
																				  -edgeData getCurrentEdgeParameters } }  {

        array set m_edgeData [list]

		itk_component add ring {
			frame $itk_interior.r
		} {
		}
		
		itk_component add canvas {
			canvas $itk_component(ring).c -width 700 -height 500
		} {
		}
		
		eval itk_initialize $args

		$itk_component(canvas) configure -background $itk_option(-lightColor) 

		$itk_component(canvas) create text 350 15 \
			 -font $itk_option(-hugeFont)  -text "Select an X-ray Absorption Edge"

		
		itk_component add edge {
			DCS::Entry $itk_component(canvas).edge \
				 -state disabled \
				 -entryWidth 10 \
				 -promptText "Edge: " -promptWidth 11 \
				 -font $itk_option(-largeFont)  -entryJustify center -entryType string \
				 -escapeToDefault 0 -reference "$this -edge" -shadowReference 1 -activeClientOnly 0 -systemIdleOnly 0
		} {
		}
		
		# create edge energy entry
		itk_component add energy {
			DCS::Entry $itk_component(canvas).energy -activeClientOnly 0 -systemIdleOnly 0 -state disabled \
				 -entryWidth 11  -promptWidth 11 -entryJustify right \
				 -font $itk_option(-largeFont) -entryJustify center -entryType positiveFloat \
				 -escapeToDefault 0 -promptText Energy \
				 -unitsList {eV {-decimalPlaces 3 -promptText "Energy:"} \
									  keV {-decimalPlaces 4 -promptText "Energy:"} \
									  A {-decimalPlaces 6 -promptText "Wavelength:"}} \
				 -units eV -reference "$this -energy" -shadowReference 1 -autoConversion 1
		} {}

		place $itk_component(edge) -x 160 -y 70
		place $itk_component(energy) -x 160 -y 105

		setEdge Se K 12658.0 11222.4
		
		announceExist

		pack $itk_component(ring)
		pack $itk_component(canvas)
	}
    destructor {
        if {$m_lastEnergyDevice != ""} {
            $m_lastEnergyDevice unregister $this limits \
            handleEnergyLimitsChange
        }
    }
}

configbody DCS::PeriodicTable::periodicFile {
	
	set errorResult ""

	if { $itk_option(-periodicFile) != "unknown" } {
		if { $itk_option(-periodicFile) != "" } {
			# open the file
			if [ catch {set fileHandle [open $itk_option(-periodicFile) r] } errorResult ] {
				displayPeriodicFileError $errorResult
				#return -code error $errorResult
			} else {
				#use the file handle to create the table
				createPeriodicTable $fileHandle
				
				#close_elements_file
				close $fileHandle
			}
		} else {
			displayPeriodicFileError "Periodic table file is undefined."
		}
	}
}

body DCS::PeriodicTable::displayPeriodicFileError { error_ } {
	
	puts "-------------------------WARNING-------------------------------"
	puts "Could not load periodic table definition."
	puts $error_
	puts "Please check the periodic.filename parameter in the config file"
	puts "---------------------------------------------------------------"

}

body DCS::PeriodicTable::createPeriodicTable { fileHandle } {
    array unset m_edgeData
		
	while {[set elementInfo [getNextElement $fileHandle]] != "null"} {
	
	 	set atomicZ [lindex $elementInfo 0]
	 	set row [lindex $elementInfo 1]
	 	set column [lindex $elementInfo 2]
		set symbol [lindex $elementInfo 3]

		set xcoordinate [expr 8 + 38*($column-1)]
		set ycoordinate [expr 8 + 53*($row-1)]
		
		if {$row > 7} {
			set xcoordinate [expr $xcoordinate+5]
			set ycoordinate [expr $ycoordinate+5]
		}
		
		$itk_component(canvas) create rectangle $xcoordinate $ycoordinate [expr $xcoordinate+38] \
			 [expr $ycoordinate+53] -fill white -outline $itk_option(-darkColor)
		
		$itk_component(canvas) create rectangle [expr $xcoordinate+1] [expr $ycoordinate+1] \
			 [expr $xcoordinate+15] \
			 [expr $ycoordinate+14] -fill $itk_option(-lightRed) -outline ""
		
		$itk_component(canvas) create text [expr $xcoordinate+2] [expr $ycoordinate+2] \
			 -anchor nw -font $itk_option(-tinyFont) \
			 -text $atomicZ 
						
		$itk_component(canvas) create text [expr $xcoordinate+16] [expr $ycoordinate+11] \
			 -anchor nw -font $itk_option(-smallFont) \
			 -text $symbol 
		
        set ll [llength $elementInfo]
		if {$ll > 5 } {
            set num_edge [expr ($ll - 5) / 3]
            set num_edge_from_file [lindex $elementInfo 4]
            if {$num_edge != $num_edge_from_file} {
                puts "bad format of periodic table: $elementInfo"
            } else {
			    for {set iedge 1} {$iedge <= $num_edge} {incr iedge} {
					set edgeType   [lindex $elementInfo [expr 2 + 3 * $iedge]]
					set edgeEnergy [lindex $elementInfo [expr 3 + 3 * $iedge]]
					set edgeCutoff [lindex $elementInfo [expr 4 + 3 * $iedge]]

					set edgeTag [format "edge%s%s" $symbol $edgeType]
					
					switch $edgeType {
						"K" {
							set xin 15
							set yin 30
							}
						"L1" {
							set xin 1
							set yin 13
							}
						"L2" {
							set xin 1
							set yin 25
							}
						"L3" {
							set xin 1
							set yin 37
							}
						"M1" {
							set xin 16
							set yin 25
							}
						"M2" {
							set xin 16
							set yin 37
							}
					}
	
                    set place_x [expr $xcoordinate + $xin]
                    set place_y [expr $ycoordinate + $yin]
					place [set temp [ label $itk_component(canvas).$edgeTag \
																	-text $edgeType -anchor nw -fg "red" -padx 0 -pady 0 -bg white\
																	-font $itk_option(-tinyFont) ]] \
						 -x $place_x -y $place_y
	
					bind $temp <1> "$this setEdge $symbol $edgeType $edgeEnergy $edgeCutoff"

                    ##### save it to the list
                    set edgeName ${symbol}-${edgeType}
                    set element [list $edgeName $temp $edgeEnergy $place_x $place_y]
                    lappend m_edgeList $element

                    set m_edgeData($edgeName) [list $edgeEnergy $edgeCutoff]
				}
			};# if {$num_edge == $num_edge_from_file}
		};# if {$ll > 5 }
	};#while
}


body DCS::PeriodicTable::getNextElement { fileHandle } {

    set nRead 0
	while {[set nRead [gets $fileHandle buffer]] > 0} {
        if {[string first # $buffer] != 0 && $nRead > 4} {
		    return $buffer
        } else {
            #puts "periodic file skip {$buffer}"
        }
	}
    return "null"
}

body DCS::PeriodicTable::setEdge { element_ edgeType_ passedEdgeEnergy_  passedEdgeCutoff_ } {

	#
	set _selectedEdge "${element_}-${edgeType_}"
	set _selectedEnergy [list $passedEdgeEnergy_ eV]
	set _passedEdgeCutoff $passedEdgeCutoff_

	# update scan parameters
	updateRegisteredComponents -edge
	updateRegisteredComponents -energy
	updateRegisteredComponents -passedEdgeCutoff
	updateRegisteredComponents -edgeData
}

body DCS::PeriodicTable::getCurrentEdgeParameters {} {
	return [list $_selectedEdge $_selectedEnergy $_passedEdgeCutoff]
}

body DCS::PeriodicTable::convertUnits { value_ fromUnits_ toUnits_ } {
	
	if {$value_ == ""} return ""
	
	return [::units convertUnits $value_ $fromUnits_ $toUnits_]
}

body DCS::PeriodicTable::handleEnergyLimitsChange { name_ targetReady_ alias_ \
contents_ - } {
    if {!$targetReady_} return

    foreach {motorType locked uL lL uLon lLon uLim lLim} $contents_ break
    puts "energy effective limits $uLim $lLim"
    set upperLim [::units convertUnitValue $uLim eV]
    set lowerLim [::units convertUnitValue $lLim eV]
    puts "to ev: $upperLim $lowerLim"

    if {$upperLim < $lowerLim} {
        set temp $upperLim
        set upperLim $lowerLim
        set lowerLim $temp
    }

    set edge_plus [::config getStr scan.edge.plus]
    set edge_minus [::config getStr scan.edge.minus]
    if {[string is double -strict $edge_plus]} {
        set upperLim [expr $upperLim - $edge_plus]
    }
    if {[string is double -strict $edge_minus]} {
        set lowerLim [expr $lowerLim + $edge_minus]
    }

    puts "energy $lowerLim --- $upperLim"

    set m_displayedEdgeList ""

    foreach edge $m_edgeList {
        foreach {name temp energy place_x place_y} $edge break
        #puts "$name $energy"
        if {$energy >= $lowerLim && $energy <= $upperLim} {
            place $temp -x $place_x -y $place_y
            #puts "showing $name"
            lappend m_displayedEdgeList $edge
        } else {
            place forget $temp
            #puts "hiding $name"
        }
    }
}


proc testPeriodic { } {
	
	DCS::PeriodicTable .test -periodicFile ~/code/bug321/blu-ice/data/periodic_bl92.dat

	pack .test
	
}

#testPeriodic
