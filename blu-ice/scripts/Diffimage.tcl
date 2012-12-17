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

class Diffimage {

	# private data members
	private variable name			""
	private variable zoom			1.0
	private variable contrastMin	0
	private variable contrastMax	200
	private variable imageCanvas	""
	private variable imageFrame	""
	private variable image			""
	private variable resolutionText ""
	private variable filename		""
	private variable lastDirectory "/data/$env(USER)"
	private variable first			1
	private variable imageValid	0
	private variable title
	private variable request		""
	private variable centerx		0.5
	private variable centery		0.5
	private variable width		
	private variable height	     
	private variable pollperiod	200		
	
	private variable wavelength     1.0
	private variable distance       100
	private variable displayOriginX 0
	private variable displayOriginY 0
	private variable jpegPixelSize "1"
	private variable exposureTime
	private variable detectorType ""
	private variable status "No Image"


	# public member functions
	public method constructor { frame serverName listeningPort imageWidth imageHeight }
	destructor {
		image_channel_delete $name
	}

	public method load { path }
	public method zoom_by { factor }
	public method set_contrast_max { max }
	public method change_contrast_max_by { delta }
	public method pan_horiz { delta }
	public method pan_vert { delta }
	public method recenter_at { x y }
	public method handle_contrast_max_entry {}
	public method handle_zoom_entry {}
	public method set_zoom { value }
	public method finish_load {}
	public method view_with_adxv {}
 	public method load_image_dialog {} 
 	public method handle_resize {} 
 	public method handle_mouse_motion {x y} 
	public method handle_mouse_exit {}	
	public method handle_right_click_load {}

	# private member functions
	private method update_request {}
	private method update_image {}
	private method redraw_image {}
}


body Diffimage::update_request {} {

	set request "$filename $width $height $zoom $contrastMax \
		$centerx $centery"
}


body Diffimage::load { path } {
	global gFont

	set lastDirectory [string range $path 0 [string last "/" $path]]

	if { ! [image_channel_load_complete $name] } {
		return
	}
	
	set status "Loading..."
	$imageCanvas itemconfigure $resolutionText -text $status -fill red -font $gFont(large)

	# image is now invalid
	set imageValid 0

	# store the filename
	set filename $path

	# update request string
	update_request

	# load the file	
	image_channel_load $name async $request
	
	# check if load done in 1 second
	after $pollperiod $this finish_load
}


body Diffimage::finish_load {} {

	# try again later if load not complete
	if { ! [image_channel_load_complete $name] } {
		after $pollperiod $this finish_load
		return
	}

	# make sure the load was successful
	if { [image_channel_error_happened $name] } {
		set status "Error loading image."
		return
	}
		
	# image is now valid
	set imageValid 1

	# update title
	$title configure -text $filename

	# display the image
	redraw_image
}


body Diffimage::redraw_image {} {
	# update the display

	#puts "image_channel_update $name"
	if { [catch {set imageParameters [image_channel_update $name]} errorResult] } {
		puts $errorResult
		return
	}

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
}

body Diffimage::update_image {} {

	# update request string
	update_request
	
	# load the file
	if { [catch {image_channel_load $name sync $request} errorResult] } {
		puts $errorResult
		return
	}

	# make sure the load was successful
	if { [image_channel_error_happened $name] } {
		print "Error loading image."
		return
	}

	redraw_image

	update idletasks
}


body Diffimage::handle_contrast_max_entry {} {

	# get new value from entry field
	set newMax [getSafeEntryValue ${name}contrastMax]
	
	# reset entry value if invalid
	if { ![is_positive_int $newMax] || ! [image_channel_load_complete $name]} {
		setSafeEntryValue ${name}contrastMax $contrastMax	
	} else {
		set_contrast_max $newMax
	}
}


body Diffimage::handle_zoom_entry {} {

	# get new value from entry field
	set newZoom [getSafeEntryValue ${name}zoom]

	# reset entry value if invalid
	if { ![is_positive_float $newZoom] || $newZoom <= 0 || ! [image_channel_load_complete $name]} {
		setSafeEntryValue ${name}zoom $zoom	
	} else {
		set_zoom $newZoom
	}
}


body Diffimage::zoom_by { factor } {

	if { ! [image_channel_load_complete $name] } {
		return
	}

	# calculate new value for zoom
	set zoom [expr $zoom * $factor]

	# update the diffimage object
	set_zoom $zoom
}


body Diffimage::set_zoom { value } {
	
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
	setSafeEntryValue ${name}zoom $zoom	

	# update the diffimage object
	update_image
}


body Diffimage::set_contrast_max { max } {
	
	if { ! $imageValid } {
		return
	}

	# store new value of contrast max
	set contrastMax $max

	# update the entry field
	setSafeEntryValue ${name}contrastMax $contrastMax

	# update the diffimage object
	update_image
}


body Diffimage::change_contrast_max_by { delta } {
	
	if { ! $imageValid } {
		return
	}

	# calculate new value of contrast max
	set_contrast_max [expr $contrastMax + $delta]
}


body Diffimage::pan_horiz { delta } {
		
	if { ! $imageValid } {
		return
	}

	$this recenter_at [expr $width / 2 + $delta * $width / 2] [expr $height / 2 ]
}


body Diffimage::pan_vert { delta } {
	
	if { ! $imageValid } {
		return
	}

	$this recenter_at [expr $width / 2] [expr $height / 2 + $delta * $height / 2]
}


body Diffimage::recenter_at { x y } {
		
	if { ! $imageValid } {
		return
	}

	set centerx [expr ( double($x) / $width  - 0.5 ) / $zoom + $centerx]
	set centery [expr ( double($y) / $height - 0.5 ) / ($zoom * $width / $height) + $centery]

	# update the diffimage object
	update_image
}


body Diffimage::view_with_adxv {} {
	exec adxv $filename &
}


body Diffimage::load_image_dialog {} {

	# get the name of the file to open
	set newfilename [tk_getOpenFile]

	# make sure the file selection was not cancelled
	if { $newfilename != {} } {
		load $newfilename
	}
}


body Diffimage::handle_resize {} {

	# let window repaint before starting the synchronous read
	update idletasks

	# make sure image is not in the process of loading
	if { ! $imageValid } {
		after 1000 [list catch "$this handle_resize"]
		return
	}

	# save old width temporarily
	set oldWidth $width

	# query and store new image size
	set width [winfo width $imageCanvas]
	set height [winfo height $imageCanvas]

	# set the image channel size
	image_channel_resize $name $width $height
	
	# set the new zoom level and refresh the view
	set_zoom [expr $zoom * $oldWidth / $width]
}


body Diffimage::handle_right_click_load {} {
	global env

	set imageFile [tk_getOpenFile -filetypes { {{ADSC} {.img}} {MAR {.mar* .tif}} {ImageCif {.cif .cbf}} } -initialdir $lastDirectory]

	if { $imageFile != "" } {
		do_command "$this load $imageFile"
	}
}

body Diffimage::handle_mouse_motion {x y} {
	global gFont

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
			$imageCanvas itemconfigure $resolutionText -text $status -fill red -font $gFont(large)
			return
		}

		#The mar header doesn't provide enough information to calculate the resolution.
		if { $detectorType == "MAR 345" } {
			$imageCanvas itemconfigure $resolutionText -text "" -fill red -font $gFont(large)
			return
		}

		set deltaX [expr $x * $jpegPixelSize + $displayOriginX]
		set deltaY [expr $y * $jpegPixelSize + $displayOriginY]
		set radius [expr sqrt($deltaX * $deltaX + $deltaY * $deltaY)]
		
		# calculate the resolution of the ring from its radius
		set twoTheta [expr atan($radius / $distance) ]
		set dSpacing [expr $wavelength / (2*sin($twoTheta/2.0))]
		
		$imageCanvas itemconfigure $resolutionText -text [format "%.2f A" $dSpacing] -fill red -font $gFont(large)
	}

}



body Diffimage::handle_mouse_exit {} {
	$imageCanvas itemconfigure $resolutionText -text ""
}


body Diffimage::constructor { frame serverName listeningPort imageWidth imageHeight } {

	# global variables
	global gBitmap
	global gDefineScan
	global env

	# store image dimensions
	set height $imageHeight
	set width  $imageWidth
	set imageFrame $frame

	# create the photo object
	set name "image[string range $this 2 end]"

	image_channel_create $name $serverName $listeningPort 1 $width $height $env(USER)
	

	pack [set title [label $frame.title \
		-width 48 -justify c]]

	pack [set joypadCanvas [canvas $frame.joypadcanvas -width 500 -height 65]] -side bottom

	pack [set imageCanvas [canvas $frame.imageCanvas \
		-height $height -width $width -bg white -relief sunken -borderwidth 3] ] \
		-padx 5 -pady 5 -fill both -expand true -side bottom
	image create photo $name -palette 256/256/256
	set image [$imageCanvas create image 0 0 -image $name -anchor nw ]

	set resolutionText [$imageCanvas create text 50 50 -text "" -tag movable]

	#puts $resolutionText

	bind $imageCanvas <Double-1> "$this view_with_adxv"
	bind $imageCanvas <1> "$this recenter_at %x %y"
	bind $imageCanvas <Configure> "$this handle_resize"
	bind $imageCanvas <Motion> "$this handle_mouse_motion %x %y"
	bind $imageCanvas <Leave> "$this handle_mouse_exit"
	bind $imageCanvas <3> "$this handle_right_click_load"

	# make joypad

	place [button $joypadCanvas.panright -image $gBitmap(rightarrow) \
		-command "$this pan_horiz 1" -width 15 -height 15 ] -x 260 -y 20
	place [button $joypadCanvas.panleft -image $gBitmap(leftarrow) \
		-command "$this pan_horiz -1" -width 15 -height 15 ] -x 220 -y 20
	place [button $joypadCanvas.panup -image $gBitmap(uparrow) \
		-command "$this pan_vert -1" -width 15 -height 15 ] -x 240 -y 0
	place [button $joypadCanvas.pandown -image $gBitmap(downarrow) \
		-command "$this pan_vert 1" -width 15 -height 15 ] -x 240 -y 40
		
	# make zoom buttons
	place [label $joypadCanvas.zoomLabel -text "Zoom" \
		-font $gDefineScan(font)] -x 383 -y 0
	place [button $joypadCanvas.zoomup -image $gBitmap(rightarrow) \
		-command "$this zoom_by 2.0" -width 15 -height 15 ] -x 440 -y 20
	place [button $joypadCanvas.zoomdown -image $gBitmap(leftarrow) \
		-command "$this zoom_by 0.5" -width 15 -height 15 ] -x 350 -y 20
	place [safeEntry $joypadCanvas.zoom \
		-type positive_float -name ${name}zoom -width 6\
		-onsubmit "$this handle_zoom_entry" -font $gDefineScan(font)] \
		-x 378 -y 20
	setSafeEntryValue ${name}zoom $zoom

	# make contrast buttons
	place [label $joypadCanvas.contrastLabel -text "Contrast" \
		-font $gDefineScan(font)] -x 65 -y 0
	place [button $joypadCanvas.contrastup -image $gBitmap(rightarrow) \
		-command "$this change_contrast_max_by 100" -width 15 -height 15 ] -x 130 -y 20
	place [button $joypadCanvas.contrastdown -image $gBitmap(leftarrow) \
		-command "$this change_contrast_max_by -100" -width 15 -height 15 ] -x 40 -y 20
	place [safeEntry $joypadCanvas.contrast \
		-type positive_int -name ${name}contrastMax -width 6\
		-onsubmit "$this handle_contrast_max_entry" -font $gDefineScan(font)] \
		-x 68 -y 20
	setSafeEntryValue ${name}contrastMax $contrastMax
	
	# make filename entry field
	#place [button $joypadCanvas.load -text "Open" -font $gDefineScan(font) \
	#	-command "$this load_image_dialog"] -x 230 -y 70
}
