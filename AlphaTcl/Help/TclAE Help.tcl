## -*-Tcl-*-
 # ==========================================================================
 # Help Files
 #
 # FILE: "TclAEDocs.tcl"
 #                                          created: 10/30/2000 {12:38:57 PM}
 #                                      last update: 03/06/2006 {05:56:58 PM}
 # Description: 
 # 
 # Script to open the TclAEDocs in a browser from Alpha's Help menu.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

help::openDirect [help::pathToHelp [file join "TclAE Help" index.html]]

