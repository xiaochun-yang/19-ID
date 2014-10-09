
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

package provide BLUICEScan 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSPrompt
package require DCSMotorControlPanel
package require DCSCheckbutton
package require DCSGraph
package require DCSLogger
package require DCSFeedback
package require DCSContour

global gImpWrapAvailable
set gImpWrapAvailable 1

if { [catch {package require DCSImperson} err ] } {
    set gImpWrapAvailable 0
}

source [file join $BLC_DIR ScanDefinition.tcl]

class DCS::ScanWidget {
 	inherit ::itk::Widget
	itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -deviceList deviceList DeviceList ""

    public method connectToCurrent
    public method markAsConnected { } {
        set m_connectToCurrentScan 1
        $itk_component(progress) configure -barcolor blue
    }
    public method markAsNotConnected { } {
        set m_connectToCurrentScan 0
        $itk_component(progress) configure -barcolor grey
    }

    public method print1DGraph { } {
        $itk_component(1dGraph) print
    }

    public method print2DGraph { } {
        $itk_component(2dGraph) print
    }
    public method loadScanDialog
    public method loadCurrentScanFile
    public method loadScan { fileName }
    public method loadScanDirectly { fileName }

    public method loadNextScan { }
    public method loadPreviousScan { }

    public method acceptLine { one_line }

	public method handleOperationEvent
	public method handleMarkerMovement

    public method handleBacklashChange
    public method handleShowSpiralChange

    public method handle2DMarkMovement

	private method addScanlogHeader

	private method addScanlogEntry

	private method changeScanDevice
	private method changeScanDevice2
	public method handleMotorSelection
	public method handleMotor2Selection

	#graphing methods
	private method addToGraph { {draw 1} }
	private method resetViews
	private method initializeGraphTraces
	private method initializeGraphTracesFor1MotorScan
	private method initializeGraphTracesFor2MotorScan
	private method createMarkerFor1MotorScan { mark_num }

	private method parseScanStart
	private method parseScanUpdate 	
	private method parseExtraParameters
	private variable _lastMotorPositions
	private variable _lastSignalReadings
	private variable _signalList "i2"

	private variable _lastScanDef
	private variable _newScanDef
	private variable _traceCnt 0

	private variable _lastDevice ""
	private variable _lastDevice2 ""

    private variable _lineNum 0
    private variable _line
    private variable _numMotors 1
    private variable _lastIndex 0

    private variable _motorFieldWidth
    private variable _signalFieldWidth
    private common   MIN_FIELD_WIDTH_MOTOR 20
    private common   MIN_FIELD_WIDTH_SIGNAL 15

	#methods for constructing the widget
	private method createAxisDefinitionFrame
	private method	createStartScanFrame
	private method createMotorControlFrame
	private method createMenuFrame

	private method registerAllButtons

	public method handleModeChange
	private method changeMotorView
	private method changeMotorView2
    private variable m_deviceFactory

    private variable m_statusObj
    private variable m_opObj

    private variable m_1dMarker1 ""
    private variable m_1dMarker2 ""

    private variable m_connectToCurrentScan 0
    private variable m_currentFile ""

    public method handleFilenameChange

    constructor { device_ args} {
        log_warning currentScanObj: $this
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_statusObj     [$m_deviceFactory createString scan_motor_status]
	    set m_opObj         [$m_deviceFactory createOperation scanMotor]

        $m_statusObj createAttributeFromField file_name 0
        $m_statusObj createAttributeFromField scan_step 1

        createMenuFrame $itk_interior

		#instantiateScanDefinitions $device_
	    set _lastScanDef [namespace current]::[DCS::FullScanDefinition \#auto]
	    set _newScanDef [namespace current]::[DCS::FullScanDefinition \#auto]


	    createStartScanFrame $itk_interior
		createMotorControlFrame $itk_interior

		#the notebook organizes all of the graphing functions in one place
		itk_component add notebook {
			DCS::TabNotebook $itk_interior.n  \
				 -tabbackground lightgrey \
				 -background lightgrey \
				 -backdrop lightgrey \
				 -borderwidth 2\
				 -tabpos n \
				 -gap -4 \
				 -angle 20 \
				 -raiseselect 1 \
				 -bevelamount 4 \
				 -width 850 -height 450
		} {
		}

		#create all of the tabs
		$itk_component(notebook) add Definition -label "Definition"
		$itk_component(notebook) add Graph -label "Graph"
		$itk_component(notebook) add Log -label "Log"
		
		#create the tabs for the definition and the graph
		set definitionSite [$itk_component(notebook) childsite 0]
		set graphSite [$itk_component(notebook) childsite 1]
		set logSite [$itk_component(notebook) childsite 2]
		
		itk_component add definition {
			DCS::ScanDefinitionWidget $definitionSite.d $_lastScanDef $_newScanDef
		} {
		}
		createAxisDefinitionFrame $definitionSite

		itk_component add 1dGraph {
			DCS::Graph $graphSite.g 	\
				 -xLabel "motor" 		\
				 -yLabel "Counts" 		\
				 -title "Empty Graph" -plotbackground white
		} {
		}

        ######customize DCS::Graph
        $itk_component(1dGraph) removeFileAccess
        $itk_component(1dGraph) setShowZero 1

        itk_component add 2dGraph {
            DCS::Contour $graphSite.g2
        } {
        }

		itk_component add log {
			DCS::scrolledLog $logSite.l
		} {
		}

        itk_component add progress {
            DCS::Feedback $itk_interior.bar \
            -barheight 10 \
            -steps 100 \
            -component $m_statusObj -attribute scan_step
        } {
        }


		eval itk_initialize $args

		registerAllButtons



        #pack $itk_component(1dGraph) -expand 1 -fill both
        #pack $itk_component(2dGraph) -expand 1 -fill both

		pack $itk_component(log) -expand yes -fill both 


	    set deviceName [namespace tail $device_]
        set valRoot "[::config getConfigRootName]"
        eval parseScanStart "{{$deviceName 21 0 2.0 0.1 [$device_ cget -baseUnits]} {(none) 21 0 2.0 0.1 mm}} {i2} {} { 0.1 0.0 1 0 min } {~ $valRoot 1}" no_log
        $itk_component(axes1) resetAxisCenter

        markAsNotConnected
        if {$m_connectToCurrentScan} {
            connectToCurrent
        }

		pack $itk_component(scanAxesTitle) 
		pack $itk_component(definition)  -expand yes -fill both

		grid $itk_component(menuFrame)          -row 0 -column 0 -columnspan 2 -sticky news

		grid $itk_component(notebook)           -row 1 -column 0 -rowspan 2 -sticky news
        grid $itk_component(startScanFrame)     -row 1 -column 1 -sticky news

		grid $itk_component(motorControlFrame)  -row 2 -column 1 -sticky news


		grid $itk_component(progress)           -row 3 -column 0 -columnspan 2 -sticky news

		grid rowconfigure $itk_interior 0 -weight 0
		grid rowconfigure $itk_interior 1 -weight 1
		grid rowconfigure $itk_interior 2 -weight 0
		grid rowconfigure $itk_interior 3 -weight 0

		grid columnconfigure $itk_interior 0 -weight 5
		grid columnconfigure $itk_interior 1 -weight 0

		pack $itk_interior -expand yes -fill both

		#registerForScanMotorOperations
	    $m_opObj registerForAllEvents $this handleOperationEvent 
        $m_statusObj register $this file_name handleFilenameChange

		$itk_component(notebook) select 0

        $_newScanDef register $this -backlash handleBacklashChange
        $_newScanDef register $this -showSpiral handleShowSpiralChange
	}


	destructor {
		$m_opObj unRegisterForAllEvents $this handleOperationEvent 
        $m_statusObj unregister $this file_name handleFilenameChange
	}
}

body DCS::ScanWidget::connectToCurrent { } {
    #get contents of string scan_motor_status
    set scanStatus [$m_statusObj getContents]

    if {[llength $scanStatus] < 1} {
        puts "failed to connect to current scan: bad contents of scan_motor_status"
    return
    }

    #extract log filename (first element)
    set m_currentFile [lindex $scanStatus 0]
    log_note current scan file: $m_currentFile

    #load the log file
    loadScan $m_currentFile

    #flag to enable operation event handling
    markAsConnected
}

body DCS::ScanWidget::loadCurrentScanFile { } {
    # get the name of the file to open
    #get contents of string scan_motor_status
    set scanStatus [$m_statusObj getContents]

    if {[llength $scanStatus] < 1} {
        puts "bad contents of scan_motor_status: $scanStatus"
        return
    }

    #extract log m_currentFile (first element)
    set m_currentFile [lindex $scanStatus 0]
    log_note current scan file: $m_currentFile
    if { $m_currentFile != {} } {

        #this flag will stop handling operation event
        markAsNotConnected

        loadScan $m_currentFile

	    if { [$_newScanDef getNumberOfMotors] == 2 } {
            # in case of a incompleted scan
            # fill all empty nodes with minimum value of known nodes
            # and plot the contour
            $itk_component(2dGraph) allDataDone
        }
    }
}

body DCS::ScanWidget::loadScanDialog { } {
    # get the name of the file to open
    set filename [tk_getOpenFile]

    # make sure the file selection was not cancelled
    if { $filename != {} } {

        #this flag will stop handling operation event
        markAsNotConnected

        set m_currentFile $filename
        loadScan $m_currentFile

	    if { [$_newScanDef getNumberOfMotors] == 2 } {
            # in case of a incompleted scan
            # fill all empty nodes with minimum value of known nodes
            # and plot the contour
            $itk_component(2dGraph) allDataDone
        }
    }
}

body DCS::ScanWidget::acceptLine { one_line } {
    #puts "acceptLine {$one_line} num=$_lineNum"

    if {$_lineNum < 8} {
        set _line($_lineNum) $one_line
        incr _lineNum
        if {$_lineNum == 7} {
            DCS::FullScanDefinition::readScanHeaderByLine \
            $_line(0) $_line(1) $_line(2) $_line(3) \
            $_line(4) $_line(5) $_line(6) \
            motor1 motor2 detectors filters timing prefix
            #puts "motor1={$motor1}, motor2={$motor2} det={$detectors} filter {$filters} timing {$timing} prefix {$prefix}"

            
            parseScanStart [list $motor1 $motor2] $detectors $filters $timing $prefix log_from_file


        }
        if {$_lineNum == 8} {
            puts "parseExtraPamraters for line 7 from file"
            parseExtraParameters $_line(7)
        }
        return
    }
    if {$_lineNum < 10} {
        incr _lineNum
        return
    }
    if {[llength $one_line] == 0} return
    
    set motorPositions [lrange $one_line 0 $_lastIndex]
    set signalReadings [lrange $one_line $_numMotors end]
	parseScanUpdate $motorPositions $signalReadings
			
	addToGraph 0
	addScanlogEntry

    return
}

body DCS::ScanWidget::loadScanDirectly { filename } {
    # make sure file exists
    if { ! [file isfile $filename] } {
        log_error File $filename does not exist.
        return
    }

    # make sure file is readable
    if { ! [file readable $filename] } {
        log_error File $filename is not readable.
        return
    }

    # open the file
    if [ catch {open $filename r} fileHandle ] {
        log_error File $filename could not be opened.
        return
    }

    set result [ catch {

        # read file header
        DCS::FullScanDefinition::readScanHeader\
        $fileHandle motor1 motor2 detectors filters timing prefix
        #puts "DEBUG motor1={$motor1}, motor2={$motor2} det={$detectors} filter {$filters} timing {$timing} prefix {$prefix}"

        parseScanStart [list $motor1 $motor2] $detectors $filters $timing $prefix log_from_file


        ### 04/11/14: line 7 changed to "# extra ....."
        gets $fileHandle buffer
        puts "parseExtraPamraters for line 7 from directload"
        parseExtraParameters $buffer

        #skip blank line
        gets $fileHandle buffer
        gets $fileHandle buffer
    
        set numMotors [$_newScanDef getNumberOfMotors]
        set lastIndex [expr $numMotors - 1]

        set mStart 0
        set mEnd   $lastIndex
        set sStart $numMotors

        set m1Name [lindex $motor1 0]
        set m2Name [lindex $motor2 0]

        if {$m1Name == "time" || $m2Name == "time"} {
            incr mStart 2
            incr mEnd 2
            incr sStart 2
        }

        while { [gets $fileHandle buffer] >= 0 } {
            if {[llength $buffer] > 0} {
                #puts "DEBUG Line: $buffer"
                set motorPositions [lrange $buffer $mStart $mEnd]
                set signalReadings [lrange $buffer $sStart end]
			    parseScanUpdate $motorPositions $signalReadings
			
			    addToGraph 0
			    addScanlogEntry
            }
        }

        if {$numMotors == 2} {
            $itk_component(2dGraph) redraw
        }
		$itk_component(log) log_string "Load scan completed" warning 0
    } errorText] 
    if { $result } {
        #puts "Error reading file $filename: $errorText"
        log_error LoadScan failed: $errorText
    }
    close $fileHandle
}
body DCS::ScanWidget::loadScan { filename } {
    global gImpWrapAvailable

    #try TCL directly access file first
    if {![catch { loadScanDirectly $filename } errorMsg]} {
        return
    }

    if {!$gImpWrapAvailable} {
        log_error load directly from $filename failed
        return
    }

    #try impersonal server if directly access failed
    log_warning load directly from $filename failed
    log_warning trying to use impersonal server.....
    set result [ catch {
        set _lineNum 0

        set username [$itk_option(-controlSystem) getUser]
        set sessionId [$itk_option(-controlSystem) getSessionId]
        set sessionId [getTicketFromSessionId $sessionId]
        impReadTextFile $username $sessionId $filename "$this acceptLine"

        if {$_numMotors == 2} {
            $itk_component(2dGraph) redraw
        }
		$itk_component(log) log_string "Load scan completed" warning 0
    } errorText] 
    if { $result } {
        log_error imperson load file Error reading file $filename: $errorText
    }
}

body DCS::ScanWidget::loadNextScan { } {
    ### get next file name from current
    if {[catch {
        parseFileNameForCounter $m_currentFile prefix numDigit counter ext
    } errMsg]} {
        log_error loadNextScan faile: $errMsg
    }
    markAsNotConnected

    incr counter

    set counter [format "%0${numDigit}d" $counter]

    set m_currentFile $prefix$counter$ext
    log_note loading next: $m_currentFile
    loadScan $m_currentFile
}
body DCS::ScanWidget::loadPreviousScan { } {
    ### get previous file name from current
    if {[catch {
        parseFileNameForCounter $m_currentFile prefix numDigit counter ext
    } errMsg]} {
        log_error loadNextScan faile: $errMsg
        return
    }

    if {$counter <= 0} {
        log_warning no more previous
        return
    }

    markAsNotConnected

    incr counter -1

    set counter [format "%0${numDigit}d" $counter]

    set m_currentFile $prefix$counter$ext
    log_note loading previous: $m_currentFile
    loadScan $m_currentFile
}
body DCS::ScanWidget::handleOperationEvent { message_ } {
	#puts "MOTORSCAN $message_"

    #check flag
    if {!$m_connectToCurrentScan} {
        #puts "ignore, not connected to current scan"
        return
    }

    set arg9 ""

	foreach {eventType operationName operationId arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9} $message_ break

	#verify that this scan operation is for this scan widget
	#set scanOfInterest [$_newScanDef getOperationId]
	#if { $operationId != $scanOfInterest } {
    #    puts "this operation not started by me"
	#}


    set call_function none
	switch -exact -- $eventType {
		stog_start_operation {
        }
		stog_operation_update {
            switch -exact -- $arg1 {
                setup {
                    set call_function "setup"
                }
                done {
                    set call_function "done"
                }
                default {
                    set call_function "update"
                }
            }
        }
		stog_operation_completed {
            $itk_component(definition) findNextScanNumber 
            if {$arg1 != "normal"} {
                eval log_error $message_
            }
        }
		default {
			return \
            -code error "Should not have received this message: $_message"
		}
    }


	switch -exact -- $call_function {
		setup {
            #puts "got stog_start_operation"
            
            #timing needs to change:
            #all in ms from operation
            #needs to convert to seconds
            foreach {iTime dTime numScans delay} $arg7 break

            set oldTiming {}
            lappend oldTiming [expr $iTime / 1000.0]
            lappend oldTiming [expr $dTime / 1000.0]
            lappend oldTiming $numScans
            lappend oldTiming [expr $delay / 1000.0]
            lappend oldTiming "s"

			parseScanStart $arg4 $arg5 $arg6 $oldTiming $arg8 log_from_operation

            if {$arg9 != ""} {
                puts "parseExtraPamraters operation $arg9"
                parseExtraParameters "# extra    $arg9"
            }

		}
		done {
			$itk_component(log) log_string "Scan completed" warning
            
            if { [$_newScanDef getNumberOfMotors] == 2} {
                # in case of a incompleted scan
                # fill all empty nodes with minimum value of known nodes
                # and plot the contour
                $itk_component(2dGraph) allDataDone
            }
            #update new scan number
            $itk_component(definition) incrScanNumber 
		}
		update {
			parseScanUpdate $arg1 $arg2
			addToGraph 1
			addScanlogEntry
		}
	}
}
body DCS::ScanWidget::parseExtraParameters { line_ } {
    puts "+parseExtraParameters $line_"
    set v 0
    if {[string range $line_ 0 7] == "# extra "} {
        set contents [string range $line_ 8 end]
        set contents [eval dict create $contents]
        if {[dict exists $contents spiral]} {
            set v [dict get $contents spiral]
        }
    }
    puts "got spiral =$v"
    $_newScanDef setSpiralOn $v
    $_lastScanDef setSpiralOn $v
    $itk_component(spiral) setValue $v 1
    puts "-parseExtraParameters"
}

body DCS::ScanWidget::parseScanStart {	scanMotors_ detectors_ filters_ timing_ prefix_ logStyle_ } {

    puts "+parseScanStart $scanMotors_ $detectors_ $filters_ $timing_ $prefix_ $logStyle_"

    ###### switch to Graph Tab
	$itk_component(notebook) select Graph

	$_newScanDef setDefinition [lindex $scanMotors_ 0] [lindex $scanMotors_ 1]  $detectors_ $filters_ $timing_ $prefix_
    set _numMotors [$_newScanDef getNumberOfMotors]
    set _lastIndex [expr $_numMotors - 1]

	#store the signal list in the class field
	set _signalList $detectors_

    ####### update GUI ######################
    #change motor display
    $itk_component(axes1) setValues [lindex $scanMotors_ 0]
    $itk_component(axes2) setValues [lindex $scanMotors_ 1]
    $itk_component(definition) setValues $detectors_ $filters_ $timing_ $prefix_

	#check to see if the new scan is different from the last definition
    #puts "calling isEqual"
	set requiresReset [expr ! [$_lastScanDef isEqual $_newScanDef]]

	if {$requiresReset} {
        #puts "reset: store new over old"

		set _traceCnt 0
		
		resetViews

		#store the new definition over the lastScan definition
		$_lastScanDef setDefinition [lindex $scanMotors_ 0] [lindex $scanMotors_ 1]  $detectors_ $filters_ $timing_ $prefix_
	} else {
        #puts "no reset needed"
	    $itk_component(1dGraph) hideAllLegends
		incr _traceCnt
	}
	initializeGraphTraces
    addScanlogHeader $logStyle_


    #puts "-parseScanStart"
}

body DCS::ScanWidget::resetViews {} {

	#clear the log
	$itk_component(log) clear

	#reset graph
    set bltGraph [$itk_component(1dGraph) getBltGraph]
	bind $bltGraph <Control-ButtonPress-1> ""
	bind $bltGraph <Control-B1-Motion> ""
	bind $bltGraph <Control-ButtonRelease-1> ""
	bind $bltGraph <Control-ButtonPress-3> ""
	bind $bltGraph <Control-B3-Motion> ""
	bind $bltGraph <Control-ButtonRelease-3> ""
	bind $bltGraph <ButtonPress-2> ""
	bind $bltGraph <B2-Motion> ""
	bind $bltGraph <ButtonRelease-2> ""

	$itk_component(1dGraph) deleteAllTraces
	$itk_component(1dGraph) deleteAllMarkers
    set m_1dMarker1 ""
    set m_1dMarker2 ""
    set m_1dMarker3 ""

    $itk_component(2dGraph) clear
}



body DCS::ScanWidget::initializeGraphTraces {} {

	#puts "in init graph num of motors= [$_newScanDef getNumberOfMotors]"
	if { [$_newScanDef getNumberOfMotors] == 1 } {
        pack forget $itk_component(2dGraph)
        pack $itk_component(1dGraph) -expand 1 -fill both
		initializeGraphTracesFor1MotorScan
	} else {
        pack forget $itk_component(1dGraph)
        pack $itk_component(2dGraph) -expand 1 -fill both
		initializeGraphTracesFor2MotorScan
	}
}

body DCS::ScanWidget::createMarkerFor1MotorScan { mark_num } {
    if {$mark_num != 1 && $mark_num != 2} return

    upvar 0 m_1dMarker$mark_num mark
    if {$mark != ""} {
        return
    }

	set motorName [$_newScanDef getListOfMotors]

    if {$motorName == "time"} {
	    set units s
    } else {
	    set device [$m_deviceFactory getObjectName $motorName]
	    set units [$device cget -baseUnits]
    }
    set startPosition [lindex [$_newScanDef getStartPositionForMotor1] 0]
    set endPosition [lindex [$_newScanDef getEndPositionForMotor1] 0]
    if {$startPosition > $endPosition} {
        set startPosition $endPosition
    }
    set startPosition [expr $startPosition - 10000]

    if {$mark_num == 1} {
        set mark_color red
        set mark_button 1

        set markervObj [$itk_component(1dGraph) createCrosshairsMarker \
        "crosshairs$mark_num" $startPosition 0 "Position $units" "Counts" \
        -width 2 \
        -hide 1 \
        -color $mark_color \
        -callback "$this handleMarkerMovement $units"]
    } else {
        set mark_color #00a040
        set mark_button 3

        set markervObj [$itk_component(1dGraph) createCrosshairsMarker \
        "Position$mark_num-counts" $startPosition 0 "Position $units" "Counts" \
        -width 2 \
        -hide 1 \
        -color $mark_color]
    }

	bind [$itk_component(1dGraph) getBltGraph] <Control-ButtonPress-$mark_button> "$markervObj drag %x %y"
	bind [$itk_component(1dGraph) getBltGraph] <Control-B$mark_button-Motion> "$markervObj drag %x %y"
	bind [$itk_component(1dGraph) getBltGraph] <Control-ButtonRelease-$mark_button> "$markervObj drag %x %y"

    ####add middle button as Control+button 1
    if {$mark_button == 1} {
	bind [$itk_component(1dGraph) getBltGraph] <ButtonPress-2> "$markervObj drag %x %y"
	bind [$itk_component(1dGraph) getBltGraph] <B2-Motion> "$markervObj drag %x %y"
	bind [$itk_component(1dGraph) getBltGraph] <ButtonRelease-2> "$markervObj drag %x %y"
    }

    set mark $markervObj
}

body DCS::ScanWidget::initializeGraphTracesFor1MotorScan {} {

	set plot(color,0) \#000000
	set plot(color,1) \#cc0000
	set plot(color,2) \#00aa00
	set plot(color,3) \#0000dd
	set plot(color,4) \#6600aa
	set plot(color,5) \#aa4444
	set plot(color,6) \#ee5555
	set plot(color,7) \#ff8888 
	set plot(color,8) \#a0a
	set plot(color,9) \#0a0

	set motorName [$_newScanDef getListOfMotors]

	#configure the title
	$itk_component(1dGraph) configure -title "[lindex $motorName 0] $m_currentFile"

    if {$motorName == "time"} {
        set units s
    } else {
	    set device [$m_deviceFactory getObjectName $motorName]
	    set units [$device cget -baseUnits]
    }
	
	$itk_component(1dGraph) createTrace Position$_traceCnt [list "Position $units"] {}

	set signalCnt [llength $_signalList]
    puts "signalCnt: $signalCnt"
	
	$itk_component(1dGraph) createSubTrace Position$_traceCnt [lindex $_signalList 0] \
		 { "Signal Counts" "Counts" } {} \
		 -width 1 -symbol circle -symbolSize 2 -color $plot(color,[expr $_traceCnt % 10])
	
	if {$signalCnt >= 2} {
        #sub-trace names are stored in a SET, make sure no duplicates.
        set ref_trace_name [lindex $_signalList 1]
        if {$ref_trace_name == [lindex $_signalList 0]} {
            set ref_trace_name ${ref_trace_name}_ref
        }
		$itk_component(1dGraph) createSubTrace Position$_traceCnt $ref_trace_name { "Reference Counts" "Counts" } {} -color red 
	}
    for {set i 2} {$i < $signalCnt} {incr i} {
        set extra_trace_name [lindex $_signalList $i]
        set end_index [expr $i - 1]
        set checkList [lrange $_signalList 0 $end_index]
        if {[lsearch -exact $checkList $extra_trace_name] >= 0} {
            set extra_trace_name Signal[expr $i + 1]
        }
		$itk_component(1dGraph) createSubTrace Position$_traceCnt \
        $extra_trace_name [list "Signal[expr $i + 1] Counts" Counts] {} \
        -color $plot(color,[expr ($_traceCnt + $i) % 10])

        puts "created subtrace: $extra_trace_name"
    }
	if {$signalCnt >= 2} {
		$itk_component(1dGraph) createSubTrace Position$_traceCnt absb { "Absorbance" } {} -color brown
		$itk_component(1dGraph) createSubTrace Position$_traceCnt trns { "Transmission" } {} -color green
        puts "created subtrace: absb and trns"
	}

	$itk_component(1dGraph) configure -xLabel "Position $units" -x2Label "" -y2Label ""


	# create the vertical marker
    createMarkerFor1MotorScan 1
    createMarkerFor1MotorScan 2

    #link them into a pair to display delta
    $m_1dMarker1 configure -pair $m_1dMarker2
    $m_1dMarker2 configure -pair $m_1dMarker1
}

body DCS::ScanWidget::handleMarkerMovement { units_ value_ dummy } {
	#It would be nice if the marker could give us the units directly, but until then
	#we can intercept and add the units ourselves
	$itk_component(deviceViewer) setValue [list $value_ $units_]
}

body DCS::ScanWidget::handle2DMarkMovement { position1 position2 } {
	$itk_component(deviceViewer) setValue $position1
	$itk_component(deviceViewer2) setValue $position2
}

body DCS::ScanWidget::initializeGraphTracesFor2MotorScan {} {

    #we can get num of row, column and max min value for them now
    set motor1 [$_newScanDef getMotor1ScanDefinition]
    set motor2 [$_newScanDef getMotor2ScanDefinition]

	set motorNames [$_newScanDef getListOfMotors]
    $itk_component(2dGraph) setTitle "$motorNames $m_currentFile"

    set n1      [$motor1 getTotalPoints]
    set pStart1 [$motor1 getStartPosition]
    set pEnd1   [$motor1 getEndPosition]
    set n2      [$motor2 getTotalPoints]
    set pStart2 [$motor2 getStartPosition]
    set pEnd2   [$motor2 getEndPosition]

    set pStep1 0
    if {$n1 > 1} {
        set start1 [lindex $pStart1 0]
        set end1   [lindex $pEnd1   0]
        set pStep1 [expr (double($end1) - $start1) / ($n1 - 1)]
    }
    set pStep2 0
    if {$n2 > 1} {
        set start2 [lindex $pStart2 0]
        set end2   [lindex $pEnd2   0]
        set pStep2 [expr (double($end2) - $start2) / ($n2 - 1)]
    }

    if {[catch {
    $itk_component(2dGraph) setup $n1 $pStart1 $pStep1 $n2 $pStart2 $pStep2
    } errMsg]} {
        puts "ERROR: $errMsg"
    }

    $itk_component(2dGraph) registerMarkMoveCallback "$this handle2DMarkMovement"
}


body DCS::ScanWidget::parseScanUpdate { motorPositions_ signalReadings_ } {
	
	set _lastMotorPositions $motorPositions_
	set _lastSignalReadings $signalReadings_
}

body DCS::ScanWidget::addScanlogHeader { style } {

    switch -exact -- $style {
        no_log {
            return
        }
        log_from_file {
	        $itk_component(log) log_string "Scan load from file" warning 0
        }
        log_from_operation {
	        $itk_component(log) log_string "Scan started" warning
        }
    }

	set logEntry ""
	
    set _motorFieldWidth ""
	foreach motorName [$_newScanDef getListOfMotors] {
        set field [format "%${MIN_FIELD_WIDTH_MOTOR}s" $motorName]
		append logEntry "$field "
        lappend _motorFieldWidth [string length $field]
	}

    set _signalFieldWidth ""
	foreach signalName $_signalList {
		set field [format "%${MIN_FIELD_WIDTH_SIGNAL}s" $signalName]
		append logEntry "$field "
        lappend _signalFieldWidth [string length $field]
	}
    if {[llength $_signalList] < 2} {
	    $itk_component(log) log_string $logEntry warning 0
        return
    }

    ####need transmission and absorption
    foreach {sig ref} $_signalList break
    ### get max length of first and seoncd signal
    set l1 [string length $sig]
    set l2 [string length $ref]
    set ll [expr ($l1 >= $l2)?$l1:$l2]
    ####generate lines
    set le [string length $logEntry]
    set pad_space [string repeat " " $le]
    set pad_dash [string repeat - $ll]

    set l_f1 $ll
    if {$l_f1 < $MIN_FIELD_WIDTH_SIGNAL} {
        set l_f1 $MIN_FIELD_WIDTH_SIGNAL
    }
    set l_f2 [expr $ll + 4]
    if {$l_f2 < $MIN_FIELD_WIDTH_SIGNAL} {
        set l_f2 $MIN_FIELD_WIDTH_SIGNAL
    }

    ###first line and third line are similar
    set first_line  $pad_space
    set second_line $logEntry
    set third_line  $pad_space
    append first_line  [format "%${l_f1}s %${l_f2}s" $sig $sig]
    append second_line [format "%${l_f1}s %${l_f2}s" $pad_dash -log$pad_dash]
    append third_line  [format "%${l_f1}s %${l_f2}s" $ref $ref]

    $itk_component(log) log_string $first_line warning 0
    $itk_component(log) log_string $second_line warning 0
    $itk_component(log) log_string $third_line warning 0

    lappend _signalFieldWidth $l_f1 $l_f2
}


body DCS::ScanWidget::addScanlogEntry { } {

	set logEntry ""

    set i -1
	foreach motorPosition $_lastMotorPositions {
        incr i
        set width [lindex $_motorFieldWidth $i]
        if {$width == ""} {
            log_error "scan data not match for motor $i"
            set width $MIN_FIELD_WIDTH_MOTOR
        }
		append logEntry [format "%#$width.6f " $motorPosition]
	}

    set i -1
	foreach signal $_lastSignalReadings {
        incr i
        set width [lindex $_signalFieldWidth $i]
        if {$width == ""} {
            log_error "scan data not match for signal $i"
            set width $MIN_FIELD_WIDTH_SIGNAL
        }
		#check if integer
		if { int($signal) != $signal } {
			append logEntry [format "%#$width.6f " $signal]
		} else {
			append logEntry [format "%$width.0f " $signal]
		}
	}

	# update the scanlog window
	$itk_component(log) log_string $logEntry warning 0
}


body DCS::ScanWidget::addToGraph { { draw 1 } } {
	
	set numMotor [$_newScanDef getNumberOfMotors]
	if { $numMotor == 1 } {
		$itk_component(1dGraph) addToTrace Position$_traceCnt $_lastMotorPositions $_lastSignalReadings
	} elseif { $numMotor == 2 } {
        $itk_component(2dGraph) addData $_lastMotorPositions $_lastSignalReadings $draw
    }
}

body DCS::ScanWidget::changeScanDevice { motorName_ } {

    if {$motorName_ == "" || $motorName_ == "(none)" || $motorName_ == "time"} {
        if {$_lastDevice == ""} {
            return
        }
        ########## hide motor1 #############
	    $itk_component(control) unregisterMotorWidget ::$itk_component(deviceViewer)
		$itk_component(scanButton) deleteInput "$_lastDevice status inactive {supporting device}"
        pack forget $itk_component(deviceViewer)
        set _lastDevice ""
        return
    }

	set deviceObject [$m_deviceFactory getObjectName $motorName_]

    if {$_lastDevice == $deviceObject} {
        return
    }

	changeMotorView $motorName_ $deviceObject
	
	if {$_lastDevice == "" } {
        #### redisplay motor1
        if {$_lastDevice2 != ""} {
            pack forget $itk_component(deviceViewer2)
        }
        pack forget $itk_component(control)

        pack $itk_component(deviceViewer)
        if {$_lastDevice2 != ""} {
            pack $itk_component(deviceViewer2)
        }
        pack $itk_component(control)
	    $itk_component(control) registerMotorWidget ::$itk_component(deviceViewer)
    } else {
		$itk_component(scanButton) deleteInput "$_lastDevice status inactive {supporting device}"
	}

	#add the status of the new motor to the input to the Start Scan button
	$itk_component(scanButton) addInput "$deviceObject status inactive {supporting device}"

	#remember the last device for next time there is a change
	set _lastDevice $deviceObject
}

body DCS::ScanWidget::changeScanDevice2 { motorName_ } {

    if {$motorName_ == "" || $motorName_ == "(none)" || $motorName_ == "time"} {
        if {$_lastDevice2 == ""} {
            return
        }
        ########## hide motor2 #############
	    $itk_component(control) unregisterMotorWidget ::$itk_component(deviceViewer2)
		$itk_component(scanButton) deleteInput "$_lastDevice2 status inactive {supporting device}"
        pack forget $itk_component(deviceViewer2)
        set _lastDevice2 ""
        return
    }

	set deviceObject [$m_deviceFactory getObjectName $motorName_]

    if {$_lastDevice2 == $deviceObject} {
        return
    }

	changeMotorView2 $motorName_ $deviceObject
	
	if {$_lastDevice2 == "" } {
        #### redisplay motor2
        pack forget $itk_component(control)
        pack $itk_component(deviceViewer2)
        pack $itk_component(control)
	    $itk_component(control) registerMotorWidget ::$itk_component(deviceViewer2)
    } else {
		$itk_component(scanButton) deleteInput "$_lastDevice2 status inactive {supporting device}"
	}

	#add the status of the new motor to the input to the Start Scan button
	$itk_component(scanButton) addInput "$deviceObject status inactive {supporting device}"

	#remember the last device for next time there is a change
	set _lastDevice2 $deviceObject
}

body DCS::ScanWidget::handleMotorSelection { caller_ targetReady_ - motorName_ initiatorId_ } {
	
	if { ! $targetReady_} return
	
	changeScanDevice $motorName_
}

body DCS::ScanWidget::handleMotor2Selection { caller_ targetReady_ - motorName_ initiatorId_ } {
	
	if { ! $targetReady_} return
	
	changeScanDevice2 $motorName_
}

body DCS::ScanWidget::changeMotorView { motorName_ deviceObject_ } {
	$itk_component(deviceViewer) configure \
    -device $deviceObject_ \
	-labelText $motorName_ \
	-units [$deviceObject_ cget -baseUnits]
}

body DCS::ScanWidget::changeMotorView2 { motorName_ deviceObject_ } {
	$itk_component(deviceViewer2) configure \
    -device $deviceObject_ \
	-labelText $motorName_ \
	-units [$deviceObject_ cget -baseUnits]
}

body DCS::ScanWidget::createMotorControlFrame { frame } {
	# create labeled frame
	itk_component add motorControlFrame {
		::iwidgets::labeledframe $frame.mc \
             -labelpos nw \
             -labelmargin 0 \
			 -labelfont "helvetica -16 bold" \
			 -labeltext "Motor Control"
	} {
		keep -background
	}

	set motorControlFrame [ $itk_component(motorControlFrame) childsite]

	# construct the table widgets
	itk_component add deviceViewer {
		::DCS::TitledMotorEntry $motorControlFrame.motor \
        -honorStatus 0 \
		-labelText "Null" \
        -autoGenerateUnitsList 1 \
        -activeClientOnly 0 \
        -units mm
	} {
		keep -activeClientOnly
        keep -systemIdleOnly
		keep -mdiHelper
	}
	
	itk_component add deviceViewer2 {
		::DCS::TitledMotorEntry $motorControlFrame.motor2 \
        -honorStatus 0 \
		-labelText "Null" \
        -autoGenerateUnitsList 1 \
        -activeClientOnly 0 \
        -units mm
	} {
		keep -activeClientOnly
        keep -systemIdleOnly
		keep -mdiHelper
	}
	
	# construct the panel of control buttons
	itk_component add control {
		::DCS::MotorControlPanel  $motorControlFrame.control \
            -serialMove 1 \
			-width 7 -orientation "vertical" \
			-ipadx 4 -ipady 2  -buttonBackground #c0c0ff \
			-activeButtonBackground #c0c0ff  -font "helvetica -14 bold"
	} {
	}

	pack $itk_component(deviceViewer)
	pack $itk_component(control)

}

body DCS::ScanWidget::createMenuFrame { frame } {
	itk_component add menuFrame {
        frame $frame.menu \
        -height         30 \
        -borderwidth    2 \
        -relief         raised
    } {
    }

	set menuFm $itk_component(menuFrame)

    itk_component add fileButton {
        menubutton $menuFm.file \
        -text "File" \
        -menu $menuFm.file.menu
    } {
    }

    itk_component add fileMenu {
        menu $menuFm.file.menu \
        -tearoff 0
    } {
    }

    $itk_component(fileMenu) add command \
    -label "Attach to current scan" \
    -command "$this connectToCurrent"

    $itk_component(fileMenu) add command \
    -label "Load current scan file" \
    -command "$this loadCurrentScanFile"

    $itk_component(fileMenu) add command \
    -label "Load scan from file" \
    -command "$this loadScanDialog"

    $itk_component(fileMenu) add command \
    -label "Load Next Scan" \
    -command "$this loadNextScan"

    $itk_component(fileMenu) add command \
    -label "Load Previous Scan" \
    -command "$this loadPreviousScan"

    $itk_component(fileMenu) add command \
    -label "Detach from current scan" \
    -command "$this markAsNotConnected"

    $itk_component(fileMenu) add command \
    -label "Print 1D graph" \
    -command "$this print1DGraph"

    $itk_component(fileMenu) add command \
    -label "Print 2D graph" \
    -command "$this print2DGraph"

    pack $itk_component(fileButton) -side left
}

body DCS::ScanWidget::createAxisDefinitionFrame { frame } {

	# create labeled frame
	itk_component add scanAxesTitle {
		frame $frame.aTitle \
        -relief groove \
        -borderwidth 2
	} {
		keep -background
	}

	set axesFrame $itk_component(scanAxesTitle)
	
	itk_component add axes1 {
		DCS::ScanAxesWidget $axesFrame.a1 \
			 [$_newScanDef getMotor1ScanDefinition] \
			 [$_lastScanDef getMotor1ScanDefinition]
	} { keep -deviceList
	}
		
	itk_component add axes2 {
		DCS::ScanAxesWidget $axesFrame.a2  \
			 [$_newScanDef getMotor2ScanDefinition] \
			 [$_lastScanDef getMotor2ScanDefinition] \
             -includeNone 1 \
             -showPrompts 0
	} { keep -deviceList
	}



	pack $itk_component(axes1)
	pack $itk_component(axes2)
}

body DCS::ScanWidget::createStartScanFrame { frame  } {

	# create labeled frame
	itk_component add startScanFrame {
		::iwidgets::labeledframe $frame.s \
        -labelmargin 0 \
        -labelpos nw \
        -labeltext "Scan Control" \
        -labelfont "helvetica -16 bold"
	} {
		keep -background
	}

    set scanControlSite [$itk_component(startScanFrame) childsite]
	
	itk_component add scanButton {
		DCS::Button $scanControlSite.b -text "Scan" \
			 -font "helvetica -14 bold" -width 7
	} {
	}
	
	itk_component add stopButton {
		DCS::Button $scanControlSite.s \
        -systemIdleOnly 0 \
        -text "Stop" \
	    -font "helvetica -14 bold" \
        -width 7
	} {
	}

    itk_component add backlash {
        label $scanControlSite.bl \
        -text "Backlash" \
        -foreground red
    } {
    }

    itk_component add spiral {
        ::DCS::Checkbutton $scanControlSite.spiral \
        -reference "$_lastScanDef -spiralOn" \
        -text Spiral \
        -activeClientOnly 0 \
        -systemIdleOnly 0 \
    } {
    }
    $_newScanDef configure -spiralReference "::$itk_component(spiral) -value"
	
	$itk_component(scanButton) configure -command \
    "$this markAsConnected; $_newScanDef startScan"
	
	grid $itk_component(backlash)   -row 0 -column 0
	grid $itk_component(scanButton) -row 1 -column 0
	grid $itk_component(stopButton) -row 2 -column 0
	grid $itk_component(spiral)     -row 3 -column 0
}

body DCS::ScanWidget::registerAllButtons {} {
	$itk_component(scanButton) addInput "$m_opObj status inactive {supporting device}"

	#register for interest in the first axes's mode
	$itk_component(axes1) register $this -mode handleModeChange

	$itk_component(axes1) registerForDeviceSelection $this handleMotorSelection
	$itk_component(axes2) registerForDeviceSelection $this handleMotor2Selection

	$itk_component(stopButton) configure \
    -command "$itk_option(-controlSystem) sendMessage {gtos_stop_operation scanMotor}"
}


body DCS::ScanWidget::handleModeChange { caller_ targetReady_ - mode_ initiatorId_} {
	if { ! $targetReady_} return
	$itk_component(axes2) configure -mode $mode_ 
}

body DCS::ScanWidget::handleFilenameChange { caller_ targetReady_ - name_ initiatorId_} {
    if {!$targetReady_} return
    if {!$m_connectToCurrentScan} return
    if {$name_ == $m_currentFile} return

    #puts "new scan file: $name_"
    set m_currentFile $name_

	set motorName [$_newScanDef getListOfMotors]

	#configure the title
	$itk_component(1dGraph) configure -title "[lindex $motorName 0] $m_currentFile"
}
body DCS::ScanWidget::handleBacklashChange { - targetReady_ - need_ - } {
    if {!$targetReady_} return

    if {$need_} {
        grid $itk_component(backlash)
    } else {
        grid remove $itk_component(backlash)
    }
}
body DCS::ScanWidget::handleShowSpiralChange { - targetReady_ - need_ - } {
    if {!$targetReady_} return

    if {$need_} {
        grid $itk_component(spiral)
    } else {
        grid remove $itk_component(spiral)
    }
}

class DCS::ScanDefinitionWidget {
 	inherit ::itk::Widget

	itk_option define -device device Device ""
	itk_option define -mdiHelper mdiHelper MdiHelper ""
	itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -deviceList deviceList DeviceList ""

    public method selectSeFoil { } {
        if {[info exists itk_component(Se)]} {
            $itk_component(Se) setValue closed
            $itk_component(Se) doCommand
        } else {
            log_warning skip select Se foil for energy. foil Se not found.
        }
    }

    public method incrScanNumber { } {
        set counter [$itk_component(scanNumber) get]
        incr counter
        $itk_component(scanNumber) setValue $counter
    }
    public method findNextScanNumber { } {
        global gImpWrapAvailable

        #puts "+findNextScanNumber"

        set dir [$itk_component(directory) get]
        set fileRoot [$itk_component(fileRoot) get]

        if {![catch { get_next_counter $dir $fileRoot "scan" } newScanNum]} {
            $itk_component(scanNumber) setValue $newScanNum

            #puts "-findNextScanNumber $newScanNum"
            return
        }

        if {!$gImpWrapAvailable} {
            log_error findNextScanNumber failed: $newScanNum
            return
        }

        set username [$itk_option(-controlSystem) getUser]
        set sessionId [$itk_option(-controlSystem) getSessionId]
        set sessionId [getTicketFromSessionId $sessionId]

        set result [ catch {
            set newScanNum [impGetNextFileIndex $username $sessionId $dir $fileRoot "scan"]
        } errorText] 
        if { $result } {
            log_error impGetNextFileIndex failed $errorText
            return
        }
        $itk_component(scanNumber) setValue $newScanNum

        #puts "-findNextScanNumber $newScanNum"
    }

    public method setValues { detecters filters timing prefix } {
        #puts "setValues: sign=[lindex $detecters 0]"
        $itk_component(signal) setValue    [lindex $detecters 0] 1
        $itk_component(reference) setValue [lindex $detecters 1] 1
        $itk_component(signal3) setValue    [lindex $detecters 2] 1
        $itk_component(signal4) setValue    [lindex $detecters 3] 1

        #set filters
        #check filter names
        foreach foil $filters {
            if {[lsearch $m_allFoilList $foil] == -1} {
                log_warning bad foil name $foil. ignored
            }
        }

        foreach {foil label} $m_allFoilList {
            if {[lsearch $filters $foil] != -1} {
                $itk_component($foil) setValue closed
            } else {
                $itk_component($foil) setValue open
            }
            $itk_component($foil) updateTextColor
        }


        $itk_component(integrationTime) setValue   "[lindex $timing 0] s" 1
        $itk_component(motorSettlingTime) setValue "[lindex $timing 1] s" 1
        $itk_component(numScans) setValue          [lindex $timing 2] 1
        $itk_component(delayBetweenScans) setValue [lrange $timing 3 4] 1

        $itk_component(directory) setValue [lindex $prefix 0] 1
        $itk_component(fileRoot) setValue [lindex $prefix 1] 1
        $itk_component(scanNumber) setValue [lindex $prefix 2] 1
        findNextScanNumber
    }


	protected variable _baseUnits
	protected variable _unappliedChanges ""

	private variable _newFullScanDef ""
	private variable _lastFullScanDef ""

    private variable m_deviceFactory ""
    private variable m_allFoilList ""

	constructor { lastScanDef_ newScanDef_ args} {
        #puts "+constructor of scan def widgets"

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_allFoilList [::config getStr bluice.filterLabelMap]

		set _lastFullScanDef $lastScanDef_
		set _newFullScanDef $newScanDef_

		itk_component add ring {
			frame $itk_interior.r 
		}

		# create labeled frame
		itk_component add DetectorTitle {
			::iwidgets::labeledframe $itk_component(ring).dTitle \
                 -labelmargin 0 \
                 -labelpos nw \
				 -labelfont "helvetica -16 bold" \
				 -labeltext "Detectors"
		} {
			keep -background
		}

		set detectorFrame [ $itk_component(DetectorTitle) childsite]

		itk_component add signal {
			DCS::MenuEntry $detectorFrame.sig1 -entryType string \
                 -entryMaxLength 0 \
				 -entryWidth 22 -showEntry 0 \
				 -promptText "Signal:"  -promptWidth 10 \
				 -reference "$_lastFullScanDef -signal" \
				 -activeClientOnly 0 -systemIdleOnly 0
				 #-alternateShadowReference "$_newFullScanDef -signal" \

		} {
		}

		itk_component add reference {
			DCS::MenuEntry $detectorFrame.sig2 -entryType string \
                 -entryMaxLength 0 \
				 -entryWidth 22 -showEntry 0 \
				 -promptText "Reference:" -promptWidth 10 \
				 -reference "$_lastFullScanDef -referenceSignal" \
				 -activeClientOnly 0 -systemIdleOnly 0
				 #-alternateShadowReference "$_newFullScanDef -referenceSignal" \
		} {
		}

		itk_component add signal3 {
			DCS::MenuEntry $detectorFrame.sig3 -entryType string \
                 -entryMaxLength 0 \
				 -entryWidth 22 -showEntry 0 \
				 -promptText "Signal3:"  -promptWidth 8 \
				 -reference "$_lastFullScanDef -signal3" \
				 -activeClientOnly 0 -systemIdleOnly 0
				 #-alternateShadowReference "$_newFullScanDef -signal3" \

		} {
		}

		itk_component add signal4 {
			DCS::MenuEntry $detectorFrame.sig4 -entryType string \
                 -entryMaxLength 0 \
				 -entryWidth 22 -showEntry 0 \
				 -promptText "Signal4:"  -promptWidth 8 \
				 -reference "$_lastFullScanDef -signal4" \
				 -activeClientOnly 0 -systemIdleOnly 0
				 #-alternateShadowReference "$_newFullScanDef -signal4" \

		} {
		}

		grid $itk_component(signal) $itk_component(signal3)
		grid $itk_component(reference) $itk_component(signal4)


		# create labeled frame
		itk_component add RepeatTitle {
			::iwidgets::labeledframe $itk_component(ring).rTitle \
                 -labelmargin 0 \
                 -labelpos nw \
				 -labelfont "helvetica -16 bold" \
				 -labeltext "Repeat"
		} {
			keep -background
		}

		set repeatFrame [ $itk_component(RepeatTitle) childsite]

		itk_component add numScans {
			DCS::Entry $repeatFrame.ns -entryType float \
				 -promptWidth 20 \
				 -entryWidth 12 -entryJustify right\
				 -promptText "Number of scans:" \
				 -reference "$_lastFullScanDef -numScans" \
				 -entryType int -unitsWidth 4 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
		}

		$itk_component(numScans) setValue 1 1
		$itk_component(numScans) configure -referenceValue 1
		pack $itk_component(numScans)

		itk_component add delayBetweenScans {
			DCS::Entry $repeatFrame.it -entryType float \
				 -promptWidth 20 \
				 -entryWidth 12 -entryJustify right\
				 -promptText "Delay between scans:" \
				 -unitsList {ms {-entryType int} s {-entryType float} min {} } \
				 -units s \
				 -unitsWidth 4 \
				 -unitConvertor ::units -autoConversion 1 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
		}
		
		$itk_component(delayBetweenScans) setValue {0.0 s} 1
		$itk_component(delayBetweenScans) configure -referenceValue [list 0.0 s]
		pack $itk_component(delayBetweenScans)



		# create labeled frame
		itk_component add timingTitle {
			::iwidgets::labeledframe $itk_component(ring).tTitle \
                 -labelmargin 0 \
                 -labelpos nw \
				 -labelfont "helvetica -16 bold" \
				 -labeltext "Timing"
		} {
			keep -background
		}

		set timingFrame [ $itk_component(timingTitle) childsite]


		itk_component add integrationTime {
			DCS::Entry $timingFrame.it -entryType float \
				 -promptWidth 17 \
				 -entryWidth 12 -entryJustify right\
				 -promptText "Integration Time:" \
				 -unitsList {ms {-entryType int} s {-entryType float} min {} } \
				 -units s \
				 -unitsWidth 4 \
				 -reference "$_lastFullScanDef -integrationTime" \
				 -unitConvertor ::units -autoConversion 1 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
		}
		
		$itk_component(integrationTime) setValue {0.1 s} 1
		#$itk_component(integrationTime) configure -referenceValue [list 0.1 s]
		pack $itk_component(integrationTime)

		itk_component add motorSettlingTime {
			DCS::Entry $timingFrame.mwt -entryType float \
				 -promptWidth 17 \
				 -entryWidth 12 -entryJustify right\
				 -promptText "Motor Settling Time:" \
				 -unitsList {ms {-entryType int} s {-entryType float} min {} } \
				 -units s \
				 -unitsWidth 4 \
				 -reference "$_lastFullScanDef -motorSettlingTime" \
				 -unitConvertor ::units -autoConversion 1 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
		}

		$itk_component(motorSettlingTime) setValue {0.0 s} 1
		#$itk_component(motorSettlingTime) configure -referenceValue [list 0.0 s]
		pack $itk_component(motorSettlingTime)

		# create labeled frame
		itk_component add FilesTitle {
			::iwidgets::labeledframe $itk_component(ring).fTitle \
                 -labelmargin 0 \
                 -labelpos nw \
				 -labelfont "helvetica -16 bold" \
				 -labeltext "Files"
		} {
			keep -background
		}

		
		set filesFrame [ $itk_component(FilesTitle) childsite]


        itk_component add directory {
			DCS::DirectoryEntry $filesFrame.dir \
				 -promptWidth 14 \
				 -entryType rootDirectory \
				 -entryWidth 64 -entryJustify left\
                 -entryMaxLength 128 \
				 -promptText "Directory:" \
				 -activeClientOnly 0 -systemIdleOnly 0
        } {
        }
		$itk_component(directory) setValue "~" 1
		pack $itk_component(directory) -side top -fill x

		itk_component add fileRoot {
			DCS::Entry $filesFrame.fr -entryType float \
				 -promptWidth 14 \
				 -entryType field \
				 -entryWidth 64 -entryJustify left\
                 -entryMaxLength 128 \
				 -promptText "Filename root:" \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
		}
		
        set valRoot "[::config getConfigRootName]"
        #puts "value for file root: {$valRoot}"
		$itk_component(fileRoot) setValue $valRoot 1
		pack $itk_component(fileRoot) -side top -fill x
		
		itk_component add scanNumber {
			DCS::Entry $filesFrame.sn -entryType positiveInt \
				 -promptWidth 14 \
				 -entryWidth 12 -entryJustify right\
				 -promptText "Scan Number:" \
				 -unitsWidth 4 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
		}

		$itk_component(scanNumber) setValue 1 1
		#$itk_component(scanNumber) configure -referenceValue 1
		pack $itk_component(scanNumber) -side top -anchor w


		# create labeled frame
		itk_component add FoilsTitle {
			frame $itk_component(ring).foilsTitle \
            -relief groove \
            -borderwidth 2
		} {
			keep -background
		}

        set foilFrame $itk_component(FoilsTitle)

        itk_component add title {
            label $foilFrame.title \
            -text "Foils: " \
            -font "helvetica -16 bold"
        } {
        }

        pack $itk_component(title) -side left

        set fcb_count 0
        foreach {device label} $m_allFoilList {
            #puts "adding $device"
            itk_component add $device {
                ::DCS::Checkbutton $foilFrame.cb$fcb_count \
                -offvalue open \
                -onvalue closed \
                -text "$label" \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
            } {
            }

            incr fcb_count
            pack $itk_component($device) -side left

            set devObj [$m_deviceFactory getObjectName $device]

            #$itk_component($device) setValue [$devObj cget -state] 1
            $itk_component($device) setValue open
            $itk_component($device) configure -reference "$devObj state"
        }

		$_newFullScanDef configure -signalReference "::$itk_component(signal) -value"
		$_newFullScanDef configure -referenceSignalReference "::$itk_component(reference) -value"
		$_newFullScanDef configure -signal3Reference "::$itk_component(signal3) -value"
		$_newFullScanDef configure -signal4Reference "::$itk_component(signal4) -value"
		$_newFullScanDef configure -numScansReference "::$itk_component(numScans) -value"
		$_newFullScanDef configure -delayBetweenScansReference "::$itk_component(delayBetweenScans) -value"
		$_newFullScanDef configure -integrationTimeReference "::$itk_component(integrationTime) -value"
		$_newFullScanDef configure -motorSettlingTimeReference "::$itk_component(motorSettlingTime) -value"
		$_newFullScanDef configure -directoryReference "::$itk_component(directory) -value"
		$_newFullScanDef configure -filenameReference "::$itk_component(fileRoot) -value"
		$_newFullScanDef configure -scanNumberReference "::$itk_component(scanNumber) -value"
        foreach {device label} $m_allFoilList {
		    $_newFullScanDef configure -filterReference "::$itk_component($device) -value"
        }

		grid $itk_component(DetectorTitle) -row 0 -column 0 -columnspan 2 -sticky news
		grid $itk_component(RepeatTitle) -row 0 -column 2 -sticky news

		grid $itk_component(timingTitle) -row 1 -column 0 -sticky news
		grid $itk_component(FilesTitle) -row 1 -column 1 -columnspan 2 -sticky news

		grid $itk_component(FoilsTitle) -row 2 -column 0 -columnspan 3 -sticky news

		#grid propagate $itk_component(ring) 1
		grid rowconfigure $itk_component(ring) 0 -weight 1
		grid rowconfigure $itk_component(ring) 1 -weight 1
		grid rowconfigure $itk_component(ring) 2 -weight 1
		#		grid rowconfigure $itk_component(ring) 3 -weight 1

		grid columnconfigure $itk_component(ring) 0 -weight 10
		grid columnconfigure $itk_component(ring) 1 -weight 1

		pack $itk_component(ring) -fill both -expand 1
		
		eval itk_initialize $args

        #create the menu selection for the signal list
        set includeEncoders [::config getStr "scan.encoderAsSignal"]
        if {$includeEncoders == "1"} {
		    set realSignalList [$m_deviceFactory getIonChamberAndEncoderList]
        } else {
		    set realSignalList [$m_deviceFactory getSignalList]
        }
		
		$itk_component(signal) configure -menuChoices $realSignalList

		set signalList {}
		eval lappend signalList (none) $realSignalList
		$itk_component(reference) configure -menuChoices $signalList
		$itk_component(signal3) configure -menuChoices $signalList
		$itk_component(signal4) configure -menuChoices $signalList

		$itk_component(reference) setValue "" 1
		$itk_component(signal3) setValue "" 1
		$itk_component(signal4) setValue "" 1
        #puts "-constructor of scan def widgets"
	}

	destructor {
		destroy $_unappliedChanges
	}
}


class DCS::ScanAxesWidget {
 	inherit ::itk::Widget ::DCS::Component

	itk_option define -mode mode Mode start
	itk_option define -showPrompts showPrompts ShowPrompts 1
	itk_option define -orientation orientation Orientation "horizontal"
	#itk_option define -showUnits showUnits ShowUnits 1

    itk_option define -includeNone includeNone IncludeNone 0
    itk_option define -includeTime includeTime IncludeTime 1
    itk_option define -deviceList deviceList DeviceList ""

	private variable _device ""

	#itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handleBacklashChange

	public method handleDeviceChange
	public method handleUnitsSelection
	public method changeAllEntryUnits
	public method registerForDeviceSelection
	public method resetAxisCenter
	public method swapStartEnd
	#public method setDevice { device_ } { $itk_component(deviceName) setValue $device_ }

    public method setValues

	public method toggleMode

	protected method changeScanMode
	protected method shrinkWidget
	private method repackCenterMode
	private method repackStartMode
	private method repackFullMode

	private variable _lastScanDef ""
	private variable _newScanDef ""


    private variable m_deviceFactory

    private variable m_origBG

	constructor { newScanDef_ lastScanDef_ args} {
		::DCS::Component::constructor {-mode "cget -mode"} 
	} {
        #puts "+ScanAxesWidget::constructor $args" 
		
        set m_deviceFactory [DCS::DeviceFactory::getObject]

		# {device_ points_ start_ end_ steps_ args }

		itk_component add ring {
			frame $itk_interior.r
		}
		
		set _lastScanDef $lastScanDef_ 
		set _newScanDef $newScanDef_
		

        #puts "add deviceName"
		itk_component add deviceName {
			DCS::MenuEntry $itk_component(ring).name \
				 -entryType string -entryWidth 25 \
                 -entryMaxLength 80 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
		}

		itk_component add totalPoints {
			DCS::Entry $itk_component(ring).p \
                 -entryType positiveInt \
				 -entryJustify right \
				  -unitsWidth 7 -autoConversion 0 \
				  -entryWidth 8 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -showUnits
			keep -state
		}

		itk_component add startPosition {
			DCS::Entry $itk_component(ring).sp -autoGenerateUnitsList 1 \
                 -entryType float \
				 -entryWidth 12 -entryJustify right \
				 -unitsWidth 7 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -showUnits
			keep -state
		}
		

		itk_component add centerPosition {
			DCS::Entry  $itk_component(ring).cp -entryWidth 12 -entryJustify right \
                 -entryType float \
				 -autoGenerateUnitsList 1 \
				 -unitsWidth 7 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -showUnits
			keep -state
		}

		itk_component add endPosition {
			DCS::Entry $itk_component(ring).ep -entryWidth 12 -entryJustify right  \
                 -entryType float \
				 -autoGenerateUnitsList 1 \
				 -unitsWidth 7 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -showUnits
			keep -state
		}

		itk_component add scanWidth {
			DCS::Entry $itk_component(ring).w -entryWidth 12 -entryJustify right \
				 -autoGenerateUnitsList 1 \
				 -unitsWidth 7 \
                 -entryType positiveFloat \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -showUnits
			keep -state
		}
	
		itk_component add stepSize {
			DCS::Entry  $itk_component(ring).ss -entryWidth 12 -entryJustify right \
				 -autoGenerateUnitsList 1 \
                 -entryType float \
				 -unitsWidth 7 \
				 -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -showUnits
			keep -state
		}
		

		itk_component add globalUnits {
			DCS::MenuEntry $itk_component(ring).units \
				 -entryType string \
				 -entryWidth 5 \
				 -showEntry 0 \
				 -activeClientOnly 0 \
				 -systemIdleOnly 0
		} {
			keep -state
		}

		$itk_component(globalUnits) setValue "" 1


		itk_component add updateButton {
			DCS::Button $itk_component(ring).button \
		    -text "Update" \
            -command "$this resetAxisCenter" \
            -activeClientOnly 0 \
            -systemIdleOnly 0
		} {
			keep -state
		}

        itk_component add swapButton {
            DCS::Button $itk_component(ring).swap \
            -text "swap" \
            -padx 0 \
            -command "$this swapStartEnd" \
            -activeClientOnly 0 \
            -systemIdleOnly 0
        } {
			keep -state
        }

        set m_origBG [$itk_component(swapButton) cget -background]

        $itk_component(deviceName) configure \
        -reference "$_lastScanDef -device" -showEntry 0

        $itk_component(totalPoints) configure \
	    -alternateShadowReference "$_newScanDef -totalPoints" \
        -reference "$_lastScanDef -totalPoints"
		
		$itk_component(startPosition) configure \
		-alternateShadowReference "$_newScanDef -startPosition" \
		-reference "$_lastScanDef -startPosition"

		$itk_component(endPosition) configure \
		-alternateShadowReference "$_newScanDef -endPosition" \
		-reference "$_lastScanDef -endPosition" 

		$itk_component(centerPosition) configure \
		-alternateShadowReference "$_newScanDef -centerPosition" \
		-reference "$_lastScanDef -centerPosition" 
		
		$itk_component(scanWidth) configure \
		-alternateShadowReference "$_newScanDef -width" \
		-reference "$_lastScanDef -width"  

		$itk_component(stepSize) configure \
		-alternateShadowReference "$_newScanDef -stepSize" \
		-reference "$_lastScanDef -stepSize" 
	 
		$_newScanDef configure -stepSizeReference "::$itk_component(stepSize) -value"
		$_newScanDef configure -totalPointsReference "::$itk_component(totalPoints) -value"
		$_newScanDef configure -startPositionReference "::$itk_component(startPosition) -value"
		$_newScanDef configure -endPositionReference "::$itk_component(endPosition) -value"
		$_newScanDef configure -centerPositionReference "::$itk_component(centerPosition) -value"
		$_newScanDef configure -widthReference "::$itk_component(scanWidth) -value"

		itk_component add title {
			label $itk_component(ring).title \
            -text "Axes" \
			-font "helvetica -16 bold"
		} {
		}

		itk_component add totalPointsLabel {
			label $itk_component(ring).tpl -text "Points"
		} {
		}

		itk_component add modeButton1 {
			button $itk_component(ring).mb1 \
            -command "$this toggleMode" \
            -text "Start" \
            -relief flat \
            -justify left
		} {
		    keep -font -bitmap
		    keep -background -foreground
		}
		
		itk_component add modeButton2 {
			button $itk_component(ring).mb2 \
            -command "$this toggleMode" \
            -text "End" \
            -relief flat \
            -justify left
		} {
			keep -font -bitmap
		    keep -background -foreground
		}
		
		itk_component add stepSizeLabel {
			label $itk_component(ring).ssl -text "Step"
		} {
		}

		eval itk_initialize $args
		
        #build the menu for selecting motors
        set motors {}
        if {$itk_option(-includeNone)} {
            lappend motors (none)
        }
        if {$itk_option(-includeTime)} {
            lappend motors time
        }

        if {$itk_option(-deviceList)==""} {
		    eval lappend motors [$m_deviceFactory getMotorList]
        } else {
	        eval lappend motors $itk_option(-deviceList)
        }
        $itk_component(deviceName) configure -menuChoices $motors

		#register for interest in the axes's deviceName
		registerForDeviceSelection $this handleDeviceChange
		$itk_component(deviceName) setValue [$_newScanDef getDeviceName] 1

		#register for interest in a global selection of units
		$itk_component(globalUnits) register $this -value handleUnitsSelection



		grid rowconfigure $itk_component(ring) 0 -weight 1
		grid rowconfigure $itk_component(ring) 1 -weight 0
		grid rowconfigure $itk_component(ring) 2 -weight 0

		grid columnconfigure $itk_component(ring) 0 -weight 1
		grid columnconfigure $itk_component(ring) 1 -weight 1
		
		pack $itk_component(ring) -fill both -expand 1


        $_newScanDef register $this -backlash handleBacklashChange
        #puts "-ScanAxesWidget::constructor" 
	}
}

body DCS::ScanAxesWidget::registerForDeviceSelection { lstnr_ callback_ } {
	$itk_component(deviceName) register $lstnr_ -value $callback_
}


body DCS::ScanAxesWidget::handleUnitsSelection  { caller_ targetReady_ - units_ initiatorId_} {
    #puts "+ScanAxesWidget::handleUnitsSelection $units_"
	if {! $targetReady_ } return
	if {$units_ == "0" } return

	changeAllEntryUnits $units_
    #puts "-ScanAxesWidget::handleUnitsSelection"
}

body DCS::ScanAxesWidget::changeAllEntryUnits { units_ } {

	$itk_component(startPosition) configure -units $units_
	$itk_component(endPosition) configure -units $units_
	$itk_component(centerPosition) configure -units $units_
	$itk_component(scanWidth) configure -units $units_
	$itk_component(stepSize) configure -units $units_
}


body DCS::ScanAxesWidget::resetAxisCenter {} {

	if { $_device == "(none)" || $_device == ""} return
	if { $_device == "time" } {
		return
	}
	
	set deviceObject [$m_deviceFactory getObjectName $_device]

	$itk_component(centerPosition) newEvent
	$itk_component(centerPosition) setValue [$deviceObject getScaledPosition]
	$itk_component(centerPosition) updateRegisteredComponentsNow -value
}

body DCS::ScanAxesWidget::swapStartEnd {} {

	if { $_device == "(none)" || $_device == ""} return
	if { $_device == "time" } {
		return
	}
	set old_value [$itk_component(stepSize) get]
    set old_value [lindex $old_value 0]
    set new_value [expr -1 * $old_value]

	
	$itk_component(stepSize) newEvent
	$itk_component(stepSize) setValue $new_value
	$itk_component(stepSize) updateRegisteredComponentsNow -value
}


body DCS::ScanAxesWidget::handleDeviceChange  { caller_ targetReady_ - device_ initiatorId_} {
    #puts "+handleDeviceChange $device_ old device: $_device"

    if {$device_ == ""} {
        set device_ "(none)"
    }

    if {$_device == $device_} {
        #puts "-handleDeviceChange no change, skip"
        return
    }

	if { ! $targetReady_} {
        #puts "-handleDeviceChange not ready skip"
        return
    }

	if {$device_ == "0" } {
        #puts "-handleDeviceChange first time  skip"
        return
    }

	set _device $device_

	if { $device_ == "(none)" } {
        #puts "in handleDeviceChange device=(none)"
		configure -state disabled
	    set deviceName $device_
	    set unitsList mm
	    set units mm

        set start 0
        set end 2
	} elseif { $device_ == "time" } {
	    configure -state normal
	    set deviceName time
	    set unitsList [list s ms min]
	    set units s

        set start 0
        set end 2
	} else {
	    configure -state normal
	    set deviceName [$m_deviceFactory getObjectName $device_]
	    set unitsList [$deviceName getRecommendedUnits]
	    set units [$deviceName cget -baseUnits]

        set cur [lindex [$deviceName getScaledPosition] 0]
        set dummy $cur
        if {![$deviceName limits_ok dummy]} {
            log_error $device_ current position $cur is out of limits
            #log_error DEBUG need move to $dummy
            ### we cannot do anything
            set start 0
            set end 2
        } else {
            set ll  [lindex [$deviceName getEffectiveLowerLimit] 0]
            set ul  [lindex [$deviceName getEffectiveUpperLimit] 0]
            if {$ll > $ul} {
                set tmp $ll
                set ll $ul
                set ul $tmp
            }
            set w 2.0
            while {($cur - $w / 2.0) < $ll || ($cur + $w / 2.0) > $ul} {
                set w [expr $w / 10.0]
                if {$w < 0.000002} {
                    ##insurance
                    break
                }
            }
            set start [expr $cur - $w / 2.0]
            set end   [expr $cur + $w / 2.0]
            #puts "for $device_ start=$start end=$end"
        }
    }

	changeScanMode

	#turn off units conversion momentarily
	$itk_component(startPosition) configure -autoConversion 0 
	$itk_component(endPosition) configure -autoConversion 0 
	$itk_component(centerPosition) configure -autoConversion 0 
	$itk_component(scanWidth) configure -autoConversion 0 
	$itk_component(stepSize) configure -autoConversion 0

	$itk_component(startPosition) configure -unitsList $unitsList  -units $units 
	$itk_component(endPosition) configure -unitsList $unitsList  -units $units 
	$itk_component(centerPosition) configure -unitsList $unitsList  -units $units 
	$itk_component(scanWidth) configure -unitsList $unitsList  -units $units 
	$itk_component(stepSize) configure -unitsList $unitsList  -units $units 

    set steps 21
    set stepSize [expr double($end - $start) / $steps]
    puts "setScanDefinion to $deviceName $steps $start $end $stepSize"
	$_newScanDef setScanDefinition $deviceName $steps $start $end $stepSize
	$_lastScanDef setScanDefinition $deviceName $steps $start $end $stepSize

	$itk_component(globalUnits) configure -menuChoices $unitsList 
	$itk_component(globalUnits) setValue $units

	#turn the units conversion back on
	$itk_component(startPosition) configure -autoConversion 1
	$itk_component(endPosition) configure -autoConversion 1
	$itk_component(centerPosition) configure -autoConversion 1 
	$itk_component(scanWidth) configure -autoConversion 1
	$itk_component(stepSize) configure -autoConversion 1
	
	$itk_component(startPosition) configure -autoGenerateUnitsList 1  
	$itk_component(endPosition) configure -autoGenerateUnitsList 1
	$itk_component(centerPosition) configure -autoGenerateUnitsList 1 
	$itk_component(scanWidth) configure -autoGenerateUnitsList 1
	$itk_component(stepSize) configure -autoGenerateUnitsList 1

	resetAxisCenter

    #puts "-handleDeviceChange"
}

configbody DCS::ScanAxesWidget::mode {
	changeScanMode
	updateRegisteredComponents -mode
}

configbody DCS::ScanAxesWidget::deviceList {
    set motors {}
    if {$itk_option(-includeNone)} {
        lappend motors (none)
    }
    if {$itk_option(-includeTime)} {
        lappend motors time
    }
    if {$itk_option(-deviceList)==""} {
	    eval lappend motors [$m_deviceFactory getMotorList]
    } else {
	    eval lappend motors $itk_option(-deviceList)
    }
    $itk_component(deviceName) configure -menuChoices $motors
}

#configbody DCS::ScanAxesWidget::showUnits {
#	if {$itk_option(-showUnits) != "" } {
#		$itk_component(totalPoints) configure -showUnits $itk_option(-showUnits) 
#		$itk_component(startPosition)  configure -showUnits $itk_option(-showUnits)
#		$itk_component(endPosition) configure -showUnits $itk_option(-showUnits)
#		$itk_component(centerPosition) configure -showUnits $itk_option(-showUnits)
#		$itk_component(scanWidth) configure -showUnits $itk_option(-showUnits)
#		$itk_component(stepSize) configure -showUnits $itk_option(-showUnits)
#	}
#}


configbody DCS::ScanAxesWidget::showPrompts {

	if { $itk_option(-showPrompts) } {
		if {$itk_option(-orientation) == "vertical" } {
			grid $itk_component(title)            -row 0 -column 0 -sticky w
			grid $itk_component(totalPointsLabel) -row 1 -column 0 -sticky e
			grid $itk_component(modeButton1) -row 2 -column 0 -sticky e
			grid $itk_component(modeButton2) -row 3 -column 0 -sticky e
			grid $itk_component(stepSizeLabel) -row 4 -column 0 -sticky e
			
			$itk_component(globalUnits) configure -fixedEntry "Units"

		} else {
			grid $itk_component(title)            -row 0 -column 0 -sticky w
			grid $itk_component(totalPointsLabel) -row 0 -column 1 -sticky e
			grid $itk_component(modeButton1) -row 0 -column 2 -sticky e
			grid $itk_component(modeButton2) -row 0 -column 3 -sticky e
			grid $itk_component(stepSizeLabel) -row 0 -column 4 -sticky e

			$itk_component(globalUnits) configure -fixedEntry ""
		}
	} else {
		grid forget $itk_component(title)
		grid forget $itk_component(totalPointsLabel)
		grid forget $itk_component(modeButton1)
		grid forget $itk_component(modeButton2)
		grid forget $itk_component(stepSizeLabel)
	}
}

configbody DCS::ScanAxesWidget::orientation {
	
	if {$itk_option(-orientation) == "vertical" } {
		configure -showUnits 0
	} else {
		configure -showUnits 0
	}

	changeScanMode
}


#configbody DCS::ScanAxesWidget::state {} {
#	if {$itk_option(-state) == "normal"} {
#		$itk_component(totalPoints) configure -state normal
#		$itk_component(startPosition) configure -state normal
#		$itk_component(endPosition) configure -state normal
#		$itk_component(centerPosition) configure -state normal
#		$itk_component(scanWidth) configure -state normal
#		$itk_component(stepSize)  configure -state normal
#		$itk_component(globalUnits) configure -state normal
#	} else {
#	$itk_component(totalPoints) configure -state disabled
#		$itk_component(startPosition) configure -state disabled
#		$itk_component(endPosition) configure -state disabled
#		$itk_component(centerPosition) configure -state disabled
#		$itk_component(scanWidth) configure -state disabled
#		$itk_component(stepSize)  configure -state disabled
#		$itk_component(globalUnits) configure -state disabled
#	}

#}

body DCS::ScanAxesWidget::shrinkWidget {} {

	grid forget $itk_component(totalPoints)
	grid forget $itk_component(startPosition)
	grid forget $itk_component(endPosition)
	grid forget $itk_component(centerPosition)
	grid forget $itk_component(scanWidth)
	grid forget $itk_component(stepSize) 
	grid forget $itk_component(globalUnits)
	grid forget $itk_component(totalPointsLabel)
	grid forget $itk_component(modeButton1)
	grid forget $itk_component(modeButton2)
	grid forget $itk_component(stepSizeLabel)
	
}

body DCS::ScanAxesWidget::repackCenterMode {} {
	grid forget $itk_component(startPosition)
	grid forget $itk_component(endPosition)
	grid forget $itk_component(swapButton)

	$itk_component(modeButton1) configure -text "Center"
	$itk_component(modeButton2) configure -text "Width"

	if {$itk_option(-orientation) == "vertical" } {
		grid $itk_component(deviceName) -row 0 -column 1 -sticky e
		grid $itk_component(totalPoints) -row 1 -column 1 -sticky news 
		grid $itk_component(centerPosition) -row 2 -column 1 -sticky news 
		grid $itk_component(scanWidth) -row 3 -column 1 -sticky news
		grid $itk_component(stepSize) -row 4 -column 1 -sticky news
	} else {
		grid $itk_component(deviceName) -row 1 -column 0 -sticky e
		grid $itk_component(totalPoints) -row 1 -column 1 -sticky news
		grid $itk_component(centerPosition) -row 1 -column 2 -sticky news
		grid $itk_component(scanWidth) -row 1 -column 3 -sticky news
		grid $itk_component(stepSize) -row 1 -column 4 -sticky news
		grid $itk_component(globalUnits) -row 1 -column 5 -sticky e
		grid $itk_component(updateButton) -row 1 -column 6 -sticky news
	}
}

body DCS::ScanAxesWidget::repackStartMode {} {
	grid forget $itk_component(centerPosition)
	grid forget $itk_component(scanWidth)

	if {$itk_option(-orientation) == "vertical" } {
		grid $itk_component(deviceName) -row 0 -column 1 -sticky e
		grid $itk_component(totalPoints) -row 1 -column 1 -sticky news
		grid $itk_component(startPosition) -row 2 -column 1  -sticky news
		grid $itk_component(endPosition) -row 3 -column 1 -sticky news 
		grid $itk_component(stepSize) -row 4 -column 1 -sticky news
		grid $itk_component(globalUnits) -row 5 -column 1 -sticky e
	} else {
		grid $itk_component(deviceName) -row 1 -column 0 -sticky e
		grid $itk_component(totalPoints) -row 1 -column 1 -sticky news
		grid $itk_component(startPosition) -row 1 -column 2  -sticky news
		grid $itk_component(endPosition) -row 1 -column 3 -sticky news
		grid $itk_component(stepSize) -row 1 -column 4 -sticky news 
		grid $itk_component(globalUnits) -row 1 -column 5 -sticky e
		grid $itk_component(updateButton) -row 1 -column 6 -sticky news
		grid $itk_component(swapButton) -row 1 -column 7 -sticky news

	}

	$itk_component(modeButton1) configure -text "Start"
	$itk_component(modeButton2) configure -text "End"
}

body DCS::ScanAxesWidget::repackFullMode {} {
	grid forget $itk_component(startPosition)
	grid forget $itk_component(endPosition)
	grid forget $itk_component(centerPosition)
	grid forget $itk_component(scanWidth)
	grid forget $itk_component(stepSize) 
	
	grid $itk_component(totalPoints) -row 1 -column 2 -sticky news
	grid $itk_component(startPosition) -row 2 -column 2  -sticky news 
	grid $itk_component(endPosition) -row 3 -column 2 -sticky news 
	grid $itk_component(centerPosition) -row 4 -column 2 -sticky news 
	grid $itk_component(scanWidth) -row 5 -column 2 -sticky news 
	grid $itk_component(stepSize) -row 6 -column 2 -sticky news 
}

body DCS::ScanAxesWidget::toggleMode {} {
    set oldMode $itk_option(-mode)

    switch -exact -- $oldMode {
        start {
            configure -mode center
        }
        center {
            configure -mode start
        }
    }
}

body DCS::ScanAxesWidget::changeScanMode {} {

	switch -exact -- $itk_option(-mode) {
		start {
			repackStartMode
		}
		
		center {
			repackCenterMode
		}
		
		full {
			repackFullMode
		}
	}
}
body DCS::ScanAxesWidget::handleBacklashChange { - targetReady_ - need_ - } {
    if {!$targetReady_} return
    if {$need_} {
        $itk_component(swapButton) configure \
        -background green
    } else {
        $itk_component(swapButton) configure \
        -background $m_origBG
    }
}

body DCS::ScanAxesWidget::setValues { motorString_ } {
    #puts "+ScanAxexWidget::setValues $motorString_"

    if {[llength $motorString_] < 5} {
        #puts "invalid values set to (none)"
        set motorString_ "(none) 21 0 2.0 0.1 mm"
    }

    foreach {name points start end step units} $motorString_ break
    set name [lindex $motorString_ 0]
    set points [lindex $motorString_ 1]
    set start [lindex $motorString_ 2]
    set end [lindex $motorString_ 3]
    set step [lindex $motorString_ 4]
    set units [lindex $motorString_ 5]

    #set device first, it will take device's current position 
    #and set to center position.
	$itk_component(deviceName) setValue $name
	$itk_component(deviceName) updateRegisteredComponentsNow -value

	$itk_component(globalUnits) setValue $units
	$itk_component(globalUnits) updateRegisteredComponentsNow -value

    $itk_component(totalPoints) setValue $points
	$itk_component(totalPoints) updateRegisteredComponentsNow -value

    $itk_component(startPosition) setValue $start
	$itk_component(startPosition) updateRegisteredComponentsNow -value

    $itk_component(endPosition) setValue $end
	$itk_component(endPosition) updateRegisteredComponentsNow -value

    #puts "-ScanAxexWidget::setValues"
}



						
proc testScanDefinitionWidget {} {

	DCS::ScanDefinitionWidget .x ::device::table_vert
	pack .x -expand yes -fill both

	# create the apply button
	::DCS::ActiveButton .activeButton
	
	pack .activeButton
	
	dcss connect
	
	return
}

#testScanDefinitionWidget
