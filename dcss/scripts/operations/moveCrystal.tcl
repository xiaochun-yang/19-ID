package require DCSUtil

## will use moveCrystal_cleanup to make sure sils are unlocked.

proc moveCrystal_initialize {} {
    variable moveCrystal_lastUserName
    variable moveCrystal_lastSessionID
    variable moveCrystal_lastSilList
    variable moveCrystal_lastKey

    set moveCrystal_lastUserName   ""
    set moveCrystal_lastSessionID  ""
    set moveCrystal_lastSilList    ""
    set moveCrystal_lastKey        ""
}

proc moveCrystal_cleanup { } {
    variable moveCrystal_lastUserName
    variable moveCrystal_lastSessionID
    variable moveCrystal_lastSilList
    variable moveCrystal_lastKey

    if {$moveCrystal_lastKey != ""} {
        ## clean flag before call to make sure it will be cleaned even
        ## the call fails.
        set v $moveCrystal_lastKey
        set moveCrystal_lastKey ""
        unlockSilList $moveCrystal_lastUserName $moveCrystal_lastSessionID \
        $moveCrystal_lastSilList $v
    }
}

proc moveCrystal_start { cmd args } {
    variable moveCrystal_lastUserName
    variable moveCrystal_lastSessionID
    variable moveCrystal_lastSilList
    variable moveCrystal_lastKey
    variable moveCrystalSilMap

    #dCS string
    variable robot_move
    variable robotMoveStatus

    moveCrystal_cleanup

    set isStaff [get_operation_isStaff]

    switch -exact -- $cmd {
        remove_all {
            set robot_move ""
            set robotMoveStatus \
            [lreplace $robotMoveStatus 1 3 0 0 "List cleared"]
            return
        }
        toggle_move_data {
            set old [lindex $robotMoveStatus 0]
            if {$old == "1"} {
                set new 0
            } else {
                set new 1
            }
            if {$isStaff} {
                set robotMoveStatus [lreplace $robotMoveStatus 0 0 $new]
            } else {
                set robotMoveStatus [lreplace $robotMoveStatus 0 0 0]
                log_warning moving spreadsheet data not supported yet
            }
            return
        }
        start {
        }
        default {
            return -code error "command {$cmd} not supported"
        }
    }

    ###get here, means "start"
    set startIndex [lindex $robotMoveStatus 2]
    set moveCrystal_lastUserName [get_operation_user]
    set moveCrystal_lastSessionID PRIVATE[get_operation_SID]
    set moveSilToo [lindex $robotMoveStatus 0]
    foreach {needMoveList needCassetteList} [moveCrystal_getList] break

    if {!$isStaff} {
        set moveSilToo 0
    }


    if {$moveSilToo} {
        user_log_note move_crystal \
        "=======$moveCrystal_lastUserName start move crystal and update spreadsheets========"
    } else {
        user_log_note move_crystal \
        "=======$moveCrystal_lastUserName start move crystal========"
    }

    if {$moveSilToo} {
        if {[catch {moveCrystal_lockSils $needCassetteList} errMsg]} {
            log_error lockSil for moveCrylstal failed: $errMsg
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            0 $startIndex $errMsg]
            user_log_error move_crystal \
            "=======lock spreadsheets failed: ${errMsg}========"
            return -code error $errMsg
        }
    }
    #########################################################
    #### ask robot to check list and prepare
    #########################################################
    set h [eval start_waitable_operation prepare_move_crystal $needMoveList]
    if {[catch {wait_for_operation $h} result]} {
        log_error robot check move list failed: $result
        set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
        0 $startIndex $result]
        user_log_error move_crystal \
        "=======check move list failed: ${result}========"
        return -code error $result
    }
    #first reply must be update or normal to continue
    set status [lindex $result 0]
    if {$status == "update"} {
        set robotMoveStatus [lreplace $robotMoveStatus 3 3 "probing"]
        if {[catch {
            wait_for_operation_to_finish $h
        } errMsg]} {
            log_error moveCrystal failed: $errMsg
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            0 $startIndex "failed: $errMsg"]
            start_recovery_operation robot_standby
            user_log_error move_crystal \
            "=======prepare failed: ${$errMsg}========"
            return -code error $errMsg
        }
    }

    #########################################################
    #### ask robot to move ONE crystal a time
    #########################################################
    if {[catch {
        foreach item $needMoveList {
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            1 $startIndex "moving $item"]

            ### move sample first
            set h [start_waitable_operation move_crystal $item]
            wait_for_operation_to_finish $h

            ## update spreadsheet
            set dataResult ""
            if {$moveSilToo} {
                if {[catch {moveCrystal_moveSilData \
                $moveCrystal_lastUserName $moveCrystal_lastSessionID \
                $moveCrystal_lastKey $item} dataResult]} {
                    user_log_warning move_crystal dataMove failed: $dataResult
                    set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
                    1 $startIndex "reversing $item"]
                    ###move crystal back##
                    set putbackItem [moveCrystal_generatePutbackItem $item]
                    set h [start_waitable_operation move_crystal $putbackItem]
                    wait_for_operation_to_finish $h
                    user_log_warning move_crystal $item rolled back by $putbackItem
                    return -code error $dataResult
                }
            }

            incr startIndex
            if {$dataResult == ""} {
                user_log_note move_crystal $item
            } else {
                user_log_note move_crystal $item \
                (spreadsheets update: $dataResult)
            }
        }
    } errMsg]} {
        log_error moveCrystal failed: $errMsg
        set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
        0 $startIndex "failed: $errMsg"]
        user_log_error move_crystal "=======failed ${errMsg}========"
    } else {
        set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
        0 $startIndex "all done"]
        user_log_note move_crystal "=======all done========"
    }

    start_recovery_operation robot_standby
}

proc moveCrystal_lockSils { needCassetteList } {
    variable sil_and_event_list

    variable moveCrystal_lastUserName
    variable moveCrystal_lastSessionID
    variable moveCrystal_lastSilList
    variable moveCrystal_lastKey
    variable moveCrystalSilMap

    ##generate sil_id list to lock
    set moveCrystalSilMap(l) [lindex $sil_and_event_list 2]
    set moveCrystalSilMap(m) [lindex $sil_and_event_list 4]
    set moveCrystalSilMap(r) [lindex $sil_and_event_list 6]

    set moveCrystal_lastSilList ""
    foreach cas $needCassetteList {
        set silId $moveCrystalSilMap($cas)
        if {$silId > 0} {
            lappend moveCrystal_lastSilList $silId
        }
    }


    if {$moveCrystal_lastSilList != ""} {
        set moveCrystal_lastSilList [join $moveCrystal_lastSilList ,]

        set key [lockSilList \
            $moveCrystal_lastUserName $moveCrystal_lastSessionID \
            $moveCrystal_lastSilList]
        ### return is "OK 4234543523"
        set moveCrystal_lastKey [lindex $key end]
    }
}

proc moveCrystal_moveSilData { userName sessionID lockKey item {rollback 0} } {
    variable moveCrystalSilMap

    if {$lockKey == ""} {
        return "no data to move"
    }

    set orig ""
    set dest ""
    ## no error check needed
    parseRobotMoveItem $item orig dest

    set srcCas [string index $orig 0]
    set srcPort [string range $orig 1 end]

    set destCas [string index $dest 0]
    set destPort [string range $dest 1 end]

    set srcSil ""
    if {[info exists moveCrystalSilMap($srcCas)] && \
    [string is integer -strict $moveCrystalSilMap($srcCas)] && \
    $moveCrystalSilMap($srcCas) > 0} {
        set srcSil $moveCrystalSilMap($srcCas)
    }

    set destSil ""
    if {[info exists moveCrystalSilMap($destCas)] && \
    [string is integer -strict $moveCrystalSilMap($destCas)] && \
    $moveCrystalSilMap($destCas) > 0} {
        set destSil $moveCrystalSilMap($destCas)
    }

    if {$srcSil == "" && $destSil == ""} {
        return "no data to move"
    }
    if {!$rollback} {
        silMoveCrystal $userName $sessionID $lockKey \
        $srcSil $srcPort \
        $destSil $destPort
        return "data $srcSil $srcPort -> $destSil $destPort"
    } else {
        ##reverse move and clean move field
        silMoveCrystal $userName $sessionID $lockKey \
        $destSil $destPort \
        $srcSil $srcPort \
        1
        return "data rollback: $srcSil $srcPort <- $destSil $destPort"
    }

}

proc moveCrystal_getList { } {
    variable robot_move
    variable robotMoveStatus

    set startIndex [lindex $robotMoveStatus 2]
    if {![string is integer $startIndex] || $startIndex < 0} {
            log_error startIndex wrong.  Please clear the list and retry
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            0 $startIndex {startIndex wrong, please remove all and retry}]
            return -code error "bad startIndex"
    }
    if {$startIndex >= [llength $robot_move]} {
            log_error No new move defined
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            0 $startIndex {no new move defined}]
            return -code error "all done"
    }
    set needMoveList [lrange $robot_move $startIndex end]

    set validCassetteList [moveCrystal_getValidCassetteList]

    set needCassetteList ""

    ####check syntax
    set i $startIndex
    foreach item $needMoveList {
        incr i
        set orig ""
        set dest ""
        if {![parseRobotMoveItem $item orig dest]} {
            log_error line $i syntax wrong
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            0 $startIndex "line $i syntax wrong"]
            return -code error "line $i syntax wrong"
        }
        if {$orig == ""} {
            log_error line $i empty origin
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            0 $startIndex "line $i empty origin"]
            return -code error "line $i empty origin"
        }
        if {$dest == ""} {
            log_error line $i empty destination
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            0 $startIndex "line $i empty destination"]
            return -code error "line $i empty destination"
        }

        ###check cassette_owner 
        set origCas [string index $orig 0]
        set destCas [string index $dest 0]
        if {[lsearch -exact $validCassetteList $origCas] < 0} {
            log_error line $i origin cassette $origCas not valid
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            0 $startIndex "line $i origin cassette {$origCas} not valid"]
            return -code error "line $i invalid origin"
        }
        if {[lsearch -exact $validCassetteList $destCas] < 0} {
            log_error line $i destination cassette $destCas not valid
            set robotMoveStatus [lreplace $robotMoveStatus 1 3 \
            0 $startIndex "line $i destination cassette {$destCas} not valid"]
            return -code error "line $i invalid destination"
        }

        if {[lsearch -exact $needCassetteList $origCas] < 0} {
            lappend needCassetteList $origCas
        }
        if {[lsearch -exact $needCassetteList $destCas] < 0} {
            lappend needCassetteList $destCas
        }
    }
    return [list $needMoveList $needCassetteList]
}
####if staff, return all cassettes
####if not staff, return cassette with no owner or owner==user
proc moveCrystal_getValidCassetteList { } {
    global gClientInfo
    variable cassette_owner

    set operationHandle [lindex [get_operation_info] 1]
    set clientId [expr int($operationHandle)]
    set isStaff $gClientInfo($clientId,staff)

    if {$isStaff} {
        return [list l m r]
    }

    set result ""
    set user [get_operation_user]

    set robotCassetteOwner [lrange $cassette_owner 1 end]

    foreach c {l m r} owner $robotCassetteOwner {
        if {$owner == "" || [lsearch -exact $owner $user] >= 0} {
            lappend result $c
        }
    }
    return $result
}
proc moveCrystal_generatePutbackItem { item } {
    set orig ""
    set dest ""
    ## no error check needed
    parseRobotMoveItem $item orig dest

    return "${dest}->${orig}"
}
