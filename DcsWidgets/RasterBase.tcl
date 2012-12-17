### this is used by both dcss and bluice.  So, not gui.
package provide DCSRasterBase 1.0

### To suppport rasterRun, all raster information are now in file.
### The rasterRun string only hold the status, label, and a filename.

### The Raster4DCSS is responsible for writing the file.
### The contents of the file are text in lines:
### Line 1: TAG: "RASTER DEFINITION 1.0"
### Line 2: 3DInfo
### Line 3: setup for area 0
### Line 4: setup for area 1
### Line 5: info  for area 0
### Line 6: info  for area 1
### Line 7: user setup for normal beam
### Line 8: user setup for micro beam

##################
# 3DInfo (line 2)
##################
#field 0:   video_view_match_index (not used and not updated anymore)
#           0 phi not match, 1: phi at view 1, 2: phi at view 2
#field 1:   orig (not used any more but still updated from view 0.
#field 2:   info of snapshot0: filename and orig of the snapshot.
#field 3:   info of snapshot1: filename and orig of the snapshot.
#field 4:   use collimator or not (for now, should == field 14: inline camera
#field 5:   5, 6 7: 3D scan area, widh, height and depth. (units: micron)
#field 6:
#field 7:
#field 8:   8, 9, 10:  Number of points for widh, height and depth.
#field 9:
#field 10:
#field 11:  view_index (not used anymore): used in sequence wizard setup style.
#field 12:  scan area on view0 defined (width, height).
#field 13:  scan area on view1 defined (width, depth).
#field 14:  inline camera (1) or sample camera (0).
#field 15:  15, 16: offset of area 0 on live video (not used, not updated)
#field 16:  (units: fraction)
#field 17:  17, 18: offset of area 1 on live video (not used, not updated)
#field 18:  (units: fraction)
#field 19:  19, 20: area center on snapshot 0
#field 20:  (units: fraction)
#field 21:  20, 21: area center on snapshot 1
#field 22:  (units: fraction)

## field 0, 15, 16, 17 ,18 were updated by "Match" following sample_xyz,
##                         gonio_phi + gonio_omega.
## They were used to display area on the live video
## "Match" code is in scan3DSetup.tcl (not used anymore).

### The area offsets on snapshots are primary information.
### The origs are derived from them.  This is to make convenient for
### calls to define area on the snapshots by drag the mouse.

##############################################
# Setup for Area (line 3 and line 4)
##############################################
# field 0:  sample_x for orig of area
# field 1:  sample_y for orig of area
# field 2:  sample_z for orig of area
# field 3:  angle (gonio_phi+gonio_omega) for orig of area (facing beam)
# field 4:  cell height in mm.
# field 5:  cell width  in mm.
# field 6:  number of rows.
# field 7:  number of columns.
# field 8:  pattern prefix to map cell (row, column) to diffraction file name.
# field 9:  diffraction file extension.
# field 10: threshold of peak signal to indicate valid matrix.

#############################################
# Info For Area (line 5 and line 6)
#############################################
#field 0:   area status: text:
#           rastering, waiting_for_result, checking_results (busy)
#           init, skipped, failed, paused, done (idle)
#field 1-(numRowXnumColumn): status/result of the cell.
#        "S": selcted to raster
#        "N": not selected (skip) and "NEW"
#        "X": collecting
#        "D": diffraction image ready, waiting for scores.
#        {number list}: scores

################################################
# User Setup (line 7 and line 8)
################################################
# copied from public common USER_SETUP_NAME_LIST
################################################
#field 0:   detector_distance
#field 1:   beam stop
#field 2:   delta phi
#field 3:   exposure time (with attenuation = 0%)
#field 4:   time used for area0 (display on bluice and check for resuming)
#field 5:   time used for area1
#field 6:   is the time equal to default time in system config.
#field 7:   skip area 0
#field 8:   skip area 1
#field 9:   energy used (to check for resuming)
#field 10:  single_view (0 or 1)

# single_view will hide the snapshot1 totally from bluice.
# skip area 1 just skip the area 0, but the snapshot and area are still
# visible on BluIce.

#### RasterBase
#### Raster4DCSS    send out operation messages
#### Raster4BluIce  receive operation messages and update state

class DCS::RasterBase {
    protected variable m_rasterHandle ""
    protected variable m_rasterNum -1
    protected variable m_rasterPath ""

    protected variable m_3DInfo ""
    protected variable m_setup0 ""
    protected variable m_setup1 ""
    protected variable m_info0 ""
    protected variable m_info1 ""
    protected variable m_userSetupNormal ""
    protected variable m_userSetupMicro ""

    protected variable m_isInline 0
    protected variable m_isCollimator 0

    protected common TAG "RASTER DEFINITION 1.0"

    public common USER_SETUP_NAME_LIST \
    [list distance beamstop delta time \
    time0 time1 is_default_time skip0 skip1 energy single_view]

    public method getUserSetup { }
    public method getBothUserSetup { }
    public method getUserSetupField { name }
    public method getRasterSetup { }
    public method getSetup { index } {
        puts "raster::getSetup $index"
        return [set m_setup$index]
    }
    public method getViewDefined { view_index } {
        if {$view_index != 0 && $view_index != 1} {
            return 0
        }
        set index [expr $view_index + 12]
        set viewDefined [lindex $m_3DInfo $index]
        if {$viewDefined == "1"} {
            return 1
        } else {
            return 0
        }
    }
    public method getRasterDefined { } {
        if {[getViewDefined 0] || [getViewDefined 1]} {
            return 1
        } else {
            return 0
        }
    }
    public method isSingleView { } {
        if {[getViewDefined 0] == [getViewDefined 1]} {
            return 0
        } else {
            return 1
        }
    }

    public method getRasterNumber { } {
        return $m_rasterNum
    }
    public method getPath { } {
        return $m_rasterPath
    }
    public method getAll { } {
        return [list \
        $m_3DInfo \
        $m_setup0 \
        $m_setup1 \
        $m_info0 \
        $m_info1 \
        $m_userSetupNormal \
        $m_userSetupMicro \
        ]
    }

    #### used by centerRaster
    public method getView0 { } {
        return [list [getViewDefined 0] $m_setup0 $m_info0]
    }
    public method getView1 { } {
        return [list [getViewDefined 1] $m_setup1 $m_info1]
    }

    public method isInline { } {
        return $m_isInline
    }
    public method useCollimator { } {
        return $m_isCollimator
    }

    public method allDone { }
    public method noneDone { }

    protected method readback { {silent 0} }

    public proc getMAXRUN { } {
        return 17
    }

    constructor { } {
    }
}
body DCS::RasterBase::getUserSetup { } {
    if {$m_isCollimator} {
        return $m_userSetupMicro
    } else {
        return $m_userSetupNormal
    }
}
body DCS::RasterBase::getBothUserSetup { } {
    return [list $m_userSetupNormal $m_userSetupMicro]
}
body DCS::RasterBase::getUserSetupField { name } {
    set index [lsearch -exact $USER_SETUP_NAME_LIST $name]
    if {$index < 0} {
        log_error bad name $name for raster user setup
        return -code error bad_name
    }

    if {$m_isCollimator} {
        return [lindex $m_userSetupMicro  $index]
    } else {
        return [lindex $m_userSetupNormal $index]
    }
}
body DCS::RasterBase::readback { {silent 0} } {
    if {$m_rasterHandle != ""} {
        catch { close $m_rasterHandle }
        set m_rasterHandle ""
    }
    set m_3DInfo ""
    set m_setup0 ""
    set m_setup1 ""
    set m_info0 ""
    set m_info1 ""
    set m_userSetupNormal ""
    set m_userSetupMicro ""
    set m_isInline 0
    set m_isCollimator 0

    if {$m_rasterPath == "not_exists"} {
        if {!$silent} {
            log_error Raster not defined yet
        }
        return -code error WRONG_RASTER
    }

    if {![catch {open $m_rasterPath r} m_rasterHandle]} {
        gets $m_rasterHandle tag
        if {$tag != $TAG} {
            close $m_rasterHandle
            set m_rasterHandle ""
            if {!$silent} {
                log_error failed to readback raster from $m_rasterPath: \
                Wrong FORMAT
            }
            return -code error WRONG_RASTER
        }
        gets $m_rasterHandle m_3DInfo
        gets $m_rasterHandle m_setup0
        gets $m_rasterHandle m_setup1
        gets $m_rasterHandle m_info0
        gets $m_rasterHandle m_info1
        gets $m_rasterHandle m_userSetupNormal
        gets $m_rasterHandle m_userSetupMicro
        close $m_rasterHandle
        set m_rasterHandle ""

        set m_isInline [lindex $m_3DInfo 14]
        set m_isCollimator [lindex $m_3DInfo 4]
    } else {
        set errMsg $m_rasterHandle
        set m_rasterHandle ""
        if {!$silent} {
            log_error failed to readback raster from $m_rasterPath: $errMsg
        }
        return -code error WRONG_RASTER
    }
}
body DCS::RasterBase::getRasterSetup { } {
    return $m_3DInfo
}
body DCS::RasterBase::allDone { } {
    set defined0 [getViewDefined 0]
    set defined1 [getViewDefined 1]
    set skip0 [getUserSetupField skip0]
    set skip1 [getUserSetupField skip1]

    set nodeInfo0 [lrange $m_info0 1 end]
    set nodeInfo1 [lrange $m_info1 1 end]

    if {$defined0 && $skip0 != "1"} {
        foreach e $nodeInfo0 {
            if {[string length $e] == 1 && $e != "N"} {
                puts "not allDone: e=$e"
                return 0
            }
        }
    }
    if {$defined1 && $skip1 != "1"} {
        foreach e $nodeInfo1 {
            if {[string length $e] == 1 && $e != "N"} {
                puts "not allDone: e=$e"
                return 0
            }
        }
    }
    puts "yes allDone"
    return 1
}
body DCS::RasterBase::noneDone { } {
    set nodeInfo0 [lrange $m_info0 1 end]
    set nodeInfo1 [lrange $m_info1 1 end]

    foreach e $nodeInfo0 {
        switch -exact -- $e {
            NEW -
            S -
            N {
            }
            default {
                puts "not noneDone: e=$e"
                return 0
            }
        }
    }
    foreach e $nodeInfo1 {
        switch -exact -- $e {
            NEW -
            S -
            N {
            }
            default {
                puts "not noneDone: e=$e"
                return 0
            }
        }
    }
    puts "yes noneDone"
    return 1
}
