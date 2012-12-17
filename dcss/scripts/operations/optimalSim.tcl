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

proc optimalExcitation_initialize {} {
    variable optimalExcitationIndex
    set optimalExcitationIndex -1
}



proc optimalExcitation_start { userName_ sessionId_ directory_ fileRoot_ selectedEdge_ energy_ scanTime_ } {
    variable optimalExcitationIndex
    variable scan_msg
	
    checkUsernameInDirectory directory_ $userName_

    if [catch {block_all_motors;unblock_all_motors} errMsg] {
        log_error $errMsg
        puts "MUST wait all motors stop moving to start"
        log_error "MUST wait all motors stop moving to start"
        return -code error "MUST wait all motors stop moving to start"
    }
	
    if {$sessionId_ == "SID"} {
        set sessionId_ "PRIVATE[get_operation_SID]"
        puts "use operation SID: $sessionId_"
    }

    ################# check directory #####################
    if {[catch {
        impDirectoryWritable $userName_ $sessionId_ $directory_
    } errMsg]} {
        log_error directory $directory_ check failed: $errMsg
        return -code error "directory not writable"
    }

    incr optimalExcitationIndex

    set searchDir [::config getStr simExcitationScan.dir]
    if {$searchDir == ""} {
        log_error no simExcitationScan.dir defined in config file
        return -code error "no simExcitationScan.dir defined in config file"
    }
    set fileList [glob -nocomplain -types f -directory $searchDir -- *.bip]
    set ll [llength $fileList]
    if {$ll <= 0} {
        log_error no bip file found in $searchDir
        return -code error "no bip file found in $searchDir"
    }

    set fileIndex [expr $optimalExcitationIndex % $ll]
    set filename [lindex $fileList $fileIndex]
    set source [file join $searchDir $filename]

   variable excitationScanStatus

   set index(active) 0
   set index(message) 1
   set index(user) 2
   set index(directory) 3
   set index(fileRoot) 4
   set index(edge) 5
   set index(energy) 6
   set index(cutoff) 7
   set index(time) 8
   set index(madResult) 9
   set index(exciteResult) 10

   set referenceDetector "i2"

    #############user log ######
    user_log_note excitationscan "============ $userName_ start =========="
    user_log_note excitationscan "edge       $selectedEdge_"
    user_log_note excitationscan "energy     $energy_"
    user_log_note excitationscan "scanTime   $scanTime_"
    user_log_note excitationscan "directory  $directory_"
    user_log_note excitationscan "fileRoot   $fileRoot_"
    user_log_note excitationscan "crystal    [user_log_get_current_crystal]"

    set fullPath [file join $directory_ ${fileRoot_}.bip]

    if {[catch {	
        impCopyFile $userName_ $sessionId_ $source $fullPath
        set exciteResult $fullPath
        send_operation_update $exciteResult 
    } errorResult]} {
        variable excitationScanStatus
        set excitationScanStatus [lreplace $excitationScanStatus 0 $index(message) 0 "Excitation scan failed: $errorResult."]
        log_error "Excitation scan failed: $errorResult"
        user_log_error excitationscan "failed $errorResult"
        user_log_note  excitationscan "==================end=================="
        set scan_msg "error: $errorResult"
        return -code error $errorResult
    }

    set fluorScanTemp [lreplace $excitationScanStatus 0 $index(message) 0 "Excitation scan completed normally."]
    set excitationScanStatus [lreplace $fluorScanTemp $index(exciteResult) $index(exciteResult) $exciteResult]

    user_log_note  excitationscan "==================end=================="

    set scan_msg ""
    return $exciteResult
}
