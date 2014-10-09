package provide DCSImperson 1.0

package require http

proc checkHttpStatus { token } {
    set status [http::status $token]
    #puts "checkHttpStatus: status = $status"
    if {$status != "ok"} {
        puts "Web Server call returned: $status"
        puts "data: [http::data $token]"
        http::cleanup $token
        return -code error "web server call: $status"
    }
    #puts "checkHttpStatus: code = [http::code $token]"
    set ncode [http::ncode $token]
    if {![string is digit $ncode] || $ncode >= 400} {
        puts "data: [http::data $token]"
        set code [http::code $token]
        http::cleanup $token
        return -code error $code
    }
}

proc impDirectoryWritable { username_ sessionId_ dir_ \
{prefix_ {}} {ext_ {}} } {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }

    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/writableDirectory?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impDirectory=[file nativename $dir_]"
puts "yangxxx url=$url"

    ### also get next file counter if exists
    if {$prefix_ != ""} {
        append url "&impFilePrefix=$prefix_"
    }
    if {$ext_ != ""} {
        append url "&impFileExtension=$ext_"
    }

    set token [http::geturl $url -timeout 8000]
    checkHttpStatus $token
    set result [http::data $token]
    upvar #0 $token state
    array set meta $state(meta)
    http::cleanup $token

    puts "writable result: $result"
    if {![info exist meta(impFileExists)]} {
        log_note $dir_ created
        ### no need to parse impFileCounter
        return 1
    }

    if {[info exist meta(impFileCounter)]} {
        return $meta(impFileCounter)
    } else {
        ###
        return 1
    }
}

proc impCreateDirectory { username_ sessionId_ dir_ } {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }

    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/createDirectory?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impDirectory=[file nativename $dir_]"
    append url "&impCreateParents=true"
    append url "&impFileMode=0700"

    #puts "create dir url=[SIDFilter $url]"
    set token [http::geturl $url -timeout 8000]
    checkHttpStatus $token
    http::cleanup $token

    #puts "create dir OK"
}

proc impCopyFile { username_ sessionId_ source_ target_ {mode_ ""} } {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }
    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/copyFile?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impOldFilePath=[file nativename $source_]"
    append url "&impNewFilePath=[file nativename $target_]"
    if {$mode_ != ""} {
        append url "&impFileMode=$mode_"
    }

    #puts "copy file url=[SIDFilter $url]"
    set token [http::geturl $url -timeout 8000]
    checkHttpStatus $token
    http::cleanup $token
    #puts "copy file OK"
}

proc impWriteFile { username_ sessionId_ fullPath_ contents_ {binary_ true}} {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }
    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/writeFile?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impFilePath=[file nativename $fullPath_]"
    append url "&impWriteBinary=$binary_"
    append url "&impAppend=false"

    #puts "write file url=[SIDFilter $url]"

    set token [http::geturl $url \
    -type "application/octet-stream" \
    -query $contents_ \
    -timeout 8000]

    checkHttpStatus $token
    http::cleanup $token

    #puts "write file OK"
}

proc impWriteFileWithBackup { username_ sessionId_ fullPath_ contents_ {binary_ true}} {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }
    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/writeFile?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impFilePath=[file nativename $fullPath_]"
    append url "&impWriteBinary=$binary_"
    append url "&impAppend=false"
    append url "&impBackupExist=true"

    #puts "write file url=[SIDFilter $url]"

    set token [http::geturl $url \
    -type "application/octet-stream" \
    -query $contents_ \
    -timeout 8000]

    checkHttpStatus $token
    upvar #0 $token state
    array set meta $state(meta)
    http::cleanup $token

    if {[info exists meta(impWarningMsg)]} {
        log_warning $meta(impWarningMsg)
    }
    #puts "write file OK"
}
proc impGetFileType { username_ sessionId_ fullPath_  } {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }
    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    #append url "http://blcpu4.slac.stanford.edu:61001"

    append url "/getFileStatus?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impFilePath=[file nativename $fullPath_]"

    #puts "get file type url=[SIDFilter $url]"

    set token [http::geturl $url -timeout 8000]
    upvar #0 $token state
    checkHttpStatus $token
    ####save result
    array set meta $state(meta)
    http::cleanup $token

    set result $meta(impFileType)

    #puts "get file type OK {$result}"
    
    return $result
}

#return "[exist] [read] [write] [execute]"
proc impGetFilePermissions { username_ sessionId_ fullPath_  } {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }
    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    #append url "http://blcpu4.slac.stanford.edu:61001"

    append url "/getFilePermissions?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impFilePath=[file nativename $fullPath_]"

    set token [http::geturl $url -timeout 8000]
    upvar #0 $token state
    checkHttpStatus $token
    ####save result
    array set meta $state(meta)
    http::cleanup $token

    if {![info exists meta(impFileExists)]} {
        return {}
    }

    if {!$meta(impFileExists)} {
        return {}
    }
    set result [list exist]
    if {$meta(impReadPermission)} {
        lappend result read
    }
    if {$meta(impWritePermission)} {
        lappend result write
    }
    if {$meta(impExecutePermission)} {
        lappend result execute
    }
    return $result
}

proc impAppendTextFile { username_ sessionId_ fullPath_ contents_ } {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }
    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/writeFile?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impFilePath=[file nativename $fullPath_]"
    append url "&impWriteBinary=false"
    append url "&impAppend=true"
    append url "&impCreateParents=true"

    ##until impersonal server fixes its bug about content-length,
    #we will use chunked
    #lappend headers Transfer-Encoding chunked

    #set ll [string length $contents_]
    #set body [format "%x\n" $ll]
    #append body $contents_
    #append body "\n0\n"

    #set token [http::geturl $url \
    #-headers $headers \
    #-type "text/plain" \
    #-query $body \
    #-timeout 8000]

    set token [http::geturl $url \
    -type "text/plain" \
    -query $contents_ \
    -timeout 8000]

    checkHttpStatus $token
    http::cleanup $token
}

proc impListDirectory { username_ sessionId_ dir_ pattern_ } {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }

    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/listDirectory?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impDirectory=[file nativename $dir_]"
    append url "&impFileFilter=$pattern_"
    append url "&impFileType=file"
    append url "&impShowDetails=false"

    #puts "url=[SIDFilter $url]"

    set token [http::geturl $url -timeout 8000]
    checkHttpStatus $token

    set result [http::data $token]
    http::cleanup $token

    return $result
}

proc impGetNextFileIndex { username_ sessionId_ dir_ prefix_ ext_ } {
    puts "impGetNextFileIndex $username_ [SIDFilter $sessionId_] $dir_ $prefix_ $ext_"

    set pattern ${prefix_}*

    set ll_prefix [string length $prefix_]
    set ll_ext [string length $ext_]

    if {$ll_ext} {
        append pattern .$ext_

        #skip "." in loop scan
        incr ll_ext
    }
        
    set fileList [impListDirectory $username_ $sessionId_ $dir_ $pattern]
    set fileList [split $fileList \n]
    if {[lindex $fileList end] == ""} {
        set fileList [lreplace $fileList end end]
    }
    puts "fileList $fileList"


    #init counter: it will be +1 at the end of loop
    set counter 0
    foreach fileName $fileList {
        set ll_filename [string length $fileName]

        #fileName is like test_0_1.jpg test_90_9999.jpg
        ###### strict check #######
        # the fileName must start with pattern and end with extension
        if {$ll_prefix} {
            set index_prefix [string first $prefix_ $fileName]
        } else {
            set index_prefix 0
        }
        if {$index_prefix < 0} {
            puts "skip a bad fileName $fileName no prefix $prefix_"
            continue
        }
        set index_ext [expr $ll_filename - $ll_ext]
        if {$ll_ext && ([string first .$ext_ $fileName] != $index_ext)} {
            puts "skip a bad fileName $fileName from ext $ext_"
            continue
        }
            
        #extract the counter part
        set fNoExt [string range $fileName [expr $index_prefix + $ll_prefix] end-$ll_ext]
        puts "counter part: $fNoExt"
        set ll [string length $fNoExt]
        for {set i 0} {$i < $ll} {incr i} {
            set strIndex [expr "$ll - $i -1"]
            set letter [string index $fNoExt $strIndex]
            if {[lsearch {0 1 2 3 4 5 6 7 8 9} $letter] < 0} {
                break
            }
        }
        if {$i == 0} {
            continue
        }
    
        set c [string range $fNoExt end-[expr $i - 1] end]
        puts "this counter=$c"
    
        set tmp_counter 0
        scan $c "%d" tmp_counter
        
        if { $tmp_counter>$counter } {
            set counter $tmp_counter
        }
    }
    incr counter

    puts "final counter: $counter"

    return $counter
}

#### file pattern "prefix_iii.scan" to "prefix_nnn.scan"
proc impScanFilesNotExist { username_ sessionId_ dir_ prefix_ ext_ \
init_counter_ num_file_ } {
    puts "impScanFilesNotExist [SIDFilter $sessionId_] {$dir_} {$prefix_} {$ext_}"
    puts "init counter: $init_counter_ num file: $num_file_"

    set pattern ${prefix_}*

    set ll_prefix [string length $prefix_]
    set ll_ext [string length $ext_]

    if {$ll_ext} {
        append pattern .$ext_

        #skip "." in loop scan: include "." in the extension
        incr ll_ext
    }
        
    if {[catch {
        set fileList [impListDirectory $username_ $sessionId_ $dir_ $pattern]
    } errMsg]} {
        if {[string first ENOENT $errMsg]} {
            return
        }
    }
    set fileList [split $fileList \n]
    if {[lindex $fileList end] == ""} {
        set fileList [lreplace $fileList end end]
    }
    #puts "fileList $fileList"

    if {[llength $fileList] == 0} return

    set first $init_counter_
    set last [expr $first + $num_file_ - 1]

    set foundAnyFile 0
    foreach fileName $fileList {
        set ll_filename [string length $fileName]

        #fileName is like test_0_1.jpg test_90_9999.jpg
        ###### strict check #######
        # the fileName must start with pattern and end with extension
        if {$ll_prefix} {
            set index_prefix [string first $prefix_ $fileName]
        } else {
            set index_prefix 0
        }
        if {$index_prefix < 0} {
            puts "skip a bad fileName $fileName no prefix $prefix_"
            continue
        }
        set index_ext [expr $ll_filename - $ll_ext]
        if {$ll_ext && ([string first .$ext_ $fileName] != $index_ext)} {
            puts "skip a bad fileName $fileName from ext $ext_"
            continue
        }
            
        #extract the counter part
        set fNoExt [string range $fileName [expr $index_prefix + $ll_prefix] end-$ll_ext]
        #puts "counter part: $fNoExt"
        set ll [string length $fNoExt]
        for {set i 0} {$i < $ll} {incr i} {
            set strIndex [expr "$ll - $i -1"]
            set letter [string index $fNoExt $strIndex]
            if {[lsearch {0 1 2 3 4 5 6 7 8 9} $letter] < 0} {
                break
            }
        }
        if {$i == 0} {
            continue
        }
    
        set c [string range $fNoExt end-[expr $i - 1] end]
        #puts "this counter=$c"
    
        set tmp_counter 0
        scan $c "%d" tmp_counter
        
        if { $tmp_counter >= $first && $tmp_counter <= $last } {
            set foundAnyFile 1
            log_error file $fileName already exists in $dir_
        }
    }
    if {$foundAnyFile} {
        return -code error "file already exists"
    }
}
proc impReadFile { username_ sessionId_ filename_ } {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }

    ###remove after impersonal server support relative path
    set firstChar [string index $filename_ 0]
    if {$firstChar != "/" && $firstChar != "~"} {
        set fullPath "~/$filename_"
    } else {
        set fullPath $filename_
    }

    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/readFile?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impFilePath=[file nativename $fullPath]"

    puts "url=[SIDFilter $url]"

    set token [http::geturl $url -timeout 8000]
    checkHttpStatus $token

    set result [http::data $token]
    http::cleanup $token

    return $result
}

proc impReadTextFile { username_ sessionId_ filename_ {call_back ""} } {
    global gImpReadTextFile_lineCallback

    if {$call_back == ""} {
        return [impReadFile $username_ $sessionId_ $filename_]
    }

    set gImpReadTextFile_lineCallback $call_back
    set handler impReadTextFile_handlerCallback

    #### we have call_back
    # it will be called with each line

    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }

    ###remove after impersonal server support relative path
    set firstChar [string index $filename_ 0]
    if {$firstChar != "/" && $firstChar != "~"} {
        set fullPath "~/$filename_"
    } else {
        set fullPath $filename_
    }

    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/readFile?impUser=$username_"
    append url "&impSessionID=$mySID"
    append url "&impFilePath=[file nativename $fullPath]"

    puts "url=[SIDFilter $url]"

    set token [http::geturl $url \
    -handler $handler \
    -timeout 8000]
    checkHttpStatus $token
    http::cleanup $token

    set gImpReadTextFile_lineCallback ""
}

proc impReadTextFile_handlerCallback { socket token } {
    global gImpReadTextFile_lineCallback

    set n [gets $socket one_line]

    if {$n < 0} {
        return $n
    }

    #puts "$one_line"
    if {$gImpReadTextFile_lineCallback != ""} {
        set command [split $gImpReadTextFile_lineCallback]
        lappend command $one_line
        eval $command
    }

    return $n
}


proc impRunScript { username_ sessionId_ cmd_ {shell_ {}} } {

    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }

	if {$cmd_ == "" } {
        return -code error "missing cmdfile already exists"
    }		

    set cmd [string map {\  %20 / %2F } $cmd_]

    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/runScript?impUser=$username_"
    append url "&impSessionID=$mySID"
    if {$shell_ != "" } {
        append url "&impShell=$shell_"
    }
	append url "&impCommandLine=$cmd"
    append url "&impUseFork=false"

    set token [http::geturl $url -timeout 8000]
    checkHttpStatus $token
    set result [http::data $token]
    upvar #0 $token state
    array set meta $state(meta)
    http::cleanup $token

    return $result

}

proc impCopyMultipleFiles { username_ sessionId_ list_ {mode_ ""} } {
    if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
        set mySID [string range $sessionId_ 7 end]
    } else {
        set mySID $sessionId_
    }
    set url "http://[::config getImpDhsImpHost]"
    append url ":[::config getImpDhsImpPort]"
    append url "/copyFile?impOldFilePath=MULTIPLE_IN_BODY"
    append url "&impUser=$username_"
    append url "&impSessionID=$mySID"
    if {$mode_ != ""} {
        append url "&impFileMode=$mode_"
    }

    set body ""
    foreach {src tgt} $list_ {
        append body "impOldFilePath=$src impNewFilePath=$tgt\n"
    }

    set token [http::geturl $url \
    -type "text/plain" \
    -query $body \
    -timeout 8000]

    checkHttpStatus $token
    http::cleanup $token
    #puts "copy file OK"
}

