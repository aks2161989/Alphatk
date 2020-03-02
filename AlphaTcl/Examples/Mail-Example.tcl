## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 # 
 # FILE: "Mail-Example.tcl"
 #                                          created: 10/17/2000 {02:18:43 pm}
 #                                      last update: 03/06/2006 {06:24:46 PM}
 # Description: 
 #  
 # Script for the "Eudora Example" in the Examples package.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # ==========================================================================
 ##

if {[catch {icGetPref RealName} userName]} {
    set userName ""
} 
Mail::createEmailWindow \
  "cupright@alumni.princeton.edu" \
  "subject" "Thanks!" \
  "content" "\rDear Craig,\
  \r\rThanks so much for creating the Examples Folder.\
  \r\rSincerely,\r\r$userName"

setWinInfo dirty 0

unset userName
