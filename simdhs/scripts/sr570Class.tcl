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

package require DCSSet

DCS::Set registered_sr570_list

class Sr570 {
	public variable name
	public variable hostname
	public variable port 
   private variable connected
   private variable socket

	private variable configured			0

	private variable errorCode			   none

	public method configureDevice
	public method constructor { args }
	private method getConnection
	private method disconnect
   private method sendMessage { message } 
   private method calcIouv
   private method validateEnumValue
	
   private variable SENS [list 1pA/V 2pA/V 5pA/V 10pA/V 20pA/V 50pA/V 100pA/V 200pA/V 500pA/V 1nA/V 2nA/V 5nA/V 10nA/V 20nA/V 50nA/V 100nA/V 200nA/V 500nA/V 1uA/V 2uA/V 5uA/V 10uA/V 20uA/V 50uA/V 100uA/V 200uA/V 500uA/V 1mA/V]
   private variable SUCM [list cal uncal]
   #private variable SUCV [list cal uncal]
   private variable IOON [list off on]
   private variable IOLV  [list 1pA 2pA 5pA 10pA 20pA 50pA 100pA 200pA 500pA 1nA 2nA 5nA 10nA 20nA 50nA 100nA 200nA 500nA 1uA 2uA 5uA 10uA 20uA 50uA 100uA 200uA 500uA 1mA 2mA 5mA]
   private variable IOSN [list neg pos]
   private variable IOUC [list cal uncal]
   #private variable IOUV
   private variable BSON [list off on]
   #private variable BSLV 
   private variable FLTT [list 6dB_highpass 12dB_highpass 6dB_bandpass 6dB_lowpass 12dB_lowpass none]
   private variable LFRQ [list 0.03Hz 0.1Hz 0.3Hz 1Hz 3Hz 10Hz 30Hz 100Hz 300Hz 1kHz 3kHz 10kHz 30kHz 100kHz 300kHz 1MHz]
   private variable HFRQ [list 0.03Hz 0.1Hz 0.3Hz 1Hz 3Hz 10Hz 30Hz 100Hz 300Hz 1kHz 3kHz 10kHz ]
   private variable GNMD [list low_noise high_bandwidth low_drift]
   private variable INVT [list non-inverted inverted]
   private variable BLNK [list no_blank blank]

   public variable currentParams 
}

configbody Sr570::name {}
configbody Sr570::hostname {}
configbody Sr570::port {}



body Sr570::constructor { args } {
   puts "$args"
   set currentParams(SENS) "-" 
   set currentParams(SUCM) "-" 
   set currentParams(IOON) "-" 
   set currentParams(IOLV) "-" 
   set currentParams(IOSN) "-" 
   set currentParams(IOUC) "-" 
   set currentParams(BSON) "-" 
   set currentParams(FLTT) "-" 
   set currentParams(LFRQ) "-" 
   set currentParams(HFRQ) "-" 
   set currentParams(GNMD) "-" 
   set currentParams(INVT) "-" 
   set currentParams(BLNK) "-" 
   set currentParams(SUCV) "100" 
   set currentParams(BSLV) "-" 
   set currentParams(IOUV) "0.0" 
	eval $this configure [concat $args]
}

body Sr570::getConnection { } {

   if {[info exists socket]} {return $socket}

   if { [catch {
      set socket [socket $hostname $port]
      after 1000
   } err] } {
      disconnect
      return -code $err
   }
   
   return $socket
}


body Sr570::disconnect { } {
   ::dcss sendMessage "htos_log severe sr570 disconnecting socket for $name"

   if {[info exists socket]} {close $socket; unset socket }

}

body Sr570::validateEnumValue { type value } {

   set enumList [set $type]
   set index [lsearch $enumList $value]
   if {$index == -1} {
      puts "for $type, $value must be one of: $enumList"
      ::dcss sendMessage "htos_log warning sr570 $value must be one of: $enumList" 
   }
   return $index
}

body Sr570::calcIouv { value_ } {
   return [expr int($value_ * 10)]
}

body Sr570::configureDevice { args } {

   foreach {key value} $args {
      switch $key {
         SENS - IOLV - IOSN - BSON - FLTT - LFRQ - HFRQ - GNMD - INVT - BLNK {
            if { [set index [validateEnumValue $key $value]] == -1 } continue;
            set message "$key $index"
         } SUCM {
            if { [set index [validateEnumValue $key $value]] == -1 } continue;
            if {$currentParams($key) == $value} continue;
            set message "$key $index"
            sendMessage $message

            set currentParams($key) $value

            if { $currentParams(SUCM) == "uncal" } {
               sendMessage "SUCV [expr int ($currentParams(SUCV) )]"
            }
            continue

         } IOUC - IOON {
            if { [set index [validateEnumValue $key $value]] == -1 } continue;
            if {$currentParams($key) == $value} continue;
            set message "$key $index"
            sendMessage $message

            set currentParams($key) $value

            if { $currentParams(IOUC) == "uncal" && $currentParams(IOON) == "on" } {
            puts $value
               sendMessage "IOUV [calcIouv $currentParams(IOUV)]"
            }
            continue

         } SUCV {
            if {$value > 100.0} {set value 100}
            if {$value < 0.0} {set value 0}
            set message "SUCV [expr int ($value)]"
         } BSLV {
            if {$value > 5.0} {set value 5.0}
            if {$value < -5.0} {set value -5.0}
            set message "$key [expr int($value * 1000)]"
         } IOUV {
            if {$value > 100.0} {set value 100.0}
            if {$value < -100.0} {set value -100.0}
            set message "$key [calcIouv $value]"
         } default {puts "SR570: unknown key: $key"}
      }

      if {$currentParams($key) == $value} continue;
      sendMessage $message
      set currentParams($key) $value
   }

   set newString [list SENS $currentParams(SENS) SUCM $currentParams(SUCM) IOON $currentParams(IOON) IOLV $currentParams(IOLV) IOUC $currentParams(IOUC) BSON $currentParams(BSON) FLTT $currentParams(FLTT) LFRQ $currentParams(LFRQ) HFRQ $currentParams(HFRQ) GNMD $currentParams(GNMD) INVT $currentParams(INVT) BLNK $currentParams(BLNK) SUCV $currentParams(SUCV) BSLV $currentParams(BSLV) IOUV $currentParams(IOUV) IOSN $currentParams(IOSN)]
   return $newString
}


body Sr570::sendMessage { message } {

   set s [getConnection]
   
   if { [catch {
      puts "sr570 -> ${message}"
      puts $s "${message}"
      flush $s
   } err] } {
      disconnect
      return -code $err
   }

}

