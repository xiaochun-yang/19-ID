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

# load the MDI package
package require BIWMDI


######################################################################
# initialize_mdw_window -- intializes the mdw_lib parameters
######################################################################

proc initialize_mdw_window {} {

	# global variables
	global mdw_main
	global gWindows
	global gColors

	# create the frame to hold the MDI interface
	pack [frame $gWindows(mdw,frame).mdw_frame] -fill both -expand true

	# create the mdi interface
	MDICanvas mdi $gWindows(mdw,frame).mdw_frame -background $gColors(midhighlight)
}


proc create_mdw_document { doc title width height constructor {destructor {}} } {

	# global variables
	global gDocument

	# fill in document structure
	set gDocument($doc,title)			$title
	set gDocument($doc,construct)		$constructor
	set gDocument($doc,destruct)		$destructor
	set gDocument($doc,width)			[expr $width - 4]
	set gDocument($doc,height)			[expr $height - 28]
	set gDocument($doc,activateCommand) {}
}


proc show_mdw_document { doc } {

	# global variables
	global gDocument
	
	if { [mdw_document_exists $doc] } {
		activate_mdw_document $doc
		return 1		
	} else {
		construct_mdw_document $doc
		set gDocument($doc,frame) [mdi getDocumentInternalFrame $doc]
		eval $gDocument($doc,construct) $gDocument($doc,frame)
		return 0
	}	
}


proc activate_mdw_document { doc } {

	# global variables
	global gDocument

	mdi activateDocument $doc
}


proc destroy_mdw_document { doc } {
	
	# global variables
	global gDocument
	
	# call custom destructor for document
	eval $gDocument($doc,destruct)
	
	# inform mdw_main of the destruction
	mdi deleteDocument $doc
}


proc destroy_mdw_window { doc } {
	
	# global variables
	global gDocument
	
	# call custom destructor for document
	eval $gDocument($doc,destruct)
}


proc construct_mdw_document { doc } {

	# global variables
	global gDocument
	
	mdi addDocument $doc \
		 -width $gDocument($doc,width) \
		 -height $gDocument($doc,height) \
		 -title $gDocument($doc,title) \
		 -isResizable 0 \
		 -activationCallback activate_mdw_window \
		 -destructionCallback destroy_mdw_window

	set gDocument(document,$doc) $doc
	set gDocument($doc,activateCommand) ""

	activate_mdw_document $doc
}


proc mdw_document_exists { doc } {

	# global variables
	global gDocument
	
	return [mdi documentExists $doc]	
}


proc activate_mdw_window { doc } {

	# global variables
	global gDevice
	global gDocument

	set command $gDocument($doc,activateCommand)
	if { $command != "" } {
		eval $command
	}
	
	if { $gDevice(control,motor) == "" } {
		return
	}

	if { $doc == $gDevice($gDevice(control,motor),component) } {
		return
	}

	if { $gDevice($gDevice(control,motor),selectedWindow) == "" } {
		select_motor none		
		return
	}		

	if { $doc == $gDevice($gDevice(control,motor),selectedWindow) } {
		return
	}

	select_motor none

}
