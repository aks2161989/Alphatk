## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "Wiki-Example.tcl"
 #                                          created: 04/25/2002 {06:29:05 pm}
 #                                      last update: 03/06/2006 {06:44:18 PM}
 # Description: 
 # 
 # Script for the "Wiki Example" in the Examples package.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

loadAMode "Wiki"
Wiki::initializeMenu
if {[askyesno "Is an internet connection available?\
  (If not, a local version of the file will be opened,\
  but this cannot be saved to the web)."]} {
    Wiki::fetchAndEdit "http://www.purl.org/net/alpha/wikipages/sandbox-edit"
} elseif {([help::pathToExample Wiki-Example] ne "")} {
    edit -mode Wiki [help::pathToExample Wiki-Example]
} else {
    alertnote "Sorry, the Wiki example file is not installed."
}

    

