# load the required standard packages
package require Itcl
package require Iwidgets
package require BWidget
package require BLT

package provide PlotWinXY 1.0

### This will load our own panedwindow using class IPanedwindow
package require IPanedwindow
namespace import ::itcl::*
package require DCSUtil
package require DCSProtocol
package require DCSComponent
package require DCSDeviceFactory
package require DCSScrolledFrame
package require DCSDevice
package require DCSString
### import some package to access variables
package require ComponentGateExtension

class DCS::PlotWinXY {
	inherit ::DCS::ComponentGateExtension

	### set variables
	#itk_option define -controlSystem controlSystem ControlSystem ::dcss
	itk_option define -stringName stringName StringName ""
	itk_option define -mdiHelper mdiHelper MdiHelper ""

	#setup DeviceFactory to get device list
	protected variable deviceFactory
       set deviceFactory [DCS::DeviceFactory::getObject]

	#slow aquisiton(SA)port data
	protected variable sa_a_mon_obj
	protected variable sa_b_mon_obj
	protected variable sa_c_mon_obj
	protected variable sa_d_mon_obj
	protected variable sa_x_mon_obj
	protected variable sa_y_mon_obj
	protected variable sa_q_mon_obj
	protected variable sa_sum_mon_obj

	global radialpos


### set method

	public method handleVector5
	public method handleVector6
	protected method updatepv
	protected method calcRadialPosition

### set procedure

	proc range args {
		foreach {start stop step} [switch -exact -- [llength $args] {
			1 {concat 0 $args 1}
			2 {concat   $args 1}
			3 {concat   $args  }
			default {error {wrong # of args: should be "range ?start? stop ?step?"}}
       	}] break
       	if {$step == 0} {error "cannot create a range when step == 0"}
       	set range [list]
       	while {$step > 0 ? $start < $stop : $stop < $start} {
			lappend range $start
			incr start $step
        	}
       	return $range
	}

	constructor { args } {}

	destructor {
		#puts "PlotWinXY destructor called"
		mediator unregister $this $sa_x_mon_obj contents
		mediator unregister $this $sa_y_mon_obj contents
	}
}

body DCS::PlotWinXY::constructor {args} {
	#puts "LiberaNo is"
	#puts $args
	set liberaNo [lindex $args 0]
	set bpmNo [lindex $args 1]

	updatepv $liberaNo $bpmNo

	toplevel .tp0
	label .tp0.l1 -text "XY (Y1Y2) plot from SA port"
	pack .tp0.l1

	wm title .tp0 "Position Plot"

puts $this

	# Setup discriptive values
	itk_component add discf {
		frame .tp0.graphf
	}

	itk_component add discrff {
		frame .tp0.graphf.f1
		frame .tp0.graphf.f2
		frame .tp0.graphf.f3
	}
	itk_component add discrval {
        	label .tp0.graphf.f1.l1 -text "X position \[nm\]" -width 15
		label .tp0.graphf.f2.l1 -text "Y position \[nm\]" -width 15
		label .tp0.graphf.f3.l1 -text "Radial position \[nm\]" -width 20
		} { 
			keep -background -foreground -font
		}
	set radialpos 0
	itk_component add discrftext {
		DCS::LiberaStringViewLabel .tp0.graphf.f1.l2 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_x_mon_obj 

		DCS::LiberaStringViewLabel .tp0.graphf.f2.l2 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_y_mon_obj 

		#DCS::LiberaStringViewLabel .tp0.graphf.f3.l2 \
		#	-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_sum_mon_obj 
	} {}
	itk_component add radialposl {
		label .tp0.graphf.f3.l2 -text $radialpos -width 15 -bg gray} {keep -text} 		

	pack .tp0.graphf.f1.l1 .tp0.graphf.f1.l2 -side left
	pack .tp0.graphf.f2.l1 .tp0.graphf.f2.l2 -side left
	pack .tp0.graphf.f3.l1 .tp0.graphf.f3.l2 -side left
		
	pack .tp0.graphf.f1 .tp0.graphf.f2 .tp0.graphf.f3 -side left
	pack .tp0.graphf


	### setup graph plot option##################################################

	### variable definitions
	blt::vector create liberax1
	liberax1 set [range 300]

	blt::vector create sa_x
	blt::vector create sa_y 

	sa_x set ""
	sa_y set ""

	# dummy value
	#sa_x set {343 506 723 77 273 128 723 546 870 228 74 393 934 199 80 35 884 860 737 507 }
	#sa_y set {901 308 722 572 931 413 351 742 471 590 120 296 839 281 621 331 341 271 29 238 }
	
	#set sa_x [range 300]
	#set sa_y [range 300]


	#puts "vector liberay1 length is [liberay1 length]"
	### setup graph configurations

	frame .tp0.fl
	frame .tp0.fr

	itk_component add xtplot {
		blt::graph .tp0.fl.g1 -title "X(Y1) position hist" -plotbackground white -height 250 -width 330} {}
	.tp0.fl.g1 element create line1 -xdata liberax1 -ydata sa_x
	.tp0.fl.g1 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tp0.fl.g1 element show
	.tp0.fl.g1 axis configure x -title {SA samples (10 S/sec)} -max 300
	.tp0.fl.g1 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tp0.fl.g1 grid configure -hide no -dashes { 2 2 }

	itk_component add ytplot {
		blt::graph .tp0.fl.g2 -title "Y(Y2) position hist" -plotbackground white -height 250 -width 330} {}
	.tp0.fl.g2 element create line1 -xdata liberax1 -ydata sa_y
	.tp0.fl.g2 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tp0.fl.g2 element show
	.tp0.fl.g2 axis configure x -title {SA samples (10 S/sec)} -max 300
	.tp0.fl.g2 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tp0.fl.g2 grid configure -hide no -dashes { 2 2 }

	itk_component add xyplot {
		blt::graph .tp0.fr.g3 -title "XY plot" -plotbackground white -height 500 -width 500} {}
	.tp0.fr.g3 element create line1 -xdata sa_x -ydata sa_y
	.tp0.fr.g3 element configure line1 -symbol circle -color red -outline black -linewidth 0 -pixels 0.05i
	.tp0.fr.g3 element show
	.tp0.fr.g3 axis configure x -title {SA X(Y1) position (mm)} 
	.tp0.fr.g3 axis configure y -title {SA Y(Y2) position (mm)} 
	.tp0.fr.g3 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tp0.fr.g3 grid configure -hide no -dashes { 2 2 }


	# pack graph
	pack .tp0.fl .tp0.fr -side left
	pack .tp0.fl.g1 .tp0.fl.g2
	pack .tp0.fr.g3
	

	#set liberaNo 0
	#set bpmNo 0
	#puts ${liberaNo}_${bpmNo}_sa_x_mon
	set deviceFactory [DCS::DeviceFactory::getObject]
	#puts $deviceFactory

	set sa_x_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_x_mon]
	set sa_x_mon_val [$sa_x_mon_obj getContents]
	#puts $sa_x_mon_val
	set sa_y_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_y_mon]
	set sa_y_mon_val [$sa_y_mon_obj getContents]
	set sa_sum_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_sum_mon]
	set sa_sum_mon_val [$sa_sum_mon_obj getContents]

	set radialpos [expr {sqrt($sa_x_mon_val * $sa_x_mon_val + $sa_y_mon_val * $sa_y_mon_val) } ]

	#register valiables to monitor value change
	::mediator register $this $sa_x_mon_obj contents DCS::PlotWinXY::handleVector5
	::mediator register $this $sa_y_mon_obj contents DCS::PlotWinXY::handleVector6
	#::mediator register $this $sa_sum_mon_obj contents DCS::PlotWinXY::calcRadialPosition

	#eval itk_initialize $args
	announceExist


}

body DCS::PlotWinXY::handleVector5 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	set sa_x_mon_val [$sa_x_mon_obj getContents]
	set sa_y_mon_val [$sa_y_mon_obj getContents]
	set tcl_precision 3
	.tp0.graphf.f3.l2 configure -text [expr {round(100*sqrt($sa_x_mon_val * $sa_x_mon_val + $sa_y_mon_val * $sa_y_mon_val))/100.0 }]
	if { ! $targetReady_} return
	if {[sa_x length] > 300} then {
		sa_x delete 0
		sa_x append $contents_
	} else {
		sa_x append $contents_
	}
}

body DCS::PlotWinXY::handleVector6 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	set sa_x_mon_val [$sa_x_mon_obj getContents]
	set sa_y_mon_val [$sa_y_mon_obj getContents]
	set tcl_precision 3
	.tp0.graphf.f3.l2 configure -text [expr {round(100*sqrt($sa_x_mon_val * $sa_x_mon_val + $sa_y_mon_val * $sa_y_mon_val))/100.0 }]
	if { ! $targetReady_} return
	if {[sa_y length] > 300} then {
		sa_y delete 0
		sa_y append $contents_
	} else {
		sa_y append $contents_
		
	}
}

body DCS::PlotWinXY::updatepv {liberaNo bpmNo} {
### This method will update variables connected with EPICS records.

	#puts $liberaNo 
	#puts $bpmNo 
	#puts ${liberaNo}_${bpmNo}_sa_a_mon_inupdatepv
	set deviceFactory [DCS::DeviceFactory::getObject]
	#puts $deviceFactory

	#slow aquisiton data
	set sa_a_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_a_mon]
	set sa_b_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_b_mon]
	set sa_c_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_c_mon]
	set sa_d_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_d_mon]
	set sa_x_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_x_mon]
	set sa_y_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_y_mon]
	set sa_q_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_q_mon]
	set sa_sum_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_sum_mon]

	#puts "a_mon value is"
	#puts [$sa_a_mon_obj getContents]

}

body DCS::PlotWinXY::calcRadialPosition {stringName_ targetReady_ alias_ contents_ -} {
	if { ! $targetReady_} return
	#puts $sa_x_mon_val
	#set radialposition [expr {sqrt($sa_x_mon_val * $sa_x_mon_val + $sa_y_mon_val * $sa_y_mon_val) } ]
	#puts radialposition
	#return radialposition
}

