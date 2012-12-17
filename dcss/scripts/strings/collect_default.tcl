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

proc STRING_initialize {} {
}


#### integrity checking
proc STRING_configure { args } {
    variable ::nScripts::STRING

    set contents $args
    set anyChange 0

    set ll [llength $contents]
    if {$ll < 5} {
        log_severe STRING contents not right, fixing
        incr anyChange

        switch $ll {
            0 {
                set contents [list 1.0 2.0 0 1 120 0 100]
            }
            1 {
                lappend contents 2.0 0 1 120 0 100
            }
            2 {
                lappend contents 0 1 120 0 100
            }
            3 {
                lappend contents 1 120 0 100
            }
            4 {
                lappend contents 120 0 100
            }
            5 {
                lappend contents 0 100
            }
            6 {
                lappend contents 100
            }
        }
    }
    foreach \
    {cur_delta cur_exposure_time cur_attenuation cur_timeMin cur_timeMax \
    cur_attMin cur_attMax} \
    $STRING break

    foreach {delta exposure_time attenuation timeMin timeMax attMin attMax } \
    $contents break
    if {$delta <= 0} {
        if {[string is double -strict $cur_delta] && $cur_delta > 0} {
            set delta $cur_delta
            log_severe default delta restored to $delta degree
        } else {
            set delta 1.0
            log_severe default delta changed to $delta degree
        }
        incr anyChange
    }
    if {$timeMin <= 0} {
        if {[string is double -strict $cur_timeMin] && $cur_timeMin > 0} {
            set timeMin $cur_timeMin
            log_severe minimum exposure time restored to $timeMin seconds
        } else {
            set timeMin 0.001
            log_severe minimum exposure time changed to $timeMin seconds
        }
        incr anyChange
    }
    if {$timeMax < $timeMin} {
        if {[string is double -strict $cur_timeMax] && \
        $cur_timeMax > $timeMin} {
            set timeMax $cur_timeMax
            log_error maximum exposure time must be bigger than minimum $timeMin
            log_severe maximum exposure time restored to $timeMax seconds
        } else {
            set timeMax [expr $timeMin + 120]
            log_severe maximum exposure time changed to $timeMax seconds
        }
        incr anyChange
    }
    if {$exposure_time < $timeMin} {
        log_error default exposure time must not smaller than min $timeMin
        if {[string is double -strict $cur_exposure_time] && \
        $cur_exposure_time >= $timeMin && \
        $cur_exposure_time <= $timeMax} {
            set exposure_time $cur_exposure_time
            log_severe default exposure time restored to $exposure_time
        } else {
            set exposure_time $timeMin
            log_severe default exposure time changed to $exposure_time
        }
        incr anyChange
    }
    if {$exposure_time > $timeMax} {
        log_error default exposure time must not bigger than max $timeMax
        if {[string is double -strict $cur_exposure_time] && \
        $cur_exposure_time >= $timeMin && \
        $cur_exposure_time <= $timeMax} {
            set exposure_time $cur_exposure_time
            log_severe default exposure time restored to $exposure_time
        } else {
            set exposure_time $timeMax
            log_severe default exposure time changed to $exposure_time
        }
        incr anyChange
    }

    if {$attMin < 0} {
        log_error minimum attenuation must not be less than 0
        if {[string is double -strict $cur_attMin] && \
        $cur_attMin >= 0 && \
        $cur_attMin <= 100} {
            set attMin $cur_attMin
            log_severe min attenuation restored to $attMin
        } else {
            set attMin 0
            log_severe min attenuation changed to $attMin
        }
        incr anyChange
    }
    if {$attMax < $attMin || $attMax > 100} {
        log_error maximum attenuation must be between $attMin - 100
        if {[string is double -strict $cur_attMax] && \
        $cur_attMax >= $attMin && \
        $cur_attMax <= 100} {
            set attMax $cur_attMax
            log_severe maximum attenuation restored to $attMax
        } else {
            set attMax 100
            log_severe maximum  attenuation changed to $attMax
        }
        incr anyChange
    }

    if {$attenuation < $attMin} {
        log_error default attenuation must not be less than min $attMin
        if {[string is double $cur_attenuation] && \
        $cur_attenuation >= $attMin && $cur_attenuation <= $attMax} {
            set attenuation $cur_attenuation
            log_severe default attenuation restored to $attenuation
        } else {
            set attenuation $attMin
            log_severe default attenuation changed to $attenuation
        }
        incr anyChange
    }
    if {$attenuation > $attMax} {
        log_error default attenuation must not be bigger than max $attMax
        if {[string is double $cur_attenuation] && \
        $cur_attenuation >= $attMin && $cur_attenuation <= $attMax} {
            set attenuation $cur_attenuation
            log_severe default attenuation restored to $attenuation
        } else {
            set attenuation $attMax
            log_severe default attenuation changed to $attenuation
        }
        incr anyChange
    }

    if {$anyChange} {
        set contents [lreplace $contents 0 6 \
        $delta $exposure_time $attenuation $timeMin $timeMax $attMin $attMax]

        return $contents
    }
	return $args
}

