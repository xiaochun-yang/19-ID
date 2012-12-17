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

package provide BLUICECollectTimedBurst 1.0

# load the DCS packages
package require DCSDevice
package require DCSDeviceView

class DCS::MaterialScienceCollectView {
	inherit ::itk::Widget

	# public methods
	constructor { args } {
		global env

       #the paned windows organizes all of the graphing functions in one place
       itk_component add pw {
           iwidgets::panedwindow $itk_interior.pw -orient horizontal 
       } {
       }
       

      $itk_component(pw) add DiffViewer -minimum 400 
      $itk_component(pw) add DoseModeViewer -minimum 100 
      
      set collectView [$itk_component(pw) childsite 0] 
      set snapshotView [$itk_component(pw) childsite 1]
        
		itk_component add collectView {
			::DCS::CollectTimedBurstView $collectView.1
		} {
		}


		itk_component add snapshotView {
			::DCS::DetectorControl $snapshotView.1
		} {
		}
        
		eval itk_initialize $args

      pack $itk_component(pw)  -expand 1 -fill both -side left
      pack $itk_component(snapshotView)  -expand 1 -fill both -side left
      pack $itk_component(collectView)  -expand 1 -fill both -side left

      $itk_component(pw) fraction 70 30
	}
}




class DCS::CollectTimedBurst {
   inherit DCS::Component 

	public method configureString
	public method sendContentsToServer

   private variable m_deviceFactory
   private variable m_collectTimedBurstParam 

   public variable status "inactive"
   public variable state 
   public variable message
   public variable username
   public variable sessionID
   public variable scanMotor
   public variable directory
   public variable fileRoot
   public variable startPos
   public variable numPoints
   public variable stepSize
   public variable timeInterval
   public variable numSets
   public variable exposureTime
   public variable numImages
   public variable controlSystem "::dcss"

   #public method setScanMotor
   public method setDirectory
   public method setFileRoot
   public method setBeamSize
   public method setStartPos
   public method setNumPoints
   public method setStepSize
   public method setTimeInterval
   public method setNumSets
   public method setExposureTime
   public method setNumImages

	public method handleScanDefinitionChange
	public method submitNewDefinition

   #variable for storing singleton object
   private common m_theObject {} 
   public proc getObject
   public method enforceUniqueness

	# call base class constructor
	constructor { args } {

		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 status {cget -status} \
					 contents { getContents } \
					 state {cget -state} \
					 message { cget -message } \
					 username {cget -username} \
					 sessionID {cget -sessionID} \
					 scanMotor { cget -scanMotor } \
					 directory { cget -directory } \
					 fileRoot { cget -fileRoot } \
					 startPos { cget -startPos } \
					 numPoints { cget -numPoints } \
					 stepSize { cget -stepSize } \
					 timeInterval { cget -timeInterval } \
					 numSets { cget -numSets } \
					 exposureTime { cget -exposureTime } \
					 numImages { cget -numImages }
			 }
	} {
		
      enforceUniqueness

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      
      set m_collectTimedBurstParam [$m_deviceFactory createString collectTimedBurstParam]
      ::mediator register $this $m_collectTimedBurstParam contents handleScanDefinitionChange

		eval configure $args
      
		announceExist
	}

}

#return the singleton object
body DCS::CollectTimedBurst::getObject {} {
   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto]
   }

   return $m_theObject
}

#this function should be called by the constructor
body DCS::CollectTimedBurst::enforceUniqueness {} {
   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if ![string match "${current}::getObject" $caller] {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}


body DCS::CollectTimedBurst::submitNewDefinition { contents_ } {
   $m_collectTimedBurstParam sendContentsToServer $contents_
}


#body DCS::CollectTimedBurst::setScanMotor  { } {
#   set motorName [$itk_component(scanMotor) get]
#   log_warning $motorName

#   submitNewDefinition  "$state \{$message\} $username $sessionID $motorName $directory $fileRoot $startPos $numPoints $stepSize $timeInterval $numSets $exposureTime $numImages" 
#}

body DCS::CollectTimedBurst::setDirectory  { directory_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $scanMotor $directory_ $fileRoot $startPos $numPoints $stepSize $timeInterval $numSets $exposureTime $numImages" 
}

body DCS::CollectTimedBurst::setFileRoot  { fileRoot_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $scanMotor $directory $fileRoot_ $startPos $numPoints $stepSize $timeInterval $numSets $exposureTime $numImages" 
}

body DCS::CollectTimedBurst::setStartPos  {startPos_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $scanMotor $directory $fileRoot [lindex $startPos_ 0] $numPoints $stepSize $timeInterval $numSets $exposureTime $numImages" 
}

body DCS::CollectTimedBurst::setNumPoints  {numPoints_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $scanMotor $directory $fileRoot $startPos [lindex $numPoints_ 0] $stepSize $timeInterval $numSets $exposureTime $numImages" 
}

body DCS::CollectTimedBurst::setStepSize  {stepSize_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $scanMotor $directory $fileRoot $startPos $numPoints [lindex $stepSize_ 0] $timeInterval $numSets $exposureTime $numImages" 
}

body DCS::CollectTimedBurst::setTimeInterval  {timeInterval_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $scanMotor $directory $fileRoot $startPos $numPoints $stepSize [lindex $timeInterval_ 0] $numSets $exposureTime $numImages" 
}

body DCS::CollectTimedBurst::setNumSets  { numSets_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $scanMotor $directory $fileRoot $startPos $numPoints $stepSize $timeInterval [lindex $numSets_ 0] $exposureTime $numImages" 
}

body DCS::CollectTimedBurst::setExposureTime  { exposureTime_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $scanMotor $directory $fileRoot $startPos $numPoints $stepSize $timeInterval $numSets [lindex $exposureTime_ 0] $numImages" 
}

body DCS::CollectTimedBurst::setNumImages  { numImages_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $scanMotor $directory $fileRoot $startPos $numPoints $stepSize $timeInterval $numSets $exposureTime [lindex $numImages_ 0]" 
}


body DCS::CollectTimedBurst::handleScanDefinitionChange { - targetReady_ - collectTimedBurstParam - } {

	if { ! $targetReady_} return
   
   #global env	
   #set username $env(USER)
   #set sessionID [ $itk_option(-controlSystem) getSessionId ]
   set username [$controlSystem getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set sessionID SID
    } else {
        set sessionID PRIVATE[$controlSystem getSessionId]
    }

   set state [lindex $collectTimedBurstParam 0]
   set message [lindex $collectTimedBurstParam 1]
   #set username [lindex $collectTimedBurstParam 2]
   #set sessionID [lindex $collectTimedBurstParam 3]
   set scanMotor [lindex $collectTimedBurstParam 4]
   set directory [lindex $collectTimedBurstParam 5]
   set fileRoot [lindex $collectTimedBurstParam 6]
   set startPos [lindex $collectTimedBurstParam 7]
   set numPoints [lindex $collectTimedBurstParam 8]
   set stepSize [lindex $collectTimedBurstParam 9]
   set timeInterval [lindex $collectTimedBurstParam 10]
   set numSets [lindex $collectTimedBurstParam 11]
   set exposureTime [lindex $collectTimedBurstParam 12]
   set numImages [lindex $collectTimedBurstParam 13]


	#inform observers of the change 
	updateRegisteredComponents state 
	updateRegisteredComponents message 
	updateRegisteredComponents username 
	updateRegisteredComponents sessionID 
	updateRegisteredComponents scanMotor
	updateRegisteredComponents directory
	updateRegisteredComponents fileRoot
	updateRegisteredComponents startPos
	updateRegisteredComponents numPoints
	updateRegisteredComponents stepSize
	updateRegisteredComponents timeInterval
	updateRegisteredComponents numSets
	updateRegisteredComponents exposureTime
	updateRegisteredComponents numImages
}




####################
#  GUI
######################
class DCS::CollectTimedBurstView {
 	inherit DCS::Component ::itk::Widget

	# protected methods
	protected method constructControlPanel
	public method updatePosition
	public method startCollectTimedBurst

   private variable m_deviceFactory
   private variable m_collectTimedBurstObj

   private method setEntryComponentDirectly
#   private method setComboComponentDirectly
   private variable m_logger

   public method changeFileRoot
   #public method changeScanMotor
   public method changeDirectory
   public method changeNumImages
   public method changeBeamSize
   public method changeStartPos
   public method changeNumPoints
   public method changeStepSize
   public method changeTimeInterval
   public method changeNumSets
   public method changeExposureTime

   itk_option define -controlSystem controlSystem ControlSystem "::dcss"

	constructor { args } {

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      set m_collectTimedBurstObj [DCS::CollectTimedBurst::getObject]
      set m_logger [DCS::Logger::getObject]

		# construct the parameter widgets
		constructControlPanel

      eval itk_initialize $args

      #bind the abort command
      $itk_component(abortButton) configure -command "$itk_option(-controlSystem) abort"


      ::mediator register $this $m_collectTimedBurstObj fileRoot changeFileRoot 
    #  ::mediator register $this $m_collectTimedBurstObj scanMotor changeScanMotor
      ::mediator register $this $m_collectTimedBurstObj directory changeDirectory
      ::mediator register $this $m_collectTimedBurstObj numImages changeNumImages
      ::mediator register $this $m_collectTimedBurstObj startPos changeStartPos
      ::mediator register $this $m_collectTimedBurstObj numPoints changeNumPoints
      ::mediator register $this $m_collectTimedBurstObj stepSize changeStepSize
      ::mediator register $this $m_collectTimedBurstObj timeInterval changeTimeInterval
      ::mediator register $this $m_collectTimedBurstObj numSets changeNumSets
      ::mediator register $this $m_collectTimedBurstObj exposureTime changeExposureTime
      
      $itk_component(updateButton) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(scanButton) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      #$itk_component(scanMotor) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(directory) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(fileRoot) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(startPos) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(numPoints) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(stepSize) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(timeInterval) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(numImages) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(exposureTime) addInput "$m_collectTimedBurstObj state 0 {supporting device}"
      $itk_component(numSets) addInput "$m_collectTimedBurstObj state 0 {supporting device}"

      $itk_component(message) configure -component $m_collectTimedBurstObj
      $itk_component(message) configure -attribute message

    announceExist 
	}

	destructor {
	}

}

body DCS::CollectTimedBurstView::setEntryComponentDirectly { component_ value_ } {
   $itk_component($component_) setValue $value_ 1
}

#body DCS::CollectTimedBurstView::setComboComponentDirectly { component_ value_ } {
#   set scanMotor $value_
#   if {$value_ == "none"} {
#      $itk_component($component_) selection set 0
#   } elseif {$value_ == "gonio_phi"} {
#      $itk_component($component_) selection set 1
#   } elseif {$value_ == "sample_x"} {
#      $itk_component($component_) selection set 2
#   } elseif {$value_ == "sample_y"} {
#      $itk_component($component_) selection set 3
#   } elseif {$value_ == "sample_z"} {
#      $itk_component($component_) selection set 4
#   } elseif {$value_ == "detector_vert"} {
#      $itk_component($component_) selection set 5
#   } 
#   log_warning $value_
#}

body DCS::CollectTimedBurstView::changeFileRoot { - targetReady_ - x - } {
	setEntryComponentDirectly fileRoot $x
}

#body DCS::CollectTimedBurstView::changeScanMotor { - targetReady_ - x - } {
#	setComboComponentDirectly scanMotor $x
#}

body DCS::CollectTimedBurstView::changeDirectory { - targetReady_ - x - } {
	setEntryComponentDirectly directory $x
}

body DCS::CollectTimedBurstView::changeNumImages { - targetReady_ - x - } {
	setEntryComponentDirectly numImages $x
}

body DCS::CollectTimedBurstView::changeStartPos { - targetReady_ - x - } {
	setEntryComponentDirectly startPos $x
}

body DCS::CollectTimedBurstView::changeNumPoints { - targetReady_ - x - } {
	setEntryComponentDirectly numPoints $x
}

body DCS::CollectTimedBurstView::changeStepSize { - targetReady_ - x - } {
	setEntryComponentDirectly stepSize $x
}

body DCS::CollectTimedBurstView::changeTimeInterval { - targetReady_ - x - } {
	setEntryComponentDirectly timeInterval $x
}


body DCS::CollectTimedBurstView::changeNumSets { - targetReady_ - x - } {
	setEntryComponentDirectly numSets $x
}

body DCS::CollectTimedBurstView::changeExposureTime { - targetReady_ - x - } {
	setEntryComponentDirectly exposureTime $x
}


body DCS::CollectTimedBurstView::constructControlPanel { } {

	global env

   set ring $itk_interior

   # make the detector mode entry
   itk_component add mode {
      DCS::DetectorModeMenu $ring.dm -entryWidth 20 \
         -promptWidth 15 \
         -showEntry 0 \
         -entryType string \
         -entryJustify center \
         -promptText "Detector: " \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 
   } {
      keep -font
   }

   # make the scan motor entry
   itk_component add scanMotor {
      iwidgets::combobox $ring.sm -width 20 \
         -labeltext "       Scan Motor: " \
         -listheight 100 \
         -justify center \
   }
   #-command "$m_collectTimedBurstObj setScanMotor" 
   $ring.sm insert list end "none"
   $ring.sm insert list end "gonio_phi"
   $ring.sm insert list end "sample_x"
   $ring.sm insert list end "sample_y"
   $ring.sm insert list end "sample_z"
   $ring.sm insert list end "detector_vert"
   $ring.sm insert list end "detector_z_corr"
   $ring.sm selection set 0
   $ring.sm configure -editable 0

   itk_component add updateButton {
      DCS::Button $ring.u -command "$this updatePosition" \
         -text "Update"\
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -font "helvetica -14 bold" -width 7
   } {}

   itk_component add scanButton {
      DCS::Button $ring.c -command "$this startCollectTimedBurst" \
         -text "Start"\
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -font "helvetica -14 bold" -width 7
   } {}

   itk_component add abortButton {
      DCS::Button $ring.a \
 	  -text "Abort" \
          -background \#ffaaaa \
          -activebackground \#ffaaaa \
          -systemIdleOnly 0 \
          -activeClientOnly 0 \
          -font "helvetica -14 bold" -width 7
   } {}

   # make the data directory entry
   itk_component add directory {
      DCS::Entry $ring.dir \
         -entryType field \
         -entryWidth 24 \
         -entryJustify center \
         -entryMaxLength 128 \
         -promptText "Directory: " \
         -promptWidth 15 \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_collectTimedBurstObj directory" \
         -onSubmit "$m_collectTimedBurstObj setDirectory %s" 
   } {}

   # make the filename root entry
   itk_component add fileRoot {
      DCS::Entry $ring.filename \
         -entryType field \
         -entryWidth 20 \
         -entryJustify center \
         -entryMaxLength 128 \
         -promptText "File Root: " \
         -promptWidth 15 \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_collectTimedBurstObj fileRoot" \
         -onSubmit "$m_collectTimedBurstObj setFileRoot %s" 
   } {}

   itk_component add startPos {
      DCS::Entry $ring.start \
         -promptText "Start Position: " -promptWidth 15 \
         -entryJustify right \
         -entryWidth 24 	\
         -decimalPlaces 3 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -shadowReference 0 \
         -reference "$m_collectTimedBurstObj startPos" \
         -onSubmit "$m_collectTimedBurstObj setStartPos %s" 
   } {}
	
   itk_component add numPoints {
      DCS::Entry $ring.points \
         -promptText "Num Points: " -promptWidth 15 \
         -entryJustify right \
         -entryWidth 10 	\
         -decimalPlaces 2 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -shadowReference 0 \
         -reference "$m_collectTimedBurstObj numPoints" \
         -onSubmit "$m_collectTimedBurstObj setNumPoints %s" 
   } {}
	
   itk_component add stepSize {
      DCS::Entry $ring.step \
         -promptText "Step Size: " -promptWidth 15 \
         -entryJustify right \
         -entryWidth 10 	\
         -decimalPlaces 2 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -shadowReference 0 \
         -reference "$m_collectTimedBurstObj stepSize" \
         -onSubmit "$m_collectTimedBurstObj setStepSize %s" 
   } {}

   itk_component add timeInterval {
      DCS::Entry $ring.interval \
         -promptText "Time Interval: " -promptWidth 15 -units "s" \
         -entryType positiveFloat \
         -entryJustify right \
         -entryWidth 10 	\
         -decimalPlaces 2 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -shadowReference 0 \
         -reference "$m_collectTimedBurstObj timeInterval" \
         -onSubmit "$m_collectTimedBurstObj setTimeInterval %s" 
   } {}
		
   # make the exposure time entry
   itk_component add exposureTime {
      DCS::Entry $ring.time -promptText "Exposure Time: " \
         -promptWidth 15 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 2 \
         -units "s" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_collectTimedBurstObj exposureTime" \
         -onSubmit "$m_collectTimedBurstObj setExposureTime %s" 
   } {}

      itk_component add doseControlView {
         ::DCS::DoseControlView $itk_interior.dose
	   } {}



   # make the num of sets entry
   itk_component add numSets {
      DCS::Entry $ring.numsets -promptText "Num Sets: " \
         -promptWidth 15 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 0 \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_collectTimedBurstObj numSets" \
         -onSubmit "$m_collectTimedBurstObj setNumSets %s" 
   } {}

    # make the num of images per set entry
   itk_component add numImages {
      DCS::Entry $ring.numimages -promptText "Num Images/Set: " \
         -promptWidth 15 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 0 \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_collectTimedBurstObj numImages" \
         -onSubmit "$m_collectTimedBurstObj setNumImages %s" 
   } {}

  
	itk_component add message {
		DCS::Label $ring.message -promptText "Status: " -width 50 
	} {}

	itk_component add emptyLabel {
		DCS::Label $ring.el  -promptText "     "
	} {}

	itk_component add emptyLabel1 {
		DCS::Label $ring.el1  -promptText "     "
	} {}

	itk_component add emptyLabel2 {
		DCS::Label $ring.el2  -promptText "     "
	} {}

	itk_component add emptyLabel3 {
		DCS::Label $ring.el3  -promptText "     "
	} {}

	itk_component add emptyLabel4 {
		DCS::Label $ring.el4  -promptText "     "
	} {}

	itk_component add emptyLabel5 {
		DCS::Label $ring.el5  -promptText "     "
	} {}

	itk_component add titleLabel {
		DCS::Label $ring.tle  -promptText " Scheduled Scan Setup "
	} {}


	grid $itk_component(titleLabel) -row 0 -column 0 -columnspan 2
	grid $itk_component(emptyLabel5) -row 1 -column 0 -columnspan 2 

	grid $itk_component(mode) -row 2 -column 0 -columnspan 2 -sticky w
	grid $itk_component(scanMotor) -row 3 -column 0 -columnspan 2 -sticky w
	grid $itk_component(emptyLabel) -row 4 -column 0 -columnspan 2 

	grid $itk_component(directory) -row 5 -column 0 -columnspan 2 -sticky w
	grid $itk_component(fileRoot) -row 6 -column 0 -columnspan 2 -sticky w
	grid $itk_component(emptyLabel1) -row 7 -column 0 -columnspan 2 

	grid $itk_component(startPos) -row 8 -column 0 -columnspan 2 -sticky w
	grid $itk_component(updateButton) -row 8 -column 2 -sticky e
	grid $itk_component(numPoints) -row 9 -column 0 -columnspan 2 -sticky w
	grid $itk_component(stepSize) -row 10 -column 0 -columnspan 2 -sticky w
	grid $itk_component(emptyLabel2) -row 11 -column 0 -columnspan 2 

	grid $itk_component(timeInterval) -row 12 -column 0 -columnspan 1 -sticky w
	grid $itk_component(exposureTime) -row 13 -column 0 -columnspan 1 -sticky w
	grid $itk_component(emptyLabel3) -row 14 -column 0 -columnspan 2 
    grid $itk_component(doseControlView) -row 12 -column 2 -sticky w -rowspan 3

	grid $itk_component(numSets) -row 15 -column 0 -columnspan 2 -sticky w
	grid $itk_component(numImages) -row 16 -column 0 -columnspan 2 -sticky w
	grid $itk_component(emptyLabel4) -row 17 -column 0 -columnspan 2 

	grid $itk_component(scanButton) -row 18 -column 0 -sticky e 
	grid $itk_component(abortButton) -row 18 -column 1 -sticky w 
	grid $itk_component(emptyLabel5) -row 19 -column 0 -columnspan 2 
	grid $itk_component(message) -row 20 -column 0 -columnspan 5 -sticky e

}

body DCS::CollectTimedBurstView::updatePosition {} {

   set motorName [$itk_component(scanMotor) get]
   if {$motorName == "none"} {
      return
   } elseif {$motorName == "gonio_phi"} {
      set obj [$m_deviceFactory getObjectName gonio_phi]
      set pos [$obj getScaledPosition]
      set value [lindex $pos 0]
     puts "phi value: $value"
   } elseif {$motorName == "sample_x"} {
      set obj [$m_deviceFactory getObjectName sample_x]
      set pos [$obj getScaledPosition]
      set value [lindex $pos 0]
   } elseif {$motorName == "sample_y"} {
      set obj [$m_deviceFactory getObjectName sample_y]
      set pos [$obj getScaledPosition]
      set value [lindex $pos 0]
   } elseif {$motorName == "sample_z"} {
      set obj [$m_deviceFactory getObjectName sample_z]
      set pos [$obj getScaledPosition]
      set value [lindex $pos 0]
   } elseif {$motorName == "detector_vert"} {
      set obj [$m_deviceFactory getObjectName detector_vert]
      set pos [$obj getScaledPosition]
      set value [lindex $pos 0]
   } elseif {$motorName == "detector_z_corr"} {
      set obj [$m_deviceFactory getObjectName detector_z_corr]
      set pos [$obj getScaledPosition]
      set value [lindex $pos 0]
   } 

   $itk_component(startPos) setValue $value 1

}

body DCS::CollectTimedBurstView::startCollectTimedBurst {} {
	global env

    set rootDir [$itk_component(directory) get]
    
    if { [catch {file mkdir $rootDir} err] } {
        
        set msg "$env(USER) could not create directory $rootDir: $err"
        $m_logger logError $msg
        return
    }
        
    if { [file isdirectory $rootDir]==0 || [file writable $rootDir]==0 } {
        $m_logger logError "$env(USER) does not have permission to write to $rootDir."
        return
    }
    
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
    
   set detectorMode [$itk_component(mode) selectDetectorMode]
   set motorName [$itk_component(scanMotor) get]
   set collectTimedBurstOp [$m_deviceFactory createOperation collectTimedBurst] 

   $collectTimedBurstOp startOperation $detectorMode $motorName $SID
}


