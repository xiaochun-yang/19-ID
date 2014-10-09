#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"
#

package require Itcl
package require yaml
namespace import ::itcl::*

################################################
# copied and modified from MicroSpectScanResult
class MicroSpecConverter {
    protected variable m_numResult 0
    protected variable m_numPoint 0
    protected variable m_reference ""
    protected variable m_saturatedRefCount 65535
    protected variable m_dark ""
    protected variable m_wavelength ""
    protected variable m_result ""
    protected variable m_motorName ""
    protected variable m_path ""

    protected variable m_fileList ""
    protected variable m_doseRate 0
    ### need these for save to file
    protected variable m_beamline ""
    protected variable m_light    ""
    protected variable m_sample_x ""
    protected variable m_sample_y ""
    protected variable m_sample_z ""
    protected variable m_sample_a ""
    protected variable m_iTime
    protected variable m_nAvg
    protected variable m_bWidth
    protected variable m_timestamp ""

    protected variable m_numSaturated 0

    protected common SATURATED_RAW_COUNT 65535

    public method convertFile { path {outputPath ""}}

    protected method retrieveHeader { header }
    protected method calculateFromRaw { dd }
    protected method writeSingleFile { path singleContentsRef }
    protected method writeAllFile { path }

    protected proc generateSingleCSVPath { path } {
        set root [file rootname $path]
        return ${root}.csv
    }
    protected proc generateAllCSVPath { path } {
        set root [file rootname $path]

        return [list ${root}_raw.csv ${root}_absr.csv ${root}_trns.csv]
    }
    protected proc getHuddleContents { path } {
        if {[catch {
            ::yaml::yaml2huddle -file $path
        } hhhh]} {
            puts "read yaml file $path failed: $hhhh"
            return -code error $hhhh
        }
        return $hhhh
    }
    protected proc getDictContents { path } {
        if {[catch {
            ::yaml::yaml2dict -types str  -file $path
        } hhhh]} {
            puts "read yaml file $path failed: $hhhh"
            return -code error $hhhh
        }
        return $hhhh
    }
    protected proc contentsIsHeader { hhhh } {
        if {[catch {
            huddle gets $hhhh reference
        } ref]} {
            return 0
        }
        return 1
    }
    protected proc getHeaderPath { singlePath } {
        set dir      [file dirname $singlePath]
        set filename [file tail $singlePath]
        set ext      [file extension $filename]
        set root     [file rootname  $filename]

        set last     [string last _ $root]

        if {$last < 0} {
            puts "bad filename pattern $singlePath"
            return -code error failed_to_parse_singlePath
        }
        incr last -1

        set headerFilename [string range $root 0 $last]
        if {$ext != ""} {
            append headerFilename $ext
        }

        return [file join $dir $headerFilename]
    }
    protected proc getMotorDisplayName { motor } {
        switch -exact -- $motor {
            dose -
            time { return Time }
            gonio_phi   { return Phi }
            gonio_omega { return Omega }
            gonio_kappa { return Kappa }
            default { return $motor }
        }
    }
    protected proc getMotorUnits { motor } {
        switch -exact -- $motor {
            time { return Seconds }
            gonio_phi   { return deg }
            gonio_omega { return deg }
            gonio_kappa { return deg }
            default { return "" }
        }
    }
    protected method formatResult { h } {
        set position    [dict get $h position]
        set timestamp   [dict get $h timestamp]
        set raw         [dict get $h raw]
        if {[catch {
            set absor   [dict get $h absorbance]
        } errMsg]} {
            set absor   ""
        }
        if {[catch {
            set trans   [dict get $h transmittance]
        } errMsg]} {
            set trans   ""
        }
        if {[catch {
            set dose   [dict get $h dose]
        } errMsg]} {
            set dose ""
        }

        set motorDisplayName [getMotorDisplayName $m_motorName]
        set units [getMotorUnits $m_motorName]

        if {$m_numSaturated} {
            set title "WARNING: saturated "
        } else {
            set title ""
        }

        if {$m_motorName == "snapshot"} {
            append title "Snapshot"
        } else {
            append title "${motorDisplayName}=[format %.3f ${position}] $units"
        }

        puts "motor=$m_motorName dose=$dose"

        if {$m_motorName == "dose"} {
            if {![string is double -strict $dose] || $dose < 0} {
                set dose 0
            }
            append title "/Estimated Dose=[format %.0f $dose] Gy"
        } elseif {[string is double -strict $dose] && $dose > 0} {
            append title "/Estimated Dose=[format %.0f $dose] Gy"
        } elseif {$m_motorName == "time" && $m_doseRate > 0} {
            #### old scan data
            set dose [expr $position * $m_doseRate]
            append title "/Estimated Dose=[format %.0f $dose] Gy"
        }
        append title " $timestamp"

        return [list $m_motorName $position $title $raw $absor $trans]
    }

    constructor { } {
    }
}
body MicroSpecConverter::calculateFromRaw { ddRef } {
    upvar $ddRef dd

    set rawCList [dict get $dd raw]

    set absorbanceCList ""
    set transmittanceCList ""

    set m_numSaturated 0
    foreach s $rawCList r $m_reference d $m_dark {
        if {$s < $SATURATED_RAW_COUNT && $r < $m_saturatedRefCount} {
            set ref [expr $r - $d]
            set trn [expr $s - $d]
        } else {
            set ref 0
            set trn 0
            incr m_numSaturated
        }

        if {$ref > 0 && $trn > 0} {
            set t [expr 1.0 * $trn / $ref]
            set a [expr -log10( $t )]
        } else {
            set a 0.0
            set t 0.0
        }

        lappend absorbanceCList $a
        lappend transmittanceCList $t
    }
    dict set dd absorbance   $absorbanceCList
    dict set dd transmittance $transmittanceCList
}
body MicroSpecConverter::retrieveHeader { header } {
    ### extract header
    set m_beamline   [huddle gets $header beamline]
    set m_motorName  [huddle gets $header motorName]
    set m_numPoint   [huddle gets $header numPoint]
    set m_timestamp  [huddle gets $header timestamp]
    set m_reference  [huddle gets $header reference]
    set m_dark       [huddle gets $header dark]
    set m_wavelength [huddle gets $header wavelength]
    set m_fileList   [huddle gets $header scan_result]
    set m_sample_x   [huddle gets $header sample_x]
    set m_sample_y   [huddle gets $header sample_y]
    set m_sample_z   [huddle gets $header sample_z]
    set m_sample_a   [huddle gets $header sample_angle]
    set m_iTime      [huddle gets $header integrationTime]
    set m_nAvg       [huddle gets $header scansToAverage]
    set m_bWidth     [huddle gets $header boxcarWidth]
    set m_numResult  [llength $m_fileList]
    if {[catch {
        huddle gets $header reference_threshold
    } m_saturatedRefCount]} {
        set m_saturatedRefCount 65535
        puts "reference_threshold not defined, assuming 65535"
    }
    if {[catch {
        huddle gets $header lightBulb
    } m_light]} {
        set m_light VIS
        puts "lightBulb not defined, assuming VIS"
    }
    set m_doseRate 0
    set keys [huddle keys $header]
    if {[lsearch -exact $keys dose_rate] >= 0} {
        set m_doseRate [huddle gets $header dose_rate]
    }

    puts "numResult=$m_numResult numPoint=$m_numPoint"
}

body MicroSpecConverter::convertFile { path_ {outputPath_ ""} } {
    if {$path_ == ""} {
        puts "need path"
        return
    }
    set dir [file dirname $path_]

    set header [getHuddleContents $path_]
    set singleFile 0

    if {![contentsIsHeader $header]} {
        set singleFile 1

        set headerPath [getHeaderPath $path_]
        puts "single file.  Retrieving its header from $headerPath"
        set header [getHuddleContents $headerPath]
        if {![contentsIsHeader $header]} {
            puts "bad file contents of $headerPath"
            return -code error BAD_HEADER
        }
    }
    retrieveHeader $header
    
    if {$singleFile} {
        if {$outputPath_ == ""} {
            set outputPath [generateSingleCSVPath $path_]    
        } else {
            set outputPath $outputPath_
        }
        set singleContents [getDictContents $path_]
        calculateFromRaw singleContents
        ### same as the save on the GUI
        puts "writing single output: $outputPath"
        writeSingleFile $outputPath singleContents
        return
    }

    ### load all files.
    set m_result ""
    set numGot 0
    if {$m_numResult > 0} {
        foreach file $m_fileList {
            set path [file join $dir $file]
            puts "loading $path"
            if {[catch {
                ::yaml::yaml2dict -file -types str $path
            } dd]} {
                log_error read scan result file $path failed: $hhhh
                break
            }
            calculateFromRaw dd
            lappend m_result $dd
            incr numGot
        }
    }
    if {$numGot <= 0} {
        puts "no individual file loaded"
        return
    }

    if {$outputPath_ == ""} {
        set allOutPath [generateAllCSVPath $path_]    
    } else {
        set allOutPath [generateAllCSVPath $outputPath_]    
    }

    puts "writing ALL out to $allOutPath"
    writeAllFile $allOutPath
}
body MicroSpecConverter::writeSingleFile { path resultRef } {
    upvar $resultRef result

    if {[catch {open $path w} handle]} {
        puts "failed to open $path to write: $handle"
        return -code error FAILED_TO_WRITE
    }
    set header "wavelength,reference,dark"
    append header ",raw,absorbance,transmittance"
    append header ",motorName,position,timestamp"
    append header ",integrationTime,scansToAverage,boxcarWidth"
    append header ",sample_x,sample_y,sample_z,sample_angle(phi+omega)"
    puts $handle $header

    foreach {mName p ts rList aList tList} [formatResult $result] break

    set firstLine ",,"
    append firstLine ",,,"
    append firstLine ",$m_motorName,$p,$ts"
    append firstLine ",$m_iTime,$m_nAvg,$m_bWidth"
    append firstLine ",$m_sample_x,$m_sample_y,$m_sample_z,$m_sample_a"
    puts $handle $firstLine

    foreach w $m_wavelength rf $m_reference d $m_dark \
    r $rList a $aList t $tList {
        set line "$w,$rf,$d"
        append line ",$r,$a,$t"
        append line ",,,"
        append line ",,,"
        append line ",,,"
        puts $handle $line
    }
    close $handle
    puts "saved scan to file $path"
}
body MicroSpecConverter::writeAllFile { path } {
    if {[llength $path] != 3} {
        puts "wrong path"
        return
    }
    foreach {rawPath absrPath trnsPath} $path break

    if {[catch {open $rawPath w} hRaw]} {
        puts "failed to open $rawPath to write: $hRaw"
        return -code error FAILED_TO_WRITE
    }
    if {[catch {open $absrPath w} hAbsr]} {
        puts "failed to open $absrPath to write: $hAbsr"
        close $hRaw
        return -code error FAILED_TO_WRITE
    }
    if {[catch {open $trnsPath w} hTrns]} {
        puts "failed to open $trnsPath to write: $hTrns"
        close $hRaw
        close $hAbsr
        return -code error FAILED_TO_WRITE
    }

    set    header "beamline"
    append header ",motorName,timestamp,lightBulb"
    append header ",integrationTime,scansToAverage,boxcarWidth"
    append header ",sample_x,sample_y,sample_z,sample_angle(phi+omega)"
    puts $hRaw $header
    puts $hAbsr $header
    puts $hTrns $header

    set firstLine "$m_beamline"
    append firstLine ",$m_motorName,$m_timestamp,$m_light"
    append firstLine ",$m_iTime,$m_nAvg,$m_bWidth"
    append firstLine ",$m_sample_x,$m_sample_y,$m_sample_z,$m_sample_a"
    puts $hRaw $firstLine
    puts $hAbsr $firstLine
    puts $hTrns $firstLine

    set header "wavelength,reference,dark"
    set sheetRaw  [dict create]
    set sheetAbsr [dict create]
    set sheetTrns [dict create]

    set row 0
    foreach w $m_wavelength rf $m_reference d $m_dark {
        set line "$w,$rf,$d"
        dict set sheetRaw  $row $line
        dict set sheetAbsr $row $line
        dict set sheetTrns $row $line
        incr row
    }
    foreach result $m_result {
        foreach {mName p ts rList aList tList} [formatResult $result] break
        append header ",$ts"
        #append header ",$p"
        set row 0
        foreach r $rList a $aList t $tList {
            dict append sheetRaw  $row ",$r"
            dict append sheetAbsr $row ",$a"
            dict append sheetTrns $row ",$t"
            incr row
        }
    }

    puts $hRaw "raw"
    puts $hAbsr "absorbance = -log10((raw-dark)/(reference-dark))"
    puts $hTrns "transmittance = (raw-dark)/(reference-dark)"

    puts $hRaw $header
    puts $hAbsr $header
    puts $hTrns $header

    for {set i 0} {$i < $row} {incr i} {
        puts $hRaw  [dict get $sheetRaw  $i]
        puts $hAbsr [dict get $sheetAbsr $i]
        puts $hTrns [dict get $sheetTrns $i]
    }

    close $hRaw
    close $hAbsr
    close $hTrns
    puts "saved scan to files $path"
}
MicroSpecConverter cvt

eval cvt convertFile $argv
