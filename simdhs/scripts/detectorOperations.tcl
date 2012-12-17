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

#This function requires that this simulator run in DCS protocol 2.0

package require DCSImperson
#package require DCSUtil

source $SIM_DIR/PilatusSupport.tcl

class ImageParams {
    public variable localFileName ""
    public variable operationHandle ""
    public variable operationActive true
    public variable runIndex
    public variable filename
    public variable directory
    public variable userName
    public variable axisName
    public variable exposureTime
    public variable oscillationStart
    public variable oscillationRange
    public variable distance
    public variable wavelength
    public variable detectorX
    public variable detectorY
    public variable detectorMode
    public variable reuseDark
    public variable sessionID 
    public variable operationType

    #copy method
    public method copy { object_ } {
        foreach dataMember { localFileName operationHandle runIndex filename directory userName axisName exposureTime oscillationStart oscillationRange \
            distance wavelength detectorX detectorY detectorMode reuseDark sessionID operationActive operationType } {
            configure -$dataMember [$object_ cget -$dataMember]
        }
    }
}


#class for holding info for shutterless mode
class MultiImageParams {
    inherit ImageParams

    public variable numImages
    public variable startIndex
    public variable numCollected 0
    public variable nFrameImg 1
    public variable nFrameDelta 0.0

    public variable localUniqueRunId
    public variable localDir

    public method lookupLocalFileName { index } {
        return [format "$localDir/${localUniqueRunId}_%05d.cbf" $index]
    }

    public method lookupRemoteFileName { index } {
        set runOffset [expr $index + $startIndex ]
        return "${directory}/${filename}_[format "%04d" $runOffset].cbf"
    }

    public method lookupLastRemoteFileName {  } {
        return [lookupRemoteFileName [expr $numImages - 1]]
    }

    public method sliceImages { sliceDeg } {
        if { $sliceDeg == 0.0} {    
            set nFrameDelta $oscillationRange
            set nFrameImg 1
            return
        }

        if {$oscillationRange <= $sliceDeg } {
            set nFrameDelta $oscillationRange
            set nFrameImg 1
        } else {
            set nFrameImg [expr floor ($oscillationRange / $sliceDeg )]
            set nFrameDelta [expr $oscillationRange / $nFrameImg]
        }
    }

    #copy method
    public method copy { object_ } {
        foreach dataMember { localFileName localDir operationHandle runIndex \
                filename directory userName axisName exposureTime \
                oscillationStart oscillationRange distance wavelength \
                detectorX detectorY detectorMode reuseDark sessionID \
                operationActive numImages startIndex numCollected operationType \
                nFrameImg nFrameDelta } {
            configure -$dataMember [$object_ cget -$dataMember]
        }
    }
}

proc detector_collect_image {operationHandle_ runIndex_ filename_ directory_ \
    userName_ axisName_ exposureTime_ oscillationStart_ oscillationRange_ \
    distance_ wavelength_ detectorX_ detectorY_ detectorMode_ reuseDark_ sessionID_ } {

    set imageParams [::itcl::local MultiImageParams #auto]
    $imageParams configure -operationHandle $operationHandle_ -runIndex $runIndex_ -filename $filename_ -directory $directory_ \
        -userName $userName_ -axisName $axisName_ \
        -exposureTime $exposureTime_ -oscillationStart $oscillationStart_ -oscillationRange $oscillationRange_ -distance $distance_ \
        -wavelength $wavelength_ -detectorX $detectorX_ -detectorY $detectorY_ -detectorMode $detectorMode_ -reuseDark $reuseDark_ \
        -sessionID $sessionID_ -operationType "detector_collect_image"

    puts "DHS<DCSS detector_collect_image"
    #########

    
    if {[catch {
        detector start $imageParams
    } errorMsg ]} {
	    putsImg SEVERE $imageParams $errorMsg
        dcss sendMessage "htos_operation_completed detector_collect_image $operationHandle_ abort $errorMsg"
    }
}

proc detector_oscillation_ready { handle_ args } {
    #should only come here if we send a prepare_for_oscillation
    #dcss sendMessage "htos_operation_update detector_collect_imge $handle_ start_oscillation $shutter $oscTime $filename"
    #dcss sendMessage "htos_operation_completed detector_oscillation_ready $operationHandle normal"
}

proc detector_transfer_image { handle_ args } {
    puts "DHS<DCSS detector_transfer_image"

    #dcss sendMessage "htos_operation_completed detector_collect_image [imageParams cget -operationHandle] normal"

    detector stop
    dcss sendMessage "htos_operation_completed detector_transfer_image $handle_ normal"

    #lastImageParams copy imageParams
}

proc detector_reset_run { handle_ runIndex_ } {
    dcss sendMessage "htos_operation_completed detector_reset_run $handle_ normal $runIndex_"
}

proc detector_stop { handle_ args } {
    puts "DHS<DCSS detector_stop $handle_"
    detector abort $handle_
}



proc detectorCollectShutterless {operationHandle_ runIndex_ filename_ directory_ \
    userName_ axisName_ exposureTime_ oscillationStart_ oscillationRange_ \
    distance_ wavelength_ detectorX_ detectorY_ detectorMode_ reuseDark_ sessionID_ numImages_ nextFrame_ } {

    set imageParams [::itcl::local MultiImageParams #auto]
    $imageParams configure -operationHandle $operationHandle_ -runIndex $runIndex_ -filename $filename_ -directory $directory_ \
        -userName $userName_ -axisName $axisName_ \
        -exposureTime $exposureTime_ -oscillationStart $oscillationStart_ -oscillationRange $oscillationRange_ -distance $distance_ \
        -wavelength $wavelength_ -detectorX $detectorX_ -detectorY $detectorY_ -detectorMode $detectorMode_ -reuseDark $reuseDark_ \
        -sessionID $sessionID_ -numImages $numImages_ -startIndex $nextFrame_ -operationType "detectorCollectShutterless"

    puts "DHS<DCSS detectorCollectShutterless"
    #########

    
    if {[catch {
        detector collectShutterless $imageParams
    } errorMsg ]} {
	    putsImg SEVERE $imageParams $errorMsg
        dcss sendMessage "htos_operation_completed detectorCollectShutterless $operationHandle_ abort $errorMsg"
    }
}




proc writeImageToUserDirWithLoggedElapsedTime { localFile remoteFile userName sessionId } {
    #check to see if object is valid
    #if { [$imageParams_ cget -operationHandle] == "" } return
    puts "COPY: Write image via imperson. [time {writeImageToUserDir $localFile $remoteFile $userName $sessionId}]"
    file delete $localFile
}


#operation for BL4-2
proc pilatusExpose {handle_ numExp_ expTime_ readTime_ filename_} {
    puts "DHS<DCSS detector_stop"
    detector  startExternalEnable $numExp_ $expTime_ $readTime_ $filename_
	dcss sendMessage "htos_operation_completed pilatusExpose $handle_ normal"
}

proc writeImageToUserDir { localFileName remoteFile userName sessionId } {

    set timeTxt [time {
        set img [open $localFileName r]
        fconfigure $img -translation binary
        set data [read $img]
        close $img
    } ]

    puts "COPY: read from $localFileName time: $timeTxt"

    puts "write"
    impWriteFileWithBackup $userName $sessionId $remoteFile $data true 

    #invalidate object after copy
    #$imageParams_ configure -operationHandle ""
    puts "done writing"
}


#trim the private keyword from the session id
proc stripPrivateKeyword { session_ } {
    if {[string equal -length 7 $session_ "PRIVATE"]} {
        return [string range $session_ 7 end]
    } else {
        return $session_
    }
}

#puts with special frame header
proc putsImg {level imageParams_ msg_} {
    puts "DHS: $level \[[$imageParams_ cget -filename]\] $msg_"  
}


