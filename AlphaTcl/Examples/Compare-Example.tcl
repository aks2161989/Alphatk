## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "Compare-Example.tcl"
 #                                          created: 10/17/2000 {02:18:43 pm}
 #                                      last update: 03/06/2006 {06:08:40 PM}
 # Description: 
 # 
 # Script for the "Compare Example" in the Examples package.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

edit -r -c [help::pathToExample Tcl-Example.tcl]
edit -r -c [help::pathToExample Trains3.tcl]
compare::windows 
