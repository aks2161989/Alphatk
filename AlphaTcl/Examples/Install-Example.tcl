## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "Install-Example.tcl"
 #                                          created: 10/17/2000 {02:18:43 pm}
 #                                      last update: 03/06/2006 {06:15:39 PM}
 # Description: 
 # 
 # Script for the "Install Example" in the Examples package.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

if {([help::pathToExample "Install-Example"] ne "")} {
    edit -r -c [help::pathToExample "Install-Example"]
} else {
    alertnote "Sorry, the Install example is not available."
}
