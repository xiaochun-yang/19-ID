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

package provide BLUICEDoseMode 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory


class DCS::DoseFactor {
 	inherit ::DCS::Component

   public method handleDoseFactorChange
   public method getDoseFactor {} {return $m_doseFactor}
   public method getStatus {} {return inactive} 
   public method calculateDoseTime
   public method estimateNewDoseFactor { situation }

    public variable dataDevice ::device::dose_data

   private variable m_doseFactor 2.0
   private variable m_lastCounts 1.0
   private variable m_storedCounts 1.0
   private variable m_lastSituation ""
   private variable m_storedSituation ""

   #variable for storing singleton doseFactor object
   private common m_theObject {} 
   public proc getObject
   public method enforceUniqueness

    private common IGNORE_BEAMSIZE \
    [::config getInt "doseEstimate.ignoreBeamSize" 0]
	
	constructor { args } {
      ::DCS::Component::constructor { doseFactor {getDoseFactor} status {getStatus} }
   } {
      #-----------------
      # singleton structure copied from [incr tcl] design patterns
      enforceUniqueness
      
      eval configure $args

      ::mediator register $this $dataDevice contents handleDoseFactorChange 

		announceExist
   }

   destructor {
      announceDestruction 
   }
}

body DCS::DoseFactor::calculateDoseTime { time_ } {
   if { ! [isFloat $m_doseFactor] } { return 1.0 }

   return [expr $time_ * $m_doseFactor]
}
body DCS::DoseFactor::estimateNewDoseFactor { situation_ } {
    if {[llength $m_lastSituation] != [llength $situation_]} {
        log_warning dosemode situation format changed, skip
        log_warning DEBUG last=$m_lastSituation
        log_warning DEBUG run=$situation_

        return $m_doseFactor
    }
    foreach {ts0 energy0 beam_size_x0 beam_size_y0 attenuation0} \
    $m_lastSituation break
    foreach {ts1 energy1 beam_size_x1 beam_size_y1 attenuation1} \
    $situation_ break

    #puts "last $m_lastSituation"
    #puts "now  $situation_"


    ### TODO: include energy in calculation
    set area0 [expr $beam_size_x0 * $beam_size_y0]
    set area1 [expr $beam_size_x1 * $beam_size_y1]
    set through0 [expr 100.0 - $attenuation0]
    set through1 [expr 100.0 - $attenuation1]
    if {$IGNORE_BEAMSIZE} {
        set flux0 $through0
        set flux1 $through0
    } else {
        set flux0 [expr $area0 * $through0]
        set flux1 [expr $area1 * $through1]
    }

    if {$flux0 < 0} {
        set flux0 0
    }
    if {$flux1 < 0} {
        set flux1 1
    }
    
    if {$flux0 == 0} {
        set extra 0.001
    } elseif {$flux1 == 0} {
        set extra 1000
    } else {
        set extra [expr $flux0 / $flux1]
    }

    if {$extra > 0.8 && $extra < 1.2} {
        return $m_doseFactor
    } else {
        if {$extra > 1000} {
            set extra 1000
        }
        if {$extra < 0.001} {
            set extra 0.001
        }
        if {$extra > 10} {
            set extra [format "%.0f" $extra]
        } elseif {$extra > 1} {
            set extra [format "%.1f" $extra]
        } elseif {$extra > 0.1} {
            set extra [format "%.2f" $extra]
        } else {
            set extra [format "%.3f" $extra]
        }

        return "$m_doseFactor * $extra"
    }
}

#return the singleton object
body DCS::DoseFactor::getObject {} {
   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto]
   }

   return $m_theObject
}

#this function should be called by the constructor
body DCS::DoseFactor::enforceUniqueness {} {
   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if ![string match "${current}::getObject" $caller] {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}


body DCS::DoseFactor::handleDoseFactorChange { - targetReady_ - contents_ - } {
   if { !$targetReady_ } return

    if {[llength $contents_] < 4} return

    foreach {m_storedSituation m_storedCounts m_lastSituation m_lastCounts} \
    $contents_ break

    if {[string is double -strict $m_storedCounts] && \
    [string is double -strict $m_lastCounts] && \
    $m_storedCounts != 0 && $m_lastCounts != 0} {
        set m_doseFactor [format "%.2f" \
        [expr abs(double($m_storedCounts) / double($m_lastCounts)) ]]
    } else {
        set m_doseFactor 1.0
    }

   #puts "DOSE CHANGE: $object_ $m_doseFactor"

   updateRegisteredComponents doseFactor
}


class DCS::DoseControlView {
 	inherit ::itk::Widget
	
	itk_option define -runListDefinition runListDefinition RunListDefinition ::device::runs

    itk_option define -forGrid forGrid ForGrid 0
   
    public method start { } {
        if {$itk_option(-forGrid)} {
            set groupId [gCurrentGridGroup getId]
            set gridId  [gCurrentGridGroup getCurrentGridId]
            if {$groupId < 0 || $gridId < 0} {
                log_error select a crystal first before do normalize
                return
            }
            $m_objGridGroupConfig normalize $groupId $gridId
        } else {
            $m_objNormalize startOperation
        }
    }

    private variable m_deviceFactory
    private variable m_objNormalize ""
    private variable m_objGridGroupConfig ""

	constructor { args} {

      set m_deviceFactory [DCS::DeviceFactory::getObject]

        set m_objNormalize \
        [$m_deviceFactory createOperation normalize]

        set m_objGridGroupConfig \
        [$m_deviceFactory createOperation gridGroupConfig]

      itk_component add doseFrame {
         ::iwidgets::labeledframe $itk_interior.lf -labeltext "Exposure Control"
      } {}
 
      set ring [$itk_component(doseFrame) childsite]

      itk_component add doseFactor {
         DCS::Label $ring.df -promptText "Exposure Factor:"
      } {}

		itk_component add doseEnable {
			DCS::Checkbutton $ring.inv -text "Enable" -state normal
		} {}

		itk_component add normalizeButton {
			DCS::Button $ring.def -text "Normalize" \
				 -width 5 -pady 0 -activeClientOnly 1 \
            -command "$this start" \
		} {}
		
		eval itk_initialize $args

      set runsList $itk_option(-runListDefinition)

      set doseFactorObject [DCS::DoseFactor::getObject] 
      $itk_component(doseFactor) configure -component $doseFactorObject -attribute doseFactor 

   	$itk_component(doseEnable) configure \
         -command "$runsList setDoseMode %s" -reference "$runsList doseMode" -shadowReference 1

      pack $itk_component(doseFrame) -expand yes -fill both
      grid $itk_component(doseEnable) -row 0 -column 0
      grid $itk_component(normalizeButton) -row 1 -column 0 
      grid $itk_component(doseFactor) -row 2 -column 0

		::mediator announceExistence $this


      return

	   DynamicHelp::register $itk_component(doseEnable) balloon "Enable Exposure Mode\n(Correct exposure time with Exposure Factor)"
	   DynamicHelp::register $itk_component(doseFactor) balloon "Exposure Factor\n(Change of ion chamber reading since last Normalize)"
	   DynamicHelp::register $itk_component(normalizeButton) balloon "Normalize Exposure Factor\n(Use current ion chamber reading to set 'Exposure Factor' to 1.0)"
   }	

	destructor {
      ::mediator announceDestruction $this
	}
}

