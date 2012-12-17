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

class MoveFileCommand {
    
    private variable _localFileName
    private variable _remoteFileName
    private variable _userName
    private variable _sessionId
    public variable timestamp

    constructor {localFileName_ remoteFileName_ userName_ sessionId_} {
        set _localFileName $localFileName_
        set _remoteFileName $remoteFileName_
        set _userName $userName_
        set _sessionId $sessionId_
        set timestamp [clock seconds]
    }

    public method exists {} {
        return [file exists $_localFileName]
    }

    public method updateLastImageCollected {} {
        after 1000 [list dcss sendMessage "htos_set_string_completed lastImageCollected normal $_remoteFileName"]
    }

    public method move {} {
        writeImageToUserDirWithLoggedElapsedTime $_localFileName $_remoteFileName $_userName $_sessionId
    }

    public method getRemoteFileName {} {
        return $_remoteFileName
    }



    public method changeFileNameToOverwritten {} {
        set dir [file dir $_remoteFileName]
        set tail [file tail $_remoteFileName]
        set _remoteFileName "${dir}/OVERWRITTEN_FILES/${tail}"
    }

    destructor {
        file delete $_localFileName
    }

}


set gLatestImageUpdateTimestamp 0

class MoveFileCommandQueue {
    private variable fileQueue
    private variable _remoteFileNameHash

    constructor {} {
        set fileQueue ""
        array set _remoteFileNameHash {}
    }


    public method getObjFromRemoteFile {remoteFile} {
        return [lindex [array get _remoteFileNameHash $remoteFile] 1]
    }

    public method addToQueue { fileObj now} {
        puts "$this addToQueue [$fileObj getRemoteFileName]"

        if {$now} {
            set fileQueue [linsert $fileQueue 0 $fileObj] 
        } else {
            lappend fileQueue $fileObj
        } 
        set remoteFile [$fileObj getRemoteFileName]
        set _remoteFileNameHash($remoteFile) $fileObj
    }

    public method removeFromQueue { fileObj } {
        puts "$this removeFromQueue [$fileObj getRemoteFileName] $fileObj"
        set remoteFile [$fileObj getRemoteFileName]
        set index -1
        foreach obj $fileQueue {
            incr index
            #puts "[$obj getRemoteFileName] == $remoteFile ?"
            if { [$obj getRemoteFileName] != $remoteFile} continue
            removeFromQueueAndHash $remoteFile $index
            return 
        }
        puts "removeFromQueue could not find a match"
        exit
    }
    private method removeFromQueueAndHash { remoteFile index } {
        puts "remove $remoteFile $index"
        array unset _remoteFileNameHash $remoteFile

        #puts "$this [ array names _remoteFileNameHash]"

        set fileQueue [lreplace $fileQueue $index $index]
    }


    public method moveOldestExisting {} {
        set index -1
        foreach fileObj $fileQueue {
            incr index
            if { ! [$fileObj exists] } continue
            set remoteFile [$fileObj getRemoteFileName]

            #the imp writefile command can return control to the tcl interpreter, so it is important to
            #remove the object from the queue before starting the move, otherwise other events
            #may attempt to remove the object before the copy is finished.
            removeFromQueueAndHash $remoteFile $index
            puts "MOVE $remoteFile"
            $fileObj move
            puts "MOVED $remoteFile"
            showLatestExisting $fileObj
            delete object $fileObj
            return true 
        }
        return false
    }


    private method showLatestExisting { fileObj } {
        global gLatestImageUpdateTimestamp

        set timestamp [$fileObj cget -timestamp]

        #puts "[clock seconds] < [expr $gLatestImageUpdateTimestamp + 5]"
        if { [clock seconds] < [expr $gLatestImageUpdateTimestamp + 5] } return

        if {$timestamp > $gLatestImageUpdateTimestamp } {
            set gLatestImageUpdateTimestamp  $timestamp
            $fileObj updateLastImageCollected
        }
    }

}

class FileMover {

    private variable _currentFiles
    private variable _overwrittenFiles

    private variable _countDownToUpdateMs 0
    private variable _latestTimestamp


    constructor {} {
        after 1000 [list $this backgroundMover]
        set _latestTimestamp 0
        set _overwrittenFileNameHash ""
        set _currentFiles [namespace current]::[MoveFileCommandQueue #auto]
        set _overwrittenFiles [namespace current]::[MoveFileCommandQueue #auto]
    }

    public method moveFile {localFile remoteFile userName sessionId now} {

        set duplicate [$_currentFiles getObjFromRemoteFile $remoteFile]
        if { $duplicate != ""} {
            $_currentFiles removeFromQueue $duplicate

            $duplicate changeFileNameToOverwritten 
            set duplicateOverwritten [$_overwrittenFiles getObjFromRemoteFile [$duplicate getRemoteFileName] ]
            puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXx  [$duplicate  getRemoteFileName]"
            if {$duplicateOverwritten != ""} {
                puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX $duplicateOverwritten"
                #this is too much -- we have overwritten the overwritten -- just delete the file...
                $_overwrittenFiles removeFromQueue $duplicateOverwritten
                delete object $duplicateOverwritten
            }
            $_overwrittenFiles addToQueue $duplicate $now
        }
        
        set fileObj [namespace current]::[MoveFileCommand #auto $localFile $remoteFile $userName $sessionId]
        $_currentFiles addToQueue $fileObj $now 
    }

    public method backgroundMover {} {
        if { [ catch {
            incr _countDownToUpdateMs -20
            #if {$_countDownToUpdateMs < 0} {
            #    $_currentFiles moveLatestExisting
            #} else {
            #}
            
            if { ! [$_currentFiles moveOldestExisting ] } {
                $_overwrittenFiles moveOldestExisting
            }
        } err ] } {
            puts $err
            #exit
        }
        after 20 [list $this backgroundMover]
    }





}

class PilatusStatus {
    private variable _lastSentStatus ""

    public variable collecting false
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
    
    constructor { root maxImageSizeKb} {
        set _maxImageSizeKb $maxImageSizeKb

        if {$root} {
            set _lastSentStatus [namespace current]::[PilatusStatus #auto false $_maxImageSizeKb]
        }
        
    }

    destructor {
        if {$_lastSentStatus != "" } {
            delete object $_lastSentStatus
        }
    }


    #copy method
    public method copy { object_ } {
        foreach dataMember { collecting temp0 temp1 temp2 humid0 humid1 humid2 gapFill imgMode exposureTime exposureMode flatField badPixelMap diskSizeKb diskUsedKb diskUsePercent freeImageSpace sumImages sumImagesDeltaDeg nFrameImg } {
            configure -$dataMember [$object_ cget -$dataMember]
        }
    }

    public method updateDetectorStatusString {} {

        if { ![equals $_lastSentStatus] } {
            dcss sendMessage "htos_set_string_completed detectorStatus normal TEMP0 $temp0 TEMP1 $temp1 TEMP2 $temp2 HUMID0 $humid0 HUMID1 $humid1 HUMID2 $humid2 GAPFILL $gapFill EXPOSUREMODE $exposureMode DISK_SIZE_KB $diskSizeKb DISK_USED_KB $diskUsedKb DISK_USE_PERCENT $diskUsePercent FREE_IMAGE_SPACE $freeImageSpace SUM_IMAGES $sumImages SUM_IMAGES_DELTA_DEG $sumImagesDeltaDeg N_FRAME_IMG $nFrameImg"
            $_lastSentStatus copy $this
        }


    }

    public method equals { object_ } {
        foreach dataMember { collecting temp0 temp1 temp2 humid0 humid1 humid2 gapFill imgMode exposureTime exposureMode flatField badPixelMap diskSizeKb diskUsedKb diskUsePercent nFrameImg } {
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

class BackgroundPilatusMonitor {

    private variable _pilatus

    constructor { pilatus } {
    
        set _pilatus $pilatus
    }

    public method monitor {} {
        monitorTemp
        monitorDisk
    }
    public method monitorTemp {} {
        catch {
            $_pilatus queryTemp
        }
        after 600000 [list $this monitorTemp]
    }

    public method monitorDisk {} {
        catch {
            $_pilatus checkDiskUse 
        }
        after 5000 [list $this monitorDisk]
    }
}

class Pilatus {

    public variable collecting false
    private variable _host ""
    private variable _port ""
    private variable _socket ""
    private variable _connected false
    private variable _detectorXCenterPixel
    private variable _detectorYCenterPixel
    private variable _flatFieldFile ""
    private variable _badPixelMapFile ""
    private variable _badPixelMap ""
    private variable _gapFillValue ""
    private variable _imageSizeX
    private variable _imageSizeY
    private variable _pixelXSizeUm
    private variable _pixelYSizeUm
    private variable _sumImages false
    private variable _sumImagesDeltaDeg 0.1

    private variable _buildingMsg ""
    private variable _abortOps 
    private variable _detectorStatus 

    #convert mm to pixel with pixelSize 172 um/pixel
    private variable _detectorPixelSizeFactorX [expr 1000.0 / 172.0 ]
    private variable _detectorPixelSizeFactorY [expr 1000.0 / 172.0 ]
    private variable _maxImageSizeKb 8000

    private variable _tmpDir ""

    private variable _multiImageParams
    private variable _fileMover

    public variable _lastMessageFromDetectorFifo
    private variable _backgroundMonitor

    public variable testMode false

    constructor { config_ } {

        set _host [$config_ getStr pilatus.host]
        set _port [$config_ getStr pilatus.port]
        set _flatFieldFile [$config_ getStr pilatus.flatFieldFile]
        set _badPixelMapFile [$config_ getStr pilatus.badPixelMapFile]
        set _imageXSizePixels [$config_ getStr pilatus.imageXSizePixels]
        set _imageYSizePixels [$config_ getStr pilatus.imageYSizePixels]
        set _pixelXSizeUm [$config_ getStr pilatus.pixelXSizeUm]
        set _pixelYSizeUm [$config_ getStr pilatus.pixelYSizeUm]
        set _gapFillValue [$config_ getStr pilatus.gapFillValue]
        set _tmpDir [$config_ getStr pilatus.tmpDir]

        set _buildingMsg ""
        set _abortOps ""
        set _detectorStatus [namespace current]::[PilatusStatus #auto true $_maxImageSizeKb]
        set _backgroundMonitor [namespace current]::[BackgroundPilatusMonitor #auto $this]
        
        #calculate center of center pixel
        if {$_imageXSizePixels ==""} {return -code error "Error: must set pilatus.imageXSizePixels"}
        if {$_imageYSizePixels ==""} {return -code error "Error: must set pilatus.imageYSizePixels"}
        set _detectorXCenterPixel [expr $_imageXSizePixels / 2 + 0.5]
        set _detectorYCenterPixel [expr $_imageYSizePixels / 2 + 0.5]

        if {$_pixelXSizeUm ==""} {return -code error "Error: must set pilatus.pixelXSizeUm"}
        if {$_pixelYSizeUm ==""} {return -code error "Error: must set pilatus.pixelYSizeUm"}
        if {$_tmpDir ==""} {return -code error "Error: must set pilatus.tmpDir"}

        $_detectorStatus checkDiskSpace $_tmpDir

        #convert mm to pixel with pixelSize 172 um/pixel
        set _detectorPixelSizeFactorX [expr 1000.0 / $_pixelXSizeUm ]
        set _detectorPixelSizeFactorY [expr 1000.0 / $_pixelYSizeUm ]


        if {$_host == ""} {return -code error "Error: Must set pilatus.host in config file"}
        if {$_port == "" } {set _port 41234}
        if {$_gapFillValue == "" } {set _gapFillValue -1}

        set _multiImageParams [namespace current]::[MultiImageParams #auto]  
        set _fileMover [namespace current]::[FileMover #auto]

        qinit _lastMessageFromDetectorFifo

        #$_detectorStatus updateDetectorStatusString
        $_backgroundMonitor monitor

        connectToDetector
    }

    public method connectToDetector {} {
        if {[catch {
            set _socket [socket $_host $_port]
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
            puts "ERROR: cannot connect to Pilatus detector $errorMsg"

            dcss breakConnection
            after 1000 [list $this connectToDetector]
            return
        }

        set connected true
    }




    private method connectError {} {
        puts "Error connecting to Pilatus detector"
        after 1000
        set socket_ [socket -error [list $this $connectError] $host $port  ]
    }
    private method putsDet {msg_} {
        puts "pilatus<DHS: $msg_"
        #if { [string length $msg_] > 5} {
        #    puts -nonewline  $_socket [string range ${msg_} 0 4]
        #    flush $_socket
        #    puts -nonewline  $_socket [string range ${msg_} 5 end]
        #    puts -nonewline  $_socket [format %c 0]
        #    flush $_socket
        #} else {
            #puts -nonewline $_socket "${msg_}[format %c 0]"
            puts -nonewline $_socket "${msg_}[format %c 0]"
            flush $_socket
        #}

        puts "pilatus<DHS: flush" 
    }

    private method loadFlatFieldCorrection {} {
        if {$_flatFieldFile != "" } {
            putsDet "LdFlatField $_flatFieldFile"
        } else {
            puts "WARNING: no flat field correction file loaded"
        }
    }

    private method loadBadPixelMap {} {
        puts "Load bad pixel map"
        if {$_badPixelMapFile != "" } {
            putsDet "LdBadPixMap $_badPixelMapFile"
        } else {
            puts "WARNING: no bad pixel map file loaded"
        }
    }

    private method setImgMode {} {
        putsDet "imgmode xray"
    }

    private method setGapFill {} {
        putsDet "GapFill $_gapFillValue"
    }

    private method configureHeader { imageParams_ } {
        putsDet "MXSettings Wavelength [$imageParams_ cget -wavelength]"
        putsDet "MXSettings Detector_distance [expr [$imageParams_ cget -distance] * 0.001 ]"
        putsDet "MXSettings Start_angle [$imageParams_ cget -oscillationStart]"
        if { [$imageParams_ cget -axisName] == "gonio_phi" } {
            putsDet "MXSettings Phi [$imageParams_ cget -oscillationStart]"
        }
        putsDet "MXSettings Angle_increment [$imageParams_ cget -oscillationRange]"
        set detectorOffsetPixelsX [expr [$imageParams_ cget -detectorX] * $_detectorPixelSizeFactorX]
        set detectorOffsetPixelsY [expr [$imageParams_ cget -detectorY] * $_detectorPixelSizeFactorY]
        putsDet "MXSettings Beam_xy [expr $_detectorXCenterPixel + $detectorOffsetPixelsX ],[expr $_detectorYCenterPixel - $detectorOffsetPixelsY]"

    }

    private method assertNotBusy {} {
        if { [cget -collecting] == true} {
            puts "two starts in a row"
            return -code error "Two starts in a row"
        }
    }

    public method start { imageParams_ } {
        puts "start" 
        assertNotBusy
        $_multiImageParams copy $imageParams_
        $_multiImageParams configure -numImages 1
        $_multiImageParams sliceImages $_sumImagesDeltaDeg

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
	        dcss sendMessage "htos_operation_completed detector_stop $handle_ normal"
        }

        lappend _abortOps $handle_ 
    }

    public method async_abort { } {
        putsDet "K"
    }


    public method sendType {} {
	    dcss sendMessage "htos_set_string_completed detectorType normal PILATUS6"	
    }

    public method collectShutterless {imageParams_ } {
        puts "collectShutterless" 
        assertNotBusy
        $_multiImageParams copy $imageParams_
        $_multiImageParams sliceImages $_sumImagesDeltaDeg

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

        set userName [$_multiImageParams cget -userName]
        set destinationRootName [$_multiImageParams cget -filename]
        set destinationDir [$_multiImageParams cget -directory]

        #setup up local directory to put the data set
        set localDir "${_tmpDir}/$userName/"
        file mkdir $localDir

        #setup unique file names for local files
        set uid [clock seconds]
        $_multiImageParams configure -localUniqueRunId $uid
        $_multiImageParams configure -localDir $localDir

        putsDet "exttrigger $localDir${uid}_.cbf"
        configure -collecting true

    }

    public method startExternalEnable {handle_ numExp_ expTime_ readTime_ filename_} {
        puts $_socket "extenable $numExp_ $expTime_ $readTime_ $filename_"
        flush $_socket
        set msg [waitForDetectorResponse]
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

        qput _lastMessageFromDetectorFifo $response
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
                    set imageNum [$_multiImageParams cget -numCollected]

                    set localFileName [$_multiImageParams lookupLocalFileName $imageNum]
                    set remoteFileName [$_multiImageParams lookupRemoteFileName $imageNum]
            
                    set userName [$_multiImageParams cget -userName]
                    set sessionId [stripPrivateKeyword [$_multiImageParams cget -sessionID]] 

                    $_fileMover moveFile $localFileName $remoteFileName $userName $sessionId false
                }
            }

            configure -collecting false
            if { [$_multiImageParams cget -operationActive] } {
                if { $exposureMode == "SHUTTER" } {
                    dcss sendMessage "htos_operation_completed detector_collect_image $opHandle abort $returnMsg"
                } else {
                    dcss sendMessage "htos_operation_completed detectorCollectShutterless $opHandle abort $returnMsg"
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
                    if { [$_multiImageParams cget -operationType] == "detector_collect_image" } {
                        dcss sendMessage "htos_operation_completed detector_collect_image [$_multiImageParams cget -operationHandle] normal"

                        set remoteFileName [$_multiImageParams cget -directory]/[$_multiImageParams cget -filename].cbf
                        set userName [$_multiImageParams cget -userName]
                        set sessionId [stripPrivateKeyword [$_multiImageParams cget -sessionID]] 
                        $_fileMover moveFile $localFileName $remoteFileName $userName $sessionId true
                    } else {
                        set remoteFileName [$_multiImageParams lookupLastRemoteFileName]
                        putsImg INFO $_multiImageParams "End shutterless, last image: $remoteFileName"
                        set userName [$_multiImageParams cget -userName]
                        set sessionId [stripPrivateKeyword [$_multiImageParams cget -sessionID]] 

                        dcss sendMessage "htos_operation_completed detectorCollectShutterless [$_multiImageParams cget -operationHandle] normal"
                        $_fileMover moveFile $localFileName $remoteFileName $userName $sessionId false 
                    }
                }
                15 {
                    handleReturnCode15 $returnMsg
                }
            }


        }
        

        set ::pilatusMessage -

        $_detectorStatus updateDetectorStatusString

    }


    private method handleReturnCode15 {  msg_ } {
        set exposureMode [$_detectorStatus cget -exposureMode]
	    set opHandle [$_multiImageParams cget -operationHandle]

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
            $_fileMover moveFile $localFileName $remoteFileName $userName $sessionId false

            dcss sendMessage "htos_operation_update [$_multiImageParams cget -operationType] $opHandle exposed $imageNum"
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
        dcss sendMessage "htos_operation_update $op $opHandle start_oscillation shutter $expTime $filename"
        #    dcss sendMessage "htos_operation_update detectorCollectShutterless $opHandle start_oscillation"


    }
   
    public method queryTemp {} {
        putsDet "th"
    }

    public method checkDiskUse {} {
        $_detectorStatus checkDiskSpace $_tmpDir
        $_detectorStatus updateDetectorStatusString
    }

    private method waitForDetectorResponse {} {
        putsImg INFO $_multiImageParams "wait for ok"
        #puts $::Pilatus::_lastMessageFromDetectorFifo
        vwait ::pilatusMessage
        putsImg INFO $_multiImageParams "got ok"

        set message [qget _lastMessageFromDetectorFifo]
        if { [lindex [split $message] end] == "ERR" } {return -code error "Pilatus error: must set expTime first"}
        
        return [qget _lastMessageFromDetectorFifo]
    }

    #puts with special frame header
    public method putsImg {level imageParams_ msg_} {
        puts "DHS: $level \[[$imageParams_ cget -filename]\] $msg_"  
    }


}

configbody Pilatus::collecting {
        puts "configuring collecting $collecting"
        if { $collecting == false} {
            foreach handle $_abortOps {
	            dcss sendMessage "htos_operation_completed detector_stop $handle normal"
            }
        }

        lset _abortOps "" 

        #putsDet "K"
    }


