## -*-Tcl-*-
 # ==========================================================================
 # Help files for Alpha
 #
 # FILE: "LaTeX Help.tcl"
 #                                          created: 10/17/2000 {02:18:43 pm}
 #                                      last update: 03/06/2006 {05:57:20 PM}
 # Description: 
 # 
 # Script to view the local LaTeX .html manual, either in one's web browser
 # or using Alpha's parser.  Additional options include opening, processing,
 # or viewing the latex_<manual>.ext files.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

help::askOrOpen "LaTeX Help" \
  [help::pathToHelp [file join "LaTeX Help" latex_guide.pdf]] \
  [help::pathToHelp [file join "LaTeX Help" "LaTeX Help"]] \
  [help::pathToHelp [file join "LaTeX Help" "teTeX Help"]]


