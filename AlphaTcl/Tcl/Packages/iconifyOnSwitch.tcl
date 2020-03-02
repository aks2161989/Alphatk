## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl extension packages
 # 
 # FILE: "iconifyOnSwitch.tcl"
 #                                          created: 02/27/2000 {14:59:21 PM}
 #                                      last update: 12/27/2004 {12:31:39 PM}
 #  
 # Author: Vince cut Pete's code out of "alphaHooks.tcl".
 #  
 # ==========================================================================
 ##

alpha::declare flag iconifyOnSwitch 0.2 global {
    # This code is only ever evaluated once
    lappend flagPrefs(Window) iconifyOnSwitch
} {
    # This code is evaluated when we turn on the flag
    hook::register suspendHook iconifyOnSwitch
    hook::register resumeHook deIconifyOnResume
} {
    # This code is evaluated when we turn off the flag
    hook::deregister suspendHook iconifyOnSwitch
    hook::deregister resumeHook deIconifyOnResume
} { 
    # off
} description {
    Iconify/minimize all windows when you switch to another application (and
    remap them when returning to Alpha)
} help {
    Iconify/minimize all windows when you switch to another application (and
    remap them when returning to Alpha).
    
    Preferences: Window
}

proc iconifyOnSwitch {args} {
    global suspIconed
    set suspIconed ""
    foreach win [winNames -f] {
	if {![icon -f "$win" -q]} {
	    lappend suspIconed $win
	    icon -f "$win" -t
	}
    }
    set suspIconed [lreverse $suspIconed]
}

proc deIconifyOnResume {args} {
    global suspIconed
    if {[info exists suspIconed]} {
	foreach win $suspIconed {
	    icon -f "$win" -o
	}
	unset suspIconed
    }
}







