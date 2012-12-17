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


#	set gFont(micro)					"\xb5"
	set gFont(micro)					"\u"
#	set gFont(micron)					"\xb5m"
	set gFont(micron)					"\um"
#	set gFont(angstrom)				"\xc1"
	set gFont(angstrom)				A

proc load_default_resources {} {
	global gBeamline
	global gColors
	global gFont
	global gConfig
	global gBitmap
	global gDefineScan
	global gScan
	global gCursor
	global gPlot
	global tcl_platform

	if { $tcl_platform(os) == "IRIX64" } {
		set gPlot(axisFont) "courier 8"
		set gPlot(smallLegendFont) "helvetica 8 bold"
		set gPlot(legendFont) "helvetica 9 bold"
		set gPlot(bigLegendFont) "helvetica 10 bold"
	} else {
		set gPlot(axisFont) "courier 10"
		set gPlot(smallLegendFont) "helvetica 10 bold"
		set gPlot(legendFont) "helvetica 11 bold"
		set gPlot(bigLegendFont) "helvetica 12 bold"
	}

	set gColors(verydark)			#555
	set gColors(dark)					#777
	set gColors(front)				#b0b0ee
	set gColors(side)					#a0a0dd
	set gColors(top)					#c0c0ff	
	set gColors(darkgrey)			#aaa
	set gColors(highlight) 			#6060d0
	set gColors(midhighlight)		#e0e0f0
	#set up a different color for simulation
	if { $gBeamline(simulation) } {
		set gColors(unhighlight)      lightblue
	} else {
		set gColors(unhighlight)		#c0c0ff
	}
	set gColors(highlight5)			#b0b0ff
	set gColors(light)				#f0f0ff
	set gColors(text)					#3030a0
#	set gColors(yellow)				#ffff00	
	set gColors(yellow)				#eeeeaa
	set gColors(green)				#cfc
	set gColors(lightRed)			#ffaaaa
	set gColors(red)					#ff6666
	set gColors(um)					blue
	set gColors(mm)					blue
	set gColors(steps)				purple
	set gColors(eV)					red
	set gColors(counts)				red
	set gColors(um/step)				purple
	set gColors(mm/step)				purple
	set gColors(deg/step)			purple	
	set gColors(steps/sec)			purple
	set gColors(steps/sec**2)		purple
	set gColors(deg)					darkgreen
	set gColors(mrad)             darkgreen
	set gColors(active)				red
	set gColors(changed)				red
	set gColors(error)				red
	set gColors(warning)				#844
	set gColors(note)					darkgreen
	set gColors(select)				$gColors(unhighlight)
	set gColors(units)				#404070
	set gColors(brownRed)         #a0352a
	set gColors(activeBlue)       #2465be

	
	set gColors(motor,foreground)						black
	set gColors(motor,background)						lightgrey
	set gColors(motor,selectedforeground)			black
	set gColors(motor,selectedbackground)			white
	set gColors(motor,activeforeground)				#f60
	set gColors(motor,activebackground)				lightgrey
	set gColors(motor,activeselectedforeground)	black
	set gColors(motor,activeselectedbackground)	darkorange

	set gPlot(color,1) #aaf
	set gPlot(color,2) #fdd
	set gPlot(color,3) #8ff
	set gPlot(color,4) #faf
	set gPlot(color,5) #aaa
	set gPlot(color,6) #afa
	set gPlot(color,7) #0aa
	set gPlot(color,8) #a0a
	set gPlot(color,9) #0a0
	set gPlot(color,10) #a00
	
	set gCursor(1,color)	#ff7
	set gCursor(2,color)  #7f7

	set tinyFont *-helvetica-bold-r-normal--10-*-*-*-*-*-*-*
	set smallFont *-helvetica-bold-r-normal--14-*-*-*-*-*-*-*
	set largeFont *-helvetica-bold-r-normal--18-*-*-*-*-*-*-*
	set hugeFont *-helvetica-medium-r-normal--30-*-*-*-*-*-*-*
	set signFont *-courier-bold-r-normal--14-*-*-*-*-*-*-*
	set gFont(tiny) $tinyFont
	set gFont(small) $smallFont
	set gFont(large) $largeFont
	set gFont(huge)  $hugeFont
	set gFont(sign) $signFont
	
	option add *Font 								$largeFont
	option add *scrolling_area.text.font 	$largeFont
	option add *Entry*Font						$largeFont
	option add *Message*Font					$largeFont
	option add *Button*Font 					$largeFont
	
	set gConfig(font)			$smallFont
	set gDefineScan(font)	$smallFont

	option add *label*padX 0
	option add *frame*highlightColor lightgrey
	option add *frame*highlightBackground blue
	option add *highlightThickness 0
	
	
	option add *foreground 	black
	option add *background 	lightgrey
	option add *selectBackground $gColors(select)
	option add *selectForeground black
	option add *highlightColor 	$gColors(highlight)
	
	option add *Entry*background 	$gColors(light)

	option add *Scrollbar*troughColor 		$gColors(midhighlight)
	option add *Scrollbar*background 		$gColors(unhighlight)
	option add *Scrollbar*activeBackground $gColors(unhighlight)
	
	option add *Button*background			$gColors(unhighlight)
	option add *Button*activeBackground $gColors(unhighlight)
	option add *Button*activeForeground black
	
	option add *Checkbutton*selectColor	blue
	option add *Checkbutton*Font	$smallFont


	option add *Message.background $gColors(midhighlight)
	
	option add *Menu*background			$gColors(unhighlight)
	option add *Menu*foreground			black
	option add *Menu*activeBackground 	$gColors(unhighlight)
	option add *Menu*activeForeground 	black

	option add *Menubutton*background			$gColors(unhighlight)
	option add *Menubutton*foreground			black
	option add *Menubutton*activeBackground 	$gColors(unhighlight)
	option add *Menubutton*activeForeground 	black
	option add *Menubutton*Font 					$smallFont
	

	option add *Listbox*background $gColors(light)
	option add *Listbox*selectbackground white
	option add *Listbox*height			0
	option add *Listbox*width			0

	option add *Scrolledlistbox*background $gColors(light)
	option add *Scrolledlistbox*selectbackground white
	option add *Scrolledlistbox*textBackground $gColors(light)

	
	option add *TixComboBox*selectbackground white


	option add *menuFrame.background	$gColors(unhighlight)
	
	
	
	bind Entry <Delete> {tkEntryBackspace %W}

	
	set arrowData {#define arrow_width 16
#define arrow_height 16
static unsigned char arrow_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfc, 0x1f,
   0xf8, 0x0f, 0xf0, 0x07, 0xe0, 0x03, 0xc0, 0x01, 0x80, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
   }
   set gBitmap(arrow) [image create bitmap -data $arrowData]
	
	set zoominData {#define zoomin_width 16
#define zoomin_height 16
static unsigned char zoomin_bits[] = {
   0xf8, 0x1f, 0xfc, 0x3f, 0x0e, 0x70, 0x07, 0xe0, 0x83, 0xc1, 0x83, 0xc1,
   0x83, 0xc1, 0xf3, 0xcf, 0xf3, 0xcf, 0x83, 0xc1, 0x83, 0xc1, 0x83, 0xc1,
   0x07, 0xe0, 0x0e, 0x70, 0xfc, 0x3f, 0xf8, 0x1f};
	}
	set gBitmap(zoomin) [image create bitmap -data $zoominData]

	set zoomoutData {#define zoomout_width 16
#define zoomout_height 16
static unsigned char zoomout_bits[] = {
  0xf8, 0x1f, 0xfc, 0x3f, 0x0e, 0x70, 0x07, 0xe0, 0x03, 0xc0, 0x03, 0xc0,
   0x03, 0xc0, 0xf3, 0xcf, 0xf3, 0xcf, 0x03, 0xc0, 0x03, 0xc0, 0x03, 0xc0,
   0x07, 0xe0, 0x0e, 0x70, 0xfc, 0x3f, 0xf8, 0x1f};
	}
	set gBitmap(zoomout) [image create bitmap -data $zoomoutData]

set zoomrestoreData {#define restore_width 16
#define restore_height 16
static unsigned char restore_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xdd, 0x4d,
   0x55, 0x2d, 0x55, 0x21, 0x55, 0x11, 0x55, 0xd1, 0xdd, 0xc9, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
	}
	set gBitmap(zoomrestore) [image create bitmap -data $zoomrestoreData]

set zoomleftData {#define zoomleft_width 16
#define zoomleft_height 16
static unsigned char zoomleft_bits[] = {
   0x00, 0x00, 0x40, 0x00, 0x60, 0x00, 0x70, 0x00, 0x78, 0x00, 0xfc, 0xff,
   0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xfc, 0xff, 0x78, 0x00,
   0x70, 0x00, 0x60, 0x00, 0x40, 0x00, 0x00, 0x00};
	}
	set gBitmap(zoomleft) [image create bitmap -data $zoomleftData]

set zoomrightData {#define zoomright_width 16
#define zoomright_height 16
static unsigned char zoomright_bits[] = {
   0x00, 0x00, 0x00, 0x02, 0x00, 0x06, 0x00, 0x0e, 0x00, 0x1e, 0xff, 0x3f,
   0xff, 0x7f, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f, 0xff, 0x3f, 0x00, 0x1e,
   0x00, 0x0e, 0x00, 0x06, 0x00, 0x02, 0x00, 0x00};
   }
	set gBitmap(zoomright) [image create bitmap -data $zoomrightData]

set stopData {#define stop_width 16
#define stop_height 16
static unsigned char stop_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x76, 0x77, 0x22, 0x55, 0x26, 0x75, 0x24, 0x15,
   0x26, 0x17, 0x00, 0x00, 0x00, 0x00, 0xb6, 0x4b, 0x92, 0x5a, 0x96, 0x7b,
   0x94, 0x6a, 0xb6, 0x4a, 0x00, 0x00, 0x00, 0x00};
}
	set gBitmap(stop) [image create bitmap -data $stopData]

set dashedlineData {#define dashedline_width 16
#define dashedline_height 1
static unsigned char dashedline_bits[] = {
   0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc, 0xcc};
   }
	set gBitmap(dashedline) [image create bitmap -data $dashedlineData]
}

set arrowData {#define arrow_width 16
#define arrow_height 16
static unsigned char arrow_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfc, 0x1f,
   0xf8, 0x0f, 0xf0, 0x07, 0xe0, 0x03, 0xc0, 0x01, 0x80, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
   }
   set gBitmap(downarrow) [image create bitmap -data $arrowData]
	

set arrowData {#define arrow_width 16
#define arrow_height 16
static unsigned char arrow_bits[] = {
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00,
   0xc0, 0x01, 0xe0, 0x03, 0xf0, 0x07, 0xf8, 0x0f, 0xfc, 0x1f, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
   }
set gBitmap(uparrow) [image create bitmap -data $arrowData]


set arrowData {#define arrow_width 16
#define arrow_height 16
static unsigned char arrow_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x06, 0x00, 0x07,
   0x80, 0x07, 0xc0, 0x07, 0xe0, 0x07, 0xc0, 0x07, 0x80, 0x07, 0x00, 0x07,
   0x00, 0x06, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00};
   }
   set gBitmap(leftarrow) [image create bitmap -data $arrowData]


set arrowData {#define arrow_width 16
#define arrow_height 16
static unsigned char arrow_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x60, 0x00, 0xe0, 0x00,
   0xe0, 0x01, 0xe0, 0x03, 0xe0, 0x07, 0xe0, 0x03, 0xe0, 0x01, 0xe0, 0x00,
   0x60, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00};
   }
   set gBitmap(rightarrow) [image create bitmap -data $arrowData]
