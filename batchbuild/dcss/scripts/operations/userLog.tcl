###################################################################
# userLog operation is the interface to create a new log and 
# change the file protection mode of the previous log file.
#
# It performs following tasks in sequence:
#
# 1. create a new log file with name pattern "timestamp-counter"
# 2. change global string of "current_user_log", point to the new file
# 3. change protection mode of previous file to staff read only.
###################################################################
# the change of global string "current_user_log" will trigger
# update of the Log tab in the BluIce.  The view will be cleared
# and display the newly created empty log file.
###################################################################
# string "current_user_log"
#
# only 1 field is defined for now (09/29/05)
# field 0:   current_log_file (full path)
###################################################################
proc userLog_initialize {} {
}

proc userLog_start { args } {
    variable current_user_log
    global gBeamlineId
    global gUserLogSystemStatus

    ################### DIRECTORY ####################
    set dir [::config getUserLogDir]
    if {$dir == ""} {
        set dir "/data/blctl/userLog/$gBeamlineId"
    }

    file mkdir $dir
    ################# FILENAME########################
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set log_root [file join $dir "userLog${timestamp}"]
    set log_name ${log_root}.ulg
    set counter 0
    while {[file exists $log_name]} {
        incr counter 1
        if {$counter > 100} {
            return -code error "user log filename conflict"
        }
        set log_name ${log_root}_${counter}.ulg
    }

    #################### CREATE NEW LOG FILE #############
    set handle [open $log_name w 0664]
    puts $handle "UserLog $log_name"
    close $handle
    ###no need anymore, we are not running as root anymore
    ##file attribute $log_name -owner blctl -group px
    file attribute $log_name -permissions 0664

    ##################### UPDATE STRING ###############
    set old_path [lindex $current_user_log 0]
    set current_user_log [lreplace $current_user_log 0 0 $log_name]

    ################### clear saved system status #########
    # so that they will be printed out in start           #
    #######################################################
    array unset gUserLogSystemStatus *

    ##################### change protection ###########
    if {[file exists $old_path]} {
        file attributes $old_path -permissions 0660
    }

    return "new user log file created $log_name"
}
