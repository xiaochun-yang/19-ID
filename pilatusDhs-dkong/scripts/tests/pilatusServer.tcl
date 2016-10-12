#!/usr/bin/tclsh

package require Itcl
namespace import itcl::*

set i 0
class MockPilatusServer {
    private variable _socket 
    #private variable _exptime ""
    public variable _exptime ""

   constructor {port_} {
      if {[catch {	
         socket -server [::itcl::code $this accept] $port_	
      } _socket]} {	
         puts "ERROR Could not create mock server socket for Pilatus: $_socket"	
         return -code error	
	}
	puts "MockPilatusServer is establed"
   } 

   public method accept {sd_ address_ port_} {
      puts "MOCK PILATUS HANDLE CONNECT $sd_"
      fconfigure $sd_ -buffering line
      fileevent $sd_ readable [::itcl::code $this handleClientInput $sd_]
   }

    public method handleClientInput { sd_ } {
        if {[catch {gets $sd_ data} rc]} {	
            return	
        }
	global i
	set i  [expr $i + 1]
        puts "PILATUS<DHS-YANG: $data $i"
        set tokens [split $data]

        switch [lindex $tokens 0] {
            exttrigger {
                if {$_exptime==""} {
    		    puts "yangx1 $sd_ 15 OK Starting externally triggered exposure(s): 2009/Jul/10 10:36:22.2837 ERR"
                    toDhs $sd_ "15 OK Starting externally triggered exposure(s): 2009/Jul/10 10:36:22.2837 ERR"
                    after [expr $_expTime * 1000] [::itcl::code $this sendExposeCompleteResponse $sd_ $_filename]
                    return
                }

                set filename [lindex $tokens 1]
#ori-yang       toDhs $sd_ "15 OK Exposure time set to: $_exptime sec.15 OK Starting externally triggered exposure(s): 2009/Jul/10 10:43:49.748"
                toDhs $sd_ "15 OK Starting externally triggered exposure(s): 2009/Jul/10 10:43:49.748"
		after  [expr {int($_exptime*1000)}] [::itcl::code $this sendExposeCompleteResponse $sd_ "/home/yangx/ptest1"]
		#after [expr $_exptime * 1000]
		#::itcl::code $this sendExposeCompleteResponse $sd_ $_filename
            }
            exptime {
                set _exptime [lindex $tokens 1]
		puts "yangx3 $sd_ 15 OK Exposure time set to: $_exptime sec."
		
		#the following are the test for why _exptime is not a double
		#It's a strange token output. 
		set sp [string range $_exptime 0 5]
		
		#set value [format %f $_exptime]
		if { [string is double $_exptime] } {
			puts "exptime  is a double"
 		} else {
			puts "exptime is not a double"
		}
		if { [string is double $sp] } {
                        puts "sp is a double"
                }

		set q [string length $_exptime]
		
		puts "the exptime lenghth=$q"
		for {set i 0} {$i < $q} {incr i} {
			set t [string index $_exptime $i]
			puts "t=$t"
			if { $t == "." } {
				puts "the . =$t at index $i"
			}
		}
#		set _exptime $sp
		#reassign _exptime here because somehow the original _exptime 
		#value has extra character with is not a number so some how
		#it dosen't consider as a double vale. Don't know how it happened. 

		#it's ok now. It's fixed. the value is from 
		# the putDet function in the pilatusControl.tcl.

                toDhs $sd_ "15 OK Exposure time set to: $_exptime sec."
            }

        }

    }

    public method sendExposeCompleteResponse {sd_ filename_} {
        toDhs $sd_ "7 OK $filename_"
    }

    public method breakConnection {} {
        puts "disconnect from dcss"
    }
    
    private method toDhs { sd_ msg } {
        puts -nonewline $sd_ $msg
#	puts $sd_ $msg
        endLine $sd_
    }

    private method endLine {sd_ } {
        puts -nonewline $sd_ [format %c "24"]
#	puts $sd_ [format %c "24"]
        flush $sd_
    }

}

#MockPilatusServer mockPilatusServer [::config getStr pilatus.port]
MockPilatusServer mockPilatusServe 41234
vwait forever
