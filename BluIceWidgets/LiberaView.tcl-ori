#! /usr/bin/wish
#
#file create date : 2016-Aug-24
#last update      : 2016-Nov-22

package provide DCSLiberaView 1.0

### load the required standard packages
package require Itcl
package require Iwidgets
package require BWidget

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


### Libera Photon GUI Create class ##########################################################################

class DCS::LiberaDetailView {
	#inherit ::itk::Widget
	inherit ::DCS::ComponentGateExtension
	#inherit ::DCS::StringViewBase <- No error but dones not show any widgets

	#itk_option definition
	#itk_option define -controlSystem controlSystem ControlSystem ::dcss
	itk_option define -stringName stringName StringName ""
	itk_option define -mdiHelper mdiHelper MdiHelper ""

	#setup DeviceFactory to get device list
	protected variable deviceFactory
       set deviceFactory [DCS::DeviceFactory::getObject]
	#puts $deviceFactory

	#epics pvs name in dcss

	#slow aquisiton(SA)port data
	protected variable sa_a_mon_obj
	protected variable sa_b_mon_obj
	protected variable sa_c_mon_obj
	protected variable sa_d_mon_obj
	protected variable sa_x_mon_obj
	protected variable sa_y_mon_obj
	protected variable sa_q_mon_obj
	protected variable sa_sum_mon_obj

	protected variable sa_a_mon_val
	protected variable sa_b_mon_val
	protected variable sa_c_mon_val
	protected variable sa_d_mon_val
	protected variable sa_x_mon_val
	protected variable sa_y_mon_val
	protected variable sa_q_mon_val
	protected variable sa_sum_mon_val

	#offset and coefficeients for position values
	protected variable env_k1_mon_obj
	protected variable env_k2_mon_obj
	protected variable env_offset1_mon_obj
	protected variable env_offset2_mon_obj

	protected variable env_k1_sp_obj
	protected variable env_k2_sp_obj
	protected variable env_offset1_sp_obj
	protected variable env_offset2_sp_obj

	protected variable env_k1_mon_val
	protected variable env_k2_mon_val
	protected variable env_offset1_mon_val
	protected variable env_offset2_mon_val

	protected variable env_k1_sp_val
	protected variable env_k2_sp_val
	protected variable env_offset1_sp_val
	protected variable env_offset2_sp_val

	#gain compensation for channel A-D
	protected variable env_ki_0_mon_obj
	protected variable env_ki_1_mon_obj
	protected variable env_ki_2_mon_obj
	protected variable env_ki_3_mon_obj

	protected variable env_ki_0_sp_obj
	protected variable env_ki_1_sp_obj
	protected variable env_ki_2_sp_obj
	protected variable env_ki_3_sp_obj

	protected variable env_ioffset_0_mon_obj
	protected variable env_ioffset_1_mon_obj
	protected variable env_ioffset_2_mon_obj
	protected variable env_ioffset_3_mon_obj

	protected variable env_ioffset_0_sp_obj
	protected variable env_ioffset_1_sp_obj
	protected variable env_ioffset_2_sp_obj
	protected variable env_ioffset_3_sp_obj

	#current range setup
	protected variable env_arc_mon_obj
	protected variable env_arc_sp_obj
	protected variable env_range_mon_obj
	protected variable env_range_sp_obj

	# Data on Demand (DD) port data
	protected variable dd1_dd_va_mon_obj
	protected variable dd1_dd_vb_mon_obj
	protected variable dd1_dd_vc_mon_obj
	protected variable dd1_dd_vd_mon_obj
	protected variable dd1_dd_st_mon_obj
	protected variable dd1_dd_finished_mon_obj
	protected variable dd1_dd_request_cmd_obj

	protected variable dd1_dd_va_mon_val
	protected variable dd1_dd_vb_mon_val
	protected variable dd1_dd_vc_mon_val
	protected variable dd1_dd_vd_mon_val
	protected variable dd1_dd_st_mon_val
	protected variable dd1_dd_finished_mon_val

	# etc
	#protected variable triger_counter 0
	protected variable bunch_counter 0
	protected variable system_status 0
	protected variable system_mode 0

	protected variable liberadevlist [list Libera01 Libera02 Libera03 Libera04 Libera05]
	protected variable liberabpmlist [list bpm01 bpm02 bpm03 bpm04 bpm05]
	#protected variable liberaPosAlg [list behindID behindBM behindBMlog]
	#protected variable scan_mode_list [list mode1 mode2 modeXYZ single_shot]
	#protected variable currentrangeid [list 0 1 2 3 4 5 6]
	protected variable currentrangeval [list 0:2nA 1:20nA 2:200nA 3:2uA 4:20uA 5:200uA 6:1850uA]
	#protected variable currentrange 6
	#protected variable rangemodeid [list 0 1]
	protected variable rangemodeval [list 0:manual 1:auto]
	#protected variable rangemode 0

	#setup othre variable. This is same as StringViewBase
	protected variable m_site
	protected variable _lastStringName ""

	protected method checkContentsBeforeSend { contentsREF } {
       return 1
	}

	#methods
	protected method updatepv
	protected method ddRequestCmd
	protected method getPlotData
	protected method cpPlotData
	protected method saveIntoFile
	protected method applyARCmode
	protected method applyCurrentRange

	#proc 
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
		puts "This is destructor of LiberaDetailView class."
		blt::vector destroy liberax1
		blt::vector destroy liberay1
		blt::vector destroy liberay2
		blt::vector destroy liberay3		
		blt::vector destroy liberay4
    }
}


###########################################################################################################
# Following are body configurations.
############################################################################################################

body DCS::LiberaDetailView::constructor {args} {
	puts "This is LiberaDetailView class constructor"

### Setup left side frame #################################
	itk_component add leftframe {
		frame $itk_interior.lff
	}
### device selection box
	itk_component add devicef {
		frame $itk_interior.lff.devicef 
	}
	itk_component add deciceff1 {
		frame $itk_interior.lff.devicef.f1
	}
	itk_component add deciceff2 {
		frame $itk_interior.lff.devicef.f2
	}

	itk_component add devicefl1 {
		label $itk_interior.lff.devicef.f1.l1 -text "Libera Device Selection Box:" -width 27
	} {}
	itk_component add devicefd1 {
		ttk::combobox $itk_interior.lff.devicef.f1.d1 -textvariable libera_combovalue \
						-values $liberadevlist -background yellow -foreground black -width 20 -justify left -state normal
	} {}
$itk_interior.lff.devicef.f1.d1 current 0

bind $itk_interior.lff.devicef.f1.d1 <<ComboboxSelected>> [code $this updatepv]


	itk_component add devicefl2 {
		label $itk_interior.lff.devicef.f2.l2 -text "BPM Selection Box:" -width 27

	} {}
	itk_component add devicefd2 {
		ttk::combobox $itk_interior.lff.devicef.f2.d2 -textvariable bpm_combovalue \
						-values $liberabpmlist -background yellow -foreground black -width 20 -justify left -state normal
	} {}
$itk_interior.lff.devicef.f2.d2 current 0
bind $itk_interior.lff.devicef.f2.d2 <<ComboboxSelected>> [code $this updatepv]


	#pack every components
	pack $itk_interior.lff.devicef.f1.l1 $itk_interior.lff.devicef.f1.d1 -side left -padx 2
	pack $itk_interior.lff.devicef.f2.l2 $itk_interior.lff.devicef.f2.d2 -side left -padx 2
	pack $itk_interior.lff.devicef.f1 $itk_interior.lff.devicef.f2 -pady 5
	pack $itk_interior.lff.devicef -anchor w -padx 5

### update pv-gateway connection
	updatepv

### setup tabs frame for current status display and parameters config
	itk_component add notetab {
		ttk::notebook $itk_interior.lff.tabsf -width 500 -height 500
	} {}

	# add tabs
	itk_component add tab1 {
		ttk::frame $itk_interior.lff.tabsf.tab1;
	} {}
	$itk_interior.lff.tabsf add $itk_interior.lff.tabsf.tab1 -text "Status"

	itk_component add tab2 {
		ttk::frame $itk_interior.lff.tabsf.tab2;
	} {}
	$itk_interior.lff.tabsf add $itk_interior.lff.tabsf.tab2 -text "Coefficitents and Offsets for position"

	itk_component add tab3 {
		ttk::frame $itk_interior.lff.tabsf.tab3;
	} {}
	$itk_interior.lff.tabsf add $itk_interior.lff.tabsf.tab3 -text "Compensation factors for signal"

### status tab setup
	itk_component add tab1f {
		frame $itk_interior.lff.tabsf.tab1.f1 
		frame $itk_interior.lff.tabsf.tab1.f2 
		frame $itk_interior.lff.tabsf.tab1.f3 
		frame $itk_interior.lff.tabsf.tab1.f4
		frame $itk_interior.lff.tabsf.tab1.f5
		frame $itk_interior.lff.tabsf.tab1.f6 
	}

	itk_component add tab1fl1 {
        	label $itk_interior.lff.tabsf.tab1.f1.l1 -text "Trigger Counter" -width 15
		label $itk_interior.lff.tabsf.tab1.f2.l1 -text "Bunch Counter" -width 15
		label $itk_interior.lff.tabsf.tab1.f3.l1 -text "System Status" -width 15
		label $itk_interior.lff.tabsf.tab1.f4.l1 -text "System Mode" -width 15
		label $itk_interior.lff.tabsf.tab1.f5.l1 -text "ARC Mode" -width 15
		label $itk_interior.lff.tabsf.tab1.f6.l1 -text "Current range" -width 15
		} { 
			keep -background -foreground -font
		}
	
	itk_component add tab1fe1 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.f1.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $dd1_dd_finished_mon_obj} {}
	itk_component add tab1fe2 {
		label $itk_interior.lff.tabsf.tab1.f2.l2 -text $bunch_counter -width 15 -bg white} {}
	itk_component add tab1fe3 {
		label $itk_interior.lff.tabsf.tab1.f3.l2 -text $system_status -width 15 -bg white} {}
	itk_component add tab1fe4 {
		label $itk_interior.lff.tabsf.tab1.f4.l2 -text $system_mode -width 15 -bg white} {}
#### add range widgets
	itk_component add tab1f5e1 {
		ttk::combobox $itk_interior.lff.tabsf.tab1.f5.combo1 -textvariable rangemode -values $rangemodeval \
									-background yellow -foreground black -width 20 -justify left -state normal
	#set rangemode "manual"
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab1.f5.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_arc_sp_obj} {keep -textvariable}
# bind to apply change
$itk_interior.lff.tabsf.tab1.f5.combo1 current 0
bind $itk_interior.lff.tabsf.tab1.f5.combo1 <<ComboboxSelected>> [code $this applyARCmode]

	itk_component add tab1f6e1 {
		ttk::combobox $itk_interior.lff.tabsf.tab1.f6.combo2 -textvariable currentrange -values $currentrangeval \
									-background yellow -foreground black -width 20 -justify left -state normal
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab1.f6.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_range_sp_obj} {keep -textvariable}
# bind to apply change
$itk_interior.lff.tabsf.tab1.f6.combo2 current 6
bind $itk_interior.lff.tabsf.tab1.f6.combo2 <<ComboboxSelected>> [code $this applyCurrentRange]

	itk_component add tab1f5l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.f5.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_arc_mon_obj} {}
	itk_component add tab1f6l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.f6.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_range_mon_obj} {}

	itk_component add tab1b {
		button $itk_interior.lff.tabsf.tab1.b1 -text "Reset" -command [puts "$this resetCMD"]
	} {}
	pack $itk_interior.lff.tabsf.tab1.f1.l1 $itk_interior.lff.tabsf.tab1.f1.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab1.f2.l1 $itk_interior.lff.tabsf.tab1.f2.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab1.f3.l1 $itk_interior.lff.tabsf.tab1.f3.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab1.f4.l1 $itk_interior.lff.tabsf.tab1.f4.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab1.f5.l1 $itk_interior.lff.tabsf.tab1.f5.combo1 $itk_interior.lff.tabsf.tab1.f5.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab1.f6.l1 $itk_interior.lff.tabsf.tab1.f6.combo2 $itk_interior.lff.tabsf.tab1.f6.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab1.f1 $itk_interior.lff.tabsf.tab1.f2 $itk_interior.lff.tabsf.tab1.f3 \
		$itk_interior.lff.tabsf.tab1.f4 $itk_interior.lff.tabsf.tab1.f5 $itk_interior.lff.tabsf.tab1.f6 -pady 5 

### Offset tab setup
	itk_component add tab2f {
		frame $itk_interior.lff.tabsf.tab2.f1 
		frame $itk_interior.lff.tabsf.tab2.f2 
		frame $itk_interior.lff.tabsf.tab2.f3 
		frame $itk_interior.lff.tabsf.tab2.f4 
	}

	itk_component add tab2fl1 {
        	label $itk_interior.lff.tabsf.tab2.f1.l1 -text "k1 \[nm\]" -width 15
		label $itk_interior.lff.tabsf.tab2.f2.l1 -text "k2 \[nm\]" -width 15
		label $itk_interior.lff.tabsf.tab2.f3.l1 -text "Offset1 \[nm\]" -width 15
		label $itk_interior.lff.tabsf.tab2.f4.l1 -text "Offset2 \[nm\]" -width 15
	} { }
### widget for setpoint
	itk_component add tab2fe1 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab2.f1.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_k1_sp_obj} {keep -textvariable}
	itk_component add tab2fe2 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab2.f2.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_k2_sp_obj } {keep -textvariable}
	itk_component add tab2fe3 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab2.f3.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_offset1_sp_obj} {keep -textvariable}
	itk_component add tab2fe4 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab2.f4.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_offset2_sp_obj} {keep -textvariable}
### widget for readback
	itk_component add tab2fl2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab2.f1.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_k1_mon_obj} {}
	itk_component add tab2fl3 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab2.f2.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_k2_mon_obj } {}
	itk_component add tab2fl4 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab2.f3.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_offset1_mon_obj} {}
	itk_component add tab2fl5 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab2.f4.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_offset2_mon_obj} {}

	pack $itk_interior.lff.tabsf.tab2.f1.l1 $itk_interior.lff.tabsf.tab2.f1.e1 $itk_interior.lff.tabsf.tab2.f1.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab2.f2.l1 $itk_interior.lff.tabsf.tab2.f2.e1 $itk_interior.lff.tabsf.tab2.f2.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab2.f3.l1 $itk_interior.lff.tabsf.tab2.f3.e1 $itk_interior.lff.tabsf.tab2.f3.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab2.f4.l1 $itk_interior.lff.tabsf.tab2.f4.e1 $itk_interior.lff.tabsf.tab2.f4.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab2.f1 $itk_interior.lff.tabsf.tab2.f2 $itk_interior.lff.tabsf.tab2.f3 $itk_interior.lff.tabsf.tab2.f4 -pady 5

### Calibration tab setup
	itk_component add tab3f {
		frame $itk_interior.lff.tabsf.tab3.f1 -bd 3 
		frame $itk_interior.lff.tabsf.tab3.f2 -bd 3 
		frame $itk_interior.lff.tabsf.tab3.f3 -bd 3 
		frame $itk_interior.lff.tabsf.tab3.f4 -bd 3 
		frame $itk_interior.lff.tabsf.tab3.f5 -bd 3 
		frame $itk_interior.lff.tabsf.tab3.f6 -bd 3
		frame $itk_interior.lff.tabsf.tab3.f7 -bd 3
		frame $itk_interior.lff.tabsf.tab3.f8 -bd 3
	} {}

	itk_component add tab3fl1 {
        	label $itk_interior.lff.tabsf.tab3.f1.l1 -text "KI_0" -width 15
		label $itk_interior.lff.tabsf.tab3.f2.l1 -text "KI_1" -width 15
		label $itk_interior.lff.tabsf.tab3.f3.l1 -text "KI_2" -width 15
		label $itk_interior.lff.tabsf.tab3.f4.l1 -text "KI_3" -width 15

        	label $itk_interior.lff.tabsf.tab3.f5.l1 -text "IOFFSET_0" -width 15
		label $itk_interior.lff.tabsf.tab3.f6.l1 -text "IOFFSET_1" -width 15
		label $itk_interior.lff.tabsf.tab3.f7.l1 -text "IOFFSET_2" -width 15
		label $itk_interior.lff.tabsf.tab3.f8.l1 -text "IOFFSET_3" -width 15
	} { }
### widget for setpoint
	itk_component add tab3fe1 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f1.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_0_sp_obj } {keep -textvariable}
	itk_component add tab3fe2 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f2.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_1_sp_obj } {keep -textvariable}
	itk_component add tab3fe3 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f3.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_2_sp_obj } {keep -textvariable}
	itk_component add tab3fe4 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f4.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_3_sp_obj } {keep -textvariable}
	itk_component add tab3fe5 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f5.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_0_sp_obj } {keep -textvariable}
	itk_component add tab3fe6 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f6.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_1_sp_obj } {keep -textvariable}
	itk_component add tab3fe7 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f7.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_2_sp_obj } {keep -textvariable}
	itk_component add tab3fe8 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f8.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_3_sp_obj } {keep -textvariable}

### widget for readback
	itk_component add tab3f1l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f1.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_0_mon_obj } {}
	itk_component add tab3f2l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f2.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_1_mon_obj } {}
	itk_component add tab3f3l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f3.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_2_mon_obj } {}
	itk_component add tab3fl2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f4.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_3_mon_obj } {}
	itk_component add tab3f5l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f5.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_0_mon_obj } {}
	itk_component add tab3f6l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f6.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_1_mon_obj } {}
	itk_component add tab3f7l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f7.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_2_mon_obj } {}
	itk_component add tab3f8l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f8.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_3_mon_obj } {}
	pack $itk_interior.lff.tabsf.tab3.f1.l1 $itk_interior.lff.tabsf.tab3.f1.e1 $itk_interior.lff.tabsf.tab3.f1.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab3.f2.l1 $itk_interior.lff.tabsf.tab3.f2.e1 $itk_interior.lff.tabsf.tab3.f2.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab3.f3.l1 $itk_interior.lff.tabsf.tab3.f3.e1 $itk_interior.lff.tabsf.tab3.f3.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab3.f4.l1 $itk_interior.lff.tabsf.tab3.f4.e1 $itk_interior.lff.tabsf.tab3.f4.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab3.f5.l1 $itk_interior.lff.tabsf.tab3.f5.e1 $itk_interior.lff.tabsf.tab3.f5.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab3.f6.l1 $itk_interior.lff.tabsf.tab3.f6.e1 $itk_interior.lff.tabsf.tab3.f6.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab3.f7.l1 $itk_interior.lff.tabsf.tab3.f7.e1 $itk_interior.lff.tabsf.tab3.f7.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab3.f8.l1 $itk_interior.lff.tabsf.tab3.f8.e1 $itk_interior.lff.tabsf.tab3.f8.l2 -side left -pady 5

	pack $itk_interior.lff.tabsf.tab3.f1 $itk_interior.lff.tabsf.tab3.f2 $itk_interior.lff.tabsf.tab3.f3 $itk_interior.lff.tabsf.tab3.f4 \
		$itk_interior.lff.tabsf.tab3.f5 $itk_interior.lff.tabsf.tab3.f6 $itk_interior.lff.tabsf.tab3.f7 $itk_interior.lff.tabsf.tab3.f8 -pady 5
	#pack tabs frame
	pack $itk_interior.lff.tabsf -pady 5


### graph display
	itk_component add graphf {
		frame $itk_interior.graphf
	}
	itk_component add graphf1 {
		frame $itk_interior.graphf.f1
	}
	itk_component add  graphf2 {
		frame $itk_interior.graphf.f2
		frame $itk_interior.graphf.f2.f1
		frame $itk_interior.graphf.f2.f2
		frame $itk_interior.graphf.f2.f3
		frame $itk_interior.graphf.f2.f4
	}
	itk_component add  graphf3 {
		frame $itk_interior.graphf.f3
	}

	itk_component add readbutton {
		button $itk_interior.graphf.f1.b2 -text "DD Triger CMD" -command [code $this DCS::LiberaDetailView::ddRequestCmd]
	} {}

	itk_component add getpvdata {
		button $itk_interior.graphf.f1.b3 -text "Update Plot" -command [code $this DCS::LiberaDetailView::getPlotData]
	} {}

  itk_component add ent {
	button $itk_interior.graphf.f1.b4 -text "Save data" -command [code $this DCS::LiberaDetailView::saveIntoFile]
    } {}
    	#pack 
	pack $itk_interior.graphf.f1.b2 $itk_interior.graphf.f1.b3 $itk_interior.graphf.f1.b4 -side left -padx 5 -pady 5
	#pack $itk_interior.graphf.f1.b2 $itk_interior.graphf.f1.b3 $itk_interior.graphf.f1.b4 $itk_interior.graphf.f1.ent -side left -padx 5 -pady 5
	pack $itk_interior.graphf.f1 -pady 5

### setup graph plot option##################################################
### variable definitions

	blt::vector create liberax1(1000)
	liberax1 set [range [llength $dd1_dd_va_mon_val]]
	blt::vector create liberay1(1000) 
	liberay1 set $dd1_dd_va_mon_val
	blt::vector create liberay2(1000)  
	liberay2 set $dd1_dd_vb_mon_val
	blt::vector create liberay3(1000)  
	liberay3 set $dd1_dd_vc_mon_val
	blt::vector create liberay4(1000)  
	liberay4 set $dd1_dd_vd_mon_val

	#puts "vector liberay1 length is [liberay1 length]"
### setup graph configurations
	itk_component add graphplot1 {
		blt::graph $itk_interior.graphf.f2.f1.g1 -title "signal on A" -plotbackground black -height 250 -width 250} {}
	$itk_interior.graphf.f2.f1.g1 element create line1 -xdata liberax1 -ydata liberay1
	$itk_interior.graphf.f2.f1.g1 element configure line1 -symbol square -color red -dashes {2 4 2} -linewidth 1 -pixels 0.02i
	$itk_interior.graphf.f2.f1.g1 element show
	$itk_interior.graphf.f2.f1.g1 axis configure x -title {time}
	$itk_interior.graphf.f2.f1.g1 axis configure y -title {current}
	$itk_interior.graphf.f2.f1.g1 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	$itk_interior.graphf.f2.f1.g1 grid configure -hide no -dashes { 2 2 }

	itk_component add graphplot2 {
		blt::graph $itk_interior.graphf.f2.f2.g1 -title "signal on B" -plotbackground black -height 250 -width 250} {}
	$itk_interior.graphf.f2.f2.g1 element create line1 -xdata liberax1 -ydata liberay2
	$itk_interior.graphf.f2.f2.g1 element configure line1 -symbol circle -color green -dashes {2 4 2} -linewidth 1 -pixels 0.03i
	$itk_interior.graphf.f2.f2.g1 element show
	$itk_interior.graphf.f2.f2.g1 axis configure x -title {time}
	$itk_interior.graphf.f2.f2.g1 axis configure y -title {current}
	$itk_interior.graphf.f2.f2.g1 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	$itk_interior.graphf.f2.f2.g1 grid configure -hide no -dashes { 2 2 }

	itk_component add graphplot3 {
		blt::graph $itk_interior.graphf.f2.f3.g1 -title "signal on C" -plotbackground black -height 250 -width 250} {}
	$itk_interior.graphf.f2.f3.g1 element create line1 -xdata liberax1 -ydata liberay3
	$itk_interior.graphf.f2.f3.g1 element configure line1 -symbol plus -color cyan -dashes {2 4 2} -linewidth 1 -pixels 0.04i
	$itk_interior.graphf.f2.f3.g1 element show
	$itk_interior.graphf.f2.f3.g1 axis configure x -title {time}
	$itk_interior.graphf.f2.f3.g1 axis configure y -title {current}
	$itk_interior.graphf.f2.f3.g1 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	$itk_interior.graphf.f2.f3.g1 grid configure -hide no -dashes { 2 2 }

	itk_component add graphplot4 {
		blt::graph $itk_interior.graphf.f2.f4.g1 -title "signal on D" -plotbackground black -height 250 -width 250} {}
	$itk_interior.graphf.f2.f4.g1 element create line1 -xdata liberax1 -ydata liberay4
	$itk_interior.graphf.f2.f4.g1 element configure line1 -symbol triangle -color blue -dashes {2 4 2} -linewidth 1 -pixels 0.05i
	$itk_interior.graphf.f2.f4.g1 element show
	$itk_interior.graphf.f2.f4.g1 axis configure x -title {time}
	$itk_interior.graphf.f2.f4.g1 axis configure y -title {current}
	$itk_interior.graphf.f2.f4.g1 legend configure -position right -relief groove -font fixed -fg blue -hide 1
	$itk_interior.graphf.f2.f4.g1 grid configure -hide no -dashes { 2 2 }

	pack $itk_interior.graphf.f2.f1.g1 $itk_interior.graphf.f2.f2.g1
	pack $itk_interior.graphf.f2.f3.g1 $itk_interior.graphf.f2.f4.g1
	grid $itk_interior.graphf.f2.f1 $itk_interior.graphf.f2.f2 
	grid $itk_interior.graphf.f2.f3 $itk_interior.graphf.f2.f4 
	pack $itk_interior.graphf.f2

	set dd1_dd_va_mon_val [$dd1_dd_va_mon_obj getContents]
	set dd1_dd_vb_mon_val [$dd1_dd_vb_mon_obj getContents]
	set dd1_dd_vc_mon_val [$dd1_dd_vc_mon_obj getContents]
	set dd1_dd_vd_mon_val [$dd1_dd_vd_mon_obj getContents]
	set dd1_dd_st_mon_val [$dd1_dd_st_mon_obj getContents]
	
	liberay1 set $dd1_dd_va_mon_val
	liberay2 set $dd1_dd_vb_mon_val
	liberay3 set $dd1_dd_vc_mon_val
	liberay4 set $dd1_dd_vd_mon_val


### setup descriptive statistic value display ###################################
	itk_component add discrff {
		frame $itk_interior.graphf.f3.f1 
		frame $itk_interior.graphf.f3.f2 
	}

	itk_component add discrflab {
        	label $itk_interior.graphf.f3.f1.l1 -text "X" -width 15
		label $itk_interior.graphf.f3.f1.l2 -text "Y" -width 15
		label $itk_interior.graphf.f3.f2.l1 -text "SUM" -width 15
		label $itk_interior.graphf.f3.f2.l2 -text "Q" -width 15
		} { 
			keep -background -foreground -font
		}

	itk_component add discrftext {
		DCS::LiberaStringViewLabel $itk_interior.graphf.f3.f1.l3 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_x_mon_obj } {} 

	itk_component add discrftext2 {
		DCS::LiberaStringViewLabel $itk_interior.graphf.f3.f1.l4 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_y_mon_obj } {} 

	itk_component add discrftext3 {
		DCS::LiberaStringViewLabel $itk_interior.graphf.f3.f2.l3 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_sum_mon_obj } {} 		

	itk_component add discrftext4 {
		DCS::LiberaStringViewLabel $itk_interior.graphf.f3.f2.l4 \
			-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_q_mon_obj } {} 

	pack $itk_interior.graphf.f3.f1.l1 $itk_interior.graphf.f3.f1.l3 $itk_interior.graphf.f3.f1.l2 $itk_interior.graphf.f3.f1.l4 -side left
	pack $itk_interior.graphf.f3.f2.l1 $itk_interior.graphf.f3.f2.l3 $itk_interior.graphf.f3.f2.l2 $itk_interior.graphf.f3.f2.l4 -side left
	pack $itk_interior.graphf.f3.f1 $itk_interior.graphf.f3.f2 -pady 5
	pack $itk_interior.graphf.f3
	
### pack left and right frame
	pack $itk_interior.lff $itk_interior.graphf -side left -fill y
		# itk_initialize analize options and affect widgets
		eval itk_initialize $args
		announceExist
### end of constructor 
}

body DCS::LiberaDetailView::updatepv {} {
### This method will update variables connected with EPICS records.

set liberaNo [$itk_interior.lff.devicef.f1.d1 current]
set bpmNo [$itk_interior.lff.devicef.f2.d2 current]
puts ${liberaNo}_${bpmNo}_sa_a_mon
	set deviceFactory [DCS::DeviceFactory::getObject]
	puts $deviceFactory

	#slow aquisiton data
	set sa_a_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_a_mon]
	set sa_a_mon_val [$sa_a_mon_obj getContents]
	set sa_b_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_b_mon]
	set sa_b_mon_val [$sa_a_mon_obj getContents]
	set sa_c_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_c_mon]
	set sa_c_mon_val [$sa_a_mon_obj getContents]
	set sa_d_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_d_mon]
	set sa_d_mon_val [$sa_a_mon_obj getContents]
	set sa_x_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_x_mon]
	set sa_x_mon_val [$sa_a_mon_obj getContents]
	set sa_y_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_y_mon]
	set sa_y_mon_val [$sa_a_mon_obj getContents]
	set sa_q_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_q_mon]
	set sa_q_mon_val [$sa_a_mon_obj getContents]
	set sa_sum_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_sa_sum_mon]
	set sa_sum_mon_val [$sa_a_mon_obj getContents]

	#offset values
	set env_k1_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_k1_mon]
	set env_k1_mon_val [$env_k1_mon_obj getContents]
	set env_k2_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_k2_mon]
	set env_k2_mon_val [$env_k1_mon_obj getContents]
	set env_offset1_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_offset1_mon]
	set env_offset1_mon_val [$env_offset1_mon_obj getContents]
	set env_offset2_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_offset2_mon]
	set env_offset2_mon_val [$env_offset2_mon_obj getContents]

	set env_k1_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_k1_sp]
	set env_k1_sp_val [$env_k1_sp_obj getContents]
	set env_k2_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_k2_sp]
	set env_k2_sp_val [$env_k1_sp_obj getContents]
	set env_offset1_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_offset1_sp]
	set env_offset1_sp_val [$env_offset1_sp_obj getContents]
	set env_offset2_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_offset2_sp]
	set env_offset2_sp_val [$env_offset2_sp_obj getContents]

	#gain compensation for channel A-D
	set env_ki_0_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ki_0_mon]
	set env_ki_0_mon_val [$env_ki_0_mon_obj getContents]
	set env_ki_1_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ki_1_mon]
	set env_ki_1_mon_val [$env_ki_1_mon_obj getContents]
	set env_ki_2_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ki_2_mon]
	set env_ki_2_mon_val [$env_ki_2_mon_obj getContents]
	set env_ki_3_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ki_3_mon]
	set env_ki_3_mon_val [$env_ki_3_mon_obj getContents]

	set env_ki_0_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ki_0_sp]
	set env_ki_0_sp_val [$env_ki_0_sp_obj getContents]
	set env_ki_1_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ki_1_sp]
	set env_ki_1_sp_val [$env_ki_1_sp_obj getContents]
	set env_ki_2_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ki_2_sp]
	set env_ki_2_sp_val [$env_ki_2_sp_obj getContents]
	set env_ki_3_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ki_3_sp]
	set env_ki_3_sp_val [$env_ki_3_sp_obj getContents]

	set dd1_dd_va_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_va_mon]
	set dd1_dd_vb_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_vb_mon]
	set dd1_dd_vc_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_vc_mon]
	set dd1_dd_vd_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_vd_mon]
	set dd1_dd_st_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_st_mon]
	set dd1_dd_finished_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_finished_mon]
	#puts "dd1_dd_finished_mon_obj is $dd1_dd_finished_mon_obj"
	set dd1_dd_request_cmd_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_dd1_dd_request_cmd]

	set dd1_dd_va_mon_val [$dd1_dd_va_mon_obj getContents]
	set dd1_dd_vb_mon_val [$dd1_dd_vb_mon_obj getContents]
	set dd1_dd_vc_mon_val [$dd1_dd_vc_mon_obj getContents]
	set dd1_dd_vd_mon_val [$dd1_dd_vd_mon_obj getContents]
	set dd1_dd_st_mon_val [$dd1_dd_st_mon_obj getContents]
	set dd1_dd_finished_mon_val [$dd1_dd_finished_mon_obj getContents]

	set env_ioffset_0_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ioffset_0_sp]
	set env_ioffset_0_sp_val [$env_ioffset_0_sp_obj getContents]
	set env_ioffset_1_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ioffset_1_sp]
	set env_ioffset_1_sp_val [$env_ioffset_1_sp_obj getContents]
	set env_ioffset_2_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ioffset_2_sp]
	set env_ioffset_2_sp_val [$env_ioffset_2_sp_obj getContents]
	set env_ioffset_3_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ioffset_3_sp]
	set env_ioffset_3_sp_val [$env_ioffset_3_sp_obj getContents]

	set env_ioffset_0_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ioffset_0_mon]
	set env_ioffset_0_mon_val [$env_ioffset_0_sp_obj getContents]
	set env_ioffset_1_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ioffset_1_mon]
	set env_ioffset_1_mon_val [$env_ioffset_1_sp_obj getContents]
	set env_ioffset_2_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ioffset_2_mon]
	set env_ioffset_2_mon_val [$env_ioffset_2_sp_obj getContents]
	set env_ioffset_3_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ioffset_3_mon]
	set env_ioffset_3_mon_val [$env_ioffset_3_sp_obj getContents]

	set env_arc_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_arc_mon]
	set env_arc_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_arc_sp]
	set env_range_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_range_mon]
	set env_range_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_range_sp]
	# etc
	#set bunch_counter 1
	#set triger_counter 1
	#set system_status 1
	#set system_mode 1
}


body DCS::LiberaDetailView::ddRequestCmd {} {
### This method send trigger request for DD1 port via epicsgw
	$dd1_dd_request_cmd_obj sendContentsToServer 1
	after 10000 [code $this getPlotData]
}

body DCS::LiberaDetailView::getPlotData {args} {
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

body DCS::LiberaDetailView::cpPlotData {} {
### This method cp data to blt vector
liberay1 set $dd1_dd_va_mon_val
liberay2 set $dd1_dd_vb_mon_val
liberay3 set $dd1_dd_vc_mon_val
liberay4 set $dd1_dd_vd_mon_val
}

body DCS::LiberaDetailView::saveIntoFile {} {
# Savefile file

    set ftype { { "TEXT Files" .txt } { "All Files" * }}
    set fname [ tk_getSaveFile -filetypes $ftype -parent . ]
    if { $fname == "" } return

    set fileid [ open $fname "w" ]

set data "# index Va Vb Vc Vd "
set maxlen [llength $dd1_dd_va_mon_val]
    puts $fileid $data
for {set i 0} {$i < $maxlen} {incr i} {
	#lappend data \n
	set data ""
	lappend data "$i"
	lappend data [lindex $dd1_dd_va_mon_val $i]
	lappend data [lindex $dd1_dd_vb_mon_val $i]
	lappend data [lindex $dd1_dd_vc_mon_val $i]
	lappend data [lindex $dd1_dd_vd_mon_val $i]
    puts $fileid $data
}

    close $fileid

}

body DCS::LiberaDetailView::applyARCmode {} {
	$env_arc_sp_obj sendContentsToServer [$itk_interior.lff.tabsf.tab1.f5.combo1 current ]
	#puts [$itk_interior.lff.tabsf.tab1.f5.combo1 current]
	
#do something
}

body DCS::LiberaDetailView::applyCurrentRange {} {
	$env_range_sp_obj sendContentsToServer [$itk_interior.lff.tabsf.tab1.f6.combo2 current ]
	#do something
}

#############################################################################################################
class DCS::LiberaStringViewLabel {
	inherit ::DCS::StringViewLabel
	constructor { args } {
		eval itk_initialize $args
		announceExist
	}
}
class DCS::LiberaStringViewEntry {
	inherit ::DCS::StringViewEntry
	constructor { args } {
		eval itk_initialize $args
		announceExist
	}
}




