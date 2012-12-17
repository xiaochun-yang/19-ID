#!/usr/bin/wish
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
##########################################################################


# provide the DCSMessageRouter package
package provide DCSLogger 1.0

# load local packages
package require DCSComponent

class DCS::Logger {
	inherit DCS::Component

   private variable m_entryCount 0 
   private variable m_entry	

   private variable m_callingObject

	# public methods
   public method logNote
   public method logWarning
   public method logError
   
   public method getTail
   public method getTailFromIndex
   private method timeStamp
   private method logEventSource

   #variable for storing singleton doseFactor object
   private common m_theObject {} 
   public proc getObject
   public method enforceUniqueness

   public method getEntryCount {} {return $m_entryCount} 
   #number of log entries

	# constructor
	constructor { args } {
		# call base class constructor
		::DCS::Component::constructor { entryCount {getEntryCount} } } {

      enforceUniqueness
   
      set m_entry(0) [list [timeStamp] logStart]

      announceExist

	}

	# destructor
	destructor {
	}
}


#return the singleton object
body DCS::Logger::getObject {} {

   #puts "getObject"

   #return

   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto]
   }

   #puts $m_theObject

   return $m_theObject
}

#this function should be called by the constructor
body DCS::Logger::enforceUniqueness {} {

   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if ![string match "${current}::getObject" $caller] {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}


body DCS::Logger::timeStamp {} {
	clock format [clock seconds] -format "%d %b %Y %X"
}


body DCS::Logger::logEventSource { {source_ ""} } {

   #get the object name that is logging this entry
   if { $source_ == "" } {
      #get the $this value of the source
      upvar 2 this source 
   } else {
      set source $source_
   }

   lappend m_callingObject($source) $m_entryCount
}

body DCS::Logger::logNote { message_ {source_ ""} } {

   incr m_entryCount

   #store the message
   set m_entry($m_entryCount) [list [timeStamp] note $message_]

   logEventSource $source_

   updateRegisteredComponents entryCount
}


body DCS::Logger::logWarning { message_ {source_ ""} } {

   incr m_entryCount

   #store the message
   set m_entry($m_entryCount) [list [timeStamp] warning $message_]

   logEventSource $source_

   updateRegisteredComponents entryCount
}


body DCS::Logger::logError { message_ {source_ ""} } {

   incr m_entryCount

   #store the message
   set m_entry($m_entryCount) [list [timeStamp] error $message_]

   logEventSource $source_

   updateRegisteredComponents entryCount
}



#returns the last num_ entries
#Useful to initialize a new log viewer
body DCS::Logger::getTail { num_ { filter all } } {

   set index [expr $m_entryCount - $num_]
   if {$index < 0} {set index 0}

   return [getTailFromIndex $index $filter]
}

#returns all entries after the passed index_
#A log viewer can use this to keep up with a growing log.
#The viewer can request all entries after the index that it
#is currently up-to-date on.
body DCS::Logger::getTailFromIndex { index_ { filter all }} {

   set tail ""

   set index $index_

   if {$index < 0 } return

    #no filter
    if {$filter == "all"} {
        while {$index < $m_entryCount } {
            lappend tail $m_entry([expr $index + 1])
            incr index
        }
        return $tail
    }

    #filting
    while {$index < $m_entryCount } {
        set line $m_entry([expr $index + 1])
        set type [lindex $line 1]
        if {[lsearch $filter $type] >= 0} {
            lappend tail $line
        }
        incr index
    }
   return $tail
}


#################################
# utility fuction
#################################
proc log_note { args } {
    [DCS::Logger::getObject] logNote $args bluIce
}

proc log_warning { args } {
    [DCS::Logger::getObject] logWarning $args bluIce
}

proc log_error { args } {
    [DCS::Logger::getObject] logError $args bluIce
}
proc log_severe { args } {
    [DCS::Logger::getObject] logError $args bluIce
}

