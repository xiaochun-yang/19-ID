package require http


proc pollTemperature { updateRate } {

   set temps [readTemp]

   catch {log_info $temps}

   ::dcss sendMessage "htos_set_string_completed temperatures normal $temps"
   after $updateRate [list pollTemperature $updateRate]
}


proc readTemp {} {
   set ip [::config getStr sensatronic.host] 
   set port [::config getStr sensatronic.port] 

   set errorList  [list  -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9 -99.9]

   if { [catch {
      set s [socket $ip $port]
      puts $s "GET /temp HTTP/1.0\n\r\n\r"
      flush $s
      set data [read $s]
      close $s
   } err]  } {
      puts "$err"
      if {[info exists s]} {close $s}
      return $errorList
   }

   set tempData [split $data |]
   set tempList {}
   set nameList {}

   foreach {tempName tempValue} $tempData {
      if {$tempValue > -99 } {
         #convert to celsius
         lappend tempList [format %4.2f [expr ($tempValue -32) * 5 / 9 ]] 
      } else {
         lappend tempList $tempValue 
      }
   }
   puts $nameList

   return $tempList
}

proc log_info { msg } {
   set log_file_name [::config getStr sensatronic.logfile] 

    puts $msg
    set prefix temperature_log_

    if { [catch {
        set h [open $log_file_name a] 
    } h ]} {
       set errorMsg "failed to log temperatures: $err"
       puts $errorMsg
       ::dcss sendMessage "htos_log severe temperatureDhs $errorMsg"
    }
    
    set timestamp [clock format [clock seconds] -format "%D|%T"]

    if { [catch {
        puts $h "$timestamp $msg"
        close $h
    } err ]} {
       set errorMsg "failed to log temperatures: $err"
       puts $errorMsg
       ::dcss sendMessage "htos_log severe temperatureDhs $errorMsg"
      if {[info exists h]} {close $h}
    }
 
}


