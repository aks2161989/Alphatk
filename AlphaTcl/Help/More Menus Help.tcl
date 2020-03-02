## -*-Tcl-*-
 # ==========================================================================
 # Help Files
 #
 # FILE: "More Menus Help.tcl"
 #                                          created: 11/11/2003 {11:17:58 AM}
 #                                      last update: 03/06/2006 {05:54:57 PM}
 # Description: 
 # 
 # Script to open a Help window for any menu.
 #
 # The "Help > More Menus Help" menu item sources this file and eventually
 # calls the [::help::openMenuHelpWindow] procedure.
 # 
 # Press Command-L to test this right now.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # ==========================================================================
 ##

namespace eval ::help {
    
    variable lastChosenMenu
    variable menuHelpOptions
    variable prettifiedMenus
    
    if {![info exists lastChosenMenu]} {
	foreach menuName [alpha::listAlphaTclPackages "menus"] {
	    set MenuName [quote::Prettify $menuName]
	    set prettifiedMenus($MenuName) $menuName
	}
	unset menuName MenuName
	set menuHelpOptions [lsort -dictionary \
	  [array names prettifiedMenus]]
	set lastChosenMenu  [lindex $menuHelpOptions 0]
    } 
}

##
 # --------------------------------------------------------------------------
 #
 # "::help::openMenuHelpWindow" --
 # 
 # The first time this file is sourced, we define this procedure.  We offer
 # the user a listpick dialog of all possible menus (including only those that
 # are presented "Config > Global Setup > Menus", which are defined using
 # either [addMenu] or [alpha::menu]).
 # 
 # --------------------------------------------------------------------------
 ##

if {![llength [info procs ::help::openMenuHelpWindow]]} {
    ;proc ::help::openMenuHelpWindow {} {
	
	variable lastChosenMenu
	variable menuHelpOptions
	variable prettifiedMenus
	
	set p "Choose a menu for which you want help:"
	set m [listpick -p $p -L [list $lastChosenMenu] $menuHelpOptions]
	package::helpWindow $prettifiedMenus($m)
	set lastChosenMenu $m
	return
    }
}

# Now we call this search procedure.
::help::openMenuHelpWindow

# ===========================================================================
# 
# .