proc videoSnapshot_initialize { } {
}
proc videoSnapshot_start { camera user sessionID path {draw_beam 0}} {
    switch -exact -- $camera {
        sample {
            set url [::config getSnapshotDirectUrl]
            if {$url == ""} {
                set url [::config getSnapshotUrl]
            }
            set origName sampleVideoOrig
        }
        inline {
            set url [::config getSnapshotDirectInlineUrl]
            set origName inlineVideoOrig
        }
        default {
            log_error only support sample and inline camera here.
            return -code error not_suppported
        }
    }
    if {$url == ""} {
        log_error not found url to get snapshot for camera $camera
        return -code error not_suppported
    }
    if {$user == "" || $user == "USER"} {
        set user [get_operation_user]
    }
    if {$sessionID == "" || $sessionID == "SID"} {
        set sessionID [get_operation_SID]
    } elseif {[string equal -length 7 $sessionID "PRIVATE"]} {
        set sessionID [string range $sessionID 7 end]
    }

    if {!$draw_beam} {
        if { [catch {
            set token [http::geturl $url -timeout 12000]
            checkHttpStatus $token
            set result [http::data $token]
            http::cleanup $token
            impWriteFile $user $sessionID $path $result
        } err] } {
            log_error video snapshot failed: $err
            return -code error $err
        }
        return
    }
    set cmd "java -Djava.awt.headless=true url $url"
    ### need to draw beam position and size.
    foreach {wMM hMM} [getCurrentBeamSize] break
    variable $origName
    set orig [set $origName]
    foreach {- - - - imgHmm imgWmm - - vert horz -} $orig break
    set w [expr abs(1.0 * $wMM / $imgWmm)]
    set h [expr abs(1.0 * $hMM / $imgHmm)]
    append cmd " -x $horz -y $vert -w $w -h $h"

    set urlTarget "http://[::config getImpDhsImpHost]"
    append urlTarget ":[::config getImpDhsImpPort]"
    append urlTarget "/writeFile?impUser=$user"
    append urlTarget "&impSessionID=$sessionID"
    append urlTarget "&impWriteBinary=true"
    append urlTarget "&impBackupExist=true"
    append urlTarget "&impAppend=false"
    append urlTarget "&impFilePath=$path"
    append cmd " -o $urlTarget"

    #puts "DEBUG cmd=$cmd"
    set mm [eval exec $cmd]
    puts "videoSnapshot result: $mm"
}
