#!/usr/bin/tclsh
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



class Pilatus::DhsProtocol {

    inherit DCS::DhsProtocol

    public variable dcssHost localhost
    public variable dcssHardwarePort 14242 


    public method handleCompleteMessage { } {
        set _socketGood 1
        if { $callback != "" } {
            eval $callback [list $_textMessage $_binaryMessage]
        }
    }

    constructor {} {DCS::DhsProtocol::constructor $dcssHost $dcssHardwarePort} {
    }

    public method afterPropertiesSet {} {
        set _otheraddr $dcssHost
        set _otherport $dcssHardwarePort
    }
}

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

    public variable numImages 0
    public variable startIndex 0
    public variable numCollected 0
    public variable nFrameImg 1
    public variable nFrameDelta 0.0

    public variable localUniqueRunId ""
    public variable localDir ""

    public method lookupLocalFileName { index } {
        return [format "$localDir/${localUniqueRunId}_%05d.cbf" $index]
    }

    public method lookupRemoteFileName { index } {
        set runOffset [expr $index + $startIndex ]
        return "${directory}/${filename}_[format "%05d" $runOffset].cbf"
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




class Pilatus::Dhs {

    public variable dcssHost
    public variable dcssHardwarePort 14242 
    public variable reconnectTime 1000
    public variable hardwareName detector
    public variable pilatus
    public variable pilatusMonitor
    public variable fileMover
    
    public variable dcss

    constructor {} {
        
    }

    public method afterPropertiesSet {} {
        $dcss configure -_reconnectTime $reconnectTime
        $dcss configure -callback "${this} handleMessagesSpecial"
        $dcss configure -networkErrorCallback "$this handleNetworkError"
        $dcss configure -hardwareName $hardwareName
        $dcss connect
        $fileMover backgroundMover
    }

    public method handleMessagesSpecial {text_ bin_} {

    if { [catch {
        handleMessages $text_   	
    } err] } {
	    puts $err
    }


    }
    public method handleMessages {text_} {

        puts $text_

        if { [scan $text_ "stoh_register_operation %s" opName ] == 1 } {
            puts "register $opName"
            return
        } 

        if { [scan $text_ "stoh_start_operation detector_collect_image \
                            %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s" \
                            operationHandle runIndex filename directory userName \
                            axisName exposureTime oscillationStart oscillationRange \
                            distance wavelength detectorX detectorY detectorMode \
                            reuseDark sessionID ] == 16} {

            set imageParams [namespace current]::[local MultiImageParams #auto]
            $imageParams configure -operationHandle $operationHandle -runIndex $runIndex -filename $filename -directory $directory \
                -userName $userName -axisName $axisName -exposureTime $exposureTime -oscillationStart $oscillationStart \
                -oscillationRange $oscillationRange -distance $distance -wavelength $wavelength -detectorX $detectorX \
                -detectorY $detectorY -detectorMode $detectorMode -reuseDark $reuseDark -sessionID $sessionID -operationType "detector_collect_image" 
            puts "DHS<DCSS detector_collect_image"
            if {[catch {
                puts $imageParams
                $pilatus start $imageParams
            } errorMsg ]} {
	            putsImg SEVERE $imageParams $errorMsg
                $dcss sendMessage "htos_operation_completed detector_collect_image $operationHandle abort $errorMsg"
            }
        }

        #detector_oscillation_ready
        #should only come here if we send a prepare_for_oscillation

        if { [scan $text_ "stoh_start_operation detector_transfer_image %s" handle] == 1 } {
            puts "DHS<DCSS detector_transfer_image"
            $pilatus stop
            $dcss sendMessage "htos_operation_completed detector_transfer_image $handle normal"
            return
        } 

        if { [scan $text_ "stoh_start_operation detector_reset_run %s %s" handle runIndex] == 2 } {
            $dcss sendMessage "htos_operation_completed detector_reset_run $handle normal $runIndex"
            return
        }

        if { [scan $text_ "stoh_start_operation detector_stop %s" handle ] == 1 } {
            $dcss sendMessage "htos_operation_completed detector_stop $handle normal"
            puts "DHS<DCSS detector_stop $handle"
            $pilatus abort $handle
            return
        }

        if { [scan $text_ "stoh_start_operation detectorSetThreshold %s %s %s" handle gain threshold ] == 3 } {
            if {[catch {
                $pilatus changeThreshold $handle $gain $threshold
                $dcss sendMessage "htos_operation_update detectorSetThreshold $handle normal Please wait two minutes to set the detector threshold."
            } errorMsg ] } {
	            $dcss sendMessage "htos_operation_completed detectorSetThreshold $handle abort $errorMsg"
            }
            return
        }

        if { [scan $text_ "stoh_start_operation detectorCollectShutterless \
                            %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s" \
                            operationHandle runIndex filename directory userName \
                            axisName exposureTime oscillationStart oscillationRange \
                            distance wavelength detectorX detectorY detectorMode \
                            reuseDark sessionID numImages nextFrame] == 18} {

            set imageParams [namespace current]::[local MultiImageParams #auto]
            $imageParams configure -operationHandle $operationHandle -runIndex $runIndex -filename $filename -directory $directory \
                -userName $userName -axisName $axisName \
                -exposureTime $exposureTime -oscillationStart $oscillationStart -oscillationRange $oscillationRange -distance $distance \
                -wavelength $wavelength -detectorX $detectorX -detectorY $detectorY -detectorMode $detectorMode -reuseDark $reuseDark \
                -sessionID $sessionID -numImages $numImages -startIndex $nextFrame -operationType "detectorCollectShutterless"
            puts "DHS<DCSS detectorCollectShutterless"
            #########
    
            if {[catch {
                $pilatus collectShutterless $imageParams
            } errorMsg ]} {
	            putsImg SEVERE $imageParams $errorMsg
                $pilatus sendMessage "htos_operation_completed detectorCollectShutterless $operationHandle abort $errorMsg"
            }
            return
        }

        if { [scan $text_ "stoh_register_string %s" strName] == 1} {
            switch $strName {
                lastImageCollected { puts "lastImageCollected" }
                detectorStatus {puts "detectorStatus"}
                detectorType {
                    sendString detectorType [$pilatus cget -detectorType]
                    return
                }
                default {
                    puts "no str"
                    return
                }
            }
        }

        if { [lindex [split $text_] 0] == "stoh_abort_all" } { 
            $pilatus async_abort
            return
        }

        puts "no handler"

    }

    public method handleNetworkError {} {
       #after 1000 [list $dcss connect]
       puts "Disconnected from dcss server."
    }

    private method sendString { str val} {
	    $dcss sendMessage "htos_set_string_completed $str normal $val"	
    }
}






