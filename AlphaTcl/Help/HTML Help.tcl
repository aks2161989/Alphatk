## -*-Tcl-*-
 # ==========================================================================
 # Help files for Alpha
 #
 # FILE: "HTML Help.tcl"
 #                                          created: 01/10/2003 {07:49:04 PM}
 #                                      last update: 03/06/2006 {05:49:08 PM}
 # Description: 
 # 
 # Script to view the local HTML .html manual, either in one's web browser or
 # using Alpha's parser.  This script does not assume that HTML mode has been
 # loaded, or that the variable "manualFolder" is available.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

help::openDirect [help::pathToHelp [file join "HTML Help" HTMLmanual.html]]
