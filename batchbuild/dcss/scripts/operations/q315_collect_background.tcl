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

proc q315_collect_background_initialize {} {}


proc q315_collect_background_start { storedDarkDir userName sessionId minTime args} {
    set binnedMode 2
    set unbinnedMode 0
    set numDarks 10

    if {$sessionId == "SID"} {
        set sessionId PRIVATE[get_operation_SID]
        #puts "use operation SID: [SIDFilter $sessionID]"
    }

    set darkTimes [list 1 2 3 4 5 6 7 8 9 10 15 20 30 40 50 60 80 100 120 180 240 320 400 480 560 600]

	if { [catch {
        foreach time $darkTimes {
            if { $time < $minTime } continue;

            set fileList ""
            for {set cnt 0} {$cnt < $numDarks} {incr cnt} {
                set fileName storedBinDark_${time}_$cnt 
                set operationHandle [start_waitable_operation collectFrame 0 $fileName $storedDarkDir $userName NULL NULL 0 $time $binnedMode 1 0 $sessionId ]
                wait_for_operation $operationHandle
                lappend fileList $storedDarkDir/${fileName}.im0
            } 

            wait_for_time 5000
            #puts "exec /tmp/dezinger_dark/dezinger_dark -nowarn -sigma 6 $fileList -o $storedDarkDir/dezingerBinDark_${time}.dzd"
            #eval exec /usr/local/dcs/det_api/dezinger_dark/dezinger_dark -nowarn -sigma 6 $fileList  -o $storedDarkDir/dezingerBinDark_${time}.dzd 2>> /dev/null
            log_warning "impRunScript $userName $sessionId"
            set result [impRunScript $userName $sessionId "/usr/local/dcs/det_api/dezinger_dark/dezinger_dark -nowarn -sigma 6 $fileList  -o $storedDarkDir/dezingerBinDark_${time}.dzd"]
            log_warning $result
        }
	} errorResult ] } {
		log_error "Error collecting background images: $errorResult"
		start_recovery_operation detector_stop
		return -code error $errorResult
	}


}

