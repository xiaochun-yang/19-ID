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


proc requestExposureTime_initialize {} {
}

proc requestExposureTime_start { requestedTime useDose } {
    variable dose_data
    
    if {![beamGood]} {
        wait_for_good_beam
    }

    if {!$useDose} {
        return $requestedTime
    }

    set doseStoredCounts [lindex $dose_data 1]
  	print "DOSE STORED: $doseStoredCounts"
    if {![string is double -strict $doseStoredCounts] || \
    $doseStoredCounts == 0} {
        log_warning dose stored counts wrong $doseStoredCounts
        return $requestedTime
    }

    set counts [getStableIonCounts FALSE]
  	print "DOSE STABLE: $counts"
    if {![string is double -strict $counts] || $counts == 0} {
        log_warning dose stable counts wrong $counts
        return $requestedTime
    }

    set doseFactor [expr abs(double($doseStoredCounts) / double($counts)) ]
	
	set correctedTime [ expr double($requestedTime) * double($doseFactor) ]

    
  	print "DOSE FACTOR = $doseFactor"
    print "CORRECTED TIME = $correctedTime"
   
    return $correctedTime
}

