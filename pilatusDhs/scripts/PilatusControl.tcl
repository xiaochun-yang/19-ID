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



set pilatusMessage -

#yangx add
#set i 0

#puts with special frame header
proc putsImg {level imageParams_ msg_} {
    puts "DHS: $level \[[$imageParams_ cget -filename]\] $msg_"  
}



class Pilatus::DetectorStatus {

    private variable _lastSentStatus ""

    public variable collecting false
    public variable threshold 6329
    public variable gain lowg
    public variable thresholdSet false
    public variable settingThreshold false
    public variable setThresholdOpHandle ""
    public variable temp0 -99.0
    public variable temp1 -99.0
    public variable temp2 -99.0
    public variable humid0 -99.0
    public variable humid1 -99.0
    public variable humid2 -99.0
    public variable gapFill -1
    public variable imgMode null
    public variable exposureTime 0
    public variable exposureMode null
    public variable flatField null
    public variable badPixelMap null
    public variable diskSizeKb 0
    public variable diskUsedKb 0
    public variable diskUsePercent 0
    public variable freeImageSpace 0
    public variable sumImages false
    public variable nFrameImg 1
    public variable sumImagesDeltaDeg 0.1

    private variable _maxImageSizeKb 0
    private variable _HF4M_ready 0
    
    constructor { root maxImageSizeKb} {
        set _maxImageSizeKb $maxImageSizeKb

        if {$root} {
            set _lastSentStatus [namespace current]::[Pilatus::DetectorStatus #auto false $_maxImageSizeKb]
        }
        
    }

    destructor {
        if {$_lastSentStatus != "" } {
            delete object $_lastSentStatus
        }
    }


    #copy method
    public method copy { object_ } {
        foreach dataMember { collecting temp0 temp1 temp2 humid0 humid1 humid2 gapFill imgMode exposureTime exposureMode flatField badPixelMap diskSizeKb diskUsedKb diskUsePercent freeImageSpace sumImages sumImagesDeltaDeg nFrameImg threshold gain thresholdSet settingThreshold setThresholdOpHandle} {
            configure -$dataMember [$object_ cget -$dataMember]
        }
    }

    public method updateDetectorStatusString { dcss_ } {

        if { ![equals $_lastSentStatus] } {
            $dcss_ sendMessage "htos_set_string_completed detectorStatus normal TEMP0 $temp0 TEMP1 $temp1 TEMP2 $temp2 HUMID0 $humid0 HUMID1 $humid1 HUMID2 $humid2 GAPFILL $gapFill EXPOSUREMODE $exposureMode DISK_SIZE_KB $diskSizeKb DISK_USED_KB $diskUsedKb DISK_USE_PERCENT $diskUsePercent FREE_IMAGE_SPACE $freeImageSpace SUM_IMAGES $sumImages SUM_IMAGES_DELTA_DEG $sumImagesDeltaDeg N_FRAME_IMG $nFrameImg THRESHOLD $threshold GAIN $gain THRESHOLD_SET $thresholdSet SETTING_THRESHOLD $settingThreshold"
            $_lastSentStatus copy $this
        }


    }

    public method equals { object_ } {
        foreach dataMember { collecting temp0 temp1 temp2 humid0 humid1 humid2 gapFill imgMode exposureTime exposureMode flatField badPixelMap diskSizeKb diskUsedKb diskUsePercent nFrameImg threshold gain thresholdSet settingThreshold setThresholdOpHandle } {
            if { [$object_ cget -$dataMember] != [set $dataMember] } {
                return false
            }
        }
        return true
    }

    public method checkDiskSpace { dir } {
        set out [exec df]
        set out [string range $out [string first "\n" $out] end]
    
        foreach {fileSystem kiloBlock used available usePercent mount} $out {
            set diskUsePercent [string trim $usePercent %]
            if {$diskUsePercent > 99} {
                set diskUsePercent 99
            }

            if {$mount != [string trimright $dir /]} continue
            #set usePercent [string trim $usePercent %]
            set diskSizeKb $kiloBlock
            set diskUsedKb $used
            set freeImageSpace [expr $available / $_maxImageSizeKb]
            if {$freeImageSpace <1 } {
                #assume at least one image will be copied off in time
                set freeImageSpace 1
            }
            
        }
    }
}

class Pilatus::BackgroundMonitor {

    public variable pilatus
    public variable monitorTempPeriodSec 60
    public variable monitorDiskPeriodSec 5
    public variable dcss

    constructor { } {
    }

    public method monitor {} {
        monitorTemp
        monitorDisk
    }
    public method monitorTemp {} {
        catch {
            $pilatus queryTemp
        }
        after [expr $monitorTempPeriodSec * 1000] [list $this monitorTemp]
    }

    public method monitorDisk {} {
        catch {
            $pilatus checkDiskUse 
        }
        after [expr $monitorDiskPeriodSec * 1000] [list $this monitorDisk]
    }

    public method afterPropertiesSet {} {
        monitor
    }
}

class Pilatus::DetectorControl {

    public variable collecting false
    public variable host ""
    public variable port 14242
    public variable flatFieldFile ""
    public variable badPixelMapFile ""
    public variable gapFillValue -1 
    public variable pixelXSizeUm 172
    public variable pixelYSizeUm 172
    public variable imageXSizePixels 
    public variable imageYSizePixels 
    public variable sumImagesDeltaDeg 0.1
    public variable tmpDir ""
    public variable detectorType PILATUS6
    public variable dcss
    public variable fileMover

    private variable _socket ""
    private variable _connected false
    private variable _detectorXCenterPixel
    private variable _detectorYCenterPixel

    private variable _buildingMsg ""
    private variable _abortOps 
    private variable _detectorStatus 

    private variable _detectorPixelSizeFactorX 
    private variable _detectorPixelSizeFactorY
    private variable _maxImageSizeKb 6500


    private variable _multiImageParams


    public variable testMode false


    constructor {} {
        puts "no params"
    }


    public method afterPropertiesSet {  } {

        set _buildingMsg ""
        set _abortOps ""
        set _detectorStatus [namespace current]::[Pilatus::DetectorStatus #auto true $_maxImageSizeKb]
        
        #calculate center of center pixel
        if {$imageXSizePixels ==""} {return -code error "Error: must configure imageXSizePixels"}
        if {$imageYSizePixels ==""} {return -code error "Error: must configure imageYSizePixels"}
        set _detectorXCenterPixel [expr $imageXSizePixels / 2 + 0.5]
        set _detectorYCenterPixel [expr $imageYSizePixels / 2 + 0.5]

        if {$pixelXSizeUm ==""} {return -code error "Error: must configure pixelXSizeUm"}
        if {$pixelYSizeUm ==""} {return -code error "Error: must configure pixelYSizeUm"}
        if {$tmpDir ==""} {return -code error "Error: must configure tmpDir"}

        $_detectorStatus checkDiskSpace $tmpDir
puts "yangx tmpDir=$tmpDir"
        #convert mm to pixel with pixelSize 172 um/pixel
        set _detectorPixelSizeFactorX [expr 1000.0 / $pixelXSizeUm ]
        set _detectorPixelSizeFactorY [expr 1000.0 / $pixelYSizeUm ]

        if {$host == ""} {return -code error "Error: Must configure host property"}
#puts "host=$host"
        set _multiImageParams [namespace current]::[MultiImageParams #auto]  


        #$_detectorStatus updateDetectorStatusString

        connectToDetector
    }

    public method connectToDetector {} {
        if {[catch {
            set _socket [socket $host $port]
	    puts "yangx1: $_socket host=$host port=$port"
            #fconfigure $_socket -blocking 0
            fconfigure $_socket -blocking 0 -translation binary
            fileevent $_socket readable [::itcl::code $this safeHandleDetectorResponse]

            loadFlatFieldCorrection
            loadBadPixelMap
            setGapFill
            setImgMode
            queryTemp
        } errorMsg ]} {
            set _connected false
#	    puts "yangx2:2: $_socket host=$host port=$port"
            puts "ERROR: cannot connect to Pilatus detector $errorMsg"

            $dcss breakConnection
            after 1000 [list $this connectToDetector]
            return
        }
	puts "connect to pilatus detect"
        set connected true
    }




    #private method connectError {} {
    #    puts "Error connecting to Pilatus detector"
    #    after 1000
    #    set socket_ [socket -error [list $this $connectError] $host $port  ]
    #}


    private method putsDet {msg_} {
        puts "pilatus<DHS: $msg_"
        #if { [string length $msg_] > 5} {
        #    puts -nonewline  $_socket [string range ${msg_} 0 4]
        #    flush $_socket
        #    puts -nonewline  $_socket [string range ${msg_} 5 end]
        #    puts -nonewline  $_socket [format %c 0]
        #    flush $_socket
        #} else {

#puts "yangx before $msg_ socket=$_socket"
# somehow with -nonewline the test MOCK PILATUS server dosen't work.
# so I used the following command. it works

             puts $_socket "${msg_}"
#the line below produce a exptime value which can be used with expr
#in the pilatusServer.tcl 

#	     puts $_socket "${msg_}[format %c 0]" 
#            puts -nonewline $_socket "${msg_}[format %c 0]"
            flush $_socket
        #}

        puts "pilatus<DHS: flush" 
    }

    private method loadFlatFieldCorrection {} {
        if {$flatFieldFile != "" } {
            putsDet "LdFlatField $flatFieldFile"
        } else {
            puts "WARNING: no flat field correction file loaded"
        }
    }

    private method loadBadPixelMap {} {
        puts "Load bad pixel map"
        if {$badPixelMapFile != "" } {
            putsDet "LdBadPixMap $badPixelMapFile"
        } else {
            puts "WARNING: no bad pixel map file loaded"
        }
    }

    private method setImgMode {} {
        putsDet "imgmode xray"
    }

    private method setGapFill {} {
        putsDet "GapFill $gapFillValue"
    }

    private method configureHeader { imageParams_ } {
#yangx original putsDet "MXSettings Wavelength [$imageParams_ cget -wavelength]"
#yangx get rid of MXSettings for all 6 following putsDet

#	puts "yangx reuseDark = [$imageParams_ cget -reuseDark]"
	
        putsDet "Wavelength [$imageParams_ cget -wavelength]"
        putsDet "Detector_distance [expr [$imageParams_ cget -distance] * 0.001 ]"
        putsDet "Start_angle [$imageParams_ cget -oscillationStart]"
        if { [$imageParams_ cget -axisName] == "gonio_phi" } {
            putsDet "Phi [$imageParams_ cget -oscillationStart]"
        }
        putsDet "Angle_increment [$imageParams_ cget -oscillationRange]"
	#yangx hf262 detector's y absolute position 315 mm is based on zero position
        #of the Q4. The real y position of hf262 at here should be 0.65. So substracting
        #314.35 from 315 is 0.65 

        set detectorOffsetPixelsX [expr [$imageParams_ cget -detectorX] * $_detectorPixelSizeFactorX]
        set detectorOffsetPixelsY [expr ([$imageParams_ cget -detectorY] - 314.35) * $_detectorPixelSizeFactorY]
	putsDet "Beam_x [expr $_detectorXCenterPixel + $detectorOffsetPixelsX]"
        putsDet "Beam_y [expr $_detectorYCenterPixel - $detectorOffsetPixelsY]"
    }

    private method assertNotBusy {} {
        if { [cget -collecting] == true} {
            puts "two starts in a row"
            return -code error "Two starts in a row"
        }
        if { [$_detectorStatus cget -settingThreshold] == true} {
            puts "busy setting threshold"
            return -code error "Busy setting threshold"
        }
    }

    public method start { imageParams_ } {
        puts "start" 
        assertNotBusy
        $_multiImageParams copy $imageParams_
        $_multiImageParams configure -numImages 1
        $_multiImageParams sliceImages $sumImagesDeltaDeg
        externalTrigger
        putsImg INFO $_multiImageParams "done handling start"
    }

    public method stop {} {

	    return

        configure -collecting false
        #puts "stopping the detector for [$_imageParams_ cget -filename]"
    }

    public method abort { handle_ } {
        #putsDet "K"
        if {[cget -collecting] == false} {
	        $dcss sendMessage "htos_operation_completed detector_stop $handle_ normal"
        }

        lappend _abortOps $handle_ 
    }

    public method async_abort { } {
        putsDet "K"
    }


    public method collectShutterless {imageParams_ } {
        assertNotBusy
        $_multiImageParams copy $imageParams_
        $_multiImageParams sliceImages $sumImagesDeltaDeg
        externalTrigger
    }

    private method externalTrigger { } {
        configureHeader $_multiImageParams

        #set the exposure time
        set nFrameImg [$_multiImageParams cget -nFrameImg ] 
        if { $nFrameImg == 1 && [$_multiImageParams cget -numImages] == 1 } {
            putsDet "exptime [$_multiImageParams cget -exposureTime]"    
            #TODO parameterize readout time
            putsDet "expp [expr [$_multiImageParams cget -exposureTime] + 0.0023]"    
            putsDet "SetAckInt 1"
        } else {
            set sliceExposureTime [expr [$_multiImageParams cget -exposureTime] / double($nFrameImg) ]
            putsDet "exptime [expr $sliceExposureTime - 0.0023]"    
            putsDet "expp $sliceExposureTime"    
            putsDet "SetAckInt 1"
        }
        putsImg INFO $_multiImageParams "Starting detector integrating"
        set numImages [expr [$_multiImageParams cget -numImages] * $nFrameImg]
        putsDet "nimages [$_multiImageParams cget -numImages]"
        putsDet "nframeimg $nFrameImg"
        putsDet "detectorMode [$_multiImageParams cget -detectorMode]"

#puts "yangx nimages = [$_multiImageParams cget -numImages]  nframeimg=$nFrameImg"

        set userName [$_multiImageParams cget -userName]
        set destinationRootName [$_multiImageParams cget -filename]
        set destinationDir [$_multiImageParams cget -directory]
#yangx add filename
#the file name here is prefix + _#. The _# is a run#

	set fileName [$_multiImageParams cget -filename]
	putsDet "filename $fileName"
	putsDet "directory $destinationDir"
puts "filename=$fileName"
puts "directory=$destinationDir"
        set startIndex [$_multiImageParams cget -startIndex]
        putsDet "startIndex $startIndex"

        #setup up local directory to put the data set
        set localDir "${tmpDir}/$userName/"
        file mkdir $localDir
puts "localdir=$localDir"
        #setup unique file names for local files
        set uid [clock seconds]
        $_multiImageParams configure -localUniqueRunId $uid
        $_multiImageParams configure -localDir $localDir

        putsDet "exttrigger $localDir${uid}_.cbf"
	set _HF4M_ready 0
#        puts "yangx _HF4M_ready = $_HF4M_ready"
#	vwait _HF4M_ready
#	puts "yangxx _HF4M_ready = $_HF4M_ready"
#	puts "yangx: EXECUTE configure command"
#	configure -collecting true

    }

    public method safeHandleDetectorResponse {} {
        if { [catch {handleDetectorResponse} err ] } {
            putsImg SEVERE $_multiImageParams $err
            exit
        }
    }

    private method handleDetectorResponse {} {
        #if {[gets $_socket response] < 0 } return
        set response ""
        set endOfLine false
        while { ! $endOfLine } {
            set a [read $_socket 1]
    
            if {$a == ""} {
                #no more data
                set _buildingMsg ${_buildingMsg}${response}
                return
            }

            scan $a %c ascii 
            if { $ascii == "24" } {
                set endOfLine true
            } else {
                append response $a
            }
        }

        set response ${_buildingMsg}${response} 
        if {$response == ""} return
        set _buildingMsg ""

        puts "DHS<Pilatus: $response"

        #get the current image parameters
	    set opHandle [$_multiImageParams cget -operationHandle]

        set filename [$_multiImageParams cget -filename]

        scan $response "%d %s" returnCode returnStatus

        set returnHeaderLen [string length "$returnCode $returnStatus"]
        set returnMsg [string range $response [expr $returnHeaderLen +1] end]

        set exposureMode [$_detectorStatus cget -exposureMode]
        if { $returnStatus == "ERR" } {
            switch $returnCode {
                1 {
                }

                7 {
                }
        
                13 {
                    puts "return code 13"
                    set imageNum [$_multiImageParams cget -numCollected]

                    set localFileName [$_multiImageParams lookupLocalFileName $imageNum]
                    set remoteFileName [$_multiImageParams lookupRemoteFileName $imageNum]
            
                    set userName [$_multiImageParams cget -userName]
                    set sessionId [stripPrivateKeyword [$_multiImageParams cget -sessionID]] 

                    $fileMover moveFile $localFileName $remoteFileName $userName $sessionId false
                    puts "handled return code 13"
                }
                15 {
                    if { [$_detectorStatus cget -settingThreshold] } {
                        $_detectorStatus configure -settingThreshold false
                        #$_detectorStatus configure -thresholdSet true
                        $dcss sendMessage "htos_operation_completed detectorSetThreshold [$_detectorStatus cget -setThresholdOpHandle] abort $returnMsg"
                        $_detectorStatus configure -setThresholdOpHandle ""
                    }
                }
            }

            configure -collecting false
            if { [$_multiImageParams cget -operationActive] } {
                if { $exposureMode == "SHUTTER" } {
                    $dcss sendMessage "htos_operation_completed detector_collect_image $opHandle abort $returnMsg"
                } else {
                    $dcss sendMessage "htos_operation_completed detectorCollectShutterless $opHandle abort $returnMsg"
                }
                $_multiImageParams configure -operationActive false
            }
        }

        if { $returnStatus == "OK" } {
            switch $returnCode {
                7 {
                    #look for image written message
                    set localFileName $returnMsg
        	    configure -collecting false

		puts "operationType = [$_multiImageParams cget -operationType]"

                    if { [$_multiImageParams cget -operationType] == "detector_collect_image" } {
                        $dcss sendMessage "htos_operation_completed detector_collect_image [$_multiImageParams cget -operationHandle] normal"

                        set remoteFileName [$_multiImageParams cget -directory]/[$_multiImageParams cget -filename].cbf
                        set userName [$_multiImageParams cget -userName]
                        set sessionId [stripPrivateKeyword [$_multiImageParams cget -sessionID]] 
                        $fileMover moveFile $localFileName $remoteFileName $userName $sessionId true
			puts "yangx true"
                    } else {
                        set remoteFileName [$_multiImageParams lookupLastRemoteFileName]

                        set userName [$_multiImageParams cget -userName]
                        set sessionId [stripPrivateKeyword [$_multiImageParams cget -sessionID]] 

                        $dcss sendMessage "htos_operation_completed detectorCollectShutterless [$_multiImageParams cget -operationHandle] normal"
                        $fileMover moveFile $localFileName $remoteFileName $userName $sessionId false 
                      #  $fileMover moveFile "/storage/test/hf262/devel/inverse/t-7_1_005.img" "/storage/test/hf262/devel/inverse/t-7_1_005.img" $userName $sessionId false 
			puts "yangx false"
                    }
		    puts "yangx localFileName=$localFileName remoteFileName=$remoteFileName userName=$userName sessionId=$sessionId\n"
		#yangx add to make sure that "Detector Ready" will be displayed on the
                #system status bar. 1.5 is the handle value. I am using a fixed value
                # here. see bluice notes for the status problem. 

		$dcss sendMessage "htos_operation_completed detector_stop 1.5 normal"

                }
                15 {
                    handleReturnCode15 $returnMsg
                }
                215 {
                    handleReturnCode15 $returnMsg
                }
                300 {
                    handleReturnCode300 $returnMsg
                }
            }


        }
        

        set ::pilatusMessage -

        $_detectorStatus updateDetectorStatusString $dcss

    }

    private method handleReturnCode300 {  msg_ } {
	puts "ReturnCode300> ${msg_}"
#	after 2000
	puts "yangx configure -collecting true"
	configure -collecting true
	set _HF4M_ready 1
    }

    private method handleReturnCode15 {  msg_ } {
        set exposureMode [$_detectorStatus cget -exposureMode]
	    set opHandle [$_multiImageParams cget -operationHandle]

        if { [$_detectorStatus cget -settingThreshold] } {
            if { $msg_ == "" || $msg_ == "/tmp/setthreshold.cmd" } {
                $_detectorStatus configure -settingThreshold false
                $_detectorStatus configure -thresholdSet true
                $dcss sendMessage "htos_operation_completed detectorSetThreshold [$_detectorStatus cget -setThresholdOpHandle] normal"
                $_detectorStatus configure -setThresholdOpHandle ""
                return
            }
        }
        if { [scan $msg_ "N images set to: %d" nImages] == 1 } {
            if {$nImages == 1 } {
                $_detectorStatus configure -exposureMode "SHUTTER"
            } else {
                $_detectorStatus configure -exposureMode "SHUTTERLESS"
            }
            return
        }
        if { [scan $msg_ "Frames per image set to: %d" nFrame] == 1 } {
            $_detectorStatus configure -nFrameImg "$nFrame"
            return
        }
        if { [scan $msg_ "Channel 0: Temperature = %fC, Rel. Humidity = %f%%;\nChannel 1: Temperature = %fC, Rel. Humidity = %f%%;\nChannel 2: Temperature = %fC, Rel. Humidity = %f%%\n" temp0 humid0 temp1 humid1 temp2 humid2] == 6 } {
            $_detectorStatus configure -temp0 $temp0
            $_detectorStatus configure -temp1 $temp1
            $_detectorStatus configure -temp2 $temp2
            $_detectorStatus configure -humid0 $humid0
            $_detectorStatus configure -humid1 $humid1
            $_detectorStatus configure -humid2 $humid2
            #after 60000 "$this queryTemp"
            return
        }

        if { [scan $msg_ "img %d" imageNum] == 1 && [$_multiImageParams cget -operationType]=="detectorCollectShutterless" } {
	    set localFileName [$_multiImageParams lookupLocalFileName $imageNum]
            set remoteFileName [$_multiImageParams lookupRemoteFileName $imageNum]
            
            set userName [$_multiImageParams cget -userName]
            set sessionId [stripPrivateKeyword [$_multiImageParams cget -sessionID]] 

            $_multiImageParams configure -numCollected [expr $imageNum +1]
            $fileMover moveFile $localFileName $remoteFileName $userName $sessionId false

            $dcss sendMessage "htos_operation_update [$_multiImageParams cget -operationType] $opHandle exposed $imageNum"
            return
        }

        set expTime [$_multiImageParams cget -exposureTime]


	if { [scan $msg_ "Exposure time set to: %f sec." detExpTime] == 1} {
		    if { [expr ($detExpTime - $expTime) > 0.01] } {
		        putsImg SEVERE $_multiImageParams "pilatus detector exposure time (${detExpTime}) does not agree with requested exposure time (${expTime})"
		    }	
            return
	    }
        #if we are here, we should be handling commands related to exposing the sample...
        if { [scan $msg_ "  Starting %f second background:" detExpTime] == 1 } {
            #exposure gives a different response than exttrig
            puts "INFO: collecting non-triggered images"
            if { !$testMode} {
                puts "WARNING: collecting non-triggered images, but not in test mode"
            }
        } elseif { [string first "Starting externally triggered exposure(s):" $msg_ ] == 0} {
            set detExpTime $expTime
	} else {
            return
        }
	if { [expr ($detExpTime - $expTime) > 0.01] } {
		    putsImg SEVERE $_multiImageParams "pilatus detector exposure time (${detExpTime}) does not agree with requested exposure time (${expTime})"
	}	
        set filename [$_multiImageParams cget -filename]
        set op [$_multiImageParams cget -operationType]
        $dcss sendMessage "htos_operation_update $op $opHandle start_oscillation shutter $expTime $filename"
#$dcss sendMessage "htos_operation_update $op $opHandle start_oscillation shutter $expTime $filename"
        #    dcss sendMessage "htos_operation_update detectorCollectShutterless $opHandle start_oscillation"
    }
   
    public method queryTemp {} {
#global i
#set i [expr $i + 1]
        assertNotBusy
        putsDet "th"
    }

    public method changeThreshold { handle gain threshold } {

        assertNotBusy

        putsDet "setthreshold $gain $threshold"

        $_detectorStatus configure -threshold $threshold
        $_detectorStatus configure -gain $gain
        $_detectorStatus configure -thresholdSet false
        $_detectorStatus configure -settingThreshold true
        $_detectorStatus configure -setThresholdOpHandle $handle
        $_detectorStatus updateDetectorStatusString $dcss
    }


    public method checkDiskUse {} {
        $_detectorStatus checkDiskSpace $tmpDir
        $_detectorStatus updateDetectorStatusString $dcss
    }

    #puts with special frame header
    public method putsImg {level imageParams_ msg_} {
        puts "DHS: $level \[[$imageParams_ cget -filename]\] $msg_"  
    }


}

configbody Pilatus::DetectorControl::collecting {
        puts "configuring collecting $collecting"
        if { $collecting == false} {
            foreach handle $_abortOps {
	            $dcss sendMessage "htos_operation_completed detector_stop $handle normal"
            }
        }

        lset _abortOps "" 

        #putsDet "K"
    }


