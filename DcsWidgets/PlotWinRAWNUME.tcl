# load the required standard packages
package require Itcl
package require Iwidgets
package require BWidget
package require BLT

package provide PlotWinRAWNUME 1.0

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






class DCS::PlotWinRAWNUME {
	inherit ::DCS::ComponentGateExtension
	#inherit ::DCS::LiberaDetailView

	### set variables
	#itk_option define -controlSystem controlSystem ControlSystem ::dcss
	itk_option define -stringName stringName StringName ""
	itk_option define -mdiHelper mdiHelper MdiHelper ""

	#setup DeviceFactory to get device list
	protected variable deviceFactory
       set deviceFactory [DCS::DeviceFactory::getObject]

	### setup variables

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

	public method unregisterall

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
		#puts "PlotWinRAWNUME destructor was called"
		::mediator unregister $this $sa_a_mon_obj contents
		::mediator unregister $this $sa_b_mon_obj contents
		::mediator unregister $this $sa_c_mon_obj contents
		::mediator unregister $this $sa_d_mon_obj contents
		::mediator unregister $this $sa_sum_mon_obj contents
	}
}



body DCS::PlotWinRAWNUME::constructor { args } {
	toplevel .tpwRN
	#label .tpwRN.l1 -text "ADC RAW NUMEent display\n"
	#pack .tpwRN.l1
	wm title .tpwRN "Numeric DATA Plot"

	set liberaNo [lindex $args 0]
	set bpmNo [lindex $args 1]

	updatepv $liberaNo $bpmNo

	#puts "sa_a_mon val is "
	#$sa_a_mon_obj sendContentsToServer 100
	#puts [$sa_a_mon_obj getContents]
	#puts "trig_sp val is"
	#puts [$adccw_ignore_trig_sp_obj getContents]


	frame .tpwRN.f1
	frame .tpwRN.f2
	frame .tpwRN.f3

	itk_component add f1l {
		label .tpwRN.f1.l1 -text "Ch.A numeric val:" -width 20
		label .tpwRN.f1.l2 -text "Ch.B numeric val:" -width 20
		label .tpwRN.f2.l3 -text "Ch.C numeric val:" -width 20
		label .tpwRN.f2.l4 -text "Ch.D numeric val:" -width 20
		label .tpwRN.f3.l5 -text "SUM  numeric val:" -width 20
		label .tpwRN.f3.ll -text "" -width 38
	}

	itk_component add discrftext {
		DCS::LiberaStringViewLabel .tpwRN.f1.l6 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_a_mon_obj 

		DCS::LiberaStringViewLabel .tpwRN.f1.l7 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_b_mon_obj 

		DCS::LiberaStringViewLabel .tpwRN.f2.l8 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_c_mon_obj 

		DCS::LiberaStringViewLabel .tpwRN.f2.l9 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_d_mon_obj 

		DCS::LiberaStringViewLabel .tpwRN.f3.l10 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_sum_mon_obj  
	} {}

	#itk_component add trigonoff {
	#	DCS::LiberaStringViewLabel .tpwRN.f1.label1 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $adccw_ignore_trig_mon_obj } {} 
	#pack .tpwRN.f1.label1

	#itk_component add trigign {
	#	button .tpwRN.f1.b0 -text "TRIGGER-IGNORED" -command [code $this trigIGN .tpwRN.f1.b0 $liberaNo $bpmNo]
	#} {keep -text}

	#itk_component add readbutton {
	#	button .tpwRN.f1.b1 -text "ADC Trigger CMD" -command [code $this trigRequestCmd]
	#} {}

	#itk_component add getpvdata {
	#	button .tpwRN.f1.b2 -text "Update Plot" -command [code $this getPlotData]
	#} {}

	#itk_component add ent {
	#	button .tpwRN.f1.b3 -text "Save data" -command [code $this saveIntoFile]
	#} {}

	#pack .tpwRN.f1.b0 .tpwRN.f1.b1 .tpwRN.f1.b2 .tpwRN.f1.b3 -side left
	#pack .tpwRN.f1

	#puts "LiberaNo is"
	#puts $args
	pack .tpwRN.f1.l1 .tpwRN.f1.l6 .tpwRN.f1.l2 .tpwRN.f1.l7 -side left
	pack .tpwRN.f2.l3 .tpwRN.f2.l8 .tpwRN.f2.l4 .tpwRN.f2.l9 -side left
	pack .tpwRN.f3.l5 .tpwRN.f3.l10 .tpwRN.f3.ll -side left
	pack .tpwRN.f1 .tpwRN.f2 .tpwRN.f3
	



	### setup graph plot option##################################################
	### variable definitions

	blt::vector create liberax1
	liberax1 set [range 300]

	#blt::vector create liberay1
	#blt::vector create liberay2
	#blt::vector create liberay3
	#blt::vector create liberay4
	#blt::vector create liberay5

	blt::vector create sa_a
	blt::vector create sa_b
	blt::vector create sa_c
	blt::vector create sa_d
	blt::vector create sa_sum

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

	frame .tpwRN.fl
	frame .tpwRN.fr
	frame .tpwRN.frr

	itk_component add atplot {
		blt::graph .tpwRN.fl.g1 -title "Ch. A signal hist" -plotbackground white -height 250 -width 330} {}
	.tpwRN.fl.g1 element create line1 -xdata liberax1 -ydata sa_a
	.tpwRN.fl.g1 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRN.fl.g1 element show
	.tpwRN.fl.g1 axis configure x -title {samples} -max 300
	.tpwRN.fl.g1 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRN.fl.g1 grid configure -hide no -dashes { 2 2 }

	itk_component add btplot {
		blt::graph .tpwRN.fl.g2 -title "Ch. C signal hist" -plotbackground white -height 250 -width 330} {}
	.tpwRN.fl.g2 element create line1 -xdata liberax1 -ydata sa_c
	.tpwRN.fl.g2 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRN.fl.g2 element show
	.tpwRN.fl.g2 axis configure x -title {samples} -max 300
	.tpwRN.fl.g2 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRN.fl.g2 grid configure -hide no -dashes { 2 2 }

	itk_component add ctplot {
		blt::graph .tpwRN.fr.g1 -title "Ch.B signal hist" -plotbackground white -height 250 -width 330} {}
	.tpwRN.fr.g1 element create line1 -xdata liberax1 -ydata sa_b
	.tpwRN.fr.g1 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRN.fr.g1 element show
	.tpwRN.fr.g1 axis configure x -title {samples} -max 300
	.tpwRN.fr.g1 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRN.fr.g1 grid configure -hide no -dashes { 2 2 }

	itk_component add dtplot {
		blt::graph .tpwRN.fr.g2 -title "Ch.D signal hist" -plotbackground white -height 250 -width 330} {}
	.tpwRN.fr.g2 element create line1 -xdata liberax1 -ydata sa_d
	.tpwRN.fr.g2 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRN.fr.g2 element show
	.tpwRN.fr.g2 axis configure x -title {samples} -max 300
	.tpwRN.fr.g2 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRN.fr.g2 grid configure -hide no -dashes { 2 2 }

	itk_component add sumtplot {
		blt::graph .tpwRN.frr.g3 -title "Signal sum hist" -plotbackground white -height 505 -width 330} {}
	.tpwRN.frr.g3 element create line1 -xdata liberax1 -ydata sa_sum
	.tpwRN.frr.g3 element configure line1 -symbol circle -color black -linewidth 1 -pixels 0.01i
	.tpwRN.frr.g3 element show
	.tpwRN.frr.g3 axis configure x -title {samples} -max 300
	.tpwRN.frr.g3 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	.tpwRN.frr.g3 grid configure -hide no -dashes { 2 2 }


	# pack graph

	pack .tpwRN.fl.g1 .tpwRN.fl.g2 -pady 5
	pack .tpwRN.fr.g1 .tpwRN.fr.g2 -pady 5
	pack .tpwRN.frr.g3 -pady 5
	pack .tpwRN.fl .tpwRN.fr .tpwRN.frr -side left

	set deviceFactory [DCS::DeviceFactory::getObject]
	#puts $deviceFactory

	#puts "liberaNo is "
	#puts ${liberaNo}

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
	#puts $sa_a_mon_val

	#set adccw_va_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd_va_mon]


	#register valiables to monitor value change
	::mediator register $this $sa_a_mon_obj contents DCS::PlotWinRAWNUME::handleVector1
	::mediator register $this $sa_b_mon_obj contents DCS::PlotWinRAWNUME::handleVector2
	::mediator register $this $sa_c_mon_obj contents DCS::PlotWinRAWNUME::handleVector3
	::mediator register $this $sa_d_mon_obj contents DCS::PlotWinRAWNUME::handleVector4
	::mediator register $this $sa_sum_mon_obj contents DCS::PlotWinRAWNUME::handleVector7
	

	announceExist

}

body DCS::PlotWinRAWNUME::updatepv {liberaNo bpmNo} {
### This method will update variables connected with EPICS records.

	#puts $liberaNo
	#puts $bpmNo

	set deviceFactory [DCS::DeviceFactory::getObject]

	#puts $deviceFactory

	#set adccw_va_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_va_mon]
	#set adccw_vb_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_vb_mon]
	#set adccw_vc_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_vc_mon]
	#set adccw_vd_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_vd_mon]

	#set adccw_st_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_st_mon]
	#set adccw_finished_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_finished_mon]
	#set adccw_request_cmd_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_request_cmd]
	#set adccw_ignore_trig_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_ign_trig_mon]
	#set adccw_ignore_trig_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_ign_trig_sp]

	#puts [$adccw_ignore_trig_mon_obj getContents]

	set sa_a_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_a_mon]
	set sa_b_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_b_mon]
	set sa_c_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_c_mon]
	set sa_d_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_d_mon]
	set sa_sum_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_sum_mon]
	set env_range_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_range_mon]

}


body DCS::PlotWinRAWNUME::trigRequestCmd {} {
### This method send trigger request for DD1 port via epicsgw
	$adccw_request_cmd_obj sendContentsToServer 1
	after 10000 [code $this getPlotData]
}

body DCS::PlotWinRAWNUME::getPlotData {args} {
	### This method update variables of DD1 port
	### Updated vaules will be copied to blt vector variable

	set adccw_va_mon_val [$adccw_va_mon_obj getContents]
	set adccw_vb_mon_val [$adccw_vb_mon_obj getContents]
	set adccw_vc_mon_val [$adccw_vc_mon_obj getContents]
	set adccw_vd_mon_val [$adccw_vd_mon_obj getContents]
	set adccw_st_mon_val [$adccw_st_mon_obj getContents]
	#puts $adccw_va_mon_val
	after 500 [code $this cpPlotData] 

}

body DCS::PlotWinRAWNUME::cpPlotData {} {
	### This method cp data to blt vector
	liberay1 set $adccw_va_mon_val
	liberay2 set $adccw_vb_mon_val
	liberay3 set $adccw_vc_mon_val
	liberay4 set $adccw_vd_mon_val
}

body DCS::PlotWinRAWNUME::saveIntoFile {} {
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

body DCS::PlotWinRAWNUME::handleVector1 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	if { ! $targetReady_} return
	if {[sa_a length] > 300} then {
		sa_a delete 0
		sa_a append $contents_
	} else {sa_a append $contents_}
}

body DCS::PlotWinRAWNUME::handleVector2 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	if { ! $targetReady_} return
	if {[sa_a length] > 300} then {
		sa_b delete 0
		sa_b append $contents_
	} else {sa_b append $contents_}
}
body DCS::PlotWinRAWNUME::handleVector3 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	if { ! $targetReady_} return
	if {[sa_c length] > 300} then {
		sa_c delete 0
		sa_c append $contents_
	} else {sa_c append $contents_}
}
body DCS::PlotWinRAWNUME::handleVector4 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	if { ! $targetReady_} return
	if {[sa_d length] > 300} then {
		sa_d delete 0
		sa_d append $contents_
	} else {sa_d append $contents_}
}

body DCS::PlotWinRAWNUME::handleVector7 { stringName_ targetReady_ alias_ contents_ - } {
	#puts $stringName
	if { ! $targetReady_} return
	if {[sa_sum length] > 300} then {
		sa_sum delete 0
		sa_sum append $contents_
	} else {sa_sum append $contents_}
}



body DCS::PlotWinRAWNUME::trigIGN {bw liberaNo bpmNo} {
	#puts "testtesttest"
	#set deviceFactory [DCS::DeviceFactory::getObject]
	#set adccw_ignore_trig_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_ignore_trig_mon]
	#set adccw_ignore_trig_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_ignore_trig_sp]
	set adccw_ignore_trig_mon_val [$adccw_ignore_trig_mon_obj getContents]
	#puts $adccw_ignore_trig_mon_val
	if {$adccw_ignore_trig_mon_val == 1} {
		#puts "ignored to arrowed"
		$adccw_ignore_trig_sp_obj sendContentsToServer 0
		$bw configure -text "TRIGGER-ARROWED"
	} else {
		#puts "arrowed to ignored"
		$adccw_ignore_trig_sp_obj sendContentsToServer 1
		$bw configure -text "TRIGGER-IGNORED"
	}
}

body DCS::PlotWinRAWNUME::unregisterall {} {
		puts "unregisterall"		
		#::mediator unregister $this $sa_a_mon_obj contents DCS::PlotWinRAWNUME::handleVector1
	
}

