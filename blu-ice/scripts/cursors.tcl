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



proc initialize_cursor { num } {

	# global variables
	global gScan
	global gPlot
	global gCursor
	
	# set the cursor legend position
	set gCursor($num,legend_z) [expr 80 * ($num - 1) + $gPlot(z_end_a) ] 

	set gCursor($num,x) [expr $gPlot(x_origin) + $gPlot(x_size) / 2 ]
	set gCursor($num,y) [expr $gPlot(z_origin) - $gPlot(z_size) / 2 ]
	set_cursor_mode $num hide
	
	# draw the cursor label on the canvas
	$gScan(canvas) create text $gPlot(legend_x) $gCursor($num,legend_z)	\
		-text "Cursor $num" -fill $gCursor($num,color) -anchor nw \
		-font $gPlot(legendFont) -tag cursor$num

	# bind cursor mode change to label
	$gScan(canvas) bind cursor$num <Button-1> "set_cursor_mode $num next"
}


proc place_cursor { num x y {correct 1} {interactive 1} {next 0} } {

	# global variables
	global gScan
	global gPlot
	global gCursor
	global gDevice

	# correct y for canvas offset
	if { $correct } { 
		set x [expr $x - 1]
		set y [expr $y + 340]
	}
	
	# make sure event was within the plotting area
	if {$x < $gPlot(x_origin) || $x > $gPlot(x_end) ||
		  $y > $gPlot(z_origin_a) || $y < $gPlot(z_end_a) } {
		return
	}

	# calculate coordinates corresponding to passed canvas point
	set gCursor($num,x) $x
	set gCursor($num,y) $y


	# show the cursor in its new position
	if { $next } {
		set_cursor_mode $num next
	} else {
		if { $gCursor($num,mode) == "hide" } {
			set_cursor_mode $num cross 0
			log_note "Showing cursor"
		}
		update_cursor $num
	}
	
	# select the motor and set the control position if scan complete
	if { ! $gScan(standalone) && $gScan(axisCount) == 1 && \
			$gScan(motor1,name) != "time"  && $interactive == 1 } {
		if { $gDevice(control,motor) != $gScan(motor1,name) } {
			select_motor $gScan(motor1,name)
		}
		if { $gDevice(control,units) != $gScan(motor1,units) } {
			set_units $gScan(motor1,units)
		}
		set gDevice(control,value) $gCursor($num,x_legend_text)
	}
}


proc update_cursor { num } {

	# global variables
	global gScan
	global gPlot
	global gCursor
	
	set gCursor($num,x_ordinate) \
		[expr ($gCursor($num,x) - $gPlot(x_origin)) / $gScan(x_scale) + \
			$gScan(min_visible_x_ordinate)]
	set gCursor($num,y_ordinate) \
		[expr ($gPlot(z_origin) - $gCursor($num,y)) / $gScan(z_scale) + \
			$gScan(min_visible_z_ordinate)]
	
	# erase the cursor
	destroy_cursor $num

	# show the cursor
	show_cursor $num
}

proc destroy_cursor { num } {

	# global variables
	global gScan
	global gCursor
	
	# delete the old objects if they exist
	catch {$gScan(canvas) delete $gCursor($num,vertical_line)} 
	catch {$gScan(canvas) delete $gCursor($num,horizontal_line) }
	catch {$gScan(canvas) delete $gCursor($num,horizontal_label) }
	catch {$gScan(canvas) delete $gCursor($num,vertical_label) }
	catch {$gScan(canvas) delete $gCursor($num,x_legend) }
	catch {$gScan(canvas) delete $gCursor($num,y_legend) }
	catch {$gScan(canvas) delete $gCursor(dx_legend) }
	catch {$gScan(canvas) delete $gCursor(dy_legend) }
}


proc show_cursor { num } {

	# global variables
	global gScan
	global gPlot
	global gCursor

	# draw cross if nothing else drawn
	if { $gScan(z_range) < 200 && [string first "Counts" $gScan(z_label)] == -1 } {
		set y_legend_text [format "%.3f" $gCursor($num,y_ordinate)]
	} else {
		set y_legend_text [format "%d" [expr int($gCursor($num,y_ordinate))]]
	}
	 
	set x_legend_text [format "%.3f" \
		[expr (round($gCursor($num,x_ordinate) * 1000.0))/1000.0] ]
	set gCursor($num,x_legend_text) $x_legend_text
	set dx_legend_text ""
	set dy_legend_text ""
	if { [info exists gCursor(2,x_ordinate)] && \
		[info exists gCursor(1,x_ordinate)] } {
		set dx_legend_text [format "%.3f" \
			[expr abs( (round(($gCursor(1,x_ordinate)- \
			$gCursor(2,x_ordinate)) * 1000.0))/1000.0 ) ] ]
	}
	catch {set dy_legend_text [format "%.3f" \
		[expr abs($gCursor(1,y_ordinate) - $gCursor(2,y_ordinate)) ] ] }	
	

	# draw the horizontal line
	if { $gCursor($num,show)} {

		if { $gCursor($num,y) < $gPlot(z_origin_a) && \
		   $gCursor($num,y) > $gPlot(z_end_a) } {

			# make the new horizontal label
			set gCursor($num,horizontal_label) [
				$gScan(canvas) create text \
				[expr $gPlot(x_end) + 5] $gCursor($num,y) 	\
				-text $y_legend_text			\
				-anchor w -fill $gCursor($num,color) -font $gPlot(axisFont)
				]
				
			# check if horizontal line is requested
			if { $gCursor($num,horiz) } {

				# make the new horizontal line
				set gCursor($num,horizontal_line) [ 
					$gScan(canvas) create line \
					$gPlot(x_origin) $gCursor($num,y)\
					$gPlot(x_end) $gCursor($num,y)\
					-fill $gCursor($num,color) -width 1
					]
			} else {
			
			# make the short horizontal line
			set gCursor($num,horizontal_line) [ 
				$gScan(canvas) create line \
				[expr $gCursor($num,x) + 5] $gCursor($num,y)\
				[expr $gCursor($num,x) - 5] $gCursor($num,y)\
				-fill $gCursor($num,color) -width 1
				]
			}		
		}
	}


	# check if cursor should be shown
	if { $gCursor($num,show) } {
		
		# check if vertical cursor is on screen
		if { [is_vertical_cursor_on_screen $num] } {

			# make the new vertical label
			set gCursor($num,vertical_label) [ 
				$gScan(canvas) create text \
				$gCursor($num,x)	\
				[expr $gPlot(z_end_a) - 5] 	\
				-text $x_legend_text	\
				-anchor s -fill $gCursor($num,color) \
				-font $gPlot(axisFont)
				]
	
			# check if vertical line is requested
			if { $gCursor($num,vert) } {

				# make the new vertical line
				set gCursor($num,vertical_line) [ 
					$gScan(canvas) create line \
					$gCursor($num,x) $gPlot(z_end_a) \
					$gCursor($num,x) $gPlot(z_origin_a) \
					-fill $gCursor($num,color) -width 1
					]
			} else {
			
				# make the short vertical line
				set gCursor($num,vertical_line) [ 
					$gScan(canvas) create line \
					$gCursor($num,x) [expr $gCursor($num,y) + 5] \
					$gCursor($num,x) [expr $gCursor($num,y) - 5] \
					-fill $gCursor($num,color) -width 1
				]
			}
		}
	}

	# draw the legend
	set gCursor($num,x_legend) [
		$gScan(canvas) create text \
			[expr $gPlot(legend_x)]	\
			[expr $gCursor($num,legend_z) + 20 ]	\
			-text "x = $x_legend_text" \
			-tag cursor$num \
			-fill $gCursor($num,color) -anchor nw -font $gPlot(axisFont)
	]
	set gCursor($num,y_legend) [ 
		$gScan(canvas) create text \
			[expr $gPlot(legend_x)]	\
			[expr $gCursor($num,legend_z) + 40 ]	\
			-text "y = $y_legend_text" \
			-tag cursor$num \
			-fill $gCursor($num,color) -anchor nw -font $gPlot(axisFont)
	]
	set gCursor(dx_legend) [ 
		$gScan(canvas) create text \
			[expr $gPlot(legend_x)]	\
			[expr $gPlot(z_end_a) + 160 ]	\
			-text "dx = $dx_legend_text" \
			-tag cursor$num \
			-fill white -anchor nw -font $gPlot(axisFont)
	]
	set gCursor(dy_legend) [ 
		$gScan(canvas) create text \
			[expr $gPlot(legend_x)]	\
			[expr $gPlot(z_end_a) + 180 ]	\
			-text "dy = $dy_legend_text" \
			-tag cursor$num \
			-fill white -anchor nw -font $gPlot(axisFont)
	]
	
	# bind cursor mode change to label
	$gScan(canvas) bind cursor$num <Button-1> "set_cursor_mode $num next"
	
}

proc is_vertical_cursor_on_screen { num } {

	# global variables
	global gCursor
	global gScan
	
	if { $gScan(motor1,end) > $gScan(motor1,start) && \
			$gCursor($num,x_ordinate) > $gScan(min_visible_x_ordinate) && \
			$gCursor($num,x_ordinate) < $gScan(max_visible_x_ordinate) } {
			return 1
		}

	if { $gScan(motor1,end) < $gScan(motor1,start) && \
			$gCursor($num,x_ordinate) < $gScan(min_visible_x_ordinate) && \
			$gCursor($num,x_ordinate) > $gScan(max_visible_x_ordinate) } {
			return 1
		}

	return 0
}



proc correct_cursor_position { num x_ordinate y_ordinate } {

	# global variables
	global gScan
	global gPlot
	global gCursor
	
	set gCursor($num,x) [ expr ( $x_ordinate - $gScan(min_visible_x_ordinate) ) \
		* $gScan(x_scale) + $gPlot(x_origin) ]
	set gCursor($num,y) [ expr ( $gScan(min_visible_z_ordinate) -$y_ordinate ) \
		* $gScan(z_scale) + $gPlot(z_origin) ]
	
	update_cursor $num
}



proc set_cursor_mode { num mode {update 1} } {
	
	# global variables
	global gCursor

	if { $mode == "next" } {
		switch $gCursor($num,mode) {	
			hide { set gCursor($num,mode) cross }
			cross { set gCursor($num,mode) vert }
			vert { set gCursor($num,mode) horiz }
			horiz { set gCursor($num,mode) small }
			small { set gCursor($num,mode) hide }
		}
	} else {
		set gCursor($num,mode) $mode
	}

	switch $gCursor($num,mode) {
		
		hide {
			set gCursor($num,show) 0	
			set gCursor($num,horiz) 0
			set gCursor($num,vert) 0
		}
		
		cross {
			set gCursor($num,show) 1	
			set gCursor($num,vert) 1
			set gCursor($num,horiz) 1
		}
		
		vert {
			set gCursor($num,show) 1	
			set gCursor($num,vert) 1
			set gCursor($num,horiz) 0
		}

		horiz {
			set gCursor($num,show) 1	
			set gCursor($num,vert) 0
			set gCursor($num,horiz) 1
		}

		small {
			set gCursor($num,show) 1	
			set gCursor($num,vert) 0
			set gCursor($num,horiz) 0
		}
	}

	if { $update }	{ update_cursor $num }
}




