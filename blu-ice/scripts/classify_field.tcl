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


# classify_field.tk
#
# The procedures in this file can be used to check whether a value
# typed into an entry field is valid or not.
#


proc is_word { string } {

	regexp {^[ \t]*[^ ]+[ \t]*$} $string

}

######################################################################
# is_positive_int -- returns TRUE if passed string contains a positive
# integer, or a positive integer with white space on either side.
######################################################################

proc is_positive_int { string } {

	regexp {^[ \t]*\+?[0-9]+[ \t]*$} $string
}


######################################################################
# is_incomplete_positive_int -- returns TRUE if passed string contains
# a positive integer, just a plus sign, just white space, or any of
# the preceding with white space on either side.
######################################################################

proc is_incomplete_positive_int { string } {

	regexp {^[ \t]*\+?[0-9]*[ \t]*$} $string
}



######################################################################
# is_int -- returns TRUE if passed string contains an integer or an
# integer with white space on either side.
######################################################################

proc is_int { string } {

	regexp {^[ \t]*(\+|\-)?[0-9]+[ \t]*$} $string
}


######################################################################
# is_incomplete_int -- returns TRUE if passed string contains an
# integer, a plus sign, or a minus sign, or any of the preceding with 
# white space on either side.
######################################################################

proc is_incomplete_int { string } {

	regexp {^[ \t]*(\+|\-)?[0-9]*[ \t]*$} $string
}


######################################################################
# is_float -- returns TRUE if passed string contains a float or a float
# with white space on either side.
######################################################################

proc is_float { string } {

	set number ""
	regexp {^[ \t]*(\+|\-)?([0-9]*\.?[0-9]*)?[ \t]*$} $string m sign number
	expr { $number != "" && $number != "." }
}


######################################################################
# is_incomplete_float -- returns TRUE if passed string contains an
# float, a plus sign, or a minus sign, or any of the preceding with 
# white space on either side.
######################################################################

proc is_incomplete_float { string } {

	regexp {^[ \t]*(\+|\-)?([0-9]*\.?[0-9]*)?[ \t]*$} $string
}


######################################################################
# is_positive_float -- returns TRUE if passed string contains
# a positive float or a positive float with white space on either side.
######################################################################

proc is_positive_float { string } {
	
	set number ""
	regexp {^[ \t]*\+?([0-9]*\.?[0-9]*)?[ \t]*$} $string sign number
	expr { $number != "" }
}


######################################################################
# is_incomplete_positive_float -- returns TRUE if passed string contains
# a positive float, a plus sign, or any of the preceding with 
# white space on either side.
######################################################################

proc is_incomplete_positive_float { string } {
	set number ""
	set sign ""
	regexp {^[ \t]*\+?([0-9]*\.?[0-9]*)?[ \t]*$} $string sign number
	expr { $sign != "" || $number != "" }
}


######################################################################
# is_blank -- returns TRUE if passed string contains only whate space
######################################################################

proc is_blank { string } {

	regexp {^[ \t]*$} $string
}
