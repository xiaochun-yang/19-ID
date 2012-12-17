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


###################################################################
#
# DiffImage class
#
# This class represents a diffraction image. It knows how to load
# an image and header into memory which can then be used by
# DiffImageViewer.
#
# Uses image_channel in tcl_clibs to load and display jpeg image.
#
###################################################################

package provide BLUICECDiffImage 1.0

loadAuthenticationProtocol1Library

class CDiffImage {

	# inheritance
	inherit DCS::Component

	# public variables
	
	# Input parameters
	public variable userName		""
	public variable sessionId		""
	public variable mode 			"sync"

   #Bug Warning: the next two lines for some reason can sometimes affect the maximum size
   #  of the image.  The image dynamically resizes, so it is unclear why this could occur. 
	public variable sizeX 			1200
	public variable sizeY 			1200

	public variable zoom 			400
	public variable gray 			400
	public variable percentX 		0.5
	public variable percentY 		0.5
	
	public variable protocol 		"2"; # authentication protocol is 1 or 2
	
	# Output parameters
	private variable imageName
	private variable parameters		{}

	# private variables
	private variable fileName		""
	
	# Mandatory parameters for initializing DiffImage
	private variable host			""
	private variable port			""
	
	# Mandatory parameters for load() method

	# Internal variables
	private variable loading		0
	private variable pollperiod		100
	private variable pollingId		0
		
	
	# public methods
	public method load				{ file_name args }
	public method isLoading			{ }
	public method isError			{ }
	public method getParameters		{ }
	public method resize			{ x y }
	public method drawImage			{ }
	public method drawBlankImage	{ }
	
	# Private method
	private method getRequest		{ }
	
	private common _maxChannels 10
	private common _numChannels 0

	#allocate 10 channels
	image_channel_allocate_channels $_maxChannels
	

	# Constructor
	constructor { server_host server_port image_name args } {
		
		if { $_numChannels >= $_maxChannels } {
			return -code error "Maximum number of image channels exceeded."
		}
		
		#puts " $server_host $server_port $image_name $args"

		set host $server_host
		set port $server_port	
		set imageName $image_name
		
		# Parse the arguments and set the public 
		# members that match the arguments
		eval configure $args
		
		# Setup an initial image
		# Later we will update the image with data coming from the imageObj.
		image create photo $imageName -palette 8/8/8 -format jpeg

		# Call C code to create a socket connection to the imgsrv
		#puts "image_channel_create $imageName $host $port $protocol $sizeX $sizeY $userName"
		image_channel_create $imageName $host $port $protocol $sizeX $sizeY $userName
		incr _numChannels
	}
	
	# public member functions
	destructor {
	
		image_channel_delete $imageName

		incr _numChannels -1
	
		if { $_numChannels < 0 } {
			set _numChannels 0
		}
	}
}


###################################################################
#
# Returns 1 if an image is being loaded and the transaction
# has not finished.
#
###################################################################
body CDiffImage::isLoading { } {
	
	if { [image_channel_load_complete $imageName] } {
		set loading 0
	} else {
		set loading 1
	}
	
	return $loading

}

###################################################################
#
# 
#
###################################################################
body CDiffImage::resize { x y } {

	set sizeX $x
	set sizeY $y

	# set the image channel size
	#puts "RESIZE $imageName $sizeX $sizeY"
	image_channel_resize $imageName $sizeX $sizeY
}


###################################################################
#
# Returns 1 if an image is being loaded and the transaction
# has not finished.
#
###################################################################
body CDiffImage::getParameters { } {

	return $parameters
}


###################################################################
#
# 
#
###################################################################
body CDiffImage::isError { } {

	set err [image_channel_error_happened $imageName]
	
	return $err 
}


###################################################################
#
# 
#
###################################################################
body CDiffImage::drawBlankImage { } {

	image_channel_blank $imageName
}

###################################################################
#
# Returns 1 if an image is being loaded and the transaction
# has not finished.
#
###################################################################
body CDiffImage::drawImage { } {


	if { [isLoading] } {
		if { $pollingId == 0 } {
			set pollingId { [ after $pollperiod "$this finish_load" ] }
		}
		return
	}

	set pollingId 0

	# Display the image in the canvas
	# Get the image parameters from cache and 
	set parameters [image_channel_update $imageName]
}


###################################################################
#
# 
#
###################################################################
body CDiffImage::getRequest {} {

	# Default protocol is "new"
	if { $protocol == "1" } {
		set request "$fileName $sizeX $sizeY $zoom $gray $percentX $percentY"
	} else {
		set request "$userName $sessionId $fileName $sizeX $sizeY $zoom $gray \
				 	 $percentX $percentY"
	
	}	
	
	return $request
}

###################################################################
#
# Load a new image file
# 
# Load the new image file as well as its header. Notice that the 
# header is loaded only when a new image file is loaded. 
#
###################################################################
body CDiffImage::load { file_name args } {
	
	
	# Simple returns if the previous transaction
	# has not finished
	if { [isLoading] } {
		return
	}
		
	set fileName $file_name
				
	
	# Parse the arguments and set the public 
	# members that match the arguments
	# If load() is called repeatedly before the current
	# transaction is finished, only the last load()
	# call 
	eval configure $args
	
	# load the file	in image_channel cache
	#puts 	"image_channel_load $imageName $mode [getRequest]"

	image_channel_load $imageName $mode [getRequest]
}


