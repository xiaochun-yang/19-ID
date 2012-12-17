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

#package require Itcl 3.2
#namespace import ::itcl::*

#source ../test_scripts/binary_command.tcl


#Parent class handling generic socket and DCS protocols.  
class DcsConnection {
	# private data members
    protected variable m_useQuickParser 0
	protected variable m_dcsMsgs
	protected variable m_quickParser ""
    protected variable m_counter 0
    protected variable m_inProcessMsg 0
    protected variable m_saveRawMsg ""

	protected variable _state
	protected variable _textMessage ""
	protected variable _binaryMessage ""

	protected variable _accumulatedMessage ""
	protected variable _textSize
	protected variable _binarySize
	protected variable _headerLength 26
	protected variable _messageHandlers ""
	
	#public data members
	public variable _socket
	public variable _myaddr  ""
	public variable _myport  ""
	public variable _otheraddr  ""
	public variable _otherport  ""
	public variable _connectionGood	0
	public variable callback ""
	public variable networkErrorCallback ""
	
	public method constructor { socket args}
	public method destructor {} {puts "$this destroyed."}
	
	#public methods
	public method sendMessage { textMessage {binaryMessage ""} }
	public method handleReadableEvent {}
	public method quickHandleReadableEvent {}
	public method registerMessageHandler {callback}
	public method breakConnection {}
	public method send_to_server { message {messageSize 200} }
	# private member functions
	protected method informCallback {}

	protected method handleNetworkError { errorMessage }
	public method dcsConfigure {}
}

body DcsConnection::constructor { args } {
	set _state "HEADER"
	eval configure $args
    if {[llength [info commands NewDcsStringParser]]} {
        set m_useQuickParser 1
        set m_quickParser [NewDcsStringParser]
        puts "$this: DcsConnection Constructor use quick parser: $m_quickParser"
    } else {
        puts "$this: DcsConnection Constructor not found [info commands NewDcsStringParser]"
    }
    array set m_dcsMsgs [list]
}

body DcsConnection::dcsConfigure {} {
	fconfigure $_socket -translation binary -encoding binary -blocking 0 -buffering none
	# set up callback for incoming packets
    if {$m_useQuickParser} {
        puts "$this DcsConnection dcsConfigure set to quick handler"
	    fileevent $_socket readable "$this quickHandleReadableEvent"
    } else {
	    fileevent $_socket readable "$this handleReadableEvent"
    }
}

body DcsConnection::registerMessageHandler { callback} {
	append _messageHandlers $callback 
}

body DcsConnection::sendMessage { textMessage {binaryMessage ""} } {
    set logMsg [PRIVATEFilter $textMessage]
    set logMsg [SIDFilter $logMsg]
	print "$this: out-> $logMsg"
	if { ! $_connectionGood } {
		print "$this not connected"
		return
	}

	if { [catch {puts -nonewline $_socket [buildDcsMessage $textMessage $binaryMessage]} badresult]} {
		$this handleNetworkError "Error writing to $_otheraddr: $badresult"
		return
	} 
	
	if { [ catch { flush $_socket } badresult ] } {
		$this handleNetworkError "Error writing to $_otheraddr: $badresult"
	}
	#puts "sent"
}

#allows sending dcs protocol 1.0
body DcsConnection::send_to_server { message {messageSize 200} }  {
	print "[time_stamp] out-> $message"
	set length [string length $message]
	append message [string repeat " " [expr $messageSize - $length] ]
	
	#puts [string length $message]

	if { [catch {puts -nonewline $_socket $message} badresult]} {
		$this handleNetworkError "Error writing to $_otheraddr: $badresult"
		return
	} 
	
	if { [catch { flush $_socket } badresult ] } {
		$this handleNetworkError "Error writing to $_otheraddr: $badresult"
	}
}


body DcsConnection::handleReadableEvent {} {
	#puts "$this: readable event"
	
	# make sure socket connection is still open
	if { [eof $_socket] } {
		handleNetworkError "Connection closed by $_otheraddr."
		return
	}
	
	# read a message from the server
	if { [catch { read $_socket} message] } {
		handleNetworkError "Error reading from $_otheraddr: $message"
		return
	}

   set lengthReceived [string length $message]
	#puts "$this: $lengthReceived bytes"
	append _accumulatedMessage $message
	#dumpBinary $_accumulatedMessage

	while { [string length $_accumulatedMessage] > 0} {
		if { $_state == "HEADER" } {
			if { [string length $_accumulatedMessage] >= $_headerLength } {
				#store the complete dcs header without any following payload
				set dcsHeader [string range $_accumulatedMessage 0 $_headerLength]
				#store any remaining payload.
				set _accumulatedMessage [string range $_accumulatedMessage $_headerLength end]
				
				#Parse the header and get the text and binary sizes to follow
				#Remove null terminated string if necessary.
				set header [string trimright $dcsHeader \0]
				#puts $header
				set _textSize [lindex  $header 0]
				set _binarySize [lindex $header 1]
				
				if { $_textSize < 5} {
					puts "****************************** textSize: $_textSize"
				}
				#puts "binarySize: $_binarySize"
				#dumpBinary $_binarySize

				#calculate the next thing to expect over the socket
				if { $_textSize > 0 } {
					#text message expected next...
					set _state "TEXT"
				} elseif { $_binarySize > 0} {
					#header and binary data only...
					set _state "BINARY"
				} else {
					#empty header with no data...
					set _state "HEADER"	
				}
			} else {
				#We didn't get the complete header with that read.
				#Return until we have another read event.
				return
			}
		}
		
		if { $_state == "TEXT" } {
			#puts "Message text: got [string length $_accumulatedMessage] bytes"
			if { [string length $_accumulatedMessage] >= $_textSize } {
				#store the complete text message only
				set _textMessage [string range $_accumulatedMessage 0 [expr $_textSize - 1]]
				set _textMessage [string trimright $_textMessage \0]

				#store any remaining payload.
				set _accumulatedMessage [string range $_accumulatedMessage $_textSize end]
				
				#set binarySize [format "%d" $_binarySize]
				#encoding convertto [encoding system] $_binarySize
				if { $_binarySize > 0 } {
					#binary data is next...
					set _state "BINARY"
					#puts "binary size $_binarySize"
				} else {
					#message is text only. Wait for next header.
					set _state "HEADER"	
				}
			} else {
				#puts "incomplete $_state."
				#We didn't get the complete text message with that event.
				#Return until we have complete message
				return
			}
		}

		if { $_state == "BINARY" } {
			if { [string length $_accumulatedMessage] >= $_binarySize } {
				#store the complete text message only
				set _binaryMessage [string range $_accumulatedMessage 0 [expr $_binarySize -1]]
				#store any remaining payload.
				set _accumulatedMessage [string range $_accumulatedMessage $_binarySize end]

			#	dumpBinary $_binaryMessage

				#next thing should be a header again
				set _state "HEADER"	
			} else {
				#We didn't get the complete text message with that event.
				#Return until we have complete message
				return
			}
		}


		#Complete DCS message now collected
		#puts "$this: in <- text:$_textMessage binary:$_binaryMessage"

		$this informCallback


		# execute the message as a command in the messageHandler namespace
		
		
		#free up the potentially large binary message
		set _binaryMessage ""
	}
}


body DcsConnection::quickHandleReadableEvent {} {
    incr m_inProcessMsg

    #puts "enter quick: $m_inProcessMsg"
    # make sure socket connection is still open
    if { [eof $_socket] } {
        handleNetworkError "Connection closed by $_otheraddr."
        incr m_inProcessMsg -1
        return
    }
    
    if {[catch {eval $m_quickParser read $_socket} em]} {
        handleNetworkError "reading socket error:$em"
        incr m_inProcessMsg -1
        return
    }

    if {$m_inProcessMsg != 1} {
        puts "re-enter quickHandleReadableEvent: $m_inProcessMsg: $_textMessage"
    }

    if {[catch {
        while {[$m_quickParser get _textMessage _binaryMessage]} {
            #puts "$this: in <- text:$_textMessage binary:$_binaryMessage"

            if { [catch {$this informCallback} errorResult] } {
                #breakConnection
                global errorInfo
                puts $errorInfo

                incr m_inProcessMsg -1
                return -code error $errorResult
            }
        }
    } em] } {
        handleNetworkError "get message error:$em"
        incr m_inProcessMsg -1
        return
    }
    incr m_inProcessMsg -1
}

body DcsConnection::informCallback { } {
	if { $callback != "" } {
		$callback $_textMessage $_binaryMessage
	}
}



body DcsConnection::breakConnection {} {
	set _connectionGood	0
	
	print "$this closing socket..."
	#fileevent $_socket readable {}
	
	catch { close $_socket }
	#deconstruct this object
	#delete object $this
}

body DcsConnection::handleNetworkError { message } {
	print "$this : network error: $message"
	$this breakConnection
	set _textSize 0
	set _binarySize 0
	set _textMessage ""
	set _binaryMessage ""
	set _accumulatedMessage ""
	set _state "HEADER"
    if {$m_useQuickParser} {
        $m_quickParser clear buffer
        set m_counter 0
    }

	eval $networkErrorCallback

	#destroy $this
}



# The DcsClientSocket allows the basic DCS protocol and
# variable length message reading and recieving,
# but does not provide master/slave handling with DCSS. 
class DcsClient {
	inherit DcsConnection
	#configurable data members
	public variable _reconnectTime 5000

	# public member functions
	public method constructor { otherAddress otherPort args }
	public method connect { }
	public method handleNetworkError { errorMessage}
	


}


body DcsClient::constructor { otherAddress otherPort args } {
	set _otheraddr $otherAddress
	set _otherport $otherPort
	eval configure $args
}




body DcsClient::connect { } {
	# disconnect from server if currently connected
	if { $_connectionGood } {
		$_socket configure -connectionGood 0
		$_socket breakConnection
	}

	print "$this connecting to server $_otheraddr on port $_otherport..."
	#log_note "Connecting to server $_otheraddr on port $_otherport."

	if { [catch { socket $_otheraddr $_otherport } result] } {
		handleNetworkError "$this could not connect: $result"
		return
	}
 
	set _socket $result
	print "$this has handle $_socket"
	
	$this dcsConfigure
	set _connectionGood 1
}



body DcsClient::handleNetworkError { errorMessage } {
	log_error "Disconnecting from server. $errorMessage"
	print "$this : network error: $errorMessage"
	if { $_connectionGood} {
		$this breakConnection
	}
	
	set _textSize 0
	set _binarySize 0
	set _textMessage ""
	set _binaryMessage ""
	set _accumulatedMessage ""
	set _state "HEADER"
    if {$m_useQuickParser} {
        $m_quickParser clear buffer
        set m_counter 0
    }
	
	eval $networkErrorCallback
	after $_reconnectTime "$this connect $_myport"
}


class AcceptedDcsClient {
	inherit DcsConnection
	private variable _serverName ""

	protected method informCallback {}
	public method handleNetworkError {message}
	public method constructor {serverName sockHandle clientsAddress clientsPort args } {}
}

body AcceptedDcsClient::constructor {serverName sockHandle clientsAddress clientsPort args} {
	set _serverName $serverName
	set _socket $sockHandle
	set _otheraddr $clientsAddress
	set _otherPort $clientsPort
	#set _myaddr $myaddr
	#set _myport $myport
	print "$_serverName received client connection from $clientsAddress"

	print "created $this for client handler.  "

	fconfigure $_socket -translation binary -encoding binary -blocking 0
    if {$m_useQuickParser} {
	    fileevent $_socket readable "$this quickHandleReadableEvent"
    } else {
	    fileevent $_socket readable "$this handleReadableEvent"
    }

	eval configure $args

	set _connectionGood 1
}


body AcceptedDcsClient::informCallback { } {
	if { $callback != "" } {
		eval [concat $callback {$this $_textMessage $_binaryMessage }]
	}
}

body AcceptedDcsClient::handleNetworkError {message } {
	print "$this network error: $message"
	if { [catch {close $_socket} result] } {
		print "closed socket with result: $result"
	} else {
		$_serverName removeClient $this
	}
	#deconstruct this object
	delete object $this
}

class DcsServer {
	private variable _socket
	private variable _myaddr
	private variable _myport
	private variable _connectedClients ""

	public method constructor {args}
	public method enable {}
	public method socketAcceptHandler { sock addr port }
	public method broadcastMessage { textMessage {binaryMessage ""}}
	public method removeClient { clientName}
	public method handleClientMessage { clientName textMessage binaryMessage }
	protected method dcsSocketConfigure {}
}

body DcsServer::constructor { listeningPort args } {
	set _myport $listeningPort
	eval configure $args
}

body DcsServer::enable {} {
	set _socket [socket -server "${this} socketAcceptHandler" $_myport]

	print "enabled server $_socket"
	#set _socket [socket -server $this::socketAcceptHandler]
}

body DcsServer::socketAcceptHandler { sock addr port } {
	print "$_socket accepted $sock from $addr $port"
	
	AcceptedDcsClient $this$sock $this $sock $addr $port -callback "$this handleClientMessage"
	lappend _connectedClients $this$sock
}

body DcsServer::broadcastMessage { textMessage {binaryMessage ""}} {
	foreach client $_connectedClients {
		$client sendMessage $textMessage $binaryMessage
	}
}

body DcsServer::removeClient {clientName} {
	#remove the client from the list
	set index [lsearch $_connectedClients $clientName]
	if { $index >= 0 } {
		set _connectedClients [lreplace $_connectedClients $index $index]
	}
}

body DcsServer::handleClientMessage {clientName textMessage binaryMessage} {
	$this broadcastMessage $textMessage $binaryMessage
	#dumpBinary $textMessage
	#dumpBinary $binaryMessage	
}


# The DcssClient class provides 
# 1) DCS protocol with variable length message 
#    reading and recieving, and
# 2) Master/slave handling with DCSS.
class DcssClient {
	inherit DcsClient
	private variable isMaster			0
	
	# public member functions
	constructor  {server port args} {DcsClient::constructor $server $port} {
		eval configure $args
	}
	public method is_master {}
	public method setMaster { state } { set isMaster $state}
}

body DcssClient::is_master {} {
	return $isMaster
}

proc buildDcsMessage { textMessage binaryMessage} {
	set textLength [string length $textMessage]
	set binaryLength [string length $binaryMessage]
	
	set header [format "%12d %12d" $textLength $binaryLength]
	
	return "${header} ${textMessage}${binaryMessage}"
}


#
class DcssHardwareClient {
	inherit DcsClient
	private variable isMaster			0

	public variable hardwareName ""
	# public member functions
	constructor  {server port args} {DcsClient::constructor $server $port} {
		eval configure $args
        #set m_useQuickParser 0
	}
	
	public method dcsConfigure {}
	public method handleFirstReadableEvent {}
    public method handleNetworkError { errorMessage }
}

body DcssHardwareClient::handleNetworkError { errorMessage } {
	log_error "Disconnecting from server. $errorMessage"
	print "$this : network error: $errorMessage"
	if { $_connectionGood} {
		$this breakConnection
	}
	
	set _textSize 0
	set _binarySize 0
	set _textMessage ""
	set _binaryMessage ""
	set _accumulatedMessage ""
	set _state "HEADER"
    if {$m_useQuickParser} {
        $m_quickParser clear buffer
        set m_counter 0
    }
	
	eval $networkErrorCallback
	after $_reconnectTime "$this connect $_myport"
}

body DcssHardwareClient::dcsConfigure {} {
	#program the reading to be blocking until the connection is established later.
	fconfigure $_socket -translation binary -encoding binary -blocking 1 -buffering none
	# set up callback for incoming packets
    fileevent $_socket readable "$this handleFirstReadableEvent"
}

body DcssHardwareClient::handleFirstReadableEvent {} {
	# make sure socket connection is still open
	if { [eof $_socket] } {
		handle_network_error "Connection closed to server."
		return
	}

	# read a message from the server
	if { [catch {set message [read $_socket 200]}] } {
		handle_network_error "Error reading from server."
		return
	}

   set lengthReceived [string length $message]
	
	#reprogram the event handler to be non-blocking
	fconfigure $_socket -translation binary -encoding binary -blocking 0 -buffering none
	send_to_server "htos_client_type_is_hardware $hardwareName dcsProtocol_2.0" 200
    if {$m_useQuickParser} {
        puts "in hardware setup quick parser"
        $m_quickParser clear buffer
	    fileevent $_socket readable "$this quickHandleReadableEvent"
    } else {
	    fileevent $_socket readable "$this handleReadableEvent"
    }
	
}


proc buildDcsMessage { textMessage binaryMessage} {
	set textLength [string length $textMessage]
	set binaryLength [string length $binaryMessage]
	
	set header [format "%12d %12d" $textLength $binaryLength]
	
	return "${header} ${textMessage}${binaryMessage}"
}




