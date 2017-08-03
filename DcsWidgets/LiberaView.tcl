#! /usr/bin/wish
#
#file create date : 2016-Aug-24 by Kazuhide Uchida
#last update      : 2017-Apr-21 by Kazuhide Uchida

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

package require DCSMdi
package require BLUICESetupTab


package require PlotWinXY
package require PlotWinRAWNUME
package require PlotWinRAWCURR

### Libera Photon GUI Create class ##########################################################################

class DCS::LiberaDetailView {
	#inherit ::itk::Widget
	inherit ::DCS::ComponentGateExtension
	#inherit ::DCS::StringViewBase <- No error but dones not show any widgets

	#itk_option definition
	#itk_option define -controlSystem controlSystem ControlSystem ::dcss
	itk_option define -stringName stringName StringName ""
	itk_option define -mdiHelper mdiHelper MdiHelper ""



	#######################################################################
	# variables
	#######################################################################
	public variable pvupdatecounter 0

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

	# test variable scope
	#public variable env_k1_mon_obj
	#public variable env_k2_mon_obj
	#public variable env_offset1_mon_obj
	#public variable env_offset2_mon_obj

	#public variable env_k1_sp_obj
	#public variable env_k2_sp_obj
	#public variable env_offset1_sp_obj
	#public variable env_offset2_sp_obj

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

	protected variable env_leakage_0_mon_obj
	protected variable env_leakage_1_mon_obj
	protected variable env_leakage_2_mon_obj
	protected variable env_leakage_3_mon_obj

	protected variable env_leakage_0_sp_obj
	protected variable env_leakage_1_sp_obj
	protected variable env_leakage_2_sp_obj
	protected variable env_leakage_3_sp_obj

	protected variable env_voltage0_mon_obj
	protected variable env_voltage1_mon_obj
	protected variable env_voltage2_mon_obj
	protected variable env_voltage3_mon_obj
	protected variable env_voltage4_mon_obj
	protected variable env_voltage5_mon_obj
	protected variable env_voltage6_mon_obj
	protected variable env_voltage7_mon_obj
	protected variable env_pbpp_1v25_mon_obj
	protected variable env_pbpp_2v5_neg_mon_obj
	protected variable env_opmode_mon_obj
	protected variable env_ilk_status_mon_obj

	protected variable env_bias_cl_mon_obj
	protected variable env_bias_int_mon_obj
	protected variable env_bias_current_mon_obj
	protected variable env_bias_voltage_mon_obj

	protected variable env_bias_cl_sp_obj
	protected variable env_bias_int_sp_obj

	protected variable env_ilk_status_obj
	protected variable env_posalg_mon_obj
	protected variable env_idgap_mon_obj
	protected variable env_calib_mon_obj
	protected variable env_max_adc_mon_obj

	protected variable env_calib_sp_obj

	protected variable env_posalg_sp_obj
	protected variable env_idgap_sp_obj

	#current range setup
	protected variable env_arc_mon_obj
	protected variable env_arc_sp_obj
	protected variable env_range_mon_obj
	protected variable env_range_sp_obj

	#pll status
	protected variable env_pll_mtlckst_mon_obj
	protected variable env_pll_stlckst_mon_obj

	#funs
	protected variable env_back_vent_act_mon_obj
	protected variable env_front_vent_act_mon_obj

	#temperature
	protected variable env_temp_mon_obj
	protected variable env_temp_inner_mon_obj
	protected variable env_temp_outer_mon_obj

	# Data on Demand (DD) port data
	#protected variable dd1_dd_va_mon_obj
	#protected variable dd1_dd_vb_mon_obj
	#protected variable dd1_dd_vc_mon_obj
	#protected variable dd1_dd_vd_mon_obj
	#protected variable dd1_dd_st_mon_obj
	#protected variable dd1_dd_finished_mon_obj
	#protected variable dd1_dd_request_cmd_obj

	#protected variable dd1_dd_va_mon_val
	#protected variable dd1_dd_vb_mon_val
	#protected variable dd1_dd_vc_mon_val
	#protected variable dd1_dd_vd_mon_val
	#protected variable dd1_dd_st_mon_val
	#protected variable dd1_dd_finished_mon_val

	#protected variable adccw_ignore_trig_mon_obj
	#protected variable adccw_ignore_trig_sp_obj

	# device info
	protected variable liberadevlist [list Libera01 Libera02 Libera03 Libera04 Libera05]
	protected variable liberabpmlist [list bpm01 bpm02 bpm03 bpm04 bpm05]
	public common liberaNo
	public common bpmNo

	# operation info
	protected variable posalgoval [list 0:behindID 1:behindBM 2:behindBMlog]
	protected variable currentrangeval [list 0:2nA 1:20nA 2:200nA 3:2uA 4:20uA 5:200uA 6:1850uA]
	protected variable rangemodeval [list 0:manual 1:auto]
	protected variable calibspval [list 0:OFF 1:UNITY 2:AUTO 3:SAVE 4:MANUAL_RANGE 5:MANUAL_ALL]

	#setup othre variable. This is same as StringViewBase
	protected variable m_site
	protected variable _lastStringName ""

	# variable to open child widget
	private variable _widgetCount

	# plot window existance flag
	protected variable plotwinrawnumeexist 0
	protected variable plotwinrawcurrexist 0
	protected variable plotwinxyexist 0
	
	#######################################################################
	#  methods
	#######################################################################
	protected method updatepv
	protected method saveIntoFile

	protected method applyARCmode
	protected method applyCurrentRange
	protected method applyPosAlg
	protected method applyCalib


	protected method checkContentsBeforeSend { contentsREF } {
       return 1
	}

	#methods for open child window. copied from SetupTab
	public method openChildWin
	public method openToolChest
	public method launchWidget 
	public method checkAndActivateExistingDocument

	#######################################################################
	# proc
	####################################################################### 
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

	proc sa_monitor {} {
		puts "trace_was_exeuted"
	}
	
	### new window open test.
	#proc open_plot_window {} {
	#	toplevel .t0
	#	message .t0.msg -text "This is toplevel and message sample."
	#	pack .t0.msg
	#}

	constructor { args } {}
	destructor {
		puts "This is destructor of LiberaDetailView class."

    }
}


############################################################################################################
# LiberaDetailView class constructor body.
############################################################################################################

body DCS::LiberaDetailView::constructor {args} {
	#puts "This is LiberaDetailView class constructor"

	#######################################################################
	# Setup left side frame (lff)
	#######################################################################
	itk_component add leftframe {
		frame $itk_interior.lff
	}

	### device selection box on the leftside frame (devicef)
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

	#pack device selection components on left top.
	pack $itk_interior.lff.devicef.f1.l1 $itk_interior.lff.devicef.f1.d1 -side left -padx 2
	pack $itk_interior.lff.devicef.f2.l2 $itk_interior.lff.devicef.f2.d2 -side left -padx 2
	pack $itk_interior.lff.devicef.f1 $itk_interior.lff.devicef.f2 -pady 5
	pack $itk_interior.lff.devicef -anchor w -padx 5

	### update pv-gateway connection
	updatepv
	set liberaNo [$itk_interior.lff.devicef.f1.d1 current]
	set bpmNo [$itk_interior.lff.devicef.f2.d2 current]

	#######################################################################
	# setup tabs frame for current status display and parameters config
	#######################################################################
	itk_component add notetab {
		ttk::notebook $itk_interior.lff.tabsf -width 500 -height 500
	} {}
	
	#######################################################################
	# add tabs 
	#	tab1 : status
	#	tab2 : DAQ mode control ... This will be implimented in future.
	#	tab3 : Calibration and Bias
	#	tab4 : Preamp gain (range control) and Position Algorithm setup
	#	tab5 : position calc coeff & offsets
	#	tab6 : leakage compensation
	#######################################################################

	itk_component add tab1 {
		ttk::frame $itk_interior.lff.tabsf.tab1;
	} {}
	$itk_interior.lff.tabsf add $itk_interior.lff.tabsf.tab1 -text "Status"

	itk_component add tab2 {
		ttk::frame $itk_interior.lff.tabsf.tab2;
	} {}
	$itk_interior.lff.tabsf add $itk_interior.lff.tabsf.tab2 -text "DAQ mode"

	itk_component add tab3 {
		ttk::frame $itk_interior.lff.tabsf.tab3;
	} {}
	$itk_interior.lff.tabsf add $itk_interior.lff.tabsf.tab3 -text "Calib. & BIAS"

	itk_component add tab4 {
		ttk::frame $itk_interior.lff.tabsf.tab4;
	} {}
	$itk_interior.lff.tabsf add $itk_interior.lff.tabsf.tab4 -text "Meas. range & Pos. Algo."

	itk_component add tab5 {
		ttk::frame $itk_interior.lff.tabsf.tab5;
	} {}
	$itk_interior.lff.tabsf add $itk_interior.lff.tabsf.tab5 -text "Parameters1"

	itk_component add tab6 {
		ttk::frame $itk_interior.lff.tabsf.tab6;
	} {}
	$itk_interior.lff.tabsf add $itk_interior.lff.tabsf.tab6 -text "Parameters2"


	### status tab setup (tab1)
	itk_component add tab1flr {
		frame $itk_interior.lff.tabsf.tab1.l -width 245
		frame $itk_interior.lff.tabsf.tab1.r -width 245
	}

	itk_component add tab1f {
		frame $itk_interior.lff.tabsf.tab1.l.f1 -borderwidth 1 -relief solid
		frame $itk_interior.lff.tabsf.tab1.l.f2 -borderwidth 1 -relief solid 
		frame $itk_interior.lff.tabsf.tab1.l.f3 -borderwidth 1 -relief solid
		frame $itk_interior.lff.tabsf.tab1.r.f4 -borderwidth 1 -relief solid
		frame $itk_interior.lff.tabsf.tab1.r.f5 -borderwidth 1 -relief solid
		frame $itk_interior.lff.tabsf.tab1.r.f6 -borderwidth 1 -relief solid
		frame $itk_interior.lff.tabsf.tab1.r.f7 -borderwidth 1 -relief solid
		frame $itk_interior.lff.tabsf.tab1.r.f8 -borderwidth 1 -relief solid
	}

	itk_component add dbv {
		label $itk_interior.lff.tabsf.tab1.l.f1.t1 -text "Digital board Voltage \[V\]"}
	itk_component add abv {
		label $itk_interior.lff.tabsf.tab1.l.f2.t2 -text "Analog board Voltage \[V\]"}
	itk_component add bs {
		label $itk_interior.lff.tabsf.tab1.l.f3.t3 -text "BIAS status"}
	itk_component add si {
		label $itk_interior.lff.tabsf.tab1.r.f4.t4 -text "Signal Info"}
	itk_component add plls {
		label $itk_interior.lff.tabsf.tab1.r.f5.t5 -text "PLL status"}
	itk_component add ilks {
		label $itk_interior.lff.tabsf.tab1.r.f6.t6 -text "Interlock status"}
	itk_component add fans {
		label $itk_interior.lff.tabsf.tab1.r.f7.t7 -text "Fans \[RPM\]"}
	itk_component add tmpera {
		label $itk_interior.lff.tabsf.tab1.r.f8.t8 -text "Temperature \[deg.C.\]"}



	# Digital and Analog Board Voltage monitor
	itk_component add tab1fl1 {
		label $itk_interior.lff.tabsf.tab1.l.f1.l1 -text "1.500 V"
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f1.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_voltage0_mon_obj} {}
	itk_component add tab1fl2 {
		label $itk_interior.lff.tabsf.tab1.l.f1.l3 -text "1.800 V" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f1.l4 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_voltage1_mon_obj} {}
	itk_component add tab1fl3 {
		label $itk_interior.lff.tabsf.tab1.l.f1.l5 -text "2.500 V" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f1.l6 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_voltage2_mon_obj} {}
	itk_component add tab1fl4 {
		label $itk_interior.lff.tabsf.tab1.l.f1.l7 -text "3.300 V" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f1.l8 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_voltage3_mon_obj} {}
	itk_component add tab1fl5 {
		label $itk_interior.lff.tabsf.tab1.l.f1.l9 -text "5.000 V" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f1.l10 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_voltage4_mon_obj} {}
	itk_component add tab1fl6 {
		label $itk_interior.lff.tabsf.tab1.l.f1.l11 -text "12.000 V" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f1.l12 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_voltage5_mon_obj} {}
	itk_component add tab1fl7 {
		label $itk_interior.lff.tabsf.tab1.l.f1.l13 -text "-12.000 V" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f1.l14 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_voltage6_mon_obj} {}
	itk_component add tab1fl8 {
		label $itk_interior.lff.tabsf.tab1.l.f1.l15 -text "-5.000 V" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f1.l16 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_voltage7_mon_obj} {}

	itk_component add tab1fl9 {
		label $itk_interior.lff.tabsf.tab1.l.f2.l1 -text "1.250 V" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f2.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_pbpp_1v25_mon_obj} {}
	itk_component add tab1fl10 {
		label $itk_interior.lff.tabsf.tab1.l.f2.l3 -text "2.500 V" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f2.l4 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_pbpp_2v5_neg_mon_obj} {}

	itk_component add tab1fl15 {
		label $itk_interior.lff.tabsf.tab1.l.f3.l1 -text "Op Mode" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f3.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_opmode_mon_obj} {}
	itk_component add tab1fl11 {
		label $itk_interior.lff.tabsf.tab1.l.f3.l3 -text "Internal BIAS" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f3.l4 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_bias_int_mon_obj} {}
	itk_component add tab1fl12 {
		label $itk_interior.lff.tabsf.tab1.l.f3.l5 -text "BIAS Voltage" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f3.l6 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_bias_voltage_mon_obj} {}
	itk_component add tab1fl13 {
		label $itk_interior.lff.tabsf.tab1.l.f3.l7 -text "BIAS Current" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f3.l8 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_bias_current_mon_obj} {}
	itk_component add tab1fl14 {
		label $itk_interior.lff.tabsf.tab1.l.f3.l9 -text "BIAS Curr. Lim." -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.l.f3.l10 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_bias_cl_mon_obj} {}

	#pack digital board voltages label
	grid $itk_interior.lff.tabsf.tab1.l.f1.t1 -columnspan 2
	grid $itk_interior.lff.tabsf.tab1.l.f1.l1 $itk_interior.lff.tabsf.tab1.l.f1.l2 -padx 2 -pady 3
	grid $itk_interior.lff.tabsf.tab1.l.f1.l3 $itk_interior.lff.tabsf.tab1.l.f1.l4 -padx 2 -pady 3
	grid $itk_interior.lff.tabsf.tab1.l.f1.l5 $itk_interior.lff.tabsf.tab1.l.f1.l6 -padx 2 -pady 3 
	grid $itk_interior.lff.tabsf.tab1.l.f1.l7 $itk_interior.lff.tabsf.tab1.l.f1.l8 -padx 2 -pady 3 
	grid $itk_interior.lff.tabsf.tab1.l.f1.l9 $itk_interior.lff.tabsf.tab1.l.f1.l10 -padx 2 -pady 3
	grid $itk_interior.lff.tabsf.tab1.l.f1.l11 $itk_interior.lff.tabsf.tab1.l.f1.l12 -padx 2 -pady 3 
	grid $itk_interior.lff.tabsf.tab1.l.f1.l13 $itk_interior.lff.tabsf.tab1.l.f1.l14 -padx 2 -pady 3 
	grid $itk_interior.lff.tabsf.tab1.l.f1.l15 $itk_interior.lff.tabsf.tab1.l.f1.l16 -padx 2 -pady 3
	#pack analog board voltages label
	grid $itk_interior.lff.tabsf.tab1.l.f2.t2 -columnspan 2
	grid $itk_interior.lff.tabsf.tab1.l.f2.l1 $itk_interior.lff.tabsf.tab1.l.f2.l2 -padx 2 -pady 3 
	grid $itk_interior.lff.tabsf.tab1.l.f2.l3 $itk_interior.lff.tabsf.tab1.l.f2.l4 -padx 2 -pady 3 
	#pack bias status
	grid $itk_interior.lff.tabsf.tab1.l.f3.t3 -columnspan 2
	grid $itk_interior.lff.tabsf.tab1.l.f3.l1 $itk_interior.lff.tabsf.tab1.l.f3.l2 -padx 2 -pady 3
	grid $itk_interior.lff.tabsf.tab1.l.f3.l3 $itk_interior.lff.tabsf.tab1.l.f3.l4 -padx 2 -pady 3
	grid $itk_interior.lff.tabsf.tab1.l.f3.l5 $itk_interior.lff.tabsf.tab1.l.f3.l6 -padx 2 -pady 3
	grid $itk_interior.lff.tabsf.tab1.l.f3.l7 $itk_interior.lff.tabsf.tab1.l.f3.l8 -padx 2 -pady 3
	grid $itk_interior.lff.tabsf.tab1.l.f3.l9 $itk_interior.lff.tabsf.tab1.l.f3.l10 -padx 2 -pady 3 

	pack $itk_interior.lff.tabsf.tab1.l.f1 $itk_interior.lff.tabsf.tab1.l.f2 $itk_interior.lff.tabsf.tab1.l.f3  -pady 7 -padx 5 -fill x

	#signal status
	itk_component add tab1fr1 {
		label $itk_interior.lff.tabsf.tab1.r.f4.l1 -text "Range" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f4.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_range_mon_obj} {}
	itk_component add tab1fr2 {
		label $itk_interior.lff.tabsf.tab1.r.f4.l3 -text "MAX ADC" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f4.l4 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_max_adc_mon_obj} {}
	itk_component add tab1fr3 {
		label $itk_interior.lff.tabsf.tab1.r.f4.l5 -text "ARC" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f4.l6 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_arc_mon_obj} {}
	itk_component add tab1fr4 {
		label $itk_interior.lff.tabsf.tab1.r.f4.l7 -text "Calib" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f4.l8 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_calib_mon_obj} {}
	itk_component add tab1fr5 {
		label $itk_interior.lff.tabsf.tab1.r.f4.l9 -text "ID gap" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f4.l10 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_idgap_mon_obj} {}
	itk_component add tab1fr6 {
		label $itk_interior.lff.tabsf.tab1.r.f4.l11 -text "PosAlg" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f4.l12 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_posalg_mon_obj} {}
	#PLL status
	itk_component add tab1fr7 {
		label $itk_interior.lff.tabsf.tab1.r.f5.l1 -text "MC PLL" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f5.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_pll_mtlckst_mon_obj} {}
	itk_component add tab1fr8 {
		label $itk_interior.lff.tabsf.tab1.r.f5.l3 -text "SC PLL" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f5.l4 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_pll_stlckst_mon_obj} {}

	#ILK
	itk_component add tab1fr9 {
		label $itk_interior.lff.tabsf.tab1.r.f6.l1 -text "ILK code" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f6.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ilk_status_mon_obj} {}

	#Fands
	itk_component add tab1fr10 {
		label $itk_interior.lff.tabsf.tab1.r.f7.l1 -text "Front" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f7.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_front_vent_act_mon_obj} {}
	itk_component add tab1fr11 {
		label $itk_interior.lff.tabsf.tab1.r.f7.l3 -text "Back" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f7.l4 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_back_vent_act_mon_obj} {}


	#Temperature
	itk_component add tab1fr12 {
		label $itk_interior.lff.tabsf.tab1.r.f8.l1 -text "Front" -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f8.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_temp_mon_obj} {}
	itk_component add tab1fr13 {
		label $itk_interior.lff.tabsf.tab1.r.f8.l3 -text "Inner " -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f8.l4 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_temp_inner_mon_obj} {}
	itk_component add tab1fr14 {
		label $itk_interior.lff.tabsf.tab1.r.f8.l5 -text "Outer " -width 18 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab1.r.f8.l6 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_temp_outer_mon_obj} {}

	#pack signalinfo 
	grid $itk_interior.lff.tabsf.tab1.r.f4.t4 -columnspan 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f4.l1 $itk_interior.lff.tabsf.tab1.r.f4.l2 -padx 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f4.l3 $itk_interior.lff.tabsf.tab1.r.f4.l4 -padx 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f4.l5 $itk_interior.lff.tabsf.tab1.r.f4.l6 -padx 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f4.l7 $itk_interior.lff.tabsf.tab1.r.f4.l8 -padx 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f4.l9 $itk_interior.lff.tabsf.tab1.r.f4.l10 -padx 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f4.l11 $itk_interior.lff.tabsf.tab1.r.f4.l12 -padx 2 -pady 2
	#pack PLL status
	grid $itk_interior.lff.tabsf.tab1.r.f5.t5 -columnspan 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f5.l1 $itk_interior.lff.tabsf.tab1.r.f5.l2 -padx 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f5.l3 $itk_interior.lff.tabsf.tab1.r.f5.l4 -padx 2 -pady 2

	#pack Interlocak status
	grid $itk_interior.lff.tabsf.tab1.r.f6.t6 -columnspan 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f6.l1 $itk_interior.lff.tabsf.tab1.r.f6.l2 -padx 2 -pady 2

	#pack Fans status
	grid $itk_interior.lff.tabsf.tab1.r.f7.t7 -columnspan 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f7.l1 $itk_interior.lff.tabsf.tab1.r.f7.l2 -padx 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f7.l3 $itk_interior.lff.tabsf.tab1.r.f7.l4 -padx 2 -pady 2

	#pack Temperature 
	grid $itk_interior.lff.tabsf.tab1.r.f8.t8 -columnspan 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f8.l1 $itk_interior.lff.tabsf.tab1.r.f8.l2 -padx 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f8.l3 $itk_interior.lff.tabsf.tab1.r.f8.l4 -padx 2 -pady 2
	grid $itk_interior.lff.tabsf.tab1.r.f8.l5 $itk_interior.lff.tabsf.tab1.r.f8.l6 -padx 2 -pady 2

	pack $itk_interior.lff.tabsf.tab1.r.f4 $itk_interior.lff.tabsf.tab1.r.f5 $itk_interior.lff.tabsf.tab1.r.f6 \
			 $itk_interior.lff.tabsf.tab1.r.f7 $itk_interior.lff.tabsf.tab1.r.f8 -pady 3 -padx 5 -fill both

	pack $itk_interior.lff.tabsf.tab1.l $itk_interior.lff.tabsf.tab1.r -side left 
	#pack $itk_interior.lff.tabsf.tab1
	
	
	### setup DAQ mode(tab2)

	itk_component add tab2f {
		frame $itk_interior.lff.tabsf.tab2.f1
	}
	# add DAQ select button
	itk_component add tab2fb {
		button $itk_interior.lff.tabsf.tab2.f1.b1 -text "ADC raw       (300 kS/s)" -width 40 -bg gray
		button $itk_interior.lff.tabsf.tab2.f1.b2 -text "Buffered data ( 10 kS/s)" -width 40 -bg gray
		button $itk_interior.lff.tabsf.tab2.f1.b3 -text "Data stream   ( 10  S/s)" -width 40 -bg gray
		button $itk_interior.lff.tabsf.tab2.f1.b4 -text "Currents"                 -width 40 -bg gray
		button $itk_interior.lff.tabsf.tab2.f1.b5 -text "Postmortem data"          -width 40 -bg gray
		button $itk_interior.lff.tabsf.tab2.f1.b6 -text "yobi" -width 40 -bg gray
	}

	pack $itk_interior.lff.tabsf.tab2.f1.b1 $itk_interior.lff.tabsf.tab2.f1.b2 $itk_interior.lff.tabsf.tab2.f1.b3 $itk_interior.lff.tabsf.tab2.f1.b4 $itk_interior.lff.tabsf.tab2.f1.b5 -pady 5 
	pack $itk_interior.lff.tabsf.tab2.f1 -pady 5


	### setup Calibration & BIAS (tab3)
	itk_component add tab3f {
		frame $itk_interior.lff.tabsf.tab3.f1 -width 70
		frame $itk_interior.lff.tabsf.tab3.f2 -width 70
		frame $itk_interior.lff.tabsf.tab3.f3 -width 70
		frame $itk_interior.lff.tabsf.tab3.f4 -width 70
	}

	#internal calib button EMV_BIAS_
	itk_component add intrcalib {
		label $itk_interior.lff.tabsf.tab3.f1.title -text "Internal Calibration\n" -width 30 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab3.f1.l1 -text "Select and wait for finish" -width 34 -anchor w -padx 5 -font {{ＭＳ gothic} 8}

	}
	itk_component add intrcalibcomb {
		ttk::combobox $itk_interior.lff.tabsf.tab3.f1.combo1 -textvariable calibval -values $calibspval \
									-background yellow -foreground black -width 20 -justify left -state normal
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f1.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_calib_sp_obj} {keep -textvariable}

	#bind to apply change
	$itk_interior.lff.tabsf.tab3.f1.combo1 current 0
	bind $itk_interior.lff.tabsf.tab3.f1.combo1 <<ComboboxSelected>> [code $this applyCalib]
	# readback
	itk_component add tab3calibrb {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f1.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_calib_mon_obj} {}

	#Bias control mode 0:IDLE mode, 1: GND mode, 2:InternalBIAS mode
	itk_component add biascont {
		label $itk_interior.lff.tabsf.tab3.f2.l1 -text "Bias Operating mode" -width 57 -anchor w -padx 5 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f2.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_opmode_mon_obj} {}

	# status of internal BIAS voltage environment variable
	itk_component add biasvolt {
		label $itk_interior.lff.tabsf.tab3.f3.l1 -text "BIAS Voltabge \[V\]" -width 20 -anchor w -padx 5 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f3.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_bias_int_sp_obj} {keep -textvariable}
	itk_component add biasvoltrb {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f3.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_bias_int_mon_obj} {}

	# status of BIAS current limit enviroment variable
	itk_component add biascurr {
		label $itk_interior.lff.tabsf.tab3.f4.l1 -text "BIAS Current limit" -width 20 -anchor w -padx 5 -font {{ＭＳ gothic} 8}
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab3.f4.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_bias_cl_sp_obj} {keep -textvariable}
	itk_component add biascurrrb {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab3.f4.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_bias_cl_mon_obj} {}

	pack $itk_interior.lff.tabsf.tab3.f1.title -fill both
	pack $itk_interior.lff.tabsf.tab3.f1.l1 $itk_interior.lff.tabsf.tab3.f1.combo1 $itk_interior.lff.tabsf.tab3.f1.l2 -side left -fill both
	pack $itk_interior.lff.tabsf.tab3.f2.l1 $itk_interior.lff.tabsf.tab3.f2.l2 -side left -fill both
	pack $itk_interior.lff.tabsf.tab3.f3.l1 $itk_interior.lff.tabsf.tab3.f3.e1 $itk_interior.lff.tabsf.tab3.f3.l2 -side left 
	pack $itk_interior.lff.tabsf.tab3.f4.l1 $itk_interior.lff.tabsf.tab3.f4.e1 $itk_interior.lff.tabsf.tab3.f4.l2 -side left 

	pack $itk_interior.lff.tabsf.tab3.f1 $itk_interior.lff.tabsf.tab3.f2 $itk_interior.lff.tabsf.tab3.f3 $itk_interior.lff.tabsf.tab3.f4 -padx 5 -pady 1 -fill both




	### setup preamp gain (tab4)
	itk_component add tab4f {
		frame $itk_interior.lff.tabsf.tab4.f1 -width 70
		frame $itk_interior.lff.tabsf.tab4.f2 -width 70
		frame $itk_interior.lff.tabsf.tab4.f3 -width 70
		frame $itk_interior.lff.tabsf.tab4.f4 -width 70
		frame $itk_interior.lff.tabsf.tab4.f5 -width 70
		frame $itk_interior.lff.tabsf.tab4.f6 -width 70
	}	

	# measuring range control
	itk_component add meascont {
		label $itk_interior.lff.tabsf.tab4.f1.l1 -text "Measuring range control" -width 20 -anchor w -padx 5 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab4.f2.l1 -text "Range mode      " -width 20 -anchor w -padx 5 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab4.f3.l1 -text "Mearsuing Range " -width 20 -anchor w -padx 5 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab4.f4.l1 -text "MAX ADC         " -width 43 -anchor w -padx 5 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab4.f5.l1 -text "Position Algorithm " -width 20 -anchor w -padx 5 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab4.f6.l1 -text   "___________________________________________________ \n \
									 0 ...  behind insertion device\n \
										X = k1((Ia+Id) - (Ib + Ic))/SUM - OFF1 \n \
									       Y = k2((Ia+Ib) - (Ic + Id))/SUM - OFF2 \n  \
									____________________________________________________ \n \
									 1 ... behind bending magnet\n \
										X = k1(Ia - Id) / (Ib + Ic) - OFF1 \n \
									       Y = k2(Ia - Ib) / (Ic + Id) - OFF2 \n  \
									____________________________________________________ \n \
									 2 ... behind bending magnet\, logarithmic\n \
										X = k1 log(Ia/Id)- OFF1 \n \
									       Y = k2 log(Ib/Ic)- OFF2 \n  \
									_____________________________________________________ \n "
	}
	# add range mode select widget
	itk_component add rangecomb {
		ttk::combobox $itk_interior.lff.tabsf.tab4.f2.combo1 -textvariable rangemode -values $rangemodeval \
									-background yellow -foreground black -width 20 -justify left -state normal
		set rangemode "manual"
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab4.f2.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_arc_sp_obj} {keep -textvariable}

	#bind to apply change
	$itk_interior.lff.tabsf.tab4.f2.combo1 current 0
	bind $itk_interior.lff.tabsf.tab4.f2.combo1 <<ComboboxSelected>> [code $this applyARCmode]
	# readback
	itk_component add tab1f5l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab4.f2.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_arc_mon_obj} {}


	# add range select widget
	itk_component add reangeconb2 {
		ttk::combobox $itk_interior.lff.tabsf.tab4.f3.combo1 -textvariable currentrange -values $currentrangeval \
									-background yellow -foreground black -width 20 -justify left -state normal
		set currentrange "3:2uA"
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab4.f3.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_range_sp_obj} {keep -textvariable}
	
	# bind to apply change
	$itk_interior.lff.tabsf.tab4.f3.combo1 current 6
	bind $itk_interior.lff.tabsf.tab4.f3.combo1 <<ComboboxSelected>> [code $this applyCurrentRange]
	# readback
	itk_component add tab4f6l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab4.f3.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_range_mon_obj} {}


	# max adc
	itk_component add maxdac {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab4.f4.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_max_adc_mon_obj} {}


	# pos alg
	itk_component add posalgcomb {
		ttk::combobox $itk_interior.lff.tabsf.tab4.f5.combo1 -textvariable posalgo -values $posalgoval \
									-background yellow -foreground black -width 20 -justify left -state normal
		set posalgo "0:behindID"
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab4.f5.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_posalg_sp_obj} {keep -textvariable}

	# bind to apply change
	$itk_interior.lff.tabsf.tab4.f5.combo1 current 0
	bind $itk_interior.lff.tabsf.tab4.f5.combo1 <<ComboboxSelected>> [code $this applyPosAlg]
	# readback
	itk_component add posalgrb {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab4.f5.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_posalg_mon_obj} {}

	pack $itk_interior.lff.tabsf.tab4.f1.l1
	pack $itk_interior.lff.tabsf.tab4.f2.l1 $itk_interior.lff.tabsf.tab4.f2.combo1 $itk_interior.lff.tabsf.tab4.f2.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab4.f3.l1 $itk_interior.lff.tabsf.tab4.f3.combo1 $itk_interior.lff.tabsf.tab4.f3.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab4.f4.l1 $itk_interior.lff.tabsf.tab4.f4.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab4.f5.l1 $itk_interior.lff.tabsf.tab4.f5.combo1 $itk_interior.lff.tabsf.tab4.f5.l2 -side left -pady 5
	pack $itk_interior.lff.tabsf.tab4.f6.l1 -pady 5

	pack $itk_interior.lff.tabsf.tab4.f1 $itk_interior.lff.tabsf.tab4.f2 $itk_interior.lff.tabsf.tab4.f3 $itk_interior.lff.tabsf.tab4.f4 \
		$itk_interior.lff.tabsf.tab4.f5 $itk_interior.lff.tabsf.tab4.f6 
	#pack $itk_interior.lff.tabsf.tab1 do not pack this line



	### setup parameter tab(tab5)
	### Offset tab setup
	itk_component add tab5f {
		frame $itk_interior.lff.tabsf.tab5.f1 
		frame $itk_interior.lff.tabsf.tab5.f2 
		frame $itk_interior.lff.tabsf.tab5.f3 
		frame $itk_interior.lff.tabsf.tab5.f4 
	}

	itk_component add tab5fl1 {
		label $itk_interior.lff.tabsf.tab5.f1.titlel -text "General geometry factors" -font {{ＭＳ gothic} 8}
        	label $itk_interior.lff.tabsf.tab5.f1.l1 -text "k1 \[nm\]" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab5.f2.l1 -text "k2 \[nm\]" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab5.f3.l1 -text "Offset1 \[nm\]" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab5.f4.l1 -text "Offset2 \[nm\]" -width 15 -font {{ＭＳ gothic} 8}
	} { }
	### widget for setpoint
	itk_component add tab5fe1 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f1.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_k1_sp_obj} {keep -textvariable}
	itk_component add tab5fe2 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f2.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_k2_sp_obj} {keep -textvariable}
	itk_component add tab5fe3 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f3.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_offset1_sp_obj} {keep -textvariable}
	itk_component add tab5fe4 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f4.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_offset2_sp_obj} {keep -textvariable}
	### widget for readback
	itk_component add tab5fl2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f1.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_k1_mon_obj} {}
	itk_component add tab5fl3 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f2.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_k2_mon_obj } {}
	itk_component add tab5fl4 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f3.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_offset1_mon_obj} {}
	itk_component add tab5fl5 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f4.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_offset2_mon_obj} {}
	
	pack $itk_interior.lff.tabsf.tab5.f1.titlel -fill x -pady 5
	pack $itk_interior.lff.tabsf.tab5.f1.l1 $itk_interior.lff.tabsf.tab5.f1.e1 $itk_interior.lff.tabsf.tab5.f1.l2 -side left 
	pack $itk_interior.lff.tabsf.tab5.f2.l1 $itk_interior.lff.tabsf.tab5.f2.e1 $itk_interior.lff.tabsf.tab5.f2.l2 -side left
	pack $itk_interior.lff.tabsf.tab5.f3.l1 $itk_interior.lff.tabsf.tab5.f3.e1 $itk_interior.lff.tabsf.tab5.f3.l2 -side left 
	pack $itk_interior.lff.tabsf.tab5.f4.l1 $itk_interior.lff.tabsf.tab5.f4.e1 $itk_interior.lff.tabsf.tab5.f4.l2 -side left
	pack $itk_interior.lff.tabsf.tab5.f1 $itk_interior.lff.tabsf.tab5.f2 $itk_interior.lff.tabsf.tab5.f3 $itk_interior.lff.tabsf.tab5.f4 -pady 1

	### Calibration tab setup
	itk_component add tab5calib {
		frame $itk_interior.lff.tabsf.tab5.f5
		frame $itk_interior.lff.tabsf.tab5.f6
		frame $itk_interior.lff.tabsf.tab5.f7
		frame $itk_interior.lff.tabsf.tab5.f8
		frame $itk_interior.lff.tabsf.tab5.f9 
		frame $itk_interior.lff.tabsf.tab5.f10
		frame $itk_interior.lff.tabsf.tab5.f11
		frame $itk_interior.lff.tabsf.tab5.f12
	} {}

	itk_component add tab5calibl {
		label $itk_interior.lff.tabsf.tab5.f5.titlel -text "Channel related factors" -font {{ＭＳ gothic} 8}
        	label $itk_interior.lff.tabsf.tab5.f5.l1 -text "KI_0" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab5.f6.l1 -text "KI_1" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab5.f7.l1 -text "KI_2" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab5.f8.l1 -text "KI_3" -width 15 -font {{ＭＳ gothic} 8}

        	label $itk_interior.lff.tabsf.tab5.f9.l1 -text "IOFFSET_0" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab5.f10.l1 -text "IOFFSET_1" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab5.f11.l1 -text "IOFFSET_2" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab5.f12.l1 -text "IOFFSET_3" -width 15 -font {{ＭＳ gothic} 8}
	} { }
	### widget for setpoint
	itk_component add tab5calibfe1 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f5.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_0_sp_obj } {keep -textvariable}
	itk_component add tab5calibfe2 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f6.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_1_sp_obj } {keep -textvariable}
	itk_component add tab5calibfe3 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f7.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_2_sp_obj } {keep -textvariable}
	itk_component add tab5calibfe4 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f8.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_3_sp_obj } {keep -textvariable}
	itk_component add tab5calibfe5 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f9.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_0_sp_obj } {keep -textvariable}
	itk_component add tab5calibfe6 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f10.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_1_sp_obj } {keep -textvariable}
	itk_component add tab5calibfe7 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f11.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_2_sp_obj } {keep -textvariable}
	itk_component add tab5calibfe8 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab5.f12.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_3_sp_obj } {keep -textvariable}

	### widget for readback
	itk_component add tab5calibf1l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f5.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_0_mon_obj } {}
	itk_component add tab5calibf2l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f6.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_1_mon_obj } {}
	itk_component add tab5calibf3l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f7.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_2_mon_obj } {}
	itk_component add tab5calibfl2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f8.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ki_3_mon_obj } {}
	itk_component add tab5calibf5l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f9.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_0_mon_obj } {}
	itk_component add tab5calibf6l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f10.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_1_mon_obj } {}
	itk_component add tab5calibf7l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f11.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_2_mon_obj } {}
	itk_component add tab5calibf8l2 {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab5.f12.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_ioffset_3_mon_obj } {}
	# test
	#itk_component add tab5calibf9l2 {
	#	entry $itk_interior.lff.tabsf.tab5.f12.testl -textvariable $liberaNo } {keep -textvariable}

	pack $itk_interior.lff.tabsf.tab5.f5.titlel -fill x -pady 5
	pack $itk_interior.lff.tabsf.tab5.f5.l1 $itk_interior.lff.tabsf.tab5.f5.e1 $itk_interior.lff.tabsf.tab5.f5.l2 -side left
	pack $itk_interior.lff.tabsf.tab5.f6.l1 $itk_interior.lff.tabsf.tab5.f6.e1 $itk_interior.lff.tabsf.tab5.f6.l2 -side left
	pack $itk_interior.lff.tabsf.tab5.f7.l1 $itk_interior.lff.tabsf.tab5.f7.e1 $itk_interior.lff.tabsf.tab5.f7.l2 -side left
	pack $itk_interior.lff.tabsf.tab5.f8.l1 $itk_interior.lff.tabsf.tab5.f8.e1 $itk_interior.lff.tabsf.tab5.f8.l2 -side left
	pack $itk_interior.lff.tabsf.tab5.f9.l1 $itk_interior.lff.tabsf.tab5.f9.e1 $itk_interior.lff.tabsf.tab5.f9.l2 -side left
	pack $itk_interior.lff.tabsf.tab5.f10.l1 $itk_interior.lff.tabsf.tab5.f10.e1 $itk_interior.lff.tabsf.tab5.f10.l2 -side left
	pack $itk_interior.lff.tabsf.tab5.f11.l1 $itk_interior.lff.tabsf.tab5.f11.e1 $itk_interior.lff.tabsf.tab5.f11.l2 -side left 
	pack $itk_interior.lff.tabsf.tab5.f12.l1 $itk_interior.lff.tabsf.tab5.f12.e1 $itk_interior.lff.tabsf.tab5.f12.l2 -side left
	# test
	#pack $itk_interior.lff.tabsf.tab5.f12.testl

	#pack tab5 frame
	pack $itk_interior.lff.tabsf.tab5.f5 $itk_interior.lff.tabsf.tab5.f6 $itk_interior.lff.tabsf.tab5.f7 $itk_interior.lff.tabsf.tab5.f8 \
		$itk_interior.lff.tabsf.tab5.f9 $itk_interior.lff.tabsf.tab5.f10 $itk_interior.lff.tabsf.tab5.f11 $itk_interior.lff.tabsf.tab5.f12 

	### setup leakage (tab6)
	itk_component add tab6leak {
		frame $itk_interior.lff.tabsf.tab6.f13
		frame $itk_interior.lff.tabsf.tab6.f14
		frame $itk_interior.lff.tabsf.tab6.f15
		frame $itk_interior.lff.tabsf.tab6.f16
	} {}

	itk_component add tab5leakll {
		label $itk_interior.lff.tabsf.tab6.f13.titlel -text "Leakage current compensation \(in pA\)" -font {{ＭＳ gothic} 8}
        	label $itk_interior.lff.tabsf.tab6.f13.l1 -text "Ch. A " -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab6.f14.l1 -text "Ch. B" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab6.f15.l1 -text "Ch. C" -width 15 -font {{ＭＳ gothic} 8}
		label $itk_interior.lff.tabsf.tab6.f16.l1 -text "Ch. D" -width 15 -font {{ＭＳ gothic} 8}
	} {}

	### widget for setpoint
	itk_component add tab6leak0 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab6.f13.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_leakage_0_sp_obj } {keep -textvariable}
	itk_component add tab6leak1 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab6.f14.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_leakage_1_sp_obj } {keep -textvariable}
	itk_component add tab6leak2 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab6.f15.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_leakage_2_sp_obj } {keep -textvariable}
	itk_component add tab6leak3 {
		DCS::LiberaStringViewEntry $itk_interior.lff.tabsf.tab6.f16.e1 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_leakage_3_sp_obj } {keep -textvariable}

	### widget for readback
	itk_component add tab6leak0rb {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab6.f13.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_leakage_0_mon_obj } {}
	itk_component add tab6leak1rb {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab6.f14.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_leakage_1_mon_obj } {}
	itk_component add tab6leak2rb {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab6.f15.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_leakage_2_mon_obj } {}
	itk_component add tab6leak3rb {
		DCS::LiberaStringViewLabel $itk_interior.lff.tabsf.tab6.f16.l2 -systemIdleOnly 0 -activeClientOnly 0 -stringName $env_leakage_3_mon_obj } {}

	pack $itk_interior.lff.tabsf.tab6.f13.titlel -pady 5
	pack $itk_interior.lff.tabsf.tab6.f13.l1  $itk_interior.lff.tabsf.tab6.f13.e1 $itk_interior.lff.tabsf.tab6.f13.l2 -side left
	pack $itk_interior.lff.tabsf.tab6.f14.l1  $itk_interior.lff.tabsf.tab6.f14.e1 $itk_interior.lff.tabsf.tab6.f14.l2 -side left
	pack $itk_interior.lff.tabsf.tab6.f15.l1  $itk_interior.lff.tabsf.tab6.f15.e1 $itk_interior.lff.tabsf.tab6.f15.l2 -side left
	pack $itk_interior.lff.tabsf.tab6.f16.l1  $itk_interior.lff.tabsf.tab6.f16.e1 $itk_interior.lff.tabsf.tab6.f16.l2 -side left


	# pack tab6 frames
	pack $itk_interior.lff.tabsf.tab6.f13 $itk_interior.lff.tabsf.tab6.f14 $itk_interior.lff.tabsf.tab6.f15 $itk_interior.lff.tabsf.tab6.f16 -pady 1
	

	##### pack tabs frame (left bottom)

	pack $itk_interior.lff.tabsf -pady 1


	#######################################################################
	# Readout display (Right side flame)
	#######################################################################

	#itk_component add ring {
		frame $itk_interior.graphf -bd 1 
	#}

	itk_component add ring {
		frame $itk_interior.r
	}

	itk_component add Mdi {
		DCS::MDICanvas $itk_component(ring).m $this -background black -relief sunken -borderwidth 2
	} { }


	itk_component add graphf1 {
		frame $itk_interior.graphf.f1 -bd 1 -relief solid
	}
	itk_component add  graphf2 {
		frame $itk_interior.graphf.f2 -bd 1 -relief solid

	}
	itk_component add  graphf3 {
		frame $itk_interior.graphf.f3 -bd 1 -relief solid
	}
	
	# Not used.
	itk_component add readoutlabel {
		label $itk_interior.graphf.f1.label -text "Data readout" -font {{ＭＳ gothic} 8}
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


	### setup plot window launch button.
	itk_component add open_window_rawneum {
		button $itk_interior.graphf.f1.pb1 -text "ADC Data Plot(4 Ch.)" -height 5 -command [code $this openChildWin plotWinRAWNUME $liberaNo $bpmNo]
	} {}
	itk_component add open_window_rawcurr {
		button $itk_interior.graphf.f1.pb2 -text "Current Plot" -height 5 -command [code $this openChildWin plotWinRAWCURR $liberaNo $bpmNo]
	} {}
	itk_component add open_window_xy {
		button $itk_interior.graphf.f1.pb3 -text "Position Plot" -height 5 -command [code $this openChildWin plotWinXY $liberaNo $bpmNo]
		#button $itk_interior.graphf.f1.pb3 -text "open plot winXY" -height 5 -command [code $this openToolChest plotWinXY $liberaNo $bpmNo]
	} {}


    	#pack 
	pack $itk_interior.graphf.f1.label -fill x -pady 20
	pack $itk_interior.graphf.f1.pb1 $itk_interior.graphf.f1.pb2 $itk_interior.graphf.f1.pb3 -pady 10 -padx 5 -fill x
	pack $itk_interior.graphf.f1 -pady 5 -fill y -pady 80

	### setup descriptive statistic value display 
	#itk_component add discrff {
	#	frame $itk_interior.graphf.f3.f1 
	#	frame $itk_interior.graphf.f3.f2 
	#}

	#itk_component add discrflab {
       # 	label $itk_interior.graphf.f3.f1.l1 -text "X position \[nm\]" -width 15
	#	label $itk_interior.graphf.f3.f1.l3 -text "Y position \[nm\]" -width 15
	#	label $itk_interior.graphf.f3.f1.l5 -text "SUM \[a.u.\] " -width 15
	#	#label $itk_interior.graphf.f3.f2.l2 -text "Q" -width 15
	#	} { 
	#		keep -background -foreground -font
	#	}

	#itk_component add discrftext {
	#	DCS::LiberaStringViewLabel $itk_interior.graphf.f3.f1.l2 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_x_mon_obj } {} 

	#itk_component add discrftext2 {
	#	DCS::LiberaStringViewLabel $itk_interior.graphf.f3.f1.l4 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_y_mon_obj } {} 

	#itk_component add discrftext3 {
	#	DCS::LiberaStringViewLabel $itk_interior.graphf.f3.f1.l6 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_sum_mon_obj } {} 		

	#itk_component add discrftext4 {
	#	DCS::LiberaStringViewLabel $itk_interior.graphf.f3.f2.l4 \
	#		-systemIdleOnly 0 -activeClientOnly 0 -stringName $sa_q_mon_obj } {} 

	#pack $itk_interior.graphf.f3.f1.l1 $itk_interior.graphf.f3.f1.l2 $itk_interior.graphf.f3.f1.l3 \
	#	$itk_interior.graphf.f3.f1.l4 $itk_interior.graphf.f3.f1.l5 $itk_interior.graphf.f3.f1.l6 -fill x
	#pack $itk_interior.graphf.f3.f1 -pady 5 -fill x
	#pack $itk_interior.graphf.f3

	
	### pack left and right frame
	pack $itk_interior.lff $itk_interior.graphf -side left -fill y -padx 10 -pady 10
		# itk_initialize analize options and affect widgets
		

		eval itk_initialize $args
		announceExist

	###pack $itk_component(ring) -expand yes -fill both
	###pack $itk_component(Mdi) -expand yes -fill both

### end of constructor ########################################################
}


####################################################################################################################################
#
# method body definition
#
####################################################################################################################################


body DCS::LiberaDetailView::updatepv {} {
### This method will update variables connected with EPICS records.
#global liberaNo
#global bpmNo


set liberaNo [$itk_interior.lff.devicef.f1.d1 current]
set bpmNo [$itk_interior.lff.devicef.f2.d2 current]
#puts ${liberaNo}_${bpmNo}_sa_a_mon
	set deviceFactory [DCS::DeviceFactory::getObject]
	#puts $deviceFactory
	#if { $pvupdatecounter > 0 } {puts "test"}

	# Check the device existance
	if {0 == [DCS::DeviceFactory::stringExists ${liberaNo}_${bpmNo}_sa_a_mon]} then {
		set liberaNo 0
		set bpmNo 0
		$itk_interior.lff.devicef.f1.d1 set [lindex $liberadevlist 0]
		$itk_interior.lff.devicef.f2.d2 set [lindex $liberabpmlist 0]
		puts "Device Not Found. Default device was selected."
	}


	#if {$liberaNo == 1 } {
	#	set env_k1_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_k1_mon]
	#	set env_k1_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_k1_sp]
	#	$itk_interior.lff.tabsf.tab5.f1.l2 configure -stringName $env_k1_mon_obj
	#	$itk_interior.lff.tabsf.tab5.f1.e1 configure -stringName $env_k1_sp_obj
	#}

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
	set env_k2_mon_val [$env_k2_mon_obj getContents]
	set env_offset1_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_offset1_mon]
	set env_offset1_mon_val [$env_offset1_mon_obj getContents]
	set env_offset2_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_offset2_mon]
	set env_offset2_mon_val [$env_offset2_mon_obj getContents]

	set env_k1_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_k1_sp]
	set env_k1_sp_val [$env_k1_sp_obj getContents]
	set env_k2_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_k2_sp]
	set env_k2_sp_val [$env_k2_sp_obj getContents]
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

	set env_leakage_0_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_leakage_0_mon]
	set env_leakage_1_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_leakage_1_mon]
	set env_leakage_2_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_leakage_2_mon]
	set env_leakage_3_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_leakage_3_mon]

	set env_leakage_0_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_leakage_0_sp]
	set env_leakage_1_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_leakage_1_sp]
	set env_leakage_2_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_leakage_2_sp]
	set env_leakage_3_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_leakage_3_sp]

	set env_arc_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_arc_mon]
	set env_arc_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_arc_sp]
	set env_range_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_range_mon]
	set env_range_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_range_sp]

	set env_voltage0_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_voltage0_mon]
	set env_voltage1_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_voltage1_mon]
	set env_voltage2_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_voltage2_mon]
	set env_voltage3_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_voltage3_mon]
	set env_voltage4_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_voltage4_mon]
	set env_voltage5_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_voltage5_mon]
	set env_voltage6_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_voltage6_mon]
	set env_voltage7_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_voltage7_mon]
	set env_pbpp_1v25_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_pbpp_1v25_mon]
	set env_pbpp_2v5_neg_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_pbpp_2v5_neg_mon]
	set env_pbpp_2v5_neg_mon_val [$env_pbpp_2v5_neg_mon_obj getContents]
	set env_opmode_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_opmode_mon]
	set env_opmode_mon_val [$env_opmode_mon_obj getContents]

	#interlock status
	set env_ilk_status_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ilk_status_mon]

	set env_calib_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_calib_mon]
	set env_bias_cl_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_bias_cl_mon]
	set env_bias_int_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_bias_int_mon]
	set env_bias_current_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_bias_current_mon]
	set env_bias_voltage_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_bias_voltage_mon]

	set env_calib_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_calib_sp]
	set env_bias_cl_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_bias_cl_sp]
	set env_bias_int_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_bias_int_sp]

	#signal info
	set env_ilk_status_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_ilk_status]
	set env_posalg_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_posalg_mon]
	set env_idgap_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_idgap_mon]
	set env_calib_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_calib_mon]
	set env_max_adc_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_max_adc_mon]

	set env_posalg_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_posalg_sp]
	set env_idgap_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_idgap_sp]

	#pll status
	set env_pll_mtlckst_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_pll_mtlckst_mon]
	set env_pll_stlckst_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_pll_stlckst_mon]

	#funs
	set env_back_vent_act_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_back_vent_act_mon]
	set env_front_vent_act_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_front_vent_act_mon]

	#temperature
	set env_temp_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_temp_mon]
	set env_temp_inner_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_temp_inner_mon]
	set env_temp_outer_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_temp_outer_mon]


	set adccw_ignore_trig_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_ign_trig_mon]
	set adccw_ignore_trig_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_adccw_ign_trig_sp]

	#puts "ign-trig value is"
	#puts [$adccw_ignore_trig_sp_obj getContents]
	
	

	if { $pvupdatecounter > 0 } {
	### configure the widget options

$itk_interior.lff.tabsf.tab1.l.f1.l2 configure -stringName $env_voltage0_mon_obj
$itk_interior.lff.tabsf.tab1.l.f1.l4 configure -stringName $env_voltage1_mon_obj
$itk_interior.lff.tabsf.tab1.l.f1.l6 configure -stringName $env_voltage2_mon_obj
$itk_interior.lff.tabsf.tab1.l.f1.l8 configure -stringName $env_voltage3_mon_obj
$itk_interior.lff.tabsf.tab1.l.f1.l10 configure -stringName $env_voltage4_mon_obj
$itk_interior.lff.tabsf.tab1.l.f1.l12 configure -stringName $env_voltage5_mon_obj
$itk_interior.lff.tabsf.tab1.l.f1.l14 configure -stringName $env_voltage6_mon_obj
$itk_interior.lff.tabsf.tab1.l.f1.l16 configure -stringName $env_voltage7_mon_obj

$itk_interior.lff.tabsf.tab1.l.f2.l2 configure -stringName $env_pbpp_1v25_mon_obj
$itk_interior.lff.tabsf.tab1.l.f2.l4 configure -stringName $env_pbpp_2v5_neg_mon_obj
$itk_interior.lff.tabsf.tab1.l.f3.l2 configure -stringName $env_opmode_mon_obj
$itk_interior.lff.tabsf.tab1.l.f3.l4 configure -stringName $env_bias_int_mon_obj
$itk_interior.lff.tabsf.tab1.l.f3.l6 configure -stringName $env_bias_voltage_mon_obj
$itk_interior.lff.tabsf.tab1.l.f3.l8 configure -stringName $env_bias_current_mon_obj
$itk_interior.lff.tabsf.tab1.l.f3.l10 configure -stringName $env_bias_cl_mon_obj
$itk_interior.lff.tabsf.tab1.r.f4.l2 configure -stringName $env_range_mon_obj
$itk_interior.lff.tabsf.tab1.r.f4.l4 configure -stringName $env_max_adc_mon_obj
$itk_interior.lff.tabsf.tab1.r.f4.l6 configure -stringName $env_arc_mon_obj
$itk_interior.lff.tabsf.tab1.r.f4.l8 configure -stringName $env_calib_mon_obj
$itk_interior.lff.tabsf.tab1.r.f4.l10 configure -stringName $env_idgap_mon_obj
$itk_interior.lff.tabsf.tab1.r.f4.l12 configure -stringName $env_posalg_mon_obj
$itk_interior.lff.tabsf.tab1.r.f5.l2 configure -stringName $env_pll_mtlckst_mon_obj
$itk_interior.lff.tabsf.tab1.r.f5.l4 configure -stringName $env_pll_stlckst_mon_obj
$itk_interior.lff.tabsf.tab1.r.f6.l2 configure -stringName $env_ilk_status_mon_obj
$itk_interior.lff.tabsf.tab1.r.f7.l2 configure -stringName $env_front_vent_act_mon_obj
$itk_interior.lff.tabsf.tab1.r.f7.l4 configure -stringName $env_back_vent_act_mon_obj
$itk_interior.lff.tabsf.tab1.r.f8.l2 configure -stringName $env_temp_mon_obj
$itk_interior.lff.tabsf.tab1.r.f8.l4 configure -stringName $env_temp_inner_mon_obj
$itk_interior.lff.tabsf.tab1.r.f8.l6 configure -stringName $env_temp_outer_mon_obj

$itk_interior.lff.tabsf.tab3.f1.e1 configure -stringName $env_calib_sp_obj
$itk_interior.lff.tabsf.tab3.f1.l2 configure -stringName $env_calib_mon_obj
$itk_interior.lff.tabsf.tab3.f2.l2 configure -stringName $env_opmode_mon_obj
$itk_interior.lff.tabsf.tab3.f3.e1 configure -stringName $env_bias_int_sp_obj
$itk_interior.lff.tabsf.tab3.f3.l2 configure -stringName $env_bias_int_mon_obj
$itk_interior.lff.tabsf.tab3.f4.e1 configure -stringName $env_bias_cl_sp_obj
$itk_interior.lff.tabsf.tab3.f4.l2 configure -stringName $env_bias_cl_mon_obj

$itk_interior.lff.tabsf.tab4.f2.l2 configure -stringName $env_arc_mon_obj
$itk_interior.lff.tabsf.tab4.f3.e1 configure -stringName $env_range_sp_obj
$itk_interior.lff.tabsf.tab4.f3.l2 configure -stringName $env_range_mon_obj
$itk_interior.lff.tabsf.tab4.f4.l2 configure -stringName $env_max_adc_mon_obj
$itk_interior.lff.tabsf.tab4.f5.e1 configure -stringName $env_posalg_sp_obj
$itk_interior.lff.tabsf.tab4.f5.l2 configure -stringName $env_posalg_mon_obj

$itk_interior.lff.tabsf.tab5.f1.e1 configure -stringName $env_k1_sp_obj
$itk_interior.lff.tabsf.tab5.f2.e1 configure -stringName $env_k2_sp_obj
$itk_interior.lff.tabsf.tab5.f3.e1 configure -stringName $env_offset1_sp_obj
$itk_interior.lff.tabsf.tab5.f4.e1 configure -stringName $env_offset2_sp_obj
$itk_interior.lff.tabsf.tab5.f1.l2 configure -stringName $env_k1_mon_obj
$itk_interior.lff.tabsf.tab5.f2.l2 configure -stringName $env_k2_mon_obj
$itk_interior.lff.tabsf.tab5.f3.l2 configure -stringName $env_offset1_mon_obj
$itk_interior.lff.tabsf.tab5.f4.l2 configure -stringName $env_offset2_mon_obj

$itk_interior.lff.tabsf.tab5.f5.e1 configure -stringName $env_ki_0_sp_obj
$itk_interior.lff.tabsf.tab5.f6.e1 configure -stringName $env_ki_1_sp_obj
$itk_interior.lff.tabsf.tab5.f7.e1 configure -stringName $env_ki_2_sp_obj
$itk_interior.lff.tabsf.tab5.f8.e1 configure -stringName $env_ki_3_sp_obj
$itk_interior.lff.tabsf.tab5.f9.e1 configure -stringName $env_ioffset_0_sp_obj
$itk_interior.lff.tabsf.tab5.f10.e1 configure -stringName $env_ioffset_1_sp_obj
$itk_interior.lff.tabsf.tab5.f11.e1 configure -stringName $env_ioffset_2_sp_obj
$itk_interior.lff.tabsf.tab5.f12.e1 configure -stringName $env_ioffset_3_sp_obj
$itk_interior.lff.tabsf.tab5.f5.l2 configure -stringName $env_ki_0_mon_obj
$itk_interior.lff.tabsf.tab5.f6.l2 configure -stringName $env_ki_1_mon_obj
$itk_interior.lff.tabsf.tab5.f7.l2 configure -stringName $env_ki_2_mon_obj
$itk_interior.lff.tabsf.tab5.f8.l2 configure -stringName $env_ki_3_mon_obj
$itk_interior.lff.tabsf.tab5.f9.l2 configure -stringName $env_ioffset_0_mon_obj
$itk_interior.lff.tabsf.tab5.f10.l2 configure -stringName $env_ioffset_1_mon_obj
$itk_interior.lff.tabsf.tab5.f11.l2 configure -stringName $env_ioffset_2_mon_obj
$itk_interior.lff.tabsf.tab5.f12.l2 configure -stringName $env_ioffset_3_mon_obj

$itk_interior.lff.tabsf.tab6.f13.e1 configure -stringName $env_leakage_0_sp_obj
$itk_interior.lff.tabsf.tab6.f14.e1 configure -stringName $env_leakage_1_sp_obj
$itk_interior.lff.tabsf.tab6.f15.e1 configure -stringName $env_leakage_2_sp_obj
$itk_interior.lff.tabsf.tab6.f16.e1 configure -stringName $env_leakage_3_sp_obj
$itk_interior.lff.tabsf.tab6.f13.l2 configure -stringName $env_leakage_0_mon_obj
$itk_interior.lff.tabsf.tab6.f14.l2 configure -stringName $env_leakage_1_mon_obj
$itk_interior.lff.tabsf.tab6.f15.l2 configure -stringName $env_leakage_2_mon_obj
$itk_interior.lff.tabsf.tab6.f16.l2 configure -stringName $env_leakage_3_mon_obj

# clear the entry widgets value <- this cause entry widget linkage error.
$itk_interior.lff.tabsf.tab3.f1.e1 deleteAll
$itk_interior.lff.tabsf.tab3.f3.e1 deleteAll
$itk_interior.lff.tabsf.tab3.f4.e1 deleteAll

$itk_interior.lff.tabsf.tab4.f3.e1 deleteAll
$itk_interior.lff.tabsf.tab4.f5.e1 deleteAll

$itk_interior.lff.tabsf.tab5.f1.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f2.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f3.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f4.e1 deleteAll

$itk_interior.lff.tabsf.tab5.f5.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f6.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f7.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f8.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f9.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f10.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f11.e1 deleteAll
$itk_interior.lff.tabsf.tab5.f12.e1 deleteAll

$itk_interior.lff.tabsf.tab6.f13.e1 deleteAll
$itk_interior.lff.tabsf.tab6.f14.e1 deleteAll
$itk_interior.lff.tabsf.tab6.f15.e1 deleteAll
$itk_interior.lff.tabsf.tab6.f16.e1 deleteAll
	}
	set pvupdatecounter 1
}

body DCS::LiberaDetailView::saveIntoFile {} {
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

body DCS::LiberaDetailView::applyARCmode {} {
set liberaNo [$itk_interior.lff.devicef.f1.d1 current]
set bpmNo [$itk_interior.lff.devicef.f2.d2 current]
	set env_arc_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_arc_mon]
	set env_arc_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_arc_sp]

	$env_arc_sp_obj sendContentsToServer [$itk_interior.lff.tabsf.tab4.f2.combo1 current ]
	#puts [$itk_interior.lff.tabsf.tab1.f5.combo1 current]
	#do something
}

body DCS::LiberaDetailView::applyCurrentRange {} {
set liberaNo [$itk_interior.lff.devicef.f1.d1 current]
set bpmNo [$itk_interior.lff.devicef.f2.d2 current]
	set env_range_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_range_mon]
	set env_range_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_range_sp]
	$env_range_sp_obj sendContentsToServer [$itk_interior.lff.tabsf.tab4.f3.combo1 current ]
	#do something
}

body DCS::LiberaDetailView::applyPosAlg {} {
set liberaNo [$itk_interior.lff.devicef.f1.d1 current]
set bpmNo [$itk_interior.lff.devicef.f2.d2 current]
	set env_posalg_mon_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_posalg_mon]
	$env_posalg_sp_obj sendContentsToServer [$itk_interior.lff.tabsf.tab4.f5.combo1 current ]
	#do something
}

body DCS::LiberaDetailView::applyCalib {  } {
set liberaNo [$itk_interior.lff.devicef.f1.d1 current]
set bpmNo [$itk_interior.lff.devicef.f2.d2 current]
set env_calib_sp_obj [$deviceFactory getObjectName ${liberaNo}_${bpmNo}_env_calib_sp]
	$env_calib_sp_obj sendContentsToServer [$itk_interior.lff.tabsf.tab3.f1.combo1 current ]

}

body DCS::LiberaDetailView::openChildWin { name liberaNo bpmNo } {
	#set path [$itk_component(Mdi) addDocument $name -title "Plot Window 1"  -resizable 1  -width 1550 -height 600]
	set parentname [winfo parent [winfo parent $itk_component(leftframe)]]

set liberaNo [$itk_interior.lff.devicef.f1.d1 current]
set bpmNo [$itk_interior.lff.devicef.f2.d2 current]

	#if {![winfo exists .t0]} {
	#	toplevel .t0
       #	wm title .t0 "About"
       #	message .t0.msg -width 100 \
       #      	   -text $parentname
      	#  	pack .t0.msg
	#	#if {![winfo exists $parentname.plotwinXY]} { }

		if {$name == "plotWinXY"} {
			if {$plotwinxyexist == 1} {
				delete object $parentname.plotWinXY0
				DCS::PlotWinXY $parentname.plotWinXY0 $liberaNo $bpmNo
				set plotwinxyexist 1
				#puts $plotwinxyexist
			} else {
				DCS::PlotWinXY $parentname.plotWinXY0 $liberaNo $bpmNo
				#puts [DCS::PlotWinXY::$parentname.plotWinXY0 whoami]
				set plotwinxyexist 1
				#puts $plotwinxyexist
			}
		} elseif { $name == "plotWinRAWCURR" } {
			if {$plotwinrawcurrexist == 1} {
				delete object $parentname.plotWinRAWCURR0
				DCS::PlotWinRAWCURR $parentname.plotWinRAWCURR0 $liberaNo $bpmNo
				#DCS::PlotWinRAWCURR .plotWinRAWCURR#auto $liberaNo $bpmNo
				set plotwinrawcurrexist 1
			} else {
				DCS::PlotWinRAWCURR $parentname.plotWinRAWCURR0 $liberaNo $bpmNo
				set plotwinrawcurrexist 1
			}
		} else {
			if {$plotwinrawnumeexist == 1} {
				delete object $parentname.plotWinRAWNUME0
				DCS::PlotWinRAWNUME $parentname.plotWinRAWNUME0 $liberaNo $bpmNo
				set plotwinrawnumeexist 1
				#puts $plotwinrawnumeexist
			} else {

				DCS::PlotWinRAWNUME $parentname.plotWinRAWNUME0 $liberaNo $bpmNo
				#puts [DCS::PlotWinXY::$parentname.plotWinXY0 whoami]
				set plotwinrawnumeexist 1
				#puts $plotwinrawnumeexist			}
		}
		
		
	#}
	
	#set mdi widget
	#itk_component add ring {
	#	frame $itk_interior.r
	#}
	#
	#itk_component add Mdi {
	#	DCS::MDICanvas $itk_component(ring).m $this -background black
	#} {}
	#pack $itk_component(Mdi)

	#set path
	#set parentname [winfo parent $itk_component(tab3f1l2)]
	#set path [$itk_component(Mdi) addDocument $name \
	#	            -title "win1"  -resizable 1  -width 550 -height 600]

	#create child window
	#itk_component add $name {
		#DCS::PlotWin1 .setup.r.m.r.mdiCanvas.lwchildsite.clipper.canvas.$name
		#SetupTab::launchWidget $name
	#	label $path.ll -text $parentname
	#} {}
	#pack $itk_component($name) -expand 1 -fill both
}

### following methodes are not used yet.

body DCS::LiberaDetailView::openToolChest { name liberaNo bpmNo} {
	#store the current pointer shape and set it to a watch/clock to show the system is busy
	#puts "test test test in the openToolChest definition"
	#puts $name 
	blt::busy hold . -cursor watch
	update
	
	if {[catch {
		launchWidget $name $liberaNo $bpmNo
	} err ] } {
	global errorInfo
	puts $errorInfo
	}

	blt::busy release .
}

body DCS::LiberaDetailView::launchWidget {name liberaNo bpmNo} {
	#puts [info exists _widgetCount($name)]
	if {![info exists _widgetCount($name)]} {
		set _widgetCount($name) 0
		#puts "if statement was excuted in launchWidget"
	}

	switch $name {
	       plotWinXY {  
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name \
				    -title "plotWinXY"  -resizable 1  -width 750 -height 600]

			itk_component add $name {
				DCS::PlotWinXY $path.$name  $liberaNo $bpmNo
			} { }
			pack $itk_component($name) -expand 1 -fill both
		}
	}		
}

body DCS::LiberaDetailView::checkAndActivateExistingDocument {documentName_} {
	if { [info exists itk_component($documentName_)] } {
		$itk_component(Mdi) activateDocument $documentName_
		return 1
	}

	return 0
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




