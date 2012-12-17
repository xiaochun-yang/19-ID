#!/bin/sh
# the next line restarts using -*-Tcl-*-sh \
	 exec wish "$0" ${1+"$@"}

package require Itcl
namespace import ::itcl::*
package require Iwidgets
package require http
package require DCSUtil
package require Img

	wm title . "Diffraction Image Server Tester "
	wm resizable . 1 1


class DiffImageViewer {
 	inherit ::itk::Widget
   public method constructor
   public method load
   public method handleResponse

   private common uniqueNameCounter 0

   private variable _sessionId
   private variable _host
   private variable _port
   private variable _username
   private variable _imageName xxx

   private variable outStandingRequest 0
   private variable dropped 0
   private variable refused 0   

	public variable sizeX 			400
	public variable sizeY 			400
	public variable zoom 			400
	public variable gray 			400
	public variable percentX 		0.5
	public variable percentY 		0.5
	public variable imageType 		"full";

}

body DiffImageViewer::constructor { sessionId_ host_ port_ username_ x y args } {
	# global variables
   global env

   set _sessionId $sessionId_
   set _host $host_
   set _port $port_
   set _username $username_

	# create the photo object with a unique name
	set m_imageName test$uniqueNameCounter
	incr uniqueNameCounter

	itk_component add imageCanvas {
		canvas $itk_interior.imageCanvas -bg white -relief sunken -borderwidth 3
	} {
      keep -width -height
   }

	image create photo $_imageName -palette 256/256/256 -format jpeg

	set image [$itk_component(imageCanvas) create image 0 0 -image $_imageName -anchor nw ]

   pack $itk_interior
   pack $itk_component(imageCanvas)
	eval itk_initialize $args
}

body DiffImageViewer::load { filename } {
   # set SID [getTicketFromSessionId $_sessionId]

	set url "http://${_host}:${_port}/getImage?userName=${_username}&sessionId=$_sessionId&fileName=$filename"

	append url "&sizeX=$sizeX&sizeY=$sizeY&zoom=$zoom&gray=$gray&percentX=$percentX&percentY=$percentY"

   if {[catch {
	   set httpObjName [http::geturl $url -binary 1 -command "$this handleResponse" -timeout 60000]
      incr outStandingRequest
   } result ] } {
      incr refused
   }

   puts "waiting for: $outStandingRequest, dropped $dropped, refused $refused"      
}

body DiffImageViewer::handleResponse { httpObjName } {
      puts "got image"

      incr outStandingRequest -1
		upvar #0 $httpObjName httpObj

		# Current status: pending, ok, eof or reset
		set status $httpObj(status)

		# Response first line
		set replystatus $httpObj(http)

		# First word in the respone first line
		set replycode [lindex $replystatus 1]

		if { $status != "ok" } {

			# http status is no ok.
			http::cleanup $httpObjName
			puts "Image server error: $replycode $status"
         #exit
         incr dropped
		   http::cleanup $httpObjName
         return
		} elseif { $replycode != 200 } {
			# http response code is not 200
			http::cleanup $httpObjName
			puts "Image server error: $replycode $status"
         incr dropped
		   http::cleanup $httpObjName
         return
		} 

	# convert the image encoding to standard Tcl encoding (base64 encoding)

	# delete the previous photo
	image delete $_imageName
						
	# create the Tcl photo from the jpeg data

   #puts "draw image"
   image create photo $_imageName -palette 256/256/256 -format jpeg -data [encoding convertto iso8859-1 $httpObj(body)]

	http::cleanup $httpObjName
}




proc testFastBursts {dir type} {
   set fileList  [glob -type f -nocomplain -directory $dir *.$type]

   for {set cnt 0} {$cnt < 100} {incr cnt} {
      foreach file $fileList  {
         #puts "load $file"

         for {set cnt 0} {$cnt<1} {incr cnt} {
            ::.i load $file
         }

         after 800
         update
      }
   } 
}

proc testOverwrittenFiles {dir } {
   set fileList  [glob -type f -nocomplain -directory $dir *.img]

   set numFiles [llength $fileList]

   for {set cnt 0} {$cnt < 1000} {incr cnt} {

      set file [lindex $fileList [expr int(rand() * $numFiles) ] ] 

      puts $file
      ::.i load $file


      after 1000

      #pick another file and touch it
      set file [lindex $fileList [expr int(rand() * $numFiles) ] ] 
      exec touch $file

      update
   }
}


proc uneraseFilesInDir {dir} {
   set fileList  [glob -type f -nocomplain -directory $dir *.bak]

   if {$fileList == ""} return

   foreach file $fileList {
      file rename $file [file rootname $file]
   }
}


proc eraseRandomFileInDir {dir} {
   set fileList  [glob -type f -nocomplain -directory $dir *.img]

   if {$fileList == ""} return


   set numFiles [llength $fileList]
   set file [lindex $fileList [expr int(rand() * $numFiles) ] ] 
   #file rename $file ${file}.bak
   file copy $file ${file}.bak
   file delete $file
}

proc uneraseRandomFileInDir {dir} {
   set fileList  [glob -type f -nocomplain -directory $dir *.bak]
   if {$fileList == ""} return

   set numFiles [llength $fileList]
   set file [lindex $fileList [expr int(rand() * $numFiles) ] ] 
   file rename $file [file rootname $file]
}






proc testDeletedFiles {dir} {
   uneraseFilesInDir $dir
   set fileList  [glob -type f -nocomplain -directory $dir *.img]
   set numFiles [llength $fileList]

   for {set cnt 0} {$cnt < 1000} {incr cnt} {

      set file [lindex $fileList [expr int(rand() * $numFiles) ] ] 
      puts $file
      ::.i load $file

      after 800

      if { int(rand() *100) < 50} {
         eraseRandomFileInDir $dir
      } else {
         uneraseRandomFileInDir $dir
      }

      update
   }
}



#create the directory
set in [open [file join ~scottm .bluice session] r]
set sessionId [read $in]
close $in


#DiffImageViewer .i $sessionId smbfs 14017 scottm 500 500
DiffImageViewer .i $sessionId localhost 14027 scottm 500 500
pack .i

#testDeletedFiles /data/scottm/BL7-1/volatile
#testOverwrittenFiles /data/scottm/BL7-1/test

testFastBursts /data/scottm/BL7-1 img
