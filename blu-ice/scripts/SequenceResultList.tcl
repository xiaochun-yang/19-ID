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

#
# SequenceResultList.tcl
#
# part of Screening UI
# used by Sequence.tcl
#

error "The screening tab is obsolete in the 'blu-ice' project. Do not source SequenceResultList.tcl.  Use 'BluIceWidgets' project instead."

package require Itcl
package require Iwidgets


# ===================================================

::itcl::class SequenceResultList {
# contructor / destructor
constructor { top} {}

# protected variables
protected variable m_fileListLimit 2500
protected variable m_filesPerSubDirLimit 620
#protected variable m_directory "U:/gwolf"
protected variable m_directory "/data/gwolf"
#
private variable w_list
private variable w_directory
private variable w_open

# private variables
private variable m_font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"
private variable m_borderWidth 2
private variable m_xviewSize 120
private variable m_yviewSize 5
private variable m_lastUpdateRequestID 0

# private methods
private method FileListFrame { top data } {}
private method bindEventHandlers { canvasFrame } {}
private method handleSelectEvent { box } {}
private method handleOpenClick {} {}
private method getFileInfoList { flist updateRequestID } {}
private method trc_msg { text } {}

# public methods
public method setDirectory { dir } {}
public method getDirectory {} {}
public method createFileList {} {}
public method updateFileList { subdir fileName } {}

}

# ===================================================

::itcl::body SequenceResultList::constructor { top } {

set data {
{offline.img}
}

frame $top -borderwidth $m_borderWidth

pack $top -side top -fill x

FileListFrame $top.fileList $data
pack $top $top.fileList -side left -fill x

DynamicHelp::register $w_open balloon "Open result image"

bindEventHandlers $w_list
}

# ===================================================
# ===================================================

::itcl::body SequenceResultList::FileListFrame { top data } {
	
	# Create the top frame (component container)
	#frame $top -borderwidth 10
	#pack $top -side top
	frame $top -borderwidth 1 -relief groove
	pack $top -side top

	# Create a frame caption
	set f [frame $top.header -bd 4]
	label $f.labelFrame -text "Results" -anchor w  -width 24  -font $m_font
	pack $f.labelFrame -side left

	set w_open [button $f.buttonOpen -text "Open" -font $m_font]
	pack $w_open -side right

	pack $f -side top

	# Create a scrolling Listbox
        set bgtext [$f cget -background]
        set bgscroll [$w_open cget -background]
	set view ""
	append view $m_xviewSize "x" $m_yviewSize
	set sl [::iwidgets::scrolledlistbox $top.scrolledList -sbwidth 12 -background $bgscroll -textbackground $bgtext -borderwidth 2 -visibleitems $view -textfont $m_font]
	pack $sl -side top -fill both

	#fill in the data

	foreach {item} "$data" {
		$sl insert end $item
	}
	set w_list $sl
}

# ===================================================

::itcl::body SequenceResultList::bindEventHandlers { scrolledList } {
	set f $scrolledList

	$scrolledList config -selectioncommand [::itcl::code $this handleSelectEvent $scrolledList]
	$w_open config -command [::itcl::code $this handleOpenClick]
	
	trc_msg "bindEventHandlers"
}

# ===================================================

::itcl::body SequenceResultList::handleSelectEvent { box} {
	trc_msg "handleSelectEvent"

	set filename [$box getcurselection]
	trc_msg "filename=$filename"

	#exec adxv $filename 
	#exec netscape $filename 
}

# ===================================================

::itcl::body SequenceResultList::handleOpenClick {} {
	trc_msg "handleOpenClick"

	set filename [$w_list getcurselection]
	if { [string length $filename]<=0 } {
		set filename [$w_list get end]
	}
	trc_msg "filename=$filename"
	set filepath [file join $m_directory $filename]
	trc_msg "filepath=$filepath"

	set extention [string range $filename end-3 end]
	switch -exact -- $extention {
		.img { 
			trc_msg "load image - exec adxv $filepath"
			set result [ catch {exec adxv $filepath &} ]
                        trc_msg "$result"
		}
		.jpg { 
			trc_msg "load jpeg - exec display $filepath"
			set result [ catch {exec display $filepath &} ]
                        trc_msg "$result"
		}
		default { trc_msg "ERROR unknown file extention=$extention" }
	}

}

# ===================================================

::itcl::body SequenceResultList::getFileInfoList { flist updateRequestID } {
#trc_msg "SequenceResultList::getFileInfoList"

set nFilesInThisDir 0
set maxTime 0
set dirname ""
set i 0
set fileInfoList {}
foreach fileName $flist {
        update
        if { $updateRequestID!=$m_lastUpdateRequestID } {
            trc_msg "aborted SequenceResultList::getFileInfoList $updateRequestID"
            return
        }
	if { $i>$m_fileListLimit } {
		trc_msg "ERROR too many files in this directory (>${m_fileListLimit})"
                set fileInfo [list 999999999999999 "Too many files..."]
                if { [lindex $fileInfoList end]!=$fileInfo } {
                    set fileInfoList [linsert $fileInfoList end $fileInfo]
                }
		break
	}
	#trc_msg "fileName=$fileName"
	if { [file isdirectory $fileName] } {
		set fl [glob -nocomplain -directory $fileName -- *]
		set fileInfoList [concat $fileInfoList [getFileInfoList $fl $updateRequestID]]
		set i [llength $fileInfoList]
		continue;
	}
        # limit the number per images in a subdiretory (for the data-home directory we apply only the total limit "m_fileListLimit")
        incr nFilesInThisDir
        if { $dirname!=$m_directory && $nFilesInThisDir>$m_filesPerSubDirLimit } {
           # we are in a subdirectory and the number of files is above the limit
           continue
        }

	# if the filesystem is mixed up we could get an exception in "file mtime...", so we have to catch it...
        set time "000000000000000"
	catch {
	set time [file mtime $fileName]
	set time "00000000000000$time"
	set time [string range $time end-14 end]
	set fileInfo [list $time $fileName]
	set fileInfoList [linsert $fileInfoList end $fileInfo]
	incr i
	}

        if { $time>$maxTime } {
            set maxTime $time
        }
        if { [string length $dirname]<1 } {
            set dirname [file dirname $fileName]
        }
        if { $dirname=="." } {
            set dirname $m_directory
        }
        if { $dirname!=$m_directory && $nFilesInThisDir==$m_filesPerSubDirLimit } {
           # we are in a subdirectory and the number of files has reached the limit
            set time [format "%s%s" $maxTime "9"]
            set x [format "%s%s" $dirname "/..."]
            set fileInfo [list $time $x]
            set fileInfoList [linsert $fileInfoList end $fileInfo]
        }
}
#trc_msg "fileInfoList=$fileInfoList"
set n [llength $fileInfoList]
#trc_msg "n=$n"

return $fileInfoList
}


# ===================================================

::itcl::body SequenceResultList::trc_msg { text } {
# puts "$text"
print "$text"
}

# ===================================================
# ===================================================
# public methods

::itcl::body SequenceResultList::setDirectory { dir } {
trc_msg "SequenceResultList::setDirectory $dir"

set m_directory $dir
}

# ===================================================

::itcl::body SequenceResultList::getDirectory {} {
return $m_directory
}

# ===================================================

::itcl::body SequenceResultList::createFileList {} {
trc_msg "SequenceResultList::createFileList"
#trc_msg [clock format [clock seconds]]

$w_list clear

set dir $m_directory

incr m_lastUpdateRequestID
set m_lastUpdateRequestTime [clock format [clock seconds]]
set m_lastUpdateRequestDirectory $dir
set updateRequestID $m_lastUpdateRequestID
trc_msg "SequenceResultList::getFileInfoList m_lastUpdateRequestID=$m_lastUpdateRequestID"

if { [file isdirectory $dir]==0 || [file readable $dir]==0 } {
    trc_msg "ERROR SequenceResultList::createFileList no readable directory $dir"
    log_note "No readable screening directory $dir"
    return
}
if { [string range $dir end end]!="/" } {
    set dir "$dir/"
}
$w_list insert end "Loading $dir ..."

trc_msg "m_directory=$dir"

set flist [glob -nocomplain -directory $dir -- *]
set fileInfoList [getFileInfoList $flist $updateRequestID]
if { $updateRequestID!=$m_lastUpdateRequestID } {
      trc_msg "aborted SequenceResultList::createFileList"
      return
}

$w_list clear
set flistSorted [lsort $fileInfoList]
foreach file $flistSorted {
	set fileName [lindex $file 1]
        set lngRootName [string length $dir]
        if { [string range $fileName 0 [expr $lngRootName -1]]==$dir } {
            set fileName [string range $fileName $lngRootName end]
        }
	#trc_msg "$fileName"
	$w_list insert end $fileName
}

$w_list see end
set size [llength $flistSorted]

if { $size>=$m_fileListLimit } {
    log_note "Too many files in directory $m_directory"
} else {
    log_note "$size files in directory $m_directory"
}

#trc_msg [clock format [clock seconds]]

trc_msg "SequenceResultList::createFileList OK $m_lastUpdateRequestID"
} ;# createFileList{}


# ===================================================

::itcl::body SequenceResultList::updateFileList { subdir fileName } {
trc_msg "SequenceResultList::updateFileList $subdir $fileName"

if { $subdir=="." } {
	set subdir ""
}
set path [file join $subdir $fileName]
$w_list insert end $path
$w_list see end

}

# ===================================================
# ===================================================
#// main

#set top .ex
#FileList results $top



# ===================================================
