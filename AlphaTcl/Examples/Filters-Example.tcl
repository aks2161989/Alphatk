## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "Filters-Example.tcl"
 #                                          created: 10/17/2000 {02:18:43 pm}
 #                                      last update: 03/06/2006 {06:23:03 PM}
 # Description: 
 # 
 # Script for the "Filters Example" in the Examples package.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

if {([help::pathToExample "Filters-Example"] ne "")} {
    new -n "* Filters Menu Tutorial *" -m Setx -text \
      [file::readAll [help::pathToExample "Filters-Example"]] -shell 1
    goto [minPos]
    if {[llength [getNamedMarks]]} {
	Setx::markAsSetext
    }
} else {
    alertnote "Sorry, the Filters Tutorial is not available."
}

