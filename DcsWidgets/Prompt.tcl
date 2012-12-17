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

# provide the DCSMenu package
package provide DCSPrompt 1.0

# load standard packages
package require Itcl
package require Iwidgets

#namespace import itcl::* 

# load other DCS packages
#package require DCSUtil 1.0


##########################################################################

class DCS::commandHistory {

	public variable maxCommands 100
	private variable _head 0
	private variable _tail 0
	private variable _current 0
	protected variable history

	private method prev
	private method next
	public method do
	public method addHistory
	public method moveUpHistory
	public method moveDownHistory

	# constructor
	constructor {args} {
		#initialize the first command history
		set history(0) ""

		eval configure $args
	}

	destructor {}
}


body DCS::commandHistory::addHistory {command} {
	
	set history($_head) $command	
	set _head [next $_head]
	set _current $_head
	if { $_head == $_tail } {
		#push the tail around as we overwrite old commands
		set _tail [next $_tail]
	}
}


body DCS::commandHistory::moveUpHistory {} {

	if { $_head == $_tail } {
		#no history 
		return ""
	}
	
	if { $_current == -1 } {
		set _current $_head
	}
	
	if { $_current != $_tail } {
		set _current [prev $_current]
	}

	set command $history($_current)
	return $command
}


body DCS::commandHistory::moveDownHistory {} {
	
	if { $_head == $_tail } {
		#no history
		return ""
	}
	
	if { $_current != [prev $_head] } {
		set _current [next $_current]
		set command $history($_current)
	} else {
		#nothing at the bottom, so that a person can type
		set command ""
	}

	return $command
}
		
	
body DCS::commandHistory::prev { index } {
	expr (($index - 1) % $maxCommands)
}
	

body DCS::commandHistory::next { index } {
	expr (($index + 1) % $maxCommands)	

}


				  

class DCS::Prompt {
	inherit ::itk::Widget
	public method do
	public method moveUpHistory
	public method moveDownHistory

	itk_option define -logger logger Logger ""
	#private
	private variable _commandHistory ""

	constructor { args } {
		
		set _commandHistory [namespace current]::[DCS::commandHistory \#auto ]

		itk_component add ring {
			frame $itk_interior.ring
		}

		itk_component add label {
			# create the button
			label $itk_component(ring).b
		} {
			keep -text -font -height -background -foreground -relief 
			rename -width -labelWidth labelWidth LabelWidth
		}

		itk_component add entry {
			# the command entry itself
			entry $itk_component(ring).e 
			#-textvariable -background white
		} {
			keep -background -foreground
		}

		eval itk_initialize $args

		pack $itk_component(ring) -expand 1 -fill x
		pack $itk_component(label) -side left -expand no
		pack $itk_component(entry) -side left -expand 1 -fill both


		bind $itk_component(entry) <Return> 	"$this do"
		bind $itk_component(entry) <Up>			"$this moveUpHistory"
		bind $itk_component(entry) <Down>		"$this moveDownHistory"
	
		bind $itk_component(entry) <Control-a> {
			set i [$itk_component(entry) index insert];
			$itk_component(entry) insert $i end; 
			break;
		}

		bind $itk_component(entry) <Control-m> {
			set i [$itk_component(entry) index insert];
			$itk_component(entry) insert $i end; 
			break;
		}
	}
	
	destructor {
		destroy $_commandHistory
	}

}

body DCS::Prompt::do {} {
	set command [concat [$itk_component(entry) get]]

	if {$itk_option(-logger) != "" } {
		$itk_option(-logger) log_command $command
	}

	if { [catch {$_commandHistory do $command} errorResult] } {
		if {$itk_option(-logger) != "" } {
			$itk_option(-logger) log_error $errorResult
		}
		$itk_component(entry) delete 0 end
		#return -code error $errorResult
	}
	$itk_component(entry) delete 0 end

}

body DCS::Prompt::moveUpHistory {} {
	$itk_component(entry) delete 0 end
	$itk_component(entry) insert 0 [$_commandHistory moveUpHistory]
}

body DCS::Prompt::moveDownHistory {} {
	$itk_component(entry) delete 0 end
	$itk_component(entry) insert 0 [$_commandHistory moveDownHistory]
}


class DCS::scrolledLog {
	inherit ::itk::Widget

    itk_option define -onDoubleClick onDoubleClick OnDoubleClick "" {
        bind [$itk_component(log) component text] <Double-1> $itk_option(-onDoubleClick)
    }

    itk_option define -extraTypes extraTypes ExtraTypes {
        addExtraType
    }

    private method addExtraType { }

	public method log
	public method log_error
	public method log_note
	public method log_warning
	public method log_command
	public method log_string
	public method clear
    private method createLogComponent
   public method bulkLog
    public method log_handle { file_handle }

	constructor { args } {
		
		itk_component add ring {
			frame $itk_interior.ring
		}


        createLogComponent
		eval itk_initialize $args

		pack $itk_component(ring) -expand yes -fill both
	}
}
body  DCS::scrolledLog::addExtraType { } {
    #### build-in types:
    set buildinList [list input output error warning note]

    set typeList $itk_option(-extraTypes)

    foreach {type color} $typeList {
        if {[lsearch -exact $buildinList $type] >= 0} {
            log_error bad extra type $type, already has buildin
            puts "bad extra type $type, already has buildin"
            continue
        }
	    $itk_component(log) tag add $type 1.0 end
	    $itk_component(log) tag configure $type -foreground $color
    }
}

body  DCS::scrolledLog::log_string { string type {timestamp 1} } {

	
	# enable modification of text window
	$itk_component(log) configure -state normal	

	if {$timestamp == 1 } {
		set time [clock format [clock seconds] -format "%d %b %Y %X"]
		$itk_component(log) insert end "\n$time  " output
	} else {
		$itk_component(log) insert end "\n" output
	}

	$itk_component(log) insert end $string $type
	
	#log_to_file "$time  $string"
	
	# disable modification of text window
	$itk_component(log) configure -state disabled
		
	# scroll window to show results
	$itk_component(log) see end
	$itk_component(log) xview moveto 0
}

body DCS::scrolledLog::log { args } { log_string "[join $args]" output }
body DCS::scrolledLog::log_command { args } { log_string "[join $args]" input }
body DCS::scrolledLog::log_error { args } { log_string "ERROR: [join $args]" error }
body DCS::scrolledLog::log_warning { args } { log_string "WARNING: [join $args]" warning }
body DCS::scrolledLog::log_note { args } { log_string "NOTE: [join $args]" note }
body DCS::scrolledLog::createLogComponent {} {
    if {[info exists itk_component(log)]} {
        itk_component delete log
        #delete object $itk_component(ring).log
        destroy $itk_component(ring).log
    }

	itk_component add log {
		iwidgets::scrolledtext $itk_component(ring).log \
		-state disabled \
        -vscrollmode dynamic \
        -hscrollmode dynamic \
        -wrap none \
        -textfont -*-courier-bold-r-*-*-12-*-*-*-*-*-*-*
	} {
		keep -background -relief -width -height
        keep -sbwidth -elementborderwidth
        keep -padx -pady
        keep -scrollmargin
    }
		
	$itk_component(log) tag add input 1.0 end
	$itk_component(log) tag configure input -foreground black -font "*-*-*-i-*--18-*-*-*-*-*-*-*"
	$itk_component(log) tag add output 1.0 end
	$itk_component(log) tag configure output -foreground black
	$itk_component(log) tag add error 1.0 end
	$itk_component(log) tag configure error -foreground red
	$itk_component(log) tag add warning 1.0 end
	$itk_component(log) tag configure warning -foreground brown
	$itk_component(log) tag add note 1.0 end
	$itk_component(log) tag configure note -foreground blue

	$itk_component(log) configure -background white
	pack $itk_component(log) -side left -expand yes -fill both
}
body DCS::scrolledLog::clear {} {
    createLogComponent
    addExtraType
    bind [$itk_component(log) component text] <Double-1> $itk_option(-onDoubleClick)
}

body DCS::scrolledLog::bulkLog { bulkLogRef } {
   upvar $bulkLogRef log

	# enable modification of text window
	$itk_component(log) configure -state normal	

   foreach logEntry $log {
      foreach {entryTime type text} $logEntry {
		   $itk_component(log) insert end "\n$entryTime  " output
	      $itk_component(log) insert end $text $type
      }
   }

	$itk_component(log) configure -state disabled	
    $itk_component(log) see end
	$itk_component(log) xview moveto 0
}

body DCS::scrolledLog::log_handle { file_handle } {
	# enable modification of text window
	$itk_component(log) configure -state normal	

    while {![eof $file_handle]} {
        set line [gets $file_handle]
        if {[llength $line] == 4} {
            foreach {entryTime type catlog text} $line {
		        $itk_component(log) insert end "\n$entryTime  " output
	            $itk_component(log) insert end "$catlog $text" $type
            }
        } else {
	        $itk_component(log) insert end $line error
        }
    }

	$itk_component(log) configure -state disabled	
    $itk_component(log) see end
	$itk_component(log) xview moveto 0
}

body DCS::commandHistory::do { args } {
	
	# concatenate arguments to create the command
	set command [join $args]
		
	# echo the command
	#log_command $command
	
	# add command to history list
	addHistory $command

	# execute the command at the global level and catch errors
	if { [catch {uplevel #0 $command} errorResult ] } {
		return -code error $errorResult
	}
}





	#	  DCS::scrolledLog .l
	#	  DCS::Prompt .p -text command -background white -logger .l
	#	  pack .p -expand yes -fill x
	#	  pack .l -expand yes -fill x


	#	  DCS::scrolledLog .l2 
	#	  DCS::Prompt .p2 -text command -background white -logger .l2
	#	  pack .p2 -expand yes -fill x
	#	  pack .l2
		  
