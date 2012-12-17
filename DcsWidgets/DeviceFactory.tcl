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

package provide DCSDeviceFactory 1.0

# provide the DCSDevice package
package require DCSDevice
package require DCSString
package require DCSRunDefinition
package require DCSHardwareManager
package require DCSOperationManager
package require DCSLogger
package require DCSStrategyStatus
package require DCSCassetteOwner
package require DCSRobotMoveList
package require DCSSpreadsheet
package require DCSRobotStatus
package require DCSCollimatorPreset
package require DCSUserAlignBeamStatus
package require DCSScreeningParameters

#this is meant to be called near the start of Blu-Ice.  It sets up the
#default values for motors, which can be overidden later.

class DCS::DeviceFactory {

	private variable _namespace ::device
	private variable _beamline
	private variable _motorObjectArray
	private variable _signalList
	private variable _stringList ""
	private variable _operationList
	private variable _shutterList ""
	private variable _encoderList ""
   private variable _controllerList ""

    private common _signalNameOrder [list i f b]
    public proc cmpSignalName { s1 s2 } {
        set c1 [string index $s1 0]
        set c2 [string index $s2 0]
        if {$c1 == $c2} {
            return [string compare $s1 $s2]
        }

        foreach char $_signalNameOrder {
            if {$c1 == $char} {
                return -1
            }
            if {$c2 == $char} {
                return 1
            }
        }


        #### we want "e" at last
        if {$c1 == "e"} {
            return 1
        }
        if {$c2 == "e"} {
            return -1
        }
        return [string compare $s1 $s2]
    }

	private method verifyMotorTypeReal
	private method verifyMotorTypePseudo
	
	public method createCoreDevices

	public method getControllerList {} {return [lsort $_controllerList]]}
	public method getMotorList {} {return [lsort [array names _motorObjectArray]]}
	public method getSignalList {} {return [lsort -command DeviceFactory::cmpSignalName $_signalList]}
	public method getOperationList {} {return [lsort $_operationList]}
	public method getStringList {} {return [lsort $_stringList]}
	public method getShutterList {} {return [lsort $_shutterList]}
	public method getEncoderList {} {return [lsort $_encoderList]}

    public method getIonChamberAndEncoderList { } {
        set ionChambers [lsort -command DeviceFactory::cmpSignalName $_signalList]
        set encoders    [lsort -command DeviceFactory::cmpSignalName $_encoderList]

        set result $ionChambers
        eval lappend result $encoders
        return $result
    }

	public method createDefaultSignals
	public method motorExists
	public method stringExists
	public method operationExists
	public method deviceExists

	public method getObjectName {device} {
		return ${_namespace}::$device
	}

   public method createHardwareController 	
	public method createRealMotor
	public method createPseudoMotor
	public method createSignal
	public method createOperation
	public method createString
	public method createRunString
	public method createRunListString
	public method createShutter
	public method createEncoder
	public method createCassetteOwnerString
	public method createRobotMoveListString
	public method createRobotStatusString
	public method createVirtualRunString
	public method createVirtualString
	public method createRunStringForQueue
	public method createCollimatorPresetString
	public method createUserAlignBeamStatusString
	public method createScreeningParametersString

   #variable for storing singleton doseFactor object
   private common m_theObject {} 
   public proc getObject
   public method enforceUniqueness

	constructor { args} {

      enforceUniqueness

      #some devices are needed first
      createCoreDevices

      #read the beamline configuration file to get default motor parameters	
      set fileReader [DCS::DeviceDefinitionFile #auto $this]
      set deviceFilename [::config getDeviceDefinitionFilename]
      $fileReader read $deviceFilename
      #delete $fileReader
	}
}


#return the singleton object
body DCS::DeviceFactory::getObject {} {
   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto]
   }

   return $m_theObject
}

#this function should be called by the constructor
body DCS::DeviceFactory::enforceUniqueness {} {
   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if ![string match "${current}::getObject" $caller] {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}

#for devices that are needed to exist very early.
body DCS::DeviceFactory::createCoreDevices {} {
   set hutchDoorString [createString hutchDoorStatus]
   $hutchDoorString createAttributeFromField doorState 0
   
    createString cassette_owner
    createString robot_move
    createString robot_status

    createVirtualRunString    virtualRunForQueue
    createVirtualString       virtualPositionForQueue

    ::device::virtualRunForQueue configure \
    -staffPermissions "1 1 1 1 1" \
    -userPermissions "1 1 1 1 1"

    ::device::virtualPositionForQueue configure \
    -staffPermissions "1 1 1 1 1" \
    -userPermissions "1 1 1 1 1"
}

body DCS::DeviceFactory::stringExists { str } {
   return [deviceExists ::device::$str] 
}
body DCS::DeviceFactory::motorExists { motor } {
   return [deviceExists ::device::$motor] 
}
body DCS::DeviceFactory::operationExists { op } {
   return [deviceExists ::device::$op] 
}

body DCS::DeviceFactory::deviceExists { deviceName_ } {
	if { [info commands $deviceName_] == "" } {return 0} else {return 1}
}

#Sometimes the initial configuration for a motor is incorrect,
# The software fixes it on the fly.
body DCS::DeviceFactory::verifyMotorTypePseudo { deviceName_ } {
	
	#guard against undefined motors
	if { ![deviceExists $deviceName_] } {return 0}
	
	if { [$deviceName_ info class] != "::DCS::Motor"} {
		#should be a pseudo motor.  Delete this one.
		puts "---------------------------------------------"
		puts "$deviceName_ is configured as a Real Motor"
		puts "Received a message for a Pseudo Motor."
		puts "DELETING $deviceName_"
		puts "---------------------------------------------"
		delete object $deviceName_
		return 0
	}
	
	return 1
}

#Sometimes the initial configuration for a motor is incorrect,
# The software fixes it on the fly.
body DCS::DeviceFactory::verifyMotorTypeReal { deviceName_ } {
	
	#guard against undefined motors
	if { ![deviceExists $deviceName_] } {return 0}
	
	if { [$deviceName_ info class] != "::DCS::RealMotor"} {
		#should be a RealMotor.  Delete this one.
		puts "---------------------------------------------"
		puts "$deviceName_ is configured as a Pseudo Motor"
		puts "Received a message for a Real Motor."
		puts "DELETING $deviceName_"
		puts "---------------------------------------------"
		delete object $deviceName_
		return 0
	}
	
	return 1
}



body ::DCS::DeviceFactory::createHardwareController { controller_ args} {
   #get the name of the new object to be created	
	if { [info commands ${_namespace}::$controller_ ] == "" } {
		namespace eval $_namespace [list ::DCS::DhsMonitor $controller_ ] $args
      lappend _controllerList $controller_
	} else {
      eval ${_namespace}::$controller_ configure $args
   }

}


body DCS::DeviceFactory::createRealMotor {motor args} {
	
	set deviceName [getObjectName $motor]

	#store the full name of the object
	set _motorObjectArray($motor) $deviceName
	
	if [verifyMotorTypeReal $deviceName] {
      eval $deviceName configure $args
		return $deviceName
	}

	#the device does not exist
	namespace eval $_namespace [list DCS::RealMotor $motor -status offline] $args

	return $deviceName
}


body DCS::DeviceFactory::createPseudoMotor {motor args} {

	set deviceName [getObjectName $motor]

	#store the full name of the object
	set _motorObjectArray($motor) $deviceName
	
	if [verifyMotorTypePseudo $deviceName] {
      eval $deviceName configure $args
		return $deviceName
	}
	
	#the device does not exist
	namespace eval $_namespace [list DCS::Motor $motor -status offline] $args
	
	return $deviceName
}

body DCS::DeviceFactory::createSignal {signal args} {
	
	if { [info commands ${_namespace}::$signal] == "" } {

		namespace eval $_namespace [list DCS::IonChamber $signal -status offline] $args
		
		#namespace eval $_namespace [list Signal $signal -status offline] $args
		#store the full name of the object
		lappend _signalList  $signal
	} 
	
	return [getObjectName $signal]
}


body DCS::DeviceFactory::createDefaultSignals {} {
	createSignal i0
}

body DCS::DeviceFactory::createOperation {operation args} {
	
	if { [info commands ${_namespace}::$operation] == "" } {

		namespace eval $_namespace [list DCS::Operation $operation -status offline] $args
		
		#namespace eval $_namespace [list Operation $operation -status offline] $args
		#store the full name of the object
		lappend _operationList  $operation
	}
	
	return [getObjectName $operation]
}

body DCS::DeviceFactory::createString { name args} {
    switch -exact -- $name {
        screeningParameters {
            return [eval createScreeningParametersString $name $args] 
        }
        runs {
            return [eval createRunListString $name $args]
        }
        cassette_owner {
            return [eval createCassetteOwnerString $name $args]
        }
        robot_move {
            return [eval createRobotMoveListString $name $args]
        }
        robot_status {
            return [eval createRobotStatusString $name $args] 
        }
        collimator_preset {
            return [eval createCollimatorPresetString $name $args]
        }
        user_align_beam_status {
            return [eval createUserAlignBeamStatusString $name $args]
        }
        run_for_queue -
        run_for_adjust -
        run_for_adjust_default {
            return [eval createRunStringForQueue $name $args]
        }
        run0 -
        run1 -
        run2 -
        run3 -
        run4 -
        run5 -
        run6 -
        run7 -
        run8 -
        run9 -
        run10 -
        run11 -
        run12 -
        run13 -
        run14 -
        run15 -
        run16 {
            return [eval createRunString $name $args]
        }
    }

	
	if { [info commands ${_namespace}::$name] == "" } {

		namespace eval $_namespace [list DCS::String $name -status offline] $args
		
		#namespace eval $_namespace [list Operation $operation -status offline] $args
		#store the full name of the object
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}


body DCS::DeviceFactory::createRunString { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {

		namespace eval $_namespace [list DCS::RunString $name -status offline] $args
		
		#namespace eval $_namespace [list Operation $operation -status offline] $args
		#store the full name of the object
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}

body DCS::DeviceFactory::createCassetteOwnerString { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {

		namespace eval $_namespace [list DCS::CassetteOwner $name -status offline] $args
		
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}
body DCS::DeviceFactory::createCollimatorPresetString { name args} {
	if { [info commands ${_namespace}::$name] == "" } {
		namespace eval $_namespace [list DCS::CollimatorPreset $name -status offline] $args
		
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}
body DCS::DeviceFactory::createUserAlignBeamStatusString { name args} {
	if { [info commands ${_namespace}::$name] == "" } {
		namespace eval $_namespace [list DCS::UserAlignBeamStatus $name -status offline] $args
		
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}
body DCS::DeviceFactory::createRobotMoveListString { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {

		namespace eval $_namespace [list DCS::RobotMoveList $name -status offline] $args
		
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}
body DCS::DeviceFactory::createRobotStatusString { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {

		namespace eval $_namespace [list DCS::RobotStatus $name -status offline] $args
		
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}
body DCS::DeviceFactory::createVirtualRunString { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {

		namespace eval $_namespace [list DCS::VirtualQueueRunString $name -status inactive] $args

	    set obj [getObjectName $name]
		
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}
body DCS::DeviceFactory::createVirtualString { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {

		namespace eval $_namespace [list DCS::VirtualString $name -status inactive] $args
		
		lappend _stringList  $name

	    set obj [getObjectName $name]
	}
	
	return [getObjectName $name]
}
body DCS::DeviceFactory::createRunStringForQueue { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {
		namespace eval $_namespace [list DCS::VirtualQueueRunString $name -status offline] $args
		lappend _stringList  $name
	}
	set objName [getObjectName $name]

    $objName setIsTrueString 1

    return $objName
}
body DCS::DeviceFactory::createRunListString { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {

		namespace eval $_namespace [list DCS::RunListString $name -status offline] $args
		
		#namespace eval $_namespace [list Operation $operation -status offline] $args
		#store the full name of the object
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}


body DCS::DeviceFactory::createShutter { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {
		
		namespace eval $_namespace [list DCS::Shutter $name -status offline] $args
		
		#store the full name of the object
		lappend _shutterList  $name
	}
	
	return [getObjectName $name]
}

body DCS::DeviceFactory::createEncoder { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {
		
		namespace eval $_namespace [list DCS::Encoder $name -status offline] $args
		
		#store the full name of the object
		lappend _encoderList  $name
	}
	
	return [getObjectName $name]
}

body DCS::DeviceFactory::createScreeningParametersString { name args} {
	
	if { [info commands ${_namespace}::$name] == "" } {

		namespace eval $_namespace [list DCS::ScreeningParameters $name -status offline] $args
		
		lappend _stringList  $name
	}
	
	return [getObjectName $name]
}



##### this is the version support both old and new format
class DCS::DeviceDefinitionFile {

   public method read

   private method parseRealMotor
   private method parsePseudoMotor
   private method parseController
   private method parseIonChamber
   private method parseShutter
   private method parseRunDefinition
   private method parseRunsDefinition
   private method parseOperation
   private method parseEncoder
   private method parseString

   private method getTrimmedLine

   
   public proc stringIsPermit { line } {
        set ll [string length $line]
        if {$ll != 9} {
            return 0
        }
        for {set i 0} {$i < $ll} {incr i} {
            set letter [string index $line $i]
            if {$i % 2} {
                if {$letter != " "} {
                    return 0
                }
            } else {
                if {$letter != "1" && $letter != "0"} {
                    return 0
                }
            }
        }
        return 1
   }

   private method readOneSectionFromDumpFile { }

   private variable m_handle
   private variable m_deviceFactory

   ####for one section of the file
   private variable m_lineList ""
   private variable m_numLine 0
   private variable MAX_NUM_LINE 20
 
   constructor { deviceFactory_ args} {

   set m_deviceFactory $deviceFactory_

   eval configure $args

   }
}


body DCS::DeviceDefinitionFile::read { filename_ } {

   if {$filename_ == "" } {
      puts "Could not find the default device file."
      return
   }

   set cnt 0

   if { [catch {set m_handle [open $filename_ RDONLY]} err] } {
      puts "could not open default device file: $filename_"
      return
   }

   while {! [eof $m_handle] } {
      if {![readOneSectionFromDumpFile]} {
        break
      }
      set deviceName [lindex $m_lineList 0]
      if {$deviceName == "END" } break
      if {$m_numLine < 2} {
        puts "device {$deviceName} not fully defined"
        exit
        #continue
      }

      set entryType [lindex $m_lineList 1]
      #looking for integer for entry type
      if { ! [string is integer $entryType] } {
        puts "device {$deviceName} type {$entryType} not an integer"
        exit
         #continue
      }

      switch $entryType {
         1 {parseRealMotor $deviceName}
         2 {parsePseudoMotor $deviceName}
         3 {parseController $deviceName} 
         4 {parseIonChamber $deviceName}
         5 {puts obsolete}
         6 {parseShutter $deviceName}
         7 {puts obsolete}
         8 {parseRunDefinition $deviceName}
         9 {parseRunsDefinition $deviceName}
         10 {puts obsolete}
         11 {parseOperation $deviceName}
         12 {parseEncoder $deviceName}
         13 {parseString $deviceName}
      }

      incr cnt
   }
   close $m_handle
}

body DCS::DeviceDefinitionFile::parseRealMotor { deviceName_ } {
    if {$m_numLine != 7} {
        puts "realmotor {$deviceName_} wrong lines: $m_numLine != 7"
        exit
    }

   foreach {controller extName} [lindex $m_lineList 2] break

    if {[stringIsPermit [lindex $m_lineList 3]]} {
        set indexStaffPermit 3
        set indexUserPermit  4
        set indexDependency  5
        set indexConfig      6
    } elseif {[stringIsPermit [lindex $m_lineList 5]]} {
        set indexConfig      3
        set indexDependency  4
        set indexStaffPermit 5
        set indexUserPermit  6
    } else {
        puts "realmotor {$deviceName_} wrong permit line"
        exit
    }

   #getPermissions
   set staffPermissions [lindex $m_lineList $indexStaffPermit]
   set userPermissions  [lindex $m_lineList $indexUserPermit]

   foreach {position upperLimit lowerLimit scaleFactor speed acceleration \
   backlash lowerLimitOn upperLimitOn motorLockOn backlashOn reverseOn \
   circleMode units} [lindex $m_lineList $indexConfig] break

   $m_deviceFactory createRealMotor $deviceName_ \
      -controller $controller \
      -scaledPosition $position \
      -upperLimit $upperLimit \
      -scaleFactor $scaleFactor \
      -speed $speed \
      -acceleration $acceleration \
      -backlash $backlash \
      -lowerLimitOn $lowerLimitOn \
      -upperLimitOn $upperLimitOn \
      -backlashOn $backlashOn \
      -reverseOn $reverseOn \
      -staffPermissions $staffPermissions \
      -userPermissions $userPermissions \
      -baseUnits $units
}



body DCS::DeviceDefinitionFile::parsePseudoMotor { deviceName_ } {
    if {$m_numLine != 8} {
        puts "pseudo motor {$deviceName_} wrong lines: $m_numLine != 8"
        exit
    }

   foreach {controller extName} [lindex $m_lineList 2] break
    if {[stringIsPermit [lindex $m_lineList 3]]} {
        set indexStaffPermit 3
        set indexUserPermit  4
        set indexDependency  5
        set indexConfig      6
        set indexChildren    7
    } elseif {[stringIsPermit [lindex $m_lineList 6]]} {
        set indexConfig      3
        set indexDependency  4
        set indexChildren    5
        set indexStaffPermit 6
        set indexUserPermit  7
    } else {
        puts "pseudo motor {$deviceName_} wrong permit line"
        exit
    }
   
   #getPermissions
   set staffPermissions [lindex $m_lineList $indexStaffPermit]
   set userPermissions  [lindex $m_lineList $indexUserPermit]

   foreach {position upperLimit lowerLimit lowerLimitOn upperLimitOn \
   motorLockOn circleMode units} [lindex $m_lineList $indexConfig] break

   $m_deviceFactory createPseudoMotor $deviceName_ \
      -controller $controller \
      -scaledPosition $position \
      -upperLimit $upperLimit \
      -lowerLimitOn $lowerLimitOn \
      -upperLimitOn $upperLimitOn \
      -staffPermissions $staffPermissions \
      -userPermissions $userPermissions \
      -baseUnits $units
}


body DCS::DeviceDefinitionFile::parseController { deviceName_ } {
    if {$m_numLine != 3} {
        puts "controller {$deviceName_} wrong lines: $m_numLine != 3"
        exit
    }
   
   foreach {hostname protocol} [lindex $m_lineList 2] break

   $m_deviceFactory createHardwareController $deviceName_ -hostname $hostname 

}

body DCS::DeviceDefinitionFile::parseIonChamber {deviceName_ } {
    if {$m_numLine != 3 && $m_numLine != 5} {
        puts "ion chamber {$deviceName_} wrong lines: $m_numLine != 3, 5"
        exit
    }
   

    if {$m_numLine == 5} {
        set staffPermissions [lindex $m_lineList 3]
        set userPermissions  [lindex $m_lineList 4]
        $m_deviceFactory createSignal $deviceName_ \
        -staffPermissions $staffPermissions \
        -userPermissions $userPermissions
    } else {
        $m_deviceFactory createSignal $deviceName_
    }
}

body DCS::DeviceDefinitionFile::parseShutter {deviceName_} {
    if {$m_numLine != 3 && $m_numLine != 5} {
        puts "shutter {$deviceName_} wrong lines: $m_numLine != 3, 5"
        exit
    }
   
   foreach {controller status} [lindex $m_lineList 2] break
    if {$m_numLine == 5} {
        set staffPermissions [lindex $m_lineList 3]
        set userPermissions  [lindex $m_lineList 4]
        $m_deviceFactory createShutter $deviceName_ \
        -controller $controller \
        -status $status \
        -staffPermissions $staffPermissions \
        -userPermissions $userPermissions
    } else {
        $m_deviceFactory createShutter $deviceName_ \
        -controller $controller \
        -status $status
    }
}

body DCS::DeviceDefinitionFile::parseRunDefinition {deviceName_ } {
    if {$m_numLine != 3 && $m_numLine != 6} {
        puts "run definition {$deviceName_} wrong lines: $m_numLine != 3, 6"
        exit
    }
    if {$m_numLine == 6} {
        set staffPermissions [lindex $m_lineList 3]
        set userPermissions  [lindex $m_lineList 4]
        $m_deviceFactory createRunString $deviceName_ \
        -staffPermissions $staffPermissions \
        -userPermissions $userPermissions
    } else {
        $m_deviceFactory createRunString $deviceName_
    }
}


body DCS::DeviceDefinitionFile::parseRunsDefinition {deviceName_ } {
    if {$m_numLine != 3 && $m_numLine != 6} {
        puts "runs status {$deviceName_} wrong lines: $m_numLine != 3, 6"
        exit
    }
    if {$m_numLine == 6} {
        set staffPermissions [lindex $m_lineList 3]
        set userPermissions  [lindex $m_lineList 4]
        $m_deviceFactory createRunListString $deviceName_ \
        -staffPermissions $staffPermissions \
        -userPermissions $userPermissions
    } else {
        $m_deviceFactory createRunListString $deviceName_
    }
}

body DCS::DeviceDefinitionFile::parseOperation {deviceName_} {
    if {$m_numLine != 5} {
        puts "operation {$deviceName_} wrong lines: $m_numLine != 5"
        exit
    }
   foreach {controller extName} [lindex $m_lineList 2] break

   #getPermissions
   set staffPermissions [lindex $m_lineList 3]
   set userPermissions [lindex $m_lineList 4]

   eval $m_deviceFactory createOperation $deviceName_ \
      -controller $controller \
      -staffPermissions [list $staffPermissions] \
      -userPermissions [list $userPermissions]
}


body DCS::DeviceDefinitionFile::parseEncoder {deviceName_ } {
    if {$m_numLine != 3 && $m_numLine != 5} {
        puts "encoder {$deviceName_} wrong lines: $m_numLine != 3, 5"
        exit
    }
    if {$m_numLine == 5} {
        set staffPermissions [lindex $m_lineList 3]
        set userPermissions  [lindex $m_lineList 4]
        $m_deviceFactory createEncoder $deviceName_ \
        -staffPermissions $staffPermissions \
        -userPermissions $userPermissions
    } else {
        $m_deviceFactory createEncoder $deviceName_
    }
   
}

body DCS::DeviceDefinitionFile::parseString { deviceName_ } {
    switch -exact -- $m_numLine {
        3 -
        4 {
            $m_deviceFactory createString $deviceName_
        }
        5 -
        6 {
            set staffPermissions [lindex $m_lineList 3]
            set userPermissions  [lindex $m_lineList 4]
            $m_deviceFactory createString $deviceName_ \
            -staffPermissions $staffPermissions \
            -userPermissions $userPermissions
        }
        default {
            puts "string {$deviceName_} wrong lines: $m_numLine != 3,4,5,6"
            exit
        }
    }
}

body DCS::DeviceDefinitionFile::getTrimmedLine { } {
   set data [gets $m_handle]
   return [string trim $data]
}

body DCS::DeviceDefinitionFile::readOneSectionFromDumpFile { } {
    set m_lineList ""
    set m_numLine 0

    while {![eof $m_handle]} {
        set line [getTrimmedLine]
        if {![string is print $line]} {
            if {$m_numLine > 0} {
                puts "non-printable char found in [lindex $m_lineList 0]"
                puts "at line $m_numLine {$line}"
            } else {
                puts "non-printable char found in name {$line}"
            }
            exit
        }
        set ll [string length $line]
        if {$ll > 0} {
            incr m_numLine
            if {$m_numLine > $MAX_NUM_LINE} {
                puts "exceed max number of lines $MAX_NUM_LINE per section"
                puts "for [lindex $m_lineList 0]"
                exit
            }
            lappend m_lineList $line
        } else {
            if {$m_numLine > 0} {
                break
            }
        }
    }
    return $m_numLine
}





class DCS::HutchDoorState {
   inherit DCS::Component
        
   #variable for storing singleton doseFactor object
   private common m_theObject {} 
   public proc getObject
   public method enforceUniqueness
  
   public method handleHutchDoorUpdate
   public method getMotorStopButton {} {return $m_lastButton}
   public method getState {} {return $m_lastState}
   public method getStatus {} {return inactive}
   public method updateListeners   

   private variable m_lastButton "unknown"
   private variable m_lastState "unknown"
   private variable m_lastUpdate 0
   private variable m_forcedDoor ""

   
   public method watchDog
   
	constructor { args} {

		# call base class constructor
		::DCS::Component::constructor \
			 { \
				state {getState} \
                status {getStatus} \
                motorStopButton {getMotorStopButton} \
			 }
	}  {
      enforceUniqueness

      #the configuration object should be created by now
      set m_forcedDoor [::config getDcssForcedDoor]
   
     
      if { $m_forcedDoor == "" } {
         ::mediator register $this ::device::hutchDoorStatus contents handleHutchDoorUpdate
         watchDog
      } else {
         puts "Forcing the hutch door to $m_forcedDoor."
         set m_lastState $m_forcedDoor
      }

 
      announceExist
      
   }
}



#return the singleton object
body DCS::HutchDoorState::getObject {} {
   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto]
   }

   return $m_theObject
}

#this function should be called by the constructor
body DCS::HutchDoorState::enforceUniqueness {} {
   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if ![string match "${current}::getObject" $caller] {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}

body DCS::HutchDoorState::handleHutchDoorUpdate {- targetReady alias value -} {

   if { ! $targetReady } {
      set state unknown
      set motorStopButton unknown
   } else {
      set state [lindex $value 0]
      set motorStopButton [lindex $value 2]
      set m_lastUpdate [clock seconds] 
   }

   updateListeners $state $motorStopButton
}


body DCS::HutchDoorState::watchDog {} {
   set now [clock seconds]

   if { $now - $m_lastUpdate > 5 } {
      updateListeners unknown unknown
   }
   
   after 1000 [list $this watchDog]
}

body DCS::HutchDoorState::updateListeners { state_ button_ } {

   if { $state_ != $m_lastState} {
      set m_lastState $state_
      updateRegisteredComponents state
   }
    if {$button_ != $m_lastButton} {
        set m_lastButton $button_
        updateRegisteredComponents motorStopButton
    }
}
