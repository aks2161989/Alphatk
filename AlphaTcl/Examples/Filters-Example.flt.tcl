## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "Filters-Example.flt.tcl"
 #                                          created: 10/17/2000 {02:18:43 pm}
 #                                      last update: 03/06/2006 {06:11:53 PM}
 # Description: 
 # 
 # Script for the "Filters Example.flt" in the Examples package.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

if {[file exists [file join $HOME Tcl Menus "Filters Menu" Filters Example.flt]]} {
    edit -r -c [file join $HOME Tcl Menus "Filters Menu" Filters Example.flt]
    goto [minPos]
} else {
    alertnote "Sorry, the \"Example.flt\" filter is not installed."
}

