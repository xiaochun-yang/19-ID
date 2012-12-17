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



class Pilatus::Logger {
    public variable appName "unknown"
    public variable filePattern ""
    public variable fileSize 31457280
    public variable numFiles 10
    public variable level LOG_ALL
    public variable stdout true
    public variable appendToFile false

    public method afterPropertiesSet {  } {

        #calculate center of center pixel
        if {$filePattern == ""} {return -code error "Error: must set filePattern"}
        if {$fileSize == ""} {return -code error "Error: must configure fileSize"}
        if {$numFiles ==""} {return -code error "Error: must configure numFiles"}
        if {$level ==""} {return -code error "Error: must configure level"}
        if {$stdout ==""} {return -code error "Error: must configure stdout (true/false)"}
        if {$appendToFile ==""} {return -code error "Error: must configure appendToFile (true/false)"}

            
#yangx orininal        load ../../tcl_clibs/linux64/tcl_clibs.so dcs_c_library
	load ../../tcl_clibs/linux/tcl_clibs.so dcs_c_library
        initPutsLogger $appName $filePattern $fileSize $numFiles $level $stdout $appendToFile
    }
}


