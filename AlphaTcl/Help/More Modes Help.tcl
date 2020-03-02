## -*-Tcl-*-
 # ==========================================================================
 # Help Files
 #
 # FILE: "More Modes Help.tcl"
 #                                          created: 11/11/2003 {11:17:58 AM}
 #                                      last update: 03/06/2006 {05:55:18 PM}
 # Description: 
 # 
 # Script to open a Help window for any mode.
 #
 # The "Help > More Modes Help" menu item sources this file and eventually
 # calls the [::help::openModeHelpWindow] procedure.
 # 
 # Press Command-L to test this right now.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # ==========================================================================
 ##

namespace eval ::help {}

##
 # --------------------------------------------------------------------------
 #
 # "::help::openModeHelpWindow" --
 # 
 # The first time this file is sourced, we define this procedure.
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info procs ::help::openModeHelpWindow]]} {
    ;proc ::help::openModeHelpWindow {} {
	
	if {[llength [winNames]]} {
	    set L [list [win::getMode [win::Current] 1]]
	} else {
	    set L [list "Text"]
	}
	set p "Choose a mode for which you want help:"
	set M [listpick -p $p -L $L [alpha::listAlphaTclPackages "modes" 1]]
	package::helpWindow [mode::getName $M 0]
	return
    }
}

# Now we call this search procedure.
::help::openModeHelpWindow

# ===========================================================================
# 
# .