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



###################################################################
#
# DiffImageViewer class
#
# A class that creates an image canvas and a control panel convas
# in a given frame window. The control panel allows the user to 
# adjust zoom/pan/contrast, change session id and load a new image.
# 
# This class is responsible for displaying the canvases and handling
# the window/mouse events. The display of the image is handled by 
# the image object which is an instance of either CDiffImage 
# or TclDiffImage. CDiffImage uses tcl_clibs retrive the image from
# the image server via socket and displays it using Tk_xxx C functions. 
# DiffImage uses pure tcl to retrieve the image from the image server
# via http and displays it using tcl image command. 
#
###################################################################
class DiffImageViewer {

	# public data members
	public variable protocol		"http"; # protocol can be http, old or new
	
	# Variable which can be set in the command 
	# line arguments of the constructor
	public variable userName		""
	public variable sessionId		""
	public variable filename		""
	public variable debug			0

	# private data members
	private variable zoom			1.0
	private variable contrastMax	400
	private variable image			""
	private variable resolutionText ""
	private variable lastDirectory "/data/$env(USER)"
	private variable centerx		0.5
	private variable centery		0.5
	private variable width			400
	private variable height	     	400
	private variable pollperiod		200		
	
	private variable wavelength     1.0
	private variable distance       100
	private variable displayOriginX 0
	private variable displayOriginY 0
	private variable jpegPixelSize 	"1"
	private variable exposureTime
	private variable detectorType 	""

	private variable name			""
	private variable status 		"No Image"	
	private variable imageObj
	private variable imageCanvas	""
	private variable imageValid		0
	
	# Gui constants	
	private variable smallFont 		*-helvetica-bold-r-normal--14-*-*-*-*-*-*-*
	private variable largeFont		*-helvetica-bold-r-normal--18-*-*-*-*-*-*-*
	
	# Variables bound to widgets
	private variable contrastEntryVar
	private variable zoomEntryVar
	private variable sessionIdEntryVar
	private variable filenameEntryVar
	
	# performance measurements
	private variable totalTime		0
	private variable updateCount	0
	private variable fastest		0
	private variable slowest		0
	private variable datapoints		{ }

	

	# Constructor
	public method constructor { frame serverName listeningPort imageWidth imageHeight args }
	
	# Destructor
	public method destructor {
		image_channel_delete $name
	}

	# Public member functions
	public method isImageValid { }
	public method load { user_name session_id path }
	public method finish_load {}
	public method zoom_at { z }
	public method zoom_by { factor }
	public method set_contrast_max { max }
	public method change_contrast_max_by { delta }
	public method pan_horiz { delta }
	public method pan_vert { delta }
	public method recenter_at { x y }
	public method handle_contrast_max_entry {}
	public method handle_sessionid_entry {}
	public method browse_dir {}
	public method handle_filename_entry {}
	public method handle_zoom_entry {}
	public method set_zoom { value }
	public method view_with_adxv {}
 	public method handle_resize {} 
 	public method handle_mouse_motion {x y} 
	public method handle_mouse_exit {}	
	public method handle_right_click_load {}

	# private member functions
	private method redraw_image {}
	private method update_image {}
	private method update_filename_entry { path }
	private method do_load {user_name session_id path }
	private method do_update_image {}
	private method update_status { text }
	private method analyse_performance { str } 
	

}


###################################################################
#
# Public method
# Returns imageValid variables: 1 if the image is valid and 0 otherwise.
# imageValid variable is set to 0 every time the image is loaded.
# When the loading is done, imageValid is set to 1 to indicating that
# the loading is finished successfully. In case of error while loading,
# imageValid will remain as 0. The callbacks for mouse or widgets 
# events should check this value before proceeding.
#
###################################################################
body DiffImageViewer::isImageValid { } {

	return $imageValid
	
}

###################################################################
#
# Public method
# Load a new image from the given file path from the image server
# Using asyncronous loading. When running in debug mode, this method
# measures the time to load/update the image. 
#
###################################################################
body DiffImageViewer::load { user_name session_id path } {

	if { $debug } {
		set str [time {do_load $user_name $session_id $path}]
		analyse_performance $str
	} else {
		do_load $user_name $session_id $path
	}
	
}

###################################################################
#
# Public method
# Load a new image from the given file path from the image server
# Using asyncronous loading. The image loading and displaying are
# performed by CDiffImage or DiffImage class. This method calls 
# finish_load to wait for the loading to finish.
#
###################################################################
body DiffImageViewer::do_load { user_name session_id path } {


	# Ask the caller to try again later if we have not finished
	# the previous transaction
	if { [imageObj isLoading] } {
		return -code error "Busy: try again later"
	}

	# update filename text entry box	
	update_filename_entry $path

	
	# Update text at cursor position
	update_status "Loading..."

	# image is now invalid
	set imageValid 0

	# store the filename
	set userName $user_name
	set sessionId $session_id
	set filename $path
	
	if { $filename == "" } {
		imageObj drawBlankImage
		return
	}
	
	# Make sure that width and height are the actual 
	# width and height of the canvas. Otherwise we will get
	# a redraw event after the image is displayed (which
	# in turn causes a redraw), causing 
	# double redraw.
	set width [winfo width $imageCanvas]
	set height [winfo height $imageCanvas]
	

	imageObj resize $width $height

	# Ansycronous call to load an image from the image server
	# If DiffImage is in the middle of loading another image,
	# that transaction will be cancelled.
	imageObj load 	 $filename 	\
					 -userName $userName -sessionId $sessionId \
					 -sizeX $width -sizeY $height	\
					 -zoom $zoom -gray $contrastMax \
					 -percentX $centerx -percentY $centery \
					 -mode async


	# Wait for the image to be ready
	# then display it
	finish_load


}


###################################################################
#
# private method
# Set text at cursor position
#
###################################################################
body DiffImageViewer::update_status { text } {

	set status $text

	#update the cursor with the new resolution
	set x [expr [winfo pointerx $imageCanvas] - [winfo rootx $imageCanvas] ]
	set y [expr [winfo pointery $imageCanvas] - [winfo rooty $imageCanvas] ]
	$this handle_mouse_motion $x $y

}

###################################################################
#
# Public method
# Called after pollperiod time out. Check if the image loader has
# indicated that the loading is finished. If so, redraw the image
# on the canvas.
#
###################################################################
body DiffImageViewer::finish_load { } {

	# wait here while the image is being loaded
	while { [imageObj isLoading] } {
#		puts "waiting for 200 msec"
		if { [imageObj isError] } {
			puts "Loading failed"
			update_status "Loading failed"
			imageObj drawBlankImage
			return
		}
		after $pollperiod
	}
	

	if { [catch {
				

		if { [imageObj isError] } {
			puts "Loading failed"
			update_status "Loading failed"
			imageObj drawBlankImage
			return
		}

		# image is now valid
		set imageValid 1

		# Redraw the image and cursor		
		redraw_image
		
		
	} err] } {

		set imageValid 0
		puts "Error in finish_load: $err"
		update_status "Loading failed"
		imageObj drawBlankImage
#		return -code error "caught an error in finish_load"
	}
	
}


###################################################################
#
# private method
# Update display
#
###################################################################
body DiffImageViewer::redraw_image {} {

	# Display the image on screen
	imageObj drawImage

	# Update the header parameters
	set imageParameters [imageObj getParameters]

	set wavelength     [lindex $imageParameters 1]
	set distance       [lindex $imageParameters 2]
	set displayOriginX [lindex $imageParameters 3]
	set displayOriginY [lindex $imageParameters 4]
	set jpegPixelSize  [lindex $imageParameters 5]
	set exposureTime   [lindex $imageParameters 6]
	set detectorType   [lindex $imageParameters 7]


	#update the cursor with the new resolution
	set x [expr [winfo pointerx $imageCanvas] - [winfo rootx $imageCanvas] ]
	set y [expr [winfo pointery $imageCanvas] - [winfo rooty $imageCanvas] ]
	$this handle_mouse_motion $x $y


	# Update last dir	
	set lastDirectory [string range $filename 0 [string last "/" $filename]]

}


###################################################################
#
# private method
# Called when an image viewing setting has changed such as zoom level.
# Need to reload the image with the new parameters.
#
# Syncronous loading
#
###################################################################
body DiffImageViewer::update_image {} {

	if { $debug } {
		set str [time { do_update_image } ]	
		analyse_performance $str
	} else {
		do_update_image
	}
}


###################################################################
#
# private method
# 
#
###################################################################
body DiffImageViewer::do_update_image {} {

	set imageValid 0
	
	imageObj load 	$filename 	\
					 -userName $userName -sessionId $sessionId \
					 -sizeX $width -sizeY $height	\
					 -zoom $zoom -gray $contrastMax \
					 -percentX $centerx -percentY $centery \
					 -mode sync

		
	# make sure the load was successful
	if { [imageObj isError] } {
		puts "Loading failed."
		update_status "Loading failed"
		imageObj drawBlankImage
		return
	}

	set imageValid 1

	# Drawing the image, cursor
	redraw_image

	# Do miscellaneous task on idle
	update idletasks
} 

###################################################################
#
# private method
# 
#
###################################################################
body DiffImageViewer::analyse_performance { str } {

	set timeInMsec 0.0
	
	if { [regexp {([0123456789]+) microseconds per iteration} $str match timeInMsec] != 1} {
		puts "Failed to extract time"
		return
	}
	
	# convert usec to msec
	set timeInMsec [expr $timeInMsec / 1000.0]
	
	# Sum of time and runs
	set totalTime [expr $totalTime + $timeInMsec]
	set updateCount [expr $updateCount + 1]
	
	# Safe data points for standard deviation
	lappend datapoints $timeInMsec
	
	# Safe slowest and fastest data points
	if { $updateCount < 2 } {
		set fastest $timeInMsec
		set slowest $timeInMsec
	} else {
	
		if { $fastest > $timeInMsec } {
			set fastest $timeInMsec
		}

		if { $slowest < $timeInMsec } {
			set slowest $timeInMsec
		}
	}
	
	# Calculate Mean
	set ave [expr $totalTime / $updateCount ]
	
	# Calculate Variance
	set variance 0.0
	set SD 0.0
	set x 0.0
	
	if { $updateCount > 1 } {
		set count 0
		foreach { point } $datapoints {
			incr count 1
			set x [expr [expr $point - $ave]*[expr $point - $ave] ]
			set variance [expr $variance +  $x]
		}
		
		set tot [expr $updateCount - 1]
		set variance [expr $variance/$tot]

		# Calculate Standard deviation
		set SD [expr sqrt($variance)]
		
	}
	
	# Print result
	puts "Num runs = $updateCount"
	puts "Sum time = $totalTime msec"
	puts "fastest  = $fastest msec"
	puts "slowest  = $slowest msec"
	puts "Average  = $ave msec"
	puts "variance = $variance"
	puts "SD       = $SD"
	puts " "
	
}	

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::handle_contrast_max_entry {} {


	upvar #0 $contrastEntryVar c
	

	# get new value from entry field
	set newMax $c
	
	if { $newMax == $contrastMax } {
		return
	}
	
	# reset entry value if invalid
	if { ![is_positive_int $newMax] || [imageObj isLoading]} {
		set c $contrastMax	
	} else {
		set_contrast_max $newMax
	}
}

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::browse_dir {} {
	
	handle_right_click_load

}

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::update_filename_entry { path } {

	upvar #0 $filenameEntryVar s
	
	set s $path
}

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::handle_filename_entry {} {
	
	upvar #0 $filenameEntryVar s

	# get new value from entry field
	set newfile [string trim $s]
	
	
	if { $newfile != "" } {
		if {$newfile == $filename} {
			return
		}
	}

	# reset entry value if invalid
	if { [imageObj isLoading] } {
		set s $filename
	} else {
		$this load $userName $sessionId $newfile
	}
}

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::handle_sessionid_entry {} {
	
	upvar #0 $sessionIdEntryVar s

	# get new value from entry field
	set id [string trim $s]
	
	if { $id == "" } {
		return
	}
	
	if {$id == $sessionId} {
		return
	}

	# reset entry value if invalid
	if { [imageObj isLoading] } {
		set s $sessionId
	} else {
		set sessionId $id
		update_image
	}
}

###################################################################
#
# 
#
###################################################################

body DiffImageViewer::zoom_at { newZoom } {

	upvar #0 $zoomEntryVar z

	set z $newZoom
	
	handle_zoom_entry
}

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::handle_zoom_entry {} {
	
	upvar #0 $zoomEntryVar z

	# get new value from entry field
	set newZoom $z
	
	if {$newZoom == $zoom} {
		return
	}

	# reset entry value if invalid
	if { ![is_positive_float $newZoom] || $newZoom <= 0 || [imageObj isLoading]} {
		set z $zoom
	} else {
		set_zoom $newZoom
	}
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::zoom_by { factor } {
	

	if { [imageObj isLoading] } {
		return
	}

	# calculate new value for zoom
	set zoom [expr $zoom * $factor]

	# update the diffimage object
	set_zoom $zoom
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::set_zoom { value } {
	
	
	if { ! $imageValid } {
		return
	}

	# store the new zoom value
	set zoom [format "%.2f" $value]

	# make sure zoom is not too small
	if { $zoom < 0.01 } {
		set zoom 0.01
	}

	# update the entry field value
	upvar #0 $zoomEntryVar z
	set z $zoom

	# update the diffimage object
	update_image
}





###################################################################
#
# 
#
###################################################################
body DiffImageViewer::set_contrast_max { max } {
	
	if { ! $imageValid } {
		return
	}

	# store new value of contrast max
	set contrastMax $max

	# update the entry field
	upvar #0 $contrastEntryVar c
	set c $contrastMax

	# update the diffimage object
	update_image
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::change_contrast_max_by { delta } {
	
	if { ! $imageValid } {
		return
	}

	# calculate new value of contrast max
	set_contrast_max [expr $contrastMax + $delta]
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::pan_horiz { delta } {
		
	if { ! $imageValid } {
		return
	}

	$this recenter_at [expr $width / 2 + $delta * $width / 2] [expr $height / 2 ]
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::pan_vert { delta } {
	
	if { ! $imageValid } {
		return
	}

	$this recenter_at [expr $width / 2] [expr $height / 2 + $delta * $height / 2]
}


###################################################################
#
#
#
###################################################################
body DiffImageViewer::recenter_at { x y } {
		
	if { ! $imageValid } {
		return
	}

	set centerx [expr ( double($x) / $width  - 0.5 ) / $zoom + $centerx]
	set centery [expr ( double($y) / $height - 0.5 ) / ($zoom * $width / $height) + $centery]

	# update the diffimage object
	update_image
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::view_with_adxv {} {
	exec adxv $filename &
}


###################################################################
#
# Callback when the window is resized
#
###################################################################
body DiffImageViewer::handle_resize {} {


	# let window repaint before starting the synchronous read
	update idletasks

	# make sure image is not in the process of loading
	if { ! $imageValid } {
		after 1000 [list catch "$this handle_resize"]
		return
	}
	
	# save old width temporarily
	set oldWidth $width
	set oldHeight $height
	
	# query and store new image size
	set width [winfo width $imageCanvas]
	set height [winfo height $imageCanvas]
	
	# size has not changed
	if { [ expr $oldWidth == $width ] && [ expr $oldHeight == $height ] } {
		return
	}
	
	puts "in handle_resize"

	imageObj resize $width $height
	
	# set the new zoom level and refresh the view
	set_zoom [expr $zoom * $oldWidth / $width]
}


###################################################################
#
# Callback when for right mouse click.
#
###################################################################
body DiffImageViewer::handle_right_click_load {} {

	set imageFile [tk_getOpenFile -filetypes 							\
		{ {{ADSC} {.img}} {MAR {.mar* .tif}} {ImageCif {.cif .cbf}} } 	\
		-initialdir $lastDirectory]

	if { $imageFile != "" } {
		$this load $userName $sessionId $imageFile
	}
}

###################################################################
#
# Callback when mouse moves in the image canvas.
#
###################################################################
body DiffImageViewer::handle_mouse_motion {x y} {
	

	catch {
		set newX [expr $x + 35]
		set newY [expr $y + 35]
		
		if { $newX + 35  > $width } {
			incr newX -70
		}
		
		if { $newY + 35  > $height } {
			incr newY -70
		}

		#move the text to near the cursor
		$imageCanvas coords $resolutionText $newX $newY
		
		#check to see if there is a loaded image
		if { ! $imageValid } {
			$imageCanvas itemconfigure $resolutionText -text $status -fill red -font $largeFont
			return
		}

		#The mar header doesn't provide enough information to calculate the resolution.
		if { $detectorType == "MAR 345" } {
			$imageCanvas itemconfigure $resolutionText -text "" \
													   -fill red -font $largeFont
			return
		}


		set deltaX [expr $x * $jpegPixelSize + $displayOriginX]
		set deltaY [expr $y * $jpegPixelSize + $displayOriginY]
		set radius [expr sqrt($deltaX * $deltaX + $deltaY * $deltaY)]

		# calculate the resolution of the ring from its radius
		set twoTheta [expr atan($radius / $distance) ]
		set dSpacing [expr $wavelength / (2*sin($twoTheta/2.0))]

		$imageCanvas itemconfigure $resolutionText -text [format "%.2f A" $dSpacing] \
												   -fill red -font $largeFont

	}

}



###################################################################
#
# Callback when mouse exits the image canvas.
#
###################################################################
body DiffImageViewer::handle_mouse_exit {} {

	$imageCanvas itemconfigure $resolutionText -text ""
}


###################################################################
#
# Creates canvases for the image and control panel.
# Create a DiffImage object to represent the image.
# DiffImage will handle the loading of the image and its header.
#
###################################################################
body DiffImageViewer::constructor { frame serverName listeningPort imageWidth imageHeight args } {


	# global variables
	global gBitmap
	global env

	# store image dimensions
	set height $imageHeight
	set width  $imageWidth
	
	# Parse the arguments and set the public 
	# members that match the arguments
	eval configure $args

	# create the photo object with a unique name
	set name "image[string range $this 2 end]"
	

	# create a DiffImage which holds the image data and image header
	# It also knows how to load/update image from source (i.e. via image server).	
	# mode can be 
	if { $protocol == "http"} {
		DiffImage imageObj $serverName $listeningPort $name
	} else {
		CDiffImage imageObj $serverName $listeningPort $name \
							-protocol $protocol 			 \
							-userName $userName
	}


	# Display the control canvas
	pack [set joypadCanvas [canvas $frame.joypadcanvas	\
							-width 500 -height 150		\
							-highlightcolor gray]] -side bottom

	# Display the image canvas
	# Note that the actual width and height of the canvas may not be exact
	# We need to set $width $height member variables again after the 
	# window becomes visible
	pack [set imageCanvas [canvas $frame.imageCanvas \
		-height $height -width $width -bg white -relief sunken -borderwidth 3] ] \
		-padx 5 -pady 5 -fill both -expand true -side bottom
				
	
	# Attach this image id to the canvas.
	set image [$imageCanvas create image 0 0 -image $name -anchor nw ]

	set resolutionText [$imageCanvas create text 50 50 -text "" -tag movable]

	bind $imageCanvas <Double-1> "$this view_with_adxv"
	bind $imageCanvas <1> "$this recenter_at %x %y"
	bind $imageCanvas <Configure> "$this handle_resize"
	bind $imageCanvas <Motion> "$this handle_mouse_motion %x %y"
	bind $imageCanvas <Leave> "$this handle_mouse_exit"
	bind $imageCanvas <3> "$this handle_right_click_load"
	
	set y_pos_high 0
	set y_pos_middle 22
	set y_pos_low 42
	
	set x_pos 20

	# make contrast buttons
	place [button $joypadCanvas.contrastdown -image $gBitmap(minus_sign) \
		-command "$this change_contrast_max_by -100" -width 15 -height 15 ] 	-x $x_pos -y $y_pos_middle
	place [label $joypadCanvas.contrastLabel -text "Brightness" \
		-font $smallFont] 														-x [set x_pos [expr $x_pos + 15]] -y $y_pos_high
	
	set contrastEntryVar ${name}contrastMax
	set contrastEntry [ entry $joypadCanvas.contrast	\
			-textvariable $contrastEntryVar			    \
			-font $smallFont							\
			-state normal								\
			-relief sunken								\
			-justify right 								\
			-background white 							\
			-highlightcolor red 						\
			-highlightthickness 0 						\
			-width 6]


	upvar #0 $contrastEntryVar c
	set c $contrastMax

	bind $contrastEntry <FocusOut> "$this handle_contrast_max_entry"
	bind $contrastEntry <Return> "$this handle_contrast_max_entry"
	
	place $contrastEntry														-x [set x_pos [expr $x_pos + 15]] -y $y_pos_middle
	place [button $joypadCanvas.contrastup -image $gBitmap(plus_sign) \
		-command "$this change_contrast_max_by 100" -width 15 -height 15 ] 		-x [set x_pos [expr $x_pos + 62]] -y $y_pos_middle

	# make joypad
	place [button $joypadCanvas.panleft -image $gBitmap(leftarrow) \
		-command "$this pan_horiz -1" -width 15 -height 15 ] 					-x [set x_pos [expr $x_pos + 60]] -y $y_pos_middle
	place [button $joypadCanvas.panup -image $gBitmap(uparrow) \
		-command "$this pan_vert -1" -width 15 -height 15 ] 					-x [set x_pos [expr $x_pos + 20]] -y $y_pos_high
	place [button $joypadCanvas.pandown -image $gBitmap(downarrow) \
		-command "$this pan_vert 1" -width 15 -height 15 ] 						-x $x_pos -y $y_pos_low
	place [button $joypadCanvas.panright -image $gBitmap(rightarrow) \
		-command "$this pan_horiz 1" -width 15 -height 15 ] 					-x [set x_pos [expr $x_pos + 20]] -y $y_pos_middle
		
	# make zoom buttons
	place [button $joypadCanvas.zoomdown -image $gBitmap(minus_sign) \
		-command "$this zoom_by 0.5" -width 15 -height 15 ] 					-x [set x_pos [expr $x_pos + 110]] -y $y_pos_middle

	set zoomEntryVar ${name}zoom
	set zoomEntry [ entry $joypadCanvas.zoom			\
			-textvariable $zoomEntryVar			    	\
			-font $smallFont							\
			-state normal								\
			-relief sunken								\
			-justify right 								\
			-background white 							\
			-highlightcolor red 						\
			-highlightthickness 0 						\
			-width 6]


	upvar #0 $zoomEntryVar z
	set z $zoom

	bind $zoomEntry <FocusOut> "$this handle_zoom_entry"
	bind $zoomEntry <Return> "$this handle_zoom_entry"

	place $zoomEntry															-x [set x_pos [expr $x_pos + 28]] -y $y_pos_middle

	place [label $joypadCanvas.zoomLabel -text "Zoom" \
		-font $smallFont] 														-x [set x_pos [expr $x_pos + 5]] -y $y_pos_high
	place [button $joypadCanvas.zoomup -image $gBitmap(plus_sign) \
		-command "$this zoom_by 2.0" -width 15 -height 15 ] 					-x [set x_pos [expr $x_pos + 57]] -y $y_pos_middle

	
	# File name entry next line 
	set y_pos_lower 70
	set x_pos 20	


	place [label $joypadCanvas.filenameLabel -text "File Name" \
		-font $smallFont] 														-x $x_pos -y $y_pos_lower

	set filenameEntryVar ${name}filename
	set filenameEntry [ entry $joypadCanvas.filename		\
			-textvariable $filenameEntryVar			\
			-font fixed							\
			-state normal								\
			-relief sunken								\
			-background white 							\
			-justify left 								\
			-highlightcolor red 						\
			-highlightthickness 0 						\
			-width 50]


	upvar #0 $filenameEntryVar s
	set s $filename

	bind $filenameEntry <FocusOut> "$this handle_filename_entry"
	bind $filenameEntry <Return> "$this handle_filename_entry"

	place $filenameEntry														-x [set x_pos [expr $x_pos + 100]] -y $y_pos_lower
	place [button $joypadCanvas.filebrowser -image $gBitmap(uparrow) \
		-command "$this browse_dir" -width 15 -height 15 ] 						-x [set x_pos [expr $x_pos + 310]] -y [expr $y_pos_lower-3]


	# Session id entry next line
	set y_pos_lower 100
	set x_pos 20	


	place [label $joypadCanvas.sessionIdLabel -text "Session ID" \
		-font $smallFont] 														-x $x_pos -y $y_pos_lower

	set sessionIdEntryVar ${name}sessionId
	set sessionIdEntry [ entry $joypadCanvas.sessionId		\
			-textvariable $sessionIdEntryVar			\
			-font fixed							\
			-state normal								\
			-relief sunken								\
			-background white 							\
			-justify left 								\
			-highlightcolor red 						\
			-highlightthickness 0 						\
			-width 50]


	upvar #0 $sessionIdEntryVar s
	set s $sessionId

	bind $sessionIdEntry <FocusOut> "$this handle_sessionid_entry"
	bind $sessionIdEntry <Return> "$this handle_sessionid_entry"

	place $sessionIdEntry														-x [set x_pos [expr $x_pos + 100]] -y $y_pos_lower

}
