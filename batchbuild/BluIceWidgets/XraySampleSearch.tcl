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

package provide BLUICEXraySampleSearch 1.0

# load the DCS packages
package require DCSDevice
package require DCSDeviceView


class DCS::XraySearchParams {
   inherit DCS::Component	

	public method configureString
	public method sendContentsToServer

   private variable m_deviceFactory
   private variable m_xraySearchParams 

   public variable status "inactive"
   public variable state 
   public variable message
   public variable username
   public variable sessionID
   public variable directory
   public variable fileRoot
   public variable beamSize_x
   public variable beamSize_y
   public variable scanWidth
   public variable scanHeight
   public variable exposureTime
   public variable delta
   public variable totalColumns
   public variable totalRows

   public method setDirectory
   public method setFileRoot
   public method setBeamSizeX
   public method setBeamSizeY
   public method setScanWidth
   public method setScanHeight
   public method setExposureTime
   public method setDelta

	public method handleSearchDefinitionChange
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
					 directory { cget -directory } \
					 fileRoot { cget -fileRoot } \
					 beamSize_x { cget -beamSize_x } \
					 beamSize_y { cget -beamSize_y } \
					 scanWidth { cget -scanWidth } \
					 scanHeight { cget -scanHeight } \
					 exposureTime { cget -exposureTime } \
					 delta { cget -delta } \
					 totalColumns { cget -totalColumns } \
					 totalRows { cget -totalRows }
			 }
	} {
		
      enforceUniqueness

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      
      set m_xraySearchParams [$m_deviceFactory createString xraySearchParams]
      ::mediator register $this $m_xraySearchParams contents handleSearchDefinitionChange

		eval configure $args
      
		announceExist
	}
}

#return the singleton object
body DCS::XraySearchParams::getObject {} {
   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto]
   }

   return $m_theObject
}

#this function should be called by the constructor
body DCS::XraySearchParams::enforceUniqueness {} {
   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if ![string match "${current}::getObject" $caller] {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}


body DCS::XraySearchParams::submitNewDefinition { contents_ } {
   $m_xraySearchParams sendContentsToServer $contents_
}


body DCS::XraySearchParams::setDirectory  { directory_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $directory_ $fileRoot $beamSize_x $beamSize_y $scanWidth $scanHeight $exposureTime $delta $totalColumns $totalRows"
}

body DCS::XraySearchParams::setFileRoot  { fileRoot_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $directory $fileRoot_ $beamSize_x $beamSize_y $scanWidth $scanHeight $exposureTime $delta $totalColumns $totalRows"
}

body DCS::XraySearchParams::setBeamSizeX  { beamSize_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $directory $fileRoot [lindex $beamSize_ 0] $beamSize_y $scanWidth $scanHeight $exposureTime $delta $totalColumns $totalRows"
}
body DCS::XraySearchParams::setBeamSizeY  { beamSize_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $directory $fileRoot $beamSize_x [lindex $beamSize_ 0] $scanWidth $scanHeight $exposureTime $delta $totalColumns $totalRows"
}

body DCS::XraySearchParams::setScanWidth  {scanWidth_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $directory $fileRoot $beamSize_x $beamSize_y [lindex $scanWidth_ 0] $scanHeight $exposureTime $delta $totalColumns $totalRows"
}

body DCS::XraySearchParams::setScanHeight  { scanHeight_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $directory $fileRoot $beamSize_x $beamSize_y $scanWidth [lindex $scanHeight_ 0] $exposureTime $delta $totalColumns $totalRows"
}

body DCS::XraySearchParams::setExposureTime  { exposureTime_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $directory $fileRoot $beamSize_x $beamSize_y $scanWidth $scanHeight [lindex $exposureTime_ 0] $delta $totalColumns $totalRows"
}

body DCS::XraySearchParams::setDelta  { delta_ } {
   submitNewDefinition  "$state \{$message\} $username $sessionID $directory $fileRoot $beamSize_x $beamSize_y $scanWidth $scanHeight $exposureTime [lindex $delta_ 0] $totalColumns $totalRows"
}


body DCS::XraySearchParams::handleSearchDefinitionChange { - targetReady_ - xraySearchParams - } {

	if { ! $targetReady_} return

   set state [lindex $xraySearchParams 0]
   set message [lindex $xraySearchParams 1]
   set username [lindex $xraySearchParams 2]
   set sessionID [lindex $xraySearchParams 3]
   set directory [lindex $xraySearchParams 4]
   set fileRoot [lindex $xraySearchParams 5]
   set beamSize_x [lindex $xraySearchParams 6]
   set beamSize_y [lindex $xraySearchParams 7]
   set scanWidth [lindex $xraySearchParams 8]
   set scanHeight [lindex $xraySearchParams 9]
   set exposureTime [lindex $xraySearchParams 10]
   set delta [lindex $xraySearchParams 11]
   set totalColumns [lindex $xraySearchParams 12]
   set totalRows [lindex $xraySearchParams 13]


	#inform observers of the change 
	updateRegisteredComponents state 
	updateRegisteredComponents message 
	updateRegisteredComponents username 
	updateRegisteredComponents sessionID 
	updateRegisteredComponents directory
	updateRegisteredComponents fileRoot
	updateRegisteredComponents beamSize_x
	updateRegisteredComponents beamSize_y
	updateRegisteredComponents scanWidth
	updateRegisteredComponents scanHeight
	updateRegisteredComponents exposureTime
	updateRegisteredComponents delta
	updateRegisteredComponents totalColumns
	updateRegisteredComponents totalRows 
}




####################
#  GUI
######################
class DCS::XraySampleSearchGui {
 	inherit DCS::Component ::itk::Widget

	# protected methods
	protected method constructControlPanel
	public method startXraySearch

   private variable m_deviceFactory
   private variable m_xraySearchParamsObj

   private method setEntryComponentDirectly
   private variable m_logger

   public method changeFileRoot
   public method changeDirectory
   public method changeDelta
   public method changeBeamSizeX
   public method changeBeamSizeY
   public method changeScanWidth
   public method changeScanHeight
   public method changeExposureTime

	constructor { args } {

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      set m_xraySearchParamsObj [DCS::XraySearchParams::getObject]
      set m_logger [DCS::Logger::getObject]

		# construct the parameter widgets
		constructControlPanel

      eval itk_initialize $args


      ::mediator register $this $m_xraySearchParamsObj fileRoot changeFileRoot 
      ::mediator register $this $m_xraySearchParamsObj directory changeDirectory
      ::mediator register $this $m_xraySearchParamsObj delta changeDelta
      ::mediator register $this $m_xraySearchParamsObj beamSize_x changeBeamSizeX
      ::mediator register $this $m_xraySearchParamsObj beamSize_y changeBeamSizeY
      ::mediator register $this $m_xraySearchParamsObj scanWidth changeScanWidth
      ::mediator register $this $m_xraySearchParamsObj scanHeight changeScanHeight
      ::mediator register $this $m_xraySearchParamsObj exposureTime changeExposureTime
      
      $itk_component(scanButton) addInput "$m_xraySearchParamsObj state 0 {supporting device}"
      $itk_component(directory) addInput "$m_xraySearchParamsObj state 0 {supporting device}"
      $itk_component(fileRoot) addInput "$m_xraySearchParamsObj state 0 {supporting device}"
      $itk_component(exposureTime) addInput "$m_xraySearchParamsObj state 0 {supporting device}"
      $itk_component(delta) addInput "$m_xraySearchParamsObj state 0 {supporting device}"
      $itk_component(beamSize_x) addInput "$m_xraySearchParamsObj state 0 {supporting device}"
      $itk_component(beamSize_y) addInput "$m_xraySearchParamsObj state 0 {supporting device}"
      $itk_component(scanWidth) addInput "$m_xraySearchParamsObj state 0 {supporting device}"
      $itk_component(scanHeight) addInput "$m_xraySearchParamsObj state 0 {supporting device}"

      $itk_component(message) configure -component $m_xraySearchParamsObj
      $itk_component(message) configure -attribute message

      $itk_component(totalRows) configure -component $m_xraySearchParamsObj
      $itk_component(totalRows) configure -attribute totalRows

      $itk_component(totalColumns) configure -component $m_xraySearchParamsObj
      $itk_component(totalColumns) configure -attribute totalColumns

    announceExist 
	}

	destructor {
	}

}

body DCS::XraySampleSearchGui::setEntryComponentDirectly { component_ value_ } {
   $itk_component($component_) setValue $value_ 1
}

body DCS::XraySampleSearchGui::changeFileRoot { - targetReady_ - x - } {
	setEntryComponentDirectly fileRoot $x
}

body DCS::XraySampleSearchGui::changeDirectory { - targetReady_ - x - } {
	setEntryComponentDirectly directory $x
}

body DCS::XraySampleSearchGui::changeDelta { - targetReady_ - x - } {
	setEntryComponentDirectly delta $x
}

body DCS::XraySampleSearchGui::changeBeamSizeX { - targetReady_ - x - } {
	setEntryComponentDirectly beamSize_x $x
}
body DCS::XraySampleSearchGui::changeBeamSizeY { - targetReady_ - y - } {
	setEntryComponentDirectly beamSize_y $y
}

body DCS::XraySampleSearchGui::changeScanWidth { - targetReady_ - x - } {
	setEntryComponentDirectly scanWidth $x
}


body DCS::XraySampleSearchGui::changeScanHeight { - targetReady_ - x - } {
	setEntryComponentDirectly scanHeight $x
}

body DCS::XraySampleSearchGui::changeExposureTime { - targetReady_ - x - } {
	setEntryComponentDirectly exposureTime $x
}


body DCS::XraySampleSearchGui::constructControlPanel { } {

	global env

   set ring $itk_interior

   itk_component add scanButton {
      DCS::Button $ring.c -command "$this startXraySearch" \
         -text "Start Xray Sample Search"\
         -width 30
   } {}

	# make the filename root entry
   itk_component add fileRoot {
      DCS::Entry $ring.filename \
         -entryType field \
         -entryWidth 20 \
         -entryJustify center \
         -entryMaxLength 128 \
         -promptText "Prefix: " \
         -promptWidth 12 \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_xraySearchParamsObj fileRoot" \
         -onSubmit "$m_xraySearchParamsObj setFileRoot %s" 
   } {}

   # make the data directory entry
   itk_component add directory {
      DCS::Entry $ring.dir \
         -entryType field \
         -entryWidth 60 \
         -entryJustify center \
         -entryMaxLength 128 \
         -promptText "Directory: " \
         -promptWidth 12 \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_xraySearchParamsObj directory" \
         -onSubmit "$m_xraySearchParamsObj setDirectory %s" 
   } {}

   #$itk_component(directory) setValue "/data/$env(USER)"

   itk_component add exposureTime {
      DCS::Entry $ring.time \
         -promptText "Time: " -promptWidth 12 -units "s" \
         -entryType positiveFloat \
         -entryJustify right \
         -entryWidth 10 	\
         -decimalPlaces 2 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -shadowReference 0 \
         -reference "$m_xraySearchParamsObj exposureTime" \
         -onSubmit "$m_xraySearchParamsObj setExposureTime %s" 
   } {}
		
   #$itk_component(exposureTime) setValue [list 1.0 s]

   # make the width entry
   itk_component add delta {
      DCS::Entry $ring.delta -promptText "Delta: " \
         -promptWidth 12 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 2 \
         -units "deg" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_xraySearchParamsObj delta" \
         -onSubmit "$m_xraySearchParamsObj setDelta %s" 
   } {}


   # make the width entry
   itk_component add beamSize_x {
      DCS::Entry $ring.bsize_x -promptText "Beam Width: " \
         -promptWidth 12 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_xraySearchParamsObj beamSize_x" \
         -onSubmit "$m_xraySearchParamsObj setBeamSizeX %s" 
   } {}
   itk_component add beamSize_y {
      DCS::Entry $ring.bsize_y -promptText "Beam Height: " \
         -promptWidth 12 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_xraySearchParamsObj beamSize_y" \
         -onSubmit "$m_xraySearchParamsObj setBeamSizeY %s" 
   } {}

   # make the width entry
   itk_component add scanWidth {
      DCS::Entry $ring.sw -promptText "Scan Width: " \
         -promptWidth 12 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_xraySearchParamsObj scanWidth" \
         -onSubmit "$m_xraySearchParamsObj setScanWidth %s" 
   } {}

   # make the width entry
   itk_component add scanHeight {
      DCS::Entry $ring.sh -promptText "Scan Height: " \
         -promptWidth 12 \
         -entryWidth 10 	\
         -entryType positiveFloat \
         -entryJustify right \
         -decimalPlaces 3 \
         -units "mm" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_xraySearchParamsObj scanHeight" \
         -onSubmit "$m_xraySearchParamsObj setScanHeight %s" 
   } {}
   
	itk_component add message {
		DCS::Label $ring.message -promptText "Status: " 
	} {}

	itk_component add totalColumns {
		DCS::Label $ring.totalColumns -promptText "Total Columns: "
	} {}
    
	itk_component add totalRows {
		DCS::Label $ring.totalRows  -promptText "Total Rows: "
	} {}
    
	grid $itk_component(directory) -row 0 -column 0 -columnspan 2 -sticky w

	grid $itk_component(fileRoot) -row 1 -column 0 -sticky w

	grid $itk_component(beamSize_x) -row 2 -column 0 -sticky w
	grid $itk_component(beamSize_y) -row 2 -column 1 -sticky w

	grid $itk_component(scanWidth) -row 3 -column 0 -sticky w
	grid $itk_component(scanHeight) -row 3 -column 1 -sticky w

	grid $itk_component(exposureTime) -row 4 -column 0 -sticky w
	grid $itk_component(delta) -row 4 -column 1 -sticky w

	grid $itk_component(totalRows) -row 5 -column 0 
	grid $itk_component(totalColumns) -row 5 -column 1 
    
	grid $itk_component(scanButton) -row 6 -column 0 -columnspan 2
	grid $itk_component(message) -row 7 -column 0 -columnspan 2

}

body DCS::XraySampleSearchGui::startXraySearch {} {
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
    
   set searchOp [$m_deviceFactory createOperation xraySampleSearch]

    set user [::dcss getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[::dcss getSessionId]
    }

   $searchOp startOperation $user $SID
}

