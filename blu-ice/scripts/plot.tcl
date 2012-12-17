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



set gPlot(signal,width) 1
set gPlot(reference,width) 2
set gPlot(trans,width) 1
set gPlot(abs,width) 1
set gPlot(z_origin) 0
set gScan(z_label) Counts
set gPlot(printer) lp

proc initialize_canvas_bindings {} {

	# global variables
	global gScan
	global gCursor
	
	if { $gScan(type) != "counts_vs_2_motors" } {
		initialize_cursor 1
		initialize_cursor 2
		
		bind $gScan(canvas) <Button-1> { place_cursor 1 %x %y }
		bind $gScan(canvas) <B1-Motion> { place_cursor 1 %x %y }
		bind $gScan(canvas) <Double-1> { place_cursor 1 %x %y 1 1 1}
		
		#bind $gScan(canvas) <Button-2> { zoom in 1 %x %y }
		
		bind $gScan(canvas) <Button-3> {  place_cursor 2 %x %y }
		bind $gScan(canvas) <B3-Motion> { place_cursor 2 %x %y }  
		bind $gScan(canvas) <Double-3> { place_cursor 2 %x %y 1 1 1}
	}
}


proc get_scaled_coord_2D {x z} {
	
	# global variables
	global gScan
	global gPlot
	
	set x_scaled [expr $gPlot(x_origin) + \
		($x - $gScan(min_visible_x_ordinate)) * $gScan(x_scale)]
	set z_scaled [expr $gPlot(z_origin) - \
		($z - $gScan(min_visible_z_ordinate))* $gScan(z_scale)]
	
	return [list $x_scaled $z_scaled]
}


proc get_scaled_coord_3D {x y z} {
	
	# global variables
	global gScan
	global gPlot
	
	set delta_x [expr $x - $gScan(x_base)]
	set delta_y [expr $y - $gScan(y_base)]
	
	set x_scaled [								\
		expr $gPlot(x_origin) + 		\
		double($delta_x) * $gPlot(dx_dx)	+	\
		double($delta_y) * $gPlot(dx_dy) ]
	set z_scaled [								\
		expr 380 + $gPlot(z_origin) - 		\
		($z * $gScan(z_scale) +				\
		double($delta_x) * $gPlot(dz_dx)	+ 	\
		double($delta_y) * $gPlot(dz_dy)) ]
		
	return [list $x_scaled $z_scaled]
}


proc initialize_2D_plot { x0 x1 xLabel zLabel } {

	# global variables
	global gScan
	global gPlot
	
	# swap parameters if x0 > x1
	if { $x0 > $x1 } {
		set temp $x0
		set x0 $x1
		set x1 $temp
	}
	
	set gScan(x0) $x0
		
	set gScan(min_visible_z_ordinate) 0
	set gScan(max_visible_z_ordinate) 0
	
	# determine dimensions of plotting area
	set gPlot(x_origin) 	90
	set gPlot(z_end)		410
	set gPlot(z_end_a)		[expr $gPlot(z_end) - 15 ]
	set gPlot(x_end)		500
	set gPlot(z_origin) 	720
	set gPlot(z_origin_a) [expr $gPlot(z_origin) + 15 ]
	set gPlot(x_size)		[expr $gPlot(x_end) - $gPlot(x_origin)]
	set gPlot(z_size)		[expr $gPlot(z_origin) - $gPlot(z_end)]
	
	# draw axes
	eval { $gScan(canvas) create rectangle }				\
		$gPlot(x_origin) $gPlot(z_origin_a)	\
		$gPlot(x_end) $gPlot(z_end_a) 			\
		-outline white -width 2

	# determine positions of plot ticks along x
	set gScan(x_base) $x0
	set gScan(x_range) [expr $x1 - $x0]
	set gScan(x_scale) [expr double($gPlot(x_size))/ $gScan(x_range)]
	set gScan(x_tick_step) [expr double($gScan(x_range)) / 5]
	set gScan(z_range) 0
	
	# place the ticks along x
	set tick_base $gPlot(z_origin_a)
	set tick_top [expr $tick_base - 10]
	set tick_step [expr $gPlot(x_size) / 5]
	set label_top [expr $tick_base + 10] 
	for { set tick 0 } { $tick <= 5 } { incr tick } {
		set tick_x [expr $gPlot(x_origin) + $tick * $tick_step]
		$gScan(canvas) create line	\
			$tick_x $tick_base	\
			$tick_x $tick_top	\
			-fill white -width 2
	}
	draw_x_tick_labels $x0 $x1
	
	# place the label along x
	$gScan(canvas) create text 	\
		[expr $gPlot(x_size) / 2 + $gPlot(x_origin)] \
		[expr $gPlot(z_origin_a) + 30 ]	\
		-text $xLabel	\
		-fill white -anchor n -font $gPlot(legendFont)

	# place the ticks along z
	set tick_base $gPlot(x_origin)
	set tick_top [expr $tick_base + 10]
	set tick_step [expr $gPlot(z_size) / 5]
	for { set tick 0 } { $tick <= 5 } { incr tick } {
		set tick_z [expr $gPlot(z_origin) - $tick * $tick_step]
		$gScan(canvas) create line	\
			$tick_base $tick_z	\
			$tick_top $tick_z		\
			-fill white -width 2
	}

	# place the label along z
	set_z_label $zLabel

	# determine trace colors
	set gPlot(legend_x) [expr $gPlot(x_end) + 60 ]
}


proc set_z_label { labelString } {

	# global variables
	global gScan
	global gPlot

	set gScan(z_label) $labelString
	set length [string length $labelString]
	set label_x [expr $gPlot(x_origin) - 75 ]	
	set label_z [expr int( $gPlot(z_origin) - $gPlot(z_size) / 2 \
		- 6.5 * $length) ]
	
	$gScan(canvas) delete z_label

	for { set i 0 } { $i < $length } { incr i; incr label_z 13 } {
		$gScan(canvas) create text 	\
			$label_x	$label_z -tag z_label \
			-text [string index $labelString $i ] \
			-fill white -anchor center -font $gPlot(legendFont)
	}
	
	if { $gScan(reference) != "none" } {
		$gScan(canvas) bind z_label <Button-1> "set_scan_mode next"
	}
}


proc initialize_3D_plot { x0 x1 xLabel y0 y1 yLabel zLabel } {

	# global variables
	global gScan
	global gPlot
	
	set gScan(min_visible_z_ordinate) 0
	set gScan(max_visible_z_ordinate) 0
	
	
	# swap parameters if x0 > x1
	if { $x0 > $x1 } {
		set temp $x0
		set x0 $x1
		set x1 $temp
	}

	# swap parameters if y0 > y1
	if { $y0 > $y1 } {
		set temp $y0
		set y0 $y1
		set y1 $temp
	}
	
	# determine dimensions of plotting area
	set gPlot(z_origin) 	300
	set gPlot(z_origin_a) [expr $gPlot(z_origin) + 15 ]
	set gPlot(z_end)		100
	set gPlot(z_end_a)		[expr $gPlot(z_end) - 25 ]
	set gPlot(z_size)		[expr $gPlot(z_origin) - $gPlot(z_end)]
	set gScan(z_range) 			500
	set gScan(z_scale)			[expr double($gPlot(z_size)) / $gScan(z_range) ]

	set gPlot(x_origin) 	90
	set gPlot(x_size_x)	260
	set gPlot(x_size_z)	60
	set gScan(x_base) 			$x0
	set gScan(x_range) 			[expr $x1 - $x0]
	set gPlot(dx_dx)		[expr double($gPlot(x_size_x)) / $gScan(x_range) ]
	set gPlot(dz_dx)		[expr - double($gPlot(x_size_z)) / $gScan(x_range) ]

	set gPlot(y_size_x)	260
	set gPlot(y_size_z)	60
	set gScan(y_base) 			$y0
	set gScan(y_range) 			[expr $y1 - $y0]
	set gPlot(y_end_x) 	[expr $gPlot(x_origin) + $gPlot(y_size_x)]
	set gPlot(y_end_z)		[expr $gPlot(z_origin) - $gPlot(y_size_z)]
	set gPlot(dx_dy)		[expr double($gPlot(y_size_x)) / $gScan(y_range) ]
	set gPlot(dz_dy)		[expr double($gPlot(y_size_z)) / $gScan(y_range) ]
	
	# draw z axis
	eval { $gScan(canvas) create line }	\
		[get_scaled_coord_3D $x0 $y0 0]	\
		[get_scaled_coord_3D $x0 $y0 500]\
		-fill white -width 2
	
	# draw x axis
	eval { $gScan(canvas) create line }	\
		[get_scaled_coord_3D $x0 $y0 0]	\
		[get_scaled_coord_3D $x1 $y0 0]	\
		-fill white -width 2

	# draw y axis
	eval { $gScan(canvas) create line } \
		[get_scaled_coord_3D $x1 $y0 0 ]	\
		[get_scaled_coord_3D $x1 $y1 0]	\
		-fill white -width 2

	# draw the grid lines
	for { set grid 0 } { $grid <= 5 } { incr grid } {
		
		# draw a grid line parallel to x
		set x [expr double($gScan(x_range)) * $grid / 5 + $gScan(x_base)]
		set start [get_scaled_coord_3D $x $y0 0]
		set end [get_scaled_coord_3D $x $y1 0]
		eval { $gScan(canvas) create line } \
			$start $end	-fill grey -width 1
		set label_x [expr [lindex $start 0] - 7 ]
		set label_y [expr [lindex $start 1] + 7 ] 
		$gScan(canvas) create text \
			$label_x $label_y			\
			-text [format "%.2f" $x] \
			-fill white -anchor e -font $gPlot(axisFont)
						
		# draw a grid line parallel to y
		set y [expr double($gScan(y_range)) * $grid / 5 + $gScan(y_base)]
		set start [get_scaled_coord_3D $x0 $y 0]
		set end [get_scaled_coord_3D $x1 $y 0]
		eval { $gScan(canvas) create line } \
			$start $end	-fill grey -width 1
		set label_x [expr [lindex $end 0] + 7 ]
		set label_y [expr [lindex $end 1] + 7 ] 
		$gScan(canvas) create text \
			$label_x $label_y			\
			-text [format "%.2f" $y] \
			-fill white -anchor w -font $gPlot(axisFont)
		}
	
	# place the label along x
	$gScan(canvas) create text 160 740 -text $xLabel	\
		-fill white -anchor n -font $gPlot(legendFont)

	# place the label along y
	$gScan(canvas) create text 530 740 -text $yLabel	\
		-fill white -anchor n -font $gPlot(legendFont)

	# place the label along z
	set_z_label $zLabel
#	$gScan(canvas) create text 70 580 \
#		-text $zLabel	-fill white -anchor e -font $gPlot(legendFont)


	# place the ticks along z
	set tick_base $gPlot(x_origin)
	set tick_top [expr $tick_base + 10]
	set tick_step [expr $gPlot(z_size) / 5]
	for { set tick 0 } { $tick <= 5 } { incr tick } {
		set tick_z [expr $gPlot(z_origin) - $tick * $tick_step + 380 ]
		$gScan(canvas) create line	\
			$tick_base $tick_z	\
			$tick_top $tick_z		\
			-fill white -width 2
	}

	set gScan(z_range) 0
	set gPlot(legend_x) 500

}


proc draw_x_tick_labels { x0 x1 } {

	# global variables
	global gScan
	global gPlot

	set gScan(x_tick_step) [expr double($x1 - $x0) / 5]
	set tick_base $gPlot(z_origin_a)
	set tick_step [expr $gPlot(x_size) / 5]
	set label_top [expr $tick_base + 10] 
	
	# delete old labels
	$gScan(canvas) delete x_tick_label
	
	for { set tick 0 } { $tick <= 5 } { incr tick } {
		set tick_x [expr $gPlot(x_origin) + $tick * $tick_step]
		$gScan(canvas) create text \
			$tick_x $label_top -tag x_tick_label \
			-text [format "%.2f" [expr $tick * $gScan(x_tick_step) + $x0 ]] \
			-fill white -anchor n -font $gPlot(axisFont) 
	}
}



proc draw_counts_axis {} {

	# global variables
	global gScan
	global gPlot
	
	if { $gScan(type) == "counts_vs_2_motors" } {
		set z_origin [ expr $gPlot(z_origin) + 380 ]
	} else { 
		set z_origin $gPlot(z_origin)
	}

	# determine new y range
	set last_min_z $gScan(min_visible_z_ordinate)
	set last_max_z $gScan(max_visible_z_ordinate)
	
	set z_range [ expr $gScan(maxCounts) - $gScan(minCounts) ]
		
	if { $z_range < 20 && $gScan(mode) == "abs" || $gScan(mode) == "trans" } {
		set factor 1
		set z_range [expr $z_range * 1000]
		set min [expr $gScan(minCounts) * 1000]	
		set max [expr $gScan(maxCounts) * 1000]	
	} else {
		set factor 0
		set min $gScan(minCounts)	
		set max $gScan(maxCounts)	
	}
	
	if { $z_range < 300 } {
	
		# set upper limit of z axis
		set gScan(max_visible_z_ordinate) [expr ( int( $max / 25 ) + 1 ) * 25 ]
	
		# set lower limit of z axis
		if { $gScan(minCounts) == 0 } {
			set gScan(min_visible_z_ordinate) 0
		} else {
			if { $gScan(min_visible_z_ordinate) < 0 } {
				set gScan(min_visible_z_ordinate) [expr ( int( $min / 25 ) - 2 ) * 25 ]
			} else {
				set gScan(min_visible_z_ordinate) [expr ( int( $min / 25 ) ) * 25 ]			
			}
		}
		
	} else {
		
		# set upper limit of z axis
		set gScan(max_visible_z_ordinate) [expr ( int( $max / 100 ) + 1 ) * 100 ]
	
		# set lower limit of z axis
		if { $gScan(minCounts) == 0 } {
			set gScan(min_visible_z_ordinate) 0
		} else {
			if { $gScan(min_visible_z_ordinate) < 0 } {
				set gScan(min_visible_z_ordinate) [expr ( int( $min / 100) - 2 ) * 100 ]
			} else {
				set gScan(min_visible_z_ordinate) [expr ( int( $min / 100) ) * 100 ]
			}
		}
	}
	
	if { $factor } {
		set gScan(min_visible_z_ordinate) [expr $gScan(min_visible_z_ordinate) / 1000.0 ]
		set gScan(max_visible_z_ordinate) [expr $gScan(max_visible_z_ordinate) / 1000.0 ]
	}
	
	# determine total range of z axis
	set gScan(z_range) [expr $gScan(max_visible_z_ordinate) - $gScan(min_visible_z_ordinate) ]

	# if scale hasn't changed and no refresh requested then return
	if { ( $last_min_z == $gScan(min_visible_z_ordinate) ) && \
		  ( $last_max_z == $gScan(max_visible_z_ordinate) ) && \
			!$gScan(refresh) } {
		return
	}

	# set refresh flag
	set gScan(refresh) 1

	# determine positions of plot ticks along y
	set gScan(z_scale) [expr double($gPlot(z_size)) / $gScan(z_range)]
	set gScan(z_tick_step) [expr double($gScan(z_range)) / 5]
	set tick_base $gPlot(x_origin)
	set tick_top [expr $tick_base + 10]
	set tick_step [expr $gPlot(z_size) / 5]
	set label_margin [expr $tick_base - 10]
	
	# delete old labels
	$gScan(canvas) delete countsLabel
	
	if { $gScan(z_range) < 20 } {
		set format double
		set formatString "%.3f"
	} else {
		set format int
		set formatString "%d"
	}
	
	# label the axis
	for { set tick 0 } { $tick <= 5 } { incr tick } {
		set tick_z [expr $z_origin - $tick * $tick_step]
		$gScan(canvas) create text \
			$label_margin $tick_z 		\
			-text [format $formatString [expr ${format}($tick * $gScan(z_tick_step) + $gScan(min_visible_z_ordinate)) ]] \
			-fill white -anchor e -tag countsLabel -font $gPlot(axisFont)
	}
}




proc clear_scan_canvas {} {

	# global variables
	global gScan

	$gScan(canvas) delete graphics	
}




proc print_plot { colormode } {

	# global variables
	global gScan
	global gCursor
	global gPlot

	set colorMap(white) {0.0 0.0 0.0 setrgbcolor}

	if { $colormode == "bw" } {
		foreach scan $gScan(scans) {
			set colorMap($gScan($scan,color)) {0.0 0.0 0.0 setrgbcolor}
	}
		set colorMap($gCursor(1,color)) {0.0 0.0 0.0 setrgbcolor}
		set colorMap($gCursor(2,color)) {0.0 0.0 0.0 setrgbcolor}
	}
	
	$gScan(canvas) postscript -file plot.ps -colormode color \
		-colormap colorMap -rotate 1 -pagewidth 30c -pageheight 30c\
		-x -70 -y 120 -height 800 -width 800
		
	update

#	$gScan(canvas) configure -bg white
#	$gScan(canvas) itemconfigure all -fill black 	
#	iwidgets::Canvasprintdialog .pcd -modality application -printcmd lp
#	.pcd setcanvas $gScan(canvas)
#	if { [.pcd activate] } {
#		.pcd print
#	}	
#	destroy .pcd	
	
	exec lp plot.ps
}


proc plot_counts_vs_one_motor {} {

	# global variables
	global gScan
	global gPlot

	# update the scan window
	draw_counts_axis
	update_cursor 1
	update_cursor 2
	
	# make sure there are at least two points to plot
	if { $gScan(no_points) } {
		set gScan(no_points) 0
		return
	}

	# clear scan curves if refresh needed
	if { $gScan(refresh) } {
		clear_scan_curves
	}
	
	# loop over all scans
	foreach scan $gScan(scans) {
	
		# make sure this scan is being shown
		if { ! $gScan(show,$scan) } {
			$gScan(canvas) delete $scan
			continue
		}
		
		# now loop over detectors for this scan
		foreach detector $gScan(requestedTraces) {
		
			# recalculate plot curve if needed
			if { $gScan(refresh) } {
				recalculate_scan_curves $scan $detector
			}
			
			# delete the old curve
			$gScan(canvas) delete ${scan}_$detector		
			
			# plot the new curve
			if { [llength $gScan($scan,$detector,x_curve)] < 4 } continue
			set taglist "{$scan $detector ${scan}_$detector}"
			eval {$gScan(canvas) create line} $gScan($scan,$detector,x_curve) {-smooth} \
				$gScan(spline)	{-fill} $gScan($scan,color) {-tag } $taglist -width $gPlot($detector,width)

			# plot derivative
			if { $gScan(show,derivative) } {
				if { [llength $gScan($scan,$detector,derivative)] < 4 } continue	
				eval {$gScan(canvas) create line} $gScan($scan,$detector,derivative) {-smooth} \
					$gScan(spline)	{-fill} red {-tag } $taglist -width $gPlot($detector,width)
			}
		}
	}
	
	# reset refresh flag
	set gScan(refresh) 0
}


proc plot_counts_vs_two_motors {} {

	# global variables
	global gScan
	global gPlot

	# update the scan window
	draw_counts_axis
	
	# clear scan curves if refresh needed
	if { $gScan(refresh) } {
		clear_scan_curves
	}

	# loop over all scans
	foreach scan $gScan(scans) {
		
		# make sure this scan is being shown
		if { ! $gScan(show,$scan) } {
			$gScan(canvas) delete $scan
			continue
		}
		
		# now loop over detectors for this scan
		foreach detector $gScan(requestedTraces) {
		
			# recalculate plot curve and plot previous curves if needed
			if { $gScan(refresh) } {
			
				# recalculate the curves
				recalculate_scan_curves $scan $detector
			
				# erase the old curves
				$gScan(canvas) delete ${scan}_$detector
			
				# plot all the y curves
				if { $gScan(trace_y) } {
					foreach x $gScan(x_ordinates) {
					
						set taglist "{$scan $detector ${scan}_$detector x$x$scan$detector}"
						if { [catch { eval {$gScan(canvas) create line} $gScan($scan,$detector,y_curve,$x)	\
							{-smooth} $gScan(spline) {-fill} $gScan($scan,color) -width $gPlot($detector,width)					\
							{-tag } $taglist }] } break
					}
				}
			
				# plot all the x curves
				if { $gScan(trace_x) } {
					foreach y $gScan(y_ordinates) {
						set taglist "{$scan $detector ${scan}_$detector y$y$scan$detector}"
						if { [catch { eval {$gScan(canvas) create line} $gScan($scan,$detector,x_curve,$y)	\
							 {-smooth} $gScan(spline) {-fill} $gScan($scan,color)	-width $gPlot($detector,width)						\
							{-tag } $taglist }] } break
					}
				}
			} else {
			
				# plot the latest y curve
				if { $gScan(trace_y) } {
					set x $gScan(motor1,position)
					$gScan(canvas) delete x$x$scan$detector
					set taglist "{$scan $detector ${scan}_$detector x$x$scan$detector}"
					catch { eval {$gScan(canvas) create line} $gScan($scan,$detector,y_curve,$x)	\
						{-smooth} $gScan(spline) {-fill} $gScan($scan,color)	{-tag } $taglist -width $gPlot($detector,width) }
				}
			
				# plot the latest x curve		
				set y $gScan(motor2,position)
				$gScan(canvas) delete y$y$scan$detector
				set taglist "{$scan $detector ${scan}_$detector y$y$scan$detector}"
				if { $gScan(trace_x) } {
					catch { eval {$gScan(canvas) create line} $gScan($scan,$detector,x_curve,$y)	\
						{-smooth} $gScan(spline) {-fill} $gScan($scan,color) {-tag } $taglist -width $gPlot($detector,width) }
				}
			}
		}
	}
		
	# reset refresh flag
	set gScan(refresh) 0
}


proc refresh_plot {} {

	# global variables
	global gScan

	# set refresh flag
	set gScan(refresh) 1

	recalculate_min_max_counts

	# call appropriate function
	switch $gScan(type) {
		counts_vs_1_motor		{ plot_counts_vs_one_motor }
		counts_vs_2_motors	{ plot_counts_vs_two_motors }
	}
}


proc zoom { {mode in} {click 0} {x 0} {y 0} } {

	# global variables
	global gScan
	global gPlot
	global gCursor

	# calculate number of points visible in zoomed view
	
	if { $mode == "out" } {
		set gScan(visible_points) [expr int( $gScan(visible_points) * 1.6 ) ]
		if { $gScan(visible_points) > $gScan(motor1,points) } {
			set gScan(visible_points) $gScan(motor1,points) 
		}
	} else {
		if { $mode == "in" } {
			set gScan(visible_points) [expr int( $gScan(visible_points) / 1.414 ) ]
			if { $gScan(visible_points) < 3 } {
				set gScan(visible_points) 3
			}
		} else { 
			if { $mode == "restore" } {
				 set gScan(visible_points) $gScan(motor1,points)
			}
		}
	}
	
	set cursor_1_x $gCursor(1,x_ordinate)
	set cursor_2_x $gCursor(2,x_ordinate)
	set cursor_1_y $gCursor(1,y_ordinate)
	set cursor_2_y $gCursor(2,y_ordinate)
	
	# calculate center point of zoomed view
	if { $mode == "right" } {
			
		set center_point [expr int ( \
			double( $gScan(max_visible_point) + $gScan(min_visible_point) ) / 2 + 1.5 ) ]
	
	} else { if { $mode == "left" } {
	
		set center_point [expr int ( \
			double( $gScan(max_visible_point) + $gScan(min_visible_point) ) / 2 - .5 ) ]
	
	} else { if { $click } {
	
		set y [expr $y + 345]
		if {$x < $gPlot(x_origin) || $x > $gPlot(x_end) ||
			$y > $gPlot(z_origin_a) || $y < $gPlot(z_end_a) } {
			return
		}
		set x [expr (double($x) - $gPlot(x_origin)) / $gScan(x_scale) + \
			$gScan(min_visible_x_ordinate)]
		set center_point [expr int( ($x - $gScan(min_x_ordinate) ) / $gScan(motor1,step) + 0.5 ) ]

	} else { if { !$gCursor(1,show) && !$gCursor(2,show) } { 
	
		set center_point [expr int( double( $gScan(max_visible_point) + $gScan(min_visible_point) ) / 2 + 0.5 ) ]
		
	} else { if { $gCursor(1,show) && !$gCursor(2,show) } { 
	
		set center_point [expr int( ( $gCursor(1,x_ordinate) - $gScan(min_x_ordinate) ) / $gScan(motor1,step) + 0.5 ) ]
	
	} else { if { !$gCursor(1,show) && $gCursor(2,show) } { 
	
		set center_point [expr int( ( $gCursor(2,x_ordinate) - $gScan(min_x_ordinate) ) / $gScan(motor1,step) + 0.5 ) ]
	
	} else {
	
		set center_point [expr int( ( ($gCursor(2,x_ordinate) + $gCursor(1,x_ordinate))/2 - $gScan(min_x_ordinate) ) / $gScan(motor1,step) + 0.5 ) ]
	
	}}}}}}
	
	
	# calculate first point visible
	set gScan(min_visible_point) [expr int( $center_point - ($gScan(visible_points)) / 2  ) ]
	if { $gScan(min_visible_point) < 0 } {
		set gScan(min_visible_point) 0
	}	
	
	# calculate last point visible
	set gScan(max_visible_point) [expr $gScan(min_visible_point) + $gScan(visible_points) - 1]
	if { $gScan(max_visible_point) > [expr $gScan(motor1,points) - 1] } {
		set gScan(max_visible_point) [expr $gScan(motor1,points) - 1]
		set gScan(min_visible_point) [expr $gScan(max_visible_point) - $gScan(visible_points) + 1]
	}	
	
	# calculate position of first and last visible points
	set gScan(min_visible_x_ordinate)  [lindex $gScan(x_ordinates) $gScan(min_visible_point)]
	set gScan(max_visible_x_ordinate) [lindex $gScan(x_ordinates) $gScan(max_visible_point)]
	
	# recalculate scale factor
	set gScan(x_scale) [expr double($gPlot(x_size))/ ( $gScan(max_visible_x_ordinate) \
		- $gScan(min_visible_x_ordinate) )]
	
	# redraw x tick labels
	draw_x_tick_labels $gScan(min_visible_x_ordinate)  $gScan(max_visible_x_ordinate)
	
	# redraw z tick labels
	recalculate_min_max_counts
	draw_counts_axis
		
	# redraw the plot
	refresh_plot

	# redraw cursors
	correct_cursor_position 1 $cursor_1_x $cursor_1_y
	correct_cursor_position 2 $cursor_2_x $cursor_2_y
	
	# set state of zoom out and restore buttons
	if { $gScan(visible_points) < $gScan(motor1,points) } {
		$gScan(zoomOutButton) configure -state normal
		$gScan(zoomRestoreButton) configure -state normal
	} else {
		$gScan(zoomOutButton) configure -state disabled
		$gScan(zoomRestoreButton) configure -state disabled
	}

	# set state of zoom in button
	if { $gScan(visible_points) > 3 } {
		$gScan(zoomInButton) configure -state normal
	} else {
		$gScan(zoomInButton) configure -state disabled
	}

	# set state of zoom left button
	if { $gScan(min_visible_point) > 0 } {
		$gScan(zoomLeftButton) configure -state normal
	} else {
		$gScan(zoomLeftButton) configure -state disabled
	}

	# set state of zoom right button
	if { $gScan(max_visible_point) < [expr $gScan(motor1,points) - 1] } {
		$gScan(zoomRightButton) configure -state normal
	} else {
		$gScan(zoomRightButton) configure -state disabled
	}
}


proc reset_zoom {} {

	# global variables
	global gScan

	set gScan(min_x_ordinate) [lindex $gScan(x_ordinates) 0]
	set gScan(max_x_ordinate) [lindex $gScan(x_ordinates) [expr $gScan(motor1,points) - 1] ]
	set gScan(min_visible_x_ordinate) $gScan(min_x_ordinate)
	set gScan(max_visible_x_ordinate) $gScan(max_x_ordinate)
	set gScan(visible_points) \
		[expr int(($gScan(max_visible_x_ordinate) - $gScan(min_visible_x_ordinate))/$gScan(motor1,step) + 1)]
	set gScan(min_visible_point) 0
	set gScan(max_visible_point) [expr $gScan(visible_points) - 1]
}
