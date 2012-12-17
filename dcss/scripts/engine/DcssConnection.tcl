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

class DcssConnection {

	# private data members
	private variable serverName		""
	private variable listeningPort	""
	private variable connectionGood	0
	private variable socket				""
	private variable blank				""
	private variable messageBuffer	""
	private variable buffercount		0

	# public member functions	
	public method constructor { server port }
	public method connect { port }
	public method handle_socket_readable_event {}
	public method send_to_server { message }

	# private member functions
	private method break_connection {}
	private method handle_network_error { errorMessage }
}



body DcssConnection::constructor { server port } {

	# store the server name
	set serverName $server

	# store the listening port
	set listeningPort  $port
	
	for { set i 0 } { $i < 4 } { incr i } {
		append blank "                                                  "
	}

}


body DcssConnection::connect { port } {

	# global variables
	global gWindows
	
	# use default port if default requested
	if { $port == "listener" } {
		set port $listeningPort
	}
	
	# disconnect from server if currently connected
	if { $connectionGood } {
		set connectionGood 0
		break_connection
	}

	log_note "Connecting to server $serverName \
		on port $port..."

	if { [catch {set newSocket [socket $serverName $port] } error] } {
		log_warning "Unable to connect to server:  $error"
		after 5000 "$this connect $port"
		return
	}

	# record success
	set socket $newSocket
	set connectionGood 1
	set messageBuffer ""
	
	# make socket nonblocking
	fconfigure $socket -blocking 0 -translation binary

	# set up callback for incoming packets
	fileevent $socket readable "$this handle_socket_readable_event"
}


body DcssConnection::break_connection {} {

	set connectionGood	0
	log_note "Disconnecting from server..."
	fileevent $socket readable {}
	catch { close $socket }
}



body DcssConnection::handle_socket_readable_event {} {

	# make sure socket connection is still open
	if { [eof $socket] } {
		handle_network_error "Connection closed to server."
		return
	}

	# read a message from the server
	if { [catch {set message [read $socket 200]}] } {
		handle_network_error "Error reading from server."
		return
	}

   set lengthReceived [string length $message]

	# concatenate new message with current message buffer
	append messageBuffer $message	
	incr buffercount [string length $message]

	while { [string length $messageBuffer] >= 200 } {

		# get next block of 200 characters
		set currentMessage [string range $messageBuffer 0 199]

		# remove the block from the message buffer
		set messageBuffer [string range $messageBuffer 200 $buffercount]

		incr buffercount -200
		
		# throw away any information after the first NULL character
		set currentMessage [lindex [split $currentMessage \x00] 0]

		# return if no text in message
		if { $currentMessage == "" } {
			return
		}
		
		print "[time_stamp] SELF in <- $currentMessage"

		# break connection if a bad message is parsed
		if { [string range $currentMessage 1 2] != "to" } {
			log_error $currentMessage
			handle_network_error "Bad message from server."
			return
		}
		
		# execute the message as a command
		global gDevice
		set gDevice(lastMessageSource) $this
		if { [ catch {uplevel #0 $currentMessage } error ] } {
			log_note $error
		}
	}
}


body DcssConnection::send_to_server { message } {

	print "[time_stamp] SELF out-> $message"
	set length [string length $message]
	append message [string range $blank 0 [expr 199 - $length] ]
	print "Ready to send message to DCSS of length $length..."

	if { [ catch { puts -nonewline $socket $message } ] || \
		[ catch { flush $socket } ] } {
		handle_network_error "Error writing to server."
	}
}


body DcssConnection::handle_network_error { errorMessage } {

	log_error $errorMessage
	reset_all
	break_connection
	after 5000 "$this connect listener"
}
