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

package provide DCSUtil 1.0

package require csv

class DCS::UniqueName {}
proc DCS::getUniqueName {} { return [string range a[::DCS::UniqueName \#auto] 0 end] }

########################
# this is a copy of what the makefile does to find out MACHINE type
# it is used to create the right sub-directory name

proc getMachineType { } {
    global env

    if {[info exists env(OS)]} {
        return nt
    } else {
        set os [exec uname]
        switch -exact -- $os {
            OSF1   { return decunix }
            IRIX64 { return irix }
            Linux {
                set mach [exec uname -m]
                switch -exact -- $mach {
                    i686 { return linux }
                    x86_64 { return linux64 }
                    ia64 { return ia64 }
                }
            }
        }
    }
    ### reach here, unknown machine
    puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    puts "Unknow MACHINE, please edit bluice.tcl to find right MACHINE!!"
    puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

    return ""
}


proc get_next_counter { directory prefix ext {types f}} {
    #make sure the directory exists
    if {![file exists $directory]} {
        file mkdir $directory
    }
    if {![file isdirectory $directory]} {
        log_error "$directory is not a directory"
        return -code error failed
    }
    
    #create pattern
    set pattern "${prefix}*"
    if {$ext != "" } {
        set pattern "${prefix}*.${ext}"
    }
    #get file list matches the pattern
    set fileList [glob -nocomplain -types $types \
    -directory $directory -- $pattern]

    #find the max counter
    set ll_ext [string length $ext]
    if {$ll_ext} {
        #skip the "." also
        incr ll_ext
    }
    set counter 0
    foreach fileName $fileList {
        #fileName is like test_0_1.jpg test_90_9999.jpg
        #extract the counter part
        if {$ll_ext} {
            set fNoExt [string range $fileName 0 end-$ll_ext]
        } else {
            set fNoExt $fileName
        }
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
        #puts "$c"
    
        set tmp_counter 0
        scan $c "%d" tmp_counter
        
        if { $tmp_counter>$counter } {
            set counter $tmp_counter
        }
    }
    incr counter

    return $counter
}

proc time_stamp {} {
	clock format [clock seconds] -format "%d %b %Y %X"
}


proc isWord { string } {

	regexp {^[ \t]*[^ ]+[ \t]*$} $string

}

######################################################################
# is_positive_int -- returns TRUE if passed string contains a positive
# integer, or a positive integer with white space on either side.
######################################################################

proc isPositiveInt { string } {

	if { [catch {set tempFloat [format "%d" $string]} errorResult ] } {
		return 0
	} else {
		if {$tempFloat < 0} {
			return 0
		} else {
			return 1
		}
	}
}


######################################################################
# is_incomplete_positive_int -- returns TRUE if passed string contains
# a positive integer, just a plus sign, just white space, or any of
# the preceding with white space on either side.
######################################################################

proc isIncompletePositiveInt { string } {

	return [regexp {^[ \t]*\+?[0-9]*[ \t]*$} $string]
}



######################################################################
# is_int -- returns TRUE if passed string contains an integer or an
# integer with white space on either side.
######################################################################

proc isInt { string } {

	if { [catch {set tempFloat [format "%d" $string]} errorResult ] } {
		puts $errorResult
		return 0
	} else {
		return 1
	}
}

proc isField { value } {

	if { [llength $value] > 1} {
		return 0
	} else {
		return 1
	}

}


######################################################################
# is_incomplete_int -- returns TRUE if passed string contains an
# integer, a plus sign, or a minus sign, or any of the preceding with 
# white space on either side.
######################################################################

proc isIncompleteInt { string } {

	return [regexp {^[ \t]*(\+|\-)?[0-9]*[ \t]*$} $string]
}


######################################################################
# is_float -- returns TRUE if passed string contains a float or a float
# with white space on either side.
######################################################################

proc isFloat { string } {
	if { [catch {set tempFloat [format "%f" $string]} errorResult ] } {
		return 0
	} else {
		return 1
	}
}


######################################################################
# is_incomplete_float -- returns TRUE if passed string contains an
# float, a plus sign, or a minus sign, or any of the preceding with 
# white space on either side.
######################################################################

proc isIncompleteFloat { string } {

	return [regexp {^[ \t]*(\+|\-)?([0-9]*\.?[0-9]*)?[ \t]*$} $string]
}


######################################################################
# is_positive_float -- returns TRUE if passed string contains
# a positive float or a positive float with white space on either side.
######################################################################

proc isPositiveFloat { string } {
	
	if { [catch {set tempFloat [format "%12.12f" $string]} errorResult ] } {
		return 0
	} else {
		if {$tempFloat < 0 } {
			return 0
		} else {
			return 1
		}
	}
}


######################################################################
# is_incomplete_positive_float -- returns TRUE if passed string contains
# a positive float, a plus sign, or any of the preceding with 
# white space on either side.
######################################################################

proc isIncompletePositiveFloat { string } {
	set number ""
	set sign ""
	regexp {^[ \t]*\+?([0-9]*\.?[0-9]*)?[ \t]*$} $string sign number
	return [expr { [isBlank $string] || $sign != "" || $number != "" }]
}

proc isIncompleteRootDirectory { string } {
    if {[isBlank $string]} {
        return 1
    }
    set tv [string trim $string]
    set first [string index $tv 0]
    if {$first != "/" && $first != "~"} {
        return 0
    }
    set tv [file nativename $tv]
    set newtv [TrimStringForRootDirectoryName $tv]
    if {$newtv != $tv} {
        log_warning "$newtv != $tv"
        return 0
    }
    return 1
}

######################################################################
# is_blank -- returns TRUE if passed string contains only whate space
######################################################################

proc isBlank { string } {

	regexp {^[ \t]*$} $string
}


proc valuesMatch { value1 value2 type {decimalPlaces 2} {precision 0.01} } {

	# clean up the two values
	set value1 [getCleanValue $value1 $type $decimalPlaces]
	set value2 [getCleanValue $value2 $type $decimalPlaces]

	# return false if either value is invalid
	if { ![valueValid $value1 $type] || ![valueValid $value2 $type] } {
		return 0
	}
	
	# compare values differently based on value type
	switch $type {

		""					{ return [expr [string compare $value1 $value2] == 0] }
        rootDirectory   -
		string 			{ return [expr [string compare $value1 $value2] == 0] }
		field 			{ return [expr [string compare $value1 $value2] == 0] }
		int 				{ return [expr [string compare $value1 $value2] == 0] }
		positiveInt 	{ return [expr [string compare $value1 $value2] == 0] }
		float 			{ return [expr abs( double($value1) - double($value2) ) < $precision ] }
		positiveFloat	{ return [expr abs( double($value1) - double($value2) ) < $precision ] }
		default {return -code error "1 Unknown type: $type"}
	}
}


proc valueValid { value type } {

	# call different validation functions based on value type
	switch $type {

		""					{ return 1 }
		string 			{ return 1 }
		field				{ return [isField $value] }
		int 				{ return [isInt $value] }
		positiveInt 	{ return [isPositiveInt $value] }
		float 			{ return [isFloat $value] }
		positiveFloat	{ return [isPositiveFloat $value] }
        rootDirectory   { return [isIncompleteRootDirectory $value] }
		default        { return -code error "2 Unknown type: $type" }
	}

	# default is to return false
	return 0
}


proc isIncompleteValue { value type } {
    #puts "in complete value $value $type"

	# call different validation functions based on value type
	switch $type {

		""					{ return 1}
		string 			{ return 1}
		field 			{ return [isField $value]}
		int 				{ return [isIncompleteInt $value] }
		positiveInt 	{ return [isIncompletePositiveInt $value] }
		float 			{ return [isIncompleteFloat $value] }
		positiveFloat	{ return [isIncompletePositiveFloat $value] }
        rootDirectory   { return [isIncompleteRootDirectory $value] }
		default {return -code error "3 Unknown type: $type"}
	}

	# return false if data type not recognized
	return 0
}

proc getCleanValue { value type {decimalPlaces 2} } {

	switch $type {

		"" 				{ return $value }
		string 			{ return $value }
		field 			{ return [getCleanField $value] }
		int				{ return [getCleanInt $value] }
		positiveInt		{ return [getCleanInt $value] }
		float				{ return [getCleanFloat $value $decimalPlaces] }
		positiveFloat	{ return [getCleanFloat $value $decimalPlaces] }
        rootDirectory   { return [getCleanRootDirectory $value] }
		default {return -code error "4 Unknown type: $type"}
	}

	# return origal value if data type not recognized
	return $value
}

proc getCleanRootDirectory { value } {
    set result [string trim $value]
    if {$result == "" || $result == "/"} {
        return $result
    }
    ###for DCS::Entry init=0
    if {$result == "0"} {
        return ""
    }
    if {[catch {
        TrimStringForRootDirectoryName $result
    } result]} {
        return ""
    }
    return $result
}

proc getCleanField { value } {
	# take the first field only
	return [lindex $value 0]
}


proc getCleanInt { value } {
	return [scan $value %d]
}


##### adust 1: only go upper, -1: only go lower
proc getCleanFloat { value decimalPlaces {adjust 0} } {
	
	if { ! [valueValid $decimalPlaces int ] } {
		return -code error "expected integer for number of decimal places"
	}

	if { [isFloat $value] } {
        set original $value
		# reformat value with correct number of decimal places
		set value [format "%.${decimalPlaces}f" $value]

        if {$adjust > 0} {
            if {$value < $original} {
                ###increase a little bit
                set dd [expr pow(0.1, $decimalPlaces)]
                set value [expr $value + $dd]
            }
        } elseif {$adjust < 0} {
            if {$value > $original} {
                ###decrease a little bit
                set dd [expr pow(0.1, $decimalPlaces)]
                set value [expr $value - $dd]
            }
        }

	} else {

		# trim off all white space
		set value [string trim $value]
		
		# trim off leading zeros
		set value [string trimleft $value 0]
	}

	# return the cleaned value
	return $value
}


proc showStack {} {
	
	set currentLevel [info level]
	
	while { $currentLevel > 0 } {
		puts "$currentLevel: [info level $currentLevel]"
		incr currentLevel -1
	}

}

class ::DCS::Units {
	
	private variable scaleFactor
	public method convertUnits {value oldUnits newUnits}
	public method convertUnitValue
	public method getConversionEquation { oldUnits newUnits }
	public method getConversionsForUnits
	private variable conversions

	constructor {} {
		
		set scaleFactor(eV,ev) ""

        ### current
        set scaleFactor(mA,mA) ""
		
		# set scale factors between length units
		set scaleFactor(mm,mm)	""
		set scaleFactor(um,um) 	""
		set scaleFactor(mm,um)	"1000. *"
		set scaleFactor(um,mm)	"0.001 *"
		
		# set scale factors between angle units
		set scaleFactor(deg,deg)	""
		set scaleFactor(mrad,mrad)	""
		set scaleFactor(deg,mrad)	"17.45329 *"
		set scaleFactor(mrad,deg)	"0.05729578 *"
		set scaleFactor(%,%)       ""
		set scaleFactor(s,s)       ""
		set scaleFactor(s,ms)       "1000.0 * "
		set scaleFactor(ms,s)       "0.001 * "
		set scaleFactor(ms,ms)       ""

        # set scale factors between time
        set scaleFactor(s,min)      "0.016666667 *"
        set scaleFactor(min,s)      "60 *"
        set scaleFactor(min,ms)      "60000 *"
        set scaleFactor(ms,min)      "0.0000166667 *"

		set scaleFactor(counts,counts) ""
		set scaleFactor(V,V)       ""
		set scaleFactor(volts,volts)       ""
		
		# set scale factors between energy units
		set scaleFactor(eV,eV)		""
		set scaleFactor(keV,keV)	""
		set scaleFactor(angstrom,angstrom)		""
		set scaleFactor(A,A)       ""
		
		set scaleFactor(eV,keV) 			"0.001 *"
		set scaleFactor(eV,angstrom)		"12398. /"
		set scaleFactor(eV,A)            "12398. /"

		set scaleFactor(keV,eV)				"1000. *"
		set scaleFactor(keV,angstrom)		"12.398 /"
		set scaleFactor(keV,A)           "12.398 /"

		set scaleFactor(angstrom,eV)		"12398. /"
		set scaleFactor(angstrom,keV)		"12.398 /"
		set scaleFactor(angstrom,A)		""

		set scaleFactor(A,eV)		"12398. /"
		set scaleFactor(A,keV)		"12.398 /"
		set scaleFactor(A,angstrom)		""

		set scaleFactor(e11p/s,e11p/s)		""

		set scaleFactor(C,C)		""
		set scaleFactor(K,K)		""

		#list of possible conversions
		set conversions(mm) {mm um}
		set conversions(um) {mm um}
		set conversions(ms) {ms s}
		set conversions(s) {ms s}
		set conversions(deg) {deg mrad}
		set conversions(mrad) {deg mrad}
		set conversions(eV) {eV keV A}
		set conversions(keV) {eV keV A}
		set conversions(A) {eV keV A}
		set conversions(%) {%}	
		set conversions(counts) {counts}	
        set conversions(K) {K}
        set conversions(C) {C}
        set conversions(L/min) {L/min}
        set conversions(volts) {volts}
        set conversions(V) {V}
        set conversions(e11p/s) {e11p/s}
        set conversions(mA) {mA}
		set conversions() {}	
	}
}

body ::DCS::Units::getConversionsForUnits {units_} {
	return $conversions($units_)
}

body DCS::Units::convertUnitValue { value_  toUnits_ } {

	if {$value_ == "" } {return ""}
	
	foreach {value units} $value_ break
	
	if {$units == ""} {return $value}
	
	set convertedValue  [convertUnits $value $units $toUnits_]

	return $convertedValue
}


body ::DCS::Units::convertUnits {value fromUnits toUnits} {
	#guard against weird inputs, don't try to convert...
	if {$fromUnits == ""} {return $value}
	if {$toUnits == ""} {return $value}
	if {$fromUnits == $toUnits } {return $value}

	if { [catch {
		set result [expr $scaleFactor($fromUnits,$toUnits) $value ]
	} errorResult ] } {
		#puts "ERROR $errorResult"
		return $value
	}
	
	return $result
}

body ::DCS::Units::getConversionEquation { fromUnits toUnits} {
	
	if { [catch {
		set result $scaleFactor($fromUnits,$toUnits)
	} errorResult ] } {
		return -code error "error converting '$fromUnits' to '$toUnits': $errorResult"
	}

	return $result
}


#set up a units conversion object
#set up a singleton object mediator called ::units
if { [info commands ::units] == "" } {
	#set up a list of default motors
	::DCS::Units units
}


proc max {num1 num2} {
   if {$num1 > $num2 } {
      return $num1
   } else {
      return $num2
   }
}

proc min {num1 num2} {
   if {$num1 < $num2 } {
      return $num1
   } else {
      return $num2
   }
}




set gLibraryStatus(Img) ""
set gLibraryStatus(tcl_c_libs) ""

proc ImgLibraryAvailable {} {
	global gLibraryStatus

	#return if the library already loaded or failed to load
	if { $gLibraryStatus(Img) != "" } {return $gLibraryStatus(Img)}
	
	#try to load the library
	if { [catch {package require Img} err]} {
		set gLibraryStatus(Img) 0

		puts "-------------------------------------------------------------------"
		puts "Could not find Img library.  Streaming video will not be available."
		puts "-------------------------------------------------------------------"	
	} {
		set gLibraryStatus(Img) 1
	}
}

proc loadAuthenticationProtocol1Library {} {

	#exit if the library for the protocol cannot be loaded
	if { [CLibraryAvailable] } {
		# generate security keys for the user
		catch {exec [file join $BLC_DIR genkey.sh]}
	}
}

proc CLibraryAvailable {} {
	global TCL_CLIBS_DIR
	global gLibraryStatus

	#return if the library already loaded or failed to load
	if { $gLibraryStatus(tcl_c_libs) != "" } {return $gLibraryStatus(tcl_c_libs)}

	#load the library
	set library [file join $TCL_CLIBS_DIR tcl_clibs.so]
	if [catch {load $library dcs_c_library} err] {
		puts "-----------------------------------------------------------------------------"
		puts $err
		puts "Could not load the C extension library."
		puts "This missing library provides:"
        puts "1. authentication protocol 1.0"
        puts "2. rapid diffraction image viewing"
        puts "3. Contour display for 2 motors Scan"
        puts "4. rapid dcs message parsing"
        puts "5. video display bilinear scaling"
		puts "The library is usually located in /usr/local/dcs/tcl_clibs."
		puts "-----------------------------------------------------------------------------"
		set gLibraryStatus(tcl_c_libs) 0

	} else {
		set gLibraryStatus(tcl_c_libs) 1
	}

	return $gLibraryStatus(tcl_c_libs)
}

proc assertSystemIdle { } {
    set deviceFactory [DCS::DeviceFactory::getObject]
    set strObj [$deviceFactory createString system_idle]
    set contents [$strObj getContents]
    if {$contents != ""} {
        log_error "system not idle: $contents"
        return -code error "system not idle: $contents"
    }
}

proc addToWaitingList { varName } {
    global gVwaitVariableList

    lappend gVwaitVariableList $varName
    puts "new waiting list $gVwaitVariableList"
    puts "length: [llength $gVwaitVariableList]"
}
proc removeFromWaitingList { varName } {
    global gVwaitVariableList

    set index [lsearch -exact $gVwaitVariableList $varName]
    if {$index >= 0} {
        set gVwaitVariableList [lreplace $gVwaitVariableList $index $index]
    }
}
proc abortAllWaiting { } {
    global gVwaitVariableList

    if {![info exists gVwaitVariableList]} {
        return
    }

    foreach varName $gVwaitVariableList {
        set $varName aborting
        puts "aborted vwait $varName"
    }
    set gVwaitVariableList ""
}
proc openWebWithBrowser { url } {
    if {![catch "exec firefox -remote openurl($url)" err]} {
        return
    }

    log_warning "open existing browser failed: $err, trying new browser.."
    exec firefox -ProfileManager -no-remote "$url" &
}
proc viewImageFile { fullPath_ } {
    set ext [file extension $fullPath_]

    if {[string equal -nocase $ext ".jpg"] \
    || [string equal -nocase $ext ".jpeg"]} {
        if [catch "openWebWithBrowser $fullPath_" errMsg] {
            log_error view of $fullPath_ failed: $errMsg
        }
    } else {
        if [catch "exec adxv $fullPath_ &" errMsg] {
            log_error view of $fullPath_ failed: $errMsg
        }
    }
}
proc get_log_file_counter { directory prefix ext } {
    #make sure the directory exists
    if {![file exists $directory]} {
        file mkdir $directory
    }
    if {![file isdirectory $directory]} {
        log_error "$directory is not a directory"
        return 0
    }
    
    #create pattern
    set pattern "${prefix}*"
    if {$ext != "" } {
        set pattern "${prefix}*.${ext}"
    }
    #get file list matches the pattern
    set fileList [glob -nocomplain -types f -directory $directory -- $pattern]
    #puts "filelist: $fileList"

    if {[llength $fileList] == 0} {
        return 0
    }

    ###find the newest file
    set newestFile {}
    set newestTS 0
    foreach fileName $fileList {
        set ts [file mtime $fileName]
        #puts "$fileName $ts"
        if {$ts > $newestTS} {
            set newestTS $ts
            set newestFile $fileName
            #puts "is newest"
        }
    }

    ###get the counter from that file
    set ll_ext [string length $ext]
    if {$ll_ext} {
        #skip the "." also
        incr ll_ext
    }
    if {$ll_ext} {
        set fNoExt [string range $newestFile 0 end-$ll_ext]
    } else {
        set fNoExt $newestFile
    }
    #puts "newest : $fNoExt"
    set ll [string length $fNoExt]
    for {set i 0} {$i < $ll} {incr i} {
        set strIndex [expr "$ll - $i -1"]
        set letter [string index $fNoExt $strIndex]
        if {[lsearch {0 1 2 3 4 5 6 7 8 9} $letter] < 0} {
            break
        }
    }
    if {$i == 0} {
        return 0
    }
    
    set c [string range $fNoExt end-[expr $i - 1] end]
    #puts "$c"
    
    set tmp_counter 0
    scan $c "%d" tmp_counter
    incr tmp_counter
    return $tmp_counter
}
proc getFilterList { shutterList } {
    set result ""

    foreach device $shutterList {
        if {$device == "Se" || \
        [string range $device 0 2] == "Al_"} {
            lappend result $device
        }
    }
    return $result
}
proc parseRobotMoveItem { item origREF destREF } {
    upvar $origREF orig
    upvar $destREF dest

    set orig ""
    set dest ""

    set index [string first -> $item]
    if {$index < 0} { return 0 }

    if {$index > 0} {
        set endO [expr $index - 1]
        set orig [string range $item 0 $endO]
    }
    set startD [expr $index + 2]
    if {$startD < [string length $item]} {
        set dest [string range $item $startD end]
    }
    if {$orig != "" || $dest != ""} {
        return 1
    } else {
        return 0
    }
}
### this is used in DCSS and may be used in bluice too
global gAuthTicketUrl
set gAuthTicketUrl ""
proc getAuthenticationOneTimeTicketUrl { } {
    global gAuthTicketUrl
    if {$gAuthTicketUrl !=""} {
        return $gAuthTicketUrl
    }
    set authHost [::config getAuthSecureHost]
    set authPort [::config getAuthSecurePort]
    set useSSL 1
    if {$authHost == ""} {
        set authHost [::config getAuthHost]
        set authPort [::config getAuthPort]
        set useSSL 0
    }
	if { $useSSL} {
		set url https://
    } else {
		set url http://
    }
    append url "$authHost:$authPort/gateway/servlet/GetOneTimeSession"
    append url "?AppName=BluIce"
    append url "&AuthMethod=smb_config_database"
    append url "&ValidBeamlines=True"

    set gAuthTicketUrl $url
    puts "gAuthTicketUrl set to: $gAuthTicketUrl"
    return $gAuthTicketUrl
}
proc getTicketFromSessionId { sessionId } {
    global gUseOneTimeTicket

    if {[info exists gUseOneTimeTicket] && !$gUseOneTimeTicket} {
        return $sessionId
    }

    if {[string equal -length 7 $sessionId "PRIVATE"]} {
        set mySID [string range $sessionId 7 end]
    } else {
        set mySID $sessionId
    }
    set url [getAuthenticationOneTimeTicketUrl]
    append url "&SMBSessionID=$mySID"

	set httpObjName ""

	if { [catch {
        set httpObjName [http::geturl $url -timeout 5000]
		upvar #0 $httpObjName httpObj
		set status $httpObj(status)
		set replystatus $httpObj(http)
		set replycode [lindex $replystatus 1]

        #puts "status: $status first $replystatus"
        #puts "body: $httpObj(body)"
	} err] } {
		if { [string length $httpObjName] > 0 } {
			http::cleanup $httpObjName
		}
		log_error "ERROR in getTicketFromSessionId: $err"
        return invalid
	}
	if { $status!="ok" } {
		# http status is no ok.
		http::cleanup $httpObjName
		log_error "ERROR in getTicketFromSessionId: Got http status $status"
        return invalid
	} elseif { $replycode == 403 } {
		# authentication failed
		http::cleanup $httpObjName
		log_error "ERROR in getTicketFromSessionId: failed 403"
        return invalid
	} elseif { $replycode!=200 } {
		# http response code is not 200
		http::cleanup $httpObjName
		log_error "ERROR in getTicketFromSessionId Got http response code $replycode"
        return invalid
                
	} else {
        set gotIt 0
        set ticket ""
		foreach {key value}  $httpObj(meta) {
            #log_note ticket key value: $key $value
		    if { [string equal -nocase $key "Auth.SessionValid"] } {
		        set gotIt [string is true $value]
		    } elseif { [string equal -nocase $key "Auth.SMBSessionID"] } {
			    set ticket $value
			}
        }
		http::cleanup $httpObjName
        if {$gotIt} {
            return $ticket
        } else {
            log_error "sessionID not valid"
            return invalid
        }
	}
    return invalid
}

proc SIDFilter { contents } {
    if {[catch {
        regsub {[0-9A-F]{32}} $contents {[string range & 0 6]} newContents
    } errMsg]} {
        return $contents
    }
    return [subst $newContents]
}
proc PRIVATEFilter { contents } {
    set start 0
    while {[set start [string first PRIVATE $contents $start]] >= 0} {
        set end [string wordend $contents $start]
        incr start 7
        #### 7 is length of PRIVATE
        set lX [expr $end - $start]
        if {$lX > 0} {
            set pad [string repeat X $lX]
            set padEnd [expr $end - 1]
            set contents [string replace $contents $start $padEnd $pad]
        }
        set start $end
    }
    return $contents
}

class ::DCS::DeviceLabelMap {
    private variable m_device
    private variable m_label

    ##these 2 access methods will failed if given a wrong name
    ##it is on purpose.
    public method getLabel { device } {
        return $m_label($device)
    }
    public method getDevice { label } {
        return $m_device($label)
    }

    constructor { mapList } {
        puts "constructor $this"
        puts "list: $mapList"

        array set m_device [list]
        array set m_label [list]

        foreach {device label} $mapList {
            set m_device($label) $device
            set m_label($device) $label
        }
    }

    destructor {
        array unset m_device
        array unset m_label
    }
}

proc parseFileNameForCounter { filename prefixRef numDRef counterRef ExtRef } {
    upvar $prefixRef prefix
    upvar $counterRef counter
    upvar $ExtRef ext
    upvar $numDRef i

    set dir  [file dirname $filename]
    set name [file tail $filename]

    set root [file rootname $name]
    set ext  [file extension $name]

    set ll [string length $root]

    set counter 0
    set base 1
    for {set i 0} {$i < $ll} {incr i} {
        set index [expr $ll - $i - 1]
        set letter [string index $root $index]
        if {[lsearch -exact {0 1 2 3 4 5 6 7 8 9} $letter] < 0} {
            break
        }
        set counter [expr $counter + $base * $letter]
        set base [expr $base * 10]
    }
    if {$i == 0} {
        return -code error "no counter found in filename $filename"
    }

    set prefix [string range $root 0 $index]
    set prefix [file join $dir $prefix]
}

### only work in BluIce
proc isDistanceOK { dtRef } {
    global gMotorDistance

    upvar $dtRef dt

    if {![::device::$gMotorDistance limits_ok dt]} {
        log_warning distance adjusted by motor limits
        return 0
    }
    if {$gMotorDistance != "detector_z"} {
        if {![::device::detector_z limits_ok dt]} {
            log_warning distance adjusted by motor limits
            return 0
        }
    }
    return 1
}
proc isTimeOK { tmRef } {
    upvar $tmRef tm

    set defT 1.0
    set minT 0.001
    set maxT 6000

    set deviceFactory [::DCS::DeviceFactory::getObject]
    if {[$deviceFactory stringExists collect_default]} {
        set obj [$deviceFactory getObjectName collect_default]
        set defContents [$obj getContents]
        if {[llength $defContents] >= 7} {
            foreach {defD defT defA minT maxT minA maxA} $defContents break
        }
    }

    if {$tm < $minT} {
        set tm $minT
        log_warning time adjusted by collect limits
        return 0
    }
    if {$tm > $maxT} {
        set tm $maxT
        log_warning time adjusted by collect limits
        return 0
    }
    return 1
}
proc isAttenuationOK { anRef } {
    upvar $anRef an 

    set defA 0
    set minA 0
    set maxA 100

    set deviceFactory [::DCS::DeviceFactory::getObject]
    if {[$deviceFactory stringExists collect_default]} {
        set obj [$deviceFactory getObjectName collect_default]
        set defContents [$obj getContents]
        if {[llength $defContents] >= 7} {
            foreach {defD defT defA minT maxT minA maxA} $defContents break
        }
    }

    if {$an < $minA} {
        set an $minA
        log_warning attenuation adjusted by collect limits
        return 0
    }
    if {$an > $maxA} {
        set an $maxA
        log_warning attenuation adjusted by collect limits
        return 0
    }
    return 1
}

proc parseReOrientInfo { contents_ mapRef } {
    upvar $mapRef reorient_info_array

    array unset reorient_info_array

    set lineList [split $contents_ \n]
    foreach line $lineList {
        set nv_pair [split $line =]
        if {[llength $nv_pair] == 2} {
            foreach {name value} $nv_pair break
            if {[string equal -length 9 $name REORIENT_]} {
                set reorient_info_array($name) $value
                puts "DEBUG set reorient_info_array($name) $value"
            }
        }
    }
}
proc secondToTimespan { s } {
    set m [expr $s / 60]
    set h [expr $m / 60]
    set d [expr $h / 24]

    set S [expr $s % 60]
    set M [expr $m % 60]
    set H [expr $h % 24]

    if {$d > 0} {
        return [format "%d %02d:%02d:%02d" $d $H $M $S]
    }
    if {$h > 0} {
        return [format "%02d:%02d:%02d" $h $M $S]
    }
    return [format "%02d:%02d" $m $S]
}
proc timespanToSecond { span } {
    set ll [string length $span]

    set s [string range $span end-1 end]
    #puts "s=$s"
    set total $s

    if {$ll > 3 && [string index $span end-2] == ":"} {
        set m [string range $span end-4 end-3]
        set total [expr $total + 60 * $m]
        #puts "m=$m total=$total"
    }
    if {$ll > 6 && [string index $span end-5] == ":"} {
        set h [string range $span end-7 end-6]
        set total [expr $total + 3600 * $h]
        #puts "h=$h total=$total"
    }
    if {$ll > 9 && [string index $span end-8] == " "} {
        set d [string range $span 0 end-9]
        set total [expr $total + 86400 * $d]
        #puts "d=$d total=$total"
    }
    return $total
}
proc setStringFieldWithPadding { copy index value {padding {}}} {
    set ll [llength $copy]
    if {$ll <= $index} {
        set need [expr $index - $ll + 1]
        for {set i 0} {$i < $need} {incr i} {
            lappend copy $padding
        }
    }

    set copy [lreplace $copy $index $index $value]

    return $copy
}
proc calculateProjectionFromSamplePosition { orig cur_x  cur_y  cur_z {return_micron 0}} {
    foreach {orig_x orig_y orig_z orig_angle cv ch} $orig break

    ###DEBUG
    if {![string is double -strict $orig_x]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $orig_y]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $orig_z]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $orig_angle]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $cv]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $ch]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }



    set dx [expr $cur_x - $orig_x]
    set dy [expr $cur_y - $orig_y]
    set dz [expr $cur_z - $orig_z]
    set da [expr $orig_angle * 3.1415926 / 180.0]

    set proj_x [expr -$dx * cos($da) - $dy * sin($da)]
    set proj_y [expr  $dx * sin($da) - $dy * cos($da)]
    set proj_z [expr -$dz]

    if {$return_micron} {
        set vu [expr $proj_x * 1000.0]
        set hu [expr $proj_z * 1000.0]
        return [list $vu $hu]
    }

    ## scaling
    set proj_v [expr $proj_x / double($cv)]
    set proj_h [expr $proj_z / double($ch)]

    return [list $proj_v $proj_h]
}
### update beam size box on matrix
proc calculateProjectionBoxFromBox { orig w h } {
    foreach {orig_x orig_y orig_z orig_angle cv ch} $orig break

    ###DEBUG
    if {![string is double -strict $orig_x]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $orig_y]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $orig_z]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $orig_angle]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $cv]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $ch]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }

    ## scaling
    set proj_w [expr abs($w / double($ch))]
    set proj_h [expr abs($h / double($cv))]

    return [list $proj_w $proj_h]
}
## used in define new sub area
proc calculateBoxFromProjectionBox { orig proj_w proj_h } {
    foreach {orig_x orig_y orig_z orig_angle cv ch} $orig break

    if {![string is double -strict $orig_x]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $orig_y]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $orig_z]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $orig_angle]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $cv]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }
    if {![string is double -strict $ch]} {
        log_error bad orig to calculate proj: $orig
        return [-999 -999]
    }

    ## scaling
    set w [expr abs($proj_w * double($ch))]
    set h [expr abs($proj_h * double($cv))]

    return [list $w $h]
}
proc calculateSamplePositionDeltaFromDeltaProjection { orig \
delta_proj_v delta_proj_h {proj_micron 0} \
} {
    foreach {orig_x orig_y orig_z orig_angle cv ch} $orig break

    if {$proj_micron} {
        set dv [expr $delta_proj_v / 1000.0]
        set dh [expr $delta_proj_h / 1000.0]
    } else {
        set dv [expr $delta_proj_v * $cv]
        set dh [expr $delta_proj_h * $ch]
    }
    set da [expr $orig_angle * 3.1415926 / 180.0]

    set dx [expr -$dv * cos($da)]
    set dy [expr -$dv * sin($da)]
    set dz [expr -$dh]

    return [list $dx $dy $dz]
}
proc calculateSamplePositionDeltaFromProjection { orig cur_x cur_y cur_z \
proj_v proj_h {proj_micron 0}} {

    set cur_proj [calculateProjectionFromSamplePosition \
    $orig $cur_x $cur_y $cur_z $proj_micron]
    foreach {cur_v cur_h} $cur_proj break

    set dv [expr $proj_v - $cur_v]
    set dh [expr $proj_h - $cur_h]

    return [calculateSamplePositionDeltaFromDeltaProjection $orig \
    $dv $dh $proj_micron]
}
proc calculateSamplePositionFromProjection { orig \
proj_v proj_h {proj_micron 0}} {

    set delta [calculateSamplePositionDeltaFromDeltaProjection $orig \
    $proj_v $proj_h $proj_micron]

    foreach {dx dy dz} $delta break

    foreach {ox oy oz oa} $orig break

    set x [expr $ox + $dx]
    set y [expr $oy + $dy]
    set z [expr $oz + $dz]
    return [list $x $y $z $oa]
}
### return horz project in orig1 which has the same sample_z as 
### h0 in orig0
### just in case we want to support indepent snapshots
proc translateHorzProjection { source_horz source_orig target_orig } {
    foreach {sx sy sz sangle scv sch} $source_orig break
    foreach {tx ty tz tangle tcv tch} $target_orig break

    #set proj_z [expr $source_horz * $sch]
    #set dz     [expr -1.0 * $proj_z]
    #set cur_z  [expr $dz + $ $sz]

    #set dz [expr $cur_z - $tz]
    #set proj_z [expr -$dz]
    #set proj_h [expr $proj_z / double($tch)]

    set target_horz [expr 1.0 *($tz - $sz + $source_horz * $sch) / $tch]

    return $target_horz
}
### now (08/22/2012) we need full translate
### we are only use for microns.
proc translateProjection { source_horz source_vert source_orig target_orig } {
    set centerV 0.5
    set centerH 0.5
    foreach {sx sy sz sangle scv sch} $source_orig break
    foreach {tx ty tz tangle tcv tch} $target_orig break

    if {[llength $target_orig] >= 10} {
        set centerV [lindex $target_orig 8]
        set centerH [lindex $target_orig 9]
    }

    ### units micron
    set sCntrX [expr $centerH * $sch * 1000.0]
    set sCntrY [expr $centerV * $scv * 1000.0]
    set tCntrX [expr $centerH * $tch * 1000.0]
    set tCntrY [expr $centerV * $tcv * 1000.0]
    foreach {v0 h0} [calculateProjectionFromSamplePosition \
    $target_orig $sx $sy $sz 1] break

    set a [expr ($sangle - $tangle) * 3.1415926 / 180.0]

    set target_horz [expr $h0 +  $source_horz - $sCntrX            + $tCntrX]
    set target_vert [expr $v0 + ($source_vert - $sCntrY) * cos($a) + $tCntrY]

    return [list $target_horz $target_vert]
}
proc reverseProjection { source_horz source_vert source_orig target_orig } {
    set centerV 0.5
    set centerH 0.5
    foreach {sx sy sz sangle scv sch} $source_orig break
    foreach {tx ty tz tangle tcv tch} $target_orig break

    if {[llength $source_orig] >= 10} {
        set centerV [lindex $source_orig 8]
        set centerH [lindex $source_orig 9]
    }

    ### units micron
    set sCntrX [expr $centerH * $sch * 1000.0]
    set sCntrY [expr $centerV * $scv * 1000.0]
    set tCntrX [expr $centerH * $tch * 1000.0]
    set tCntrY [expr $centerV * $tcv * 1000.0]
    foreach {v0 h0} [calculateProjectionFromSamplePosition \
    $target_orig $sx $sy $sz 1] break

    set a [expr ($sangle - $tangle) * 3.1415926 / 180.0]

    set target_horz [expr $h0 +  $source_horz - $sCntrX            + $tCntrX]
    set target_vert [expr $v0 + ($source_vert - $sCntrY) / cos($a) + $tCntrY]

    return [list $target_horz $target_vert]
}
## units in microns
proc translateProjectionBox { s_horz s_vert source_orig target_orig } {
    foreach {sx sy sz sangle scv sch} $source_orig break
    foreach {tx ty tz tangle tcv tch} $target_orig break

    set a [expr ($sangle - $tangle) * 3.1415926 / 180.0]

    set target_horz $s_horz
    set target_vert [expr $s_vert * cos($a)]

    return [list $target_horz $target_vert]
}
proc reverseProjectionBox { s_horz s_vert source_orig target_orig } {
    foreach {sx sy sz sangle scv sch} $source_orig break
    foreach {tx ty tz tangle tcv tch} $target_orig break

    set a [expr ($sangle - $tangle) * 3.1415926 / 180.0]

    set target_horz $s_horz
    set target_vert [expr $s_vert / cos($a)]

    return [list $target_horz $target_vert]
}

### units in microns
proc translateProjectionCoords { coords source_orig target_orig } {
    foreach {sx sy sz sangle scv sch} $source_orig break
    foreach {tx ty tz tangle tcv tch - - centerV centerH} $target_orig break

    if {$centerV == "" || $centerH == ""} {
        puts "no center in target orig: $target_orig"
        puts "source=$source_orig"
        set centerV 0.5
        set centerH 0.5
    }

    ### units micron
    set sCntrX [expr $centerH * $sch * 1000.0]
    set sCntrY [expr $centerV * $scv * 1000.0]
    set tCntrX [expr $centerH * $tch * 1000.0]
    set tCntrY [expr $centerV * $tcv * 1000.0]
    foreach {v0 h0} [calculateProjectionFromSamplePosition \
    $target_orig $sx $sy $sz 1] break

    set a [expr ($sangle - $tangle) * 3.1415926 / 180.0]

    set result ""

    foreach {h v} $coords {
        set target_horz [expr $h0 +  $h - $sCntrX            + $tCntrX]
        set target_vert [expr $v0 + ($v - $sCntrY) * cos($a) + $tCntrY]

        lappend result $target_horz $target_vert
    }
    return $result
}
proc reverseProjectionCoords { coords source_orig target_orig } {
    foreach {sx sy sz sangle scv sch - - centerV centerH} $source_orig break
    foreach {tx ty tz tangle tcv tch} $target_orig break

    if {$centerV == "" || $centerH == ""} {
        puts "no center in target orig: $target_orig"
        puts "source=$source_orig"
        set centerV 0.5
        set centerH 0.5
    }

    ### units micron
    set sCntrX [expr $centerH * $sch * 1000.0]
    set sCntrY [expr $centerV * $scv * 1000.0]
    set tCntrX [expr $centerH * $tch * 1000.0]
    set tCntrY [expr $centerV * $tcv * 1000.0]
    foreach {v0 h0} [calculateProjectionFromSamplePosition \
    $target_orig $sx $sy $sz 1] break

    set a [expr ($sangle - $tangle) * 3.1415926 / 180.0]

    set result ""

    foreach {h v} $coords {
        set target_horz [expr $h0 +  $h - $sCntrX            + $tCntrX]
        set target_vert [expr $v0 + ($v - $sCntrY) / cos($a) + $tCntrY]

        lappend result $target_horz $target_vert
    }
    return $result
}
proc UtilTakeVideoSnapshot { } {
    set url [::config getSnapshotDirectUrl]
    if { [catch {
        set token [http::geturl $url -timeout 12000]
    } err] } {
        set status "ERROR $err $url"
        set ncode 0
        set code_msg "get url failed for snapshot"
        set result ""
    } else {
        upvar #0 $token state
        set status $state(status)
        set ncode [http::ncode $token]
        set code_msg [http::code $token]
        set result [http::data $token]
        http::cleanup $token
    }

    if { $status!="ok" || $ncode != 200 } {
        set msg \
        "ERROR VideoSnapshot http::geturl status=$status"
        puts $msg
        log_error Web error: $status $code_msg

        return -code error "web error: $status $code_msg"
    }
    return $result
}
proc UtilTakeInlineVideoSnapshot { } {
    set url [::config getSnapshotDirectInlineUrl]
    if {$url == ""} {
        log_error url for direct inline snapshot not defined
        return -code error URL_NOT_DEFINED
    }

    if { [catch {
        set token [http::geturl $url -timeout 12000]
    } err] } {
        set status "ERROR $err $url"
        set ncode 0
        set code_msg "get url failed for snapshot"
        set result ""
    } else {
        upvar #0 $token state
        set status $state(status)
        set ncode [http::ncode $token]
        set code_msg [http::code $token]
        set result [http::data $token]
        http::cleanup $token
    }

    if { $status!="ok" || $ncode != 200 } {
        set msg \
        "ERROR VideoSnapshot http::geturl status=$status"
        puts $msg
        log_error Web error: $status $code_msg

        return -code error "web error: $status $code_msg"
    }
    return $result
}

proc replaceDirectoryTags { dir_with_tags } {
    global OPERATION_DIR

    set date     [clock format [clock seconds] -format "%Y%m%d"]
    set beamline [::config getConfigRootName]
    if {[info exists OPERATION_DIR]} {
        set user [get_operation_user]
    } else {
        set user     [::dcss getUser]
    }

    set result $dir_with_tags
    regsub -all {\{DATE\}} $result $date result
    regsub -all {\{USER\}} $result $user result
    regsub -all {\{BEAMLINE\}} $result $beamline result


    return $result
}
proc getDefaultDataDirectory { user_ } {
    set defHome [::config getDefaultDataHome]
    if {[string first $user_ $defHome] >= 0} {
        return $defHome
    } else {
        return [file join $defHome $user_]
    }
}
proc checkUsernameInDirectory { dirRef username } {
    upvar $dirRef dir
    set needChange 0
    set sdl [file split $dir]
    set goodDir ""
    foreach sd $sdl {
        if {[string equal -nocase $sd "username"]} {
            set sd $username
            incr needChange
        }
        lappend goodDir $sd
    }
    if {$needChange} {
        set dir [eval file join $goodDir]
        log_warning directory changed to $dir
    }
    return $needChange
}
proc getAutoInterval { range } {
    set result 1.0

    set ff [list 2.0 2.5 2.0]

    set n 0
    while {$result * 5 > $range} {
        set n [expr $n % 3]
        set f [lindex $ff $n]
        incr n
        set result [expr $result / $f]
    }
    while {$result < $range / 10.0} {
        set n [expr $n % 3]
        set f [lindex $ff $n]
        incr n
        set result [expr $result * $f]
    }
    return $result
}
proc getMotorUnits { motor } {
    if {$motor == "time"} {
        return second
    }
    if {[catch {::device::$motor cget -baseUnits} result]} {
        return ""
    }
    return $result
}
proc getMotorDisplayName { motor } {
    switch -exact -- $motor {
        dose -
        time {
            return Time
        }
        gonio_phi -
        gonio_omega -
        gonio_kappa {
            return [string totitle [string range $motor 6 end]]
        }
        default {
            return [string totitle $motor]
        }
    }
}
proc readCSVFileIntoList { path } {
    if {[catch {open $path r} fh]} {
        log_error open file $path failed: $fh
        return -code error $fh
    }
    set contents [read -nonewline $fh]
    close $fh
    set lines [split $contents "\n"]

    set result ""
    foreach line $lines {
        if {![::csv::iscomplete $line]} {
            log_error skip line: $line
            continue
        }
        set eList [::csv::split $line]
        lappend result $eList
    }
    return $result
}
