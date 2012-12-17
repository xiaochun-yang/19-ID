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

# provide the DiffIMage package
#package provide DiffIMage 1.0

package provide BLUICEDiffImage 1.0

# load standard packages
package require Iwidgets
package require http
ImgLibraryAvailable

# load other BIW packages
package require DCSUtil
package require DCSComponent

# The photo image type can be used as follows: 
# image create photo -file 
# or 
# image create photo -data ;#(base-64 encoding required with Tk8.2 and lower) 
# Valid format specifiers for reading photo's:
# 
#   "bmp"  
#   "gif -index <n>"  
#   "jpeg -fast -grayscale"  
#   "png"  
#   "tiff"  
#   "xbm"  
#   "xpm"  
#   "postscript -index <n> -zoom <x> <y>" (-index not yet implemented)  
#   "window" (works only with "-data", not "-file") 

# parameters
# -userName xxx
# -sessionId xxxx
# -sizeX 400
# -sizeY 400
# -zoom 1.0
# -gray 400
# -percentX 0.5
# -percentY=0.5

###################################################################
#
# DiffImage class
#
# This class represents a diffraction image. It knows how to load
# an image and header into memory which can then be used by
# DiffImageViewer.
#
###################################################################

class DiffImage {

	# inheritance
	inherit DCS::Component

	# public variables
	
	# Input parameters
	public variable userName		""
	public variable sessionId		""
	public variable mode 			"sync"
	public variable sizeX 			400
	public variable sizeY 			400
	public variable zoom 			400
	public variable gray 			400
	public variable percentX 		0.5
	public variable percentY 		0.5
	public variable imageType 		"full"; # imageType is either full or thumbnail
	
	# Output parameters
	private variable imageName
	private variable imageData
	private variable parameters		{}

	# private variables
	
	# Mandatory parameters for initializing DiffImage
	private variable host			""
	private variable port			""
	
	# Mandatory parameters for load() method
	private variable fileName		""

	# Internal variables
	private variable loading		0
	
	# Http protocol
	private variable httpObjName	""
	
	# Socket protocol
	private variable sock
	private variable connected		0

	private variable _encodingCalled		0

	# public methods
	public method load				{ file_name args }
	public method isLoading			{ }
	public method isError			{ }
	public method getParameters		{ }
	public method resize			{ x y }
	public method drawImage			{ }
	public method drawBlankImage	{ }
	
	# Callbacks for asyncronous http transaction
	public method loadImageCB		{ token }

	# private methods
	private method loadImage		{ }
	
	
	

	# Constructor
	constructor { server_host server_port image_name args } {
	
		set host $server_host
		set port $server_port	
		set imageName $image_name
		
		# Parse the arguments and set the public 
		# members that match the arguments
		eval configure $args
		
		# Setup an initial image
		# Later we will update the image with data coming from the imageObj.
		image create photo $imageName -palette 256/256/256 -format jpeg
	}
	
	# public member functions
	destructor {
	
		http::cleanup $httpObjName
		
	}
}


###################################################################
#
# Returns 1 if an image is being loaded and the transaction
# has not finished.
#
###################################################################
body DiffImage::isLoading { } {
	
	return $loading
}


###################################################################
#
# 
#
###################################################################
body DiffImage::resize { x y } {

}


###################################################################
#
# Returns 1 if an image is being loaded and the transaction
# has not finished.
#
###################################################################
body DiffImage::getParameters { } {

	return $parameters
}


###################################################################
#
# 
#
###################################################################
body DiffImage::isError { } {



	upvar #0 $httpObjName state

	if { [info exist state(error)] } {
		return 1
	} 
	
	return 0
}


###################################################################
#
# Load a new image file
# 
# Load the new image file as well as its header. Notice that the 
# header is loaded only when a new image file is loaded. 
#
###################################################################
body DiffImage::load { file_name args } {
	
	
	# Simple returns if the previous transaction
	# has not finished
	if { $loading != 0 } {
		return
	}
		
	set fileName $file_name
				
	
	# Parse the arguments and set the public 
	# members that match the arguments
	# If load() is called repeatedly before the current
	# transaction is finished, only the last load()
	# call 
	eval configure $args
		

	# Asyncronous call to load the image using 
	# current parameter settings
	loadImage
		
	
}



###################################################################
#
# httpLoadImage
#
###################################################################
body DiffImage::loadImage { } {


	# Get the image from the image server
	 if { [catch {
	 
	

		# Check if there is an outstanding transaction
		# Need to check this since the call to http::geturl is asyncronous
		# The loading flag is reset in finishLoad
		if { $loading != 0 }  {
			return
		}
	

		if { $imageType == "full" } {
			set command "getImage"
		} elseif { $imageType == "thumbnail" } {
			set command "getThumbnail"
		} else {
			return -code error "Invalid image type requested: $imageType"
		}


		# Indicate that we are now in the middle of a loading transaction
		set loading 1

        set SID [getTicketFromSessionId $sessionId]

		set url "http://$host:$port/$command?userName=$userName&sessionId=$SID&fileName=$fileName"

		append url "&sizeX=$sizeX&sizeY=$sizeY&zoom=$zoom&gray=$gray&percentX=$percentX&percentY=$percentY"

        #puts "image url: $url"


		# delete previous geturl result
		if { $httpObjName != "" } {
			http::cleanup $httpObjName
		}
							

		# Get the image from the image server
		if { $mode == "async" } {
				
			# None blocking call
			# The callback will be called after the transaction is finished.
			set httpObjName [http::geturl $url -binary 1 -command "$this loadImageCB" -timeout 60000]
						
		} else {
		
			# Block call until the transaction is finished
			set httpObjName [http::geturl $url -binary 1 -timeout 60000]
			
			# Call the callback directly
			loadImageCB $httpObjName
		}


	 } err ] } {

			# report the error
			puts "Error in DiffImage::httpLoadImage: $err"

			# Transaction failed
			set loading 0

			# Should we return an error here?
			return -code error "Error in DiffImage::httpLoadImage: $err"

	}
	

}

###################################################################
#
# http callback
# Display the loaded image on screen
# Do nothing since we display 
# the image automatically after loading
#
###################################################################
body DiffImage::loadImageCB { token } {
	
	set loading 0
	
}


###################################################################
#
# 
#
###################################################################
body DiffImage::drawBlankImage { } {
	# delete the previous photo
	image delete $imageName
}

###################################################################
#
# http callback
# Called when the http transaction is completed
#
###################################################################
body DiffImage::drawImage { } {

	
	 if { [catch {


		upvar #0 $httpObjName httpObj

		# Current status: pending, ok, eof or reset
		set status $httpObj(status)

		# Response first line
		set replystatus $httpObj(http)

		# First word in the respone first line
		set replycode [lindex $replystatus 1]

		if { $status != "ok" } {

			# http status is no ok.
			http::cleanup $httpObjName
			return -code error "Image server error: $replycode $status"

		} elseif { $replycode != 200 } {
			# http response code is not 200
			http::cleanup $httpObjName
			return -code error "Image server error: $replycode $status"

		} 


		# convert the image encoding to standard Tcl encoding (base64 encoding)

		# delete the previous photo
		image delete $imageName
						
		# create the Tcl photo from the jpeg data

        if { !$_encodingCalled } {
		    image create photo $imageName -palette 256/256/256 -format jpeg -data [encoding convertto iso8859-1 $httpObj(body)]
            set _encodingCalled 1
        } else {
		    image create photo $imageName -palette 256/256/256 -data $httpObj(body)
        }


		# Save http headers
				
		set parameters {}
		
		
		lappend parameters success
		
		
		if { [set i [lsearch -exact $httpObj(meta) wavelength] ] >= 0 } {
			lappend parameters [lindex $httpObj(meta) [expr $i+1]]
		} else {
			lappend parameters 0.0
		}

		if { [set i [lsearch -exact $httpObj(meta) distance] ] >= 0 } {
			lappend parameters [lindex $httpObj(meta) [expr $i+1]]
		} else {
			lappend parameters 0.0
		}

		if { [set i [lsearch -exact $httpObj(meta) originX] ] >= 0 } {
			lappend parameters [lindex $httpObj(meta) [expr $i+1]]
		} else {
			lappend parameters 0.0
		}
		
		if { [set i [lsearch -exact $httpObj(meta) originY] ] >= 0 } {
			lappend parameters [lindex $httpObj(meta) [expr $i+1]]
		} else {
			lappend parameters 0.0
		}

		if { [set i [lsearch -exact $httpObj(meta) pixelSize] ] >= 0 } {
			lappend parameters [lindex $httpObj(meta) [expr $i+1]]
		} else {
			lappend parameters 0
		}
		
		if { [set i [lsearch -exact $httpObj(meta) time] ] >= 0 } {
			lappend parameters [lindex $httpObj(meta) [expr $i+1]]
		} else {
			lappend parameters 0
		}

		if { [set i [lsearch -exact $httpObj(meta) detectorTypeC64] ] >= 0 } {
			lappend parameters [lindex $httpObj(meta) [expr $i+1]]
		} else {
			lappend parameters "unkown"
		}



		# delete the geturl result
		http::cleanup $httpObjName

		set loading 0

	
		
	 } err ] } {

			# report the error
			puts "Error in loadImageCB: $err"

			# Transaction failed
			set loading 0

			# Should we return an error here?
			return -code error "Error in loadImageCB: $err"

	}
	
}

