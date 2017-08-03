# load the required standard packages
package require Itcl
package require Iwidgets
package require BWidget
package require BLT

package provide PlotWinRAWCURR 1.0

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

class DCS::PlotWinRAWCURR {
	inherit ::DCS::ComponentGateExtension

	### set variables
	#itk_option define -controlSystem controlSystem ControlSystem ::dcss
	itk_option define -stringName stringName StringName ""
	itk_option define -mdiHelper mdiHelper MdiHelper ""

	#setup DeviceFactory to get device list
	protected variable deviceFactory
       set deviceFactory [DCS::DeviceFactory::getObject]

	### setup variables
	# Data on Demand 1(DD1) port data
	#protected variable dd1_dd_va_mon_obj
	#protected variable dd1_dd_vb_mon_obj
	#protected variable dd1_dd_vc_mon_obj
	#protected variable dd1_dd_vd_mon_obj
	#protected variable dd1_dd_st_mon_obj
	#protected variable dd1_dd_finished_mon_obj
	#protected variable dd1_dd_request_cmd_obj

	# ADCCW port data
	#protected variable adccw_va_mon_obj
	#protected variable adccw_vb_mon_obj
	#protected variable adccw_vc_mon_obj
	#protected variable adccw_vd_mon_obj
	#protected variable adccw_st_mon_obj

	#protected variable adccw_finished_mon_obj
	#protected variable adccw_request_cmd_obj
	#protected variable adccw_ignore_trig_mon_obj
	#protected variable adccw_ignore_trig_sp_obj

	# SA port
	protected variable sa_a_mon_obj
	protected variable sa_b_mon_obj
	protected variable sa_c_mon_obj
	protected variable sa_d_mon_obj
	protected variable sa_sum_mon_obj

	# ENV port
	protected variable env_range_mon_obj


	global liberaNo
	global bpmNo

	### setup methods
	protected method updatepv
	protected method trigRequestCmd
	protected method getPlotData
	protected method cpPlotData
	protected method saveIntoFile
	protected method trigIGN

	public method handleVector1
	public method handleVector2
	public method handleVector3
	public method handleVector4
	public method handleVector7


	### set proc
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
		#puts "PlotWinRAWCURR destructor was called."
		::mediator unregister $this $sa_a_mon_obj contents
		::mediator unregister $this $sa_b_mon_obj contents
		::mediator unregister $this $sa_c_mon_obj contents
		::mediator unregister $this $sa_d_mon_obj contents
		::mediator unregister $this $sa_sum_mon_obj contents
	}

}



body DCS::PlotWinRAWCURR::constructor {args} {

	toplevel .tpwRC
	wm title .tpwRC "Current Plot"

#wm protocol .tpwRC WM_DELETE_WINDOW {
#    if {[tk_messageBox -message "Quit?" -type yesno] eq "yes"} {
#       #exit
#	#puts "close window."
#	destroy .tpwRC
#    }
#}


	set liberaNo [lindex $args 0]
	set bpmNo [lindex $args 1]

	updatepv $liberaNo $bpmNo

	#puts "trig_sp val is"
	#puts [$adccw_ignore_trig_sp_obj getContents]


	frame .tpwRC.f1
	frame .tpwRC.f2
	frame .tpwRC.f3

	itk_component add f1l {
		label .tpwRC.f1.l1 -text "Ch.A current \[A\]" -width 20
		label .tpwRC.f1.l2 -text "Ch.B current \[A\]" -width 20
		label .tpwRC.f2.l3 -text "Ch.C current \[A\]" -width 20
		label .tpwRC.f2.l4 -text "Ch.D current \[A\]" -width 20
		label .tpwRC.f3.l5 -text "SUM  current \[A\]" -width 20
		label .tpwRC.f3.ll -text "" -width 51
	}
	set chacurr 0
	set chbcurr 0
	set chccurr 0
	set chdcurr 0
	set chsumcurr 0

	#itk_component add debugfr {
	#	DCS::LiberaStringViewLabel .tpwRC.f1.ldbg1 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_a_mon_obj 
	#	DCS::LiberaStringViewLabel .tpwRC.f1.ldbg2 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_b_mon_obj
	#	DCS::LiberaStringViewLabel .tpwRC.f1.ldbg3 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_c_mon_obj
	#	DCS::LiberaStringViewLabel .tpwRC.f1.ldbg4 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_d_mon_obj
	#	DCS::LiberaStringViewLabel .tpwRC.f1.ldbg5 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_sum_mon_obj
	#} {}

	itk_component add f1v1 {
		label .tpwRC.f1.l6 -text $chacurr -width 30 -bg gray} {keep -text} 
	itk_component add f1v2 {
		label .tpwRC.f1.l7 -text $chbcurr -width 30 -bg gray} {keep -text} 
	itk_component add f1v3 {
		label .tpwRC.f2.l8 -text $chccurr -width 30 -bg gray} {keep -text} 
	itk_component add f1v4 {
		label .tpwRC.f2.l9 -text $chdcurr -width 30 -bg gray} {keep -text} 
	itk_component add f1v5 {
		label .tpwRC.f3.l10 -text $chsumcurr -width 30 -bg gray} {keep -text} 

	#itk_component add trigonoff {
	#	DCS::LiberaStringViewLabel .tpwRC.f1.label1 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $adccw_ignore_trig_mon_obj } {} 
	#pack .tpwRC.f1.label1

	#itk_component add trigign {
	#	button .tpwRC.f1.b0 -text "TRIGGER-IGNORED" -command [code $this trigIGN .tpwRN.f1.b0 $liberaNo $bpmNo]
	#} {keep -text}

	#itk_component add readbutton {
	#	button .tpwRC.f1.b1 -text "DD Triger CMD" -command [code $this trigRequestCmd]
	#} {}

	#itk_component add getpvdata {
	#	button .tpwRC.f1.b2 -text "Update Plot" -command [code $this getPlotData]
	#} {}

	#itk_component add ent {
	#	button .tpwRC.f1.b3 -text "Save data" -command [code $this saveIntoFile]
	#} {}

	pack .tpwRC.f1.l1 .tpwRC.f1.l6 .tpwRC.f1.l2 .tpwRC.f1.l7 -side left
	pack .tpwRC.f2.l3 .tpwRC.f2.l8 .tpwRC.f2.l4 .tpwRC.f2.l9 -side left
	pack .tpwRC.f3.l5 .tpwRC.f3.l10 .tpwRC.f3.ll -side left
	pack .tpwRC.f1 .tpwRC.f2 .tpwRC.f3
	

	### setup graph plot option##################################################
	### variable definitions
	#puts "LiberaNo is"
	#puts $args
	set liberaNo [lindex $args 0]
	set bpmNo [lindex $args 1]

	updatepv $liberaNo $bpmNo

	blt::vector create liberax1
	liberax1 set [range 300]

	blt::vector create sa_a
	blt::vector create sa_b
	blt::vector create sa_c
	blt::vector create sa_d
	blt::vector create sa_sum
	#blt::vector create liberay1
	#blt::vector create liberay2
	#blt::vector create liberay3
	#blt::vector create liberay4
	#blt::vector create liberay5

	sa_a set ""
	sa_b set ""
	sa_c set ""
	sa_d set ""
	sa_sum set ""

	# dummy data
	#liberay1 set {343 506 723 77 273 128 723 546 870 228 74 393 934 199 80 35 884 860 737 507 }
	#liberay2 set {901 308 722 572 931 413 351 742 471 590 120 296 839 281 621 331 341 271 29 238 }
	#liberay3 set {343 506 723 77 273 128 723 546 870 228 74 393 934 199 80 35 884 860 737 507 }
	#liberay4 set {901 308 722 572 931 413 351 742 471 590 120 296 839 281 621 331 341 271 29 238 }
	#liberay5 expr {liberay1 + liberay2 + liberay3 + liberay4}
	
	#set sa_x [range 300]
	#set sa_y [range 300]

	#puts "vector liberay1 length is [liberay1 length]"
	### setup graph configurations

	frame .tpwRC.fl
	frame .tpwRC.fr
	frame .tpwRC.frr

	itk_component add atplot {
		blt::graph .tpwRC.fl.g1 -title "Ch. A signal hist" -plotbackground white -height 250 -width 330} {}
	.tpwRC.fl.g1 element create line1 -xdata liberax1 -ydata sa_a
	.tpwRC.fl.g1 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRC.fl.g1 element show
	.tpwRC.fl.g1 axis configure x -title {samples} -max 300
	.tpwRC.fl.g1 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRC.fl.g1 grid configure -hide no -dashes { 2 2 }

	itk_component add btplot {
		blt::graph .tpwRC.fl.g2 -title "Ch. C signal hist" -plotbackground white -height 250 -width 330} {}
	.tpwRC.fl.g2 element create line1 -xdata liberax1 -ydata sa_c
	.tpwRC.fl.g2 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRC.fl.g2 element show
	.tpwRC.fl.g2 axis configure x -title {samples} -max 300
	.tpwRC.fl.g2 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRC.fl.g2 grid configure -hide no -dashes { 2 2 }

	itk_component add ctplot {
		blt::graph .tpwRC.fr.g1 -title "Ch.B signal hist" -plotbackground white -height 250 -width 330} {}
	.tpwRC.fr.g1 element create line1 -xdata liberax1 -ydata sa_b
	.tpwRC.fr.g1 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRC.fr.g1 element show
	.tpwRC.fr.g1 axis configure x -title {samples} -max 300
	.tpwRC.fr.g1 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRC.fr.g1 grid configure -hide no -dashes { 2 2 }

	itk_component add dtplot {
		blt::graph .tpwRC.fr.g2 -title "Ch.D signal hist" -plotbackground white -height 250 -width 330} {}
	.tpwRC.fr.g2 element create line1 -xdata liberax1 -ydata sa_d
	.tpwRC.fr.g2 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRC.fr.g2 element show
	.tpwRC.fr.g2 axis configure x -title {samples} -max 300
	.tpwRC.fr.g2 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRC.fr.g2 grid configure -hide no -dashes { 2 2 }

	itk_component add sumtplot {
		blt::graph .tpwRC.frr.g3 -title "Signal sum hist" -plotbackground white -height 505 -width 330} {}
	.tpwRC.frr.g3 element create line1 -xdata liberax1 -ydata sa_sum
	.tpwRC.frr.g3 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRC.frr.g3 element show
	.tpwRC.frr.g3 axis configure x -title {samples} -max 300
	.tpwRC.frr.g3 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRC.frr.g3 grid configure -hide no -dashes { 2 2 }


	# pack graph

	pack .tpwRC.fl.g1 .tpwRC.fl.g2 -pady 5
	pack .tpwRC.fr.g1 .tpwRC.fr.g2 -pady 5
	pack .tpwRC.frr.g3 -pady 5
	pack .tpwRC.fl .tpwRC.fr .tpwRC.frr -side left

	set deviceFactory [DCS::DeviceFactory::getObject]
	#puts $deviceFactory


	#set dd1_dd_va_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd_va_mon]

	set sa_a_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_a_mon]
	set sa_a_mon_val [$sa_a_mon_obj getContents]
	set sa_b_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_b_mon]
	set sa_b_mon_val [$sa_b_mon_obj getContents]
	set sa_c_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_c_mon]
	set sa_c_mon_val [$sa_c_mon_obj getContents]
	set sa_d_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_d_mon]
	set sa_d_mon_val [$sa_d_mon_obj getContents]
	set sa_sum_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_sum_mon]
	set sa_sum_mon_val [$sa_sum_mon_obj getContents]
	set env_range_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_range_mon]
	set env_range_mon_val [$env_range_mon_obj getContents]
	#puts $env_range_mon_val

	#register valiables to monitor value change
	::mediator register $this $sa_a_mon_obj contents DCS::PlotWinRAWCURR::handleVector1
	::mediator register $this $sa_b_mon_obj contents DCS::PlotWinRAWCURR::handleVector2
	::mediator register $this $sa_c_mon_obj contents DCS::PlotWinRAWCURR::handleVector3
	::mediator register $this $sa_d_mon_obj contents DCS::PlotWinRAWCURR::handleVector4
	::mediator register $this $sa_sum_mon_obj contents DCS::PlotWinRAWCURR::handleVector7
	
	#eval itk_initialize $args
	announceExist
}

body DCS::PlotWinRAWCURR::updatepv {liberaNo bpmNo} {
### This method will update variables connected with EPICS records.

	#puts $liberaNo
	#puts $bpmNo

	set deviceFactory [DCS::DeviceFactory::getObject]
	#puts $deviceFactory

	#set dd1_dd_va_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_va_mon]
	#set dd1_dd_vb_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_vb_mon]
	#set dd1_dd_vc_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_vc_mon]
	#set dd1_dd_vd_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_vd_mon]

	set sa_a_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_a_mon]
	set sa_b_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_b_mon]
	set sa_c_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_c_mon]
	set sa_d_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_d_mon]
	set sa_sum_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_sum_mon]
	set env_range_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_range_mon]


	#set dd1_dd_st_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_st_mon]
	#set dd1_dd_finished_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_finished_mon]
	#puts "dd1_dd_finished_mon_obj is $dd1_dd_finished_mon_obj"
	#set dd1_dd_request_cmd_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_request_cmd]

}


body DCS::PlotWinRAWCURR::trigRequestCmd {} {
### This method send trigger request for DD1 port via epicsgw
	$dd1_dd_request_cmd_obj sendContentsToServer 1
	after 10000 [code $this getPlotData]
}

body DCS::PlotWinRAWCURR::getPlotData {args} {
	### This method update variables of DD1 port
	### Updated vaules will be copied to blt vector variable

	set dd1_dd_va_mon_val [$dd1_dd_va_mon_obj getContents]
	set dd1_dd_vb_mon_val [$dd1_dd_vb_mon_obj getContents]
	set dd1_dd_vc_mon_val [$dd1_dd_vc_mon_obj getContents]
	set dd1_dd_vd_mon_val [$dd1_dd_vd_mon_obj getContents]
	set dd1_dd_st_mon_val [$dd1_dd_st_mon_obj getContents]
	#puts $dd1_dd_va_mon_val
	after 500 [code $this cpPlotData] 

}

body DCS::PlotWinRAWCURR::cpPlotData {} {
	### This method cp data to blt vector
	liberay1 set $dd1_dd_va_mon_val
	liberay2 set $dd1_dd_vb_mon_val
	liberay3 set $dd1_dd_vc_mon_val
	liberay4 set $dd1_dd_vd_mon_val
}

body DCS::PlotWinRAWCURR::saveIntoFile {} {
# Savefile file

    set ftype { { "TEXT Files" .txt } { "All Files" * }}
    set fname [ tk_getSaveFile -filetypes $ftype -parent . ]
    if { $fname == "" } return

    set fileid [ open $fname "w" ]

set data "# index Ch.A Ch.B Ch.C Ch.d X Y of $sa_a_mon_obj"
set maxlen [liberay1 length]
    #puts $fileid $data
for {set i 0} {$i < $maxlen} {incr i} {
	#lappend data \n
	set data ""
	lappend data "$i"
	lappend data [liberay1 index $i]
	lappend data [liberay2 index $i]
	lappend data [liberay3 index $i]
	lappend data [liberay4 index $i]
	lappend data [liberay5 index $i]
	lappend data [liberay6 index $i]
    #puts $fileid $data
}

    close $fileid

}

body DCS::PlotWinRAWCURR::handleVector1 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	set sa_a_mon_val [$sa_a_mon_obj getContents]
	set env_range_mon_val [$env_range_mon_obj getContents]
	#puts $contents_
	#puts [expr {2*$sa_a_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	.tpwRC.f1.l6 configure -text [format {%0.3g} [expr {2*$sa_a_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]]
	if { ! $targetReady_} return
	if {[sa_a length] > 300} then {
		sa_a delete 0
		#sa_a append $contents_
		sa_a append [expr {2*$sa_a_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	} else {
		#sa_a append $contents_
		sa_a append [expr {2*$sa_a_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	}
}


body DCS::PlotWinRAWCURR::handleVector2 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	set sa_b_mon_val [$sa_b_mon_obj getContents]
	set env_range_mon_val [$env_range_mon_obj getContents]
	#puts [expr {2*$sa_b_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	.tpwRC.f1.l7 configure -text [format {%0.3g} [expr {2*$sa_b_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]]
	if { ! $targetReady_} return
	if {[sa_b length] > 300} then {
		sa_b delete 0
		#sa_b append $contents_
		sa_b append [expr {2*$sa_b_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	} else {
		#sa_b append $contents_
		sa_b append [expr {2*$sa_b_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	}
}


body DCS::PlotWinRAWCURR::handleVector3 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	set sa_c_mon_val [$sa_c_mon_obj getContents]
	set env_range_mon_val [$env_range_mon_obj getContents]
	#puts [expr {2*$sa_c_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	.tpwRC.f2.l8 configure -text [format {%0.3g} [expr {2*$sa_c_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]]
	if { ! $targetReady_} return
	if {[sa_c length] > 300} then {
		sa_c delete 0
		#sa_c append $contents_
		sa_c append [expr {2*$sa_c_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	} else {
		#sa_c append $contents_
		sa_c append [expr {2*$sa_c_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	}
}


body DCS::PlotWinRAWCURR::handleVector4 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	set sa_d_mon_val [$sa_d_mon_obj getContents]
	set env_range_mon_val [$env_range_mon_obj getContents]
	#puts [expr {2*$sa_d_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	.tpwRC.f2.l9 configure -text [format {%0.3g} [expr {2*$sa_d_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]]
	if { ! $targetReady_} return
	if {[sa_d length] > 300} then {
		sa_d delete 0
		#sa_d append $contents_
		sa_d append [expr {2*$sa_d_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	} else {
		#sa_d append $contents_
		sa_d append [expr {2*$sa_d_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	}
}


body DCS::PlotWinRAWCURR::handleVector7 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	set sa_sum_mon_val [$sa_sum_mon_obj getContents]
	set env_range_mon_val [$env_range_mon_obj getContents]
	#puts [expr {2*$sa_sum_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	.tpwRC.f3.l10 configure -text [format {%0.3g} [expr {2*$sa_sum_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]]
	if { ! $targetReady_} return
	if {[sa_sum length] > 300} then {
		sa_sum delete 0
		#sa_sum append $contents_
		sa_sum append [expr {2*$sa_sum_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	} else {
		#sa_sum append $contents_
		sa_sum append [expr {2*$sa_sum_mon_val*(3.2768/pow(2,31))/(pow(10,(9-$env_range_mon_val)))*1000000}]
	}
}


body DCS::PlotWinRAWCURR::trigIGN {bw liberaNo bpmNo} {
	# this method is for waveform data triger.
	#puts "testtesttest"
	#set deviceFactory [DCS::DeviceFactory::getObject]
	#set adccw_ignore_trig_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_ignore_trig_mon]
	#set adccw_ignore_trig_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_ignore_trig_sp]
	set adccw_ignore_trig_mon_val [$adccw_ignore_trig_mon_obj getContents]
	#puts $adccw_ignore_trig_mon_val
	if {$adccw_ignore_trig_mon_val == 1} {
		puts "ignored to arrowed"
		$adccw_ignore_trig_sp_obj sendContentsToServer 0
		$bw configure -text "TRIGGER-ARROWED"
	} else {
		puts "arrowed to ignored"
		$adccw_ignore_trig_sp_obj sendContentsToServer 1
		$bw configure -text "TRIGGER-IGNORED"
	}
}


