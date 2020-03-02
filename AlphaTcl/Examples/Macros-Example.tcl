## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "Macros-Example.tcl"
 #                                   created: 02/27/01 {02:22:28 pm} 
 #                               last update: 03/06/2006 {06:22:38 PM} 
 # Description: 
 # 
 # Script for the "Macros Example" in the Examples package.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

if {([help::pathToExample "Macros-Example"] ne "")} {
    new -n "* Macros Tutorial *" -m Setx -text \
      [file::readAll [help::pathToExample "Macros-Example"]] -shell 1
    goto [minPos]
    if {[llength [getNamedMarks]]} {
	Setx::markAsSetext
    }
} else {
    alertnote "Sorry, the Macros Tutorial is not available."
}
 