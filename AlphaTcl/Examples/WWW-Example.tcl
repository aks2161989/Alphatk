## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "WWW-Example.tcl"
 #                                          created: 10/17/2000 {02:18:43 pm}
 #                                      last update: 03/06/2006 {06:46:37 PM}
 # Description: 
 # 
 # Script for the "WWW Example" in the Examples package.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # ==========================================================================
 ##

if {[askyesno "Is an internet connection available?\
  (If not, a local html file will be rendered.)"]} {
    WWW::renderUrl "http://www.purl.org/net/alpha/wiki/"
} elseif {([help::pathToHelp [file join "HTML Help" HTMLmanual.html]] ne "")} {
    WWW::renderFile [file join $HOME Help "HTML Help" HTMLmanual.html]
} else {
    alertnote "Sorry, the HTML Manual help file is not installed."
}

