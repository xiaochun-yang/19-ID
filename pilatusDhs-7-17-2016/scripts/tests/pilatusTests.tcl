class MockPilatusServer {
    private variable _socket 
    private variable _exptime ""

   constructor {port_} {
      if {[catch {	
         socket -server [::itcl::code $this accept] $port_	
      } _socket]} {	
         puts "ERROR Could not create mock server socket for Pilatus: $_socket"	
         return -code error	
	}
	puts "yangx MockPilatusServer is establed"
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
        puts "PILATUS<DHS: $data"
        set tokens [split $data]

        switch [lindex $tokens 0] {
            exttrigger {
                if {$_exptime==""} {
                    toDhs $sd_ "15 OK Starting externally triggered exposure(s): 2009/Jul/10 10:36:22.2837 ERR"
                    after [expr $_expTime * 1000] [::itcl::code $this sendExposeCompleteResponse $sd_ $_filename]
                    return
                }

                set filename [lindex $tokens 1]
                toDhs $sd_ "15 OK Exposure time set to: $_exptime sec.15 OK Starting externally triggered exposure(s): 2009/Jul/10 10:43:49.748"
            }
            exptime {
                set _exptime [lindex $tokens 1]
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
        endLine $sd_
    }

    private method endLine {sd_ } {
        puts -nonewline $sd_ [format %c "24"]
        flush $sd_
    }

}

MockPilatusServer mockPilatusServer [::config getStr pilatus.port]
