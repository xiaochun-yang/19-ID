### this file is shared between BluIce and DCSS script engine.
package provide DCSSpreadsheet 1.0

package require http
package require DCSImperson

#create default data
proc createDefaultSpreadsheet { } {
    global gDefaultSpreadsheetNo
    global gDefaultSpreadsheetLeft
    global gDefaultSpreadsheetMiddle
    global gDefaultSpreadsheetRight

    set gDefaultSpreadsheetNo {}
    set gDefaultSpreadsheetLeft {}
    set gDefaultSpreadsheetMiddle {}
    set gDefaultSpreadsheetRight {}
#yangx change from 8 to 16 below for 16 samples, letter extent from L to P.
#need to add right-2 in the future. we have 16 pucks
    foreach x {A B C D E F G H I J K L M N O P} {
        for {set y 1} {$y<=16} {incr y} {
            set port ${x}$y
            lappend gDefaultSpreadsheetNo [list $port c_$port 0 0 0 0 0 0 0]
            lappend gDefaultSpreadsheetLeft [list $port c_l$port 0 0 0 0 0 0 0]
            lappend gDefaultSpreadsheetMiddle [list $port c_m$port 0 0 0 0 0 0 0]
            lappend gDefaultSpreadsheetRight [list $port c_r$port 0 0 0 0 0 0 0]
        }
    }
}

###### sub directory
# must start with alphabeta or number
# only allow alphabeta, number, /, -, and _
proc TrimStringForSubDirectoryName { dir_name } {
    set num1 [regsub -all {^[^[:alnum:]]+}   $dir_name "" dir1]
    set num2 [regsub -all {/[^[:alnum:]]+}   $dir1     /  dir2]
    set num3 [regsub -all {[^[:alnum:]/_\-]} $dir2     _  dir3]

    if {$num1 > 0 || $num2 > 0 || $num3 > 0} {
        log_warning directory changed to $dir3
    }
    return $dir3
}

# root directory must start with / or ~
proc TrimStringForRootDirectoryName { dir_name } {
    ### take care of ~username
    set native_dir [file nativename $dir_name]
    if {[string index $native_dir 0] != "/"} {
        log_error "root directory must start with \"/\" or \"~\""
        return -code error "root directory must start with \"/\" or \"~\""
    }

    ######same as sub directory
    set sub_dir [string range $native_dir 1 end]
    set new_sub_dir [TrimStringForSubDirectoryName $sub_dir]
    return "/$new_sub_dir"
}
#ID must start with alpha number
proc TrimStringForCrystalID { id } {
    set num1 [regsub -all {^[^[:alnum:]]+}  $id  "" id1]
    set num2 [regsub -all {[^[:alnum:]_\-]} $id1 _  id2]
    if {$num1 > 0 || $num2 > 0} {
        log_error crystalID changed to $id2
    }
    return $id2
}

#map index in spreadsheet to index to robot_cassette
proc generateIndexMap { cassette_index port_index spreadsheetRef cassette_status} {
    upvar $spreadsheetRef data
    puts " generateIndexMap $cassette_index $port_index $spreadsheetRef $cassette_status"

    if {$cassette_status == "-"} {
        return {}
    }

    if {$cassette_index <= 0 || \
    $cassette_index > 3 || \
    $cassette_status == "0"} {
        return {}
    }
    set offset [expr ($cassette_index - 1) * 97 + 1]

    #### find out whether it is super-puck adaptor
    set isSuperPuckAdaptor 0
    set isMARCSC 0
    switch -exact -- $cassette_status {
        4 {
            set isMARCSC 1
        }
        3 {
            set isSuperPuckAdaptor 1
        }
        1 -
        2 {
            #set isSuperPuckAdaptor 0
        }
        u -
        default {
            ###maybe , check the row numbers.
            ### if row number >8 we assume it is
            set max_row 0
            foreach row $data {
                set port [lindex $row $port_index]
                set port_row [string range $port 1 end]
                if {[string is integer -strict $port_row] && \
                $port_row > $max_row} {
                    set max_row $port_row
                }
            }
            if {$max_row > 8} {
                set isSuperPuckAdaptor 1
            }
        }
    }

#yangx The formular " lappend resultList [expr $offset + 16 * $CIndex + $RIndex]"
#	used here for making index map is not corect. The correction is made as follows
#       193+128=322 97+64=161 getPortIndexInCassette function add 64 more on  middle
#       128 more on the right cassette. It should be get corrected in that function.
#       if {$index > 322 } {
#              set ind [expr $index - 128]
#       } elseif {$index > 161} {
#              set ind [expr $index - 64]
#       } else {
#                set ind $index
#       }


    set resultList {}
    if {$isSuperPuckAdaptor} {
        foreach row $data {
            set port [lindex $row $port_index]
            set port_column [string index $port 0]
            set port_row [string range $port 1 end]
            set CIndex [lsearch {A B C D E F G H I J K L M N O P} $port_column]
            set RIndex [lsearch {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16} \
            $port_row]
            if {$CIndex < 0 || $RIndex < 0} {
                lappend resultList -1
            } else {
		set ind [expr $offset + 16 * $CIndex + $RIndex]
		if {$ind > 322 } {
                	lappend resultList [expr $ind - 128]
      		} elseif {$ind > 161} {
              		lappend resultList [expr $ind - 64]
      		} else {
                	lappend resultList $ind
      		}
#yangx original       lappend resultList [expr $offset + 16 * $CIndex + $RIndex]
            }
        }
        return $resultList
    }
    if {$isMARCSC} {
        foreach row $data {
            set port [lindex $row $port_index]
            set port_column [string index $port 0]
            set port_row [string range $port 1 end]
            set CIndex [lsearch A $port_column]
            set RIndex [lsearch \
            {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19} $port_row]
            if {$CIndex < 0 || $RIndex < 0} {
                lappend resultList -1
            } else {
                lappend resultList [expr $offset + $RIndex]
            }
        }
        return $resultList
    }
    foreach row $data {
        set port [lindex $row $port_index]
        set port_column [string index $port 0]
        set port_row [string range $port 1 end]
        set CIndex [lsearch {A B C D E F G H I J K L M N O P} $port_column]
        set RIndex [lsearch {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16} $port_row]
        if {$CIndex < 0 || $RIndex < 0} {
            lappend resultList -1
        } else {
            lappend resultList [expr $offset + 16 * $CIndex + $RIndex]
        }
    }
    return $resultList
}

proc getSpreadsheetFromWeb { beamline_ username_ sessionID_ cassette_index_ cassette_list_ } {
    global gDefaultSpreadsheetNo
    global gDefaultSpreadsheetLeft
    global gDefaultSpreadsheetMiddle
    global gDefaultSpreadsheetRight

    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }

    #####default#####
    if {$cassette_index_ < 0 || $cassette_index_ > 3} {
        return $gDefaultSpreadsheetNo
    }
    set tag [lindex $cassette_list_ $cassette_index_]
    if {$tag == "undefined"} {
        switch -exact -- $cassette_index_ {
            1 {
                return $gDefaultSpreadsheetLeft
            }
            2 {
                return $gDefaultSpreadsheetMiddle
            }
            3 {
                return $gDefaultSpreadsheetRight
            }

            default -
            0 {
                return $gDefaultSpreadsheetNo
            }
        }
    }
    if {[string equal -length 5 $tag "file:"]} {
        set path [string range $tag 5 end]
        set first [string index $path 0]
        if {$first != "/" && $first != "~"} {
            log_error bad file path for spreadsheet CSV
            return {}
        }
        if {[catch {readCSVFileIntoList $path} data]} {
            log_error failed to load CSV file: $data
            return {}
        }
        ## fake header
        set data [linsert $data 0 csv 0 load]
        return $data
    }

    ####load from webserver
    set url [::config getCrystalDataUrl]
    append url "?forBeamLine=$beamline_"
    append url "&forUser=$username_"
    append url "&forCassetteIndex=$cassette_index_"
    append url "&accessID=$mySID"

    puts "url=[SIDFilter $url]"

    set result {}

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 12000]
    } err] } {
        log_error "getSpreadsheetFromWeb failed $err"
        puts "getSpreadsheetFromWeb failed $err"
        return {}
    }

    #check status
    variable $token
    upvar #0 $token state
    set status $state(status)
    set ncode [http::ncode $token]

    if { $status != "ok" || $ncode != 200 } {
        http::cleanup $token

        log_error "getSpreadsheetFromWeb failed $status != ok or $ncode != 200"
        puts "getSpreadsheetFromWeb failed $status != ok or $ncode != 200"
        return {}
    }
    #check body size
    if { $state(currentsize) <10 } {
        http::cleanup $token

        log_error "getSpreadsheetFromWeb failed contents too short"
        return {}
    }

    #check body content
    #set dd $state(body)
    set dd [string trim $state(body)]
    set code [http::code $token]
    http::cleanup $token

    if { [string range $dd 0 3]=="<Err" || \
         [string first "\{" [string range $dd 0 5] ]<0 } {

        log_error "getSpreadsheetFromWeb failed body=$dd"
        puts "getSpreadsheetFromWeb failed body=$dd"
        return {}
    }

    ##ok de-brace the data
    set data [lindex $dd 0]

    ######### remove all newlines
    set data [string map {\n { }} $data]

    return $data
}

proc clearSpreadsheet { beamline_ user_ sessionID_ } {
    unassignSil $beamline_ $user_ $sessionID_
}

proc loadSpreadSheet { userName_ sessionID_ cassetteIndex_ fileName_ sheetName_ } {
    puts "loadSpreadSheet $userName_ [SIDFilter $sessionID_] $cassetteIndex_ $fileName_ $sheetName_ "

    loadSIL $userName_ $sessionID_ $cassetteIndex_ $fileName_ $sheetName_
}

proc getSpreadsheetChangesSince { username_ sessionID_ SILID_ SILEventID_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    ####load from webserver
    set url [::config getCrystalChangesUrl]
    append url "?userName=$username_"
    append url "&silId=$SILID_"
    append url "&eventId=$SILEventID_"
    append url "&accessID=$mySID"

    puts "url=[SIDFilter $url]"

    set result {}

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "getSpreadsheetChangesSince failed $err"
        puts "getSpreadsheetChangesSince failed $err"
        return {}
    }

    #check status
    variable $token
    upvar #0 $token state
    set status $state(status)
    set ncode [http::ncode $token]

    if { $status != "ok" || $ncode != 200 } {
        http::cleanup $token

        log_error "getSpreadsheetChangesSince failed $status != ok or $ncode != 200"
        puts "getSpreadsheetChangesSince failed $status != ok or $ncode != 200"
        return {}
    }
    #check body size
    if { $state(currentsize) <10 } {
        http::cleanup $token

        log_error "getSpreadsheetChangesSince failed contents too short"
        return {}
    }

    #check body content
    #set dd $state(body)
    set dd [string trim $state(body)]
    #puts "response = $dd"
    set code [http::code $token]
    http::cleanup $token

    if { [string range $dd 0 3]=="<Err" || \
         [string first "\{" [string range $dd 0 5] ]<0 } {

        log_error "getSpreadsheetChangesSinces failed body=$dd"
        puts "getSpreadsheetChangesSinces failed body=$dd"
        return {}
    }

    ##ok de-brace the data
    set data [lindex $dd 0]
    set data [string map {\n { }} $data]
    return $data
}
proc editSpreadsheet { username_ sessionID_ SILID_ row_ data_ uniqueID_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getCrystalEditUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$row_"
    append url "&uniqueId=$uniqueID_"
    append url "&$data_"

    puts "url=[SIDFilter $url]"

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "editSpreadsheet failed $err"
        puts "editSpreadsheet failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc clearCrystalImages { username_ sessionID_ SILID_ row_ group_ uniqueID_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getCrystalClearImagesUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$row_"
    append url "&uniqueId=$uniqueID_"
    append url "&group=$group_"

    puts "clear url: [SIDFilter $url]"
    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "clearCrystalImages failed $err"
        puts "clearCrystalImages failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc clearCrystalResults { username_ sessionID_ SILID_ row_ uniqueID_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getCrystalClearResultsUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$row_"
    append url "&uniqueId=$uniqueID_"

    puts "clear results: [SIDFilter $url]"
    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "clearCrystalResults failed $err"
        puts "clearCrystalResults failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc resetSpreadsheet { username_ sessionID_ SILID_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getCrystalClearAllUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"

    puts "clear all url: [SIDFilter $url]"
    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "resetSpeadsheet failed $err"
        puts "resetSpeadsheet failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc addCrystalImage { username_ sessionID_ SILID_ row_ group_ filename_ jpegname_ uniqueID_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }

    #####format changed to: dir, name
    set dir [file dirname $filename_]
    set name [file tail $filename_]
    set jpg [file tail $jpegname_]

    set base_name [file root $name]
    set small  ${base_name}_small.jpg
    set medium ${base_name}_medium.jpg
    set large  ${base_name}_large.jpg
    
    set url [::config getCrystalAddImageUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$row_"
    append url "&uniqueId=$uniqueID_"
    append url "&group=$group_"
    append url "&dir=$dir"
    append url "&name=$name"
    append url "&small=$small"
    append url "&medium=$medium"
    append url "&large=$large"
    
    if {$jpg != ""} {
    append url "&jpeg=$jpg"
    }

    puts "add url: [SIDFilter $url]"

    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 20000]
    } err] } {
        log_error "addCrystalImage failed $err"
        puts "addCrystalImage failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc analyzeCrystalImage { username_ sessionID_ SILID_ row_ group_ filename_ beamline_  crystalId_ uniqueID_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getCrystalAnalyzeImageUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$row_"
    append url "&serialNumber=$uniqueID_"
    append url "&imageGroup=$group_"
    append url "&imagePath=$filename_"
    append url "&forBeamLine=$beamline_"
    append url "&crystalId=$crystalId_"

    puts "analyze url: [SIDFilter $url]"

    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 20000]
    } err] } {
        log_error "analyzeCrystalImage failed $err"
        puts "analyzeCrystalImage failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc analyzeCenterImage { username_ sessionID_ SILID_ row_ sN_ group_ filename_ beamline_ workDir_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getCenterAnalyzeImageUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$row_"
    append url "&serialNumber=$sN_"
    append url "&imageGroup=$group_"
    append url "&imagePath=$filename_"
    append url "&forBeamLine=$beamline_"
    append url "&workDir=$workDir_"
    append url "&crystalId=dummy"

    puts "center analyze url: [SIDFilter $url]"

    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 20000]
    } err] } {
        log_error "analyzeCenterImage failed $err"
        puts "analyzeCenterImage failed $err"
        return -code error $err
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc autoindexCrystal { username_ sessionID_ SILID_ row_ sN_ image1_ image2_ \
beamline_ uniqueID_  strategy_ strategyFileName_ \
{expType {}} {laueGroup {}} {unitCell {}} {workDir {}} \
{edge {}} {inflection {}} {peak {}} {remote {}} {numHeavyAtoms {}} {numResidues {}} \
{strategyMethod {}} {phiRange {}}
} {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getCrystalAutoindexUrl]
     if {[string first ? $url] > -1} {
        append url "&"
     } else {
        append url "?"
     }

    append url "userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$row_"
    append url "&serialNumber=$sN_"
    append url "&image1=$image1_"
    append url "&image2=$image2_"
    append url "&forBeamLine=$beamline_"
    append url "&uniqueID=$uniqueID_"
    append url "&strategy=$strategy_"
    append url "&dcsStrategyFile=$strategyFileName_"

    if {$laueGroup != ""} {
        append url "&laueGroup=$laueGroup"
    }
    if {$expType != ""} {
        append url "&expType=$expType"
    }
    if {$unitCell != ""} {
        append url "&unitCell=$unitCell"
    }
    if {$workDir != ""} {
        append url "&workDir=$workDir"
    }
    if {$edge != ""} {
        append url "&edge=$edge"
    }
    if {$inflection != ""} {
        append url "&inflection=$inflection"
    }
    if {$peak != ""} {
        append url "&peak=$peak"
    }
    if {$remote != ""} {
        append url "&remote=$remote"
    }

    if {$numHeavyAtoms != ""} {
        append url "&numHeavyAtoms=$numHeavyAtoms"
    }
    if {$numResidues != ""} {
        append url "&numResidues=$numResidues"
    }
    if {$strategyMethod != ""} {
        append url "&strategyMethod=$strategyMethod"
    }
    if {$phiRange != ""} {
        append url "&phiRange=$phiRange"
    }

    puts "autoindex url: [SIDFilter $url]"
    
    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "autoindexCrystal failed $err"
        puts "autoindexCrystal failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc loadSIL { userName_ sessionID_ cassetteIndex_ fileName_ sheetName_ } {

    #puts "loadSIL $userName_ $sessionID_ $cassetteIndex_ $fileName_ $sheetName_ "

    #######read the file first
    if [ catch {open $fileName_ r} fileHandle ] {
        #log_error File $fileName_ could not be opened.
        puts "File $fileName_ could not be opened."
        return -code error "failed to open file"
    }
    fconfigure $fileHandle -translation binary -encoding binary
    if [catch {read $fileHandle} fileContents] {
        #log_error read file failed
        puts "read file failed"
        close $fileHandle
        return -code error "failed to read file"
    }
    close $fileHandle

    set ll [string length $fileContents]
    puts "file contents length: $ll" 

    #########load the file##############3
    set boundary "BOUNDARYQqWwEeRrTtYyUuIiOoPpBOUNDARY"
    set CRLF "\r\n"
    set headers [list Content-Type "multipart/form-data; boundary=$boundary"]

    set contents {}
    append contents "--$boundary$CRLF"
    append contents "content-disposition: form-data; name=\"accessID\"$CRLF"
    append contents "$CRLF"
    append contents "$sessionID_$CRLF"

    append contents "--$boundary$CRLF"
    append contents "content-disposition: form-data; name=\"userName\"$CRLF"
    append contents "$CRLF"
    append contents "$userName_$CRLF"

    set beamline [::config getConfigRootName]
    append contents "--$boundary$CRLF"
    append contents "content-disposition: form-data; name=\"forBeamLine\"$CRLF"
    append contents "$CRLF"
    append contents "$beamline$CRLF"

    append contents "--$boundary$CRLF"
    append contents "content-disposition: form-data; name=\"forCassetteIndex\"$CRLF"
    append contents "$CRLF"
    append contents "$cassetteIndex_$CRLF"

    append contents "--$boundary$CRLF"
    append contents "content-disposition: form-data; name=\"forSheetName\"$CRLF"
    append contents "$CRLF"
    append contents "$sheetName_$CRLF"

    append contents "--$boundary$CRLF"
    append contents "content-disposition: form-data; name=\"PIN_Number\"$CRLF"
    append contents "$CRLF"
    append contents "UNKNOWN$CRLF"

    puts "contents without file: $contents"

    append contents "--$boundary$CRLF"
    append contents "content-disposition: form-data; name=\"fileName\"; filename=\"[file tail $fileName_]\"$CRLF"
    append contents "Content-Type: application/vnd.ms-excel$CRLF"
    append contents "$CRLF"
    append contents "$fileContents$CRLF"

    #end
    append contents "--${boundary}--$CRLF"
    append contents "$CRLF"

    puts "contents length [string length $contents]"

    set url [::config getUploadSILUrl]
    if {$url == ""} {
        return -code error "config getUploadSILUrl failed"
    }
    
    append url "?accessID=$sessionID_"
    append url "&userName=$userName_"
    append url "&beamLine=$beamline"
    append url "&forCassetteIndex=$cassetteIndex_"
    append url "&forSheetName=$sheetName_"
    append url "&PIN_Number=UNKNOWN"

    puts "url: [SIDFilter $url]"
    puts "headers: $headers"

    #puts "headers: $headers"
    set token [http::geturl $url -timeout 12000 -headers $headers -query $contents]
    checkHttpStatus $token
    set data [http::data $token]
    http::cleanup $token
    puts "fileload ok"
    puts "result: $data"

    log_note load $fileName_ to spreadsheet: $data
}
proc downloadSil { userName_ sessionID_  silID_ fileName_ } {
    puts "downloadSil: $fileName_"
    set url [::config getDownloadSILUrl]
    if {$url == ""} {
        log_error "downloadSil: empty url from config"
        return
    }
    append url "?accessID=$sessionID_"
    append url "&userName=$userName_"
    append url "&silId=$silID_"
    puts "url: [SIDFilter $url]"
    set token [http::geturl $url -timeout 12000]
    checkHttpStatus $token

    upvar #0 $token state
    array set meta $state(meta)
    set data [http::data $token]
    http::cleanup $token

    #puts "data length: [string length $data]"
    #puts "meta: [array get meta]"
    if {[info exists meta(Content-Type)] && \
    [string first "application/vnd.ms-excel" $meta(Content-Type)] >= 0} {
        puts "get an Excel file"

        if [ catch {open $fileName_ w} fileHandle ] {
            puts "File $fileName_ could not be opened."
            return -code error "failed to open file"
        }
        fconfigure $fileHandle -translation binary -encoding binary
        puts $fileHandle $data
        close $fileHandle
        log_note "spreadsheet downloaded to $fileName_"
    } else {
        log_error failed to get an excel file
        puts "download spreadsheet failed"
        puts "meta: [array get meta]"
        return -code error "failed to download"
    }
}
proc lockSil { userName_ sessionID_ cassetteIndex_ } {
    puts "lockSil: $userName_ [SIDFilter $sessionID_] $cassetteIndex_"
    set url [::config getLockSILUrl]
    if {$url == ""} {
        return
    }
    set beamline [::config getConfigRootName]
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    append url "?accessID=$mySID"
    append url "&userName=$userName_"
    append url "&forBeamLine=$beamline"
    append url "&forCassetteIndex=$cassetteIndex_"
    append url "&lock=true"
    puts "lock url: [SIDFilter $url]"

    set token [http::geturl $url -timeout 2000]
    checkHttpStatus $token
    http::cleanup $token
}
proc unlockAllSil { userName_ sessionID_ {forced_ 0}} {
    set url [::config getLockSILUrl]
    if {$url == ""} {
        return
    }
    set beamline [::config getConfigRootName]
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    append url "?accessID=$mySID"
    append url "&userName=$userName_"
    append url "&forBeamLine=$beamline"
    append url "&lock=false"
    if {$forced_} {
    append url "&forced=true"
    }
    puts "unlock url: [SIDFilter $url]"

    set token [http::geturl $url -timeout 20000]
    checkHttpStatus $token
    http::cleanup $token
}

proc unassignSil { beamline_ user_ sessionID_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getUnassignSILUrl]
    if {$url == ""} {
        log_error unassign spreadsheet failed: url not found at config file
        return
    }
    append url "?accessID=$mySID"
    append url "&userName=$user_"
    append url "&forBeamLine=$beamline_"
    puts "clear sil url: [SIDFilter $url]"
    set token [http::geturl $url -timeout 12000]
    checkHttpStatus $token
    http::cleanup $token
}
proc deleteSil { user_ sessionID_ silid_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getDeleteSILUrl]
    if {$url == ""} {
        log_error delete spreadsheet failed: url not found at config file
        return
    }
    append url "?accessID=$mySID"
    append url "&userName=$user_"
    append url "&silId=$silid_"
    puts "delete sil url: [SIDFilter $url]"
    set token [http::geturl $url -timeout 12000]
    checkHttpStatus $token
    http::cleanup $token
}
proc setSpreadsheetAttribute { username_ sessionID_ SILID_ data_ {key_ ""} } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getSaveCrystalAttributeUrl]
    if {$url == ""} {
        puts "skip setSpreadsheetAttribute url not found"
        return
    }
    append url "?userName=$username_"
    if {$key_ != ""} {
        append url "&key=$key_"
    }
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&$data_"

    puts "setSpreadsheetAttribute url: [SIDFilter $url]"

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "setSpreadsheetAttribute failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc getSpreadsheetProperty { username_ sessionID_ SILID_ propertyName_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getRetrieveCrystalPropertyUrl]
    if {$url == ""} {
        puts "skip. RetrieveCrystalProperty url not found"
        return
    }
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&propertyName=$propertyName_"

    puts "getSpreadsheetAttribute url: [SIDFilter $url]"

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "getSpreadsheetProperty failed $err"
    }
    checkHttpStatus $token
    set data [http::data $token]
    http::cleanup $token

    puts "DEBUG: property: $propertyName_: $data"

    return $data
}
proc setSpreadsheetProperty { username_ sessionID_ SILID_ propertyName_ valueList_ {key_ ""} } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getSaveCrystalPropertyUrl]
    if {$url == ""} {
        puts "skip. SaveCrystalProperty url not found"
        return
    }
    append url "?userName=$username_"
    if {$key_ != ""} {
        append url "&key=$key_"
    }
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&propertyName=$propertyName_"

    puts "getSpreadsheetAttribute url: [SIDFilter $url]"
    puts "the valueList: $valueList_"

    #call web
    if { [catch {
        set token [http::geturl $url \
        -timeout 2000 \
        -type "text/plain" \
        -query $valueList_ \
        ]
    } err] } {
        log_error "getSpreadsheetAttribute failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc createDefaultSil { username_ sessionID_ {extra {}}} {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getDefaultSILUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    if {$extra != ""} {
    append url $extra
    }
    puts "default sil url: [SIDFilter $url]"

    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 12000]
    } err] } {
        log_error "createDefaultSil failed $err"
        puts "createDefaultSil failed $err"
    }
    checkHttpStatus $token
    set result [http::data $token]
    http::cleanup $token

    set result [string trim $result]
    return [lindex $result 1]
}
proc getSilRowData { username_ sessionID_ sil_id_ row_  uniqueID_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getSILRowUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$sil_id_"
    append url "&row=$row_"
    append url "&uniqueId=$uniqueID_"

    #puts "getRowData url: [SIDFilter $url]"

    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 120000]
    } err] } {
        log_error "getSilRowData failed $err"
        puts "getSilRowData failed $err"
    }
    checkHttpStatus $token
    set result [http::data $token]
    http::cleanup $token

    set result [string trim $result]
    set result [string map {\n { }} $result]
    return $result
}
proc getNumSpotsData { username_ sessionID_ sil_id_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getStr "screening.getNumSpotsUrl"]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$sil_id_"

    #puts "getNumSpotsData url: [SIDFilter $url]"

    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 120000]
    } err] } {
        log_error "getNumSpotsData failed $err"
        puts "getNumSpotsData failed $err"
    }
    checkHttpStatus $token
    set result [http::data $token]
    http::cleanup $token

    set result [string trim $result]
    set result [string map {\n { }} $result]

    #puts "getnumSpots: raw: $result"

    if {[llength $result] == 1} {
        set result [lindex $result 0]
    }
    return $result
}
################strategy#####################
proc strategyParseError { contents } {
    if {[lindex $contents 0] == "error"} {
        return [lindex $contents 1]
    }
    return $contents
}
proc strategyParseSpaceGroup { contents type nameListREF runDefListREF warningListREF } {
    upvar $nameListREF nameList
    upvar $runDefListREF runDefList
    upvar $warningListREF warningList

    set nameList [list]
    set runDefList [list]
    set warningList [list]

    if {$type != "0" && $type != "1"} {
        if {[string first Anomalous $type] >= 0} {
            set type 0
        } else {
            set type 1
        }
    }
    set typeIndex [expr $type + 2]

    set newContents $contents
    foreach group_contents [lrange $newContents 1 end] {
        if {[lindex $group_contents 0] != "spaceGroup"} {
            log_error "no spaceGroup found:$group_contents"
            break
        }
        set group_name [join [lrange $group_contents 0 1]]
        set strategy_contents [lindex $group_contents $typeIndex]
        set run_contents [lindex $strategy_contents 2]
        set warning_contents [lindex $strategy_contents 3]
        set warning_contents [string map [list "\}\{" "\} \{"] $warning_contents]

        if {[lindex $run_contents 0] != "runDef"} {
            log_error "no runDef found:$run_contents"
            break
        }
        set runDef [lrange $run_contents 1 end]
        if {[lindex $warning_contents 0] == "warning"} {
            set warning [lrange $warning_contents 1 end]
        } else {
            set warning ""
        }
        lappend nameList $group_name
        lappend runDefList $runDef
        lappend warningList $warning
    }
}
proc strategyParseFirstGroup { contents } {
    set nameList ""
    set runDefList ""
    set warningList ""
    strategyParseSpaceGroup $contents 0 nameList runDefList warningList
    return [lindex $runDefList 0]
}

proc lockSilList { username_ sessionID_ silList_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getLockSILUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silList=$silList_"
    append url "&lock=true"
    append url "&lockType=full"

    puts "lockSilList url: [SIDFilter $url]"

    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 15000]
    } err] } {
        log_error "lockSilList failed $err"
        puts "lockSilList failed $err"
    }
    checkHttpStatus $token
    set result [http::data $token]
    http::cleanup $token
    puts "lockSilList returned: $result"
    return $result
}
proc unlockSilList { username_ sessionID_ silList_ key_ } {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getLockSILUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silList=$silList_"
    append url "&key=$key_"
    append url "&lock=false"

    puts "lockSilList url: [SIDFilter $url]"

    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 15000]
    } err] } {
        log_error "lockSilList failed $err"
        puts "lockSilList failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc silMoveCrystal { username_ sessionID_ key_ srcSil_ srcPort_ destSil_ destPort_ {clearMove 0}} {
    if {$srcSil_ == "" && $destSil_ == ""} {
        puts "silMoveCrystal both source and destination sils are empty"
        return
    }
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getMoveCrystalUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&key=$key_"
    if {$srcSil_ != ""} {
        append url "&srcSil=$srcSil_"
        append url "&srcPort=$srcPort_"
    }
    if {$destSil_ != ""} {
        append url "&destSil=$destSil_"
        append url "&destPort=$destPort_"
    }
    if {$clearMove} {
        append url "&clearMove=true"
    }

    puts "moveCrystal url: [SIDFilter $url]"

    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 5000]
    } err] } {
        log_error "silMoveCrystal failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}

proc autoindexForPrepareReOrient { username_ sessionID_ SILID_ row_ sN_ image1_ image2_ \
beamline_ uniqueID_ {pid_ 0} \
} {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getCrystalPrepareReOrientUrl]
     if {[string first ? $url] > -1} {
        append url "&"
     } else {
        append url "?"
     }

    append url "userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$row_"
    append url "&serialNumber=$sN_"
    append url "&image1=$image1_"
    append url "&image2=$image2_"
    append url "&forBeamLine=$beamline_"
    append url "&uniqueID=$uniqueID_"
    ##### this is the key: the analysis server will write the results to
    ##### to both position 0 and the mail row.
    append url "&repositionId=$pid_"

    puts "prepare reorient url: [SIDFilter $url]"
    
    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "autoindexForPrepareReOrient failed $err"
        puts "autoindexforPrepareReOrient failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc autoindexForReOrient { username_ sessionID_ SILID_ row_ sN_ image1_ image2_ \
beamline_ uniqueID_ \
} {
    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }
    set url [::config getCrystalReOrientUrl]
     if {[string first ? $url] > -1} {
        append url "&"
     } else {
        append url "?"
     }

    append url "userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$row_"
    append url "&serialNumber=$sN_"
    append url "&image1=$image1_"
    append url "&image2=$image2_"
    append url "&forBeamLine=$beamline_"
    append url "&uniqueID=$uniqueID_"

    puts "reorient url: [SIDFilter $url]"
    
    set result {}
    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error "autoindexForReOrient failed $err"
        puts "autoindexforReOrient failed $err"
    }
    checkHttpStatus $token
    http::cleanup $token
}
proc getRunDefinitionForQueue { username_ sessionID_ \
SILID_ rowIndex_ uniqueID_ runIndex_ } {

    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }

    set url [::config getQueueGetRunUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$rowIndex_"
    append url "&runIndex=$runIndex_"

    if {$uniqueID_ != ""} {
        append url "&uniqueId=$uniqueID_"
    }

    puts "url=[SIDFilter $url]"

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 20000]
    } err] } {
        log_error getRunDefinitionForQueue failed $err
        puts "getRunDefinitionForQueue failed $err"
        return -code error $err
    }
    checkHttpStatus $token
    set data [http::data $token]
    http::cleanup $token

    return $data
}
proc modifyRunDefinitionForQueue { username_ sessionID_ \
SILID_ rowIndex_ uniqueID_ runIndex_ data_ {silent_ 0}} {

    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }

    set url [::config getQueueSetRunUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$rowIndex_"
    if {$uniqueID_ != ""} {
        append url "&uniqueId=$uniqueID_"
    }
    append url "&runIndex=$runIndex_"
    append url "&$data_"
    append url "&silent=$silent_"

    puts "url=[SIDFilter $url]"

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error getRunDefinitionForQueue failed $err
        puts "modifyRunDefinitionForQueue failed $err"
        return -code error $err
    }
    checkHttpStatus $token
    set data [http::data $token]
    http::cleanup $token

    return $data
}
proc deleteRunDefinitionForQueue { username_ sessionID_ \
SILID_ rowIndex_ uniqueID_ runIndex_ } {

    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }

    set url [::config getQueueDeleteRunUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$rowIndex_"
    if {$uniqueID_ != ""} {
        append url "&uniqueId=$uniqueID_"
    }
    append url "&runIndex=$runIndex_"

    puts "url=[SIDFilter $url]"

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error getRunDefinitionForQueue failed $err
        puts "deleteRunDefinitionForQueue failed $err"
        return -code error $err
    }
    checkHttpStatus $token
    set data [http::data $token]
    http::cleanup $token

    return $data
}
proc addDefaultRepositionForQueue { username_ sessionID_ \
SILID_ rowIndex_ uniqueID_ data_ } {

    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }

    set url [::config getQueueAddDefaultRepositionUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$rowIndex_"
    if {$uniqueID_ != ""} {
        append url "&uniqueId=$uniqueID_"
    }
    append url "&$data_"

    puts "url=[SIDFilter $url]"

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error addDefaultRepositionForQueue failed $err
        puts "addDefaultRepositionForQueue failed $err"
        return -code error $err
    }
    checkHttpStatus $token
    set data [http::data $token]
    http::cleanup $token

    return $data
}
proc addNormalRepositionForQueue { username_ sessionID_ \
SILID_ rowIndex_ uniqueID_ data_ } {

    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }

    set url [::config getQueueAddNormalRepositionUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$rowIndex_"
    if {$uniqueID_ != ""} {
        append url "&uniqueId=$uniqueID_"
    }
    append url "&$data_"

    puts "url=[SIDFilter $url]"

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } err] } {
        log_error addNormalRepositionForQueue failed $err
        puts "addNormalRepositionForQueue failed $err"
        return -code error $err
    }
    checkHttpStatus $token
    set data [http::data $token]
    http::cleanup $token

    return $data
}
proc getPositionDefinitionForQueue { username_ sessionID_ \
SILID_ rowIndex_ uniqueID_ positionIndex_ } {

    if {[string equal -length 7 $sessionID_ "PRIVATE"]} {
        set mySID [string range $sessionID_ 7 end]
    } else {
        set mySID $sessionID_
    }

    set url [::config getQueueGetRepositionUrl]
    append url "?userName=$username_"
    append url "&accessID=$mySID"
    append url "&silId=$SILID_"
    append url "&row=$rowIndex_"
    append url "&repositionId=$positionIndex_"

    if {$uniqueID_ != ""} {
        append url "&uniqueId=$uniqueID_"
    }

    puts "url=[SIDFilter $url]"

    #call web
    if { [catch {
        set token [http::geturl $url -timeout 20000]
    } err] } {
        log_error getPositionDefinitionForQueue failed $err
        puts "getPositionDefinitionForQueue failed $err"
        return -code error $err
    }
    checkHttpStatus $token
    set data [http::data $token]
    http::cleanup $token

    return $data
}
########################################
createDefaultSpreadsheet
