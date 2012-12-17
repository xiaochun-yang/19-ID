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
#
#                       Permission Notice
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
# BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
##########################################################################


# load standard packages
package require Itcl

package provide DCSClientList 1.0

#package require Iwidgets
#package require DCSPrompt
#package require DCSTitledFrame
#package require DCSButton


class DCS::ClientList {
   inherit DCS::Component

   public method getClientList {} {return $m_clientList}
   public method handleNewClientList
   public method handleNewClient   

   private variable m_numClients 0 
   private variable m_numClientsDefined 0 
   private variable m_clientList ""

   #variable for storing singleton doseFactor object
   private common m_theObject {} 
   public proc getObject
   public method enforceUniqueness

   constructor {} {DCS::Component::constructor {clientList getClientList} } {

      enforceUniqueness
	   
      announceExist
   }
}

#return the singleton object
body DCS::ClientList::getObject {} {
   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto]
   }

   return $m_theObject
}

#this function should be called by the constructor
body DCS::ClientList::enforceUniqueness {} {
   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if ![string match "${current}::getObject" $caller] {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}


body DCS::ClientList::handleNewClientList { message_ } {
   #clear all of the variables and start building the list again
   set m_numClients [lindex $message_ 1]
   set m_numClientsDefined 0
   set m_clientList ""
}


body DCS::ClientList::handleNewClient { message_ } {
   incr m_numClientsDefined

   lappend m_clientList $message_

   #inform observers only when we have the complete list
   if {$m_numClientsDefined >= $m_numClients } {
      updateRegisteredComponents clientList
   }
}


