#
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


proc create_splash_screen { imageFile } {

	# load required packages
	package require BWidget 1.2.1
	package require Img

	destroy_splash_screen

	# create the splash screen window
	toplevel .splash

	# hide the splash screen until complete
	wm withdraw .splash

	# remove the window manager border from the window
	wm overrideredirect .splash 1

	# load the splash screen image
	set splashImage [image create photo -file $imageFile -palette "8/8/8"]

	# create a canvas in the splash screen
	pack [canvas .splash.canvas -width 300 -height 400]

	# display the image on the canvas
	.splash.canvas create image 0 0 -anchor nw -image $splashImage

	# place the splash screen in the center of the display
	BWidget::place .splash 0 0 center

	# set up an event binding to hide the splash screen if it is clicked
#	bind .splash.canvas <Button-1> {wm withdraw .splash}
	bind .splash.canvas <Button-1> {destroy_splash_screen}

	# finally show the completed splash screen
	wm deiconify .splash

	# force wish to display the splash screen immediately
	update
}

proc raise_splash_screen {} {
	raise .splash
}

proc destroy_splash_screen {} {
	destroy .splash
}
