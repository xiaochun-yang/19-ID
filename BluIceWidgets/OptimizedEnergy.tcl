#!/usr/bin/wish
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

package require Itcl
package require Iwidgets
package require BWidget

package provide BLUICEOptimizedEnergy 1.0

# load the DCS packages
package require DCSDevice
package require DCSDeviceView


class DCS::OptimizedEnergyParams {
   inherit DCS::Component	

	public method configureString
	public method sendContentsToServer

   private variable m_deviceFactory
   private variable m_optimizedEnergyParams 

   public variable status "inactive"

   public variable state 
   public variable message

   #enable optimization bits
   public variable trackingEnable 
   public variable optimizeEnable
   public variable beamlineOpenCheck
   public variable resetEnergyAfterOptimize 0
   public variable spareOption2 0
   public variable spareOption3 0
   public variable spareOption4 0

   #when to optimize parameters
   public variable lastOptimizedPosition
   public variable lastOptimizedTime
   public variable lastOptimizedDetectorZ
   public variable lastOptimizedTablePosition
   public variable energyTolerance
   public variable optimizeTimeout
   public variable detectorZTolerance

   #scan parameters for optimization
   public variable flux
   public variable wmin
   public variable glc
   public variable grc
   public variable ionChamber
   public variable minBeamsizeX
   public variable minBeamsizeY
   public variable minCounts
   public variable scanPoints
   public variable scanStep
   public variable scanTime
   public variable ionChamberCheck
   public variable beamlineOpenStateDelay

    #injection check
    public variable injectionStateCheck
    public variable injectionStateDelay

    public variable beamHappyCheck

    public variable spearCurrentCheck 0
    public variable minCurrent 0

   public method setField
   public method setTrackingEnable  {value_} {setField 2 $value_}
   public method setOptimizeEnable  {value_} {setField 3 $value_}
   public method setBeamlineOpenCheck  {value_} {setField 4 $value_}
   public method setResetEnergyAfterOptimize  {value_} {setField 5 $value_}
   public method setLastOptimizedPosition  {value_} {setField 9 $value_}
   public method setLastOptimizedTime  {value_} {setField 10 $value_}
   public method setEnergyTolerance  {value_} {setField 11 $value_}
   public method setDetectorZTolerance  {value_} {setField 31 $value_}
   public method setOptimizeTimeout  {value_} {setField 12 $value_}
   public method setLastOptimizedTablePosition  {value_} {setField 13 $value_}
   public method setFlux   {value_} {setField 14 $value_}
   public method setWmin  {value_} {setField 15 $value_}
   public method setGlc  {value_} {setField 16 $value_}
   public method setGrc  {value_} {setField 17 $value_}
   public method setIonChamber  {value_} {setField 18 $value_}
   public method setMinBeamsizeX  {value_} {setField 19 $value_}
   public method setMinBeamsizeY  {value_} {setField 20 $value_}
   public method setMinCounts  {value_} {setField 21 $value_}
   public method setScanPoints {value_} {setField 22 $value_}
   public method setScanStep {value_} {setField 23 $value_}
   public method setScanTime {value_} {setField 24 $value_}
   public method setIonChamberCheck  {value_} {setField 25 $value_}
   public method setOpenStateDelay  {value_} {setField 26 $value_}
   public method setInjectionCheck  {value_} {setField 27 $value_}
   public method setInjectionDelay  {value_} {setField 28 $value_}
   public method setBeamHappyCheck  {value_} {setField 29 $value_}
   public method setSpearCurrentCheck  {value_} {setField 32 $value_}
   public method setMinCurrent  {value_} {setField 33 $value_}

	public method handleParametersChange
	public method submitNewParameters
    public method getContents { } {
        $m_optimizedEnergyParams getContents
    }

   #variable for storing singleton object
   private common m_theObject {} 
   private common m_theDefaultObj {} 
   public proc getObject
   public proc getDefaultObject
   public method enforceUniqueness

	# call base class constructor
	constructor { string_name args } {

		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 status {cget -status} \
					 contents { getContents } \
					 state {cget -state} \
					 message { cget -message } \
					 trackingEnable {cget -trackingEnable} \
					 optimizeEnable {cget -optimizeEnable} \
					 beamlineOpenCheck {cget -beamlineOpenCheck} \
					 resetEnergyAfterOptimize {cget -resetEnergyAfterOptimize} \
				    lastOptimizedPosition { cget -lastOptimizedPosition } \
					 lastOptimizedTime { cget -lastOptimizedTime } \
					 lastOptimizedDetectorZ { cget -lastOptimizedDetectorZ } \
					 energyTolerance { cget -energyTolerance } \
					 detectorZTolerance { cget -detectorZTolerance } \
					 optimizeTimeout { cget -optimizeTimeout } \
					 lastOptimizedTablePosition { cget -lastOptimizedTablePosition } \
					 flux { cget -flux } \
					 wmin { cget -wmin } \
					 glc { cget -glc } \
					 grc { cget -grc } \
					 ionChamber { cget -ionChamber } \
					 minBeamsizeX { cget -minBeamsizeX } \
					 minBeamsizeY { cget -minBeamsizeY } \
					 minCounts { cget -minCounts } \
					 scanPoints { cget -scanPoints } \
					 scanStep { cget -scanStep } \
					 scanTime { cget -scanTime } \
					 ionChamberCheck {cget -ionChamberCheck} \
					 beamlineOpenStateDelay {cget -beamlineOpenStateDelay} \
                     injectionStateCheck { cget -injectionStateCheck } \
                     injectionStateDelay { cget -injectionStateDelay } \
                     beamHappyCheck      { cget -beamHappyCheck } \
                     spearCurrentCheck   { cget -spearCurrentCheck } \
                     minCurrent          { cget -minCurrent } \
			 }
	} {
		
      enforceUniqueness

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      
      set m_optimizedEnergyParams [$m_deviceFactory createString $string_name]

      ::mediator register $this $m_optimizedEnergyParams contents handleParametersChange

		eval configure $args
      
		announceExist
	}
}

#return the singleton object
body DCS::OptimizedEnergyParams::getObject {} {
   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto optimizedEnergyParameters]
   }

   return $m_theObject
}
body DCS::OptimizedEnergyParams::getDefaultObject {} {
   if {$m_theDefaultObj == {}} {
      #instantiate the singleton object
      set m_theDefaultObj [[namespace current] ::#auto optimizedEnergy_default]
   }

   return $m_theDefaultObj
}

#this function should be called by the constructor
body DCS::OptimizedEnergyParams::enforceUniqueness {} {
   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if {![string match "${current}::getObject" $caller] && \
   ![string match "${current}::getDefaultObject" $caller]} {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}


body DCS::OptimizedEnergyParams::submitNewParameters { contents_ } {
   $m_optimizedEnergyParams sendContentsToServer $contents_
}

body DCS::OptimizedEnergyParams::setField  { index_ value_} {

   set clientState [::dcss cget -clientState]

   if { $clientState != "active"} return

   set newString [list $state $message $trackingEnable $optimizeEnable $beamlineOpenCheck $resetEnergyAfterOptimize $spareOption2 $spareOption3 $spareOption4 $lastOptimizedPosition $lastOptimizedTime $energyTolerance $optimizeTimeout $lastOptimizedTablePosition $flux $wmin $glc $grc $ionChamber $minBeamsizeX $minBeamsizeY $minCounts $scanPoints $scanStep $scanTime $ionChamberCheck $beamlineOpenStateDelay $injectionStateCheck $injectionStateDelay $beamHappyCheck $lastOptimizedDetectorZ $detectorZTolerance $spearCurrentCheck $minCurrent]


   set newString [lreplace $newString $index_ $index_ $value_]
   submitNewParameters $newString
}

body DCS::OptimizedEnergyParams::handleParametersChange { - targetReady_ - optimizedEnergyParams - } {

	if { ! $targetReady_} return

   set state [lindex $optimizedEnergyParams 0]
   set message [lindex $optimizedEnergyParams 1]
   set trackingEnable [lindex $optimizedEnergyParams 2]
   set optimizeEnable [lindex $optimizedEnergyParams 3]
   set beamlineOpenCheck [lindex $optimizedEnergyParams 4]
   set resetEnergyAfterOptimize [lindex $optimizedEnergyParams 5]
   set spareOption2 [lindex $optimizedEnergyParams 6]
   set spareOption3 [lindex $optimizedEnergyParams 7]
   set spareOption4 [lindex $optimizedEnergyParams 8]
   set lastOptimizedPosition [lindex $optimizedEnergyParams 9]
   set lastOptimizedTime [lindex $optimizedEnergyParams 10]
   set energyTolerance [lindex $optimizedEnergyParams 11]
   set optimizeTimeout [lindex $optimizedEnergyParams 12]
   set lastOptimizedTablePosition [lindex $optimizedEnergyParams 13]
   set flux [lindex $optimizedEnergyParams 14]
   set wmin [lindex $optimizedEnergyParams 15]
   set glc [lindex $optimizedEnergyParams 16]
   set grc [lindex $optimizedEnergyParams 17]
   set ionChamber [lindex $optimizedEnergyParams 18]
   set minBeamsizeX [lindex $optimizedEnergyParams 19]
   set minBeamsizeY [lindex $optimizedEnergyParams 20]
   set minCounts [lindex $optimizedEnergyParams 21]
   set scanPoints [lindex $optimizedEnergyParams 22]
   set scanStep [lindex $optimizedEnergyParams 23]
   set scanTime [lindex $optimizedEnergyParams 24]
   set ionChamberCheck [lindex $optimizedEnergyParams 25]
   set beamlineOpenStateDelay [lindex $optimizedEnergyParams 26]
   set injectionStateCheck [lindex $optimizedEnergyParams 27]
   set injectionStateDelay [lindex $optimizedEnergyParams 28]
   set beamHappyCheck [lindex $optimizedEnergyParams 29]
   set lastOptimizedDetectorZ [lindex $optimizedEnergyParams 30]
   set detectorZTolerance [lindex $optimizedEnergyParams 31]
   set spearCurrentCheck [lindex $optimizedEnergyParams 32]
   set minCurrent [lindex $optimizedEnergyParams 33]


	#inform observers of the change 
	updateRegisteredComponents state 
	updateRegisteredComponents message 
	updateRegisteredComponents trackingEnable 
	updateRegisteredComponents optimizeEnable
	updateRegisteredComponents beamlineOpenCheck
	updateRegisteredComponents resetEnergyAfterOptimize 
	updateRegisteredComponents lastOptimizedPosition
	updateRegisteredComponents lastOptimizedDetectorZ
	updateRegisteredComponents lastOptimizedTime
	updateRegisteredComponents energyTolerance
	updateRegisteredComponents detectorZTolerance
	updateRegisteredComponents optimizeTimeout
	updateRegisteredComponents lastOptimizedTablePosition
	updateRegisteredComponents flux
	updateRegisteredComponents wmin
	updateRegisteredComponents glc
	updateRegisteredComponents grc
	updateRegisteredComponents ionChamber 
	updateRegisteredComponents minBeamsizeX
	updateRegisteredComponents minBeamsizeY
	updateRegisteredComponents minCounts
	updateRegisteredComponents scanPoints 
	updateRegisteredComponents scanStep
	updateRegisteredComponents scanTime
	updateRegisteredComponents ionChamberCheck
	updateRegisteredComponents beamlineOpenStateDelay
	updateRegisteredComponents injectionStateCheck
	updateRegisteredComponents injectionStateDelay
	updateRegisteredComponents beamHappyCheck
	updateRegisteredComponents spearCurrentCheck
	updateRegisteredComponents minCurrent
}


####################
#  GUI
######################
class DCS::OptimizedEnergyGui {
 	inherit ::itk::Widget DCS::Component

    itk_option define -mdiHelper mdiHelper MdiHelper ""

	# protected methods
	protected method constructParameterEntryPanel

   private variable m_deviceFactory
   private variable m_optimizeEnergyParamsObj
    private variable m_refObj
    private variable m_shadowRef
    private variable m_allState

   private method setEntryComponentDirectly
   private variable m_logger

   public method changeTrackingEnable
   public method changeOptimizeEnable
   public method changeBeamlineOpenCheck
   public method changeResetEnergyAfterOptimize
   public method changeLastOptimizedPosition
   public method changeLastOptimizedTime
   public method changeEnergyTolerance
   public method changeDetectorZTolerance
   public method changeOptimizeTimeout
   public method changeFlux
   public method changeWmin
   public method changeGlc
   public method changeGrc
   public method changeIonChamber
   public method changeMinBeamsizeX
   public method changeMinBeamsizeY
   public method changeMinCounts
   public method changeScanPoints
   public method changeScanStep
   public method changeScanTime
   public method changeIonChamberCheck
   public method changeDelay
   public method changeInjectionCheck
   public method changeInjectionDelay
   public method changeBeamHappyCheck
   public method changeSpearCurrentCheck
   public method changeMinCurrent
   public method handleWebClick
   public method copyFromCurrent
   public method openCurrent

	constructor { obj ref_obj args } {

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      set m_optimizeEnergyParamsObj $obj
      set m_refObj $ref_obj

        if {$obj == $ref_obj} {
            set m_shadowRef 1
            set m_allState normal
        } else {
            set m_shadowRef 0
            set m_allState disabled
        }


      set m_logger [DCS::Logger::getObject]

		# construct the parameter widgets
		constructParameterEntryPanel

      eval itk_initialize $args

      ::mediator register $this $m_optimizeEnergyParamsObj trackingEnable changeTrackingEnable 
      ::mediator register $this $m_optimizeEnergyParamsObj optimizeEnable changeOptimizeEnable
      ::mediator register $this $m_optimizeEnergyParamsObj beamlineOpenCheck changeBeamlineOpenCheck
      ::mediator register $this $m_optimizeEnergyParamsObj resetEnergyAfterOptimize changeResetEnergyAfterOptimize
      ::mediator register $this $m_optimizeEnergyParamsObj energyTolerance changeEnergyTolerance
      ::mediator register $this $m_optimizeEnergyParamsObj detectorZTolerance changeDetectorZTolerance
      ::mediator register $this $m_optimizeEnergyParamsObj optimizeTimeout changeOptimizeTimeout
      ::mediator register $this $m_optimizeEnergyParamsObj flux changeFlux
      ::mediator register $this $m_optimizeEnergyParamsObj wmin changeWmin
      ::mediator register $this $m_optimizeEnergyParamsObj glc changeGlc
      ::mediator register $this $m_optimizeEnergyParamsObj grc changeGrc
      ::mediator register $this $m_optimizeEnergyParamsObj ionChamber changeIonChamber
      ::mediator register $this $m_optimizeEnergyParamsObj minBeamsizeX changeMinBeamsizeX
      ::mediator register $this $m_optimizeEnergyParamsObj minBeamsizeY changeMinBeamsizeY
      ::mediator register $this $m_optimizeEnergyParamsObj minCounts changeMinCounts
      ::mediator register $this $m_optimizeEnergyParamsObj scanPoints changeScanPoints
      ::mediator register $this $m_optimizeEnergyParamsObj scanStep changeScanStep
      ::mediator register $this $m_optimizeEnergyParamsObj scanTime changeScanTime
      ::mediator register $this $m_optimizeEnergyParamsObj ionChamberCheck changeIonChamberCheck
      ::mediator register $this $m_optimizeEnergyParamsObj beamlineOpenStateDelay changeDelay
      ::mediator register $this $m_optimizeEnergyParamsObj injectionStateCheck changeInjectionCheck
      ::mediator register $this $m_optimizeEnergyParamsObj injectionStateDelay changeInjectionDelay
      ::mediator register $this $m_optimizeEnergyParamsObj beamHappyCheck changeBeamHappyCheck
      ::mediator register $this $m_optimizeEnergyParamsObj spearCurrentCheck changeSpearCurrentCheck
      ::mediator register $this $m_optimizeEnergyParamsObj minCurrent changeMinCurrent
      
      $itk_component(message) configure -component $m_optimizeEnergyParamsObj
      $itk_component(message) configure -attribute message

    announceExist 
	}

	destructor {
	}
}

body DCS::OptimizedEnergyGui::setEntryComponentDirectly { component_ value_ } {
   $itk_component($component_) setValue $value_ 1
}

body DCS::OptimizedEnergyGui::changeTrackingEnable { - targetReady_ - x - } {
	$itk_component(trackingEnable) setValue $x
	$itk_component(trackingEnable) updateTextColor
}

body DCS::OptimizedEnergyGui::changeOptimizeEnable { - targetReady_ - x - } {
	$itk_component(optimizeEnable) setValue $x
	$itk_component(optimizeEnable) updateTextColor
}

body DCS::OptimizedEnergyGui::changeBeamlineOpenCheck { - targetReady_ - x - } {
	$itk_component(beamlineOpenCheck) setValue $x
	$itk_component(beamlineOpenCheck) updateTextColor
}

body DCS::OptimizedEnergyGui::changeResetEnergyAfterOptimize { - targetReady_ - x - } {
	$itk_component(resetEnergyAfterOptimize) setValue $x
	$itk_component(resetEnergyAfterOptimize) updateTextColor
}


body DCS::OptimizedEnergyGui::changeEnergyTolerance { - targetReady_ - x - } {
	setEntryComponentDirectly energyTolerance $x
}
body DCS::OptimizedEnergyGui::changeDetectorZTolerance { - targetReady_ - x - } {
	setEntryComponentDirectly detectorZTolerance $x
}

body DCS::OptimizedEnergyGui::changeOptimizeTimeout { - targetReady_ - x - } {
	setEntryComponentDirectly optimizeTimeout $x
}

body DCS::OptimizedEnergyGui::changeFlux { - targetReady_ - x - } {
	setEntryComponentDirectly flux $x
}


body DCS::OptimizedEnergyGui::changeWmin { - targetReady_ - x - } {
	setEntryComponentDirectly wmin $x
}

body DCS::OptimizedEnergyGui::changeGlc { - targetReady_ - x - } {
	setEntryComponentDirectly glc $x
}

body DCS::OptimizedEnergyGui::changeGrc { - targetReady_ - x - } {
	setEntryComponentDirectly grc $x
}

body DCS::OptimizedEnergyGui::changeIonChamber { - targetReady_ - x - } {
	setEntryComponentDirectly signal $x
}

body DCS::OptimizedEnergyGui::changeMinBeamsizeX { - targetReady_ - x - } {
	setEntryComponentDirectly minBeamsizeX $x
}

body DCS::OptimizedEnergyGui::changeMinBeamsizeY { - targetReady_ - x - } {
	setEntryComponentDirectly minBeamsizeY $x
}

body DCS::OptimizedEnergyGui::changeMinCounts { - targetReady_ - x - } {
	setEntryComponentDirectly minCounts $x
}

body DCS::OptimizedEnergyGui::changeScanPoints { - targetReady_ - x - } {
	setEntryComponentDirectly scanPoints $x
}

body DCS::OptimizedEnergyGui::changeScanStep { - targetReady_ - x - } {
	setEntryComponentDirectly scanStep $x
}

body DCS::OptimizedEnergyGui::changeScanTime { - targetReady_ - x - } {
	setEntryComponentDirectly scanTime $x
}

body DCS::OptimizedEnergyGui::changeIonChamberCheck { - targetReady_ - x - } {
	$itk_component(ionChamberCheck) setValue $x
	$itk_component(ionChamberCheck) updateTextColor
}
body DCS::OptimizedEnergyGui::changeDelay { - targetReady_ - x - } {
	setEntryComponentDirectly openStateDelay $x
}
body DCS::OptimizedEnergyGui::changeInjectionCheck { - targetReady_ - x - } {
	$itk_component(injectionCheck) setValue $x
	$itk_component(injectionCheck) updateTextColor
}
body DCS::OptimizedEnergyGui::changeInjectionDelay { - targetReady_ - x - } {
	setEntryComponentDirectly injectionDelay $x
}
body DCS::OptimizedEnergyGui::changeBeamHappyCheck { - targetReady_ - x - } {
	$itk_component(beamHappyCheck) setValue $x
	$itk_component(beamHappyCheck) updateTextColor
}
body DCS::OptimizedEnergyGui::changeSpearCurrentCheck { - targetReady_ - x - } {
	$itk_component(spearCurrentCheck) setValue $x
	$itk_component(spearCurrentCheck) updateTextColor
}
body DCS::OptimizedEnergyGui::changeMinCurrent { - targetReady_ - x - } {
	setEntryComponentDirectly minCurrent $x
}
body DCS::OptimizedEnergyGui::constructParameterEntryPanel { } {

	global env

    set sigName [::config getBeamGoodSignal]

   itk_component add enableFrame {
      ::iwidgets::labeledframe $itk_interior.ef -labeltext "Enable / Disable " -labelfont "helvetica -16 bold" -foreground blue
   } {}

   set ring [$itk_component(enableFrame) childsite]

    itk_component add web {
        DCS::Button $itk_interior.buttonWeb \
        -text {Web Help} -width 10\
        -foreground blue \
        -padx 0 -activeClientOnly 0 -debounceTime 10000 \
        -command "$this handleWebClick"
    } {
    }


	itk_component add trackingEnable {
		DCS::Checkbutton $ring.te \
            -state $m_allState \
			 -text "Enable energy motion during data collection" \
			 -activeClientOnly 1 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_refObj trackingEnable" \
         -command "$m_optimizeEnergyParamsObj setTrackingEnable %s" 
	} {}

	itk_component add optimizeEnable {
		DCS::Checkbutton $ring.oe \
            -state $m_allState \
			 -text "Enable Table Optimizations" \
			 -activeClientOnly 1 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_refObj optimizeEnable" \
         -command "$m_optimizeEnergyParamsObj setOptimizeEnable %s" 
	} {}

   itk_component add beamCheck {
      ::iwidgets::labeledframe $itk_interior.bc -labeltext "How to determine that beam is good in the hutch" -labelfont "helvetica -16 bold" -foreground blue
   } {}

   set ring [$itk_component(beamCheck) childsite]

	itk_component add beamlineOpenCheck {
		DCS::Checkbutton $ring.boc \
            -state $m_allState \
			 -text "Check SPEAR" \
            -width 22 \
			 -activeClientOnly 1 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_refObj beamlineOpenCheck" \
         -command "$m_optimizeEnergyParamsObj setBeamlineOpenCheck %s" 
	} {}

	itk_component add injectionCheck {
		DCS::Checkbutton $ring.injChk \
            -state $m_allState \
			-text "Check Injection" \
            -width 22 \
			-activeClientOnly 1 \
            -systemIdleOnly 0 \
			-shadowReference $m_shadowRef \
            -reference "$m_refObj injectionStateCheck" \
            -command "$m_optimizeEnergyParamsObj setInjectionCheck %s" 
	} {}

	itk_component add ionChamberCheck {
		DCS::Checkbutton $ring.icc \
            -state $m_allState \
			-text "Check $sigName reading" \
            -width 20 \
			-activeClientOnly 1 \
            -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_refObj ionChamberCheck" \
         -command "$m_optimizeEnergyParamsObj setIonChamberCheck %s" 
	} {}

    itk_component add openStateDelay {
        DCS::Entry $ring.delay \
        -state $m_allState \
        -promptText "Optics Temp. Stabilization Delay" \
        -promptWidth 35 \
         -entryWidth 10 	\
        -entryType int \
        -entryJustify right \
        -units "seconds" \
        -shadowReference 0 \
        -systemIdleOnly 1 \
        -activeClientOnly 1 \
        -reference "$m_refObj beamlineOpenStateDelay" \
        -onSubmit "$m_optimizeEnergyParamsObj setOpenStateDelay %s" 
    } {
    }

    itk_component add injectionDelay {
        DCS::Entry $ring.inj_delay \
        -state $m_allState \
        -promptText "Optics Temp. Stabilization Delay" \
        -promptWidth 35 \
        -entryWidth 10 	\
        -entryType int \
        -entryJustify right \
        -units "seconds" \
        -shadowReference 0 \
        -systemIdleOnly 1 \
        -activeClientOnly 1 \
        -reference "$m_refObj injectionStateDelay" \
        -onSubmit "$m_optimizeEnergyParamsObj setInjectionDelay %s" 
    } {
    }

   itk_component add minCounts {
      DCS::Entry $ring.mc -promptText "Minimum Counts on $sigName. " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType float \
         -entryJustify right \
         -units "counts  " \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj minCounts" \
         -onSubmit "$m_optimizeEnergyParamsObj setMinCounts %s" 
   } {}
    
	itk_component add beamHappyCheck {
		DCS::Checkbutton $ring.beamhappyChk \
            -state $m_allState \
			-text "Check Beam Happy" \
            -width 22 \
			-activeClientOnly 1 \
            -systemIdleOnly 0 \
			-shadowReference $m_shadowRef \
            -reference "$m_refObj beamHappyCheck" \
            -command "$m_optimizeEnergyParamsObj setBeamHappyCheck %s" 
	} {}

	itk_component add spearCurrentCheck {
		DCS::Checkbutton $ring.spearCurrentChk \
            -state $m_allState \
			-text "Check Spear Current" \
            -width 22 \
			-activeClientOnly 1 \
            -systemIdleOnly 0 \
			-shadowReference $m_shadowRef \
            -reference "$m_refObj spearCurrentCheck" \
            -command "$m_optimizeEnergyParamsObj setSpearCurrentCheck %s" 
	} {}

   itk_component add minCurrent {
      DCS::Entry $ring.mcur -promptText "Minimum Spear Current" \
      -state $m_allState \
      -promptWidth 35 \
      -entryWidth 10 	\
      -entryType float \
      -entryJustify right \
      -units "mA" \
      -shadowReference 0 \
      -systemIdleOnly 0 \
      -activeClientOnly 1 \
      -reference "$m_refObj minCurrent" \
      -onSubmit "$m_optimizeEnergyParamsObj setMinCurrent %s" 
   } {}
    
   itk_component add optimizeTrigger {
      ::iwidgets::labeledframe $itk_interior.ot -labeltext "When to optimize table"  -labelfont "helvetica -16 bold" -foreground blue
   } {}

   set ring [$itk_component(optimizeTrigger) childsite]

   itk_component add energyTolerance {
      DCS::Entry $ring.et \
            -state $m_allState \
         -promptText "After energy change greater than: " -promptWidth 38 -units "eV" \
         -entryType positiveFloat \
         -entryJustify right \
         -entryWidth 10 \
         -decimalPlaces 2 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -shadowReference 0 \
         -reference "$m_refObj energyTolerance" \
         -onSubmit "$m_optimizeEnergyParamsObj setEnergyTolerance %s" 
   } {}
		
   # make the width entry
   itk_component add optimizeTimeout {
      DCS::Entry $ring.ot -promptText "After timeout of: " \
            -state $m_allState \
         -promptWidth 38 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 2 \
         -units "s" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj optimizeTimeout" \
         -onSubmit "$m_optimizeEnergyParamsObj setOptimizeTimeout %s" 
   } {}

    itk_component add detectorZTolerance {
        DCS::Entry $ring.dzt \
        -state $m_allState \
        -promptText "After detector_z change greater than: " \
        -promptWidth 38 \
        -units "mm" \
        -entryType positiveFloat \
        -entryJustify right \
        -entryWidth 10 \
        -decimalPlaces 2 \
        -systemIdleOnly 1 \
        -activeClientOnly 1 \
        -shadowReference 0 \
        -reference "$m_refObj detectorZTolerance" \
        -onSubmit "$m_optimizeEnergyParamsObj setDetectorZTolerance %s" 
   } {}

   itk_component add analyzePeak {
      ::iwidgets::labeledframe $itk_interior.ap -labeltext "Parameters to analyze peak" -labelfont "helvetica -16 bold" -foreground blue
   } {}

   set ring [$itk_component(analyzePeak) childsite]

   # make the width entry
   itk_component add flux {
      DCS::Entry $ring.flux -promptText "Flux: " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 4 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj flux" \
         -onSubmit "$m_optimizeEnergyParamsObj setFlux %s" 
   } {}

   # make the width entry
   itk_component add wmin {
      DCS::Entry $ring.sw -promptText "Minimum Peak Width: " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj wmin" \
         -onSubmit "$m_optimizeEnergyParamsObj setWmin %s" 
   } {}

   # make the width entry
   itk_component add glc {
      DCS::Entry $ring.glc -promptText "Scan glc: " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj glc" \
         -onSubmit "$m_optimizeEnergyParamsObj setGlc %s" 
   } {}

   # make the width entry
   itk_component add grc {
      DCS::Entry $ring.grc -promptText "Scan grc: " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType float \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj grc" \
         -onSubmit "$m_optimizeEnergyParamsObj setGrc %s" 
   } {}
    
   itk_component add scanParameters {
      ::iwidgets::labeledframe $itk_interior.sp -labeltext "Parameters for table scan" -labelfont "helvetica -16 bold" -foreground blue
   } {}

   set ring [$itk_component(scanParameters) childsite]

    if {$m_allState == "normal"} {
	    itk_component add signal {
		    DCS::MenuEntry $ring.sig1 -entryType string \
                -state $m_allState \
			    -entryWidth 12 \
                -showEntry 0 \
			    -promptText "Signal:"  \
                -promptWidth 11 \
			    -reference "$m_refObj ionChamber" \
                -onSubmit "$m_optimizeEnergyParamsObj setIonChamber %s" \
                -activeClientOnly 1 \
	            -systemIdleOnly 0
	    } {
	    }

        #create the menu selection for the signal list
	    set realSignalList [$m_deviceFactory getSignalList]
		
	    $itk_component(signal) configure -menuChoices $realSignalList
    } else {
	    itk_component add signal {
		    DCS::Entry $ring.sig1 -entryType string \
                -state $m_allState \
			    -entryWidth 12 \
			    -promptText "Signal:"  \
                -promptWidth 11 \
			    -reference "$m_refObj ionChamber" \
                -onSubmit "$m_optimizeEnergyParamsObj setIonChamber %s" \
                -activeClientOnly 1 \
	            -systemIdleOnly 0
	    } {
	    }
    }

   itk_component add scanPoints {
      DCS::Entry $ring.sp -promptText "Number of points in Scan:  " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType positiveInt \
         -entryJustify right \
         -units "steps" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj scanPoints" \
         -onSubmit "$m_optimizeEnergyParamsObj setScanPoints %s" 
   } {}
   
   # make the width entry
   itk_component add scanStep {
      DCS::Entry $ring.ss -promptText "Scan step size: " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj scanStep" \
         -onSubmit "$m_optimizeEnergyParamsObj setScanStep %s" 
   } {}
     

   # make the width entry
   itk_component add scanTime {
      DCS::Entry $ring.st -promptText "Scan time at each point: " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 2 \
         -units "s" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj scanTime" \
         -onSubmit "$m_optimizeEnergyParamsObj setScanTime %s" 
   } {}

   # make the width entry
   itk_component add minBeamsizeX {
      DCS::Entry $ring.bsx -promptText "Minimum beam width during scan: " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj minBeamsizeX" \
         -onSubmit "$m_optimizeEnergyParamsObj setMinBeamsizeX %s" 
   } {}
    

   # make the width entry
   itk_component add minBeamsizeY {
      DCS::Entry $ring.bsy -promptText "Minimum beam height during scan: " \
            -state $m_allState \
         -promptWidth 35 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_refObj minBeamsizeY" \
         -onSubmit "$m_optimizeEnergyParamsObj setMinBeamsizeY %s" 
   } {}

   itk_component add advanced {
      ::iwidgets::labeledframe $itk_interior.adv -labeltext "Advanced parameters" -labelfont "helvetica -16 bold" -foreground blue
   } {}

   set ring [$itk_component(advanced) childsite]

	itk_component add resetEnergyAfterOptimize {
		DCS::Checkbutton $ring.reao \
            -state $m_allState \
			 -text "Reset Energy after Optimize" \
			 -activeClientOnly 0 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_refObj resetEnergyAfterOptimize" \
         -command "$m_optimizeEnergyParamsObj setResetEnergyAfterOptimize %s" 
	} {}

    itk_component add current {
        frame $itk_interior.fCurrent
    } {
    }

    itk_component add copy_current {
        DCS::Button $itk_interior.fCurrent.copy \
        -text {Copy From Current Settings} \
        -background yellow \
        -width 26\
        -padx 0 \
        -activeClientOnly 1 \
        -systemIdleOnly 1 \
        -debounceTime 1000 \
        -command "$this copyFromCurrent"
    } {
    }

    itk_component add open_current {
        button $itk_interior.fCurrent.open \
        -text {View Current Settings} \
        -command "$this openCurrent"
    } {
    }
    pack $itk_component(copy_current) -side left
    pack $itk_component(open_current) -side left

   set ring $itk_interior
	itk_component add message {
		DCS::Label $ring.message -promptText "Status: " 
	} {}



	grid $itk_component(enableFrame) -row 0 -column 0 -sticky news
	grid $itk_component(trackingEnable) -row 0 -column 0  -sticky w
	grid $itk_component(optimizeEnable) -row 1 -column 0 -sticky w

	grid $itk_component(web) -row 0 -column 1 

	grid $itk_component(optimizeTrigger) -row 1 -column 0 -sticky news
	grid $itk_component(energyTolerance) -row 1 -column 0  -sticky w
	grid $itk_component(optimizeTimeout) -row 2 -column 0 -sticky w
	grid $itk_component(detectorZTolerance) -row 3 -column 0  -sticky w

	grid $itk_component(beamCheck) -row 1 -column 1 -sticky news
	grid $itk_component(beamlineOpenCheck) -row 0 -column 0 -sticky e
	grid $itk_component(openStateDelay) -row 1 -column 0 -sticky e
	grid $itk_component(injectionCheck) -row 2 -column 0 -sticky e
	grid $itk_component(injectionDelay) -row 3 -column 0 -sticky e
	grid $itk_component(spearCurrentCheck) -row 4 -column 0 -sticky e
	grid $itk_component(minCurrent) -row 5 -column 0 -sticky e
	grid $itk_component(ionChamberCheck) -row 6 -column 0 -sticky e
	grid $itk_component(minCounts) -row 7 -column 0 -sticky e

    global gBeamHappyExists
    if {$gBeamHappyExists} {
	    grid $itk_component(beamHappyCheck) -row 8 -column 0 -sticky e
    }

	grid $itk_component(scanParameters) -row 2 -column 0 -sticky news
	grid $itk_component(signal) -row 0 -column 0 -sticky w
	grid $itk_component(scanPoints) -row 1 -column 0 -sticky w
	grid $itk_component(scanStep) -row 2 -column 0 -sticky w
	grid $itk_component(scanTime) -row 3 -column 0 -sticky w
	grid $itk_component(minBeamsizeX) -row 4 -column 0 -sticky w
	grid $itk_component(minBeamsizeY) -row 5 -column 0 -sticky w

	grid $itk_component(analyzePeak) -row 2 -column 1 -sticky news
	grid $itk_component(flux) -row 0 -column 0 -sticky w
	grid $itk_component(wmin) -row 1 -column 0 -sticky w
	grid $itk_component(glc) -row 2 -column 0 -sticky w
	grid $itk_component(grc) -row 3 -column 0 -sticky w


	grid $itk_component(advanced) -row 3 -column 0 -sticky news
	grid $itk_component(resetEnergyAfterOptimize) -row 0 -column 0 -sticky w

    if {!$m_shadowRef} {
	    grid $itk_component(current) -row 3 -column 1
    }

	grid $itk_component(message) -row 4 -column 0 -columnspan 2
}
body DCS::OptimizedEnergyGui::copyFromCurrent { } {
    if {$m_shadowRef} {
        log_error Telll software programmer it is a bug
        return
    }
    set contents [$m_refObj getContents]
    $m_optimizeEnergyParamsObj submitNewParameters $contents
    ###same as $m_optimizeEnergyParamsObj sendContentsToServer $contents

}
body DCS::OptimizedEnergyGui::openCurrent { } {
    $itk_option(-mdiHelper) openToolChest optimizedEnergyParameterGui
}

body DCS::OptimizedEnergyGui::handleWebClick {} {
   if {[catch {
      openWebWithBrowser [::config getStr document.optimized_energy]
   } result]} {
      log_error "start mozilla failed: $result"
   } else {
      $itk_component(web) configure -state disabled
      after 10000 [list $itk_component(web) configure -state normal]
   }
}

