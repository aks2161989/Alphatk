## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "ManipCols-Example.tcl"
 #                                          created: 10/17/2000 {02:18:43 pm}
 #                                      last update: 03/06/2006 {06:26:48 PM}
 # Description: 
 # 
 # Script for the "ManipCols Example" in the Examples package.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

if {([help::pathToExample "ManipCols-Example"] ne "")} {
    new -n "* Manip Cols Tutorial *" -m Setx -tabsize 8 -text \
      [file::readAll [help::pathToExample "ManipCols-Example"]] -shell 1
    goto [minPos]
    if {[llength [getNamedMarks]]} {
	Setx::markAsSetext
    }
} else {
    alertnote "Sorry, the ManipCols Tutorial is not available."
}
