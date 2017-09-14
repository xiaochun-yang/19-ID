
package require http

class DCS::ImpersonWriteFiles {
    public variable host
    public variable port
    public variable timeoutMs 8000


    private variable _lastSession ""
    private variable _socket ""
    private variable _fileDoneCallback
    private variable _fileWarnCallback
    private variable _fileWriteCallback
    private variable _errorCallback
    #private variable _singleFileGuard 0
    private variable _username
    private variable _contents
    private variable _fullPath
    private variable _sessionId
    private variable _startTime

    private variable _blank

    public method afterPropertiesSet {} {}


    constructor {} {
        after 2000 [list $this watchdog]
        array set _fileDoneCallback {}
        array set _fileWarnCallback {}
    }

    destructor {
        if { $_socket != "" } {
            close $_socket
        }
    }

    private method trimPrivate { sessionId_ } {
        if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
            return [string range $sessionId_ 7 end]
        }
        return $sessionId_
    }


    public method writeFiles { username_ sessionId_ fullPath_ contents_ fileWriteCallback_ fileDoneCallback_ errorCallback_ warnCallback_ } {
        #incr _singleFileGuard
        #if { $_singleFileGuard > 1 } {
        #    return -code error "tried to start more than one file copy"
        #}
        set _startTime [clock seconds]

        set _username $username_
        set _fullPath [file dirname $fullPath_]/[file tail $fullPath_]
        set _contents $contents_
        set _sessionId $sessionId_
        set _fileDoneCallback($_fullPath) $fileDoneCallback_
        set _fileWarnCallback($_fullPath) $warnCallback_
        set _fileWriteCallback $fileWriteCallback_
        set _errorCallback $errorCallback_

        if { $_lastSession != $sessionId_ || $_socket=="" } {
            puts "new sessionId"
            setupNewStream 
            return
        }
    
        fileevent $_socket writable [list $this writeContentsBg]
        fileevent $_socket readable [list $this readResponseBg]
        #fileevent $_socket readable {}
        #fileevent $_socket readable [list $this readResponseBg]
    }

    private method setupNewStream { } {
        if { $_socket != "" } {
            close $_socket
            set _socket ""
        }

        set _socket [socket -async $host $port]
        fileevent $_socket writable [list $this sendHeaderBg]
    }

    public method sendHeaderBg {} {
        set connectError [fconfigure $_socket -error]
        if { $connectError != "" } {
            #puts "error: [gets $_socket]"
            handleError "connectError error:  $connectError"
            return
        }  

        if {[catch {
            sendHeader
        } errorMsg ]} {
            #puts "error: [gets $_socket]"
            handleError "writeContents error:  $errorMsg"
        }
    }

    private method sendHeader {} {
        puts "got a new socket"
        fconfigure $_socket -translation binary -blocking false

        set mySID [trimPrivate $_sessionId]
        
        set url "/writeFiles?impUser=$_username"
        append url "&impSessionID=$mySID"
        append url "&impWriteBinary=true"
        append url "&impBackupExist=true"

        #set _socket [open out.txt w]
        puts -nonewline $_socket "POST $url HTTP/1.1\n"
        puts -nonewline $_socket "Host: $host:$port\n"
        puts -nonewline $_socket "Content-Type: binary/octet-stream\n"
        puts -nonewline $_socket "Connection: close\n"
        puts -nonewline $_socket "\n"
        #close $_socket
        #exit

        flush $_socket
        #puts "response: [read $_socket]"
        puts "sent header"
        set _lastSession $_sessionId
        fileevent $_socket writable [list $this writeContentsBg]
        #fileevent $_socket readable [list $this readResponseBg]
    }

    public method writeContentsBg {} {
        if {[catch {
            writeContents
        } errorMsg ]} {
            handleError "writeContents error:  $errorMsg"
        }

    }

    private method writeContents {} {
        #puts "enter write"
        set _blank 0
        set size [string length $_contents]
        #puts "SIZE $size"
        puts -nonewline $_socket "[file nativename $_fullPath]\n"
        puts -nonewline $_socket "${size}\n"
        puts -nonewline $_socket "$_contents\n"
        flush $_socket
        fileevent $_socket writable {}
        fileevent $_socket readable [list $this readResponseBg]
        after idle $_fileWriteCallback
    }

    public method readResponseBg {} {
        if {[catch {
            readResponse
        } errorMsg ]} {
            handleError "readResponse error:  $errorMsg"
        }
    }

    public method tryAgain {} {
        puts tryAgain
        fileevent $_socket readable [list $this readResponseBg] 
    }

    private method readResponse {} {
        #puts "RESPONSE gets"
        set cnt [gets $_socket response]

        if {$cnt == "-1"} {
            #fileevent $_socket readable {} 
            #after idle [$this tryAgain]
            puts "RESPONSE empty"
            #set response "[read $_socket 1]"
        }

        if {$response == "" } {
            incr _blank
            #fconfigure $_socket -blocking true
            #gets $_socket response
            #fconfigure $_socket -blocking false
        }

        set cnt 0

            #while {$response == "" && $cnt <10000 } {
            #    gets $_socket response
            #    if {$response == "" } {incr _blank}
                #after 100
            #    puts "read"

            #    puts -nonewline $_socket "x\n"
            #    puts $cnt

            #    incr cnt
            #}
        

        puts "RESPONSE ${response}"
        #foreach a [after info] { puts "$a : [after info $a]" }
        
        if { [scan $response "OK %s" filename] == 1 } {
            puts "$filename"
            after idle $_fileDoneCallback($filename)
            array unset _fileDoneCallback $filename
            array unset _fileWarnCallback $filename
            return
        }


        if { [scan $response "impWarningMsg=movedExistingFile %s to %s" filename backupDir] == 2 } {
            lappend _fileWarnCallback($filename) $backupDir
            after idle $_fileWarnCallback($filename)
            return
        }



        if { [scan $response "HTTP/1.1 %d" code] == 1 } {
            if { $code != 200 } {
                puts "ERROR: $code"
                handleError "http return code $code"
                return
            }
        }

    }

    public method watchdog {} {
        if {$_socket != "" } {
            #puts "watchdog [fileevent $_socket readable]"
            #puts "watchdog"
        }
        #if { $_singleFileGuard > 0 } {
        #    if { [expr [clock seconds] - $_startTime] > 30 } {
        #        puts "TIMEOUT"
        #        close $_socket
        #        set _socket ""
        #        set _singleFileGuard 0
        #        after idle $_errorCallback
        #    }
        #}
        after 1000 [list $this watchdog]
    }

    private method handleError { msg } {
        puts $msg

        close $_socket
        set _socket ""
        set _singleFileGuard 0
        after idle $_errorCallback
    }


}






class DCS::Imperson {

    public variable host
    public variable port
    public variable timeoutMs 8000

    public method afterPropertiesSet {} {}

    private method checkHttpStatus { token } {
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

    private method trimPrivate { sessionId_ } {
        if {[string equal -length 7 $sessionId_ "PRIVATE"]} {
            return [string range $sessionId_ 7 end]
        }
        return $sessionId_
    }


    public method directoryWritable { username_ sessionId_ dir_ {prefix_ {}} {ext_ {}} } {

        set url "http://$host:$port"
        append url "/writableDirectory?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impDirectory=[file nativename $dir_]"

        ### also get next file counter if exists
        if {$prefix_ != ""} {
            append url "&impFilePrefix=$prefix_"
        }
        if {$ext_ != ""} {
            append url "&impFileExtension=$ext_"
        }

        set token [http::geturl $url -timeout $timeoutMs]
        checkHttpStatus $token
        set result [http::data $token]
        upvar #0 $token state
        array set meta $state(meta)
        http::cleanup $token

        #puts "writable result: $result"
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

    public method createDirectory { username_ sessionId_ dir_ } {
        set mySID [trimPrivate $sessionId_]

        set url "http://$host:$port"
        append url "/createDirectory?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impDirectory=[file nativename $dir_]"
        append url "&impCreateParents=true"
        append url "&impFileMode=0700"

        #puts "create dir url=[SIDFilter $url]"
        set token [http::geturl $url -timeout $timeoutMs]
        checkHttpStatus $token
        http::cleanup $token

        #puts "create dir OK"
    }

    public method copyFile { username_ sessionId_ source_ target_ {mode_ ""} } {
        set mySID [trimPrivate $sessionId_]
        set url "http://$host:$port"
        append url "/copyFile?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impOldFilePath=[file nativename $source_]"
        append url "&impNewFilePath=[file nativename $target_]"
        if {$mode_ != ""} {
            append url "&impFileMode=$mode_"
        }

        #puts "copy file url=[SIDFilter $url]"
        set token [http::geturl $url -timeout $timeoutMs]
        checkHttpStatus $token
        http::cleanup $token
        #puts "copy file OK"
    }

    public method writeFile { username_ sessionId_ fullPath_ contents_ {binary_ true}} {
        set mySID [trimPrivate $sessionId_]

        set url "http://$host:$port"
        append url "/writeFile?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impFilePath=[file nativename $fullPath_]"
        append url "&impWriteBinary=$binary_"
        append url "&impAppend=false"

        #puts "write file url=[SIDFilter $url]"

        set token [http::geturl $url \
            -type "application/octet-stream" \
        -query $contents_ \
        -timeout $timeoutMs]

        checkHttpStatus $token
        http::cleanup $token

        #puts "write file OK"
    }

    public method writeFileWithBackup { username_ sessionId fullPath_ contents_ {binary_ true}} {
        puts writeFileWithBackup
        set mySID [trimPrivate $sessionId]
        puts $mySID

        set url "http://$host:$port"
        append url "/writeFile?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impFilePath=[file nativename $fullPath_]"
        append url "&impWriteBinary=$binary_"
        append url "&impAppend=false"
        append url "&impBackupExist=true"

        puts "write file url=[SIDFilter $url]"

        set token [http::geturl $url \
            -type "application/octet-stream" \
            -query $contents_ \
            -timeout $timeoutMs]

        checkHttpStatus $token
        upvar #0 $token state
        array set meta $state(meta)
        http::cleanup $token

        if {[info exists meta(impWarningMsg)]} {
            log_warning $meta(impWarningMsg)
        }
        #puts "write file OK"
    }

    public method getFileType { username_ sessionId_ fullPath_  } {
        set mySID [trimPrivate $sessionId_]
        set url "http://$host:$port"
        append url "/getFileStatus?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impFilePath=[file nativename $fullPath_]"

        #puts "get file type url=[SIDFilter $url]"

        set token [http::geturl $url -timeout $timeoutMs]
        upvar #0 $token state
        checkHttpStatus $token
        ####save result
        array set meta $state(meta)
        http::cleanup $token

        set result $meta(impFileType)

        #puts "get file type OK {$result}"
    
        return $result
    }

    public method getFilePermissions { username_ sessionId_ fullPath_  } {
        set mySID [trimPrivate $sessionId_]

        set url "http://$host:$port"
        append url "/getFilePermissions?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impFilePath=[file nativename $fullPath_]"

        set token [http::geturl $url -timeout $timeoutMs]
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

    public method appendTextFile { username_ sessionId_ fullPath_ contents_ } {
        set mySID [trimPrivate $sessionId_]

        set url "http://$host:$port"
        append url "/writeFile?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impFilePath=[file nativename $fullPath_]"
        append url "&impWriteBinary=false"
        append url "&impAppend=true"

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
        #-timeout $timeoutMs]

        set token [http::geturl $url \
            -type "text/plain" \
            -query $contents_ \
        -timeout $timeoutMs]

        checkHttpStatus $token
        http::cleanup $token
    }


    public method listDirectory { username_ sessionId_ dir_ pattern_ } {
        set mySID [trimPrivate $sessionId_]

        set url "http://$host:$port"
        append url "/listDirectory?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impDirectory=[file nativename $dir_]"
        append url "&impFileFilter=$pattern_"
        append url "&impFileType=file"
        append url "&impShowDetails=false"

        #puts "url=[SIDFilter $url]"

        set token [http::geturl $url -timeout $timeoutMs]
        checkHttpStatus $token

        set result [http::data $token]
        http::cleanup $token

        return $result
    }

    public method readFile { username_ sessionId_ filename_ } {
        set mySID [trimPrivate $sessionId_]

        ###remove after impersonal server support relative path
        set firstChar [string index $filename_ 0]
        if {$firstChar != "/" && $firstChar != "~"} {
            set fullPath "~/$filename_"
        } else {
            set fullPath $filename_
        }

        set url "http://$host:$port"
        append url "/readFile?impUser=$username_"
        append url "&impSessionID=$mySID"
        append url "&impFilePath=[file nativename $fullPath]"

        puts "url=[SIDFilter $url]"

        set token [http::geturl $url -timeout $timeoutMs]
        checkHttpStatus $token

        set result [http::data $token]
        http::cleanup $token

        return $result
    }

    public method runScript { username_ sessionId_ cmd_ {shell_ {}} } {
        set mySID [trimPrivate $sessionId_]

	    if {$cmd_ == "" } {
            return -code error "missing cmdfile already exists"
        }		

        set cmd [string map {\  %20 / %2F } $cmd_]

        set url "http://$host:$port"
        append url "/runScript?impUser=$username_"
        append url "&impSessionID=$mySID"
        if {$shell_ != "" } {
            append url "&impShell=$shell_"
        }
	    append url "&impCommandLine=$cmd"
        append url "&impUseFork=false"

        set token [http::geturl $url -timeout $timeoutMs]
        checkHttpStatus $token
        set result [http::data $token]
        upvar #0 $token state
        array set meta $state(meta)
        http::cleanup $token
        return $result
    }
}





